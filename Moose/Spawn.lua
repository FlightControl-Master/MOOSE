--- Dynamic spawning of groups (and units).
-- 
-- @{#SPAWN} class
-- ===============
-- The @{#SPAWN} class allows to spawn dynamically new groups, based on pre-defined initialization settings, modifying the behaviour when groups are spawned.
-- For each group to be spawned, within the mission editor, a group has to be created with the "late activation flag" set. We call this group the *"Spawn Template"* of the SPAWN object.
-- A reference to this Spawn Template needs to be provided when constructing the SPAWN object, by indicating the name of the group within the mission editor in the constructor methods.
-- 
-- Within the SPAWN object, there is an internal index that keeps track of which group from the internal group list was spawned. 
-- When new groups get spawned by using the SPAWN functions (see below), it will be validated whether the Limits (@{#SPAWN.Limit}) of the SPAWN object are not reached.
-- When all is valid, a new group will be created by the spawning methods, and the internal index will be increased with 1.
-- 
-- Regarding the name of new spawned groups, a _SpawnPrefix_ will be assigned for each new group created. 
-- If you want to have the Spawn Template name to be used as the _SpawnPrefix_ name, use the @{#SPAWN.New} constructor.
-- However, when the @{#SPAWN.NewWithAlias} constructor was used, the Alias name will define the _SpawnPrefix_ name.
-- Groups will follow the following naming structure when spawned at run-time:
-- 
--   1. Spawned groups will have the name _SpawnPrefix_#ggg, where ggg is a counter from 0 to 999.
--   2. Spawned units will have the name _SpawnPrefix_#ggg-uu, where uu is a counter from 0 to 99 for each new spawned unit belonging to the group.
-- 
-- Some additional notes that need to be remembered:
-- 
--   * Templates are actually groups defined within the mission editor, with the flag "Late Activation" set. As such, these groups are never used within the mission, but are used by the @{#SPAWN} module.
--   * It is important to defined BEFORE you spawn new groups, a proper initialization of the SPAWN instance is done with the options you want to use.
--   * When designing a mission, NEVER name groups using a "#" within the name of the group Spawn Template(s), or the SPAWN module logic won't work anymore.
--   
-- SPAWN construction methods:
-- =========================== 
-- Create a new SPAWN object with the @{#SPAWN.New} or the @{#SPAWN.NewWithAlias} methods:
-- 
--   * @{#SPAWN.New}: Creates a new SPAWN object taking the name of the group that functions as the Template.
--
-- It is important to understand how the SPAWN class works internally. The SPAWN object created will contain internally a list of groups that will be spawned and that are already spawned.
-- The initialization functions will modify this list of groups so that when a group gets spawned, ALL information is already prepared when spawning. This is done for performance reasons.
-- So in principle, the group list will contain all parameters and configurations after initialization, and when groups get actually spawned, this spawning can be done quickly and efficient.
--
-- SPAWN initialization methods: 
-- =============================
-- A spawn object will behave differently based on the usage of initialization methods:  
-- 
--   * @{#SPAWN.Limit}: Limits the amount of groups that can be alive at the same time and that can be dynamically spawned.
--   * @{#SPAWN.RandomizeRoute}: Randomize the routes of spawned groups.
--   * @{#SPAWN.RandomizeTemplate}: Randomize the group templates so that when a new group is spawned, a random group template is selected from one of the templates defined. 
--   * @{#SPAWN.Uncontrolled}: Spawn plane groups uncontrolled.
--   * @{#SPAWN.Array}: Make groups visible before they are actually activated, and order these groups like a batallion in an array.
--   * @{#SPAWN.InitRepeat}: Re-spawn groups when they land at the home base. Similar functions are @{#SPAWN.InitRepeatOnLanding} and @{#SPAWN.InitRepeatOnEngineShutDown}.
-- 
-- SPAWN spawning methods:
-- =======================
-- Groups can be spawned at different times and methods:
-- 
--   * @{#SPAWN.Spawn}: Spawn one new group based on the last spawned index.
--   * @{#SPAWN.ReSpawn}: Re-spawn a group based on a given index.
--   * @{#SPAWN.SpawnScheduled}: Spawn groups at scheduled but randomized intervals. You can use @{#SPAWN.SpawnScheduleStart} and @{#SPAWN.SpawnScheduleStop} to start and stop the schedule respectively.
--   * @{#SPAWN.SpawnFromUnit}: Spawn a new group taking the position of a @{UNIT}.
--   * @{#SPAWN.SpawnInZone}: Spawn a new group in a @{ZONE}.
-- 
-- Note that @{#SPAWN.Spawn} and @{#SPAWN.ReSpawn} return a @{GROUP#GROUP.New} object, that contains a reference to the DCSGroup object. 
-- You can use the @{GROUP} object to do further actions with the DCSGroup.
--  
-- SPAWN object cleaning:
-- =========================
-- Sometimes, it will occur during a mission run-time, that ground or especially air objects get damaged, and will while being damged stop their activities, while remaining alive.
-- In such cases, the SPAWN object will just sit there and wait until that group gets destroyed, but most of the time it won't, 
-- and it may occur that no new groups are or can be spawned as limits are reached.
-- To prevent this, a @{#SPAWN.CleanUp} initialization method has been defined that will silently monitor the status of each spawned group.
-- Once a group has a velocity = 0, and has been waiting for a defined interval, that group will be cleaned or removed from run-time. 
-- There is a catch however :-) If a damaged group has returned to an airbase within the coalition, that group will not be considered as "lost"... 
-- In such a case, when the inactive group is cleaned, a new group will Re-spawned automatically. 
-- This models AI that has succesfully returned to their airbase, to restart their combat activities.
-- Check the @{#SPAWN.CleanUp} for further info.
-- 
-- ====
-- @module Spawn
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )
Include.File( "Zone" )
Include.File( "Event" )

--- SPAWN Class
-- @type SPAWN
-- @extends Base#BASE
-- @field ClassName
-- @field #string SpawnTemplatePrefix
-- @field #string SpawnAliasPrefix
SPAWN = {
  ClassName = "SPAWN",
  SpawnTemplatePrefix = nil,
  SpawnAliasPrefix = nil,
}



--- Creates the main object to spawn a GROUP defined in the DCS ME.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template.  Each new group will have the name starting with SpawnTemplatePrefix.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
-- @usage local Plane = SPAWN:New( "Plane" ) -- Creates a new local variable that can initiate new planes with the name "Plane#ddd" using the template "Plane" as defined within the ME.
function SPAWN:New( SpawnTemplatePrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { SpawnTemplatePrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.Repeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxUnitsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end

	return self
end

--- Creates a new SPAWN instance to create new groups based on the defined template and using a new alias for each new group.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template.
-- @param #string SpawnAliasPrefix is the name that will be given to the Group at runtime.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:NewWithAlias( 'BE KA-50@RAMP-Ground Defense', 'Helicopter Attacking a City' )
-- @usage local PlaneWithAlias = SPAWN:NewWithAlias( "Plane", "Bomber" ) -- Creates a new local variable that can instantiate new planes with the name "Bomber#ddd" using the template "Plane" as defined within the ME.
function SPAWN:NewWithAlias( SpawnTemplatePrefix, SpawnAliasPrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { SpawnTemplatePrefix, SpawnAliasPrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnAliasPrefix = SpawnAliasPrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.Repeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxUnitsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	return self
end


--- Limits the Maximum amount of Units that can be alive at the same time, and the maximum amount of groups that can be spawned.
-- Note that this method is exceptionally important to balance the performance of the mission. Depending on the machine etc, a mission can only process a maximum amount of units.
-- If the time interval must be short, but there should not be more Units or Groups alive than a maximum amount of units, then this function should be used...
-- When a @{#SPAWN.New} is executed and the limit of the amount of units alive is reached, then no new spawn will happen of the group, until some of these units of the spawn object will be destroyed.
-- @param #SPAWN self
-- @param #number SpawnMaxUnitsAlive The maximum amount of units that can be alive at runtime.    
-- @param #number SpawnMaxGroups The maximum amount of groups that can be spawned. When the limit is reached, then no more actual spawns will happen of the group. 
-- This parameter is useful to define a maximum amount of airplanes, ground troops, helicopters, ships etc within a supply area. 
-- This parameter accepts the value 0, which defines that there are no maximum group limits, but there are limits on the maximum of units that can be alive at the same time.
-- @return #SPAWN self
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- This helicopter group consists of one Unit. So, this group will SPAWN maximum 2 groups simultaneously within the DCSRTE.
-- -- There will be maximum 24 groups spawned during the whole mission lifetime. 
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Limit( 2, 24 )
function SPAWN:Limit( SpawnMaxUnitsAlive, SpawnMaxGroups )
	self:F( { self.SpawnTemplatePrefix, SpawnMaxUnitsAlive, SpawnMaxGroups } )

	self.SpawnMaxUnitsAlive = SpawnMaxUnitsAlive				-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
	self.SpawnMaxGroups = SpawnMaxGroups						-- The maximum amount of groups that can be spawned.
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_InitializeSpawnGroups( SpawnGroupID )
	end

	return self
end


--- Randomizes the defined route of the SpawnTemplatePrefix group in the ME. This is very useful to define extra variation of the behaviour of groups.
-- @param #SPAWN self
-- @param #number SpawnStartPoint is the waypoint where the randomization begins. 
-- Note that the StartPoint = 0 equaling the point where the group is spawned.
-- @param #number SpawnEndPoint is the waypoint where the randomization ends counting backwards. 
-- This parameter is useful to avoid randomization to end at a waypoint earlier than the last waypoint on the route.
-- @param #number SpawnRadius is the radius in meters in which the randomization of the new waypoints, with the original waypoint of the original template located in the middle ...
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field. 
-- -- The KA-50 has waypoints Start point ( =0 or SP ), 1, 2, 3, 4, End point (= 5 or DP). 
-- -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new spawn of the helicopter.
-- -- The randomization of waypoint 2 and 3 will take place within a radius of 2000 meters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):RandomizeRoute( 2, 2, 2000 )
function SPAWN:RandomizeRoute( SpawnStartPoint, SpawnEndPoint, SpawnRadius )
	self:F( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius } )

	self.SpawnRandomizeRoute = true
	self.SpawnRandomizeRouteStartPoint = SpawnStartPoint
	self.SpawnRandomizeRouteEndPoint = SpawnEndPoint
	self.SpawnRandomizeRouteRadius = SpawnRadius

	for GroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeRoute( GroupID )
	end
	
	return self
end


--- This function is rather complicated to understand. But I'll try to explain.
-- This function becomes useful when you need to spawn groups with random templates of groups defined within the mission editor, 
-- but they will all follow the same Template route and have the same prefix name.
-- In other words, this method randomizes between a defined set of groups the template to be used for each new spawn of a group.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefixTable A table with the names of the groups defined within the mission editor, from which one will be choosen when a new group will be spawned. 
-- @return #SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- -- Choose between 13 different 'US Tank Platoon' configurations for each new SPAWN the Group to be spawned for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SpawnTemplatePrefixes.
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be spawned during the whole mission.
-- Spawn_US_Platoon = { 'US Tank Platoon 1', 'US Tank Platoon 2', 'US Tank Platoon 3', 'US Tank Platoon 4', 'US Tank Platoon 5', 
--                      'US Tank Platoon 6', 'US Tank Platoon 7', 'US Tank Platoon 8', 'US Tank Platoon 9', 'US Tank Platoon 10', 
--                      'US Tank Platoon 11', 'US Tank Platoon 12', 'US Tank Platoon 13' }
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
function SPAWN:RandomizeTemplate( SpawnTemplatePrefixTable )
	self:F( { self.SpawnTemplatePrefix, SpawnTemplatePrefixTable } )

	self.SpawnTemplatePrefixTable = SpawnTemplatePrefixTable
	self.SpawnRandomizeTemplate = true

	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeTemplate( SpawnGroupID )
	end
	
	return self
end





--- For planes and helicopters, when these groups go home and land on their home airbases and farps, they normally would taxi to the parking spot, shut-down their engines and wait forever until the Group is removed by the runtime environment.
-- This function is used to re-spawn automatically (so no extra call is needed anymore) the same group after it has landed. 
-- This will enable a spawned group to be re-spawned after it lands, until it is destroyed...
-- Note: When the group is respawned, it will re-spawn from the original airbase where it took off. 
-- So ensure that the routes for groups that respawn, always return to the original airbase, or players may get confused ...
-- @param #SPAWN self
-- @return #SPAWN self
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN:New( 'TF1 RU Su-34 Krymsk@AI - Attack Ships' ):Schedule( 2, 3, 1800, 0.4 ):SpawnUncontrolled():RandomizeRoute( 1, 1, 3000 ):RepeatOnEngineShutDown()
function SPAWN:InitRepeat()
	self:F( { self.SpawnTemplatePrefix, self.SpawnIndex } )

	self.Repeat = true
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true

	return self
end

--- Respawn group after landing.
-- @param #SPAWN self
-- @return #SPAWN self
function SPAWN:InitRepeatOnLanding()
	self:F( { self.SpawnTemplatePrefix } )

	self:InitRepeat()
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true
	
	return self
end


--- Respawn after landing when its engines have shut down.
-- @param #SPAWN self
-- @return #SPAWN self
function SPAWN:InitRepeatOnEngineShutDown()
	self:F( { self.SpawnTemplatePrefix } )

	self:InitRepeat()
	self.RepeatOnEngineShutDown = true
	self.RepeatOnLanding = false
	
	return self
end


--- CleanUp groups when they are still alive, but inactive.
-- When groups are still alive and have become inactive due to damage and are unable to contribute anything, then this group will be removed at defined intervals in seconds.
-- @param #SPAWN self
-- @param #string SpawnCleanUpInterval The interval to check for inactive groups within seconds.
-- @return #SPAWN self
-- @usage Spawn_Helicopter:CleanUp( 20 )  -- CleanUp the spawning of the helicopters every 20 seconds when they become inactive.
function SPAWN:CleanUp( SpawnCleanUpInterval )
	self:F( { self.SpawnTemplatePrefix, SpawnCleanUpInterval } )

	self.SpawnCleanUpInterval = SpawnCleanUpInterval
	self.SpawnCleanUpTimeStamps = {}
	self.CleanUpFunction = routines.scheduleFunction( self._SpawnCleanUpScheduler, { self }, timer.getTime() + 1, SpawnCleanUpInterval )
	
	return self
end



--- Makes the groups visible before start (like a batallion).
-- The method will take the position of the group as the first position in the array.
-- @param #SPAWN self
-- @param #number SpawnAngle         The angle in degrees how the groups and each unit of the group will be positioned.
-- @param #number SpawnWidth		     The amount of Groups that will be positioned on the X axis.
-- @param #number SpawnDeltaX        The space between each Group on the X-axis.
-- @param #number SpawnDeltaY		     The space between each Group on the Y-axis.
-- @return #SPAWN self
-- @usage
-- -- Define an array of Groups.
-- Spawn_BE_Ground = SPAWN:New( 'BE Ground' ):Limit( 2, 24 ):Visible( 90, "Diamond", 10, 100, 50 )
function SPAWN:Array( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY )
	self:F( { self.SpawnTemplatePrefix, SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY } )

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

    _EVENTDISPATCHER:OnBirthForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnBirth, self )
    _EVENTDISPATCHER:OnCrashForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnDeadOrCrash, self )
    _EVENTDISPATCHER:OnDeadForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnDeadOrCrash, self )

    if self.Repeat then
      _EVENTDISPATCHER:OnTakeOffForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnTakeOff, self )
      _EVENTDISPATCHER:OnLandForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnLand, self )
    end
    if self.RepeatOnEngineShutDown then
      _EVENTDISPATCHER:OnEngineShutDownForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnEngineShutDown, self )
    end
		
		self.SpawnGroups[SpawnGroupID].Group = _DATABASE:Spawn( self.SpawnGroups[SpawnGroupID].SpawnTemplate )

		SpawnX = SpawnXIndex * SpawnDeltaX
		SpawnY = SpawnYIndex * SpawnDeltaY
	end
	
	return self
end



--- Will spawn a group based on the internal index.
-- Note: Uses @{DATABASE} module defined in MOOSE.
-- @param #SPAWN self
-- @return Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:Spawn()
	self:F( { self.SpawnTemplatePrefix, self.SpawnIndex } )

	return self:SpawnWithIndex( self.SpawnIndex + 1 )
end

--- Will re-spawn a group based on a given index.
-- Note: Uses @{DATABASE} module defined in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group to be spawned.
-- @return Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:ReSpawn( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )
	
	if not SpawnIndex then
		SpawnIndex = 1
	end

-- TODO: This logic makes DCS crash and i don't know why (yet).
	local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
	if SpawnGroup then
    local SpawnDCSGroup = SpawnGroup:GetDCSGroup()
  	if SpawnDCSGroup then
      SpawnGroup:Destroy()
  	end
  end

	return self:SpawnWithIndex( SpawnIndex )
end

--- Will spawn a group with a specified index number.
-- Uses @{DATABASE} global object defined in MOOSE.
-- @param #SPAWN self
-- @return Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:SpawnWithIndex( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups } )
	
	if self:_GetSpawnIndex( SpawnIndex ) then
		
		if self.SpawnGroups[self.SpawnIndex].Visible then
			self.SpawnGroups[self.SpawnIndex].Group:Activate()
		else
			self:T( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
      _EVENTDISPATCHER:OnBirthForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnBirth, self )
      _EVENTDISPATCHER:OnCrashForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnDeadOrCrash, self )
      _EVENTDISPATCHER:OnDeadForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnDeadOrCrash, self )

      if self.Repeat then
        _EVENTDISPATCHER:OnTakeOffForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnTakeOff, self )
        _EVENTDISPATCHER:OnLandForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnLand, self )
      end
      if self.RepeatOnEngineShutDown then
        _EVENTDISPATCHER:OnEngineShutDownForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnEngineShutDown, self )
      end
      
      self:T( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )

			self.SpawnGroups[self.SpawnIndex].Group = _DATABASE:Spawn( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
			
			-- If there is a SpawnFunction hook defined, call it.
			if self.SpawnFunctionHook then
			  self.SpawnFunctionHook( self.SpawnGroups[self.SpawnIndex].Group, unpack( self.SpawnFunctionArguments ) )
			end
			-- TODO: Need to fix this by putting an "R" in the name of the group when the group repeats.
			--if self.Repeat then
			--	_DATABASE:SetStatusGroup( SpawnTemplate.name, "ReSpawn" )
			--end
		end
		
		self.SpawnGroups[self.SpawnIndex].Spawned = true
		return self.SpawnGroups[self.SpawnIndex].Group
	else
		--self:E( { self.SpawnTemplatePrefix, "No more Groups to Spawn:", SpawnIndex, self.SpawnMaxGroups } )
	end

	return nil
end

--- Spawns new groups at varying time intervals.
-- This is useful if you want to have continuity within your missions of certain (AI) groups to be present (alive) within your missions.
-- @param #SPAWN self
-- @param #number SpawnTime The time interval defined in seconds between each new spawn of new groups.
-- @param #number SpawnTimeVariation The variation to be applied on the defined time interval between each new spawn.
-- The variation is a number between 0 and 1, representing the %-tage of variation to be applied on the time interval.
-- @return #SPAWN self
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- The time interval is set to SPAWN new helicopters between each 600 seconds, with a time variation of 50%.
-- -- The time variation in this case will be between 450 seconds and 750 seconds. 
-- -- This is calculated as follows: 
-- --      Low limit:   600 * ( 1 - 0.5 / 2 ) = 450 
-- --      High limit:  600 * ( 1 + 0.5 / 2 ) = 750
-- -- Between these two values, a random amount of seconds will be choosen for each new spawn of the helicopters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Schedule( 600, 0.5 )
function SPAWN:SpawnScheduled( SpawnTime, SpawnTimeVariation )
	self:F( { SpawnTime, SpawnTimeVariation } )

	self.SpawnCurrentTimer = 0									-- The internal timer counter to trigger a scheduled spawning of SpawnTemplatePrefix.
	self.SpawnSetTimer = 0										-- The internal timer value when a scheduled spawning of SpawnTemplatePrefix occurs.
	self.AliveFactor = 1									--
	self.SpawnLowTimer = 0
	self.SpawnHighTimer = 0
		
	if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
		self.SpawnLowTimer = SpawnTime - SpawnTime / 2 * SpawnTimeVariation
		self.SpawnHighTimer = SpawnTime + SpawnTime / 2 * SpawnTimeVariation
		self:SpawnScheduleStart()
	end

	self:T( { self.SpawnLowTimer, self.SpawnHighTimer } )
	
	return self
end

--- Allows to place a CallFunction hook when a new group spawns.
-- The provided function will be called when a new group is spawned, including its given parameters.
-- The first parameter of the SpawnFunction is the @{Group#GROUP} that was spawned.
-- @param #SPAWN self
-- @param #function SpawnFunctionHook The function to be called when a group spawns.
-- @param SpawnFunctionArguments A random amount of arguments to be provided to the function when the group spawns.
-- @return #SPAWN
function SPAWN:SpawnFunction( SpawnFunctionHook, ... )
  self:F( SpawnFunction )

  self.SpawnFunctionHook = SpawnFunctionHook
  self.SpawnFunctionArguments = {}
  if arg then
    self.SpawnFunctionArguments = arg
  end  

  return self
end



--- Will start the spawning scheduler.
-- Note: This function is called automatically when @{#SPAWN.Scheduled} is called.
function SPAWN:SpawnScheduleStart()
	self:F( { self.SpawnTemplatePrefix } )

	--local ClientUnit = #AlivePlayerUnits()
	
	self.AliveFactor = 10 -- ( 10 - ClientUnit  ) / 10
	
	if self.SpawnIsScheduled == false then
		self.SpawnIsScheduled = true
		self.SpawnInit = true
		self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor / 10 , self.SpawnHighTimer * self.AliveFactor  / 10 )
		
		self.SpawnFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 1 )
	end
end

--- Will stop the scheduled spawning scheduler.
function SPAWN:SpawnScheduleStop()
	self:F( { self.SpawnTemplatePrefix } )
	
	self.SpawnIsScheduled = false
end

--- Will spawn a group from a hosting unit. This function is mostly advisable to be used if you want to simulate spawning from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Unit#UNIT HostUnit The air or ground unit dropping or unloading the group.
-- @param #number OuterRadius The outer radius in meters where the new group will be spawned.
-- @param #number InnerRadius The inner radius in meters where the new group will NOT be spawned.
-- @param #number SpawnIndex (Optional) The index which group to spawn within the given zone.
-- @return Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromUnit( HostUnit, OuterRadius, InnerRadius, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, HostUnit, OuterRadius, InnerRadius, SpawnIndex } )

  if HostUnit and HostUnit:IsAlive() then -- and HostUnit:getUnit(1):inAir() == false then

    if SpawnIndex then
    else
      SpawnIndex = self.SpawnIndex + 1
    end
    
    if self:_GetSpawnIndex( SpawnIndex ) then
      
      local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
    
      if SpawnTemplate then

        local UnitPoint = HostUnit:GetPointVec2()
        
        self:T( { "Current point of ", self.SpawnTemplatePrefix, UnitPoint } )
        
        --for PointID, Point in pairs( SpawnTemplate.route.points ) do
          --Point.x = UnitPoint.x
          --Point.y = UnitPoint.y
          --Point.alt = nil
          --Point.alt_type = nil
        --end
        
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
            local CirclePos = routines.getRandPointInCircle( UnitPoint, OuterRadius, InnerRadius )
            SpawnTemplate.units[UnitID].x = CirclePos.x
            SpawnTemplate.units[UnitID].y = CirclePos.y
          end
          self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        end
        
        local SpawnPos = routines.getRandPointInCircle( UnitPoint, OuterRadius, InnerRadius )
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

--- Will spawn a Group within a given @{Zone#ZONE}.
-- Once the group is spawned within the zone, it will continue on its route.
-- The first waypoint (where the group is spawned) is replaced with the zone coordinates.
-- @param #SPAWN self
-- @param Zone#ZONE Zone The zone where the group is to be spawned.
-- @param #number ZoneRandomize (Optional) Set to true if you want to randomize the starting point in the zone.
-- @param #number SpawnIndex (Optional) The index which group to spawn within the given zone.
-- @return Group#GROUP that was spawned.
-- @return #nil when nothing was spawned.
function SPAWN:SpawnInZone( Zone, ZoneRandomize, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, Zone, ZoneRandomize, SpawnIndex } )
  
  if Zone then
    
    if SpawnIndex then
    else
      SpawnIndex = self.SpawnIndex + 1
    end
    
    if self:_GetSpawnIndex( SpawnIndex ) then

      local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
      
      if SpawnTemplate then
    
        local ZonePoint 
        
        if ZoneRandomize == true then
          ZonePoint = Zone:GetRandomPointVec2()
        else
          ZonePoint = Zone:GetPointVec2()
        end

        SpawnTemplate.route.points[1].x = ZonePoint.x
        SpawnTemplate.route.points[1].y = ZonePoint.y
        
        -- Apply SpawnFormation
        for UnitID = 1, #SpawnTemplate.units do
          local ZonePointUnit = Zone:GetRandomPointVec2()
          SpawnTemplate.units[UnitID].x = ZonePointUnit.x
          SpawnTemplate.units[UnitID].y = ZonePointUnit.y
          self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        end
       
        return self:SpawnWithIndex( self.SpawnIndex )
      end
    end
  end
  
  return nil
end




--- Will spawn a plane group in uncontrolled mode... 
-- This will be similar to the uncontrolled flag setting in the ME.
-- @return #SPAWN self
function SPAWN:UnControlled()
	self:F( { self.SpawnTemplatePrefix } )
	
	self.SpawnUnControlled = true
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self.SpawnGroups[SpawnGroupID].UnControlled = true
	end
	
	return self
end



--- Will return the SpawnGroupName either with with a specific count number or without any count.
-- @param #SPAWN self
-- @param #number SpawnIndex Is the number of the Group that is to be spawned.
-- @return #string SpawnGroupName
function SPAWN:SpawnGroupName( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

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

--- Find the first alive group.
-- @param #SPAWN self
-- @param #number SpawnCursor A number holding the index from where to find the first group from.
-- @return Group#GROUP, #number The group found, the new index where the group was found.
-- @return #nil, #nil When no group is found, #nil is returned.
function SPAWN:GetFirstAliveGroup( SpawnCursor )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

  for SpawnIndex = 1, self.SpawnCount do
    local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
    if SpawnGroup and SpawnGroup:IsAlive() then
      SpawnCursor = SpawnIndex
      return SpawnGroup, SpawnCursor
    end
  end
  
  return nil, nil
end


--- Find the next alive group.
-- @param #SPAWN self
-- @param #number SpawnCursor A number holding the last found previous index.
-- @return Group#GROUP, #number The group found, the new index where the group was found.
-- @return #nil, #nil When no group is found, #nil is returned.
function SPAWN:GetNextAliveGroup( SpawnCursor )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

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

--- Find the last alive group during runtime.
function SPAWN:GetLastAliveGroup()
	self:F( { self.SpawnTemplatePrefixself.SpawnAliasPrefix } )

  self.SpawnIndex = self:_GetLastIndex()
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



--- Get the group from an index.
-- Returns the group from the SpawnGroups list.
-- If no index is given, it will return the first group in the list.
-- @param #SPAWN self
-- @param #number SpawnIndex The index of the group to return.
-- @return Group#GROUP
function SPAWN:GetGroupFromIndex( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )
	
	if not SpawnIndex then
    SpawnIndex = 1
	end
	
	if self.SpawnGroups and self.SpawnGroups[SpawnIndex] then
		local SpawnGroup = self.SpawnGroups[SpawnIndex].Group
		return SpawnGroup
	else
    return nil
	end
end

--- Get the group index from a DCSUnit.
-- The method will search for a #-mark, and will return the index behind the #-mark of the DCSUnit.
-- It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param DCSUnit The DCS unit to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetGroupIndexFromDCSUnit( DCSUnit )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

	if DCSUnit and DCSUnit:getName() then
		local IndexString = string.match( DCSUnit:getName(), "#.*-" ):sub( 2, -2 )
		self:T( IndexString )
		
		if IndexString then
			local Index = tonumber( IndexString )
			self:T( { "Index:", IndexString, Index } )
			return Index
		end
	end
	
	return nil
end

--- Return the prefix of a DCSUnit.
-- The method will search for a #-mark, and will return the text before the #-mark.
-- It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param DCSUnit The DCS unit to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetPrefixFromDCSUnit( DCSUnit )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

	if DCSUnit and DCSUnit:getName() then
		local SpawnPrefix = string.match( DCSUnit:getName(), ".*#" )
		if SpawnPrefix then
			SpawnPrefix = SpawnPrefix:sub( 1, -2 )
		end
		self:T( SpawnPrefix )
		return SpawnPrefix
	end
	
	return nil
end

--- Return the group within the SpawnGroups collection with input a DCSUnit.
function SPAWN:_GetGroupFromDCSUnit( DCSUnit )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )
	
	if DCSUnit then
		local SpawnPrefix = self:_GetPrefixFromDCSUnit( DCSUnit )
		
		if self.SpawnTemplatePrefix == SpawnPrefix or ( self.SpawnAliasPrefix and self.SpawnAliasPrefix == SpawnPrefix ) then
			local SpawnGroupIndex = self:_GetGroupIndexFromDCSUnit( DCSUnit )
			local SpawnGroup = self.SpawnGroups[SpawnGroupIndex].Group
			self:T( SpawnGroup )
			return SpawnGroup
		end
	end

	return nil
end


--- Get the index from a given group.
-- The function will search the name of the group for a #, and will return the number behind the #-mark.
function SPAWN:GetSpawnIndexFromGroup( SpawnGroup )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )
	
	local IndexString = string.match( SpawnGroup:GetName(), "#.*$" ):sub( 2 )
	local Index = tonumber( IndexString )
	
	self:T( IndexString, Index )
	return Index
	
end

--- Return the last maximum index that can be used.
function SPAWN:_GetLastIndex()
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

	return self.SpawnMaxGroups
end

--- Initalize the SpawnGroups collection.
function SPAWN:_InitializeSpawnGroups( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )

	if not self.SpawnGroups[SpawnIndex] then
		self.SpawnGroups[SpawnIndex] = {}
		self.SpawnGroups[SpawnIndex].Visible = false
		self.SpawnGroups[SpawnIndex].Spawned = false
		self.SpawnGroups[SpawnIndex].UnControlled = false
		self.SpawnGroups[SpawnIndex].SpawnTime = 0
		
		self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefix
		self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
	end
	
	self:_RandomizeTemplate( SpawnIndex )
	self:_RandomizeRoute( SpawnIndex )
	--self:_TranslateRotate( SpawnIndex )
	
	return self.SpawnGroups[SpawnIndex]
end



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
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnPrefix } )
	
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		local TemplateUnits = TemplateGroup:getUnits()
		return TemplateUnits[1]:getCountry()
	else
		return nil
	end
end

--- Gets the Group Template from the ME environment definition.
-- This method used the @{DATABASE} object, which contains ALL initial and new spawned object in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix
-- @return @SPAWN self
function SPAWN:_GetTemplate( SpawnTemplatePrefix )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnTemplatePrefix } )

	local SpawnTemplate = nil

	SpawnTemplate = routines.utils.deepCopy( _DATABASE.Groups[SpawnTemplatePrefix].Template )
	
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
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_Prepare( SpawnTemplatePrefix, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )
	
	local SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
	SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
	
	SpawnTemplate.groupId = nil
	SpawnTemplate.lateActivation = false

	if SpawnTemplate.SpawnCategoryID == Group.Category.GROUND then
	  self:T( "For ground units, visible needs to be false..." )
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

--- Private method randomizing the routes.
-- @param #SPAWN self
-- @param #number SpawnIndex The index of the group to be spawned.
-- @return #SPAWN
function SPAWN:_RandomizeRoute( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeRoute, self.SpawnRandomizeRouteStartPoint, self.SpawnRandomizeRouteEndPoint, self.SpawnRandomizeRouteRadius } )

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

--- Private method that randomizes the template of the group.
-- @param #SPAWN self
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_RandomizeTemplate( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

  if self.SpawnRandomizeTemplate then
    self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefixTable[ math.random( 1, #self.SpawnTemplatePrefixTable ) ]
    self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.route = routines.utils.deepCopy( self.SpawnTemplate.route )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.x = self.SpawnTemplate.x
    self.SpawnGroups[SpawnIndex].SpawnTemplate.y = self.SpawnTemplate.y
    self.SpawnGroups[SpawnIndex].SpawnTemplate.start_time = self.SpawnTemplate.start_time
    for UnitID = 1, #self.SpawnGroups[SpawnIndex].SpawnTemplate.units do
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].heading = self.SpawnTemplate.units[1].heading
    end
  end
  
  self:_RandomizeRoute( SpawnIndex )
  
  return self
end

function SPAWN:_TranslateRotate( SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle } )
  
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
    self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading + math.rad( SpawnAngle )
  end
  
  return self
end

--- Get the next index of the groups to be spawned. This function is complicated, as it is used at several spaces.
function SPAWN:_GetSpawnIndex( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive, self.AliveUnits, #self.SpawnTemplate.units } )

  
  if ( self.SpawnMaxGroups == 0 ) or ( SpawnIndex <= self.SpawnMaxGroups ) then
    if ( self.SpawnMaxUnitsAlive == 0 ) or ( self.AliveUnits < self.SpawnMaxUnitsAlive * #self.SpawnTemplate.units ) or self.UnControlled then
      if SpawnIndex and SpawnIndex >= self.SpawnCount + 1 then
        self.SpawnCount = self.SpawnCount + 1
        SpawnIndex = self.SpawnCount
      end
      self.SpawnIndex = SpawnIndex
      if not self.SpawnGroups[self.SpawnIndex] then
        self:_InitializeSpawnGroups( self.SpawnIndex )
      end
    else
      return nil
    end
  else
    return nil
  end
  
  return self.SpawnIndex
end


-- TODO Need to delete this... _DATABASE does this now ...
function SPAWN:_OnBirth( event )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and event.initiator:getName() then
			local EventPrefix = self:_GetPrefixFromDCSUnit( event.initiator )
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
-- @todo Need to delete this... _DATABASE does this now ...
function SPAWN:_OnDeadOrCrash( event )
  self:F( self.SpawnTemplatePrefix,  event )

	if event.initiator and event.initiator:getName() then
		local EventPrefix = self:_GetPrefixFromDCSUnit( event.initiator )
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

--- Will detect AIR Units taking off... When the event takes place, the spawned Group is registered as airborne...
-- This is needed to ensure that Re-SPAWNing only is done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:_OnTakeOff( event )
  self:F( self.SpawnTemplatePrefix,  event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:_GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "TakeOff event: " .. event.initiator:getName(), event } )
			self:T( "self.Landed = false" )
			self.Landed = false
		end
	end
end

--- Will detect AIR Units landing... When the event takes place, the spawned Group is registered as landed.
-- This is needed to ensure that Re-SPAWNing is only done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:_OnLand( event )
  self:F( self.SpawnTemplatePrefix,  event )

  local SpawnUnit = event.initiator
	if SpawnUnit and SpawnUnit:isExist() and Object.getCategory(SpawnUnit) == Object.Category.UNIT then
		local SpawnGroup = self:_GetGroupFromDCSUnit( SpawnUnit )
		if SpawnGroup then
			self:T( { "Landed event:" .. SpawnUnit:getName(), event } )
			self.Landed = true
			self:T( "self.Landed = true" )
			if self.Landed and self.RepeatOnLanding then
				local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
				self:T( { "Landed:", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- Will detect AIR Units shutting down their engines ...
-- When the event takes place, and the method @{RepeatOnEngineShutDown} was called, the spawned Group will Re-SPAWN.
-- But only when the Unit was registered to have landed.
-- @param #SPAWN self
-- @see _OnTakeOff
-- @see _OnLand
-- @todo Need to test for AIR Groups only...
function SPAWN:_OnEngineShutDown( event )
  self:F( self.SpawnTemplatePrefix,  event )

  local SpawnUnit = event.initiator
  if SpawnUnit and SpawnUnit:isExist() and Object.getCategory(SpawnUnit) == Object.Category.UNIT then
		local SpawnGroup = self:_GetGroupFromDCSUnit( SpawnUnit )
		if SpawnGroup then
			self:T( { "EngineShutDown event: " .. SpawnUnit:getName(), event } )
			if self.Landed and self.RepeatOnEngineShutDown then
				local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
				self:T( { "EngineShutDown: ", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- This function is called automatically by the Spawning scheduler.
-- It is the internal worker method SPAWNing new Groups on the defined time intervals.
function SPAWN:_Scheduler()
	self:F( { "_Scheduler", self.SpawnTemplatePrefix, self.SpawnAliasPrefix, self.SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive } )
	
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
	self:F( { "CleanUp Scheduler:", self.SpawnTemplatePrefix } )

	local SpawnCursor
	local SpawnGroup, SpawnCursor = self:GetFirstAliveGroup( SpawnCursor )
	
	self:T( { "CleanUp Scheduler:", SpawnGroup } )

	while SpawnGroup do
		
		if SpawnGroup:AllOnGround() and SpawnGroup:GetMaxVelocity() < 1 then
			if not self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] then
				self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] = timer.getTime()
			else
				if self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] + self.SpawnCleanUpInterval < timer.getTime() then
					self:T( { "CleanUp Scheduler:", "Cleaning:", SpawnGroup } )
					SpawnGroup:Destroy()
				end
			end
		else
			self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] = nil
		end
		
		SpawnGroup, SpawnCursor = self:GetNextAliveGroup( SpawnCursor )
		
		self:T( { "CleanUp Scheduler:", SpawnGroup } )
		
	end
	
end
