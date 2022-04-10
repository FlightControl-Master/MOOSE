--- **Sound** - Sound output classes.
--
-- ===
-- 
-- ## Features:
-- 
--   * Create a SOUNDFILE object (mp3 or ogg) to be played via DCS or SRS transmissions
--   * Create a SOUNDTEXT object for text-to-speech output vis SRS Simple-Text-To-Speech (STTS)
-- 
-- ===
-- 
-- ### Author: **funkyfranky**
-- 
-- ===
-- 
-- There are two classes, SOUNDFILE and SOUNDTEXT, defined in this section that deal with playing
-- sound files or arbitrary text (via SRS Simple-Text-To-Speech), respectively.
-- 
-- The SOUNDFILE and SOUNDTEXT objects can be defined and used in other MOOSE classes.
-- 
-- 
-- @module Sound.SoundOutput
-- @image Sound_SoundOutput.png

do -- Sound Base

  --- @type SOUNDBASE
  -- @field #string ClassName Name of the class.
  -- @extends Core.Base#BASE


  --- Basic sound output inherited by other classes suche as SOUNDFILE and SOUNDTEXT.
  -- 
  -- This class is **not** meant to be used by "ordinary" users.
  -- 
  -- @field #SOUNDBASE
  SOUNDBASE={
    ClassName   = "SOUNDBASE",
  }
  
  --- Constructor to create a new SOUNDBASE object.
  -- @param #SOUNDBASE self
  -- @return #SOUNDBASE self
  function SOUNDBASE:New()
  
    -- Inherit BASE.
    local self=BASE:Inherit(self, BASE:New()) -- #SOUNDBASE

    

    return self
  end
  
  --- Function returns estimated speech time in seconds.
  -- Assumptions for time calc: 100 Words per min, avarage of 5 letters for english word so
  -- 
  --   * 5 chars * 100wpm = 500 characters per min = 8.3 chars per second
  --   
  -- So lengh of msg / 8.3 = number of seconds needed to read it. rounded down to 8 chars per sec map function:
  -- 
  -- * (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  -- 
  -- @param #string Text The text string to analyze.
  -- @param #number Speed Speed factor. Default 1.
  -- @param #boolean isGoogle If true, google text-to-speech is used.
  function SOUNDBASE:GetSpeechTime(length,speed,isGoogle)
  
    local maxRateRatio = 3 
  
    speed = speed or 1.0
    isGoogle = isGoogle or false
  
    local speedFactor = 1.0
    if isGoogle then
        speedFactor = speed
    else
        if speed ~= 0 then
            speedFactor = math.abs(speed) * (maxRateRatio - 1) / 10 + 1
        end
        if speed < 0 then
            speedFactor = 1/speedFactor
        end
    end
  
    -- Words per minute.
    local wpm = math.ceil(100 * speedFactor)
    
    -- Characters per second.
    local cps = math.floor((wpm * 5)/60)
  
    if type(length) == "string" then
        length = string.len(length)
    end
  
    return math.ceil(length/cps)
  end  
  
end


do -- Sound File

  --- @type SOUNDFILE
  -- @field #string ClassName Name of the class
  -- @field #string filename Name of the flag.
  -- @field #string path Directory path, where the sound file is located. This includes the final slash "/".
  -- @field #string duration Duration of the sound file in seconds.
  -- @field #string subtitle Subtitle of the transmission.
  -- @field #number subduration Duration in seconds how long the subtitle is displayed.
  -- @field #boolean useSRS If true, sound file is played via SRS. Sound file needs to be on local disk not inside the miz file!
  -- @extends Core.Base#BASE


  --- Sound files used by other classes.
  -- 
  -- # The SOUNDFILE Concept
  --   
  -- A SOUNDFILE object hold the important properties that are necessary to play the sound file, e.g. its file name, path, duration.
  -- 
  -- It can be created with the @{#SOUNDFILE.New}(*FileName*, *Path*, *Duration*) function:
  -- 
  --     local soundfile=SOUNDFILE:New("My Soundfile.ogg", "Sound File/", 3.5)
  -- 
  -- ## SRS
  -- 
  -- If sound files are supposed to be played via SRS, you need to use the @{#SOUNDFILE.SetPlayWithSRS}() function.
  -- 
  -- # Location/Path
  -- 
  -- ## DCS
  -- 
  -- DCS can only play sound files that are located inside the mission (.miz) file. In particular, DCS cannot make use of files that are stored on
  -- your hard drive.
  -- 
  -- The default location where sound files are stored in DCS is the directory "l10n/DEFAULT/". This is where sound files are placed, if they are
  -- added via the mission editor (TRIGGERS-->ACTIONS-->SOUND TO ALL). Note however, that sound files which are not added with a trigger command,
  -- will be deleted each time the mission is saved! Therefore, this directory is not ideal to be used especially if many sound files are to
  -- be included since for each file a trigger action needs to be created. Which is cumbersome, to say the least.
  -- 
  -- The recommended way is to create a new folder inside the mission (.miz) file (a miz file is essentially zip file and can be opened, e.g., with 7-Zip)
  -- and to place the sound files in there. Sound files in these folders are not wiped out by DCS on the next save.
  -- 
  -- ## SRS
  -- 
  -- SRS sound files need to be located on your local drive (not inside the miz). Therefore, you need to specify the full path.
  -- 
  -- @field #SOUNDFILE
  SOUNDFILE={
    ClassName   = "SOUNDFILE",
    filename    =  nil,
    path        = "l10n/DEFAULT/",
    duration    =    3,
    subtitle    =   nil,
    subduration =   0,
    useSRS      = false,
  }
  
  --- Constructor to create a new SOUNDFILE object.
  -- @param #SOUNDFILE self
  -- @param #string FileName The name of the sound file, e.g. "Hello World.ogg".
  -- @param #string Path The path of the directory, where the sound file is located. Default is "l10n/DEFAULT/" within the miz file.
  -- @param #number Duration Duration in seconds, how long it takes to play the sound file. Default is 3 seconds.
  -- @return #SOUNDFILE self
  function SOUNDFILE:New(FileName, Path, Duration)
  
    -- Inherit BASE.
    local self=BASE:Inherit(self, BASE:New()) -- #SOUNDFILE

    -- Set file name.
    self:SetFileName(FileName)
    
    -- Set path.
    self:SetPath(Path)
    
    -- Set duration.
    self:SetDuration(Duration)
    
    -- Debug info:
    self:T(string.format("New SOUNDFILE: file name=%s, path=%s", self.filename, self.path))

    return self
  end
  
  --- Set path, where the sound file is located.
  -- @param #SOUNDFILE self
  -- @param #string Path Path to the directory, where the sound file is located. In case this is nil, it defaults to the DCS mission temp directory.
  -- @return #SOUNDFILE self
  function SOUNDFILE:SetPath(Path)
    
    -- Init path.
    self.path=Path or "l10n/DEFAULT/"
    
    if not Path and self.useSRS then -- use path to mission temp dir
      self.path = os.getenv('TMP') .. "\\DCS\\Mission\\l10n\\DEFAULT"
    end    
    
    -- Remove (back)slashes.
    local nmax=1000 ; local n=1
    while (self.path:sub(-1)=="/" or self.path:sub(-1)==[[\]]) and n<=nmax do
      self.path=self.path:sub(1,#self.path-1)
      n=n+1
    end
    
    -- Append slash.
    self.path=self.path.."/"
          
    return self
  end  

  --- Get path of the directory, where the sound file is located.
  -- @param #SOUNDFILE self
  -- @return #string Path.
  function SOUNDFILE:GetPath()
    local path=self.path or "l10n/DEFAULT/"
    return path
  end

  --- Set sound file name. This must be a .ogg or .mp3 file!
  -- @param #SOUNDFILE self
  -- @param #string FileName Name of the file. Default is "Hello World.mp3".
  -- @return #SOUNDFILE self
  function SOUNDFILE:SetFileName(FileName)
    --TODO: check that sound file is really .ogg or .mp3
    self.filename=FileName or "Hello World.mp3"
    return self
  end

  --- Get the sound file name.
  -- @param #SOUNDFILE self
  -- @return #string Name of the soud file. This does *not* include its path.
  function SOUNDFILE:GetFileName()    
    return self.filename
  end


  --- Set duration how long it takes to play the sound file.
  -- @param #SOUNDFILE self
  -- @param #string Duration Duration in seconds. Default 3 seconds.
  -- @return #SOUNDFILE self
  function SOUNDFILE:SetDuration(Duration)
    self.duration=Duration or 3
    return self
  end  

  --- Get duration how long the sound file takes to play.
  -- @param #SOUNDFILE self
  -- @return #number Duration in seconds.
  function SOUNDFILE:GetDuration()
    return self.duration or 3
  end

  --- Get the complete sound file name inlcuding its path.
  -- @param #SOUNDFILE self
  -- @return #string Name of the sound file.
  function SOUNDFILE:GetName()
    local path=self:GetPath()
    local filename=self:GetFileName()
    local name=string.format("%s%s", path, filename)
    return name
  end
  
  --- Set whether sound files should be played via SRS.
  -- @param #SOUNDFILE self
  -- @param #boolean Switch If true or nil, use SRS. If false, use DCS transmission.
  -- @return #SOUNDFILE self
  function SOUNDFILE:SetPlayWithSRS(Switch)
    if Switch==true or Switch==nil then
      self.useSRS=true
    else
      self.useSRS=false
    end
    return self
  end  
  
end

do -- Text-To-Speech

  --- @type SOUNDTEXT
  -- @field #string ClassName Name of the class
  -- @field #string text Text to speak.
  -- @field #number duration Duration in seconds.
  -- @field #string gender Gender: "male", "female".
  -- @field #string culture Culture, e.g. "en-GB".
  -- @field #string voice Specific voice to use. Overrules `gender` and `culture` settings.
  -- @extends Core.Base#BASE


  --- Text-to-speech objects for other classes.
  -- 
  -- # The SOUNDTEXT Concept
  -- 
  -- A SOUNDTEXT object holds all necessary information to play a general text via SRS Simple-Text-To-Speech.
  -- 
  -- It can be created with the @{#SOUNDTEXT.New}(*Text*, *Duration*) function.
  --   
  --   * @{#SOUNDTEXT.New}(*Text, Duration*): Creates a new SOUNDTEXT object.
  --
  -- # Options
  -- 
  -- ## Gender
  -- 
  -- You can choose a gender ("male" or "femal") with the @{#SOUNDTEXT.SetGender}(*Gender*) function.
  -- Note that the gender voice needs to be installed on your windows machine for the used culture (see below).
  -- 
  -- ## Culture
  -- 
  -- You can choose a "culture" (accent) with the @{#SOUNDTEXT.SetCulture}(*Culture*) function, where the default (SRS) culture is "en-GB".
  -- 
  -- Other examples for culture are: "en-US" (US accent), "de-DE" (German), "it-IT" (Italian), "ru-RU" (Russian), "zh-CN" (Chinese).
  -- 
  -- Note that the chosen culture needs to be installed on your windows machine. 
  --
  -- ## Specific Voice
  -- 
  -- You can use a specific voice for the transmission with the @{SOUNDTEXT.SetVoice}(*VoiceName*) function. Here are some examples
  --
  -- * Name: Microsoft Hazel Desktop, Culture: en-GB,  Gender: Female, Age: Adult, Desc: Microsoft Hazel Desktop - English (Great Britain)
  -- * Name: Microsoft David Desktop, Culture: en-US,  Gender: Male, Age: Adult, Desc: Microsoft David Desktop - English (United States)
  -- * Name: Microsoft Zira Desktop, Culture: en-US,  Gender: Female, Age: Adult, Desc: Microsoft Zira Desktop - English (United States)
  -- * Name: Microsoft Hedda Desktop, Culture: de-DE,  Gender: Female, Age: Adult, Desc: Microsoft Hedda Desktop - German
  -- * Name: Microsoft Helena Desktop, Culture: es-ES,  Gender: Female, Age: Adult, Desc: Microsoft Helena Desktop - Spanish (Spain)
  -- * Name: Microsoft Hortense Desktop, Culture: fr-FR,  Gender: Female, Age: Adult, Desc: Microsoft Hortense Desktop - French
  -- * Name: Microsoft Elsa Desktop, Culture: it-IT,  Gender: Female, Age: Adult, Desc: Microsoft Elsa Desktop - Italian (Italy)
  -- * Name: Microsoft Irina Desktop, Culture: ru-RU,  Gender: Female, Age: Adult, Desc: Microsoft Irina Desktop - Russian
  -- * Name: Microsoft Huihui Desktop, Culture: zh-CN,  Gender: Female, Age: Adult, Desc: Microsoft Huihui Desktop - Chinese (Simplified)
  -- 
  -- Note that this must be installed on your windos machine. Also note that this overrides any culture and gender settings.
  -- 
  -- @field #SOUNDTEXT
  SOUNDTEXT={
    ClassName   = "SOUNDTEXT",
  }
  
  --- Constructor to create a new SOUNDTEXT object.
  -- @param #SOUNDTEXT self
  -- @param #string Text The text to speak.
  -- @param #number Duration Duration in seconds, how long it takes to play the text. Default is 3 seconds.
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:New(Text, Duration)
  
    -- Inherit BASE.
    local self=BASE:Inherit(self, BASE:New()) -- #SOUNDTEXT

    self:SetText(Text)
    self:SetDuration(Duration or STTS.getSpeechTime(Text))
    --self:SetGender()
    --self:SetCulture()
    
    -- Debug info:
    self:T(string.format("New SOUNDTEXT: text=%s, duration=%.1f sec", self.text, self.duration))

    return self
  end
  
  --- Set text.
  -- @param #SOUNDTEXT self
  -- @param #string Text Text to speak. Default "Hello World!".
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:SetText(Text)
    
    self.text=Text or "Hello World!"
                  
    return self
  end
  
  --- Set duration, how long it takes to speak the text.
  -- @param #SOUNDTEXT self
  -- @param #number Duration Duration in seconds. Default 3 seconds.
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:SetDuration(Duration)
    
    self.duration=Duration or 3
                  
    return self
  end    
  
  --- Set gender.
  -- @param #SOUNDTEXT self
  -- @param #string Gender Gender: "male" or "female" (default).
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:SetGender(Gender)
    
    self.gender=Gender or "female"
                  
    return self
  end
  
  --- Set TTS culture - local for the voice.
  -- @param #SOUNDTEXT self
  -- @param #string Culture TTS culture. Default "en-GB".
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:SetCulture(Culture)
    
    self.culture=Culture or "en-GB"
                  
    return self
  end    
  
  --- Set to use a specific voice name.
  -- See the list from `DCS-SR-ExternalAudio.exe --help` or if using google see [google voices](https://cloud.google.com/text-to-speech/docs/voices).
  -- @param #SOUNDTEXT self
  -- @param #string VoiceName Voice name. Note that this will overrule `Gender` and `Culture`.
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:SetVoice(VoiceName)
    
    self.voice=VoiceName
                  
    return self
  end
  
end