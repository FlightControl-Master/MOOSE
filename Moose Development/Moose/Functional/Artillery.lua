--- **Functional** - Control artillery units.
--
-- ===
--
-- The ARTY class can be used to easily assign and manage targets for artillery units using an advanced queueing system.
--
-- ## Features:
--
--   * Multiple targets can be assigned. No restriction on number of targets.
--   * Targets can be given a priority. Engagement of targets is executed a according to their priority.
--   * Engagements can be scheduled, i.e. will be executed at a certain time of the day.
--   * Multiple relocations of the group can be assigned and scheduled via queueing system.
--   * Special weapon types can be selected for each attack, e.g. cruise missiles for Naval units.
--   * Automatic rearming once the artillery is out of ammo (optional).
--   * Automatic relocation after each firing engagement to prevent counter strikes (optional).
--   * Automatic relocation movements to get the battery within firing range (optional).
--   * Simulation of tactical nuclear shells as well as illumination and smoke shells.
--   * New targets can be added during the mission, e.g. when they are detected by recon units.
--   * Targets and relocations can be assigned by placing markers on the F10 map.
--   * Finite state machine implementation. Mission designer can interact when certain events occur.
--
-- ====
--
-- ## [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
--
-- ===
--
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
--
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536)
--
-- ====
-- @module Functional.Artillery
-- @image Artillery.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ARTY class
-- @type ARTY
-- @field #string ClassName Name of the class.
-- @field #string lid Log id for DCS.log file.
-- @field #boolean Debug Write Debug messages to DCS log file and send Debug messages to all players.
-- @field #table targets All targets assigned.
-- @field #table moves All moves assigned.
-- @field #ARTY.Target currentTarget Holds the current target, if there is one assigned.
-- @field #table currentMove Holds the current commanded move, if there is one assigned.
-- @field #number Nammo0 Initial amount total ammunition (shells+rockets+missiles) of the whole group.
-- @field #number Nshells0 Initial amount of shells of the whole group.
-- @field #number Nrockets0 Initial amount of rockets of the whole group.
-- @field #number Nmissiles0 Initial amount of missiles of the whole group.
-- @field #number Nukes0 Initial amount of tactical nukes of the whole group. Default is 0.
-- @field #number Nillu0 Initial amount of illumination shells of the whole group. Default is 0.
-- @field #number Nsmoke0 Initial amount of smoke shells of the whole group. Default is 0.
-- @field #number StatusInterval Update interval in seconds between status updates. Default 10 seconds.
-- @field #number WaitForShotTime Max time in seconds to wait until fist shot event occurs after target is assigned. If time is passed without shot, the target is deleted. Default is 300 seconds.
-- @field #table DCSdesc DCS descriptors of the ARTY group.
-- @field #string Type Type of the ARTY group.
-- @field #string DisplayName Extended type name of the ARTY group.
-- @field #number IniGroupStrength Inital number of units in the ARTY group.
-- @field #boolean IsArtillery If true, ARTY group has attribute "Artillery". This is automatically derived from the DCS descriptor table.
-- @field #boolean ismobile If true, ARTY group can move.
-- @field #boolean iscargo If true, ARTY group is defined as possible cargo. If it is immobile, targets out of range are not deleted from the queue.
-- @field Cargo.CargoGroup#CARGO_GROUP cargogroup Cargo group object if ARTY group is a cargo that will be transported to another place.
-- @field #string groupname Name of the ARTY group as defined in the mission editor.
-- @field #string alias Name of the ARTY group.
-- @field #table clusters Table of names of clusters the group belongs to. Can be used to address all groups within the cluster simultaniously.
-- @field #number SpeedMax Maximum speed of ARTY group in km/h. This is determined from the DCS descriptor table.
-- @field #number Speed Default speed in km/h the ARTY group moves at. Maximum speed possible is 80% of maximum speed the group can do.
-- @field #number RearmingDistance Safe distance in meters between ARTY group and rearming group or place at which rearming is possible. Default 100 m.
-- @field Wrapper.Group#GROUP RearmingGroup Unit designated to rearm the ARTY group.
-- @field #number RearmingGroupSpeed Speed in km/h the rearming unit moves at. Default is 50% of the max speed possible of the group.
-- @field #boolean RearmingGroupOnRoad If true, rearming group will move to ARTY group or rearming place using mainly roads. Default false.
-- @field Core.Point#COORDINATE RearmingGroupCoord Initial coordinates of the rearming unit. After rearming complete, the unit will return to this position.
-- @field Core.Point#COORDINATE RearmingPlaceCoord Coordinates of the rearming place. If the place is more than 100 m away from the ARTY group, the group will go there.
-- @field #boolean RearmingArtyOnRoad If true, ARTY group will move to rearming place using mainly roads. Default false.
-- @field Core.Point#COORDINATE InitialCoord Initial coordinates of the ARTY group.
-- @field #boolean report Arty group sends messages about their current state or target to its coalition.
-- @field #table ammoshells Table holding names of the shell types which are included when counting the ammo. Default is {"weapons.shells"} which include most shells.
-- @field #table ammorockets Table holding names of the rocket types which are included when counting the ammo. Default is {"weapons.nurs"} which includes most unguided rockets.
-- @field #table ammomissiles Table holding names of the missile types which are included when counting the ammo. Default is {"weapons.missiles"} which includes some guided missiles.
-- @field #number Nshots Number of shots fired on current target.
-- @field #number minrange Minimum firing range in kilometers. Targets closer than this distance are not engaged. Default 0.1 km.
-- @field #number maxrange Maximum firing range in kilometers. Targets further away than this distance are not engaged. Default 10000 km.
-- @field #number nukewarhead Explosion strength of tactical nuclear warhead in kg TNT. Default 75000.
-- @field #number Nukes Number of nuclear shells, the group has available. Note that if normal shells are empty, firing nukes is also not possible any more.
-- @field #number Nillu Number of illumination shells the group has available. Note that if normal shells are empty, firing illumination shells is also not possible any more.
-- @field #number illuPower Power of illumination warhead in mega candela. Default 1 mcd.
-- @field #number illuMinalt Minimum altitude in meters the illumination warhead will detonate.
-- @field #number illuMaxalt Maximum altitude in meters the illumination warhead will detonate.
-- @field #number Nsmoke Number of smoke shells the group has available. Note that if normal shells are empty, firing smoke shells is also not possible any more.
-- @field Utilities.Utils#SMOKECOLOR Smoke color of smoke shells. Default SMOKECOLOR.red.
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
-- @field #number coalition The coalition of the arty group.
-- @field #boolean respawnafterdeath Respawn arty group after all units are dead.
-- @field #number respawndelay Respawn delay in seconds.
-- @field #number dtTrack Time interval in seconds for weapon tracking.
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- Enables mission designers easily to assign targets for artillery units. Since the implementation is based on a Finite State Model (FSM), the mission designer can
-- interact with the process at certain events or states.
--
-- A new ARTY object can be created with the @{#ARTY.New}(*group*) constructor.
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
-- Assigning targets is a central point of the ARTY class. Multiple targets can be assigned simultaneously and are put into a queue.
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
-- If the engagement should start on the following day the format can be specified as "10:15:35+1", where the +1 denotes the following day.
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
-- have been engaged equally often, the target with the higher priority is engaged again. This continues until a target has engaged three times.
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
-- This also applies when multiple engagements are requested via the *maxengage* parameter. The first attack will not happen before the specified time.
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
-- In order to determine when a unit is out of ammo and possible initiate the rearming process it is necessary to know which types of weapons have to be counted.
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
-- One way to determine which types of ammo the unit carries, one can use the debug mode of the arty class via @{#ARTY.SetDebugON}().
-- In debug mode, the all ammo types of the group are printed to the monitor as message and can be found in the DCS.log file.
--
-- ## Employing Selected Weapons
--
-- If an ARTY group carries multiple weapons, which can be used for artillery task, a certain weapon type can be selected to attack the target.
-- This is done via the *weapontype* parameter of the @{#ARTY.AssignTargetCoord}(..., *weapontype*, ...) function.
--
-- The enumerator @{#ARTY.WeaponType} has been defined to select a certain weapon type. Supported values are:
--
-- * @{#ARTY.WeaponType}.Auto: Automatic weapon selection by the DCS logic. This is the default setting.
-- * @{#ARTY.WeaponType}.Cannon: Only cannons are used during the attack. Corresponding ammo type are shells and can be defined by @{#ARTY.SetShellTypes}.
-- * @{#ARTY.WeaponType}.Rockets: Only unguided are used during the attack. Corresponding ammo type are rockets/nurs and can be defined by @{#ARTY.SetRocketTypes}.
-- * @{#ARTY.WeaponType}.CruiseMissile: Only cruise missiles are used during the attack. Corresponding ammo type are missiles and can be defined by @{#ARTY.SetMissileTypes}.
-- * @{#ARTY.WeaponType}.TacticalNukes: Use tactical nuclear shells. This works only with units that have shells and is described below.
-- * @{#ARTY.WeaponType}.IlluminationShells: Use illumination shells. This works only with units that have shells and is described below.
-- * @{#ARTY.WeaponType}.SmokeShells: Use smoke shells. This works only with units that have shells and is described below.
--
-- ## Assigning Relocation Movements
-- The ARTY group can be commanded to move. This is done by the @{#ARTY.AssignMoveCoord}(*coord*, *time*, *speed*, *onroad*, *cancel*, *name*) function.
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
-- ## Simulated Weapons
--
-- In addition to the standard weapons a group has available some special weapon types that are not possible to use in the native DCS environment are simulated.
--
-- ### Tactical Nukes
--
-- ARTY groups that can fire shells can also be used to fire tactical nukes. This is achieved by setting the weapon type to **ARTY.WeaponType.TacticalNukes** in the
-- @{#ARTY.AssignTargetCoord}() function.
--
-- By default, they group does not have any nukes available. To give the group the ability the function @{#ARTY.SetTacNukeShells}(*n*) can be used.
-- This supplies the group with *n* nuclear shells, where *n* is restricted to the number of conventional shells the group can carry.
-- Note that the group must always have conventional shells left in order to fire a nuclear shell.
--
-- The default explosion strength is 0.075 kilo tons TNT. The can be changed with the @{#ARTY.SetTacNukeWarhead}(*strength*), where *strength* is given in kilo tons TNT.
--
-- ### Illumination Shells
--
-- ARTY groups that possess shells can fire shells with illumination bombs. First, the group needs to be equipped with this weapon. This is done by the
-- function @{ARTY.SetIlluminationShells}(*n*, *power*), where *n* is the number of shells the group has available and *power* the illumination power in mega candela (mcd).
--
-- In order to execute an engagement with illumination shells one has to use the weapon type *ARTY.WeaponType.IlluminationShells* in the
-- @{#ARTY.AssignTargetCoord}() function.
--
-- In the simulation, the explosive shell that is fired is destroyed once it gets close to the target point but before it can actually impact.
-- At this position an illumination bomb is triggered at a random altitude between 500 and 1000 meters. This interval can be set by the function
-- @{ARTY.SetIlluminationMinMaxAlt}(*minalt*, *maxalt*).
--
-- ### Smoke Shells
--
-- In a similar way to illumination shells, ARTY groups can also employ smoke shells. The number of smoke shells the group has available is set by the function
-- @{#ARTY.SetSmokeShells}(*n*, *color*), where *n* is the number of shells and *color* defines the smoke color. Default is SMOKECOLOR.Red.
--
-- The weapon type to be used in the @{#ARTY.AssignTargetCoord}() function is *ARTY.WeaponType.SmokeShells*.
--
-- The explosive shell the group fired is destroyed shortly before its impact on the ground and smoke of the specified color is triggered at that position.
--
--
-- ## Assignments via Markers on F10 Map
--
-- Targets and relocations can be assigned by players via placing a mark on the F10 map. The marker text must contain certain keywords.
--
-- This feature can be turned on with the @{#ARTY.SetMarkAssignmentsOn}(*key*, *readonly*). The parameter *key* is optional. When set, it can be used as PIN, i.e. only
-- players who know the correct key are able to assign and cancel targets or relocations. Default behavior is that all players belonging to the same coalition as the
-- ARTY group are able to assign targets and moves without a key.
--
-- ### Target Assignments
-- A new target can be assigned by writing **arty engage** in the marker text.
-- This is followed by a **comma separated list** of (optional) keywords and parameters.
-- First, it is important to address the ARTY group or groups that should engage. This can be done in numerous ways. The keywords are *battery*, *alias*, *cluster*.
-- It is also possible to address all ARTY groups by the keyword *everyone* or *allbatteries*. These two can be used synonymously.
-- **Note that**, if no battery is assigned nothing will happen.
--
-- * *everyone* or *allbatteries* The target is assigned to all batteries.
-- * *battery* Name of the ARTY group that the target is assigned to. Note that **the name is case sensitive** and has to be given in quotation marks. Default is all ARTY groups of the right coalition.
-- * *alias* Alias of the ARTY group that the target is assigned to. The alias is **case sensitive** and needs to be in quotation marks.
-- * *cluster* The cluster of ARTY groups that is addressed. Clusters can be defined by the function @{#ARTY.AddToCluster}(*clusters*). Names are **case sensitive** and need to be in quotation marks.
-- * *key* A number to authorize the target assignment. Only specifying the correct number will trigger an engagement.
-- * *time* Time for which which the engagement is schedules, e.g. 08:42. Default is as soon as possible.
-- * *prio*  Priority of the engagement as number between 1 (high prio) and 100 (low prio). Default is 50, i.e. medium priority.
-- * *shots* Number of shots (shells, rockets or missiles) fired at each engagement. Default is 5.
-- * *maxengage* Number of times the target is engaged. Default is 1.
-- * *radius* Scattering radius of the fired shots in meters. Default is 100 m.
-- * *weapon* Type of weapon to be used. Valid parameters are *cannon*, *rocket*, *missile*, *nuke*. Default is automatic selection.
-- * *lldms* Specify the coordinates in Lat/Long degrees, minutes and seconds format. The actual location of the marker is unimportant here. The group will engage the coordinates given in the lldms keyword.
-- Format is DD:MM:SS[N,S] DD:MM:SS[W,E]. See example below. This can be useful when coordinates in this format are obtained from elsewhere.
-- * *readonly* The marker is readonly and cannot be deleted by users. Hence, assignment cannot be cancelled by removing the marker.
--
-- Here are examples of valid marker texts:
--      arty engage, battery "Blue Paladin Alpha"
--      arty engage, everyone
--      arty engage, allbatteries
--      arty engage, alias "Bob", weapon missiles
--      arty engage, cluster "All Mortas"
--      arty engage, cluster "Northern Batteries" "Southern Batteries"
--      arty engage, cluster "Northern Batteries", cluster "Southern Batteries"
--      arty engage, cluster "Horwitzers", shots 20, prio 10, time 08:15, weapon cannons
--      arty engage, battery "Blue Paladin 1" "Blue MRLS 1", shots 10, time 10:15
--      arty engage, battery "Blue MRLS 1", key 666
--      arty engage, battery "Paladin Alpha", weapon nukes, shots 1, time 20:15
--      arty engage, battery "Horwitzer 1", lldms 41:51:00N 41:47:58E
--
-- Note that the keywords and parameters are *case insensitive*. Only exception are the battery, alias and cluster names.
-- These must be exactly the same as the names of the groups defined in the mission editor or the aliases and cluster names defined in the script.
--
-- ### Relocation Assignments
--
-- Markers can also be used to relocate the group with the keyphrase **arty move**. This is done in a similar way as assigning targets. Here, the (optional) keywords and parameters are:
--
-- * *time* Time for which which the relocation/move is schedules, e.g. 08:42. Default is as soon as possible.
-- * *speed* The speed in km/h the group will drive at. Default is 70% of its max possible speed.
-- * *on road* Group will use mainly roads. Default is off, i.e. it will go in a straight line from its current position to the assigned coordinate.
-- * *canceltarget* Group will cancel all running firing engagements and immediately start to move. Default is that group will wait until is current assignment is over.
-- * *battery* Name of the ARTY group that the relocation is assigned to.
-- * *alias* Alias of the ARTY group that the target is assigned to. The alias is **case sensitive** and needs to be in quotation marks.
-- * *cluster* The cluster of ARTY groups that is addressed. Clusters can be defined by the function @{#ARTY.AddToCluster}(*clusters*). Names are **case sensitive** and need to be in quotation marks.
-- * *key* A number to authorize the target assignment. Only specifying the correct number will trigger an engagement.
-- * *lldms* Specify the coordinates in Lat/Long degrees, minutes and seconds format. The actual location of the marker is unimportant. The group will move to the coordinates given in the lldms keyword.
-- Format is DD:MM:SS[N,S] DD:MM:SS[W,E]. See example below.
-- * *readonly* Marker cannot be deleted by users any more. Hence, assignment cannot be cancelled by removing the marker.
--
-- Here are some examples:
--      arty move, battery "Blue Paladin"
--      arty move, battery "Blue MRLS", canceltarget, speed 10, on road
--      arty move, cluster "mobile", lldms 41:51:00N 41:47:58E
--      arty move, alias "Bob", weapon missiles
--      arty move, cluster "All Howitzer"
--      arty move, cluster "Northern Batteries" "Southern Batteries"
--      arty move, cluster "Northern Batteries", cluster "Southern Batteries"
--      arty move, everyone
--
-- ### Requests
--
-- Marks can also be to send requests to the ARTY group. This is done by the keyword **arty request**, which can have the keywords
--
-- * *target* All assigned targets are reported.
-- * *move* All assigned relocation moves are reported.
-- * *ammo* Current ammunition status is reported.
--
-- For example
--      arty request, everyone, ammo
--      arty request, battery "Paladin Bravo", targets
--      arty request, cluster "All Mortars", move
--
-- The actual location of the marker is irrelevant for these requests.
--
-- ### Cancel
--
-- Current actions can be cancelled by the keyword **arty cancel**. Actions that can be cancelled are current engagements, relocations and rearming assignments.
--
-- For example
--      arty cancel, target, battery "Paladin Bravo"
--      arty cancel, everyone, move
--      arty cancel, rearming, battery "MRLS Charly"
--
-- ### Settings
--
-- A few options can be set by marks. The corresponding keyword is **arty set**. This can be used to define the rearming place and group for a battery.
--
-- To set the rearming place of a group at the marker position type
--      arty set, battery "Paladin Alpha", rearming place
--
-- Setting the rearming group is independent of the position of the mark. Just create one anywhere on the map and type
--      arty set, battery "Mortar Bravo", rearming group "Ammo Truck M818"
-- Note that the name of the rearming group has to be given in quotation marks and spelt exactly as the group name defined in the mission editor.
--
-- ## Transporting
--
-- ARTY groups can be transported to another location as @{Cargo.Cargo} by means of classes such as @{AI.AI_Cargo_APC}, @{AI.AI_Cargo_Dispatcher_APC},
-- @{AI.AI_Cargo_Helicopter}, @{AI.AI_Cargo_Dispatcher_Helicopter} or @{AI.AI_Cargo_Airplane}.
--
-- In order to do this, one needs to define an ARTY object via the @{#ARTY.NewFromCargoGroup}(*cargogroup*, *alias*) function.
-- The first argument *cargogroup* has to be a @{Cargo.CargoGroup#CARGO_GROUP} object. The second argument *alias* is a string which can be freely chosen by the user.
--
-- ## Fine Tuning
--
-- The mission designer has a few options to tailor the ARTY object according to his needs.
--
-- * @{#ARTY.SetAutoRelocateToFiringRange}(*maxdist*, *onroad*) lets the ARTY group automatically move to within firing range if a current target is outside the min/max firing range. The
-- optional parameter *maxdist* is the maximum distance im km the group will move. If the distance is greater no relocation is performed. Default is 50 km.
-- * @{#ARTY.SetAutoRelocateAfterEngagement}(*rmax*, *rmin*) will cause the ARTY group to change its position after each firing assignment.
-- Optional parameters *rmax*, *rmin* define the max/min distance for relocation of the group. Default distance is randomly between 300 and 800 m.
-- * @{#ARTY.AddToCluster}(*clusters*) Can be used to add the ARTY group to one or more clusters. All groups in a cluster can be addressed simultaniously with one marker command.
-- * @{#ARTY.SetSpeed}(*speed*) sets the speed in km/h the group moves at if not explicitly stated otherwise.
-- * @{#ARTY.RemoveAllTargets}() removes all targets from the target queue.
-- * @{#ARTY.RemoveTarget}(*name*) deletes the target with *name* from the target queue.
-- * @{#ARTY.SetMaxFiringRange}(*range*) defines the maximum firing range. Targets further away than this distance are not engaged.
-- * @{#ARTY.SetMinFiringRange}(*range*) defines the minimum firing range. Targets closer than this distance are not engaged.
-- * @{#ARTY.SetRearmingGroup}(*group*) sets the group responsible for rearming of the ARTY group once it is out of ammo.
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
-- ### Transportation as Cargo
-- This example demonstates how an ARTY group can be transported to another location as cargo.
--      -- Define a group as CARGO_GROUP
--      CargoGroupMortars=CARGO_GROUP:New(GROUP:FindByName("Mortars"), "Mortars", "Mortar Platoon Alpha", 100 , 10)
--
--      -- Define the mortar CARGO GROUP as ARTY object
--      mortars=ARTY:NewFromCargoGroup(CargoGroupMortars, "Mortar Platoon Alpha")
--
--      -- Start ARTY process
--      mortars:Start()
--
--      -- Setup AI cargo dispatcher for e.g. helos
--      SetHeloCarriers = SET_GROUP:New():FilterPrefixes("CH-47D"):FilterStart()
--      SetCargoMortars = SET_CARGO:New():FilterTypes("Mortars"):FilterStart()
--      SetZoneDepoly   = SET_ZONE:New():FilterPrefixes("Deploy"):FilterStart()
--      CargoHelo=AI_CARGO_DISPATCHER_HELICOPTER:New(SetHeloCarriers, SetCargoMortars, SetZoneDepoly)
--      CargoHelo:Start()
-- The ARTY group will be transported and resume its normal operation after it has been deployed. New targets can be assigned at any time also during the transportation process.
--
-- @field #ARTY
ARTY={
  ClassName="ARTY",
  lid=nil,
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
  Nillu0=0,
  Nsmoke0=0,
  StatusInterval=10,
  WaitForShotTime=300,
  DCSdesc=nil,
  Type=nil,
  DisplayName=nil,
  groupname=nil,
  alias=nil,
  clusters={},
  ismobile=true,
  iscargo=false,
  cargogroup=nil,
  IniGroupStrength=0,
  IsArtillery=nil,
  RearmingDistance=100,
  RearmingGroup=nil,
  RearmingGroupSpeed=nil,
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
  Nillu=nil,
  illuPower=1000000,
  illuMinalt=500,
  illuMaxalt=1000,
  Nsmoke=nil,
  smokeColor=SMOKECOLOR.Red,
  relocateafterfire=false,
  relocateRmin=300,
  relocateRmax=800,
  markallow=false,
  markkey=nil,
  markreadonly=false,
  autorelocate=false,
  autorelocatemaxdist=50000,
  autorelocateonroad=false,
  coalition=nil,
  respawnafterdeath=false,
  respawndelay=nil
}

--- Weapong type ID. See [here](http://wiki.hoggit.us/view/DCS_enum_weapon_flag).
-- @type ARTY.WeaponType
-- @field #number Auto Automatic selection of weapon type.
-- @field #number Cannon Cannons using conventional shells.
-- @field #number Rockets Unguided rockets.
-- @field #number CruiseMissile Cruise missiles.
-- @field #number TacticalNukes Tactical nuclear shells (simulated).
-- @field #number IlluminationShells Illumination shells (simulated).
-- @field #number SmokeShells Smoke shells (simulated).
ARTY.WeaponType={
  Auto=1073741822,
  Cannon=805306368,
  Rockets=30720,
  CruiseMissile=2097152,
  TacticalNukes=666,
  IlluminationShells=667,
  SmokeShells=668,
}

--- Database of common artillery unit properties.
-- @type ARTY.db
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

--- Target.
-- @type ARTY.Target
-- @field #string name Name of target.
-- @field Core.Point#COORDINATE coord Target coordinates.
-- @field #number radius Shelling radius in meters.
-- @field #number nshells Number of shells (or other weapon types) fired upon target.
-- @field #number engaged Number of times this target was engaged.
-- @field #boolean underfire If true, target is currently under fire.
-- @field #number prio Priority of target.
-- @field #number maxengage Max number of times, the target will be engaged.
-- @field #number time Abs. mission time in seconds, when the target is scheduled to be attacked.
-- @field #number weapontype Type of weapon used for engagement. See #ARTY.WeaponType.
-- @field #number Tassigned Abs. mission time when target was assigned.
-- @field #boolean attackgroup If true, use task attack group rather than fire at point for engagement.

--- Arty script version.
-- @field #string version
ARTY.version="1.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- TODO: Add hit event and make the arty group relocate.
-- TODO: Handle rearming for ships. How?
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
-- DONE: Add pseudo user transitions. OnAfter...
-- DONE: Make reaming unit a group.
-- DONE: Write documenation.
-- DONE: Add command move to make arty group move.
-- DONE: remove schedulers for status event.
-- DONE: Improve handling of special weapons. When winchester if using selected weapons?
-- DONE: Make coordinate after rearming general, i.e. also work after the group has moved to anonther location.
-- DONE: Add set commands via markers. E.g. set rearming place.
-- DONE: Test stationary types like mortas ==> rearming etc.
-- DONE: Add illumination and smoke.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new ARTY object from a MOOSE group object.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group The GROUP object for which artillery tasks should be assigned.
-- @param alias (Optional) Alias name the group will be calling itself when sending messages. Default is the group name.
-- @return #ARTY ARTY object or nil if group does not exist or is not a ground or naval group.
function ARTY:New(group, alias)

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #ARTY
  
  -- If group name was given.
  if type(group)=="string" then
    self.groupname=group
    group=GROUP:FindByName(group)
    if not group then
      self:E(string.format("ERROR: Requested ARTY group %s does not exist! (Has to be a MOOSE group.)", self.groupname))
      return nil      
    end
  end

  -- Check that group is present.
  if group then
    self:T(string.format("ARTY script version %s. Added group %s.", ARTY.version, group:GetName()))
  else
    self:E("ERROR: Requested ARTY group does not exist! (Has to be a MOOSE group.)")
    return nil
  end

  -- Check that we actually have a GROUND group.
  if not (group:IsGround() or group:IsShip()) then
    self:E(string.format("ERROR: ARTY group %s has to be a GROUND or SHIP group!", group:GetName()))
    return nil
  end

  -- Set the controllable for the FSM.
  self:SetControllable(group)

  -- Set the group name
  self.groupname=group:GetName()

  -- Get coalition.
  self.coalition=group:GetCoalition()

  -- Set an alias name.
  if alias~=nil then
    self.alias=tostring(alias)
  else
    self.alias=self.groupname
  end

  -- Log id.
  self.lid=string.format("ARTY %s | ", self.alias)

  -- Set the initial coordinates of the ARTY group.
  self.InitialCoord=group:GetCoordinate()

  -- Get DCS descriptors of group.
  local DCSgroup=Group.getByName(group:GetName())
  local DCSunit=DCSgroup:getUnit(1)
  self.DCSdesc=DCSunit:getDesc()

  -- DCS descriptors.
  self:T3(self.lid.."DCS descriptors for group "..group:GetName())
  for id,desc in pairs(self.DCSdesc) do
    self:T3({id=id, desc=desc})
  end

  -- Maximum speed in km/h.
  self.SpeedMax=group:GetSpeedMax()

  -- Group is mobile or not (e.g. mortars).
  if self.SpeedMax>1 then
    self.ismobile=true
  else
    self.ismobile=false
  end
  
  -- Set track time interval.
  self.dtTrack=0.2

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
  self:AddTransition("*",           "Respawn",     "CombatReady")

  -- Transport as cargo (not in diagram).
  self:AddTransition("*",           "Loaded",      "InTransit")
  self:AddTransition("InTransit",   "UnLoaded",    "CombatReady")

  -- Unknown transitons. To be checked if adding these causes problems.
  self:AddTransition("Rearming",    "Arrived",     "Rearming")
  self:AddTransition("Rearming",    "Move",        "Rearming")


  --- User function for OnAfter "NewTarget" event.
  -- @function [parent=#ARTY] OnAfterNewTarget
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table target Array holding the target info.

  --- User function for OnAfter "OpenFire" event.
  -- @function [parent=#ARTY] OnAfterOpenFire
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table target Array holding the target info.

  --- User function for OnAfter "CeaseFire" event.
  -- @function [parent=#ARTY] OnAfterCeaseFire
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table target Array holding the target info.

  --- User function for OnAfer "NewMove" event.
  -- @function [parent=#ARTY] OnAfterNewMove
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table move Array holding the move info.

  --- User function for OnAfer "Move" event.
  -- @function [parent=#ARTY] OnAfterMove
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table move Array holding the move info.

  --- User function for OnAfer "Arrived" event.
  -- @function [parent=#ARTY] OnAfterArrvied
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnAfter "Winchester" event.
  -- @function [parent=#ARTY] OnAfterWinchester
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnAfter "Rearm" event.
  -- @function [parent=#ARTY] OnAfterRearm
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnAfter "Rearmed" event.
  -- @function [parent=#ARTY] OnAfterRearmed
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnAfter "Start" event.
  -- @function [parent=#ARTY] OnAfterStart
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnAfter "Status" event.
  -- @function [parent=#ARTY] OnAfterStatus
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnAfter "Dead" event.
  -- @function [parent=#ARTY] OnAfterDead
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Unitname Name of the dead unit.

  --- User function for OnAfter "Respawn" event.
  -- @function [parent=#ARTY] OnAfterRespawn
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnEnter "CombatReady" state.
  -- @function [parent=#ARTY] OnEnterCombatReady
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnEnter "Firing" state.
  -- @function [parent=#ARTY] OnEnterFiring
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnEnter "OutOfAmmo" state.
  -- @function [parent=#ARTY] OnEnterOutOfAmmo
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnEnter "Rearming" state.
  -- @function [parent=#ARTY] OnEnterRearming
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnEnter "Rearmed" state.
  -- @function [parent=#ARTY] OnEnterRearmed
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- User function for OnEnter "Moving" state.
  -- @function [parent=#ARTY] OnEnterMoving
  -- @param #ARTY self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Function to start the ARTY FSM process.
  -- @function [parent=#ARTY] Start
  -- @param #ARTY self

  --- Function to start the ARTY FSM process after a delay.
  -- @function [parent=#ARTY] __Start
  -- @param #ARTY self
  -- @param #number Delay before start in seconds.

  --- Function to update the status of the ARTY group and tigger FSM events. Triggers the FSM event "Status".
  -- @function [parent=#ARTY] Status
  -- @param #ARTY self

  --- Function to update the status of the ARTY group and tigger FSM events after a delay. Triggers the FSM event "Status".
  -- @function [parent=#ARTY] __Status
  -- @param #ARTY self
  -- @param #number Delay in seconds.

  --- Function called when a unit of the ARTY group died. Triggers the FSM event "Dead".
  -- @function [parent=#ARTY] Dead
  -- @param #ARTY self
  -- @param #string unitname Name of the unit that died.

  --- Function called when a unit of the ARTY group died after a delay. Triggers the FSM event "Dead".
  -- @function [parent=#ARTY] __Dead
  -- @param #ARTY self
  -- @param #number Delay in seconds.
  -- @param #string unitname Name of the unit that died.

  --- Add a new target for the ARTY group. Triggers the FSM event "NewTarget".
  -- @function [parent=#ARTY] NewTarget
  -- @param #ARTY self
  -- @param #table target Array holding the target data.

  --- Add a new target for the ARTY group with a delay. Triggers the FSM event "NewTarget".
  -- @function [parent=#ARTY] __NewTarget
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.
  -- @param #table target Array holding the target data.

  --- Add a new relocation move for the ARTY group. Triggers the FSM event "NewMove".
  -- @function [parent=#ARTY] NewMove
  -- @param #ARTY self
  -- @param #table move Array holding the relocation move data.

  --- Add a new relocation for the ARTY group after a delay. Triggers the FSM event "NewMove".
  -- @function [parent=#ARTY] __NewMove
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.
  -- @param #table move Array holding the relocation move data.

  --- Order ARTY group to open fire on a target. Triggers the FSM event "OpenFire".
  -- @function [parent=#ARTY] OpenFire
  -- @param #ARTY self
  -- @param #table target Array holding the target data.

  --- Order ARTY group to open fire on a target with a delay. Triggers the FSM event "Move".
  -- @function [parent=#ARTY] __OpenFire
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.
  -- @param #table target Array holding the target data.

  --- Order ARTY group to cease firing on a target. Triggers the FSM event "CeaseFire".
  -- @function [parent=#ARTY] CeaseFire
  -- @param #ARTY self
  -- @param #table target Array holding the target data.

  --- Order ARTY group to cease firing on a target after a delay. Triggers the FSM event "CeaseFire".
  -- @function [parent=#ARTY] __CeaseFire
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.
  -- @param #table target Array holding the target data.

  --- Order ARTY group to move to another location. Triggers the FSM event "Move".
  -- @function [parent=#ARTY] Move
  -- @param #ARTY self
  -- @param #table move Array holding the relocation move data.

  --- Order ARTY group to move to another location after a delay. Triggers the FSM event "Move".
  -- @function [parent=#ARTY] __Move
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.
  -- @param #table move Array holding the relocation move data.

  --- Tell ARTY group it has arrived at its destination. Triggers the FSM event "Arrived".
  -- @function [parent=#ARTY] Arrived
  -- @param #ARTY self

  --- Tell ARTY group it has arrived at its destination after a delay. Triggers the FSM event "Arrived".
  -- @function [parent=#ARTY] __Arrived
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.

  --- Tell ARTY group it is combat ready. Triggers the FSM event "CombatReady".
  -- @function [parent=#ARTY] CombatReady
  -- @param #ARTY self

  --- Tell ARTY group it is combat ready after a delay. Triggers the FSM event "CombatReady".
  -- @function [parent=#ARTY] __CombatReady
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.

  --- Tell ARTY group it is out of ammo. Triggers the FSM event "Winchester".
  -- @function [parent=#ARTY] Winchester
  -- @param #ARTY self

  --- Tell ARTY group it is out of ammo after a delay. Triggers the FSM event "Winchester".
  -- @function [parent=#ARTY] __Winchester
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.

  --- Respawn ARTY group.
  -- @function [parent=#ARTY] Respawn
  -- @param #ARTY self

  --- Respawn ARTY group after a delay.
  -- @function [parent=#ARTY] __Respawn
  -- @param #ARTY self
  -- @param #number delay Delay in seconds.

  return self
end

--- Creates a new ARTY object from a MOOSE CARGO_GROUP object.
-- @param #ARTY self
-- @param Cargo.CargoGroup#CARGO_GROUP cargogroup The CARGO GROUP object for which artillery tasks should be assigned.
-- @param alias (Optional) Alias name the group will be calling itself when sending messages. Default is the group name.
-- @return #ARTY ARTY object or nil if group does not exist or is not a ground or naval group.
function ARTY:NewFromCargoGroup(cargogroup, alias)

  if cargogroup then
    BASE:T(string.format("ARTY script version %s. Added CARGO group %s.", ARTY.version, cargogroup:GetName()))
  else
    BASE:E("ERROR: Requested ARTY CARGO GROUP does not exist! (Has to be a MOOSE CARGO(!) group.)")
    return nil
  end

  -- Get group belonging to the cargo group.
  local group=cargogroup:GetObject()

  -- Create ARTY object.
  local arty=ARTY:New(group,alias)

  -- Set iscargo flag.
  arty.iscargo=true

  -- Set cargo group object.
  arty.cargogroup=cargogroup

  return arty
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
    self:E(self.lid..text)
    return nil
  end
  if text~=nil then
    self:E(self.lid..text)
  end

  -- Name of the target.
  local _name=name or coord:ToStringLLDMS()
  local _unique=true

  -- Check if the name has already been used for another target. If so, the function returns a new unique name.
  _name,_unique=self:_CheckName(self.targets, _name, not unique)

  -- Target name should be unique and is not.
  if unique==true and _unique==false then
    self:T(self.lid..string.format("%s: target %s should have a unique name but name was already given. Rejecting target!", self.groupname, _name))
    return nil
  end

  -- Time in seconds.
  local _time
  if type(time)=="string" then
    _time=self:_ClockToSeconds(time)
  elseif type(time)=="number" then
    _time=timer.getAbsTime()+time
  else
    _time=timer.getAbsTime()
  end

  -- Prepare target array.
  local _target={name=_name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false, prio=prio, maxengage=maxengage, time=_time, weapontype=weapontype}

  -- Add to table.
  table.insert(self.targets, _target)

  -- Trigger new target event.
  self:__NewTarget(1, _target)

  return _name
end

--- Assign a target group to the ARTY group. Note that this will use the Attack Group Task rather than the Fire At Point Task.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Target group.
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
function ARTY:AssignAttackGroup(group, prio, radius, nshells, maxengage, time, weapontype, name, unique)

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

  -- TODO Check if we have a group object.
  if type(group)=="string" then
    group=GROUP:FindByName(group)
  end

  if group and group:IsAlive() then

    local coord=group:GetCoordinate()

    -- Name of the target.
    local _name=group:GetName()
    local _unique=true

    -- Check if the name has already been used for another target. If so, the function returns a new unique name.
    _name,_unique=self:_CheckName(self.targets, _name, not unique)

    -- Target name should be unique and is not.
    if unique==true and _unique==false then
      self:T(self.lid..string.format("%s: target %s should have a unique name but name was already given. Rejecting target!", self.groupname, _name))
      return nil
    end

    -- Time in seconds.
    local _time
    if type(time)=="string" then
      _time=self:_ClockToSeconds(time)
    elseif type(time)=="number" then
      _time=timer.getAbsTime()+time
    else
      _time=timer.getAbsTime()
    end

    -- Prepare target array.
    local target={} --#ARTY.Target
    target.attackgroup=true
    target.name=_name
    target.coord=coord
    target.radius=radius
    target.nshells=nshells
    target.engaged=0
    target.underfire=false
    target.prio=prio
    target.time=_time
    target.maxengage=maxengage
    target.weapontype=weapontype

    -- Add to table.
    table.insert(self.targets, target)

    -- Trigger new target event.
    self:__NewTarget(1, target)

    return _name
  else
    self:E("ERROR: Group does not exist!")
  end

  return nil
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

  -- Reject move if the group is immobile.
  if not self.ismobile then
    self:T(self.lid..string.format("%s: group is immobile. Rejecting move request!", self.groupname))
    return nil
  end

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
    self:T(self.lid..string.format("%s: move %s should have a unique name but name was already given. Rejecting move!", self.groupname, _name))
    return nil
  end

  -- Set speed.
  if speed then
    -- Make sure, given speed is less than max physiaclly possible speed of group.
    speed=math.min(speed, self.SpeedMax)
  elseif self.Speed then
    speed=self.Speed
  else
    speed=self.SpeedMax*0.7
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
  local _time
  if type(time)=="string" then
    _time=self:_ClockToSeconds(time)
  elseif type(time)=="number" then
    _time=timer.getAbsTime()+time
  else
    _time=timer.getAbsTime()
  end

  -- Prepare move array.
  local _move={name=_name, coord=coord, time=_time, speed=speed, onroad=onroad, cancel=cancel}

  -- Add to table.
  table.insert(self.moves, _move)

  return _name
end

--- Set alias, i.e. the name the group will use when sending messages.
-- @param #ARTY self
-- @param #string alias The alias for the group.
-- @return self
function ARTY:SetAlias(alias)
  self:F({alias=alias})
  self.alias=tostring(alias)
  return self
end

--- Add ARTY group to one or more clusters. Enables addressing all ARTY groups within a cluster simultaniously via marker assignments.
-- @param #ARTY self
-- @param #table clusters Table of cluster names the group should belong to.
-- @return self
function ARTY:AddToCluster(clusters)
  self:F({clusters=clusters})

  -- Convert input to table.
  local names
  if type(clusters)=="table" then
    names=clusters
  elseif type(clusters)=="string" then
    names={clusters}
  else
    -- error message
    self:E(self.lid.."ERROR: Input parameter must be a string or a table in ARTY:AddToCluster()!")
    return
  end

  -- Add names to cluster array.
  for _,cluster in pairs(names) do
    table.insert(self.clusters, cluster)
  end

  return self
end

--- Set minimum firing range. Targets closer than this distance are not engaged.
-- @param #ARTY self
-- @param #number range Min range in kilometers. Default is 0.1 km.
-- @return self
function ARTY:SetMinFiringRange(range)
  self:F({range=range})
  self.minrange=range*1000 or 100
  return self
end

--- Set maximum firing range. Targets further away than this distance are not engaged.
-- @param #ARTY self
-- @param #number range Max range in kilometers. Default is 1000 km.
-- @return self
function ARTY:SetMaxFiringRange(range)
  self:F({range=range})
  self.maxrange=range*1000 or 1000*1000
  return self
end

--- Set time interval between status updates. During the status check, new events are triggered.
-- @param #ARTY self
-- @param #number interval Time interval in seconds. Default 10 seconds.
-- @return self
function ARTY:SetStatusInterval(interval)
  self:F({interval=interval})
  self.StatusInterval=interval or 10
  return self
end

--- Set time interval for weapon tracking.
-- @param #ARTY self
-- @param #number interval Time interval in seconds. Default 0.2 seconds.
-- @return self
function ARTY:SetTrackInterval(interval)
  self.dtTrack=interval or 0.2
  return self
end

--- Set time how it is waited a unit the first shot event happens. If no shot is fired after this time, the task to fire is aborted and the target removed.
-- @param #ARTY self
-- @param #number waittime Time in seconds. Default 300 seconds.
-- @return self
function ARTY:SetWaitForShotTime(waittime)
  self:F({waittime=waittime})
  self.WaitForShotTime=waittime or 300
  return self
end

--- Define the safe distance between ARTY group and rearming unit or rearming place at which rearming process is possible.
-- @param #ARTY self
-- @param #number distance Safe distance in meters. Default is 100 m.
-- @return self
function ARTY:SetRearmingDistance(distance)
  self:F({distance=distance})
  self.RearmingDistance=distance or 100
  return self
end

--- Assign a group, which is responsible for rearming the ARTY group. If the group is too far away from the ARTY group it will be guided towards the ARTY group.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group that is supposed to rearm the ARTY group. For the blue coalition, this is often a unarmed M818 transport whilst for red an unarmed Ural-375 transport can be used.
-- @return self
function ARTY:SetRearmingGroup(group)
  self:F({group=group})
  self.RearmingGroup=group
  return self
end

--- Set the speed the rearming group moves at towards the ARTY group or the rearming place.
-- @param #ARTY self
-- @param #number speed Speed in km/h.
-- @return self
function ARTY:SetRearmingGroupSpeed(speed)
  self:F({speed=speed})
  self.RearmingGroupSpeed=speed
  return self
end

--- Define if rearming group uses mainly roads to drive to the ARTY group or rearming place.
-- @param #ARTY self
-- @param #boolean onroad If true, rearming group uses mainly roads. If false, it drives directly to the ARTY group or rearming place.
-- @return self
function ARTY:SetRearmingGroupOnRoad(onroad)
  self:F({onroad=onroad})
  if onroad==nil then
    onroad=true
  end
  self.RearmingGroupOnRoad=onroad
  return self
end

--- Define if ARTY group uses mainly roads to drive to the rearming place.
-- @param #ARTY self
-- @param #boolean onroad If true, ARTY group uses mainly roads. If false, it drives directly to the rearming place.
-- @return self
function ARTY:SetRearmingArtyOnRoad(onroad)
  self:F({onroad=onroad})
  if onroad==nil then
    onroad=true
  end
  self.RearmingArtyOnRoad=onroad
  return self
end

--- Defines the rearming place of the ARTY group. If the place is too far away from the ARTY group it will be routed to the place.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates of the rearming place.
-- @return self
function ARTY:SetRearmingPlace(coord)
  self:F({coord=coord})
  self.RearmingPlaceCoord=coord
  return self
end

--- Set automatic relocation of ARTY group if a target is assigned which is out of range. The unit will drive automatically towards or away from the target to be in max/min firing range.
-- @param #ARTY self
-- @param #number maxdistance (Optional) The maximum distance in km the group will travel to get within firing range. Default is 50 km. No automatic relocation is performed if targets are assigned which are further away.
-- @param #boolean onroad (Optional) If true, ARTY group uses roads whenever possible. Default false, i.e. group will move in a straight line to the assigned coordinate.
-- @return self
function ARTY:SetAutoRelocateToFiringRange(maxdistance, onroad)
  self:F({distance=maxdistance, onroad=onroad})
  self.autorelocate=true
  self.autorelocatemaxdist=maxdistance or 50
  self.autorelocatemaxdist=self.autorelocatemaxdist*1000
  if onroad==nil then
    onroad=false
  end
  self.autorelocateonroad=onroad
  return self
end

--- Set relocate after firing. Group will find a new location after each engagement. Default is off
-- @param #ARTY self
-- @param #number rmax (Optional) Max distance in meters, the group will move to relocate. Default is 800 m.
-- @param #number rmin (Optional) Min distance in meters, the group will move to relocate. Default is 300 m.
-- @return self
function ARTY:SetAutoRelocateAfterEngagement(rmax, rmin)
  self.relocateafterfire=true
  self.relocateRmax=rmax or 800
  self.relocateRmin=rmin or 300

  -- Ensure that Rmin<=Rmax
  self.relocateRmin=math.min(self.relocateRmin, self.relocateRmax)

  return self
end

--- Report messages of ARTY group turned on. This is the default.
-- @param #ARTY self
-- @return self
function ARTY:SetReportON()
  self.report=true
  return self
end

--- Report messages of ARTY group turned off. Default is on.
-- @param #ARTY self
-- @return self
function ARTY:SetReportOFF()
  self.report=false
  return self
end

--- Respawn group once all units are dead.
-- @param #ARTY self
-- @param #number delay (Optional) Delay before respawn in seconds.
-- @return self
function ARTY:SetRespawnOnDeath(delay)
  self.respawnafterdeath=true
  self.respawndelay=delay
  return self
end

--- Turn debug mode on. Information is printed to screen.
-- @param #ARTY self
-- @return self
function ARTY:SetDebugON()
  self.Debug=true
  return self
end

--- Turn debug mode off. This is the default setting.
-- @param #ARTY self
-- @return self
function ARTY:SetDebugOFF()
  self.Debug=false
  return self
end

--- Set default speed the group is moving at if not specified otherwise.
-- @param #ARTY self
-- @param #number speed Speed in km/h.
-- @return self
function ARTY:SetSpeed(speed)
  self.Speed=speed
  return self
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
    self:T(self.lid..string.format("Group %s: Removing target %s (id=%d).", self.groupname, name, id))
    table.remove(self.targets, id)

    -- Delete marker belonging to this engagement.
    if self.markallow then
      local batteryname,markTargetID, markMoveID=self:_GetMarkIDfromName(name)
      if batteryname==self.groupname and markTargetID~=nil then
        COORDINATE:RemoveMark(markTargetID)
      end
    end

  end
  self:T(self.lid..string.format("Group %s: Number of targets = %d.", self.groupname, #self.targets))
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
    self:T(self.lid..string.format("Group %s: Removing move %s (id=%d).", self.groupname, name, id))
    table.remove(self.moves, id)

    -- Delete marker belonging to this relocation move.
    if self.markallow then
      local batteryname,markTargetID,markMoveID=self:_GetMarkIDfromName(name)
      if batteryname==self.groupname and markMoveID~=nil then
        COORDINATE:RemoveMark(markMoveID)
      end
    end

  end
  self:T(self.lid..string.format("Group %s: Number of moves = %d.", self.groupname, #self.moves))
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
-- @return self
function ARTY:SetShellTypes(tableofnames)
  self:F2(tableofnames)
  self.ammoshells={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammoshells, _type)
  end
  return self
end

--- Define rocket types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of rocket type names.
-- @return self
function ARTY:SetRocketTypes(tableofnames)
  self:F2(tableofnames)
  self.ammorockets={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammorockets, _type)
  end
  return self
end

--- Define missile types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of rocket type names.
-- @return self
function ARTY:SetMissileTypes(tableofnames)
  self:F2(tableofnames)
  self.ammomissiles={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammomissiles, _type)
  end
  return self
end

--- Set number of tactical nuclear warheads available to the group.
-- Note that it can be max the number of normal shells. Also if all normal shells are empty, firing nuclear shells is also not possible any more until group gets rearmed.
-- @param #ARTY self
-- @param #number n Number of warheads for the whole group.
-- @return self
function ARTY:SetTacNukeShells(n)
  self.Nukes=n
  return self
end

--- Set nuclear warhead explosion strength.
-- @param #ARTY self
-- @param #number strength Explosion strength in kilo tons TNT. Default is 0.075 kt.
-- @return self
function ARTY:SetTacNukeWarhead(strength)
  self.nukewarhead=strength or 0.075
  self.nukewarhead=self.nukewarhead*1000*1000 -- convert to kg TNT.
  return self
end

--- Set number of illumination shells available to the group.
-- Note that it can be max the number of normal shells. Also if all normal shells are empty, firing illumination shells is also not possible any more until group gets rearmed.
-- @param #ARTY self
-- @param #number n Number of illumination shells for the whole group.
-- @param #number power (Optional) Power of illumination warhead in mega candela. Default 1.0 mcd.
-- @return self
function ARTY:SetIlluminationShells(n, power)
  self.Nillu=n
  self.illuPower=power or 1.0
  self.illuPower=self.illuPower * 1000000
  return self
end

--- Set minimum and maximum detotation altitude for illumination shells. A value between min/max is selected randomly.
-- The illumination bomb will burn for 300 seconds (5 minutes). Assuming a descent rate of ~3 m/s the "optimal" altitude would be 900 m.
-- @param #ARTY self
-- @param #number minalt (Optional) Minium altitude in meters. Default 500 m.
-- @param #number maxalt (Optional) Maximum altitude in meters. Default 1000 m.
-- @return self
function ARTY:SetIlluminationMinMaxAlt(minalt, maxalt)
  self.illuMinalt=minalt or 500
  self.illuMaxalt=maxalt or 1000

  if self.illuMinalt>self.illuMaxalt then
    self.illuMinalt=self.illuMaxalt
  end
  return self
end

--- Set number of smoke shells available to the group.
-- Note that it can be max the number of normal shells. Also if all normal shells are empty, firing smoke shells is also not possible any more until group gets rearmed.
-- @param #ARTY self
-- @param #number n Number of smoke shells for the whole group.
-- @param Utilities.Utils#SMOKECOLOR color (Optional) Color of the smoke. Default SMOKECOLOR.Red.
-- @return self
function ARTY:SetSmokeShells(n, color)
  self.Nsmoke=n
  self.smokeColor=color or SMOKECOLOR.Red
  return self
end

--- Set nuclear fires and extra demolition explosions.
-- @param #ARTY self
-- @param #number nfires (Optional) Number of big smoke and fire objects created in the demolition zone.
-- @param #number demolitionrange (Optional) Demolition range in meters.
-- @return self
function ARTY:SetTacNukeFires(nfires, range)
  self.nukefire=true
  self.nukefires=nfires
  self.nukerange=range
  return self
end

--- Enable assigning targets and moves by placing markers on the F10 map.
-- @param #ARTY self
-- @param #number key (Optional) Authorization key. Only players knowing this key can assign targets. Default is no authorization required.
-- @param #boolean readonly (Optional) Marks are readonly and cannot be removed by players. This also means that targets cannot be cancelled by removing the mark. Default false.
-- @return self
function ARTY:SetMarkAssignmentsOn(key, readonly)
  self.markkey=key
  self.markallow=true
  if readonly==nil then
    self.markreadonly=false
  end
  return self
end

--- Disable assigning targets by placing markers on the F10 map.
-- @param #ARTY self
-- @return self
function ARTY:SetMarkTargetsOff()
  self.markallow=false
  self.markkey=nil
  return self
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
  self:I(self.lid..text)
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

  -- Init nuclear shells.
  if self.Nukes~=nil then
    self.Nukes0=math.min(self.Nukes, self.Nshells0)
  else
    self.Nukes=0
    self.Nukes0=0
  end

  -- Init illumination shells.
  if self.Nillu~=nil then
    self.Nillu0=math.min(self.Nillu, self.Nshells0)
  else
    self.Nillu=0
    self.Nillu0=0
  end

  -- Init smoke shells.
  if self.Nsmoke~=nil then
    self.Nsmoke0=math.min(self.Nsmoke, self.Nshells0)
  else
    self.Nsmoke=0
    self.Nsmoke0=0
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

  -- Some mobility consitency checks if group cannot move.
  if not self.ismobile then
    self.RearmingPlaceCoord=nil
    self.relocateafterfire=false
    self.autorelocate=false
    --self.RearmingGroupSpeed=20
  end

  -- Check that default speed is below max speed.
  self.Speed=math.min(self.Speed, self.SpeedMax)

  -- Set Rearming group speed if not specified by user
  if self.RearmingGroup then

    -- Get max speed of rearming group.
    local speedmax=self.RearmingGroup:GetSpeedMax()
    self:T(self.lid..string.format("%s, rearming group %s max speed = %.1f km/h.", self.groupname, self.RearmingGroup:GetName(), speedmax))

    if self.RearmingGroupSpeed==nil then
      -- Set rearming group speed to 50% of max possible speed.
      self.RearmingGroupSpeed=speedmax*0.5
    else
      -- Ensure that speed is <= max speed.
      self.RearmingGroupSpeed=math.min(self.RearmingGroupSpeed, self.RearmingGroup:GetSpeedMax())
    end
  else
    -- Just to have a reasonable number for output format below.
    self.RearmingGroupSpeed=23
  end

  local text=string.format("\n******************************************************\n")
  text=text..string.format("Arty group          = %s\n", self.groupname)
  text=text..string.format("Arty alias          = %s\n", self.alias)
  text=text..string.format("Artillery attribute = %s\n", tostring(self.IsArtillery))
  text=text..string.format("Type                = %s\n", self.Type)
  text=text..string.format("Display Name        = %s\n", self.DisplayName)
  text=text..string.format("Number of units     = %d\n", self.IniGroupStrength)
  text=text..string.format("Speed max           = %d km/h\n", self.SpeedMax)
  text=text..string.format("Speed default       = %d km/h\n", self.Speed)
  text=text..string.format("Is mobile           = %s\n", tostring(self.ismobile))
  text=text..string.format("Is cargo            = %s\n", tostring(self.iscargo))
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
  text=text..string.format("Number of illum.    = %d\n", self.Nillu0)
  text=text..string.format("Illuminaton Power   = %.3f mcd\n", self.illuPower/1000000)
  text=text..string.format("Illuminaton Minalt  = %d m\n", self.illuMinalt)
  text=text..string.format("Illuminaton Maxalt  = %d m\n", self.illuMaxalt)
  text=text..string.format("Number of smoke     = %d\n", self.Nsmoke0)
  text=text..string.format("Smoke color         = %d\n", self.smokeColor)
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
  text=text..string.format("Auto move in range  = %s\n", tostring(self.autorelocate))
  text=text..string.format("Auto move dist. max = %.1f km\n", self.autorelocatemaxdist/1000)
  text=text..string.format("Auto move on road   = %s\n", tostring(self.autorelocateonroad))
  text=text..string.format("Marker assignments  = %s\n", tostring(self.markallow))
  text=text..string.format("Marker auth. key    = %s\n", tostring(self.markkey))
  text=text..string.format("Marker readonly     = %s\n", tostring(self.markreadonly))
  text=text..string.format("Clusters:\n")
  for _,cluster in pairs(self.clusters) do
    text=text..string.format("- %s\n", tostring(cluster))
  end
  text=text..string.format("******************************************************\n")
  text=text..string.format("Targets:\n")
  for _, target in pairs(self.targets) do
    text=text..string.format("- %s\n", self:_TargetInfo(target))
    local possible=self:_CheckWeaponTypePossible(target)
    if not possible then
      self:E(self.lid..string.format("WARNING: Selected weapon type %s is not possible", self:_WeaponTypeName(target.weapontype)))
    end
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
    self:I(self.lid..text)
  else
    self:T(self.lid..text)
  end

  -- Set default ROE to weapon hold.
  self.Controllable:OptionROEHoldFire()

  -- Add event handler.
  self:HandleEvent(EVENTS.Shot) --, self._OnEventShot)
  self:HandleEvent(EVENTS.Dead) --, self._OnEventDead)
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
  local Nillu=self.Nillu
  local Nsmoke=self.Nsmoke

  local Tnow=timer.getTime()
  local Clock=self:_SecondsToClock(timer.getAbsTime())

  local text=string.format("\n******************* STATUS ***************************\n")
  text=text..string.format("ARTY group          = %s\n", self.groupname)
  text=text..string.format("Clock               = %s\n", Clock)
  text=text..string.format("FSM state           = %s\n", self:GetState())
  text=text..string.format("Total ammo count    = %d\n", Nammo)
  text=text..string.format("Number of shells    = %d\n", Nshells)
  text=text..string.format("Number of rockets   = %d\n", Nrockets)
  text=text..string.format("Number of missiles  = %d\n", Nmissiles)
  text=text..string.format("Number of nukes     = %d\n", Nnukes)
  text=text..string.format("Number of illum.    = %d\n", Nillu)
  text=text..string.format("Number of smoke     = %d\n", Nsmoke)
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
  env.info(self.lid..text)
  MESSAGE:New(text, 20):Clear():ToCoalitionIf(self.coalition, display)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Handling
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called during tracking of weapon.
-- @param Wrapper.Weapon#WEAPON weapon Weapon object.
-- @param #ARTY self ARTY object.
-- @param #ARTY.Target target Target of the weapon.
function ARTY._FuncTrack(weapon, self, target)
  
  -- Coordinate and distance to target.
  local _coord=weapon.coordinate
  local _dist=_coord:Get2DDistance(target.coord)
  local _destroyweapon=false
  
  -- Debug
  self:T3(self.lid..string.format("ARTY %s weapon to target dist = %d m", self.groupname,_dist))
  
  if target.weapontype==ARTY.WeaponType.IlluminationShells then
  
    -- Check if within distace.
    if _dist<target.radius then
  
      -- Get random coordinate within certain radius of the target.
      local _cr=target.coord:GetRandomCoordinateInRadius(target.radius)
  
      -- Get random altitude over target.
      local _alt=_cr:GetLandHeight()+math.random(self.illuMinalt, self.illuMaxalt)
  
      -- Adjust explosion height of coordinate.
      local _ci=COORDINATE:New(_cr.x,_alt,_cr.z)
  
      -- Create illumination flare.
      _ci:IlluminationBomb(self.illuPower)
  
      -- Destroy actual shell.
      _destroyweapon=true
    end
  
  elseif target.weapontype==ARTY.WeaponType.SmokeShells then
  
    if _dist<target.radius then
  
      -- Get random coordinate within a certain radius.
      local _cr=_coord:GetRandomCoordinateInRadius(_data.target.radius)
  
      -- Fire smoke at this coordinate.
      _cr:Smoke(self.smokeColor)
  
      -- Destroy actual shell.
      _destroyweapon=true
  
    end
  
  end
  
  if _destroyweapon then
  
    self:T2(self.lid..string.format("ARTY %s destroying shell, stopping timer.", self.groupname))
  
    -- Destroy weapon and stop timer.
    weapon:Destroy()
    
    -- No more tracking.
    weapon.tracking=false

  end

end


--- Function called after impact of weapon.
-- @param Wrapper.Weapon#WEAPON weapon Weapon object.
-- @param #ARTY self ARTY object.
-- @param #ARTY.Target target Target of the weapon.
function ARTY._FuncImpact(weapon, self, target)

  -- Debug info.
  self:I(self.lid..string.format("ARTY %s weapon NOT ALIVE any more.", self.groupname))

  -- Get impact coordinate.
  local _impactcoord=weapon:GetImpactCoordinate()
    
  -- Create a "nuclear" explosion and blast at the impact point.
  if target.weapontype==ARTY.WeaponType.TacticalNukes then
    self:T(self.lid..string.format("ARTY %s triggering nuclear explosion in one second.", self.groupname))
    --SCHEDULER:New(nil, ARTY._NuclearBlast, {self,_impactcoord}, 1.0)
    self:ScheduleOnce(1.0, ARTY._NuclearBlast, self, _impactcoord)
  end

end


--- Eventhandler for shot event.
-- @param #ARTY self
-- @param Core.Event#EVENTDATA EventData
function ARTY:OnEventShot(EventData)
  self:F(EventData)

    -- Weapon data.
  local _weapon = EventData.Weapon:getTypeName()  -- should be the same as Event.WeaponTypeName
  local _weaponStrArray = self:_split(_weapon,"%.")
  local _weaponName = _weaponStrArray[#_weaponStrArray]

  -- Debug info.
  self:T3(self.lid.."EVENT SHOT: Ini unit    = "..EventData.IniUnitName)
  self:T3(self.lid.."EVENT SHOT: Ini group   = "..EventData.IniGroupName)
  self:T3(self.lid.."EVENT SHOT: Weapon type = ".._weapon)
  self:T3(self.lid.."EVENT SHOT: Weapon name = ".._weaponName)

  local group = EventData.IniGroup --Wrapper.Group#GROUP

  if group and group:IsAlive() then

    if EventData.IniGroupName == self.groupname then

      if self.currentTarget then

        -- Increase number of shots fired by this group on this target.
        self.Nshots=self.Nshots+1

        -- Debug output.
        local text=string.format("%s, fired shot %d of %d with weapon %s on target %s.", self.alias, self.Nshots, self.currentTarget.nshells, _weaponName, self.currentTarget.name)
        self:T(self.lid..text)
        MESSAGE:New(text, 5):Clear():ToAllIf(self.report or self.Debug)

        -- Start track the shell if we want to model a tactical nuke.
        local _tracknuke  = self.currentTarget.weapontype==ARTY.WeaponType.TacticalNukes and self.Nukes>0
        local _trackillu  = self.currentTarget.weapontype==ARTY.WeaponType.IlluminationShells and self.Nillu>0
        local _tracksmoke = self.currentTarget.weapontype==ARTY.WeaponType.SmokeShells and self.Nsmoke>0
        
        
        if _tracknuke or _trackillu or _tracksmoke then

          -- Debug info.  
          self:T(self.lid..string.format("ARTY %s: Tracking of weapon starts in two seconds.", self.groupname))
            
          -- Create a weapon object.
          local weapon=WEAPON:New(EventData.weapon)
          
          -- Set time step for tracking.
          weapon:SetTimeStepTrack(self.dtTrack)
          
          -- Copy target. We need a copy because it might already be overwritten with the next target during flight of weapon.
          local target=UTILS.DeepCopy(self.currentTarget)
          
          -- Set callback functions.
          weapon:SetFuncTrack(ARTY._FuncTrack, self, target)
          weapon:SetFuncImpact(ARTY._FuncImpact, self, target)
          
          -- Start tracking in 2 sec (arty ammo should fly a bit).
          weapon:StartTrack(2)
        end

        -- Get current ammo.
        local _nammo,_nshells,_nrockets,_nmissiles=self:GetAmmo()

        -- Decrease available nukes because we just fired one.
        if self.currentTarget.weapontype==ARTY.WeaponType.TacticalNukes then
          self.Nukes=self.Nukes-1
        end

        -- Decrease available illuminatin shells because we just fired one.
        if self.currentTarget.weapontype==ARTY.WeaponType.IlluminationShells then
          self.Nillu=self.Nillu-1
        end

        -- Decrease available illuminatin shells because we just fired one.
        if self.currentTarget.weapontype==ARTY.WeaponType.SmokeShells then
          self.Nsmoke=self.Nsmoke-1
        end

        -- Check if we are completely out of ammo.
        local _outofammo=false
        if _nammo==0 then
          self:T(self.lid..string.format("Group %s completely out of ammo.", self.groupname))
          _outofammo=true
        end

        -- Check if we are out of ammo of the weapon type used for this target.
        -- Note that should not happen because we only open fire with the available number of shots.
        local _partlyoutofammo=self:_CheckOutOfAmmo({self.currentTarget})

        -- Weapon type name for current target.
        local _weapontype=self:_WeaponTypeName(self.currentTarget.weapontype)
        self:T(self.lid..string.format("Group %s ammo: total=%d, shells=%d, rockets=%d, missiles=%d", self.groupname, _nammo, _nshells, _nrockets, _nmissiles))
        self:T(self.lid..string.format("Group %s uses weapontype %s for current target.", self.groupname, _weapontype))

        -- Default switches for cease fire and relocation.
        local _ceasefire=false
        local _relocate=false

        -- Check if number of shots reached max.
        if self.Nshots >= self.currentTarget.nshells then

          -- Debug message
          local text=string.format("Group %s stop firing on target %s.", self.groupname, self.currentTarget.name)
          self:T(self.lid..text)
          MESSAGE:New(text, 5):ToAllIf(self.Debug)

          -- Cease fire.
          _ceasefire=true

          -- Relocate if enabled.
          _relocate=self.relocateafterfire
        end

        -- Check if we are (partly) out of ammo.
        if _outofammo or _partlyoutofammo then
          _ceasefire=true
        end

        -- Relocate position.
        if _relocate then
          self:_Relocate()
        end

        -- Cease fire on current target.
        if _ceasefire then
          self:CeaseFire(self.currentTarget)
        end

      else
        self:E(self.lid..string.format("WARNING: No current target for group %s?!", self.groupname))
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
  --local batteryname=self.groupname
  --local batterycoalition=self.Controllable:GetCoalition()

  self:T2(string.format("Event captured  = %s", tostring(self.groupname)))
  self:T2(string.format("Event id        = %s", tostring(Event.id)))
  self:T2(string.format("Event time      = %s", tostring(Event.time)))
  self:T2(string.format("Event idx       = %s", tostring(Event.idx)))
  self:T2(string.format("Event coalition = %s", tostring(Event.coalition)))
  self:T2(string.format("Event group id  = %s", tostring(Event.groupID)))
  self:T2(string.format("Event text      = %s", tostring(Event.text)))
  if Event.initiator~=nil then
    local _unitname=Event.initiator:getName()
    self:T2(string.format("Event ini unit name = %s", tostring(_unitname)))
  end

  if Event.id==world.event.S_EVENT_MARK_ADDED then
    self:T2({event="S_EVENT_MARK_ADDED", battery=self.groupname, vec3=Event.pos})

  elseif Event.id==world.event.S_EVENT_MARK_CHANGE then
    self:T({event="S_EVENT_MARK_CHANGE", battery=self.groupname, vec3=Event.pos})

    -- Handle event.
    self:_OnEventMarkChange(Event)

  elseif Event.id==world.event.S_EVENT_MARK_REMOVED then
    self:T2({event="S_EVENT_MARK_REMOVED", battery=self.groupname, vec3=Event.pos})

    -- Hande event.
    self:_OnEventMarkRemove(Event)
  end

end

--- Function called when a F10 map mark was removed.
-- @param #ARTY self
-- @param #table Event Event data.
function ARTY:_OnEventMarkRemove(Event)

  -- Get battery coalition and name.
  local batterycoalition=self.coalition
  --local batteryname=self.groupname

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
            -- We do clear tasks here because in Arrived() it can cause a CTD if the group did actually arrive!
            self.Controllable:ClearTasks()
            -- Current move is removed here. In contrast to RemoveTarget() there are is no maxengage parameter.
            self:Arrived()
          else
            -- Remove move from queue
            self:RemoveMove(_name)
          end
        elseif _canceltarget then
          if self.currentTarget and self.currentTarget.name==_name then
            -- Cease fire.
            self:CeaseFire(self.currentTarget)
            -- We still need to remove the target, because there might be more planned engagements (maxengage>1).
            self:RemoveTarget(_name)
          else
            -- Remove target from queue
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

    -- Convert (wrong x-->z, z-->x) vec3
    -- DONE: This needs to be "fixed", once DCS gives the correct numbers for x and z.
    -- Was fixed in DCS 2.5.5.34644!
    local vec3={y=Event.pos.y, x=Event.pos.x, z=Event.pos.z}
    --local vec3={y=Event.pos.y, x=Event.pos.z, z=Event.pos.x}

    -- Get coordinate from vec3.
    local _coord=COORDINATE:NewFromVec3(vec3)

    -- Adjust y component to actual land height. When a coordinate is create it uses y=5 m!
    _coord.y=_coord:GetLandHeight()

    -- Get battery coalition and name.
    local batterycoalition=self.coalition
    local batteryname=self.groupname

    -- Check if the coalition is the same or an authorization key has been defined.
    if (batterycoalition==Event.coalition and self.markkey==nil) or self.markkey~=nil then

      -- Evaluate marker text and extract parameters.
      local _assign=self:_Markertext(Event.text)

      -- Check if ENGAGE or MOVE or REQUEST keywords were found.
      if _assign==nil or not (_assign.engage or _assign.move or _assign.request or _assign.cancel or _assign.set) then
          self:T(self.lid..string.format("WARNING: %s, no keyword ENGAGE, MOVE, REQUEST, CANCEL or SET in mark text! Command will not be executed. Text:\n%s", self.groupname, Event.text))
        return
      end

      -- Check if job is assigned to this ARTY group. Default is for all ARTY groups.
      local _assigned=false

      -- If any array is filled something has been assigned.
      if _assign.everyone then

        -- Everyone was addressed.
        _assigned=true

      else --#_assign.battery>0 or #_assign.aliases>0 or #_assign.cluster>0 then

        -- Loop over batteries.
        for _,bat in pairs(_assign.battery) do
          if self.groupname==bat then
            _assigned=true
          end
        end

        -- Loop over aliases.
        for _,alias in pairs(_assign.aliases) do
          if self.alias==alias then
            _assigned=true
          end
        end

        -- Loop over clusters.
        for _,bat in pairs(_assign.cluster) do
          for _,cluster in pairs(self.clusters) do
            if cluster==bat then
              _assigned=true
            end
          end
        end

      end

      -- We were not addressed.
      if not _assigned then
        self:T3(self.lid..string.format("INFO: ARTY group %s was not addressed! Mark text:\n%s", self.groupname, Event.text))
        return
      else
        if self.Controllable and self.Controllable:IsAlive() then
        
        else
          self:T3(self.lid..string.format("INFO: ARTY group %s was addressed but is NOT alive! Mark text:\n%s", self.groupname, Event.text))
          return
        end
      end

      -- Coordinate was given in text, e.g. as lat, long.
      if _assign.coord then
        _coord=_assign.coord
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

      -- Cancel stuff and return.
      if _assign.cancel and _validkey then
        if _assign.cancelmove and self.currentMove then
          self.Controllable:ClearTasks()
          self:Arrived()
        elseif _assign.canceltarget and self.currentTarget then
          self.currentTarget.engaged=self.currentTarget.engaged+1
          self:CeaseFire(self.currentTarget)
        elseif _assign.cancelrearm and self:is("Rearming") then
          local nammo=self:GetAmmo()
          if nammo>0 then
            self:Rearmed()
          else
            self:Winchester()
          end
        end
        -- Cancels Done ==> End of story!
        return
      end

      -- Set stuff and return.
      if _assign.set and _validkey then
        if _assign.setrearmingplace and self.ismobile then
          self:SetRearmingPlace(_coord)
          _coord:RemoveMark(Event.idx)
          _coord:MarkToCoalition(string.format("Rearming place for battery %s", self.groupname), self.coalition, false, string.format("New rearming place for battery %s defined.", self.groupname))
          if self.Debug then
            _coord:SmokeOrange()
          end
        end
        if _assign.setrearminggroup then
          _coord:RemoveMark(Event.idx)
          local rearminggroupcoord=_assign.setrearminggroup:GetCoordinate()
          rearminggroupcoord:MarkToCoalition(string.format("Rearming group for battery %s", self.groupname), self.coalition, false, string.format("New rearming group for battery %s defined.", self.groupname))
          self:SetRearmingGroup(_assign.setrearminggroup)
          if self.Debug then
            rearminggroupcoord:SmokeOrange()
          end
        end
        -- Set stuff Done ==> End of story!
        return
      end

      -- Handle engagements and relocations.
      if _validkey then

        -- Remove old mark because it might contain confidential data such as the key.
        -- Also I don't know who can see the mark which was created.
        _coord:RemoveMark(Event.idx)

        -- Anticipate marker ID.
        -- WARNING: Make sure, no marks are set until the COORDINATE:MarkToCoalition() is called or the target/move name will be wrong and target cannot be removed by deleting its marker.
        local _id=UTILS._MarkID+1

        if _assign.move then

          -- Create a new name. This determins the string we search when deleting a move!
          local _name=self:_MarkMoveName(_id)

          local text=string.format("%s, received new relocation assignment.", self.alias)
          text=text..string.format("\nCoordinates %s",_coord:ToStringLLDMS())
          MESSAGE:New(text, 10):ToCoalitionIf(batterycoalition, self.report or self.Debug)

          -- Assign a relocation of the arty group.
          local _movename=self:AssignMoveCoord(_coord, _assign.time, _assign.speed, _assign.onroad, _assign.movecanceltarget,_name, true)

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
            local text=string.format("%s, relocation not possible.", self.alias)
            MESSAGE:New(text, 10):ToCoalitionIf(batterycoalition, self.report or self.Debug)
          end

        else

          -- Create a new name.
          local _name=self:_MarkTargetName(_id)

          local text=string.format("%s, received new target assignment.", self.alias)
          text=text..string.format("\nCoordinates %s",_coord:ToStringLLDMS())
          if _assign.time then
            text=text..string.format("\nTime %s",_assign.time)
          end
          if _assign.prio then
            text=text..string.format("\nPrio %d",_assign.prio)
          end
          if _assign.radius then
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
function ARTY:OnEventDead(EventData)
  self:F(EventData)

  -- Name of controllable.
  local _name=self.groupname

  -- Check for correct group.
  if EventData and EventData.IniGroupName and EventData.IniGroupName==_name then

    -- Name of the dead unit.
    local unitname=tostring(EventData.IniUnitName)

    -- Dead Unit.
    self:T(self.lid..string.format("%s: Captured dead event for unit %s.", _name, unitname))

    -- FSM Dead event. We give one second for update of data base.
    --self:__Dead(1, unitname)
    self:Dead(unitname)
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
  
  -- Get ammo.
  local nammo, nshells, nrockets, nmissiles=self:GetAmmo()
  
  -- We have a cargo group ==> check if group was loaded into a carrier.
  if self.iscargo and self.cargogroup then
    if self.cargogroup:IsLoaded() and not self:is("InTransit")  then
      -- Group is now InTransit state. Current target is canceled.
      self:T(self.lid..string.format("Group %s has been loaded into a carrier and is now transported.", self.alias))
      self:Loaded()
    elseif self.cargogroup:IsUnLoaded() then
      -- Group has been unloaded and is combat ready again.
      self:T(self.lid..string.format("Group %s has been unloaded from the carrier.", self.alias))
      self:UnLoaded()
    end
  end  

  -- FSM state.
  local fsmstate=self:GetState()
  self:T(self.lid..string.format("Status %s, Ammo total=%d: shells=%d [smoke=%d, illu=%d, nukes=%d*%.3f kT], rockets=%d, missiles=%d", fsmstate, nammo, nshells, self.Nsmoke, self.Nillu, self.Nukes, self.nukewarhead/1000000, nrockets, nmissiles))

  if self.Controllable and self.Controllable:IsAlive() then

    -- Debug current status info.
    if self.Debug then
      self:_StatusReport()
    end

    -- Group on the move.
    if self:is("Moving") then
      self:T2(self.lid..string.format("%s: Moving", Controllable:GetName()))
    end

    -- Group is rearming.
    if self:is("Rearming") then
      local _rearmed=self:_CheckRearmed()
      if _rearmed then
        self:T2(self.lid..string.format("%s: Rearming ==> Rearmed", Controllable:GetName()))
        self:Rearmed()
      end
    end

    -- Group finished rearming.
    if self:is("Rearmed") then
      local distance=self.Controllable:GetCoordinate():Get2DDistance(self.InitialCoord)
      self:T2(self.lid..string.format("%s: Rearmed. Distance ARTY to InitalCoord = %d m", Controllable:GetName(), distance))
      -- Check that ARTY group is back and set it to combat ready.
      if distance <= self.RearmingDistance then
        self:T2(self.lid..string.format("%s: Rearmed ==> CombatReady", Controllable:GetName()))
        self:CombatReady()
      end
    end

    -- Group arrived at destination.
    if self:is("Arrived") then
      self:T2(self.lid..string.format("%s: Arrived ==> CombatReady", Controllable:GetName()))
      self:CombatReady()
    end

    -- Group is firing on target.
    if self:is("Firing") then
      -- Check that firing started after ~5 min. If not, target is removed.
      self:_CheckShootingStarted()
    end

    -- Check if targets are in range and update target.inrange value.
    self:_CheckTargetsInRange()

    -- Check if selected weapon type for target is possible at all. E.g. request rockets for Paladin.
    local notpossible={}
    for i=1,#self.targets do
      local _target=self.targets[i]
      local possible=self:_CheckWeaponTypePossible(_target)
      if not possible then
        table.insert(notpossible, _target.name)
      end
    end
    for _,targetname in pairs(notpossible) do
      self:E(self.lid..string.format("%s: Removing target %s because requested weapon is not possible with this type of unit.", self.groupname, targetname))
      self:RemoveTarget(targetname)
    end

    -- Get a valid timed target if it is due to be attacked.
    local _timedTarget=self:_CheckTimedTargets()

    -- Get a valid normal target (one that is not timed).
    local _normalTarget=self:_CheckNormalTargets()

    -- Get a commaned move to another location.
    local _move=self:_CheckMoves()

    if _move then

      -- Command to move.
      self:Move(_move)

    elseif _timedTarget then

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

    -- Get ammo.
    --local nammo, nshells, nrockets, nmissiles=self:GetAmmo()

    -- Check if we have a target in the queue for which weapons are still available.
    local gotsome=false
    if #self.targets>0 then
      for i=1,#self.targets do
        local _target=self.targets[i]
        if self:_CheckWeaponTypeAvailable(_target)>0 then
          gotsome=true
        end
      end
    else
      -- No targets in the queue.
      gotsome=true
    end

    -- No ammo available. Either completely blank or only queued targets for ammo which is out.
    if (nammo==0 or not gotsome) and not (self:is("Moving") or self:is("Rearming") or self:is("OutOfAmmo")) then
      self:Winchester()
    end

    -- Group is out of ammo.
    if self:is("OutOfAmmo") then
      self:T2(self.lid..string.format("%s: OutOfAmmo ==> Rearm ==> Rearming", Controllable:GetName()))
      self:Rearm()
    end

    -- Call status again in ~10 sec.
    self:__Status(self.StatusInterval)

  elseif self.iscargo then

    -- We have a cargo group ==> check if group was loaded into a carrier.
    if self.cargogroup and self.cargogroup:IsAlive() then

      -- Group is being transported as cargo ==> skip everything and check again in 5 seconds.
      if self:is("InTransit") then
        self:__Status(-5)
      end
      
    end  

  else
    self:E(self.lid..string.format("Arty group %s is not alive!", self.groupname))
  end
  
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Loaded" event. Checks if group is currently firing and removes the target by calling CeaseFire.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, proceed to onafterLoaded.
function ARTY:onbeforeLoaded(Controllable, From, Event, To)
  if self.currentTarget then
    self:CeaseFire(self.currentTarget)
  end

  return true
end

--- After "UnLoaded" event. Group is combat ready again.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, proceed to onafterLoaded.
function ARTY:onafterUnLoaded(Controllable, From, Event, To)
  self:CombatReady()
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
  self:T3(self.lid..string.format("onenterComabReady, from=%s, event=%s, to=%s", From, Event, To))
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
    self:E(self.lid..string.format("ERROR: Group %s already has a target %s!", self.groupname, self.currentTarget.name))
    -- Deny transition.
    return false
  end

  -- Check if target is in range.
  if not self:_TargetInRange(target) then
    -- This should not happen. Some earlier check failed.
    self:E(self.lid..string.format("ERROR: Group %s, target %s is out of range!", self.groupname, self.currentTarget.name))
    -- Deny transition.
    return false
  end

  -- Get the number of available shells, rockets or missiles requested for this target.
  local nfire=self:_CheckWeaponTypeAvailable(target)

  -- Adjust if less than requested ammo is left.
  target.nshells=math.min(target.nshells, nfire)

  -- No ammo left ==> deny transition.
  if target.nshells<1 then
    local text=string.format("%s, no ammo left to engage target %s with selected weapon type %s.")
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
-- @param #ARTY.Target target Array holding the target info.
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
  elseif target.weapontype==ARTY.WeaponType.IlluminationShells then
    nfire=self.Nillu
    _type="illumination shells"
  elseif target.weapontype==ARTY.WeaponType.SmokeShells then
    nfire=self.Nsmoke
    _type="smoke shells"
  elseif target.weapontype==ARTY.WeaponType.Rockets then
    nfire=Nrockets
    _type="rockets"
  elseif target.weapontype==ARTY.WeaponType.CruiseMissile then
    nfire=Nmissiles
    _type="cruise missiles"
  end

  -- Adjust if less than requested ammo is left.
  target.nshells=math.min(target.nshells, nfire)

  -- Send message.
  local text=string.format("%s, opening fire on target %s with %d %s. Distance %.1f km.", Controllable:GetName(), target.name, target.nshells, _type, range/1000)
  self:T(self.lid..text)
  MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report)

  --if self.Debug then
  --  local _coord=target.coord --Core.Point#COORDINATE
  --  local text=string.format("ARTY %s, Target %s, n=%d, weapon=%s", self.Controllable:GetName(), target.name, target.nshells, self:_WeaponTypeName(target.weapontype))
  --  _coord:MarkToAll(text)
  --end

  -- Start firing.
  if target.attackgroup then
    self:_AttackGroup(target)
  else
    self:_FireAtCoord(target.coord, target.radius, target.nshells, target.weapontype)
  end

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
    self:T(self.lid..text)
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report)

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

  else
    self:E(self.lid..string.format("ERROR: No target in cease fire for group %s.", self.groupname))
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
  self:T(self.lid..text)
  MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

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
    self:T(self.lid..string.format("%s, group is already armed to the teeth. Rearming request denied!", self.groupname))
    return false
  else
    self:T(self.lid..string.format("%s, group might be rearmed.", self.groupname))
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

    if self.RearmingGroup and self.RearmingPlaceCoord and self.ismobile then

      -- CASE 1: Rearming unit and ARTY group meet at rearming place.

      -- Send message.
      local text=string.format("%s, %s, request rearming at rearming place.", Controllable:GetName(), self.RearmingGroup:GetName())
      self:T(self.lid..text)
      MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

      -- Distances.
      local dA=coordARTY:Get2DDistance(self.RearmingPlaceCoord)
      local dR=coordRARM:Get2DDistance(self.RearmingPlaceCoord)

      -- Route ARTY group to rearming place.
      if dA > self.RearmingDistance then
        local _tocoord=self:_VicinityCoord(self.RearmingPlaceCoord, self.RearmingDistance/4, self.RearmingDistance/2)
        self:AssignMoveCoord(_tocoord, nil, nil, self.RearmingArtyOnRoad, false, "REARMING MOVE TO REARMING PLACE", true)
      end

      -- Route Rearming group to rearming place.
      if dR > self.RearmingDistance then
        local ToCoord=self:_VicinityCoord(self.RearmingPlaceCoord, self.RearmingDistance/4, self.RearmingDistance/2)
        self:_Move(self.RearmingGroup, ToCoord, self.RearmingGroupSpeed, self.RearmingGroupOnRoad)
      end

    elseif self.RearmingGroup then

      -- CASE 2: Rearming unit drives to ARTY group.

      -- Send message.
      local text=string.format("%s, %s, request rearming.", Controllable:GetName(), self.RearmingGroup:GetName())
      self:T(self.lid..text)
      MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

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
      self:T(self.lid..text)
      MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

      -- Distance.
      local dA=coordARTY:Get2DDistance(self.RearmingPlaceCoord)

      -- Route ARTY group to rearming place.
      if dA > self.RearmingDistance then
        local _tocoord=self:_VicinityCoord(self.RearmingPlaceCoord)
        self:AssignMoveCoord(_tocoord, nil, nil, self.RearmingArtyOnRoad, false, "REARMING MOVE TO REARMING PLACE", true)
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
  self:T(self.lid..text)
  MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

  -- "Rearm" tactical nukes as well.
  self.Nukes=self.Nukes0
  self.Nillu=self.Nillu0
  self.Nsmoke=self.Nsmoke0

  -- Route ARTY group back to where it came from (if distance is > 100 m).
  local dist=self.Controllable:GetCoordinate():Get2DDistance(self.InitialCoord)
  if dist > self.RearmingDistance then
    self:AssignMoveCoord(self.InitialCoord, nil, nil, self.RearmingArtyOnRoad, false, "REARMING MOVE REARMING COMPLETE", true)
  end

  -- Route unit back to where it came from (if distance is > 100 m).
  if self.RearmingGroup and self.RearmingGroup:IsAlive() then
    local d=self.RearmingGroup:GetCoordinate():Get2DDistance(self.RearmingGroupCoord)
    if d > self.RearmingDistance then
      self:_Move(self.RearmingGroup, self.RearmingGroupCoord, self.RearmingGroupSpeed, self.RearmingGroupOnRoad)
    else
      -- Clear tasks.
      self.RearmingGroup:ClearTasks()
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
  local FullAmmo=self.Nammo0 * nunits / self.IniGroupStrength

  -- Rearming status in per cent.
  local _rearmpc=nammo/FullAmmo*100

  -- Send message if rearming > 1% complete
  if _rearmpc>1 then
    local text=string.format("%s, rearming %d %% complete.", self.alias, _rearmpc)
    self:T(self.lid..text)
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)
  end

  -- Return if ammo is full.
  -- TODO: Strangely, I got the case that a Paladin got one more shell than it can max carry, i.e. 40 not 39 when rearming when it still had some ammo left. Need to report.
  if nammo>=FullAmmo then
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
-- @param #table move Table containing the move parameters.
-- @param Core.Point#COORDINATE ToCoord Coordinate to which the ARTY group should move.
-- @param #boolean OnRoad If true group should move on road mainly.
-- @return #boolean If true, proceed to onafterMove.
function ARTY:onbeforeMove(Controllable, From, Event, To, move)
  self:_EventFromTo("onbeforeMove", Event, From, To)

  -- Check if group can actually move...
  if not self.ismobile then
    return false
  end

  -- Check if group is engaging.
  if self.currentTarget then
    if move.cancel then
      -- Cancel current target.
      self:CeaseFire(self.currentTarget)
    else
      -- We should not cancel.
      return false
    end
  end

  return true
end

--- After "Move" event. Route group to given coordinate.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table move Table containing the move parameters.
function ARTY:onafterMove(Controllable, From, Event, To, move)
  self:_EventFromTo("onafterMove", Event, From, To)

  -- Set alarm state to green and ROE to weapon hold.
  self.Controllable:OptionAlarmStateGreen()
  self.Controllable:OptionROEHoldFire()

  -- Take care of max speed.
  local _Speed=math.min(move.speed, self.SpeedMax)

  -- Smoke coordinate
  if self.Debug then
    move.coord:SmokeRed()
  end

  -- Set current move.
  self.currentMove=move

  -- Route group to coordinate.
  self:_Move(self.Controllable, move.coord, move.speed, move.onroad)

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
  self:T(self.lid..text)
  MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

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
function ARTY:onafterNewTarget(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterNewTarget", Event, From, To)

  -- Debug message.
  local text=string.format("Adding new target %s.", target.name)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  self:T(self.lid..text)
end

--- After "NewMove" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table move Array holding the move parameters.
function ARTY:onafterNewMove(Controllable, From, Event, To, move)
  self:_EventFromTo("onafterNewTarget", Event, From, To)

  -- Debug message.
  local text=string.format("Adding new move %s.", move.name)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  self:T(self.lid..text)
end


--- After "Dead" event, when a unit has died. When all units of a group are dead trigger "Stop" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Unitname Name of the unit that died.
function ARTY:onafterDead(Controllable, From, Event, To, Unitname)
  self:_EventFromTo("onafterDead", Event, From, To)

  -- Number of units still alive.
  --local nunits=self.Controllable and self.Controllable:CountAliveUnits() or 0
  local nunits=self.Controllable:CountAliveUnits()

  -- Message.
  local text=string.format("%s, our unit %s just died! %d units left.", self.groupname, Unitname, nunits)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  self:I(self.lid..text)

  -- Go to stop state.
  if nunits==0 then

      -- Cease Fire on current target.
    if self.currentTarget then
      self:CeaseFire(self.currentTarget)
    end

    if self.respawnafterdeath then
      -- Respawn group.
      if not self.respawning then
        self.respawning=true
        self:__Respawn(self.respawndelay or 1)
      end
    else
      -- Stop FSM.
      self:Stop()
    end
  end

end


--- After "Dead" event, when a unit has died. When all units of a group are dead trigger "Stop" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterRespawn(Controllable, From, Event, To)
  self:_EventFromTo("onafterRespawn", Event, From, To)

  env.info("FF Respawning arty group")

  local group=self.Controllable --Wrapper.Group#GROUP

  -- Respawn group.
  self.Controllable=group:Respawn()

  self.respawning=false

  -- Call status again.
  self:__Status(-1)
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
  self:I(self.lid..string.format("Stopping ARTY FSM for group %s.", tostring(Controllable:GetName())))

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
  if weapontype==ARTY.WeaponType.TacticalNukes or weapontype==ARTY.WeaponType.IlluminationShells or weapontype==ARTY.WeaponType.SmokeShells then
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

--- Set task for attacking a group.
-- @param #ARTY self
-- @param #ARTY.Target target Target data.
function ARTY:_AttackGroup(target)

  -- Controllable.
  local group=self.Controllable --Wrapper.Group#GROUP

  local weapontype=target.weapontype

  -- Tactical nukes are actually cannon shells.
  if weapontype==ARTY.WeaponType.TacticalNukes or weapontype==ARTY.WeaponType.IlluminationShells or weapontype==ARTY.WeaponType.SmokeShells then
    weapontype=ARTY.WeaponType.Cannon
  end

  -- Set ROE to weapon free.
  group:OptionROEOpenFire()

  -- Target group.
  local targetgroup=GROUP:FindByName(target.name)

  -- Get task.
  local fire=group:TaskAttackGroup(targetgroup, weapontype, AI.Task.WeaponExpend.ONE, 1)

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
    self:T2(self.lid..string.format("Nuclear explosion strength s(%.1f m) = %.5f (s/s0=%.1f %%), alpha=%.3f", R, strength, strength/S0*100, alpha))
    return strength
  end

  local function ignite(_fires)
    for _,fire in pairs(_fires) do
      local _fire=fire.coord --Core.Point#COORDINATE

      -- Get distance to impact and calc exponential explosion strength.
      local R=_fire:Get2DDistance(_coord)
      local S=_explosion(R)
      self:T2(self.lid..string.format("Explosion r=%.1f, s=%.3f", R, S))

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
  self:F2({group=group:GetName(), Speed=Speed, OnRoad=OnRoad})

  -- Clear all tasks.
  group:ClearTasks()
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
  local cpini=group:GetCoordinate() -- Core.Point#COORDINATE

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

    -- Get path on road.
    local _pathonroad=cpini:GetPathOnRoad(ToCoord)

    -- Check if we actually got a path. There are situations where nil is returned. In that case, we go directly.
    if _pathonroad then

      -- Just take the first and last point.
      local _first=_pathonroad[1]
      local _last=_pathonroad[#_pathonroad]

      if self.Debug then
        _first:SmokeGreen()
        _last:SmokeGreen()
      end

      -- First point on road.
      path[#path+1]=_first:WaypointGround(Speed, "On Road")
      task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, false)

      -- Last point on road.
      path[#path+1]=_last:WaypointGround(Speed, "On Road")
      task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, false)
    end

  end

  -- Last waypoint at ToCoord.
  path[#path+1]=ToCoord:WaypointGround(Speed, formation)
  task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, true)

  --if self.Debug then
  --  cpini:SmokeBlue()
  --  ToCoord:SmokeBlue()
  --end

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

  if group and group:IsAlive() then
  
    local groupname=tostring(group:GetName())

    -- Debug message.
    local text=string.format("%s, passing waypoint %d.", groupname, i)
    if final then
      text=string.format("%s, arrived at destination.", groupname)
    end
    arty:T(arty.lid..text)
  
    -- Arrived event.
    if final and arty.groupname==groupname then
      arty:Arrived()
    end
    
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
    self:AssignMoveCoord(_new, nil, nil, false, false, "RELOCATION MOVE AFTER FIRING")
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

  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT

    if unit then

      -- Output.
      local text=string.format("ARTY group %s - unit %s:\n", self.groupname, unit:GetName())

      -- Get ammo table.
      local ammotable=unit:GetAmmo()

      if ammotable ~= nil then

        local weapons=#ammotable

        -- Display ammo table
        if display then
          self:I(self.lid..string.format("Number of weapons %d.", weapons))
          self:I({ammotable=ammotable})
          self:I(self.lid.."Ammotable:")
          for id,bla in pairs(ammotable) do
            self:I({id=id, ammo=bla})
          end
        end

        -- Loop over all weapons.
        for w=1,weapons do

          -- Number of current weapon.
          local Nammo=ammotable[w]["count"]

          -- Typename of current weapon
          local Tammo=ammotable[w]["desc"]["typeName"]

          local _weaponString = self:_split(Tammo,"%.")
          local _weaponName   = _weaponString[#_weaponString]

          -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3
          local Category=ammotable[w].desc.category

          -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
          local MissileCategory=nil
          if Category==Weapon.Category.MISSILE then
            MissileCategory=ammotable[w].desc.missileCategory
          end


          -- Check for correct shell type.
          local _gotshell=false
          if #self.ammoshells>0 then
            -- User explicitly specified the valid type(s) of shells.
            for _,_type in pairs(self.ammoshells) do
              if string.match(Tammo, _type) and Category==Weapon.Category.SHELL then
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
              if string.match(Tammo, _type) and Category==Weapon.Category.ROCKET then
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
              if string.match(Tammo,_type)  and Category==Weapon.Category.MISSILE then
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
            text=text..string.format("- %d shells of type %s\n", Nammo, _weaponName)

          elseif _gotrocket then

            -- Add up all rockets.
            nrockets=nrockets+Nammo

            -- Debug info.
            text=text..string.format("- %d rockets of type %s\n", Nammo, _weaponName)

          elseif _gotmissile then

            -- Add up all cruise missiles (category 5)
            if MissileCategory==Weapon.MissileCategory.CRUISE then
              nmissiles=nmissiles+Nammo
            end

            -- Debug info.
            text=text..string.format("- %d %s missiles of type %s\n", Nammo, self:_MissileCategoryName(MissileCategory), _weaponName)

          else

            -- Debug info.
            text=text..string.format("- %d unknown ammo of type %s (category=%d, missile category=%s)\n", Nammo, Tammo, Category, tostring(MissileCategory))

          end

        end
      end

      -- Debug text and send message.
      if display then
        self:I(self.lid..text)
      else
        self:T3(self.lid..text)
      end
      MESSAGE:New(text, 10):ToAllIf(display)

    end
  end

  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles

  return nammo, nshells, nrockets, nmissiles
end

--- Returns a name of a missile category.
-- @param #ARTY self
-- @param #number categorynumber Number of missile category from weapon missile category enumerator. See https://wiki.hoggitworld.com/view/DCS_Class_Weapon
-- @return #string Missile category name.
function ARTY:_MissileCategoryName(categorynumber)
  local cat="unknown"
  if categorynumber==Weapon.MissileCategory.AAM then
    cat="air-to-air"
  elseif categorynumber==Weapon.MissileCategory.SAM then
    cat="surface-to-air"
  elseif categorynumber==Weapon.MissileCategory.BM then
    cat="ballistic"
  elseif categorynumber==Weapon.MissileCategory.ANTI_SHIP then
    cat="anti-ship"
  elseif categorynumber==Weapon.MissileCategory.CRUISE then
    cat="cruise"
  elseif categorynumber==Weapon.MissileCategory.OTHER then
    cat="other"
  end
  return cat
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
  --local batteryname=self.groupname
  local batterycoalition=self.coalition

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
        self:T(self.lid..string.format("Authorisation Key=%s.", val))
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
    self:T2(self.lid..string.format("%s, authkey=%s == %s=playerkey ==> valid=%s", self.groupname, tostring(self.markkey), tostring(mykey), tostring(_validkey)))

    -- Send message
    local text=""
    if mykey==nil then
      text=string.format("%s, authorization required but did not receive a key!", self.alias)
    elseif _validkey==false then
      text=string.format("%s, authorization required but did receive an incorrect key (key=%s)!", self.alias, tostring(mykey))
    elseif _validkey==true then
      text=string.format("%s, authentification successful!", self.alias)
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
  assignment.aliases={}
  assignment.cluster={}
  assignment.everyone=false
  assignment.move=false
  assignment.engage=false
  assignment.request=false
  assignment.cancel=false
  assignment.set=false
  assignment.readonly=false
  assignment.movecanceltarget=false
  assignment.cancelmove=false
  assignment.canceltarget=false
  assignment.cancelrearm=false
  assignment.setrearmingplace=false
  assignment.setrearminggroup=false

  -- Check for correct keywords.
  if text:lower():find("arty engage") or text:lower():find("arty attack") then
    assignment.engage=true
  elseif text:lower():find("arty move") or text:lower():find("arty relocate") then
    assignment.move=true
  elseif text:lower():find("arty request") then
    assignment.request=true
  elseif text:lower():find("arty cancel") then
    assignment.cancel=true
  elseif text:lower():find("arty set") then
    assignment.set=true
  else
    self:E(self.lid..'ERROR: Neither "ARTY ENGAGE" nor "ARTY MOVE" nor "ARTY RELOCATE" nor "ARTY REQUEST" nor "ARTY CANCEL" nor "ARTY SET" keyword specified!')
    return nil
  end

  -- keywords are split by ","
  local keywords=self:_split(text, ",")
  self:T({keywords=keywords})

  for _,keyphrase in pairs(keywords) do

    -- Split keyphrase by space. First one is the key and second, ... the parameter(s) until the next comma.
    local str=self:_split(keyphrase, " ")
    local key=str[1]
    local val=str[2]

    -- Debug output.
    self:T3(self.lid..string.format("%s, keyphrase = %s, key = %s, val = %s", self.groupname, tostring(keyphrase), tostring(key), tostring(val)))

    -- Battery name, i.e. which ARTY group should fire.
    if key:lower():find("battery") then

      local v=self:_split(keyphrase, '"')

      for i=2,#v,2 do
        table.insert(assignment.battery, v[i])
        self:T2(self.lid..string.format("Key Battery=%s.", v[i]))
      end

    elseif key:lower():find("alias") then

      local v=self:_split(keyphrase, '"')

      for i=2,#v,2 do
        table.insert(assignment.aliases, v[i])
        self:T2(self.lid..string.format("Key Aliases=%s.", v[i]))
      end

    elseif key:lower():find("cluster") then

      local v=self:_split(keyphrase, '"')

      for i=2,#v,2 do
        table.insert(assignment.cluster, v[i])
        self:T2(self.lid..string.format("Key Cluster=%s.", v[i]))
      end

    elseif keyphrase:lower():find("everyone") or keyphrase:lower():find("all batteries") or keyphrase:lower():find("allbatteries") then

      assignment.everyone=true
      self:T(self.lid..string.format("Key Everyone=true."))

    elseif keyphrase:lower():find("irrevocable") or keyphrase:lower():find("readonly") then

      assignment.readonly=true
      self:T2(self.lid..string.format("Key Readonly=true."))

    elseif (assignment.engage or assignment.move) and key:lower():find("time") then

      if val:lower():find("now") then
        assignment.time=self:_SecondsToClock(timer.getTime0()+2)
      else
        assignment.time=val
      end
      self:T2(self.lid..string.format("Key Time=%s.", val))

    elseif assignment.engage and key:lower():find("shot") then

      assignment.nshells=tonumber(val)
      self:T(self.lid..string.format("Key Shot=%s.", val))

    elseif assignment.engage and key:lower():find("prio") then

      assignment.prio=tonumber(val)
      self:T2(string.format("Key Prio=%s.", val))

    elseif assignment.engage and key:lower():find("maxengage") then

      assignment.maxengage=tonumber(val)
      self:T2(self.lid..string.format("Key Maxengage=%s.", val))

    elseif assignment.engage and key:lower():find("radius") then

      assignment.radius=tonumber(val)
      self:T2(self.lid..string.format("Key Radius=%s.", val))

    elseif assignment.engage and key:lower():find("weapon") then

      if val:lower():find("cannon") then
        assignment.weapontype=ARTY.WeaponType.Cannon
      elseif val:lower():find("rocket") then
        assignment.weapontype=ARTY.WeaponType.Rockets
      elseif val:lower():find("missile") then
        assignment.weapontype=ARTY.WeaponType.CruiseMissile
      elseif val:lower():find("nuke") then
        assignment.weapontype=ARTY.WeaponType.TacticalNukes
      elseif val:lower():find("illu") then
        assignment.weapontype=ARTY.WeaponType.IlluminationShells
      elseif val:lower():find("smoke") then
        assignment.weapontype=ARTY.WeaponType.SmokeShells
      else
        assignment.weapontype=ARTY.WeaponType.Auto
      end
      self:T2(self.lid..string.format("Key Weapon=%s.", val))

    elseif (assignment.move or assignment.set) and key:lower():find("speed") then

      assignment.speed=tonumber(val)
      self:T2(self.lid..string.format("Key Speed=%s.", val))

    elseif (assignment.move or assignment.set) and (keyphrase:lower():find("on road") or keyphrase:lower():find("onroad") or keyphrase:lower():find("use road")) then

      assignment.onroad=true
      self:T2(self.lid..string.format("Key Onroad=true."))

    elseif assignment.move and (keyphrase:lower():find("cancel target") or keyphrase:lower():find("canceltarget")) then

      assignment.movecanceltarget=true
      self:T2(self.lid..string.format("Key Cancel Target (before move)=true."))

    elseif assignment.request and keyphrase:lower():find("rearm") then

      assignment.requestrearming=true
      self:T2(self.lid..string.format("Key Request Rearming=true."))

    elseif assignment.request and keyphrase:lower():find("ammo") then

      assignment.requestammo=true
      self:T2(self.lid..string.format("Key Request Ammo=true."))

    elseif assignment.request and keyphrase:lower():find("target") then

      assignment.requesttargets=true
      self:T2(self.lid..string.format("Key Request Targets=true."))

    elseif assignment.request and keyphrase:lower():find("status") then

      assignment.requeststatus=true
      self:T2(self.lid..string.format("Key Request Status=true."))

    elseif assignment.request and (keyphrase:lower():find("move") or keyphrase:lower():find("relocation")) then

      assignment.requestmoves=true
      self:T2(self.lid..string.format("Key Request Moves=true."))

    elseif assignment.cancel and (keyphrase:lower():find("engagement") or keyphrase:lower():find("attack") or keyphrase:lower():find("target")) then

      assignment.canceltarget=true
      self:T2(self.lid..string.format("Key Cancel Target=true."))

    elseif assignment.cancel and (keyphrase:lower():find("move") or keyphrase:lower():find("relocation")) then

      assignment.cancelmove=true
      self:T2(self.lid..string.format("Key Cancel Move=true."))

    elseif assignment.cancel and keyphrase:lower():find("rearm") then

      assignment.cancelrearm=true
      self:T2(self.lid..string.format("Key Cancel Rearm=true."))

    elseif assignment.set and keyphrase:lower():find("rearming place") then

      assignment.setrearmingplace=true
      self:T(self.lid..string.format("Key Set Rearming Place=true."))

    elseif assignment.set and keyphrase:lower():find("rearming group") then

      local v=self:_split(keyphrase, '"')
      local groupname=v[2]

      local group=GROUP:FindByName(groupname)
      if group and group:IsAlive() then
        assignment.setrearminggroup=group
      end

      self:T2(self.lid..string.format("Key Set Rearming Group = %s.", tostring(groupname)))

    elseif key:lower():find("lldms") then

      local _flat = "%d+:%d+:%d+%s*[N,S]"
      local _flon = "%d+:%d+:%d+%s*[W,E]"
      local _lat=keyphrase:match(_flat)
      local _lon=keyphrase:match(_flon)
      self:T2(self.lid..string.format("Key LLDMS: lat=%s, long=%s  format=DMS", _lat,_lon))

      if _lat and _lon then

        -- Convert DMS string to DD numbers format.
        local _latitude, _longitude=self:_LLDMS2DD(_lat, _lon)
        self:T2(self.lid..string.format("Key LLDMS: lat=%.3f, long=%.3f  format=DD", _latitude,_longitude))

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
  local text=string.format("%s, relocations:", self.groupname)
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
  MESSAGE:New(text, 20):Clear():ToCoalition(self.coalition)
end

--- Request Targets.
-- @param #ARTY self
function ARTY:_MarkRequestTargets()
  local text=string.format("%s, targets:", self.groupname)
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
  MESSAGE:New(text, 20):Clear():ToCoalition(self.coalition)
end

--- Create a name for an engagement initiated by placing a marker.
-- @param #ARTY self
-- @param #number markerid ID of the placed marker.
-- @return #string Name of target engagement.
function ARTY:_MarkTargetName(markerid)
  return string.format("BATTERY=%s, Marked Target ID=%d", self.groupname, markerid)
end

--- Create a name for a relocation move initiated by placing a marker.
-- @param #ARTY self
-- @param #number markerid ID of the placed marker.
-- @return #string Name of relocation move.
function ARTY:_MarkMoveName(markerid)
  return string.format("BATTERY=%s, Marked Relocation ID=%d", self.groupname, markerid)
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
  self:T3(self.lid.."Sorted targets wrt prio and number of engagements:")
  for i=1,#self.targets do
    local _target=self.targets[i]
    self:T3(self.lid..string.format("Target %s", self:_TargetInfo(_target)))
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
  self:T3(self.lid.."Sorted queue wrt time:")
  for i=1,#queue do
    local _queue=queue[i]
    local _time=tostring(_queue.time)
    local _clock=tostring(self:_SecondsToClock(_queue.time))
    self:T3(self.lid..string.format("%s: time=%s, clock=%s", _queue.name, _time, _clock))
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

  local targets2delete={}

  for i=1,#self.targets do
    local _target=self.targets[i]

    self:T3(self.lid..string.format("Before: Target %s - in range = %s", _target.name, tostring(_target.inrange)))

    -- Check if target is in range.
    local _inrange,_toofar,_tooclose,_remove=self:_TargetInRange(_target)
    self:T3(self.lid..string.format("Inbetw: Target %s - in range = %s, toofar = %s, tooclose = %s", _target.name, tostring(_target.inrange), tostring(_toofar), tostring(_tooclose)))

    if _remove then

      -- The ARTY group is immobile and not cargo but the target is not in range!
      table.insert(targets2delete, _target.name)

    else

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
          local text=string.format("%s, target %s is now in range.", self.alias, _target.name)
          self:T(self.lid..text)
          MESSAGE:New(text,10):ToCoalitionIf(self.coalition, self.report or self.Debug)
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
            _name=string.format("%s, relocation to within max firing range of target %s", self.alias, _target.name)

          elseif _moveaway then

            -- Target was in range on previous check but now we are too far away.
            local _waytogo=_dist-self.minrange+_safetymargin
            local _heading=self:_GetHeading(_target.coord,_from)
            _tocoord=_from:Translate(_waytogo, _heading)
            _name=string.format("%s, relocation to within min firing range of target %s", self.alias, _target.name)

          end

          -- Send info message.
          MESSAGE:New(_name.." assigned.", 10):ToCoalitionIf(self.coalition, self.report or self.Debug)

          -- Assign relocation move.
          self:AssignMoveCoord(_tocoord, nil, nil, self.autorelocateonroad, false, _name, true)

        end

      end

      -- Update value.
      _target.inrange=_inrange

      self:T3(self.lid..string.format("After: Target %s - in range = %s", _target.name, tostring(_target.inrange)))
    end
  end

  -- Remove targets not in range.
  for _,targetname in pairs(targets2delete) do
    self:RemoveTarget(targetname)
  end

end

--- Check all normal (untimed) targets and return the target with the highest priority which has been engaged the fewest times.
-- @param #ARTY self
-- @return #table Target which is due to be attacked now or nil if no target could be found.
function ARTY:_CheckNormalTargets()
  self:F3()

  -- Sort targets w.r.t. prio and number times engaged already.
  self:_SortTargetQueuePrio()

  -- No target engagements if rearming!
  if self:is("Rearming") then
    return nil
  end

  -- Loop over all sorted targets.
  for i=1,#self.targets do
    local _target=self.targets[i]

    -- Debug info.
    self:T3(self.lid..string.format("Check NORMAL target %d: %s", i, self:_TargetInfo(_target)))

    -- Check that target no time, is not under fire currently and in range.
    if _target.underfire==false and _target.time==nil and _target.maxengage > _target.engaged and self:_TargetInRange(_target) and self:_CheckWeaponTypeAvailable(_target)>0 then

      -- Debug info.
      self:T2(self.lid..string.format("Found NORMAL target %s", self:_TargetInfo(_target)))

      return _target
    end
  end

  return nil
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

  -- No target engagements if rearming!
  if self:is("Rearming") then
    return nil
  end

  for i=1,#self.targets do
    local _target=self.targets[i]

    -- Debug info.
    self:T3(self.lid..string.format("Check TIMED target %d: %s", i, self:_TargetInfo(_target)))

    -- Check if target has an attack time which has already passed. Also check that target is not under fire already and that it is in range.
    if _target.time and Tnow>=_target.time and _target.underfire==false and self:_TargetInRange(_target) and self:_CheckWeaponTypeAvailable(_target)>0 then

      -- Check if group currently has a target and whether its priorty is lower than the timed target.
      if self.currentTarget then
        if self.currentTarget.prio > _target.prio then
          -- Current target under attack but has lower priority than this target.
          self:T2(self.lid..string.format("Found TIMED HIGH PRIO target %s.", self:_TargetInfo(_target)))
          return _target
        end
      else
        -- No current target.
        self:T2(self.lid..string.format("Found TIMED target %s.", self:_TargetInfo(_target)))
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

  -- Loop over all moves in queue.
  for i=1,#self.moves do

    -- Shortcut.
    local _move=self.moves[i]

    if string.find(_move.name, "REARMING MOVE") and ((self.currentMove and self.currentMove.name~=_move.name) or self.currentMove==nil) then
      -- We got an rearming assignment which has priority.
      return _move
    elseif (Tnow >= _move.time) and (firing==false or _move.cancel) and (not self.currentMove) and (not self:is("Rearming")) then
      -- Time for move is reached and maybe current target should be cancelled.
      return _move
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
      self:T(self.lid..string.format("%s, waiting for %d seconds for first shot on target %s.", self.groupname, dt, name))
    end

    -- Check if we waited long enough and no shot was fired.
    --if dt > self.WaitForShotTime and self.Nshots==0 then
    if dt > self.WaitForShotTime and (self.Nshots==0 or self.currentTarget.nshells >= self.Nshots) then  --https://github.com/FlightControl-Master/MOOSE/issues/1356

      -- Debug info.
      self:T(self.lid..string.format("%s, no shot event after %d seconds. Removing current target %s from list.", self.groupname, self.WaitForShotTime, name))

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
    self:T3(self.lid..string.format("Have target with name %s. Index = %d", targetname, i))
    if targetname==name then
      self:T2(self.lid..string.format("Found target with name %s. Index = %d", name, i))
      return i
    end
  end

  self:T2(self.lid..string.format("WARNING: Target with name %s could not be found. (This can happen.)", name))
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
    self:T3(self.lid..string.format("Have move with name %s. Index = %d", movename, i))
    if movename==name then
      self:T2(self.lid..string.format("Found move with name %s. Index = %d", name, i))
      return i
    end
  end

  self:T2(self.lid..string.format("WARNING: Move with name %s could not be found. (This can happen.)", name))
  return nil
end

--- Check if group is (partly) out of ammo of a special weapon type.
-- @param #ARTY self
-- @param #table targets Table of targets.
-- @return @boolean True if any target requests a weapon type that is empty.
function ARTY:_CheckOutOfAmmo(targets)

  -- Get current ammo.
  local _nammo,_nshells,_nrockets,_nmissiles=self:GetAmmo()

   -- Special weapon type requested ==> Check if corresponding ammo is empty.
  local _partlyoutofammo=false

  for _,Target in pairs(targets) do

    if Target.weapontype==ARTY.WeaponType.Auto and _nammo==0 then

      self:T(self.lid..string.format("Group %s, auto weapon requested for target %s but all ammo is empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    elseif Target.weapontype==ARTY.WeaponType.Cannon and _nshells==0 then

      self:T(self.lid..string.format("Group %s, cannons requested for target %s but shells empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    elseif Target.weapontype==ARTY.WeaponType.TacticalNukes and self.Nukes<=0 then

      self:T(self.lid..string.format("Group %s, tactical nukes requested for target %s but nukes empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    elseif Target.weapontype==ARTY.WeaponType.IlluminationShells and self.Nillu<=0 then

      self:T(self.lid..string.format("Group %s, illumination shells requested for target %s but illumination shells empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    elseif Target.weapontype==ARTY.WeaponType.SmokeShells and self.Nsmoke<=0 then

      self:T(self.lid..string.format("Group %s, smoke shells requested for target %s but smoke shells empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    elseif Target.weapontype==ARTY.WeaponType.Rockets and _nrockets==0 then

      self:T(self.lid..string.format("Group %s, rockets requested for target %s but rockets empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    elseif Target.weapontype==ARTY.WeaponType.CruiseMissile and _nmissiles==0 then

      self:T(self.lid..string.format("Group %s, cruise missiles requested for target %s but all missiles empty.", self.groupname, Target.name))
      _partlyoutofammo=true

    end

  end

  return _partlyoutofammo
end

--- Check if a selected weapon type is available for this target, i.e. if the current amount of ammo of this weapon type is currently available.
-- @param #ARTY self
-- @param #boolean target Target array data structure.
-- @return #number Amount of shells, rockets or missiles available of the weapon type selected for the target.
function ARTY:_CheckWeaponTypeAvailable(target)

  -- Get current ammo of group.
  local Nammo, Nshells, Nrockets, Nmissiles=self:GetAmmo()

  -- Check if enough ammo is there for the selected weapon type.
  local nfire=Nammo
  if target.weapontype==ARTY.WeaponType.Auto then
    nfire=Nammo
  elseif target.weapontype==ARTY.WeaponType.Cannon then
    nfire=Nshells
  elseif target.weapontype==ARTY.WeaponType.TacticalNukes then
    nfire=self.Nukes
  elseif target.weapontype==ARTY.WeaponType.IlluminationShells then
    nfire=self.Nillu
  elseif target.weapontype==ARTY.WeaponType.SmokeShells then
    nfire=self.Nsmoke
  elseif target.weapontype==ARTY.WeaponType.Rockets then
    nfire=Nrockets
  elseif target.weapontype==ARTY.WeaponType.CruiseMissile then
    nfire=Nmissiles
  end

  return nfire
end
--- Check if a selected weapon type is in principle possible for this group. The current amount of ammo might be zero but the group still can be rearmed at a later point in time.
-- @param #ARTY self
-- @param #boolean target Target array data structure.
-- @return #boolean True if the group can carry this weapon type, false otherwise.
function ARTY:_CheckWeaponTypePossible(target)

  -- Check if enough ammo is there for the selected weapon type.
  local possible=false
  if target.weapontype==ARTY.WeaponType.Auto then
    possible=self.Nammo0>0
  elseif target.weapontype==ARTY.WeaponType.Cannon then
    possible=self.Nshells0>0
  elseif target.weapontype==ARTY.WeaponType.TacticalNukes then
    possible=self.Nukes0>0
  elseif target.weapontype==ARTY.WeaponType.IlluminationShells then
    possible=self.Nillu0>0
  elseif target.weapontype==ARTY.WeaponType.SmokeShells then
    possible=self.Nsmoke0>0
  elseif target.weapontype==ARTY.WeaponType.Rockets then
    possible=self.Nrockets0>0
  elseif target.weapontype==ARTY.WeaponType.CruiseMissile then
    possible=self.Nmissiles0>0
  end

  return possible
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
      self:T3(self.lid..string.format("%d: givenname = %s, newname=%s, unique = %s, makeunique = %s", n, tostring(_givenname), newname, tostring(_unique), tostring(makeunique)))
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
      self:T3(self.lid..string.format("Name %s is not unique. Return false.", tostring(newname)))

      -- Return
      return name, false
    end

    -- Increase loop counter. We try max 100 times.
    n=n+1
  until (_unique or n==nmax)

  -- Debug output and return new name.
  self:T3(self.lid..string.format("Original name %s, new name = %s", name, newname))
  return newname, true
end

--- Check if target is in range.
-- @param #ARTY self
-- @param #table target Target table.
-- @param #boolean message (Optional) If true, send a message to the coalition if the target is not in range. Default is no message is send.
-- @return #boolean True if target is in range, false otherwise.
-- @return #boolean True if ARTY group is too far away from the target, i.e. distance > max firing range.
-- @return #boolean True if ARTY group is too close to the target, i.e. distance < min finring range.
-- @return #boolean True if target should be removed since ARTY group is immobile and not cargo.
function ARTY:_TargetInRange(target, message)
  self:F3(target)

  -- Default is no message.
  if message==nil then
    message=false
  end

  -- Distance between ARTY group and target.
  self:T3({controllable=self.Controllable, targetcoord=target.coord})
  local _dist=self.Controllable:GetCoordinate():Get2DDistance(target.coord)

  -- Assume we are in range.
  local _inrange=true
  local _tooclose=false
  local _toofar=false
  local text=""

  if _dist < self.minrange then
    _inrange=false
    _tooclose=true
    text=string.format("%s, target is out of range. Distance of %.1f km is below min range of %.1f km.", self.alias, _dist/1000, self.minrange/1000)
  elseif _dist > self.maxrange then
    _inrange=false
    _toofar=true
    text=string.format("%s, target is out of range. Distance of %.1f km is greater than max range of %.1f km.", self.alias, _dist/1000, self.maxrange/1000)
  end

  -- Debug output.
  if not _inrange then
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, (self.report and message) or (self.Debug and message))
  end

  -- Remove target if ARTY group cannot move, e.g. Mortas. No chance to be ever in range - unless they are cargo.
  local _remove=false
  if not (self.ismobile or self.iscargo) and _inrange==false then
    --self:RemoveTarget(target.name)
    _remove=true
  end

  return _inrange,_toofar,_tooclose,_remove
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
  elseif tnumber==ARTY.WeaponType.CruiseMissile then
    name="Cruise Missiles"
  elseif tnumber==ARTY.WeaponType.TacticalNukes then
    name="Tactical Nukes"
  elseif tnumber==ARTY.WeaponType.IlluminationShells then
    name="Illumination Shells"
  elseif tnumber==ARTY.WeaponType.SmokeShells then
    name="Smoke Shells"
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
  self:T3(self.lid..string.format("Vicinity distance = %d (rmin=%d, rmax=%d)", pops:Get2DDistance(coord), rmin, rmax))
  return pops
end

--- Print event-from-to string to DCS log file.
-- @param #ARTY self
-- @param #string BA Before/after info.
-- @param #string Event Event.
-- @param #string From From state.
-- @param #string To To state.
function ARTY:_EventFromTo(BA, Event, From, To)
  local text=string.format("%s: %s EVENT %s: %s --> %s", BA, self.groupname, Event, From, To)
  self:T3(self.lid..text)
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
-- @param #ARTY.Target target The target data.
-- @return #string name, prio, radius, nshells, engaged, maxengage, time, weapontype
function ARTY:_TargetInfo(target)
  local clock=tostring(self:_SecondsToClock(target.time))
  local weapon=self:_WeaponTypeName(target.weapontype)
  local _underfire=tostring(target.underfire)
  return string.format("%s: prio=%d, radius=%d, nshells=%d, engaged=%d/%d, weapontype=%s, time=%s, underfire=%s, attackgroup=%s",
  target.name, target.prio, target.radius, target.nshells, target.engaged, target.maxengage, weapon, clock,_underfire, tostring(target.attackgroup))
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

    if _ldms then

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
      self:T2(self.lid..text)

    end
  end

  -- Debug text.
  local text=string.format("\nLatitude  %s", tostring(_latitude))
  text=text..string.format("\nLongitude %s", tostring(_longitude))
  self:T2(self.lid..text)

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

  self:T3(self.lid..string.format("Clock %s = %d seconds", clock, seconds))
  return seconds
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
