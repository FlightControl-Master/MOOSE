--- **Sound** - Simple Radio Standalone (SRS) Integration.
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
-- ## Sound files: None yet.
--
-- ===
--
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, *i.e.* airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Addons.SRS
-- @image Addons_SRS.png

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
-- @extends Core.Base#BASE

--- *It is a very sad thing that nowadays there is so little useless information.* - Oscar Wilde
--
-- ===
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_Main.png)
--
-- # The MSRS Concept
--
-- This class allows to broadcast sound files or text via Simple Radio Standalone (SRS).
-- 
-- # Prerequisites
-- 
-- This script needs SRS version >= 0.9.6.
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
  culture        =    "en-GB",  
  voice          =        nil,
  volume         =          1,  
  speed          =          1,
  coordinate     =        nil,
  latitude       =        nil,
  longitude      =        nil,
  altitude       =        nil,
}

--- MSRS class version.
-- @field #string version
MSRS.version="0.0.2"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new MSRS object.
-- @param #MSRS self
-- @param #string PathToSRS Path to the directory, where SRS is located.
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz. Can also be given as a #table of multiple frequencies.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators. Can also be given as a #table of multiple modulations.
-- @return #MSRS self
function MSRS:New(PathToSRS, Frequency, Modulation)

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
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set path to SRS install directory. More precisely, path to where the DCS-
-- @param #MSRS self
-- @param #string Path Path to the directory, where the sound file is located.
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
  
  self.path=self.path.."/"
  
  self:I(string.format("SRS path=%s", self:GetPath()))
  
  return self
end

--- Get path to SRS directory.
-- @param #MSRS self
-- @return #string Path to the directory. This includes the final slash "/".
function MSRS:GetPath()
  return self.path
end

--- Set port.
-- @param #MSRS self
-- @param #number Port Port. Default 5002.
-- @return #MSRS self
function MSRS:SetPort(Port)
  self.port=Port or 5002
end

--- Get port.
-- @param #MSRS self
-- @return #number Port.
function MSRS:GetPort()
  return self.port
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
  
  Gender=Gender:lower()
  
  self.gender=Gender
  
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

    local soundfile=Soundfile:GetName()

    local command=self:_GetCommand()
    
    command=command.." --file="..tostring(soundfile)
    
    env.info(string.format("FF PlaySoundfile command=%s", command))

    -- Execute SRS command.
    os.execute(command)
        
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

    local command=self:_GetCommand(nil, nil, nil, SoundText.gender, SoundText.voice, SoundText.culture, SoundText.volume, SoundText.speed)
    
    command=command..string.format(" --text=\"%s\"", tostring(SoundText.text))
    
    env.info(string.format("FF PlaySoundfile command=%s", command))

    -- Execute SRS command.
    os.execute(command)
        
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

    local text=string.format("\"%s\"", Text)
    
    local command=self:_GetCommand()    

    command=command..string.format(" --text=\"%s\"", tostring(Text))
    
    env.info(string.format("FF Text command=%s", command))

    -- Execute SRS command.
    local x=os.execute(command)
    env.info(x)
        
  end
  
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
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
-- @return #string Command.
function MSRS:_GetCommand(freqs, modus, coal, gender, voice, culture, volume, speed, port)

    
  local exe=self:GetPath().."DCS-SR-ExternalAudio.exe"
  freqs=table.concat(freqs or self.frequencies, ",")
  modus=table.concat(modus or self.modulations, ",")
  coal=coal or self.coalition
  gender=gender or self.gender
  voice=voice or self.voice
  culture=culture or self.culture
  volume=volume or self.volume
  speed=speed or self.speed
  port=port or self.port  
  
  local command=string.format("%s --freqs=%s --modulations=%s --coalition=%d --port=%d --gender=%s --volume=%.2f --speed=%d", exe, freqs, modus, coal, port, gender, volume, speed)
  
  if voice then
    command=command..string.format(" --voice=\"%s\"", tostring(voice))
  end
  
  if culture then
    command=command.." --culture="..tostring(culture)
  end
  
  env.info("FF command="..command)

  return command
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
