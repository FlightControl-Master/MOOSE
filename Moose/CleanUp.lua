--- CLEANUP Classes
-- @module CLEANUP
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

--- The CLEANUP class.
-- @type CLEANUP
CLEANUP = {
	ClassName = "CLEANUP",
	ZoneNames = {},
	TimeInterval = 300,
	CleanUpList = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @param table{string,...}|string ZoneNames which is a table of zone names where the debris should be cleaned. Also a single string can be passed with one zone name.
-- @param ?number TimeInterval is the interval in seconds when the clean activity takes place. The default is 300 seconds, thus every 5 minutes.
-- @return CLEANUP
-- @usage
-- -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { 'CLEAN Tbilisi', 'CLEAN Kutaisi' }, 150 )
-- or
-- CleanUpTbilisi = CLEANUP:New( 'CLEAN Tbilisi', 150 )
-- CleanUpKutaisi = CLEANUP:New( 'CLEAN Kutaisi', 600 )
function CLEANUP:New( ZoneNames, TimeInterval )	local self = BASE:Inherit( self, BASE:New() )
	self:F( { ZoneNames, TimeInterval } )
	
	if type( ZoneNames ) == 'table' then
		self.ZoneNames = ZoneNames
	else
		self.ZoneNames = { ZoneNames }
	end
	if TimeInterval then
		self.TimeInterval = TimeInterval
	end
	
	self:AddEvent( world.event.S_EVENT_ENGINE_SHUTDOWN, self._EventAddForCleanUp )
	self:AddEvent( world.event.S_EVENT_ENGINE_STARTUP, self._EventAddForCleanUp )
	self:AddEvent( world.event.S_EVENT_HIT, self._EventAddForCleanUp ) -- , self._EventHitCleanUp )
	self:AddEvent( world.event.S_EVENT_CRASH, self._EventCrash ) -- , self._EventHitCleanUp )
	--self:AddEvent( world.event.S_EVENT_DEAD, self._EventCrash )
	self:AddEvent( world.event.S_EVENT_SHOT, self._EventShot )
	
	self:EnableEvents()

	self.CleanUpFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, TimeInterval )
	
	return self
end


--- Destroys a group from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyGroup( GroupObject, CleanUpGroupName )
	self:F( { GroupObject, CleanUpGroupName } )

	if GroupObject then -- and GroupObject:isExist() then
		--MESSAGE:New( "Destroy Group " .. CleanUpGroupName, CleanUpGroupName, 1, CleanUpGroupName ):ToAll()
		trigger.action.deactivateGroup(GroupObject)
		self:T( { "GroupObject Destroyed", GroupObject } )
	end
end

--- Destroys a unit from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyUnit( CleanUpUnit, CleanUpUnitName )
	self:F( { CleanUpUnit, CleanUpUnitName } )

	if CleanUpUnit then
		--MESSAGE:New( "Destroy " .. CleanUpUnitName, CleanUpUnitName, 1, CleanUpUnitName ):ToAll()
		local CleanUpGroup = Unit.getGroup(CleanUpUnit)
    -- TODO Client bug in 1.5.3
		if CleanUpGroup and CleanUpGroup:isExist() then
			local CleanUpGroupUnits = CleanUpGroup:getUnits()
			if #CleanUpGroupUnits == 1 then
				local CleanUpGroupName = CleanUpGroup:getName()
				local Event = {["initiator"]=CleanUpUnit,["id"]=8}
				world.onEvent( Event )
				trigger.action.deactivateGroup( CleanUpGroup )
				self:T( { "Destroyed Group:", CleanUpGroupName } )
			else
				CleanUpUnit:destroy()
				self:T( { "Destroyed Unit:", CleanUpUnitName } )
			end
			self.CleanUpList[CleanUpUnitName] = nil -- Cleaning from the list
			CleanUpUnit = nil
		end
	end
end

