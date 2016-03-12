--- Dynamic spawning of Groups and Units.
-- @classmod SPAWN
-- @author Flightcontrol

MOOSE_Version = "0.1.1.1"

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )
Include.File( "Zone" )


SPAWN = {
	ClassName = "SPAWN",
}

--- Public 
-- @section Public

--- Creates the main object to spawn a Group defined in the DCS ME.
-- Spawned Groups and Units will follow the following naming convention within the DCS World run-time environment:
--       Groups will have the name SpawnTemplatePrefix#ggg, where ggg is a counter from 0 to 999 for each new spawned Group.
--       Units will have the name SpawnTemplatePrefix#ggg-uu, where uu is a counter from 0 to 99 for each new spawned Unit belonging to that Group.
-- @tparam string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template. That Group must have the flag "Late Activation" set. Note that this SpawnTemplatePrefix name should not contain any # character.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
function SPAWN:New( SpawnTemplatePrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( { SpawnTemplatePrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.SpawnRepeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxGroupsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	self.AddEvent( self, world.event.S_EVENT_BIRTH, self.OnBirth )
	self.AddEvent( self, world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self.AddEvent( self, world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self.EnableEvents( self )

	return self
end

--- Creates the main object to spawn a Group defined in the DCS ME.
-- Spawned Groups and Units will follow the following naming convention within the DCS World run-time environment:
--       Groups will have the name SpawnTemplatePrefix#ggg, where ggg is a counter from 0 to 999 for each new spawned Group.
--       Units will have the name SpawnTemplatePrefix#ggg-uu, where uu is a counter from 0 to 99 for each new spawned Unit belonging to that Group.
-- @tparam string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template. That Group must have the flag "Late Activation" set. Note that this SpawnTemplatePrefix name should not contain any # character.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
function SPAWN:NewWithAlias( SpawnTemplatePrefix, SpawnAliasPrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( { SpawnTemplatePrefix, SpawnAliasPrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnAliasPrefix = SpawnAliasPrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.SpawnRepeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxGroupsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	self.AddEvent( self, world.event.S_EVENT_BIRTH, self.OnBirth )
	self.AddEvent( self, world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self.AddEvent( self, world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self.EnableEvents( self )

	return self
end


function SPAWN:Limit( SpawnMaxGroupsAlive, SpawnMaxGroups )
	self:T( { self.SpawnTemplatePrefix, SpawnMaxGroupsAlive, SpawnMaxGroups } )

	self.SpawnMaxGroupsAlive = SpawnMaxGroupsAlive				-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
	self.SpawnMaxGroups = SpawnMaxGroups						-- The maximum amount of groups that can be spawned.
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:InitializeSpawnGroups( SpawnGroupID )
	end

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
	self:T( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius } )

	self.SpawnRandomizeRoute = true
	self.SpawnRandomizeRouteStartPoint = SpawnStartPoint
	self.SpawnRandomizeRouteEndPoint = SpawnEndPoint
	self.SpawnRandomizeRouteRadius = SpawnRadius

	for GroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeRoute( GroupID )
	end
	
	return self
end

function SPAWN:_RandomizeRoute( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeRoute, self.SpawnRandomizeRouteStartPoint, self.SpawnRandomizeRouteEndPoint, self.SpawnRandomizeRouteRadius } )

	if self.SpawnRandomizeRoute then
		local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate
		local RouteCount = #SpawnTemplate.route.points
		
		for t = self.SpawnRandomizeRouteStartPoint + 1, ( RouteCount - self.SpawnRandomizeRouteEndPoint ) do
			SpawnTemplate.route.points[t].x = SpawnTemplate.route.points[t].x + math.random( self.SpawnRandomizeRouteRadius * -1, self.SpawnRandomizeRouteRadius )
			SpawnTemplate.route.points[t].y = SpawnTemplate.route.points[t].y + math.random( self.SpawnRandomizeRouteRadius * -1, self.SpawnRandomizeRouteRadius )
			-- TODO: manage altitude for airborne units ...
			SpawnTemplate.route.points[t].alt = nil
			--SpawnGroup.route.points[t].alt_type = nil
			self:T( 'SpawnTemplate.route.points[' .. t .. '].x = ' .. SpawnTemplate.route.points[t].x .. ', SpawnTemplate.route.points[' .. t .. '].y = ' .. SpawnTemplate.route.points[t].y )
		end
	end
	
	return self
end

--- This function is rather complicated to understand. But I'll try to explain...
-- This function becomes useful when you need to SPAWN random types of Groups defined within the ME, but they all need to follow the same Template route and have the same SpawnTemplatePrefix name, then this method becomes very useful.
-- @tparam table{string,...} SpawnTemplatePrefixTable is a table with the names of the Groups defined within the ME (with late activatio on), from which on a new SPAWN of SpawnTemplatePrefix (the main Group name), a NEW Group will be choosen as the Group to be SPAWNed.
-- In other words, this method randomizes between a defined set of Groups the Group to be SPAWNed for each new SPAWN.
-- @treturn SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- -- Choose between 13 different 'US Tank Platoon' configurations for each new SPAWN the Group to be SPAWNed for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SpawnTemplatePrefixes.
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be SPAWNed during the whole mission.
-- Spawn_US_Platoon = { 'US Tank Platoon 1', 'US Tank Platoon 2', 'US Tank Platoon 3', 'US Tank Platoon 4', 'US Tank Platoon 5', 
--                      'US Tank Platoon 6', 'US Tank Platoon 7', 'US Tank Platoon 8', 'US Tank Platoon 9', 'US Tank Platoon 10', 
--                      'US Tank Platoon 11', 'US Tank Platoon 12', 'US Tank Platoon 13' }
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )

function SPAWN:RandomizeTemplate( SpawnTemplatePrefixTable )
	self:T( { self.SpawnTemplatePrefix, SpawnTemplatePrefixTable } )

	self.SpawnTemplatePrefixTable = SpawnTemplatePrefixTable
	self.SpawnRandomizeTemplate = true

	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeTemplate( SpawnGroupID )
	end
	
	return self
end


function SPAWN:_RandomizeTemplate( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex } )

	if self.SpawnRandomizeTemplate then
		self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefixTable[ math.random( 1, #self.SpawnTemplatePrefixTable ) ]
		self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
		self.SpawnGroups[SpawnIndex].SpawnTemplate.route = routines.utils.deepCopy( self.SpawnTemplate.route )
		self.SpawnGroups[SpawnIndex].SpawnTemplate.x = self.SpawnTemplate.x
		self.SpawnGroups[SpawnIndex].SpawnTemplate.y = self.SpawnTemplate.y
	end
	
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
	self:T( { self.SpawnTemplatePrefix } )

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
	self:T( { self.SpawnTemplatePrefix } )

	self:Repeat()
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true
	
	return self
end

--- Same as the @{Repeat) method, but now the Group will respawn after its engines have shut down.
-- @treturn SPAWN
-- @see Repeat

function SPAWN:RepeatOnEngineShutDown()
	self:T( { self.SpawnTemplatePrefix } )

	self:Repeat()
	self.RepeatOnEngineShutDown = true
	self.RepeatOnLanding = false
	
	return self
end

function SPAWN:CleanUp( SpawnCleanUpInterval )
	self:T( { self.SpawnTemplatePrefix, SpawnCleanUpInterval } )

	self.SpawnCleanUpInterval = SpawnCleanUpInterval
	self.SpawnCleanUpTimeStamps = {}
	self.CleanUpFunction = routines.scheduleFunction( self._SpawnCleanUpScheduler, { self }, timer.getTime() + 1, 60 )
	
	return self
end



--- Makes the Groups visible before start (like a batallion).
-- @tparam number SpawnZone 		A @{ZONE} where the group will be positioned. The X and Y coordinates of the zone define the start position.
-- @tparam number SpawnAngle 		The angle in degrees how the Groups and each Unit of the Group will be positioned.
-- @tparam number SpawnFormation    The formation of the Units within the Group.
-- @tparam number SpawnWidth		The amount of Groups that will be positioned on the X axis.
-- @tparam number SpawnDeltaX       The space between each Group on the X-axis.
-- @tparam number SpawnDeltaY		The space between each Group on the Y-axis.
-- @treturn SPAWN
-- @usage
-- -- Define an array of Groups within Zone "Start".
-- Spawn_BE_Ground = SPAWN:New( 'BE Ground' ):Limit( 2, 24 ):Visible( ZONE:New( "Start" ), 90, "Diamond", 10, 100, 50 )

function SPAWN:SpawnArray( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY )
	self:T( { self.SpawnTemplatePrefix, SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY } )

	self.SpawnVisible = true									-- When the first Spawn executes, all the Groups need to be made visible before start.
	
	local SpawnX = 0
	local SpawnY = 0
	local SpawnXIndex = 0
	local SpawnYIndex = 0
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:T( { SpawnX, SpawnY, SpawnXIndex, SpawnYIndex } )

		self.SpawnGroups[SpawnGroupID].Visible = true
		self.SpawnGroups[SpawnGroupID].Spawned = false
		
		SpawnXIndex = SpawnXIndex + 1
		if SpawnWidth and SpawnWidth ~= 0 then
			if SpawnXIndex >= SpawnWidth then
				SpawnXIndex = 0
				SpawnYIndex = SpawnYIndex + 1
			end
		end

		local SpawnRootX = self.SpawnGroups[SpawnGroupID].SpawnTemplate.x
		local SpawnRootY = self.SpawnGroups[SpawnGroupID].SpawnTemplate.y
		
		self:_TranslateRotate( SpawnGroupID, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle )
		
		self.SpawnGroups[SpawnGroupID].SpawnTemplate.lateActivation = true
		self.SpawnGroups[SpawnGroupID].SpawnTemplate.visible = true
		
		self.SpawnGroups[SpawnGroupID].Visible = true
		self.SpawnGroups[SpawnGroupID].Group = _Database:Spawn( self.SpawnGroups[SpawnGroupID].SpawnTemplate )

		SpawnX = SpawnXIndex * SpawnDeltaX
		SpawnY = SpawnYIndex * SpawnDeltaY
	end
	
	return self
end

function SPAWN:_TranslateRotate( SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle } )
	
	-- Translate
	local TranslatedX = SpawnX
	local TranslatedY = SpawnY
	
	-- Rotate
	-- From Wikipedia: https://en.wikipedia.org/wiki/Rotation_matrix#Common_rotations
	-- x' = x \cos \theta - y \sin \theta\
	-- y' = x \sin \theta + y \cos \theta\ 
	local RotatedX = - TranslatedX * math.cos( math.rad( SpawnAngle ) )
					 + TranslatedY * math.sin( math.rad( SpawnAngle ) )
	local RotatedY =   TranslatedX * math.sin( math.rad( SpawnAngle ) )
					 + TranslatedY * math.cos( math.rad( SpawnAngle ) )
	
	-- Assign
	self.SpawnGroups[SpawnIndex].SpawnTemplate.x = SpawnRootX - RotatedX
	self.SpawnGroups[SpawnIndex].SpawnTemplate.y = SpawnRootY + RotatedY

					 
	local SpawnUnitCount = table.getn( self.SpawnGroups[SpawnIndex].SpawnTemplate.units )
	for u = 1, SpawnUnitCount do
		
		-- Translate
		local TranslatedX = SpawnX 
		local TranslatedY = SpawnY - 10 * ( u - 1 )
		
		-- Rotate
		local RotatedX = - TranslatedX * math.cos( math.rad( SpawnAngle ) ) 
						 + TranslatedY * math.sin( math.rad( SpawnAngle ) )
		local RotatedY =   TranslatedX * math.sin( math.rad( SpawnAngle ) )
						 + TranslatedY * math.cos( math.rad( SpawnAngle ) )
		
		-- Assign
		self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].x = SpawnRootX - RotatedX
		self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].y = SpawnRootY + RotatedY
		self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading = math.rad( SpawnAngle )
	end
	
	return self
end

function SPAWN:GetSpawnIndex( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxGroupsAlive, self.AliveUnits, #self.SpawnTemplate.units } )

	
	if ( self.SpawnMaxGroups == 0 ) or ( SpawnIndex <= self.SpawnMaxGroups ) then
		if ( self.SpawnMaxGroupsAlive == 0 ) or ( self.AliveUnits < self.SpawnMaxGroupsAlive * #self.SpawnTemplate.units ) or self.UnControlled then
			self.SpawnIndex = SpawnIndex
			if not self.SpawnGroups[self.SpawnIndex] then
				self:InitializeSpawnGroups( self.SpawnIndex )
			end
		else
			return nil
		end
	else
		return nil
	end
	
	return self.SpawnIndex
end


--- Will SPAWN a Group whenever you want to do this.
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- Uses @{DATABASE} global object defined in MOOSE.
-- @treturn SPAWN
function SPAWN:Spawn()
	self:T( { self.SpawnTemplatePrefix, self.SpawnIndex } )

	return self:SpawnWithIndex( self.SpawnIndex + 1 )
end

--- Will Re-SPAWN a Group based on a given GroupName. The GroupName must be a group that is already alive within the DCSRTE and should have a Group Template defined in the ME (with Late Activation flag on).
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- @tparam string SpawnGroupName 
-- @treturn SPAWN
-- Uses _Database global object defined in MOOSE.
function SPAWN:ReSpawn( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex } )
	
	if not SpawnIndex then
		SpawnIndex = 1
	end

	--local SpawnGroup = self:GetGroupFromIndex( SpawnIndex ):GetDCSGroup()
	--if SpawnGroup then
		--DCSGroup:destroy()
	--end
	
	return self:SpawnWithIndex( SpawnIndex )
end

--- Will SPAWN a Group with a specified index number whenever you want to do this.
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- Uses @{DATABASE} global object defined in MOOSE.
-- @treturn GROUP The @{GROUP} that was spawned. You can use this group for further actions.
function SPAWN:SpawnWithIndex( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups } )
	
	if self:GetSpawnIndex( SpawnIndex ) then
		
		if self.SpawnGroups[self.SpawnIndex].Visible then
			self.SpawnGroups[self.SpawnIndex].Group:Activate()
		else
			self:T( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
			self.SpawnGroups[self.SpawnIndex].Group = _Database:Spawn( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
			--if self.SpawnRepeat then
			--	_Database:SetStatusGroup( SpawnTemplate.name, "ReSpawn" )
			--end
		end
		
		self.SpawnGroups[self.SpawnIndex].Spawned = true
		return self.SpawnGroups[self.SpawnIndex].Group
	else
		env.info( "No more Groups to Spawn" )
	end

	return nil
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

function SPAWN:SpawnScheduled( SpawnTime, SpawnTimeVariation )
	self:T( { SpawnTime, SpawnTimeVariation } )

	self.SpawnCurrentTimer = 0									-- The internal timer counter to trigger a scheduled spawning of SpawnTemplatePrefix.
	self.SpawnSetTimer = 0										-- The internal timer value when a scheduled spawning of SpawnTemplatePrefix occurs.
	self.AliveFactor = 1									--
	self.SpawnLowTimer = 0
	self.SpawnHighTimer = 0
	
	if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
		self.SpawnLowTimer = SpawnTime - SpawnTime / 2 * SpawnTimeVariation
		self.SpawnHighTimer = SpawnTime + SpawnTime / 2 * SpawnTimeVariation
		self:ScheduleStart()
	end

	self:T( { self.SpawnLowTimer, self.SpawnHighTimer } )
	
	return self
end

--- Will start the SPAWNing timers.
-- This function is called automatically when @{Schedule} is called.
function SPAWN:ScheduleStart()
	self:T( { self.SpawnTemplatePrefix } )

	--local ClientUnit = #AlivePlayerUnits()
	
	self.AliveFactor = 10 -- ( 10 - ClientUnit  ) / 10
	
	if self.SpawnIsScheduled == false then
		self.SpawnIsScheduled = true
		self.SpawnInit = true
		self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor / 10 , self.SpawnHighTimer * self.AliveFactor  / 10 )
		
		self.SpawnFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 1 )
	end
end

--- Will stop the scheduled SPAWNing activity.
function SPAWN:ScheduleStop()
	self:T( { self.SpawnTemplatePrefix } )
	
	self.SpawnIsScheduled = false
end

--- Limits the Maximum amount of Units to be alive, and the maximum amount of Groups to be SPAWNed within the DCS World run-time environment.
-- Note that this method is exceptionally important to balance the amount of Units alive within the DCSRTE and the performance of the mission. Depending on the machine etc, a mission can only process a maximum amount of units.
-- If the time interval must be short, but there should not be more Units or Groups alive than a maximum amount of units, then this function should be used...
-- @tparam number SpawnMaxGroupsAlive is the Maximum amount of Units to be alive. When there are more Units alive in the DCSRTE of SpawnTemplatePrefix, then no new SPAWN will happen of the Group, until some of these Units will be destroyed.
-- @tparam number SpawnMaxGroups is the Maximum amount of Groups that can be SPAWNed from SpawnTemplatePrefix. When there are more Groups alive in the DCSRTE of SpawnTemplatePrefix, then no more SPAWNs will happen of the Group. This parameter is useful to define a maximum amount of airplanes, ground troops, helicopters, ships etc within a supply area. 
--        This parameter accepts the value 0, which expresses no Group count limits.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- This helicopter group consists of one Unit. So, this group will SPAWN maximum 2 groups simultaneously within the DCSRTE.
-- -- There will be maximum 24 groups SPAWNed during the whole mission lifetime. 
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Limit( 2, 24 )



--- Will SPAWN a Group whenever you want to do this, but for AIR Groups only to be applied, and will SPAWN the Group in Uncontrolled mode... This will be similar to the Uncontrolled flag setting in the ME.
-- @treturn SPAWN
function SPAWN:UnControlled()
	self:T( { self.SpawnTemplatePrefix } )
	
	self.SpawnUnControlled = true
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self.SpawnGroups[SpawnGroupID].UnControlled = true
	end
	
	return self
end


--- Will SPAWN a Group from a Hosting @{UNIT}. This function is mostly advisable to be used if you want to simulate SPAWNing from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- Note that each point in the route assigned to the spawning @{GROUP} is reset to the Point of the spawn.
-- You can use the returned @{GROUP} to further define the route to be followed.
-- @tparam UNIT HostUnit is the AIR unit or GROUND unit dropping or unloading the Spawn group.
-- @treturn GROUP Spawned.
-- @treturn nil when nothing was spawned.
function SPAWN:SpawnFromUnit( HostUnit, OuterRadius, InnerRadius, SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, HostUnit, SpawnFormation, SpawnIndex } )

	if HostUnit and HostUnit:IsAlive() then -- and HostUnit:getUnit(1):inAir() == false then

		if SpawnIndex then
		else
			SpawnIndex = self.SpawnIndex + 1
		end
		
		if self:GetSpawnIndex( SpawnIndex ) then
			
			local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
		
			if SpawnTemplate then

				local UnitPoint = HostUnit:GetPoint()
				--for PointID, Point in pairs( SpawnTemplate.route.points ) do
					--Point.x = UnitPoint.x
					--Point.y = UnitPoint.y
					--Point.alt = nil
					--Point.alt_type = nil
				--end
				
				SpawnTemplate.route.points = nil
				SpawnTemplate.route.points = {}
				SpawnTemplate.route.points[1] = {}
				SpawnTemplate.route.points[1].x = UnitPoint.x
				SpawnTemplate.route.points[1].y = UnitPoint.y

				if not InnerRadius then
					InnerRadius = 10
				end
				
				if not OuterRadius then
					OuterRadius = 50
				end
				
				-- Apply SpawnFormation
				for UnitID = 1, #SpawnTemplate.units do
					if InnerRadius == 0 then
						SpawnTemplate.units[UnitID].x = UnitPoint.x
						SpawnTemplate.units[UnitID].y = UnitPoint.y
					else
						local CirclePos = routines.getRandPointInCircle( UnitPoint, InnerRadius+1, InnerRadius )
						SpawnTemplate.units[UnitID].x = CirclePos.x
						SpawnTemplate.units[UnitID].y = CirclePos.y
					end
					self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
				end
				
				local SpawnPos = routines.getRandPointInCircle( UnitPoint, InnerRadius+1, InnerRadius )
				local Point = {}
				Point.type = "Turning Point"
				Point.x = SpawnPos.x
				Point.y = SpawnPos.y
				Point.action = "Cone"
				Point.speed = 5
				
				table.insert( SpawnTemplate.route.points, 2, Point )
				
				return self:SpawnWithIndex( self.SpawnIndex )
			end
		end
	end
	
	return nil
end

--- Will spawn a Group within a given @{ZONE}.
-- @tparam ZONE The @{ZONE} where the Group is to be SPAWNed.
-- @treturn GROUP that was spawned.
-- @treturn nil when nothing as spawned.
function SPAWN:SpawnInZone( Zone, SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, Zone, SpawnIndex } )
	
	if Zone then
		
		if SpawnIndex then
		else
			SpawnIndex = self.SpawnIndex + 1
		end
		
		if self:GetSpawnIndex( SpawnIndex ) then

			local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
			
			if SpawnTemplate then
		
				local ZonePoint = Zone:GetPoint()

				SpawnTemplate.route.points = nil
				SpawnTemplate.route.points = {}
				SpawnTemplate.route.points[1] = {}
				SpawnTemplate.route.points[1].x = ZonePoint.x
				SpawnTemplate.route.points[1].y = ZonePoint.y
				
				-- Apply SpawnFormation
				for UnitID = 1, #SpawnTemplate.units do
					SpawnTemplate.units[UnitID].x = ZonePoint.x
					SpawnTemplate.units[UnitID].y = ZonePoint.y
					self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
				end
				
				local SpawnPos = Zone:GetRandomPoint()
				local Point = {}
				Point.type = "Turning Point"
				Point.x = SpawnPos.x
				Point.y = SpawnPos.y
				Point.action = "Cone"
				Point.speed = 5
				
				table.insert( SpawnTemplate.route.points, 2, Point )
				
				return self:SpawnWithIndex( self.SpawnIndex )
			end
		end
	end
	
	return nil
end


--- Will return the SpawnGroupName either with with a specific count number or without any count.
-- @tparam number SpawnIndex is the number of the Group that is to be SPAWNed.
-- @treturn string SpawnGroupName
function SPAWN:SpawnGroupName( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex } )

	local SpawnPrefix = self.SpawnTemplatePrefix
	if self.SpawnAliasPrefix then
		SpawnPrefix = self.SpawnAliasPrefix
	end

	if SpawnIndex then
		local SpawnName = string.format( '%s#%03d', SpawnPrefix, SpawnIndex )
		self:T( SpawnName )
		return SpawnName
	else
		self:T( SpawnPrefix )
		return SpawnPrefix
	end
	
end

function SPAWN:GetGroupFromIndex( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )
	
	if SpawnIndex then
		local SpawnGroup = self.SpawnGroups[SpawnIndex].Group
		return SpawnGroup
	else
		local SpawnGroup = self.SpawnGroups[1].Group
		return SpawnGroup
	end
end

function SPAWN:GetGroupIndexFromDCSUnit( DCSUnit )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )
	
	local IndexString = string.match( DCSUnit:getName(), "#.*-" ):sub( 2, -2 )
	self:T( IndexString )
	
	if IndexString then
		local Index = tonumber( IndexString )
		self:T( { "Index:", IndexString, Index } )
		return Index
	end
	
	return nil
end

function SPAWN:GetPrefixFromDCSUnit( DCSUnit )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

	local SpawnPrefix = string.match( DCSUnit:getName(), ".*#" ):sub( 1, -2 )
	self:T( SpawnPrefix )

	return SpawnPrefix
end

function SPAWN:GetGroupFromDCSUnit( DCSUnit )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )
	
	local SpawnPrefix = self:GetPrefixFromDCSUnit( DCSUnit )
	
	if self.SpawnTemplatePrefix == SpawnPrefix or ( self.SpawnAliasPrefix and self.SpawnAliasPrefix == SpawnPrefix ) then
		local SpawnGroupIndex = self:GetGroupIndexFromDCSUnit( DCSUnit )
		local SpawnGroup = self.SpawnGroups[SpawnGroupIndex].Group
		self:T( SpawnGroup )
		return SpawnGroup
	end

	return nil
