--- **Tasking** -- A COMMANDCENTER is the owner of multiple missions within MOOSE. 
-- A COMMANDCENTER governs multiple missions, the tasking and the reporting.
-- 
-- ===
--  
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module CommandCenter





--- The COMMANDCENTER class
-- @type COMMANDCENTER
-- @field Wrapper.Group#GROUP HQ
-- @field Dcs.DCSCoalitionWrapper.Object#coalition CommandCenterCoalition
-- @list<Tasking.Mission#MISSION> Missions
-- @extends Core.Base#BASE


--- # COMMANDCENTER class, extends @{Base#BASE}
-- 
--  The COMMANDCENTER class governs multiple missions, the tasking and the reporting.
--  
--  The commandcenter communicates important messages between the various groups of human players executing tasks in missions.
--  
-- ## COMMANDCENTER constructor
--
--   * @{#COMMANDCENTER.New}(): Creates a new COMMANDCENTER object.
-- 
-- ## Mission Management
-- 
--   * @{#COMMANDCENTER.AddMission}(): Adds a mission to the commandcenter control.
--   * @{#COMMANDCENTER.RemoveMission}(): Removes a mission to the commandcenter control.
--   * @{#COMMANDCENTER.GetMissions}(): Retrieves the missions table controlled by the commandcenter.
-- 
-- ## Reference Zones
-- 
-- Command Centers may be aware of certain Reference Zones within the battleground. These Reference Zones can refer to
-- known areas, recognizable buildings or sites, or any other point of interest.
-- Command Centers will use these Reference Zones to help pilots with defining coordinates in terms of navigation
-- during the WWII era.
-- The Reference Zones are related to the WWII mode that the Command Center will operate in.
-- Use the method @{#COMMANDCENTER.SetModeWWII}() to set the mode of communication to the WWII mode.
-- 
-- In WWII mode, the Command Center will receive detected targets, and will select for each target the closest
-- nearby Reference Zone. This allows pilots to navigate easier through the battle field readying for combat.
-- 
-- The Reference Zones need to be set by the Mission Designer in the Mission Editor.
-- Reference Zones are set by normal trigger zones. One can color the zones in a specific color, 
-- and the radius of the zones doesn't matter, only the point is important. Place the center of these Reference Zones at
-- specific scenery objects or points of interest (like cities, rivers, hills, crossing etc).
-- The trigger zones indicating a Reference Zone need to follow a specific syntax.
-- The name of each trigger zone expressing a Reference Zone need to start with a classification name of the object,
-- followed by a #, followed by a symbolic name of the Reference Zone.
-- A few examples:
-- 
--   * A church at Tskinvali would be indicated as: *Church#Tskinvali*
--   * A train station near Kobuleti would be indicated as: *Station#Kobuleti*
--   
-- The COMMANDCENTER class contains a method to indicate which trigger zones need to be used as Reference Zones.
-- This is done by using the method @{#COMMANDCENTER.SetReferenceZones}().
-- For the moment, only one Reference Zone class can be specified, but in the future, more classes will become possible.
-- 
-- @field #COMMANDCENTER
COMMANDCENTER = {
  ClassName = "COMMANDCENTER",
  CommandCenterName = "",
  CommandCenterCoalition = nil,
  CommandCenterPositionable = nil,
  Name = "",
  ReferencePoints = {},
  ReferenceNames = {},
  CommunicationMode = "80",
}

--- The constructor takes an IDENTIFIABLE as the HQ command center.
-- @param #COMMANDCENTER self
-- @param Wrapper.Positionable#POSITIONABLE CommandCenterPositionable
-- @param #string CommandCenterName
-- @return #COMMANDCENTER
function COMMANDCENTER:New( CommandCenterPositionable, CommandCenterName )

  local self = BASE:Inherit( self, BASE:New() )

  self.CommandCenterPositionable = CommandCenterPositionable  
  self.CommandCenterName = CommandCenterName or CommandCenterPositionable:GetName()
  self.CommandCenterCoalition = CommandCenterPositionable:GetCoalition()
	
	self.Missions = {}

  self:HandleEvent( EVENTS.Birth,
    --- @param #COMMANDCENTER self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      if EventData.IniObjectCategory == 1 then
        local EventGroup = GROUP:Find( EventData.IniDCSGroup )
        if EventGroup and self:HasGroup( EventGroup ) then
          local MenuReporting = MENU_GROUP:New( EventGroup, "Missions Reports", self.CommandCenterMenu )
          local MenuMissionsSummary = MENU_GROUP_COMMAND:New( EventGroup, "Missions Status Report", MenuReporting, self.ReportMissionsStatus, self, EventGroup )
          local MenuMissionsDetails = MENU_GROUP_COMMAND:New( EventGroup, "Missions Players Report", MenuReporting, self.ReportMissionsPlayers, self, EventGroup )
          self:ReportSummary( EventGroup )
          local PlayerUnit = EventData.IniUnit
          for MissionID, Mission in pairs( self:GetMissions() ) do
            local Mission = Mission -- Tasking.Mission#MISSION
            local PlayerGroup = EventData.IniGroup -- The GROUP object should be filled!
            Mission:JoinUnit( PlayerUnit, PlayerGroup )
          end
          self:SetMenu()
         _DATABASE:PlayerSettingsMenu( PlayerUnit ) 
        end
      end
      
    end
    )
  
--  -- When a player enters a client or a unit, the CommandCenter will check for each Mission and each Task in the Mission if the player has things to do.
--  -- For these elements, it will=
--  -- - Set the correct menu.
--  -- - Assign the PlayerUnit to the Task if required.
--  -- - Send a message to the other players in the group that this player has joined.
--  self:HandleEvent( EVENTS.PlayerEnterUnit,
--    --- @param #COMMANDCENTER self
--    -- @param Core.Event#EVENTDATA EventData
--    function( self, EventData )
--      local PlayerUnit = EventData.IniUnit
--      for MissionID, Mission in pairs( self:GetMissions() ) do
--        local Mission = Mission -- Tasking.Mission#MISSION
--        local PlayerGroup = EventData.IniGroup -- The GROUP object should be filled!
--        Mission:JoinUnit( PlayerUnit, PlayerGroup )
--      end
--      self:SetMenu()
--    end
--  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.MissionEnd,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        Mission:Stop()
      end
    end
  )

--  -- Handle when a player leaves a slot and goes back to spectators ... 
--  -- The PlayerUnit will be UnAssigned from the Task.
--  -- When there is no Unit left running the Task, the Task goes into Abort...
--  self:HandleEvent( EVENTS.PlayerLeaveUnit,
--    --- @param #TASK self
--    -- @param Core.Event#EVENTDATA EventData
--    function( self, EventData )
--      local PlayerUnit = EventData.IniUnit
--      for MissionID, Mission in pairs( self:GetMissions() ) do
--        local Mission = Mission -- Tasking.Mission#MISSION
--        if Mission:IsENGAGED() then
--          Mission:AbortUnit( PlayerUnit )
--        end
--      end
--    end
--  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.Crash,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        if Mission:IsENGAGED() then
          Mission:CrashUnit( PlayerUnit )
        end
      end
    end
  )
  
  self:SetMenu()
  
  _SETTINGS:SetSystemMenu( CommandCenterPositionable )
	
	return self
end

--- Gets the name of the HQ command center.
-- @param #COMMANDCENTER self
-- @return #string
function COMMANDCENTER:GetName()

  return self.CommandCenterName
end

--- Gets the POSITIONABLE of the HQ command center.
-- @param #COMMANDCENTER self
-- @return Wrapper.Positionable#POSITIONABLE
function COMMANDCENTER:GetPositionable()
  return self.CommandCenterPositionable
end

--- Get the Missions governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @return #list<Tasking.Mission#MISSION>
function COMMANDCENTER:GetMissions()

  return self.Missions
end

--- Add a MISSION to be governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @param Tasking.Mission#MISSION Mission
-- @return Tasking.Mission#MISSION
function COMMANDCENTER:AddMission( Mission )

  self.Missions[Mission] = Mission

  return Mission
end

--- Removes a MISSION to be governed by the HQ command center.
-- The given Mission is not nilified.
-- @param #COMMANDCENTER self
-- @param Tasking.Mission#MISSION Mission
-- @return Tasking.Mission#MISSION
function COMMANDCENTER:RemoveMission( Mission )

  self.Missions[Mission] = nil

  return Mission
end

--- Set special Reference Zones known by the Command Center to guide airborne pilots during WWII.
-- 
-- These Reference Zones are normal trigger zones, with a special naming.
-- The Reference Zones need to be set by the Mission Designer in the Mission Editor.
-- Reference Zones are set by normal trigger zones. One can color the zones in a specific color, 
-- and the radius of the zones doesn't matter, only the center of the zone is important. Place the center of these Reference Zones at
-- specific scenery objects or points of interest (like cities, rivers, hills, crossing etc).
-- The trigger zones indicating a Reference Zone need to follow a specific syntax.
-- The name of each trigger zone expressing a Reference Zone need to start with a classification name of the object,
-- followed by a #, followed by a symbolic name of the Reference Zone.
-- A few examples:
-- 
--   * A church at Tskinvali would be indicated as: *Church#Tskinvali*
--   * A train station near Kobuleti would be indicated as: *Station#Kobuleti*
-- 
-- Taking the above example, this is how this method would be used:
-- 
--     CC:SetReferenceZones( "Church" )
--     CC:SetReferenceZones( "Station" )
-- 
-- 
-- @param #COMMANDCENTER self
-- @param #string ReferenceZonePrefix The name before the #-mark indicating the class of the Reference Zones.
-- @return #COMMANDCENTER
function COMMANDCENTER:SetReferenceZones( ReferenceZonePrefix )
  local MatchPattern = "(.*)#(.*)"
  self:F( { MatchPattern = MatchPattern } )
  for ReferenceZoneName in pairs( _DATABASE.ZONENAMES ) do
    local ZoneName, ReferenceName = string.match( ReferenceZoneName, MatchPattern )
    self:F( { ZoneName = ZoneName, ReferenceName = ReferenceName } )
    if ZoneName and ReferenceName and ZoneName == ReferenceZonePrefix then
      self.ReferencePoints[ReferenceZoneName] = ZONE:New( ReferenceZoneName )
      self.ReferenceNames[ReferenceZoneName] = ReferenceName
    end
  end
  return self
end

--- Set the commandcenter operations in WWII mode
-- This will disable LL, MGRS, BRA, BULLS navigatin messages sent by the Command Center, 
-- and will be replaced by a navigation using Reference Zones.
-- It will also disable the settings at the settings menu for these.
-- @param #COMMANDCENTER self
-- @return #COMMANDCENTER
function COMMANDCENTER:SetModeWWII()
  self.CommunicationMode = "WWII"
  return self
end


--- Returns if the commandcenter operations is in WWII mode
-- @param #COMMANDCENTER self
-- @return #boolean true if in WWII mode.
function COMMANDCENTER:IsModeWWII()
  return self.CommunicationMode == "WWII"
end




--- Sets the menu structure of the Missions governed by the HQ command center.
-- @param #COMMANDCENTER self
function COMMANDCENTER:SetMenu()
  self:F()

  local MenuTime = timer.getTime()
  for MissionID, Mission in pairs( self:GetMissions() or {} ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Mission:SetMenu( MenuTime )
  end

  for MissionID, Mission in pairs( self:GetMissions() or {} ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Mission:RemoveMenu( MenuTime )
  end
  
end

--- Gets the commandcenter menu structure governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @return Core.Menu#MENU_COALITION
function COMMANDCENTER:GetMenu()
  return self.CommandCenterMenu
end

--- Checks of the COMMANDCENTER has a GROUP.
-- @param #COMMANDCENTER self
-- @param Wrapper.Group#GROUP
-- @return #boolean
function COMMANDCENTER:HasGroup( MissionGroup )

  local Has = false
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    if Mission:HasGroup( MissionGroup ) then
      Has = true
      break
    end      
  end
  
  return Has
end

--- Send a CC message to the coalition of the CC.
-- @param #COMMANDCENTER self
function COMMANDCENTER:MessageToAll( Message )

    self:GetPositionable():MessageToAll( Message, 20, self:GetName() )

end

--- Send a CC message to a GROUP.
-- @param #COMMANDCENTER self
-- @param #string Message
-- @param Wrapper.Group#GROUP TaskGroup
function COMMANDCENTER:MessageToGroup( Message, TaskGroup )

  self:GetPositionable():MessageToGroup( Message, 15, TaskGroup, self:GetName() )

end

--- Send a CC message of a specified type to a GROUP.
-- @param #COMMANDCENTER self
-- @param #string Message
-- @param Wrapper.Group#GROUP TaskGroup
-- @param Core.Message#MESSAGE.MessageType MessageType The type of the message, resulting in automatic time duration and prefix of the message.
function COMMANDCENTER:MessageTypeToGroup( Message, TaskGroup, MessageType )

  self:GetPositionable():MessageTypeToGroup( Message, MessageType, TaskGroup, self:GetName() )

end

--- Send a CC message to the coalition of the CC.
-- @param #COMMANDCENTER self
function COMMANDCENTER:MessageToCoalition( Message )

  local CCCoalition = self:GetPositionable():GetCoalition()
    --TODO: Fix coalition bug!
    
    self:GetPositionable():MessageToCoalition( Message, 15, CCCoalition )

end


--- Send a CC message of a specified type to the coalition of the CC.
-- @param #COMMANDCENTER self
-- @param #string Message The message.
-- @param Core.Message#MESSAGE.MessageType MessageType The type of the message, resulting in automatic time duration and prefix of the message.
function COMMANDCENTER:MessageTypeToCoalition( Message, MessageType )

  local CCCoalition = self:GetPositionable():GetCoalition()
    --TODO: Fix coalition bug!
    
    self:GetPositionable():MessageTypeToCoalition( Message, MessageType, CCCoalition )

end


--- Report the status of all MISSIONs to a GROUP.
-- Each Mission is listed, with an indication how many Tasks are still to be completed.
-- @param #COMMANDCENTER self
function COMMANDCENTER:ReportMissionsStatus( ReportGroup )
  self:E( ReportGroup )

  local Report = REPORT:New()

  Report:Add( "Status report of all missions." )
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportStatus() )
  end
  
  self:MessageToGroup( Report:Text(), ReportGroup )
end

--- Report the players of all MISSIONs to a GROUP.
-- Each Mission is listed, with an indication how many Tasks are still to be completed.
-- @param #COMMANDCENTER self
function COMMANDCENTER:ReportMissionsPlayers( ReportGroup )
  self:E( ReportGroup )

  local Report = REPORT:New()
  
  Report:Add( "Players active in all missions." )

  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportPlayers() )
  end
  
  self:MessageToGroup( Report:Text(), ReportGroup )
end

--- Report the status of a Task to a Group.
-- Report the details of a Mission, listing the Mission, and all the Task details.
-- @param #COMMANDCENTER self
function COMMANDCENTER:ReportDetails( ReportGroup, Task )
  self:E( ReportGroup )

  local Report = REPORT:New()
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportDetails() )
  end
  
  self:MessageToGroup( Report:Text(), ReportGroup )
end

