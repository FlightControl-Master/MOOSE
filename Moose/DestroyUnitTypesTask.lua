--- Set TASK to destroy certain unit types.
-- @module DESTROYUNITTYPESTASK

Include.File("DestroyBaseTask")

--- The DESTROYUNITTYPESTASK class
-- @type
DESTROYUNITTYPESTASK = {
  ClassName = "DESTROYUNITTYPESTASK",
	GoalVerb = "Destroy",
}

--- Creates a new DESTROYUNITTYPESTASK.
-- @param string DestroyGroupType 		String describing the group to be destroyed. f.e. "Radar Installations", "Fleet", "Batallion", "Command Centers".
-- @param string DestroyUnitType 		String describing the unit to be destroyed. f.e. "radars", "ships", "tanks", "centers".
-- @param table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @param string DestroyUnitTypes	 	Table of string containing the type names of the units to achieve mission success.
-- @return DESTROYUNITTYPESTASK
function DESTROYUNITTYPESTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyUnitTypes )
	local self = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames ) )
	self:F( { DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyUnitTypes } )
  	
	if type(DestroyUnitTypes) == 'table' then
		self.DestroyUnitTypes = DestroyUnitTypes
	else
		self.DestroyUnitTypes = { DestroyUnitTypes }
	end
	
	self.Name = 'Destroy Unit Types'
	self.GoalVerb = "Destroy " .. DestroyGroupType

	self:AddEvent( world.event.S_EVENT_DEAD, self.EventDead )

	return self
end

--- Report Goal Progress.
-- @param 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYUNITTYPESTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F( { DestroyGroup, DestroyUnit } )

	local DestroyCount = 0
	for UnitTypeID, UnitType in pairs( self.DestroyUnitTypes ) do
		if DestroyUnit and DestroyUnit:getTypeName() == UnitType then
			if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
				DestroyCount = DestroyCount + 1
			end
		end
	end
	return DestroyCount
end
