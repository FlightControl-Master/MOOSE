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
  ClassName      = "MSRS",
  lid            =   nil,
}

--- ATIS class version.
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

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #MSRS
  
  self.path=self:SetPath(PathToSRS)
  
  self.frequency=Frequency or 143
  
  self.modulation=Modulation or radio.modulation.AM


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- Set path, where the sound file is located.
-- @param #MSRS self
-- @param #string Path Path to the directory, where the sound file is located.
-- @return #MSRS self
function MSRS:SetPath(Path)

  if Path==nil then
    return nil
  end
  
  self.path=Path

  -- Remove (back)slashes.
  local nmax=1000
  local n=1
  while (self.path:sub(-1)=="/" or self.path:sub(-1)==[[\]]) and n<=nmax do
    env.info(string.format("FF SRS path=%s (before)", self.path))
    self.path=self.path:sub(1,#self.path-1)
    env.info(string.format("FF SRS path=%s (after)", self.path))
    n=n+1
  end
  
  env.info(string.format("FF SRS path=%s (final)", self.path))
  
  return self
end

--- Get path to SRS directory.
-- @param #MSRS self
-- @return #string 
function MSRS:GetPath()
  return self.path
end

--- Set path, where the sound file is located.
-- @param #MSRS self
-- @param Sound.SoundFile#SOUNDFILE Soundfile Sound file to play.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
function MSRS:PlaySoundfile(Soundfile, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundfile, Soundfile, 0)
  else

    local exe=self:GetPath().."/".."DCS-SR-ExternalAudio.exe"
    local soundfile=Soundfile:GetName()
    
    env.info(string.format("FF PlaySoundfile soundfile=%s", soundfile))
    
    local command=string.format("%s --file %s --freqs %d --modulations %d --coalition %d", exe, soundfile, self.frequency, 0)
    
    env.info(string.format("FF PlaySoundfile command=%s", command))
    
  end
  
  -- TODO: execute!

end

--- Set path, where the sound file is located.
-- @param #MSRS self
-- @param #string Message Text message.
-- @return #MSRS self
function MSRS:PlayText(Message)


end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
