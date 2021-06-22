--- **Ops** -- Combat Search and Rescue.
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
-- ### Author: **Applevangelist** (Moose Version), ***Ciribob*** (original)
-- @module Ops.CSAR
-- @image OPS_CSAR.jpg

-- Date: June 2021

-------------------------------------------------------------------------
--- **CSAR** class, extends #Core.Base#BASE, #Core.Fsm#FSM
-- @type CSAR
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
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
--        my_csar.invisiblevrew = false -- downed pilot spawn is visible
--        -- start the FSM
--        my_csar:__Start(5)
-- 
-- ## 2. Options
-- 
-- The following options are available (with their defaults). Only set the ones you want changed:
--
--         self.allowDownedPilotCAcontrol = false -- Set to false if you don\'t want to allow control by Combined Arms.
--         self.allowFARPRescue = true -- allows pilots to be rescued by landing at a FARP or Airbase. Else MASH only!
--         self.autosmoke = false -- automatically smoke a downed pilot\'s location when a heli is near.
--         self.coordtype = 1 -- Use Lat/Long DDM (0), Lat/Long DMS (1), MGRS (2), Bullseye imperial (3) or Bullseye metric (4) for coordinates.
--         self.csarOncrash = false -- (WIP) If set to true, will generate a downed pilot when a plane crashes as well.
--         self.enableForAI = false -- set to false to disable AI pilots from being rescued.
--         self.pilotRuntoExtractPoint = true -- Downed pilot will run to the rescue helicopter up to self.extractDistance in meters. 
--         self.extractDistance = 500 -- Distance the downed pilot will start to run to the rescue helicopter.
--         self.immortalcrew = true -- Set to true to make wounded crew immortal.
--         self.invisiblecrew = false -- Set to true to make wounded crew insvisible.
--         self.loadDistance = 75 -- configure distance for pilots to get into helicopter in meters.
--         self.mashprefix = {"MASH"} -- prefixes of #GROUP objects used as MASHes.
--         self.max_units = 6 -- max number of pilots that can be carried if #CSAR.AircraftType is undefined.
--         self.messageTime = 15 -- Time to show messages for in seconds. Doubled for long messages.
--         self.radioSound = "beacon.ogg" -- the name of the sound file to use for the pilots\' radio beacons. 
--         self.smokecolor = 4 -- Color of smokemarker, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue.
--         self.useprefix = true  -- Requires CSAR helicopter #GROUP names to have the prefix(es) defined below.
--         self.csarPrefix = { "helicargo", "MEDEVAC"} -- #GROUP name prefixes used for useprefix=true - DO NOT use # in helicopter names in the Mission Editor! 
--         self.verbose = 0 -- set to > 1 for stats output for debugging.
-- 
-- ## 2.1 Experimental Features
-- 
--       "WARNING - Here\'ll be dragons!
--       DANGER - For this to work you need to de-sanitize your mission environment (all three entries) in <DCS root>\Scripts\MissionScripting.lua
--       Needs SRS => 1.9.6 to work (works on the *server* side of SRS)"
--       self.useSRS = false -- Set true to use FF\'s SRS integration
--       self.SRSPath = "E:\\Program Files\\DCS-SimpleRadio-Standalone\\" -- adjust your own path in your SRS installation -- server(!)
--       self.SRSchannel = 300 -- radio channel
--       self.SRSModulation = radio.modulation.AM -- modulation
-- 
-- ## 3. Results
-- 
-- Number of successful landings with save pilots and aggregated number of saved pilots is stored in these variables in the object:
--      
--        self.rescues -- number of successful landings *with* saved pilots
--        self.rescuedpilots -- aggregated number of pilots rescued from the field (of *all* players)
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
--          function my_csar:OnAfterBoarded(from, event, to, heliname, groupname)
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
--        my_csar:_SpawnCsarAtZone( "CSAR_Start_1", coalition.side.BLUE, "Pilot Wagner", true )
--
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
  max_units = 6, --number of pilots that can be carried
  hoverStatus = {}, -- tracks status of a helis hover above a downed pilot
  pilotDisabled = {}, -- tracks what aircraft a pilot is disabled for
  pilotLives = {}, -- tracks how many lives a pilot has
  useprefix    = true,  -- Use the Prefixed defined below, Requires Unit have the Prefix defined below 
  csarPrefix = {},
  template = nil,
  bluemash = {},
  smokecolor = 4,
  rescues = 0,
  rescuedpilots = 0,
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
-- @field #number timestamp Timestamp for approach process
  
--- Updated and sorted list of known NDB beacons (in kHz!) from the available maps.
-- @field #CSAR.SkipFrequencies
CSAR.SkipFrequencies = {
  214,274,291.5,295,297.5,
  300.5,304,307,309.5,311,312,312.5,316,
  320,324,328,329,330,336,337,
  342,343,348,351,352,353,358,
  363,365,368,372.5,374,
  380,381,384,389,395,396,
  414,420,430,432,435,440,450,455,462,470,485,
  507,515,520,525,528,540,550,560,570,577,580,602,625,641,662,670,680,682,690,
  705,720,722,730,735,740,745,750,770,795,
  822,830,862,866,
  905,907,920,935,942,950,995,
  1000,1025,1030,1050,1065,1116,1175,1182,1210
  }
 
--- All slot / Limit settings
-- @type CSAR.AircraftType
-- @field #string typename Unit type name.
CSAR.AircraftType = {} -- Type and limit
CSAR.AircraftType["SA342Mistral"] = 2
CSAR.AircraftType["SA342Minigun"] = 2
CSAR.AircraftType["SA342L"] = 4
CSAR.AircraftType["SA342M"] = 4
CSAR.AircraftType["UH-1H"] = 8
CSAR.AircraftType["Mi-8MT"] = 12 
CSAR.AircraftType["Mi-24P"] = 8 
CSAR.AircraftType["Mi-24V"] = 8

