--- **Core** - Manage user sound.
--
-- ===
-- 
-- ## Features:
-- 
--   * Play sounds wihtin running missions.
-- 
-- ===
-- 
-- Management of DCS User Sound.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module Core.UserSound
-- @image Core_Usersound.JPG

do -- UserSound

  --- @type USERSOUND
  -- @extends Core.Base#BASE


  --- Management of DCS User Sound.
  -- 
  -- ## USERSOUND constructor
  --   
  --   * @{#USERSOUND.New}(): Creates a new USERSOUND object.
  -- 
  -- @field #USERSOUND
  USERSOUND = {
    ClassName = "USERSOUND",
  }
  
  --- USERSOUND Constructor.
  -- @param #USERSOUND self
  -- @param #string UserSoundFileName The filename of the usersound.
  -- @return #USERSOUND
  function USERSOUND:New( UserSoundFileName ) --R2.3
  
    local self = BASE:Inherit( self, BASE:New() ) -- #USERSOUND

    self.UserSoundFileName = UserSoundFileName

    return self
  end


  --- Set usersound filename.
  -- @param #USERSOUND self
  -- @param #string UserSoundFileName The filename of the usersound.
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   BlueVictory:SetFileName( "BlueVictoryLoud.ogg" ) -- Set the BlueVictory to change the file name to play a louder sound.
  --   
  function USERSOUND:SetFileName( UserSoundFileName ) --R2.3
    
    self.UserSoundFileName = UserSoundFileName

    return self
  end  

  


  --- Play the usersound to all players.
  -- @param #USERSOUND self
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   BlueVictory:ToAll() -- Play the sound that Blue has won.
  --   
  function USERSOUND:ToAll() --R2.3
    
    trigger.action.outSound( self.UserSoundFileName )
    
    return self
  end  

  
  --- Play the usersound to the given coalition.
  -- @param #USERSOUND self
  -- @param DCS#coalition Coalition The coalition to play the usersound to.
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   BlueVictory:ToCoalition( coalition.side.BLUE ) -- Play the sound that Blue has won to the blue coalition.
  --   
  function USERSOUND:ToCoalition( Coalition ) --R2.3
    
    trigger.action.outSoundForCoalition(Coalition, self.UserSoundFileName )
    
    return self
  end  


  --- Play the usersound to the given country.
  -- @param #USERSOUND self
  -- @param DCS#country Country The country to play the usersound to.
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   BlueVictory:ToCountry( country.id.USA ) -- Play the sound that Blue has won to the USA country.
  --   
  function USERSOUND:ToCountry( Country ) --R2.3
    
    trigger.action.outSoundForCountry( Country, self.UserSoundFileName )
    
    return self
  end  


  --- Play the usersound to the given @{Wrapper.Group}.
  -- @param #USERSOUND self
  -- @param Wrapper.Group#GROUP Group The @{Wrapper.Group} to play the usersound to.
  -- @param #number Delay (Optional) Delay in seconds, before the sound is played. Default 0.
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   local PlayerGroup = GROUP:FindByName( "PlayerGroup" ) -- Search for the active group named "PlayerGroup", that contains a human player.
  --   BlueVictory:ToGroup( PlayerGroup ) -- Play the sound that Blue has won to the player group.
  --   
  function USERSOUND:ToGroup( Group, Delay ) --R2.3
  
    Delay=Delay or 0
    if Delay>0 then
      SCHEDULER:New(nil, USERSOUND.ToGroup,{self, Group}, Delay)      
    else
      trigger.action.outSoundForGroup( Group:GetID(), self.UserSoundFileName )
    end
    
    return self
  end  

end