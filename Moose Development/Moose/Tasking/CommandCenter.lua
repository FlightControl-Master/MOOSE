--- A COMMANDCENTER is the owner of multiple missions within MOOSE. 
-- A COMMANDCENTER governs multiple missions, the tasking and the reporting.
-- @module CommandCenter



--- The REPORT class
-- @type REPORT
-- @extends Core.Base#BASE
REPORT = {
  ClassName = "REPORT",
}

--- Create a new REPORT.
-- @param #REPORT self
-- @param #string Title
-- @return #REPORT
function REPORT:New( Title )

  local self = BASE:Inherit( self, BASE:New() )

  self.Report = {}
  if Title then
    self.Report[#self.Report+1] = Title  
  end

  return self
end

--- Add a new line to a REPORT.
-- @param #REPORT self
-- @param #string Text
-- @return #REPORT
function REPORT:Add( Text )
  self.Report[#self.Report+1] = Text
  return self.Report[#self.Report]
end

--- Produces the text of the report, taking into account an optional delimeter, which is \n by default.
-- @param #REPORT self
-- @param #string Delimiter (optional) A delimiter text.
-- @return #string The report text.
function REPORT:Text( Delimiter )
  Delimiter = Delimiter or "\n"
  local ReportText = table.concat( self.Report, Delimiter ) or ""
  return ReportText
end

--- The COMMANDCENTER class
-- @type COMMANDCENTER
-- @field Wrapper.Group#GROUP HQ
-- @field Dcs.DCSCoalitionWrapper.Object#coalition CommandCenterCoalition
-- @list<Tasking.Mission#MISSION> Missions
-- @extends Core.Base#BASE
COMMANDCENTER = {
  ClassName = "COMMANDCENTER",
  CommandCenterName = "",
  CommandCenterCoalition = nil,
  CommandCenterPositionable = nil,
  Name = "",
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
          local MenuReporting = MENU_GROUP:New( EventGroup, "Reporting", self.CommandCenterMenu )
          local MenuMissionsSummary = MENU_GROUP_COMMAND:New( EventGroup, "Missions Summary Report", MenuReporting, self.ReportSummary, self, EventGroup )
          local MenuMissionsDetails = MENU_GROUP_COMMAND:New( EventGroup, "Missions Details Report", MenuReporting, self.ReportDetails, self, EventGroup )
          self:ReportSummary( EventGroup )
        end
        local PlayerUnit = EventData.IniUnit
        for MissionID, Mission in pairs( self:GetMissions() ) do
          local Mission = Mission -- Tasking.Mission#MISSION
          local PlayerGroup = EventData.IniGroup -- The GROUP object should be filled!
          Mission:JoinUnit( PlayerUnit, PlayerGroup )
          Mission:ReportDetails()
        end
      end
      
    end
    )
  
  -- When a player enters a client or a unit, the CommandCenter will check for each Mission and each Task in the Mission if the player has things to do.
  -- For these elements, it will=
  -- - Set the correct menu.
  -- - Assign the PlayerUnit to the Task if required.
  -- - Send a message to the other players in the group that this player has joined.
  self:HandleEvent( EVENTS.PlayerEnterUnit,
    --- @param #COMMANDCENTER self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        local PlayerGroup = EventData.IniGroup -- The GROUP object should be filled!
        Mission:JoinUnit( PlayerUnit, PlayerGroup )
        Mission:ReportDetails()
      end
    end
  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.PlayerLeaveUnit,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        Mission:AbortUnit( PlayerUnit )
      end
    end
  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:HandleEvent( EVENTS.Crash,
    --- @param #TASK self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        Mission:CrashUnit( PlayerUnit )
      end
    end
  )
	
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

--- Sets the menu structure of the Missions governed by the HQ command center.
-- @param #COMMANDCENTER self
function COMMANDCENTER:SetMenu()
  self:F()

  self.CommandCenterMenu = self.CommandCenterMenu or MENU_COALITION:New( self.CommandCenterCoalition, "Command Center (" .. self:GetName() .. ")" )

  local MenuTime = timer.getTime()
  for MissionID, Mission in pairs( self:GetMissions() ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Mission:SetMenu( MenuTime )
  end

  for MissionID, Mission in pairs( self:GetMissions() ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Mission:RemoveMenu( MenuTime )
  end
  
end

--- Gets the commandcenter menu structure governed by the HQ command center.
-- @param #COMMANDCENTER self
-- @return Core.Menu#MENU_COALITION
function COMMANDCENTER:GetMenu()
  self:F()
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
-- @param #sring Name (optional) The name of the Group used as a prefix for the message to the Group. If not provided, there will be nothing shown.
function COMMANDCENTER:MessageToGroup( Message, TaskGroup, Name )

  local Prefix = "@ Group"
  Prefix = Prefix .. ( Name and " (" .. Name .. "): " or '' )
  Message = Prefix .. Message 
  self:GetPositionable():MessageToGroup( Message , 20, TaskGroup, self:GetName() )

end

--- Send a CC message to the coalition of the CC.
-- @param #COMMANDCENTER self
function COMMANDCENTER:MessageToCoalition( Message )

  local CCCoalition = self:GetPositionable():GetCoalition()
    --TODO: Fix coalition bug!
    self:GetPositionable():MessageToCoalition( Message, 20, CCCoalition, self:GetName() )

end


--- Report the status of all MISSIONs to a GROUP.
-- Each Mission is listed, with an indication how many Tasks are still to be completed.
-- @param #COMMANDCENTER self
function COMMANDCENTER:ReportSummary( ReportGroup )
  self:E( ReportGroup )

  local Report = REPORT:New()
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportOverview() )
  end
  
  self:GetPositionable():MessageToGroup( Report:Text(), 30, ReportGroup )
  
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
  
  self:GetPositionable():MessageToGroup( Report:Text(), 30, ReportGroup )
end

