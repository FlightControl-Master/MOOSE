--- **Ops** - MOOSE AI AWACS Operations using text-to-speech.
-- 
-- ===
-- 
-- **AWACS** - MOOSE AI AWACS Operations using text-to-speech.
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Awacs/).
--
-- ## Videos:
-- 
-- Demo videos can be found on [Youtube](https://www.youtube.com/watch?v=ocdy8QzTNN4&list=PLFxp425SeXnq-oS0DSjam1HtddywH8i_k)
--    
-- ===
--
-- ### Author: **applevangelist**
-- @date Last Update July 2025
-- @module Ops.AWACS
-- @image OPS_AWACS.jpg

do
--- Ops AWACS Class
-- @type AWACS
-- @field #string ClassName Name of this class.
-- @field #string version Versioning.
-- @field #string lid LID for log entries.
-- @field #number coalition Coalition side.
-- @field #string coalitiontxt e.g."blue"
-- @field Core.Zone#ZONE OpsZone,
-- @field Core.Zone#ZONE StationZone,
-- @field Core.Zone#ZONE BorderZone,
-- @field Core.Zone#ZONE RejectZone,
-- @field #number Frequency
-- @field #number Modulation
-- @field Wrapper.Airbase#AIRBASE Airbase
-- @field Ops.Airwing#AIRWING AirWing
-- @field #number AwacsAngels
-- @field Core.Zone#ZONE OrbitZone
-- @field #number CallSign
-- @field #number CallSignNo
-- @field #boolean debug
-- @field #number verbose
-- @field #table ManagedGrps
-- @field #number ManagedGrpID
-- @field #number ManagedTaskID
-- @field Utilities.FiFo#FIFO AnchorStacks
-- @field Utilities.FiFo#FIFO CAPIdleAI
-- @field Utilities.FiFo#FIFO CAPIdleHuman
-- @field Utilities.FiFo#FIFO TaskedCAPAI
-- @field Utilities.FiFo#FIFO TaskedCAPHuman
-- @field Utilities.FiFo#FIFO OpenTasks
-- @field Utilities.FiFo#FIFO ManagedTasks
-- @field Utilities.FiFo#FIFO PictureAO
-- @field Utilities.FiFo#FIFO PictureEWR
-- @field Utilities.FiFo#FIFO Contacts
-- @field #table CatchAllMissions
-- @field #table CatchAllFGs
-- @field #number Countactcounter
-- @field Utilities.FiFo#FIFO ContactsAO
-- @field Utilities.FiFo#FIFO RadioQueue
-- @field Utilities.FiFo#FIFO PrioRadioQueue
-- @field Utilities.FiFo#FIFO CAPAirwings
-- @field Utilities.FiFo#FIFO TacticalQueue
-- @field #number AwacsTimeOnStation
-- @field #number AwacsTimeStamp
-- @field #number EscortsTimeOnStation
-- @field #number EscortsTimeStamp
-- @field #string AwacsROE
-- @field #string AwacsROT
-- @field Ops.Auftrag#AUFTRAG AwacsMission
-- @field Ops.Auftrag#AUFTRAG EscortMission
-- @field Ops.Auftrag#AUFTRAG AwacsMissionReplacement
-- @field Ops.Auftrag#AUFTRAG EscortMissionReplacement
-- @field Utilities.FiFo#FIFO AICAPMissions FIFO for Ops.Auftrag#AUFTRAG for AI CAP
-- @field #boolean MenuStrict
-- @field #number MaxAIonCAP
-- @field #number AIonCAP
-- @field #boolean ShiftChangeAwacsFlag
-- @field #boolean ShiftChangeEscortsFlag
-- @field #boolean ShiftChangeAwacsRequested
-- @field #boolean ShiftChangeEscortsRequested
-- @field #AWACS.MonitoringData MonitoringData
-- @field #boolean MonitoringOn
-- @field Core.Set#SET_CLIENT clientset
-- @field Utilities.FiFo#FIFO FlightGroups
-- @field #number PictureInterval Interval in seconds for general picture
-- @field #number PictureTimeStamp Interval timestamp
-- @field #number maxassigndistance Only assing AI/Pilots to targets max this far away
-- @field #boolean PlayerGuidance if true additional callouts to guide/warn players
-- @field #boolean ModernEra if true we get more intel on targets, and EPLR on the AIC
-- @field #boolean callsignshort if true use short (group) callsigns, e.g. "Ghost 1", else "Ghost 1 1"
-- @field #boolean keepnumber if true, use the full string after # for a player custom callsign
-- @field #table callsignTranslations optional translations for callsigns
-- @field #number MeldDistance 25nm - distance for "Meld" Call , usually shortly before the actual engagement 
-- @field #number TacDistance 30nm - distance for "TAC" Call
-- @field #number ThreatDistance 15nm - distance to declare untargeted (new) threats
-- @field #string AOName name of the FEZ, e.g. Rock
-- @field Core.Point#COORDINATE AOCoordinate Coordinate of bulls eye
-- @field Utilities.FiFo#FIFO clientmenus
-- @field #number RadarBlur Radar blur in %
-- @field #number ReassignmentPause Wait this many seconds before re-assignment of a player
-- @field #boolean NoGroupTags Set to true if you don't want group tags.
-- @field #boolean SuppressScreenOutput Set to true to suppress all screen output.
-- @field #boolean NoMissileCalls Suppress missile callouts
-- @field #boolean PlayerCapAssignment Assign players to CAP tasks when they are logged on
-- @field #number GoogleTTSPadding
-- @field #number WindowsTTSPadding
-- @field #boolean AllowMarkers
-- @field #string PlayerStationName
-- @field #boolean GCI Act as GCI
-- @field Wrapper.Group#GROUP GCIGroup EWR group object for GCI ops
-- @field #string locale Localization
-- @field #boolean IncludeHelicopters
-- @field #boolean TacticalMenu
-- @field #table TacticalFrequencies
-- @field #table TacticalSubscribers
-- @field #number TacticalBaseFreq
-- @field #number TacticalIncrFreq
-- @field #number TacticalModulation
-- @field #number TacticalInterval
-- @field Core.Set#SET_GROUP DetectionSet
-- @field #number MaxMissionRange
-- @extends Core.Fsm#FSM


---
--
-- *Of all men\'s miseries the bitterest is this: to know so much and to have control over nothing.* (Herodotus)
--
-- ===
-- 
-- # AWACS AI Air Controller
-- 
--  * WIP (beta)
--  * AWACS replacement for the in-game AWACS
--  * Will control a fighter engagement zone and assign tasks to AI and human CAP flights
--  * Callouts referenced from:   
--  ** References from ARN33396 ATP 3-52.4 (Sep 2021) (Combined Forces)   
--  ** References from CNATRA P-877 (Rev 12-20) (NAVY)   
--  * FSM events that the mission designer can hook into
--  * Can also be used as GCI Controller
-- 
-- ## 0 Note for Multiplayer Setup
-- 
-- Due to DCS limitations you need to set up a second, "normal" AWACS plane in multi-player/server environments to keep the EPLRS/DataLink going in these environments.
-- Though working in single player, the situational awareness screens of the e.g. F14/16/18 will else not receive datalink targets.
-- 
-- ## 1 Prerequisites
-- 
-- The radio callouts in this class are ***exclusively*** created with Text-To-Speech (TTS), based on the Moose @{Sound.SRS} Class, and output is via [Ciribob's SRS system](https://github.com/ciribob/DCS-SimpleRadioStandalone/releases)
-- Ensure you have this covered and working before tackling this class. TTS generation can thus be done via the Windows built-in system or via Google TTS; 
-- the latter offers a wider range of voices and options, but you need to set up your own Google product account for this to work correctly.
-- 
-- ## 2 Mission Design - Operational Priorities
-- 
-- Basic operational target of the AWACS is to control a Fighter Engagement Zone, or FEZ, and defend itself.
-- 
-- ## 3 Airwing(s)
-- 
-- The AWACS plane, the optional escort planes, and the AI CAP planes work based on the @{Ops.Airwing} class. Read and understand the manual for this class in 
-- order to set everything up correctly. You will at least need one Squadron containing the AWACS plane itself.
-- 
-- Set up the Airwing
-- 
--            local AwacsAW = AIRWING:New("AirForce WH-1","AirForce One")
--            AwacsAW:SetMarker(false)
--            AwacsAW:SetAirbase(AIRBASE:FindByName(AIRBASE.Caucasus.Kutaisi))
--            AwacsAW:SetRespawnAfterDestroyed(900)
--            AwacsAW:SetTakeoffAir()
--            AwacsAW:__Start(2)
-- 
-- Add the AWACS template Squadron - **Note**: remove the task AWACS in the mission editor under "Advanced Waypoint Actions" from the template to remove the DCS F10 AWACS menu
-- 
--            local Squad_One = SQUADRON:New("Awacs One",2,"Awacs North")
--            Squad_One:AddMissionCapability({AUFTRAG.Type.ORBIT},100)
--            Squad_One:SetFuelLowRefuel(true)
--            Squad_One:SetFuelLowThreshold(0.2)
--            Squad_One:SetTurnoverTime(10,20)
--            AwacsAW:AddSquadron(Squad_One)
--            AwacsAW:NewPayload("Awacs One One",-1,{AUFTRAG.Type.ORBIT},100)
--            
-- Add Escorts Squad (recommended, optional)
-- 
--            local Squad_Two = SQUADRON:New("Escorts",4,"Escorts North") -- taking a template with 2 planes here, will result in a group of 2 escorts which can fly in formation escorting the AWACS.
--            Squad_Two:AddMissionCapability({AUFTRAG.Type.ESCORT})
--            Squad_Two:SetFuelLowRefuel(true)
--            Squad_Two:SetFuelLowThreshold(0.3)
--            Squad_Two:SetTurnoverTime(10,20)
--            Squad_Two:SetTakeoffAir()
--            Squad_Two:SetRadio(255,radio.modulation.AM)
--            AwacsAW:AddSquadron(Squad_Two)
--            AwacsAW:NewPayload("Escorts",-1,{AUFTRAG.Type.ESCORT},100)
--            
-- Add CAP Squad (recommended, optional)
-- 
--            local Squad_Three = SQUADRON:New("CAP",10,"CAP North")
--            Squad_Three:AddMissionCapability({AUFTRAG.Type.ALERT5, AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT},80)
--            Squad_Three:SetFuelLowRefuel(true)
--            Squad_Three:SetFuelLowThreshold(0.3)
--            Squad_Three:SetTurnoverTime(10,20)
--            Squad_Three:SetTakeoffAir()
--            Squad_Two:SetRadio(255,radio.modulation.AM)
--            AwacsAW:AddSquadron(Squad_Three)
--            AwacsAW:NewPayload("Aerial-1-2",-1,{AUFTRAG.Type.ALERT5,AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT},100)
-- 
-- ## 4 Zones
-- 
-- For the setup, you need to set up a couple of zones:
-- 
-- * An Orbit Zone, where your AWACS will orbit
-- * A Fighter Engagement Zone or FEZ
-- * A zone where your CAP flights will be stationed, waiting for assignments
-- * Optionally, an additional zone you wish to defend
-- * Optionally, a border of the opposing party
-- * Also, and move your BullsEye in the mission accordingly - this will be the key reference point for most AWACS callouts
-- 
-- ### 4.1 Strategic considerations
-- 
-- Your AWACS is an HVT or high-value-target. Thus it makes sense to position the Orbit Zone in a way that your FEZ and thus your CAP flights defend it. 
-- It should hence be positioned behind the FEZ, away from the direction of enemy engagement.
-- The zone for CAP stations should be close to the FEZ, but not inside it.
-- The optional additional defense zone can be anywhere, but keep an eye on the location so your CAP flights don't take ages to get there. 
-- The optional border is useful for e.g. "cold war" scenarios - planes across the border will not be considered as targets by AWACS.
-- 
-- ## 5 Set up AWACS
-- 
--            -- Set up AWACS called "AWACS North". It will use the AwacsAW Airwing set up above and be of the "blue" coalition. Homebase is Kutaisi.
--            -- The AWACS Orbit Zone is a round zone set in the mission editor named "Awacs Orbit", the FEZ is a Polygon-Zone called "Rock" we have also
--            -- set up in the mission editor with a late activated helo named "Rock#ZONE_POLYGON". Note this also sets the BullsEye to be referenced as "Rock".
--            -- The CAP station zone is called "Fremont". We will be on 255 AM.
--            local testawacs = AWACS:New("AWACS North",AwacsAW,"blue",AIRBASE.Caucasus.Kutaisi,"Awacs Orbit",ZONE:FindByName("Rock"),"Fremont",255,radio.modulation.AM )
--            -- set one escort group; this example has two units in the template group, so they can fly a nice formation.
--            testawacs:SetEscort(1,ENUMS.Formation.FixedWing.FingerFour.Group,{x=-500,y=50,z=500},45)
--            -- Callsign will be "Focus". We'll be a Angels 30, doing 300 knots, orbit leg to 88deg with a length of 25nm.
--            testawacs:SetAwacsDetails(CALLSIGN.AWACS.Focus,1,30,300,88,25)
--            -- Set up SRS on port 5010 - change the below to your path and port
--            testawacs:SetSRS("C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio","female","en-GB",5010)
--            -- Add a "red" border we don't want to cross, set up in the mission editor with a late activated helo named "Red Border#ZONE_POLYGON"
--            testawacs:SetRejectionZone(ZONE:FindByName("Red Border"))
--            -- Our CAP flight will have the callsign "Ford", we want 4 AI planes, Time-On-Station is four hours, doing 300 kn IAS.
--            testawacs:SetAICAPDetails(CALLSIGN.Aircraft.Ford,4,4,300)
--            -- We're modern (default), e.g. we have EPLRS and get more fill-in information on detections
--            testawacs:SetModernEra()
--            -- And start
--            testawacs:__Start(5)
--            
-- ### 5.1 Alternative - Set up as GCI (no AWACS plane needed) Theater Air Control System (TACS)
-- 
--            -- Set up as TACS called "GCI Senaki". It will use the AwacsAW Airwing set up above and be of the "blue" coalition. Homebase is Senaki.
--            -- No need to set the AWACS Orbit Zone; the FEZ is still a Polygon-Zone called "Rock" we have also
--            -- set up in the mission editor with a late activated helo named "Rock#ZONE_POLYGON". Note this also sets the BullsEye to be referenced as "Rock".
--            -- The CAP station zone is called "Fremont". We will be on 255 AM. Note the Orbit Zone is given as *nil* in the `New()`-Statement
--            local testawacs = AWACS:New("GCI Senaki",AwacsAW,"blue",AIRBASE.Caucasus.Senaki_Kolkhi,nil,ZONE:FindByName("Rock"),"Fremont",255,radio.modulation.AM )
--            -- Set up SRS on port 5010 - change the below to your path and port
--            testawacs:SetSRS("C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio","female","en-GB",5010)
--            -- Add a "red" border we don't want to cross, set up in the mission editor with a late activated helo named "Red Border#ZONE_POLYGON"
--            testawacs:SetRejectionZone(ZONE:FindByName("Red Border"))
--            -- Our CAP flight will have the callsign "Ford", we want 4 AI planes, Time-On-Station is four hours, doing 300 kn IAS.
--            testawacs:SetAICAPDetails(CALLSIGN.Aircraft.Ford,4,4,300)
--            -- We're modern (default), e.g. we have EPLRS and get more fill-in information on detections
--            testawacs:SetModernEra()
--            -- Give it a fancy callsign
--            testawacs:SetAwacsDetails(CALLSIGN.AWACS.Wizard)
--            -- And start as GCI using a group name "Blue EWR" as main EWR station
--            testawacs:SetAsGCI(GROUP:FindByName("Blue EWR"),2)
--            -- Set Custom CAP Flight Callsigns for use with TTS
--            testawacs:SetCustomCallsigns({
--              Devil = 'Bengal',
--              Snake = 'Winder',
--              Colt = 'Camelot',
--              Enfield = 'Victory',
--              Uzi = 'Evil Eye'
--            })
--            testawacs:__Start(4)
--            
-- ## 6 Menu entries
-- 
-- **Note on Radio Menu entries**: Due to a DCS limitation, these are on GROUP level and not individual (UNIT level). Hence, either put each player in his/her own group,
-- or ensure that only the flight lead will use the menu. Recommend the 1st option, unless you have a disciplined team.
-- 
-- ### 6.1 Check-in
-- 
-- In the base setup, you need to check in to the AWACS to get the full menu. This can be done once the AWACS is airborne. You will get an Alpha Check callout 
-- and be assigned a CAP station.
-- 
-- ### 6.2 Check-out
-- 
-- You can check-out anytime, of course.
-- 
-- ### 6.3 Picture
-- 
-- Get a picture from the AWACS. It will call out the three most important groups. References are **always** to the (named) BullsEye position.
-- **Note** that AWACS will anyway do a regular picture call to all stations every five minutes.
-- 
-- ### 6.4 Bogey Dope
-- 
-- Get bogey dope from the AWACS. It will call out the closest bogey group, if any. Reference is BRAA to the Player position.
-- 
-- ### 6.5 Declare
-- 
-- AWACS will declare, if the bogey closest to the calling player in a 3nm circle is hostile, friendly or neutral.
-- 
-- ### 6.6 Tasking
-- 
-- Tasking will show you the current task with "Showtask". Updated directions are shown, also.
-- You can decline a **requested** task with "unable", and abort **any task but CAP station** with "abort".
-- You can "commit" to a requested task within 3 minutes.
-- "VID" - if AWACS is set to Visial ID or VID oncoming planes first, there will also be an "VID" entry. Similar to "Declare" you can declare the requested contact 
-- to be hostile, friendly or neutral if you are close enough to it (3nm). If hostile, at the time of writing, an engagement task will be assigned to you (not: requested).
-- If neutral/friendly, contact will be excluded from further tasking.
-- 
-- ## 7 Air-to-Air Timeline Support
-- 
-- To support your engagement timeline, AWACS will make Tac-Range, Meld, Merge and Threat call-outs to the player/group (Figure 7-3, CNATRA P-877). Default settings in NM are 
-- 
--            Tac Distance = 45
--            Meld Distance = 35
--            Threat Distance = 25
--            Merge Distance = 5 
-- 
-- ## 8 Bespoke Player CallSigns
-- 
-- Append the GROUP name of your client slots with "#CallSign" to use bespoke callsigns in AWACS callouts. E.g. "Player F14#Ghostrider" will be refered to 
-- as "Ghostrider" plus group number, e.g. "Ghostrider 9". Alternatively, if you have set up your Player name in the "Logbook" in the mission editor main screen
-- as e.g. "Pikes | Goose", you will be addressed as "Goose" by the AWACS callouts.
--
-- ## 9 Options
-- 
-- There's a number of functions available, to set various options for the setup.
-- 
-- * @{#AWACS.SetBullsEyeAlias}() : Set the alias name of the Bulls Eye.
-- * @{#AWACS.SetTOS}() : Set time on station for AWACS and CAP.
-- * @{#AWACS.SetReassignmentPause}() : Pause this number of seconds before re-assigning a Player to a task.
-- * @{#AWACS.SuppressScreenMessages}() : Suppress message output on screen.
-- * @{#AWACS.SetRadarBlur}() : Set the radar blur faktor in percent.
-- * @{#AWACS.SetColdWar}() : Set to cold war - no fill-ins, no EPLRS, VID as standard.
-- * @{#AWACS.SetModernEraDefensive}() : Set to modern, EPLRS, BVR/IFF engagement, fill-ins.
-- * @{#AWACS.SetModernEraAggressive}() : Set to modern, EPLRS, BVR/IFF engagement, fill-ins.
-- * @{#AWACS.SetPolicingModern}() : Set to modern, EPLRS, VID engagement, fill-ins.
-- * @{#AWACS.SetPolicingColdWar}() : Set to cold war, no EPLRS, VID engagement, no fill-ins.
-- * @{#AWACS.SetInterceptTimeline}() : Set distances for TAC, Meld and Threat range calls.
-- * @{#AWACS.SetAdditionalZone}() : Add one additional defense zone, e.g. own border.
-- * @{#AWACS.SetRejectionZone}() : Add one foreign border. Targets beyond will be ignored for tasking.
-- * @{#AWACS.DrawFEZ}() : Show the FEZ on the F10 map.
-- * @{#AWACS.SetAWACSDetails}() : Set AWACS details.
-- * @{#AWACS.AddGroupToDetection}() : Add a GROUP or SET_GROUP object to INTEL detection, e.g. EWR.
-- * @{#AWACS.SetSRS}() : Set SRS details.
-- * @{#AWACS.SetSRSVoiceCAP}() : Set voice details for AI CAP planes, using Windows dektop TTS.
-- * @{#AWACS.SetAICAPDetails}() : Set AI CAP details.
-- * @{#AWACS.SetEscort}() : Set number of escorting planes for AWACS.
-- * @{#AWACS.AddCAPAirWing}() : Add an additional @{Ops.Airwing#AIRWING} for CAP flights.
-- * @{#AWACS.ZipLip}() : Do not show messages on screen, no extra calls for player guidance, use short callsigns, no group tags.
-- * @{#AWACS.AddFrequencyAndModulation}() : Add additional frequencies with modulation which will receive AWACS SRS messages.
-- 
-- ## 9.1 Single Options
-- 
-- Further single options (set before starting your AWACS instance, but after `:New()`)
-- 
--            testawacs.PlayerGuidance = true -- allow missile warning call-outs.
--            testawacs.NoGroupTags = false -- use group tags like Alpha, Bravo .. etc in call outs.
--            testawacs.callsignshort = true -- use short callsigns, e.g. "Moose 1", not "Moose 1-1".
--            testawacs.DeclareRadius = 5 -- you need to be this close to the lead unit for declare/VID to work, in NM.
--            testawacs.MenuStrict = true -- Players need to check-in to see the menu; check-in still require to use the menu.
--            testawacs.maxassigndistance = 100 -- Don't assign targets further out than this, in NM.
--            testawacs.debug = false -- set to true to produce more log output.
--            testawacs.NoMissileCalls = true -- suppress missile callouts
--            testawacs.PlayerCapAssignment = true -- no intercept task assignments for players
--            testawacs.invisible = false -- set AWACS to be invisible to hostiles
--            testawacs.immortal = false -- set AWACS to be immortal
--            -- By default, the radio queue is checked every 10 secs. This is altered by the calculated length of the sentence to speak
--            -- over the radio. Google and Windows speech speed is different. Use the below to fine-tune the setup in case of overlapping
--            -- messages or too long pauses
--            testawacs.GoogleTTSPadding = 1 -- seconds
--            testawacs.WindowsTTSPadding = 2.5 -- seconds
--            testawacs.PikesSpecialSwitch = false -- if set to true, AWACS will omit the "doing xy knots" on the station assignement callout
--            testawacs.IncludeHelicopters = false -- if set to true, Helicopter pilots will also get the AWACS Menu and options
-- 
-- ## 9.2 Bespoke random voices for AI CAP (Google TTS only)
-- 
-- Currently there are 10 voices defined which are randomly assigned to the AI CAP flights:
-- 
-- Defaults are:
-- 
--          testawacs.CapVoices = {
--            [1] = "de-DE-Wavenet-A",
--            [2] = "de-DE-Wavenet-B",
--            [3] = "fr-FR-Wavenet-A",
--            [4] = "fr-FR-Wavenet-B",
--            [5] = "en-GB-Wavenet-A",
--            [6] = "en-GB-Wavenet-B",
--            [7] = "en-GB-Wavenet-D",
--            [8] = "en-AU-Wavenet-B",
--            [9] = "en-US-Wavenet-J",
--            [10] = "en-US-Wavenet-H",
--           }
-- 
-- ## 10 Using F10 map markers to create new player station points
-- 
-- You can use F10 map markers to create new station points for human CAP flights. The latest created station will take priority for (new) station assignments for humans.
-- Enable this option with
-- 
--            testawacs.AllowMarkers = true
--            
-- Set a marker on the map and add the following text to create a station: "AWACS Station London" - "AWACS Station" are the necessary keywords, "London" 
-- in this example will be the name of the new station point. The user marker can then be deleted, an info marker point at the same place will remain.
-- You can delete a player station point the same way: "AWACS Delete London"; note this will only work if currently there are no assigned flights on this station. 
-- Lastly, you can move the station around with keyword "Move": "AWACS Move London".
-- 
-- ## 11 Localization
-- 
-- Localization for English text is build-in. Default setting is English. Change with @{#AWACS.SetLocale}()
-- 
-- ### 11.1 Adding Localization
-- 
-- A list of fields to be defined follows below. **Note** that in some cases `string.format()` is used to format texts for screen and SRS. 
-- Hence, the `%d`, `%s` and `%f` special characters need to appear in the exact same amount and order of appearance in the localized text or it will create errors.
-- To add a localization, the following texts need to be translated and set in your mission script **before** @{#AWACS.Start}():   
-- 
--      AWACS.Messages = {
--        EN =
--          {
--          DEFEND = "%s, %s! %s! %s! Defend!",
--          VECTORTO = "%s, %s. Vector%s %s",
--          VECTORTOTTS = "%s, %s, Vector%s %s",
--          ANGELS = ". Angels ",
--          ZERO = "zero",
--          VANISHED = "%s, %s Group. Vanished.",
--          VANISHEDTTS = "%s, %s group vanished.",
--          SHIFTCHANGE = "%s shift change for %s control.",
--          GROUPCAP = "Group",
--          GROUP = "group",
--          MILES = "miles",
--          THOUSAND = "thousand",
--          BOGEY = "Bogey",
--          ALLSTATIONS = "All Stations",
--          PICCLEAN = "%s. %s. Picture Clean.",
--          PICTURE = "Picture",
--          ONE = "One",
--          GROUPMULTI = "groups",
--          NOTCHECKEDIN = "%s. %s. Negative. You are not checked in.",
--          CLEAN = "%s. %s. Clean.",
--          DOPE = "%s. %s. Bogey Dope. ",
--          VIDPOS = "%s. %s. Copy, target identified as %s.",
--          VIDNEG = "%s. %s. Negative, get closer to target.",
--          FFNEUTRAL = "Neutral",
--          FFFRIEND = "Friendly",
--          FFHOSTILE = "Hostile",
--          FFSPADES = "Spades",
--          FFCLEAN = "Clean",
--          COPY = "%s. %s. Copy.",
--          TARGETEDBY = "Targeted by %s.",
--          STATUS = "Status",
--          ALREADYCHECKEDIN = "%s. %s. Negative. You are already checked in.",
--          ALPHACHECK = "Alpha Check",
--          CHECKINAI = "%s. %s. Checking in as fragged. Expected playtime %d hours. Request Alpha Check %s.",
--          SAFEFLIGHT = "%s. %s. Copy. Have a safe flight home.",
--          VERYLOW = "very low",
--          AIONSTATION = "%s. %s. On station over anchor %d at angels  %d. Ready for tasking.",
--          POPUP = "Pop-up",
--          NEWGROUP = "New group",
--          HIGH= " High.",
--          VERYFAST = " Very fast.",
--          FAST = " Fast.",
--          THREAT = "Threat",
--          MERGED = "Merged",
--          SCREENVID = "Intercept and VID %s group.",
--          SCREENINTER = "Intercept %s group.",
--          ENGAGETAG = "Targeted by %s.",
--          REQCOMMIT = "%s. %s group. %s. %s, request commit.",
--          AICOMMIT = "%s. %s group. %s. %s, commit.",
--          COMMIT = "Commit",
--          SUNRISE = "%s. All stations, SUNRISE SUNRISE SUNRISE, %s.",
--          AWONSTATION = "%s on station for %s control.",
--          STATIONAT = "%s. %s. Station at %s at angels %d.",
--          STATIONATLONG = "%s. %s. Station at %s at angels %d doing %d knots.",
--          STATIONSCREEN = "%s. %s.\nStation at %s\nAngels %d\nSpeed %d knots\nCoord %s\nROE %s.",
--          STATIONTASK = "Station at %s\nAngels %d\nSpeed %d knots\nCoord %s\nROE %s",
--          VECTORSTATION = " to Station",
--          TEXTOPTIONS1 = "Lost friendly flight",
--          TEXTOPTIONS2 =  "Vanished friendly flight",
--          TEXTOPTIONS3 =  "Faded friendly contact",
--          TEXTOPTIONS4 =  "Lost contact with",
--          },
--         } 
-- 
-- e.g.
-- 
--            testawacs.Messages = {
--              DE = {
--                ...
--                FFNEUTRAL = "Neutral",
--                FFFRIEND = "Freund",
--                FFHOSTILE = "Feind",
--                FFSPADES = "Uneindeutig",
--                FFCLEAN = "Sauber",
--                ...
--              },
--             
-- ## 12 Discussion
--
-- If you have questions or suggestions, please visit the [MOOSE Discord](https://discord.gg/AeYAkHP) #ops-awacs channel.
-- 
-- 
-- 
-- 
-- @field #AWACS
AWACS = {
  ClassName = "AWACS", -- #string
  version = "0.2.74", -- #string
  lid = "", -- #string
  coalition = coalition.side.BLUE, -- #number
  coalitiontxt = "blue", -- #string
  OpsZone = nil,
  StationZone = nil,
  AirWing = nil,
  Frequency = 271, -- #number
  Modulation = radio.modulation.AM, -- #number
  Airbase = nil,
  AwacsAngels = 25, -- orbit at 25'000 ft
  OrbitZone = nil,
  CallSign = CALLSIGN.AWACS.Magic, -- #number
  CallSignNo = 1, -- #number
  debug = false,
  verbose = false,
  ManagedGrps = {},
  ManagedGrpID = 0, -- #number
  ManagedTaskID = 0, -- #number
  AnchorStacks = {}, -- Utilities.FiFo#FIFO
  CAPIdleAI = {},
  CAPIdleHuman = {},
  TaskedCAPAI = {},
  TaskedCAPHuman = {},
  OpenTasks = {}, -- Utilities.FiFo#FIFO
  ManagedTasks = {}, -- Utilities.FiFo#FIFO
  PictureAO = {}, -- Utilities.FiFo#FIFO
  PictureEWR = {}, -- Utilities.FiFo#FIFO
  Contacts = {}, -- Utilities.FiFo#FIFO
  Countactcounter = 0,
  ContactsAO = {}, -- Utilities.FiFo#FIFO
  RadioQueue = {}, -- Utilities.FiFo#FIFO
  PrioRadioQueue = {}, -- Utilities.FiFo#FIFO
  TacticalQueue = {}, -- Utilities.FiFo#FIFO
  AwacsTimeOnStation = 4,
  AwacsTimeStamp = 0,
  EscortsTimeOnStation = 4,
  EscortsTimeStamp = 0,
  CAPTimeOnStation = 4,
  AwacsROE = "",
  AwacsROT = "",
  MenuStrict = true,
  MaxAIonCAP = 3,
  AIonCAP = 0,
  AICAPMissions = {}, -- Utilities.FiFo#FIFO
  ShiftChangeAwacsFlag = false,
  ShiftChangeEscortsFlag = false,
  ShiftChangeAwacsRequested = false,
  ShiftChangeEscortsRequested = false,
  CAPAirwings = {},  -- Utilities.FiFo#FIFO
  MonitoringData = {},
  MonitoringOn = false,
  FlightGroups = {},
  AwacsMission = nil,
  AwacsInZone = false, -- not yet arrived or gone again
  AwacsReady = false,
  CatchAllMissions = {},
  CatchAllFGs = {},
  PictureInterval = 300,
  ReassignTime = 120,
  PictureTimeStamp = 0,
  BorderZone = nil,
  RejectZone = nil,
  maxassigndistance = 100,
  PlayerGuidance = true,
  ModernEra = true,
  callsignshort = true,
  keepnumber = true,
  callsignTranslations = nil,
  TacDistance = 45,
  MeldDistance = 35,
  ThreatDistance = 25,
  AOName = "Rock",
  AOCoordinate = nil,
  clientmenus = nil,
  RadarBlur = 15,
  ReassignmentPause = 180,
  NoGroupTags = false,
  SuppressScreenOutput = false,
  NoMissileCalls = true,
  GoogleTTSPadding = 1,
  WindowsTTSPadding = 2.5,
  PlayerCapAssignment = true,
  AllowMarkers = false,
  PlayerStationName = nil,
  GCI = false,
  GCIGroup = nil,
  locale = "en",
  IncludeHelicopters = false,
  TacticalMenu = false,
  TacticalFrequencies = {},
  TacticalSubscribers = {},
  TacticalBaseFreq = 130,
  TacticalIncrFreq = 0.5,
  TacticalModulation = radio.modulation.AM,
  TacticalInterval = 120,
  DetectionSet = nil,
  MaxMissionRange = 125,
}

---
--@field CallSignClear
AWACS.CallSignClear = {
    [1]="Overlord",
    [2]="Magic",
    [3]="Wizard",
    [4]="Focus",
    [5]="Darkstar",
}

---
-- @field AnchorNames
AWACS.AnchorNames = {
  [1] = "One",
  [2] = "Two",
  [3] = "Three",
  [4] = "Four",
  [5] = "Five",
  [6] = "Six",
  [7] = "Seven",
  [8] = "Eight",
  [9] = "Nine",
  [10] = "Ten",
}

---
-- @field IFF
AWACS.IFF =
{
  SPADES = "Spades",
  NEUTRAL = "Neutral",
  FRIENDLY = "Friendly",
  ENEMY = "Hostile",
  BOGEY = "Bogey",
}

---
-- @field Phonetic
AWACS.Phonetic =
{
  [1] = 'Alpha',
  [2] = 'Bravo',
  [3] = 'Charlie',
  [4] = 'Delta',
  [5] = 'Echo',
  [6] = 'Foxtrot',
  [7] = 'Golf',
  [8] = 'Hotel',
  [9] = 'India',
  [10] = 'Juliett',
  [11] = 'Kilo',
  [12] = 'Lima',
  [13] = 'Mike',
  [14] = 'November',
  [15] = 'Oscar',
  [16] = 'Papa',
  [17] = 'Quebec',
  [18] = 'Romeo',
  [19] = 'Sierra',
  [20] = 'Tango',
  [21] = 'Uniform',
  [22] = 'Victor',
  [23] = 'Whiskey',
  [24] = 'Xray',
  [25] = 'Yankee',
  [26] = 'Zulu',
}

---
-- @field Shipsize
AWACS.Shipsize =
{
  [1] = "Singleton",
  [2] = "Two-Ship",
  [3] = "Heavy",
  [4] = "Gorilla",
}

---
-- @field ROE
AWACS.ROE = {
  POLICE = "Police",
  VID = "Visual ID",
  IFF = "IFF",
  BVR = "Beyond Visual Range",
}

---
-- @field AWACS.ROT
AWACS.ROT = {
    BYPASSESCAPE = "Bypass and Escape",
    EVADE = "Evade Fire",
    PASSIVE = "Passive Defense",
    RETURNFIRE = "Return Fire",
    OPENFIRE = "Open Fire",
 }
 
---
--@field THREATLEVEL -- can be 1-10, thresholds
AWACS.THREATLEVEL = {
  GREEN = 3,
  AMBER = 7,
  RED = 10,
}

---
--@field CapVoices -- Random CAP voices
AWACS.CapVoices = {
  [1] = "de-DE-Wavenet-A",
  [2] = "de-DE-Wavenet-B",
  [3] = "fr-FR-Wavenet-A",
  [4] = "fr-FR-Wavenet-B",
  [5] = "en-GB-Wavenet-A",
  [6] = "en-GB-Wavenet-B",
  [7] = "en-GB-Wavenet-D",
  [8] = "en-AU-Wavenet-B",
  [9] = "en-US-Wavenet-J",
  [10] = "en-US-Wavenet-H",
}

---
-- @field Messages 
AWACS.Messages = {
  EN =
    {
    DEFEND = "%s, %s! %s! %s! Defend!",
    VECTORTO = "%s, %s. Vector%s %s",
    VECTORTOTTS = "%s, %s, Vector%s %s",
    ANGELS = ". Angels ",
    ZERO = "zero",
    VANISHED = "%s, %s Group. Vanished.",
    VANISHEDTTS = "%s, %s group vanished.",
    SHIFTCHANGE = "%s shift change for %s control.",
    GROUPCAP = "Group",
    GROUP = "group",
    MILES = "miles",
    THOUSAND = "thousand",
    BOGEY = "Bogey",
    ALLSTATIONS = "All Stations",
    PICCLEAN = "%s. %s. Picture Clean.",
    PICTURE = "Picture",
    ONE = "One",
    GROUPMULTI = "groups",
    NOTCHECKEDIN = "%s. %s. Negative. You are not checked in.",
    CLEAN = "%s. %s. Clean.",
    DOPE = "%s. %s. Bogey Dope. ",
    VIDPOS = "%s. %s. Copy, target identified as %s.",
    VIDNEG = "%s. %s. Negative, get closer to target.",
    FFNEUTRAL = "Neutral",
    FFFRIEND = "Friendly",
    FFHOSTILE = "Hostile",
    FFSPADES = "Spades",
    FFCLEAN = "Clean",
    COPY = "%s. %s. Copy.",
    TARGETEDBY = "Targeted by %s.",
    STATUS = "Status",
    ALREADYCHECKEDIN = "%s. %s. Negative. You are already checked in.",
    ALPHACHECK = "Alpha Check",
    CHECKINAI = "%s. %s. Checking in as fragged. Expected playtime %d hours. Request Alpha Check %s.",
    SAFEFLIGHT = "%s. %s. Copy. Have a safe flight home.",
    VERYLOW = "very low",
    AIONSTATION = "%s. %s. On station over anchor %d at angels  %d. Ready for tasking.",
    POPUP = "Pop-up",
    NEWGROUP = "New group",
    HIGH= " High.",
    VERYFAST = " Very fast.",
    FAST = " Fast.",
    THREAT = "Threat",
    MERGED = "Merged",
    SCREENVID = "Intercept and VID %s group.",
    SCREENINTER = "Intercept %s group.",
    ENGAGETAG = "Targeted by %s.",
    REQCOMMIT = "%s. %s group. %s. %s, request commit.",
    AICOMMIT = "%s. %s group. %s. %s, commit.",
    COMMIT = "Commit",
    SUNRISE = "%s. All stations, SUNRISE SUNRISE SUNRISE, %s.",
    AWONSTATION = "%s on station for %s control.",
    STATIONAT = "%s. %s. Station at %s at angels %d.",
    STATIONATLONG = "%s. %s. Station at %s at angels %d doing %d knots.",
    STATIONSCREEN = "%s. %s.\nStation at %s\nAngels %d\nSpeed %d knots\nCoord %s\nROE %s.",
    STATIONTASK = "Station at %s\nAngels %d\nSpeed %d knots\nCoord %s\nROE %s",
    VECTORSTATION = " to Station",
    TEXTOPTIONS1 = "Lost friendly flight",
    TEXTOPTIONS2 =  "Vanished friendly flight",
    TEXTOPTIONS3 =  "Faded friendly contact",
    TEXTOPTIONS4 =  "Lost contact with",
    },
} 

---
-- @type AWACS.MonitoringData
-- @field #string AwacsStateMission
-- @field #string AwacsStateFG
-- @field #boolean AwacsShiftChange 
-- @field #table EscortsStateMission
-- @field #table EscortsStateFG
-- @field #boolean EscortsShiftChange
-- @field #number AICAPMax
-- @field #number AICAPCurrent
-- @field #number Airwings
-- @field #number Players
-- @field #number PlayersCheckedin

---
-- @type AWACS.MenuStructure
-- @field #boolean menuset
-- @field #string groupname
-- @field Core.Menu#MENU_GROUP basemenu
-- @field Core.Menu#MENU_GROUP_COMMAND checkin
-- @field Core.Menu#MENU_GROUP_COMMAND checkout
-- @field Core.Menu#MENU_GROUP_COMMAND picture
-- @field Core.Menu#MENU_GROUP_COMMAND bogeydope
-- @field Core.Menu#MENU_GROUP_COMMAND declare
-- @field Core.Menu#MENU_GROUP tasking
-- @field Core.Menu#MENU_GROUP_COMMAND showtask
-- @field Core.Menu#MENU_GROUP_COMMAND judy
-- @field Core.Menu#MENU_GROUP_COMMAND unable
-- @field Core.Menu#MENU_GROUP_COMMAND abort
-- @field Core.Menu#MENU_GROUP_COMMAND commit
-- @field Core.Menu#MENU_GROUP vid
-- @field Core.Menu#MENU_GROUP_COMMAND neutral
-- @field Core.Menu#MENU_GROUP_COMMAND hostile
-- @field Core.Menu#MENU_GROUP_COMMAND friendly

--- Group Data
-- @type AWACS.ManagedGroup
-- @field Wrapper.Group#GROUP Group
-- @field #string GroupName
-- @field Ops.FlightGroup#FLIGHTGROUP FlightGroup for AI
-- @field #boolean IsPlayer
-- @field #boolean IsAI
-- @field #string CallSign
-- @field #number CurrentAuftrag -- Auftragsnummer for AI
-- @field #number CurrentTask -- ManagedTask ID
-- @field #boolean HasAssignedTask
-- @field #number GID
-- @field #number AnchorStackNo
-- @field #number AnchorStackAngels
-- @field #number ContactCID
-- @field Core.Point#COORDINATE LastKnownPosition
-- @field #number LastTasking TimeStamp

--- Contact Data
-- @type AWACS.ManagedContact
-- @field #number CID
-- @field Ops.Intel#INTEL.Contact Contact
-- @field Ops.Intel#INTEL.Cluster Cluster
-- @field #string IFF -- ID'ed or not (yet)
-- @field Ops.Target#TARGET Target
-- @field #number LinkedTask --> TID
-- @field #number LinkedGroup --> GID
-- @field #string Status - #AWACS.TaskStatus
-- @field #string TargetGroupNaming -- Alpha, Charlie
-- @field #string ReportingName -- NATO platform name
-- @field #string EngagementTag
-- @field #boolean TACCallDone
-- @field #boolean MeldCallDone
-- @field #boolean MergeCallDone

---
-- @type AWACS.TaskDescription
AWACS.TaskDescription = {
  ANCHOR = "Anchor",
  REANCHOR = "Re-Anchor",
  VID = "VID",
  IFF = "IFF",
  INTERCEPT = "Intercept",
  SWEEP = "Sweep",
  RTB = "RTB",
}

---
-- @type AWACS.TaskStatus
AWACS.TaskStatus = {
  IDLE = "Idle",
  UNASSIGNED = "Unassigned",
  REQUESTED = "Requested",
  ASSIGNED = "Assigned",
  EXECUTING = "Executing",
  SUCCESS = "Success",
  FAILED = "Failed",
  DEAD = "Dead",
}

---
-- @type AWACS.ManagedTask
-- @field #number TID
-- @field #number AssignedGroupID
-- @field #boolean IsPlayerTask
-- @field #boolean IsUnassigned
-- @field Ops.Target#TARGET Target
-- @field Ops.Auftrag#AUFTRAG Auftrag
-- @field #AWACS.TaskStatus Status
-- @field #AWACS.TaskDescription ToDo
-- @field #string ScreenText Long descrition
-- @field Ops.Intel#INTEL.Contact Contact
-- @field Ops.Intel#INTEL.Cluster Cluster
-- @field #number CurrentAuftrag
-- @field #number RequestedTimestamp

---
-- @type AWACS.AnchorAssignedEntry
-- @field #number ID
-- @field #number Angels

---
-- @type AWACS.AnchorData
-- @field #number AnchorBaseAngels
-- @field Core.Zone#ZONE_RADIUS StationZone
-- @field Core.Point#COORDINATE StationZoneCoordinate
-- @field #string StationZoneCoordinateText
-- @field #string StationName
-- @field Utilities.FiFo#FIFO AnchorAssignedID FiFo of #AWACS.AnchorAssignedEntry
-- @field Utilities.FiFo#FIFO Anchors FiFo of available stacks
-- @field Wrapper.Marker#MARKER AnchorMarker Tag for this station

---
--@type RadioEntry
--@field #string TextTTS
--@field #string TextScreen
--@field #boolean IsNew
--@field #boolean IsGroup
--@field #boolean GroupID
--@field #number Duration
--@field #boolean ToScreen
--@field #boolean FromAI

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO-List 0.2.54
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- DONE - WIP - Player tasking, VID
-- DONE - Localization (sensible?)
-- TODO - (LOW) LotATC
-- DONE - SW Optimization
-- WONTDO - Maybe check in AI only when airborne
-- DONE - remove SSML tag when not on google (currently sometimes spoken)
-- DONE - Maybe - Assign specific number of AI CAP to a station
-- DONE - Multiple AIRWING connection? Can't really get recruit to work, switched to random round robin
-- DONE - System for Players to VID contacts?
-- DONE - Task reassignment - if a player reject a task, don't choose him again for 3 minutes
-- DONE - added SSML tags to make google readouts nicer
-- DONE - 2nd audio queue for priority messages
-- DONE - (WIP) Missile launch callout
-- DONE - Event detection, Player joining, eject, crash, dead, leaving; AI shot -> DEFEND
-- DONE - AI Tasking
-- DONE - Shift Change, Change on asset RTB or dead or mission done (done for AWACS and Escorts)
-- DONE - TripWire - WIP - Threat (35nm), Meld (45nm, on mission), Merged (<3nm)
-- 
-- DONE - Escorts via Airwing not staying on
-- DONE - Borders for INTEL. Optional, i.e. land based defense within borders
-- DONE - Use AO as Anchor of Bulls, AO as default
-- DONE - SRS TTS output
-- DONE - Check-In/Out Humans
-- DONE - Check-In/Out AI
-- DONE - Picture
-- DONE - Declare
-- DONE - Bogey Dope
-- DONE - Radio Menu
-- DONE - Intel Detection
-- DONE - ROE
-- DONE - Anchor Stack Management
-- DONE - Shift Length AWACS/AI
-- DONE - (WIP) Reporting
-- DONE - Do not report non-airborne groups
-- DONE - Added option for helos
-- DONE - Added setting a coordinate for SRS

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO Constructor

--- Set up a new AI AWACS.
-- @param #AWACS self
-- @param #string Name Name of this AWACS for the radio menu.
-- @param #string AirWing The core Ops.Airwing#AIRWING managing the AWACS, Escort and (optionally) AI CAP planes for us.
-- @param #number Coalition Coalition, e.g. coalition.side.BLUE. Can also be passed as "blue", "red" or "neutral".
-- @param #string AirbaseName Name of the home airbase.
-- @param #string AwacsOrbit Name of the round, mission editor created zone where this AWACS orbits.
-- @param #string OpsZone Name of the round, mission editor created Fighter Engagement operations zone (FEZ) this AWACS controls. Can be passed as #ZONE_POLYGON. 
-- The name of the zone will be used in reference calls as bulls eye name, so ensure a radio friendly name that does not collide with NATOPS keywords.
-- @param #string StationZone Name of the round, mission editor created anchor zone where CAP groups will be stationed. Usually a short city name.
-- @param #number Frequency Radio frequency, e.g. 271.
-- @param #number Modulation Radio modulation, e.g. radio.modulation.AM or radio.modulation.FM.
-- @return #AWACS self
-- @usage
-- You can set up the OpsZone/FEZ in a number of ways:
-- * As a string denominating a normal, round zone you have created and named in the mission editor, e.g. "Rock".
-- * As a polygon zone, defined e.g. like `ZONE_POLYGON:New("Rock",GROUP:FindByName("RockZone"))` where "RockZone" is the name of a late activated helo, and it\'s waypoints (not more than 10) describe a closed polygon zone in the mission editor.
-- * As a string denominating a polygon zone from the mission editor (same late activated helo, but named "Rock#ZONE_POLYGON" in the mission editor. Here, Moose will auto-create a polygon zone when loading, and name it "Rock". Pass as `ZONE:FindByName("Rock")`.
function AWACS:New(Name,AirWing,Coalition,AirbaseName,AwacsOrbit,OpsZone,StationZone,Frequency,Modulation)
    -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New())
  
  --set Coalition
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
      self.coalitiontxt = Coalition
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
      self.coalitiontxt = Coalition
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
      self.coalitiontxt = Coalition
    else
      self:E("ERROR: Unknown coalition in AWACS!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- base setup
  self.Name = Name -- #string
  self.AirWing = AirWing -- Ops.Airwing#AIRWING object
  
  AirWing:SetUsingOpsAwacs(self)
  
  self.CAPAirwings = FIFO:New() -- Utilities.FiFo#FIFO
  self.CAPAirwings:Push(AirWing,1)
  
  self.AwacsFG = nil
  --self.AwacsPayload = PayLoad -- Ops.Airwing#AIRWING.Payload
  --self.ModernEra = true -- use of EPLRS
  self.RadarBlur = 15 -- +/-15% detection precision i.e. 85-115 reported group size
  if type(OpsZone) == "string" then
    self.OpsZone = ZONE:New(OpsZone) -- Core.Zone#ZONE
  elseif type(OpsZone) == "table" and OpsZone.ClassName and string.find(OpsZone.ClassName,"ZONE") then
    self.OpsZone = OpsZone
  else
    self:E("AWACS - Invalid Zone passed!")
    return
  end
  
  --self.AOCoordinate = self.OpsZone:GetCoordinate()
  self.AOCoordinate = COORDINATE:NewFromVec3( coalition.getMainRefPoint( self.coalition ) ) -- bulls eye from ME
  self.AOName = self.OpsZone:GetName()
  self.UseBullsAO = true -- as per NATOPS
  self.ControlZoneRadius = 100 -- nm
  self.StationZone = ZONE:New(StationZone) -- Core.Zone#ZONE
  self.StationZoneName = StationZone
  
  self.Frequency = Frequency or 271 -- #number
  self.Modulation = Modulation or radio.modulation.AM
  self.MultiFrequency = {self.Frequency}
  self.MultiModulation = {self.Modulation}

  self.Airbase = AIRBASE:FindByName(AirbaseName)
  self.AwacsAngels = 25 -- orbit at 25'000 ft
  if AwacsOrbit then
    self.OrbitZone = ZONE:New(AwacsOrbit) -- Core.Zone#ZONE
  end
  self.BorderZone = nil
  self.CallSign = CALLSIGN.AWACS.Magic -- #number
  self.CallSignNo = 1 -- #number
  self.NoHelos = true
  self.AIRequested = 0
  self.AIonCAP = 0
  self.AICAPMissions = FIFO:New() -- Utilities.FiFo#FIFO
  self.FlightGroups = FIFO:New() -- Utilities.FiFo#FIFO
  self.Countactcounter = 0
  
  self.PictureInterval = 300 -- picture every 5s mins
  self.PictureTimeStamp = 0 -- timestamp
  self.ReassignTime = 120 -- time for player re-assignment
  
  self.intelstarted = false
  self.sunrisedone = false
  
  local speed = 250
  self.SpeedBase = speed
  --self.Speed = UTILS.KnotsToAltKIAS(speed,self.AwacsAngels*1000)
  self.Speed = speed
  
  self.Heading = 0 -- north
  self.Leg = 50 -- nm
  self.invisible = false
  self.immortal = false
  self.callsigntxt = "AWACS"
  
  self.AwacsTimeOnStation = 4
  self.AwacsTimeStamp = 0
  self.EscortsTimeOnStation = 4
  self.EscortsTimeStamp = 0
  self.ShiftChangeTime = 0.25 -- 15mins
  self.ShiftChangeAwacsFlag = false
  self.ShiftChangeEscortsFlag = false
  
  self.CapSpeedBase = 270
  self.CAPTimeOnStation = 4
  self.MaxAIonCAP = 4
  self.AICAPCAllName = CALLSIGN.Aircraft.Colt
  self.AICAPCAllNumber = 0
  self.CAPGender = "male"
  self.CAPCulture = "en-US"
  self.CAPVoice = nil
  
  self.AwacsMission = nil
  self.AwacsInZone = false -- not yet arrived or gone again
  self.AwacsReady = false
  
  self.AwacsROE = AWACS.ROE.IFF
  self.AwacsROT = AWACS.ROT.BYPASSESCAPE
  
  -- Escorts
  self.HasEscorts = false
  self.EscortTemplate = ""
  self.EscortMission = {}
  self.EscortMissionReplacement = {}
  
  -- SRS
  self.PathToSRS = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
  self.Gender = "female"
  self.Culture = "en-GB"
  self.Voice = nil
  self.Port = 5002
  self.Volume = 1.0
  self.RadioQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.PrioRadioQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TacticalQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.maxspeakentries = 3
  self.GoogleTTSPadding = 1
  self.WindowsTTSPadding = 2.5
  
  -- Client SET  
  self.clientset = SET_CLIENT:New():FilterActive(true):FilterCoalitions(self.coalitiontxt):FilterCategories("plane"):FilterStart()
  
  -- Player options
  self.PlayerGuidance = true
  self.ModernEra = true
  self.NoGroupTags = false
  self.SuppressScreenOutput = false  
  self.ReassignmentPause = 180
  self.callsignshort = true
  self.DeclareRadius = 5 -- NM
  self.MenuStrict = true
  self.maxassigndistance = 100 --nm
  self.NoMissileCalls = true
  self.PlayerCapAssignment = true
    
  -- managed groups
  self.ManagedGrps = {} -- #table of #AWACS.ManagedGroup entries
  self.ManagedGrpID = 0  
  self.callsignTranslations = nil
  
  -- Anchor stacks init
  self.AnchorStacks = FIFO:New() -- Utilities.FiFo#FIFO
  self.AnchorBaseAngels = 22
  self.AnchorStackDistance = 2
  self.AnchorMaxStacks = 4
  self.AnchorMaxAnchors = 2
  self.AnchorMaxZones = 6
  self.AnchorCurrZones = 1
  self.AnchorTurn = -(360/self.AnchorMaxZones)

  self:_CreateAnchorStack()

  -- Task lists
  self.ManagedTasks = FIFO:New() -- Utilities.FiFo#FIFO
  --self.OpenTasks = FIFO:New() -- Utilities.FiFo#FIFO

  -- Monitoring, init
  local MonitoringData = {} -- #AWACS.MonitoringData
  MonitoringData.AICAPCurrent = 0
  MonitoringData.AICAPMax = self.MaxAIonCAP
  MonitoringData.Airwings = 1
  MonitoringData.PlayersCheckedin = 0
  MonitoringData.Players = 0 
  MonitoringData.AwacsShiftChange = false
  MonitoringData.AwacsStateFG = "unknown"
  MonitoringData.AwacsStateMission = "unknown"
  MonitoringData.EscortsShiftChange = false
  MonitoringData.EscortsStateFG = {}
  MonitoringData.EscortsStateMission = {}
  self.MonitoringOn = false -- #boolean
  self.MonitoringData = MonitoringData
  
  self.CatchAllMissions = {}
  self.CatchAllFGs = {}
  
  -- Picture, Contacts, Bogeys
  self.PictureAO = FIFO:New() -- Utilities.FiFo#FIFO
  self.PictureEWR = FIFO:New() -- Utilities.FiFo#FIFO
  self.Contacts = FIFO:New() -- Utilities.FiFo#FIFO
  --self.ManagedContacts = FIFO:New()
  self.CID = 0
  self.ContactsAO = FIFO:New() -- Utilities.FiFo#FIFO
  
  self.clientmenus = FIFO:New() -- Utilities.FiFo#FIFO
  
  -- Tactical Menu
  self.TacticalMenu = false
  self.TacticalBaseFreq = 130
  self.TacticalIncrFreq = 0.5
  self.TacticalModulation = radio.modulation.AM
  self.acticalFrequencies = {}
  self.TacticalSubscribers = {}
  self.TacticalInterval = 120
  
  -- SET for Intel Detection
  self.DetectionSet=SET_GROUP:New()
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.Name, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
    -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "StartUp")     -- Start FSM.
  self:AddTransition("StartUp",       "Started",            "Running")    
  self:AddTransition("*",             "Status",             "*")           -- Status update.
  self:AddTransition("*",             "CheckedIn",          "*") 
  self:AddTransition("*",             "CheckedOut",         "*") 
  self:AddTransition("*",             "AssignAnchor",       "*") 
  self:AddTransition("*",             "AssignedAnchor",     "*")
  self:AddTransition("*",             "ReAnchor",           "*")
  self:AddTransition("*",             "NewCluster",         "*")
  self:AddTransition("*",             "NewContact",         "*")
  self:AddTransition("*",             "LostCluster",        "*")
  self:AddTransition("*",             "LostContact",        "*")
  self:AddTransition("*",             "CheckRadioQueue",    "*")
  self:AddTransition("*",             "CheckTacticalQueue", "*")  
  self:AddTransition("*",             "EscortShiftChange",  "*")
  self:AddTransition("*",             "AwacsShiftChange",   "*")
  self:AddTransition("*",             "FlightOnMission",    "*")
  self:AddTransition("*",             "Intercept",          "*")
  self:AddTransition("*",             "InterceptSuccess",   "*")
  self:AddTransition("*",             "InterceptFailure",   "*")
  self:AddTransition("*",             "VIDSuccess",   "*")
  self:AddTransition("*",             "VIDFailure",   "*")
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.
  
  
  local text = string.format("%sAWACS Version %s Initiated",self.lid,self.version)
  
  self:I(text)
  
  -- Events
  -- Player joins
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
    -- Player leaves
  self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.Crash, self._EventHandler)
  self:HandleEvent(EVENTS.Dead, self._EventHandler)
  self:HandleEvent(EVENTS.UnitLost, self._EventHandler)
  self:HandleEvent(EVENTS.BDA, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  -- Missile warning
  self:HandleEvent(EVENTS.Shot, self._EventHandler)
  
  self:_InitLocalization()
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
    --- Triggers the FSM event "Start". Starts the AWACS. Initializes parameters and starts event handlers.
  -- @function [parent=#AWACS] Start
  -- @param #AWACS self

  --- Triggers the FSM event "Start" after a delay. Starts the AWACS. Initializes parameters and starts event handlers.
  -- @function [parent=#AWACS] __Start
  -- @param #AWACS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the AWACS and all its event handlers.
  -- @param #AWACS self

  --- Triggers the FSM event "Stop" after a delay. Stops the AWACS and all its event handlers.
  -- @function [parent=#AWACS] __Stop
  -- @param #AWACS self
  -- @param #number delay Delay in seconds.
  
  --- On After "CheckedIn" event. AI or Player checked in.
  -- @function [parent=#AWACS] OnAfterCheckedIn
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
    --- On After "CheckedOut" event. AI or Player checked out.
  -- @function [parent=#AWACS] OnAfterCheckedOut
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
    --- On After "AssignedAnchor" event. AI or Player has been assigned a CAP station.
  -- @function [parent=#AWACS] OnAfterAssignedAnchor
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
    --- On After "ReAnchor" event. AI or Player has been send back to station.
  -- @function [parent=#AWACS] OnAfterReAnchor
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "NewCluster" event. AWACS detected a cluster.
  -- @function [parent=#AWACS] OnAfterNewCluster
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "NewContact" event. AWACS detected a contact.
  -- @function [parent=#AWACS] OnAfterNewContact
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "LostCluster" event. AWACS lost a radar cluster.
  -- @function [parent=#AWACS] OnAfterLostCluster
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "LostContact" event. AWACS lost a radar contact.
  -- @function [parent=#AWACS] OnAfterLostContact
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
    --- On After "EscortShiftChange" event. AWACS escorts shift change.
  -- @function [parent=#AWACS] OnAfterEscortShiftChange
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "AwacsShiftChange" event. AWACS shift change.
  -- @function [parent=#AWACS] OnAfterAwacsShiftChange
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "Intercept" event. CAP send on intercept.
  -- @function [parent=#AWACS] OnAfterIntercept
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "InterceptSuccess" event. Intercept successful.
  -- @function [parent=#AWACS] OnAfterInterceptSuccess
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "InterceptFailure" event. Intercept failure.
  -- @function [parent=#AWACS] OnAfterInterceptFailure
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- On After "VIDSuccess" event. Intercept successful.
  -- @function [parent=#AWACS] OnAfterVIDSuccess
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number GID Managed group ID (Player)
  -- @param Wrapper.Group#GROUP Group (Player) Group done the VID
  -- @param #AWACS.ManagedContact Contact The contact that was VID'd 
  
  --- On After "VIDFailure" event. Intercept failure.
  -- @function [parent=#AWACS] OnAfterVIDFailure
  -- @param #AWACS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number GID Managed group ID (Player)
  -- @param Wrapper.Group#GROUP Group (Player) Group done the VID
  -- @param #AWACS.ManagedContact Contact The contact that was VID'd 
  
  return self
end

-- TODO Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [User] Set the tactical information option, create 10 radio channels groups can subscribe and get Bogey Dope on a specific frequency automatically. You **need** to set up SRS first before using this!
-- @param #AWACS self
-- @param #number BaseFreq Base Frequency to use, defaults to 130.
-- @param #number Increase Increase to use, defaults to 0.5, thus channels created are 130, 130.5, 131 .. etc.
-- @param #number Modulation Modulation to use, defaults to radio.modulation.AM.
-- @param #number Interval Seconds between each update call.
-- @param #number Number Number of Frequencies to create, can be 1..10.
-- @return #AWACS self
function AWACS:SetTacticalRadios(BaseFreq,Increase,Modulation,Interval,Number)
  self:T(self.lid.."SetTacticalRadios")
  if not self.AwacsSRS then
    MESSAGE:New("AWACS: Setup SRS in your code BEFORE trying to add tac radios please!",30,"ERROR",true):ToLog():ToAll()
    return self
  end
  self.TacticalMenu = true
  self.TacticalBaseFreq = BaseFreq or 130
  self.TacticalIncrFreq = Increase or 0.5
  self.TacticalModulation = Modulation or radio.modulation.AM
  self.TacticalInterval = Interval or 120
  local number = Number or 10
  if number < 1 then number = 1 end
  if number > 10 then number = 10 end
  for i=1,number do
    local freq = self.TacticalBaseFreq + ((i-1)*self.TacticalIncrFreq)
    self.TacticalFrequencies[freq] = freq
  end
  if self.AwacsSRS then
    self.TacticalSRS = MSRS:New(self.PathToSRS,self.TacticalBaseFreq,self.TacticalModulation,self.Backend)
    self.TacticalSRS:SetCoalition(self.coalition)
    self.TacticalSRS:SetGender(self.Gender)
    self.TacticalSRS:SetCulture(self.Culture)
    self.TacticalSRS:SetVoice(self.Voice)
    self.TacticalSRS:SetPort(self.Port)
    self.TacticalSRS:SetLabel("AWACS")
    self.TacticalSRS:SetVolume(self.Volume)
    if self.PathToGoogleKey then
      --self.TacticalSRS:SetGoogle(self.PathToGoogleKey)
      self.TacticalSRS:SetProviderOptionsGoogle(self.PathToGoogleKey,self.AccessKey)
      self.TacticalSRS:SetProvider(MSRS.Provider.GOOGLE)
    end
    self.TacticalSRSQ = MSRSQUEUE:New("Tactical AWACS")
  end
  return self
end

--- TODO
-- [Internal] _RefreshMenuNonSubscribed
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_RefreshMenuNonSubscribed()
  self:T(self.lid.."_RefreshMenuNonSubscribed")
  local aliveset = self.clientset:GetAliveSet()
  
  for _,_group in pairs(aliveset) do
    -- go through set and re-build the sub-menu
    local grp = _group -- Wrapper.Client#CLIENT
    local Group = grp:GetGroup()
    local gname = nil
    if Group and Group:IsAlive() then
      gname = Group:GetName()
      self:T(gname)
    end
    local menustr = self.clientmenus:ReadByID(gname)
    local menu = menustr.tactical -- Core.Menu#MENU_GROUP
    if not self.TacticalSubscribers[gname] and menu then
      menu:RemoveSubMenus()
      for _,_freq in UTILS.spairs(self.TacticalFrequencies) do
        local modu = UTILS.GetModulationName(self.TacticalModulation)
        local text = string.format("Subscribe to %.3f %s",_freq,modu)
        local entry = MENU_GROUP_COMMAND:New(Group,text,menu,self._SubScribeTactRadio,self,Group,_freq) 
      end
    end
  end
  return self
end

--- [Internal] _UnsubScribeTactRadio
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group
-- @return #AWACS self
function AWACS:_UnsubScribeTactRadio(Group)
  self:T(self.lid.."_UnsubScribeTactRadio")
  local text = ""
  local textScreen = ""
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local gcallsign = self:_GetCallSign(Group,GID) or "Ghost 1"
  local gname = Group:GetName() or "unknown"
    
  if Outcome and self.TacticalSubscribers[gname] then
    -- Pilot is checked in
    local Freq = self.TacticalSubscribers[gname]
    self.TacticalFrequencies[Freq] = Freq
    self.TacticalSubscribers[gname] = nil
    local modu = self.TacticalModulation == 0 and "AM" or "FM"
    text = string.format("%s, %s, switch back to AWACS main frequency!",gcallsign,self.callsigntxt)
    self:_NewRadioEntry(text,text,GID,true,true,true,false,true)
    self:_RefreshMenuNonSubscribed()
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] _SubScribeTactRadio
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group
-- @param #number Frequency
-- @return #AWACS self
function AWACS:_SubScribeTactRadio(Group,Frequency)
  self:T(self.lid.."_SubScribeTactRadio")
  local text = ""
  local textScreen = ""
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local gcallsign = self:_GetCallSign(Group,GID) or "Ghost 1"
  local gname = Group:GetName() or "unknown"
    
  if Outcome then
    -- Pilot is checked in
    self.TacticalSubscribers[gname] = Frequency
    self.TacticalFrequencies[Frequency] = nil
    local modu = self.TacticalModulation == 0 and "AM" or "FM"
    text = string.format("%s, %s, switch to %.3f %s for tactical information!",gcallsign,self.callsigntxt,Frequency,modu)
    self:_NewRadioEntry(text,text,GID,true,true,true,false,true)
    local menustr = self.clientmenus:ReadByID(gname)
    local menu = menustr.tactical -- Core.Menu#MENU_GROUP
    if menu then
      menu:RemoveSubMenus()
      local text = string.format("Unsubscribe %.3f %s",Frequency,modu)
      local entry = MENU_GROUP_COMMAND:New(Group,text,menu,self._UnsubScribeTactRadio,self,Group)
    end 
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  
  return self
end

--- [Internal] _CheckSubscribers
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CheckSubscribers()
   self:T(self.lid.."_InitLocalization")
   
   for _name,_freq in pairs(self.TacticalSubscribers or {}) do
    local grp = GROUP:FindByName(_name)
    if (not grp) or (not grp:IsAlive()) then
      self.TacticalFrequencies[_freq] = _freq
      self.TacticalSubscribers[_name] = nil
    end
   end
   
   return self
end

--- [Internal] Init localization
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_InitLocalization()
  self:T(self.lid.."_InitLocalization")
  self.gettext = TEXTANDSOUND:New("AWACS","en") -- Core.TextAndSound#TEXTANDSOUND
  self.locale = "en"
  for locale,table in pairs(self.Messages) do
    local Locale = string.lower(tostring(locale))
    self:T("**** Adding locale: "..Locale)
    for ID,Text in pairs(table) do
      self:T(string.format('Adding ID %s',tostring(ID)))
      self.gettext:AddEntry(Locale,tostring(ID),Text)
    end
  end
  return self
end

--- [User] Set locale for localization. Defaults to "en"
-- @param #AWACS self
-- @param #string Locale The locale to use
-- @return #AWACS self
function AWACS:SetLocale(Locale)
  self:T(self.lid.."SetLocale")
  self.locale = Locale or "en"
  return self
end

--- [User] Set own coordinate for BullsEye.
-- @param #AWACS self
-- @param Core.Point#COORDINATE
-- @return #AWACS self
function AWACS:SetBullsCoordinate(Coordinate)
  self:T(self.lid.."SetBullsCoordinate")
  self.AOCoordinate = Coordinate
  return self
end

--- [User] Set the max mission range flights can be away from their home base.
-- @param #AWACS self
-- @param #number NM Distance in nautical miles
-- @return #AWACS self
function AWACS:SetMaxMissionRange(NM)
  self.MaxMissionRange = NM or 125
  return self
end

--- [User] Add additional frequency and modulation for AWACS SRS output.
-- @param #AWACS self
-- @param #number Frequency The frequency to add, e.g. 132.5
-- @param #number Modulation The modulation to add for the frequency, e.g. radio.modulation.AM
-- @return #AWACS self
function AWACS:AddFrequencyAndModulation(Frequency,Modulation)
  self:T(self.lid.."AddFrequencyAndModulation")
  table.insert(self.MultiFrequency,Frequency)
  table.insert(self.MultiModulation,Modulation)
  if self.AwacsSRS then
    self.AwacsSRS:SetFrequencies(self.MultiFrequency)
    self.AwacsSRS:SetModulations(self.MultiModulation)
  end
  return self
end

--- [User] Set this instance to act as GCI TACS Theater Air Control System
-- @param #AWACS self
-- @param Wrapper.Group#GROUP EWR The **main** Early Warning Radar (EWR) GROUP object for GCI.
-- @param #number Delay (option) Start after this many seconds (optional).
-- @return #AWACS self
function AWACS:SetAsGCI(EWR,Delay)
  self:T(self.lid.."SetGCI")
  local delay = Delay or -5
  if type(EWR) == "string" then
    self.GCIGroup = GROUP:FindByName(EWR)
  else
    self.GCIGroup = EWR
  end
  self.GCI = true
  self:SetEscort(0)
  return self
end

--- [Internal] Create a AIC-TTS message entry
-- @param #AWACS self
-- @param #string TextTTS Text to speak
-- @param #string TextScreen Text for screen
-- @param #number GID Group ID #AWACS.ManagedGroup GID
-- @param #boolean IsGroup Has a group
-- @param #boolean ToScreen Show on screen
-- @param #boolean IsNew New
-- @param #boolean FromAI From AI
-- @param #boolean IsPrio Priority entry
-- @param #boolean Tactical Is for tactical info
-- @return #AWACS self
function AWACS:_NewRadioEntry(TextTTS, TextScreen,GID,IsGroup,ToScreen,IsNew,FromAI,IsPrio,Tactical)
  self:T(self.lid.."_NewRadioEntry")
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = IsNew
  RadioEntry.TextTTS = TextTTS
  RadioEntry.TextScreen = TextScreen or TextTTS
  RadioEntry.GroupID = GID
  RadioEntry.ToScreen = ToScreen 
  RadioEntry.Duration = MSRS.getSpeechTime(TextTTS,0.95,false) or 8
  RadioEntry.FromAI = FromAI
  RadioEntry.IsGroup = IsGroup
  if Tactical then
    self.TacticalQueue:Push(RadioEntry)
  elseif IsPrio then
    self.PrioRadioQueue:Push(RadioEntry)
  else
    self.RadioQueue:Push(RadioEntry)
  end
  return self
end

--- [User] Change the bulls eye alias for AWACS callout. Defaults to "Rock"
-- @param #AWACS self
-- @param #string Name
-- @return #AWACS self
function AWACS:SetBullsEyeAlias(Name)
  self:T(self.lid.."_SetBullsEyeAlias")
  self.AOName = Name or "Rock"
  return self
end

--- [User] Set TOS Time-on-Station in Hours
-- @param #AWACS self
-- @param #number AICHours AWACS stays this number of hours on station before shift change, default is 4.
-- @param #number CapHours (optional) CAP stays this number of hours on station before shift change, default is 4.
-- @return #AWACS self
function AWACS:SetTOS(AICHours,CapHours)
  self:T(self.lid.."SetTOS")
  self.AwacsTimeOnStation = AICHours or 4
  self.CAPTimeOnStation = CapHours or 4
  return self
end

--- [User] Change number of seconds AWACS waits until a Player is re-assigned a different task. Defaults to 180.
-- @param #AWACS self
-- @param #number Seconds
-- @return #AWACS self
function AWACS:SetReassignmentPause(Seconds)
  self.ReassignmentPause = Seconds or 180
  return self
end

--- [User] Do not show messages on screen
-- @param #AWACS self
-- @param #boolean Switch If true, no messages will be shown on screen.
-- @return #AWACS self
function AWACS:SuppressScreenMessages(Switch)
  self:T(self.lid.."_SetBullsEyeAlias")
  self.SuppressScreenOutput = Switch or false
  return self
end

--- [User] Do not show messages on screen, no extra calls for player guidance, use short callsigns etc.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:ZipLip()
  self:T(self.lid.."ZipLip")
  self:SuppressScreenMessages(true)
  self.PlayerGuidance = false
  self.callsignshort = true
  --self.NoGroupTags = true
  self.NoMissileCalls = true
  return self
end

--- [User] For CAP flights: Replace ME callsigns with user-defined callsigns for use with TTS and on-screen messaging
-- @param #AWACS self
-- @param #table translationTable with DCS callsigns as keys and replacements as values
-- @return #AWACS self
-- @usage
--            -- Set Custom CAP Flight Callsigns for use with TTS
--            testawacs:SetCustomCallsigns({
--              Devil = 'Bengal',
--              Snake = 'Winder',
--              Colt = 'Camelot',
--              Enfield = 'Victory',
--              Uzi = 'Evil Eye'
--            })
function AWACS:SetCustomCallsigns(translationTable) 
  self.callsignTranslations = translationTable
end

--- [Internal] Event handler
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group, can also be passed as #string group name
-- @return #boolean found
-- @return #number GID
-- @return #string CallSign
function AWACS:_GetGIDFromGroupOrName(Group)
  self:T(self.lid.."_GetGIDFromGroupOrName")
  self:T({Group})
  local GID = 0
  local Outcome = false
  local CallSign = "Ghost 1"
  local nametocheck = CallSign
  if Group and type(Group) == "string" then
    nametocheck = Group
  elseif Group and Group:IsInstanceOf("GROUP") then
    nametocheck = Group:GetName()
  else
    return false, 0, CallSign
  end

  local managedgrps = self.ManagedGrps or {}
  for _,_managed in pairs (managedgrps) do
    local managed = _managed -- #AWACS.ManagedGroup
    if managed.GroupName == nametocheck then
      GID = managed.GID
      Outcome = true
      CallSign = managed.CallSign
    end
  end
  self:T({Outcome, GID, CallSign})
  return Outcome, GID, CallSign
end

--- [Internal] Event handler
-- @param #AWACS self
-- @param Core.Event#EVENTDATA EventData
-- @return #AWACS self
function AWACS:_EventHandler(EventData)
  self:T(self.lid.."_EventHandler")
  self:T({Event = EventData.id})
  
  local Event = EventData -- Core.Event#EVENTDATA
  
  if Event.id == EVENTS.PlayerEnterAircraft or Event.id == EVENTS.PlayerEnterUnit then --player entered unit
    --self:T("Player enter unit: " .. Event.IniPlayerName)
    --self:T("Coalition = " .. UTILS.GetCoalitionName(Event.IniCoalition))
    if Event.IniCoalition == self.coalition then
      self:_SetClientMenus()
    end
  end
  
  if Event.id == EVENTS.PlayerLeaveUnit and Event.IniGroupName then --player left unit
    -- check known player?
    self:T("Player group left  unit: " .. Event.IniGroupName)
    self:T("Player name left: " .. Event.IniPlayerName)
    self:T("Coalition = " .. UTILS.GetCoalitionName(Event.IniCoalition))
    if Event.IniCoalition == self.coalition then
      local Outcome, GID, CallSign = self:_GetGIDFromGroupOrName(Event.IniGroupName)
      if Outcome and GID > 0 then
        self:T("Task Abort and Checkout Called")
        self:_TaskAbort(Event.IniGroupName)
        self:_CheckOut(nil,GID,true)
      end
    end
  end
  
  if Event.id == EVENTS.Ejection or Event.id == EVENTS.Crash or Event.id == EVENTS.Dead or Event.id == EVENTS.PilotDead then --unit or player dead
    -- check known group?
    if Event.IniCoalition == self.coalition then
      --self:T("Ejection/Crash/Dead/PilotDead Group: " .. Event.IniGroupName)
      --self:T("Coalition = " .. UTILS.GetCoalitionName(Event.IniCoalition))
      local Outcome, GID, CallSign = self:_GetGIDFromGroupOrName(Event.IniGroupName)
      if Outcome and GID > 0 then
        self:_TaskAbort(Event.IniGroupName)
        self:_CheckOut(nil,GID,true)
      end
    end
  end
  
  if Event.id == EVENTS.Shot and self.PlayerGuidance and not self.NoMissileCalls then
    if Event.IniCoalition ~= self.coalition then
      self:T("Shot from: " .. Event.IniGroupName)
      
      local position = Event.IniGroup:GetCoordinate()
      if not position then return self end
      
      -- Check missile type
      local Category = Event.WeaponCategory
      local WeaponDesc = EventData.Weapon:getDesc() -- https://wiki.hoggitworld.com/view/DCS_enum_weapon
      self:T({WeaponDesc})
      
      if WeaponDesc.category == 1 and (WeaponDesc.missileCategory == 1 or WeaponDesc.missileCategory == 2) then
        self:T("AAM or SAM Missile fired")
        -- Missile fired
        -- WIP Missile Callouts
        local warndist = 25
        local Type = "SAM"
        if WeaponDesc.category == 1 then
          Type = "Missile"
          -- AAM  
          local guidance = WeaponDesc.guidance or 4 -- IR=2, Radar Active=3, Radar Semi Active=4, Radar Passive = 5
          if guidance == 2 then
            warndist = 10
          elseif guidance == 3 then
            warndist = 25
          elseif guidance == 4 then
            warndist = 15
          elseif guidance == 5 then
            warndist = 10
          end -- guidance
        end -- cat 1
        self:_MissileWarning(position,Type,warndist)
      end -- cat 1 or 2
      
    end -- end coalition
  end -- end shot
  
  return self
end

--- [Internal] Missile Warning Callout
-- @param #AWACS self
-- @param Core.Point#COORDINATE Coordinate Where the shot happened
-- @param #string Type Type to call out, e.i. "SAM" or "Missile"
-- @param #number Warndist Distance in NM to find friendly planes
-- @return #AWACS self
function AWACS:_MissileWarning(Coordinate,Type,Warndist)
  self:T(self.lid.."_MissileWarning Type="..Type.." WarnDist="..Warndist)
  
  if not Coordinate then return self end
  local shotzone = ZONE_RADIUS:New("WarningZone",Coordinate:GetVec2(),UTILS.NMToMeters(Warndist))
  local targetgrpset = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterCategoryAirplane():FilterActive():FilterZones({shotzone}):FilterOnce()
  if targetgrpset:Count() > 0 then
    local targets = targetgrpset:GetSetObjects()
    for _,_grp in pairs (targets) do
      -- DONE -- player callouts only
      if _grp and _grp:IsAlive() then
        local isPlayer = _grp:IsPlayer()
        
        if isPlayer then
          local callsign = self:_GetCallSign(_grp)
          local defend = self.gettext:GetEntry("DEFEND",self.locale)
          --local text = string.format("%s, %s! %s! %s! Defend!",callsign,Type,Type,Type)
          local text = string.format(defend,callsign,Type,Type,Type)
          self:_NewRadioEntry(text, text,0,false,self.debug,true,false,true)
        end
      end
    end
  end
  return self
end

--- [User] Set AWACS Radar Blur - the radar contact count per group/cluster will be distored up or down by this number percent. Defaults to 15 in Modern Era and 25 in Cold War.
-- @param #AWACS self
-- @param #number Percent
-- @return #AWACS self
function AWACS:SetRadarBlur(Percent)
  local percent = Percent or 15
  if percent < 0  then percent = 0 end
  if percent > 100 then percent = 100 end
  self.RadarBlur = Percent
  return self
end

--- [User] Set AWACS to Cold War standards - ROE to VID, ROT to Passive (bypass and escape). Radar blur 25%.
-- Sets TAC/Meld/Threat call distances to 35, 25 and 15 nm.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:SetColdWar()
  self.ModernEra = false
  self.AwacsROT = AWACS.ROT.PASSIVE
  self.AwacsROE = AWACS.ROE.VID
  self.RadarBlur = 25
  self:SetInterceptTimeline(35, 25, 15)
  return self
end

--- [User] Set AWACS to Modern Era standards - ROE to BVR, ROT to defensive (evade fire). Radar blur 15%.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:SetModernEra()
  self.ModernEra = true
  self.AwacsROT = AWACS.ROT.EVADE
  self.AwacsROE = AWACS.ROE.BVR
  self.RadarBlur = 15
  return self
end

--- [User] Set AWACS to Modern Era standards - ROE to IFF, ROT to defensive (evade fire). Radar blur 15%.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:SetModernEraDefensive()
  self.ModernEra = true
  self.AwacsROT = AWACS.ROT.EVADE
  self.AwacsROE = AWACS.ROE.IFF
  self.RadarBlur = 15
  return self
end

--- [User] Set AWACS to Modern Era standards - ROE to BVR, ROT to return fire. Radar blur 15%.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:SetModernEraAggressive()
  self.ModernEra = true
  self.AwacsROT = AWACS.ROT.RETURNFIRE
  self.AwacsROE = AWACS.ROE.BVR
  self.RadarBlur = 15
  return self
end

--- [User] Set AWACS to Policing standards - ROE to VID, ROT to Lock (bypass and escape). Radar blur 15%.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:SetPolicingModern()
  self.ModernEra = true
  self.AwacsROT = AWACS.ROT.BYPASSESCAPE
  self.AwacsROE = AWACS.ROE.VID
  self.RadarBlur = 15
  return self
end

--- [User] Set AWACS to Policing standards - ROE to VID, ROT to Lock (bypass and escape). Radar blur 25%.
-- Sets TAC/Meld/Threat call distances to 35, 25 and 15 nm.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:SetPolicingColdWar()
  self.ModernEra = false
  self.AwacsROT = AWACS.ROT.BYPASSESCAPE
  self.AwacsROE = AWACS.ROE.VID
  self.RadarBlur = 25
  self:SetInterceptTimeline(35, 25, 15)
  return self
end

--- [User] Set AWACS Player Guidance - influences missile callout and the "New" label in group callouts. 
-- @param #AWACS self
-- @param #boolean Switch If true (default) it is on, if false, it is off.
-- @return #AWACS self
function AWACS:SetPlayerGuidance(Switch)
  if (Switch == nil) or (Switch == true) then
   self.PlayerGuidance = true
  else
    self.PlayerGuidance = false
  end
  return self
end

--- [User] Get AWACS Name
-- @param #AWACS self
-- @return #string Name of this instance
function AWACS:GetName()
  return self.Name or "not set"
end

--- [User] Set AWACS intercept timeline support distance.
-- @param #AWACS self
-- @param #number TacDistance Distance for TAC call, default 45nm
-- @param #number MeldDistance Distance for Meld call, default 35nm
-- @param #number ThreatDistance Distance for Threat call, default 25nm
-- @return #AWACS self
function AWACS:SetInterceptTimeline(TacDistance, MeldDistance, ThreatDistance)
  self.TacDistance = TacDistance or 45
  self.MeldDistance = MeldDistance or 35
  self.ThreatDistance = ThreatDistance or 25
  return self
end

--- [User] Set additional defensive zone, e.g. the zone behind the FEZ to also be defended
-- @param #AWACS self
-- @param Core.Zone#ZONE Zone
-- @param #boolean Draw Draw lines around this zone if true
-- @return #AWACS self
function AWACS:SetAdditionalZone(Zone, Draw)
  self:T(self.lid.."SetAdditionalZone")
  self.BorderZone = Zone
  if self.debug then
    Zone:DrawZone(self.coalition,{1,0.64,0},1,{1,0.64,0},0.2,1,true)
    if self.AllowMarkers then
      MARKER:New(Zone:GetCoordinate(),"Defensive Zone"):ToCoalition(self.coalition)
    end
  elseif Draw then
    Zone:DrawZone(self.coalition,{1,0.64,0},1,{1,0.64,0},0.2,1,true)
  end
  return self
end

--- [User] Set rejection zone, e.g. a border of a foreign country. Detected bogeys in here won't be engaged.
-- @param #AWACS self
-- @param Core.Zone#ZONE Zone
-- @param #boolean Draw Draw lines around this zone if true
-- @return #AWACS self
function AWACS:SetRejectionZone(Zone,Draw)
  self:T(self.lid.."SetRejectionZone")
  self.RejectZone = Zone
  if Draw then
    Zone:DrawZone(self.coalition,{1,0.64,0},1,{1,0.64,0},0.2,1,true)
    --MARKER:New(Zone:GetCoordinate(),"Rejection Zone"):ToAll()
  elseif self.debug then
    Zone:DrawZone(self.coalition,{1,0.64,0},1,{1,0.64,0},0.2,1,true)
    if self.AllowMarkers then
      MARKER:New(Zone:GetCoordinate(),"Rejection Zone"):ToCoalition(self.coalition)
    end
  end
  return self
end

--- Function to set corridor zones.
-- @param #AWACS self
-- @param Core.Set#SET_ZONE CorridorZones Can be handed in as SET\_ZONE or single ZONE object.
-- @return #AWACS self
function AWACS:SetCorridorZones(CorridorZones)
  self:T(self.lid .. "SetCorridorZones")
  if CorridorZones and CorridorZones:IsInstanceOf("SET_ZONE") then
    self.corridorzones = CorridorZones
    self.usecorridors = true
  elseif CorridorZones and CorridorZones:IsInstanceOf("ZONE_BASE") then
    if not self.corridorzones then self.corridorzones = SET_ZONE:New() end
    self.corridorzones:AddZone(CorridorZones)
    self.usecorridors = true
  end
  return self
end

--- Function to add one corridor zone.
-- @param #AWACS self
-- @param Core.Zone#ZONE CorridorZone The ZONE object to be added.
-- @return #AWACS self
function AWACS:AddCorridorZone(CorridorZone)
  self:T(self.lid .. "AddCorridorZone")
  self:SetCorridorZones(CorridorZone)
  return self
end

--- Function to set corridor zone floor and ceiling in FEET.
-- @param #AWACS self
-- @param #number Floor Floor altitude ASL in feet.
-- @param #number Ceiling Ceiling altitude ASL in feet.
-- @return #AWACS self
function AWACS:SetCorridorZoneFloorAndCeiling(Floor,Ceiling)
  self.corridorfloor = UTILS.FeetToMeters(Floor)
  self.corridorceiling = UTILS.FeetToMeters(Ceiling)
  return self
end

--- Function to set corridor zone floor and ceiling in METERS.
-- @param #AWACS self
-- @param #number Floor Floor altitude ASL in meters.
-- @param #number Ceiling Ceiling altitude ASL in meters.
-- @return #AWACS self
function AWACS:SetCorridorZoneFloorAndCeilingMeters(Floor,Ceiling)
  self.corridorfloor = Floor    
  self.corridorceiling = Ceiling
  return self
end

--- [User] Draw a line around the FEZ on the F10 map.
-- @param #AWACS self
-- @return #AWACS self
function AWACS:DrawFEZ()
  self.OpsZone:DrawZone(self.coalition,{1,0,0},1,{1,0,0},0.2,5,true)
  return self
end

--- [User] Set AWACS flight details
-- @param #AWACS self
-- @param #number CallSign Defaults to CALLSIGN.AWACS.Magic
-- @param #number CallSignNo Defaults to 1
-- @param #number Angels Defaults to 25 (i.e. 25000 ft)
-- @param #number Speed Defaults to 250kn
-- @param #number Heading Defaults to 0 (North)
-- @param #number Leg Defaults to 25nm
-- @return #AWACS self
function AWACS:SetAwacsDetails(CallSign,CallSignNo,Angels,Speed,Heading,Leg)
  self:T(self.lid.."SetAwacsDetails")
  self.CallSign = CallSign or CALLSIGN.AWACS.Magic
  self.CallSignNo = CallSignNo or 1
  self.AwacsAngels = Angels or 25
  local speed = Speed or 250
  self.SpeedBase = speed
  --self.Speed = UTILS.KnotsToAltKIAS(speed,self.AwacsAngels*1000)
  self.Speed = speed
  self.Heading = Heading or 0
  self.Leg = Leg or 25
  return self
end

--- [User] Set AWACS custom callsigns for TTS
-- @param #AWACS self
-- @param #table CallsignTable Table of custom callsigns to use with TTS
-- @return #AWACS self
-- @usage
-- You can overwrite the standard AWACS callsign for TTS usage with your own naming, e.g. like so:
--              testawacs:SetCustomAWACSCallSign({
--                [1]="Overlord", -- Overlord
--                [2]="Bookshelf", -- Magic
--                [3]="Wizard", -- Wizard
--                [4]="Focus", -- Focus
--                [5]="Darkstar", -- Darkstar
--                })
-- The default callsign used in AWACS is "Magic". With the above change, the AWACS will call itself "Bookshelf" over TTS instead.
function AWACS:SetCustomAWACSCallSign(CallsignTable)
  self:T(self.lid.."SetCustomAWACSCallSign")
  self.CallSignClear = CallsignTable
  return self
end

--- [User] Add a radar GROUP object to the INTEL detection SET_GROUP
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group The GROUP to be added. Can be passed as SET_GROUP.
-- @return #AWACS self
function AWACS:AddGroupToDetection(Group)
  self:T(self.lid.."AddGroupToDetection")
  if Group and Group.ClassName and Group.ClassName == "GROUP" then
    self.DetectionSet:AddGroup(Group)
  elseif Group and Group.ClassName and Group.ClassName == "SET_GROUP" then
    self.DetectionSet:AddSet(Group)
  end
  return self
end

--- [User] Set AWACS SRS TTS details - see @{Sound.SRS} for details. `SetSRS()` will try to use as many attributes configured with @{Sound.SRS#MSRS.LoadConfigFile}() as possible.
-- @param #AWACS self
-- @param #string PathToSRS Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
-- @param #string Gender Defaults to "male"
-- @param #string Culture Defaults to "en-US"
-- @param #number Port Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{Sound.SRS#SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @param #number Volume Volume - between 0.0 (silent) and 1.0 (loudest)
-- @param #string PathToGoogleKey (Optional) Path to your google key if you want to use google TTS; if you use a config file for MSRS, hand in nil here.
-- @param #string AccessKey (Optional) Your Google API access key. This is necessary if DCS-gRPC is used as backend; if you use a config file for MSRS, hand in nil here.
-- @param #string Backend (Optional) Your MSRS Backend if different from your config file settings, e.g. MSRS.Backend.SRSEXE or MSRS.Backend.GRPC
-- @return #AWACS self
function AWACS:SetSRS(PathToSRS,Gender,Culture,Port,Voice,Volume,PathToGoogleKey,AccessKey,Backend)
  self:T(self.lid.."SetSRS")
  self.PathToSRS = PathToSRS or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio" 
  self.Gender = Gender or MSRS.gender or "male"
  self.Culture = Culture or MSRS.culture or "en-US"
  self.Port = Port or MSRS.port or 5002
  self.Voice = Voice or MSRS.voice
  self.PathToGoogleKey = PathToGoogleKey
  self.AccessKey = AccessKey
  self.Volume = Volume or 1.0
  self.Backend = Backend or MSRS.backend
  BASE:I({backend = self.Backend})
  self.AwacsSRS = MSRS:New(self.PathToSRS,self.MultiFrequency,self.MultiModulation,self.Backend)
  self.AwacsSRS:SetCoalition(self.coalition)
  self.AwacsSRS:SetGender(self.Gender)
  self.AwacsSRS:SetCulture(self.Culture)
  self.AwacsSRS:SetPort(self.Port)
  self.AwacsSRS:SetLabel("AWACS")
  self.AwacsSRS:SetVolume(Volume)
  if self.PathToGoogleKey then
    --self.AwacsSRS:SetGoogle(self.PathToGoogleKey)
    self.AwacsSRS:SetProviderOptionsGoogle(self.PathToGoogleKey,self.AccessKey)
    self.AwacsSRS:SetProvider(MSRS.Provider.GOOGLE)
  end
   -- Pre-configured Google?
  if (not PathToGoogleKey) and self.AwacsSRS:GetProvider() == MSRS.Provider.GOOGLE then
    self.PathToGoogleKey = MSRS.poptions.gcloud.credentials
    self.Voice = Voice or MSRS.poptions.gcloud.voice
    self.AccessKey = AccessKey or MSRS.poptions.gcloud.key
  end
  self.AwacsSRS:SetVoice(self.Voice)
  return self
end

--- [User] Set AWACS Voice Details for AI CAP Planes  - SRS TTS - see @{Sound.SRS} for details
-- @param #AWACS self
-- @param #string Gender Defaults to "male"
-- @param #string Culture Defaults to "en-US"
-- @param #string Voice (Optional) Use a specifc voice with the @{#MSRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @return #AWACS self
function AWACS:SetSRSVoiceCAP(Gender, Culture, Voice)
  self:T(self.lid.."SetSRSVoiceCAP")
  self.CAPGender = Gender or "male"
  self.CAPCulture = Culture or "en-US"
  self.CAPVoice = Voice or "en-GB-Standard-B"
  return self
end

--- [User] Set AI CAP Plane Details
-- @param #AWACS self
-- @param #number Callsign Callsign name of AI CAP, e.g. CALLSIGN.Aircraft.Dodge. Defaults to CALLSIGN.Aircraft.Colt. Note that not all available callsigns work for all plane types.
-- @param #number MaxAICap Maximum number of AI CAP planes on station that AWACS will set up automatically. Default to 4.
-- @param #number TOS Time on station, in  hours. AI planes might go back to base earlier if they run out of fuel or missiles.
-- @param #number Speed Airspeed to be used in knots. Will be adjusted to flight height automatically. Defaults to 270.
-- @return #AWACS self
function AWACS:SetAICAPDetails(Callsign,MaxAICap,TOS,Speed)
  self:T(self.lid.."SetAICAPDetails")
  self.CapSpeedBase = Speed or 270
  self.CAPTimeOnStation = TOS or 4
  self.MaxAIonCAP = MaxAICap or 4
  self.AICAPCAllName = Callsign or CALLSIGN.Aircraft.Colt
  return self
end

--- [User] Set AWACS Escorts Template
-- @param #AWACS self
-- @param #number EscortNumber Number of fighther plane GROUPs to accompany this AWACS. 0 or nil means no escorts. If you want >1 plane in an escort group, you can either set the respective squadron grouping to the desired number, or use a template for escorts with >1 unit.
-- @param #number Formation Formation the escort should take (if more than one plane), e.g. `ENUMS.Formation.FixedWing.FingerFour.Group`. Formation is used on GROUP level, multiple groups of one unit will NOT conform to this formation.
-- @param #table OffsetVector Offset the escorts should fly behind the AWACS, given as table, distance in meters, e.g. `{x=-500,y=0,z=500}` - 500m behind (negative value) and to the right (negative for left), no vertical separation (positive over, negative under the AWACS flight). For multiple groups, the vectors will be slightly changed to avoid collisions.
-- @param #number EscortEngageMaxDistance Escorts engage air targets max this NM away, defaults to 45NM.
-- @return #AWACS self
function AWACS:SetEscort(EscortNumber,Formation,OffsetVector,EscortEngageMaxDistance)
  self:T(self.lid.."SetEscort")
  if EscortNumber and EscortNumber > 0 then
    self.HasEscorts = true
    self.EscortNumber = EscortNumber
  else
    self.HasEscorts = false
    self.EscortNumber = 0
  end
  self.EscortFormation = Formation
  self.OffsetVec = OffsetVector or {x=500,y=100,z=500}
  self.EscortEngageMaxDistance = EscortEngageMaxDistance or 45
  return self
end

--- [Internal] Message a vector BR to a position
-- @param #AWACS self
-- @param #number GID Group GID
-- @param #string Tag (optional) Text to add after Vector, e.g. " to Anchor" - NOTE the leading space
-- @param Core.Point#COORDINATE Coordinate The Coordinate to use
-- @param #number Angels (Optional) Add Angels 
-- @return #AWACS self
function AWACS:_MessageVector(GID,Tag,Coordinate,Angels)
  self:T(self.lid.."_MessageVector")
  
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local Tag = Tag or ""
  
  if managedgroup and Coordinate then
    
    local tocallsign = managedgroup.CallSign or "Ghost 1"
    local group = managedgroup.Group
    local groupposition = group:GetCoordinate()
    
    local BRtext,BRtextTTS = self:_ToStringBR(groupposition,Coordinate)
    
    local vector = self.gettext:GetEntry("VECTORTO",self.locale)
    local vectortts = self.gettext:GetEntry("VECTORTOTTS",self.locale)
    local angelstxt = self.gettext:GetEntry("ANGELS",self.locale)
    
    local text = string.format(vectortts,tocallsign, self.callsigntxt,Tag,BRtextTTS)
    local textScreen = string.format(vector,tocallsign, self.callsigntxt,Tag,BRtext)
    
    if Angels then
      text = text .. angelstxt ..tostring(Angels).."."
      textScreen = textScreen ..angelstxt..tostring(Angels).."."
    end
    
    self:_NewRadioEntry(text,textScreen,0,false,self.debug,true,false)
  
  end
  
  return self
end

--- [Internal] Start AWACS Escorts FlightGroup
-- @param #AWACS self
-- @param #boolean Shiftchange This is a shift change call
-- @return #AWACS self
function AWACS:_StartEscorts(Shiftchange)
  self:T(self.lid.."_StartEscorts")
  
  local AwacsFG = self.AwacsFG -- Ops.FlightGroup#FLIGHTGROUP
  local group = AwacsFG:GetGroup()

  local timeonstation = (self.EscortsTimeOnStation + self.ShiftChangeTime) * 3600 -- hours to seconds
  local OffsetX = 500
  local OffsetY = 500
  local OffsetZ = 500
  if self.OffsetVec then
    OffsetX = self.OffsetVec.x or 500
    OffsetY = self.OffsetVec.y or 500
    OffsetZ = self.OffsetVec.z or 500
  end
  
  for i=1,self.EscortNumber do
    -- every
    local escort = AUFTRAG:NewESCORT(group, {x= OffsetX*((i + (i%2))/2), y=OffsetY*((i + (i%2))/2), z=(OffsetZ + OffsetZ*((i + (i%2))/2))*(-1)^i},self.EscortEngageMaxDistance,{"Air"})
    --local escort = AUFTRAG:NewESCORT(group,self.OffsetVec,self.EscortEngageMaxDistance,{"Air"})
    --escort:SetRequiredAssets(self.EscortNumber)
    escort:SetTime(nil,timeonstation)
    if self.Escortformation then
      escort:SetFormation(self.Escortformation)
    end
    escort:SetMissionRange(self.MaxMissionRange)
    
    self.AirWing:AddMission(escort)
    self.CatchAllMissions[#self.CatchAllMissions+1] = escort

    if Shiftchange then
      self.EscortMissionReplacement[i] = escort
    else
      self.EscortMission[i] = escort
    end
  end
  
  return self
end

--- [Internal] AWACS further Start Settings
-- @param #AWACS self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup
-- @param Ops.Auftrag#AUFTRAG Mission
-- @return #AWACS self
function AWACS:_StartSettings(FlightGroup,Mission)
  self:T(self.lid.."_StartSettings")
  
  local Mission = Mission -- Ops.Auftrag#AUFTRAG
  local AwacsFG = FlightGroup -- Ops.FlightGroup#FLIGHTGROUP
  
  -- Is this our Awacs mission?
  if self.AwacsMission:GetName() == Mission:GetName() then
    self:T("Setting up Awacs")
    AwacsFG:SetDefaultRadio(self.Frequency,self.Modulation,false)
    AwacsFG:SwitchRadio(self.Frequency,self.Modulation)
    AwacsFG:SetDefaultAltitude(self.AwacsAngels*1000)
    AwacsFG:SetHomebase(self.Airbase)
    AwacsFG:SetDefaultCallsign(self.CallSign,self.CallSignNo)
    AwacsFG:SetDefaultROE(ENUMS.ROE.WeaponHold)
    AwacsFG:SetDefaultAlarmstate(AI.Option.Ground.val.ALARM_STATE.GREEN)
    AwacsFG:SetDefaultEPLRS(self.ModernEra)
    AwacsFG:SetDespawnAfterLanding()
    AwacsFG:SetFuelLowRTB(true)
    AwacsFG:SetFuelLowThreshold(20)
    
    local group = AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    
    group:SetCommandInvisible(self.invisible)
    group:SetCommandImmortal(self.immortal)
    group:CommandSetCallsign(self.CallSign,self.CallSignNo,2)
    group:CommandEPLRS(self.ModernEra,5)
    -- Non AWACS does not seem take AWACS CS in DCS Group

    self.AwacsFG = AwacsFG 
    
    --self.AwacsFG:SetSRS(self.PathToSRS,self.Gender,self.Culture,self.Voice,self.Port,self.PathToGoogleKey,"AWACS",self.Volume)
     
    self.callsigntxt = string.format("%s",self.CallSignClear[self.CallSign])
    
    self:__CheckRadioQueue(10)
    
    if self.HasEscorts then
      --mission:SetRequiredEscorts(self.EscortNumber)
      self:_StartEscorts()
    end
    
    self.AwacsTimeStamp = timer.getTime()
    self.EscortsTimeStamp = timer.getTime()

    self.PictureTimeStamp = timer.getTime() + 10*60
    
    self.AwacsReady = true
    -- set FSM to started
    self:Started()
    
  elseif self.ShiftChangeAwacsRequested and self.AwacsMissionReplacement and self.AwacsMissionReplacement:GetName() == Mission:GetName() then
    self:T("Setting up Awacs Replacement")
    -- manage AWACS Replacement
    AwacsFG:SetDefaultRadio(self.Frequency,self.Modulation,false)
    AwacsFG:SwitchRadio(self.Frequency,self.Modulation)
    AwacsFG:SetDefaultAltitude(self.AwacsAngels*1000)
    AwacsFG:SetHomebase(self.Airbase)
    self.CallSignNo = self.CallSignNo+1
    AwacsFG:SetDefaultCallsign(self.CallSign,self.CallSignNo)
    AwacsFG:SetDefaultROE(ENUMS.ROE.WeaponHold)
    AwacsFG:SetDefaultAlarmstate(AI.Option.Ground.val.ALARM_STATE.GREEN)
    AwacsFG:SetDefaultEPLRS(self.ModernEra)
    AwacsFG:SetDespawnAfterLanding()
    AwacsFG:SetFuelLowRTB(true)
    AwacsFG:SetFuelLowThreshold(20)
    
    local group = AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    
    group:SetCommandInvisible(self.invisible)
    group:SetCommandImmortal(self.immortal)
    group:CommandSetCallsign(self.CallSign,self.CallSignNo,2)
    
    --AwacsFG:SetSRS(self.PathToSRS,self.Gender,self.Culture,self.Voice,self.Port,nil,"AWACS")

    self.callsigntxt = string.format("%s",self.CallSignClear[self.CallSign])
    
    local shifting = self.gettext:GetEntry("SHIFTCHANGE",self.locale)
    
    local text = string.format(shifting,self.callsigntxt,self.AOName or "Rock")
    
    self:T(self.lid..text)
    
    AwacsFG:RadioTransmission(text,1,false)
    
    self.AwacsFG = AwacsFG 
    
    if self.HasEscorts then
      self:_StartEscorts(true)
    end
    
    self.AwacsTimeStamp = timer.getTime()
    self.EscortsTimeStamp = timer.getTime()
    
    self.AwacsReady = true
    
  end
  return self
end

--- [Internal] Return Bullseye BR for Alpha Check etc, returns e.g. "Rock 021, 16" ("Rock" being the set BE name)
-- @param #AWACS self
-- @param Core.Point#COORDINATE Coordinate
-- @param #boolean ssml Add SSML tag
-- @param #boolean TTS For non-Alpha checks, hand back in format "Rock 0 2 1, 16"
-- @return #string BullseyeBR
function AWACS:_ToStringBULLS( Coordinate, ssml, TTS )
  self:T(self.lid.."_ToStringBULLS")
  local bullseyename = self.AOName or "Rock"
  local BullsCoordinate = self.AOCoordinate
  local DirectionVec3 = BullsCoordinate:GetDirectionVec3( Coordinate )
  local AngleRadians =  Coordinate:GetAngleRadians( DirectionVec3 )
  local Distance = Coordinate:Get2DDistance( BullsCoordinate )
  local AngleDegrees = UTILS.Round( UTILS.ToDegree( AngleRadians ), 0 )
  local Bearing = string.format( '%03d', AngleDegrees )
  local Distance = UTILS.Round( UTILS.MetersToNM( Distance ), 0 )
  if ssml then
    return string.format("%s <say-as interpret-as='characters'>%03d</say-as>, %d",bullseyename,Bearing,Distance)
  end
  if TTS then
    Bearing = self:_ToStringBullsTTS(Bearing)
    local zero = self.gettext:GetEntry("ZERO",self.locale)
    local BearingTTS = string.gsub(Bearing,"0",zero)
    return string.format("%s %s, %d",bullseyename,BearingTTS,Distance)
  else
    return string.format("%s %s, %d",bullseyename,Bearing,Distance)
  end
end

--- [Internal] Change Bullseye string to be TTS friendly,  "Bullseye 021, 16" returns e.g. "Bulls eye 0 2 1. 1 6"
-- @param #AWACS self
-- @param #string Text Input text
-- @return #string BullseyeBRTTS
function AWACS:_ToStringBullsTTS(Text)
  local text = Text
  text=string.gsub(text,"Bullseye","Bulls eye")
  text=string.gsub(text,"%d","%1 ")
  text=string.gsub(text," ," ,".")
  text=string.gsub(text," $","")
  return text
end


--- [Internal] Check if a group has checked in
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to check
-- @return #number ID
-- @return #boolean CheckedIn
-- @return #string CallSign
function AWACS:_GetManagedGrpID(Group)
  if not Group or not Group:IsAlive() then
    self:T(self.lid.."_GetManagedGrpID - Requested Group is not alive!")
    return 0,false,""
  end
  self:T(self.lid.."_GetManagedGrpID for "..Group:GetName())
  local GID = 0
  local Outcome = false
  local CallSign = "Ghost 1"
  local nametocheck = Group:GetName()
  local managedgrps = self.ManagedGrps or {}
  for _,_managed in pairs (managedgrps) do
    local managed = _managed -- #AWACS.ManagedGroup
    if managed.GroupName == nametocheck then
      GID = managed.GID
      Outcome = true
      CallSign = managed.CallSign
    end
  end
  return GID, Outcome, CallSign
end

--- [Internal] AWACS Get TTS compatible callsign
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #number GID GID to use
-- @param #boolean IsPlayer Check in player if true
-- @return #string Callsign
function AWACS:_GetCallSign(Group,GID, IsPlayer)
  self:T(self.lid.."_GetCallSign - GID "..tostring(GID))
  
  if GID and type(GID) == "number" and GID > 0 then
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    self:T("Saved Callsign for TTS = " .. tostring(managedgroup.CallSign))
    return managedgroup.CallSign
  end
  
  local callsign = "Ghost 1"
  if Group and Group:IsAlive() then
    callsign = Group:GetCustomCallSign(self.callsignshort,self.keepnumber,self.callsignTranslations,self.callsignCustomFunc,self.callsignCustomArgs)
  end  
  return callsign
end

--- [User] Set player callsign options for TTS output. See @{Wrapper.Group#GROUP.GetCustomCallSign}() on how to set customized callsigns.
-- @param #AWACS self
-- @param #boolean ShortCallsign If true, only call out the major flight number
-- @param #boolean Keepnumber If true, keep the **customized callsign** in the #GROUP name as-is, no amendments or numbers.
-- @param #table CallsignTranslations (Optional) Table to translate between DCS standard callsigns and bespoke ones. Does not apply if using customized.
-- callsigns from playername or group name.
-- @param #func CallsignCustomFunc (Optional) For player names only(!). If given, this function will return the callsign. Needs to take the groupname and the playername as first two arguments.
-- @param #arg ... (Optional) Comma separated arguments to add to the custom function call after groupname and playername.
-- @return #AWACS self
function AWACS:SetCallSignOptions(ShortCallsign,Keepnumber,CallsignTranslations,CallsignCustomFunc,...)
  if not ShortCallsign or ShortCallsign == false then
   self.callsignshort = false
  else
   self.callsignshort = true
  end
  self.keepnumber = Keepnumber or false
  self.callsignTranslations = CallsignTranslations
  self.callsignCustomFunc = CallsignCustomFunc
  self.callsignCustomArgs = arg or {}
  return self  
end

--- [Internal] Update contact from cluster data
-- @param #AWACS self
-- @param #number CID Contact ID
-- @return #AWACS self
function AWACS:_UpdateContactFromCluster(CID)
  self:T(self.lid.."_UpdateContactFromCluster CID="..CID)
  
  local existingcontact = self.Contacts:PullByID(CID) -- #AWACS.ManagedContact
  local ContactTable = existingcontact.Cluster.Contacts or {}
  
  local function GetFirstAliveContact(table)
    for _,_contact in pairs (table) do
      local contact = _contact -- Ops.Intel#INTEL.Contact
      if contact and contact.group and contact.group:IsAlive() then
        return contact
      end
    end
    return nil
  end
  
  local NewContact = GetFirstAliveContact(ContactTable)
  
  if NewContact then
    existingcontact.Contact = NewContact
    self.Contacts:Push(existingcontact,existingcontact.CID)
  end
  
  return self
end

--- [Internal] Check merges for Players
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CheckMerges()
  self:T(self.lid.."_CheckMerges") 
  for _id,_pilot in pairs (self.ManagedGrps) do
    local pilot = _pilot -- #AWACS.ManagedGroup
    if pilot.Group and pilot.Group:IsAlive() then
      local ppos = pilot.Group:GetCoordinate()
      local pcallsign = pilot.CallSign
      self:T(self.lid.."Checking for "..pcallsign)
      if ppos then
        self.Contacts:ForEach(
          function (Contact)
            local contact = Contact -- #AWACS.ManagedContact
            local cpos = contact.Cluster.coordinate or contact.Contact.position or contact.Contact.group:GetCoordinate()
            local dist = ppos:Get2DDistance(cpos)
            local distnm = UTILS.Round(UTILS.MetersToNM(dist),0)
            if (pilot.IsPlayer or self.debug) and distnm <= 5 then --and ((not contact.MergeCallDone) or (timer.getTime() - contact.MergeCallDone > 30)) then
              --local label = contact.EngagementTag or ""
              --if not contact.MergeCallDone or not string.find(label,pcallsign) then
                self:T(self.lid.."Merged")
                self:_MergedCall(_id)
                --contact.MergeCallDone = true
              --end
            end
            if (pilot.IsPlayer or self.debug) and distnm >5 and distnm <= self.ThreatDistance then 
              self:_ThreatRangeCall(_id,Contact)
            end
            if (pilot.IsPlayer or self.debug) and distnm > self.ThreatDistance and distnm <= self.MeldDistance then 
              self:_MeldRangeCall(_id,Contact)
            end
            if (pilot.IsPlayer or self.debug) and distnm > self.MeldDistance and distnm <= self.TacDistance then 
              self:_TACRangeCall(_id,Contact)
            end
          end
        )      
      end
    end
  end  
  return self
end

--- [Internal] Clean up contacts list
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CleanUpContacts()
  self:T(self.lid.."_CleanUpContacts")
  
  if self.Contacts:Count() >  0 then
    local deadcontacts = FIFO:New()   
    self.Contacts:ForEach(
      function (Contact)
        local contact = Contact -- #AWACS.ManagedContact
        if not contact.Contact.group:IsAlive() or contact.Target:IsDead() or contact.Target:IsDestroyed() or contact.Target:CountTargets() == 0 then
          deadcontacts:Push(contact,contact.CID)
          self:T("DEAD contact CID="..contact.CID)
        end
      end
    )

    -- announce VANISHED
    if deadcontacts:Count() > 0 and (not self.NoGroupTags) then
    
      self:T("DEAD count="..deadcontacts:Count())
      deadcontacts:ForEach(
      function (Contact) 
        local contact = Contact -- #AWACS.ManagedContact
          local vanished = self.gettext:GetEntry("VANISHED",self.locale)
          local vanishedtts = self.gettext:GetEntry("VANISHEDTTS",self.locale)
          local text = string.format(vanishedtts,self.callsigntxt, contact.TargetGroupNaming)
          local textScreen = string.format(vanished, self.callsigntxt, contact.TargetGroupNaming)
          self:_NewRadioEntry(text,textScreen,0,false,self.debug,true,false,true)
          self.Contacts:PullByID(contact.CID)
       -- end        
      end
      )
      
    end
    
    if self.Contacts:Count() > 0 then
      self.Contacts:ForEach(
        function (Contact)
          local contact = Contact -- #AWACS.ManagedContact 
          self:_UpdateContactFromCluster(contact.CID)
        end
        )
    end
    
    -- cleanup
    deadcontacts:Clear()
   -- aliveclusters:Clear()
    
  end
  return self
end

--- [Internal] Select pilots available for tasking, return AI and Human
-- @param #AWACS self
-- @return #table AIPilots Table of #AWACS.ManagedGroup
-- @return #table HumanPilots Table of #AWACS.ManagedGroup
function AWACS:_GetIdlePilots()
  self:T(self.lid.."_GetIdlePilots")
  local AIPilots = {}
  local HumanPilots = {}
  
  for _name,_entry in pairs (self.ManagedGrps) do
    local entry = _entry -- #AWACS.ManagedGroup
    self:T("Looking at entry "..entry.GID.." Name "..entry.GroupName)
    local managedtask = self:_ReadAssignedTaskFromGID(entry.GID) -- #AWACS.ManagedTask
    local overridetask = false
    if managedtask then
      self:T("Current task = "..(managedtask.ToDo or "Unknown"))
      if managedtask.ToDo == AWACS.TaskDescription.ANCHOR then
        overridetask = true
      end
    end
    if entry.IsAI then
      if entry.FlightGroup:IsAirborne() and ((not entry.HasAssignedTask) or overridetask) then -- must be idle, or?
        self:T("Adding AI with Callsign: "..entry.CallSign)
        AIPilots[#AIPilots+1] = _entry
      end
    elseif entry.IsPlayer and (not entry.Blocked) and (not entry.Group:IsHelicopter()) then
      if (not entry.HasAssignedTask) or overridetask then -- must be idle, or?
        -- check last assignment
        local TNow = timer.getTime()
        if entry.LastTasking and (TNow-entry.LastTasking > self.ReassignTime) then
          self:T("Adding Human with Callsign: "..entry.CallSign)
          HumanPilots[#HumanPilots+1] = _entry
        end
      end
    end
  end
  
  return AIPilots, HumanPilots

end

--- [Internal] Select max 3 targets for picture, bogey dope etc
-- @param #AWACS self
-- @param #boolean Untargeted Return not yet targeted contacts only
-- @return #boolean HaveTargets True if targets could be found, else false
-- @return Utilities.FiFo#FIFO Targetselection
function AWACS:_TargetSelectionProcess(Untargeted)
  self:T(self.lid.."_TargetSelectionProcess")
  
  local maxtargets = 3 -- handleable number of callouts
  local contactstable = self.Contacts:GetDataTable()
  local targettable = FIFO:New()
  local sortedtargets = FIFO:New()
  local prefiltered = FIFO:New() 
  local HaveTargets = false
  
  self:T(self.lid.."Initial count: "..self.Contacts:Count())
  
  -- Bucket sort
   
  if Untargeted then
    -- pre-filter
    self.Contacts:ForEach(
      function (Contact)
        local contact = Contact -- #AWACS.ManagedContact
        if contact.Contact.group:IsAlive() and (contact.Status == AWACS.TaskStatus.IDLE or contact.Status == AWACS.TaskStatus.UNASSIGNED) then
          if self.AwacsROE == AWACS.ROE.POLICE or self.AwacsROE == AWACS.ROE.VID then
            -- filter out VID'd non-hostiles
            if not (contact.IFF == AWACS.IFF.FRIENDLY or contact.IFF == AWACS.IFF.NEUTRAL) then
              prefiltered:Push(contact,contact.CID)
            end
          else
            prefiltered:Push(contact,contact.CID)
          end
        end
      end
    )
    contactstable = prefiltered:GetDataTable()
    self:T(self.lid.."Untargeted: "..prefiltered:Count())
  end
 
  -- Loop through 
  for _,_contact in pairs(contactstable) do
    local contact = _contact -- #AWACS.ManagedContact
    local checked = false
    local contactname = contact.TargetGroupNaming or "ZETA"
    local typename = contact.ReportingName or "Unknown"
    self:T(self.lid..string.format("Looking at group %s type %s",contactname,typename))
    local contactcoord = contact.Cluster.coordinate or contact.Contact.position or contact.Contact.group:GetCoordinate()
    local contactvec2 = contactcoord:GetVec2()
   
    -- Bucket 0 - NOT in Rejection Zone :)
    if self.RejectZone then
      local isinrejzone = self.RejectZone:IsVec2InZone(contactvec2)
      if isinrejzone then
        self:T(self.lid.."Across Border = YES - ignore")
        checked = true
      end
    end
    -- Bucket 1 - close to AIC (HVT) ca ~45nm
    if not self.GCI then
      local HVTCoordinate = self.OrbitZone:GetCoordinate()
      local distance = UTILS.NMToMeters(200)
      if contactcoord then
        distance = HVTCoordinate:Get2DDistance(contactcoord)
      end
      self:T(self.lid.."HVT Distance = "..UTILS.Round(UTILS.MetersToNM(distance),0))
      if UTILS.MetersToNM(distance) <= 45 and not checked then
        self:T(self.lid.."In HVT Distance = YES")
        targettable:Push(contact,distance)
        checked = true
      end
    end
    
    -- Bucket 2 - in AO/FEZ   
    local isinopszone = self.OpsZone:IsVec2InZone(contactvec2)
    local distance = self.OpsZone:Get2DDistance(contactcoord)
    if isinopszone and not checked then
      self:T(self.lid.."In FEZ = YES")
      targettable:Push(contact,distance)
      checked = true
    end
    
    -- Bucket 3 - in Radar(Control)Zone, < 100nm to AO, Aspect HOT on AO
    local isinopszone = self.ControlZone:IsVec2InZone(contactvec2)
    if isinopszone and not checked then
      self:T(self.lid.."In Radar Zone = YES")
      -- Close to Bulls Eye?
      local distance = self.AOCoordinate:Get2DDistance(contactcoord) -- m
      local AOdist = UTILS.Round(UTILS.MetersToNM(distance),0) -- NM
      if not contactcoord.Heading then
        contactcoord.Heading = self.intel:CalcClusterDirection(contact.Cluster)
      end -- end heading
      local aspect = contactcoord:ToStringAspect(self.ControlZone:GetCoordinate())
      local sizing = contact.Cluster.size or self.intel:ClusterCountUnits(contact.Cluster) or 1
      -- prefer heavy groups
      sizing = math.fmod((sizing * 0.1),1)
      local AOdist2 = (AOdist / 2) * sizing
      AOdist2 = UTILS.Round((AOdist/2)+((AOdist/2)-AOdist2), 0)
      self:T(self.lid.."Aspect = "..aspect.." | Size = "..sizing )
      if (AOdist2 < 75) or (aspect == "Hot") then
        local text = string.format("In AO(Adj) dist = %d(%d) NM",AOdist,AOdist2)
        self:T(self.lid..text)
        targettable:Push(contact,distance)
        checked = true
      end
    end
    
    -- Bucket 4 (if set) within the border polyzone to be defended
    if self.BorderZone then
      local isinborderzone = self.BorderZone:IsVec2InZone(contactvec2)
      if isinborderzone and not checked then
        self:T(self.lid.."In BorderZone = YES")
        targettable:Push(contact,distance)
        checked = true
      end
    end
  end 
  
  self:T(self.lid.."Post filter count: "..targettable:Count())
  
  if targettable:Count() > maxtargets then
    local targets = targettable:GetSortedDataTable()
    targettable:Clear()
    for i=1,maxtargets do
      targettable:Push(targets[i])
    end
  end
  
  sortedtargets:Clear()
  prefiltered:Clear()
  
  if targettable:Count() > 0 then
    HaveTargets = true
  end
  
  return HaveTargets, targettable
end

--- [Internal] AWACS Speak Picture AO/EWR entries
-- @param #AWACS self
-- @param #boolean AO If true this is for AO, else EWR
-- @param #string Callsign Callsign to address
-- @param #number GID GroupID for comms
-- @param #number MaxEntries Max entries to show
-- @param #boolean IsGeneral Is a general picture, address all stations
-- @return #AWACS self
function AWACS:_CreatePicture(AO,Callsign,GID,MaxEntries,IsGeneral)
  self:T(self.lid.."_CreatePicture AO="..tostring(AO).." for "..Callsign.." GID "..GID)
  
  local managedgroup = nil
  local group = nil
  local groupcoord = nil
  
  if not IsGeneral then
    managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    group = managedgroup.Group -- Wrapper.Group#GROUP
    groupcoord = group:GetCoordinate()
  end
  
  local fifo = self.PictureAO -- Utilities.FiFo#FIFO
  
  local maxentries = self.maxspeakentries or 3
  
  if MaxEntries and MaxEntries>0  and MaxEntries <= 3 then
   maxentries = MaxEntries
  end
  
  local counter = 0
  
  if not AO then 
   -- fifo = self.PictureEWR 
  end
  
  local entries = fifo:GetSize()
  
  if entries < maxentries then maxentries = entries end
  
  local text = ""
  local textScreen = ""
  
  -- "<tag> group, BRA <bearing> for <range> at angels <alt/1000>, <aspect>, <shipsize>"
  while counter < maxentries do
    counter = counter + 1
    local contact = fifo:Pull() -- #AWACS.ManagedContact
    self:T({contact})
    if contact and contact.Contact.group and contact.Contact.group:IsAlive() then

      local coordinate = contact.Cluster.coordinate or contact.Contact.position or contact.Contact.group:GetCoordinate() -- Core.Point#COORDINATE
      if not coordinate then
        self:E(self.lid.."NO Coordinate for this cluster! CID="..contact.CID)
        self:E({contact})
        break
      end
      if not coordinate.Heading then
        coordinate.Heading = contact.Contact.heading or contact.Contact.group:GetHeading()
      end
      local refBRAA = ""
      local refBRAATTS = ""
      
      if self.NoGroupTags then
        local grouptxt = self.gettext:GetEntry("GROUPCAP",self.locale)
        text = grouptxt .. "." -- Alpha Group.
        textScreen = grouptxt ..","
      else
        local grouptxt = self.gettext:GetEntry("GROUP",self.locale)
        text = contact.TargetGroupNaming.." "..grouptxt.."." -- Alpha Group.
        textScreen = contact.TargetGroupNaming.." "..grouptxt..","
      end
      
      if IsGeneral or not self.PlayerGuidance then
        local milestxt = self.gettext:GetEntry("MILES",self.locale)
        local thsdtxt = self.gettext:GetEntry("THOUSAND",self.locale)
        refBRAA=self:_ToStringBULLS(coordinate)
        refBRAATTS = self:_ToStringBULLS(coordinate, false, true)
        local alt = contact.Contact.group:GetAltitude() or 8000
        alt = UTILS.Round(UTILS.MetersToFeet(alt)/1000,0)
        -- Alpha Group. Bulls eye 0 2 1, 16 miles, 25 thousand. 
        text = string.format("%s %s %s, %d %s.",text,refBRAATTS,milestxt,alt,thsdtxt) 
        textScreen = string.format("%s %s %s, %d %s.",textScreen,refBRAA,milestxt,alt,thsdtxt)      
      else
        -- pilot reference
        refBRAA = coordinate:ToStringBRAANATO(groupcoord,true,true)
        refBRAATTS = string.gsub(refBRAA,"BRAA","brah")
        refBRAATTS = string.gsub(refBRAATTS,"BRA","brah")
         -- Charlie group, BRAA 045, 105 miles, Angels 41, Flanking, Track North-East, Bogey, Spades.
        if self.PathToGoogleKey then
          refBRAATTS = coordinate:ToStringBRAANATO(groupcoord,true,true,true,false,true)
        end
        if contact.IFF ~= AWACS.IFF.BOGEY then
          local bogey = self.gettext:GetEntry("BOGEY",self.locale)
          refBRAA = string.gsub(refBRAA,bogey, contact.IFF)
          refBRAATTS = string.gsub(refBRAATTS,bogey, contact.IFF)
        end
        text = text .. " "..refBRAATTS
        textScreen = textScreen .." "..refBRAA
      end
      
      -- Aspect
      local aspect = ""
      
      -- sizing
      local size = contact.Contact.group:CountAliveUnits()
      local threatsize, threatsizetext = self:_GetBlurredSize(size)
      
      if threatsize > 1 then  
        text = text.." "..threatsizetext.."." -- Alpha Group. Heavy.
        textScreen = textScreen.." "..threatsizetext.."."
      end 
      
      -- engagement tag?
      if contact.EngagementTag then
        text = text .. " "..contact.EngagementTag -- Alpha Group. Bulls eye 0 2 1, 16. Heavy. Targeted by Jazz 1 1.
        textScreen = textScreen .. " "..contact.EngagementTag -- Alpha Group, Bullseye 021, 16, Flanking. Targeted by Jazz 1 1.
      end
      
      -- Transmit Radio
      local RadioEntry_IsGroup = false
      local RadioEntry_ToScreen = self.debug
      if managedgroup and not IsGeneral then
        RadioEntry_IsGroup = managedgroup.IsPlayer
        RadioEntry_ToScreen = managedgroup.IsPlayer
      end 
      
      self:_NewRadioEntry(text,textScreen,GID,RadioEntry_IsGroup,RadioEntry_ToScreen,true,false)

    end
  end
  
  -- empty queue from leftovers
  fifo:Clear()
 
  return self
end

--- [Internal] AWACS Speak Bogey Dope entries
-- @param #AWACS self
-- @param #string Callsign Callsign to address
-- @param #number GID GroupID for comms
-- @param #boolean Tactical Is for tactical info
-- @return #AWACS self
function AWACS:_CreateBogeyDope(Callsign,GID,Tactical)
  self:T(self.lid.."_CreateBogeyDope for "..Callsign.." GID "..GID)
  
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local group = managedgroup.Group -- Wrapper.Group#GROUP
  local groupcoord = group:GetCoordinate()
  
  local fifo = self.ContactsAO -- Utilities.FiFo#FIFO
  local maxentries = 1
  local counter = 0
  
  local entries = fifo:GetSize()
  
  if entries < maxentries then maxentries = entries end
  
  local sortedIDs = fifo:GetIDStackSorted() -- sort by distance
  
  while counter < maxentries do
    counter = counter + 1
    local contact = fifo:PullByID(sortedIDs[counter]) -- #AWACS.ManagedContact
    self:T({contact})
    local position = contact.Cluster.coordinate or contact.Contact.position
    if contact and position then
      local tag =  contact.TargetGroupNaming
      local reportingname = contact.ReportingName
      -- DONE - add tag
      self:_AnnounceContact(contact,false,group,true,tag,false,reportingname,Tactical)
    end
  end
  
  -- empty queue from leftovers
  fifo:Clear()
  
  return self
end

--- [Internal] AWACS Menu for Picture
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #boolean IsGeneral General picture if true, address no-one specific
-- @return #AWACS self
function AWACS:_Picture(Group,IsGeneral)
  self:T(self.lid.."_Picture")
  local text = ""
  local textScreen = text
  local general = IsGeneral
  local GID, Outcome, gcallsign = self:_GetManagedGrpID(Group) 
  
  if general then
    local allst = self.gettext:GetEntry("ALLSTATIONS",self.locale)
    gcallsign = allst
  end
  
  if Group and Outcome then
    general = false
  end
    
  if not self.intel then
    -- no intel yet!
    local picclean = self.gettext:GetEntry("PICCLEAN",self.locale)
    text = string.format(picclean,gcallsign,self.callsigntxt)
    textScreen = text
    
    self:_NewRadioEntry(text,text,GID,false,true,true,false)

    return self 
  end

  if Outcome or general then
    -- Pilot is checked in
    -- get clusters from Intel  
    local contactstable = self.Contacts:GetDataTable()
    
    -- sort into buckets
    for _,_contact in pairs(contactstable) do
      
      local contact  = _contact -- #AWACS.ManagedContact

      local coordVec2 = contact.Contact.position:GetVec2()        
      
      if self.OpsZone:IsVec2InZone(coordVec2) then
        self.PictureAO:Push(contact)
      elseif self.OrbitZone and self.OrbitZone:IsVec2InZone(coordVec2) then
        self.PictureAO:Push(contact)
      elseif self.ControlZone:IsVec2InZone(coordVec2) then
        local distance = math.floor((contact.Contact.position:Get2DDistance(self.ControlZone:GetCoordinate()) / 1000) + 1) -- km
        self.PictureEWR:Push(contact,distance)
      end
      
    end
    
    local clustersAO = self.PictureAO:GetSize()
    local clustersEWR = self.PictureEWR:GetSize()
    
    if clustersAO < 3 and clustersEWR > 0 then
      -- make sure we have 3, can only add 1, 2 or 3
      local IDstack = self.PictureEWR:GetSortedDataTable()
      -- how many do we need?
      local weneed = 3-clustersAO
      -- do we have enough?
      self:T(string.format("Picture - adding %d/%d contacts from EWR",weneed,clustersEWR))
      if weneed > clustersEWR then
        weneed = clustersEWR
      end
      for i=1,weneed do
        self.PictureAO:Push(IDstack[i])
      end
    end
    
    clustersAO = self.PictureAO:GetSize()
    
    if clustersAO == 0 and clustersEWR == 0 then
      -- clean
      local picclean = self.gettext:GetEntry("PICCLEAN",self.locale)
      text = string.format(picclean,gcallsign,self.callsigntxt)
      textScreen = text
      self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
    else
    
      if clustersAO > 0 then
        local picture = self.gettext:GetEntry("PICTURE",self.locale)
        text = string.format("%s, %s. %s. ",gcallsign, self.callsigntxt,picture)
        textScreen = string.format("%s, %s. %s. ",gcallsign, self.callsigntxt,picture)
        local onetxt = self.gettext:GetEntry("ONE",self.locale)
        local grptxt = self.gettext:GetEntry("GROUP",self.locale)
        local groupstxt = self.gettext:GetEntry("GROUPMULTI",self.locale)  
        if clustersAO == 1 then
          text = string.format("%s%s %s. ",text,onetxt,grptxt)
          textScreen = string.format("%s%s %s.\n",textScreen,onetxt,grptxt)
        else
          text = string.format("%s%d %s. ",text,clustersAO,groupstxt)
          textScreen = string.format("%s%d %s.\n",textScreen,clustersAO,groupstxt)
        end
        self:_NewRadioEntry(text,textScreen,GID,Outcome,true,true,false)
        
        self:_CreatePicture(true,gcallsign,GID,3,general)
        
        self.PictureAO:Clear()
        self.PictureEWR:Clear()
      end
    end
    
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,gcallsign, self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] AWACS Menu for Bogey Dope
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #boolean Tactical Check for tactical info
-- @return #AWACS self
function AWACS:_BogeyDope(Group,Tactical)
  self:T(self.lid.."_BogeyDope")
  local text = ""
  local textScreen = ""
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local gcallsign = self:_GetCallSign(Group,GID) or "Ghost 1"
    
  if not self.intel then
    -- no intel yet!
    local clean = self.gettext:GetEntry("CLEAN",self.locale)
    text = string.format(clean,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
    self:_NewRadioEntry(text,text,0,false,true,true,false,true,Tactical)
    return self 
  end

  if Outcome then
    -- Pilot is checked in
    
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local pilotgroup = managedgroup.Group
    local pilotcoord = managedgroup.Group:GetCoordinate()
    
    local contactstable = self.Contacts:GetDataTable()
    
    -- sort into buckets - AO only for bogey dope!
    for _,_contact in pairs(contactstable) do
      local managedcontact = _contact -- #AWACS.ManagedContact
      local contactposition = managedcontact.Cluster.coordinate or managedcontact.Contact.position -- Core.Point#COORDINATE
      local coordVec2 = contactposition:GetVec2()
      -- Get distance for sorting
      local dist = pilotcoord:Get2DDistance(contactposition)

      if self.ControlZone:IsVec2InZone(coordVec2) then
        self.ContactsAO:Push(managedcontact,dist)
      elseif self.BorderZone and self.BorderZone:IsVec2InZone(coordVec2) then 
       self.ContactsAO:Push(managedcontact,dist)
      else
        if self.OrbitZone then
          local distance = contactposition:Get2DDistance(self.OrbitZone:GetCoordinate())
          if (distance <= UTILS.NMToMeters(45)) then
            self.ContactsAO:Push(managedcontact,distance)
          end
        end
      end     
    end
    
    local contactsAO = self.ContactsAO:GetSize()
    
    if contactsAO == 0 then
      -- clean
      local clean = self.gettext:GetEntry("CLEAN",self.locale)
      text = string.format(clean,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
      
      self:_NewRadioEntry(text,text,GID,Outcome,Outcome,true,false,true,Tactical)

    else
    
      if contactsAO > 0 then
        local dope = self.gettext:GetEntry("DOPE",self.locale)
        text = string.format(dope,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
        textScreen = string.format(dope,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
        local onetxt = self.gettext:GetEntry("ONE",self.locale)
        local grptxt = self.gettext:GetEntry("GROUP",self.locale)
        local groupstxt = self.gettext:GetEntry("GROUPMULTI",self.locale)  
        if contactsAO == 1 then
          text = string.format("%s%s %s. ",text,onetxt,grptxt)
          textScreen = string.format("%s%s %s.\n",textScreen,onetxt,grptxt)
        else
          text = string.format("%s%d %s. ",text,contactsAO,groupstxt)
          textScreen = string.format("%s%d %s.\n",textScreen,contactsAO,groupstxt)
        end
                
        self:_NewRadioEntry(text,textScreen,GID,Outcome,true,true,false,true,Tactical)
        
        self:_CreateBogeyDope(self:_GetCallSign(Group,GID) or "Ghost 1",GID,Tactical)
      end
    end
    
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false,Tactical)

  end
  return self
end

--- [Internal] AWACS Menu for Show Info
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_ShowAwacsInfo(Group)
  self:T(self.lid.."_ShowAwacsInfo")
  local report = REPORT:New("Info")
  local STN = self.STN 
  report:Add("====================")
  report:Add(string.format("AWACS %s",self.callsigntxt))
  report:Add(string.format("Radio: %.3f %s",self.Frequency,UTILS.GetModulationName(self.Modulation)))
  if STN then
    report:Add(string.format("Link-16 STN: %s",STN))
  end
  report:Add(string.format("Bulls Alias: %s",self.AOName))
  report:Add(string.format("Coordinate: %s",self.AOCoordinate:ToStringLLDDM()))
  report:Add("====================")
  report:Add(string.format("Assignment Distance: %d NM",self.maxassigndistance))
  report:Add(string.format("TAC Distance: %d NM",self.TacDistance))
  report:Add(string.format("MELD Distance: %d NM",self.MeldDistance))
  report:Add(string.format("THREAT Distance: %d NM",self.ThreatDistance))
  report:Add("====================")
  report:Add(string.format("ROE/ROT: %s, %s",self.AwacsROE,self.AwacsROT))
  MESSAGE:New(report:Text(),45,"AWACS"):ToGroup(Group)
  return self
end

--- [Internal] AWACS Menu for VID
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #string Declaration Text declaration the player used
-- @return #AWACS self
function AWACS:_VID(Group,Declaration)
  self:T(self.lid.."_VID")

  local GID, Outcome, Callsign = self:_GetManagedGrpID(Group)
  local text = ""
  local TextTTS = ""
  
  if Outcome then
    --yes, known
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local group = managedgroup.Group
    local position = group:GetCoordinate()
    local radius = UTILS.NMToMeters(self.DeclareRadius) or UTILS.NMToMeters(5)
    
    -- find tasked contact
    local TID = managedgroup.CurrentTask or 0
    if TID > 0 then
      local task = self.ManagedTasks:ReadByID(TID) -- #AWACS.ManagedTask
      -- correct task?
      if task.ToDo ~= AWACS.TaskDescription.VID then
        return self
      end
      -- already done?
      if task.Status ~= AWACS.TaskStatus.ASSIGNED then
        return self
      end 
      local CID = task.Cluster.CID
      local cluster = self.Contacts:ReadByID(CID) -- #AWACS.ManagedContact
      if cluster then
        local gposition = cluster.Contact.group:GetCoordinate() 
        local cposition = gposition or cluster.Cluster.coordinate or cluster.Contact.position
        local distance = cposition:Get2DDistance(position)
        distance = UTILS.Round(distance,0) + 1
        if distance <= radius or self.debug then
          -- we can VID
          self:T("Contact VID as "..Declaration)
          -- update
          cluster.IFF = Declaration
          task.Status = AWACS.TaskStatus.SUCCESS
          self.ManagedTasks:PullByID(TID)
          self.ManagedTasks:Push(task,TID)
          self.Contacts:PullByID(CID)
          self.Contacts:Push(cluster,CID)
          local vidpos = self.gettext:GetEntry("VIDPOS",self.locale)
          text = string.format(vidpos,Callsign,self.callsigntxt, Declaration)
          self:T(text)
          self:__VIDSuccess(3,GID,group,cluster)
        else
          -- too far away
          self:T("Contact VID not close enough")
          local vidneg = self.gettext:GetEntry("VIDNEG",self.locale)
          text = string.format(vidneg,Callsign,self.callsigntxt)
          self:T(text)
          self:__VIDFailure(3,GID,group,cluster)
        end
        self:_NewRadioEntry(text,text,GID,Outcome,true,true,false,true)
      end
    end 
    --
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] AWACS Menu for Declare
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Declare(Group)
  self:T(self.lid.."_Declare")

  local GID, Outcome, Callsign = self:_GetManagedGrpID(Group)
  local text = ""
  local TextTTS = ""
  
  if Outcome then
    --yes, known
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local group = managedgroup.Group
    local position = group:GetCoordinate()
    local radius = UTILS.NMToMeters(self.DeclareRadius) or UTILS.NMToMeters(5)
    -- find contacts nearby
    local groupzone = ZONE_GROUP:New(group:GetName(),group, radius)
    local Coalitions = {"red","neutral"}
    if self.coalition == coalition.side.NEUTRAL then
      Coalitions = {"red","blue"}
    elseif self.coalition == coalition.side.RED then
      Coalitions = {"blue","neutral"}
    end
    local contactset = SET_GROUP:New():FilterCategoryAirplane():FilterCoalitions(Coalitions):FilterZones({groupzone}):FilterOnce()
    local numbercontacts = contactset:CountAlive() or 0
    local foundcontacts = {}
    if numbercontacts > 0 then
      -- we have some around
      -- sort by distance
      contactset:ForEach(
        function (airpl)
          local distance = position:Get2DDistance(airpl:GetCoordinate())
          distance = UTILS.Round(distance,0) + 1
          foundcontacts[distance] = airpl
        end
      ,{}
      )
      for _dist,_contact in UTILS.spairs(foundcontacts) do
        local distanz = _dist
        local contact = _contact -- Wrapper.Group#GROUP
        local ccoalition = contact:GetCoalition()
        local ctypename = contact:GetTypeName()
        
        local ffneutral = self.gettext:GetEntry("FFNEUTRAL",self.locale)
        local fffriend = self.gettext:GetEntry("FFFRIEND",self.locale)
        local ffhostile = self.gettext:GetEntry("FFHOSTILE",self.locale)
        local ffspades = self.gettext:GetEntry("FFSPADES",self.locale)
        
        local friendorfoe = ffneutral
        if self.self.ModernEra then
          if ccoalition == self.coalition then
            friendorfoe = fffriend
          elseif ccoalition == coalition.side.NEUTRAL then
            friendorfoe = ffneutral
          elseif ccoalition ~= self.coalition then 
            friendorfoe = ffhostile
          end
        else
          friendorfoe = ffspades
        end
        -- see if that works
        self:T(string.format("Distance %d ContactName %s Coalition %d (%s) TypeName %s",distanz,contact:GetName(),ccoalition,friendorfoe,ctypename))
        
        text = string.format("%s. %s. %s.",Callsign,self.callsigntxt,friendorfoe)
        TextTTS = text
        if self.ModernEra then
          text = string.format("%s %s.",text,ctypename)
        end
        break 
      end
    else
      -- clean
      local ffclean = self.gettext:GetEntry("FFCLEAN",self.locale)
      text = string.format("%s. %s. %s.",Callsign,self.callsigntxt,ffclean)
      TextTTS = text
    end   
    self:_NewRadioEntry(TextTTS,text,GID,Outcome,true,true,false,true) 
    --
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] AWACS Menu for Commit
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Commit(Group)
  self:T(self.lid.."_Commit") 
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if Outcome then 
    local Pilot = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    -- Get current task from the group
    local currtaskid = Pilot.CurrentTask
    local managedtask = self.ManagedTasks:ReadByID(currtaskid) -- #AWACS.ManagedTask
    self:T(string.format("TID %d(%d) | ToDo %s | Status %s",currtaskid,managedtask.TID,managedtask.ToDo,managedtask.Status))
    if managedtask then
      -- got a task, status?
      if managedtask.Status == AWACS.TaskStatus.REQUESTED then
        -- ok let's commit this one
        managedtask = self.ManagedTasks:PullByID(currtaskid)
        managedtask.Status = AWACS.TaskStatus.ASSIGNED
        self.ManagedTasks:Push(managedtask,currtaskid)
        self:T(string.format("COMMITTED - TID %d(%d) for GID %d | ToDo %s | Status %s",currtaskid,GID,managedtask.TID,managedtask.ToDo,managedtask.Status))
        -- link to Pilot
        Pilot.HasAssignedTask = true
        Pilot.CurrentTask = currtaskid
        self.ManagedGrps[GID] = Pilot
        local copy = self.gettext:GetEntry("COPY",self.locale)
        local targetedby = self.gettext:GetEntry("TARGETEDBY",self.locale)
        text = string.format(copy,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
        local EngagementTag = string.format(targetedby,Pilot.CallSign)
        self:_UpdateContactEngagementTag(Pilot.ContactCID,EngagementTag,false,false,AWACS.TaskStatus.ASSIGNED)
        self:_NewRadioEntry(text,text,GID,Outcome,true,true,false,true)
      else
        self:E(self.lid.."Cannot find REQUESTED managed task with TID="..currtaskid.." for GID="..GID)
      end
    else
      self:E(self.lid.."Cannot find managed task with TID="..currtaskid.." for GID="..GID)
    end
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] AWACS Menu for Judy
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Judy(Group)
  self:T(self.lid.."_Judy")
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if Outcome then 
    local Pilot = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    -- Get current task from the group
    local currtaskid = Pilot.CurrentTask
    local managedtask = self.ManagedTasks:ReadByID(currtaskid) -- #AWACS.ManagedTask
    if managedtask then
      -- got a task, status?
      if managedtask.Status == AWACS.TaskStatus.REQUESTED or managedtask.Status == AWACS.TaskStatus.UNASSIGNED then
        -- ok let's commit this one
        managedtask = self.ManagedTasks:PullByID(currtaskid)
        managedtask.Status = AWACS.TaskStatus.ASSIGNED
        self.ManagedTasks:Push(managedtask,currtaskid)
        local copy = self.gettext:GetEntry("COPY",self.locale)
        local targetedby = self.gettext:GetEntry("TARGETEDBY",self.locale)
        text = string.format(copy,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
        local EngagementTag = string.format(targetedby,Pilot.CallSign)
        self:_UpdateContactEngagementTag(Pilot.ContactCID,EngagementTag,false,false,AWACS.TaskStatus.ASSIGNED)
        self:_NewRadioEntry(text,text,GID,Outcome,true,true,false,true)
      else
        self:E(self.lid.."Cannot find REQUESTED or UNASSIGNED managed task with TID="..currtaskid.." for GID="..GID)
      end
    else
      self:E(self.lid.."Cannot find managed task with TID="..currtaskid.." for GID="..GID)
    end
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
     self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] AWACS Menu for Unable
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Unable(Group)
  self:T(self.lid.."_Unable")
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if Outcome then 
    local Pilot = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    -- Get current task from the group
    local currtaskid = Pilot.CurrentTask
    local managedtask = self.ManagedTasks:ReadByID(currtaskid) -- #AWACS.ManagedTask
    self:T(string.format("UNABLE for TID %d(%d) | ToDo %s | Status %s",currtaskid,managedtask.TID,managedtask.ToDo,managedtask.Status))
    if managedtask then
      -- got a task, status?
      if managedtask.Status == AWACS.TaskStatus.REQUESTED then
        -- ok let's commit this one
        managedtask = self.ManagedTasks:PullByID(currtaskid)
        managedtask.IsUnassigned = true
        managedtask.Status = AWACS.TaskStatus.FAILED
        self.ManagedTasks:Push(managedtask,currtaskid)
        self:T(string.format("REJECTED - TID %d(%d) for GID %d | ToDo %s | Status %s",currtaskid,GID,managedtask.TID,managedtask.ToDo,managedtask.Status))
        -- unlink group from task
        Pilot.HasAssignedTask = false
        Pilot.CurrentTask = 0
        Pilot.LastTasking = timer.getTime()
        self.ManagedGrps[GID] = Pilot
        local copy = self.gettext:GetEntry("COPY",self.locale)
        text = string.format(copy,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
        local EngagementTag = ""
        self:_UpdateContactEngagementTag(Pilot.ContactCID,EngagementTag,false,false,AWACS.TaskStatus.UNASSIGNED)
        self:_NewRadioEntry(text,text,GID,Outcome,true,true,false,true)
      else
        self:E(self.lid.."Cannot find REQUESTED managed task with TID="..currtaskid.." for GID="..GID)
      end
    else
      self:E(self.lid.."Cannot find managed task with TID="..currtaskid.." for GID="..GID)
    end
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end
  return self
end

--- [Internal] AWACS Menu for Abort
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_TaskAbort(Group)
  self:T(self.lid.."_TaskAbort")
  local Outcome,GID = self:_GetGIDFromGroupOrName(Group)
  local text = ""
  if Outcome then 
    local Pilot = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    self:T({Pilot})
    -- Get current task from the group
    local currtaskid = Pilot.CurrentTask
    local managedtask = self.ManagedTasks:ReadByID(currtaskid) -- #AWACS.ManagedTask
    if managedtask then
      -- got a task, status?
      self:T(string.format("ABORT for TID %d(%d) | ToDo %s | Status %s",currtaskid,managedtask.TID,managedtask.ToDo,managedtask.Status))
      if managedtask.Status == AWACS.TaskStatus.ASSIGNED then
        -- ok let's un-commit this one
        managedtask = self.ManagedTasks:PullByID(currtaskid)
        managedtask.Status = AWACS.TaskStatus.FAILED
        managedtask.IsUnassigned = true
        self.ManagedTasks:Push(managedtask,currtaskid)
        -- unlink group
        self:T(string.format("ABORTED - TID %d(%d) for GID %d | ToDo %s | Status %s",currtaskid,GID,managedtask.TID,managedtask.ToDo,managedtask.Status))
        -- unlink group from task
        Pilot.HasAssignedTask = false
        Pilot.CurrentTask = 0
        Pilot.LastTasking = timer.getTime()
        self.ManagedGrps[GID] = Pilot
        local copy = self.gettext:GetEntry("COPY",self.locale)
        text = string.format(copy,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
        local EngagementTag = ""
        self:_UpdateContactEngagementTag(Pilot.ContactCID,EngagementTag,false,false,AWACS.TaskStatus.UNASSIGNED)
        self:_NewRadioEntry(text,text,GID,Outcome,true,true,false,true)
      else
        self:E(self.lid.."Cannot find ASSIGNED managed task with TID="..currtaskid.." for GID="..GID)
      end
    else
      self:E(self.lid.."Cannot find managed task with TID="..currtaskid.." for GID="..GID)
    end
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)
  end

  return self
end

--- [Internal] AWACS Menu for Showtask
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Showtask(Group)
  self:T(self.lid.."_Showtask")

  local GID, Outcome, Callsign = self:_GetManagedGrpID(Group)
  local text = ""
  
  if Outcome then
   -- known group
   
   -- Do we have a task?
   local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
   
   if managedgroup.IsPlayer then

    if managedgroup.CurrentTask >0 and self.ManagedTasks:HasUniqueID(managedgroup.CurrentTask) then
      -- get task structure
      local currenttask = self.ManagedTasks:ReadByID(managedgroup.CurrentTask) -- #AWACS.ManagedTask
      if currenttask then
        local status = currenttask.Status
        local targettype = currenttask.Target:GetCategory()
        local targetstatus = currenttask.Target:GetState()
        local ToDo = currenttask.ToDo
        local description = currenttask.ScreenText
        local descTTS = currenttask.ScreenText
        local callsign = Callsign
        
        if self.debug then
          local taskreport = REPORT:New("AWACS Tasking Display")
          taskreport:Add("===============")
          taskreport:Add(string.format("Task for Callsign: %s",Callsign))
          taskreport:Add(string.format("Task: %s with Status: %s",ToDo,status))
          taskreport:Add(string.format("Target of Type: %s",targettype))
          taskreport:Add(string.format("Target in State: %s",targetstatus))
          taskreport:Add("===============")
          self:I(taskreport:Text())
        end
        
        local pposition = managedgroup.Group:GetCoordinate() or managedgroup.LastKnownPosition
        if currenttask.ToDo == AWACS.TaskDescription.INTERCEPT or currenttask.ToDo == AWACS.TaskDescription.VID then
          local targetpos = currenttask.Target:GetCoordinate()
          if pposition and targetpos then
            local alti = currenttask.Cluster.altitude or currenttask.Contact.altitude or currenttask.Contact.group:GetAltitude()
            local direction, direcTTS = self:_ToStringBRA(pposition,targetpos,alti)
            description = description .. "\nBRA "..direction
            descTTS = descTTS ..";BRA "..direcTTS
          end
        elseif currenttask.ToDo == AWACS.TaskDescription.ANCHOR or currenttask.ToDo == AWACS.TaskDescription.REANCHOR then
          local targetpos = currenttask.Target:GetCoordinate()
          local direction, direcTTS = self:_ToStringBR(pposition,targetpos)
          description = description .. "\nBR "..direction
          descTTS = descTTS .. ";BR "..direcTTS
        end
        local statustxt = self.gettext:GetEntry("STATUS",self.locale)  
        --MESSAGE:New(string.format("%s\n%s %s",description,statustxt,status),30,"AWACS",true):ToGroup(Group)
        local text = string.format("%s\n%s %s",description,statustxt,status)
        local ttstext = string.format("%s. %s. %s",managedgroup.CallSign,self.callsigntxt,descTTS)
        ttstext = string.gsub(ttstext,"\\n",";")
        ttstext = string.gsub(ttstext,"VID","V I D")
        self:_NewRadioEntry(ttstext,text,GID,true,true,false,false,true)
      end
    end
   end
   
  elseif self.AwacsFG then
    -- no, unknown
    local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt) 
    self:_NewRadioEntry(text,text,GID,Outcome,true,true,false)  
  end
  return self
end

--- [Internal] AWACS Menu for Check in
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_CheckIn(Group)
  self:T(self.lid.."_CheckIn "..Group:GetName())
  -- check if already known
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  local textTTS = ""
  if not Outcome then
    self.ManagedGrpID = self.ManagedGrpID + 1
    local managedgroup = {} -- #AWACS.ManagedGroup
      managedgroup.Group = Group
      managedgroup.GroupName = Group:GetName()
      managedgroup.IsPlayer = true
      managedgroup.IsAI = false
      managedgroup.CallSign = self:_GetCallSign(Group,GID,true) or "Ghost 1"
      managedgroup.CurrentAuftrag = 0
      managedgroup.CurrentTask = 0
      managedgroup.HasAssignedTask = true
      managedgroup.Blocked = true
      managedgroup.GID = self.ManagedGrpID
      managedgroup.LastKnownPosition = Group:GetCoordinate()
      managedgroup.LastTasking = timer.getTime()
      
      GID = managedgroup.GID
      self.ManagedGrps[self.ManagedGrpID]=managedgroup
    
    local alphacheckbulls = self:_ToStringBULLS(Group:GetCoordinate())
    local alphacheckbullstts = self:_ToStringBULLS(Group:GetCoordinate(),false,true)
    local alpha = self.gettext:GetEntry("ALPHACHECK",self.locale)
    text = string.format("%s. %s. %s. %s",managedgroup.CallSign,self.callsigntxt,alpha,alphacheckbulls)
    textTTS = string.format("%s. %s. %s. %s",managedgroup.CallSign,self.callsigntxt,alpha,alphacheckbullstts)
   
    self:__CheckedIn(1,managedgroup.GID)
    
    if self.PlayerStationName then
       self:__AssignAnchor(5,managedgroup.GID,true,self.PlayerStationName)
    else    
      self:__AssignAnchor(5,managedgroup.GID)
    end
    
  elseif self.AwacsFG then
    local nocheckin = self.gettext:GetEntry("ALREADYCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
    textTTS = text
  end
  
  self:_NewRadioEntry(textTTS,text,GID,Outcome,true,true,false)
  
  return self
end

--- [Internal] AWACS Menu for CheckInAI
-- @param #AWACS self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup to use
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #number AuftragsNr Ops.Auftrag#AUFTRAG.auftragsnummer
-- @return #AWACS self
function AWACS:_CheckInAI(FlightGroup,Group,AuftragsNr)
  self:T(self.lid.."_CheckInAI "..Group:GetName() .. " to Auftrag Nr "..AuftragsNr)
  -- check if already known
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if not Outcome then
    self.ManagedGrpID = self.ManagedGrpID + 1
    local managedgroup = {} -- #AWACS.ManagedGroup
      managedgroup.Group = Group
      managedgroup.GroupName = Group:GetName()
      managedgroup.FlightGroup = FlightGroup
      managedgroup.IsPlayer = false
      managedgroup.IsAI = true
      local callsignstring = UTILS.GetCallsignName(self.AICAPCAllName)
      if self.callsignTranslations and self.callsignTranslations[callsignstring] then
        callsignstring = self.callsignTranslations[callsignstring]
      end
      local callsignmajor = math.fmod(self.AICAPCAllNumber,9)
      local callsign = string.format("%s %d 1",callsignstring,callsignmajor)
      if self.callsignshort then
        callsign = string.format("%s %d",callsignstring,callsignmajor)
      end
      self:T("Assigned Callsign: ".. callsign)
      managedgroup.CallSign =  callsign
      managedgroup.CurrentAuftrag = AuftragsNr
      managedgroup.HasAssignedTask = false
      managedgroup.GID = self.ManagedGrpID
      managedgroup.LastKnownPosition = Group:GetCoordinate()
    
    self.ManagedGrps[self.ManagedGrpID]=managedgroup
    
    -- SRS voice for CAP   
    FlightGroup:SetDefaultRadio(self.Frequency,self.Modulation,false)
    FlightGroup:SwitchRadio(self.Frequency,self.Modulation)
    
    local CAPVoice = self.CAPVoice
    
    if self.PathToGoogleKey then
      CAPVoice = self.CapVoices[math.floor(math.random(1,10))]
    end
    
    FlightGroup:SetSRS(self.PathToSRS,self.CAPGender,self.CAPCulture,CAPVoice,self.Port,self.PathToGoogleKey,"FLIGHT",1)
    
    local checkai = self.gettext:GetEntry("CHECKINAI",self.locale)
    text = string.format(checkai,self.callsigntxt, managedgroup.CallSign, self.CAPTimeOnStation, self.AOName)
    
    self:_NewRadioEntry(text,text,managedgroup.GID,Outcome,false,true,true)
    
    local alphacheckbulls = self:_ToStringBULLS(Group:GetCoordinate(),false,true)

    local alpha = self.gettext:GetEntry("ALPHACHECK",self.locale)
    text = string.format("%s. %s. %s. %s",managedgroup.CallSign,self.callsigntxt,alpha,alphacheckbulls)
    self:__CheckedIn(1,managedgroup.GID)

    local AW = FlightGroup.legion
    if AW.HasOwnStation then
      self:__AssignAnchor(5,managedgroup.GID,AW.HasOwnStation,AW.StationName)
    else
      self:__AssignAnchor(5,managedgroup.GID)
    end
  else
    local nocheckin = self.gettext:GetEntry("ALREADYCHECKEDIN",self.locale)
    text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
  end
  
  self:_NewRadioEntry(text,text,GID,Outcome,false,true,false)
  
  return self
end

--- [Internal] AWACS Menu for Check Out
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #number GID GroupID
-- @param #boolean dead If true, group is dead crashed or otherwise n/a
-- @return #AWACS self
function AWACS:_CheckOut(Group,GID,dead)
  self:T(self.lid.."_CheckOut")

  -- check if already known
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if Outcome then
    -- yes, known
    local safeflight = self.gettext:GetEntry("SAFEFLIGHT",self.locale)
    text = string.format(safeflight,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
    self:T(text)
    -- grab some data before we nil the entry
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local Stack = managedgroup.AnchorStackNo
    local Angels = managedgroup.AnchorStackAngels
    local GroupName = managedgroup.GroupName
    -- remove menus
    if managedgroup.IsPlayer then
      if self.clientmenus:HasUniqueID(GroupName) then
        local menus = self.clientmenus:PullByID(GroupName) --#AWACS.MenuStructure
        menus.basemenu:Remove()
        if self.TacticalSubscribers[GroupName] then
          local Freq = self.TacticalSubscribers[GroupName]
          self.TacticalFrequencies[Freq] = Freq
          self.TacticalSubscribers[GroupName] = nil
        end
      end
    end
    -- delete open tasks
    if managedgroup.CurrentTask and managedgroup.CurrentTask > 0 then
      self.ManagedTasks:PullByID(managedgroup.CurrentTask )
      self:_UpdateContactEngagementTag(managedgroup.ContactCID,"",false,false)
    end
    self.ManagedGrps[GID] = nil
    self:__CheckedOut(1,GID,Stack,Angels)
  else
    -- no, unknown
    if not dead then
      local nocheckin = self.gettext:GetEntry("NOTCHECKEDIN",self.locale)
      text = string.format(nocheckin,self:_GetCallSign(Group,GID) or "Ghost 1", self.callsigntxt)
    end
  end
  
  if not dead then
    self:_NewRadioEntry(text,text,GID,Outcome,false,true,false)
  end
  
  return self
end

--- [Internal] AWACS set client menus
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_SetClientMenus()
  self:T(self.lid.."_SetClientMenus")
  local clientset = self.clientset -- Core.Set#SET_CLIENT
  local aliveset = clientset:GetSetObjects() or {}-- #table of #CLIENT objects
  local clientcount = 0
  local clientcheckedin = 0 
  for _,_group in pairs(aliveset) do
    -- go through set and build the menu
    local grp = _group -- Wrapper.Client#CLIENT
    local cgrp = grp:GetGroup()
    local cgrpname = nil
    if cgrp and cgrp:IsAlive() then
      cgrpname = cgrp:GetName()
      self:T(cgrpname)
    end
    if self.MenuStrict then
      -- check if pilot has checked in
      if cgrp and cgrp:IsAlive() then
        clientcount = clientcount + 1
        local GID, checkedin = self:_GetManagedGrpID(cgrp)
        if checkedin then
          -- full menu minus checkin
          clientcheckedin = clientcheckedin + 1
          local hasclientmenu = self.clientmenus:ReadByID(cgrpname) -- #AWACS.MenuStructure
          local basemenu = hasclientmenu.basemenu -- Core.Menu#MENU_GROUP
          
          if hasclientmenu and (not hasclientmenu.menuset) then
          
            self:T(self.lid.."Setting Menus for "..cgrpname)
          
            basemenu:RemoveSubMenus()
            local bogeydope = MENU_GROUP_COMMAND:New(cgrp,"Bogey Dope",basemenu,self._BogeyDope,self,cgrp)
            local picture = MENU_GROUP_COMMAND:New(cgrp,"Picture",basemenu,self._Picture,self,cgrp)
            local declare = MENU_GROUP_COMMAND:New(cgrp,"Declare",basemenu,self._Declare,self,cgrp)
            local tasking = MENU_GROUP:New(cgrp,"Tasking",basemenu)
            local showtask = MENU_GROUP_COMMAND:New(cgrp,"Showtask",tasking,self._Showtask,self,cgrp)
            
            local commit
            local unable
            local abort
            if self.PlayerCapAssignment then
              commit = MENU_GROUP_COMMAND:New(cgrp,"Commit",tasking,self._Commit,self,cgrp)
              unable = MENU_GROUP_COMMAND:New(cgrp,"Unable",tasking,self._Unable,self,cgrp)
              abort = MENU_GROUP_COMMAND:New(cgrp,"Abort",tasking,self._TaskAbort,self,cgrp)
              --local judy = MENU_GROUP_COMMAND:New(cgrp,"Judy",tasking,self._Judy,self,cgrp)
            end
            
            if self.AwacsROE == AWACS.ROE.POLICE or self.AwacsROE == AWACS.ROE.VID then
              local vid = MENU_GROUP:New(cgrp,"VID as",tasking)
              local hostile = MENU_GROUP_COMMAND:New(cgrp,"Hostile",vid,self._VID,self,cgrp,AWACS.IFF.ENEMY)
              local neutral = MENU_GROUP_COMMAND:New(cgrp,"Neutral",vid,self._VID,self,cgrp,AWACS.IFF.NEUTRAL)
              local friendly = MENU_GROUP_COMMAND:New(cgrp,"Friendly",vid,self._VID,self,cgrp,AWACS.IFF.FRIENDLY)
            end
            
            local tactical
            if self.TacticalMenu then
              tactical = MENU_GROUP:New(cgrp,"Tactical Radio",basemenu)
              if self.TacticalSubscribers[cgrpname] then
                -- unsubscribe
                local entry = MENU_GROUP_COMMAND:New(cgrp,"Unsubscribe",tactical,self._UnsubScribeTactRadio,self,cgrp) 
              else
                -- subscribe
                for _,_freq in UTILS.spairs(self.TacticalFrequencies) do
                  local modu = UTILS.GetModulationName(self.TacticalModulation)
                  local text = string.format("Subscribe to %.3f %s",_freq,modu)
                  local entry = MENU_GROUP_COMMAND:New(cgrp,text,tactical,self._SubScribeTactRadio,self,cgrp,_freq) 
                end
              end
            end

            local ainfo = MENU_GROUP_COMMAND:New(cgrp,"Awacs Info",basemenu,self._ShowAwacsInfo,self,cgrp)                
            local checkout = MENU_GROUP_COMMAND:New(cgrp,"Check Out",basemenu,self._CheckOut,self,cgrp)
            
            local menus = { -- #AWACS.MenuStructure
              groupname =  cgrpname,
              menuset = true,
              basemenu = basemenu,
              checkout= checkout,
              picture = picture,
              bogeydope = bogeydope,
              declare = declare,
              tasking = tasking,
              showtask = showtask,
              --judy = judy,
              unable = unable,
              abort = abort,
              commit=commit,
              tactical=tactical,
            }
            self.clientmenus:PullByID(cgrpname)
            self.clientmenus:Push(menus,cgrpname)
          end
        elseif not self.clientmenus:HasUniqueID(cgrpname) then
          -- check in only
          local basemenu = MENU_GROUP:New(cgrp,self.Name,nil)
          local checkin = MENU_GROUP_COMMAND:New(cgrp,"Check In",basemenu,self._CheckIn,self,cgrp)
          checkin:SetTag(cgrp:GetName())
          basemenu:Refresh()         
          local menus = { -- #AWACS.MenuStructure
            groupname =  cgrpname,
            menuset = false,
            basemenu = basemenu,
            checkin = checkin,
          }
          self.clientmenus:Push(menus,cgrpname)
          -- catch errors - when this entry is built we should NOT have a managed entry
          local GID,hasentry = self:_GetManagedGrpID(cgrp)
          if hasentry then
            -- this user is checked in but has the check in entry ... not good.
            self:_CheckOut(cgrp,GID,true)
          end
        end
      end
    else
      if cgrp and cgrp:IsAlive() and not self.clientmenus:HasUniqueID(cgrpname) then
        local basemenu = MENU_GROUP:New(cgrp,self.Name,nil)
        local picture = MENU_GROUP_COMMAND:New(cgrp,"Picture",basemenu,self._Picture,self,cgrp)
        local bogeydope = MENU_GROUP_COMMAND:New(cgrp,"Bogey Dope",basemenu,self._BogeyDope,self,cgrp)
        local declare = MENU_GROUP_COMMAND:New(cgrp,"Declare",basemenu,self._Declare,self,cgrp)
        
        local tasking = MENU_GROUP:New(cgrp,"Tasking",basemenu)
        local showtask = MENU_GROUP_COMMAND:New(cgrp,"Showtask",tasking,self._Showtask,self,cgrp)
        local commit = MENU_GROUP_COMMAND:New(cgrp,"Commit",tasking,self._Commit,self,cgrp)
        local unable = MENU_GROUP_COMMAND:New(cgrp,"Unable",tasking,self._Unable,self,cgrp)
        local abort = MENU_GROUP_COMMAND:New(cgrp,"Abort",tasking,self._TaskAbort,self,cgrp)
        --local judy = MENU_GROUP_COMMAND:New(cgrp,"Judy",tasking,self._Judy,self,cgrp)
        
        if self.AwacsROE == AWACS.ROE.POLICE or self.AwacsROE == AWACS.ROE.VID then
          local vid = MENU_GROUP:New(cgrp,"VID as",tasking)
          local hostile = MENU_GROUP_COMMAND:New(cgrp,"Hostile",vid,self._VID,self,cgrp,AWACS.IFF.ENEMY)
          local neutral = MENU_GROUP_COMMAND:New(cgrp,"Neutral",vid,self._VID,self,cgrp,AWACS.IFF.NEUTRAL)
          local friendly = MENU_GROUP_COMMAND:New(cgrp,"Friendly",vid,self._VID,self,cgrp,AWACS.IFF.FRIENDLY)
        end
        
        local ainfo = MENU_GROUP_COMMAND:New(cgrp,"Awacs Info",basemenu,self._ShowAwacsInfo,self,cgrp)  
        local checkin = MENU_GROUP_COMMAND:New(cgrp,"Check In",basemenu,self._CheckIn,self,cgrp)
        local checkout = MENU_GROUP_COMMAND:New(cgrp,"Check Out",basemenu,self._CheckOut,self,cgrp)
        
        basemenu:Refresh()
        
        local menus = { -- #AWACS.MenuStructure
          groupname =  cgrpname,
          menuset = true,
          basemenu = basemenu,
          checkin = checkin,
          checkout= checkout,
          picture = picture,
          bogeydope = bogeydope,
          declare = declare,
          showtask = showtask,
          tasking = tasking,
          --judy = judy,
          unable = unable,
          abort = abort,
          commit = commit,
        }
        self.clientmenus:Push(menus,cgrpname)
      end
    end
  end

  self.MonitoringData.Players = clientcount or 0
  self.MonitoringData.PlayersCheckedin = clientcheckedin or 0
    
  return self
end

--- [Internal] AWACS Delete a new Anchor Stack from a Marker - only works if no assignments are on the station
-- @param #AWACS self
-- @return #AWACS self 
function AWACS:_DeleteAnchorStackFromMarker(Name,Coord)
  self:T(self.lid.."_DeleteAnchorStackFromMarker")
  if self.AnchorStacks:HasUniqueID(Name) and self.PlayerStationName == Name then
    local stack = self.AnchorStacks:ReadByID(Name) -- #AWACS.AnchorData
    local marker = stack.AnchorMarker
    if stack.AnchorAssignedID:Count() == 0 then
      marker:Remove()
      if self.debug then
        stack.StationZone:UndrawZone()
      end
      self.AnchorStacks:PullByID(Name)
      self.PlayerStationName = nil
    else
      if self.debug then
        self:I(self.lid.."**** Cannot delete station, there are CAPs assigned!")
        local text = marker:GetText()
        marker:TextUpdate(text.."\nMarked for deletion")
      end
    end
  end
  return self
end

--- [Internal] AWACS Move a new Anchor Stack from a Marker
-- @param #AWACS self
-- @return #AWACS self 
function AWACS:_MoveAnchorStackFromMarker(Name,Coord)
  self:T(self.lid.."_MoveAnchorStackFromMarker")
  if self.AnchorStacks:HasUniqueID(Name) and self.PlayerStationName == Name then
    local station = self.AnchorStacks:PullByID(Name) -- #AWACS.AnchorData
    local stationtag = string.format("Station: %s\nCoordinate: %s",Name,Coord:ToStringLLDDM())
    local marker = station.AnchorMarker
    local zone = station.StationZone
    if self.debug then
      zone:UndrawZone()
    end
    local radius = self.StationZone:GetRadius()
    if radius < 10000 then radius = 10000 end
    station.StationZone = ZONE_RADIUS:New(Name, Coord:GetVec2(), radius)
    marker:UpdateCoordinate(Coord)
    marker:UpdateText(stationtag)
    station.AnchorMarker = marker
    if self.debug then
      station.StationZone:DrawZone(self.coalition,{0,0,1},1,{0,0,1},0.2,5,true)
    end
    self.AnchorStacks:Push(station,Name)
  end
  return self
end

--- [Internal] AWACS Create a new Anchor Stack from a Marker - this then is the preferred station for players
-- @param #AWACS self
-- @return #AWACS self 
function AWACS:_CreateAnchorStackFromMarker(Name,Coord)
  self:T(self.lid.."_CreateAnchorStackFromMarker")
  local AnchorStackOne = {} -- #AWACS.AnchorData
  AnchorStackOne.AnchorBaseAngels = self.AnchorBaseAngels
  AnchorStackOne.Anchors = FIFO:New() -- Utilities.FiFo#FIFO
  AnchorStackOne.AnchorAssignedID = FIFO:New() -- Utilities.FiFo#FIFO
  
  local newname = Name
  
  for i=1,self.AnchorMaxStacks do
    AnchorStackOne.Anchors:Push((i-1)*self.AnchorStackDistance+self.AnchorBaseAngels)
  end
  local radius = self.StationZone:GetRadius()
  if radius < 10000 then radius = 10000 end
  AnchorStackOne.StationZone = ZONE_RADIUS:New(newname, Coord:GetVec2(), radius)
  AnchorStackOne.StationZoneCoordinate = Coord
  AnchorStackOne.StationZoneCoordinateText = Coord:ToStringLLDDM()
  AnchorStackOne.StationName = newname
  
  --push to AnchorStacks
  if self.debug then
    AnchorStackOne.StationZone:DrawZone(self.coalition,{0,0,1},1,{0,0,1},0.2,5,true)
    local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
    if self.AllowMarkers then
      AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
    end
  else
    local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
    if self.AllowMarkers then
      AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
    end
  end
  
  self.AnchorStacks:Push(AnchorStackOne,newname)
  self.PlayerStationName = newname
  
  return self
end

--- [Internal] AWACS Create a new Anchor Stack
-- @param #AWACS self
-- @return #boolean success
-- @return #number AnchorStackNo
function AWACS:_CreateAnchorStack()
  self:T(self.lid.."_CreateAnchorStack")
  local stackscreated = self.AnchorStacks:GetSize()
  if stackscreated == self.AnchorMaxAnchors  then
    -- only create self.AnchorMaxAnchors Anchors
    return false, 0
  end
  local AnchorStackOne = {} -- #AWACS.AnchorData
  AnchorStackOne.AnchorBaseAngels = self.AnchorBaseAngels
  AnchorStackOne.Anchors = FIFO:New() -- Utilities.FiFo#FIFO
  AnchorStackOne.AnchorAssignedID = FIFO:New() -- Utilities.FiFo#FIFO
  
  local newname = self.StationZone:GetName()
  
  for i=1,self.AnchorMaxStacks do
    AnchorStackOne.Anchors:Push((i-1)*self.AnchorStackDistance+self.AnchorBaseAngels)
  end
  
  if stackscreated == 0 then
    local newsubname = AWACS.AnchorNames[stackscreated+1] or tostring(stackscreated+1)
    newname = self.StationZone:GetName() .. "-"..newsubname
    AnchorStackOne.StationZone = self.StationZone
    AnchorStackOne.StationZoneCoordinate = self.StationZone:GetCoordinate()
    AnchorStackOne.StationZoneCoordinateText = self.StationZone:GetCoordinate():ToStringLLDDM()
    AnchorStackOne.StationName = newname
    --push to AnchorStacks
    if self.debug then
      --self.AnchorStacks:Flush()
      AnchorStackOne.StationZone:DrawZone(self.coalition,{0,0,1},1,{0,0,1},0.2,5,true)
      local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
      if self.AllowMarkers then
        AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
      end
    else
      local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
      if self.AllowMarkers then
        AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
      end
    end
    self.AnchorStacks:Push(AnchorStackOne,newname)
  else
    local newsubname = AWACS.AnchorNames[stackscreated+1] or tostring(stackscreated+1)
    newname = self.StationZone:GetName() .. "-"..newsubname
    local anchorbasecoord = self.OpsZone:GetCoordinate() -- Core.Point#COORDINATE
    -- OpsZone can be Polygon, so use distance to StationZone as radius
    local anchorradius = anchorbasecoord:Get2DDistance(self.StationZone:GetCoordinate())
    local angel = self.StationZone:GetCoordinate():GetAngleDegrees(self.OpsZone:GetVec3())
    self:T("Angel Radians= " .. angel)
    local turn = math.fmod(self.AnchorTurn*stackscreated,360) -- #number
    if self.AnchorTurn < 0 then turn = -turn end
    local newanchorbasecoord = anchorbasecoord:Translate(anchorradius,turn+angel) -- Core.Point#COORDINATE
    local radius = self.StationZone:GetRadius()
    if radius < 10000 then radius = 10000 end
    AnchorStackOne.StationZone = ZONE_RADIUS:New(newname, newanchorbasecoord:GetVec2(), radius)
    AnchorStackOne.StationZoneCoordinate = newanchorbasecoord
    AnchorStackOne.StationZoneCoordinateText = newanchorbasecoord:ToStringLLDDM()
    AnchorStackOne.StationName = newname
    --push to AnchorStacks
    if self.debug then
      AnchorStackOne.StationZone:DrawZone(self.coalition,{0,0,1},1,{0,0,1},0.2,5,true)
      local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
      if self.AllowMarkers then
        AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
      end
    else
      local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
      if self.AllowMarkers then
        AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
      end
    end
    self.AnchorStacks:Push(AnchorStackOne,newname)
  end

  return true,self.AnchorStacks:GetSize()
  
end

--- [Internal] AWACS get free anchor stack for managed groups
-- @param #AWACS self
-- @return #number AnchorStackNo
-- @return #boolean free 
function AWACS:_GetFreeAnchorStack()
  self:T(self.lid.."_GetFreeAnchorStack")
  local AnchorStackNo, Free = 0, false
  --return AnchorStackNo, Free
  local availablestacks = self.AnchorStacks:GetPointerStack() or {} -- #table
  for _id,_entry in pairs(availablestacks) do
    local entry = _entry -- Utilities.FiFo#FIFO.IDEntry
    local data = entry.data -- #AWACS.AnchorData
    if data.Anchors:IsNotEmpty() then
      AnchorStackNo = _id
      Free = true
      break
    end
  end
  -- TODO - if extension of anchor stacks to max, send AI home
  if not Free then
    -- try to create another stack
    local created, number = self:_CreateAnchorStack()
    if created then
      -- we could create a new one - phew!
      self:_GetFreeAnchorStack()
    end
  end
  return AnchorStackNo, Free
end

--- [Internal] AWACS Assign Anchor Position to a Group
-- @param #AWACS self
-- @param #number GID Managed Group ID
-- @param #boolean HasOwnStation
-- @param #string StationName
-- @return #AWACS self
function AWACS:_AssignAnchorToID(GID, HasOwnStation, StationName)
  self:T(self.lid.."_AssignAnchorToID")
  if not HasOwnStation then
    local AnchorStackNo, Free = self:_GetFreeAnchorStack()
    if Free then
      -- get the Anchor from the stack
      local Anchor = self.AnchorStacks:PullByPointer(AnchorStackNo) -- #AWACS.AnchorData
      -- pull one free angels
      local freeangels = Anchor.Anchors:Pull()
      -- push GID on anchor
      Anchor.AnchorAssignedID:Push(GID)
      -- push back to AnchorStacks
      self.AnchorStacks:Push(Anchor,Anchor.StationName)
      self:T({Anchor,freeangels})
      self:__AssignedAnchor(5,GID,Anchor,AnchorStackNo,freeangels)
    else
      self:E(self.lid .. "Cannot assign free anchor stack to GID ".. GID .. " Trying again in 10secs.")
      -- try again ...
      self:__AssignAnchor(10,GID)
    end
  else
    local Anchor = self.AnchorStacks:PullByID(StationName) -- #AWACS.AnchorData
    -- pull one free angels
    local freeangels = Anchor.Anchors:Pull() or 25
    -- push GID on anchor
    Anchor.AnchorAssignedID:Push(GID)
    -- push back to AnchorStacks
    self.AnchorStacks:Push(Anchor,StationName)
    self:T({Anchor,freeangels})
    local StackNo = self.AnchorStacks.stackbyid[StationName].pointer
    self:__AssignedAnchor(5,GID,Anchor,StackNo,freeangels)
  end
  return self
end

--- [Internal] Remove GID (group) from Anchor Stack
-- @param #AWACS self
-- @param #AWACS.ManagedGroup.GID ID
-- @param #number AnchorStackNo
-- @param #number Angels
-- @return #AWACS self
function AWACS:_RemoveIDFromAnchor(GID,AnchorStackNo,Angels)
  local gid = GID or 0
  local stack = AnchorStackNo or 0
  local angels = Angels or 0
  local debugstring = string.format("%s_RemoveIDFromAnchor for GID=%d Stack=%d Angels=%d",self.lid,gid,stack,angels)
  self:T(debugstring)
  -- pull correct anchor
  if stack > 0 and angels > 0 then
    local AnchorStackNo = AnchorStackNo or 1
    local Anchor = self.AnchorStacks:ReadByPointer(AnchorStackNo) -- #AWACS.AnchorData
    -- pull GID from stack
    local removedID = Anchor.AnchorAssignedID:PullByID(GID)
    -- push free angels to stack
    Anchor.Anchors:Push(Angels)
  end
  return self
end

--- [Internal] Start INTEL detection when we reach the AWACS Orbit Zone
-- @param #AWACS self
-- @param Wrapper.Group#GROUP awacs
-- @return #AWACS self
function AWACS:_StartIntel(awacs)
  self:T(self.lid.."_StartIntel")
  
  if self.intelstarted then return self end
  
  self.DetectionSet:AddGroup(awacs)

  local intel = INTEL:New(self.DetectionSet,self.coalition,self.callsigntxt)

  intel:SetClusterAnalysis(true,false,false)
  
  local acceptzoneset = SET_ZONE:New()
  acceptzoneset:AddZone(self.ControlZone)
  acceptzoneset:AddZone(self.OpsZone)
  
  if not self.GCI then
    self.OrbitZone:SetRadius(UTILS.NMToMeters(55))
    acceptzoneset:AddZone(self.OrbitZone)
  end
  
  if self.BorderZone then
    acceptzoneset:AddZone(self.BorderZone)
  end
  
  intel:SetAcceptZones(acceptzoneset)
  
  if self.NoHelos then
    intel:SetFilterCategory({Unit.Category.AIRPLANE})
  else
    intel:SetFilterCategory({Unit.Category.AIRPLANE,Unit.Category.HELICOPTER})
  end
  
  -- Corridors
  if self.usecorridors == true then
    intel:SetCorridorZones(self.corridorzones)
    if self.corridorceiling or self.corridorfloor then
      intel:SetCorridorLimits(self.corridorfloor,self.corridorceiling)
    end
  end
  
  -- Callbacks
  local function NewCluster(Cluster)
    self:__NewCluster(5,Cluster)
  end 
  function intel:OnAfterNewCluster(From,Event,To,Cluster)
    NewCluster(Cluster)
  end
  
  local function NewContact(Contact)
    self:__NewContact(5,Contact)
  end 
  function intel:OnAfterNewContact(From,Event,To,Contact)
   NewContact(Contact)
  end
  
  local function LostContact(Contact)
    self:__LostContact(5,Contact)
  end 
  function intel:OnAfterLostContact(From,Event,To,Contact)
    LostContact(Contact)
  end
  
  local function LostCluster(Cluster,Mission)
    self:__LostCluster(5,Cluster,Mission)
  end
  function intel:OnAfterLostCluster(From,Event,To,Cluster,Mission)
    LostCluster(Cluster,Mission)
  end
  
  self.intelstarted = true
  
  intel.statusupdate = -30
  
  intel:__Start(5)
  
  self.intel = intel -- Ops.Intel#INTEL
  return self
end

--- [Internal] Get blurred size of group or cluster
-- @param #AWACS self
-- @param #number size
-- @return #number adjusted size
-- @return #string AWACS.Shipsize entry for size 1..4
function AWACS:_GetBlurredSize(size)
  self:T(self.lid.."_GetBlurredSize")
  local threatsize = 0
  local blur = self.RadarBlur
  local blurmin = 100 - blur
  local blurmax = 100 + blur
  local actblur = math.random(blurmin,blurmax) / 100
  threatsize = math.floor(size * actblur)
  if threatsize == 0 then threatsize = 1 end
  if threatsize then end
  local threatsizetext = AWACS.Shipsize[1]
  if threatsize == 2  then 
    threatsizetext = AWACS.Shipsize[2]
  elseif threatsize == 3 then 
    threatsizetext = AWACS.Shipsize[3]
  elseif threatsize > 3 then
    threatsizetext = AWACS.Shipsize[4] 
  end
  return threatsize, threatsizetext
end

--- [Internal] Get threat level as clear test
-- @param #AWACS self
-- @param #number threatlevel
-- @return #string threattext
function AWACS:_GetThreatLevelText(threatlevel)
  self:T(self.lid.."_GetThreatLevelText")
  local threattext = "GREEN"
  if threatlevel <= AWACS.THREATLEVEL.GREEN then
   threattext = "GREEN"
  elseif threatlevel <= AWACS.THREATLEVEL.AMBER then
   threattext = "AMBER"
  else
    threattext = "RED"
  end
  return threattext
end


--- [Internal] Get BR text for TTS
-- @param #AWACS self
-- @param Core.Point#COORDINATE FromCoordinate
-- @param Core.Point#COORDINATE ToCoordinate
-- @return #string BRText Desired Output (BR) "214, 35 miles"
-- @return #string BRTextTTS Desired Output (BR) "2 1 4, 35 miles"
function AWACS:_ToStringBR(FromCoordinate,ToCoordinate)
  self:T(self.lid.."_ToStringBR")
  local BRText = ""
  local BRTextTTS = ""
  local DirectionVec3 = FromCoordinate:GetDirectionVec3( ToCoordinate )
  local AngleRadians =  FromCoordinate:GetAngleRadians( DirectionVec3 )
  local AngleDegrees = UTILS.Round( UTILS.ToDegree( AngleRadians ), 0 ) -- degrees
  
  local AngleDegText = string.format("%03d",AngleDegrees) -- 051
  local AngleDegTextTTS = ""
  
  local zero = self.gettext:GetEntry("ZERO",self.locale)
  local miles = self.gettext:GetEntry("MILES",self.locale)
  
  AngleDegText = string.gsub(AngleDegText,"%d","%1 ") -- "0 5 1 "
  AngleDegText = string.gsub(AngleDegText," $","") -- "0 5 1"
  
  AngleDegTextTTS = string.gsub(AngleDegText,"0",zero)
  
  local Distance = ToCoordinate:Get2DDistance( FromCoordinate ) --meters
  local distancenm = UTILS.Round(UTILS.MetersToNM(Distance),0)
  
  BRText = string.format("%03d, %d %s",AngleDegrees,distancenm,miles)
  BRTextTTS = string.format("%s, %d %s",AngleDegText,distancenm,miles)
  
  if self.PathToGoogleKey then
    BRTextTTS = string.format("%s, %d %s",AngleDegTextTTS,distancenm,miles)
  end
  
  self:T(BRText,BRTextTTS)
  return BRText,BRTextTTS
end

--- [Internal] Get BRA text for TTS
-- @param #AWACS self
-- @param Core.Point#COORDINATE FromCoordinate
-- @param Core.Point#COORDINATE ToCoordinate
-- @param #number Altitude Altitude in meters
-- @return #string BRText Desired Output (BRA) "214, 35 miles, 20 thousand"
-- @return #string BRTextTTS Desired Output (BRA) "2 1 4, 35 miles, 20 thousand"
function AWACS:_ToStringBRA(FromCoordinate,ToCoordinate,Altitude)
  self:T(self.lid.."_ToStringBRA")
  local BRText = ""
  local BRTextTTS = ""
  local altitude = UTILS.Round(UTILS.MetersToFeet(Altitude)/1000,0)
  local DirectionVec3 = FromCoordinate:GetDirectionVec3( ToCoordinate )
  local AngleRadians =  FromCoordinate:GetAngleRadians( DirectionVec3 )
  local AngleDegrees = UTILS.Round( UTILS.ToDegree( AngleRadians ), 0 ) -- degrees
  
  local AngleDegText = string.format("%03d",AngleDegrees) -- 051
  
  AngleDegText = string.gsub(AngleDegText,"%d","%1 ") -- "0 5 1 "
  AngleDegText = string.gsub(AngleDegText," $","") -- "0 5 1"
  local AngleDegTextTTS = string.gsub(AngleDegText,"0","zero")
  local Distance = ToCoordinate:Get2DDistance( FromCoordinate ) --meters
  local distancenm = UTILS.Round(UTILS.MetersToNM(Distance),0)
  
  local zero = self.gettext:GetEntry("ZERO",self.locale)
  local miles = self.gettext:GetEntry("MILES",self.locale)
  local thsd = self.gettext:GetEntry("THOUSAND",self.locale)
  local vlow = self.gettext:GetEntry("VERYLOW",self.locale)
  
  if altitude >= 1 then
    BRText = string.format("%03d, %d %s, %d %s",AngleDegrees,distancenm,miles,altitude,thsd)
    BRTextTTS = string.format("%s, %d %s, %d %s",AngleDegText,distancenm,miles,altitude,thsd)
    if self.PathToGoogleKey then
      BRTextTTS = string.format("%s, %d %s, %d %s",AngleDegTextTTS,distancenm,miles,altitude,thsd)
    end
  else
    BRText = string.format("%03d, %d %s, %s",AngleDegrees,distancenm,miles,vlow)
    BRTextTTS = string.format("%s, %d %s, %s",AngleDegText,distancenm,miles,vlow)
    if self.PathToGoogleKey then
      BRTextTTS = string.format("%s, %d %s, %s",AngleDegTextTTS,distancenm,miles,vlow)
    end
  end
  self:T(BRText,BRTextTTS)
  return BRText,BRTextTTS
end

--- [Internal] Get BR text for TTS - ie "Rock 214, 24 miles" and TTS "Rock 2 1 4, 24 miles"
-- @param #AWACS self
-- @param Core.Point#COORDINATE clustercoordinate
-- @return #string BRAText
-- @return #string BRATextTTS
function AWACS:_GetBRAfromBullsOrAO(clustercoordinate)
  self:T(self.lid.."_GetBRAfromBullsOrAO")
  local refcoord = self.AOCoordinate -- Core.Point#COORDINATE
  local BRAText = ""
  local BRATextTTS = ""
  -- get BR from AO
  local bullsname = self.AOName or "Rock"
  local stringbr, stringbrtts = self:_ToStringBR(refcoord,clustercoordinate)
  BRAText = string.format("%s %s",bullsname,stringbr)
  BRATextTTS = string.format("%s %s",bullsname,stringbrtts)
  self:T(BRAText,BRATextTTS)
  return BRAText,BRATextTTS
end

--- [Internal] Register Task for Group by GID
-- @param #AWACS self
-- @param #number GroupID ManagedGroup ID
-- @param #AWACS.TaskDescription Description Short Description Task Type
-- @param #string ScreenText Long task description for screen output
-- @param #table Object Object for Ops.Target#TARGET assignment
-- @param #AWACS.TaskStatus TaskStatus Status of this task
-- @param Ops.Auftrag#AUFTRAG Auftrag The Auftrag for this task if any
-- @param Ops.Intel#INTEL.Cluster Cluster Intel Cluster for this task
-- @param Ops.Intel#INTEL.Contact Contact Intel Contact for this task
-- @return #number TID Task ID created
function AWACS:_CreateTaskForGroup(GroupID,Description,ScreenText,Object,TaskStatus,Auftrag,Cluster,Contact)
   self:T(self.lid.."_CreateTaskForGroup "..GroupID .." Description: "..Description)
   
   local managedgroup = self.ManagedGrps[GroupID] -- #AWACS.ManagedGroup
   local task = {} -- #AWACS.ManagedTask
   self.ManagedTaskID = self.ManagedTaskID + 1
   task.TID = self.ManagedTaskID
   task.AssignedGroupID = GroupID
   task.Status = TaskStatus or AWACS.TaskStatus.ASSIGNED
   task.ToDo = Description
   task.Auftrag = Auftrag
   task.Cluster = Cluster
   task.Contact = Contact
   task.IsPlayerTask = managedgroup.IsPlayer
   task.IsUnassigned = TaskStatus == AWACS.TaskStatus.UNASSIGNED and false or true
  -- task.
   if Object and Object:IsInstanceOf("TARGET") then
    task.Target = Object
   else
    task.Target = TARGET:New(Object)
   end
   task.ScreenText = ScreenText
   if Description == AWACS.TaskDescription.ANCHOR or Description == AWACS.TaskDescription.REANCHOR then
    task.Target.Type = TARGET.ObjectType.ZONE
   end
   task.RequestedTimestamp = timer.getTime()
   
   self.ManagedTasks:Push(task,task.TID)

   managedgroup.HasAssignedTask = true
   managedgroup.CurrentTask = task.TID
   --managedgroup.TaskQueue:Push(task.TID)
  
   self:T({managedgroup})
   self.ManagedGrps[GroupID] = managedgroup

   return task.TID 
end 

--- [Internal] Read registered Task for Group by its ID
-- @param #AWACS self
-- @param #number GroupID ManagedGroup ID
-- @return #AWACS.ManagedTask Task or nil if n/e
function AWACS:_ReadAssignedTaskFromGID(GroupID)
   self:T(self.lid.."_GetAssignedTaskFromGID "..GroupID)
   local managedgroup = self.ManagedGrps[GroupID] -- #AWACS.ManagedGroup
   if managedgroup and managedgroup.HasAssignedTask and managedgroup.CurrentTask ~= 0 then
     local TaskID = managedgroup.CurrentTask
     if self.ManagedTasks:HasUniqueID(TaskID) then
      return self.ManagedTasks:ReadByID(TaskID)
     end
   end
   return nil
end

--- [Internal] Read assigned Group from a TaskID
-- @param #AWACS self
-- @param #number TaskID ManagedTask ID
-- @return #AWACS.ManagedGroup Group structure or nil if n/e
function AWACS:_ReadAssignedGroupFromTID(TaskID)
   self:T(self.lid.."_ReadAssignedGroupFromTID "..TaskID)
   if self.ManagedTasks:HasUniqueID(TaskID) then
    local task = self.ManagedTasks:ReadByID(TaskID) -- #AWACS.ManagedTask
    if task and task.AssignedGroupID and task.AssignedGroupID > 0 then
      return self.ManagedGrps[task.AssignedGroupID]
    end
   end
   return nil
end
 
--- [Internal] Create radio entry to tell players that CAP is on station in Anchor
-- @param #AWACS self
-- @param #number GID Group ID 
-- @return #AWACS self
function AWACS:_MessageAIReadyForTasking(GID)
  self:T(self.lid.."_MessageAIReadyForTasking")
  -- obtain group details
  if GID >0  and self.ManagedGrps[GID] then
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local GFCallsign = self:_GetCallSign(managedgroup.Group)
    local aionst = self.gettext:GetEntry("AIONSTATION",self.locale)
    local TextTTS = string.format(aionst,GFCallsign,self.callsigntxt,managedgroup.AnchorStackNo or 1,managedgroup.AnchorStackAngels or 25)
    self:_NewRadioEntry(TextTTS,TextTTS,GID,false,false,true,true)
  end
  return self
end

--- [Internal] Update Contact Tag
-- @param #AWACS self
-- @param #number CID Contact ID
-- @param #string Text Text to be used
-- @param #boolean TAC TAC Call done
-- @param #boolean MELD MELD Call done
-- @param #string TaskStatus Overwrite status with #AWACS.TaskStatus  Status
-- @return #AWACS self
function AWACS:_UpdateContactEngagementTag(CID,Text,TAC,MELD,TaskStatus)
  self:T(self.lid.."_UpdateContactEngagementTag")
  local text = Text or ""
  -- get contact
  local contact = self.Contacts:PullByID(CID) -- #AWACS.ManagedContact
  if contact then
    contact.EngagementTag = text
    contact.TACCallDone = TAC or false
    contact.MeldCallDone = MELD or false
    contact.Status = TaskStatus or AWACS.TaskStatus.UNASSIGNED
    self.Contacts:Push(contact,CID)
  end
  return self
end

--- [Internal] Check available tasks and status
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CheckTaskQueue()
  self:T(self.lid.."_CheckTaskQueue")
  local opentasks = 0
  local assignedtasks = 0
  
  -- update last known positions
  for _id,_managedgroup in pairs(self.ManagedGrps) do
    local group = _managedgroup -- #AWACS.ManagedGroup
    if group.Group and group.Group:IsAlive() then
      local coordinate = group.Group:GetCoordinate()
      if coordinate then
        local NewCoordinate = COORDINATE:New(0,0,0)
        group.LastKnownPosition = group.LastKnownPosition:UpdateFromCoordinate(coordinate)
        self.ManagedGrps[_id] = group
      end
    end
  end
  
  ----------------------------------------
  -- ANCHOR
  ----------------------------------------
  
  if self.ManagedTasks:IsNotEmpty() then
    opentasks = self.ManagedTasks:GetSize()
    self:T("Assigned Tasks: " .. opentasks)
    local taskstack = self.ManagedTasks:GetPointerStack()
    for _id,_entry in pairs(taskstack) do
      local data = _entry -- Utilities.FiFo#FIFO.IDEntry
      local entry = data.data -- #AWACS.ManagedTask
      local target = entry.Target -- Ops.Target#TARGET
      local description = entry.ToDo
      if description == AWACS.TaskDescription.ANCHOR or description == AWACS.TaskDescription.REANCHOR then
        self:T("Open Task ANCHOR/REANCHOR")
        -- see if we have reached the anchor zone
        local managedgroup = self.ManagedGrps[entry.AssignedGroupID] -- #AWACS.ManagedGroup
        if managedgroup then
          local group = managedgroup.Group
          if group and group:IsAlive() then
            local groupcoord = group:GetCoordinate()
            local zone = target:GetObject() -- Core.Zone#ZONE
            self:T({zone})
            if group:IsInZone(zone) then
              self:T("Open Task ANCHOR/REANCHOR success for GroupID "..entry.AssignedGroupID)
              -- made it
              target:Stop()
              -- add group to idle stack
              if managedgroup.IsAI then
                -- message AI on station
                self:_MessageAIReadyForTasking(managedgroup.GID)
              end -- end isAI
              managedgroup.HasAssignedTask = false
              self.ManagedGrps[entry.AssignedGroupID] = managedgroup
              -- pull task from OpenTasks
              self.ManagedTasks:PullByID(entry.TID)
            else --inzone
              -- not there yet
              self:T("Open Task ANCHOR/REANCHOR executing for GroupID "..entry.AssignedGroupID)
            end
          else
            -- group dead, pull task
            self.ManagedTasks:PullByID(entry.TID)
          end
        end
      
      ----------------------------------------
      -- INTERCEPT
      ----------------------------------------
        
      elseif description == AWACS.TaskDescription.INTERCEPT then
        -- DONE
        self:T("Open Tasks INTERCEPT")
        local taskstatus = entry.Status
        local targetstatus = entry.Target:GetState()
        
        if taskstatus == AWACS.TaskStatus.UNASSIGNED then
          -- thou shallst not be in this list!      
          self.ManagedTasks:PullByID(entry.TID)
          break
        end
        
        local managedgroup = self.ManagedGrps[entry.AssignedGroupID] -- #AWACS.ManagedGroup
        
        -- Check ranges for TAC and MELD
        -- postions relative to CAP position
        --[[
        local targetgrp = entry.Contact.group
        local position = entry.Contact.position or entry.Cluster.coordinate
        if targetgrp and targetgrp:IsAlive() and managedgroup then
          if position and managedgroup.Group and managedgroup.Group:IsAlive() then
            local grouposition = managedgroup.Group:GetCoordinate() or managedgroup.Group:GetCoordinate()
            local distance = 1000
            if grouposition then
              distance = grouposition:Get2DDistance(position)
              distance = UTILS.Round(UTILS.MetersToNM(distance),0)
            end        
            self:T("TAC/MELD distance check: "..distance.."NM!")
            if distance <= self.TacDistance and distance >= self.MeldDistance then
              -- TAC distance
              self:T("TAC distance: "..distance.."NM!")
              local Contact = self.Contacts:ReadByID(entry.Contact.CID)
              self:_TACRangeCall(entry.AssignedGroupID,Contact)
            elseif distance <= self.MeldDistance and distance >= self.ThreatDistance then
              -- MELD distance
              self:T("MELD distance: "..distance.."NM!")
              local Contact = self.Contacts:ReadByID(entry.Contact.CID)
              self:_MeldRangeCall(entry.AssignedGroupID,Contact)
            end
          end
        end
        --]]
        
        local auftrag = entry.Auftrag -- Ops.Auftrag#AUFTRAG
        local auftragstatus = "Not Known"
        if auftrag then
          auftragstatus = auftrag:GetState()
        end 
        local text = string.format("ID=%d | Status=%s | TargetState=%s | AuftragState=%s",entry.TID,taskstatus,targetstatus,auftragstatus)
        self:T(text)
        if auftrag then
          if auftrag:IsExecuting() then
            entry.Status = AWACS.TaskStatus.EXECUTING
          elseif auftrag:IsSuccess() then
            entry.Status = AWACS.TaskStatus.SUCCESS
          elseif auftrag:GetState() == AUFTRAG.Status.FAILED then 
            entry.Status = AWACS.TaskStatus.FAILED
          end 
          if targetstatus == "Dead" then
            entry.Status = AWACS.TaskStatus.SUCCESS
          elseif targetstatus == "Alive" and auftrag:IsOver() then
            entry.Status = AWACS.TaskStatus.FAILED
          end
        elseif entry.IsPlayerTask then
          -- Player task
          -- DONE
          if entry.Target:IsDead() or entry.Target:IsDestroyed() or entry.Target:CountTargets() == 0 then
            -- success!
            entry.Status = AWACS.TaskStatus.SUCCESS
          elseif entry.Target:IsAlive() then
            -- still alive
            -- out of zones?
            local targetpos = entry.Target:GetCoordinate()
            -- success == out of our controlled zones
            local outofzones = false
            self.RejectZoneSet:ForEachZone(
              function(Zone,Position)
                local zone = Zone -- Core.Zone#ZONE
                local pos = Position -- Core.Point#VEC2
                if pos and zone:IsVec2InZone(pos) then
                  -- crossed the border
                  outofzones = true
                end
              end,
              targetpos:GetVec2()
            )
            if not outofzones then
              outofzones = true
              self.ZoneSet:ForEachZone(
                function(Zone,Position)
                  local zone = Zone -- Core.Zone#ZONE
                  local pos = Position -- Core.Point#VEC2
                  if pos and zone:IsVec2InZone(pos) then
                    -- in any zone
                    outofzones = false
                  end
                end,
                targetpos:GetVec2()
              )
            end
            if outofzones then
              entry.Status = AWACS.TaskStatus.SUCCESS
            end
          end
        end
        
        if entry.Status == AWACS.TaskStatus.SUCCESS then
          self:T("Open Tasks INTERCEPT success for GroupID "..entry.AssignedGroupID)
          if managedgroup then
          
            self:_UpdateContactEngagementTag(managedgroup.ContactCID,"",true,true,AWACS.TaskStatus.SUCCESS)
            
            managedgroup.HasAssignedTask = false
            managedgroup.ContactCID = 0
            managedgroup.LastTasking = timer.getTime()
            
            if managedgroup.IsAI then
              managedgroup.CurrentAuftrag = 0
            else
              managedgroup.CurrentTask = 0
            end
            
            self.ManagedGrps[entry.AssignedGroupID] = managedgroup
            self.ManagedTasks:PullByID(entry.TID)
            
            self:__InterceptSuccess(1)
            self:__ReAnchor(5,managedgroup.GID)
          end
         
        elseif entry.Status == AWACS.TaskStatus.FAILED then
          self:T("Open Tasks INTERCEPT failed for GroupID "..entry.AssignedGroupID)
          if managedgroup then
            managedgroup.HasAssignedTask = false
            self:_UpdateContactEngagementTag(managedgroup.ContactCID,"",false,false,AWACS.TaskStatus.UNASSIGNED)
            managedgroup.ContactCID = 0
            managedgroup.LastTasking = timer.getTime()
            if managedgroup.IsAI then
              managedgroup.CurrentAuftrag = 0
            else
              managedgroup.CurrentTask = 0
            end
            if managedgroup.IsPlayer then
              entry.IsPlayerTask = false
            end 
            self.ManagedGrps[entry.AssignedGroupID] = managedgroup
            if managedgroup.Group:IsAlive() or (managedgroup.FlightGroup and managedgroup.FlightGroup:IsAlive()) then
              self:__ReAnchor(5,managedgroup.GID)
            end
          end
          -- remove         
          self.ManagedTasks:PullByID(entry.TID)
          self:__InterceptFailure(1)
        
        elseif entry.Status == AWACS.TaskStatus.REQUESTED then
          -- requested - player tasks only!
          self:T("Open Tasks INTERCEPT REQUESTED for GroupID "..entry.AssignedGroupID)
          local created = entry.RequestedTimestamp or timer.getTime() - 120
          local Tnow = timer.getTime()
          local Trunning = (Tnow-created) / 60 -- mins
          local text = string.format("Task TID %s Requested %d minutes ago.",entry.TID,Trunning)
          if Trunning > self.ReassignmentPause then
            -- reassign if player didn't react within 3 mins
            entry.Status = AWACS.TaskStatus.UNASSIGNED
            self.ManagedTasks:PullByID(entry.TID)
          end
          self:T(text)
        end
        
      ----------------------------------------
      -- VID/POLICE
      ----------------------------------------
        
      elseif description == AWACS.TaskDescription.VID then
       -- TODO - how to do this with AI?
       -- humans only ATM
          local managedgroup = self.ManagedGrps[entry.AssignedGroupID] -- #AWACS.ManagedGroup
          -- check we're alive
          if (not managedgroup) or (not managedgroup.Group:IsAlive()) then
            self.ManagedTasks:PullByID(entry.TID)
            return self
          end
          
          -- target dead or out of bounds?
          if entry.Target:IsDead() or entry.Target:IsDestroyed() or entry.Target:CountTargets() == 0 then
            -- success!
            entry.Status = AWACS.TaskStatus.SUCCESS
          elseif entry.Target:IsAlive() then
            -- still alive
            -- out of zones?
            self:T("Checking VID target out of bounds")
            local targetpos = entry.Target:GetCoordinate()
            -- success == out of our controlled zones
            local outofzones = false
            self.RejectZoneSet:ForEachZone(
              function(Zone,Position)
                local zone = Zone -- Core.Zone#ZONE
                local pos = Position -- Core.Point#VEC2
                if pos and zone:IsVec2InZone(pos) then
                  -- crossed the border
                  outofzones = true
                end
              end,
              targetpos:GetVec2()
            )
            if not outofzones then
              outofzones = true
              self.ZoneSet:ForEachZone(
                function(Zone,Position)
                  local zone = Zone -- Core.Zone#ZONE
                  local pos = Position -- Core.Point#VEC2
                  if pos and zone:IsVec2InZone(pos) then
                    -- in any zone
                    outofzones = false
                  end
                end,
                targetpos:GetVec2()
              )
            end
            if outofzones then
              entry.Status = AWACS.TaskStatus.SUCCESS
              self:T("Out of bounds - SUCCESS")
            end
          end
          
          if entry.Status == AWACS.TaskStatus.REQUESTED then
             -- requested - player tasks only!
            self:T("Open Tasks VID REQUESTED for GroupID "..entry.AssignedGroupID)
            local created = entry.RequestedTimestamp or timer.getTime() - 120
            local Tnow = timer.getTime()
            local Trunning = (Tnow-created) / 60 -- mins
            local text = string.format("Task TID %s Requested %d minutes ago.",entry.TID,Trunning)
            if Trunning > self.ReassignmentPause then
              -- reassign if player didn't react within 3 mins
              entry.Status = AWACS.TaskStatus.UNASSIGNED
              self.ManagedTasks:PullByID(entry.TID)
            end
            self:T(text)
          elseif entry.Status == AWACS.TaskStatus.ASSIGNED then
            self:T("Open Tasks VID ASSIGNED for GroupID "..entry.AssignedGroupID)
            -- check TAC/MELD ranges
            --[[
            local targetgrp = entry.Contact.group
            local position = entry.Contact.position or entry.Cluster.coordinate
            if targetgrp and targetgrp:IsAlive() and managedgroup then
              if position and managedgroup.Group and managedgroup.Group:IsAlive() then
                local grouposition = managedgroup.Group:GetCoordinate() or managedgroup.Group:GetCoordinate()
                local distance = 1000
                if grouposition then
                  distance = grouposition:Get2DDistance(position)
                  distance = UTILS.Round(UTILS.MetersToNM(distance),0)
                end        
                self:T("TAC/MELD distance check: "..distance.."NM!")
                if distance <= self.TacDistance and distance >= self.MeldDistance then
                  -- TAC distance
                  self:T("TAC distance: "..distance.."NM!")
                  local Contact = self.Contacts:ReadByID(entry.Contact.CID)
                  self:_TACRangeCall(entry.AssignedGroupID,Contact)
                elseif distance <= self.MeldDistance and distance >= self.ThreatDistance then
                  -- MELD distance
                  self:T("MELD distance: "..distance.."NM!")
                  local Contact = self.Contacts:ReadByID(entry.Contact.CID)
                  self:_MeldRangeCall(entry.AssignedGroupID,Contact)
                end
              end
            end
            --]]
          elseif entry.Status == AWACS.TaskStatus.SUCCESS then
            self:T("Open Tasks VID success for GroupID "..entry.AssignedGroupID)
            -- outcomes - player ID'd
            -- target dead or left zones handled above
            -- target ID'd --> if hostile, assign INTERCEPT TASK
            self.ManagedTasks:PullByID(entry.TID)
            local Contact = self.Contacts:ReadByID(entry.Contact.CID) -- #AWACS.ManagedContact
            if Contact and (Contact.IFF == AWACS.IFF.FRIENDLY or Contact.IFF == AWACS.IFF.NEUTRAL) then
              self:T("IFF outcome friendly/neutral for GroupID "..entry.AssignedGroupID)
              -- nothing todo, re-anchor
              if managedgroup then
                managedgroup.HasAssignedTask = false
                self:_UpdateContactEngagementTag(managedgroup.ContactCID,"",false,false,AWACS.TaskStatus.UNASSIGNED)
                managedgroup.ContactCID = 0
                managedgroup.LastTasking = timer.getTime()
                if managedgroup.IsAI then
                  managedgroup.CurrentAuftrag = 0
                else
                  managedgroup.CurrentTask = 0
                end
                if managedgroup.IsPlayer then
                  entry.IsPlayerTask = false
                end
                self.ManagedGrps[entry.AssignedGroupID] = managedgroup
                self:__ReAnchor(5,managedgroup.GID)
              end
            elseif Contact and Contact.IFF == AWACS.IFF.ENEMY then
              self:T("IFF outcome hostile for GroupID "..entry.AssignedGroupID)
              -- change to intercept
              entry.ToDo = AWACS.TaskDescription.INTERCEPT
              entry.Status = AWACS.TaskStatus.ASSIGNED
              local cname = Contact.TargetGroupNaming
              entry.ScreenText = string.format("Engage hostile %s group.",cname)
              self.ManagedTasks:Push(entry,entry.TID)
              local TextTTS = string.format("%s, %s. Engage hostile target!",managedgroup.CallSign,self.callsigntxt)
              self:_NewRadioEntry(TextTTS,TextTTS,managedgroup.GID,true,self.debug,true,false,true)
            elseif not Contact then
              self:T("IFF outcome target DEAD for GroupID "..entry.AssignedGroupID)
              -- nothing todo, re-anchor
              if managedgroup then
                managedgroup.HasAssignedTask = false
                self:_UpdateContactEngagementTag(managedgroup.ContactCID,"",false,false,AWACS.TaskStatus.UNASSIGNED)
                managedgroup.ContactCID = 0
                managedgroup.LastTasking = timer.getTime()
                if managedgroup.IsAI then
                  managedgroup.CurrentAuftrag = 0
                else
                  managedgroup.CurrentTask = 0
                end
                if managedgroup.IsPlayer then
                  entry.IsPlayerTask = false
                end
                self.ManagedGrps[entry.AssignedGroupID] = managedgroup
                if managedgroup.Group:IsAlive() or managedgroup.FlightGroup:IsAlive() then
                  self:__ReAnchor(5,managedgroup.GID)
                end
              end
            end
          elseif entry.Status == AWACS.TaskStatus.FAILED then
            -- outcomes - player unable/abort
            -- Player dead managed above
            -- Remove task
            self:T("Open Tasks VID failed for GroupID "..entry.AssignedGroupID)
            if managedgroup then
              managedgroup.HasAssignedTask = false
              self:_UpdateContactEngagementTag(managedgroup.ContactCID,"",false,false,AWACS.TaskStatus.UNASSIGNED)
              managedgroup.ContactCID = 0
              managedgroup.LastTasking = timer.getTime()
              if managedgroup.IsAI then
                managedgroup.CurrentAuftrag = 0
              else
                managedgroup.CurrentTask = 0
              end
              if managedgroup.IsPlayer then
                entry.IsPlayerTask = false
              end 
              self.ManagedGrps[entry.AssignedGroupID] = managedgroup
              if managedgroup.Group:IsAlive() or managedgroup.FlightGroup:IsAlive() then
                self:__ReAnchor(5,managedgroup.GID)
              end
            end
            -- remove          
            self.ManagedTasks:PullByID(entry.TID)
            self:__InterceptFailure(1)
          end
      end
      
    end
  end
  
  return self
end

--- [Internal] Write stats to log
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_LogStatistics()
  self:T(self.lid.."_LogStatistics")
  local text = string.gsub(UTILS.OneLineSerialize(self.MonitoringData),",","\n")
  local text = string.gsub(text,"{","\n")
  local text = string.gsub(text,"}","")
  local text = string.gsub(text,"="," = ")
  self:T(text)
  if self.MonitoringOn then
    MESSAGE:New(text,20,"AWACS",false):ToAll()
  end
  return self 
end

--- [User] Add another AirWing for AI CAP Flights under management
-- @param #AWACS self
-- @param Ops.Airwing#AIRWING AirWing The AirWing to (also) obtain CAP flights from
-- @param Core.Zone#ZONE_RADIUS Zone (optional) This AirWing has it's own station zone, AI CAP will be send there
-- @return #AWACS self
function AWACS:AddCAPAirWing(AirWing,Zone)
  self:T(self.lid.."AddCAPAirWing")
  if AirWing then
    AirWing:SetUsingOpsAwacs(self)
    local distance = self.AOCoordinate:Get2DDistance(AirWing:GetCoordinate())
    if Zone then
      -- create AnchorStack
        local stackscreated = self.AnchorStacks:GetSize()
        if stackscreated == self.AnchorMaxAnchors  then
          -- only create self.AnchorMaxAnchors Anchors
          self:E(self.lid.."Max number of stacks already created!")
        else
          local AnchorStackOne = {} -- #AWACS.AnchorData
          AnchorStackOne.AnchorBaseAngels = self.AnchorBaseAngels
          AnchorStackOne.Anchors = FIFO:New() -- Utilities.FiFo#FIFO
          AnchorStackOne.AnchorAssignedID = FIFO:New() -- Utilities.FiFo#FIFO
          
          local newname = Zone:GetName()
                    
          for i=1,self.AnchorMaxStacks do
            AnchorStackOne.Anchors:Push((i-1)*self.AnchorStackDistance+self.AnchorBaseAngels)
          end
          
          local newsubname = AWACS.AnchorNames[stackscreated+1] or tostring(stackscreated+1)
          newname = Zone:GetName() .. "-"..newsubname
          AnchorStackOne.StationZone = Zone
          AnchorStackOne.StationZoneCoordinate = Zone:GetCoordinate()
          AnchorStackOne.StationZoneCoordinateText = Zone:GetCoordinate():ToStringLLDDM()
          AnchorStackOne.StationName = newname
          --push to AnchorStacks
          if self.debug then
            AnchorStackOne.StationZone:DrawZone(self.coalition,{0,0,1},1,{0,0,1},0.2,5,true)
            local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
            if self.AllowMarkers then
              AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
            end
          else
            local stationtag = string.format("Station: %s\nCoordinate: %s",newname,self.StationZone:GetCoordinate():ToStringLLDDM())
            if self.AllowMarkers then
              AnchorStackOne.AnchorMarker=MARKER:New(AnchorStackOne.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
            end
          end
          self.AnchorStacks:Push(AnchorStackOne,newname)
          AirWing.HasOwnStation = true
          AirWing.StationName = newname
        end
    end
    self.CAPAirwings:Push(AirWing,distance)
  end
  return self
end

--- [Internal] Announce a new contact
-- @param #AWACS self
-- @param #AWACS.ManagedContact Contact
-- @param #boolean IsNew Is a new contact
-- @param Wrapper.Group#GROUP Group Announce to Group if not nil
-- @param #boolean IsBogeyDope If true, this is a bogey dope announcement
-- @param #string Tag Tag name for this contact. Alpha, Brave, Charlie ... 
-- @param #boolean IsPopup This is a pop-up group
-- @param #string ReportingName The NATO code reporting name for the contact, e.g. "Foxbat". "Bogey" if unknown.
-- @param #boolean Tactical
-- @return #AWACS self
function AWACS:_AnnounceContact(Contact,IsNew,Group,IsBogeyDope,Tag,IsPopup,ReportingName,Tactical)
  self:T(self.lid.."_AnnounceContact")
  -- do we have a group to talk to?
  local tag = ""
  local Tag = Tag
  local CID = 0
  if not Tag then
    -- injected data available?
    CID = Contact.CID or 0
    Tag = Contact.TargetGroupNaming or ""
  end
  if self.NoGroupTags then
    Tag = nil
  end
  local isGroup = false
  local GID = 0
  local grpcallsign = "Ghost 1"
  if Group and Group:IsAlive() then
    GID, isGroup,grpcallsign = self:_GetManagedGrpID(Group)
    self:T("GID="..GID.." CheckedIn = "..tostring(isGroup))
  end

  local cluster = Contact.Cluster
  local intel = self.intel -- Ops.Intel#INTEL
  
  local size = self.intel:ClusterCountUnits(cluster)
  local threatsize, threatsizetext = self:_GetBlurredSize(size)

  local clustercoordinate = Contact.Cluster.coordinate or Contact.Contact.position
  
  local heading = Contact.Contact.group:GetHeading() or self.intel:CalcClusterDirection(cluster)
  
  clustercoordinate:SetHeading(Contact.Contact.group:GetHeading())
  
  local BRAfromBulls, BRAfromBullsTTS = self:_GetBRAfromBullsOrAO(clustercoordinate)
   
  self:T(BRAfromBulls)
  self:T(BRAfromBullsTTS)
  BRAfromBulls=BRAfromBulls.."."
  BRAfromBullsTTS=BRAfromBullsTTS.."."

  if isGroup then
    BRAfromBulls = clustercoordinate:ToStringBRAANATO(Group:GetCoordinate(),true,true)
    BRAfromBullsTTS = string.gsub(BRAfromBulls,"BRAA","brah")
    BRAfromBullsTTS = string.gsub(BRAfromBullsTTS,"BRA","brah")
    if self.PathToGoogleKey then
      BRAfromBullsTTS = clustercoordinate:ToStringBRAANATO(Group:GetCoordinate(),true,true,true,false,true)
    end
  end
  
  local BRAText = ""
  local TextScreen = ""
  
  if isGroup then
    BRAText = string.format("%s, %s.",grpcallsign,self.callsigntxt)
    TextScreen = string.format("%s, %s.",grpcallsign,self.callsigntxt)
  else
    BRAText = string.format("%s.",self.callsigntxt)
    TextScreen = string.format("%s.",self.callsigntxt)
  end
  
  local newgrp = self.gettext:GetEntry("NEWGROUP",self.locale)
  local grptxt = self.gettext:GetEntry("GROUP",self.locale)
  local GRPtxt = self.gettext:GetEntry("GROUPCAP",self.locale)
  local popup = self.gettext:GetEntry("POPUP",self.locale)
  
  if IsNew and self.PlayerGuidance then
    BRAText = string.format("%s %s.",BRAText,newgrp)
    TextScreen = string.format("%s %s.",TextScreen,newgrp)
  elseif IsPopup then
    BRAText = string.format("%s %s %s.",BRAText,popup,grptxt)
    TextScreen = string.format("%s %s %s.",TextScreen,popup,grptxt)
  elseif IsBogeyDope and Tag and Tag ~= "" then
    BRAText = string.format("%s %s %s.",BRAText,Tag,grptxt)
    TextScreen = string.format("%s %s %s.",TextScreen,Tag,grptxt)
  else
    BRAText = string.format("%s %s.",BRAText,GRPtxt)
    TextScreen = string.format("%s %s.",TextScreen,GRPtxt)
  end
  
  if not IsBogeyDope then
    if Tag and Tag ~= "" then
      BRAText = BRAText .. " "..Tag.."."
      TextScreen = TextScreen .. " "..Tag.."."
    end
  end
  
  if threatsize > 1 then
    BRAText = BRAText .. " "..BRAfromBullsTTS.." "..threatsizetext.."."
    TextScreen = TextScreen .. " "..BRAfromBulls.." "..threatsizetext.."."
  else
    BRAText = BRAText .. " "..BRAfromBullsTTS
    TextScreen = TextScreen .. " "..BRAfromBulls
  end
  
  if self.ModernEra then
    local high = self.gettext:GetEntry("HIGH",self.locale)
    local vfast = self.gettext:GetEntry("VERYFAST",self.locale)
    local fast = self.gettext:GetEntry("FAST",self.locale)
    -- Platform
    if ReportingName and ReportingName ~= "Bogey" then
      ReportingName = string.gsub(ReportingName,"_"," ")
      BRAText = BRAText .. " "..ReportingName.."."
      TextScreen = TextScreen .. " "..ReportingName.."."
    end
    -- High - > 40k feet
    local height = Contact.Contact.group:GetHeight()
    local height = UTILS.Round(UTILS.MetersToFeet(height)/1000,0) -- e.g, 25
    if height >= 40 then
      BRAText = BRAText .. high
      TextScreen = TextScreen .. high
    end
    -- Fast (>600kn) or Very fast (>900kn)
    local speed = Contact.Contact.group:GetVelocityKNOTS()
    if speed > 900 then
      BRAText = BRAText .. vfast
      TextScreen = TextScreen .. vfast
    elseif speed >= 600 and speed <= 900 then
      BRAText = BRAText .. fast
      TextScreen = TextScreen .. fast
    end
  end
  
  BRAText = string.gsub(BRAText,"BRAA","brah")
  BRAText = string.gsub(BRAText,"BRA","brah")
  
  local prio = IsNew or IsBogeyDope
  self:_NewRadioEntry(BRAText,TextScreen,GID,isGroup,true,IsNew,false,prio,Tactical)

  return self
end

--- [Internal] Check for alive OpsGroup from Mission OpsGroups table
-- @param #AWACS self
-- @param #table OpsGroups
-- @return Ops.OpsGroup#OPSGROUP or nil
function AWACS:_GetAliveOpsGroupFromTable(OpsGroups)
  self:T(self.lid.."_GetAliveOpsGroupFromTable")
  local handback = nil 
  for _,_OG in pairs(OpsGroups or {}) do
    local OG = _OG -- Ops.OpsGroup#OPSGROUP
    if OG and OG:IsAlive() then
      handback = OG
      break
    end
  end 
  return handback
end

--- [Internal] Clean up mission stack
-- @param #AWACS self
-- @return #number CAPMissions
-- @return #number Alert5Missions
-- @return #number InterceptMissions
function AWACS:_CleanUpAIMissionStack()
  self:T(self.lid.."_CleanUpAIMissionStack")
  
  local CAPMissions = 0
  local Alert5Missions = 0
  local InterceptMissions = 0
  
  local MissionStack = FIFO:New()
  
  self:T("Checking MissionStack")
  for _,_mission in pairs(self.CatchAllMissions) do
    -- looking for missions of type CAP and ALERT5
    local mission = _mission -- Ops.Auftrag#AUFTRAG
    local type = mission:GetType()
    if type == AUFTRAG.Type.ALERT5 and mission:IsNotOver() then
      MissionStack:Push(mission,mission.auftragsnummer)
      Alert5Missions = Alert5Missions + 1
    elseif type == AUFTRAG.Type.CAP and mission:IsNotOver() then
      MissionStack:Push(mission,mission.auftragsnummer)
      CAPMissions = CAPMissions + 1
    elseif type == AUFTRAG.Type.INTERCEPT and mission:IsNotOver() then
      MissionStack:Push(mission,mission.auftragsnummer)
      InterceptMissions = InterceptMissions + 1
    end
  end
  
  self.AICAPMissions = nil
  self.AICAPMissions = MissionStack
  
  return CAPMissions, Alert5Missions, InterceptMissions
  
end

function AWACS:_ConsistencyCheck()
  self:T(self.lid.."_ConsistencyCheck")
  if self.debug then
    self:T("CatchAllMissions")
    local catchallm = {}
    local report1 = REPORT:New("CatchAll")
    report1:Add("====================")
    report1:Add("CatchAllMissions")
    report1:Add("====================")
    for _,_mission in pairs(self.CatchAllMissions) do
      local mission = _mission -- Ops.Auftrag#AUFTRAG
      local nummer = mission.auftragsnummer or 0
      local type = mission:GetType()
      local state = mission:GetState()
      local FG = mission:GetOpsGroups()
      local OG = self:_GetAliveOpsGroupFromTable(FG)
      local OGName = "UnknownFromMission"
      if OG then
        OGName=OG:GetName()
      end
      report1:Add(string.format("Auftrag Nr %d Type %s State %s FlightGroup %s",nummer,type,state,OGName))
      if mission:IsNotOver() then
        catchallm[#catchallm+1] = mission
      end
    end
    
    self.CatchAllMissions = nil
    self.CatchAllMissions = catchallm
    
    local catchallfg = {}
    
    self:T("CatchAllFGs")
    report1:Add("====================")
    report1:Add("CatchAllFGs")
    report1:Add("====================")
    for _,_fg in pairs(self.CatchAllFGs) do
      local FG = _fg -- Ops.FlightGroup#FLIGHTGROUP
      local mission = FG:GetMissionCurrent()
      local OGName = FG:GetName() or "UnknownFromFG"
      local nummer = 0
      local type = "No Type"
      local state = "None"
      if mission then
        type = mission:GetType()
        nummer = mission.auftragsnummer or 0
        state = mission:GetState()
      end
      report1:Add(string.format("Auftrag Nr %d Type %s State %s FlightGroup %s",nummer,type,state,OGName))
      if FG:IsAlive() then
        catchallfg[#catchallfg+1] = FG
      end
    end
    report1:Add("====================")
    self:T(report1:Text())
    
    self.CatchAllFGs = nil
    self.CatchAllFGs = catchallfg
    
  end
  return self
end

--- [Internal] Check Enough AI CAP on Station
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CheckAICAPOnStation()
  self:T(self.lid.."_CheckAICAPOnStation")
  
  self:_ConsistencyCheck()
  
  local capmissions, alert5missions, interceptmissions = self:_CleanUpAIMissionStack()
  self:T("CAP="..capmissions.." ALERT5="..alert5missions.." Requested="..self.AIRequested)
  
  if self.MaxAIonCAP > 0 then
    
    local onstation = capmissions + alert5missions
    
    if capmissions > self.MaxAIonCAP then
      -- too many, send one home
      self:T(string.format("*** Onstation %d > MaxAIOnCAP %d",onstation,self.MaxAIonCAP))
      local mission = self.AICAPMissions:Pull() -- Ops.Auftrag#AUFTRAG
      local Groups = mission:GetOpsGroups()
      local OpsGroup = self:_GetAliveOpsGroupFromTable(Groups)
      local GID,checkedin = self:_GetManagedGrpID(OpsGroup)
      mission:__Cancel(30)
      self.AIRequested = self.AIRequested - 1
      if checkedin then
        self:_CheckOut(OpsGroup,GID)
      end
    end
    
    -- control number of AI CAP Flights
    if capmissions < self.MaxAIonCAP and alert5missions < self.MaxAIonCAP+2 then
      -- not enough
      local AnchorStackNo,free = self:_GetFreeAnchorStack()
      if free then
        -- create Alert5 and assign to ONE of our AWs
        -- TODO better selection due to resource shortage?
        local mission = AUFTRAG:NewALERT5(AUFTRAG.Type.CAP)
        self.CatchAllMissions[#self.CatchAllMissions+1] = mission
        local availableAWS = self.CAPAirwings:Count()
        local AWS = self.CAPAirwings:GetDataTable()
        -- round robin
        self.AIRequested = self.AIRequested + 1
        local selectedAW = AWS[(((self.AIRequested-1) % availableAWS)+1)]
        selectedAW:AddMission(mission)    
        self:T("CAP="..capmissions.." ALERT5="..alert5missions.." Requested="..self.AIRequested)
      end
    end
    
    -- Check CAP Mission states
    if onstation > 0 and capmissions < self.MaxAIonCAP then
      local missions = self.AICAPMissions:GetDataTable()
      -- get mission type and state
      for _,_Mission in pairs(missions) do

        local mission = _Mission -- Ops.Auftrag#AUFTRAG
        self:T("Looking at AuftragsNr " .. mission.auftragsnummer)
        local type = mission:GetType()
        local state = mission:GetState()

        if type == AUFTRAG.Type.ALERT5 then
          -- parked up for CAP
          local OpsGroups = mission:GetOpsGroups()
          local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups)
          local FGstate = mission:GetGroupStatus(OpsGroup)
          if OpsGroup then
             FGstate = OpsGroup:GetState()
             self:T("FG Object in state: " .. FGstate)
          end
          -- FG ready?

          if OpsGroup and (FGstate == "Parking" or FGstate == "Cruising") then
            -- has this group checked in already? Avoid double tasking
            local GID, CheckedInAlready = self:_GetManagedGrpID(OpsGroup:GetGroup())
            if not CheckedInAlready then
              self:_SetAIROE(OpsGroup,OpsGroup:GetGroup())
              self:_CheckInAI(OpsGroup,OpsGroup:GetGroup(),mission.auftragsnummer)
            end
          end
        end
      end
    end
    
    -- cycle mission status
    if onstation > 0 then
      local report = REPORT:New("CAP Mission Status")
      report:Add("===============")
      --local missionIDs = self.AICAPMissions:GetIDStackSorted()
      local missions = self.AICAPMissions:GetDataTable()
      local i = 1
      for _,_Mission in pairs(missions) do 
        local mission = _Mission -- Ops.Auftrag#AUFTRAG
        if mission then
          i = i + 1
          report:Add(string.format("Entry %d",i))
          report:Add(string.format("Mission No %d",mission.auftragsnummer))
          report:Add(string.format("Mission Type %s",mission:GetType()))
          report:Add(string.format("Mission State %s",mission:GetState()))
          local OpsGroups = mission:GetOpsGroups()
          local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
          if OpsGroup then
            local OpsName = OpsGroup:GetName() or "Unknown"
            local found,GID,OpsCallSign = self:_GetGIDFromGroupOrName(OpsGroup)
            report:Add(string.format("Mission FG %s",OpsName))
            report:Add(string.format("Callsign %s",OpsCallSign))
            report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
          else
            report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
          end
          report:Add(string.format("Target Type %s",mission:GetTargetType()))
        end
        report:Add("===============") 
      end
      if self.debug then
        self:I(report:Text())
      end    
    end
  end
  return self
end

--- [Internal] Set ROE for AI CAP
-- @param #AWACS self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup
-- @param Wrapper.Group#GROUP Group
-- @return #AWACS self
function AWACS:_SetAIROE(FlightGroup,Group)
  self:T(self.lid.."_SetAIROE")
  local ROE = self.AwacsROE or AWACS.ROE.POLICE
  local ROT = self.AwacsROT or AWACS.ROT.PASSIVE
  
  -- TODO adjust to AWACS set ROE
  -- for the time being set to be defensive
  Group:OptionAlarmStateGreen()
  Group:OptionECM_OnlyLockByRadar()
  Group:OptionROEHoldFire()
  Group:OptionROTEvadeFire()
  Group:OptionRTBBingoFuel(true)
  Group:OptionKeepWeaponsOnThreat()
  local callname = self.AICAPCAllName or CALLSIGN.Aircraft.Colt
  self.AICAPCAllNumber = self.AICAPCAllNumber + 1 
  Group:CommandSetCallsign(callname,math.fmod(self.AICAPCAllNumber,9))
  -- FG level
  FlightGroup:SetDefaultAlarmstate(AI.Option.Ground.val.ALARM_STATE.GREEN)
  FlightGroup:SetDefaultCallsign(callname,math.fmod(self.AICAPCAllNumber,9))
  if ROE == AWACS.ROE.POLICE or ROE == AWACS.ROE.VID then
    FlightGroup:SetDefaultROE(ENUMS.ROE.WeaponHold)
  elseif ROE == AWACS.ROE.IFF then
    FlightGroup:SetDefaultROE(ENUMS.ROE.ReturnFire)
  elseif ROE == AWACS.ROE.BVR then
    FlightGroup:SetDefaultROE(ENUMS.ROE.OpenFire)
  end
  if ROT == AWACS.ROT.BYPASSESCAPE or ROT == AWACS.ROT.PASSIVE then
    FlightGroup:SetDefaultROT(ENUMS.ROT.PassiveDefense)
  elseif ROT == AWACS.ROT.OPENFIRE or ROT == AWACS.ROT.RETURNFIRE then
    FlightGroup:SetDefaultROT(ENUMS.ROT.BypassAndEscape)
  elseif ROT == AWACS.ROT.EVADE then
    FlightGroup:SetDefaultROT(ENUMS.ROT.EvadeFire)
  end
  FlightGroup:SetFuelLowRTB(true)
  FlightGroup:SetFuelLowThreshold(0.2)
  FlightGroup:SetEngageDetectedOff()
  FlightGroup:SetOutOfAAMRTB(true)
  return self
end

--- [Internal] TAC Range Call to Pilot
-- @param #AWACS self
-- @param #number GID GID
-- @param #AWACS.ManagedContact Contact
-- @return #AWACS self
function AWACS:_TACRangeCall(GID,Contact)
  self:T(self.lid.."_TACRangeCall")
  -- AIC: “Enforcer 11, single group, 30 miles.”
  if not Contact then return self end
  local pilotcallsign = self:_GetCallSign(nil,GID) 
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local contact = Contact.Contact -- Ops.Intel#INTEL.Contact
  local contacttag = Contact.TargetGroupNaming
  local name = managedgroup.GroupName
  if contact then --and not Contact.TACCallDone then
    local position = contact.position -- Core.Point#COORDINATE
    if position then     
      local distance = position:Get2DDistance(managedgroup.Group:GetCoordinate())
      distance = UTILS.Round(UTILS.MetersToNM(distance)) -- 30nm - hopefully
      local grptxt = self.gettext:GetEntry("GROUP",self.locale)
      local miles = self.gettext:GetEntry("MILES",self.locale)
      local text = string.format("%s. %s. %s %s, %d %s.",self.callsigntxt,pilotcallsign,contacttag,grptxt,distance,miles)
      if not self.TacticalSubscribers[name] then
        self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true)
      end
      self:_UpdateContactEngagementTag(Contact.CID,Contact.EngagementTag,true,false,AWACS.TaskStatus.EXECUTING)
      if GID and GID ~= 0 then
        --local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
        if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
          if self.TacticalSubscribers[name] then
            self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true,true)
          end
        end
      end
    end
  end
  return self
end

--- [Internal] Meld Range Call to Pilot
-- @param #AWACS self
-- @param #number GID GID
-- @param #AWACS.ManagedContact Contact
-- @return #AWACS self
function AWACS:_MeldRangeCall(GID,Contact)
  self:T(self.lid.."_MeldRangeCall")
  if not Contact then return self end
  -- AIC: “Heat 11, single group, BRAA 089/28, 32 thousand, hot, hostile, crow.”
  local pilotcallsign = self:_GetCallSign(nil,GID) 
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local flightpos = managedgroup.Group:GetCoordinate()
  local contact = Contact.Contact -- Ops.Intel#INTEL.Contact
  local contacttag = Contact.TargetGroupNaming or "Bogey"
  local name = managedgroup.GroupName
  if contact then --and not Contact.MeldCallDone then
    local position = contact.position -- Core.Point#COORDINATE
    if position then
      local BRATExt = ""
      if self.PathToGoogleKey then     
        BRATExt = position:ToStringBRAANATO(flightpos,false,false,true,false,true)
      else
        BRATExt = position:ToStringBRAANATO(flightpos,false,false)
      end
      local grptxt = self.gettext:GetEntry("GROUP",self.locale)
      local text = string.format("%s. %s. %s %s, %s",self.callsigntxt,pilotcallsign,contacttag,grptxt,BRATExt)
      if not self.TacticalSubscribers[name] then
        self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true)
      end
      self:_UpdateContactEngagementTag(Contact.CID,Contact.EngagementTag,true,true,AWACS.TaskStatus.EXECUTING)
      if GID and GID ~= 0 then
        --local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
        if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
          local name = managedgroup.GroupName
          if self.TacticalSubscribers[name] then
            self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true,true)
          end
        end
      end
    end
  end
  return self
end

--- [Internal] Threat Range Call to Pilot
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_ThreatRangeCall(GID,Contact)
  self:T(self.lid.."_ThreatRangeCall")
  if not Contact then return self end
  -- AIC: “Enforcer 11 12, east group, THREAT, BRAA 260/15, 29 thousand, hot, hostile, robin.”
  local pilotcallsign = self:_GetCallSign(nil,GID) 
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local flightpos = managedgroup.Group:GetCoordinate() or managedgroup.LastKnownPosition
  local contact = Contact.Contact -- Ops.Intel#INTEL.Contact
  local contacttag = Contact.TargetGroupNaming or "Bogey"
  local name = managedgroup.GroupName
  local IsSub = self.TacticalSubscribers[name] and true or false
  if contact then
    local position = contact.position or contact.group:GetCoordinate() -- Core.Point#COORDINATE
    if position then     
      local BRATExt = ""
      if self.PathToGoogleKey then     
        BRATExt = position:ToStringBRAANATO(flightpos,false,false,true,false,true)
      else
        BRATExt = position:ToStringBRAANATO(flightpos,false,false)
      end
      local grptxt = self.gettext:GetEntry("GROUP",self.locale)
      local thrt = self.gettext:GetEntry("THREAT",self.locale)
      local text = string.format("%s. %s. %s %s, %s. %s",self.callsigntxt,pilotcallsign,contacttag,grptxt, thrt, BRATExt)
      -- DONE MS TTS - fix spelling out B-R-A in this case
      if string.find(text,"BRAA",1,true) then
        text = string.gsub(text,"BRAA","brah")
      elseif string.find(text,"BRA",1,true) then
       text = string.gsub(text,"BRA","brah")
      end
      if IsSub == false then
        self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true)
      end
      if GID and GID ~= 0 then
        --local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
        if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
          local name = managedgroup.GroupName
          if self.TacticalSubscribers[name] then
            self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true,true)
          end
        end
      end
    end
  end
  return self
end

--- [Internal] Merged Call to Pilot
-- @param #AWACS self
-- @param #number GID
-- @return #AWACS self
function AWACS:_MergedCall(GID)
  self:T(self.lid.."_MergedCall")
  -- AIC: “Enforcer, mergedb”
  local pilotcallsign = self:_GetCallSign(nil,GID) 
  local merge = self.gettext:GetEntry("MERGED",self.locale)  
  local text = string.format("%s. %s. %s.",self.callsigntxt,pilotcallsign,merge)
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local name
  if managedgroup then
    name = managedgroup.GroupName or "none"
  end
  if not self.TacticalSubscribers[name] then
    self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true)
  end
  if GID and GID ~= 0 then
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then    
      if self.TacticalSubscribers[name] then
        self:_NewRadioEntry(text,text,GID,true,self.debug,true,false,true,true)
      end
    end
  end
  return self
end

--- [Internal] Assign a Pilot to a target
-- @param #AWACS self
-- @param #table Pilots Table of #AWACS.ManagedGroup Pilot 
-- @param Utilities.FiFo#FIFO Targets FiFo of #AWACS.ManagedContact Targets
-- @return #AWACS self 
function AWACS:_AssignPilotToTarget(Pilots,Targets)
  self:T(self.lid.."_AssignPilotToTarget")
  
  local inreach = false
  local Pilot = nil -- #AWACS.ManagedGroup
  

  local closest = UTILS.NMToMeters(self.maxassigndistance+1)
  local targets = Targets:GetDataTable()
  local Target = nil
  
  for _,_target in pairs(targets) do
      -- Check Distance
    local targetgroupcoord = _target.Contact.position
    -- get closest pilot from target    
    for _,_Pilot in pairs(Pilots) do
      local pilotcoord = _Pilot.Group:GetCoordinate()
      local targetdist = targetgroupcoord:Get2DDistance(pilotcoord)
      if UTILS.MetersToNM(targetdist) < self.maxassigndistance and targetdist < closest then
        self:T(string.format("%sTarget distance %d! Assignment %s!",self.lid,UTILS.Round(UTILS.MetersToNM(targetdist),0),_Pilot.CallSign))
        inreach = true
        closest = targetdist
        Pilot = _Pilot
        Target = _target
        Targets:PullByID(_target.CID)
        break
      else
        self:T(self.lid .. "Target distance > "..self.maxassigndistance.."NM! No Assignment!")
      end
    end
  end
  
  -- DONE Check Human assignment working
  if inreach and Pilot and Pilot.IsPlayer then
     local callsign = Pilot.CallSign
     -- update pilot TaskSheet
    self.ManagedTasks:PullByID(Pilot.CurrentTask)
    
    Pilot.HasAssignedTask = true
    local TargetPosition = Target.Target:GetCoordinate()
    local PlayerPositon = Pilot.LastKnownPosition
    local TargetAlt = Target.Contact.altitude or Target.Cluster.altitude or Target.Contact.group:GetAltitude()
    local TargetDirections, TargetDirectionsTTS = self:_ToStringBRA(PlayerPositon,TargetPosition,TargetAlt)
    local ScreenText = ""
    local TaskType = AWACS.TaskDescription.INTERCEPT
    if self.AwacsROE == AWACS.ROE.POLICE or self.AwacsROE == AWACS.ROE.VID then
      local interc = self.gettext:GetEntry("SCREENVID",self.locale) 
      ScreenText = string.format(interc,Target.TargetGroupNaming)
      TaskType = AWACS.TaskDescription.VID
    else
      local interc = self.gettext:GetEntry("SCREENINTER",self.locale) 
      ScreenText = string.format(interc,Target.TargetGroupNaming)
    end
    Pilot.CurrentTask = self:_CreateTaskForGroup(Pilot.GID,TaskType,ScreenText,Target.Target,AWACS.TaskStatus.REQUESTED,nil,Target.Cluster,Target.Contact)

    Pilot.ContactCID = Target.CID
    
    -- update managed group
    self.ManagedGrps[Pilot.GID] = Pilot
    
    -- Update Contact Status
    Target.LinkedTask = Pilot.CurrentTask
    Target.LinkedGroup = Pilot.GID
    Target.Status = AWACS.TaskStatus.REQUESTED
    local targeted = self.gettext:GetEntry("ENGAGETAG",self.locale) 
    Target.EngagementTag = string.format(targeted,Pilot.CallSign)
    
    self.Contacts:PullByID(Target.CID)
    self.Contacts:Push(Target,Target.CID)
    
    local reqcomm = self.gettext:GetEntry("REQCOMMIT",self.locale)
    local text = string.format(reqcomm, self.callsigntxt,Target.TargetGroupNaming,TargetDirectionsTTS,Pilot.CallSign)
    local textScreen = string.format(reqcomm, self.callsigntxt,Target.TargetGroupNaming,TargetDirections,Pilot.CallSign)
    
    self:_NewRadioEntry(text,textScreen,Pilot.GID,true,self.debug,true,false,true)
    
  elseif inreach and Pilot and Pilot.IsAI then
    -- Target information
    local callsign = Pilot.CallSign
    local FGStatus = Pilot.FlightGroup:GetState()
    self:T("Pilot AI Callsign: " .. callsign)
    self:T("Pilot FG State: " .. FGStatus)
    local targetstatus = Target.Target:GetState()
    self:T("Target State: " .. targetstatus)
 
    --
    local currmission = Pilot.FlightGroup:GetMissionCurrent()
    if currmission then
      self:T("Current Mission: " .. currmission:GetType())
    end
    -- create one intercept Auftrag and one to return to CAP post this one
    local ZoneSet = self.ZoneSet
    local RejectZoneSet = self.RejectZoneSet
    
    local intercept = AUFTRAG:NewINTERCEPT(Target.Target)
    intercept:SetWeaponExpend(AI.Task.WeaponExpend.ALL)
    intercept:SetWeaponType(ENUMS.WeaponFlag.Auto)
    intercept:SetMissionRange(self.MaxMissionRange)
    -- TODO 
    -- now this is going to be interesting...
    -- Check if the target left the "hot" area or is dead already
    intercept:AddConditionSuccess(
      function(target,zoneset,rzoneset)
       -- BASE:I("AUFTRAG Condition Succes Eval Running")
        local success = true
        local target = target -- Ops.Target#TARGET
        if target:IsDestroyed() or target:IsDead() or target:CountTargets() == 0 then return true end
        local tgtcoord = target:GetCoordinate()
        local tgtvec2 = nil
        if tgtcoord then
          tgtvec2 = tgtcoord:GetVec2()
        end
        local zones = zoneset -- Core.Set#SET_ZONE
        local rzones = rzoneset -- Core.Set#SET_ZONE
        if tgtvec2 then
          zones:ForEachZone(
            function(zone)
              if zone:IsVec2InZone(tgtvec2) then
                success = false
              end
            end
          )
          rzones:ForEachZone(
            function(zone)
              if zone:IsVec2InZone(tgtvec2) then
                success = true
              end
            end
          )
        end
        return success
      end,
      Target.Target,
      ZoneSet,
      RejectZoneSet
    )
    
    Pilot.FlightGroup:AddMission(intercept)    
    
    local Angels = Pilot.AnchorStackAngels or 25
    Angels = Angels * 1000
    local AnchorSpeed = self.CapSpeedBase or 270
    AnchorSpeed = UTILS.KnotsToAltKIAS(AnchorSpeed,Angels)
    local Anchor = self.AnchorStacks:ReadByPointer(Pilot.AnchorStackNo) -- #AWACS.AnchorData
    local capauftrag = AUFTRAG:NewCAP(Anchor.StationZone,Angels,AnchorSpeed,Anchor.StationZoneCoordinate,0,15,{})
    capauftrag:SetMissionRange(self.MaxMissionRange)
    capauftrag:SetTime(nil,((self.CAPTimeOnStation*3600)+(15*60)))
    Pilot.FlightGroup:AddMission(capauftrag) 
    
    -- cancel current mission
    if currmission then
      currmission:__Cancel(3)
    end
    
    -- update known mission list
    self.CatchAllMissions[#self.CatchAllMissions+1] = intercept
    self.CatchAllMissions[#self.CatchAllMissions+1] = capauftrag
    
    -- update pilot TaskSheet
    self.ManagedTasks:PullByID(Pilot.CurrentTask)
    
    Pilot.HasAssignedTask = true
    Pilot.CurrentTask = self:_CreateTaskForGroup(Pilot.GID,AWACS.TaskDescription.INTERCEPT,"Intercept Task",Target.Target,AWACS.TaskStatus.ASSIGNED,intercept,Target.Cluster,Target.Contact)
    Pilot.CurrentAuftrag = intercept.auftragsnummer
    Pilot.ContactCID = Target.CID
    
    -- update managed group
    self.ManagedGrps[Pilot.GID] = Pilot
    
    -- Update Contact Status
    Target.LinkedTask = Pilot.CurrentTask
    Target.LinkedGroup = Pilot.GID
    Target.Status = AWACS.TaskStatus.ASSIGNED
    local targeted = self.gettext:GetEntry("ENGAGETAG",self.locale) 
    Target.EngagementTag = string.format(targeted,Pilot.CallSign)
    
    self.Contacts:PullByID(Target.CID)
    self.Contacts:Push(Target,Target.CID)
    
    local altitude = Target.Contact.altitude or Target.Contact.group:GetAltitude()
    local position = Target.Cluster.coordinate or Target.Contact.position
    if not position then
      self.intel:GetClusterCoordinate(Target.Cluster,true)
    end
    local bratext, bratexttts = self:_ToStringBRA(Pilot.Group:GetCoordinate(),position,altitude or 8000)
    
    local aicomm = self.gettext:GetEntry("AICOMMIT",self.locale) 
    local text = string.format(aicomm, self.callsigntxt,Target.TargetGroupNaming,bratexttts,Pilot.CallSign)
    local textScreen = string.format(aicomm, self.callsigntxt,Target.TargetGroupNaming,bratext,Pilot.CallSign)
    
    self:_NewRadioEntry(text,textScreen,Pilot.GID,true,self.debug,true,false,true)
    
    local comm = self.gettext:GetEntry("COMMIT",self.locale) 
    local text = string.format("%s. %s.",Pilot.CallSign,comm)
    
    self:_NewRadioEntry(text,text,Pilot.GID,true,self.debug,true,true,true)
    
    self:__Intercept(2)
    
  end
  
  return self
end

-- TODO FSMs
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] onbeforeStart
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onbeforeStart(From,Event,To)
  self:T({From, Event, To})
  if self.IncludeHelicopters then
    self.clientset:FilterCategories("helicopter")
  end
  return self
end

--- [Internal] onafterStart
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterStart(From, Event, To)
  self:T({From, Event, To})
  
  -- Set up control zone
  local controlzonename = "FEZ-"..self.AOName
  self.ControlZone = ZONE_RADIUS:New(controlzonename,self.OpsZone:GetVec2(),UTILS.NMToMeters(self.ControlZoneRadius))
  if self.debug then
    self.ControlZone:DrawZone(self.coalition,{0,1,0},1,{1,0,0},0.05,3,true)
    self.OpsZone:DrawZone(self.coalition,{1,0,0},1,{1,0,0},0.2,5,true)
    local AOCoordString = self.AOCoordinate:ToStringLLDDM()
    local Rocktag = string.format("FEZ: %s\nBulls Coordinate: %s",self.AOName,AOCoordString)
    if self.AllowMarkers then
      MARKER:New(self.AOCoordinate,Rocktag):ToCoalition(self.coalition)
    end
    self.StationZone:DrawZone(self.coalition,{0,0,1},1,{0,0,1},0.2,5,true)
    local stationtag = string.format("Station: %s\nCoordinate: %s",self.StationZoneName,self.StationZone:GetCoordinate():ToStringLLDDM())
    if not self.GCI then
      if self.AllowMarkers then
        MARKER:New(self.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
      end
      self.OrbitZone:DrawZone(self.coalition,{0,1,0},1,{0,1,0},0.2,5,true)
      if self.AllowMarkers then
        MARKER:New(self.OrbitZone:GetCoordinate(),"AIC Orbit Zone"):ToCoalition(self.coalition)
      end
    end
  else
    local AOCoordString = self.AOCoordinate:ToStringLLDDM()
    local Rocktag = string.format("FEZ: %s\nBulls Coordinate: %s",self.AOName,AOCoordString)
    if self.AllowMarkers then
      MARKER:New(self.AOCoordinate,Rocktag):ToCoalition(self.coalition)
    end
    if not self.GCI then
      if self.AllowMarkers then
        MARKER:New(self.OrbitZone:GetCoordinate(),"AIC Orbit Zone"):ToCoalition(self.coalition)
      end
    end
    local stationtag = string.format("Station: %s\nCoordinate: %s",self.StationZoneName,self.StationZone:GetCoordinate():ToStringLLDDM())
    if self.AllowMarkers then
      MARKER:New(self.StationZone:GetCoordinate(),stationtag):ToCoalition(self.coalition)
    end
  end
  
  if not self.GCI then
    -- set up the AWACS and let it orbit
    local AwacsAW = self.AirWing -- Ops.Airwing#AIRWING
    local mission = AUFTRAG:NewORBIT_RACETRACK(self.OrbitZone:GetCoordinate(),self.AwacsAngels*1000,self.Speed,self.Heading,self.Leg)
    mission:SetMissionRange(self.MaxMissionRange)
    mission:SetRequiredAttribute({ GROUP.Attribute.AIR_AWACS }) -- prefered plane type, thanks to Heart8reaker
    local timeonstation = (self.AwacsTimeOnStation + self.ShiftChangeTime) * 3600
    mission:SetTime(nil,timeonstation)
    self.CatchAllMissions[#self.CatchAllMissions+1] = mission
    
    AwacsAW:AddMission(mission)
    
    self.AwacsMission = mission
    self.AwacsInZone = false -- not yet arrived or gone again
    self.AwacsReady = false
  else
    self.AwacsInZone = true -- for GCI - arrived
    self.AwacsReady = true
    self:_StartIntel(self.GCIGroup)
    
    if self.GCIGroup:IsGround() then
      self.AwacsFG = ARMYGROUP:New(self.GCIGroup)
      self.AwacsFG:SetDefaultRadio(self.Frequency,self.Modulation)
      self.AwacsFG:SwitchRadio(self.Frequency,self.Modulation)
    elseif self.GCIGroup:IsShip() then
      self.AwacsFG = NAVYGROUP:New(self.GCIGroup)
      self.AwacsFG:SetDefaultRadio(self.Frequency,self.Modulation)
      self.AwacsFG:SwitchRadio(self.Frequency,self.Modulation)
    else
      self:E(self.lid.."**** Group unsuitable for GCI ops! Needs to be a GROUND or SHIP type group!")
      self:Stop()
      return self
    end
    
    self.callsigntxt = string.format("%s",self.CallSignClear[self.CallSign])  
    self:__CheckRadioQueue(-10)
    
    local sunrise = self.gettext:GetEntry("SUNRISE",self.locale)
    local text = string.format(sunrise,self.callsigntxt,self.callsigntxt)
    self:_NewRadioEntry(text,text,0,false,false,false,false,true)
    self:T(self.lid..text)
    self.sunrisedone = true
  end
  
  local ZoneSet = SET_ZONE:New()
  ZoneSet:AddZone(self.ControlZone)
  
  if not self.GCI then
    ZoneSet:AddZone(self.OrbitZone)
  end
  
  if self.BorderZone then
    ZoneSet:AddZone(self.BorderZone)
  end
  
  local RejectZoneSet = SET_ZONE:New()
  if self.RejectZone then
    RejectZoneSet:AddZone(self.RejectZone)
  end
  
  self.ZoneSet = ZoneSet
  self.RejectZoneSet = RejectZoneSet
  
  if self.AllowMarkers then
    -- Add MarkerOps
    
    local MarkerOps = MARKEROPS_BASE:New("AWACS",{"Station","Delete","Move"})
    
    local function Handler(Keywords,Coord,Text)
      self:T(Text)
      for _,_word in pairs (Keywords) do
        if string.lower(_word) == "station" then
          -- get the station name from the text field
          local Name = string.match(Text," ([%a]+)$")
          self:_CreateAnchorStackFromMarker(Name,Coord)
          break
        elseif string.lower(_word) == "delete" then
          -- get the station name from the text field
          local Name = string.match(Text," ([%a]+)$")
          self:_DeleteAnchorStackFromMarker(Name,Coord)
          break
        elseif string.lower(_word) == "move" then
          -- get the station name from the text field
          local Name = string.match(Text," ([%a]+)$")
          self:_MoveAnchorStackFromMarker(Name,Coord)
          break  
        end
      end
    end
    
    -- Event functions
    function MarkerOps:OnAfterMarkAdded(From,Event,To,Text,Keywords,Coord)
      Handler(Keywords,Coord,Text)
    end
    
    function MarkerOps:OnAfterMarkChanged(From,Event,To,Text,Keywords,Coord)
      Handler(Keywords,Coord,Text)
    end
    
    function MarkerOps:OnAfterMarkDeleted(From,Event,To)
    end
    
    self.MarkerOps = MarkerOps
    
  end
  
  if self.GCI then
    -- set FSM to started
    self:__Started(-5)
  end
  
  if self.TacticalMenu then
    self:__CheckTacticalQueue(55)
  end
  
  self:__Status(-30)
  return self
end

function AWACS:_CheckAwacsStatus()
  self:T(self.lid.."_CheckAwacsStatus")
  
  local awacs = nil -- Wrapper.Group#GROUP
  if self.AwacsFG then
    awacs = self.AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    local unit = awacs:GetUnit(1)
    if unit then
      self.STN = tostring(unit:GetSTN())
    end
  end
  
  local monitoringdata = self.MonitoringData -- #AWACS.MonitoringData
  
  if not self.GCI then
    if awacs and awacs:IsAlive() and not self.AwacsInZone then
      -- check if we arrived
      local orbitzone = self.OrbitZone -- Core.Zone#ZONE
      if awacs:IsInZone(orbitzone) then
        -- arrived
        self.AwacsInZone = true
        self:T(self.lid.."Arrived in Orbit Zone: " .. orbitzone:GetName())
        local onstationtxt = self.gettext:GetEntry("AWONSTATION",self.locale)
        local text = string.format(onstationtxt,self.callsigntxt,self.AOName or "Rock")
        local textScreen = text    
        self:_NewRadioEntry(text,textScreen,0,false,true,true,false,true)
      end
    end 
  end
  
  --------------------------------
  --     AWACS
  --------------------------------
   
  if (awacs and awacs:IsAlive()) then
    
    if not self.intelstarted then
      local alt = UTILS.Round(UTILS.MetersToFeet(awacs:GetAltitude())/1000,0)
      if alt >= 10 then 
        self:_StartIntel(awacs)
      end
    end
    
    if self.intelstarted  and not self.sunrisedone then
      -- TODO Sunrise call on after airborne at ca 10k feet
      local alt = UTILS.Round(UTILS.MetersToFeet(awacs:GetAltitude())/1000,0)
      if alt >= 10 then
        local sunrise = self.gettext:GetEntry("SUNRISE",self.locale)      
        local text = string.format(sunrise,self.callsigntxt,self.callsigntxt)
        self:_NewRadioEntry(text,text,0,false,false,false,false,true)
        self:T(self.lid..text)
        self.sunrisedone = true
      end
    end
    
    -- Check on Awacs Mission Status
    local AWmission = self.AwacsMission -- Ops.Auftrag#AUFTRAG
    local awstatus = AWmission:GetState()
    local AWmissiontime = (timer.getTime() - self.AwacsTimeStamp)
    
    local AWTOSLeft = UTILS.Round((((self.AwacsTimeOnStation+self.ShiftChangeTime)*3600) - AWmissiontime),0) -- seconds
    
    AWTOSLeft = UTILS.Round(AWTOSLeft/60,0) -- minutes
    
    local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
    
    local Changedue = "No"
    
    if not self.ShiftChangeAwacsFlag and (AWTOSLeft <= ChangeTime or AWmission:IsOver()) then 
      Changedue = "Yes"
      self.ShiftChangeAwacsFlag = true
      self:__AwacsShiftChange(2) 
    end
    
    local report = REPORT:New("AWACS:")
    report:Add("====================")
    report:Add("AWACS:")
    report:Add(string.format("Auftrag Status: %s",awstatus))
    report:Add(string.format("TOS Left: %d min",AWTOSLeft))
    report:Add(string.format("Needs ShiftChange: %s",Changedue))
    
    local OpsGroups = AWmission:GetOpsGroups()
    local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
    if OpsGroup then
      local OpsName = OpsGroup:GetName() or "Unknown"
      local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
      report:Add(string.format("Mission FG %s",OpsName))
      report:Add(string.format("Callsign %s",OpsCallSign))
      report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
    else
      report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
    end
    
    -- Check for replacement mission - if any
    if self.ShiftChangeAwacsFlag and self.ShiftChangeAwacsRequested then -- Ops.Auftrag#AUFTRAG
      AWmission = self.AwacsMissionReplacement
      local esstatus = AWmission:GetState()
      local ESmissiontime = (timer.getTime() - self.AwacsTimeStamp)
      local ESTOSLeft = UTILS.Round((((self.AwacsTimeOnStation+self.ShiftChangeTime)*3600) - ESmissiontime),0) -- seconds
      ESTOSLeft = UTILS.Round(ESTOSLeft/60,0) -- minutes
      local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
      
      report:Add("AWACS REPLACEMENT:")
      report:Add(string.format("Auftrag Status: %s",esstatus))
      report:Add(string.format("TOS Left: %d min",ESTOSLeft))
      
      local OpsGroups = AWmission:GetOpsGroups()
      local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
      if OpsGroup then
        local OpsName = OpsGroup:GetName() or "Unknown"
        local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
        report:Add(string.format("Mission FG %s",OpsName))
        report:Add(string.format("Callsign %s",OpsCallSign))
        report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
      else
        report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
      end
      
      if AWmission:IsExecuting() then
        -- make the actual change in the queue
        self.ShiftChangeAwacsFlag = false
        self.ShiftChangeAwacsRequested = false
        self.sunrisedone = false
        -- cancel old mission
        if self.AwacsMission and self.AwacsMission:IsNotOver() then
            self.AwacsMission:Cancel()
        end
        self.AwacsMission = self.AwacsMissionReplacement
        self.AwacsMissionReplacement = nil
        self.AwacsTimeStamp = timer.getTime()
        report:Add("*** Replacement DONE ***")
      end
      report:Add("====================")
    end
    
    --------------------------------
    --     ESCORTS
    --------------------------------
                       
    if self.HasEscorts then
      for i=1, self.EscortNumber do
        local ESmission = self.EscortMission[i] -- Ops.Auftrag#AUFTRAG
        if not ESmission then break end
        local esstatus = ESmission:GetState()
        local ESmissiontime = (timer.getTime() - self.EscortsTimeStamp)
        local ESTOSLeft = UTILS.Round((((self.EscortsTimeOnStation+self.ShiftChangeTime)*3600) - ESmissiontime),0) -- seconds
        ESTOSLeft = UTILS.Round(ESTOSLeft/60,0) -- minutes
        local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
        local Changedue = "No"
        
        if (ESTOSLeft <= ChangeTime and not self.ShiftChangeEscortsFlag) or (ESmission:IsOver() and not self.ShiftChangeEscortsFlag) then 
          Changedue = "Yes" 
          self.ShiftChangeEscortsFlag = true -- set this back when new Escorts arrived
          self:__EscortShiftChange(2)
        end
        
        report:Add("====================")
        report:Add("ESCORTS:")
        report:Add(string.format("Auftrag Status: %s",esstatus))
        report:Add(string.format("TOS Left: %d min",ESTOSLeft))
        report:Add(string.format("Needs ShiftChange: %s",Changedue))
        
        local OpsGroups = ESmission:GetOpsGroups()
        local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
        if OpsGroup then
          local OpsName = OpsGroup:GetName() or "Unknown"
          local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
          report:Add(string.format("Mission FG %s",OpsName))
          report:Add(string.format("Callsign %s",OpsCallSign))
          report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
          monitoringdata.EscortsStateMission[i] = esstatus
          monitoringdata.EscortsStateFG[i] = OpsGroup:GetState()
        else
          report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
        end
        
        report:Add("====================")
        
        local RESMission
        -- Check for replacement mission - if any
        if self.ShiftChangeEscortsFlag and self.ShiftChangeEscortsRequested then -- Ops.Auftrag#AUFTRAG
          RESMission = self.EscortMissionReplacement[i]
          local esstatus = RESMission:GetState()
          local RESMissiontime = (timer.getTime() - self.EscortsTimeStamp)
          local ESTOSLeft = UTILS.Round((((self.EscortsTimeOnStation+self.ShiftChangeTime)*3600) - RESMissiontime),0) -- seconds
          ESTOSLeft = UTILS.Round(ESTOSLeft/60,0) -- minutes
          local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)

          report:Add("ESCORTS REPLACEMENT:")
          report:Add(string.format("Auftrag Status: %s",esstatus))
          report:Add(string.format("TOS Left: %d min",ESTOSLeft))
          
          local OpsGroups = RESMission:GetOpsGroups()
          local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
          if OpsGroup then
            local OpsName = OpsGroup:GetName() or "Unknown"
            local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
            report:Add(string.format("Mission FG %s",OpsName))
            report:Add(string.format("Callsign %s",OpsCallSign))
            report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
          else
            report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
          end
          
          if RESMission and RESMission:IsExecuting() then
            -- make the actual change in the queue
            self.ShiftChangeEscortsFlag = false
            self.ShiftChangeEscortsRequested = false
            -- cancel old mission
            if ESmission and ESmission:IsNotOver() then
              ESmission:__Cancel(1)
            end
            self.EscortMission[i] = self.EscortMissionReplacement[i]
              self.EscortMissionReplacement[i] = nil
            self.EscortsTimeStamp = timer.getTime()
            report:Add("*** Replacement DONE ***")
          end
          report:Add("====================")
        end
      end
    end
      
    if self.debug then  
      self:T(report:Text())
    end
  
  else
       -- Check on Awacs Mission Status
    local AWmission = self.AwacsMission -- Ops.Auftrag#AUFTRAG
    local awstatus = AWmission:GetState()
    if AWmission:IsOver() then
      -- yup we're dead
      self:I(self.lid.."*****AWACS is dead!*****")
      self.ShiftChangeAwacsFlag = true
      self:__AwacsShiftChange(2)
    end 
  end
  
  return monitoringdata
end

--- [Internal] onafterStatus
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  
  self:_SetClientMenus()
  
  local monitoringdata = self.MonitoringData -- #AWACS.MonitoringData
  
  if not self.GCI then
    monitoringdata = self:_CheckAwacsStatus()
  end
  
  local awacsalive = false
  if self.AwacsFG then
    local awacs = self.AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    if awacs and awacs:IsAlive() then
      awacsalive= true
    end
  end
  
  -- Check on AUFTRAG status for CAP AI
  if self:Is("Running") and (awacsalive or self.AwacsInZone) then
    
      
    -- update coord for SRS
    
    if self.AwacsSRS then
      self.AwacsSRS:SetCoordinate(self.AwacsFG:GetCoordinate())
      if self.TacticalSRS then
        self.TacticalSRS:SetCoordinate(self.AwacsFG:GetCoordinate())
      end
    end
    
    self:_CheckAICAPOnStation()
    
    self:_CleanUpContacts()
    
    self:_CheckMerges()
    
    self:_CheckSubscribers()
    
    local outcome, targets = self:_TargetSelectionProcess(true)
    
    self:_CheckTaskQueue()
    
    local AI, Humans = self:_GetIdlePilots()
    -- assign Pilot if there are targets and available Pilots, prefer Humans to AI
    -- DONE - Implemented AI First, Humans laters - need to work out how to loop the targets to assign a pilot
    if outcome and #Humans > 0 and self.PlayerCapAssignment then
      -- add a task for AI
      self:_AssignPilotToTarget(Humans,targets)
    end
    if outcome and #AI > 0 then
      -- add a task for AI
      self:_AssignPilotToTarget(AI,targets)
    end
  end
  
  if not self.GCI then
    monitoringdata.AwacsShiftChange = self.ShiftChangeAwacsFlag
    
    if self.AwacsFG then
     monitoringdata.AwacsStateFG = self.AwacsFG:GetState()
    end
    
    monitoringdata.AwacsStateMission = self.AwacsMission:GetState()
    monitoringdata.EscortsShiftChange = self.ShiftChangeEscortsFlag
  end
  
  monitoringdata.AICAPCurrent = self.AICAPMissions:Count()
  monitoringdata.AICAPMax = self.MaxAIonCAP
  monitoringdata.Airwings = self.CAPAirwings:Count()
  
  self.MonitoringData = monitoringdata
  
  if self.debug then
    self:_LogStatistics()
  end
  
  local picturetime = timer.getTime() - self.PictureTimeStamp
  
  if self.AwacsInZone and picturetime > self.PictureInterval then
    -- reset timer
    self.PictureTimeStamp = timer.getTime()
    self:_Picture(nil,true)
  end
  
  self:__Status(30)
  
  return self
end

--- [Internal] onafterStop
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterStop(From, Event, To)
  self:T({From, Event, To})
  -- unhandle stuff, exit intel
  
  self.intel:Stop()
  
  local AWFiFo = self.CAPAirwings -- Utilities.FiFo#FIFO
  local AWStack = AWFiFo:GetPointerStack()
  for _ID,_AWID in pairs(AWStack) do
    local SubAW = self.CAPAirwings:ReadByPointer(_ID)
    if SubAW then
      SubAW:RemoveUsingOpsAwacs()
    end
  end
    -- Events
  -- Player joins
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  self:UnHandleEvent(EVENTS.PlayerEnterUnit)
    -- Player leaves
  self:UnHandleEvent(EVENTS.PlayerLeaveUnit)
  self:UnHandleEvent(EVENTS.Ejection)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.UnitLost)
  self:UnHandleEvent(EVENTS.BDA)
  self:UnHandleEvent(EVENTS.PilotDead)
  -- Missile warning
  self:UnHandleEvent(EVENTS.Shot)
  
  return self
end

--- [Internal] onafterAssignAnchor
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #number GID Group ID
-- @param #boolean HasOwnStation
-- @param #string HasOwnStation
-- @return #AWACS self
function AWACS:onafterAssignAnchor(From, Event, To, GID, HasOwnStation, StationName)
  self:T({From, Event, To, "GID = " .. GID})
  self:_AssignAnchorToID(GID, HasOwnStation, StationName)
  return self
end

--- [Internal] onafterCheckedOut
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #AWACS.ManagedGroup.GID Group ID 
-- @param #number AnchorStackNo
-- @param #number Angels
-- @return #AWACS self
function AWACS:onafterCheckedOut(From, Event, To, GID, AnchorStackNo, Angels)
  self:T({From, Event, To, "GID = " .. GID})
  self:_RemoveIDFromAnchor(GID,AnchorStackNo,Angels)
  return self
end

--- [Internal] onafterAssignedAnchor
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #number GID Managed Group ID
-- @param #AWACS.AnchorData Anchor
-- @param #number AnchorStackNo
-- @return #AWACS self
function AWACS:onafterAssignedAnchor(From, Event, To, GID, Anchor, AnchorStackNo, AnchorAngels)
  self:T({From, Event, To, "GID=" .. GID, "Stack=" .. AnchorStackNo})
  -- TODO
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  if not managedgroup then
    self:E(self.lid .. "**** GID "..GID.." Not Registered!")
    return self
  end
  managedgroup.AnchorStackNo = AnchorStackNo
  managedgroup.AnchorStackAngels = AnchorAngels
  managedgroup.Blocked = false
  local isPlayer = managedgroup.IsPlayer
  local isAI = managedgroup.IsAI
  local Group = managedgroup.Group
  local CallSign = managedgroup.CallSign or "Ghost 1"
  local AnchorName = Anchor.StationName or "unknown"
  local AnchorCoordTxt = Anchor.StationZoneCoordinateText or "unknown"
  local Angels = AnchorAngels or 25
  local AnchorSpeed = self.CapSpeedBase or 270
  local AuftragsNr = managedgroup.CurrentAuftrag
  
  local textTTS = ""
  if self.PikesSpecialSwitch then
    local stationtxt = self.gettext:GetEntry("STATIONAT",self.locale) 
    textTTS = string.format(stationtxt,CallSign,self.callsigntxt,AnchorName,Angels)
  else
    local stationtxt = self.gettext:GetEntry("STATIONATLONG",self.locale) 
    textTTS = string.format(stationtxt,CallSign,self.callsigntxt,AnchorName,Angels,AnchorSpeed)
  end
  local ROEROT = self.AwacsROE..", "..self.AwacsROT
  local stationtxtsc = self.gettext:GetEntry("STATIONSCREEN",self.locale) 
  local stationtxtta = self.gettext:GetEntry("STATIONTASK",self.locale) 
  local textScreen = string.format(stationtxtsc,CallSign,self.callsigntxt,AnchorName,Angels,AnchorSpeed,AnchorCoordTxt,ROEROT)
  local TextTasking = string.format(stationtxtta,AnchorName,Angels,AnchorSpeed,AnchorCoordTxt,ROEROT)
  
  self:_NewRadioEntry(textTTS,textScreen,GID,isPlayer,isPlayer,true,false)
      
  managedgroup.CurrentTask = self:_CreateTaskForGroup(GID,AWACS.TaskDescription.ANCHOR,TextTasking,Anchor.StationZone)

  -- if it's a Alert5, we want to push CAP instead
  if isAI then
    local auftrag = managedgroup.FlightGroup:GetMissionCurrent() -- Ops.Auftrag#AUFTRAG
    if auftrag then
      local auftragtype = auftrag:GetType()
      if auftragtype == AUFTRAG.Type.ALERT5 then
        -- all correct
        local capauftrag = AUFTRAG:NewCAP(Anchor.StationZone,Angels*1000,AnchorSpeed,Anchor.StationZone:GetCoordinate(),0,15,{})
        capauftrag:SetMissionRange(self.MaxMissionRange)
        capauftrag:SetTime(nil,((self.CAPTimeOnStation*3600)+(15*60)))
        capauftrag:AddAsset(managedgroup.FlightGroup)
        self.CatchAllMissions[#self.CatchAllMissions+1] = capauftrag
        managedgroup.FlightGroup:AddMission(capauftrag)
        auftrag:Cancel()
      else
       self:E("**** AssignedAnchor but Auftrag NOT ALERT5!")
      end
    else
      self:E("**** AssignedAnchor but NO Auftrag!")
    end 
  end
  
  self.ManagedGrps[GID] = managedgroup
    
  return self
end

--- [Internal] onafterNewCluster
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intel#INTEL.Cluster Cluster
-- @return #AWACS self
function AWACS:onafterNewCluster(From,Event,To,Cluster)
  self:T({From, Event, To, Cluster.index})
  
  self.CID = self.CID + 1
  self.Countactcounter = self.Countactcounter + 1
  
  local ContactTable = Cluster.Contacts or {}
  
  local function GetFirstAliveContact(table)
    for _,_contact in pairs (table) do
      local contact = _contact -- Ops.Intel#INTEL.Contact
      if contact and contact.group and contact.group:IsAlive() then
        return contact, contact.group
      end
    end
    return nil
  end
  
  local Contact, Group = GetFirstAliveContact(ContactTable) -- Ops.Intel#INTEL.Contact
  
  if not Contact then return self end
  
  if Group and not Group:IsAirborne() then
    return self
  end
  
  local targetset = SET_GROUP:New()
  -- SET for TARGET
  for _,_grp in pairs(ContactTable) do
    local grp = _grp -- Ops.Intel#INTEL.Contact
    targetset:AddGroup(grp.group, true)
  end
  local managedcontact = {} -- #AWACS.ManagedContact
  managedcontact.CID = self.CID
  managedcontact.Contact = Contact
  managedcontact.Cluster = Cluster
  -- TODO set as per tech / engagement / alarm level age...
  managedcontact.IFF = AWACS.IFF.BOGEY -- no IFF yet
  managedcontact.Target = TARGET:New(targetset)
  managedcontact.LinkedGroup = 0
  managedcontact.LinkedTask = 0
  managedcontact.Status = AWACS.TaskStatus.IDLE
  local phoneid = math.fmod(self.Countactcounter,27)
  if phoneid == 0 then phoneid = 1 end
  managedcontact.TargetGroupNaming = AWACS.Phonetic[phoneid]
  managedcontact.ReportingName = Contact.group:GetNatoReportingName() -- e.g. Foxbat. Bogey if unknown
  managedcontact.TACCallDone = false
  managedcontact.MeldCallDone = false
  managedcontact.EngagementTag = ""
  
  local IsPopup = false
  -- is this a pop-up group? i.e. appeared inside AO
  if self.OpsZone:IsVec2InZone(Contact.position:GetVec2()) then
   IsPopup = true
  end
  
  -- let's see if we can inject some info into Contact
  Contact.CID = managedcontact.CID
  Contact.TargetGroupNaming = managedcontact.TargetGroupNaming
  Cluster.CID = managedcontact.CID
  Cluster.TargetGroupNaming = managedcontact.TargetGroupNaming
  
  self.Contacts:Push(managedcontact,self.CID)
  
  -- only announce if in right distance to HVT/AIC or in ControlZone or in BorderZone
  local ContactCoordinate = Contact.position:GetVec2()
  local incontrolzone = self.ControlZone:IsVec2InZone(ContactCoordinate)
  
  -- distance check to HVT
  local distance = 1000000
  if not self.GCI then
    distance = Contact.position:Get2DDistance(self.OrbitZone:GetCoordinate())
  end
  
  local inborderzone = false
  if self.BorderZone then
    inborderzone = self.BorderZone:IsVec2InZone(ContactCoordinate)
  end
  
  if incontrolzone or inborderzone or (distance <= UTILS.NMToMeters(55)) or IsPopup then
    self:_AnnounceContact(managedcontact,true,nil,false,managedcontact.TargetGroupNaming,IsPopup,managedcontact.ReportingName)
  end
  
  return self
end
  
--- [Internal] onafterNewContact
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intel#INTEL.Contact Contact
-- @return #AWACS self 
function AWACS:onafterNewContact(From,Event,To,Contact)
  self:T({From, Event, To, Contact})
  local tdist = self.ThreatDistance -- NM 
  -- is any plane near-by? 
  for _gid,_mgroup in pairs(self.ManagedGrps) do
    local managedgroup = _mgroup -- #AWACS.ManagedGroup
    local group = managedgroup.Group
    if group and group:IsAlive() and group:IsAirborne() then
       -- contact distance
       local cpos = Contact.position or Contact.group:GetCoordinate() -- Core.Point#COORDINATE
       local mpos = group:GetCoordinate()
       local dist = cpos:Get2DDistance(mpos) -- meter
       dist = UTILS.Round(UTILS.MetersToNM(dist),0)
       if dist <= tdist then
        -- threat call
        self:_ThreatRangeCall(_gid,Contact)
       end
    end
  end
  return self
end
  
--- [Internal] onafterLostContact
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intel#INTEL.Contact Contact
-- @return #AWACS self
function AWACS:onafterLostContact(From,Event,To,Contact)
  self:T({From, Event, To, Contact})
  return self
end
  
--- [Internal] onafterLostCluster
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intel#INTEL.Cluster Cluster
-- @param Ops.Auftrag#AUFTRAG Mission
-- @return #AWACS self
function AWACS:onafterLostCluster(From,Event,To,Cluster,Mission)
  self:T({From, Event, To})
  return self
end

--- [Internal] onafterCheckTacticalQueue
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterCheckTacticalQueue(From,Event,To)
 self:T({From, Event, To})
 -- do we have messages queued?
 
 if self.clientset:CountAlive() ==  0 then 
  self:T(self.lid.."No player connected.")
  self:__CheckTacticalQueue(-5)
  return self 
 end
 
 for _name,_freq in pairs(self.TacticalSubscribers) do
  local Group = nil
  if _name then
    Group = GROUP:FindByName(_name)
  end
  if Group and Group:IsAlive() then
    self:_BogeyDope(Group,true)
  end
 end
 
 if (self.TacticalQueue:IsNotEmpty()) then
  
  while self.TacticalQueue:Count() > 0 do
  
    local RadioEntry = self.TacticalQueue:Pull() -- #AWACS.RadioEntry 
    self:T({RadioEntry})
    local frequency = self.TacticalBaseFreq
    if RadioEntry.GroupID and RadioEntry.GroupID ~= 0 then
      local managedgroup = self.ManagedGrps[RadioEntry.GroupID] -- #AWACS.ManagedGroup
      if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
        local name = managedgroup.GroupName
        frequency = self.TacticalSubscribers[name]
      end
    end
    -- AI AWACS Speaking
    local gtext = RadioEntry.TextTTS
    if self.PathToGoogleKey then
      gtext = string.format("<speak><prosody rate='medium'>%s</prosody></speak>",gtext)
    end
    self.TacticalSRSQ:NewTransmission(gtext,nil,self.TacticalSRS,nil,0.5,nil,nil,nil,frequency,self.TacticalModulation)
  
    self:T(RadioEntry.TextTTS)
    
    if RadioEntry.ToScreen and RadioEntry.TextScreen and (not self.SuppressScreenOutput) then
      if RadioEntry.GroupID and RadioEntry.GroupID ~= 0 then
        local managedgroup = self.ManagedGrps[RadioEntry.GroupID] -- #AWACS.ManagedGroup
        if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
          MESSAGE:New(RadioEntry.TextScreen,20,"AWACS"):ToGroup(managedgroup.Group)
          self:T(RadioEntry.TextScreen)
        end
      else
        MESSAGE:New(RadioEntry.TextScreen,20,"AWACS"):ToCoalition(self.coalition)
      end
    end
   end
 
 end -- end while
 
 if not self:Is("Stopped") then
  self:__CheckTacticalQueue(-self.TacticalInterval)
 end
 return self
end


--- [Internal] onafterCheckRadioQueue
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterCheckRadioQueue(From,Event,To)
 self:T({From, Event, To})
 -- do we have messages queued?
 
 local nextcall = 10
 if (self.RadioQueue:IsNotEmpty() or self.PrioRadioQueue:IsNotEmpty()) then
  
  local RadioEntry = nil
  
  if self.PrioRadioQueue:IsNotEmpty() then
    RadioEntry = self.PrioRadioQueue:Pull() -- #AWACS.RadioEntry
  else
    RadioEntry = self.RadioQueue:Pull() -- #AWACS.RadioEntry
  end
  self:T({RadioEntry})
  
  if self.clientset:CountAlive() ==  0 then 
    self:T(self.lid.."No player connected.")
    self:__CheckRadioQueue(-5)
    return self 
  end
  
  if not RadioEntry.FromAI then
    -- AI AWACS Speaking
    if self.PathToGoogleKey then
      local gtext = RadioEntry.TextTTS
      gtext = string.format("<speak><prosody rate='medium'>%s</prosody></speak>",gtext)
      self.AwacsSRS:PlayTextExt(gtext,nil,self.MultiFrequency,self.MultiModulation,self.Gender,self.Culture,self.Voice,self.Volume,"AWACS")
    else
      self.AwacsSRS:PlayTextExt(RadioEntry.TextTTS,nil,self.MultiFrequency,self.MultiModulation,self.Gender,self.Culture,self.Voice,self.Volume,"AWACS")
    end
    self:T(RadioEntry.TextTTS)
  else
    -- CAP AI speaking
    if RadioEntry.GroupID and RadioEntry.GroupID ~= 0 then
      local managedgroup = self.ManagedGrps[RadioEntry.GroupID] -- #AWACS.ManagedGroup
      if managedgroup and managedgroup.FlightGroup and managedgroup.FlightGroup:IsAlive() then
        if self.PathToGoogleKey then
          local gtext = RadioEntry.TextTTS
          gtext = string.format("<speak><prosody rate='medium'>%s</prosody></speak>",gtext)
          managedgroup.FlightGroup:RadioTransmission(gtext,1,false)
        else
          managedgroup.FlightGroup:RadioTransmission(RadioEntry.TextTTS,1,false)
        end
        self:T(RadioEntry.TextTTS)
      end
    end
  end
  
  if RadioEntry.Duration then nextcall = RadioEntry.Duration end
  
  if RadioEntry.ToScreen and RadioEntry.TextScreen and (not self.SuppressScreenOutput) then
    if RadioEntry.GroupID and RadioEntry.GroupID ~= 0 then
      local managedgroup = self.ManagedGrps[RadioEntry.GroupID] -- #AWACS.ManagedGroup
      if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
        MESSAGE:New(RadioEntry.TextScreen,20,"AWACS"):ToGroup(managedgroup.Group)
        self:T(RadioEntry.TextScreen)
      end
    else
      MESSAGE:New(RadioEntry.TextScreen,20,"AWACS"):ToCoalition(self.coalition)
    end
  end
 end
 
 if self:Is("Running") then
  -- exit if stopped
  if self.PathToGoogleKey then
    nextcall = nextcall + self.GoogleTTSPadding
  else
    nextcall = nextcall + self.WindowsTTSPadding
  end
  self:__CheckRadioQueue(-nextcall)
 end
 return self
end

--- [Internal] onafterEscortShiftChange
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterEscortShiftChange(From,Event,To)
  self:T({From, Event, To})
  -- request new Escorts, check if AWACS-FG still alive first!
  if self.AwacsFG and self.ShiftChangeEscortsFlag and not self.ShiftChangeEscortsRequested then
    local awacs = self.AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    if awacs and awacs:IsAlive() then
      -- ok we're good to re-request
      self.ShiftChangeEscortsRequested = true
      self.EscortsTimeStamp = timer.getTime()
      self:_StartEscorts(true)
    else
      -- should not happen
      self:E("**** AWACS group dead at onafterEscortShiftChange!")
    end
  end
  return self
end

--- [Internal] onafterAwacsShiftChange
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterAwacsShiftChange(From,Event,To)
  self:T({From, Event, To})
  -- request new AWACS
  if self.AwacsFG and self.ShiftChangeAwacsFlag and not self.ShiftChangeAwacsRequested then
    
    -- ok we're good to re-request
    self.ShiftChangeAwacsRequested = true
    self.AwacsTimeStamp = timer.getTime()
    
    -- set up the AWACS and let it orbit
    local AwacsAW = self.AirWing -- Ops.Airwing#AIRWING
    local mission = AUFTRAG:NewORBIT_RACETRACK(self.OrbitZone:GetCoordinate(),self.AwacsAngels*1000,self.Speed,self.Heading,self.Leg)
    self.CatchAllMissions[#self.CatchAllMissions+1] = mission
    local timeonstation = (self.AwacsTimeOnStation + self.ShiftChangeTime) * 3600
    mission:SetTime(nil,timeonstation)
    mission:SetMissionRange(self.MaxMissionRange)
    
    AwacsAW:AddMission(mission)
    
    self.AwacsMissionReplacement = mission
    
  end
  return self
end

--- On after "FlightOnMission".
-- @param #AWACS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup on mission.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
-- @return #AWACS self
function AWACS:onafterFlightOnMission(From, Event, To, FlightGroup, Mission)
  self:T({From, Event, To})
  -- coming back from AW, set up the flight
  self:T("FlightGroup " .. FlightGroup:GetName() .. " Mission " .. Mission:GetName() .. " Type "..Mission:GetType())
  self.CatchAllFGs[#self.CatchAllFGs+1] = FlightGroup
  if not self:Is("Stopped") then
    if not self.AwacsReady or self.ShiftChangeAwacsFlag or self.ShiftChangeEscortsFlag then
     self:_StartSettings(FlightGroup,Mission)
    elseif Mission and (Mission:GetType() == AUFTRAG.Type.CAP or Mission:GetType() == AUFTRAG.Type.ALERT5 or Mission:GetType() == AUFTRAG.Type.ORBIT) then
        if not self.FlightGroups:HasUniqueID(FlightGroup:GetName()) then
          self:T("Pushing FG " .. FlightGroup:GetName() .. " to stack!")
          self.FlightGroups:Push(FlightGroup,FlightGroup:GetName())
        end
    end
  end
  return self
end

--- On after "ReAnchor".
-- @param #AWACS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number GID Group ID to check and re-anchor if possible
-- @return #AWACS self
function AWACS:onafterReAnchor(From, Event, To, GID)
  self:T({From, Event, To, GID})
  -- get managedgroup, heck AI FG state, heck weapon state, check fuel state, vector back to anchor or RTB
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  if managedgroup then
    if managedgroup.IsAI then
      -- AI will now have a new CAP AUFTRAG and head back to the stack anyway
      local AIFG = managedgroup.FlightGroup -- Ops.FlightGroup#FLIGHTGROUP
      if AIFG and AIFG:IsAlive() then
        -- check state
        if AIFG:IsFuelLow() or AIFG:IsOutOfMissiles() or AIFG:IsOutOfAmmo() then
          local destbase = AIFG.homebase
          if not destbase then destbase = self.Airbase end
          -- RTB call needs an AIRBASE
          AIFG:RTB(destbase)
          -- Check out
          self:_CheckOut(AIFG:GetGroup(),GID)
          self.AIRequested = self.AIRequested - 1
        else
          -- re-establish anchor task, get anchor zone data
          local Anchor = self.AnchorStacks:ReadByPointer(managedgroup.AnchorStackNo) -- #AWACS.AnchorData
          local StationZone = Anchor.StationZone -- Core.Zone#ZONE
          managedgroup.CurrentTask = self:_CreateTaskForGroup(GID,AWACS.TaskDescription.ANCHOR,"Re-Station AI",StationZone)
          managedgroup.HasAssignedTask = true
          local mission = AIFG:GetMissionCurrent() -- Ops.Auftrag#AUFTRAG
          if mission then
            managedgroup.CurrentAuftrag = mission.auftragsnummer or 0
          else
            managedgroup.CurrentAuftrag = 0
          end
          managedgroup.ContactCID = 0
          self.ManagedGrps[GID] = managedgroup 
          local tostation = self.gettext:GetEntry("VECTORSTATION",self.locale)       
          self:_MessageVector(GID,tostation,Anchor.StationZoneCoordinate,managedgroup.AnchorStackAngels)
        end
      else
        -- lost group, remove from known groups, declare vanished
        -- AI - remove from known FGs! -- done in status loop
        -- ALL remove from managedgrps
        
        -- message loss
        local savedcallsign = managedgroup.CallSign
          --vanished/friendly flight faded/lost contact with C/S/CSAR Scramble
           -- Magic, RIGHTGUARD, RIGHTGUARD, Dodge 41, Bullseye X/Y
       local textoptions = {}    
       textoptions[1] = self.gettext:GetEntry("TEXTOPTIONS1",self.locale)  
       textoptions[2] = self.gettext:GetEntry("TEXTOPTIONS2",self.locale)  
       textoptions[3] = self.gettext:GetEntry("TEXTOPTIONS3",self.locale)  
       textoptions[4] = self.gettext:GetEntry("TEXTOPTIONS4",self.locale)
       local allstations = self.gettext:GetEntry("ALLSTATIONS",self.locale)
       local milestxt = self.gettext:GetEntry("MILES",self.locale)  
        -- DONE - need to save last known coordinate
        
        if managedgroup.LastKnownPosition then
          local lastknown = UTILS.DeepCopy(managedgroup.LastKnownPosition)
          local faded = textoptions[math.random(1,4)]
          local text = string.format("%s. %s. %s %s.",allstations,self.callsigntxt, faded, savedcallsign)
          local textScreen = string.format("%s, %s. %s %s.",allstations, self.callsigntxt, faded, savedcallsign)
          
          local brtext = self:_ToStringBULLS(lastknown)
          local brtexttts = self:_ToStringBULLS(lastknown,false,true)

          text = text .. " "..brtexttts.." "..milestxt.."."
          textScreen = textScreen .. " "..brtext.." "..milestxt.."."
          
          self:_NewRadioEntry(text,textScreen,0,false,self.debug,true,false,true)
        end
        self.ManagedGrps[GID] = nil
      end 
    elseif managedgroup.IsPlayer then
      -- TODO
      local PLFG = managedgroup.Group -- Wrapper.Group#GROUP
      if PLFG and PLFG:IsAlive() then
          -- re-establish anchor task
          -- get anchor zone data
          local Anchor = self.AnchorStacks:ReadByPointer(managedgroup.AnchorStackNo) -- #AWACS.AnchorData
          local AnchorName = Anchor.StationName or "unknown"
          local AnchorCoordTxt = Anchor.StationZoneCoordinateText or "unknown"
          local Angels = managedgroup.AnchorStackAngels or 25
          local AnchorSpeed = self.CapSpeedBase or 270
          local StationZone = Anchor.StationZone -- Core.Zone#ZONE
          local ROEROT = self.AwacsROE.." "..self.AwacsROT
          local stationtxt = self.gettext:GetEntry("STATIONTASK",self.locale)
          local TextTasking = string.format(stationtxt,AnchorName,Angels,AnchorSpeed,AnchorCoordTxt,ROEROT)
          managedgroup.CurrentTask = self:_CreateTaskForGroup(GID,AWACS.TaskDescription.ANCHOR,TextTasking,StationZone)
          managedgroup.HasAssignedTask = true
          managedgroup.ContactCID = 0
          self.ManagedGrps[GID] = managedgroup
          local vectortxt = self.gettext:GetEntry("VECTORSTATION",self.locale)        
          self:_MessageVector(GID,vectortxt,Anchor.StationZoneCoordinate,managedgroup.AnchorStackAngels)
      else
        -- lost group, remove from known groups, declare vanished
        -- ALL remove from managedgrps       
        -- message loss
        local savedcallsign = managedgroup.CallSign
          --vanished/friendly flight faded/lost contact with C/S/CSAR Scramble
           -- Magic, RIGHTGUARD, RIGHTGUARD, Dodge 41, Bullseye X/Y
         local textoptions = {}    
         textoptions[1] = self.gettext:GetEntry("TEXTOPTIONS1",self.locale)  
         textoptions[2] = self.gettext:GetEntry("TEXTOPTIONS2",self.locale)  
         textoptions[3] = self.gettext:GetEntry("TEXTOPTIONS3",self.locale)  
         textoptions[4] = self.gettext:GetEntry("TEXTOPTIONS4",self.locale)
         local allstations = self.gettext:GetEntry("ALLSTATIONS",self.locale)
         local milestxt = self.gettext:GetEntry("MILES",self.locale)  
        
        -- DONE - need to save last known coordinate
        local faded = textoptions[math.random(1,4)]
        local text = string.format("%s. %s. %s %s.",allstations, self.callsigntxt, faded, savedcallsign)
        local textScreen = string.format("%s, %s. %s %s.", allstations,self.callsigntxt, faded, savedcallsign)
        if managedgroup.LastKnownPosition then
          local lastknown = UTILS.DeepCopy(managedgroup.LastKnownPosition)
          local brtext = self:_ToStringBULLS(lastknown)
          local brtexttts = self:_ToStringBULLS(lastknown,false,true)
          text = text .. " "..brtexttts.." "..milestxt.."."
          textScreen = textScreen .. " "..brtext.." "..milestxt.."."
        
          self:_NewRadioEntry(text,textScreen,0,false,self.debug,true,false,true)
        end
        self.ManagedGrps[GID] = nil
      end 
    end
  end
end

end -- end do
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END AWACS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
