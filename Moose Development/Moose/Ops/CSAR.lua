--- **Ops** - Combat Search and Rescue.
--
-- ===
-- 
-- **CSAR** - MOOSE based Helicopter CSAR Operations.
-- 
-- ===
-- 
-- ## Missions:--- **Ops** -- Combat Search and Rescue.
--
-- ===
-- 
-- **CSAR** - MOOSE based Helicopter CSAR Operations.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [CSAR - Combat Search & Rescue](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20CSAR)
-- 
-- ===
-- 
-- **Main Features:**
--
--    * MOOSE-based Helicopter CSAR Operations for Players.
--
-- ===
--
-- ### Author: **Applevangelist** (Moose Version), ***Ciribob*** (original), Thanks to: Shadowze, Cammel (testing), The Chosen One (Persistence)
-- @module Ops.CSAR
-- @image OPS_CSAR.jpg

-- Date: May 2023

-------------------------------------------------------------------------
--- **CSAR** class, extends Core.Base#BASE, Core.Fsm#FSM
-- @type CSAR
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
-- @field Core.Set#SET_GROUP allheligroupset Set of CSAR heli groups.
-- @extends Core.Fsm#FSM

--- *Combat search and rescue (CSAR) are search and rescue operations that are carried out during war that are within or near combat zones.* (Wikipedia)
--
-- ===
--
-- ![Banner Image](OPS_CSAR.jpg)
--
-- # CSAR Concept
-- 
--  * MOOSE-based Helicopter CSAR Operations for Players.
--  * Object oriented refactoring of Ciribob\'s fantastic CSAR script.
--  * No need for extra MIST loading. 
--  * Additional events to tailor your mission.
--  * Optional SpawnCASEVAC to create casualties without beacon (e.g. handling dead ground vehicles and create CASVAC requests).
-- 
-- ## 0. Prerequisites
-- 
-- You need to load an .ogg soundfile for the pilot\'s beacons into the mission, e.g. "beacon.ogg", use a once trigger, "sound to country" for that.
-- Create a late-activated single infantry unit as template in the mission editor and name it e.g. "Downed Pilot".
-- 
-- ## 1. Basic Setup
-- 
-- A basic setup example is the following:
--        
--        -- Instantiate and start a CSAR for the blue side, with template "Downed Pilot" and alias "Luftrettung"
--        local my_csar = CSAR:New(coalition.side.BLUE,"Downed Pilot","Luftrettung")
--        -- options
--        my_csar.immortalcrew = true -- downed pilot spawn is immortal
--        my_csar.invisiblecrew = false -- downed pilot spawn is visible
--        -- start the FSM
--        my_csar:__Start(5)
-- 
-- ## 2. Options
-- 
-- The following options are available (with their defaults). Only set the ones you want changed:
--
--         mycsar.allowDownedPilotCAcontrol = false -- Set to false if you don\'t want to allow control by Combined Arms.
--         mycsar.allowFARPRescue = true -- allows pilots to be rescued by landing at a FARP or Airbase. Else MASH only!
--         mycsar.FARPRescueDistance = 1000 -- you need to be this close to a FARP or Airport for the pilot to be rescued.
--         mycsar.autosmoke = false -- automatically smoke a downed pilot\'s location when a heli is near.
--         mycsar.autosmokedistance = 1000 -- distance for autosmoke
--         mycsar.coordtype = 1 -- Use Lat/Long DDM (0), Lat/Long DMS (1), MGRS (2), Bullseye imperial (3) or Bullseye metric (4) for coordinates.
--         mycsar.csarOncrash = false -- (WIP) If set to true, will generate a downed pilot when a plane crashes as well.
--         mycsar.enableForAI = false -- set to false to disable AI pilots from being rescued.
--         mycsar.pilotRuntoExtractPoint = true -- Downed pilot will run to the rescue helicopter up to mycsar.extractDistance in meters. 
--         mycsar.extractDistance = 500 -- Distance the downed pilot will start to run to the rescue helicopter.
--         mycsar.immortalcrew = true -- Set to true to make wounded crew immortal.
--         mycsar.invisiblecrew = false -- Set to true to make wounded crew insvisible.
--         mycsar.loadDistance = 75 -- configure distance for pilots to get into helicopter in meters.
--         mycsar.mashprefix = {"MASH"} -- prefixes of #GROUP objects used as MASHes.
--         mycsar.max_units = 6 -- max number of pilots that can be carried if #CSAR.AircraftType is undefined.
--         mycsar.messageTime = 15 -- Time to show messages for in seconds. Doubled for long messages.
--         mycsar.radioSound = "beacon.ogg" -- the name of the sound file to use for the pilots\' radio beacons. 
--         mycsar.smokecolor = 4 -- Color of smokemarker, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue.
--         mycsar.useprefix = true  -- Requires CSAR helicopter #GROUP names to have the prefix(es) defined below.
--         mycsar.csarPrefix = { "helicargo", "MEDEVAC"} -- #GROUP name prefixes used for useprefix=true - DO NOT use # in helicopter names in the Mission Editor! 
--         mycsar.verbose = 0 -- set to > 1 for stats output for debugging.
--         -- limit amount of downed pilots spawned by **ejection** events
--         mycsar.limitmaxdownedpilots = true
--         mycsar.maxdownedpilots = 10 
--         -- allow to set far/near distance for approach and optionally pilot must open doors
--         mycsar.approachdist_far = 5000 -- switch do 10 sec interval approach mode, meters
--         mycsar.approachdist_near = 3000 -- switch to 5 sec interval approach mode, meters
--         mycsar.pilotmustopendoors = false -- switch to true to enable check of open doors
--         mycsar.suppressmessages = false -- switch off all messaging if you want to do your own
--         mycsar.rescuehoverheight = 20 -- max height for a hovering rescue in meters
--         mycsar.rescuehoverdistance = 10 -- max distance for a hovering rescue in meters
--         -- Country codes for spawned pilots
--         mycsar.countryblue= country.id.USA
--         mycsar.countryred = country.id.RUSSIA
--         mycsar.countryneutral = country.id.UN_PEACEKEEPERS
--         mycsar.topmenuname = "CSAR" -- set the menu entry name
--         mycsar.ADFRadioPwr = 1000 -- ADF Beacons sending with 1KW as default
--         mycsar.PilotWeight = 80 --  Loaded pilots weigh 80kgs each
--         
-- ## 2.1 Experimental Features
-- 
--       WARNING - Here\'ll be dragons!
--       DANGER - For this to work you need to de-sanitize your mission environment (all three entries) in <DCS root>\Scripts\MissionScripting.lua
--       Needs SRS => 1.9.6 to work (works on the **server** side of SRS)
--       mycsar.useSRS = false -- Set true to use FF\'s SRS integration
--       mycsar.SRSPath = "C:\\Progra~1\\DCS-SimpleRadio-Standalone\\" -- adjust your own path in your SRS installation -- server(!)
--       mycsar.SRSchannel = 300 -- radio channel
--       mycsar.SRSModulation = radio.modulation.AM -- modulation
--       mycsar.SRSport = 5002  -- and SRS Server port
--       mycsar.SRSCulture = "en-GB" -- SRS voice culture
--       mycsar.SRSVoice = nil -- SRS voice, relevant for Google TTS
--       mycsar.SRSGPathToCredentials = nil -- Path to your Google credentials json file, set this if you want to use Google TTS
--       mycsar.SRSVolume = 1 -- Volume, between 0 and 1
--       mycsar.SRSGender = "male" -- male or female voice
--       --
--       mycsar.csarUsePara = false -- If set to true, will use the LandingAfterEjection Event instead of Ejection. Requires mycsar.enableForAI to be set to true. --shagrat
--       mycsar.wetfeettemplate = "man in floating thingy" -- if you use a mod to have a pilot in a rescue float, put the template name in here for wet feet spawns. Note: in conjunction with csarUsePara this might create dual ejected pilots in edge cases.
--       mycsar.allowbronco = false  -- set to true to use the Bronco mod as a CSAR plane
--        
-- ## 3. Results
-- 
-- Number of successful landings with save pilots and aggregated number of saved pilots is stored in these variables in the object:
--      
--        mycsar.rescues -- number of successful landings *with* saved pilots
--        mycsar.rescuedpilots -- aggregated number of pilots rescued from the field (of *all* players)
-- 
-- ## 4. Events
--
--  The class comes with a number of FSM-based events that missions designers can use to shape their mission.
--  These are:
--  
-- ### 4.1. PilotDown. 
--      
--      The event is triggered when a new downed pilot is detected. Use e.g. `function my_csar:OnAfterPilotDown(...)` to link into this event:
--      
--          function my_csar:OnAfterPilotDown(from, event, to, spawnedgroup, frequency, groupname, coordinates_text)
--            ... your code here ...
--          end
--    
-- ### 4.2. Approach. 
--      
--      A CSAR helicpoter is closing in on a downed pilot. Use e.g. `function my_csar:OnAfterApproach(...)` to link into this event:
--      
--          function my_csar:OnAfterApproach(from, event, to, heliname, groupname)
--            ... your code here ...
--          end
--    
-- ### 4.3. Boarded. 
--    
--      The pilot has been boarded to the helicopter. Use e.g. `function my_csar:OnAfterBoarded(...)` to link into this event:
--      
--          function my_csar:OnAfterBoarded(from, event, to, heliname, groupname, description)
--            ... your code here ...
--          end
--    
-- ### 4.4. Returning. 
--      
--       The CSAR helicopter is ready to return to an Airbase, FARP or MASH. Use e.g. `function my_csar:OnAfterReturning(...)` to link into this event:
--       
--          function my_csar:OnAfterReturning(from, event, to, heliname, groupname)
--            ... your code here ...
--          end
--    
-- ### 4.5. Rescued. 
--    
--      The CSAR helicopter has landed close to an Airbase/MASH/FARP and the pilots are safe. Use e.g. `function my_csar:OnAfterRescued(...)` to link into this event:
--      
--          function my_csar:OnAfterRescued(from, event, to, heliunit, heliname, pilotssaved)
--            ... your code here ...
--          end     
--
-- ## 5. Spawn downed pilots at location to be picked up.
--  
--      If missions designers want to spawn downed pilots into the field, e.g. at mission begin to give the helicopter guys works, they can do this like so:
--      
--        -- Create downed "Pilot Wagner" in #ZONE "CSAR_Start_1" at a random point for the blue coalition
--        my_csar:SpawnCSARAtZone( "CSAR_Start_1", coalition.side.BLUE, "Pilot Wagner", true )
--
--      --Create a casualty and CASEVAC request from a "Point" (VEC2) for the blue coalition --shagrat
--      my_csar:SpawnCASEVAC(Point, coalition.side.BLUE)  
--      
-- ## 6. Save and load downed pilots - Persistance
-- 
-- You can save and later load back downed pilots to make your mission persistent.
-- For this to work, you need to de-sanitize **io** and **lfs** in your MissionScripting.lua, which is located in your DCS installtion folder under Scripts.
-- There is a risk involved in doing that; if you do not know what that means, this is possibly not for you.
-- 
-- Use the following options to manage your saves:
-- 
--              mycsar.enableLoadSave = true -- allow auto-saving and loading of files
--              mycsar.saveinterval = 600 -- save every 10 minutes
--              mycsar.filename = "missionsave.csv" -- example filename
--              mycsar.filepath = "C:\\Users\\myname\\Saved Games\\DCS\Missions\\MyMission" -- example path
--  
--  Then use an initial load at the beginning of your mission:
--  
--            mycsar:__Load(10)
--            
--  **Caveat:**
-- Dropped troop noMessage and forcedesc parameters aren't saved.      
--
-- @field #CSAR
CSAR = {
  ClassName       = "CSAR",
  verbose         =     0,
  lid             =   "",
  coalition       = 1,
  coalitiontxt    = "blue",
  FreeVHFFrequencies = {},
  UsedVHFFrequencies = {},
  takenOff = {},
  csarUnits = {},  -- table of unit names
  downedPilots = {},
  woundedGroups = {},
  landedStatus = {},
  addedTo = {},
  woundedGroups = {}, -- contains the new group of units
  inTransitGroups = {}, -- contain a table for each SAR with all units he has with the original names
  smokeMarkers = {}, -- tracks smoke markers for groups
  heliVisibleMessage = {}, -- tracks if the first message has been sent of the heli being visible
  heliCloseMessage = {}, -- tracks heli close message  ie heli < 500m distance
  max_units = 6, -- number of pilots that can be carried
  hoverStatus = {}, -- tracks status of a helis hover above a downed pilot
  pilotDisabled = {}, -- tracks what aircraft a pilot is disabled for
  pilotLives = {}, -- tracks how many lives a pilot has
  useprefix    = true,  -- Use the Prefixed defined below, Requires Unit have the Prefix defined below 
  csarPrefix = {},
  template = nil,
  mash = {},
  smokecolor = 4,
  rescues = 0,
  rescuedpilots = 0,
  limitmaxdownedpilots = true,
  maxdownedpilots = 10,
  allheligroupset = nil,
  topmenuname = "CSAR",
  ADFRadioPwr = 1000,
  PilotWeight = 80,
}

