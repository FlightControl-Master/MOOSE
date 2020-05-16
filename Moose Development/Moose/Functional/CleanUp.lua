--- **Functional** -- Keep airbases clean of crashing or colliding airplanes, and kill missiles when being fired at airbases.
--
-- ===
--
-- ## Features:
--
--
--  * Try to keep the airbase clean and operational.
--  * Prevent airplanes from crashing.
--  * Clean up obstructing airplanes from the runway that are standing still for a period of time.
--  * Prevent airplanes firing missiles within the airbase zone.
--
-- ===
--
-- ## Missions:
--
-- [CLA - CleanUp Airbase](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/CLA%20-%20CleanUp%20Airbase)
--
-- ===
--
-- Specific airbases need to be provided that need to be guarded. Each airbase registered, will be guarded within a zone of 8 km around the airbase.
-- Any unit that fires a missile, or shoots within the zone of an airbase, will be monitored by CLEANUP_AIRBASE.
-- Within the 8km zone, units cannot fire any missile, which prevents the airbase runway to receive missile or bomb hits.
-- Any airborne or ground unit that is on the runway below 30 meters (default value) will be automatically removed if it is damaged.
--
-- This is not a full 100% secure implementation. It is still possible that CLEANUP_AIRBASE cannot prevent (in-time) to keep the airbase clean.
-- The following situations may happen that will still stop the runway of an airbase:
--
--   * A damaged unit is not removed on time when above the runway, and crashes on the runway.
--   * A bomb or missile is still able to dropped on the runway.
--   * Units collide on the airbase, and could not be removed on time.
--
-- When a unit is within the airbase zone and needs to be monitored,
-- its status will be checked every 0.25 seconds! This is required to ensure that the airbase is kept clean.
-- But as a result, there is more CPU overload.
--
-- So as an advise, I suggest you use the CLEANUP_AIRBASE class with care:
--
--   * Only monitor airbases that really need to be monitored!
--   * Try not to monitor airbases that are likely to be invaded by enemy troops.
--     For these airbases, there is little use to keep them clean, as they will be invaded anyway...
--
-- By following the above guidelines, you can add airbase cleanup with acceptable CPU overhead.
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions:
--
-- ===
--
-- @module Functional.CleanUp
-- @image CleanUp_Airbases.JPG

--- @type CLEANUP_AIRBASE.__ Methods which are not intended for mission designers, but which are used interally by the moose designer :-)
-- @field #map<#string,Wrapper.Airbase#AIRBASE> Airbases Map of Airbases.
-- @extends Core.Base#BASE

--- @type CLEANUP_AIRBASE
-- @extends #CLEANUP_AIRBASE.__

