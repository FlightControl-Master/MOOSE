--- Task class to destroy radar installations.
-- @classmod DESTROYRADARSTASK 

Include.File("DestroyBaseTask")

DESTROYRADARSTASK = {
  ClassName = "DESTROYRADARSTASK",
  GoalVerb = "Destroy Radars"
}

--- Creates a new DESTROYRADARSTASK.
-- @tparam table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @treturn DESTROYRADARSTASK
function DESTROYRADARSTASK:New( DestroyGroupNames )
trace.f(self.ClassName)

	-- Inheritance
	local Child = BASE:Inherit( self, DESTROYGROUPSTASK:New( 'radar installations', 'radars', DestroyGroupNames ) )

	Child.Name = 'Destroy Radars'

	
	Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.EventDead )

	return Child
end

--- Report Goal Progress.
-- @tparam 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @tparam 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYRADARSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
trace.f(self.ClassName)

	local DestroyCount = 0
	if DestroyUnit and DestroyUnit:hasSensors( Unit.SensorType.RADAR, Unit.RadarType.AS ) then
		if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
			trace.i( self.ClassName, 'Destroyed a radar' )
			DestroyCount = 1
		end
	end
	return DestroyCount
end
