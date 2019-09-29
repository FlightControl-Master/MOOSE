--- **Ops** - (R2.5) - Automatic Terminal Information Service.
--
-- **Main Features:**
--
--    * Active runway
--    * Wind direction and speed
--    * Visibility
--    * Cloud coverage, base and ceiling
--    * Temprature
--    * Pressure QNH/QFE
--    * Weather phenomena: rain, thunderstorm, fog, dust
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
-- @field #string theatre DCS map name.
-- @field #string airbasename The name of the airbase.
-- @field Wrapper.Airbase#AIRBASE airbase The airbase object.
-- @field #number frequency Radio frequency in MHz.
-- @field #number modulation Radio modulation 0=AM or 1=FM.
-- @field Core.RadioQueue#RADIOQUEUE radioqueue Radio queue for broadcasing messages.
-- @field #string soundpath Path to sound files.
-- @field #string relayunitname Name of the radio relay unit.
-- @field #table towerfrequency Table with tower frequencies.
-- @field #string activerunway The active runway specified by the user.
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
  theatre        =   nil,
  airbasename    =   nil,
  airbase        =   nil,
  frequency      =   nil,
  modulation     =   nil,
  radioqueue     =   nil,
  soundpath      =   nil,
  relayunitname  =   nil,
  towerfrequency =   nil,
  activerunway   =   nil,
}

--- NATO alphabet.
-- @type ATIS.Alphabet
ATIS.Alphabet = {
  [1]  = "Alfa",
  [2]  = "Bravo",
  [3]  = "Charlie",
  [4]  = "Delta",
  [5]  = "Echo",
  [6]  = "Delta",
  [7]  = "Echo",
  [8]  = "Foxtrot",
  [9]  = "Golf",
  [10] = "Hotel",
  [11] = "India",
  [12] = "Juliett",
  [13] = "Kilo",
  [15] = "Lima",
  [16] = "Mike",
  [17] = "November",
  [18] = "Oscar",
  [19] = "Papa",
  [20] = "Quebec",
  [21] = "Romeo",
  [22] = "Sierra",
  [23] = "Tango",
  [24] = "Uniform",
  [25] = "Victor",
  [26] = "Whiskey",
  [27] = "Xray",
  [28] = "Yankee",
  [29] = "Zulu",
}

--- ATIS class version.
-- @field #string version
ATIS.version="0.2.0"

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
  
  self.theatre=env.mission.theatre

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

--- Set tower frequencies.
-- @param #ATIS self
-- @param #table freqs Frequencies in MHz. A single frequency can be given as a number.
-- @return #ATIS self
function ATIS:SetTowerFrequencies(freqs)
  if type(freqs)=="table" then
    -- nothing to do
  else  
    freqs={freqs}
  end
  self.towerfrequency=freqs
end

