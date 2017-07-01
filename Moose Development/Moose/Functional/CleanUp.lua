--- **Functional** -- The CLEANUP class keeps an area clean of crashing or colliding airplanes. It also prevents airplanes from firing within this area.
-- 
-- ===
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
-- 
-- @module CleanUp

--- @type CLEANUP.__
-- @extends Core.Base#BASE

--- @type CLEANUP
-- @extends #CLEANUP.__
-- @field #map<#string,Wrapper.Airbase#AIRBASE> Airbases Map of Airbases.

--- # CLEANUP, extends @{Base#BASE}
-- 
-- ![Banner Image](..\Presentations\CLEANUP\Dia1.JPG)
-- 
-- The CLEANUP class keeps airbases clean, and tries to guarantee continuous airbase operations, even under combat.
-- Specific airbases need to be provided that need to be guarded. Each airbase registered, will be guarded within a zone of 8 km around the airbase.
-- Any unit that fires a missile, or shoots within the zone of an airbase, will be monitored by CLEANUP.
-- Within the 8km zone, units cannot fire any missile, which prevents the airbase runway to receive missile or bomb hits. 
-- Any airborne or ground unit that is on the runway below 30 meters (default value) will be automatically removed if it is damaged.
-- 
-- This is not a full 100% secure implementation. It is still possible that CLEANUP cannot prevent (in-time) to keep the airbase clean.
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
-- So as an advise, I suggest you use the CLEANUP class with care:
-- 
--   * Only monitor airbases that really need to be monitored!
--   * Try not to monitor airbases that are likely to be invaded by enemy troops.
--     For these airbases, there is little use to keep them clean, as they will be invaded anyway...
--     
-- By following the above guidelines, you can add airbase cleanup with acceptable CPU overhead.
-- 
-- ## 1. CLEANUP Constructor
-- 
-- Creates the main object which is preventing the airbase to get polluted with debris on the runway, which halts the airbase.
-- 
--      -- Clean these Zones.
--      CleanUpAirports = CLEANUP:New( { AIRBASE.Caucasus.Tbilisi, AIRBASE.Caucasus.Kutaisi )
--      
--      -- or
--      CleanUpTbilisi = CLEANUP:New( AIRBASE.Caucasus.Tbilisi )
--      CleanUpKutaisi = CLEANUP:New( AIRBASE.Caucasus.Kutaisi )
-- 
-- ## 2. Add or Remove airbases
-- 
-- The method @{#CLEANUP.AddAirbase} to add an airbase to the cleanup validation process.
-- The method @{#CLEANUP.RemoveAirbase} removes an airbase from the cleanup validation process.
-- 
-- @field #CLEANUP
CLEANUP = {
	ClassName = "CLEANUP",
	TimeInterval = 0.2,
	CleanUpList = {},
	Airbases = {},
}


--- @field #CLEANUP.__
CLEANUP.__ = {}

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
	
	self:HandleEvent( EVENTS.Birth, self.__.OnEventBirth )
	
  self.CleanUpScheduler = SCHEDULER:New( self, self.__.CleanUpScheduler, {}, 1, self.TimeInterval )
	
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



function CLEANUP.__:IsInAirbase( Vec2 )

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



--- Destroys a @{Unit} from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param Wrapper.Unit#UNIT CleanUpUnit The object to be destroyed.
function CLEANUP.__:DestroyUnit( CleanUpUnit )
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



--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param Dcs.DCSTypes#Weapon MissileObject
function CLEANUP.__:DestroyMissile( MissileObject )
	self:F( { MissileObject } )
  
	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		self:T( "MissileObject Destroyed")
	end
end

--- @param #CLEANUP self
-- @param Core.Event#EVENTDATA EventData
function CLEANUP.__:OnEventBirth( EventData )
  self:F( { EventData } )
  
  self.CleanUpList[EventData.IniDCSUnitName] = {}
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnit = EventData.IniUnit
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroup = EventData.IniGroup
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpGroupName = EventData.IniDCSGroupName
  self.CleanUpList[EventData.IniDCSUnitName].CleanUpUnitName = EventData.IniDCSUnitName

  self:HandleEvent( EVENTS.EngineShutdown , self.__.EventAddForCleanUp )
  self:HandleEvent( EVENTS.EngineStartup, self.__.EventAddForCleanUp )
  self:HandleEvent( EVENTS.Hit, self.__.EventAddForCleanUp )
  self:HandleEvent( EVENTS.PilotDead, self.__.OnEventCrash )
  self:HandleEvent( EVENTS.Dead, self.__.OnEventCrash )
  self:HandleEvent( EVENTS.Crash, self.__.OnEventCrash )
  self:HandleEvent( EVENTS.Shot, self.__.OnEventShot )

end


--- Detects if a crash event occurs.
-- Crashed units go into a CleanUpList for removal.
-- @param #CLEANUP self
-- @param Core.Event#EVENTDATA Event
function CLEANUP.__:OnEventCrash( Event )
	self:F( { Event } )

  --TODO: This stuff is not working due to a DCS bug. Burning units cannot be destroyed.
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
-- @param #CLEANUP self
-- @param Core.Event#EVENTDATA Event
function CLEANUP.__:OnEventShot( Event )
	self:F( { Event } )

	-- Test if the missile was fired within one of the CLEANUP.AirbaseNames.
	if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
		-- Okay, the missile was fired within the CLEANUP.AirbaseNames, destroy the fired weapon.
    self:DestroyMissile( Event.Weapon )
	end
end

--- Detects if the Unit has an S_EVENT_HIT within the given AirbaseNames. If this is the case, destroy the unit.
-- @param #CLEANUP self
-- @param Core.Event#EVENTDATA Event
function CLEANUP.__:OnEventHit( Event )
	self:F( { Event } )

	if Event.IniUnit then
		if self:IsInAirbase( Event.IniUnit:GetVec2() ) then
			self:T( { "Life: ", Event.IniDCSUnitName, ' = ',  Event.IniUnit:GetLife(), "/", Event.IniUnit:GetLife0() } )
			if Event.IniUnit:GetLife() < Event.IniUnit:GetLife0() then
				self:T( "CleanUp: Destroy: " .. Event.IniDCSUnitName )
        CLEANUP.__:DestroyUnit( Event.IniUnit )
			end
		end
	end

	if Event.TgtUnit then
		if self:IsInAirbase( Event.TgtUnit:GetVec2() ) then
			self:T( { "Life: ", Event.TgtDCSUnitName, ' = ', Event.TgtUnit:GetLife(), "/", Event.TgtUnit:GetLife0() } )
			if Event.TgtUnit:GetLife() < Event.TgtUnit:GetLife0() then
				self:T( "CleanUp: Destroy: " .. Event.TgtDCSUnitName )
        CLEANUP.__:DestroyUnit( Event.TgtUnit )
			end
		end
	end
end

--- Add the @{DCSWrapper.Unit#Unit} to the CleanUpList for CleanUp.
-- @param #CLEANUP self
-- @param Wrapper.Unit#UNIT CleanUpUnit
-- @oaram #string CleanUpUnitName
function CLEANUP.__:AddForCleanUp( CleanUpUnit, CleanUpUnitName )
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

--- Detects if the Unit has an S_EVENT_ENGINE_SHUTDOWN or an S_EVENT_HIT within the given AirbaseNames. If this is the case, add the Group to the CLEANUP List.
-- @param #CLEANUP.__ self
-- @param Core.Event#EVENTDATA Event
function CLEANUP.__:EventAddForCleanUp( Event )

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
-- @param #CLEANUP self
function CLEANUP.__:CleanUpScheduler()

  local CleanUpCount = 0
	for CleanUpUnitName, CleanUpListData in pairs( self.CleanUpList ) do
	  CleanUpCount = CleanUpCount + 1
	
		local CleanUpUnit = CleanUpListData.CleanUpUnit -- Wrapper.Unit#UNIT
		local CleanUpGroupName = CleanUpListData.CleanUpGroupName

		if CleanUpUnit:IsAlive() ~= nil then

			if _DATABASE:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then

				local CleanUpCoordinate = CleanUpUnit:GetCoordinate()

        self:T( { "CleanUp Scheduler", CleanUpUnitName } )
        if CleanUpUnit:GetLife() <= CleanUpUnit:GetLife0() * 0.95 then
					if CleanUpUnit:IsAboveRunway() then
						if CleanUpUnit:InAir() then

							local CleanUpLandHeight = CleanUpCoordinate:GetLandHeight()
							local CleanUpUnitHeight = CleanUpCoordinate.y - CleanUpLandHeight
							
							if CleanUpUnitHeight < 30 then
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
				if CleanUpUnit then
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

