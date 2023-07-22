--- **Core** - Spawn dynamically new groups of units in running missions.
--
-- ===
--
-- ## Features:
--
--   * Spawn new groups in running missions.
--   * Schedule spawning of new groups.
--   * Put limits on the amount of groups that can be spawned, and the amount of units that can be alive at the same time.
--   * Randomize the spawning location between different zones.
--   * Randomize the initial positions within the zones.
--   * Spawn in array formation.
--   * Spawn uncontrolled (for planes or helicopters only).
--   * Clean up inactive helicopters that "crashed".
--   * Place a hook to capture a spawn event, and tailor with customer code.
--   * Spawn late activated.
--   * Spawn with or without an initial delay.
--   * Respawn after landing, on the runway or at the ramp after engine shutdown.
--   * Spawn with custom heading, both for a group formation and for the units in the group.
--   * Spawn with different skills.
--   * Spawn with different liveries.
--   * Spawn with an inner and outer radius to set the initial position.
--   * Spawn with a randomize route.
--   * Spawn with a randomized template.
--   * Spawn with a randomized start points on a route.
--   * Spawn with an alternative name.
--   * Spawn and keep the unit names.
--   * Spawn with a different coalition and country.
--   * Enquiry methods to check on spawn status.
--
-- ===
-- 
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SPA%20-%20Spawning)
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
-- which modify the behavior or the way groups are spawned.
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
--   * @{#SPAWN.InitArray}(): Make groups visible before they are actually activated, and order these groups like a battalion in an array.
--   
-- ### Group initial position - if wanted different from template position, for use with e.g. @{#SPAWN.SpawnScheduled}().   
-- 
--   * @{#SPAWN.InitPositionCoordinate}(): Set initial position of group via a COORDINATE.
--   * @{#SPAWN.InitPositionVec2}(): Set initial position of group via a VEC2. 
--   
-- ### Set the positions of a group's units to absolute positions, or relative positions to unit No. 1
-- 
--   * @{#SPAWN.InitSetUnitRelativePositions}(): Spawn the UNITs of this group with individual relative positions to unit #1 and individual headings.
--   * @{#SPAWN.InitSetUnitAbsolutePositions}(): Spawn the UNITs of this group with individual absolute positions and individual headings.
--   
-- ### Position randomization
--
--   * @{#SPAWN.InitRandomizePosition}(): Randomizes the position of @{Wrapper.Group}s that are spawned within a **radius band**, given an Outer and Inner radius, from the point that the spawn happens.
--   * @{#SPAWN.InitRandomizeUnits}(): Randomizes the @{Wrapper.Unit}s in the @{Wrapper.Group} that is spawned within a **radius band**, given an Outer and Inner radius.
--   * @{#SPAWN.InitRandomizeZones}(): Randomizes the spawning between a predefined list of @{Core.Zone}s that are declared using this function. Each zone can be given a probability factor.
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
--   * @{#SPAWN.InitDelayOnOff}(): Turns the initial delay On/Off when scheduled spawning the first @{Wrapper.Group} object.
--   * @{#SPAWN.InitDelayOn}(): Turns the initial delay On when scheduled spawning the first @{Wrapper.Group} object.
--   * @{#SPAWN.InitDelayOff}(): Turns the initial delay Off when scheduled spawning the first @{Wrapper.Group} object.
--
-- ### Repeat spawned @{Wrapper.Group}s upon landing
--
--   * @{#SPAWN.InitRepeat}() or @{#SPAWN.InitRepeatOnLanding}(): This method is used to re-spawn automatically the same group after it has landed.
--   * @{#SPAWN.InitRepeatOnEngineShutDown}(): This method is used to re-spawn automatically the same group after it has landed and it shuts down the engines at the ramp.
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
--   * @{#SPAWN.SpawnFromStatic}(): Spawn a new group from a structure, taking the position of a @{Wrapper.Static}.
--   * @{#SPAWN.SpawnFromUnit}(): Spawn a new group taking the position of a @{Wrapper.Unit}.
--   * @{#SPAWN.SpawnInZone}(): Spawn a new group in a @{Core.Zone}.
--   * @{#SPAWN.SpawnAtAirbase}(): Spawn a new group at an @{Wrapper.Airbase}, which can be an airdrome, ship or helipad.
--
-- Note that @{#SPAWN.Spawn} and @{#SPAWN.ReSpawn} return a @{Wrapper.Group#GROUP.New} object, that contains a reference to the DCSGroup object.
-- You can use the @{Wrapper.Group#GROUP} object to do further actions with the DCSGroup.
--
-- ### **Scheduled** spawning methods
--
--   * @{#SPAWN.SpawnScheduled}(): Spawn groups at scheduled but randomized intervals.
---  * @{#SPAWN.SpawnScheduleStart}(): Start or continue to spawn groups at scheduled time intervals.
--   * @{#SPAWN.SpawnScheduleStop}(): Stop the spawning of groups at scheduled time intervals.
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
-- Sometimes, it will occur during a mission run-time, that ground or especially air objects get damaged, and will while being damaged stop their activities, while remaining alive.
-- In such cases, the SPAWN object will just sit there and wait until that group gets destroyed, but most of the time it won't,
-- and it may occur that no new groups are or can be spawned as limits are reached.
-- To prevent this, a @{#SPAWN.InitCleanUp}() initialization method has been defined that will silently monitor the status of each spawned group.
-- Once a group has a velocity = 0, and has been waiting for a defined interval, that group will be cleaned or removed from run-time.
-- There is a catch however :-) If a damaged group has returned to an airbase within the coalition, that group will not be considered as "lost"...
-- In such a case, when the inactive group is cleaned, a new group will Re-spawned automatically.
-- This models AI that has successfully returned to their airbase, to restart their combat activities.
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
-- When using the @{#SPAWN.SpawnScheduled)() method, the default behavior of this method will be that it will spawn the initial (first) @{Wrapper.Group}
-- immediately when :SpawnScheduled() is initiated. The methods @{#SPAWN.InitDelayOnOff}() and @{#SPAWN.InitDelayOn}() can be used to
-- activate a delay before the first @{Wrapper.Group} is spawned. For completeness, a method @{#SPAWN.InitDelayOff}() is also available, that
-- can be used to switch off the initial delay. Because there is no delay by default, this method would only be used when a
-- @{#SPAWN.SpawnScheduleStop}() ; @{#SPAWN.SpawnScheduleStart}() sequence would have been used.
--
-- @field #SPAWN SPAWN
SPAWN = {
  ClassName = "SPAWN",
  SpawnTemplatePrefix = nil,
  SpawnAliasPrefix = nil,
}

--- Enumerator for spawns at airbases
-- @type SPAWN.Takeoff
-- @extends Wrapper.Group#GROUP.Takeoff

-- @field #SPAWN.Takeoff Takeoff
SPAWN.Takeoff = {
  Air = 1,
  Runway = 2,
  Hot = 3,
  Cold = 4,
}

-- @type SPAWN.SpawnZoneTable
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
    self.SpawnCount = 0 -- The internal counter of the amount of spawning the has happened since SpawnStart.
    self.AliveUnits = 0 -- Contains the counter how many units are currently alive
    self.SpawnIsScheduled = false -- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
    self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix ) -- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
    self.Repeat = false -- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
    self.UnControlled = false -- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
    self.SpawnInitLimit = false -- By default, no InitLimit
    self.SpawnMaxUnitsAlive = 0 -- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
    self.SpawnMaxGroups = 0 -- The maximum amount of groups that can be spawned.
    self.SpawnRandomize = false -- Sets the randomization flag of new Spawned units to false.
    self.SpawnVisible = false -- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.
    self.AIOnOff = true -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false
    self.SpawnInitKeepUnitNames = false -- Overwrite unit names by default with group name.
    self.DelayOnOff = false -- No intial delay when spawning the first group.
    self.SpawnGrouping = nil -- No grouping.
    self.SpawnInitLivery = nil -- No special livery.
    self.SpawnInitSkill = nil -- No special skill.
    self.SpawnInitFreq = nil -- No special frequency.
    self.SpawnInitModu = nil -- No special modulation.
    self.SpawnInitRadio = nil -- No radio comms setting.
    self.SpawnInitModex = nil
    self.SpawnInitAirbase = nil
    self.TweakedTemplate = false -- Check if the user is using self made template.

    self.SpawnGroups = {} -- Array containing the descriptions of each Group to be Spawned.
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
-- @return #SPAWN self
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
    self.SpawnCount = 0 -- The internal counter of the amount of spawning the has happened since SpawnStart.
    self.AliveUnits = 0 -- Contains the counter how many units are currently alive
    self.SpawnIsScheduled = false -- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
    self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix ) -- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
    self.Repeat = false -- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
    self.UnControlled = false -- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
    self.SpawnInitLimit = false -- By default, no InitLimit
    self.SpawnMaxUnitsAlive = 0 -- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
    self.SpawnMaxGroups = 0 -- The maximum amount of groups that can be spawned.
    self.SpawnRandomize = false -- Sets the randomization flag of new Spawned units to false.
    self.SpawnVisible = false -- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.
    self.AIOnOff = true -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false
    self.SpawnInitKeepUnitNames = false -- Overwrite unit names by default with group name.
    self.DelayOnOff = false -- No initial delay when spawning the first group.
    self.SpawnGrouping = nil -- No grouping.
    self.SpawnInitLivery = nil -- No special livery.
    self.SpawnInitSkill = nil -- No special skill.
    self.SpawnInitFreq = nil -- No special frequency.
    self.SpawnInitModu = nil -- No special modulation.
    self.SpawnInitRadio = nil -- No radio communication setting.
    self.SpawnInitModex = nil
    self.SpawnInitAirbase = nil
    self.TweakedTemplate = false -- Check if the user is using self made template.

    self.SpawnGroups = {} -- Array containing the descriptions of each Group to be Spawned.
  else
    error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
  end

  self:SetEventPriority( 5 )
  self.SpawnHookScheduler = SCHEDULER:New( nil )

  return self
end

--- Creates a new SPAWN instance to create new groups based on the provided template. This will also register the template for future use.
-- @param #SPAWN self
-- @param #table SpawnTemplate is the Template of the Group. This must be a valid Group Template structure - see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_func_addGroup)!
-- @param #string SpawnTemplatePrefix [Mandatory] is the name of the template and the prefix of the GROUP on spawn. The name in the template **will** be overwritten!
-- @param #string SpawnAliasPrefix [Optional] is the prefix that will be given to the GROUP on spawn.
-- @param #boolean NoMooseNamingPostfix [Optional] If true, skip the Moose naming additions (like groupname#001-01) - **but** you need to ensure yourself no duplicate group names exist!
-- @return #SPAWN self
-- @usage
-- -- Spawn a P51 Mustang from scratch
-- local ttemp =  
--   {
--       ["modulation"] = 0,
--       ["tasks"] = 
--       {
--       }, -- end of ["tasks"]
--       ["task"] = "Reconnaissance",
--       ["uncontrolled"] = false,
--       ["route"] = 
--       {
--           ["points"] = 
--           {
--               [1] = 
--               {
--                   ["alt"] = 2000,
--                   ["action"] = "Turning Point",
--                   ["alt_type"] = "BARO",
--                   ["speed"] = 125,
--                   ["task"] = 
--                   {
--                       ["id"] = "ComboTask",
--                       ["params"] = 
--                       {
--                           ["tasks"] = 
--                           {
--                           }, -- end of ["tasks"]
--                       }, -- end of ["params"]
--                   }, -- end of ["task"]
--                   ["type"] = "Turning Point",
--                   ["ETA"] = 0,
--                   ["ETA_locked"] = true,
--                   ["y"] = 666285.71428571,
--                   ["x"] = -312000,
--                   ["formation_template"] = "",
--                   ["speed_locked"] = true,
--               }, -- end of [1]
--           }, -- end of ["points"]
--       }, -- end of ["route"]
--       ["groupId"] = 1,
--       ["hidden"] = false,
--       ["units"] = 
--       {
--           [1] = 
--           {
--               ["alt"] = 2000,
--               ["alt_type"] = "BARO",
--               ["livery_id"] = "USAF 364th FS",
--               ["skill"] = "High",
--               ["speed"] = 125,
--               ["type"] = "TF-51D",
--               ["unitId"] = 1,
--               ["psi"] = 0,
--               ["y"] = 666285.71428571,
--               ["x"] = -312000,
--               ["name"] = "P51-1-1",
--               ["payload"] = 
--               {
--                   ["pylons"] = 
--                   {
--                   }, -- end of ["pylons"]
--                   ["fuel"] = 340.68,
--                   ["flare"] = 0,
--                   ["chaff"] = 0,
--                   ["gun"] = 100,
--               }, -- end of ["payload"]
--               ["heading"] = 0,
--               ["callsign"] = 
--               {
--                   [1] = 1,
--                   [2] = 1,
--                   ["name"] = "Enfield11",
--                   [3] = 1,
--               }, -- end of ["callsign"]
--               ["onboard_num"] = "010",
--           }, -- end of [1]
--       }, -- end of ["units"]
--       ["y"] = 666285.71428571,
--       ["x"] = -312000,
--       ["name"] = "P51",
--       ["communication"] = true,
--       ["start_time"] = 0,
--       ["frequency"] = 124,
--   } 
-- 
-- 
-- local mustang = SPAWN:NewFromTemplate(ttemp,"P51D")
-- -- you MUST set the next three:
-- mustang:InitCountry(country.id.FRANCE)
-- mustang:InitCategory(Group.Category.AIRPLANE)
-- mustang:InitCoalition(coalition.side.BLUE)
-- mustang:OnSpawnGroup(
--   function(grp)
--     MESSAGE:New("Group Spawned: "..grp:GetName(),15,"SPAWN"):ToAll()
--   end
-- )
-- mustang:Spawn()
-- 
function SPAWN:NewFromTemplate( SpawnTemplate, SpawnTemplatePrefix, SpawnAliasPrefix, NoMooseNamingPostfix )
   local self = BASE:Inherit( self, BASE:New() )
   self:F( { SpawnTemplate, SpawnTemplatePrefix, SpawnAliasPrefix } )
   --if SpawnAliasPrefix == nil or SpawnAliasPrefix == "" then
     --BASE:I( "ERROR: in function NewFromTemplate, required parameter SpawnAliasPrefix is not set" )
     --return nil
  --end
  if SpawnTemplatePrefix == nil or SpawnTemplatePrefix == "" then
    BASE:I( "ERROR: in function NewFromTemplate, required parameter SpawnTemplatePrefix is not set" )
    return nil
  end

  if SpawnTemplate then
    self.SpawnTemplate = SpawnTemplate -- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
    self.SpawnTemplatePrefix = SpawnTemplatePrefix
    self.SpawnAliasPrefix = SpawnAliasPrefix or SpawnTemplatePrefix
    self.SpawnTemplate.name = SpawnTemplatePrefix
    self.SpawnIndex = 0
    self.SpawnCount = 0 -- The internal counter of the amount of spawning the has happened since SpawnStart.
    self.AliveUnits = 0 -- Contains the counter how many units are currently alive
    self.SpawnIsScheduled = false -- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
    self.Repeat = false -- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
    self.UnControlled = false -- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
    self.SpawnInitLimit = false -- By default, no InitLimit.
    self.SpawnMaxUnitsAlive = 0 -- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
    self.SpawnMaxGroups = 0 -- The maximum amount of groups that can be spawned.
    self.SpawnRandomize = false -- Sets the randomization flag of new Spawned units to false.
    self.SpawnVisible = false -- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.
    self.AIOnOff = true -- The AI is on by default when spawning a group.
    self.SpawnUnControlled = false
    self.SpawnInitKeepUnitNames = false -- Overwrite unit names by default with group name.
    self.DelayOnOff = false -- No initial delay when spawning the first group.
    self.Grouping = nil -- No grouping.
    self.SpawnInitLivery = nil -- No special livery.
    self.SpawnInitSkill = nil -- No special skill.
    self.SpawnInitFreq = nil -- No special frequency.
    self.SpawnInitModu = nil -- No special modulation.
    self.SpawnInitRadio = nil -- No radio communication setting.
    self.SpawnInitModex = nil
    self.SpawnInitAirbase = nil
    self.TweakedTemplate = true -- Check if the user is using self made template.
    self.MooseNameing  = true
    if NoMooseNamingPostfix == true then
     self.MooseNameing  = false
    end
    
    self.SpawnGroups = {} -- Array containing the descriptions of each Group to be Spawned.
  else
    error( "There is no template provided for SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
  end

  self:SetEventPriority( 5 )
  self.SpawnHookScheduler = SCHEDULER:New( nil )

  return self
end

--- Stops any more repeat spawns from happening once the UNIT count of Alive units, spawned by the same SPAWN object, exceeds the first parameter. Also can stop spawns from happening once a total GROUP still alive is met.
-- Exceptionally powerful when combined with SpawnSchedule for Respawning.
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
--
--   -- NATO helicopters engaging in the battle field.
--   -- This helicopter group consists of one Unit. So, this group will SPAWN maximum 2 groups simultaneously within the DCSRTE.
--   -- There will be maximum 24 groups spawned during the whole mission lifetime. 
--   Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitLimit( 2, 24 )
--
function SPAWN:InitLimit( SpawnMaxUnitsAlive, SpawnMaxGroups )
  self:F( { self.SpawnTemplatePrefix, SpawnMaxUnitsAlive, SpawnMaxGroups } )

  self.SpawnInitLimit = true
  self.SpawnMaxUnitsAlive = SpawnMaxUnitsAlive -- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
  self.SpawnMaxGroups = SpawnMaxGroups -- The maximum amount of groups that can be spawned.

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
  self:F()

  self.SpawnInitKeepUnitNames = KeepUnitNames or true

  return self
end

--- Flags that the spawned groups must be spawned late activated. 
-- @param #SPAWN self
-- @param #boolean LateActivated (optional) If true, the spawned groups are late activated.
-- @return #SPAWN self
function SPAWN:InitLateActivated( LateActivated )
  self:F()

  self.LateActivated = LateActivated or true

  return self
end

--- Set spawns to happen at a particular airbase. Only for aircraft, of course.
-- @param #SPAWN self
-- @param #string AirbaseName Name of the airbase.
-- @param #number Takeoff (Optional) Takeoff type. Can be SPAWN.Takeoff.Hot (default), SPAWN.Takeoff.Cold or SPAWN.Takeoff.Runway.
-- @param #number TerminalType (Optional) The terminal type.
-- @return #SPAWN self
function SPAWN:InitAirbase( AirbaseName, Takeoff, TerminalType )
  self:F()

  self.SpawnInitAirbase = AIRBASE:FindByName( AirbaseName )

  self.SpawnInitTakeoff = Takeoff or SPAWN.Takeoff.Hot

  self.SpawnInitTerminalType = TerminalType

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
--   Spawn = SPAWN:New( ... )
--
--   -- Spawn the units pointing to 100 degrees.
--   Spawn:InitHeading( 100 )
--
--   -- Spawn the units pointing between 100 and 150 degrees.
--   Spawn:InitHeading( 100, 150 )
--
function SPAWN:InitHeading( HeadingMin, HeadingMax )
  self:F()

  self.SpawnInitHeadingMin = HeadingMin
  self.SpawnInitHeadingMax = HeadingMax

  return self
end

--- Defines the heading of the overall formation of the new spawned group. 
-- The heading can be given as one fixed degree, or can be randomized between minimum and maximum degrees.
-- The Group's formation as laid out in its template will be rotated around the first unit in the group
-- Group individual units facings will rotate to match.  If InitHeading is also applied to this SPAWN then that will take precedence for individual unit facings.
-- Note that InitGroupHeading does *not* rotate the groups route; only its initial facing!
-- @param #SPAWN self
-- @param #number HeadingMin The minimum or fixed heading in degrees.
-- @param #number HeadingMax (optional) The maximum heading in degrees. This there is no maximum heading, then the heading for the group will be HeadingMin.
-- @param #number unitVar (optional) Individual units within the group will have their heading randomized by +/- unitVar degrees.  Default is zero.
-- @return #SPAWN self
-- @usage
--
-- mySpawner = SPAWN:New( ... )
--
--   -- Spawn the Group with the formation rotated +100 degrees around unit #1, compared to the mission template.
--   mySpawner:InitGroupHeading( 100 )
--
--   -- Spawn the Group with the formation rotated units between +100 and +150 degrees around unit #1, compared to the mission template, and with individual units varying by +/- 10 degrees from their templated facing.
--   mySpawner:InitGroupHeading( 100, 150, 10 )
--
--   -- Spawn the Group with the formation rotated -60 degrees around unit #1, compared to the mission template, but with all units facing due north regardless of how they were laid out in the template.
--   mySpawner:InitGroupHeading(-60):InitHeading(0)
--   -- or
--   mySpawner:InitHeading(0):InitGroupHeading(-60)
--
function SPAWN:InitGroupHeading( HeadingMin, HeadingMax, unitVar )
  self:F( { HeadingMin = HeadingMin, HeadingMax = HeadingMax, unitVar = unitVar } )

  self.SpawnInitGroupHeadingMin = HeadingMin
  self.SpawnInitGroupHeadingMax = HeadingMax
  self.SpawnInitGroupUnitVar = unitVar
  return self
end

--- Sets the coalition of the spawned group. Note that it might be necessary to also set the country explicitly!
-- @param #SPAWN self
-- @param DCS#coalition.side Coalition Coalition of the group as number of enumerator:
--
--   * @{DCS#coalition.side.NEUTRAL}
--   * @{DCS#coalition.side.RED}
--   * @{DCS#coalition.side.BLUE}
--  
-- @return #SPAWN self
function SPAWN:InitCoalition( Coalition )
  self:F( { coalition = Coalition } )

  self.SpawnInitCoalition = Coalition

  return self
end

--- Sets the country of the spawn group. Note that the country determines the coalition of the group depending on which country is defined to be on which side for each specific mission!
-- @param #SPAWN self
-- @param #number Country Country id as number or enumerator:
--
--   * @{DCS#country.id.RUSSIA}
--   * @{DCS#county.id.USA}
--
-- @return #SPAWN self
function SPAWN:InitCountry( Country )
  self:F()

  self.SpawnInitCountry = Country

  return self
end

--- Sets category ID of the group.
-- @param #SPAWN self
-- @param #number Category Category id.
-- @return #SPAWN self
function SPAWN:InitCategory( Category )
  self:F()

  self.SpawnInitCategory = Category

  return self
end

--- Sets livery of the group.
-- @param #SPAWN self
-- @param #string Livery Livery name. Note that this is not necessarily the same name as displayed in the mission editor.
-- @return #SPAWN self
function SPAWN:InitLivery( Livery )
  self:F( { livery = Livery } )

  self.SpawnInitLivery = Livery

  return self
end

--- Sets skill of the group.
-- @param #SPAWN self
-- @param #string Skill Skill, possible values "Average", "Good", "High", "Excellent" or "Random".
-- @return #SPAWN self
function SPAWN:InitSkill( Skill )
  self:F( { skill = Skill } )
  if Skill:lower() == "average" then
    self.SpawnInitSkill = "Average"
  elseif Skill:lower() == "good" then
    self.SpawnInitSkill = "Good"
  elseif Skill:lower() == "excellent" then
    self.SpawnInitSkill = "Excellent"
  elseif Skill:lower() == "random" then
    self.SpawnInitSkill = "Random"
  else
    self.SpawnInitSkill = "High"
  end

  return self
end

--- Sets the radio communication on or off. Same as checking/unchecking the COMM box in the mission editor.
-- @param #SPAWN self
-- @param #number switch If true (or nil), enables the radio communication. If false, disables the radio for the spawned group.
-- @return #SPAWN self
function SPAWN:InitRadioCommsOnOff( switch )
  self:F( { switch = switch } )
  self.SpawnInitRadio = switch or true
  return self
end

--- Sets the radio frequency of the group.
-- @param #SPAWN self 
-- @param #number frequency The frequency in MHz.
-- @return #SPAWN self
function SPAWN:InitRadioFrequency( frequency )
  self:F( { frequency = frequency } )

  self.SpawnInitFreq = frequency

  return self
end

--- Set radio modulation. Default is AM.
-- @param #SPAWN self
-- @param #string modulation Either "FM" or "AM". If no value is given, modulation is set to AM.
-- @return #SPAWN self
function SPAWN:InitRadioModulation( modulation )
  self:F( { modulation = modulation } )
  if modulation and modulation:lower() == "fm" then
    self.SpawnInitModu = radio.modulation.FM
  else
    self.SpawnInitModu = radio.modulation.AM
  end
  return self
end

--- Sets the modex of the first unit of the group. If more units are in the group, the number is increased by one with every unit.
-- @param #SPAWN self
-- @param #number modex Modex of the first unit.
-- @return #SPAWN self
function SPAWN:InitModex( modex )

  if modex then
    self.SpawnInitModex = tonumber( modex )
  end

  return self
end

--- Randomizes the defined route of the SpawnTemplatePrefix group in the ME. This is very useful to define extra variation of the behavior of groups.
-- @param #SPAWN self
-- @param #number SpawnStartPoint is the waypoint where the randomization begins.
-- Note that the StartPoint = 0 equaling the point where the group is spawned.
-- @param #number SpawnEndPoint is the waypoint where the randomization ends counting backwards.
-- This parameter is useful to avoid randomization to end at a waypoint earlier than the last waypoint on the route.
-- @param #number SpawnRadius is the radius in meters in which the randomization of the new waypoints, with the original waypoint of the original template located in the middle ...
-- @param #number SpawnHeight (optional) Specifies the **additional** height in meters that can be added to the base height specified at each waypoint in the ME.
-- @return #SPAWN
-- @usage
--
--   -- NATO helicopters engaging in the battle field.
--   -- The KA-50 has waypoints Start point ( =0 or SP ), 1, 2, 3, 4, End point (= 5 or DP).
--   -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new spawn of the helicopter.
--   -- The randomization of waypoint 2 and 3 will take place within a radius of 2000 meters.
--   Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitRandomizeRoute( 2, 2, 2000 )
--
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
-- @param #boolean RandomizeUnits If true, SPAWN will perform the randomization of the @{Wrapper.Unit#UNIT}s position within the group between a given outer and inner radius.
-- @param DCS#Distance OuterRadius (optional) The outer radius in meters where the new group will be spawned.
-- @param DCS#Distance InnerRadius (optional) The inner radius in meters where the new group will NOT be spawned.
-- @return #SPAWN
-- @usage
--
--   -- NATO helicopters engaging in the battle field.
--   -- UNIT positions of this group will be randomized around the base unit #1 in a circle of 50 to 500 meters.
--   Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitRandomizeUnits( true, 500, 50 )
--
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

--- Spawn the UNITs of this group with individual relative positions to unit #1 and individual headings.
-- @param #SPAWN self
-- @param #table Positions Table of positions, needs to one entry per unit in the group(!). The table contains one table each for each unit, with x,y, and optionally z 
-- relative positions, and optionally an individual heading.
-- @return #SPAWN
-- @usage
--
--   -- NATO helicopter group of three units engaging in the battle field.
--   local Positions = { [1] = {x = 0, y = 0, heading = 0}, [2] = {x = 50, y = 50, heading = 90}, [3] = {x = -50, y = 50, heading = 180} }
--   Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitSetUnitRelativePositions(Positions)
--
function SPAWN:InitSetUnitRelativePositions(Positions)
  self:F({self.SpawnTemplatePrefix, Positions})
  
  self.SpawnUnitsWithRelativePositions = true
  self.UnitsRelativePositions = Positions
  
  return self
end

--- Spawn the UNITs of this group with individual absolute positions and individual headings.
-- @param #SPAWN self
-- @param #table Positions Table of positions, needs to one entry per unit in the group(!). The table contains one table each for each unit, with x,y, and optionally z 
-- absolute positions, and optionally an individual heading.
-- @return #SPAWN
-- @usage
--
--   -- NATO helicopter group of three units engaging in the battle field.
--   local Positions = { [1] = {x = 0, y = 0, heading = 0}, [2] = {x = 50, y = 50, heading = 90}, [3] = {x = -50, y = 50, heading = 180} }
--   Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):InitSetUnitAbsolutePositions(Positions)
--
function SPAWN:InitSetUnitAbsolutePositions(Positions)
  self:F({self.SpawnTemplatePrefix, Positions})
  
  self.SpawnUnitsWithAbsolutePositions = true
  self.UnitsAbsolutePositions = Positions
  
  return self
end

--- This method is rather complicated to understand. But I'll try to explain.
-- This method becomes useful when you need to spawn groups with random templates of groups defined within the mission editor,
-- but they will all follow the same Template route and have the same prefix name.
-- In other words, this method randomizes between a defined set of groups the template to be used for each new spawn of a group.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefixTable A table with the names of the groups defined within the mission editor, from which one will be chosen when a new group will be spawned.
-- @return #SPAWN
-- @usage
--
--   -- NATO Tank Platoons invading Gori.
--   -- Choose between 13 different 'US Tank Platoon' configurations for each new SPAWN the Group to be spawned for the
--   -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SpawnTemplatePrefixes.
--   -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and
--   -- with a limit set of maximum 12 Units alive simultaneously  and 150 Groups to be spawned during the whole mission.
--   Spawn_US_Platoon = { 'US Tank Platoon 1', 'US Tank Platoon 2', 'US Tank Platoon 3', 'US Tank Platoon 4', 'US Tank Platoon 5',
--                        'US Tank Platoon 6', 'US Tank Platoon 7', 'US Tank Platoon 8', 'US Tank Platoon 9', 'US Tank Platoon 10',
--                        'US Tank Platoon 11', 'US Tank Platoon 12', 'US Tank Platoon 13' }
--   Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplate( Spawn_US_Platoon ):InitRandomizeRoute( 3, 3, 2000 )
--   Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplate( Spawn_US_Platoon ):InitRandomizeRoute( 3, 3, 2000 )
--   Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplate( Spawn_US_Platoon ):InitRandomizeRoute( 3, 3, 2000 )
function SPAWN:InitRandomizeTemplate( SpawnTemplatePrefixTable )
  self:F( { self.SpawnTemplatePrefix, SpawnTemplatePrefixTable } )
  
  local temptable = {}
  for _,_temp in pairs(SpawnTemplatePrefixTable) do
    temptable[#temptable+1] = _temp
  end
  
  self.SpawnTemplatePrefixTable = UTILS.ShuffleTable(temptable)
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
--
--   -- NATO Tank Platoons invading Gori.
--
--   -- Choose between different 'US Tank Platoon Template' configurations to be spawned for the
--   -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SPAWN objects.
--
--   -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and
--   -- with a limit set of maximum 12 Units alive simultaneously  and 150 Groups to be spawned during the whole mission.
--
--   Spawn_US_PlatoonSet = SET_GROUP:New():FilterPrefixes( "US Tank Platoon Templates" ):FilterOnce()
--
--   -- Now use the Spawn_US_PlatoonSet to define the templates using InitRandomizeTemplateSet.
--   Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplateSet( Spawn_US_PlatoonSet ):InitRandomizeRoute( 3, 3, 2000 )
--   Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplateSet( Spawn_US_PlatoonSet ):InitRandomizeRoute( 3, 3, 2000 )
--   Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplateSet( Spawn_US_PlatoonSet ):InitRandomizeRoute( 3, 3, 2000 )
--
function SPAWN:InitRandomizeTemplateSet( SpawnTemplateSet )
  self:F( { self.SpawnTemplatePrefix } )

  local setnames = SpawnTemplateSet:GetSetNames()
  self:InitRandomizeTemplate(setnames)
  
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
--
--  -- NATO Tank Platoons invading Gori.
--
--   -- Choose between different 'US Tank Platoon Templates' configurations to be spawned for the
--   -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SPAWN objects.
--
--   -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and
--   -- with a limit set of maximum 12 Units alive simultaneously  and 150 Groups to be spawned during the whole mission.
--
--   Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplatePrefixes( "US Tank Platoon Templates" ):InitRandomizeRoute( 3, 3, 2000 )
--   Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplatePrefixes( "US Tank Platoon Templates" ):InitRandomizeRoute( 3, 3, 2000 )
--   Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):InitLimit( 12, 150 ):SpawnScheduled( 200, 0.4 ):InitRandomizeTemplatePrefixes( "US Tank Platoon Templates" ):InitRandomizeRoute( 3, 3, 2000 )
--
function SPAWN:InitRandomizeTemplatePrefixes( SpawnTemplatePrefixes ) -- R2.3
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

--- This method provides the functionality to randomize the spawning of the Groups at a given list of zones of different types.
-- @param #SPAWN self
-- @param #table SpawnZoneTable A table with @{Core.Zone} objects. If this table is given, then each spawn will be executed within the given list of @{Core.Zone}s objects.
-- @return #SPAWN self
-- @usage
--
--    -- Create a zone table of the 2 zones.
--    ZoneTable = { ZONE:New( "Zone1" ), ZONE:New( "Zone2" ) }
--
--    Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" )
--                           :InitLimit( 10, 10 )
--                           :InitRandomizeRoute( 1, 1, 200 )
--                           :InitRandomizeZones( ZoneTable )
--                           :SpawnScheduled( 5, .5 )
--
function SPAWN:InitRandomizeZones( SpawnZoneTable )
  self:F( { self.SpawnTemplatePrefix, SpawnZoneTable } )
  
  local temptable = {}
  for _,_temp in pairs(SpawnZoneTable) do
    temptable[#temptable+1] = _temp
  end
  
  self.SpawnZoneTable = UTILS.ShuffleTable(temptable)
  self.SpawnRandomizeZones = true

  for SpawnGroupID = 1, self.SpawnMaxGroups do
    self:_RandomizeZones( SpawnGroupID )
  end

  return self
end

--- This method sets a spawn position for the group that is different from the location of the template.
-- @param #SPAWN self
-- @param Core.Point#COORDINATE Coordinate The position to spawn from
-- @return #SPAWN self
function SPAWN:InitPositionCoordinate(Coordinate)
  self:T( { self.SpawnTemplatePrefix, Coordinate:GetVec2()} )
  self:InitPositionVec2(Coordinate:GetVec2())
  return self
end

--- This method sets a spawn position for the group that is different from the location of the template.
-- @param #SPAWN self
-- @param DCS#Vec2 Vec2 The position to spawn from
-- @return #SPAWN self
function SPAWN:InitPositionVec2(Vec2)
  self:T( { self.SpawnTemplatePrefix, Vec2} )
  self.SpawnInitPosition = Vec2
  self.SpawnFromNewPosition = true
  self:I("MaxGroups:"..self.SpawnMaxGroups)
  for SpawnGroupID = 1, self.SpawnMaxGroups do
    self:_SetInitialPosition( SpawnGroupID )
  end
  return self
end

--- For planes and helicopters, when these groups go home and land on their home airbases and FARPs, they normally would taxi to the parking spot, shut-down their engines and wait forever until the Group is removed by the runtime environment.
-- This method is used to re-spawn automatically (so no extra call is needed anymore) the same group after it has landed.
-- This will enable a spawned group to be re-spawned after it lands, until it is destroyed...
-- Note: When the group is respawned, it will re-spawn from the original airbase where it took off.
-- So ensure that the routes for groups that respawn, always return to the original airbase, or players may get confused ...
-- @param #SPAWN self
-- @return #SPAWN self
-- @usage
--
--   -- RU Su-34 - AI Ship Attack
--   -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically.
--   SpawnRU_SU34 = SPAWN:New( 'Su-34' )
--                       :Schedule( 2, 3, 1800, 0.4 )
--                       :SpawnUncontrolled()
--                       :InitRandomizeRoute( 1, 1, 3000 )
--                       :InitRepeatOnEngineShutDown()
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
--
--   -- RU Su-34 - AI Ship Attack
--   -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically.
--   SpawnRU_SU34 = SPAWN:New( 'Su-34' )
--                       :InitRandomizeRoute( 1, 1, 3000 )
--                       :InitRepeatOnLanding()
--                       :Spawn()
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
--
--   -- RU Su-34 - AI Ship Attack
--   -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically.
--   SpawnRU_SU34 = SPAWN:New( 'Su-34' )
--                       :SpawnUncontrolled()
--                       :InitRandomizeRoute( 1, 1, 3000 )
--                       :InitRepeatOnEngineShutDown()
--                       :Spawn()
function SPAWN:InitRepeatOnEngineShutDown()
  self:F( { self.SpawnTemplatePrefix } )

  self:InitRepeat()
  self.RepeatOnEngineShutDown = true
  self.RepeatOnLanding = false

  return self
end

--- Delete groups that have not moved for X seconds - AIR ONLY!!!
-- DO NOT USE ON GROUPS THAT DO NOT MOVE OR YOUR SERVER WILL BURN IN HELL (Pikes - April 2020)
-- When groups are still alive and have become inactive due to damage and are unable to contribute anything, then this group will be removed at defined intervals in seconds.
-- @param #SPAWN self
-- @param #string SpawnCleanUpInterval The interval to check for inactive groups within seconds.
-- @return #SPAWN self
-- @usage
--
--   Spawn_Helicopter:InitCleanUp( 20 )  -- CleanUp the spawning of the helicopters every 20 seconds when they become inactive.
--
function SPAWN:InitCleanUp( SpawnCleanUpInterval )
  self:F( { self.SpawnTemplatePrefix, SpawnCleanUpInterval } )

  self.SpawnCleanUpInterval = SpawnCleanUpInterval
  self.SpawnCleanUpTimeStamps = {}

  local SpawnGroup, SpawnCursor = self:GetFirstAliveGroup()
  self:T( { "CleanUp Scheduler:", SpawnGroup } )

  -- self.CleanUpFunction = routines.scheduleFunction( self._SpawnCleanUpScheduler, { self }, timer.getTime() + 1, SpawnCleanUpInterval )
  self.CleanUpScheduler = SCHEDULER:New( self, self._SpawnCleanUpScheduler, {}, 1, SpawnCleanUpInterval, 0.2 )
  return self
end

--- Makes the groups visible before start (like a battalion).
-- The method will take the position of the group as the first position in the array.
-- CAUTION: this directive will NOT work with OnSpawnGroup function.
-- @param #SPAWN self
-- @param #number SpawnAngle The angle in degrees how the groups and each unit of the group will be positioned.
-- @param #number SpawnWidth The amount of Groups that will be positioned on the X axis.
-- @param #number SpawnDeltaX The space between each Group on the X-axis.
-- @param #number SpawnDeltaY The space between each Group on the Y-axis.
-- @return #SPAWN self
-- @usage
--
--   -- Define an array of Groups.
--   Spawn_BE_Ground = SPAWN:New( 'BE Ground' )
--                          :InitLimit( 2, 24 )
--                          :InitArray( 90, 10, 100, 50 )
--
function SPAWN:InitArray( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY )
  self:F( { self.SpawnTemplatePrefix, SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY } )

  self.SpawnVisible = true -- When the first Spawn executes, all the Groups need to be made visible before start.

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
    self:HandleEvent( EVENTS.RemoveUnit, self._OnDeadOrCrash )
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

  --- Turns the Delay On for the @{Wrapper.Group} when spawning with @{SpawnScheduled}(). In effect then the 1st group will only be spawned
  -- after the number of seconds given in SpawnScheduled as arguments, and not immediately.
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
-- Note: This method uses the global _DATABASE object (an instance of @{Core.Database#DATABASE}), which contains ALL initial and new spawned objects in MOOSE.
-- @param #SPAWN self
-- @return Wrapper.Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:Spawn()
  self:F( { self.SpawnTemplatePrefix, self.SpawnIndex, self.AliveUnits } )

  if self.SpawnInitAirbase then
    return self:SpawnAtAirbase( self.SpawnInitAirbase, self.SpawnInitTakeoff, nil, self.SpawnInitTerminalType )
  else
    return self:SpawnWithIndex( self.SpawnIndex + 1 )
  end

end

--- Will re-spawn a group based on a given index.
-- Note: This method uses the global _DATABASE object (an instance of @{Core.Database#DATABASE}), which contains ALL initial and new spawned objects in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group to be spawned.
-- @return Wrapper.Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:ReSpawn( SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

  if not SpawnIndex then
    SpawnIndex = 1
  end

  -- TODO: This logic makes DCS crash and i don't know why (yet). -- ED (Pikes -- not in the least bit scary to see this, right?)
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

--- Set the spawn index to a specified index number.
-- This method can be used to "reset" the spawn counter to a specific index number.
-- This will actually enable a respawn of groups from the specific index.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group from where the spawning will start again. The default value would be 0, which means a complete reset of the spawnindex.
-- @return #SPAWN self
function SPAWN:SetSpawnIndex( SpawnIndex )
  self.SpawnIndex = SpawnIndex or 0
end

--- Will spawn a group with a specified index number.
-- Note: This method uses the global _DATABASE object (an instance of @{Core.Database#DATABASE}), which contains ALL initial and new spawned objects in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group to be spawned.
-- @return Wrapper.Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:SpawnWithIndex( SpawnIndex, NoBirth )
  self:F2( { SpawnTemplatePrefix = self.SpawnTemplatePrefix, SpawnIndex = SpawnIndex, AliveUnits = self.AliveUnits, SpawnMaxGroups = self.SpawnMaxGroups } )

  if self:_GetSpawnIndex( SpawnIndex ) then
    
    if self.SpawnFromNewPosition then
     self:_SetInitialPosition( SpawnIndex )
    end
      
      
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
            SpawnTemplate.units[UnitID].x = SpawnTemplate.units[UnitID].x + (RandomVec2.x - CurrentX)
            SpawnTemplate.units[UnitID].y = SpawnTemplate.units[UnitID].y + (RandomVec2.y - CurrentY)
            self:T( 'SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )
          end
        end

        -- If RandomizeUnits, then Randomize the formation at the start point.
        if self.SpawnRandomizeUnits then
          for UnitID = 1, #SpawnTemplate.units do
            local RandomVec2 = PointVec3:GetRandomVec2InRadius( self.SpawnOuterRadius, self.SpawnInnerRadius )
            SpawnTemplate.units[UnitID].x = RandomVec2.x
            SpawnTemplate.units[UnitID].y = RandomVec2.y
            self:T( 'SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )
          end
        end

        -- Get correct heading in Radians.
        local function _Heading( courseDeg )
          local h
          if courseDeg <= 180 then
            h = math.rad( courseDeg )
          else
            h = -math.rad( 360 - courseDeg )
          end
          return h
        end

        local Rad180 = math.rad( 180 )
        local function _HeadingRad( courseRad )
          if courseRad <= Rad180 then
            return courseRad
          else
            return -((2 * Rad180) - courseRad)
          end
        end

        -- Generate a random value somewhere between two floating point values.
        local function _RandomInRange( min, max )
          if min and max then
            return min + (math.random() * (max - min))
          else
            return min
          end
        end

        -- Apply InitGroupHeading rotation if requested.
        -- We do this before InitHeading unit rotation so that can take precedence
        -- NOTE: Does *not* rotate the groups route; only its initial facing.
        if self.SpawnInitGroupHeadingMin and #SpawnTemplate.units > 0 then

          local pivotX = SpawnTemplate.units[1].x -- unit #1 is the pivot point
          local pivotY = SpawnTemplate.units[1].y

          local headingRad = math.rad( _RandomInRange( self.SpawnInitGroupHeadingMin or 0, self.SpawnInitGroupHeadingMax ) )
          local cosHeading = math.cos( headingRad )
          local sinHeading = math.sin( headingRad )

          local unitVarRad = math.rad( self.SpawnInitGroupUnitVar or 0 )

          for UnitID = 1, #SpawnTemplate.units do

            if UnitID > 1 then -- don't rotate position of unit #1
              local unitXOff = SpawnTemplate.units[UnitID].x - pivotX -- rotate position offset around unit #1
              local unitYOff = SpawnTemplate.units[UnitID].y - pivotY

              SpawnTemplate.units[UnitID].x = pivotX + (unitXOff * cosHeading) - (unitYOff * sinHeading)
              SpawnTemplate.units[UnitID].y = pivotY + (unitYOff * cosHeading) + (unitXOff * sinHeading)
            end

            -- adjust heading of all units, including unit #1
            local unitHeading = SpawnTemplate.units[UnitID].heading + headingRad -- add group rotation to units default rotation
            SpawnTemplate.units[UnitID].heading = _HeadingRad( _RandomInRange( unitHeading - unitVarRad, unitHeading + unitVarRad ) )
            SpawnTemplate.units[UnitID].psi = -SpawnTemplate.units[UnitID].heading

          end

        end

        -- If Heading is given, point all the units towards the given Heading.  Overrides any heading set in InitGroupHeading above.
        if self.SpawnInitHeadingMin then
          for UnitID = 1, #SpawnTemplate.units do
            SpawnTemplate.units[UnitID].heading = _Heading( _RandomInRange( self.SpawnInitHeadingMin, self.SpawnInitHeadingMax ) )
            SpawnTemplate.units[UnitID].psi = -SpawnTemplate.units[UnitID].heading
          end
        end
        
        -- Individual relative unit positions + heading
        if self.SpawnUnitsWithRelativePositions and self.UnitsRelativePositions then
          local BaseX = SpawnTemplate.units[1].x or 0
          local BaseY = SpawnTemplate.units[1].y or 0
          local BaseZ = SpawnTemplate.units[1].z or 0 
          for UnitID = 1, #SpawnTemplate.units do
            if self.UnitsRelativePositions[UnitID].heading then
              SpawnTemplate.units[UnitID].heading = math.rad(self.UnitsRelativePositions[UnitID].heading or 0)
            end
            SpawnTemplate.units[UnitID].x = BaseX + (self.UnitsRelativePositions[UnitID].x or 0)
            SpawnTemplate.units[UnitID].y = BaseY  + (self.UnitsRelativePositions[UnitID].y or 0)
            if self.UnitsRelativePositions[UnitID].z then
              SpawnTemplate.units[UnitID].z =  BaseZ + (self.UnitsRelativePositions[UnitID].z or 0)
            end
          end
        end
        
       -- Individual asbolute unit positions + heading
        if self.SpawnUnitsWithAbsolutePositions and self.UnitsAbsolutePositions then
          for UnitID = 1, #SpawnTemplate.units do
            if self.UnitsAbsolutePositions[UnitID].heading then
              SpawnTemplate.units[UnitID].heading = math.rad(self.UnitsAbsolutePositions[UnitID].heading or 0)
            end
            SpawnTemplate.units[UnitID].x = self.UnitsAbsolutePositions[UnitID].x or 0
            SpawnTemplate.units[UnitID].y = self.UnitsAbsolutePositions[UnitID].y or 0
            if self.UnitsAbsolutePositions[UnitID].z then
              SpawnTemplate.units[UnitID].z = self.UnitsAbsolutePositions[UnitID].z or 0
            end
          end
        end
        
        -- Set livery.
        if self.SpawnInitLivery then
          for UnitID = 1, #SpawnTemplate.units do
            SpawnTemplate.units[UnitID].livery_id = self.SpawnInitLivery
          end
        end

        -- Set skill.
        if self.SpawnInitSkill then
          for UnitID = 1, #SpawnTemplate.units do
            SpawnTemplate.units[UnitID].skill = self.SpawnInitSkill
          end
        end

        -- Set tail number.
        if self.SpawnInitModex then
          for UnitID = 1, #SpawnTemplate.units do
            SpawnTemplate.units[UnitID].onboard_num = string.format( "%03d", self.SpawnInitModex + (UnitID - 1) )
          end
        end

        -- Set radio comms on/off.
        if self.SpawnInitRadio then
          SpawnTemplate.communication = self.SpawnInitRadio
        end

        -- Set radio frequency.
        if self.SpawnInitFreq then
          SpawnTemplate.frequency = self.SpawnInitFreq
        end

        -- Set radio modulation.
        if self.SpawnInitModu then
          SpawnTemplate.modulation = self.SpawnInitModu
        end

        -- Set country, coalition and category.
        SpawnTemplate.CategoryID = self.SpawnInitCategory or SpawnTemplate.CategoryID
        SpawnTemplate.CountryID = self.SpawnInitCountry or SpawnTemplate.CountryID
        SpawnTemplate.CoalitionID = self.SpawnInitCoalition or SpawnTemplate.CoalitionID

        --        if SpawnTemplate.CategoryID == Group.Category.HELICOPTER or SpawnTemplate.CategoryID == Group.Category.AIRPLANE then
        --          if SpawnTemplate.route.points[1].type == "TakeOffParking" then
        --            SpawnTemplate.uncontrolled = self.SpawnUnControlled
        --          end
        --        end
      end

      if not NoBirth then
        self:HandleEvent( EVENTS.Birth, self._OnBirth )
      end
      self:HandleEvent( EVENTS.Dead, self._OnDeadOrCrash )
      self:HandleEvent( EVENTS.Crash, self._OnDeadOrCrash )
      self:HandleEvent( EVENTS.RemoveUnit, self._OnDeadOrCrash )
      if self.Repeat then
        self:HandleEvent( EVENTS.Takeoff, self._OnTakeOff )
        self:HandleEvent( EVENTS.Land, self._OnLand )
      end
      if self.RepeatOnEngineShutDown then
        self:HandleEvent( EVENTS.EngineShutdown, self._OnEngineShutDown )
      end

      self.SpawnGroups[self.SpawnIndex].Group = _DATABASE:Spawn( SpawnTemplate )

      local SpawnGroup = self.SpawnGroups[self.SpawnIndex].Group -- Wrapper.Group#GROUP

      -- TODO: Need to check if this function doesn't need to be scheduled, as the group may not be immediately there!
      if SpawnGroup then

        SpawnGroup:SetAIOnOff( self.AIOnOff )
      end

      self:T3( SpawnTemplate.name )

      -- If there is a SpawnFunction hook defined, call it.
      if self.SpawnFunctionHook then
        -- delay calling this for .1 seconds so that it hopefully comes after the BIRTH event of the group.
        self.SpawnHookScheduler:Schedule( nil, self.SpawnFunctionHook, { self.SpawnGroups[self.SpawnIndex].Group, unpack( self.SpawnFunctionArguments ) }, 0.1 )
      end
      -- TODO: Need to fix this by putting an "R" in the name of the group when the group repeats.
      -- if self.Repeat then
      --  _DATABASE:SetStatusGroup( SpawnTemplate.name, "ReSpawn" )
      -- end
    end

    self.SpawnGroups[self.SpawnIndex].Spawned = true
    return self.SpawnGroups[self.SpawnIndex].Group
  else
    -- self:E( { self.SpawnTemplatePrefix, "No more Groups to Spawn:", SpawnIndex, self.SpawnMaxGroups } )
  end

  return nil
end

--- Spawns new groups at varying time intervals.
-- This is useful if you want to have continuity within your missions of certain (AI) groups to be present (alive) within your missions.
-- @param #SPAWN self
-- @param #number SpawnTime The time interval defined in seconds between each new spawn of new groups.
-- @param #number SpawnTimeVariation The variation to be applied on the defined time interval between each new spawn.
-- The variation is a number between 0 and 1, representing the % of variation to be applied on the time interval.
-- @param #boolean WithDelay Do not spawn the **first** group immediately, but delay the spawn as per the calculation below.
-- Effectively the same as @{InitDelayOn}().
-- @return #SPAWN self
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- The time interval is set to SPAWN new helicopters between each 600 seconds, with a time variation of 50%.
-- -- The time variation in this case will be between 450 seconds and 750 seconds.
-- -- This is calculated as follows:
-- --      Low limit:   600 * ( 1 - 0.5 / 2 ) = 450
-- --      High limit:  600 * ( 1 + 0.5 / 2 ) = 750
-- -- Between these two values, a random amount of seconds will be chosen for each new spawn of the helicopters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):SpawnScheduled( 600, 0.5 )
function SPAWN:SpawnScheduled( SpawnTime, SpawnTimeVariation, WithDelay )
  self:F( { SpawnTime, SpawnTimeVariation } )
  
  local SpawnTime = SpawnTime or 60
  local SpawnTimeVariation = SpawnTimeVariation or 0.5
  
  if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
    local InitialDelay = 0
    if WithDelay or self.DelayOnOff == true then
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
--
--    -- Declare SpawnObject and call a function when a new Group is spawned.
--    local SpawnObject = SPAWN:New( "SpawnObject" )
--                             :InitLimit( 2, 10 )
--                             :OnSpawnGroup( function( SpawnGroup )
--                                 SpawnGroup:E( "I am spawned" )
--                                 end
--                               )
--                             :SpawnScheduled( 300, 0.3 )
--
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
-- Ships and FARPs are added within the mission, and are therefore not known.
-- For these AIRBASE objects, there isn't an @{Wrapper.Airbase#AIRBASE} enumeration defined.
-- You need to provide the **exact name** of the airbase as the parameter to the @{Wrapper.Airbase#AIRBASE.FindByName}() method!
--
-- @param #SPAWN self
-- @param Wrapper.Airbase#AIRBASE SpawnAirbase The @{Wrapper.Airbase} where to spawn the group.
-- @param #SPAWN.Takeoff Takeoff (optional) The location and takeoff method. Default is Hot.
-- @param #number TakeoffAltitude (optional) The altitude above the ground.
-- @param Wrapper.Airbase#AIRBASE.TerminalType TerminalType (optional) The terminal type the aircraft should be spawned at. See @{Wrapper.Airbase#AIRBASE.TerminalType}.
-- @param #boolean EmergencyAirSpawn (optional) If true (default), groups are spawned in air if there is no parking spot at the airbase. If false, nothing is spawned if no parking spot is available.
-- @param #table Parkingdata (optional) Table holding the coordinates and terminal ids for all units of the group. Spawning will be forced to happen at exactly these spots!
-- @return Wrapper.Group#GROUP The group that was spawned or nil when nothing was spawned.
-- @usage
--
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
--   Spawn_Plane:SpawnAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Krymsk ), SPAWN.Takeoff.Cold, nil, AIRBASE.TerminalType.OpenBig )
--
function SPAWN:SpawnAtAirbase( SpawnAirbase, Takeoff, TakeoffAltitude, TerminalType, EmergencyAirSpawn, Parkingdata ) -- R2.2, R2.4
  self:F( { self.SpawnTemplatePrefix, SpawnAirbase, Takeoff, TakeoffAltitude, TerminalType } )

  -- Get position of airbase.
  local PointVec3 = SpawnAirbase:GetCoordinate()
  self:T2( PointVec3 )

  -- Set take off type. Default is hot.
  Takeoff = Takeoff or SPAWN.Takeoff.Hot

  -- By default, groups are spawned in air if no parking spot is available.
  if EmergencyAirSpawn == nil then
    EmergencyAirSpawn = true
  end

  self:F( { SpawnIndex = self.SpawnIndex } )

  if self:_GetSpawnIndex( self.SpawnIndex + 1 ) then

    -- Get group template.
    local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate

    self:F( { SpawnTemplate = SpawnTemplate } )

    if SpawnTemplate then

      -- Check if the aircraft with the specified SpawnIndex is already spawned.
      -- If yes, ensure that the aircraft is spawned at the same aircraft spot.

      local GroupAlive = self:GetGroupFromIndex( self.SpawnIndex )

      self:F( { GroupAlive = GroupAlive } )

      -- Debug output
      self:T( { "Current point of ", self.SpawnTemplatePrefix, SpawnAirbase } )

      -- Template group, unit and its attributes.
      local TemplateGroup = GROUP:FindByName( self.SpawnTemplatePrefix )
      local TemplateUnit = TemplateGroup:GetUnit( 1 )

      -- General category of spawned group.
      local group = TemplateGroup
      local istransport = group:HasAttribute( "Transports" ) and group:HasAttribute( "Planes" )
      local isawacs = group:HasAttribute( "AWACS" )
      local isfighter = group:HasAttribute( "Fighters" ) or group:HasAttribute( "Interceptors" ) or group:HasAttribute( "Multirole fighters" ) or (group:HasAttribute( "Bombers" ) and not group:HasAttribute( "Strategic bombers" ))
      local isbomber = group:HasAttribute( "Strategic bombers" )
      local istanker = group:HasAttribute( "Tankers" )
      local ishelo = TemplateUnit:HasAttribute( "Helicopters" )

      -- Number of units in the group. With grouping this can actually differ from the template group size!
      local nunits = #SpawnTemplate.units

      -- First waypoint of the group.
      local SpawnPoint = SpawnTemplate.route.points[1]

      -- These are only for ships and FARPS.
      SpawnPoint.linkUnit = nil
      SpawnPoint.helipadId = nil
      SpawnPoint.airdromeId = nil

      -- Get airbase ID and category.
      local AirbaseID = SpawnAirbase:GetID()
      local AirbaseCategory = SpawnAirbase:GetAirbaseCategory()
      self:F( { AirbaseCategory = AirbaseCategory } )

      -- Set airdromeId.
      if AirbaseCategory == Airbase.Category.SHIP then
        SpawnPoint.linkUnit = AirbaseID
        SpawnPoint.helipadId = AirbaseID
      elseif AirbaseCategory == Airbase.Category.HELIPAD then
        SpawnPoint.linkUnit = AirbaseID
        SpawnPoint.helipadId = AirbaseID
      elseif AirbaseCategory == Airbase.Category.AIRDROME then
        SpawnPoint.airdromeId = AirbaseID
      end

      -- Set waypoint type/action.
      SpawnPoint.alt = 0
      SpawnPoint.type = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
      SpawnPoint.action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action

      -- Check if we spawn on ground. 
      local spawnonground = not (Takeoff == SPAWN.Takeoff.Air)
      self:T( { spawnonground = spawnonground, TOtype = Takeoff, TOair = Takeoff == SPAWN.Takeoff.Air } )

      -- Check where we actually spawn if we spawn on ground.
      local spawnonship = false
      local spawnonfarp = false
      local spawnonrunway = false
      local spawnonairport = false
      if spawnonground then
        if AirbaseCategory == Airbase.Category.SHIP then
          spawnonship = true
        elseif AirbaseCategory == Airbase.Category.HELIPAD then
          spawnonfarp = true
        elseif AirbaseCategory == Airbase.Category.AIRDROME then
          spawnonairport = true
        end
        spawnonrunway = Takeoff == SPAWN.Takeoff.Runway
      end

      -- Array with parking spots coordinates.
      local parkingspots = {}
      local parkingindex = {}
      local spots

      -- Spawn happens on ground, i.e. at an airbase, a FARP or a ship.
      if spawnonground and not SpawnTemplate.parked then

        -- Number of free parking spots.
        local nfree = 0

        -- Set terminal type.
        local termtype = TerminalType
        if spawnonrunway then
          if spawnonship then
            -- Looks like there are no runway spawn spots on the stennis!
            if ishelo then
              termtype = AIRBASE.TerminalType.HelicopterUsable
            else
              termtype = AIRBASE.TerminalType.OpenMedOrBig
            end
          else
            termtype = AIRBASE.TerminalType.Runway
          end
        end

        -- Scan options. Might make that input somehow.
        local scanradius = 50
        local scanunits = true
        local scanstatics = true
        local scanscenery = false
        local verysafe = false

        -- Number of free parking spots at the airbase.
        if spawnonship or spawnonfarp or spawnonrunway then
          -- These places work procedural and have some kind of build in queue ==> Less effort.
          self:T( string.format( "Group %s is spawned on farp/ship/runway %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )
          nfree = SpawnAirbase:GetFreeParkingSpotsNumber( termtype, true )
          spots = SpawnAirbase:GetFreeParkingSpotsTable( termtype, true )
          --[[
        elseif Parkingdata~=nil then
          -- Parking data explicitly set by user as input parameter.
          nfree=#Parkingdata
          spots=Parkingdata
        ]]
        else
          if ishelo then
            if termtype == nil then
              -- Helo is spawned. Try exclusive helo spots first.
              self:T( string.format( "Helo group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.HelicopterOnly ) )
              spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.HelicopterOnly, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
              nfree = #spots
              if nfree < nunits then
                -- Not enough helo ports. Let's try also other terminal types.
                self:T( string.format( "Helo group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.HelicopterUsable ) )
                spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.HelicopterUsable, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
                nfree = #spots
              end
            else
              -- No terminal type specified. We try all spots except shelters.
              self:T( string.format( "Helo group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), termtype ) )
              spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, termtype, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
              nfree = #spots
            end
          else
            -- Fixed wing aircraft is spawned.
            if termtype == nil then
              if isbomber or istransport or istanker or isawacs then
                -- First we fill the potentially bigger spots.
                self:T( string.format( "Transport/bomber group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.OpenBig ) )
                spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.OpenBig, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
                nfree = #spots
                if nfree < nunits then
                  -- Now we try the smaller ones.
                  self:T( string.format( "Transport/bomber group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.OpenMedOrBig ) )
                  spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.OpenMedOrBig, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
                  nfree = #spots
                end
              else
                self:T( string.format( "Fighter group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.FighterAircraft ) )
                spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.FighterAircraft, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
                nfree = #spots
              end
            else
              -- Terminal type explicitly given.
              self:T( string.format( "Plane group %s is at %s using terminal type %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), tostring( termtype ) ) )
              spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, termtype, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
              nfree = #spots
            end
          end
        end

        -- Debug: Get parking data.
        --[[
        local parkingdata=SpawnAirbase:GetParkingSpotsTable(termtype)
        self:T(string.format("Parking at %s, terminal type %s:", SpawnAirbase:GetName(), tostring(termtype)))
        for _,_spot in pairs(parkingdata) do
          self:T(string.format("%s, Termin Index = %3d, Term Type = %03d, Free = %5s, TOAC = %5s, Term ID0 = %3d, Dist2Rwy = %4d",
          SpawnAirbase:GetName(), _spot.TerminalID, _spot.TerminalType,tostring(_spot.Free),tostring(_spot.TOAC),_spot.TerminalID0,_spot.DistToRwy))
        end
        self:T(string.format("%s at %s: free parking spots = %d - number of units = %d", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), nfree, nunits))
        ]]

        -- Set this to true if not enough spots are available for emergency air start.
        local _notenough = false

        -- Need to differentiate some cases again.
        if spawnonship or spawnonfarp or spawnonrunway then

          -- On free spot required in these cases.
          if nfree >= 1 then

            -- All units get the same spot. DCS takes care of the rest.
            for i = 1, nunits do
              table.insert( parkingspots, spots[1].Coordinate )
              table.insert( parkingindex, spots[1].TerminalID )
            end
            -- This is actually used...
            PointVec3 = spots[1].Coordinate

          else
            -- If there is absolutely no spot ==> air start!
            _notenough = true
          end

        elseif spawnonairport then

          if nfree >= nunits then

            for i = 1, nunits do
              table.insert( parkingspots, spots[i].Coordinate )
              table.insert( parkingindex, spots[i].TerminalID )
            end

          else
            -- Not enough spots for the whole group ==> air start!
            _notenough = true
          end
        end

        -- Not enough spots ==> Prepare airstart.
        if _notenough then

          if EmergencyAirSpawn and not self.SpawnUnControlled then
            self:E( string.format( "WARNING: Group %s has no parking spots at %s ==> air start!", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )

            -- Not enough parking spots at the airport ==> Spawn in air.
            spawnonground = false
            spawnonship = false
            spawnonfarp = false
            spawnonrunway = false

            -- Set waypoint type/action to turning point.
            SpawnPoint.type = GROUPTEMPLATE.Takeoff[GROUP.Takeoff.Air][1] -- type   = Turning Point
            SpawnPoint.action = GROUPTEMPLATE.Takeoff[GROUP.Takeoff.Air][2] -- action = Turning Point

            -- Adjust altitude to be 500-1000 m above the airbase.
            PointVec3.x = PointVec3.x + math.random( -500, 500 )
            PointVec3.z = PointVec3.z + math.random( -500, 500 )
            if ishelo then
              PointVec3.y = PointVec3:GetLandHeight() + math.random( 100, 1000 )
            else
              -- Randomize position so that multiple AC wont be spawned on top even in air.
              PointVec3.y = PointVec3:GetLandHeight() + math.random( 500, 2500 )
            end

            Takeoff = GROUP.Takeoff.Air
          else
            self:E( string.format( "WARNING: Group %s has no parking spots at %s ==> No emergency air start or uncontrolled spawning ==> No spawn!", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )
            return nil
          end
        end

      else

        -- Air start requested initially ==> Set altitude. 
        if TakeoffAltitude then
          PointVec3.y = TakeoffAltitude
        else
          if ishelo then
            PointVec3.y = PointVec3:GetLandHeight() + math.random( 100, 1000 )
          else
            -- Randomize position so that multiple AC wont be spawned on top even in air.
            PointVec3.y = PointVec3:GetLandHeight() + math.random( 500, 2500 )
          end
        end

      end

      if not SpawnTemplate.parked then
        -- Translate the position of the Group Template to the Vec3.

        SpawnTemplate.parked = true

        for UnitID = 1, nunits do
          self:T2( 'Before Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )

          -- Template of the current unit.
          local UnitTemplate = SpawnTemplate.units[UnitID]

          -- Tranlate position and preserve the relative position/formation of all aircraft.  
          local SX = UnitTemplate.x
          local SY = UnitTemplate.y
          local BX = SpawnTemplate.route.points[1].x
          local BY = SpawnTemplate.route.points[1].y
          local TX = PointVec3.x + (SX - BX)
          local TY = PointVec3.z + (SY - BY)

          if spawnonground then

            -- Ships and FARPS seem to have a build in queue.
            if spawnonship or spawnonfarp or spawnonrunway then

              self:T( string.format( "Group %s spawning at farp, ship or runway %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )

              -- Spawn on ship. We take only the position of the ship.
              SpawnTemplate.units[UnitID].x = PointVec3.x -- TX
              SpawnTemplate.units[UnitID].y = PointVec3.z -- TY
              SpawnTemplate.units[UnitID].alt = PointVec3.y

            else

              self:T( string.format( "Group %s spawning at airbase %s on parking spot id %d", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), parkingindex[UnitID] ) )

              -- Get coordinates of parking spot.
              SpawnTemplate.units[UnitID].x = parkingspots[UnitID].x
              SpawnTemplate.units[UnitID].y = parkingspots[UnitID].z
              SpawnTemplate.units[UnitID].alt = parkingspots[UnitID].y

              -- parkingspots[UnitID]:MarkToAll(string.format("Group %s spawning at airbase %s on parking spot id %d", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), parkingindex[UnitID]))
            end

          else

            self:T( string.format( "Group %s spawning in air at %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )

            -- Spawn in air as requested initially. Original template orientation is perserved, altitude is already correctly set.
            SpawnTemplate.units[UnitID].x = TX
            SpawnTemplate.units[UnitID].y = TY
            SpawnTemplate.units[UnitID].alt = PointVec3.y

          end

          -- Parking spot id.
          UnitTemplate.parking = nil
          UnitTemplate.parking_id = nil
          if parkingindex[UnitID] then
            UnitTemplate.parking = parkingindex[UnitID]
          end

          -- Debug output.
          self:T( string.format( "Group %s unit number %d: Parking    = %s", self.SpawnTemplatePrefix, UnitID, tostring( UnitTemplate.parking ) ) )
          self:T( string.format( "Group %s unit number %d: Parking ID = %s", self.SpawnTemplatePrefix, UnitID, tostring( UnitTemplate.parking_id ) ) )
          self:T2( 'After Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )
        end
      end

      -- Set gereral spawnpoint position.
      SpawnPoint.x = PointVec3.x
      SpawnPoint.y = PointVec3.z
      SpawnPoint.alt = PointVec3.y

      SpawnTemplate.x = PointVec3.x
      SpawnTemplate.y = PointVec3.z

      SpawnTemplate.uncontrolled = self.SpawnUnControlled

      -- Spawn group.
      local GroupSpawned = self:SpawnWithIndex( self.SpawnIndex )

      -- When spawned in the air, we need to generate a Takeoff Event.
      if Takeoff == GROUP.Takeoff.Air then
        for UnitID, UnitSpawned in pairs( GroupSpawned:GetUnits() ) do
          SCHEDULER:New( nil, BASE.CreateEventTakeoff, { GroupSpawned, timer.getTime(), UnitSpawned:GetDCSObject() }, 5 )
        end
      end

      -- Check if we accidentally spawned on the runway. Needs to be schedules, because group is not immidiately alive.
      if Takeoff ~= SPAWN.Takeoff.Runway and Takeoff ~= SPAWN.Takeoff.Air and spawnonairport then
        SCHEDULER:New( nil, AIRBASE.CheckOnRunWay, { SpawnAirbase, GroupSpawned, 75, true }, 1.0 )
      end

      return GroupSpawned
    end
  end

  return nil
end

--- Spawn a group on an @{Wrapper.Airbase} at a specific parking spot.
-- @param #SPAWN self
-- @param Wrapper.Airbase#AIRBASE Airbase The @{Wrapper.Airbase} where to spawn the group.
-- @param #table Spots Table of parking spot IDs. Note that these in general are different from the numbering in the mission editor!
-- @param #SPAWN.Takeoff Takeoff (Optional) Takeoff type, i.e. either SPAWN.Takeoff.Cold or SPAWN.Takeoff.Hot. Default is Hot.
-- @return Wrapper.Group#GROUP The group that was spawned or nil when nothing was spawned.
function SPAWN:SpawnAtParkingSpot( Airbase, Spots, Takeoff ) -- R2.5
  self:F( { Airbase = Airbase, Spots = Spots, Takeoff = Takeoff } )

  -- Ensure that Spots parameter is a table.
  if type( Spots ) ~= "table" then
    Spots = { Spots }
  end

  -- Get template group.
  local group = GROUP:FindByName( self.SpawnTemplatePrefix )

  -- Get number of units in group.
  local nunits = self.SpawnGrouping or #group:GetUnits()

  -- Quick check.
  if nunits then

    -- Check that number of provided parking spots is large enough.
    if #Spots < nunits then
      self:E( "ERROR: Number of provided parking spots is less than number of units in group!" )
      return nil
    end

    -- Table of parking data.
    local Parkingdata = {}

    -- Loop over provided Terminal IDs.
    for _, TerminalID in pairs( Spots ) do

      -- Get parking spot data.
      local spot = Airbase:GetParkingSpotData( TerminalID )

      self:T2( { spot = spot } )

      if spot and spot.Free then
        self:T( string.format( "Adding parking spot ID=%d TermType=%d", spot.TerminalID, spot.TerminalType ) )
        table.insert( Parkingdata, spot )
      end

    end

    if #Parkingdata >= nunits then
      return self:SpawnAtAirbase( Airbase, Takeoff, nil, nil, nil, Parkingdata )
    else
      self:E( "ERROR: Could not find enough free parking spots!" )
    end

  else
    self:E( "ERROR: Could not get number of units in group!" )
  end

  return nil
end

--- Will park a group at an @{Wrapper.Airbase}.
--
-- @param #SPAWN self
-- @param Wrapper.Airbase#AIRBASE SpawnAirbase The @{Wrapper.Airbase} where to spawn the group.
-- @param Wrapper.Airbase#AIRBASE.TerminalType TerminalType (optional) The terminal type the aircraft should be spawned at. See @{Wrapper.Airbase#AIRBASE.TerminalType}.
-- @param #table Parkingdata (optional) Table holding the coordinates and terminal ids for all units of the group. Spawning will be forced to happen at exactily these spots!
-- @return #nil Nothing is returned!
function SPAWN:ParkAircraft( SpawnAirbase, TerminalType, Parkingdata, SpawnIndex )

  self:F( { SpawnIndex = SpawnIndex, SpawnMaxGroups = self.SpawnMaxGroups } )

  -- Get position of airbase.
  local PointVec3 = SpawnAirbase:GetCoordinate()
  self:T2( PointVec3 )

  -- Set take off type. Default is hot.
  local Takeoff = SPAWN.Takeoff.Cold

  -- Get group template.
  local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate

  if SpawnTemplate then

    -- Check if the aircraft with the specified SpawnIndex is already spawned.
    -- If yes, ensure that the aircraft is spawned at the same aircraft spot.

    local GroupAlive = self:GetGroupFromIndex( SpawnIndex )

    -- Debug output
    self:T( { "Current point of ", self.SpawnTemplatePrefix, SpawnAirbase } )

    -- Template group, unit and its attributes.
    local TemplateGroup = GROUP:FindByName( self.SpawnTemplatePrefix )
    local TemplateUnit = TemplateGroup:GetUnit( 1 )
    local ishelo = TemplateUnit:HasAttribute( "Helicopters" )
    local isbomber = TemplateUnit:HasAttribute( "Bombers" )
    local istransport = TemplateUnit:HasAttribute( "Transports" )
    local isfighter = TemplateUnit:HasAttribute( "Battleplanes" )

    -- Number of units in the group. With grouping this can actually differ from the template group size!
    local nunits = #SpawnTemplate.units

    -- First waypoint of the group.
    local SpawnPoint = SpawnTemplate.route.points[1]

    -- These are only for ships and FARPS.
    SpawnPoint.linkUnit = nil
    SpawnPoint.helipadId = nil
    SpawnPoint.airdromeId = nil

    -- Get airbase ID and category.
    local AirbaseID = SpawnAirbase:GetID()
    local AirbaseCategory = SpawnAirbase:GetAirbaseCategory()
    self:F( { AirbaseCategory = AirbaseCategory } )

    -- Set airdromeId.
    if AirbaseCategory == Airbase.Category.SHIP then
      SpawnPoint.linkUnit = AirbaseID
      SpawnPoint.helipadId = AirbaseID
    elseif AirbaseCategory == Airbase.Category.HELIPAD then
      SpawnPoint.linkUnit = AirbaseID
      SpawnPoint.helipadId = AirbaseID
    elseif AirbaseCategory == Airbase.Category.AIRDROME then
      SpawnPoint.airdromeId = AirbaseID
    end

    -- Set waypoint type/action.
    SpawnPoint.alt = 0
    SpawnPoint.type = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
    SpawnPoint.action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action

    -- Check if we spawn on ground. 
    local spawnonground = not (Takeoff == SPAWN.Takeoff.Air)
    self:T( { spawnonground = spawnonground, TOtype = Takeoff, TOair = Takeoff == SPAWN.Takeoff.Air } )

    -- Check where we actually spawn if we spawn on ground.
    local spawnonship = false
    local spawnonfarp = false
    local spawnonrunway = false
    local spawnonairport = false
    if spawnonground then
      if AirbaseCategory == Airbase.Category.SHIP then
        spawnonship = true
      elseif AirbaseCategory == Airbase.Category.HELIPAD then
        spawnonfarp = true
      elseif AirbaseCategory == Airbase.Category.AIRDROME then
        spawnonairport = true
      end
      spawnonrunway = Takeoff == SPAWN.Takeoff.Runway
    end

    -- Array with parking spots coordinates.
    local parkingspots = {}
    local parkingindex = {}
    local spots

    -- Spawn happens on ground, i.e. at an airbase, a FARP or a ship.
    if spawnonground and not SpawnTemplate.parked then

      -- Number of free parking spots.
      local nfree = 0

      -- Set terminal type.
      local termtype = TerminalType

      -- Scan options. Might make that input somehow.
      local scanradius = 50
      local scanunits = true
      local scanstatics = true
      local scanscenery = false
      local verysafe = false

      -- Number of free parking spots at the airbase.
      if spawnonship or spawnonfarp or spawnonrunway then
        -- These places work procedural and have some kind of build in queue ==> Less effort.
        self:T( string.format( "Group %s is spawned on farp/ship/runway %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )
        nfree = SpawnAirbase:GetFreeParkingSpotsNumber( termtype, true )
        spots = SpawnAirbase:GetFreeParkingSpotsTable( termtype, true )
        --[[
      elseif Parkingdata~=nil then
        -- Parking data explicitly set by user as input parameter.
        nfree=#Parkingdata
        spots=Parkingdata
      ]]
      else
        if ishelo then
          if termtype == nil then
            -- Helo is spawned. Try exclusive helo spots first.
            self:T( string.format( "Helo group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.HelicopterOnly ) )
            spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.HelicopterOnly, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
            nfree = #spots
            if nfree < nunits then
              -- Not enough helo ports. Let's try also other terminal types.
              self:T( string.format( "Helo group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.HelicopterUsable ) )
              spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.HelicopterUsable, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
              nfree = #spots
            end
          else
            -- No terminal type specified. We try all spots except shelters.
            self:T( string.format( "Helo group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), termtype ) )
            spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, termtype, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
            nfree = #spots
          end
        else
          -- Fixed wing aircraft is spawned.
          if termtype == nil then
            -- TODO: Add some default cases for transport, bombers etc. if no explicit terminal type is provided.
            -- TODO: We don't want Bombers to spawn in shelters. But I don't know a good attribute for just fighers.
            -- TODO: Some attributes are "Helicopters", "Bombers", "Transports", "Battleplanes". Need to check it out.
            if isbomber or istransport then
              -- First we fill the potentially bigger spots.
              self:T( string.format( "Transport/bomber group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.OpenBig ) )
              spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.OpenBig, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
              nfree = #spots
              if nfree < nunits then
                -- Now we try the smaller ones.
                self:T( string.format( "Transport/bomber group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.OpenMedOrBig ) )
                spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.OpenMedOrBig, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
                nfree = #spots
              end
            else
              self:T( string.format( "Fighter group %s is at %s using terminal type %d.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), AIRBASE.TerminalType.FighterAircraft ) )
              spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, AIRBASE.TerminalType.FighterAircraft, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
              nfree = #spots
            end
          else
            -- Terminal type explicitly given.
            self:T( string.format( "Plane group %s is at %s using terminal type %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), tostring( termtype ) ) )
            spots = SpawnAirbase:FindFreeParkingSpotForAircraft( TemplateGroup, termtype, scanradius, scanunits, scanstatics, scanscenery, verysafe, nunits, Parkingdata )
            nfree = #spots
          end
        end
      end

      -- Debug: Get parking data.
      --[[
      local parkingdata=SpawnAirbase:GetParkingSpotsTable(termtype)
      self:T2(string.format("Parking at %s, terminal type %s:", SpawnAirbase:GetName(), tostring(termtype)))
      for _,_spot in pairs(parkingdata) do
        self:T2(string.format("%s, Termin Index = %3d, Term Type = %03d, Free = %5s, TOAC = %5s, Term ID0 = %3d, Dist2Rwy = %4d",
        SpawnAirbase:GetName(), _spot.TerminalID, _spot.TerminalType,tostring(_spot.Free),tostring(_spot.TOAC),_spot.TerminalID0,_spot.DistToRwy))
      end
      self:T(string.format("%s at %s: free parking spots = %d - number of units = %d", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), nfree, nunits))
      ]]

      -- Set this to true if not enough spots are available for emergency air start.
      local _notenough = false

      -- Need to differentiate some cases again.
      if spawnonship or spawnonfarp or spawnonrunway then

        -- On free spot required in these cases. 
        if nfree >= 1 then

          -- All units get the same spot. DCS takes care of the rest.
          for i = 1, nunits do
            table.insert( parkingspots, spots[1].Coordinate )
            table.insert( parkingindex, spots[1].TerminalID )
          end
          -- This is actually used...
          PointVec3 = spots[1].Coordinate

        else
          -- If there is absolutely no spot ==> air start!
          _notenough = true
        end

      elseif spawnonairport then

        if nfree >= nunits then

          for i = 1, nunits do
            table.insert( parkingspots, spots[i].Coordinate )
            table.insert( parkingindex, spots[i].TerminalID )
          end

        else
          -- Not enough spots for the whole group ==> air start!
          _notenough = true
        end
      end

      -- Not enough spots ==> Prepare airstart.
      if _notenough then

        if not self.SpawnUnControlled then
        else
          self:E( string.format( "WARNING: Group %s has no parking spots at %s ==> No emergency air start or uncontrolled spawning ==> No spawn!", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )
          return nil
        end
      end

    else

    end

    if not SpawnTemplate.parked then
      -- Translate the position of the Group Template to the Vec3.

      SpawnTemplate.parked = true

      for UnitID = 1, nunits do
        self:F( 'Before Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )

        -- Template of the current unit.
        local UnitTemplate = SpawnTemplate.units[UnitID]

        -- Tranlate position and preserve the relative position/formation of all aircraft.  
        local SX = UnitTemplate.x
        local SY = UnitTemplate.y
        local BX = SpawnTemplate.route.points[1].x
        local BY = SpawnTemplate.route.points[1].y
        local TX = PointVec3.x + (SX - BX)
        local TY = PointVec3.z + (SY - BY)

        if spawnonground then

          -- Ships and FARPS seem to have a build in queue.
          if spawnonship or spawnonfarp or spawnonrunway then

            self:T( string.format( "Group %s spawning at farp, ship or runway %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )

            -- Spawn on ship. We take only the position of the ship.
            SpawnTemplate.units[UnitID].x = PointVec3.x -- TX
            SpawnTemplate.units[UnitID].y = PointVec3.z -- TY
            SpawnTemplate.units[UnitID].alt = PointVec3.y

          else

            self:T( string.format( "Group %s spawning at airbase %s on parking spot id %d", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), parkingindex[UnitID] ) )

            -- Get coordinates of parking spot.
            SpawnTemplate.units[UnitID].x = parkingspots[UnitID].x
            SpawnTemplate.units[UnitID].y = parkingspots[UnitID].z
            SpawnTemplate.units[UnitID].alt = parkingspots[UnitID].y

            -- parkingspots[UnitID]:MarkToAll(string.format("Group %s spawning at airbase %s on parking spot id %d", self.SpawnTemplatePrefix, SpawnAirbase:GetName(), parkingindex[UnitID]))
          end

        else

          self:T( string.format( "Group %s spawning in air at %s.", self.SpawnTemplatePrefix, SpawnAirbase:GetName() ) )

          -- Spawn in air as requested initially. Original template orientation is perserved, altitude is already correctly set.
          SpawnTemplate.units[UnitID].x = TX
          SpawnTemplate.units[UnitID].y = TY
          SpawnTemplate.units[UnitID].alt = PointVec3.y

        end

        -- Parking spot id.
        UnitTemplate.parking = nil
        UnitTemplate.parking_id = nil
        if parkingindex[UnitID] then
          UnitTemplate.parking = parkingindex[UnitID]
        end

        -- Debug output.
        self:T2( string.format( "Group %s unit number %d: Parking    = %s", self.SpawnTemplatePrefix, UnitID, tostring( UnitTemplate.parking ) ) )
        self:T2( string.format( "Group %s unit number %d: Parking ID = %s", self.SpawnTemplatePrefix, UnitID, tostring( UnitTemplate.parking_id ) ) )
        self:T2( 'After Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )
      end
    end

    -- Set general spawnpoint position.
    SpawnPoint.x = PointVec3.x
    SpawnPoint.y = PointVec3.z
    SpawnPoint.alt = PointVec3.y

    SpawnTemplate.x = PointVec3.x
    SpawnTemplate.y = PointVec3.z

    SpawnTemplate.uncontrolled = true

    -- Spawn group.
    local GroupSpawned = self:SpawnWithIndex( SpawnIndex, true )

    -- When spawned in the air, we need to generate a Takeoff Event.
    if Takeoff == GROUP.Takeoff.Air then
      for UnitID, UnitSpawned in pairs( GroupSpawned:GetUnits() ) do
        SCHEDULER:New( nil, BASE.CreateEventTakeoff, { GroupSpawned, timer.getTime(), UnitSpawned:GetDCSObject() }, 5 )
      end
    end

    -- Check if we accidentally spawned on the runway. Needs to be schedules, because group is not immidiately alive.
    if Takeoff ~= SPAWN.Takeoff.Runway and Takeoff ~= SPAWN.Takeoff.Air and spawnonairport then
      SCHEDULER:New( nil, AIRBASE.CheckOnRunWay, { SpawnAirbase, GroupSpawned, 75, true }, 1.0 )
    end

  end

end

--- Will park a group at an @{Wrapper.Airbase}.
-- This method is mostly advisable to be used if you want to simulate parking units at an airbase and be visible.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
--
-- All groups that are in the spawn collection and that are alive, and not in the air, are parked.
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
-- Ships and FARPs are added within the mission, and are therefore not known.
-- For these AIRBASE objects, there isn't an @{Wrapper.Airbase#AIRBASE} enumeration defined.
-- You need to provide the **exact name** of the airbase as the parameter to the @{Wrapper.Airbase#AIRBASE.FindByName}() method!
--
-- @param #SPAWN self
-- @param Wrapper.Airbase#AIRBASE SpawnAirbase The @{Wrapper.Airbase} where to spawn the group.
-- @param Wrapper.Airbase#AIRBASE.TerminalType TerminalType (optional) The terminal type the aircraft should be spawned at. See @{Wrapper.Airbase#AIRBASE.TerminalType}.
-- @param #table Parkingdata (optional) Table holding the coordinates and terminal ids for all units of the group. Spawning will be forced to happen at exactily these spots!
-- @return #nil Nothing is returned!
-- @usage
--   Spawn_Plane = SPAWN:New( "Plane" )
--   Spawn_Plane:ParkAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Krymsk ) )
--
--   Spawn_Heli = SPAWN:New( "Heli")
--
--   Spawn_Heli:ParkAtAirbase( AIRBASE:FindByName( "FARP Cold" ) )
--
--   Spawn_Heli:ParkAtAirbase( AIRBASE:FindByName( "Carrier" ) )
--
--   Spawn_Plane:ParkAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Krymsk ), AIRBASE.TerminalType.OpenBig )
--
function SPAWN:ParkAtAirbase( SpawnAirbase, TerminalType, Parkingdata ) -- R2.2, R2.4, R2.5
  self:F( { self.SpawnTemplatePrefix, SpawnAirbase, TerminalType } )

  self:ParkAircraft( SpawnAirbase, TerminalType, Parkingdata, 1 )

  for SpawnIndex = 2, self.SpawnMaxGroups do
    self:ParkAircraft( SpawnAirbase, TerminalType, Parkingdata, SpawnIndex )
    -- self:ScheduleOnce( SpawnIndex * 0.1, SPAWN.ParkAircraft, self, SpawnAirbase, TerminalType, Parkingdata, SpawnIndex )
  end

  self:SetSpawnIndex( 0 )

  return nil
end

--- Will spawn a group from a Vec3 in 3D space.
-- This method is mostly advisable to be used if you want to simulate spawning units in the air, like helicopters or airplanes.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param DCS#Vec3 Vec3 The Vec3 coordinates where to spawn the group.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned.
function SPAWN:SpawnFromVec3( Vec3, SpawnIndex )
  self:F( { self.SpawnTemplatePrefix, Vec3, SpawnIndex } )

  local PointVec3 = POINT_VEC3:NewFromVec3( Vec3 )
  self:T2( PointVec3 )

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
        -- self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        local UnitTemplate = SpawnTemplate.units[UnitID]
        local SX = UnitTemplate.x or 0
        local SY = UnitTemplate.y or 0
        local BX = SpawnTemplate.route.points[1].x
        local BY = SpawnTemplate.route.points[1].y
        local TX = Vec3.x + (SX - BX)
        local TY = Vec3.z + (SY - BY)
        SpawnTemplate.units[UnitID].x = TX
        SpawnTemplate.units[UnitID].y = TY
        if SpawnTemplate.CategoryID ~= Group.Category.SHIP then
          SpawnTemplate.units[UnitID].alt = Vec3.y or TemplateHeight
        end
        self:T( 'After Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. SpawnTemplate.units[UnitID].y )
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
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned.
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
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned.
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
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned.
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
    Height = math.random( MinHeight, MaxHeight )
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
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned.
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
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned.
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

--- Will spawn a Group within a given @{Core.Zone}.
-- The @{Core.Zone} can be of any type derived from @{Core.Zone#ZONE_BASE}.
-- Once the @{Wrapper.Group} is spawned within the zone, the @{Wrapper.Group} will continue on its route.
-- The **first waypoint** (where the group is spawned) is replaced with the zone location coordinates.
-- @param #SPAWN self
-- @param Core.Zone#ZONE Zone The zone where the group is to be spawned.
-- @param #boolean RandomizeGroup (optional) Randomization of the @{Wrapper.Group} position in the zone.
-- @param #number MinHeight (optional) The minimum height to spawn an airborne group into the zone.
-- @param #number MaxHeight (optional) The maximum height to spawn an airborne group into the zone.
-- @param #number SpawnIndex (optional) The index which group to spawn within the given zone.
-- @return Wrapper.Group#GROUP that was spawned or #nil if nothing was spawned. 
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

  self.SpawnUnControlled = (UnControlled == true) and true or nil

  for SpawnGroupID = 1, self.SpawnMaxGroups do
    self.SpawnGroups[SpawnGroupID].UnControlled = self.SpawnUnControlled
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
--
--   -- Find the first alive @{Wrapper.Group} object of the SpawnPlanes SPAWN object @{Wrapper.Group} collection that it has spawned during the mission.
--   local GroupPlane, Index = SpawnPlanes:GetFirstAliveGroup()
--   while GroupPlane ~= nil do
--     -- Do actions with the GroupPlane object.
--     GroupPlane, Index = SpawnPlanes:GetNextAliveGroup( Index )
--   end
--
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
--
--   -- Find the first alive @{Wrapper.Group} object of the SpawnPlanes SPAWN object @{Wrapper.Group} collection that it has spawned during the mission.
--   local GroupPlane, Index = SpawnPlanes:GetFirstAliveGroup()
--   while GroupPlane ~= nil do
--     -- Do actions with the GroupPlane object.
--     GroupPlane, Index = SpawnPlanes:GetNextAliveGroup( Index )
--   end
--
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
--
--   -- Find the last alive @{Wrapper.Group} object of the SpawnPlanes SPAWN object @{Wrapper.Group} collection that it has spawned during the mission.
--   local GroupPlane, Index = SpawnPlanes:GetLastAliveGroup()
--   if GroupPlane then -- GroupPlane can be nil!!!
--     -- Do actions with the GroupPlane object.
--   end
--
function SPAWN:GetLastAliveGroup()
  self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

  for SpawnIndex = self.SpawnCount, 1, -1 do -- Added
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
-- @param Wrapper.Group#GROUP SpawnGroup The GROUP object.
-- @return #string The prefix or #nil if nothing was found.
function SPAWN:_GetPrefixFromGroup( SpawnGroup )

  local GroupName = SpawnGroup:GetName()
  
  if GroupName then
  
    local SpawnPrefix=self:_GetPrefixFromGroupName(GroupName)
    
    return SpawnPrefix
  end
  
  return nil
end

--- Return the prefix of a spawned group.
-- The method will search for a `#`-mark, and will return the text before the `#`-mark. It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param #string SpawnGroupName The name of the spawned group.
-- @return #string The prefix or #nil if nothing was found.
function SPAWN:_GetPrefixFromGroupName(SpawnGroupName)

  if SpawnGroupName then
  
    local SpawnPrefix=string.match(SpawnGroupName, ".*#")
    
    if SpawnPrefix then
      SpawnPrefix = SpawnPrefix:sub(1, -2)
    end
    
    return SpawnPrefix
  end
  
  return nil
end

--- Get the index from a given group.
-- The function will search the name of the group for a #, and will return the number behind the #-mark.
function SPAWN:GetSpawnIndexFromGroup( SpawnGroup )
  self:F2( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )

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
  -- self:_TranslateRotate( SpawnIndex )

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
-- Note: This method uses the global _DATABASE object (an instance of @{Core.Database#DATABASE}), which contains ALL initial and new spawned objects in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix
-- @return @SPAWN self
function SPAWN:_GetTemplate( SpawnTemplatePrefix )
  self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnTemplatePrefix } )

  local SpawnTemplate = nil
  
  if _DATABASE.Templates.Groups[SpawnTemplatePrefix] == nil then
    error( 'No Template exists for SpawnTemplatePrefix = ' .. SpawnTemplatePrefix )
  end
  
  local Template = _DATABASE.Templates.Groups[SpawnTemplatePrefix].Template
  self:F( { Template = Template } )

  SpawnTemplate = UTILS.DeepCopy( _DATABASE.Templates.Groups[SpawnTemplatePrefix].Template )

  if SpawnTemplate == nil then
    error( 'No Template returned for SpawnTemplatePrefix = ' .. SpawnTemplatePrefix )
  end

  -- SpawnTemplate.SpawnCoalitionID = self:_GetGroupCoalitionID( SpawnTemplatePrefix )
  -- SpawnTemplate.SpawnCategoryID = self:_GetGroupCategoryID( SpawnTemplatePrefix )
  -- SpawnTemplate.SpawnCountryID = self:_GetGroupCountryID( SpawnTemplatePrefix )

  self:T3( { SpawnTemplate } )
  return SpawnTemplate
end

--- Prepares the new Group Template.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_Prepare( SpawnTemplatePrefix, SpawnIndex ) -- R2.2
  self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

  --  if not self.SpawnTemplate then
  --    self.SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
  --  end

  local SpawnTemplate
  if self.TweakedTemplate ~= nil and self.TweakedTemplate == true then
    BASE:I( "WARNING: You are using a tweaked template." )
    SpawnTemplate = self.SpawnTemplate
    if self.MooseNameing == true then
      SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
    else
      SpawnTemplate.name = self:SpawnGroupName()
    end
  else
    SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
    SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
  end

  SpawnTemplate.groupId = nil
  -- SpawnTemplate.lateActivation = false
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

  -- Callsign
  for UnitID = 1, #SpawnTemplate.units do
    local Callsign = SpawnTemplate.units[UnitID].callsign
    if Callsign then
      if type( Callsign ) ~= "number" then -- blue callsign
        Callsign[2] = ((SpawnIndex - 1) % 10) + 1
        local CallsignName = SpawnTemplate.units[UnitID].callsign["name"] -- #string
        CallsignName = string.match(CallsignName,"^(%a+)") -- 2.8 - only the part w/o numbers
        local CallsignLen = CallsignName:len()
        SpawnTemplate.units[UnitID].callsign["name"] = CallsignName:sub( 1, CallsignLen ) .. SpawnTemplate.units[UnitID].callsign[2] .. SpawnTemplate.units[UnitID].callsign[3]
      else
        SpawnTemplate.units[UnitID].callsign = Callsign + SpawnIndex
      end
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

    for t = self.SpawnRandomizeRouteStartPoint + 1, (RouteCount - self.SpawnRandomizeRouteEndPoint) do

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
    self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefixTable[math.random( 1, #self.SpawnTemplatePrefixTable )]
    self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.route = UTILS.DeepCopy( self.SpawnTemplate.route )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.x = self.SpawnTemplate.x
    self.SpawnGroups[SpawnIndex].SpawnTemplate.y = self.SpawnTemplate.y
    self.SpawnGroups[SpawnIndex].SpawnTemplate.start_time = self.SpawnTemplate.start_time
    local OldX = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[1].x
    local OldY = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[1].y
    for UnitID = 1, #self.SpawnGroups[SpawnIndex].SpawnTemplate.units do
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].heading = self.SpawnTemplate.units[1].heading
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].x = self.SpawnTemplate.units[1].x + (self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].x - OldX)
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].y = self.SpawnTemplate.units[1].y + (self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].y - OldY)
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].alt = self.SpawnTemplate.units[1].alt
    end
  end

  self:_RandomizeRoute( SpawnIndex )

  return self
end

--- Private method that sets the DCS#Vec2 where the Group will be spawned.
-- @param #SPAWN self
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_SetInitialPosition( SpawnIndex )
  self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeZones } )
  
  if self.SpawnFromNewPosition then
    
    self:T( "Preparing Spawn at Vec2 ", self.SpawnInitPosition )

    local SpawnVec2 = self.SpawnInitPosition

    self:T( { SpawnVec2 = SpawnVec2 } )

    local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate

    SpawnTemplate.route = SpawnTemplate.route or {}
    SpawnTemplate.route.points = SpawnTemplate.route.points or {}
    SpawnTemplate.route.points[1] = SpawnTemplate.route.points[1] or {}
    SpawnTemplate.route.points[1].x = SpawnTemplate.route.points[1].x or 0
    SpawnTemplate.route.points[1].y = SpawnTemplate.route.points[1].y or 0
      
    self:T( { Route = SpawnTemplate.route } )

    for UnitID = 1, #SpawnTemplate.units do
      local UnitTemplate = SpawnTemplate.units[UnitID]
      self:T( 'Before Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. UnitTemplate.y )
      local SX = UnitTemplate.x
      local SY = UnitTemplate.y
      local BX = SpawnTemplate.route.points[1].x
      local BY = SpawnTemplate.route.points[1].y
      local TX = SpawnVec2.x + (SX - BX)
      local TY = SpawnVec2.y + (SY - BY)
      UnitTemplate.x = TX
      UnitTemplate.y = TY
      -- TODO: Manage altitude based on landheight...
      -- SpawnTemplate.units[UnitID].alt = SpawnVec2:
      self:T( 'After Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. UnitTemplate.y )
    end
    
    SpawnTemplate.route.points[1].x = SpawnVec2.x
    SpawnTemplate.route.points[1].y = SpawnVec2.y
    SpawnTemplate.x = SpawnVec2.x
    SpawnTemplate.y = SpawnVec2.y
    
  end

  return self
end

--- Private method that randomizes the @{Core.Zone}s where the Group will be spawned.
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
      SpawnZone = self.SpawnZoneTable[ZoneID]:GetZoneMaybe()
    end

    self:T( "Preparing Spawn in Zone", SpawnZone:GetName() )

    local SpawnVec2 = SpawnZone:GetRandomVec2()

    self:T( { SpawnVec2 = SpawnVec2 } )

    local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate

    self:T( { Route = SpawnTemplate.route } )

    for UnitID = 1, #SpawnTemplate.units do
      local UnitTemplate = SpawnTemplate.units[UnitID]
      self:T( 'Before Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. UnitTemplate.y )
      local SX = UnitTemplate.x
      local SY = UnitTemplate.y
      local BX = SpawnTemplate.route.points[1].x
      local BY = SpawnTemplate.route.points[1].y
      local TX = SpawnVec2.x + (SX - BX)
      local TY = SpawnVec2.y + (SY - BY)
      UnitTemplate.x = TX
      UnitTemplate.y = TY
      -- TODO: Manage altitude based on landheight...
      -- SpawnTemplate.units[UnitID].alt = SpawnVec2:
      self:T( 'After Translation SpawnTemplate.units[' .. UnitID .. '].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units[' .. UnitID .. '].y = ' .. UnitTemplate.y )
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
  local RotatedX = -TranslatedX * math.cos( math.rad( SpawnAngle ) ) + TranslatedY * math.sin( math.rad( SpawnAngle ) )
  local RotatedY = TranslatedX * math.sin( math.rad( SpawnAngle ) ) + TranslatedY * math.cos( math.rad( SpawnAngle ) )

  -- Assign
  self.SpawnGroups[SpawnIndex].SpawnTemplate.x = SpawnRootX - RotatedX
  self.SpawnGroups[SpawnIndex].SpawnTemplate.y = SpawnRootY + RotatedY

  local SpawnUnitCount = table.getn( self.SpawnGroups[SpawnIndex].SpawnTemplate.units )
  for u = 1, SpawnUnitCount do

    -- Translate
    local TranslatedX = SpawnX
    local TranslatedY = SpawnY - 10 * (u - 1)

    -- Rotate
    local RotatedX = -TranslatedX * math.cos( math.rad( SpawnAngle ) ) + TranslatedY * math.sin( math.rad( SpawnAngle ) )
    local RotatedY = TranslatedX * math.sin( math.rad( SpawnAngle ) ) + TranslatedY * math.cos( math.rad( SpawnAngle ) )

    -- Assign
    self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].x = SpawnRootX - RotatedX
    self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].y = SpawnRootY + RotatedY
    self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading + math.rad( SpawnAngle )
  end

  return self
end

--- Get the next index of the groups to be spawned. This method is complicated, as it is used at several spaces.
-- @param #SPAWN self
-- @param #number SpawnIndex Spawn index.
-- @return #number self.SpawnIndex
function SPAWN:_GetSpawnIndex( SpawnIndex )
  self:F2( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive, self.AliveUnits, #self.SpawnTemplate.units } )

  if (self.SpawnMaxGroups == 0) or (SpawnIndex <= self.SpawnMaxGroups) then
    if (self.SpawnMaxUnitsAlive == 0) or (self.AliveUnits + #self.SpawnTemplate.units <= self.SpawnMaxUnitsAlive) or self.UnControlled == true then
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

-- @param #SPAWN self 
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnBirth( EventData )
  self:F( self.SpawnTemplatePrefix )

  local SpawnGroup = EventData.IniGroup

  if SpawnGroup then
    local EventPrefix = self:_GetPrefixFromGroup( SpawnGroup )
    if EventPrefix then -- EventPrefix can be nil if no # is found, which means, no spawnable group!
      self:T( { "Birth Event:", EventPrefix, self.SpawnTemplatePrefix } )
      if EventPrefix == self.SpawnTemplatePrefix or (self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix) then
        self.AliveUnits = self.AliveUnits + 1
        self:T( "Alive Units: " .. self.AliveUnits )
      end
    end
  end

end

-- @param #SPAWN self 
-- @param Core.Event#EVENTDATA EventData
function SPAWN:_OnDeadOrCrash( EventData )
  self:F( self.SpawnTemplatePrefix )
  
  local unit=UNIT:FindByName(EventData.IniUnitName)
  
  if unit then
  
    local EventPrefix = self:_GetPrefixFromGroupName(unit.GroupName)
   
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
      if EventPrefix == self.SpawnTemplatePrefix or (self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix) then
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
      if EventPrefix == self.SpawnTemplatePrefix or (self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix) then
        -- TODO: Check if this is the last unit of the group that lands.
        SpawnGroup:SetState( SpawnGroup, "Spawn_Landed", true )
        if self.RepeatOnLanding then
          local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
          self:T( { "Landed:", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
          -- self:ReSpawn( SpawnGroupIndex )
          -- Delay respawn by three seconds due to DCS 2.5.4.26368 OB bug https://github.com/FlightControl-Master/MOOSE/issues/1076
          -- Bug was initially only for engine shutdown event but after ED "fixed" it, it now happens on landing events.
          SCHEDULER:New( nil, self.ReSpawn, { self, SpawnGroupIndex }, 3 )
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
      if EventPrefix == self.SpawnTemplatePrefix or (self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix) then
        -- todo: test if on the runway
        local Landed = SpawnGroup:GetState( SpawnGroup, "Spawn_Landed" )
        if Landed and self.RepeatOnEngineShutDown then
          local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
          self:T( { "EngineShutDown: ", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
          -- self:ReSpawn( SpawnGroupIndex )
          -- Delay respawn by three seconds due to DCS 2.5.4 OB bug https://github.com/FlightControl-Master/MOOSE/issues/1076
          SCHEDULER:New( nil, self.ReSpawn, { self, SpawnGroupIndex }, 3 )
        end
      end
    end
  end
end

--- This function is called automatically by the Spawning scheduler.
-- It is the internal worker method SPAWNing new Groups on the defined time intervals.
-- @param #SPAWN self
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

  local IsHelo = false
  
  while SpawnGroup do
    
    IsHelo = SpawnGroup:IsHelicopter()
    
    local SpawnUnits = SpawnGroup:GetUnits()

    for UnitID, UnitData in pairs( SpawnUnits ) do

      local SpawnUnit = UnitData -- Wrapper.Unit#UNIT
      local SpawnUnitName = SpawnUnit:GetName()

      self.SpawnCleanUpTimeStamps[SpawnUnitName] = self.SpawnCleanUpTimeStamps[SpawnUnitName] or {}
      local Stamp = self.SpawnCleanUpTimeStamps[SpawnUnitName]
      self:T( { SpawnUnitName, Stamp } )

      if Stamp.Vec2 then
        if (SpawnUnit:InAir() == false and SpawnUnit:GetVelocityKMH() < 1) or IsHelo then
          local NewVec2 = SpawnUnit:GetVec2() or {x=0, y=0}
          if (Stamp.Vec2.x == NewVec2.x and Stamp.Vec2.y == NewVec2.y) or (SpawnUnit:GetLife() <= 1) then
            -- If the plane is not moving or dead , and is on the ground, assign it with a timestamp...
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
        if SpawnUnit:InAir() == false or (IsHelo and SpawnUnit:GetLife() <= 1) then
          Stamp.Vec2 = SpawnUnit:GetVec2() or {x=0, y=0}
          if (SpawnUnit:GetVelocityKMH() < 1) then
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
