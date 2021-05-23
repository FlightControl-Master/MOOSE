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
-- ## Youtube Videos:
--
--    * None
--
-- ===
--
-- ## Missions: Example missions can be found [here](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20ATIS)
--
-- ===
--
-- ## Sound files: Check out the pinned messages in the Moose discord #ops-atis channel.
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
  while self.path:sub(-1)=="/" or self.path:sub(-1)=="\\" do
    self.path=self.path:sub(1,-1)
  end
  
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
-- @param #string Path Path to the directory, where the sound file is located.
-- @return #MSRS self
function MSRS:PlaySoundfile(Soundfile)

  

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
