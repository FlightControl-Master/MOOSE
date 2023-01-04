--- **Core** - TACAN and other beacons.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Provide beacon functionality to assist pilots.
--
-- ===
--
-- ### Authors: Hugues "Grey_Echo" Bousquet, funkyfranky
--
-- @module Core.Beacon
-- @image Core_Radio.JPG

--- *In order for the light to shine so brightly, the darkness must be present.* -- Francis Bacon
-- 
-- After attaching a @{#BEACON} to your @{Wrapper.Positionable#POSITIONABLE}, you need to select the right function to activate the kind of beacon you want. 
-- There are two types of BEACONs available : the (aircraft) TACAN Beacon and the general purpose Radio Beacon.
-- Note that in both case, you can set an optional parameter : the `BeaconDuration`. This can be very useful to simulate the battery time if your BEACON is
-- attach to a cargo crate, for example. 
-- 
-- ## Aircraft TACAN Beacon usage
-- 
-- This beacon only works with airborne @{Wrapper.Unit#UNIT} or a @{Wrapper.Group#GROUP}. Use @{#BEACON.ActivateTACAN}() to set the beacon parameters and start the beacon.
-- Use @{#BEACON.StopRadioBeacon}() to stop it.
-- 
-- ## General Purpose Radio Beacon usage
-- 
-- This beacon will work with any @{Wrapper.Positionable#POSITIONABLE}, but **it won't follow the @{Wrapper.Positionable#POSITIONABLE}** ! This means that you should only use it with
-- @{Wrapper.Positionable#POSITIONABLE} that don't move, or move very slowly. Use @{#BEACON.RadioBeacon}() to set the beacon parameters and start the beacon.
-- Use @{#BEACON.StopRadioBeacon}() to stop it.
-- 
-- @type BEACON
-- @field #string ClassName Name of the class "BEACON".
-- @field Wrapper.Controllable#CONTROLLABLE Positionable The @{Wrapper.Controllable#CONTROLLABLE} that will receive radio capabilities.
-- @extends Core.Base#BASE
BEACON = {
  ClassName    = "BEACON",
  Positionable = nil,
  name         = nil,
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
-- @field #number ILS_GLIDESLOPE ILS glide slope.
-- @field #number PRGM_LOCALIZER PRGM localizer.
-- @field #number PRGM_GLIDESLOPE PRGM glide slope.
-- @field #number BROADCAST_STATION Broadcast station.
-- @field #number VORTAC Radio-based navigational aid for aircraft pilots consisting of a co-located VHF omni-directional range (VOR) beacon and a tactical air navigation system (TACAN) beacon.
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
-- @param Wrapper.Positionable#POSITIONABLE Positionable The @{Wrapper.Positionable} that will receive radio capabilities.
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

  Mode=Mode or "Y"

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
    if Mode=="X" then
      --self:E({"WARNING: The POSITIONABLE you want to attach the AA Tacan Beacon is an aircraft: Mode should Y!", self.Positionable})
      System=BEACON.System.TACAN_TANKER_X
    else
      System=BEACON.System.TACAN_TANKER_Y
    end
  end

  -- Attached unit.
  local UnitID=self.Positionable:GetID()

  -- Debug.
  self:I({string.format("BEACON Activating TACAN %s: Channel=%d%s, Morse=%s, Bearing=%s, Duration=%s!", tostring(self.name), Channel, Mode, Message, tostring(Bearing), tostring(Duration))})

  -- Start beacon.
  self.Positionable:CommandActivateBeacon(Type, System, Frequency, UnitID, Channel, Mode, AA, Message, Bearing)

  -- Stop scheduler.
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

  -- Stop scheduler
  if Duration then -- Schedule the stop of the BEACON if asked by the MD
    self.Positionable:DeactivateBeacon(Duration)
  end

  return self
end

--- Activates a LINK4 BEACON. The unit the BEACON is attached to should be an aircraft carrier supporting this system.
-- @param #BEACON self
-- @param #number Frequency LINK4 FRequency in MHz, eg 336.
-- @param #string Morse The ID that is going to be coded in Morse and broadcasted by the beacon.
-- @param #number Duration How long will the beacon last in seconds. Omit for forever.
-- @return #BEACON self
function BEACON:ActivateLink4(Frequency, Morse, Duration)
  self:F({Frequency=Frequency, Morse=Morse, Duration=Duration})

  -- Attached unit.
  local UnitID=self.Positionable:GetID()

  -- Debug
  self:T2({"LINK4 BEACON started!"})

  -- Start beacon.
  self.Positionable:CommandActivateLink4(Frequency,UnitID,Morse)

  -- Stop sheduler
  if Duration then -- Schedule the stop of the BEACON if asked by the MD
    self.Positionable:CommandDeactivateLink4(Duration)
  end

  return self
end

--- DEPRECATED: Please use @{#BEACON.ActivateTACAN}() instead.
-- Activates a TACAN BEACON on an Aircraft.
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

  -- I'm using the beacon type 4 (BEACON_TYPE_TACAN). For System, I'm using 5 (TACAN_TANKER_MODE_Y) if the bearing shows its bearing or 14 (TACAN_AA_MODE_Y) if it does not
  local System
  if Bearing then
    System = BEACON.System.TACAN_TANKER_Y
  else
    System = BEACON.System.TACAN_AA_MODE_Y
  end

  if IsValid then -- Starts the BEACON
    self:T2({"AA TACAN BEACON started !"})
    self.Positionable:SetCommand({
      id = "ActivateBeacon",
      params = {
        type = BEACON.Type.TACAN,
        system = System,
        callsign = Message,
        AA = true,
        frequency = Frequency,
        bearing = Bearing,
        modeChannel = "Y",
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

--- Activates a general purpose Radio Beacon
-- This uses the very generic singleton function "trigger.action.radioTransmission()" provided by DCS to broadcast a sound file on a specific frequency.
-- Although any frequency could be used, only a few DCS Modules can home on radio beacons at the time of writing, i.e. the Mi-8, Huey, Gazelle etc.
-- The following e.g. can home in on these specific frequencies : 
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

--- Stops the Radio Beacon
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
