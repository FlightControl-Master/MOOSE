--- This module contains the MESSAGE class.
-- 
-- 1) @{Radio#RADIO} class, extends @{Base#BASE}
-- =================================================
-- Radio system to manage radio communications
-- Radio transmissions consist of sound files that are broadcasted on a specific channel and modulation 
-- If sent by a UNIT or a GROUP, Radio communications can be subtitled for a specific amount of time
-- 
-- 1.1) RADIO construction methods
-- -------------------------------
-- RADIO is created with @{Radio#RADIO.New}. This doesn't broadcast a transmission, but only create a RADIO object
-- It should only be used internally. To create a RADIO object, please use @{Positionable#POSITIONABLE.GetRadio}
-- To actually broadcast your transmission, you need to use @{Radio#RADIO.Broadcast}
--   
-- @module Radio
-- @author Grey-Echo

--- The RADIO class
-- @type RADIO
-- @extends Core.Base#BASE
RADIO = {
    ClassName = "RADIO",
    Positionable,
    FileName = "",
    Frequency = 0,
    Modulation = radio.modulation.AM,
    Subtitle = "",
    SubtitleDuration = 0,
    Power = 100,
    Loop = 0,   
}

--- Create a new RADIO Object. This doesn't broadcast a transmission, though, use @{#RADIO.Broadcast} to actually broadcast
-- @param Wrapper.Positionable#POSITIONABLE Positionable
-- @return #RADIO Radio
-- @return #nil If Positionable is invalid
-- @usage
-- -- If you want to create a RADIO, you probably should use @{Wrapper.Positionable#POSITIONABLE.GetRadio} instead
function RADIO:New(positionable)
    local self = BASE:Inherit( self, BASE:New() )
    self:F(positionable)
    if positionable:GetPointVec2() ~= nil then -- It's stupid, but the only way I found to make sure positionable is valid
      self.Positionable = positionable
      return self
    else
      self:E({"The passed positionable is invalid, no RADIO created", positionable})
      return nil
    end
end

--- Check validity of the filename passed and sets RADIO.FileName
-- @param #RADIO self
-- @param #string fileName Filename of the sound
-- @return self
-- @usage
function RADIO:SetFileName(filename)
  self:F(filename)
  if type(filename) == "string" then
    if filename:find(".ogg") ~= nil or filename:find(".wav") ~= nil then
      if filename:find("l10n/DEFAULT/") == nil then
       filename = "l10n/DEFAULT/" .. filename
       self.FileName = filename
       return self
      end
    end
  end
  self:E({"File name invalid. Maybe something wrong with the extension ?", self.FileName})
  return self
end

--- Check validity of the frequency passed and sets RADIO.Frequency
-- @param #RADIO self
-- @param #number frequency
-- @return self
-- @usage
function RADIO:SetFrequency(frequency)
  self:F(frequency)
  if type(frequency) == "number" then
    if (frequency >= 30 and frequency < 88) or (frequency >= 108 and frequency < 152) or (frequency >= 225 and frequency < 400) then 
      self.Frequency = frequency * 1000 -- Coversion in Hz
      return self
    end
  end
  self:E({"Frequency is outside of DCS Frequency ranges (30-80, 108-152, 225-400). Frequency unchanged.", self.Frequency})
  return self
end

--- Check validity of the frequency passed and sets RADIO.Modulation
-- @param #RADIO self
-- @param #number modulation
-- @return #self
-- @usage
function RADIO:SetModulation(modulation)
  self:F(modulation)
  if type(modulation) == "number" then
      if modulation == radio.modulation.AM or modulation == radio.modulation.FM then --TODO Maybe make this future proof if ED decides to add an other modulation ?
        self.Modulation = modulation
        return self
      end
  end 
  self:E({"Modulation is invalid. Use DCS's enum radio.modulation. Modulation unchanged.", self.Modulation})
  return self
end

--- Check validity of the power passed and sets RADIO.Power
-- @param #RADIO self
-- @param #number Power
-- @return #self
-- @usage
function RADIO:SetPower(power)
  self:F(power)
  if type(power) == "number" then
    if math.floor(math.abs(power)) == power then
       self.Power = power --TODO Find what is the maximum power allowed by DCS and limit power to that
       return self
     end
  end
  self:E({"Power is invalid. Power unchanged.", self.Power})
  return self
end

--- Check validity of the loop passed and sets RADIO.Loop
-- @param #RADIO self
-- @param #bool Loop
-- @return #self
-- @usage
function RADIO:SetLoop(loop)
  self:F(loop)
  if type(loop) == "boolean" then
      self.Loop = loop
      return self
  end
  self:E({"Loop is invalid. Loop unchanged.", self.Loop})
  return self
end

--- Check validity of the subtitle and the subtitleDuration  passed and sets RADIO.subtitle and RADIO.subtitleDuration
-- @param #RADIO self
-- @param #string Subtitle
-- @param #number SubtitleDuration in s
-- @return #self
-- @usage
-- -- Both parameters are mandatory, since it wouldn't make much sense to change the Subtitle and not it's duration
function RADIO:SetSubtitle(subtitle, subtitleDuration)
  self:F({subtitle, subtitleDuration})
  if type(subtitle) == "string" then
    self.Subtitle = subtitle
  else
    self.Subtitle = ""
    self:E({"Subtitle is invalid. Subtitle reset.", self.Subtitle}) 
  end
  if type(subtitleDuration) == "number" then
    if math.floor(math.abs(subtitleDuration)) == subtitleDuration then
      self.SubtitleDuration = subtitleDuration
      return self
    end
  end
  self.SubtitleDuration = 0
  self:E({"SubtitleDuration is invalid. SubtitleDuration reset.", self.SubtitleDuration})
end
--- Create a new transmission, that is to say, populate the RADIO with relevant data
-- @param self
-- @param #string Filename
-- @param #number Frequency in kHz
-- @param #number Modulation
-- @param #number Power in W
-- @return self
-- @usage
-- -- In this function the data is especially relevant if the broadcaster is anything but a UNIT or a GROUP,
-- -- but it will work with a UNIT or a GROUP anyway
-- -- Only the RADIO and the Filename are mandatory
function RADIO:NewGenericTransmission(...)
    self:F(arg)
    
    return self
end


--- Create a new transmission, that is to say, populate the RADIO with relevant data
-- @param self
-- @param #string Filename
-- @param #string Subtitle
-- @param #number SubtitleDuration in s
-- @param #number Frequency in kHz
-- @param #number Modulation
-- @param #bool Loop
-- @return self
-- @usage
-- -- In this function the data is especially relevant if the broadcaster is a UNIT or a GROUP,
-- -- but it will work for any POSITIONABLE
-- -- Only the RADIO and the Filename are mandatory 
-- -- Loop : O is no loop, 1 is loop
-- -- @TODO : Verify the type of passed args and throw errors when necessary
function RADIO:NewUnitTransmission(...)
    self:F(arg)
    
    return self
end

--- Actually Broadcast the transmission
-- @param self
-- @return self
-- @usage
-- -- This class is in fact pretty smart, it determines the right DCS function to use depending on the type of POSITIONABLE
-- -- If the POSITIONABLE is not a UNIT or a GROUP, we use the generic (but limited) trigger.action.radioTransmission()
-- -- If the POSITIONABLE is a UNIT or a GROUP, we use the "TransmitMessage" Command
-- -- In both case, you need to tell the class the name of the file to play with either @{Radio#RADIO.NewTransmission} or @{Radio#RADIO.NewTransmissionUnit}
-- -- If your POSITIONABLE is a UNIT or a GROUP, the Power is ignored.
-- -- If your POSITIONABLE is not a UNIT or a GROUP, the Subtitle, SubtitleDuration and Loop are ignored 
function RADIO:Broadcast() 
    self:F()
    -- If the POSITIONABLE is actually a Unit or a Group, use the more complicated DCS function
    if self.Positionable.ClassName == "UNIT" or self.Positionable.ClassName == "GROUP" then
        -- If the user didn't change the frequency, he wants to use the on defined in the Mission Editor.
        -- Else we set the frequency of the UNIT or the GROUP in DCS
        if self.Frequency ~= 0 then
            self.Positionable:GetDCSObject():getController():setCommand({ 
                id = "SetFrequency", 
                params = { 
                    frequency = self.Frequency, 
                    modulation = self.Modulation,
                    }
                })
        end
            
        self.Positionable:GetDCSObject():getController():setCommand({ 
            id = "TransmitMessage", 
            params = {
                file = self.FileName,
                duration = self.SubtitleDuration,
                subtitle = self.Subtitle,
                loop = self.Loop,
                } 
            })
    else
        -- If the POSITIONABLE is anything else, we revert to the general function
        trigger.action.radioTransmission(self.FileName, self.Positionable:GetPositionVec3(), self.Modulation, false, self.Frequency, self.Power)
    end
    return self
end
