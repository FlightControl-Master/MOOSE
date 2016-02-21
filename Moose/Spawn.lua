--- Dynamic spawning of Groups and Units.
-- @classmod SPAWN
-- @author Flightcontrol

MOOSE_Version = "0.1.1.1"

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )


SPAWN = {
	ClassName = "SPAWN",
}

--- Public 
-- @section Public

--- Creates the main object to spawn a Group defined in the DCS ME.
-- Spawned Groups and Units will follow the following naming convention within the DCS World run-time environment:
--       Groups will have the name SpawnPrefix#ggg, where ggg is a counter from 0 to 999 for each new spawned Group.
--       Units will have the name SpawnPrefix#ggg-uu, where uu is a counter from 0 to 99 for each new spawned Unit belonging to that Group.
-- @tparam string SpawnPrefix is the name of the Group in the ME that defines the Template. That Group must have the flag "Late Activation" set. Note that this SpawnPrefix name should not contain any # character.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
function SPAWN:New( SpawnPrefix )
trace.f(self.ClassName, SpawnPrefix)

	-- Inherits from BASE
	local self = BASE:Inherit( self, BASE:New() )
  
	local TemplateGroup = Group.getByName( SpawnPrefix )
	if TemplateGroup then
		self.SpawnPrefix = SpawnPrefix
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnScheduled = false													-- Reflects if the spawning for this SpawnPrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnPrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.SpawnRepeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxGroupsAlive = 0												-- The maximum amount of groups that can be alive of SpawnPrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnPrefix = '" .. SpawnPrefix .. "'" )
	end
	
	self.AddEvent( self, world.event.S_EVENT_BIRTH, self.OnBirth )
	self.AddEvent( self, world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self.AddEvent( self, world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self.EnableEvents( self )

	return self
end

--- Randomizes a defined route of the Template Group in the ME when the Group is Spawned. This is very useful to define extra variation in the DCS World run-time environment of the behaviour of Groups like Ground Units, Ships, Planes, Helicopters.
-- @tparam number SpawnStartPoint is the waypoint where the randomization begins. Note that the StartPoint = 0 equals the point where the Group is Spawned. This parameter is useful to avoid randomization to start from the first waypoint, but a bit further down the route...
-- @tparam number SpawnEndPoint is the waypoint where the randomization ends. this parameter is useful to avoid randomization to end at a waypoint earlier than the last waypoint on the route.
-- @tparam number SpawnRadius is the radius in meters, that defines the concentric circle in which the randomization of the new waypoint will take place, with the original waypoint located in the middle...
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field. 
-- -- The KA-50 has waypoints SP, 1, 2, 3, 4, DP. 
-- -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new ${SPAWN} of the helicopter.
-- -- The randomization of waypoint 2 and 3 will take place within a diameter of 4000 meters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):RandomizeRoute( 2, 2, 2000 )
 
function SPAWN:RandomizeRoute( SpawnStartPoint, SpawnEndPoint, SpawnRadius )
trace.f( self.ClassName, { SpawnStartPoint, SpawnEndPoint, SpawnRadius } )

	self.SpawnStartPoint = SpawnStartPoint						-- When the spawning occurs, randomize the route points from SpawnStartPoint.
	self.SpawnEndPoint = SpawnEndPoint							-- When the spawning occurs, randomize the route points till SpawnEndPoint.
	self.SpawnRadius = SpawnRadius								-- The Radius of randomization of the route points from SpawnStartPoint till SpawnEndPoint.
	
	return self
end

--- SPAWNs a new Group within varying time intervals. This is useful if you want to have continuity within your missions of certain (AI) Groups to be present (alive) within your missions.
-- @tparam number SpawnTime is the time interval defined in seconds between each new SPAWN of new Groups.
-- @tparam number SpawnTimeVariation is the variation to be applied on the defined time interval between each new SPAWN. The variation is defined as a value between 0 and 1, which expresses the %-tage of variation to be applied as the low and high time interval boundaries. Between these boundaries a new time interval will be applied. See usage.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- The time interval is set to SPAWN new helicopters between each 600 seconds, with a time variation of 50%.
-- -- The time variation in this case will be between 450 seconds and 750 seconds. 
-- -- This is calculated as follows: 
-- --      Low limit:   600 * ( 1 - 0.5 / 2 ) = 450 
-- --      High limit:  600 * ( 1 + 0.5 / 2 ) = 750
-- -- Between these two values, a random amount of seconds will be choosen for each new SPAWN of the helicopters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Schedule( 600, 0.5 )

function SPAWN:Schedule( SpawnTime, SpawnTimeVariation )
trace.f( self.ClassName, { SpawnTime, SpawnTimeVariation } )

	self.SpawnCurrentTimer = 0									-- The internal timer counter to trigger a scheduled spawning of SpawnPrefix.
	self.SpawnSetTimer = 0										-- The internal timer value when a scheduled spawning of SpawnPrefix occurs.
	self.AliveFactor = 1									--
	self.SpawnLowTimer = 0
	self.SpawnHighTimer = 0
	
	if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
		self.SpawnLowTimer = SpawnTime - SpawnTime / 2 * SpawnTimeVariation
		self.SpawnHighTimer = SpawnTime + SpawnTime / 2 * SpawnTimeVariation
		self:ScheduleStart()
	end

	trace.i( self.ClassName, { self.SpawnLowTimer, self.SpawnHighTimer } )
	
	return self
end

--- Will start the SPAWNing timers.
-- This function is called automatically when @{Schedule} is called.
function SPAWN:ScheduleStart()
trace.f( self.ClassName )

	--local ClientUnit = #AlivePlayerUnits()
	
	self.AliveFactor = 10 -- ( 10 - ClientUnit  ) / 10
	
	if self.SpawnScheduled == false then
		self.SpawnScheduled = true
		self.SpawnInit = true
		self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor / 10 , self.SpawnHighTimer * self.AliveFactor  / 10 )
		
		self.SpawnFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 1 )
	end
