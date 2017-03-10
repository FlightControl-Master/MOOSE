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
-- It should only be used internally. To create a RADIO object, please use @{Identifiable#IDENIFIABLE.GetRadio}
-- To actually broadcast your transmission, you need to use @{Radio#RADIO.Broadcast}
--   
-- @module Radio
-- @author Grey-Echo

--- The RADIO class
-- @type RADIO
-- @extends Core.Base#BASE
MESSAGE = {
    ClassName = "RADIO",
    Identifiable = IDENTIFIABLE:New(),
    FileName = "",
    Frequency = 255000,
    Power = 100,
    Modulation = 0,
    Loop = 0,
    Subtitle = "",
    SubtitleDuration = ""
}

-- @TODO Manage Trace in all functions below

--- Create a new RADIO Object. This doesn't broadcast a transmission, though, use @{Radio#RADIO.Broadcast} to actually broadcast
-- @param self
-- @param #IDENTIFIABLE Identifiable
-- @return self
-- @usage
-- -- If you want to create a RADIO, you probably should use @{Identifiable#IDENIFIABLE.GetRadio}
function RADIO:New(identifiable)
    local self = BASE:Inherit( self, BASE:New() )
    -- self:F( { MessageText, MessageDuration, MessageCategory } )
    
    self.Identifiable = identifiable
    return self
end

--- Add the 'l10n/DEFAULT/' in the file name if necessary
-- @param #string File name
-- @return #string Corrected file name
-- @usage
-- -- internal use only
function RADIO.VerifyFileName(filename)
    if filename:find("l10n/DEFAULT/") == nil then
        filename = "l10n/DEFAULT/" .. filename
    end 
    return filename
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
function RADIO:NewTransmission(filename, frequency, mod, power)
    self.FileName = RADIO.VerifyFile(filename)
    if frequency ~= nil then
        self.Frequecy = frequency * 1000 -- Convert to Hz
    end
    if mod ~= nil then
        self.Modulation = mod
    end
    if power ~= nil then
        self.Power = power
    end
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
-- -- but it will work for any IDENTIFIABLE
-- -- Only the RADIO and the Filename are mandatory 
-- -- Loop : O is no loop, 1 is loop
function RADIO:NewTransmissionUnit(filename, subtitle, subtitleDuraction, frequency, mod, loop)
    self.FileName = RADIO.VerifyFile(filename)
    if subtitle ~= nil then
        self.Subtitle = subtitle
    end 
    if subtitleDuration ~= nil then
        self.SubtitleDuration = subtitleDuration
    end
    if frequency ~= nil then
        self.Frequecy = frequency * 1000 -- Convert to Hz
    end
    if mod ~= nil then
        self.Modulation = mod
    end
    if loop ~= nil then
        self.Loop = loop
    end
    return self
end

