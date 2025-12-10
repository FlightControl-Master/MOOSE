--- **Functional** - AI CSAR system.
-- 
-- ===
--
-- ## Features:
--
--    * Send out helicopters to downed pilots
--    * Rescues players and AI alike
--    * Coalition specific
--    * Starting from a FARP or Airbase
--    * Dedicated MASH zone
--    * Some FSM functions to include in your mission scripts
--    * Limit number of available helos
--    * SRS voice output via TTS or soundfiles
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Functional/AICSAR).
--
-- ===
-- 
-- ### Author: **Applevangelist**
-- Last Update July 2025
--
-- ===
-- @module Functional.AICSAR
-- @image MOOSE.JPG



--- AI CSAR class.
-- @type AICSAR
-- @field #string ClassName Name of this class.
-- @field #string version Versioning.
-- @field #string lid LID for log entries.
-- @field #number coalition Colition side.
-- @field #string template Template for pilot.
-- @field #string helotemplate Template for CSAR helo.
-- @field #string alias Alias Name.
-- @field Wrapper.Airbase#AIRBASE farp FARP object from where to start.
-- @field Core.Zone#ZONE farpzone MASH zone to drop rescued pilots.
-- @field #number maxdistance Max distance to go for a rescue.
-- @field #table pilotqueue Queue of pilots to rescue.
-- @field #number pilotindex Table index to bind pilot to helo.
-- @field #table helos Table of Ops.FlightGroup#FLIGHTGROUP objects
-- @field #boolean verbose Switch more output.
-- @field #number rescuezoneradius Radius around downed pilot for the helo to land in.
-- @field #table rescued Track number of rescued pilot.
-- @field #boolean autoonoff Only send a helo when no human heli pilots are available.
-- @field Core.Set#SET_CLIENT playerset Track if alive heli pilots are available.
-- @field #boolean limithelos limit available number of helos going on mission (defaults to true)
-- @field #number helonumber number of helos available (default: 3)
-- @field Utilities.FiFo#FIFO PilotStore
-- @field #number Altitude Default altitude setting for the helicopter FLIGHTGROUP 1500ft.
-- @field #number Speed Default speed setting for the helicopter FLIGHTGROUP is 100kn.
-- @field #boolean UseEventEject In case Event LandingAfterEjection isn't working, use set this to true.
-- @field #number Delay In case of UseEventEject wait this long until we spawn a landed pilot.
-- @field #boolean UseRescueZone If true, use a rescue zone and not the max distance to FARP/MASH
-- @field Core.Zone#ZONE_RADIUS RescueZone Use this zone as operational area for the AICSAR instance.
-- @extends Core.Fsm#FSM


