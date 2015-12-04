--- CLEANUP Classes
-- @classmod CLEANUP
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

CLEANUP = {
	ClassName = "CLEANUP",
	ZoneNames = {},
	TimeInterval = 300,
	CleanUpList = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @tparam table{string,...}|string ZoneNames which is a table of zone names where the debris should be cleaned. Also a single string can be passed with one zone name.
-- @tparam ?number TimeInterval is the interval in seconds when the clean activity takes place. The default is 300 seconds, thus every 5 minutes.
-- @treturn CLEANUP
-- @usage
-- -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { 'CLEAN Tbilisi', 'CLEAN Kutaisi' }, 150 )
-- or
-- CleanUpTbilisi = CLEANUP:New( 'CLEAN Tbilisi', 150 )
-- CleanUpKutaisi = CLEANUP:New( 'CLEAN Kutaisi', 600 )
function CLEANUP:New( ZoneNames, TimeInterval )
trace.f( self.ClassName, { ZoneNames, TimeInterval } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, BASE:New() )
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
trace.f( self.ClassName )

	if GroupObject then -- and GroupObject:isExist() then
		MESSAGE:New( "Destroy Group " .. CleanUpGroupName, CleanUpGroupName, 1, CleanUpGroupName ):ToAll()
		trigger.action.deactivateGroup(GroupObject)
		trace.i(self.ClassName, "GroupObject Destroyed")
	end
end

--- Destroys a unit from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyUnit( CleanUpUnit, CleanUpUnitName )
trace.f( self.ClassName )

	if CleanUpUnit then
		MESSAGE:New( "Destroy " .. CleanUpUnitName, CleanUpUnitName, 1, CleanUpUnitName ):ToAll()
		local CleanUpGroup = Unit.getGroup(CleanUpUnit)
		if CleanUpGroup then
			local CleanUpGroupUnits = CleanUpGroup:getUnits()
			if #CleanUpGroupUnits == 1 then
				local CleanUpGroupName = CleanUpGroup:getName()
				local Event = {["initiator"]=CleanUpUnit,["id"]=8}
				world.onEvent(Event)
				trigger.action.deactivateGroup(CleanUpGroup)
				trace.i(self.ClassName, "Destroyed Group " .. CleanUpGroupName )
			else
				CleanUpUnit:destroy()
				trace.i(self.ClassName, "Destroyed Unit " .. CleanUpUnitName )
			end
			self.CleanUpList[CleanUpUnitName] = nil -- Cleaning from the list
			CleanUpUnit = nil
		end
	end
end

