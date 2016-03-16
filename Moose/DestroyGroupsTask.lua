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
-- @param 	string DestroyGroupType 	String describing the group to be destroyed.
-- @param 	string DestroyUnitType 	String describing the unit to be destroyed.
-- @param 	table{string,...} DestroyGroupNames 	Table of string containing the name of the groups to be destroyed before task is completed.
-- @param ?number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
---@return DESTROYGROUPSTASK
function DESTROYGROUPSTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage )
trace.f(self.ClassName)

	-- Inheritance
	local Child = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage ) )

	Child.Name = 'Destroy Groups'
	Child.GoalVerb = "Destroy " .. DestroyGroupType
	
	Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.EventDead )
	Child.AddEvent( Child, world.event.S_EVENT_CRASH, Child.EventDead )
	--Child.AddEvent( Child, world.event.S_EVENT_PILOT_DEAD, Child.EventDead )

	return Child
end

--- Report Goal Progress.
-- @param 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYGROUPSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
trace.f(self.ClassName)
	trace.i( self.ClassName, DestroyGroup:getSize() )

	local DestroyCount = 0
	if DestroyGroup then
		if ( ( DestroyGroup:getInitialSize() * self.DestroyPercentage ) / 100 ) - DestroyGroup:getSize() <= 0 then
			DestroyCount = 1
--[[ 		else
			if DestroyGroup:getSize() == 1 then
				if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
					DestroyCount = 1
				end
			end
 ]]		end
	else
		DestroyCount = 1
	end
	
	return DestroyCount
end
