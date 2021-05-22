--- **AddOn** - Simple Radio
--
-- ===
--
-- **Main Features:**
--
--    * SRS integration
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
-- @extends Core.Fsm#FSM

--- *It is a very sad thing that nowadays there is so little useless information.* - Oscar Wilde
--
-- ===
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_Main.png)
--
-- # The MSRS Concept
--
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, *i.e.* airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
--
-- @field #MSRS
MSRS = {
  ClassName      = "MSRS",
  lid            =   nil,
}

--- ATIS class version.
-- @field #string version
MSRS.version="0.9.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ATIS class object for a specific aircraft carrier unit.
-- @param #MSRS self
-- @param #string airbasename Name of the airbase.
-- @param #number frequency Radio frequency in MHz. Default 143.00 MHz.
-- @param #number modulation Radio modulation: 0=AM, 1=FM. Default 0=AM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators
-- @return #MSRS self
function MSRS:New(airbasename, frequency, modulation)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #ATIS


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set sound files folder within miz file.
-- @param #MSRS self
-- @param #string path Path for sound files. Default "ATIS Soundfiles/". Mind the slash "/" at the end!
-- @return #MSRS self
function MSRS:SetSoundfilesPath(path)
  self.soundpath=tostring(path or "ATIS Soundfiles/")
  self:I(self.lid..string.format("Setting sound files path to %s", self.soundpath))
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start ATIS FSM.
-- @param #MSRS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function MSRS:onafterStart(From, Event, To)

end

--- Update status.
-- @param #MSRS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function MSRS:onafterStatus(From, Event, To)

  -- Get FSM state.
  local fsmstate=self:GetState()

  self:__Status(-60)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if radio queue is empty. If so, start broadcasting the message again.
-- @param #MRSRS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function MSRS:onafterCheckQueue(From, Event, To)

  -- Check back in 5 seconds.
  self:__CheckQueue(-5)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
