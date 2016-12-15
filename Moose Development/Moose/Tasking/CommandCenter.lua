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
  self.Report[#self.Report+1] = Title  

  return self
end

--- Add a new line to a REPORT.
-- @param #REPORT self
-- @param #string Text
-- @return #REPORT
function REPORT:Add( Text )
  self.Report[#self.Report+1] = Text
  return self.Report[#self.Report+1]
end

function REPORT:Text()
  return table.concat( self.Report, "\n" ) 
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
	
	self.Missions = setmetatable( {}, { __mode = "v" } )

  self:EventOnBirth(
    --- @param #COMMANDCENTER self
    --- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      self:E( { EventData } )
      local EventGroup = GROUP:Find( EventData.IniDCSGroup )
      if EventGroup and self:HasGroup( EventGroup ) then
        local MenuReporting = MENU_GROUP:New( EventGroup, "Reporting", self.CommandCenterMenu )
        local MenuMissionsSummary = MENU_GROUP_COMMAND:New( EventGroup, "Missions Summary Report", MenuReporting, self.ReportSummary, self, EventGroup )
        local MenuMissionsDetails = MENU_GROUP_COMMAND:New( EventGroup, "Missions Details Report", MenuReporting, self.ReportDetails, self, EventGroup )
        self:ReportSummary( EventGroup )
      end
    end
    )
  
  -- When a player enters a client or a unit, the CommandCenter will check for each Mission and each Task in the Mission if the player has things to do.
  -- For these elements, it will=
  -- - Set the correct menu.
  -- - Assign the PlayerUnit to the Task if required.
  -- - Send a message to the other players in the group that this player has joined.
  self:EventOnPlayerEnterUnit(
    --- @param #COMMANDCENTER self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        local Mission = Mission -- Tasking.Mission#MISSION
        Mission:AddUnit( PlayerUnit )
        Mission:ReportDetails()
      end
    end
  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:EventOnPlayerLeaveUnit(
    --- @param #TASK_BASE self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      local PlayerUnit = EventData.IniUnit
      for MissionID, Mission in pairs( self:GetMissions() ) do
        Mission:AbortUnit( PlayerUnit )
      end
    end
  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The PlayerUnit will be UnAssigned from the Task.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:EventOnCrash(
    --- @param #TASK_BASE self
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

  return self.HQName
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

  self.CommandCenterMenu = self.CommandCenterMenu or MENU_COALITION:New( self.CommandCenterCoalition, "HQ" )
  
  for MissionID, Mission in pairs( self:GetMissions() ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Mission:SetMenu()
  end
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

--- Send a CC message to a GROUP.
-- @param #COMMANDCENTER self
function COMMANDCENTER:MessageToGroup( Message, TaskGroup )

    self:GetPositionable():MessageToGroup( Message , 20, TaskGroup )

end

--- Send a CC message to the coalition of the CC.
-- @param #COMMANDCENTER self
function COMMANDCENTER:MessageToCoalition( Message )

  local CCCoalition = self:GetPositionable():GetCoalition()
    self:GetPositionable():MessageToBlue( Message , 20, CCCoalition )

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