--- CSAR class version.
-- @field #string version
CSAR.version="0.1.3r4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: SRS Integration (to be tested)

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
        self.alias="Спасение"
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
  self:AddTransition("*",             "Boarded",            "*")          -- Pilot boarded.
  self:AddTransition("*",             "Returning",          "*")        -- CSAR able to return to base.
  self:AddTransition("*",             "Rescued",            "*")          -- Pilot at MASH.
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
  self.allowFARPRescue = true --allows pilot to be rescued by landing at a FARP or Airbase
  self.max_units = 6 --max number of pilots that can be carried
  self.useprefix = true  -- Use the Prefixed defined below, Requires Unit have the Prefix defined below 
  self.csarPrefix = { "helicargo", "MEDEVAC"} -- prefixes used for useprefix=true - DON\'T use # in names!
  self.template = Template or "generic" -- template for downed pilot
  self.mashprefix = {"MASH"} -- prefixes used to find MASHes
  self.bluemash = SET_GROUP:New():FilterCoalitions(self.coalition):FilterPrefixes(self.mashprefix):FilterOnce() -- currently only GROUP objects, maybe support STATICs also?
  self.autosmoke = false -- automatically smoke location when heli is near
  
  -- WARNING - here\'ll be dragons
  -- for this to work you need to de-sanitize your mission environment in <DCS root>\Scripts\MissionScripting.lua
  -- needs SRS => 1.9.6 to work (works on the *server* side)
  self.useSRS = false -- Use FF\'s SRS integration
  self.SRSPath = "E:\\Program Files\\DCS-SimpleRadio-Standalone\\" -- adjust your own path in your server(!)
  self.SRSchannel = 300 -- radio channel
  self.SRSModulation = radio.modulation.AM -- modulation
  
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
  
    --- On After "Boarded" event. Downed pilot boarded heli.
  -- @function [parent=#CSAR] OnAfterBoarded
  -- @param #CSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Heliname Name of the helicopter group.
  -- @param #string Woundedgroupname Name of the downed pilot\'s group.

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
  
  return self
end

------------------------
--- Helper Functions ---
------------------------

--- Function to insert downed pilot tracker object.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP Group The #GROUP object
-- @param #string Groupname Name of the spawned group.
-- @param #number Side Coalition.
-- @param #string OriginalUnit Name of original Unit.
-- @param #string Description Descriptive text.
-- @param #string Typename Typename of unit.
-- @param #number Frequency Frequency of the NDB in Hz
-- @param #string Playername Name of Player (if applicable)
-- @return #CSAR self.
function CSAR:_CreateDownedPilotTrack(Group,Groupname,Side,OriginalUnit,Description,Typename,Frequency,Playername)
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
  
  -- Add Pilot
  local PilotTable = self.downedPilots
  local counter = self.downedpilotcounter
  PilotTable[counter] = {}
  PilotTable[counter] = DownedPilot
  self:T({Table=PilotTable})
  self.downedPilots = PilotTable
  -- Increase counter
  self.downedpilotcounter = self.downedpilotcounter+1
end

--- Count pilots on board.
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

--- Function to check for dupe eject events.
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

--- Spawn a downed pilot
-- @param #CSAR self
-- @param #number country Country for template.
-- @param Core.Point#COORDINATE point Coordinate to spawn at.
-- @return Wrapper.Group#GROUP group The #GROUP object.
-- @return #string alias The alias name.
function CSAR:_SpawnPilotInField(country,point)
  self:T({country,point})
  for i=1,10 do
    math.random(i,10000)
  end
  local template = self.template
  local alias = string.format("Downed Pilot-%d",math.random(1,10000))
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

--- Add options to a downed pilot
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

end

--- Function to spawn a CSAR object into the scene.
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
function CSAR:_AddCsar(_coalition , _country, _point, _typeName, _unitName, _playerName, _freq, noMessage, _description )
  self:T(self.lid .. " _AddCsar")
  self:T({_coalition , _country, _point, _typeName, _unitName, _playerName, _freq, noMessage, _description})

  local template = self.template

  local _spawnedGroup, _alias = self:_SpawnPilotInField(_country,_point)
  local _typeName = _typeName or "PoW"
  if not noMessage then
    local m = MESSAGE:New("MAYDAY MAYDAY! " .. _typeName .. " is down. ",10,"INFO"):ToCoalition(self.coalition)
  end
  
  if not _freq then
    _freq = self:_GenerateADFFrequency()
    if not _freq then _freq = "333.25" end --noob catch
  end 
  
  if _freq then
    self:_AddBeaconToGroup(_spawnedGroup, _freq)
  end
  
  self:_AddSpecialOptions(_spawnedGroup)

  local _text = " "
  if _playerName ~= nil then
      _text = "Pilot " .. _playerName .. " of " .. _unitName .. " - " .. _typeName
  elseif _typeName ~= nil then
      _text = "AI Pilot of " .. _unitName .. " - " .. _typeName
  else
      _text = _description
  end
    
  self:T({_spawnedGroup, _alias})
  
  local _GroupName = _spawnedGroup:GetName() or _alias

  self:_CreateDownedPilotTrack(_spawnedGroup,_GroupName,_coalition,_unitName,_text,_typeName,_freq,_playerName)

  self:_InitSARForPilot(_spawnedGroup, _GroupName, _freq, noMessage)
  
end

--- Function to add a CSAR object into the scene at a zone coordinate. For mission designers wanting to add e.g. PoWs to the scene.
-- @param #CSAR self
-- @param #string _zone Name of the zone.
-- @param #number _coalition Coalition.
-- @param #string _description (optional) Description.
-- @param #boolean _randomPoint (optional) Random yes or no.
-- @param #boolean _nomessage (optional) If true, don\'t send a message to SAR.
function CSAR:_SpawnCsarAtZone( _zone, _coalition, _description, _randomPoint, _nomessage)
  self:T(self.lid .. " _SpawnCsarAtZone")
  local freq = self:_GenerateADFFrequency()
  local _triggerZone = ZONE:New(_zone) -- trigger to use as reference position
  if _triggerZone == nil then
    self:E(self.lid.."ERROR: Can\'t find zone called " .. _zone, 10)
    return
  end
  
  local _description = _description or "none"
  
  local pos = {}
  if _randomPoint then
    local _pos =  _triggerZone:GetRandomPointVec3()
    pos = COORDINATE:NewFromVec3(_pos)
  else
    pos  = _triggerZone:GetCoordinate()
  end
  
  local _country = 0
  if _coalition == coalition.side.BLUE then
    _country = country.id.USA
  elseif _coalition == coalition.side.RED then
    _country = country.id.RUSSIA
  else
    _country = country.id.UN_PEACEKEEPERS
  end
  
  self:_AddCsar(_coalition, _country, pos, "PoW", "Unknown", nil, freq, _nomessage, _description)
end

-- TODO: Split in functions per Event type
--- Event handler.
-- @param #CSAR self
function CSAR:_EventHandler(EventData)
  self:T(self.lid .. " _EventHandler")
  self:T({Event = EventData.id})
  
  local _event = EventData -- Core.Event#EVENTDATA
  
  -- no event  
  if _event == nil or _event.initiator == nil then
    return false
  
  -- take off
  elseif _event.id == EVENTS.Takeoff then -- taken off
    self:T(self.lid .. " Event unit - Takeoff")
      
    local _coalition = _event.IniCoalition
    if _coalition ~= self.coalition then
        return --ignore!
    end
      
    if _event.IniGroupName then
        self.takenOff[_event.IniUnitName] = true
    end
    
    return true
  
  -- player enter unit
  elseif _event.id == EVENTS.PlayerEnterAircraft or _event.id == EVENTS.PlayerEnterUnit then --player entered unit
    self:T(self.lid .. " Event unit - Player Enter")
    
    local _coalition = _event.IniCoalition
    if _coalition ~= self.coalition then
        return --ignore!
    end
    
    if _event.IniPlayerName then
        self.takenOff[_event.IniPlayerName] = nil
    end
    
    local _unit = _event.IniUnit
    local _group = _event.IniGroup
    if _unit:IsHelicopter() or _group:IsHelicopter() then
      self:_AddMedevacMenuItem()
    end 
    
    return true
  
  elseif (_event.id == EVENTS.PilotDead and self.csarOncrash == false) then
      -- Pilot dead
  
      self:T(self.lid .. " Event unit - Pilot Dead")
  
      local _unit = _event.IniUnit
      local _unitname = _event.IniUnitName
      local _group = _event.IniGroup
      
      if _unit == nil then
          return -- error!
      end
  
      local _coalition = _event.IniCoalition
      if _coalition ~= self.coalition then
          return --ignore!
      end
  
      -- Catch multiple events here?
      if self.takenOff[_event.IniUnitName] == true or _group:IsAirborne() then
          if self:_DoubleEjection(_unitname) then
            return
          end         
          local m = MESSAGE:New("MAYDAY MAYDAY! " .. _unit:GetTypeName() .. " shot down. No Chute!",10,"Info"):ToCoalition(self.coalition)
      else
          self:T(self.lid .. " Pilot has not taken off, ignore")
      end
  
      return
  
  elseif _event.id == EVENTS.PilotDead or _event.id == EVENTS.Ejection then
      if _event.id == EVENTS.PilotDead and self.csarOncrash == false then 
          return     
      end
      self:T(self.lid .. " Event unit - Pilot Ejected")
  
      local _unit = _event.IniUnit
      local _unitname = _event.IniUnitName
      local _group = _event.IniGroup
      
      if _unit == nil then
          return -- error!
      end
  
      local _coalition = _unit:GetCoalition() 
      if _coalition ~= self.coalition then
          return --ignore!
      end
   
      if self.enableForAI == false and _event.IniPlayerName == nil then
          return
      end

      if not self.takenOff[_event.IniUnitName] and not _group:IsAirborne() then
          self:T(self.lid .. " Pilot has not taken off, ignore")
          return -- give up, pilot hasnt taken off
      end
      
      if self:_DoubleEjection(_unitname) then
        return
      end
          
      local _freq = self:_GenerateADFFrequency()
       self:_AddCsar(_coalition, _unit:GetCountry(), _unit:GetCoordinate()  , _unit:GetTypeName(),  _unit:GetName(), _event.IniPlayerName, _freq, false, 0)
       
      return true
  
  elseif _event.id == EVENTS.Land then
      self:T(self.lid .. " Landing")
      
      if _event.IniUnitName then
          self.takenOff[_event.IniUnitName] = nil
      end
  
      if self.allowFARPRescue then
          
          local _unit = _event.IniUnit  -- Wrapper.Unit#UNIT
  
          if _unit == nil then
              self:T(self.lid .. " Unit nil on landing")
              return -- error!
          end
          
          local _coalition = _event.IniCoalition
          if _coalition ~= self.coalition then
              return --ignore!
          end
          
          self.takenOff[_event.IniUnitName] = nil
 
          local _place = _event.Place -- Wrapper.Airbase#AIRBASE
  
          if _place == nil then
              self:T(self.lid .. " Landing Place Nil")
              return -- error!
          end
   
          if _place:GetCoalition() == self.coalition or _place:GetCoalition() == coalition.side.NEUTRAL then
              self:_RescuePilots(_unit)  
          else
              self:T(string.format("Airfield %d, Unit %d", _place:GetCoalition(), _unit:GetCoalition()))
              end
          end
  
          return true
      end

end

--- Initialize the action for a pilot.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP _downedGroup The group to rescue.
-- @param #string _GroupName Name of the Group
-- @param #number _freq Beacon frequency.
-- @param #boolean _nomessage Send message true or false.
function CSAR:_InitSARForPilot(_downedGroup, _GroupName, _freq, _nomessage)
  self:T(self.lid .. " _InitSARForPilot")
  local _leader = _downedGroup:GetUnit(1)
  --local _groupName = _downedGroup:GetName()
  local _groupName = _GroupName
  local _freqk = _freq / 1000
  local _coordinatesText = self:_GetPositionOfWounded(_downedGroup)
  local _leadername = _leader:GetName()
  
  if not _nomessage then
    local _text = string.format("%s requests SAR at %s, beacon at %.2f KHz", _leadername, _coordinatesText, _freqk) 
    self:_DisplayToAllSAR(_text,self.coalition,self.messageTime)
  end
  
  for _,_heliName in pairs(self.csarUnits) do
    self:_CheckWoundedGroupStatus(_heliName, _groupName)
  end

   -- trigger FSM event
  self:__PilotDown(2,_downedGroup, _freqk, _leadername, _coordinatesText)
end

--- Check if a name is in downed pilot table
-- @param #CSAR self
-- @param #string name Name to search for.
-- @return #boolean Outcome.
-- @return #CSAR.DownedPilot Table if found else nil.
function CSAR:_CheckNameInDownedPilots(name)
  local PilotTable = self.downedPilots --#CSAR.DownedPilot
  local found = false
  local table = nil
  for _,_pilot in pairs(PilotTable) do
    if _pilot.name == name then
      found = true
      table = _pilot
      break
    end  
  end
  return found, table
end

--- Check if a name is in downed pilot table and remove it.
-- @param #CSAR self
-- @param #string name Name to search for.
-- @param #boolean force Force removal.
-- @return #boolean Outcome.
function CSAR:_RemoveNameFromDownedPilots(name,force)
  local PilotTable = self.downedPilots --#CSAR.DownedPilot
  local found = false
  for _,_pilot in pairs(PilotTable) do
    if _pilot.name == name then
    local group = _pilot.group -- Wrapper.Group#GROUP
    if group then
      if (not group:IsAlive()) or ( force == true) then -- don\'t delete groups which still exist
        found = true
        _pilot.desc = nil
        _pilot.frequency = nil
        _pilot.index = nil
        _pilot.name = nil
        _pilot.originalUnit = nil
        _pilot.player = nil
        _pilot.side = nil
        _pilot.typename = nil
        _pilot.group = nil
        _pilot.timestamp = nil
      end
    end
   end
  end
  return found
end

--- Check state of wounded group.
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
  if _woundedGroup ~= nil then 
    local _heliUnit = self:_GetSARHeli(_heliName) -- Wrapper.Unit#UNIT
    
    local _lookupKeyHeli = _heliName .. "_" .. _woundedGroupName --lookup key for message state tracking
            
    if _heliUnit == nil then
      self.heliVisibleMessage[_lookupKeyHeli] = nil
      self.heliCloseMessage[_lookupKeyHeli] = nil
      self.landedStatus[_lookupKeyHeli] = nil
      self:T("...helinunit nil!")
      return
    end

  --if self:_CheckGroupNotKIA(_woundedGroup, _woundedGroupName, _heliUnit, _heliName) then
    local _heliCoord = _heliUnit:GetCoordinate()
    local _leaderCoord = _woundedGroup:GetCoordinate()
    local _distance = self:_GetDistance(_heliCoord,_leaderCoord)
    if _distance < 3000 and _distance > 0 then
      if self:_CheckCloseWoundedGroup(_distance, _heliUnit, _heliName, _woundedGroup, _woundedGroupName) == true then
        -- we\'re close, reschedule
        _downedpilot.timestamp = timer.getAbsTime()
        self:__Approach(-5,heliname,woundedgroupname)
      end
    else
      self.heliVisibleMessage[_lookupKeyHeli] = nil
      --reschedule as units aren\'t dead yet , schedule for a bit slower though as we\'re far away
      _downedpilot.timestamp = timer.getAbsTime()
      self:__Approach(-10,heliname,woundedgroupname)
    end
  else
  self:T("...Downed Pilot KIA?!")
  self:_RemoveNameFromDownedPilots(_downedpilot.name)
  end
end

--- Function to pop a smoke at a wounded pilot\'s positions.
-- @param #CSAR self
-- @param #string _woundedGroupName Name of the group.
-- @param Wrapper.Group#GROUP _woundedLeader Object of the group.
function CSAR:_PopSmokeForGroup(_woundedGroupName, _woundedLeader)
  self:T(self.lid .. " _PopSmokeForGroup")
  -- have we popped smoke already in the last 5 mins
  local _lastSmoke = self.smokeMarkers[_woundedGroupName]
  if _lastSmoke == nil or timer.getTime() > _lastSmoke then
  
      local _smokecolor = self.smokecolor
      local _smokecoord = _woundedLeader:GetCoordinate()
      _smokecoord:Smoke(_smokecolor)
      self.smokeMarkers[_woundedGroupName] = timer.getTime() + 300 -- next smoke time
  end
end

--- Function to pickup the wounded pilot from the ground.
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
      self:_DisplayMessageToSAR(_heliUnit, string.format("%s, %s. We\'re already crammed with %d guys! Sorry!", _pilotName, _heliName, _unitsInHelicopter, _unitsInHelicopter), self.messageTime)
      return true
  end
  
  local found,downedgrouptable = self:_CheckNameInDownedPilots(_woundedGroupName)
  local grouptable = downedgrouptable --#CSAR.DownedPilot
  self.inTransitGroups[_heliName][_woundedGroupName] =
  {
      -- DONE: Fix with #CSAR.DownedPilot
      originalUnit = grouptable.originalUnit,
      woundedGroup = _woundedGroupName,
      side = self.coalition,
      desc = grouptable.desc,
      player = grouptable.player,
  }

  _woundedGroup:Destroy()
  self:_RemoveNameFromDownedPilots(_woundedGroupName,true)
  
  self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s I\'m in! Get to the MASH ASAP! ", _heliName, _pilotName), self.messageTime,true,true)
  
  self:__Boarded(5,_heliName,_woundedGroupName)
  
  return true
end

--- Move group to destination.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP _leader
-- @param Core.Point#COORDINATE _destination
function CSAR:_OrderGroupToMoveToPoint(_leader, _destination)
  self:T(self.lid .. " _OrderGroupToMoveToPoint")
  local group = _leader
  local coordinate = _destination:GetVec2()

  group:SetAIOn()
  group:RouteToVec2(coordinate,5)
end

--- Function to check if heli is close to group.
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
  
  if (self.autosmoke == true) and (_distance < 500) then
      self:_PopSmokeForGroup(_woundedGroupName, _woundedLeader)
  end
  
  if self.heliVisibleMessage[_lookupKeyHeli] == nil then
      if self.autosmoke == true then
        self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. I hear you! Damn, that thing is loud! Land or hover by the smoke.", _heliName, _pilotName), self.messageTime,true,true)
      else
        self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. I hear you! Damn, that thing is loud! Request a Flare or Smoke if you need", _heliName, _pilotName), self.messageTime,true,true)
      end
      --mark as shown for THIS heli and THIS group
      self.heliVisibleMessage[_lookupKeyHeli] = true
  end
  
  if (_distance < 500) then
  
      if self.heliCloseMessage[_lookupKeyHeli] == nil then
          if self.autosmoke == true then
            self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. You\'re close now! Land or hover at the smoke.", _heliName, _pilotName), self.messageTime,true,true)
          else
            self:_DisplayMessageToSAR(_heliUnit, string.format("%s: %s. You\'re close now! Land in a safe place, I will go there ", _heliName, _pilotName), self.messageTime,true,true)
          end
          --mark as shown for THIS heli and THIS group
          self.heliCloseMessage[_lookupKeyHeli] = true
      end
  
      -- have we landed close enough?
      if not _heliUnit:InAir() then
  
          -- if you land on them, doesnt matter if they were heading to someone else as you\'re closer, you win! :)
        if self.pilotRuntoExtractPoint == true then
            if (_distance < self.extractDistance) then
              local _time = self.landedStatus[_lookupKeyHeli]
              if _time == nil then
                  self.landedStatus[_lookupKeyHeli] = math.floor( (_distance - self.loadDistance) / 3.6 )   
                  _time = self.landedStatus[_lookupKeyHeli] 
                  self:_OrderGroupToMoveToPoint(_woundedGroup, _heliUnit:GetCoordinate())
                  self:_DisplayMessageToSAR(_heliUnit, "Wait till " .. _pilotName .. " gets in. \nETA " .. _time .. " more seconds.", self.messageTime, true)
              else
                  _time = self.landedStatus[_lookupKeyHeli] - 10
                  self.landedStatus[_lookupKeyHeli] = _time
              end
              if _time <= 0 or _distance < self.loadDistance then
                 self.landedStatus[_lookupKeyHeli] = nil
                 self:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
                 return false
              end
            end
        else
          if (_distance < self.loadDistance) then
              self:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
              return false
          end
        end
      else
  
          local _unitsInHelicopter = self:_PilotsOnboard(_heliName)
          local _maxUnits = self.AircraftType[_heliUnit:GetTypeName()]
          if _maxUnits == nil then
            _maxUnits = self.max_units
          end
          
          if _heliUnit:InAir() and _unitsInHelicopter + 1 <= _maxUnits then
  
              if _distance < 8.0 then
  
                  --check height!
                  local leaderheight = _woundedLeader:GetHeight()
                  if leaderheight < 0 then leaderheight = 0 end
                  local _height = _heliUnit:GetHeight() - leaderheight
  
                  if _height <= 20.0 then
  
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
                          self.hoverStatus[_lookupKeyHeli] = nil
                          self:_PickupUnit(_heliUnit, _pilotName, _woundedGroup, _woundedGroupName)
                          return false
                      end
                      _reset = false
                  else
                      self:_DisplayMessageToSAR(_heliUnit, "Too high to winch " .. _pilotName .. " \nReduce height and hover for 10 seconds!", self.messageTime, true,true)
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

--- Check if group not KIA.
-- @param #CSAR self
-- @param Wrapper.Group#GROUP _woundedGroup
-- @param #string _woundedGroupName
-- @param Wrapper.Unit#UNIT _heliUnit
-- @param #string _heliName
-- @return #boolean Outcome
function CSAR:_CheckGroupNotKIA(_woundedGroup, _woundedGroupName, _heliUnit, _heliName)
  self:T(self.lid .. " _CheckGroupNotKIA")
  -- check if unit has died or been picked up
  local inTransit = false
  if _woundedGroup and _heliUnit then
    for _currentHeli, _groups in pairs(self.inTransitGroups) do
      if _groups[_woundedGroupName] then
        inTransit = true
        self:_DisplayToAllSAR(string.format("%s has been picked up by %s", _woundedGroupName, _currentHeli), self.coalition, self.messageTime)
        break
      end -- end name check
    end -- end loop
    if not inTransit then
      -- KIA
      self:_DisplayToAllSAR(string.format("%s is KIA ", _woundedGroupName), self.coalition, self.messageTime)
    end
    --stops the message being displayed again
    self:_RemoveNameFromDownedPilots(_woundedGroupName)
  end
  --continue
  return inTransit
end

--- Monitor in-flight returning groups.
-- @param #CSAR self
-- @param #string heliname Heli name
-- @param #string groupname Group name
function CSAR:_ScheduledSARFlight(heliname,groupname)
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

        if _dist < 200 and _heliUnit:InAir() == false then
            self:_RescuePilots(_heliUnit)
            return
        end

        --queue up
        self:__Returning(-5,heliname,_woundedGroupName)
end

--- Mark pilot as rescued and remove from tables.
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
  
  -- DONE: count saved units?
  local PilotsSaved = self:_PilotsOnboard(_heliName)
  
  self.inTransitGroups[_heliName] = nil
  
  local _txt = string.format("%s: The %d pilot(s) have been taken to the\nmedical clinic. Good job!", _heliName, PilotsSaved)
  
  self:_DisplayMessageToSAR(_heliUnit, _txt, self.messageTime)
  -- trigger event
  self:__Rescued(-1,_heliUnit,_heliName, PilotsSaved)
end

--- Check and return Wrappe.Unit#UNIT based on the name if alive.
-- @param #CSAR self
-- @param #string _unitname Name of Unit
-- @return #UNIT or nil
function CSAR:_GetSARHeli(_unitName)
  self:T(self.lid .. " _GetSARHeli")
  local unit = UNIT:FindByName(_unitName)
  if unit and unit:IsAlive() then
    return unit
  else
    return nil
  end
end

--- Display message to single Unit.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _unit Unit #UNIT to display to.
-- @param #string _text Text of message.
-- @param #number _time Message show duration.
-- @param #boolean _clear (optional) Clear screen.
-- @param #boolean _speak (optional) Speak message via SRS.
function CSAR:_DisplayMessageToSAR(_unit, _text, _time, _clear, _speak)
  self:T(self.lid .. " _DisplayMessageToSAR")
  local group = _unit:GetGroup()
  local _clear = _clear or nil
  local _time = _time or self.messageTime
  local m = MESSAGE:New(_text,_time,"Info",_clear):ToGroup(group)
  -- integrate SRS
  if _speak and self.useSRS then
    local srstext = SOUNDTEXT:New(_text)
    local path = self.SRSPath
    local modulation = self.SRSModulation
    local channel = self.SRSchannel
    local msrs = MSRS:New(path,channel,modulation)
    msrs:PlaySoundText(srstext, 2)
  end
end

--- Function to get string of a group\'s position.
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
    elseif self.coordtype == 3 then -- Bullseye Imperial
    local Settings = _SETTINGS:SetImperial()
      _coordinatesText = _coordinate:ToStringBULLS(self.coalition,Settings)
    else -- Bullseye Metric --(medevac.coordtype == 4)
    local Settings = _SETTINGS:SetMetric()
      _coordinatesText = _coordinate:ToStringBULLS(self.coalition,Settings)
    end
  end
  return _coordinatesText
end

--- Display active SAR tasks to player.
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
    --local _woundedGroup = GROUP:FindByName(_groupName)
    local _woundedGroup = _value.group
    if _woundedGroup then  
        local _coordinatesText = self:_GetPositionOfWounded(_woundedGroup) 
        local _helicoord =  _heli:GetCoordinate()
        local _woundcoord = _woundedGroup:GetCoordinate()
        local _distance = self:_GetDistance(_helicoord, _woundcoord)
        self:T({_distance = _distance})
        -- change distance to miles if self.coordtype < 4
        local distancetext = ""
        if self.coordtype < 4 then
          distancetext = string.format("%.3fnm",UTILS.MetersToNM(_distance))
        else
          distancetext = string.format("%.3fkm", _distance/1000.0)
        end
        table.insert(_csarList, { dist = _distance, msg = string.format("%s at %s - %.2f KHz ADF - %s ", _value.desc, _coordinatesText, _value.frequency / 1000, distancetext) })
    end
  end
  
  local function sortDistance(a, b)
      return a.dist < b.dist
  end
  
  table.sort(_csarList, sortDistance)
  
  for _, _line in pairs(_csarList) do
      _msg = _msg .. "\n" .. _line.msg
  end
  
  self:_DisplayMessageToSAR(_heli, _msg, self.messageTime*2)
end

--- Find the closest downed pilot to a heli.
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
  local _heliCoord = _heli:GetCoordinate()
  
  local DownedPilotsTable = self.downedPilots
  for _, _groupInfo in pairs(DownedPilotsTable) do
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

--- Fire a flare at the point of a downed pilot.
-- @param #CSAR self
-- @param #string _unitName Name of the unit.
function CSAR:_SignalFlare(_unitName)
  self:T(self.lid .. " _SignalFlare")
  local _heli = self:_GetSARHeli(_unitName)
  if _heli == nil then
      return
  end
  
  local _closest = self:_GetClosestDownedPilot(_heli)
  
  if _closest ~= nil and _closest.pilot ~= nil and _closest.distance < 8000.0 then
  
      local _clockDir = self:_GetClockDirection(_heli, _closest.pilot)
      local _distance = 0
      if self.coordtype < 4 then
        _distance = string.format("%.3fnm",UTILS.MetersToNM(_closest.distance))
      else
        _distance = string.format("%.3fkm",_closest.distance)
      end 
      local _msg = string.format("%s - Popping signal flare at your %s o\'clock. Distance %s", _unitName, _clockDir, _distance)
      self:_DisplayMessageToSAR(_heli, _msg, self.messageTime, false, true)
      
      local _coord = _closest.pilot:GetCoordinate()
      _coord:FlareRed(_clockDir)
  else
      local disttext = "4.3nm"
      if self.coordtype == 4 then
          disttext = "8km"
      end
      self:_DisplayMessageToSAR(_heli, string.format("No Pilots within %s",disttext), self.messageTime)
  end
end

--- Display info to all SAR groups.
-- @param #CSAR self
-- @param #string _message Message to display.
-- @param #number _side Coalition of message.
-- @param #number _messagetime How long to show.
function CSAR:_DisplayToAllSAR(_message, _side, _messagetime)
  self:T(self.lid .. " _DisplayToAllSAR")
  for _, _unitName in pairs(self.csarUnits) do
    local _unit = self:_GetSARHeli(_unitName)
    if _unit then
      if not _messagetime then
          self:_DisplayMessageToSAR(_unit, _message, _messagetime)
      end
    end
  end
end

---Request smoke at closest downed pilot.
--@param #CSAR self
--@param #string _unitName Name of the helicopter
function CSAR:_Reqsmoke( _unitName )
  self:T(self.lid .. " _Reqsmoke")
  local _heli = self:_GetSARHeli(_unitName)
  if _heli == nil then
      return
  end
  local _closest = self:_GetClosestDownedPilot(_heli)
  if _closest ~= nil and _closest.pilot ~= nil and _closest.distance < 8000.0 then
      local _clockDir = self:_GetClockDirection(_heli, _closest.pilot)
      local _distance = 0
      if self.coordtype < 4 then
        _distance = string.format("%.3fnm",UTILS.MetersToNM(_closest.distance))
      else
        _distance = string.format("%.3fkm",_closest.distance)
      end 
      local _msg = string.format("%s - Popping signal smoke at your %s o\'clock. Distance %s", _unitName, _clockDir, _distance)
      self:_DisplayMessageToSAR(_heli, _msg, self.messageTime, false, true)
      local _coord = _closest.pilot:GetCoordinate()
      local color = self.smokecolor
      _coord:Smoke(color)
  else
      local disttext = "4.3nm"
      if self.coordtype == 4 then
          disttext = "8km"
      end
      self:_DisplayMessageToSAR(_heli, string.format("No Pilots within %s",disttext), self.messageTime)
  end
end

--- Determine distance to closest MASH.
-- @param #CSAR self
-- @param Wrapper.Unit#UNIT _heli Helicopter #UNIT
-- @retunr
function CSAR:_GetClosestMASH(_heli)
  self:T(self.lid .. " _GetClosestMASH")
  local _mashset = self.bluemash -- Core.Set#SET_GROUP
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
    local afb,distance = position:GetClosestAirbase2(nil,self.coalition)
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

--- Display onboarded rescued pilots.
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
        self:_DisplayMessageToSAR(_unit, "No Rescued Pilots onboard", self.messageTime)
    else
        local _text = "Onboard - RTB to FARP/Airfield or MASH: "
        for _, _onboard in pairs(self.inTransitGroups[_unitName]) do
            _text = _text .. "\n" .. _onboard.desc
        end
        self:_DisplayMessageToSAR(_unit, _text, self.messageTime*2)
    end
end

--- Populate F10 menu for CSAR players.
-- @param #CSAR self
function CSAR:_AddMedevacMenuItem()
  self:T(self.lid .. " _AddMedevacMenuItem")
  
  local coalition = self.coalition
  local allheligroupset = self.allheligroupset
  local _allHeliGroups = allheligroupset:GetSetObjects()

  -- rebuild units table
  local _UnitList = {}
  for _key, _group in pairs (_allHeliGroups) do  
    local _unit = _group:GetUnit(1) -- Asume that there is only one unit in the flight for players
    if _unit then 
      if _unit:IsAlive() then         
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
          local _rootPath = MENU_GROUP:New(_group,"CSAR")
          local _rootMenu1 = MENU_GROUP_COMMAND:New(_group,"List Active CSAR",_rootPath, self._DisplayActiveSAR,self,_unitName)
          local _rootMenu2 = MENU_GROUP_COMMAND:New(_group,"Check Onboard",_rootPath, self._CheckOnboard,self,_unitName)
          local _rootMenu3 = MENU_GROUP_COMMAND:New(_group,"Request Signal Flare",_rootPath, self._SignalFlare,self,_unitName)
          local _rootMenu4 = MENU_GROUP_COMMAND:New(_group,"Request Smoke",_rootPath, self._Reqsmoke,self,_unitName):Refresh()
        end
      end
    end
  end  
  return
end

--- Return distance in meters between two coordinates.
-- @param #CSAR self
-- @param Core.Point#COORDINATE _point1 Coordinate one
-- @param Core.Point#COORDINATE _point2 Coordinate two
-- @return #number Distance in meters
function CSAR:_GetDistance(_point1, _point2)
  self:T(self.lid .. " _GetDistance")
  if _point1 and _point2 then
    local distance = _point1:DistanceFromPointVec2(_point2)
   return distance
  else
    return -1
  end
end

--- Populate table with available beacon frequencies.
-- @param #CSAR self
function CSAR:_GenerateVHFrequencies()
  self:T(self.lid .. " _GenerateVHFrequencies")
  local _skipFrequencies = self.SkipFrequencies
      
  local FreeVHFFrequencies = {}
  local UsedVHFFrequencies = {}
  
    -- first range
  local _start = 200000
  while _start < 400000 do
  
      -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end

      if _found == false then
          table.insert(FreeVHFFrequencies, _start)
      end
  
      _start = _start + 10000
  end
 
   -- second range
  _start = 400000
  while _start < 850000 do
  
      -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
  
      if _found == false then
          table.insert(FreeVHFFrequencies, _start)
      end
  
      _start = _start + 10000
  end
  
  -- third range
  _start = 850000
  while _start <= 999000 do -- updated for Gazelle
  
      -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
  
      if _found == false then
          table.insert(FreeVHFFrequencies, _start)
      end
  
      _start = _start + 50000
  end
  self.FreeVHFFrequencies = FreeVHFFrequencies
end

--- Pop frequency from prepopulated table.
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

--- Function to determine clockwise direction for flares.
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
  local clock = 12   
  if _heading then
    local Aspect = Angle - _heading
    if Aspect == 0 then Aspect = 360 end
    clock = math.floor(Aspect / 30)
    if clock == 0 then clock = 12 end
  end    
  return clock
end

--- Function to add beacon to downed pilot.
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
      local Frequency = _freq -- Freq in Hertz
      local Sound =  "l10n/DEFAULT/"..self.radioSound
      trigger.action.radioTransmission(Sound, _radioUnit:GetPositionVec3(), 0, false, Frequency, 1000) -- Beacon in MP only runs for exactly 30secs straight
    end
end

--- Helper function to (re-)add beacon to downed pilot.
-- @param #CSAR self
-- @param #table _args Arguments
function CSAR:_RefreshRadioBeacons()
    self:T(self.lid .. " _RefreshRadioBeacons")
    local PilotTable = self.downedPilots
    for _,_pilot in pairs (PilotTable) do
      local pilot = _pilot -- #CSAR.DownedPilot
      local group = pilot.group
      local frequency = pilot.frequency
      if frequency and frequency > 0 then
        self:_AddBeaconToGroup(group,frequency)
      end
    end
end

  ------------------------------
  --- FSM internal Functions ---
  ------------------------------

--- Function called after Start() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
function CSAR:onafterStart(From, Event, To)
  self:T({From, Event, To})
  self:I(self.lid .. "Started.")
  -- event handler
  self:HandleEvent(EVENTS.Takeoff, self._EventHandler)
  self:HandleEvent(EVENTS.Land, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  self:_GenerateVHFrequencies()
  if self.useprefix then
    local prefixes = self.csarPrefix or {}
    self.allheligroupset = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefixes):FilterCategoryHelicopter():FilterStart()
  else
    self.allheligroupset = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterCategoryHelicopter():FilterStart()
  end
  self:__Status(-10)
  return self
end

--- Function called before Status() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
function CSAR:onbeforeStatus(From, Event, To)
  self:T({From, Event, To})
  -- housekeeping
  self:_AddMedevacMenuItem()
  self:_RefreshRadioBeacons()
  for _,_sar in pairs (self.csarUnits) do
    local PilotTable = self.downedPilots
    for _,_entry in pairs (PilotTable) do
      local entry = _entry -- #CSAR.DownedPilot
      local name = entry.name
      local timestamp = entry.timestamp or 0
      local now = timer.getAbsTime()
      if now - timestamp > 17 then -- only check if we\'re not in approach mode, which is iterations of 5 and 10.
          self:_CheckWoundedGroupStatus(_sar,name)
      end
    end
  end
  return self
end

--- Function called after Status() event.
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

  local PilotsInFieldN = 0
  for _, _unitName in pairs(self.downedPilots) do
    self:T({_unitName})
    if _unitName.name ~= nil then
      PilotsInFieldN = PilotsInFieldN + 1
    end
  end
  
  local PilotsBoarded = 0
  for _, _unitName in pairs(self.inTransitGroups) do
    for _,_units in pairs(_unitName) do
      PilotsBoarded = PilotsBoarded + 1
    end
  end
  
  if self.verbose > 0 then
    local text = string.format("%s Active SAR: %d | Downed Pilots in field: %d | Pilots boarded: %d | Landings: %d | Pilots rescued: %d",
      self.lid,NumberOfSARPilots,PilotsInFieldN,PilotsBoarded,self.rescues,self.rescuedpilots)
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

--- Function called after Stop() event.
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
  self:UnHandleEvent(EVENTS.PlayerEnterUnit)
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  self:UnHandleEvent(EVENTS.PilotDead)
  self:T(self.lid .. "Stopped.")
  return self
end

--- Function called before Approach() event.
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

--- Function called before Boarded() event.
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param #string Heliname Name of the helicopter group.
-- @param #string Woundedgroupname Name of the downed pilot\'s group.
function CSAR:onbeforeBoarded(From, Event, To, Heliname, Woundedgroupname)
  self:T({From, Event, To, Heliname, Woundedgroupname})
  self:_ScheduledSARFlight(Heliname,Woundedgroupname)
  return self
end

--- Function called before Returning() event. 
-- @param #CSAR self.
-- @param #string From From state.
-- @param #string Event Event triggered.
-- @param #string To To state.
-- @param #string Heliname Name of the helicopter group.
-- @param #string Woundedgroupname Name of the downed pilot\'s group.
function CSAR:onbeforeReturning(From, Event, To, Heliname, Woundedgroupname)
  self:T({From, Event, To, Heliname, Woundedgroupname})
  self:_ScheduledSARFlight(Heliname,Woundedgroupname)
  return self
end

--- Function called before Rescued() event.
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
  return self
end

--- Function called before PilotDown() event.
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
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- End Ops.CSAR
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