end

--- Will stop the scheduled SPAWNing activity.
function SPAWN:ScheduleStop()
trace.f( self.ClassName )
	self.SpawnScheduled = false
end

--- Limits the Maximum amount of Units to be alive, and the maximum amount of Groups to be SPAWNed within the DCS World run-time environment.
-- Note that this method is exceptionally important to balance the amount of Units alive within the DCSRTE and the performance of the mission. Depending on the machine etc, a mission can only process a maximum amount of units.
-- If the time interval must be short, but there should not be more Units or Groups alive than a maximum amount of units, then this function should be used...
-- @tparam number SpawnMaxGroupsAlive is the Maximum amount of Units to be alive. When there are more Units alive in the DCSRTE of SpawnPrefix, then no new SPAWN will happen of the Group, until some of these Units will be destroyed.
-- @tparam number SpawnMaxGroups is the Maximum amount of Groups that can be SPAWNed from SpawnPrefix. When there are more Groups alive in the DCSRTE of SpawnPrefix, then no more SPAWNs will happen of the Group. This parameter is useful to define a maximum amount of airplanes, ground troops, helicopters, ships etc within a supply area. 
--        This parameter accepts the value 0, which expresses no Group count limits.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- This helicopter group consists of one Unit. So, this group will SPAWN maximum 2 groups simultaneously within the DCSRTE.
-- -- There will be maximum 24 groups SPAWNed during the whole mission lifetime. 
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Limit( 2, 24 )

function SPAWN:Limit( SpawnMaxGroupsAlive, SpawnMaxGroups )
trace.f( self.ClassName, { SpawnMaxGroupsAlive, SpawnMaxGroups } )

	self.SpawnMaxGroupsAlive = SpawnMaxGroupsAlive				-- The maximum amount of groups that can be alive of SpawnPrefix at the same time.
	self.SpawnMaxGroups = SpawnMaxGroups						-- The maximum amount of groups that can be spawned.

	return self
end

