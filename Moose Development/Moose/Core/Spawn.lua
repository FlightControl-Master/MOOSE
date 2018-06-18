--- **Core** -- SPAWN class dynamically spawns new groups of units in your missions.
--  
-- ===
-- 
-- The documentation of the SPAWN class can be found further in this document.
-- 
-- ===
-- 
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/SPA%20-%20Spawning)
-- 
-- ===
-- 
-- ### [YouTube Playlist](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: A lot of people within this community!
-- 
-- ===
-- 
-- @module Core.Spawn
-- @image Core_Spawn.JPG


--- SPAWN Class
-- @type SPAWN
-- @field ClassName
-- @field #string SpawnTemplatePrefix
-- @field #string SpawnAliasPrefix
-- @field #number AliveUnits
-- @field #number MaxAliveUnits
-- @field #number SpawnIndex
-- @field #number MaxAliveGroups
-- @field #SPAWN.SpawnZoneTable SpawnZoneTable
-- @extends Core.Base#BASE


--- Allows to spawn dynamically new @{Core.Group}s.  
-- 
-- Each SPAWN object needs to be have related **template groups** setup in the Mission Editor (ME),
-- which is a normal group with the **Late Activation** flag set. 
-- This template group will never be activated in your mission.  
-- SPAWN uses that **template group** to reference to all the characteristics 
-- (air, ground, livery, unit composition, formation, skill level etc) of each new group to be spawned.  
-- 
-- Therefore, when creating a SPAWN object, the @{#SPAWN.New} and @{#SPAWN.NewWithAlias} require
-- **the name of the template group** to be given as a string to those constructor methods.  
--  
-- Initialization settings can be applied on the SPAWN object, 
-- which modify the behaviour or the way groups are spawned.
-- These initialization methods have the prefix **Init**.
-- There are also spawn methods with the prefix **Spawn** and will spawn new groups in various ways.
-- 
-- ### IMPORTANT! The methods with prefix **Init** must be used before any methods with prefix **Spawn** method are used, or unexpected results may appear!!!  
-- 
-- Because SPAWN can spawn multiple groups of a template group, 
-- SPAWN has an **internal index** that keeps track 
-- which was the latest group that was spawned.  
-- 
-- **Limits** can be set on how many groups can be spawn in each SPAWN object, 
-- using the method @{#SPAWN.InitLimit}. SPAWN has 2 kind of limits:
-- 
--   * The maximum amount of @{Wrapper.Unit}s that can be **alive** at the same time... 
--   * The maximum amount of @{Wrapper.Group}s that can be **spawned**... This is more of a **resource**-type of limit.
--   
-- When new groups get spawned using the **Spawn** methods, 
-- it will be evaluated whether any limits have been reached.
-- When no spawn limit is reached, a new group will be created by the spawning methods, 
-- and the internal index will be increased with 1.  
-- 
-- These limits ensure that your mission does not accidentally get flooded with spawned groups.  
-- Additionally, it also guarantees that independent of the group composition, 
-- at any time, the most optimal amount of groups are alive in your mission.
-- For example, if your template group has a group composition of 10 units, and you specify a limit of 100 units alive at the same time,
-- with unlimited resources = :InitLimit( 100, 0 ) and 10 groups are alive, but two groups have only one unit alive in the group,
-- then a sequent Spawn(Scheduled) will allow a new group to be spawned!!!
-- 
-- ### IMPORTANT!! If a limit has been reached, it is possible that a **Spawn** method returns **nil**, meaning, no @{Wrapper.Group} had been spawned!!!  
-- 
-- Spawned groups get **the same name** as the name of the template group.  
-- Spawned units in those groups keep _by default_ **the same name** as the name of the template group.  
-- However, because multiple groups and units are created from the template group, 
-- a suffix is added to each spawned group and unit.
-- 
-- Newly spawned groups will get the following naming structure at run-time:
-- 
--   1. Spawned groups will have the name _GroupName_#_nnn_, where _GroupName_ is the name of the **template group**, 
--   and _nnn_ is a **counter from 0 to 999**.
--   2. Spawned units will have the name _GroupName_#_nnn_-_uu_, 
--   where _uu_ is a **counter from 0 to 99** for each new spawned unit belonging to the group.
-- 
-- That being said, there is a way to keep the same unit names!  
-- The method @{#SPAWN.InitKeepUnitNames}() will keep the same unit names as defined within the template group, thus:
-- 
--   3. Spawned units will have the name _UnitName_#_nnn_-_uu_, 
--   where _UnitName_ is the **unit name as defined in the template group*, 
--   and _uu_ is a **counter from 0 to 99** for each new spawned unit belonging to the group.
-- 
-- Some **additional notes that need to be considered!!**:
-- 
--   * templates are actually groups defined within the mission editor, with the flag "Late Activation" set. 
--   As such, these groups are never used within the mission, but are used by the @{#SPAWN} module.
--   * It is important to defined BEFORE you spawn new groups, 
--   a proper initialization of the SPAWN instance is done with the options you want to use.
--   * When designing a mission, NEVER name groups using a "#" within the name of the group Spawn template(s), 
--   or the SPAWN module logic won't work anymore.
--   
-- ## SPAWN construction methods
-- 
-- Create a new SPAWN object with the @{#SPAWN.New}() or the @{#SPAWN.NewWithAlias}() methods:
-- 
--   * @{#SPAWN.New}(): Creates a new SPAWN object taking the name of the group that represents the GROUP template (definition).
--   * @{#SPAWN.NewWithAlias}(): Creates a new SPAWN object taking the name of the group that represents the GROUP template (definition), and gives each spawned @{Wrapper.Group} an different name.
--
-- It is important to understand how the SPAWN class works internally. The SPAWN object created will contain internally a list of groups that will be spawned and that are already spawned.
-- The initialization methods will modify this list of groups so that when a group gets spawned, ALL information is already prepared when spawning. This is done for performance reasons.
-- So in principle, the group list will contain all parameters and configurations after initialization, and when groups get actually spawned, this spawning can be done quickly and efficient.
--
-- ## SPAWN **Init**ialization methods
-- 
-- A spawn object will behave differently based on the usage of **initialization** methods, which all start with the **Init** prefix:  
-- 
-- ### Unit Names
-- 
--   * @{#SPAWN.InitKeepUnitNames}(): Keeps the unit names as defined within the mission editor, but note that anything after a # mark is ignored, and any spaces before and after the resulting name are removed. IMPORTANT! This method MUST be the first used after :New !!!
-- 
-- ### Route randomization
-- 
--   * @{#SPAWN.InitRandomizeRoute}(): Randomize the routes of spawned groups, and for air groups also optionally the height.
--   
-- ### Group composition randomization  
--   
--   * @{#SPAWN.InitRandomizeTemplate}(): Randomize the group templates so that when a new group is spawned, a random group template is selected from one of the templates defined. 
-- 
-- ### Uncontrolled
-- 
--   * @{#SPAWN.InitUnControlled}(): Spawn plane groups uncontrolled.
-- 
-- ### Array formation
--   
--   * @{#SPAWN.InitArray}(): Make groups visible before they are actually activated, and order these groups like a batallion in an array.
-- 
-- ### Position randomization
-- 
--   * @{#SPAWN.InitRandomizePosition}(): Randomizes the position of @{Wrapper.Group}s that are spawned within a **radius band**, given an Outer and Inner radius, from the point that the spawn happens.
--   * @{#SPAWN.InitRandomizeUnits}(): Randomizes the @{Wrapper.Unit}s in the @{Wrapper.Group} that is spawned within a **radius band**, given an Outer and Inner radius.
--   * @{#SPAWN.InitRandomizeZones}(): Randomizes the spawning between a predefined list of @{Zone}s that are declared using this function. Each zone can be given a probability factor.
--   
-- ### Enable / Disable AI when spawning a new @{Wrapper.Group}
--   
--   * @{#SPAWN.InitAIOn}(): Turns the AI On when spawning the new @{Wrapper.Group} object.
--   * @{#SPAWN.InitAIOff}(): Turns the AI Off when spawning the new @{Wrapper.Group} object.
--   * @{#SPAWN.InitAIOnOff}(): Turns the AI On or Off when spawning the new @{Wrapper.Group} object.
-- 
-- ### Limit scheduled spawning  
--   
--   * @{#SPAWN.InitLimit}(): Limits the amount of groups that can be alive at the same time and that can be dynamically spawned.
--   
-- ### Delay initial scheduled spawn
-- 
--   * @{#SPAWN.InitDelayOnOff}(): Turns the inital delay On/Off when scheduled spawning the first @{Wrapper.Group} object.
--   * @{#SPAWN.InitDelayOn}(): Turns the inital delay On when scheduled spawning the first @{Wrapper.Group} object.
--   * @{#SPAWN.InitDelayOff}(): Turns the inital delay Off when scheduled spawning the first @{Wrapper.Group} object.
-- 
-- ### Repeat spawned @{Wrapper.Group}s upon landing
-- 
--   * @{#SPAWN.InitRepeat}() or @{#SPAWN.InitRepeatOnLanding}(): This method is used to re-spawn automatically the same group after it has landed.
--   * @{#SPAWN.InitRepeatOnEngineShutDown}(): This method is used to re-spawn automatically the same group after it has landed and it shuts down the engines at the ramp.
-- 
-- 
-- ## SPAWN **Spawn** methods
-- 
-- Groups can be spawned at different times and methods:
-- 
-- ### **Single** spawning methods
-- 
--   * @{#SPAWN.Spawn}(): Spawn one new group based on the last spawned index.
--   * @{#SPAWN.ReSpawn}(): Re-spawn a group based on a given index.
--   * @{#SPAWN.SpawnFromVec3}(): Spawn a new group from a Vec3 coordinate. (The group will can be spawned at a point in the air).
--   * @{#SPAWN.SpawnFromVec2}(): Spawn a new group from a Vec2 coordinate. (The group will be spawned at land height ).
--   * @{#SPAWN.SpawnFromStatic}(): Spawn a new group from a structure, taking the position of a @{Static}.
--   * @{#SPAWN.SpawnFromUnit}(): Spawn a new group taking the position of a @{Wrapper.Unit}.
--   * @{#SPAWN.SpawnInZone}(): Spawn a new group in a @{Zone}.
--   * @{#SPAWN.SpawnAtAirbase}(): Spawn a new group at an @{Wrapper.Airbase}, which can be an airdrome, ship or helipad.
-- 
-- Note that @{#SPAWN.Spawn} and @{#SPAWN.ReSpawn} return a @{Wrapper.Group#GROUP.New} object, that contains a reference to the DCSGroup object. 
-- You can use the @{GROUP} object to do further actions with the DCSGroup.
-- 
-- ### **Scheduled** spawning methods
-- 
--   * @{#SPAWN.SpawnScheduled}(): Spawn groups at scheduled but randomized intervals. 
--   * @{#SPAWN.SpawnScheduledStart}(): Start or continue to spawn groups at scheduled time intervals. 
--   * @{#SPAWN.SpawnScheduledStop}(): Stop the spawning of groups at scheduled time intervals. 
-- 
-- 
--  
-- ## Retrieve alive GROUPs spawned by the SPAWN object
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
-- ## Spawned cleaning of inactive groups
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
-- ## Catch the @{Wrapper.Group} Spawn Event in a callback function!
-- 
-- When using the @{#SPAWN.SpawnScheduled)() method, new @{Wrapper.Group}s are created following the spawn time interval parameters.
-- When a new @{Wrapper.Group} is spawned, you maybe want to execute actions with that group spawned at the spawn event.
-- The SPAWN class supports this functionality through the method @{#SPAWN.OnSpawnGroup}( **function( SpawnedGroup ) end ** ), 
-- which takes a function as a parameter that you can define locally. 
-- Whenever a new @{Wrapper.Group} is spawned, the given function is called, and the @{Wrapper.Group} that was just spawned, is given as a parameter.
-- As a result, your spawn event handling function requires one parameter to be declared, which will contain the spawned @{Wrapper.Group} object. 
-- A coding example is provided at the description of the @{#SPAWN.OnSpawnGroup}( **function( SpawnedGroup ) end ** ) method.
-- 
-- ## Delay the initial spawning
-- 
-- When using the @{#SPAWN.SpawnScheduled)() method, the default behaviour of this method will be that it will spawn the initial (first) @{Wrapper.Group}
-- immediately when :SpawnScheduled() is initiated. The methods @{#SPAWN.InitDelayOnOff}() and @{#SPAWN.InitDelayOn}() can be used to
-- activate a delay before the first @{Wrapper.Group} is spawned. For completeness, a method @{#SPAWN.InitDelayOff}() is also available, that
-- can be used to switch off the initial delay. Because there is no delay by default, this method would only be used when a 
-- @{#SPAWN.SpawnScheduledStop}() ; @{#SPAWN.SpawnScheduledStart}() sequence would have been used.
-- 
-- 
-- @field #SPAWN SPAWN
-- 
SPAWN = {
  ClassName = "SPAWN",
  SpawnTemplatePrefix = nil,
  SpawnAliasPrefix = nil,
}


--- Enumerator for spawns at airbases
-- @type SPAWN.Takeoff
-- @extends Wrapper.Group#GROUP.Takeoff

--- @field #SPAWN.Takeoff Takeoff
SPAWN.Takeoff = {
  Air = 1,
  Runway = 2,
  Hot = 3,
  Cold = 4,
}

--- @type SPAWN.SpawnZoneTable
-- @list <Core.Zone#ZONE_BASE> SpawnZone


--- Creates the main object to spawn a @{Wrapper.Group} defined in the DCS ME.
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
  
	local TemplateGroup = GROUP:FindByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false										-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.Repeat = false													    -- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false												-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
    self.SpawnInitLimit = false                     -- By default, no InitLimit
		self.SpawnMaxUnitsAlive = 0											-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0													-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false											-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false												-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.
		self.AIOnOff = true                             -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false
    self.SpawnInitKeepUnitNames = false             -- Overwrite unit names by default with group name.
    self.DelayOnOff = false                         -- No intial delay when spawning the first group.
    self.Grouping = nil                             -- No grouping

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end

  self:SetEventPriority( 5 )
  self.SpawnHookScheduler = SCHEDULER:New( nil )

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
  
	local TemplateGroup = GROUP:FindByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnAliasPrefix = SpawnAliasPrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false										-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.Repeat = false													    -- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false												-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnInitLimit = false                     -- By default, no InitLimit
		self.SpawnMaxUnitsAlive = 0											-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0													-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false											-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false												-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.
    self.AIOnOff = true                             -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false
    self.SpawnInitKeepUnitNames = false             -- Overwrite unit names by default with group name.
    self.DelayOnOff = false                         -- No intial delay when spawning the first group.
    self.Grouping = nil

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
  self:SetEventPriority( 5 )
  self.SpawnHookScheduler = SCHEDULER:New( nil )
	
	return self
end


--- Creates a new SPAWN instance to create new groups based on the provided template.
-- @param #SPAWN self
-- @param #table SpawnTemplate is the Template of the Group. This must be a valid Group Template structure!
-- @param #string SpawnTemplatePrefix is the name of the Group that will be given at each spawn.
-- @param #string SpawnAliasPrefix (optional) is the name that will be given to the Group at runtime.
-- @return #SPAWN
-- @usage
-- -- Create a new SPAWN object based on a Group Template defined from scratch.
-- Spawn_BE_KA50 = SPAWN:NewWithAlias( 'BE KA-50@RAMP-Ground Defense', 'Helicopter Attacking a City' )
-- @usage 
-- -- Create a new CSAR_Spawn object based on a normal Group Template to spawn a soldier.
-- local CSAR_Spawn = SPAWN:NewWithFromTemplate( Template, "CSAR", "Pilot" )
function SPAWN:NewFromTemplate( SpawnTemplate, SpawnTemplatePrefix, SpawnAliasPrefix )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( { SpawnTemplate, SpawnTemplatePrefix, SpawnAliasPrefix } )
  
  if SpawnTemplate then
    self.SpawnTemplate = SpawnTemplate              -- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
    self.SpawnTemplatePrefix = SpawnTemplatePrefix
    self.SpawnAliasPrefix = SpawnAliasPrefix
    self.SpawnIndex = 0
    self.SpawnCount = 0                             -- The internal counter of the amount of spawning the has happened since SpawnStart.
    self.AliveUnits = 0                             -- Contains the counter how many units are currently alive
    self.SpawnIsScheduled = false                   -- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
    self.Repeat = false                             -- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
    self.UnControlled = false                       -- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
    self.SpawnInitLimit = false                     -- By default, no InitLimit.
    self.SpawnMaxUnitsAlive = 0                     -- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
    self.SpawnMaxGroups = 0                         -- The maximum amount of groups that can be spawned.
    self.SpawnRandomize = false                     -- Sets the randomization flag of new Spawned units to false.
    self.SpawnVisible = false                       -- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.
    self.AIOnOff = true                             -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false
    self.SpawnInitKeepUnitNames = false             -- Overwrite unit names by default with group name.
    self.DelayOnOff = false                         -- No intial delay when spawning the first group.
    self.Grouping = nil

    self.SpawnGroups = {}                           -- Array containing the descriptions of each Group to be Spawned.
  else
    error( "There is no template provided for SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
  end
  
  self:SetEventPriority( 5 )
  self.SpawnHookScheduler = SCHEDULER:New( nil )
  
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

  self.SpawnInitLimit = true
	self.SpawnMaxUnitsAlive = SpawnMaxUnitsAlive				-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
	self.SpawnMaxGroups = SpawnMaxGroups						-- The maximum amount of groups that can be spawned.
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_InitializeSpawnGroups( SpawnGroupID )
	end

	return self
end

--- Keeps the unit names as defined within the mission editor, 
-- but note that anything after a # mark is ignored, 
-- and any spaces before and after the resulting name are removed.
-- IMPORTANT! This method MUST be the first used after :New !!!
-- @param #SPAWN self
-- @param #boolean KeepUnitNames (optional) If true, the unit names are kept, false or not provided to make new unit names.
-- @return #SPAWN self
function SPAWN:InitKeepUnitNames( KeepUnitNames )
  self:F( )

  self.SpawnInitKeepUnitNames = KeepUnitNames or true
  
  return self
end


--- Flags that the spawned groups must be spawned late activated. 
-- @param #SPAWN self
-- @param #boolean LateActivated (optional) If true, the spawned groups are late activated.
-- @return #SPAWN self
function SPAWN:InitLateActivated( LateActivated )
  self:F( )

  self.LateActivated = LateActivated or true
  
  return self
end


--- Defines the Heading for the new spawned units. 
-- The heading can be given as one fixed degree, or can be randomized between minimum and maximum degrees.
-- @param #SPAWN self
-- @param #number HeadingMin The minimum or fixed heading in degrees.
-- @param #number HeadingMax (optional) The maximum heading in degrees. This there is no maximum heading, then the heading will be fixed for all units using minimum heading.
-- @return #SPAWN self
-- @usage
-- 
-- Spawn = SPAWN:New( ... )
-- 
-- -- Spawn the units pointing to 100 degrees.
-- Spawn:InitHeading( 100 )
-- 
-- -- Spawn the units pointing between 100 and 150 degrees.
-- Spawn:InitHeading( 100, 150 )
-- 
function SPAWN:InitHeading( HeadingMin, HeadingMax )
  self:F( )

  self.SpawnInitHeadingMin = HeadingMin
  self.SpawnInitHeadingMax = HeadingMax
  
  return self
end


function SPAWN:InitCoalition( Coalition )
  self:F( )

  self.SpawnInitCoalition = Coalition
  
  return self
end


function SPAWN:InitCountry( Country )
  self:F( )

  self.SpawnInitCountry = Country
  
  return self
end


function SPAWN:InitCategory( Category )
  self:F( )

  self.SpawnInitCategory = Category
  
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

--- Randomizes the position of @{Wrapper.Group}s that are spawned within a **radius band**, given an Outer and Inner radius, from the point that the spawn happens.
-- @param #SPAWN self
-- @param #boolean RandomizePosition If true, SPAWN will perform the randomization of the @{Wrapper.Group}s position between a given outer and inner radius. 
-- @param DCS#Distance OuterRadius (optional) The outer radius in meters where the new group will be spawned.
-- @param DCS#Distance InnerRadius (optional) The inner radius in meters where the new group will NOT be spawned.
-- @return #SPAWN
function SPAWN:InitRandomizePosition( RandomizePosition, OuterRadius, InnerRadius )
  self:F( { self.SpawnTemplatePrefix, RandomizePosition, OuterRadius, InnerRadius } )

  self.SpawnRandomizePosition = RandomizePosition or false
  self.SpawnRandomizePositionOuterRadius = OuterRadius or 0
  self.SpawnRandomizePositionInnerRadius = InnerRadius or 0

  for GroupID = 1, self.SpawnMaxGroups do
    self:_RandomizeRoute( GroupID )
  end
  
  return self
end


--- Randomizes the UNITs that are spawned within a radius band given an Outer and Inner radius.
-- @param #SPAWN self
-- @param #boolean RandomizeUnits If true, SPAWN will perform the randomization of the @{UNIT}s position within the group between a given outer and inner radius. 
-- @param DCS#Distance OuterRadius (optional) The outer radius in meters where the new group will be spawned.
-- @param DCS#Distance InnerRadius (optional) The inner radius in meters where the new group will NOT be spawned.
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


--- Randomize templates to be used as the unit representatives for the Spawned group, defined using a SET_GROUP object.
-- This method becomes useful when you need to spawn groups with random templates of groups defined within the mission editor, 
-- but they will all follow the same Template route and have the same prefix name.
-- In other words, this method randomizes between a defined set of groups the template to be used for each new spawn of a group.
-- @param #SPAWN self
-- @param Core.Set#SET_GROUP SpawnTemplateSet A SET_GROUP object set, that contains the groups that are possible unit representatives of the group to be spawned. 
-- @return #SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- 
-- -- Choose between different 'US Tank Platoon Template' configurations to be spawned for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SPAWN objects.
-- 
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be spawned during the whole mission.
-- 
-- Spawn_US_PlatoonSet = SET_GROUP:New():FilterPrefixes( "US Tank Platoon Templates" ):FilterOnce()
-- 
-- --- Now use the Spawn_US_PlatoonSet to define the templates using InitRandomizeTemplateSet.
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplateSet( Spawn_US_PlatoonSet ):InitRandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplateSet( Spawn_US_PlatoonSet ):InitRandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplateSet( Spawn_US_PlatoonSet ):InitRandomizeRoute( 3, 3, 2000 )
function SPAWN:InitRandomizeTemplateSet( SpawnTemplateSet ) -- R2.3
  self:F( { self.SpawnTemplatePrefix } )

  self.SpawnTemplatePrefixTable = SpawnTemplateSet:GetSetNames()
  self.SpawnRandomizeTemplate = true

  for SpawnGroupID = 1, self.SpawnMaxGroups do
    self:_RandomizeTemplate( SpawnGroupID )
  end
  
  return self
end


--- Randomize templates to be used as the unit representatives for the Spawned group, defined by specifying the prefix names.
-- This method becomes useful when you need to spawn groups with random templates of groups defined within the mission editor, 
-- but they will all follow the same Template route and have the same prefix name.
-- In other words, this method randomizes between a defined set of groups the template to be used for each new spawn of a group.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefixes A string or a list of string that contains the prefixes of the groups that are possible unit representatives of the group to be spawned. 
-- @return #SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- 
-- -- Choose between different 'US Tank Platoon Templates' configurations to be spawned for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SPAWN objects.
-- 
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be spawned during the whole mission.
-- 
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplatePrefixes( "US Tank Platoon Templates" ):InitRandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplatePrefixes( "US Tank Platoon Templates" ):InitRandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):InitLimit( 12, 150 ):Schedule( 200, 0.4 ):InitRandomizeTemplatePrefixes( "US Tank Platoon Templates" ):InitRandomizeRoute( 3, 3, 2000 )
function SPAWN:InitRandomizeTemplatePrefixes( SpawnTemplatePrefixes ) --R2.3
  self:F( { self.SpawnTemplatePrefix } )

  local SpawnTemplateSet = SET_GROUP:New():FilterPrefixes( SpawnTemplatePrefixes ):FilterOnce()

  self:InitRandomizeTemplateSet( SpawnTemplateSet )
  
  return self
end


--- When spawning a new group, make the grouping of the units according the InitGrouping setting.
-- @param #SPAWN self
-- @param #number Grouping Indicates the maximum amount of units in the group. 
-- @return #SPAWN
function SPAWN:InitGrouping( Grouping ) -- R2.2
  self:F( { self.SpawnTemplatePrefix, Grouping } )

  self.SpawnGrouping = Grouping

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
-- SpawnRU_SU34 = SPAWN
--   :New( 'Su-34' )
--   :Schedule( 2, 3, 1800, 0.4 )
--   :SpawnUncontrolled()
--   :InitRandomizeRoute( 1, 1, 3000 )
--   :InitRepeatOnEngineShutDown()
--   
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
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN
--   :New( 'Su-34' )
--   :Schedule( 2, 3, 1800, 0.4 )
--   :SpawnUncontrolled()
--   :InitRandomizeRoute( 1, 1, 3000 )
--   :InitRepeatOnLanding()
--   
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
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN
--   :New( 'Su-34' )
--   :Schedule( 2, 3, 1800, 0.4 )
--   :SpawnUncontrolled()
--   :InitRandomizeRoute( 1, 1, 3000 )
--   :InitRepeatOnEngineShutDown()
--   
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
-- @usage 
-- Spawn_Helicopter:InitCleanUp( 20 )  -- CleanUp the spawning of the helicopters every 20 seconds when they become inactive.
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
-- Spawn_BE_Ground = SPAWN
--   :New( 'BE Ground' )
--   :InitLimit( 2, 24 )
--   :InitArray( 90, 10, 100, 50 )
--   
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

    self:HandleEvent( EVENTS.Birth, self._OnBirth )
    self:HandleEvent( EVENTS.Dead, self._OnDeadOrCrash )
    self:HandleEvent( EVENTS.Crash, self._OnDeadOrCrash )
    if self.Repeat then
      self:HandleEvent( EVENTS.Takeoff, self._OnTakeOff )
      self:HandleEvent( EVENTS.Land, self._OnLand )
    end
    if self.RepeatOnEngineShutDown then
      self:HandleEvent( EVENTS.EngineShutdown, self._OnEngineShutDown )
    end
		
		self.SpawnGroups[SpawnGroupID].Group = _DATABASE:Spawn( self.SpawnGroups[SpawnGroupID].SpawnTemplate )

		SpawnX = SpawnXIndex * SpawnDeltaX
		SpawnY = SpawnYIndex * SpawnDeltaY
	end
	
	return self
end

do -- AI methods
  --- Turns the AI On or Off for the @{Wrapper.Group} when spawning.
  -- @param #SPAWN self
  -- @param #boolean AIOnOff A value of true sets the AI On, a value of false sets the AI Off.
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitAIOnOff( AIOnOff )
  
    self.AIOnOff = AIOnOff
    return self
  end
  
  --- Turns the AI On for the @{Wrapper.Group} when spawning.
  -- @param #SPAWN self
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitAIOn()
  
    return self:InitAIOnOff( true )
  end
  
  --- Turns the AI Off for the @{Wrapper.Group} when spawning.
  -- @param #SPAWN self
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitAIOff()
  
    return self:InitAIOnOff( false )
  end

end -- AI methods

do -- Delay methods
  --- Turns the Delay On or Off for the first @{Wrapper.Group} scheduled spawning.
  -- The default value is that for scheduled spawning, there is an initial delay when spawning the first @{Wrapper.Group}.
  -- @param #SPAWN self
  -- @param #boolean DelayOnOff A value of true sets the Delay On, a value of false sets the Delay Off.
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitDelayOnOff( DelayOnOff )
  
    self.DelayOnOff = DelayOnOff
    return self
  end
  
  --- Turns the Delay On for the @{Wrapper.Group} when spawning.
  -- @param #SPAWN self
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitDelayOn()
  
    return self:InitDelayOnOff( true )
  end
  
  --- Turns the Delay Off for the @{Wrapper.Group} when spawning.
  -- @param #SPAWN self
  -- @return #SPAWN The SPAWN object
  function SPAWN:InitDelayOff()
  
    return self:InitDelayOnOff( false )
  end

end -- Delay methods

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
	
	SpawnGroup:ResetEvents()
	
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

        -- If RandomizePosition, then Randomize the formation in the zone band, keeping the template.
        if self.SpawnRandomizePosition then
          local RandomVec2 = PointVec3:GetRandomVec2InRadius( self.SpawnRandomizePositionOuterRadius, self.SpawnRandomizePositionInnerRadius )
          local CurrentX = SpawnTemplate.units[1].x
          local CurrentY = SpawnTemplate.units[1].y
          SpawnTemplate.x = RandomVec2.x
          SpawnTemplate.y = RandomVec2.y
          for UnitID = 1, #SpawnTemplate.units do
            SpawnTemplate.units[UnitID].x = SpawnTemplate.units[UnitID].x + ( RandomVec2.x - CurrentX )
            SpawnTemplate.units[UnitID].y = SpawnTemplate.units[UnitID].y + ( RandomVec2.y - CurrentY )
            self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
          end
        end
        
        -- If RandomizeUnits, then Randomize the formation at the start point.
        if self.SpawnRandomizeUnits then
          for UnitID = 1, #SpawnTemplate.units do
            local RandomVec2 = PointVec3:GetRandomVec2InRadius( self.SpawnOuterRadius, self.SpawnInnerRadius )
            SpawnTemplate.units[UnitID].x = RandomVec2.x
            SpawnTemplate.units[UnitID].y = RandomVec2.y
            self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
          end
        end
        
        -- If Heading is given, point all the units towards the given Heading.
        if self.SpawnInitHeadingMin then
          for UnitID = 1, #SpawnTemplate.units do
            SpawnTemplate.units[UnitID].heading = self.SpawnInitHeadingMax and math.random( self.SpawnInitHeadingMin, self.SpawnInitHeadingMax ) or self.SpawnInitHeadingMin
          end
        end
        
        SpawnTemplate.CategoryID = self.SpawnInitCategory or SpawnTemplate.CategoryID 
        SpawnTemplate.CountryID = self.SpawnInitCountry or SpawnTemplate.CountryID 
        SpawnTemplate.CoalitionID = self.SpawnInitCoalition or SpawnTemplate.CoalitionID 
        
        
        if SpawnTemplate.CategoryID == Group.Category.HELICOPTER or SpawnTemplate.CategoryID == Group.Category.AIRPLANE then
          if SpawnTemplate.route.points[1].type == "TakeOffParking" then
            SpawnTemplate.uncontrolled = self.SpawnUnControlled
          end
        end
      end
		  
      self:HandleEvent( EVENTS.Birth, self._OnBirth )
      self:HandleEvent( EVENTS.Dead, self._OnDeadOrCrash )
      self:HandleEvent( EVENTS.Crash, self._OnDeadOrCrash )
      if self.Repeat then
        self:HandleEvent( EVENTS.Takeoff, self._OnTakeOff )
        self:HandleEvent( EVENTS.Land, self._OnLand )
      end
      if self.RepeatOnEngineShutDown then
        self:HandleEvent( EVENTS.EngineShutdown, self._OnEngineShutDown )
      end

			self.SpawnGroups[self.SpawnIndex].Group = _DATABASE:Spawn( SpawnTemplate )
			
			local SpawnGroup = self.SpawnGroups[self.SpawnIndex].Group -- Wrapper.Group#GROUP
			
			--TODO: Need to check if this function doesn't need to be scheduled, as the group may not be immediately there!
      if SpawnGroup then
      
			  SpawnGroup:SetAIOnOff( self.AIOnOff )
			end

      self:T3( SpawnTemplate.name )
			
			-- If there is a SpawnFunction hook defined, call it.
			if self.SpawnFunctionHook then
			  -- delay calling this for .1 seconds so that it hopefully comes after the BIRTH event of the group.
			  self.SpawnHookScheduler:Schedule( nil, self.SpawnFunctionHook, { self.SpawnGroups[self.SpawnIndex].Group, unpack( self.SpawnFunctionArguments)}, 0.1 )
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
	  local InitialDelay = 0
	  if self.DelayOnOff == true then
	    InitialDelay = math.random( SpawnTime - SpawnTime * SpawnTimeVariation, SpawnTime + SpawnTime * SpawnTimeVariation )
	  end
    self.SpawnScheduler = SCHEDULER:New( self, self._Scheduler, {}, InitialDelay, SpawnTime, SpawnTimeVariation )
	end

	return self
end

--- Will re-start the spawning scheduler.
-- Note: This method is only required to be called when the schedule was stopped.
-- @param #SPAWN self
-- @return #SPAWN
function SPAWN:SpawnScheduleStart()
  self:F( { self.SpawnTemplatePrefix } )

  self.SpawnScheduler:Start()
  return self
end

--- Will stop the scheduled spawning scheduler.
-- @param #SPAWN self
-- @return #SPAWN
function SPAWN:SpawnScheduleStop()
  self:F( { self.SpawnTemplatePrefix } )
  
  self.SpawnScheduler:Stop()
  return self
end


--- Allows to place a CallFunction hook when a new group spawns.
-- The provided method will be called when a new group is spawned, including its given parameters.
-- The first parameter of the SpawnFunction is the @{Wrapper.Group#GROUP} that was spawned.
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

--- Will spawn a group at an @{Wrapper.Airbase}. 
-- This method is mostly advisable to be used if you want to simulate spawning units at an airbase.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- 
-- The @{Wrapper.Airbase#AIRBASE} object must refer to a valid airbase known in the sim.
-- You can use the following enumerations to search for the pre-defined airbases on the current known maps of DCS:
-- 
--   * @{Wrapper.Airbase#AIRBASE.Caucasus}: The airbases on the Caucasus map. 
--   * @{Wrapper.Airbase#AIRBASE.Nevada}: The airbases on the Nevada (NTTR) map. 
--   * @{Wrapper.Airbase#AIRBASE.Normandy}: The airbases on the Normandy map. 
-- 
-- Use the method @{Wrapper.Airbase#AIRBASE.FindByName}() to retrieve the airbase object. 
-- The known AIRBASE objects are automatically imported at mission start by MOOSE.
-- Therefore, there isn't any New() constructor defined for AIRBASE objects.
-- 
-- Ships and Farps are added within the mission, and are therefore not known.
-- For these AIRBASE objects, there isn't an @{Wrapper.Airbase#AIRBASE} enumeration defined.
-- You need to provide the **exact name** of the airbase as the parameter to the @{Wrapper.Airbase#AIRBASE.FindByName}() method!
-- 
-- @param #SPAWN self
-- @param Wrapper.Airbase#AIRBASE SpawnAirbase The @{Wrapper.Airbase} where to spawn the group.
-- @param #SPAWN.Takeoff Takeoff (optional) The location and takeoff method. Default is Hot.
-- @param #number TakeoffAltitude (optional) The altitude above the ground.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
-- @usage
--   Spawn_Plane = SPAWN:New( "Plane" )
--   Spawn_Plane:SpawnAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Krymsk ), SPAWN.Takeoff.Cold )
--   Spawn_Plane:SpawnAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Krymsk ), SPAWN.Takeoff.Hot )
--   Spawn_Plane:SpawnAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Krymsk ), SPAWN.Takeoff.Runway )
--   
--   Spawn_Plane:SpawnAtAirbase( AIRBASE:FindByName( "Carrier" ), SPAWN.Takeoff.Cold )
--   
--   Spawn_Heli = SPAWN:New( "Heli")
--   
--   Spawn_Heli:SpawnAtAirbase( AIRBASE:FindByName( "FARP Cold" ), SPAWN.Takeoff.Cold )
--   Spawn_Heli:SpawnAtAirbase( AIRBASE:FindByName( "FARP Hot" ), SPAWN.Takeoff.Hot )
--   Spawn_Heli:SpawnAtAirbase( AIRBASE:FindByName( "FARP Runway" ), SPAWN.Takeoff.Runway )
--   Spawn_Heli:SpawnAtAirbase( AIRBASE:FindByName( "FARP Air" ), SPAWN.Takeoff.Air )
--   
--   Spawn_Heli:SpawnAtAirbase( AIRBASE:FindByName( "Carrier" ), SPAWN.Takeoff.Cold )
-- 
function SPAWN:SpawnAtAirbase( SpawnAirbase, Takeoff, TakeoffAltitude ) -- R2.2
  self:F( { self.SpawnTemplatePrefix, SpawnAirbase, Takeoff, TakeoffAltitude } )

  local PointVec3 = SpawnAirbase:GetPointVec3()
  self:T2(PointVec3)

  Takeoff = Takeoff or SPAWN.Takeoff.Hot
  
  if self:_GetSpawnIndex( self.SpawnIndex + 1 ) then
    
    local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
  
    if SpawnTemplate then

      self:T( { "Current point of ", self.SpawnTemplatePrefix, SpawnAirbase } )

      local SpawnPoint = SpawnTemplate.route.points[1] 

      -- These are only for ships.
      SpawnPoint.linkUnit = nil
      SpawnPoint.helipadId = nil
      SpawnPoint.airdromeId = nil

      local AirbaseID = SpawnAirbase:GetID()
      local AirbaseCategory = SpawnAirbase:GetDesc().category
      self:F( { AirbaseCategory = AirbaseCategory } )
      
      if AirbaseCategory == Airbase.Category.SHIP then
        SpawnPoint.linkUnit = AirbaseID
        SpawnPoint.helipadId = AirbaseID
      elseif AirbaseCategory == Airbase.Category.HELIPAD then
        SpawnPoint.linkUnit = AirbaseID
        SpawnPoint.helipadId = AirbaseID
      elseif AirbaseCategory == Airbase.Category.AIRDROME then
        SpawnPoint.airdromeId = AirbaseID
      end

      SpawnPoint.alt = 0
              
      SpawnPoint.type = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
      SpawnPoint.action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action
      

      -- Translate the position of the Group Template to the Vec3.
      for UnitID = 1, #SpawnTemplate.units do
        self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )

        -- These cause a lot of confusion.
        local UnitTemplate = SpawnTemplate.units[UnitID]

        UnitTemplate.parking = nil
        UnitTemplate.parking_id = nil
        UnitTemplate.alt = 0

        local SX = UnitTemplate.x
        local SY = UnitTemplate.y 
        local BX = SpawnPoint.x
        local BY = SpawnPoint.y
        local TX = PointVec3.x + ( SX - BX )
        local TY = PointVec3.z + ( SY - BY )
        
        UnitTemplate.x = TX
        UnitTemplate.y = TY
        
        if Takeoff == GROUP.Takeoff.Air then
          UnitTemplate.alt = PointVec3.y + ( TakeoffAltitude or 200 )
        --else
        --  UnitTemplate.alt = PointVec3.y + 10
        end
        self:T( 'After Translation SpawnTemplate.units['..UnitID..'].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. UnitTemplate.y )
      end
      
      SpawnPoint.x = PointVec3.x
      SpawnPoint.y = PointVec3.z
      
      if Takeoff == GROUP.Takeoff.Air then
        SpawnPoint.alt = PointVec3.y + ( TakeoffAltitude or 200 )
      --else
      --  SpawnPoint.alt = PointVec3.y + 10
      end

      SpawnTemplate.x = PointVec3.x
      SpawnTemplate.y = PointVec3.z
      
      local GroupSpawned = self:SpawnWithIndex( self.SpawnIndex )
      
      -- When spawned in the air, we need to generate a Takeoff Event
      
      if Takeoff == GROUP.Takeoff.Air then
        for UnitID, UnitSpawned in pairs( GroupSpawned:GetUnits() ) do
          SCHEDULER:New( nil, BASE.CreateEventTakeoff, { GroupSpawned, timer.getTime(), UnitSpawned:GetDCSObject() } , 1 )
        end
      end

      return GroupSpawned
    end
  end
  
  return nil
end



--- Will spawn a group from a Vec3 in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning units in the air, like helicopters or airplanes.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param DCS#Vec3 Vec3 The Vec3 coordinates where to spawn the group.
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
      
      local TemplateHeight = SpawnTemplate.route and SpawnTemplate.route.points[1].alt or nil

      SpawnTemplate.route = SpawnTemplate.route or {}
      SpawnTemplate.route.points = SpawnTemplate.route.points or {}
      SpawnTemplate.route.points[1] = SpawnTemplate.route.points[1] or {}
      SpawnTemplate.route.points[1].x = SpawnTemplate.route.points[1].x or 0
      SpawnTemplate.route.points[1].y = SpawnTemplate.route.points[1].y or 0

      -- Translate the position of the Group Template to the Vec3.
      for UnitID = 1, #SpawnTemplate.units do
        --self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        local UnitTemplate = SpawnTemplate.units[UnitID]
        local SX = UnitTemplate.x or 0
        local SY = UnitTemplate.y  or 0
        local BX = SpawnTemplate.route.points[1].x
        local BY = SpawnTemplate.route.points[1].y
        local TX = Vec3.x + ( SX - BX )
        local TY = Vec3.z + ( SY - BY )
        SpawnTemplate.units[UnitID].x = TX
        SpawnTemplate.units[UnitID].y = TY
        if SpawnTemplate.CategoryID ~= Group.Category.SHIP then
          SpawnTemplate.units[UnitID].alt = Vec3.y or TemplateHeight
        end
        self:T( 'After Translation SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
      end
      SpawnTemplate.route.points[1].x = Vec3.x
      SpawnTemplate.route.points[1].y = Vec3.z
      if SpawnTemplate.CategoryID ~= Group.Category.SHIP then
        SpawnTemplate.route.points[1].alt = Vec3.y or TemplateHeight
      end
      SpawnTemplate.x = Vec3.x
      SpawnTemplate.y = Vec3.z
      SpawnTemplate.alt = Vec3.y or TemplateHeight
              
      return self:SpawnWithIndex( self.SpawnIndex )
    end
  end
  
  return nil
end


--- Will spawn a group from a Coordinate in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning units in the air, like helicopters or airplanes.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Core.Point#Coordinate Coordinate The Coordinate coordinates where to spawn the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromCoordinate( Coordinate, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

  return self:SpawnFromVec3( Coordinate:GetVec3(), SpawnIndex )
end



--- Will spawn a group from a PointVec3 in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning units in the air, like helicopters or airplanes.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Core.Point#POINT_VEC3 PointVec3 The PointVec3 coordinates where to spawn the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
-- @usage
-- 
--   local SpawnPointVec3 = ZONE:New( ZoneName ):GetPointVec3( 2000 ) -- Get the center of the ZONE object at 2000 meters from the ground.
-- 
--   -- Spawn at the zone center position at 2000 meters from the ground!
--   SpawnAirplanes:SpawnFromPointVec3( SpawnPointVec3 )  
--   
function SPAWN:SpawnFromPointVec3( PointVec3, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

  return self:SpawnFromVec3( PointVec3:GetVec3(), SpawnIndex )
end


--- Will spawn a group from a Vec2 in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning groups on the ground from air units, like vehicles.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param DCS#Vec2 Vec2 The Vec2 coordinates where to spawn the group.
-- @param #number MinHeight (optional) The minimum height to spawn an airborne group into the zone.
-- @param #number MaxHeight (optional) The maximum height to spawn an airborne group into the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
-- @usage
-- 
--   local SpawnVec2 = ZONE:New( ZoneName ):GetVec2()
-- 
--   -- Spawn at the zone center position at the height specified in the ME of the group template!
--   SpawnAirplanes:SpawnFromVec2( SpawnVec2 )  
--   
--   -- Spawn from the static position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnFromVec2( SpawnVec2, 2000, 4000 )  
-- 
function SPAWN:SpawnFromVec2( Vec2, MinHeight, MaxHeight, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, self.SpawnIndex, Vec2, MinHeight, MaxHeight, SpawnIndex } )

  local Height = nil

  if MinHeight and MaxHeight then
    Height = math.random( MinHeight, MaxHeight)
  end
  
  return self:SpawnFromVec3( { x = Vec2.x, y = Height, z = Vec2.y }, SpawnIndex ) -- y can be nil. In this case, spawn on the ground for vehicles, and in the template altitude for air.
end


--- Will spawn a group from a POINT_VEC2 in 3D space. 
-- This method is mostly advisable to be used if you want to simulate spawning groups on the ground from air units, like vehicles.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Core.Point#POINT_VEC2 PointVec2 The PointVec2 coordinates where to spawn the group.
-- @param #number MinHeight (optional) The minimum height to spawn an airborne group into the zone.
-- @param #number MaxHeight (optional) The maximum height to spawn an airborne group into the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
-- @usage
-- 
--   local SpawnPointVec2 = ZONE:New( ZoneName ):GetPointVec2()
-- 
--   -- Spawn at the zone center position at the height specified in the ME of the group template!
--   SpawnAirplanes:SpawnFromPointVec2( SpawnPointVec2 )  
--   
--   -- Spawn from the static position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnFromPointVec2( SpawnPointVec2, 2000, 4000 )  
-- 
function SPAWN:SpawnFromPointVec2( PointVec2, MinHeight, MaxHeight, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, self.SpawnIndex } )

  return self:SpawnFromVec2( PointVec2:GetVec2(), MinHeight, MaxHeight, SpawnIndex )
end



--- Will spawn a group from a hosting unit. This method is mostly advisable to be used if you want to simulate spawning from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Wrapper.Unit#UNIT HostUnit The air or ground unit dropping or unloading the group.
-- @param #number MinHeight (optional) The minimum height to spawn an airborne group into the zone.
-- @param #number MaxHeight (optional) The maximum height to spawn an airborne group into the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
-- @usage
-- 
--   local SpawnStatic = STATIC:FindByName( StaticName )
-- 
--   -- Spawn from the static position at the height specified in the ME of the group template!
--   SpawnAirplanes:SpawnFromUnit( SpawnStatic )  
--   
--   -- Spawn from the static position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnFromUnit( SpawnStatic, 2000, 4000 )  
-- 
function SPAWN:SpawnFromUnit( HostUnit, MinHeight, MaxHeight, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, HostUnit, MinHeight, MaxHeight, SpawnIndex } )

  if HostUnit and HostUnit:IsAlive() ~= nil then -- and HostUnit:getUnit(1):inAir() == false then
    return self:SpawnFromVec2( HostUnit:GetVec2(), MinHeight, MaxHeight, SpawnIndex )
  end
  
  return nil
end

--- Will spawn a group from a hosting static. This method is mostly advisable to be used if you want to simulate spawning from buldings and structures (static buildings).
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Wrapper.Static#STATIC HostStatic The static dropping or unloading the group.
-- @param #number MinHeight (optional) The minimum height to spawn an airborne group into the zone.
-- @param #number MaxHeight (optional) The maximum height to spawn an airborne group into the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
-- @usage
-- 
--   local SpawnStatic = STATIC:FindByName( StaticName )
-- 
--   -- Spawn from the static position at the height specified in the ME of the group template!
--   SpawnAirplanes:SpawnFromStatic( SpawnStatic )  
--   
--   -- Spawn from the static position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnFromStatic( SpawnStatic, 2000, 4000 )  
-- 
function SPAWN:SpawnFromStatic( HostStatic, MinHeight, MaxHeight, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, HostStatic, MinHeight, MaxHeight, SpawnIndex } )

  if HostStatic and HostStatic:IsAlive() then
    return self:SpawnFromVec2( HostStatic:GetVec2(), MinHeight, MaxHeight, SpawnIndex )
  end
  
  return nil
end

--- Will spawn a Group within a given @{Zone}.
-- The @{Zone} can be of any type derived from @{Core.Zone#ZONE_BASE}.
-- Once the @{Wrapper.Group} is spawned within the zone, the @{Wrapper.Group} will continue on its route.
-- The **first waypoint** (where the group is spawned) is replaced with the zone location coordinates.
-- @param #SPAWN self
-- @param Core.Zone#ZONE Zone The zone where the group is to be spawned.
-- @param #boolean RandomizeGroup (optional) Randomization of the @{Wrapper.Group} position in the zone.
-- @param #number MinHeight (optional) The minimum height to spawn an airborne group into the zone.
-- @param #number MaxHeight (optional) The maximum height to spawn an airborne group into the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned.
-- @return #nil when nothing was spawned.
-- @usage
-- 
--   local SpawnZone = ZONE:New( ZoneName )
-- 
--   -- Spawn at the zone center position at the height specified in the ME of the group template!
--   SpawnAirplanes:SpawnInZone( SpawnZone )  
--   
--   -- Spawn in the zone at a random position at the height specified in the Me of the group template.
--   SpawnAirplanes:SpawnInZone( SpawnZone, true )  
--   
--   -- Spawn in the zone at a random position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnInZone( SpawnZone, true, 2000, 4000 )  
-- 
--   -- Spawn at the zone center position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnInZone( SpawnZone, false, 2000, 4000 )  
--   
--   -- Spawn at the zone center position at the height randomized between 2000 and 4000 meters.
--   SpawnAirplanes:SpawnInZone( SpawnZone, nil, 2000, 4000 )  
--   
function SPAWN:SpawnInZone( Zone, RandomizeGroup, MinHeight, MaxHeight, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, Zone, RandomizeGroup, MinHeight, MaxHeight, SpawnIndex } )
  
  if Zone then
    if RandomizeGroup then
      return self:SpawnFromVec2( Zone:GetRandomVec2(), MinHeight, MaxHeight, SpawnIndex )
    else
      return self:SpawnFromVec2( Zone:GetVec2(), MinHeight, MaxHeight, SpawnIndex )
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


--- Get the Coordinate of the Group that is Late Activated as the template for the SPAWN object.
-- @param #SPAWN self
-- @return Core.Point#COORDINATE The Coordinate
function SPAWN:GetCoordinate()

  local LateGroup = GROUP:FindByName( self.SpawnTemplatePrefix )
  if LateGroup then
    return LateGroup:GetCoordinate()
  end
  
  return nil
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

--- Will find the first alive @{Wrapper.Group} it has spawned, and return the alive @{Wrapper.Group} object and the first Index where the first alive @{Wrapper.Group} object has been found.
-- @param #SPAWN self
-- @return Wrapper.Group#GROUP, #number The @{Wrapper.Group} object found, the new Index where the group was found.
-- @return #nil, #nil When no group is found, #nil is returned.
-- @usage
-- -- Find the first alive @{Wrapper.Group} object of the SpawnPlanes SPAWN object @{Wrapper.Group} collection that it has spawned during the mission.
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


--- Will find the next alive @{Wrapper.Group} object from a given Index, and return a reference to the alive @{Wrapper.Group} object and the next Index where the alive @{Wrapper.Group} has been found.
-- @param #SPAWN self
-- @param #number SpawnIndexStart A Index holding the start position to search from. This method can also be used to find the first alive @{Wrapper.Group} object from the given Index.
-- @return Wrapper.Group#GROUP, #number The next alive @{Wrapper.Group} object found, the next Index where the next alive @{Wrapper.Group} object was found.
-- @return #nil, #nil When no alive @{Wrapper.Group} object is found from the start Index position, #nil is returned.
-- @usage
-- -- Find the first alive @{Wrapper.Group} object of the SpawnPlanes SPAWN object @{Wrapper.Group} collection that it has spawned during the mission.
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

--- Will find the last alive @{Wrapper.Group} object, and will return a reference to the last live @{Wrapper.Group} object and the last Index where the last alive @{Wrapper.Group} object has been found.
-- @param #SPAWN self
-- @return Wrapper.Group#GROUP, #number The last alive @{Wrapper.Group} object found, the last Index where the last alive @{Wrapper.Group} object was found.
-- @return #nil, #nil When no alive @{Wrapper.Group} object is found, #nil is returned.
-- @usage
-- -- Find the last alive @{Wrapper.Group} object of the SpawnPlanes SPAWN object @{Wrapper.Group} collection that it has spawned during the mission.
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


--- Return the prefix of a SpawnUnit.
-- The method will search for a #-mark, and will return the text before the #-mark.
-- It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param DCS#UNIT DCSUnit The @{DCSUnit} to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetPrefixFromGroup( SpawnGroup )
  self:F3( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )

  local GroupName = SpawnGroup:GetName()
  if GroupName then
    local SpawnPrefix = string.match( GroupName, ".*#" )
    if SpawnPrefix then
      SpawnPrefix = SpawnPrefix:sub( 1, -2 )
    end
    return SpawnPrefix
  end
  
  return nil
end


--- Get the index from a given group.
-- The function will search the name of the group for a #, and will return the number behind the #-mark.
function SPAWN:GetSpawnIndexFromGroup( SpawnGroup )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )
	
	local IndexString = string.match( SpawnGroup:GetName(), "#(%d*)$" ):sub( 2 )
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
-- @param #SPAWN self
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

  local Template = _DATABASE.Templates.Groups[SpawnTemplatePrefix].Template
  self:F( { Template = Template } )

	SpawnTemplate = UTILS.DeepCopy( _DATABASE.Templates.Groups[SpawnTemplatePrefix].Template )
	
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
function SPAWN:_Prepare( SpawnTemplatePrefix, SpawnIndex ) --R2.2
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )
	
--	if not self.SpawnTemplate then
--	  self.SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
--	end
	
  local SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
	--local SpawnTemplate = self.SpawnTemplate
	SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
	
	SpawnTemplate.groupId = nil
	--SpawnTemplate.lateActivation = false
  SpawnTemplate.lateActivation = self.LateActivated or false 

	if SpawnTemplate.CategoryID == Group.Category.GROUND then
	  self:T3( "For ground units, visible needs to be false..." )
		SpawnTemplate.visible = false 
	end
	
	if self.SpawnGrouping then
	  local UnitAmount = #SpawnTemplate.units
	  self:F( { UnitAmount = UnitAmount, SpawnGrouping = self.SpawnGrouping } )
	  if UnitAmount > self.SpawnGrouping then
      for UnitID = self.SpawnGrouping + 1, UnitAmount do
        SpawnTemplate.units[UnitID] = nil
      end
    else
      if UnitAmount < self.SpawnGrouping then
        for UnitID = UnitAmount + 1, self.SpawnGrouping do
          SpawnTemplate.units[UnitID] = UTILS.DeepCopy( SpawnTemplate.units[1] )
          SpawnTemplate.units[UnitID].unitId = nil
        end
      end
    end
  end
	
  if self.SpawnInitKeepUnitNames == false then
  	for UnitID = 1, #SpawnTemplate.units do
  		SpawnTemplate.units[UnitID].name = string.format( SpawnTemplate.name .. '-%02d', UnitID )
  		SpawnTemplate.units[UnitID].unitId = nil
  	end
  else
    for UnitID = 1, #SpawnTemplate.units do
      local UnitPrefix, Rest = string.match( SpawnTemplate.units[UnitID].name, "^([^#]+)#?" ):gsub( "^%s*(.-)%s*$", "%1" )
      self:T( { UnitPrefix, Rest } )
      
      SpawnTemplate.units[UnitID].name = string.format( '%s#%03d-%02d', UnitPrefix, SpawnIndex, UnitID )
      SpawnTemplate.units[UnitID].unitId = nil
    end
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
    self.SpawnGroups[SpawnIndex].SpawnTemplate.route = UTILS.DeepCopy( self.SpawnTemplate.route )
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
      self:F( { SpawnCount = self.SpawnCount, SpawnIndex = SpawnIndex } )
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
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnBirth( EventData )
  self:F( self.SpawnTemplatePrefix )

  local SpawnGroup = EventData.IniGroup
  
  if SpawnGroup then
    local EventPrefix = self:_GetPrefixFromGroup( SpawnGroup )
    if EventPrefix then -- EventPrefix can be nil if no # is found, which means, no spawnable group!
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
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnDeadOrCrash( EventData )
  self:F( self.SpawnTemplatePrefix )

  local SpawnGroup = EventData.IniGroup
  
	if SpawnGroup then
		local EventPrefix = self:_GetPrefixFromGroup( SpawnGroup )
		if EventPrefix then -- EventPrefix can be nil if no # is found, which means, no spawnable group!
      self:T( { "Dead event: " .. EventPrefix } )
  		if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
  			self.AliveUnits = self.AliveUnits - 1
  			self:T( "Alive Units: " .. self.AliveUnits )
  		end
    end
	end
end

--- Will detect AIR Units taking off... When the event takes place, the spawned Group is registered as airborne...
-- This is needed to ensure that Re-SPAWNing only is done for landed AIR Groups.
-- @param #SPAWN self
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnTakeOff( EventData )
  self:F( self.SpawnTemplatePrefix )

  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local EventPrefix = self:_GetPrefixFromGroup( SpawnGroup )
    if EventPrefix then -- EventPrefix can be nil if no # is found, which means, no spawnable group!
      self:T( { "TakeOff event: " .. EventPrefix } )
      if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
    		self:T( "self.Landed = false" )
    		SpawnGroup:SetState( SpawnGroup, "Spawn_Landed", false )
      end
    end
	end
end

--- Will detect AIR Units landing... When the event takes place, the spawned Group is registered as landed.
-- This is needed to ensure that Re-SPAWNing is only done for landed AIR Groups.
-- @param #SPAWN self
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnLand( EventData )
  self:F( self.SpawnTemplatePrefix )

  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local EventPrefix = self:_GetPrefixFromGroup( SpawnGroup )
    if EventPrefix then -- EventPrefix can be nil if no # is found, which means, no spawnable group!
      self:T( { "Land event: " .. EventPrefix } )
      if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
  	    -- TODO: Check if this is the last unit of the group that lands.
  	    SpawnGroup:SetState( SpawnGroup, "Spawn_Landed", true )
  			if self.RepeatOnLanding then
  				local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
  				self:T( { "Landed:", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
  				self:ReSpawn( SpawnGroupIndex )
  			end
  		end
    end
	end
end

--- Will detect AIR Units shutting down their engines ...
-- When the event takes place, and the method @{RepeatOnEngineShutDown} was called, the spawned Group will Re-SPAWN.
-- But only when the Unit was registered to have landed.
-- @param #SPAWN self
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnEngineShutDown( EventData )
  self:F( self.SpawnTemplatePrefix )

  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local EventPrefix = self:_GetPrefixFromGroup( SpawnGroup )
    if EventPrefix then -- EventPrefix can be nil if no # is found, which means, no spawnable group!
      self:T( { "EngineShutdown event: " .. EventPrefix } )
      if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
  			-- todo: test if on the runway
  			local Landed = SpawnGroup:GetState( SpawnGroup, "Spawn_Landed" )
  			if Landed and self.RepeatOnEngineShutDown then
  				local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
  				self:T( { "EngineShutDown: ", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
  				self:ReSpawn( SpawnGroupIndex )
  			end
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
