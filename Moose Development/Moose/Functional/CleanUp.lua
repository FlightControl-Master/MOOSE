--- **Functional** -- The CLEANUP class keeps an area clean of crashing or colliding airplanes. It also prevents airplanes from firing within this area.
-- 
-- ![Banner Image](..\Presentations\CLEANUP\Dia1.JPG)
-- 
-- ===
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
-- 
-- @module CleanUp


--- @type CLEANUP
-- @extends Core.Base#BASE
-- @field #map<#string,Wrapper.Airbase#AIRBASE> Airbases Map of Airbases.

--- # CLEANUP, extends @{Base#BASE}
-- 
-- The CLEANUP class keeps airbases clean, and tries to guarantee continuous airbase operations, even under combat.
-- 
-- @field #CLEANUP
CLEANUP = {
	ClassName = "CLEANUP",
	TimeInterval = 0.2,
	CleanUpList = {},
	Airbases = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @param #CLEANUP self
-- @param #list<#string> AirbaseNames Is a table of airbase names where the debris should be cleaned. Also a single string can be passed with one airbase name.
-- @return #CLEANUP
-- @usage
--  -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { AIRBASE.Caucasus.Tbilisi, AIRBASE.Caucasus.Kutaisi )
-- or
-- CleanUpTbilisi = CLEANUP:New( AIRBASE.Caucasus.Tbilisi )
-- CleanUpKutaisi = CLEANUP:New( AIRBASE.Caucasus.Kutaisi )
function CLEANUP:New( AirbaseNames )	

  local self = BASE:Inherit( self, BASE:New() ) -- #CLEANUP
	self:F( { AirbaseNames } )
	
	if type( AirbaseNames ) == 'table' then
    for AirbaseID, AirbaseName in pairs( AirbaseNames ) do
      self:AddAirbase( AirbaseName )
    end
	else
    local AirbaseName = AirbaseNames
    self:AddAirbase( AirbaseName )
	end
	
	self:HandleEvent( EVENTS.Birth )
	
  self.CleanUpScheduler = SCHEDULER:New( self, self._CleanUpScheduler, {}, 1, self.TimeInterval )
	
	return self
end

--- Adds an airbase to the airbase validation list.
-- @param #CLEANUP self
-- @param #string AirbaseName
-- @return #CLEANUP
function CLEANUP:AddAirbase( AirbaseName )
  self.Airbases[AirbaseName] = AIRBASE:FindByName( AirbaseName )
  self:F({"Airbase:", AirbaseName, self.Airbases[AirbaseName]:GetDesc()})
  
  return self
end

--- Removes an airbase from the airbase validation list.
-- @param #CLEANUP self
-- @param #string AirbaseName
-- @return #CLEANUP
function CLEANUP:RemoveAirbase( AirbaseName )
  self.Airbases[AirbaseName] = nil
  return self
end



function CLEANUP:IsInAirbase( Vec2 )

  local InAirbase = false
  for AirbaseName, Airbase in pairs( self.Airbases ) do
    local Airbase = Airbase -- Wrapper.Airbase#AIRBASE
    if Airbase:GetZone():IsVec2InZone( Vec2 ) then
      InAirbase = true
      break;
    end
  end
  
  return InAirbase
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

--- Destroys a @{Unit} from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param Wrapper.Unit#UNIT CleanUpUnit The object to be destroyed.
function CLEANUP:_DestroyUnit( CleanUpUnit )
	self:F( { CleanUpUnit } )

	if CleanUpUnit then
	  local CleanUpUnitName = CleanUpUnit:GetName()
		local CleanUpGroup = CleanUpUnit:GetGroup()
    -- TODO Client bug in 1.5.3
		if CleanUpGroup:IsAlive() then
			local CleanUpGroupUnits = CleanUpGroup:GetUnits()
			if #CleanUpGroupUnits == 1 then
				local CleanUpGroupName = CleanUpGroup:GetName()
				CleanUpGroup:Destroy()
			else
				CleanUpUnit:Destroy()
			end
			self.CleanUpList[CleanUpUnitName] = nil
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
function CLEANUP:OnEventBirth( EventData )
  self:F( { EventData } )
  
  self.CleanUpList[EventData.IniDCSUnitName] = {}
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnit = EventData.IniDCSUnit
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroup = EventData.IniDCSGroup
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroupName = EventData.IniDCSGroupName
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnitName = EventData.IniDCSUnitName

  self:HandleEvent( EVENTS.EngineShutdown , self._EventAddForCleanUp )
  self:HandleEvent( EVENTS.EngineStartup, self._EventAddForCleanUp )
  self:HandleEvent( EVENTS.Hit, self._EventAddForCleanUp )
  self:HandleEvent( EVENTS.PilotDead, self.OnEventCrash )
  self:HandleEvent( EVENTS.Dead, self.OnEventCrash )
  self:HandleEvent( EVENTS.Crash, self.OnEventCrash )
  self:HandleEvent( EVENTS.Shot, self.OnEventShot )

end

--- Detects if a crash event occurs.
-- Crashed units go into a CleanUpList for removal.
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Event event
function CLEANUP:OnEventCrash( Event )
	self:F( { Event } )

  --TODO: This stuff is not working due to a DCS bug. Burning units cannot be destroyed.
	-- self:T("before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	-- self:T("after getGroup")
	-- _grp:destroy()
	-- self:T("after deactivateGroup")
	-- event.initiator:destroy()

  if Event.IniDCSUnitName then
    self.CleanUpList[Event.IniDCSUnitName] = {}
    self.CleanUpList[Event.IniDCSUnitName].CleanUpUnit = Event.IniDCSUnit
    self.CleanUpList[Event.IniDCSUnitName].CleanUpGroup = Event.IniDCSGroup
    self.CleanUpList[Event.IniDCSUnitName].CleanUpGroupName = Event.IniDCSGroupName
    self.CleanUpList[Event.IniDCSUnitName].CleanUpUnitName = Event.IniDCSUnitName
  end
  
end

--- Detects if a unit shoots a missile.
-- If this occurs within one of the airbases, then the weapon used must be destroyed.
-- @param #CLEANUP self
-- @param Core.Event#EVENTDATA Event
function CLEANUP:OnEventShot( Event )
	self:F( { Event } )

	-- Test if the missile was fired within one of the CLEANUP.AirbaseNames.
	if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
		-- Okay, the missile was fired within the CLEANUP.AirbaseNames, destroy the fired weapon.
    self:_DestroyMissile( Event.Weapon )
	end
end


--- Detects if the Unit has an S_EVENT_HIT within the given AirbaseNames. If this is the case, destroy the unit.
-- @param #CLEANUP self
-- @param Core.Event#EVENTDATA Event
function CLEANUP:OnEventHit( Event )
	self:F( { Event } )

	if Event.IniUnit then
		if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
			self:T( { "Life: ", Event.IniDCSUnitName, ' = ',  Event.IniDCSUnit:getLife(), "/", Event.IniDCSUnit:getLife0() } )
			if Event.IniDCSUnit:getLife() < Event.IniDCSUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. Event.IniDCSUnitName )
        CLEANUP:_DestroyUnit( Event.IniUnit )
			end
		end
	end

	if Event.TgtUnit then
		if self:IsInAirbase( Event.TgtUnit:GetVec2() ) then
			self:T( { "Life: ", Event.TgtDCSUnitName, ' = ', Event.TgtDCSUnit:getLife(), "/", Event.TgtDCSUnit:getLife0() } )
			if Event.TgtDCSUnit:getLife() < Event.TgtDCSUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. Event.TgtDCSUnitName )
        CLEANUP:_DestroyUnit( Event.TgtUnit )
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

