--- **Sound** - Radio transmissions.
--
-- ===
--
-- ## Features:
--
--   * Provide radio functionality to broadcast radio transmissions.
--
-- What are radio communications in DCS?
--
--   * Radio transmissions consist of **sound files** that are broadcasted on a specific **frequency** (e.g. 115MHz) and **modulation** (e.g. AM),
--   * They can be **subtitled** for a specific **duration**, the **power** in Watts of the transmitter's antenna can be set, and the transmission can be **looped**.
--
-- How to supply DCS my own Sound Files?
--
--   * Your sound files need to be encoded in **.ogg** or .wav,
--   * Your sound files should be **as tiny as possible**. It is suggested you encode in .ogg with low bitrate and sampling settings,
--   * They need to be added in .\l10n\DEFAULT\ in you .miz file (which can be decompressed like a .zip file),
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
-- you won't hear/be able to use the TACAN beacon information.
--
-- ===
--
-- ### Authors: Hugues "Grey_Echo" Bousquet, funkyfranky
--
-- @module Sound.Radio
-- @image Core_Radio.JPG


--- *It's not true I had nothing on, I had the radio on.* -- Marilyn Monroe
--
-- # RADIO usage
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
  ClassName        = "RADIO",
  FileName         = "",
  Frequency        = 0,
  Modulation       = radio.modulation.AM,
  Subtitle         = "",
  SubtitleDuration = 0,
  Power            = 100,
  Loop             = false,
  alias            = nil,
}

--- Create a new RADIO Object. This doesn't broadcast a transmission, though, use @{#RADIO.Broadcast} to actually broadcast.
-- If you want to create a RADIO, you probably should use @{Wrapper.Positionable#POSITIONABLE.GetRadio}() instead.
-- @param #RADIO self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Wrapper.Positionable#POSITIONABLE} that will receive radio capabilities.
-- @return #RADIO The RADIO object or #nil if Positionable is invalid.
function RADIO:New(Positionable)

  -- Inherit base
  local self = BASE:Inherit( self, BASE:New() ) -- Sound.Radio#RADIO
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
-- @param #number Frequency Frequency in MHz.
-- @return #RADIO self
function RADIO:SetFrequency(Frequency)
  self:F2(Frequency)

  if type(Frequency) == "number" then

    -- If frequency is in range
    --if (Frequency >= 30 and Frequency <= 87.995) or (Frequency >= 108 and Frequency <= 173.995) or (Frequency >= 225 and Frequency <= 399.975) then

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
    --end
  end

  self:E({"Frequency is not a number. Frequency unchanged.", Frequency})
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
-- This function is especially useful to stop the broadcast of looped transmissions
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
