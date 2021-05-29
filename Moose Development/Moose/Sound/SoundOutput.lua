--- **Sound** - Sound output classes.
--
-- ===
-- 
-- ## Features:
-- 
--   * Create a SOUNDFILE object (mp3 or ogg) to be played via DCS or SRS transmissions
--   * Create a SOUNDTEXT object for text-to-speech output
-- 
-- ===
-- 
-- ### Author: **funkyfranky**
-- 
-- ===
-- 
-- @module Sound.SoundOutput
-- @image Sound_SoundOutput.png

do -- Sound Base

  --- @type SOUNDBASE
  -- @field #string ClassName Name of the class.
  -- @extends Core.Base#BASE


  --- Basic sound output inherited by other classes.
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
  
end


do -- Sound File

  --- @type SOUNDFILE
  -- @field #string ClassName Name of the class
  -- @field #string filename Name of the flag.
  -- @field #string path Directory path, where the sound file is located. This includes the final slash "/".
  -- @field #string duration Duration of the sound file in seconds.
  -- @field #string subtitle Subtitle of the transmission.
  -- @field #number subduration Duration in seconds how long the subtitle is displayed.
  -- @field #boolean insideMiz If true (default), the sound file is located inside the mission .miz file.
  -- @extends Core.Base#BASE


  --- Sound files used by other classes.
  -- 
  -- # 1. USERFLAG constructor
  --   
  --   * @{#USERFLAG.New}(): Creates a new USERFLAG object.
  -- 
  -- @field #SOUNDFILE
  SOUNDFILE={
    ClassName   = "SOUNDFILE",
    filename    =  nil,
    path        = "l10n/DEFAULT/",
    duration    =    3,
    subtitle    =   nil,
    subduration =   0,
    insideMiz   = true,
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
    self:I(string.format("New SOUNDFILE: file name=%s, path=%s", self.filename, self.path))

    return self
  end
  
  --- Set path, where the sound file is located.
  -- @param #SOUNDFILE self
  -- @param #string Path Path to the directory, where the sound file is located.
  -- @return #SOUNDFILE self
  function SOUNDFILE:SetPath(Path)
    
    -- Init path.
    self.path=Path or "l10n/DEFAULT/"
        
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
  -- # Constructor
  --   
  --   * @{#SOUNDTEXT.New}(*Text, Duration*): Creates a new SOUNDTEXT object.
  --
  -- Name: Microsoft Hazel Desktop, Culture: en-GB,  Gender: Female, Age: Adult, Desc: Microsoft Hazel Desktop - English (Great Britain)
  -- Name: Microsoft David Desktop, Culture: en-US,  Gender: Male, Age: Adult, Desc: Microsoft David Desktop - English (United States)
  -- Name: Microsoft Zira Desktop, Culture: en-US,  Gender: Female, Age: Adult, Desc: Microsoft Zira Desktop - English (United States)
  -- Name: Microsoft Hedda Desktop, Culture: de-DE,  Gender: Female, Age: Adult, Desc: Microsoft Hedda Desktop - German
  -- Name: Microsoft Helena Desktop, Culture: es-ES,  Gender: Female, Age: Adult, Desc: Microsoft Helena Desktop - Spanish (Spain)
  -- Name: Microsoft Hortense Desktop, Culture: fr-FR,  Gender: Female, Age: Adult, Desc: Microsoft Hortense Desktop - French
  -- Name: Microsoft Elsa Desktop, Culture: it-IT,  Gender: Female, Age: Adult, Desc: Microsoft Elsa Desktop - Italian (Italy)
  -- Name: Microsoft Irina Desktop, Culture: ru-RU,  Gender: Female, Age: Adult, Desc: Microsoft Irina Desktop - Russian
  -- Name: Microsoft Huihui Desktop, Culture: zh-CN,  Gender: Female, Age: Adult, Desc: Microsoft Huihui Desktop - Chinese (Simplified)
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
    self:SetDuration(Duration)
    --self:SetGender()
    --self:SetCulture()
    
    -- Debug info:
    self:I(string.format("New SOUNDTEXT: text=%s, duration=%.1f sec", self.text, self.duration))

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
  
  --- Set to use a specific voice name.
  -- See the list from `DCS-SR-ExternalAudio.exe --help` or if using google see https://cloud.google.com/text-to-speech/docs/voices
  -- @param #SOUNDTEXT self
  -- @param #string Voice Voice name. Note that this will overrule `Gender` and `Culture`.
  -- @return #SOUNDTEXT self
  function SOUNDTEXT:SetVoice(Voice)
    
    self.voice=Voice
                  
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
  
end