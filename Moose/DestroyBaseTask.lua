--- A DESTROYBASETASK will monitor the destruction of Groups and Units. This is a BASE class, other classes are derived from this class.
-- @classmod DESTROYBASETASK
-- @see DESTROYGROUPSTASK
-- @see DESTROYUNITTYPESTASK
-- @see DESTROY_RADARS_TASK

Include.File("Task")

DESTROYBASETASK = {
  ClassName = "DESTROYBASETASK",
  Destroyed = 0,
  GoalVerb = "Destroy",
  DestroyPercentage = 100,
}

--- Creates a new DESTROYBASETASK.
-- @tparam string DestroyGroupType Text describing the group to be destroyed. f.e. "Radar Installations", "Ships", "Vehicles", "Command Centers".
-- @tparam string DestroyUnitType Text describing the unit types to be destroyed. f.e. "SA-6", "Row Boats", "Tanks", "Tents".
-- @tparam table{string,...} DestroyGroupPrefixes Table of Prefixes of the Groups to be destroyed before task is completed.
-- @tparam ?number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
-- @treturn DESTROYBASETASK
function DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupPrefixes, DestroyPercentage )
trace.f(self.ClassName)

	-- Inheritance
	local Child = BASE:Inherit( self, TASK:New() )
	
	Child.Name = 'Destroy'
	Child.Destroyed = 0
	Child.DestroyGroupPrefixes = DestroyGroupPrefixes
	Child.DestroyGroupType = DestroyGroupType
	Child.DestroyUnitType = DestroyUnitType
	Child.TaskBriefing = "Task: Destroy " .. DestroyGroupType .. "."
    Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEGROUPSDESTROYED:New(), STAGEDONE:New() }
	Child.SetStage( Child, 1 )

	--Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.EventDead )

	--env.info( 'New Table Child = ' .. tostring(Child) )
	--env.info( 'New Table self = ' .. tostring(self) )
	
	return Child
end

--- Handle the S_EVENT_DEAD events to validate the destruction of units for the task monitoring.
-- @param 	event 		Event structure of DCS world.
function DESTROYBASETASK:EventDead( event )
trace.f( self.ClassName, { 'EventDead', event } )
	
	if event.initiator then
		local DestroyGroup = Unit.getGroup( event.initiator )
		local DestroyGroupName = DestroyGroup:getName()
		local DestroyUnit = event.initiator
		local DestroyUnitName = DestroyUnit:getName()
		local UnitsDestroyed = 0
		trace.i( self.ClassName, DestroyGroupName )
		trace.i( self.ClassName, DestroyUnitName )
		for DestroyGroupPrefixID, DestroyGroupPrefix in pairs( self.DestroyGroupPrefixes ) do
			trace.i( self.ClassName, DestroyGroupPrefix )
			if string.find( DestroyGroupName, DestroyGroupPrefix, 1, true ) then
				trace.i( self.ClassName, BASE:Inherited(self).ClassName )
				UnitsDestroyed = self:ReportGoalProgress( DestroyGroup, DestroyUnit )
				trace.i( self.ClassName, UnitsDestroyed )
			end
		end
		
		trace.i( self.ClassName, { UnitsDestroyed } )
		self:IncreaseGoalCount( UnitsDestroyed, self.GoalVerb )
	end
end

--- Validate task completeness of DESTROYBASETASK.
-- @param 	DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYBASETASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
trace.f(self.ClassName)

	return 0
end
