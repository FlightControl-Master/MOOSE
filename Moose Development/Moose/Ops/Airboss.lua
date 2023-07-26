--- **Ops** - Manages aircraft CASE X recoveries for carrier operations (X=I, II, III).
--
-- The AIRBOSS class manages recoveries of human pilots and AI aircraft on aircraft carriers.
--
-- **Main Features:**
--
--    * CASE I, II and III recoveries.
--    * Supports human pilots as well as AI flight groups.
--    * Automatic LSO grading including (optional) live grading while in the groove.
--    * Different skill levels from on-the-fly tips for flight students to *ziplip* for pros. Can be set for each player individually.
--    * Define recovery time windows with individual recovery cases in the same mission.
--    * Option to let the carrier steam into the wind automatically.
--    * Automatic TACAN and ICLS channel setting of carrier.
--    * Separate radio channels for LSO and Marshal transmissions.
--    * Voice over support for LSO and Marshal radio transmissions.
--    * Advanced F10 radio menu including carrier info, weather, radio frequencies, TACAN/ICLS channels, player LSO grades, marking of zones etc.
--    * Recovery tanker and refueling option via integration of @{Ops.RecoveryTanker} class.
--    * Rescue helicopter option via @{Ops.RescueHelo} class.
--    * Combine multiple human players to sections.
--    * Many parameters customizable by convenient user API functions.
--    * Multiple carrier support due to object oriented approach.
--    * Unlimited number of players.
--    * Persistence of player results (optional). LSO grading data is saved to csv file.
--    * Trap sheet (optional).
--    * Finite State Machine (FSM) implementation.
--
-- **Supported Carriers:**
--
--    * [USS John C. Stennis](https://en.wikipedia.org/wiki/USS_John_C._Stennis) (CVN-74)
--    * [USS Theodore Roosevelt](https://en.wikipedia.org/wiki/USS_Theodore_Roosevelt_(CVN-71\)) (CVN-71) [Super Carrier Module]
--    * [USS Abraham Lincoln](https://en.wikipedia.org/wiki/USS_Abraham_Lincoln_(CVN-72\)) (CVN-72) [Super Carrier Module]
--    * [USS George Washington](https://en.wikipedia.org/wiki/USS_George_Washington_(CVN-73\)) (CVN-73) [Super Carrier Module]
--    * [USS Harry S. Truman](https://en.wikipedia.org/wiki/USS_Harry_S._Truman) (CVN-75) [Super Carrier Module]
--    * [USS Forrestal](https://en.wikipedia.org/wiki/USS_Forrestal_(CV-59\)) (CV-59) [Heatblur Carrier Module]
--    * [HMS Hermes](https://en.wikipedia.org/wiki/HMS_Hermes_(R12\)) (R12)
--    * [HMS Invincible](https://en.wikipedia.org/wiki/HMS_Invincible_(R05\)) (R05)
--    * [USS Tarawa](https://en.wikipedia.org/wiki/USS_Tarawa_(LHA-1\)) (LHA-1)
--    * [USS America](https://en.wikipedia.org/wiki/USS_America_(LHA-6\)) (LHA-6)
--    * [Juan Carlos I](https://en.wikipedia.org/wiki/Spanish_amphibious_assault_ship_Juan_Carlos_I) (L61)
--    * [HMAS Canberra](https://en.wikipedia.org/wiki/HMAS_Canberra_(L02\)) (L02)
--
-- **Supported Aircraft:**
--
--    * [F/A-18C Hornet Lot 20](https://forums.eagle.ru/forumdisplay.php?f=557) (Player & AI)
--    * [F-14A/B Tomcat](https://forums.eagle.ru/forumdisplay.php?f=395) (Player & AI)
--    * [A-4E Skyhawk Community Mod](https://forums.eagle.ru/showthread.php?t=224989) (Player & AI)
--    * [AV-8B N/A Harrier](https://forums.eagle.ru/forumdisplay.php?f=555) (Player & AI)
--    * [T-45C Goshawk](https://www.vnao-cvw-7.com/t-45-goshawk) (VNAO mod) (Player & AI)
--    * [FE/A-18E/F/G Superhornet](https://forum.dcs.world/topic/316971-cjs-super-hornet-community-mod-v20-official-thread/) (CJS mod) (Player & AI)
--    * F/A-18C Hornet (AI)
--    * F-14A Tomcat (AI)
--    * E-2D Hawkeye (AI)
--    * S-3B Viking & tanker version (AI)
--    * [C-2A Greyhound](https://forums.eagle.ru/showthread.php?t=255641) (AI)
--
-- At the moment, optimized parameters are available for the F/A-18C Hornet (Lot 20) and A-4E community mod as aircraft and the USS John C. Stennis as carrier.
--
-- The AV-8B Harrier, HMS Hermes, HMS Invincible, the USS Tarawa, USS America, HMAS Canberra, and Juan Carlos I are WIP. The AV-8B harrier and the LHA's and LHD can only be used together, i.e. these ships are the only carriers the harrier is supposed to land on and
-- no other fixed wing aircraft (human or AI controlled) are supposed to land on these ships. Currently only Case I is supported. Case II/III take slightly different steps from the CVN carrier.
-- However, if no offset is used for the holding radial this provides a very close representation of the V/STOL Case III, allowing for an approach to over the deck and a vertical landing.
--
-- Heatblur's mighty F-14B Tomcat has been added (March 13th 2019) as well. Same goes for the A version.
--
-- The [DCS Supercarriers](https://forums.eagle.ru/forum/151-dcs-supercarrier/) are also supported.
--
-- ## Discussion
--
-- If you have questions or suggestions, please visit the [MOOSE Discord](https://discord.gg/AeYAkHP) #ops-airboss channel.
-- There you also find an example mission and the necessary voice over sound files. Check out the **pinned messages**.
--
-- ## Example Missions
--
-- Example missions can be found [here](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Airboss).
-- They contain the latest development Moose.lua file.
--
-- ## IMPORTANT
--
-- Some important restrictions (of DCS) you should be aware of:
--
--    * Each player slot (client) should be in a separate group as DCS does only allow for sending messages to groups and not individual units.
--    * Players are identified by their player name. Hence, ensure that no two player have the same name, e.g. "New Callsign", as this will lead to unexpected results.
--    * The modex (tail number) of an aircraft should **not** be changed dynamically in the mission by a player. Unfortunately, there is no way to get this information via scripting API functions.
--    * The A-4E-C mod needs *easy comms* activated to interact with the F10 radio menu.
--
-- ## Youtube Videos
--
-- ### AIRBOSS videos:
--
--    * [[MOOSE] Airboss - Groove Testing (WIP)](https://www.youtube.com/watch?v=94KHQxxX3UI)
--    * [[MOOSE] Airboss - Groove Test A-4E Community Mod](https://www.youtube.com/watch?v=ZbjD7FHiaHo)
--    * [[MOOSE] Airboss - Groove Test: On-the-fly LSO Grading](https://www.youtube.com/watch?v=Xgs1hwDcPyM)
--    * [[MOOSE] Airboss - Carrier Auto Steam Into Wind](https://www.youtube.com/watch?v=IsU8dYgsp90)
--    * [[MOOSE] Airboss - CASE I Walkthrough in the F/A-18C by TG](https://www.youtube.com/watch?v=o1UrP4Q6PMM)
--    * [[MOOSE] Airboss - New LSO/Marshal Voice Overs by Raynor](https://www.youtube.com/watch?v=_Suo68bRu8k)
--    * [[MOOSE] Airboss - CASE I, "Until We Go Down" featuring the F-14B by Pikes](https://www.youtube.com/watch?v=ojgHDSw3Doc)
--    * [[MOOSE] Airboss - Skipper Menu](https://youtu.be/awnecCxRoNQ)
--
-- ### Lex explaining Boat Ops:
--
--    * [( DCS HORNET ) Some boat ops basics VID 1](https://www.youtube.com/watch?v=LvGQS-3AzMc)
--    * [( DCS HORNET ) Some boat ops basics VID 2](https://www.youtube.com/watch?v=bN44wvtRsw0)
--
-- ### Jabbers Case I and III Recovery Tutorials:
--
--    * [DCS World - F/A-18 - Case I Carrier Recovery Tutorial](https://www.youtube.com/watch?v=lm-M3VUy-_I)
--    * [DCS World - Case I Recovery Tutorial - Followup](https://www.youtube.com/watch?v=cW5R32Q6xC8)
--    * [DCS World - CASE III Recovery Tutorial](https://www.youtube.com/watch?v=Lnfug5CVAvo)
--
-- ### Wags DCS Hornet Videos:
--
--    * [DCS: F/A-18C Hornet - Episode 9: CASE I Carrier Landing](https://www.youtube.com/watch?v=TuigBLhtAH8)
--    * [DCS: F/A-18C Hornet â€“ Episode 16: CASE III Introduction](https://www.youtube.com/watch?v=DvlMHnLjbDQ)
--    * [DCS: F/A-18C Hornet Case I Carrier Landing Training Lesson Recording](https://www.youtube.com/watch?v=D33uM9q4xgA)
--
-- ### AV-8B Harrier and V/STOL Operations:
--
--    * [Harrier Ship Landing Mission with Auto LSO!](https://www.youtube.com/watch?v=lqmVvpunk2c)
--    * [Updated Airboss V/STOL Features USS Tarawa](https://youtu.be/K7I4pU6j718)
--    * [Harrier Practice pattern USS America](https://youtu.be/99NigITYmcI)
--    * [Harrier CASE III TACAN Approach USS Tarawa](https://www.youtube.com/watch?v=bTgJXZ9Mhdc&t=1s)
--    * [Harrier CASE III TACAN Approach USS Tarawa](https://www.youtube.com/watch?v=wWHag5WpNZ0)
--
-- ===
--
-- ### Author: **funkyfranky** LHA and LHD V/STOL additions by **Pene**
-- ### Special Thanks To **Bankler**
-- For his great [Recovery Trainer](https://forums.eagle.ru/showthread.php?t=221412) mission and script!
-- His work was the initial inspiration for this class. Also note that this implementation uses some routines for determining the player position in Case I recoveries he developed.
-- Bankler was kind enough to allow me to add this to the class - thanks again!
--
-- @module Ops.Airboss
-- @image Ops_Airboss.png

--- AIRBOSS class.
-- @type AIRBOSS
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string theatre The DCS map used in the mission.
-- @field Wrapper.Unit#UNIT carrier Aircraft carrier unit on which we want to practice.
-- @field #string carriertype Type name of aircraft carrier.
-- @field #AIRBOSS.CarrierParameters carrierparam Carrier specific parameters.
-- @field #string alias Alias of the carrier.
-- @field Wrapper.Airbase#AIRBASE airbase Carrier airbase object.
-- @field #table waypoints Waypoint coordinates of carrier.
-- @field #number currentwp Current waypoint, i.e. the one that has been passed last.
-- @field Core.Beacon#BEACON beacon Carrier beacon for TACAN and ICLS.
-- @field #boolean TACANon Automatic TACAN is activated.
-- @field #number TACANchannel TACAN channel.
-- @field #string TACANmode TACAN mode, i.e. "X" or "Y".
-- @field #string TACANmorse TACAN morse code, e.g. "STN".
-- @field #boolean ICLSon Automatic ICLS is activated.
-- @field #number ICLSchannel ICLS channel.
-- @field #string ICLSmorse ICLS morse code, e.g. "STN".
-- @field #AIRBOSS.Radio LSORadio Radio for LSO calls.
-- @field #number LSOFreq LSO radio frequency in MHz.
-- @field #string LSOModu LSO radio modulation "AM" or "FM".
-- @field #AIRBOSS.Radio MarshalRadio Radio for carrier calls.
-- @field #number MarshalFreq Marshal radio frequency in MHz.
-- @field #string MarshalModu Marshal radio modulation "AM" or "FM".
-- @field #number TowerFreq Tower radio frequency in MHz.
-- @field Core.Scheduler#SCHEDULER radiotimer Radio queue scheduler.
-- @field Core.Zone#ZONE_UNIT zoneCCA Carrier controlled area (CCA), i.e. a zone of 50 NM radius around the carrier.
-- @field Core.Zone#ZONE_UNIT zoneCCZ Carrier controlled zone (CCZ), i.e. a zone of 5 NM radius around the carrier.
-- @field #table players Table of players.
-- @field #table menuadded Table of units where the F10 radio menu was added.
-- @field #AIRBOSS.Checkpoint BreakEntry Break entry checkpoint.
-- @field #AIRBOSS.Checkpoint BreakEarly Early break checkpoint.
-- @field #AIRBOSS.Checkpoint BreakLate Late break checkpoint.
-- @field #AIRBOSS.Checkpoint Abeam Abeam checkpoint.
-- @field #AIRBOSS.Checkpoint Ninety At the ninety checkpoint.
-- @field #AIRBOSS.Checkpoint Wake Checkpoint right behind the carrier.
-- @field #AIRBOSS.Checkpoint Final Checkpoint when turning to final.
-- @field #AIRBOSS.Checkpoint Groove In the groove checkpoint.
-- @field #AIRBOSS.Checkpoint Platform Case II/III descent at 2000 ft/min at 5000 ft platform.
-- @field #AIRBOSS.Checkpoint DirtyUp Case II/III dirty up and on speed position at 1200 ft and 10-12 NM from the carrier.
-- @field #AIRBOSS.Checkpoint Bullseye Case III intercept glideslope and follow ICLS aka "bullseye".
-- @field #number defaultcase Default recovery case. This is the case used if not specified otherwise.
-- @field #number case Recovery case I, II or III currently in progress.
-- @field #table recoverytimes List of time windows when aircraft are recovered including the recovery case and holding offset.
-- @field #number defaultoffset Default holding pattern update if not specified otherwise.
-- @field #number holdingoffset Offset [degrees] of Case II/III holding pattern.
-- @field #table flights List of all flights in the CCA.
-- @field #table Qmarshal Queue of marshalling aircraft groups.
-- @field #table Qpattern Queue of aircraft groups in the landing pattern.
-- @field #table Qwaiting Queue of aircraft groups waiting outside 10 NM zone for the next free Marshal stack.
-- @field #table Qspinning Queue of aircraft currently spinning.
-- @field #table RQMarshal Radio queue of marshal.
-- @field #number TQMarshal Abs mission time, the last transmission ended.
-- @field #table RQLSO Radio queue of LSO.
-- @field #number TQLSO Abs mission time, the last transmission ended.
-- @field #number Nmaxpattern Max number of aircraft in landing pattern.
-- @field #number Nmaxmarshal Number of max Case I Marshal stacks available. Default 3, i.e. angels 2, 3 and 4.
-- @field #number NmaxSection Number of max section members (excluding the lead itself), i.e. NmaxSection=1 is a section of two.
-- @field #number NmaxStack Number of max flights per stack. Default 2.
-- @field #boolean handleai If true (default), handle AI aircraft.
-- @field Ops.RecoveryTanker#RECOVERYTANKER tanker Recovery tanker flying overhead of carrier.
-- @field DCS#Vec3 Corientation Carrier orientation in space.
-- @field DCS#Vec3 Corientlast Last known carrier orientation.
-- @field Core.Point#COORDINATE Cposition Carrier position.
-- @field #string defaultskill Default player skill @{#AIRBOSS.Difficulty}.
-- @field #boolean adinfinitum If true, carrier patrols ad infinitum, i.e. when reaching its last waypoint it starts at waypoint one again.
-- @field #number magvar Magnetic declination in degrees.
-- @field #number Tcollapse Last time timer.gettime() the stack collapsed.
-- @field #AIRBOSS.Recovery recoverywindow Current or next recovery window opened.
-- @field #boolean usersoundradio Use user sound output instead of radio transmissions.
-- @field #number Tqueue Last time in seconds of timer.getTime() the queue was updated.
-- @field #number dTqueue Time interval in seconds for updating the queues etc.
-- @field #number dTstatus Time interval for call FSM status updates.
-- @field #boolean menumarkzones If false, disables the option to mark zones via smoke or flares.
-- @field #boolean menusmokezones If false, disables the option to mark zones via smoke.
-- @field #table playerscores Table holding all player scores and grades.
-- @field #boolean autosave If true, all player grades are automatically saved to a file on disk.
-- @field #string autosavepath Path where the player grades file is saved on auto save.
-- @field #string autosavefilename File name of the auto player grades save file. Default is auto generated from carrier name/alias.
-- @field #number marshalradius Radius of the Marshal stack zone.
-- @field #boolean airbossnice Airboss is a nice guy.
-- @field #boolean staticweather Mission uses static rather than dynamic weather.
-- @field #number windowcount Running number counting the recovery windows.
-- @field #number LSOdT Time interval in seconds before the LSO will make its next call.
-- @field #string senderac Name of the aircraft acting as sender for broadcasting radio messages from the carrier. DCS shortcoming workaround.
-- @field #string radiorelayLSO Name of the aircraft acting as sender for broadcasting LSO radio messages from the carrier. DCS shortcoming workaround.
-- @field #string radiorelayMSH Name of the aircraft acting as sender for broadcasting Marhsal radio messages from the carrier. DCS shortcoming workaround.
-- @field #boolean turnintowind If true, carrier is currently turning into the wind.
-- @field #boolean detour If true, carrier is currently making a detour from its path along the ME waypoints.
-- @field Core.Point#COORDINATE Creturnto Position to return to after turn into the wind leg is over.
-- @field Core.Set#SET_GROUP squadsetAI AI groups in this set will be handled by the airboss.
-- @field Core.Set#SET_GROUP excludesetAI AI groups in this set will be explicitly excluded from handling by the airboss and not forced into the Marshal pattern.
-- @field #boolean menusingle If true, menu is optimized for a single carrier.
-- @field #number collisiondist Distance up to which collision checks are done.
-- @field #number holdtimestamp Timestamp when the carrier first came to an unexpected hold.
-- @field #number Tmessage Default duration in seconds messages are displayed to players.
-- @field #string soundfolder Folder within the mission (miz) file where airboss sound files are located.
-- @field #string soundfolderLSO Folder withing the mission (miz) file where LSO sound files are stored.
-- @field #string soundfolderMSH Folder withing the mission (miz) file where Marshal sound files are stored.
-- @field #boolean despawnshutdown Despawn group after engine shutdown.
-- @field #number Tbeacon Last time the beacons were refeshed.
-- @field #number dTbeacon Time interval to refresh the beacons. Default 5 minutes.
-- @field #AIRBOSS.LSOCalls LSOCall Radio voice overs of the LSO.
-- @field #AIRBOSS.MarshalCalls MarshalCall Radio voice over of the Marshal/Airboss.
-- @field #AIRBOSS.PilotCalls PilotCall Radio voice over from AI pilots.
-- @field #number lowfuelAI Low fuel threshold for AI groups in percent.
-- @field #boolean emergency If true (default), allow emergency landings, i.e. bypass any pattern and go for final approach.
-- @field #boolean respawnAI If true, respawn AI flights as they enter the CCA to detach and airfields from the mission plan. Default false.
-- @field #boolean turning If true, carrier is currently turning.
-- @field #AIRBOSS.GLE gle Glidesope error thresholds.
-- @field #AIRBOSS.LUE lue Lineup error thresholds.
-- @field #boolean trapsheet If true, players can save their trap sheets.
-- @field #string trappath Path where to save the trap sheets.
-- @field #string trapprefix File prefix for trap sheet files.
-- @field #number initialmaxalt Max altitude in meters to register in the inital zone.
-- @field #boolean welcome If true, display welcome message to player.
-- @field #boolean skipperMenu If true, add skipper menu.
-- @field #number skipperSpeed Speed in knots for manual recovery start.
-- @field #number skipperCase Manual recovery case.
-- @field #boolean skipperUturn U-turn on/off via menu.
-- @field #number skipperOffset Holding offset angle in degrees for Case II/III manual recoveries.
-- @field #number skipperTime Recovery time in min for manual recovery.
-- @extends Core.Fsm#FSM

--- Be the boss!
--
-- ===
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Main.png)
--
-- # The AIRBOSS Concept
--
-- On a carrier, the AIRBOSS is guy who is really in charge - don't mess with him!
--
-- # Recovery Cases
--
-- The AIRBOSS class supports all three commonly used recovery cases, i.e.
--
--    * **CASE I** during daytime and good weather (ceiling > 3000 ft, visibility > 5 NM),
--    * **CASE II** during daytime but poor visibility conditions (ceiling > 1000 ft, visibility > 5NM),
--    * **CASE III** when below Case II conditions and during nighttime (ceiling < 1000 ft, visibility < 5 NM).
--
-- That being said, this script allows you to use any of the three cases to be used at any time. Or, in other words, *you* need to specify when which case is safe and appropriate.
--
-- This is a lot of responsibility. *You* are the boss, but *you* need to make the right decisions or things will go terribly wrong!
--
-- Recovery windows can be set up via the @{#AIRBOSS.AddRecoveryWindow} function as explained below. With this it is possible to seamlessly (within reason!) switch recovery cases in the same mission.
--
-- ## CASE I
--
-- As mentioned before, Case I recovery is the standard procedure during daytime and good visibility conditions.
--
-- ### Holding Pattern
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Case1_Holding.png)
--
-- The graphic depicts a the standard holding pattern during a Case I recovery. Incoming aircraft enter the holding pattern, which is a counter clockwise turn with a
-- diameter of 5 NM, at their assigned altitude. The holding altitude of the first stack is 2000 ft. The interval between stacks is 1000 ft.
--
-- Once a recovery window opens, the aircraft of the lowest stack commence their landing approach and the rest of the Marshal stack collapses, i.e. aircraft switch from
-- their current stack to the next lower stack.
--
-- The flight that transitions form the holding pattern to the landing approach, it should leave the Marshal stack at the 3 position and make a left hand turn to the *Initial*
-- position, which is 3 NM astern of the boat. Note that you need to be below 1300 feet to be registered in the initial zone.
-- The altitude can be set via the function @{#AIRBOSS.SetInitialMaxAlt}(*altitude*) function.
-- As described below, the initial zone can be smoked or flared via the AIRBOSS F10 Help radio menu.
--
-- ### Landing Pattern
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Case1_Landing.png)
--
-- Once the aircraft reaches the Initial, the landing pattern begins. The important steps of the pattern are shown in the image above.
-- The AV-8B Harrier pattern is very similar, the only differences are as there is no angled deck there is no wake check. from the ninety you wil fly a straight approach offset 26 ft to port (left) of the tram line.
-- The aim is to arrive abeam the landing spot in a stable hover at 120 ft with forward speed matched to the boat. From there the LSO will call "cleared to land". You then level cross to the tram line at the designated landing spot at land vertcally. When you stabalise over the landing spot LSO will call Stabalise to indicate you are centered at the correct spot.
--
-- ## CASE III
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Case3.png)
--
-- A Case III recovery is conducted during nighttime or when the visibility is below CASE II minima during the day. The holding position and the landing pattern are rather different from a Case I recovery as can be seen in the image above.
--
-- The first holding zone starts 21 NM astern the carrier at angels 6. The separation between the stacks is 1000 ft just like in Case I. However, the distance to the boat
-- increases by 1 NM with each stack. The general form can be written as D=15+6+(N-1), where D is the distance to the boat in NM and N the number of the stack starting at N=1.
--
-- Once the aircraft of the lowest stack is allowed to commence to the landing pattern, it starts a descent at 4000 ft/min until it reaches the "*Platform*" at 5000 ft and
-- ~19 NM DME. From there a shallower descent at 2000 ft/min should be performed. At an altitude of 1200 ft the aircraft should level out and "*Dirty Up*" (gear, flaps & hook down).
--
-- At 3 NM distance to the carrier, the aircraft should intercept the 3.5 degrees glideslope at the "*Bullseye*". From there the pilot should "follow the needles" of the ICLS.
--
-- ## CASE II
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Case2.png)
--
-- Case II is the common recovery procedure at daytime if visibility conditions are poor. It can be viewed as hybrid between Case I and III.
-- The holding pattern is very similar to that of the Case III recovery with the difference the the radial is the inverse of the BRC instead of the FB.
-- From the holding zone aircraft are follow the Case III path until they reach the Initial position 3 NM astern the boat. From there a standard Case I recovery procedure is
-- in place.
--
-- Note that the image depicts the case, where the holding zone has an angle offset of 30 degrees with respect to the BRC. This is optional. Commonly used offset angels
-- are 0 (no offset), +-15 or +-30 degrees. The AIRBOSS class supports all these scenarios which are used during Case II and III recoveries.
--
-- ===
--
-- # The F10 Radio Menu
--
-- The F10 radio menu can be used to post requests to Marshal but also provides information about the player and carrier status. Additionally, helper functions
-- can be called.
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuMain.png)
--
-- By default, the script creates a submenu "Airboss" in the "F10 Other ..." menu and each @{#AIRBOSS} carrier gets its own submenu.
-- If you intend to have only one carrier, you can simplify the menu structure using the @{#AIRBOSS.SetMenuSingleCarrier} function, which will create all carrier specific menu entries directly
-- in the "Airboss" submenu. (Needless to say, that if you enable this and define multiple carriers, the menu structure will get completely screwed up.)
--
-- ## Root Menu
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuRoot.png)
--
-- The general structure
--
--    * **F1 Help...**  (Help submenu, see below.)
--    * **F2 Kneeboard...** (Kneeboard submenu, see below. Carrier information, weather report, player status.)
--    * **F3 Request Marshal**
--    * **F4 Request Commence**
--    * **F5 Request Refueling**
--    * **F6 Spinning**
--    * **F7 Emergency Landing**
--    * **F8 [Reset My Status]**
--
-- ### Request Marshal
--
-- This radio command can be used to request a stack in the holding pattern from Marshal. Necessary conditions are that the flight is inside the Carrier Controlled Area (CCA)
-- (see @{#AIRBOSS.SetCarrierControlledArea}).
--
-- Marshal will assign an individual stack for each player group depending on the current or next open recovery case window.
-- If multiple players have registered as a section, the section lead will be assigned a stack and is responsible to guide his section to the assigned holding position.
--
-- ### Request Commence
--
-- This command can be used to request commencing from the marshal stack to the landing pattern. Necessary condition is that the player is in the lowest marshal stack
-- and that the number of aircraft in the landing pattern is smaller than four (or the number set by the mission designer).
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Case1Pattern.png)
--
-- The image displays the standard Case I Marshal pattern recovery. Pilots are supposed to fly a clockwise circle and descent between the **3** and **1** positions.
--
-- Commence should be performed at around the **3** position. If the pilot is in the lowest Marshal stack, and flies through this area, he is automatically cleared for the
-- landing pattern. In other words, there is no need for the "Request Commence" radio command. The zone can be marked via smoke or flared using the player's F10 radio menu.
--
-- A player can also request commencing if he is not registered in a marshal stack yet. If the pattern is free, Marshal will allow him to directly enter the landing pattern.
-- However, this is only possible when the Airboss has a nice day - see @{#AIRBOSS.SetAirbossNiceGuy}.
--
-- ### Request Refueling
--
-- If a recovery tanker has been set up via the @{#AIRBOSS.SetRecoveryTanker}, the player can request refueling at any time. If currently in the marshal stack, the stack above will collapse.
-- The player will be informed if the tanker is currently busy or going RTB to refuel itself at its home base. Once the re-fueling is complete, the player has to re-register to the marshal stack.
--
-- ### Spinning
--
-- If the pattern is full, players can go into the spinning pattern. This step is only allowed, if the player is in the pattern and his next step
-- is initial, break entry, early/late break. At this point, the player should climb to 1200 ft a fly on the port side of the boat to go back to the initial again.
--
-- If a player is in the spin pattern, flights in the Marshal queue should hold their altitude and are not allowed into the pattern until the spinning aircraft
-- proceeds.
--
-- Once the player reaches a point 100 meters behind the boat and at least 1 NM port, his step is set to "Initial" and he can resume the normal pattern approach.
--
-- If necessary, the player can call "Spinning" again when in the above mentioned steps.
--
-- ### Emergency Landing
--
-- Request an emergency landing, i.e. bypass all pattern steps and go directly to the final approach.
--
-- All section members are supposed to follow. Player (or section lead) is removed from all other queues and automatically added to the landing pattern queue.
--
-- If this command is called while the player is currently on the carrier, he will be put in the bolter pattern. So the next expected step after take of
-- is the abeam position. This allows for quick landing training exercises without having to go through the whole pattern.
--
-- The mission designer can forbid this option my setting @{#AIRBOSS.SetEmergencyLandings}(false) in the script.
--
-- ### [Reset My Status]
--
-- This will reset the current player status. If player is currently in a marshal stack, he will be removed from the marshal queue and the stack above will collapse.
-- The player needs to re-register later if desired. If player is currently in the landing pattern, he will be removed from the pattern queue.
--
-- ## Help Menu
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuHelp.png)
--
-- This menu provides commands to help the player.
--
-- ### Mark Zones Submenu
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuMarkZones.png)
--
-- These commands can be used to mark marshal or landing pattern zones.
--
--    * **Smoke Pattern Zones** Smoke is used to mark the landing pattern zone of the player depending on his recovery case.
--    For Case I this is the initial zone. For Case II/III and three these are the Platform, Arc turn, Dirty Up, Bullseye/Initial zones as well as the approach corridor.
--    * **Flare Pattern Zones** Similar to smoke but uses flares to mark the pattern zones.
--    * **Smoke Marshal Zone** This smokes the surrounding area of the currently assigned Marshal zone of the player. Player has to be registered in Marshal queue.
--    * **Flare Marshal Zone** Similar to smoke but uses flares to mark the Marshal zone.
--
-- Note that the smoke lasts ~5 minutes but the zones are moving along with the carrier. So after some time, the smoke gives shows you a picture of the past.
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_Case3_FlarePattern.png)
--
-- ### Skill Level Submenu
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuSkill.png)
--
-- The player can choose between three skill or difficulty levels.
--
--    * **Flight Student**: The player receives tips at certain stages of the pattern, e.g. if he is at the right altitude, speed, etc.
--    * **Naval Aviator**: Less tips are show. Player should be familiar with the procedures and its aircraft parameters.
--    * **TOPGUN Graduate**: Only very few information is provided to the player. This is for the pros.
--    * **Hints On/Off**: Toggle displaying hints.
--
-- ### My Status
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuMyStatus.png)
--
-- This command provides information about the current player status. For example, his current step in the pattern.
--
-- ### Attitude Monitor
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuAttitudeMonitor.png)
--
-- This command displays the current aircraft attitude of the player aircraft in short intervals as message on the screen.
-- It provides information about current pitch, roll, yaw, orientation of the plane with respect to the carrier's orientation (*Gamma*) etc.
--
-- If you are in the groove, current lineup and glideslope errors are displayed and you get an on-the-fly LSO grade.
--
-- ### LSO Radio Check
--
-- LSO will transmit a short message on his radio frequency. See @{#AIRBOSS.SetLSORadio}. Note that in the A-4E you will not hear the message unless you are in the pattern.
--
-- ### Marshal Radio Check
--
-- Marshal will transmit a short message on his radio frequency. See @{#AIRBOSS.SetMarshalRadio}.
--
-- ### Subtitles On/Off
--
-- This command toggles the display of radio message subtitles if no radio relay unit is used. By default subtitles are on.
-- Note that subtitles for radio messages which do not have a complete voice over are always displayed.
--
-- ### Trapsheet On/Off
--
-- Each player can activated or deactivate the recording of his flight data (AoA, glideslope, lineup, etc.) during his landing approaches.
-- Note that this feature also has to be enabled by the mission designer.
--
-- ## Kneeboard Menu
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuKneeboard.png)
--
-- The Kneeboard menu provides information about the carrier, weather and player results.
--
-- ### Results Submenu
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuResults.png)
--
-- Here you find your LSO grading results as well as scores of other players.
--
--    * **Greenie Board** lists average scores of all players obtained during landing approaches.
--    * **My LSO Grades** lists all grades the player has received for his approaches in this mission.
--    * **Last Debrief** shows the detailed debriefing of the player's last approach.
--
-- ### Carrier Info
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuCarrierInfo.png)
--
-- Information about the current carrier status is displayed. This includes current BRC, FB, LSO and Marshal frequencies, list of next recovery windows.
--
-- ### Weather Report
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuWeatherReport.png)
--
-- Displays information about the current weather at the carrier such as QFE, wind and temperature.
--
-- For missions using static weather, more information such as cloud base, thickness, precipitation, visibility distance, fog and dust are displayed.
-- If your mission uses dynamic weather, you can disable this output via the @{#AIRBOSS.SetStaticWeather}(**false**) function.
--
-- ### Set Section
--
-- With this command, you can define a section of human flights. The player who issues the command becomes the section lead and all other human players
-- within a radius of 100 meters become members of the section.
--
-- The responsibilities of the section leader are:
--
--    * To request Marshal. The section members are not allowed to do this and have to follow the lead to his assigned stack.
--    * To lead the right way to the pattern if the flight is allowed to commence.
--    * The lead is also the only one who can request commence if the flight wants to bypass the Marshal stack.
--
-- Each time the command is issued by the lead, the complete section is set up from scratch. Members which are not inside the 100 m radius any more are
-- removed and/or new members which are now in range are added.
--
-- If a section member issues this command, it is removed from the section of his lead. All flights which are not yet in another section will become members.
--
-- The default maximum size of a section is two human players. This can be adjusted by the @{#AIRBOSS.SetMaxSectionSize}(*size*) function. The maximum allowed size
-- is four.
--
-- ### Marshal Queue
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuMarshalQueue.png)
--
-- Lists all flights currently in the Marshal queue including their assigned stack, recovery case and Charlie time estimate.
-- By default, the number of available Case I stacks is three, i.e. at angels 2, 3 and 4. Usually, the recovery thanker orbits at angels 6.
-- The number of available stacks can be set by the @{#AIRBOSS.SetMaxMarshalStack} function.
--
-- The default number of human players per stack is two. This can be set via the @{#AIRBOSS.SetMaxFlightsPerStack} function but has to be between one and four.
--
-- Due to technical reasons, each AI group always gets its own stack. DCS does not allow to control the AI in a manner that more than one group per stack would make sense unfortunately.
--
-- ### Pattern Queue
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_MenuPatternQueue.png)
--
-- Lists all flights currently in the landing pattern queue showing the time since they entered the pattern.
-- By default, a maximum of four flights is allowed to enter the pattern. This can be set via the @{#AIRBOSS.SetMaxLandingPattern} function.
--
-- ### Waiting Queue
--
-- Lists all flights currently waiting for a free Case I Marshal stack. Note, stacks are limited only for Case I recovery ops but not for Case II or III.
-- If the carrier is switches recovery ops form Case I to Case II or III, all waiting flights will be assigned a stack.
--
-- # Landing Signal Officer (LSO)
--
-- The LSO will first contact you on his radio channel when you are at the the abeam position (Case I) with the phrase "Paddles, contact.".
-- Once you are in the groove the LSO will ask you to "Call the ball." and then acknowledge your ball call by "Roger Ball."
--
-- During the groove the LSO will give you advice if you deviate from the correct landing path. These advices will be given when you are
--
--    * too low or too high with respect to the glideslope,
--    * too fast or too slow with respect to the optimal AoA,
--    * too far left or too far right with respect to the lineup of the (angled) runway.
--
-- ## LSO Grading
--
-- LSO grading starts when the player enters the groove. The flight path and aircraft attitude is evaluated at certain steps (distances measured from rundown):
--
--    * **X** At the Start (0.75 NM = 1390 m).
--    * **IM** In the Middle (0.5 NM = 926 m), middle one third of the glideslope.
--    * **IC** In Close (0.25 NM = 463 m), last one third of the glideslope.
--    * **AR** At the Ramp (0.027 NM = 50 m).
--    * **IW** In the Wires (at the landing position).
--
-- Grading at each step includes the above calls, i.e.
--
--    * **L**ined **U**p **L**eft or **R**ight: LUL, LUR
--    * Too **H**igh or too **LO**w: H, LO
--    * Too **F**ast or too **SLO**w: F, SLO
--    * **O**ver**S**hoot: OS, only referenced during **X**
--    * **Fly through** glideslope **down** or **up**: \\ , /, advisory only
--    * **D**rift **L**eft or **R**ight:DL, DR, advisory only
--    * **A**ngled **A**pproach: Angled approach (wings level and LUL): AA, advisory only
--
-- Each grading, x, is subdivided by
--
--    * (x): parenthesis, indicating "a little" for a minor deviation and
--    * \_x\_: underline, indicating "a lot" for major deviations.
--
-- The position at the landing event is analyzed and the corresponding trapped wire calculated. If no wire was caught, the LSO will give the bolter call.
--
-- If a player is significantly off from the ideal parameters from IC to AR, the LSO will wave the player off. Thresholds for wave off are
--
--    * Line up error > 3.0 degrees left or right and/or
--    * Glideslope error < -1.2 degrees or > 1.8 degrees and/or
--    * AOA depending on aircraft type and only applied if skill level is "TOPGUN graduate".
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_LSOPlatcam.png)
--
-- Line up and glideslope error thresholds were tested extensively using [VFA-113 Stingers LSO Mod](https://forums.eagle.ru/showthread.php?t=211557),
-- if the aircraft is outside the red box. In the picture above, **blue** numbers denote the line up thresholds while the **blacks** refer to the glideslope.
--
-- A wave off is called, when the aircraft is outside the red rectangle. The measurement stops already ~50 m before the rundown, since the error in the calculation
-- increases the closer the aircraft gets to the origin/reference point.
--
-- The optimal glideslope is assumed to be 3.5 degrees leading to a touch down point between the second and third wire.
-- The height of the carrier deck and the exact wire locations are taken into account in the calculations.
--
-- ## Pattern Waveoff
--
-- The player's aircraft position is evaluated at certain critical locations in the landing pattern. If the player is far off from the ideal approach, the LSO will
-- issue a pattern wave off. Currently, this is only implemented for Case I recoveries and the Case I part in the Case II recovery, i.e.
--
--    * Break Entry
--    * Early Break
--    * Late Break
--    * Abeam
--    * Ninety
--    * Wake
--    * Groove
--
-- At these points it is also checked if a player comes too close to another aircraft ahead of him in the pattern.
--
-- ## Grading Points
--
-- Currently grades are given by as follows
--
--    * 5.0 Points **\_OK\_**: "Okay underline", given only for a perfect pass, i.e. when no deviations at all were observed by the LSO. The unicorn!
--    * 4.0 Points **OK**: "Okay pass" when only minor () deviations happened.
--    * 3.0 Points **(OK)**: "Fair pass", when only "normal" deviations were detected.
--    * 2.0 Points **--**: "No grade", for larger deviations.
--
-- Furthermore, we have the cases:
--
--    * 2.5 Points **B**: "Bolter", when the player landed but did not catch a wire.
--    * 2.0 Points **WOP**: "Pattern Wave-Off", when pilot was far away from where he should be in the pattern.
--    * 2.0 Points **OWO**: "Own Wave-Off**, when pilot flies past the deck without touching it.
--    * 1.0 Points **WO**: "Technique Wave-Off": Player got waved off in the final parts of the groove.
--    * 1.0 Points **LIG**: "Long In the Groove", when pilot extents the downwind leg too far and screws up the timing for the following aircraft.
--    * 0.0 Points **CUT**: "Cut pass", when player was waved off but landed anyway. In addition if a V/STOL lands without having been Cleared to Land.
--
-- ## Foul Deck Waveoff
--
-- A foul deck waveoff is called by the LSO if an aircraft is detected within the landing area when an approaching aircraft is at position IM-IC during Case I/II operations,
-- or with an aircraft approaching the 3/4 NM during Case III operations.
--
-- The approaching aircraft will be notified via LSO radio comms and is supposed to overfly the landing area to enter the Bolter pattern. **This pass is not graded**.
--
-- ===
--
-- # Scripting
--
-- Writing a basic script is easy and can be done in two lines.
--
--     local airbossStennis=AIRBOSS:New("USS Stennis", "Stennis")
--     airbossStennis:Start()
--
-- The **first line** creates and AIRBOSS object via the @{#AIRBOSS.New}(*carriername*, *alias*) constructor. The first parameter *carriername* is name of the carrier unit as
-- defined in the mission editor. The second parameter *alias* is optional. This name will, e.g., be used for the F10 radio menu entry. If not given, the alias is identical
-- to the *carriername* of the first parameter.
--
-- This simple script initializes a lot of parameters with default values:
--
--    * TACAN channel is set to 74X, see @{#AIRBOSS.SetTACAN},
--    * ICSL channel is set to 1, see @{#AIRBOSS.SetICLS},
--    * LSO radio is set to 264 MHz FM, see @{#AIRBOSS.SetLSORadio},
--    * Marshal radio is set to 305 MHz FM, see @{#AIRBOSS.SetMarshalRadio},
--    * Default recovery case is set to 1, see @{#AIRBOSS.SetRecoveryCase},
--    * Carrier Controlled Area (CCA) is set to 50 NM, see @{#AIRBOSS.SetCarrierControlledArea},
--    * Default player skill "Flight Student" (easy), see @{#AIRBOSS.SetDefaultPlayerSkill},
--    * Once the carrier reaches its final waypoint, it will restart its route, see @{#AIRBOSS.SetPatrolAdInfinitum}.
--
-- The **second line** starts the AIRBOSS class. If you set options this should happen after the @{#AIRBOSS.New} and before @{#AIRBOSS.Start} command.
--
-- However, good mission planning involves also planning when aircraft are supposed to be launched or recovered. The definition of *case specific* recovery ops within the same mission is described in
-- the next section.
--
-- ## Recovery Windows
--
-- Recovery of aircraft is only allowed during defined time slots. You can define these slots via the @{#AIRBOSS.AddRecoveryWindow}(*start*, *stop*, *case*, *holdingoffset*) function.
-- The parameters are:
--
--   * *start*: The start time as a string. For example "8:00" for a window opening at 8 am. Or "13:30+1" for half past one on the next day. Default (nil) is ASAP.
--   * *stop*: Time when the window closes as a string. Same format as *start*. Default is 90 minutes after start time.
--   * *case*: The recovery case during that window (1, 2 or 3). Default 1.
--   * *holdingoffset*: Holding offset angle in degrees. Only for Case II or III recoveries. Default 0 deg. Common +-15 deg or +-30 deg.
--
-- If recovery is closed, AI flights will be send to marshal stacks and orbit there until the next window opens.
-- Players can request marshal via the F10 menu and will also be given a marshal stack. Currently, human players can request commence via the F10 radio regardless of
-- whether a window is open or not and will be allowed to enter the pattern (if not already full). This will probably change in the future.
--
-- At the moment there is no automatic recovery case set depending on weather or daytime. So it is the AIRBOSS (i.e. you as mission designer) who needs to make that decision.
-- It is probably a good idea to synchronize the timing with the waypoints of the carrier. For example, setting up the waypoints such that the carrier
-- already has turning into the wind, when a recovery window opens.
--
-- The code for setting up multiple recovery windows could look like this
--     local airbossStennis=AIRBOSS:New("USS Stennis", "Stennis")
--     airbossStennis:AddRecoveryWindow("8:30", "9:30", 1)
--     airbossStennis:AddRecoveryWindow("12:00", "13:15", 2, 15)
--     airbossStennis:AddRecoveryWindow("23:30", "00:30+1", 3, -30)
--     airbossStennis:Start()
--
-- This will open a Case I recovery window from 8:30 to 9:30. Then a Case II recovery from 12:00 to 13:15, where the holing offset is +15 degrees wrt BRC.
-- Finally, a Case III window opens 23:30 on the day the mission starts and closes 0:30 on the following day. The holding offset is -30 degrees wrt FB.
--
-- Note that incoming flights will be assigned a holding pattern for the next opening window case if no window is open at the moment. So in the above example,
-- all flights incoming after 13:15 will be assigned to a Case III marshal stack. Therefore, you should make sure that no flights are incoming long before the
-- next window opens or adjust the recovery planning accordingly.
--
-- The following example shows how you set up a recovery window for the next week:
--
--     for i=0,7 do
--        airbossStennis:AddRecoveryWindow(string.format("08:05:00+%d", i), string.format("08:50:00+%d", i))
--     end
--
-- ### Turning into the Wind
--
-- For each recovery window, you can define if the carrier should automatically turn into the wind. This is done by passing one or two additional arguments to the @{#AIRBOSS.AddRecoveryWindow} function:
--
--     airbossStennis:AddRecoveryWindow("8:30", "9:30", 1, nil, true, 20)
--
-- Setting the fifth parameter to *true* enables the automatic turning into the wind. The sixth parameter (here 20) specifies the speed in knots the carrier will go so that to total wind above the deck
-- corresponds to this wind speed. For example, if the is blowing with 5 knots, the carrier will go 15 knots so that the total velocity adds up to the specified 20 knots for the pilot.
--
-- The carrier will steam into the wind for as long as the recovery window is open. The distance up to which possible collisions are detected can be set by the @{#AIRBOSS.SetCollisionDistance} function.
--
-- However, the AIRBOSS scans the type of the surface up to 5 NM in the direction of movement of the carrier. If he detects anything but deep water, he will stop the current course and head back to
-- the point where he initially turned into the wind.
--
-- The same holds true after the recovery window closes. The carrier will head back to the place where he left its assigned route and resume the path to the next waypoint defined in the mission editor.
--
-- Note that the carrier will only head into the wind, if the wind direction is different by more than 5° from the current heading of the carrier (the angled runway, if any, fis taken into account here).
--
-- ===
--
-- # Persistence of Player Results
--
-- LSO grades of players can be saved to disk and later reloaded when a new mission is started.
--
-- ## Prerequisites
--
-- **Important** By default, DCS does not allow for writing data to files. Therefore, one first has to comment out the line "sanitizeModule('io')" and "sanitizeModule('lfs')", i.e.
--
--     do
--       sanitizeModule('os')
--       --sanitizeModule('io')    -- required for saving files
--       --sanitizeModule('lfs')   -- optional for setting the default path to your "Saved Games\DCS" folder
--       require = nil
--       loadlib = nil
--     end
--
-- in the file "MissionScripting.lua", which is located in the subdirectory "Scripts" of your DCS installation root directory.
--
-- **WARNING** Desanitizing the "io" and "lfs" modules makes your machine or server vulnerable to attacks from the outside! Use this at your own risk.
--
-- ## Save Results
--
-- Saving asset data to file is achieved by the @{#AIRBOSS.Save}(*path*, *filename*) function.
--
-- The parameter *path* specifies the path on the file system where the
-- player grades are saved. If you do not specify a path, the file is saved your the DCS installation root directory if the **lfs** module is *not* desanizied or
-- your "Saved Games\\DCS" folder in case you did desanitize the **lfs** module.
--
-- The parameter *filename* is optional and defines the name of the saved file. By default this is automatically created from the AIRBOSS carrier name/alias, i.e.
-- "Airboss-USS Stennis_LSOgrades.csv", if the alias is "USS Stennis".
--
-- In the easiest case, you desanitize the **io** and **lfs** modules and just add the line
--
--     airbossStennis:Save()
--
-- If you want to specify an explicit path you can do this by
--
--     airbossStennis:Save("D:\\My Airboss Data\\")
--
-- This will save all player grades to in "D:\\My Airboss Data\\Airboss-USS Stennis_LSOgrades.csv".
--
-- ### Automatic Saving
--
-- The player grades can be saved automatically after each graded player pass via the @{#AIRBOSS.SetAutoSave}(*path*, *filename*) function. Again the parameters *path* and *filename* are optional.
-- In the simplest case, you desanitize the **lfs** module and just add
--
--     airbossStennis:SetAutoSave()
--
-- Note that the the stats are saved after the *final* grade has been given, i.e. the player has landed on the carrier. After intermediate results such as bolters or waveoffs the stats are not automatically saved.
--
-- In case you want to specify an explicit path, you can write
--
--     airbossStennis:SetAutoSave("D:\\My Airboss Data\\")
--
-- ## Results Output
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_PersistenceResultsTable.png)
--
-- The results file is stored as comma separated file. The columns are
--
--    * *Name*: The player name.
--    * *Pass*: A running number counting the passes of the player
--    * *Points Final*: The final points (i.e. when the player has landed). This is the average over all previous bolters or waveoffs, if any.
--    * *Points Pass*: The points of each pass including bolters and waveoffs.
--    * *Grade*: LSO grade.
--    * *Details*: Detailed analysis of deviations within the groove.
--    * *Wire*: Trapped wire, if any.
--    * *Tgroove*: Time in the groove in seconds (not applicable during Case III).
--    * *Case*: The recovery case operations in progress during the pass.
--    * *Wind*: Wind on deck in knots during approach.
--    * *Modex*: Tail number of the player.
--    * *Airframe*: Aircraft type used in the recovery.
--    * *Carrier Type*: Type name of the carrier.
--    * *Carrier Name*: Name/alias of the carrier.
--    * *Theatre*: DCS map.
--    * *Mission Time*: Mission time at the end of the approach.
--    * *Mission Date*: Mission date in yyyy/mm/dd format.
--    * *OS Date*: Real life date from os.date(). Needs **os** to be desanitized.
--
-- ## Load Results
--
-- Loading player grades from file is achieved by the @{#AIRBOSS.Load}(*path*, *filename*) function. The parameter *path* specifies the path on the file system where the
-- data is loaded from. If you do not specify a path, the file is loaded from your the DCS installation root directory or, if **lfs** was desanitized from you "Saved Games\DCS" directory.
-- The parameter *filename* is optional and defines the name of the file to load. By default this is automatically generated from the AIBOSS carrier name/alias, for example
-- "Airboss-USS Stennis_LSOgrades.csv".
--
-- Note that the AIRBOSS FSM **must not be started** in order to load the data. In other words, loading should happen **after** the
-- @{#AIRBOSS.New} command is specified in the code but **before** the @{#AIRBOSS.Start} command is given.
--
-- The easiest was to load player results is
--
--     airbossStennis:New("USS Stennis")
--     airbossStennis:Load()
--     airbossStennis:SetAutoSave()
--     -- Additional specification of parameters such as recovery windows etc, if required.
--     airbossStennis:Start()
--
-- This sequence loads all available player grades from the default file and automatically saved them when a player received a (final) grade. Again, if **lfs** was desanitized, the files are save to and loaded
-- from the "Saved Games\DCS" directory. If **lfs** was *not* desanitized, the DCS root installation folder is the default path.
--
-- # Trap Sheet
--
-- Important aircraft attitude parameters during the Groove can be saved to file for later analysis. This also requires the **io** and optionally **lfs** modules to be desanitized.
--
-- In the script you have to add the @{#AIRBOSS.SetTrapSheet}(*path*) function to activate this feature.
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_TrapSheetTable.png)
--
-- Data the is written to a file in csv format and contains the following information:
--
--    * *Time*: time in seconds since start.
--    * *Rho*: distance from rundown to player aircraft in NM.
--    * *X*: distance parallel to the carrier in meters.
--    * *Z*: distance perpendicular to the carrier in meters.
--    * *Alt*: altitude of player aircraft in feet.
--    * *AoA*: angle of attack in degrees.
--    * *GSE*: glideslope error in degrees.
--    * *LUE*: lineup error in degrees.
--    * *Vtot*: total velocity of player aircraft in knots.
--    * *Vy*: vertical (descent) velocity in ft/min.
--    * *Gamma*: angle between vector of aircraft nose and vector point in the direction of the carrier runway in degrees.
--    * *Pitch*: pitch angle of player aircraft in degrees.
--    * *Roll*: roll angle of player aircraft in degrees.
--    * *Yaw*: yaw angle of player aircraft in degrees.
--    * *Step*: Step in the groove.
--    * *Grade*: Current LSO grade.
--    * *Points*: Current points for the pass.
--    * *Details*: Detailed grading analysis.
--
-- ## Lineup Error
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_TrapSheetLUE.png)
--
-- The graph displays the lineup error (LUE) as a function of the distance to the carrier.
--
-- The pilot approaches the carrier from the port side, LUE>0°, at a distance of ~1 NM.
-- At the beginning of the groove (X), he significantly overshoots to the starboard side (LUE<5°).
-- In the middle (IM), he performs good corrections and smoothly reduces the lineup error.
-- Finally, at a distance of ~0.3 NM (IC) he has corrected his lineup with the runway to a reasonable level, |LUE|<0.5°.
--
-- ## Glideslope Error
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_TrapSheetGLE.png)
--
-- The graph displays the glideslope error (GSE) as a function of the distance to the carrier.
--
-- In this case the pilot already enters the groove (X) below the optimal glideslope. He is not able to correct his height in the IM part and
-- stays significantly too low. In close, he performs a harsh correction to gain altitude and ends up even slightly too high (GSE>0.5°).
-- At his point further corrections are necessary.
--
-- ## Angle of Attack
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_TrapSheetAoA.png)
--
-- The graph displays the angle of attack (AoA) as a function of the distance to the carrier.
--
-- The pilot starts off being on speed after the ball call. Then he get way to fast troughout the most part of the groove. He manages to correct
-- this somewhat short before touchdown.
--
-- ===
--
-- # Sound Files
--
-- An important aspect of the AIRBOSS is that it uses voice overs for greater immersion. The necessary sound files can be obtained from the
-- MOOSE Discord in the [#ops-airboss](https://discordapp.com/channels/378590350614462464/527363141185830915) channel. Check out the **pinned messages**.
--
-- However, including sound files into a new mission is tedious as these usually need to be included into the mission **miz** file via (unused) triggers.
--
-- The default location inside the miz file is "l10n/DEFAULT/". But simply opening the *miz* file with e.g. [7-zip](https://www.7-zip.org/) and copying the files into that folder does not work.
-- The next time the mission is saved, files not included via trigger are automatically removed by DCS.
--
-- However, if you create a new folder inside the miz file, which contains the sounds, it will not be deleted and can be used. The location of the sound files can be specified
-- via the @{#AIRBOSS.SetSoundfilesFolder}(*folderpath*) function. The parameter *folderpath* defines the location of the sound files folder within the mission *miz* file.
--
-- ![Banner Image](..\Presentations\AIRBOSS\Airboss_SoundfilesFolder.png)
--
-- For example as
--
--     airbossStennis:SetSoundfilesFolder("Airboss Soundfiles/")
--
-- ## Carrier Specific Voice Overs
--
-- It is possible to use different sound files for different carriers. If you have set up two (or more) AIRBOSS objects at different carriers - say Stennis and Tarawa - each
-- carrier would use the files in the specified directory, e.g.
--
--     airbossStennis:SetSoundfilesFolder("Airboss Soundfiles Stennis/")
--     airbossTarawa:SetSoundfilesFolder("Airboss Soundfiles Tarawa/")
--
-- ## Sound Packs
--
-- The AIRBOSS currently has two different "sound packs" for LSO and three different "sound Packs" for Marshal radios. These contain voice overs by different actors.
-- These can be set by @{#AIRBOSS.SetVoiceOversLSOByRaynor}() and @{#AIRBOSS.SetVoiceOversMarshalByRaynor}(). These are the default settings.
-- The other sound files can be set by @{#AIRBOSS.SetVoiceOversLSOByFF}(), @{#AIRBOSS.SetVoiceOversMarshalByGabriella}() and @{#AIRBOSS.SetVoiceOversMarshalByFF}().
-- Also combinations can be used, e.g.
--
--     airbossStennis:SetVoiceOversLSOByFF()
--     airbossStennis:SetVoiceOversMarshalByRaynor()
--
-- In this example LSO voice overs by FF and Marshal voice overs by Raynor are used.
--
-- **Note** that this only initializes the correct parameters parameters of sound files, i.e. the duration. The correct files have to be in the directory set by the
-- @{#AIRBOSS.SetSoundfilesFolder}(*folder*) function.
--
-- ## How To Use Your Own Voice Overs
--
-- If you have a set of AIRBOSS sound files recorded or got it from elsewhere it is possible to use those instead of the default ones.
-- I recommend to use exactly the same file names as the original sound files have.
--
-- However, the **timing is critical**! As sometimes sounds are played directly after one another, e.g. by saying the modex but also on other occations, the airboss
-- script has a radio queue implemented (actually two - one for the LSO and one for the Marshal/Airboss radio).
-- By this it is automatically taken care that played messages are not overlapping and played over each other. The disadvantage is, that the script needs to know
-- the exact duration of *each* voice over. For the default sounds this is hard coded in the source code. For your own files, you need to give that bit of information
-- to the script via the @{#AIRBOSS.SetVoiceOver}(**radiocall**, **duration**, **subtitle**, **subduration**, **filename**, **suffix**) function. Only the first two
-- parameters **radiocall** and **duration** are usually important to adjust here.
--
-- For example, if you want to change the LSO "Call the Ball" and "Roger Ball" calls:
--
--     airbossStennis:SetVoiceOver(airbossStennis.LSOCall.CALLTHEBALL, 0.6)
--     airbossStennis:SetVoiceOver(airbossStennis.LSOCall.ROGERBALL, 0.7)
--
-- Again, changing the file name, subtitle, subtitle duration is not required if you name the file exactly like the original one, which is this case would be "LSO-RogerBall.ogg".
--
-- ## The Radio Dilemma
--
-- DCS offers two (actually three) ways to send radio messages. Each one has its advantages and disadvantages and it is important to understand the differences.
--
-- ### Transmission via Command
--
-- *In principle*, the best way to transmit messages is via the [TransmitMessage](https://wiki.hoggitworld.com/view/DCS_command_transmitMessage) command.
-- This method has the advantage that subtitles can be used and these subtitles are only displayed to the players who dialed in the same radio frequency as
-- used for the transmission.
-- However, this method unfortunately only works if the sending unit is an **aircraft**. Therefore, it is not usable by the AIRBOSS per se as the transmission comes from
-- a naval unit (i.e. the carrier).
--
-- As a workaround, you can put an aircraft, e.g. a Helicopter on the deck of the carrier or another ship of the strike group. The aircraft should be set to
-- uncontrolled and maybe even to immortal. With the @{#AIRBOSS.SetRadioUnitName}(*unitname*) function you can use this unit as "radio repeater" for both Marshal and LSO
-- radio channels. However, this might lead to interruptions in the transmission if both channels transmit simultaniously. Therefore, it is better to assign a unit for
-- each radio via the @{#AIRBOSS.SetRadioRelayLSO}(unitname) and @{#AIRBOSS.SetRadioRelayMarshal}(unitname) functions.
--
-- Of course you can also use any other aircraft in the vicinity of the carrier, e.g. a rescue helo or a recovery tanker. It is just important that this
-- unit is and stays close the the boat as the distance from the sender to the receiver is modeled in DCS. So messages from too far away might not reach the players.
--
-- **Note** that not all radio messages the airboss sends have voice overs. Therefore, if you use a radio relay unit, users should *not* disable the
-- subtitles in the DCS game menu.
--
-- ### Transmission via Trigger
--
-- Another way to broadcast messages is via the [radio transmission trigger](https://wiki.hoggitworld.com/view/DCS_func_radioTransmission). This method can be used for all
-- units (land, air, naval). However, messages cannot be subtitled. Therefore, subtitles are displayed to the players via normal textout messages.
-- The disadvantage is that is is impossible to know which players have the right radio frequencies dialed in. Therefore, subtitles of the Marshal radio calls are displayed to all players
-- inside the CCA. Subtitles on the LSO radio frequency are displayed to all players in the pattern.
--
-- ### Sound to User
--
-- The third way to play sounds to the user via the [outsound trigger](https://wiki.hoggitworld.com/view/DCS_func_outSound).
-- These sounds are not coming from a radio station and therefore can be heard by players independent of their actual radio frequency setting.
-- The AIRBOSS class uses this method to play sounds to players which are of a more "private" nature - for example when a player has left his assigned altitude
-- in the Marshal stack. Often this is the modex of the player in combination with a textout messaged displayed on screen.
--
-- If you want to use this method for all radio messages you can enable it via the @{#AIRBOSS.SetUserSoundRadio}() function. This is the analogue of activating easy comms in DCS.
--
-- Note that this method is used for all players who are in the A-4E community mod as this mod does not have the ability to use radios due to current DCS restrictions.
-- Therefore, A-4E drivers will hear all radio transmissions from the Marshal/Airboss and all LSO messages as soon as their commence the pattern.
--
-- ===
--
-- # AI Handling
--
-- The @{#AIRBOSS} class allows to handle incoming AI units and integrate them into the marshal and landing pattern.
--
-- By default, incoming carrier capable aircraft which are detecting inside the Carrier Controlled Area (CCA) and approach the carrier by more than 5 NM are automatically guided to the holding zone.
-- Each AI group gets its own marshal stack in the holding pattern. Once a recovery window opens, the AI group of the lowest stack is transitioning to the landing pattern
-- and the Marshal stack collapses.
--
-- If no AI handling is desired, this can be turned off via the @{#AIRBOSS.SetHandleAIOFF} function.
--
-- In case only specifc AI groups shall be excluded, it can be done by adding the groups to a set, e.g.
--
--     -- AI groups explicitly excluded from handling by the Airboss
--     local CarrierExcludeSet=SET_GROUP:New():FilterPrefixes("E-2D Wizard Group"):FilterStart()
--     AirbossStennis:SetExcludeAI(CarrierExcludeSet)
--
-- Similarly, to the @{#AIRBOSS.SetExcludeAI} function, AI groups can be explicitly *included* via the @{#AIRBOSS.SetSquadronAI} function. If this is used, only the *included* groups are handled
-- by the AIRBOSS.
--
-- ## Keep the Deck Clean
--
-- Once the AI groups have landed on the carrier, they can be despawned automatically after they shut down their engines. This is achieved by the @{#AIRBOSS.SetDespawnOnEngineShutdown}() function.
--
-- ## Refueling
--
-- AI groups in the marshal pattern can be send to refuel at the recovery tanker or if none is defined to the nearest divert airfield. This can be enabled by the @{#AIRBOSS.SetRefuelAI}(*lowfuelthreshold*).
-- The parameter *lowfuelthreshold* is the threshold of fuel in percent. If the fuel drops below this value, the group will go for refueling. If refueling is performed at the recovery tanker,
-- the group will return to the marshal stack when done. The aircraft will not return from the divert airfield however.
--
-- Note that this feature is not enabled by default as there might be bugs in DCS that prevent a smooth refueling of the AI. Enable at your own risk.
--
-- ## Respawning - DCS Landing Bug
--
-- AI groups that enter the CCA are usually guided to Marshal stack. However, due to DCS limitations they might not obey the landing task if they have another airfield as departure and/or destination in
-- their mission task. Therefore, AI groups can be respawned when detected in the CCA. This should clear all other airfields and allow the aircraft to land on the carrier.
-- This is achieved by the @{#AIRBOSS.SetRespawnAI}() function.
--
-- ## Known Issues
--
-- Dealing with the DCS AI is a big challenge and there is only so much one can do. Please bear this in mind!
--
-- ### Pattern Updates
--
-- The holding position of the AI is updated regularly when the carrier has changed its position by more then 2.5 NM or changed its course significantly.
-- The patterns are realized by orbit or racetrack patterns of the DCS scripting API.
-- However, when the position is updated or the marshal stack collapses, it comes to disruptions of the regular orbit because a new waypoint with a new
-- orbit task needs to be created.
--
-- ### Recovery Cases
--
-- The AI performs a very realistic Case I recovery. Therefore, we already have a good Case I and II recovery simulation since the final part of Case II is a
-- Case I recovery. However, I don't think the AI can do a proper Case III recovery. If you give the AI the landing command, it is out of our hands and will
-- always go for a Case I in the final pattern part. Maybe this will improve in future DCS version but right now, there is not much we can do about it.
--
-- ===
--
-- # Finite State Machine (FSM)
--
-- The AIRBOSS class has a Finite State Machine (FSM) implementation for the carrier. This allows mission designers to hook into certain events and helps
-- simulate complex behaviour easier.
--
-- FSM events are:
--
--    * @{#AIRBOSS.Start}: Starts the AIRBOSS FSM.
--    * @{#AIRBOSS.Stop}: Stops the AIRBOSS FSM.
--    * @{#AIRBOSS.Idle}: Carrier is set to idle and not recovering.
--    * @{#AIRBOSS.RecoveryStart}: Starts the recovery ops.
--    * @{#AIRBOSS.RecoveryStop}: Stops the recovery ops.
--    * @{#AIRBOSS.RecoveryPause}: Pauses the recovery ops.
--    * @{#AIRBOSS.RecoveryUnpause}: Unpauses the recovery ops.
--    * @{#AIRBOSS.RecoveryCase}: Sets/switches the recovery case.
--    * @{#AIRBOSS.PassingWaypoint}: Carrier passes a waypoint defined in the mission editor.
--
-- These events can be used in the user script. When the event is triggered, it is automatically a function OnAfter*Eventname* called. For example
--
--     --- Carrier just passed waypoint *n*.
--     function AirbossStennis:OnAfterPassingWaypoint(From, Event, To, n)
--      -- Launch green flare.
--      self.carrier:FlareGreen()
--     end
--
-- In this example, we only launch a green flare every time the carrier passes a waypoint defined in the mission editor. But, of course, you can also use it to add new
-- recovery windows each time a carrier passes a waypoint. Therefore, you can create an "infinite" number of windows easily.
--
-- ===
--
-- # Examples
--
-- In this section a few simple examples are given to illustrate the scripting part.
--
-- ## Simple Case
--
--     -- Create AIRBOSS object.
--     local AirbossStennis=AIRBOSS:New("USS Stennis")
--
--     -- Add recovery windows:
--     -- Case I from 9 to 10 am. Carrier will turn into the wind 5 min before window opens and go at a speed so that wind over the deck is 25 knots.
--     local window1=AirbossStennis:AddRecoveryWindow("9:00",  "10:00", 1, nil, true, 25)
--     -- Case II with +15 degrees holding offset from 15:00 for 60 min.
--     local window2=AirbossStennis:AddRecoveryWindow("15:00", "16:00", 2, 15)
--     -- Case III with +30 degrees holding offset from 21:00 to 23:30.
--     local window3=AirbossStennis:AddRecoveryWindow("21:00", "23:30", 3, 30)
--
--     -- Load all saved player grades from your "Saved Games\DCS" folder (if lfs was desanitized).
--     AirbossStennis:Load()
--
--     -- Automatically save player results to your "Saved Games\DCS" folder each time a player get a final grade from the LSO.
--     AirbossStennis:SetAutoSave()
--
--     -- Start airboss class.
--     AirbossStennis:Start()
--
-- ===
--
-- # Debugging
--
-- In case you have problems, it is always a good idea to have a look at your DCS log file. You find it in your "Saved Games" folder, so for example in
--     C:\Users\<yourname>\Saved Games\DCS\Logs\dcs.log
-- All output concerning the @{#AIRBOSS} class should have the string "AIRBOSS" in the corresponding line.
-- Searching for lines that contain the string "error" or "nil" can also give you a hint what's wrong.
--
-- The verbosity of the output can be increased by adding the following lines to your script:
--
--     BASE:TraceOnOff(true)
--     BASE:TraceLevel(1)
--     BASE:TraceClass("AIRBOSS")
--
-- To get even more output you can increase the trace level to 2 or even 3, c.f. @{Core.Base#BASE} for more details.
--
-- ### Debug Mode
--
-- You have the option to enable the debug mode for this class via the @{#AIRBOSS.SetDebugModeON} function.
-- If enabled, status and debug text messages will be displayed on the screen. Also informative marks on the F10 map are created.
--
-- @field #AIRBOSS
AIRBOSS = {
  ClassName      = "AIRBOSS",
  Debug          = false,
  lid            = nil,
  theatre        = nil,
  carrier        = nil,
  carriertype    = nil,
  carrierparam   =  {},
  alias          = nil,
  airbase        = nil,
  waypoints      =  {},
  currentwp      = nil,
  beacon         = nil,
  TACANon        = nil,
  TACANchannel   = nil,
  TACANmode      = nil,
  TACANmorse     = nil,
  ICLSon         = nil,
  ICLSchannel    = nil,
  ICLSmorse      = nil,
  LSORadio       = nil,
  LSOFreq        = nil,
  LSOModu        = nil,
  MarshalRadio   = nil,
  MarshalFreq    = nil,
  MarshalModu    = nil,
  TowerFreq      = nil,
  radiotimer     = nil,
  zoneCCA        = nil,
  zoneCCZ        = nil,
  players        =  {},
  menuadded      =  {},
  BreakEntry     =  {},
  BreakEarly     =  {},
  BreakLate      =  {},
  Abeam          =  {},
  Ninety         =  {},
  Wake           =  {},
  Final          =  {},
  Groove         =  {},
  Platform       =  {},
  DirtyUp        =  {},
  Bullseye       =  {},
  defaultcase    = nil,
  case           = nil,
  defaultoffset  = nil,
  holdingoffset  = nil,
  recoverytimes  =  {},
  flights        =  {},
  Qpattern       =  {},
  Qmarshal       =  {},
  Qwaiting       =  {},
  Qspinning      =  {},
  RQMarshal      =  {},
  RQLSO          =  {},
  TQMarshal      =   0,
  TQLSO          =   0,
  Nmaxpattern    = nil,
  Nmaxmarshal    = nil,
  NmaxSection    = nil,
  NmaxStack      = nil,
  handleai       = nil,
  xtVoiceOvers   = nil,
  xtVoiceOversAI = nil,
  tanker         = nil,
  Corientation   = nil,
  Corientlast    = nil,
  Cposition      = nil,
  defaultskill   = nil,
  adinfinitum    = nil,
  magvar         = nil,
  Tcollapse      = nil,
  recoverywindow = nil,
  usersoundradio = nil,
  Tqueue         = nil,
  dTqueue        = nil,
  dTstatus       = nil,
  menumarkzones  = nil,
  menusmokezones = nil,
  playerscores   = nil,
  autosave       = nil,
  autosavefile   = nil,
  autosavepath   = nil,
  marshalradius  = nil,
  airbossnice    = nil,
  staticweather  = nil,
  windowcount    =   0,
  LSOdT          = nil,
  senderac       = nil,
  radiorelayLSO  = nil,
  radiorelayMSH  = nil,
  turnintowind   = nil,
  detour         = nil,
  squadsetAI     = nil,
  excludesetAI   = nil,
  menusingle     = nil,
  collisiondist  = nil,
  holdtimestamp  = nil,
  Tmessage       = nil,
  soundfolder    = nil,
  soundfolderLSO = nil,
  soundfolderMSH = nil,
  despawnshutdown= nil,
  dTbeacon       = nil,
  Tbeacon        = nil,
  LSOCall        = nil,
  MarshalCall    = nil,
  lowfuelAI      = nil,
  emergency      = nil,
  respawnAI      = nil,
  gle            =  {},
  lue            =  {},
  trapsheet      = nil,
  trappath       = nil,
  trapprefix     = nil,
  initialmaxalt  = nil,
  welcome        = nil,
  skipperMenu    = nil,
  skipperSpeed   = nil,
  skipperTime    = nil,
  skipperOffset  = nil,
  skipperUturn   = nil,
}

--- Aircraft types capable of landing on carrier (human+AI).
-- @type AIRBOSS.AircraftCarrier
-- @field #string AV8B AV-8B Night Harrier. Works only with the HMS Hermes, HMS Invincible, USS Tarawa, USS America, and Juan Carlos I.
-- @field #string A4EC A-4E Community mod.
-- @field #string HORNET F/A-18C Lot 20 Hornet by Eagle Dynamics.
-- @field #string F14A F-14A by Heatblur.
-- @field #string F14B F-14B by Heatblur.
-- @field #string F14A_AI F-14A Tomcat (AI).
-- @field #string FA18C F/A-18C Hornet (AI).
-- @field #string S3B Lockheed S-3B Viking.
-- @field #string S3BTANKER Lockheed S-3B Viking tanker.
-- @field #string E2D Grumman E-2D Hawkeye AWACS.
-- @field #string C2A Grumman C-2A Greyhound from Military Aircraft Mod.
-- @field #string T45C T-45C by VNAO.
-- @field #string RHINOE F/A-18E Superhornet (mod).
-- @field #string RHINOF F/A-18F Superhornet (mod).
-- @field #string GROWLER FEA-18G Superhornet (mod).
AIRBOSS.AircraftCarrier={
  AV8B="AV8BNA",
  HORNET="FA-18C_hornet",
  A4EC="A-4E-C",
  F14A="F-14A-135-GR",
  F14B="F-14B",
  F14A_AI="F-14A",
  FA18C="F/A-18C",
  T45C="T-45",
  S3B="S-3B",
  S3BTANKER="S-3B Tanker",
  E2D="E-2C",
  C2A="C2A_Greyhound",
  RHINOE="FA-18E",
  RHINOF="FA-18F",
  GROWLER="EA-18G",
}

--- Carrier types.
-- @type AIRBOSS.CarrierType
-- @field #string ROOSEVELT USS Theodore Roosevelt (CVN-71) [Super Carrier Module]
-- @field #string LINCOLN USS Abraham Lincoln (CVN-72) [Super Carrier Module]
-- @field #string WASHINGTON USS George Washington (CVN-73) [Super Carrier Module]
-- @field #string STENNIS USS John C. Stennis (CVN-74)
-- @field #string TRUMAN USS Harry S. Truman (CVN-75) [Super Carrier Module]
-- @field #string FORRESTAL USS Forrestal (CV-59) [Heatblur Carrier Module]
-- @field #string VINSON USS Carl Vinson (CVN-70) [Deprecated!]
-- @field #string HERMES HMS Hermes (R12) [V/STOL Carrier]
-- @field #string INVINCIBLE HMS Invincible (R05) [V/STOL Carrier]
-- @field #string TARAWA USS Tarawa (LHA-1) [V/STOL Carrier]
-- @field #string AMERICA USS America (LHA-6) [V/STOL Carrier]
-- @field #string JCARLOS Juan Carlos I (L61) [V/STOL Carrier]
-- @field #string HMAS Canberra (L02) [V/STOL Carrier]
-- @field #string KUZNETSOV Admiral Kuznetsov (CV 1143.5)
AIRBOSS.CarrierType = {
  ROOSEVELT = "CVN_71",
  LINCOLN = "CVN_72",
  WASHINGTON = "CVN_73",
  TRUMAN = "CVN_75",
  STENNIS = "Stennis",
  FORRESTAL = "Forrestal",
  VINSON = "VINSON",
  HERMES = "HERMES81",
  INVINCIBLE = "hms_invincible",
  TARAWA = "LHA_Tarawa",
  AMERICA = "USS America LHA-6",
  JCARLOS = "L61",
  CANBERRA = "L02",
  KUZNETSOV = "KUZNECOW",
}

--- Carrier specific parameters.
-- @type AIRBOSS.CarrierParameters
-- @field #number rwyangle Runway angle in degrees. for carriers with angled deck. For USS Stennis -9 degrees.
-- @field #number sterndist Distance in meters from carrier position to stern of carrier. For USS Stennis -150 meters.
-- @field #number deckheight Height of deck in meters. For USS Stennis ~63 ft = 19 meters.
-- @field #number wire1 Distance in meters from carrier position to first wire.
-- @field #number wire2 Distance in meters from carrier position to second wire.
-- @field #number wire3 Distance in meters from carrier position to third wire.
-- @field #number wire4 Distance in meters from carrier position to fourth wire.
-- @field #number landingdist Distance in meeters to the landing position.
-- @field #number rwylength Length of the landing runway in meters.
-- @field #number rwywidth Width of the landing runway in meters.
-- @field #number totlength Total length of carrier.
-- @field #number totwidthstarboard Total with of the carrier from stern position to starboard side (asymmetric carriers).
-- @field #number totwidthport Total with of the carrier from stern position to port side (asymmetric carriers).

--- Aircraft specific Angle of Attack (AoA) (or alpha) parameters.
-- @type AIRBOSS.AircraftAoA
-- @field #number OnSpeedMin Minimum on speed AoA. Values below are fast
-- @field #number OnSpeedMax Maximum on speed AoA. Values above are slow.
-- @field #number OnSpeed Optimal on-speed AoA.
-- @field #number Fast Fast AoA threshold. Smaller means faster.
-- @field #number Slow Slow AoA threshold. Larger means slower.
-- @field #number FAST Really fast AoA threshold.
-- @field #number SLOW Really slow AoA threshold.

--- Glideslope error thresholds in degrees.
-- @type AIRBOSS.GLE
-- @field #number _max Max _OK_ value. Default 0.4 deg.
-- @field #number _min Min _OK_ value. Default -0.3 deg.
-- @field #number High (H) threshold. Default 0.8 deg.
-- @field #number Low  (L) threshold. Default -0.6 deg.
-- @field #number HIGH  H  threshold. Default 1.5 deg.
-- @field #number LOW   L  threshold. Default -0.9 deg.

--- Lineup error thresholds in degrees.
-- @type AIRBOSS.LUE
-- @field #number _max Max _OK_ value. Default 0.5 deg.
-- @field #number _min Min _OK_ value. Default -0.5 deg.
-- @field #number Left  (LUR) threshold. Default -1.0 deg.
-- @field #number Right (LUL) threshold. Default 1.0 deg.
-- @field #number LeftMed threshold for AA/OS measuring. Default -2.0 deg.
-- @field #number RightMed threshold for AA/OS measuring. Default 2.0 deg.
-- @field #number LEFT   LUR  threshold. Default -3.0 deg.
-- @field #number RIGHT  LUL  threshold. Default 3.0 deg.

--- Pattern steps.
-- @type AIRBOSS.PatternStep
-- @field #string UNDEFINED "Undefined".
-- @field #string REFUELING "Refueling".
-- @field #string SPINNING "Spinning".
-- @field #string COMMENCING "Commencing".
-- @field #string HOLDING "Holding".
-- @field #string WAITING "Waiting for free Marshal stack".
-- @field #string PLATFORM "Platform".
-- @field #string ARCIN "Arc Turn In".
-- @field #string ARCOUT "Arc Turn Out".
-- @field #string DIRTYUP "Dirty Up".
-- @field #string BULLSEYE "Bullseye".
-- @field #string INITIAL "Initial".
-- @field #string BREAKENTRY "Break Entry".
-- @field #string EARLYBREAK "Early Break".
-- @field #string LATEBREAK "Late Break".
-- @field #string ABEAM "Abeam".
-- @field #string NINETY "Ninety".
-- @field #string WAKE "Wake".
-- @field #string FINAL "Final".
-- @field #string GROOVE_XX "Groove X".
-- @field #string GROOVE_IM "Groove In the Middle".
-- @field #string GROOVE_IC "Groove In Close".
-- @field #string GROOVE_AR "Groove At the Ramp".
-- @field #string GROOVE_AL "Groove Abeam Landing Spot".
-- @field #string GROOVE_LC "Groove Level Cross".
-- @field #string GROOVE_IW "Groove In the Wires".
-- @field #string BOLTER "Bolter Pattern".
-- @field #string EMERGENCY "Emergency Landing".
-- @field #string DEBRIEF "Debrief".
AIRBOSS.PatternStep = {
  UNDEFINED = "Undefined",
  REFUELING = "Refueling",
  SPINNING = "Spinning",
  COMMENCING = "Commencing",
  HOLDING = "Holding",
  WAITING = "Waiting for free Marshal stack",
  PLATFORM = "Platform",
  ARCIN = "Arc Turn In",
  ARCOUT = "Arc Turn Out",
  DIRTYUP = "Dirty Up",
  BULLSEYE = "Bullseye",
  INITIAL = "Initial",
  BREAKENTRY = "Break Entry",
  EARLYBREAK = "Early Break",
  LATEBREAK = "Late Break",
  ABEAM = "Abeam",
  NINETY = "Ninety",
  WAKE = "Wake",
  FINAL = "Turn Final",
  GROOVE_XX = "Groove X",
  GROOVE_IM = "Groove In the Middle",
  GROOVE_IC = "Groove In Close",
  GROOVE_AR = "Groove At the Ramp",
  GROOVE_IW = "Groove In the Wires",
  GROOVE_AL = "Groove Abeam Landing Spot",
  GROOVE_LC = "Groove Level Cross",
  BOLTER = "Bolter Pattern",
  EMERGENCY = "Emergency Landing",
  DEBRIEF = "Debrief",
}

--- Groove position.
-- @type AIRBOSS.GroovePos
-- @field #string X0 "X0": Entering the groove.
-- @field #string XX "XX": At the start, i.e. 3/4 from the run down.
-- @field #string IM "IM": In the middle.
-- @field #string IC "IC": In close.
-- @field #string AR "AR": At the ramp.
-- @field #string AL "AL": Abeam landing position (V/STOL).
-- @field #string LC "LC": Level crossing (V/STOL).
-- @field #string IW "IW": In the wires.
AIRBOSS.GroovePos = {
  X0 = "X0",
  XX = "XX",
  IM = "IM",
  IC = "IC",
  AR = "AR",
  AL = "AL",
  LC = "LC",
  IW = "IW",
}

--- Radio.
-- @type AIRBOSS.Radio
-- @field #number frequency Frequency in Hz.
-- @field #number modulation Band modulation.
-- @field #string alias Radio alias.

--- Radio sound file and subtitle.
-- @type AIRBOSS.RadioCall
-- @field #string file Sound file name without suffix.
-- @field #string suffix File suffix/extension, e.g. "ogg".
-- @field #boolean loud Loud version of sound file available.
-- @field #string subtitle Subtitle displayed during transmission.
-- @field #number duration Duration of the sound in seconds. This is also the duration the subtitle is displayed.
-- @field #number subduration Duration in seconds the subtitle is displayed.
-- @field #string modexsender Onboard number of the sender (optional).
-- @field #string modexreceiver Onboard number of the receiver (optional).
-- @field #string sender Sender of the message (optional). Default radio alias.

--- Pilot radio calls.
-- type AIRBOSS.PilotCalls
-- @field #AIRBOSS.RadioCall N0 "Zero" call.
-- @field #AIRBOSS.RadioCall N1 "One" call.
-- @field #AIRBOSS.RadioCall N2 "Two" call.
-- @field #AIRBOSS.RadioCall N3 "Three" call.
-- @field #AIRBOSS.RadioCall N4 "Four" call.
-- @field #AIRBOSS.RadioCall N5 "Five" call.
-- @field #AIRBOSS.RadioCall N6 "Six" call.
-- @field #AIRBOSS.RadioCall N7 "Seven" call.
-- @field #AIRBOSS.RadioCall N8 "Eight" call.
-- @field #AIRBOSS.RadioCall N9 "Nine" call.
-- @field #AIRBOSS.RadioCall POINT "Point" call.
-- @field #AIRBOSS.RadioCall BALL "Ball" call.
-- @field #AIRBOSS.RadioCall HARRIER "Harrier" call.
-- @field #AIRBOSS.RadioCall HAWKEYE "Hawkeye" call.
-- @field #AIRBOSS.RadioCall HORNET "Hornet" call.
-- @field #AIRBOSS.RadioCall SKYHAWK "Skyhawk" call.
-- @field #AIRBOSS.RadioCall TOMCAT "Tomcat" call.
-- @field #AIRBOSS.RadioCall VIKING "Viking" call.
-- @field #AIRBOSS.RadioCall BINGOFUEL "Bingo Fuel" call.
-- @field #AIRBOSS.RadioCall GASATDIVERT "Going for gas at the divert field" call.
-- @field #AIRBOSS.RadioCall GASATTANKER "Going for gas at the recovery tanker" call.

--- LSO radio calls.
-- @type AIRBOSS.LSOCalls
-- @field #AIRBOSS.RadioCall BOLTER "Bolter, Bolter" call.
-- @field #AIRBOSS.RadioCall CALLTHEBALL "Call the Ball" call.
-- @field #AIRBOSS.RadioCall CHECK "CHECK" call.
-- @field #AIRBOSS.RadioCall CLEAREDTOLAND "Cleared to land" call.
-- @field #AIRBOSS.RadioCall COMELEFT "Come left" call.
-- @field #AIRBOSS.RadioCall DEPARTANDREENTER "Depart and re-enter" call.
-- @field #AIRBOSS.RadioCall EXPECTHEAVYWAVEOFF "Expect heavy wavoff" call.
-- @field #AIRBOSS.RadioCall EXPECTSPOT75 "Expect spot 7.5" call.
-- @field #AIRBOSS.RadioCall EXPECTSPOT5 "Expect spot 5" call.
-- @field #AIRBOSS.RadioCall FAST "You're fast" call.
-- @field #AIRBOSS.RadioCall FOULDECK "Foul Deck" call.
-- @field #AIRBOSS.RadioCall HIGH "You're high" call.
-- @field #AIRBOSS.RadioCall IDLE "Idle" call.
-- @field #AIRBOSS.RadioCall LONGINGROOVE "You're long in the groove" call.
-- @field #AIRBOSS.RadioCall LOW "You're low" call.
-- @field #AIRBOSS.RadioCall N0 "Zero" call.
-- @field #AIRBOSS.RadioCall N1 "One" call.
-- @field #AIRBOSS.RadioCall N2 "Two" call.
-- @field #AIRBOSS.RadioCall N3 "Three" call.
-- @field #AIRBOSS.RadioCall N4 "Four" call.
-- @field #AIRBOSS.RadioCall N5 "Five" call.
-- @field #AIRBOSS.RadioCall N6 "Six" call.
-- @field #AIRBOSS.RadioCall N7 "Seven" call.
-- @field #AIRBOSS.RadioCall N8 "Eight" call.
-- @field #AIRBOSS.RadioCall N9 "Nine" call.
-- @field #AIRBOSS.RadioCall PADDLESCONTACT "Paddles, contact" call.
-- @field #AIRBOSS.RadioCall POWER "Power" call.
-- @field #AIRBOSS.RadioCall RADIOCHECK "Paddles, radio check" call.
-- @field #AIRBOSS.RadioCall RIGHTFORLINEUP "Right for line up" call.
-- @field #AIRBOSS.RadioCall ROGERBALL "Roger ball" call.
-- @field #AIRBOSS.RadioCall SLOW "You're slow" call.
-- @field #AIRBOSS.RadioCall STABILIZED "Stabilized" call.
-- @field #AIRBOSS.RadioCall WAVEOFF "Wave off" call.
-- @field #AIRBOSS.RadioCall WELCOMEABOARD "Welcome aboard" call.
-- @field #AIRBOSS.RadioCall CLICK Radio end transmission click sound.
-- @field #AIRBOSS.RadioCall NOISE Static noise sound.
-- @field #AIRBOSS.RadioCall SPINIT "Spin it" call.

--- Marshal radio calls.
-- @type AIRBOSS.MarshalCalls
-- @field #AIRBOSS.RadioCall AFFIRMATIVE "Affirmative" call.
-- @field #AIRBOSS.RadioCall ALTIMETER "Altimeter" call.
-- @field #AIRBOSS.RadioCall BRC "BRC" call.
-- @field #AIRBOSS.RadioCall CARRIERTURNTOHEADING "Turn to heading" call.
-- @field #AIRBOSS.RadioCall CASE "Case" call.
-- @field #AIRBOSS.RadioCall CHARLIETIME "Charlie Time" call.
-- @field #AIRBOSS.RadioCall CLEAREDFORRECOVERY "You're cleared for case" call.
-- @field #AIRBOSS.RadioCall DECKCLOSED "Deck closed" sound.
-- @field #AIRBOSS.RadioCall DEGREES "Degrees" call.
-- @field #AIRBOSS.RadioCall EXPECTED "Expected" call.
-- @field #AIRBOSS.RadioCall FLYNEEDLES "Fly your needles" call.
-- @field #AIRBOSS.RadioCall HOLDATANGELS "Hold at angels" call.
-- @field #AIRBOSS.RadioCall HOURS "Hours" sound.
-- @field #AIRBOSS.RadioCall MARSHALRADIAL "Marshal radial" call.
-- @field #AIRBOSS.RadioCall N0 "Zero" call.
-- @field #AIRBOSS.RadioCall N1 "One" call.
-- @field #AIRBOSS.RadioCall N2 "Two" call.
-- @field #AIRBOSS.RadioCall N3 "Three" call.
-- @field #AIRBOSS.RadioCall N4 "Four" call.
-- @field #AIRBOSS.RadioCall N5 "Five" call.
-- @field #AIRBOSS.RadioCall N6 "Six" call.
-- @field #AIRBOSS.RadioCall N7 "Seven" call.
-- @field #AIRBOSS.RadioCall N8 "Eight" call.
-- @field #AIRBOSS.RadioCall N9 "Nine" call.
-- @field #AIRBOSS.RadioCall NEGATIVE "Negative" sound.
-- @field #AIRBOSS.RadioCall NEWFB "New final bearing" call.
-- @field #AIRBOSS.RadioCall OBS "Obs" call.
-- @field #AIRBOSS.RadioCall POINT "Point" call.
-- @field #AIRBOSS.RadioCall RADIOCHECK "Radio check" call.
-- @field #AIRBOSS.RadioCall RECOVERY "Recovery" call.
-- @field #AIRBOSS.RadioCall RECOVERYOPSSTOPPED "Recovery ops stopped" sound.
-- @field #AIRBOSS.RadioCall RECOVERYPAUSEDNOTICE "Recovery paused until further notice" call.
-- @field #AIRBOSS.RadioCall RECOVERYPAUSEDRESUMED "Recovery paused and will be resumed at" call.
-- @field #AIRBOSS.RadioCall RESUMERECOVERY "Resuming aircraft recovery" call.
-- @field #AIRBOSS.RadioCall REPORTSEEME "Report see me" call.
-- @field #AIRBOSS.RadioCall ROGER "Roger" call.
-- @field #AIRBOSS.RadioCall SAYNEEDLES "Say needles" call.
-- @field #AIRBOSS.RadioCall STACKFULL "Marshal stack is currently full. Hold outside 10 NM zone and wait for further instructions" call.
-- @field #AIRBOSS.RadioCall STARTINGRECOVERY "Starting aircraft recovery" call.
-- @field #AIRBOSS.RadioCall CLICK Radio end transmission click sound.
-- @field #AIRBOSS.RadioCall NOISE Static noise sound.

--- Difficulty level.
-- @type AIRBOSS.Difficulty
-- @field #string EASY Flight Student. Shows tips and hints in important phases of the approach.
-- @field #string NORMAL Naval aviator. Moderate number of hints but not really zip lip.
-- @field #string HARD TOPGUN graduate. For people who know what they are doing. Nearly *ziplip*.
AIRBOSS.Difficulty = {
  EASY = "Flight Student",
  NORMAL = "Naval Aviator",
  HARD = "TOPGUN Graduate",
}

--- Recovery window parameters.
-- @type AIRBOSS.Recovery
-- @field #number START Start of recovery in seconds of abs mission time.
-- @field #number STOP End of recovery in seconds of abs mission time.
-- @field #number CASE Recovery case (1-3) of that time slot.
-- @field #number OFFSET Angle offset of the holding pattern in degrees. Usually 0, +-15, or +-30 degrees.
-- @field #boolean OPEN Recovery window is currently open.
-- @field #boolean OVER Recovery window is over and closed.
-- @field #boolean WIND Carrier will turn into the wind.
-- @field #number SPEED The speed in knots the carrier has during the recovery.
-- @field #boolean UTURN If true, carrier makes a U-turn to the point it came from before resuming its route to the next waypoint.
-- @field #number ID Recovery window ID.

--- Groove data.
-- @type AIRBOSS.GrooveData
-- @field #number Step Current step.
-- @field #number Time Time in seconds.
-- @field #number Rho Distance in meters.
-- @field #number X Distance in meters.
-- @field #number Z Distance in meters.
-- @field #number AoA Angle of Attack.
-- @field #number Alt Altitude in meters.
-- @field #number GSE Glideslope error in degrees.
-- @field #number LUE Lineup error in degrees.
-- @field #number Pitch Pitch angle in degrees.
-- @field #number Roll Roll angle in degrees.
-- @field #number Yaw Yaw angle in degrees.
-- @field #number Vel Total velocity in m/s.
-- @field #number Vy Vertical velocity in m/s.
-- @field #number Gamma Relative heading player to carrier's runway. 0=parallel, +-90=perpendicular.
-- @field #string Grade LSO grade.
-- @field #number GradePoints LSO grade points
-- @field #string GradeDetail LSO grade details.
-- @field #string FlyThrough Fly through up "/" or fly through down "\\".

--- LSO grade data.
-- @type AIRBOSS.LSOgrade
-- @field #string grade LSO grade, i.e. _OK_, OK, (OK), --, CUT
-- @field #number points Points received.
-- @field #number finalscore Points received after player has finally landed. This is the average over all incomplete passes (bolter, waveoff) before.
-- @field #string details Detailed flight analysis.
-- @field #number wire Wire caught.
-- @field #number Tgroove Time in the groove in seconds.
-- @field #number case Recovery case.
-- @field #string wind Wind speed on deck in knots.
-- @field #string modex Onboard number.
-- @field #string airframe Aircraft type name of player.
-- @field #string carriertype Carrier type name.
-- @field #string carriername Carrier name/alias.
-- @field #string theatre DCS map.
-- @field #string mitime Mission time in hh:mm:ss+d format
-- @field #string midate Mission date in yyyy/mm/dd format.
-- @field #string osdate Real live date. Needs **os** to be desanitized.

--- Checkpoint parameters triggering the next step in the pattern.
-- @type AIRBOSS.Checkpoint
-- @field #string name Name of checkpoint.
-- @field #number Xmin Minimum allowed longitual distance to carrier.
-- @field #number Xmax Maximum allowed longitual distance to carrier.
-- @field #number Zmin Minimum allowed latitudal distance to carrier.
-- @field #number Zmax Maximum allowed latitudal distance to carrier.
-- @field #number LimitXmin Latitudal threshold for triggering the next step if X<Xmin.
-- @field #number LimitXmax Latitudal threshold for triggering the next step if X>Xmax.
-- @field #number LimitZmin Latitudal threshold for triggering the next step if Z<Zmin.
-- @field #number LimitZmax Latitudal threshold for triggering the next step if Z>Zmax.

--- Parameters of a flight group.
-- @type AIRBOSS.FlightGroup
-- @field Wrapper.Group#GROUP group Flight group.
-- @field #string groupname Name of the group.
-- @field #number nunits Number of units in group.
-- @field #number dist0 Distance to carrier in meters when the group was first detected inside the CCA.
-- @field #number time Timestamp in seconds of timer.getAbsTime() of the last important event, e.g. added to the queue.
-- @field #number flag Flag value describing the current stack.
-- @field #boolean ai If true, flight is purly AI.
-- @field #string actype Aircraft type name.
-- @field #table onboardnumbers Onboard numbers of aircraft in the group.
-- @field #string onboard Onboard number of player or first unit in group.
-- @field #number case Recovery case of flight.
-- @field #string seclead Name of section lead.
-- @field #table section Other human flight groups belonging to this flight. This flight is the lead.
-- @field #boolean holding If true, flight is in holding zone.
-- @field #boolean ballcall If true, flight called the ball in the groove.
-- @field #table elements Flight group elements.
-- @field #number Tcharlie Charlie (abs) time in seconds.
-- @field #string name Player name or name of first AI unit.
-- @field #boolean refueling Flight is refueling.

--- Parameters of an element in a flight group.
-- @type AIRBOSS.FlightElement
-- @field Wrapper.Unit#UNIT unit Aircraft unit.
-- @field #string unitname Name of the unit.
-- @field #boolean ai If true, AI sits inside. If false, human player is flying.
-- @field #string onboard Onboard number of the aircraft.
-- @field #boolean ballcall If true, flight called the ball in the groove.
-- @field #boolean recovered If true, element was successfully recovered.

--- Player data table holding all important parameters of each player.
-- @type AIRBOSS.PlayerData
-- @field Wrapper.Unit#UNIT unit Aircraft of the player.
-- @field #string unitname Name of the unit.
-- @field Wrapper.Client#CLIENT client Client object of player.
-- @field #string callsign Callsign of player.
-- @field #string difficulty Difficulty level.
-- @field #string step Current/next pattern step.
-- @field #boolean warning Set true once the player got a warning.
-- @field #number passes Number of passes.
-- @field #boolean attitudemonitor If true, display aircraft attitude and other parameters constantly.
-- @field #table debrief Debrief analysis of the current step of this pass.
-- @field #table lastdebrief Debrief of player performance of last completed pass.
-- @field #boolean landed If true, player landed or attempted to land.
-- @field #boolean boltered If true, player boltered.
-- @field #boolean waveoff If true, player was waved off during final approach.
-- @field #boolean wop If true, player was waved off during the pattern.
-- @field #boolean lig If true, player was long in the groove.
-- @field #boolean owo If true, own waveoff by player.
-- @field #boolean wofd If true, player was waved off because of a foul deck.
-- @field #number Tlso Last time the LSO gave an advice.
-- @field #number Tgroove Time in the groove in seconds.
-- @field #number TIG0 Time in groove start timer.getTime().
-- @field #number wire Wire caught by player when trapped.
-- @field #AIRBOSS.GroovePos groove Data table at each position in the groove. Elements are of type @{#AIRBOSS.GrooveData}.
-- @field #table points Points of passes until finally landed.
-- @field #number finalscore Final score if points are averaged over multiple passes.
-- @field #boolean valid If true, player made a valid approach. Is set true on start of Groove X.
-- @field #boolean subtitles If true, display subtitles of radio messages.
-- @field #boolean showhints If true, show step hints.
-- @field #table trapsheet Groove data table recorded every 0.5 seconds.
-- @field #boolean trapon If true, save trap sheets.
-- @field #string debriefschedulerID Debrief scheduler ID.
-- @extends #AIRBOSS.FlightGroup

--- Main group level radio menu: F10 Other/Airboss.
-- @field #table MenuF10
AIRBOSS.MenuF10 = {}

--- Airboss mission level F10 root menu.
-- @field #table MenuF10Root
AIRBOSS.MenuF10Root = nil

--- Airboss class version.
-- @field #string version
AIRBOSS.version = "1.3.0"
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Handle tanker and AWACS. Put them into pattern.
-- TODO: Handle cases where AI crashes on carrier deck ==> Clean up deck.
-- TODO: Player eject and crash debrief "gradings".
-- TODO: PWO during case 2/3.
-- TODO: PWO when player comes too close to other flight.
-- DONE: Spin pattern. Add radio menu entry. Not sure what to add though?!
-- DONE: Despawn AI after engine shutdown option.
-- DONE: What happens when section lead or member dies?
-- DONE: Do not remove recovered elements but only set switch. Remove only groups which are completely recovered.
-- DONE: Option to filter AI groups for recovery.
-- DONE: Rework radio messages. Better control over player board numbers.
-- DONE: Case I & II/III zone so that player gets into pattern automatically. Case I 3 position on the circle. Case II/III when the player enters the approach corridor maybe?
-- DONE: Add static weather information.
-- DONE: Allow up to two flights per Case I marshal stack.
-- DONE: Add max stack for Case I and define waiting queue outside CCZ.
-- DONE: Maybe do an additional step at the initial (Case II) or bullseye (Case III) and register player in case he missed some steps.
-- DONE: Subtitles off options on player level.
-- DONE: Persistence of results.
-- DONE: Foul deck waveoff.
-- DONE: Get Charlie time estimate function.
-- DONE: Average player grades until landing.
-- DONE: Check player heading at zones, e.g. initial.
-- DONE: Fix bug that player leaves the approach zone if he boltered or was waved off during Case II or III. NOTE: Partly due to increasing approach zone size.
-- DONE: Fix bug that player gets an altitude warning if stack collapses. NOTE: Would not work if two stacks Case I and II/III are used.
-- DONE: Improve radio messages. Maybe usersound for messages which are only meant for players?
-- DONE: Add voice over fly needs and welcome aboard.
-- DONE: Improve trapped wire calculation.
-- DONE: Carrier zone with dimensions of carrier. to check if landing happened on deck.
-- DONE: Carrier runway zone for fould deck check.
-- DONE: More Hints for Case II/III.
-- DONE: Set magnetic declination function.
-- DONE: First send AI to marshal and then allow them into the landing pattern ==> task function when reaching the waypoint.
-- DONE: Extract (static) weather from mission for cloud cover etc.
-- DONE: Check distance to players during approach.
-- DONE: Option to turn AI handling off.
-- DONE: Add user functions.
-- DONE: Update AI holding pattern wrt to moving carrier.
-- DONE: Generalize parameters for other carriers.
-- DONE: Generalize parameters for other aircraft.
-- DONE: Add radio check (LSO, AIRBOSS) to F10 radio menu.
-- DONE: Right pattern step after bolter/wo/patternWO? Guess so.
-- DONE: Set case II and III times (via recovery time).
-- DONE: Get correct wire when trapped. DONE but might need further tweaking.
-- DONE: Add radio transmission queue for LSO and airboss.
-- DONE: CASE II.
-- DONE: CASE III.
-- NOPE: Strike group with helo bringing cargo etc. Not yet.
-- DONE: Handle crash event. Delete A/C from queue, send rescue helo.
-- DONE: Get fuel state in pounds. (working for the hornet, did not check others)
-- DONE: Add aircraft numbers in queue to carrier info F10 radio output.
-- DONE: Monitor holding of players/AI in zoneHolding.
-- DONE: Transmission via radio.
-- DONE: Get board numbers.
-- DONE: Get an _OK_ pass if long in groove. Possible other pattern wave offs as well?!
-- DONE: Add scoring to radio menu.
-- DONE: Optimized debrief.
-- DONE: Add automatic grading.
-- DONE: Fix radio menu.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRBOSS class object for a specific aircraft carrier unit.
-- @param #AIRBOSS self
-- @param carriername Name of the aircraft carrier unit as defined in the mission editor.
-- @param alias (Optional) Alias for the carrier. This will be used for radio messages and the F10 radius menu. Default is the carrier name as defined in the mission editor.
-- @return #AIRBOSS self or nil if carrier unit does not exist.
function AIRBOSS:New( carriername, alias )

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit( self, FSM:New() ) -- #AIRBOSS

  -- Debug.
  self:F2( { carriername = carriername, alias = alias } )

  -- Set carrier unit.
  self.carrier = UNIT:FindByName( carriername )

  -- Check if carrier unit exists.
  if self.carrier == nil then
    -- Error message.
    local text = string.format( "ERROR: Carrier unit %s could not be found! Make sure this UNIT is defined in the mission editor and check the spelling of the unit name carefully.", carriername )
    MESSAGE:New( text, 120 ):ToAll()
    self:E( text )
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid = string.format( "AIRBOSS %s | ", carriername )

  -- Current map.
  self.theatre = env.mission.theatre
  self:T2( self.lid .. string.format( "Theatre = %s.", tostring( self.theatre ) ) )

  -- Get carrier type.
  self.carriertype = self.carrier:GetTypeName()

  -- Set alias.
  self.alias = alias or carriername

  -- Set carrier airbase object.
  self.airbase = AIRBASE:FindByName( carriername )

  -- Create carrier beacon.
  self.beacon = BEACON:New( self.carrier )

  -- Set Tower Frequency of carrier.
  self:_GetTowerFrequency()

  -- Init player scores table.
  self.playerscores = {}

  -- Initialize ME waypoints.
  self:_InitWaypoints()

  -- Current waypoint.
  self.currentwp = 1

  -- Patrol route.
  self:_PatrolRoute()

  -------------
  --- Defaults:
  -------------

  -- Set up Airboss radio.
  self:SetMarshalRadio()

  -- Set up LSO radio.
  self:SetLSORadio()

  -- Set LSO call interval. Default 4 sec.
  self:SetLSOCallInterval()

  -- Radio scheduler.
  self.radiotimer = SCHEDULER:New()

  -- Set magnetic declination.
  self:SetMagneticDeclination()

  -- Set ICSL to channel 1.
  self:SetICLS()

  -- Set TACAN to channel 74X.
  self:SetTACAN()

  -- Becons are reactivated very 5 min.
  self:SetBeaconRefresh()

  -- Set max aircraft in landing pattern. Default 4.
  self:SetMaxLandingPattern()

  -- Set max Case I Marshal stacks. Default 3.
  self:SetMaxMarshalStacks()

  -- Set max section members. Default 2.
  self:SetMaxSectionSize()

  -- Set max flights per stack. Default is 2.
  self:SetMaxFlightsPerStack()

  -- Set AI handling On.
  self:SetHandleAION()

  -- No extra voiceover/calls from player by default
  self:SetExtraVoiceOvers(false)

  -- No extra voiceover/calls from AI by default
  self:SetExtraVoiceOversAI(false)

  -- Airboss is a nice guy.
  self:SetAirbossNiceGuy()

  -- Allow emergency landings.
  self:SetEmergencyLandings()

  -- No despawn after engine shutdown by default.
  self:SetDespawnOnEngineShutdown( false )

  -- No respawning of AI groups when entering the CCA.
  self:SetRespawnAI( false )

  -- Mission uses static weather by default.
  self:SetStaticWeather()

  -- Default recovery case. This sets self.defaultcase and self.case. Default Case I.
  self:SetRecoveryCase()

  -- Set time the turn starts before the window opens.
  self:SetRecoveryTurnTime()

  -- Set holding offset to 0 degrees. This set self.defaultoffset and self.holdingoffset.
  self:SetHoldingOffsetAngle()

  -- Set Marshal stack radius. Default 2.75 NM, which gives a diameter of 5.5 NM.
  self:SetMarshalRadius()

  -- Set max alt at initial. Default 1300 ft.
  self:SetInitialMaxAlt()

  -- Default player skill EASY.
  self:SetDefaultPlayerSkill( AIRBOSS.Difficulty.EASY )

  -- Default glideslope error thresholds.
  self:SetGlideslopeErrorThresholds()

  -- Default lineup error thresholds.
  self:SetLineupErrorThresholds()

  -- CCA 50 NM radius zone around the carrier.
  self:SetCarrierControlledArea()

  -- CCZ 5 NM radius zone around the carrier.
  self:SetCarrierControlledZone()

  -- Carrier patrols its waypoints until the end of time.
  self:SetPatrolAdInfinitum( true )

  -- Collision check distance. Default 5 NM.
  self:SetCollisionDistance()

  -- Set update time intervals.
  self:SetQueueUpdateTime()
  self:SetStatusUpdateTime()
  self:SetDefaultMessageDuration()

  -- Menu options.
  self:SetMenuMarkZones()
  self:SetMenuSmokeZones()
  self:SetMenuSingleCarrier( false )

  -- Welcome players.
  self:SetWelcomePlayers( true )

  -- Coordinates
  self.landingcoord = COORDINATE:New( 0, 0, 0 ) -- Core.Point#COORDINATE
  self.sterncoord = COORDINATE:New( 0, 0, 0 ) -- Core.Point#COORDINATE
  self.landingspotcoord = COORDINATE:New( 0, 0, 0 ) -- Core.Point#COORDINATE

  -- Init carrier parameters.
  if self.carriertype == AIRBOSS.CarrierType.STENNIS then
    -- Stennis parameters were updated to match the other Super Carriers.
    self:_InitNimitz()
  elseif self.carriertype == AIRBOSS.CarrierType.ROOSEVELT then
    self:_InitNimitz()
  elseif self.carriertype == AIRBOSS.CarrierType.LINCOLN then
    self:_InitNimitz()
  elseif self.carriertype == AIRBOSS.CarrierType.WASHINGTON then
    self:_InitNimitz()
  elseif self.carriertype == AIRBOSS.CarrierType.TRUMAN then
    self:_InitNimitz()
  elseif self.carriertype == AIRBOSS.CarrierType.FORRESTAL then
    self:_InitForrestal()
  elseif self.carriertype == AIRBOSS.CarrierType.VINSON then
    -- Carl Vinson is legacy now.
    self:_InitStennis()
  elseif self.carriertype == AIRBOSS.CarrierType.HERMES then
    -- Hermes parameters.
    self:_InitHermes()
  elseif self.carriertype == AIRBOSS.CarrierType.INVINCIBLE then
    -- Invincible parameters.
    self:_InitInvincible()
  elseif self.carriertype == AIRBOSS.CarrierType.TARAWA then
    -- Tarawa parameters.
    self:_InitTarawa()
  elseif self.carriertype == AIRBOSS.CarrierType.AMERICA then
    -- Use America parameters.
    self:_InitAmerica()
  elseif self.carriertype == AIRBOSS.CarrierType.JCARLOS then
    -- Use Juan Carlos parameters.
    self:_InitJcarlos()
  elseif self.carriertype == AIRBOSS.CarrierType.CANBERRA then
    -- Use Juan Carlos parameters at this stage.
    self:_InitCanberra()
  elseif self.carriertype == AIRBOSS.CarrierType.KUZNETSOV then
    -- Kusnetsov parameters - maybe...
    self:_InitStennis()
  else
    self:E( self.lid .. string.format( "ERROR: Unknown carrier type %s!", tostring( self.carriertype ) ) )
    return nil
  end

  -- Init voice over files.
  self:_InitVoiceOvers()

  -------------------
  -- Debug Section --
  -------------------

  -- Debug trace.
  if false then
    self.Debug = true
    BASE:TraceOnOff( true )
    BASE:TraceClass( self.ClassName )
    BASE:TraceLevel( 3 )
    -- self.dTstatus=0.1
  end

  -- Smoke zones.
  if false then
    local case = 3
    self.holdingoffset = 30
    self:_GetZoneGroove():SmokeZone( SMOKECOLOR.Red, 5 )
    self:_GetZoneLineup():SmokeZone( SMOKECOLOR.Green, 5 )
    self:_GetZoneBullseye( case ):SmokeZone( SMOKECOLOR.White, 45 )
    self:_GetZoneDirtyUp( case ):SmokeZone( SMOKECOLOR.Orange, 45 )
    self:_GetZoneArcIn( case ):SmokeZone( SMOKECOLOR.Blue, 45 )
    self:_GetZoneArcOut( case ):SmokeZone( SMOKECOLOR.Blue, 45 )
    self:_GetZonePlatform( case ):SmokeZone( SMOKECOLOR.Blue, 45 )
    self:_GetZoneCorridor( case ):SmokeZone( SMOKECOLOR.Green, 45 )
    self:_GetZoneHolding( case, 1 ):SmokeZone( SMOKECOLOR.White, 45 )
    self:_GetZoneHolding( case, 2 ):SmokeZone( SMOKECOLOR.White, 45 )
    self:_GetZoneInitial( case ):SmokeZone( SMOKECOLOR.Orange, 45 )
    self:_GetZoneCommence( case, 1 ):SmokeZone( SMOKECOLOR.Red, 45 )
    self:_GetZoneCommence( case, 2 ):SmokeZone( SMOKECOLOR.Red, 45 )
    self:_GetZoneAbeamLandingSpot():SmokeZone( SMOKECOLOR.Red, 5 )
    self:_GetZoneLandingSpot():SmokeZone( SMOKECOLOR.Red, 5 )
  end

  -- Carrier parameter debug tests.
  if false then
    -- Stern coordinate.
    local FB = self:GetFinalBearing( false )
    local hdg = self:GetHeading( false )

    -- Stern pos.
    local stern = self:_GetSternCoord()

    -- Bow pos.
    local bow = stern:Translate( self.carrierparam.totlength, hdg, true )

    -- End of rwy.
    local rwy = stern:Translate( self.carrierparam.rwylength, FB, true )

    --- Flare points and zones.
    local function flareme()

      -- Carrier pos.
      self:GetCoordinate():FlareYellow()

      -- Stern
      stern:FlareYellow()

      -- Bow
      bow:FlareYellow()

      -- Runway half width = 10 m.
      local r1 = stern:Translate( self.carrierparam.rwywidth * 0.5, FB + 90, true )
      local r2 = stern:Translate( self.carrierparam.rwywidth * 0.5, FB - 90, true )
      -- r1:FlareWhite()
      -- r2:FlareWhite()

      -- End of runway.
      rwy:FlareRed()

      -- Right 30 meters from stern.
      local cR = stern:Translate( self.carrierparam.totwidthstarboard, hdg + 90, true )
      -- cR:FlareYellow()

      -- Left 40 meters from stern.
      local cL = stern:Translate( self.carrierparam.totwidthport, hdg - 90, true )
      -- cL:FlareYellow()

      -- Carrier specific.
      if self.carrier:GetTypeName() ~= AIRBOSS.CarrierType.INVINCIBLE or self.carrier:GetTypeName() ~= AIRBOSS.CarrierType.HERMES or self.carrier:GetTypeName() ~= AIRBOSS.CarrierType.TARAWA or self.carrier:GetTypeName() ~= AIRBOSS.CarrierType.AMERICA or self.carrier:GetTypeName() ~= AIRBOSS.CarrierType.JCARLOS or self.carrier:GetTypeName() ~= AIRBOSS.CarrierType.CANBERRA then

        -- Flare wires.
        local w1 = stern:Translate( self.carrierparam.wire1, FB, true )
        local w2 = stern:Translate( self.carrierparam.wire2, FB, true )
        local w3 = stern:Translate( self.carrierparam.wire3, FB, true )
        local w4 = stern:Translate( self.carrierparam.wire4, FB, true )
        w1:FlareWhite()
        w2:FlareYellow()
        w3:FlareWhite()
        w4:FlareYellow()

      else

        -- Abeam landing spot zone.
        local ALSPT = self:_GetZoneAbeamLandingSpot()
        ALSPT:FlareZone( FLARECOLOR.Red, 5, nil, UTILS.FeetToMeters( 120 ) )

        -- Primary landing spot zone.
        local LSPT = self:_GetZoneLandingSpot()
        LSPT:FlareZone( FLARECOLOR.Green, 5, nil, self.carrierparam.deckheight )

        -- Landing spot coordinate.
        local PLSC = self:_GetLandingSpotCoordinate()
        PLSC:FlareWhite()
      end

      -- Flare carrier and landing runway.
      local cbox = self:_GetZoneCarrierBox()
      local rbox = self:_GetZoneRunwayBox()
      cbox:FlareZone( FLARECOLOR.Green, 5, nil, self.carrierparam.deckheight )
      rbox:FlareZone( FLARECOLOR.White, 5, nil, self.carrierparam.deckheight )
    end

    -- Flare points every 3 seconds for 3 minutes.
    SCHEDULER:New( nil, flareme, {}, 1, 3, nil, 180 )
  end

  -----------------------
  --- FSM Transitions ---
  -----------------------

  -- Start State.
  self:SetStartState( "Stopped" )

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Load",            "Stopped")     -- Load player scores from file.
  self:AddTransition("Stopped",       "Start",           "Idle")        -- Start AIRBOSS script.
  self:AddTransition("*",             "Idle",            "Idle")        -- Carrier is idling.
  self:AddTransition("Idle",          "RecoveryStart",   "Recovering")  -- Start recovering aircraft.
  self:AddTransition("Recovering",    "RecoveryStop",    "Idle")        -- Stop recovering aircraft.
  self:AddTransition("Recovering",    "RecoveryPause",   "Paused")      -- Pause recovering aircraft.
  self:AddTransition("Paused",        "RecoveryUnpause", "Recovering")  -- Unpause recovering aircraft.
  self:AddTransition("*",             "Status",          "*")           -- Update status of players and queues.
  self:AddTransition("*",             "RecoveryCase",    "*")           -- Switch to another case recovery.
  self:AddTransition("*",             "PassingWaypoint", "*")           -- Carrier is passing a waypoint.
  self:AddTransition("*",             "LSOGrade",        "*")           -- LSO grade.
  self:AddTransition("*",             "Marshal",         "*")           -- A flight was send into the marshal stack.
  self:AddTransition("*",             "Save",            "*")           -- Save player scores to file.
  self:AddTransition("*",             "Stop",            "Stopped")     -- Stop AIRBOSS FMS.


  --- Triggers the FSM event "Start" that starts the airboss. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRBOSS] Start
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Start" that starts the airboss after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRBOSS] __Start
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.

  --- On after "Start" user function. Called when the AIRBOSS FSM is started.
  -- @function [parent=#AIRBOSS] OnAfterStart
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "Idle" that puts the carrier into state "Idle" where no recoveries are carried out.
  -- @function [parent=#AIRBOSS] Idle
  -- @param #AIRBOSS self

  --- Triggers the FSM delayed event "Idle" that puts the carrier into state "Idle" where no recoveries are carried out.
  -- @function [parent=#AIRBOSS] __Idle
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "RecoveryStart" that starts the recovery of aircraft. Marshalling aircraft are send to the landing pattern.
  -- @function [parent=#AIRBOSS] RecoveryStart
  -- @param #AIRBOSS self
  -- @param #number Case Recovery case (1, 2 or 3) that is started.
  -- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.

  --- Triggers the FSM delayed event "RecoveryStart" that starts the recovery of aircraft. Marshalling aircraft are send to the landing pattern.
  -- @function [parent=#AIRBOSS] __RecoveryStart
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #number Case Recovery case (1, 2 or 3) that is started.
  -- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.

  --- On after "RecoveryStart" user function. Called when recovery of aircraft is started and carrier switches to state "Recovering".
  -- @function [parent=#AIRBOSS] OnAfterRecoveryStart
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number Case The recovery case (1, 2 or 3) to start.
  -- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.

  --- Triggers the FSM event "RecoveryStop" that stops the recovery of aircraft.
  -- @function [parent=#AIRBOSS] RecoveryStop
  -- @param #AIRBOSS self

  --- Triggers the FSM delayed event "RecoveryStop" that stops the recovery of aircraft.
  -- @function [parent=#AIRBOSS] __RecoveryStop
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.

  --- On after "RecoveryStop" user function. Called when recovery of aircraft is stopped.
  -- @function [parent=#AIRBOSS] OnAfterRecoveryStop
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "RecoveryPause" that pauses the recovery of aircraft.
  -- @function [parent=#AIRBOSS] RecoveryPause
  -- @param #AIRBOSS self
  -- @param #number duration Duration of pause in seconds. After that recovery is automatically resumed.

  --- Triggers the FSM delayed event "RecoveryPause" that pauses the recovery of aircraft.
  -- @function [parent=#AIRBOSS] __RecoveryPause
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #number duration Duration of pause in seconds. After that recovery is automatically resumed.

  --- Triggers the FSM event "RecoveryUnpause" that resumes the recovery of aircraft if it was paused.
  -- @function [parent=#AIRBOSS] RecoveryUnpause
  -- @param #AIRBOSS self

  --- Triggers the FSM delayed event "RecoveryUnpause" that resumes the recovery of aircraft if it was paused.
  -- @function [parent=#AIRBOSS] __RecoveryUnpause
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "RecoveryCase" that switches the aircraft recovery case.
  -- @function [parent=#AIRBOSS] RecoveryCase
  -- @param #AIRBOSS self
  -- @param #number Case The new recovery case (1, 2 or 3).
  -- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.

  --- Triggers the delayed FSM event "RecoveryCase" that sets the used aircraft recovery case.
  -- @function [parent=#AIRBOSS] __RecoveryCase
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #number Case The new recovery case (1, 2 or 3).
  -- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.

  --- Triggers the FSM event "PassingWaypoint". Called when the carrier passes a waypoint.
  -- @function [parent=#AIRBOSS] PassingWaypoint
  -- @param #AIRBOSS self
  -- @param #number waypoint Number of waypoint.

  --- Triggers the FSM delayed event "PassingWaypoint". Called when the carrier passes a waypoint.
  -- @function [parent=#AIRBOSS] __PassingWaypoint
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #number Case Recovery case (1, 2 or 3) that is started.
  -- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.

  --- On after "PassingWaypoint" user function. Called when the carrier passes a waypoint of its route.
  -- @function [parent=#AIRBOSS] OnAfterPassingWaypoint
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number waypoint Number of waypoint.

  --- Triggers the FSM event "Save" that saved the player scores to a file.
  -- @function [parent=#AIRBOSS] Save
  -- @param #AIRBOSS self
  -- @param #string path Path where the file is saved. Default is the DCS installation root directory or your "Saved Games\DCS" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name. Default is AIRBOSS-*ALIAS*_LSOgrades.csv.

  --- Triggers the FSM delayed event "Save" that saved the player scores to a file.
  -- @function [parent=#AIRBOSS] __Save
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #string path Path where the file is saved. Default is the DCS installation root directory or your "Saved Games\DCS" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name. Default is AIRBOSS-*ALIAS*_LSOgrades.csv.

  --- On after "Save" event user function. Called when the player scores are saved to disk.
  -- @function [parent=#AIRBOSS] OnAfterSave
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path Path where the file is saved. Default is the DCS installation root directory or your "Saved Games\DCS" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name. Default is AIRBOSS-*ALIAS*_LSOgrades.csv.

  --- Triggers the FSM event "Load" that loads the player scores from a file. AIRBOSS FSM must **not** be started at this point.
  -- @function [parent=#AIRBOSS] Load
  -- @param #AIRBOSS self
  -- @param #string path Path where the file is located. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is AIRBOSS-<ALIAS>_LSOgrades.csv.

  --- Triggers the FSM delayed event "Load" that loads the player scores from a file. AIRBOSS FSM must **not** be started at this point.
  -- @function [parent=#AIRBOSS] __Load
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #string path Path where the file is located. Default is the DCS installation root directory or your "Saved Games\DCS" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name. Default is AIRBOSS-*ALIAS*_LSOgrades.csv.

  --- On after "Load" event user function. Called when the player scores are loaded from disk.
  -- @function [parent=#AIRBOSS] OnAfterLoad
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path Path where the file is located. Default is the DCS installation root directory or your "Saved Games\DCS" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name. Default is AIRBOSS-*ALIAS*_LSOgrades.csv.

  --- Triggers the FSM event "LSOGrade". Called when the LSO grades a player
  -- @function [parent=#AIRBOSS] LSOGrade
  -- @param #AIRBOSS self
  -- @param #AIRBOSS.PlayerData playerData Player Data.
  -- @param #AIRBOSS.LSOgrade grade LSO grade.

  --- Triggers the FSM event "LSOGrade". Delayed called when the LSO grades a player.
  -- @function [parent=#AIRBOSS] __LSOGrade
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #AIRBOSS.PlayerData playerData Player Data.
  -- @param #AIRBOSS.LSOgrade grade LSO grade.

  --- On after "LSOGrade" user function. Called when the carrier passes a waypoint of its route.
  -- @function [parent=#AIRBOSS] OnAfterLSOGrade
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #AIRBOSS.PlayerData playerData Player Data.
  -- @param #AIRBOSS.LSOgrade grade LSO grade.

  --- Triggers the FSM event "Marshal". Called when a flight is send to the Marshal stack.
  -- @function [parent=#AIRBOSS] Marshal
  -- @param #AIRBOSS self
  -- @param #AIRBOSS.FlightGroup flight The flight group data.

  --- Triggers the FSM event "Marshal". Delayed call when a flight is send to the Marshal stack.
  -- @function [parent=#AIRBOSS] __Marshal
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.
  -- @param #AIRBOSS.FlightGroup flight The flight group data.

  --- On after "Marshal" user function. Called when a flight is send to the Marshal stack.
  -- @function [parent=#AIRBOSS] OnAfterMarshal
  -- @param #AIRBOSS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #AIRBOSS.FlightGroup flight The flight group data.

  --- Triggers the FSM event "Stop" that stops the airboss. Event handlers are stopped.
  -- @function [parent=#AIRBOSS] Stop
  -- @param #AIRBOSS self

  --- Triggers the FSM event "Stop" that stops the airboss after a delay. Event handlers are stopped.
  -- @function [parent=#AIRBOSS] __Stop
  -- @param #AIRBOSS self
  -- @param #number delay Delay in seconds.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- USER API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set welcome messages for players.
-- @param #AIRBOSS self
-- @param #boolean Switch If true, display welcome message to player.
-- @return #AIRBOSS self
function AIRBOSS:SetWelcomePlayers( Switch )

  self.welcome = Switch

  return self
end

--- Set carrier controlled area (CCA).
-- This is a large zone around the carrier, which is constantly updated wrt the carrier position.
-- @param #AIRBOSS self
-- @param #number Radius Radius of zone in nautical miles (NM). Default 50 NM.
-- @return #AIRBOSS self
function AIRBOSS:SetCarrierControlledArea( Radius )

  Radius = UTILS.NMToMeters( Radius or 50 )

  self.zoneCCA = ZONE_UNIT:New( "Carrier Controlled Area", self.carrier, Radius )

  return self
end

--- Set carrier controlled zone (CCZ).
-- This is a small zone (usually 5 NM radius) around the carrier, which is constantly updated wrt the carrier position.
-- @param #AIRBOSS self
-- @param #number Radius Radius of zone in nautical miles (NM). Default 5 NM.
-- @return #AIRBOSS self
function AIRBOSS:SetCarrierControlledZone( Radius )

  Radius = UTILS.NMToMeters( Radius or 5 )

  self.zoneCCZ = ZONE_UNIT:New( "Carrier Controlled Zone", self.carrier, Radius )

  return self
end

--- Set distance up to which water ahead is scanned for collisions.
-- @param #AIRBOSS self
-- @param #number Distance Distance in NM. Default 5 NM.
-- @return #AIRBOSS self
function AIRBOSS:SetCollisionDistance( Distance )
  self.collisiondist = UTILS.NMToMeters( Distance or 5 )
  return self
end

--- Set the default recovery case.
-- @param #AIRBOSS self
-- @param #number Case Case of recovery. Either 1, 2 or 3. Default 1.
-- @return #AIRBOSS self
function AIRBOSS:SetRecoveryCase( Case )

  -- Set default case or 1.
  self.defaultcase = Case or 1

  -- Current case init.
  self.case = self.defaultcase

  return self
end

--- Set holding pattern offset from final bearing for Case II/III recoveries.
-- Usually, this is +-15 or +-30 degrees. You should not use and offset angle >= 90 degrees, because this will cause a devision by zero in some of the equations used to calculate the approach corridor.
-- So best stick to the defaults up to 30 degrees.
-- @param #AIRBOSS self
-- @param #number Offset Offset angle in degrees. Default 0.
-- @return #AIRBOSS self
function AIRBOSS:SetHoldingOffsetAngle( Offset )

  -- Set default angle or 0.
  self.defaultoffset = Offset or 0

  -- Current offset init.
  self.holdingoffset = self.defaultoffset

  return self
end

--- Enable F10 menu to manually start recoveries.
-- @param #AIRBOSS self
-- @param #number Duration Default duration of the recovery in minutes. Default 30 min.
-- @param #number WindOnDeck Default wind on deck in knots. Default 25 knots.
-- @param #boolean Uturn U-turn after recovery window closes on=true or off=false/nil. Default off.
-- @param #number Offset Relative Marshal radial in degrees for Case II/III recoveries. Default 30°.
-- @return #AIRBOSS self
function AIRBOSS:SetMenuRecovery( Duration, WindOnDeck, Uturn, Offset )

  self.skipperMenu = true
  self.skipperTime = Duration or 30
  self.skipperSpeed = WindOnDeck or 25
  self.skipperOffset = Offset or 30

  if Uturn then
    self.skipperUturn = true
  else
    self.skipperUturn = false
  end

  return self
end

--- Add aircraft recovery time window and recovery case.
-- @param #AIRBOSS self
-- @param #string starttime Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number case Recovery case for that time slot. Number between one and three.
-- @param #number holdingoffset Only for CASE II/III: Angle in degrees the holding pattern is offset.
-- @param #boolean turnintowind If true, carrier will turn into the wind 5 minutes before the recovery window opens.
-- @param #number speed Speed in knots during turn into wind leg.
-- @param #boolean uturn If true (or nil), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @return #AIRBOSS.Recovery Recovery window.
function AIRBOSS:AddRecoveryWindow( starttime, stoptime, case, holdingoffset, turnintowind, speed, uturn )

  -- Absolute mission time in seconds.
  local Tnow = timer.getAbsTime()

  if starttime and type( starttime ) == "number" then
    starttime = UTILS.SecondsToClock( Tnow + starttime )
  end

  if stoptime and type( stoptime ) == "number" then
    stoptime = UTILS.SecondsToClock( Tnow + stoptime )
  end

  -- Input or now.
  starttime = starttime or UTILS.SecondsToClock( Tnow )

  -- Set start time.
  local Tstart = UTILS.ClockToSeconds( starttime )

  -- Set stop time.
  local Tstop = stoptime and UTILS.ClockToSeconds( stoptime ) or Tstart + 90 * 60

  -- Consistancy check for timing.
  if Tstart > Tstop then
    self:E( string.format( "ERROR: Recovery stop time %s lies before recovery start time %s! Recovery window rejected.", UTILS.SecondsToClock( Tstart ), UTILS.SecondsToClock( Tstop ) ) )
    return self
  end
  if Tstop <= Tnow then
    self:I( string.format( "WARNING: Recovery stop time %s already over. Tnow=%s! Recovery window rejected.", UTILS.SecondsToClock( Tstop ), UTILS.SecondsToClock( Tnow ) ) )
    return self
  end

  -- Case or default value.
  case = case or self.defaultcase

  -- Holding offset or default value.
  holdingoffset = holdingoffset or self.defaultoffset

  -- Offset zero for case I.
  if case == 1 then
    holdingoffset = 0
  end

  -- Increase counter.
  self.windowcount = self.windowcount + 1

  -- Recovery window.
  local recovery = {} -- #AIRBOSS.Recovery
  recovery.START = Tstart
  recovery.STOP = Tstop
  recovery.CASE = case
  recovery.OFFSET = holdingoffset
  recovery.OPEN = false
  recovery.OVER = false
  recovery.WIND = turnintowind
  recovery.SPEED = speed or 20
  recovery.ID = self.windowcount

  if uturn == nil or uturn == true then
    recovery.UTURN = true
  else
    recovery.UTURN = false
  end

  -- Add to table
  table.insert( self.recoverytimes, recovery )

  return recovery
end

--- Define a set of AI groups that are handled by the airboss.
-- @param #AIRBOSS self
-- @param Core.Set#SET_GROUP SetGroup The set of AI groups which are handled by the airboss.
-- @return #AIRBOSS self
function AIRBOSS:SetSquadronAI( SetGroup )
  self.squadsetAI = SetGroup
  return self
end

--- Define a set of AI groups that excluded from AI handling. Members of this set will be left allone by the airboss and not forced into the Marshal pattern.
-- @param #AIRBOSS self
-- @param Core.Set#SET_GROUP SetGroup The set of AI groups which are excluded.
-- @return #AIRBOSS self
function AIRBOSS:SetExcludeAI( SetGroup )
  self.excludesetAI = SetGroup
  return self
end

--- Add a group to the exclude set. If no set exists, it is created.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP Group The group to be excluded.
-- @return #AIRBOSS self
function AIRBOSS:AddExcludeAI( Group )

  self.excludesetAI = self.excludesetAI or SET_GROUP:New()

  self.excludesetAI:AddGroup( Group )

  return self
end

--- Close currently running recovery window and stop recovery ops. Recovery window is deleted.
-- @param #AIRBOSS self
-- @param #number Delay (Optional) Delay in seconds before the window is deleted.
function AIRBOSS:CloseCurrentRecoveryWindow( Delay )

  if Delay and Delay > 0 then
    -- SCHEDULER:New(nil, self.CloseCurrentRecoveryWindow, {self}, delay)
    self:ScheduleOnce( Delay, self.CloseCurrentRecoveryWindow, self )
  else
    if self:IsRecovering() and self.recoverywindow and self.recoverywindow.OPEN then
      self:RecoveryStop()
      self.recoverywindow.OPEN = false
      self.recoverywindow.OVER = true
      self:DeleteRecoveryWindow( self.recoverywindow )
    end
  end
end

--- Delete all recovery windows.
-- @param #AIRBOSS self
-- @param #number Delay (Optional) Delay in seconds before the windows are deleted.
-- @return #AIRBOSS self
function AIRBOSS:DeleteAllRecoveryWindows( Delay )

  -- Loop over all recovery windows.
  for _, recovery in pairs( self.recoverytimes ) do
    self:I( self.lid .. string.format( "Deleting recovery window ID %s", tostring( recovery.ID ) ) )
    self:DeleteRecoveryWindow( recovery, Delay )
  end

  return self
end

--- Return the recovery window of the given ID.
-- @param #AIRBOSS self
-- @param #number id The ID of the recovery window.
-- @return #AIRBOSS.Recovery Recovery window with the right ID or nil if no such window exists.
function AIRBOSS:GetRecoveryWindowByID( id )
  if id then
    for _, _window in pairs( self.recoverytimes ) do
      local window = _window -- #AIRBOSS.Recovery
      if window and window.ID == id then
        return window
      end
    end
  end
  return nil
end

--- Delete a recovery window. If the window is currently open, it is closed and the recovery stopped.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Recovery Window Recovery window.
-- @param #number Delay Delay in seconds, before the window is deleted.
function AIRBOSS:DeleteRecoveryWindow( Window, Delay )

  if Delay and Delay > 0 then
    -- Delayed call.
    -- SCHEDULER:New(nil, self.DeleteRecoveryWindow, {self, window}, delay)
    self:ScheduleOnce( Delay, self.DeleteRecoveryWindow, self, Window )
  else

    for i, _recovery in pairs( self.recoverytimes ) do
      local recovery = _recovery -- #AIRBOSS.Recovery

      if Window and Window.ID == recovery.ID then
        if Window.OPEN then
          -- Window is currently open.
          self:RecoveryStop()
        else
          table.remove( self.recoverytimes, i )
        end

      end
    end
  end
end

--- Set time before carrier turns and recovery window opens.
-- @param #AIRBOSS self
-- @param #number Interval Time interval in seconds. Default 300 sec.
-- @return #AIRBOSS self
function AIRBOSS:SetRecoveryTurnTime( Interval )
  self.dTturn = Interval or 300
  return self
end

--- Set multiplayer environment wire correction.
-- @param #AIRBOSS self
-- @param #number Dcorr Correction distance in meters. Default 12 m.
-- @return #AIRBOSS self
function AIRBOSS:SetMPWireCorrection( Dcorr )
  self.mpWireCorrection = Dcorr or 12
  return self
end

--- Set time interval for updating queues and other stuff.
-- @param #AIRBOSS self
-- @param #number TimeInterval Time interval in seconds. Default 30 sec.
-- @return #AIRBOSS self
function AIRBOSS:SetQueueUpdateTime( TimeInterval )
  self.dTqueue = TimeInterval or 30
  return self
end

--- Set time interval between LSO calls. Optimal time in the groove is ~16 seconds. So the default of 4 seconds gives around 3-4 correction calls in the groove.
-- @param #AIRBOSS self
-- @param #number TimeInterval Time interval in seconds between LSO calls. Default 4 sec.
-- @return #AIRBOSS self
function AIRBOSS:SetLSOCallInterval( TimeInterval )
  self.LSOdT = TimeInterval or 4
  return self
end

--- Airboss is a rather nice guy and not strictly following the rules. Fore example, he does allow you into the landing pattern if you are not coming from the Marshal stack.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, Airboss bends the rules a bit.
-- @return #AIRBOSS self
function AIRBOSS:SetAirbossNiceGuy( Switch )
  if Switch == true or Switch == nil then
    self.airbossnice = true
  else
    self.airbossnice = false
  end
  return self
end

--- Allow emergency landings, i.e. bypassing any pattern and go directly to final approach.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, emergency landings are okay.
-- @return #AIRBOSS self
function AIRBOSS:SetEmergencyLandings( Switch )
  if Switch == true or Switch == nil then
    self.emergency = true
  else
    self.emergency = false
  end
  return self
end

--- Despawn AI groups after they they shut down their engines.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, AI groups are despawned.
-- @return #AIRBOSS self
function AIRBOSS:SetDespawnOnEngineShutdown( Switch )
  if Switch == true or Switch == nil then
    self.despawnshutdown = true
  else
    self.despawnshutdown = false
  end
  return self
end

--- Respawn AI groups once they reach the CCA. Clears any attached airbases and allows making them land on the carrier via script.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, AI groups are respawned.
-- @return #AIRBOSS self
function AIRBOSS:SetRespawnAI( Switch )
  if Switch == true or Switch == nil then
    self.respawnAI = true
  else
    self.respawnAI = false
  end
  return self
end

--- Give AI aircraft the refueling task if a recovery tanker is present or send them to the nearest divert airfield.
-- @param #AIRBOSS self
-- @param #number LowFuelThreshold Low fuel threshold in percent. AI will go refueling if their fuel level drops below this value. Default 10 %.
-- @return #AIRBOSS self
function AIRBOSS:SetRefuelAI( LowFuelThreshold )
  self.lowfuelAI = LowFuelThreshold or 10
  return self
end

--- Set max altitude to register flights in the initial zone. Aircraft above this altitude will not be registerered.
-- @param #AIRBOSS self
-- @param #number MaxAltitude Max altitude in feet. Default 1300 ft.
-- @return #AIRBOSS self
function AIRBOSS:SetInitialMaxAlt( MaxAltitude )
  self.initialmaxalt = UTILS.FeetToMeters( MaxAltitude or 1300 )
  return self
end

--- Set folder path where the airboss sound files are located **within you mission (miz) file**.
-- The default path is "l10n/DEFAULT/" but sound files simply copied there will be removed by DCS the next time you save the mission.
-- However, if you create a new folder inside the miz file, which contains the sounds, it will not be deleted and can be used.
-- @param #AIRBOSS self
-- @param #string FolderPath The path to the sound files, e.g. "Airboss Soundfiles/".
-- @return #AIRBOSS self
function AIRBOSS:SetSoundfilesFolder( FolderPath )

  -- Check that it ends with /
  if FolderPath then
    local lastchar = string.sub( FolderPath, -1 )
    if lastchar ~= "/" then
      FolderPath = FolderPath .. "/"
    end
  end

  -- Folderpath.
  self.soundfolder = FolderPath

  -- Info message.
  self:I( self.lid .. string.format( "Setting sound files folder to: %s", self.soundfolder ) )

  return self
end

--- Set time interval for updating player status and other things.
-- @param #AIRBOSS self
-- @param #number TimeInterval Time interval in seconds. Default 0.5 sec.
-- @return #AIRBOSS self
function AIRBOSS:SetStatusUpdateTime( TimeInterval )
  self.dTstatus = TimeInterval or 0.5
  return self
end

--- Set duration how long messages are displayed to players.
-- @param #AIRBOSS self
-- @param #number Duration Duration in seconds. Default 10 sec.
-- @return #AIRBOSS self
function AIRBOSS:SetDefaultMessageDuration( Duration )
  self.Tmessage = Duration or 10
  return self
end

--- Set glideslope error thresholds.
-- @param #AIRBOSS self
-- @param #number _max
-- @param #number _min
-- @param #number High
-- @param #number HIGH
-- @param #number Low
-- @param #number LOW
-- @return #AIRBOSS self

function AIRBOSS:SetGlideslopeErrorThresholds(_max,_min, High, HIGH, Low, LOW)

  --Check if V/STOL Carrier
  if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
  
  -- allow a larger GSE for V/STOL operations --Pene Testing
  self.gle._max=_max or  0.7
  self.gle.High=High or  1.4
  self.gle.HIGH=HIGH or  1.9
  self.gle._min=_min or -0.5
  self.gle.Low=Low   or -1.2
  self.gle.LOW=LOW   or -1.5
  -- CVN values
  else
  self.gle._max=_max or  0.4
  self.gle.High=High or  0.8
  self.gle.HIGH=HIGH or  1.5
  self.gle._min=_min or -0.3
  self.gle.Low=Low   or -0.6
  self.gle.LOW=LOW   or -0.9
  end
  
  return self
end

--- Set lineup error thresholds.
-- @param #AIRBOSS self
-- @param #number _max
-- @param #number _min
-- @param #number Left
-- @param #number LeftMed
-- @param #number LEFT
-- @param #number Right
-- @param #number RightMed
-- @param #number RIGHT
-- @return #AIRBOSS self

function AIRBOSS:SetLineupErrorThresholds(_max,_min, Left, LeftMed, LEFT, Right, RightMed, RIGHT)

  --Check if V/STOL Carrier -- Pene testing
  if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
  
  -- V/STOL Values -- allow a larger LUE for V/STOL operations
  self.lue._max=_max   or  1.8
  self.lue._min=_min   or -1.8
  self.lue.Left=Left   or -2.8
  self.lue.LeftMed=LeftMed   or -3.8
  self.lue.LEFT=LEFT   or -4.5
  self.lue.Right=Right or  2.8
  self.lue.RightMed=RightMed or  3.8
  self.lue.RIGHT=RIGHT or  4.5
  -- CVN Values
  else
  self.lue._max=_max   or  0.5
  self.lue._min=_min   or -0.5
  self.lue.Left=Left   or -1.0
  self.lue.LeftMed=LeftMed   or -2.0
  self.lue.LEFT=LEFT   or -3.0
  self.lue.Right=Right or  1.0
  self.lue.RightMed=RightMed or  2.0
  self.lue.RIGHT=RIGHT or  3.0
  end
  
  return self
end

--- Set Case I Marshal radius. This is the radius of the valid zone around "the post" aircraft are supposed to be holding in the Case I Marshal stack.
-- The post is 2.5 NM port of the carrier.
-- @param #AIRBOSS self
-- @param #number Radius Radius in NM. Default 2.8 NM, which gives a diameter of 5.6 NM.
-- @return #AIRBOSS self
function AIRBOSS:SetMarshalRadius( Radius )
  self.marshalradius = UTILS.NMToMeters( Radius or 2.8 )
  return self
end

--- Optimized F10 radio menu for a single carrier. The menu entries will be stored directly under F10 Other/Airboss/ and not F10 Other/Airboss/"Carrier Alias"/.
-- **WARNING**: If you use this with two airboss objects/carriers, the radio menu will be screwed up!
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil single menu is enabled. If false, menu is for multiple carriers in the mission.
-- @return #AIRBOSS self
function AIRBOSS:SetMenuSingleCarrier( Switch )
  if Switch == true or Switch == nil then
    self.menusingle = true
  else
    self.menusingle = false
  end
  return self
end

--- Enable or disable F10 radio menu for marking zones via smoke or flares.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, menu is enabled. If false, menu is not available to players.
-- @return #AIRBOSS self
function AIRBOSS:SetMenuMarkZones( Switch )
  if Switch == nil or Switch == true then
    self.menumarkzones = true
  else
    self.menumarkzones = false
  end
  return self
end

--- Enable or disable F10 radio menu for marking zones via smoke.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, menu is enabled. If false, menu is not available to players.
-- @return #AIRBOSS self
function AIRBOSS:SetMenuSmokeZones( Switch )
  if Switch == nil or Switch == true then
    self.menusmokezones = true
  else
    self.menusmokezones = false
  end
  return self
end

--- Enable saving of player's trap sheets and specify an optional directory path.
-- @param #AIRBOSS self
-- @param #string Path (Optional) Path where to save the trap sheets.
-- @param #string Prefix (Optional) Prefix for trap sheet files. File name will be saved as *prefix_aircrafttype-0001.csv*, *prefix_aircrafttype-0002.csv*, etc.
-- @return #AIRBOSS self
function AIRBOSS:SetTrapSheet( Path, Prefix )
  if io then
    self.trapsheet = true
    self.trappath = Path
    self.trapprefix = Prefix
  else
    self:E( self.lid .. "ERROR: io is not desanitized. Cannot save trap sheet." )
  end
  return self
end

--- Specify weather the mission has set static or dynamic weather.
-- @param #AIRBOSS self
-- @param #boolean Switch If true or nil, mission uses static weather. If false, dynamic weather is used in this mission.
-- @return #AIRBOSS self
function AIRBOSS:SetStaticWeather( Switch )
  if Switch == nil or Switch == true then
    self.staticweather = true
  else
    self.staticweather = false
  end
  return self
end

--- Disable automatic TACAN activation
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetTACANoff()
  self.TACANon = false
  return self
end

--- Set TACAN channel of carrier and switches TACAN on.
-- @param #AIRBOSS self
-- @param #number Channel (Optional) TACAN channel. Default 74.
-- @param #string Mode (Optional) TACAN mode, i.e. "X" or "Y". Default "X".
-- @param #string MorseCode (Optional) Morse code identifier. Three letters, e.g. "STN". Default "STN".
-- @return #AIRBOSS self
function AIRBOSS:SetTACAN( Channel, Mode, MorseCode )

  self.TACANchannel = Channel or 74
  self.TACANmode = Mode or "X"
  self.TACANmorse = MorseCode or "STN"
  self.TACANon = true

  return self
end

--- Disable automatic ICLS activation.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetICLSoff()
  self.ICLSon = false
  return self
end

--- Set ICLS channel of carrier.
-- @param #AIRBOSS self
-- @param #number Channel (Optional) ICLS channel. Default 1.
-- @param #string MorseCode (Optional) Morse code identifier. Three letters, e.g. "STN". Default "STN".
-- @return #AIRBOSS self
function AIRBOSS:SetICLS( Channel, MorseCode )

  self.ICLSchannel = Channel or 1
  self.ICLSmorse = MorseCode or "STN"
  self.ICLSon = true

  return self
end

--- Set beacon (TACAN/ICLS) time refresh interfal in case the beacons die.
-- @param #AIRBOSS self
-- @param #number TimeInterval (Optional) Time interval in seconds. Default 1200 sec = 20 min.
-- @return #AIRBOSS self
function AIRBOSS:SetBeaconRefresh( TimeInterval )
  self.dTbeacon = TimeInterval or (20 * 60)
  return self
end

--- Set LSO radio frequency and modulation. Default frequency is 264 MHz AM.
-- @param #AIRBOSS self
-- @param #number Frequency (Optional) Frequency in MHz. Default 264 MHz.
-- @param #string Modulation (Optional) Modulation, "AM" or "FM". Default "AM".
-- @return #AIRBOSS self
function AIRBOSS:SetLSORadio( Frequency, Modulation )

  self.LSOFreq = (Frequency or 264)
  Modulation = Modulation or "AM"

  if Modulation == "FM" then
    self.LSOModu = radio.modulation.FM
  else
    self.LSOModu = radio.modulation.AM
  end

  self.LSORadio = {} -- #AIRBOSS.Radio
  self.LSORadio.frequency = self.LSOFreq
  self.LSORadio.modulation = self.LSOModu
  self.LSORadio.alias = "LSO"

  return self
end

--- Set carrier radio frequency and modulation. Default frequency is 305 MHz AM.
-- @param #AIRBOSS self
-- @param #number Frequency (Optional) Frequency in MHz. Default 305 MHz.
-- @param #string Modulation (Optional) Modulation, "AM" or "FM". Default "AM".
-- @return #AIRBOSS self
function AIRBOSS:SetMarshalRadio( Frequency, Modulation )

  self.MarshalFreq = Frequency or 305
  Modulation = Modulation or "AM"

  if Modulation == "FM" then
    self.MarshalModu = radio.modulation.FM
  else
    self.MarshalModu = radio.modulation.AM
  end

  self.MarshalRadio = {} -- #AIRBOSS.Radio
  self.MarshalRadio.frequency = self.MarshalFreq
  self.MarshalRadio.modulation = self.MarshalModu
  self.MarshalRadio.alias = "MARSHAL"

  return self
end

--- Set unit name for sending radio messages.
-- @param #AIRBOSS self
-- @param #string unitname Name of the unit.
-- @return #AIRBOSS self
function AIRBOSS:SetRadioUnitName( unitname )
  self.senderac = unitname
  return self
end

--- Set unit acting as radio relay for the LSO radio.
-- @param #AIRBOSS self
-- @param #string unitname Name of the unit.
-- @return #AIRBOSS self
function AIRBOSS:SetRadioRelayLSO( unitname )
  self.radiorelayLSO = unitname
  return self
end

--- Set unit acting as radio relay for the Marshal radio.
-- @param #AIRBOSS self
-- @param #string unitname Name of the unit.
-- @return #AIRBOSS self
function AIRBOSS:SetRadioRelayMarshal( unitname )
  self.radiorelayMSH = unitname
  return self
end

--- Use user sound output instead of radio transmission for messages. Might be handy if radio transmissions are broken.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetUserSoundRadio()
  self.usersoundradio = true
  return self
end

--- Test LSO radio sounds.
-- @param #AIRBOSS self
-- @param #number delay Delay in seconds be sound check starts.
-- @return #AIRBOSS self
function AIRBOSS:SoundCheckLSO( delay )

  if delay and delay > 0 then
    -- Delayed call.
    -- SCHEDULER:New(nil, AIRBOSS.SoundCheckLSO, {self}, delay)
    self:ScheduleOnce( delay, AIRBOSS.SoundCheckLSO, self )
  else

    local text = "Playing LSO sound files:"

    for _name, _call in pairs( self.LSOCall ) do
      local call = _call -- #AIRBOSS.RadioCall

      -- Debug text.
      text = text .. string.format( "\nFile=%s.%s, duration=%.2f sec, loud=%s, subtitle=\"%s\".", call.file, call.suffix, call.duration, tostring( call.loud ), call.subtitle )

      -- Radio transmission to queue.
      self:RadioTransmission( self.LSORadio, call, false )

      -- Also play the loud version.
      if call.loud then
        self:RadioTransmission( self.LSORadio, call, true )
      end
    end

    -- Debug message.
    self:I( self.lid .. text )

  end
end

--- Test Marshal radio sounds.
-- @param #AIRBOSS self
-- @param #number delay Delay in seconds be sound check starts.
-- @return #AIRBOSS self
function AIRBOSS:SoundCheckMarshal( delay )

  if delay and delay > 0 then
    -- Delayed call.
    -- SCHEDULER:New(nil, AIRBOSS.SoundCheckMarshal, {self}, delay)
    self:ScheduleOnce( delay, AIRBOSS.SoundCheckMarshal, self )
  else

    local text = "Playing Marshal sound files:"

    for _name, _call in pairs( self.MarshalCall ) do
      local call = _call -- #AIRBOSS.RadioCall

      -- Debug text.
      text = text .. string.format( "\nFile=%s.%s, duration=%.2f sec, loud=%s, subtitle=\"%s\".", call.file, call.suffix, call.duration, tostring( call.loud ), call.subtitle )

      -- Radio transmission to queue.
      self:RadioTransmission( self.MarshalRadio, call, false )

      -- Also play the loud version.
      if call.loud then
        self:RadioTransmission( self.MarshalRadio, call, true )
      end
    end

    -- Debug message.
    self:I( self.lid .. text )

  end
end

--- Set number of aircraft units, which can be in the landing pattern before the pattern is full.
-- @param #AIRBOSS self
-- @param #number nmax Max number. Default 4. Minimum is 1, maximum is 6.
-- @return #AIRBOSS self
function AIRBOSS:SetMaxLandingPattern( nmax )
  nmax = nmax or 4
  nmax = math.max( nmax, 1 )
  nmax = math.min( nmax, 6 )
  self.Nmaxpattern = nmax
  return self
end

--- Set number available Case I Marshal stacks. If Marshal stacks are full, flights requesting Marshal will be told to hold outside 10 NM zone until a stack becomes available again.
-- Marshal stacks for Case II/III are unlimited.
-- @param #AIRBOSS self
-- @param #number nmax Max number of stacks available to players and AI flights. Default 3, i.e. angels 2, 3, 4. Minimum is 1.
-- @return #AIRBOSS self
function AIRBOSS:SetMaxMarshalStacks( nmax )
  self.Nmaxmarshal = nmax or 3
  self.Nmaxmarshal = math.max( self.Nmaxmarshal, 1 )
  return self
end

--- Set max number of section members. Minimum is one, i.e. the section lead itself. Maximum number is four. Default is two, i.e. the lead and one other human flight.
-- @param #AIRBOSS self
-- @param #number nmax Number of max allowed members including the lead itself. For example, Nmax=2 means a section lead plus one member.
-- @return #AIRBOSS self
function AIRBOSS:SetMaxSectionSize( nmax )
  nmax = nmax or 2
  nmax = math.max( nmax, 1 )
  nmax = math.min( nmax, 4 )
  self.NmaxSection = nmax - 1 -- We substract one because internally the section lead is not counted!
  return self
end

--- Set max number of flights per stack. All members of a section count as one "flight".
-- @param #AIRBOSS self
-- @param #number nmax Number of max allowed flights per stack. Default is two. Minimum is one, maximum is 4.
-- @return #AIRBOSS self
function AIRBOSS:SetMaxFlightsPerStack( nmax )
  nmax = nmax or 2
  nmax = math.max( nmax, 1 )
  nmax = math.min( nmax, 4 )
  self.NmaxStack = nmax
  return self
end

--- Handle AI aircraft.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetHandleAION()
  self.handleai = true
  return self
end

--- Will play the inbound calls, commencing, initial, etc. from the player when requesteing marshal
-- @param #AIRBOSS self
-- @param #AIRBOSS status Boolean to activate (true) / deactivate (false) the radio inbound calls (default is ON)
-- @return #AIRBOSS self
function AIRBOSS:SetExtraVoiceOvers(status)
  self.xtVoiceOvers=status
  return self
end

--- Will simulate the inbound call, commencing, initial, etc from the AI when requested by Airboss
-- @param #AIRBOSS self
-- @param #AIRBOSS status Boolean to activate (true) / deactivate (false) the radio inbound calls (default is ON)
-- @return #AIRBOSS self
function AIRBOSS:SetExtraVoiceOversAI(status)
  self.xtVoiceOversAI=status
  return self
end
 
--- Do not handle AI aircraft.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetHandleAIOFF()
  self.handleai = false
  return self
end

--- Define recovery tanker associated with the carrier.
-- @param #AIRBOSS self
-- @param Ops.RecoveryTanker#RECOVERYTANKER recoverytanker Recovery tanker object.
-- @return #AIRBOSS self
function AIRBOSS:SetRecoveryTanker( recoverytanker )
  self.tanker = recoverytanker
  return self
end

--- Define an AWACS associated with the carrier.
-- @param #AIRBOSS self
-- @param Ops.RecoveryTanker#RECOVERYTANKER awacs AWACS (recovery tanker) object.
-- @return #AIRBOSS self
function AIRBOSS:SetAWACS( awacs )
  self.awacs = awacs
  return self
end

--- Set default player skill. New players will be initialized with this skill.
--
-- * "Flight Student" = @{#AIRBOSS.Difficulty.Easy}
-- * "Naval Aviator" = @{#AIRBOSS.Difficulty.Normal}
-- * "TOPGUN Graduate" = @{#AIRBOSS.Difficulty.Hard}
-- @param #AIRBOSS self
-- @param #string skill Player skill. Default "Naval Aviator".
-- @return #AIRBOSS self
function AIRBOSS:SetDefaultPlayerSkill( skill )

  -- Set skill or normal.
  self.defaultskill = skill or AIRBOSS.Difficulty.NORMAL

  -- Check that defualt skill is valid.
  local gotit = false
  for _, _skill in pairs( AIRBOSS.Difficulty ) do
    if _skill == self.defaultskill then
      gotit = true
    end
  end

  -- If invalid user input, fall back to normal.
  if not gotit then
    self.defaultskill = AIRBOSS.Difficulty.NORMAL
    self:E( self.lid .. string.format( "ERROR: Invalid default skill = %s. Resetting to Naval Aviator.", tostring( skill ) ) )
  end

  return self
end

--- Enable auto save of player results each time a player is *finally* graded. *Finally* means after the player landed on the carrier! After intermediate passes (bolter or waveoff) the stats are *not* saved.
-- @param #AIRBOSS self
-- @param #string path Path where to save the asset data file. Default is the DCS root installation directory or your "Saved Games\\DCS" folder if lfs was desanitized.
-- @param #string filename File name. Default is generated automatically from airboss carrier name/alias.
-- @return #AIRBOSS self
function AIRBOSS:SetAutoSave( path, filename )
  self.autosave = true
  self.autosavepath = path
  self.autosavefile = filename
  return self
end

--- Activate debug mode. Display debug messages on screen.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetDebugModeON()
  self.Debug = true
  return self
end

--- Carrier patrols ad inifintum. If the last waypoint is reached, it will go to waypoint one and repeat its route.
-- @param #AIRBOSS self
-- @param #boolean switch If true or nil, patrol until the end of time. If false, go along the waypoints once and stop.
-- @return #AIRBOSS self
function AIRBOSS:SetPatrolAdInfinitum( switch )
  if switch == false then
    self.adinfinitum = false
  else
    self.adinfinitum = true
  end
  return self
end

--- Set the magnetic declination (or variation). By default this is set to the standard declination of the map.
-- @param #AIRBOSS self
-- @param #number declination Declination in degrees or nil for default declination of the map.
-- @return #AIRBOSS self
function AIRBOSS:SetMagneticDeclination( declination )
  self.magvar = declination or UTILS.GetMagneticDeclination()
  return self
end

--- Deactivate debug mode. This is also the default setting.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:SetDebugModeOFF()
  self.Debug = false
  return self
end


--- Set FunkMan socket. LSO grades and trap sheets will be send to your Discord bot.
-- **Requires running FunkMan program**.
-- @param #AIRBOSS self
-- @param #number Port Port. Default `10042`.
-- @param #string Host Host. Default `"127.0.0.1"`.
-- @return #AIRBOSS self
function AIRBOSS:SetFunkManOn(Port, Host)
  
  self.funkmanSocket=SOCKET:New(Port, Host)
  
  return self
end

--- Get next time the carrier will start recovering aircraft.
-- @param #AIRBOSS self
-- @param #boolean InSeconds If true, abs. mission time seconds is returned. Default is a clock #string.
-- @return #string Clock start (or start time in abs. seconds).
-- @return #string Clock stop (or stop time in abs. seconds).
function AIRBOSS:GetNextRecoveryTime( InSeconds )
  if self.recoverywindow then
    if InSeconds then
      return self.recoverywindow.START, self.recoverywindow.STOP
    else
      return UTILS.SecondsToClock( self.recoverywindow.START ), UTILS.SecondsToClock( self.recoverywindow.STOP )
    end
  else
    if InSeconds then
      return -1, -1
    else
      return "?", "?"
    end
  end
end

--- Check if carrier is recovering aircraft.
-- @param #AIRBOSS self
-- @return #boolean If true, time slot for recovery is open.
function AIRBOSS:IsRecovering()
  return self:is( "Recovering" )
end

--- Check if carrier is idle, i.e. no operations are carried out.
-- @param #AIRBOSS self
-- @return #boolean If true, carrier is in idle state.
function AIRBOSS:IsIdle()
  return self:is( "Idle" )
end

--- Check if recovery of aircraft is paused.
-- @param #AIRBOSS self
-- @return #boolean If true, recovery is paused
function AIRBOSS:IsPaused()
  return self:is( "Paused" )
end

--- Activate TACAN and ICLS beacons.
-- @param #AIRBOSS self
function AIRBOSS:_ActivateBeacons()
  self:T( self.lid .. string.format( "Activating Beacons (TACAN=%s, ICLS=%s)", tostring( self.TACANon ), tostring( self.ICLSon ) ) )

  -- Activate TACAN.
  if self.TACANon then
    self:I( self.lid .. string.format( "Activating TACAN Channel %d%s (%s)", self.TACANchannel, self.TACANmode, self.TACANmorse ) )
    self.beacon:ActivateTACAN( self.TACANchannel, self.TACANmode, self.TACANmorse, true )
  end

  -- Activate ICLS.
  if self.ICLSon then
    self:I( self.lid .. string.format( "Activating ICLS Channel %d (%s)", self.ICLSchannel, self.ICLSmorse ) )
    self.beacon:ActivateICLS( self.ICLSchannel, self.ICLSmorse )
  end

  -- Set time stamp.
  self.Tbeacon = timer.getTime()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM event functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the AIRBOSS. Adds event handlers and schedules status updates of requests and queue.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStart( From, Event, To )

  -- Events are handled my MOOSE.
  self:I( self.lid .. string.format( "Starting AIRBOSS v%s for carrier unit %s of type %s on map %s", AIRBOSS.version, self.carrier:GetName(), self.carriertype, self.theatre ) )

  -- Activate TACAN and ICLS if desired.
  self:_ActivateBeacons()

  -- Schedule radio queue checks.
  -- self.RQLid=self.radiotimer:Schedule(nil, AIRBOSS._CheckRadioQueue, {self, self.RQLSO,     "LSO"},     1, 0.1)
  -- self.RQMid=self.radiotimer:Schedule(nil, AIRBOSS._CheckRadioQueue, {self, self.RQMarshal, "MARSHAL"}, 1, 0.1)

  -- self:I("FF: starting timer.scheduleFunction")
  -- timer.scheduleFunction(AIRBOSS._CheckRadioQueueT, {airboss=self, radioqueue=self.RQLSO,     name="LSO"},     timer.getTime()+1)
  -- timer.scheduleFunction(AIRBOSS._CheckRadioQueueT, {airboss=self, radioqueue=self.RQMarshal, name="MARSHAL"}, timer.getTime()+1)

  -- Initial carrier position and orientation.
  self.Cposition = self:GetCoordinate()
  self.Corientation = self.carrier:GetOrientationX()
  self.Corientlast = self.Corientation
  self.Tpupdate = timer.getTime()

  -- Check if no recovery window is set. DISABLED!
  if #self.recoverytimes == 0 and false then

    -- Open window in 15 minutes for 3 hours.
    local Topen = timer.getAbsTime() + 15 * 60
    local Tclose = Topen + 3 * 60 * 60

    -- Add window.
    self:AddRecoveryWindow( UTILS.SecondsToClock( Topen ), UTILS.SecondsToClock( Tclose ) )
  end

  -- Check Recovery time.s
  self:_CheckRecoveryTimes()

  -- Time stamp for checking queues. We substract 60 seconds so the routine is called right after status is called the first time.
  self.Tqueue = timer.getTime() - 60

  -- Handle events.
  self:HandleEvent( EVENTS.Birth )
  self:HandleEvent( EVENTS.Land )
  self:HandleEvent( EVENTS.EngineShutdown )
  self:HandleEvent( EVENTS.Takeoff )
  self:HandleEvent( EVENTS.Crash )
  self:HandleEvent( EVENTS.Ejection )
  self:HandleEvent( EVENTS.PlayerLeaveUnit, self._PlayerLeft )
  self:HandleEvent( EVENTS.MissionEnd )
  self:HandleEvent( EVENTS.RemoveUnit )

  -- self.StatusScheduler=SCHEDULER:New(self)
  -- self.StatusScheduler:Schedule(self, self._Status, {}, 1, 0.5)

  self.StatusTimer = TIMER:New( self._Status, self ):Start( 2, 0.5 )

  -- Start status check in 1 second.
  self:__Status( 1 )
end

--- On after Status event. Checks for new flights, updates queue and checks player status.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStatus( From, Event, To )

  -- Get current time.
  local time = timer.getTime()

  -- Update marshal and pattern queue every 30 seconds.
  if time - self.Tqueue > self.dTqueue then

    -- Get time.
    local clock = UTILS.SecondsToClock( timer.getAbsTime() )
    local eta = UTILS.SecondsToClock( self:_GetETAatNextWP() )

    -- Current heading and position of the carrier.
    local hdg = self:GetHeading()
    local pos = self:GetCoordinate()
    local speed = self.carrier:GetVelocityKNOTS()

    -- Check water is ahead.
    local collision = false -- self:_CheckCollisionCoord(pos:Translate(self.collisiondist, hdg))

    local holdtime = 0
    if self.holdtimestamp then
      holdtime = timer.getTime() - self.holdtimestamp
    end

    -- Check if carrier is stationary.
    local NextWP = self:_GetNextWaypoint()
    local ExpectedSpeed = UTILS.MpsToKnots( NextWP:GetVelocity() )
    if speed < 0.5 and ExpectedSpeed > 0 and not (self.detour or self.turnintowind) then
      if not self.holdtimestamp then
        self:E( self.lid .. string.format( "Carrier came to an unexpected standstill. Trying to re-route in 3 min. Speed=%.1f knots, expected=%.1f knots", speed, ExpectedSpeed ) )
        self.holdtimestamp = timer.getTime()
      else
        if holdtime > 3 * 60 then
          local coord = self:GetCoordinate():Translate( 500, hdg + 10 )
          -- coord:MarkToAll("Re-route after standstill.")
          self:CarrierResumeRoute( coord )
          self.holdtimestamp = nil
        end
      end
    end

    -- Debug info.
    local text = string.format( "Time %s - Status %s (case=%d) - Speed=%.1f kts - Heading=%d - WP=%d - ETA=%s - Turning=%s - Collision Warning=%s - Detour=%s - Turn Into Wind=%s - Holdtime=%d sec", clock, self:GetState(), self.case, speed, hdg, self.currentwp, eta, tostring( self.turning ), tostring( collision ), tostring( self.detour ), tostring( self.turnintowind ), holdtime )
    self:T( self.lid .. text )

    -- Players online:
    text = "Players:"
    local i = 0
    for _name, _player in pairs( self.players ) do
      i = i + 1
      local player = _player -- #AIRBOSS.FlightGroup
      text = text .. string.format( "\n%d.) %s: Step=%s, Unit=%s, Airframe=%s", i, tostring( player.name ), tostring( player.step ), tostring( player.unitname ), tostring( player.actype ) )
    end
    if i == 0 then
      text = text .. " none"
    end
    self:I( self.lid .. text )

    -- Check for collision.
    if collision then

      -- We are currently turning into the wind.
      if self.turnintowind then

        -- Carrier resumes its initial route. This disables turnintowind switch.
        self:CarrierResumeRoute( self.Creturnto )

        -- Since current window would stay open, we disable the WIND switch.
        if self:IsRecovering() and self.recoverywindow and self.recoverywindow.WIND then
          -- Disable turn into the wind for this window so that we do not do this all over again.
          self.recoverywindow.WIND = false
        end

      end

    end

    -- Check recovery times and start/stop recovery mode if necessary.
    self:_CheckRecoveryTimes()

    -- Remove dead/zombie flight groups. Player leaving the server whilst in pattern etc.
    -- self:_RemoveDeadFlightGroups()

    -- Scan carrier zone for new aircraft.
    self:_ScanCarrierZone()

    -- Check marshal and pattern queues.
    self:_CheckQueue()

    -- Check if carrier is currently turning.
    self:_CheckCarrierTurning()

    -- Check if marshal pattern of AI needs an update.
    self:_CheckPatternUpdate()

    -- Time stamp.
    self.Tqueue = time
  end

  -- (Re-)activate TACAN and ICLS channels.
  if time - self.Tbeacon > self.dTbeacon then
    self:_ActivateBeacons()
  end

  -- Call status every ~0.5 seconds.
  self:__Status( -30 )

end

--- Check AI status. Pattern queue AI in the groove? Marshal queue AI arrived in holding zone?
-- @param #AIRBOSS self
function AIRBOSS:_Status()

  -- Check player status.
  self:_CheckPlayerStatus()

  -- Check AI landing pattern status
  self:_CheckAIStatus()

end

--- Check AI status. Pattern queue AI in the groove? Marshal queue AI arrived in holding zone?
-- @param #AIRBOSS self
function AIRBOSS:_CheckAIStatus()

  -- Loop over all flights in Marshal stack.
  for _, _flight in pairs( self.Qmarshal ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Only AI!
    if flight.ai then

      -- Get fuel amount in %.
      local fuel = flight.group:GetFuelMin() * 100

      -- Debug text.
      local text = string.format( "Group %s fuel=%.1f %%", flight.groupname, fuel )
      self:T3( self.lid .. text )

      -- Check if flight is low on fuel and not yet refueling.
      if self.lowfuelAI and fuel < self.lowfuelAI and not flight.refueling then

        -- Send AI for refueling at tanker or divert field.
        self:_RefuelAI( flight )

        -- Remove flight from marshal queue.
        self:_RemoveFlightFromMarshalQueue( flight, true )

      end

    end
  end

  -- Loop over all flights in landing pattern.
  for _, _flight in pairs( self.Qpattern ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Only AI!
    if flight.ai then

      -- Loop over all units in AI flight.
      for _, _element in pairs( flight.elements ) do
        local element = _element -- #AIRBOSS.FlightElement

        -- Unit
        local unit = element.unit

        -- Get lineup and distance to carrier.
        local lineup = self:_Lineup( unit, true )

        local unitcoord = unit:GetCoord()

        local dist = unitcoord:Get2DDistance( self:GetCoord() )

        -- Distance in NM.
        local distance = UTILS.MetersToNM( dist )

        -- Altitude in ft.
        local alt = UTILS.MetersToFeet( unitcoord.y )

        -- Check if parameters are right and flight is in the groove.
        if lineup < 2 and distance <= 0.75 and alt < 500 and not element.ballcall then

          -- Paddles: Call the ball!
          self:RadioTransmission( self.LSORadio, self.LSOCall.CALLTHEBALL, nil, nil, nil, true )

          -- Pilot: "405, Hornet Ball, 3.2"
          self:_LSOCallAircraftBall( element.onboard, self:_GetACNickname( unit:GetTypeName() ), self:_GetFuelState( unit ) / 1000 )

          -- Paddles: Roger ball after 0.5 seconds.
          self:RadioTransmission( self.LSORadio, self.LSOCall.ROGERBALL, nil, nil, 0.5, true )

          -- Flight element called the ball.
          element.ballcall = true

          -- This is for the whole flight. Maybe we need it.
          flight.ballcall = true
        end

      end
    end
  end

end

--- Check if player in the landing pattern is too close to another aircarft in the pattern.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData player Player data.
function AIRBOSS:_CheckPlayerPatternDistance( player )

  -- Check if player is too close to another aircraft in the pattern.
  -- TODO: At which steps is the really necessary. Case II/III?
  if  player.step==AIRBOSS.PatternStep.INITIAL    or
      player.step==AIRBOSS.PatternStep.BREAKENTRY or
      player.step==AIRBOSS.PatternStep.EARLYBREAK or
      player.step==AIRBOSS.PatternStep.LATEBREAK  or
      player.step==AIRBOSS.PatternStep.ABEAM      or
      player.step==AIRBOSS.PatternStep.GROOVE_XX  or
      player.step==AIRBOSS.PatternStep.GROOVE_IM  then

    -- Right step but not implemented.
    return

  else
    -- Wrong step - no check performed.
    return
  end

  -- Nothing to do since we check only in the pattern.
  if #self.Qpattern == 0 then
    return
  end

  --- Function that checks if unit1 is too close to unit2.
  local function _checkclose( _unit1, _unit2 )

    local unit1 = _unit1 -- Wrapper.Unit#UNIT
    local unit2 = _unit2 -- Wrapper.Unit#UNIT

    if (not unit1) or (not unit2) then
      return false
    end

    -- Check that this is not the same unit.
    if unit1:GetName() == unit2:GetName() then
      return false
    end

    -- Return false when unit2 is not in air? Could be on the carrier.
    if not unit2:InAir() then
      return false
    end

    -- Positions of units.
    local c1 = unit1:GetCoordinate()
    local c2 = unit2:GetCoordinate()

    -- Vector from unit1 to unit2
    local vec12 = { x = c2.x - c1.x, y = 0, z = c2.z - c1.z } -- DCS#Vec3

    -- Distance between units.
    local dist = UTILS.VecNorm( vec12 )

    -- Orientation of unit 1 in space.
    local vec1 = unit1:GetOrientationX()
    vec1.y = 0

    -- Get angle between the two orientation vectors. Does the player aircraft nose point into the direction of the other aircraft? (Could be behind him!)
    local rhdg = math.deg( math.acos( UTILS.VecDot( vec12, vec1 ) / UTILS.VecNorm( vec12 ) / UTILS.VecNorm( vec1 ) ) )

    -- Check altitude difference?
    local dalt = math.abs( c2.y - c1.y )

    -- 650 feet ~= 200 meters distance between flights
    local dcrit = UTILS.FeetToMeters( 650 )

    -- Direction in 30 degrees cone and distance < 200 meters and altitude difference <50
    -- TODO: Test parameter values.
    if math.abs( rhdg ) < 10 and dist < dcrit and dalt < 50 then
      return true
    else
      return false
    end
  end

  -- Loop over all other flights in pattern.
  for _, _flight in pairs( self.Qpattern ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Now we still need to loop over all units in the flight.
    for _, _element in pairs( flight.elements ) do
      local element = _element -- #AIRBOSS.FlightElement

      -- Check if player is too close to another aircraft in the pattern.
      local tooclose = _checkclose( player.unit, element.unit )

      -- Check if we are too close.
      if tooclose then

        -- Debug message.
        local text = string.format( "Player %s too close (<200 meters) to aircraft %s!", player.name, element.unit:GetName() )
        self:T2( self.lid .. text )
        -- MESSAGE:New(text, 20, "DEBUG"):ToAllIf(self.Debug)

        -- Inform player that he is too close.
        -- TODO: Pattern wave off?
        -- TODO: This function needs a switch so that it is not called over and over again!
        -- local text=string.format("you're getting too close to the aircraft, %s, ahead of you!\nKeep a min distance of at least 650 ft.", element.onboard)
        -- self:MessageToPlayer(player, text, "LSO")
      end

    end
  end

end

--- Check recovery times and start/stop recovery mode of aircraft.
-- @param #AIRBOSS self
function AIRBOSS:_CheckRecoveryTimes()

  -- Get current abs time.
  local time = timer.getAbsTime()
  local Cnow = UTILS.SecondsToClock( time )

  -- Debug output:
  local text = string.format( self.lid .. "Recovery time windows:" )

  -- Handle case with no recoveries.
  if #self.recoverytimes == 0 then
    text = text .. " none!"
  end

  -- Sort windows wrt to start time.
  local _sort = function( a, b )
    return a.START < b.START
  end
  table.sort( self.recoverytimes, _sort )

  -- Next recovery case in the future.
  local nextwindow = nil -- #AIRBOSS.Recovery
  local currwindow = nil -- #AIRBOSS.Recovery

  -- Loop over all slots.
  for _, _recovery in pairs( self.recoverytimes ) do
    local recovery = _recovery -- #AIRBOSS.Recovery

    -- Get start/stop clock strings.
    local Cstart = UTILS.SecondsToClock( recovery.START )
    local Cstop = UTILS.SecondsToClock( recovery.STOP )

    -- Status info.
    local state = ""

    -- Check if start time passed.
    if time >= recovery.START then
      -- Start time has passed.

      if time < recovery.STOP then
        -- Stop time has NOT passed.

        if self:IsRecovering() then
          -- Carrier is already recovering.
          state = "in progress"
        else
          -- Start recovery.
          self:RecoveryStart( recovery.CASE, recovery.OFFSET )
          state = "starting now"
          recovery.OPEN = true
        end

        -- Set current recovery window.
        currwindow = recovery

      else -- Stop time HAS passed.

        if self:IsRecovering() and not recovery.OVER then

          -- Get number of airborne aircraft units(!) currently in pattern.
          local _, npattern = self:_GetQueueInfo( self.Qpattern )

          if npattern > 0 then

            -- Extend recovery time. 5 min per flight.
            local extmin = 5 * npattern
            recovery.STOP = recovery.STOP + extmin * 60

            local text = string.format( "We still got flights in the pattern.\nRecovery time prolonged by %d minutes.\nNow get your act together and no more bolters!", extmin )
            self:MessageToPattern( text, "AIRBOSS", "99", 10, false, nil )

          else

            -- Set carrier to idle.
            self:RecoveryStop()
            state = "closing now"

            -- Closed.
            recovery.OPEN = false

            -- Window just closed.
            recovery.OVER = true

          end
        else

          -- Carrier is already idle.
          state = "closed"
        end

      end

    else
      -- This recovery is in the future.
      state = "in the future"

      -- This is the next to come as we sorted by start time.
      if nextwindow == nil then
        nextwindow = recovery
        state = "next in line"
      end
    end

    -- Debug text.
    text = text .. string.format( "\n- Start=%s Stop=%s Case=%d Offset=%d Open=%s Closed=%s Status=\"%s\"", Cstart, Cstop, recovery.CASE, recovery.OFFSET, tostring( recovery.OPEN ), tostring( recovery.OVER ), state )
  end

  -- Debug output.
  self:T( self.lid .. text )

  -- Current recovery window.
  self.recoverywindow = nil

  if self:IsIdle() then
    -----------------------------------------------------------------------------------------------------------------
    -- Carrier is idle: We need to make sure that incoming flights get the correct recovery info of the next window.
    -----------------------------------------------------------------------------------------------------------------

    -- Check if there is a next windows defined.
    if nextwindow then

      -- Set case and offset of the next window.
      self:RecoveryCase( nextwindow.CASE, nextwindow.OFFSET )

      -- Check if time is less than 5 minutes.
      if nextwindow.WIND and nextwindow.START - time < self.dTturn and not self.turnintowind then

        -- Check that wind is blowing from a direction > 5° different from the current heading.
        local hdg = self:GetHeading()
        local wind = self:GetHeadingIntoWind()
        local delta = self:_GetDeltaHeading( hdg, wind )
        local uturn = delta > 5

        -- Check if wind is actually blowing (0.1 m/s = 0.36 km/h = 0.2 knots)
        local _, vwind = self:GetWind()
        if vwind < 0.1 then
          uturn = false
        end

        -- U-turn disabled by user input.
        if not nextwindow.UTURN then
          uturn = false
        end

        -- Debug info
        self:T( self.lid .. string.format( "Heading=%03d°, Wind=%03d° %.1f kts, Delta=%03d° ==> U-turn=%s", hdg, wind, UTILS.MpsToKnots( vwind ), delta, tostring( uturn ) ) )

        -- Time into the wind 1 day or if longer recovery time + the 5 min early.
        local t = math.max( nextwindow.STOP - nextwindow.START + self.dTturn, 60 * 60 * 24 )

        -- Recovery wind on deck in knots.
        local v = UTILS.KnotsToMps( nextwindow.SPEED )

        -- Check that we do not go above max possible speed.
        local vmax = self.carrier:GetSpeedMax() / 3.6 -- convert to m/s
        v = math.min( v, vmax )

        -- Route carrier into the wind. Sets self.turnintowind=true
        self:CarrierTurnIntoWind( t, v, uturn )

      end

      -- Set current recovery window.
      self.recoverywindow = nextwindow

    else
      -- No next window. Set default values.
      self:RecoveryCase()
    end

  else
    -------------------------------------------------------------------------------------
    -- Carrier is recovering: We set the recovery window to the current one or next one.
    -------------------------------------------------------------------------------------

    if currwindow then
      self.recoverywindow = currwindow
    else
      self.recoverywindow = nextwindow
    end
  end

  self:T2( { "FF", recoverywindow = self.recoverywindow } )
end

--- Get section lead of a flight.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight
-- @return #AIRBOSS.FlightGroup The leader of the section. Could be the flight itself.
-- @return #boolean If true, flight is lead.
function AIRBOSS:_GetFlightLead( flight )

  if flight.name ~= flight.seclead then
    -- Section lead of flight.
    local lead = self.players[flight.seclead]
    return lead, false
  else
    -- Flight without section or section lead.
    return flight, true
  end

end

--- On before "RecoveryCase" event. Check if case or holding offset did change. If not transition is denied.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Case The recovery case (1, 2 or 3) to switch to.
-- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.
function AIRBOSS:onbeforeRecoveryCase( From, Event, To, Case, Offset )

  -- Input or default value.
  Case = Case or self.defaultcase

  -- Input or default value
  Offset = Offset or self.defaultoffset

  if Case == self.case and Offset == self.holdingoffset then
    return false
  end

  return true
end

--- On after "RecoveryCase" event. Sets new aircraft recovery case. Updates
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Case The recovery case (1, 2 or 3) to switch to.
-- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.
function AIRBOSS:onafterRecoveryCase( From, Event, To, Case, Offset )

  -- Input or default value.
  Case = Case or self.defaultcase

  -- Input or default value
  Offset = Offset or self.defaultoffset

  -- Debug output.
  local text = string.format( "Switching recovery case %d ==> %d", self.case, Case )
  if Case > 1 then
    text = text .. string.format( " Holding offset angle %d degrees.", Offset )
  end
  MESSAGE:New( text, 20, self.alias ):ToAllIf( self.Debug )
  self:T( self.lid .. text )

  -- Set new recovery case.
  self.case = Case

  -- Set holding offset.
  self.holdingoffset = Offset

  -- Update case of all flights not in Marshal or Pattern queue.
  for _, _flight in pairs( self.flights ) do
    local flight = _flight -- #AIRBOSS.FlightGroup
    if not (self:_InQueue( self.Qmarshal, flight.group ) or self:_InQueue( self.Qpattern, flight.group )) then

      -- Also not for section members. These are not in the marshal or pattern queue if the lead is.
      if flight.name ~= flight.seclead then
        local lead = self.players[flight.seclead]

        if lead and not (self:_InQueue( self.Qmarshal, lead.group ) or self:_InQueue( self.Qpattern, lead.group )) then
          -- This is section member and the lead is not in the Marshal or Pattern queue.
          flight.case = self.case
        end

      else

        -- This is a flight without section or the section lead.
        flight.case = self.case

      end

    end
  end
end

--- On after "RecoveryStart" event. Recovery of aircraft is started and carrier switches to state "Recovering".
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Case The recovery case (1, 2 or 3) to start.
-- @param #number Offset Holding pattern offset angle in degrees for CASE II/III recoveries.
function AIRBOSS:onafterRecoveryStart( From, Event, To, Case, Offset )

  -- Input or default value.
  Case = Case or self.defaultcase

  -- Input or default value.
  Offset = Offset or self.defaultoffset

  -- Radio message: "99, starting aircraft recovery case X ops. (Marshal radial XYZ degrees)"
  self:_MarshalCallRecoveryStart( Case )

  -- Switch to case.
  self:RecoveryCase( Case, Offset )
end

--- On after "RecoveryStop" event. Recovery of aircraft is stopped and carrier switches to state "Idle". Running recovery window is deleted.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterRecoveryStop( From, Event, To )
  -- Debug output.
  self:T( self.lid .. string.format( "Stopping aircraft recovery." ) )

  -- Recovery ops stopped message.
  self:_MarshalCallRecoveryStopped( self.case )

  -- If carrier is currently heading into the wind, we resume the original route.
  if self.turnintowind then

    -- Coordinate to return to.
    local coord = self.Creturnto

    -- No U-turn.
    if self.recoverywindow and self.recoverywindow.UTURN == false then
      coord = nil
    end

    -- Carrier resumes route.
    self:CarrierResumeRoute( coord )
  end

  -- Delete current recovery window if open.
  if self.recoverywindow and self.recoverywindow.OPEN == true then
    self.recoverywindow.OPEN = false
    self.recoverywindow.OVER = true
    self:DeleteRecoveryWindow( self.recoverywindow )
  end

  -- Check recovery windows. This sets self.recoverywindow to the next window.
  self:_CheckRecoveryTimes()
end

--- On after "RecoveryPause" event. Recovery of aircraft is paused. Marshal queue stays intact.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number duration Duration of pause in seconds. After that recovery is resumed automatically.
function AIRBOSS:onafterRecoveryPause( From, Event, To, duration )
  -- Debug output.
  self:T( self.lid .. string.format( "Pausing aircraft recovery." ) )

  -- Message text

  if duration then

    -- Auto resume.
    self:__RecoveryUnpause( duration )

    -- Time to resume.
    local clock = UTILS.SecondsToClock( timer.getAbsTime() + duration )

    -- Marshal call: "99, aircraft recovery paused and will be resume at XX:YY."
    self:_MarshalCallRecoveryPausedResumedAt( clock )
  else

    local text = string.format( "aircraft recovery is paused until further notice." )

    -- Marshal call: "99, aircraft recovery paused until further notice."
    self:_MarshalCallRecoveryPausedNotice()

  end

end

--- On after "RecoveryUnpause" event. Recovery of aircraft is resumed.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterRecoveryUnpause( From, Event, To )
  -- Debug output.
  self:T( self.lid .. string.format( "Unpausing aircraft recovery." ) )

  -- Resume recovery.
  self:_MarshalCallResumeRecovery()

end

--- On after "PassingWaypoint" event. Carrier has just passed a waypoint
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Number of waypoint that was passed.
function AIRBOSS:onafterPassingWaypoint( From, Event, To, n )
  -- Debug output.
  self:I( self.lid .. string.format( "Carrier passed waypoint %d.", n ) )
end

--- On after "Idle" event. Carrier goes to state "Idle".
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterIdle( From, Event, To )
  -- Debug output.
  self:T( self.lid .. string.format( "Carrier goes to idle." ) )
end

--- On after Stop event. Unhandle events.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRBOSS:onafterStop( From, Event, To )
  self:I( self.lid .. string.format( "Stopping airboss script." ) )

  -- Unhandle events.
  self:UnHandleEvent( EVENTS.Birth )
  self:UnHandleEvent( EVENTS.Land )
  self:UnHandleEvent( EVENTS.EngineShutdown )
  self:UnHandleEvent( EVENTS.Takeoff )
  self:UnHandleEvent( EVENTS.Crash )
  self:UnHandleEvent( EVENTS.Ejection )
  self:UnHandleEvent( EVENTS.PlayerLeaveUnit )
  self:UnHandleEvent( EVENTS.MissionEnd )

  self.CallScheduler:Clear()
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parameter initialization
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Init parameters for USS Stennis carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -153
  self.carrierparam.deckheight = 18.30

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 310 -- Wiki says 332.8 meters overall length.
  self.carrierparam.totwidthport = 40 -- Wiki says  76.8 meters overall beam.
  self.carrierparam.totwidthstarboard = 30

  -- Landing runway.
  self.carrierparam.rwyangle = -9.1359
  self.carrierparam.rwylength = 225
  self.carrierparam.rwywidth = 20

  -- Wires.
  self.carrierparam.wire1 = 46 -- Distance from stern to first wire.
  self.carrierparam.wire2 = 46 + 12
  self.carrierparam.wire3 = 46 + 24
  self.carrierparam.wire4 = 46 + 35 -- Last wire is strangely one meter closer.

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.wire3

  -- Platform at 5k. Reduce descent rate to 2000 ft/min to 1200 dirty up level flight.
  self.Platform.name = "Platform 5k"
  self.Platform.Xmin = -UTILS.NMToMeters( 22 ) -- Not more than 22 NM behind the boat. Last check was at 21 NM.
  self.Platform.Xmax = nil
  self.Platform.Zmin = -UTILS.NMToMeters( 30 ) -- Not more than 30 NM port of boat.
  self.Platform.Zmax = UTILS.NMToMeters( 30 ) -- Not more than 30 NM starboard of boat.
  self.Platform.LimitXmin = nil -- Limits via zone
  self.Platform.LimitXmax = nil
  self.Platform.LimitZmin = nil
  self.Platform.LimitZmax = nil

  -- Level out at 1200 ft and dirty up.
  self.DirtyUp.name = "Dirty Up"
  self.DirtyUp.Xmin = -UTILS.NMToMeters( 21 ) -- Not more than 21 NM behind the boat.
  self.DirtyUp.Xmax = nil
  self.DirtyUp.Zmin = -UTILS.NMToMeters( 30 ) -- Not more than 30 NM port of boat.
  self.DirtyUp.Zmax = UTILS.NMToMeters( 30 ) -- Not more than 30 NM starboard of boat.
  self.DirtyUp.LimitXmin = nil -- Limits via zone
  self.DirtyUp.LimitXmax = nil
  self.DirtyUp.LimitZmin = nil
  self.DirtyUp.LimitZmax = nil

  -- Intercept glide slope and follow bullseye.
  self.Bullseye.name = "Bullseye"
  self.Bullseye.Xmin = -UTILS.NMToMeters( 11 ) -- Not more than 11 NM behind the boat. Last check was at 10 NM.
  self.Bullseye.Xmax = nil
  self.Bullseye.Zmin = -UTILS.NMToMeters( 30 ) -- Not more than 30 NM port.
  self.Bullseye.Zmax = UTILS.NMToMeters( 30 ) -- Not more than 30 NM starboard.
  self.Bullseye.LimitXmin = nil -- Limits via zone.
  self.Bullseye.LimitXmax = nil
  self.Bullseye.LimitZmin = nil
  self.Bullseye.LimitZmax = nil

  -- Break entry.
  self.BreakEntry.name = "Break Entry"
  self.BreakEntry.Xmin = -UTILS.NMToMeters( 4 ) -- Not more than 4 NM behind the boat. Check for initial is at 3 NM with a radius of 500 m and 100 m starboard.
  self.BreakEntry.Xmax = nil
  self.BreakEntry.Zmin = -UTILS.NMToMeters( 0.5 ) -- Not more than 0.5 NM port of boat.
  self.BreakEntry.Zmax = UTILS.NMToMeters( 1.5 ) -- Not more than 1.5 NM starboard.
  self.BreakEntry.LimitXmin = 0 -- Check and next step when at carrier and starboard of carrier.
  self.BreakEntry.LimitXmax = nil
  self.BreakEntry.LimitZmin = nil
  self.BreakEntry.LimitZmax = nil

  -- Early break.
  self.BreakEarly.name = "Early Break"
  self.BreakEarly.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakEarly.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakEarly.Zmin = -UTILS.NMToMeters( 2 ) -- Not more than 2 NM port.
  self.BreakEarly.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakEarly.LimitXmin = 0 -- Check and next step 0.2 NM port and in front of boat.
  self.BreakEarly.LimitXmax = nil
  self.BreakEarly.LimitZmin = -UTILS.NMToMeters( 0.2 ) -- -370 m port
  self.BreakEarly.LimitZmax = nil

  -- Late break.
  self.BreakLate.name = "Late Break"
  self.BreakLate.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin = -UTILS.NMToMeters( 2 ) -- Not more than 2 NM port.
  self.BreakLate.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin = 0 -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax = nil
  self.BreakLate.LimitZmin = -UTILS.NMToMeters( 0.8 ) -- -1470 m port
  self.BreakLate.LimitZmax = nil

  -- Abeam position.
  self.Abeam.name = "Abeam Position"
  self.Abeam.Xmin = -UTILS.NMToMeters( 5 ) -- Not more then 5 NM astern of boat. Should be LIG call anyway.
  self.Abeam.Xmax = UTILS.NMToMeters( 5 ) -- Not more then 5 NM ahead of boat.
  self.Abeam.Zmin = -UTILS.NMToMeters( 2 ) -- Not more than 2 NM port.
  self.Abeam.Zmax = 500 -- Not more than 500 m starboard. Must be port!
  self.Abeam.LimitXmin = -200 -- Check and next step 200 meters behind the ship.
  self.Abeam.LimitXmax = nil
  self.Abeam.LimitZmin = nil
  self.Abeam.LimitZmax = nil

  -- At the Ninety.
  self.Ninety.name = "Ninety"
  self.Ninety.Xmin = -UTILS.NMToMeters( 4 ) -- Not more than 4 NM behind the boat. LIG check anyway.
  self.Ninety.Xmax = 0 -- Must be behind the boat.
  self.Ninety.Zmin = -UTILS.NMToMeters( 2 ) -- Not more than 2 NM port of boat.
  self.Ninety.Zmax = nil
  self.Ninety.LimitXmin = nil
  self.Ninety.LimitXmax = nil
  self.Ninety.LimitZmin = nil
  self.Ninety.LimitZmax = -UTILS.NMToMeters( 0.6 ) -- Check and next step when 0.6 NM port.

  -- At the Wake.
  self.Wake.name = "Wake"
  self.Wake.Xmin = -UTILS.NMToMeters( 4 ) -- Not more than 4 NM behind the boat.
  self.Wake.Xmax = 0 -- Must be behind the boat.
  self.Wake.Zmin = -2000 -- Not more than 2 km port of boat.
  self.Wake.Zmax = nil
  self.Wake.LimitXmin = nil
  self.Wake.LimitXmax = nil
  self.Wake.LimitZmin = 0 -- Check and next step when directly behind the boat.
  self.Wake.LimitZmax = nil

  -- Turn to final.
  self.Final.name = "Final"
  self.Final.Xmin = -UTILS.NMToMeters( 4 ) -- Not more than 4 NM behind the boat.
  self.Final.Xmax = 0 -- Must be behind the boat.
  self.Final.Zmin = -2000 -- Not more than 2 km port.
  self.Final.Zmax = nil
  self.Final.LimitXmin = nil -- No limits. Check is carried out differently.
  self.Final.LimitXmax = nil
  self.Final.LimitZmin = nil
  self.Final.LimitZmax = nil

  -- In the Groove.
  self.Groove.name = "Groove"
  self.Groove.Xmin = -UTILS.NMToMeters( 4 ) -- Not more than 4 NM behind the boat.
  self.Groove.Xmax = nil
  self.Groove.Zmin = -UTILS.NMToMeters( 2 ) -- Not more than 2 NM port
  self.Groove.Zmax = UTILS.NMToMeters( 2 ) -- Not more than 2 NM starboard.
  self.Groove.LimitXmin = nil -- No limits. Check is carried out differently.
  self.Groove.LimitXmax = nil
  self.Groove.LimitZmin = nil
  self.Groove.LimitZmax = nil

end

--- Init parameters for Nimitz class super carriers.
-- @param #AIRBOSS self
function AIRBOSS:_InitNimitz()

  -- Init Stennis as default.
  self:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -164
  self.carrierparam.deckheight = 20.1494 -- DCS World OpenBeta\CoreMods\tech\USS_Nimitz\Database\USS_CVN_7X.lua

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 332.8 -- Wiki says 332.8 meters overall length.
  self.carrierparam.totwidthport = 45 -- Wiki says  76.8 meters overall beam.
  self.carrierparam.totwidthstarboard = 35

  -- Landing runway.
  self.carrierparam.rwyangle = -9.1359 -- DCS World OpenBeta\CoreMods\tech\USS_Nimitz\scripts\USS_Nimitz_RunwaysAndRoutes.lua
  self.carrierparam.rwylength = 250
  self.carrierparam.rwywidth = 25

  -- Wires.
  self.carrierparam.wire1 = 55 -- Distance from stern to first wire.
  self.carrierparam.wire2 = 67
  self.carrierparam.wire3 = 79
  self.carrierparam.wire4 = 92

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.wire3

end

--- Init parameters for Forrestal class super carriers.
-- @param #AIRBOSS self
function AIRBOSS:_InitForrestal()

  -- Init Nimitz as default.
  self:_InitNimitz()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -135.5
  self.carrierparam.deckheight = 20 -- 20.1494  --DCS World OpenBeta\CoreMods\tech\USS_Nimitz\Database\USS_CVN_7X.lua

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 315 -- Wiki says 325 meters overall length.
  self.carrierparam.totwidthport = 45 -- Wiki says  73 meters overall beam.
  self.carrierparam.totwidthstarboard = 35

  -- Landing runway.
  self.carrierparam.rwyangle = -9.1359 -- DCS World OpenBeta\CoreMods\tech\USS_Nimitz\scripts\USS_Nimitz_RunwaysAndRoutes.lua
  self.carrierparam.rwylength = 212
  self.carrierparam.rwywidth = 25

  -- Wires.
  self.carrierparam.wire1 = 44 -- Distance from stern to first wire. Original from Frank - 42
  self.carrierparam.wire2 = 54 -- 51.5
  self.carrierparam.wire3 = 64 -- 62
  self.carrierparam.wire4 = 74 -- 72.5

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.wire3

end

--- Init parameters for R12 HMS Hermes carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitHermes()

  -- Init Stennis as default.
  self:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -105
  self.carrierparam.deckheight = 12 -- From model viewer WL0.

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 228.19
  self.carrierparam.totwidthport = 20.5
  self.carrierparam.totwidthstarboard = 24.5

  -- Landing runway.
  self.carrierparam.rwyangle = 0
  self.carrierparam.rwylength = 215
  self.carrierparam.rwywidth = 13

  -- Wires.
  self.carrierparam.wire1 = nil
  self.carrierparam.wire2 = nil
  self.carrierparam.wire3 = nil
  self.carrierparam.wire4 = nil

  -- Distance to landing spot.
  self.carrierparam.landingspot=69

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.landingspot

  -- Late break.
  self.BreakLate.name = "Late Break"
  self.BreakLate.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin = -UTILS.NMToMeters( 1.6 ) -- Not more than 1.6 NM port.
  self.BreakLate.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin = 0 -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax = nil
  self.BreakLate.LimitZmin = -UTILS.NMToMeters( 0.5 ) -- 926 m port, closer than the stennis as abeam is 0.8-1.0 rather than 1.2
  self.BreakLate.LimitZmax = nil

end

--- Init parameters for R05 HMS Invincible carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitInvincible()

  -- Init Stennis as default.
  self:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -105
  self.carrierparam.deckheight = 12 -- From model viewer WL0.

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 228.19
  self.carrierparam.totwidthport = 20.5
  self.carrierparam.totwidthstarboard = 24.5

  -- Landing runway.
  self.carrierparam.rwyangle = 0
  self.carrierparam.rwylength = 215
  self.carrierparam.rwywidth = 13

  -- Wires.
  self.carrierparam.wire1 = nil
  self.carrierparam.wire2 = nil
  self.carrierparam.wire3 = nil
  self.carrierparam.wire4 = nil

  -- Distance to landing spot.
  self.carrierparam.landingspot=69

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.landingspot

  -- Late break.
  self.BreakLate.name = "Late Break"
  self.BreakLate.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin = -UTILS.NMToMeters( 1.6 ) -- Not more than 1.6 NM port.
  self.BreakLate.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin = 0 -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax = nil
  self.BreakLate.LimitZmin = -UTILS.NMToMeters( 0.5 ) -- 926 m port, closer than the stennis as abeam is 0.8-1.0 rather than 1.2
  self.BreakLate.LimitZmax = nil

end

--- Init parameters for LHA-1 Tarawa carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitTarawa()

  -- Init Stennis as default.
  self:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -125
  self.carrierparam.deckheight = 21 -- 69 ft

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 245
  self.carrierparam.totwidthport = 10
  self.carrierparam.totwidthstarboard = 25

  -- Landing runway.
  self.carrierparam.rwyangle = 0
  self.carrierparam.rwylength = 225
  self.carrierparam.rwywidth = 15

  -- Wires.
  self.carrierparam.wire1 = nil
  self.carrierparam.wire2 = nil
  self.carrierparam.wire3 = nil
  self.carrierparam.wire4 = nil

  -- Distance to landing spot.
  self.carrierparam.landingspot=57

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.landingspot

  -- Late break.
  self.BreakLate.name = "Late Break"
  self.BreakLate.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin = -UTILS.NMToMeters( 1.6 ) -- Not more than 1.6 NM port.
  self.BreakLate.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin = 0 -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax = nil
  self.BreakLate.LimitZmin = -UTILS.NMToMeters( 0.5 ) -- 926 m port, closer than the stennis as abeam is 0.8-1.0 rather than 1.2
  self.BreakLate.LimitZmax = nil

end

--- Init parameters for LHA-6 America carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitAmerica()

  -- Init Stennis as default.
  self:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -125
  self.carrierparam.deckheight = 20 -- 67 ft

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 257
  self.carrierparam.totwidthport = 11
  self.carrierparam.totwidthstarboard = 25

  -- Landing runway.
  self.carrierparam.rwyangle = 0
  self.carrierparam.rwylength = 240
  self.carrierparam.rwywidth = 15

  -- Wires.
  self.carrierparam.wire1 = nil
  self.carrierparam.wire2 = nil
  self.carrierparam.wire3 = nil
  self.carrierparam.wire4 = nil

  -- Distance to landing spot.
  self.carrierparam.landingspot=59

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.landingspot

  -- Late break.
  self.BreakLate.name = "Late Break"
  self.BreakLate.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin = -UTILS.NMToMeters( 1.6 ) -- Not more than 1.6 NM port.
  self.BreakLate.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin = 0 -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax = nil
  self.BreakLate.LimitZmin = -UTILS.NMToMeters( 0.5 ) -- 926 m port, closer than the stennis as abeam is 0.8-1.0 rather than 1.2
  self.BreakLate.LimitZmax = nil

end

--- Init parameters for L61 Juan Carlos carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitJcarlos()

  -- Init Stennis as default.
  self:_InitStennis()

  -- Carrier Parameters.
  self.carrierparam.sterndist = -125
  self.carrierparam.deckheight = 20 -- 67 ft

  -- Total size of the carrier (approx as rectangle).
  self.carrierparam.totlength = 231
  self.carrierparam.totwidthport = 10
  self.carrierparam.totwidthstarboard = 22

  -- Landing runway.
  self.carrierparam.rwyangle = 0
  self.carrierparam.rwylength = 202
  self.carrierparam.rwywidth = 14

  -- Wires.
  self.carrierparam.wire1 = nil
  self.carrierparam.wire2 = nil
  self.carrierparam.wire3 = nil
  self.carrierparam.wire4 = nil

  -- Distance to landing spot.
  self.carrierparam.landingspot=89

  -- Landing distance.
  self.carrierparam.landingdist = self.carrierparam.sterndist+self.carrierparam.landingspot

  -- Late break.
  self.BreakLate.name = "Late Break"
  self.BreakLate.Xmin = -UTILS.NMToMeters( 1 ) -- Not more than 1 NM behind the boat. Last check was at 0.
  self.BreakLate.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat. Enough for late breaks?
  self.BreakLate.Zmin = -UTILS.NMToMeters( 1.6 ) -- Not more than 1.6 NM port.
  self.BreakLate.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  self.BreakLate.LimitXmin = 0 -- Check and next step 0.8 NM port and in front of boat.
  self.BreakLate.LimitXmax = nil
  self.BreakLate.LimitZmin = -UTILS.NMToMeters( 0.5 ) -- 926 m port, closer than the stennis as abeam is 0.8-1.0 rather than 1.2
  self.BreakLate.LimitZmax = nil

end

--- Init parameters for L02 Canberra carrier.
-- @param #AIRBOSS self
function AIRBOSS:_InitCanberra()

    -- Init Juan Carlos as default.
    self:_InitJcarlos()

end

--- Init parameters for Marshal Voice overs *Gabriella* by HighwaymanEd.
-- @param #AIRBOSS self
-- @param #string mizfolder (Optional) Folder within miz file where the sound files are located.
function AIRBOSS:SetVoiceOversMarshalByGabriella( mizfolder )

  -- Set sound files folder.
  if mizfolder then
    local lastchar = string.sub( mizfolder, -1 )
    if lastchar ~= "/" then
      mizfolder = mizfolder .. "/"
    end
    self.soundfolderMSH = mizfolder
  else
    -- Default is the general folder.
    self.soundfolderMSH = self.soundfolder
  end

  -- Report for duty.
  self:I( self.lid .. string.format( "Marshal Gabriella reporting for duty! Soundfolder=%s", tostring( self.soundfolderMSH ) ) )

  self.MarshalCall.AFFIRMATIVE.duration = 0.65
  self.MarshalCall.ALTIMETER.duration = 0.60
  self.MarshalCall.BRC.duration = 0.67
  self.MarshalCall.CARRIERTURNTOHEADING.duration = 1.62
  self.MarshalCall.CASE.duration = 0.30
  self.MarshalCall.CHARLIETIME.duration = 0.77
  self.MarshalCall.CLEAREDFORRECOVERY.duration = 0.93
  self.MarshalCall.DECKCLOSED.duration = 0.73
  self.MarshalCall.DEGREES.duration = 0.48
  self.MarshalCall.EXPECTED.duration = 0.50
  self.MarshalCall.FLYNEEDLES.duration = 0.89
  self.MarshalCall.HOLDATANGELS.duration = 0.81
  self.MarshalCall.HOURS.duration = 0.41
  self.MarshalCall.MARSHALRADIAL.duration = 0.95
  self.MarshalCall.N0.duration = 0.41
  self.MarshalCall.N1.duration = 0.30
  self.MarshalCall.N2.duration = 0.34
  self.MarshalCall.N3.duration = 0.31
  self.MarshalCall.N4.duration = 0.34
  self.MarshalCall.N5.duration = 0.30
  self.MarshalCall.N6.duration = 0.33
  self.MarshalCall.N7.duration = 0.38
  self.MarshalCall.N8.duration = 0.35
  self.MarshalCall.N9.duration = 0.35
  self.MarshalCall.NEGATIVE.duration = 0.60
  self.MarshalCall.NEWFB.duration = 0.95
  self.MarshalCall.OPS.duration = 0.23
  self.MarshalCall.POINT.duration = 0.38
  self.MarshalCall.RADIOCHECK.duration = 1.27
  self.MarshalCall.RECOVERY.duration = 0.60
  self.MarshalCall.RECOVERYOPSSTOPPED.duration = 1.25
  self.MarshalCall.RECOVERYPAUSEDNOTICE.duration = 2.55
  self.MarshalCall.RECOVERYPAUSEDRESUMED.duration = 2.55
  self.MarshalCall.REPORTSEEME.duration = 0.87
  self.MarshalCall.RESUMERECOVERY.duration = 1.55
  self.MarshalCall.ROGER.duration = 0.50
  self.MarshalCall.SAYNEEDLES.duration = 0.82
  self.MarshalCall.STACKFULL.duration = 5.70
  self.MarshalCall.STARTINGRECOVERY.duration = 1.61

end

--- Init parameters for Marshal Voice overs by *Raynor*.
-- @param #AIRBOSS self
-- @param #string mizfolder (Optional) Folder within miz file where the sound files are located.
function AIRBOSS:SetVoiceOversMarshalByRaynor( mizfolder )

  -- Set sound files folder.
  if mizfolder then
    local lastchar = string.sub( mizfolder, -1 )
    if lastchar ~= "/" then
      mizfolder = mizfolder .. "/"
    end
    self.soundfolderMSH = mizfolder
  else
    -- Default is the general folder.
    self.soundfolderMSH = self.soundfolder
  end

  -- Report for duty.
  self:I( self.lid .. string.format( "Marshal Raynor reporting for duty! Soundfolder=%s", tostring( self.soundfolderMSH ) ) )

  self.MarshalCall.AFFIRMATIVE.duration = 0.70
  self.MarshalCall.ALTIMETER.duration = 0.60
  self.MarshalCall.BRC.duration = 0.60
  self.MarshalCall.CARRIERTURNTOHEADING.duration = 1.87
  self.MarshalCall.CASE.duration = 0.60
  self.MarshalCall.CHARLIETIME.duration = 0.81
  self.MarshalCall.CLEAREDFORRECOVERY.duration = 1.21
  self.MarshalCall.DECKCLOSED.duration = 0.86
  self.MarshalCall.DEGREES.duration = 0.55
  self.MarshalCall.EXPECTED.duration = 0.61
  self.MarshalCall.FLYNEEDLES.duration = 0.90
  self.MarshalCall.HOLDATANGELS.duration = 0.91
  self.MarshalCall.HOURS.duration = 0.54
  self.MarshalCall.MARSHALRADIAL.duration = 0.80
  self.MarshalCall.N0.duration = 0.38
  self.MarshalCall.N1.duration = 0.30
  self.MarshalCall.N2.duration = 0.30
  self.MarshalCall.N3.duration = 0.30
  self.MarshalCall.N4.duration = 0.32
  self.MarshalCall.N5.duration = 0.41
  self.MarshalCall.N6.duration = 0.48
  self.MarshalCall.N7.duration = 0.51
  self.MarshalCall.N8.duration = 0.38
  self.MarshalCall.N9.duration = 0.34
  self.MarshalCall.NEGATIVE.duration = 0.60
  self.MarshalCall.NEWFB.duration = 1.10
  self.MarshalCall.OPS.duration = 0.46
  self.MarshalCall.POINT.duration = 0.21
  self.MarshalCall.RADIOCHECK.duration = 0.95
  self.MarshalCall.RECOVERY.duration = 0.63
  self.MarshalCall.RECOVERYOPSSTOPPED.duration = 1.36
  self.MarshalCall.RECOVERYPAUSEDNOTICE.duration = 2.8 -- Strangely the file is actually a shorter ~2.4 sec.
  self.MarshalCall.RECOVERYPAUSEDRESUMED.duration = 2.75
  self.MarshalCall.REPORTSEEME.duration = 1.06 -- 0.96
  self.MarshalCall.RESUMERECOVERY.duration = 1.41
  self.MarshalCall.ROGER.duration = 0.41
  self.MarshalCall.SAYNEEDLES.duration = 0.79
  self.MarshalCall.STACKFULL.duration = 4.70
  self.MarshalCall.STARTINGRECOVERY.duration = 2.06

end

--- Set parameters for LSO Voice overs by *Raynor*.
-- @param #AIRBOSS self
-- @param #string mizfolder (Optional) Folder within miz file where the sound files are located.
function AIRBOSS:SetVoiceOversLSOByRaynor( mizfolder )

  -- Set sound files folder.
  if mizfolder then
    local lastchar = string.sub( mizfolder, -1 )
    if lastchar ~= "/" then
      mizfolder = mizfolder .. "/"
    end
    self.soundfolderLSO = mizfolder
  else
    -- Default is the general folder.
    self.soundfolderLSO = self.soundfolder
  end

  -- Report for duty.
  self:I( self.lid .. string.format( "LSO Raynor reporting for duty! Soundfolder=%s", tostring( self.soundfolderLSO ) ) )

  self.LSOCall.BOLTER.duration = 0.75
  self.LSOCall.CALLTHEBALL.duration = 0.625
  self.LSOCall.CHECK.duration = 0.40
  self.LSOCall.CLEAREDTOLAND.duration = 0.85
  self.LSOCall.COMELEFT.duration = 0.60
  self.LSOCall.DEPARTANDREENTER.duration = 1.10
  self.LSOCall.EXPECTHEAVYWAVEOFF.duration = 1.30
  self.LSOCall.EXPECTSPOT75.duration = 1.85
  self.LSOCall.EXPECTSPOT5.duration = 1.3
  self.LSOCall.FAST.duration = 0.75
  self.LSOCall.FOULDECK.duration = 0.75
  self.LSOCall.HIGH.duration = 0.65
  self.LSOCall.IDLE.duration = 0.40
  self.LSOCall.LONGINGROOVE.duration = 1.25
  self.LSOCall.LOW.duration = 0.60
  self.LSOCall.N0.duration = 0.38
  self.LSOCall.N1.duration = 0.30
  self.LSOCall.N2.duration = 0.30
  self.LSOCall.N3.duration = 0.30
  self.LSOCall.N4.duration = 0.32
  self.LSOCall.N5.duration = 0.41
  self.LSOCall.N6.duration = 0.48
  self.LSOCall.N7.duration = 0.51
  self.LSOCall.N8.duration = 0.38
  self.LSOCall.N9.duration = 0.34
  self.LSOCall.PADDLESCONTACT.duration = 0.91
  self.LSOCall.POWER.duration = 0.45
  self.LSOCall.RADIOCHECK.duration = 0.90
  self.LSOCall.RIGHTFORLINEUP.duration = 0.70
  self.LSOCall.ROGERBALL.duration = 0.72
  self.LSOCall.SLOW.duration = 0.63
  -- self.LSOCall.SLOW.duration=0.59  --TODO
  self.LSOCall.STABILIZED.duration = 0.75
  self.LSOCall.WAVEOFF.duration = 0.55
  self.LSOCall.WELCOMEABOARD.duration = 0.80
end

--- Set parameters for LSO Voice overs by *funkyfranky*.
-- @param #AIRBOSS self
-- @param #string mizfolder (Optional) Folder within miz file where the sound files are located.
function AIRBOSS:SetVoiceOversLSOByFF( mizfolder )

  -- Set sound files folder.
  if mizfolder then
    local lastchar = string.sub( mizfolder, -1 )
    if lastchar ~= "/" then
      mizfolder = mizfolder .. "/"
    end
    self.soundfolderLSO = mizfolder
  else
    -- Default is the general folder.
    self.soundfolderLSO = self.soundfolder
  end

  -- Report for duty.
  self:I( self.lid .. string.format( "LSO FF reporting for duty! Soundfolder=%s", tostring( self.soundfolderLSO ) ) )

  self.LSOCall.BOLTER.duration = 0.75
  self.LSOCall.CALLTHEBALL.duration = 0.60
  self.LSOCall.CHECK.duration = 0.45
  self.LSOCall.CLEAREDTOLAND.duration = 1.00
  self.LSOCall.COMELEFT.duration = 0.60
  self.LSOCall.DEPARTANDREENTER.duration = 1.10
  self.LSOCall.EXPECTHEAVYWAVEOFF.duration = 1.20
  self.LSOCall.EXPECTSPOT75.duration = 2.00
  self.LSOCall.EXPECTSPOT5.duration = 1.3
  self.LSOCall.FAST.duration = 0.70
  self.LSOCall.FOULDECK.duration = 0.62
  self.LSOCall.HIGH.duration = 0.65
  self.LSOCall.IDLE.duration = 0.45
  self.LSOCall.LONGINGROOVE.duration = 1.20
  self.LSOCall.LOW.duration = 0.50
  self.LSOCall.N0.duration = 0.40
  self.LSOCall.N1.duration = 0.25
  self.LSOCall.N2.duration = 0.37
  self.LSOCall.N3.duration = 0.37
  self.LSOCall.N4.duration = 0.39
  self.LSOCall.N5.duration = 0.39
  self.LSOCall.N6.duration = 0.40
  self.LSOCall.N7.duration = 0.40
  self.LSOCall.N8.duration = 0.37
  self.LSOCall.N9.duration = 0.40
  self.LSOCall.PADDLESCONTACT.duration = 1.00
  self.LSOCall.POWER.duration = 0.50
  self.LSOCall.RADIOCHECK.duration = 1.10
  self.LSOCall.RIGHTFORLINEUP.duration = 0.80
  self.LSOCall.ROGERBALL.duration = 1.00
  self.LSOCall.SLOW.duration = 0.65
  self.LSOCall.SLOW.duration = 0.59
  self.LSOCall.STABILIZED.duration = 0.90
  self.LSOCall.WAVEOFF.duration = 0.60
  self.LSOCall.WELCOMEABOARD.duration = 1.00
end

--- Intit parameters for Marshal Voice overs by *funkyfranky*.
-- @param #AIRBOSS self
-- @param #string mizfolder (Optional) Folder within miz file where the sound files are located.
function AIRBOSS:SetVoiceOversMarshalByFF( mizfolder )

  -- Set sound files folder.
  if mizfolder then
    local lastchar = string.sub( mizfolder, -1 )
    if lastchar ~= "/" then
      mizfolder = mizfolder .. "/"
    end
    self.soundfolderMSH = mizfolder
  else
    -- Default is the general folder.
    self.soundfolderMSH = self.soundfolder
  end

  -- Report for duty.
  self:I( self.lid .. string.format( "Marshal FF reporting for duty! Soundfolder=%s", tostring( self.soundfolderMSH ) ) )

  self.MarshalCall.AFFIRMATIVE.duration = 0.90
  self.MarshalCall.ALTIMETER.duration = 0.85
  self.MarshalCall.BRC.duration = 0.80
  self.MarshalCall.CARRIERTURNTOHEADING.duration = 2.48
  self.MarshalCall.CASE.duration = 0.40
  self.MarshalCall.CHARLIETIME.duration = 0.90
  self.MarshalCall.CLEAREDFORRECOVERY.duration = 1.25
  self.MarshalCall.DECKCLOSED.duration = 1.10
  self.MarshalCall.DEGREES.duration = 0.60
  self.MarshalCall.EXPECTED.duration = 0.55
  self.MarshalCall.FLYNEEDLES.duration = 0.90
  self.MarshalCall.HOLDATANGELS.duration = 1.10
  self.MarshalCall.HOURS.duration = 0.60
  self.MarshalCall.MARSHALRADIAL.duration = 1.10
  self.MarshalCall.N0.duration = 0.40
  self.MarshalCall.N1.duration = 0.25
  self.MarshalCall.N2.duration = 0.37
  self.MarshalCall.N3.duration = 0.37
  self.MarshalCall.N4.duration = 0.39
  self.MarshalCall.N5.duration = 0.39
  self.MarshalCall.N6.duration = 0.40
  self.MarshalCall.N7.duration = 0.40
  self.MarshalCall.N8.duration = 0.37
  self.MarshalCall.N9.duration = 0.40
  self.MarshalCall.NEGATIVE.duration = 0.80
  self.MarshalCall.NEWFB.duration = 1.35
  self.MarshalCall.OPS.duration = 0.48
  self.MarshalCall.POINT.duration = 0.33
  self.MarshalCall.RADIOCHECK.duration = 1.20
  self.MarshalCall.RECOVERY.duration = 0.70
  self.MarshalCall.RECOVERYOPSSTOPPED.duration = 1.65
  self.MarshalCall.RECOVERYPAUSEDNOTICE.duration = 2.9 -- Strangely the file is actually a shorter ~2.4 sec.
  self.MarshalCall.RECOVERYPAUSEDRESUMED.duration = 3.40
  self.MarshalCall.REPORTSEEME.duration = 0.95
  self.MarshalCall.RESUMERECOVERY.duration = 1.75
  self.MarshalCall.ROGER.duration = 0.53
  self.MarshalCall.SAYNEEDLES.duration = 0.90
  self.MarshalCall.STACKFULL.duration = 6.35
  self.MarshalCall.STARTINGRECOVERY.duration = 2.65

end

--- Init voice over radio transmission call.
-- @param #AIRBOSS self
function AIRBOSS:_InitVoiceOvers()

  ---------------
  -- LSO Radio --
  ---------------

  -- LSO Radio Calls.
  self.LSOCall = {
    BOLTER = { file = "LSO-BolterBolter", suffix = "ogg", loud = false, subtitle = "Bolter, Bolter", duration = 0.75, subduration = 5 },
    CALLTHEBALL = { file = "LSO-CallTheBall", suffix = "ogg", loud = false, subtitle = "Call the ball", duration = 0.6, subduration = 2 },
    CHECK = { file = "LSO-Check", suffix = "ogg", loud = false, subtitle = "Check", duration = 0.45, subduration = 2.5 },
    CLEAREDTOLAND = { file = "LSO-ClearedToLand", suffix = "ogg", loud = false, subtitle = "Cleared to land", duration = 1.0, subduration = 5 },
    COMELEFT = { file = "LSO-ComeLeft", suffix = "ogg", loud = true, subtitle = "Come left", duration = 0.60, subduration = 1 },
    RADIOCHECK = { file = "LSO-RadioCheck", suffix = "ogg", loud = false, subtitle = "Paddles, radio check", duration = 1.1, subduration = 5 },
    RIGHTFORLINEUP = { file = "LSO-RightForLineup", suffix = "ogg", loud = true, subtitle = "Right for line up", duration = 0.80, subduration = 1 },
    HIGH = { file = "LSO-High", suffix = "ogg", loud = true, subtitle = "You're high", duration = 0.65, subduration = 1 },
    LOW = { file = "LSO-Low", suffix = "ogg", loud = true, subtitle = "You're low", duration = 0.50, subduration = 1 },
    POWER = { file = "LSO-Power", suffix = "ogg", loud = true, subtitle = "Power", duration = 0.50, subduration = 1 }, -- duration 0.45 was too short
    SLOW = { file = "LSO-Slow", suffix = "ogg", loud = true, subtitle = "You're slow", duration = 0.65, subduration = 1 },
    FAST = { file = "LSO-Fast", suffix = "ogg", loud = true, subtitle = "You're fast", duration = 0.70, subduration = 1 },
    ROGERBALL = { file = "LSO-RogerBall", suffix = "ogg", loud = false, subtitle = "Roger ball", duration = 1.00, subduration = 2 },
    WAVEOFF = { file = "LSO-WaveOff", suffix = "ogg", loud = false, subtitle = "Wave off", duration = 0.6, subduration = 5 },
    LONGINGROOVE = { file = "LSO-LongInTheGroove", suffix = "ogg", loud = false, subtitle = "You're long in the groove", duration = 1.2, subduration = 5 },
    FOULDECK = { file = "LSO-FoulDeck", suffix = "ogg", loud = false, subtitle = "Foul deck", duration = 0.62, subduration = 5 },
    DEPARTANDREENTER = { file = "LSO-DepartAndReenter", suffix = "ogg", loud = false, subtitle = "Depart and re-enter", duration = 1.1, subduration = 5 },
    PADDLESCONTACT = { file = "LSO-PaddlesContact", suffix = "ogg", loud = false, subtitle = "Paddles, contact", duration = 1.0, subduration = 5 },
    WELCOMEABOARD = { file = "LSO-WelcomeAboard", suffix = "ogg", loud = false, subtitle = "Welcome aboard", duration = 1.0, subduration = 5 },
    EXPECTHEAVYWAVEOFF = { file = "LSO-ExpectHeavyWaveoff", suffix = "ogg", loud = false, subtitle = "Expect heavy waveoff", duration = 1.2, subduration = 5 },
    EXPECTSPOT75 = { file = "LSO-ExpectSpot75", suffix = "ogg", loud = false, subtitle = "Expect spot 7.5", duration = 2.0, subduration = 5 },
    EXPECTSPOT5 = { file = "LSO-ExpectSpot5", suffix = "ogg", loud = false, subtitle = "Expect spot 5", duration = 1.3, subduration = 5 },
    STABILIZED = { file = "LSO-Stabilized", suffix = "ogg", loud = false, subtitle = "Stabilized", duration = 0.9, subduration = 5 },
    IDLE = { file = "LSO-Idle", suffix = "ogg", loud = false, subtitle = "Idle", duration = 0.45, subduration = 5 },
    N0 = { file = "LSO-N0", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N1 = { file = "LSO-N1", suffix = "ogg", loud = false, subtitle = "", duration = 0.25 },
    N2 = { file = "LSO-N2", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N3 = { file = "LSO-N3", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N4 = { file = "LSO-N4", suffix = "ogg", loud = false, subtitle = "", duration = 0.39 },
    N5 = { file = "LSO-N5", suffix = "ogg", loud = false, subtitle = "", duration = 0.39 },
    N6 = { file = "LSO-N6", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N7 = { file = "LSO-N7", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N8 = { file = "LSO-N8", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N9 = { file = "LSO-N9", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    CLICK = { file = "AIRBOSS-RadioClick", suffix = "ogg", loud = false, subtitle = "", duration = 0.35 },
    NOISE = { file = "AIRBOSS-Noise", suffix = "ogg", loud = false, subtitle = "", duration = 3.6 },
    SPINIT = { file = "AIRBOSS-SpinIt", suffix = "ogg", loud = false, subtitle = "", duration = 0.73, subduration = 5 },
  }

  -----------------
  -- Pilot Calls --
  -----------------

  -- Pilot Radio Calls.
  self.PilotCall = {
    N0 = { file = "PILOT-N0", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N1 = { file = "PILOT-N1", suffix = "ogg", loud = false, subtitle = "", duration = 0.25 },
    N2 = { file = "PILOT-N2", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N3 = { file = "PILOT-N3", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N4 = { file = "PILOT-N4", suffix = "ogg", loud = false, subtitle = "", duration = 0.39 },
    N5 = { file = "PILOT-N5", suffix = "ogg", loud = false, subtitle = "", duration = 0.39 },
    N6 = { file = "PILOT-N6", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N7 = { file = "PILOT-N7", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N8 = { file = "PILOT-N8", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N9 = { file = "PILOT-N9", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    POINT = { file = "PILOT-Point", suffix = "ogg", loud = false, subtitle = "", duration = 0.33 },
    SKYHAWK = { file = "PILOT-Skyhawk", suffix = "ogg", loud = false, subtitle = "", duration = 0.95, subduration = 5 },
    HARRIER = { file = "PILOT-Harrier", suffix = "ogg", loud = false, subtitle = "", duration = 0.58, subduration = 5 },
    HAWKEYE = { file = "PILOT-Hawkeye", suffix = "ogg", loud = false, subtitle = "", duration = 0.63, subduration = 5 },
    TOMCAT = { file = "PILOT-Tomcat", suffix = "ogg", loud = false, subtitle = "", duration = 0.66, subduration = 5 },
    HORNET = { file = "PILOT-Hornet", suffix = "ogg", loud = false, subtitle = "", duration = 0.56, subduration = 5 },
    VIKING = { file = "PILOT-Viking", suffix = "ogg", loud = false, subtitle = "", duration = 0.61, subduration = 5 },
    BALL = { file = "PILOT-Ball", suffix = "ogg", loud = false, subtitle = "", duration = 0.50, subduration = 5 },
    BINGOFUEL = { file = "PILOT-BingoFuel", suffix = "ogg", loud = false, subtitle = "", duration = 0.80 },
    GASATDIVERT = { file = "PILOT-GasAtDivert", suffix = "ogg", loud = false, subtitle = "", duration = 1.80 },
    GASATTANKER = { file = "PILOT-GasAtTanker", suffix = "ogg", loud = false, subtitle = "", duration = 1.95 },
  }

  -------------------
  -- MARSHAL Radio --
  -------------------

  -- MARSHAL Radio Calls.
  self.MarshalCall = {
    AFFIRMATIVE = { file = "MARSHAL-Affirmative", suffix = "ogg", loud = false, subtitle = "", duration = 0.90 },
    ALTIMETER = { file = "MARSHAL-Altimeter", suffix = "ogg", loud = false, subtitle = "", duration = 0.85 },
    BRC = { file = "MARSHAL-BRC", suffix = "ogg", loud = false, subtitle = "", duration = 0.80 },
    CARRIERTURNTOHEADING = { file = "MARSHAL-CarrierTurnToHeading", suffix = "ogg", loud = false, subtitle = "", duration = 2.48, subduration = 5 },
    CASE = { file = "MARSHAL-Case", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    CHARLIETIME = { file = "MARSHAL-CharlieTime", suffix = "ogg", loud = false, subtitle = "", duration = 0.90 },
    CLEAREDFORRECOVERY = { file = "MARSHAL-ClearedForRecovery", suffix = "ogg", loud = false, subtitle = "", duration = 1.25 },
    DECKCLOSED = { file = "MARSHAL-DeckClosed", suffix = "ogg", loud = false, subtitle = "", duration = 1.10, subduration = 5 },
    DEGREES = { file = "MARSHAL-Degrees", suffix = "ogg", loud = false, subtitle = "", duration = 0.60 },
    EXPECTED = { file = "MARSHAL-Expected", suffix = "ogg", loud = false, subtitle = "", duration = 0.55 },
    FLYNEEDLES = { file = "MARSHAL-FlyYourNeedles", suffix = "ogg", loud = false, subtitle = "Fly your needles", duration = 0.9, subduration = 5 },
    HOLDATANGELS = { file = "MARSHAL-HoldAtAngels", suffix = "ogg", loud = false, subtitle = "", duration = 1.10 },
    HOURS = { file = "MARSHAL-Hours", suffix = "ogg", loud = false, subtitle = "", duration = 0.60, subduration = 5 },
    MARSHALRADIAL = { file = "MARSHAL-MarshalRadial", suffix = "ogg", loud = false, subtitle = "", duration = 1.10 },
    N0 = { file = "MARSHAL-N0", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N1 = { file = "MARSHAL-N1", suffix = "ogg", loud = false, subtitle = "", duration = 0.25 },
    N2 = { file = "MARSHAL-N2", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N3 = { file = "MARSHAL-N3", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N4 = { file = "MARSHAL-N4", suffix = "ogg", loud = false, subtitle = "", duration = 0.39 },
    N5 = { file = "MARSHAL-N5", suffix = "ogg", loud = false, subtitle = "", duration = 0.39 },
    N6 = { file = "MARSHAL-N6", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N7 = { file = "MARSHAL-N7", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    N8 = { file = "MARSHAL-N8", suffix = "ogg", loud = false, subtitle = "", duration = 0.37 },
    N9 = { file = "MARSHAL-N9", suffix = "ogg", loud = false, subtitle = "", duration = 0.40 },
    NEGATIVE = { file = "MARSHAL-Negative", suffix = "ogg", loud = false, subtitle = "", duration = 0.80, subduration = 5 },
    NEWFB = { file = "MARSHAL-NewFB", suffix = "ogg", loud = false, subtitle = "", duration = 1.35 },
    OPS = { file = "MARSHAL-Ops", suffix = "ogg", loud = false, subtitle = "", duration = 0.48 },
    POINT = { file = "MARSHAL-Point", suffix = "ogg", loud = false, subtitle = "", duration = 0.33 },
    RADIOCHECK = { file = "MARSHAL-RadioCheck", suffix = "ogg", loud = false, subtitle = "Radio check", duration = 1.20, subduration = 5 },
    RECOVERY = { file = "MARSHAL-Recovery", suffix = "ogg", loud = false, subtitle = "", duration = 0.70, subduration = 5 },
    RECOVERYOPSSTOPPED = { file = "MARSHAL-RecoveryOpsStopped", suffix = "ogg", loud = false, subtitle = "", duration = 1.65, subduration = 5 },
    RECOVERYPAUSEDNOTICE = { file = "MARSHAL-RecoveryPausedNotice", suffix = "ogg", loud = false, subtitle = "aircraft recovery paused until further notice", duration = 2.90, subduration = 5 },
    RECOVERYPAUSEDRESUMED = { file = "MARSHAL-RecoveryPausedResumed", suffix = "ogg", loud = false, subtitle = "", duration = 3.40, subduration = 5 },
    REPORTSEEME = { file = "MARSHAL-ReportSeeMe", suffix = "ogg", loud = false, subtitle = "", duration = 0.95 },
    RESUMERECOVERY = { file = "MARSHAL-ResumeRecovery", suffix = "ogg", loud = false, subtitle = "resuming aircraft recovery", duration = 1.75, subduraction = 5 },
    ROGER = { file = "MARSHAL-Roger", suffix = "ogg", loud = false, subtitle = "", duration = 0.53, subduration = 5 },
    SAYNEEDLES = { file = "MARSHAL-SayNeedles", suffix = "ogg", loud = false, subtitle = "Say needles", duration = 0.90, subduration = 5 },
    STACKFULL = { file = "MARSHAL-StackFull", suffix = "ogg", loud = false, subtitle = "Marshal Stack is currently full. Hold outside 10 NM zone and wait for further instructions", duration = 6.35, subduration = 10 },
    STARTINGRECOVERY = { file = "MARSHAL-StartingRecovery", suffix = "ogg", loud = false, subtitle = "", duration = 2.65, subduration = 5 },
    CLICK = { file = "AIRBOSS-RadioClick", suffix = "ogg", loud = false, subtitle = "", duration = 0.35 },
    NOISE = { file = "AIRBOSS-Noise", suffix = "ogg", loud = false, subtitle = "", duration = 3.6 },
  }

  -- Default timings by Raynor
  self:SetVoiceOversLSOByRaynor()
  self:SetVoiceOversMarshalByRaynor()

end

--- Init voice over radio transmission call.
-- @param #AIRBOSS self
-- @param #AIRBOSS.RadioCall radiocall LSO or Marshal radio call object.
-- @param #number duration Duration of the voice over in seconds.
-- @param #string subtitle (Optional) Subtitle to be displayed along with voice over.
-- @param #number subduration (Optional) Duration how long the subtitle is displayed.
-- @param #string filename (Optional) Name of the voice over sound file.
-- @param #string suffix (Optional) Extention of file. Default ".ogg".
function AIRBOSS:SetVoiceOver( radiocall, duration, subtitle, subduration, filename, suffix )
  radiocall.duration = duration
  radiocall.subtitle = subtitle or radiocall.subtitle
  radiocall.file = filename
  radiocall.suffix = suffix or ".ogg"
end

--- Get optimal aircraft AoA parameters..
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #AIRBOSS.AircraftAoA AoA parameters for the given aircraft type.
function AIRBOSS:_GetAircraftAoA( playerData )

  -- Get AC type.
  local hornet =   playerData.actype == AIRBOSS.AircraftCarrier.HORNET
                or playerData.actype == AIRBOSS.AircraftCarrier.RHINOE
                or playerData.actype == AIRBOSS.AircraftCarrier.RHINOF
                or playerData.actype == AIRBOSS.AircraftCarrier.GROWLER
  local goshawk = playerData.actype == AIRBOSS.AircraftCarrier.T45C
  local skyhawk = playerData.actype == AIRBOSS.AircraftCarrier.A4EC
  local harrier = playerData.actype == AIRBOSS.AircraftCarrier.AV8B
  local tomcat = playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B

  -- Table with AoA values.
  local aoa = {} -- #AIRBOSS.AircraftAoA

  if hornet then
    -- F/A-18C Hornet parameters.
    aoa.SLOW = 9.8
    aoa.Slow = 9.3
    aoa.OnSpeedMax = 8.8
    aoa.OnSpeed = 8.1
    aoa.OnSpeedMin = 7.4
    aoa.Fast = 6.9
    aoa.FAST = 6.3
  elseif tomcat then
    -- F-14A/B Tomcat parameters (taken from NATOPS). Converted from units 0-30 to degrees.
    -- Currently assuming a linear relationship with 0=-10 degrees and 30=+40 degrees as stated in NATOPS.
    aoa.SLOW = self:_AoAUnit2Deg( playerData, 17.0 ) -- 18.33 --17.0 units
    aoa.Slow = self:_AoAUnit2Deg( playerData, 16.0 ) -- 16.67 --16.0 units
    aoa.OnSpeedMax = self:_AoAUnit2Deg( playerData, 15.5 ) -- 15.83 --15.5 units
    aoa.OnSpeed = self:_AoAUnit2Deg( playerData, 15.0 ) -- 15.0  --15.0 units
    aoa.OnSpeedMin = self:_AoAUnit2Deg( playerData, 14.5 ) -- 14.17 --14.5 units
    aoa.Fast = self:_AoAUnit2Deg( playerData, 14.0 ) -- 13.33 --14.0 units
    aoa.FAST = self:_AoAUnit2Deg( playerData, 13.0 ) -- 11.67 --13.0 units
  elseif goshawk then
    -- T-45C Goshawk parameters.
    aoa.SLOW = 8.00 -- 19
    aoa.Slow = 7.75 -- 18
    aoa.OnSpeedMax = 7.25 -- 17.5
    aoa.OnSpeed = 7.00 -- 17
    aoa.OnSpeedMin = 6.75 -- 16.5
    aoa.Fast = 6.25 -- 16
    aoa.FAST = 6.00 -- 15
  elseif skyhawk then
    -- A-4E-C Skyhawk parameters from https://forums.eagle.ru/showpost.php?p=3703467&postcount=390
    -- Note that these are arbitrary UNITS and not degrees. We need a conversion formula!
    -- Github repo suggests they simply use a factor of two to get from degrees to units.
    aoa.SLOW = 9.50 -- =19.0/2
    aoa.Slow = 9.25 -- =18.5/2
    aoa.OnSpeedMax = 9.00 -- =18.0/2
    aoa.OnSpeed = 8.75 -- =17.5/2 8.1
    aoa.OnSpeedMin = 8.50 -- =17.0/2
    aoa.Fast = 8.25 -- =17.5/2
    aoa.FAST = 8.00 -- =16.5/2
  elseif harrier then

    -- AV-8B Harrier parameters. Tuning done on the Fast AoA to allow for abeam and ninety at Nozzles 55. Pene testing
    aoa.SLOW       = 16.0
    aoa.Slow       = 13.5
    aoa.OnSpeedMax = 12.5
    aoa.OnSpeed    = 10.0
    aoa.OnSpeedMin =  9.5
    aoa.Fast       =  8.0
    aoa.FAST       =  7.5

  end

  return aoa
end

--- Convert AoA from arbitrary units to degrees.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number aoaunits AoA in arbitrary units.
-- @return #number AoA in degrees.
function AIRBOSS:_AoAUnit2Deg( playerData, aoaunits )

  -- Init.
  local degrees = aoaunits

  -- Check aircraft type of player.
  if playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B then

    -------------
    -- F-14A/B --
    -------------

    -- NATOPS:
    -- unit=0  ==> alpha=-10 degrees.
    -- unit=30 ==> alpha=+40 degrees.

    -- Assuming a linear relationship between these to points of the graph.
    -- However: AoA=15 Units ==> 15 degrees, which is too much.
    degrees = -10 + 50 / 30 * aoaunits

    -- HB Facebook page https://www.facebook.com/heatblur/photos/a.683612385159716/754368278084126
    -- AoA=15 Units <==> AoA=10.359 degrees.
    degrees = 0.918 * aoaunits - 3.411

  elseif playerData.actype == AIRBOSS.AircraftCarrier.A4EC then

    ----------
    -- A-4E --
    ----------

    -- A-4E-C source code suggests a simple factor of 1/2 for conversion.
    degrees = 0.5 * aoaunits

  end

  return degrees
end

--- Convert AoA from degrees to arbitrary units.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number degrees AoA in degrees.
-- @return #number AoA in arbitrary units.
function AIRBOSS:_AoADeg2Units( playerData, degrees )

  -- Init.
  local aoaunits = degrees

  -- Check aircraft type of player.
  if playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B then

    -------------
    -- F-14A/B --
    -------------

    -- NATOPS:
    -- unit=0  ==> alpha=-10 degrees.
    -- unit=30 ==> alpha=+40 degrees.

    -- Assuming a linear relationship between these to points of the graph.
    aoaunits = (degrees + 10) * 30 / 50

    -- HB Facebook page https://www.facebook.com/heatblur/photos/a.683612385159716/754368278084126
    -- AoA=15 Units <==> AoA=10.359 degrees.
    aoaunits = 1.089 * degrees + 3.715

  elseif playerData.actype == AIRBOSS.AircraftCarrier.A4EC then

    ----------
    -- A-4E --
    ----------

    -- A-4E source code suggests a simple factor of two as conversion.
    aoaunits = 2 * degrees

  end

  return aoaunits
end

--- Get optimal aircraft flight parameters at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #string step Pattern step.
-- @return #number Altitude in meters or nil.
-- @return #number Angle of Attack or nil.
-- @return #number Distance to carrier in meters or nil.
-- @return #number Speed in m/s or nil.
function AIRBOSS:_GetAircraftParameters( playerData, step )

  -- Get parameters depended on step.
  step = step or playerData.step

  -- Get AC type.
  local hornet =    playerData.actype == AIRBOSS.AircraftCarrier.HORNET
                 or playerData.actype == AIRBOSS.AircraftCarrier.RHINOE
                 or playerData.actype == AIRBOSS.AircraftCarrier.RHINOF
                 or playerData.actype == AIRBOSS.AircraftCarrier.GROWLER
  local skyhawk = playerData.actype == AIRBOSS.AircraftCarrier.A4EC
  local tomcat = playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B
  local harrier = playerData.actype == AIRBOSS.AircraftCarrier.AV8B

  -- Return values.
  local alt
  local aoa
  local dist
  local speed

  -- Aircraft specific AoA.
  local aoaac = self:_GetAircraftAoA( playerData )

  if step == AIRBOSS.PatternStep.PLATFORM then

    alt = UTILS.FeetToMeters( 5000 )

    -- dist=UTILS.NMToMeters(20)

    speed = UTILS.KnotsToMps( 250 )

  elseif step == AIRBOSS.PatternStep.ARCIN then

    if tomcat then
      speed = UTILS.KnotsToMps( 150 )
    else
      speed = UTILS.KnotsToMps( 250 )
    end

  elseif step == AIRBOSS.PatternStep.ARCOUT then

    if tomcat then
      speed = UTILS.KnotsToMps( 150 )
    else
      speed = UTILS.KnotsToMps( 250 )
    end

  elseif step == AIRBOSS.PatternStep.DIRTYUP then

    alt = UTILS.FeetToMeters( 1200 )

    -- speed=UTILS.KnotsToMps(250)

  elseif step == AIRBOSS.PatternStep.BULLSEYE then

    alt = UTILS.FeetToMeters( 1200 )

    dist = -UTILS.NMToMeters( 3 )

    aoa = aoaac.OnSpeed

  elseif step == AIRBOSS.PatternStep.INITIAL then

    if hornet or tomcat or harrier then
      alt = UTILS.FeetToMeters( 800 )
      speed = UTILS.KnotsToMps( 350 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 600 )
      speed = UTILS.KnotsToMps( 250 )
    elseif goshawk then
      alt = UTILS.FeetToMeters( 800 )
      speed = UTILS.KnotsToMps( 300 )
    end

  elseif step == AIRBOSS.PatternStep.BREAKENTRY then

    if hornet or tomcat or harrier then
      alt = UTILS.FeetToMeters( 800 )
      speed = UTILS.KnotsToMps( 350 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 600 )
      speed = UTILS.KnotsToMps( 250 )
    elseif goshawk then
      alt = UTILS.FeetToMeters( 800 )
      speed = UTILS.KnotsToMps( 300 )
    end

  elseif step == AIRBOSS.PatternStep.EARLYBREAK then

    if hornet or tomcat or harrier or goshawk then
      alt = UTILS.FeetToMeters( 800 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 600 )
    end

  elseif step == AIRBOSS.PatternStep.LATEBREAK then

    if hornet or tomcat or harrier or goshawk then
      alt = UTILS.FeetToMeters( 800 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 600 )
    end

  elseif step == AIRBOSS.PatternStep.ABEAM then

    if hornet or tomcat or harrier or goshawk then
      alt = UTILS.FeetToMeters( 600 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 500 )
    end

    aoa = aoaac.OnSpeed

    if goshawk then
      -- 0.9 to 1.1 NM per natops ch.4 page 48
      dist = UTILS.NMToMeters( 0.9 )
    elseif harrier then
      -- 0.8 to 1.0 NM
      dist = UTILS.NMToMeters( 0.9 )
    else
      dist = UTILS.NMToMeters( 1.1 )
    end

  elseif step == AIRBOSS.PatternStep.NINETY then

    if hornet or tomcat then
      alt = UTILS.FeetToMeters( 500 )
    elseif goshawk then
      alt = UTILS.FeetToMeters( 450 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 500 )
    elseif harrier then
      alt = UTILS.FeetToMeters( 425 )
    end

    aoa = aoaac.OnSpeed

  elseif step == AIRBOSS.PatternStep.WAKE then

    if hornet or goshawk then
      alt = UTILS.FeetToMeters( 370 )
    elseif tomcat then
      alt = UTILS.FeetToMeters( 430 ) -- Tomcat should be a bit higher as it intercepts the GS a bit higher.
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 370 ) -- ?
    end
    -- Harrier wont get into wake pos. Runway is not angled and it stays port.

    aoa = aoaac.OnSpeed

  elseif step == AIRBOSS.PatternStep.FINAL then

    if hornet or goshawk then
      alt = UTILS.FeetToMeters( 300 )
    elseif tomcat then
      alt = UTILS.FeetToMeters( 360 )
    elseif skyhawk then
      alt = UTILS.FeetToMeters( 300 ) -- ?
    elseif harrier then
      alt=UTILS.FeetToMeters(312)-- 300-325 ft
    end

    aoa = aoaac.OnSpeed

  end

  return alt, aoa, dist, speed
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- QUEUE Functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get next marshal flight which is ready to enter the landing pattern.
-- @param #AIRBOSS self
-- @return #AIRBOSS.FlightGroup Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function AIRBOSS:_GetNextMarshalFight()

  -- Loop over all marshal flights.
  for _, _flight in pairs( self.Qmarshal ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Current stack.
    local stack = flight.flag

    -- Total marshal time in seconds.
    local Tmarshal = timer.getAbsTime() - flight.time

    -- Min time in marshal stack.
    local TmarshalMin = 2 * 60 -- Two minutes for human players.
    if flight.ai then
      TmarshalMin = 3 * 60 -- Three minutes for AI.
    end

    -- Check if conditions are right.
    if flight.holding ~= nil and Tmarshal >= TmarshalMin then
      if flight.case == 1 and stack == 1 or flight.case > 1 then
        if flight.ai then
          -- Return AI flight.
          return flight
        else
          -- Check for human player if they are already commencing.
          if flight.step ~= AIRBOSS.PatternStep.COMMENCING then
            return flight
          end
        end
      end
    end
  end

  return nil
end

--- Check marshal and pattern queues.
-- @param #AIRBOSS self
function AIRBOSS:_CheckQueue()

  -- Print queues.
  if self.Debug then
    self:_PrintQueue( self.flights, "All Flights" )
  end
  self:_PrintQueue( self.Qmarshal, "Marshal" )
  self:_PrintQueue( self.Qpattern, "Pattern" )
  self:_PrintQueue( self.Qwaiting, "Waiting" )
  self:_PrintQueue( self.Qspinning, "Spinning" )

  -- If flights are waiting outside 10 NM zone and carrier switches from Case I to Case II/III, they should be added to the Marshal stack as now there is no stack limit any more.
  if self.case > 1 then
    for _, _flight in pairs( self.Qwaiting ) do
      local flight = _flight -- #AIRBOSS.FlightGroup

      -- Remove flight from waiting queue.
      local removed = self:_RemoveFlightFromQueue( self.Qwaiting, flight )

      if removed then

        -- Get free stack
        local stack = self:_GetFreeStack( flight.ai )

        -- Debug info.
        self:T( self.lid .. string.format( "Moving flight %s onboard %s from Waiting queue to Case %d Marshal stack %d", flight.groupname, flight.onboard, self.case, stack ) )

        -- Send flight to marshal stack.
        if flight.ai then
          self:_MarshalAI( flight, stack )
        else
          self:_MarshalPlayer( flight, stack )
        end

        -- Break the loop so that only one flight per 30 seconds is removed.
        break
      end

    end
  end

  -- Check if carrier is currently in recovery mode.
  if not self:IsRecovering() then

    -----------------------------
    -- Switching Recovery Case --
    -----------------------------

    -- Loop over all flights currently in the marshal queue.
    for _, _flight in pairs( self.Qmarshal ) do
      local flight = _flight -- #AIRBOSS.FlightGroup

      -- TODO: In principle this should be done/necessary only if case 1-->2/3 or 2/3-->1, right?
      -- When recovery switches from 2->3 or 3-->2 nothing changes in the marshal stack.

      -- Check if a change of stack is necessary.
      if (flight.case == 1 and self.case > 1) or (flight.case > 1 and self.case == 1) then

        -- Remove flight from marshal queue.
        local removed = self:_RemoveFlightFromQueue( self.Qmarshal, flight )

        if removed then

          -- Get free stack
          local stack = self:_GetFreeStack( flight.ai )

          -- Debug output.
          self:T( self.lid .. string.format( "Moving flight %s onboard %s from Marshal Case %d ==> %d Marshal stack %d", flight.groupname, flight.onboard, flight.case, self.case, stack ) )

          -- Send flight to marshal queue.
          if flight.ai then
            self:_MarshalAI( flight, stack )
          else
            self:_MarshalPlayer( flight, stack )
          end

          -- Break the loop so that only one flight per 30 seconds is removed. No spam of messages, no conflict with the loop over queue entries.
          break

        elseif flight.case ~= self.case then

          -- This should handle 2-->3 or 3-->2
          flight.case = self.case

        end

      end
    end

    -- Not recovering ==> skip the rest!
    return
  end

  -- Get number of airborne aircraft units(!) currently in pattern.
  local _, npattern = self:_GetQueueInfo( self.Qpattern )

  -- Get number of aircraft units spinning.
  local _, nspinning = self:_GetQueueInfo( self.Qspinning )

  -- Get next marshal flight.
  local marshalflight = self:_GetNextMarshalFight()

  -- Check if there are flights waiting in the Marshal stack and if the pattern is free. No one should be spinning.
  if marshalflight and npattern < self.Nmaxpattern and nspinning == 0 then

    -- Time flight is marshaling.
    local Tmarshal = timer.getAbsTime() - marshalflight.time
    self:T( self.lid .. string.format( "Marshal time of next group %s = %d seconds", marshalflight.groupname, Tmarshal ) )

    -- Time (last) flight has entered landing pattern.
    local Tpattern = 9999
    local npunits = 1
    local pcase = 1
    if npattern > 0 then

      -- Last flight group send to pattern.
      local patternflight = self.Qpattern[#self.Qpattern] -- #AIRBOSS.FlightGroup

      -- Recovery case of pattern flight.
      pcase = patternflight.case

      -- Number of airborne aircraft in this group. Count includes section members.
      local npunits = self:_GetFlightUnits( patternflight, false )

      -- Get time in pattern.
      Tpattern = timer.getAbsTime() - patternflight.time
      self:T( self.lid .. string.format( "Pattern time of last group %s = %d seconds. # of units=%d.", patternflight.groupname, Tpattern, npunits ) )
    end

    -- Min time in pattern before next aircraft is allowed.
    local TpatternMin
    if pcase == 1 then
      TpatternMin = 2 * 60 * npunits -- 45*npunits   --  45 seconds interval per plane!
    else
      TpatternMin = 2 * 60 * npunits -- 120*npunits  -- 120 seconds interval per plane!
    end

    -- Check interval to last pattern flight.
    if Tpattern > TpatternMin then
      self:T( self.lid .. string.format( "Sending marshal flight %s to pattern.", marshalflight.groupname ) )
      self:_ClearForLanding( marshalflight )
    end

  end
end

--- Clear flight for landing. AI are removed from Marshal queue and the Marshal stack is collapsed.
-- If next in line is an AI flight, this is done. If human player is next, we wait for "Commence" via F10 radio menu command.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight to go to pattern.
function AIRBOSS:_ClearForLanding( flight )

  -- Check if flight is AI or human. If AI, we collapse the stack and commence. If human, we suggest to commence.
  if flight.ai then

    -- Collapse stack and send AI to pattern.
    self:_RemoveFlightFromMarshalQueue( flight, false )
    self:_LandAI( flight )

    -- Cleared for Case X recovery.
    self:_MarshalCallClearedForRecovery( flight.onboard, flight.case )

    -- Voice over of the commencing simulated call from AI
    if self.xtVoiceOversAI then
      local leader = flight.group:GetUnits()[1]
      self:_CommencingCall(leader, flight.onboard)
    end

  else

    -- Cleared for Case X recovery.
    if flight.step ~= AIRBOSS.PatternStep.COMMENCING then
      self:_MarshalCallClearedForRecovery( flight.onboard, flight.case )
      flight.time = timer.getAbsTime()
    end

    -- Set step to commencing. This will trigger the zone check until the player is in the right place.
    self:_SetPlayerStep( flight, AIRBOSS.PatternStep.COMMENCING, 3 )

  end

end

--- Set player step. Any warning is erased and next step hint shown.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string step Next step.
-- @param #number delay (Optional) Set set after a delay in seconds.
function AIRBOSS:_SetPlayerStep( playerData, step, delay )

  if delay and delay > 0 then
    -- Delayed call.
    -- SCHEDULER:New(nil, self._SetPlayerStep, {self, playerData, step}, delay)
    self:ScheduleOnce( delay, self._SetPlayerStep, self, playerData, step )
  else

    -- Check if player still exists after possible delay.
    if playerData then

      -- Set player step.
      playerData.step = step

      -- Erase warning.
      playerData.warning = nil

      -- Next step hint.
      self:_StepHint( playerData )
    end

  end

end

--- Scan carrier zone for (new) units.
-- @param #AIRBOSS self
function AIRBOSS:_ScanCarrierZone()

  -- Carrier position.
  local coord = self:GetCoordinate()

  -- Scan radius = radius of the CCA.
  local RCCZ = self.zoneCCA:GetRadius()

  -- Debug info.
  self:T( self.lid .. string.format( "Scanning Carrier Controlled Area. Radius=%.1f NM.", UTILS.MetersToNM( RCCZ ) ) )

  -- Scan units in carrier zone.
  local _, _, _, unitscan = coord:ScanObjects( RCCZ, true, false, false )

  -- Make a table with all groups currently in the CCA zone.
  local insideCCA = {}
  for _, _unit in pairs( unitscan ) do
    local unit = _unit -- Wrapper.Unit#UNIT

    -- Necessary conditions to be met:
    local airborne = unit:IsAir() -- and unit:InAir()
    local inzone = unit:IsInZone( self.zoneCCA )
    local friendly = self:GetCoalition() == unit:GetCoalition()
    local carrierac = self:_IsCarrierAircraft( unit )

    -- Check if this an aircraft and that it is airborne and closing in.
    if airborne and inzone and friendly and carrierac then

      local group = unit:GetGroup()
      local groupname = group:GetName()

      if insideCCA[groupname] == nil then
        insideCCA[groupname] = group
      end

    end
  end

  -- Find new flights that are inside CCA.
  for groupname, _group in pairs( insideCCA ) do
    local group = _group -- Wrapper.Group#GROUP

    -- Get flight group if possible.
    local knownflight = self:_GetFlightFromGroupInQueue( group, self.flights )

    -- Get aircraft type name.
    local actype = group:GetTypeName()

    if knownflight then

      -- Debug output.
      self:T2(self.lid..string.format("Known flight group %s of type %s in CCA.", groupname, actype))

      -- Check if flight is AI and if we want to handle it at all.
      if knownflight.ai and self.handleai then

        -- Defines if AI group should be handled by the airboss.
        local iscarriersquad=true

        -- Check if AI group is part of the group set if a set was defined.
        if self.squadsetAI then
          local group=self.squadsetAI:FindGroup(groupname)
          if group then
            iscarriersquad=true
          else
            iscarriersquad=false
          end
        end

        -- Check if group was explicitly excluded.
        if self.excludesetAI then
          local group=self.excludesetAI:FindGroup(groupname)
          if group then
            iscarriersquad=false
          end
                 
        end


        -- Get distance to carrier.
        local dist=knownflight.group:GetCoordinate():Get2DDistance(self:GetCoordinate())

        -- Close in distance. Is >0 if AC comes closer wrt to first detected distance d0.
        local closein=knownflight.dist0-dist

        -- Debug info.
        self:T3(self.lid..string.format("Known AI flight group %s closed in by %.1f NM", knownflight.groupname, UTILS.MetersToNM(closein)))

        -- Is this group the tanker?
        local istanker=self.tanker and self.tanker.tanker:GetName()==groupname

        -- Is this group the AWACS?
        local isawacs=self.awacs and self.awacs.tanker:GetName()==groupname

        -- Send tanker to marshal stack?
        local tanker2marshal = istanker and self.tanker:IsReturning() and self.tanker.airbase:GetName()==self.airbase:GetName() and knownflight.flag==-100 and self.tanker.recovery==true

        -- Send AWACS to marhsal stack?
        local awacs2marshal  = isawacs  and self.awacs:IsReturning()  and self.awacs.airbase:GetName()==self.airbase:GetName()  and knownflight.flag==-100 and self.awacs.recovery==true

        -- Put flight into Marshal.
        local putintomarshal=closein>UTILS.NMToMeters(5) and knownflight.flag==-100 and iscarriersquad and istanker==false and isawacs==false

        -- Send AI flight to marshal stack if group closes in more than 5 and has initial flag value.
        if putintomarshal or tanker2marshal or awacs2marshal then


          -- Get the next free stack for current recovery case.
          local stack = self:_GetFreeStack( knownflight.ai )

          -- Repawn.
          local respawn = self.respawnAI

          if stack then

            -- Send AI to marshal stack. We respawn the group to clean possible departure and destination airbases.
            self:_MarshalAI( knownflight, stack, respawn )

          else

            -- Send AI to orbit outside 10 NM zone and wait until the next Marshal stack is available.
            if not self:_InQueue( self.Qwaiting, knownflight.group ) then
              self:_WaitAI( knownflight, respawn ) -- Group is respawned to clear any attached airfields.
            end

          end

          -- Break the loop to not have all flights at once! Spams the message screen.
          break

        end -- Closed in or tanker/AWACS

      end

    else

      -- Unknown new AI flight. Create a new flight group.
      if not self:_IsHuman( group ) then
        self:_CreateFlightGroup( group )
      end
    end

  end

  -- Find flights that are not in CCA.
  local remove = {}
  for _, _flight in pairs( self.flights ) do
    local flight = _flight -- #AIRBOSS.FlightGroup
    if insideCCA[flight.groupname] == nil then
      -- Do not remove flights in marshal pattern. At least for case 2 & 3. If zone is set small, they might be outside in the holding pattern.
      if flight.ai and not (self:_InQueue( self.Qmarshal, flight.group ) or self:_InQueue( self.Qpattern, flight.group )) then
        table.insert( remove, flight )
      end
    end
  end

  -- Remove flight groups outside CCA.
  for _, flight in pairs( remove ) do
    self:_RemoveFlightFromQueue( self.flights, flight )
  end

end

--- Tell player to wait outside the 10 NM zone until a Marshal stack is available.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_WaitPlayer( playerData )

  -- Check if flight is known to the airboss already.
  if playerData then

    -- Number of waiting flights
    local nwaiting = #self.Qwaiting

    -- Radio message: Stack is full.
    self:_MarshalCallStackFull( playerData.onboard, nwaiting )

    -- Add player flight to waiting queue.
    table.insert( self.Qwaiting, playerData )

    -- Set time stamp.
    playerData.time = timer.getAbsTime()

    -- Set step to waiting.
    playerData.step = AIRBOSS.PatternStep.WAITING
    playerData.warning = nil

    -- Set all flights in section to waiting.
    for _, _flight in pairs( playerData.section ) do
      local flight = _flight -- #AIRBOSS.PlayerData
      flight.step = AIRBOSS.PatternStep.WAITING
      flight.time = timer.getAbsTime()
      flight.warning = nil
    end

  end

end

--- Orbit at a specified position at a specified altitude with a specified speed.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #number stack The Marshal stack the player gets.
function AIRBOSS:_MarshalPlayer( playerData, stack )

  -- Check if flight is known to the airboss already.
  if playerData then

    -- Add group to marshal stack.
    self:_AddMarshalGroup( playerData, stack )

    -- Set step to holding.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.HOLDING )

    -- Holding switch to nil until player arrives in the holding zone.
    playerData.holding = nil

    -- Set same stack for all flights in section.
    for _, _flight in pairs( playerData.section ) do
      local flight = _flight -- #AIRBOSS.PlayerData

      -- XXX: Inform player? Should be done by lead via radio?

      -- Set step.
      self:_SetPlayerStep( flight, AIRBOSS.PatternStep.HOLDING )

      -- Holding to nil, until arrived.
      flight.holding = nil

      -- Set case to that of lead.
      flight.case = playerData.case

      -- Set stack flag.
      flight.flag = stack

      -- Trigger Marshal event.
      self:Marshal( flight )
    end

  else
    self:E( self.lid .. "ERROR: Could not add player to Marshal stack! playerData=nil" )
  end

end

--- Command AI flight to orbit outside the 10 NM zone and wait for a free Marshal stack.
-- If the flight is not already holding in the Marshal stack, it is guided there first.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group.
-- @param #boolean respawn If true respawn the group. Otherwise reset the mission task with new waypoints.
function AIRBOSS:_WaitAI( flight, respawn )

  -- Set flag to something other than -100 and <0
  flight.flag = -99

  -- Add AI flight to waiting queue.
  table.insert( self.Qwaiting, flight )

  -- Flight group name.
  local group = flight.group
  local groupname = flight.groupname

  -- Aircraft speed 274 knots TAS ~= 250 KIAS when orbiting the pattern. (Orbit expects m/s.)
  local speedOrbitMps = UTILS.KnotsToMps( 274 )

  -- Orbit speed in km/h for waypoints.
  local speedOrbitKmh = UTILS.KnotsToKmph( 274 )

  -- Aircraft speed 400 knots when transiting to holding zone. (Waypoint expects km/h.)
  local speedTransit = UTILS.KnotsToKmph( 370 )

  -- Carrier coordinate
  local cv = self:GetCoordinate()

  -- Coordinate of flight group
  local fc = group:GetCoordinate()

  -- Carrier heading
  local hdg = self:GetHeading( false )

  -- Heading from carrier to flight group
  local hdgto = cv:HeadingTo( fc )

  -- Holding altitude between angels 6 and 10 (random).
  local angels = math.random( 6, 10 )
  local altitude = UTILS.FeetToMeters( angels * 1000 )

  -- Point outsize 10 NM zone of the carrier.
  local p0 = cv:Translate( UTILS.NMToMeters( 11 ), hdgto ):Translate( UTILS.NMToMeters( 5 ), hdg ):SetAltitude( altitude )

  -- Waypoints array to be filled depending on case etc.
  local wp = {}

  -- Current position. Always good for as the first waypoint.
  wp[1] = group:GetCoordinate():WaypointAirTurningPoint( nil, speedTransit, {}, "Current Position" )

  -- Set orbit task.
  local taskorbit = group:TaskOrbit( p0, altitude, speedOrbitMps )

  -- Orbit at waypoint.
  wp[#wp + 1] = p0:WaypointAirTurningPoint( nil, speedOrbitKmh, { taskorbit }, string.format( "Waiting Orbit at Angels %d", angels ) )

  -- Debug markers.
  if self.Debug then
    p0:MarkToAll( string.format( "Waiting Orbit of flight %s at Angels %s", groupname, angels ) )
  end

  if respawn then

    -- This should clear the landing waypoints.
    -- Note: This resets the weapons and the fuel state. But not the units fortunately.

    -- Get group template.
    local Template = group:GetTemplate()

    -- Set route points.
    Template.route.points = wp

    -- Respawn the group.
    group = group:Respawn( Template, true )

  end

  -- Reinit waypoints.
  group:WayPointInitialize( wp )

  -- Route group.
  group:Route( wp, 1 )

end

--- Command AI flight to orbit at a specified position at a specified altitude with a specified speed. If flight is not in the Marshal queue yet, it is added. This fixes the recovery case.
-- If the flight is not already holding in the Marshal stack, it is guided there first.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group.
-- @param #number nstack Stack number of group. Can also be the current stack if AI position needs to be updated wrt to changed carrier position.
-- @param #boolean respawn If true, respawn the flight otherwise update mission task with new waypoints.
function AIRBOSS:_MarshalAI( flight, nstack, respawn )
  self:F2( { flight = flight, nstack = nstack, respawn = respawn } )

  -- Nil check.
  if flight == nil or flight.group == nil then
    self:E( self.lid .. "ERROR: flight or flight.group is nil." )
    return
  end

  -- Nil check.
  if flight.group:GetCoordinate() == nil then
    self:E( self.lid .. "ERROR: cannot get coordinate of flight group." )
    return
  end

  -- Check if flight is already in Marshal queue.
  if not self:_InQueue(self.Qmarshal,flight.group) then
    -- Simulate inbound call
    if self.xtVoiceOversAI then
      local leader = flight.group:GetUnits()[1]
      self:_MarshallInboundCall(leader, flight.onboard)
    end
    -- Add group to marshal stack queue.
    self:_AddMarshalGroup( flight, nstack )
  end

  -- Explode unit for testing. Worked!
  -- local u1=flight.group:GetUnit(1) --Wrapper.Unit#UNIT
  -- u1:Explode(500, 10)

  -- Recovery case.
  local case = flight.case

  -- Get old/current stack.
  local ostack = flight.flag

  -- Flight group name.
  local group = flight.group
  local groupname = flight.groupname

  -- Set new stack.
  flight.flag = nstack

  -- Current carrier position.
  local Carrier = self:GetCoordinate()

  -- Carrier heading.
  local hdg = self:GetHeading()

  -- Aircraft speed 274 knots TAS ~= 250 KIAS when orbiting the pattern. (Orbit expects m/s.)
  local speedOrbitMps = UTILS.KnotsToMps( 274 )

  -- Orbit speed in km/h for waypoints.
  local speedOrbitKmh = UTILS.KnotsToKmph( 274 )

  -- Aircraft speed 400 knots when transiting to holding zone. (Waypoint expects km/h.)
  local speedTransit = UTILS.KnotsToKmph( 370 )

  local altitude
  local p0 -- Core.Point#COORDINATE
  local p1 -- Core.Point#COORDINATE
  local p2 -- Core.Point#COORDINATE

  -- Get altitude and positions.
  altitude, p1, p2 = self:_GetMarshalAltitude( nstack, case )

  -- Waypoints array to be filled depending on case etc.
  local wp = {}

  -- If flight has not arrived in the holding zone, we guide it there.
  if not flight.holding then

    ----------------------
    -- Route to Holding --
    ----------------------

    -- Debug info.
    self:T( self.lid .. string.format( "Guiding AI flight %s to marshal stack %d-->%d.", groupname, ostack, nstack ) )

    -- Current position. Always good for as the first waypoint.
    wp[1] = group:GetCoordinate():WaypointAirTurningPoint( nil, speedTransit, {}, "Current Position" )

    -- Task function when arriving at the holding zone. This will set flight.holding=true.
    local TaskArrivedHolding = flight.group:TaskFunction( "AIRBOSS._ReachedHoldingZone", self, flight )

    -- Select case.
    if case == 1 then

      -- Initial point 7 NM and a bit port of carrier.
      local pE = Carrier:Translate( UTILS.NMToMeters( 7 ), hdg - 30 ):SetAltitude( altitude )

      -- Entry point 5 NM port and slightly astern the boat.
      p0 = Carrier:Translate( UTILS.NMToMeters( 5 ), hdg - 135 ):SetAltitude( altitude )

      -- Waypoint ahead of carrier's holding zone.
      wp[#wp + 1] = pE:WaypointAirTurningPoint( nil, speedTransit, { TaskArrivedHolding }, "Entering Case I Marshal Pattern" )

    else

      -- Get correct radial depending on recovery case including offset.
      local radial = self:GetRadial( case, false, true )

      -- Point in the middle of the race track and a 5 NM more port perpendicular.
      p0 = p2:Translate( UTILS.NMToMeters( 5 ), radial + 90, true ):Translate( UTILS.NMToMeters( 5 ), radial, true )

      -- Entering Case II/III marshal pattern waypoint.
      wp[#wp + 1] = p0:WaypointAirTurningPoint( nil, speedTransit, { TaskArrivedHolding }, "Entering Case II/III Marshal Pattern" )

    end

  else

    ------------------------
    -- In Marshal Pattern --
    ------------------------

    -- Debug info.
    self:T( self.lid .. string.format( "Updating AI flight %s at marshal stack %d-->%d.", groupname, ostack, nstack ) )

    -- Current position. Speed expected in km/h.
    wp[1] = group:GetCoordinate():WaypointAirTurningPoint( nil, speedOrbitKmh, {}, "Current Position" )

    -- Create new waypoint 0.2 Nm ahead of current positon.
    p0 = group:GetCoordinate():Translate( UTILS.NMToMeters( 0.2 ), group:GetHeading(), true )

  end

  -- Set orbit task.
  local taskorbit = group:TaskOrbit( p1, altitude, speedOrbitMps, p2 )

  -- Orbit at waypoint.
  wp[#wp + 1] = p0:WaypointAirTurningPoint( nil, speedOrbitKmh, { taskorbit }, string.format( "Marshal Orbit Stack %d", nstack ) )

  -- Debug markers.
  if self.Debug then
    p0:MarkToAll( "WP P0 " .. groupname )
    p1:MarkToAll( "RT P1 " .. groupname )
    p2:MarkToAll( "RT P2 " .. groupname )
  end

  if respawn then

    -- This should clear the landing waypoints.
    -- Note: This resets the weapons and the fuel state. But not the units fortunately.

    -- Get group template.
    local Template = group:GetTemplate()

    -- Set route points.
    Template.route.points = wp

    -- Respawn the group.
    flight.group = group:Respawn( Template, true )

  end

  -- Reinit waypoints.
  flight.group:WayPointInitialize( wp )

  -- Route group.
  flight.group:Route( wp, 1 )

  -- Trigger Marshal event.
  self:Marshal( flight )

end

--- Tell AI to refuel. Either at the recovery tanker or at the nearest divert airfield.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group.
function AIRBOSS:_RefuelAI( flight )

  -- Waypoints array.
  local wp = {}

  -- Current speed.
  local CurrentSpeed = flight.group:GetVelocityKMH()

  -- Current positon.
  wp[#wp + 1] = flight.group:GetCoordinate():WaypointAirTurningPoint( nil, CurrentSpeed, {}, "Current position" )

  -- Check if aircraft can be refueled.
  -- TODO: This should also depend on the tanker type AC.
  local refuelac=false
  local actype=flight.group:GetTypeName()
  if actype==AIRBOSS.AircraftCarrier.AV8B      or
     actype==AIRBOSS.AircraftCarrier.F14A      or
     actype==AIRBOSS.AircraftCarrier.F14B      or
     actype==AIRBOSS.AircraftCarrier.F14A_AI   or
     actype==AIRBOSS.AircraftCarrier.HORNET    or
     actype==AIRBOSS.AircraftCarrier.RHINOE    or
     actype==AIRBOSS.AircraftCarrier.RHINOF    or
     actype==AIRBOSS.AircraftCarrier.GROWLER   or
     actype==AIRBOSS.AircraftCarrier.FA18C     or
     actype==AIRBOSS.AircraftCarrier.S3B       or
     actype==AIRBOSS.AircraftCarrier.S3BTANKER then
     refuelac=true
  end

  -- Message.
  local text = ""

  -- Refuel or divert?
  if self.tanker and refuelac then

    -- Current Tanker position.
    local tankerpos = self.tanker.tanker:GetCoordinate()

    -- Task refueling.
    local TaskRefuel = flight.group:TaskRefueling()

    -- Task to go back to Marshal.
    local TaskMarshal = flight.group:TaskFunction( "AIRBOSS._TaskFunctionMarshalAI", self, flight )

    -- Waypoint with tasks.
    wp[#wp + 1] = tankerpos:WaypointAirTurningPoint( nil, CurrentSpeed, { TaskRefuel, TaskMarshal }, "Refueling" )

    -- Marshal Message.
    self:_MarshalCallGasAtTanker( flight.onboard )

  else

    ------------------------------
    -- Guide AI to divert field --
    ------------------------------

    -- Closest Airfield of the coalition.
    local divertfield = self:GetCoordinate():GetClosestAirbase( Airbase.Category.AIRDROME, self:GetCoalition() )

    -- Handle case where there is no divert field of the own coalition and try neutral instead.
    if divertfield == nil then
      divertfield = self:GetCoordinate():GetClosestAirbase( Airbase.Category.AIRDROME, 0 )
    end

    if divertfield then

      -- Coordinate.
      local divertcoord = divertfield:GetCoordinate()

      -- Landing waypoint.
      wp[#wp + 1] = divertcoord:WaypointAirLanding( UTILS.KnotsToKmph( 300 ), divertfield, {}, "Divert Field" )

      -- Marshal Message.
      self:_MarshalCallGasAtDivert( flight.onboard, divertfield:GetName() )

      -- Respawn!

      -- Get group template.
      local Template = flight.group:GetTemplate()

      -- Set route points.
      Template.route.points = wp

      -- Respawn the group.
      flight.group = flight.group:Respawn( Template, true )

    else
      -- Set flight to refueling so this is not called again.
      self:E( self.lid .. string.format( "WARNING: No recovery tanker or divert field available for group %s.", flight.groupname ) )
      flight.refueling = true
      return
    end

  end

  -- Reinit waypoints.
  flight.group:WayPointInitialize( wp )

  -- Route group.
  flight.group:Route( wp, 1 )

  -- Set refueling switch.
  flight.refueling = true

end

--- Tell AI to land on the carrier.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group.
function AIRBOSS:_LandAI( flight )

  -- Debug info.
  self:T( self.lid .. string.format( "Landing AI flight %s.", flight.groupname ) )

  -- NOTE: Looks like the AI needs to approach at the "correct" speed. If they are too fast, they fly an unnecessary circle to bleed of speed first.
  --       Unfortunately, the correct speed depends on the aircraft type!

  -- Aircraft speed when flying the pattern.
  local Speed = UTILS.KnotsToKmph( 200 )

  if   flight.actype == AIRBOSS.AircraftCarrier.HORNET 
    or flight.actype == AIRBOSS.AircraftCarrier.FA18C
    or flight.actype == AIRBOSS.AircraftCarrier.RHINOE
    or flight.actype == AIRBOSS.AircraftCarrier.RHINOF
    or flight.actype == AIRBOSS.AircraftCarrier.GROWLER then
    Speed = UTILS.KnotsToKmph( 200 )
  elseif flight.actype == AIRBOSS.AircraftCarrier.E2D then
    Speed = UTILS.KnotsToKmph( 150 )
  elseif flight.actype == AIRBOSS.AircraftCarrier.F14A_AI or flight.actype == AIRBOSS.AircraftCarrier.F14A or flight.actype == AIRBOSS.AircraftCarrier.F14B then
    Speed = UTILS.KnotsToKmph( 175 )
  elseif flight.actype == AIRBOSS.AircraftCarrier.S3B or flight.actype == AIRBOSS.AircraftCarrier.S3BTANKER then
    Speed = UTILS.KnotsToKmph( 140 )
  end

  -- Carrier position.
  local Carrier = self:GetCoordinate()

  -- Carrier heading.
  local hdg = self:GetHeading()

  -- Waypoints array.
  local wp = {}

  local CurrentSpeed = flight.group:GetVelocityKMH()

  -- Current positon.
  wp[#wp + 1] = flight.group:GetCoordinate():WaypointAirTurningPoint( nil, CurrentSpeed, {}, "Current position" )

  -- Altitude 800 ft. Looks like this works best.
  local alt = UTILS.FeetToMeters( 800 )

  -- Landing waypoint 5 NM behind carrier at 2000 ft = 610 meters ASL.
  wp[#wp + 1] = Carrier:Translate( UTILS.NMToMeters( 4 ), hdg - 160 ):SetAltitude( alt ):WaypointAirLanding( Speed, self.airbase, nil, "Landing" )
  -- wp[#wp+1]=Carrier:Translate(UTILS.NMToMeters(4), hdg-160):SetAltitude(alt):WaypointAirLandingReFu(Speed, self.airbase, nil, "Landing")

  -- wp[#wp+1]=self:GetCoordinate():Translate(UTILS.NMToMeters(3), hdg-160):SetAltitude(alt):WaypointAirTurningPoint(nil,Speed, {}, "Before Initial") ---WaypointAirLanding(Speed, self.airbase, nil, "Landing")
  -- wp[#wp+1]=self:GetCoordinate():WaypointAirLanding(Speed, self.airbase, nil, "Landing")

  -- Reinit waypoints.
  flight.group:WayPointInitialize( wp )

  -- Route group.
  flight.group:Route( wp, 0 )
end

--- Get marshal altitude and two positions of a counter-clockwise race track pattern.
-- @param #AIRBOSS self
-- @param #number stack Assigned stack number. Counting starts at one, i.e. stack=1 is the first stack.
-- @param #number case Recovery case. Default is self.case.
-- @return #number Holding altitude in meters.
-- @return Core.Point#COORDINATE First race track coordinate.
-- @return Core.Point#COORDINATE Second race track coordinate.
function AIRBOSS:_GetMarshalAltitude( stack, case )

  -- Stack <= 0.
  if stack <= 0 then
    return 0, nil, nil
  end

  -- Recovery case.
  case = case or self.case

  -- Carrier position.
  local Carrier = self:GetCoordinate()

  -- Altitude of first stack. Depends on recovery case.
  local angels0
  local Dist
  local p1 = nil -- Core.Point#COORDINATE
  local p2 = nil -- Core.Point#COORDINATE

  -- Stack number.
  local nstack = stack - 1

  if case == 1 then

    -- CASE I: Holding at 2000 ft on a circular pattern port of the carrier. Interval +1000 ft for next stack.
    angels0 = 2

    -- Get true heading of carrier.
    local hdg = self.carrier:GetHeading()

    -- For CCW pattern: First point astern, second ahead of the carrier.

    -- First point over carrier.
    p1 = Carrier

    -- Second point 1.5 NM ahead.
    p2 = Carrier:Translate( UTILS.NMToMeters( 1.5 ), hdg )

    -- Tarawa,LHA,LHD Delta patterns.
    if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then

      -- Pattern is directly overhead the carrier.
      p1 = Carrier:Translate( UTILS.NMToMeters( 1.0 ), hdg + 90 )
      p2 = p1:Translate( 2.5, hdg )

    end

  else

    -- CASE II/III: Holding at 6000 ft on a racetrack pattern astern the carrier.
    angels0 = 6

    -- Distance: d=n*angels0+15 NM, so first stack is at 15+6=21 NM
    Dist = UTILS.NMToMeters( nstack + angels0 + 15 )

    -- Get correct radial depending on recovery case including offset.
    local radial = self:GetRadial( case, false, true )

    -- For CCW pattern: p1 further astern than p2.

    -- Length of the race track pattern.
    local l = UTILS.NMToMeters( 10 )

    -- First point of race track pattern.
    p1 = Carrier:Translate( Dist + l, radial )

    -- Second point.
    p2 = Carrier:Translate( Dist, radial )

  end

  -- Pattern altitude.
  local altitude = UTILS.FeetToMeters( (nstack + angels0) * 1000 )

  -- Set altitude of coordinate.
  p1:SetAltitude( altitude, true )
  p2:SetAltitude( altitude, true )

  return altitude, p1, p2
end

--- Calculate an estimate of the charlie time of the player based on how many other aircraft are in the marshal or pattern queue before him.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flightgroup Flight data.
-- @return #number Charlie (abs) time in seconds. Or nil, if stack<0 or no recovery window will open.
function AIRBOSS:_GetCharlieTime( flightgroup )

  -- Get current stack of player.
  local stack = flightgroup.flag

  -- Flight is not in marshal stack.
  if stack <= 0 then
    return nil
  end

  -- Current abs time.
  local Tnow = timer.getAbsTime()

  -- Time the player has to spend in marshal stack until all lower stacks are emptied.
  local Tcharlie = 0

  local Trecovery = 0
  if self.recoverywindow then
    -- Time in seconds until the next recovery starts or 0 if window is already open.
    Trecovery = math.max( self.recoverywindow.START - Tnow, 0 )
  else
    -- Set ~7 min if no future recovery window is defined. Otherwise radio call function crashes.
    Trecovery = 7 * 60
  end

  -- Loop over flights currently in the marshal queue.
  for _, _flight in pairs( self.Qmarshal ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Stack of marshal flight.
    local mstack = flight.flag

    -- Time to get to the marshal stack if not holding already.
    local Tarrive = 0

    -- Minimum holding time per stack.
    local Tholding = 3 * 60

    if stack > 0 and mstack > 0 and mstack <= stack then

      -- Check if flight is already holding or just on its way.
      if flight.holding == nil then
        -- Flight is on its way to the marshal stack.

        -- Coordinate of the holding zone.
        local holdingzone = self:_GetZoneHolding( flight.case, 1 ):GetCoordinate()

        -- Distance to holding zone.
        local d0 = holdingzone:Get2DDistance( flight.group:GetCoordinate() )

        -- Current velocity.
        local v0 = flight.group:GetVelocityMPS()

        -- Time to get to the carrier.
        Tarrive = d0 / v0

        self:T3( self.lid .. string.format( "Tarrive=%.1f seconds, Clock %s", Tarrive, UTILS.SecondsToClock( Tnow + Tarrive ) ) )

      else
        -- Flight is already holding.

        -- Next in line.
        if mstack == 1 then

          -- Current holding time. flight.time stamp should be when entering holding or last time the stack collapsed.
          local tholding = timer.getAbsTime() - flight.time

          -- Deduce current holding time. Ensure that is >=0.
          Tholding = math.max( 3 * 60 - tholding, 0 )
        end

      end

      -- This is the approx time needed to get to the pattern. If we are already there, it is the time until the recovery window opens or 0 if it is already open.
      local Tmin = math.max( Tarrive, Trecovery )

      -- Charlie time + 2 min holding in stack 1.
      Tcharlie = math.max( Tmin, Tcharlie ) + Tholding
    end

  end

  -- Convert to abs time.
  Tcharlie = Tcharlie + Tnow

  -- Debug info.
  local text = string.format( "Charlie time for flight %s (%s) %s", flightgroup.onboard, flightgroup.groupname, UTILS.SecondsToClock( Tcharlie ) )
  MESSAGE:New( text, 10, "DEBUG" ):ToAllIf( self.Debug )
  self:T( self.lid .. text )

  return Tcharlie
end

--- Add a flight group to the Marshal queue at a specific stack. Flight is informed via message. This fixes the recovery case to the current case ops in progress self.case).
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group.
-- @param #number stack Marshal stack. This (re-)sets the flag value.
function AIRBOSS:_AddMarshalGroup( flight, stack )

  -- Set flag value. This corresponds to the stack number which starts at 1.
  flight.flag = stack

  -- Set recovery case.
  flight.case = self.case

  -- Add to marshal queue.
  table.insert( self.Qmarshal, flight )

  -- Pressure.
  local P = UTILS.hPa2inHg( self:GetCoordinate():GetPressure() )

  -- Stack altitude.
  -- local alt=UTILS.MetersToFeet(self:_GetMarshalAltitude(stack, flight.case))
  local alt = self:_GetMarshalAltitude( stack, flight.case )

  -- Current BRC.
  local brc = self:GetBRC()

  -- If the carrier is supposed to turn into the wind, we take the wind coordinate.
  if self.recoverywindow and self.recoverywindow.WIND then
    brc = self:GetBRCintoWind()
  end

  -- Get charlie time estimate.
  flight.Tcharlie = self:_GetCharlieTime( flight )

  -- Convert to clock string.
  local Ccharlie = UTILS.SecondsToClock( flight.Tcharlie )

  -- Combined marshal call.
  self:_MarshalCallArrived( flight.onboard, flight.case, brc, alt, Ccharlie, P )

  -- Hint about TACAN bearing.
  if self.TACANon and (not flight.ai) and flight.difficulty == AIRBOSS.Difficulty.EASY then
    -- Get inverse magnetic radial potential offset.
    local radial = self:GetRadial( flight.case, true, true, true )
    if flight.case == 1 then
      -- For case 1 we want the BRC but above routine return FB.
      radial = self:GetBRC()
    end
    local text = string.format( "Select TACAN %03d°, channel %d%s (%s)", radial, self.TACANchannel, self.TACANmode, self.TACANmorse )
    self:MessageToPlayer( flight, text, nil, "" )
  end

end

--- Collapse marshal stack.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight that left the marshal stack.
-- @param #boolean nopattern If true, flight does not go to pattern.
function AIRBOSS:_CollapseMarshalStack( flight, nopattern )
  self:F2( { flight = flight, nopattern = nopattern } )

  -- Recovery case of flight.
  local case = flight.case

  -- Stack of flight.
  local stack = flight.flag

  -- Check that stack > 0.
  if stack <= 0 then
    self:E( self.lid .. string.format( "ERROR: Flight %s is has stack value %d<0. Cannot collapse stack!", flight.groupname, stack ) )
    return
  end

  -- Memorize time when stack collapsed. Should better depend on case but for now we assume there are no two different stacks Case I or II/III.
  self.Tcollapse = timer.getTime()

  -- Decrease flag values of all flight groups in marshal stack.
  for _, _flight in pairs( self.Qmarshal ) do
    local mflight = _flight -- #AIRBOSS.PlayerData

    -- Only collapse stack of which the flight left. CASE II/III stacks are not collapsed.
    if (case == 1 and mflight.case == 1) then -- or (case>1 and mflight.case>1) then

      -- Get current flag/stack value.
      local mstack = mflight.flag

      -- Only collapse stacks above the new pattern flight.
      if mstack > stack then

        -- TODO: Is this now right as we allow more flights per stack?
        -- Question is, does the stack collapse if the lower stack is completely empty or do aircraft descent if just one flight leaves.
        -- For now, assuming that the stack must be completely empty before the next higher AC are allowed to descent.
        local newstack = self:_GetFreeStack( mflight.ai, mflight.case, true )

        -- Free stack has to be below.
        if newstack and newstack < mstack then

          -- Debug info.
          self:T( self.lid .. string.format( "Collapse Marshal: Flight %s (case %d) is changing marshal stack %d --> %d.", mflight.groupname, mflight.case, mstack, newstack ) )

          if mflight.ai then

            -- Command AI to decrease stack. Flag is set in the routine.
            self:_MarshalAI( mflight, newstack )

          else

            -- Decrease stack/flag. Human player needs to take care himself.
            mflight.flag = newstack

            -- Angels of new stack.
            local angels = self:_GetAngels( self:_GetMarshalAltitude( newstack, case ) )

            -- Inform players.
            if mflight.difficulty ~= AIRBOSS.Difficulty.HARD then

              -- Send message to all non-pros that they can descent.
              local text = string.format( "descent to stack at Angels %d.", angels )
              self:MessageToPlayer( mflight, text, "MARSHAL" )

            end

            -- Set time stamp.
            mflight.time = timer.getAbsTime()

            -- Loop over section members.
            for _, _sec in pairs( mflight.section ) do
              local sec = _sec -- #AIRBOSS.PlayerData

              -- Also decrease flag for section members of flight.
              sec.flag = newstack

              -- Set new time stamp.
              sec.time = timer.getAbsTime()

              -- Inform section member.
              if sec.difficulty ~= AIRBOSS.Difficulty.HARD then
                local text = string.format( "descent to stack at Angels %d.", angels )
                self:MessageToPlayer( sec, text, "MARSHAL" )
              end

            end

          end

        end
      end
    end
  end

  if nopattern then

    -- Debug message.
    self:T( self.lid .. string.format( "Flight %s is leaving stack but not going to pattern.", flight.groupname ) )

  else

    -- Debug message.
    local Tmarshal = UTILS.SecondsToClock( timer.getAbsTime() - flight.time )
    self:T( self.lid .. string.format( "Flight %s is leaving marshal after %s and going pattern.", flight.groupname, Tmarshal ) )

    -- Add flight to pattern queue.
    self:_AddFlightToPatternQueue( flight )

  end

  -- Set flag to -1 (-1 is rather arbitrary but it should not be positive or -100 or -42).
  flight.flag = -1

  -- New time stamp for time in pattern.
  flight.time = timer.getAbsTime()

end

--- Get next free Marshal stack. Depending on AI/human and recovery case.
-- @param #AIRBOSS self
-- @param #boolean ai If true, get a free stack for an AI flight group.
-- @param #number case Recovery case. Default current (self) case in progress.
-- @param #boolean empty Return lowest stack that is completely empty.
-- @return #number Lowest free stack available for the given case or nil if all Case I stacks are taken.
function AIRBOSS:_GetFreeStack( ai, case, empty )

  -- Recovery case.
  case = case or self.case

  if case == 1 then
    return self:_GetFreeStack_Old( ai, case, empty )
  end

  -- Max number of stacks available.
  local nmaxstacks = 100
  if case == 1 then
    nmaxstacks = self.Nmaxmarshal
  end

  -- Assume up to two (human) flights per stack. All are free.
  local stack = {}
  for i = 1, nmaxstacks do
    stack[i] = self.NmaxStack -- Number of human flights per stack.
  end

  local nmax = 1

  -- Loop over all flights in marshal stack.
  for _, _flight in pairs( self.Qmarshal ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Check that the case is right.
    if flight.case == case then

      -- Get stack of flight.
      local n = flight.flag

      if n > nmax then
        nmax = n
      end

      if n > 0 then
        if flight.ai or flight.case > 1 then
          stack[n] = 0 -- AI get one stack on their own. Also CASE II/III get one stack each.
        else
          stack[n] = stack[n] - 1
        end
      else
        self:E( string.format( "ERROR: Flight %s in marshal stack has stack value <= 0. Stack value is %d.", flight.groupname, n ) )
      end

    end
  end

  local nfree = nil
  if stack[nmax] == 0 then
    -- Max occupied stack is completely full!
    if case == 1 then
      if nmax >= nmaxstacks then
        -- Already all Case I stacks are occupied ==> wait outside 10 NM zone.
        nfree = nil
      else
        -- Return next free stack.
        nfree = nmax + 1
      end
    else
      -- Case II/III return next stack
      nfree = nmax + 1
    end

  elseif stack[nmax] == self.NmaxStack then
    -- Max occupied stack is completely empty! This should happen only when there is no other flight in the marshal queue.
    self:E( self.lid .. string.format( "ERROR: Max occupied stack is empty. Should not happen! Nmax=%d, stack[nmax]=%d", nmax, stack[nmax] ) )
    nfree = nmax
  else
    -- Max occupied stack is partly full.
    if ai or empty or case > 1 then
      nfree = nmax + 1
    else
      nfree = nmax
    end

  end

  self:I( self.lid .. string.format( "Returning free stack %s", tostring( nfree ) ) )
  return nfree
end

--- Get next free Marshal stack. Depending on AI/human and recovery case.
-- @param #AIRBOSS self
-- @param #boolean ai If true, get a free stack for an AI flight group.
-- @param #number case Recovery case. Default current (self) case in progress.
-- @param #boolean empty Return lowest stack that is completely empty.
-- @return #number Lowest free stack available for the given case or nil if all Case I stacks are taken.
function AIRBOSS:_GetFreeStack_Old( ai, case, empty )

  -- Recovery case.
  case = case or self.case

  -- Max number of stacks available.
  local nmaxstacks = 100
  if case == 1 then
    nmaxstacks = self.Nmaxmarshal
  end

  -- Assume up to two (human) flights per stack. All are free.
  local stack = {}
  for i = 1, nmaxstacks do
    stack[i] = self.NmaxStack -- Number of human flights per stack.
  end

  -- Loop over all flights in marshal stack.
  for _, _flight in pairs( self.Qmarshal ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Check that the case is right.
    if flight.case == case then

      -- Get stack of flight.
      local n = flight.flag

      if n > 0 then
        if flight.ai or flight.case > 1 then
          stack[n] = 0 -- AI get one stack on their own. Also CASE II/III get one stack each.
        else
          stack[n] = stack[n] - 1
        end
      else
        self:E( string.format( "ERROR: Flight %s in marshal stack has stack value <= 0. Stack value is %d.", flight.groupname, n ) )
      end

    end
  end

  -- Loop over stacks and check which one has a place left.
  local nfree = nil
  for i = 1, nmaxstacks do
    self:T2( self.lid .. string.format( "FF Stack[%d]=%d", i, stack[i] ) )
    if ai or empty or case > 1 then
      -- AI need the whole stack.
      if stack[i] == self.NmaxStack then
        nfree = i
        return i
      end
    else
      -- Human players only need one free spot.
      if stack[i] > 0 then
        nfree = i
        return i
      end
    end
  end

  return nfree
end

--- Get number of (airborne) units in a flight.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight The flight group.
-- @param #boolean onground If true, include units on the ground. By default only airborne units are counted.
-- @return #number Number of units in flight including section members.
-- @return #number Number of units in flight excluding section members.
-- @return #number Number of section members.
function AIRBOSS:_GetFlightUnits( flight, onground )

  -- Default is only airborne.
  local inair = true
  if onground == true then
    inair = false
  end

  --- Count units of a group which are alive and in the air.
  local function countunits( _group, inair )
    local group = _group -- Wrapper.Group#GROUP
    local units = group:GetUnits()
    local n = 0
    if units then
      for _, _unit in pairs( units ) do
        local unit = _unit -- Wrapper.Unit#UNIT
        if unit and unit:IsAlive() then
          if inair then
            -- Only count units in air.
            if unit:InAir() then
              self:T2( self.lid .. string.format( "Unit %s is in AIR", unit:GetName() ) )
              n = n + 1
            end
          else
            -- Count units in air or on the ground.
            n = n + 1
          end
        end
      end
    end
    return n
  end

  -- Count units of the group itself (alive units in air).
  local nunits = countunits( flight.group, inair )

  -- Count section members.
  local nsection = 0
  for _, sec in pairs( flight.section ) do
    local secflight = sec -- #AIRBOSS.PlayerData
    -- Count alive units in air.
    nsection = nsection + countunits( secflight.group, inair )
  end

  return nunits + nsection, nunits, nsection
end

--- Get number of groups and units in queue, which are alive and airborne. In units we count the section members as well.
-- @param #AIRBOSS self
-- @param #table queue The queue. Can be self.flights, self.Qmarshal or self.Qpattern.
-- @param #number case (Optional) Only count flights, which are in a specific recovery case. Note that you can use case=23 for flights that are either in Case II or III. By default all groups/units regardless of case are counted.
-- @return #number Total number of flight groups in queue.
-- @return #number Total number of aircraft in queue since each flight group can contain multiple aircraft.
function AIRBOSS:_GetQueueInfo( queue, case )

  local ngroup = 0
  local Nunits = 0

  -- Loop over flight groups.
  for _, _flight in pairs( queue ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Check if a specific case was requested.
    if case then

      ------------------------------------------------------------------------
      -- Only count specific case with special 23 = CASE II and III combined.
      ------------------------------------------------------------------------

      if (flight.case == case) or (case == 23 and (flight.case == 2 or flight.case == 3)) then

        -- Number of total units, units in flight and section members ALIVE and AIRBORNE.
        local ntot, nunits, nsection = self:_GetFlightUnits( flight )

        -- Add up total unit number.
        Nunits = Nunits + ntot

        -- Increase group count.
        if ntot > 0 then
          ngroup = ngroup + 1
        end

      end

    else

      ---------------------------------------------------------------------------
      -- No specific case requested. Count all groups & units in selected queue.
      ---------------------------------------------------------------------------

      -- Number of total units, units in flight and section members ALIVE and AIRBORNE.
      local ntot, nunits, nsection = self:_GetFlightUnits( flight )

      -- Add up total unit number.
      Nunits = Nunits + ntot

      -- Increase group count.
      if ntot > 0 then
        ngroup = ngroup + 1
      end

    end

  end

  return ngroup, Nunits
end

--- Print holding queue.
-- @param #AIRBOSS self
-- @param #table queue Queue to print.
-- @param #string name Queue name.
function AIRBOSS:_PrintQueue( queue, name )

  -- local nqueue=#queue
  local Nqueue, nqueue = self:_GetQueueInfo( queue )

  local text = string.format( "%s Queue N=%d (#%d), n=%d:", name, Nqueue, #queue, nqueue )
  if #queue == 0 then
    text = text .. " empty."
  else
    for i, _flight in pairs( queue ) do
      local flight = _flight -- #AIRBOSS.FlightGroup

      local clock = UTILS.SecondsToClock( timer.getAbsTime() - flight.time )
      local case = flight.case
      local stack = flight.flag
      local fuel = flight.group:GetFuelMin() * 100
      local ai = tostring( flight.ai )
      local lead = flight.seclead
      local Nsec = #flight.section
      local actype = self:_GetACNickname( flight.actype )
      local onboard = flight.onboard
      local holding = tostring( flight.holding )

      -- Airborne units.
      local _, nunits, nsec = self:_GetFlightUnits( flight, false )

      -- Text.
      text = text .. string.format( "\n[%d] %s*%d (%s): lead=%s (%d/%d), onboard=%s, flag=%d, case=%d, time=%s, fuel=%d, ai=%s, holding=%s", i, flight.groupname, nunits, actype, lead, nsec, Nsec, onboard, stack, case, clock, fuel, ai, holding )
      if stack > 0 then
        local alt = UTILS.MetersToFeet( self:_GetMarshalAltitude( stack, case ) )
        text = text .. string.format( " stackalt=%d ft", alt )
      end
      for j, _element in pairs( flight.elements ) do
        local element = _element -- #AIRBOSS.FlightElement
        text = text .. string.format( "\n  (%d) %s (%s): ai=%s, ballcall=%s, recovered=%s", j, element.onboard, element.unitname, tostring( element.ai ), tostring( element.ballcall ), tostring( element.recovered ) )
      end
    end
  end
  self:T( self.lid .. text )
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FLIGHT & PLAYER functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new flight group. Usually when a flight appears in the CCA.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #AIRBOSS.FlightGroup Flight group.
function AIRBOSS:_CreateFlightGroup( group )

  -- Debug info.
  self:T( self.lid .. string.format( "Creating new flight for group %s of aircraft type %s.", group:GetName(), group:GetTypeName() ) )

  -- New flight.
  local flight = {} -- #AIRBOSS.FlightGroup

  -- Check if not already in flights
  if not self:_InQueue( self.flights, group ) then

    -- Flight group name
    local groupname = group:GetName()
    local human, playername = self:_IsHuman( group )

    -- Queue table item.
    flight.group = group
    flight.groupname = group:GetName()
    flight.nunits = #group:GetUnits()
    flight.time = timer.getAbsTime()
    flight.dist0 = group:GetCoordinate():Get2DDistance( self:GetCoordinate() )
    flight.flag = -100
    flight.ai = not human
    flight.actype = group:GetTypeName()
    flight.onboardnumbers = self:_GetOnboardNumbers( group )
    flight.seclead = flight.group:GetUnit( 1 ):GetName() -- Sec lead is first unitname of group but player name for players.
    flight.section = {}
    flight.ballcall = false
    flight.refueling = false
    flight.holding = nil
    flight.name = flight.group:GetUnit( 1 ):GetName() -- Will be overwritten in _Newplayer with player name if human player in the group.

    -- Note, this should be re-set elsewhere!
    flight.case = self.case

    -- Flight elements.
    local text = string.format( "Flight elements of group %s:", flight.groupname )
    flight.elements = {}
    local units = group:GetUnits()
    for i, _unit in pairs( units ) do
      local unit = _unit -- Wrapper.Unit#UNIT
      local element = {} -- #AIRBOSS.FlightElement
      element.unit = unit
      element.unitname = unit:GetName()
      element.onboard = flight.onboardnumbers[element.unitname]
      element.ballcall = false
      element.ai = not self:_IsHumanUnit( unit )
      element.recovered = nil
      text = text .. string.format( "\n[%d] %s onboard #%s, AI=%s", i, element.unitname, tostring( element.onboard ), tostring( element.ai ) )
      table.insert( flight.elements, element )
    end
    self:T( self.lid .. text )

    -- Onboard
    if flight.ai then
      local onboard = flight.onboardnumbers[flight.seclead]
      flight.onboard = onboard
    else
      flight.onboard = self:_GetOnboardNumberPlayer( group )
    end

    -- Add to known flights.
    table.insert( self.flights, flight )

  else
    self:E( self.lid .. string.format( "ERROR: Flight group %s already exists in self.flights!", group:GetName() ) )
    return nil
  end

  return flight
end

--- Initialize player data after birth event of player unit.
-- @param #AIRBOSS self
-- @param #string unitname Name of the player unit.
-- @return #AIRBOSS.PlayerData Player data.
function AIRBOSS:_NewPlayer( unitname )

  -- Get player unit and name.
  local playerunit, playername = self:_GetPlayerUnitAndName( unitname )

  if playerunit and playername then

    -- Get group.
    local group = playerunit:GetGroup()

    -- Player data.
    local playerData -- #AIRBOSS.PlayerData

    -- Create a flight group for the player.
    playerData = self:_CreateFlightGroup( group )

    -- Nil check.
    if playerData then

      -- Player unit, client and callsign.
      playerData.unit = playerunit
      playerData.unitname = unitname
      playerData.name = playername
      playerData.callsign = playerData.unit:GetCallsign()
      playerData.client = CLIENT:FindByName( unitname, nil, true )
      playerData.seclead = playername

      -- Number of passes done by player in this slot.
      playerData.passes = 0 -- playerData.passes or 0

      -- Messages for player.
      playerData.messages = {}

      -- Debriefing tables.
      playerData.lastdebrief = playerData.lastdebrief or {}

      -- Attitude monitor.
      playerData.attitudemonitor = false

      -- Trap sheet save.
      if playerData.trapon == nil then
        playerData.trapon = self.trapsheet
      end

      -- Set difficulty level.
      playerData.difficulty = playerData.difficulty or self.defaultskill

      -- Subtitles of player.
      if playerData.subtitles == nil then
        playerData.subtitles = true
      end

      -- Show step hints.
      if playerData.showhints == nil then
        if playerData.difficulty == AIRBOSS.Difficulty.HARD then
          playerData.showhints = false
        else
          playerData.showhints = true
        end
      end

      -- Points rewarded.
      playerData.points = {}

      -- Init stuff for this round.
      playerData = self:_InitPlayer( playerData )

      -- Init player data.
      self.players[playername] = playerData

      -- Init player grades table if necessary.
      self.playerscores[playername] = self.playerscores[playername] or {}

      -- Welcome player message.
      if self.welcome then
        self:MessageToPlayer( playerData, string.format( "Welcome, %s %s!", playerData.difficulty, playerData.name ), string.format( "AIRBOSS %s", self.alias ), "", 5 )
      end

    end

    -- Return player data table.
    return playerData
  end

  return nil
end

--- Initialize player data by (re-)setting parmeters to initial values.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string step (Optional) New player step. Default UNDEFINED.
-- @return #AIRBOSS.PlayerData Initialized player data.
function AIRBOSS:_InitPlayer( playerData, step )
  self:T( self.lid .. string.format( "Initializing player data for %s callsign %s.", playerData.name, playerData.callsign ) )

  playerData.step = step or AIRBOSS.PatternStep.UNDEFINED
  playerData.groove = {}
  playerData.debrief = {}
  playerData.trapsheet = {}
  playerData.warning = nil
  playerData.holding = nil
  playerData.refueling = false
  playerData.valid = false
  playerData.lig = false
  playerData.wop = false
  playerData.waveoff = false
  playerData.wofd = false
  playerData.owo = false
  playerData.boltered = false
  playerData.hover = false
  playerData.stable = false
  playerData.landed = false
  playerData.Tlso = timer.getTime()
  playerData.Tgroove = nil
  playerData.TIG0 = nil
  playerData.wire = nil
  playerData.flag = -100
  playerData.debriefschedulerID = nil

  -- Set us up on final if group name contains "Groove". But only for the first pass.
  if playerData.group:GetName():match( "Groove" ) and playerData.passes == 0 then
    self:MessageToPlayer( playerData, "Group name contains \"Groove\". Happy groove testing." )
    playerData.attitudemonitor = true
    playerData.step = AIRBOSS.PatternStep.FINAL
    self:_AddFlightToPatternQueue( playerData )
    self.dTstatus = 0.1
  end

  return playerData
end

--- Get flight from group in a queue.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Group that will be removed from queue.
-- @param #table queue The queue from which the group will be removed.
-- @return #AIRBOSS.FlightGroup Flight group or nil.
-- @return #number Queue index or nil.
function AIRBOSS:_GetFlightFromGroupInQueue( group, queue )

  if group then

    -- Group name
    local name = group:GetName()

    -- Loop over all flight groups in queue
    for i, _flight in pairs( queue ) do
      local flight = _flight -- #AIRBOSS.FlightGroup

      if flight.groupname == name then
        return flight, i
      end
    end

    self:T2( self.lid .. string.format( "WARNING: Flight group %s could not be found in queue.", name ) )
  end

  self:T2( self.lid .. string.format( "WARNING: Flight group could not be found in queue. Group is nil!" ) )
  return nil, nil
end

--- Get element in flight.
-- @param #AIRBOSS self
-- @param #string unitname Name of the unit.
-- @return #AIRBOSS.FlightElement Element of the flight or nil.
-- @return #number Element index or nil.
-- @return #AIRBOSS.FlightGroup The Flight group or nil
function AIRBOSS:_GetFlightElement( unitname )

  -- Get the unit.
  local unit = UNIT:FindByName( unitname )

  -- Check if unit exists.
  if unit then

    -- Get flight element from all flights.
    local flight = self:_GetFlightFromGroupInQueue( unit:GetGroup(), self.flights )

    -- Check if fight exists.
    if flight then

      -- Loop over all elements in flight group.
      for i, _element in pairs( flight.elements ) do
        local element = _element -- #AIRBOSS.FlightElement

        if element.unit:GetName() == unitname then
          return element, i, flight
        end
      end

      self:T2( self.lid .. string.format( "WARNING: Flight element %s could not be found in flight group.", unitname, flight.groupname ) )
    end
  end

  return nil, nil, nil
end

--- Get element in flight.
-- @param #AIRBOSS self
-- @param #string unitname Name of the unit.
-- @return #boolean If true, element could be removed or nil otherwise.
function AIRBOSS:_RemoveFlightElement( unitname )

  -- Get table index.
  local element, idx, flight = self:_GetFlightElement( unitname )

  if idx then
    table.remove( flight.elements, idx )
    return true
  else
    self:T( "WARNING: Flight element could not be removed from flight group. Index=nil!" )
    return nil
  end
end

--- Check if a group is in a queue.
-- @param #AIRBOSS self
-- @param #table queue The queue to check.
-- @param Wrapper.Group#GROUP group The group to be checked.
-- @return #boolean If true, group is in the queue. False otherwise.
function AIRBOSS:_InQueue( queue, group )
  local name = group:GetName()
  for _, _flight in pairs( queue ) do
    local flight = _flight -- #AIRBOSS.FlightGroup
    if name == flight.groupname then
      return true
    end
  end
  return false
end

--- Remove dead flight groups from all queues.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #AIRBOSS.FlightGroup Flight group.
function AIRBOSS:_RemoveDeadFlightGroups()

  -- Remove dead flights from all flights table.
  for i = #self.flight, 1, -1 do
    local flight = self.flights[i] -- #AIRBOSS.FlightGroup
    if not flight.group:IsAlive() then
      self:T( string.format( "Removing dead flight group %s from ALL flights table.", flight.groupname ) )
      table.remove( self.flights, i )
    end
  end

  -- Remove dead flights from Marhal queue table.
  for i = #self.Qmarshal, 1, -1 do
    local flight = self.Qmarshal[i] -- #AIRBOSS.FlightGroup
    if not flight.group:IsAlive() then
      self:T( string.format( "Removing dead flight group %s from Marshal Queue table.", flight.groupname ) )
      table.remove( self.Qmarshal, i )
    end
  end

  -- Remove dead flights from Pattern queue table.
  for i = #self.Qpattern, 1, -1 do
    local flight = self.Qpattern[i] -- #AIRBOSS.FlightGroup
    if not flight.group:IsAlive() then
      self:T( string.format( "Removing dead flight group %s from Pattern Queue table.", flight.groupname ) )
      table.remove( self.Qpattern, i )
    end
  end

end

--- Get the lead flight group of a flight group.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group to check.
-- @return #AIRBOSS.FlightGroup Flight group of the leader or flight itself if no other leader.
function AIRBOSS:_GetLeadFlight( flight )

  -- Init.
  local lead = flight

  -- Only human players can be section leads of other players.
  if flight.name ~= flight.seclead then
    lead = self.players[flight.seclead]
  end

  return lead
end

--- Check if all elements of a flight were recovered. This also checks potential section members.
-- If so, flight is removed from the queue.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group to check.
-- @return #boolean If true, all elements landed.
function AIRBOSS:_CheckSectionRecovered( flight )

  -- Nil check.
  if flight == nil then
    return true
  end

  -- Get the lead flight first, so that we can also check all section members.
  local lead = self:_GetLeadFlight( flight )

  -- Check all elements of the lead flight group.
  for _, _element in pairs( lead.elements ) do
    local element = _element -- #AIRBOSS.FlightElement
    if not element.recovered then
      return false
    end
  end

  -- Now check all section members, if any.
  for _, _section in pairs( lead.section ) do
    local sectionmember = _section -- #AIRBOSS.FlightGroup

    -- Check all elements of the secmember flight group.
    for _, _element in pairs( sectionmember.elements ) do
      local element = _element -- #AIRBOSS.FlightElement
      if not element.recovered then
        return false
      end
    end
  end

  -- Remove lead flight from pattern queue. It is this flight who is added to the queue.
  self:_RemoveFlightFromQueue( self.Qpattern, lead )

  -- Just for now, check if it is in other queues as well.
  if self:_InQueue( self.Qmarshal, lead.group ) then
    self:E( self.lid .. string.format( "ERROR: lead flight group %s should not be in marshal queue", lead.groupname ) )
    self:_RemoveFlightFromMarshalQueue( lead, true )
  end
  -- Just for now, check if it is in other queues as well.
  if self:_InQueue( self.Qwaiting, lead.group ) then
    self:E( self.lid .. string.format( "ERROR: lead flight group %s should not be in pattern queue", lead.groupname ) )
    self:_RemoveFlightFromQueue( self.Qwaiting, lead )
  end

  return true
end

--- Add flight to pattern queue and set recoverd to false for all elements of the flight and its section members.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup Flight group of element.
function AIRBOSS:_AddFlightToPatternQueue( flight )

  -- Add flight to table.
  table.insert( self.Qpattern, flight )

  -- Set flag to -1 (-1 is rather arbitrary but it should not be positive or -100 or -42).
  flight.flag = -1
  -- New time stamp for time in pattern.
  flight.time = timer.getAbsTime()

  -- Init recovered switch.
  flight.recovered = false
  for _, elem in pairs( flight.elements ) do
    elem.recoverd = false
  end

  -- Set recovered for all section members.
  for _, sec in pairs( flight.section ) do
    -- Set flag and timestamp for section members
    sec.flag = -1
    sec.time = timer.getAbsTime()
    for _, elem in pairs( sec.elements ) do
      elem.recoverd = false
    end
  end
end

--- Sets flag recovered=true for a flight element, which was successfully recovered (landed).
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit The aircraft unit that was recovered.
-- @return #AIRBOSS.FlightGroup Flight group of element.
function AIRBOSS:_RecoveredElement( unit )

  -- Get element of flight.
  local element, idx, flight = self:_GetFlightElement( unit:GetName() ) -- #AIRBOSS.FlightElement

  -- Nil check. Could be if a helo landed or something else we dont know!
  if element then
    element.recovered = true
  end

  return flight
end

--- Remove a flight group from the Marshal queue. Marshal stack is collapsed, too, if flight was in the queue. Waiting flights are send to marshal.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight Flight group that will be removed from queue.
-- @param #boolean nopattern If true, flight is NOT going to landing pattern.
-- @return #boolean True, flight was removed or false otherwise.
-- @return #number Table index of the flight in the Marshal queue.
function AIRBOSS:_RemoveFlightFromMarshalQueue( flight, nopattern )

  -- Remove flight from marshal queue if it is in.
  local removed, idx = self:_RemoveFlightFromQueue( self.Qmarshal, flight )

  -- Collapse marshal stack if flight was removed.
  if removed then

    -- Flight is not holding any more.
    flight.holding = nil

    -- Collapse marshal stack if flight was removed.
    self:_CollapseMarshalStack( flight, nopattern )

    -- Stacks are only limited for Case I.
    if flight.case == 1 and #self.Qwaiting > 0 then

      -- Next flight in line waiting.
      local nextflight = self.Qwaiting[1] -- #AIRBOSS.FlightGroup

      -- Get free stack.
      local freestack = self:_GetFreeStack( nextflight.ai )

      -- Send next flight to marshal stack.
      if nextflight.ai then

        -- Send AI to Marshal Stack.
        self:_MarshalAI( nextflight, freestack )

      else

        -- Send player to Marshal stack.
        self:_MarshalPlayer( nextflight, freestack )

      end

      -- Remove flight from waiting queue.
      self:_RemoveFlightFromQueue( self.Qwaiting, nextflight )

    end
  end

  return removed, idx
end

--- Remove a flight group from a queue.
-- @param #AIRBOSS self
-- @param #table queue The queue from which the group will be removed.
-- @param #AIRBOSS.FlightGroup flight Flight group that will be removed from queue.
-- @return #boolean True, flight was in Queue and removed. False otherwise.
-- @return #number Table index of removed queue element or nil.
function AIRBOSS:_RemoveFlightFromQueue( queue, flight )

  -- Loop over all flights in group.
  for i, _flight in pairs( queue ) do
    local qflight = _flight -- #AIRBOSS.FlightGroup

    -- Check for name.
    if qflight.groupname == flight.groupname then
      self:T( self.lid .. string.format( "Removing flight group %s from queue.", flight.groupname ) )
      table.remove( queue, i )
      return true, i
    end
  end

  return false, nil
end

--- Remove a unit and its element from a flight group (e.g. when landed) and update all queues if the whole flight group is gone.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit The unit to be removed.
function AIRBOSS:_RemoveUnitFromFlight( unit )

  -- Check if unit exists.
  if unit and unit:IsInstanceOf( "UNIT" ) then

    -- Get group.
    local group = unit:GetGroup()

    -- Check if group exists.
    if group then

      -- Get flight.
      local flight = self:_GetFlightFromGroupInQueue( group, self.flights )

      -- Check if flight exists.
      if flight then

        -- Remove element from flight group.
        local removed = self:_RemoveFlightElement( unit:GetName() )

        if removed then

          -- Get number of units (excluding section members). For AI only those that are still in air as we assume once they landed, they are out of the game.
          local _, nunits = self:_GetFlightUnits( flight, not flight.ai )

          -- Number of flight elements still left.
          local nelements = #flight.elements

          -- Debug info.
          self:T( self.lid .. string.format( "Removed unit %s: nunits=%d, nelements=%d", unit:GetName(), nunits, nelements ) )

          -- Check if no units are left.
          if nunits == 0 or nelements == 0 then
            -- Remove flight from all queues.
            self:_RemoveFlight( flight )
          end

        end
      end
    end
  end

end

--- Remove a flight, which is a member of a section, from this section.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight The flight to be removed from the section
function AIRBOSS:_RemoveFlightFromSection( flight )

  -- First check if player is not the lead.
  if flight.name ~= flight.seclead then

    -- Remove this flight group from the section of the leader.
    local lead = self.players[flight.seclead] -- #AIRBOSS.FlightGroup
    if lead then
      for i, sec in pairs( lead.section ) do
        local sectionmember = sec -- #AIRBOSS.FlightGroup
        if sectionmember.name == flight.name then
          table.remove( lead.section, i )
          break
        end
      end
    end
  end

end

--- Update section if a flight is removed.
-- If removed flight is member of a section, he is removed for the leaders section.
-- If removed flight is the section lead, we try to find a new leader.
-- @param #AIRBOSS self
-- @param #AIRBOSS.FlightGroup flight The flight to be removed.
function AIRBOSS:_UpdateFlightSection( flight )

  -- Check if this player is the leader of a section.
  if flight.seclead == flight.name then

    --------------------
    -- Section Leader --
    --------------------

    -- This player is the leader ==> We need a new one.
    if #flight.section >= 1 then

      -- New leader.
      local newlead = flight.section[1] -- #AIRBOSS.FlightGroup
      newlead.seclead = newlead.name

      -- Adjust new section members.
      for i = 2, #flight.section do
        local member = flight.section[i] -- #AIRBOSS.FlightGroup

        -- Add remaining members new leaders table.
        table.insert( newlead.section, member )

        -- Set new section lead of member.
        member.seclead = newlead.name
      end

    end

    -- Flight section empty
    flight.section = {}

  else

    --------------------
    -- Section Member --
    --------------------

    -- Remove flight from its leaders section.
    self:_RemoveFlightFromSection( flight )

  end

end

--- Remove a flight from Marshal, Pattern and Waiting queues. If flight is in Marhal queue, the above stack is collapsed.
-- Also set player step to undefined if applicable or remove human flight if option *completely* is true.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData flight The flight to be removed.
-- @param #boolean completely If true, also remove human flight from all flights table.
function AIRBOSS:_RemoveFlight( flight, completely )
  self:F( self.lid .. string.format( "Removing flight %s, ai=%s completely=%s.", tostring( flight.groupname ), tostring( flight.ai ), tostring( completely ) ) )

  -- Remove flight from all queues.
  self:_RemoveFlightFromMarshalQueue( flight, true )
  self:_RemoveFlightFromQueue( self.Qpattern, flight )
  self:_RemoveFlightFromQueue( self.Qwaiting, flight )
  self:_RemoveFlightFromQueue( self.Qspinning, flight )

  -- Check if player or AI
  if flight.ai then

    -- Remove AI flight completely. Pure AI flights have no sections and cannot be members.
    self:_RemoveFlightFromQueue( self.flights, flight )

  else

    -- Remove all grades until a final grade is reached.
    local grades = self.playerscores[flight.name]
    if grades and #grades > 0 then
      while #grades > 0 and grades[#grades].finalscore == nil do
        table.remove( grades, #grades )
      end
    end

    -- Check if flight should be completely removed, e.g. after the player died or simply left the slot.
    if completely then

      -- Update flight section. Remove flight from section or find new section leader if flight was the lead.
      self:_UpdateFlightSection( flight )

      -- Remove completely.
      self:_RemoveFlightFromQueue( self.flights, flight )

      -- Remove player from players table.
      local playerdata = self.players[flight.name]
      if playerdata then
        self:I( self.lid .. string.format( "Removing player %s completely.", flight.name ) )
        self.players[flight.name] = nil
      end

      -- Remove flight.
      flight = nil

    else

      -- Set player step to undefined.
      self:_SetPlayerStep( flight, AIRBOSS.PatternStep.UNDEFINED )

      -- Also set this for the section members as they are in the same boat.
      for _, sectionmember in pairs( flight.section ) do
        self:_SetPlayerStep( sectionmember, AIRBOSS.PatternStep.UNDEFINED )
        -- Also remove section member in case they are in the spinning queue.
        self:_RemoveFlightFromQueue( self.Qspinning, sectionmember )
      end

      -- What if flight is member of a section. His status is now undefined. Should he be removed from the section?
      -- I think yes, if he pulls the trigger.
      self:_RemoveFlightFromSection( flight )

    end
  end

end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Status
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check current player status.
-- @param #AIRBOSS self
function AIRBOSS:_CheckPlayerStatus()

  -- Loop over all players.
  for _playerName, _playerData in pairs( self.players ) do
    local playerData = _playerData -- #AIRBOSS.PlayerData

    if playerData then

      -- Player unit.
      local unit = playerData.unit

      -- Check if unit is alive.
      if unit and unit:IsAlive() then

        -- Check if player is in carrier controlled area (zone with R=50 NM around the carrier).
        -- TODO: This might cause problems if the CCA is set to be very small!
        if unit:IsInZone( self.zoneCCA ) then

          -- Display aircraft attitude and other parameters as message text.
          if playerData.attitudemonitor then
            self:_AttitudeMonitor( playerData )
          end

          -- Check distance to other flights.
          self:_CheckPlayerPatternDistance( playerData )

          -- Foul deck check.
          self:_CheckFoulDeck( playerData )

          -- Check current step.
          if playerData.step == AIRBOSS.PatternStep.UNDEFINED then

            -- Status undefined.
            -- local time=timer.getAbsTime()
            -- local clock=UTILS.SecondsToClock(time)
            -- self:T3(string.format("Player status undefined. Waiting for next step. Time %s", clock))

          elseif playerData.step == AIRBOSS.PatternStep.REFUELING then

            -- Nothing to do here at the moment.

          elseif playerData.step == AIRBOSS.PatternStep.SPINNING then

            -- Player is spinning.
            self:_Spinning( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.HOLDING then

            -- CASE I/II/III: In holding pattern.
            self:_Holding( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.WAITING then

            -- CASE I: Waiting outside 10 NM zone for next free Marshal stack.
            self:_Waiting( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.COMMENCING then

            -- CASE I/II/III: New approach.
            self:_Commencing( playerData, true )

          elseif playerData.step == AIRBOSS.PatternStep.BOLTER then

            -- CASE I/II/III: Bolter pattern.
            self:_BolterPattern( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.PLATFORM then

            -- CASE II/III: Player has reached 5k "Platform".
            self:_Platform( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.ARCIN then

            -- Case II/III if offset.
            self:_ArcInTurn( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.ARCOUT then

            -- Case II/III if offset.
            self:_ArcOutTurn( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.DIRTYUP then

            -- CASE III: Player has descended to 1200 ft and is going level from now on.
            self:_DirtyUp( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.BULLSEYE then

            -- CASE III: Player has intercepted the glide slope and should follow "Bullseye" (ICLS).
            self:_Bullseye( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.INITIAL then

            -- CASE I/II: Player is at the initial position entering the landing pattern.
            self:_Initial( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.BREAKENTRY then

            -- CASE I/II: Break entry.
            self:_BreakEntry( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.EARLYBREAK then

            -- CASE I/II: Early break.
            self:_Break( playerData, AIRBOSS.PatternStep.EARLYBREAK )

          elseif playerData.step == AIRBOSS.PatternStep.LATEBREAK then

            -- CASE I/II: Late break.
            self:_Break( playerData, AIRBOSS.PatternStep.LATEBREAK )

          elseif playerData.step == AIRBOSS.PatternStep.ABEAM then

            -- CASE I/II: Abeam position.
            self:_Abeam( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.NINETY then

            -- CASE:I/II: Check long down wind leg.
            self:_CheckForLongDownwind( playerData )

            -- At the ninety.
            self:_Ninety( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.WAKE then

            -- CASE I/II: In the wake.
            self:_Wake( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.EMERGENCY then

            -- Emergency landing. Player pos is not checked.
            self:_Final( playerData, true )

          elseif playerData.step == AIRBOSS.PatternStep.FINAL then

            -- CASE I/II: Turn to final and enter the groove.
            self:_Final( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.GROOVE_XX or
                 playerData.step == AIRBOSS.PatternStep.GROOVE_IM or
                 playerData.step == AIRBOSS.PatternStep.GROOVE_IC or
                 playerData.step == AIRBOSS.PatternStep.GROOVE_AR or
                 playerData.step == AIRBOSS.PatternStep.GROOVE_AL or
                 playerData.step == AIRBOSS.PatternStep.GROOVE_LC or
                 playerData.step == AIRBOSS.PatternStep.GROOVE_IW then

            -- CASE I/II: In the groove.
            self:_Groove( playerData )

          elseif playerData.step == AIRBOSS.PatternStep.DEBRIEF then

            -- Debriefing in 5 seconds.
            -- SCHEDULER:New(nil, self._Debrief, {self, playerData}, 5)
            playerData.debriefschedulerID = self:ScheduleOnce( 5, self._Debrief, self, playerData )

            -- Undefined status.
            playerData.step = AIRBOSS.PatternStep.UNDEFINED

          else

            -- Error, unknown step!
            self:E( self.lid .. string.format( "ERROR: Unknown player step %s. Please report!", tostring( playerData.step ) ) )

          end

          -- Check if player missed a step during Case II/III and allow him to enter the landing pattern.
          self:_CheckMissedStepOnEntry( playerData )

        else
          self:T2( self.lid .. "WARNING: Player unit not inside the CCA!" )
        end

      else
        -- Unit not alive.
        self:T( self.lid .. "WARNING: Player unit is not alive!" )
      end
    end
  end

end

--- Checks if a player is in the pattern queue and has missed a step in Case II/III approach.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_CheckMissedStepOnEntry( playerData )

  -- Conditions to be met: Case II/III, in pattern queue, flag!=42 (will be set to 42 at the end if player missed a step).
  local rightcase = playerData.case > 1
  local rightqueue = self:_InQueue( self.Qpattern, playerData.group )
  local rightflag = playerData.flag ~= -42

  -- Steps that the player could have missed during Case II/III.
  local step = playerData.step
  local missedstep = step == AIRBOSS.PatternStep.PLATFORM or step == AIRBOSS.PatternStep.ARCIN or step == AIRBOSS.PatternStep.ARCOUT or step == AIRBOSS.PatternStep.DIRTYUP

  -- Check if player is about to enter the initial or bullseye zones and maybe has missed a step in the pattern.
  if rightcase and rightqueue and rightflag then

    -- Get right zone.
    local zone = nil
    if playerData.case == 2 and missedstep then

      zone = self:_GetZoneInitial( playerData.case )

    elseif playerData.case == 3 and missedstep then

      zone = self:_GetZoneBullseye( playerData.case )

    end

    -- Zone only exists if player is not at the initial or bullseye step.
    if zone then

      -- Check if player is in initial or bullseye zone.
      local inzone = playerData.unit:IsInZone( zone )

      -- Relative heading to carrier direction.
      local relheading = self:_GetRelativeHeading( playerData.unit, false )

      -- Check if player is in zone and flying roughly in the right direction.
      if inzone and math.abs( relheading ) < 60 then

        -- Player is in one of the initial zones short before the landing pattern.
        local text = string.format( "you missed an important step in the pattern!\nYour next step would have been %s.", playerData.step )
        self:MessageToPlayer( playerData, text, "AIRBOSS", nil, 5 )

        if playerData.case == 2 then
          -- Set next step to initial.
          playerData.step = AIRBOSS.PatternStep.INITIAL
        elseif playerData.case == 3 then
          -- Set next step to bullseye.
          playerData.step = AIRBOSS.PatternStep.BULLSEYE
        end

        -- Set flag value to -42. This is the value to ensure that this routine is not called again!
        playerData.flag = -42
      end
    end
  end
end

--- Set time in the groove for player.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_SetTimeInGroove( playerData )

  -- Set time in the groove
  if playerData.TIG0 then
    playerData.Tgroove = timer.getTime() - playerData.TIG0
  else
    playerData.Tgroove = 999
  end

end

--- Get time in the groove of player.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @return #number Player's time in groove in seconds.
function AIRBOSS:_GetTimeInGroove( playerData )

  local Tgroove = 999

  -- Get time in the groove.
  if playerData.TIG0 then
    Tgroove = timer.getTime() - playerData.TIG0
  end

  return Tgroove
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Airboss event handler for event birth.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventBirth( EventData )
  self:F3( { eventbirth = EventData } )
  
  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event BIRTH!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event BIRTH!" )
    self:E( EventData )
    return
  end
  
  if EventData.IniObjectCategory ~= Object.Category.UNIT then return end
  
  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T( self.lid .. "BIRTH: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T( self.lid .. "BIRTH: group  = " .. tostring( EventData.IniGroupName ) )
  self:T( self.lid .. "BIRTH: player = " .. tostring( _playername ) )

  if _unit and _playername then

    local _uid = _unit:GetID()
    local _group = _unit:GetGroup()
    local _callsign = _unit:GetCallsign()

    -- Debug output.
    local text = string.format( "Pilot %s, callsign %s entered unit %s of group %s.", _playername, _callsign, _unitName, _group:GetName() )
    self:T( self.lid .. text )
    MESSAGE:New( text, 5 ):ToAllIf( self.Debug )

    -- Check if aircraft type the player occupies is carrier capable.
    local rightaircraft = self:_IsCarrierAircraft( _unit )
    if rightaircraft == false then
      local text = string.format( "Player aircraft type %s not supported by AIRBOSS class.", _unit:GetTypeName() )
      MESSAGE:New( text, 30 ):ToAllIf( self.Debug )
      self:T2( self.lid .. text )
      return
    end

    -- Check that coalition of the carrier and aircraft match.
    if self:GetCoalition() ~= _unit:GetCoalition() then
      local text = string.format( "Player entered aircraft of other coalition." )
      MESSAGE:New( text, 30 ):ToAllIf( self.Debug )
      self:T( self.lid .. text )
      return
    end

    -- Add Menu commands.
    self:_AddF10Commands( _unitName )

    -- Delaying the new player for a second, because AI units of the flight would not be registered correctly.
    -- SCHEDULER:New(nil, self._NewPlayer, {self, _unitName}, 1)
    self:ScheduleOnce( 1, self._NewPlayer, self, _unitName )

  end
end

--- Airboss event handler for event land.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventLand( EventData )
  self:F3( { eventland = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event LAND!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event LAND!" )
    self:E( EventData )
    return
  end

  -- Get unit name that landed.
  local _unitName = EventData.IniUnitName

  -- Check if this was a player.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Debug output.
  self:T( self.lid .. "LAND: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T( self.lid .. "LAND: group  = " .. tostring( EventData.IniGroupName ) )
  self:T( self.lid .. "LAND: player = " .. tostring( _playername ) )

  -- This would be the closest airbase.
  local airbase = EventData.Place

  -- Nil check for airbase. Crashed as player gave me no airbase.
  if airbase == nil then
    return
  end

  -- Get airbase name.
  local airbasename = tostring( airbase:GetName() )

  -- Check if aircraft landed on the right airbase.
  if airbasename == self.airbase:GetName() then

    -- Stern coordinate at the rundown.
    local stern = self:_GetSternCoord()

    -- Polygon zone close around the carrier.
    local zoneCarrier = self:_GetZoneCarrierBox()

    -- Check if player or AI landed.
    if _unit and _playername then

      -------------------------
      -- Human Player landed --
      -------------------------

      -- Get info.
      local _uid = _unit:GetID()
      local _group = _unit:GetGroup()
      local _callsign = _unit:GetCallsign()

      -- Debug output.
      local text = string.format( "Player %s, callsign %s unit %s (ID=%d) of group %s landed at airbase %s", _playername, _callsign, _unitName, _uid, _group:GetName(), airbasename )
      self:T( self.lid .. text )
      MESSAGE:New( text, 5, "DEBUG" ):ToAllIf( self.Debug )

      -- Player data.
      local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

      -- Check if playerData is okay.
      if playerData == nil then
        self:E( self.lid .. string.format( "ERROR: playerData nil in landing event. unit=%s player=%s", tostring( _unitName ), tostring( _playername ) ) )
        return
      end

      -- Check that player landed on the carrier.
      if _unit:IsInZone( zoneCarrier ) then

        -- Check if this was a valid approach.
        if not playerData.valid then
          -- Player missed at least one step in the pattern.
          local text = string.format( "you missed at least one important step in the pattern!\nYour next step would have been %s.\nThis pass is INVALID.", playerData.step )
          self:MessageToPlayer( playerData, text, "AIRBOSS", nil, 30, true, 5 )

          -- Clear queues just in case.
          self:_RemoveFlightFromMarshalQueue( playerData, true )
          self:_RemoveFlightFromQueue( self.Qpattern, playerData )
          self:_RemoveFlightFromQueue( self.Qwaiting, playerData )
          self:_RemoveFlightFromQueue( self.Qspinning, playerData )

          -- Reinitialize player data.
          self:_InitPlayer( playerData )

          return
        end

        -- Check if player already landed. We dont need a second time.
        if playerData.landed then

          self:E( self.lid .. string.format( "Player %s just landed a second time.", _playername ) )

        else

          -- We did land.
          playerData.landed = true

          -- Switch attitude monitor off if on.
          playerData.attitudemonitor = false

          -- Coordinate at landing event.
          local coord = playerData.unit:GetCoordinate()

          -- Get distances relative to
          local X, Z, rho, phi = self:_GetDistances( _unit )

          -- Landing distance wrt to stern position.
          local dist = coord:Get2DDistance( stern )

          -- Debug mark of player landing coord.
          if self.Debug and false then
            -- Debug mark of player landing coord.
            local lp = coord:MarkToAll( "Landing coord." )
            coord:SmokeGreen()
          end

          -- Set time in the groove of player.
          self:_SetTimeInGroove( playerData )

          -- Debug text.
          local text = string.format( "Player %s AC type %s landed at dist=%.1f m. Tgroove=%.1f sec.", playerData.name, playerData.actype, dist, self:_GetTimeInGroove( playerData ) )
          text = text .. string.format( " X=%.1f m, Z=%.1f m, rho=%.1f m.", X, Z, rho )
          self:T( self.lid .. text )

          -- Check carrier type.
          if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then

            -- Power "Idle".
            self:RadioTransmission( self.LSORadio, self.LSOCall.IDLE, false, 1, nil, true )

            -- Next step debrief.
            self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.DEBRIEF )

          else

            -- Next step undefined until we know more.
            self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.UNDEFINED )

            -- Call trapped function in 1 second to make sure we did not bolter.
            -- SCHEDULER:New(nil, self._Trapped, {self, playerData}, 1)
            self:ScheduleOnce( 1, self._Trapped, self, playerData )

          end

        end

      else
        -- Handle case where player did not land on the carrier.
        -- Well, I guess, he leaves the slot or ejects. Both should be handled.
        if playerData then
          self:E( self.lid .. string.format( "Player %s did not land in carrier box zone. Maybe in the water near the carrier?", playerData.name ) )
        end
      end

    else

      --------------------
      -- AI unit landed --
      --------------------

      if self.carriertype ~= AIRBOSS.CarrierType.INVINCIBLE or self.carriertype ~= AIRBOSS.CarrierType.HERMES or self.carriertype ~= AIRBOSS.CarrierType.TARAWA or self.carriertype ~= AIRBOSS.CarrierType.AMERICA or self.carriertype ~= AIRBOSS.CarrierType.JCARLOS or self.carriertype ~= AIRBOSS.CarrierType.CANBERRA then

        -- Coordinate at landing event
        local coord = EventData.IniUnit:GetCoordinate()

        -- Debug mark of player landing coord.
        local dist = coord:Get2DDistance( self:GetCoordinate() )

        -- Get wire
        local wire = self:_GetWire( coord, 0 )

        -- Aircraft type.
        local _type = EventData.IniUnit:GetTypeName()

        -- Debug text.
        local text = string.format( "AI unit %s of type %s landed at dist=%.1f m. Trapped wire=%d.", _unitName, _type, dist, wire )
        self:T( self.lid .. text )

      end

      -- AI always lands ==> remove unit from flight group and queues.
      local flight = self:_RecoveredElement( EventData.IniUnit )

      -- Check if all were recovered. If so update pattern queue.
      self:_CheckSectionRecovered( flight )

    end
  end
end

--- Airboss event handler for event that a unit shuts down its engines.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventEngineShutdown( EventData )
  self:F3( { eventengineshutdown = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event ENGINESHUTDOWN!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event ENGINESHUTDOWN!" )
    self:E( EventData )
    return
  end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T3( self.lid .. "ENGINESHUTDOWN: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "ENGINESHUTDOWN: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "ENGINESHUTDOWN: player = " .. tostring( _playername ) )

  if _unit and _playername then

    -- Debug message.
    self:T( self.lid .. string.format( "Player %s shut down its engines!", _playername ) )

  else

    -- Debug message.
    self:T( self.lid .. string.format( "AI unit %s shut down its engines!", _unitName ) )

    -- Get flight.
    local flight = self:_GetFlightFromGroupInQueue( EventData.IniGroup, self.flights )

    -- Only AI flights.
    if flight and flight.ai then

      -- Check if all elements were recovered.
      local recovered = self:_CheckSectionRecovered( flight )

      -- Despawn group and completely remove flight.
      if recovered then
        self:T( self.lid .. string.format( "AI group %s completely recovered. Despawning group after engine shutdown event as requested in 5 seconds.", tostring( EventData.IniGroupName ) ) )

        -- Remove flight.
        self:_RemoveFlight( flight )

        -- Check if this is a tanker or AWACS associated with the carrier.
        local istanker = self.tanker and self.tanker.tanker:GetName() == EventData.IniGroupName
        local isawacs = self.awacs and self.awacs.tanker:GetName() == EventData.IniGroupName

        -- Destroy group if desired. Recovery tankers have their own logic for despawning.
        if self.despawnshutdown and not (istanker or isawacs) then
          EventData.IniGroup:Destroy( nil, 5 )
        end

      end

    end
  end
end

--- Airboss event handler for event that a unit takes off.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventTakeoff( EventData )
  self:F3( { eventtakeoff = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event TAKEOFF!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event TAKEOFF!" )
    self:E( EventData )
    return
  end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T3( self.lid .. "TAKEOFF: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "TAKEOFF: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "TAKEOFF: player = " .. tostring( _playername ) )

  -- Airbase.
  local airbase = EventData.Place

  -- Airbase name.
  local airbasename = "unknown"
  if airbase then
    airbasename = airbase:GetName()
  end

  -- Check right airbase.
  if airbasename == self.airbase:GetName() then

    if _unit and _playername then

      -- Debug message.
      self:T( self.lid .. string.format( "Player %s took off at %s!", _playername, airbasename ) )

    else

      -- Debug message.
      self:T2( self.lid .. string.format( "AI unit %s took off at %s!", _unitName, airbasename ) )

      -- Get flight.
      local flight = self:_GetFlightFromGroupInQueue( EventData.IniGroup, self.flights )

      if flight then

        -- Set ballcall and recoverd status.
        for _, elem in pairs( flight.elements ) do
          local element = elem -- #AIRBOSS.FlightElement
          element.ballcall = false
          element.recovered = nil
        end
      end
    end

  end
end

--- Airboss event handler for event crash.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventCrash( EventData )
  self:F3( { eventcrash = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event CRASH!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event CRASH!" )
    self:E( EventData )
    return
  end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T3( self.lid .. "CRASH: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "CRASH: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "CARSH: player = " .. tostring( _playername ) )

  if _unit and _playername then
    -- Debug message.
    self:T( self.lid .. string.format( "Player %s crashed!", _playername ) )

    -- Get player flight.
    local flight = self.players[_playername]

    -- Remove flight completely from all queues and collapse marshal if necessary.
    -- This also updates the section, if any and removes any unfinished gradings of the player.
    if flight then
      self:_RemoveFlight( flight, true )
    end

  else
    -- Debug message.
    self:T2( self.lid .. string.format( "AI unit %s crashed!", EventData.IniUnitName ) )

    -- Remove unit from flight and queues.
    self:_RemoveUnitFromFlight( EventData.IniUnit )
  end

end

--- Airboss event handler for event Ejection.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventEjection( EventData )
  self:F3( { eventland = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event EJECTION!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event EJECTION!" )
    self:E( EventData )
    return
  end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T3( self.lid .. "EJECT: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "EJECT: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "EJECT: player = " .. tostring( _playername ) )

  if _unit and _playername then
    self:T( self.lid .. string.format( "Player %s ejected!", _playername ) )

    -- Get player flight.
    local flight = self.players[_playername]

    -- Remove flight completely from all queues and collapse marshal if necessary.
    if flight then
      self:_RemoveFlight( flight, true )
    end

  else
    -- Debug message.
    self:T( self.lid .. string.format( "AI unit %s ejected!", EventData.IniUnitName ) )

    -- Remove element/unit from flight group and from all queues if no elements alive.
    self:_RemoveUnitFromFlight( EventData.IniUnit )

    -- What could happen is, that another element has landed (recovered) already and this one crashes.
    -- This would mean that the flight would not be deleted from the queue ==> Check if section recovered.
    local flight = self:_GetFlightFromGroupInQueue( EventData.IniGroup, self.flights )
    self:_CheckSectionRecovered( flight )
  end

end

--- Airboss event handler for event REMOVEUNIT.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
function AIRBOSS:OnEventRemoveUnit( EventData )
  self:F3( { eventland = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event REMOVEUNIT!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event REMOVEUNIT!" )
    self:E( EventData )
    return
  end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T3( self.lid .. "EJECT: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "EJECT: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "EJECT: player = " .. tostring( _playername ) )

  if _unit and _playername then
    self:T( self.lid .. string.format( "Player %s removed!", _playername ) )

    -- Get player flight.
    local flight = self.players[_playername]

    -- Remove flight completely from all queues and collapse marshal if necessary.
    if flight then
      self:_RemoveFlight( flight, true )
    end

  else
    -- Debug message.
    self:T( self.lid .. string.format( "AI unit %s removed!", EventData.IniUnitName ) )

    -- Remove element/unit from flight group and from all queues if no elements alive.
    self:_RemoveUnitFromFlight( EventData.IniUnit )

    -- What could happen is, that another element has landed (recovered) already and this one crashes.
    -- This would mean that the flight would not be deleted from the queue ==> Check if section recovered.
    local flight = self:_GetFlightFromGroupInQueue( EventData.IniGroup, self.flights )
    self:_CheckSectionRecovered( flight )
  end

end

--- Airboss event handler for event player leave unit.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData
-- function AIRBOSS:OnEventPlayerLeaveUnit(EventData)
function AIRBOSS:_PlayerLeft( EventData )
  self:F3( { eventleave = EventData } )

  -- Nil checks.
  if EventData == nil then
    self:E( self.lid .. "ERROR: EventData=nil in event PLAYERLEFTUNIT!" )
    self:E( EventData )
    return
  end
  if EventData.IniUnit == nil then
    self:E( self.lid .. "ERROR: EventData.IniUnit=nil in event PLAYERLEFTUNIT!" )
    self:E( EventData )
    return
  end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  self:T3( self.lid .. "PLAYERLEAVEUNIT: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "PLAYERLEAVEUNIT: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "PLAYERLEAVEUNIT: player = " .. tostring( _playername ) )

  if _unit and _playername then

    -- Debug info.
    self:T( self.lid .. string.format( "Player %s left unit %s!", _playername, _unitName ) )

    -- Get player flight.
    local flight = self.players[_playername]

    -- Remove flight completely from all queues and collapse marshal if necessary.
    if flight then
      self:_RemoveFlight( flight, true )
    end

  end

end

--- Airboss event function handling the mission end event.
-- Handles the case when the mission is ended.
-- @param #AIRBOSS self
-- @param Core.Event#EVENTDATA EventData Event data.
function AIRBOSS:OnEventMissionEnd( EventData )
  self:T3( self.lid .. "Mission Ended" )
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PATTERN functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Spinning
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Spinning( playerData )

  -- Early break.
  local SpinIt = {}
  SpinIt.name = "Spinning"
  SpinIt.Xmin = -UTILS.NMToMeters( 6 ) -- Not more than 5 NM behind the boat.
  SpinIt.Xmax = UTILS.NMToMeters( 5 ) -- Not more than 5 NM in front of the boat.
  SpinIt.Zmin = -UTILS.NMToMeters( 6 ) -- Not more than 5 NM port.
  SpinIt.Zmax = UTILS.NMToMeters( 2 ) -- Not more than 3 NM starboard.
  SpinIt.LimitXmin = -100 -- 100 meters behind the boat
  SpinIt.LimitXmax = nil
  SpinIt.LimitZmin = -UTILS.NMToMeters( 1 ) -- 1 NM port
  SpinIt.LimitZmax = nil

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances( playerData.unit )

  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits( X, Z, SpinIt ) then

    -- Player is "de-spinned". Should go to initial again.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.INITIAL )

    -- Remove player from spinning queue.
    self:_RemoveFlightFromQueue( self.Qspinning, playerData )

  end

end

--- Waiting outside 10 NM zone for free Marshal stack.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Waiting( playerData )

  -- Create 10 NM zone around the carrier.
  local radius = UTILS.NMToMeters( 10 )
  local zone = ZONE_RADIUS:New( "Carrier 10 NM Zone", self.carrier:GetVec2(), radius )

  -- Check if player is inside 10 NM radius of the carrier.
  local inzone = playerData.unit:IsInZone( zone )

  -- Time player is waiting.
  local Twaiting = timer.getAbsTime() - playerData.time

  -- Warning if player is inside the zone.
  if inzone and Twaiting > 3 * 60 and not playerData.warning then
    local text = string.format( "You are supposed to wait outside the 10 NM zone." )
    self:MessageToPlayer( playerData, text, "AIRBOSS" )
    playerData.warning = true
  end

  -- Reset warning.
  if inzone == false and playerData.warning == true then
    playerData.warning = nil
  end

end

--- Holding.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Holding( playerData )

  -- Player unit and flight.
  local unit = playerData.unit

  -- Current stack.
  local stack = playerData.flag

  -- Check for reported error.
  if stack <= 0 then
    local text = string.format( "ERROR: player %s in step %s is holding but has stack=%s (<=0)", playerData.name, playerData.step, tostring( stack ) )
    self:E( self.lid .. text )
  end

  ---------------------------
  -- Holding Pattern Check --
  ---------------------------

  -- Pattern altitude.
  local patternalt = self:_GetMarshalAltitude( stack, playerData.case )

  -- Player altitude.
  local playeralt = unit:GetAltitude()

  -- Get holding zone of player.
  local zoneHolding = self:_GetZoneHolding( playerData.case, stack )

  -- Nil check.
  if zoneHolding == nil then
    self:E( self.lid .. "ERROR: zoneHolding is nil!" )
    self:E( { playerData = playerData } )
    return
  end

  -- Check if player is in holding zone.
  local inholdingzone = unit:IsInZone( zoneHolding )

  -- Altitude difference between player and assigned stack.
  local altdiff = playeralt - patternalt

  -- Acceptable altitude depending on player skill.
  local altgood = UTILS.FeetToMeters( 500 )
  if playerData.difficulty == AIRBOSS.Difficulty.HARD then
    -- Pros can be expected to be within +-200 ft.
    altgood = UTILS.FeetToMeters( 200 )
  elseif playerData.difficulty == AIRBOSS.Difficulty.NORMAL then
    -- Normal guys should be within +-350 ft.
    altgood = UTILS.FeetToMeters( 350 )
  elseif playerData.difficulty == AIRBOSS.Difficulty.EASY then
    -- Students should be within +-500 ft.
    altgood = UTILS.FeetToMeters( 500 )
  end

  -- When back to good altitude = 50%.
  local altback = altgood * 0.5

  -- Check if stack just collapsed and give the player one minute to change the altitude.
  local justcollapsed = false
  if self.Tcollapse then
    -- Time since last stack change.
    local dT = timer.getTime() - self.Tcollapse

    -- TODO: check if this works.
    -- local dT=timer.getAbsTime()-playerData.time

    -- Check if less then 90 seconds.
    if dT <= 90 then
      justcollapsed = true
    end
  end

  -- Check if altitude is acceptable.
  local goodalt = math.abs( altdiff ) < altgood

  -- Angels.
  local angels = self:_GetAngels( patternalt )

  -- XXX: Check if player is flying counter clockwise. AOB<0.

  -- Message text.
  local text = ""

  -- Different cases
  if playerData.holding == true then
    -- Player was in holding zone last time we checked.

    if inholdingzone then
      -- Player is still in holding zone.
      self:T3( "Player is still in the holding zone. Good job." )
    else
      -- Player left the holding zone.
      text = text .. string.format( "You just left the holding zone. Watch your numbers!" )
      playerData.holding = false
    end

    -- Altitude check if stack not just collapsed.
    if not justcollapsed then

      if altdiff > altgood then

        -- Issue warning for being too high.
        if not playerData.warning then
          text = text .. string.format( "You left your assigned altitude. Descent to angels %d.", angels )
          playerData.warning = true
        end

      elseif altdiff < -altgood then

        -- Issue warning for being too low.
        if not playerData.warning then
          text = text .. string.format( "You left your assigned altitude. Climb to angels %d.", angels )
          playerData.warning = true
        end

      end

    end

    -- Back to assigned altitude.
    if playerData.warning and math.abs( altdiff ) <= altback then
      text = text .. string.format( "Altitude is looking good again." )
      playerData.warning = nil
    end

  elseif playerData.holding == false then

    -- Player left holding zone
    if inholdingzone then
      -- Player is back in the holding zone.
      text = text .. string.format( "You are back in the holding zone. Now stay there!" )
      playerData.holding = true
    else
      -- Player is still outside the holding zone.
      self:T3( "Player still outside the holding zone. What are you doing man?!" )
    end

  elseif playerData.holding == nil then
    -- Player did not entered the holding zone yet.

    if inholdingzone then

      -- Player arrived in holding zone.
      playerData.holding = true

      -- Inform player.
      text = text .. string.format( "You arrived at the holding zone." )

      -- Feedback on altitude.
      if goodalt then
        text = text .. string.format( " Altitude is good." )
      else
        if altdiff < 0 then
          text = text .. string.format( " But you're too low." )
        else
          text = text .. string.format( " But you're too high." )
        end
        text = text .. string.format( "\nCurrently assigned altitude is %d ft.", UTILS.MetersToFeet( patternalt ) )
        playerData.warning = true
      end

    else
      -- Player did not yet arrive in holding zone.
      self:T3( "Waiting for player to arrive in the holding zone." )
    end

  end

  -- Send message.
  if playerData.showhints then
    self:MessageToPlayer( playerData, text, "MARSHAL" )
  end

end

--- Commence approach. This step initializes the player data. Section members are also set to commence. Next step depends on recovery case:
--
-- * Case 1: Initial
-- * Case 2/3: Platform
--
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #boolean zonecheck If true, zone is checked before player is released.
function AIRBOSS:_Commencing( playerData, zonecheck )

  -- Check for auto commence
  if zonecheck then

    -- Get auto commence zone.
    local zoneCommence = self:_GetZoneCommence( playerData.case, playerData.flag )

    -- Check if unit is in the zone.
    local inzone = playerData.unit:IsInZone( zoneCommence )

    -- Skip the rest if not in the zone yet.
    if not inzone then

      -- Friendly reminder.
      if timer.getAbsTime() - playerData.time > 180 then
        self:_MarshalCallClearedForRecovery( playerData.onboard, playerData.case )
        playerData.time = timer.getAbsTime()
      end

      -- Skip the rest.
      return
    end

  end

  -- Remove flight from Marshal queue. If flight was in queue, stack is collapsed and flight added to the pattern queue.
  self:_RemoveFlightFromMarshalQueue( playerData )

  -- Initialize player data for new approach.
  self:_InitPlayer( playerData )

  -- Commencing message to player only.
  if playerData.difficulty ~= AIRBOSS.Difficulty.HARD then

    -- Text
    local text = ""

    -- Positive response.
    if playerData.case == 1 then
      text = text .. "Proceed to initial."
    else
      text = text .. "Descent to platform."
      if playerData.difficulty == AIRBOSS.Difficulty.EASY and playerData.showhints then
        text = text .. " VSI 4000 ft/min until you reach 5000 ft."
      end
    end

    -- Message to player.
    self:MessageToPlayer( playerData, text, "MARSHAL" )
  end

  -- Next step: depends on case recovery.
  local nextstep
  if playerData.case == 1 then
    -- CASE I: Player has to fly to the initial which is 3 NM DME astern of the boat.
    nextstep = AIRBOSS.PatternStep.INITIAL
  else
    -- CASE II/III: Player has to start the descent at 4000 ft/min to the platform at 5k ft.
    nextstep = AIRBOSS.PatternStep.PLATFORM
  end

  -- Next step hint.
  self:_SetPlayerStep( playerData, nextstep )

  -- Commence section members as well but dont check the zone.
  for i, _flight in pairs( playerData.section ) do
    local flight = _flight -- #AIRBOSS.PlayerData
    self:_Commencing( flight, false )
  end

end

--- Start pattern when player enters the initial zone in case I/II recoveries.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #boolean True if player is in the initial zone.
function AIRBOSS:_Initial( playerData )

  -- Check if player is in initial zone and entering the CASE I pattern.
  local inzone = playerData.unit:IsInZone( self:_GetZoneInitial( playerData.case ) )

  -- Relative heading to carrier direction.
  local relheading = self:_GetRelativeHeading( playerData.unit, false )

  -- altitude of player in feet.
  local altitude = playerData.unit:GetAltitude()

  -- Check if player is in zone and flying roughly in the right direction.
  if inzone and math.abs( relheading ) < 60 and altitude <= self.initialmaxalt then

    -- Send message for normal and easy difficulty.
    if playerData.showhints then

      -- Inform player.
      local hint = string.format( "Initial" )

      -- Hook down for students.
      if playerData.difficulty == AIRBOSS.Difficulty.EASY and playerData.actype ~= AIRBOSS.AircraftCarrier.AV8B then
        if playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B then
          hint = hint .. " - Hook down, SAS on, Wing Sweep 68°!"
        else
          hint = hint .. " - Hook down!"
        end
      end

      self:MessageToPlayer( playerData, hint, "MARSHAL" )
    end

    -- Next step: Break entry.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.BREAKENTRY )

    return true
  end

  return false
end

--- Check if player is in CASE II/III approach corridor.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_CheckCorridor( playerData )

  -- Check if player is in valid zone
  local validzone = self:_GetZoneCorridor( playerData.case )

  -- Check if we are inside the moving zone.
  local invalid = playerData.unit:IsNotInZone( validzone )

  -- Issue warning.
  if invalid and (not playerData.warning) then
    self:MessageToPlayer( playerData, "you left the approach corridor!", "AIRBOSS" )
    playerData.warning = true
  end

  -- Back in zone.
  if (not invalid) and playerData.warning then
    self:MessageToPlayer( playerData, "you're back in the approach corridor.", "AIRBOSS" )
    playerData.warning = false
  end

end

--- Platform at 5k ft for case II/III recoveries. Descent at 2000 ft/min.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Platform( playerData )

  -- Check if player left or got back to the approach corridor.
  self:_CheckCorridor( playerData )

  -- Check if we are inside the moving zone.
  local inzone = playerData.unit:IsInZone( self:_GetZonePlatform( playerData.case ) )

  -- Check if we are in zone.
  if inzone then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step: depends.
    local nextstep
    if math.abs( self.holdingoffset ) > 0 and playerData.case > 1 then
      -- Turn to BRC (case II) or FB (case III).
      nextstep = AIRBOSS.PatternStep.ARCIN
    else
      if playerData.case == 2 then
        -- Case II: Initial zone then Case I recovery.
        nextstep = AIRBOSS.PatternStep.INITIAL
      elseif playerData.case == 3 then
        -- CASE III: Dirty up.
        nextstep = AIRBOSS.PatternStep.DIRTYUP
      end
    end

    -- Next step hint.
    self:_SetPlayerStep( playerData, nextstep )

  end
end

--- Arc in turn for case II/III recoveries.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_ArcInTurn( playerData )

  -- Check if player left or got back to the approach corridor.
  self:_CheckCorridor( playerData )

  -- Check if we are inside the moving zone.
  local inzone = playerData.unit:IsInZone( self:_GetZoneArcIn( playerData.case ) )

  if inzone then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step: Arc Out Turn.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.ARCOUT )

  end
end

--- Arc out turn for case II/III recoveries.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_ArcOutTurn( playerData )

  -- Check if player left or got back to the approach corridor.
  self:_CheckCorridor( playerData )

  -- Check if we are inside the moving zone.
  local inzone = playerData.unit:IsInZone( self:_GetZoneArcOut( playerData.case ) )

  if inzone then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step:
    local nextstep
    if playerData.case == 3 then
      -- Case III: Dirty up.
      nextstep = AIRBOSS.PatternStep.DIRTYUP
    else
      -- Case II: Initial.
      nextstep = AIRBOSS.PatternStep.INITIAL
    end

    -- Next step hint.
    self:_SetPlayerStep( playerData, nextstep )
  end
end

--- Dirty up and level out at 1200 ft for case III recovery.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_DirtyUp( playerData )

  -- Check if player left or got back to the approach corridor.
  self:_CheckCorridor( playerData )

  -- Check if we are inside the moving zone.
  local inzone = playerData.unit:IsInZone( self:_GetZoneDirtyUp( playerData.case ) )

  if inzone then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Radio call "Say/Fly needles". Delayed by 10/15 seconds.
    if   playerData.actype == AIRBOSS.AircraftCarrier.HORNET 
      or playerData.actype == AIRBOSS.AircraftCarrier.F14A 
      or playerData.actype == AIRBOSS.AircraftCarrier.F14B 
      or playerData.actype == AIRBOSS.AircraftCarrier.RHINOE
      or playerData.actype == AIRBOSS.AircraftCarrier.RHINOF
      or playerData.actype == AIRBOSS.AircraftCarrier.GROWLER
    then
      local callsay = self:_NewRadioCall( self.MarshalCall.SAYNEEDLES, nil, nil, 5, playerData.onboard )
      local callfly = self:_NewRadioCall( self.MarshalCall.FLYNEEDLES, nil, nil, 5, playerData.onboard )
      self:RadioTransmission( self.MarshalRadio, callsay, false, 55, nil, true )
      self:RadioTransmission( self.MarshalRadio, callfly, false, 60, nil, true )
    end

    -- TODO: Make Fly Bullseye call if no automatic ICLS is active.

    -- Next step: CASE III: Intercept glide slope and follow bullseye (ICLS).
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.BULLSEYE )

  end
end

--- Intercept glide slop and follow ICLS, aka Bullseye for case III recovery.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #boolean If true, player is in bullseye zone.
function AIRBOSS:_Bullseye( playerData )

  -- Check if player left or got back to the approach corridor.
  self:_CheckCorridor( playerData )

  -- Check if we are inside the moving zone.
  local inzone = playerData.unit:IsInZone( self:_GetZoneBullseye( playerData.case ) )

  -- Relative heading to carrier direction of the runway.
  local relheading = self:_GetRelativeHeading( playerData.unit, true )

  -- Check if player is in zone and flying roughly in the right direction.
  if inzone and math.abs( relheading ) < 60 then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- LSO expect spot 5 or 7.5 call
    if playerData.actype == AIRBOSS.AircraftCarrier.AV8B and self.carriertype == AIRBOSS.CarrierType.JCARLOS then
      self:RadioTransmission( self.LSORadio, self.LSOCall.EXPECTSPOT5, nil, nil, nil, true )
    elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B and self.carriertype == AIRBOSS.CarrierType.CANBERRA then
      self:RadioTransmission( self.LSORadio, self.LSOCall.EXPECTSPOT5, nil, nil, nil, true )
    elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
      self:RadioTransmission( self.LSORadio, self.LSOCall.EXPECTSPOT75, nil, nil, nil, true )
    end

    -- Next step: Groove Call the ball.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_XX )

  end
end

--- Bolter pattern. Sends player to abeam for Case I/II or Bullseye for Case III ops.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_BolterPattern( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances( playerData.unit )

  -- Bolter Pattern thresholds.
  local Bolter = {}
  Bolter.name = "Bolter Pattern"
  Bolter.Xmin = -UTILS.NMToMeters( 5 ) -- Not more then 5 NM astern of boat.
  Bolter.Xmax = UTILS.NMToMeters( 3 ) -- Not more then 3 NM ahead of boat.
  Bolter.Zmin = -UTILS.NMToMeters( 5 ) -- Not more than 2 NM port.
  Bolter.Zmax = UTILS.NMToMeters( 1 ) -- Not more than 1 NM starboard.
  Bolter.LimitXmin = 100 -- Check that 100 meter ahead and port
  Bolter.LimitXmax = nil
  Bolter.LimitZmin = nil
  Bolter.LimitZmax = nil

  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits( X, Z, Bolter ) then
    local nextstep
    if playerData.case < 3 then
      nextstep = AIRBOSS.PatternStep.ABEAM
    else
      nextstep = AIRBOSS.PatternStep.BULLSEYE
    end
    self:_SetPlayerStep( playerData, nextstep )
  end
end

--- Break entry for case I/II recoveries.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_BreakEntry( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances( playerData.unit )

  -- Abort condition check.
  if self:_CheckAbort( X, Z, self.BreakEntry ) then
    self:_AbortPattern( playerData, X, Z, self.BreakEntry, true )
    return
  end

  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits( X, Z, self.BreakEntry ) then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step: Early Break.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.EARLYBREAK )

  end
end

--- Break.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #string part Part of the break.
function AIRBOSS:_Break( playerData, part )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances( playerData.unit )

  -- Early or late break.
  local breakpoint = self.BreakEarly
  if part == AIRBOSS.PatternStep.LATEBREAK then
    breakpoint = self.BreakLate
  end

  -- Check abort conditions.
  if self:_CheckAbort( X, Z, breakpoint ) then
    self:_AbortPattern( playerData, X, Z, breakpoint, true )
    return
  end

  -- Player made a very tight turn and did not trigger the latebreak threshold at 0.8 NM.
  local tooclose = false
  if part == AIRBOSS.PatternStep.LATEBREAK then
    local close = 0.8
    if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
      close = 0.5
    end
    if X < 0 and Z < UTILS.NMToMeters( close ) then
      if playerData.difficulty == AIRBOSS.Difficulty.EASY and playerData.showhints then
        self:MessageToPlayer( playerData, "your turn was too tight! Allow for more distance to the boat next time.", "LSO" )
      end
      tooclose = true
    end
  end

  -- Check limits.
  if self:_CheckLimits( X, Z, breakpoint ) or tooclose then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step: Late Break or Abeam.
    local nextstep
    if part == AIRBOSS.PatternStep.EARLYBREAK then
      nextstep = AIRBOSS.PatternStep.LATEBREAK
    else
      nextstep = AIRBOSS.PatternStep.ABEAM
    end

    self:_SetPlayerStep( playerData, nextstep )
  end
end

--- Long downwind leg check.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_CheckForLongDownwind( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances( playerData.unit )

  -- 1.6 NM from carrier is too far.
  local limit = UTILS.NMToMeters( -1.6 )

  -- For the tarawa, other LHA and LHD we give a bit more space.
  if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
    limit = UTILS.NMToMeters( -2.0 )
  end

  -- Check we are not too far out w.r.t back of the boat.
  if X < limit then -- and relhead<45 then

    -- Sound output.
    self:RadioTransmission( self.LSORadio, self.LSOCall.LONGINGROOVE )
    self:RadioTransmission( self.LSORadio, self.LSOCall.DEPARTANDREENTER, nil, nil, nil, true )

    -- Debrief.
    self:_AddToDebrief( playerData, "Long in the groove - Pattern Waveoff!" )

    -- grade="LIG PATTERN WAVE OFF - CUT 1 PT"
    playerData.lig = true
    playerData.wop = true

    -- Next step: Debriefing.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.DEBRIEF )

  end

end

--- Abeam position.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Abeam( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances( playerData.unit )

  -- Check abort conditions.
  if self:_CheckAbort( X, Z, self.Abeam ) then
    self:_AbortPattern( playerData, X, Z, self.Abeam, true )
    return
  end

  -- Check nest step threshold.
  if self:_CheckLimits( X, Z, self.Abeam ) then

    -- Paddles contact.
    self:RadioTransmission( self.LSORadio, self.LSOCall.PADDLESCONTACT, nil, nil, nil, true )

    -- LSO expect spot 5 or 7.5 call
    if playerData.actype == AIRBOSS.AircraftCarrier.AV8B and self.carriertype == AIRBOSS.CarrierType.JCARLOS then
      self:RadioTransmission( self.LSORadio, self.LSOCall.EXPECTSPOT5, false, 5, nil, true )
    elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B and self.carriertype == AIRBOSS.CarrierType.CANBERRA then
      self:RadioTransmission( self.LSORadio, self.LSOCall.EXPECTSPOT5, false, 5, nil, true )
    elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
      self:RadioTransmission( self.LSORadio, self.LSOCall.EXPECTSPOT75, false, 5, nil, true )
    end

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData, 3 )

    -- Next step: ninety.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.NINETY )

  end
end

--- At the Ninety.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Ninety( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances( playerData.unit )

  -- Check abort conditions.
  if self:_CheckAbort( X, Z, self.Ninety ) then
    self:_AbortPattern( playerData, X, Z, self.Ninety, true )
    return
  end

  -- Get Realtive heading player to carrier.
  local relheading = self:_GetRelativeHeading( playerData.unit, false )

  -- At the 90, i.e. 90 degrees between player heading and BRC of carrier.
  if relheading <= 90 then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step: wake.
    if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
      -- Harrier has no wake stop. It stays port of the boat.
      self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.FINAL )
    else
      self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.WAKE )
    end

  elseif relheading > 90 and self:_CheckLimits( X, Z, self.Wake ) then
    -- Message to player.
    self:MessageToPlayer( playerData, "you are already at the wake and have not passed the 90. Turn faster next time!", "LSO" )
    self:RadioTransmission( self.LSORadio, self.LSOCall.DEPARTANDREENTER, nil, nil, nil, true )
    playerData.wop = true
    -- Debrief.
    self:_AddToDebrief( playerData, "Overshoot at wake - Pattern Waveoff!" )
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.DEBRIEF )
  end
end

--- At the Wake.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Wake( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z = self:_GetDistances( playerData.unit )

  -- Check abort conditions.
  if self:_CheckAbort( X, Z, self.Wake ) then
    self:_AbortPattern( playerData, X, Z, self.Wake, true )
    return
  end

  -- Right behind the wake of the carrier dZ>0.
  if self:_CheckLimits( X, Z, self.Wake ) then

    -- Hint for player about altitude, AoA etc.
    self:_PlayerHint( playerData )

    -- Next step: Final.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.FINAL )

  end
end

--- Get groove data.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #AIRBOSS.GrooveData Groove data table.
function AIRBOSS:_GetGrooveData( playerData )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier).
  local X, Z = self:_GetDistances( playerData.unit )

  -- Stern position at the rundown.
  local stern = self:_GetSternCoord()

  -- Distance from rundown to player aircraft.
  local rho = stern:Get2DDistance( playerData.unit:GetCoordinate() )

  -- Aircraft is behind the carrier.
  local astern = X < self.carrierparam.sterndist

  -- Correct sign. Negative if passed rundown.
  if astern == false then
    rho = -rho
  end

  -- Velocity vector.
  local vel = playerData.unit:GetVelocityVec3()

  -- Grade, points, details
  local Gg, Gp, Gd = self:_LSOgrade( playerData )

  -- Gather pilot data.
  local groovedata = {} -- #AIRBOSS.GrooveData
  groovedata.Step = playerData.step
  groovedata.Time = timer.getTime()
  groovedata.Rho = rho
  groovedata.X = X
  groovedata.Z = Z
  groovedata.Alt = self:_GetAltCarrier( playerData.unit )
  groovedata.AoA = playerData.unit:GetAoA()
  groovedata.GSE = self:_Glideslope( playerData.unit )
  groovedata.LUE = self:_Lineup( playerData.unit, true )
  groovedata.Roll = playerData.unit:GetRoll()
  groovedata.Pitch = playerData.unit:GetPitch()
  groovedata.Yaw = playerData.unit:GetYaw()
  groovedata.Vel = UTILS.VecNorm( vel )
  groovedata.Vy = vel.y
  groovedata.Gamma = self:_GetRelativeHeading( playerData.unit, true )
  groovedata.Grade = Gg
  groovedata.GradePoints = Gp
  groovedata.GradeDetail = Gd

  -- env.info(string.format(", %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f", groovedata.Time, groovedata.Rho, groovedata.X, groovedata.Alt, groovedata.GSE, groovedata.LUE, groovedata.AoA))

  return groovedata
end

--- Turn to final.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #boolean nocheck If true, player is not checked to be in the right position.
function AIRBOSS:_Final( playerData, nocheck )

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local X, Z, rho, phi = self:_GetDistances( playerData.unit )

  -- In front of carrier or more than 4 km behind carrier.
  if not nocheck then
    if self:_CheckAbort( X, Z, self.Final ) then
      self:_AbortPattern( playerData, X, Z, self.Final, true )
      return
    end
  end

  -- Get Groove data
  local groovedata = self:_GetGrooveData( playerData )

  -- Trap sheet data.
  table.insert( playerData.trapsheet, groovedata )

  -- Get groove zone.
  local zone = self:_GetZoneGroove()

  -- Check if player is in zone.
  local inzone = playerData.unit:IsInZone( zone )

  -- Check.
  if inzone then -- and math.abs(groovedata.Roll)<5 then

    -- Hint for player about altitude, AoA etc. Sound is off.
    self:_PlayerHint( playerData, nil, true )

    -- Init FlyThrough.
    groovedata.FlyThrough = nil

    -- TODO: could add angled approach if lineup<5 and relhead>5. This would mean the player has not turned in correctly!

    -- Groove data.
    playerData.groove.X0 = UTILS.DeepCopy( groovedata )

    -- Set time stamp. Next call in 4 seconds.
    playerData.Tlso = timer.getTime()

    -- Next step: X start.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_XX )
  end

  -- Groovedata step.
  groovedata.Step = playerData.step

end

--- In the groove.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Groove( playerData )

  -- Ranges in the groove.
  local RX0 = UTILS.NMToMeters( 1.000 ) -- Everything before X    1.00  = 1852 m
  local RXX = UTILS.NMToMeters( 0.750 ) -- Start of groove.       0.75  = 1389 m
  local RIM = UTILS.NMToMeters( 0.500 ) -- In the Middle          0.50  =  926 m (middle one third of the glideslope)
  local RIC = UTILS.NMToMeters( 0.250 ) -- In Close               0.25  =  463 m (last one third of the glideslope)
  local RAR = UTILS.NMToMeters( 0.040 ) -- At the Ramp.           0.04  =   75 m

  -- Groove data.
  local groovedata = self:_GetGrooveData( playerData )

  -- Add data to trapsheet.
  table.insert( playerData.trapsheet, groovedata )

  -- Coords.
  local X = groovedata.X
  local Z = groovedata.Z

  -- Check abort conditions.
  if self:_CheckAbort( groovedata.X, groovedata.Z, self.Groove ) then
    self:_AbortPattern( playerData, groovedata.X, groovedata.Z, self.Groove, true )
    return
  end

  -- Shortcuts.
  local rho = groovedata.Rho
  local lineupError = groovedata.LUE
  local glideslopeError = groovedata.GSE
  local AoA = groovedata.AoA

  if rho <= RXX and playerData.step == AIRBOSS.PatternStep.GROOVE_XX and (math.abs( groovedata.Roll ) <= 4.0 or playerData.unit:IsInZone( self:_GetZoneLineup() )) then

    -- Start time in groove
    playerData.TIG0 = timer.getTime()

    -- LSO "Call the ball" call.
    self:RadioTransmission( self.LSORadio, self.LSOCall.CALLTHEBALL, nil, nil, nil, true )
    playerData.Tlso = timer.getTime()

    -- Pilot "405, Hornet Ball, 3.2".

    -- LSO "Roger ball" call in three seconds.
    self:RadioTransmission( self.LSORadio, self.LSOCall.ROGERBALL, false, nil, 2, true )

    -- Store data.
    playerData.groove.XX = UTILS.DeepCopy( groovedata )

    -- This is a valid approach and player did not miss any important steps in the pattern.
    playerData.valid = true

    -- Next step: in the middle.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_IM )

  elseif rho <= RIM and playerData.step == AIRBOSS.PatternStep.GROOVE_IM then

    -- Store data.
    playerData.groove.IM = UTILS.DeepCopy( groovedata )

    -- Next step: in close.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_IC )

  elseif rho <= RIC and playerData.step == AIRBOSS.PatternStep.GROOVE_IC then

    -- Store data.
    playerData.groove.IC = UTILS.DeepCopy( groovedata )

    -- Next step: AR at the ramp.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_AR )

  elseif rho <= RAR and playerData.step == AIRBOSS.PatternStep.GROOVE_AR then

    -- Store data.
    playerData.groove.AR = UTILS.DeepCopy( groovedata )

    -- Next step: in the wires.
    if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
      self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_AL )
    else
      self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_IW )
    end

  elseif rho <= RAR and playerData.step == AIRBOSS.PatternStep.GROOVE_AL then

    -- Store data.
    playerData.groove.AL = UTILS.DeepCopy( groovedata )

    -- Get zone abeam LDG spot.
    local ZoneALS = self:_GetZoneAbeamLandingSpot()

    -- Get player velocity in km/h.
    local vplayer = playerData.unit:GetVelocityKMH()

    -- Get carrier velocity in km/h.
    local vcarrier = self.carrier:GetVelocityKMH()

    -- Speed difference.
    local dv = math.abs( vplayer - vcarrier )


    -- Stable when speed difference < 30 km/h.(16 Kts)Pene Testing
    local stable=dv<30

    -- Check if player is inside the zone.
    if playerData.unit:IsInZone( ZoneALS ) and stable then

      -- Radio Transmission "Cleared to land" once the aircraft is inside the zone.
      self:RadioTransmission( self.LSORadio, self.LSOCall.CLEAREDTOLAND, nil, nil, nil, true )

      -- Next step: Level cross.
      self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.GROOVE_LC )
      -- Set Stable Hover
      playerData.stable = true
      playerData.hover = true
    end

  elseif rho <= RAR and playerData.step == AIRBOSS.PatternStep.GROOVE_LC then

    -- Store data.
    playerData.groove.LC = UTILS.DeepCopy( groovedata )

    -- Get zone primary LDG spot.
    local ZoneLS = self:_GetZoneLandingSpot()

    -- Get player velocity in km/h.
    local vplayer = playerData.unit:GetVelocityKMH()

    -- Get carrier velocity in km/h.
    local vcarrier = self.carrier:GetVelocityKMH()

    -- Speed difference.
    local dv = math.abs( vplayer - vcarrier )

    -- Stable when v<15 km/h.
    local stable=dv<15

    -- Radio Transmission "Stabilized" once the aircraft has been cleared to cross and is over the Landing Spot and stable.
    if playerData.unit:IsInZone( ZoneLS ) and stable and playerData.stable == true then
      self:RadioTransmission( self.LSORadio, self.LSOCall.STABILIZED, nil, nil, nil, false )
      playerData.stable = false
      playerData.warning = true
    end

    -- We keep it in this step until landed.

  end

  --------------
  -- Wave Off --
  --------------

  -- Between IC and AR check for wave off.
  if rho >= RAR and rho <= RIC and not playerData.waveoff then

    -- Check if player should wave off.
    local waveoff = self:_CheckWaveOff( glideslopeError, lineupError, AoA, playerData )

    -- Let's see..
    if waveoff then

      -- Debug info.
      self:T3( self.lid .. string.format( "Waveoff distance rho=%.1f m", rho ) )

      -- LSO Wave off!
      self:RadioTransmission( self.LSORadio, self.LSOCall.WAVEOFF, nil, nil, nil, true )
      playerData.Tlso = timer.getTime()

      -- Player was waved off!
      playerData.waveoff = true

      -- Nothing else necessary.
      return
    end

   end   
    
    -- Long V/STOL groove time Wave Off over 75 seconds to IC - TOPGUN level Only. --pene testing (WIP)--- Need to think more about this.
   
  --if rho>=RAR and rho<=RIC and not playerData.waveoff and playerData.difficulty==AIRBOSS.Difficulty.HARD and  playerData.actype==      AIRBOSS.AircraftCarrier.AV8B then
   -- Get groove time
   --local vSlow=groovedata.time
   -- If too slow wave off.  
   --if vSlow >75 then
  
   -- LSO Wave off!
     --self:RadioTransmission(self.LSORadio, self.LSOCall.WAVEOFF, nil, nil, nil, true)
     --playerData.Tlso=timer.getTime()
   
   -- Player was waved Off
     --playerData.waveoff=true
     --return
  --end    
 --end

  -- Groovedata step.
  groovedata.Step = playerData.step

  -----------------
  -- Groove Data --
  -----------------

  -- Check if we are beween 3/4 NM and end of ship.
  if rho >= RAR and rho < RX0 and playerData.waveoff == false then

    -- Get groove step short hand of the previous step.
    local gs = self:_GS( playerData.step, -1 )

    -- Get current groove data.
    local gd = playerData.groove[gs] -- #AIRBOSS.GrooveData

    if gd then
      self:T3( gd )

      -- Distance in NM.
      local d = UTILS.MetersToNM( rho )

      -- Drift on lineup.
      if rho >= RAR and rho <= RIM then
        if gd.LUE > 0.22 and lineupError < -0.22 then
          env.info " Drift Right across centre ==> DR-"
          gd.Drift = " DR"
          self:T( self.lid .. string.format( "Got Drift Right across centre step %s, d=%.3f: Max LUE=%.3f, lower LUE=%.3f", gs, d, gd.LUE, lineupError ) )
        elseif gd.LUE < -0.22 and lineupError > 0.22 then
          env.info " Drift Left ==> DL-"
          gd.Drift = " DL"
          self:T( self.lid .. string.format( "Got Drift Left across centre at step %s, d=%.3f: Min LUE=%.3f, lower LUE=%.3f", gs, d, gd.LUE, lineupError ) )
        elseif gd.LUE > 0.13 and lineupError < -0.14 then
          env.info " Little Drift Right across centre ==> (DR-)"
          gd.Drift = " (DR)"
          self:T( self.lid .. string.format( "Got Little Drift Right across centre at step %s, d=%.3f: Max LUE=%.3f, lower LUE=%.3f", gs, d, gd.LUE, lineupError ) )
        elseif gd.LUE < -0.13 and lineupError > 0.14 then
          env.info " Little Drift Left across centre ==> (DL-)"
          gd.Drift = " (DL)"
          self:E( self.lid .. string.format( "Got Little Drift Left across centre at step %s, d=%.3f: Min LUE=%.3f, lower LUE=%.3f", gs, d, gd.LUE, lineupError ) )
        end
      end

      -- Update max deviation of line up error.
      if math.abs( lineupError ) > math.abs( gd.LUE ) then
        self:T( self.lid .. string.format( "Got bigger LUE at step %s, d=%.3f: LUE %.3f>%.3f", gs, d, lineupError, gd.LUE ) )
        gd.LUE = lineupError
      end

      -- Fly through good window of glideslope.
      if gd.GSE > 0.4 and glideslopeError < -0.3 then
        -- Fly through down ==> "\"
        gd.FlyThrough = "\\"
        self:T( self.lid .. string.format( "Got Fly through DOWN at step %s, d=%.3f: Max GSE=%.3f, lower GSE=%.3f", gs, d, gd.GSE, glideslopeError ) )
      elseif gd.GSE < -0.3 and glideslopeError > 0.4 then
        -- Fly through up ==> "/"
        gd.FlyThrough = "/"
        self:E( self.lid .. string.format( "Got Fly through UP at step %s, d=%.3f: Min GSE=%.3f, lower GSE=%.3f", gs, d, gd.GSE, glideslopeError ) )
      end

      -- Update max deviation of glideslope error.
      if math.abs( glideslopeError ) > math.abs( gd.GSE ) then
        self:T( self.lid .. string.format( "Got bigger GSE at step %s, d=%.3f: GSE |%.3f|>|%.3f|", gs, d, glideslopeError, gd.GSE ) )
        gd.GSE = glideslopeError
      end

      -- Get aircraft AoA parameters.
      local aircraftaoa = self:_GetAircraftAoA( playerData )

      -- On Speed AoA.
      local aoaopt = aircraftaoa.OnSpeed

      -- Compare AoAs wrt on speed AoA and update max deviation.
      if math.abs( AoA - aoaopt ) > math.abs( gd.AoA - aoaopt ) then
        self:T( self.lid .. string.format( "Got bigger AoA error at step %s, d=%.3f: AoA %.3f>%.3f.", gs, d, AoA, gd.AoA ) )
        gd.AoA = AoA
      end

      -- local gs2=self:_GS(groovedata.Step, -1)
      -- env.info(string.format("groovestep %s %s d=%.3f NM: GSE=%.3f %.3f, LUE=%.3f %.3f, AoA=%.3f %.3f", gs, gs2, d, groovedata.GSE, gd.GSE, groovedata.LUE, gd.LUE, groovedata.AoA, gd.AoA))

    end

    ---------------
    -- LSO Calls --
    ---------------

    -- Time since last LSO call.
    local deltaT = timer.getTime() - playerData.Tlso

    -- Wait until player passed the 0.75 NM distance.
    local _advice = true
    if playerData.TIG0 == nil and playerData.difficulty ~= AIRBOSS.Difficulty.EASY then -- rho>RXX
      _advice = false
    end

    -- LSO call if necessary.
    if deltaT >= self.LSOdT and _advice then
      self:_LSOadvice( playerData, glideslopeError, lineupError )
    end

  end

  ----------------------------------------------------------
  --- Some time here the landing event MIGHT be triggered --
  ----------------------------------------------------------

  -- Player infront of the carrier X>~77 m.
  if X > self.carrierparam.totlength + self.carrierparam.sterndist then

    if playerData.waveoff then

      if playerData.landed then
        -- This should not happen because landing event was triggered.
        self:_AddToDebrief( playerData, "You were waved off but landed anyway. Airboss wants to talk to you!" )
      else
        self:_AddToDebrief( playerData, "You were waved off." )
      end

    elseif playerData.boltered then

      -- This should not happen because landing event was triggered.
      self:_AddToDebrief( playerData, "You boltered." )

    else

      -- This should not happen.
      self:T( "Player was not waved off but flew past the carrier without landing ==> Own wave off!" )

      -- We count this as OWO.
      self:_AddToDebrief( playerData, "Own waveoff." )

      -- Set Owo
      playerData.owo = true

    end

    -- Next step: debrief.
    self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.DEBRIEF )

  end

end

--- LSO check if player needs to wave off.
-- Wave off conditions are:
--
-- * Glideslope error <1.2 or >1.8 degrees.
-- * |Line up error| > 3 degrees.
-- * AoA check but only for TOPGUN graduates.
-- @param #AIRBOSS self
-- @param #number glideslopeError Glideslope error in degrees.
-- @param #number lineupError Line up error in degrees.
-- @param #number AoA Angle of attack of player aircraft.
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @return #boolean If true, player should wave off!
function AIRBOSS:_CheckWaveOff( glideslopeError, lineupError, AoA, playerData )

  -- Assume we're all good.
  local waveoff = false

  -- Parameters
  local glMax = 1.8
  local glMin = -1.2
  local luAbs = 3.0

  -- For the harrier, we allow a bit more room.
  if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
    glMax = 2.6
    glMin = -2.2 -- Testing, @Engines may be just dragging it in on Hermes, or the carrier parameters need adjusting.
    luAbs = 4.1 -- Testing Pene.

  end

  -- Too high or too low?
  if glideslopeError > glMax then
    local text = string.format( "\n- Waveoff due to glideslope error %.2f > %.1f degrees!", glideslopeError, glMax )
    self:T( self.lid .. string.format( "%s: %s", playerData.name, text ) )
    self:_AddToDebrief( playerData, text )
    waveoff = true
  elseif glideslopeError < glMin then
    local text = string.format( "\n- Waveoff due to glideslope error %.2f < %.1f degrees!", glideslopeError, glMin )
    self:T( self.lid .. string.format( "%s: %s", playerData.name, text ) )
    self:_AddToDebrief( playerData, text )
    waveoff = true
  end

  -- Too far from centerline?
  if math.abs( lineupError ) > luAbs then
    local text = string.format( "\n- Waveoff due to line up error |%.1f| > %.1f degrees!", lineupError, luAbs )
    self:T( self.lid .. string.format( "%s: %s", playerData.name, text ) )
    self:_AddToDebrief( playerData, text )
    waveoff = true
  end

  -- Too slow or too fast? Only for pros.  

  if playerData.difficulty == AIRBOSS.Difficulty.HARD and playerData.actype ~= AIRBOSS.AircraftCarrier.AV8B then
    -- Get aircraft specific AoA values. Not for AV-8B due to transition to Stable Hover.
    local aoaac = self:_GetAircraftAoA( playerData )
    -- Check too slow or too fast.
    if AoA < aoaac.FAST then
      local text = string.format( "\n- Waveoff due to AoA %.1f < %.1f!", AoA, aoaac.FAST )
      self:T( self.lid .. string.format( "%s: %s", playerData.name, text ) )
      self:_AddToDebrief( playerData, text )
      waveoff = true
    elseif AoA > aoaac.SLOW then
      local text = string.format( "\n- Waveoff due to AoA %.1f > %.1f!", AoA, aoaac.SLOW )
      self:T( self.lid .. string.format( "%s: %s", playerData.name, text ) )
      self:_AddToDebrief( playerData, text )
      waveoff = true

    end
  end

  return waveoff
end

--- Check if other aircraft are currently on the landing runway.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @return boolean If true, we have a foul deck.
function AIRBOSS:_CheckFoulDeck( playerData )

  -- Assume no check necessary.
  local check = false

  -- CVN: Check at IM and IC.
  if playerData.step == AIRBOSS.PatternStep.GROOVE_IM or playerData.step == AIRBOSS.PatternStep.GROOVE_IC then
    check = true
  end

  -- AV-8B check until
  if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
    if playerData.step == AIRBOSS.PatternStep.GROOVE_AR or playerData.step == AIRBOSS.PatternStep.GROOVE_AL then
      check = true
    end
  end

  -- Check if player was already waved off. Should not be necessary as player step is set to debrief afterwards!
  if playerData.wofd == true or check == false then
    -- Player was already waved off.
    return
  end

  -- Landing runway zone.
  local runway = self:_GetZoneRunwayBox()

  -- For AB-8B we just check the primary landing spot.
  if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
    runway = self:_GetZoneLandingSpot()
  end

  -- Scan radius.
  local R = 250

  -- Debug info.
  self:T( self.lid .. string.format( "Foul deck check: Scanning Carrier Runway Area. Radius=%.1f m.", R ) )

  -- Scan units in carrier zone.
  local _, _, _, unitscan = self:GetCoordinate():ScanObjects( R, true, false, false )

  -- Loop over all scanned units and check if they are on the runway.
  local fouldeck = false
  local foulunit = nil -- Wrapper.Unit#UNIT
  for _, _unit in pairs( unitscan ) do
    local unit = _unit -- Wrapper.Unit#UNIT

    -- Check if unit is in zone.
    local inzone = unit:IsInZone( runway )

    -- Check if aircraft and in air.
    local isaircraft = unit:IsAir()
    local isairborn = unit:InAir()

    if inzone and isaircraft and not isairborn then
      local text = string.format( "Unit %s on landing runway ==> Foul deck!", unit:GetName() )
      self:T( self.lid .. text )
      MESSAGE:New( text, 10 ):ToAllIf( self.Debug )
      if self.Debug then
        runway:FlareZone( FLARECOLOR.Red, 30 )
      end
      fouldeck = true
      foulunit = unit
    end
  end

  -- Add to debrief and
  if playerData and fouldeck then

    -- Debrief text.
    local text = string.format( "Foul deck waveoff due to aircraft %s!", foulunit:GetName() )
    self:T( self.lid .. string.format( "%s: %s", playerData.name, text ) )
    self:_AddToDebrief( playerData, text )

    -- Foul deck + wave off radio message.
    self:RadioTransmission( self.LSORadio, self.LSOCall.FOULDECK, false, 1 )
    self:RadioTransmission( self.LSORadio, self.LSOCall.WAVEOFF, false, 1.2, nil, true )

    -- Player hint for flight students.
    if playerData.showhints then
      local text = string.format( "overfly landing area and enter bolter pattern." )
      self:MessageToPlayer( playerData, text, "LSO", nil, nil, false, 3 )
    end

    -- Set player parameters for foul deck.
    playerData.wofd = true

    -- Debrief.
    playerData.step = AIRBOSS.PatternStep.DEBRIEF
    playerData.warning = nil

    -- Pass would be invalid if the player lands.
    playerData.valid = false

    -- Send a message to the player that blocks the runway.
    if foulunit then
      local foulflight = self:_GetFlightFromGroupInQueue( foulunit:GetGroup(), self.flights )
      if foulflight and not foulflight.ai then
        self:MessageToPlayer( foulflight, "move your ass from my runway. NOW!", "AIRBOSS" )
      end
    end
  end

  return fouldeck
end

--- Get "stern" coordinate.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Coordinate at the rundown of the carrier.
function AIRBOSS:_GetSternCoord()

  -- Heading of carrier (true).
  local hdg = self.carrier:GetHeading()

  -- Final bearing (true).
  local FB=self:GetFinalBearing()
  local case=self.case

  -- Stern coordinate (sterndist<0). Also translate 10 meters starboard wrt Final bearing.
  self.sterncoord:UpdateFromCoordinate( self:GetCoordinate() )
  -- local stern=self:GetCoordinate()

  -- Stern coordinate (sterndist<0). --Pene testing Case III
  if self.carriertype==AIRBOSS.CarrierType.INVINCIBLE or self.carriertype==AIRBOSS.CarrierType.HERMES or self.carriertype==AIRBOSS.CarrierType.TARAWA or self.carriertype==AIRBOSS.CarrierType.AMERICA or self.carriertype==AIRBOSS.CarrierType.JCARLOS or self.carriertype==AIRBOSS.CarrierType.CANBERRA then
    if case==3 then
    -- CASE III V/STOL translation Due over deck approach if needed.
    self.sterncoord:Translate(self.carrierparam.sterndist, hdg, true, true):Translate(8, FB-90, true, true)
    elseif case==2 or case==1 then
    -- V/Stol: Translate 8 meters port.
    self.sterncoord:Translate(self.carrierparam.sterndist, hdg, true, true):Translate(8, FB-90, true, true)
  end
  elseif self.carriertype==AIRBOSS.CarrierType.STENNIS then
    -- Stennis: translate 7 meters starboard wrt Final bearing.
    self.sterncoord:Translate( self.carrierparam.sterndist, hdg, true, true ):Translate( 7, FB + 90, true, true )
  elseif self.carriertype == AIRBOSS.CarrierType.FORRESTAL then
    -- Forrestal
    self.sterncoord:Translate( self.carrierparam.sterndist, hdg, true, true ):Translate( 7.5, FB + 90, true, true )
  else
    -- Nimitz SC: translate 8 meters starboard wrt Final bearing.
    self.sterncoord:Translate( self.carrierparam.sterndist, hdg, true, true ):Translate( 9.5, FB + 90, true, true )
  end

  -- Set altitude.
  self.sterncoord:SetAltitude( self.carrierparam.deckheight )

  return self.sterncoord
end

--- Get wire from draw argument.
-- @param #AIRBOSS self
-- @param Core.Point#COORDINATE Lcoord Landing position.
-- @return #number Trapped wire (1-4) or 99 if no wire was trapped.
function AIRBOSS:_GetWireFromDrawArg()

  local wireArgs={}
  wireArgs[1]=141
  wireArgs[2]=142
  wireArgs[3]=143
  wireArgs[4]=144

  for wire,drawArg in pairs(wireArgs) do
    local value=self.carrier:GetDrawArgumentValue(drawArg)
    if math.abs(value)>0.001 then
      return wire
    end
  end

  return 99
end

--- Get wire from landing position.
-- @param #AIRBOSS self
-- @param Core.Point#COORDINATE Lcoord Landing position.
-- @param #number dc Distance correction. Shift the landing coord back if dc>0 and forward if dc<0.
-- @return #number Trapped wire (1-4) or 99 if no wire was trapped.
function AIRBOSS:_GetWire( Lcoord, dc )

  -- Final bearing (true).
  local FB = self:GetFinalBearing()

  -- Stern coordinate (sterndist<0). Also translate 10 meters starboard wrt Final bearing.
  local Scoord = self:_GetSternCoord()

  -- Distance to landing coord.
  local Ldist = Lcoord:Get2DDistance( Scoord )

  -- For human (not AI) the lading event is delayed unfortunately. Therefore, we need another correction factor.
  dc = dc or 65

  -- Corrected landing distance wrt to stern. Landing distance needs to be reduced due to delayed landing event for human players.
  local d = Ldist - dc

  -- Multiplayer wire correction.
  if self.mpWireCorrection then
    d = d - self.mpWireCorrection
  end

  -- Shift wires from stern to their correct position.
  local w1 = self.carrierparam.wire1
  local w2 = self.carrierparam.wire2
  local w3 = self.carrierparam.wire3
  local w4 = self.carrierparam.wire4

  -- Which wire was caught?
  local wire
  if d < w1 then -- 46
    wire = 1
  elseif d < w2 then -- 46+12
    wire = 2
  elseif d < w3 then -- 46+24
    wire = 3
  elseif d < w4 then -- 46+35
    wire = 4
  else
    wire = 99
  end

  if self.Debug and false then

    -- Wire position coordinates.
    local wp1 = Scoord:Translate( w1, FB )
    local wp2 = Scoord:Translate( w2, FB )
    local wp3 = Scoord:Translate( w3, FB )
    local wp4 = Scoord:Translate( w4, FB )

    -- Debug marks.
    wp1:MarkToAll( "Wire 1" )
    wp2:MarkToAll( "Wire 2" )
    wp3:MarkToAll( "Wire 3" )
    wp4:MarkToAll( "Wire 4" )

    -- Mark stern.
    Scoord:MarkToAll( "Stern" )

    -- Mark at landing position.
    Lcoord:MarkToAll( string.format( "Landing Point wire=%s", wire ) )

    -- Smoke landing position.
    Lcoord:SmokeGreen()

    -- Corrected landing position.
    local Dcoord = Lcoord:Translate( -dc, FB )

    -- Smoke corrected landing pos red.
    Dcoord:SmokeRed()

  end

  -- Debug output.
  self:T( string.format( "GetWire: L=%.1f, L-dc=%.1f ==> wire=%d (dc=%.1f)", Ldist, Ldist - dc, wire, dc ) )

  return wire
end

--- Trapped? Check if in air or not after landing event.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
function AIRBOSS:_Trapped( playerData )

  if playerData.unit:InAir() == false then
    -- Seems we have successfully landed.

    -- Lets see if we can get a good wire.
    local unit = playerData.unit

    -- Coordinate of player aircraft.
    local coord = unit:GetCoordinate()

    -- Get velocity in km/h. We need to substrackt the carrier velocity.
    local v = unit:GetVelocityKMH() - self.carrier:GetVelocityKMH()

    -- Stern coordinate.
    local stern = self:_GetSternCoord()

    -- Distance to stern pos.
    local s = stern:Get2DDistance( coord )

    -- Get current wire (estimate). This now based on the position where the player comes to a standstill which should reflect the trapped wire better.
    local dcorr = 100
    if   playerData.actype == AIRBOSS.AircraftCarrier.HORNET 
      or playerData.actype == AIRBOSS.AircraftCarrier.RHINOE
      or playerData.actype == AIRBOSS.AircraftCarrier.RHINOF
      or playerData.actype == AIRBOSS.AircraftCarrier.GROWLER then
      dcorr = 100
    elseif playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B then
      -- TODO: Check Tomcat.
      dcorr = 100
    elseif playerData.actype == AIRBOSS.AircraftCarrier.A4EC then
      -- A-4E gets slowed down much faster the the F/A-18C!
      dcorr = 56
    elseif playerData.actype == AIRBOSS.AircraftCarrier.T45C then
      -- T-45 also gets slowed down much faster the the F/A-18C.
      dcorr = 56
    end

    -- Get wire.
    local wire = self:_GetWire( coord, dcorr )

    -- Debug.
    local text = string.format( "Player %s _Trapped: v=%.1f km/h, s-dcorr=%.1f m ==> wire=%d (dcorr=%d)", playerData.name, v, s - dcorr, wire, dcorr )
    self:T( self.lid .. text )

    -- Call this function again until v < threshold. Player comes to a standstill ==> Get wire!
    if v > 5 then

      -- Check if we passed all wires.
      if wire > 4 and v > 10 and not playerData.warning then
        -- Looks like we missed the wires ==> Bolter!
        self:RadioTransmission( self.LSORadio, self.LSOCall.BOLTER, nil, nil, nil, true )
        playerData.warning = true
      end

      -- Call function again and check if converged or back in air.
      -- SCHEDULER:New(nil, self._Trapped, {self, playerData}, 0.1)
      self:ScheduleOnce( 0.1, self._Trapped, self, playerData )
      return
    end

    ----------------------------------------
    --- Form this point on we have converged
    ----------------------------------------

    -- Put some smoke and a mark.
    if self.Debug then
      coord:SmokeBlue()
      coord:MarkToAll( text )
      stern:MarkToAll( "Stern" )
    end

    -- Set player wire.
    playerData.wire = wire

    -- Message to player.
    local text = string.format( "Trapped %d-wire.", wire )
    if wire == 3 then
      text = text .. " Well done!"
    elseif wire == 2 then
      text = text .. " Not bad, maybe you even get the 3rd next time."
    elseif wire == 4 then
      text = text .. " That was scary. You can do better than this!"
    elseif wire == 1 then
      text = text .. " Try harder next time!"
    end

    -- Message to player.
    self:MessageToPlayer( playerData, text, "LSO", "" )

    -- Debrief.
    local hint = string.format( "Trapped %d-wire.", wire )
    self:_AddToDebrief( playerData, hint, "Groove: IW" )

  else

    -- Again in air ==> Boltered!
    local text = string.format( "Player %s boltered in trapped function.", playerData.name )
    self:T( self.lid .. text )
    MESSAGE:New( text, 5, "DEBUG" ):ToAllIf( self.debug )

    -- Bolter switch on.
    playerData.boltered = true

  end

  -- Next step: debriefing.
  playerData.step = AIRBOSS.PatternStep.DEBRIEF
  playerData.warning = nil
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ZONE functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get Initial zone for Case I or II.
-- @param #AIRBOSS self
-- @param #number case Recovery Case.
-- @return Core.Zone#ZONE_POLYGON_BASE Initial zone.
function AIRBOSS:_GetZoneInitial( case )

  self.zoneInitial = self.zoneInitial or ZONE_POLYGON_BASE:New( "Zone CASE I/II Initial" )

  -- Get radial, i.e. inverse of BRC.
  local radial = self:GetRadial( 2, false, false )

  -- Carrier coordinate.
  local cv = self:GetCoordinate()

  -- Vec2 array.
  local vec2 = {}

  if case == 1 then
    -- Case I

    local c1 = cv:Translate( UTILS.NMToMeters( 0.5 ), radial - 90 ) --  0.0  0.5 starboard
    local c2 = cv:Translate( UTILS.NMToMeters( 1.3 ), radial - 90 ):Translate( UTILS.NMToMeters( 3 ), radial ) -- -3.0  1.3 starboard, astern
    local c3 = cv:Translate( UTILS.NMToMeters( 0.4 ), radial + 90 ):Translate( UTILS.NMToMeters( 3 ), radial ) -- -3.0 -0.4 port, astern
    local c4 = cv:Translate( UTILS.NMToMeters( 1.0 ), radial )
    local c5 = cv

    -- Vec2 array.
    vec2 = { c1:GetVec2(), c2:GetVec2(), c3:GetVec2(), c4:GetVec2(), c5:GetVec2() }

  else
    -- Case II

    -- Funnel.
    local c1 = cv:Translate( UTILS.NMToMeters( 0.5 ), radial - 90 ) -- 0.0, 0.5
    local c2 = c1:Translate( UTILS.NMToMeters( 0.5 ), radial ) -- 0.5, 0.5
    local c3 = cv:Translate( UTILS.NMToMeters( 1.2 ), radial - 90 ):Translate( UTILS.NMToMeters( 3 ), radial ) -- 3.0, 1.2
    local c4 = cv:Translate( UTILS.NMToMeters( 1.2 ), radial + 90 ):Translate( UTILS.NMToMeters( 3 ), radial ) -- 3.0,-1.2
    local c5 = cv:Translate( UTILS.NMToMeters( 0.5 ), radial )
    local c6 = cv

    -- Vec2 array.
    vec2 = { c1:GetVec2(), c2:GetVec2(), c3:GetVec2(), c4:GetVec2(), c5:GetVec2(), c6:GetVec2() }

  end

  -- Polygon zone.
  -- local zone=ZONE_POLYGON_BASE:New("Zone CASE I/II Initial", vec2)

  self.zoneInitial:UpdateFromVec2( vec2 )

  -- return zone
  return self.zoneInitial
end

--- Get lineup groove zone.
-- @param #AIRBOSS self
-- @return Core.Zone#ZONE_POLYGON_BASE Lineup zone.
function AIRBOSS:_GetZoneLineup()

  self.zoneLineup = self.zoneLineup or ZONE_POLYGON_BASE:New( "Zone Lineup" )

  -- Get radial, i.e. inverse of BRC.
  local fbi = self:GetRadial( 1, false, false )

  -- Stern coordinate.
  local st = self:_GetOptLandingCoordinate()

  -- Zone points.
  local c1 = st
  local c2 = st:Translate( UTILS.NMToMeters( 0.50 ), fbi + 15 )
  local c3 = st:Translate( UTILS.NMToMeters( 0.50 ), fbi + self.lue._max - 0.05 )
  local c4 = st:Translate( UTILS.NMToMeters( 0.77 ), fbi + self.lue._max - 0.05 )
  local c5 = c4:Translate( UTILS.NMToMeters( 0.25 ), fbi - 90 )

  -- Vec2 array.
  local vec2 = { c1:GetVec2(), c2:GetVec2(), c3:GetVec2(), c4:GetVec2(), c5:GetVec2() }

  self.zoneLineup:UpdateFromVec2( vec2 )

  -- Polygon zone.
  -- local zone=ZONE_POLYGON_BASE:New("Zone Lineup", vec2)
  -- return zone

  return self.zoneLineup
end

--- Get groove zone.
-- @param #AIRBOSS self
-- @param #number l Length of the groove in NM. Default 1.5 NM.
-- @param #number w Width of the groove in NM. Default 0.25 NM.
-- @param #number b Width of the beginning in NM. Default 0.10 NM.
-- @return Core.Zone#ZONE_POLYGON_BASE Groove zone.
function AIRBOSS:_GetZoneGroove( l, w, b )

  self.zoneGroove = self.zoneGroove or ZONE_POLYGON_BASE:New( "Zone Groove" )

  l = l or 1.50
  w = w or 0.25
  b = b or 0.10

  -- Get radial, i.e. inverse of BRC.
  local fbi = self:GetRadial( 1, false, false )

  -- Stern coordinate.
  local st = self:_GetSternCoord()

  -- Zone points.
  local c1 = st:Translate( self.carrierparam.totwidthstarboard, fbi - 90 )
  local c2 = st:Translate( UTILS.NMToMeters( 0.10 ), fbi - 90 ):Translate( UTILS.NMToMeters( 0.3 ), fbi )
  local c3 = st:Translate( UTILS.NMToMeters( 0.25 ), fbi - 90 ):Translate( UTILS.NMToMeters( l ), fbi )
  local c4 = st:Translate( UTILS.NMToMeters( w / 2 ), fbi + 90 ):Translate( UTILS.NMToMeters( l ), fbi )
  local c5 = st:Translate( UTILS.NMToMeters( b ), fbi + 90 ):Translate( UTILS.NMToMeters( 0.3 ), fbi )
  local c6 = st:Translate( self.carrierparam.totwidthport, fbi + 90 )

  -- Vec2 array.
  local vec2 = { c1:GetVec2(), c2:GetVec2(), c3:GetVec2(), c4:GetVec2(), c5:GetVec2(), c6:GetVec2() }

  self.zoneGroove:UpdateFromVec2( vec2 )

  -- Polygon zone.
  -- local zone=ZONE_POLYGON_BASE:New("Zone Groove", vec2)
  -- return zone

  return self.zoneGroove
end

--- Get Bullseye zone with radius 1 NM and DME 3 NM from the carrier. Radial depends on recovery case.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @return Core.Zone#ZONE_RADIUS Arc in zone.
function AIRBOSS:_GetZoneBullseye( case )

  -- Radius = 1 NM.
  local radius = UTILS.NMToMeters( 1 )

  -- Distance = 3 NM
  local distance = UTILS.NMToMeters( 3 )

  -- Zone depends on Case recovery.
  local radial = self:GetRadial( case, false, false )

  -- Get coordinate and vec2.
  local coord = self:GetCoordinate():Translate( distance, radial )
  local vec2 = coord:GetVec2()

  -- Create zone.
  local zone = ZONE_RADIUS:New( "Zone Bullseye", vec2, radius )
  return zone

  -- self.zoneBullseye=self.zoneBullseye or ZONE_RADIUS:New("Zone Bullseye", vec2, radius)
end

--- Get dirty up zone with radius 1 NM and DME 9 NM from the carrier. Radial depends on recovery case.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @return Core.Zone#ZONE_RADIUS Dirty up zone.
function AIRBOSS:_GetZoneDirtyUp( case )

  -- Radius = 1 NM.
  local radius = UTILS.NMToMeters( 1 )

  -- Distance = 9 NM
  local distance = UTILS.NMToMeters( 9 )

  -- Zone depends on Case recovery.
  local radial = self:GetRadial( case, false, false )

  -- Get coordinate and vec2.
  local coord = self:GetCoordinate():Translate( distance, radial )
  local vec2 = coord:GetVec2()

  -- Create zone.
  local zone = ZONE_RADIUS:New( "Zone Dirty Up", vec2, radius )

  return zone
end

--- Get arc out zone with radius 1 NM and DME 12 NM from the carrier. Radial depends on recovery case.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @return Core.Zone#ZONE_RADIUS Arc in zone.
function AIRBOSS:_GetZoneArcOut( case )

  -- Radius = 1.25 NM.
  local radius = UTILS.NMToMeters( 1.25 )

  -- Distance = 12 NM
  local distance = UTILS.NMToMeters( 11.75 )

  -- Zone depends on Case recovery.
  local radial = self:GetRadial( case, false, false )

  -- Get coordinate of carrier and translate.
  local coord = self:GetCoordinate():Translate( distance, radial )

  -- Create zone.
  local zone = ZONE_RADIUS:New( "Zone Arc Out", coord:GetVec2(), radius )

  return zone
end

--- Get arc in zone with radius 1 NM and DME 14 NM from the carrier. Radial depends on recovery case.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @return Core.Zone#ZONE_RADIUS Arc in zone.
function AIRBOSS:_GetZoneArcIn( case )

  -- Radius = 1.25 NM.
  local radius = UTILS.NMToMeters( 1.25 )

  -- Zone depends on Case recovery.
  local radial = self:GetRadial( case, false, true )

  -- Angle between FB/BRC and holding zone.
  local alpha = math.rad( self.holdingoffset )

  -- 14+x NM from carrier
  local x = 14 -- /math.cos(alpha)

  -- Distance = 14 NM
  local distance = UTILS.NMToMeters( x )

  -- Get coordinate.
  local coord = self:GetCoordinate():Translate( distance, radial )

  -- Create zone.
  local zone = ZONE_RADIUS:New( "Zone Arc In", coord:GetVec2(), radius )

  return zone
end

--- Get platform zone with radius 1 NM and DME 19 NM from the carrier. Radial depends on recovery case.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @return Core.Zone#ZONE_RADIUS Circular platform zone.
function AIRBOSS:_GetZonePlatform( case )

  -- Radius = 1 NM.
  local radius = UTILS.NMToMeters( 1 )

  -- Zone depends on Case recovery.
  local radial = self:GetRadial( case, false, true )

  -- Angle between FB/BRC and holding zone.
  local alpha = math.rad( self.holdingoffset )

  -- Distance = 19 NM
  local distance = UTILS.NMToMeters( 19 ) -- /math.cos(alpha)

  -- Get coordinate.
  local coord = self:GetCoordinate():Translate( distance, radial )

  -- Create zone.
  local zone = ZONE_RADIUS:New( "Zone Platform", coord:GetVec2(), radius )

  return zone
end

--- Get approach corridor zone. Shape depends on recovery case.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @param #number l Length of the zone in NM. Default 31 (=21+10) NM.
-- @return Core.Zone#ZONE_POLYGON_BASE Box zone.
function AIRBOSS:_GetZoneCorridor( case, l )

  -- Total length.
  l = l or 31

  -- Radial and offset.
  local radial = self:GetRadial( case, false, false )
  local offset = self:GetRadial( case, false, true )

  -- Distance shift ahead of carrier to allow for some space to bolter.
  local dx = 5

  -- Width of the box in NM.
  local w = 2
  local w2 = w / 2

  -- Distance from carrier to arc out zone.
  local d = 12

  -- Carrier position.
  local cv = self:GetCoordinate()

  -- Polygon points.
  local c = {}

  -- First point. Carrier coordinate translated 5 NM in direction of travel to allow for bolter space.
  c[1] = cv:Translate( -UTILS.NMToMeters( dx ), radial )

  if math.abs( self.holdingoffset ) >= 5 then

    -----------------
    -- Angled Case --
    -----------------

    c[2] = c[1]:Translate( UTILS.NMToMeters( w2 ), radial - 90 ) -- 1 Right of carrier, dx ahead.
    c[3] = c[2]:Translate( UTILS.NMToMeters( d + dx + w2 ), radial ) -- 13 "south" @ 1 right

    c[4] = cv:Translate( UTILS.NMToMeters( 15 ), offset ):Translate( UTILS.NMToMeters( 1 ), offset - 90 )
    c[5] = cv:Translate( UTILS.NMToMeters( l ), offset ):Translate( UTILS.NMToMeters( 1 ), offset - 90 )
    c[6] = cv:Translate( UTILS.NMToMeters( l ), offset ):Translate( UTILS.NMToMeters( 1 ), offset + 90 )
    c[7] = cv:Translate( UTILS.NMToMeters( 13 ), offset ):Translate( UTILS.NMToMeters( 1 ), offset + 90 )
    c[8] = cv:Translate( UTILS.NMToMeters( 11 ), radial ):Translate( UTILS.NMToMeters( 1 ), radial + 90 )

    c[9] = c[1]:Translate( UTILS.NMToMeters( w2 ), radial + 90 )

  else

    -----------------------------
    -- Easy case of a long box --
    -----------------------------

    c[2] = c[1]:Translate( UTILS.NMToMeters( w2 ), radial - 90 )
    c[3] = c[2]:Translate( UTILS.NMToMeters( dx + l ), radial ) -- Stack 1 starts at 21 and is 7 NM.
    c[4] = c[3]:Translate( UTILS.NMToMeters( w ), radial + 90 )
    c[5] = c[1]:Translate( UTILS.NMToMeters( w2 ), radial + 90 )

  end

  -- Create an array of a square!
  local p = {}
  for _i, _c in ipairs( c ) do
    if self.Debug then
      -- _c:SmokeBlue()
    end
    p[_i] = _c:GetVec2()
  end

  -- Square zone length=10NM width=6 NM behind the carrier starting at angels+15 NM behind the carrier.
  -- So stay 0-5 NM (+1 NM error margin) port of carrier.
  local zone = ZONE_POLYGON_BASE:New( "CASE II/III Approach Corridor", p )

  return zone
end

--- Get zone of carrier. Carrier is approximated as rectangle.
-- @param #AIRBOSS self
-- @return Core.Zone#ZONE Zone surrounding the carrier.
function AIRBOSS:_GetZoneCarrierBox()

  self.zoneCarrierbox = self.zoneCarrierbox or ZONE_POLYGON_BASE:New( "Carrier Box Zone" )

  -- Stern coordinate.
  local S = self:_GetSternCoord()

  -- Current carrier heading.
  local hdg = self:GetHeading( false )

  -- Coordinate array.
  local p = {}

  -- Starboard stern point.
  p[1] = S:Translate( self.carrierparam.totwidthstarboard, hdg + 90 )

  -- Starboard bow point.
  p[2] = p[1]:Translate( self.carrierparam.totlength, hdg )

  -- Port bow point.
  p[3] = p[2]:Translate( self.carrierparam.totwidthstarboard + self.carrierparam.totwidthport, hdg - 90 )

  -- Port stern point.
  p[4] = p[3]:Translate( self.carrierparam.totlength, hdg - 180 )

  -- Convert to vec2.
  local vec2 = {}
  for _, coord in ipairs( p ) do
    table.insert( vec2, coord:GetVec2() )
  end

  -- Create polygon zone.
  -- local zone=ZONE_POLYGON_BASE:New("Carrier Box Zone", vec2)
  -- return zone

  self.zoneCarrierbox:UpdateFromVec2( vec2 )

  return self.zoneCarrierbox
end

--- Get zone of landing runway.
-- @param #AIRBOSS self
-- @return Core.Zone#ZONE_POLYGON Zone surrounding landing runway.
function AIRBOSS:_GetZoneRunwayBox()

  self.zoneRunwaybox = self.zoneRunwaybox or ZONE_POLYGON_BASE:New( "Landing Runway Zone" )

  -- Stern coordinate.
  local S = self:_GetSternCoord()

  -- Current carrier heading.
  local FB = self:GetFinalBearing( false )

  -- Coordinate array.
  local p = {}

  -- Points.
  p[1] = S:Translate( self.carrierparam.rwywidth * 0.5, FB + 90 )
  p[2] = p[1]:Translate( self.carrierparam.rwylength, FB )
  p[3] = p[2]:Translate( self.carrierparam.rwywidth, FB - 90 )
  p[4] = p[3]:Translate( self.carrierparam.rwylength, FB - 180 )

  -- Convert to vec2.
  local vec2 = {}
  for _, coord in ipairs( p ) do
    table.insert( vec2, coord:GetVec2() )
  end

  -- Create polygon zone.
  -- local zone=ZONE_POLYGON_BASE:New("Landing Runway Zone", vec2)
  -- return zone

  self.zoneRunwaybox:UpdateFromVec2( vec2 )

  return self.zoneRunwaybox
end

--- Get zone of primary abeam landing position of HMS Hermes, HMS Invincible, USS Tarawa, USS America and Juan Carlos. Box length 50 meters and width 30 meters.

--- Allow for Clear to land call from LSO approaching abeam the landing spot if stable as per NATOPS 00-80T
-- @param #AIRBOSS self
-- @return Core.Zone#ZONE_POLYGON Zone surrounding landing runway.
function AIRBOSS:_GetZoneAbeamLandingSpot()

  -- Primary landing Spot coordinate.
  local S = self:_GetOptLandingCoordinate()

  -- Current carrier heading.
  local FB = self:GetFinalBearing( false )

  -- Coordinate array. Pene Testing extended Abeam landing spot V/STOL.
  local p={}
  
  -- Points.
  p[1] = S:Translate( 15, FB ):Translate( 15, FB + 90 ) -- Top-Right
  p[2] = S:Translate( -45, FB ):Translate( 15, FB + 90 ) -- Bottom-Right
  p[3] = S:Translate( -45, FB ):Translate( 15, FB - 90 ) -- Bottom-Left
  p[4] = S:Translate( 15, FB ):Translate( 15, FB - 90 ) -- Top-Left

  -- Convert to vec2.
  local vec2 = {}
  for _, coord in ipairs( p ) do
    table.insert( vec2, coord:GetVec2() )
  end

  -- Create polygon zone.
  local zone = ZONE_POLYGON_BASE:New( "Abeam Landing Spot Zone", vec2 )

  return zone
end

--- Get zone of the primary landing spot of the USS Tarawa.
-- @param #AIRBOSS self
-- @return Core.Zone#ZONE_POLYGON Zone surrounding landing runway.
function AIRBOSS:_GetZoneLandingSpot()

  -- Primary landing Spot coordinate.
  local S = self:_GetLandingSpotCoordinate()

  -- Current carrier heading.
  local FB = self:GetFinalBearing( false )

  -- Coordinate array.
  local p = {}

  -- Points.
  p[1] = S:Translate( 10, FB ):Translate( 10, FB + 90 ) -- Top-Right
  p[2] = S:Translate( -10, FB ):Translate( 10, FB + 90 ) -- Bottom-Right
  p[3] = S:Translate( -10, FB ):Translate( 10, FB - 90 ) -- Bottom-Left
  p[4] = S:Translate( 10, FB ):Translate( 10, FB - 90 ) -- Top-left

  -- Convert to vec2.
  local vec2 = {}
  for _, coord in ipairs( p ) do
    table.insert( vec2, coord:GetVec2() )
  end

  -- Create polygon zone.
  local zone = ZONE_POLYGON_BASE:New( "Landing Spot Zone", vec2 )

  return zone
end

--- Get holding zone of player.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @param #number stack Marshal stack number.
-- @return Core.Zone#ZONE Holding zone.
function AIRBOSS:_GetZoneHolding( case, stack )

  -- Holding zone.
  local zoneHolding = nil -- Core.Zone#ZONE

  -- Stack is <= 0 ==> no marshal zone.
  if stack <= 0 then
    self:E( self.lid .. "ERROR: Stack <= 0 in _GetZoneHolding!" )
    self:E( { case = case, stack = stack } )
    return nil
  end

  -- Pattern altitude.
  local patternalt, c1, c2 = self:_GetMarshalAltitude( stack, case )

  -- Select case.
  if case == 1 then
    -- CASE I

    -- Get current carrier heading.
    local hdg = self:GetHeading()

    -- Distance to the post.
    local D = UTILS.NMToMeters( 2.5 )

    -- Post 2.5 NM port of carrier.
    local Post = self:GetCoordinate():Translate( D, hdg + 270 )

    -- TODO: update zone not creating a new one.

    -- Create holding zone.
    self.zoneHolding = ZONE_RADIUS:New( "CASE I Holding Zone", Post:GetVec2(), self.marshalradius )

    -- Delta pattern.
    if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
      self.zoneHolding = ZONE_RADIUS:New( "CASE I Holding Zone", self.carrier:GetVec2(), UTILS.NMToMeters( 5 ) )
    end

  else
    -- CASE II/II

    -- Get radial.
    local radial = self:GetRadial( case, false, true )

    -- Create an array of a rectangle. Length is 7 NM, width is 8 NM. One NM starboard to line up with the approach corridor.
    local p = {}
    p[1] = c2:Translate( UTILS.NMToMeters( 1 ), radial - 90 ):GetVec2() -- c2 is at (angels+15) NM directly behind the carrier. We translate it 1 NM starboard.
    p[2] = c1:Translate( UTILS.NMToMeters( 1 ), radial - 90 ):GetVec2() -- c1 is 7 NM further behind. Also translated 1 NM starboard.
    p[3] = c1:Translate( UTILS.NMToMeters( 7 ), radial + 90 ):GetVec2() -- p3 7 NM port of carrier.
    p[4] = c2:Translate( UTILS.NMToMeters( 7 ), radial + 90 ):GetVec2() -- p4 7 NM port of carrier.

    -- Square zone length=7NM width=6 NM behind the carrier starting at angels+15 NM behind the carrier.
    -- So stay 0-5 NM (+1 NM error margin) port of carrier.
    self.zoneHolding = self.zoneHolding or ZONE_POLYGON_BASE:New( "CASE II/III Holding Zone" )

    self.zoneHolding:UpdateFromVec2( p )
  end

  return self.zoneHolding
end

--- Get zone where player are automatically commence when enter.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @param #number stack Stack for Case II/III as we commence from stack>=1.
-- @return Core.Zone#ZONE Holding zone.
function AIRBOSS:_GetZoneCommence( case, stack )

  -- Commence zone.
  local zone

  if case == 1 then
    -- Case I

    -- Get current carrier heading.
    local hdg = self:GetHeading()

    -- Distance to the zone.
    local D = UTILS.NMToMeters( 4.75 )

    -- Zone radius.
    local R = UTILS.NMToMeters( 1 )

    -- Three position
    local Three = self:GetCoordinate():Translate( D, hdg + 275 )

    if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
      local Dx = UTILS.NMToMeters( 2.25 )

      local Dz = UTILS.NMToMeters( 2.25 )

      R = UTILS.NMToMeters( 1 )

      Three = self:GetCoordinate():Translate( Dz, hdg - 90 ):Translate( Dx, hdg - 180 )

    end

    -- Create holding zone.
    self.zoneCommence = self.zoneCommence or ZONE_RADIUS:New( "CASE I Commence Zone" )

    self.zoneCommence:UpdateFromVec2( Three:GetVec2(), R )

  else
    -- Case II/III

    stack = stack or 1

    -- Start point at 21 NM for stack=1.
    local l = 20 + stack

    -- Offset angle
    local offset = self:GetRadial( case, false, true )

    -- Carrier position.
    local cv = self:GetCoordinate()

    -- Polygon points.
    local c = {}

    c[1] = cv:Translate( UTILS.NMToMeters( l ), offset ):Translate( UTILS.NMToMeters( 1 ), offset - 90 )
    c[2] = cv:Translate( UTILS.NMToMeters( l + 2.5 ), offset ):Translate( UTILS.NMToMeters( 1 ), offset - 90 )
    c[3] = cv:Translate( UTILS.NMToMeters( l + 2.5 ), offset ):Translate( UTILS.NMToMeters( 1 ), offset + 90 )
    c[4] = cv:Translate( UTILS.NMToMeters( l ), offset ):Translate( UTILS.NMToMeters( 1 ), offset + 90 )

    -- Create an array of a square!
    local p = {}
    for _i, _c in ipairs( c ) do
      p[_i] = _c:GetVec2()
    end

    -- Zone polygon.
    self.zoneCommence = self.zoneCommence or ZONE_POLYGON_BASE:New( "CASE II/III Commence Zone" )

    self.zoneCommence:UpdateFromVec2( p )

  end

  return self.zoneCommence
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ORIENTATION functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Provide info about player status on the fly.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_AttitudeMonitor( playerData )

  -- Player unit.
  local unit = playerData.unit

  -- Aircraft attitude.
  local aoa = unit:GetAoA()
  local yaw = unit:GetYaw()
  local roll = unit:GetRoll()
  local pitch = unit:GetPitch()

  -- Distance to the boat.
  local dist = playerData.unit:GetCoordinate():Get2DDistance( self:GetCoordinate() )
  local dx, dz, rho, phi = self:_GetDistances( unit )

  -- Wind vector.
  local wind = unit:GetCoordinate():GetWindWithTurbulenceVec3()

  -- Aircraft veloecity vector.
  local velo = unit:GetVelocityVec3()
  local vabs = UTILS.VecNorm( velo )

  local rwy = false
  local step = playerData.step
  if playerData.step == AIRBOSS.PatternStep.FINAL or
     playerData.step == AIRBOSS.PatternStep.GROOVE_XX or
     playerData.step == AIRBOSS.PatternStep.GROOVE_IM or
     playerData.step == AIRBOSS.PatternStep.GROOVE_IC or
     playerData.step == AIRBOSS.PatternStep.GROOVE_AR or
     playerData.step == AIRBOSS.PatternStep.GROOVE_AL or
     playerData.step == AIRBOSS.PatternStep.GROOVE_LC or
     playerData.step == AIRBOSS.PatternStep.GROOVE_IW then
    step = self:_GS( step, -1 )
    rwy = true
  end

  -- Relative heading Aircraft to Carrier.
  local relhead = self:_GetRelativeHeading( playerData.unit, rwy )

  -- local lc=self:_GetOptLandingCoordinate()
  -- lc:FlareRed()

  -- Output
  local text = string.format( "Pattern step: %s", step )
  text = text .. string.format( "\nAoA=%.1f° = %.1f Units | |V|=%.1f knots", aoa, self:_AoADeg2Units( playerData, aoa ), UTILS.MpsToKnots( vabs ) )
  if self.Debug then
    -- Velocity vector.
    text = text .. string.format( "\nVx=%.1f Vy=%.1f Vz=%.1f m/s", velo.x, velo.y, velo.z )
    -- Wind vector.
    text = text .. string.format( "\nWind Vx=%.1f Vy=%.1f Vz=%.1f m/s", wind.x, wind.y, wind.z )
  end
  text = text .. string.format( "\nPitch=%.1f° | Roll=%.1f° | Yaw=%.1f°", pitch, roll, yaw )
  text = text .. string.format( "\nClimb Angle=%.1f° | Rate=%d ft/min", unit:GetClimbAngle(), velo.y * 196.85 )
  local dist = self:_GetOptLandingCoordinate():Get3DDistance( playerData.unit )
  -- Get player velocity in km/h.
  local vplayer = playerData.unit:GetVelocityKMH()
  -- Get carrier velocity in km/h.
  local vcarrier = self.carrier:GetVelocityKMH()
  -- Speed difference.
  local dv = math.abs( vplayer - vcarrier )
  local alt = self:_GetAltCarrier( playerData.unit )
  text = text .. string.format( "\nDist=%.1f m Alt=%.1f m delta|V|=%.1f km/h", dist, alt, dv )
  -- If in the groove, provide line up and glide slope error.
  if playerData.step == AIRBOSS.PatternStep.FINAL or
     playerData.step == AIRBOSS.PatternStep.GROOVE_XX or
     playerData.step == AIRBOSS.PatternStep.GROOVE_IM or
     playerData.step == AIRBOSS.PatternStep.GROOVE_IC or
     playerData.step == AIRBOSS.PatternStep.GROOVE_AR or
     playerData.step == AIRBOSS.PatternStep.GROOVE_AL or
     playerData.step == AIRBOSS.PatternStep.GROOVE_LC or
     playerData.step == AIRBOSS.PatternStep.GROOVE_IW then
    local lue = self:_Lineup( playerData.unit, true )
    local gle = self:_Glideslope( playerData.unit )
    text = text .. string.format( "\nGamma=%.1f° | Rho=%.1f°", relhead, phi )
    text = text .. string.format( "\nLineUp=%.2f° | GlideSlope=%.2f° | AoA=%.1f Units", lue, gle, self:_AoADeg2Units( playerData, aoa ) )
    local grade, points, analysis = self:_LSOgrade( playerData )
    text = text .. string.format( "\nTgroove=%.1f sec", self:_GetTimeInGroove( playerData ) )
    text = text .. string.format( "\nGrade: %s %.1f PT - %s", grade, points, analysis )
  else
    text = text .. string.format( "\nR=%.2f NM | X=%d Z=%d m", UTILS.MetersToNM( rho ), dx, dz )
    text = text .. string.format( "\nGamma=%.1f° | Rho=%.1f°", relhead, phi )
  end

  MESSAGE:New( text, 1, nil, true ):ToClient( playerData.client )
end

--- Get glide slope of aircraft unit.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @param #number optangle (Optional) Return glide slope relative to this angle, i.e. the error from the optimal glide slope ~3.5 degrees.
-- @return #number Glide slope angle in degrees measured from the deck of the carrier and third wire.
function AIRBOSS:_Glideslope( unit, optangle )

  if optangle == nil then
    if unit:GetTypeName() == AIRBOSS.AircraftCarrier.AV8B then
      optangle = 3.0
    else
      optangle = 3.5
    end
  end
  -- Landing coordinate
  local landingcoord = self:_GetOptLandingCoordinate()

  -- Distance from stern to aircraft.
  local x = unit:GetCoordinate():Get2DDistance( landingcoord )

  -- Altitude of unit corrected by the deck height of the carrier.
  local h = self:_GetAltCarrier( unit )

  -- Harrier should be 40-50 ft above the deck.
  if unit:GetTypeName() == AIRBOSS.AircraftCarrier.AV8B then
    h = unit:GetAltitude() - (UTILS.FeetToMeters( 50 ) + self.carrierparam.deckheight + 2)
  end

  -- Glide slope.
  local glideslope = math.atan( h / x )

  -- Glide slope (error) in degrees.
  local gs = math.deg( glideslope ) - optangle

  return gs
end

--- Get glide slope of aircraft unit.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @param #number optangle (Optional) Return glide slope relative to this angle, i.e. the error from the optimal glide slope ~3.5 degrees.
-- @return #number Glide slope angle in degrees measured from the deck of the carrier and third wire.
function AIRBOSS:_Glideslope2( unit, optangle )

  if optangle == nil then
    if unit:GetTypeName() == AIRBOSS.AircraftCarrier.AV8B then
      optangle = 3.0
    else
      optangle = 3.5
    end
  end
  -- Landing coordinate
  local landingcoord = self:_GetOptLandingCoordinate()

  -- Distance from stern to aircraft.
  local x = unit:GetCoordinate():Get3DDistance( landingcoord )

  -- Altitude of unit corrected by the deck height of the carrier.
  local h = self:_GetAltCarrier( unit )

  -- Harrier should be 40-50 ft above the deck.
  if unit:GetTypeName() == AIRBOSS.AircraftCarrier.AV8B then
    h = unit:GetAltitude() - (UTILS.FeetToMeters( 50 ) + self.carrierparam.deckheight + 2)
  end

  -- Glide slope.
  local glideslope = math.asin( h / x )

  -- Glide slope (error) in degrees.
  local gs = math.deg( glideslope ) - optangle

  -- Debug.
  self:T3( self.lid .. string.format( "Glide slope error = %.1f, x=%.1f h=%.1f", gs, x, h ) )

  return gs
end

--- Get line up of player wrt to carrier.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @param #boolean runway If true, include angled runway.
-- @return #number Line up with runway heading in degrees. 0 degrees = perfect line up. +1 too far left. -1 too far right.
function AIRBOSS:_Lineup( unit, runway )

  -- Landing coordinate
  local landingcoord = self:_GetOptLandingCoordinate()

  -- Vector to landing coord.
  local A = landingcoord:GetVec3()

  -- Vector to player.
  local B = unit:GetVec3()

  -- Vector from player to carrier.
  local C = UTILS.VecSubstract( A, B )

  -- Only in 2D plane.
  C.y = 0.0

  -- Orientation of carrier.
  local X = self.carrier:GetOrientationX()
  X.y = 0.0

  -- Rotate orientation to angled runway.
  if runway then
    X = UTILS.Rotate2D( X, -self.carrierparam.rwyangle )
  end

  -- Projection of player pos on x component.
  local x = UTILS.VecDot( X, C )

  -- Orientation of carrier.
  local Z = self.carrier:GetOrientationZ()
  Z.y = 0.0

  -- Rotate orientation to angled runway.
  if runway then
    Z = UTILS.Rotate2D( Z, -self.carrierparam.rwyangle )
  end

  -- Projection of player pos on z component.
  local z = UTILS.VecDot( Z, C )

  ---
  local lineup = math.deg( math.atan2( z, x ) )

  return lineup
end

--- Get altitude of aircraft wrt carrier deck. Should give zero when the aircraft touched down.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #number Altitude in meters wrt carrier height.
function AIRBOSS:_GetAltCarrier( unit )

  -- TODO: Value 4 meters is for the Hornet. Adjust for Harrier, A4E and

  -- Altitude of unit corrected by the deck height of the carrier.
  local h = unit:GetAltitude() - self.carrierparam.deckheight - 2

  return h
end

--- Get optimal landing position of the aircraft. Usually between second and third wire. In case of Tarawa, Canberrra, Juan Carlos and America we take the abeam landing spot 120 ft above and 21 ft abeam the 7.5 position, for the Juan Carlos I, HMS Invincible, and HMS Hermes and Invincible it is 120 ft above and 21 ft abeam the 5 position. For CASE III it is 120ft directly above the landing spot.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Optimal landing coordinate.
function AIRBOSS:_GetOptLandingCoordinate()

  -- Start with stern coordiante.
  self.landingcoord:UpdateFromCoordinate( self:_GetSternCoord() )

  -- Final bearing.
  local FB=self:GetFinalBearing(false)

  -- Cse
  local case=self.case

  -- set Case III V/STOL abeam landing spot over deck -- Pene Testing
  if self.carriertype==AIRBOSS.CarrierType.INVINCIBLE or self.carriertype==AIRBOSS.CarrierType.HERMES or self.carriertype==AIRBOSS.CarrierType.TARAWA or self.carriertype==AIRBOSS.CarrierType.AMERICA or self.carriertype==AIRBOSS.CarrierType.JCARLOS or self.carriertype==AIRBOSS.CarrierType.CANBERRA then
  
    if case==3 then

      -- Landing coordinate.
      self.landingcoord:UpdateFromCoordinate(self:_GetLandingSpotCoordinate())

      -- Altitude 120ft -- is this corect for Case III?
      self.landingcoord:SetAltitude(UTILS.FeetToMeters(120))
 
    elseif case==2 or case==1 then

      -- Landing 100 ft abeam, 120 ft alt.
      self.landingcoord:UpdateFromCoordinate(self:_GetLandingSpotCoordinate()):Translate(35, FB-90, true, true)

      -- Alitude 120 ft.
      self.landingcoord:SetAltitude(UTILS.FeetToMeters(120))

    end
  
  else

    -- Ideally we want to land between 2nd and 3rd wire.
    if self.carrierparam.wire3 then
      -- We take the position of the 3rd wire to approximately account for the length of the aircraft.
      self.landingcoord:Translate( self.carrierparam.wire3, FB, true, true )
    end

    -- Add 2 meters to account for aircraft height.
    self.landingcoord.y = self.landingcoord.y + 2

  end

  return self.landingcoord
end

--- Get landing spot on Tarawa and others.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Primary landing spot coordinate.
function AIRBOSS:_GetLandingSpotCoordinate()

  -- Start at stern coordinate.
  self.landingspotcoord:UpdateFromCoordinate( self:_GetSternCoord() )

  -- Landing 100 ft abeam, 100 alt.
  local hdg = self:GetHeading()

  -- Primary landing spot. Different carriers handled via carrier parameter landingspot now.
  self.landingspotcoord:Translate( self.carrierparam.landingspot, hdg, true, true ):SetAltitude( self.carrierparam.deckheight )

  return self.landingspotcoord
end

--- Get true (or magnetic) heading of carrier.
-- @param #AIRBOSS self
-- @param #boolean magnetic If true, calculate magnetic heading. By default true heading is returned.
-- @return #number Carrier heading in degrees.
function AIRBOSS:GetHeading( magnetic )
  self:F3( { magnetic = magnetic } )

  -- Carrier heading
  local hdg = self.carrier:GetHeading()

  -- Include magnetic declination.
  if magnetic then
    hdg = hdg - self.magvar
  end

  -- Adjust negative values.
  if hdg < 0 then
    hdg = hdg + 360
  end

  return hdg
end

--- Get base recovery course (BRC) of carrier.
-- The is the magnetic heading of the carrier.
-- @param #AIRBOSS self
-- @return #number BRC in degrees.
function AIRBOSS:GetBRC()
  return self:GetHeading( true )
end

--- Get wind direction and speed at carrier position.
-- @param #AIRBOSS self
-- @param #number alt Altitude ASL in meters. Default 15 m.
-- @param #boolean magnetic Direction including magnetic declination.
-- @param Core.Point#COORDINATE coord (Optional) Coordinate at which to get the wind. Default is current carrier position.
-- @return #number Direction the wind is blowing **from** in degrees.
-- @return #number Wind speed in m/s.
function AIRBOSS:GetWind( alt, magnetic, coord )

  -- Current position of the carrier or input.
  local cv = coord or self:GetCoordinate()

  -- Wind direction and speed. By default at 18 meters ASL.
  local Wdir, Wspeed = cv:GetWind( alt or 18 )

  -- Include magnetic declination.
  if magnetic then
    Wdir = Wdir - self.magvar
    -- Adjust negative values.
    if Wdir < 0 then
      Wdir = Wdir + 360
    end
  end

  return Wdir, Wspeed
end

--- Get wind speed on carrier deck parallel and perpendicular to runway.
-- @param #AIRBOSS self
-- @param #number alt Altitude in meters. Default 18 m.
-- @return #number Wind component parallel to runway im m/s.
-- @return #number Wind component perpendicular to runway in m/s.
-- @return #number Total wind strength in m/s.
function AIRBOSS:GetWindOnDeck( alt )

  -- Position of carrier.
  local cv = self:GetCoordinate()

  -- Velocity vector of carrier.
  local vc = self.carrier:GetVelocityVec3()

  -- Carrier orientation X.
  local xc = self.carrier:GetOrientationX()

  -- Carrier orientation Z.
  local zc = self.carrier:GetOrientationZ()

  -- Rotate back so that angled deck points to wind.
  xc = UTILS.Rotate2D( xc, -self.carrierparam.rwyangle )
  zc = UTILS.Rotate2D( zc, -self.carrierparam.rwyangle )

  -- Wind (from) vector
  local vw = cv:GetWindWithTurbulenceVec3( alt or 18 ) --(change made from 50m to 15m from Discord discussion from Sickdog, next change to 18m due to SC higher deck discord)

  -- Total wind velocity vector.
  -- Carrier velocity has to be negative. If carrier drives in the direction the wind is blowing from, we have less wind in total.
  local vT = UTILS.VecSubstract( vw, vc )

  -- || Parallel component.
  local vpa = UTILS.VecDot( vT, xc )

  -- == Perpendicular component.
  local vpp = UTILS.VecDot( vT, zc )

  -- Strength.
  local vabs = UTILS.VecNorm( vT )

  -- We return positive values as head wind and negative values as tail wind.
  -- TODO: Check minus sign.
  return -vpa, vpp, vabs
end

--- Get true (or magnetic) heading of carrier into the wind. This accounts for the angled runway.
-- @param #AIRBOSS self
-- @param #boolean magnetic If true, calculate magnetic heading. By default true heading is returned.
-- @param Core.Point#COORDINATE coord (Optional) Coordinate from which heading is calculated. Default is current carrier position.
-- @return #number Carrier heading in degrees.
function AIRBOSS:GetHeadingIntoWind( magnetic, coord )

  -- Get direction the wind is blowing from. This is where we want to go.
  local windfrom, vwind = self:GetWind( nil, nil, coord )

  -- Actually, we want the runway in the wind.
  local intowind = windfrom - self.carrierparam.rwyangle

  -- If no wind, take current heading.
  if vwind < 0.1 then
    intowind = self:GetHeading()
  end

  -- Magnetic heading.
  if magnetic then
    intowind = intowind - self.magvar
  end

  -- Adjust negative values.
  if intowind < 0 then
    intowind = intowind + 360
  end

  return intowind
end

--- Get base recovery course (BRC) when the carrier would head into the wind.
-- This includes the current wind direction and accounts for the angled runway.
-- @param #AIRBOSS self
-- @return #number BRC into the wind in degrees.
function AIRBOSS:GetBRCintoWind()
  -- BRC is the magnetic heading.
  return self:GetHeadingIntoWind( true )
end

--- Get final bearing (FB) of carrier.
-- By default, the routine returns the magnetic FB depending on the current map (Caucasus, NTTR, Normandy, Persion Gulf etc).
-- The true bearing can be obtained by setting the *TrueNorth* parameter to true.
-- @param #AIRBOSS self
-- @param #boolean magnetic If true, magnetic FB is returned.
-- @return #number FB in degrees.
function AIRBOSS:GetFinalBearing( magnetic )

  -- First get the heading.
  local fb = self:GetHeading( magnetic )

  -- Final baring = BRC including angled deck.
  fb = fb + self.carrierparam.rwyangle

  -- Adjust negative values.
  if fb < 0 then
    fb = fb + 360
  end

  return fb
end

--- Get radial with respect to carrier BRC or FB and (optionally) holding offset.
--
-- * case=1: radial=FB-180
-- * case=2: radial=HDG-180 (+offset)
-- * case=3: radial=FB-180 (+offset)
--
-- @param #AIRBOSS self
-- @param #number case Recovery case.
-- @param #boolean magnetic If true, magnetic radial is returned. Default is true radial.
-- @param #boolean offset If true, inlcude holding offset.
-- @param #boolean inverse Return inverse, i.e. radial-180 degrees.
-- @return #number Radial in degrees.
function AIRBOSS:GetRadial( case, magnetic, offset, inverse )

  -- Case or current case.
  case = case or self.case

  -- Radial.
  local radial

  -- Select case.
  if case == 1 then

    -- Get radial.
    radial = self:GetFinalBearing( magnetic ) - 180

  elseif case == 2 then

    -- Radial wrt to heading of carrier.
    radial = self:GetHeading( magnetic ) - 180

    -- Holding offset angle (+-15 or 30 degrees usually)
    if offset then
      radial = radial + self.holdingoffset
    end

  elseif case == 3 then

    -- Radial wrt angled runway.
    radial = self:GetFinalBearing( magnetic ) - 180

    -- Holding offset angle (+-15 or 30 degrees usually)
    if offset then
      radial = radial + self.holdingoffset
    end

  end

  -- Adjust for negative values.
  if radial < 0 then
    radial = radial + 360
  end

  -- Inverse?
  if inverse then

    -- Inverse radial
    radial = radial - 180

    -- Adjust for negative values.
    if radial < 0 then
      radial = radial + 360
    end

  end

  return radial
end

--- Get difference between to headings in degrees taking into accound the [0,360) periodocity.
-- @param #AIRBOSS self
-- @param #number hdg1 Heading one.
-- @param #number hdg2 Heading two.
-- @return #number Difference between the two headings in degrees.
function AIRBOSS:_GetDeltaHeading( hdg1, hdg2 )

  local V = {} -- DCS#Vec3
  V.x = math.cos( math.rad( hdg1 ) )
  V.y = 0
  V.z = math.sin( math.rad( hdg1 ) )

  local W = {} -- DCS#Vec3
  W.x = math.cos( math.rad( hdg2 ) )
  W.y = 0
  W.z = math.sin( math.rad( hdg2 ) )

  local alpha = UTILS.VecAngle( V, W )

  return alpha
end

--- Get relative heading of player wrt carrier.
-- This is the angle between the direction/orientation vector of the carrier and the direction/orientation vector of the provided unit.
-- Note that this is calculated in the X-Z plane, i.e. the altitude Y is not taken into account.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Player unit.
-- @param #boolean runway (Optional) If true, return relative heading of unit wrt to angled runway of the carrier.
-- @return #number Relative heading in degrees. An angle of 0 means, unit fly parallel to carrier. An angle of + or - 90 degrees means, unit flies perpendicular to carrier.
function AIRBOSS:_GetRelativeHeading( unit, runway )

  -- Direction vector of the carrier.
  local vC = self.carrier:GetOrientationX()

  -- Include runway angle.
  if runway then
    vC = UTILS.Rotate2D( vC, -self.carrierparam.rwyangle )
  end

  -- Direction vector of the unit.
  local vP = unit:GetOrientationX()

  -- We only want the X-Z plane. Aircraft could fly parallel but ballistic and we dont want the "pitch" angle.
  vC.y = 0;
  vP.y = 0

  -- Get angle between the two orientation vectors in degrees.
  local rhdg = UTILS.VecAngle( vC, vP )

  -- Return heading in degrees.
  return rhdg
end

--- Get relative velocity of player unit wrt to carrier
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Player unit.
-- @return #number Relative velocity in m/s.
function AIRBOSS:_GetRelativeVelocity( unit )

  local vC = self.carrier:GetVelocityVec3()
  local vP = unit:GetVelocityVec3()

  -- Only X-Z plane is necessary here.
  vC.y = 0;
  vP.y = 0

  local v = UTILS.VecSubstract( vP, vC )

  return UTILS.VecNorm( v ), v
end

--- Calculate distances between carrier and aircraft unit.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #number Distance [m] in the direction of the orientation of the carrier.
-- @return #number Distance [m] perpendicular to the orientation of the carrier.
-- @return #number Distance [m] to the carrier.
-- @return #number Angle [Deg] from carrier to plane. Phi=0 if the plane is directly behind the carrier, phi=90 if the plane is starboard, phi=180 if the plane is in front of the carrier.
function AIRBOSS:_GetDistances( unit )

  -- Vector to carrier
  local a = self.carrier:GetVec3()

  -- Vector to player
  local b = unit:GetVec3()

  -- Vector from carrier to player.
  local c = { x = b.x - a.x, y = 0, z = b.z - a.z }

  -- Orientation of carrier.
  local x = self.carrier:GetOrientationX()

  -- Projection of player pos on x component.
  local dx = UTILS.VecDot( x, c )

  -- Orientation of carrier.
  local z = self.carrier:GetOrientationZ()

  -- Projection of player pos on z component.
  local dz = UTILS.VecDot( z, c )

  -- Polar coordinates.
  local rho = math.sqrt( dx * dx + dz * dz )

  -- Not exactly sure any more what I wanted to calculate here.
  local phi = math.deg( math.atan2( dz, dx ) )

  -- Correct for negative values.
  if phi < 0 then
    phi = phi + 360
  end

  return dx, dz, rho, phi
end

--- Check limits for reaching next step.
-- @param #AIRBOSS self
-- @param #number X X position of player unit.
-- @param #number Z Z position of player unit.
-- @param #AIRBOSS.Checkpoint check Checkpoint.
-- @return #boolean If true, checkpoint condition for next step was reached.
function AIRBOSS:_CheckLimits( X, Z, check )

  -- Limits
  local nextXmin = check.LimitXmin == nil or (check.LimitXmin and (check.LimitXmin < 0 and X <= check.LimitXmin or check.LimitXmin >= 0 and X >= check.LimitXmin))
  local nextXmax = check.LimitXmax == nil or (check.LimitXmax and (check.LimitXmax < 0 and X >= check.LimitXmax or check.LimitXmax >= 0 and X <= check.LimitXmax))
  local nextZmin = check.LimitZmin == nil or (check.LimitZmin and (check.LimitZmin < 0 and Z <= check.LimitZmin or check.LimitZmin >= 0 and Z >= check.LimitZmin))
  local nextZmax = check.LimitZmax == nil or (check.LimitZmax and (check.LimitZmax < 0 and Z >= check.LimitZmax or check.LimitZmax >= 0 and Z <= check.LimitZmax))

  -- Proceed to next step if all conditions are fullfilled.
  local next = nextXmin and nextXmax and nextZmin and nextZmax

  -- Debug info.
  local text = string.format( "step=%s: next=%s: X=%d Xmin=%s Xmax=%s | Z=%d Zmin=%s Zmax=%s", check.name, tostring( next ), X, tostring( check.LimitXmin ), tostring( check.LimitXmax ), Z, tostring( check.LimitZmin ), tostring( check.LimitZmax ) )
  self:T3( self.lid .. text )

  return next
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LSO functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- LSO advice radio call.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number glideslopeError Error in degrees.
-- @param #number lineupError Error in degrees.
function AIRBOSS:_LSOadvice( playerData, glideslopeError, lineupError )

  -- Advice time.
  local advice = 0

  -- Glideslope high/low calls.
  if glideslopeError > self.gle.HIGH then -- 1.5 then
    -- "You're high!"
    self:RadioTransmission( self.LSORadio, self.LSOCall.HIGH, true, nil, nil, true )
    advice = advice + self.LSOCall.HIGH.duration
  elseif glideslopeError > self.gle.High then -- 0.8 then
    -- "You're high."
    self:RadioTransmission( self.LSORadio, self.LSOCall.HIGH, false, nil, nil, true )
    advice = advice + self.LSOCall.HIGH.duration
  elseif glideslopeError < self.gle.LOW then -- -0.9 then
    -- "Power!"
    self:RadioTransmission( self.LSORadio, self.LSOCall.POWER, true, nil, nil, true )
    advice = advice + self.LSOCall.POWER.duration
  elseif glideslopeError < self.gle.Low then -- -0.6 then
    -- "Power."
    self:RadioTransmission( self.LSORadio, self.LSOCall.POWER, false, nil, nil, true )
    advice = advice + self.LSOCall.POWER.duration
  else
    -- "Good altitude."
  end

  -- Lineup left/right calls.
  if lineupError < self.lue.LEFT then
    -- "Come left!"
    self:RadioTransmission( self.LSORadio, self.LSOCall.COMELEFT, true, nil, nil, true )
    advice = advice + self.LSOCall.COMELEFT.duration
  elseif lineupError < self.lue.Left then
    -- "Come left."
    self:RadioTransmission( self.LSORadio, self.LSOCall.COMELEFT, false, nil, nil, true )
    advice = advice + self.LSOCall.COMELEFT.duration
  elseif lineupError > self.lue.RIGHT then -- 3 then
    -- "Right for lineup!"
    self:RadioTransmission( self.LSORadio, self.LSOCall.RIGHTFORLINEUP, true, nil, nil, true )
    advice = advice + self.LSOCall.RIGHTFORLINEUP.duration
  elseif lineupError > self.lue.Right then -- 1 then
    -- "Right for lineup."
    self:RadioTransmission( self.LSORadio, self.LSOCall.RIGHTFORLINEUP, false, nil, nil, true )
    advice = advice + self.LSOCall.RIGHTFORLINEUP.duration
  else
    -- "Good lineup."
  end

  -- Get current AoA.
  local AOA = playerData.unit:GetAoA()

  -- Get aircraft AoA parameters.
  local acaoa = self:_GetAircraftAoA( playerData )

  -- Speed via AoA - not for the Harrier.
  if playerData.actype ~= AIRBOSS.AircraftCarrier.AV8B then
    if AOA > acaoa.SLOW then
      -- "Your're slow!"
      self:RadioTransmission( self.LSORadio, self.LSOCall.SLOW, true, nil, nil, true )
      advice = advice + self.LSOCall.SLOW.duration
      -- S=underline("SLO")
    elseif AOA > acaoa.Slow then
      -- "Your're slow."
      self:RadioTransmission( self.LSORadio, self.LSOCall.SLOW, false, nil, nil, true )
      advice = advice + self.LSOCall.SLOW.duration
      -- S="SLO"
    elseif AOA > acaoa.OnSpeedMax then
      -- No call.
      -- S=little("SLO")
    elseif AOA < acaoa.FAST then
      -- "You're fast!"
      self:RadioTransmission( self.LSORadio, self.LSOCall.FAST, true, nil, nil, true )
      advice = advice + self.LSOCall.FAST.duration
      -- S=underline("F")
    elseif AOA < acaoa.Fast then
      -- "You're fast."
      self:RadioTransmission( self.LSORadio, self.LSOCall.FAST, false, nil, nil, true )
      advice = advice + self.LSOCall.FAST.duration
      -- S="F"
    elseif AOA < acaoa.OnSpeedMin then
      -- No Call.
      -- S=little("F")
    end
  end

  -- Set last time.
  playerData.Tlso = timer.getTime()
end

--- Grade player time in the groove - from turning to final until touchdown.
--
-- If time
--
-- * < 9 seconds: No Grade "--"
-- * 9-11 seconds: Fair "(OK)"
-- * 12-21 seconds: OK (15-18 is ideal)
-- * 22-24 seconds: Fair "(OK)
-- * > 24 seconds: No Grade "--"
--
-- If you manage to be between 16.4 and and 16.6 seconds, you will even get and okay underline "\_OK\_".
-- No groove time for Harrier on LHA, LHD set to Tgroove Unicorn as starting point to allow possible _OK_ 5.0.
--
-- If time in the AV-8B
--
-- * < 55 seconds: Fast V/STOL
-- * < 75 seconds: OK V/STOL
-- * > 76 Seconds: SLOW V/STOL (Early hover stop selection)
--
-- If you manage to be between 60.0 and 65.0 seconds in the AV-8B, you will even get and okay underline "\_OK\_"
--
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #string LSO grade for time in groove, i.e. \_OK\_, OK, (OK), --.
function AIRBOSS:_EvalGrooveTime( playerData )

  -- Time in groove.
  local t = playerData.Tgroove

  local grade = ""
  if t < 9 then
    grade = "_NESA_"
  elseif t < 15 then
    grade = "NESA"
  elseif t < 19 then
    grade = "OK Groove"
  elseif t <= 24 then
    grade = "(LIG)"
    -- Time in groove for AV-8B
  elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B and t < 55 then -- VSTOL Late Hover stop selection too fast to Abeam LDG Spot AV-8B.
    grade = "FAST V/STOL Groove"
  elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B and t < 75 then -- VSTOL Operations with AV-8B.
    grade = "OK V/STOL Groove"
  elseif playerData.actype == AIRBOSS.AircraftCarrier.AV8B and t >= 76 then -- VSTOL Early Hover stop selection slow to Abeam LDG Spot AV-8B.
    grade = "SLOW V/STOL Groove"
  else
    grade = "LIG"
  end

  -- The unicorn!
  if t >= 16.4 and t <= 16.6 then
    grade = "_OK_"
  end

  -- V/STOL Unicorn!
  if playerData.actype == AIRBOSS.AircraftCarrier.AV8B and (t >= 60.0 and t <= 65.0) then
    grade = "_OK_ V/STOL"
  end

  return grade
end

--- Grade approach.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #string LSO grade, i.g. _OK_, OK, (OK), --, etc.
-- @return #number Points.
-- @return #string LSO analysis of flight path.
function AIRBOSS:_LSOgrade( playerData )

  --- Count deviations.
  local function count( base, pattern )
    return select( 2, string.gsub( base, pattern, "" ) )
  end

  -- Analyse flight data and convert to LSO text.
  local GXX, nXX = self:_Flightdata2Text( playerData, AIRBOSS.GroovePos.XX )
  local GIM, nIM = self:_Flightdata2Text( playerData, AIRBOSS.GroovePos.IM )
  local GIC, nIC = self:_Flightdata2Text( playerData, AIRBOSS.GroovePos.IC )
  local GAR, nAR = self:_Flightdata2Text( playerData, AIRBOSS.GroovePos.AR )

  -- Put everything together.
  local G = GXX .. " " .. GIM .. " " .. " " .. GIC .. " " .. GAR

  -- Count number of minor, normal and major deviations.
  local N=nXX+nIM+nIC+nAR
  local Nv=nXX+nIM
  local nL=count(G, '_')/2
  local nS=count(G, '%(')
  local nN=N-nS-nL
  local nNv=Nv-nS-nL
  
  -- Groove time 15-18.99 sec for a unicorn. Or 60-65 for V/STOL unicorn.
  local Tgroove=playerData.Tgroove
  local TgrooveUnicorn=Tgroove and (Tgroove>=15.0 and Tgroove<=18.99) or false
  local TgrooveVstolUnicorn=Tgroove and (Tgroove>=60.0 and Tgroove<=65.0)and playerData.actype==AIRBOSS.AircraftCarrier.AV8B or false

  local grade
  local points
  if N == 0 and (TgrooveUnicorn or TgrooveVstolUnicorn or playerData.case==3) then
    -- No deviations, should be REALLY RARE!
    grade = "_OK_"
    points = 5.0
    G = "Unicorn"
  else

    -- Add AV-8B Harrier devation allowances due to lower groundspeed and 3x conventional groove time, this allows to maintain LSO tolerances while respecting the deviations are not unsafe.--Pene testing
      -- Large devaitions still result in a No Grade, A Unicorn still requires a clean pass with no deviation.
  if nL > 1 and playerData.actype==AIRBOSS.AircraftCarrier.AV8B then
      -- Larger deviations ==> "No grade" 2.0 points.
      grade="--"
      points=2.0
  elseif nNv >= 1 and playerData.actype==AIRBOSS.AircraftCarrier.AV8B then
      -- Only average deviations ==>  "Fair Pass" Pass with average deviations and corrections.
      grade="(OK)"
      points=3.0
  elseif nNv < 1 and playerData.actype==AIRBOSS.AircraftCarrier.AV8B then
      -- Only minor average deviations ==>  "OK" Pass with minor deviations and corrections. (test nNv<=1 and)
      grade="OK"
      points=4.0
  elseif nL > 0 then
      -- Larger deviations ==> "No grade" 2.0 points.
      grade="--"
      points=2.0
  elseif nN> 0 then
      -- No larger but average deviations ==>  "Fair Pass" Pass with average deviations and corrections.
      grade="(OK)"
      points=3.0
  else
      -- Only minor corrections
      grade="OK"
      points=4.0
  end

  end

  -- Replace" )"( and "__"
  G = G:gsub( "%)%(", "" )
  G = G:gsub( "__", "" )

  -- Debug info
  local text = "LSO grade:\n"
  text = text .. G .. "\n"
  text = text .. "Grade = " .. grade .. " points = " .. points .. "\n"
  text = text .. "# of total deviations   = " .. N .. "\n"
  text = text .. "# of large deviations _ = " .. nL .. "\n"
  text = text .. "# of normal deviations  = " .. nN .. "\n"
  text = text .. "# of small deviations ( = " .. nS .. "\n"
  self:T2( self.lid .. text )

  -- Special cases.
  if playerData.wop then
    ---------------------
    -- Pattern Waveoff --
    ---------------------
    if playerData.lig then
      -- Long In the Groove (LIG).
      -- According to Stingers this is a CUT pass and gives 1.0 points.
      grade = "WO"
      points = 1.0
      G = "LIG"
    else
      -- Other pattern WO
      grade = "WOP"
      points = 2.0
      G = "n/a"
    end
  elseif playerData.wofd then
    -----------------------
    -- Foul Deck Waveoff --
    -----------------------
    if playerData.landed then
      -- AIRBOSS wants to talk to you!
      grade = "CUT"
      points = 0.0
    else
      grade = "WOFD"
      points = -1.0
    end
    G = "n/a"
  elseif playerData.owo then
    -----------------
    -- Own Waveoff --
    -----------------
    grade = "OWO"
    points = 2.0
    if N == 0 then
      G = "n/a"
    end
  elseif playerData.waveoff then
    -------------
    -- Waveoff --
    -------------
    if playerData.landed then
      -- AIRBOSS wants to talk to you!
      grade = "CUT"
      points = 0.0
    else
      grade = "WO"
      points = 1.0
    end
  elseif playerData.boltered then
    -- Bolter
    grade = "-- (BOLTER)"
    points = 2.5

  elseif not playerData.hover and playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
    -------------------------------
    -- AV-8B not cleared to land -- -- Landing clearence is carrier from LC to Landing 
    -------------------------------
    if playerData.landed then
      -- AIRBOSS wants your balls!
      grade = "CUT"
      points = 0.0
    end

  end
  return grade, points, G
end

--- Grade flight data.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string groovestep Step in the groove.
-- @param #AIRBOSS.GrooveData fdata Flight data in the groove.
-- @return #string LSO grade or empty string if flight data table is nil.
-- @return #number Number of deviations from perfect flight path.
function AIRBOSS:_Flightdata2Text( playerData, groovestep )

  local function little( text )
    return string.format( "(%s)", text )
  end
  local function underline( text )
    return string.format( "_%s_", text )
  end

  -- Groove Data.
  local fdata = playerData.groove[groovestep] -- #AIRBOSS.GrooveData

  -- No flight data ==> return empty string.
  if fdata == nil then
    self:T3( self.lid .. "Flight data is nil." )
    return "", 0
  end

  -- Flight data.
  local step = fdata.Step
  local AOA = fdata.AoA
  local GSE = fdata.GSE
  local LUE = fdata.LUE
  local ROL = fdata.Roll

  -- Aircraft specific AoA values.
  local acaoa = self:_GetAircraftAoA( playerData )

  -- Angled Approach.
  local P = nil
  if step == AIRBOSS.PatternStep.GROOVE_XX and ROL <= 4.0 and playerData.case < 3 then
    if LUE > self.lue.RIGHT then
      P = underline( "AA" )
    elseif LUE > self.lue.RightMed then
      P = "AA "
    elseif LUE > self.lue.Right then
      P = little( "AA" )
    end
  end

  -- Overshoot Start.
  local O = nil
  if step == AIRBOSS.PatternStep.GROOVE_XX then
    if LUE < self.lue.LEFT then
      O = underline( "OS" )
    elseif LUE < self.lue.Left then
      O = "OS"
    elseif LUE < self.lue._min then
      O = little( "OS" )
    end
  end

  -- Speed via AoA. Depends on aircraft type.
  local S = nil
  if AOA > acaoa.SLOW then
    S = underline( "SLO" )
  elseif AOA > acaoa.Slow then
    S = "SLO"
  elseif AOA > acaoa.OnSpeedMax then
    S = little( "SLO" )
  elseif AOA < acaoa.FAST then
    S = underline( "F" )
  elseif AOA < acaoa.Fast then
    S = "F"
  elseif AOA < acaoa.OnSpeedMin then
    S = little( "F" )
  end

  -- Glideslope/altitude. Good [-0.3, 0.4] asymmetric!
  local A = nil
  if GSE > self.gle.HIGH then
    A = underline( "H" )
  elseif GSE > self.gle.High then
    A = "H"
  elseif GSE > self.gle._max then
    A = little( "H" )
  elseif GSE < self.gle.LOW then
    A = underline( "LO" )
  elseif GSE < self.gle.Low then
    A = "LO"
  elseif GSE < self.gle._min then
    A = little( "LO" )
  end

  -- Line up. XX Step replaced by Overshoot start (OS). Good [-0.5, 0.5]
  local D = nil
  if LUE > self.lue.RIGHT then
    D = underline( "LUL" )
  elseif LUE > self.lue.Right then
    D = "LUL"
  elseif LUE > self.lue._max then
    D = little( "LUL" )
  elseif playerData.case < 3 then
    if LUE < self.lue.LEFT and step ~= AIRBOSS.PatternStep.GROOVE_XX then
      D = underline( "LUR" )
    elseif LUE < self.lue.Left and step ~= AIRBOSS.PatternStep.GROOVE_XX then
      D = "LUR"
    elseif LUE < self.lue._min and step ~= AIRBOSS.PatternStep.GROOVE_XX then
      D = little( "LUR" )
    end
  elseif playerData.case == 3 then
    if LUE < self.lue.LEFT then
      D = underline( "LUR" )
    elseif LUE < self.lue.Left then
      D = "LUR"
    elseif LUE < self.lue._min then
      D = little( "LUR" )
    end
  end

  -- Compile.
  local G = ""
  local n = 0
  -- Fly trough.
  if fdata.FlyThrough then
    G = G .. fdata.FlyThrough
  end
  -- Angled Approach - doesn't affect score, advisory only.
  if P then
    G = G .. P
    n = n
  end
  -- Speed.
  if S then
    G = G .. S
    n = n + 1
  end
  -- Glide slope.
  if A then
    G = G .. A
    n = n + 1
  end
  -- Line up.
  if D then
    G = G .. D
    n = n + 1
  end
  -- Drift in Lineup
  if fdata.Drift then
    G = G .. fdata.Drift
    n = n -- Drift doesn't affect score, advisory only.
  end
  -- Overshoot.
  if O then
    G = G .. O
    n = n + 1
  end

  -- Add current step.
  local step = self:_GS( step )
  step = step:gsub( "XX", "X" )
  if G ~= "" then
    G = G .. step
  end

  -- Debug info.
  local text = string.format( "LSO Grade at %s:\n", step )
  text = text .. string.format( "AOA=%.1f\n", AOA )
  text = text .. string.format( "GSE=%.1f\n", GSE )
  text = text .. string.format( "LUE=%.1f\n", LUE )
  text = text .. string.format( "ROL=%.1f\n", ROL )
  text = text .. G
  self:T3( self.lid .. text )

  return G, n
end

--- Get short name of the grove step.
-- @param #AIRBOSS self
-- @param #string step Player step.
-- @param #number n Use -1 for previous or +1 for next. Default 0.
-- @return #string Shortcut name "X", "RB", "IM", "AR", "IW".
function AIRBOSS:_GS( step, n )
  local gp
  n = n or 0

  if step == AIRBOSS.PatternStep.FINAL then
    gp = AIRBOSS.GroovePos.X0 -- "X0"  -- Entering the groove.
    if n == -1 then
      gp = AIRBOSS.GroovePos.X0 -- There is no previous step.
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.XX
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_XX then
    gp = AIRBOSS.GroovePos.XX -- "XX"  -- Starting the groove.
    if n == -1 then
      gp = AIRBOSS.GroovePos.X0
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.IM
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_IM then
    gp = AIRBOSS.GroovePos.IM -- "IM"  -- In the middle.
    if n == -1 then
      gp = AIRBOSS.GroovePos.XX
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.IC
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_IC then
    gp = AIRBOSS.GroovePos.IC -- "IC"  -- In close.
    if n == -1 then
      gp = AIRBOSS.GroovePos.IM
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.AR
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_AR then
    gp = AIRBOSS.GroovePos.AR -- "AR"  -- At the ramp.
    if n == -1 then
      gp = AIRBOSS.GroovePos.IC
    elseif n == 1 then
      if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
        gp = AIRBOSS.GroovePos.AL
      else
        gp = AIRBOSS.GroovePos.IW
      end
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_AL then
    gp = AIRBOSS.GroovePos.AL -- "AL"  -- Abeam landing spot.
    if n == -1 then
      gp = AIRBOSS.GroovePos.AR
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.LC
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_LC then
    gp = AIRBOSS.GroovePos.LC -- "LC"  -- Level crossing.
    if n == -1 then
      gp = AIRBOSS.GroovePos.AL
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.LC
    end
  elseif step == AIRBOSS.PatternStep.GROOVE_IW then
    gp = AIRBOSS.GroovePos.IW -- "IW"  -- In the wires.
    if n == -1 then
      gp = AIRBOSS.GroovePos.AR
    elseif n == 1 then
      gp = AIRBOSS.GroovePos.IW -- There is no next step.
    end
  end
  return gp
end

--- Check if a player is within the right area.
-- @param #AIRBOSS self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint pos Position data limits.
-- @return #boolean If true, approach should be aborted.
function AIRBOSS:_CheckAbort( X, Z, pos )

  local abort = false
  if pos.Xmin and X < pos.Xmin then
    self:T( string.format( "Xmin: X=%d < %d=Xmin", X, pos.Xmin ) )
    abort = true
  elseif pos.Xmax and X > pos.Xmax then
    self:T( string.format( "Xmax: X=%d > %d=Xmax", X, pos.Xmax ) )
    abort = true
  elseif pos.Zmin and Z < pos.Zmin then
    self:T( string.format( "Zmin: Z=%d < %d=Zmin", Z, pos.Zmin ) )
    abort = true
  elseif pos.Zmax and Z > pos.Zmax then
    self:T( string.format( "Zmax: Z=%d > %d=Zmax", Z, pos.Zmax ) )
    abort = true
  end

  return abort
end

--- Generate a text if a player is too far from where he should be.
-- @param #AIRBOSS self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint posData Checkpoint data.
function AIRBOSS:_TooFarOutText( X, Z, posData )

  -- Intro.
  local text = "you are too "

  -- X text.
  local xtext = nil
  if posData.Xmin and X < posData.Xmin then
    if posData.Xmin <= 0 then
      xtext = "far behind "
    else
      xtext = "close to "
    end
  elseif posData.Xmax and X > posData.Xmax then
    if posData.Xmax >= 0 then
      xtext = "far ahead of "
    else
      xtext = "close to "
    end
  end

  -- Z text.
  local ztext = nil
  if posData.Zmin and Z < posData.Zmin then
    if posData.Zmin <= 0 then
      ztext = "far port of "
    else
      ztext = "close to "
    end
  elseif posData.Zmax and Z > posData.Zmax then
    if posData.Zmax >= 0 then
      ztext = "far starboard of "
    else
      ztext = "too close to "
    end
  end

  -- Combine X-Z text.
  if xtext and ztext then
    text = text .. xtext .. " and " .. ztext
  elseif xtext then
    text = text .. xtext
  elseif ztext then
    text = text .. ztext
  end

  -- Complete the sentence
  text = text .. "the carrier."

  -- If no case could be identified.
  if xtext == nil and ztext == nil then
    text = "you are too far from where you should be!"
  end

  return text
end

--- Pattern aborted.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #AIRBOSS.Checkpoint posData Checkpoint data.
-- @param #boolean patternwo (Optional) Pattern wave off.
function AIRBOSS:_AbortPattern( playerData, X, Z, posData, patternwo )

  -- Text where we are wrong.
  local text = self:_TooFarOutText( X, Z, posData )

  -- Debug.
  local dtext = string.format( "Abort: X=%d Xmin=%s, Xmax=%s | Z=%d Zmin=%s Zmax=%s", X, tostring( posData.Xmin ), tostring( posData.Xmax ), Z, tostring( posData.Zmin ), tostring( posData.Zmax ) )
  self:T( self.lid .. dtext )

  -- Message to player.
  self:MessageToPlayer( playerData, text, "LSO" )

  if patternwo then

    -- Pattern wave off!
    playerData.wop = true

    -- Add to debrief.
    self:_AddToDebrief( playerData, string.format( "Pattern wave off: %s", text ) )

    -- Depart and re-enter radio message.
    -- TODO: Radio should depend on player step.
    self:RadioTransmission( self.LSORadio, self.LSOCall.DEPARTANDREENTER, false, 3, nil, nil, true )

    -- Next step debrief.
    playerData.step = AIRBOSS.PatternStep.DEBRIEF
    playerData.warning = nil
  end

end

--- Display hint to player.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number delay Delay before playing sound messages. Default 0 sec.
-- @param #boolean soundoff If true, don't play and sound hint.
function AIRBOSS:_PlayerHint( playerData, delay, soundoff )

  -- No hint for the pros.
  if not playerData.showhints then
    return
  end

  -- Get optimal altitude, distance and speed.
  local alt, aoa, dist, speed = self:_GetAircraftParameters( playerData )

  -- Get altitude hint.
  local hintAlt, debriefAlt, callAlt = self:_AltitudeCheck( playerData, alt )

  -- Get speed hint.
  local hintSpeed, debriefSpeed, callSpeed = self:_SpeedCheck( playerData, speed )

  -- Get AoA hint.
  local hintAoA, debriefAoA, callAoA = self:_AoACheck( playerData, aoa )

  -- Get distance to the boat hint.
  local hintDist, debriefDist, callDist = self:_DistanceCheck( playerData, dist )

  -- Message to player.
  local hint = ""
  if hintAlt and hintAlt ~= "" then
    hint = hint .. "\n" .. hintAlt
  end
  if hintSpeed and hintSpeed ~= "" then
    hint = hint .. "\n" .. hintSpeed
  end
  if hintAoA and hintAoA ~= "" then
    hint = hint .. "\n" .. hintAoA
  end
  if hintDist and hintDist ~= "" then
    hint = hint .. "\n" .. hintDist
  end

  -- Debriefing text.
  local debrief = ""
  if debriefAlt and debriefAlt ~= "" then
    debrief = debrief .. "\n- " .. debriefAlt
  end
  if debriefSpeed and debriefSpeed ~= "" then
    debrief = debrief .. "\n- " .. debriefSpeed
  end
  if debriefAoA and debriefAoA ~= "" then
    debrief = debrief .. "\n- " .. debriefAoA
  end
  if debriefDist and debriefDist ~= "" then
    debrief = debrief .. "\n- " .. debriefDist
  end

  -- Add step to debriefing.
  if debrief ~= "" then
    self:_AddToDebrief( playerData, debrief )
  end

  -- Voice hint.
  delay = delay or 0
  if not soundoff then
    if callAlt then
      self:Sound2Player( playerData, self.LSORadio, callAlt, false, delay )
      delay = delay + callAlt.duration + 0.5
    end
    if callSpeed then
      self:Sound2Player( playerData, self.LSORadio, callSpeed, false, delay )
      delay = delay + callSpeed.duration + 0.5
    end
    if callAoA then
      self:Sound2Player( playerData, self.LSORadio, callAoA, false, delay )
      delay = delay + callAoA.duration + 0.5
    end
    if callDist then
      self:Sound2Player( playerData, self.LSORadio, callDist, false, delay )
      delay = delay + callDist.duration + 0.5
    end
  end

  -- ARC IN info.
  if playerData.step == AIRBOSS.PatternStep.ARCIN then

    -- Hint turn and set TACAN.
    if playerData.difficulty == AIRBOSS.Difficulty.EASY then
      -- Get inverse magnetic radial without offset ==> FB for Case II or BRC for Case III.
      local radial = self:GetRadial( playerData.case, true, false, true )
      local turn = "right"
      if self.holdingoffset < 0 then
        turn = "left"
      end
      hint = hint .. string.format( "\nTurn %s and select TACAN %03d°.", turn, radial )
    end

  end

  -- DIRTUP additonal info.
  if playerData.step == AIRBOSS.PatternStep.DIRTYUP then
    if playerData.difficulty == AIRBOSS.Difficulty.EASY then
      if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
        hint = hint .. "\nFAF! Checks completed. Nozzles 50°."
      else
        -- TODO: Tomcat?
        hint = hint .. "\nDirty up! Hook, gear and flaps down."
      end
    end
  end

  -- BULLSEYE additonal info.
  if playerData.step == AIRBOSS.PatternStep.BULLSEYE then
    -- Hint follow the needles.
    if playerData.difficulty == AIRBOSS.Difficulty.EASY then
      if   playerData.actype == AIRBOSS.AircraftCarrier.HORNET
        or playerData.actype == AIRBOSS.AircraftCarrier.RHINOE
        or playerData.actype == AIRBOSS.AircraftCarrier.RHINOF
        or playerData.actype == AIRBOSS.AircraftCarrier.GROWLER then
        hint = hint .. string.format( "\nIntercept glideslope and follow the needles." )
      else
        hint = hint .. string.format( "\nIntercept glideslope." )
      end
    end
  end

  -- Message to player.
  if hint ~= "" then
    local text = string.format( "%s%s", playerData.step, hint )
    self:MessageToPlayer( playerData, hint, "AIRBOSS", "" )
  end
end

--- Display hint for flight students about the (next) step. Message is displayed after one second.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string step Step for which hint is given.
function AIRBOSS:_StepHint( playerData, step )

  -- Set step.
  step = step or playerData.step

  -- Message is only for "Flight Students".
  if playerData.difficulty == AIRBOSS.Difficulty.EASY and playerData.showhints then

    -- Get optimal parameters at step.
    local alt, aoa, dist, speed = self:_GetAircraftParameters( playerData, step )

    -- Hint:
    local hint = ""

    -- Altitude.
    if alt then
      hint = hint .. string.format( "\nAltitude %d ft", UTILS.MetersToFeet( alt ) )
    end

    -- AoA.
    if aoa then
      hint = hint .. string.format( "\nAoA %.1f", self:_AoADeg2Units( playerData, aoa ) )
    end

    -- Speed.
    if speed then
      hint = hint .. string.format( "\nSpeed %d knots", UTILS.MpsToKnots( speed ) )
    end

    -- Distance to the boat.
    if dist then
      hint = hint .. string.format( "\nDistance to the boat %.1f NM", UTILS.MetersToNM( dist ) )
    end

    -- Late break.
    if step == AIRBOSS.PatternStep.LATEBREAK then
      if playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B then
        hint = hint .. "\nWing Sweep 20°, Gear DOWN < 280 KIAS."
      end
    end

    -- Abeam.
    if step == AIRBOSS.PatternStep.ABEAM then
      if playerData.actype == AIRBOSS.AircraftCarrier.AV8B then
        hint = hint .. "\nNozzles 50°-60°. Antiskid OFF. Lights OFF."
      elseif playerData.actype == AIRBOSS.AircraftCarrier.F14A or playerData.actype == AIRBOSS.AircraftCarrier.F14B then
        hint = hint .. "\nSlats/Flaps EXTENDED < 225 KIAS. DLC SELECTED. Auto Throttle IF DESIRED."
      else
        hint = hint .. "\nDirty up! Gear DOWN, flaps DOWN. Check hook down."
      end
    end

    -- Check if there was actually anything to tell.
    if hint ~= "" then

      -- Compile text if any.
      local text = string.format( "Optimal setup at next step %s:%s", step, hint )

      -- Send hint to player.
      self:MessageToPlayer( playerData, text, "AIRBOSS", "", nil, false, 1 )

    end

  end
end

--- Evaluate player's altitude at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number altopt Optimal altitude in meters.
-- @return #string Feedback text.
-- @return #string Debriefing text.
-- @return #AIRBOSS.RadioCall Radio call.
function AIRBOSS:_AltitudeCheck( playerData, altopt )

  if altopt == nil then
    return nil, nil
  end

  -- Player altitude.
  local altitude = playerData.unit:GetAltitude()

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore( playerData )

  -- Altitude error +-X%
  local _error = (altitude - altopt) / altopt * 100

  -- Radio call for flight students.
  local radiocall = nil -- #AIRBOSS.RadioCall

  local hint = ""
  if _error > badscore then
    -- hint=string.format("You're high.")
    radiocall = self:_NewRadioCall( self.LSOCall.HIGH, "Paddles", "" )
  elseif _error > lowscore then
    -- hint= string.format("You're slightly high.")
    radiocall = self:_NewRadioCall( self.LSOCall.HIGH, "Paddles", "" )
  elseif _error < -badscore then
    -- hint=string.format("You're low. ")
    radiocall = self:_NewRadioCall( self.LSOCall.LOW, "Paddles", "" )
  elseif _error < -lowscore then
    -- hint=string.format("You're slightly low.")
    radiocall = self:_NewRadioCall( self.LSOCall.LOW, "Paddles", "" )
  else
    hint = string.format( "Good altitude. " )
  end

  -- Extend or decrease depending on skill.
  if playerData.difficulty == AIRBOSS.Difficulty.EASY then
    -- Also inform students about the optimal altitude.
    hint = hint .. string.format( "Optimal altitude is %d ft.", UTILS.MetersToFeet( altopt ) )
  elseif playerData.difficulty == AIRBOSS.Difficulty.NORMAL then
    -- We keep it short normally.
    hint = ""
  elseif playerData.difficulty == AIRBOSS.Difficulty.HARD then
    -- No hint at all for the pros.
    hint = ""
  end

  -- Debrief text.
  local debrief = string.format( "Altitude %d ft = %d%% deviation from %d ft.", UTILS.MetersToFeet( altitude ), _error, UTILS.MetersToFeet( altopt ) )

  return hint, debrief, radiocall
end

--- Score for correct AoA.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #number optaoa Optimal AoA.
-- @return #string Feedback message text or easy and normal difficulty level or nil for hard.
-- @return #string Debriefing text.
-- @return #AIRBOSS.RadioCall Radio call.
function AIRBOSS:_AoACheck( playerData, optaoa )

  if optaoa == nil then
    return nil, nil
  end

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore( playerData )

  -- Player AoA
  local aoa = playerData.unit:GetAoA()

  -- Altitude error +-X%
  local _error = (aoa - optaoa) / optaoa * 100

  -- Get aircraft AoA parameters.
  local aircraftaoa = self:_GetAircraftAoA( playerData )

  -- Radio call for flight students.
  local radiocall = nil -- #AIRBOSS.RadioCall

  -- Rate aoa.
  local hint = ""
  if aoa >= aircraftaoa.SLOW then
    -- hint="Your're slow!"
    radiocall = self:_NewRadioCall( self.LSOCall.SLOW, "Paddles", "" )
  elseif aoa >= aircraftaoa.Slow then
    -- hint="Your're slow."
    radiocall = self:_NewRadioCall( self.LSOCall.SLOW, "Paddles", "" )
  elseif aoa >= aircraftaoa.OnSpeedMax then
    hint = "Your're a little slow. "
  elseif aoa >= aircraftaoa.OnSpeedMin then
    hint = "You're on speed. "
  elseif aoa >= aircraftaoa.Fast then
    hint = "You're a little fast. "
  elseif aoa >= aircraftaoa.FAST then
    -- hint="Your're fast."
    radiocall = self:_NewRadioCall( self.LSOCall.FAST, "Paddles", "" )
  else
    -- hint="You're fast!"
    radiocall = self:_NewRadioCall( self.LSOCall.FAST, "Paddles", "" )
  end

  -- Extend or decrease depending on skill.
  if playerData.difficulty == AIRBOSS.Difficulty.EASY then
    -- Also inform students about optimal value.
    hint = hint .. string.format( "Optimal AoA is %.1f.", self:_AoADeg2Units( playerData, optaoa ) )
  elseif playerData.difficulty == AIRBOSS.Difficulty.NORMAL then
    -- We keep is short normally.
    hint = ""
  elseif playerData.difficulty == AIRBOSS.Difficulty.HARD then
    -- No hint at all for the pros.
    hint = ""
  end

  -- Debriefing text.
  local debrief = string.format( "AoA %.1f = %d%% deviation from %.1f.", self:_AoADeg2Units( playerData, aoa ), _error, self:_AoADeg2Units( playerData, optaoa ) )

  return hint, debrief, radiocall
end

--- Evaluate player's speed.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number speedopt Optimal speed in m/s.
-- @return #string Feedback text.
-- @return #string Debriefing text.
-- @return #AIRBOSS.RadioCall Radio call.
function AIRBOSS:_SpeedCheck( playerData, speedopt )

  if speedopt == nil then
    return nil, nil
  end

  -- Player altitude.
  local speed = playerData.unit:GetVelocityMPS()

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore( playerData )

  -- Altitude error +-X%
  local _error = (speed - speedopt) / speedopt * 100

  -- Radio call for flight students.
  local radiocall = nil -- #AIRBOSS.RadioCall

  local hint = ""
  if _error > badscore then
    -- hint=string.format("You're fast.")
    radiocall = self:_NewRadioCall( self.LSOCall.FAST, "AIRBOSS", "" )
  elseif _error > lowscore then
    -- hint= string.format("You're slightly fast.")
    radiocall = self:_NewRadioCall( self.LSOCall.FAST, "AIRBOSS", "" )
  elseif _error < -badscore then
    -- hint=string.format("You're slow.")
    radiocall = self:_NewRadioCall( self.LSOCall.SLOW, "AIRBOSS", "" )
  elseif _error < -lowscore then
    -- hint=string.format("You're slightly slow.")
    radiocall = self:_NewRadioCall( self.LSOCall.SLOW, "AIRBOSS", "" )
  else
    hint = string.format( "Good speed. " )
  end

  -- Extend or decrease depending on skill.
  if playerData.difficulty == AIRBOSS.Difficulty.EASY then
    hint = hint .. string.format( "Optimal speed is %d knots.", UTILS.MpsToKnots( speedopt ) )
  elseif playerData.difficulty == AIRBOSS.Difficulty.NORMAL then
    -- We keep is short normally.
    hint = ""
  elseif playerData.difficulty == AIRBOSS.Difficulty.HARD then
    -- No hint at all for pros.
    hint = ""
  end

  -- Debrief text.
  local debrief = string.format( "Speed %d knots = %d%% deviation from %d knots.", UTILS.MpsToKnots( speed ), _error, UTILS.MpsToKnots( speedopt ) )

  return hint, debrief, radiocall
end

--- Evaluate player's distance to the boat at checkpoint.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #number optdist Optimal distance in meters.
-- @return #string Feedback message text.
-- @return #string Debriefing text.
-- @return #AIRBOSS.RadioCall Distance radio call. Not implemented yet.
function AIRBOSS:_DistanceCheck( playerData, optdist )

  if optdist == nil then
    return nil, nil
  end

  -- Distance to carrier.
  local distance = playerData.unit:GetCoordinate():Get2DDistance( self:GetCoordinate() )

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore( playerData )

  -- Altitude error +-X%
  local _error = (distance - optdist) / optdist * 100

  local hint
  if _error > badscore then
    hint = string.format( "You're too far from the boat!" )
  elseif _error > lowscore then
    hint = string.format( "You're slightly too far from the boat." )
  elseif _error < -badscore then
    hint = string.format( "You're too close to the boat!" )
  elseif _error < -lowscore then
    hint = string.format( "You're slightly too far from the boat." )
  else
    hint = string.format( "Good distance to the boat." )
  end

  -- Extend or decrease depending on skill.
  if playerData.difficulty == AIRBOSS.Difficulty.EASY then
    -- Also inform students about optimal value.
    hint = hint .. string.format( " Optimal distance is %.1f NM.", UTILS.MetersToNM( optdist ) )
  elseif playerData.difficulty == AIRBOSS.Difficulty.NORMAL then
    -- We keep it short normally.
    hint = ""
  elseif playerData.difficulty == AIRBOSS.Difficulty.HARD then
    -- No hint at all for the pros.
    hint = ""
  end

  -- Debriefing text.
  local debrief = string.format( "Distance %.1f NM = %d%% deviation from %.1f NM.", UTILS.MetersToNM( distance ), _error, UTILS.MetersToNM( optdist ) )

  return hint, debrief, nil
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DEBRIEFING
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Append text to debriefing.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string hint Debrief text of this step.
-- @param #string step (Optional) Current step in the pattern. Default from playerData.
function AIRBOSS:_AddToDebrief( playerData, hint, step )
  step = step or playerData.step
  table.insert( playerData.debrief, { step = step, hint = hint } )
end

--- Debrief player and set next step.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
function AIRBOSS:_Debrief( playerData )
  self:F( self.lid .. string.format( "Debriefing of player %s.", playerData.name ) )

  -- Delete scheduler ID.
  playerData.debriefschedulerID = nil

  -- Switch attitude monitor off if on.
  playerData.attitudemonitor = false

  -- LSO grade, points, and flight data analyis.
  local grade, points, analysis = self:_LSOgrade( playerData )

  -- Insert points to table of all points until player landed.
  if points and points >= 0 then
    table.insert( playerData.points, points )
  end

  -- Player has landed and is not airborne any more.
  local Points = 0
  if playerData.landed and not playerData.unit:InAir() then

    -- Average over all points received so far.
    for _, _points in pairs( playerData.points ) do
      Points = Points + _points
    end

    -- This is the final points.
    Points = Points / #playerData.points

    -- Reset points array.
    playerData.points = {}
  else
    -- Player boltered or was waved off ==> We display the normal points.
    Points = points
  end

  -- My LSO grade.
  local mygrade = {} -- #AIRBOSS.LSOgrade
  mygrade.grade = grade
  mygrade.points = points
  mygrade.details = analysis
  mygrade.wire = playerData.wire
  mygrade.Tgroove = playerData.Tgroove
  if playerData.landed and not playerData.unit:InAir() then
    mygrade.finalscore = Points
  end
  mygrade.case = playerData.case
  local windondeck = self:GetWindOnDeck()
  mygrade.wind = UTILS.Round( UTILS.MpsToKnots( windondeck ), 1 )
  mygrade.modex = playerData.onboard
  mygrade.airframe = playerData.actype
  mygrade.carriertype = self.carriertype
  mygrade.carriername = self.alias
  mygrade.carrierrwy  = self.carrierparam.rwyangle
  mygrade.theatre = self.theatre
  mygrade.mitime = UTILS.SecondsToClock( timer.getAbsTime(), true )
  mygrade.midate = UTILS.GetDCSMissionDate()
  mygrade.osdate = "n/a"
  if os then
    mygrade.osdate = os.date() -- os.date("%d.%m.%Y")
  end

  -- Add last grade to playerdata for FunkMan.
  playerData.grade=mygrade

  -- Save trap sheet.
  if playerData.trapon and self.trapsheet then
    self:_SaveTrapSheet( playerData, mygrade )
  end

  -- Add LSO grade to player grades table.
  table.insert( self.playerscores[playerData.name], mygrade )

  -- Trigger grading event.
  self:LSOGrade( playerData, mygrade )

  -- LSO grade: (OK) 3.0 PT - LURIM
  local text = string.format( "%s %.1f PT - %s", grade, Points, analysis )
  if Points == -1 then
    text = string.format( "%s n/a PT - Foul deck", grade, Points, analysis )
  end

  -- Wire and Groove time only if not pattern WO.
  if not (playerData.wop or playerData.wofd) then

    -- Wire trapped. Not if pattern WI.
    if playerData.wire and playerData.wire <= 4 then
      text = text .. string.format( " %d-wire", playerData.wire )
    end

    -- Time in the groove. Only Case I/II and not pattern WO.
    if playerData.Tgroove and playerData.Tgroove <= 360 and playerData.case < 3 then
      text = text .. string.format( "\nTime in the groove %.1f seconds: %s", playerData.Tgroove, self:_EvalGrooveTime( playerData ) )
    end

  end

  -- Copy debriefing text.
  playerData.lastdebrief = UTILS.DeepCopy( playerData.debrief )

  -- Info text.
  if playerData.difficulty == AIRBOSS.Difficulty.EASY then
    text = text .. string.format( "\nYour detailed debriefing can be found via the F10 radio menu." )
  end

  -- Message.
  self:MessageToPlayer( playerData, text, "LSO", "", 30, true )

  -- Set step to undefined and check if other cases apply.
  playerData.step = AIRBOSS.PatternStep.UNDEFINED

  -- Check what happened?
  if playerData.wop then

    ----------------------
    -- Pattern Wave Off --
    ----------------------

    -- Next step?
    -- TODO: CASE I: After bolter/wo turn left and climb to 600 ft and re-enter the pattern. But do not go to initial but reenter earlier?
    -- TODO: CASE I: After pattern wo? go back to initial, I guess?
    -- TODO: CASE III: After bolter/wo turn left and climb to 1200 ft and re-enter pattern?
    -- TODO: CASE III: After pattern wo? No idea...

    -- Can become nil when I crashed and changed to observer. Which events are captured? Nil check for unit?
    if playerData.unit:IsAlive() then

      -- Heading and distance tip.
      local heading, distance

      if playerData.case == 1 or playerData.case == 2 then

        -- Next step: Initial again.
        playerData.step = AIRBOSS.PatternStep.INITIAL

        -- Create a point 3.0 NM astern for re-entry.
        local initial = self:GetCoordinate():Translate( UTILS.NMToMeters( 3.5 ), self:GetRadial( 2, false, false, false ) )

        -- Get heading and distance to initial zone ~3 NM astern.
        heading = playerData.unit:GetCoordinate():HeadingTo( initial )
        distance = playerData.unit:GetCoordinate():Get2DDistance( initial )

      elseif playerData.case == 3 then

        -- Next step? Bullseye for now.
        -- TODO: Could be DIRTY UP or PLATFORM or even back to MARSHAL STACK?
        playerData.step = AIRBOSS.PatternStep.BULLSEYE

        -- Get heading and distance to bullseye zone ~3 NM astern.
        local zone = self:_GetZoneBullseye( playerData.case )

        heading = playerData.unit:GetCoordinate():HeadingTo( zone:GetCoordinate() )
        distance = playerData.unit:GetCoordinate():Get2DDistance( zone:GetCoordinate() )

      end

      -- Re-enter message.
      local text = string.format( "fly heading %03d° for %d NM to re-enter the pattern.", heading, UTILS.MetersToNM( distance ) )
      self:MessageToPlayer( playerData, text, "LSO", nil, nil, false, 5 )

    else

      -- Unit does not seem to be alive!
      -- TODO: What now?
      self:E( self.lid .. string.format( "ERROR: Player unit not alive!" ) )

    end

  elseif playerData.wofd then

    ---------------
    -- Foul Deck --
    ---------------

    if playerData.unit:InAir() then

      -- Bolter pattern. Then Abeam or bullseye.
      playerData.step = AIRBOSS.PatternStep.BOLTER

    else

      -- Welcome aboard!
      self:Sound2Player( playerData, self.LSORadio, self.LSOCall.WELCOMEABOARD )

      -- Airboss talkto!
      local text = string.format( "deck was fouled but you landed anyway. Airboss wants to talk to you!" )
      self:MessageToPlayer( playerData, text, "LSO", nil, nil, false, 3 )

    end

  elseif playerData.owo then

    ------------------
    -- Own Wave Off --
    ------------------

    if playerData.unit:InAir() then

      -- Bolter pattern. Then Abeam or bullseye.
      playerData.step = AIRBOSS.PatternStep.BOLTER

    else

      -- Welcome aboard!
      -- NOTE: This should not happen as owo is only triggered if player flew past the carrier.
      self:E( self.lid .. "ERROR: player landed when OWO was issues. This should not happen. Please report!" )
      self:Sound2Player( playerData, self.LSORadio, self.LSOCall.WELCOMEABOARD )

    end

  elseif playerData.waveoff then

    --------------
    -- Wave Off --
    --------------

    if playerData.unit:InAir() then

      -- Bolter pattern. Then Abeam or bullseye.
      playerData.step = AIRBOSS.PatternStep.BOLTER

    else

      -- Welcome aboard!
      self:Sound2Player( playerData, self.LSORadio, self.LSOCall.WELCOMEABOARD )

      -- Airboss talkto!
      local text = string.format( "you were waved off but landed anyway. Airboss wants to talk to you!" )
      self:MessageToPlayer( playerData, text, "LSO", nil, nil, false, 3 )

    end

  elseif playerData.boltered then

    --------------
    -- Boltered --
    --------------

    if playerData.unit:InAir() then

      -- Bolter pattern. Then Abeam or bullseye.
      playerData.step = AIRBOSS.PatternStep.BOLTER

    end

  elseif playerData.landed then

    ------------
    -- Landed --
    ------------

    if not playerData.unit:InAir() then

      -- Welcome aboard!
      self:Sound2Player( playerData, self.LSORadio, self.LSOCall.WELCOMEABOARD )

    end

  else

    -- Message to player.
    self:MessageToPlayer( playerData, "Undefined state after landing! Please report.", "ERROR", nil, 20 )

    -- Next step.
    playerData.step = AIRBOSS.PatternStep.UNDEFINED

  end

  -- Player landed and is not in air anymore.
  if playerData.landed and not playerData.unit:InAir() then
    -- Set recovered flag.
    self:_RecoveredElement( playerData.unit )

    -- Check if all elements
    self:_CheckSectionRecovered( playerData )
  end

  -- Increase number of passes.
  playerData.passes = playerData.passes + 1

  -- Next step hint for students if any.
  self:_StepHint( playerData )

  -- Reinitialize player data for new approach.
  self:_InitPlayer( playerData, playerData.step )

  -- Debug message.
  MESSAGE:New( string.format( "Player step %s.", playerData.step ), 5, "DEBUG" ):ToAllIf( self.Debug )

  -- Auto save player results.
  if self.autosave and mygrade.finalscore then
    self:Save( self.autosavepath, self.autosavefile )
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CARRIER ROUTING Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check for possible collisions between two coordinates.
-- @param #AIRBOSS self
-- @param Core.Point#COORDINATE coordto Coordinate to which the collision is check.
-- @param Core.Point#COORDINATE coordfrom Coordinate from which the collision is check.
-- @return #boolean If true, surface type ahead is not deep water.
-- @return #number Max free distance in meters.
function AIRBOSS:_CheckCollisionCoord( coordto, coordfrom )

  -- Increment in meters.
  local dx = 100

  -- From coordinate. Default 500 in front of the carrier.
  local d = 0
  if coordfrom then
    d = 0
  else
    d = 250
    coordfrom = self:GetCoordinate():Translate( d, self:GetHeading() )
  end

  -- Distance between the two coordinates.
  local dmax = coordfrom:Get2DDistance( coordto )

  -- Direction.
  local direction = coordfrom:HeadingTo( coordto )

  -- Scan path between the two coordinates.
  local clear = true
  while d <= dmax do

    -- Check point.
    local cp = coordfrom:Translate( d, direction )

    -- Check if surface type is water.
    if not cp:IsSurfaceTypeWater() then

      -- Debug mark points.
      if self.Debug then
        local st = cp:GetSurfaceType()
        cp:MarkToAll( string.format( "Collision check surface type %d", st ) )
      end

      -- Collision WARNING!
      clear = false
      break
    end

    -- Increase distance.
    d = d + dx
  end

  local text = ""
  if clear then
    text = string.format( "Path into direction %03d° is clear for the next %.1f NM.", direction, UTILS.MetersToNM( d ) )
  else
    text = string.format( "Detected obstacle at distance %.1f NM into direction %03d°.", UTILS.MetersToNM( d ), direction )
  end
  self:T2( self.lid .. text )

  return not clear, d
end

--- Check Collision.
-- @param #AIRBOSS self
-- @param Core.Point#COORDINATE fromcoord Coordinate from which the path to the next WP is calculated. Default current carrier position.
-- @return #boolean If true, surface type ahead is not deep water.
function AIRBOSS:_CheckFreePathToNextWP( fromcoord )

  -- Position.
  fromcoord = fromcoord or self:GetCoordinate():Translate( 250, self:GetHeading() )

  -- Next wp = current+1 (or last)
  local Nnextwp = math.min( self.currentwp + 1, #self.waypoints )

  -- Next waypoint.
  local nextwp = self.waypoints[Nnextwp] -- Core.Point#COORDINATE

  -- Check for collision.
  local collision = self:_CheckCollisionCoord( nextwp, fromcoord )

  return collision
end

--- Find free path to the next waypoint.
-- @param #AIRBOSS self
function AIRBOSS:_Pathfinder()

  -- Heading and current coordiante.
  local hdg = self:GetHeading()
  local cv = self:GetCoordinate()

  -- Possible directions.
  local directions = { -20, 20, -30, 30, -40, 40, -50, 50, -60, 60, -70, 70, -80, 80, -90, 90, -100, 100 }

  -- Starboard turns up to 90 degrees.
  for _, _direction in pairs( directions ) do

    -- New direction.
    local direction = hdg + _direction

    -- Check for collisions in the next 20 NM of the current direction.
    local _, dfree = self:_CheckCollisionCoord( cv:Translate( UTILS.NMToMeters( 20 ), direction ), cv )

    -- Loop over distances and find the first one which gives a clear path to the next waypoint.
    local distance = 500
    while distance <= dfree do

      -- Coordinate from which we calculate the path.
      local fromcoord = cv:Translate( distance, direction )

      -- Check for collision between point and next waypoint.
      local collision = self:_CheckFreePathToNextWP( fromcoord )

      -- Debug info.
      self:T2( self.lid .. string.format( "Pathfinder d=%.1f m, direction=%03d°, collision=%s", distance, direction, tostring( collision ) ) )

      -- If path is clear, we start a little detour.
      if not collision then
        self:CarrierDetour( fromcoord )
        return
      end

      distance = distance + 500
    end
  end
end

--- Carrier resumes the route at its next waypoint.
-- @param #AIRBOSS self
-- @param Core.Point#COORDINATE gotocoord (Optional) First goto this coordinate before resuming route.
-- @return #AIRBOSS self
function AIRBOSS:CarrierResumeRoute( gotocoord )

  -- Make carrier resume its route.
  AIRBOSS._ResumeRoute( self.carrier:GetGroup(), self, gotocoord )

  return self
end

--- Let the carrier make a detour to a given point. When it reaches the point, it will resume its normal route.
-- @param #AIRBOSS self
-- @param Core.Point#COORDINATE coord Coordinate of the detour.
-- @param #number speed Speed in knots. Default is current carrier velocity.
-- @param #boolean uturn (Optional) If true, carrier will go back to where it came from before it resumes its route to the next waypoint.
-- @param #number uspeed Speed in knots after U-turn. Default is same as before.
-- @param Core.Point#COORDINATE tcoord Additional coordinate to make turn smoother.
-- @return #AIRBOSS self
function AIRBOSS:CarrierDetour( coord, speed, uturn, uspeed, tcoord )

  -- Current coordinate of the carrier.
  local pos0 = self:GetCoordinate()

  -- Current speed in knots.
  local vel0 = self.carrier:GetVelocityKNOTS()

  -- Default. If speed is not given we take the current speed but at least 5 knots.
  speed = speed or math.max( vel0, 5 )

  -- Speed in km/h. At least 2 knots.
  local speedkmh = math.max( UTILS.KnotsToKmph( speed ), UTILS.KnotsToKmph( 2 ) )

  -- Turn speed in km/h. At least 10 knots.
  local cspeedkmh = math.max( self.carrier:GetVelocityKMH(), UTILS.KnotsToKmph( 10 ) )

  -- U-turn speed in km/h.
  local uspeedkmh = UTILS.KnotsToKmph( uspeed or speed )

  -- Waypoint table.
  local wp = {}

  -- Waypoint at current position.
  table.insert( wp, pos0:WaypointGround( cspeedkmh ) )

  -- Waypooint to help the turn.
  if tcoord then
    table.insert( wp, tcoord:WaypointGround( cspeedkmh ) )
  end

  -- Detour waypoint.
  table.insert( wp, coord:WaypointGround( speedkmh ) )

  -- U-turn waypoint. If enabled, go back to where you came from.
  if uturn then
    table.insert( wp, pos0:WaypointGround( uspeedkmh ) )
  end

  -- Get carrier group.
  local group = self.carrier:GetGroup()

  -- Passing waypoint taskfunction
  local TaskResumeRoute = group:TaskFunction( "AIRBOSS._ResumeRoute", self )

  -- Set task to restart route at the last point.
  group:SetTaskWaypoint( wp[#wp], TaskResumeRoute )

  -- Debug mark.
  if self.Debug then
    if tcoord then
      tcoord:MarkToAll( string.format( "Detour Turn Help WP. Speed %.1f knots", UTILS.KmphToKnots( cspeedkmh ) ) )
    end
    coord:MarkToAll( string.format( "Detour Waypoint. Speed %.1f knots", UTILS.KmphToKnots( speedkmh ) ) )
    if uturn then
      pos0:MarkToAll( string.format( "Detour U-turn WP. Speed %.1f knots", UTILS.KmphToKnots( uspeedkmh ) ) )
    end
  end

  -- Detour switch true.
  self.detour = true

  -- Route carrier into the wind.
  self.carrier:Route( wp )
end

--- Let the carrier turn into the wind.
-- @param #AIRBOSS self
-- @param #number time Time in seconds.
-- @param #number vdeck Speed on deck m/s. Carrier will
-- @param #boolean uturn Make U-turn and go back to initial after downwind leg.
-- @return #AIRBOSS self
function AIRBOSS:CarrierTurnIntoWind( time, vdeck, uturn )

  -- Wind speed.
  local _, vwind = self:GetWind()

  -- Speed of carrier in m/s but at least 2 knots.
  local vtot = math.max( vdeck - vwind, UTILS.KnotsToMps( 2 ) )

  -- Distance to travel
  local dist = vtot * time

  -- Speed in knots
  local speedknots = UTILS.MpsToKnots( vtot )
  local distNM = UTILS.MetersToNM( dist )

  -- Debug output
  self:I( self.lid .. string.format( "Carrier steaming into the wind (%.1f kts). Distance=%.1f NM, Speed=%.1f knots, Time=%d sec.", UTILS.MpsToKnots( vwind ), distNM, speedknots, time ) )

  -- Get heading into the wind accounting for angled runway.
  local hiw = self:GetHeadingIntoWind()

  -- Current heading.
  local hdg = self:GetHeading()

  -- Heading difference.
  local deltaH = self:_GetDeltaHeading( hdg, hiw )

  local Cv = self:GetCoordinate()

  local Ctiw = nil -- Core.Point#COORDINATE
  local Csoo = nil -- Core.Point#COORDINATE

  -- Define path depending on turn angle.
  if deltaH < 45 then
    -- Small turn.

    -- Point in the right direction to help turning.
    Csoo = Cv:Translate( 750, hdg ):Translate( 750, hiw )

    -- Heading into wind from Csoo.
    local hsw = self:GetHeadingIntoWind( false, Csoo )

    -- Into the wind coord.
    Ctiw = Csoo:Translate( dist, hsw )

  elseif deltaH < 90 then
    -- Medium turn.

    -- Point in the right direction to help turning.
    Csoo = Cv:Translate( 900, hdg ):Translate( 900, hiw )

    -- Heading into wind from Csoo.
    local hsw = self:GetHeadingIntoWind( false, Csoo )

    -- Into the wind coord.
    Ctiw = Csoo:Translate( dist, hsw )

  elseif deltaH < 135 then
    -- Large turn backwards.

    -- Point in the right direction to help turning.
    Csoo = Cv:Translate( 1100, hdg - 90 ):Translate( 1000, hiw )

    -- Heading into wind from Csoo.
    local hsw = self:GetHeadingIntoWind( false, Csoo )

    -- Into the wind coord.
    Ctiw = Csoo:Translate( dist, hsw )

  else
    -- Huge turn backwards.

    -- Point in the right direction to help turning.
    Csoo = Cv:Translate( 1200, hdg - 90 ):Translate( 1000, hiw )

    -- Heading into wind from Csoo.
    local hsw = self:GetHeadingIntoWind( false, Csoo )

    -- Into the wind coord.
    Ctiw = Csoo:Translate( dist, hsw )

  end

  -- Return to coordinate if collision is detected.
  self.Creturnto = self:GetCoordinate()

  -- Next waypoint.
  local nextwp = self:_GetNextWaypoint()

  -- For downwind, we take the velocity at the next WP.
  local vdownwind = UTILS.MpsToKnots( nextwp:GetVelocity() )

  -- Make sure we move at all in case the speed at the waypoint is zero.
  if vdownwind < 1 then
    vdownwind = 10
  end

  -- Let the carrier make a detour from its route but return to its current position.
  self:CarrierDetour( Ctiw, speedknots, uturn, vdownwind, Csoo )

  -- Set switch that we are currently turning into the wind.
  self.turnintowind = true

  return self
end

--- Get next waypoint of the carrier.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
-- @return #number Number of waypoint.
function AIRBOSS:_GetNextWaypoint()

  -- Next waypoint.
  local Nextwp = nil
  if self.currentwp == #self.waypoints then
    Nextwp = 1
  else
    Nextwp = self.currentwp + 1
  end

  -- Debug output
  local text = string.format( "Current WP=%d/%d, next WP=%d", self.currentwp, #self.waypoints, Nextwp )
  self:T2( self.lid .. text )

  -- Next waypoint.
  local nextwp = self.waypoints[Nextwp] -- Core.Point#COORDINATE

  return nextwp, Nextwp
end

--- Initialize Mission Editor waypoints.
-- @param #AIRBOSS self
-- @return #AIRBOSS self
function AIRBOSS:_InitWaypoints()

  -- Waypoints of group as defined in the ME.
  local Waypoints = self.carrier:GetGroup():GetTemplateRoutePoints()

  -- Init array.
  self.waypoints = {}

  -- Set waypoint table.
  for i, point in ipairs( Waypoints ) do

    -- Coordinate of the waypoint
    local coord = COORDINATE:New( point.x, point.alt, point.y )

    -- Set velocity of the coordinate.
    coord:SetVelocity( point.speed )

    -- Add to table.
    table.insert( self.waypoints, coord )

    -- Debug info.
    if self.Debug then
      coord:MarkToAll( string.format( "Carrier Waypoint %d, Speed=%.1f knots", i, UTILS.MpsToKnots( point.speed ) ) )
    end

  end

  return self
end

--- Patrol carrier.
-- @param #AIRBOSS self
-- @param #number n Next waypoint number.
-- @return #AIRBOSS self
function AIRBOSS:_PatrolRoute( n )

  -- Get next waypoint coordinate and number.
  local nextWP, N = self:_GetNextWaypoint()

  -- Default resume is to next waypoint.
  n = n or N

  -- Get carrier group.
  local CarrierGroup = self.carrier:GetGroup()

  -- Waypoints table.
  local Waypoints = {}

  -- Create a waypoint from the current coordinate.
  local wp = self:GetCoordinate():WaypointGround( CarrierGroup:GetVelocityKMH() )

  -- Add current position as first waypoint.
  table.insert( Waypoints, wp )

  -- Loop over waypoints.
  for i = n, #self.waypoints do
    local coord = self.waypoints[i] -- Core.Point#COORDINATE

    -- Create a waypoint from the coordinate.
    local wp = coord:WaypointGround( UTILS.MpsToKmph( coord.Velocity ) )

    -- Passing waypoint taskfunction
    local TaskPassingWP = CarrierGroup:TaskFunction( "AIRBOSS._PassingWaypoint", self, i, #self.waypoints )

    -- Call task function when carrier arrives at waypoint.
    CarrierGroup:SetTaskWaypoint( wp, TaskPassingWP )

    -- Add waypoint to table.
    table.insert( Waypoints, wp )
  end

  -- Route carrier group.
  CarrierGroup:Route( Waypoints )

  return self
end

--- Estimated the carrier position at some point in the future given the current waypoints and speeds.
-- @param #AIRBOSS self
-- @return DCS#time ETA abs. time in seconds.
function AIRBOSS:_GetETAatNextWP()

  -- Current waypoint
  local cwp = self.currentwp

  -- Current abs. time.
  local tnow = timer.getAbsTime()

  -- Current position.
  local p = self:GetCoordinate()

  -- Current velocity [m/s].
  local v = self.carrier:GetVelocityMPS()

  -- Next waypoint.
  local nextWP = self:_GetNextWaypoint()

  -- Distance to next waypoint.
  local s = p:Get2DDistance( nextWP )

  -- Distance to next waypoint.
  -- local s=0
  -- if #self.waypoints>cwp then
  --  s=p:Get2DDistance(self.waypoints[cwp+1])
  -- end

  -- v=s/t <==> t=s/v
  local t = s / v

  -- ETA
  local eta = t + tnow

  return eta
end

--- Check if carrier is turning. If turning started or stopped, we inform the players via radio message.
-- @param #AIRBOSS self
function AIRBOSS:_CheckCarrierTurning()

  -- Current orientation of carrier.
  local vNew = self.carrier:GetOrientationX()

  -- Last orientation from 30 seconds ago.
  local vLast = self.Corientlast

  -- We only need the X-Z plane.
  vNew.y = 0;
  vLast.y = 0

  -- Angle between current heading and last time we checked ~30 seconds ago.
  local deltaLast = math.deg( math.acos( UTILS.VecDot( vNew, vLast ) / UTILS.VecNorm( vNew ) / UTILS.VecNorm( vLast ) ) )

  -- Last orientation becomes new orientation
  self.Corientlast = vNew

  -- Carrier is turning when its heading changed by at least one degree since last check.
  local turning = math.abs( deltaLast ) >= 1

  -- Check if turning stopped. (Carrier was turning but is not any more.)
  if self.turning and not turning then

    -- Get final bearing.
    local FB = self:GetFinalBearing( true )

    -- Marshal radio call: "99, new final bearing XYZ degrees."
    self:_MarshalCallNewFinalBearing( FB )

  end

  -- Check if turning started. (Carrier was not turning and is now.)
  if turning and not self.turning then

    -- Get heading.
    local hdg
    if self.turnintowind then
      -- We are now steaming into the wind.
      hdg = self:GetHeadingIntoWind( false )
    else
      -- We turn towards the next waypoint.
      hdg = self:GetCoordinate():HeadingTo( self:_GetNextWaypoint() )
    end

    -- Magnetic!
    hdg = hdg - self.magvar
    if hdg < 0 then
      hdg = 360 + hdg
    end

    -- Radio call: "99, Carrier starting turn to heading XYZ degrees".
    self:_MarshalCallCarrierTurnTo( hdg )
  end

  -- Update turning.
  self.turning = turning
end

--- Check if heading or position of carrier have changed significantly.
-- @param #AIRBOSS self
function AIRBOSS:_CheckPatternUpdate()

  ----------------------------------------
  -- TODO: Make parameters input values --
  ----------------------------------------

  -- Min 10 min between pattern updates.
  local dTPupdate = 10 * 60

  -- Update if carrier moves by more than 2.5 NM.
  local Dupdate = UTILS.NMToMeters( 2.5 )

  -- Update if carrier turned by more than 5°.
  local Hupdate = 5

  -----------------------
  -- Time Update Check --
  -----------------------

  -- Time since last pattern update
  local dt = timer.getTime() - self.Tpupdate

  -- Check whether at least 10 min between updates and not turning currently.
  if dt < dTPupdate or self.turning then
    return
  end

  --------------------------
  -- Heading Update Check --
  --------------------------

  -- Current orientation of carrier.
  local vNew = self.carrier:GetOrientationX()

  -- Reference orientation of carrier after the last update.
  local vOld = self.Corientation

  -- We only need the X-Z plane.
  vNew.y = 0;
  vOld.y = 0

  -- Get angle between old and new orientation vectors in rad and convert to degrees.
  local deltaHeading = math.deg( math.acos( UTILS.VecDot( vNew, vOld ) / UTILS.VecNorm( vNew ) / UTILS.VecNorm( vOld ) ) )

  -- Check if orientation changed.
  local Hchange = false
  if math.abs( deltaHeading ) >= Hupdate then
    self:T( self.lid .. string.format( "Carrier heading changed by %d°.", deltaHeading ) )
    Hchange = true
  end

  ---------------------------
  -- Distance Update Check --
  ---------------------------

  -- Get current position and orientation of carrier.
  local pos = self:GetCoordinate()

  -- Get distance to saved position.
  local dist = pos:Get2DDistance( self.Cposition )

  -- Check if carrier moved more than ~10 km.
  local Dchange = false
  if dist >= Dupdate then
    self:T( self.lid .. string.format( "Carrier position changed by %.1f NM.", UTILS.MetersToNM( dist ) ) )
    Dchange = true
  end

  ----------------------------
  -- Update Marshal Flights --
  ----------------------------

  -- If heading or distance changed ==> update marshal AI patterns.
  if Hchange or Dchange then

    -- Loop over all marshal flights
    for _, _flight in pairs( self.Qmarshal ) do
      local flight = _flight -- #AIRBOSS.FlightGroup

      -- Update marshal pattern of AI keeping the same stack.
      if flight.ai then
        self:_MarshalAI( flight, flight.flag )
      end

    end

    -- Reset parameters for next update check.
    self.Corientation = vNew
    self.Cposition = pos
    self.Tpupdate = timer.getTime()
  end

end

--- Function called when a group is passing a waypoint.
-- @param Wrapper.Group#GROUP group Group that passed the waypoint
-- @param #AIRBOSS airboss Airboss object.
-- @param #number i Waypoint number that has been reached.
-- @param #number final Final waypoint number.
function AIRBOSS._PassingWaypoint( group, airboss, i, final )

  -- Debug message.
  local text = string.format( "Group %s passing waypoint %d of %d.", group:GetName(), i, final )

  -- Debug smoke and marker.
  if airboss.Debug and false then
    local pos = group:GetCoordinate()
    pos:SmokeRed()
    local MarkerID = pos:MarkToAll( string.format( "Group %s reached waypoint %d", group:GetName(), i ) )
  end

  -- Debug message.
  MESSAGE:New( text, 10 ):ToAllIf( airboss.Debug )
  airboss:T( airboss.lid .. text )

  -- Set current waypoint.
  airboss.currentwp = i

  -- Passing Waypoint event.
  airboss:PassingWaypoint( i )

  -- Reactivate beacons.
  -- airboss:_ActivateBeacons()

  -- If final waypoint reached, do route all over again.
  if i == final and final > 1 and airboss.adinfinitum then
    airboss:_PatrolRoute()
  end
end

--- Carrier Strike Group resumes the route of the waypoints defined in the mission editor.
-- @param Wrapper.Group#GROUP group Carrier Strike Group that passed the waypoint.
-- @param #AIRBOSS airboss Airboss object.
-- @param Core.Point#COORDINATE gotocoord Go to coordinate before route is resumed.
function AIRBOSS._ResumeRoute( group, airboss, gotocoord )

  -- Get next waypoint
  local nextwp, Nextwp = airboss:_GetNextWaypoint()

  -- Speed set at waypoint.
  local speedkmh = nextwp.Velocity * 3.6

  -- If speed at waypoint is zero, we set it to 10 knots.
  if speedkmh < 1 then
    speedkmh = UTILS.KnotsToKmph( 10 )
  end

  -- Waypoints array.
  local waypoints = {}

  -- Current position.
  local c0 = group:GetCoordinate()

  -- Current positon as first waypoint.
  local wp0 = c0:WaypointGround( speedkmh )
  table.insert( waypoints, wp0 )

  -- First goto this coordinate.
  if gotocoord then

    -- gotocoord:MarkToAll(string.format("Goto waypoint speed=%.1f km/h", speedkmh))

    local headingto = c0:HeadingTo( gotocoord )

    local hdg1 = airboss:GetHeading()
    local hdg2 = c0:HeadingTo( gotocoord )
    local delta = airboss:_GetDeltaHeading( hdg1, hdg2 )

    -- env.info(string.format("FF hdg1=%d, hdg2=%d, delta=%d", hdg1, hdg2, delta))

    -- Add additional turn points
    if delta > 90 then

      -- Turn radius 3 NM.
      local turnradius = UTILS.NMToMeters( 3 )

      local gotocoordh = c0:Translate( turnradius, hdg1 + 45 )
      -- gotocoordh:MarkToAll(string.format("Goto help waypoint 1 speed=%.1f km/h", speedkmh))

      local wp = gotocoordh:WaypointGround( speedkmh )
      table.insert( waypoints, wp )

      gotocoordh = c0:Translate( turnradius, hdg1 + 90 )
      -- gotocoordh:MarkToAll(string.format("Goto help waypoint 2 speed=%.1f km/h", speedkmh))

      wp = gotocoordh:WaypointGround( speedkmh )
      table.insert( waypoints, wp )

    end

    local wp1 = gotocoord:WaypointGround( speedkmh )
    table.insert( waypoints, wp1 )

  end

  -- Debug message.
  local text = string.format( "Carrier is resuming route. Next waypoint %d, Speed=%.1f knots.", Nextwp, UTILS.KmphToKnots( speedkmh ) )

  -- Debug message.
  MESSAGE:New( text, 10 ):ToAllIf( airboss.Debug )
  airboss:I( airboss.lid .. text )

  -- Loop over all remaining waypoints.
  for i = Nextwp, #airboss.waypoints do

    -- Coordinate of the next WP.
    local coord = airboss.waypoints[i] -- Core.Point#COORDINATE

    -- Speed in km/h of that WP. Velocity is in m/s.
    local speed = coord.Velocity * 3.6

    -- If speed is zero we set it to 10 knots.
    if speed < 1 then
      speed = UTILS.KnotsToKmph( 10 )
    end

    -- coord:MarkToAll(string.format("Resume route WP %d, speed=%.1f km/h", i, speed))

    -- Create waypoint.
    local wp = coord:WaypointGround( speed )

    -- Passing waypoint task function.
    local TaskPassingWP = group:TaskFunction( "AIRBOSS._PassingWaypoint", airboss, i, #airboss.waypoints )

    -- Call task function when carrier arrives at waypoint.
    group:SetTaskWaypoint( wp, TaskPassingWP )

    -- Add waypoints to table.
    table.insert( waypoints, wp )
  end

  -- Set turn into wind switch false.
  airboss.turnintowind = false
  airboss.detour = false

  -- Route group.
  group:Route( waypoints )
end

--- Function called when a group has reached the holding zone.
-- @param Wrapper.Group#GROUP group Group that reached the holding zone.
-- @param #AIRBOSS airboss Airboss object.
-- @param #AIRBOSS.FlightGroup flight Flight group that has reached the holding zone.
function AIRBOSS._ReachedHoldingZone( group, airboss, flight )

  -- Debug message.
  local text = string.format( "Flight %s reached holding zone.", group:GetName() )
  MESSAGE:New( text, 10 ):ToAllIf( airboss.Debug )
  airboss:T( airboss.lid .. text )

  -- Debug mark.
  if airboss.Debug then
    group:GetCoordinate():MarkToAll( text )
  end

  -- Set holding flag true and set timestamp for marshal time check.
  if flight then
    flight.holding = true
    flight.time = timer.getAbsTime()
  end
end

--- Function called when a group should be send to the Marshal stack. If stack is full, it is send to wait.
-- @param Wrapper.Group#GROUP group Group that reached the holding zone.
-- @param #AIRBOSS airboss Airboss object.
-- @param #AIRBOSS.FlightGroup flight Flight group that has reached the holding zone.
function AIRBOSS._TaskFunctionMarshalAI( group, airboss, flight )

  -- Debug message.
  local text = string.format( "Flight %s is send to marshal.", group:GetName() )
  MESSAGE:New( text, 10 ):ToAllIf( airboss.Debug )
  airboss:T( airboss.lid .. text )

  -- Get the next free stack for current recovery case.
  local stack = airboss:_GetFreeStack( flight.ai )

  if stack then

    -- Send AI to marshal stack.
    airboss:_MarshalAI( flight, stack )

  else

    -- Send AI to orbit outside 10 NM zone and wait until the next Marshal stack is available.
    if not airboss:_InQueue( airboss.Qwaiting, flight.group ) then
      airboss:_WaitAI( flight )
    end

  end

  -- If it came from refueling.
  if flight.refueling == true then
    airboss:I( airboss.lid .. string.format( "Flight group %s finished refueling task.", flight.groupname ) )
  end

  -- Not refueling any more in case it was.
  flight.refueling = false

end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MISC functions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get aircraft nickname.
-- @param #AIRBOSS self
-- @param #string actype Aircraft type name.
-- @return #string Aircraft nickname. E.g. "Hornet" for the F/A-18C or "Tomcat" For the F-14A.
function AIRBOSS:_GetACNickname( actype )

  local nickname = "unknown"
  if actype == AIRBOSS.AircraftCarrier.A4EC then
    nickname = "Skyhawk"
  elseif actype == AIRBOSS.AircraftCarrier.T45C then
    nickname = "Goshawk"
  elseif actype == AIRBOSS.AircraftCarrier.AV8B then
    nickname = "Harrier"
  elseif actype == AIRBOSS.AircraftCarrier.E2D then
    nickname = "Hawkeye"
  elseif actype == AIRBOSS.AircraftCarrier.F14A_AI or actype == AIRBOSS.AircraftCarrier.F14A or actype == AIRBOSS.AircraftCarrier.F14B then
    nickname = "Tomcat"
  elseif actype == AIRBOSS.AircraftCarrier.FA18C or actype == AIRBOSS.AircraftCarrier.HORNET then
    nickname = "Hornet"
  elseif actype == AIRBOSS.AircraftCarrier.RHINOE or actype == AIRBOSS.AircraftCarrier.RHINOF then
    nickname = "Rhino"
  elseif actype == AIRBOSS.AircraftCarrier.GROWLER then
    nickname = "Growler"
  elseif actype == AIRBOSS.AircraftCarrier.S3B or actype == AIRBOSS.AircraftCarrier.S3BTANKER then
    nickname = "Viking"
  end

  return nickname
end

--- Get onboard number of player or client.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #string Onboard number as string.
function AIRBOSS:_GetOnboardNumberPlayer( group )
  return self:_GetOnboardNumbers( group, true )
end

--- Get onboard numbers of all units in a group.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @param #boolean playeronly If true, return the onboard number for player or client skill units.
-- @return #table Table of onboard numbers.
function AIRBOSS:_GetOnboardNumbers( group, playeronly )
  -- self:F({groupname=group:GetName})

  -- Get group name.
  local groupname = group:GetName()

  -- Debug text.
  local text = string.format( "Onboard numbers of group %s:", groupname )

  -- Units of template group.
  local units = group:GetTemplate().units

  -- Get numbers.
  local numbers = {}
  for _, unit in pairs( units ) do

    -- Onboard number and unit name.
    local n = tostring( unit.onboard_num )
    local name = unit.name
    local skill = unit.skill or "Unknown"

    -- Debug text.
    text = text .. string.format( "\n- unit %s: onboard #=%s  skill=%s", name, n, tostring( skill ) )

    if playeronly and skill == "Client" or skill == "Player" then
      -- There can be only one player in the group, so we skip everything else.
      return n
    end

    -- Table entry.
    numbers[name] = n
  end

  -- Debug info.
  self:T2( self.lid .. text )

  return numbers
end

--- Get Tower frequency of carrier.
-- @param #AIRBOSS self
function AIRBOSS:_GetTowerFrequency()

  -- Tower frequency in MHz
  self.TowerFreq = 0

  -- Get Template of Strike Group
  local striketemplate = self.carrier:GetGroup():GetTemplate()

  -- Find the carrier unit.
  for _, unit in pairs( striketemplate.units ) do
    if self.carrier:GetName() == unit.name then
      self.TowerFreq = unit.frequency / 1000000
      return
    end
  end
end

--- Get error margin depending on player skill.
--
-- * Flight students: 10% and 20%
-- * Naval Aviators: 5% and 10%
-- * TOPGUN Graduates: 2.5% and 5%
--
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @return #number Error margin for still being okay.
-- @return #number Error margin for really sucking.
function AIRBOSS:_GetGoodBadScore( playerData )

  local lowscore
  local badscore
  if playerData.difficulty == AIRBOSS.Difficulty.EASY then
    lowscore = 10
    badscore = 20
  elseif playerData.difficulty == AIRBOSS.Difficulty.NORMAL then
    lowscore = 5
    badscore = 10
  elseif playerData.difficulty == AIRBOSS.Difficulty.HARD then
    lowscore = 2.5
    badscore = 5
  end

  return lowscore, badscore
end

--- Check if aircraft is capable of landing on this aircraft carrier.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit. (Will also work with groups as given parameter.)
-- @return #boolean If true, aircraft can land on a carrier.
function AIRBOSS:_IsCarrierAircraft( unit )

  -- Get aircraft type name
  local aircrafttype = unit:GetTypeName()

  -- Special case for Harrier which can only land on Tarawa, LHA and LHD.
  if aircrafttype == AIRBOSS.AircraftCarrier.AV8B then
    if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
      return true
    else
      return false
    end
  end

  -- Also only Harriers can land on the Tarawa, LHA and LHD.
  if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
    if aircrafttype ~= AIRBOSS.AircraftCarrier.AV8B then
      return false
    end
  end

  -- Loop over all other known carrier capable aircraft.
  for _, actype in pairs( AIRBOSS.AircraftCarrier ) do

    -- Check if this is a carrier capable aircraft type.
    if actype == aircrafttype then
      return true
    end
  end

  -- No carrier carrier aircraft.
  return false
end

--- Checks if a human player sits in the unit.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #boolean If true, human player inside the unit.
function AIRBOSS:_IsHumanUnit( unit )

  -- Get player unit or nil if no player unit.
  local playerunit = self:_GetPlayerUnitAndName( unit:GetName() )

  if playerunit then
    return true
  else
    return false
  end
end

--- Checks if a group has a human player.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #boolean If true, human player inside group.
function AIRBOSS:_IsHuman( group )

  -- Get all units of the group.
  local units = group:GetUnits()

  -- Loop over all units.
  for _, _unit in pairs( units ) do
    -- Check if unit is human.
    local human = self:_IsHumanUnit( _unit )
    if human then
      return true
    end
  end

  return false
end

--- Get fuel state in pounds.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit The unit for which the mass is determined.
-- @return #number Fuel state in pounds.
function AIRBOSS:_GetFuelState( unit )

  -- Get relative fuel [0,1].
  local fuel = unit:GetFuel()

  -- Get max weight of fuel in kg.
  local maxfuel = self:_GetUnitMasses( unit )

  -- Fuel state, i.e. what let's
  local fuelstate = fuel * maxfuel

  -- Debug info.
  self:T2( self.lid .. string.format( "Unit %s fuel state = %.1f kg = %.1f lbs", unit:GetName(), fuelstate, UTILS.kg2lbs( fuelstate ) ) )

  return UTILS.kg2lbs( fuelstate )
end

--- Convert altitude from meters to angels (thousands of feet).
-- @param #AIRBOSS self
-- @param alt altitude in meters.
-- @return #number Altitude in Anglels = thousands of feet using math.floor().
function AIRBOSS:_GetAngels( alt )

  if alt then
    local angels = UTILS.Round( UTILS.MetersToFeet( alt ) / 1000, 0 )
    return angels
  else
    return 0
  end

end

--- Get unit masses especially fuel from DCS descriptor values.
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit The unit for which the mass is determined.
-- @return #number Mass of fuel in kg.
-- @return #number Empty weight of unit in kg.
-- @return #number Max weight of unit in kg.
-- @return #number Max cargo weight in kg.
function AIRBOSS:_GetUnitMasses( unit )

  -- Get DCS descriptors table.
  local Desc = unit:GetDesc()

  -- Mass of fuel in kg.
  local massfuel = Desc.fuelMassMax or 0

  -- Mass of empty unit in km.
  local massempty = Desc.massEmpty or 0

  -- Max weight of unit in kg.
  local massmax = Desc.massMax or 0

  -- Rest is cargo.
  local masscargo = massmax - massfuel - massempty

  -- Debug info.
  self:T2( self.lid .. string.format( "Unit %s mass fuel=%.1f kg, empty=%.1f kg, max=%.1f kg, cargo=%.1f kg", unit:GetName(), massfuel, massempty, massmax, masscargo ) )

  return massfuel, massempty, massmax, masscargo
end

--- Get player data from unit object
-- @param #AIRBOSS self
-- @param Wrapper.Unit#UNIT unit Unit in question.
-- @return #AIRBOSS.PlayerData Player data or nil if not player with this name or unit exists.
function AIRBOSS:_GetPlayerDataUnit( unit )
  if unit:IsAlive() then
    local unitname = unit:GetName()
    local playerunit, playername = self:_GetPlayerUnitAndName( unitname )
    if playerunit and playername then
      return self.players[playername]
    end
  end
  return nil
end

--- Get player data from group object.
-- @param #AIRBOSS self
-- @param Wrapper.Group#GROUP group Group in question.
-- @return #AIRBOSS.PlayerData Player data or nil if not player with this name or unit exists.
function AIRBOSS:_GetPlayerDataGroup( group )
  local units = group:GetUnits()
  for _, unit in pairs( units ) do
    local playerdata = self:_GetPlayerDataUnit( unit )
    if playerdata then
      return playerdata
    end
  end
  return nil
end

--- Returns the unit of a player and the player name from the self.players table if it exists.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of player or nil.
function AIRBOSS:_GetPlayerUnit( _unitName )

  for _, _player in pairs( self.players ) do

    local player = _player -- #AIRBOSS.PlayerData

    if player.unit and player.unit:GetName() == _unitName then
      self:T( self.lid .. string.format( "Found player=%s unit=%s in players table.", tostring( player.name ), tostring( _unitName ) ) )
      return player.unit, player.name
    end

  end

  return nil, nil
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function AIRBOSS:_GetPlayerUnitAndName( _unitName )
  self:F2( _unitName )

  if _unitName ~= nil then

    -- First, let's look up all current players.
    local u, pn = self:_GetPlayerUnit( _unitName )

    -- Return
    if u and pn then
      return u, pn
    end

    -- Get DCS unit from its name.
    local DCSunit = Unit.getByName( _unitName )

    if DCSunit then

      -- Get player name if any.
      local playername = DCSunit:getPlayerName()

      -- Unit object.
      local unit = UNIT:Find( DCSunit )

      -- Debug.
      self:T2( { DCSunit = DCSunit, unit = unit, playername = playername } )

      -- Check if enverything is there.
      if DCSunit and unit and playername then
        self:T( self.lid .. string.format( "Found DCS unit %s with player %s.", tostring( _unitName ), tostring( playername ) ) )
        return unit, playername
      end

    end

  end

  -- Return nil if we could not find a player.
  return nil, nil
end

--- Get carrier coalition.
-- @param #AIRBOSS self
-- @return #number Coalition side of carrier.
function AIRBOSS:GetCoalition()
  return self.carrier:GetCoalition()
end

--- Get carrier coordinate.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Carrier coordinate.
function AIRBOSS:GetCoordinate()
  return self.carrier:GetCoord()
end

--- Get carrier coordinate.
-- @param #AIRBOSS self
-- @return Core.Point#COORDINATE Carrier coordinate.
function AIRBOSS:GetCoord()
  return self.carrier:GetCoord()
end

--- Get static weather of this mission from env.mission.weather.
-- @param #AIRBOSS self
-- @param #table Clouds table which has entries "thickness", "density", "base", "iprecptns".
-- @param #number Visibility distance in meters.
-- @param #table Fog table, which has entries "thickness", "visibility" or nil if fog is disabled in the mission.
-- @param #number Dust density or nil if dust is disabled in the mission.
function AIRBOSS:_GetStaticWeather()

  -- Weather data from mission file.
  local weather = env.mission.weather

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
  local clouds = weather.clouds

  -- Visibilty distance in meters.
  local visibility = weather.visibility.distance

  -- Dust
  --[[
  ["enable_dust"] = false,
  ["dust_density"] = 0,
  ]]
  local dust = nil
  if weather.enable_dust == true then
    dust = weather.dust_density
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
  local fog = nil
  if weather.enable_fog == true then
    fog = weather.fog
  end

  return clouds, visibility, fog, dust
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RADIO MESSAGE Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called by DCS timer. Unused.
-- @param #table param Parameters.
-- @param #number time Time.
function AIRBOSS._CheckRadioQueueT( param, time )
  AIRBOSS._CheckRadioQueue( param.airboss, param.radioqueue, param.name )
  return time + 0.05
end

--- Radio queue item.
-- @type AIRBOSS.Radioitem
-- @field #number Tplay Abs time when transmission should be played.
-- @field #number Tstarted Abs time when transmission began to play.
-- @field #boolean isplaying Currently playing.
-- @field #AIRBOSS.Radio radio Radio object.
-- @field #AIRBOSS.RadioCall call Radio call.
-- @field #boolean loud If true, play loud version of file.
-- @field #number interval Interval in seconds after the last sound was played.

--- Check radio queue for transmissions to be broadcasted.
-- @param #AIRBOSS self
-- @param #table radioqueue The radio queue.
-- @param #string name Name of the queue.
function AIRBOSS:_CheckRadioQueue( radioqueue, name )

  -- env.info(string.format("FF %s #radioqueue %d", name, #radioqueue))

  -- Check if queue is empty.
  if #radioqueue == 0 then

    if name == "LSO" then
      self:T( self.lid .. string.format( "Stopping LSO radio queue." ) )
      self.radiotimer:Stop( self.RQLid )
      self.RQLid = nil
    elseif name == "MARSHAL" then
      self:T( self.lid .. string.format( "Stopping Marshal radio queue." ) )
      self.radiotimer:Stop( self.RQMid )
      self.RQMid = nil
    end

    return
  end

  -- Get current abs time.
  local _time = timer.getAbsTime()

  local playing = false
  local next = nil -- #AIRBOSS.Radioitem
  local _remove = nil
  for i, _transmission in ipairs( radioqueue ) do
    local transmission = _transmission -- #AIRBOSS.Radioitem

    -- Check if transmission time has passed.
    if _time >= transmission.Tplay then

      -- Check if transmission is currently playing.
      if transmission.isplaying then

        -- Check if transmission is finished.
        if _time >= transmission.Tstarted + transmission.call.duration then

          -- Transmission over.
          transmission.isplaying = false
          _remove = i

          if transmission.radio.alias == "LSO" then
            self.TQLSO = _time
          elseif transmission.radio.alias == "MARSHAL" then
            self.TQMarshal = _time
          end

        else -- still playing

          -- Transmission is still playing.
          playing = true

        end

      else -- not playing yet

        local Tlast = nil
        if transmission.interval then
          if transmission.radio.alias == "LSO" then
            Tlast = self.TQLSO
          elseif transmission.radio.alias == "MARSHAL" then
            Tlast = self.TQMarshal
          end
        end

        if transmission.interval == nil then

          -- Not playing ==> this will be next.
          if next == nil then
            next = transmission
          end

        else

          if _time - Tlast >= transmission.interval then
            next = transmission
          else

          end
        end

        -- We got a transmission or one with an interval that is not due yet. No need for anything else.
        if next or Tlast then
          break
        end

      end

    else

      -- Transmission not due yet.

    end
  end

  -- Found a new transmission.
  if next ~= nil and not playing then
    self:Broadcast( next.radio, next.call, next.loud )
    next.isplaying = true
    next.Tstarted = _time
  end

  -- Remove completed calls from queue.
  if _remove then
    table.remove( radioqueue, _remove )
  end

  return
end

--- Add Radio transmission to radio queue.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Radio radio Radio sending the transmission.
-- @param #AIRBOSS.RadioCall call Radio sound files and subtitles.
-- @param #boolean loud If true, play loud sound file version.
-- @param #number delay Delay in seconds, before the message is broadcasted.
-- @param #number interval Interval in seconds after the last sound has been played.
-- @param #boolean click If true, play radio click at the end.
-- @param #boolean pilotcall If true, it's a pilot call.
function AIRBOSS:RadioTransmission( radio, call, loud, delay, interval, click, pilotcall )
  self:F2( { radio = radio, call = call, loud = loud, delay = delay, interval = interval, click = click } )

  -- Nil check.
  if radio == nil or call == nil then
    return
  end

  -- Create a new radio transmission item.
  local transmission = {} -- #AIRBOSS.Radioitem

  transmission.radio = radio
  transmission.call = call
  transmission.Tplay = timer.getAbsTime() + (delay or 0)
  transmission.interval = interval
  transmission.isplaying = false
  transmission.Tstarted = nil
  transmission.loud = loud and call.loud

  -- Player onboard number if sender has one.
  if self:_IsOnboard( call.modexsender ) then
    self:_Number2Radio( radio, call.modexsender, delay, 0.3, pilotcall )
  end

  -- Play onboard number if receiver has one.
  if self:_IsOnboard( call.modexreceiver ) then
    self:_Number2Radio( radio, call.modexreceiver, delay, 0.3, pilotcall )
  end

  -- Add transmission to the right queue.
  local caller = ""
  if radio.alias == "LSO" then

    table.insert( self.RQLSO, transmission )

    caller = "LSOCall"

    -- Schedule radio queue checks.
    if not self.RQLid then
      self:T( self.lid .. string.format( "Starting LSO radio queue." ) )
      self.RQLid = self.radiotimer:Schedule( nil, AIRBOSS._CheckRadioQueue, { self, self.RQLSO, "LSO" }, 0.02, 0.05 )
    end

  elseif radio.alias == "MARSHAL" then

    table.insert( self.RQMarshal, transmission )

    caller = "MarshalCall"

    if not self.RQMid then
      self:T( self.lid .. string.format( "Starting Marhal radio queue." ) )
      self.RQMid = self.radiotimer:Schedule( nil, AIRBOSS._CheckRadioQueue, { self, self.RQMarshal, "MARSHAL" }, 0.02, 0.05 )
    end

  end

  -- Append radio click sound at the end of the transmission.
  if click then
    self:RadioTransmission( radio, self[caller].CLICK, false, delay )
  end
end

--- Check if a call needs a subtitle because the complete voice overs are not available.
-- @param #AIRBOSS self
-- @param #AIRBOSS.RadioCall call Radio sound files and subtitles.
-- @return #boolean If true, call needs a subtitle.
function AIRBOSS:_NeedsSubtitle( call )
  -- Currently we play the noise file.
  if call.file == self.MarshalCall.NOISE.file or call.file == self.LSOCall.NOISE.file then
    return true
  else
    return false
  end
end

--- Broadcast radio message.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Radio radio Radio sending transmission.
-- @param #AIRBOSS.RadioCall call Radio sound files and subtitles.
-- @param #boolean loud Play loud version of file.
function AIRBOSS:Broadcast( radio, call, loud )
  self:F( call )

  -- Check which sound output method to use.
  if not self.usersoundradio then

    ----------------------------
    -- Transmission via Radio --
    ----------------------------

    -- Get unit sending the transmission.
    local sender = self:_GetRadioSender( radio )

    -- Construct file name and subtitle.
    local filename = self:_RadioFilename( call, loud, radio.alias )

    -- Create subtitle for transmission.
    local subtitle = self:_RadioSubtitle( radio, call, loud )

    -- Debug.
    self:T( { filename = filename, subtitle = subtitle } )

    if sender then

      -- Broadcasting from aircraft. Only players tuned in to the right frequency will see the message.
      self:T( self.lid .. string.format( "Broadcasting from aircraft %s", sender:GetName() ) )

      -- Command to set the Frequency for the transmission.
      local commandFrequency = {
        id = "SetFrequency",
        params = {
          frequency = radio.frequency * 1000000, -- Frequency in Hz.
          modulation = radio.modulation,
        },
      }

      -- Command to tranmit the call.
      local commandTransmit = {
        id = "TransmitMessage",
        params = {
          file = filename,
          duration = call.subduration or 5,
          subtitle = subtitle,
          loop = false,
        },
      }

      -- Set commend for frequency
      sender:SetCommand( commandFrequency )

      -- Set command for radio transmission.
      sender:SetCommand( commandTransmit )

    else

      -- Broadcasting from carrier. No subtitle possible. Need to send messages to players.
      self:T( self.lid .. string.format( "Broadcasting from carrier via trigger.action.radioTransmission()." ) )

      -- Transmit from carrier position.
      local vec3 = self.carrier:GetPositionVec3()

      -- Transmit via trigger.
      trigger.action.radioTransmission( filename, vec3, radio.modulation, false, radio.frequency * 1000000, 100 )

      -- Display subtitle of message to players.
      for _, _player in pairs( self.players ) do
        local playerData = _player -- #AIRBOSS.PlayerData

        -- Message to all players in CCA that have subtites on.
        if playerData.unit:IsInZone( self.zoneCCA ) and playerData.actype ~= AIRBOSS.AircraftCarrier.A4EC then

          -- Only to players with subtitle on or if noise is played.
          if playerData.subtitles or self:_NeedsSubtitle( call ) then

            -- Messages to marshal to everyone. Messages on LSO radio only to those in the pattern.
            if radio.alias == "MARSHAL" or (radio.alias == "LSO" and self:_InQueue( self.Qpattern, playerData.group )) then

              -- Message to player.
              self:MessageToPlayer( playerData, subtitle, nil, "", call.subduration or 5 )

            end

          end

        end
      end
    end
  end

  ----------------
  -- Easy Comms --
  ----------------

  -- Workaround for the community A-4E-C as long as their radios are not functioning properly.
  for _, _player in pairs( self.players ) do
    local playerData = _player -- #AIRBOSS.PlayerData

    -- Easy comms if globally activated but definitly for all player in the community A-4E.
    if self.usersoundradio or playerData.actype == AIRBOSS.AircraftCarrier.A4EC then

      -- Messages to marshal to everyone. Messages on LSO radio only to those in the pattern.
      if radio.alias == "MARSHAL" or (radio.alias == "LSO" and self:_InQueue( self.Qpattern, playerData.group )) then

        -- User sound to players (inside CCA).
        self:Sound2Player( playerData, radio, call, loud )
      end

    end
  end

end

--- Player user sound to player if he is inside the CCA.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #AIRBOSS.Radio radio The radio used for transmission.
-- @param #AIRBOSS.RadioCall call Radio sound files and subtitles.
-- @param #boolean loud If true, play loud sound file version.
-- @param #number delay Delay in seconds, before the message is broadcasted.
function AIRBOSS:Sound2Player( playerData, radio, call, loud, delay )

  -- Only to players inside the CCA.
  if playerData.unit:IsInZone( self.zoneCCA ) and call then

    -- Construct file name.
    local filename = self:_RadioFilename( call, loud, radio.alias )

    -- Get Subtitle
    local subtitle = self:_RadioSubtitle( radio, call, loud )

    -- Play sound file via usersound trigger.
    USERSOUND:New( filename ):ToGroup( playerData.group, delay )

    -- Only to players with subtitle on or if noise is played.
    if playerData.subtitles or self:_NeedsSubtitle( call ) then
      self:MessageToPlayer( playerData, subtitle, nil, "", call.subduration, false, delay )
    end

  end
end

--- Create radio subtitle from radio call.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Radio radio The radio used for transmission.
-- @param #AIRBOSS.RadioCall call Radio sound files and subtitles.
-- @param #boolean loud If true, append "!" else ".".
-- @return #string Subtitle to be displayed.
function AIRBOSS:_RadioSubtitle( radio, call, loud )

  -- No subtitle if call is nil, or subtitle is nil or subtitle is empty.
  if call == nil or call.subtitle == nil or call.subtitle == "" then
    return ""
  end

  -- Sender
  local sender = call.sender or radio.alias
  if call.modexsender then
    sender = call.modexsender
  end

  -- Modex of receiver.
  local receiver = call.modexreceiver or ""

  -- Init subtitle.
  local subtitle = string.format( "%s: %s", sender, call.subtitle )
  if receiver and receiver ~= "" then
    subtitle = string.format( "%s: %s, %s", sender, receiver, call.subtitle )
  end

  -- Last character of the string.
  local lastchar = string.sub( subtitle, -1 )

  -- Append ! or .
  if loud then
    if lastchar == "." or lastchar == "!" then
      subtitle = string.sub( subtitle, 1, -1 )
    end
    subtitle = subtitle .. "!"
  else
    if lastchar == "!" then
      -- This also okay.
    elseif lastchar == "." then
      -- Nothing to do.
    else
      subtitle = subtitle .. "."
    end
  end

  return subtitle
end

--- Get full file name for radio call.
-- @param #AIRBOSS self
-- @param #AIRBOSS.RadioCall call Radio sound files and subtitles.
-- @param #boolean loud Use loud version of file if available.
-- @param #string channel Radio channel alias "LSO" or "LSOCall", "MARSHAL" or "MarshalCall".
-- @return #string The file name of the radio sound.
function AIRBOSS:_RadioFilename( call, loud, channel )

  -- Construct file name and subtitle.
  local prefix = call.file or ""
  local suffix = call.suffix or "ogg"

  -- Path to sound files. Default is in the ME
  local path = self.soundfolder or "l10n/DEFAULT/"

  -- Check for special LSO and Marshal sound folders.
  if string.find( call.file, "LSO-" ) and channel and (channel == "LSO" or channel == "LSOCall") then
    path = self.soundfolderLSO or path
  end
  if string.find( call.file, "MARSHAL-" ) and channel and (channel == "MARSHAL" or channel == "MarshalCall") then
    path = self.soundfolderMSH or path
  end

  -- Loud version.
  if loud then
    prefix = prefix .. "_Loud"
  end

  -- File name inclusing path in miz file.
  local filename = string.format( "%s%s.%s", path, prefix, suffix )

  return filename
end

--- Send text message to player client.
-- Message format will be "SENDER: RECCEIVER, MESSAGE".
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string message The message to send.
-- @param #string sender The person who sends the message or nil.
-- @param #string receiver The person who receives the message. Default player's onboard number. Set to "" for no receiver.
-- @param #number duration Display message duration. Default 10 seconds.
-- @param #boolean clear If true, clear screen from previous messages.
-- @param #number delay Delay in seconds, before the message is displayed.
function AIRBOSS:MessageToPlayer( playerData, message, sender, receiver, duration, clear, delay )

  if playerData and message and message ~= "" then

    -- Default duration.
    duration = duration or self.Tmessage

    -- Format message.
    local text
    if receiver and receiver == "" then
      -- No (blank) receiver.
      text = string.format( "%s", message )
    else
      -- Default "receiver" is onboard number of player.
      receiver = receiver or playerData.onboard
      text = string.format( "%s, %s", receiver, message )
    end
    self:T( self.lid .. text )

    if delay and delay > 0 then
      -- Delayed call.
      -- SCHEDULER:New(nil, self.MessageToPlayer, {self, playerData, message, sender, receiver, duration, clear}, delay)
      self:ScheduleOnce( delay, self.MessageToPlayer, self, playerData, message, sender, receiver, duration, clear )
    else

      -- Wait until previous sound finished.
      local wait = 0

      -- Onboard number to get the attention.
      if receiver == playerData.onboard then

        -- Which voice over number to use.
        if sender and (sender == "LSO" or sender == "MARSHAL" or sender == "AIRBOSS") then

          -- User sound of board number.
          wait = wait + self:_Number2Sound( playerData, sender, receiver )

        end
      end

      -- Negative.
      if string.find( text:lower(), "negative" ) then
        local filename = self:_RadioFilename( self.MarshalCall.NEGATIVE, false, "MARSHAL" )
        USERSOUND:New( filename ):ToGroup( playerData.group, wait )
        wait = wait + self.MarshalCall.NEGATIVE.duration
      end

      -- Affirm.
      if string.find( text:lower(), "affirm" ) then
        local filename = self:_RadioFilename( self.MarshalCall.AFFIRMATIVE, false, "MARSHAL" )
        USERSOUND:New( filename ):ToGroup( playerData.group, wait )
        wait = wait + self.MarshalCall.AFFIRMATIVE.duration
      end

      -- Roger.
      if string.find( text:lower(), "roger" ) then
        local filename = self:_RadioFilename( self.MarshalCall.ROGER, false, "MARSHAL" )
        USERSOUND:New( filename ):ToGroup( playerData.group, wait )
        wait = wait + self.MarshalCall.ROGER.duration
      end

      -- Play click sound to end message.
      if wait > 0 then
        local filename = self:_RadioFilename( self.MarshalCall.CLICK )
        USERSOUND:New( filename ):ToGroup( playerData.group, wait )
      end

      -- Text message to player client.
      if playerData.client then
        MESSAGE:New( text, duration, sender, clear ):ToClient( playerData.client )
      end

    end

  end
end

--- Send text message to all players in the pattern queue.
-- Message format will be "SENDER: RECCEIVER, MESSAGE".
-- @param #AIRBOSS self
-- @param #string message The message to send.
-- @param #string sender The person who sends the message or nil.
-- @param #string receiver The person who receives the message. Default player's onboard number. Set to "" for no receiver.
-- @param #number duration Display message duration. Default 10 seconds.
-- @param #boolean clear If true, clear screen from previous messages.
-- @param #number delay Delay in seconds, before the message is displayed.
function AIRBOSS:MessageToPattern( message, sender, receiver, duration, clear, delay )

  -- Create new (fake) radio call to show the subtitile.
  local call = self:_NewRadioCall( self.LSOCall.NOISE, sender or "LSO", message, duration, receiver, sender )

  -- Dummy radio transmission to display subtitle only to those who tuned in.
  self:RadioTransmission( self.LSORadio, call, false, delay, nil, true )

end

--- Send text message to all players in the marshal queue.
-- Message format will be "SENDER: RECCEIVER, MESSAGE".
-- @param #AIRBOSS self
-- @param #string message The message to send.
-- @param #string sender The person who sends the message or nil.
-- @param #string receiver The person who receives the message. Default player's onboard number. Set to "" for no receiver.
-- @param #number duration Display message duration. Default 10 seconds.
-- @param #boolean clear If true, clear screen from previous messages.
-- @param #number delay Delay in seconds, before the message is displayed.
function AIRBOSS:MessageToMarshal( message, sender, receiver, duration, clear, delay )

  -- Create new (fake) radio call to show the subtitile.
  local call = self:_NewRadioCall( self.MarshalCall.NOISE, sender or "MARSHAL", message, duration, receiver, sender )

  -- Dummy radio transmission to display subtitle only to those who tuned in.
  self:RadioTransmission( self.MarshalRadio, call, false, delay, nil, true )

end

--- Generate a new radio call (deepcopy) from an existing default call.
-- @param #AIRBOSS self
-- @param #AIRBOSS.RadioCall call Radio call to be enhanced.
-- @param #string sender Sender of the message. Default is the radio alias.
-- @param #string subtitle Subtitle of the message. Default from original radio call. Use "" for no subtitle.
-- @param #number subduration Time in seconds the subtitle is displayed. Default 10 seconds.
-- @param #string modexreceiver Onboard number of the receiver or nil.
-- @param #string modexsender Onboard number of the sender or nil.
function AIRBOSS:_NewRadioCall( call, sender, subtitle, subduration, modexreceiver, modexsender )

  -- Create a new call
  local newcall = UTILS.DeepCopy( call ) -- #AIRBOSS.RadioCall

  -- Sender for displaying the subtitle.
  newcall.sender = sender

  -- Subtitle of the message.
  newcall.subtitle = subtitle or call.subtitle

  -- Duration of subtitle display.
  newcall.subduration = subduration or self.Tmessage

  -- Tail number of the receiver.
  if self:_IsOnboard( modexreceiver ) then
    newcall.modexreceiver = modexreceiver
  end

  -- Tail number of the sender.
  if self:_IsOnboard( modexsender ) then
    newcall.modexsender = modexsender
  end

  return newcall
end

--- Get unit from which we want to transmit a radio message. This has to be an aircraft for subtitles to work.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Radio radio Airboss radio data.
-- @return Wrapper.Unit#UNIT Sending aircraft unit or nil if was not setup, is not an aircraft or is not alive.
function AIRBOSS:_GetRadioSender( radio )

  -- Check if we have a sending aircraft.
  local sender = nil -- Wrapper.Unit#UNIT

  -- Try the general default.
  if self.senderac then
    sender = UNIT:FindByName( self.senderac )
  end

  -- Try the specific marshal unit.
  if radio.alias == "MARSHAL" then
    if self.radiorelayMSH then
      sender = UNIT:FindByName( self.radiorelayMSH )
    end
  end

  -- Try the specific LSO unit.
  if radio.alias == "LSO" then
    if self.radiorelayLSO then
      sender = UNIT:FindByName( self.radiorelayLSO )
    end
  end

  -- Check that sender is alive and an aircraft.
  if sender and sender:IsAlive() and sender:IsAir() then
    return sender
  end

  return nil
end

--- Check if text is an onboard number of a flight.
-- @param #AIRBOSS self
-- @param #string text Text to check.
-- @return #boolean If true, text is an onboard number of a flight.
function AIRBOSS:_IsOnboard( text )

  -- Nil check.
  if text == nil then
    return false
  end

  -- Message to all.
  if text == "99" then
    return true
  end

  -- Loop over all flights.
  for _, _flight in pairs( self.flights ) do
    local flight = _flight -- #AIRBOSS.FlightGroup

    -- Loop over all onboard number of that flight.
    for _, onboard in pairs( flight.onboardnumbers ) do
      if text == onboard then
        return true
      end
    end

  end

  return false
end

--- Convert a number (as string) into an outsound and play it to a player group. E.g. for board number or headings.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data.
-- @param #string sender Who is sending the call, either "LSO" or "MARSHAL".
-- @param #string number Number string, e.g. "032" or "183".
-- @param #number delay Delay before transmission in seconds.
-- @return #number Duration of the call in seconds.
function AIRBOSS:_Number2Sound( playerData, sender, number, delay )

  -- Default.
  delay = delay or 0

  --- Split string into characters.
  local function _split( str )
    local chars = {}
    for i = 1, #str do
      local c = str:sub( i, i )
      table.insert( chars, c )
    end
    return chars
  end

  -- Sender
  local Sender
  if sender == "LSO" then
    Sender = "LSOCall"
  elseif sender == "MARSHAL" or sender == "AIRBOSS" then
    Sender = "MarshalCall"
  else
    self:E( self.lid .. string.format( "ERROR: Unknown radio sender %s!", tostring( sender ) ) )
    return
  end

  -- Split string into characters.
  local numbers = _split( number )

  local wait = 0
  for i = 1, #numbers do

    -- Current number
    local n = numbers[i]

    -- Convert to N0, N1, ...
    local N = string.format( "N%s", n )

    -- Radio call.
    local call = self[Sender][N] -- #AIRBOSS.RadioCall

    -- Create file name.
    local filename = self:_RadioFilename( call, false, Sender )

    -- Play sound.
    USERSOUND:New( filename ):ToGroup( playerData.group, delay + wait )

    -- Wait until this call is over before playing the next.
    wait = wait + call.duration
  end

  return wait
end

--- Convert a number (as string) into a radio message.
-- E.g. for board number or headings.
-- @param #AIRBOSS self
-- @param #AIRBOSS.Radio radio Radio used for transmission.
-- @param #string number Number string, e.g. "032" or "183".
-- @param #number delay Delay before transmission in seconds.
-- @param #number interval Interval between the next call.
-- @param #boolean pilotcall If true, use pilot sound files.
-- @return #number Duration of the call in seconds.
function AIRBOSS:_Number2Radio( radio, number, delay, interval, pilotcall )

  --- Split string into characters.
  local function _split( str )
    local chars = {}
    for i = 1, #str do
      local c = str:sub( i, i )
      table.insert( chars, c )
    end
    return chars
  end

  -- Sender.
  local Sender = ""
  if radio.alias == "LSO" then
    Sender = "LSOCall"
  elseif radio.alias == "MARSHAL" then
    Sender = "MarshalCall"
  else
    self:E( self.lid .. string.format( "ERROR: Unknown radio alias %s!", tostring( radio.alias ) ) )
  end

  if pilotcall then
    Sender = "PilotCall"
  end

  -- Split string into characters.
  local numbers = _split( number )

  local wait = 0
  for i = 1, #numbers do

    -- Current number
    local n = numbers[i]

    -- Convert to N0, N1, ...
    local N = string.format( "N%s", n )

    -- Radio call.
    local call = self[Sender][N] -- #AIRBOSS.RadioCall

    if interval and i == 1 then
      -- Transmit.
      self:RadioTransmission( radio, call, false, delay, interval )
    else
      self:RadioTransmission( radio, call, false, delay )
    end

    -- Add up duration of the number.
    wait = wait + call.duration
  end

  -- Return the total duration of the call.
  return wait
end

--- Aircraft request marshal (Inbound call both for players and AI).
-- @param #AIRBOSS self
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @param #string modex Tail number.
function AIRBOSS:_MarshallInboundCall(unit, modex)

  -- Calculate 
  local vectorCarrier = self:GetCoordinate():GetDirectionVec3(unit:GetCoordinate())
  local bearing =  UTILS.Round(unit:GetCoordinate():GetAngleDegrees( vectorCarrier ), 0)
  local distance = UTILS.Round(UTILS.MetersToNM(unit:GetCoordinate():Get2DDistance(self:GetCoordinate())),0)
  local angels = UTILS.Round(UTILS.MetersToFeet(unit:GetHeight()/1000),0)
  local state = UTILS.Round(self:_GetFuelState(unit)/1000,1)
  
  -- Pilot: "Marshall, [modex], marking mom's [bearing] for [distance], angels [XX], state [X.X]"
  local text=string.format("Marshal, %s, marking mom's %d for %d, angels %d, state %.1f", modex, bearing, distance, angels, state)
  -- Debug message.
  self:T(self.lid..text)

  -- Fuel state.
  local FS=UTILS.Split(string.format("%.1f", state), ".")

  -- Create new call to display complete subtitle.
  local inboundcall=self:_NewRadioCall(self.MarshalCall.CLICK,  unit.UnitName:upper() , text, self.Tmessage, nil, unit.UnitName:upper())

  -- CLICK!
  self:RadioTransmission(self.MarshalRadio, inboundcall)
  -- Marshal ..
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.MARSHAL, nil, nil, nil, nil, true)
  -- Modex..
  self:_Number2Radio(self.MarshalRadio, modex, nil, nil, true)
  -- Marking Mom's,
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.MARKINGMOMS, nil, nil, nil, nil, true)
  -- Bearing ..
  self:_Number2Radio(self.MarshalRadio, tostring(bearing), nil, nil, true)
  -- For ..
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.FOR, nil, nil, nil, nil, true)
  -- Distance ..
  self:_Number2Radio(self.MarshalRadio, tostring(distance), nil, nil, true)
  -- Angels ..
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.ANGELS, nil, nil, nil, nil, true)
  -- Angels Number ..
  self:_Number2Radio(self.MarshalRadio, tostring(angels), nil, nil, true)
  -- State ..
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.STATE, nil, nil, nil, nil, true)
  -- X..
  self:_Number2Radio(self.MarshalRadio, FS[1], nil, nil, true)
  -- Point..
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.POINT, nil, nil, nil, nil, true)
  -- Y.
  self:_Number2Radio(self.MarshalRadio, FS[2], nil, nil, true)
  -- CLICK!
  self:RadioTransmission(self.MarshalRadio, self.MarshalRadio.CLICK, nil, nil, nil, nil, true)

end

--- Aircraft commencing call (both for players and AI).
-- @param #AIRBOSS self
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @param #string modex Tail number.
function AIRBOSS:_CommencingCall(unit, modex)

  -- Pilot: "[modex], commencing"
  local text=string.format("%s, commencing", modex)
  -- Debug message.
  self:T(self.lid..text)

  -- Create new call to display complete subtitle.
  local commencingCall=self:_NewRadioCall(self.MarshalCall.CLICK,  unit.UnitName:upper() , text, self.Tmessage, nil, unit.UnitName:upper())

  -- Click
  self:RadioTransmission(self.MarshalRadio, commencingCall)
  -- Modex..
  self:_Number2Radio(self.MarshalRadio, modex, nil, nil, true)
  -- Commencing
  self:RadioTransmission(self.MarshalRadio, self.PilotCall.COMMENCING, nil, nil, nil, nil, true)
  -- CLICK!
  self:RadioTransmission(self.MarshalRadio, self.MarshalRadio.CLICK, nil, nil, nil, nil, true)

end

--- AI aircraft calls the ball.
-- @param #AIRBOSS self
-- @param #string modex Tail number.
-- @param #string nickname Aircraft nickname.
-- @param #number fuelstate Aircraft fuel state in thouthands of pounds.
function AIRBOSS:_LSOCallAircraftBall( modex, nickname, fuelstate )

  -- Pilot: "405, Hornet Ball, 3.2"
  local text = string.format( "%s Ball, %.1f.", nickname, fuelstate )

  -- Debug message.
  self:I( self.lid .. text )

  -- Nickname UPPERCASE.
  local NICKNAME = nickname:upper()

  -- Fuel state.
  local FS = UTILS.Split( string.format( "%.1f", fuelstate ), "." )

  -- Create new call to display complete subtitle.
  local call = self:_NewRadioCall( self.PilotCall[NICKNAME], modex, text, self.Tmessage, nil, modex )

  -- Hornet ..
  self:RadioTransmission( self.LSORadio, call, nil, nil, nil, nil, true )
  -- Ball,
  self:RadioTransmission( self.LSORadio, self.PilotCall.BALL, nil, nil, nil, nil, true )
  -- X..
  self:_Number2Radio( self.LSORadio, FS[1], nil, nil, true )
  -- Point..
  self:RadioTransmission( self.LSORadio, self.PilotCall.POINT, nil, nil, nil, nil, true )
  -- Y.
  self:_Number2Radio( self.LSORadio, FS[2], nil, nil, true )

  -- CLICK!
  self:RadioTransmission( self.LSORadio, self.LSOCall.CLICK )

end

--- AI is bingo and goes to the recovery tanker.
-- @param #AIRBOSS self
-- @param #string modex Tail number.
function AIRBOSS:_MarshalCallGasAtTanker( modex )

  -- Subtitle.
  local text = string.format( "Bingo fuel! Going for gas at the recovery tanker." )

  -- Debug message.
  self:I( self.lid .. text )


  -- Create new call to display complete subtitle.
  local call = self:_NewRadioCall( self.PilotCall.BINGOFUEL, modex, text, self.Tmessage, nil, modex )

  -- MODEX, bingo fuel!
  self:RadioTransmission( self.MarshalRadio, call, nil, nil, nil, nil, true )

  -- Going for fuel at the recovery tanker. Click!
  self:RadioTransmission( self.MarshalRadio, self.PilotCall.GASATTANKER, nil, nil, nil, true, true )

end

--- AI is bingo and goes to the divert field.
-- @param #AIRBOSS self
-- @param #string modex Tail number.
-- @param #string divertname Name of the divert field.
function AIRBOSS:_MarshalCallGasAtDivert( modex, divertname )

  -- Subtitle.
  local text = string.format( "Bingo fuel! Going for gas at divert field %s.", divertname )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call to display complete subtitle.
  local call = self:_NewRadioCall( self.PilotCall.BINGOFUEL, modex, text, self.Tmessage, nil, modex )

  -- MODEX, bingo fuel!
  self:RadioTransmission( self.MarshalRadio, call, nil, nil, nil, nil, true )

  -- Going for fuel at the divert field. Click!
  self:RadioTransmission( self.MarshalRadio, self.PilotCall.GASATDIVERT, nil, nil, nil, true, true )

end

--- Inform everyone that recovery ops are stopped and deck is closed.
-- @param #AIRBOSS self
-- @param #number case Recovery case.
function AIRBOSS:_MarshalCallRecoveryStopped( case )

  -- Subtitle.
  local text = string.format( "Case %d recovery ops are stopped. Deck is closed.", case )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call to display complete subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.CASE, "AIRBOSS", text, self.Tmessage, "99" )

  -- 99, Case..
  self:RadioTransmission( self.MarshalRadio, call )
  -- X.
  self:_Number2Radio( self.MarshalRadio, tostring( case ) )
  -- recovery ops are stopped.
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.RECOVERYOPSSTOPPED, nil, nil, 0.2 )
  -- Deck is closed. Click!
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.DECKCLOSED, nil, nil, nil, true )

end

--- Inform everyone that recovery is paused and will resume at a certain time.
-- @param #AIRBOSS self
function AIRBOSS:_MarshalCallRecoveryPausedUntilFurtherNotice()

  -- Create new call. Subtitle already set.
  local call = self:_NewRadioCall( self.MarshalCall.RECOVERYPAUSEDNOTICE, "AIRBOSS", nil, self.Tmessage, "99" )

  -- 99, aircraft recovery is paused until further notice.
  self:RadioTransmission( self.MarshalRadio, call, nil, nil, nil, true )

end

--- Inform everyone that recovery is paused and will resume at a certain time.
-- @param #AIRBOSS self
-- @param #string clock Time.
function AIRBOSS:_MarshalCallRecoveryPausedResumedAt( clock )

  -- Get relevant part of clock.
  local _clock = UTILS.Split( clock, "+" )
  local CT = UTILS.Split( _clock[1], ":" )

  -- Subtitle.
  local text = string.format( "aircraft recovery is paused and will be resumed at %s.", clock )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call with full subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.RECOVERYPAUSEDRESUMED, "AIRBOSS", text, self.Tmessage, "99" )

  -- 99, aircraft recovery is paused and will resume at...
  self:RadioTransmission( self.MarshalRadio, call )

  -- XY.. (hours)
  self:_Number2Radio( self.MarshalRadio, CT[1] )
  -- XY (minutes)..
  self:_Number2Radio( self.MarshalRadio, CT[2] )
  -- hours. Click!
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.HOURS, nil, nil, nil, true )

end

--- Inform flight that he is cleared for recovery.
-- @param #AIRBOSS self
-- @param #string modex Tail number.
-- @param #number case Recovery case.
function AIRBOSS:_MarshalCallClearedForRecovery( modex, case )

  -- Subtitle.
  local text = string.format( "you're cleared for Case %d recovery.", case )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call with full subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.CLEAREDFORRECOVERY, "MARSHAL", text, self.Tmessage, modex )

  -- Two second delay.
  local delay = 2

  -- XYZ, you're cleared for case..
  self:RadioTransmission( self.MarshalRadio, call, nil, delay )
  -- X..
  self:_Number2Radio( self.MarshalRadio, tostring( case ), delay )
  -- recovery. Click!
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.RECOVERY, nil, delay, nil, true )

end

--- Inform everyone that recovery is resumed after pause.
-- @param #AIRBOSS self
function AIRBOSS:_MarshalCallResumeRecovery()

  -- Create new call with full subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.RESUMERECOVERY, "AIRBOSS", nil, self.Tmessage, "99" )

  -- 99, aircraft recovery resumed. Click!
  self:RadioTransmission( self.MarshalRadio, call, nil, nil, nil, true )

end

--- Inform everyone about new final bearing.
-- @param #AIRBOSS self
-- @param #number FB Final Bearing in degrees.
function AIRBOSS:_MarshalCallNewFinalBearing( FB )

  -- Subtitle.
  local text = string.format( "new final bearing %03d°.", FB )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call with full subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.NEWFB, "AIRBOSS", text, self.Tmessage, "99" )

  -- 99, new final bearing..
  self:RadioTransmission( self.MarshalRadio, call )
  -- XYZ..
  self:_Number2Radio( self.MarshalRadio, string.format( "%03d", FB ), nil, 0.2 )
  -- Degrees. Click!
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.DEGREES, nil, nil, nil, true )

end

--- Compile a radio call when Marshal tells a flight the holding altitude.
-- @param #AIRBOSS self
-- @param #number hdg Heading in degrees.
function AIRBOSS:_MarshalCallCarrierTurnTo( hdg )

  -- Subtitle.
  local text = string.format( "carrier is now starting turn to heading %03d°.", hdg )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call with full subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.CARRIERTURNTOHEADING, "AIRBOSS", text, self.Tmessage, "99" )

  -- 99, turning to heading...
  self:RadioTransmission( self.MarshalRadio, call )
  -- XYZ..
  self:_Number2Radio( self.MarshalRadio, string.format( "%03d", hdg ), nil, 0.2 )
  -- Degrees. Click!
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.DEGREES, nil, nil, nil, true )

end

--- Compile a radio call when Marshal tells a flight the holding altitude.
-- @param #AIRBOSS self
-- @param #string modex Tail number.
-- @param #number nwaiting Number of flights already waiting.
function AIRBOSS:_MarshalCallStackFull( modex, nwaiting )

  -- Subtitle.
  local text = string.format( "Marshal stack is currently full. Hold outside 10 NM zone and wait for further instructions. " )
  if nwaiting == 1 then
    text = text .. string.format( "There is one flight ahead of you." )
  elseif nwaiting > 1 then
    text = text .. string.format( "There are %d flights ahead of you.", nwaiting )
  else
    text = text .. string.format( "You are next in line." )
  end

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call with full subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.STACKFULL, "AIRBOSS", text, self.Tmessage, modex )

  -- XYZ, Marshal stack is currently full.
  self:RadioTransmission( self.MarshalRadio, call, nil, nil, nil, true )
end

--- Compile a radio call when Marshal tells a flight the holding altitude.
-- @param #AIRBOSS self
function AIRBOSS:_MarshalCallRecoveryStart( case )

  -- Marshal radial.
  local radial = self:GetRadial( case, true, true, false )

  -- Debug output.
  local text = string.format( "Starting aircraft recovery Case %d ops.", case )
  if case == 1 then
    text = text .. string.format( " BRC %03d°.", self:GetBRC() )
  elseif case == 2 then
    text = text .. string.format( " Marshal radial %03d°. BRC %03d°.", radial, self:GetBRC() )
  elseif case == 3 then
    text = text .. string.format( " Marshal radial %03d°. Final heading %03d°.", radial, self:GetFinalBearing( false ) )
  end
  self:T( self.lid .. text )

  -- New call including the subtitle.
  local call = self:_NewRadioCall( self.MarshalCall.STARTINGRECOVERY, "AIRBOSS", text, self.Tmessage, "99" )

  -- 99, Starting aircraft recovery case..
  self:RadioTransmission( self.MarshalRadio, call )
  -- X..
  self:_Number2Radio( self.MarshalRadio, tostring( case ), nil, 0.1 )
  -- ops.
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.OPS )

  -- Marshal Radial
  if case > 1 then
    -- Marshal radial..
    self:RadioTransmission( self.MarshalRadio, self.MarshalCall.MARSHALRADIAL )
    -- XYZ..
    self:_Number2Radio( self.MarshalRadio, string.format( "%03d", radial ), nil, 0.2 )
    -- Degrees.
    self:RadioTransmission( self.MarshalRadio, self.MarshalCall.DEGREES, nil, nil, nil, true )
  end

end

--- Compile a radio call when Marshal tells a flight the holding altitude.
-- @param #AIRBOSS self
-- @param #string modex Tail number.
-- @param #number case Recovery case.
-- @param #number brc Base recovery course.
-- @param #number altitude Holding altitude.
-- @param #string charlie Charlie Time estimate.
-- @param #number qfe Alitmeter inHg.
function AIRBOSS:_MarshalCallArrived( modex, case, brc, altitude, charlie, qfe )
  self:F( { modex = modex, case = case, brc = brc, altitude = altitude, charlie = charlie, qfe = qfe } )

  -- Split strings etc.
  local angels = self:_GetAngels( altitude )
  -- local QFE=UTILS.Split(tostring(UTILS.Round(qfe,2)), ".")
  local QFE = UTILS.Split( string.format( "%.2f", qfe ), "." )
  local clock = UTILS.Split( charlie, "+" )
  local CT = UTILS.Split( clock[1], ":" )

  -- Subtitle text.
  local text = string.format( "Case %d, expected BRC %03d°, hold at angels %d. Expected Charlie Time %s. Altimeter %.2f. Report see me.", case, brc, angels, charlie, qfe )

  -- Debug message.
  self:I( self.lid .. text )

  -- Create new call to display complete subtitle.
  local casecall = self:_NewRadioCall( self.MarshalCall.CASE, "MARSHAL", text, self.Tmessage, modex )

  -- Case..
  self:RadioTransmission( self.MarshalRadio, casecall )
  -- X.
  self:_Number2Radio( self.MarshalRadio, tostring( case ) )

  -- Expected..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.EXPECTED, nil, nil, 0.5 )
  -- BRC..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.BRC )
  -- XYZ...
  self:_Number2Radio( self.MarshalRadio, string.format( "%03d", brc ) )
  -- Degrees.
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.DEGREES )

  -- Hold at..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.HOLDATANGELS, nil, nil, 0.5 )
  -- X.
  self:_Number2Radio( self.MarshalRadio, tostring( angels ) )

  -- Expected..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.EXPECTED, nil, nil, 0.5 )
  -- Charlie time..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.CHARLIETIME )
  -- XY.. (hours)
  self:_Number2Radio( self.MarshalRadio, CT[1] )
  -- XY (minutes).
  self:_Number2Radio( self.MarshalRadio, CT[2] )
  -- hours.
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.HOURS )

  -- Altimeter..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.ALTIMETER, nil, nil, 0.5 )
  -- XY..
  self:_Number2Radio( self.MarshalRadio, QFE[1] )
  -- Point..
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.POINT )
  -- XY.
  self:_Number2Radio( self.MarshalRadio, QFE[2] )

  -- Report see me. Click!
  self:RadioTransmission( self.MarshalRadio, self.MarshalCall.REPORTSEEME, nil, nil, 0.5, true )

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RADIO MENU Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #AIRBOSS self
-- @param #string _unitName Name of player unit.
function AIRBOSS:_AddF10Commands( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group = _unit:GetGroup()
    local gid = group:GetID()

    if group and gid then

      if not self.menuadded[gid] then

        -- Enable switch so we don't do this twice.
        self.menuadded[gid] = true

        -- Set menu root path.
        local _rootPath = nil
        if AIRBOSS.MenuF10Root then
          ------------------------
          -- MISSON LEVEL MENUE --
          ------------------------

          if self.menusingle then
            -- F10/Airboss/...
            _rootPath = AIRBOSS.MenuF10Root
          else
            -- F10/Airboss/<Carrier Alias>/...
            _rootPath = missionCommands.addSubMenuForGroup( gid, self.alias, AIRBOSS.MenuF10Root )
          end

        else
          ------------------------
          -- GROUP LEVEL MENUES --
          ------------------------

          -- Main F10 menu: F10/Airboss/
          if AIRBOSS.MenuF10[gid] == nil then
            AIRBOSS.MenuF10[gid] = missionCommands.addSubMenuForGroup( gid, "Airboss" )
          end

          if self.menusingle then
            -- F10/Airboss/...
            _rootPath = AIRBOSS.MenuF10[gid]
          else
            -- F10/Airboss/<Carrier Alias>/...
            _rootPath = missionCommands.addSubMenuForGroup( gid, self.alias, AIRBOSS.MenuF10[gid] )
          end

        end

        --------------------------------
        -- F10/Airboss/<Carrier>/F1 Help
        --------------------------------
        local _helpPath = missionCommands.addSubMenuForGroup( gid, "Help", _rootPath )
        -- F10/Airboss/<Carrier>/F1 Help/F1 Mark Zones
        if self.menumarkzones then
          local _markPath = missionCommands.addSubMenuForGroup( gid, "Mark Zones", _helpPath )
          -- F10/Airboss/<Carrier>/F1 Help/F1 Mark Zones/
          if self.menusmokezones then
            missionCommands.addCommandForGroup( gid, "Smoke Pattern Zones", _markPath, self._MarkCaseZones, self, _unitName, false ) -- F1
          end
          missionCommands.addCommandForGroup( gid, "Flare Pattern Zones", _markPath, self._MarkCaseZones, self, _unitName, true ) -- F2
          if self.menusmokezones then
            missionCommands.addCommandForGroup( gid, "Smoke Marshal Zone", _markPath, self._MarkMarshalZone, self, _unitName, false ) -- F3
          end
          missionCommands.addCommandForGroup( gid, "Flare Marshal Zone", _markPath, self._MarkMarshalZone, self, _unitName, true ) -- F4
        end
        -- F10/Airboss/<Carrier>/F1 Help/F2 Skill Level
        local _skillPath = missionCommands.addSubMenuForGroup( gid, "Skill Level", _helpPath )
        -- F10/Airboss/<Carrier>/F1 Help/F2 Skill Level/
        missionCommands.addCommandForGroup( gid, "Flight Student", _skillPath, self._SetDifficulty, self, _unitName, AIRBOSS.Difficulty.EASY ) -- F1
        missionCommands.addCommandForGroup( gid, "Naval Aviator", _skillPath, self._SetDifficulty, self, _unitName, AIRBOSS.Difficulty.NORMAL ) -- F2
        missionCommands.addCommandForGroup( gid, "TOPGUN Graduate", _skillPath, self._SetDifficulty, self, _unitName, AIRBOSS.Difficulty.HARD ) -- F3
        missionCommands.addCommandForGroup( gid, "Hints On/Off", _skillPath, self._SetHintsOnOff, self, _unitName ) -- F4
        -- F10/Airboss/<Carrier>/F1 Help/
        missionCommands.addCommandForGroup( gid, "My Status", _helpPath, self._DisplayPlayerStatus, self, _unitName ) -- F3
        missionCommands.addCommandForGroup( gid, "Attitude Monitor", _helpPath, self._DisplayAttitude, self, _unitName ) -- F4
        missionCommands.addCommandForGroup( gid, "Radio Check LSO", _helpPath, self._LSORadioCheck, self, _unitName ) -- F5
        missionCommands.addCommandForGroup( gid, "Radio Check Marshal", _helpPath, self._MarshalRadioCheck, self, _unitName ) -- F6
        missionCommands.addCommandForGroup( gid, "Subtitles On/Off", _helpPath, self._SubtitlesOnOff, self, _unitName ) -- F7
        missionCommands.addCommandForGroup( gid, "Trapsheet On/Off", _helpPath, self._TrapsheetOnOff, self, _unitName ) -- F8

        -------------------------------------
        -- F10/Airboss/<Carrier>/F2 Kneeboard
        -------------------------------------
        local _kneeboardPath = missionCommands.addSubMenuForGroup( gid, "Kneeboard", _rootPath )
        -- F10/Airboss/<Carrier>/F2 Kneeboard/F1 Results
        local _resultsPath = missionCommands.addSubMenuForGroup( gid, "Results", _kneeboardPath )
        -- F10/Airboss/<Carrier>/F2 Kneeboard/F1 Results/
        missionCommands.addCommandForGroup( gid, "Greenie Board", _resultsPath, self._DisplayScoreBoard, self, _unitName ) -- F1
        missionCommands.addCommandForGroup( gid, "My LSO Grades", _resultsPath, self._DisplayPlayerGrades, self, _unitName ) -- F2
        missionCommands.addCommandForGroup( gid, "Last Debrief", _resultsPath, self._DisplayDebriefing, self, _unitName ) -- F3

        -- F10/Airboss/<Carrier>/F2 Kneeboard/F2 Skipper/
        if self.skipperMenu then
          local _skipperPath = missionCommands.addSubMenuForGroup( gid, "Skipper", _kneeboardPath )
          local _menusetspeed = missionCommands.addSubMenuForGroup( gid, "Set Speed", _skipperPath )
          missionCommands.addCommandForGroup( gid, "10 knots", _menusetspeed, self._SkipperRecoverySpeed, self, _unitName, 10 )
          missionCommands.addCommandForGroup( gid, "15 knots", _menusetspeed, self._SkipperRecoverySpeed, self, _unitName, 15 )
          missionCommands.addCommandForGroup( gid, "20 knots", _menusetspeed, self._SkipperRecoverySpeed, self, _unitName, 20 )
          missionCommands.addCommandForGroup( gid, "25 knots", _menusetspeed, self._SkipperRecoverySpeed, self, _unitName, 25 )
          missionCommands.addCommandForGroup( gid, "30 knots", _menusetspeed, self._SkipperRecoverySpeed, self, _unitName, 30 )
          local _menusetrtime = missionCommands.addSubMenuForGroup( gid, "Set Time", _skipperPath )
          missionCommands.addCommandForGroup( gid, "15 min", _menusetrtime, self._SkipperRecoveryTime, self, _unitName, 15 )
          missionCommands.addCommandForGroup( gid, "30 min", _menusetrtime, self._SkipperRecoveryTime, self, _unitName, 30 )
          missionCommands.addCommandForGroup( gid, "45 min", _menusetrtime, self._SkipperRecoveryTime, self, _unitName, 45 )
          missionCommands.addCommandForGroup( gid, "60 min", _menusetrtime, self._SkipperRecoveryTime, self, _unitName, 60 )
          missionCommands.addCommandForGroup( gid, "90 min", _menusetrtime, self._SkipperRecoveryTime, self, _unitName, 90 )
          local _menusetrtime = missionCommands.addSubMenuForGroup( gid, "Set Marshal Radial", _skipperPath )
          missionCommands.addCommandForGroup( gid, "+30°", _menusetrtime, self._SkipperRecoveryOffset, self, _unitName, 30 )
          missionCommands.addCommandForGroup( gid, "+15°", _menusetrtime, self._SkipperRecoveryOffset, self, _unitName, 15 )
          missionCommands.addCommandForGroup( gid, "0°", _menusetrtime, self._SkipperRecoveryOffset, self, _unitName, 0 )
          missionCommands.addCommandForGroup( gid, "-15°", _menusetrtime, self._SkipperRecoveryOffset, self, _unitName, -15 )
          missionCommands.addCommandForGroup( gid, "-30°", _menusetrtime, self._SkipperRecoveryOffset, self, _unitName, -30 )
          missionCommands.addCommandForGroup( gid, "U-turn On/Off", _skipperPath, self._SkipperRecoveryUturn, self, _unitName )
          missionCommands.addCommandForGroup( gid, "Start CASE I", _skipperPath, self._SkipperStartRecovery, self, _unitName, 1 )
          missionCommands.addCommandForGroup( gid, "Start CASE II", _skipperPath, self._SkipperStartRecovery, self, _unitName, 2 )
          missionCommands.addCommandForGroup( gid, "Start CASE III", _skipperPath, self._SkipperStartRecovery, self, _unitName, 3 )
          missionCommands.addCommandForGroup( gid, "Stop Recovery", _skipperPath, self._SkipperStopRecovery, self, _unitName )
        end

        -- F10/Airboss/<Carrier/F2 Kneeboard/
        missionCommands.addCommandForGroup( gid, "Carrier Info", _kneeboardPath, self._DisplayCarrierInfo, self, _unitName ) -- F2
        missionCommands.addCommandForGroup( gid, "Weather Report", _kneeboardPath, self._DisplayCarrierWeather, self, _unitName ) -- F3
        missionCommands.addCommandForGroup( gid, "Set Section", _kneeboardPath, self._SetSection, self, _unitName ) -- F4
        missionCommands.addCommandForGroup( gid, "Marshal Queue", _kneeboardPath, self._DisplayQueue, self, _unitName, "Marshal" ) -- F5
        missionCommands.addCommandForGroup( gid, "Pattern Queue", _kneeboardPath, self._DisplayQueue, self, _unitName, "Pattern" ) -- F6
        missionCommands.addCommandForGroup( gid, "Waiting Queue", _kneeboardPath, self._DisplayQueue, self, _unitName, "Waiting" ) -- F7

        -------------------------
        -- F10/Airboss/<Carrier>/
        -------------------------
        missionCommands.addCommandForGroup( gid, "Request Marshal", _rootPath, self._RequestMarshal, self, _unitName ) -- F3
        missionCommands.addCommandForGroup( gid, "Request Commence", _rootPath, self._RequestCommence, self, _unitName ) -- F4
        missionCommands.addCommandForGroup( gid, "Request Refueling", _rootPath, self._RequestRefueling, self, _unitName ) -- F5
        missionCommands.addCommandForGroup( gid, "Spinning", _rootPath, self._RequestSpinning, self, _unitName ) -- F6
        missionCommands.addCommandForGroup( gid, "Emergency Landing", _rootPath, self._RequestEmergency, self, _unitName ) -- F7
        missionCommands.addCommandForGroup( gid, "[Reset My Status]", _rootPath, self._ResetPlayerStatus, self, _unitName ) -- F8
      end
    else
      self:E( self.lid .. string.format( "ERROR: Could not find group or group ID in AddF10Menu() function. Unit name: %s.", _unitName ) )
    end
  else
    self:E( self.lid .. string.format( "ERROR: Player unit does not exist in AddF10Menu() function. Unit name: %s.", _unitName ) )
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SKIPPER MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Reset player status. Player is removed from all queues and its status is set to undefined.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
-- @param #number case Recovery case.
function AIRBOSS:_SkipperStartRecovery( _unitName, case )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Inform player.
      local text = string.format( "affirm, Case %d recovery will start in 5 min for %d min. Wind on deck %d knots. U-turn=%s.", case, self.skipperTime, self.skipperSpeed, tostring( self.skipperUturn ) )
      if case > 1 then
        text = text .. string.format( " Marshal radial %d°.", self.skipperOffset )
      end
      if self:IsRecovering() then
        text = "negative, carrier is already recovering."
        self:MessageToPlayer( playerData, text, "AIRBOSS" )
        return
      end
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

      -- Recovery staring in 5 min for 30 min.
      local t0 = timer.getAbsTime() + 5 * 60
      local t9 = t0 + self.skipperTime * 60
      local C0 = UTILS.SecondsToClock( t0 )
      local C9 = UTILS.SecondsToClock( t9 )

      -- Carrier will turn into the wind. Wind on deck 25 knots. U-turn on.
      self:AddRecoveryWindow( C0, C9, case, self.skipperOffset, true, self.skipperSpeed, self.skipperUturn )

    end
  end
end

--- Skipper Stop recovery function.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_SkipperStopRecovery( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Inform player.
      local text = "roger, stopping recovery right away."
      if not self:IsRecovering() then
        text = "negative, carrier is currently not recovering."
        self:MessageToPlayer( playerData, text, "AIRBOSS" )
        return
      end
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

      self:RecoveryStop()
    end
  end
end

--- Skipper set recovery offset angle.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
-- @param #number offset Recovery holding offset angle in degrees for Case II/III.
function AIRBOSS:_SkipperRecoveryOffset( _unitName, offset )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Inform player.
      local text = string.format( "roger, relative CASE II/III Marshal radial set to %d°.", offset )
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

      self.skipperOffset = offset
    end
  end
end

--- Skipper set recovery time.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
-- @param #number time Recovery time in minutes.
function AIRBOSS:_SkipperRecoveryTime( _unitName, time )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Inform player.
      local text = string.format( "roger, manual recovery time set to %d min.", time )
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

      self.skipperTime = time

    end
  end
end

--- Skipper set recovery speed.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
-- @param #number speed Recovery speed in knots.
function AIRBOSS:_SkipperRecoverySpeed( _unitName, speed )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Inform player.
      local text = string.format( "roger, wind on deck set to %d knots.", speed )
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

      self.skipperSpeed = speed
    end
  end
end

--- Skipper set recovery speed.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_SkipperRecoveryUturn( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      self.skipperUturn = not self.skipperUturn

      -- Inform player.
      local text = string.format( "roger, U-turn is now %s.", tostring( self.skipperUturn ) )
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ROOT MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Reset player status. Player is removed from all queues and its status is set to undefined.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_ResetPlayerStatus( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Inform player.
      local text = "roger, status reset executed! You have been removed from all queues."
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

      -- Remove flight from queues. Collapse marshal stack if necessary.
      -- Section members are removed from the Spinning queue. If flight is member, he is removed from the section.
      self:_RemoveFlight( playerData )

      -- Stop pending debrief scheduler.
      if playerData.debriefschedulerID and self.Scheduler then
        self.Scheduler:Stop( playerData.debriefschedulerID )
      end

      -- Initialize player data.
      self:_InitPlayer( playerData )

    end
  end
end

--- Request marshal.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_RequestMarshal( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Voice over of inbound call (regardless of airboss rejecting it or not)
      if self.xtVoiceOvers then
        self:_MarshallInboundCall(_unit, playerData.onboard)
      end   
    
      -- Check if player is in CCA
      local inCCA = playerData.unit:IsInZone( self.zoneCCA )

      if inCCA then

        if self:_InQueue( self.Qmarshal, playerData.group ) then

          -- Flight group is already in marhal queue.
          local text = string.format( "negative, you are already in the Marshal queue. New marshal request denied!" )
          self:MessageToPlayer( playerData, text, "MARSHAL" )

        elseif self:_InQueue( self.Qpattern, playerData.group ) then

          -- Flight group is already in pattern queue.
          local text = string.format( "negative, you are already in the Pattern queue. Marshal request denied!" )
          self:MessageToPlayer( playerData, text, "MARSHAL" )

        elseif self:_InQueue( self.Qwaiting, playerData.group ) then

          -- Flight group is already in pattern queue.
          local text = string.format( "negative, you are in the Waiting queue with %d flights ahead of you. Marshal request denied!", #self.Qwaiting )
          self:MessageToPlayer( playerData, text, "MARSHAL" )

        elseif not _unit:InAir() then

          -- Flight group is already in pattern queue.
          local text = string.format( "negative, you are not airborne. Marshal request denied!" )
          self:MessageToPlayer( playerData, text, "MARSHAL" )

        elseif playerData.name ~= playerData.seclead then

          -- Flight group is already in pattern queue.
          local text = string.format( "negative, your section lead %s needs to request Marshal.", playerData.seclead )
          self:MessageToPlayer( playerData, text, "MARSHAL" )

        else

          -- Get next free Marshal stack.
          local freestack = self:_GetFreeStack( playerData.ai )

          -- Check if stack is available. For Case I the number is limited.
          if freestack then

            -- Add flight to marshal stack.
            self:_MarshalPlayer( playerData, freestack )

          else

            -- Add flight to waiting queue.
            self:_WaitPlayer( playerData )

          end

        end

      else

        -- Flight group is not in CCA yet.
        local text = string.format( "negative, you are not inside CCA. Marshal request denied!" )
        self:MessageToPlayer( playerData, text, "MARSHAL" )

      end
    end
  end
end

--- Request emergency landing.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_RequestEmergency( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      local text = ""
      if not self.emergency then

        -- Mission designer did not allow emergency landing.
        text = "negative, no emergency landings on my carrier. We are currently busy. See how you get along!"

      elseif not _unit:InAir() then

        -- Carrier zone.
        local zone = self:_GetZoneCarrierBox()

        -- Check if player is on the carrier.
        if playerData.unit:IsInZone( zone ) then

          -- Bolter pattern.
          text = "roger, you are now technically in the bolter pattern. Your next step after takeoff is abeam!"

          -- Get flight lead.
          local lead = self:_GetFlightLead( playerData )

          -- Set set for lead.
          self:_SetPlayerStep( lead, AIRBOSS.PatternStep.BOLTER )

          -- Also set bolter pattern for all members.
          for _, sec in pairs( lead.section ) do
            local sectionmember = sec -- #AIRBOSS.PlayerData
            self:_SetPlayerStep( sectionmember, AIRBOSS.PatternStep.BOLTER )
          end

          -- Remove flight from waiting queue just in case.
          self:_RemoveFlightFromQueue( self.Qwaiting, lead )

          if self:_InQueue( self.Qmarshal, lead.group ) then
            -- Remove flight from Marshal queue and add to pattern.
            self:_RemoveFlightFromMarshalQueue( lead )
          else
            -- Add flight to pattern if he was not.
            if not self:_InQueue( self.Qpattern, lead.group ) then
              self:_AddFlightToPatternQueue( lead )
            end
          end

        else
          -- Flight group is not in air.
          text = string.format( "negative, you are not airborne. Request denied!" )
        end

      else

        -- Cleared.
        text = "affirmative, you can bypass the pattern and are cleared for final approach!"

        -- Now, if player is in the marshal or waiting queue he will be removed. But the new leader should stay in or not.
        local lead = self:_GetFlightLead( playerData )

        -- Set set for lead.
        self:_SetPlayerStep( lead, AIRBOSS.PatternStep.EMERGENCY )

        -- Also set emergency landing for all members.
        for _, sec in pairs( lead.section ) do
          local sectionmember = sec -- #AIRBOSS.PlayerData
          self:_SetPlayerStep( sectionmember, AIRBOSS.PatternStep.EMERGENCY )

          -- Remove flight from spinning queue just in case (everone can spin on his own).
          self:_RemoveFlightFromQueue( self.Qspinning, sectionmember )
        end

        -- Remove flight from waiting queue just in case.
        self:_RemoveFlightFromQueue( self.Qwaiting, lead )

        if self:_InQueue( self.Qmarshal, lead.group ) then
          -- Remove flight from Marshal queue and add to pattern.
          self:_RemoveFlightFromMarshalQueue( lead )
        else
          -- Add flight to pattern if he was not.
          if not self:_InQueue( self.Qpattern, lead.group ) then
            self:_AddFlightToPatternQueue( lead )
          end
        end

      end

      -- Send message.
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

    end

  end
end

--- Request spinning.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_RequestSpinning( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      local text = ""
      if not self:_InQueue( self.Qpattern, playerData.group ) then

        -- Player not in pattern queue.
        text = "negative, you have to be in the pattern to spin it!"

      elseif playerData.step == AIRBOSS.PatternStep.SPINNING then

        -- Player is already spinning.
        text = "negative, you are already spinning."

        -- Check if player is in the right step.
      elseif not (playerData.step == AIRBOSS.PatternStep.BREAKENTRY or
                  playerData.step == AIRBOSS.PatternStep.EARLYBREAK or
                  playerData.step == AIRBOSS.PatternStep.LATEBREAK) then

        -- Player is not in the right step.
        text = "negative, you have to be in the right step to spin it!"

      else

        -- Set player step.
        self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.SPINNING )

        -- Add player to spinning queue.
        table.insert( self.Qspinning, playerData )

        -- 405, Spin it! Click.
        local call = self:_NewRadioCall( self.LSOCall.SPINIT, "AIRBOSS", "Spin it!", self.Tmessage, playerData.onboard )
        self:RadioTransmission( self.LSORadio, call, nil, nil, nil, true )

        -- Some advice.
        if playerData.difficulty == AIRBOSS.Difficulty.EASY then
          local text = "Climb to 1200 feet and proceed to the initial again."
          self:MessageToPlayer( playerData, text, "INSTRUCTOR", "" )
        end

        return
      end

      -- Send message.
      self:MessageToPlayer( playerData, text, "AIRBOSS" )

    end
  end
end

--- Request to commence landing approach.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_RequestCommence( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then
   
      -- Voice over of Commencing call (regardless of Airboss will rejected or not)
      if self.xtVoiceOvers then
        self:_CommencingCall(_unit, playerData.onboard)
      end
      
      -- Check if unit is in CCA.
      local text = ""
      local cleared = false
      if _unit:IsInZone( self.zoneCCA ) then

        -- Get stack value.
        local stack = playerData.flag

        -- Number of airborne aircraft currently in pattern.
        local _, npattern = self:_GetQueueInfo( self.Qpattern )

        -- TODO: Check distance to initial or platform. Only allow commence if < max distance. Otherwise say bearing.

        if self:_InQueue( self.Qpattern, playerData.group ) then

          -- Flight group is already in pattern queue.
          text = string.format( "negative, %s, you are already in the Pattern queue.", playerData.name )

        elseif not _unit:InAir() then

          -- Flight group is already in pattern queue.
          text = string.format( "negative, %s, you are not airborne.", playerData.name )

        elseif playerData.seclead ~= playerData.name then

          -- Flight group is already in pattern queue.
          text = string.format( "negative, %s, your section leader %s has to request commence!", playerData.name, playerData.seclead )

        elseif stack > 1 then

          -- We are in a higher stack.
          text = string.format( "negative, %s, it's not your turn yet! You are in stack no. %s.", playerData.name, stack )

        elseif npattern >= self.Nmaxpattern then

          -- Patern is full!
          text = string.format( "negative ghostrider, pattern is full!\nThere are %d aircraft currently in the pattern.", npattern )

        elseif self:IsRecovering() == false and not self.airbossnice then

          -- Carrier is not recovering right now.
          if self.recoverywindow then
            local clock = UTILS.SecondsToClock( self.recoverywindow.START )
            text = string.format( "negative, carrier is currently not recovery. Next window will open at %s.", clock )
          else
            text = string.format( "negative, carrier is not recovering. No future windows planned." )
          end

        elseif not self:_InQueue( self.Qmarshal, playerData.group ) and not self.airbossnice then

          text = "negative, you have to request Marshal before you can commence."

        else

          -----------------------
          -- Positive Response --
          -----------------------

          text = text .. "roger."

          -- Carrier is not recovering but Airboss has a good day.
          if not self:IsRecovering() then
            text = text .. " Carrier is not recovering currently! However, you are cleared anyway as I have a nice day."
          end

          -- If player is not in the Marshal queue set player case to current case.
          if not self:_InQueue( self.Qmarshal, playerData.group ) then

            -- Set current case.
            playerData.case = self.case

            -- Hint about TACAN bearing.
            if self.TACANon and playerData.difficulty ~= AIRBOSS.Difficulty.HARD then
              -- Get inverse magnetic radial potential offset.
              local radial = self:GetRadial( playerData.case, true, true, true )
              if playerData.case == 1 then
                -- For case 1 we want the BRC but above routine return FB.
                radial = self:GetBRC()
              end
              text = text .. string.format( "\nSelect TACAN %03d°, Channel %d%s (%s).\n", radial, self.TACANchannel, self.TACANmode, self.TACANmorse )
            end

            -- TODO: Inform section members.

            -- Set case of section members as well. Not sure if necessary any more since it is set as soon as the recovery case is changed.
            for _, flight in pairs( playerData.section ) do
              flight.case = playerData.case
            end

            -- Add player to pattern queue. Usually this is done when the stack is collapsed but this player is not in the Marshal queue.
            self:_AddFlightToPatternQueue( playerData )
          end

          -- Clear player for commence.
          cleared = true
        end

      else
        -- This flight is not yet registered!
        text = string.format( "negative, %s, you are not inside the CCA!", playerData.name )
      end

      -- Debug
      self:T( self.lid .. text )

      -- Send message.
      self:MessageToPlayer( playerData, text, "MARSHAL" )

      -- Check if player was cleard. Need to do this after the message above is displayed.
      if cleared then
        -- Call commence routine. No zone check. NOTE: Commencing will set step for all section members as well.
        self:_Commencing( playerData, false )
      end
    end
  end
end

--- Player requests refueling.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_RequestRefueling( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Check if there is a recovery tanker defined.
      local text
      if self.tanker then

        -- Check if player is in CCA.
        if _unit:IsInZone( self.zoneCCA ) then

          -- Check if tanker is running or refueling or returning.
          if self.tanker:IsRunning() or self.tanker:IsRefueling() then

            -- Get alt of tanker in angels.
            -- local angels=UTILS.Round(UTILS.MetersToFeet(self.tanker.altitude)/1000, 0)
            local angels = self:_GetAngels( self.tanker.altitude )

            -- Tanker is up and running.
            text = string.format( "affirmative, proceed to tanker at angels %d.", angels )

            -- State TACAN channel of tanker if defined.
            if self.tanker.TACANon then
              text = text .. string.format( "\nTanker TACAN channel %d%s (%s).", self.tanker.TACANchannel, self.tanker.TACANmode, self.tanker.TACANmorse )
              text = text .. string.format( "\nRadio frequency %.3f MHz AM.", self.tanker.RadioFreq )
            end

            -- Tanker is currently refueling. Inform player.
            if self.tanker:IsRefueling() then
              text = text .. "\nTanker is currently refueling. You might have to queue up."
            end

            -- Collapse marshal stack if player is in queue.
            self:_RemoveFlightFromMarshalQueue( playerData, true )

            -- Set step to refueling.
            self:_SetPlayerStep( playerData, AIRBOSS.PatternStep.REFUELING )

            -- Inform section and set step.
            for _, sec in pairs( playerData.section ) do
              local sectext = "follow your section leader to the tanker."
              self:MessageToPlayer( sec, sectext, "MARSHAL" )
              self:_SetPlayerStep( sec, AIRBOSS.PatternStep.REFUELING )
            end

          elseif self.tanker:IsReturning() then
            -- Tanker is RTB.
            text = "negative, tanker is RTB. Request denied!\nWait for the tanker to be back on station if you can."
          end

        else
          text = "negative, you are not inside the CCA yet."
        end
      else
        text = "negative, no refueling tanker available."
      end

      -- Send message.
      self:MessageToPlayer( playerData, text, "MARSHAL" )
    end
  end
end

--- Remove a member from the player's section.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player
-- @param #AIRBOSS.PlayerData sectionmember The section member to be removed.
-- @return #boolean If true, flight was a section member and could be removed. False otherwise.
function AIRBOSS:_RemoveSectionMember( playerData, sectionmember )
  -- Loop over all flights in player's section
  for i, _flight in pairs( playerData.section ) do
    local flight = _flight -- #AIRBOSS.PlayerData
    if flight.name == sectionmember.name then
      table.remove( playerData.section, i )
      return true
    end
  end
  return false
end

--- Set all flights within 100 meters to be part of my section.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_SetSection( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Coordinate of flight lead.
      local mycoord = _unit:GetCoordinate()

      -- Max distance up to which section members are allowed.
      local dmax = 100

      -- Check if player is in Marshal or pattern queue already.
      local text
      if self.NmaxSection == 0 then
        text = string.format( "negative, setting sections is disabled in this mission. You stay alone." )
      elseif self:_InQueue( self.Qmarshal, playerData.group ) then
        text = string.format( "negative, you are already in the Marshal queue. Setting section not possible any more!" )
      elseif self:_InQueue( self.Qpattern, playerData.group ) then
        text = string.format( "negative, you are already in the Pattern queue. Setting section not possible any more!" )
      else

        -- Check if player is member of another section already. If so, remove him from his current section.
        if playerData.seclead ~= playerData.name then
          local lead = self.players[playerData.seclead] -- #AIRBOSS.PlayerData
          if lead then

            -- Remove player from his old section lead.
            local removed = self:_RemoveSectionMember( lead, playerData )
            if removed then
              self:MessageToPlayer( lead, string.format( "Flight %s has been removed from your section.", playerData.name ), "AIRBOSS", "", 5 )
              self:MessageToPlayer( playerData, string.format( "You have been removed from %s's section.", lead.name ), "AIRBOSS", "", 5 )
            end

          end
        end

        -- Potential section members.
        local section = {}

        -- Loop over all registered flights.
        for _, _flight in pairs( self.flights ) do
          local flight = _flight -- #AIRBOSS.FlightGroup

          -- Only human flight groups excluding myself. Also only flights that dont have a section itself (would get messy) or are part of another section (no double membership).
          if flight.ai == false and flight.groupname ~= playerData.groupname and #flight.section == 0 and flight.seclead == flight.name then

            -- Distance (3D) to other flight group.
            local distance = flight.group:GetCoordinate():Get3DDistance( mycoord )

            -- Check distance.
            if distance < dmax then
              self:T( self.lid .. string.format( "Found potential section member %s for lead %s at distance %.1f m.", flight.name, playerData.name, distance ) )
              table.insert( section, { flight = flight, distance = distance } )
            end

          end
        end

        -- Sort potential section members wrt to distance to lead.
        table.sort( section, function( a, b )
          return a.distance < b.distance
        end )

        -- Make player section lead if he was not before.
        playerData.seclead = playerData.name

        -- Loop over all flights in player's current section and inform those members that will be removed because they are not in range any more.
        for _, _flight in pairs( playerData.section ) do
          local flight = _flight -- #AIRBOSS.PlayerData

          -- Loop over all potential new members and check if they were already part of the player's section.
          local gotit = false
          for _, _new in pairs( section ) do
            local newflight = _new.flight -- #AIRBOSS.PlayerData
            if newflight.name == flight.name then
              gotit = true -- This is an old one that stays.
            end
          end

          -- Flight is not a member any more ==> remove it.
          if not gotit then
            self:MessageToPlayer( flight, string.format( "you were removed from %s's section and are on your own now.", playerData.name ), "AIRBOSS", "", 5 )
            flight.seclead = flight.name
            self:_RemoveSectionMember( playerData, flight )
          end
        end

        -- Remove all flights that are currently in the player's section already from scanned potential new section members.
        for i, _new in pairs( section ) do
          local newflight = _new.flight -- #AIRBOSS.PlayerData
          for _, _flight in pairs( playerData.section ) do
            local currentflight = _flight -- #AIRBOSS.PlayerData
            if newflight.name == currentflight.name then
              table.remove( section, i )
            end
          end
        end

        -- Init section table. Should not be necessary as all members are removed anyhow above.
        -- playerData.section={}

        -- Output text.
        text = string.format( "Registered flight section:" )
        text = text .. string.format( "\n- %s (lead)", playerData.seclead )
        -- Old members that stay (if any).
        for _, _flight in pairs( playerData.section ) do
          local flight = _flight -- #AIRBOSS.PlayerData
          text = text .. string.format( "\n- %s", flight.name )
        end
        -- New members (if any).
        for i = 1, math.min( self.NmaxSection - #playerData.section, #section ) do
          local flight = section[i].flight -- #AIRBOSS.PlayerData

          -- New flight members.
          text = text .. string.format( "\n- %s", flight.name )

          -- Set section lead of player flight.
          flight.seclead = playerData.name

          -- Set case of f
          flight.case = playerData.case

          -- Inform player that he is now part of a section.
          self:MessageToPlayer( flight, string.format( "your section lead is now %s.", playerData.name ), "AIRBOSS" )

          -- Add flight to section table.
          table.insert( playerData.section, flight )
        end

        -- Section is empty.
        if #playerData.section == 0 then
          text = text .. string.format( "\n- No other human flights found within radius of %.1f meters!", dmax )
        end

      end

      -- Message to section lead.
      self:MessageToPlayer( playerData, text, "MARSHAL" )
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RESULTS MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Display top 10 player scores.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayScoreBoard( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then

    -- Results table.
    local _playerResults = {}

    -- Calculate average points for all players.
    for playerName, playerGrades in pairs( self.playerscores ) do

      if playerGrades then

        -- Loop over all grades
        local Paverage = 0
        local n = 0
        for _, _grade in pairs( playerGrades ) do
          local grade = _grade -- #AIRBOSS.LSOgrade

          -- Add up only final scores for the average.
          if grade.finalscore then -- grade.points>=0 then
            Paverage = Paverage + grade.finalscore
            n = n + 1
          else
            -- Case when the player just leaves after an unfinished pass, e.g bolter, without landing.
            -- But this should now be solved by deleteing all unfinished results.
          end
        end

        -- We dont want to devide by zero.
        if n > 0 then
          _playerResults[playerName] = Paverage / n
        end

      end
    end

    -- Message text.
    local text = string.format( "Greenie Board (top ten):" )
    local i = 1
    for _playerName, _points in UTILS.spairs( _playerResults, function( t, a, b )
      return t[b] < t[a]
    end ) do

      -- Text.
      text = text .. string.format( "\n[%d] %s %.1f||", i, _playerName, _points )

      -- All player grades.
      local playerGrades = self.playerscores[_playerName]

      -- Add grades of passes. We use the actual grade of each pass here and not the average after player has landed.
      for _, _grade in pairs( playerGrades ) do
        local grade = _grade -- #AIRBOSS.LSOgrade
        if grade.finalscore then
          text = text .. string.format( "%.1f|", grade.points )
        elseif grade.points >= 0 then -- Only points >=0 as foul deck gives -1.
          text = text .. string.format( "(%.1f)", grade.points )
        end
      end

      -- Display only the top ten.
      i = i + 1
      if i > 10 then
        break
      end
    end

    -- If no results yet.
    if i == 1 then
      text = text .. "\nNo results yet."
    end

    -- Send message.
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData
    if playerData.client then
      MESSAGE:New( text, 30, nil, true ):ToClient( playerData.client )
    end

  end
end

--- Display top 10 player scores.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayPlayerGrades( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Grades of player:
      local text = string.format( "Your last 10 grades, %s:", _playername )

      -- All player grades.
      local playerGrades = self.playerscores[_playername] or {}

      local p = 0 -- Average points.
      local n = 0 -- Number of final passes.
      local m = 0 -- Number of total passes.
      -- for i,_grade in pairs(playerGrades) do
      for i = #playerGrades, 1, -1 do
        -- local grade=_grade --#AIRBOSS.LSOgrade
        local grade = playerGrades[i] -- #AIRBOSS.LSOgrade

        -- Check if points >=0. For foul deck WO we give -1 and pass is not counted.
        if grade.points >= 0 then

          -- Show final points or points of pass.
          local points = grade.finalscore or grade.points

          -- Display max 10 results.
          if m < 10 then
            text = text .. string.format( "\n[%d] %s %.1f PT - %s", i, grade.grade, points, grade.details )

            -- Wire trapped if any.
            if grade.wire and grade.wire <= 4 then
              text = text .. string.format( " %d-wire", grade.wire )
            end

            -- Time in the groove if any.
            if grade.Tgroove and grade.Tgroove <= 360 then
              text = text .. string.format( " Tgroove=%.1f s", grade.Tgroove )
            end
          end

          -- Add up final points.
          if grade.finalscore then
            p = p + grade.finalscore
            n = n + 1
          end

          -- Total passes
          m = m + 1
        end
      end

      if n > 0 then
        text = text .. string.format( "\nAverage points = %.1f", p / n )
      else
        text = text .. string.format( "\nNo data available." )
      end

      -- Send message.
      if playerData.client then
        MESSAGE:New( text, 30, nil, true ):ToClient( playerData.client )
      end
    end
  end
end

--- Display last debriefing.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_DisplayDebriefing( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Debriefing text.
      local text = string.format( "Debriefing:" )

      -- Check if data is present.
      if #playerData.lastdebrief > 0 then
        text = text .. string.format( "\n================================\n" )
        for _, _data in pairs( playerData.lastdebrief ) do
          local step = _data.step
          local comment = _data.hint
          text = text .. string.format( "* %s:", step )
          text = text .. string.format( "%s\n", comment )
        end
      else
        text = text .. " Nothing to show yet."
      end

      -- Send debrief message to player
      self:MessageToPlayer( playerData, text, nil, "", 30, true )

    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KNEEBOARD MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Display marshal or pattern queue.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
-- @param #string qname Name of the queue.
function AIRBOSS:_DisplayQueue( _unitname, qname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Queue to display.
      local queue = nil
      if qname == "Marshal" then
        queue = self.Qmarshal
      elseif qname == "Pattern" then
        queue = self.Qpattern
      elseif qname == "Waiting" then
        queue = self.Qwaiting
      end

      -- Number of group and units in queue
      local Nqueue, nqueue = self:_GetQueueInfo( queue, playerData.case )

      local text = string.format( "%s Queue:", qname )
      if #queue == 0 then
        text = text .. " empty"
      else
        local N = 0
        if qname == "Marshal" then
          for i, _flight in pairs( queue ) do
            local flight = _flight -- #AIRBOSS.FlightGroup
            local charlie = self:_GetCharlieTime( flight )
            local Charlie = UTILS.SecondsToClock( charlie )
            local stack = flight.flag
            local angels = self:_GetAngels( self:_GetMarshalAltitude( stack, flight.case ) )
            local _, nunit, nsec = self:_GetFlightUnits( flight, true )
            local nick = self:_GetACNickname( flight.actype )
            N = N + nunit
            text = text .. string.format( "\n[Stack %d] %s (%s*%d+%d): Case %d, Angels %d, Charlie %s", stack, flight.onboard, nick, nunit, nsec, flight.case, angels, tostring( Charlie ) )
          end
        elseif qname == "Pattern" or qname == "Waiting" then
          for i, _flight in pairs( queue ) do
            local flight = _flight -- #AIRBOSS.FlightGroup
            local _, nunit, nsec = self:_GetFlightUnits( flight, true )
            local nick = self:_GetACNickname( flight.actype )
            local ptime = UTILS.SecondsToClock( timer.getAbsTime() - flight.time )
            N = N + nunit
            text = text .. string.format( "\n[%d] %s (%s*%d+%d): Case %d, T=%s", i, flight.onboard, nick, nunit, nsec, flight.case, ptime )
          end
        end
        text = text .. string.format( "\nTotal AC: %d (airborne %d)", N, nqueue )
      end

      -- Send message.
      self:MessageToPlayer( playerData, text, nil, "", nil, true )
    end
  end
end

--- Report information about carrier.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayCarrierInfo( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Current coordinates.
      local coord = self:GetCoordinate()

      -- Carrier speed and heading.
      local carrierheading = self.carrier:GetHeading()
      local carrierspeed = UTILS.MpsToKnots( self.carrier:GetVelocityMPS() )

      -- TACAN/ICLS.
      local tacan = "unknown"
      local icls = "unknown"
      if self.TACANon and self.TACANchannel ~= nil then
        tacan = string.format( "%d%s (%s)", self.TACANchannel, self.TACANmode, self.TACANmorse )
      end
      if self.ICLSon and self.ICLSchannel ~= nil then
        icls = string.format( "%d (%s)", self.ICLSchannel, self.ICLSmorse )
      end

      -- Wind on flight deck
      local wind = UTILS.MpsToKnots( select( 1, self:GetWindOnDeck() ) )

      -- Get groups, units in queues.
      local Nmarshal, nmarshal = self:_GetQueueInfo( self.Qmarshal, playerData.case )
      local Npattern, npattern = self:_GetQueueInfo( self.Qpattern )
      local Nspinning, nspinning = self:_GetQueueInfo( self.Qspinning )
      local Nwaiting, nwaiting = self:_GetQueueInfo( self.Qwaiting )
      local Ntotal, ntotal = self:_GetQueueInfo( self.flights )

      -- Current abs time.
      local Tabs = timer.getAbsTime()

      -- Get recovery times of carrier.
      local recoverytext = "Recovery time windows (max 5):"
      if #self.recoverytimes == 0 then
        recoverytext = recoverytext .. " none."
      else
        -- Loop over recovery windows.
        local rw = 0
        for _, _recovery in pairs( self.recoverytimes ) do
          local recovery = _recovery -- #AIRBOSS.Recovery
          -- Only include current and future recovery windows.
          if Tabs < recovery.STOP then
            -- Output text.
            recoverytext = recoverytext .. string.format( "\n* %s - %s: Case %d (%d°)", UTILS.SecondsToClock( recovery.START ), UTILS.SecondsToClock( recovery.STOP ), recovery.CASE, recovery.OFFSET )
            if recovery.WIND then
              recoverytext = recoverytext .. string.format( " @ %.1f kts wind", recovery.SPEED )
            end
            rw = rw + 1
            if rw >= 5 then
              -- Break the loop after 5 recovery times.
              break
            end
          end
        end
      end

      -- Recovery tanker TACAN text.
      local tankertext = nil
      if self.tanker then
        tankertext = string.format( "Recovery tanker frequency %.3f MHz\n", self.tanker.RadioFreq )
        if self.tanker.TACANon then
          tankertext = tankertext .. string.format( "Recovery tanker TACAN %d%s (%s)", self.tanker.TACANchannel, self.tanker.TACANmode, self.tanker.TACANmorse )
        else
          tankertext = tankertext .. "Recovery tanker TACAN n/a"
        end
      end

      -- Carrier FSM state. Idle is not clear enough.
      local state = self:GetState()
      if state == "Idle" then
        state = "Deck closed"
      end
      if self.turning then
        state = state .. " (turning currently)"
      end

      -- Message text.
      local text = string.format( "%s info:\n", self.alias )
      text = text .. string.format( "================================\n" )
      text = text .. string.format( "Carrier state: %s\n", state )
      if self.case == 1 then
        text = text .. string.format( "Case %d recovery ops\n", self.case )
      else
        local radial = self:GetRadial( self.case, true, true, false )
        text = text .. string.format( "Case %d recovery ops\nMarshal radial %03d°\n", self.case, radial )
      end
      text = text .. string.format( "BRC %03d° - FB %03d°\n", self:GetBRC(), self:GetFinalBearing( true ) )
      text = text .. string.format( "Speed %.1f kts - Wind on deck %.1f kts\n", carrierspeed, wind )
      text = text .. string.format( "Tower frequency %.3f MHz\n", self.TowerFreq )
      text = text .. string.format( "Marshal radio %.3f MHz\n", self.MarshalFreq )
      text = text .. string.format( "LSO radio %.3f MHz\n", self.LSOFreq )
      text = text .. string.format( "TACAN Channel %s\n", tacan )
      text = text .. string.format( "ICLS Channel %s\n", icls )
      if tankertext then
        text = text .. tankertext .. "\n"
      end
      text = text .. string.format( "# A/C total %d (%d)\n", Ntotal, ntotal )
      text = text .. string.format( "# A/C marshal %d (%d)\n", Nmarshal, nmarshal )
      text = text .. string.format( "# A/C pattern %d (%d) - spinning %d (%d)\n", Npattern, npattern, Nspinning, nspinning )
      text = text .. string.format( "# A/C waiting %d (%d)\n", Nwaiting, nwaiting )
      text = text .. string.format( recoverytext )
      self:T2( self.lid .. text )

      -- Send message.
      self:MessageToPlayer( playerData, text, nil, "", 30, true )

    else
      self:E( self.lid .. string.format( "ERROR: Could not get player data for player %s.", playername ) )
    end
  end

end

--- Report weather conditions at the carrier location. Temperature, QFE pressure and wind data.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayCarrierWeather( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Message text.
    local text = ""

    -- Current coordinates.
    local coord = self:GetCoordinate()

    -- Get atmospheric data at carrier location.
    local T = coord:GetTemperature()
    local P = coord:GetPressure()

    -- Get wind direction (magnetic) and strength.
    local Wd, Ws = self:GetWind( nil, true )

    -- Get Beaufort wind scale.
    local Bn, Bd = UTILS.BeaufortScale( Ws )

    -- Wind on flight deck.
    local WodPA, WodPP = self:GetWindOnDeck()
    local WodPA = UTILS.MpsToKnots( WodPA )
    local WodPP = UTILS.MpsToKnots( WodPP )

    local WD = string.format( '%03d°', Wd )
    local Ts = string.format( "%d°C", T )

    local tT = string.format( "%d°C", T )
    local tW = string.format( "%.1f knots", UTILS.MpsToKnots( Ws ) )
    local tP = string.format( "%.2f inHg", UTILS.hPa2inHg( P ) )

    -- Report text.
    text = text .. string.format( "Weather Report at Carrier %s:\n", self.alias )
    text = text .. string.format( "================================\n" )
    text = text .. string.format( "Temperature %s\n", tT )
    text = text .. string.format( "Wind from %s at %s (%s)\n", WD, tW, Bd )
    text = text .. string.format( "Wind on deck || %.1f kts, == %.1f kts\n", WodPA, WodPP )
    text = text .. string.format( "QFE %.1f hPa = %s", P, tP )

    -- More info only reliable if Mission uses static weather.
    if self.staticweather then
      local clouds, visibility, fog, dust = self:_GetStaticWeather()
      text = text .. string.format( "\nVisibility %.1f NM", UTILS.MetersToNM( visibility ) )
      text = text .. string.format( "\nCloud base %d ft", UTILS.MetersToFeet( clouds.base ) )
      text = text .. string.format( "\nCloud thickness %d ft", UTILS.MetersToFeet( clouds.thickness ) )
      text = text .. string.format( "\nCloud density %d", clouds.density )
      text = text .. string.format( "\nPrecipitation %d", clouds.iprecptns )
      if fog then
        text = text .. string.format( "\nFog thickness %d ft", UTILS.MetersToFeet( fog.thickness ) )
        text = text .. string.format( "\nFog visibility %d ft", UTILS.MetersToFeet( fog.visibility ) )
      else
        text = text .. string.format( "\nNo fog" )
      end
      if dust then
        text = text .. string.format( "\nDust density %d", dust )
      else
        text = text .. string.format( "\nNo dust" )
      end
    end

    -- Debug output.
    self:T2( self.lid .. text )

    -- Send message to player group.
    self:MessageToPlayer( self.players[playername], text, nil, "", 30, true )

  else
    self:E( self.lid .. string.format( "ERROR! Could not find player unit in CarrierWeather! Unit name = %s", _unitname ) )
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HELP MENU
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set difficulty level.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
-- @param #AIRBOSS.Difficulty difficulty Difficulty level.
function AIRBOSS:_SetDifficulty( _unitname, difficulty )
  self:T2( { difficulty = difficulty, unitname = _unitname } )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then
      playerData.difficulty = difficulty
      local text = string.format( "roger, your skill level is now: %s.", difficulty )
      self:MessageToPlayer( playerData, text, nil, playerData.name, 5 )
    else
      self:E( self.lid .. string.format( "ERROR: Could not get player data for player %s.", playername ) )
    end

    -- Set hints as well.
    if playerData.difficulty == AIRBOSS.Difficulty.HARD then
      playerData.showhints = false
    else
      playerData.showhints = true
    end

  end
end

--- Turn player's aircraft attitude display on or off.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_SetHintsOnOff( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Invert hints.
      playerData.showhints = not playerData.showhints

      -- Inform player.
      local text = ""
      if playerData.showhints == true then
        text = string.format( "roger, hints are now ON." )
      else
        text = string.format( "affirm, hints are now OFF." )
      end
      self:MessageToPlayer( playerData, text, nil, playerData.name, 5 )

    end
  end
end

--- Turn player's aircraft attitude display on or off.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_DisplayAttitude( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then
      playerData.attitudemonitor = not playerData.attitudemonitor
    end
  end

end

--- Turn radio subtitles of player on or off.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_SubtitlesOnOff( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then
      playerData.subtitles = not playerData.subtitles
      -- Inform player.
      local text = ""
      if playerData.subtitles == true then
        text = string.format( "roger, subtitiles are now ON." )
      elseif playerData.subtitles == false then
        text = string.format( "affirm, subtitiles are now OFF." )
      end
      self:MessageToPlayer( playerData, text, nil, playerData.name, 5 )
    end
  end

end

--- Turn radio subtitles of player on or off.
-- @param #AIRBOSS self
-- @param #string _unitname Name of the player unit.
function AIRBOSS:_TrapsheetOnOff( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.players[playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Check if option is enabled at all.
      local text = ""
      if self.trapsheet then

        -- Invert current setting.
        playerData.trapon = not playerData.trapon

        -- Inform player.
        if playerData.trapon == true then
          text = string.format( "roger, your trapsheets are now SAVED." )
        else
          text = string.format( "affirm, your trapsheets are NOT SAVED." )
        end

      else
        text = "negative, trap sheet data recorder is broken on this carrier."
      end

      -- Message to player.
      self:MessageToPlayer( playerData, text, nil, playerData.name, 5 )
    end
  end

end

--- Display player status.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
function AIRBOSS:_DisplayPlayerStatus( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Pattern step text.
      local steptext = playerData.step
      if playerData.step == AIRBOSS.PatternStep.HOLDING then
        if playerData.holding == nil then
          steptext = "Transit to Marshal"
        elseif playerData.holding == false then
          steptext = "Marshal (outside zone)"
        elseif playerData.holding == true then
          steptext = "Marshal Stack Holding"
        end
      end

      -- Stack.
      local stack = playerData.flag

      -- Stack text.
      local stacktext = nil
      if stack > 0 then
        local stackalt = self:_GetMarshalAltitude( stack )
        local angels = self:_GetAngels( stackalt )
        stacktext = string.format( "Marshal Stack %d, Angels %d\n", stack, angels )

        -- Hint about TACAN bearing.
        if playerData.step == AIRBOSS.PatternStep.HOLDING and playerData.case > 1 then
          -- Get inverse magnetic radial potential offset.
          local radial = self:GetRadial( playerData.case, true, true, true )
          stacktext = stacktext .. string.format( "Select TACAN %03d°, %d DME\n", radial, angels + 15 )
        end
      end

      -- Fuel and fuel state.
      local fuel = playerData.unit:GetFuel() * 100
      local fuelstate = self:_GetFuelState( playerData.unit )

      -- Number of units in group.
      local _, nunitsGround = self:_GetFlightUnits( playerData, true )
      local _, nunitsAirborne = self:_GetFlightUnits( playerData, false )

      -- Player data.
      local text = string.format( "Status of player %s (%s)\n", playerData.name, playerData.callsign )
      text = text .. string.format( "================================\n" )
      text = text .. string.format( "Step: %s\n", steptext )
      if stacktext then
        text = text .. stacktext
      end
      text = text .. string.format( "Recovery Case: %d\n", playerData.case )
      text = text .. string.format( "Skill Level: %s\n", playerData.difficulty )
      text = text .. string.format( "Modex: %s (%s)\n", playerData.onboard, self:_GetACNickname( playerData.actype ) )
      text = text .. string.format( "Fuel State: %.1f lbs/1000 (%.1f %%)\n", fuelstate / 1000, fuel )
      text = text .. string.format( "# units: %d (%d airborne)\n", nunitsGround, nunitsAirborne )
      text = text .. string.format( "Section Lead: %s (%d/%d)", tostring( playerData.seclead ), #playerData.section + 1, self.NmaxSection + 1 )
      for _, _sec in pairs( playerData.section ) do
        local sec = _sec -- #AIRBOSS.PlayerData
        text = text .. string.format( "\n- %s", sec.name )
      end

      if playerData.step == AIRBOSS.PatternStep.INITIAL then

        -- Create a point 3.0 NM astern for re-entry.
        local zoneinitial = self:GetCoordinate():Translate( UTILS.NMToMeters( 3.5 ), self:GetRadial( 2, false, false, false ) )

        -- Heading and distance to initial zone.
        local flyhdg = playerData.unit:GetCoordinate():HeadingTo( zoneinitial )
        local flydist = UTILS.MetersToNM( playerData.unit:GetCoordinate():Get2DDistance( zoneinitial ) )
        local brc = self:GetBRC()

        -- Help player to find its way to the initial zone.
        text = text .. string.format( "\nTo Initial: Fly heading %03d° for %.1f NM and turn to BRC %03d°", flyhdg, flydist, brc )

      elseif playerData.step == AIRBOSS.PatternStep.PLATFORM then

        -- Coordinate of the platform zone.
        local zoneplatform = self:_GetZonePlatform( playerData.case ):GetCoordinate()

        -- Heading and distance to platform zone.
        local flyhdg = playerData.unit:GetCoordinate():HeadingTo( zoneplatform )
        local flydist = UTILS.MetersToNM( playerData.unit:GetCoordinate():Get2DDistance( zoneplatform ) )

        -- Get heading.
        local hdg = self:GetRadial( playerData.case, true, true, true )

        -- Help player to find its way to the initial zone.
        text = text .. string.format( "\nTo Platform: Fly heading %03d° for %.1f NM and turn to %03d°", flyhdg, flydist, hdg )

      end

      -- Send message.
      self:MessageToPlayer( playerData, text, nil, "", 30, true )
    else
      self:E( self.lid .. string.format( "ERROR: playerData=nil. Unit name=%s, player name=%s", _unitName, _playername ) )
    end
  else
    self:E( self.lid .. string.format( "ERROR: could not find player for unit %s", _unitName ) )
  end

end

--- Mark current marshal zone of player by either smoke or flares.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
-- @param #boolean flare If true, flare the zone. If false, smoke the zone.
function AIRBOSS:_MarkMarshalZone( _unitName, flare )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Get player stack and recovery case.
      local stack = playerData.flag
      local case = playerData.case

      local text = ""
      if stack > 0 then

        -- Get current holding zone.
        local zoneHolding = self:_GetZoneHolding( case, stack )

        -- Get Case I commence zone at three position.
        local zoneThree = self:_GetZoneCommence( case, stack )

        -- Pattern altitude.
        local patternalt = self:_GetMarshalAltitude( stack, case )

        -- Flare and smoke at the ground.
        patternalt = 5

        -- Roger!
        text = "roger, marking"
        if flare then

          -- Marshal WHITE flares.
          text = text .. string.format( "\n* Marshal zone stack %d with WHITE flares.", stack )
          zoneHolding:FlareZone( FLARECOLOR.White, 45, nil, patternalt )

          -- Commence RED flares.
          text = text .. "\n* Commence zone with RED flares."
          zoneThree:FlareZone( FLARECOLOR.Red, 45, nil, patternalt )

        else

          -- Marshal WHITE smoke.
          text = text .. string.format( "\n* Marshal zone stack %d with WHITE smoke.", stack )
          zoneHolding:SmokeZone( SMOKECOLOR.White, 45, patternalt )

          -- Commence RED smoke
          text = text .. "\n* Commence zone with RED smoke."
          zoneThree:SmokeZone( SMOKECOLOR.Red, 45, patternalt )

        end

      else
        text = "negative, you are currently not in a Marshal stack. No zones will be marked!"
      end

      -- Send message to player.
      self:MessageToPlayer( playerData, text, "MARSHAL", playerData.name )
    end
  end

end

--- Mark CASE I or II/II zones by either smoke or flares.
-- @param #AIRBOSS self
-- @param #string _unitName Name of the player unit.
-- @param #boolean flare If true, flare the zone. If false, smoke the zone.
function AIRBOSS:_MarkCaseZones( _unitName, flare )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData

    if playerData then

      -- Player's recovery case.
      local case = playerData.case

      -- Initial
      local text = string.format( "affirm, marking CASE %d zones", case )

      -- Flare or smoke?
      if flare then

        -----------
        -- Flare --
        -----------

        -- Case I/II: Initial
        if case == 1 or case == 2 then
          text = text .. "\n* initial with GREEN flares"
          self:_GetZoneInitial( case ):FlareZone( FLARECOLOR.Green, 45 )
        end

        -- Case II/III: approach corridor
        if case == 2 or case == 3 then
          text = text .. "\n* approach corridor with GREEN flares"
          self:_GetZoneCorridor( case ):FlareZone( FLARECOLOR.Green, 45 )
        end

        -- Case II/III: platform
        if case == 2 or case == 3 then
          text = text .. "\n* platform with RED flares"
          self:_GetZonePlatform( case ):FlareZone( FLARECOLOR.Red, 45 )
        end

        -- Case III: dirty up
        if case == 3 then
          text = text .. "\n* dirty up with YELLOW flares"
          self:_GetZoneDirtyUp( case ):FlareZone( FLARECOLOR.Yellow, 45 )
        end

        -- Case II/III: arc in/out
        if case == 2 or case == 3 then
          if math.abs( self.holdingoffset ) > 0 then
            self:_GetZoneArcIn( case ):FlareZone( FLARECOLOR.White, 45 )
            text = text .. "\n* arc turn in with WHITE flares"
            self:_GetZoneArcOut( case ):FlareZone( FLARECOLOR.White, 45 )
            text = text .. "\n* arc trun out with WHITE flares"
          end
        end

        -- Case III: bullseye
        if case == 3 then
          text = text .. "\n* bullseye with GREEN flares"
          self:_GetZoneBullseye( case ):FlareZone( FLARECOLOR.Green, 45 )
        end

        -- Tarawa, LHA and LHD landing spots.
        if self.carriertype == AIRBOSS.CarrierType.INVINCIBLE or self.carriertype == AIRBOSS.CarrierType.HERMES or self.carriertype == AIRBOSS.CarrierType.TARAWA or self.carriertype == AIRBOSS.CarrierType.AMERICA or self.carriertype == AIRBOSS.CarrierType.JCARLOS or self.carriertype == AIRBOSS.CarrierType.CANBERRA then
          text = text .. "\n* abeam landing stop with RED flares"
          -- Abeam landing spot zone.
          local ALSPT = self:_GetZoneAbeamLandingSpot()
          ALSPT:FlareZone( FLARECOLOR.Red, 5, nil, UTILS.FeetToMeters( 110 ) )
          -- Primary landing spot zone.
          text = text .. "\n* primary landing spot with GREEN flares"
          local LSPT = self:_GetZoneLandingSpot()
          LSPT:FlareZone( FLARECOLOR.Green, 5, nil, self.carrierparam.deckheight )
        end

      else

        -----------
        -- Smoke --
        -----------

        -- Case I/II: Initial
        if case == 1 or case == 2 then
          text = text .. "\n* initial with GREEN smoke"
          self:_GetZoneInitial( case ):SmokeZone( SMOKECOLOR.Green, 45 )
        end

        -- Case II/III: Approach Corridor
        if case == 2 or case == 3 then
          text = text .. "\n* approach corridor with GREEN smoke"
          self:_GetZoneCorridor( case ):SmokeZone( SMOKECOLOR.Green, 45 )
        end

        -- Case II/III: platform
        if case == 2 or case == 3 then
          text = text .. "\n* platform with RED smoke"
          self:_GetZonePlatform( case ):SmokeZone( SMOKECOLOR.Red, 45 )
        end

        -- Case II/III: arc in/out if offset>0.
        if case == 2 or case == 3 then
          if math.abs( self.holdingoffset ) > 0 then
            self:_GetZoneArcIn( case ):SmokeZone( SMOKECOLOR.Blue, 45 )
            text = text .. "\n* arc turn in with BLUE smoke"
            self:_GetZoneArcOut( case ):SmokeZone( SMOKECOLOR.Blue, 45 )
            text = text .. "\n* arc trun out with BLUE smoke"
          end
        end

        -- Case III: dirty up
        if case == 3 then
          text = text .. "\n* dirty up with ORANGE smoke"
          self:_GetZoneDirtyUp( case ):SmokeZone( SMOKECOLOR.Orange, 45 )
        end

        -- Case III: bullseye
        if case == 3 then
          text = text .. "\n* bullseye with GREEN smoke"
          self:_GetZoneBullseye( case ):SmokeZone( SMOKECOLOR.Green, 45 )
        end

      end

      -- Send message to player.
      self:MessageToPlayer( playerData, text, "MARSHAL", playerData.name )
    end
  end

end

--- LSO radio check. Will broadcase LSO message at given LSO frequency.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_LSORadioCheck( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData
    if playerData then
      -- Broadcase LSO radio check message on LSO radio.
      self:RadioTransmission( self.LSORadio, self.LSOCall.RADIOCHECK, nil, nil, nil, true )
    end
  end
end

--- Marshal radio check. Will broadcase Marshal message at given Marshal frequency.
-- @param #AIRBOSS self
-- @param #string _unitName Name fo the player unit.
function AIRBOSS:_MarshalRadioCheck( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then
    local playerData = self.players[_playername] -- #AIRBOSS.PlayerData
    if playerData then
      -- Broadcase Marshal radio check message on Marshal radio.
      self:RadioTransmission( self.MarshalRadio, self.MarshalCall.RADIOCHECK, nil, nil, nil, true )
    end
  end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Persistence Functions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Save trapsheet data.
-- @param #AIRBOSS self
-- @param #AIRBOSS.PlayerData playerData Player data table.
-- @param #AIRBOSS.LSOgrade grade LSO grad data.
function AIRBOSS:_SaveTrapSheet( playerData, grade )

  -- Nothing to save.
  if playerData.trapsheet == nil or #playerData.trapsheet == 0 or not io then
    return
  end

  --- Function that saves data to file
  local function _savefile( filename, data )
    local f = io.open( filename, "wb" )
    if f then
      f:write( data )
      f:close()
    else
      self:E( self.lid .. string.format( "ERROR: could not save trap sheet to file %s.\nFile may contain invalid characters.", tostring( filename ) ) )
    end
  end

  -- Set path or default.
  local path = self.trappath
  if lfs then
    path = path or lfs.writedir()
  end

  -- Create unused file name.
  local filename = nil
  for i = 1, 9999 do

    -- Create file name
    if self.trapprefix then
      filename = string.format( "%s_%s-%04d.csv", self.trapprefix, playerData.actype, i )
    else
      local name = UTILS.ReplaceIllegalCharacters( playerData.name, "_" )
      filename = string.format( "AIRBOSS-%s_Trapsheet-%s_%s-%04d.csv", self.alias, name, playerData.actype, i )
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

  -- Info
  local text = string.format( "Saving player %s trapsheet to file %s", playerData.name, filename )
  self:I( self.lid .. text )

  -- Header line
  local data = "#Time,Rho,X,Z,Alt,AoA,GSE,LUE,Vtot,Vy,Gamma,Pitch,Roll,Yaw,Step,Grade,Points,Details\n"

  local g0 = playerData.trapsheet[1] -- #AIRBOSS.GrooveData
  local T0 = g0.Time

  -- for _,_groove in ipairs(playerData.trapsheet) do
  for i = 1, #playerData.trapsheet do
    -- local groove=_groove --#AIRBOSS.GrooveData
    local groove = playerData.trapsheet[i]
    local t = groove.Time - T0
    local a = UTILS.MetersToNM( groove.Rho or 0 )
    local b = -groove.X or 0
    local c = groove.Z or 0
    local d = UTILS.MetersToFeet( groove.Alt or 0 )
    local e = groove.AoA or 0
    local f = groove.GSE or 0
    local g = -groove.LUE or 0
    local h = UTILS.MpsToKnots( groove.Vel or 0 )
    local i = (groove.Vy or 0) * 196.85
    local j = groove.Gamma or 0
    local k = groove.Pitch or 0
    local l = groove.Roll or 0
    local m = groove.Yaw or 0
    local n = self:_GS( groove.Step, -1 ) or "n/a"
    local o = groove.Grade or "n/a"
    local p = groove.GradePoints or 0
    local q = groove.GradeDetail or "n/a"
    --                              t    a    b    c    d    e    f    g    h    i    j    k    l    m   n  o   p   q
    data = data .. string.format( "%.2f,%.3f,%.1f,%.1f,%.1f,%.2f,%.2f,%.2f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%s,%s,%.1f,%s\n", t, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q )
  end

  -- Save file.
  _savefile( filename, data )
end

--- On before "Save" event. Checks if io and lfs are available.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
-- @param #string filename (Optional) File name for saving the player grades. Default is "AIRBOSS-<ALIAS>_LSOgrades.csv".
function AIRBOSS:onbeforeSave( From, Event, To, path, filename )

  -- Check io module is available.
  if not io then
    self:E( self.lid .. "ERROR: io not desanitized. Can't save player grades." )
    return false
  end

  -- Check default path.
  if path == nil and not lfs then
    self:E( self.lid .. "WARNING: lfs not desanitized. Results will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder." )
  end

  return true
end

--- On after "Save" event. Player data is saved to file.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is saved. If nil, file is saved in the DCS root installtion directory or your "Saved Games" folder if lfs was desanitized.
-- @param #string filename (Optional) File name for saving the player grades. Default is "AIRBOSS-<ALIAS>_LSOgrades.csv".
function AIRBOSS:onafterSave( From, Event, To, path, filename )

  --- Function that saves data to file
  local function _savefile( filename, data )
    local f = assert( io.open( filename, "wb" ) )
    f:write( data )
    f:close()
  end

  -- Set path or default.
  if lfs then
    path = path or lfs.writedir()
  end

  -- Set file name.
  filename = filename or string.format( "AIRBOSS-%s_LSOgrades.csv", self.alias )

  -- Set path.
  if path ~= nil then
    filename = path .. "\\" .. filename
  end

  -- Header line
  local scores = "Name,Pass,Points Final,Points Pass,Grade,Details,Wire,Tgroove,Case,Wind,Modex,Airframe,Carrier Type,Carrier Name,Theatre,Mission Time,Mission Date,OS Date\n"

  -- Loop over all players.
  local n = 0
  for playername, grades in pairs( self.playerscores ) do

    -- Loop over player grades table.
    for i, _grade in pairs( grades ) do
      local grade = _grade -- #AIRBOSS.LSOgrade

      -- Check some stuff that could be nil.
      local wire = "n/a"
      if grade.wire and grade.wire <= 4 then
        wire = tostring( grade.wire )
      end

      local Tgroove = "n/a"
      if grade.Tgroove and grade.Tgroove <= 360 and grade.case < 3 then
        Tgroove = tostring( UTILS.Round( grade.Tgroove, 1 ) )
      end

      local finalscore = "n/a"
      if grade.finalscore then
        finalscore = tostring( UTILS.Round( grade.finalscore, 1 ) )
      end

      -- Compile grade line.
      scores = scores .. string.format( "%s,%d,%s,%.1f,%s,%s,%s,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", playername, i, finalscore, grade.points, grade.grade, grade.details, wire, Tgroove, grade.case, grade.wind, grade.modex, grade.airframe, grade.carriertype, grade.carriername, grade.theatre, grade.mitime, grade.midate, grade.osdate )
      n = n + 1
    end
  end

  -- Info
  local text = string.format( "Saving %d player LSO grades to file %s", n, filename )
  self:I( self.lid .. text )

  -- Save file.
  _savefile( filename, scores )
end

--- On before "Load" event. Checks if the file that the player grades from exists.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path (Optional) Path where the file is loaded from. Default is the DCS installation root directory or your "Saved Games\\DCS" folder if lfs was desanizized.
-- @param #string filename (Optional) File name for saving the player grades. Default is "AIRBOSS-<ALIAS>_LSOgrades.csv".
function AIRBOSS:onbeforeLoad( From, Event, To, path, filename )

  --- Function that check if a file exists.
  local function _fileexists( name )
    local f = io.open( name, "r" )
    if f ~= nil then
      io.close( f )
      return true
    else
      return false
    end
  end

  -- Check io module is available.
  if not io then
    self:E( self.lid .. "WARNING: io not desanitized. Can't load player grades." )
    return false
  end

  -- Check default path.
  if path == nil and not lfs then
    self:E( self.lid .. "WARNING: lfs not desanitized. Results will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder." )
  end

  -- Set path or default.
  if lfs then
    path = path or lfs.writedir()
  end

  -- Set file name.
  filename = filename or string.format( "AIRBOSS-%s_LSOgrades.csv", self.alias )

  -- Set path.
  if path ~= nil then
    filename = path .. "\\" .. filename
  end

  -- Check if file exists.
  local exists = _fileexists( filename )

  if exists then
    return true
  else
    self:E( self.lid .. string.format( "WARNING: Player LSO grades file %s does not exist.", filename ) )
    return false
  end

end

--- On after "Load" event. Loads grades of all players from file.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is loaded from. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if lfs was desanizied.
-- @param #string filename (Optional) File name for saving the player grades. Default is "AIRBOSS-<ALIAS>_LSOgrades.csv".
function AIRBOSS:onafterLoad( From, Event, To, path, filename )

  --- Function that load data from a file.
  local function _loadfile( filename )
    local f = assert( io.open( filename, "rb" ) )
    local data = f:read( "*all" )
    f:close()
    return data
  end

  -- Set path or default.
  if lfs then
    path = path or lfs.writedir()
  end

  -- Set file name.
  filename = filename or string.format( "AIRBOSS-%s_LSOgrades.csv", self.alias )

  -- Set path.
  if path ~= nil then
    filename = path .. "\\" .. filename
  end

  -- Info message.
  local text = string.format( "Loading player LSO grades from file %s", filename )
  MESSAGE:New( text, 10 ):ToAllIf( self.Debug )
  self:I( self.lid .. text )

  -- Load asset data from file.
  local data = _loadfile( filename )

  -- Split by line break.
  local playergrades = UTILS.Split( data, "\n" )

  -- Remove first header line.
  table.remove( playergrades, 1 )

  -- Init player scores table.
  self.playerscores = {}

  -- Loop over all lines.
  local n = 0
  for _, gradeline in pairs( playergrades ) do

    -- Parameters are separated by commata.
    local gradedata = UTILS.Split( gradeline, "," )

    -- Debug info.
    self:T2( gradedata )

    -- Grade table
    local grade = {} -- #AIRBOSS.LSOgrade

    --- Line format:
    -- playername, i, grade.finalscore, grade.points, grade.grade, grade.details, wire, Tgroove, case,
    -- time, wind, airframe, modex, carriertype, carriername, theatre, date
    local playername = gradedata[1]
    if gradedata[3] ~= nil and gradedata[3] ~= "n/a" then
      grade.finalscore = tonumber( gradedata[3] )
    end
    grade.points = tonumber( gradedata[4] )
    grade.grade = tostring( gradedata[5] )
    grade.details = tostring( gradedata[6] )
    if gradedata[7] ~= nil and gradedata[7] ~= "n/a" then
      grade.wire = tonumber( gradedata[7] )
    end
    if gradedata[8] ~= nil and gradedata[8] ~= "n/a" then
      grade.Tgroove = tonumber( gradedata[8] )
    end
    grade.case = tonumber( gradedata[9] )
    -- new
    grade.wind = gradedata[10] or "n/a"
    grade.modex = gradedata[11] or "n/a"
    grade.airframe = gradedata[12] or "n/a"
    grade.carriertype = gradedata[13] or "n/a"
    grade.carriername = gradedata[14] or "n/a"
    grade.theatre = gradedata[15] or "n/a"
    grade.mitime = gradedata[16] or "n/a"
    grade.midate = gradedata[17] or "n/a"
    grade.osdate = gradedata[18] or "n/a"

    -- Init player table if necessary.
    self.playerscores[playername] = self.playerscores[playername] or {}

    -- Add grade to table.
    table.insert( self.playerscores[playername], grade )

    n = n + 1

    -- Debug info.
    self:T2( { playername, self.playerscores[playername] } )
  end

  -- Info message.
  local text = string.format( "Loaded %d player LSO grades from file %s", n, filename )
  self:I( self.lid .. text )

end

--- On after "LSOGrade" event.
-- @param #AIRBOSS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRBOSS.PlayerData playerData Player Data.
-- @param #AIRBOSS.LSOgrade grade LSO grade.
function AIRBOSS:onafterLSOGrade(From, Event, To, playerData, grade)

  if self.funkmanSocket then

    -- Extract used info for FunkMan. We need to be careful with the amount of data send via UDP socket.
    local trapsheet={} ; trapsheet.X={} ; trapsheet.Z={} ; trapsheet.AoA={} ; trapsheet.Alt={}

    -- Loop over trapsheet and extract used values.
    for i = 1, #playerData.trapsheet do
      local ts=playerData.trapsheet[i] --#AIRBOSS.GrooveData
      table.insert(trapsheet.X, UTILS.Round(ts.X, 1))
      table.insert(trapsheet.Z, UTILS.Round(ts.Z, 1))
      table.insert(trapsheet.AoA, UTILS.Round(ts.AoA, 2))
      table.insert(trapsheet.Alt, UTILS.Round(ts.Alt, 1))
    end

    local result={}
    result.command=SOCKET.DataType.LSOGRADE
    result.name=playerData.name
    result.trapsheet=trapsheet
    result.airframe=grade.airframe
    result.mitime=grade.mitime
    result.midate=grade.midate
    result.wind=grade.wind
    result.carriertype=grade.carriertype
    result.carriername=grade.carriername
    result.carrierrwy=grade.carrierrwy
    result.landingdist=self.carrierparam.landingdist
    result.theatre=grade.theatre
    result.case=playerData.case
    result.Tgroove=grade.Tgroove
    result.wire=grade.wire
    result.grade=grade.grade
    result.points=grade.points
    result.details=grade.details

    -- Debug info.
    self:T(self.lid.."Result onafterLSOGrade")
    self:T(result)

    -- Send result.
    self.funkmanSocket:SendTable(result)
  end

end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