--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyMissile( MissileObject )
	self:F( { MissileObject } )

	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		self:T( "MissileObject Destroyed")
	end
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see CLEANUP
function CLEANUP:_EventCrash( event )
	self:F( { event } )

	--MESSAGE:New( "Crash ", "Crash", 10, "Crash" ):ToAll()
	-- self:T("before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	-- self:T("after getGroup")
	-- _grp:destroy()
	-- self:T("after deactivateGroup")
	-- event.initiator:destroy()

	local CleanUpUnit = event.initiator -- the Unit
	local CleanUpUnitName = CleanUpUnit:getName() -- return the name of the Unit
	local CleanUpGroup = Unit.getGroup(CleanUpUnit)-- Identify the Group 
	local CleanUpGroupName = ""
	if CleanUpGroup and CleanUpGroup:isExist() then
    CleanUpGroupName = CleanUpGroup:getName() -- return the name of the Group
  end

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpGroup = CleanUpGroup
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = CleanUpGroupName
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName

	

end
--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see CLEANUP
function CLEANUP:_EventShot( event )
	self:F( { event } )

	local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	local _groupname = _grp:getName() -- return the name of the group
	local _unittable = {event.initiator:getName()} -- return the name of the units in the group
	local _SEADmissile = event.weapon -- Identify the weapon fired					
	--local _SEADmissileName = _SEADmissile:getTypeName()	-- return weapon type
	--trigger.action.outText( string.format("Alerte, depart missile " ..string.format(_SEADmissileName)), 20) --debug message
	-- Start of the 2nd loop
	--self:T( "Missile Launched = " .. _SEADmissileName )
	
	-- Test if the missile was fired within one of the CLEANUP.ZoneNames.
	local CurrentLandingZoneID = 0
	CurrentLandingZoneID  = routines.IsUnitInZones( event.initiator, self.ZoneNames )
	if  ( CurrentLandingZoneID ) then
		-- Okay, the missile was fired within the CLEANUP.ZoneNames, destroy the fired weapon.
		--_SEADmissile:destroy()
		routines.scheduleFunction( CLEANUP._DestroyMissile, {self, _SEADmissile}, timer.getTime() + 0.1)
	end
end


--- Detects if the Unit has an S_EVENT_HIT within the given ZoneNames. If this is the case, destroy the unit.
function CLEANUP:_EventHitCleanUp( event )
	self:F( { event } )

	local CleanUpUnit = event.initiator -- the Unit
	if CleanUpUnit and CleanUpUnit:isExist() and Object.getCategory(CleanUpUnit) == Object.Category.UNIT then
		local CleanUpUnitName = event.initiator:getName() -- return the name of the Unit
		
		if routines.IsUnitInZones( CleanUpUnit, self.ZoneNames ) ~= nil then
			self:T( "Life: " .. CleanUpUnitName .. ' = ' .. CleanUpUnit:getLife() .. "/" .. CleanUpUnit:getLife0() )
			if CleanUpUnit:getLife() < CleanUpUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. CleanUpUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, {self, CleanUpUnit}, timer.getTime() + 0.1)
			end
		end
	end

	local CleanUpTgtUnit = event.target -- the target Unit
	if CleanUpTgtUnit and CleanUpTgtUnit:isExist() and Object.getCategory(CleanUpTgtUnit) == Object.Category.UNIT then
		local CleanUpTgtUnitName = event.target:getName() -- return the name of the target Unit
		local CleanUpTgtGroup = Unit.getGroup(event.target)-- Identify the target Group 
		local CleanUpTgtGroupName = CleanUpTgtGroup:getName() -- return the name of the target Group
		
		
		if routines.IsUnitInZones( CleanUpTgtUnit, self.ZoneNames ) ~= nil then
			self:T( "Life: " .. CleanUpTgtUnitName .. ' = ' .. CleanUpTgtUnit:getLife() .. "/" .. CleanUpTgtUnit:getLife0() )
			if CleanUpTgtUnit:getLife() < CleanUpTgtUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. CleanUpTgtUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, {self, CleanUpTgtUnit}, timer.getTime() + 0.1)
			end
		end
	end
	
end

function CLEANUP:_AddForCleanUp( CleanUpUnit, CleanUpUnitName )
	self:F( { CleanUpUnit, CleanUpUnitName } )

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName
	self.CleanUpList[CleanUpUnitName].CleanUpGroup = Unit.getGroup(CleanUpUnit)
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = Unit.getGroup(CleanUpUnit):getName()
	self.CleanUpList[CleanUpUnitName].CleanUpTime = timer.getTime()
	self.CleanUpList[CleanUpUnitName].CleanUpMoved = false

	self:T( { "CleanUp: Add to CleanUpList: ", Unit.getGroup(CleanUpUnit):getName(), CleanUpUnitName } )
	
end

