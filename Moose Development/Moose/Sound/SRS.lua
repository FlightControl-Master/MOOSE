--- **Sound** - Simple Radio Standalone (SRS) Integration and Text-to-Speech.
--
-- ===
--
-- **Main Features:**
--
--    * Incease immersion of your missions with more sound output
--    * Play sound files via SRS
--    * Play text-to-speech via SRS
--
-- ===
--
-- ## Youtube Videos: None yet
--
-- ===
--
-- ## Example Missions: [GitHub](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Sound/MSRS).
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
-- @field #string name Name. Default "MSRS".
-- @field #number volume Volume between 0 (min) and 1 (max). Default 1.
-- @field #string culture Culture. Default "en-GB".
-- @field #string gender Gender. Default "female".
-- @field #string voice Specific voice. Only used if no explicit provider voice specified.
-- @field Core.Point#COORDINATE coordinate Coordinate from where the transmission is send.
-- @field #string path Path to the SRS exe.
-- @field #string Label Label showing up on the SRS radio overlay. Default is "ROBOT". No spaces allowed.
-- @field #string ConfigFileName Name of the standard config file.
-- @field #string ConfigFilePath Path to the standard config file.
-- @field #boolean ConfigLoaded If `true` if config file was loaded.
-- @field #table poptions Provider options. Each element is a data structure of type `MSRS.ProvierOptions`.
-- @field #string provider Provider of TTS (win, gcloud, azure, amazon).
-- @field #string backend Backend used as interface to SRS (MSRS.Backend.SRSEXE or MSRS.Backend.GRPC).
-- @field #boolean UsePowerShell Use PowerShell to execute the command and not cmd.exe
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
-- * This script needs SRS version >= 1.9.6
-- * You need to de-sanitize os, io and lfs in the missionscripting.lua
-- * Optional: DCS-gRPC as backend to communicate with SRS (vide infra)
--
-- ## Knwon Issues
--
-- ### Pop-up Window
--
-- The text-to-speech conversion of SRS is done via an external exe file. When this file is called, a windows `cmd` window is briefly opended. That puts DCS out of focus, which is annoying,
-- expecially in VR but unavoidable (if you have a solution, please feel free to share!).
--
-- NOTE that this is not an issue if the mission is running on a server.
-- Also NOTE that using DCS-gRPC as backend will avoid the pop-up window.
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
-- ## Set Voice
--
-- Use a specific voice with the @{#MSRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system.
--
-- Note that you can set voices for each provider via the @{#MSRS.SetVoiceProvider} function. Also shortcuts are available, *i.e.*
-- @{#MSRS.SetVoiceWindows}, @{#MSRS.SetVoiceGoogle}, @{#MSRS.SetVoiceAzure} and @{#MSRS.SetVoiceAmazon}.
--
-- For voices there are enumerators in this class to help you out on voice names:
--
--     MSRS.Voices.Microsoft -- e.g. MSRS.Voices.Microsoft.Hedda - the Microsoft enumerator contains all voices known to work with SRS
--     MSRS.Voices.Google -- e.g. MSRS.Voices.Google.Standard.en_AU_Standard_A or MSRS.Voices.Google.Wavenet.de_DE_Wavenet_C - The Google enumerator contains voices for EN, DE, IT, FR and ES.
--
-- ## Set Coordinate
--
-- Use @{#MSRS.SetCoordinate} to define the origin from where the transmission is broadcasted.
-- Note that this is only a factor if SRS server has line-of-sight and/or distance limit enabled.
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
-- ## TTS Providers
--
-- The default provider for generating speech from text is the native Windows TTS service. Note that you need to install the voices you want to use.
-- 
-- **Pro-Tip** - use the command line with power shell to call `DCS-SR-ExternalAudio.exe` - it will tell you what is missing
-- and also the Google Console error, in case you have missed a step in setting up your Google TTS.
-- For example, `.\DCS-SR-ExternalAudio.exe -t "Text Message" -f 255 -m AM -c 2 -s 2 -z -G "Path_To_You_Google.Json"`
-- plays a message on 255 MHz AM for the blue coalition in-game.
--
-- ### Google
-- 
-- In order to use Google Cloud for TTS you need to use @{#MSRS.SetProvider} and @{#MSRS.SetProviderOptionsGoogle} functions:
-- 
--     msrs:SetProvider(MSRS.Provider.GOOGLE)
--     msrs:SetProviderOptionsGoogle(CredentialsFile, AccessKey)
--
-- The parameter `CredentialsFile` is used with the default 'DCS-SR-ExternalAudio.exe' backend and must be the full path to the credentials JSON file.
-- The `AccessKey` parameter is used with the DCS-gRPC backend (see below).
--
-- You can set the voice to use with Google via @{#MSRS.SetVoiceGoogle}.
--
-- When using Google it also allows you to utilize SSML in your text for more flexibility.
-- For more information on setting up a cloud account, visit: https://cloud.google.com/text-to-speech
-- Google's supported SSML reference: https://cloud.google.com/text-to-speech/docs/ssml
--
-- ### Amazon Web Service [Only DCS-gRPC backend]
-- 
-- In order to use Amazon Web Service (AWS) for TTS you need to use @{#MSRS.SetProvider} and @{#MSRS.SetProviderOptionsAmazon} functions:
-- 
--     msrs:SetProvider(MSRS.Provider.AMAZON)
--     msrs:SetProviderOptionsAmazon(AccessKey, SecretKey, Region)
--     
-- The parameters `AccessKey` and `SecretKey` are your AWS access and secret keys, respectively. The parameter `Region` is your [AWS region](https://docs.aws.amazon.com/general/latest/gr/pol.html).
-- 
-- You can set the voice to use with AWS via @{#MSRS.SetVoiceAmazon}.
-- 
-- ### Microsoft Azure [Only DCS-gRPC backend]
-- 
-- In order to use Microsoft Azure for TTS you need to use @{#MSRS.SetProvider} and @{#MSRS.SetProviderOptionsAzure} functions:
-- 
--     msrs:SetProvider(MSRS.Provider.AZURE)
--     msrs:SetProviderOptionsAmazon(AccessKey, Region)
--
-- The parameter `AccessKey` is your Azure access key. The parameter `Region` is your [Azure region](https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/regions).
--
-- You can set the voice to use with Azure via @{#MSRS.SetVoiceAzure}.
--
-- ## Backend
--
-- The default interface to SRS is via calling the 'DCS-SR-ExternalAudio.exe'. As noted above, this has the unavoidable drawback that a pop-up briefly appears
-- and DCS might be put out of focus.
--
-- ## DCS-gRPC as an alternative to 'DCS-SR-ExternalAudio.exe' for TTS
--
-- Another interface to SRS is [DCS-gRPC](https://github.com/DCS-gRPC/rust-server). This does not call an exe file and therefore avoids the annoying pop-up window.
-- In addition to Windows and Google cloud, it also offers Microsoft Azure and Amazon Web Service as providers for TTS.
--
-- Use @{#MSRS.SetDefaultBackendGRPC} to enable [DCS-gRPC](https://github.com/DCS-gRPC/rust-server) as an alternate backend for transmitting text-to-speech over SRS.
-- This can be useful if 'DCS-SR-ExternalAudio.exe' cannot be used in the environment or to use Azure or AWS clouds for TTS.  Note that DCS-gRPC does not (yet?) support
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
  backend        =   "srsexe",
  frequencies    =         {},
  modulations    =         {},
  coalition      =          0,
  gender         =   "female",
  culture        =        nil,
  voice          =        nil,
  volume         =          1,
  speed          =          1,
  coordinate     =        nil,
  provider       =      "win",
  Label          =    "ROBOT",
  ConfigFileName =    "Moose_MSRS.lua",
  ConfigFilePath =    "Config\\",
  ConfigLoaded   =     false,
  poptions       =        {},
  UsePowerShell  =      false,
}

--- MSRS class version.
-- @field #string version
MSRS.version="0.3.3"

--- Voices
-- @type MSRS.Voices
MSRS.Voices = {
  Microsoft = { -- working ones if not using gRPC and MS
    ["Hedda"] = "Microsoft Hedda Desktop", -- de-DE
    ["Hazel"] = "Microsoft Hazel Desktop", -- en-GB
    ["David"] = "Microsoft David Desktop", -- en-US
    ["Zira"] = "Microsoft Zira Desktop", -- en-US
    ["Hortense"] = "Microsoft Hortense Desktop", --fr-FR
    ["de_DE_Hedda"] = "Microsoft Hedda Desktop", -- de-DE
    ["en_GB_Hazel"] = "Microsoft Hazel Desktop", -- en-GB
    ["en_US_David"] = "Microsoft David Desktop", -- en-US
    ["en_US_Zira"] = "Microsoft Zira Desktop", -- en-US
    ["fr_FR_Hortense"] = "Microsoft Hortense Desktop", --fr-FR
    },
  MicrosoftGRPC = { -- en-US/GB voices only as of Jan 2024, working ones if using gRPC and MS, if voice packs are installed
    --["Hedda"] = "Hedda", -- de-DE
    ["Hazel"] = "Hazel", -- en-GB
    ["George"] = "George", -- en-GB
    ["Susan"] = "Susan", -- en-GB
    ["David"] = "David", -- en-US
    ["Zira"] = "Zira", -- en-US
    ["Mark"] = "Mark", -- en-US
    ["James"] = "James", --en-AU
    ["Catherine"] = "Catherine", --en-AU
    ["Richard"] = "Richard", --en-CA
    ["Linda"] = "Linda", --en-CA
    ["Ravi"] = "Ravi", --en-IN
    ["Heera"] = "Heera", --en-IN
    ["Sean"] = "Sean", --en-IR
    ["en_GB_Hazel"] = "Hazel", -- en-GB
    ["en_GB_George"] = "George", -- en-GB
    ["en_GB_Susan"] = "Susan", -- en-GB
    ["en_US_David"] = "David", -- en-US
    ["en_US_Zira"] = "Zira", -- en-US
    ["en_US_Mark"] = "Mark", -- en-US
    ["en_AU_James"] = "James", --en-AU
    ["en_AU_Catherine"] = "Catherine", --en-AU
    ["en_CA_Richard"] = "Richard", --en-CA
    ["en_CA_Linda"] = "Linda", --en-CA
    ["en_IN_Ravi"] = "Ravi", --en-IN
    ["en_IN_Heera"] = "Heera", --en-IN
    ["en_IR_Sean"] = "Sean", --en-IR   
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
       -- 2025 changes
       ["en_GB_Standard_A"] = 'en-GB-Standard-N', -- [9] FEMALE
       ["en_GB_Standard_B"] = 'en-GB-Standard-O', -- [10] MALE
       ["en_GB_Standard_C"] = 'en-GB-Standard-N', -- [11] FEMALE
       ["en_GB_Standard_D"] = 'en-GB-Standard-O', -- [12] MALE
       ["en_GB_Standard_F"] = 'en-GB-Standard-N', -- [13] FEMALE
       ["en_GB_Standard_O"] = 'en-GB-Standard-O', -- [12] MALE
       ["en_GB_Standard_N"] = 'en-GB-Standard-N', -- [13] FEMALE
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
       -- 2025 catalog changes
       ["fr_FR_Standard_A"] = "fr-FR-Standard-F", -- Female
       ["fr_FR_Standard_B"] = "fr-FR-Standard-G", -- Male
       ["fr_FR_Standard_C"] = "fr-FR-Standard-F", -- Female
       ["fr_FR_Standard_D"] = "fr-FR-Standard-G", -- Male
       ["fr_FR_Standard_E"] = "fr-FR-Standard-F", -- Female
       ["fr_FR_Standard_G"] = "fr-FR-Standard-G", -- Male
       ["fr_FR_Standard_F"] = "fr-FR-Standard-F", -- Female
       -- 2025 catalog changes
       ["de_DE_Standard_A"] = "de-DE-Standard-G", -- Female
       ["de_DE_Standard_B"] = "de-DE-Standard-H", -- Male
       ["de_DE_Standard_C"] = "de-DE-Standard-G", -- Female
       ["de_DE_Standard_D"] = "de-DE-Standard-H", -- Male
       ["de_DE_Standard_E"] = "de-DE-Standard-H", -- Male
       ["de_DE_Standard_F"] = "de-DE-Standard-G", -- Female
       ["de_DE_Standard_H"] = "de-DE-Standard-H", -- Male
       ["de_DE_Standard_G"] = "de-DE-Standard-G", -- Female
       ["es_ES_Standard_A"] = "es-ES-Standard-E", -- Female
       ["es_ES_Standard_B"] = "es-ES-Standard-F", -- Male
       ["es_ES_Standard_C"] = "es-ES-Standard-E", -- Female
       ["es_ES_Standard_D"] = "es-ES-Standard-F", -- Male
       ["es_ES_Standard_E"] = "es-ES-Standard-E", -- Female
       ["es_ES_Standard_F"] = "es-ES-Standard-F", -- Male
       -- 2025 catalog changes
       ["it_IT_Standard_A"] = "it-IT-Standard-E", -- Female
       ["it_IT_Standard_B"] = "it-IT-Standard-E", -- Female
       ["it_IT_Standard_C"] = "it-IT-Standard-F", -- Male
       ["it_IT_Standard_D"] = "it-IT-Standard-F", -- Male
       ["it_IT_Standard_E"] = "it-IT-Standard-E", -- Female
       ["it_IT_Standard_F"] = "it-IT-Standard-F", -- Male
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
       -- 2025 changes
       ["en_GB_Wavenet_A"] = 'en-GB-Wavenet-N', -- [9] FEMALE
       ["en_GB_Wavenet_B"] = 'en-GB-Wavenet-O', -- [10] MALE
       ["en_GB_Wavenet_C"] = 'en-GB-Wavenet-N', -- [11] FEMALE
       ["en_GB_Wavenet_D"] = 'en-GB-Wavenet-O', -- [12] MALE
       ["en_GB_Wavenet_F"] = 'en-GB-Wavenet-N', -- [13] FEMALE
       ["en_GB_Wavenet_O"] = 'en-GB-Wavenet-O', -- [12] MALE
       ["en_GB_Wavenet_N"] = 'en-GB-Wavenet-N', -- [13] FEMALE     
       ["en_US_Wavenet_A"] = 'en-US-Wavenet-N', -- [14] MALE
       ["en_US_Wavenet_B"] = 'en-US-Wavenet-B', -- [15] MALE
       ["en_US_Wavenet_C"] = 'en-US-Wavenet-C', -- [16] FEMALE
       ["en_US_Wavenet_D"] = 'en-US-Wavenet-D', -- [17] MALE
       ["en_US_Wavenet_E"] = 'en-US-Wavenet-E', -- [18] FEMALE
       ["en_US_Wavenet_F"] = 'en-US-Wavenet-F', -- [19] FEMALE
       ["en_US_Wavenet_G"] = 'en-US-Wavenet-G', -- [20] FEMALE
       ["en_US_Wavenet_H"] = 'en-US-Wavenet-H', -- [21] FEMALE
       ["en_US_Wavenet_I"] = 'en-US-Wavenet-I', -- [22] MALE
       ["en_US_Wavenet_J"] = 'en-US-Wavenet-J', -- [23] MALE
       -- 2025 catalog changes
       ["fr_FR_Wavenet_A"] = "fr-FR-Wavenet-F", -- Female
       ["fr_FR_Wavenet_B"] = "fr-FR-Wavenet-G", -- Male
       ["fr_FR_Wavenet_C"] = "fr-FR-Wavenet-F", -- Female
       ["fr_FR_Wavenet_D"] = "fr-FR-Wavenet-G", -- Male
       ["fr_FR_Wavenet_E"] = "fr-FR-Wavenet-F", -- Female
       ["fr_FR_Wavenet_G"] = "fr-FR-Wavenet-G", -- Male
       ["fr_FR_Wavenet_F"] = "fr-FR-Wavenet-F", -- Female
       -- 2025 catalog changes
       ["de_DE_Wavenet_A"] = "de-DE-Wavenet-G", -- Female
       ["de_DE_Wavenet_B"] = "de-DE-Wavenet-H", -- Male
       ["de_DE_Wavenet_C"] = "de-DE-Wavenet-G", -- Female
       ["de_DE_Wavenet_D"] = "de-DE-Wavenet-H", -- Male
       ["de_DE_Wavenet_E"] = "de-DE-Wavenet-H", -- Male
       ["de_DE_Wavenet_F"] = "de-DE-Wavenet-G", -- Female
       ["de_DE_Wavenet_H"] = "de-DE-Wavenet-H", -- Male
       ["de_DE_Wavenet_G"] = "de-DE-Wavenet-G", -- Female
       ["es_ES_Wavenet_B"] = "es-ES-Wavenet-E", -- Male
       ["es_ES_Wavenet_C"] = "es-ES-Wavenet-F", -- Female
       ["es_ES_Wavenet_D"] = "es-ES-Wavenet-E", -- Female
       ["es_ES_Wavenet_E"] = "es-ES-Wavenet-E", -- Male
       ["es_ES_Wavenet_F"] = "es-ES-Wavenet-F", -- Female
       -- 2025 catalog changes
       ["it_IT_Wavenet_A"] = "it-IT-Wavenet-E", -- Female
       ["it_IT_Wavenet_B"] = "it-IT-Wavenet-E", -- Female
       ["it_IT_Wavenet_C"] = "it-IT-Wavenet-F", -- Male
       ["it_IT_Wavenet_D"] = "it-IT-Wavenet-F", -- Male
       ["it_IT_Wavenet_E"] = "it-IT-Wavenet-E", -- Female
       ["it_IT_Wavenet_F"] = "it-IT-Wavenet-F", -- Male
      } ,
    },
  }


--- Backend options to communicate with SRS.
-- @type MSRS.Backend
-- @field #string SRSEXE Use `DCS-SR-ExternalAudio.exe`.
-- @field #string GRPC Use DCS-gRPC.
MSRS.Backend = {
  SRSEXE = "srsexe",
  GRPC   = "grpc",
}

--- Text-to-speech providers. These are compatible with the DCS-gRPC conventions.
-- @type MSRS.Provider
-- @field #string WINDOWS Microsoft windows (`win`).
-- @field #string GOOGLE Google (`gcloud`).
-- @field #string AZURE Microsoft Azure (`azure`). Only possible with DCS-gRPC backend.
-- @field #string AMAZON Amazon Web Service (`aws`). Only possible with DCS-gRPC backend.
MSRS.Provider = {
  WINDOWS = "win",
  GOOGLE  = "gcloud",
  AZURE   = "azure",
  AMAZON  = "aws",
}

--- Function for UUID.
function MSRS.uuid()
  local random = math.random
  local template = 'yxxx-xxxxxxxxxxxx'
  return string.gsub( template, '[xy]', function( c )
    local v = (c == 'x') and random( 0, 0xf ) or random( 8, 0xb )
    return string.format( '%x', v )
  end )
end

--- Provider options.
-- @type MSRS.ProviderOptions
-- @field #string provider Provider.
-- @field #string credentials Google credentials JSON file (full path).
-- @field #string key Access key (DCS-gRPC with Google, AWS, AZURE as provider).
-- @field #string secret Secret key (DCS-gRPC with AWS as provider)
-- @field #string region Region.
-- @field #string defaultVoice Default voice (not used).
-- @field #string voice Voice used.

--- GRPC options.
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Refactoring of input/config file.
-- DONE: Refactoring gRPC backend.
-- TODO: Add functions to remove freqs and modulations.
-- DONE: Add coordinate.
-- DONE: Add google.
-- DONE: Add gRPC google options
-- DONE: Add loading default config file

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new MSRS object. Required argument is the frequency and modulation.
-- Other parameters are read from the `Moose_MSRS.lua` config file. If you do not have that file set up you must set up and use the `DCS-SR-ExternalAudio.exe` (not DCS-gRPC) as backend, you need to still
-- set the path to the exe file via @{#MSRS.SetPath}.
--
-- @param #MSRS self
-- @param #string Path Path to SRS directory. Default `C:\\Program Files\\DCS-SimpleRadio-Standalone`.
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz. Can also be given as a #table of multiple frequencies.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators. Can also be given as a #table of multiple modulations.
-- @param #string Backend Backend used: `MSRS.Backend.SRSEXE` (default) or `MSRS.Backend.GRPC`.
-- @return #MSRS self
function MSRS:New(Path, Frequency, Modulation, Backend)

  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #MSRS

  self:F( {Path, Frequency, Modulation, Backend} )

  -- Defaults.
  Frequency = Frequency or 143
  Modulation = Modulation or radio.modulation.AM

  self.lid = string.format("%s-%s | ", "unknown", self.version)

  if not self.ConfigLoaded then

    -- Defaults.
    self:SetPath(Path)
    self:SetPort()
    self:SetFrequencies(Frequency)
    self:SetModulations(Modulation)
    self:SetGender()
    self:SetCoalition()
    self:SetLabel()
    self:SetVolume()
    self:SetBackend(Backend)

  else

    -- Default overwrites from :New()
    
    if Path then
      self:SetPath(Path)
    end

    if Frequency then
      self:SetFrequencies(Frequency)
    end

    if Modulation then
      self:SetModulations(Modulation)
    end

    if Backend then
      self:SetBackend(Backend)
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

--- Set backend to communicate with SRS.
-- There are two options:
--
-- - `MSRS.Backend.SRSEXE`: This is the default and uses the `DCS-SR-ExternalAudio.exe`.
-- - `MSRS.Backend.GRPC`: Via DCS-gRPC.
--
-- @param #MSRS self
-- @param #string Backend Backend used. Default is `MSRS.Backend.SRSEXE`.
-- @return #MSRS self
function MSRS:SetBackend(Backend)
  self:F( {Backend=Backend} )
  Backend = Backend or MSRS.Backend.SRSEXE -- avoid nil
  local function Checker(back)
    local ok = false
    for _,_backend in pairs(MSRS.Backend) do
      if tostring(back) == _backend then ok = true end
    end
    return ok
  end
  
  if Checker(Backend) then  
    self.backend=Backend 
  else    
    MESSAGE:New("ERROR: Backend "..tostring(Backend).." is not supported!",30,"MSRS",true):ToLog():ToAll()    
  end 
  return self
end

--- Set DCS-gRPC as backend to communicate with SRS.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetBackendGRPC()
  self:F()
  self:SetBackend(MSRS.Backend.GRPC)

  return self
end

--- Set `DCS-SR-ExternalAudio.exe` as backend to communicate with SRS.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetBackendSRSEXE()
  self:F()
  self:SetBackend(MSRS.Backend.SRSEXE)

  return self
end

--- Set the default backend.
-- @param #string Backend
function MSRS.SetDefaultBackend(Backend)
  MSRS.backend=Backend or MSRS.Backend.SRSEXE
end

--- Set DCS-gRPC to be the default backend.
-- @param #MSRS self
function MSRS.SetDefaultBackendGRPC()
  MSRS.backend=MSRS.Backend.GRPC
end

--- Get currently set backend.
-- @param #MSRS self
-- @return #string Backend.
function MSRS:GetBackend()
  return self.backend
end

--- Set path to SRS install directory. More precisely, path to where the `DCS-SR-ExternalAudio.exe` is located.
-- @param #MSRS self
-- @param #string Path Path to the directory, where the sound file is located. Default is `C:\\Program Files\\DCS-SimpleRadio-Standalone`.
-- @return #MSRS self
function MSRS:SetPath(Path)
  self:F( {Path=Path} )

  -- Set path.
  self.path=Path or "C:\\Program Files\\DCS-SimpleRadio-Standalone"

  -- Remove (back)slashes.
  local n=1 ; local nmax=1000
  while (self.path:sub(-1)=="/" or self.path:sub(-1)==[[\]]) and n<=nmax do
    self.path=self.path:sub(1,#self.path-1)
    n=n+1
  end

  -- Debug output.
  self:F(string.format("SRS path=%s", self:GetPath()))
  
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
  self:F( {Volume=Volume} )
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
  self:F( {Label=Label} )
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
  self:F( {Port=Port} )
  self.port=Port or 5002
  self:T(string.format("SRS port=%s", self:GetPort()))
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
  self:F( {Coalition=Coalition} )
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
  self:F( Frequencies )
  self.frequencies=UTILS.EnsureTable(Frequencies, false)

  return self
end

--- Add frequencies.
-- @param #MSRS self
-- @param #table Frequencies Frequencies in MHz. Can also be given as a #number if only one frequency should be used.
-- @return #MSRS self
function MSRS:AddFrequencies(Frequencies)
  self:F( Frequencies )
  for _,_freq in pairs(UTILS.EnsureTable(Frequencies, false)) do
    self:T(self.lid..string.format("Adding frequency %s", tostring(_freq)))
    table.insert(self.frequencies,_freq)
  end

  return self
end

--- Get frequencies.
-- @param #MSRS self
-- @return #table Frequencies in MHz.
function MSRS:GetFrequencies()
  return self.frequencies
end


--- Set modulations.
-- @param #MSRS self
-- @param #table Modulations Modulations. Can also be given as a #number if only one modulation should be used.
-- @return #MSRS self
function MSRS:SetModulations(Modulations)
  self:F( Modulations )
  self.modulations=UTILS.EnsureTable(Modulations, false)

  -- Debug info.
  self:T(self.lid.."Modulations:")
  self:T(self.modulations)

  return self
end

--- Add modulations.
-- @param #MSRS self
-- @param #table Modulations Modulations. Can also be given as a #number if only one modulation should be used.
-- @return #MSRS self
function MSRS:AddModulations(Modulations)
  self:F( Modulations )
   for _,_mod in pairs(UTILS.EnsureTable(Modulations, false)) do
    table.insert(self.modulations,_mod)
   end

  return self
end

--- Get modulations.
-- @param #MSRS self
-- @return #table Modulations.
function MSRS:GetModulations()
  return self.modulations
end

--- Set gender.
-- @param #MSRS self
-- @param #string Gender Gender: "male" or "female" (default).
-- @return #MSRS self
function MSRS:SetGender(Gender)
  self:F( {Gender=Gender} )
  Gender=Gender or "female"

  self.gender=Gender:lower()

  -- Debug output.
  self:T("Setting gender to "..tostring(self.gender))

  return self
end

--- Set culture.
-- @param #MSRS self
-- @param #string Culture Culture, *e.g.* "en-GB".
-- @return #MSRS self
function MSRS:SetCulture(Culture)
  self:F( {Culture=Culture} )
  self.culture=Culture

  return self
end

--- Set to use a specific voice. Note that this will override any gender and culture settings as a voice already has a certain gender/culture.
-- @param #MSRS self
-- @param #string Voice Voice.
-- @return #MSRS self
function MSRS:SetVoice(Voice)
  self:F( {Voice=Voice} )
  self.voice=Voice

  return self
end

--- Set to use a specific voice for a given provider. Note that this will override any gender and culture settings.
-- @param #MSRS self
-- @param #string Voice Voice.
-- @param #string Provider Provider. Default is as set by @{#MSRS.SetProvider}, which itself defaults to `MSRS.Provider.WINDOWS` if not set.
-- @return #MSRS self
function MSRS:SetVoiceProvider(Voice, Provider)
  self:F( {Voice=Voice, Provider=Provider} )
  self.poptions=self.poptions or {}

  self.poptions[Provider or self:GetProvider()].voice=Voice

  return self
end

--- Set to use a specific voice if Microsoft Windows' native TTS is use as provider. Note that this will override any gender and culture settings.
-- @param #MSRS self
-- @param #string Voice Voice. Default `"Microsoft Hazel Desktop"`.
-- @return #MSRS self
function MSRS:SetVoiceWindows(Voice)
  self:F( {Voice=Voice} )
  self:SetVoiceProvider(Voice or "Microsoft Hazel Desktop", MSRS.Provider.WINDOWS)

  return self
end

--- Set to use a specific voice if Google is use as provider. Note that this will override any gender and culture settings.
-- @param #MSRS self
-- @param #string Voice Voice. Default `MSRS.Voices.Google.Standard.en_GB_Standard_A`.
-- @return #MSRS self
function MSRS:SetVoiceGoogle(Voice)
  self:F( {Voice=Voice} )
  self:SetVoiceProvider(Voice or MSRS.Voices.Google.Standard.en_GB_Standard_A, MSRS.Provider.GOOGLE)

  return self
end


--- Set to use a specific voice if Microsoft Azure is use as provider (only DCS-gRPC backend). Note that this will override any gender and culture settings.
-- @param #MSRS self
-- @param #string Voice [Azure Voice](https://learn.microsoft.com/azure/cognitive-services/speech-service/language-support). Default `"en-US-AriaNeural"`.
-- @return #MSRS self
function MSRS:SetVoiceAzure(Voice)
  self:F( {Voice=Voice} )
  self:SetVoiceProvider(Voice or "en-US-AriaNeural", MSRS.Provider.AZURE)

  return self
end

--- Set to use a specific voice if Amazon Web Service is use as provider (only DCS-gRPC backend). Note that this will override any gender and culture settings.
-- @param #MSRS self
-- @param #string Voice [AWS Voice](https://docs.aws.amazon.com/polly/latest/dg/voicelist.html). Default `"Brian"`.
-- @return #MSRS self
function MSRS:SetVoiceAmazon(Voice)
  self:F( {Voice=Voice} )
  self:SetVoiceProvider(Voice or "Brian", MSRS.Provider.AMAZON)

  return self
end

--- Get voice.
-- @param #MSRS self
-- @param #string Provider Provider. Default is the currently set provider (`self.provider`).
-- @return #string Voice.
function MSRS:GetVoice(Provider)

  Provider=Provider or self.provider

  if Provider and self.poptions[Provider] and self.poptions[Provider].voice then
    return self.poptions[Provider].voice
  else
    return self.voice
  end

end

--- Set the coordinate from which the transmissions will be broadcasted. Note that this is only a factor if SRS has line-of-sight or distance enabled.
-- @param #MSRS self
-- @param Core.Point#COORDINATE Coordinate Origin of the transmission.
-- @return #MSRS self
function MSRS:SetCoordinate(Coordinate)
  self:F( Coordinate )
  self.coordinate=Coordinate

  return self
end

--- **[Deprecated]** Use google text-to-speech credentials. Also sets Google as default TTS provider.
-- @param #MSRS self
-- @param #string PathToCredentials Full path to the google credentials JSON file, e.g. "C:\Users\username\Downloads\service-account-file.json". Can also be the Google API key.
-- @return #MSRS self
function MSRS:SetGoogle(PathToCredentials)
  self:F( {PathToCredentials=PathToCredentials} )
  if PathToCredentials then

    self.provider = MSRS.Provider.GOOGLE

    self:SetProviderOptionsGoogle(PathToCredentials, PathToCredentials)

  end

  return self
end

--- **[Deprecated]** Use google text-to-speech set the API key (only for DCS-gRPC).
-- @param #MSRS self
-- @param #string APIKey API Key, usually a string of length 40 with characters and numbers.
-- @return #MSRS self
function MSRS:SetGoogleAPIKey(APIKey)
  self:F( {APIKey=APIKey} )
  if APIKey then

    self.provider = MSRS.Provider.GOOGLE

    if self.poptions[MSRS.Provider.GOOGLE] then
      self.poptions[MSRS.Provider.GOOGLE].key=APIKey
    else
      self:SetProviderOptionsGoogle(nil ,APIKey)
    end

  end
  return self
end


--- Set provider used to generate text-to-speech.
-- These options are available:
--
-- - `MSRS.Provider.WINDOWS`: Microsoft Windows (default)
-- - `MSRS.Provider.GOOGLE`: Google Cloud
-- - `MSRS.Provider.AZURE`: Microsoft Azure (only with DCS-gRPC backend)
-- - `MSRS.Provier.AMAZON`: Amazone Web Service (only with DCS-gRPC backend)
--
-- Note that all providers except Microsoft Windows need as additonal information the credentials of your account.
--
-- @param #MSRS self
-- @param #string Provider
-- @return #MSRS self
function MSRS:SetProvider(Provider)
  BASE:F( {Provider=Provider} )
  if self then
    self.provider = Provider or MSRS.Provider.WINDOWS
    return self
  else
    MSRS.provider = Provider or MSRS.Provider.WINDOWS
  end
  return
end

--- Get provider.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:GetProvider()
  return self.provider or MSRS.Provider.WINDOWS
end

--- Set provider options and credentials.
-- @param #MSRS self
-- @param #string Provider Provider.
-- @param #string CredentialsFile Full path to your credentials file. For Google this is the path to a JSON file.
-- @param #string AccessKey Your API access key.
-- @param #string SecretKey Your secret key.
-- @param #string Region Region to use.
-- @return #MSRS.ProviderOptions Provider optionas table.
function MSRS:SetProviderOptions(Provider, CredentialsFile, AccessKey, SecretKey, Region)
  BASE:F( {Provider, CredentialsFile, AccessKey, SecretKey, Region} )
  local option=MSRS._CreateProviderOptions(Provider, CredentialsFile, AccessKey, SecretKey, Region)

  if self then
    self.poptions=self.poptions or {}
    self.poptions[Provider]=option
  else
    MSRS.poptions=MSRS.poptions or {}
    MSRS.poptions[Provider]=option
  end

  return option
end

--- Create MSRS.ProviderOptions.
-- @param #string Provider Provider.
-- @param #string CredentialsFile Full path to your credentials file. For Google this is the path to a JSON file.
-- @param #string AccessKey Your API access key.
-- @param #string SecretKey Your secret key.
-- @param #string Region Region to use.
-- @return #MSRS.ProviderOptions Provider optionas table.
function MSRS._CreateProviderOptions(Provider, CredentialsFile, AccessKey, SecretKey, Region)
  BASE:F( {Provider, CredentialsFile, AccessKey, SecretKey, Region} )
  local option={} --#MSRS.ProviderOptions

  option.provider=Provider
  option.credentials=CredentialsFile
  option.key=AccessKey
  option.secret=SecretKey
  option.region=Region

  return option
end

--- Set provider options and credentials for Google Cloud.
-- @param #MSRS self
-- @param #string CredentialsFile Full path to your credentials file. For Google this is the path to a JSON file. This is used if `DCS-SR-ExternalAudio.exe` is used as backend.
-- @param #string AccessKey Your API access key. This is necessary if DCS-gRPC is used as backend.
-- @return #MSRS self
function MSRS:SetProviderOptionsGoogle(CredentialsFile, AccessKey)
  self:F( {CredentialsFile, AccessKey} )
  self:SetProviderOptions(MSRS.Provider.GOOGLE, CredentialsFile, AccessKey)
  return self
end

--- Set provider options and credentials for Amazon Web Service (AWS). Only supported in combination with DCS-gRPC as backend.
-- @param #MSRS self
-- @param #string AccessKey Your API access key.
-- @param #string SecretKey Your secret key.
-- @param #string Region Your AWS [region](https://docs.aws.amazon.com/general/latest/gr/pol.html).
-- @return #MSRS self
function MSRS:SetProviderOptionsAmazon(AccessKey, SecretKey, Region)
  self:F( {AccessKey, SecretKey, Region} )
  self:SetProviderOptions(MSRS.Provider.AMAZON, nil, AccessKey, SecretKey, Region)
  return self
end

--- Set provider options and credentials for Microsoft Azure. Only supported in combination with DCS-gRPC as backend.
-- @param #MSRS self
-- @param #string AccessKey Your API access key.
-- @param #string Region Your Azure [region](https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/regions).
-- @return #MSRS self
function MSRS:SetProviderOptionsAzure(AccessKey, Region)
  self:F( {AccessKey, Region} )
  self:SetProviderOptions(MSRS.Provider.AZURE, nil, AccessKey, nil, Region)
  return self
end


--- Get provider options.
-- @param #MSRS self
-- @param #string Provider Provider. Default is as set via @{#MSRS.SetProvider}.
-- @return #MSRS.ProviderOptions Provider options.
function MSRS:GetProviderOptions(Provider)
  return self.poptions[Provider or self.provider] or {}
end


--- Use Google to provide text-to-speech.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetTTSProviderGoogle()
  self:F()
  self:SetProvider(MSRS.Provider.GOOGLE)
  return self
end

--- Use Microsoft to provide text-to-speech.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetTTSProviderMicrosoft()
  self:F()
  self:SetProvider(MSRS.Provider.WINDOWS)
  return self
end


--- Use Microsoft Azure to provide text-to-speech. Only supported if used in combination with DCS-gRPC as backend.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetTTSProviderAzure()
  self:F()
  self:SetProvider(MSRS.Provider.AZURE)
  return self
end

--- Use Amazon Web Service (AWS) to provide text-to-speech. Only supported if used in combination with DCS-gRPC as backend.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:SetTTSProviderAmazon()
  self:F()
  self:SetProvider(MSRS.Provider.AMAZON)
  return self
end


--- Print SRS help to DCS log file.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:Help()
  self:F()
  -- Path and exe.
  local path=self:GetPath()
  local exe="DCS-SR-ExternalAudio.exe"

  -- Text file for output.
  local filename = os.getenv('TMP') .. "\\MSRS-help-"..MSRS.uuid()..".txt"

  -- Print help.
  local command=string.format("%s/%s --help > %s", path, exe, filename)
  os.execute(command)

  local f=assert(io.open(filename, "rb"))
  local data=f:read("*all")
  f:close()

  -- Print to log file.
  env.info("SRS help output:")
  env.info("======================================================================")
  env.info(data)
  env.info("======================================================================")

  return self
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
  self:F( {Soundfile, Delay} )

  -- Sound file name.
  local soundfile=Soundfile:GetName()

  -- First check if text file exists!
  local exists=UTILS.FileExists(soundfile)
  if not exists then
    self:E("ERROR: MSRS sound file does not exist! File="..soundfile)
    return self
  end

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundFile, self, Soundfile, 0)
  else

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
  self:F( {SoundText, Delay} )

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundText, self, SoundText, 0)
  else

    if self.backend==MSRS.Backend.GRPC then
      self:_DCSgRPCtts(SoundText.text, nil, SoundText.gender, SoundText.culture, SoundText.voice, SoundText.volume, SoundText.label, SoundText.coordinate)
    else

      -- Get command.
      local command=self:_GetCommand(nil, nil, nil, SoundText.gender, SoundText.voice, SoundText.culture, SoundText.volume, SoundText.speed)

      -- Append text.
      command=command..string.format(" --text=\"%s\"", tostring(SoundText.text))

      -- Execute command.
      self:_ExecCommand(command)

    end

  end

  return self
end

--- Play text message via MSRS.
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @return #MSRS self
function MSRS:PlayText(Text, Delay, Coordinate)
  self:F( {Text, Delay, Coordinate} )

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayText, self, Text, nil, Coordinate)
  else

    if self.backend==MSRS.Backend.GRPC then
      self:T(self.lid.."Transmitting")
      self:_DCSgRPCtts(Text, nil, nil , nil, nil, nil, nil, Coordinate)
    else
      self:PlayTextExt(Text, Delay, nil, nil, nil, nil, nil, nil, nil, Coordinate)
    end

  end

  return self
end

--- Play text message via MSRS with explicitly specified options.
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
  self:T({Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate} )

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, self.PlayTextExt, self, Text, 0, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label, Coordinate)
  else

    Frequencies = Frequencies or self:GetFrequencies()
    Modulations = Modulations or self:GetModulations()

    if self.backend==MSRS.Backend.SRSEXE then

      -- Get command line.
      local command=self:_GetCommand(UTILS.EnsureTable(Frequencies, false), UTILS.EnsureTable(Modulations, false), nil, Gender, Voice, Culture, Volume, nil, nil, Label, Coordinate)

      -- Append text.
      command=command..string.format(" --text=\"%s\"", tostring(Text))

      -- Execute command.
      self:_ExecCommand(command)

    elseif self.backend==MSRS.Backend.GRPC then
      --BASE:I("MSRS.Backend.GRPC")

      self:_DCSgRPCtts(Text, Frequencies, Gender, Culture, Voice, Volume, Label, Coordinate)

    end

  end

  return self
end


--- Play text file via MSRS.
-- @param #MSRS self
-- @param #string TextFile Full path to the file.
-- @param #number Delay Delay in seconds, before the message is played.
-- @return #MSRS self
function MSRS:PlayTextFile(TextFile, Delay)
  self:F( {TextFile, Delay} )

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
    self:T(string.format("Command length=%d", l))

    -- Execute command.
    self:_ExecCommand(command)

  end

  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get lat, long and alt from coordinate.
-- @param #MSRS self
-- @param Core.Point#Coordinate Coordinate Coordinate. Can also be a DCS#Vec3.
-- @return #number Latitude (or 0 if no input coordinate was given).
-- @return #number Longitude (or 0 if no input coordinate was given).
-- @return #number Altitude (or 0 if no input coordinate was given).
function MSRS:_GetLatLongAlt(Coordinate)
  self:F( {Coordinate=Coordinate} )

  local lat=0.0
  local lon=0.0
  local alt=0.0

  if Coordinate then
    lat, lon, alt=coord.LOtoLL(Coordinate)
  end

  return lat, lon, math.floor(alt)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Backend ExternalAudio.exe
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
function MSRS:_GetCommand(freqs, modus, coal, gender, voice, culture, volume, speed, port, label, coordinate)
  self:F( {freqs, modus, coal, gender, voice, culture, volume, speed, port, label, coordinate} )

  local path=self:GetPath()
  local exe="DCS-SR-ExternalAudio.exe"
  local fullPath = string.format("%s\\%s", path, exe)

  freqs=table.concat(freqs or self.frequencies, ",")
  modus=table.concat(modus or self.modulations, ",")

  coal=coal or self.coalition
  gender=gender or self.gender
  voice=voice or self:GetVoice(self.provider) or self.voice
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
  local pwsh = string.format('Start-Process -WindowStyle Hidden -WorkingDirectory \"%s\" -FilePath \"%s\" -ArgumentList \'-f "%s" -m "%s" -c %s -p %s -n "%s" -v "%.1f"', path, exe, freqs, modus, coal, port, label,volume )
  
  local command=string.format('"%s\\%s" -f "%s" -m "%s" -c %s -p %s -n "%s" -v "%.1f"', path, exe, freqs, modus, coal, port, label,volume)

  -- Set voice or gender/culture.
  if voice and self.UsePowerShell ~= true then
    -- Use a specific voice (no need for gender and/or culture.
    command=command..string.format(" --voice=\"%s\"", tostring(voice))
    pwsh=pwsh..string.format(" --voice=\"%s\"", tostring(voice))
  else
    -- Add gender.
    if gender and gender~="female" then
      command=command..string.format(" -g %s", tostring(gender))
      pwsh=pwsh..string.format(" -g %s", tostring(gender))
    end
    -- Add culture.
    if culture and culture~="en-GB" then
      command=command..string.format(" -l %s", tostring(culture))
      pwsh=pwsh..string.format(" -l %s", tostring(culture))
    end
  end

  -- Set coordinate.
  if coordinate then
    local lat,lon,alt=self:_GetLatLongAlt(coordinate)
    command=command..string.format(" -L %.4f -O %.4f -A %d", lat, lon, alt)
    pwsh=pwsh..string.format(" -L %.4f -O %.4f -A %d", lat, lon, alt)
  end

  -- Set provider options
  if self.provider==MSRS.Provider.GOOGLE then
    local pops=self:GetProviderOptions()
    command=command..string.format(' --ssml -G "%s"', pops.credentials)
    pwsh=pwsh..string.format(' --ssml -G "%s"', pops.credentials)
  elseif self.provider==MSRS.Provider.WINDOWS then
    -- Nothing to do.
  else
    self:E("ERROR: SRS only supports WINWOWS and GOOGLE as TTS providers! Use DCS-gRPC backend for other providers such as ")
  end

  if not UTILS.FileExists(fullPath) then
    self:E("ERROR: MSRS SRS executable does not exist! FullPath="..fullPath)
    command="CommandNotFound"
  end

  -- Debug output.
  self:T("MSRS command from _GetCommand="..command)
  
  if self.UsePowerShell == true then
    return pwsh
  else
    return command
  end
end

--- Execute SRS command to play sound using the `DCS-SR-ExternalAudio.exe`.
-- @param #MSRS self
-- @param #string command Command to executer
-- @return #number Return value of os.execute() command.
function MSRS:_ExecCommand(command)
  self:T2( {command=command} )

  -- Skip this function if _GetCommand was not able to find the executable
  if string.find(command, "CommandNotFound") then return 0 end

  local batContent = command.." && exit"
  -- Create a tmp file.
  local filename=os.getenv('TMP').."\\MSRS-"..MSRS.uuid()..".bat"
  
  if self.UsePowerShell == true then
   filename=os.getenv('TMP').."\\MSRS-"..MSRS.uuid()..".ps1"
   batContent = command .. "\'"
   self:I({batContent=batContent})
  end
  
  local script=io.open(filename, "w+")
  script:write(batContent)
  script:close()

  self:T("MSRS batch file created: "..filename)
  self:T("MSRS batch content: "..batContent)

  local res=nil
  if self.UsePowerShell ~= true then

    -- Create a tmp file.
    local filenvbs = os.getenv('TMP') .. "\\MSRS-"..MSRS.uuid()..".vbs"

    -- VBS script
    local script = io.open(filenvbs, "w+")
    script:write(string.format('Dim WinScriptHost\n'))
    script:write(string.format('Set WinScriptHost = CreateObject("WScript.Shell")\n'))
    script:write(string.format('WinScriptHost.Run Chr(34) & "%s" & Chr(34), 0\n', filename))
    script:write(string.format('Set WinScriptHost = Nothing'))
    script:close()
    self:T("MSRS vbs file created to start batch="..filenvbs)

    -- Run visual basic script. This still pops up a window but very briefly and does not put the DCS window out of focus.
    local runvbs=string.format('cscript.exe //Nologo //B "%s"', filenvbs)

    -- Debug output.
    self:T("MSRS execute VBS command="..runvbs)

    -- Play file in 0.01 seconds
    res=os.execute(runvbs)

    -- Remove file in 1 second.
    timer.scheduleFunction(os.remove, filename, timer.getTime()+1)
    timer.scheduleFunction(os.remove, filenvbs, timer.getTime()+1)
    self:T("MSRS vbs and batch file removed")

  elseif self.UsePowerShell == true then

    local pwsh = string.format('start /min "" powershell.exe  -ExecutionPolicy Unrestricted -WindowStyle Hidden -Command "%s"',filename)
    --env.info("[MSRS] TextToSpeech Command :\n" .. pwsh.."\n")
    
    if string.len(pwsh) > 255 then
      self:E("[MSRS] - pwsh string too long")      
    end
    
    -- Play file in 0.01 seconds
    res=os.execute(pwsh)
    
    -- Remove file in 1 second.
    timer.scheduleFunction(os.remove, filename, timer.getTime()+1)

  else
    -- Play command.
    command=string.format('start /b "" "%s"', filename)

    -- Debug output.
    self:T("MSRS execute command="..command)

    -- Execute command
    res=os.execute(command)

    -- Remove file in 1 second.
    timer.scheduleFunction(os.remove, filename, timer.getTime()+1)

  end


  return res
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DCS-gRPC Backend Functions
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
-- @param #table Frequencies Radio frequencies to transmit on. Can also accept a number in MHz.
-- @param #string Gender Gender.
-- @param #string Culture Culture.
-- @param #string Voice Voice.
-- @param #number Volume Volume.
-- @param #string Label Label.
-- @param Core.Point#COORDINATE Coordinate Coordinate.
-- @return #MSRS self
function MSRS:_DCSgRPCtts(Text, Frequencies, Gender, Culture, Voice, Volume, Label, Coordinate)

  -- Debug info.
  self:T("MSRS_BACKEND_DCSGRPC:_DCSgRPCtts()")
  self:T({Text, Frequencies, Gender, Culture, Voice, Volume, Label, Coordinate})

  local options = {} -- #MSRS.GRPCOptions

  local ssml = Text or ''

  -- Get frequenceies.
  Frequencies = UTILS.EnsureTable(Frequencies, true) or self:GetFrequencies()

  -- Plain text (not really used.
  options.plaintext=Text

  -- Name shows as sender.
  options.srsClientName = Label or self.Label

  -- Set position.
  if self.coordinate then
    options.position = {}
    options.position.lat, options.position.lon, options.position.alt = self:_GetLatLongAlt(self.coordinate)
  end

  -- Coalition (gRPC expects lower case)
  options.coalition = UTILS.GetCoalitionName(self.coalition):lower()

  -- Provider (win, gcloud, ...)
  local provider = self.provider or MSRS.Provider.WINDOWS

  -- Provider options: voice, credentials
  options.provider = {}
  options.provider[provider] = self:GetProviderOptions(provider)

  -- Voice
  Voice=Voice or self:GetVoice(self.provider) or self.voice
  
  if Voice then
    -- We use a specific voice
    options.provider[provider].voice = Voice
  else
  
    -- DCS-gRPC doesn't directly support language/gender, but can use SSML

    local preTag, genderProp, langProp, postTag = '', '', '', ''

    local gender=""
    if self.gender then
      gender=string.format(' gender=\"%s\"', self.gender)
    end
    local language=""
    if self.culture then
      language=string.format(' language=\"%s\"', self.culture)
    end

    if self.gender or self.culture then
      ssml=string.format("<voice%s%s>%s</voice>", gender, language, Text)
    end
  end

  for _,freq in pairs(Frequencies) do
    self:T("Calling GRPC.tts with the following parameter:")
    self:T({ssml=ssml, freq=freq, options=options})
    self:T(options.provider[provider])
    GRPC.tts(ssml, freq*1e6, options)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Config File
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
--     -- Moose MSRS default Config
--     MSRS_Config = {
--       Path = "C:\\Program Files\\DCS-SimpleRadio-Standalone", -- Path to SRS install directory.
--       Port = 5002,            -- Port of SRS server. Default 5002.
--       Backend = "srsexe",     -- Interface to SRS: "srsexe" or "grpc".
--       Frequency = {127, 243}, -- Default frequences. Must be a table 1..n entries!
--       Modulation = {0,0},     -- Default modulations. Must be a table, 1..n entries, one for each frequency!
--       Volume = 1.0,           -- Default volume [0,1].
--       Coalition = 0,          -- 0 = Neutral, 1 = Red, 2 = Blue (only a factor if SRS server has encryption enabled).
--       Coordinate = {0,0,0},   -- x, y, alt (only a factor if SRS server has line-of-sight and/or distance limit enabled).
--       Culture = "en-GB",
--       Gender = "male",
--       Voice = "Microsoft Hazel Desktop", -- Voice that is used if no explicit provider voice is specified.
--       Label = "MSRS",   
--       Provider = "win", --Provider for generating TTS (win, gcloud, azure, aws).      
--       -- Windows
--       win = {
--         voice = "Microsoft Hazel Desktop",
--       },
--       -- Google Cloud
--       gcloud = {
--         voice = "en-GB-Standard-A", -- The Google Cloud voice to use (see https://cloud.google.com/text-to-speech/docs/voices).
--         credentials="C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourfilename.json", -- Full path to credentials JSON file (only for SRS-TTS.exe backend)
--         key="Your access Key", -- Google API access key (only for DCS-gRPC backend)
--       },
--       -- Amazon Web Service
--       aws = {
--         voice = "Brian", -- The default AWS voice to use (see https://docs.aws.amazon.com/polly/latest/dg/voicelist.html).
--         key="Your access Key",  -- Your AWS key.
--         secret="Your secret key", -- Your AWS secret key.
--         region="eu-central-1", -- Your AWS region (see https://docs.aws.amazon.com/general/latest/gr/pol.html).
--       },
--       -- Microsoft Azure
--       azure = {
--         voice="en-US-AriaNeural",  --The default Azure voice to use (see https://learn.microsoft.com/azure/cognitive-services/speech-service/language-support).
--         key="Your access key", -- Your Azure access key.
--         region="westeurope", -- The Azure region to use (see https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/regions).
--       },
--     }
--
--  3) The config file is automatically loaded when Moose starts. You can also load the config into the MSRS raw class manually before you do anything else:
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
--     mysrs:LoadConfigFile(Path,Filename)
--
--  4) Use the config in your code like so, variable names are basically the same as in the config file, but all lower case, examples:
--
--         -- Needed once only
--         MESSAGE.SetMSRS(MSRS.path,MSRS.port,nil,127,rado.modulation.FM,nil,nil,nil,nil,nil,"TALK")
--
--         -- later on in your code
--
--         MESSAGE:New("Test message!",15,"SPAWN"):ToSRS(243,radio.modulation.AM,nil,nil,MSRS.Voices.Google.Standard.fr_FR_Standard_C)
--
--         -- Create new ATIS as usual
--         atis=ATIS:New(AIRBASE.Caucasus.Batumi, 123, radio.modulation.AM)
--         atis:SetSRS(nil,nil,nil,MSRS.Voices.Google.Standard.en_US_Standard_H)
--         --Start ATIS
--         atis:Start()
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

    env.info("FF reading config file")

    -- Load global MSRS_Config
    assert(loadfile(path..file))()

    if MSRS_Config then

      local Self = self or MSRS  --#MSRS

      Self.path = MSRS_Config.Path or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
      Self.port = MSRS_Config.Port or 5002
      Self.backend = MSRS_Config.Backend or MSRS.Backend.SRSEXE
      Self.frequencies = MSRS_Config.Frequency or {127,243}
      Self.modulations = MSRS_Config.Modulation or {0,0}
      Self.coalition = MSRS_Config.Coalition or 0
      if MSRS_Config.Coordinate then
        Self.coordinate = COORDINATE:New( MSRS_Config.Coordinate[1], MSRS_Config.Coordinate[2], MSRS_Config.Coordinate[3] )
      end
      Self.culture = MSRS_Config.Culture or "en-GB"
      Self.gender = MSRS_Config.Gender or "male"
      Self.Label = MSRS_Config.Label or "MSRS"
      Self.voice = MSRS_Config.Voice --or MSRS.Voices.Microsoft.Hazel

      Self.provider = MSRS_Config.Provider or MSRS.Provider.WINDOWS
      for _,provider in pairs(MSRS.Provider) do
        if MSRS_Config[provider] then
          Self.poptions[provider]=MSRS_Config[provider]
        end
      end

      Self.ConfigLoaded = true

    end
    env.info("MSRS - Successfully loaded default configuration from disk!",false)
  end

  if not filexsists then
    env.info("MSRS - Cannot find default configuration file!",false)
    return false
  end

  return true
end

--- Function returns estimated speech time in seconds.
-- Assumptions for time calc: 100 Words per min, average of 5 letters for english word so
--
--   * 5 chars * 100wpm = 500 characters per min = 8.3 chars per second
--
-- So length of msg / 8.3 = number of seconds needed to read it. rounded down to 8 chars per sec map function:
--
-- * (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
--
-- @param #number length can also be passed as #string
-- @param #number speed Defaults to 1.0
-- @param #boolean isGoogle We're using Google TTS
function MSRS.getSpeechTime(length,speed,isGoogle)

  local maxRateRatio = 3

  speed = speed or 1.0
  isGoogle = isGoogle or false

  local speedFactor = 1.0
  if isGoogle then
    speedFactor = speed
  else
    if speed ~= 0 then
      speedFactor = math.abs( speed ) * (maxRateRatio - 1) / 10 + 1
    end
    if speed < 0 then
      speedFactor = 1 / speedFactor
    end
  end

  local wpm = math.ceil( 100 * speedFactor )
  local cps = math.floor( (wpm * 5) / 60 )

  if type( length ) == "string" then
    length = string.len( length )
  end

  return length/cps --math.ceil(length/cps)
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
  self:T(self.lid.."Clearing MSRSQUEUE")
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
  transmission.duration=duration or MSRS.getSpeechTime(text)
  transmission.msrs=msrs
  transmission.Tplay=tstart or timer.getAbsTime()
  transmission.subtitle=subtitle
  transmission.interval=interval or 0
  transmission.frequency=frequency or msrs.frequencies
  transmission.modulation=modulation or msrs.modulations
  transmission.subgroups=subgroups
  if transmission.subtitle then
    transmission.subduration=subduration or transmission.duration
  else
    transmission.subduration=0 --nil
  end
  transmission.gender = gender or msrs.gender
  transmission.culture = culture or msrs.culture
  transmission.voice = voice or msrs.voice
  transmission.volume = volume or msrs.volume
  transmission.label = label or msrs.Label
  transmission.coordinate = coordinate or msrs.coordinate

  -- Add transmission to queue.
  self:AddTransmission(transmission)

  return transmission
end

--- Broadcast radio message.
-- @param #MSRSQUEUE self
-- @param #MSRSQUEUE.Transmission transmission The transmission.
function MSRSQUEUE:Broadcast(transmission)
  self:T(self.lid.."Broadcast")
  
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