--- This function is rather complicated to understand. But I'll try to explain...
-- This function becomes useful when you need to SPAWN random types of Groups defined within the ME, but they all need to follow the same Template route and have the same SpawnPrefix name, then this method becomes very useful.
-- @tparam table{string,...} SpawnPrefixTable is a table with the names of the Groups defined within the ME (with late activatio on), from which on a new SPAWN of SpawnPrefix (the main Group name), a NEW Group will be choosen as the Group to be SPAWNed.
-- In other words, this method randomizes between a defined set of Groups the Group to be SPAWNed for each new SPAWN.
-- @treturn SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- -- Choose between 13 different 'US Tank Platoon' configurations for each new SPAWN the Group to be SPAWNed for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SpawnPrefixes.
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be SPAWNed during the whole mission.
-- Spawn_US_Platoon = { 'US Tank Platoon 1', 'US Tank Platoon 2', 'US Tank Platoon 3', 'US Tank Platoon 4', 'US Tank Platoon 5', 
--                      'US Tank Platoon 6', 'US Tank Platoon 7', 'US Tank Platoon 8', 'US Tank Platoon 9', 'US Tank Platoon 10', 
--                      'US Tank Platoon 11', 'US Tank Platoon 12', 'US Tank Platoon 13' }
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )

function SPAWN:RandomizeTemplate( SpawnPrefixTable )
trace.f( self.ClassName, { SpawnPrefix, SpawnPrefixTable } )

	self.SpawnPrefixTable = SpawnPrefixTable

	return self
end

--- When a Group got SPAWNed, it has a life within the DCSRTE. For planes and helicopters, when these Units go home and land on their home airbases and farps, they normally would taxi to the parking spot, shut-down their engines and wait forever until the Group is removed by the DCSRTE.
-- This function is used to Re-Spawn automatically (so no extra call is needed anymore) the same Group after it landed. This will enable a SPAWNed group to be Re-SPAWNed after it lands, until it is destroyed...
-- Note: When the Group is respawned, it will @{ReSpawn} at the original airbase where it took off. So ensure that the paths for Groups that ReSpawn, always return to the original airbase.
-- @treturn SPAWN
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN:New( 'TF1 RU Su-34 Krymsk@AI - Attack Ships' ):Schedule( 2, 3, 1800, 0.4 ):SpawnUncontrolled():RandomizeRoute( 1, 1, 3000 ):RepeatOnEngineShutDown()

function SPAWN:Repeat()
trace.f( self.ClassName )

	self.SpawnRepeat = true
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true

	self:AddEvent( world.event.S_EVENT_LAND, self.OnLand )
	self:AddEvent( world.event.S_EVENT_TAKEOFF, self.OnTakeOff )
	self:AddEvent( world.event.S_EVENT_ENGINE_SHUTDOWN, self.OnEngineShutDown )
	self:EnableEvents()

	return self
end

--- Same as the @{Repeat) method.
-- @treturn SPAWN
-- @see Repeat

function SPAWN:RepeatOnLanding()
trace.f( self.ClassName )

	self:Repeat()
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true
	
	return self
end

--- Same as the @{Repeat) method, but now the Group will respawn after its engines have shut down.
-- @treturn SPAWN
-- @see Repeat

function SPAWN:RepeatOnEngineShutDown()
trace.f( self.ClassName )

	self:Repeat()
	self.RepeatOnEngineShutDown = true
	self.RepeatOnLanding = false
	
	return self
end


--- Will SPAWN a Group whenever you want to do this.
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- Uses @{DATABASE} global object defined in MOOSE.
-- @treturn SPAWN
function SPAWN:Spawn( SpawnGroupName )
trace.f( self.ClassName )
	local SpawnTemplate = self:_Prepare( SpawnGroupName )
	if self.SpawnStartPoint ~= 0 or self.SpawnEndPoint ~= 0 then
		SpawnTemplate = self:_RandomizeRoute( SpawnTemplate )
	end
	_Database:Spawn( SpawnTemplate )
	if self.SpawnRepeat then
		_Database:SetStatusGroup( SpawnTemplate.name, "ReSpawn" )
	end
	return self
end


