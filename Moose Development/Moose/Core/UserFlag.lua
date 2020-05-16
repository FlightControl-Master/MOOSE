--- **Core** - Manage user flags to interact with the mission editor trigger system and server side scripts.
--
-- ===
-- 
-- ## Features:
-- 
--   * Set or get DCS user flags within running missions.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module Core.UserFlag
-- @image Core_Userflag.JPG
-- 

do -- UserFlag

  --- @type USERFLAG
  -- @field #string ClassName Name of the class
  -- @field #string UserFlagName Name of the flag.
  -- @extends Core.Base#BASE


  --- Management of DCS User Flags.
  -- 
  -- # 1. USERFLAG constructor
  --   
  --   * @{#USERFLAG.New}(): Creates a new USERFLAG object.
  -- 
  -- @field #USERFLAG
  USERFLAG = {
    ClassName    = "USERFLAG",
    UserFlagName = nil,
  }
  
  --- USERFLAG Constructor.
  -- @param #USERFLAG self
  -- @param #string UserFlagName The name of the userflag, which is a free text string.
  -- @return #USERFLAG
  function USERFLAG:New( UserFlagName ) --R2.3
  
    local self = BASE:Inherit( self, BASE:New() ) -- #USERFLAG

    self.UserFlagName = UserFlagName

    return self
  end

  --- Get the userflag name.
  -- @param #USERFLAG self
  -- @return #string Name of the user flag.
  function USERFLAG:GetName()    
    return self.UserFlagName
  end  

  --- Set the userflag to a given Number.
  -- @param #USERFLAG self
  -- @param #number Number The number value to be checked if it is the same as the userflag.
  -- @param #number Delay Delay in seconds, before the flag is set.
  -- @return #USERFLAG The userflag instance.
  -- @usage
  --   local BlueVictory = USERFLAG:New( "VictoryBlue" )
  --   BlueVictory:Set( 100 ) -- Set the UserFlag VictoryBlue to 100.
  --   
  function USERFLAG:Set( Number, Delay ) --R2.3
  
    if Delay and Delay>0 then
      self:ScheduleOnce(Delay, USERFLAG.Set, self, Number)
    else
      --env.info(string.format("Setting flag \"%s\" to %d at T=%.1f", self.UserFlagName, Number, timer.getTime()))
      trigger.action.setUserFlag( self.UserFlagName, Number )
    end
    
    return self
  end  

  
  --- Get the userflag Number.
  -- @param #USERFLAG self
  -- @return #number Number The number value to be checked if it is the same as the userflag.
  -- @usage
  --   local BlueVictory = USERFLAG:New( "VictoryBlue" )
  --   local BlueVictoryValue = BlueVictory:Get() -- Get the UserFlag VictoryBlue value.
  --   
  function USERFLAG:Get() --R2.3
    
    return trigger.misc.getUserFlag( self.UserFlagName )
  end  

  
  
  --- Check if the userflag has a value of Number.
  -- @param #USERFLAG self
  -- @param #number Number The number value to be checked if it is the same as the userflag.
  -- @return #boolean true if the Number is the value of the userflag.
  -- @usage
  --   local BlueVictory = USERFLAG:New( "VictoryBlue" )
  --   if BlueVictory:Is( 1 ) then
  --     return "Blue has won"
  --   end
  function USERFLAG:Is( Number ) --R2.3
    
    return trigger.misc.getUserFlag( self.UserFlagName ) == Number
    
  end  

end