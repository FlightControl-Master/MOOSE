--- **Core** - Models a velocity or speed, which can be expressed in various formats according the settings.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Convert velocity in various metric systems.
--   * Set the velocity.
--   * Create a text in a specific format of a velocity.
--   
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Core.Velocity
-- @image MOOSE.JPG

do -- Velocity

  --- @type VELOCITY
  -- @extends Core.Base#BASE


  --- VELOCITY models a speed, which can be expressed in various formats according the Settings.
  -- 
  -- ## VELOCITY constructor
  --   
  --   * @{#VELOCITY.New}(): Creates a new VELOCITY object.
  -- 
  -- @field #VELOCITY
  VELOCITY = {
    ClassName = "VELOCITY",
  }

  --- VELOCITY Constructor.
  -- @param #VELOCITY self
  -- @param #number VelocityMps The velocity in meters per second. 
  -- @return #VELOCITY
  function VELOCITY:New( VelocityMps )
    local self = BASE:Inherit( self, BASE:New() ) -- #VELOCITY
    self:F( {} )
    self.Velocity = VelocityMps
    return self
  end

  --- Set the velocity in Mps (meters per second).
  -- @param #VELOCITY self
  -- @param #number VelocityMps The velocity in meters per second. 
  -- @return #VELOCITY
  function VELOCITY:Set( VelocityMps )
    self.Velocity = VelocityMps
    return self
  end
  
  --- Get the velocity in Mps (meters per second).
  -- @param #VELOCITY self
  -- @return #number The velocity in meters per second. 
  function VELOCITY:Get()
    return self.Velocity
  end

  --- Set the velocity in Kmph (kilometers per hour).
  -- @param #VELOCITY self
  -- @param #number VelocityKmph The velocity in kilometers per hour. 
  -- @return #VELOCITY
  function VELOCITY:SetKmph( VelocityKmph )
    self.Velocity = UTILS.KmphToMps( VelocityKmph )
    return self
  end
  
  --- Get the velocity in Kmph (kilometers per hour).
  -- @param #VELOCITY self
  -- @return #number The velocity in kilometers per hour. 
  function VELOCITY:GetKmph()
  
    return UTILS.MpsToKmph( self.Velocity )
  end

  --- Set the velocity in Miph (miles per hour).
  -- @param #VELOCITY self
  -- @param #number VelocityMiph The velocity in miles per hour. 
  -- @return #VELOCITY
  function VELOCITY:SetMiph( VelocityMiph )
    self.Velocity = UTILS.MiphToMps( VelocityMiph )
    return self
  end
  
  --- Get the velocity in Miph (miles per hour).
  -- @param #VELOCITY self
  -- @return #number The velocity in miles per hour. 
  function VELOCITY:GetMiph()
    return UTILS.MpsToMiph( self.Velocity )
  end

  
  --- Get the velocity in text, according the player @{Settings}.
  -- @param #VELOCITY self
  -- @param Core.Settings#SETTINGS Settings
  -- @return #string The velocity in text. 
  function VELOCITY:GetText( Settings )
    local Settings = Settings or _SETTINGS
    if self.Velocity ~= 0 then
      if Settings:IsMetric() then
        return string.format( "%d km/h", UTILS.MpsToKmph( self.Velocity ) )
      else
        return string.format( "%d mi/h", UTILS.MpsToMiph( self.Velocity ) )
      end
    else
      return "stationary"
    end
  end

  --- Get the velocity in text, according the player or default @{Settings}.
  -- @param #VELOCITY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings
  -- @return #string The velocity in text according the player or default @{Settings}
  function VELOCITY:ToString( VelocityGroup, Settings ) -- R2.3
    self:F( { Group = VelocityGroup and VelocityGroup:GetName() } )
    local Settings = Settings or ( VelocityGroup and _DATABASE:GetPlayerSettings( VelocityGroup:GetPlayerName() ) ) or _SETTINGS
    return self:GetText( Settings )
  end

end

do -- VELOCITY_POSITIONABLE

  --- @type VELOCITY_POSITIONABLE
  -- @extends Core.Base#BASE


  --- # VELOCITY_POSITIONABLE class, extends @{Core.Base#BASE}
  -- 
  -- VELOCITY_POSITIONABLE monitors the speed of an @{Positionable} in the simulation, which can be expressed in various formats according the Settings.
  -- 
  -- ## 1. VELOCITY_POSITIONABLE constructor
  --   
  --   * @{#VELOCITY_POSITIONABLE.New}(): Creates a new VELOCITY_POSITIONABLE object.
  -- 
  -- @field #VELOCITY_POSITIONABLE
  VELOCITY_POSITIONABLE = {
    ClassName = "VELOCITY_POSITIONABLE",
  }

  --- VELOCITY_POSITIONABLE Constructor.
  -- @param #VELOCITY_POSITIONABLE self
  -- @param Wrapper.Positionable#POSITIONABLE Positionable The Positionable to monitor the speed. 
  -- @return #VELOCITY_POSITIONABLE
  function VELOCITY_POSITIONABLE:New( Positionable )
    local self = BASE:Inherit( self, VELOCITY:New() ) -- #VELOCITY_POSITIONABLE
    self:F( {} )
    self.Positionable = Positionable
    return self
  end

  --- Get the velocity in Mps (meters per second).
  -- @param #VELOCITY_POSITIONABLE self
  -- @return #number The velocity in meters per second. 
  function VELOCITY_POSITIONABLE:Get()
    return self.Positionable:GetVelocityMPS() or 0
  end

  --- Get the velocity in Kmph (kilometers per hour).
  -- @param #VELOCITY_POSITIONABLE self
  -- @return #number The velocity in kilometers per hour. 
  function VELOCITY_POSITIONABLE:GetKmph()
  
    return UTILS.MpsToKmph( self.Positionable:GetVelocityMPS() or 0)
  end

  --- Get the velocity in Miph (miles per hour).
  -- @param #VELOCITY_POSITIONABLE self
  -- @return #number The velocity in miles per hour. 
  function VELOCITY_POSITIONABLE:GetMiph()
    return UTILS.MpsToMiph( self.Positionable:GetVelocityMPS() or 0 )
  end

  --- Get the velocity in text, according the player or default @{Settings}.
  -- @param #VELOCITY_POSITIONABLE self
  -- @return #string The velocity in text according the player or default @{Settings}
  function VELOCITY_POSITIONABLE:ToString() -- R2.3
    self:F( { Group = self.Positionable and self.Positionable:GetName() } )
    local Settings = Settings or ( self.Positionable and _DATABASE:GetPlayerSettings( self.Positionable:GetPlayerName() ) ) or _SETTINGS
    self.Velocity = self.Positionable:GetVelocityMPS()
    return self:GetText( Settings )
  end

end