--- Will Re-SPAWN a Group based on a given GroupName. The GroupName must be a group that is already alive within the DCSRTE and should have a Group Template defined in the ME (with Late Activation flag on).
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- @tparam string SpawnGroupName 
-- @treturn SPAWN
-- Uses _Database global object defined in MOOSE.
function SPAWN:ReSpawn( SpawnGroupName )
trace.f( self.ClassName, { SpawnGroupName } )
	
	local SpawnGroup = Group.getByName( SpawnGroupName )
		if SpawnGroup then
		SpawnGroup:destroy()
	end
	
	local SpawnTemplate = self:_Prepare( SpawnGroupName )

	-- Give the units of the Group the name following the SPAWN naming convention, so that they don't replace other units within the ME.
	local SpawnUnits = table.getn( SpawnTemplate.units )
	for u = 1, SpawnUnits do
		SpawnTemplate.units[u].name = string.format( '%s-%02d', SpawnGroupName, u )
		SpawnTemplate.units[u].unitId = nil
	end
	_Database:Spawn( SpawnTemplate )
	return self
end

--- Will SPAWN a Group whenever you want to do this, but for AIR Groups only to be applied, and will SPAWN the Group in Uncontrolled mode... This will be similar to the Uncontrolled flag setting in the ME.
-- @treturn SPAWN
function SPAWN:SpawnUncontrolled()
trace.f( self.ClassName )
	
	self.UnControlled = true
	
	local SpawnCountStart = self.SpawnCount + 1
	for SpawnCount = SpawnCountStart, self.SpawnMaxGroups do
		local SpawnTemplate = self:_Prepare( )
		SpawnTemplate.uncontrolled = true
		_Database:Spawn( SpawnTemplate )
	end
	self.SpawnCount = SpawnCountStart - 1
	
	return self
end


