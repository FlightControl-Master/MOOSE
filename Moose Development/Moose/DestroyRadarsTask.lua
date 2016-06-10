--- Task class to destroy radar installations.
-- @module DESTROYRADARSTASK 



--- The DESTROYRADARS class
-- @type
DESTROYRADARSTASK = {
  ClassName = "DESTROYRADARSTASK",
  GoalVerb = "Destroy Radars"
}

--- Creates a new DESTROYRADARSTASK.
-- @param table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @return DESTROYRADARSTASK
function DESTROYRADARSTASK:New( DestroyGroupNames )
	local self = BASE:Inherit( self, DESTROYGROUPSTASK:New( 'radar installations', 'radars', DestroyGroupNames ) )
	self:F()

	self.Name = 'Destroy Radars'

  _EVENTDISPATCHER:OnDead( self.EventDead , self )

	return self
end

--- Report Goal Progress.
-- @param 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYRADARSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F( { DestroyGroup, DestroyUnit } )

	local DestroyCount = 0
	if DestroyUnit and DestroyUnit:hasSensors( Unit.SensorType.RADAR, Unit.RadarType.AS ) then
		if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
			self:T( 'Destroyed a radar' )
			DestroyCount = 1
		end
	end
	return DestroyCount
end