end


--TODO: Rename to GetGroupIndexFromGroup
function SPAWN:GetGroupIndexFromGroup( SpawnGroup )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )
	
	local IndexString = string.match( SpawnGroup:GetName(), "#.*$" ):sub( 2 )
	local Index = tonumber( IndexString )
	
	self:T( IndexString, Index )
	return Index
	
end

function SPAWN:GetLastIndex()
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

	return self.SpawnMaxGroups
end


function SPAWN:InitializeSpawnGroups( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )

	if not self.SpawnGroups[SpawnIndex] then
		self.SpawnGroups[SpawnIndex] = {}
		self.SpawnGroups[SpawnIndex].Visible = false
		self.SpawnGroups[SpawnIndex].Spawned = false
		self.SpawnGroups[SpawnIndex].UnControlled = false
		self.SpawnGroups[SpawnIndex].Spawned = false
		self.SpawnGroups[SpawnIndex].SpawnTime = 0
		
		self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefix
		self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
	end
	
	self:_RandomizeTemplate( SpawnIndex )
	self:_RandomizeRoute( SpawnIndex )
	--self:_TranslateRotate( SpawnIndex )
	
	return self.SpawnGroups[SpawnIndex]
end



function SPAWN:GetFirstAliveGroup( SpawnCursor )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

	for SpawnIndex = 1, self.SpawnCount do
		local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
		if SpawnGroup and SpawnGroup:IsAlive() then
			SpawnCursor = SpawnIndex
			return SpawnGroup, SpawnCursor
		end
	end
	
	return nil, nil
