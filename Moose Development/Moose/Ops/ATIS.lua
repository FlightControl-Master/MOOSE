--- **Ops** - (R2.5) - Automatic Terminal Information Service.
--
-- **Main Features:**
--
--    * Broadcast 
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Atis
-- @image OPS_ATIS.png


--- ATIS class.
-- @type ATIS
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string airbasename The name of the airbase.
-- @field Wrapper.Airbase#AIRBASE airbase The airbase object.
-- @field #number frequency Radio frequency in MHz.
-- @field #number modulation Radio modulation 0=AM or 1=FM.
-- @field Core.RadioQueue#RADIOQUEUE radioqueue Radio queue for broadcasing messages.
-- @field #string soundpath Path to sound files.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_Main.jpg)
--
-- # The ATIS Concept
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, i.e. airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
--
--
-- @field #ATIS
ATIS = {
  ClassName      = "ATIS",
  Debug          = false,
  lid            =   nil,
  airbasename    =   nil,
  airbase        =   nil,
  frequency      =   nil,
  modulation     =   nil,
  radioqueue     =   nil,
  soundpath      =   nil,
}

--- ATIS class version.
-- @field #string version
ATIS.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ATIS class object for a specific aircraft carrier unit.
-- @param #ATIS self
-- @param #string airbasename Name of the airbase.
-- @param #number frequency Radio frequency in MHz. Default 143.00 MHz.
-- @param #number modulation 0=AM, 1=FM. Default 0=AM.
-- @return #ATIS self
function ATIS:New(airbasename, frequency, modulation)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #ATIS
  
  self.airbasename=airbasename
  self.airbase=AIRBASE:FindByName(airbasename)
  
  self.frequency=frequency or 143.00
  self.modulation=modulation or 0

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ATIS %s | ", self.airbasename)
  
  -- Defaults:
  self:SetSoundfilesPath()

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",          "*")           -- Update status.
  self:AddTransition("*",             "Broadcast",       "*")           -- Update status.
  self:AddTransition("*",             "CheckQueue",      "*")           -- Update status.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the ATIS.
  -- @function [parent=#ATIS] Start
  -- @param #ATIS self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#ATIS] __Start
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the ATIS.
  -- @param #ATIS self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#ATIS] __Stop
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.

  -- Debug trace.
  if true then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  self:__Start(1)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set sound files folder within miz file.
-- @param #ATIS self
-- @param #string path Path for sound files. Default "ATIS Soundfiles".
-- @return #ATIS self
function ATIS:SetSoundfilesPath(path)
  self.soundpath=tostring(path or "ATIS Soundfiles/")
  self:I(self.lid..string.format("Setting sound files path to %s", self.soundpath))
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start ATIS FSM.
-- @param #ATIS self
function ATIS:onafterStart(From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting ATIS v%s for airbase %s", ATIS.version, self.airbasename))
  
  -- Start radio queue.
  self.radioqueue=RADIOQUEUE:New(self.frequency, self.modulation)
  
  self.radioqueue:SetSenderCoordinate(self.airbase:GetCoordinate())
  
  self.radioqueue:Start(1, 0.01)
  
  self.radioqueue:SetDigit(0, "0-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(1, "1-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(2, "2-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(3, "3-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(4, "4-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(5, "5-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(6, "6-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(7, "7-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(8, "8-continue.wav", 0.8, self.soundpath)
  self.radioqueue:SetDigit(9, "9-continue.wav", 0.8, self.soundpath)
  

  -- Init status updates.
  self:__Status(-1)
  self:__CheckQueue(-2)
end

--- Update status.
-- @param #ATIS self
function ATIS:onafterStatus(From, Event, To)

  local fsmstate=self:GetState()
  
    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.lid..text)
  
  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if radio queue is empty. If so, start broadcasting the message again.
-- @param #ATIS self
function ATIS:onafterCheckQueue(From, Event, To)

  if #self.radioqueue.queue==0 then
    self:I(self.lid..string.format("Radio queue empty. Repeating message."))
    self:Broadcast()
  end
  
  -- Check back in 5 seconds.
  self:__CheckQueue(-5)
end

--- Update status.
-- @param #ATIS self
function ATIS:onafterBroadcast(From, Event, To)

  self.radioqueue:Number2Transmission("0123456789", 0, 0)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get static weather of this mission from env.mission.weather.
-- @param #ATIS self
-- @param #table Clouds table which has entries "thickness", "density", "base", "iprecptns".
-- @param #number Visibility distance in meters.
-- @param #table Fog table, which has entries "thickness", "visibility" or nil if fog is disabled in the mission.
-- @param #number Dust density or nil if dust is disabled in the mission.
function ATIS:GetStaticWeather()

  -- Weather data from mission file.
  local weather=env.mission.weather

  -- Clouds
  --[[
  ["clouds"] =
  {
      ["thickness"] = 430,
      ["density"] = 7,
      ["base"] = 0,
      ["iprecptns"] = 1,
  }, -- end of ["clouds"]
  ]]
  local clouds=weather.clouds

  -- Visibilty distance in meters.
  local visibility=weather.visibility.distance

  -- Dust
  --[[
  ["enable_dust"] = false,
  ["dust_density"] = 0,
  ]]
  local dust=nil
  if weather.enable_dust==true then
    dust=weather.dust_density
  end

  -- Fog
  --[[
  ["enable_fog"] = false,
  ["fog"] =
  {
      ["thickness"] = 0,
      ["visibility"] = 25,
  }, -- end of ["fog"]
  ]]
  local fog=nil
  if weather.enable_fog==true then
    fog=weather.fog
  end


  return clouds, visibility, fog, dust
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
