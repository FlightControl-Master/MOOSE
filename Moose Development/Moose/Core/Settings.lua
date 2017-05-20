--- **Core** - **SETTINGS** classe defines the format settings management for measurement.
--
-- ![Banner Image](..\Presentations\SETTINGS\Dia1.JPG)
--
-- ====
--
-- # Demo Missions
--
-- ### [SETTINGS Demo Missions source code]()
--
-- ### [SETTINGS Demo Missions, only for beta testers]()
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
--
-- ====
--
-- # YouTube Channel
--
-- ### [SETTINGS YouTube Channel]()
--
-- ===
--
-- ### Authors:
--
--   * FlightControl : Design & Programming
--
-- ### Contributions:
--
-- @module Settings


--- @type SETTINGS
-- @field #number LL_Accuracy
-- @field #boolean LL_DMS
-- @field #number MGRS_Accuracy
-- @field #string A2GSystem
-- @field #string A2ASystem
-- @extends Core.Base#BASE

--- # SETTINGS class, extends @{Base#BASE}
--
-- @field #SETTINGS
SETTINGS = {
  ClassName = "SETTINGS",
  LL_Accuracy = 2,
  LL_DMS = true,
  MGRS_Accuracy = 5,
  A2GSystem = "MGRS",
  A2ASystem = "BRA",
  
}



do -- SETTINGS

  --- SETTINGS constructor.
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:New() 

    local self = BASE:Inherit( self, BASE:New() ) -- #SETTINGS

    self:SetMetric() -- Defaults
    self:SetA2G_MGRS() -- Defaults
    self:SetA2A_BRA() -- Defaults

    return self
  end

 
  --- Sets the SETTINGS metric.
  -- @param #SETTINGS self
  function SETTINGS:SetMetric()
    self.Metric = true
  end
 
  --- Gets if the SETTINGS is metric.
  -- @param #SETTINGS self
  -- @return #boolean true if metric.
  function SETTINGS:IsMetric()
    return self.Metric == true
  end

  --- Sets the SETTINGS imperial.
  -- @param #SETTINGS self
  function SETTINGS:SetImperial()
    self.Metric = false
  end
 
  --- Gets if the SETTINGS is imperial.
  -- @param #SETTINGS self
  -- @return #boolean true if imperial.
  function SETTINGS:IsImperial()
    return self.Metric == false
  end

  --- Sets A2G LL
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2G_LL()
    self.A2GSystem = "LL"
  end

  --- Is LL
  -- @param #SETTINGS self
  -- @return #boolean true if LL
  function SETTINGS:IsA2G_LL()
    return self.A2GSystem == "LL"
  end

  --- Sets A2G MGRS
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2G_MGRS()
    self.A2GSystem = "MGRS"
  end

  --- Is MGRS
  -- @param #SETTINGS self
  -- @return #boolean true if MGRS
  function SETTINGS:IsA2G_MGRS()
    return self.A2GSystem == "MGRS"
  end

  --- Sets A2A BRA
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2A_BRA()
    self.A2ASystem = "BRA"
  end

  --- Is BRA
  -- @param #SETTINGS self
  -- @return #boolean true if BRA
  function SETTINGS:IsA2A_BRA()
    return self.A2ASystem == "BRA"
  end

  --- Sets A2A BULLS
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2A_BULLS()
    self.A2ASystem = "BULLS"
  end

  --- Is BULLS
  -- @param #SETTINGS self
  -- @return #boolean true if BULLS
  function SETTINGS:IsA2A_BULLS()
    return self.A2ASystem == "BULLS"
  end

  --- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SettingsMenu( RootMenu )

    if self.SystemMenu then
      self.SystemMenu:Remove()
      self.SystemMenu = nil
    end
  
    self.SystemMenu = MENU_MISSION:New( "Settings" )
    
    local A2GCoordinateMenu = MENU_MISSION:New( "A2G Coordinate System", self.SystemMenu )
  
    if self:IsA2G_LL() then
      MENU_MISSION_COMMAND:New( "Activate MGRS", A2GCoordinateMenu, self.A2GMenuSystem, self, "MGRS" )
      MENU_MISSION_COMMAND:New( "LL Accuracy 1", A2GCoordinateMenu, self.MenuLL_Accuracy, self, 1 )
      MENU_MISSION_COMMAND:New( "LL Accuracy 2", A2GCoordinateMenu, self.MenuLL_Accuracy, self, 2 )
      MENU_MISSION_COMMAND:New( "LL Accuracy 3", A2GCoordinateMenu, self.MenuLL_Accuracy, self, 3 )
      MENU_MISSION_COMMAND:New( "LL Decimal On", A2GCoordinateMenu, self.MenuLL_DMS, self, true )
      MENU_MISSION_COMMAND:New( "LL Decimal Off", A2GCoordinateMenu, self.MenuLL_DMS, self, false )
    end
  
    if self:IsA2G_MGRS() then
      MENU_MISSION_COMMAND:New( "Activate LL", A2GCoordinateMenu, self.A2GMenuSystem, self, "LL" )
      MENU_MISSION_COMMAND:New( "MGRS Accuracy 1", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, 1 )
      MENU_MISSION_COMMAND:New( "MGRS Accuracy 2", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, 2 )
      MENU_MISSION_COMMAND:New( "MGRS Accuracy 3", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, 3 )
      MENU_MISSION_COMMAND:New( "MGRS Accuracy 4", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, 4 )
      MENU_MISSION_COMMAND:New( "MGRS Accuracy 5", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, 5 )
    end

    local A2ACoordinateMenu = MENU_MISSION:New( "A2A Coordinate System", self.SystemMenu )

    if self:IsA2A_BULLS() then
      MENU_MISSION_COMMAND:New( "Activate BRA", A2ACoordinateMenu, self.A2AMenuSystem, self, "BRA" )
    end
  
    if self:IsA2A_BRA() then
      MENU_MISSION_COMMAND:New( "Activate BULLS", A2ACoordinateMenu, self.A2AMenuSystem, self, "BULLS" )
    end
    
    return self
  end

  --- @param #SETTINGS self
  function SETTINGS:A2GMenuSystem( A2GSystem )
    self.A2GSystem = A2GSystem
    self:SettingsMenu()
  end

  --- @param #SETTINGS self
  function SETTINGS:A2AMenuSystem( A2ASystem )
    self.A2ASystem = A2ASystem
    self:SettingsMenu()
  end

  --- @param #SETTINGS self
  function SETTINGS:MenuLL_Accuracy( LL_Accuracy )
    self.LL_Accuracy = LL_Accuracy
    self:SettingsMenu()
  end

  --- @param #SETTINGS self
  function SETTINGS:MenuLL_DMS( LL_DMS )
    self.LL_DMS = LL_DMS
    self:SettingsMenu()
  end
  --- @param #SETTINGS self
  function SETTINGS:MenuMGRS_Accuracy( MGRS_Accuracy )
    self.MGRS_Accuracy = MGRS_Accuracy
    self:SettingsMenu()
  end

end