--- Set active runway. This can be used if the automatic runway determination via the wind direction gives incorrect results.
-- For example, use this if there are two runways with the same directions.
-- @param #ATIS self
-- @param #string runway Active runway, e.g. "31L".
-- @return #ATIS self
function ATIS:SetActiveRunway(runway)
  self.activerunway=tostring(runway)
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
  
  self.radioqueue:Start(1, 0.1)

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
  
  local height=coord:GetLandHeight()+10
  
  ----------------
  --- Pressure ---
  ----------------
  local qfe=coord:GetPressure(height)
  local qnh=coord:GetPressure(0)
  
  -- Convert to inHg
  qfe=UTILS.hPa2inHg(qfe)
  qnh=UTILS.hPa2inHg(qnh)
      
  local QFE=UTILS.Split(string.format("%.2f", qfe), ".")
  local QNH=UTILS.Split(string.format("%.2f", qnh), ".")
  
  --------------
  --- Runway ---
  --------------
  
  -- Get runway based on wind direction.
  local runway=self.airbase:GetActiveRunway().idx
  
  -- Left or right in case there are two runways with the same heading.
  local rleft=false
  local rright=false
  
  -- Check if user explicitly specified a runway.
  if self.activerunway then
    runway=self.activerunway:gsub("%D+", "")
    rleft=self.activerunway:lower():find("l")
    rright=self.activerunway:lower():find("r")
  end
  
  ------------
  --- Wind ---
  ------------
  local windFrom, windSpeed=coord:GetWind(height)
  local WINDFROM=string.format("%03d", windFrom)
  local WINDSPEED=string.format("%d", UTILS.MpsToKnots(windSpeed))
  
  ------------
  --- Time ---
  ------------
  local time=timer.getAbsTime()
  
  -- Conversion to Zulu time.
  if self.theatre==DCSMAP.Caucasus then
    time=time-4*60*60  -- Caucasus UTC+4 hours
  elseif self.theatre==DCSMAP.PersianGulf then
    time=time-4*60*60  -- Abu Dhabi UTC+4 hours
  elseif self.theatre==DCSMAP.NTTR then
    time=time+7*60*60  -- Las Vegas UTC-7 hours
  elseif self.theatre==DCSMAP.Normandy then
    time=time-1*60*60  -- Calais UTC+1 hour
  end
  
  local clock=UTILS.SecondsToClock(time)
  local zulu=UTILS.Split(clock, ":")
  local ZULU=string.format("%s%s", zulu[1], zulu[2])
  
  
  -- NATO time stamp.
  local NATO=ATIS.Alphabet[tonumber(zulu[1])-1]
  
  self:I({nato=NATO})
  
  -------------------
  --- Temperature ---
  -------------------
  local temperature=coord:GetTemperature(height)
  local TEMPERATURE=string.format("%d", temperature)
  
  -- Weather
  local clouds, visibility, turbulence, fog, dust=self:GetStaticWeather()


  ------------------
  --- Visibility ---
  ------------------
  local visibilitymin=visibility
  if fog then
    if fog.visibility<visibilitymin then
      visibilitymin=fog.visibility
    end    
  end
  if dust then
    if dust<visibilitymin then
      visibilitymin=dust
    end
  end
  
  local VISIBILITY=string.format("%d", UTILS.Round(UTILS.MetersToNM(visibilitymin)))
  
  --------------
  --- Clouds ---
  --------------
  local cloudbase=clouds.base
  local cloudceil=clouds.base+clouds.thickness
  local clouddens=clouds.density  
  local precepitation=tonumber(clouds.iprecptns)
  
  local CLOUDBASE=string.format("%d", UTILS.MetersToFeet(cloudbase))
  local CLOUDCEIL=string.format("%d", UTILS.MetersToFeet(cloudceil))
  
  local CLOUDBASE0100=tostring(self:_GetHundreds( UTILS.MetersToFeet(cloudbase)))
  local CLOUDBASE1000=tostring(self:_GetThousands(UTILS.MetersToFeet(cloudbase)))
  local CLOUDCEIL0100=tostring(self:_GetHundreds( UTILS.MetersToFeet(cloudceil)))
  local CLOUDCEIL1000=tostring(self:_GetThousands(UTILS.MetersToFeet(cloudceil)))
  
  self:I({cloudbase0100=CLOUDBASE0100})
  self:I({cloudbase1000=CLOUDBASE1000})
  
  -- No cloud info for dynamic weather.
  local CLOUDSogg="CloudsNotAvailable.ogg"
  local CLOUDSsub="Cloud coverage information not available"
  local CLOUDSdur=2.40
  
  -- TODO: add static weather switch
  if true then
    if clouddens>=9 then
      -- Overcast 9,10
      CLOUDSogg="CloudsOvercast.ogg"
      CLOUDSsub="Overcast"
      CLOUDSdur=0.85
    elseif clouddens>=7 then
      -- Broken 7,8
      CLOUDSogg="CloudsBroken.ogg"
      CLOUDSsub="Broken clouds"
      CLOUDSdur=1.10
    elseif clouddens>=4 then
      -- Scattered 4,5,6
      CLOUDSogg="CloudsScattered.ogg"
      CLOUDSsub="Scattered clouds"
      CLOUDSdur=1.20
    elseif clouddens>=1 then
      -- Few 1,2,3
      CLOUDSogg="CloudsFew.ogg"
      CLOUDSsub="Few clouds"
      CLOUDSdur=1.00
    else
      -- No clouds
      CLOUDBASE=nil
      CLOUDCEIL=nil
      CLOUDSogg="CloudsNo.ogg"
      CLOUDSsub="No clouds"
      CLOUDSdur=1.00
    end
  end
  
  --------------------
  --- Transmission ---
  --------------------
  
  local subduration=10
  local subtitle=""
  
  --Airbase name
  subtitle=string.format("%s", self.airbasename)
  if self.airbasename:find("AFB")==nil and self.airbasename:find("Airport")==nil and self.airbasename:find("Airstrip")==nil and self.airbasename:find("airfield")==nil then
    subtitle=subtitle.." Airport"
  end
  self.radioqueue:NewTransmission(string.format("%s/%s.ogg", self.theatre, self.airbasename), 3.0, self.soundpath, nil, nil, subtitle, subduration)
  
  -- Information tag
  subtitle=string.format("Information %s", NATO)
  self.radioqueue:NewTransmission("Information.ogg", 0.85, self.soundpath, nil, 0.5, subtitle, subduration)
  self.radioqueue:NewTransmission(string.format("NATO Alphabet/%s.ogg", NATO), 0.75, self.soundpath)
  
  -- Zulu Time
  subtitle=string.format("%s Zulu Time", ZULU)
  self.radioqueue:Number2Transmission(ZULU, nil, 0.5)
  self.radioqueue:NewTransmission("TimeZulu.ogg", 0.89, self.soundpath, nil, 0.2, subtitle, subduration)
  
  -- Visibility
  subtitle=string.format("Visibility %s NM", VISIBILITY)
  self.radioqueue:NewTransmission("Visibility.ogg", 0.8, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:Number2Transmission(VISIBILITY)
  self.radioqueue:NewTransmission("NauticalMiles.ogg", 1.05, self.soundpath, nil, 0.2)
  
  -- Cloud base
  self.radioqueue:NewTransmission(CLOUDSogg, CLOUDSdur, self.soundpath, nil, 1.0, CLOUDSsub, subduration)
  if CLOUDBASE then
    -- Base
    self.radioqueue:NewTransmission("CloudBase.ogg", 0.81, self.soundpath, nil, 1.0, string.format("Cloudbase %s, ceiling %s ft", CLOUDBASE, CLOUDCEIL), subduration)
    if tonumber(CLOUDBASE1000)>0 then
      self.radioqueue:Number2Transmission(CLOUDBASE1000)
      self.radioqueue:NewTransmission("Thousand.ogg", 0.55, self.soundpath, nil, 0.1)
    end 
    if tonumber(CLOUDBASE0100)>0 then
      self.radioqueue:Number2Transmission(CLOUDBASE0100)
      self.radioqueue:NewTransmission("Hundred.ogg", 0.47, self.soundpath, nil, 0.1)
    end
    -- Ceiling
    self.radioqueue:NewTransmission("CloudCeiling.ogg", 0.62, self.soundpath, nil, 0.5)
    if tonumber(CLOUDCEIL1000)>0 then
      self.radioqueue:Number2Transmission(CLOUDCEIL1000)
      self.radioqueue:NewTransmission("Thousand.ogg", 0.55, self.soundpath, nil, 0.1)
    end 
    if tonumber(CLOUDCEIL0100)>0 then
      self.radioqueue:Number2Transmission(CLOUDCEIL0100)
      self.radioqueue:NewTransmission("Hundred.ogg", 0.47, self.soundpath, nil, 0.1)
    end
    self.radioqueue:NewTransmission("Feet.ogg", 0.45, self.soundpath, nil, 0.1)
  end
  
  -- Weather phenomena
  local wp=false
  local wpsub=""
  if precepitation==1 then
    wp=true
    wpsub=wpsub.." rain"
  elseif precepitation==2 then
    if wp then
      wpsub=wpsub..","
    end
    wpsub=wpsub.." thunderstorm"
    wp=true
  end
  if fog then
    if wp then
      wpsub=wpsub..","
    end  
    wpsub=wpsub.." fog"
    wp=true    
  end
  if dust then
    if wp then
      wpsub=wpsub..","
    end  
    wpsub=wpsub.." dust"
    wp=true    
  end
  -- Actual output
  if wp then
    self.radioqueue:NewTransmission("WeatherPhenomena.ogg", 1.07, self.soundpath, nil, 1.0, string.format("Weather phenomena:%s", wpsub), subduration)
    if precepitation==1 then
      self.radioqueue:NewTransmission("Rain.ogg", 0.41, self.soundpath, nil, 0.5)
    elseif precepitation==2 then
      self.radioqueue:NewTransmission("ThunderStorm.ogg", 0.81, self.soundpath, nil, 0.5)
    end
    if fog then
      self.radioqueue:NewTransmission("Fog.ogg", 0.81, self.soundpath, nil, 0.5)
    end
    if dust then
      self.radioqueue:NewTransmission("Dust.ogg", 0.81, self.soundpath, nil, 0.5)    
    end  
  end  
  
  -- Altimeter QFE.
  self.radioqueue:NewTransmission("Altimeter.ogg", 0.7, self.soundpath, nil, 1.0, string.format("Altimeter QNH %s.%s, QFE %s.%s inHg", QNH[1], QNH[2], QFE[1], QFE[2]), subduration)
  self.radioqueue:NewTransmission("QNH.ogg", 0.70, self.soundpath, nil, 0.5)
  self.radioqueue:Number2Transmission(QNH[1])
  self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QNH[2])
  self.radioqueue:NewTransmission("QFE.ogg", 0.62, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QFE[1])
  self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QFE[2])
  self.radioqueue:NewTransmission("InchesOfMercury.ogg", 1.16, self.soundpath, nil, 0.1)
  
  -- Temperature
  self.radioqueue:NewTransmission("Temperature.ogg", 0.55, self.soundpath, nil, 1.0, string.format("Temperature %s C", TEMPERATURE), subduration)
  self.radioqueue:Number2Transmission(TEMPERATURE)
  self.radioqueue:NewTransmission("DegreesCelsius.ogg", 1.28, self.soundpath, nil, 0.2)
  
  -- Wind
  local subtitle=string.format("Wind from %s at %s knots", WINDFROM, WINDSPEED)
  if turbulence>0 then
    subtitle=subtitle..", gusting"
  end
  self.radioqueue:NewTransmission("WindFrom.ogg", 0.60, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:Number2Transmission(WINDFROM)
  self.radioqueue:NewTransmission("At.ogg", 0.40, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(WINDSPEED)
  self.radioqueue:NewTransmission("Knots.ogg", 0.60, self.soundpath, nil, 0.2)
  if turbulence>0 then
    self.radioqueue:NewTransmission("Gusting.ogg", 0.55, self.soundpath, nil, 0.2)
  end
  
  -- Active runway.
  local subtitle=string.format("Active runway %s", runway)
  if rleft then
    subtitle=subtitle.." Left"
  elseif rright then
    subtitle=subtitle.." Right"
  end
  self.radioqueue:NewTransmission("ActiveRunway.ogg", 1.05, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:Number2Transmission(runway)
  if rleft then
    self.radioqueue:NewTransmission("Left.ogg", 0.53, self.soundpath, nil, 0.2)
  elseif rright then
    self.radioqueue:NewTransmission("Right.ogg", 0.43, self.soundpath, nil, 0.2)
  end
  
  -- Tower frequency.
  if self.towerfrequency then
    local freqs=""
    for i,freq in pairs(self.towerfrequency) do
      freqs=freqs..string.format("%.3f MHz", freq)
      if i<#self.towerfrequency then
        freqs=freqs..", "
      end
    end
    self.radioqueue:NewTransmission("TowerFrequency.ogg", 1.19, self.soundpath, nil, 1.0, string.format("Tower frequency %s", freqs), subduration)
    for _,freq in pairs(self.towerfrequency) do
      local f=string.format("%.3f", freq)
      f=UTILS.Split(f, ".")      
      self.radioqueue:Number2Transmission(f[1], nil, 0.5)
      self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
      self.radioqueue:Number2Transmission(f[2])
      self.radioqueue:NewTransmission("MegaHertz.ogg", 0.86, self.soundpath, nil, 0.2)
    end    
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get static weather of this mission from env.mission.weather.
-- @param #ATIS self
-- @return #table Clouds table which has entries "thickness", "density", "base", "iprecptns".
-- @return #number Visibility distance in meters.
-- @return #number Ground turbulence in m/s. 
-- @return #table Fog table, which has entries "thickness", "visibility" or nil if fog is disabled in the mission.
-- @return #number Dust density or nil if dust is disabled in the mission.
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
  
  local turbulence=weather.groundTurbulence

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

  self:T("FF weather:")
  self:T({clouds=clouds})
  self:T({visibility=visibility})
  self:T({turbulence=turbulence})
  self:T({fog=fog})
  self:T({dust=dust})
  return clouds, visibility, turbulence, fog, dust
end

--- Get rounded hundreds of a number.
-- @param #ATIS self
-- @param #number n Number, e.g. 4359.
-- @return #number Thousands of n, e.g. 4 for 4359.
function ATIS:_GetHundreds(n)
  local h=UTILS.Round(n/100 % 10, 0)
  if h==10 then
    h=0
  end
  return h 
end

--- Get thousands of a number.
-- @param #ATIS self
-- @param #number n Number, e.g. 4359.
-- @return #number Thousands of n, e.g. 4 for 4359.
function ATIS:_GetThousands(n)
  local h=UTILS.Round(n/100 % 10, 0)
  local t=math.floor(n/1000 % 10)
  if h==10 then
    t=t+1
  end
  return t
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