end

function SPAWN:GetNextAliveGroup( SpawnCursor )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

	SpawnCursor = SpawnCursor + 1
	for SpawnIndex = SpawnCursor, self.SpawnCount do
		local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
		if SpawnGroup and SpawnGroup:IsAlive() then
			SpawnCursor = SpawnIndex
			return SpawnGroup, SpawnCursor
		end
	end
	
	return nil, nil
end

function SPAWN:GetLastAliveGroup()
	self:T( { self.SpawnTemplatePrefixself.SpawnAliasPrefix } )

	self.SpawnIndex = self:GetLastIndex()
	for SpawnIndex = self.SpawnIndex, 1, -1 do
		local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
		if SpawnGroup and SpawnGroup:IsAlive() then
			self.SpawnIndex = SpawnIndex
			return SpawnGroup
		end
	end

	self.SpawnIndex = nil
	return nil
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
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnPrefix } )
	
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
function SPAWN:_GetTemplate( SpawnTemplatePrefix )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnTemplatePrefix } )

	local SpawnTemplate = nil

	SpawnTemplate = routines.utils.deepCopy( _Database.Groups[SpawnTemplatePrefix].Template )
	
	if SpawnTemplate == nil then
		error( 'No Template returned for SpawnTemplatePrefix = ' .. SpawnTemplatePrefix )
	end

	SpawnTemplate.SpawnCoalitionID = self:_GetGroupCoalitionID( SpawnTemplatePrefix )
	SpawnTemplate.SpawnCategoryID = self:_GetGroupCategoryID( SpawnTemplatePrefix )
	SpawnTemplate.SpawnCountryID = self:_GetGroupCountryID( SpawnTemplatePrefix )
	
	self:T( { SpawnTemplate } )
	return SpawnTemplate
