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
-- @param #DESTROYBASETASK self
-- @param #string DestroyGroupType Text describing the group to be destroyed. f.e. "Radar Installations", "Ships", "Vehicles", "Command Centers".
-- @param #string DestroyUnitType Text describing the unit types to be destroyed. f.e. "SA-6", "Row Boats", "Tanks", "Tents".
-- @param #list<#string> DestroyGroupPrefixes Table of Prefixes of the Groups to be destroyed before task is completed.
-- @param #number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
-- @return DESTROYBASETASK
function DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupPrefixes, DestroyPercentage )
	local self = BASE:Inherit( self, TASK:New() )
	self:F()
	
	self.Name = 'Destroy'
	self.Destroyed = 0
	self.DestroyGroupPrefixes = DestroyGroupPrefixes
	self.DestroyGroupType = DestroyGroupType
	self.DestroyUnitType = DestroyUnitType
	if DestroyPercentage then
  	self.DestroyPercentage = DestroyPercentage
  end
	self.TaskBriefing = "Task: Destroy " .. DestroyGroupType .. "."
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEGROUPSDESTROYED:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )

	return self
end

--- Handle the S_EVENT_DEAD events to validate the destruction of units for the task monitoring.
-- @param #DESTROYBASETASK self
-- @param Event#EVENTDATA Event structure of MOOSE.
function DESTROYBASETASK:EventDead( Event )
	self:F( { Event } )
	
	if Event.IniDCSUnit then
		local DestroyUnit = Event.IniDCSUnit
		local DestroyUnitName = Event.IniDCSUnitName
		local DestroyGroup = Event.IniDCSGroup
		local DestroyGroupName = Event.IniDCSGroupName

    --TODO: I need to fix here if 2 groups in the mission have a similar name with GroupPrefix equal, then i should differentiate for which group the goal was reached!
    --I may need to test if for the goalverb that group goal was reached or something. Need to think about it a bit more ...
		local UnitsDestroyed = 0
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
