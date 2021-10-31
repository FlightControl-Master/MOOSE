--- **Sound** - Simple Radio Standalone (SRS) Integration.
--
-- ===
--
-- **Main Features:**
--
--    * Play sound files via SRS
--    * Play text-to-speach via SRS
--
-- ===
--
-- ## Youtube Videos: None yet
--
-- ===
--
-- ## Missions: None yet
--
-- ===
--
-- ## Sound files: [MOOSE Sound Files](https://github.com/FlightControl-Master/MOOSE_SOUND/releases)
--
-- ===
--
-- The goal of the [SRS](https://github.com/ciribob/DCS-SimpleRadioStandalone) project is to bring VoIP communication into DCS and to make communication as frictionless as possible.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Sound.MSRS
-- @image Sound_MSRS.png

--- MSRS class.
-- @type MSRS
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table frequencies Frequencies used in the transmissions.
-- @field #table modulations Modulations used in the transmissions.
-- @field #number coalition Coalition of the transmission.
-- @field #number port Port. Default 5002.
-- @field #string name Name. Default "DCS-STTS".
-- @field #number volume Volume between 0 (min) and 1 (max). Default 1.
-- @field #string culture Culture. Default "en-GB".
-- @field #string gender Gender. Default "female".
-- @field #string voice Specifc voce.
-- @field Core.Point#COORDINATE coordinate Coordinate from where the transmission is send.
-- @field #string path Path to the SRS exe. This includes the final slash "/".
-- @field #string google Full path google credentials JSON file, e.g. "C:\Users\username\Downloads\service-account-file.json".
-- @extends Core.Base#BASE

--- *It is a very sad thing that nowadays there is so little useless information.* - Oscar Wilde
--
-- ===
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_Main.png)
--
-- # The MSRS Concept
--
-- This class allows to broadcast sound files or text via Simple Radio Standalone (SRS).
-- 
-- ## Prerequisites
-- 
-- This script needs SRS version >= 1.9.6.
-- 
-- # Play Sound Files
-- 
--     local soundfile=SOUNDFILE:New("My Soundfile.ogg", "D:\\Sounds For DCS")
--     local msrs=MSRS:New("C:\\Path To SRS", 251, radio.modulation.AM)
--     msrs:PlaySoundFile(soundfile)
-- 
-- # Play Text-To-Speech
-- 
-- Basic example:
-- 
--     -- Create a SOUNDTEXT object.
--     local text=SOUNDTEXT:New("All Enemies destroyed")
--     
--     -- MOOSE SRS 
--     local msrs=MSRS:New("D:\\DCS\\_SRS\\", 305, radio.modulation.AM)
--
--     -- Text-to speech with default voice after 2 seconds.
--     msrs:PlaySoundText(text, 2)
--
-- ## Set Gender
-- 
-- Use a specific gender with the @{#MSRS.SetGender} function, e.g. `SetGender("male")` or `:SetGender("female")`.
-- 
-- ## Set Culture
-- 
-- Use a specific "culture" with the @{#MSRS.SetCulture} function, e.g. `:SetCulture("en-US")` or `:SetCulture("de-DE")`.
-- 
-- ## Set Google
-- 
-- Use Google's text-to-speech engine with the @{#MSRS.SetGoogle} function, e.g. ':SetGoogle()'.
-- By enabling this it also allows you to utilize SSML in your text for added flexibilty.
-- For more information on setting up a cloud account, visit: https://cloud.google.com/text-to-speech
-- Google's supported SSML reference: https://cloud.google.com/text-to-speech/docs/ssml
-- 
-- ## Set Voice
-- 
-- Use a specifc voice with the @{#MSRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system.
-- If enabling SetGoogle(), you can use voices provided by Google
-- Google's supported voices: https://cloud.google.com/text-to-speech/docs/voices
-- 
-- ## Set Coordinate
-- 
-- Use @{#MSRS.SetCoordinate} to define the origin from where the transmission is broadcasted.
--
-- @field #MSRS
MSRS = {
  ClassName      =     "MSRS",
  lid            =        nil,
  port           =       5002,
  name           =     "MSRS",
  frequencies    =         {},
  modulations    =         {},
  coalition      =          0,
  gender         =   "female",
  culture        =        nil,  
  voice          =        nil,
  volume         =          1,  
  speed          =          1,
  coordinate     =        nil,
}

--- MSRS class version.
-- @field #string version
MSRS.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add functions to add/remove freqs and modulations.
-- DONE: Add coordinate.
-- DONE: Add google.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new MSRS object.
-- @param #MSRS self
-- @param #string PathToSRS Path to the directory, where SRS is located.
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz. Can also be given as a #table of multiple frequencies.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators. Can also be given as a #table of multiple modulations.
-- @return #MSRS self
function MSRS:New(PathToSRS, Frequency, Modulation)

  -- Defaults.
  Frequency =Frequency or 143
  Modulation= Modulation or radio.modulation.AM

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #MSRS
  
  self:SetPath(PathToSRS)
  self:SetPort()
  self:SetFrequencies(Frequency)
  self:SetModulations(Modulation)
  self:SetGender()
  self:SetCoalition()
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set path to SRS install directory. More precisely, path to where the DCS-
-- @param #MSRS self
-- @param #string Path Path to the directory, where the sound file is located. This does **not** contain a final backslash or slash.
-- @return #MSRS self
function MSRS:SetPath(Path)

  if Path==nil then
    self:E("ERROR: No path to SRS directory specified!")
    return nil
  end
  
  -- Set path.
  self.path=Path

  -- Remove (back)slashes.
  local n=1 ; local nmax=1000
  while (self.path:sub(-1)=="/" or self.path:sub(-1)==[[\]]) and n<=nmax do
    self.path=self.path:sub(1,#self.path-1)
    n=n+1
  end
  
  -- Debug output.
  self:T(string.format("SRS path=%s", self:GetPath()))
  
  return self
end

--- Get path to SRS directory.
-- @param #MSRS self
-- @return #string Path to the directory. This includes the final slash "/".
function MSRS:GetPath()
  return self.path
end

--- Set port.
-- @param #MSRS self
-- @param #number Port Port. Default 5002.
-- @return #MSRS self
function MSRS:SetPort(Port)
  self.port=Port or 5002
end

--- Get port.
-- @param #MSRS self
-- @return #number Port.
function MSRS:GetPort()
  return self.port
end

--- Set coalition.
-- @param #MSRS self
-- @param #number Coalition Coalition. Default 0.
-- @return #MSRS self
function MSRS:SetCoalition(Coalition)
  self.coalition=Coalition or 0
end

--- Get coalition.
-- @param #MSRS self
-- @return #number Coalition.
function MSRS:GetCoalition()
  return self.coalition
end


--- Set frequencies.
-- @param #MSRS self
-- @param #table Frequencies Frequencies in MHz. Can also be given as a #number if only one frequency should be used.
-- @return #MSRS self
function MSRS:SetFrequencies(Frequencies)

  -- Ensure table.
  if type(Frequencies)~="table" then
    Frequencies={Frequencies}
  end
  
  self.frequencies=Frequencies
  
  return self
end

--- Get frequencies.
-- @param #MSRS self
-- @param #table Frequencies in MHz.
function MSRS:GetFrequencies()
  return self.frequencies
end


--- Set modulations.
-- @param #MSRS self
-- @param #table Modulations Modulations. Can also be given as a #number if only one modulation should be used.
-- @return #MSRS self
function MSRS:SetModulations(Modulations)

  -- Ensure table.
  if type(Modulations)~="table" then
    Modulations={Modulations}
  end
  
  self.modulations=Modulations
  
  return self
end

--- Get modulations.
-- @param #MSRS self
-- @param #table Modulations.
function MSRS:GetModulations()
  return self.modulations
end

--- Set gender.
-- @param #MSRS self
-- @param #string Gender Gender: "male" or "female" (default).
-- @return #MSRS self
function MSRS:SetGender(Gender)
  
  Gender=Gender or "female"
  
  self.gender=Gender:lower()
  
  -- Debug output.
  self:T("Setting gender to "..tostring(self.gender))
  
  return self
end

--- Set culture.
-- @param #MSRS self
-- @param #string Culture Culture, e.g. "en-GB" (default).
-- @return #MSRS self
function MSRS:SetCulture(Culture)

  self.culture=Culture
  
  return self
end

--- Set to use a specific voice. Will override gender and culture settings. 
-- @param #MSRS self
-- @param #string Voice Voice.
-- @return #MSRS self
function MSRS:SetVoice(Voice)

  self.voice=Voice
  
  return self
end

--- Set the coordinate from which the transmissions will be broadcasted.
-- @param #MSRS self
-- @param Core.Point#COORDINATE Coordinate Origin of the transmission.
-- @return #MSRS self
function MSRS:SetCoordinate(Coordinate)

  self.coordinate=Coordinate
  
  return self
end

--- Use google text-to-speech.
-- @param #MSRS self
-- @param PathToCredentials Full path to the google credentials JSON file, e.g. "C:\Users\username\Downloads\service-account-file.json".
-- @return #MSRS self
function MSRS:SetGoogle(PathToCredentials)

  self.google=PathToCredentials
  
  return self
end

--- Print SRS STTS help to DCS log file.
-- @param #MSRS self
-- @return #MSRS self
function MSRS:Help()

  -- Path and exe.
  local path=self:GetPath() or STTS.DIRECTORY    
  local exe=STTS.EXECUTABLE or "DCS-SR-ExternalAudio.exe"
  
  -- Text file for output.
  local filename = os.getenv('TMP') .. "\\MSRS-help-"..STTS.uuid()..".txt"
    
  -- Print help.
  local command=string.format("%s/%s --help > %s", path, exe, filename)  
  os.execute(command)
  
  local f=assert(io.open(filename, "rb"))
  local data=f:read("*all")
  f:close()
  
  -- Print to log file.
  env.info("SRS STTS help output:")
  env.info("======================================================================")
  env.info(data)
  env.info("======================================================================")
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Transmission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Play sound file (ogg or mp3) via SRS.
-- @param #MSRS self
-- @param Sound.SoundFile#SOUNDFILE Soundfile Sound file to play.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
function MSRS:PlaySoundFile(Soundfile, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundFile, self, Soundfile, 0)
  else

    -- Sound file name.
    local soundfile=Soundfile:GetName()

    -- Get command.
    local command=self:_GetCommand()
    
    -- Append file.
    command=command.." --file="..tostring(soundfile)
    
    self:_ExecCommand(command)
    
    --[[
    
    command=command.." > bla.txt"
    
    -- Debug output.
    self:I(string.format("MSRS PlaySoundfile command=%s", command))

    -- Execute SRS command.
    local x=os.execute(command)
    
    ]]
        
  end

  return self
end

--- Play a SOUNDTEXT text-to-speech object.
-- @param #MSRS self
-- @param Sound.SoundFile#SOUNDTEXT SoundText Sound text.
-- @param #number Delay Delay in seconds, before the sound file is played.
-- @return #MSRS self
function MSRS:PlaySoundText(SoundText, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlaySoundText, self, SoundText, 0)
  else

    -- Get command.
    local command=self:_GetCommand(nil, nil, nil, SoundText.gender, SoundText.voice, SoundText.culture, SoundText.volume, SoundText.speed)
    
    -- Append text.
    command=command..string.format(" --text=\"%s\"", tostring(SoundText.text))
    
    -- Execute command.
    self:_ExecCommand(command)
    
    --[[
    command=command.." > bla.txt"
    
    -- Debug putput.
    self:I(string.format("MSRS PlaySoundfile command=%s", command))

    -- Execute SRS command.
    local x=os.execute(command)
    ]]
        
  end

  return self
end

--- Play text message via STTS.
-- @param #MSRS self
-- @param #string Text Text message.
-- @param #number Delay Delay in seconds, before the message is played.
-- @return #MSRS self
function MSRS:PlayText(Text, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayText, self, Text, 0)
  else

    -- Get command line.
    local command=self:_GetCommand()    

    -- Append text.
    command=command..string.format(" --text=\"%s\"", tostring(Text))
    
    -- Execute command.
    self:_ExecCommand(command)
    
    --[[
    
    -- Check that length of command is max 255 chars or os.execute() will not work!
    if string.len(command)>255 then
    
      -- Create a tmp file.
      local filename = os.getenv('TMP') .. "\\MSRS-"..STTS.uuid()..".bat"
      
      local script = io.open(filename, "w+")
      script:write(command.." && exit")
      script:close()
    
      -- Play command.  
      command=string.format("\"%s\"", filename)
            
      -- Play file in 0.05 seconds
      timer.scheduleFunction(os.execute, command, timer.getTime()+0.05)
      
      -- Remove file in 1 second.
      timer.scheduleFunction(os.remove, filename, timer.getTime()+1)
    else

      -- Debug output.
      self:I(string.format("MSRS Text command=%s", command))
  
      -- Execute SRS command.
      local x=os.execute(command)
    
    end    
    
    ]]
  end
  
  return self
end


--- Play text file via STTS.
-- @param #MSRS self
-- @param #string TextFile Full path to the file.
-- @param #number Delay Delay in seconds, before the message is played.
-- @return #MSRS self
function MSRS:PlayTextFile(TextFile, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MSRS.PlayTextFile, self, TextFile, 0)
  else
  
    -- First check if text file exists!
    local exists=UTILS.FileExists(TextFile)    
    if not exists then
      self:E("ERROR: MSRS Text file does not exist! File="..tostring(TextFile))
      return self
    end

    -- Get command line.    
    local command=self:_GetCommand()

    -- Append text file.
    command=command..string.format(" --textFile=\"%s\"", tostring(TextFile))
    
    -- Debug output.
    self:T(string.format("MSRS TextFile command=%s", command))
    
    -- Count length of command.
    local l=string.len(command)

    -- Execute command.
    self:_ExecCommand(command)
        
  end
  
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Execute SRS command to play sound using the `DCS-SR-ExternalAudio.exe`.
-- @param #MSRS self
-- @param #string command Command to executer
-- @return #number Return value of os.execute() command.
function MSRS:_ExecCommand(command)

    -- Create a tmp file.
    local filename=os.getenv('TMP').."\\MSRS-"..STTS.uuid()..".bat"
    
    local script=io.open(filename, "w+")
    script:write(command.." && exit")
    script:close()
      
    -- Play command.  
    command=string.format('start /b "" "%s"', filename)
    
    local res=nil
    if true then
    
      -- Create a tmp file.
      local filenvbs = os.getenv('TMP') .. "\\MSRS-"..STTS.uuid()..".vbs"
      
      -- VBS script
      local script = io.open(filenvbs, "w+")
      script:write(string.format('Dim WinScriptHost\n'))
      script:write(string.format('Set WinScriptHost = CreateObject("WScript.Shell")\n'))
      script:write(string.format('WinScriptHost.Run Chr(34) & "%s" & Chr(34), 0\n', filename))
      script:write(string.format('Set WinScriptHost = Nothing'))
      script:close()

      -- Run visual basic script. This still pops up a window but very briefly and does not put the DCS window out of focus.      
      local runvbs=string.format('cscript.exe //Nologo //B "%s"', filenvbs)
      
      -- Debug output.
      self:T("MSRS execute command="..command)
      self:T("MSRS execute VBS command="..runvbs)
            
      -- Play file in 0.01 seconds
      res=os.execute(runvbs)      
      
      -- Remove file in 1 second.
      timer.scheduleFunction(os.remove, filename, timer.getTime()+1)
      timer.scheduleFunction(os.remove, filenvbs, timer.getTime()+1)
    
    
    else

      -- Debug output.
      self:T("MSRS execute command="..command)    
            
      -- Execute command
      res=os.execute(command)
      
      -- Remove file in 1 second.
      timer.scheduleFunction(os.remove, filename, timer.getTime()+1)  
    
    end
    

  return res
end

--- Get lat, long and alt from coordinate.
-- @param #MSRS self
-- @param Core.Point#Coordinate Coordinate Coordinate. Can also be a DCS#Vec3.
-- @return #number Latitude.
-- @return #number Longitude.
-- @return #number Altitude.
function MSRS:_GetLatLongAlt(Coordinate)
  
  local lat, lon, alt=coord.LOtoLL(Coordinate)
  
  return lat, lon, math.floor(alt)
end


--- Get SRS command to play sound using the `DCS-SR-ExternalAudio.exe`.
-- @param #MSRS self
-- @param #table freqs Frequencies in MHz.
-- @param #table modus Modulations.
-- @param #number coal Coalition.
-- @param #string gender Gender.
-- @param #string voice Voice.
-- @param #string culture Culture.
-- @param #number volume Volume.
-- @param #number speed Speed.
-- @param #number port Port.
-- @return #string Command.
function MSRS:_GetCommand(freqs, modus, coal, gender, voice, culture, volume, speed, port)

  local path=self:GetPath() or STTS.DIRECTORY    
  local exe=STTS.EXECUTABLE or "DCS-SR-ExternalAudio.exe"
  freqs=table.concat(freqs or self.frequencies, ",")
  modus=table.concat(modus or self.modulations, ",")
  coal=coal or self.coalition
  gender=gender or self.gender
  voice=voice or self.voice
  culture=culture or self.culture
  volume=volume or self.volume
  speed=speed or self.speed
  port=port or self.port
  
  -- Replace modulation
  modus=modus:gsub("0", "AM")
  modus=modus:gsub("1", "FM")
  
  -- This did not work well. Stopped if the transmission was a bit longer with no apparent error.  
  --local command=string.format("%s --freqs=%s --modulations=%s --coalition=%d --port=%d --volume=%.2f --speed=%d", exe, freqs, modus, coal, port, volume, speed)

  -- Command from orig STTS script. Works better for some unknown reason!
  local command=string.format("start /min \"\" /d \"%s\" /b \"%s\" -f %s -m %s -c %s -p %s -n \"%s\" -h", path, exe, freqs, modus, coal, port, "ROBOT")
  
  --local command=string.format('start /b "" /d "%s" "%s" -f %s -m %s -c %s -p %s -n "%s" > bla.txt', path, exe, freqs, modus, coal, port, "ROBOT")
  
  -- Command.
  local command=string.format('%s/%s -f %s -m %s -c %s -p %s -n "%s"', path, exe, freqs, modus, coal, port, "ROBOT")

  -- Set voice or gender/culture.
  if voice then
    -- Use a specific voice (no need for gender and/or culture.
    command=command..string.format(" --voice=\"%s\"", tostring(voice))
  else
    -- Add gender.
    if gender and gender~="female" then
      command=command..string.format(" --gender=%s", tostring(gender))
    end
    -- Add culture.
    if culture and culture~="en-GB" then
      command=command..string.format(" -l %s", tostring(culture))
    end
  end
  
  -- Set coordinate.
  if self.coordinate then
    local lat,lon,alt=self:_GetLatLongAlt(self.coordinate)
    command=command..string.format(" -L %.4f -O %.4f -A %d", lat, lon, alt)
  end
  
  -- Set google.
  if self.google then
    command=command..string.format(' --ssml -G "%s"', self.google)
  end
  
  -- Debug output.
  self:T("MSRS command="..command)

  return command
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
