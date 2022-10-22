--- **Functional** - Limit the movement of simulaneous moving ground vehicles.
-- 
-- ===
--  
-- Limit the simultaneous movement of Groups within a running Mission.
-- This module is defined to improve the performance in missions, and to bring additional realism for GROUND vehicles.
-- Performance: If in a DCSRTE there are a lot of moving GROUND units, then in a multi player mission, this WILL create lag if
-- the main DCS execution core of your CPU is fully utilized. So, this class will limit the amount of simultaneous moving GROUND units
-- on defined intervals (currently every minute).
-- @module Functional.Movement
-- @image MOOSE.JPG

--- @type MOVEMENT
-- @extends Core.Base#BASE

---
--@field #MOVEMENT
MOVEMENT = {
	ClassName = "MOVEMENT",
}

--- Creates the main object which is handling the GROUND forces movement.
-- @param table{string,...}|string MovePrefixes is a table of the Prefixes (names) of the GROUND Groups that need to be controlled by the MOVEMENT Object.
-- @param number MoveMaximum is a number that defines the maximum amount of GROUND Units to be moving during one minute.
-- @return MOVEMENT
-- @usage
-- -- Limit the amount of simultaneous moving units on the ground to prevent lag.
-- Movement_US_Platoons = MOVEMENT:New( { 'US Tank Platoon Left', 'US Tank Platoon Middle', 'US Tank Platoon Right', 'US CH-47D Troops' }, 15 )

function MOVEMENT:New( MovePrefixes, MoveMaximum )
	local self = BASE:Inherit( self, BASE:New() ) -- #MOVEMENT
	self:F( { MovePrefixes, MoveMaximum } )

	if type( MovePrefixes ) == 'table' then
		self.MovePrefixes = MovePrefixes
	else
		self.MovePrefixes = { MovePrefixes }
	end
	self.MoveCount = 0              -- The internal counter of the amount of Moving the has happened since MoveStart.
	self.MoveMaximum = MoveMaximum  -- Contains the Maximum amount of units that are allowed to move.
	self.AliveUnits = 0             -- Contains the counter how many units are currently alive.
	self.MoveUnits = {}             -- Reflects if the Moving for this MovePrefixes is going to be scheduled or not.

	self:HandleEvent( EVENTS.Birth )

--	self:AddEvent( world.event.S_EVENT_BIRTH, self.OnBirth )
--	
--	self:EnableEvents()

	self:ScheduleStart()

	return self
end

--- Call this function to start the MOVEMENT scheduling.
function MOVEMENT:ScheduleStart()
	self:F()
	--self.MoveFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 120 )
  self.MoveFunction = SCHEDULER:New( self, self._Scheduler, {}, 1, 120 )
end

--- Call this function to stop the MOVEMENT scheduling.
-- @todo need to implement it ... Forgot.
function MOVEMENT:ScheduleStop()
	self:F()

end

--- Captures the birth events when new Units were spawned.
-- @todo This method should become obsolete. The global _DATABASE object (an instance of @{Core.Database#DATABASE}) will handle the collection administration.
-- @param #MOVEMENT self
-- @param Core.Event#EVENTDATA self
function MOVEMENT:OnEventBirth( EventData )
	self:F( { EventData } )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if EventData.IniDCSUnit then
			self:T( "Birth object : " .. EventData.IniDCSUnitName )
			if EventData.IniDCSGroup and EventData.IniDCSGroup:isExist() then
				for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
					if string.find( EventData.IniDCSUnitName, MovePrefix, 1, true ) then
						self.AliveUnits = self.AliveUnits + 1
						self.MoveUnits[EventData.IniDCSUnitName] = EventData.IniDCSGroupName
						self:T( self.AliveUnits )
					end
				end
			end
		end
	
		EventData.IniUnit:HandleEvent( EVENTS.DEAD, self.OnDeadOrCrash )
	end

end

--- Captures the Dead or Crash events when Units crash or are destroyed.
-- @todo This method should become obsolete. The global _DATABASE object (an instance of @{Core.Database#DATABASE}) will handle the collection administration.
function MOVEMENT:OnDeadOrCrash( Event )
	self:F( { Event } )

	if Event.IniDCSUnit then
		self:T( "Dead object : " .. Event.IniDCSUnitName )
		for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
			if string.find( Event.IniDCSUnitName, MovePrefix, 1, true ) then
				self.AliveUnits = self.AliveUnits - 1
				self.MoveUnits[Event.IniDCSUnitName] = nil
				self:T( self.AliveUnits )
			end
		end
	end
end

--- This function is called automatically by the MOVEMENT scheduler. A new function is scheduled when MoveScheduled is true.
function MOVEMENT:_Scheduler()
	self:F( { self.MovePrefixes, self.MoveMaximum, self.AliveUnits, self.MovementGroups } )
	
	if self.AliveUnits > 0 then
		local MoveProbability = ( self.MoveMaximum * 100 ) / self.AliveUnits
		self:T( 'Move Probability = ' .. MoveProbability )
		
		for MovementUnitName, MovementGroupName in pairs( self.MoveUnits ) do
			local MovementGroup = Group.getByName( MovementGroupName )
			if MovementGroup and MovementGroup:isExist() then
				local MoveOrStop = math.random( 1, 100 )
				self:T( 'MoveOrStop = ' .. MoveOrStop )
				if MoveOrStop <= MoveProbability then
					self:T( 'Group continues moving = ' .. MovementGroupName )
					trigger.action.groupContinueMoving( MovementGroup )
				else
					self:T( 'Group stops moving = ' .. MovementGroupName )
					trigger.action.groupStopMoving( MovementGroup )
				end
			else
				self.MoveUnits[MovementUnitName] = nil
			end
		end
	end
	return true
end
