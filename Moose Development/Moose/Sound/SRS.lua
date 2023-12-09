--- **Sound** - Simple Radio Standalone (SRS) Integration and Text-to-Speech.
--
-- ===
--
-- **Main Features:**
--
--    * Play sound files via SRS
--    * Play text-to-speach via SRS
--
-- ===
--
-- ## Youtube Videos: None yet
--
-- ===
--
-- ## Missions: None yet
--
-- ===
--
-- ## Sound files: [MOOSE Sound Files](https://github.com/FlightControl-Master/MOOSE_SOUND/releases)
--
-- ===
--
-- The goal of the [SRS](https://github.com/ciribob/DCS-SimpleRadioStandalone) project is to bring VoIP communication into DCS and to make communication as frictionless as possible.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Sound.SRS
-- @image Sound_MSRS.png

--- MSRS class.
-- @type MSRS
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table frequencies Frequencies used in the transmissions.
-- @field #table modulations Modulations used in the transmissions.
-- @field #number coalition Coalition of the transmission.
-- @field #number port Port. Default 5002.
-- @field #string name Name. Default "DCS-STTS".
-- @field #number volume Volume between 0 (min) and 1 (max). Default 1.
-- @field #string culture Culture. Default "en-GB".
-- @field #string gender Gender. Default "female".
-- @field #string voice Specifc voce.
-- @field Core.Point#COORDINATE coordinate Coordinate from where the transmission is send.
-- @field #string path Path to the SRS exe. This includes the final slash "/".
-- @field #string google Full path google credentials JSON file, e.g. "C:\Users\username\Downloads\service-account-file.json".
-- @field #string Label Label showing up on the SRS radio overlay. Default is "ROBOT". No spaces allowed.
-- @field #table AltBackend Table containing functions and variables to enable an alternate backend to transmit to SRS.
-- @field #string ConfigFileName Name of the standard config file
-- @field #string ConfigFilePath Path to the standard config file
-- @field #boolean ConfigLoaded
-- @field #string ttsprovider Default provider TTS backend, e.g. "Google" or "Microsoft", default is Microsoft
-- @extends Core.Base#BASE

--- *It is a very sad thing that nowadays there is so little useless information.* - Oscar Wilde
--
-- ===
--
-- # The MSRS Concept
--
-- This class allows to broadcast sound files or text via Simple Radio Standalone (SRS).
-- 
-- ## Prerequisites
-- 
-- This script needs SRS version >= 1.9.6.
-- 
-- # Play Sound Files
-- 
--     local soundfile=SOUNDFILE:New("My Soundfile.ogg", "D:\\Sounds For DCS")
--     local msrs=MSRS:New("C:\\Path To SRS", 251, radio.modulation.AM)
--     msrs:PlaySoundFile(soundfile)
-- 
-- # Play Text-To-Speech
-- 
-- Basic example:
-- 
--     -- Create a SOUNDTEXT object.
--     local text=SOUNDTEXT:New("All Enemies destroyed")
--     
--     -- MOOSE SRS 
--     local msrs=MSRS:New("D:\\DCS\\_SRS\\", 305, radio.modulation.AM)
--
--     -- Text-to speech with default voice after 2 seconds.
--     msrs:PlaySoundText(text, 2)
--
-- ## Set Gender
-- 
-- Use a specific gender with the @{#MSRS.SetGender} function, e.g. `SetGender("male")` or `:SetGender("female")`.
-- 
-- ## Set Culture
-- 
-- Use a specific "culture" with the @{#MSRS.SetCulture} function, e.g. `:SetCulture("en-US")` or `:SetCulture("de-DE")`.
-- 
-- ## Set Google
-- 
-- Use Google's text-to-speech engine with the @{#MSRS.SetGoogle} function, e.g. ':SetGoogle()'.
-- By enabling this it also allows you to utilize SSML in your text for added flexibility.
-- For more information on setting up a cloud account, visit: https://cloud.google.com/text-to-speech
-- Google's supported SSML reference: https://cloud.google.com/text-to-speech/docs/ssml
-- 
-- 
-- **Pro-Tipp** - use the command line with power shell to call DCS-SR-ExternalAudio.exe - it will tell you what is missing.    
-- and also the Google Console error, in case you have missed a step in setting up your Google TTS.   
-- E.g. `.\DCS-SR-ExternalAudio.exe -t "Text Message" -f 255 -m AM -c 2 -s 2 -z -G "Path_To_You_Google.Json"`   
-- Plays a message on 255AM for the blue coalition in-game.
-- 
-- ## Set Voice
-- 
-- Use a specific voice with the @{#MSRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system.
-- If enabling SetGoogle(), you can use voices provided by Google
-- Google's supported voices: https://cloud.google.com/text-to-speech/docs/voices
-- For voices there are enumerators in this class to help you out on voice names:
-- 
--            MSRS.Voices.Microsoft -- e.g. MSRS.Voices.Microsoft.Hedda - the Microsoft enumerator contains all voices known to work with SRS
--            MSRS.Voices.Google -- e.g. MSRS.Voices.Google.Standard.en_AU_Standard_A or MSRS.Voices.Google.Wavenet.de_DE_Wavenet_C - The Google enumerator contains voices for EN, DE, IT, FR and ES.
-- 
-- ## Set Coordinate
-- 
-- Use @{#MSRS.SetCoordinate} to define the origin from where the transmission is broadcasted.
--
-- ## Set SRS Port
-- 
-- Use @{#MSRS.SetPort} to define the SRS port. Defaults to 5002.
-- 
-- ## Set SRS Volume
-- 
-- Use @{#MSRS.SetVolume} to define the SRS volume. Defaults to 1.0. Allowed values are between 0.0 and 1.0, from silent to loudest.
-- 
-- ## Config file for many variables, auto-loaded by Moose
-- 
-- See @{#MSRS.LoadConfigFile} for details on how to set this up.
-- 
-- ## Set DCS-gRPC as an alternative to 'DCS-SR-ExternalAudio.exe' for TTS 
--
-- Use @{#MSRS.SetDefaultBackendGRPC} to enable [DCS-gRPC](https://github.com/DCS-gRPC/rust-server) as an alternate backend for transmitting text-to-speech over SRS.
-- This can be useful if 'DCS-SR-ExternalAudio.exe' cannot be used in the environment, or to use Azure or AWS clouds for TTS.  Note that DCS-gRPC does not (yet?) support
-- all of the features and options available with 'DCS-SR-ExternalAudio.exe'. Of note, only text-to-speech is supported and it it cannot be used to transmit audio files.
--
-- DCS-gRPC must be installed and configured per the [DCS-gRPC documentation](https://github.com/DCS-gRPC/rust-server) and already running via either the 'autostart' mechanism 
-- or a Lua call to 'GRPC.load()' prior to use of the alternate DCS-gRPC backend. If a cloud TTS provider is being used, the API key must be set via the 'Config\dcs-grpc.lua' 
-- configuration file prior DCS-gRPC being started. DCS-gRPC can be used both with DCS dedicated server and regular DCS installations.
-- 
-- To use the default local Windows TTS with DCS-gRPC, Windows 2019 Server (or newer) or Windows 10/11 are required.  Voices for non-local languages and dialects may need to
-- be explicitly installed.
--
-- To set the MSRS class to use the DCS-gRPC backend for all future instances, call the function `MSRS.SetDefaultBackendGRPC()`.
--
-- **Note** - When using other classes that use MSRS with the alternate DCS-gRPC backend, pass them strings instead of nil values for non-applicable fields with filesystem paths, 
-- such as the SRS path or Google credential path. This will help maximize compatibility with other classes that were written for the default backend.
--
-- Basic Play Text-To-Speech example using alternate DCS-gRPC backend (DCS-gRPC not previously started):
--
--     -- Start DCS-gRPC
--     GRPC.load()
--     -- Select the alternate DCS-gRPC backend for new MSRS instances
--     MSRS.SetDefaultBackendGRPC()
--     -- Create a SOUNDTEXT object.
--     local text=SOUNDTEXT:New("All Enemies destroyed")  
--     -- MOOSE SRS 
--     local msrs=MSRS:New('', 305.0)
--     -- Text-to speech with default voice after 30 seconds.
--     msrs:PlaySoundText(text, 30)
--
-- Basic example of using another class (ATIS) with SRS and the DCS-gRPC backend (DCS-gRPC not previously started):
--
--     -- Start DCS-gRPC
--     GRPC.load()
--     -- Select the alternate DCS-gRPC backend for new MSRS instances
--     MSRS.SetDefaultBackendGRPC()
--     -- Create new ATIS as usual
--     atis=ATIS:New("Nellis", 251, radio.modulation.AM)
--     -- ATIS:SetSRS() expects a string for the SRS path even though it is not needed with DCS-gRPC
--     atis:SetSRS('')
--     -- Start ATIS
--     atis:Start()
--
-- @field #MSRS
MSRS = {
  ClassName      =     "MSRS",
  lid            =        nil,
  port           =       5002,
  name           =     "MSRS",
  frequencies    =         {},
  modulations    =         {},
  coalition      =          0,
  gender         =   "female",
  culture        =        nil,  
  voice          =        nil,
  volume         =          1,  
  speed          =          1,
  coordinate     =        nil,
  Label          =    "ROBOT",
  AltBackend     =        nil,
  ConfigFileName =    "Moose_MSRS.lua",
  ConfigFilePath =    "Config\\",
  ConfigLoaded   =     false,
  ttsprovider    =     "Microsoft",
}

--- MSRS class version.
-- @field #string version
MSRS.version="0.1.3"

--- Voices
-- @type MSRS.Voices
MSRS.Voices = {
  Microsoft = {
    ["Hedda"] = "Microsoft Hedda Desktop", -- de-DE
    ["Hazel"] = "Microsoft Hazel Desktop", -- en-GB
    ["David"] = "Microsoft David Desktop", -- en-US
    ["Zira"] = "Microsoft Zira Desktop", -- en-US
    ["Hortense"] = "Microsoft Hortense Desktop", --fr-FR
    },
  Google = {
    Standard = {
       ["en_AU_Standard_A"] = 'en-AU-Standard-A', -- [1] FEMALE
       ["en_AU_Standard_B"] = 'en-AU-Standard-B', -- [2] MALE
       ["en_AU_Standard_C"] = 'en-AU-Standard-C', -- [3] FEMALE
       ["en_AU_Standard_D"] = 'en-AU-Standard-D', -- [4] MALE
       ["en_IN_Standard_A"] = 'en-IN-Standard-A', -- [5] FEMALE
       ["en_IN_Standard_B"] = 'en-IN-Standard-B', -- [6] MALE
       ["en_IN_Standard_C"] = 'en-IN-Standard-C', -- [7] MALE
       ["en_IN_Standard_D"] = 'en-IN-Standard-D', -- [8] FEMALE
       ["en_GB_Standard_A"] = 'en-GB-Standard-A', -- [9] FEMALE
       ["en_GB_Standard_B"] = 'en-GB-Standard-B', -- [10] MALE
       ["en_GB_Standard_C"] = 'en-GB-Standard-C', -- [11] FEMALE
       ["en_GB_Standard_D"] = 'en-GB-Standard-D', -- [12] MALE
       ["en_GB_Standard_F"] = 'en-GB-Standard-F', -- [13] FEMALE
       ["en_US_Standard_A"] = 'en-US-Standard-A', -- [14] MALE
       ["en_US_Standard_B"] = 'en-US-Standard-B', -- [15] MALE
       ["en_US_Standard_C"] = 'en-US-Standard-C', -- [16] FEMALE
       ["en_US_Standard_D"] = 'en-US-Standard-D', -- [17] MALE
       ["en_US_Standard_E"] = 'en-US-Standard-E', -- [18] FEMALE
       ["en_US_Standard_F"] = 'en-US-Standard-F', -- [19] FEMALE
       ["en_US_Standard_G"] = 'en-US-Standard-G', -- [20] FEMALE
       ["en_US_Standard_H"] = 'en-US-Standard-H', -- [21] FEMALE
       ["en_US_Standard_I"] = 'en-US-Standard-I', -- [22] MALE
       ["en_US_Standard_J"] = 'en-US-Standard-J', -- [23] MALE
       ["fr_FR_Standard_A"] = "fr-FR-Standard-A", -- Female
       ["fr_FR_Standard_B"] = "fr-FR-Standard-B", -- Male
       ["fr_FR_Standard_C"] = "fr-FR-Standard-C", -- Female
       ["fr_FR_Standard_D"] = "fr-FR-Standard-D", -- Male
       ["fr_FR_Standard_E"] = "fr-FR-Standard-E", -- Female
       ["de_DE_Standard_A"] = "de-DE-Standard-A", -- Female
       ["de_DE_Standard_B"] = "de-DE-Standard-B", -- Male
       ["de_DE_Standard_C"] = "de-DE-Standard-C", -- Female
       ["de_DE_Standard_D"] = "de-DE-Standard-D", -- Male
       ["de_DE_Standard_E"] = "de-DE-Standard-E", -- Male
       ["de_DE_Standard_F"] = "de-DE-Standard-F", -- Female
       ["es_ES_Standard_A"] = "es-ES-Standard-A", -- Female
       ["es_ES_Standard_B"] = "es-ES-Standard-B", -- Male
       ["es_ES_Standard_C"] = "es-ES-Standard-C", -- Female
       ["es_ES_Standard_D"] = "es-ES-Standard-D", -- Female
       ["it_IT_Standard_A"] = "it-IT-Standard-A", -- Female
       ["it_IT_Standard_B"] = "it-IT-Standard-B", -- Female
       ["it_IT_Standard_C"] = "it-IT-Standard-C", -- Male
       ["it_IT_Standard_D"] = "it-IT-Standard-D", -- Male
      },
      Wavenet = {
       ["en_AU_Wavenet_A"] = 'en-AU-Wavenet-A', -- [1] FEMALE
       ["en_AU_Wavenet_B"] = 'en-AU-Wavenet-B', -- [2] MALE
       ["en_AU_Wavenet_C"] = 'en-AU-Wavenet-C', -- [3] FEMALE
       ["en_AU_Wavenet_D"] = 'en-AU-Wavenet-D', -- [4] MALE
       ["en_IN_Wavenet_A"] = 'en-IN-Wavenet-A', -- [5] FEMALE
       ["en_IN_Wavenet_B"] = 'en-IN-Wavenet-B', -- [6] MALE
       ["en_IN_Wavenet_C"] = 'en-IN-Wavenet-C', -- [7] MALE
       ["en_IN_Wavenet_D"] = 'en-IN-Wavenet-D', -- [8] FEMALE
       ["en_GB_Wavenet_A"] = 'en-GB-Wavenet-A', -- [9] FEMALE
       ["en_GB_Wavenet_B"] = 'en-GB-Wavenet-B', -- [10] MALE
       ["en_GB_Wavenet_C"] = 'en-GB-Wavenet-C', -- [11] FEMALE
       ["en_GB_Wavenet_D"] = 'en-GB-Wavenet-D', -- [12] MALE
       ["en_GB_Wavenet_F"] = 'en-GB-Wavenet-F', -- [13] FEMALE
       ["en_US_Wavenet_A"] = 'en-US-Wavenet-A', -- [14] MALE
       ["en_US_Wavenet_B"] = 'en-US-Wavenet-B', -- [15] MALE
       ["en_US_Wavenet_C"] = 'en-US-Wavenet-C', -- [16] FEMALE
       ["en_US_Wavenet_D"] = 'en-US-Wavenet-D', -- [17] MALE
       ["en_US_Wavenet_E"] = 'en-US-Wavenet-E', -- [18] FEMALE
       ["en_US_Wavenet_F"] = 'en-US-Wavenet-F', -- [19] FEMALE
       ["en_US_Wavenet_G"] = 'en-US-Wavenet-G', -- [20] FEMALE
       ["en_US_Wavenet_H"] = 'en-US-Wavenet-H', -- [21] FEMALE
       ["en_US_Wavenet_I"] = 'en-US-Wavenet-I', -- [22] MALE
       ["en_US_Wavenet_J"] = 'en-US-Wavenet-J', -- [23] MALE
       ["fr_FR_Wavenet_A"] = "fr-FR-Wavenet-A", -- Female
       ["fr_FR_Wavenet_B"] = "fr-FR-Wavenet-B", -- Male
       ["fr_FR_Wavenet_C"] = "fr-FR-Wavenet-C", -- Female
       ["fr_FR_Wavenet_D"] = "fr-FR-Wavenet-D", -- Male
       ["fr_FR_Wavenet_E"] = "fr-FR-Wavenet-E", -- Female
       ["de_DE_Wavenet_A"] = "de-DE-Wavenet-A", -- Female
       ["de_DE_Wavenet_B"] = "de-DE-Wavenet-B", -- Male
       ["de_DE_Wavenet_C"] = "de-DE-Wavenet-C", -- Female
       ["de_DE_Wavenet_D"] = "de-DE-Wavenet-D", -- Male
       ["de_DE_Wavenet_E"] = "de-DE-Wavenet-E", -- Male
       ["de_DE_Wavenet_F"] = "de-DE-Wavenet-F", -- Female      
       ["es_ES_Wavenet_B"] = "es-ES-Wavenet-B", -- Male
       ["es_ES_Wavenet_C"] = "es-ES-Wavenet-C", -- Female
       ["es_ES_Wavenet_D"] = "es-ES-Wavenet-D", -- Female
       ["it_IT_Wavenet_A"] = "it-IT-Wavenet-A", -- Female
       ["it_IT_Wavenet_B"] = "it-IT-Wavenet-B", -- Female
       ["it_IT_Wavenet_C"] = "it-IT-Wavenet-C", -- Male
       ["it_IT_Wavenet_D"] = "it-IT-Wavenet-D", -- Male
      } , 
    },
  }

---
-- @type MSRS.ProviderOptions
-- @field #string key
-- @field #string secret
-- @field #string region
-- @field #string defaultVoice
-- @field #string voice

--- GRPC options
-- @type MSRS.GRPCOptions
-- @field #string plaintext
-- @field #string srsClientName
-- @field #table position
-- @field #string coalition
-- @field #MSRS.ProviderOptions gcloud
-- @field #MSRS.ProviderOptions win
-- @field #MSRS.ProviderOptions azure
-- @field #MSRS.ProviderOptions aws
-- @field #string DefaultProvider

MSRS.GRPCOptions = {} -- #MSRS.GRPCOptions
MSRS.GRPCOptions.gcloud = {} -- #MSRS.ProviderOptions
MSRS.GRPCOptions.win = {} -- #MSRS.ProviderOptions
MSRS.GRPCOptions.azure = {} -- #MSRS.ProviderOptions
MSRS.GRPCOptions.aws = {} -- #MSRS.ProviderOptions

MSRS.GRPCOptions.win.defaultVoice = "Hedda"
MSRS.GRPCOptions.win.voice = "Hedda"

MSRS.GRPCOptions.DefaultProvider = "win"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add functions to remove freqs and modulations.
-- DONE: Add coordinate.
-- DONE: Add google.
-- DONE: Add gRPC google options
-- DONE: Add loading default config file

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new MSRS object.
-- @param #MSRS self
-- @param #string PathToSRS Path to the directory, where SRS is located.
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz. Can also be given as a #table of multiple frequencies.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators. Can also be given as a #table of multiple modulations.
-- @param #number Volume Volume - 1.0 is max, 0.0 is silence
-- @param #table AltBackend Optional table containing tables 'Functions' and 'Vars' which add/replace functions and variables for the MSRS instance to allow alternate backends for transmitting to SRS.
-- @return #MSRS self
function MSRS:New(PathToSRS, Frequency, Modulation, Volume, AltBackend)

  -- Defaults.
  Frequency = Frequency or 143
  Modulation = Modulation or radio.modulation.AM

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #MSRS

  -- If AltBackend is supplied, initialize it, which will add/replace functions and variables in this MSRS instance.
  if type( AltBackend ) == "table" or type( self.AltBackend ) == "table" then

    local Backend = UTILS.DeepCopy(AltBackend) or UTILS.DeepCopy(self.AltBackend)

    -- Add parameters to vars so alternate backends can use them if applicable
    Backend.Vars            = Backend.Vars or {}
    Backend.Vars.PathToSRS  = PathToSRS
    Backend.Vars.Frequency  = UTILS.DeepCopy(Frequency)
    Backend.Vars.Modulation = UTILS.DeepCopy(Modulation)
    Backend.Vars.Volume     = Volume

    Backend.Functions = Backend.Functions or {} 

    return self:_NewAltBackend(Backend)
  end
  
  if not self.ConfigLoaded then
  
    -- If no AltBackend table, the proceed with default initialisation
    self:SetPath(PathToSRS)
    self:SetPort()
    self:SetFrequencies(Frequency)
    self:SetModulations(Modulation)
    self:SetGender()
    self:SetCoalition()
    self:SetLabel()
    self:SetVolume(Volume)
  
  else
    
    -- there might be some overwrites from :New()
    
    if PathToSRS then
      self:SetPath(PathToSRS)
    end
    
    if Frequency then
      self:SetFrequencies(Frequency)
      self:SetModulations(Modulation)
    end
    
    if Volume then
      self:SetVolume(Volume)
    end
  
  end
  
  self.lid = string.format("%s-%s | ", self.name, self.version)
  
  if not io or not os then
    self:E(self.lid.."***** ERROR - io or os NOT desanitized! MSRS will not work!")
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set path to SRS install directory. More precisely, path to where the DCS-
-- @param #MSRS self
-- @param #string Path Path to the directory, where the sound file is located. This does **not** contain a final backslash or slash.
-- @return #MSRS self
function MSRS:SetPath(Path)

  if Path==nil and not self.path then
    self:E("ERROR: No path to SRS directory specified!")
    return nil
  end
  
  if Path then
    -- Set path.
    self.path=Path
  
    -- Remove (back)slashes.
    local n=1 ; local nmax=1000
    while (self.path:sub(-1)=="/" or self.path:sub(-1)==[[\]]) and n<=nmax do
      self.path=self.path:sub(1,#self.path-1)
      n=n+1
    end
    
    -- Debug output.
    self:T(string.format("SRS path=%s", self:GetPath()))
  end
  return self
end

--- Get path to SRS directory.
-- @param #MSRS self
-- @return #string Path to the directory. This includes the final slash "/".
function MSRS:GetPath()
  return self.path
end

--- Set SRS volume.
-- @param #MSRS self
-- @param #number Volume Volume - 1.0 is max, 0.0 is silence
-- @return #MSRS self
function MSRS:SetVolume(Volume)
  local volume = Volume or 1
  if volume > 1 then volume = 1 elseif volume < 0 then volume = 0 end
  self.volume = volume
  return self
end

--- Get SRS volume.
-- @param #MSRS self 
-- @return #number Volume Volume - 1.0 is max, 0.0 is silence
function MSRS:GetVolume()
  return self.volume
end

--- Set label.
-- @param #MSRS self
-- @param #number Label. Default "ROBOT"
-- @return #MSRS self
function MSRS:SetLabel(Label)
  self.Label=Label or "ROBOT"
  return self
end

--- Get label.
-- @param #MSRS self
-- @return #number Label.
function MSRS:GetLabel()
  return self.Label
end

--- Set port.
-- @param #MSRS self
-- @param #number Port Port. Default 5002.
-- @return #MSRS self
function MSRS:SetPort(Port)
  self.port=Port or 5002
  return self
end

--- Get port.
-- @param #MSRS self
-- @return #number Port.
function MSRS:GetPort()
  return self.port
end

--- Set coalition.
-- @param #MSRS self
-- @param #number Coalition Coalition. Default 0.
-- @return #MSRS self
function MSRS:SetCoalition(Coalition)
  self.coalition=Coalition or 0
  return self
end

--- Get coalition.
-- @param #MSRS self
-- @return #number Coalition.
function MSRS:GetCoalition()
  return self.coalition
end


--- Set frequencies.
-- @param #MSRS self
-- @param #table Frequencies Frequencies in MHz. Can also be given as a #number if only one frequency should be used.
-- @return #MSRS self
function MSRS:SetFrequencies(Frequencies)

  -- Ensure table.
  if type(Frequencies)~="table" then
    Frequencies={Frequencies}
  end
  
  self.frequencies=Frequencies
  
  return self
end

--- Add frequencies.
-- @param #MSRS self
-- @param #table Frequencies Frequencies in MHz. Can also be given as a #number if only one frequency should be used.
-- @return #MSRS self
function MSRS:AddFrequencies(Frequencies)

  -- Ensure table.
  if type(Frequencies)~="table" then
    Frequencies={Frequencies}
  end
  
  for _,_freq in pairs(Frequencies) do
    table.insert(self.frequencies,_freq)
  end
  
  return self
end

--- Get frequencies.
-- @param #MSRS self
-- @param #table Frequencies in MHz.
function MSRS:GetFrequencies()
  return self.frequencies
end


--- Set modulations.
-- @param #MSRS self
-- @param #table Modulations Modulations. Can also be given as a #number if only one modulation should be used.
-- @return #MSRS self
function MSRS:SetModulations(Modulations)

  -- Ensure table.
  if type(Modulations)~="table" then
    Modulations={Modulations}
  end
  
  self.modulations=Modulations
  
  return self
end

--- Add modulations.
-- @param #MSRS self
-- @param #table Modulations Modulations. Can also be given as a #number if only one modulation should be used.
-- @return #MSRS self
function MSRS:AddModulations(Modulations)

  -- Ensure table.
  if type(Modulations)~="table" then
    Modulations={Modulations}
  end
  
   for _,_mod in pairs(Modulations) do
    table.insert(self.modulations,_mod)
   end
  
  return self
end

--- Get modulations.
-- @param #MSRS self
-- @param #table Modulations.
function MSRS:GetModulations()
  return self.modulations
end

--- Set gender.
-- @param #MSRS self
-- @param #string Gender Gender: "male" or "female" (default).
-- @return #MSRS self
function MSRS:SetGender(Gender)
  
  Gender=Gender or "female"
  
  self.gender=Gender:lower()
  
  -- Debug output.
  self:T("Setting gender to "..tostring(self.gender))
  
  return self
end

--- Set culture.
-- @param #MSRS self
-- @param #string Culture Culture, e.g. "en-GB" (default).
-- @return #MSRS self
function MSRS:SetCulture(Culture)

  self.culture=Culture
  
  return self
end

--- Set to use a specific voice. Will override gender and culture settings. 
-- @param #MSRS self
-- @param #string Voice Voice.
-- @return #MSRS self
function MSRS:SetVoice(Voice)

  self.voice=Voice
  
  --local defaultprovider = self.provider or self.GRPCOptions.DefaultProvider or MSRS.GRPCOptions.DefaultProvider or "win"
  
  --self.GRPCOptions[defaultprovider].voice = Voice
  
  return self
end

--- Set to use a specific voice. Will override gender and culture settings. 
-- @param #MSRS self
-- @param #string Voice Voice.
-- @return #MSRS self
function MSRS:SetDefaultVoice(Voice)

  self.defaultVoice=Voice
  local provider = self.provider or self.GRPCOptions.DefaultProvider or MSRS.GRPCOptions.DefaultProvider or "win"
  self.GRPCOptions[provider].defaultVoice = Voice
  
  return self
end

--- Set the coordinate from which the transmissions will be broadcasted.
-- @param #MSRS self
-- @param Core.Point#COORDINATE Coordinate Origin of the transmission.
-- @return #MSRS self
function MSRS:SetCoordinate(Coordinate)

  self.coordinate=Coordinate
  
  return self
end

--- Use google text-to-speech credentials. Also sets Google as default TTS provider.
-- @param #MSRS self
-- @param #string PathToCredentials Full path to the google credentials JSON file, e.g. "C:\Users\username\Downloads\service-account-file.json". Can also be the Google API key.
-- @return #MSRS self
function MSRS:SetGoogle(PathToCredentials)
  
  if PathToCredentials then
  
    self.google=PathToCredentials
    self.APIKey=PathToCredentials
    self.provider = "gcloud"
    
    self.GRPCOptions.DefaultProvider = "gcloud"
    self.GRPCOptions.gcloud.key = PathToCredentials
    self.ttsprovider = "Google"
  
  end
  
  return self
end

--- gRPC Backend: Use google text-to-speech set the API key.
-- @param #MSRS self
-- @param #string APIKey API Key, usually a string of length 40 with characters and numbers.
-- @return #MSRS self
function MSRS:SetGoogleAPIKey(APIKey)
  if APIKey then
    self.APIKey=APIKey
    self.provider = "gcloud"
    self.GRPCOptions.DefaultProvider = "gcloud"
    self.GRPCOptions.gcloud.key = APIKey
  end
  return self
end

--- Use Google text-to-speech as default.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetTTSProviderGoogle()
  self.ttsprovider = "Google"
  return self
end

--- Use Microsoft text-to-speech as default.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetTTSProviderMicrosoft()
  self.ttsprovider = "Microsoft"
  return self
end

--- Print SRS STTS help to DCS log file.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:Help()

  -- Path and exe.
  local path=self:GetPath() or STTS.DIRECTORY    
  local exe=STTS.EXECUTABLE or "DCS-SR-ExternalAudio.exe"
  
  -- Text file for output.
  local filename = os.getenv('TMP') .. "\\MSRS-help-"..STTS.uuid()..".txt"
    
  -- Print help.
  local command=string.format("%s/%s --help > %s", path, exe, filename)  
  os.execute(command)
  
  local f=assert(io.open(filename, "rb"))
  local data=f:read("*all")
  f:close()
  
  -- Print to log file.
  env.info("SRS STTS help output:")
  env.info("======================================================================")
  env.info(data)
  env.info("======================================================================")
  
  return self
end

--- Sets an alternate SRS backend to be used by MSRS to transmit over SRS for all new MSRS class instances.
-- @param #table Backend A table containing a table `Functions` with new/replacement class functions and `Vars` with new/replacement variables. 
-- @return #boolean Returns 'true' on success.
function MSRS.SetDefaultBackend(Backend)
  if type(Backend) == "table" then
    MSRS.AltBackend = UTILS.DeepCopy(Backend)
  else
    return false
  end
  
  return true
end

--- Restores default SRS backend (DCS-SR-ExternalAudio.exe) to be used by all new MSRS class instances to transmit over SRS.
-- @return #boolean Returns 'true' on success.
function MSRS.ResetDefaultBackend()
  MSRS.AltBackend = nil
  return true
end

--- Sets DCS-gRPC as the default SRS backend for all new MSRS class instances.
-- @return #boolean Returns 'true' on success.
function MSRS.SetDefaultBackendGRPC()
  return MSRS.SetDefaultBackend(MSRS_BACKEND_DCSGRPC)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Transmission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Play sound file (ogg or mp3) via SRS.
-- @param #MSRS self
-- @param Sound.SoundOutput#SOUNDFILE Soundfile Sound file to play.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
function MSRS:PlaySoundFile(Soundfile, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundFile, self, Soundfile, 0)
  else

    -- Sound file name.
    local soundfile=Soundfile:GetName()

    -- Get command.
    local command=self:_GetCommand()
    
    -- Append file.
    command=command..' --file="'..tostring(soundfile)..'"'
    
    -- Execute command.
    self:_ExecCommand(command)
        
  end

  return self
end

--- Play a SOUNDTEXT text-to-speech object.
-- @param #MSRS self
-- @param Sound.SoundOutput#SOUNDTEXT SoundText Sound text.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
function MSRS:PlaySoundText(SoundText, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundText, self, SoundText, 0)
  else

    -- Get command.
    local command=self:_GetCommand(nil, nil, nil, SoundText.gender, SoundText.voice, SoundText.culture, SoundText.volume, SoundText.speed)
    
    -- Append text.
    command=command..string.format(" --text=\"%s\"", tostring(SoundText.text))
    
    -- Execute command.
    self:_ExecCommand(command)
        
  end

  return self
end

--- Play text message via STTS.
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @return #MSRS self
function MSRS:PlayText(Text, Delay, Coordinate)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayText, self, Text, nil, Coordinate)
  else

    -- Get command line.
    local command=self:_GetCommand(nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,Coordinate)    

    -- Append text.
    command=command..string.format(" --text=\"%s\"", tostring(Text))
    
    -- Execute command.
    self:_ExecCommand(command)
    
  end
  
  return self
end

--- Play text message via STTS with explicitly specified options.
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @param #table Frequencies Radio frequencies.
-- @param #table Modulations Radio modulations.
-- @param #string Gender Gender.
-- @param #string Culture Culture.
-- @param #string Voice Voice.
-- @param #number Volume Volume.
-- @param #string Label Label.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @return #MSRS self
function MSRS:PlayTextExt(Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayTextExt, self, Text, 0, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
  else
  
    -- Ensure table.
    if Frequencies and type(Frequencies)~="table" then
      Frequencies={Frequencies}
    end

    -- Ensure table.
    if Modulations and type(Modulations)~="table" then
      Modulations={Modulations}
    end

    -- Get command line.
    local command=self:_GetCommand(Frequencies, Modulations, nil, Gender, Voice, Culture, Volume, nil, nil, Label, Coordinate)    

    -- Append text.
    command=command..string.format(" --text=\"%s\"", tostring(Text))
    
    -- Execute command.
    self:_ExecCommand(command)
    
  end
  
  return self
end


--- Play text file via STTS.
-- @param #MSRS self
-- @param #string TextFile Full path to the file.
-- @param #number Delay Delay in seconds, before the message is played.
-- @return #MSRS self
function MSRS:PlayTextFile(TextFile, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayTextFile, self, TextFile, 0)
  else
  
    -- First check if text file exists!
    local exists=UTILS.FileExists(TextFile)    
    if not exists then
      self:E("ERROR: MSRS Text file does not exist! File="..tostring(TextFile))
      return self
    end

    -- Get command line.    
    local command=self:_GetCommand()

    -- Append text file.
    command=command..string.format(" --textFile=\"%s\"", tostring(TextFile))
    
    -- Debug output.
    self:T(string.format("MSRS TextFile command=%s", command))
    
    -- Count length of command.
    local l=string.len(command)

    -- Execute command.
    self:_ExecCommand(command)
        
  end
  
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Adds or replaces functions and variables in the current MSRS class instance to enable an alternate backends for transmitting to SRS.
-- @param #MSRS self
-- @param #table A table containing a table `Functions` with new/replacement class functions and `Vars` with new/replacement variables. 
-- @return #MSRS self
function MSRS:_NewAltBackend(Backend)
  BASE:T('Entering MSRS:_NewAltBackend()')

  -- Add/replace class instance functions with those defined in the alternate backend in Functions table
  for funcName,funcDef in pairs(Backend.Functions) do
    if type(funcDef) == 'function' then
      BASE:T('MSRS (re-)defining function MSRS:' .. funcName )
      self[funcName] = funcDef
    end
  end

  -- Add/replace class instance variables with those defined in the alternate backend in Vars table
  for varName,varVal in pairs(Backend.Vars) do
      BASE:T('MSRS setting self.' .. varName)
      self[varName] = UTILS.DeepCopy(varVal)
  end
  
  -- If _MSRSbackendInit() is defined in the backend, then run it (it should return self)
  if self._MSRSbackendInit and type(self._MSRSbackendInit) == 'function' then
    return self:_MSRSbackendInit()
  end

  return self
end

--- Execute SRS command to play sound using the `DCS-SR-ExternalAudio.exe`.
-- @param #MSRS self
-- @param #string command Command to executer
-- @return #number Return value of os.execute() command.
function MSRS:_ExecCommand(command)

    -- Create a tmp file.
    local filename=os.getenv('TMP').."\\MSRS-"..STTS.uuid()..".bat"
    
    local script=io.open(filename, "w+")
    script:write(command.." && exit")
    script:close()
      
    -- Play command.  
    command=string.format('start /b "" "%s"', filename)
    
    local res=nil
    if true then
    
      -- Create a tmp file.
      local filenvbs = os.getenv('TMP') .. "\\MSRS-"..STTS.uuid()..".vbs"
      
      -- VBS script
      local script = io.open(filenvbs, "w+")
      script:write(string.format('Dim WinScriptHost\n'))
      script:write(string.format('Set WinScriptHost = CreateObject("WScript.Shell")\n'))
      script:write(string.format('WinScriptHost.Run Chr(34) & "%s" & Chr(34), 0\n', filename))
      script:write(string.format('Set WinScriptHost = Nothing'))
      script:close()

      -- Run visual basic script. This still pops up a window but very briefly and does not put the DCS window out of focus.      
      local runvbs=string.format('cscript.exe //Nologo //B "%s"', filenvbs)
      
      -- Debug output.
      self:T("MSRS execute command="..command)
      self:T("MSRS execute VBS command="..runvbs)
            
      -- Play file in 0.01 seconds
      res=os.execute(runvbs)      
      
      -- Remove file in 1 second.
      timer.scheduleFunction(os.remove, filename, timer.getTime()+1)
      timer.scheduleFunction(os.remove, filenvbs, timer.getTime()+1)

    elseif false then

      -- Create a tmp file.
      local filenvbs = os.getenv('TMP') .. "\\MSRS-"..STTS.uuid()..".vbs"
      
      -- VBS script
      local script = io.open(filenvbs, "w+")
      script:write(string.format('Set oShell = CreateObject ("Wscript.Shell")\n'))
      script:write(string.format('Dim strArgs\n'))
      script:write(string.format('strArgs = "cmd /c %s"\n', filename))
      script:write(string.format('oShell.Run strArgs, 0, false'))
      script:close()      
      
      local runvbs=string.format('cscript.exe //Nologo //B "%s"', filenvbs)

      -- Play file in 0.01 seconds
      res=os.execute(runvbs)
      
    else

      -- Debug output.
      self:T("MSRS execute command="..command)    
            
      -- Execute command
      res=os.execute(command)
      
      -- Remove file in 1 second.
      timer.scheduleFunction(os.remove, filename, timer.getTime()+1)  
    
    end
    

  return res
end

--- Get lat, long and alt from coordinate.
-- @param #MSRS self
-- @param Core.Point#Coordinate Coordinate Coordinate. Can also be a DCS#Vec3.
-- @return #number Latitude.
-- @return #number Longitude.
-- @return #number Altitude.
function MSRS:_GetLatLongAlt(Coordinate)
  
  local lat, lon, alt=coord.LOtoLL(Coordinate)
  
  return lat, lon, math.floor(alt)
end


--- Get SRS command to play sound using the `DCS-SR-ExternalAudio.exe`.
-- @param #MSRS self
-- @param #table freqs Frequencies in MHz.
-- @param #table modus Modulations.
-- @param #number coal Coalition.
-- @param #string gender Gender.
-- @param #string voice Voice.
-- @param #string culture Culture.
-- @param #number volume Volume.
-- @param #number speed Speed.
-- @param #number port Port.
-- @param #string label Label, defaults to "ROBOT" (displayed sender name in the radio overlay of SRS) - No spaces allowed!
-- @param Core.Point#COORDINATE coordinate Coordinate.
-- @return #string Command.
function MSRS:_GetCommand(freqs, modus, coal, gender, voice, culture, volume, speed, port,label,coordinate)

  local path=self:GetPath() or STTS.DIRECTORY    
  local exe=STTS.EXECUTABLE or "DCS-SR-ExternalAudio.exe"
  freqs=table.concat(freqs or self.frequencies, ",")
  modus=table.concat(modus or self.modulations, ",")
  coal=coal or self.coalition
  gender=gender or self.gender
  voice=voice or self.voice
  culture=culture or self.culture
  volume=volume or self.volume
  speed=speed or self.speed
  port=port or self.port
  label=label or self.Label
  coordinate=coordinate or self.coordinate
  
  -- Replace modulation
  modus=modus:gsub("0", "AM")
  modus=modus:gsub("1", "FM")
  
  -- Command.
  local command=string.format('"%s\\%s" -f "%s" -m "%s" -c %s -p %s -n "%s" -v "%.1f"', path, exe, freqs, modus, coal, port, label,volume)

  -- Set voice or gender/culture.
  if voice then
    -- Use a specific voice (no need for gender and/or culture.
    command=command..string.format(" --voice=\"%s\"", tostring(voice))
  else
    -- Add gender.
    if gender and gender~="female" then
      command=command..string.format(" -g %s", tostring(gender))
    end
    -- Add culture.
    if culture and culture~="en-GB" then
      command=command..string.format(" -l %s", tostring(culture))
    end
  end
  
  -- Set coordinate.
  if coordinate then
    local lat,lon,alt=self:_GetLatLongAlt(coordinate)
    command=command..string.format(" -L %.4f -O %.4f -A %d", lat, lon, alt)
  end
  
  -- Set google.
  if self.google and self.ttsprovider == "Google" then
    command=command..string.format(' --ssml -G "%s"', self.google)
  end
  
  -- Debug output.
  self:T("MSRS command="..command)

  return command
end

--- Get central SRS configuration to be able to play tts over SRS radio using the `DCS-SR-ExternalAudio.exe`.
-- @param #MSRS self
-- @param #string Path Path to config file, defaults to "C:\Users\<yourname>\Saved Games\DCS\Config"
-- @param #string Filename File to load, defaults to "Moose_MSRS.lua"
-- @return #boolean success
-- @usage
--  0) Benefits: Centralize configuration of SRS, keep paths and keys out of the mission source code, making it safer and easier to move missions to/between servers,
--  and also make config easier to use in the code.
--  1) Create a config file named "Moose_MSRS.lua" at this location "C:\Users\<yourname>\Saved Games\DCS\Config" (or wherever your Saved Games folder resides).
--  2) The file needs the following structure:
--
--          -- Moose MSRS default Config
--          MSRS_Config = {
--            Path = "C:\\Program Files\\DCS-SimpleRadio-Standalone", -- adjust as needed, note double  \\
--            Port = 5002, -- adjust as needed
--            Frequency = {127,243}, -- must be a table, 1..n entries!
--            Modulation = {0,0}, -- must be a table, 1..n entries, one for each frequency!
--            Volume = 1.0, -- 0.0 to 1.0
--            Coalition = 0,  -- 0 = Neutral, 1 = Red, 2 = Blue
--            Coordinate = {0,0,0}, -- x,y,altitude - optional, all in meters
--            Culture = "en-GB",
--            Gender = "male",
--            Google = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourfilename.json", -- path to google json key file - optional.
--            Label = "MSRS",
--            Voice = "Microsoft Hazel Desktop",
--            Provider = "Microsoft", -- this is the default TTS provider, e.g. "Google" or "Microsoft"
--            -- gRPC (optional)
--            GRPC = { -- see https://github.com/DCS-gRPC/rust-server
--              coalition = "blue", -- blue, red, neutral
--              DefaultProvider = "gcloud", -- win, gcloud, aws, or azure, some of the values below depend on your cloud provider
--              gcloud = {
--                key = "<API Google Key>", -- for gRPC Google API key
--                --secret = "", -- needed for aws
--                --region = "",-- needed for aws
--                defaultVoice = MSRS.Voices.Google.Standard.en_GB_Standard_F,
--              },
--              win = {
--                defaultVoice = "Hazel",
--              },
--            }
--          }
--  
--  3) The config file is automatically loaded when Moose starts. YOu can also load the config into the MSRS raw class manually before you do anything else:
--  
--         MSRS.LoadConfigFile() -- Note the "." here
-- 
--  Optionally, your might want to provide a specific path and filename:
--  
--         MSRS.LoadConfigFile(nil,MyPath,MyFilename) -- Note the "." here
--         
--  This will populate variables for the MSRS raw class and all instances you create with e.g. `mysrs = MSRS:New()`
--  Optionally you can also load this per **single instance** if so needed, i.e.
--    
--         mysrs:LoadConfigFile(Path,Filename)
--         
--  4) Use the config in your code like so, variable names are basically the same as in the config file, but all lower case, examples:
--  
--         -- Needed once only
--         MESSAGE.SetMSRS(MSRS.path,nil,MSRS.google,243,radio.modulation.AM,nil,nil,
--         MSRS.Voices.Google.Standard.de_DE_Standard_B,coalition.side.BLUE)
--
--         -- later on in your code
--
--         MESSAGE:New("Test message!",15,"SPAWN"):ToSRS(243,radio.modulation.AM,nil,nil,MSRS.Voices.Google.Standard.fr_FR_Standard_C)
--        
--          -- Create new ATIS as usual
--          atis=ATIS:New(AIRBASE.Caucasus.Batumi, 123, radio.modulation.AM)
--          atis:SetSRS(nil,nil,nil,MSRS.Voices.Google.Standard.en_US_Standard_H)
--          --Start ATIS
--          atis:Start()
function MSRS:LoadConfigFile(Path,Filename)

  if lfs == nil then
        env.info("*****Note - lfs and os need to be desanitized for MSRS to work!")
        return false
  end
  local path = Path or lfs.writedir()..MSRS.ConfigFilePath 
  local file = Filename or MSRS.ConfigFileName or "Moose_MSRS.lua"
  local pathandfile = path..file
  local filexsists =  UTILS.FileExists(pathandfile)
  
  if filexsists and not MSRS.ConfigLoaded then
    assert(loadfile(path..file))()
    -- now we should have a global var MSRS_Config
    if MSRS_Config then
      if self then
        self.path = MSRS_Config.Path or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
        self.port = MSRS_Config.Port or 5002
        self.frequencies = MSRS_Config.Frequency or {127,243}
        self.modulations = MSRS_Config.Modulation or {0,0}
        self.coalition = MSRS_Config.Coalition or 0
        if MSRS_Config.Coordinate then
          self.coordinate = COORDINATE:New( MSRS_Config.Coordinate[1],MSRS_Config.Coordinate[2],MSRS_Config.Coordinate[3])
        end
        self.culture = MSRS_Config.Culture or "en-GB"
        self.gender = MSRS_Config.Gender or "male"
        self.google = MSRS_Config.Google
        if MSRS_Config.Provider then
          self.ttsprovider = MSRS_Config.Provider
        end
        self.Label = MSRS_Config.Label or "MSRS"
        self.voice = MSRS_Config.Voice --or MSRS.Voices.Microsoft.Hazel
        if MSRS_Config.GRPC then
           self.provider = MSRS_Config.GRPC.DefaultProvider
           if MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider] then
              self.APIKey = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].key
              self.defaultVoice = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].defaultVoice
              self.region = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].secret
              self.secret = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].region
           end
        end
        self.ConfigLoaded = true
      else
        MSRS.path = MSRS_Config.Path or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
        MSRS.port = MSRS_Config.Port or 5002
        MSRS.frequencies = MSRS_Config.Frequency or {127,243}
        MSRS.modulations = MSRS_Config.Modulation or {0,0}
        MSRS.coalition = MSRS_Config.Coalition or 0
        if MSRS_Config.Coordinate then
          MSRS.coordinate = COORDINATE:New( MSRS_Config.Coordinate[1],MSRS_Config.Coordinate[2],MSRS_Config.Coordinate[3])
        end
        MSRS.culture = MSRS_Config.Culture or "en-GB"
        MSRS.gender = MSRS_Config.Gender or "male"
        MSRS.google = MSRS_Config.Google
        if MSRS_Config.Provider then
          MSRS.ttsprovider = MSRS_Config.Provider
        end
        MSRS.Label = MSRS_Config.Label or "MSRS"
        MSRS.voice = MSRS_Config.Voice --or MSRS.Voices.Microsoft.Hazel
        if MSRS_Config.GRPC then
           MSRS.provider = MSRS_Config.GRPC.DefaultProvider
           if MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider] then
              MSRS.APIKey = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].key
              MSRS.defaultVoice = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].defaultVoice
              MSRS.region = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].secret
              MSRS.secret = MSRS_Config.GRPC[MSRS_Config.GRPC.DefaultProvider].region
           end
        end
        MSRS.ConfigLoaded = true
      end
    end
    env.info("MSRS - Successfully loaded default configuration from disk!",false)
  end
  if not filexsists then
    env.info("MSRS - Cannot find default configuration file!",false)
    return false
  end
  
  return true
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MSRS DCS-gRPC alternate backend
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Alternate backend for MSRS to enable text-to-speech via DCS-gRPC.
-- ### Author: **dogjutsu**
-- A table containing functions and variables for MSRS to use DCS-gRPC [DCS-gRPC](https://github.com/DCS-gRPC/rust-server) 0.7.0 or newer as a backend to transmit over SRS.
-- This is not a standalone class. Instead, variables and functions under the `Vars` and `Functions` tables get added to or replace MSRS variables/functions when activated.
-- 
-- @type MSRS_BACKEND_DCSGRPC 
-- @field #number version Version number of this alternate backend.
-- @field #table Functions A table of functions that will add or replace the default MSRS class functions.
-- @field #table Vars A table of variables that will add or replace the default MSRS class variables.
MSRS_BACKEND_DCSGRPC = {}
MSRS_BACKEND_DCSGRPC.version = 0.1

MSRS_BACKEND_DCSGRPC.Functions = {}
MSRS_BACKEND_DCSGRPC.Vars = { provider = 'win' }

--- Called by @{#MSRS._NewAltBackend} (if present) immediately after an alternate backend functions and variables for MSRS are added/replaced.
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions._MSRSbackendInit = function (self)
  BASE:I('Loaded MSRS DCS-gRPC alternate backend version ' .. self.AltBackend.version or 'unspecified')

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MSRS DCS-gRPC alternate backend User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- No-op replacement function for @{#MSRS.SetPath} (Not Applicable)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetPath = function (self)
  return self
end

--- No-op replacement function for @{#MSRS.GetPath} (Not Applicable)
-- @param #MSRS self
-- @return #string Empty string
MSRS_BACKEND_DCSGRPC.Functions.GetPath = function (self)
  return ''
end

--- No-op replacement function for @{#MSRS.SetVolume} (Not Applicable)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetVolume = function (self)
  BASE:I('NOTE: MSRS:SetVolume() not used with DCS-gRPC backend.')
  return self
end

--- No-op replacement function for @{#MSRS.GetVolume} (Not Applicable)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.GetVolume = function (self)
  BASE:I('NOTE: MSRS:GetVolume() not used with DCS-gRPC backend.')
  return 1
end

--- No-op replacement function for @{#MSRS.SetGender} (Not Applicable)
-- @param #MSRS self
-- #string Gender Gender: "male" or "female"
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetGender = function (self, Gender)
  -- Use DCS-gRPC default if not specified

  if Gender then
    self.gender=Gender:lower()
  end
  
  -- Debug output.
  self:T("Setting gender to "..tostring(self.gender))
  return self
end

--- Replacement function for @{#MSRS.SetGoogle} to use google text-to-speech.  (API key set as part of DCS-gRPC configuration)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetGoogle = function (self)
    self.provider = 'gcloud'
    return self
end

--- MSRS:SetAWS() Use AWS text-to-speech. (API key set as part of DCS-gRPC configuration)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetAWS = function (self)
    self.provider = 'aws'
    return self
end

--- MSRS:SetAzure() Use Azure text-to-speech. (API key set as part of DCS-gRPC configuration)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetAzure = function (self)
    self.provider = 'azure'
    return self
end

--- MSRS:SetWin() Use local Windows OS text-to-speech (Windows Server 2019 / Windows 11 / Windows 10? or newer). (Default)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.SetWin = function (self)
    self.provider = 'win'
    return self
end

--- Replacement function for @{#MSRS.Help} to display help.
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.Help = function (self)
    env.info('For DCS-gRPC help, please see: https://github.com/DCS-gRPC/rust-server')
    return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MSRS DCS-gRPC alternate backend Transmission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- No-op replacement function for @{#MSRS.PlaySoundFile} (Not Applicable)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.PlaySoundFile = function (self)
    BASE:E("ERROR: MSRS:PlaySoundFile() is not supported by the DCS-gRPC backend.")
    return self
end

--- Replacement function for @{#MSRS.PlaySoundText} 
-- @param #MSRS self
-- @param Sound.SoundOutput#SOUNDTEXT SoundText Sound text.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.PlaySoundText = function (self, SoundText, Delay)

    if Delay and Delay>0 then
        self:ScheduleOnce(Delay, self.PlaySoundText, self, SoundText, 0)
    else
        self:_DCSgRPCtts(tostring(SoundText.text))
    end
    
    return self
end

--- Replacement function for @{#MSRS.PlayText} 
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.PlayText = function (self, Text, Delay)

    if Delay and Delay>0 then
        self:ScheduleOnce(Delay, self.PlayText, self, Text, 0)
    else
        self:_DCSgRPCtts(tostring(Text))
    end
    
    return self
end

--- Replacement function for @{#MSRS.PlayText} 
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @param #table Frequencies Radio frequencies.
-- @param #table Modulations Radio modulations. (Non-functional, DCS-gRPC sets automatically)
-- @param #string Gender Gender. (Non-functional, only 'Voice' supported)
-- @param #string Culture Culture. (Non-functional, only 'Voice' supported)
-- @param #string Voice Voice. 
-- @param #number Volume Volume. (Non-functional, all transmissions full volume with DCS-gRPC)
-- @param #string Label Label.
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.PlayTextExt = function (self, Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label)
  if Delay and Delay>0 then
      self:ScheduleOnce(Delay, self.PlayTextExt, self, Text, 0, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label)
  else
      self:_DCSgRPCtts(tostring(Text), nil, Frequencies, Voice, Label)
  end
  
  return self
end

--- No-op replacement function for @{#MSRS.PlayTextFile} (Not Applicable)
-- @param #MSRS self
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions.PlayTextFile = function (self, TextFile, Delay)
  BASE:E("ERROR: MSRS:PlayTextFile() is not supported by the DCS-gRPC backend.")
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MSRS DCS-gRPC alternate backend Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DCS-gRPC v0.70 TTS API call:
-- GRPC.tts(ssml, frequency[, options]) - Synthesize text (ssml; SSML tags supported) to speech and transmit it over SRS on the frequency with the following optional options (and their defaults):

-- {
--     -- The plain text without any transformations made to it for the purpose of getting it spoken out
--     -- as desired (no SSML tags, no FOUR NINER instead of 49, ...). Even though this field is
--     -- optional, please consider providing it as it can be used to display the spoken text to players
--     -- with hearing impairments.
--     plaintext = null, -- e.g. `= "Hello Pilot"`

--     -- Name of the SRS client.
--     srsClientName = "DCS-gRPC",

--     -- The origin of the transmission. Relevant if the SRS server has "Line of
--     -- Sight" and/or "Distance Limit" enabled.
--     position = {
--         lat = 0.0,
--         lon = 0.0,
--         alt = 0.0, -- in meters
--     },

--     -- The coalition of the transmission. Relevant if the SRS server has "Secure
--     -- Coalition Radios" enabled. Supported values are: `blue` and `red`. Defaults
--     -- to being spectator if not specified.
--     coalition = null,

--     -- TTS provider to be use. Defaults to the one configured in your config or to Windows'
--     -- built-in TTS. Examples:
--     -- `= { aws = {} }` / `= { aws = { voice = "..." } }` enable AWS TTS
--     -- `= { azure = {} }` / `= { azure = { voice = "..." } }` enable Azure TTS
--     -- `= { gcloud = {} }` / `= { gcloud = { voice = "..." } }` enable Google Cloud TTS
--     -- `= { win = {} }` / `= { win = { voice = "..." } }` enable Windows TTS
--     provider = null,
-- }

--- Make DCS-gRPC API call to transmit text-to-speech over SRS.
-- @param #MSRS self
-- @param #string Text Text of message to transmit (can also be SSML).
-- @param #string Optional plaintext version of message (for accessiblity)
-- @param #table Frequencies Radio frequencies to transmit on. Can also accept a number in MHz.
-- @param #string Voice Voice for the TTS provider to user. 
-- @param #string Label Label (SRS diplays as name of the transmitter).
-- @return #MSRS self
MSRS_BACKEND_DCSGRPC.Functions._DCSgRPCtts = function (self, Text, Plaintext, Frequencies, Voice, Label)

    BASE:T("MSRS_BACKEND_DCSGRPC:_DCSgRPCtts()")
    BASE:T({Text, Plaintext, Frequencies, Voice, Label})

    local options = self.ProviderOptions or MSRS.ProviderOptions or {} -- #MSRS.GRPCOptions
    local ssml = Text or ''

    local XmitFrequencies = Frequencies or self.Frequency
    if type(XmitFrequencies)~="table" then
        XmitFrequencies={XmitFrequencies}
    end

    options.plaintext = Plaintext
    options.srsClientName = Label or self.Label
    options.position = {}
    if self.coordinate then
        options.position.lat, options.position.lon, options.position.alt = self:_GetLatLongAlt(self.coordinate)
    end

    options.position.lat = options.position.lat or 0.0
    options.position.lon = options.position.lon or 0.0
    options.position.alt = options.position.alt or 0.0

    if UTILS.GetCoalitionName(self.coalition) == 'Blue' then
      options.coalition = 'blue'
    elseif UTILS.GetCoalitionName(self.coalition) == 'Red' then
      options.coalition = 'red'
    end
    
    local provider = self.provider or self.GRPCOptions.DefaultProvider or MSRS.GRPCOptions.DefaultProvider
    
    options.provider = {}
    
    options.provider[provider] = {}
    
    if self.APIKey then
      options.provider[provider].key = self.APIKey
    end
    
    if self.defaultVoice then
      options.provider[provider].defaultVoice = self.defaultVoice
    end
    
    if self.voice then
      options.provider[provider].voice = Voice or self.voice or self.defaultVoice
    elseif ssml then
      -- DCS-gRPC doesn't directly support language/gender, but can use SSML
      -- Only use if a voice isn't explicitly set
      local preTag, genderProp, langProp, postTag = '', '', '', ''

      if self.gender then
        genderProp = ' gender=\"' .. self.gender .. '\"'
      end
      if self.culture then
        langProp = ' language=\"' .. self.culture .. '\"'
      end

      if self.culture or self.gender then
        preTag = '<voice' .. langProp .. genderProp  .. '>'
        postTag = '</voice>'
        ssml = preTag .. Text .. postTag
      end

    end

    for _,_freq in ipairs(XmitFrequencies) do
        local freq = _freq*1000000
        BASE:T("GRPC.tts")
        BASE:T(ssml)
        BASE:T(freq)
        BASE:T({options})
        GRPC.tts(ssml, freq, options)
    end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Manages radio transmissions.
-- 
-- The purpose of the MSRSQUEUE class is to manage SRS text-to-speech (TTS) messages using the MSRS class.
-- This can be used to submit multiple TTS messages and the class takes care that they are transmitted one after the other (and not overlapping).
-- 
-- @type MSRSQUEUE
-- @field #string ClassName Name of the class "MSRSQUEUE".
-- @field #string lid ID for dcs.log.
-- @field #table queue The queue of transmissions.
-- @field #string alias Name of the radio queue.
-- @field #number dt Time interval in seconds for checking the radio queue. 
-- @field #number Tlast Time (abs) when the last transmission finished.
-- @field #boolean checking If `true`, the queue update function is scheduled to be called again.
-- @extends Core.Base#BASE
MSRSQUEUE = {
  ClassName   = "MSRSQUEUE",
  Debugmode   = nil,
  lid         = nil,
  queue       =  {},
  alias       = nil,
  dt          = nil,
  Tlast       = nil,
  checking    = nil,
}

--- Radio queue transmission data.
-- @type MSRSQUEUE.Transmission
-- @field #string text Text to be transmitted.
-- @field Sound.SRS#MSRS msrs MOOSE SRS object.
-- @field #number duration Duration in seconds.
-- @field #table subgroups Groups to send subtitle to.
-- @field #string subtitle Subtitle of the transmission.
-- @field #number subduration Duration of the subtitle being displayed.
-- @field #number frequency Frequency.
-- @field #number modulation Modulation.
-- @field #number Tstarted Mission time (abs) in seconds when the transmission started.
-- @field #boolean isplaying If true, transmission is currently playing.
-- @field #number Tplay Mission time (abs) in seconds when the transmission should be played.
-- @field #number interval Interval in seconds before next transmission.
-- @field #boolean TransmitOnlyWithPlayers If true, only transmit if there are alive Players.
-- @field Core.Set#SET_CLIENT PlayerSet PlayerSet created when TransmitOnlyWithPlayers == true
-- @field #string gender Voice gender
-- @field #string culture Voice culture
-- @field #string voice Voice if any
-- @field #number volume Volume
-- @field #string label Label to be used
-- @field Core.Point#COORDINATE coordinate Coordinate for this transmission

--- Create a new MSRSQUEUE object for a given radio frequency/modulation.
-- @param #MSRSQUEUE self
-- @param #string alias (Optional) Name of the radio queue.
-- @return #MSRSQUEUE self The MSRSQUEUE object.
function MSRSQUEUE:New(alias)

  -- Inherit base
  local self=BASE:Inherit(self, BASE:New()) --#MSRSQUEUE
  
  self.alias=alias or "My Radio"
  
  self.dt=1.0
  
  self.lid=string.format("MSRSQUEUE %s | ", self.alias)
  
  return self
end

--- Clear the radio queue.
-- @param #MSRSQUEUE self
-- @return #MSRSQUEUE self The MSRSQUEUE object.
function MSRSQUEUE:Clear()
  self:I(self.lid.."Clearing MSRSQUEUE")
  self.queue={}
  return self
end


--- Add a transmission to the radio queue.
-- @param #MSRSQUEUE self
-- @param #MSRSQUEUE.Transmission transmission The transmission data table. 
-- @return #MSRSQUEUE self
function MSRSQUEUE:AddTransmission(transmission)
  
  -- Init.
  transmission.isplaying=false
  transmission.Tstarted=nil

  -- Add to queue.
  table.insert(self.queue, transmission)
  
  -- Start checking.
  if not self.checking then
    self:_CheckRadioQueue()
  end

  return self
end

--- Switch to only transmit if there are players on the server.
-- @param #MSRSQUEUE self
-- @param #boolean Switch If true, only send SRS if there are alive Players.
-- @return #MSRSQUEUE self
function MSRSQUEUE:SetTransmitOnlyWithPlayers(Switch)
  self.TransmitOnlyWithPlayers = Switch
  if Switch == false or Switch==nil then
    if self.PlayerSet then
      self.PlayerSet:FilterStop()
    end
    self.PlayerSet = nil
  else
    self.PlayerSet = SET_CLIENT:New():FilterStart()
  end
  return self
end

--- Create a new transmission and add it to the radio queue.
-- @param #MSRSQUEUE self
-- @param #string text Text to play.
-- @param #number duration Duration in seconds the file lasts. Default is determined by number of characters of the text message.
-- @param Sound.SRS#MSRS msrs MOOSE SRS object.
-- @param #number tstart Start time (abs) seconds. Default now.
-- @param #number interval Interval in seconds after the last transmission finished.
-- @param #table subgroups Groups that should receive the subtiltle.
-- @param #string subtitle Subtitle displayed when the message is played.
-- @param #number subduration Duration [sec] of the subtitle being displayed. Default 5 sec.
-- @param #number frequency Radio frequency if other than MSRS default.
-- @param #number modulation Radio modulation if other then MSRS default.
-- @param #string gender Gender of the voice
-- @param #string culture Culture of the voice
-- @param #string voice Specific voice
-- @param #number volume Volume setting
-- @param #string label Label to be used
-- @param Core.Point#COORDINATE coordinate Coordinate to be used
-- @return #MSRSQUEUE.Transmission Radio transmission table.
function MSRSQUEUE:NewTransmission(text, duration, msrs, tstart, interval, subgroups, subtitle, subduration, frequency, modulation, gender, culture, voice, volume, label,coordinate)
  
  if self.TransmitOnlyWithPlayers then
    if self.PlayerSet and self.PlayerSet:CountAlive() == 0 then
      return self
    end
  end
  
  -- Sanity checks.
  if not text then
    self:E(self.lid.."ERROR: No text specified.")
    return nil
  end
  if type(text)~="string" then
    self:E(self.lid.."ERROR: Text specified is NOT a string.")
    return nil    
  end

  
  -- Create a new transmission object.
  local transmission={} --#MSRSQUEUE.Transmission
  transmission.text=text
  transmission.duration=duration or STTS.getSpeechTime(text)
  transmission.msrs=msrs
  transmission.Tplay=tstart or timer.getAbsTime()
  transmission.subtitle=subtitle
  transmission.interval=interval or 0
  transmission.frequency=frequency
  transmission.modulation=modulation
  transmission.subgroups=subgroups
  if transmission.subtitle then
    transmission.subduration=subduration or transmission.duration
  else
    transmission.subduration=0 --nil
  end
  transmission.gender = gender
  transmission.culture = culture
  transmission.voice = voice
  transmission.volume = volume
  transmission.label = label
  transmission.coordinate = coordinate
    
  -- Add transmission to queue.  
  self:AddTransmission(transmission)
  
  return transmission
end

--- Broadcast radio message.
-- @param #MSRSQUEUE self
-- @param #MSRSQUEUE.Transmission transmission The transmission.
function MSRSQUEUE:Broadcast(transmission)

  if transmission.frequency then
    transmission.msrs:PlayTextExt(transmission.text, nil, transmission.frequency, transmission.modulation, transmission.gender, transmission.culture, transmission.voice, transmission.volume, transmission.label, transmission.coordinate)
  else
    transmission.msrs:PlayText(transmission.text,nil,transmission.coordinate)
  end
  
  local function texttogroup(gid)
    -- Text to group.
    trigger.action.outTextForGroup(gid, transmission.subtitle, transmission.subduration, true)  
  end
  
  if transmission.subgroups and #transmission.subgroups>0 then
    
    for _,_group in pairs(transmission.subgroups) do
      local group=_group --Wrapper.Group#GROUP
      
      if group and group:IsAlive() then
        local gid=group:GetID()
        
        self:ScheduleOnce(4, texttogroup, gid) 
      end
      
    end
    
  end
  
end

--- Calculate total transmission duration of all transmission in the queue.
-- @param #MSRSQUEUE self
-- @return #number Total transmission duration.
function MSRSQUEUE:CalcTransmisstionDuration()

  local Tnow=timer.getAbsTime()

  local T=0
  for _,_transmission in pairs(self.queue) do
    local transmission=_transmission --#MSRSQUEUE.Transmission
    
    if transmission.isplaying then
    
      -- Playing for dt seconds.
      local dt=Tnow-transmission.Tstarted
      
      T=T+transmission.duration-dt
    
    else
      T=T+transmission.duration
    end
  
  end

  return T
end

--- Check radio queue for transmissions to be broadcasted.
-- @param #MSRSQUEUE self
-- @param #number delay Delay in seconds before checking.
function MSRSQUEUE:_CheckRadioQueue(delay)

  -- Transmissions in queue.  
  local N=#self.queue

  -- Debug info.
  self:T2(self.lid..string.format("Check radio queue %s: delay=%.3f sec, N=%d, checking=%s", self.alias, delay or 0, N, tostring(self.checking)))
  
  if delay and delay>0 then
  
    -- Delayed call.
    self:ScheduleOnce(delay, MSRSQUEUE._CheckRadioQueue, self)
    
    -- Checking on.
    self.checking=true
  
  else

    -- Check if queue is empty.
    if N==0 then
    
      -- Debug info.
      self:T(self.lid..string.format("Check radio queue %s empty ==> disable checking", self.alias))
    
      -- Queue is now empty. Nothing to else to do. We start checking again, if a transmission is added.
      self.checking=false
      
      return
    end

    -- Get current abs time.
    local time=timer.getAbsTime()
    
    -- Checking on.
    self.checking=true
    
    -- Set dt.
    local dt=self.dt
      
    
    local playing=false
    local next=nil  --#MSRSQUEUE.Transmission
    local remove=nil
    for i,_transmission in ipairs(self.queue) do
      local transmission=_transmission  --#MSRSQUEUE.Transmission
      
      -- Check if transmission time has passed.
      if time>=transmission.Tplay then 
        
        -- Check if transmission is currently playing.
        if transmission.isplaying then
        
          -- Check if transmission is finished.
          if time>=transmission.Tstarted+transmission.duration then
            
            -- Transmission over.
            transmission.isplaying=false
            
            -- Remove ith element in queue.
            remove=i
            
            -- Store time last transmission finished.
            self.Tlast=time
                      
          else -- still playing
          
            -- Transmission is still playing.
            playing=true
            
            dt=transmission.duration-(time-transmission.Tstarted)
            
          end
        
        else -- not playing yet
        
          local Tlast=self.Tlast
        
          if transmission.interval==nil  then
        
            -- Not playing ==> this will be next.
            if next==nil then
              next=transmission
            end
            
          else
          
            if Tlast==nil or time-Tlast>=transmission.interval then
              next=transmission            
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
    if next~=nil and not playing then
      -- Debug info.
      self:T(self.lid..string.format("Broadcasting text=\"%s\" at T=%.3f", next.text, time))
      
      -- Call SRS.
      self:Broadcast(next)
      
      next.isplaying=true
      next.Tstarted=time
      dt=next.duration
    end
    
    -- Remove completed call from queue.
    if remove then
      -- Remove from queue.
      table.remove(self.queue, remove)
      N=N-1
      
      -- Check if queue is empty.
      if #self.queue==0 then
        -- Debug info.
        self:T(self.lid..string.format("Check radio queue %s empty ==> disable checking", self.alias))
              
        self.checking=false
        
        return
      end
    end
    
    -- Check queue.
    self:_CheckRadioQueue(dt)
    
  end
  
end

MSRS.LoadConfigFile()
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