--- Keeps airbases clean, and tries to guarantee continuous airbase operations, even under combat.
--
-- # 1. CLEANUP_AIRBASE Constructor
--
-- Creates the main object which is preventing the airbase to get polluted with debris on the runway, which halts the airbase.
--
--      -- Clean these Zones.
--      CleanUpAirports = CLEANUP_AIRBASE:New( { AIRBASE.Caucasus.Tbilisi, AIRBASE.Caucasus.Kutaisi } )
--
--      -- or
--      CleanUpTbilisi = CLEANUP_AIRBASE:New( AIRBASE.Caucasus.Tbilisi )
--      CleanUpKutaisi = CLEANUP_AIRBASE:New( AIRBASE.Caucasus.Kutaisi )
--
-- # 2. Add or Remove airbases
--
-- The method @{#CLEANUP_AIRBASE.AddAirbase}() to add an airbase to the cleanup validation process.
-- The method @{#CLEANUP_AIRBASE.RemoveAirbase}() removes an airbase from the cleanup validation process.
--
-- # 3. Clean missiles and bombs within the airbase zone.
--
-- When missiles or bombs hit the runway, the airbase operations stop.
-- Use the method @{#CLEANUP_AIRBASE.SetCleanMissiles}() to control the cleaning of missiles, which will prevent airbases to stop.
-- Note that this method will not allow anymore airbases to be attacked, so there is a trade-off here to do.
--
-- @field #CLEANUP_AIRBASE
CLEANUP_AIRBASE = {
	ClassName = "CLEANUP_AIRBASE",
	TimeInterval = 0.2,
	CleanUpList = {},
}

-- @field #CLEANUP_AIRBASE.__
CLEANUP_AIRBASE.__ = {}

--- @field #CLEANUP_AIRBASE.__.Airbases
CLEANUP_AIRBASE.__.Airbases = {}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @param #CLEANUP_AIRBASE self
-- @param #list<#string> AirbaseNames Is a table of airbase names where the debris should be cleaned. Also a single string can be passed with one airbase name.
-- @return #CLEANUP_AIRBASE
-- @usage
--  -- Clean these Zones.
-- CleanUpAirports = CLEANUP_AIRBASE:New( { AIRBASE.Caucasus.Tbilisi, AIRBASE.Caucasus.Kutaisi )
-- or
-- CleanUpTbilisi = CLEANUP_AIRBASE:New( AIRBASE.Caucasus.Tbilisi )
-- CleanUpKutaisi = CLEANUP_AIRBASE:New( AIRBASE.Caucasus.Kutaisi )
function CLEANUP_AIRBASE:New( AirbaseNames )

  local self = BASE:Inherit( self, BASE:New() ) -- #CLEANUP_AIRBASE
	self:F( { AirbaseNames } )

	if type( AirbaseNames ) == 'table' then
    for AirbaseID, AirbaseName in pairs( AirbaseNames ) do
      self:AddAirbase( AirbaseName )
    end
	else
    local AirbaseName = AirbaseNames
    self:AddAirbase( AirbaseName )
	end

	self:HandleEvent( EVENTS.Birth, self.__.OnEventBirth )

  self.__.CleanUpScheduler = SCHEDULER:New( self, self.__.CleanUpSchedule, {}, 1, self.TimeInterval )

  self:HandleEvent( EVENTS.EngineShutdown , self.__.EventAddForCleanUp )
  self:HandleEvent( EVENTS.EngineStartup, self.__.EventAddForCleanUp )
  self:HandleEvent( EVENTS.Hit, self.__.EventAddForCleanUp )
  self:HandleEvent( EVENTS.PilotDead, self.__.OnEventCrash )
  self:HandleEvent( EVENTS.Dead, self.__.OnEventCrash )
  self:HandleEvent( EVENTS.Crash, self.__.OnEventCrash )

  for UnitName, Unit in pairs( _DATABASE.UNITS ) do
    local Unit = Unit -- Wrapper.Unit#UNIT
    if Unit:IsAlive() ~= nil then
      if self:IsInAirbase( Unit:GetVec2() ) then
        self:F( { UnitName = UnitName } )
        self.CleanUpList[UnitName] = {}
        self.CleanUpList[UnitName].CleanUpUnit = Unit
        self.CleanUpList[UnitName].CleanUpGroup = Unit:GetGroup()
        self.CleanUpList[UnitName].CleanUpGroupName = Unit:GetGroup():GetName()
        self.CleanUpList[UnitName].CleanUpUnitName = Unit:GetName()
      end
    end
  end

	return self
end

--- Adds an airbase to the airbase validation list.
-- @param #CLEANUP_AIRBASE self
-- @param #string AirbaseName
-- @return #CLEANUP_AIRBASE
function CLEANUP_AIRBASE:AddAirbase( AirbaseName )
  self.__.Airbases[AirbaseName] = AIRBASE:FindByName( AirbaseName )
  self:F({"Airbase:", AirbaseName, self.__.Airbases[AirbaseName]:GetDesc()})

  return self
end

--- Removes an airbase from the airbase validation list.
-- @param #CLEANUP_AIRBASE self
-- @param #string AirbaseName
-- @return #CLEANUP_AIRBASE
function CLEANUP_AIRBASE:RemoveAirbase( AirbaseName )
  self.__.Airbases[AirbaseName] = nil
  return self
end

--- Enables or disables the cleaning of missiles within the airbase zones.
-- Airbase operations stop when a missile or bomb is dropped at a runway.
-- Note that when this method is used, the airbase operations won't stop if
-- the missile or bomb was cleaned within the airbase zone, which is 8km from the center of the airbase.
-- However, there is a trade-off to make. Attacks on airbases won't be possible anymore if this method is used.
-- Note, one can also use the method @{#CLEANUP_AIRBASE.RemoveAirbase}() to remove the airbase from the control process as a whole,
-- when an enemy unit is near. That is also an option...
-- @param #CLEANUP_AIRBASE self
-- @param #string CleanMissiles (Default=true) If true, missiles fired are immediately destroyed. If false missiles are not controlled.
-- @return #CLEANUP_AIRBASE
function CLEANUP_AIRBASE:SetCleanMissiles( CleanMissiles )

  if CleanMissiles then
    self:HandleEvent( EVENTS.Shot, self.__.OnEventShot )
  else
    self:UnHandleEvent( EVENTS.Shot )
  end
end

function CLEANUP_AIRBASE.__:IsInAirbase( Vec2 )

  local InAirbase = false
  for AirbaseName, Airbase in pairs( self.__.Airbases ) do
    local Airbase = Airbase -- Wrapper.Airbase#AIRBASE
    if Airbase:GetZone():IsVec2InZone( Vec2 ) then
      InAirbase = true
      break;
    end
  end

  return InAirbase
end



--- Destroys a @{Wrapper.Unit} from the simulator, but checks first if it is still existing!
-- @param #CLEANUP_AIRBASE self
-- @param Wrapper.Unit#UNIT CleanUpUnit The object to be destroyed.
function CLEANUP_AIRBASE.__:DestroyUnit( CleanUpUnit )
	self:F( { CleanUpUnit } )

	if CleanUpUnit then
	  local CleanUpUnitName = CleanUpUnit:GetName()
		local CleanUpGroup = CleanUpUnit:GetGroup()
    -- TODO DCS BUG - Client bug in 1.5.3
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



--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @param #CLEANUP_AIRBASE self
-- @param DCS#Weapon MissileObject
function CLEANUP_AIRBASE.__:DestroyMissile( MissileObject )
	self:F( { MissileObject } )

	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		self:T( "MissileObject Destroyed")
	end
end

--- @param #CLEANUP_AIRBASE self
-- @param Core.Event#EVENTDATA EventData
function CLEANUP_AIRBASE.__:OnEventBirth( EventData )
  self:F( { EventData } )
  
  if EventData and EventData.IniUnit and EventData.IniUnit:IsAlive() ~= nil then
    if self:IsInAirbase( EventData.IniUnit:GetVec2() ) then
      self.CleanUpList[EventData.IniDCSUnitName] = {}
      self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnit = EventData.IniUnit
      self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroup = EventData.IniGroup
      self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroupName = EventData.IniDCSGroupName
      self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnitName = EventData.IniDCSUnitName
    end
  end

end


--- Detects if a crash event occurs.
-- Crashed units go into a CleanUpList for removal.
-- @param #CLEANUP_AIRBASE self
-- @param Core.Event#EVENTDATA Event
function CLEANUP_AIRBASE.__:OnEventCrash( Event )
	self:F( { Event } )

  --TODO: DCS BUG - This stuff is not working due to a DCS bug. Burning units cannot be destroyed.
	-- self:T("before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired
	-- self:T("after getGroup")
	-- _grp:destroy()
	-- self:T("after deactivateGroup")
	-- event.initiator:destroy()

  if Event.IniDCSUnitName and Event.IniCategory == Object.Category.UNIT then
    self.CleanUpList[Event.IniDCSUnitName] = {}
    self.CleanUpList[Event.IniDCSUnitName].CleanUpUnit = Event.IniUnit
    self.CleanUpList[Event.IniDCSUnitName].CleanUpGroup = Event.IniGroup
    self.CleanUpList[Event.IniDCSUnitName].CleanUpGroupName = Event.IniDCSGroupName
    self.CleanUpList[Event.IniDCSUnitName].CleanUpUnitName = Event.IniDCSUnitName
  end

end

--- Detects if a unit shoots a missile.
-- If this occurs within one of the airbases, then the weapon used must be destroyed.
-- @param #CLEANUP_AIRBASE self
-- @param Core.Event#EVENTDATA Event
function CLEANUP_AIRBASE.__:OnEventShot( Event )
	self:F( { Event } )

	-- Test if the missile was fired within one of the CLEANUP_AIRBASE.AirbaseNames.
	if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
		-- Okay, the missile was fired within the CLEANUP_AIRBASE.AirbaseNames, destroy the fired weapon.
    self:DestroyMissile( Event.Weapon )
	end
end

--- Detects if the Unit has an S_EVENT_HIT within the given AirbaseNames. If this is the case, destroy the unit.
-- @param #CLEANUP_AIRBASE self
-- @param Core.Event#EVENTDATA Event
function CLEANUP_AIRBASE.__:OnEventHit( Event )
	self:F( { Event } )

	if Event.IniUnit then
		if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
			self:T( { "Life: ", Event.IniDCSUnitName, ' = ',  Event.IniUnit:GetLife(), "/", Event.IniUnit:GetLife0() } )
			if Event.IniUnit:GetLife() < Event.IniUnit:GetLife0() then
				self:T( "CleanUp: Destroy: " .. Event.IniDCSUnitName )
        CLEANUP_AIRBASE.__:DestroyUnit( Event.IniUnit )
			end
		end
	end

	if Event.TgtUnit then
		if self:IsInAirbase( Event.TgtUnit:GetVec2() ) then
			self:T( { "Life: ", Event.TgtDCSUnitName, ' = ', Event.TgtUnit:GetLife(), "/", Event.TgtUnit:GetLife0() } )
			if Event.TgtUnit:GetLife() < Event.TgtUnit:GetLife0() then
				self:T( "CleanUp: Destroy: " .. Event.TgtDCSUnitName )
        CLEANUP_AIRBASE.__:DestroyUnit( Event.TgtUnit )
			end
		end
	end
end

--- Add the @{DCS#Unit} to the CleanUpList for CleanUp.
-- @param #CLEANUP_AIRBASE self
-- @param DCS#UNIT CleanUpUnit
-- @oaram #string CleanUpUnitName
function CLEANUP_AIRBASE.__:AddForCleanUp( CleanUpUnit, CleanUpUnitName )
	self:F( { CleanUpUnit, CleanUpUnitName } )

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName

	local CleanUpGroup = CleanUpUnit:GetGroup()

	self.CleanUpList[CleanUpUnitName].CleanUpGroup = CleanUpGroup
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = CleanUpGroup:GetName()
	self.CleanUpList[CleanUpUnitName].CleanUpTime = timer.getTime()
	self.CleanUpList[CleanUpUnitName].CleanUpMoved = false

	self:T( { "CleanUp: Add to CleanUpList: ", CleanUpGroup:GetName(), CleanUpUnitName } )

end

--- Detects if the Unit has an S_EVENT_ENGINE_SHUTDOWN or an S_EVENT_HIT within the given AirbaseNames. If this is the case, add the Group to the CLEANUP_AIRBASE List.
-- @param #CLEANUP_AIRBASE.__ self
-- @param Core.Event#EVENTDATA Event
function CLEANUP_AIRBASE.__:EventAddForCleanUp( Event )

  self:F({Event})


	if Event.IniDCSUnit and Event.IniCategory == Object.Category.UNIT then
		if self.CleanUpList[Event.IniDCSUnitName] == nil then
			if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
				self:AddForCleanUp( Event.IniUnit, Event.IniDCSUnitName )
			end
		end
	end

	if Event.TgtDCSUnit and Event.TgtCategory == Object.Category.UNIT then
		if self.CleanUpList[Event.TgtDCSUnitName] == nil then
			if self:IsInAirbase( Event.TgtUnit:GetVec2() ) then
				self:AddForCleanUp( Event.TgtUnit, Event.TgtDCSUnitName )
			end
		end
	end

end


--- At the defined time interval, CleanUp the Groups within the CleanUpList.
-- @param #CLEANUP_AIRBASE self
function CLEANUP_AIRBASE.__:CleanUpSchedule()

  local CleanUpCount = 0
	for CleanUpUnitName, CleanUpListData in pairs( self.CleanUpList ) do
	  CleanUpCount = CleanUpCount + 1

		local CleanUpUnit = CleanUpListData.CleanUpUnit -- Wrapper.Unit#UNIT
		local CleanUpGroupName = CleanUpListData.CleanUpGroupName

		if CleanUpUnit:IsAlive() ~= nil then

		  if self:IsInAirbase( CleanUpUnit:GetVec2() ) then

  			if _DATABASE:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then

  				local CleanUpCoordinate = CleanUpUnit:GetCoordinate()

          self:T( { "CleanUp Scheduler", CleanUpUnitName } )
          if CleanUpUnit:GetLife() <= CleanUpUnit:GetLife0() * 0.95 then
  					if CleanUpUnit:IsAboveRunway() then
  						if CleanUpUnit:InAir() then

  							local CleanUpLandHeight = CleanUpCoordinate:GetLandHeight()
  							local CleanUpUnitHeight = CleanUpCoordinate.y - CleanUpLandHeight

  							if CleanUpUnitHeight < 100 then
  								self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because below safe height and damaged." } )
  								self:DestroyUnit( CleanUpUnit )
  							end
  						else
  							self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because on runway and damaged." } )
  							self:DestroyUnit( CleanUpUnit )
  						end
  					end
  				end
  				-- Clean Units which are waiting for a very long time in the CleanUpZone.
  				if CleanUpUnit and not CleanUpUnit:GetPlayerName() then
  					local CleanUpUnitVelocity = CleanUpUnit:GetVelocityKMH()
  					if CleanUpUnitVelocity < 1 then
  						if CleanUpListData.CleanUpMoved then
  							if CleanUpListData.CleanUpTime + 180 <= timer.getTime() then
  								self:T( { "CleanUp Scheduler", "Destroy due to not moving anymore " .. CleanUpUnitName } )
  								self:DestroyUnit( CleanUpUnit )
  							end
  						end
  					else
  						CleanUpListData.CleanUpTime = timer.getTime()
  						CleanUpListData.CleanUpMoved = true
  					end
  				end
        else
          -- not anymore in an airbase zone, remove from cleanup list.
          self.CleanUpList[CleanUpUnitName] = nil
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