--- Downed pilots info.
-- @type CSAR.DownedPilot
-- @field #number index Pilot index.
-- @field #string name Name of the spawned group.
-- @field #number side Coalition.
-- @field #string originalUnit Name of the original unit.
-- @field #string desc Description.
-- @field #string typename Typename of Unit.
-- @field #number frequency Frequency of the NDB.
-- @field #string player Player name if applicable.
-- @field Wrapper.Group#GROUP group Spawned group object.
-- @field #number timestamp Timestamp for approach process.
-- @field #boolean alive Group is alive or dead/rescued.
-- @field #boolean wetfeet Group is spawned over (deep) water.

--- All slot / Limit settings
-- @type CSAR.AircraftType
-- @field #string typename Unit type name.
CSAR.AircraftType = {} -- Type and limit
CSAR.AircraftType["SA342Mistral"] = 2
CSAR.AircraftType["SA342Minigun"] = 2
CSAR.AircraftType["SA342L"] = 4
CSAR.AircraftType["SA342M"] = 4
CSAR.AircraftType["UH-1H"] = 8
CSAR.AircraftType["Mi-8MTV2"] = 12
CSAR.AircraftType["Mi-8MT"] = 12  
CSAR.AircraftType["Mi-24P"] = 8 
CSAR.AircraftType["Mi-24V"] = 8
CSAR.AircraftType["Bell-47"] = 2                
CSAR.AircraftType["UH-60L"] = 10
CSAR.AircraftType["AH-64D_BLK_II"] = 2
CSAR.AircraftType["Bronco-OV-10A"] = 2

