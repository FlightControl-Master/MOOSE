--- **Core** -- **SETTINGS** classe defines the format settings management for measurement.
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
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
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
  ShowPlayerMenu = true,
}



do -- SETTINGS

  --- SETTINGS constructor.
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:Set( PlayerName ) 

    if PlayerName == nil then
      local self = BASE:Inherit( self, BASE:New() ) -- #SETTINGS
      self:SetMetric() -- Defaults
      self:SetA2G_BR() -- Defaults
      self:SetA2A_BRAA() -- Defaults
      self:SetLL_Accuracy( 3 ) -- Defaults
      self:SetMGRS_Accuracy( 5 ) -- Defaults
      self:SetMessageTime( MESSAGE.Type.Briefing, 180 )
      self:SetMessageTime( MESSAGE.Type.Detailed, 60 )
      self:SetMessageTime( MESSAGE.Type.Information, 30 )
      self:SetMessageTime( MESSAGE.Type.Overview, 60 )
      self:SetMessageTime( MESSAGE.Type.Update, 15 )
      return self
    else
      local Settings = _DATABASE:GetPlayerSettings( PlayerName )
      if not Settings then
        Settings = BASE:Inherit( self, BASE:New() ) -- #SETTINGS
        _DATABASE:SetPlayerSettings( PlayerName, Settings )
      end
      return Settings
    end
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
    return ( self.Metric ~= nil and self.Metric == true ) or ( self.Metric == nil and _SETTINGS:IsMetric() )
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
    return ( self.Metric ~= nil and self.Metric == false ) or ( self.Metric == nil and _SETTINGS:IsMetric() )
  end

  --- Sets the SETTINGS LL accuracy.
  -- @param #SETTINGS self
  -- @param #number LL_Accuracy
  -- @return #SETTINGS
  function SETTINGS:SetLL_Accuracy( LL_Accuracy )
    self.LL_Accuracy = LL_Accuracy
  end

  --- Gets the SETTINGS LL accuracy.
  -- @param #SETTINGS self
  -- @return #number
  function SETTINGS:GetLL_DDM_Accuracy()
    return self.LL_DDM_Accuracy or _SETTINGS:GetLL_DDM_Accuracy()
  end

  --- Sets the SETTINGS MGRS accuracy.
  -- @param #SETTINGS self
  -- @param #number MGRS_Accuracy
  -- @return #SETTINGS
  function SETTINGS:SetMGRS_Accuracy( MGRS_Accuracy )
    self.MGRS_Accuracy = MGRS_Accuracy
  end

  --- Gets the SETTINGS MGRS accuracy.
  -- @param #SETTINGS self
  -- @return #number
  function SETTINGS:GetMGRS_Accuracy()
    return self.MGRS_Accuracy or _SETTINGS:GetMGRS_Accuracy()
  end
  
  --- Sets the SETTINGS Message Display Timing of a MessageType
  -- @param #SETTINGS self
  -- @param Core.Message#MESSAGE MessageType The type of the message.
  -- @param #number MessageTime The display time duration in seconds of the MessageType.
  function SETTINGS:SetMessageTime( MessageType, MessageTime )
    self.MessageTypeTimings = self.MessageTypeTimings or {}
    self.MessageTypeTimings[MessageType] = MessageTime
  end
  
  
  --- Gets the SETTINGS Message Display Timing of a MessageType
  -- @param #SETTINGS self
  -- @param Core.Message#MESSAGE MessageType The type of the message.
  -- @return #number
  function SETTINGS:GetMessageTime( MessageType )
    return ( self.MessageTypeTimings and self.MessageTypeTimings[MessageType] ) or _SETTINGS:GetMessageTime( MessageType )
  end

  --- Sets A2G LL DMS
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2G_LL_DMS()
    self.A2GSystem = "LL DMS"
  end

  --- Sets A2G LL DDM
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2G_LL_DDM()
    self.A2GSystem = "LL DDM"
  end

  --- Is LL DMS
  -- @param #SETTINGS self
  -- @return #boolean true if LL DMS
  function SETTINGS:IsA2G_LL_DMS()
    return ( self.A2GSystem and self.A2GSystem == "LL DMS" ) or ( not self.A2GSystem and _SETTINGS:IsA2G_LL_DMS() )
  end

  --- Is LL DDM
  -- @param #SETTINGS self
  -- @return #boolean true if LL DDM
  function SETTINGS:IsA2G_LL_DDM()
    return ( self.A2GSystem and self.A2GSystem == "LL DDM" ) or ( not self.A2GSystem and _SETTINGS:IsA2G_LL_DDM() )
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
    return ( self.A2GSystem and self.A2GSystem == "MGRS" ) or ( not self.A2GSystem and _SETTINGS:IsA2G_MGRS() )
  end

  --- Sets A2G BRA
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2G_BR()
    self.A2GSystem = "BR"
  end

  --- Is BRA
  -- @param #SETTINGS self
  -- @return #boolean true if BRA
  function SETTINGS:IsA2G_BR()
    return ( self.A2GSystem and self.A2GSystem == "BR" ) or ( not self.A2GSystem and _SETTINGS:IsA2G_BR() )
  end

  --- Sets A2A BRA
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2A_BRAA()
    self.A2ASystem = "BRAA"
  end

  --- Is BRA
  -- @param #SETTINGS self
  -- @return #boolean true if BRA
  function SETTINGS:IsA2A_BRAA()
    self:E( { BRA = ( self.A2ASystem and self.A2ASystem == "BRAA" ) or ( not self.A2ASystem and _SETTINGS:IsA2A_BRAA() ) } )
    return ( self.A2ASystem and self.A2ASystem == "BRAA" ) or ( not self.A2ASystem and _SETTINGS:IsA2A_BRAA() )
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
    return ( self.A2ASystem and self.A2ASystem == "BULLS" ) or ( not self.A2ASystem and _SETTINGS:IsA2A_BULLS() )
  end

  --- Sets A2A LL DMS
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2A_LL_DMS()
    self.A2ASystem = "LL DMS"
  end

  --- Sets A2A LL DDM
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2A_LL_DDM()
    self.A2ASystem = "LL DDM"
  end

  --- Is LL DMS
  -- @param #SETTINGS self
  -- @return #boolean true if LL DMS
  function SETTINGS:IsA2A_LL_DMS()
    return ( self.A2ASystem and self.A2ASystem == "LL DMS" ) or ( not self.A2ASystem and _SETTINGS:IsA2A_LL_DMS() )
  end

  --- Is LL DDM
  -- @param #SETTINGS self
  -- @return #boolean true if LL DDM
  function SETTINGS:IsA2A_LL_DDM()
    return ( self.A2ASystem and self.A2ASystem == "LL DDM" ) or ( not self.A2ASystem and _SETTINGS:IsA2A_LL_DDM() )
  end

  --- Sets A2A MGRS
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetA2A_MGRS()
    self.A2ASystem = "MGRS"
  end

  --- Is MGRS
  -- @param #SETTINGS self
  -- @return #boolean true if MGRS
  function SETTINGS:IsA2A_MGRS()
    return ( self.A2ASystem and self.A2ASystem == "MGRS" ) or ( not self.A2ASystem and _SETTINGS:IsA2A_MGRS() )
  end

  --- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetSystemMenu( MenuGroup, RootMenu )

    local MenuText = "System Settings"
    
    local MenuTime = timer.getTime()
    
    local SettingsMenu = MENU_GROUP:New( MenuGroup, MenuText, RootMenu ):SetTime( MenuTime )

    local A2GCoordinateMenu = MENU_GROUP:New( MenuGroup, "A2G Coordinate System", SettingsMenu ):SetTime( MenuTime )
  
    
    if not self:IsA2G_LL_DMS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Lat/Lon Degree Min Sec (LL DMS)", A2GCoordinateMenu, self.A2GMenuSystem, self, MenuGroup, RootMenu, "LL DMS" ):SetTime( MenuTime )
    end
    
    if not self:IsA2G_LL_DDM() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Lat/Lon Degree Dec Min (LL DDM)", A2GCoordinateMenu, self.A2GMenuSystem, self, MenuGroup, RootMenu, "LL DDM" ):SetTime( MenuTime )
    end
    
    if self:IsA2G_LL_DDM() then
      MENU_GROUP_COMMAND:New( MenuGroup, "LL DDM Accuracy 1", A2GCoordinateMenu, self.MenuLL_DDM_Accuracy, self, MenuGroup, RootMenu, 1 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "LL DDM Accuracy 2", A2GCoordinateMenu, self.MenuLL_DDM_Accuracy, self, MenuGroup, RootMenu, 2 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "LL DDM Accuracy 3", A2GCoordinateMenu, self.MenuLL_DDM_Accuracy, self, MenuGroup, RootMenu, 3 ):SetTime( MenuTime )
    end
    
    if not self:IsA2G_BR() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Bearing, Range (BR)", A2GCoordinateMenu, self.A2GMenuSystem, self, MenuGroup, RootMenu, "BR" ):SetTime( MenuTime )
    end
    
    if not self:IsA2G_MGRS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Military Grid (MGRS)", A2GCoordinateMenu, self.A2GMenuSystem, self, MenuGroup, RootMenu, "MGRS" ):SetTime( MenuTime )
    end
    
    if self:IsA2G_MGRS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 1", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 1 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 2", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 2 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 3", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 3 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 4", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 4 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 5", A2GCoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 5 ):SetTime( MenuTime )
    end

    local A2ACoordinateMenu = MENU_GROUP:New( MenuGroup, "A2A Coordinate System", SettingsMenu ):SetTime( MenuTime )

    if not self:IsA2A_LL_DMS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Lat/Lon Degree Min Sec (LL DMS)", A2ACoordinateMenu, self.A2AMenuSystem, self, MenuGroup, RootMenu, "LL DMS" ):SetTime( MenuTime )
    end

    if not self:IsA2A_LL_DDM() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Lat/Lon Degree Dec Min (LL DDM)", A2ACoordinateMenu, self.A2AMenuSystem, self, MenuGroup, RootMenu, "LL DDM" ):SetTime( MenuTime )
    end

    if self:IsA2A_LL_DDM() then
      MENU_GROUP_COMMAND:New( MenuGroup, "LL DDM Accuracy 1", A2ACoordinateMenu, self.MenuLL_DDM_Accuracy, self, MenuGroup, RootMenu, 1 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "LL DDM Accuracy 2", A2ACoordinateMenu, self.MenuLL_DDM_Accuracy, self, MenuGroup, RootMenu, 2 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "LL DDM Accuracy 3", A2ACoordinateMenu, self.MenuLL_DDM_Accuracy, self, MenuGroup, RootMenu, 3 ):SetTime( MenuTime )
    end    

    if not self:IsA2A_BULLS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Bullseye (BULLS)", A2ACoordinateMenu, self.A2AMenuSystem, self, MenuGroup, RootMenu, "BULLS" ):SetTime( MenuTime )
    end
    
    if not self:IsA2A_BRAA() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Bearing Range Altitude Aspect (BRAA)", A2ACoordinateMenu, self.A2AMenuSystem, self, MenuGroup, RootMenu, "BRAA" ):SetTime( MenuTime )
    end
    
    if not self:IsA2A_MGRS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Military Grid (MGRS)", A2ACoordinateMenu, self.A2AMenuSystem, self, MenuGroup, RootMenu, "MGRS" ):SetTime( MenuTime )
    end

    if self:IsA2A_MGRS() then
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 1", A2ACoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 1 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 2", A2ACoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 2 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 3", A2ACoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 3 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 4", A2ACoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 4 ):SetTime( MenuTime )
      MENU_GROUP_COMMAND:New( MenuGroup, "MGRS Accuracy 5", A2ACoordinateMenu, self.MenuMGRS_Accuracy, self, MenuGroup, RootMenu, 5 ):SetTime( MenuTime )
    end        
  
    local MetricsMenu = MENU_GROUP:New( MenuGroup, "Measures and Weights System", SettingsMenu ):SetTime( MenuTime )
    
    if self:IsMetric() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Imperial (Miles,Feet)", MetricsMenu, self.MenuMWSystem, self, MenuGroup, RootMenu, false ):SetTime( MenuTime )
    end
    
    if self:IsImperial() then
      MENU_GROUP_COMMAND:New( MenuGroup, "Metric (Kilometers,Meters)", MetricsMenu, self.MenuMWSystem, self, MenuGroup, RootMenu, true ):SetTime( MenuTime )
    end    
    
    local MessagesMenu = MENU_GROUP:New( MenuGroup, "Messages and Reports", SettingsMenu ):SetTime( MenuTime )

    local UpdateMessagesMenu = MENU_GROUP:New( MenuGroup, "Update Messages", MessagesMenu ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "Off", UpdateMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Update, 0 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "5 seconds", UpdateMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Update, 5 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "10 seconds", UpdateMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Update, 10 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "15 seconds", UpdateMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Update, 15 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "30 seconds", UpdateMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Update, 30 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "1 minute", UpdateMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Update, 60 ):SetTime( MenuTime )

    local InformationMessagesMenu = MENU_GROUP:New( MenuGroup, "Information Messages", MessagesMenu ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "5 seconds", InformationMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Information, 5 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "10 seconds", InformationMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Information, 10 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "15 seconds", InformationMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Information, 15 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "30 seconds", InformationMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Information, 30 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "1 minute", InformationMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Information, 60 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "2 minutes", InformationMessagesMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Information, 120 ):SetTime( MenuTime )

    local BriefingReportsMenu = MENU_GROUP:New( MenuGroup, "Briefing Reports", MessagesMenu ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "15 seconds", BriefingReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Briefing, 15 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "30 seconds", BriefingReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Briefing, 30 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "1 minute", BriefingReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Briefing, 60 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "2 minutes", BriefingReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Briefing, 120 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "3 minutes", BriefingReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Briefing, 180 ):SetTime( MenuTime )

    local OverviewReportsMenu = MENU_GROUP:New( MenuGroup, "Overview Reports", MessagesMenu ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "15 seconds", OverviewReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Overview, 15 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "30 seconds", OverviewReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Overview, 30 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "1 minute", OverviewReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Overview, 60 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "2 minutes", OverviewReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Overview, 120 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "3 minutes", OverviewReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.Overview, 180 ):SetTime( MenuTime )

    local DetailedReportsMenu = MENU_GROUP:New( MenuGroup, "Detailed Reports", MessagesMenu ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "15 seconds", DetailedReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.DetailedReportsMenu, 15 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "30 seconds", DetailedReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.DetailedReportsMenu, 30 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "1 minute", DetailedReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.DetailedReportsMenu, 60 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "2 minutes", DetailedReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.DetailedReportsMenu, 120 ):SetTime( MenuTime )
    MENU_GROUP_COMMAND:New( MenuGroup, "3 minutes", DetailedReportsMenu, self.MenuMessageTimingsSystem, self, MenuGroup, RootMenu, MESSAGE.Type.DetailedReportsMenu, 180 ):SetTime( MenuTime )
    

    SettingsMenu:Remove( MenuTime )
    
    return self
  end

  --- Sets the player menus on, so that they will show to the players.
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetPlayerMenuOn()
    self.ShowPlayerMenu = true
  end

  --- Sets the player menus off, so that they will hide from the players.
  -- @param #SETTINGS self
  -- @return #SETTINGS
  function SETTINGS:SetPlayerMenuOff()
    self.ShowPlayerMenu = false
  end



  --- Updates the menu of the player seated in the PlayerUnit.
  -- @param #SETTINGS self
  -- @param Wrapper.Client#CLIENT PlayerUnit
  -- @return #SETTINGS
  function SETTINGS:SetPlayerMenu( PlayerUnit )

    if _SETTINGS.ShowPlayerMenu == true then
    
      local PlayerGroup = PlayerUnit:GetGroup()
      local PlayerName = PlayerUnit:GetPlayerName()
      local PlayerNames = PlayerGroup:GetPlayerNames()
  
      local PlayerMenu = MENU_GROUP:New( PlayerGroup, 'Settings "' .. PlayerName .. '"' )
      
      self.PlayerMenu = PlayerMenu
  
      local A2GCoordinateMenu = MENU_GROUP:New( PlayerGroup, "A2G Coordinate System", PlayerMenu )
    
      if not self:IsA2G_LL_DMS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Lat/Lon Degree Min Sec (LL DMS)", A2GCoordinateMenu, self.MenuGroupA2GSystem, self, PlayerUnit, PlayerGroup, PlayerName, "LL DMS" )
      end
    
      if not self:IsA2G_LL_DDM() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Lat/Lon Degree Dec Min (LL DDM)", A2GCoordinateMenu, self.MenuGroupA2GSystem, self, PlayerUnit, PlayerGroup, PlayerName, "LL DDM" )
      end
    
      if self:IsA2G_LL_DDM() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "LL DDM Accuracy 1", A2GCoordinateMenu, self.MenuGroupLL_DDM_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 1 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "LL DDM Accuracy 2", A2GCoordinateMenu, self.MenuGroupLL_DDM_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 2 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "LL DDM Accuracy 3", A2GCoordinateMenu, self.MenuGroupLL_DDM_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 3 )
      end
      
      if not self:IsA2G_BR() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Bearing, Range (BR)", A2GCoordinateMenu, self.MenuGroupA2GSystem, self, PlayerUnit, PlayerGroup, PlayerName, "BR" )
      end
      
      if not self:IsA2G_MGRS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS)", A2GCoordinateMenu, self.MenuGroupA2GSystem, self, PlayerUnit, PlayerGroup, PlayerName, "MGRS" )
      end    
  
      if self:IsA2G_MGRS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "MGRS Accuracy 1", A2GCoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 1 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "MGRS Accuracy 2", A2GCoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 2 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "MGRS Accuracy 3", A2GCoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 3 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "MGRS Accuracy 4", A2GCoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 4 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "MGRS Accuracy 5", A2GCoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 5 )
      end
  
      local A2ACoordinateMenu = MENU_GROUP:New( PlayerGroup, "A2A Coordinate System", PlayerMenu )
  
  
      if not self:IsA2A_LL_DMS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Lat/Lon Degree Min Sec (LL DMS)", A2GCoordinateMenu, self.MenuGroupA2GSystem, self, PlayerUnit, PlayerGroup, PlayerName, "LL DMS" )
      end
    
      if not self:IsA2A_LL_DDM() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Lat/Lon Degree Dec Min (LL DDM)", A2GCoordinateMenu, self.MenuGroupA2GSystem, self, PlayerUnit, PlayerGroup, PlayerName, "LL DDM" )
      end
    
      if self:IsA2A_LL_DDM() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "LL DDM Accuracy 1", A2GCoordinateMenu, self.MenuGroupLL_DDM_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 1 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "LL DDM Accuracy 2", A2GCoordinateMenu, self.MenuGroupLL_DDM_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 2 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "LL DDM Accuracy 3", A2GCoordinateMenu, self.MenuGroupLL_DDM_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 3 )
      end
  
      if not self:IsA2A_BULLS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Bullseye (BULLS)", A2ACoordinateMenu, self.MenuGroupA2ASystem, self, PlayerUnit, PlayerGroup, PlayerName, "BULLS" )
      end
      
      if not self:IsA2A_BRAA() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Bearing Range Altitude Aspect (BRAA)", A2ACoordinateMenu, self.MenuGroupA2ASystem, self, PlayerUnit, PlayerGroup, PlayerName, "BRAA" )
      end
      
      if not self:IsA2A_MGRS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS)", A2ACoordinateMenu, self.MenuGroupA2ASystem, self, PlayerUnit, PlayerGroup, PlayerName, "MGRS" )
      end
      
      if self:IsA2A_MGRS() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS) Accuracy 1", A2ACoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 1 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS) Accuracy 2", A2ACoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 2 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS) Accuracy 3", A2ACoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 3 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS) Accuracy 4", A2ACoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 4 )
        MENU_GROUP_COMMAND:New( PlayerGroup, "Military Grid (MGRS) Accuracy 5", A2ACoordinateMenu, self.MenuGroupMGRS_AccuracySystem, self, PlayerUnit, PlayerGroup, PlayerName, 5 )
      end    
  
      local MetricsMenu = MENU_GROUP:New( PlayerGroup, "Measures and Weights System", PlayerMenu )
      
      if self:IsMetric() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Imperial (Miles,Feet)", MetricsMenu, self.MenuGroupMWSystem, self, PlayerUnit, PlayerGroup, PlayerName, false )
      end
      
      if self:IsImperial() then
        MENU_GROUP_COMMAND:New( PlayerGroup, "Metric (Kilometers,Meters)", MetricsMenu, self.MenuGroupMWSystem, self, PlayerUnit, PlayerGroup, PlayerName, true )
      end    
  
  
      local MessagesMenu = MENU_GROUP:New( PlayerGroup, "Messages and Reports", PlayerMenu )
  
      local UpdateMessagesMenu = MENU_GROUP:New( PlayerGroup, "Update Messages", MessagesMenu )
      MENU_GROUP_COMMAND:New( PlayerGroup, "Off", UpdateMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Update, 0 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "5 seconds", UpdateMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Update, 5 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "10 seconds", UpdateMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Update, 10 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "15 seconds", UpdateMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Update, 15 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "30 seconds", UpdateMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Update, 30 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "1 minute", UpdateMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Update, 60 )
  
      local InformationMessagesMenu = MENU_GROUP:New( PlayerGroup, "Information Messages", MessagesMenu )
      MENU_GROUP_COMMAND:New( PlayerGroup, "5 seconds", InformationMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Information, 5 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "10 seconds", InformationMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Information, 10 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "15 seconds", InformationMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Information, 15 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "30 seconds", InformationMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Information, 30 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "1 minute", InformationMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Information, 60 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "2 minutes", InformationMessagesMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Information, 120 )
  
      local BriefingReportsMenu = MENU_GROUP:New( PlayerGroup, "Briefing Reports", MessagesMenu )
      MENU_GROUP_COMMAND:New( PlayerGroup, "15 seconds", BriefingReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Briefing, 15 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "30 seconds", BriefingReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Briefing, 30 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "1 minute", BriefingReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Briefing, 60 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "2 minutes", BriefingReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Briefing, 120 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "3 minutes", BriefingReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Briefing, 180 )
  
      local OverviewReportsMenu = MENU_GROUP:New( PlayerGroup, "Overview Reports", MessagesMenu )
      MENU_GROUP_COMMAND:New( PlayerGroup, "15 seconds", OverviewReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Overview, 15 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "30 seconds", OverviewReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Overview, 30 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "1 minute", OverviewReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Overview, 60 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "2 minutes", OverviewReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Overview, 120 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "3 minutes", OverviewReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.Overview, 180 )
  
      local DetailedReportsMenu = MENU_GROUP:New( PlayerGroup, "Detailed Reports", MessagesMenu )
      MENU_GROUP_COMMAND:New( PlayerGroup, "15 seconds", DetailedReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.DetailedReportsMenu, 15 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "30 seconds", DetailedReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.DetailedReportsMenu, 30 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "1 minute", DetailedReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.DetailedReportsMenu, 60 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "2 minutes", DetailedReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.DetailedReportsMenu, 120 )
      MENU_GROUP_COMMAND:New( PlayerGroup, "3 minutes", DetailedReportsMenu, self.MenuGroupMessageTimingsSystem, self, PlayerUnit, PlayerGroup, PlayerName, MESSAGE.Type.DetailedReportsMenu, 180 )
    
    end  
    
    return self
  end

  --- Removes the player menu from the PlayerUnit.
  --- @param #SETTINGS self
  -- @param Wrapper.Client#CLIENT PlayerUnit
  -- @return #SETTINGS
  function SETTINGS:RemovePlayerMenu( PlayerUnit )

    if self.PlayerMenu then
      self.PlayerMenu:Remove()
      self.PlayerMenu = nil
    end
    
    return self
  end


  --- @param #SETTINGS self
  function SETTINGS:A2GMenuSystem( MenuGroup, RootMenu, A2GSystem )
    self.A2GSystem = A2GSystem
    MESSAGE:New( string.format("Settings: Default A2G coordinate system set to %s for all players!", A2GSystem ), 5 ):ToAll()
    self:SetSystemMenu( MenuGroup, RootMenu )
  end

  --- @param #SETTINGS self
  function SETTINGS:A2AMenuSystem( MenuGroup, RootMenu, A2ASystem )
    self.A2ASystem = A2ASystem
    MESSAGE:New( string.format("Settings: Default A2A coordinate system set to %s for all players!", A2ASystem ), 5 ):ToAll()
    self:SetSystemMenu( MenuGroup, RootMenu )
  end

  --- @param #SETTINGS self
  function SETTINGS:MenuLL_DDM_Accuracy( MenuGroup, RootMenu, LL_Accuracy )
    self.LL_Accuracy = LL_Accuracy
    MESSAGE:New( string.format("Settings: Default LL accuracy set to %s for all players!", LL_Accuracy ), 5 ):ToAll()
    self:SetSystemMenu( MenuGroup, RootMenu )
  end

  --- @param #SETTINGS self
  function SETTINGS:MenuMGRS_Accuracy( MenuGroup, RootMenu, MGRS_Accuracy )
    self.MGRS_Accuracy = MGRS_Accuracy
    MESSAGE:New( string.format("Settings: Default MGRS accuracy set to %s for all players!", MGRS_Accuracy ), 5 ):ToAll()
    self:SetSystemMenu( MenuGroup, RootMenu )
  end

  --- @param #SETTINGS self
  function SETTINGS:MenuMWSystem( MenuGroup, RootMenu, MW )
    self.Metric = MW
    MESSAGE:New( string.format("Settings: Default measurement format set to %s for all players!", MW and "Metric" or "Imperial" ), 5 ):ToAll()
    self:SetSystemMenu( MenuGroup, RootMenu )
  end

  --- @param #SETTINGS self
  function SETTINGS:MenuMessageTimingsSystem( MenuGroup, RootMenu, MessageType, MessageTime )
    self:SetMessageTime( MessageType, MessageTime )
    MESSAGE:New( string.format( "Settings: Default message time set for %s to %d.", MessageType, MessageTime ), 5 ):ToAll()
  end

  do
    --- @param #SETTINGS self
    function SETTINGS:MenuGroupA2GSystem( PlayerUnit, PlayerGroup, PlayerName, A2GSystem )
      BASE:E( {self, PlayerUnit:GetName(), A2GSystem} )
      self.A2GSystem = A2GSystem
      MESSAGE:New( string.format( "Settings: A2G format set to %s for player %s.", A2GSystem, PlayerName ), 5 ):ToGroup( PlayerGroup )
      self:RemovePlayerMenu(PlayerUnit)
      self:SetPlayerMenu(PlayerUnit)
    end
  
    --- @param #SETTINGS self
    function SETTINGS:MenuGroupA2ASystem( PlayerUnit, PlayerGroup, PlayerName, A2ASystem )
      self.A2ASystem = A2ASystem
      MESSAGE:New( string.format( "Settings: A2A format set to %s for player %s.", A2ASystem, PlayerName ), 5 ):ToGroup( PlayerGroup )
      self:RemovePlayerMenu(PlayerUnit)
      self:SetPlayerMenu(PlayerUnit)
    end
  
    --- @param #SETTINGS self
    function SETTINGS:MenuGroupLL_DDM_AccuracySystem( PlayerUnit, PlayerGroup, PlayerName, LL_Accuracy )
      self.LL_Accuracy = LL_Accuracy
      MESSAGE:New( string.format( "Settings: A2G LL format accuracy set to %d for player %s.", LL_Accuracy, PlayerName ), 5 ):ToGroup( PlayerGroup )
      self:RemovePlayerMenu(PlayerUnit)
      self:SetPlayerMenu(PlayerUnit)
    end
  
    --- @param #SETTINGS self
    function SETTINGS:MenuGroupMGRS_AccuracySystem( PlayerUnit, PlayerGroup, PlayerName, MGRS_Accuracy )
      self.MGRS_Accuracy = MGRS_Accuracy
      MESSAGE:New( string.format( "Settings: A2G MGRS format accuracy set to %d for player %s.", MGRS_Accuracy, PlayerName ), 5 ):ToGroup( PlayerGroup )
      self:RemovePlayerMenu(PlayerUnit)
      self:SetPlayerMenu(PlayerUnit)
    end

    --- @param #SETTINGS self
    function SETTINGS:MenuGroupMWSystem( PlayerUnit, PlayerGroup, PlayerName, MW )
      self.Metric = MW
      MESSAGE:New( string.format( "Settings: Measurement format set to %s for player %s.", MW and "Metric" or "Imperial", PlayerName ), 5 ):ToGroup( PlayerGroup )
      self:RemovePlayerMenu(PlayerUnit)
      self:SetPlayerMenu(PlayerUnit)
    end

    --- @param #SETTINGS self
    function SETTINGS:MenuGroupMessageTimingsSystem( PlayerUnit, PlayerGroup, PlayerName, MessageType, MessageTime )
      self:SetMessageTime( MessageType, MessageTime )
      MESSAGE:New( string.format( "Settings: Default message time set for %s to %d.", MessageType, MessageTime ), 5 ):ToGroup( PlayerGroup )
    end
  
  end

end


