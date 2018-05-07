-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - (R2.4) Control artillery units.
-- 
-- ===
-- 
-- ![Banner Image](..\Presentations\ARTY\ARTY_Main.png)
-- 
-- ====
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
-- * Finite state machine implementation. Mission designer can interact when certain events occur.
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: **[FlightControl](https://forums.eagle.ru/member.php?u=89536)**
-- 
-- ====
-- @module Arty

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
-- @field #number FullAmmo Full amount of all ammunition taking the number of alive units into account.
-- @field #number StatusInterval Update interval in seconds between status updates. Default 10 seconds.
-- @field #number WaitForShotTime Max time in seconds to wait until fist shot event occurs after target is assigned. If time is passed without shot, the target is deleted. Default is 300 seconds.
-- @field #table DCSdesc DCS descriptors of the ARTY group.
-- @field #string Type Type of the ARTY group.
-- @field #string DisplayName Extended type name of the ARTY group.
-- @field #number IniGroupStrength Inital number of units in the ARTY group.
-- @field #boolean IsArtillery If true, ARTY group has attribute "Artillery".
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
-- @field #number minrange Minimum firing range in kilometers. Targets closer than this distance are not engaged. Default 0.5 km.
-- @field #number maxrange Maximum firing range in kilometers. Targets further away than this distance are not engaged. Default 10000 km. 
-- @extends Core.Fsm#FSM_CONTROLLABLE

---# ARTY class, extends @{Core.Fsm#FSM_CONTROLLABLE}
--
-- The ARTY class enables mission designers easily to assign targets for artillery units. Since the implementation is based on a Finite State Model (FSM), the mission designer can
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
-- * *coord*: Coordinates of the target, given as @{Point#COORDINATE} object.
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
-- * @{#ARTY.SetShellTypes}(*tableofnames*): Defines the ammo types for unguided cannons. Default is *tableofnames*={"weapons.shells"}, i.e. **all** types of shells are counted.
-- * @{#ARTY.SetRocketTypes}(*tableofnames*): Defines the ammo types of unguided rockets. Default is *tableofnames*={"weapons.nurs"}, i.e. **all** types of rockets are counted.
-- * @{#ARTY.SetMissileTypes}(*tableofnames*): Defines the ammo types of guided missiles. Default is *tableofnames*={"weapons.missiles"}, i.e. **all** types of missiles are counted.
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
-- 
-- ## Assigning Moves
-- The ARTY group can be commanded to move. This is done by the @{#ARTY.AssignMoveCoord}(*coord*,*time*,*speed*,*onroad*,*cancel*,*name*) function.
-- With this multiple timed moves of the group can be scheduled easily. By default, these moves will only be executed if the group is state **CombatReady**.
-- 
-- ### Parameters
-- 
-- * *coord*: Coordinates where the group should move to given as @{Point#COORDINATE} object.
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
-- ## Fine Tuning
-- 
-- The mission designer has a few options to tailor the ARTY object according to his needs.
-- 
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
--     normandy:AssignTargetCoord(GROUP:FindByName("Red Targets 1"),  20, 300,   50, 1, "08:01:00", ARTY.WeaponType.CruiseMissile)
--     
--     -- Add target: prio=50, radius=300 m, number of shells=100, number of engagements=1, start time=08:15 hours, only use cannons during this attack.
--     normandy:AssignTargetCoord(GROUP:FindByName("Red Targets 1"),  50, 300, 100, 1, "08:15:00", ARTY.WeaponType.Cannon)
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
  Debug=true,
  targets={},
  moves={},
  currentTarget=nil,
  currentMove=nil,
  Nammo0=0,
  Nshells0=0,
  Nrockets0=0,
  Nmissiles0=0,
  FullAmmo=0,
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
  ammoshells={"weapons.shells"},
  ammorockets={"weapons.nurs"},
  ammomissiles={"weapons.missiles"},
  Nshots=0,
  minrange=500,
  maxrange=1000000,
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
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
ARTY.id="ARTY | "

--- Arty script version.
-- @field #number version
ARTY.version="0.8.9"

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
  
  -- DCS descriptors.
  self:T3(ARTY.id.."DCS descriptors for group "..group:GetName())
  for id,desc in pairs(self.DCSdesc) do
    self:T3({id=id, desc=desc})
  end
  
  -- Maximum speed in km/h.
  self.SpeedMax=self.DCSdesc.speedMax*3.6
  
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
  self:AddTransition("Rearming",                    "Move",        "Rearming")
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

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Assign target coordinates to the ARTY group. Only the first parameter, i.e. the coordinate of the target is mandatory. The remaining parameters are optional and can be used to fine tune the engagement.
-- @param #ARTY self
-- @param Wrapper.Point#COORDINATE coord Coordinates of the target.
-- @param #number prio (Optional) Priority of target. Number between 1 (high) and 100 (low). Default 50.
-- @param #number radius (Optional) Radius. Default is 100 m.
-- @param #number nshells (Optional) How many shells (or rockets) are fired on target per engagement. Default 5.
-- @param #number maxengage (Optional) How many times a target is engaged. Default 1.
-- @param #string time (Optional) Day time at which the target should be engaged. Passed as a string in format "08:13:45". Current task will be canceled.
-- @param #number weapontype (Optional) Type of weapon to be used to attack this target. Default ARTY.WeaponType.Auto, i.e. the DCS logic automatically determins the appropriate weapon.
-- @param #string name (Optional) Name of the target. Default is LL DMS coordinate of the target. If the name was already given, the numbering "#01", "#02",... is appended automatically.
-- @return #string Name of the target. Can be used for further reference, e.g. deleting the target from the list.
-- @usage paladin=ARTY:New(GROUP:FindByName("Blue Paladin"))
-- paladin:AssignTargetCoord(GROUP:FindByName("Red Targets 1"):GetCoordinate(), 10, 300, 10, 1, "08:02:00", ARTY.WeaponType.Auto, "Target 1")
-- paladin:Start()
function ARTY:AssignTargetCoord(coord, prio, radius, nshells, maxengage, time, weapontype, name)
  self:F({coord=coord, prio=prio, radius=radius, nshells=nshells, maxengage=maxengage, time=time, weapontype=weapontype, name=name})
  
  -- Set default values.
  nshells=nshells or 5
  radius=radius or 100
  maxengage=maxengage or 1
  prio=prio or 50
  prio=math.max(  1, prio)
  prio=math.min(100, prio)
  weapontype=weapontype or ARTY.WeaponType.Auto
  
  -- Name of the target.
  local _name=name or coord:ToStringLLDMS() 
    
  -- Check if the name has already been used for another target. If so, the function returns a new unique name.
  _name=self:_CheckName(self.targets, _name)
  
  -- Time in seconds.
  local _time=self:_ClockToSeconds(time)
  
  -- Prepare target array.
  local _target={name=_name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false, prio=prio, maxengage=maxengage, time=_time, weapontype=weapontype}
  
  -- Add to table.
  table.insert(self.targets, _target)
  
  -- Trigger new target event.
  self:NewTarget(_target)
  
  return _name
end

--- Assign coordinate to where the ARTY group should move.
-- @param #ARTY self
-- @param Wrapper.Point#COORDINATE coord Coordinates of the target.
-- @param #string time (Optional) Day time at which the group should start moving. Passed as a string in format "08:13:45".
-- @param #number speed (Optinal) Speed in km/h the group should move at. Default 50 km/h.
-- @param #boolean onroad (Optional) If true, group will mainly use roads. Default off, i.e. go directly towards the specified coordinate.
-- @param #boolean cancel (Optional) If true, cancel any running attack when move should begin. Default is false.
-- @param #string name (Optional) Name of the coordinate. Default is LL DMS string of the coordinate. If the name was already given, the numbering "#01", "#02",... is appended automatically.
-- @return #string Name of the move. Can be used for further reference, e.g. deleting the move from the list.
function ARTY:AssignMoveCoord(coord, time, speed, onroad, cancel, name)
  self:F({coord=coord, time=time, speed=speed, onroad=onroad, cancel=cancel, name=name})
  
    -- Name of the target.
  local _name=name or coord:ToStringLLDMS() 
    
  -- Check if the name has already been used for another target. If so, the function returns a new unique name.
  _name=self:_CheckName(self.moves, _name)
  
  -- Default is current time if no time was specified.
  time=time or self:_SecondsToClock(timer.getAbsTime())
  
  -- Default speed is 50 km/h.
  speed=speed or 50
  
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
  
end

--- Set minimum firing range. Targets closer than this distance are not engaged.
-- @param #ARTY self
-- @param #number range Min range in kilometers. Default is 0.5 km.
function ARTY:SetMinFiringRange(range)
  self:F({range=range})
  self.minrange=range*1000 or 500
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
-- @param Wrapper.Point#COORDINATE coord Coordinates of the rearming place.
function ARTY:SetRearmingPlace(coord)
  self:F({coord=coord})
  self.RearmingPlaceCoord=coord
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

--- Delete a target from target list.
-- @param #ARTY self
-- @param #string name Name of the target.
function ARTY:RemoveTarget(name)
  self:F2(name)
  local id=self:_GetTargetIndexByName(name)
  if id then
    self:T(ARTY.id..string.format("Group %s: Removing target %s (id=%d).", self.Controllable:GetName(), name, id))
    table.remove(self.targets, id)
  end
  self:T(ARTY.id..string.format("Group %s: Number of targets = %d.", self.Controllable:GetName(), #self.targets))
end

--- Delete a move from move list.
-- @param #ARTY self
-- @param #string name Name of the target.
function ARTY:RemoveMove(name)
  self:F2(name)
  local id=self:_GetMoveIndexByName(name)
  if id then
    self:T(ARTY.id..string.format("Group %s: Removing move %s (id=%d).", self.Controllable:GetName(), name, id))
    table.remove(self.moves, id)
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
  local text=string.format("Started ARTY for group %s.", Controllable:GetName())
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  
  -- Get Ammo.
  self.Nammo0, self.Nshells0, self.Nrockets0, self.Nmissiles0=self:GetAmmo(self.Debug)
  
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Arty group          = %s\n", Controllable:GetName())
  text=text..string.format("Artillery attribute = %s\n", tostring(self.IsArtillery))
  text=text..string.format("Type                = %s\n", self.Type)
  text=text..string.format("Display Name        = %s\n", self.DisplayName)  
  text=text..string.format("Number of units     = %d\n", self.IniGroupStrength)
  text=text..string.format("Speed max           = %d km/h\n", self.SpeedMax)
  text=text..string.format("Speed default       = %d km/h\n", self.Speed)
  text=text..string.format("Min range           = %d km\n", self.minrange/1000)
  text=text..string.format("Max range           = %d km\n", self.maxrange/1000)
  text=text..string.format("Total ammo count    = %d\n", self.Nammo0)
  text=text..string.format("Number of shells    = %d\n", self.Nshells0)
  text=text..string.format("Number of rockets   = %d\n", self.Nrockets0)
  text=text..string.format("Number of missiles  = %d\n", self.Nmissiles0)
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
  text=text..string.format("******************************************************\n")
  text=text..string.format("Targets:\n")
  for _, target in pairs(self.targets) do
    text=text..string.format("- %s\n", self:_TargetInfo(target))
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
  self:T(ARTY.id..text)
  
  -- Add event handler.
  self:HandleEvent(EVENTS.Shot, self._OnEventShot)
  self:HandleEvent(EVENTS.Dead, self._OnEventDead)
  
  -- Start checking status.
  self:__Status(self.StatusInterval)
end

--- After "Start" event. Initialized ROE and alarm state. Starts the event handler.
-- @param #ARTY self
function ARTY:_StatusReport()

  -- Get Ammo.
  local Nammo, Nshells, Nrockets, Nmissiles=self:GetAmmo()
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
  text=text..string.format("Moves:\n")
  for i=1,#self.moves do
    text=text..string.format("- %s\n", self:_MoveInfo(self.moves[i]))
  end
  text=text..string.format("******************************************************")
  env.info(ARTY.id..text)
  
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
        local text=string.format("Group %s fired shot %d of %d with weapon %s on target %s.", self.Controllable:GetName(), self.Nshots, self.currentTarget.nshells, _weaponName, self.currentTarget.name)
        self:T(ARTY.id..text)
        MESSAGE:New(text, 5):ToAllIf(self.Debug)
        
        -- Get current ammo.
        local _nammo,_nshells,_nrockets,_nmissiles=self:GetAmmo()
        
        if _nammo==0 then
        
          self:T(ARTY.id..string.format("Group %s completely out of ammo.", self.Controllable:GetName()))
          self:CeaseFire(self.currentTarget)
          self:Winchester()
          
          -- Current target is deallocated ==> return
          return
        end
        
        -- Weapon type name for current target.
        local _weapontype=self:_WeaponTypeName(self.currentTarget.weapontype)
        self:T(ARTY.id..string.format("nammo=%d, nshells=%d, nrockets=%d, nmissiles=%d", _nammo, _nshells, _nrockets, _nmissiles))
        self:T(ARTY.id..string.format("Weapontype = %s", _weapontype))        
        
        -- Special weapon type requested ==> Check if corresponding ammo is empty.
        if self.currentTarget.weapontype==ARTY.WeaponType.Cannon and _nshells==0 then
        
          self:T(ARTY.id.."Cannons requested but shells empty.")
          self:CeaseFire(self.currentTarget)
          return
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.Rockets and _nrockets==0 then

          self:T(ARTY.id.."Rockets requested but rockets empty.")
          self:CeaseFire(self.currentTarget)
          return
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.UnguidedAny and _nshells+_nrockets==0 then
        
          self:T(ARTY.id.."Unguided weapon requested but shells and rockets empty.")
          self:CeaseFire(self.currentTarget)
          return
        
        elseif (self.currentTarget.weapontype==ARTY.WeaponType.CruiseMissile or self.currentTarget.weapontype==ARTY.WeaponType.CruiseMissile) and _nmissiles==0 then
        
          self:T(ARTY.id.."Guided or Cruise missiles requested but all missiles empty.")
          self:CeaseFire(self.currentTarget)
          return
        end
       
        -- Check if number of shots reached max.
        if self.Nshots >= self.currentTarget.nshells then
          local text=string.format("Group %s stop firing on target %s.", self.Controllable:GetName(), self.currentTarget.name)
          self:T(ARTY.id..text)
          MESSAGE:New(text, 5):ToAllIf(self.Debug)
          
          -- Cease fire.
          self:CeaseFire(self.currentTarget)
        end
        
      else
        self:E(ARTY.id..string.format("ERROR: No current target?!"))
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
    env.info(string.format("FF: OutOfAmmo. ==> Rearm"))
    self:Rearm()
  end
  
  -- Group is out of moving.
  if self:is("Moving") then
    --local _speed=self.Controllable:GetVelocityKMH()
    --env.info(string.format("FF: Moving. Velocity = %d km/h", _speed))
    env.info(string.format("FF: Moving"))
  end
  
  -- Group is rearming.
  if self:is("Rearming") then
    local _rearmed=self:_CheckRearmed()
    env.info(string.format("FF: Rearming. _rearmed = %s", tostring(_rearmed)))
    if _rearmed then
      self:Rearmed()
    end
  end
  
  -- Group finished rearming.
  if self:is("Rearmed") then
    local distance=self.Controllable:GetCoordinate():Get2DDistance(self.InitialCoord)
    env.info(string.format("FF: Rearmed. Distance ARTY to InitalCoord = %d", distance))
    if distance <= self.RearmingDistance then
      self:CombatReady()
    end
  end
  
  -- Group arrived at destination.
  if self:is("Arrived") then
    env.info(string.format("FF: Arrived. ==> CombatReady"))
    self:CombatReady()
  end
  
  -- Group is firing on target.
  if self:is("Firing") then
    -- Check that firing started after ~5 min. If not, target is removed.
    self:_CheckShootingStarted()
  end


  -- Get a valid timed target if it is due to be attacked.  
  local _timedTarget=self:_CheckTimedTargets()
      
  -- Get a valid normal target (one that is not timed).
  local _normalTarget=self:_CheckNormalTargets()
  
  -- Get a commaned move to another location.
  local _move=self:_CheckMoves()

  -- Group is combat ready or firing but we have a high prio timed target.
  if (self:is("CombatReady") or self:is("Firing")) and _move then
  
    -- Command to move.
    self.currentMove=_move
    self:Move(_move.coord, _move.speed, _move.onroad)
  
  elseif self:is("CombatReady") or (self:is("Firing") and _timedTarget) then
    env.info(string.format("FF: Combatready or firing and high prio timed target."))
  
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
  self:T(string.format("FF: onenterComabReady, from=%s, event=%s, to=%s", From, Event, To))
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
  
  --local _coord=target.coord --Core.Point#COORDINATE  
  --_coord:MarkToAll("Arty Target")
    
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
  if self.WeaponType==ARTY.WeaponType.Auto then
    nfire=Nammo
    _type="shots"
  elseif self.WeaponType==ARTY.WeaponType.Cannon then
    nfire=Nshells
    _type="shells"
  elseif self.WeaponType==ARTY.WeaponType.Rockets then
    nfire=Nrockets
    _type="rockets"
  elseif self.WeaponType==ARTY.WeaponType.UnguidedAny then
    nfire=Nshells+Nrockets
    _type="shells or rockets"
  elseif self.WeaponType==ARTY.WeaponType.GuidedMissile then
    nfire=Nmissiles
    _type="missiles"
  elseif self.WeaponType==ARTY.WeaponType.CruiseMissile then
    nfire=Nmissiles
    _type="cruise missiles"
  end  
  
  -- Adjust if less than requested ammo is left.
  local _n=math.min(target.nshells, nfire)
    
  -- Send message.
  local text=string.format("%s, opening fire on target %s with %d %s. Distance %.1f km.", Controllable:GetName(), target.name, _n, _type, range/1000)
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report)
  
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
    
    -- Increase engaged counter
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
  MESSAGE:New(text, 30):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
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
        self:Move(self:_VicinityCoord(self.RearmingPlaceCoord, self.RearmingDistance/4, self.RearmingDistance/2), self.Speed, self.RearmingArtyOnRoad)
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
        self:Move(self:_VicinityCoord(self.RearmingPlaceCoord), self.Speed, self.RearmingArtyOnRoad)
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
  
  -- Route ARTY group back to where it came from (if distance is > 100 m).
  local d1=self.Controllable:GetCoordinate():Get2DDistance(self.InitialCoord)
  if d1 > self.RearmingDistance then
    self:Move(self.InitialCoord, self.Speed, self.RearmingArtyOnRoad)
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
-- @param Wrapper.Point#COORDINATE ToCoord Coordinate to which the ARTY group should move.
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
  --MESSAGE:New(text, 30):ToAllIf(self.Debug)
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
  MESSAGE:New(text, 30):ToAllIf(self.Debug)
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
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
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

  -- Set ROE to weapon free.
  group:OptionROEOpenFire()
  
  -- Get Vec2
  local vec2=coord:GetVec2()
  
  -- Get task.
  local fire=group:TaskFireAtPoint(vec2, radius, nshells, weapontype)
  
  -- Execute task.
  group:SetTask(fire)
end



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
        
        self:T2(ARTY.id..string.format("Number of weapons %d.", weapons))
        self:T2({ammotable=ammotable})
        
        -- Loop over all weapons.
        for w=1,weapons do
        
          -- Number of current weapon.
          local Nammo=ammotable[w]["count"]
          
          -- Typename of current weapon
          local Tammo=ammotable[w]["desc"]["typeName"]
          
          -- Check for correct shell type.
          local _gotshell=false
          for _,_type in pairs(self.ammoshells) do
            if string.match(Tammo, _type) then
              _gotshell=true
            end
          end

          -- Check for correct rocket type.
          local _gotrocket=false
          for _,_type in pairs(self.ammorockets) do
            if string.match(Tammo, _type) then
              _gotrocket=true
            end
          end

          -- Check for correct missile type.
          local _gotmissile=false
          for _,_type in pairs(self.ammomissiles) do
            if string.match(Tammo,_type) then
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
          
            -- Add up all rockets.
            nmissiles=nmissiles+Nammo
            
            -- Debug info.
            text=text..string.format("- %d missiles of type %s\n", name, Nammo, Tammo)
                                
          else
          
            -- Debug info.
            text=text..string.format("- %d unknown ammo of type %s\n", Nammo, Tammo)
            
          end
          
        end
      end

      -- Debug text and send message.
      self:T2(ARTY.id..text)
      MESSAGE:New(text, 10):ToAllIf(display)
               
    end
  end
      
  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles
  
  return nammo, nshells, nrockets, nmissiles
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
    if targetname==name then
      self:T2(ARTY.id..string.format("Found target with name %s. Index = %d", name, i))
      return i
    end
  end
  
  self:E(ARTY.id..string.format("ERROR: Target with name %s could not be found!", name))
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
    if movename==name then
      self:T2(ARTY.id..string.format("Found move with name %s. Index = %d", name, i))
      return i
    end
  end
  
  self:E(ARTY.id..string.format("ERROR: Move with name %s could not be found!", name))
  return nil
end



--- Check if a name is unique. If not, a new unique name is created by adding a running index #01, #02, ...
-- @param #ARTY self
-- @param #table givennames Table with entries of already given names. Must contain a .name item.
-- @param #string name Desired name.
-- @return #string Unique name, which is not already given for another target.
function ARTY:_CheckName(givennames, name)
  self:F2({givennames=givennames, name=name})  

  local newname=name
  local counter=1
  
  repeat
    -- We assume the name is unique.
    local unique=true
    
    -- Loop over all targets already defined.
    for _,_target in pairs(givennames) do
    
      -- Target name.
      local _givenname=givennames.name
      
      if _givenname==newname then
        -- Define new name = "name #01"
        newname=string.format("%s #%02d", name, counter)
        
        -- Increase counter.
        counter=counter+1
        
        -- Name is already used for another target ==> try again with new name.
        unique=false
      end      
    end
    
  until (unique)
  
  -- Debug output and return new name.
  self:T(string.format("Original name %s, new name = %s", name, newname))
  return newname
end

--- Check if target is in range.
-- @param #ARTY self
-- @param #table target Target table.
-- @return #boolean True if target is in range, false otherwise.
function ARTY:_TargetInRange(target)
  self:F3(target)

  -- Distance between ARTY group and target.
  local _dist=self.Controllable:GetCoordinate():Get2DDistance(target.coord)
  
  -- Assume we are in range.
  local _inrange=true
  local text=""
  
  if _dist < self.minrange then
    _inrange=false
    text=string.format("%s, target is out of range. Distance of %.1f km is below min range of %.1f km.", self.Controllable:GetName(), _dist/1000, self.minrange/1000)
  elseif _dist > self.maxrange then
    _inrange=false
    text=string.format("%s, target is out of range. Distance of %.1f km is greater than max range of %.1f km.", self.Controllable:GetName(), _dist/1000, self.maxrange/1000)
  end
  
  -- Debug output.
  if not _inrange then
    self:T(ARTY.id..text)
    MESSAGE:New(text, 10):ToCoalitionIf(self.Controllable:GetCoalition(), self.report or self.Debug)
  end
    
  -- Remove target if ARTY group cannot move. No change to be ever in range.
  if self.Speed==0 then
    self:RemoveTarget(target.name)
  end

  return _inrange
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
  self:T(ARTY.id..string.format("Vicinity distance = %d (rmin=%d, rmax=%d)", pops:Get2DDistance(coord), rmin, rmax))
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

--- Route group to a certain point.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group to route.
-- @param Core.Point#COORDINATE ToCoord Coordinate where we want to go.
-- @param #number Speed Speed in km/h.
-- @param #boolean OnRoad If true, use (mainly) roads.
function ARTY:_Move(group, ToCoord, Speed, OnRoad)
  
  -- Clear all tasks.
  group:ClearTasks()
  group:OptionAlarmStateGreen()
  group:OptionROEHoldFire()
  
  -- Set formation.
  local formation = "Off road"
  
  -- Default speed is 30 km/h.
  Speed=Speed or 30
  
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

    local _first=cpini:GetClosestPointToRoad()
    local _last=ToCoord:GetClosestPointToRoad()
    local _onroad=_first:GetPathOnRoad(_last)
    
    -- Points on road.
    for i=1,#_onroad do
      path[#path+1]=_onroad[i]:WaypointGround(Speed, "On road")
      task[#task+1]=group:TaskFunction("ARTY._PassingWaypoint", self, #path-1, false)
    end
     
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
  env.info(ARTY.id..text)
  if final then
    MESSAGE:New(text, 10):ToCoalitionIf(group:GetCoalition(), arty.Debug or arty.report)
  else
    MESSAGE:New(text, 10):ToAllIf(arty.Debug)
  end
  
  -- Arrived event.
  if final and arty.Controllable:GetName()==group:GetName() then
    arty:Arrived()
  end

end
  