--- CSAR class version.
-- @field #string version
CSAR.version="1.0.18"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: SRS Integration (to be tested)
-- TODO: Maybe - add option to smoke/flare closest MASH
-- DONE: shagrat Add cargoWeight to helicopter when pilot boarded
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new CSAR object and start the FSM.
-- @param #CSAR self
-- @param #number Coalition Coalition side. Can also be passed as a string "red", "blue" or "neutral".
-- @param #string Template Name of the late activated infantry unit standing in for the downed pilot.
-- @param #string Alias An *optional* alias how this object is called in the logs etc.
-- @return #CSAR self
function CSAR:New(Coalition, Template, Alias)
  
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #CSAR
  
  BASE:T({Coalition, Template, Alias})
  
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
      self:E("ERROR: Unknown coalition in CSAR!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="Red Cross"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="IFRC"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="CSAR"
      end
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- CSAR status update.
  self:AddTransition("*",             "PilotDown",          "*")          -- Downed Pilot added
  self:AddTransition("*",             "Approach",           "*")         -- CSAR heli closing in.
  self:AddTransition("*",             "Landed",             "*")         -- CSAR heli landed 
  self:AddTransition("*",             "Boarded",            "*")          -- Pilot boarded.
  self:AddTransition("*",             "Returning",          "*")        -- CSAR able to return to base.
  self:AddTransition("*",             "Rescued",            "*")          -- Pilot at MASH.
  self:AddTransition("*",             "KIA",                "*")          -- Pilot killed in action.
  self:AddTransition("*",             "Load",                "*")           -- CSAR load  event.  
  self:AddTransition("*",             "Save",                "*")           -- CSAR save  event.
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.

  -- tables, mainly for tracking actions
  self.addedTo = {}
  self.allheligroupset = {} -- GROUP_SET of all helis
  self.csarUnits = {} -- table of CSAR unit names
  self.FreeVHFFrequencies = {}
  self.heliVisibleMessage = {} -- tracks if the first message has been sent of the heli being visible
  self.heliCloseMessage = {} -- tracks heli close message  ie heli < 500m distance
  self.hoverStatus = {} -- tracks status of a helis hover above a downed pilot
  self.inTransitGroups = {} -- contain a table for each SAR with all units he has with the original names
  self.landedStatus = {}
  self.lastCrash = {}
  self.takenOff = {}
  self.smokeMarkers = {} -- tracks smoke markers for groups
  self.UsedVHFFrequencies = {}
  self.woundedGroups = {} -- contains the new group of units
  self.downedPilots = {} -- Replacement woundedGroups
  self.downedpilotcounter = 1
  
  -- settings, counters etc
  self.rescues = 0 -- counter for successful rescue landings at FARP/AFB/MASH
  self.rescuedpilots = 0 -- counter for saved pilots
  self.csarOncrash = false -- If set to true, will generate a csar when a plane crashes as well.
  self.allowDownedPilotCAcontrol = false -- Set to false if you don\'t want to allow control by Combined arms.
  self.enableForAI = false -- set to false to disable AI units from being rescued.
  self.smokecolor = 4 -- Color of smokemarker for blue side, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue
  self.coordtype = 2 -- Use Lat/Long DDM (0), Lat/Long DMS (1), MGRS (2), Bullseye imperial (3) or Bullseye metric (4) for coordinates.
  self.immortalcrew = true -- Set to true to make wounded crew immortal
  self.invisiblecrew = false -- Set to true to make wounded crew insvisible 
  self.messageTime = 15 -- Time to show longer messages for in seconds 
  self.pilotRuntoExtractPoint = true -- Downed Pilot will run to the rescue helicopter up to self.extractDistance METERS 
  self.loadDistance = 75 -- configure distance for pilot to get in helicopter in meters.
  self.extractDistance = 500 -- Distance the Downed pilot will run to the rescue helicopter
  self.loadtimemax = 135 -- seconds
  self.radioSound = "beacon.ogg" -- the name of the sound file to use for the Pilot radio beacons. If this isnt added to the mission BEACONS WONT WORK!
  self.beaconRefresher = 29 -- seconds
  self.allowFARPRescue = true --allows pilot to be rescued by landing at a FARP or Airbase
  self.FARPRescueDistance = 1000 -- you need to be this close to a FARP or Airport for the pilot to be rescued.
  self.max_units = 6 --max number of pilots that can be carried
  self.useprefix = true  -- Use the Prefixed defined below, Requires Unit have the Prefix defined below 
  self.csarPrefix = { "helicargo", "MEDEVAC"} -- prefixes used for useprefix=true - DON\'T use # in names!
  self.template = Template or "generic" -- template for downed pilot
  self.mashprefix = {"MASH"} -- prefixes used to find MASHes
 
  self.autosmoke = false -- automatically smoke location when heli is near
  self.autosmokedistance = 2000 -- distance for autosmoke
  -- added 0.1.4
  self.limitmaxdownedpilots = true
  self.maxdownedpilots = 25
  -- generate Frequencies
  self:_GenerateVHFrequencies()
  -- added 0.1.8
  self.approachdist_far = 5000 -- switch do 10 sec interval approach mode, meters
  self.approachdist_near = 3000 -- switch to 5 sec interval approach mode, meters
  self.pilotmustopendoors = false -- switch to true to enable check on open doors
  self.suppressmessages = false
  
  -- added 0.1.11r1
  self.rescuehoverheight = 20
  self.rescuehoverdistance = 10
 
  -- added 0.1.12
  self.countryblue= country.id.USA
  self.countryred = country.id.RUSSIA
  self.countryneutral = country.id.UN_PEACEKEEPERS
  
  -- added 0.1.3
  self.csarUsePara = false -- shagrat set to true, will use the LandingAfterEjection Event instead of Ejection
  
  -- added 0.1.4
  self.wetfeettemplate = nil
  self.usewetfeet = false
  
  -- added 1.0.15
  self.allowbronco = false  -- set to true to use the Bronco mod as a CSAR plane
  
  self.ADFRadioPwr = 1000
  
  -- added 1.0.16
  self.PilotWeight = 80
      
  -- WARNING - here\'ll be dragons
  -- for this to work you need to de-sanitize your mission environment in <DCS root>\Scripts\MissionScripting.lua
  -- needs SRS => 1.9.6 to work (works on the *server* side)
  self.useSRS = false -- Use FF\'s SRS integration
  self.SRSPath = "E:\\Program Files\\DCS-SimpleRadio-Standalone" -- adjust your own path in your server(!)
  self.SRSchannel = 300 -- radio channel
  self.SRSModulation = radio.modulation.AM -- modulation
  self.SRSport = 5002 -- port
  self.SRSCulture = "en-GB"
  self.SRSVoice = nil
  self.SRSGPathToCredentials = nil
  self.SRSVolume = 1.0 -- volume 0.0 to 1.0
  self.SRSGender = "male" -- male or female
  
  local AliaS = string.gsub(self.alias," ","_")
  self.filename = string.format("CSAR_%s_Persist.csv",AliaS)
  
  -- load and save downed pilots
  self.enableLoadSave = false
  self.filepath = nil
  self.saveinterval = 600
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
    --- Triggers the FSM event "Start". Starts the CSAR. Initializes parameters and starts event handlers.
  -- @function [parent=#CSAR] Start
  -- @param #CSAR self

  --- Triggers the FSM event "Start" after a delay. Starts the CSAR. Initializes parameters and starts event handlers.
  -- @function [parent=#CSAR] __Start
  -- @param #CSAR self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the CSAR and all its event handlers.
  -- @param #CSAR self

  --- Triggers the FSM event "Stop" after a delay. Stops the CSAR and all its event handlers.
  -- @function [parent=#CSAR] __Stop
  -- @param #CSAR self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#CSAR] Status
  -- @param #CSAR self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#CSAR] __Status
  -- @param #CSAR self
  -- @param #number delay Delay in seconds.
  -- 
  --   --- Triggers the FSM event "Load".
  -- @function [parent=#CSAR] Load
  -- @param #CSAR self

  --- Triggers the FSM event "Load" after a delay.
  -- @function [parent=#CSAR] __Load
  -- @param #CSAR self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Save".
  -- @function [parent=#CSAR] Load
  -- @param #CSAR self

  --- Triggers the FSM event "Save" after a delay.
  -- @function [parent=#CSAR] __Save
  -- @param #CSAR self
  -- @param #number delay Delay in seconds.
  
  --- On After "PilotDown" event. Downed Pilot detected.
  -- @function [parent=#CSAR] OnAfterPilotDown
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP Group Group object of the downed pilot.
  -- @param #number Frequency Beacon frequency in kHz.
  -- @param #string Leadername Name of the #UNIT of the downed pilot.
  -- @param #string CoordinatesText String of the position of the pilot. Format determined by self.coordtype.
  
  --- On After "Aproach" event. Heli close to downed Pilot.
  -- @function [parent=#CSAR] OnAfterApproach
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Heliname Name of the helicopter group.
  -- @param #string Woundedgroupname Name of the downed pilot\'s group.
  
   --- On After "Landed" event. Heli landed at an airbase.
  -- @function [parent=#CSAR] OnAfterLanded
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string HeliName Name of the #UNIT which has landed.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where the heli landed.
    
   --- On After "Boarded" event. Downed pilot boarded heli.
  -- @function [parent=#CSAR] OnAfterBoarded
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Heliname Name of the helicopter group.
  -- @param #string Woundedgroupname Name of the downed pilot\'s group.
  -- @param #string Description Descriptive name of the group.

    --- On After "Returning" event. Heli can return home with downed pilot(s).
  -- @function [parent=#CSAR] OnAfterReturning
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Heliname Name of the helicopter group.
  -- @param #string Woundedgroupname Name of the downed pilot\'s group.
  
    --- On After "Rescued" event. Pilot(s) have been brought to the MASH/FARP/AFB.
  -- @function [parent=#CSAR] OnAfterRescued
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT HeliUnit Unit of the helicopter.
  -- @param #string HeliName Name of the helicopter group.
  -- @param #number PilotsSaved Number of the saved pilots on board when landing.
  
  --- On After "KIA" event. Pilot is dead.
  -- @function [parent=#CSAR] OnAfterKIA
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Pilotname Name of the pilot KIA.
  
  --- FSM Function OnAfterLoad.
  -- @function [parent=#CSAR] OnAfterLoad
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CSAR_<alias>_Persist.csv".
  
  --- FSM Function OnAfterSave.
  -- @function [parent=#CSAR] OnAfterSave
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for saving. Default is "CSAR_<alias>_Persist.csv".
  
  return self
end

------------------------
--- Helper Functions ---
------------------------

--- (Internal) Function to insert downed pilot tracker object.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP Group The #GROUP object
-- @param #string Groupname Name of the spawned group.
-- @param #number Side Coalition.
-- @param #string OriginalUnit Name of original Unit.
-- @param #string Description Descriptive text.
-- @param #string Typename Typename of unit.
-- @param #number Frequency Frequency of the NDB in Hz
-- @param #string Playername Name of Player (if applicable)
-- @param #boolean Wetfeet Ejected over water
-- @return #CSAR self.
function CSAR:_CreateDownedPilotTrack(Group,Groupname,Side,OriginalUnit,Description,Typename,Frequency,Playername,Wetfeet)
  self:T({"_CreateDownedPilotTrack",Groupname,Side,OriginalUnit,Description,Typename,Frequency,Playername})
  
  -- create new entry
  local DownedPilot = {} -- #CSAR.DownedPilot
  DownedPilot.desc = Description or ""
  DownedPilot.frequency = Frequency or 0
  DownedPilot.index = self.downedpilotcounter
  DownedPilot.name = Groupname or ""
  DownedPilot.originalUnit = OriginalUnit or ""
  DownedPilot.player = Playername or ""
  DownedPilot.side = Side or 0
  DownedPilot.typename = Typename or ""
  DownedPilot.group = Group
  DownedPilot.timestamp = 0
  DownedPilot.alive = true
  DownedPilot.wetfeet = Wetfeet or false
  
  -- Add Pilot
  local PilotTable = self.downedPilots
  local counter = self.downedpilotcounter
  PilotTable[counter] = {}
  PilotTable[counter] = DownedPilot
  self:T({Table=PilotTable})
  self.downedPilots = PilotTable
  -- Increase counter
  self.downedpilotcounter = self.downedpilotcounter+1
  return self
end

--- (Internal) Count pilots on board.
-- @param #CSAR self
-- @param #string _heliName
-- @return #number count  
function CSAR:_PilotsOnboard(_heliName)
  self:T(self.lid .. " _PilotsOnboard")
 local count = 0
  if self.inTransitGroups[_heliName] then
      for _, _group in pairs(self.inTransitGroups[_heliName]) do
          count = count + 1
      end
  end
  return count
end

--- (Internal) Function to check for dupe eject events.
-- @param #CSAR self
-- @param #string _unitname Name of unit.
-- @return #boolean Outcome
function CSAR:_DoubleEjection(_unitname)
    if self.lastCrash[_unitname] then
        local _time = self.lastCrash[_unitname]
        if timer.getTime() - _time < 10 then
            self:E(self.lid.."Caught double ejection!")
            return true
        end
    end
    self.lastCrash[_unitname] = timer.getTime()
    return false
end

--- (User) Add a PLAYERTASK - FSM events will check success
-- @param #CSAR self
-- @param Ops.PlayerTask#PLAYERTASK PlayerTask
-- @return #CSAR self
function CSAR:AddPlayerTask(PlayerTask)
  self:T(self.lid .. " AddPlayerTask")
  if not self.PlayerTaskQueue then
    self.PlayerTaskQueue = FIFO:New()
  end
  self.PlayerTaskQueue:Push(PlayerTask,PlayerTask.PlayerTaskNr)
  return self
end

--- (Internal) Spawn a downed pilot
-- @param #CSAR self
-- @param #number country Country for template.
-- @param Core.Point#COORDINATE point Coordinate to spawn at.
-- @param #number frequency Frequency of the pilot's beacon
-- @param #boolean wetfeet Spawn is over water
-- @return Wrapper.Group#GROUP group The #GROUP object.
-- @return #string alias The alias name.
function CSAR:_SpawnPilotInField(country,point,frequency,wetfeet)
  self:T({country,point,frequency,tostring(wetfeet)})
  local freq = frequency or 1000
  local freq = freq / 1000 -- kHz
  for i=1,10 do
    math.random(i,10000)
  end
  if point:IsSurfaceTypeWater() or wetfeet then 
    point.y = 0 
  end
  local template = self.template
  if self.usewetfeet and wetfeet then
    template = self.wetfeettemplate
  end
  local alias = string.format("Pilot %.2fkHz-%d", freq, math.random(1,99))
  local coalition = self.coalition
  local pilotcacontrol = self.allowDownedPilotCAcontrol -- Switch AI on/oof - is this really correct for CA?
  local _spawnedGroup = SPAWN
    :NewWithAlias(template,alias)
    :InitCoalition(coalition)
    :InitCountry(country)
    :InitAIOnOff(pilotcacontrol)
    :InitDelayOff()
    :SpawnFromCoordinate(point)

  return _spawnedGroup, alias -- Wrapper.Group#GROUP object
end

--- (Internal) Add options to a downed pilot
-- @param #CSAR self
-- @param Wrapper.Group#GROUP group Group to use.
function CSAR:_AddSpecialOptions(group)
  self:T(self.lid.." _AddSpecialOptions")
  self:T({group})
  
  local immortalcrew = self.immortalcrew
  local invisiblecrew = self.invisiblecrew
  if immortalcrew then
    local _setImmortal = {
        id = 'SetImmortal',
        params = {
            value = true
        }
    }
    group:SetCommand(_setImmortal)
  end

  if invisiblecrew then
    local _setInvisible = {
        id = 'SetInvisible',
        params = {
            value = true
        }
    }
    group:SetCommand(_setInvisible) 
  end
  
  group:OptionAlarmStateGreen()
  group:OptionROEHoldFire()
  return self
end

--- (Internal) Function to spawn a CSAR object into the scene.
-- @param #CSAR self
-- @param #number _coalition Coalition
-- @param DCS#country.id _country Country ID
-- @param Core.Point#COORDINATE _point Coordinate
-- @param #string _typeName Typename
-- @param #string _unitName Unitname
-- @param #string _playerName Playername
-- @param #number _freq Frequency
-- @param #boolean noMessage 
-- @param #string _description Description
-- @param #boolean forcedesc Use the description only for the pilot track entry
function CSAR:_AddCsar(_coalition , _country, _point, _typeName, _unitName, _playerName, _freq, noMessage, _description, forcedesc )
  self:T(self.lid .. " _AddCsar")
  self:T({_coalition , _country, _point, _typeName, _unitName, _playerName, _freq, noMessage, _description})

  local template = self.template
  local wetfeet = false
  
  local surface = _point:GetSurfaceType()
  if surface == land.SurfaceType.WATER then
    wetfeet = true
  end
  
  if not _freq then
    _freq = self:_GenerateADFFrequency()
    if not _freq then _freq = 333000 end --noob catch
  end 
  
  local _spawnedGroup, _alias = self:_SpawnPilotInField(_country,_point,_freq,wetfeet)
  
  local _typeName = _typeName or "Pilot"
  
  if not noMessage then
    if _freq ~= 0 then --shagrat different CASEVAC msg
    self:_DisplayToAllSAR("MAYDAY MAYDAY! " .. _typeName .. " is down. ", self.coalition, self.messageTime)
  else    
    self:_DisplayToAllSAR("Troops In Contact. " .. _typeName .. " requests CASEVAC. ", self.coalition, self.messageTime)
  end
  end
  
  if (_freq and _freq ~= 0) then --shagrat only add beacon if _freq is NOT 0 
    self:_AddBeaconToGroup(_spawnedGroup, _freq)
  end
  
  self:_AddSpecialOptions(_spawnedGroup)

  local _text = _description
  if not forcedesc then
    if _playerName ~= nil then
    if _freq ~= 0 then --shagrat
      _text = "Pilot " .. _playerName
    else
      _text = "TIC - " .. _playerName
    end
    elseif _unitName ~= nil then
        if _freq ~= 0 then --shagrat
      _text = "AI Pilot of " .. _unitName
    else
      _text = "TIC - " .. _unitName
    end
  end
  end   
  self:T({_spawnedGroup, _alias})
  
  local _GroupName = _spawnedGroup:GetName() or _alias

  self:_CreateDownedPilotTrack(_spawnedGroup,_GroupName,_coalition,_unitName,_text,_typeName,_freq,_playerName,wetfeet)

  self:_InitSARForPilot(_spawnedGroup, _unitName, _freq, noMessage) --shagrat use unitName to have the aircraft callsign / descriptive "name" etc.
  
  return self
end

--- (Internal) Function to add a CSAR object into the scene at a zone coordinate. For mission designers wanting to add e.g. PoWs to the scene.
-- @param #CSAR self
-- @param #string _zone Name of the zone. Can also be passed as a (normal, round) ZONE object.
-- @param #number _coalition Coalition.
-- @param #string _description (optional) Description.
-- @param #boolean _randomPoint (optional) Random yes or no.
-- @param #boolean _nomessage (optional) If true, don\'t send a message to SAR.
-- @param #string unitname (optional) Name of the lost unit.
-- @param #string typename (optional) Type of plane.
-- @param #boolean forcedesc (optional) Force to use the description passed only for the pilot track entry. Use to have fully custom names.
function CSAR:_SpawnCsarAtZone( _zone, _coalition, _description, _randomPoint, _nomessage, unitname, typename, forcedesc)
  self:T(self.lid .. " _SpawnCsarAtZone")
  local freq = self:_GenerateADFFrequency()
  
  local _triggerZone = nil
  if type(_zone) == "string" then
    _triggerZone = ZONE:New(_zone) -- trigger to use as reference position
  elseif type(_zone) == "table" and _zone.ClassName then
    if string.find(_zone.ClassName, "ZONE",1) then
      _triggerZone = _zone -- is already a zone
    end
  end
  
  if _triggerZone == nil then
    self:E(self.lid.."ERROR: Can\'t find zone called " .. _zone, 10)
    return
  end
  
  local _description = _description or "PoW"
  local unitname = unitname or "Old Rusty"
  local typename = typename or "Phantom II"
  
  local pos = {}
  if _randomPoint then
    local _pos =  _triggerZone:GetRandomPointVec3()
    pos = COORDINATE:NewFromVec3(_pos)
  else
    pos  = _triggerZone:GetCoordinate()
  end
  
  local _country = 0
  if _coalition == coalition.side.BLUE then
    _country = self.countryblue
  elseif _coalition == coalition.side.RED then
    _country = self.countryred
  else
    _country = self.countryneutral
  end
  
  self:_AddCsar(_coalition, _country, pos, typename, unitname, _description, freq, _nomessage, _description, forcedesc)
  
  return self
end

--- Function to add a CSAR object into the scene at a zone coordinate. For mission designers wanting to add e.g. PoWs to the scene.
-- @param #CSAR self
-- @param #string Zone Name of the zone. Can also be passed as a (normal, round) ZONE object.
-- @param #number Coalition Coalition.
-- @param #string Description (optional) Description.
-- @param #boolean RandomPoint (optional) Random yes or no.
-- @param #boolean Nomessage (optional) If true, don\'t send a message to SAR.
-- @param #string Unitname (optional) Name of the lost unit.
-- @param #string Typename (optional) Type of plane.
-- @param #boolean Forcedesc (optional) Force to use the **description passed only** for the pilot track entry. Use to have fully custom names.
-- @usage If missions designers want to spawn downed pilots into the field, e.g. at mission begin, to give the helicopter guys work, they can do this like so:
--      
--        -- Create downed "Pilot Wagner" in #ZONE "CSAR_Start_1" at a random point for the blue coalition
--        my_csar:SpawnCSARAtZone( "CSAR_Start_1", coalition.side.BLUE, "Wagner", true, false, "Charly-1-1", "F5E" )
function CSAR:SpawnCSARAtZone(Zone, Coalition, Description, RandomPoint, Nomessage, Unitname, Typename, Forcedesc)
  self:_SpawnCsarAtZone(Zone, Coalition, Description, RandomPoint, Nomessage, Unitname, Typename, Forcedesc)
  return self
end

--- (Internal) Function to add a CSAR object into the scene at a Point coordinate (VEC_2). For mission designers wanting to add e.g. casualties to the scene, that don't use beacons.
-- @param #CSAR self
-- @param Core.Point#COORDINATE _Point
-- @param #number _coalition Coalition.
-- @param #string _description (optional) Description.
-- @param #boolean _nomessage (optional) If true, don\'t send a message to SAR.
-- @param #string unitname (optional) Name of the lost unit.
-- @param #string typename (optional) Type of plane.
-- @param #boolean forcedesc (optional) Force to use the description passed only for the pilot track entry. Use to have fully custom names.
function CSAR:_SpawnCASEVAC( _Point, _coalition, _description, _nomessage, unitname, typename, forcedesc) --shagrat added internal Function _SpawnCASEVAC
  self:T(self.lid .. " _SpawnCASEVAC")
       
  local _description = _description or "CASEVAC"
  local unitname = unitname or "CASEVAC"
  local typename = typename or "Ground Commander"
  
  local pos = {}
  pos  = _Point
   
  local _country = 0
  if _coalition == coalition.side.BLUE then
    _country = self.countryblue
  elseif _coalition == coalition.side.RED then
    _country = self.countryred
  else
    _country = self.countryneutral
  end
  --shagrat set frequency to 0 as "flag" for no beacon
  self:_AddCsar(_coalition, _country, pos, typename, unitname, _description, 0, _nomessage, _description, forcedesc)
  
  return self
end

--- Function to add a CSAR object into the scene at a zone coordinate. For mission designers wanting to add e.g. PoWs to the scene.
-- @param #CSAR self
-- @param Core.Point#COORDINATE Point
-- @param #number Coalition Coalition.
-- @param #string Description (optional) Description.
-- @param #boolean addBeacon (optional) yes or no.
-- @param #boolean Nomessage (optional) If true, don\'t send a message to SAR.
-- @param #string Unitname (optional) Name of the lost unit.
-- @param #string Typename (optional) Type of plane.
-- @param #boolean Forcedesc (optional) Force to use the **description passed only** for the pilot track entry. Use to have fully custom names.
-- @usage If missions designers want to spawn downed pilots into the field, e.g. at mission begin, to give the helicopter guys work, they can do this like so:
--      
--        -- Create casualty  "CASEVAC" at coordinate Core.Point#COORDINATE for the blue coalition.
--        my_csar:SpawnCASEVAC( coordinate, coalition.side.BLUE )
function CSAR:SpawnCASEVAC(Point, Coalition, Description, Nomessage, Unitname, Typename, Forcedesc) 
  self:_SpawnCASEVAC(Point, Coalition, Description, Nomessage, Unitname, Typename, Forcedesc)
  return self
end --shagrat end added CASEVAC

--- (Internal) Event handler.
-- @param #CSAR self
function CSAR:_EventHandler(EventData)
  self:T(self.lid .. " _EventHandler")
  self:T({Event = EventData.id})
  
  local _event = EventData -- Core.Event#EVENTDATA
  
    -- no Player  
  if self.enableForAI == false and _event.IniPlayerName == nil then
      return self
  end 
   
  -- no event  
  if _event == nil or _event.initiator == nil then
    return self
  
  -- take off
  elseif _event.id == EVENTS.Takeoff then -- taken off
    self:T(self.lid .. " Event unit - Takeoff")
      
    local _coalition = _event.IniCoalition
    if _coalition ~= self.coalition then
        return self --ignore!
    end
      
    if _event.IniGroupName then
        self.takenOff[_event.IniUnitName] = true
    end
    
    return self
  
  -- player enter unit
  elseif _event.id == EVENTS.PlayerEnterAircraft or _event.id == EVENTS.PlayerEnterUnit then --player entered unit
    self:T(self.lid .. " Event unit - Player Enter")
    
    local _coalition = _event.IniCoalition
    self:T("Coalition = "..UTILS.GetCoalitionName(_coalition))
    if _coalition ~= self.coalition then
        return self --ignore!
    end
    
    if _event.IniPlayerName then
        self.takenOff[_event.IniPlayerName] = nil
    end
    
    -- jumped into flying plane?
    self:T("Taken Off: "..tostring(_event.IniUnit:InAir(true)))
    
    if _event.IniUnit:InAir(true) then
      self.takenOff[_event.IniPlayerName] = true
    end
    
    local _unit = _event.IniUnit
    local _group = _event.IniGroup
    
    local function IsBronco(Group)
      local grp = Group -- Wrapper.Group#GROUP
      local typename = grp:GetTypeName()
      self:T(typename)
      if typename == "Bronco-OV-10A" then return true end
      return false
    end
    
    if _unit:IsHelicopter() or _group:IsHelicopter() or IsBronco(_group) then
      self:_AddMedevacMenuItem()
    end 
    
    return self
  
  elseif (_event.id == EVENTS.PilotDead and self.csarOncrash == false) then
      -- Pilot dead
  
      self:T(self.lid .. " Event unit - Pilot Dead")
  
      local _unit = _event.IniUnit
      local _unitname = _event.IniUnitName
      local _group = _event.IniGroup
      
      if _unit == nil then
          return self -- error!
      end
  
      local _coalition = _event.IniCoalition
      if _coalition ~= self.coalition then
          return self --ignore!
      end
  
      -- Catch multiple events here?
      if self.takenOff[_event.IniUnitName] == true or _group:IsAirborne() then
          if self:_DoubleEjection(_unitname) then
            return self
          end

      else
          self:T(self.lid .. " Pilot has not taken off, ignore")
      end
  
      return self
  
  elseif _event.id == EVENTS.PilotDead or _event.id == EVENTS.Ejection then
      if _event.id == EVENTS.PilotDead and self.csarOncrash == false then 
          return self    
      end
      self:T(self.lid .. " Event unit - Pilot Ejected")
  
      local _unit = _event.IniUnit
      local _unitname = _event.IniUnitName
      local _group = _event.IniGroup
      
      self:T({_unit.UnitName, _unitname, _group.GroupName})
          
      if _unit == nil then
          self:T("Unit NIL!")
          return self -- error!
      end
    
    --local _coalition = _unit:GetCoalition() -- nil now for some reason
    local _coalition = _group:GetCoalition() 
      if _coalition ~= self.coalition then
        self:T("Wrong coalition! Coalition = "..UTILS.GetCoalitionName(_coalition))
          return self --ignore!
      end
      
      
      self:T("Airborne: "..tostring(_group:IsAirborne()))
      self:T("Taken Off: "..tostring(self.takenOff[_event.IniUnitName]))
      
      if not self.takenOff[_event.IniUnitName] and not _group:IsAirborne() then
          self:T(self.lid .. " Pilot has not taken off, ignore")
         -- return self -- give up, pilot hasnt taken off
      end
      
      if self:_DoubleEjection(_unitname) then
        self:T("Double Ejection!")
        return self
      end
      
      -- limit no of pilots in the field.
      if self.limitmaxdownedpilots and self:_ReachedPilotLimit() then
        self:T("Maxed Downed Pilot!")
        return self
      end
    
    
    -- TODO: Over water check --- EVENTS.LandingAfterEjection NOT triggered by DCS, so handle csarUsePara = true case
    -- might create dual pilots in edge cases
    
    local wetfeet = false
    
    local initdcscoord = nil
    local initcoord = nil
    if _event.id == EVENTS.Ejection then
      initdcscoord = _event.TgtDCSUnit:getPoint()
      initcoord = COORDINATE:NewFromVec3(initdcscoord)
      self:T({initdcscoord})
    else
      initdcscoord = _event.IniDCSUnit:getPoint()
      initcoord = COORDINATE:NewFromVec3(initdcscoord)
      self:T({initdcscoord})
    end
    
    --local surface = _unit:GetCoordinate():GetSurfaceType()
    local surface = initcoord:GetSurfaceType()
    
    if surface == land.SurfaceType.WATER then
      self:T("Wet feet!")
      wetfeet = true
    end  
      -- all checks passed, get going.
    if self.csarUsePara == false or (self.csarUsePara and wetfeet ) then --shagrat check parameter LandingAfterEjection, if true don't spawn a Pilot from EJECTION event, wait for the Chute to land
      local _freq = self:_GenerateADFFrequency()
       self:_AddCsar(_coalition, _unit:GetCountry(), initcoord , _unit:GetTypeName(),  _unit:GetName(), _event.IniPlayerName, _freq, false, "none")
      return self
    end
  
  elseif _event.id == EVENTS.Land then
      self:T(self.lid .. " Landing")
      
      if _event.IniUnitName then
          self.takenOff[_event.IniUnitName] = nil
      end
  
      if self.allowFARPRescue then
          
          local _unit = _event.IniUnit  -- Wrapper.Unit#UNIT
  
          if _unit == nil then
              self:T(self.lid .. " Unit nil on landing")
              return self -- error!
          end
          
          --local _coalition = _event.IniCoalition
          local _coalition = _event.IniGroup:GetCoalition()
          if _coalition ~= self.coalition then
            self:T(self.lid .. " Wrong coalition")
              return self --ignore!
          end
          
          self.takenOff[_event.IniUnitName] = nil
 
          local _place = _event.Place -- Wrapper.Airbase#AIRBASE
          
          if _place == nil then
              self:T(self.lid .. " Landing Place Nil")
              return self -- error!
          end
          
          -- anyone on board?
          if self.inTransitGroups[_event.IniUnitName] == nil then
            -- ignore
            return self
          end
   
          if _place:GetCoalition() == self.coalition or _place:GetCoalition() == coalition.side.NEUTRAL then
            self:__Landed(2,_event.IniUnitName, _place)
            self:_ScheduledSARFlight(_event.IniUnitName,_event.IniGroupName,true)
          else
              self:T(string.format("Airfield %d, Unit %d", _place:GetCoalition(), _unit:GetCoalition()))
              end
          end
  
          return self
      end
      
  ---- shagrat on event LANDING_AFTER_EJECTION spawn pilot at parachute location
  if (_event.id == EVENTS.LandingAfterEjection and self.csarUsePara == true) then
    self:T("LANDING_AFTER_EJECTION")
    local _LandingPos = COORDINATE:NewFromVec3(_event.initiator:getPosition().p)
    local _unitname = "Aircraft" --_event.initiator:getName() or "Aircraft" --shagrat Optional use of Object name which is unfortunately 'f15_Pilot_Parachute'
    local _typename = "Ejected Pilot" --_event.Initiator.getTypeName() or "Ejected Pilot" 
    local _country = _event.initiator:getCountry()
    local _coalition = coalition.getCountryCoalition( _country )
    self:T("Country = ".._country.." Coalition = ".._coalition)
    if _coalition == self.coalition then
      local _freq = self:_GenerateADFFrequency()
      self:I({coalition=_coalition,country= _country, coord=_LandingPos, name=_unitname, player=_event.IniPlayerName, freq=_freq})
      self:_AddCsar(_coalition, _country, _LandingPos, nil, _unitname, _event.IniPlayerName, _freq, false, "none")--shagrat add CSAR at Parachute location.
    
      Unit.destroy(_event.initiator) -- shagrat remove static Pilot model
    end 
  end
  
  return self
end

--- (Internal)  Initialize the action for a pilot.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP _downedGroup The group to rescue.
-- @param #string _GroupName Name of the Group
-- @param #number _freq Beacon frequency.
-- @param #boolean _nomessage Send message true or false.
function CSAR:_InitSARForPilot(_downedGroup, _GroupName, _freq, _nomessage)
  self:T(self.lid .. " _InitSARForPilot")
  local _leader = _downedGroup:GetUnit(1)
  local _groupName = _GroupName
  local _freqk = _freq / 1000
  local _coordinatesText = self:_GetPositionOfWounded(_downedGroup)
  local _leadername = _leader:GetName()
  
  if not _nomessage then
  if _freq ~= 0 then --shagrat
    local _text = string.format("%s requests SAR at %s, beacon at %.2f KHz", _groupName, _coordinatesText, _freqk)--shagrat _groupName to prevent 'f15_Pilot_Parachute'
    self:_DisplayToAllSAR(_text,self.coalition,self.messageTime)
  else --shagrat CASEVAC msg
    local _text = string.format("Pickup Zone at %s.", _coordinatesText )
    self:_DisplayToAllSAR(_text,self.coalition,self.messageTime)
  end 
  end
  
  for _,_heliName in pairs(self.csarUnits) do
    self:_CheckWoundedGroupStatus(_heliName, _groupName)
  end

   -- trigger FSM event
  self:__PilotDown(2,_downedGroup, _freqk, _groupName, _coordinatesText)
  
  return self
end

--- (Internal) Check if a name is in downed pilot table
-- @param #CSAR self
-- @param #string name Name to search for.
-- @return #boolean Outcome.
-- @return #CSAR.DownedPilot Table if found else nil.
function CSAR:_CheckNameInDownedPilots(name)
  local PilotTable = self.downedPilots --#CSAR.DownedPilot
  local found = false
  local table = nil
  for _,_pilot in pairs(PilotTable) do
    if _pilot.name == name and _pilot.alive == true then
      found = true
      table = _pilot
      break
    end  
  end
  return found, table
end

--- (Internal) Check if a name is in downed pilot table and remove it.
-- @param #CSAR self
-- @param #string name Name to search for.
-- @param #boolean force Force removal.
-- @return #boolean Outcome.
function CSAR:_RemoveNameFromDownedPilots(name,force)
  local PilotTable = self.downedPilots --#CSAR.DownedPilot
  local found = false
  for _index,_pilot in pairs(PilotTable) do
    if _pilot.name == name then
      self.downedPilots[_index].alive = false
    end
  end
  return found
end

--- [User] Set callsign options for TTS output. See @{Wrapper.Group#GROUP.GetCustomCallSign}() on how to set customized callsigns.
-- @param #CSAR self
-- @param #boolean ShortCallsign If true, only call out the major flight number
-- @param #boolean Keepnumber If true, keep the **customized callsign** in the #GROUP name for players as-is, no amendments or numbers.
-- @param #table CallsignTranslations (optional) Table to translate between DCS standard callsigns and bespoke ones. Does not apply if using customized
-- callsigns from playername or group name.
-- @return #CSAR self
function CSAR:SetCallSignOptions(ShortCallsign,Keepnumber,CallsignTranslations)
  if not ShortCallsign or ShortCallsign == false then
   self.ShortCallsign = false
  else
   self.ShortCallsign = true
  end
  self.Keepnumber = Keepnumber or false
  self.CallsignTranslations = CallsignTranslations
  return self  
end

--- (Internal) Check if a name is in downed pilot table and remove it.
-- @param #CSAR self
-- @param #string UnitName
-- @return #string CallSign
function CSAR:_GetCustomCallSign(UnitName)
  local callsign = Unitname
  local unit = UNIT:FindByName(UnitName)
  if unit and unit:IsAlive() then
    local group = unit:GetGroup()
    callsign = group:GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations)
  end
  return callsign
end

--- (Internal) Check state of wounded group.
-- @param #CSAR self
-- @param #string heliname heliname
-- @param #string woundedgroupname woundedgroupname
function CSAR:_CheckWoundedGroupStatus(heliname,woundedgroupname)
  self:T(self.lid .. " _CheckWoundedGroupStatus")
  local _heliName = heliname
  local _woundedGroupName = woundedgroupname
  self:T({Heli = _heliName, Downed  = _woundedGroupName})
  -- if wounded group is not here then message already been sent to SARs
  -- stop processing any further
  local _found, _downedpilot = self:_CheckNameInDownedPilots(_woundedGroupName)
  if not _found then
    self:T("...not found in list!")
    return
  end
  
  local _woundedGroup = _downedpilot.group
  if _woundedGroup ~= nil and _woundedGroup:IsAlive() then 
    local _heliUnit = self:_GetSARHeli(_heliName) -- Wrapper.Unit#UNIT
    
    local _lookupKeyHeli = _heliName .. "_" .. _woundedGroupName --lookup key for message state tracking
            
    if _heliUnit == nil then
      self.heliVisibleMessage[_lookupKeyHeli] = nil
      self.heliCloseMessage[_lookupKeyHeli] = nil
      self.landedStatus[_lookupKeyHeli] = nil
      self:T("...heliunit nil!")
      return
    end
    
    local _heliCoord = _heliUnit:GetCoordinate()
    local _leaderCoord = _woundedGroup:GetCoordinate()
    local _distance = self:_GetDistance(_heliCoord,_leaderCoord)
    -- autosmoke
    if (self.autosmoke == true) and (_distance < self.autosmokedistance) and (_distance ~= -1) then
        self:_PopSmokeForGroup(_woundedGroupName, _woundedGroup)
    end
    
    if _distance < self.approachdist_near and _distance > 0 then
      if self:_CheckCloseWoundedGroup(_distance, _heliUnit, _heliName, _woundedGroup, _woundedGroupName) == true then
        -- we\'re close, reschedule
        _downedpilot.timestamp = timer.getAbsTime()
        self:__Approach(-5,heliname,woundedgroupname)
      end
    elseif _distance >= self.approachdist_near and _distance < self.approachdist_far then
      -- message once
      if self.heliVisibleMessage[_lookupKeyHeli] == nil then
          local _pilotName = _downedpilot.desc
          if self.autosmoke == true then
            local dist = self.autosmokedistance / 1000
            local disttext = string.format("%.0fkm",dist)
            if _SETTINGS:IsImperial() then
              local dist = UTILS.MetersToNM(self.autosmokedistance)
              disttext = string.format("%.0fnm",dist)
            end
            self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. I hear you! Finally, that is music in my ears!\nI'll pop a smoke when you are %s away.\nLand or hover by the smoke.", self:_GetCustomCallSign(_heliName), _pilotName, disttext), self.messageTime,false,true)
          else
            self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. I hear you! Finally, that is music in my ears!\nRequest a flare or smoke if you need.", self:_GetCustomCallSign(_heliName), _pilotName), self.messageTime,false,true)
          end
          --mark as shown for THIS heli and THIS group
          self.heliVisibleMessage[_lookupKeyHeli] = true     
      end    
      self.heliCloseMessage[_lookupKeyHeli] = nil
      self.landedStatus[_lookupKeyHeli] = nil
      --reschedule as units aren\'t dead yet , schedule for a bit slower though as we\'re far away
      _downedpilot.timestamp = timer.getAbsTime()
      self:__Approach(-10,heliname,woundedgroupname)
    end
  else
  self:T("...Downed Pilot KIA?!")
  if not _downedpilot.alive then
    --self:__KIA(1,_downedpilot.name)
    self:_RemoveNameFromDownedPilots(_downedpilot.name, true)
  end
  end
  return self
end

--- (Internal) Function to pop a smoke at a wounded pilot\'s positions.
-- @param #CSAR self
-- @param #string _woundedGroupName Name of the group.
-- @param Wrapper.Group#GROUP _woundedLeader Object of the group.
function CSAR:_PopSmokeForGroup(_woundedGroupName, _woundedLeader)
  self:T(self.lid .. " _PopSmokeForGroup")
  -- have we popped smoke already in the last 5 mins
  local _lastSmoke = self.smokeMarkers[_woundedGroupName]
  if _lastSmoke == nil or timer.getTime() > _lastSmoke then
  
      local _smokecolor = self.smokecolor
      local _smokecoord = _woundedLeader:GetCoordinate():Translate( 6, math.random( 1, 360) ) --shagrat place smoke at a random 6 m distance, so smoke does not obscure the pilot
      _smokecoord:Smoke(_smokecolor)
      self.smokeMarkers[_woundedGroupName] = timer.getTime() + 300 -- next smoke time
  end
  return self
end

--- (Internal) Function to pickup the wounded pilot from the ground.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _heliUnit Object of the group.
-- @param #string _pilotName Name of the pilot.
-- @param Wrapper.Group#GROUP _woundedGroup Object of the group.
-- @param #string _woundedGroupName Name of the group.
function CSAR:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
  self:T(self.lid .. " _PickupUnit")
  -- board
  local _heliName = _heliUnit:GetName()
  local _groups = self.inTransitGroups[_heliName]
  local _unitsInHelicopter = self:_PilotsOnboard(_heliName)
  
  -- init table if there is none for this helicopter
  if not _groups then
      self.inTransitGroups[_heliName] = {}
      _groups = self.inTransitGroups[_heliName]
  end
  
  -- if the heli can\'t pick them up, show a message and return
  local _maxUnits = self.AircraftType[_heliUnit:GetTypeName()]
  if _maxUnits == nil then
    _maxUnits = self.max_units
  end
  if _unitsInHelicopter + 1 > _maxUnits then
      self:_DisplayMessageToSAR(_heliUnit, string.format("%s, %s. We\'re already crammed with %d guys! Sorry!", _pilotName, self:_GetCustomCallSign(_heliName), _unitsInHelicopter, _unitsInHelicopter), self.messageTime,false,false,true)
      return self
  end
  
  local found,downedgrouptable = self:_CheckNameInDownedPilots(_woundedGroupName)
  local grouptable = downedgrouptable --#CSAR.DownedPilot
  self.inTransitGroups[_heliName][_woundedGroupName] =
  {
      originalUnit = grouptable.originalUnit,
      woundedGroup = _woundedGroupName,
      side = self.coalition,
      desc = grouptable.desc,
      player = grouptable.player,
  }

  _woundedGroup:Destroy(false)
  self:_RemoveNameFromDownedPilots(_woundedGroupName,true)
  
  self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s I\'m in! Get to the MASH ASAP! ", self:_GetCustomCallSign(_heliName), _pilotName), self.messageTime,true,true)
  
  self:_UpdateUnitCargoMass(_heliName)
  
  self:__Boarded(5,_heliName,_woundedGroupName,grouptable.desc)
  
  return self
end

--- (Internal) Function to calculate and set Unit internal cargo mass
-- @param #CSAR self
-- @param #string _heliName Unit name
-- @return #CSAR self
function CSAR:_UpdateUnitCargoMass(_heliName)
  self:T(self.lid .. " _UpdateUnitCargoMass")
  local calculatedMass = self:_PilotsOnboard(_heliName)*(self.PilotWeight or 80)
  local Unit = UNIT:FindByName(_heliName)
  if Unit then
    Unit:SetUnitInternalCargo(calculatedMass)
  end
  return self
end

--- (Internal) Move group to destination.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP _leader
-- @param Core.Point#COORDINATE _destination
function CSAR:_OrderGroupToMoveToPoint(_leader, _destination)
  self:T(self.lid .. " _OrderGroupToMoveToPoint")
  local group = _leader
  local coordinate = _destination:GetVec2()

  group:SetAIOn()
  group:RouteToVec2(coordinate,5)
  return self
end

--- (internal) Function to check if the heli door(s) are open. Thanks to Shadowze.
-- @param #CSAR self
-- @param #string unit_name Name of unit.
-- @return #boolean outcome The outcome.
function CSAR:_IsLoadingDoorOpen( unit_name )
  self:T(self.lid .. " _IsLoadingDoorOpen")
  return UTILS.IsLoadingDoorOpen(unit_name)
end

--- (Internal) Function to check if heli is close to group.
-- @param #CSAR self
-- @param #number _distance
-- @param Wrapper.Unit#UNIT _heliUnit
-- @param #string _heliName
-- @param Wrapper.Group#GROUP _woundedGroup
-- @param #string _woundedGroupName
-- @return #boolean Outcome
function CSAR:_CheckCloseWoundedGroup(_distance, _heliUnit, _heliName, _woundedGroup, _woundedGroupName)
  self:T(self.lid .. " _CheckCloseWoundedGroup")

  local _woundedLeader = _woundedGroup
  local _lookupKeyHeli = _heliUnit:GetName() .. "_" .. _woundedGroupName --lookup key for message state tracking
  
  local _found, _pilotable = self:_CheckNameInDownedPilots(_woundedGroupName) -- #boolean, #CSAR.DownedPilot
  local _pilotName = _pilotable.desc

  
  local _reset = true
  
  if (_distance < 500) then
  
      if self.heliCloseMessage[_lookupKeyHeli] == nil then
          if self.autosmoke == true then
            self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. You\'re close now! Land or hover at the smoke.", self:_GetCustomCallSign(_heliName), _pilotName), self.messageTime,false,true)
          else
            self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. You\'re close now! Land in a safe place, I will go there ", self:_GetCustomCallSign(_heliName), _pilotName), self.messageTime,false,true)
          end
          self.heliCloseMessage[_lookupKeyHeli] = true
      end
  
      -- have we landed close enough?
      if not _heliUnit:InAir() then
  
        if self.pilotRuntoExtractPoint == true then
            if (_distance < self.extractDistance) then
              local _time = self.landedStatus[_lookupKeyHeli]
              if _time == nil then
                  self.landedStatus[_lookupKeyHeli] = math.floor( (_distance - self.loadDistance) / 3.6 )   
                  _time = self.landedStatus[_lookupKeyHeli]
                  _woundedGroup:OptionAlarmStateGreen() 
                  self:_OrderGroupToMoveToPoint(_woundedGroup, _heliUnit:GetCoordinate())
                  self:_DisplayMessageToSAR(_heliUnit, "Wait till " .. _pilotName .. " gets in. \nETA " .. _time .. " more seconds.", self.messageTime, false)
              else
                  _time = self.landedStatus[_lookupKeyHeli] - 10
                  self.landedStatus[_lookupKeyHeli] = _time
              end
              --if _time <= 0 or _distance < self.loadDistance then
              if _distance < self.loadDistance + 5 or _distance <= 13 then
                 if self.pilotmustopendoors and (self:_IsLoadingDoorOpen(_heliName) == false) then
                  self:_DisplayMessageToSAR(_heliUnit, "Open the door to let me in!", self.messageTime, true, true)
                  return false
                 else
                   self.landedStatus[_lookupKeyHeli] = nil
                   self:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
                   return true
                 end
              end
            end
        else
          if (_distance < self.loadDistance) then
              if self.pilotmustopendoors and (self:_IsLoadingDoorOpen(_heliName) == false) then
                self:_DisplayMessageToSAR(_heliUnit, "Open the door to let me in!", self.messageTime, true, true)
                return false
              else
                self:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
                return true
              end
          end
        end
      else
  
          local _unitsInHelicopter = self:_PilotsOnboard(_heliName)
          local _maxUnits = self.AircraftType[_heliUnit:GetTypeName()]
          if _maxUnits == nil then
            _maxUnits = self.max_units
          end
          
          if _heliUnit:InAir() and _unitsInHelicopter + 1 <= _maxUnits then
              -- DONE - make variable
              if _distance < self.rescuehoverdistance then
  
                  --check height!
                  local leaderheight = _woundedLeader:GetHeight()
                  if leaderheight < 0 then leaderheight = 0 end
                  local _height = _heliUnit:GetHeight() - leaderheight
                  
                  -- DONE - make variable
                  if _height <= self.rescuehoverheight then
  
                      local _time = self.hoverStatus[_lookupKeyHeli]
  
                      if _time == nil then
                          self.hoverStatus[_lookupKeyHeli] = 10
                          _time = 10
                      else
                          _time = self.hoverStatus[_lookupKeyHeli] - 10
                          self.hoverStatus[_lookupKeyHeli] = _time
                      end
  
                      if _time > 0 then
                          self:_DisplayMessageToSAR(_heliUnit, "Hovering above " .. _pilotName .. ". \n\nHold hover for " .. _time .. " seconds to winch them up. \n\nIf the countdown stops you\'re too far away!", self.messageTime, true)
                      else
                       if self.pilotmustopendoors and (self:_IsLoadingDoorOpen(_heliName) == false) then
                          self:_DisplayMessageToSAR(_heliUnit, "Open the door to let me in!", self.messageTime, true, true)
                          return false
                        else
                          self.hoverStatus[_lookupKeyHeli] = nil
                          self:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
                          return true
                        end
                      end
                      _reset = false
                  else
                      self:_DisplayMessageToSAR(_heliUnit, "Too high to winch " .. _pilotName .. " \nReduce height and hover for 10 seconds!", self.messageTime, true,true)
                      return false
                  end
              end
          
          end
      end
  end
  
  if _reset then
      self.hoverStatus[_lookupKeyHeli] = nil
  end
  
  if _distance < 500 then
    return true
  else
    return false
  end
end

--- (Internal) Monitor in-flight returning groups.
-- @param #CSAR self
-- @param #string heliname Heli name
-- @param #string groupname Group name
-- @param #boolean isairport If true, EVENT.Landing took place at an airport or FARP
function CSAR:_ScheduledSARFlight(heliname,groupname, isairport)
  self:T(self.lid .. " _ScheduledSARFlight")
  self:T({heliname,groupname})
  local _heliUnit = self:_GetSARHeli(heliname)
  local _woundedGroupName = groupname

  if (_heliUnit == nil) then
      --helicopter crashed?
      self.inTransitGroups[heliname] = nil
      return
  end

  if self.inTransitGroups[heliname] == nil or self.inTransitGroups[heliname][_woundedGroupName] == nil then
      -- Groups already rescued
      return
  end

  local _dist = self:_GetClosestMASH(_heliUnit)

  if _dist == -1 then
      return
  end

  if ( _dist < self.FARPRescueDistance or isairport ) and _heliUnit:InAir() == false then
    if self.pilotmustopendoors and self:_IsLoadingDoorOpen(heliname) == false then
      self:_DisplayMessageToSAR(_heliUnit, "Open the door to let me out!", self.messageTime, true, true)
    else
      self:_RescuePilots(_heliUnit)
      return
    end
  end

  --queue up
  self:__Returning(-5,heliname,_woundedGroupName, isairport)
  return self
end

--- (Internal) Mark pilot as rescued and remove from tables.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _heliUnit
function CSAR:_RescuePilots(_heliUnit)
  self:T(self.lid .. " _RescuePilots")
  local _heliName = _heliUnit:GetName()
  local _rescuedGroups = self.inTransitGroups[_heliName]
  
  if _rescuedGroups == nil then
      -- Groups already rescued
      return
  end

  local PilotsSaved = self:_PilotsOnboard(_heliName)
  
  self.inTransitGroups[_heliName] = nil
  
  local _txt = string.format("%s: The %d pilot(s) have been taken to the\nmedical clinic. Good job!", self:_GetCustomCallSign(_heliName), PilotsSaved)
  
  self:_DisplayMessageToSAR(_heliUnit, _txt, self.messageTime)
  
  self:_UpdateUnitCargoMass(_heliName)
  
  -- trigger event
  self:__Rescued(-1,_heliUnit,_heliName, PilotsSaved)
  return self
end

--- (Internal) Check and return Wrappe.Unit#UNIT based on the name if alive.
-- @param #CSAR self
-- @param #string _unitname Name of Unit
-- @return Wrapper.Unit#UNIT The unit or nil
function CSAR:_GetSARHeli(_unitName)
  self:T(self.lid .. " _GetSARHeli")
  local unit = UNIT:FindByName(_unitName)
  if unit and unit:IsAlive() then
    return unit
  else
    return nil
  end
end

--- (Internal) Display message to single Unit.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _unit Unit #UNIT to display to.
-- @param #string _text Text of message.
-- @param #number _time Message show duration.
-- @param #boolean _clear (optional) Clear screen.
-- @param #boolean _speak (optional) Speak message via SRS.
-- @param #boolean _override (optional) Override message suppression
function CSAR:_DisplayMessageToSAR(_unit, _text, _time, _clear, _speak, _override)
  self:T(self.lid .. " _DisplayMessageToSAR")
  local group = _unit:GetGroup()
  local _clear = _clear or nil
  local _time = _time or self.messageTime
  if _override or not self.suppressmessages then
    local m = MESSAGE:New(_text,_time,"CSAR",_clear):ToGroup(group)
  end
  -- integrate SRS
  if _speak and self.useSRS then
    self.SRSQueue:NewTransmission(_text,nil,self.msrs,nil,2)
  end
  return self
end

--- (Internal) Function to get string of a group\'s position.
-- @param #CSAR self
-- @param Wrapper.Controllable#CONTROLLABLE _woundedGroup Group or Unit object.
-- @return #string Coordinates as Text
function CSAR:_GetPositionOfWounded(_woundedGroup)
  self:T(self.lid .. " _GetPositionOfWounded")
  local _coordinate = _woundedGroup:GetCoordinate()
  local _coordinatesText = "None"
  if _coordinate then
    if self.coordtype == 0 then -- Lat/Long DMTM
      _coordinatesText = _coordinate:ToStringLLDDM()
    elseif self.coordtype == 1 then -- Lat/Long DMS
      _coordinatesText = _coordinate:ToStringLLDMS()  
    elseif self.coordtype == 2 then -- MGRS
      _coordinatesText = _coordinate:ToStringMGRS()  
    else -- Bullseye Metric --(medevac.coordtype == 4 or 3)
      _coordinatesText = _coordinate:ToStringBULLS(self.coalition)
    end
  end
  return _coordinatesText
end

--- (Internal) Display active SAR tasks to player.
-- @param #CSAR self
-- @param #string _unitName Unit to display to
function CSAR:_DisplayActiveSAR(_unitName)
  self:T(self.lid .. " _DisplayActiveSAR")
  local _msg = "Active MEDEVAC/SAR:"  
  local _heli = self:_GetSARHeli(_unitName) -- Wrapper.Unit#UNIT
  if _heli == nil then
      return
  end
  
  local _heliSide = self.coalition
  local _csarList = {}
  
  local _DownedPilotTable = self.downedPilots
  self:T({Table=_DownedPilotTable})
  for _, _value in pairs(_DownedPilotTable) do
    local _groupName = _value.name
    self:T(string.format("Display Active Pilot: %s", tostring(_groupName)))
    self:T({Table=_value})
    local _woundedGroup = _value.group
    if _woundedGroup and _value.alive then  
        local _coordinatesText = self:_GetPositionOfWounded(_woundedGroup) 
        local _helicoord =  _heli:GetCoordinate()
        local _woundcoord = _woundedGroup:GetCoordinate()
        local _distance = self:_GetDistance(_helicoord, _woundcoord)
        self:T({_distance = _distance})
        local distancetext = ""
        if _SETTINGS:IsImperial() then
          distancetext = string.format("%.1fnm",UTILS.MetersToNM(_distance))
        else
          distancetext = string.format("%.1fkm", _distance/1000.0)
        end
    if _value.frequency == 0 then--shagrat insert CASEVAC without Frequency
      table.insert(_csarList, { dist = _distance, msg = string.format("%s at %s - %s ", _value.desc, _coordinatesText, distancetext) })
    else
      table.insert(_csarList, { dist = _distance, msg = string.format("%s at %s - %.2f KHz ADF - %s ", _value.desc, _coordinatesText, _value.frequency / 1000, distancetext) })
    end
    end
  end
  
  local function sortDistance(a, b)
      return a.dist < b.dist
  end
  
  table.sort(_csarList, sortDistance)
  
  for _, _line in pairs(_csarList) do
      _msg = _msg .. "\n" .. _line.msg
  end
  
  self:_DisplayMessageToSAR(_heli, _msg, self.messageTime*2, false, false, true)
  return self
end

--- (Internal) Find the closest downed pilot to a heli.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _heli Helicopter #UNIT
-- @return #table Table of results
function CSAR:_GetClosestDownedPilot(_heli)
  self:T(self.lid .. " _GetClosestDownedPilot")
  local _side = self.coalition
  local _closestGroup = nil
  local _shortestDistance = -1
  local _distance = 0
  local _closestGroupInfo = nil
  local _heliCoord = _heli:GetCoordinate() or _heli:GetCoordinate()
  
  if _heliCoord == nil then 
    self:E("****Error obtaining coordinate!")
    return nil 
  end
  
  local DownedPilotsTable = self.downedPilots
  
  for _, _groupInfo in UTILS.spairs(DownedPilotsTable) do 
  --for _, _groupInfo in pairs(DownedPilotsTable) do
      local _woundedName = _groupInfo.name
      local _tempWounded = _groupInfo.group
      
      -- check group exists and not moving to someone else
      if _tempWounded then
          local _tempCoord = _tempWounded:GetCoordinate()
          _distance = self:_GetDistance(_heliCoord, _tempCoord)

          if _distance ~= nil and (_shortestDistance == -1 or _distance < _shortestDistance) then
              _shortestDistance = _distance
              _closestGroup = _tempWounded
              _closestGroupInfo = _groupInfo
          end
      end
  end

  return { pilot = _closestGroup, distance = _shortestDistance, groupInfo = _closestGroupInfo }
end

--- (Internal) Fire a flare at the point of a downed pilot.
-- @param #CSAR self
-- @param #string _unitName Name of the unit.
function CSAR:_SignalFlare(_unitName)
  self:T(self.lid .. " _SignalFlare")
  local _heli = self:_GetSARHeli(_unitName)
  if _heli == nil then
      return
  end
  
  local _closest = self:_GetClosestDownedPilot(_heli)
  local smokedist = 8000
  if self.approachdist_far > smokedist then smokedist = self.approachdist_far end
  if _closest ~= nil and _closest.pilot ~= nil and _closest.distance > 0 and _closest.distance < smokedist then
  
      local _clockDir = self:_GetClockDirection(_heli, _closest.pilot)
      local _distance = 0
      if _SETTINGS:IsImperial() then
        _distance = string.format("%.1fnm",UTILS.MetersToNM(_closest.distance))
      else
        _distance = string.format("%.1fkm",_closest.distance/1000)
      end 
      local _msg = string.format("%s - Popping signal flare at your %s o\'clock. Distance %s", self:_GetCustomCallSign(_unitName), _clockDir, _distance)
      self:_DisplayMessageToSAR(_heli, _msg, self.messageTime, false, true, true)
      
      local _coord = _closest.pilot:GetCoordinate()
      _coord:FlareRed(_clockDir)
  else
      local _distance = smokedist
      if _SETTINGS:IsImperial() then
        _distance = string.format("%.1fnm",UTILS.MetersToNM(smokedist))
      else
        _distance = string.format("%.1fkm",smokedist/1000)
      end 
      self:_DisplayMessageToSAR(_heli, string.format("No Pilots within %s",_distance), self.messageTime, false, false, true)
  end
  return self
end

--- (Internal) Display info to all SAR groups.
-- @param #CSAR self
-- @param #string _message Message to display.
-- @param #number _side Coalition of message.
-- @param #number _messagetime How long to show.
function CSAR:_DisplayToAllSAR(_message, _side, _messagetime)
  self:T(self.lid .. " _DisplayToAllSAR")
  local messagetime = _messagetime or self.messageTime
  for _, _unitName in pairs(self.csarUnits) do
    local _unit = self:_GetSARHeli(_unitName)
    if _unit and not self.suppressmessages then
       self:_DisplayMessageToSAR(_unit, _message, _messagetime)
    end
  end
  return self
end

---(Internal) Request smoke at closest downed pilot.
--@param #CSAR self
--@param #string _unitName Name of the helicopter
function CSAR:_Reqsmoke( _unitName )
  self:T(self.lid .. " _Reqsmoke")
  local _heli = self:_GetSARHeli(_unitName)
  if _heli == nil then
      return
  end
  local smokedist = 8000
  if smokedist < self.approachdist_far then smokedist = self.approachdist_far end
  local _closest = self:_GetClosestDownedPilot(_heli)
  if _closest ~= nil and _closest.pilot ~= nil and _closest.distance > 0 and _closest.distance < smokedist then
      local _clockDir = self:_GetClockDirection(_heli, _closest.pilot)
      local _distance = 0
      if _SETTINGS:IsImperial() then
        _distance = string.format("%.1fnm",UTILS.MetersToNM(_closest.distance))
      else
        _distance = string.format("%.1fkm",_closest.distance/1000)
      end 
      local _msg = string.format("%s - Popping smoke at your %s o\'clock. Distance %s", self:_GetCustomCallSign(_unitName), _clockDir, _distance)
      self:_DisplayMessageToSAR(_heli, _msg, self.messageTime, false, true, true)
      local _coord = _closest.pilot:GetCoordinate()
      local color = self.smokecolor
      _coord:Smoke(color)
  else
      local _distance = 0
      if _SETTINGS:IsImperial() then
        _distance = string.format("%.1fnm",UTILS.MetersToNM(smokedist))
      else
        _distance = string.format("%.1fkm",smokedist/1000)
      end 
      self:_DisplayMessageToSAR(_heli, string.format("No Pilots within %s",_distance), self.messageTime, false, false, true)
  end
  return self
end

--- (Internal) Determine distance to closest MASH.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _heli Helicopter #UNIT
-- @retunr
function CSAR:_GetClosestMASH(_heli)
  self:T(self.lid .. " _GetClosestMASH")
  local _mashset = self.mash -- Core.Set#SET_GROUP
  local _mashes = _mashset:GetSetObjects() -- #table
  local _shortestDistance = -1
  local _distance = 0
  local _helicoord = _heli:GetCoordinate()
  
  local function GetCloseAirbase(coordinate,Coalition,Category)
      
      local a=coordinate:GetVec3()
      local distmin=math.huge
      local airbase=nil
      for DCSairbaseID, DCSairbase in pairs(world.getAirbases(Coalition)) do
        local b=DCSairbase:getPoint()
  
        local c=UTILS.VecSubstract(a,b)
        local dist=UTILS.VecNorm(c)
  
        if dist<distmin and (Category==nil or Category==DCSairbase:getDesc().category) then
          distmin=dist
          airbase=DCSairbase
        end
  
      end  
      return distmin
  end
  
  if self.allowFARPRescue then
    local position = _heli:GetCoordinate()
    local afb,distance = position:GetClosestAirbase(nil,self.coalition)
    _shortestDistance = distance
  end
  
  for _, _mashUnit in pairs(_mashes) do
      if _mashUnit and _mashUnit:IsAlive() then
          local _mashcoord = _mashUnit:GetCoordinate()
          _distance = self:_GetDistance(_helicoord, _mashcoord)
          if _distance ~= nil and (_shortestDistance == -1 or _distance < _shortestDistance) then
            _shortestDistance = _distance
          end
      end
  end
  
  if _shortestDistance ~= -1 then
      return _shortestDistance
  else
      return -1
  end
end

--- (Internal) Display onboarded rescued pilots.
-- @param #CSAR self
-- @param #string _unitName Name of the chopper
function CSAR:_CheckOnboard(_unitName)
  self:T(self.lid .. " _CheckOnboard")
    local _unit = self:_GetSARHeli(_unitName)
    if _unit == nil then
        return
    end
    --list onboard pilots
    local _inTransit = self.inTransitGroups[_unitName]
    if _inTransit == nil then
        self:_DisplayMessageToSAR(_unit, "No Rescued Pilots onboard", self.messageTime, false, false, true)
    else
        local _text = "Onboard - RTB to FARP/Airfield or MASH: "
        for _, _onboard in pairs(self.inTransitGroups[_unitName]) do
            _text = _text .. "\n" .. _onboard.desc
        end
        self:_DisplayMessageToSAR(_unit, _text, self.messageTime*2, false, false, true)
    end
    return self
end

--- (Internal) Populate F10 menu for CSAR players.
-- @param #CSAR self
function CSAR:_AddMedevacMenuItem()
  self:T(self.lid .. " _AddMedevacMenuItem")
  
  local coalition = self.coalition
  local allheligroupset = self.allheligroupset -- Core.Set#SET_GROUP
  local _allHeliGroups = allheligroupset:GetSetObjects()

  -- rebuild units table
  local _UnitList = {}
  for _key, _group in pairs (_allHeliGroups) do  
    local _unit = _group:GetUnit(1) -- Asume that there is only one unit in the flight for players
    if _unit then 
      if _unit:IsAlive() and _unit:IsPlayer() then         
        local unitName = _unit:GetName()
            _UnitList[unitName] = unitName
      end -- end isAlive
    end -- end if _unit
  end -- end for
  self.csarUnits = _UnitList
  
  -- build unit menus  
  for _, _unitName in pairs(self.csarUnits) do
    local _unit = self:_GetSARHeli(_unitName) -- Wrapper.Unit#UNIT
    if _unit then
      local _group = _unit:GetGroup() -- Wrapper.Group#GROUP
      if _group then
        local groupname = _group:GetName()
        if self.addedTo[groupname] == nil then
          self.addedTo[groupname] = true
          local menuname = self.topmenuname or "CSAR"
          local _rootPath = MENU_GROUP:New(_group,menuname)
          local _rootMenu1 = MENU_GROUP_COMMAND:New(_group,"List Active CSAR",_rootPath, self._DisplayActiveSAR,self,_unitName)
          local _rootMenu2 = MENU_GROUP_COMMAND:New(_group,"Check Onboard",_rootPath, self._CheckOnboard,self,_unitName)
          local _rootMenu3 = MENU_GROUP_COMMAND:New(_group,"Request Signal Flare",_rootPath, self._SignalFlare,self,_unitName)
          local _rootMenu4 = MENU_GROUP_COMMAND:New(_group,"Request Smoke",_rootPath, self._Reqsmoke,self,_unitName):Refresh()
        end
      end
    end
  end  
  return self
end

--- (Internal) Return distance in meters between two coordinates.
-- @param #CSAR self
-- @param Core.Point#COORDINATE _point1 Coordinate one
-- @param Core.Point#COORDINATE _point2 Coordinate two
-- @return #number Distance in meters
function CSAR:_GetDistance(_point1, _point2)
  self:T(self.lid .. " _GetDistance")
  if _point1 and _point2 then
    local distance1 = _point1:Get2DDistance(_point2)
    local distance2 = _point1:DistanceFromPointVec2(_point2)
    if distance1 and type(distance1) == "number" then
      return distance1
    elseif distance2 and type(distance2) == "number" then
      return distance2
    else
      self:E("*****Cannot calculate distance!")
      self:E({_point1,_point2})
      return -1
    end
  else
    self:E("******Cannot calculate distance!")
    self:E({_point1,_point2})
    return -1
  end
end

--- (Internal) Populate table with available beacon frequencies.
-- @param #CSAR self
function CSAR:_GenerateVHFrequencies()
  self:T(self.lid .. " _GenerateVHFrequencies")
      
  local FreeVHFFrequencies = {}
  FreeVHFFrequencies = UTILS.GenerateVHFrequencies()
  self.FreeVHFFrequencies = FreeVHFFrequencies
  return self
end

--- (Internal) Pop frequency from prepopulated table.
-- @param #CSAR self
-- @return #number frequency
function CSAR:_GenerateADFFrequency()
  self:T(self.lid .. " _GenerateADFFrequency")
  -- get a free freq for a beacon
  if #self.FreeVHFFrequencies <= 3 then
      self.FreeVHFFrequencies = self.UsedVHFFrequencies
      self.UsedVHFFrequencies = {}
  end
  local _vhf = table.remove(self.FreeVHFFrequencies, math.random(#self.FreeVHFFrequencies))
  return _vhf
end

--- (Internal) Function to determine clockwise direction for flares.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _heli The Helicopter
-- @param Wrapper.Group#GROUP _group The downed Group
-- @return #number direction
function CSAR:_GetClockDirection(_heli, _group)
  self:T(self.lid .. " _GetClockDirection")
 
  local _playerPosition = _heli:GetCoordinate() -- get position of helicopter
  local _targetpostions = _group:GetCoordinate() -- get position of downed pilot
  local _heading = _heli:GetHeading() -- heading
  local DirectionVec3 = _playerPosition:GetDirectionVec3( _targetpostions )
  local Angle = _playerPosition:GetAngleDegrees( DirectionVec3 )
  self:T(self.lid .. " _GetClockDirection"..tostring(Angle).." "..tostring(_heading))
  local hours = 0
  local clock = 12
  if _heading and Angle then
    clock = 12
    --if angle == 0 then angle = 360 end
    clock = _heading-Angle  
    hours = (clock/30)*-1
    clock = 12+hours
    clock = UTILS.Round(clock,0)
    if clock > 12 then clock = clock-12 end
  end  
  return clock
end

--- (Internal) Function to add beacon to downed pilot.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP _group Group #GROUP object.
-- @param #number _freq Frequency to use
function CSAR:_AddBeaconToGroup(_group, _freq)
    self:T(self.lid .. " _AddBeaconToGroup")
    local _group = _group   
    if _group == nil then
        --return frequency to pool of available
        for _i, _current in ipairs(self.UsedVHFFrequencies) do
            if _current == _freq then
                table.insert(self.FreeVHFFrequencies, _freq)
                table.remove(self.UsedVHFFrequencies, _i)
            end
        end
        return
    end
    
    if _group:IsAlive() then
      local _radioUnit = _group:GetUnit(1)
      if _radioUnit then    
     local name = _radioUnit:GetName()
        local Frequency = _freq -- Freq in Hertz
        local name = _radioUnit:GetName()
        local Sound =  "l10n/DEFAULT/"..self.radioSound
        local vec3 = _radioUnit:GetVec3() or _radioUnit:GetPositionVec3() or {x=0,y=0,z=0}
        trigger.action.radioTransmission(Sound, vec3, 0, false, Frequency, self.ADFRadioPwr or 1000,name..math.random(1,10000)) -- Beacon in MP only runs for exactly 30secs straight
      end
    end
    return self
end

--- (Internal) Helper function to (re-)add beacon to downed pilot.
-- @param #CSAR self
-- @param #table _args Arguments
function CSAR:_RefreshRadioBeacons()
    self:T(self.lid .. " _RefreshRadioBeacons")
    if self:_CountActiveDownedPilots() > 0 then
      local PilotTable = self.downedPilots
      for _,_pilot in pairs (PilotTable) do
        self:T({_pilot})
        local pilot = _pilot -- #CSAR.DownedPilot
        local group = pilot.group
        local frequency = pilot.frequency or 0 -- thanks to @Thrud
        if group and group:IsAlive() and frequency > 0 then
          self:_AddBeaconToGroup(group,frequency)
        end
      end
    end
    return self
end

--- (Internal) Helper function to count active downed pilots.
-- @param #CSAR self
-- @return #number Number of pilots in the field.
function CSAR:_CountActiveDownedPilots()
  self:T(self.lid .. " _CountActiveDownedPilots")
  local PilotsInFieldN = 0
  for _, _unitName in pairs(self.downedPilots) do
    self:T({_unitName.desc})
    if _unitName.alive == true then
      PilotsInFieldN = PilotsInFieldN + 1
    end
  end
  return PilotsInFieldN
end

--- (Internal) Helper to decide if we're over max limit.
-- @param #CSAR self
-- @return #boolean True or false.
function CSAR:_ReachedPilotLimit()
   self:T(self.lid .. " _ReachedPilotLimit")
   local limit = self.maxdownedpilots
   local islimited = self.limitmaxdownedpilots
   local count = self:_CountActiveDownedPilots()
   if islimited and (count >= limit) then
      return true
   else
      return false
   end
end

  ------------------------------
  --- FSM internal Functions ---
  ------------------------------

--- (Internal) Function called after Start() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
function CSAR:onafterStart(From, Event, To)
  self:T({From, Event, To})
  self:I(self.lid .. "Started ("..self.version..")")
  -- event handler
  self:HandleEvent(EVENTS.Takeoff, self._EventHandler)
  self:HandleEvent(EVENTS.Land, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.LandingAfterEjection, self._EventHandler) --shagrat
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  
  if self.allowbronco then
    local prefixes = self.csarPrefix or {}
    self.allheligroupset = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefixes):FilterStart()
  elseif self.useprefix then
    local prefixes = self.csarPrefix or {}
    self.allheligroupset = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefixes):FilterCategoryHelicopter():FilterStart()
  else
    self.allheligroupset = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterCategoryHelicopter():FilterStart()
  end
  self.mash = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(self.mashprefix):FilterStart() -- currently only GROUP objects, maybe support STATICs also?
  if self.wetfeettemplate then
    self.usewetfeet = true
  end
  if self.useSRS then
    local path = self.SRSPath
    local modulation = self.SRSModulation
    local channel = self.SRSchannel
    self.msrs = MSRS:New(path,channel,modulation)
    self.msrs:SetPort(self.SRSport)
    self.msrs:SetLabel("CSAR")
    self.msrs:SetCulture(self.SRSCulture)
    self.msrs:SetCoalition(self.coalition)
    self.msrs:SetVoice(self.SRSVoice)
    self.msrs:SetGender(self.SRSGender)
    if self.SRSGPathToCredentials then
      self.msrs:SetGoogle(self.SRSGPathToCredentials)
    end
    self.msrs:SetVolume(self.SRSVolume)
    self.msrs:SetLabel("CSAR")
    self.SRSQueue = MSRSQUEUE:New("CSAR")
  end
  
  self:__Status(-10)
  
  if self.enableLoadSave then
    local interval = self.saveinterval
    local filename = self.filename
    local filepath = self.filepath
    self:__Save(interval,filepath,filename)
  end
  
  return self
end

--- (Internal) Function called before Status() event.
-- @param #CSAR self
function CSAR:_CheckDownedPilotTable()
  local pilots = self.downedPilots
  local npilots = {}
  
  for _ind,_entry in pairs(pilots) do
    local _group = _entry.group
    if _group:IsAlive() then
      npilots[_ind] = _entry      
    else
      if _entry.alive then
        self:__KIA(1,_entry.desc)
      end
    end
  end
  self.downedPilots = npilots
  return self
end

--- (Internal) Function called before Status() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
function CSAR:onbeforeStatus(From, Event, To)
  self:T({From, Event, To})
  -- housekeeping
  self:_AddMedevacMenuItem()
  
  if not self.BeaconTimer or (self.BeaconTimer and not self.BeaconTimer:IsRunning()) then
    self.BeaconTimer = TIMER:New(self._RefreshRadioBeacons,self)
    self.BeaconTimer:Start(2,self.beaconRefresher)
  end
  
  self:_CheckDownedPilotTable()
  for _,_sar in pairs (self.csarUnits) do
    local PilotTable = self.downedPilots
    for _,_entry in pairs (PilotTable) do
      if _entry.alive then
        local entry = _entry -- #CSAR.DownedPilot
        local name = entry.name
        local timestamp = entry.timestamp or 0
        local now = timer.getAbsTime()
        if now - timestamp > 17 then -- only check if we\'re not in approach mode, which is iterations of 5 and 10.
            self:_CheckWoundedGroupStatus(_sar,name)
        end
      end
    end
  end
  return self
end

--- (Internal) Function called after Status() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
function CSAR:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  -- collect some stats
  local NumberOfSARPilots = 0
  for _, _unitName in pairs(self.csarUnits) do
    NumberOfSARPilots = NumberOfSARPilots + 1
  end

  local PilotsInFieldN = self:_CountActiveDownedPilots()
  
  local PilotsBoarded = 0
  for _, _unitName in pairs(self.inTransitGroups) do
    for _,_units in pairs(_unitName) do
      PilotsBoarded = PilotsBoarded + 1
    end
  end
  
  if self.verbose > 0 then
    local text = string.format("%s Active SAR: %d | Downed Pilots in field: %d (max %d) | Pilots boarded: %d | Landings: %d | Pilots rescued: %d",
      self.lid,NumberOfSARPilots,PilotsInFieldN,self.maxdownedpilots,PilotsBoarded,self.rescues,self.rescuedpilots)
    self:T(text)
    if self.verbose < 2 then
      self:I(text)
    elseif self.verbose > 1 then
      self:I(text)
      local m = MESSAGE:New(text,"10","Status",true):ToCoalition(self.coalition)
    end
  end
  self:__Status(-20)
  return self
end

--- (Internal) Function called after Stop() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
function CSAR:onafterStop(From, Event, To)
  self:T({From, Event, To})
  -- event handler
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.Ejection)
  self:UnHandleEvent(EVENTS.LandingAfterEjection) -- shagrat
  self:UnHandleEvent(EVENTS.PlayerEnterUnit)
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  self:UnHandleEvent(EVENTS.PilotDead)
  self:T(self.lid .. "Stopped.")
  return self
end

--- (Internal) Function called before Approach() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param #string Heliname Name of the helicopter group.
-- @param #string Woundedgroupname Name of the downed pilot\'s group.
function CSAR:onbeforeApproach(From, Event, To, Heliname, Woundedgroupname)
  self:T({From, Event, To, Heliname, Woundedgroupname})
  self:_CheckWoundedGroupStatus(Heliname,Woundedgroupname)
  return self
end

--- (Internal) Function called before Boarded() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param #string Heliname Name of the helicopter group.
-- @param #string Woundedgroupname Name of the downed pilot\'s group.
function CSAR:onbeforeBoarded(From, Event, To, Heliname, Woundedgroupname)
  self:T({From, Event, To, Heliname, Woundedgroupname})
  self:_ScheduledSARFlight(Heliname,Woundedgroupname)
  local Unit = UNIT:FindByName(Heliname)
  if Unit and Unit:IsPlayer() and self.PlayerTaskQueue then
    local playername = Unit:GetPlayerName()
    local dropcoord = Unit:GetCoordinate() or COORDINATE:New(0,0,0)
    local dropvec2 = dropcoord:GetVec2()
    self.PlayerTaskQueue:ForEach(
      function (Task)
        local task = Task -- Ops.PlayerTask#PLAYERTASK
        local subtype = task:GetSubType()
        -- right subtype?
        if Event == subtype and not task:IsDone() then
          local targetzone = task.Target:GetObject() -- Core.Zone#ZONE should be a zone in this case ....
          if (targetzone and targetzone.ClassName and string.match(targetzone.ClassName,"ZONE") and targetzone:IsVec2InZone(dropvec2)) 
            or (string.find(task.CSARPilotName,Woundedgroupname)) then
            if task.Clients:HasUniqueID(playername) then
              -- success
              task:__Success(-1)
            end
          end
        end
      end
    )
  end
  return self
end

--- (Internal) Function called before Returning() event. 
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param #string Heliname Name of the helicopter group.
-- @param #string Woundedgroupname Name of the downed pilot\'s group.
-- @param #boolean IsAirport True if heli has landed on an AFB (from event land).
function CSAR:onbeforeReturning(From, Event, To, Heliname, Woundedgroupname, IsAirPort)
  self:T({From, Event, To, Heliname, Woundedgroupname})
  self:_ScheduledSARFlight(Heliname,Woundedgroupname, IsAirPort)
  return self
end

--- (Internal) Function called before Rescued() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT HeliUnit Unit of the helicopter.
-- @param #string HeliName Name of the helicopter group.
-- @param #number PilotsSaved Number of the saved pilots on board when landing.
function CSAR:onbeforeRescued(From, Event, To, HeliUnit, HeliName, PilotsSaved)
  self:T({From, Event, To, HeliName, HeliUnit})
  self.rescues = self.rescues + 1
  self.rescuedpilots = self.rescuedpilots + PilotsSaved
  local Unit = HeliUnit or UNIT:FindByName(HeliName)
  if Unit and Unit:IsPlayer() and self.PlayerTaskQueue then
    local playername = Unit:GetPlayerName()
    self.PlayerTaskQueue:ForEach(
      function (Task)
        local task = Task -- Ops.PlayerTask#PLAYERTASK
        local subtype = task:GetSubType()
        -- right subtype?
        if Event == subtype and not task:IsDone() then
            if task.Clients:HasUniqueID(playername) then
              -- success
              task:__Success(-1)
            end
        end
      end
    )
  end
  return self
end

--- (Internal) Function called before PilotDown() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group Group object of the downed pilot.
-- @param #number Frequency Beacon frequency in kHz.
-- @param #string Leadername Name of the #UNIT of the downed pilot.
-- @param #string CoordinatesText String of the position of the pilot. Format determined by self.coordtype.
function CSAR:onbeforePilotDown(From, Event, To, Group, Frequency, Leadername, CoordinatesText)
  self:T({From, Event, To, Group, Frequency, Leadername, CoordinatesText})
  return self
end

--- (Internal) Function called before Landed() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param #string HeliName Name of the #UNIT which has landed.
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase where the heli landed.
function CSAR:onbeforeLanded(From, Event, To, HeliName, Airbase)
  self:T({From, Event, To, HeliName, Airbase})
  return self
end

--- On before "Save" event. Checks if io and lfs are available.
-- @param #CSAR self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
-- @param #string filename (Optional) File name for saving. Default is "CSAR_<alias>_Persist.csv".
function CSAR:onbeforeSave(From, Event, To, path, filename)
  self:T({From, Event, To, path, filename})
  if not self.enableLoadSave then
    return self
  end
  -- Thanks to @FunkyFranky 
  -- Check io module is available.
  if not io then
    self:E(self.lid.."ERROR: io not desanitized. Can't save current state.")
    return false
  end

  -- Check default path.
  if path==nil and not lfs then
    self:E(self.lid.."WARNING: lfs not desanitized. State will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
  end

  return true
end

--- On after "Save" event. Player data is saved to file.
-- @param #CSAR self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is saved. If nil, file is saved in the DCS root installtion directory or your "Saved Games" folder if lfs was desanitized.
-- @param #string filename (Optional) File name for saving. Default is Default is "CSAR_<alias>_Persist.csv".
function CSAR:onafterSave(From, Event, To, path, filename)
  self:T({From, Event, To, path, filename})
  -- Thanks to @FunkyFranky 
  if not self.enableLoadSave then
    return self
  end
  --- Function that saves data to file
  local function _savefile(filename, data)
    local f = assert(io.open(filename, "wb"))
    f:write(data)
    f:close()
  end

  -- Set path or default.
  if lfs then
    path=self.filepath or lfs.writedir()
  end
  
  -- Set file name.
  filename=filename or self.filename

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end
  
  local pilots = self.downedPilots
  
  --local data = "LoadedData = {\n"
  local data = "playerName,x,y,z,coalition,country,description,typeName,unitName,freq\n"
  local n = 0
  for _,_grp in pairs(pilots) do
    local DownedPilot = _grp -- Wrapper.Group#GROUP
    if DownedPilot and DownedPilot.alive then
      -- get downed pilot data for saving
      local playerName = DownedPilot.player
      local group = DownedPilot.group
      local coalition = group:GetCoalition()
      local country = group:GetCountry()
      local description = DownedPilot.desc
      local typeName = DownedPilot.typename
      local freq = DownedPilot.frequency
      local location = group:GetVec3()
      local unitName = DownedPilot.originalUnit
      local txt = string.format("%s,%d,%d,%d,%s,%s,%s,%s,%s,%d\n",playerName,location.x,location.y,location.z,coalition,country,description,typeName,unitName,freq)
      
      self:I(self.lid.."Saving to CSAR File: " .. txt)
      
      data = data .. txt
    end
  end
  
  _savefile(filename, data)
   
  -- AutoSave
  if self.enableLoadSave then
    local interval = self.saveinterval
    local filename = self.filename
    local filepath = self.filepath
    self:__Save(interval,filepath,filename)
  end
  return self
end

--- On before "Load" event. Checks if io and lfs and the file are available.
-- @param #CSAR self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
-- @param #string filename (Optional) File name for loading. Default is "CSAR_<alias>_Persist.csv".
function CSAR:onbeforeLoad(From, Event, To, path, filename)
  self:T({From, Event, To, path, filename})
  if not self.enableLoadSave then
    return self
  end
  --- Function that check if a file exists.
  local function _fileexists(name)
     local f=io.open(name,"r")
     if f~=nil then
      io.close(f)
      return true
    else
      return false
    end
  end
  
  -- Set file name and path
  filename=filename or self.filename
  path = path or self.filepath
  
  -- Check io module is available.
  if not io then
    self:E(self.lid.."WARNING: io not desanitized. Cannot load file.")
    return false
  end

  -- Check default path.
  if path==nil and not lfs then
    self:E(self.lid.."WARNING: lfs not desanitized. State will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
  end

  -- Set path or default.
  if lfs then
    path=path or lfs.writedir()
  end

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end

  -- Check if file exists.
  local exists=_fileexists(filename)

  if exists then
    return true
  else
    self:E(self.lid..string.format("WARNING: State file %s might not exist.", filename))
    return false
    --return self
  end

end

--- On after "Load" event. Loads dropped units from file.
-- @param #CSAR self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
-- @param #string filename (Optional) File name for loading. Default is "CSAR_<alias>_Persist.csv".
function CSAR:onafterLoad(From, Event, To, path, filename)
  self:T({From, Event, To, path, filename})
  if not self.enableLoadSave then
    return self
  end
  --- Function that loads data from a file.
  local function _loadfile(filename)
    local f=assert(io.open(filename, "rb"))
    local data=f:read("*all")
    f:close()
    return data
  end
  
  -- Set file name and path
  filename=filename or self.filename
  path = path or self.filepath
  
  -- Set path or default.
  if lfs then
    path=path or lfs.writedir()
  end

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end

  -- Info message.
  local text=string.format("Loading CSAR state from file %s", filename)
  MESSAGE:New(text,10):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  local file=assert(io.open(filename, "rb"))
  
  local loadeddata = {}
  for line in file:lines() do
      loadeddata[#loadeddata+1] = line
  end
  file:close()
  
  -- remove header
  table.remove(loadeddata, 1)
  
  for _id,_entry in pairs (loadeddata) do
    local dataset = UTILS.Split(_entry,",")
    -- 1=playerName,2=x,3=y,4=z,5=coalition,6=country,7=description,8=typeName,9=unitName,10=freq\n
    local playerName = dataset[1]
    
    local vec3 = {}
    vec3.x = tonumber(dataset[2])
    vec3.y = tonumber(dataset[3])
    vec3.z = tonumber(dataset[4])
    local point = COORDINATE:NewFromVec3(vec3)
    
    local coalition = tonumber(dataset[5])
    local country = tonumber(dataset[6])
    local description = dataset[7]
    local typeName = dataset[8]
    local unitName = dataset[9]
    local freq = tonumber(dataset[10])
    
    self:_AddCsar(coalition, country, point, typeName, unitName, playerName, freq, nil, description, nil)    
  end
  
  return self
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- End Ops.CSAR
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