--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyMissile( MissileObject )
trace.f( self.ClassName )

	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		trace.i(self.ClassName, "MissileObject Destroyed")
	end
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see CLEANUP
function CLEANUP:_EventCrash( event )
trace.f( self.ClassName )

	--MESSAGE:New( "Crash ", "Crash", 10, "Crash" ):ToAll()
	-- trace.i(self.ClassName,"before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	-- trace.i(self.ClassName,"after getGroup")
	-- _grp:destroy()
	-- trace.i(self.ClassName,"after deactivateGroup")
	-- event.initiator:destroy()

	local CleanUpUnit = event.initiator -- the Unit
	local CleanUpUnitName = CleanUpUnit:getName() -- return the name of the Unit
	local CleanUpGroup = Unit.getGroup(CleanUpUnit)-- Identify the Group 
	local CleanUpGroupName = CleanUpGroup:getName() -- return the name of the Group

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpGroup = CleanUpGroup
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = CleanUpGroupName
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName

	

end
--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see CLEANUP
function CLEANUP:_EventShot( event )
trace.f( self.ClassName )

	local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	local _groupname = _grp:getName() -- return the name of the group
	local _unittable = {event.initiator:getName()} -- return the name of the units in the group
	local _SEADmissile = event.weapon -- Identify the weapon fired					
	--local _SEADmissileName = _SEADmissile:getTypeName()	-- return weapon type
	--trigger.action.outText( string.format("Alerte, depart missile " ..string.format(_SEADmissileName)), 20) --debug message
	-- Start of the 2nd loop
	--trace.i( self.ClassName, "Missile Launched = " .. _SEADmissileName )
	
	-- Test if the missile was fired within one of the CLEANUP.ZoneNames.
	local CurrentLandingZoneID = 0
	CurrentLandingZoneID  = routines.IsUnitInZones( event.initiator, self.ZoneNames )
	if  ( CurrentLandingZoneID ) then
		-- Okay, the missile was fired within the CLEANUP.ZoneNames, destroy the fired weapon.
		--_SEADmissile:destroy()
		routines.scheduleFunction( CLEANUP._DestroyMissile, {self, _SEADmissile}, timer.getTime() + 0.1)
	end

--[[
	if _SEADmissileName == "KH-58" or _SEADmissileName == "KH-25MPU" or _SEADmissileName == "AGM-88" or _SEADmissileName == "KH-31A" or _SEADmissileName == "KH-31P" then -- Check if the missile is a SEAD
		local _evade = math.random (1,100) -- random number for chance of evading action
		local _targetMim = Weapon.getTarget(_SEADmissile) -- Identify target
		local _targetMimname = Unit.getName(_targetMim)
		local _targetMimgroup = Unit.getGroup(Weapon.getTarget(_SEADmissile))
		local _targetMimgroupName = _targetMimgroup:getName()
		local _targetMimcont= _targetMimgroup:getController()
		local _targetskill =  _Database.Units[_targetMimname].Template.skill
		trace.i( self.ClassName, self.SEADGroupPrefixes )
		trace.i( self.ClassName, _targetMimgroupName )
		local SEADGroupFound = false
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( self.SEADGroupPrefixes ) do
			if string.find( _targetMimgroupName, SEADGroupPrefix, 1, true ) then
				SEADGroupFound = true
				trace.i( self.ClassName, 'Group Found' )
				break
			end
		end		
		if SEADGroupFound == true then
			if _targetskill == "Random" then -- when skill is random, choose a skill
				local Skills = { "Average", "Good", "High", "Excellent" }
				_targetskill = Skills[ math.random(1,4) ]
			end
			trace.i( self.ClassName, _targetskill ) -- debug message for skill check
			if self.TargetSkill[_targetskill] then
				if (_evade > self.TargetSkill[_targetskill].Evade) then
					trace.i( self.ClassName, string.format("Evading, target skill  " ..string.format(_targetskill)) ) --debug message
					local _targetMim = Weapon.getTarget(_SEADmissile)
					local _targetMimname = Unit.getName(_targetMim)
					local _targetMimgroup = Unit.getGroup(Weapon.getTarget(_SEADmissile))
					local _targetMimcont= _targetMimgroup:getController()
					routines.groupRandomDistSelf(_targetMimgroup,300,'Rank',250,20) -- move randomly
					local SuppressedGroups1 = {} -- unit suppressed radar off for a random time
					local function SuppressionEnd1(id)
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						SuppressedGroups1[id.groupName] = nil
					end
					local id = {
					groupName = _targetMimgroup,
					ctrl = _targetMimcont
					}
					local delay1 = math.random(self.TargetSkill[_targetskill].DelayOff[1], self.TargetSkill[_targetskill].DelayOff[2])
					if SuppressedGroups1[id.groupName] == nil then
						SuppressedGroups1[id.groupName] = {
							SuppressionEndTime1 = timer.getTime() + delay1,
							SuppressionEndN1 = SuppressionEndCounter1	--Store instance of SuppressionEnd() scheduled function
						}	
						Controller.setOption(_targetMimcont, AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						timer.scheduleFunction(SuppressionEnd1, id, SuppressedGroups1[id.groupName].SuppressionEndTime1)	--Schedule the SuppressionEnd() function
						--trigger.action.outText( string.format("Radar Off " ..string.format(delay1)), 20)
					end
					
					local SuppressedGroups = {}
					local function SuppressionEnd(id)
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.RED)
						SuppressedGroups[id.groupName] = nil
					end
					local id = {
						groupName = _targetMimgroup,
						ctrl = _targetMimcont
					}
					local delay = math.random(self.TargetSkill[_targetskill].DelayOn[1], self.TargetSkill[_targetskill].DelayOn[2])
					if SuppressedGroups[id.groupName] == nil then
						SuppressedGroups[id.groupName] = {
							SuppressionEndTime = timer.getTime() + delay,
							SuppressionEndN = SuppressionEndCounter	--Store instance of SuppressionEnd() scheduled function
						}
						timer.scheduleFunction(SuppressionEnd, id, SuppressedGroups[id.groupName].SuppressionEndTime)	--Schedule the SuppressionEnd() function
						--trigger.action.outText( string.format("Radar On " ..string.format(delay)), 20)
					end
				end
			end
		end
	end
	--]]
end


--- Detects if the Unit has an S_EVENT_HIT within the given ZoneNames. If this is the case, destroy the unit.
function CLEANUP:_EventHitCleanUp( event )
trace.f( self.ClassName )

	local CleanUpUnit = event.initiator -- the Unit
	if CleanUpUnit and CleanUpUnit:isExist() and Object.getCategory(CleanUpUnit) == Object.Category.UNIT then
		local CleanUpUnitName = event.initiator:getName() -- return the name of the Unit
		local CleanUpGroup = Unit.getGroup(event.initiator)-- Identify the Group 
		local CleanUpGroupName = CleanUpGroup:getName() -- return the name of the Group
		
		if routines.IsUnitInZones( CleanUpUnit, self.ZoneNames ) ~= nil then
			trace.i( self.ClassName, "Life: " .. CleanUpUnitName .. ' = ' .. CleanUpUnit:getLife() .. "/" .. CleanUpUnit:getLife0() )
			if CleanUpUnit:getLife() < CleanUpUnit:getLife0() then
				trace.i( self.ClassName, "CleanUp: Destroy: " .. CleanUpUnitName )
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
			trace.i( self.ClassName, "Life: " .. CleanUpTgtUnitName .. ' = ' .. CleanUpTgtUnit:getLife() .. "/" .. CleanUpTgtUnit:getLife0() )
			if CleanUpTgtUnit:getLife() < CleanUpTgtUnit:getLife0() then
				trace.i( self.ClassName, "CleanUp: Destroy: " .. CleanUpTgtUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, {self, CleanUpTgtUnit}, timer.getTime() + 0.1)
			end
		end
	end
	
end

function CLEANUP:_AddForCleanUp( CleanUpUnit, CleanUpUnitName )

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName
	self.CleanUpList[CleanUpUnitName].CleanUpGroup = Unit.getGroup(CleanUpUnit)
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = Unit.getGroup(CleanUpUnit):getName()
	self.CleanUpList[CleanUpUnitName].CleanUpTime = timer.getTime()
	self.CleanUpList[CleanUpUnitName].CleanUpMoved = false

	trace.i( self.ClassName, "CleanUp: Add to CleanUpList: " .. Unit.getGroup(CleanUpUnit):getName() .. " / " .. CleanUpUnitName )
	
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

	for CleanUpUnitName, UnitData in pairs( self.CleanUpList ) do
	
		trace.i( self.ClassName, { CleanUpUnitName, UnitData } )
		local CleanUpGroup = Group.getByName(UnitData.CleanUpGroupName)
		local CleanUpUnit = Unit.getByName(UnitData.CleanUpUnitName)
		local CleanUpGroupName = UnitData.CleanUpGroupName
		local CleanUpUnitName = UnitData.CleanUpUnitName
		if CleanUpUnit then
			trace.i( self.ClassName, "Checking " .. CleanUpUnitName )
			if _Database:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then
				local CleanUpUnitVec3 = CleanUpUnit:getPoint()
				--trace.i( self.ClassName, CleanUpUnitVec3 )
				local CleanUpUnitVec2 = {}
				CleanUpUnitVec2.x = CleanUpUnitVec3.x
				CleanUpUnitVec2.y = CleanUpUnitVec3.z
				--trace.i( self.ClassName, CleanUpUnitVec2 )
				local CleanUpSurfaceType = land.getSurfaceType(CleanUpUnitVec2)
				--trace.i( self.ClassName, CleanUpSurfaceType )
				--MESSAGE:New( "Surface " .. CleanUpUnitName .. " = " .. CleanUpSurfaceTypeText[CleanUpSurfaceType], CleanUpUnitName, 10, CleanUpUnitName ):ToAll()
				
				if CleanUpUnit and CleanUpUnit:getLife() <= CleanUpUnit:getLife0() * 0.95 then
					if CleanUpSurfaceType == land.SurfaceType.RUNWAY then
						if CleanUpUnit:inAir() then
							local CleanUpLandHeight = land.getHeight(CleanUpUnitVec2)
							local CleanUpUnitHeight = CleanUpUnitVec3.y - CleanUpLandHeight
							trace.i( self.ClassName, "Height = " .. CleanUpUnitHeight )
							if CleanUpUnitHeight < 30 then
								trace.i( self.ClassName, "Destroy " .. CleanUpUnitName .. " because below safe height and damaged." )
								self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
							end
						else
							trace.i( self.ClassName, "Destroy " .. CleanUpUnitName .. " because on runway and damaged." )
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
								trace.i( self.ClassName, "Destroy due to not moving anymore " .. CleanUpUnitName )
								self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
							end
						end
					else
						UnitData.CleanUpTime = timer.getTime()
						UnitData.CleanUpMoved = true
						MESSAGE:New( "Moved " .. CleanUpUnitName, CleanUpUnitName, 10, CleanUpUnitName ):ToAll()
					end
				end
				
			else
				-- Do nothing ...
				self.CleanUpList[CleanUpUnitName] = nil -- Not anymore in the DCSRTE
			end
		else
			trace.i( self.ClassName, "CleanUp: Group " .. CleanUpUnitName .. " cannot be found in DCS RTE, removing ..." )
			self.CleanUpList[CleanUpUnitName] = nil -- Not anymore in the DCSRTE
		end
	end
end

