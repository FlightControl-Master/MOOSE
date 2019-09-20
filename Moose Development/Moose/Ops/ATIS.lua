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
-- @field #string relayunitname Name of the radio relay unit.
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
  relayunitname  =   nil,
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
  self:AddTransition("*",             "Broadcast",       "*")           -- Broadcast ATIS message.
  self:AddTransition("*",             "CheckQueue",      "*")           -- Check if radio queue is empty.
  
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

--- Set sound files folder within miz file.
-- @param #ATIS self
-- @param #string unitname
-- @return #ATIS self
function ATIS:SetRadioRelayUnitName(unitname)
  self.relayunitname=unitname
  self:I(self.lid..string.format("Setting radio relay unit to %s", self.relayunitname))
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
  self.radioqueue:SetSenderUnitName(self.relayunitname)
  
  self.radioqueue:SetDigit(0, "N-0.ogg", 0.55, self.soundpath)
  self.radioqueue:SetDigit(1, "N-1.ogg", 0.40, self.soundpath)
  self.radioqueue:SetDigit(2, "N-2.ogg", 0.35, self.soundpath)
  self.radioqueue:SetDigit(3, "N-3.ogg", 0.40, self.soundpath)
  self.radioqueue:SetDigit(4, "N-4.ogg", 0.36, self.soundpath)
  self.radioqueue:SetDigit(5, "N-5.ogg", 0.42, self.soundpath)
  self.radioqueue:SetDigit(6, "N-6.ogg", 0.53, self.soundpath)
  self.radioqueue:SetDigit(7, "N-7.ogg", 0.42, self.soundpath)
  self.radioqueue:SetDigit(8, "N-8.ogg", 0.37, self.soundpath)
  self.radioqueue:SetDigit(9, "N-9.ogg", 0.38, self.soundpath)
  
  self.radioqueue:Start(1, 0.05)

  -- Init status updates.
  self:__Status(-2)
  self:__CheckQueue(-3)
end

--- Update status.
-- @param #ATIS self
function ATIS:onafterStatus(From, Event, To)

  local fsmstate=self:GetState()
  
    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.lid..text)
  
  self:__Status(30)
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
  else
    self:I(self.lid..string.format("Radio queue %d transmissions queued.", #self.radioqueue.queue))
  end
  
  -- Check back in 5 seconds.
  self:__CheckQueue(5)
end

--- Update status.
-- @param #ATIS self
function ATIS:onafterBroadcast(From, Event, To)

  local coord=self.airbase:GetCoordinate()
  
  local height=coord:GetLandHeight()
  
  ----------------
  --- Pressure ---
  ----------------
  local qfe=coord:GetPressure(height+5)
  local qnh=coord:GetPressure(0)
  
  -- Convert to inHg
  qfe=UTILS.hPa2inHg(qfe)
  qnh=UTILS.hPa2inHg(qnh)
      
  local QFE=UTILS.Split(string.format("%.2f", qfe), ".")
  local QNH=UTILS.Split(string.format("%.2f", qnh), ".")
  
  
  local runway=self.airbase:GetActiveRunway()
  
  local windFrom, windSpeed=coord:GetWind()
  local WINDFROM=string.format("%03d", windFrom)
  local WINDSPEED=string.format("%d", UTILS.MpsToKnots(windSpeed))
  
  -- Time
  local time=timer.getAbsTime()
  
  -- TODO add zulu time correction.
  
  local clock=UTILS.SecondsToClock(time)
  local zulu=UTILS.Split(clock, ":")
  local ZULU=string.format("%s%s", zulu[1], zulu[2])
  
  -- Temperature
  local temperature=coord:GetTemperature(height+5)
  local TEMPERATURE=string.format("%d", temperature)
  
  -- Weather
  local clouds, visibility, fog, dust=self:GetStaticWeather()
  local cloudbase=clouds.base
  local cloudceiling=clouds.base+clouds.thickness
  local clouddensity=clouds.density
  
  local subduration=10
  
  -- Batumi Airbase.
  self.radioqueue:NewTransmission("Batumi.ogg",  0.52, self.soundpath, nil, nil, "Batumi Airport", subduration)
  self.radioqueue:NewTransmission("Airport.ogg", 0.65, self.soundpath)
  
  -- 1300 Zulu
  self.radioqueue:Number2Transmission(ZULU)
  self.radioqueue:NewTransmission("TimeZulu.ogg", 0.89, self.soundpath, nil, nil, string.format("%s Zulu Time", ZULU), subduration)
  
  -- Visibility
  local visibility="3"
  self.radioqueue:NewTransmission("Visibility.ogg", 0.8, self.soundpath, nil, 1.0, string.format("Visibility %s NM", visibility), subduration)
  self.radioqueue:Number2Transmission(visibility)
  -- TODO: 0.8
  self.radioqueue:NewTransmission("NauticalMiles.ogg", 0.8, self.soundpath, nil, 0.2)
  
  -- Altimeter QFE.
  self.radioqueue:NewTransmission("Altimeter.ogg", 0.7, self.soundpath, nil, 2.0, string.format("Altimeter QFE %s.%s inHg, QNH %s.%s inHg", QFE[1], QFE[2], QNH[1], QNH[2]), subduration)
  self.radioqueue:NewTransmission("QFE.ogg", 0.62, self.soundpath)
  self.radioqueue:Number2Transmission(QFE[1])
  self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QFE[2])
  self.radioqueue:NewTransmission("QNH.ogg", 0.70, self.soundpath, nil, 2.0)
  self.radioqueue:Number2Transmission(QNH[1])
  self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QNH[2])
  
  -- Temperature
  self.radioqueue:NewTransmission("Temperature.ogg", 0.7, self.soundpath, nil, 2.0, string.format("Temperature %s C", TEMPERATURE), subduration)
  self.radioqueue:Number2Transmission(TEMPERATURE)
  -- TODO: Celcius --> Celsius, 0.9?
  self.radioqueue:NewTransmission("DegreesCelsius.ogg", 0.9, self.soundpath, nil, 0.2)
  
  -- Wind
  self.radioqueue:NewTransmission("WindFrom.ogg", 0.7, self.soundpath, nil, 2.0, string.format("Wind from %s at %s knots", WINDFROM, WINDSPEED), subduration)
  self.radioqueue:Number2Transmission(WINDFROM)
  self.radioqueue:NewTransmission("At.ogg", 0.7, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(WINDSPEED)
  self.radioqueue:NewTransmission("Knots.ogg", 0.7, self.soundpath, nil, 0.2)
  
  -- Active runway.
  self.radioqueue:NewTransmission("ActiveRunway.ogg", 1.05, self.soundpath, nil, 2.0, string.format("Active runway %s", runway.idx), subduration)
  self.radioqueue:Number2Transmission(runway.idx)
  
  
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