end

--- Prepares the new Group Template.
function SPAWN:_Prepare( SpawnTemplatePrefix, SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )
	
	local SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
	SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
	
	SpawnTemplate.groupId = nil
	SpawnTemplate.lateActivation = false

	if SpawnTemplate.SpawnCategoryID == Group.Category.GROUND then
		SpawnTemplate.visible = false
	end
	
	if SpawnTemplate.SpawnCategoryID == Group.Category.HELICOPTER or SpawnTemplate.SpawnCategoryID == Group.Category.AIRPLANE then
		SpawnTemplate.uncontrolled = false
	end

	for UnitID = 1, #SpawnTemplate.units do
		SpawnTemplate.units[UnitID].name = string.format( SpawnTemplate.name .. '-%02d', UnitID )
		SpawnTemplate.units[UnitID].unitId = nil
		SpawnTemplate.units[UnitID].x = SpawnTemplate.route.points[1].x
		SpawnTemplate.units[UnitID].y = SpawnTemplate.route.points[1].y 
	end
	
	self:T( { "Template:", SpawnTemplate } )
	return SpawnTemplate
		
end

--- Events
-- @section Events

--- Obscolete
-- @todo Need to delete this... _Database does this now ...
function SPAWN:OnBirth( event )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and event.initiator:getName() then
			local EventPrefix = self:GetPrefixFromDCSUnit( event.initiator )
			if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
				self:T( { "Birth event: " .. event.initiator:getName(), event } )
				--MessageToAll( "Mission command: unit " .. SpawnTemplatePrefix .. " spawned." , 5,  EventPrefix .. '/Event')
				self.AliveUnits = self.AliveUnits + 1
				self:T( "Alive Units: " .. self.AliveUnits )
			end
		end
	end

