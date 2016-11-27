--- A COMMANDCENTER is the owner of multiple missions within MOOSE. 
-- A COMMANDCENTER governs multiple missions, the tasking and the reporting.
-- @module CommandCenter

--- The COMMANDCENTER class
-- @type COMMANDCENTER
-- @field Wrapper.Group#GROUP HQ
-- @list<Tasking.Mission#MISSION> Missions
-- @extends Core.Base#BASE
COMMANDCENTER = {
	ClassName = "COMMANDCENTER",
	Name = "",
}

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


--- The constructor takes an IDENTIFIABLE as the HQ command center.
-- @param #COMMANDCENTER self
-- @param Wrapper.Positionable#POSITIONABLE HQ
-- @param #string HQName
-- @return #COMMANDCENTER
function COMMANDCENTER:New( HQ, HQName )

  local self = BASE:Inherit( self, BASE:New() )

  self.HQ = HQ  
  self.HQName = HQName or HQ:GetName()
  self.HQCoalition = HQ:GetCoalition()
	
	self.Missions = {}
	setmetatable( self.Missions, { __mode = "v" } )

  self:EventOnBirth(
    --- @param Core.Event#EVENTDATA EventData
    function( HQ, EventData )
      self:E( { EventData } )
      local EventGroup = GROUP:Find( EventData.IniDCSGroup )
      if EventGroup and HQ:HasGroup( EventGroup ) then
        local MenuHQ = MENU_GROUP:New( EventGroup, "HQ" )
        local MenuReporting = MENU_GROUP:New( EventGroup, "Reporting", MenuHQ )
        local MenuMissions = MENU_GROUP_COMMAND:New( EventGroup, "Missions", MenuReporting, HQ.ReportMissions, HQ, EventGroup )
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

  for MissionID, Mission in pairs( self.Missions ) do
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


--- Report the status of all MISSIONs to a GROUP.
function COMMANDCENTER:ReportMissions( ReportGroup )
  self:E( ReportGroup )

  local Report = REPORT:New()
  
  for MissionID, Mission in pairs( self.Missions ) do
    local Mission = Mission -- Tasking.Mission#MISSION
    Report:Add( " - " .. Mission:ReportStatus() )
  end
  
  MESSAGE:New( Report:Text(), 30, "Status Report Missions from " .. self:GetName() .. "\n" ):ToGroup( ReportGroup )
  
end

