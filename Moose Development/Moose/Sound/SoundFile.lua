--- **Sound** - Sound file management.
--
-- ===
-- 
-- ## Features:
-- 
--   * Add a sound file to the 
-- 
-- ===
-- 
-- ### Author: **funkyfranky**
-- 
-- ===
-- 
-- @module Sound.Soundfile
-- @image Sound_Soundfile.png
-- 

do -- Sound File

  --- @type SOUNDFILE
  -- @field #string ClassName Name of the class
  -- @field #string filename Name of the flag.
  -- @field #string path Directory path, where the sound file is located.
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
    path        = "l10n/DEFAULT",
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
    self.filename=FileName or "Hallo World.ogg"
    
    --TODO: check that sound file is .ogg or .mp3
    
    -- Set path
    self.path=Path or "l10n/DEFAULT/"
    
    self.duration=Duration or 3
    
    -- Debug info:
    self:I(string.format("New SOUNDFILE: file name=%s, path=%s", self.filename, self.path))

    return self
  end
  
  --- Set path, where the sound file is located.
  -- @param #SOUNDFILE self
  -- @param #string Path Path to the directory, where the sound file is located.
  -- @return #SOUNDFILE self
  function SOUNDFILE:SetPath(Path)
    
    self.path=Path or "l10n/DEFAULT/"
        
    -- Remove (back)slashes.
    local nmax=1000
    local n=1
    while (self.path:sub(-1)=="/" or self.path:sub(-1)==[[\]]) and n<=nmax do
      self.path=self.path:sub(1,#self.path-1)
      n=n+1
    end
          
    return self
  end  
  

  --- Get the sound file name.
  -- @param #SOUNDFILE self
  -- @return #string Name of the soud file. This does *not* include its path.
  function SOUNDFILE:GetFileName()    
    return self.filename
  end
  
  --- Get path of the directory, where the sound file is located.
  -- @param #SOUNDFILE self
  -- @return #string Path.
  function SOUNDFILE:GetPath()
    local path=self.path or "l10n/DEFAULT"
    path=path.."/"    
    return path
  end

  --- Get the complete sound file name inlcuding its path.
  -- @param #SOUNDFILE self
  -- @return #string Name of the sound file.
  function SOUNDFILE:GetName()
    local filename=self:GetFileName()
    local path=self:GetPath()
    local name=string.format("%s/%s", path, filename)
    return name
  end
  
end