end

--- Obscolete
-- @todo Need to delete this... _Database does this now ...
function SPAWN:OnDeadOrCrash( event )


	if event.initiator and event.initiator:getName() then
		local EventPrefix = self:GetPrefixFromDCSUnit( event.initiator )
		if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
			self:T( { "Dead event: " .. event.initiator:getName(), event } )
--					local DestroyedUnit = Unit.getByName( EventPrefix )
--					if DestroyedUnit and DestroyedUnit.getLife() <= 1.0 then
				--MessageToAll( "Mission command: unit " .. SpawnTemplatePrefix .. " crashed." , 5,  EventPrefix .. '/Event')
				self.AliveUnits = self.AliveUnits - 1
				self:T( "Alive Units: " .. self.AliveUnits )
--					end
		end
	end
end

--- Will detect AIR Units taking off... When the event takes place, the SPAWNed Group is registered as airborne...
-- This is needed to ensure that Re-SPAWNing only is done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:OnTakeOff( event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "TakeOff event: " .. event.initiator:getName(), event } )
			self:T( "self.Landed = false" )
			self.Landed = false
		end
	end
end

--- Will detect AIR Units landing... When the event takes place, the SPAWNed Group is registered as landed.
-- This is needed to ensure that Re-SPAWNing is only done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:OnLand( event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "Landed event:" .. event.initiator:getName(), event } )
			self.Landed = true
			self:T( "self.Landed = true" )
			if self.Landed and self.RepeatOnLanding then
				local SpawnGroupIndex = self:GetGroupIndexFromGroup( SpawnGroup )
				self:T( { "Landed:", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
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

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "EngineShutDown event: " .. event.initiator:getName(), event } )
			if self.Landed and self.RepeatOnEngineShutDown then
				local SpawnGroupIndex = self:GetGroupIndexFromGroup( SpawnGroup )
				self:T( { "EngineShutDown: ", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- Scheduled
-- @section Scheduled

--- This function is called automatically by the Spawning scheduler.
-- It is the internal worker method SPAWNing new Groups on the defined time intervals.
function SPAWN:_Scheduler()
self:T( { "_Scheduler", self.SpawnTemplatePrefix, self.SpawnAliasPrefix, self.SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxGroupsAlive } )
	
	if self.SpawnInit or self.SpawnCurrentTimer == self.SpawnSetTimer then
		-- Validate if there are still groups left in the batch...
		self:Spawn()
		self.SpawnInit = false
		if self.SpawnIsScheduled == true then
			--local ClientUnit = #AlivePlayerUnits()
			self.AliveFactor = 1 -- ( 10 - ClientUnit  ) / 10
			self.SpawnCurrentTimer = 0
			self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor , self.SpawnHighTimer * self.AliveFactor )
		end
	else
		self.SpawnCurrentTimer = self.SpawnCurrentTimer + 1
	end
end

function SPAWN:_SpawnCleanUpScheduler()
	self:T( "CleanUp Scheduler:" .. self.SpawnTemplatePrefix )

	local SpawnCursor
	local SpawnGroup, SpawnCursor = self:GetFirstAliveGroup( SpawnCursor )

	while SpawnGroup do
		
		if SpawnGroup:AllOnGround() and SpawnGroup:GetMaxVelocity() < 1 then
			if not self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] then
				self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] = timer.getTime()
			else
				if self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] + self.SpawnCleanUpInterval < timer.getTime() then
					SpawnGroup:Destroy()
				end
			end
		else
			self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] = nil
		end
		
		SpawnGroup, SpawnCursor = self:GetNextAliveGroup( SpawnCursor )
	end
	
end


