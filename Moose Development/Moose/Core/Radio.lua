--- **Core** - The RADIO class is responsible for **transmitting radio communications**.
--
-- --- bitmap
-- 
-- ===
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
-- Due to weird DCS quirks, **radio communications behave differently** if sent by a @{Unit#UNIT} or a @{Group#GROUP} or by any other @{Positionable#POSITIONABLE}
-- 
--   * If the transmitter is a @{Unit#UNIT} or a @{Group#GROUP}, DCS will set the power of the transmission  automatically,
--   * If the transmitter is any other @{Positionable#POSITIONABLE}, the transmisison can't be subtitled or looped.
--   
-- Note that obviously, the **frequency** and the **modulation** of the transmission are important only if the players are piloting an **Advanced System Modelling** enabled aircraft,
-- like the A10C or the Mirage 2000C. They will **hear the transmission** if they are tuned on the **right frequency and modulation** (and if they are close enough - more on that below).
-- If a FC3 airacraft is used, it will **hear every communication, whatever the frequency and the modulation** is set to.
--
-- ===
--
-- ### Authors: Hugues "Grey_Echo" Bousquet
--
-- @module Radio

--- # 1) RADIO class, extends @{Base#BASE}
-- 
-- ## 1.1) RADIO usage
-- 
-- There are 3 steps to a successful radio transmission.
-- 
--   * First, you need to **"add" a @{#RADIO} object** to your @{Positionable#POSITIONABLE}. This is done using the @{Positionable#POSITIONABLE.GetRadio}() function,
--   * Then, you will **set the relevant parameters** to the transmission (see below),
--   * When done, you can actually **broadcast the transmission** (i.e. play the sound) with the @{Positionable#POSITIONABLE.Broadcast}() function.
--   
-- Methods to set relevant parameters for both a @{Unit#UNIT} or a @{Group#GROUP} or any other @{Positionable#POSITIONABLE}
-- 
--   * @{#RADIO.SetFileName}() : Sets the file name of your sound file (e.g. "Noise.ogg"),
--   * @{#RADIO.SetFrequency}() : Sets the frequency of your transmission,
--   * @{#RADIO.SetModulation}() : Sets the modulation of your transmission.
-- 
-- Additional Methods to set relevant parameters if the transmiter is a @{Unit#UNIT} or a @{Group#GROUP}
-- 
--   * @{#RADIO.SetLoop}() : Choose if you want the transmission to be looped,
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
--   * If your transmission is sent by a @{Positionable#POSITIONABLE} other than a @{Unit#UNIT} or a @{Group#GROUP}, you can set the power of the antenna,
--   * Otherwise, DCS sets it automatically, depending on what's available on your Unit,
--   * If the player gets **too far** from the transmiter, or if the antenna is **too weak**, the transmission will **fade** and **become noisyer**,
--   * This an automated DCS calculation you have no say on,
--   * For reference, a standard VOR station has a 100W antenna, a standard AA TACAN has a 120W antenna, and civilian ATC's antenna usually range between 300 and 500W,
--   * Note that if the transmission has a subtitle, it will be readable, regardless of the quality of the transmission. 
--   
-- @type RADIO
-- @field Wrapper.Positionable#POSITIONABLE Positionable The transmiter
-- @field #string FileName Name of the sound file
-- @field #number Frequency Frequency of the transmission in Hz
-- @field #number Modulation Modulation of the transmission (either radio.modulation.AM or radio.modulation.FM)
-- @field #string Subtitle Subtitle of the transmission
-- @field #number SubtitleDuration Duration of the Subtitle in seconds
-- @field #number Power Power of the antenna is Watts
-- @field #boolean Loop 
-- @extends Core.Base#BASE
RADIO = {
  ClassName = "RADIO",
  FileName = "",
  Frequency = 0,
  Modulation = radio.modulation.AM,
  Subtitle = "",
  SubtitleDuration = 0,
  Power = 100,
  Loop = 0,
}

--- Create a new RADIO Object. This doesn't broadcast a transmission, though, use @{#RADIO.Broadcast} to actually broadcast
-- @param #RADIO self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Positionable} that will receive radio capabilities.
-- @return #RADIO Radio
-- @return #nil If Positionable is invalid
-- @usage
-- -- If you want to create a RADIO, you probably should use @{Positionable#POSITIONABLE.GetRadio}() instead
function RADIO:New(Positionable)
  local self = BASE:Inherit( self, BASE:New() ) -- Core.Radio#RADIO
  
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
-- @param #RADIO self
-- @param #string Subtitle
-- @param #number SubtitleDuration in s
-- @return #RADIO self
-- @usage
-- -- Both parameters are mandatory, since it wouldn't make much sense to change the Subtitle and not its duration
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
-- @param #RADIO self
-- @param #string FileName
-- @param #number Frequency in MHz
-- @param #number Modulation either radio.modulation.AM or radio.modulation.FM
-- @param #number Power in W
-- @return #RADIO self
-- @usage
-- -- In this function the data is especially relevant if the broadcaster is anything but a UNIT or a GROUP,
-- but it will work with a UNIT or a GROUP anyway
-- -- Only the RADIO and the Filename are mandatory
function RADIO:NewGenericTransmission(FileName, Frequency, Modulation, Power)
  self:F({FileName, Frequency, Modulation, Power})
  
  self:SetFileName(FileName)
  if Frequency then self:SetFrequency(Frequency) end
  if Modulation then self:SetModulation(Modulation) end
  if Power then self:SetPower(Power) end
  
  return self
end


--- Create a new transmission, that is to say, populate the RADIO with relevant data
-- @param #RADIO self
-- @param #string FileName
-- @param #string Subtitle
-- @param #number SubtitleDuration in s
-- @param #number Frequency in MHz
-- @param #number Modulation either radio.modulation.AM or radio.modulation.FM
-- @param #boolean Loop
-- @return #RADIO self
-- @usage
-- -- In this function the data is especially relevant if the broadcaster is a UNIT or a GROUP,
-- but it will work for any POSITIONABLE
-- -- Only the RADIO and the Filename are mandatory
function RADIO:NewUnitTransmission(FileName, Subtitle, SubtitleDuration, Frequency, Modulation, Loop)
  self:F({FileName, Subtitle, SubtitleDuration, Frequency, Modulation, Loop})

  self:SetFileName(FileName)
  if Subtitle then self:SetSubtitle(Subtitle) end
  if SubtitleDuration then self:SetSubtitleDuration(SubtitleDuration) end
  if Frequency then self:SetFrequency(Frequency) end
  if Modulation then self:SetModulation(Modulation) end
  if Loop then self:SetLoop(Loop) end
  
  return self
end

--- Actually Broadcast the transmission
-- @param #RADIO self
-- @return #RADIO self
-- @usage
-- -- The Radio has to be populated with the new transmission before broadcasting.
-- -- Please use RADIO setters or either @{Radio#RADIO.NewGenericTransmission} or @{Radio#RADIO.NewUnitTransmission}
-- -- This class is in fact pretty smart, it determines the right DCS function to use depending on the type of POSITIONABLE
-- -- If the POSITIONABLE is not a UNIT or a GROUP, we use the generic (but limited) trigger.action.radioTransmission()
-- -- If the POSITIONABLE is a UNIT or a GROUP, we use the "TransmitMessage" Command
-- -- If your POSITIONABLE is a UNIT or a GROUP, the Power is ignored.
-- -- If your POSITIONABLE is not a UNIT or a GROUP, the Subtitle, SubtitleDuration and Loop are ignored
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
    self:T2("Broadcasting from a POSITIONABLE")
    trigger.action.radioTransmission(self.FileName, self.Positionable:GetPositionVec3(), self.Modulation, false, self.Frequency, self.Power)
  end
  return self
end

--- Stops a transmission
-- @param #RADIO self
-- @return #RADIO self
-- @usage
-- -- Especially usefull to stop the broadcast of looped transmissions
-- -- Only works with broadcasts from UNIT or GROUP
function RADIO:StopBroadcast()
  self:F()
  -- If the POSITIONABLE is a UNIT or a GROUP, stop the transmission with the DCS "StopTransmission" command 
  if self.Positionable.ClassName == "UNIT" or self.Positionable.ClassName == "GROUP" then
    self.Positionable:SetCommand({
      id = "StopTransmission",
      params = {}
    })
  else
    self:E("This broadcast can't be stopped. It's not looped either, so please wait for the end of the sound file playback")
  end
  return self
end