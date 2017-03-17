--- The CLEANUP class keeps an area clean of crashing or colliding airplanes. It also prevents airplanes from firing within this area.
-- @module CleanUp
-- @author Flightcontrol







--- The CLEANUP class.
-- @type CLEANUP
-- @extends Core.Base#BASE
CLEANUP = {
	ClassName = "CLEANUP",
	ZoneNames = {},
	TimeInterval = 300,
	CleanUpList = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @param #CLEANUP self
-- @param #table ZoneNames Is a table of zone names where the debris should be cleaned. Also a single string can be passed with one zone name.
-- @param #number TimeInterval The interval in seconds when the clean activity takes place. The default is 300 seconds, thus every 5 minutes.
-- @return #CLEANUP
-- @usage
--  -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { 'CLEAN Tbilisi', 'CLEAN Kutaisi' }, 150 )
-- or
-- CleanUpTbilisi = CLEANUP:New( 'CLEAN Tbilisi', 150 )
-- CleanUpKutaisi = CLEANUP:New( 'CLEAN Kutaisi', 600 )
function CLEANUP:New( ZoneNames, TimeInterval )	

  local self = BASE:Inherit( self, BASE:New() ) -- #CLEANUP
	self:F( { ZoneNames, TimeInterval } )
	
	if type( ZoneNames ) == 'table' then
		self.ZoneNames = ZoneNames
	else
		self.ZoneNames = { ZoneNames }
	end
	if TimeInterval then
		self.TimeInterval = TimeInterval
	end
	
	self:HandleEvent( EVENTS.Birth )
	
  self.CleanUpScheduler = SCHEDULER:New( self, self._CleanUpScheduler, {}, 1, TimeInterval )
	
	return self
end


--- Destroys a group from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param Dcs.DCSWrapper.Group#Group GroupObject The object to be destroyed.
-- @param #string CleanUpGroupName The groupname...
function CLEANUP:_DestroyGroup( GroupObject, CleanUpGroupName )
	self:F( { GroupObject, CleanUpGroupName } )

	if GroupObject then -- and GroupObject:isExist() then
		trigger.action.deactivateGroup(GroupObject)
		self:T( { "GroupObject Destroyed", GroupObject } )
	end
end

--- Destroys a @{DCSWrapper.Unit#Unit} from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param Dcs.DCSWrapper.Unit#Unit CleanUpUnit The object to be destroyed.
-- @param #string CleanUpUnitName The Unit name ...
function CLEANUP:_DestroyUnit( CleanUpUnit, CleanUpUnitName )
	self:F( { CleanUpUnit, CleanUpUnitName } )

	if CleanUpUnit then
		local CleanUpGroup = Unit.getGroup(CleanUpUnit)
    -- TODO Client bug in 1.5.3
		if CleanUpGroup and CleanUpGroup:isExist() then
			local CleanUpGroupUnits = CleanUpGroup:getUnits()
			if #CleanUpGroupUnits == 1 then
				local CleanUpGroupName = CleanUpGroup:getName()
				--self:CreateEventCrash( timer.getTime(), CleanUpUnit )
				CleanUpGroup:destroy()
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

-- TODO check Dcs.DCSTypes#Weapon
--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Weapon MissileObject
function CLEANUP:_DestroyMissile( MissileObject )
	self:F( { MissileObject } )

	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		self:T( "MissileObject Destroyed")
	end
end

--- @param #CLEANUP self
-- @param Core.Event#EVENTDATA EventData
function CLEANUP:_OnEventBirth( EventData )
  self:F( { EventData } )
  
  self.CleanUpList[EventData.IniDCSUnitName] = {}
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnit = EventData.IniDCSUnit
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroup = EventData.IniDCSGroup
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroupName = EventData.IniDCSGroupName
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnitName = EventData.IniDCSUnitName

  EventData.IniUnit:HandleEvent( EVENTS.EngineShutdown , self._EventAddForCleanUp )
  EventData.IniUnit:HandleEvent( EVENTS.EngineStartup, self._EventAddForCleanUp )
  EventData.IniUnit:HandleEvent( EVENTS.Hit, self._EventAddForCleanUp )
  EventData.IniUnit:HandleEvent( EVENTS.PilotDead, self._EventCrash )
  EventData.IniUnit:HandleEvent( EVENTS.Dead, self._EventCrash )
  EventData.IniUnit:HandleEvent( EVENTS.Crash, self._EventCrash )
  EventData.IniUnit:HandleEvent( EVENTS.Shot, self._EventShot )

end

--- Detects if a crash event occurs.
-- Crashed units go into a CleanUpList for removal.
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Event event
function CLEANUP:_EventCrash( Event )
	self:F( { Event } )

  --TODO: This stuff is not working due to a DCS bug. Burning units cannot be destroyed.
	-- self:T("before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	-- self:T("after getGroup")
	-- _grp:destroy()
	-- self:T("after deactivateGroup")
	-- event.initiator:destroy()

  self.CleanUpList[Event.IniDCSUnitName] = {}
  self.CleanUpList[Event.IniDCSUnitName].CleanUpUnit = Event.IniDCSUnit
  self.CleanUpList[Event.IniDCSUnitName].CleanUpGroup = Event.IniDCSGroup
  self.CleanUpList[Event.IniDCSUnitName].CleanUpGroupName = Event.IniDCSGroupName
  self.CleanUpList[Event.IniDCSUnitName].CleanUpUnitName = Event.IniDCSUnitName
  
end

--- Detects if a unit shoots a missile.
-- If this occurs within one of the zones, then the weapon used must be destroyed.
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Event event
function CLEANUP:_EventShot( Event )
	self:F( { Event } )

	-- Test if the missile was fired within one of the CLEANUP.ZoneNames.
	local CurrentLandingZoneID = 0
	CurrentLandingZoneID  = routines.IsUnitInZones( Event.IniDCSUnit, self.ZoneNames )
	if  ( CurrentLandingZoneID ) then
		-- Okay, the missile was fired within the CLEANUP.ZoneNames, destroy the fired weapon.
		--_SEADmissile:destroy()
    SCHEDULER:New( self, CLEANUP._DestroyMissile, { Event.Weapon }, 0.1 )
	end
end


--- Detects if the Unit has an S_EVENT_HIT within the given ZoneNames. If this is the case, destroy the unit.
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Event event
function CLEANUP:_EventHitCleanUp( Event )
	self:F( { Event } )

	if Event.IniDCSUnit then
		if routines.IsUnitInZones( Event.IniDCSUnit, self.ZoneNames ) ~= nil then
			self:T( { "Life: ", Event.IniDCSUnitName, ' = ',  Event.IniDCSUnit:getLife(), "/", Event.IniDCSUnit:getLife0() } )
			if Event.IniDCSUnit:getLife() < Event.IniDCSUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. Event.IniDCSUnitName )
        SCHEDULER:New( self, CLEANUP._DestroyUnit, { Event.IniDCSUnit }, 0.1 )
			end
		end
	end

	if Event.TgtDCSUnit then
		if routines.IsUnitInZones( Event.TgtDCSUnit, self.ZoneNames ) ~= nil then
			self:T( { "Life: ", Event.TgtDCSUnitName, ' = ', Event.TgtDCSUnit:getLife(), "/", Event.TgtDCSUnit:getLife0() } )
			if Event.TgtDCSUnit:getLife() < Event.TgtDCSUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. Event.TgtDCSUnitName )
        SCHEDULER:New( self, CLEANUP._DestroyUnit, { Event.TgtDCSUnit }, 0.1 )
			end
		end
	end
