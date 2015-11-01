--- Limit the simultaneous movement of Groups within a running Mission.
-- This module is defined to improve the performance in missions, and to bring additional realism for GROUND vehicles.
-- Performance: If in a DCSRTE there are a lot of moving GROUND units, then in a multi player mission, this WILL create lag if
-- the main DCS execution core of your CPU is fully utilized. So, this class will limit the amount of simultaneous moving GROUND units
-- on defined intervals (currently every minute).
-- @classmod MOVEMENT

Include.File( "Routines" )

MOVEMENT = {
	ClassName = "MOVEMENT",
}

--- Creates the main object which is handling the GROUND forces movement.
-- @tparam table{string,...}|string MovePrefixes is a table of the Prefixes (names) of the GROUND Groups that need to be controlled by the MOVEMENT Object.
-- @tparam number MoveMaximum is a number that defines the maximum amount of GROUND Units to be moving during one minute.
-- @treturn MOVEMENT
-- @usage
-- -- Limit the amount of simultaneous moving units on the ground to prevent lag.
-- Movement_US_Platoons = MOVEMENT:New( { 'US Tank Platoon Left', 'US Tank Platoon Middle', 'US Tank Platoon Right', 'US CH-47D Troops' }, 15 )

function MOVEMENT:New( MovePrefixes, MoveMaximum )
trace.f(self.ClassName, { MovePrefixes, MoveMaximum } )

	-- Inherits from BASE
	local Child = BASE:Inherit( self, BASE:New() )
  
	if type( MovePrefixes ) == 'table' then
		Child.MovePrefixes = MovePrefixes
	else
		Child.MovePrefixes = { MovePrefixes }
	end
	Child.MoveCount = 0															-- The internal counter of the amount of Moveing the has happened since MoveStart.
	Child.MoveMaximum = MoveMaximum												-- Contains the Maximum amount of units that are allowed to move...
	Child.AliveUnits = 0														-- Contains the counter how many units are currently alive
	Child.MoveGroups = {}														-- Reflects if the Moveing for this MovePrefixes is going to be scheduled or not.
	
	Child.AddEvent( Child, world.event.S_EVENT_BIRTH, Child.OnBirth )
	Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.OnDeadOrCrash )
	Child.AddEvent( Child, world.event.S_EVENT_CRASH, Child.OnDeadOrCrash )
	
	Child.EnableEvents( Child )
	
	Child.ScheduleStart( Child )

	return Child
end

--- Call this function to start the MOVEMENT scheduling.
function MOVEMENT:ScheduleStart()
trace.f( self.ClassName )
	self.MoveFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 60 )
end

--- Call this function to stop the MOVEMENT scheduling.
-- @todo need to implement it ... Forgot.
function MOVEMENT:ScheduleStop()
trace.f( self.ClassName )

end

--- Captures the birth events when new Units were spawned.
-- @todo This method should become obsolete. The new @{DATABASE} class will handle the collection administration.
function MOVEMENT:OnBirth( event )
trace.f( self.ClassName, { event } )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and event.initiator:getName() then
			trace.l(self.ClassName, "OnBirth", "Birth object : " .. event.initiator:getName() )
			local GroupData = Unit.getGroup(event.initiator)
			if GroupData and GroupData:isExist() then
				local EventGroupName = GroupData:getName()
				for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
					if string.find( EventGroupName, MovePrefix, 1, true ) then
						self.AliveUnits = self.AliveUnits + 1
						self.MoveGroups[EventGroupName] = EventGroupName
						trace.l(self.ClassName, "OnBirth", self.AliveUnits )
					end
				end
			end
		end
	end

end

--- Captures the Dead or Crash events when Units crash or are destroyed.
-- @todo This method should become obsolete. The new @{DATABASE} class will handle the collection administration.
function MOVEMENT:OnDeadOrCrash( event )
trace.f( self.ClassName, { event } )

	if event.initiator and event.initiator:getName() then
		trace.l( self.ClassName, "OnDeadOrCrash", "Dead object : " .. event.initiator:getName() )
		local EventGroupName = Unit.getGroup(event.initiator):getName()
		for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
			if string.find( EventGroupName, MovePrefix, 1, true ) then
				self.AliveUnits = self.AliveUnits - 1
				self.MoveGroups[EventGroupName] = nil
				trace.l( self.ClassName, "OnDeadOrCrash", self.AliveUnits )
			end
		end
	end
end

--- This function is called automatically by the MOVEMENT scheduler. A new function is scheduled when MoveScheduled is true.
function MOVEMENT:_Scheduler()
trace.l( self.ClassName, '_Scheduler', { self.MovePrefixes, self.MoveMaximum, self.AliveUnits, self.MoveGroups } )
	
	if self.AliveUnits > 0 then
		local MoveProbability = ( self.MoveMaximum * 100 ) / self.AliveUnits
		trace.l( self.ClassName, '_Scheduler', 'Move Probability = ' .. MoveProbability )
		
		for MoveGroupID, MoveGroupName in pairs( self.MoveGroups ) do
			local MoveGroup = Group.getByName( MoveGroupName )
			if MoveGroup then
				local MoveOrStop = math.random( 1, 100 )
				trace.l( self.ClassName, '_Scheduler', 'MoveOrStop = ' .. MoveOrStop )
				if MoveOrStop <= MoveProbability then
					trace.l( self.ClassName, '_Scheduler', 'Group continues moving = ' .. MoveGroupName )
					trigger.action.groupContinueMoving( MoveGroup )
				else
					trace.l( self.ClassName, '_Scheduler', 'Group stops moving = ' .. MoveGroupName )
					trigger.action.groupStopMoving( MoveGroup )
				end
			end
		end
	end
end
