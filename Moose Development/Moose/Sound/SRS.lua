--- **Sound** - Simple Radio Standalone Integration
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
-- @field #string path Path to the SRS exe.
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
  frequencies    =         {},
  modulations    =         {},
  coalition      =          0,
  speed          =          1,
  port           =       5002,
  name           = "DCS-STTS",
  volume         =     1,
  culture        =    "en-GB",
  gender         =   "female",
  voice          =        nil,
  latitude       =        nil,
  longitude      =        nil,
  altitude       =        nil,
}

--- MSRS class version.
-- @field #string version
MSRS.version="0.0.1"

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
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators.
-- @return #MSRS self
function MSRS:New(PathToSRS, Frequency, Modulation)

  -- Defaults.
  Frequency =Frequency or 143
  Modulation= Modulation or radio.modulation.AM

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #MSRS
  
  self:SetPath(PathToSRS)
  self:SetFrequencies(Frequency)
  self:SetModulations(Modulation)

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
  
  self:I(string.format("SRS path=%s", self:GetPath()))
  
  return self
end

--- Get path to SRS directory.
-- @param #MSRS self
-- @return #string Path to the directory.
function MSRS:GetPath()
  return self.path
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

--- Play sound file (ogg or mp3) via SRS.
-- @param #MSRS self
-- @param Sound.SoundFile#SOUNDFILE Soundfile Sound file to play.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
function MSRS:PlaySoundfile(Soundfile, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundfile, self, Soundfile, 0)
  else

    local exe=self:GetPath().."/".."DCS-SR-ExternalAudio.exe"
    local soundfile=Soundfile:GetName()
    local freq=table.concat(self.frequencies, " ")
    local modu=table.concat(self.modulations, " ")
    local coal=self.coalition
    local port=self.port
    
    local command=string.format("%s --file %s --freqs %s --modulations %s --coalition %d --port %d -h", exe, soundfile, freq, modu, coal, port)
    
    env.info(string.format("FF PlaySoundfile command=%s", command))

    -- Execute SRS command.
    os.execute(command)
        
  end

  return self
end

--- Play text message via STTS.
-- @param #MSRS self
-- @param #string Message Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @return #MSRS self
function MSRS:PlayText(Message, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayText, self, Message, 0)
  else

    local text=string.format("\"%s\"", Message)
    local exe=self:GetPath().."/".."DCS-SR-ExternalAudio.exe"
    local freq=table.concat(self.frequencies, " ")
    local modu=table.concat(self.modulations, " ")
    local coal=self.coalition
    local port=self.port
    local gender="male"
    
    local command=string.format("%s -h --text=%s --freqs=%s --modulations=%s --coalition=%d --port=%d --gender=%s", exe, text, freq, modu, coal, port, gender)
    
    env.info(string.format("FF Text command=%s", command))

    -- Execute SRS command.
    os.execute(command)
        
  end
  
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