--- *I once donated a pint of my finest red corpuscles to the great American Red Cross and the doctor opined my blood was very helpful; contained so much alcohol they could use it to sterilize their instruments.*    
--  W.C.Fields
--
-- ===
--
-- # AICSAR Concept
-- 
-- For an AI or human pilot landing with a parachute, a rescue mission will be spawned. The helicopter will fly to the pilot, pick him or her up,
-- and fly back to a designated MASH (medical) zone, drop the pilot and then return to base.
-- Operational maxdistance can be set as well as the landing radius around the downed pilot.
-- Keep in mind that AI helicopters cannot hover-load at the time of writing, so rescue operations over water or in the mountains might not
-- work.
-- Optionally, if you have a CSAR operation with human pilots in your mission, you can set AICSAR to ignore missions when human helicopter
-- pilots are around.
--
-- ## Setup
-- 
-- Setup is a one-liner:
--            
--            -- @param #string Alias Name of this instance.
--            -- @param #number Coalition Coalition as in coalition.side.BLUE, can also be passed as "blue", "red" or "neutral"
--            -- @param #string Pilottemplate Pilot template name.
--            -- @param #string Helotemplate Helicopter template name. Set the template to "cold start". Hueys work best.
--            -- @param Wrapper.Airbase#AIRBASE FARP FARP object or Airbase from where to start.
--            -- @param Core.Zone#ZONE MASHZone Zone where to drop pilots after rescue.
--            local my_aicsar=AICSAR:New("Luftrettung",coalition.side.BLUE,"Downed Pilot","Rescue Helo",AIRBASE:FindByName("Test FARP"),ZONE:New("MASH"))
--
-- ## Options are
--  
--            my_aicsar.maxdistance -- maximum operational distance in meters. Defaults to 50NM or 92.6km
--            my_aicsar.rescuezoneradius -- landing zone around downed pilot. Defaults to 200m
--            my_aicsar.autoonoff -- stop operations when human helicopter pilots are around. Defaults to true.
--            my_aicsar.verbose -- text messages to own coalition about ongoing operations. Defaults to true.
--            my_aicsar.limithelos -- limit available number of helos going on mission (defaults to true)
--            my_aicsar.helonumber -- number of helos available (default: 3)
--            my_aicsar.verbose -- boolean, set to `true`for message output on-screen
-- 
-- ## Radio output options
-- 
-- Radio messages, soundfile names and (for SRS) lengths are defined in three enumerators, so you can customize, localize messages and soundfiles to your liking:
-- 
-- Defaults are:
-- 
--            AICSAR.Messages = {
--              EN = {
--              INITIALOK = "Roger, Pilot, we hear you. Stay where you are, a helo is on the way!",
--              INITIALNOTOK = "Sorry, Pilot. You're behind maximum operational distance! Good Luck!",
--              PILOTDOWN = "Mayday, mayday, mayday! Pilot down at ", -- note that this will be appended with the position in MGRS
--              PILOTKIA = "Pilot KIA!",
--              HELODOWN = "CSAR Helo Down!",
--              PILOTRESCUED = "Pilot rescued!",
--              PILOTINHELO = "Pilot picked up!",
--              },
--            }
-- 
-- Correspondingly, sound file names are defined as these defaults:
-- 
--            AICSAR.RadioMessages = {
--              EN = {
--              INITIALOK = "initialok.ogg",
--              INITIALNOTOK = "initialnotok.ogg",
--              PILOTDOWN = "pilotdown.ogg",
--              PILOTKIA = "pilotkia.ogg", 
--              HELODOWN = "helodown.ogg", 
--              PILOTRESCUED = "pilotrescued.ogg", 
--              PILOTINHELO = "pilotinhelo.ogg",
--              }, 
--            }
-- 
-- and these default transmission lengths in seconds:
-- 
--            AICSAR.RadioLength = {
--              EN = {
--              INITIALOK = 4.1,
--              INITIALNOTOK = 4.6, 
--              PILOTDOWN = 2.6,
--              PILOTKIA = 1.1,
--              HELODOWN = 2.1,
--              PILOTRESCUED = 3.5,
--              PILOTINHELO = 2.6,
--              },
--            }
--
-- ## Radio output via SRS and Text-To-Speech (TTS)
-- 
-- Radio output can be done via SRS and Text-To-Speech. No extra sound files required! 
-- [Initially, Have a look at the guide on setting up SRS TTS for Moose](https://github.com/FlightControl-Master/MOOSE_GUIDES/blob/master/documents/Moose%20TTS%20Setup%20Guide.pdf).
-- The text from the `AICSAR.Messages` table above is converted on the fly to an .ogg-file, which is then played back via SRS on the selected frequency and mdulation.
-- Hint - the small black window popping up shortly is visible in Single-Player only. 
-- 
-- To set up AICSAR for SRS TTS output, add e.g. the following to your script:
--              
--              -- setup for google TTS, radio 243 AM, SRS server port 5002 with a google standard-quality voice (google cloud account required)
--              my_aicsar:SetSRSTTSRadio(true,"C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio",243,radio.modulation.AM,5002,MSRS.Voices.Google.Standard.en_US_Standard_D,"en-US","female","C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio\\google.json")
--              
--              -- alternatively for MS Desktop TTS (voices need to be installed locally first!)
--              my_aicsar:SetSRSTTSRadio(true,"C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio",243,radio.modulation.AM,5002,MSRS.Voices.Microsoft.Hazel,"en-GB","female")
--              
--              -- define a different voice for the downed pilot(s)
--              my_aicsar:SetPilotTTSVoice(MSRS.Voices.Google.Standard.en_AU_Standard_D,"en-AU","male")
--              
--              -- define another voice for the operator
--              my_aicsar:SetOperatorTTSVoice(MSRS.Voices.Google.Standard.en_GB_Standard_A,"en-GB","female")
--
-- ## Radio output via preproduced soundfiles
--
-- The easiest way to add a soundfile to your mission is to use the "Sound to..." trigger in the mission editor. This will effectively 
-- save your sound file inside of the .miz mission file. [Example soundfiles are located on github](https://github.com/FlightControl-Master/MOOSE_SOUND/tree/master/AICSAR)
-- 
-- To customize or localize your texts and sounds, you can take e.g. the following approach to add a German language version:
-- 
--           -- parameters are: locale, ID, text, soundfilename, duration
--           my_aicsar.gettext:AddEntry("de","INITIALOK","Copy, Pilot, wir hören Sie. Bleiben Sie, wo Sie sind, ein Hubschrauber sammelt Sie auf!","okneu.ogg",5.0)
--           my_aicsar.locale = "de" -- plays and shows the defined German language texts and sound. Fallback is "en", if something is undefined.
--           
-- Switch on radio transmissions via **either** SRS **or** "normal" DCS radio e.g. like so:
-- 
--          my_aicsar:SetSRSRadio(true,"C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio",270,radio.modulation.AM,nil,5002)
--         
-- or         
--          
--          my_aicsar:SetDCSRadio(true,300,radio.modulation.AM,GROUP:FindByName("FARP-Radio"))
-- 
-- See the function documentation for parameter details.
--                    
-- ===
---
--
-- @field #AICSAR
AICSAR = {
  ClassName = "AICSAR",
  version = "0.1.18",
  lid = "",
  coalition = coalition.side.BLUE,
  template = "",
  helotemplate = "",
  alias = "",
  farp = nil,
  farpzone = nil,
  maxdistance = UTILS.NMToMeters(50),
  pilotqueue = {},
  pilotindex = 0,
  helos = {},
  verbose = false,
  rescuezoneradius = 200,
  rescued = {},
  autoonoff = true,
  playerset = nil,
  Messages = {},
  SRS = nil,
  SRSRadio = false,
  SRSFrequency = 243,
  SRSPath = "\\",
  SRSModulation = radio.modulation.AM,
  SRSSoundPath = nil, -- defaults to "l10n/DEFAULT/", i.e. add messages via "Sount to..." in the ME
  SRSPort = 5002,
  DCSRadio = false,
  DCSFrequency = 243,
  DCSModulation = radio.modulation.AM,
  DCSRadioGroup = nil,
  limithelos = true,
  helonumber = 3,
  gettext = nil,
  locale ="en", -- default text language
  SRSTTSRadio = false,
  SRSGoogle = false,
  SRSQ = nil,
  SRSPilot = nil,
  SRSPilotVoice = false,
  SRSOperator = nil,
  SRSOperatorVoice = false,
  PilotStore = nil,
  Speed = 100,
  Altitude = 1500,
  UseEventEject = false,
  Delay = 100,
  UseRescueZone = false,
  RescueZone = nil,
}

-- TODO Messages
--- Messages enum
-- @field Messages
AICSAR.Messages = {
  EN = {
  INITIALOK = "Roger, Pilot, we hear you. Stay where you are, a helo is on the way!",
  INITIALNOTOK = "Sorry, Pilot. You're behind maximum operational distance! Good Luck!",
  PILOTDOWN = "Mayday, mayday, mayday! Pilot down at ",
  PILOTKIA = "Pilot KIA!",
  HELODOWN = "CSAR Helo Down!",
  PILOTRESCUED = "Pilot rescued!",
  PILOTINHELO = "Pilot picked up!",
  },
  DE = {
  INITIALOK = "Copy, Pilot, wir hören Sie. Bleiben Sie, wo Sie sind!\nEin Hubschrauber sammelt Sie auf!",
  INITIALNOTOK = "Verstehe, Pilot. Sie sind zu weit weg von uns.\nViel Glück!",
  PILOTDOWN = "Mayday, mayday, mayday! Pilot abgestürzt: ",
  PILOTKIA = "Pilot gefallen!",
  HELODOWN = "CSAR Hubschrauber verloren!",
  PILOTRESCUED = "Pilot gerettet!",
  PILOTINHELO = "Pilot an Bord geholt!",
  },
}

-- TODO Radio Messages
--- Radio Messages enum for ogg files
-- @field RadioMessages
AICSAR.RadioMessages = {
  EN = {
  INITIALOK = "initialok.ogg", -- 4.1 secs
  INITIALNOTOK = "initialnotok.ogg", -- 4.6 secs
  PILOTDOWN = "pilotdown.ogg", -- 2.6 secs
  PILOTKIA = "pilotkia.ogg", -- 1.1 sec
  HELODOWN = "helodown.ogg", -- 2.1 secs
  PILOTRESCUED = "pilotrescued.ogg", -- 3.5 secs
  PILOTINHELO = "pilotinhelo.ogg", -- 2.6 secs
  },
}

-- TODO Radio Messages
--- Radio Messages enum for ogg files length in secs
-- @field RadioLength
AICSAR.RadioLength = {
  EN = {
  INITIALOK = 4.1,
  INITIALNOTOK = 4.6, 
  PILOTDOWN = 2.6,
  PILOTKIA = 1.1,
  HELODOWN = 2.1,
  PILOTRESCUED = 3.5,
  PILOTINHELO = 2.6,
  },
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function to create a new AICSAR object
-- @param #AICSAR self
-- @param #string Alias Name of this instance.
-- @param #number Coalition Coalition as in coalition.side.BLUE, can also be passed as "blue", "red" or "neutral"
-- @param #string Pilottemplate Pilot template name.
-- @param #string Helotemplate Helicopter template name.
-- @param Wrapper.Airbase#AIRBASE FARP FARP object or Airbase from where to start.
-- @param Core.Zone#ZONE MASHZone Zone where to drop pilots after rescue.
-- @param #number Helonumber Max number of alive Ai Helos at the same time. Defaults to three.
-- @return #AICSAR self
function AICSAR:New(Alias,Coalition,Pilottemplate,Helotemplate,FARP,MASHZone,Helonumber)
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
      self:E("ERROR: Unknown coalition in AICSAR!")
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
  
  self.template = Pilottemplate
  self.helotemplate = Helotemplate
  self.farp = FARP
  self.farpzone = MASHZone
  self.playerset = SET_CLIENT:New():FilterActive(true):FilterCategories("helicopter"):FilterStart()
  self.UseEventEject = false
  self.Delay = 300
  
  -- Radio
  self.SRS = nil
  self.SRSRadio = false
  self.SRSTTSRadio = false
  self.SRSGoogle = false
  self.SRSQ = nil
  self.SRSFrequency = 243
  self.SRSPath = "\\"
  self.SRSModulation = radio.modulation.AM
  self.SRSSoundPath = nil -- defaults to "l10n/DEFAULT/", i.e. add messages via "Sound to..." in the ME
  self.SRSPort = 5002
  
  -- DCS Radio - add messages via "Sound to..." in the ME
  self.DCSRadio = false
  self.DCSFrequency = 243
  self.DCSModulation = radio.modulation.AM
  self.DCSRadioGroup = nil
  self.DCSRadioQueue = nil
  
  self.MGRS_Accuracy = 2
  
  -- limit number of available helos at the same time
  self.limithelos = true
  self.helonumber = Helonumber or 3

  -- localization
  self:InitLocalization()
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  --Pilot Store
  self.PilotStore = FIFO:New()
  
  -- Start State.
  self:SetStartState("Stopped")
  
    -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- CSAR status update.
  self:AddTransition("*",             "PilotDown",          "*")           -- Pilot down
  self:AddTransition("*",             "PilotPickedUp",      "*")           -- Pilot in helo
  self:AddTransition("*",             "PilotUnloaded",      "*")           -- Pilot Unloaded from helo
  self:AddTransition("*",             "PilotRescued",       "*")           -- Pilot Rescued
  self:AddTransition("*",             "PilotKIA",           "*")           -- Pilot dead
  self:AddTransition("*",             "HeloDown",           "*")           -- Helo dead
  self:AddTransition("*",             "HeloOnDuty",         "*")           -- Helo spawnd
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.
  
  self:HandleEvent(EVENTS.LandingAfterEjection,self._EventHandler)
  self:HandleEvent(EVENTS.Ejection,self._EjectEventHandler)
  
  self:__Start(math.random(2,5))
  
  local text = string.format("%sAICSAR Version %s Starting",self.lid,self.version)
  
  self:I(text)
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Status".
  -- @function [parent=#AICSAR] Status
  -- @param #AICSAR self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#AICSAR] __Status
  -- @param #AICSAR self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop".
  -- @function [parent=#AICSAR] Stop
  -- @param #AICSAR self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#AICSAR] __Stop
  -- @param #AICSAR self
  -- @param #number delay Delay in seconds.
  
  --- On after "PilotDown" event.
  -- @function [parent=#AICSAR] OnAfterPilotDown
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Coordinate Location of the pilot.
  -- @param #boolean InReach True if in maxdistance else false. 
  
  --- On after "PilotPickedUp" event.
  -- @function [parent=#AICSAR] OnAfterPilotPickedUp
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP Helo
  -- @param #table CargoTable of Ops.OpsGroup#OPSGROUP Cargo objects
  -- @param #number Index  
  
  --- On after "PilotRescued" event.
  -- @function [parent=#AICSAR] OnAfterPilotRescued
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string PilotName 

  --- On after "PilotUnloaded" event.
  -- @function [parent=#AICSAR] OnAfterPilotUnloaded
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP Helo
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup  

  --- On after "PilotKIA" event.
  -- @function [parent=#AICSAR] OnAfterPilotKIA
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state. 

  --- On after "HeloOnDuty" event.
  -- @function [parent=#AICSAR] OnAfterHeloOnDuty
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP Helo Helo group object

  --- On after "HeloDown" event.
  -- @function [parent=#AICSAR] OnAfterHeloDown
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP Helo
  -- @param #number Index
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] Create the Moose TextAndSoundEntries
-- @param #AICSAR self
-- @return #AICSAR self
function AICSAR:InitLocalization()
  self:T(self.lid .. "InitLocalization")
  -- English standard localization
  self.gettext=TEXTANDSOUND:New(self.ClassName, "en")
  self.gettext:AddEntry("en","INITIALOK",AICSAR.Messages.EN.INITIALOK,AICSAR.RadioMessages.EN.INITIALOK,AICSAR.RadioLength.INITIALOK)
  self.gettext:AddEntry("en","INITIALNOTOK",AICSAR.Messages.EN.INITIALNOTOK,AICSAR.RadioMessages.EN.INITIALNOTOK,AICSAR.RadioLength.EN.INITIALNOTOK)
  self.gettext:AddEntry("en","HELODOWN",AICSAR.Messages.EN.HELODOWN,AICSAR.RadioMessages.EN.HELODOWN,AICSAR.RadioLength.EN.HELODOWN)
  self.gettext:AddEntry("en","PILOTDOWN",AICSAR.Messages.EN.PILOTDOWN,AICSAR.RadioMessages.EN.PILOTDOWN,AICSAR.RadioLength.EN.PILOTDOWN)
  self.gettext:AddEntry("en","PILOTINHELO",AICSAR.Messages.EN.PILOTINHELO,AICSAR.RadioMessages.EN.PILOTINHELO,AICSAR.RadioLength.EN.PILOTINHELO)
  self.gettext:AddEntry("en","PILOTKIA",AICSAR.Messages.EN.PILOTKIA,AICSAR.RadioMessages.EN.PILOTKIA,AICSAR.RadioLength.EN.PILOTKIA)
  self.gettext:AddEntry("en","PILOTRESCUED",AICSAR.Messages.EN.PILOTRESCUED,AICSAR.RadioMessages.EN.PILOTRESCUED,AICSAR.RadioLength.EN.PILOTRESCUED)
  -- German localization - we keep the sound files English
  self.gettext:AddEntry("de","INITIALOK",AICSAR.Messages.DE.INITIALOK,AICSAR.RadioMessages.EN.INITIALOK,AICSAR.RadioLength.INITIALOK)
  self.gettext:AddEntry("de","INITIALNOTOK",AICSAR.Messages.DE.INITIALNOTOK,AICSAR.RadioMessages.EN.INITIALNOTOK,AICSAR.RadioLength.EN.INITIALNOTOK)
  self.gettext:AddEntry("de","HELODOWN",AICSAR.Messages.DE.HELODOWN,AICSAR.RadioMessages.EN.HELODOWN,AICSAR.RadioLength.EN.HELODOWN)
  self.gettext:AddEntry("de","PILOTDOWN",AICSAR.Messages.DE.PILOTDOWN,AICSAR.RadioMessages.EN.PILOTDOWN,AICSAR.RadioLength.EN.PILOTDOWN)
  self.gettext:AddEntry("de","PILOTINHELO",AICSAR.Messages.DE.PILOTINHELO,AICSAR.RadioMessages.EN.PILOTINHELO,AICSAR.RadioLength.EN.PILOTINHELO)
  self.gettext:AddEntry("de","PILOTKIA",AICSAR.Messages.DE.PILOTKIA,AICSAR.RadioMessages.EN.PILOTKIA,AICSAR.RadioLength.EN.PILOTKIA)
  self.gettext:AddEntry("de","PILOTRESCUED",AICSAR.Messages.DE.PILOTRESCUED,AICSAR.RadioMessages.EN.PILOTRESCUED,AICSAR.RadioLength.EN.PILOTRESCUED)
  self.locale = "en"
  return self
end

--- [User] Use a defined zone as area of operation and not the distance to FARP.
-- @param #AICSAR self
-- @param Core.Zone#ZONE Zone The operational zone to use. Downed pilots in this area will be rescued. Can be any known #ZONE type.
-- @return #AICSAR self 
function AICSAR:SetUsingRescueZone(Zone)
  self.UseRescueZone = true
  self.RescueZone = Zone
  return self
end

--- [User] Switch sound output on and use SRS output for sound files.
-- @param #AICSAR self
-- @param #boolean OnOff Switch on (true) or off (false).
-- @param #string Path Path to your SRS Server External Audio Component, e.g. "C:\\\\Program Files\\\\DCS-SimpleRadio-Standalone\\\\ExternalAudio"
-- @param #number Frequency Defaults to 243 (guard)
-- @param #number Modulation Radio modulation. Defaults to radio.modulation.AM
-- @param #string SoundPath Where to find the audio files. Defaults to nil, i.e. add messages via "Sound to..." in the Mission Editor.
-- @param #number Port Port of the SRS, defaults to 5002.
-- @return #AICSAR self
function AICSAR:SetSRSRadio(OnOff,Path,Frequency,Modulation,SoundPath,Port)
  self:T(self.lid .. "SetSRSRadio")
  self.SRSRadio = OnOff and true
  self.SRSTTSRadio = false
  self.SRSFrequency = Frequency or 243
  self.SRSPath = Path or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
  self.SRS:SetLabel("ACSR")
  self.SRS:SetCoalition(self.coalition)
  self.SRSModulation = Modulation or radio.modulation.AM
  local soundpath = os.getenv('TMP') .. "\\DCS\\Mission\\l10n\\DEFAULT" -- defaults to "l10n/DEFAULT/", i.e. add messages by "Sound to..." in the ME
  self.SRSSoundPath = SoundPath or soundpath
  self.SRSPort = Port or MSRS.port or 5002
  if OnOff then
    self.SRS = MSRS:New(Path,Frequency,Modulation)
    self.SRS:SetPort(self.SRSPort)
  end
  return self
end

--- [User] Switch sound output on and use SRS-TTS output. The voice will be used across all outputs, unless you define an extra voice for downed pilots and/or the operator.
-- See `AICSAR:SetPilotTTSVoice()` and `AICSAR:SetOperatorTTSVoice()`
-- @param #AICSAR self
-- @param #boolean OnOff Switch on (true) or off (false).
-- @param #string Path Path to your SRS Server Component, e.g. "E:\\\\Program Files\\\\DCS-SimpleRadio-Standalone\\ExternalAudio"
-- @param #number Frequency (Optional) Defaults to 243 (guard)
-- @param #number Modulation (Optional) Radio modulation. Defaults to radio.modulation.AM
-- @param #number Port (Optional) Port of the SRS, defaults to 5002.
-- @param #string Voice (Optional) The voice to be used.
-- @param #string Culture (Optional) The culture to be used, defaults to "en-GB"
-- @param #string Gender (Optional)  The gender to be used, defaults to "male"
-- @param #string GoogleCredentials (Optional) Path to google credentials
-- @return #AICSAR self
function AICSAR:SetSRSTTSRadio(OnOff,Path,Frequency,Modulation,Port,Voice,Culture,Gender,GoogleCredentials)
  self:T(self.lid .. "SetSRSTTSRadio")
  self.SRSTTSRadio = OnOff and true
  self.SRSRadio = false
  self.SRSFrequency = Frequency or 243
  self.SRSPath = Path or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
  self.SRSModulation = Modulation or radio.modulation.AM
  self.SRSPort = Port or MSRS.port or 5002
  if OnOff then
    self.SRS = MSRS:New(self.SRSPath,Frequency,Modulation)
    self.SRS:SetPort(self.SRSPort)
    self.SRS:SetCoalition(self.coalition)
    self.SRS:SetLabel("ACSR")
    self.SRS:SetVoice(Voice)
    self.SRS:SetCulture(Culture)
    self.SRS:SetGender(Gender)
    if GoogleCredentials then
      self.SRS:SetProviderOptionsGoogle(GoogleCredentials,GoogleCredentials)
      self.SRS:SetProvider(MSRS.Provider.GOOGLE)
      self.SRSGoogle = true
    end
    self.SRSQ = MSRSQUEUE:New(self.alias)
  end
  return self
end

--- [User] Set SRS TTS Voice of downed pilot. `AICSAR:SetSRSTTSRadio()` needs to be set first!
-- @param #AICSAR self
-- @param #string Voice The voice to be used, e.g. `MSRS.Voices.Google.Standard.en_US_Standard_J` for Google or `MSRS.Voices.Microsoft.David` for Microsoft. 
-- Specific voices override culture and gender!
-- @param #string Culture (Optional) The culture to be used, defaults to "en-US"
-- @param #string Gender (Optional)  The gender to be used, defaults to "male"
-- @return #AICSAR self
function AICSAR:SetPilotTTSVoice(Voice,Culture,Gender)
 self:T(self.lid .. "SetPilotTTSVoice")
 self.SRSPilotVoice = true
 self.SRSPilot = MSRS:New(self.SRSPath,self.SRSFrequency,self.SRSModulation)
 self.SRSPilot:SetCoalition(self.coalition)
 self.SRSPilot:SetVoice(Voice)
 self.SRSPilot:SetCulture(Culture or "en-US")
 self.SRSPilot:SetGender(Gender or "male")
 self.SRSPilot:SetLabel("PILOT")
 if self.SRSGoogle then
  local poptions = self.SRS:GetProviderOptions(MSRS.Provider.GOOGLE) -- Sound.SRS#MSRS.ProviderOptions
  self.SRSPilot:SetProviderOptionsGoogle(poptions.credentials,poptions.key)
  self.SRSPilot:SetProvider(MSRS.Provider.GOOGLE)
 end
 return self
end

--- [User] Set SRS TTS Voice of the rescue operator. `AICSAR:SetSRSTTSRadio()` needs to be set first!
-- @param #AICSAR self
-- @param #string Voice The voice to be used, e.g. `MSRS.Voices.Google.Standard.en_US_Standard_J` for Google or `MSRS.Voices.Microsoft.David` for Microsoft.
-- Specific voices override culture and gender!
-- @param #string Culture (Optional) The culture to be used, defaults to "en-GB"
-- @param #string Gender (Optional)  The gender to be used, defaults to "female"
-- @return #AICSAR self
function AICSAR:SetOperatorTTSVoice(Voice,Culture,Gender)
 self:T(self.lid .. "SetOperatorTTSVoice")
 self.SRSOperatorVoice = true
 self.SRSOperator = MSRS:New(self.SRSPath,self.SRSFrequency,self.SRSModulation)
 self.SRSOperator:SetCoalition(self.coalition)
 self.SRSOperator:SetVoice(Voice)
 self.SRSOperator:SetCulture(Culture or "en-GB")
 self.SRSOperator:SetGender(Gender or "female")
 self.SRSOperator:SetLabel("RESCUE")
 if self.SRSGoogle then
  local poptions = self.SRS:GetProviderOptions(MSRS.Provider.GOOGLE) -- Sound.SRS#MSRS.ProviderOptions
  self.SRSOperator:SetProviderOptionsGoogle(poptions.credentials,poptions.key)
  self.SRSOperator:SetProvider(MSRS.Provider.GOOGLE)
 end
 return self
end

--- [User] Switch sound output on and use normale (DCS) radio
-- @param #AICSAR self
-- @param #boolean OnOff Switch on (true) or off (false).
-- @param #number Frequency Defaults to 243 (guard).
-- @param #number Modulation Radio modulation. Defaults to radio.modulation.AM.
-- @param Wrapper.Group#GROUP Group The group to use as sending station.
-- @return #AICSAR self
function AICSAR:SetDCSRadio(OnOff,Frequency,Modulation,Group)
  self:T(self.lid .. "SetDCSRadio")
  self:T(self.lid .. "SetDCSRadio to "..tostring(OnOff))
  self.DCSRadio = OnOff and true
  self.DCSFrequency = Frequency or 243
  self.DCSModulation = Modulation or radio.modulation.AM
  self.DCSRadioGroup = Group
  if self.DCSRadio then
    self.DCSRadioQueue = RADIOQUEUE:New(Frequency,Modulation,"AI-CSAR")
    self.DCSRadioQueue:Start(5,5)
    self.DCSRadioQueue:SetRadioPower(1000)
    self.DCSRadioQueue:SetSenderCoordinate(Group:GetCoordinate())
  else
    if self.DCSRadioQueue then
      self.DCSRadioQueue:Stop()
    end
  end
  return self
end

--- [Internal] Sound output via non-SRS Radio. Add message files (.ogg) via "Sound to..." in the ME.
-- @param #AICSAR self
-- @param #string Soundfile Name of the soundfile
-- @param #number Duration Duration of the sound
-- @param #string Subtitle Text to display
-- @return #AICSAR self
function AICSAR:DCSRadioBroadcast(Soundfile,Duration,Subtitle)
  self:T(self.lid .. "DCSRadioBroadcast")
  local radioqueue = self.DCSRadioQueue -- Sound.RadioQueue#RADIOQUEUE
  radioqueue:NewTransmission(Soundfile,Duration,nil,2,nil,Subtitle,10)
  return self
end

--- [Internal] Catch the ejection and save the pilot name
-- @param #AICSAR self
-- @param Core.Event#EVENTDATA EventData
-- @return #AICSAR self
function AICSAR:_EjectEventHandler(EventData)
  local _event = EventData -- Core.Event#EVENTDATA
  if _event.IniPlayerName then
    self.PilotStore:Push(_event.IniPlayerName)
    self:T(self.lid.."Pilot Ejected: ".._event.IniPlayerName)
    if self.UseEventEject then
      -- get position and spawn in a template pilot
      local _LandingPos = COORDINATE:NewFromVec3(_event.initiator:getPosition().p)
      local _country = _event.initiator:getCountry()
      local _coalition = coalition.getCountryCoalition( _country )
      --local data = UTILS.DeepCopy(EventData)
      Unit.destroy(_event.initiator) -- shagrat remove static Pilot model
      self:ScheduleOnce(self.Delay,self._DelayedSpawnPilot,self,_LandingPos,_coalition)
    end
  end
  return self
end

--- [Internal] Spawn a pilot
-- @param #AICSAR self
-- @param Core.Point#COORDINATE _LandingPos Landing Postion
-- @param #number _coalition Coalition side
-- @return #AICSAR self
function AICSAR:_DelayedSpawnPilot(_LandingPos,_coalition)

  local distancetofarp = _LandingPos:Get2DDistance(self.farp:GetCoordinate())
  if self.UseRescueZone == true and self.RescueZone ~= nil then
    if self.RescueZone:IsCoordinateInZone(_LandingPos) then
      distancetofarp = self.maxdistance - 10
    else
      distancetofarp = self.maxdistance + 10
    end
  end 
  -- Mayday Message
  local Text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("PILOTDOWN",self.locale)
  local text = ""
  local setting = {}
  setting.MGRS_Accuracy = self.MGRS_Accuracy
  local location = _LandingPos:ToStringMGRS(setting)
  local msgtxt = Text..location.."!"
  location = string.gsub(location,"MGRS ","")
  location = string.gsub(location,"%s+","")
  location = string.gsub(location,"([%a%d])","%1;") -- "0 5 1 "
  location = string.gsub(location,"0","zero")
  location = string.gsub(location,"9","niner")
  location = "MGRS;"..location
  if self.SRSGoogle then
    location = string.format("<say-as interpret-as='characters'>%s</say-as>",location)
  end
  text = Text .. location .. "!"
  local ttstext = Text .. location .. "! Repeat! "..location
  if _coalition == self.coalition then
    if self.verbose then
      MESSAGE:New(msgtxt,15,"AICSAR"):ToCoalition(self.coalition)
     -- MESSAGE:New(msgtxt,15,"AICSAR"):ToLog()
    end
    if self.SRSRadio then
      local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
      sound:SetPlayWithSRS(true)
      self.SRS:PlaySoundFile(sound,2)
    elseif self.DCSRadio then
      self:DCSRadioBroadcast(Soundfile,Soundlength,text)
    elseif self.SRSTTSRadio then
      if self.SRSPilotVoice then
        self.SRSQ:NewTransmission(ttstext,nil,self.SRSPilot,nil,1)
      else
        self.SRSQ:NewTransmission(ttstext,nil,self.SRS,nil,1)
      end
    end   
  end
  
  -- further processing
  if _coalition == self.coalition and distancetofarp <= self.maxdistance then
    -- in reach
    self:T(self.lid .. "Spawning new Pilot")
    self.pilotindex = self.pilotindex + 1
    local newpilot = SPAWN:NewWithAlias(self.template,string.format("%s-AICSAR-%d",self.template, self.pilotindex))
    newpilot:InitDelayOff()
    newpilot:OnSpawnGroup(
      function (grp)
        self.pilotqueue[self.pilotindex] = grp
      end
    )
    newpilot:SpawnFromCoordinate(_LandingPos) 
    
    self:__PilotDown(2,_LandingPos,true)
  elseif _coalition == self.coalition and distancetofarp > self.maxdistance then
    -- out of reach, apologies, too far off   
    self:T(self.lid .. "Pilot out of reach")
    self:__PilotDown(2,_LandingPos,false)
  end 
  return self
end

--- [Internal] Catch the landing after ejection and spawn a pilot in situ.
-- @param #AICSAR self
-- @param Core.Event#EVENTDATA EventData
-- @param #boolean FromEject
-- @return #AICSAR self
function AICSAR:_EventHandler(EventData, FromEject)
  self:T(self.lid .. "OnEventLandingAfterEjection ID=" .. EventData.id)
  
  -- autorescue on off?
  if self.autoonoff then
    if self.playerset:CountAlive() > 0 then
      return self
    end
  end
  
  if self.UseEventEject and (not FromEject) then return self end
  
  local _event = EventData -- Core.Event#EVENTDATA
  -- get position and spawn in a template pilot
  local _LandingPos = COORDINATE:NewFromVec3(_event.initiator:getPosition().p)
  local _country = _event.initiator:getCountry()
  local _coalition = coalition.getCountryCoalition( _country )

  -- DONE: add distance check
  local distancetofarp = _LandingPos:Get2DDistance(self.farp:GetCoordinate())
  if self.UseRescueZone == true and self.RescueZone ~= nil then
    if self.RescueZone:IsCoordinateInZone(_LandingPos) then
      distancetofarp = self.maxdistance - 10
    else
      distancetofarp = self.maxdistance + 10
    end
  end 
  -- Mayday Message
  local Text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("PILOTDOWN",self.locale)
  local text = ""
  local setting = {}
  setting.MGRS_Accuracy = self.MGRS_Accuracy
  local location = _LandingPos:ToStringMGRS(setting)
  local msgtxt = Text..location.."!"
  location = string.gsub(location,"MGRS ","")
  location = string.gsub(location,"%s+","")
  location = string.gsub(location,"([%a%d])","%1;") -- "0 5 1 "
  location = string.gsub(location,"0","zero")
  location = string.gsub(location,"9","niner")
  location = "MGRS;"..location
  if self.SRSGoogle then
    location = string.format("<say-as interpret-as='characters'>%s</say-as>",location)
  end
  text = Text .. location .. "!"
  local ttstext = Text .. location .. "! Repeat! "..location
  if _coalition == self.coalition then
    if self.verbose then
      MESSAGE:New(msgtxt,15,"AICSAR"):ToCoalition(self.coalition)
    end
    if self.SRSRadio then
      local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
      sound:SetPlayWithSRS(true)
      self.SRS:PlaySoundFile(sound,2)
    elseif self.DCSRadio then
      self:DCSRadioBroadcast(Soundfile,Soundlength,text)
    elseif self.SRSTTSRadio then
      if self.SRSPilotVoice then
        self.SRSQ:NewTransmission(ttstext,nil,self.SRSPilot,nil,1)
      else
        self.SRSQ:NewTransmission(ttstext,nil,self.SRS,nil,1)
      end
    end   
  end
  
  -- further processing
  if _coalition == self.coalition and distancetofarp <= self.maxdistance then
    -- in reach
    self:T(self.lid .. "Spawning new Pilot")
    self.pilotindex = self.pilotindex + 1
    local newpilot = SPAWN:NewWithAlias(self.template,string.format("%s-AICSAR-%d",self.template, self.pilotindex))
    newpilot:InitDelayOff()
    newpilot:OnSpawnGroup(
      function (grp)
        self.pilotqueue[self.pilotindex] = grp
      end
    )
    newpilot:SpawnFromCoordinate(_LandingPos) 
    
    Unit.destroy(_event.initiator) -- shagrat remove static Pilot model
    self:__PilotDown(2,_LandingPos,true)
  elseif _coalition == self.coalition and distancetofarp > self.maxdistance then
    -- out of reach, apologies, too far off   
    self:T(self.lid .. "Pilot out of reach")
    self:__PilotDown(2,_LandingPos,false)
  end 
  return self
end

--- [Internal] Get FlightGroup
-- @param #AICSAR self
-- @return Ops.FlightGroup#FLIGHTGROUP The FlightGroup
function AICSAR:_GetFlight()
  self:T(self.lid .. "_GetFlight")
  -- Helo Carrier.
  local newhelo = SPAWN:NewWithAlias(self.helotemplate,self.helotemplate..math.random(1,10000))
    :InitDelayOff()
    :InitUnControlled(true)
    :OnSpawnGroup(
      function(Group)
        Group:OptionPreferVerticalLanding()
        self:__HeloOnDuty(1,Group)
      end
    )
    :Spawn()
    
  local nhelo=FLIGHTGROUP:New(newhelo)
  nhelo:SetHomebase(self.farp)
  nhelo:Activate()
  return nhelo
end

--- [Internal] Create a new rescue mission
-- @param #AICSAR self
-- @param Wrapper.Group#GROUP Pilot The pilot to be rescued.
-- @param #number Index Index number of this pilot
-- @return #AICSAR self
function AICSAR:_InitMission(Pilot,Index)
  self:T(self.lid .. "_InitMission")
  
  local pickupzone = ZONE_GROUP:New(Pilot:GetName(),Pilot,self.rescuezoneradius)
  --local pilotset = SET_GROUP:New()
  --pilotset:AddGroup(Pilot)
  
  -- Cargo transport assignment.
  local opstransport=OPSTRANSPORT:New(Pilot, pickupzone, self.farpzone)
  --opstransport:SetVerbosity(3)
  
  local helo = self:_GetFlight()
  -- inject reservation
  helo.AICSARReserved = true
  
  helo:SetDefaultAltitude(self.Altitude or 1500)
  
  helo:SetDefaultSpeed(self.Speed or 100)
  
  -- Cargo transport assignment to first Huey group.
  helo:AddOpsTransport(opstransport)
  
  -- callback functions
  local function AICPickedUp(Helo,Cargo,Index)
    self:__PilotPickedUp(2,Helo,Cargo,Index)   
  end
  
  local function AICHeloDead(Helo,Index)
    self:__HeloDown(2,Helo,Index)   
  end
  
  local function AICHeloUnloaded(Helo,OpsGroup)
    self:__PilotUnloaded(2,Helo,OpsGroup)
  end
  
  function helo:OnAfterLoading(From,Event,To)
    AICPickedUp(helo,helo:GetCargoGroups(),Index) 
    helo:__LoadingDone(5)  
  end
  
  function helo:OnAfterDead(From,Event,To)
    AICHeloDead(helo,Index)
  end
  
  function helo:OnAfterUnloaded(From,Event,To,OpsGroupCargo)
    AICHeloUnloaded(helo,OpsGroupCargo)
    helo:__UnloadingDone(5)
  end
  
  function helo:OnAfterLandAtAirbase(From,Event,To,airbase)
    helo:Despawn(2)
  end
  
  self.helos[Index] = helo
  
  return self
end

--- [Internal] Check if pilot arrived in rescue zone (MASH)
-- @param #AICSAR self
-- @param Wrapper.Group#GROUP Pilot The pilot to be rescued.
-- @return #boolean outcome
function AICSAR:_CheckInMashZone(Pilot)
  self:T(self.lid .. "_CheckInMashZone")
  if Pilot:IsInZone(self.farpzone) then
    return true
  else
    return false
  end
end

--- [User] Set default helo speed. Note - AI might have other ideas. Defaults to 100kn.
-- @param #AICSAR self
-- @param #number Knots Speed in knots.
-- @return #AICSAR self
function AICSAR:SetDefaultSpeed(Knots)
  self:T(self.lid .. "SetDefaultSpeed")
  self.Speed = Knots or 100
  return self
end

--- [User] Set default helo altitudeAGL. Note - AI might have other ideas. Defaults to 1500ft.
-- @param #AICSAR self
-- @param #number Feet AGL set in feet.
-- @return #AICSAR self
function AICSAR:SetDefaultAltitude(Feet)
  self:T(self.lid .. "SetDefaultAltitude")
  self.Altitude = Feet or 1500
  return self
end

--- [Internal] Check helo queue 
-- @param #AICSAR self
-- @return #AICSAR self
function AICSAR:_CheckHelos()
  self:T(self.lid .. "_CheckHelos")
  for _index,_helo in pairs(self.helos) do
    local helo = _helo -- Ops.FlightGroup#FLIGHTGROUP
    if helo and helo.ClassName == "FLIGHTGROUP" then
      local state = helo:GetState()
      local name = helo:GetName()
      self:T("Helo group "..name.." in state "..state)
      if state == "Arrived" then
        --helo:__Stop(5)
        helo.OnAfterDead = nil
        helo:Despawn(35)
        self.helos[_index] = nil
      end
    else
      self.helos[_index] = nil
    end
  end
  return self
end

--- [Internal] Count helos queue 
-- @param #AICSAR self
-- @return #number Number of helos on mission
function AICSAR:_CountHelos()
  self:T(self.lid .. "_CountHelos")
  local count = 0
    for _index,_helo in pairs(self.helos) do
      count = count + 1
    end
  return count
end

--- [Internal] Check pilot queue for next mission
-- @param #AICSAR self
-- @param Ops.OpsGroup#OPSGROUP OpsGroup
-- @return #AICSAR self
function AICSAR:_CheckQueue(OpsGroup)
  self:T(self.lid .. "_CheckQueue")
  for _index, _pilot in pairs(self.pilotqueue) do
    local classname = _pilot.ClassName and _pilot.ClassName or "NONE"
    local name = _pilot.GroupName and _pilot.GroupName or "NONE"
    local playername = "John Doe"
    local helocount = self:_CountHelos()
    --self:T("Looking at " .. classname .. " " .. name)
    -- find one w/o mission
    if _pilot and _pilot.ClassName and _pilot.ClassName == "GROUP" then
     local flightgroup = self.helos[_index] -- Ops.FlightGroup#FLIGHTGROUP
     -- rescued?
     if self:_CheckInMashZone(_pilot) then
      self:T("Pilot" .. _pilot.GroupName .. " rescued!")
      if OpsGroup then
        --OpsGroup:Despawn(10)
      else 
        _pilot:Destroy(true,10)
      end
      self.pilotqueue[_index] = nil
      self.rescued[_index] = true
      if self.PilotStore:Count() > 0 then
        playername = self.PilotStore:Pull()
      end
      self:__PilotRescued(2,playername)
      if flightgroup then
        flightgroup.AICSARReserved = false
      end
     end -- end rescued
      -- has no mission assigned?
      if not _pilot.AICSAR then
        -- helo available?
        if self.limithelos and helocount >= self.helonumber then
            -- none free
            break
        end -- end limit
        _pilot.AICSAR = {}
        _pilot.AICSAR.Status = "Initiated"
        _pilot.AICSAR.Boarded = false
        self:_InitMission(_pilot,_index)
        break
      else 
       -- update status from OPSGROUP
       if flightgroup then
         local state = flightgroup:GetState()
         _pilot.AICSAR.Status = state
       end
       --self:T("Flight for " .. _pilot.GroupName .. " in state " .. state)
      end -- end has mission
    end -- end if pilot
  end -- end loop
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] onafterStart
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterStart(From, Event, To)
  self:T({From, Event, To})
  self:__Status(3)
  return self
end

--- [Internal] onafterStatus
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  --self:_CheckQueue()
  self:_CheckHelos()
  self:__Status(30)
  return self
end

--- [Internal] onafterStop
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterStop(From, Event, To)
  self:T({From, Event, To})
  self:UnHandleEvent(EVENTS.LandingAfterEjection)
  if self.DCSRadioQueue then
    self.DCSRadioQueue:Stop()
  end
  return self
end

--- [Internal] onafterPilotDown
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Core.Point#COORDINATE Coordinate Location of the pilot.
-- @param #boolean InReach True if in maxdistance else false.
-- @return #AICSAR self
function AICSAR:onafterPilotDown(From, Event, To, Coordinate, InReach)
  self:T({From, Event, To})
  local CoordinateText = Coordinate:ToStringMGRS()
  local inreach = tostring(InReach)
  --local text = string.format("Pilot down at %s. In reach = %s",CoordinateText,inreach)
  if InReach then
    local text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("INITIALOK",self.locale)
    --local text = AICSAR.Messages.EN.INITIALOK
    self:T(text)
    if self.verbose then
      MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
    end
    if self.SRSRadio then
      local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
      sound:SetPlayWithSRS(true)
      self.SRS:PlaySoundFile(sound,2)
    elseif self.DCSRadio then
      self:DCSRadioBroadcast(Soundfile,Soundlength,text)
    elseif self.SRSTTSRadio then
      if self.SRSOperatorVoice then
       self.SRSQ:NewTransmission(text,nil,self.SRSOperator,nil,1)
      else
        self.SRSQ:NewTransmission(text,nil,self.SRS,nil,1)
      end
    end
  else
    local text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("INITIALNOTOK",self.locale)
    --local text = AICSAR.Messages.EN.INITIALNOTOK
    self:T(text)
    if self.verbose then
      MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
    end
    if self.SRSRadio then
      local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
      sound:SetPlayWithSRS(true)
      self.SRS:PlaySoundFile(sound,2)
    elseif self.DCSRadio then
      self:DCSRadioBroadcast(Soundfile,Soundlength,text)
    elseif self.SRSTTSRadio then
      if self.SRSOperatorVoice then
        self.SRSQ:NewTransmission(text,nil,self.SRSOperator,nil,1)
      else
        self.SRSQ:NewTransmission(text,nil,self.SRS,nil,1)
      end
    end
  end
  self:_CheckQueue()
  return self
end

--- [Internal] onafterPilotKIA
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterPilotKIA(From, Event, To)
  self:T({From, Event, To})
  local text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("PILOTKIA",self.locale)
  if self.verbose then
    MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
    sound:SetPlayWithSRS(true)
    self.SRS:PlaySoundFile(sound,2)
  elseif self.DCSRadio then
    self:DCSRadioBroadcast(Soundfile,Soundlength,text)
  elseif self.SRSTTSRadio then
      self.SRSQ:NewTransmission(text,nil,self.SRS,nil,1)
    end
  return self
end

--- [Internal] onafterHeloDown
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.FlightGroup#FLIGHTGROUP Helo
-- @param #number Index
-- @return #AICSAR self
function AICSAR:onafterHeloDown(From, Event, To, Helo, Index)
  self:T({From, Event, To})
  local text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("HELODOWN",self.locale)
  if self.verbose then
    MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
    sound:SetPlayWithSRS(true)
    self.SRS:PlaySoundFile(sound,2)
  elseif self.DCSRadio then
    self:DCSRadioBroadcast(Soundfile,Soundlength,text)
  elseif self.SRSTTSRadio then
    if self.SRSOperatorVoice then
      self.SRSQ:NewTransmission(text,nil,self.SRSOperator,nil,1)
    else
      self.SRSQ:NewTransmission(text,nil,self.SRS,nil,1)
    end
  end
  local findex = 0
  local fhname = Helo:GetName()
  -- find index of Helo
  if Index and Index > 0 then
    findex=Index
  else
    for _index, _helo in pairs(self.helos) do
      local helo = _helo -- Ops.FlightGroup#FLIGHTGROUP
      local hname = helo:GetName()
      if fhname == hname then
        findex = _index
        break
      end
    end
  end
  -- find pilot
  if findex > 0  and not self.rescued[findex] then
    local pilot = self.pilotqueue[findex]
    self.helos[findex] = nil
    if pilot.AICSAR.Boarded then
      self:T("Helo Down: Found DEAD Pilot ID " .. findex .. " with name " .. pilot:GetName())
      -- pilot also dead
      self:__PilotKIA(2)
      self.pilotqueue[findex] = nil
    else
      -- initiate new mission
      self:T("Helo Down: Found ALIVE Pilot ID " .. findex .. " with name " .. pilot:GetName())
      self:_InitMission(pilot,findex)
    end
  end
  return self
end

--- [Internal] onafterPilotRescued
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #string PilotName
-- @return #AICSAR self
function AICSAR:onafterPilotRescued(From, Event, To, PilotName)
  self:T({From, Event, To})
  local text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("PILOTRESCUED",self.locale)
  if self.verbose then
    MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
    sound:SetPlayWithSRS(true)
    self.SRS:PlaySoundFile(sound,2)
  elseif self.DCSRadio then
    self:DCSRadioBroadcast(Soundfile,Soundlength,text)
  elseif self.SRSTTSRadio then
      self.SRSQ:NewTransmission(text,nil,self.SRS,nil,1)
  end
  return self
end

--- [Internal] onafterPilotUnloaded
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.FlightGroup#FLIGHTGROUP Helo
-- @param Ops.OpsGroup#OPSGROUP OpsGroup
-- @return #AICSAR self
function AICSAR:onafterPilotUnloaded(From, Event, To, Helo, OpsGroup)
  self:T({From, Event, To})
  self:_CheckQueue(OpsGroup)
  return self
end

--- [Internal] onafterPilotPickedUp
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.FlightGroup#FLIGHTGROUP Helo
-- @param #table CargoTable of Ops.OpsGroup#OPSGROUP Cargo objects
-- @param #number Index 
-- @return #AICSAR self
function AICSAR:onafterPilotPickedUp(From, Event, To, Helo, CargoTable, Index)
  self:T({From, Event, To})
  local text,Soundfile,Soundlength,Subtitle = self.gettext:GetEntry("PILOTINHELO",self.locale)
  if self.verbose then
    MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(Soundfile,self.SRSSoundPath,Soundlength)
    sound:SetPlayWithSRS(true)
    self.SRS:PlaySoundFile(sound,2)
  elseif self.DCSRadio then
    self:DCSRadioBroadcast(Soundfile,Soundlength,text)
  elseif self.SRSTTSRadio then
    self.SRSQ:NewTransmission(text,nil,self.SRS,nil,1)
  end
  local findex = 0
  local fhname = Helo:GetName()
  if Index and Index > 0 then
    findex = Index
  else
    -- find index of Helo
    for _index, _helo in pairs(self.helos) do
      local helo = _helo -- Ops.FlightGroup#FLIGHTGROUP
      local hname = helo:GetName()
      if fhname == hname then
        findex = _index
        break
      end
    end
  end
  -- find pilot
  if findex > 0  then
    local pilot = self.pilotqueue[findex]
    self:T("Boarded: Found Pilot ID " .. findex .. " with name " .. pilot:GetName())
    pilot.AICSAR.Boarded = true -- mark as boarded
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END AICSAR
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
