--- A DESTROYBASETASK will monitor the destruction of Groups and Units. This is a BASE class, other classes are derived from this class.
-- @module DESTROYBASETASK
-- @see DESTROYGROUPSTASK
-- @see DESTROYUNITTYPESTASK
-- @see DESTROY_RADARS_TASK

Include.File("Task")

--- The DESTROYBASETASK class
-- @type DESTROYBASETASK
DESTROYBASETASK = {
  ClassName = "DESTROYBASETASK",
  Destroyed = 0,
  GoalVerb = "Destroy",
  DestroyPercentage = 100,
}

--- Creates a new DESTROYBASETASK.
-- @param string DestroyGroupType Text describing the group to be destroyed. f.e. "Radar Installations", "Ships", "Vehicles", "Command Centers".
-- @param string DestroyUnitType Text describing the unit types to be destroyed. f.e. "SA-6", "Row Boats", "Tanks", "Tents".
-- @param table{string,...} DestroyGroupPrefixes Table of Prefixes of the Groups to be destroyed before task is completed.
-- @param ?number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
-- @return DESTROYBASETASK
function DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupPrefixes, DestroyPercentage )
	local self = BASE:Inherit( self, TASK:New() )
	self:F()
	
	self.Name = 'Destroy'
	self.Destroyed = 0
	self.DestroyGroupPrefixes = DestroyGroupPrefixes
	self.DestroyGroupType = DestroyGroupType
	self.DestroyUnitType = DestroyUnitType
	self.TaskBriefing = "Task: Destroy " .. DestroyGroupType .. "."
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEGROUPSDESTROYED:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )

	--self.AddEvent( self, world.event.S_EVENT_DEAD, self.EventDead )

	--env.info( 'New Table self = ' .. tostring(self) )
	--env.info( 'New Table self = ' .. tostring(self) )
	
	return self
end

--- Handle the S_EVENT_DEAD events to validate the destruction of units for the task monitoring.
-- @param 	event 		Event structure of DCS world.
function DESTROYBASETASK:EventDead( event )
	self:F( { 'EventDead', event } )
	
	if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
		local DestroyUnit = event.initiator
		local DestroyUnitName = DestroyUnit:getName()
		local DestroyGroup = Unit.getGroup( DestroyUnit )
		local DestroyGroupName = ""
		if DestroyGroup and DestroyGroup:isExist() then
			local DestroyGroupName = DestroyGroup:getName()
		end
		local UnitsDestroyed = 0
		self:T( DestroyGroupName )
		self:T( DestroyUnitName )
		for DestroyGroupPrefixID, DestroyGroupPrefix in pairs( self.DestroyGroupPrefixes ) do
			self:T( DestroyGroupPrefix )
			if string.find( DestroyGroupName, DestroyGroupPrefix, 1, true ) then
				self:T( BASE:Inherited(self).ClassName )
				UnitsDestroyed = self:ReportGoalProgress( DestroyGroup, DestroyUnit )
				self:T( UnitsDestroyed )
			end
		end
		
		self:T( { UnitsDestroyed } )
		self:IncreaseGoalCount( UnitsDestroyed, self.GoalVerb )
	end
end

--- Validate task completeness of DESTROYBASETASK.
-- @param 	DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYBASETASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F()

	return 0
end
