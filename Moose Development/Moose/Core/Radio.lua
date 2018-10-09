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
-- What are radio communications in DCS ?
-- 
--   * Radio transmissions consist of **sound files** that are broadcasted on a specific **frequency** (e.g. 115MHz) and **modulation** (e.g. AM),
--   * They can be **subtitled** for a specific **duration**, the **power** in Watts of the transmiter's antenna can be set, and the transmission can be **looped**.
-- 
-- How to supply DCS my own Sound Files ?
--   
--   * Your sound files need to be encoded in **.ogg** or .wav,
--   * Your sound files should be **as tiny as possible**. It is suggested you encode in .ogg with low bitrate and sampling settings,
--   * They need to be added in .\l10n\DEFAULT\ in you .miz file (wich can be decompressed like a .zip file),
--   * For simplicty sake, you can **let DCS' Mission Editor add the file** itself, by creating a new Trigger with the action "Sound to Country", and choosing your sound file and a country you don't use in your mission.
--   
-- Due to weird DCS quirks, **radio communications behave differently** if sent by a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP} or by any other @{Wrapper.Positionable#POSITIONABLE}
-- 
--   * If the transmitter is a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}, DCS will set the power of the transmission  automatically,
--   * If the transmitter is any other @{Wrapper.Positionable#POSITIONABLE}, the transmisison can't be subtitled or looped.
--   
-- Note that obviously, the **frequency** and the **modulation** of the transmission are important only if the players are piloting an **Advanced System Modelling** enabled aircraft,
-- like the A10C or the Mirage 2000C. They will **hear the transmission** if they are tuned on the **right frequency and modulation** (and if they are close enough - more on that below).
-- If a FC3 airacraft is used, it will **hear every communication, whatever the frequency and the modulation** is set to. The same is true for TACAN beacons. If your aircaft isn't compatible,
-- you won't hear/be able to use the TACAN beacon informations.
--
-- ===
--
-- ### Author: Hugues "Grey_Echo" Bousquet
--
-- @module Core.Radio
-- @image Core_Radio.JPG


--- Models the radio capabilty.
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
-- Additional Methods to set relevant parameters if the transmiter is a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}
-- 
--   * @{#RADIO.SetSubtitle}() : Set both the subtitle and its duration,
--   * @{#RADIO.NewUnitTransmission}() : Shortcut to set all the relevant parameters in one method call
-- 
-- Additional Methods to set relevant parameters if the transmiter is any other @{Wrapper.Positionable#POSITIONABLE}
-- 
--   * @{#RADIO.SetPower}() : Sets the power of the antenna in Watts
--   * @{#RADIO.NewGenericTransmission}() : Shortcut to set all the relevant parameters in one method call
-- 
-- What is this power thing ?
-- 
--   * If your transmission is sent by a @{Wrapper.Positionable#POSITIONABLE} other than a @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}, you can set the power of the antenna,
--   * Otherwise, DCS sets it automatically, depending on what's available on your Unit,
--   * If the player gets **too far** from the transmiter, or if the antenna is **too weak**, the transmission will **fade** and **become noisyer**,
--   * This an automated DCS calculation you have no say on,
--   * For reference, a standard VOR station has a 100W antenna, a standard AA TACAN has a 120W antenna, and civilian ATC's antenna usually range between 300 and 500W,
--   * Note that if the transmission has a subtitle, it will be readable, regardless of the quality of the transmission. 
--   
-- @type RADIO
-- @field Positionable#POSITIONABLE Positionable The transmiter
-- @field #string FileName Name of the sound file
-- @field #number Frequency Frequency of the transmission in Hz
-- @field #number Modulation Modulation of the transmission (either radio.modulation.AM or radio.modulation.FM)
-- @field #string Subtitle Subtitle of the transmission
-- @field #number SubtitleDuration Duration of the Subtitle in seconds
-- @field #number Power Power of the antenna is Watts
-- @field #boolean Loop (default true)
-- @extends Core.Base#BASE
RADIO = {
  ClassName = "RADIO",
  FileName = "",
  Frequency = 0,
  Modulation = radio.modulation.AM,
  Subtitle = "",
  SubtitleDuration = 0,
  Power = 100,
  Loop = true,
}

--- Create a new RADIO Object. This doesn't broadcast a transmission, though, use @{#RADIO.Broadcast} to actually broadcast
-- If you want to create a RADIO, you probably should use @{Wrapper.Positionable#POSITIONABLE.GetRadio}() instead
-- @param #RADIO self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Positionable} that will receive radio capabilities.
-- @return #RADIO Radio
-- @return #nil If Positionable is invalid
function RADIO:New(Positionable)
  local self = BASE:Inherit( self, BASE:New() ) -- Core.Radio#RADIO
  
  self.Loop = true        -- default Loop to true (not sure the above RADIO definition actually is working)
  self:F(Positionable)
  
  if Positionable:GetPointVec2() then -- It's stupid, but the only way I found to make sure positionable is valid
    self.Positionable = Positionable
    return self
  end
  
  self:E({"The passed positionable is invalid, no RADIO created", Positionable})
  return nil
end

--- Check validity of the filename passed and sets RADIO.FileName
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
  
  self:E({"File name invalid. Maybe something wrong with the extension ?", self.FileName})
  return self
end

--- Check validity of the frequency passed and sets RADIO.Frequency
-- @param #RADIO self
-- @param #number Frequency in MHz (Ranges allowed for radio transmissions in DCS : 30-88 / 108-152 / 225-400MHz)
-- @return #RADIO self
function RADIO:SetFrequency(Frequency)
  self:F2(Frequency)
  if type(Frequency) == "number" then
    -- If frequency is in range
    if (Frequency >= 30 and Frequency < 88) or (Frequency >= 108 and Frequency < 152) or (Frequency >= 225 and Frequency < 400) then
      self.Frequency = Frequency * 1000000 -- Conversion in Hz
      -- If the RADIO is attached to a UNIT or a GROUP, we need to send the DCS Command "SetFrequency" to change the UNIT or GROUP frequency
      if self.Positionable.ClassName == "UNIT" or self.Positionable.ClassName == "GROUP" then
        self.Positionable:SetCommand({
          id = "SetFrequency",
          params = {
            frequency = self.Frequency,
            modulation = self.Modulation,
          }
        })
      end
      return self
    end
  end
  self:E({"Frequency is outside of DCS Frequency ranges (30-80, 108-152, 225-400). Frequency unchanged.", self.Frequency})
  return self
end

--- Check validity of the frequency passed and sets RADIO.Modulation
-- @param #RADIO self
-- @param #number Modulation either radio.modulation.AM or radio.modulation.FM
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
-- @param #number Power in W
-- @return #RADIO self
function RADIO:SetPower(Power)
  self:F2(Power)
  if type(Power) == "number" then
    self.Power = math.floor(math.abs(Power)) --TODO Find what is the maximum power allowed by DCS and limit power to that
    return self
  end
  self:E({"Power is invalid. Power unchanged.", self.Power})
  return self
end

--- Check validity of the loop passed and sets RADIO.Loop
-- @param #RADIO self
-- @param #boolean Loop
-- @return #RADIO self
-- @usage
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
    if math.floor(math.abs(SubtitleDuration)) == SubtitleDuration then
      self.SubtitleDuration = SubtitleDuration
      return self
    end
  end
  self.SubtitleDuration = 0
  self:E({"SubtitleDuration is invalid. SubtitleDuration reset.", self.SubtitleDuration})
end

--- Create a new transmission, that is to say, populate the RADIO with relevant data
-- In this function the data is especially relevant if the broadcaster is anything but a UNIT or a GROUP,
-- but it will work with a UNIT or a GROUP anyway. 
-- Only the #RADIO and the Filename are mandatory
-- @param #RADIO self
-- @param #string FileName
-- @param #number Frequency in MHz
-- @param #number Modulation either radio.modulation.AM or radio.modulation.FM
-- @param #number Power in W
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
-- @param #string FileName
-- @param #string Subtitle
-- @param #number SubtitleDuration in s
-- @param #number Frequency in MHz
-- @param #number Modulation either radio.modulation.AM or radio.modulation.FM
-- @param #boolean Loop
-- @return #RADIO self
function RADIO:NewUnitTransmission(FileName, Subtitle, SubtitleDuration, Frequency, Modulation, Loop)
  self:F({FileName, Subtitle, SubtitleDuration, Frequency, Modulation, Loop})

  self:SetFileName(FileName)
  local Duration = 5
  if SubtitleDuration then Duration = SubtitleDuration end
  -- SubtitleDuration argument was missing, adding it
  if Subtitle then self:SetSubtitle(Subtitle, Duration) end
  -- self:SetSubtitleDuration is non existent, removing faulty line
  -- if SubtitleDuration then self:SetSubtitleDuration(SubtitleDuration) end
  if Frequency then self:SetFrequency(Frequency) end
  if Modulation then self:SetModulation(Modulation) end
  if Loop then self:SetLoop(Loop) end
  
  return self
end

--- Actually Broadcast the transmission
-- * The Radio has to be populated with the new transmission before broadcasting.
-- * Please use RADIO setters or either @{#RADIO.NewGenericTransmission} or @{#RADIO.NewUnitTransmission}
-- * This class is in fact pretty smart, it determines the right DCS function to use depending on the type of POSITIONABLE
-- * If the POSITIONABLE is not a UNIT or a GROUP, we use the generic (but limited) trigger.action.radioTransmission()
-- * If the POSITIONABLE is a UNIT or a GROUP, we use the "TransmitMessage" Command
-- * If your POSITIONABLE is a UNIT or a GROUP, the Power is ignored.
-- * If your POSITIONABLE is not a UNIT or a GROUP, the Subtitle, SubtitleDuration are ignored
-- @param #RADIO self
-- @return #RADIO self
function RADIO:Broadcast()
  self:F()
  
  -- If the POSITIONABLE is actually a UNIT or a GROUP, use the more complicated DCS command system
  if self.Positionable.ClassName == "UNIT" or self.Positionable.ClassName == "GROUP" then
    self:T2("Broadcasting from a UNIT or a GROUP")
    self.Positionable:SetCommand({
      id = "TransmitMessage",
      params = {
        file = self.FileName,
        duration = self.SubtitleDuration,
        subtitle = self.Subtitle,
        loop = self.Loop,
      }
    })
  else
    -- If the POSITIONABLE is anything else, we revert to the general singleton function
    -- I need to give it a unique name, so that the transmission can be stopped later. I use the class ID
    self:T2("Broadcasting from a POSITIONABLE")
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
    self.Positionable:SetCommand({
      id = "StopTransmission",
      params = {}
    })
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
-- @extends Core.Base#BASE
BEACON = {
  ClassName = "BEACON",
}

--- Create a new BEACON Object. This doesn't activate the beacon, though, use @{#BEACON.AATACAN} or @{#BEACON.Generic}
-- If you want to create a BEACON, you probably should use @{Wrapper.Positionable#POSITIONABLE.GetBeacon}() instead.
-- @param #BEACON self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Positionable} that will receive radio capabilities.
-- @return #BEACON Beacon
-- @return #nil If Positionable is invalid
function BEACON:New(Positionable)
  local self = BASE:Inherit(self, BASE:New())
  
  self:F(Positionable)
  
  if Positionable:GetPointVec2() then -- It's stupid, but the only way I found to make sure positionable is valid
    self.Positionable = Positionable
    return self
  end
  
  self:E({"The passed positionable is invalid, no BEACON created", Positionable})
  return nil
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
      SCHEDULER:New( nil, 
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
end