--- Detects if the Unit has an S_EVENT_ENGINE_SHUTDOWN or an S_EVENT_HIT within the given ZoneNames. If this is the case, add the Group to the CLEANUP List.
function CLEANUP:_EventAddForCleanUp( event )

	local CleanUpUnit = event.initiator -- the Unit
	if CleanUpUnit and Object.getCategory(CleanUpUnit) == Object.Category.UNIT then
		local CleanUpUnitName = CleanUpUnit:getName() -- return the name of the Unit
		if self.CleanUpList[CleanUpUnitName] == nil then
			if routines.IsUnitInZones( CleanUpUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( CleanUpUnit, CleanUpUnitName )
			end
		end
	end

	local CleanUpTgtUnit = event.target -- the target Unit
	if CleanUpTgtUnit and Object.getCategory(CleanUpTgtUnit) == Object.Category.UNIT then
		local CleanUpTgtUnitName = CleanUpTgtUnit:getName() -- return the name of the target Unit
		if self.CleanUpList[CleanUpTgtUnitName] == nil then
			if routines.IsUnitInZones( CleanUpTgtUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( CleanUpTgtUnit, CleanUpTgtUnitName )
			end
		end
	end
	
end

CleanUpSurfaceTypeText = {
   "LAND",
   "SHALLOW_WATER",
   "WATER",
   "ROAD",
   "RUNWAY"
 }

--- At the defined time interval, CleanUp the Groups within the CleanUpList.
function CLEANUP:_Scheduler()
	self:F( "CleanUp Scheduler" )

	for CleanUpUnitName, UnitData in pairs( self.CleanUpList ) do
	
		self:T( { CleanUpUnitName, UnitData } )
		local CleanUpUnit = Unit.getByName(UnitData.CleanUpUnitName)
		local CleanUpGroupName = UnitData.CleanUpGroupName
		local CleanUpUnitName = UnitData.CleanUpUnitName
		if CleanUpUnit then
			self:T( { "CleanUp Scheduler", "Checking:", CleanUpUnitName } )
			if _Database:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then
				local CleanUpUnitVec3 = CleanUpUnit:getPoint()
				--self:T( CleanUpUnitVec3 )
				local CleanUpUnitVec2 = {}
				CleanUpUnitVec2.x = CleanUpUnitVec3.x
				CleanUpUnitVec2.y = CleanUpUnitVec3.z
				--self:T( CleanUpUnitVec2 )
				local CleanUpSurfaceType = land.getSurfaceType(CleanUpUnitVec2)
				--self:T( CleanUpSurfaceType )
				--MESSAGE:New( "Surface " .. CleanUpUnitName .. " = " .. CleanUpSurfaceTypeText[CleanUpSurfaceType], CleanUpUnitName, 10, CleanUpUnitName ):ToAll()
				
				if CleanUpUnit and CleanUpUnit:getLife() <= CleanUpUnit:getLife0() * 0.95 then
					if CleanUpSurfaceType == land.SurfaceType.RUNWAY then
						if CleanUpUnit:inAir() then
							local CleanUpLandHeight = land.getHeight(CleanUpUnitVec2)
							local CleanUpUnitHeight = CleanUpUnitVec3.y - CleanUpLandHeight
							self:T( { "CleanUp Scheduler", "Height = " .. CleanUpUnitHeight } )
							if CleanUpUnitHeight < 30 then
								self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because below safe height and damaged." } )
								self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
							end
						else
							self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because on runway and damaged." } )
							self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
						end
					end
				end
				-- Clean Units which are waiting for a very long time in the CleanUpZone.
				if CleanUpUnit then
					local CleanUpUnitVelocity = CleanUpUnit:getVelocity()
					local CleanUpUnitVelocityTotal = math.abs(CleanUpUnitVelocity.x) + math.abs(CleanUpUnitVelocity.y) + math.abs(CleanUpUnitVelocity.z)
					if CleanUpUnitVelocityTotal < 1 then
						if UnitData.CleanUpMoved then
							if UnitData.CleanUpTime + 180 <= timer.getTime() then
								self:T( { "CleanUp Scheduler", "Destroy due to not moving anymore " .. CleanUpUnitName } )
								self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
							end
						end
					else
						UnitData.CleanUpTime = timer.getTime()
						UnitData.CleanUpMoved = true
						--MESSAGE:New( "Moved " .. CleanUpUnitName, CleanUpUnitName, 10, CleanUpUnitName ):ToAll()
					end
				end
				
			else
				-- Do nothing ...
				self.CleanUpList[CleanUpUnitName] = nil -- Not anymore in the DCSRTE
			end
		else
			self:T( "CleanUp: Group " .. CleanUpUnitName .. " cannot be found in DCS RTE, removing ..." )
			self.CleanUpList[CleanUpUnitName] = nil -- Not anymore in the DCSRTE
		end
	end
end

