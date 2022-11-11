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
-- By enabling this it also allows you to utilize SSML in your text for added flexibilty.
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
}

--- MSRS class version.
-- @field #string version
MSRS.version="0.1.1"

--- Voices
-- @type Voices
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add functions to remove freqs and modulations.
-- DONE: Add coordinate.
-- DONE: Add google.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new MSRS object.
-- @param #MSRS self
-- @param #string PathToSRS Path to the directory, where SRS is located.
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz. Can also be given as a #table of multiple frequencies.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators. Can also be given as a #table of multiple modulations.
-- @param #number Volume Volume - 1.0 is max, 0.0 is silence
-- @return #MSRS self
function MSRS:New(PathToSRS, Frequency, Modulation, Volume)

  -- Defaults.
  Frequency =Frequency or 143
  Modulation= Modulation or radio.modulation.AM

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #MSRS
  
  self:SetPath(PathToSRS)
  self:SetPort()
  self:SetFrequencies(Frequency)
  self:SetModulations(Modulation)
  self:SetGender()
  self:SetCoalition()
  self:SetLabel()
  self:SetVolume()
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

  if Path==nil then
    self:E("ERROR: No path to SRS directory specified!")
    return nil
  end
  
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

--- Use google text-to-speech.
-- @param #MSRS self
-- @param PathToCredentials Full path to the google credentials JSON file, e.g. "C:\Users\username\Downloads\service-account-file.json".
-- @return #MSRS self
function MSRS:SetGoogle(PathToCredentials)

  self.google=PathToCredentials
  
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Transmission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Play sound file (ogg or mp3) via SRS.
-- @param #MSRS self
-- @param Sound.SoundFile#SOUNDFILE Soundfile Sound file to play.
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
-- @param Sound.SoundFile#SOUNDTEXT SoundText Sound text.
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
-- @return #MSRS self
function MSRS:PlayText(Text, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayText, self, Text, 0)
  else

    -- Get command line.
    local command=self:_GetCommand()    

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
-- @return #MSRS self
function MSRS:PlayTextExt(Text, Delay, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayTextExt, self, Text, 0, Frequencies, Modulations, Gender, Culture, Voice, Volume, Label)
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
    local command=self:_GetCommand(Frequencies, Modulations, nil, Gender, Voice, Culture, Volume, nil, nil, Label)    

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
-- @return #string Command.
function MSRS:_GetCommand(freqs, modus, coal, gender, voice, culture, volume, speed, port,label)

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
  if self.coordinate then
    local lat,lon,alt=self:_GetLatLongAlt(self.coordinate)
    command=command..string.format(" -L %.4f -O %.4f -A %d", lat, lon, alt)
  end
  
  -- Set google.
  if self.google then
    command=command..string.format(' --ssml -G "%s"', self.google)
  end
  
  -- Debug output.
  self:T("MSRS command="..command)

  return command
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
  self:I(self.lid.."Clearning MSRSQUEUE")
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
-- @return #MSRSQUEUE.Transmission Radio transmission table.
function MSRSQUEUE:NewTransmission(text, duration, msrs, tstart, interval, subgroups, subtitle, subduration, frequency, modulation)
  
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
  
  -- Add transmission to queue.  
  self:AddTransmission(transmission)
  
  return transmission
end

--- Broadcast radio message.
-- @param #MSRSQUEUE self
-- @param #MSRSQUEUE.Transmission transmission The transmission.
function MSRSQUEUE:Broadcast(transmission)
  
  if transmission.frequency then
    transmission.msrs:PlayTextExt(transmission.text, nil, transmission.frequency, transmission.modulation, Gender, Culture, Voice, Volume, Label)
  else
    transmission.msrs:PlayText(transmission.text)
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