--- Will SPAWN a Group from a Carrier. This function is mostly advisable to be used if you want to simulate SPAWNing from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- @tparam Group HostUnit is the AIR unit or GROUND unit dropping or unloading the Spawn group.
-- @tparam string TargetZonePrefix is the Prefix of the Zone defined in the ME where the Group should be moving to after drop.
-- @tparam string NewGroupName (forgot this).
-- @tparam bool LateActivate (optional) does the SPAWNing with Lateactivation on.
function SPAWN:FromHost( HostUnit, OuterRadius, InnerRadius, NewGroupName, LateActivate )
trace.f( self.ClassName, { HostUnit, OuterRadius, InnerRadius, NewGroupName, LateActivate } )

	local SpawnTemplate

	if HostUnit and HostUnit:isExist() then -- and HostUnit:getUnit(1):inAir() == false then

		SpawnTemplate = self:_Prepare( NewGroupName )
		
		if ( self.SpawnMaxGroups == 0 ) or ( self.SpawnCount <= self.SpawnMaxGroups ) then
			if ( self.SpawnMaxGroupsAlive == 0 ) or ( self.AliveUnits < self.SpawnMaxGroupsAlive * #self.SpawnTemplate.units ) or self.UnControlled then

				if LateActivate ~= nil then
					if LateActivate == true then
						SpawnTemplate.lateActivation = true
						SpawnTemplate.visible = true
					end
				end

				SpawnTemplate = self:_RandomizeRoute( SpawnTemplate )
				
				local RouteCount = table.getn( SpawnTemplate.route.points )
				trace.i( self.ClassName, "RouteCount = " .. RouteCount )

				local UnitDeployPosition = HostUnit:getPoint()
				for PointID, Point in pairs( SpawnTemplate.route.points ) do
					Point.x = UnitDeployPosition.x
					Point.y = UnitDeployPosition.z
					Point.alt = nil
					Point.alt_type = nil
				end
				
				for v = 1, table.getn( SpawnTemplate.units ) do
					local SpawnPos = routines.getRandPointInCircle( UnitDeployPosition, OuterRadius, InnerRadius )
					SpawnTemplate.units[v].x = SpawnPos.x
					SpawnTemplate.units[v].y = SpawnPos.y
					trace.i( self.ClassName, 'SpawnTemplate.units['..v..'].x = ' .. SpawnTemplate.units[v].x .. ', SpawnTemplate.units['..v..'].y = ' .. SpawnTemplate.units[v].y )
				end
				
				_Database:Spawn( SpawnTemplate )
			end
		end
	end
	
	return SpawnTemplate 
end

--- Will SPAWN a Group from a Carrier. This function is mostly advisable to be used if you want to simulate SPAWNing from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- @tparam Group CarrierUnit is the AIR unit or GROUND unit dropping or unloading the Spawn group.
-- @tparam string TargetZonePrefix is the Prefix of the Zone defined in the ME where the Group should be moving to after drop.
-- @tparam string NewGroupName (forgot this).
-- @tparam bool LateActivate (optional) does the SPAWNing with Lateactivation on.
function SPAWN:FromCarrier( CarrierUnit, TargetZonePrefix, NewGroupName, LateActivate )
trace.f( self.ClassName, { CarrierUnit, TargetZonePrefix, NewGroupName, LateActivate } )

	local SpawnTemplate

	if CarrierUnit and CarrierUnit:isExist() then -- and CarrierUnit:getUnit(1):inAir() == false then

		SpawnTemplate = self:_Prepare( NewGroupName )
		
		if ( self.SpawnMaxGroups == 0 ) or ( self.SpawnCount <= self.SpawnMaxGroups ) then
			if ( self.SpawnMaxGroupsAlive == 0 ) or ( self.AliveUnits < self.SpawnMaxGroupsAlive * #self.SpawnTemplate.units ) or self.UnControlled then

				if LateActivate ~= nil then
					if LateActivate == true then
						SpawnTemplate.lateActivation = true
						SpawnTemplate.visible = true
					end
				end

				SpawnTemplate = self:_RandomizeRoute( SpawnTemplate )
				
				local TargetZone = trigger.misc.getZone( TargetZonePrefix )
				local TargetZonePos = {}
				TargetZonePos.x = TargetZone.point.x + math.random(TargetZone.radius / 2 * -1, TargetZone.radius / 2 )
				TargetZonePos.z = TargetZone.point.z + math.random(TargetZone.radius / 2 * -1, TargetZone.radius / 2 )

				local RouteCount = table.getn( SpawnTemplate.route.points )
				trace.i( self.ClassName, "RouteCount = " .. RouteCount )

				local UnitDeployPosition = CarrierUnit:getPosition().p
				SpawnTemplate.route.points[1].x = UnitDeployPosition.x - 50
				SpawnTemplate.route.points[1].y = UnitDeployPosition.z
				SpawnTemplate.route.points[1].alt = nil
				SpawnTemplate.route.points[1].alt_type = nil

				if SpawnStartPoint ~= 0 and SpawnEndPoint ~= 0 then
					SpawnTemplate.route.points[RouteCount].x = TargetZonePos.x
					SpawnTemplate.route.points[RouteCount].y = TargetZonePos.z
				else 
					SpawnTemplate.route.points[RouteCount].x = TargetZone.point.x
					SpawnTemplate.route.points[RouteCount].y = TargetZone.point.z
				end
				
				trace.i( self.ClassName, 'SpawnTemplate.route.points['..RouteCount..'].x = ' .. SpawnTemplate.route.points[RouteCount].x .. ', SpawnTemplate.route.points['..RouteCount..'].y = ' .. SpawnTemplate.route.points[RouteCount].y )

				for v = 1, table.getn( SpawnTemplate.units ) do
					local SpawnPos = routines.getRandPointInCircle( UnitDeployPosition, 40, 10 )
					SpawnTemplate.units[v].x = SpawnPos.x
					SpawnTemplate.units[v].y = SpawnPos.y
					trace.i( self.ClassName, 'SpawnTemplate.units['..v..'].x = ' .. SpawnTemplate.units[v].x .. ', SpawnTemplate.units['..v..'].y = ' .. SpawnTemplate.units[v].y )
				end
				
				_Database:Spawn( SpawnTemplate )
			end
		end
	end
	
	trace.r( self.ClassName, "" ) 

	return SpawnTemplate 
end


--- Will return the SpawnGroupName either with with a specific count number or without any count.
-- @tparam number SpawnIndex is the number of the Group that is to be SPAWNed.
-- @treturn string SpawnGroupName
function SPAWN:SpawnGroupName( SpawnIndex )
trace.f("Spawn", SpawnIndex )

	if SpawnIndex then
		trace.i( self.ClassName, string.format( '%s#%03d', self.SpawnPrefix, SpawnIndex ) )
		return string.format( '%s#%03d', self.SpawnPrefix, SpawnIndex )
	else
		trace.i( self.ClassName, self.SpawnPrefix )
		return self.SpawnPrefix
	end
	
end

function SPAWN:GetLastIndex()

	return self.SpawnCount
end


function SPAWN:GetLastGroup()
trace.f( self.ClassName )

	local LastGroupName = self:SpawnGroupName( self:GetLastIndex() )
	
	return GROUP:New( Group.getByName( LastGroupName ) )
end


--- Will SPAWN a Group within a given ZoneName.
-- @tparam string ZonePrefix is the name of the zone where the Group is to be SPAWNed.
-- @treturn SpawnTemplate
function SPAWN:InZone( ZonePrefix, SpawnGroupName )
trace.f("Spawn", ZonePrefix )
	
	local SpawnTemplate
	
	if SpawnGroupName then
		SpawnTemplate = self:_Prepare( SpawnGroupName )
	else
		SpawnTemplate =  self:_Prepare()
	end

	local Zone = trigger.misc.getZone( ZonePrefix )
	local ZonePos = {}
	ZonePos.x = Zone.point.x + math.random(Zone.radius * -1, Zone.radius)
	ZonePos.z = Zone.point.z + math.random(Zone.radius * -1, Zone.radius)

	local RouteCount = table.getn(SpawnTemplate.route.points)

	SpawnTemplate.route.points[1].x = ZonePos.x
	SpawnTemplate.route.points[1].y = ZonePos.z
	SpawnTemplate.route.points[1].alt = nil
	SpawnTemplate.route.points[1].alt_type = nil

	SpawnTemplate.route.points[RouteCount].x = ZonePos.x
	SpawnTemplate.route.points[RouteCount].y = ZonePos.z
	
	_Database:Spawn( SpawnTemplate )
	
	return SpawnTemplate
end


--- Private
-- @section

--- Gets the CategoryID of the Group with the given SpawnPrefix
function SPAWN:_GetGroupCategoryID( SpawnPrefix )
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		return TemplateGroup:getCategory()
	else
		return nil
	end
end

--- Gets the CoalitionID of the Group with the given SpawnPrefix
function SPAWN:_GetGroupCoalitionID( SpawnPrefix )
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		return TemplateGroup:getCoalition()
	else
		return nil
	end
end

--- Gets the CountryID of the Group with the given SpawnPrefix
function SPAWN:_GetGroupCountryID( SpawnPrefix )
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		local TemplateUnits = TemplateGroup:getUnits()
		return TemplateUnits[1]:getCountry()
	else
		return nil
	end
end

--- Gets the Group Template from the ME environment definition.
-- This method used the @{DATABASE} object, which contains ALL initial and new SPAWNed object in MOOSE.
function SPAWN:_GetTemplate( SpawnPrefix )
trace.f( self.ClassName, SpawnPrefix )

	local SpawnTemplate = nil

	SpawnTemplate = routines.utils.deepCopy( _Database.Groups[SpawnPrefix].Template )
	
	if SpawnTemplate == nil then
		error( 'No Template returned for SpawnPrefix = ' .. SpawnPrefix )
	end

	SpawnTemplate.SpawnCoalitionID = self:_GetGroupCoalitionID( SpawnPrefix )
	SpawnTemplate.SpawnCategoryID = self:_GetGroupCategoryID( SpawnPrefix )
	SpawnTemplate.SpawnCountryID = self:_GetGroupCountryID( SpawnPrefix )
	
	trace.r( self.ClassName, "", { SpawnTemplate } )
	return SpawnTemplate
end

--- Prepares the new Group Template before Spawning.
function SPAWN:_Prepare( SpawnGroupName )
trace.f( self.ClassName )
	
	local SpawnCount
	local SpawnUnits
	
	local SpawnTemplate = routines.utils.deepCopy( self.SpawnTemplate )

	if self.SpawnRoute ~= nil then
		local SpawnRoute = self:_GetTemplate( self.SpawnRoute ).route
		SpawnTemplate.route = routines.utils.deepCopy( SpawnRoute )
	end
	
	-- Increase the spawn counter for the group
	if SpawnGroupName then
		SpawnTemplate.name = SpawnGroupName
	else
		self.SpawnCount = self.SpawnCount + 1
		SpawnTemplate.name = self:SpawnGroupName( self.SpawnCount )
	end

	
	SpawnTemplate.groupId = nil
	SpawnTemplate.lateActivation = false
	if SpawnTemplate.SpawnCategoryID == Group.Category.GROUND then
		SpawnTemplate.visible = false
	end
	if SpawnTemplate.SpawnCategoryID == Group.Category.HELICOPTER or SpawnTemplate.SpawnCategoryID == Group.Category.AIRPLANE then
		SpawnTemplate.uncontrolled = false
	end

	if self.SpawnPrefixTable ~= nil then
		local SpawnTemplatePrefix = self.SpawnPrefixTable[ math.random( 1, #self.SpawnPrefixTable ) ]
		SpawnTemplateRandom = self:_GetTemplate( SpawnTemplatePrefix )
		SpawnTemplate.SpawnCoalitionID = SpawnTemplateRandom.SpawnCoalitionID
		SpawnTemplate.SpawnCategoryID = SpawnTemplateRandom.SpawnCategoryID
		SpawnTemplate.SpawnCountryID = SpawnTemplateRandom.SpawnCountryID
		SpawnTemplate.units = routines.utils.deepCopy( SpawnTemplateRandom.units )
	end
	
	SpawnUnits = table.getn( SpawnTemplate.units )
	for u = 1, SpawnUnits do
		SpawnTemplate.units[u].name = string.format( SpawnTemplate.name .. '-%02d', u )
		SpawnTemplate.units[u].unitId = nil
		SpawnTemplate.units[u].x = SpawnTemplate.route.points[1].x + math.random( -50, 50 )
		SpawnTemplate.units[u].y = SpawnTemplate.route.points[1].y + math.random( -50, 50 )
	end
	
	trace.r( self.ClassName, "", SpawnTemplate.name )
	return SpawnTemplate
end

--- Will randomize the route of the Group Template.
function SPAWN:_RandomizeRoute( SpawnTemplate )
trace.f( self.ClassName, SpawnTemplate.name )

	if self.SpawnStartPoint and self.SpawnEndPoint then
		local RouteCount = table.getn( SpawnTemplate.route.points )
		for t = self.SpawnStartPoint, RouteCount - self.SpawnEndPoint do
			SpawnTemplate.route.points[t].x = SpawnTemplate.route.points[t].x + math.random( self.SpawnRadius * -1, self.SpawnRadius )
			SpawnTemplate.route.points[t].y = SpawnTemplate.route.points[t].y + math.random( self.SpawnRadius * -1, self.SpawnRadius )
			SpawnTemplate.route.points[t].alt = nil
			--SpawnGroup.route.points[t].alt_type = nil
			trace.i( self.ClassName, 'SpawnTemplate.route.points[' .. t .. '].x = ' .. SpawnTemplate.route.points[t].x .. ', SpawnTemplate.route.points[' .. t .. '].y = ' .. SpawnTemplate.route.points[t].y )
		end
	end
	
	trace.r( self.ClassName, "", SpawnTemplate.name )
	return SpawnTemplate
end

--- Events
-- @section Events

--- Obscolete
-- @todo Need to delete this... _Database does this now ...
function SPAWN:OnBirth( event )
trace.f( self.ClassName, { event } )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and event.initiator:getName() then
			trace.l(self.ClassName, "OnBirth", "Birth object : " .. event.initiator:getName() )
			local EventPrefix = string.match( event.initiator:getName(), ".*#" )
			if EventPrefix == self.SpawnPrefix .. '#' then
				--MessageToAll( "Mission command: unit " .. SpawnPrefix .. " spawned." , 5,  EventPrefix .. '/Event')
				self.AliveUnits = self.AliveUnits + 1
				trace.l(self.ClassName, "OnBirth", self.AliveUnits )
			end
		end
	end

end

--- Obscolete
-- @todo Need to delete this... _Database does this now ...
function SPAWN:OnDeadOrCrash( event )
trace.f( self.ClassName, { event } )

	if event.initiator and event.initiator:getName() then
		trace.l( self.ClassName, "OnDeadOrCrash", "Dead object : " .. event.initiator:getName() )
		local EventPrefix = string.match( event.initiator:getName(), ".*#" )
		if EventPrefix == self.SpawnPrefix .. '#' then
--					local DestroyedUnit = Unit.getByName( EventPrefix )
--					if DestroyedUnit and DestroyedUnit.getLife() <= 1.0 then
				--MessageToAll( "Mission command: unit " .. SpawnPrefix .. " crashed." , 5,  EventPrefix .. '/Event')
				self.AliveUnits = self.AliveUnits - 1
				trace.l( self.ClassName, "OnDeadOrCrash", self.AliveUnits )
--					end
		end
	end
end

--- Will detect AIR Units landing... When the event takes place, the SPAWNed Group is registered as landed.
-- This is needed to ensure that Re-SPAWNing is only done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:OnLand( event )
trace.f( self.ClassName, { event } )

	if event.initiator and event.initiator:getName() then
		trace.l( self.ClassName, "OnLand", "Landed object : " .. event.initiator:getName() )
		local EventPrefix = string.match( event.initiator:getName(), ".*#" )
		if EventPrefix == self.SpawnPrefix .. '#' then
			self.Landed = true
			trace.l( self.ClassName, "OnLand", "self.Landed = true" )
			if self.Landed and self.RepeatOnLanding then
				local SpawnGroupName = Unit.getGroup(event.initiator):getName()
				trace.l( self.ClassName, "OnLand", "ReSpawn " .. SpawnGroupName )
				self:ReSpawn( SpawnGroupName )
			end
		end
	end
end

--- Will detect AIR Units taking off... When the event takes place, the SPAWNed Group is registered as airborne...
-- This is needed to ensure that Re-SPAWNing only is done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:OnTakeOff( event )
trace.f( self.ClassName, { event } )

	if event.initiator and event.initiator:getName() then
		trace.l( self.ClassName, "OnTakeOff", "TakeOff object : " .. event.initiator:getName() )
		local EventPrefix = string.match( event.initiator:getName(), ".*#" )
		if EventPrefix == self.SpawnPrefix .. '#' then
			trace.l( self.ClassName, "OnTakeOff", "self.Landed = false" )
			self.Landed = false
		end
	end
end

--- Will detect AIR Units shutting down their engines ...
-- When the event takes place, and the method @{RepeatOnEngineShutDown} was called, the SPAWNed Group will Re-SPAWN.
-- But only when the Unit was registered to have landed.
-- @see OnTakeOff
-- @see OnLand
-- @todo Need to test for AIR Groups only...
function SPAWN:OnEngineShutDown( event )
trace.f( self.ClassName, { event } )

	if event.initiator and event.initiator:getName() then
		trace.l( self.ClassName, "OnEngineShutDown", "EngineShutDown object : " .. event.initiator:getName() )
		local EventPrefix = string.match( event.initiator:getName(), ".*#" )
		if EventPrefix == self.SpawnPrefix .. '#' then
			if self.Landed and self.RepeatOnEngineShutDown then
				local SpawnGroupName = Unit.getGroup(event.initiator):getName()
				trace.l( self.ClassName, "OnEngineShutDown", "ReSpawn " .. SpawnGroupName )
				self:ReSpawn( SpawnGroupName )
			end
		end
	end
end

--- Scheduled
-- @section Scheduled

--- This function is called automatically by the Spawning scheduler.
-- It is the internal worker method SPAWNing new Groups on the defined time intervals.
function SPAWN:_Scheduler()
trace.l( self.ClassName, '_Scheduler', self.SpawnPrefix )
	
	if self.SpawnInit or self.SpawnCurrentTimer == self.SpawnSetTimer then
		-- Validate if there are still groups left in the batch...
		if ( self.SpawnMaxGroups == 0 ) or ( self.SpawnCount <= self.SpawnMaxGroups ) then
			if self.AliveUnits < self.SpawnMaxGroupsAlive * #self.SpawnTemplate.units or self.UnControlled then
				self:Spawn()
				self.SpawnInit = false
			end
		end
		if self.SpawnScheduled == true then
			--local ClientUnit = #AlivePlayerUnits()
			self.AliveFactor = 1 -- ( 10 - ClientUnit  ) / 10
			self.SpawnCurrentTimer = 0
			self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor , self.SpawnHighTimer * self.AliveFactor )
		end
	else
		self.SpawnCurrentTimer = self.SpawnCurrentTimer + 1
	end
end
