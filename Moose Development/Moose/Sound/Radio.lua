--- **Core** - Is responsible for everything that is related to radio transmission and you can hear in DCS, be it TACAN beacons, Radio transmissions.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Provide radio functionality to broadcast radio transmissions.
--   * Provide beacon functionality to assist pilots.
--
-- The Radio contains 2 classes : RADIO and BEACON
--  
-- What are radio communications in DCS?
-- 
--   * Radio transmissions consist of **sound files** that are broadcasted on a specific **frequency** (e.g. 115MHz) and **modulation** (e.g. AM),
--   * They can be **subtitled** for a specific **duration**, the **power** in Watts of the transmiter's antenna can be set, and the transmission can be **looped**.
-- 
-- How to supply DCS my own Sound Files?
--   
--   * Your sound files need to be encoded in **.ogg** or .wav,
--   * Your sound files should be **as tiny as possible**. It is suggested you encode in .ogg with low bitrate and sampling settings,
--   * They need to be added in .\l10n\DEFAULT\ in you .miz file (wich can be decompressed like a .zip file),
--   * For simplicity sake, you can **let DCS' Mission Editor add the file** itself, by creating a new Trigger with the action "Sound to Country", and choosing your sound file and a country you don't use in your mission.
--   
-- Due to weird DCS quirks, **radio communications behave differently** if sent by a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP} or by any other @{Wrapper.Positionable#POSITIONABLE}
-- 
--   * If the transmitter is a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}, DCS will set the power of the transmission automatically,
--   * If the transmitter is any other @{Wrapper.Positionable#POSITIONABLE}, the transmisison can't be subtitled or looped.
--   
-- Note that obviously, the **frequency** and the **modulation** of the transmission are important only if the players are piloting an **Advanced System Modelling** enabled aircraft,
-- like the A10C or the Mirage 2000C. They will **hear the transmission** if they are tuned on the **right frequency and modulation** (and if they are close enough - more on that below).
-- If an FC3 aircraft is used, it will **hear every communication, whatever the frequency and the modulation** is set to. The same is true for TACAN beacons. If your aircraft isn't compatible,
-- you won't hear/be able to use the TACAN beacon informations.
--
-- ===
--
-- ### Authors: Hugues "Grey_Echo" Bousquet, funkyfranky
--
-- @module Core.Radio
-- @image Core_Radio.JPG


--- Models the radio capability.
-- 
-- ## RADIO usage
-- 
-- There are 3 steps to a successful radio transmission.
-- 
--   * First, you need to **"add a @{#RADIO} object** to your @{Wrapper.Positionable#POSITIONABLE}. This is done using the @{Wrapper.Positionable#POSITIONABLE.GetRadio}() function,
--   * Then, you will **set the relevant parameters** to the transmission (see below),
--   * When done, you can actually **broadcast the transmission** (i.e. play the sound) with the @{RADIO.Broadcast}() function.
--   
-- Methods to set relevant parameters for both a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP} or any other @{Wrapper.Positionable#POSITIONABLE}
-- 
--   * @{#RADIO.SetFileName}() : Sets the file name of your sound file (e.g. "Noise.ogg"),
--   * @{#RADIO.SetFrequency}() : Sets the frequency of your transmission.
--   * @{#RADIO.SetModulation}() : Sets the modulation of your transmission.
--   * @{#RADIO.SetLoop}() : Choose if you want the transmission to be looped. If you need your transmission to be looped, you might need a @{#BEACON} instead...
-- 
-- Additional Methods to set relevant parameters if the transmitter is a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}
-- 
--   * @{#RADIO.SetSubtitle}() : Set both the subtitle and its duration,
--   * @{#RADIO.NewUnitTransmission}() : Shortcut to set all the relevant parameters in one method call
-- 
-- Additional Methods to set relevant parameters if the transmitter is any other @{Wrapper.Positionable#POSITIONABLE}
-- 
--   * @{#RADIO.SetPower}() : Sets the power of the antenna in Watts
--   * @{#RADIO.NewGenericTransmission}() : Shortcut to set all the relevant parameters in one method call
-- 
-- What is this power thing?
-- 
--   * If your transmission is sent by a @{Wrapper.Positionable#POSITIONABLE} other than a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}, you can set the power of the antenna,
--   * Otherwise, DCS sets it automatically, depending on what's available on your Unit,
--   * If the player gets **too far** from the transmitter, or if the antenna is **too weak**, the transmission will **fade** and **become noisyer**,
--   * This an automated DCS calculation you have no say on,
--   * For reference, a standard VOR station has a 100 W antenna, a standard AA TACAN has a 120 W antenna, and civilian ATC's antenna usually range between 300 and 500 W,
--   * Note that if the transmission has a subtitle, it will be readable, regardless of the quality of the transmission. 
--   
-- @type RADIO
-- @field Wrapper.Controllable#CONTROLLABLE Positionable The @{#CONTROLLABLE} that will transmit the radio calls.
-- @field #string FileName Name of the sound file played.
-- @field #number Frequency Frequency of the transmission in Hz.
-- @field #number Modulation Modulation of the transmission (either radio.modulation.AM or radio.modulation.FM).
-- @field #string Subtitle Subtitle of the transmission.
-- @field #number SubtitleDuration Duration of the Subtitle in seconds.
-- @field #number Power Power of the antenna is Watts.
-- @field #boolean Loop Transmission is repeated (default true).
-- @field #string alias Name of the radio transmitter.
-- @extends Core.Base#BASE
RADIO = {
  ClassName = "RADIO",
  FileName = "",
  Frequency = 0,
  Modulation = radio.modulation.AM,
  Subtitle = "",
  SubtitleDuration = 0,
  Power = 100,
  Loop = false,
  alias=nil,
}

--- Create a new RADIO Object. This doesn't broadcast a transmission, though, use @{#RADIO.Broadcast} to actually broadcast.
-- If you want to create a RADIO, you probably should use @{Wrapper.Positionable#POSITIONABLE.GetRadio}() instead.
-- @param #RADIO self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Positionable} that will receive radio capabilities.
-- @return #RADIO The RADIO object or #nil if Positionable is invalid.
function RADIO:New(Positionable)

  -- Inherit base
  local self = BASE:Inherit( self, BASE:New() ) -- Core.Radio#RADIO
  self:F(Positionable)
  
  if Positionable:GetPointVec2() then -- It's stupid, but the only way I found to make sure positionable is valid
    self.Positionable = Positionable
    return self
  end
  
  self:E({error="The passed positionable is invalid, no RADIO created!", positionable=Positionable})
  return nil
end

--- Set alias of the transmitter.
-- @param #RADIO self
-- @param #string alias Name of the radio transmitter.
-- @return #RADIO self
function RADIO:SetAlias(alias)
  self.alias=tostring(alias)
  return self
end

--- Get alias of the transmitter.
-- @param #RADIO self
-- @return #string Name of the transmitter.
function RADIO:GetAlias()
  return tostring(self.alias)
end

--- Set the file name for the radio transmission.
-- @param #RADIO self
-- @param #string FileName File name of the sound file (i.e. "Noise.ogg")
-- @return #RADIO self
function RADIO:SetFileName(FileName)
  self:F2(FileName)
  
  if type(FileName) == "string" then
  
    if FileName:find(".ogg") or FileName:find(".wav") then
      if not FileName:find("l10n/DEFAULT/") then
        FileName = "l10n/DEFAULT/" .. FileName
      end
      
      self.FileName = FileName
      return self
    end
  end
  
  self:E({"File name invalid. Maybe something wrong with the extension?", FileName})
  return self
end

--- Set the frequency for the radio transmission.
-- If the transmitting positionable is a unit or group, this also set the command "SetFrequency" with the defined frequency and modulation.
-- @param #RADIO self
-- @param #number Frequency Frequency in MHz. Ranges allowed for radio transmissions in DCS : 30-87.995 / 108-173.995 / 225-399.975MHz.
-- @return #RADIO self
function RADIO:SetFrequency(Frequency)
  self:F2(Frequency)
  
  if type(Frequency) == "number" then
  
    -- If frequency is in range
    if (Frequency >= 30 and Frequency <= 87.995) or (Frequency >= 108 and Frequency <= 173.995) or (Frequency >= 225 and Frequency <= 399.975) then
    
      -- Convert frequency from MHz to Hz
      self.Frequency = Frequency * 1000000
            
      -- If the RADIO is attached to a UNIT or a GROUP, we need to send the DCS Command "SetFrequency" to change the UNIT or GROUP frequency
      if self.Positionable.ClassName == "UNIT" or self.Positionable.ClassName == "GROUP" then
      
        local commandSetFrequency={
          id = "SetFrequency",
          params = {
            frequency  = self.Frequency,
            modulation = self.Modulation,
          }
        }            
      
        self:T2(commandSetFrequency)
        self.Positionable:SetCommand(commandSetFrequency)
      end
      
      return self
    end
  end
  
  self:E({"Frequency is outside of DCS Frequency ranges (30-80, 108-152, 225-400). Frequency unchanged.", Frequency})
  return self
end

--- Set AM or FM modulation of the radio transmitter.
-- @param #RADIO self
-- @param #number Modulation Modulation is either radio.modulation.AM or radio.modulation.FM.
-- @return #RADIO self
function RADIO:SetModulation(Modulation)
  self:F2(Modulation)
  if type(Modulation) == "number" then
    if Modulation == radio.modulation.AM or Modulation == radio.modulation.FM then --TODO Maybe make this future proof if ED decides to add an other modulation ?
      self.Modulation = Modulation
      return self
    end
  end
  self:E({"Modulation is invalid. Use DCS's enum radio.modulation. Modulation unchanged.", self.Modulation})
  return self
end

--- Check validity of the power passed and sets RADIO.Power
-- @param #RADIO self
-- @param #number Power Power in W.
-- @return #RADIO self
function RADIO:SetPower(Power)
  self:F2(Power)
  
  if type(Power) == "number" then
    self.Power = math.floor(math.abs(Power)) --TODO Find what is the maximum power allowed by DCS and limit power to that
  else
    self:E({"Power is invalid. Power unchanged.", self.Power})
  end
  
  return self
end

--- Set message looping on or off.
-- @param #RADIO self
-- @param #boolean Loop If true, message is repeated indefinitely.
-- @return #RADIO self
function RADIO:SetLoop(Loop)
  self:F2(Loop)
  if type(Loop) == "boolean" then
    self.Loop = Loop
    return self
  end
  self:E({"Loop is invalid. Loop unchanged.", self.Loop})
  return self
end

--- Check validity of the subtitle and the subtitleDuration  passed and sets RADIO.subtitle and RADIO.subtitleDuration
-- Both parameters are mandatory, since it wouldn't make much sense to change the Subtitle and not its duration
-- @param #RADIO self
-- @param #string Subtitle
-- @param #number SubtitleDuration in s
-- @return #RADIO self
-- @usage
-- -- create the broadcaster and attaches it a RADIO
-- local MyUnit = UNIT:FindByName("MyUnit")
-- local MyUnitRadio = MyUnit:GetRadio()
-- 
-- -- add a subtitle for the next transmission, which will be up for 10s
-- MyUnitRadio:SetSubtitle("My Subtitle, 10)
function RADIO:SetSubtitle(Subtitle, SubtitleDuration)
  self:F2({Subtitle, SubtitleDuration})
  if type(Subtitle) == "string" then
    self.Subtitle = Subtitle
  else
    self.Subtitle = ""
    self:E({"Subtitle is invalid. Subtitle reset.", self.Subtitle})
  end
  if type(SubtitleDuration) == "number" then
    self.SubtitleDuration = SubtitleDuration
  else
    self.SubtitleDuration = 0
    self:E({"SubtitleDuration is invalid. SubtitleDuration reset.", self.SubtitleDuration})  
  end
  return self
end

--- Create a new transmission, that is to say, populate the RADIO with relevant data
-- In this function the data is especially relevant if the broadcaster is anything but a UNIT or a GROUP,
-- but it will work with a UNIT or a GROUP anyway. 
-- Only the #RADIO and the Filename are mandatory
-- @param #RADIO self
-- @param #string FileName Name of the sound file that will be transmitted.
-- @param #number Frequency Frequency in MHz.
-- @param #number Modulation Modulation of frequency, which is either radio.modulation.AM or radio.modulation.FM.
-- @param #number Power Power in W.
-- @return #RADIO self
function RADIO:NewGenericTransmission(FileName, Frequency, Modulation, Power, Loop)
  self:F({FileName, Frequency, Modulation, Power})
  
  self:SetFileName(FileName)
  if Frequency then self:SetFrequency(Frequency) end
  if Modulation then self:SetModulation(Modulation) end
  if Power then self:SetPower(Power) end
  if Loop then self:SetLoop(Loop) end
  
  return self
end


--- Create a new transmission, that is to say, populate the RADIO with relevant data
-- In this function the data is especially relevant if the broadcaster is a UNIT or a GROUP,
-- but it will work for any @{Wrapper.Positionable#POSITIONABLE}. 
-- Only the RADIO and the Filename are mandatory.
-- @param #RADIO self
-- @param #string FileName Name of sound file.
-- @param #string Subtitle Subtitle to be displayed with sound file.
-- @param #number SubtitleDuration Duration of subtitle display in seconds.
-- @param #number Frequency Frequency in MHz.
-- @param #number Modulation Modulation which can be either radio.modulation.AM or radio.modulation.FM
-- @param #boolean Loop If true, loop message.
-- @return #RADIO self
function RADIO:NewUnitTransmission(FileName, Subtitle, SubtitleDuration, Frequency, Modulation, Loop)
  self:F({FileName, Subtitle, SubtitleDuration, Frequency, Modulation, Loop})

  -- Set file name.
  self:SetFileName(FileName)

  -- Set modulation AM/FM.
  if Modulation then
    self:SetModulation(Modulation)
  end

  -- Set frequency.
  if Frequency then 
    self:SetFrequency(Frequency)
  end
  
  -- Set subtitle.
  if Subtitle then
    self:SetSubtitle(Subtitle, SubtitleDuration or 0)
  end
 
  -- Set Looping.
  if Loop then 
    self:SetLoop(Loop)
  end
  
  return self
end

--- Broadcast the transmission.
-- * The Radio has to be populated with the new transmission before broadcasting.
-- * Please use RADIO setters or either @{#RADIO.NewGenericTransmission} or @{#RADIO.NewUnitTransmission}
-- * This class is in fact pretty smart, it determines the right DCS function to use depending on the type of POSITIONABLE
-- * If the POSITIONABLE is not a UNIT or a GROUP, we use the generic (but limited) trigger.action.radioTransmission()
-- * If the POSITIONABLE is a UNIT or a GROUP, we use the "TransmitMessage" Command
-- * If your POSITIONABLE is a UNIT or a GROUP, the Power is ignored.
-- * If your POSITIONABLE is not a UNIT or a GROUP, the Subtitle, SubtitleDuration are ignored
-- @param #RADIO self
-- @param #boolean viatrigger Use trigger.action.radioTransmission() in any case, i.e. also for UNITS and GROUPS.
-- @return #RADIO self
function RADIO:Broadcast(viatrigger)
  self:F({viatrigger=viatrigger})
  
  -- If the POSITIONABLE is actually a UNIT or a GROUP, use the more complicated DCS command system.
  if (self.Positionable.ClassName=="UNIT" or self.Positionable.ClassName=="GROUP") and (not viatrigger) then
    self:T("Broadcasting from a UNIT or a GROUP")

    local commandTransmitMessage={
      id = "TransmitMessage",
      params = {
        file = self.FileName,
        duration = self.SubtitleDuration,
        subtitle = self.Subtitle,
        loop = self.Loop,
      }}
    
    self:T3(commandTransmitMessage)
    self.Positionable:SetCommand(commandTransmitMessage)
  else
    -- If the POSITIONABLE is anything else, we revert to the general singleton function
    -- I need to give it a unique name, so that the transmission can be stopped later. I use the class ID
    self:T("Broadcasting from a POSITIONABLE")
    trigger.action.radioTransmission(self.FileName, self.Positionable:GetPositionVec3(), self.Modulation, self.Loop, self.Frequency, self.Power, tostring(self.ID))
  end
  
  return self
end



--- Stops a transmission
-- This function is especially usefull to stop the broadcast of looped transmissions
-- @param #RADIO self
-- @return #RADIO self
function RADIO:StopBroadcast()
  self:F()
  -- If the POSITIONABLE is a UNIT or a GROUP, stop the transmission with the DCS "StopTransmission" command 
  if self.Positionable.ClassName == "UNIT" or self.Positionable.ClassName == "GROUP" then
  
    local commandStopTransmission={id="StopTransmission", params={}}
  
    self.Positionable:SetCommand(commandStopTransmission)
  else
    -- Else, we use the appropriate singleton funciton
    trigger.action.stopRadioTransmission(tostring(self.ID))
  end
  return self
end


--- After attaching a @{#BEACON} to your @{Wrapper.Positionable#POSITIONABLE}, you need to select the right function to activate the kind of beacon you want. 
-- There are two types of BEACONs available : the AA TACAN Beacon and the general purpose Radio Beacon.
-- Note that in both case, you can set an optional parameter : the `BeaconDuration`. This can be very usefull to simulate the battery time if your BEACON is
-- attach to a cargo crate, for exemple. 
-- 
-- ## AA TACAN Beacon usage
-- 
-- This beacon only works with airborne @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}. Use @{#BEACON:AATACAN}() to set the beacon parameters and start the beacon.
-- Use @#BEACON:StopAATACAN}() to stop it.
-- 
-- ## General Purpose Radio Beacon usage
-- 
-- This beacon will work with any @{Wrapper.Positionable#POSITIONABLE}, but **it won't follow the @{Wrapper.Positionable#POSITIONABLE}** ! This means that you should only use it with
-- @{Wrapper.Positionable#POSITIONABLE} that don't move, or move very slowly. Use @{#BEACON:RadioBeacon}() to set the beacon parameters and start the beacon.
-- Use @{#BEACON:StopRadioBeacon}() to stop it.
-- 
-- @type BEACON
-- @field #string ClassName Name of the class "BEACON".
-- @field Wrapper.Controllable#CONTROLLABLE Positionable The @{#CONTROLLABLE} that will receive radio capabilities.
-- @extends Core.Base#BASE
BEACON = {
  ClassName = "BEACON",
  Positionable = nil,
  name=nil,
}

--- Beacon types supported by DCS. 
-- @type BEACON.Type
-- @field #number NULL
-- @field #number VOR
-- @field #number DME
-- @field #number VOR_DME
-- @field #number TACAN TACtical Air Navigation system.
-- @field #number VORTAC
-- @field #number RSBN
-- @field #number BROADCAST_STATION
-- @field #number HOMER
-- @field #number AIRPORT_HOMER
-- @field #number AIRPORT_HOMER_WITH_MARKER
-- @field #number ILS_FAR_HOMER
-- @field #number ILS_NEAR_HOMER
-- @field #number ILS_LOCALIZER
-- @field #number ILS_GLIDESLOPE
-- @field #number PRMG_LOCALIZER
-- @field #number PRMG_GLIDESLOPE
-- @field #number ICLS Same as ICLS glideslope.
-- @field #number ICLS_LOCALIZER
-- @field #number ICLS_GLIDESLOPE
-- @field #number NAUTICAL_HOMER
BEACON.Type={
  NULL                      = 0, 
  VOR                       = 1,
  DME                       = 2,
  VOR_DME                   = 3, 
  TACAN                     = 4,
  VORTAC                    = 5, 
  RSBN                      = 128,
  BROADCAST_STATION         = 1024, 
  HOMER                     = 8,
  AIRPORT_HOMER             = 4104, 
  AIRPORT_HOMER_WITH_MARKER = 4136, 
  ILS_FAR_HOMER             = 16408,
  ILS_NEAR_HOMER            = 16424, 
  ILS_LOCALIZER             = 16640,
  ILS_GLIDESLOPE            = 16896,
  PRMG_LOCALIZER            = 33024,
  PRMG_GLIDESLOPE           = 33280,
  ICLS                      = 131584, --leaving this in here but it is the same as ICLS_GLIDESLOPE
  ICLS_LOCALIZER            = 131328,
  ICLS_GLIDESLOPE           = 131584,
  NAUTICAL_HOMER            = 65536,

}

--- Beacon systems supported by DCS. https://wiki.hoggitworld.com/view/DCS_command_activateBeacon
-- @type BEACON.System
-- @field #number PAR_10 ?
-- @field #number RSBN_5 Russian VOR/DME system.
-- @field #number TACAN TACtical Air Navigation system on ground.
-- @field #number TACAN_TANKER_X TACtical Air Navigation system for tankers on X band.
-- @field #number TACAN_TANKER_Y TACtical Air Navigation system for tankers on Y band.
-- @field #number VOR Very High Frequency Omni-Directional Range
-- @field #number ILS_LOCALIZER ILS localizer
-- @field #number ILS_GLIDESLOPE ILS glideslope.
-- @field #number PRGM_LOCALIZER PRGM localizer.
-- @field #number PRGM_GLIDESLOPE PRGM glideslope.
-- @field #number BROADCAST_STATION Broadcast station.
-- @field #number VORTAC Radio-based navigational aid for aircraft pilots consisting of a co-located VHF omnidirectional range (VOR) beacon and a tactical air navigation system (TACAN) beacon.
-- @field #number TACAN_AA_MODE_X TACtical Air Navigation for aircraft on X band.
-- @field #number TACAN_AA_MODE_Y TACtical Air Navigation for aircraft on Y band.
-- @field #number VORDME Radio beacon that combines a VHF omnidirectional range (VOR) with a distance measuring equipment (DME).
-- @field #number ICLS_LOCALIZER Carrier landing system.
-- @field #number ICLS_GLIDESLOPE Carrier landing system.
BEACON.System={
  PAR_10            = 1, 
  RSBN_5            = 2, 
  TACAN             = 3, 
  TACAN_TANKER_X    = 4,
  TACAN_TANKER_Y    = 5,
  VOR               = 6, 
  ILS_LOCALIZER     = 7, 
  ILS_GLIDESLOPE    = 8,
  PRMG_LOCALIZER    = 9,
  PRMG_GLIDESLOPE   = 10,
  BROADCAST_STATION = 11,
  VORTAC            = 12,
  TACAN_AA_MODE_X   = 13,
  TACAN_AA_MODE_Y   = 14,
  VORDME            = 15,
  ICLS_LOCALIZER    = 16,
  ICLS_GLIDESLOPE   = 17,
}

--- Create a new BEACON Object. This doesn't activate the beacon, though, use @{#BEACON.ActivateTACAN} etc.
-- If you want to create a BEACON, you probably should use @{Wrapper.Positionable#POSITIONABLE.GetBeacon}() instead.
-- @param #BEACON self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Positionable} that will receive radio capabilities.
-- @return #BEACON Beacon object or #nil if the positionable is invalid.
function BEACON:New(Positionable)

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) --#BEACON
  
  -- Debug.
  self:F(Positionable)
  
  -- Set positionable.
  if Positionable:GetPointVec2() then -- It's stupid, but the only way I found to make sure positionable is valid
    self.Positionable = Positionable
    self.name=Positionable:GetName()
    self:I(string.format("New BEACON %s", tostring(self.name)))
    return self
  end
  
  self:E({"The passed positionable is invalid, no BEACON created", Positionable})
  return nil
end


--- Activates a TACAN BEACON.
-- @param #BEACON self
-- @param #number Channel TACAN channel, i.e. the "10" part in "10Y".
-- @param #string Mode TACAN mode, i.e. the "Y" part in "10Y".
-- @param #string Message The Message that is going to be coded in Morse and broadcasted by the beacon.
-- @param #boolean Bearing If true, beacon provides bearing information. If false (or nil), only distance information is available.
-- @param #number Duration How long will the beacon last in seconds. Omit for forever.
-- @return #BEACON self
-- @usage
-- -- Let's create a TACAN Beacon for a tanker
-- local myUnit = UNIT:FindByName("MyUnit") 
-- local myBeacon = myUnit:GetBeacon() -- Creates the beacon
-- 
-- myBeacon:ActivateTACAN(20, "Y", "TEXACO", true) -- Activate the beacon
function BEACON:ActivateTACAN(Channel, Mode, Message, Bearing, Duration)
  self:T({channel=Channel, mode=Mode, callsign=Message, bearing=Bearing, duration=Duration})
  
  -- Get frequency.
  local Frequency=UTILS.TACANToFrequency(Channel, Mode)
  
  -- Check.
  if not Frequency then 
    self:E({"The passed TACAN channel is invalid, the BEACON is not emitting"})
    return self
  end
  
  -- Beacon type.
  local Type=BEACON.Type.TACAN
  
  -- Beacon system.  
  local System=BEACON.System.TACAN
  
  -- Check if unit is an aircraft and set system accordingly.
  local AA=self.Positionable:IsAir()
  if AA then
    System=5 --NOTE: 5 is how you cat the correct tanker behaviour! --BEACON.System.TACAN_TANKER
    -- Check if "Y" mode is selected for aircraft.
    if Mode~="Y" then
      self:E({"WARNING: The POSITIONABLE you want to attach the AA Tacan Beacon is an aircraft: Mode should Y !The BEACON is not emitting.", self.Positionable})
    end
  end
  
  -- Attached unit.
  local UnitID=self.Positionable:GetID()
  
  -- Debug.
  self:I({string.format("BEACON Activating TACAN %s: Channel=%d%s, Morse=%s, Bearing=%s, Duration=%s!", tostring(self.name), Channel, Mode, Message, tostring(Bearing), tostring(Duration))})
    
  -- Start beacon.
  self.Positionable:CommandActivateBeacon(Type, System, Frequency, UnitID, Channel, Mode, AA, Message, Bearing)
      
  -- Stop sheduler.
  if Duration then
    self.Positionable:DeactivateBeacon(Duration)
  end
  
  return self
end

--- Activates an ICLS BEACON. The unit the BEACON is attached to should be an aircraft carrier supporting this system.
-- @param #BEACON self
-- @param #number Channel ICLS channel.
-- @param #string Callsign The Message that is going to be coded in Morse and broadcasted by the beacon.
-- @param #number Duration How long will the beacon last in seconds. Omit for forever.
-- @return #BEACON self
function BEACON:ActivateICLS(Channel, Callsign, Duration)
  self:F({Channel=Channel, Callsign=Callsign, Duration=Duration})
  
  -- Attached unit.
  local UnitID=self.Positionable:GetID()
  
  -- Debug
  self:T2({"ICLS BEACON started!"})
    
  -- Start beacon.
  self.Positionable:CommandActivateICLS(Channel, UnitID, Callsign)
      
  -- Stop sheduler
  if Duration then -- Schedule the stop of the BEACON if asked by the MD
    self.Positionable:DeactivateBeacon(Duration)
  end
  
  return self
end






--- Activates a TACAN BEACON on an Aircraft.
-- @param #BEACON self
-- @param #number TACANChannel (the "10" part in "10Y"). Note that AA TACAN are only available on Y Channels
-- @param #string Message The Message that is going to be coded in Morse and broadcasted by the beacon
-- @param #boolean Bearing Can the BEACON be homed on ?
-- @param #number BeaconDuration How long will the beacon last in seconds. Omit for forever.
-- @return #BEACON self
-- @usage
-- -- Let's create a TACAN Beacon for a tanker
-- local myUnit = UNIT:FindByName("MyUnit") 
-- local myBeacon = myUnit:GetBeacon() -- Creates the beacon
-- 
-- myBeacon:AATACAN(20, "TEXACO", true) -- Activate the beacon
function BEACON:AATACAN(TACANChannel, Message, Bearing, BeaconDuration)
  self:F({TACANChannel, Message, Bearing, BeaconDuration})
  
  local IsValid = true
  
  if not self.Positionable:IsAir() then
    self:E({"The POSITIONABLE you want to attach the AA Tacan Beacon is not an aircraft ! The BEACON is not emitting", self.Positionable})
    IsValid = false
  end
    
  local Frequency = self:_TACANToFrequency(TACANChannel, "Y")
  if not Frequency then 
    self:E({"The passed TACAN channel is invalid, the BEACON is not emitting"})
    IsValid = false
  end
  
  -- I'm using the beacon type 4 (BEACON_TYPE_TACAN). For System, I'm using 5 (TACAN_TANKER_MODE_Y) if the bearing shows its bearing
  -- or 14 (TACAN_AA_MODE_Y) if it does not
  local System
  if Bearing then
    System = 5
  else
    System = 14
  end
  
  if IsValid then -- Starts the BEACON
    self:T2({"AA TACAN BEACON started !"})
    self.Positionable:SetCommand({
      id = "ActivateBeacon",
      params = {
        type = 4,
        system = System,
        callsign = Message,
        frequency = Frequency,
        }
      })
      
    if BeaconDuration then -- Schedule the stop of the BEACON if asked by the MD
      SCHEDULER:New(nil, 
      function()
        self:StopAATACAN()
      end, {}, BeaconDuration)
    end
  end
  
  return self
end

--- Stops the AA TACAN BEACON
-- @param #BEACON self
-- @return #BEACON self
function BEACON:StopAATACAN()
  self:F()
  if not self.Positionable then
    self:E({"Start the beacon first before stoping it !"})
  else
    self.Positionable:SetCommand({
      id = 'DeactivateBeacon', 
        params = { 
      } 
    })
  end
end


--- Activates a general pupose Radio Beacon
-- This uses the very generic singleton function "trigger.action.radioTransmission()" provided by DCS to broadcast a sound file on a specific frequency.
-- Although any frequency could be used, only 2 DCS Modules can home on radio beacons at the time of writing : the Huey and the Mi-8. 
-- They can home in on these specific frequencies : 
-- * **Mi8**
-- * R-828 -> 20-60MHz
-- * ARKUD -> 100-150MHz (canal 1 : 114166, canal 2 : 114333, canal 3 : 114583, canal 4 : 121500, canal 5 : 123100, canal 6 : 124100) AM
-- * ARK9 -> 150-1300KHz
-- * **Huey**
-- * AN/ARC-131 -> 30-76 Mhz FM
-- @param #BEACON self
-- @param #string FileName The name of the audio file
-- @param #number Frequency in MHz
-- @param #number Modulation either radio.modulation.AM or radio.modulation.FM
-- @param #number Power in W
-- @param #number BeaconDuration How long will the beacon last in seconds. Omit for forever.
-- @return #BEACON self
-- @usage
-- -- Let's create a beacon for a unit in distress.
-- -- Frequency will be 40MHz FM (home-able by a Huey's AN/ARC-131)
-- -- The beacon they use is battery-powered, and only lasts for 5 min
-- local UnitInDistress = UNIT:FindByName("Unit1")
-- local UnitBeacon = UnitInDistress:GetBeacon()
-- 
-- -- Set the beacon and start it
-- UnitBeacon:RadioBeacon("MySoundFileSOS.ogg", 40, radio.modulation.FM, 20, 5*60)
function BEACON:RadioBeacon(FileName, Frequency, Modulation, Power, BeaconDuration)
  self:F({FileName, Frequency, Modulation, Power, BeaconDuration})
  local IsValid = false
  
  -- Check the filename
  if type(FileName) == "string" then
    if FileName:find(".ogg") or FileName:find(".wav") then
      if not FileName:find("l10n/DEFAULT/") then
        FileName = "l10n/DEFAULT/" .. FileName
      end
      IsValid = true
    end
  end
  if not IsValid then
    self:E({"File name invalid. Maybe something wrong with the extension ? ", FileName})
  end
  
  -- Check the Frequency
  if type(Frequency) ~= "number" and IsValid then
    self:E({"Frequency invalid. ", Frequency})
    IsValid = false
  end
  Frequency = Frequency * 1000000 -- Conversion to Hz
  
  -- Check the modulation
  if Modulation ~= radio.modulation.AM and Modulation ~= radio.modulation.FM and IsValid then --TODO Maybe make this future proof if ED decides to add an other modulation ?
    self:E({"Modulation is invalid. Use DCS's enum radio.modulation.", Modulation})
    IsValid = false
  end
  
  -- Check the Power
  if type(Power) ~= "number" and IsValid then
    self:E({"Power is invalid. ", Power})
    IsValid = false
  end
  Power = math.floor(math.abs(Power)) --TODO Find what is the maximum power allowed by DCS and limit power to that
  
  if IsValid then
    self:T2({"Activating Beacon on ", Frequency, Modulation})
    -- Note that this is looped. I have to give this transmission a unique name, I use the class ID
    trigger.action.radioTransmission(FileName, self.Positionable:GetPositionVec3(), Modulation, true, Frequency, Power, tostring(self.ID))
    
     if BeaconDuration then -- Schedule the stop of the BEACON if asked by the MD
       SCHEDULER:New( nil, 
         function()
           self:StopRadioBeacon()
         end, {}, BeaconDuration)
     end
  end 
end

--- Stops the AA TACAN BEACON
-- @param #BEACON self
-- @return #BEACON self
function BEACON:StopRadioBeacon()
  self:F()
  -- The unique name of the transmission is the class ID
  trigger.action.stopRadioTransmission(tostring(self.ID))
  return self
end

--- Converts a TACAN Channel/Mode couple into a frequency in Hz
-- @param #BEACON self
-- @param #number TACANChannel
-- @param #string TACANMode
-- @return #number Frequecy
-- @return #nil if parameters are invalid
function BEACON:_TACANToFrequency(TACANChannel, TACANMode)
  self:F3({TACANChannel, TACANMode})

  if type(TACANChannel) ~= "number" then
    if TACANMode ~= "X" and TACANMode ~= "Y" then
      return nil -- error in arguments
    end
  end
  
-- This code is largely based on ED's code, in DCS World\Scripts\World\Radio\BeaconTypes.lua, line 137.
-- I have no idea what it does but it seems to work
  local A = 1151 -- 'X', channel >= 64
  local B = 64   -- channel >= 64
  
  if TACANChannel < 64 then
    B = 1
  end
  
  if TACANMode == 'Y' then
    A = 1025
    if TACANChannel < 64 then
      A = 1088
    end
  else -- 'X'
    if TACANChannel < 64 then
      A = 962
    end
  end
  
  return (A + TACANChannel - B) * 1000000
end


