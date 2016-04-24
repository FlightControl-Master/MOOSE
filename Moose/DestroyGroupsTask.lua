--- DESTROYGROUPSTASK
-- @module DESTROYGROUPSTASK

Include.File("DestroyBaseTask")

--- The DESTROYGROUPSTASK class
-- @type
DESTROYGROUPSTASK = {
  ClassName = "DESTROYGROUPSTASK",
  GoalVerb = "Destroy Groups",
}

--- Creates a new DESTROYGROUPSTASK.
-- @param #DESTROYGROUPSTASK self
-- @param #string DestroyGroupType 	String describing the group to be destroyed.
-- @param #string DestroyUnitType 	String describing the unit to be destroyed.
-- @param #list<#string> DestroyGroupNames 	Table of string containing the name of the groups to be destroyed before task is completed.
-- @param #number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
---@return DESTROYGROUPSTASK
function DESTROYGROUPSTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage )
	local self = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage ) )
	self:F()
  
	self.Name = 'Destroy Groups'
	self.GoalVerb = "Destroy " .. DestroyGroupType
	
  _EVENTDISPATCHER:OnDead( self.EventDead , self )
  _EVENTDISPATCHER:OnCrash( self.EventDead , self )

	return self
end

--- Report Goal Progress.
-- @param #DESTROYGROUPSTASK self
-- @param DCSGroup#Group DestroyGroup Group structure describing the group to be evaluated.
-- @param DCSUnit#Unit DestroyUnit Unit structure describing the Unit to be evaluated.
-- @return #number The DestroyCount reflecting the amount of units destroyed within the group.
function DESTROYGROUPSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F( { DestroyGroup, DestroyUnit, self.DestroyPercentage } )
	
	local DestroyGroupSize = DestroyGroup:getSize() - 1 -- When a DEAD event occurs, the getSize is still one larger than the destroyed unit.
	local DestroyGroupInitialSize = DestroyGroup:getInitialSize()
	self:T( { DestroyGroupSize, DestroyGroupInitialSize - ( DestroyGroupInitialSize * self.DestroyPercentage / 100 ) } )

	local DestroyCount = 0
	if DestroyGroup then
		if DestroyGroupSize <= DestroyGroupInitialSize - ( DestroyGroupInitialSize * self.DestroyPercentage / 100 ) then
			DestroyCount = 1
		end
	else
		DestroyCount = 1
	end
	
	self:T( DestroyCount )
	
	return DestroyCount
end
