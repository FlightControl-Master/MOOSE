--- Single-Player:**Yes** / Mulit-Player:**Yes** / AI:**Yes** / Human:**No** / Types:**All** --  
-- **Spawn groups of units dynamically in your missions.**
--  
-- ![Banner Image](..\Presentations\SPAWN\SPAWN.JPG)
-- 
-- ===
-- 
-- # 1) @{#SPAWN} class, extends @{Base#BASE}
-- 
-- The @{#SPAWN} class allows to spawn dynamically new groups, based on pre-defined initialization settings, modifying the behaviour when groups are spawned.
-- For each group to be spawned, within the mission editor, a group has to be created with the "late activation flag" set. We call this group the *"Spawn Template"* of the SPAWN object.
-- A reference to this Spawn Template needs to be provided when constructing the SPAWN object, by indicating the name of the group within the mission editor in the constructor methods.
-- 
-- Within the SPAWN object, there is an internal index that keeps track of which group from the internal group list was spawned. 
-- When new groups get spawned by using the SPAWN methods (see below), it will be validated whether the Limits (@{#SPAWN.Limit}) of the SPAWN object are not reached.
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
-- ## 1.1) SPAWN construction methods
-- 
-- Create a new SPAWN object with the @{#SPAWN.New}() or the @{#SPAWN.NewWithAlias}() methods:
-- 
--   * @{#SPAWN.New}(): Creates a new SPAWN object taking the name of the group that represents the GROUP Template (definition).
--   * @{#SPAWN.NewWithAlias}(): Creates a new SPAWN object taking the name of the group that represents the GROUP Template (definition), and gives each spawned @{Group} an different name.
--
-- It is important to understand how the SPAWN class works internally. The SPAWN object created will contain internally a list of groups that will be spawned and that are already spawned.
-- The initialization methods will modify this list of groups so that when a group gets spawned, ALL information is already prepared when spawning. This is done for performance reasons.
-- So in principle, the group list will contain all parameters and configurations after initialization, and when groups get actually spawned, this spawning can be done quickly and efficient.
--
-- ## 1.2) SPAWN initialization methods
-- 
-- A spawn object will behave differently based on the usage of **initialization** methods, which all start with the **Init** prefix:  
-- 
--   * @{#SPAWN.InitLimit}(): Limits the amount of groups that can be alive at the same time and that can be dynamically spawned.
--   * @{#SPAWN.InitRandomizeRoute}(): Randomize the routes of spawned groups, and for air groups also optionally the height.
--   * @{#SPAWN.InitRandomizeTemplate}(): Randomize the group templates so that when a new group is spawned, a random group template is selected from one of the templates defined. 
--   * @{#SPAWN.InitUnControlled}(): Spawn plane groups uncontrolled.
--   * @{#SPAWN.InitArray}(): Make groups visible before they are actually activated, and order these groups like a batallion in an array.
--   * @{#SPAWN.InitRepeat}(): Re-spawn groups when they land at the home base. Similar methods are @{#SPAWN.InitRepeatOnLanding} and @{#SPAWN.InitRepeatOnEngineShutDown}.
--   * @{#SPAWN.InitRandomizeUnits}(): Randomizes the @{Unit}s in the @{Group} that is spawned within a **radius band**, given an Outer and Inner radius.
--   * @{#SPAWN.InitRandomizeZones}(): Randomizes the spawning between a predefined list of @{Zone}s that are declared using this function. Each zone can be given a probability factor.
--   * @{#SPAWN.InitAIOn}(): Turns the AI On when spawning the new @{Group} object.
--   * @{#SPAWN.InitAIOff}(): Turns the AI Off when spawning the new @{Group} object.
--   * @{#SPAWN.InitAIOnOff}(): Turns the AI On or Off when spawning the new @{Group} object.
-- 
-- ## 1.3) SPAWN spawning methods
-- 
-- Groups can be spawned at different times and methods:
-- 
--   * @{#SPAWN.Spawn}(): Spawn one new group based on the last spawned index.
--   * @{#SPAWN.ReSpawn}(): Re-spawn a group based on a given index.
--   * @{#SPAWN.SpawnScheduled}(): Spawn groups at scheduled but randomized intervals. You can use @{#SPAWN.SpawnScheduleStart}() and @{#SPAWN.SpawnScheduleStop}() to start and stop the schedule respectively.
--   * @{#SPAWN.SpawnFromVec3}(): Spawn a new group from a Vec3 coordinate. (The group will can be spawned at a point in the air).
--   * @{#SPAWN.SpawnFromVec2}(): Spawn a new group from a Vec2 coordinate. (The group will be spawned at land height ).
--   * @{#SPAWN.SpawnFromStatic}(): Spawn a new group from a structure, taking the position of a @{Static}.
--   * @{#SPAWN.SpawnFromUnit}(): Spawn a new group taking the position of a @{Unit}.
--   * @{#SPAWN.SpawnInZone}(): Spawn a new group in a @{Zone}.
-- 
-- Note that @{#SPAWN.Spawn} and @{#SPAWN.ReSpawn} return a @{GROUP#GROUP.New} object, that contains a reference to the DCSGroup object. 
-- You can use the @{GROUP} object to do further actions with the DCSGroup.
--  
-- ## 1.4) Retrieve alive GROUPs spawned by the SPAWN object
-- 
-- The SPAWN class administers which GROUPS it has reserved (in stock) or has created during mission execution.
-- Every time a SPAWN object spawns a new GROUP object, a reference to the GROUP object is added to an internal table of GROUPS.
-- SPAWN provides methods to iterate through that internal GROUP object reference table:
-- 
--   * @{#SPAWN.GetFirstAliveGroup}(): Will find the first alive GROUP it has spawned, and return the alive GROUP object and the first Index where the first alive GROUP object has been found.
--   * @{#SPAWN.GetNextAliveGroup}(): Will find the next alive GROUP object from a given Index, and return a reference to the alive GROUP object and the next Index where the alive GROUP has been found.
--   * @{#SPAWN.GetLastAliveGroup}(): Will find the last alive GROUP object, and will return a reference to the last live GROUP object and the last Index where the last alive GROUP object has been found.
-- 
-- You can use the methods @{#SPAWN.GetFirstAliveGroup}() and sequently @{#SPAWN.GetNextAliveGroup}() to iterate through the alive GROUPS within the SPAWN object, and to actions... See the respective methods for an example.
-- The method @{#SPAWN.GetGroupFromIndex}() will return the GROUP object reference from the given Index, dead or alive...
-- 
-- ## 1.5) SPAWN object cleaning
-- 
-- Sometimes, it will occur during a mission run-time, that ground or especially air objects get damaged, and will while being damged stop their activities, while remaining alive.
-- In such cases, the SPAWN object will just sit there and wait until that group gets destroyed, but most of the time it won't, 
-- and it may occur that no new groups are or can be spawned as limits are reached.
-- To prevent this, a @{#SPAWN.InitCleanUp}() initialization method has been defined that will silently monitor the status of each spawned group.
-- Once a group has a velocity = 0, and has been waiting for a defined interval, that group will be cleaned or removed from run-time. 
-- There is a catch however :-) If a damaged group has returned to an airbase within the coalition, that group will not be considered as "lost"... 
-- In such a case, when the inactive group is cleaned, a new group will Re-spawned automatically. 
-- This models AI that has succesfully returned to their airbase, to restart their combat activities.
-- Check the @{#SPAWN.InitCleanUp}() for further info.
-- 
-- ## 1.6) Catch the @{Group} spawn event in a callback function!
-- 
-- When using the SpawnScheduled method, new @{Group}s are created following the schedule timing parameters.
-- When a new @{Group} is spawned, you maybe want to execute actions with that group spawned at the spawn event.
-- To SPAWN class supports this functionality through the @{#SPAWN.OnSpawnGroup}( **function( SpawnedGroup ) end ** ) method, which takes a function as a parameter that you can define locally. 
-- Whenever a new @{Group} is spawned, the given function is called, and the @{Group} that was just spawned, is given as a parameter.
-- As a result, your spawn event handling function requires one parameter to be declared, which will contain the spawned @{Group} object. 
-- A coding example is provided at the description of the @{#SPAWN.OnSpawnGroup}( **function( SpawnedGroup ) end ** ) method.
-- 
-- ====
-- 
-- # **API CHANGE HISTORY**
-- 
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
-- 
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
-- 
-- Hereby the change log:
-- 
-- 2017-02-04: SPAWN:InitUnControlled( **UnControlled** ) replaces SPAWN:InitUnControlled().
-- 
-- 2017-01-24: SPAWN:**InitAIOnOff( AIOnOff )** added.
-- 
-- 2017-01-24: SPAWN:**InitAIOn()** added.
-- 
-- 2017-01-24: SPAWN:**InitAIOff()** added.
-- 
-- 2016-08-15: SPAWN:**InitCleanUp**( SpawnCleanUpInterval ) replaces SPAWN:_CleanUp_( SpawnCleanUpInterval ).
-- 
-- 2016-08-15: SPAWN:**InitRandomizeZones( SpawnZones )** added.
-- 
-- 2016-08-14: SPAWN:**OnSpawnGroup**( SpawnCallBackFunction, ... ) replaces SPAWN:_SpawnFunction_( SpawnCallBackFunction, ... ).
-- 
-- 2016-08-14: SPAWN.SpawnInZone( Zone, __RandomizeGroup__, SpawnIndex ) replaces SpawnInZone( Zone, _RandomizeUnits, OuterRadius, InnerRadius,_ SpawnIndex ).
-- 
-- 2016-08-14: SPAWN.SpawnFromVec3( Vec3, SpawnIndex ) replaces SpawnFromVec3( Vec3, _RandomizeUnits, OuterRadius, InnerRadius,_ SpawnIndex ):
-- 
-- 2016-08-14: SPAWN.SpawnFromVec2( Vec2, SpawnIndex ) replaces SpawnFromVec2( Vec2, _RandomizeUnits, OuterRadius, InnerRadius,_ SpawnIndex ):
-- 
-- 2016-08-14: SPAWN.SpawnFromUnit( SpawnUnit, SpawnIndex ) replaces SpawnFromUnit( SpawnUnit, _RandomizeUnits, OuterRadius, InnerRadius,_ SpawnIndex ):
-- 
-- 2016-08-14: SPAWN.SpawnFromUnit( SpawnUnit, SpawnIndex ) replaces SpawnFromStatic( SpawnStatic, _RandomizeUnits, OuterRadius, InnerRadius,_ SpawnIndex ): 
-- 
-- 2016-08-14: SPAWN.**InitRandomizeUnits( RandomizeUnits, OuterRadius, InnerRadius )** added:
-- 
-- 2016-08-14: SPAWN.**Init**Limit( SpawnMaxUnitsAlive, SpawnMaxGroups ) replaces SPAWN._Limit_( SpawnMaxUnitsAlive, SpawnMaxGroups ):
-- 
-- 2016-08-14: SPAWN.**Init**Array( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY ) replaces SPAWN._Array_( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY ).
-- 
-- 2016-08-14: SPAWN.**Init**RandomizeRoute( SpawnStartPoint, SpawnEndPoint, SpawnRadius, SpawnHeight ) replaces SPAWN._RandomizeRoute_( SpawnStartPoint, SpawnEndPoint, SpawnRadius, SpawnHeight ).
-- 
-- 2016-08-14: SPAWN.**Init**RandomizeTemplate( SpawnTemplatePrefixTable ) replaces SPAWN._RandomizeTemplate_( SpawnTemplatePrefixTable ).
-- 
-- 2016-08-14: SPAWN.**Init**UnControlled() replaces SPAWN._UnControlled_().
-- 
-- ===
-- 
-- # **AUTHORS and CONTRIBUTIONS**
-- 
-- ### Contributions: 
-- 
--   * **Aaron**: Posed the idea for Group position randomization at SpawnInZone and make the Unit randomization separate from the Group randomization.
--   * [**Entropy**](https://forums.eagle.ru/member.php?u=111471), **Afinegan**: Came up with the requirement for AIOnOff().
-- 
-- ### Authors: 
-- 
--   * **FlightControl**: Design & Programming
-- 
-- @module Spawn



--- SPAWN Class
-- @type SPAWN
-- @extends Core.Base#BASE
-- @field ClassName
-- @field #string SpawnTemplatePrefix
-- @field #string SpawnAliasPrefix
-- @field #number AliveUnits
-- @field #number MaxAliveUnits
-- @field #number SpawnIndex
-- @field #number MaxAliveGroups
-- @field #SPAWN.SpawnZoneTable SpawnZoneTable
SPAWN = {
  ClassName = "SPAWN",
  SpawnTemplatePrefix = nil,
  SpawnAliasPrefix = nil,
}


--- @type SPAWN.SpawnZoneTable
-- @list <Core.Zone#ZONE_BASE> SpawnZone


--- Creates the main object to spawn a @{Group} defined in the DCS ME.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template.  Each new group will have the name starting with SpawnTemplatePrefix.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
-- @usage local Plane = SPAWN:New( "Plane" ) -- Creates a new local variable that can initiate new planes with the name "Plane#ddd" using the template "Plane" as defined within the ME.
function SPAWN:New( SpawnTemplatePrefix )
	local self = BASE:Inherit( self, BASE:New() ) -- #SPAWN
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
		self.AIOnOff = true                               -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false

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
    self.AIOnOff = true                               -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	return self
end


--- Limits the Maximum amount of Units that can be alive at the same time, and the maximum amount of groups that can be spawned.
-- Note that this method is exceptionally important to balance the performance of the mission. Depending on the machine etc, a mission can only process a maximum amount of units.
-- If the time interval must be short, but there should not be more Units or Groups alive than a maximum amount of units, then this method should be used...
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
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitLimit( 2, 24 )
function SPAWN:InitLimit( SpawnMaxUnitsAlive, SpawnMaxGroups )
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
-- @param #number SpawnHeight (optional) Specifies the **additional** height in meters that can be added to the base height specified at each waypoint in the ME.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field. 
-- -- The KA-50 has waypoints Start point ( =0 or SP ), 1, 2, 3, 4, End point (= 5 or DP). 
-- -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new spawn of the helicopter.
-- -- The randomization of waypoint 2 and 3 will take place within a radius of 2000 meters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitRandomizeRoute( 2, 2, 2000 )
function SPAWN:InitRandomizeRoute( SpawnStartPoint, SpawnEndPoint, SpawnRadius, SpawnHeight )
	self:F( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius, SpawnHeight } )

	self.SpawnRandomizeRoute = true
	self.SpawnRandomizeRouteStartPoint = SpawnStartPoint
	self.SpawnRandomizeRouteEndPoint = SpawnEndPoint
	self.SpawnRandomizeRouteRadius = SpawnRadius
	self.SpawnRandomizeRouteHeight = SpawnHeight

	for GroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeRoute( GroupID )
	end
	
	return self
end

--- Randomizes the UNITs that are spawned within a radius band given an Outer and Inner radius.
-- @param #SPAWN self
-- @param #boolean RandomizeUnits If true, SPAWN will perform the randomization of the @{UNIT}s position within the group between a given outer and inner radius. 
-- @param Dcs.DCSTypes#Distance OuterRadius (optional) The outer radius in meters where the new group will be spawned.
-- @param Dcs.DCSTypes#Distance InnerRadius (optional) The inner radius in meters where the new group will NOT be spawned.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field. 
-- -- The KA-50 has waypoints Start point ( =0 or SP ), 1, 2, 3, 4, End point (= 5 or DP). 
-- -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new spawn of the helicopter.
-- -- The randomization of waypoint 2 and 3 will take place within a radius of 2000 meters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitRandomizeRoute( 2, 2, 2000 )
function SPAWN:InitRandomizeUnits( RandomizeUnits, OuterRadius, InnerRadius )
  self:F( { self.SpawnTemplatePrefix, RandomizeUnits, OuterRadius, InnerRadius } )

  self.SpawnRandomizeUnits = RandomizeUnits or false
  self.SpawnOuterRadius = OuterRadius or 0
  self.SpawnInnerRadius = InnerRadius or 0

  for GroupID = 1, self.SpawnMaxGroups do
    self:_RandomizeRoute( GroupID )
  end
  
  return self
end

--- This method is rather complicated to understand. But I'll try to explain.
-- This method becomes useful when you need to spawn groups with random templates of groups defined within the mission editor, 
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
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplate( Spawn_US_Platoon ):InitRandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplate( Spawn_US_Platoon ):InitRandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplate( Spawn_US_Platoon ):InitRandomizeRoute( 3, 3, 2000 )
function SPAWN:InitRandomizeTemplate( SpawnTemplatePrefixTable )
	self:F( { self.SpawnTemplatePrefix, SpawnTemplatePrefixTable } )

	self.SpawnTemplatePrefixTable = SpawnTemplatePrefixTable
	self.SpawnRandomizeTemplate = true

	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeTemplate( SpawnGroupID )
	end
	
	return self
end

--TODO: Add example.
--- This method provides the functionality to randomize the spawning of the Groups at a given list of zones of different types.
-- @param #SPAWN self
-- @param #table SpawnZoneTable A table with @{Zone} objects. If this table is given, then each spawn will be executed within the given list of @{Zone}s objects. 
-- @return #SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- -- Choose between 3 different zones for each new SPAWN the Group to be executed, regardless of the zone type. 
function SPAWN:InitRandomizeZones( SpawnZoneTable )
  self:F( { self.SpawnTemplatePrefix, SpawnZoneTable } )

  self.SpawnZoneTable = SpawnZoneTable
  self.SpawnRandomizeZones = true

  for SpawnGroupID = 1, self.SpawnMaxGroups do
    self:_RandomizeZones( SpawnGroupID )
  end
  
  return self
end





--- For planes and helicopters, when these groups go home and land on their home airbases and farps, they normally would taxi to the parking spot, shut-down their engines and wait forever until the Group is removed by the runtime environment.
-- This method is used to re-spawn automatically (so no extra call is needed anymore) the same group after it has landed. 
-- This will enable a spawned group to be re-spawned after it lands, until it is destroyed...
-- Note: When the group is respawned, it will re-spawn from the original airbase where it took off. 
-- So ensure that the routes for groups that respawn, always return to the original airbase, or players may get confused ...
-- @param #SPAWN self
-- @return #SPAWN self
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN:New( 'TF1 RU Su-34 Krymsk@AI - Attack Ships' ):Schedule( 2, 3, 1800, 0.4 ):SpawnUncontrolled():InitRandomizeRoute( 1, 1, 3000 ):RepeatOnEngineShutDown()
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
function SPAWN:InitCleanUp( SpawnCleanUpInterval )
	self:F( { self.SpawnTemplatePrefix, SpawnCleanUpInterval } )

	self.SpawnCleanUpInterval = SpawnCleanUpInterval
	self.SpawnCleanUpTimeStamps = {}

  local SpawnGroup, SpawnCursor = self:GetFirstAliveGroup()
  self:T( { "CleanUp Scheduler:", SpawnGroup } )
	
	--self.CleanUpFunction = routines.scheduleFunction( self._SpawnCleanUpScheduler, { self }, timer.getTime() + 1, SpawnCleanUpInterval )
	self.CleanUpScheduler = SCHEDULER:New( self, self._SpawnCleanUpScheduler, {}, 1, SpawnCleanUpInterval, 0.2 )
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
-- Spawn_BE_Ground = SPAWN:New( 'BE Ground' ):InitLimit( 2, 24 ):InitArray( 90, "Diamond", 10, 100, 50 )
function SPAWN:InitArray( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY )
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

do -- AI methods
  --- Turns the AI On or Off for the @{Group} when spawning.
  -- @param #SPAWN self
  -- @param #boolean AIOnOff A value of true sets the AI On, a value of false sets the AI Off.
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitAIOnOff( AIOnOff )
  
    self.AIOnOff = AIOnOff
    return self
  end
  
  --- Turns the AI On for the @{Group} when spawning.
  -- @param #SPAWN self
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitAIOn()
  
    return self:InitAIOnOff( true )
  end
  
  --- Turns the AI Off for the @{Group} when spawning.
  -- @param #SPAWN self
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitAIOff()
  
    return self:InitAIOnOff( false )
  end

end -- AI methods

--- Will spawn a group based on the internal index.
-- Note: Uses @{DATABASE} module defined in MOOSE.
-- @param #SPAWN self
-- @return Wrapper.Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:Spawn()
	self:F( { self.SpawnTemplatePrefix, self.SpawnIndex, self.AliveUnits } )

	return self:SpawnWithIndex( self.SpawnIndex + 1 )
end

--- Will re-spawn a group based on a given index.
-- Note: Uses @{DATABASE} module defined in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group to be spawned.
-- @return Wrapper.Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:ReSpawn( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )
	
	if not SpawnIndex then
		SpawnIndex = 1
	end

-- TODO: This logic makes DCS crash and i don't know why (yet).
	local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
	local WayPoints = SpawnGroup and SpawnGroup.WayPoints or nil
	if SpawnGroup then
    local SpawnDCSGroup = SpawnGroup:GetDCSObject()
  	if SpawnDCSGroup then
      SpawnGroup:Destroy()
  	end
  end

	local SpawnGroup = self:SpawnWithIndex( SpawnIndex )
	if SpawnGroup and WayPoints then
	  -- If there were WayPoints set, then Re-Execute those WayPoints!
	  SpawnGroup:WayPointInitialize( WayPoints )
	  SpawnGroup:WayPointExecute( 1, 5 )
	end
	
	if SpawnGroup.ReSpawnFunction then
	  SpawnGroup:ReSpawnFunction()
	end
	
	return SpawnGroup
end

--- Will spawn a group with a specified index number.
-- Uses @{DATABASE} global object defined in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group to be spawned.
-- @return Wrapper.Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:SpawnWithIndex( SpawnIndex )
	self:F2( { SpawnTemplatePrefix = self.SpawnTemplatePrefix, SpawnIndex = SpawnIndex, AliveUnits = self.AliveUnits, SpawnMaxGroups = self.SpawnMaxGroups } )
	
	if self:_GetSpawnIndex( SpawnIndex ) then
		
		if self.SpawnGroups[self.SpawnIndex].Visible then
			self.SpawnGroups[self.SpawnIndex].Group:Activate()
		else

		  local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
		  self:T( SpawnTemplate.name )

      if SpawnTemplate then

        local PointVec3 = POINT_VEC3:New( SpawnTemplate.route.points[1].x, SpawnTemplate.route.points[1].alt, SpawnTemplate.route.points[1].y )
        self:T( { "Current point of ", self.SpawnTemplatePrefix, PointVec3 } )
        
        -- If RandomizeUnits, then Randomize the formation at the start point.
        if self.SpawnRandomizeUnits then
          for UnitID = 1, #SpawnTemplate.units do
            local RandomVec2 = PointVec3:GetRandomVec2InRadius( self.SpawnOuterRadius, self.SpawnInnerRadius )
            SpawnTemplate.units[UnitID].x = RandomVec2.x
            SpawnTemplate.units[UnitID].y = RandomVec2.y
            self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
          end
        end
        
        if SpawnTemplate.CategoryID == Group.Category.HELICOPTER or SpawnTemplate.CategoryID == Group.Category.AIRPLANE then
          if SpawnTemplate.route.points[1].type == "TakeOffParking" then
            SpawnTemplate.uncontrolled = self.SpawnUnControlled
          end
        end
      end
		  
      _EVENTDISPATCHER:OnBirthForTemplate( SpawnTemplate, self._OnBirth, self )
      _EVENTDISPATCHER:OnCrashForTemplate( SpawnTemplate, self._OnDeadOrCrash, self )
      _EVENTDISPATCHER:OnDeadForTemplate( SpawnTemplate, self._OnDeadOrCrash, self )

      if self.Repeat then
        _EVENTDISPATCHER:OnTakeOffForTemplate( SpawnTemplate, self._OnTakeOff, self )
        _EVENTDISPATCHER:OnLandForTemplate( SpawnTemplate, self._OnLand, self )
      end
      if self.RepeatOnEngineShutDown then
        _EVENTDISPATCHER:OnEngineShutDownForTemplate( SpawnTemplate, self._OnEngineShutDown, self )
      end
      self:T3( SpawnTemplate.name )

			self.SpawnGroups[self.SpawnIndex].Group = _DATABASE:Spawn( SpawnTemplate )
			
			local SpawnGroup = self.SpawnGroups[self.SpawnIndex].Group -- Wrapper.Group#GROUP
			
			--TODO: Need to check if this function doesn't need to be scheduled, as the group may not be immediately there!
      if SpawnGroup then
      
			  SpawnGroup:SetAIOnOff( self.AIOnOff )
			end
			
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

	if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
    self.SpawnScheduler = SCHEDULER:New( self, self._Scheduler, {}, 1, SpawnTime, SpawnTimeVariation )
	end

	return self
end

--- Will re-start the spawning scheduler.
-- Note: This method is only required to be called when the schedule was stopped.
function SPAWN:SpawnScheduleStart()
  self:F( { self.SpawnTemplatePrefix } )

  self.SpawnScheduler:Start()
end

--- Will stop the scheduled spawning scheduler.
function SPAWN:SpawnScheduleStop()
  self:F( { self.SpawnTemplatePrefix } )
  
  self.SpawnScheduler:Stop()
end


--- Allows to place a CallFunction hook when a new group spawns.
-- The provided method will be called when a new group is spawned, including its given parameters.
-- The first parameter of the SpawnFunction is the @{Group#GROUP} that was spawned.
-- @param #SPAWN self
-- @param #function SpawnCallBackFunction The function to be called when a group spawns.
-- @param SpawnFunctionArguments A random amount of arguments to be provided to the function when the group spawns.
-- @return #SPAWN
-- @usage
-- -- Declare SpawnObject and call a function when a new Group is spawned.
-- local SpawnObject = SPAWN
--   :New( "SpawnObject" )
--   :InitLimit( 2, 10 )
--   :OnSpawnGroup(
--     function( SpawnGroup )
--       SpawnGroup:E( "I am spawned" )
--     end 
--     )
--   :SpawnScheduled( 300, 0.3 )
function SPAWN:OnSpawnGroup( SpawnCallBackFunction, ... )
  self:F( "OnSpawnGroup" )

  self.SpawnFunctionHook = SpawnCallBackFunction
  self.SpawnFunctionArguments = {}
  if arg then
    self.SpawnFunctionArguments = arg
  end  

  return self
end


--- Will spawn a group from a Vec3 in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning units in the air, like helicopters or airplanes.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Dcs.DCSTypes#Vec3 Vec3 The Vec3 coordinates where to spawn the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromVec3( Vec3, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, Vec3, SpawnIndex } )

  local PointVec3 = POINT_VEC3:NewFromVec3( Vec3 )
  self:T2(PointVec3)

  if SpawnIndex then
  else
    SpawnIndex = self.SpawnIndex + 1
  end
  
  if self:_GetSpawnIndex( SpawnIndex ) then
    
    local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
  
    if SpawnTemplate then

      self:T( { "Current point of ", self.SpawnTemplatePrefix, Vec3 } )

      -- Translate the position of the Group Template to the Vec3.
      for UnitID = 1, #SpawnTemplate.units do
        self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        local UnitTemplate = SpawnTemplate.units[UnitID]
        local SX = UnitTemplate.x
        local SY = UnitTemplate.y 
        local BX = SpawnTemplate.route.points[1].x
        local BY = SpawnTemplate.route.points[1].y
        local TX = Vec3.x + ( SX - BX )
        local TY = Vec3.z + ( SY - BY )
        SpawnTemplate.units[UnitID].x = TX
        SpawnTemplate.units[UnitID].y = TY
        SpawnTemplate.units[UnitID].alt = Vec3.y
        self:T( 'After Translation SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
      end
      
      SpawnTemplate.route.points[1].x = Vec3.x
      SpawnTemplate.route.points[1].y = Vec3.z
      SpawnTemplate.route.points[1].alt = Vec3.y
      
      SpawnTemplate.x = Vec3.x
      SpawnTemplate.y = Vec3.z
              
      return self:SpawnWithIndex( self.SpawnIndex )
    end
  end
  
  return nil
end

--- Will spawn a group from a Vec2 in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning groups on the ground from air units, like vehicles.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Dcs.DCSTypes#Vec2 Vec2 The Vec2 coordinates where to spawn the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromVec2( Vec2, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, Vec2, SpawnIndex } )

  local PointVec2 = POINT_VEC2:NewFromVec2( Vec2 )
  return self:SpawnFromVec3( PointVec2:GetVec3(), SpawnIndex )
end


--- Will spawn a group from a hosting unit. This method is mostly advisable to be used if you want to simulate spawning from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Wrapper.Unit#UNIT HostUnit The air or ground unit dropping or unloading the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromUnit( HostUnit, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, HostUnit, SpawnIndex } )

  if HostUnit and HostUnit:IsAlive() then -- and HostUnit:getUnit(1):inAir() == false then
    return self:SpawnFromVec3( HostUnit:GetVec3(), SpawnIndex )
  end
  
  return nil
end

--- Will spawn a group from a hosting static. This method is mostly advisable to be used if you want to simulate spawning from buldings and structures (static buildings).
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Wrapper.Static#STATIC HostStatic The static dropping or unloading the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromStatic( HostStatic, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, HostStatic, SpawnIndex } )

  if HostStatic and HostStatic:IsAlive() then
    return self:SpawnFromVec3( HostStatic:GetVec3(), SpawnIndex )
  end
  
  return nil
end

--- Will spawn a Group within a given @{Zone}.
-- The @{Zone} can be of any type derived from @{Zone#ZONE_BASE}.
-- Once the @{Group} is spawned within the zone, the @{Group} will continue on its route.
-- The **first waypoint** (where the group is spawned) is replaced with the zone location coordinates.
-- @param #SPAWN self
-- @param Core.Zone#ZONE Zone The zone where the group is to be spawned.
-- @param #boolean RandomizeGroup (optional) Randomization of the @{Group} position in the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil when nothing was spawned.
function SPAWN:SpawnInZone( Zone, RandomizeGroup, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, Zone, RandomizeGroup, SpawnIndex } )
  
  if Zone then
    if RandomizeGroup then
      return self:SpawnFromVec2( Zone:GetRandomVec2(), SpawnIndex )
    else
      return self:SpawnFromVec2( Zone:GetVec2(), SpawnIndex )
    end
  end
  
  return nil
end

--- (**AIR**) Will spawn a plane group in UnControlled or Controlled mode... 
-- This will be similar to the uncontrolled flag setting in the ME.
-- You can use UnControlled mode to simulate planes startup and ready for take-off but aren't moving (yet).
-- ReSpawn the plane in Controlled mode, and the plane will move...
-- @param #SPAWN self
-- @param #boolean UnControlled true if UnControlled, false if Controlled.
-- @return #SPAWN self
function SPAWN:InitUnControlled( UnControlled )
	self:F2( { self.SpawnTemplatePrefix, UnControlled } )
	
	self.SpawnUnControlled = UnControlled
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self.SpawnGroups[SpawnGroupID].UnControlled = UnControlled
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

--- Will find the first alive @{Group} it has spawned, and return the alive @{Group} object and the first Index where the first alive @{Group} object has been found.
-- @param #SPAWN self
-- @return Wrapper.Group#GROUP, #number The @{Group} object found, the new Index where the group was found.
-- @return #nil, #nil When no group is found, #nil is returned.
-- @usage
-- -- Find the first alive @{Group} object of the SpawnPlanes SPAWN object @{Group} collection that it has spawned during the mission.
-- local GroupPlane, Index = SpawnPlanes:GetFirstAliveGroup()
-- while GroupPlane ~= nil do
--   -- Do actions with the GroupPlane object.
--   GroupPlane, Index = SpawnPlanes:GetNextAliveGroup( Index )
-- end
function SPAWN:GetFirstAliveGroup()
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

  for SpawnIndex = 1, self.SpawnCount do
    local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
    if SpawnGroup and SpawnGroup:IsAlive() then
      return SpawnGroup, SpawnIndex
    end
  end
  
  return nil, nil
end


--- Will find the next alive @{Group} object from a given Index, and return a reference to the alive @{Group} object and the next Index where the alive @{Group} has been found.
-- @param #SPAWN self
-- @param #number SpawnIndexStart A Index holding the start position to search from. This method can also be used to find the first alive @{Group} object from the given Index.
-- @return Wrapper.Group#GROUP, #number The next alive @{Group} object found, the next Index where the next alive @{Group} object was found.
-- @return #nil, #nil When no alive @{Group} object is found from the start Index position, #nil is returned.
-- @usage
-- -- Find the first alive @{Group} object of the SpawnPlanes SPAWN object @{Group} collection that it has spawned during the mission.
-- local GroupPlane, Index = SpawnPlanes:GetFirstAliveGroup()
-- while GroupPlane ~= nil do
--   -- Do actions with the GroupPlane object.
--   GroupPlane, Index = SpawnPlanes:GetNextAliveGroup( Index )
-- end
function SPAWN:GetNextAliveGroup( SpawnIndexStart )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndexStart } )

  SpawnIndexStart = SpawnIndexStart + 1
  for SpawnIndex = SpawnIndexStart, self.SpawnCount do
    local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
    if SpawnGroup and SpawnGroup:IsAlive() then
      return SpawnGroup, SpawnIndex
    end
  end
  
  return nil, nil
end

--- Will find the last alive @{Group} object, and will return a reference to the last live @{Group} object and the last Index where the last alive @{Group} object has been found.
-- @param #SPAWN self
-- @return Wrapper.Group#GROUP, #number The last alive @{Group} object found, the last Index where the last alive @{Group} object was found.
-- @return #nil, #nil When no alive @{Group} object is found, #nil is returned.
-- @usage
-- -- Find the last alive @{Group} object of the SpawnPlanes SPAWN object @{Group} collection that it has spawned during the mission.
-- local GroupPlane, Index = SpawnPlanes:GetLastAliveGroup()
-- if GroupPlane then -- GroupPlane can be nil!!!
--   -- Do actions with the GroupPlane object.
-- end
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
-- @return Wrapper.Group#GROUP self
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
-- @param Dcs.DCSWrapper.Unit#Unit DCSUnit The @{DCSUnit} to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetGroupIndexFromDCSUnit( DCSUnit )
	self:F3( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

  local SpawnUnitName = ( DCSUnit and DCSUnit:getName() ) or nil
	if SpawnUnitName then
		local IndexString = string.match( SpawnUnitName, "#.*-" ):sub( 2, -2 )
		if IndexString then
			local Index = tonumber( IndexString )
			return Index
		end
	end
	
	return nil
end

--- Return the prefix of a SpawnUnit.
-- The method will search for a #-mark, and will return the text before the #-mark.
-- It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param Dcs.DCSWrapper.Unit#UNIT DCSUnit The @{DCSUnit} to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetPrefixFromDCSUnit( DCSUnit )
	self:F3( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

  local DCSUnitName = ( DCSUnit and DCSUnit:getName() ) or nil
	if DCSUnitName then
		local SpawnPrefix = string.match( DCSUnitName, ".*#" )
		if SpawnPrefix then
			SpawnPrefix = SpawnPrefix:sub( 1, -2 )
		end
		return SpawnPrefix
	end
	
	return nil
end

--- Return the group within the SpawnGroups collection with input a DCSUnit.
-- @param #SPAWN self
-- @param Dcs.DCSWrapper.Unit#Unit DCSUnit The @{DCSUnit} to be searched.
-- @return Wrapper.Group#GROUP The Group
-- @return #nil Nothing found
function SPAWN:_GetGroupFromDCSUnit( DCSUnit )
	self:F3( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )
	
	local SpawnPrefix = self:_GetPrefixFromDCSUnit( DCSUnit )
	
	if self.SpawnTemplatePrefix == SpawnPrefix or ( self.SpawnAliasPrefix and self.SpawnAliasPrefix == SpawnPrefix ) then
		local SpawnGroupIndex = self:_GetGroupIndexFromDCSUnit( DCSUnit )
		local SpawnGroup = self.SpawnGroups[SpawnGroupIndex].Group
		self:T( SpawnGroup )
		return SpawnGroup
	end

	return nil
end


--- Get the index from a given group.
-- The function will search the name of the group for a #, and will return the number behind the #-mark.
function SPAWN:GetSpawnIndexFromGroup( SpawnGroup )
	self:F3( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )
	
	local IndexString = string.match( SpawnGroup:GetName(), "#.*$" ):sub( 2 )
	local Index = tonumber( IndexString )
	
	self:T3( IndexString, Index )
	return Index
	
end

--- Return the last maximum index that can be used.
function SPAWN:_GetLastIndex()
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

	return self.SpawnMaxGroups
end

--- Initalize the SpawnGroups collection.
function SPAWN:_InitializeSpawnGroups( SpawnIndex )
	self:F3( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )

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

	SpawnTemplate = routines.utils.deepCopy( _DATABASE.Templates.Groups[SpawnTemplatePrefix].Template )
	
	if SpawnTemplate == nil then
		error( 'No Template returned for SpawnTemplatePrefix = ' .. SpawnTemplatePrefix )
	end

	--SpawnTemplate.SpawnCoalitionID = self:_GetGroupCoalitionID( SpawnTemplatePrefix )
	--SpawnTemplate.SpawnCategoryID = self:_GetGroupCategoryID( SpawnTemplatePrefix )
	--SpawnTemplate.SpawnCountryID = self:_GetGroupCountryID( SpawnTemplatePrefix )
	
	self:T3( { SpawnTemplate } )
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
	--SpawnTemplate.lateActivation = false
  SpawnTemplate.lateActivation = false 

	if SpawnTemplate.CategoryID == Group.Category.GROUND then
	  self:T3( "For ground units, visible needs to be false..." )
		SpawnTemplate.visible = false 
	end
	

	for UnitID = 1, #SpawnTemplate.units do
		SpawnTemplate.units[UnitID].name = string.format( SpawnTemplate.name .. '-%02d', UnitID )
		SpawnTemplate.units[UnitID].unitId = nil
	end
	
	self:T3( { "Template:", SpawnTemplate } )
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
      
      -- Manage randomization of altitude for airborne units ...
      if SpawnTemplate.CategoryID == Group.Category.AIRPLANE or SpawnTemplate.CategoryID == Group.Category.HELICOPTER then
        if SpawnTemplate.route.points[t].alt and self.SpawnRandomizeRouteHeight then
          SpawnTemplate.route.points[t].alt = SpawnTemplate.route.points[t].alt + math.random( 1, self.SpawnRandomizeRouteHeight )
        end
      else
        SpawnTemplate.route.points[t].alt = nil
      end
      
      self:T( 'SpawnTemplate.route.points[' .. t .. '].x = ' .. SpawnTemplate.route.points[t].x .. ', SpawnTemplate.route.points[' .. t .. '].y = ' .. SpawnTemplate.route.points[t].y )
    end
  end
  
  self:_RandomizeZones( SpawnIndex )
  
  return self
end

--- Private method that randomizes the template of the group.
-- @param #SPAWN self
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_RandomizeTemplate( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeTemplate } )

  if self.SpawnRandomizeTemplate then
    self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefixTable[ math.random( 1, #self.SpawnTemplatePrefixTable ) ]
    self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.route = routines.utils.deepCopy( self.SpawnTemplate.route )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.x = self.SpawnTemplate.x
    self.SpawnGroups[SpawnIndex].SpawnTemplate.y = self.SpawnTemplate.y
    self.SpawnGroups[SpawnIndex].SpawnTemplate.start_time = self.SpawnTemplate.start_time
    local OldX = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[1].x
    local OldY = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[1].y
    for UnitID = 1, #self.SpawnGroups[SpawnIndex].SpawnTemplate.units do
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].heading = self.SpawnTemplate.units[1].heading
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].x = self.SpawnTemplate.units[1].x + ( self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].x - OldX ) 
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].y = self.SpawnTemplate.units[1].y + ( self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].y - OldY )
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].alt = self.SpawnTemplate.units[1].alt
    end
  end
  
  self:_RandomizeRoute( SpawnIndex )
  
  return self
end

--- Private method that randomizes the @{Zone}s where the Group will be spawned.
-- @param #SPAWN self
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_RandomizeZones( SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeZones } )

  if self.SpawnRandomizeZones then
    local SpawnZone = nil -- Core.Zone#ZONE_BASE
    while not SpawnZone do
      self:T( { SpawnZoneTableCount = #self.SpawnZoneTable, self.SpawnZoneTable } )
      local ZoneID = math.random( #self.SpawnZoneTable )
      self:T( ZoneID )
      SpawnZone = self.SpawnZoneTable[ ZoneID ]:GetZoneMaybe() 
    end
    
    self:T( "Preparing Spawn in Zone", SpawnZone:GetName() )
    
    local SpawnVec2 = SpawnZone:GetRandomVec2()
    
    self:T( { SpawnVec2 = SpawnVec2 } )
    
    local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate
    
    self:T( { Route = SpawnTemplate.route } )
    
    for UnitID = 1, #SpawnTemplate.units do
      local UnitTemplate = SpawnTemplate.units[UnitID]
      self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. UnitTemplate.y )
      local SX = UnitTemplate.x
      local SY = UnitTemplate.y 
      local BX = SpawnTemplate.route.points[1].x
      local BY = SpawnTemplate.route.points[1].y
      local TX = SpawnVec2.x + ( SX - BX )
      local TY = SpawnVec2.y + ( SY - BY )
      UnitTemplate.x = TX
      UnitTemplate.y = TY
      -- TODO: Manage altitude based on landheight...
      --SpawnTemplate.units[UnitID].alt = SpawnVec2:
      self:T( 'After Translation SpawnTemplate.units['..UnitID..'].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. UnitTemplate.y )
    end
    SpawnTemplate.x = SpawnVec2.x
    SpawnTemplate.y = SpawnVec2.y
    SpawnTemplate.route.points[1].x = SpawnVec2.x
    SpawnTemplate.route.points[1].y = SpawnVec2.y
  end
    
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

--- Get the next index of the groups to be spawned. This method is complicated, as it is used at several spaces.
function SPAWN:_GetSpawnIndex( SpawnIndex )
	self:F2( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive, self.AliveUnits, #self.SpawnTemplate.units } )
  
  if ( self.SpawnMaxGroups == 0 ) or ( SpawnIndex <= self.SpawnMaxGroups ) then
    if ( self.SpawnMaxUnitsAlive == 0 ) or ( self.AliveUnits + #self.SpawnTemplate.units <= self.SpawnMaxUnitsAlive ) or self.UnControlled == true then
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

--- @param #SPAWN self 
-- @param Core.Event#EVENTDATA Event
function SPAWN:_OnBirth( Event )

	if timer.getTime0() < timer.getAbsTime() then
		if Event.IniDCSUnit then
			local EventPrefix = self:_GetPrefixFromDCSUnit( Event.IniDCSUnit )
			self:T( { "Birth Event:", EventPrefix, self.SpawnTemplatePrefix } )
			if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
				self.AliveUnits = self.AliveUnits + 1
				self:T( "Alive Units: " .. self.AliveUnits )
			end
		end
	end

end

--- Obscolete
-- @todo Need to delete this... _DATABASE does this now ...

--- @param #SPAWN self 
-- @param Core.Event#EVENTDATA Event
function SPAWN:_OnDeadOrCrash( Event )
  self:F( self.SpawnTemplatePrefix,  Event )

	if Event.IniDCSUnit then
		local EventPrefix = self:_GetPrefixFromDCSUnit( Event.IniDCSUnit )
    self:T( { "Dead event: " .. EventPrefix, self.SpawnTemplatePrefix } )
		if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
			self.AliveUnits = self.AliveUnits - 1
			self:T( "Alive Units: " .. self.AliveUnits )
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
	self:F2( { "_Scheduler", self.SpawnTemplatePrefix, self.SpawnAliasPrefix, self.SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive } )
	
	-- Validate if there are still groups left in the batch...
	self:Spawn()
	
	return true
end

--- Schedules the CleanUp of Groups
-- @param #SPAWN self
-- @return #boolean True = Continue Scheduler
function SPAWN:_SpawnCleanUpScheduler()
	self:F( { "CleanUp Scheduler:", self.SpawnTemplatePrefix } )

	local SpawnGroup, SpawnCursor = self:GetFirstAliveGroup()
	self:T( { "CleanUp Scheduler:", SpawnGroup, SpawnCursor } )

	while SpawnGroup do

    local SpawnUnits = SpawnGroup:GetUnits()
	  
	  for UnitID, UnitData in pairs( SpawnUnits ) do
	    
	    local SpawnUnit = UnitData -- Wrapper.Unit#UNIT
	    local SpawnUnitName = SpawnUnit:GetName()
	    
	    
	    self.SpawnCleanUpTimeStamps[SpawnUnitName] = self.SpawnCleanUpTimeStamps[SpawnUnitName] or {}
	    local Stamp = self.SpawnCleanUpTimeStamps[SpawnUnitName]
      self:T( { SpawnUnitName, Stamp } )
	    
	    if Stamp.Vec2 then
    		if SpawnUnit:InAir() == false and SpawnUnit:GetVelocityKMH() < 1 then
    		  local NewVec2 = SpawnUnit:GetVec2()
    		  if Stamp.Vec2.x == NewVec2.x and Stamp.Vec2.y == NewVec2.y then
      		  -- If the plane is not moving, and is on the ground, assign it with a timestamp...
    				if Stamp.Time + self.SpawnCleanUpInterval < timer.getTime() then
    					self:T( { "CleanUp Scheduler:", "ReSpawning:", SpawnGroup:GetName() } )
    					self:ReSpawn( SpawnCursor )
              Stamp.Vec2 = nil
              Stamp.Time = nil
    				end
      		else
      		  Stamp.Time = timer.getTime()
            Stamp.Vec2 = SpawnUnit:GetVec2()
      		end
    		else
    		  Stamp.Vec2 = nil
    			Stamp.Time = nil
    		end
    	else
        if SpawnUnit:InAir() == false then
          Stamp.Vec2 = SpawnUnit:GetVec2()
          if SpawnUnit:GetVelocityKMH() < 1 then
            Stamp.Time = timer.getTime()
          end
        else
          Stamp.Time = nil
          Stamp.Vec2 = nil
        end
      end
    end
		
		SpawnGroup, SpawnCursor = self:GetNextAliveGroup( SpawnCursor )
		
		self:T( { "CleanUp Scheduler:", SpawnGroup, SpawnCursor } )
		
	end
	
	return true -- Repeat
	
end
