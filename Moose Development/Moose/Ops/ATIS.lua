--- **Ops** - (R2.5) - Automatic Terminal Information Service (ATIS).
-- 
-- ===
--
-- **Main Features:**
--
--    * Wind direction and speed,
--    * Visibility,
--    * Cloud coverage, base and ceiling,
--    * Temprature,
--    * Pressure QNH/QFE,
--    * Weather phenomena: rain, thunderstorm, fog, dust,
--    * Active runway based on wind direction,
--    * Tower frequencies,
--    * More than 180 voice overs,
--    * Airbase names pronounced in locale accent (russian, US, french, arabic),
--    * Option to present information in imperial or metric units.
--
-- ===
--
-- ## Youtube Videos:
--
--    * [ATIS v0.1 Caucasus - Batumi (WIP)](https://youtu.be/MdH9FmbNabo)
--    * [ATIS Airport Names Sound Check](https://youtu.be/qIE_OUQNAc0)
--    * [ATIS v0.2 Nevada - Nellis AFB (WIP)](https://youtu.be/8CT_9AoPrTk)
--    * [ATIS v0.3 Persion Gulf - Abu Dhabi/Dubai International](https://youtu.be/NjkKvPz6ovM)
--
-- ===
--
-- ## Missions: Example missions will be added later.
-- 
-- ===
-- 
-- ## Sound files: Check out the pinned messages in the Moose discord #ops-atis channel.
--
-- ===
--
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, i.e. airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
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
-- @field #number subduration Duration how long subtitles are displayed in seconds.
-- @field #boolean metric If true, use metric units. If false, use imperial (default).
-- @field #boolean PmmHg If true, give pressure in millimeters of Mercury. Default is inHg for imperial and hecto Pascal (=mili Bars) for metric units.
-- @field #boolean TDegF If true, give temperature in degrees Fahrenheit. Default is in degrees Celsius independent of chosen unit system. 
-- @field #number zuludiff Time difference local vs. zulu in hours.
-- @field #number magvar Magnetic declination/variation at the airport in degrees.
-- @extends Core.Fsm#FSM

--- Be informed!
--
-- ===
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_Main.png)
--
-- # The ATIS Concept
-- 
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, i.e. airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
-- 
-- # DCS Limitations
-- 
-- Unfortunately, the DCS API only allow to get the temperature, pressure as well as wind direction and speed. Therefore, some other information such as cloud coverage, base and ceiling are not available
-- when dynamic weather is used.
-- 
-- # Scripting
-- 
-- The lua script to create an ATIS at an airport is pretty easy:
-- 
--     -- ATIS at Batumi Airport on 143.00 MHz AM.
--     atisBatumi=ATIS:New("Batumi", 143.00)
--     atisBatumi:Start()
--     
-- The @{#ATIS.New}(*airbasename*, *frequency*) creates a new ATIS object. The parameter *airbasename* is the name of the airbase or airport. Note that this has to be spelled exactly as in the DCS mission editor.
-- The parameter *frequency* is the frequency the ATIS broadcasts in MHz.
-- 
-- Broadcasting is started via the @{#ATIS.Start}() function. The start can be delayed by useing @{#ATIS.__Start}(*delay*), where *delay* is the delay in seconds. 
-- 
-- ## Subtitles
-- 
-- Currently, DCS allows for displaying subtitles of radio transmissions only from airborne units, i.e. airplanes and helicopters. Therefore, if you want to have subtitles, it is necessary to place an 
-- additonal aircraft on the ATIS airport and set it to uncontrolled. This unit can then function as a radio relay to transmit messages with subtitles. These subtitles will only be displayed, if the
-- player has tuned in the correct ATIS frequency.
-- 
-- Radio transmissions via an airborne unit can be set via the @{#ATIS.SetRadioRelayUnitName}(*unitname*) function, where the parameter *unitname* is the name of the unit passed as string, e.g.
-- 
--     atisBatumi:SetRadioRelayUnitName("Radio Relay Batumi")
--     
-- With a unit set in the mission editor with name "Radio Relay Batumi".
-- 
-- By default, subtitles are displayed for 10 seconds. This can be changed using @{#ATIS.SetSubtitleDuration}(*duration*) with *duration* being the duration in seconds.
-- 
-- ## Active Runway
-- 
-- By default, the currently active runway is determined automatically by analysing the wind direction. Therefore, you should obviously set the wind speed to be greater zero in your mission.
-- 
-- Note however, there are a few special cases, where automatic detection does not yield the correct or desired result.
-- For example, there are airports with more than one runway facing in the same direction (usually denoted left and right). In this case, there is obviously no *unique* result depending on the wind vector.
-- 
-- If the automatic runway detection fails, the active runway can be specified manually in the script via the @{#ATIS.SetActiveRunway}(*runway*) function.
-- The parameter *runway* is a string which can be used to specify the runway heading and, if applicable, whether the left or right runway is in use.
-- 
-- For example, setting runway 21L would be
-- 
--     atisNellis:SetActiveRunway("21L")
--     
-- The script will examine the string and search for the characters "L" (left) and "R" (right).
-- 
-- If only left or right should be set and the direction determined by the wind vector, the runway heading can be left out, e.g.
-- 
--     atisAbuDhabi:SetActiveRunway("L")
-- 
-- The first two digits of the runway are determined by converting the *true* runway heading into its magnetic heading. The magnetic declination (or variation) is assumed to be constant on the given map.
-- The magnatic declinatin can also be specified for the specific airport using the @{#ATIS.SetMagneticDeclination}(*magvar*).
-- 
-- ## Tower Frequencies
-- 
-- The tower frequency (or frequencies) can also be included in the ATIS information. However, there is no way to get these automatically. Therefore, it is necessary to manually specify them in the script via the
-- @{#ATIS.SetTowerFrequencies}(*frequencies*) function. The parameter *frequencies* can be a plain number if only one frequency is necessary or it can be a table of frequencies.
-- 
-- ## Unit System
-- 
-- By default, information is given in imperial units, i.e. wind speed in knots, pressure in inches of mercury, visibility in Nautical miles, etc.
-- 
-- If you prefer metric units, you can enable this via the @{#ATIS.SetMetricUnits}() function,
-- 
--     atisBatumi:SetMetricUnits()
--     
-- With this, wind speed is given in meters per second, pressure in hecto Pascal (mbar), visibility in kilometers etc.
-- 
-- # Sound Files
-- 
-- More than 180 individual sound files have been created using a text-to-speech program. All ATIS information is given with en-US accent. 
-- 
-- Check out the pinned messages in the Moose discord #ops-atis channel.
-- 
-- To include the files, open the mission (.miz) file with, e.g., 7-zip. Then just drag-n-drop the file into the miz.
-- 
-- ![Banner Image](..\Presentations\ATIS\ATIS_SoundFolder.png)
-- 
-- **Note** that the default folder name is *ATIS Soundfiles/*. If you want to change it, you can use the @{#ATIS.SetSoundfilesPath}(*path*), where *path* is the path of the directory. This must end with a slash "/"!
-- 
-- # Examples
-- 
-- ## Caucasus: Batumi
-- 
--     -- ATIS Batumi Airport on 143.00 MHz AM.
--     atisBatumi=ATIS:New(AIRBASE.Caucasus.Batumi, 143.00)
--     atisBatumi:SetRadioRelayUnitName("Radio Relay Batumi")
--     atisBatumi:Start()
-- 
-- ## Nevada: Nellis AFB
-- 
--     -- ATIS Nellis AFB on 270.100 MHz AM.
--     atisNellis=ATIS:New(AIRBASE.Nevada.Nellis_AFB, 270.100)
--     atisNellis:SetRadioRelayUnitName("Radio Relay Nellis")
--     atisNellis:SetActiveRunway("21L")
--     atisNellis:SetTowerFrequencies({327.000, 132.550})
--     atisNellis:Start()
-- 
-- ## Persian Gulf: Abu Dhabi International Airport
--
--     atisAbuDhabi=ATIS:New(AIRBASE.PersianGulf.Abu_Dhabi_International_Airport, 125.1)
--     atisAbuDhabi:SetRadioRelayUnitName("Radio Relay Abu Dhabi International Airport")
--     atisAbuDhabi:SetMetricUnits()
--     atisAbuDhabi:SetActiveRunway("L")
--     atisAbuDhabi:Start()
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
  subduration    =   nil,
  metric         =   nil,
  PmmHg          =   nil,
  TDegF          =   nil,
  zuludiff       =   nil,
  magvar         =   nil,
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
  [14] = "Lima",
  [15] = "Mike",
  [16] = "November",
  [17] = "Oscar",
  [18] = "Papa",
  [19] = "Quebec",
  [20] = "Romeo",
  [21] = "Sierra",
  [22] = "Tango",
  [23] = "Uniform",
  [24] = "Victor",
  [25] = "Whiskey",
  [26] = "Xray",
  [27] = "Yankee",
  [28] = "Zulu",
}

--- ATIS class version.
-- @field #string version
ATIS.version="0.3.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Metric units.
-- TODO: Correct fog for elevation.
-- TODO: Set UTC correction.
-- TODO: Use local time.
-- TODO: Set magnetic variation.
-- TODO: Add stop/pause FMS functions.

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
  
  if self.airbase==nil then
    self:E("ERROR: Airbase %s for ATIS could not be found!", tostring(airbasename))
  end
  
  -- Default freq and modulation.
  self.frequency=frequency or 143.00
  self.modulation=modulation or 0
  
  -- Get map.
  self.theatre=env.mission.theatre

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ATIS %s | ", self.airbasename)
  
  -- Defaults:
  self:SetSoundfilesPath()
  self:SetSubtitleDuration()

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
  if false then
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
-- @param #string path Path for sound files. Default "ATIS Soundfiles/". Mind the slash "/" at the end!
-- @return #ATIS self
function ATIS:SetSoundfilesPath(path)
  self.soundpath=tostring(path or "ATIS Soundfiles/")
  self:I(self.lid..string.format("Setting sound files path to %s", self.soundpath))
  return self
end

--- Set airborne unit (airplane or helicopter), used to transmit radio messages including subtitles.
-- Best is to place the unit on a parking spot of the airbase and set it to *uncontrolled* in the mission editor.
-- @param #ATIS self
-- @param #string unitname Name of the unit.
-- @return #ATIS self
function ATIS:SetRadioRelayUnitName(unitname)
  self.relayunitname=unitname
  self:I(self.lid..string.format("Setting radio relay unit to %s", self.relayunitname))
  return self
end

--- Set tower frequencies.
-- @param #ATIS self
-- @param #table freqs Table of frequencies in MHz. A single frequency can be given as a plain number (i.e. must not be table).
-- @return #ATIS self
function ATIS:SetTowerFrequencies(freqs)
  if type(freqs)=="table" then
    -- nothing to do
  else  
    freqs={freqs}
  end
  self.towerfrequency=freqs
  return self
end

--- Set active runway. This can be used if the automatic runway determination via the wind direction gives incorrect results.
-- For example, use this if there are two runways with the same directions.
-- @param #ATIS self
-- @param #string runway Active runway, e.g. "31L".
-- @return #ATIS self
function ATIS:SetActiveRunway(runway)
  self.activerunway=tostring(runway)
  return self
end

--- Set duration how long subtitles are displayed.
-- @param #ATIS self
-- @param #number duration Duration in seconds. Default 10 seconds.
-- @return #ATIS self
function ATIS:SetSubtitleDuration(duration)
  self.subduration=tonumber(duration) or 10
  return self
end

--- Set unit system to metric units.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetMetricUnits()
  self.metric=true
  return self
end

--- Set unit system to imperial units.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetImperialUnits()
  self.metric=false
  return self
end

--- Set pressure unit to millimeters of mercury (mmHg).
-- Default is inHg for imperial and hPa (=mBar) for metric units. 
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetPressureMillimetersMercury()
  self.PmmHg=true
  return self
end

--- Set temperature to be given in degrees Fahrenheit.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetTemperatureFahrenheit()
  self.TDegF=true
  return self
end

--- Set magnetic declination/variation at the airport.
-- 
-- Default is per map:
-- 
-- * Caucasus +6 (East), year ~ 2011
-- * NTTR +12 (East), year ~ 2011
-- * Normandy -10 (West), year ~ 1944
-- * Persian Gulf +2 (East), year ~ 2011
-- 
-- @param #ATIS self
-- @param #number magvar Magnetic variation in degrees.
-- @return #ATIS self
function ATIS:SetMagneticDeclination(magvar)
  self.magvar=magvar
  return self
end

--- Set time local difference with respect to Zulu time.
-- Default is per map:
-- 
--    * Caucasus +4
--    * Nevada -7
--    * Normandy +1
--    * Persian Gulf +4
--    
-- @param #ATIS self
-- @param #number delta Time difference in hours.
-- @return #ATIS self
function ATIS:SetZuluTimeDifference(delta)
  self.zuludiff=delta
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start ATIS FSM.
-- @param #ATIS self
function ATIS:onafterStart(From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting ATIS v%s for airbase %s on %.3f MHz Modulation=%d", ATIS.version, self.airbasename, self.frequency, self.modulation))
  
  -- Start radio queue.
  self.radioqueue=RADIOQUEUE:New(self.frequency, self.modulation)
  
  -- Send coordinate is airbase coord.
  self.radioqueue:SetSenderCoordinate(self.airbase:GetCoordinate())
  
  -- Set relay unit if we have one.
  self.radioqueue:SetSenderUnitName(self.relayunitname)
  
  -- Init numbers.
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
  
  -- Start radio queue.
  self.radioqueue:Start(1, 0.1)

  -- Init status updates.
  self:__Status(-2)
  self:__CheckQueue(-3)
end

--- Update status.
-- @param #ATIS self
function ATIS:onafterStatus(From, Event, To)

  -- Get FSM state.
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
    self:T(self.lid..string.format("Radio queue empty. Repeating message."))
    self:Broadcast()
  else
    self:T2(self.lid..string.format("Radio queue %d transmissions queued.", #self.radioqueue.queue))
  end
  
  -- Check back in 5 seconds.
  self:__CheckQueue(5)
end

--- Broadcast ATIS radio message.
-- @param #ATIS self
function ATIS:onafterBroadcast(From, Event, To)

  -- Get current coordinate.
  local coord=self.airbase:GetCoordinate()
  
  -- Get elevation.
  local height=coord:GetLandHeight()+10
  
  ----------------
  --- Pressure ---
  ----------------
  
  -- Pressure in hPa.
  local qfe=coord:GetPressure(height)
  local qnh=coord:GetPressure(0)
  
  -- Convert to inHg.
  if self.PmmHg then
    qfe=UTILS.hPa2mmHg(qfe)
    qnh=UTILS.hPa2mmHg(qnh)
  else  
    if not self.metric then
      qfe=UTILS.hPa2inHg(qfe)
      qnh=UTILS.hPa2inHg(qnh)
    end
  end
        
  local QFE=UTILS.Split(string.format("%.2f", qfe), ".")
  local QNH=UTILS.Split(string.format("%.2f", qnh), ".")

  if self.PmmHg then
    QFE=UTILS.Split(string.format("%.1f", qfe), ".")
    QNH=UTILS.Split(string.format("%.1f", qnh), ".")
  else
    if self.metric then
      QFE=UTILS.Split(string.format("%.1f", qfe), ".")
      QNH=UTILS.Split(string.format("%.1f", qnh), ".")
    end
  end
  
  --------------
  --- Runway ---
  --------------
  
  -- Get runway based on wind direction.
  local runway=self.airbase:GetActiveRunway(self.magvar).idx
  
  -- Left or right in case there are two runways with the same heading.
  local rleft=false
  local rright=false
  
  -- Check if user explicitly specified a runway.
  if self.activerunway then
    local runwayno=self.activerunway:gsub("%D+", "")
    if runwayno~="" then
      runway=runwayno
    end
    rleft=self.activerunway:lower():find("l")
    rright=self.activerunway:lower():find("r")
  end
  
  ------------
  --- Wind ---
  ------------
  
  -- Get wind direction and speed in m/s.
  local windFrom, windSpeed=coord:GetWind(height)
  
  
  local WINDFROM=string.format("%03d", windFrom)
  local WINDSPEED=string.format("%d", UTILS.MpsToKnots(windSpeed))
  
  if self.metric then
    WINDSPEED=string.format("%d", windSpeed)
  end
  
  ------------
  --- Time ---
  ------------
  local time=timer.getAbsTime()
  
  -- Conversion to Zulu time.
  if self.zuludiff then
    -- User specified.
    time=time-self.zuludiff*60*60
  else
    if self.theatre==DCSMAP.Caucasus then
      time=time-4*60*60  -- Caucasus UTC+4 hours
    elseif self.theatre==DCSMAP.PersianGulf then
      time=time-4*60*60  -- Abu Dhabi UTC+4 hours
    elseif self.theatre==DCSMAP.NTTR then
      time=time+7*60*60  -- Las Vegas UTC-7 hours
    elseif self.theatre==DCSMAP.Normandy then
      time=time-1*60*60  -- Calais UTC+1 hour
    end
  end
  
  local clock=UTILS.SecondsToClock(time)
  local zulu=UTILS.Split(clock, ":")
  local ZULU=string.format("%s%s", zulu[1], zulu[2])
  
  
  -- NATO time stamp. 0=Alfa, 1=Bravo, 2=Charlie, etc.
  local NATO=ATIS.Alphabet[tonumber(zulu[1])+1]
  
  -- Debug.
  self:T3(string.format("clock=%s", tostring(clock)))
  self:T3(string.format("zulu1=%s", tostring(zulu[1])))
  self:T3(string.format("zulu2=%s", tostring(zulu[2])))
  self:T3(string.format("ZULU =%s", tostring(ZULU)))
  self:T3(string.format("NATO =%s", tostring(NATO)))
  
  -------------------
  --- Temperature ---
  -------------------
  
  -- Temperature in �C.
  local temperature=coord:GetTemperature(height)
  
  local TEMPERATURE=string.format("%d", temperature)
  
  if self.TDegF then
    TEMPERATURE=string.format("%d", UTILS.CelciusToFarenheit(temperature))
  end
  
  ---------------
  --- Weather ---
  ---------------
  
  -- Get mission weather info. Most of this is static.
  local clouds, visibility, turbulence, fog, dust, static=self:GetMissionWeather()
  
  -- Check that fog is actually "thick" enough to reach the airport. If an airport is in the mountains, fog might not affect it as it is measured from sea level.
  if fog and fog.thickness<height then
    fog=nil
  end
  
  -- Dust only up to 1500 ft = 457 m ASL.
  if dust and height>UTILS.FeetToMeters(1500) then
    dust=nil
  end

  ------------------
  --- Visibility ---
  ------------------
  
  -- Get min visibility.
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
  
  -- Visibility in NM.
  local VISIBILITY=string.format("%d", UTILS.Round(UTILS.MetersToNM(visibilitymin)))
  
  -- Visibility in km.
  if self.metric then
    VISIBILITY=string.format("%d", UTILS.Round(visibilitymin/1000))
  end
  
  --------------
  --- Clouds ---
  --------------
  
  local cloudbase=clouds.base
  local cloudceil=clouds.base+clouds.thickness
  local clouddens=clouds.density
  
  -- Precepitation: 0=None, 1=Rain, 2=Thunderstorm.
  local precepitation=tonumber(clouds.iprecptns)
  
  local CLOUDBASE=string.format("%d", UTILS.MetersToFeet(cloudbase))
  local CLOUDCEIL=string.format("%d", UTILS.MetersToFeet(cloudceil))
  
  if self.metric then
    CLOUDBASE=string.format("%d", cloudbase)
    CLOUDCEIL=string.format("%d", cloudceil)
  end
  
  -- Cloud base/ceiling in thousands and hundrets of ft/meters.
  local CLOUDBASE1000, CLOUDBASE0100=self:_GetThousandsAndHundreds(UTILS.MetersToFeet(cloudbase))
  local CLOUDCEIL1000, CLOUDCEIL0100=self:_GetThousandsAndHundreds(UTILS.MetersToFeet(cloudceil))
  
  if self.metric then
    CLOUDBASE1000, CLOUDBASE0100=self:_GetThousandsAndHundreds(cloudbase)
    CLOUDCEIL1000, CLOUDCEIL0100=self:_GetThousandsAndHundreds(cloudceil)
  end
  
  -- No cloud info for dynamic weather.
  local CLOUDSogg="CloudsNotAvailable.ogg"
  local CLOUDSsub="Cloud coverage information not available"
  local CLOUDSdur=2.40
  
  -- Only valid for static weather.
  if static then
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
  
  local subduration=self.subduration
  local subtitle=""
  
  --Airbase name
  subtitle=string.format("%s", self.airbasename)
  if self.airbasename:find("AFB")==nil and self.airbasename:find("Airport")==nil and self.airbasename:find("Airstrip")==nil and self.airbasename:find("airfield")==nil and self.airbasename:find("AB")==nil then
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
  if self.metric then
    subtitle=string.format("Visibility %s km", VISIBILITY)
  else
    subtitle=string.format("Visibility %s NM", VISIBILITY)
  end
  self.radioqueue:NewTransmission("Visibility.ogg", 0.8, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:Number2Transmission(VISIBILITY)
  if self.metric then
    self.radioqueue:NewTransmission("Kilometers.ogg", 0.78, self.soundpath, nil, 0.2)
  else
    self.radioqueue:NewTransmission("NauticalMiles.ogg", 1.05, self.soundpath, nil, 0.2)    
  end
  
  -- Cloud base
  self.radioqueue:NewTransmission(CLOUDSogg, CLOUDSdur, self.soundpath, nil, 1.0, CLOUDSsub, subduration)
  if CLOUDBASE and static then
    -- Base
    if self.metric then
      subtitle=string.format("Cloudbase %s, ceiling %s meters", CLOUDBASE, CLOUDCEIL)
    else
      subtitle=string.format("Cloudbase %s, ceiling %s ft", CLOUDBASE, CLOUDCEIL)
    end
    self.radioqueue:NewTransmission("CloudBase.ogg", 0.81, self.soundpath, nil, 1.0, subtitle, subduration)
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
    if self.metric then
      self.radioqueue:NewTransmission("Meters.ogg", 0.59, self.soundpath, nil, 0.1)
    else
      self.radioqueue:NewTransmission("Feet.ogg", 0.45, self.soundpath, nil, 0.1)
    end
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
  
  -- Altimeter QNH/QFE.
  if self.PmmHg then
    subtitle=string.format("Altimeter QNH %s.%s, QFE %s.%s mmHg", QNH[1], QNH[2], QFE[1], QFE[2])
  else  
    if self.metric then
      subtitle=string.format("Altimeter QNH %s.%s, QFE %s.%s hPa", QNH[1], QNH[2], QFE[1], QFE[2])
    else
      subtitle=string.format("Altimeter QNH %s.%s, QFE %s.%s inHg", QNH[1], QNH[2], QFE[1], QFE[2])
    end
  end
  self.radioqueue:NewTransmission("Altimeter.ogg", 0.7, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:NewTransmission("QNH.ogg", 0.70, self.soundpath, nil, 0.5)
  self.radioqueue:Number2Transmission(QNH[1])
  self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QNH[2])
  self.radioqueue:NewTransmission("QFE.ogg", 0.62, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QFE[1])
  self.radioqueue:NewTransmission("Decimal.ogg", 0.58, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(QFE[2])
  if self.PmmHg then
    self.radioqueue:NewTransmission("MillimetersOfMercury.ogg", 1.53, self.soundpath, nil, 0.1)
  else
    if self.metric then
      self.radioqueue:NewTransmission("HectoPascal.ogg", 1.15, self.soundpath, nil, 0.1)
    else
      self.radioqueue:NewTransmission("InchesOfMercury.ogg", 1.16, self.soundpath, nil, 0.1)
    end
  end
  
  -- Temperature
  if self.TDegF then
    subtitle=string.format("Temperature %s °F", TEMPERATURE)
  else
    subtitle=string.format("Temperature %s °C", TEMPERATURE)
  end
  self.radioqueue:NewTransmission("Temperature.ogg", 0.55, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:Number2Transmission(TEMPERATURE)
  if self.TDegF then
    self.radioqueue:NewTransmission("DegreesFahrenheit.ogg", 1.23, self.soundpath, nil, 0.2)
  else
    self.radioqueue:NewTransmission("DegreesCelsius.ogg", 1.28, self.soundpath, nil, 0.2)
  end
  
  -- Wind
  if self.metric then
    subtitle=string.format("Wind from %s at %s m/s", WINDFROM, WINDSPEED)
  else
    subtitle=string.format("Wind from %s at %s knots", WINDFROM, WINDSPEED)
  end
  if turbulence>0 then
    subtitle=subtitle..", gusting"
  end
  self.radioqueue:NewTransmission("WindFrom.ogg", 0.60, self.soundpath, nil, 1.0, subtitle, subduration)
  self.radioqueue:Number2Transmission(WINDFROM)
  self.radioqueue:NewTransmission("At.ogg", 0.40, self.soundpath, nil, 0.2)
  self.radioqueue:Number2Transmission(WINDSPEED)
  if self.metric then
    self.radioqueue:NewTransmission("MetersPerSecond.ogg", 1.14, self.soundpath, nil, 0.2)
  else
    self.radioqueue:NewTransmission("Knots.ogg", 0.60, self.soundpath, nil, 0.2)
  end
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

--- Get weather of this mission from env.mission.weather variable.
-- @param #ATIS self
-- @return #table Clouds table which has entries "thickness", "density", "base", "iprecptns".
-- @return #number Visibility distance in meters.
-- @return #number Ground turbulence in m/s. 
-- @return #table Fog table, which has entries "thickness", "visibility" or nil if fog is disabled in the mission.
-- @return #number Dust density or nil if dust is disabled in the mission.
-- @return #boolean static If true, static weather is used. If false, dynamic weather is used.
function ATIS:GetMissionWeather()

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
  
  -- 0=static, 1=dynamic
  local static=weather.atmosphere_type==0

  -- Visibilty distance in meters.
  local visibility=weather.visibility.distance
  
  -- Ground turbulence.
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
  self:T({static=static})
  return clouds, visibility, turbulence, fog, dust, static
end


--- Get thousands of a number.
-- @param #ATIS self
-- @param #number n Number, e.g. 4359.
-- @return #string Thousands of n, e.g. "4" for 4359.
-- @return #string Hundreds of n, e.g. "4" for 4359 because its rounded.
function ATIS:_GetThousandsAndHundreds(n)

  local N=UTILS.Round(n/1000, 1)
  
  local S=UTILS.Split(string.format("%.1f", N), ".")
  
  local t=S[1]
  local h=S[2]
  
  return t, h
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
