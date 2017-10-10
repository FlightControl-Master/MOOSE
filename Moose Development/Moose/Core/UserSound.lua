--- **Core (WIP)** -- Manage user sound.
--
-- ====
-- 
-- Management of DCS User Sound.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ====
-- 
-- @module UserSound

do -- UserSound

  --- @type USERSOUND
  -- @extends Core.Base#BASE


  --- # USERSOUND class, extends @{Base#BASE}
  -- 
  -- Management of DCS User Sound.
  -- 
  -- ## 1. USERSOUND constructor
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
  -- @param Dcs.DCScoalition#coalition Coalition The coalition to play the usersound to.
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
  -- @param Dcs.DCScountry#country Country The country to play the usersound to.
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   BlueVictory:ToCountry( country.id.USA ) -- Play the sound that Blue has won to the USA country.
  --   
  function USERSOUND:ToCountry( Country ) --R2.3
    
    trigger.action.outSoundForCountry( Country, self.UserSoundFileName )
    
    return self
  end  


  --- Play the usersound to the given @{Group}.
  -- @param #USERSOUND self
  -- @param Wrapper.Group#GROUP Group The @{Group} to play the usersound to.
  -- @return #USERSOUND The usersound instance.
  -- @usage
  --   local BlueVictory = USERSOUND:New( "BlueVictory.ogg" )
  --   local PlayerGroup = GROUP:FindByName( "PlayerGroup" ) -- Search for the active group named "PlayerGroup", that contains a human player.
  --   BlueVictory:ToGroup( PlayerGroup ) -- Play the sound that Blue has won to the player group.
  --   
  function USERSOUND:ToGroup( Group ) --R2.3
    
    trigger.action.outSoundForGroup( Group:GetID(), self.UserSoundFileName )
    
    return self
  end  

end