end

--- Add the @{DCSWrapper.Unit#Unit} to the CleanUpList for CleanUp.
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
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Event event
function CLEANUP:_EventAddForCleanUp( Event )

	if Event.IniDCSUnit then
		if self.CleanUpList[Event.IniDCSUnitName] == nil then
			if routines.IsUnitInZones( Event.IniDCSUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( Event.IniDCSUnit, Event.IniDCSUnitName )
			end
		end
	end

	if Event.TgtDCSUnit then
		if self.CleanUpList[Event.TgtDCSUnitName] == nil then
			if routines.IsUnitInZones( Event.TgtDCSUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( Event.TgtDCSUnit, Event.TgtDCSUnitName )
			end
		end
	end
	
end

local CleanUpSurfaceTypeText = {
   "LAND",
   "SHALLOW_WATER",
   "WATER",
   "ROAD",
   "RUNWAY"
 }

--- At the defined time interval, CleanUp the Groups within the CleanUpList.
-- @param #CLEANUP self
function CLEANUP:_CleanUpScheduler()
	self:F( { "CleanUp Scheduler" } )

  local CleanUpCount = 0
	for CleanUpUnitName, UnitData in pairs( self.CleanUpList ) do
	  CleanUpCount = CleanUpCount + 1
	
		self:T( { CleanUpUnitName, UnitData } )
		local CleanUpUnit = Unit.getByName(UnitData.CleanUpUnitName)
		local CleanUpGroupName = UnitData.CleanUpGroupName
		local CleanUpUnitName = UnitData.CleanUpUnitName
		if CleanUpUnit then
			self:T( { "CleanUp Scheduler", "Checking:", CleanUpUnitName } )
			if _DATABASE:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then
				local CleanUpUnitVec3 = CleanUpUnit:getPoint()
				--self:T( CleanUpUnitVec3 )
				local CleanUpUnitVec2 = {}
				CleanUpUnitVec2.x = CleanUpUnitVec3.x
				CleanUpUnitVec2.y = CleanUpUnitVec3.z
				--self:T( CleanUpUnitVec2 )
				local CleanUpSurfaceType = land.getSurfaceType(CleanUpUnitVec2)
				--self:T( CleanUpSurfaceType )
				
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
	self:T(CleanUpCount)
	
	return true
end

