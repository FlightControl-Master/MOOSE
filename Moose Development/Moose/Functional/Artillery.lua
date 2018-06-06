--- **Functional** - (R2.4) Control artillery units.
-- 
-- ===
-- 
-- The ARTY class can be used to easily assign and manage targets for artillery units.
-- 
-- ## Features:
-- 
-- * Multiple targets can be assigned. No restriction on number of targets.
-- * Targets can be given a priority. Engagement of targets is executed a according to their priority.
-- * Engagements can be scheduled, i.e. will be executed at a certain time of the day.
-- * Special weapon types can be selected for each attack, e.g. cruise missiles for Naval units.
-- * Automatic rearming once the artillery is out of ammo.
-- * New targets can be added during the mission, e.g. when they are detected by recon units.
-- * Modeling of tactical nuclear shells.
-- * Targets and relocations can be assigned by placing markers on the F10 map.
-- * Finite state machine implementation. Mission designer can interact when certain events occur.
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [MOOSE - ALL Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536)
-- 
-- ====
-- @module Functional.Arty
-- @image Artillery.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ARTY class
-- @type ARTY
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Write Debug messages to DCS log file and send Debug messages to all players.
-- @field #table targets All targets assigned.
-- @field #table moves All moves assigned.
-- @field #table currentTarget Holds the current target, if there is one assigned.
-- @field #table currentMove Holds the current commanded move, if there is one assigned.
-- @field #number Nammo0 Initial amount total ammunition (shells+rockets+missiles) of the whole group.
-- @field #number Nshells0 Initial amount of shells of the whole group.
-- @field #number Nrockets0 Initial amount of rockets of the whole group.
-- @field #number Nmissiles0 Initial amount of missiles of the whole group.
-- @field #number Nukes0 Initial amount of tactical nukes of the whole group. Default is 0.
-- @field #number FullAmmo Full amount of all ammunition taking the number of alive units into account.
-- @field #number StatusInterval Update interval in seconds between status updates. Default 10 seconds.
-- @field #number WaitForShotTime Max time in seconds to wait until fist shot event occurs after target is assigned. If time is passed without shot, the target is deleted. Default is 300 seconds.
-- @field #table DCSdesc DCS descriptors of the ARTY group.
-- @field #string Type Type of the ARTY group.
-- @field #string DisplayName Extended type name of the ARTY group.
-- @field #number IniGroupStrength Inital number of units in the ARTY group.
-- @field #boolean IsArtillery If true, ARTY group has attribute "Artillery". This is automatically derived from the DCS descriptor table.
-- @field #number SpeedMax Maximum speed of ARTY group in km/h. This is determined from the DCS descriptor table.
-- @field #number Speed Default speed in km/h the ARTY group moves at. Maximum speed possible is 80% of maximum speed the group can do.
-- @field #number RearmingDistance Safe distance in meters between ARTY group and rearming group or place at which rearming is possible. Default 100 m.
-- @field Wrapper.Group#GROUP RearmingGroup Unit designated to rearm the ARTY group.
-- @field #number RearmingGroupSpeed Speed in km/h the rearming unit moves at. Default 50 km/h.
-- @field #boolean RearmingGroupOnRoad If true, rearming group will move to ARTY group or rearming place using mainly roads. Default false. 
-- @field Core.Point#COORDINATE RearmingGroupCoord Initial coordinates of the rearming unit. After rearming complete, the unit will return to this position.
-- @field Core.Point#COORDINATE RearmingPlaceCoord Coordinates of the rearming place. If the place is more than 100 m away from the ARTY group, the group will go there.
-- @field #boolean RearmingArtyOnRoad If true, ARTY group will move to rearming place using mainly roads. Default false.
-- @field Core.Point#COORDINATE InitialCoord Initial coordinates of the ARTY group.
-- @field #boolean report Arty group sends messages about their current state or target to its coaliton.
-- @field #table ammoshells Table holding names of the shell types which are included when counting the ammo. Default is {"weapons.shells"} which include most shells.
-- @field #table ammorockets Table holding names of the rocket types which are included when counting the ammo. Default is {"weapons.nurs"} which includes most unguided rockets.
-- @field #table ammomissiles Table holding names of the missile types which are included when counting the ammo. Default is {"weapons.missiles"} which includes some guided missiles.
-- @field #number Nshots Number of shots fired on current target.
-- @field #number minrange Minimum firing range in kilometers. Targets closer than this distance are not engaged. Default 0.1 km.
-- @field #number maxrange Maximum firing range in kilometers. Targets further away than this distance are not engaged. Default 10000 km.
-- @field #number nukewarhead Explosion strength of tactical nuclear warhead in kg TNT. Default 75000.
-- @field #number Nukes Number of nuclear shells, the group has available. Default is same number as normal shells. Note that if normal shells are empty, firing nukes is also not possible any more.
-- @field #number nukerange Demolition range of tactical nuclear explostions.
-- @field #boolean nukefire Ignite additional fires and smoke for nuclear explosions Default true.
-- @field #number nukefires Number of nuclear fires and subexplosions.
-- @field #boolean relocateafterfire Group will relocate after each firing task. Default false.
-- @field #number relocateRmin Minimum distance in meters the group will look for places to relocate.
-- @field #number relocateRmax Maximum distance in meters the group will look for places to relocate.
-- @field #boolean markallow If true, Players are allowed to assign targets and moves for ARTY group by placing markers on the F10 map. Default is false.
-- @field #number markkey Authorization key. Only player who know this key can assign targets and moves via markers on the F10 map. Default no authorization required.
-- @field #boolean markreadonly Marks for targets are readonly and cannot be removed by players. Default is false.
-- @field #boolean autorelocate ARTY group will automatically move to within the max/min firing range.
-- @field #number autorelocatemaxdist Max distance [m] the ARTY group will travel to get within firing range. Default 50000 m = 50 km.
-- @field #boolean autorelocateonroad ARTY group will use mainly road to automatically get within firing range. Default is false. 
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- Enables mission designers easily to assign targets for artillery units. Since the implementation is based on a Finite State Model (FSM), the mission designer can
-- interact with the process at certain events or states.
-- 
-- A new ARTY object can be created with the @{#ARTY.New}(*group*) contructor.
-- The parameter *group* has to be a MOOSE Group object and defines ARTY group.
-- 
-- The ARTY FSM process can be started by the @{#ARTY.Start}() command.
--
-- ## The ARTY Process
-- 
-- ![Process](..\Presentations\ARTY\ARTY_Process.png)
-- 
-- ### Blue Branch
-- After the FMS process is started the ARTY group will be in the state **CombatReady**. Once a target is assigned the **OpenFire** event will be triggered and the group starts
-- firing. At this point the group in in the state **Firing**.
-- When the defined number of shots has been fired on the current target the event **CeaseFire** is triggered. The group will stop firing and go back to the state **CombatReady**.
-- If another target is defined (or multiple engagements of the same target), the cycle starts anew.
-- 
-- ### Violet Branch
-- When the ARTY group runs out of ammunition, the event **Winchester** is triggered and the group enters the state **OutOfAmmo**.
-- In this state, the group is unable to engage further targets.
-- 
-- ### Red Branch
-- With the @{#ARTY.SetRearmingGroup}(*group*) command, a special group can be defined to rearm the ARTY group. If this unit has been assigned and the group has entered the state
-- **OutOfAmmo** the event **Rearm** is triggered followed by a transition to the state **Rearming**.
-- If the rearming group is less than 100 meters away from the ARTY group, the rearming process starts. If the rearming group is more than 100 meters away from the ARTY unit, the
-- rearming group is routed to a point 20 to 100 m from the ARTY group.
-- 
-- Once the rearming is complete, the **Rearmed** event is triggered and the group enters the state **CombatReady**. At this point targeted can be engaged again.
-- 
-- ### Green Branch
-- The ARTY group can be ordered to change its position via the @{#ARTY.AssignMoveCoord}() function as described below. When the group receives the command to move
-- the event **Move** is triggered and the state changes to **Moving**. When the unit arrives to its destination the event **Arrived** is triggered and the group
-- becomes **CombatReady** again.
-- 
-- Note, that the ARTY group will not open fire while it is in state **Moving**. This property differentiates artillery from tanks. 
-- 
-- ### Yellow Branch
-- When a new target is assigned via the @{#ARTY.AssignTargetCoord}() function (see below), the **NewTarget** event is triggered.
-- 
-- ## Assigning Targets
-- Assigning targets is a central point of the ARTY class. Multiple targets can be assigned simultanioulsly and are put into a queue.
-- Of course, targets can be added at any time during the mission. For example, once they are detected by a reconnaissance unit.  
-- 
-- In order to add a target, the function @{#ARTY.AssignTargetCoord}(*coord*, *prio*, *radius*, *nshells*, *maxengage*, *time*, *weapontype*, *name*) has to be used.
-- Only the first parameter *coord* is mandatory while all remaining parameters are all optional.
-- 
-- ### Parameters:
-- 
-- * *coord*: Coordinates of the target, given as @{Core.Point#COORDINATE} object.
-- * *prio*: Priority of the target. This a number between 1 (high prio) and 100 (low prio). Targets with higher priority are engaged before targets with lower priority.
-- * *radius*: Radius in meters which defines the area the ARTY group will attempt to be hitting. Default is 100 meters.
-- * *nshells*: Number of shots (shells, rockets, missiles) fired by the group at each engagement of a target. Default is 5.
-- * *maxengage*: Number of times a target is engaged.
-- * *time*: Time of day the engagement is schedule in the format "hh:mm:ss" for hh=hours, mm=minutes, ss=seconds.
-- For example "10:15:35". In the case the attack will be executed at a quarter past ten in the morning at the day the mission started.
-- If the engagement should start on the following day the format can be specified as "10:15:35+1", where the +1 denots the following day.
-- This is useful for longer running missions or if the mission starts at 23:00 hours and the attack should be scheduled at 01:00 hours on the following day.
-- Of course, later days are also possible by appending "+2", "+3", etc.
-- **Note** that the time has to be given as a string. So the enclosing quotation marks "" are important.
-- * *weapontype*: Specified the weapon type that should be used for this attack if the ARTY group has multiple weapons to engage the target.
-- For example, this is useful for naval units which carry a bigger arsenal (cannons and missiles). Default is Auto, i.e. DCS logic selects the appropriate weapon type.
-- *name*: A special name can be defined for this target. Default name are the coordinates of the target in LL DMS format. If a name is already given for another target
-- or the same target should be attacked two or more times with different parameters a suffix "#01", "#02", "#03" is automatically appended to the specified name.
-- 
-- ## Target Queue
-- In case multiple targets have been defined, it is important to understand how the target queue works.
-- 
-- Here, the essential parameters are the priority *prio*, the number of engagements *maxengage* and the scheduled *time* as described above.
-- 
-- For example, we have assigned two targets one with *prio*=10 and the other with *prio*=50 and both targets should be engaged three times (*maxengage*=3).
-- Let's first consider the case that none of the targets is scheduled to be executed at a certain time (*time*=nil).
-- The ARTY group will first engage the target with higher priority (*prio*=10). After the engagement is finished, the target with lower priority is attacked.
-- This is because the target with lower prio has been attacked one time less. After the attack on the lower priority task is finished and both targets 
-- have been engaged equally often, the target with the higher priority is engaged again. This coninues until a target has engaged three times.
-- Once the maximum number of engagements is reached, the target is deleted from the queue.
-- 
-- In other words, the queue is first sorted with respect to the number of engagements and targets with the same number of engagements are sorted with
-- respect to their priority.
-- 
-- ### Timed Engagements
-- 
-- As mentioned above, targets can be engaged at a specific time of the day via the *time* parameter.
-- 
-- If the *time* parameter is specified for a target, the first engagement of that target will happen at that time of the day and not before.
-- This also applies when multiple engagements are requested via the *maxengage* parameter. The first attack will not happen before the specifed time.
-- When that timed attack is finished, the *time* parameter is deleted and the remaining engagements are carried out in the same manner as for untimed targets (described above).
-- 
-- Of course, it can happen that a scheduled task should be executed at a time, when another target is already under attack.
-- If the priority of the target is higher than the priority of the current target, then the current attack is cancelled and the engagement of the target with the higher
-- priority is started.
-- 
-- By contrast, if the current target has a higher priority than the target scheduled at that time, the current attack is finished before the scheduled attack is started.
-- 
-- ## Determining the Amount of Ammo
-- 
-- In order to determin when a unit is out of ammo and possible initiate the rearming process it is necessary to know which types of weapons have to be counted.
-- For most artillery unit types, this is simple because they only have one type of weapon and hence ammunition.
-- 
-- However, there are more complex scenarios. For example, naval units carry a big arsenal of different ammunition types ranging from various cannon shell types
-- over surface-to-air missiles to cruise missiles. Obviously, not all of these ammo types can be employed for artillery tasks.
-- 
-- Unfortunately, there is no easy way to count only those ammo types useable as artillery. Therefore, to keep the implementation general the user
-- can specify the names of the ammo types by the following functions:
-- 
-- * @{#ARTY.SetShellTypes}(*tableofnames*): Defines the ammo types for unguided cannons, e.g. *tableofnames*={"weapons.shells"}, i.e. **all** types of shells are counted.
-- * @{#ARTY.SetRocketTypes}(*tableofnames*): Defines the ammo types of unguided rockets, e.g. *tableofnames*={"weapons.nurs"}, i.e. **all** types of rockets are counted.
-- * @{#ARTY.SetMissileTypes}(*tableofnames*): Defines the ammo types of guided missiles, e.g. is *tableofnames*={"weapons.missiles"}, i.e. **all** types of missiles are counted.
-- 
-- **Note** that the default parameters "weapons.shells", "weapons.nurs", "weapons.missiles" **should in priciple** capture all the corresponding ammo types.
-- However, the logic searches for the string "weapon.missies" in the ammo type. Especially for missiles, this string is often not contained in the ammo type descriptor.
-- 
-- One way to determin which types of ammo the unit carries, one can use the debug mode of the arty class via @{#ARTY.SetDebugON}().
-- In debug mode, the all ammo types of the group are printed to the monitor as message and can be found in the DCS.log file.   
-- 
-- ## Empoying Selected Weapons
-- 
-- If an ARTY group carries multiple weapons, which can be used for artillery task, a certain weapon type can be selected to attack the target.
-- This is done via the *weapontype* parameter of the @{#ARTY.AssignTargetCoord}(..., *weapontype*, ...) function.
-- 
-- The enumerator @{#ARTY.WeaponType} has been defined to select a certain weapon type. Supported values are:
-- 
-- * @{#ARTY.WeaponType}.Auto: Automatic weapon selection by the DCS logic. This is the default setting.
-- * @{#ARTY.WeaponType}.Cannon: Only cannons are used during the attack. Corresponding ammo type are shells and can be defined by @{#ARTY.SetShellTypes}.
-- * @{#ARTY.WeaponType}.Rockets: Only unguided are used during the attack. Corresponding ammo type are rockets/nurs and can be defined by @{#ARTY.SetRocketTypes}.
-- * @{#ARTY.WeaponType}.UnguidedAny: Any unguided weapon (cannons or rockes) will be used.
-- * @{#ARTY.WeaponType}.GuidedMissile: Any guided missiles are used during the attack. Corresponding ammo type are missiles and can be defined by @{#ARTY.SetMissileTypes}.
-- * @{#ARTY.WeaponType}.CruiseMissile: Only cruise missiles are used during the attack. Corresponding ammo type are missiles and can be defined by @{#ARTY.SetMissileTypes}.
-- * @{#ARTY.WeaponType}.TacticalNukes: Use tactical nuclear shells. This works only with units that have shells and is described below.
-- 
-- ## Assigning Moves
-- The ARTY group can be commanded to move. This is done by the @{#ARTY.AssignMoveCoord}(*coord*,*time*,*speed*,*onroad*,*cancel*,*name*) function.
-- With this multiple timed moves of the group can be scheduled easily. By default, these moves will only be executed if the group is state **CombatReady**.
-- 
-- ### Parameters
-- 
-- * *coord*: Coordinates where the group should move to given as @{Core.Point#COORDINATE} object.
-- * *time*: The time when the move should be executed. This has to be given as a string in the format "hh:mm:ss" (hh=hours, mm=minutes, ss=seconds).
-- * *speed*: Speed of the group in km/h.
-- * *onroad*: If this parameter is set to true, the group uses mainly roads to get to the commanded coordinates.
-- * *cancel*: If set to true, any current engagement of targets is cancelled at the time the move should be executed.
-- * *name*: Can be used to set a user defined name of the move. By default the name is created from the LL DMS coordinates.
-- 
-- ## Automatic Rearming
-- 
-- If an ARTY group runs out of ammunition, it can be rearmed automatically.
-- 
-- ### Rearming Group
-- The first way to activate the automatic rearming is to define a rearming group with the function @{#ARTY.SetRearmingGroup}(*group*). For the blue side, this
-- could be a M181 transport truck and for the red side an Ural-375 truck.
-- 
-- Once the ARTY group is out of ammo and the **Rearm** event is triggered, the defined rearming truck will drive to the ARTY group.
-- So the rearming truck does not have to be placed nearby the artillery group. When the rearming is complete, the rearming truck will drive back to its original position.
-- 
-- ### Rearming Place
-- The second alternative is to define a rearming place, e.g. a FRAP, airport or any other warehouse. This is done with the function @{#ARTY.SetRearmingPlace}(*coord*).
-- The parameter *coord* specifies the coordinate of the rearming place which should not be further away then 100 meters from the warehouse.
-- 
-- When the **Rearm** event is triggered, the ARTY group will move to the rearming place. Of course, the group must be mobil. So for a mortar this rearming procedure would not work.
-- 
-- After the rearming is complete, the ARTY group will move back to its original position and resume normal operations.
-- 
-- ### Rearming Group **and** Rearming Place
-- If both a rearming group *and* a rearming place are specified like described above, both the ARTY group and the rearming truck will move to the rearming place and meet there.
-- 
-- After the rearming is complete, both groups will move back to their original positions.
-- 
-- ## Tactical Nukes
-- 
-- ARTY groups that can fire shells can also be used to fire tactical nukes. This is achieved by setting the weapon type to **ARTY.WeaponType.TacticalNukes** in the
-- @{#ARTY.AssignTargetCoord}() function.
--
-- By default, they group does not have any nukes available. To give the group the ability the function @{#ARTY.SetTacNukeShells}(*n*) can be used.
-- This supplies the group with *n* nuclear shells, where *n* is restricted to the number of conventional shells the group can carry.
-- Note that the group must always have convenctional shells left in order to fire a nuclear shell. 
-- 
-- The default explostion strength is 0.075 kilo tons TNT. The can be changed with the @{#ARTY.SetTacNukeWarhead}(*strength*), where *strength* is given in kilo tons TNT.
--
-- 
-- ## Assignments via Markers on F10 Map
-- 
-- Targets and relocations can be assigned by players via placing a mark on the F10 map. The marker text must contain certain keywords.
-- 
-- This feature can be turned on with the @{#ARTY.SetMarkAssignmentsOn}(*key*). The parameter *key* is optional. When set, it can be used as PIN, i.e. only
-- players who know the correct key are able to assign and cancel targets or relocations. Default behavior is that all players belonging to the same coalition as the
-- ARTY group are able to assign targets and moves without a key.
-- 
-- ### Target Assignments
-- A new target can be assigned by writing **arty engage** in the marker text. This can be followed by a comma separated lists of optional keywords and parameters:
-- 
-- * *time* Time for which which the engagement is schedules, e.g. 08:42. Default is as soon as possible.
-- * *prio*  Priority of the engagement as number between 1 (high prio) and 100 (low prio). Default is 50.
-- * *shots* Number of shots (shells, rockets or missiles) fired at each engagement. Default is 5.
-- * *maxengage* Number of times the target is engaged. Default is 1.
-- * *radius* Scattering radius of the fired shots in meters. Default is 100 m.
-- * *weapon* Type of weapon to be used. Valid parameters are *cannon*, *rocket*, *missile*, *nuke*. Default is automatic selection.
-- * *battery* Name of the ARTY group that the target is assigned to. Note that the name is case sensitive and has to be given in quotation marks. Default is all ARTY groups of the right coalition.
-- * *key* A number to authorize the target assignment. Only specifing the correct number will trigger an engagement.
-- * *readonly* Marker cannot be deleted by users any more. Hence, assignment cannot be cancelled by removing the marker.
-- 
-- Here are examples of valid marker texts:
--      arty engage!
--      arty engage! shots 20, prio 10, time 08:15, weapon cannons
--      arty engage! battery "Blue Paladin 1" "Blue MRLS 1", shots 10, time 10:15
--      arty engage! battery "Blue MRLS 1", key 666
--      arty engage, battery "Paladin Alpha", weapon nukes, shots 1, time 20:15
--      
-- Note that the keywords and parameters are case insensitve. Only exception are the battery group names. These must be exactly the same as the names of the goups defined 
-- in the mission editor.
-- 
-- ### Relocation Assignments
-- 
-- Markers can also be used to relocate the group with the keyphrase **arty move**. This is done in a similar way as assigning targets. Here, the (optional) keywords and parameters are:
-- 
-- * *time* Time for which which the relocation/move is schedules, e.g. 08:42. Default is as soon as possible.
-- * *speed* The speed in km/h the group will drive at. Default is 70% of its max possible speed.
-- * *on road* Group will use mainly roads. Default is off, i.e. it will go in a straight line from its current position to the assigned coordinate.
-- * *canceltarget* Group will cancel all running firing engagements and immidiately start to move. Default is that group will wait until is current assignment is over.
-- * *battery* Name of the ARTY group that the relocation is assigned to.
-- * *key* A number to authorize the target assignment. Only specifing the correct number will trigger an engagement.
-- * *readonly* Marker cannot be deleted by users any more. Hence, assignment cannot be cancelled by removing the marker.
-- 
-- Here are some examples:
--      arty move
--      arty move! time 23:45, speed 50, on road
--      arty move! battery "Blue Paladin"
--      arty move, battery "Blue MRLS", canceltarget, speed 10, on road
--      
-- ### Coordinate Independent Commands
-- 
-- There are a couple of commands, which are independent of the position where the marker is placed.
-- These commands are
--      arty move, cancelcurrent
-- which will cancel the current relocation movement. Of course, this can be combined with the *battery* keyword to address a certain battery.
-- Same goes for targets, e.g.
--     arty engage, battery "Paladin Alpha", cancelcurrent
-- which will cancel all running firing tasks.
-- 
-- ### General Requests
-- 
-- Marks can also be to send requests to the ARTY group. This is done by the keyword **arty request**, which can have the keywords
-- * *target* All assigned targets are reported.
-- * *move* All assigned relocation moves are reported.
-- * *ammo* Current ammunition status is reported.
-- 
-- For example
--      arty request, ammo
--      arty request, battery "Paladin Bravo", targets
--      arty request, battery "MRLS Charly", move
-- 
-- 
-- ## Fine Tuning
-- 
-- The mission designer has a few options to tailor the ARTY object according to his needs.
-- 
-- * @{#ARTY.SetRelocateAfterEngagement}() will cause the ARTY group to change its position after each firing assignment. 
-- * @{#ARTY.SetRelocateDistance}(*rmax*, *rmin*) sets the max/min distance for relocation of the group. Default distance is randomly between 300 and 800 m.
-- * @{#ARTY.RemoveAllTargets}() removes all targets from the target queue.
-- * @{#ARTY.RemoveTarget}(*name*) deletes the target with *name* from the target queue.
-- * @{#ARTY.SetMaxFiringRange}(*range*) defines the maximum firing range. Targets further away than this distance are not engaged.
-- * @{#ARTY.SetMinFiringRange}(*range*) defines the minimum firing range. Targets closer than this distance are not engaged.
-- * @{#ARTY.SetRearmingGroup}(*group*) sets the group resposible for rearming of the ARTY group once it is out of ammo.
-- * @{#ARTY.SetReportON}() and @{#ARTY.SetReportOFF}() can be used to enable/disable status reports of the ARTY group send to all coalition members.
-- * @{#ARTY.SetWaitForShotTime}(*waittime*) sets the time after which a target is deleted from the queue if no shooting event occured after the target engagement started.
-- Default is 300 seconds. Note that this can for example happen, when the assigned target is out of range.
-- *  @{#ARTY.SetDebugON}() and @{#ARTY.SetDebugOFF}() can be used to enable/disable the debug mode.
-- 
-- ## Examples
-- 
-- ### Assigning Multiple Targets
-- This basic example illustrates how to assign multiple targets and defining a rearming group.
--     -- Creat a new ARTY object from a Paladin group.
--     paladin=ARTY:New(GROUP:FindByName("Blue Paladin"))
--     
--     -- Define a rearming group. This is a Transport M818 truck.
--     paladin:SetRearmingGroup(GROUP:FindByName("Blue Ammo Truck"))
--     
--     -- Set the max firing range. A Paladin unit has a range of 20 km.
--     paladin:SetMaxFiringRange(20)
--     
--     -- Low priorty (90) target, will be engage last. Target is engaged two times. At each engagement five shots are fired.
--     paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 3"):GetCoordinate(),  90, nil,  5, 2)
--     -- Medium priorty (nil=50) target, will be engage second. Target is engaged two times. At each engagement ten shots are fired.
--     paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 1"):GetCoordinate(), nil, nil, 10, 2)
--     -- High priorty (10) target, will be engage first. Target is engaged three times. At each engagement twenty shots are fired.
--     paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 2"):GetCoordinate(),  10, nil, 20, 3)
--     
--     -- Start ARTY process.
--     paladin:Start()
-- **Note**
-- 
-- * If a parameter should be set to its default value, it has to be set to *nil* if other non-default parameters follow. Parameters at the end can simply be skiped.
-- * In this example, the target coordinates are taken from groups placed in the mission edit using the COORDINATE:GetCoordinate() function.   
-- 
-- ### Scheduled Engagements
--     -- Mission starts at 8 o'clock.
--     -- Assign two scheduled targets.
--     
--     -- Create ARTY object from Paladin group.
--     paladin=ARTY:New(GROUP:FindByName("Blue Paladin"))
--     
--     -- Assign target coordinates. Priority=50 (medium), radius=100 m, use 5 shells per engagement, engage 1 time at two past 8 o'clock.
--     paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 1"):GetCoordinate(), 50, 100,  5, 1, "08:02:00", ARTY.WeaponType.Auto, "Target 1")
--     
--     -- Assign target coordinates. Priority=10 (high), radius=300 m, use 10 shells per engagement, engage 1 time at seven past 8 o'clock.
--     paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 2"):GetCoordinate(), 10, 300, 10, 1, "08:07:00", ARTY.WeaponType.Auto, "Target 2")
--     
--     -- Start ARTY process.
--     paladin:Start()
-- 
-- ### Specific Weapons
-- This example demonstrates how to use specific weapons during an engagement.
--     -- Define the Normandy as ARTY object.
--     normandy=ARTY:New(GROUP:FindByName("Normandy"))
--     
--     -- Add target: prio=50, radius=300 m, number of missiles=20, number of engagements=1, start time=08:05 hours, only use cruise missiles for this attack.
--     normandy:AssignTargetCoord(GROUP:FindByName("Red Targets 1"):GetCoordinate(),  20, 300,  50, 1, "08:01:00", ARTY.WeaponType.CruiseMissile)
--     
--     -- Add target: prio=50, radius=300 m, number of shells=100, number of engagements=1, start time=08:15 hours, only use cannons during this attack.
--     normandy:AssignTargetCoord(GROUP:FindByName("Red Targets 1"):GetCoordinate(),  50, 300, 100, 1, "08:15:00", ARTY.WeaponType.Cannon)
--     
--     -- Define shells that are counted to check whether the ship is out of ammo.
--     -- Note that this is necessary because the Normandy has a lot of other shell type weapons which cannot be used to engage ground targets in an artillery style manner.
--     normandy:SetShellTypes({"MK45_127"})
--        
--     -- Define missile types that are counted.
--     normandy:SetMissileTypes({"BGM"})
--        
--     -- Start ARTY process.
--     normandy:Start()
--
-- 
-- @field #ARTY
ARTY={
  ClassName="ARTY",
  Debug=false,
  targets={},
  moves={},
  currentTarget=nil,
  currentMove=nil,
  Nammo0=0,
  Nshells0=0,
  Nrockets0=0,
  Nmissiles0=0,
  Nukes0=0,
  FullAmmo=0,
  defaultROE="weapon_hold",
  StatusInterval=10,
  WaitForShotTime=300,
  DCSdesc=nil,
  Type=nil,
  DisplayName=nil,
  IniGroupStrength=0,
  IsArtillery=nil,
  RearmingDistance=100,
  RearmingGroup=nil,
  RearmingGroupSpeed=50,
  RearmingGroupOnRoad=false,
  RearmingGroupCoord=nil,
  RearmingPlaceCoord=nil,
  RearmingArtyOnRoad=false,
  InitialCoord=nil,
  report=true,
  ammoshells={},
  ammorockets={},
  ammomissiles={},
  Nshots=0,
  minrange=300,
  maxrange=1000000,
  nukewarhead=75000,
  Nukes=nil,
  nukefire=false,
  nukefires=nil,
  nukerange=nil,
  relocateafterfire=false,
  relocateRmin=300,
  relocateRmax=800,
  markallow=false,
  markkey=nil,
  markreadonly=false,
  autorelocate=false,
  autorelocatemaxdist=50000,
  autorelocateonroad=false,
}

--- Weapong type ID. http://wiki.hoggit.us/view/DCS_enum_weapon_flag
-- @list WeaponType
ARTY.WeaponType={
  Auto=1073741822,
  Cannon=805306368,
  Rockets=30720,
  UnguidedAny=805339120,
  GuidedMissile=268402688,
  CruiseMissile=2097152,
  AntiShipMissile=65536,
  TacticalNukes=666,
}

--- Database of common artillery unit properties.
-- @list db
ARTY.db={
  ["2B11 mortar"] = {  -- type "2B11 mortar"
    minrange   = 500,  -- correct?
    maxrange   = 7000, -- 7 km
    reloadtime = 30,   -- 30 sec
  },
  ["SPH 2S1 Gvozdika"] = { -- type "SAU Gvozdika"
    minrange   = 300,      -- correct?
    maxrange   = 15000,    -- 15 km
    reloadtime = nil,      -- unknown
  },
  ["SPH 2S19 Msta"] = { --type "SAU Msta", alias "2S19 Msta"
    minrange   = 300,     -- correct?
    maxrange   = 23500,   -- 23.5 km
    reloadtime = nil,     -- unknown
  },
  ["SPH 2S3 Akatsia"] = { -- type "SAU Akatsia", alias "2S3 Akatsia"
    minrange   = 300,   -- correct?
    maxrange   = 17000, -- 17 km
    reloadtime = nil,   -- unknown
  },
  ["SPH 2S9 Nona"] = { --type "SAU 2-C9"
    minrange   = 500,   -- correct?
    maxrange   = 7000,  -- 7 km
    reloadtime = nil,   -- unknown
  },
  ["SPH M109 Paladin"] = { -- type "M-109", alias "M109"
    minrange   = 300,     -- correct?
    maxrange   = 22000,   -- 22 km
    reloadtime = nil,   -- unknown
  },
  ["SpGH Dana"] = {       -- type "SpGH_Dana"
    minrange   = 300,     -- correct?
    maxrange   = 18700,   -- 18.7 km
    reloadtime = nil,     -- unknown
  },
  ["MLRS BM-21 Grad"] = { --type "Grad-URAL", alias "MLRS BM-21 Grad"
    minrange = 5000,  --  5 km
    maxrange = 19000, -- 19 km
    reloadtime = 420, -- 7 min
  },
  ["MLRS 9K57 Uragan BM-27"] = { -- type "Uragan_BM-27"
    minrange   = 11500, -- 11.5 km
    maxrange   = 35800, -- 35.8 km
    reloadtime = 840,   -- 14 min
  },
  ["MLRS 9A52 Smerch"] = { -- type "Smerch"
    minrange   = 20000, -- 20 km
    maxrange   = 70000, -- 70 km
    reloadtime = 2160,  -- 36 min
  },
  ["MLRS M270"] = { --type "MRLS", alias "M270 MRLS"
    minrange   = 10000, -- 10 km
    maxrange   = 32000, -- 32 km
    reloadtime = 540,   -- 9 min
  },
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
ARTY.id="ARTY | "

--- Arty script version.
-- @field #string version
ARTY.version="0.9.94"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- DONE: Delete targets from queue user function.
-- DONE: Delete entire target queue user function.
-- DONE: Add weapon types. Done but needs improvements.
-- DONE: Add user defined rearm weapon types.
-- DONE: Check if target is in range. Maybe this requires a data base with the ranges of all arty units. <solved by user function>
-- DONE: Make ARTY move to rearming position.
-- DONE: Check that right rearming vehicle is specified. Blue M818, Red Ural-375. Are there more? <user needs to know!>
-- DONE: Check if ARTY group is still alive.
-- DONE: Handle dead events.
-- DONE: Abort firing task if no shooting event occured with 5(?) minutes. Something went wrong then. Min/max range for example.
-- DONE: Improve assigned time for engagement. Next day?
-- DONE: Improve documentation.
-- TODO: Add pseudo user transitions. OnAfter...
-- DONE: Make reaming unit a group.
-- DONE: Write documenation.
-- DONE: Add command move to make arty group move.
-- DONE: remove schedulers for status event.
-- TODO: Improve handling of special weapons. When winchester if using selected weapons?
-- TODO: Handle rearming for ships.
-- TODO: Make coordinate after rearming general, i.e. also work after the group has moved to anonther location.
-- TODO: Add set commands via markers. E.g. set rearming place.
-- TODO: Test stationary types like mortas ==> rearming etc.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new ARTY object.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group The GROUP object for which artillery tasks should be assigned.
-- @return #ARTY ARTY object.
-- @return nil If group does not exist or is not a ground or naval group.
function ARTY:New(group)
  BASE:F2(group)

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #ARTY
  
  -- Check that group is present.
  if group then
    self:T(ARTY.id..string.format("ARTY script version %s. Added group %s.", ARTY.version, group:GetName()))
  else
    self:E(ARTY.id.."ERROR: Requested ARTY group does not exist! (Has to be a MOOSE group.)")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
  if group:IsGround()==false and group:IsShip()==false then
    self:E(ARTY.id..string.format("ERROR: ARTY group %s has to be a GROUND or SHIP group!", group:GetName()))
    return nil
  end  
  
  -- Set the controllable for the FSM.
  self:SetControllable(group)
  
  -- Set the initial coordinates of the ARTY group.
  self.InitialCoord=group:GetCoordinate()
  
  -- Get DCS descriptors of group.
  local DCSgroup=Group.getByName(group:GetName())
  local DCSunit=DCSgroup:getUnit(1)
  self.DCSdesc=DCSunit:getDesc()
  
  --self.DCSdesc=group:GetDesc()
  
  -- DCS descriptors.
  self:T3(ARTY.id.."DCS descriptors for group "..group:GetName())
  for id,desc in pairs(self.DCSdesc) do
    self:T3({id=id, desc=desc})
  end
  
  -- Maximum speed in km/h.
  self.SpeedMax=group:GetSpeedMax()
  
  -- Set speed to 0.7 of maximum.
  self.Speed=self.SpeedMax * 0.7
  
  -- Displayed name (similar to type name below)
  self.DisplayName=self.DCSdesc.displayName
  
  -- Is this infantry or not.
  self.IsArtillery=DCSunit:hasAttribute("Artillery")
  
  -- Type of group.
  self.Type=group:GetTypeName()
  
  -- Initial group strength.
  self.IniGroupStrength=#group:GetUnits()

  ---------------  
  -- Transitions:
  ---------------

  -- Entry.
  self:AddTransition("*",           "Start",       "CombatReady")
  
  -- Blue branch.
  self:AddTransition("CombatReady", "OpenFire",    "Firing")
  self:AddTransition("Firing",      "CeaseFire",   "CombatReady")
  
  -- Violett branch.
  self:AddTransition("CombatReady", "Winchester",  "OutOfAmmo")

  -- Red branch.  
  self:AddTransition({"CombatReady", "OutOfAmmo"},  "Rearm",       "Rearming")
  self:AddTransition("Rearming",                    "Rearmed",     "Rearmed")
    
  -- Green branch.
  self:AddTransition("*",           "Move",        "Moving")
  self:AddTransition("Moving",      "Arrived",     "Arrived")
  
  -- Yellow branch.
  self:AddTransition("*",           "NewTarget",   "*")
  
  -- Not in diagram.
  self:AddTransition("*",           "CombatReady", "CombatReady")
  self:AddTransition("*",           "Status",      "*")
  self:AddTransition("*",           "NewMove",     "*")
  self:AddTransition("*",           "Dead",        "*")
  
  -- Unknown transitons. To be checked if adding these causes problems.
  self:AddTransition("Rearming",    "Arrived",     "Rearming")
  self:AddTransition("Rearming",    "Move",        "Rearming")
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Assign target coordinates to the ARTY group. Only the first parameter, i.e. the coordinate of the target is mandatory. The remaining parameters are optional and can be used to fine tune the engagement.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates of the target.
-- @param #number prio (Optional) Priority of target. Number between 1 (high) and 100 (low). Default 50.
-- @param #number radius (Optional) Radius. Default is 100 m.
-- @param #number nshells (Optional) How many shells (or rockets) are fired on target per engagement. Default 5.
-- @param #number maxengage (Optional) How many times a target is engaged. Default 1.
-- @param #string time (Optional) Day time at which the target should be engaged. Passed as a string in format "08:13:45". Current task will be canceled.
-- @param #number weapontype (Optional) Type of weapon to be used to attack this target. Default ARTY.WeaponType.Auto, i.e. the DCS logic automatically determins the appropriate weapon.
-- @param #string name (Optional) Name of the target. Default is LL DMS coordinate of the target. If the name was already given, the numbering "#01", "#02",... is appended automatically.
-- @param #boolean unique (Optional) Target is unique. If the target name is already known, the target is rejected. Default false.
-- @return #string Name of the target. Can be used for further reference, e.g. deleting the target from the list.
-- @usage paladin=ARTY:New(GROUP:FindByName("Blue Paladin"))
-- paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 1"):GetCoordinate(), 10, 300, 10, 1, "08:02:00", ARTY.WeaponType.Auto, "Target 1")
-- paladin:Start()
function ARTY:AssignTargetCoord(coord, prio, radius, nshells, maxengage, time, weapontype, name, unique)
  self:F({coord=coord, prio=prio, radius=radius, nshells=nshells, maxengage=maxengage, time=time, weapontype=weapontype, name=name, unique=unique})
  
  -- Set default values.
  nshells=nshells or 5
  radius=radius or 100
  maxengage=maxengage or 1
  prio=prio or 50
  prio=math.max(  1, prio)
  prio=math.min(100, prio)
  if unique==nil then
    unique=false
  end
  weapontype=weapontype or ARTY.WeaponType.Auto

  -- Check if we have a coordinate object.
  local text=nil
  if coord:IsInstanceOf("GROUP") then
    text="WARNING: ARTY:AssignTargetCoordinate(coord, ...) needs a COORDINATE object as first parameter - you gave a GROUP. Converting to COORDINATE..."
    coord=coord:GetCoordinate()
  elseif coord:IsInstanceOf("UNIT") then
    text="WARNING: ARTY:AssignTargetCoordinate(coord, ...) needs a COORDINATE object as first parameter - you gave a UNIT. Converting to COORDINATE..."
    coord=coord:GetCoordinate()
  elseif coord:IsInstanceOf("POSITIONABLE") then
    text="WARNING: ARTY:AssignTargetCoordinate(coord, ...) needs a COORDINATE object as first parameter - you gave a POSITIONABLE. Converting to COORDINATE..."
    coord=coord:GetCoordinate()
  elseif coord:IsInstanceOf("COORDINATE") then
    -- Nothing to do here.
  else
    text="ERROR: ARTY:AssignTargetCoordinate(coord, ...) needs a COORDINATE object as first parameter!"
    MESSAGE:New(text, 30):ToAll()
    self:E(ARTY.id..text)
    return nil
  end
  if text~=nil then
    self:E(ARTY.id..text)
  end
  
  -- Name of the target.
  local _name=name or coord:ToStringLLDMS() 
  local _unique=true
    
  -- Check if the name has already been used for another target. If so, the function returns a new unique name.
  _name,_unique=self:_CheckName(self.targets, _name, not unique)
  
  -- Target name should be unique and is not.
  if unique==true and _unique==false then
    self:T(ARTY.id..string.format("%s: target %s should have a unique name but name was already given. Rejecting target!", self.Controllable:GetName(), _name))
    return nil
  end
  
  -- Time in seconds.
  local _time=self:_ClockToSeconds(time)
  
  -- Prepare target array.
  local _target={name=_name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false, prio=prio, maxengage=maxengage, time=_time, weapontype=weapontype}
  
  -- Add to table.
  table.insert(self.targets, _target)
  
  -- Trigger new target event.
  self:__NewTarget(1, _target)
  
  return _name
end

--- Assign coordinate to where the ARTY group should move.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates of the new position.
-- @param #string time (Optional) Day time at which the group should start moving. Passed as a string in format "08:13:45". Default is now.
-- @param #number speed (Optinal) Speed in km/h the group should move at. Default 70% of max posible speed of group.
-- @param #boolean onroad (Optional) If true, group will mainly use roads. Default off, i.e. go directly towards the specified coordinate.
-- @param #boolean cancel (Optional) If true, cancel any running attack when move should begin. Default is false.
-- @param #string name (Optional) Name of the coordinate. Default is LL DMS string of the coordinate. If the name was already given, the numbering "#01", "#02",... is appended automatically.
-- @param #boolean unique (Optional) Move is unique. If the move name is already known, the move is rejected. Default false.
-- @return #string Name of the move. Can be used for further reference, e.g. deleting the move from the list.
function ARTY:AssignMoveCoord(coord, time, speed, onroad, cancel, name, unique)
  self:F({coord=coord, time=time, speed=speed, onroad=onroad, cancel=cancel, name=name, unique=unique})
    
  -- Default
  if unique==nil then
    unique=false
  end
  
  -- Name of the target.
  local _name=name or coord:ToStringLLDMS()
  local _unique=true
  
  -- Check if the name has already been used for another target. If so, the function returns a new unique name.
  _name,_unique=self:_CheckName(self.moves, _name, not unique)
  
  -- Move name should be unique and is not.
  if unique==true and _unique==false then
    self:T(ARTY.id..string.format("%s: move %s should have a unique name but name was already given. Rejecting move!", self.Controllable:GetName(), _name))
    return nil
  end
      
  -- Default is current time if no time was specified.
  time=time or self:_SecondsToClock(timer.getAbsTime())
  
  -- Get max speed of group.
  local speedmax=self.Controllable:GetSpeedMax()
  
  -- Set speed.
  if speed then
    -- Make sure, given speed is less than max phycially possible speed of group.
    speed=math.min(speed, speedmax)
  elseif self.Speed then
   speed=self.Speed
  else
    speed=speedmax*0.7
  end
    
  -- Default is off road.
  if onroad==nil then
    onroad=false
  end

  -- Default is not to cancel a running attack.
  if cancel==nil then
    cancel=false
  end
  
  -- Time in seconds.
  local _time=self:_ClockToSeconds(time)
  
  -- Prepare move array.
  local _move={name=_name, coord=coord, time=_time, speed=speed, onroad=onroad, cancel=cancel}
  
  -- Add to table.
  table.insert(self.moves, _move)
  
  return _name
end

--- Set minimum firing range. Targets closer than this distance are not engaged.
-- @param #ARTY self
-- @param #number range Min range in kilometers. Default is 0.1 km.
function ARTY:SetMinFiringRange(range)
  self:F({range=range})
  self.minrange=range*1000 or 100
end

--- Set maximum firing range. Targets further away than this distance are not engaged.
-- @param #ARTY self
-- @param #number range Max range in kilometers. Default is 1000 km.
function ARTY:SetMaxFiringRange(range)
  self:F({range=range})
  self.maxrange=range*1000 or 1000*1000
end

--- Set time interval between status updates. During the status check, new events are triggered.
-- @param #ARTY self
-- @param #number interval Time interval in seconds. Default 10 seconds.
function ARTY:SetStatusInterval(interval)
  self:F({interval=interval})
  self.StatusInterval=interval or 10
end

--- Set time how it is waited a unit the first shot event happens. If no shot is fired after this time, the task to fire is aborted and the target removed.
-- @param #ARTY self
-- @param #number waittime Time in seconds. Default 300 seconds.
function ARTY:SetWaitForShotTime(waittime)
  self:F({waittime=waittime})
  self.WaitForShotTime=waittime or 300
end

--- Define the safe distance between ARTY group and rearming unit or rearming place at which rearming process is possible.
-- @param #ARTY self
-- @param #number distance Safe distance in meters. Default is 100 m. 
function ARTY:SetRearmingDistance(distance)
  self:F({distance=distance})
  self.RearmingDistance=distance or 100
end

--- Assign a group, which is responsible for rearming the ARTY group. If the group is too far away from the ARTY group it will be guided towards the ARTY group.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group that is supposed to rearm the ARTY group.
function ARTY:SetRearmingGroup(group)
  self:F({group=group})
  self.RearmingGroup=group
end

--- Set the speed the rearming group moves at towards the ARTY group or the rearming place.
-- @param #ARTY self
-- @param #number speed Speed in km/h. Default 50 km/h.
function ARTY:SetRearmingGroupSpeed(speed)
  self:F({speed=speed})
  self.RearmingGroupSpeed=speed or 50
end

--- Define if rearming group uses mainly roads to drive to the ARTY group or rearming place. 
-- @param #ARTY self
-- @param #boolean onroad If true, rearming group uses mainly roads. If false, it drives directly to the ARTY group or rearming place.
function ARTY:SetRearmingGroupOnRoad(onroad)
  self:F({onroad=onroad})
  if onroad==nil then
    onroad=true
  end
  self.RearmingGroupOnRoad=onroad
end

--- Define if ARTY group uses mainly roads to drive to the rearming place. 
-- @param #ARTY self
-- @param #boolean onroad If true, ARTY group uses mainly roads. If false, it drives directly to the rearming place.
function ARTY:SetRearmingArtyOnRoad(onroad)
  self:F({onroad=onroad})
  if onroad==nil then
    onroad=true
  end
  self.RearmingArtyOnRoad=onroad
end

--- Defines the rearming place of the ARTY group. If the place is too far away from the ARTY group it will be routed to the place.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates of the rearming place.
function ARTY:SetRearmingPlace(coord)
  self:F({coord=coord})
  self.RearmingPlaceCoord=coord
end

--- Set automatic relocation of ARTY group if a target is assigned which is out of range. The unit will drive automatically towards or away from the target to be in max/min firing range.
-- @param #ARTY self
-- @param #number maxdistance (Optional) The maximum distance in km the group will travel to get within firing range. Default is 50 km. No automatic relocation is performed if targets are assigned which are further away.
-- @param #boolean onroad (Optional) If true, ARTY group uses roads whenever possible. Default false, i.e. group will move in a straight line to the assigned coordinate. 
function ARTY:SetAutomaticRelocate(maxdistance, onroad)
  self:F({distance=maxdistance, onroad=onroad})
  self.autorelocate=true
  self.autorelocatemaxdist=maxdistance or 50
  self.autorelocatemaxdist=self.autorelocatemaxdist*1000
  if onroad==nil then
    onroad=false
  end
  self.autorelocateonroad=onroad
end

--- Report messages of ARTY group turned on. This is the default.
-- @param #ARTY self
function ARTY:SetReportON()
  self.report=true
end

--- Report messages of ARTY group turned off. Default is on.
-- @param #ARTY self
function ARTY:SetReportOFF()
  self.report=false
end

--- Turn debug mode on. Information is printed to screen.
-- @param #ARTY self
function ARTY:SetDebugON()
  self.Debug=true
end

--- Turn debug mode off. This is the default setting.
-- @param #ARTY self
function ARTY:SetDebugOFF()
  self.Debug=false
end

--- Delete a target from target list. If the target is currently engaged, it is cancelled.
-- @param #ARTY self
-- @param #string name Name of the target.
function ARTY:RemoveTarget(name)
  self:F2(name)
  
  -- Get target ID from namd
  local id=self:_GetTargetIndexByName(name)
  
  if id then
  
    -- Remove target from table.
    self:T(ARTY.id..string.format("Group %s: Removing target %s (id=%d).", self.Controllable:GetName(), name, id))
    table.remove(self.targets, id)
  
    -- Delete marker belonging to this engagement.
    if self.markallow then
      local batteryname,markTargetID, markMoveID=self:_GetMarkIDfromName(name)
      if batteryname==self.Controllable:GetName() and markTargetID~=nil then
        COORDINATE:RemoveMark(markTargetID)
      end 
    end
        
  end
  self:T(ARTY.id..string.format("Group %s: Number of targets = %d.", self.Controllable:GetName(), #self.targets))
end

--- Delete a move from move list.
-- @param #ARTY self
-- @param #string name Name of the target.
function ARTY:RemoveMove(name)
  self:F2(name)
  
  -- Get move ID from name.
  local id=self:_GetMoveIndexByName(name)
  
  if id then
  
    -- Remove move from table.
    self:T(ARTY.id..string.format("Group %s: Removing move %s (id=%d).", self.Controllable:GetName(), name, id))
    table.remove(self.moves, id)
    
    -- Delete marker belonging to this relocation move.
    if self.markallow then
      local batteryname,markTargetID,markMoveID=self:_GetMarkIDfromName(name)
      if batteryname==self.Controllable:GetName() and markMoveID~=nil then
        COORDINATE:RemoveMark(markMoveID)
      end
    end
    
  end
  self:T(ARTY.id..string.format("Group %s: Number of moves = %d.", self.Controllable:GetName(), #self.moves))
end

--- Delete ALL targets from current target list.
-- @param #ARTY self
function ARTY:RemoveAllTargets()
  self:F2()
  for _,target in pairs(self.targets) do
    self:RemoveTarget(target.name)
  end
end

--- Define shell types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of shell type names.
function ARTY:SetShellTypes(tableofnames)
  self:F2(tableofnames)
  self.ammoshells={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammoshells, _type)
  end
end

--- Define rocket types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of rocket type names.
function ARTY:SetRocketTypes(tableofnames)
  self:F2(tableofnames)
  self.ammorockets={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammorockets, _type)
  end
end

--- Define missile types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of rocket type names.
function ARTY:SetMissileTypes(tableofnames)
  self:F2(tableofnames)
  self.ammomissiles={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammomissiles, _type)
  end
end

--- Set number of tactical nuclear warheads available to the group.
-- Note that it can be max the number of normal shells. Also if all normal shells are empty, firing nuclear shells is also not possible any more until group gets rearmed.
-- @param #ARTY self
-- @param #number n Number of warheads for the whole group.
function ARTY:SetTacNukeShells(n)
  self.Nukes=n
end

--- Set nuclear warhead explosion strength.
-- @param #ARTY self
-- @param #number strength Explosion strength in kilo tons TNT. Default is 0.075 kt.
function ARTY:SetTacNukeWarhead(strength)
  self.nukewarhead=strength or 0.075
  self.nukewarhead=self.nukewarhead*1000*1000 -- convert to kg TNT.
end

--- Set nuclear fires and extra demolition explosions.
-- @param #ARTY self
-- @param #number nfires (Optional) Number of big smoke and fire objects created in the demolition zone.
-- @param #number demolitionrange (Optional) Demolition range in meters.
function ARTY:SetTacNukeFires(nfires, range)
  self.nukefire=true
  self.nukefires=nfires
  self.nukerange=range
end

--- Set relocate after firing. Group will find a new location after each engagement. Default is off
-- @param #ARTY self
-- @param #number switch (Optional) If true, activate relocation. If false, deactivate relocation.
function ARTY:SetRelocateAfterEngagement(switch)
  if switch==nil then
    switch=true
  end
  self.relocateafterfire=switch
end

--- Set relocation distance.
-- @param #ARTY self
-- @param #number rmax (Optional) Max distance in meters, the group will move to relocate. Default is 800 m.
-- @param #number rmin (Optional) Min distance in meters, the group will move to relocate. Default is 300 m.
function ARTY:SetRelocateDistance(rmax, rmin)
  self.relocateRmax=rmax or 800
  self.relocateRmin=rmin or 300
end

--- Enable assigning targets and moves by placing markers on the F10 map.
-- @param #ARTY self
-- @param #number key (Optional) Authorization key. Only players knowing this key can assign targets. Default is no authorization required.
-- @param #boolean readonly (Optional) Marks are readonly and cannot be removed by players. This also means that targets cannot be cancelled by removing the mark. Default false.
function ARTY:SetMarkAssignmentsOn(key, readonly)
  self.markkey=key
  self.markallow=true
  if readonly==nil then
    self.markreadonly=false
  end
end

--- Disable assigning targets by placing markers on the F10 map.
-- @param #ARTY self
function ARTY:SetMarkTargetsOff()
  self.markallow=false
  self.markkey=nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Start Event
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Start" event. Initialized ROE and alarm state. Starts the event handler.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterStart(Controllable, From, Event, To)
  self:_EventFromTo("onafterStart", Event, From, To)
  
  -- Debug output.
  local text=string.format("Started ARTY version %s for group %s.", ARTY.version, Controllable:GetName())
  self:E(ARTY.id..text)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  
  -- Get Ammo.
  self.Nammo0, self.Nshells0, self.Nrockets0, self.Nmissiles0=self:GetAmmo(self.Debug)
  
  -- Init nuclear explosion parameters if they were not set by user.
  if self.nukerange==nil then
    self.nukerange=1500/75000*self.nukewarhead  -- linear dependence
  end
  if self.nukefires==nil then
    self.nukefires=20/1000/1000*self.nukerange*self.nukerange
  end
  if self.Nukes~=nil then
    self.Nukes0=math.min(self.Nukes, self.Nshells0)
  else
    self.Nukes=0
    self.Nukes0=0
  end
  
  -- Check if we have and arty type that is in the DB.
  local _dbproperties=self:_CheckDB(self.DisplayName)
  self:T({dbproperties=_dbproperties})
  if _dbproperties~=nil then
    for property,value in pairs(_dbproperties) do
      self:T({property=property, value=value})
        self[property]=value
    end
  end
  
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Arty group          = %s\n", Controllable:GetName())
  text=text..string.format("Artillery attribute = %s\n", tostring(self.IsArtillery))
  text=text..string.format("Type                = %s\n", self.Type)
  text=text..string.format("Display Name        = %s\n", self.DisplayName)  
  text=text..string.format("Number of units     = %d\n", self.IniGroupStrength)
  text=text..string.format("Speed max           = %d km/h\n", self.SpeedMax)
  text=text..string.format("Speed default       = %d km/h\n", self.Speed)
  text=text..string.format("Min range           = %.1f km\n", self.minrange/1000)
  text=text..string.format("Max range           = %.1f km\n", self.maxrange/1000)
  text=text..string.format("Total ammo count    = %d\n", self.Nammo0)
  text=text..string.format("Number of shells    = %d\n", self.Nshells0)
  text=text..string.format("Number of rockets   = %d\n", self.Nrockets0)
  text=text..string.format("Number of missiles  = %d\n", self.Nmissiles0)
  text=text..string.format("Number of nukes     = %d\n", self.Nukes0)
  text=text..string.format("Nuclear warhead     = %d tons TNT\n", self.nukewarhead/1000)
  text=text..string.format("Nuclear demolition  = %d m\n", self.nukerange)
  text=text..string.format("Nuclear fires       = %d (active=%s)\n", self.nukefires, tostring(self.nukefire))
  if self.RearmingGroup or self.RearmingPlaceCoord then
  text=text..string.format("Rearming safe dist. = %d m\n", self.RearmingDistance)
  end
  if self.RearmingGroup then
  text=text..string.format("Rearming group      = %s\n", self.RearmingGroup:GetName())
  text=text..string.format("Rearming group speed= %d km/h\n", self.RearmingGroupSpeed)
  text=text..string.format("Rearming group roads= %s\n", tostring(self.RearmingGroupOnRoad))
  end
  if self.RearmingPlaceCoord then
  local dist=self.InitialCoord:Get2DDistance(self.RearmingPlaceCoord)
  text=text..string.format("Rearming coord dist = %d m\n", dist)
  text=text..string.format("Rearming ARTY roads = %s\n", tostring(self.RearmingArtyOnRoad))
  end
  text=text..string.format("Relocate after fire = %s\n", tostring(self.relocateafterfire))
  text=text..string.format("Relocate min dist.  = %d m\n", self.relocateRmin)
  text=text..string.format("Relocate max dist.  = %d m\n", self.relocateRmax)
  text=text..string.format("Auto move in  range = %s\n", tostring(self.autorelocate))
  text=text..string.format("Auto move dist. max = %.1f km\n", self.autorelocatemaxdist/1000)
  text=text..string.format("Auto move on road   = %s\n", tostring(self.autorelocateonroad))
  text=text..string.format("Marker assignments  = %s\n", tostring(self.markallow))
  text=text..string.format("Marker auth. key    = %s\n", tostring(self.markkey))
  text=text..string.format("Marker readonly     = %s\n", tostring(self.markreadonly))
  text=text..string.format("******************************************************\n")
  text=text..string.format("Targets:\n")
  for _, target in pairs(self.targets) do
    text=text..string.format("- %s\n", self:_TargetInfo(target))
    if self.Debug then
      local zone=ZONE_RADIUS:New(target.name, target.coord:GetVec2(), target.radius)
      zone:BoundZone(180, coalition.side.NEUTRAL)
    end
  end
  text=text..string.format("Moves:\n")
  for i=1,#self.moves do
    text=text..string.format("- %s\n", self:_MoveInfo(self.moves[i]))
  end
  text=text..string.format("******************************************************\n")
  text=text..string.format("Shell types:\n")
  for _,_type in pairs(self.ammoshells) do
    text=text..string.format("- %s\n", _type)
  end
  text=text..string.format("Rocket types:\n")
  for _,_type in pairs(self.ammorockets) do
    text=text..string.format("- %s\n", _type)
  end
  text=text..string.format("Missile types:\n")
  for _,_type in pairs(self.ammomissiles) do
    text=text..string.format("- %s\n", _type)
  end  
  text=text..string.format("******************************************************")
  if self.Debug then
    self:E(ARTY.id..text)
  else
    self:T(ARTY.id..text)
  end
  
  -- Set default ROE to weapon hold.
  self.Controllable:OptionROEHoldFire()
  
  -- Add event handler.
  self:HandleEvent(EVENTS.Shot, self._OnEventShot)
  self:HandleEvent(EVENTS.Dead, self._OnEventDead)
  --self:HandleEvent(EVENTS.MarkAdded, self._OnEventMarkAdded)

  -- Add DCS event handler - necessary for S_EVENT_MARK_* events. So we only start it, if this was requested.
  if self.markallow then
    world.addEventHandler(self)
  end
  
  -- Start checking status.
  self:__Status(self.StatusInterval)
end

--- Check the DB for properties of the specified artillery unit type.
-- @param #ARTY self
-- @return #table Properties of the requested artillery type. Returns nil if no matching DB entry could be found.
function ARTY:_CheckDB(displayname)
  for _type,_properties in pairs(ARTY.db) do
    self:T({type=_type, properties=_properties})
    if _type==displayname then
      self:T({type=_type, properties=_properties})
      return _properties
    end
  end
  return nil
end

--- After "Start" event. Initialized ROE and alarm state. Starts the event handler.
-- @param #ARTY self
-- @param #boolean display (Optional) If true, send message to coalition. Default false.
function ARTY:_StatusReport(display)

  -- Set default.
  if display==nil then
    display=false
  end

  -- Get Ammo.
  local Nammo, Nshells, Nrockets, Nmissiles=self:GetAmmo()
  local Nnukes=self.Nukes
  
  local Tnow=timer.getTime()
  local Clock=self:_SecondsToClock(timer.getAbsTime())
  
  local text=string.format("\n******************* STATUS ***************************\n")
  text=text..string.format("ARTY group          = %s\n", self.Controllable:GetName())
  text=text..string.format("Clock               = %s\n", Clock)
  text=text..string.format("FSM state           = %s\n", self:GetState())
  text=text..string.format("Total ammo count    = %d\n", Nammo)
  text=text..string.format("Number of shells    = %d\n", Nshells)
  text=text..string.format("Number of rockets   = %d\n", Nrockets)
  text=text..string.format("Number of missiles  = %d\n", Nmissiles)
  text=text..string.format("Number of nukes     = %d\n", Nnukes)
  if self.currentTarget then
  text=text..string.format("Current Target      = %s\n", tostring(self.currentTarget.name))
  text=text..string.format("Curr. Tgt assigned  = %d\n", Tnow-self.currentTarget.Tassigned)
  else
  text=text..string.format("Current Target      = %s\n", "none")
  end
  text=text..string.format("Nshots curr. Target = %d\n", self.Nshots)
  text=text..string.format("Targets:\n")
  for i=1,#self.targets do
    text=text..string.format("- %s\n", self:_TargetInfo(self.targets[i]))
  end
  if self.currentMove then
  text=text..string.format("Current Move        = %s\n", tostring(self.currentMove.name))
  else
  text=text..string.format("Current Move        = %s\n", "none")
  end
  text=text..string.format("Moves:\n")
  for i=1,#self.moves do
    text=text..string.format("- %s\n", self:_MoveInfo(self.moves[i]))
  end
  text=text..string.format("******************************************************")
  env.info(ARTY.id..text)
  MESSAGE:New(text, 20):Clear():ToCoalitionIf(self.Controllable:GetCoalition(), display)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Handling
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Eventhandler for shot event.
-- @param #ARTY self
-- @param Core.Event#EVENTDATA EventData
function ARTY:_OnEventShot(EventData)
  self:F(EventData)
  
    -- Weapon data.
  local _weapon = EventData.Weapon:getTypeName()  -- should be the same as Event.WeaponTypeName
  local _weaponStrArray = self:_split(_weapon,"%.")
  local _weaponName = _weaponStrArray[#_weaponStrArray]
  
  -- Debug info.
  self:T3(ARTY.id.."EVENT SHOT: Ini unit    = "..EventData.IniUnitName)
  self:T3(ARTY.id.."EVENT SHOT: Ini group   = "..EventData.IniGroupName)
  self:T3(ARTY.id.."EVENT SHOT: Weapon type = ".._weapon)
  self:T3(ARTY.id.."EVENT SHOT: Weapon name = ".._weaponName)
  
  local group = EventData.IniGroup --Wrapper.Group#GROUP
  
  if group and group:IsAlive() then
  
    if EventData.IniGroupName == self.Controllable:GetName() then
    
      if self.currentTarget then
      
        -- Increase number of shots fired by this group on this target.
        self.Nshots=self.Nshots+1
        
        -- Debug output.
        local text=string.format("%s, fired shot %d of %d with weapon %s on target %s.", self.Controllable:GetName(), self.Nshots, self.currentTarget.nshells, _weaponName, self.currentTarget.name)
        self:T(ARTY.id..text)
        MESSAGE:New(text, 5):Clear():ToAllIf(self.report or self.Debug)
        
        -- Last known position of the weapon fired.
        local _lastpos={x=0, y=0, z=0}
        
        --- Track the position of the weapon if it is supposed to model a tac nuke. 
        -- @param #table _weapon
        local function _TrackWeapon(_weapon)
        
          -- When the pcall status returns false the weapon has hit.
          local _status,_currpos =  pcall(
          function()
            return _weapon:getPoint()
          end)
          
          self:T(ARTY.id..string.format("ARTY %s: Weapon still in air: %s", self.Controllable:GetName(), tostring(_status)))
          
          if _status then
            
            -- Update last position.
            _lastpos={x=_currpos.x, y=_currpos.y, z=_currpos.z}
            
            -- Check again in 0.05 seconds.
            --return timer.getTime() + self.dtBombtrack
            return timer.getTime() + 0.05
            
          else
        
            local _impactcoord=COORDINATE:NewFromVec3(_lastpos)
            
            -- Create a "nuclear" explosion and blast at the impact point.
            SCHEDULER:New(nil, ARTY._NuclearBlast, {self,_impactcoord}, 1.0)
        
          end
        
        end
        
        -- Start track the shell if we want to model a tactical nuke.
        if self.currentTarget.weapontype==ARTY.WeaponType.TacticalNukes and self.Nukes>0 then
            self:T(ARTY.id..string.format("ARTY %s: Tracking of weapon starts in two seconds.", self.Controllable:GetName()))
            timer.scheduleFunction(_TrackWeapon, EventData.weapon, timer.getTime() + 2.0)
        end
               
        -- Get current ammo.
        local _nammo,_nshells,_nrockets,_nmissiles=self:GetAmmo()
          
        -- Decrease available nukes.
        if self.currentTarget.weapontype==ARTY.WeaponType.TacticalNukes then
          self.Nukes=self.Nukes-1
        end
        
        local _outofammo=false
        if _nammo==0 then        
          self:T(ARTY.id..string.format("Group %s completely out of ammo.", self.Controllable:GetName()))
          _outofammo=true
        end
        
        -- Weapon type name for current target.
        local _weapontype=self:_WeaponTypeName(self.currentTarget.weapontype)
        self:T(ARTY.id..string.format("Group %s ammo: total=%d, shells=%d, rockets=%d, missiles=%d", self.Controllable:GetName(), _nammo, _nshells, _nrockets, _nmissiles))
        self:T(ARTY.id..string.format("Group %s uses weapontype %s for current target.", self.Controllable:GetName(), _weapontype))        
        
        -- Special weapon type requested ==> Check if corresponding ammo is empty.
        local _partlyoutofammo=false
        if self.currentTarget.weapontype==ARTY.WeaponType.Cannon and _nshells==0 then
        
          self:T(ARTY.id..string.format("Group %s, cannons requested but shells empty.", self.Controllable:GetName()))
          _partlyoutofammo=true
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.TacticalNukes and self.Nukes<=0 then

          self:T(ARTY.id..string.format("Group %s, tactical nukes requested but nukes empty.", self.Controllable:GetName()))
          _partlyoutofammo=true
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.Rockets and _nrockets==0 then

          self:T(ARTY.id..string.format("Group %s, rockets requested but rockets empty.", self.Controllable:GetName()))
          _partlyoutofammo=true
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.UnguidedAny and _nshells+_nrockets==0 then
        
          self:T(ARTY.id..string.format("Group %s, unguided weapon requested but shells AND rockets empty.", self.Controllable:GetName()))
          _partlyoutofammo=true
        
        elseif (self.currentTarget.weapontype==ARTY.WeaponType.GuidedMissile or self.currentTarget.weapontype==ARTY.WeaponType.CruiseMissile or self.currentTarget.weapontype==ARTY.WeaponType.AntiShipMissile) and _nmissiles==0 then
        
          self:T(ARTY.id..string.format("Group %s, guided, anti-ship or cruise missiles requested but all missiles empty.", self.Controllable:GetName()))
          _partlyoutofammo=true
          
        end        
       
        -- Check if number of shots reached max.
        local _ceasefire=false
        local _relocate=false
        if self.Nshots >= self.currentTarget.nshells then
          local text=string.format("Group %s stop firing on target %s.", self.Controllable:GetName(), self.currentTarget.name)
          self:T(ARTY.id..text)
          MESSAGE:New(text, 5):ToAllIf(self.Debug)
          
          -- Cease fire.
          _ceasefire=true
          
          if self.relocateafterfire then
            _relocate=true
          end
        end
        
        -- Check if we are (partly) out of ammo.
        if _outofammo or _partlyoutofammo then
          _ceasefire=true
        end
        
        -- Cease fire on current target.
        if _ceasefire then
          self:CeaseFire(self.currentTarget)
        end

        -- Group is out of ammo (or partly and can rearm) ==> Winchester (==> Rearm).
        if _outofammo or (_partlyoutofammo and self.RearmingGroup ~=nil) then
          self:Winchester()
          return
        end
        
        -- Relocate position
        if _relocate then
          self:_Relocate()
        end  
        
      else
        self:E(ARTY.id..string.format("ERROR: No current target for group %s?!", self.Controllable:GetName()))
      end        
    end
  end
end

--- After "Start" event. Initialized ROE and alarm state. Starts the event handler.
-- @param #ARTY self
-- @param #table Event
function ARTY:onEvent(Event)

  if Event == nil or Event.idx == nil then
    self:T3("Skipping onEvent. Event or Event.idx unknown.")
    return true
  end

  -- Set battery and coalition.
  local batteryname=self.Controllable:GetName()
  local batterycoalition=self.Controllable:GetCoalition()
  
  self:T2(string.format("Event captured  = %s", tostring(batteryname)))
  self:T2(string.format("Event id        = %s", tostring(Event.id)))
  self:T2(string.format("Event time      = %s", tostring(Event.time)))
  self:T2(string.format("Event idx       = %s", tostring(Event.idx)))
  self:T2(string.format("Event coalition = %s", tostring(Event.coalition)))
  self:T2(string.format("Event group id  = %s", tostring(Event.groupID)))
  self:T2(string.format("Event text      = %s", tostring(Event.text)))
  if Event.initiator~=nil then
    local _unitname=Event.initiator:getName()
    self:T(string.format("Event ini unit name = %s", tostring(_unitname)))
  end
  
  if Event.id==world.event.S_EVENT_MARK_ADDED then
    self:E({event="S_EVENT_MARK_ADDED", battery=batteryname, vec3=Event.pos})
    
  elseif Event.id==world.event.S_EVENT_MARK_CHANGE then
    self:E({event="S_EVENT_MARK_CHANGE", battery=batteryname, vec3=Event.pos})
    
    -- Handle event.
    self:_OnEventMarkChange(Event)
       
  elseif Event.id==world.event.S_EVENT_MARK_REMOVED then
    self:E({event="S_EVENT_MARK_REMOVED", battery=batteryname, vec3=Event.pos})
    
    -- Hande event.
    self:_OnEventMarkRemove(Event)
  end
    
end

--- Function called when a F10 map mark was removed.
-- @param #ARTY self
-- @param #table Event Event data.
function ARTY:_OnEventMarkRemove(Event)

  -- Get battery coalition and name.
  local batterycoalition=self.Controllable:GetCoalition()
  local batteryname=self.Controllable:GetName()
  
  if Event.text~=nil and Event.text:find("BATTERY") then
  
    -- Init defaults.
    local _cancelmove=false
    local _canceltarget=false
    local _name=""
    local _id=nil
    
    -- Check for key phrases of relocation or engagements in marker text. If not, return.
    if Event.text:find("Marked Relocation") then
      _cancelmove=true
      _name=self:_MarkMoveName(Event.idx)
      _id=self:_GetMoveIndexByName(_name)
    elseif Event.text:find("Marked Target") then
      _canceltarget=true
      _name=self:_MarkTargetName(Event.idx)
      _id=self:_GetTargetIndexByName(_name)
    else
      return
    end
    
    -- Check if there is a task which matches.
    if _id==nil then
      return
    end
  
    -- Check if the coalition is the same or an authorization key has been defined.
    if (batterycoalition==Event.coalition and self.markkey==nil) or self.markkey~=nil then
  
      -- Authentify key
      local _validkey=self:_MarkerKeyAuthentification(Event.text)
    
      -- Check if we have the right coalition.
      if _validkey then
      
        -- This should be the unique name of the target or move.    
        if _cancelmove then
          if self.currentMove and self.currentMove.name==_name then
            self.Controllable:ClearTasks()
            self:Arrived()
          else
            self:RemoveMove(_name)
          end
        elseif _canceltarget then
          if self.currentTarget and self.currentTarget.name==_name then
            self:CeaseFire(self.currentTarget)
            self:RemoveTarget(_name)
          else
            self:RemoveTarget(_name)
          end
        end
        
      end    
    end
  end  
end

--- Function called when a F10 map mark was changed. This happens when a user enters text.
-- @param #ARTY self
-- @param #table Event Event data.
function ARTY:_OnEventMarkChange(Event)

  -- Check if marker has a text and the "arty" keyword.
  if Event.text~=nil and Event.text:lower():find("arty") then
  
    -- Get battery coalition and name.
    local batterycoalition=self.Controllable:GetCoalition()
    local batteryname=self.Controllable:GetName()
  
    -- Check if the coalition is the same or an authorization key has been defined.
    if (batterycoalition==Event.coalition and self.markkey==nil) or self.markkey~=nil then
  
      -- Evaluate marker text and extract parameters.
      local _assign=self:_Markertext(Event.text)

      -- Check if ENGAGE or MOVE or REQUEST keywords were found.
      if _assign==nil or not (_assign.engage or _assign.move or _assign.request) then
        return
      end
                    
      -- Check if job is assigned to this ARTY group. Default is for all ARTY groups.
      local _assigned=true
      if #_assign.battery>0 then
        _assigned=false
        for _,bat in pairs(_assign.battery) do
          self:T2(ARTY.id..string.format("Compare battery names %s=%s ==> %s",batteryname, bat, tostring(batteryname==bat)))
          if batteryname==bat then
            _assigned=true
          end
        end
      end
            
      -- We were not addressed.
      if not _assigned then
        return
      end
            
      -- Check if the authorization key is required and if it is valid.
      local _validkey=self:_MarkerKeyAuthentification(Event.text)
      
       -- Handle requests and return.
      if _assign.request and _validkey then
        if _assign.requestammo then
          self:_MarkRequestAmmo()
        end
        if _assign.requestmoves then
          self:_MarkRequestMoves()
        end
        if _assign.requesttargets then
          self:_MarkRequestTargets()
        end
        if _assign.requeststatus then
          self:_MarkRequestStatus()
        end        
        if _assign.requestrearming then
          self:Rearm()
        end        
        -- Requests Done ==> End of story!
        return
      end
      
      -- Cancel current target and return.
      if  _assign.cancelcurrent and _validkey then
        if _assign.move and self.currentMove then
          self.Controllable:ClearTasks()
          self:Arrived()
        end
        if _assign.engage and self.currentTarget then
          self:CeaseFire(self.currentTarget)
        end
        return
      end
      
      -- Handle engagements and relocations.
      if _validkey then
      
        -- Convert (wrong x-->z, z-->x) vec3
        -- TODO: This needs to be "fixed", once DCS gives the correct numbers for x and z.
        -- local vec3={y=Event.pos.y, x=Event.pos.x, z=Event.pos.z}
        local vec3={y=Event.pos.y, x=Event.pos.z, z=Event.pos.x}
        
        -- Get coordinate from vec3.
        local _coord=COORDINATE:NewFromVec3(vec3)
        
        -- Remove old mark because it might contain confidential data such as the key.
        -- Also I don't know who can see the mark which was created.
        _coord:RemoveMark(Event.idx)
        
        -- Coordinate was given in text, e.g. as lat, long.
        if _assign.coord then
          _coord=_assign.coord
        end
        
        -- Anticipate marker ID.
        -- WARNING: Make sure, no marks are set until the COORDINATE:MarkToCoalition() is called or the target/move name will be wrong and target cannot be removed by deleting its marker.
        local _id=UTILS._MarkID+1
      
        if _assign.move then
        
          -- Create a new name. This determins the string we search when deleting a move!
          local _name=self:_MarkMoveName(_id)
        
          local text=string.format("%s, received new relocation assignment.", batteryname)
          text=text..string.format("\nCoordinates %s",_coord:ToStringLLDMS())
          MESSAGE:New(text, 10):ToCoalitionIf(batterycoalition, self.report or self.Debug)
                
          -- Assign a relocation of the arty group.
          local _movename=self:AssignMoveCoord(_coord, _assign.time, _assign.speed, _assign.onroad, _assign.canceltarget,_name, true)
          
          if _movename~=nil then
            local _mid=self:_GetMoveIndexByName(_movename)
            local _move=self.moves[_mid]
          
            -- Create new target name.
            local clock=tostring(self:_SecondsToClock(_move.time))
            local _markertext=_movename..string.format(", Time=%s, Speed=%d km/h, Use Roads=%s.", clock, _move.speed, tostring(_move.onroad))
                    
            -- Create a new mark. This will trigger the mark added event.
            local _randomcoord=_coord:GetRandomCoordinateInRadius(100)
            _randomcoord:MarkToCoalition(_markertext, batterycoalition, self.markreadonly or _assign.readonly)
          else
            local text=string.format("%s, relocation not possible.", batteryname)
            MESSAGE:New(text, 10):ToCoalitionIf(batterycoalition, self.report or self.Debug)
          end           
        
        else
         
          -- Create a new name.
          local _name=self:_MarkTargetName(_id)
                                  
          local text=string.format("%s, received new target assignment.", batteryname)
          text=text..string.format("\nCoordinates %s",_coord:ToStringLLDMS())
          if _assign.time then
            text=text..string.format("\nTime %s",_assign.time)
          end
          if _assign.prio then
            text=text..string.format("\nPrio %d",_assign.prio)
          end
          if _assign.prio then
            text=text..string.format("\nRadius %d m",_assign.radius)
          end
          if _assign.nshells then
            text=text..string.format("\nShots %d",_assign.nshells)
          end
          if _assign.maxengage then
            text=text..string.format("\nEngagements %d",_assign.maxengage)
          end
          if _assign.weapontype then
            text=text..string.format("\nWeapon %s",self:_WeaponTypeName(_assign.weapontype))
          end            
          MESSAGE:New(text, 10):ToCoalitionIf(batterycoalition, self.report or self.Debug)
                                      
          -- Assign a new firing engagement.
          -- Note, we set unique=true so this target gets only added once.
          local _targetname=self:AssignTargetCoord(_coord,_assign.prio,_assign.radius,_assign.nshells,_assign.maxengage,_assign.time,_assign.weapontype, _name, true)
          
          if _targetname~=nil then
            local _tid=self:_GetTargetIndexByName(_targetname)
            local _target=self.targets[_tid]
          
            -- Create new target name.
            local clock=tostring(self:_SecondsToClock(_target.time))
            local weapon=self:_WeaponTypeName(_target.weapontype)
            local _markertext=_targetname..string.format(", Priority=%d, Radius=%d m, Shots=%d, Engagements=%d, Weapon=%s, Time=%s", _target.prio, _target.radius, _target.nshells, _target.maxengage, weapon, clock)
                    
            -- Create a new mark. This will trigger the mark added event.
            local _randomcoord=_coord:GetRandomCoordinateInRadius(250)
            _randomcoord:MarkToCoalition(_markertext, batterycoalition, self.markreadonly or _assign.readonly)
          end 
        end
      end
      
    end  
  end

end

--- Event handler for event Dead.
-- @param #ARTY self
-- @param Core.Event#EVENTDATA EventData
function ARTY:_OnEventDead(EventData)
  self:F(EventData)

  -- Name of controllable.
  local _name=self.Controllable:GetName()

  -- Check for correct group.
  if  EventData.IniGroupName==_name then
    
    -- Dead Unit.
    self:T2(string.format("%s: Captured dead event for unit %s.", _name, EventData.IniUnitName))
    
    -- FSM Dead event. We give one second for update of data base.
    self:__Dead(1)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events and States
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Status" event. Report status of group.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterStatus(Controllable, From, Event, To)
  self:_EventFromTo("onafterStatus", Event, From, To)
  
  -- Debug current status info.
  if self.Debug then
    self:_StatusReport()
  end
  
  -- Group is out of ammo.
  if self:is("OutOfAmmo") then
    self:T2(ARTY.id..string.format("%s: OutOfAmmo. ==> Rearm", Controllable:GetName()))
    self:Rearm()
  end
  
  -- Group is out of moving.
  if self:is("Moving") then
    self:T2(ARTY.id..string.format("%s: Moving", Controllable:GetName()))
  end
  
  -- Group is rearming.
  if self:is("Rearming") then
    local _rearmed=self:_CheckRearmed()
    if _rearmed then
      self:T2(ARTY.id..string.format("%s: Rearming ==> Rearmed", Controllable:GetName()))
      self:Rearmed()
    end
  end
  
  -- Group finished rearming.
  if self:is("Rearmed") then
    local distance=self.Controllable:GetCoordinate():Get2DDistance(self.InitialCoord)
    self:T2(ARTY.id..string.format("%s: Rearmed. Distance ARTY to InitalCoord = %d m", Controllable:GetName(), distance))
    -- Check that ARTY group is back and set it to combat ready.
    if distance <= self.RearmingDistance then
      self:T2(ARTY.id..string.format("%s: Rearmed ==> CombatReady", Controllable:GetName()))
      self:CombatReady()
    end
  end
  
  -- Group arrived at destination.
  if self:is("Arrived") then
    self:T2(ARTY.id..string.format("%s: Arrived ==> CombatReady", Controllable:GetName()))
    self:CombatReady()
  end
  
  -- Group is firing on target.
  if self:is("Firing") then
    -- Check that firing started after ~5 min. If not, target is removed.
    self:_CheckShootingStarted()
  end
  
  
  -- Check if targets are in range and update target.inrange value.
  self:_CheckTargetsInRange()

  -- Get a valid timed target if it is due to be attacked.
  local _timedTarget=self:_CheckTimedTargets()
      
  -- Get a valid normal target (one that is not timed).
  local _normalTarget=self:_CheckNormalTargets()
  
  -- Get a commaned move to another location.
  local _move=self:_CheckMoves()
  
  if (self:is("CombatReady") or self:is("Firing")) and _move then
    -- Group is combat ready or firing but we have a move.
    self:T2(ARTY.id..string.format("%s: CombatReady/Firing ==> Move", Controllable:GetName()))
  
    -- Command to move.
    self.currentMove=_move
    self:Move(_move.coord, _move.speed, _move.onroad)
  
  elseif self:is("CombatReady") or (self:is("Firing") and _timedTarget) then
    -- Group is combat ready or firing but we have a high prio timed target.
    self:T2(ARTY.id..string.format("%s: CombatReady or Firing+Timed Target ==> OpenFire", Controllable:GetName()))
  
    -- Engage target.
    if _timedTarget then
    
      -- Cease fire on current target first.
      if self.currentTarget then
        self:CeaseFire(self.currentTarget)
      end
      
      -- Open fire on timed target.
      self:OpenFire(_timedTarget)
      
    elseif _normalTarget then
    
      -- Open fire on normal target.
      self:OpenFire(_normalTarget)
      
    end
  end

  -- Call status again in ~10 sec.
  self:__Status(self.StatusInterval)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Enter "CombatReady" state. Route the group back if necessary.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onenterCombatReady(Controllable, From, Event, To)
  self:_EventFromTo("onenterCombatReady", Event, From, To)
  -- Debug info
  self:T3(ARTY.id..string.format("onenterComabReady, from=%s, event=%s, to=%s", From, Event, To))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "OpenFire" event. Checks if group already has a target. Checks for valid min/max range and removes the target if necessary.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
-- @return #boolean If true, proceed to onafterOpenfire.
function ARTY:onbeforeOpenFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onbeforeOpenFire", Event, From, To)
     
  -- Check that group has no current target already.
  if self.currentTarget then
    -- This should not happen. Some earlier check failed.
    self:E(ARTY.id..string.format("ERROR: Group %s already has a target %s!", self.Controllable:GetName(), self.currentTarget.name))
    -- Deny transition.
    return false
  end
  
  -- Check if target is in range.
  if not self:_TargetInRange(target) then
    -- This should not happen. Some earlier check failed.
    self:E(ARTY.id..string.format("ERROR: Group %s, target %s is out of range!", self.Controllable:GetName(), self.currentTarget.name))
    -- Deny transition.
    return false
  end
  
  -- Get ammo.
  local Nammo, Nshells, Nrockets, Nmissiles=self:GetAmmo()
  local nfire=Nammo
  if target.weapontype==ARTY.WeaponType.Auto then
    nfire=Nammo
  elseif target.weapontype==ARTY.WeaponType.Cannon then
    nfire=Nshells
  elseif target.weapontype==ARTY.WeaponType.TacticalNukes then
    nfire=self.Nukes
  elseif target.weapontype==ARTY.WeaponType.Rockets then
    nfire=Nrockets
  elseif target.weapontype==ARTY.WeaponType.UnguidedAny then
    nfire=Nshells+Nrockets
  elseif target.weapontype==ARTY.WeaponType.GuidedMissile then
    nfire=Nmissiles
  elseif target.weapontype==ARTY.WeaponType.CruiseMissile then
    nfire=Nmissiles
  elseif target.weapontype==ARTY.WeaponType.AntiShipMissile then
    nfire=Nmissiles
  end
  
  -- Adjust if less than requested ammo is left.
  target.nshells=math.min(target.nshells, nfire)
  
  -- No ammo left ==> deny transition.
  if target.nshells<1 then
    return false
  end
  
  return true
end

--- After "OpenFire" event. Sets the current target and starts the fire at point task.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
function ARTY:onafterOpenFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterOpenFire", Event, From, To)
      
  -- Get target array index.
  local id=self:_GetTargetIndexByName(target.name)
  
  -- Target is now under fire and has been engaged once more.
  if id then
    -- Set under fire flag.
    self.targets[id].underfire=true
    -- Set current target.
    self.currentTarget=target
    -- Set time the target was assigned.
    self.currentTarget.Tassigned=timer.getTime()
  end
  
  -- Distance to target
  local range=Controllable:GetCoordinate():Get2DDistance(target.coord)
  
  -- Get ammo.
  local Nammo, Nshells, Nrockets, Nmissiles=self:GetAmmo()
  local nfire=Nammo
  local _type="shots"
  if target.weapontype==ARTY.WeaponType.Auto then
    nfire=Nammo
    _type="shots"
  elseif target.weapontype==ARTY.WeaponType.Cannon then
    nfire=Nshells
    _type="shells"
  elseif target.weapontype==ARTY.WeaponType.TacticalNukes then
    nfire=self.Nukes
    _type="nuclear shells"
  elseif target.weapontype==ARTY.WeaponType.Rockets then
    nfire=Nrockets
    _type="rockets"
  elseif target.weapontype==ARTY.WeaponType.UnguidedAny then
    nfire=Nshells+Nrockets
    _type="shells or rockets"
  elseif target.weapontype==ARTY.WeaponType.GuidedMissile then
    nfire=Nmissiles
    _type="guided missiles"
  elseif target.weapontype==ARTY.WeaponType.CruiseMissile then
    nfire=Nmissiles
    _type="cruise missiles"
  elseif target.weapontype==ARTY.WeaponType.AntiShipMissile then
    nfire=Nmissiles
    _type="anti-ship missiles"
  end
  
  -- Adjust if less than requested ammo is left.
  target.nshells=math.min(target.nshells, nfire)
    
  -- Send message.
  local text=string.format("%s, opening fire on target %s with %d %s. Distance %.1f km.", Controllable:GetName(), target.name, target.nshells, _type, range/1000)
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report)
  
  --if self.Debug then
  --  local _coord=target.coord --Core.Point#COORDINATE
  --  local text=string.format("ARTY %s, Target %s, n=%d, weapon=%s", self.Controllable:GetName(), target.name, target.nshells, self:_WeaponTypeName(target.weapontype))
  --  _coord:MarkToAll(text)
  --end
  
  -- Start firing.
  self:_FireAtCoord(target.coord, target.radius, target.nshells, target.weapontype)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "CeaseFire" event. Clears task of the group and removes the target if max engagement was reached.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
function ARTY:onafterCeaseFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterCeaseFire", Event, From, To)
  
  if target then
    
    -- Send message.
    local text=string.format("%s, ceasing fire on target %s.", Controllable:GetName(), target.name)
    self:T(ARTY.id..text)
    MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report)
        
    -- Get target array index.
    local id=self:_GetTargetIndexByName(target.name)
    
    -- We have a target.
    if id then
      -- Target was actually engaged. (Could happen that engagement was aborted while group was still aiming.)
      if self.Nshots>0 then
        self.targets[id].engaged=self.targets[id].engaged+1
        -- Clear the attack time.
        self.targets[id].time=nil
      end
      -- Target is not under fire any more.
      self.targets[id].underfire=false
    end
    
    -- If number of engagements has been reached, the target is removed.
    if target.engaged >= target.maxengage then
      self:RemoveTarget(target.name)
    end
    
    -- Set ROE to weapon hold.
    self.Controllable:OptionROEHoldFire()
    
    -- Clear tasks.
    self.Controllable:ClearTasks()
    
  end
      
  -- Set number of shots to zero.
  self.Nshots=0
  
  -- ARTY group has no current target any more.
  self.currentTarget=nil
    
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Winchester" event. Group is out of ammo. Trigger "Rearm" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterWinchester(Controllable, From, Event, To)
  self:_EventFromTo("onafterWinchester", Event, From, To)
  
  -- Send message.
  local text=string.format("%s, winchester!", Controllable:GetName())
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Rearm" event. Check if a unit to rearm the ARTY group has been defined.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, proceed to onafterRearm.
function ARTY:onbeforeRearm(Controllable, From, Event, To)
  self:_EventFromTo("onbeforeRearm", Event, From, To)
  
  local _rearmed=self:_CheckRearmed()
  if _rearmed then
    self:T(ARTY.id..string.format("%s, group is already armed to the teeth. Rearming request denied!", self.Controllable:GetName()))
    return false
  else
    self:T(ARTY.id..string.format("%s, group might be rearmed.", self.Controllable:GetName()))
  end
  
  -- Check if a reaming unit or rearming place was specified.
  if self.RearmingGroup and self.RearmingGroup:IsAlive() then
    return true
  elseif self.RearmingPlaceCoord then
    return true 
  else
    return false
  end
  
end

--- After "Rearm" event. Send message if reporting is on. Route rearming unit to ARTY group.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterRearm(Controllable, From, Event, To)
  self:_EventFromTo("onafterRearm", Event, From, To)
  
     -- Coordinate of ARTY unit.
    local coordARTY=self.Controllable:GetCoordinate()
    
    -- Remember current coordinates so that we find our way back home.
    self.InitialCoord=coordARTY
    
    -- Coordinate of rearming group.
    local coordRARM=nil
    if self.RearmingGroup then
      -- Coordinate of the rearming unit.
      coordRARM=self.RearmingGroup:GetCoordinate()
      -- Remember the coordinates of the rearming unit. After rearming it will go back to this position.
      self.RearmingGroupCoord=coordRARM
    end
    
    if self.RearmingGroup and self.RearmingPlaceCoord and self.SpeedMax>0 then
    
      -- CASE 1: Rearming unit and ARTY group meet at rearming place.
      
      -- Send message.
      local text=string.format("%s, %s, request rearming at rearming place.", Controllable:GetName(), self.RearmingGroup:GetName())
      self:T(ARTY.id..text)
      MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
      
      -- Distances.
      local dA=coordARTY:Get2DDistance(self.RearmingPlaceCoord)
      local dR=coordRARM:Get2DDistance(self.RearmingPlaceCoord)
      
      -- Route ARTY group to rearming place.
      if dA > self.RearmingDistance then
        local _tocoord=self:_VicinityCoord(self.RearmingPlaceCoord, self.RearmingDistance/4, self.RearmingDistance/2)
        self:AssignMoveCoord(_tocoord, nil, self.Speed, self.RearmingArtyOnRoad, false, "Relocate to rearming place", true)
        --self:Move(, self.Speed, self.RearmingArtyOnRoad)
      end
      
      -- Route Rearming group to rearming place.
      if dR > self.RearmingDistance then
        self:_Move(self.RearmingGroup, self:_VicinityCoord(self.RearmingPlaceCoord, self.RearmingDistance/4, self.RearmingDistance/2), self.RearmingGroupSpeed, self.RearmingGroupOnRoad)
      end
    
    elseif self.RearmingGroup then
    
      -- CASE 2: Rearming unit drives to ARTY group.
    
      -- Send message.
      local text=string.format("%s, %s, request rearming.", Controllable:GetName(), self.RearmingGroup:GetName())
      self:T(ARTY.id..text)
      MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
          
      -- Distance between ARTY group and rearming unit.
      local distance=coordARTY:Get2DDistance(coordRARM)
       
      -- If distance is larger than ~100 m, the Rearming unit is routed to the ARTY group.
      if distance > self.RearmingDistance then
            
        -- Route rearming group to ARTY group.
        self:_Move(self.RearmingGroup, self:_VicinityCoord(coordARTY), self.RearmingGroupSpeed, self.RearmingGroupOnRoad)
      end
      
    elseif self.RearmingPlaceCoord then
    
      -- CASE 3: ARTY drives to rearming place.
      
      -- Send message.
      local text=string.format("%s, moving to rearming place.", Controllable:GetName())
      self:T(ARTY.id..text)
      MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
      -- Distance.
      local dA=coordARTY:Get2DDistance(self.RearmingPlaceCoord)
      
      -- Route ARTY group to rearming place.
      if dA > self.RearmingDistance then
        local _tocoord=self:_VicinityCoord(self.RearmingPlaceCoord)
        self:AssignMoveCoord(_tocoord, nil, self.Speed, self.RearmingArtyOnRoad, false, "Relocate to rearming place", true)
      end    
      
    end
    
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Rearmed" event. Send ARTY and rearming group back to their inital positions.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterRearmed(Controllable, From, Event, To)
  self:_EventFromTo("onafterRearmed", Event, From, To)
  
  -- Send message.
  local text=string.format("%s, rearming complete.", Controllable:GetName())
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
  -- "Rearm" tactical nukes as well.
  self.Nukes=self.Nukes0
  
  -- Route ARTY group back to where it came from (if distance is > 100 m).
  local d1=self.Controllable:GetCoordinate():Get2DDistance(self.InitialCoord)
  if d1 > self.RearmingDistance then
    --self:Move(self.InitialCoord, self.Speed, self.RearmingArtyOnRoad)
    self:AssignMoveCoord(self.InitialCoord, nil, self.Speed, self.RearmingArtyOnRoad, false, "After rearm back to initial pos", true)
  end
  
  -- Route unit back to where it came from (if distance is > 100 m).
  if self.RearmingGroup and self.RearmingGroup:IsAlive() then
    local d=self.RearmingGroup:GetCoordinate():Get2DDistance(self.RearmingGroupCoord)
    if d > self.RearmingDistance then
      self:_Move(self.RearmingGroup, self.RearmingGroupCoord, self.RearmingGroupSpeed, self.RearmingGroupOnRoad)
    end
  end
  
end

--- Check if ARTY group is rearmed, i.e. has its full amount of ammo.
-- @param #ARTY self
-- @return #boolean True if rearming is complete, false otherwise.
function ARTY:_CheckRearmed()
  self:F2()

  -- Get current ammo.
  local nammo,nshells,nrockets,nmissiles=self:GetAmmo()
  
  -- Number of units still alive.
  local units=self.Controllable:GetUnits()
  local nunits=0
  if units then
    nunits=#units
  end
  
  -- Full Ammo count.
  self.FullAmmo=self.Nammo0 * nunits / self.IniGroupStrength
  
  -- Rearming status in per cent.
  local _rearmpc=nammo/self.FullAmmo*100
  
  -- Send message.
  if _rearmpc>1 then
    local text=string.format("%s, rearming %d %% complete.", self.Controllable:GetName(), _rearmpc)
    self:T(ARTY.id..text)
    MESSAGE:New(text, 10):ToCoalitionIf(self.Controllable:GetCoalition(), self.report or self.Debug)
  end
      
  -- Return if ammo is full.
  if nammo==self.FullAmmo then
    return true
  else
    return false
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Move" event. Check if a unit to rearm the ARTY group has been defined.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE ToCoord Coordinate to which the ARTY group should move.
-- @param #boolean OnRoad If true group should move on road mainly. 
-- @return #boolean If true, proceed to onafterMove.
function ARTY:onbeforeMove(Controllable, From, Event, To, ToCoord, OnRoad)
  self:_EventFromTo("onbeforeMove", Event, From, To)
  
  -- Check if group can actually move...
  if self.SpeedMax==0 then
    return false
  end
  
  -- Cease fire first.
  if self.currentTarget then
    self:CeaseFire(self.currentTarget)
  end
      
  return true
end

--- After "Move" event. Route group to given coordinate.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE ToCoord Coordinate to which the ARTY group should move.
-- @param #number Speed Speed in km/h at which the grou p should move.
-- @param #boolean OnRoad If true group should move on road mainly. 
function ARTY:onafterMove(Controllable, From, Event, To, ToCoord, Speed, OnRoad)
  self:_EventFromTo("onafterMove", Event, From, To)

  -- Set alarm state to green and ROE to weapon hold.
  self.Controllable:OptionAlarmStateGreen()
  self.Controllable:OptionROEHoldFire()
  
  -- Take care of max speed.
  local _Speed=math.min(Speed, self.SpeedMax)
  
  -- Smoke coordinate
  if self.Debug then
    ToCoord:SmokeRed()
  end

  -- Route group to coodinate.
  self:_Move(self.Controllable, ToCoord, _Speed, OnRoad)
  
end

--- After "Arrived" event. Group has reached its destination.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterArrived(Controllable, From, Event, To)
  self:_EventFromTo("onafterArrived", Event, From, To)

  -- Set alarm state to auto.
  self.Controllable:OptionAlarmStateAuto()
  
  -- WARNING: calling ClearTasks() here causes CTD of DCS when move is over. Dont know why? combotask?
  --self.Controllable:ClearTasks()
  
  -- Send message
  local text=string.format("%s, arrived at destination.", Controllable:GetName())
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
  -- Remove executed move from queue.
  if self.currentMove then
    self:RemoveMove(self.currentMove.name)
    self.currentMove=nil
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "NewTarget" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target parameters.
-- @return #boolean If true, proceed to onafterOpenfire.
function ARTY:onafterNewTarget(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterNewTarget", Event, From, To)
  
  -- Debug message.
  local text=string.format("Adding new target %s.", target.name)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  self:T(ARTY.id..text)
end

--- After "NewMove" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table move Array holding the move parameters.
-- @return #boolean If true, proceed to onafterOpenfire.
function ARTY:onafterNewMove(Controllable, From, Event, To, move)
  self:_EventFromTo("onafterNewTarget", Event, From, To)
  
  -- Debug message.
  local text=string.format("Adding new move %s.", move.name)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  self:T(ARTY.id..text)
end


--- After "Dead" event, when a unit has died. When all units of a group are dead trigger "Stop" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterDead(Controllable, From, Event, To)
  self:_EventFromTo("onafterDead", Event, From, To)
  
  -- Number of units left in the group.
  local units=self.Controllable:GetUnits()
  local nunits=0
  if units~=nil then
    nunits=#units
  end
  
  -- Adjust full ammo count
  self.FullAmmo=self.Nammo0*nunits/self.IniGroupStrength
  
  -- Message.
  local text=string.format("%s, one of our units just died! %d units left.", self.Controllable:GetName(), nunits)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  self:T(ARTY.id..text)
      
  -- Go to stop state.
  if nunits==0 then
    self:Stop()
  end
  
end

--- After "Stop" event. Unhandle events and cease fire on current target.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterStop(Controllable, From, Event, To)
  self:_EventFromTo("onafterStop", Event, From, To)
  
  -- Debug info.
  self:T(ARTY.id..string.format("Stopping ARTY FSM for group %s.", Controllable:GetName()))
  
    -- Cease Fire on current target.
  if self.currentTarget then
    self:CeaseFire(self.currentTarget)
  end
  
  -- Remove all targets.
  --self:RemoveAllTargets()
  
  -- Unhandle event.
  self:UnHandleEvent(EVENTS.Shot)
  self:UnHandleEvent(EVENTS.Dead)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set task for firing at a coordinate.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates to fire upon.
-- @param #number radius Radius around coordinate.
-- @param #number nshells Number of shells to fire.
-- @param #number weapontype Type of weapon to use.
function ARTY:_FireAtCoord(coord, radius, nshells, weapontype)
  self:F({coord=coord, radius=radius, nshells=nshells})

  -- Controllable.
  local group=self.Controllable --Wrapper.Group#GROUP
  
  -- Tactical nukes are actually cannon shells.
  if weapontype==ARTY.WeaponType.TacticalNukes then
    weapontype=ARTY.WeaponType.Cannon
  end

  -- Set ROE to weapon free.
  group:OptionROEOpenFire()
  
  -- Get Vec2
  local vec2=coord:GetVec2()
  
  -- Get task.
  local fire=group:TaskFireAtPoint(vec2, radius, nshells, weapontype)
  
  -- Execute task.
  group:SetTask(fire)
end

--- Model a nuclear blast/destruction by creating fires and destroy scenery.
-- @param #ARTY self
-- @param Core.Point#COORDINATE _coord Coordinate of the impact point (center of the blast).
function ARTY:_NuclearBlast(_coord)

  local S0=self.nukewarhead
  local R0=self.nukerange
  
  -- Number of fires
  local N0=self.nukefires
  
  -- Create an explosion at the last known position.
  _coord:Explosion(S0)
  
  -- Huge fire at direct impact point.
  --if self.nukefire then
  _coord:BigSmokeAndFireHuge()
  --end
  
  -- Create a table of fire coordinates within the demolition zone.
  local _fires={}
  for i=1,N0 do    
    local _fire=_coord:GetRandomCoordinateInRadius(R0)
    local _dist=_fire:Get2DDistance(_coord)
    table.insert(_fires, {distance=_dist, coord=_fire})
  end
  
  -- Sort scenery wrt to distance from impact point.
  local _sort = function(a,b) return a.distance < b.distance end
  table.sort(_fires,_sort)
  
  local function _explosion(R)
    -- At R=R0 ==> explosion strength is 1% of S0 at impact point.
    local alpha=math.log(100)
    local strength=S0*math.exp(-alpha*R/R0)
    self:T2(ARTY.id..string.format("Nuclear explosion strength s(%.1f m) = %.5f (s/s0=%.1f %%), alpha=%.3f", R, strength, strength/S0*100, alpha))
    return strength
  end
  
  local function ignite(_fires)
    for _,fire in pairs(_fires) do
      local _fire=fire.coord --Core.Point#COORDINATE
      
      -- Get distance to impact and calc exponential explosion strength.
      local R=_fire:Get2DDistance(_coord)
      local S=_explosion(R)
      self:T2(ARTY.id..string.format("Explosion r=%.1f, s=%.3f", R, S))
      
      -- Get a random Big Smoke and fire object.
      local _preset=math.random(0,7)
      local _density=S/S0 --math.random()+0.1
  
      _fire:BigSmokeAndFire(_preset,_density)
      _fire:Explosion(S)
    
    end
  end
  
  if self.nukefire==true then
    ignite(_fires)
  end
  
--[[ 
  local ZoneNuke=ZONE_RADIUS:New("Nukezone", _coord:GetVec2(), 2000)

  -- Scan for Scenery objects.
  ZoneNuke:Scan(Object.Category.SCENERY)
  
  -- Array with all possible hideouts, i.e. scenery objects in the vicinity of the group.
  local scenery={}

  for SceneryTypeName, SceneryData in pairs(ZoneNuke:GetScannedScenery()) do
    for SceneryName, SceneryObject in pairs(SceneryData) do
    
      local SceneryObject = SceneryObject -- Wrapper.Scenery#SCENERY
      
      -- Position of the scenery object.
      local spos=SceneryObject:GetCoordinate()
      
      -- Distance from group to impact point.
      local distance= spos:Get2DDistance(_coord)

      -- Place markers on every possible scenery object.
      if self.Debug then
        local MarkerID=spos:MarkToAll(string.format("%s scenery object %s", self.Controllable:GetName(), SceneryObject:GetTypeName()))
        local text=string.format("%s scenery: %s, Coord %s", self.Controllable:GetName(), SceneryObject:GetTypeName(), SceneryObject:GetCoordinate():ToStringLLDMS())
        self:T2(SUPPRESSION.id..text)
      end
      
      -- Add to table.
      table.insert(scenery, {object=SceneryObject, distance=distance})
      
      --SceneryObject:Destroy()      
    end
  end
  
  -- Sort scenery wrt to distance from impact point.
--  local _sort = function(a,b) return a.distance < b.distance end
--  table.sort(scenery,_sort)
  
--  for _,object in pairs(scenery) do
--    local sobject=object -- Wrapper.Scenery#SCENERY
--    sobject:Destroy()
--  end

]]

end

--- Route group to a certain point.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group to route.
-- @param Core.Point#COORDINATE ToCoord Coordinate where we want to go.
-- @param #number Speed (Optional) Speed in km/h. Default is 70% of max speed the group can do.
-- @param #boolean OnRoad If true, use (mainly) roads.
function ARTY:_Move(group, ToCoord, Speed, OnRoad)
  
  -- Clear all tasks.
  --group:ClearTasks()
  group:OptionAlarmStateGreen()
  group:OptionROEHoldFire()
  
  -- Set formation.
  local formation = "Off Road"
  
  -- Get max speed of group.
  local SpeedMax=group:GetSpeedMax()
  
  -- Set speed.
  Speed=Speed or SpeedMax*0.7
  
  -- Make sure, we do not go above max speed possible.
  Speed=math.min(Speed, SpeedMax)
  
  -- Current coordinates of group.
  local cpini=group:GetCoordinate()
  
  -- Distance between current and final point. 
  local dist=cpini:Get2DDistance(ToCoord)
      
  -- Waypoint and task arrays.
  local path={}
  local task={}

  -- First waypoint is the current position of the group.
  path[#path+1]=cpini:WaypointGround(Speed, formation)
  task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, false)

  -- Route group on road if requested.
  if OnRoad then

    -- Path on road (only first and last points)
    local _first=cpini:GetClosestPointToRoad()
    local _last=ToCoord:GetClosestPointToRoad()
    
    -- First point on road.
    path[#path+1]=_first:WaypointGround(Speed, "On Road")
    task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, false)
    
    -- Last point on road.
    path[#path+1]=_last:WaypointGround(Speed, "On Road")
    task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, false)
    
  end
  
  -- Last waypoint at ToCoord.
  path[#path+1]=ToCoord:WaypointGround(Speed, formation)
  task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, true)
  
  
  -- Init waypoints of the group.
  local Waypoints={}
  
  -- New points are added to the default route.
  for i=1,#path do
    table.insert(Waypoints, i, path[i])
  end
  
  -- Set task for all waypoints.
  for i=1,#Waypoints do
    group:SetTaskWaypoint(Waypoints[i], task[i])
  end
  
  -- Submit task and route group along waypoints.
  group:Route(Waypoints)

end

--- Function called when group is passing a waypoint.
-- @param Wrapper.Group#GROUP group Group for which waypoint passing should be monitored. 
-- @param #ARTY arty ARTY object.
-- @param #number i Waypoint number that has been reached.
-- @param #boolean final True if it is the final waypoint.
function ARTY._PassingWaypoint(group, arty, i, final)

  -- Debug message.
  local text=string.format("%s, passing waypoint %d.", group:GetName(), i)
  if final then
    text=string.format("%s, arrived at destination.", group:GetName())
  end
  arty:T(ARTY.id..text)
  
  --[[
  if final then
    MESSAGE:New(text, 10):ToCoalitionIf(group:GetCoalition(), arty.Debug or arty.report)
  else
    MESSAGE:New(text, 10):ToAllIf(arty.Debug)
  end
  ]]
  
  -- Arrived event.
  if final and arty.Controllable:GetName()==group:GetName() then
    arty:Arrived()
  end

end

--- Relocate to another position, e.g. after an engagement to avoid couter strikes.
-- @param #ARTY self
function ARTY:_Relocate()

  -- Current position.
  local _pos=self.Controllable:GetCoordinate()
  
  local _new=nil
  local _gotit=false
  local _n=0
  local _nmax=1000
  repeat
    -- Get a random coordinate.
    _new=_pos:GetRandomCoordinateInRadius(self.relocateRmax, self.relocateRmin)
    local _surface=_new:GetSurfaceType()
    
    -- Check that new coordinate is not water(-ish).
    if _surface~=land.SurfaceType.WATER and _surface~=land.SurfaceType.SHALLOW_WATER then
      _gotit=true
    end
    -- Increase counter.
    _n=_n+1
  until _gotit or _n>_nmax
  
  -- Assign relocation.
  if _gotit then
    self:AssignMoveCoord(_new, nil, nil, false, false)
  end
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #ARTY self
-- @param #boolean display Display ammo table as message to all. Default false.
-- @return #number Total amount of ammo the whole group has left.
-- @return #number Number of shells the group has left.
-- @return #number Number of rockets the group has left.
-- @return #number Number of missiles the group has left.
function ARTY:GetAmmo(display)
  self:F3({display=display})
  
  -- Default is display false.
  if display==nil then
    display=false
  end
    
  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
  
  -- Get all units.
  local units=self.Controllable:GetUnits()
  if units==nil then
    return nammo, nshells, nrockets, nmissiles
  end
    
  for _,unit in pairs(units) do
  
    if unit and unit:IsAlive() then
    
      -- Output.
      local text=string.format("ARTY group %s - unit %s:\n", self.Controllable:GetName(), unit:GetName())
  
      -- Get ammo table.
      local ammotable=unit:GetAmmo()

      if ammotable ~= nil then
      
        local weapons=#ammotable
        
        -- Display ammo table
        if display then
          self:E(ARTY.id..string.format("Number of weapons %d.", weapons))
          self:E({ammotable=ammotable})    
          self:E(ARTY.id.."Ammotable:")
          for id,bla in pairs(ammotable) do
            self:E({id=id, ammo=bla})
          end
        end
                
        -- Loop over all weapons.
        for w=1,weapons do
        
          -- Number of current weapon.
          local Nammo=ammotable[w]["count"]
          
          -- Typename of current weapon
          local Tammo=ammotable[w]["desc"]["typeName"]
          
          -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3
          local Category=ammotable[w].desc.category
          
          -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
          local MissileCategory=nil
          if Category==Weapon.Category.MISSILE then
            MissileCategory=ammotable[w].desc.missileCategory
          end
          
          local function missilecat(n)
            local cat="unknown"
            if n==1 then
              cat="air-to-air"
            elseif n==2 then
              cat="surface-to-air"
            elseif n==3 then
              cat="ballistic"
            elseif n==4 then
              cat="anti-ship"
            elseif n==5 then
              cat="cruise"
            elseif n==6 then
              cat="other"
            end
            return cat
          end
          
          -- Check for correct shell type.
          local _gotshell=false
          if #self.ammoshells>0 then
            -- User explicitly specified the valid type(s) of shells.
            for _,_type in pairs(self.ammoshells) do
              if string.match(Tammo, _type) then
                _gotshell=true
              end
            end
          else
            if Category==Weapon.Category.SHELL then
              _gotshell=true
            end
          end

          -- Check for correct rocket type.
          local _gotrocket=false
          if #self.ammorockets>0 then
            for _,_type in pairs(self.ammorockets) do
              if string.match(Tammo, _type) then
                _gotrocket=true
              end
            end
          else
            if Category==Weapon.Category.ROCKET then
              _gotrocket=true
            end            
          end

          -- Check for correct missile type.
          local _gotmissile=false
          if #self.ammomissiles>0 then
            for _,_type in pairs(self.ammomissiles) do
              if string.match(Tammo,_type) then
                _gotmissile=true
              end
            end
          else
            if Category==Weapon.Category.MISSILE then
              _gotmissile=true
            end                      
          end
                           
          -- We are specifically looking for shells or rockets here.
          if _gotshell then 
          
            -- Add up all shells.
            nshells=nshells+Nammo
          
            -- Debug info.
            text=text..string.format("- %d shells of type %s\n", Nammo, Tammo)
            
          elseif _gotrocket then
          
            -- Add up all rockets.
            nrockets=nrockets+Nammo
            
            -- Debug info.
            text=text..string.format("- %d rockets of type %s\n", Nammo, Tammo)
            
          elseif _gotmissile then
          
            -- Add up all cruise missiles (category 5)
            if MissileCategory==5 then
              nmissiles=nmissiles+Nammo
            end
            
            -- Debug info.
            text=text..string.format("- %d %s missiles of type %s\n", Nammo, missilecat(MissileCategory), Tammo)
                                
          else
          
            -- Debug info.
            text=text..string.format("- %d unknown ammo of type %s (category=%d, missile category=%s)\n", Nammo, Tammo, Category, tostring(MissileCategory))
            
          end
          
        end
      end

      -- Debug text and send message.
      if display then
        self:E(ARTY.id..text)
      else
        self:T3(ARTY.id..text)
      end
      MESSAGE:New(text, 10):ToAllIf(display)
               
    end
  end
      
  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles
  
  return nammo, nshells, nrockets, nmissiles
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mark Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Extract engagement assignments and parameters from mark text.
-- @param #ARTY self
-- @param #string text Marker text.
-- @return #boolean If true, authentification successful. 
function ARTY:_MarkerKeyAuthentification(text)

  -- Set battery and coalition.
  local batteryname=self.Controllable:GetName()
  local batterycoalition=self.Controllable:GetCoalition()

  -- Get assignment.
  local mykey=nil
  if self.markkey~=nil then
  
    -- keywords are split by "," 
    local keywords=self:_split(text, ",")
    for _,key in pairs(keywords) do
      local s=self:_split(key, " ")
      local val=s[2]
      if key:lower():find("key") then      
        mykey=tonumber(val)
        self:T(ARTY.id..string.format("Authorisation Key=%s.", val))
      end
    end
    
  end
  
  -- Check if the authorization key is required and if it is valid.
  local _validkey=true
  
  -- Check if group needs authorization.
  if self.markkey~=nil then
    -- Assume key is incorrect.
    _validkey=false
    
    -- If key was found, check if matches.
    if mykey~=nil then
      _validkey=self.markkey==mykey            
    end    
    self:T2(ARTY.id..string.format("%s, authkey=%s == %s=playerkey ==> valid=%s", batteryname, tostring(self.markkey), tostring(mykey), tostring(_validkey)))
    
    -- Send message
    local text=""
    if mykey==nil then
      text=string.format("%s, authorization required but did not receive a key!", batteryname)
    elseif _validkey==false then
      text=string.format("%s, authorization required but did receive an incorrect key (key=%s)!", batteryname, tostring(mykey))
    elseif _validkey==true then
      text=string.format("%s, authentification successful!", batteryname)
    end
    MESSAGE:New(text, 10):ToCoalitionIf(batterycoalition, self.report or self.Debug)
  end

  return _validkey
end

--- Extract engagement assignments and parameters from mark text.
-- @param #ARTY self
-- @param #string text Marker text to be analyzed.
-- @return #table Table with assignment parameters, e.g. number of shots, radius, time etc.
function ARTY:_Markertext(text)
  self:F(text)
 
  -- Assignment parameters. 
  local assignment={}
  assignment.battery={}
  assignment.move=false
  assignment.engage=false
  assignment.request=false
  assignment.readonly=false
  assignment.canceltarget=false
  assignment.cancelcurrent=false
  
  -- Check for correct keywords.
  if text:lower():find("arty engage") or text:lower():find("arty attack") then
    assignment.engage=true
  elseif text:lower():find("arty move") or text:lower():find("arty relocate") then
    assignment.move=true
  elseif text:lower():find("arty request") then
    assignment.request=true  
  else
    self:E(ARTY.id..'ERROR: Neither "ARTY ENGAGE" nor "ARTY MOVE" nor "ARTY RELOCATE" nor "ARTY REQUEST" keyword specified!')
    return nil
  end
    
  -- keywords are split by "," 
  local keywords=self:_split(text, ",")
  self:T({keywords=keywords})

  for _,key in pairs(keywords) do
  
    local s=self:_split(key, " ")
    local val=s[2]
  
    -- Battery name, i.e. which ARTY group should fire.
    if key:lower():find("battery") then
      
      local v=self:_split(key, '"')
      
      for i=2,#v,2 do        
        table.insert(assignment.battery, v[i])
        self:T2(ARTY.id..string.format("Key Battery=%s.", v[i]))
      end
                
    elseif (assignment.engage or assignment.move) and key:lower():find("time") then
    
      if val:lower():find("now") then
        assignment.time=self:_SecondsToClock(timer.getTime0()+2)
      else
        assignment.time=val
      end        
      self:T2(ARTY.id..string.format("Key Time=%s.", val))
      
    elseif assignment.engage and key:lower():find("shot") then
    
      assignment.nshells=tonumber(s[2])
      self:T(ARTY.id..string.format("Key Shot=%s.", val))
      
    elseif assignment.engage and key:lower():find("prio") then
    
      assignment.prio=tonumber(val)
      self:T2(string.format("Key Prio=%s.", val))
      
    elseif assignment.engage and key:lower():find("maxengage") then
    
      assignment.maxengage=tonumber(val)
      self:T2(ARTY.id..string.format("Key Maxengage=%s.", val))
      
    elseif assignment.engage and key:lower():find("radius") then
    
      assignment.radius=tonumber(val)
      self:T2(ARTY.id..string.format("Key Radius=%s.", val))
      
    elseif assignment.engage and key:lower():find("weapon") then
      
      if val:lower():find("cannon") then
        assignment.weapontype=ARTY.WeaponType.Cannon
      elseif val:lower():find("rocket") then
        assignment.weapontype=ARTY.WeaponType.Rockets
      elseif val:lower():find("missile") then
        assignment.weapontype=ARTY.WeaponType.GuidedMissile
      elseif val:lower():find("nuke") then
        assignment.weapontype=ARTY.WeaponType.TacticalNukes
      else
        assignment.weapontype=ARTY.WeaponType.Auto
      end        
      self:T2(ARTY.id..string.format("Key Weapon=%s.", val))
      
    elseif assignment.move and key:lower():find("speed") then
    
      assignment.speed=tonumber(val)
      self:T2(ARTY.id..string.format("Key Speed=%s.", val))
      
    elseif assignment.move and (key:lower():find("on road") or key:lower():find("onroad") or key:lower():find("use road")) then
    
      assignment.onroad=true
      self:T2(ARTY.id..string.format("Key Onroad=true."))
              
    elseif key:lower():find("irrevocable") or key:lower():find("readonly") then
    
      assignment.readonly=true
      self:T2(ARTY.id..string.format("Key Readonly=true."))

    elseif assignment.move and key:lower():find("canceltarget") then
    
      assignment.canceltarget=true
      self:T2(ARTY.id..string.format("Key Cancel Target (before move)=true."))
      
    elseif (assignment.engage or assignment.move) and key:lower():find("cancelcurrent") then
    
      assignment.cancelcurrent=true
      self:T2(ARTY.id..string.format("Key Cancel Current=true."))
      
    elseif assignment.request and key:lower():find("rearm") then
    
      assignment.requestrearming=true
      self:T2(ARTY.id..string.format("Key Request Rearming=true."))
      
    elseif assignment.request and key:lower():find("ammo") then
    
      assignment.requestammo=true
      self:T2(ARTY.id..string.format("Key Request Ammo=true."))

    elseif assignment.request and key:lower():find("target") then
    
      assignment.requesttargets=true
      self:T2(ARTY.id..string.format("Key Request Targets=true."))

    elseif assignment.request and key:lower():find("status") then
    
      assignment.requeststatus=true
      self:T2(ARTY.id..string.format("Key Request Status=true."))

    elseif assignment.request and (key:lower():find("move") or key:lower():find("relocation")) then
    
      assignment.requestmoves=true
      self:T2(ARTY.id..string.format("Key Request Moves=true."))
              
    elseif key:lower():find("lldms") then
      
      local _flat = "%d+:%d+:%d+%s*[N,S]"
      local _flon = "%d+:%d+:%d+%s*[W,E]"
      local _lat=key:match(_flat)
      local _lon=key:match(_flon)
      self:T2(ARTY.id..string.format("Key LLDMS: lat=%s, long=%s", _lat,_lon))
      
      if _lat and _lon then
      
        -- Convert DMS string to DD numbers format.
        local _latitude, _longitude=self:_LLDMS2DD(_lat, _lon)
        self:T2(ARTY.id..string.format("Key LLDMS: lat=%.3f, long=%.3f", _latitude,_longitude))
        
        -- Convert LL to coordinate object.
        if _latitude and _longitude then
          assignment.coord=COORDINATE:NewFromLLDD(_latitude,_longitude)
        end
                  
      end
    end      
  end
  
  return assignment
end

--- Request ammo via mark.
-- @param #ARTY self
function ARTY:_MarkRequestAmmo()
  self:GetAmmo(true)
end

--- Request status via mark.
-- @param #ARTY self
function ARTY:_MarkRequestStatus()
  self:_StatusReport(true)
end

--- Request Moves.
-- @param #ARTY self
function ARTY:_MarkRequestMoves()
  local text=string.format("%s, relocations:", self.Controllable:GetName())
  if #self.moves>0 then
    for _,move in pairs(self.moves) do
      if self.currentMove and move.name == self.currentMove.name then
        text=text..string.format("\n- %s (current)", self:_MoveInfo(move))
      else
        text=text..string.format("\n- %s", self:_MoveInfo(move))
      end
    end
  else
    text=text..string.format("\n- no queued relocations")
  end
  MESSAGE:New(text, 20):Clear():ToCoalition(self.Controllable:GetCoalition())
end

--- Request Targets.
-- @param #ARTY self
function ARTY:_MarkRequestTargets()
  local text=string.format("%s, targets:", self.Controllable:GetName())
  if #self.targets>0 then
    for _,target in pairs(self.targets) do
      if self.currentTarget and target.name == self.currentTarget.name then
        text=text..string.format("\n- %s (current)", self:_TargetInfo(target))
      else
        text=text..string.format("\n- %s", self:_TargetInfo(target))
      end
    end
  else
    text=text..string.format("\n- no queued targets")
  end
  MESSAGE:New(text, 20):Clear():ToCoalition(self.Controllable:GetCoalition())
end

--- Create a name for an engagement initiated by placing a marker.
-- @param #ARTY self
-- @param #number markerid ID of the placed marker.
-- @return #string Name of target engagement.
function ARTY:_MarkTargetName(markerid)
  return string.format("BATTERY=%s, Marked Target ID=%d", self.Controllable:GetName(), markerid)
end

--- Create a name for a relocation move initiated by placing a marker.
-- @param #ARTY self
-- @param #number markerid ID of the placed marker.
-- @return #string Name of relocation move.
function ARTY:_MarkMoveName(markerid)
  return string.format("BATTERY=%s, Marked Relocation ID=%d", self.Controllable:GetName(), markerid)
end

--- Get the marker ID from the assigned task name.
-- @param #ARTY self
-- @param #string name Name of the assignment.
-- @return #string Name of the ARTY group or nil
-- @return #number ID of the marked target or nil.
-- @return #number ID of the marked relocation move or nil
function ARTY:_GetMarkIDfromName(name)

    -- keywords are split by "," 
    local keywords=self:_split(name, ",")

    local battery=nil
    local markTID=nil
    local markMID=nil
    
    for _,key in pairs(keywords) do

      local str=self:_split(key, "=")
      local par=str[1]
      local val=str[2]
      
      if par:find("BATTERY") then
        battery=val
      end
      if par:find("Marked Target ID") then
        markTID=tonumber(val)
      end
      if par:find("Marked Relocation ID") then
        markMID=tonumber(val)
      end
      
    end
    
    return battery, markTID, markMID
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Sort targets with respect to priority and number of times it was already engaged.
-- @param #ARTY self
function ARTY:_SortTargetQueuePrio()
  self:F2()
  
  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    return (a.engaged < b.engaged) or (a.engaged==b.engaged and a.prio < b.prio)
  end
  table.sort(self.targets, _sort)
  
  -- Debug output.
  self:T3(ARTY.id.."Sorted targets wrt prio and number of engagements:")
  for i=1,#self.targets do
    local _target=self.targets[i]
    self:T3(ARTY.id..string.format("Target %s", self:_TargetInfo(_target)))
  end
end

--- Sort array with respect to time. Array elements must have a .time entry. 
-- @param #ARTY self
-- @param #table queue Array to sort. Should have elemnt .time.
function ARTY:_SortQueueTime(queue)
  self:F3({queue=queue})

  -- Sort targets w.r.t attack time.
  local function _sort(a, b)
    if a.time == nil and b.time == nil then
      return false
    end
    if a.time == nil then
      return false
    end
    if b.time == nil then
      return true
    end
    return a.time < b.time
  end
  table.sort(queue, _sort)

  -- Debug output.
  self:T3(ARTY.id.."Sorted queue wrt time:")
  for i=1,#queue do
    local _queue=queue[i]
    local _time=tostring(_queue.time)
    local _clock=tostring(self:_SecondsToClock(_queue.time))
    self:T3(ARTY.id..string.format("%s: time=%s, clock=%s", _queue.name, _time, _clock))
  end

end

--- Heading from point a to point b in degrees.
--@param #ARTY self
--@param Core.Point#COORDINATE a Coordinate.
--@param Core.Point#COORDINATE b Coordinate.
--@return #number angle Angle from a to b in degrees.
function ARTY:_GetHeading(a, b)
  local dx = b.x-a.x
  local dy = b.z-a.z
  local angle = math.deg(math.atan2(dy,dx))
  if angle < 0 then
    angle = 360 + angle
  end
  return angle
end

--- Check all targets whether they are in range.
-- @param #ARTY self
function ARTY:_CheckTargetsInRange()

  for i=1,#self.targets do
    local _target=self.targets[i]
    
    self:T(ARTY.id..string.format("Before: Target %s - in range = %s", _target.name, tostring(_target.inrange)))
    
    -- Check if target is in range.
    local _inrange,_toofar,_tooclose=self:_TargetInRange(_target)
    self:T(ARTY.id..string.format("Inbetw: Target %s - in range = %s, toofar = %s, tooclose = %s", _target.name, tostring(_target.inrange), tostring(_toofar), tostring(_tooclose)))
    
    -- Init default for assigning moves into range.
    local _movetowards=false
    local _moveaway=false
    
    if _target.inrange==nil then
    
      -- First time the check is performed. We call the function again and send a message.
      _target.inrange,_toofar,_tooclose=self:_TargetInRange(_target, self.report or self.Debug)
      
      -- Send group towards/away from target.
      if _toofar then
        _movetowards=true
      elseif _tooclose then
        _moveaway=true
      end
    
    elseif _target.inrange==true then
    
      -- Target was in range at previous check...
           
      if _toofar then       --...but is now too far away.
        _movetowards=true
      elseif _tooclose then --...but is now too close.
        _moveaway=true
      end
    
    elseif _target.inrange==false then
    
      -- Target was out of range at previous check.
      
      if _inrange then
        -- Inform coalition that target is now in range.
        local text=string.format("%s, target %s is now in range.", self.Controllable:GetName(), _target.name)
        self:T(ARTY.id..text)
        MESSAGE:New(text,10):ToCoalitionIf(self.Controllable:GetCoalition(), self.report or self.Debug)
      end
    
    end
    
    -- Assign a relocation command so that the unit will be in range of the requested target.
    if self.autorelocate and (_movetowards or _moveaway) then
    
      -- Get current position.
      local _from=self.Controllable:GetCoordinate()
      local _dist=_from:Get2DDistance(_target.coord)
      
      if _dist<=self.autorelocatemaxdist then
      
        local _tocoord --Core.Point#COORDINATE
        local _name=""
        local _safetymargin=500
      
        if _movetowards then
        
          -- Target was in range on previous check but now we are too far away.        
          local _waytogo=_dist-self.maxrange+_safetymargin
          local _heading=self:_GetHeading(_from,_target.coord)
          _tocoord=_from:Translate(_waytogo, _heading)
          _name=string.format("Relocation to within max firing range of target %s", _target.name)
          
        elseif _moveaway then
        
        -- Target was in range on previous check but now we are too far away.        
        local _waytogo=_dist-self.minrange+_safetymargin
        local _heading=self:_GetHeading(_target.coord,_from)
        _tocoord=_from:Translate(_waytogo, _heading)
        _name=string.format("Relocation to within min firing range of target %s", _target.name)

        end
  
        -- Send info message.
        MESSAGE:New(_name.." assigned.", 10):ToCoalitionIf(self.Controllable:GetCoalition(), self.report or self.Debug)
        
        -- Assign relocation move.
        self:AssignMoveCoord(_tocoord, nil, nil, self.autorelocateonroad, false, _name, true)
        
      end
            
    end
    
    -- Update value.
    _target.inrange=_inrange
    
    self:T(ARTY.id..string.format("After: Target %s - in range = %s", _target.name, tostring(_target.inrange)))
    
  end
end

--- Check all timed targets and return the target which should be attacked next.
-- @param #ARTY self
-- @return #table Target which is due to be attacked now. 
function ARTY:_CheckTimedTargets()
  self:F3()
  
  -- Current time.
  local Tnow=timer.getAbsTime()
  
  -- Sort Targets wrt time.
  self:_SortQueueTime(self.targets)
  
  for i=1,#self.targets do
    local _target=self.targets[i]
    
    -- Debug info.
    self:T3(ARTY.id..string.format("Check TIMED target %d: %s", i, self:_TargetInfo(_target)))
    
    -- Check if target has an attack time which has already passed. Also check that target is not under fire already and that it is in range. 
    if _target.time and Tnow>=_target.time and _target.underfire==false and self:_TargetInRange(_target) then
    
      -- Check if group currently has a target and whether its priorty is lower than the timed target.
      if self.currentTarget then
        if self.currentTarget.prio > _target.prio then
          -- Current target under attack but has lower priority than this target.
          self:T2(ARTY.id..string.format("Found TIMED HIGH PRIO target %s.", self:_TargetInfo(_target)))
          return _target
        end
      else
        -- No current target.
        self:T2(ARTY.id..string.format("Found TIMED target %s.", self:_TargetInfo(_target)))
        return _target
      end
    end
  end

  return nil
end

--- Check all moves and return the one which should be executed next.
-- @param #ARTY self
-- @return #table Move which is due. 
function ARTY:_CheckMoves()
  self:F3()
  
  -- Current time.
  local Tnow=timer.getAbsTime()
  
  -- Sort Targets wrt time.
  self:_SortQueueTime(self.moves)
  
  -- Check if we are currently firing.
  local firing=false
  if self.currentTarget then
    firing=true
  end
  
  for i=1,#self.moves do
    local _move=self.moves[i]
    
    -- Check if time for move is reached. 
    if Tnow >= _move.time and (firing==false or _move.cancel) then
      return _move
    end 
  end
  
  return nil
end

--- Check all normal (untimed) targets and return the target with the highest priority which has been engaged the fewest times.
-- @param #ARTY self
-- @return #table Target which is due to be attacked now or nil if no target could be found.
function ARTY:_CheckNormalTargets()
  self:F3()
  
  -- Sort targets w.r.t. prio and number times engaged already.
  self:_SortTargetQueuePrio()
      
  -- Loop over all sorted targets.
  for i=1,#self.targets do  
    local _target=self.targets[i]
    
    -- Debug info.
    self:T3(ARTY.id..string.format("Check NORMAL target %d: %s", i, self:_TargetInfo(_target)))
  
    -- Check that target no time, is not under fire currently and in range.
    if _target.underfire==false and _target.time==nil and _target.maxengage > _target.engaged and self:_TargetInRange(_target) then
      
      -- Debug info.
      self:T2(ARTY.id..string.format("Found NORMAL target %s", self:_TargetInfo(_target)))
      
      return _target
    end
  end
  
  return nil
end

--- Check whether shooting started within a certain time (~5 min). If not, the current target is considered invalid and removed from the target list.
-- @param #ARTY self
function ARTY:_CheckShootingStarted()
  self:F2()
  
  if self.currentTarget then
  
    -- Current time.
    local Tnow=timer.getTime()
    
    -- Get name and id of target.
    local name=self.currentTarget.name
          
    -- Time that passed after current target has been assigned.
    local dt=Tnow-self.currentTarget.Tassigned
    
    -- Debug info
    if self.Nshots==0 then
      self:T(ARTY.id..string.format("%s, waiting for %d seconds for first shot on target %s.", self.Controllable:GetName(), dt, name))
    end
    
    -- Check if we waited long enough and no shot was fired.
    if dt > self.WaitForShotTime and self.Nshots==0 then
    
      -- Debug info.
      self:T(ARTY.id..string.format("%s, no shot event after %d seconds. Removing current target %s from list.", self.Controllable:GetName(), self.WaitForShotTime, name))
    
      -- CeaseFire.
      self:CeaseFire(self.currentTarget)
    
      -- Remove target from list.
      self:RemoveTarget(name)
      
    end
  end
end

--- Get the index of a target by its name.
-- @param #ARTY self
-- @param #string name Name of target.
-- @return #number Arrayindex of target.
function ARTY:_GetTargetIndexByName(name)
  self:F2(name)
  
  for i=1,#self.targets do
    local targetname=self.targets[i].name
    self:T3(ARTY.id..string.format("Have target with name %s. Index = %d", targetname, i))
    if targetname==name then
      self:T2(ARTY.id..string.format("Found target with name %s. Index = %d", name, i))
      return i
    end
  end
  
  self:T2(ARTY.id..string.format("WARNING: Target with name %s could not be found. (This can happen.)", name))
  return nil
end

--- Get the index of a move by its name.
-- @param #ARTY self
-- @param #string name Name of move.
-- @return #number Arrayindex of move.
function ARTY:_GetMoveIndexByName(name)
  self:F2(name)
  
  for i=1,#self.moves do
    local movename=self.moves[i].name
    self:T3(ARTY.id..string.format("Have move with name %s. Index = %d", movename, i))
    if movename==name then
      self:T2(ARTY.id..string.format("Found move with name %s. Index = %d", name, i))
      return i
    end
  end
  
  self:T2(ARTY.id..string.format("WARNING: Move with name %s could not be found. (This can happen.)", name))
  return nil
end

--- Check if a name is unique. If not, a new unique name can be created by adding a running index #01, #02, ...
-- @param #ARTY self
-- @param #table givennames Table with entries of already given names. Must contain a .name item.
-- @param #string name Name to check if it already exists in givennames table.
-- @param #boolean makeunique If true, a new unique name is returned by appending the running index.
-- @return #string Unique name, which is not already given for another target.
function ARTY:_CheckName(givennames, name, makeunique)
  self:F2({givennames=givennames, name=name})  

  local newname=name
  local counter=1
  local n=1
  local nmax=100
  if makeunique==nil then
    makeunique=true
  end
  
  repeat -- until a unique name is found.
  
    -- We assume the name is unique.
    local _unique=true
    
    -- Loop over all targets already defined.
    for _,_target in pairs(givennames) do
    
      -- Target name.
      local _givenname=_target.name
      
      -- Name is already used by another target.
      if _givenname==newname then
      
        -- Name is already used for another target ==> try again with new name.
        _unique=false
              
      end
      
      -- Debug info.
      self:T3(ARTY.id..string.format("%d: givenname = %s, newname=%s, unique = %s, makeunique = %s", n, tostring(_givenname), newname, tostring(_unique), tostring(makeunique)))   
    end
    
    -- Create a new name if requested and try again.
    if _unique==false and makeunique==true then
    
      -- Define newname = "name #01"
      newname=string.format("%s #%02d", name, counter)
      
      -- Increase counter.
      counter=counter+1
    end
    
    -- Name is not unique and we don't want to make it unique.
    if _unique==false and makeunique==false then
      self:T3(ARTY.id..string.format("Name %s is not unique. Return false.", tostring(newname)))
      
      -- Return
      return name, false
    end
    
    -- Increase loop counter. We try max 100 times.
    n=n+1
  until (_unique or n==nmax)
  
  -- Debug output and return new name.
  self:T3(ARTY.id..string.format("Original name %s, new name = %s", name, newname))
  return newname, true
end

--- Check if target is in range.
-- @param #ARTY self
-- @param #table target Target table.
-- @param #boolean message (Optional) If true, send a message to the coalition if the target is not in range. Default is no message is send.
-- @return #boolean True if target is in range, false otherwise.
-- @return #boolean True if ARTY group is too far away from the target, i.e. distance > max firing range.
-- @return #boolean True if ARTY group is too close to the target, i.e. distance < min finring range.
function ARTY:_TargetInRange(target, message)
  self:F3(target)
  
  -- Default is no message.
  if message==nil then
    message=false
  end

  -- Distance between ARTY group and target.
  local _dist=self.Controllable:GetCoordinate():Get2DDistance(target.coord)
  
  -- Assume we are in range.
  local _inrange=true
  local _tooclose=false
  local _toofar=false
  local text=""
  
  if _dist < self.minrange then
    _inrange=false
    _tooclose=true
    text=string.format("%s, target is out of range. Distance of %.1f km is below min range of %.1f km.", self.Controllable:GetName(), _dist/1000, self.minrange/1000)
  elseif _dist > self.maxrange then
    _inrange=false
    _toofar=true
    text=string.format("%s, target is out of range. Distance of %.1f km is greater than max range of %.1f km.", self.Controllable:GetName(), _dist/1000, self.maxrange/1000)
  end
  
  -- Debug output.
  if not _inrange then
    self:T(ARTY.id..text)
    MESSAGE:New(text, 5):ToCoalitionIf(self.Controllable:GetCoalition(), (self.report and message) or (self.Debug and message))
  end
    
  -- Remove target if ARTY group cannot move, e.g. Mortas. No chance to be ever in range.
  if self.SpeedMax<1 and _inrange==false then
    self:RemoveTarget(target.name)
  end

  return _inrange,_toofar,_tooclose
end

--- Get the weapon type name, which should be used to attack the target.
-- @param #ARTY self
-- @param #number tnumber Number of weapon type ARTY.WeaponType.XXX
-- @return #number tnumber of weapon type.
function ARTY:_WeaponTypeName(tnumber)
  self:F2(tnumber)
  local name="unknown"
  if tnumber==ARTY.WeaponType.Auto then
    name="Auto" -- (Cannon, Rockets, Missiles)
  elseif tnumber==ARTY.WeaponType.Cannon then
    name="Cannons"
  elseif tnumber==ARTY.WeaponType.Rockets then
    name="Rockets"
   elseif tnumber==ARTY.WeaponType.UnguidedAny then
    name="Unguided Weapons" -- (Cannon or Rockets)
  elseif tnumber==ARTY.WeaponType.CruiseMissile then
    name="Cruise Missiles"
  elseif tnumber==ARTY.WeaponType.GuidedMissile then
    name="Guided Missiles"
  elseif tnumber==ARTY.WeaponType.AntiShipMissile then
    name="Anti-Ship Missiles"
  elseif tnumber==ARTY.WeaponType.TacticalNukes then
    name="Tactical Nukes"    
  end
  return name
end

--- Find a random coordinate in the vicinity of another coordinate. 
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Center coordinate.
-- @param #number rmin (Optional) Minimum distance in meters from center coordinate. Default 20 m.
-- @param #number rmax (Optional) Maximum distance in meters from center coordinate. Default 80 m.
-- @return Core.Point#COORDINATE Random coordinate in a certain distance from center coordinate.
function ARTY:_VicinityCoord(coord, rmin, rmax)
  self:F2({coord=coord, rmin=rmin, rmax=rmax})
  -- Set default if necessary.
  rmin=rmin or 20
  rmax=rmax or 80
  -- Random point withing range.
  local vec2=coord:GetRandomVec2InRadius(rmax, rmin)
  local pops=COORDINATE:NewFromVec2(vec2)
  -- Debug info.
  self:T3(ARTY.id..string.format("Vicinity distance = %d (rmin=%d, rmax=%d)", pops:Get2DDistance(coord), rmin, rmax))
  return pops
end

--- Print event-from-to string to DCS log file. 
-- @param #ARTY self
-- @param #string BA Before/after info.
-- @param #string Event Event.
-- @param #string From From state.
-- @param #string To To state.
function ARTY:_EventFromTo(BA, Event, From, To)
  local text=string.format("%s: %s EVENT %s: %s --> %s", BA, self.Controllable:GetName(), Event, From, To)
  self:T3(ARTY.id..text)
end

--- Split string. C.f. http://stackoverflow.com/questions/1426954/split-string-in-lua
-- @param #ARTY self
-- @param #string str Sting to split.
-- @param #string sep Speparator for split.
-- @return #table Split text.
function ARTY:_split(str, sep)
  self:F3({str=str, sep=sep})  
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
    table.insert(result, each)
  end
  return result
end

--- Returns the target parameters as formatted string.
-- @param #ARTY self
-- @return #string name, prio, radius, nshells, engaged, maxengage, time, weapontype
function ARTY:_TargetInfo(target)
  local clock=tostring(self:_SecondsToClock(target.time))
  local weapon=self:_WeaponTypeName(target.weapontype)
  local _underfire=tostring(target.underfire)
  return string.format("%s: prio=%d, radius=%d, nshells=%d, engaged=%d/%d, weapontype=%s, time=%s, underfire=%s",
  target.name, target.prio, target.radius, target.nshells, target.engaged, target.maxengage, weapon, clock,_underfire)
end

--- Returns a formatted string with information about all move parameters.
-- @param #ARTY self
-- @param #table move Move table item.
-- @return #string Info string.
function ARTY:_MoveInfo(move)
  self:F3(move)
  local _clock=self:_SecondsToClock(move.time)
  return string.format("%s: time=%s, speed=%d, onroad=%s, cancel=%s", move.name, _clock, move.speed, tostring(move.onroad), tostring(move.cancel))
end

--- Convert Latitude and Lontigude from DMS to DD.
-- @param #ARTY self
-- @param #string l1 Latitude or longitude as string in the format DD:MM:SS N/S/W/E
-- @param #string l2 Latitude or longitude as string in the format DD:MM:SS N/S/W/E
-- @return #number Latitude in decimal degree format.
-- @return #number Longitude in decimal degree format.
function ARTY:_LLDMS2DD(l1,l2)
  self:F2(l1,l2)

  -- Make an array of lat and long.
  local _latlong={l1,l2}
  
  local _latitude=nil
  local _longitude=nil
  
  for _,ll in pairs(_latlong) do
  
    -- Format is expected as "DD:MM:SS" or "D:M:S".
    local _format = "%d+:%d+:%d+"    
    local _ldms=ll:match(_format)
    
    if ldms then
      
      -- Split DMS to degrees, minutes and seconds.
      local _dms=self:_split(_ldms, ":")
      local _deg=tonumber(_dms[1])
      local _min=tonumber(_dms[2])
      local _sec=tonumber(_dms[3])
      
      -- Convert DMS to DD.
      local function DMS2DD(d,m,s)
       return d+m/60+s/3600
      end
  
      -- Detect with hemisphere is meant.
      if ll:match("N") then
        _latitude=DMS2DD(_deg,_min,_sec)
      elseif ll:match("S") then
        _latitude=-DMS2DD(_deg,_min,_sec)
      elseif ll:match("W") then
        _longitude=-DMS2DD(_deg,_min,_sec)
      elseif ll:match("E") then
        _longitude=DMS2DD(_deg,_min,_sec)
      end
          
      -- Debug text.
      local text=string.format("DMS %02d Deg %02d min %02d sec",_deg,_min,_sec)
      self:T2(ARTY.id..text)

    end   
  end
  
  -- Debug text.
  local text=string.format("\nLatitude  %.3f", _latitude)
  text=text..string.format("\nLongitude %.3f", _longitude)
  self:T2(ARTY.id..text)
  
  return _latitude,_longitude
end

--- Convert time in seconds to hours, minutes and seconds.
-- @param #ARTY self
-- @param #number seconds Time in seconds.
-- @return #string Time in format Hours:minutes:seconds.
function ARTY:_SecondsToClock(seconds)
  self:F3({seconds=seconds})
  
  if seconds==nil then
    return nil
  end
  
  -- Seconds
  local seconds = tonumber(seconds)
  
  -- Seconds of this day.
  local _seconds=seconds%(60*60*24)

  if seconds <= 0 then
    return nil
  else
    local hours = string.format("%02.f", math.floor(_seconds/3600))
    local mins  = string.format("%02.f", math.floor(_seconds/60 - (hours*60)))
    local secs  = string.format("%02.f", math.floor(_seconds - hours*3600 - mins *60))
    local days  = string.format("%d", seconds/(60*60*24))
    return hours..":"..mins..":"..secs.."+"..days
  end
end

--- Convert clock time from hours, minutes and seconds to seconds.
-- @param #ARTY self
-- @param #string clock String of clock time. E.g., "06:12:35".
function ARTY:_ClockToSeconds(clock)
  self:F3({clock=clock})
  
  if clock==nil then
    return nil
  end
  
  -- Seconds init.
  local seconds=0
  
  -- Split additional days.
  local dsplit=self:_split(clock, "+")
  
  -- Convert days to seconds.
  if #dsplit>1 then
    seconds=seconds+tonumber(dsplit[2])*60*60*24
  end

  -- Split hours, minutes, seconds    
  local tsplit=self:_split(dsplit[1], ":")

  -- Get time in seconds
  local i=1
  for _,time in ipairs(tsplit) do
    if i==1 then
      -- Hours
      seconds=seconds+tonumber(time)*60*60
    elseif i==2 then
      -- Minutes
      seconds=seconds+tonumber(time)*60
    elseif i==3 then
      -- Seconds
      seconds=seconds+tonumber(time)
    end
    i=i+1
  end
  
  self:T3(ARTY.id..string.format("Clock %s = %d seconds", clock, seconds))
  return seconds
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  