--- Detects if the Unit has an S_EVENT_ENGINE_SHUTDOWN or an S_EVENT_HIT within the given AirbaseNames. If this is the case, add the Group to the CLEANUP List.
-- @param #CLEANUP self
-- @param Core.Event#EVENTDATA Event
function CLEANUP:_EventAddForCleanUp( Event )

  self:F({Event})

	if Event.IniDCSUnit then
		if self.CleanUpList[Event.IniDCSUnitName] == nil then
			if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
				self:_AddForCleanUp( Event.IniDCSUnit, Event.IniDCSUnitName )
			end
		end
	end

	if Event.TgtDCSUnit then
		if self.CleanUpList[Event.TgtDCSUnitName] == nil then
			if self:IsInAirbase( Event.TgtUnit:GetVec2() ) then
				self:_AddForCleanUp( Event.TgtDCSUnit, Event.TgtDCSUnitName )
			end
		end
	end
	
end


--- At the defined time interval, CleanUp the Groups within the CleanUpList.
-- @param #CLEANUP self
function CLEANUP:_CleanUpScheduler()

  local CleanUpCount = 0
	for CleanUpUnitName, UnitData in pairs( self.CleanUpList ) do
	  CleanUpCount = CleanUpCount + 1
	
		local CleanUpUnit = UNIT:FindByName( CleanUpUnitName )
		local CleanUpDCSUnit = Unit.getByName( CleanUpUnitName )
		local CleanUpGroupName = UnitData.CleanUpGroupName

		if CleanUpUnit then

			if _DATABASE:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then

				local CleanUpCoordinate = CleanUpUnit:GetCoordinate()

				if CleanUpDCSUnit and CleanUpDCSUnit:getLife() <= CleanUpDCSUnit:getLife0() * 0.95 then
					if CleanUpUnit:IsAboveRunway() then
						if CleanUpUnit:InAir() then

							local CleanUpLandHeight = CleanUpCoordinate:GetLandHeight()
							local CleanUpUnitHeight = CleanUpCoordinate.y - CleanUpLandHeight
							
							if CleanUpUnitHeight < 30 then
								self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because below safe height and damaged." } )
								self:_DestroyUnit( CleanUpUnit )
							end
						else
							self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because on runway and damaged." } )
							self:_DestroyUnit(CleanUpUnit )
						end
					end
				end
				-- Clean Units which are waiting for a very long time in the CleanUpZone.
				if CleanUpUnit then
					local CleanUpUnitVelocity = CleanUpUnit:GetVelocityKMH()
					if CleanUpUnitVelocity < 1 then
						if UnitData.CleanUpMoved then
							if UnitData.CleanUpTime + 180 <= timer.getTime() then
								self:T( { "CleanUp Scheduler", "Destroy due to not moving anymore " .. CleanUpUnitName } )
								self:_DestroyUnit( CleanUpUnit )
							end
						end
					else
						UnitData.CleanUpTime = timer.getTime()
						UnitData.CleanUpMoved = true
					end
				end
				
			else
				-- Do nothing ...
				self.CleanUpList[CleanUpUnitName] = nil
			end
		else
			self:T( "CleanUp: Group " .. CleanUpUnitName .. " cannot be found in DCS RTE, removing ..." )
			self.CleanUpList[CleanUpUnitName] = nil
		end
	end
	self:T(CleanUpCount)
	
	return true
end

