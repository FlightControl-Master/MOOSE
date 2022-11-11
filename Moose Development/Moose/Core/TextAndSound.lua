--- **Core** - A Moose GetText system.
--
-- ===
-- 
-- ## Main Features:
--
--    * A GetText for Moose
--    * Build a set of localized text entries, alongside their sounds and subtitles
--    * Aimed at class developers to offer localizable language support
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/).
--       
-- ===
-- 
-- ### Author: **applevangelist**
-- ## Date: April 2022
-- 
-- ===
-- 
-- @module Core.TextAndSound
-- @image MOOSE.JPG

--- Text and Sound class.
-- @type TEXTANDSOUND
-- @field #string ClassName Name of this class.
-- @field #string version Versioning.
-- @field #string lid LID for log entries.
-- @field #string locale Default locale of this object.
-- @field #table entries Table of entries.
-- @field #string textclass Name of the class the texts belong to.
-- @extends Core.Base#BASE

---
--
-- @field #TEXTANDSOUND
TEXTANDSOUND = {
  ClassName = "TEXTANDSOUND",
  version = "0.0.1",
  lid = "",
  locale = "en",
  entries = {},
  textclass = "",
}

--- Text and Sound entry.
-- @type TEXTANDSOUND.Entry
-- @field #string Classname Name of the class this entry is for.
-- @field #string Locale Locale of this entry, defaults to "en".
-- @field #table Data The list of entries.

--- Text and Sound data
-- @type TEXTANDSOUND.Data
-- @field #string ID ID of this entry for retrieval.
-- @field #string Text Text of this entry.
-- @field #string Soundfile (optional) Soundfile File name of the corresponding sound file.
-- @field #number Soundlength (optional)  Length of the sound file in seconds.
-- @field #string Subtitle (optional)  Subtitle for the sound file.

--- Instantiate a new object
-- @param #TEXTANDSOUND self
-- @param #string ClassName Name of the class this instance is providing texts for.
-- @param #string Defaultlocale (Optional) Default locale of this instance, defaults to "en". 
-- @return #TEXTANDSOUND self
function TEXTANDSOUND:New(ClassName,Defaultlocale)
    -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New())
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.ClassName, self.version)
  self.locale = Defaultlocale or (_SETTINGS:GetLocale() or "en")
  self.textclass = ClassName or "none"
  self.entries = {}
  local initentry = {} -- #TEXTANDSOUND.Entry
  initentry.Classname = ClassName
  initentry.Data = {}
  initentry.Locale = self.locale
  self.entries[self.locale] = initentry
  self:I(self.lid .. "Instantiated.")
  self:T({self.entries[self.locale]})
  return self
end

--- Add an entry
-- @param #TEXTANDSOUND self
-- @param #string Locale Locale to set for this entry, e.g. "de".
-- @param #string ID Unique(!) ID of this entry under this locale (i.e. use the same ID to get localized text for the entry in another language).
-- @param #string Text Text for this entry.
-- @param #string Soundfile (Optional) Sound file name for this entry.
-- @param #number Soundlength (Optional) Length of the sound file in seconds.
-- @param #string Subtitle (Optional) Subtitle to be used alongside the sound file.
-- @return #TEXTANDSOUND self
function TEXTANDSOUND:AddEntry(Locale,ID,Text,Soundfile,Soundlength,Subtitle)
  self:T(self.lid .. "AddEntry")
  local locale = Locale or self.locale
  local dataentry = {} -- #TEXTANDSOUND.Data
  dataentry.ID = ID or "1"
  dataentry.Text = Text or "none"
  dataentry.Soundfile = Soundfile
  dataentry.Soundlength = Soundlength or 0
  dataentry.Subtitle = Subtitle
  if not self.entries[locale] then
    local initentry = {} -- #TEXTANDSOUND.Entry
    initentry.Classname = self.textclass -- class name entry
    initentry.Data = {} -- data array
    initentry.Locale = locale -- default locale
    self.entries[locale] = initentry
  end
  self.entries[locale].Data[ID] = dataentry
  self:T({self.entries[locale].Data})
  return self
end

--- Get an entry
-- @param #TEXTANDSOUND self
-- @param #string ID The unique ID of the data to be retrieved.
-- @param #string Locale (Optional) The locale of the text to be retrieved - defauls to default locale set with `New()`.
-- @return #string Text Text or nil if not found and no fallback.
-- @return #string Soundfile Filename or nil if not found and no fallback.
-- @return #string Soundlength Length of the sound or 0 if not found and no fallback.
-- @return #string Subtitle Text for subtitle or nil if not found and no fallback.
function TEXTANDSOUND:GetEntry(ID,Locale)
  self:T(self.lid .. "GetEntry")
  local locale = Locale or self.locale
  if not self.entries[locale] then
    -- fall back to default "en"
    locale = self.locale
  end
  local Text,Soundfile,Soundlength,Subtitle = nil, nil, 0, nil
  if self.entries[locale] then
    if self.entries[locale].Data then
      local data = self.entries[locale].Data[ID] -- #TEXTANDSOUND.Data
      if data then 
        Text = data.Text
        Soundfile = data.Soundfile
        Soundlength = data.Soundlength
        Subtitle = data.Subtitle
      elseif self.entries[self.locale].Data[ID] then
        -- no matching entry, try default
        local data = self.entries[self.locale].Data[ID]
        Text = data.Text
        Soundfile = data.Soundfile
        Soundlength = data.Soundlength
        Subtitle = data.Subtitle
      end
    end
  else
    return nil, nil, 0, nil
  end
  return Text,Soundfile,Soundlength,Subtitle
end

--- Get the default locale of this object
-- @param #TEXTANDSOUND self
-- @return #string locale
function TEXTANDSOUND:GetDefaultLocale()
  self:T(self.lid .. "GetDefaultLocale")
  return self.locale
end

--- Set default locale of this object
-- @param #TEXTANDSOUND self
-- @param #string locale
-- @return #TEXTANDSOUND self 
function TEXTANDSOUND:SetDefaultLocale(locale)
  self:T(self.lid .. "SetDefaultLocale")
  self.locale = locale or "en"
  return self
end

--- Check if a locale exists
-- @param #TEXTANDSOUND self
-- @return #boolean outcome
function TEXTANDSOUND:HasLocale(Locale)
  self:T(self.lid .. "HasLocale")
  return self.entries[Locale] and true or false
end

--- Flush all entries to the log
-- @param #TEXTANDSOUND self
-- @return #TEXTANDSOUND self
function TEXTANDSOUND:FlushToLog()
  self:I(self.lid .. "Flushing entries:")
  local text = string.format("Textclass: %s | Default Locale: %s",self.textclass, self.locale)
  for _,_entry in pairs(self.entries) do
    local entry = _entry -- #TEXTANDSOUND.Entry
    local text = string.format("Textclassname: %s | Locale: %s",entry.Classname, entry.Locale)
    self:I(text)
    for _ID,_data in pairs(entry.Data) do
      local data = _data -- #TEXTANDSOUND.Data
      local text = string.format("ID: %s\nText: %s\nSoundfile: %s With length: %d\nSubtitle: %s",tostring(_ID), data.Text or "none",data.Soundfile or "none",data.Soundlength or 0,data.Subtitle or "none")
      self:I(text)
    end
  end
  return self
end

----------------------------------------------------------------
-- End TextAndSound
----------------------------------------------------------------
