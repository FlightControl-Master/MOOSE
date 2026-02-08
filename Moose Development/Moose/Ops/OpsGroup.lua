--- **Ops** - Generic group enhancement.
--
-- This class is **not** meant to be used itself by the end user. It contains common functionalities of derived classes for air, ground and sea.
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module Ops.OpsGroup
-- @image OPS_OpsGroup.png


--- OPSGROUP class.
-- @type OPSGROUP
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level. 0=silent.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string groupname Name of the group.
-- @field Wrapper.Group#GROUP group Group object.
-- @field DCS#Group dcsgroup The DCS group object.
-- @field DCS#Controller controller The DCS controller of the group.
-- @field DCS#Template template Template table of the group.
-- @field #table elements Table of elements, i.e. units of the group.
-- @field #boolean isLateActivated Is the group late activated.
-- @field #boolean isUncontrolled Is the group uncontrolled.
-- @field #boolean isFlightgroup Is a FLIGHTGROUP.
-- @field #boolean isArmygroup Is an ARMYGROUP.
-- @field #boolean isNavygroup Is a NAVYGROUP.
-- @field #boolean isHelo If true, this is a helicopter group.
-- @field #boolean isVTOL If true, this is capable of Vertical TakeOff and Landing (VTOL).
-- @field #boolean isSubmarine If true, this is a submarine group.
-- @field #boolean isAI If true, group is purely AI.
-- @field #boolean isDestroyed If true, the whole group was destroyed.
-- @field #boolean isDead If true, the whole group is dead.
-- @field #table waypoints Table of waypoints.
-- @field #table waypoints0 Table of initial waypoints.
-- @field #boolean useMEtasks If `true`, use tasks set in the ME. Default `false`.
-- @field Wrapper.Airbase#AIRBASE homebase The home base of the flight group.
-- @field Wrapper.Airbase#AIRBASE destbase The destination base of the flight group.
-- @field Wrapper.Airbase#AIRBASE currbase The current airbase of the flight group, i.e. where it is currently located or landing at.
-- @field Core.Zone#ZONE homezone The home zone of the flight group. Set when spawn happens in air.
-- @field Core.Zone#ZONE destzone The destination zone of the flight group. Set when final waypoint is in air.
-- @field #number currentwp Current waypoint index. This is the index of the last passed waypoint.
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @field #number Twaiting Abs. mission time stamp when the group was ordered to wait.
-- @field #number dTwait Time to wait in seconds. Default `nil` (for ever).
-- @field #table taskqueue Queue of tasks.
-- @field #number taskcounter Running number of task ids.
-- @field #number taskcurrent ID of current task. If 0, there is no current task assigned.
-- @field #table taskenroute Enroute task of the group.
-- @field #table taskpaused Paused tasks.
-- @field #table missionqueue Queue of missions.
-- @field #number currentmission The ID (auftragsnummer) of the currently assigned AUFTRAG.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
-- @field Core.Set#SET_GROUP detectedgroups Set of detected groups.
-- @field #string attribute Generalized attribute.
-- @field #number speedMax Max speed in km/h.
-- @field #number speedCruise Cruising speed in km/h.
-- @field #number speedWp Speed to the next waypoint in m/s.
-- @field #boolean isMobile If `true`, group is mobile (speed > 1 m/s)
-- @field #boolean passedfinalwp Group has passed the final waypoint.
-- @field #number wpcounter Running number counting waypoints.
-- @field Core.Set#SET_ZONE checkzones Set of zones.
-- @field Core.Set#SET_ZONE inzones Set of zones in which the group is currently in.
-- @field Core.Timer#TIMER timerStatus Timer for status update.
-- @field Core.Timer#TIMER timerCheckZone Timer for check zones.
-- @field Core.Timer#TIMER timerQueueUpdate Timer for queue updates.
-- @field #boolean groupinitialized If true, group parameters were initialized.
-- @field #boolean detectionOn If true, detected units of the group are analyzed.
-- @field #table pausedmissions Paused missions.
-- @field #number Ndestroyed Number of destroyed units.
-- @field #number Nkills Number kills of this groups.
-- @field #number Nhit Number of hits taken.
--
-- @field #boolean rearmOnOutOfAmmo If `true`, group will go to rearm once it runs out of ammo.
--
-- @field Ops.Legion#LEGION legion Legion the group belongs to.
-- @field Ops.Cohort#COHORT cohort Cohort the group belongs to.
--
-- @field Core.Point#COORDINATE coordinate Current coordinate.
--
-- @field DCS#Vec3 position Position of the group at last status check.
-- @field DCS#Vec3 positionLast Backup of last position vec to monitor changes.
-- @field #number heading Heading of the group at last status check.
-- @field #number headingLast Backup of last heading to monitor changes.
-- @field DCS#Vec3 orientX Orientation at last status check.
-- @field DCS#Vec3 orientXLast Backup of last orientation to monitor changes.
-- @field #number traveldist Distance traveled in meters. This is a lower bound.
-- @field #number traveltime Time.
--
-- @field Core.Astar#ASTAR Astar path finding.
-- @field #boolean ispathfinding If true, group is on pathfinding route.
--
-- @field #boolean engagedetectedOn If `true`, auto engage detected targets.
-- @field #number engagedetectedRmax Max range in NM. Only detected targets within this radius from the group will be engaged. Default is 25 NM.
-- @field #table engagedetectedTypes Types of target attributes that will be engaged. See [DCS enum attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes). Default "All".
-- @field Core.Set#SET_ZONE engagedetectedEngageZones Set of zones in which targets are engaged. Default is anywhere.
-- @field Core.Set#SET_ZONE engagedetectedNoEngageZones Set of zones in which targets are *not* engaged. Default is nowhere.
--
-- @field #OPSGROUP.Radio radio Current radio settings.
-- @field #OPSGROUP.Radio radioDefault Default radio settings.
-- @field Sound.Radio#RADIOQUEUE radioQueue Radio queue.
--
-- @field #OPSGROUP.Beacon tacan Current TACAN settings.
-- @field #OPSGROUP.Beacon tacanDefault Default TACAN settings.
--
-- @field #OPSGROUP.Beacon icls Current ICLS settings.
-- @field #OPSGROUP.Beacon iclsDefault Default ICLS settings.
--
-- @field #OPSGROUP.Option option Current optional settings.
-- @field #OPSGROUP.Option optionDefault Default option settings.
--
-- @field #OPSGROUP.Callsign callsign Current callsign settings.
-- @field #OPSGROUP.Callsign callsignDefault Default callsign settings.
-- @field #string callsignName Callsign name.
-- @field #string callsignAlias Callsign alias.
--
-- @field #OPSGROUP.Spot spot Laser and IR spot.
-- 
-- @field DCS#Vec3 stuckVec3 Position where the group got stuck.
-- @field #number stuckTimestamp Time stamp [sec], when the group got stuck.
-- @field #boolean stuckDespawn If `true`, group gets despawned after beeing stuck for a certain time.
--
-- @field #OPSGROUP.Ammo ammo Initial ammount of ammo.
-- @field #OPSGROUP.WeaponData weaponData Weapon data table with key=BitType.
--
-- @field #OPSGROUP.Element carrier Carrier the group is loaded into as cargo.
-- @field #OPSGROUP carrierGroup Carrier group transporting this group as cargo.
-- @field #OPSGROUP.MyCarrier mycarrier Carrier group for this group.
-- @field #table cargoqueue Table containing cargo groups to be transported.
-- @field #table cargoBay Table containing OPSGROUP loaded into this group.
-- @field Ops.OpsTransport#OPSTRANSPORT cargoTransport Current cargo transport assignment.
-- @field Ops.OpsTransport#OPSTRANSPORT.TransportZoneCombo cargoTZC Transport zone combo (pickup, deploy etc.) currently used.
-- @field #string cargoStatus Cargo status of this group acting as cargo.
-- @field #number cargoTransportUID Unique ID of the transport assignment this cargo group is associated with.
-- @field #string carrierStatus Carrier status of this group acting as cargo carrier.
-- @field #OPSGROUP.CarrierLoader carrierLoader Carrier loader parameters.
-- @field #OPSGROUP.CarrierLoader carrierUnloader Carrier unloader parameters.
--
-- @field #boolean useSRS Use SRS for transmissions.
-- @field Sound.SRS#MSRS msrs MOOSE SRS wrapper.
--
-- @extends Core.Fsm#FSM

--- *A small group of determined and like-minded people can change the course of history.* -- Mahatma Gandhi
--
-- ===
--
-- # The OPSGROUP Concept
--
-- The OPSGROUP class contains common functions used by other classes such as FLIGHTGROUP, NAVYGROUP and ARMYGROUP.
-- Those classes inherit everything of this class and extend it with features specific to their unit category.
--
-- This class is **NOT** meant to be used by the end user itself.
--
--
-- @field #OPSGROUP
OPSGROUP = {
  ClassName          = "OPSGROUP",
  verbose            =     0,
  lid                =   nil,
  groupname          =   nil,
  group              =   nil,
  template           =   nil,
  isLateActivated    =   nil,
  waypoints          =   nil,
  waypoints0         =   nil,
  currentwp          =     1,
  elements           =    {},
  taskqueue          =    {},
  taskcounter        =   nil,
  taskcurrent        =   nil,
  taskenroute        =   nil,
  taskpaused         =    {},
  missionqueue       =    {},
  currentmission     =   nil,
  detectedunits      =    {},
  detectedgroups     =    {},
  attribute          =   nil,
  checkzones         =   nil,
  inzones            =   nil,
  groupinitialized   =   nil,
  wpcounter          =     1,
  radio              =    {},
  option             =    {},
  optionDefault      =    {},
  tacan              =    {},
  icls               =    {},
  callsign           =    {},
  Ndestroyed         =     0,
  Nkills             =     0,
  Nhit               =     0,
  weaponData         =    {},
  cargoqueue         =    {},
  cargoBay           =    {},
  mycarrier          =    {},
  carrierLoader      =    {},
  carrierUnloader    =    {},
  useMEtasks         = false,
  pausedmissions     =    {},
}


--- OPS group element.
-- @type OPSGROUP.Element
-- @field #string name Name of the element, i.e. the unit.
-- @field #string status The element status. See @{#OPSGROUP.ElementStatus}.
-- @field Wrapper.Unit#UNIT unit The UNIT object.
-- @field Wrapper.Group#GROUP group The GROUP object.
-- @field DCS#Unit DCSunit The DCS unit object.
-- @field DCS#Controller controller The DCS controller of the unit.
-- @field #boolean ai If true, element is AI.
-- @field #string skill Skill level.
-- @field #string playerName Name of player if this is a client.
-- @field #number Nhit Number of times the element was hit.
-- @field #boolean engineOn If `true`, engines were started.
--
-- @field Core.Zone#ZONE_POLYGON_BASE zoneBoundingbox Bounding box zone of the element unit.
-- @field Core.Zone#ZONE_POLYGON_BASE zoneLoad Loading zone.
-- @field Core.Zone#ZONE_POLYGON_BASE zoneUnload Unloading zone.
--
-- @field #string typename Type name.
-- @field #number category Aircraft category.
-- @field #string categoryname Aircraft category name.
--
-- @field #number size Size (max of length, width, height) in meters.
-- @field #number length Length of element in meters.
-- @field #number width Width of element in meters.
-- @field #number height Height of element in meters.
--
-- @field DCS#Vec3 vec3 Last known 3D position vector.
-- @field DCS#Vec3 orientX Last known ordientation vector in the direction of the nose X.
-- @field #number heading Last known heading in degrees.
--
-- @field #number life0 Initial life points.
-- @field #number life Life points when last updated.
-- @field #number damage Damage of element in percent.
--
-- @field DCS#Object.Desc descriptors Descriptors table.
-- @field #number weightEmpty Empty weight in kg.
-- @field #number weightMaxTotal Max. total weight in kg.
-- @field #number weightMaxCargo Max. cargo weight in kg.
-- @field #number weightCargo Current cargo weight in kg.
-- @field #number weight Current weight including cargo in kg.
-- @field #table cargoBay Cargo bay.
--
-- @field #string modex Tail number.
-- @field Wrapper.Client#CLIENT client The client if element is occupied by a human player.
-- @field #table pylons Table of pylons.
-- @field #number fuelmass Mass of fuel in kg.
-- @field #string callsign Call sign, e.g. "Uzi 1-1".
-- @field Wrapper.Airbase#AIRBASE.ParkingSpot parking The parking spot table the element is parking on.


--- Status of group element.
-- @type OPSGROUP.ElementStatus
-- @field #string INUTERO Element was not spawned yet or its status is unknown so far.
-- @field #string SPAWNED Element was spawned into the world.
-- @field #string PARKING Element is parking after spawned on ramp.
-- @field #string ENGINEON Element started its engines.
-- @field #string TAXIING Element is taxiing after engine startup.
-- @field #string TAKEOFF Element took of after takeoff event.
-- @field #string AIRBORNE Element is airborne. Either after takeoff or after air start.
-- @field #string LANDING Element is landing.
-- @field #string LANDED Element landed and is taxiing to its parking spot.
-- @field #string ARRIVED Element arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
OPSGROUP.ElementStatus={
  INUTERO="InUtero",
  SPAWNED="Spawned",
  PARKING="Parking",
  ENGINEON="Engine On",
  TAXIING="Taxiing",
  TAKEOFF="Takeoff",
  AIRBORNE="Airborne",
  LANDING="Landing",
  LANDED="Landed",
  ARRIVED="Arrived",
  DEAD="Dead",
}

--- Status of group.
-- @type OPSGROUP.GroupStatus
-- @field #string INUTERO Not spawned yet or its status is unknown so far.
-- @field #string PARKING Parking after spawned on ramp.
-- @field #string TAXIING Taxiing after engine startup.
-- @field #string AIRBORNE Element is airborne. Either after takeoff or after air start.
-- @field #string LANDING Landing.
-- @field #string LANDED Landed and is taxiing to its parking spot.
-- @field #string ARRIVED Arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
OPSGROUP.GroupStatus={
  INUTERO="InUtero",
  PARKING="Parking",
  TAXIING="Taxiing",
  AIRBORNE="Airborne",
  INBOUND="Inbound",
  LANDING="Landing",
  LANDED="Landed",
  ARRIVED="Arrived",
  DEAD="Dead",
}

--- Ops group task status.
-- @type OPSGROUP.TaskStatus
-- @field #string SCHEDULED Task is scheduled.
-- @field #string EXECUTING Task is being executed.
-- @field #string PAUSED Task is paused.
-- @field #string DONE Task is done.
OPSGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  PAUSED="paused",
  DONE="done",
}

--- Ops group task status.
-- @type OPSGROUP.TaskType
-- @field #string SCHEDULED Task is scheduled and will be executed at a given time.
-- @field #string WAYPOINT Task is executed at a specific waypoint.
OPSGROUP.TaskType={
  SCHEDULED="scheduled",
  WAYPOINT="waypoint",
}

--- Task structure.
-- @type OPSGROUP.Task
-- @field #string type Type of task: either SCHEDULED or WAYPOINT.
-- @field #boolean ismission This is an AUFTRAG task.
-- @field #number id Task ID. Running number to get the task.
-- @field #number prio Priority.
-- @field #number time Abs. mission time when to execute the task.
-- @field #table dcstask DCS task structure.
-- @field #string description Brief text which describes the task.
-- @field #string status Task status.
-- @field #number duration Duration before task is cancelled in seconds. Default never.
-- @field #number timestamp Abs. mission time, when task was started.
-- @field #number waypoint Waypoint index if task is a waypoint task.
-- @field Core.UserFlag#USERFLAG stopflag If flag is set to 1 (=true), the task is stopped.
-- @field #number backupROE Rules of engagement that are restored once the task is over.
-- @field Ops.Target#TARGET target Target object.

--- Option data.
-- @type OPSGROUP.Option
-- @field #number ROE Rule of engagement.
-- @field #number ROT Reaction on threat.
-- @field #number Alarm Alarm state.
-- @field #number Formation Formation.
-- @field #boolean EPLRS data link.
-- @field #boolean Disperse Disperse under fire.
-- @field #boolean Emission Emission on/off.
-- @field #boolean Invisible Invisible on/off.
-- @field #boolean Immortal Immortal on/off.

--- Beacon data.
-- @type OPSGROUP.Beacon
-- @field #number Channel Channel.
-- @field #number Morse Morse Code.
-- @field #string Band Band "X" or "Y" for TACAN beacon.
-- @field #string BeaconName Name of the unit acting as beacon.
-- @field Wrapper.Unit#UNIT BeaconUnit Unit object acting as beacon.
-- @field #boolean On If true, beacon is on, if false, beacon is turned off. If nil, has not been used yet.

--- Radio data.
-- @type OPSGROUP.Radio
-- @field #number Freq Frequency
-- @field #number Modu Modulation.
-- @field #boolean On If true, radio is on, if false, radio is turned off. If nil, has not been used yet.

--- Callsign data.
-- @type OPSGROUP.Callsign
-- @field #number NumberSquad Squadron number corresponding to a name like "Uzi".
-- @field #number NumberGroup Group number. First number after name, e.g. "Uzi-**1**-1".
-- @field #string NameSquad Name of the squad, e.g. "Uzi".

--- Weapon range data.
-- @type OPSGROUP.WeaponData
-- @field #number BitType Type of weapon.
-- @field #number RangeMin Min range in meters.
-- @field #number RangeMax Max range in meters.
-- @field #number ReloadTime Time to reload in seconds.

--- Laser and IR spot data.
-- @type OPSGROUP.Spot
-- @field #boolean CheckLOS If true, check LOS to target.
-- @field #boolean IRon If true, turn IR pointer on.
-- @field #number dt Update time interval in seconds.
-- @field DCS#Spot Laser Laser spot.
-- @field DCS#Spot IR Infra-red spot.
-- @field #number Code Laser code.
-- @field Wrapper.Group#GROUP TargetGroup The target group.
-- @field Wrapper.Positionable#POSITIONABLE TargetUnit The current target unit.
-- @field Core.Point#COORDINATE Coordinate where the spot is pointing.
-- @field #number TargetType Type of target: 0=coordinate, 1=static, 2=unit, 3=group.
-- @field #boolean On If true, the laser is on.
-- @field #boolean Paused If true, laser is paused.
-- @field #boolean lostLOS If true, laser lost LOS.
-- @field #OPSGROUP.Element element The element of the group that is lasing.
-- @field DCS#Vec3 vec3 The 3D positon vector of the laser (and IR) spot.
-- @field DCS#Vec3 offset Local offset of the laser source.
-- @field DCS#Vec3 offsetTarget Offset of the target.
-- @field Core.Timer#TIMER timer Spot timer.

--- Ammo data.
-- @type OPSGROUP.Ammo
-- @field #number Total Total amount of ammo.
-- @field #number Shells Amount of shells (guns + cannons).
-- @field #number Guns Amount of gun shells (caliber < 25).
-- @field #number Cannons Amount of cannon shells (caliber >= 25).
-- @field #number Bombs Amount of bombs.
-- @field #number Rockets Amount of rockets.
-- @field #number Torpedos Amount of torpedos.
-- @field #number Missiles Amount of missiles.
-- @field #number MissilesAA Amount of air-to-air missiles.
-- @field #number MissilesAG Amount of air-to-ground missiles.
-- @field #number MissilesAS Amount of anti-ship missiles.
-- @field #number MissilesCR Amount of cruise missiles.
-- @field #number MissilesBM Amount of ballistic missiles.
-- @field #number MissilesSA Amount of surfe-to-air missiles.

--- Spawn point data.
-- @type OPSGROUP.Spawnpoint
-- @field Core.Point#COORDINATE Coordinate Coordinate where to spawn
-- @field Wrapper.Airbase#AIRBASE Airport Airport where to spawn.
-- @field #table TerminalIDs Terminal IDs, where to spawn the group. It is a table of `#number`s because a group can consist of multiple units.

--- Waypoint data.
-- @type OPSGROUP.Waypoint
-- @field #number uid Waypoint's unit id, which is a running number.
-- @field #number speed Speed in m/s.
-- @field #number alt Altitude in meters. For submaries use negative sign for depth.
-- @field #string action Waypoint action (turning point, etc.). Ground groups have the formation here.
-- @field #table task Waypoint DCS task combo.
-- @field #string type Waypoint type.
-- @field #string name Waypoint description. Shown in the F10 map.
-- @field #number x Waypoint x-coordinate.
-- @field #number y Waypoint y-coordinate.
-- @field #number detour Signifies that this waypoint is not part of the normal route: 0=Hold, 1=Resume Route.
-- @field #boolean intowind If true, this waypoint is a turn into wind route point.
-- @field #boolean astar If true, this waypint was found by A* pathfinding algorithm.
-- @field #boolean temp If true, this is a temporary waypoint and will be deleted when passed. Also the passing waypoint FSM event is not triggered.
-- @field #number npassed Number of times a groups passed this waypoint.
-- @field Core.Point#COORDINATE coordinate Waypoint coordinate.
-- @field Core.Point#COORDINATE roadcoord Closest point to road.
-- @field #number roaddist Distance to closest point on road.
-- @field Wrapper.Marker#MARKER marker Marker on the F10 map.
-- @field #string formation Ground formation. Similar to action but on/off road.
-- @field #number missionUID Mission UID (Auftragsnr) this waypoint belongs to.

--- Cargo Carrier status.
-- @type OPSGROUP.CarrierStatus
-- @field #string NOTCARRIER This group is not a carrier yet.
-- @field #string PICKUP Carrier is on its way to pickup cargo.
-- @field #string LOADING Carrier is loading cargo.
-- @field #string LOADED Carrier has loaded cargo.
-- @field #string TRANSPORTING Carrier is transporting cargo.
-- @field #string UNLOADING Carrier is unloading cargo.
OPSGROUP.CarrierStatus={
  NOTCARRIER="not carrier",
  PICKUP="pickup",
  LOADING="loading",
  LOADED="loaded",
  TRANSPORTING="transporting",
  UNLOADING="unloading",
}

--- Cargo status.
-- @type OPSGROUP.CargoStatus
-- @field #string AWAITING Group is awaiting carrier.
-- @field #string NOTCARGO This group is no cargo yet.
-- @field #string ASSIGNED Cargo is assigned to a carrier. (Not used!)
-- @field #string BOARDING Cargo is boarding a carrier.
-- @field #string LOADED Cargo is loaded into a carrier.
OPSGROUP.CargoStatus={
  AWAITING="Awaiting carrier",
  NOTCARGO="not cargo",
  ASSIGNED="assigned to carrier",
  BOARDING="boarding",
  LOADED="loaded",
}

--- Cargo carrier loader parameters.
-- @type OPSGROUP.CarrierLoader
-- @field #string type Loader type "Front", "Back", "Left", "Right", "All".
-- @field #number length Length of (un-)loading zone in meters.
-- @field #number width Width of (un-)loading zone in meters.

--- Data of the carrier that has loaded this group.
-- @type OPSGROUP.MyCarrier
-- @field #OPSGROUP group The carrier group.
-- @field #OPSGROUP.Element element The carrier element.
-- @field #boolean reserved If `true`, the carrier has caro space reserved for me.

--- Element cargo bay data.
-- @type OPSGROUP.MyCargo
-- @field #OPSGROUP group The cargo group.
-- @field #number storageType Type of storage.
-- @field #number storageAmount Amount of storage.
-- @field #number storageWeight Weight of storage item.
-- @field #boolean reserved If `true`, the cargo bay space is reserved but cargo has not actually been loaded yet.

--- Cargo group data.
-- @type OPSGROUP.CargoGroup
-- @field #number uid Unique ID of this cargo data.
-- @field #string type Type of cargo: "OPSGROUP" or "STORAGE".
-- @field #OPSGROUP opsgroup The cargo opsgroup.
-- @field Ops.OpsTransport#OPSTRANSPORT.Storage storage Storage data.
-- @field #boolean delivered If `true`, group was delivered.
-- @field #boolean disembarkActivation If `true`, group is activated. If `false`, group is late activated.
-- @field Core.Zone#ZONE disembarkZone Zone where this group is disembarked to.
-- @field Core.Set#SET_OPSGROUP disembarkCarriers Carriers where this group is directly disembared to.
-- @field #string status Status of the cargo group. Not used yet.

--- OpsGroup version.
-- @field #string version
OPSGROUP.version="1.0.5"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: AI on/off.
-- TODO: F10 menu.
-- TODO: Add pseudo function.
-- TODO: Afterburner restrict.
-- TODO: What more options?
-- TODO: Shot events?
-- TODO: Marks to add waypoints/tasks on-the-fly.
-- DONE: Invisible/immortal.
-- DONE: Emission on/off
-- DONE: Damage?
-- DONE: Options EPLRS

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSGROUP class object.
-- @param #OPSGROUP self
-- @param Wrapper.Group#GROUP group The GROUP object. Can also be given by its group name as `#string`.
-- @return #OPSGROUP self
function OPSGROUP:New(group)
    
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPSGROUP

  -- Get group and group name.
  if type(group)=="string" then
    self.groupname=group
    self.group=GROUP:FindByName(self.groupname)
  else
    self.group=group
    self.groupname=group:GetName()
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSGROUP %s | ", tostring(self.groupname))

  -- Check if group exists.
  if self.group then
    if not self:IsExist() then
      self:E(self.lid.."ERROR: GROUP does not exist! Returning nil")
      return nil
    end
  end
  
  if UTILS.IsInstanceOf(group,"OPSGROUP") then
    self:E(self.lid.."ERROR: GROUP is already an OPSGROUP: "..tostring(self.groupname).."!")
    return group
  end

  -- Set the template.
  self:_SetTemplate()

  -- Set DCS group and controller.
  self.dcsgroup=self:GetDCSGroup()
  self.controller=self.dcsgroup:getController()

  -- Category.
  self.category=self.dcsgroup:getCategory()
  if self.category==Group.Category.GROUND then
    self.isArmygroup=true
  elseif self.category==Group.Category.TRAIN then
    self.isArmygroup=true
    self.isTrain=true
  elseif self.category==Group.Category.SHIP then
    self.isNavygroup=true
  elseif self.category==Group.Category.AIRPLANE then
    self.isFlightgroup=true
  elseif self.category==Group.Category.HELICOPTER then
    self.isFlightgroup=true
    self.isHelo=true
  else

  end
  
  -- Set gen attribute.
  self.attribute=self.group:GetAttribute()

  local units=self.group:GetUnits()

  if units then
    local masterunit=units[1] --Wrapper.Unit#UNIT
    
    if masterunit then
      -- Get Descriptors.
      self.descriptors=masterunit:GetDesc()
  
      -- Set type name.
      self.actype=masterunit:GetTypeName()
  
      -- Is this a submarine.
      self.isSubmarine=masterunit:HasAttribute("Submarines")
  
      -- Has this a datalink?
      self.isEPLRS=masterunit:HasAttribute("Datalink")
  
      if self:IsFlightgroup() then
  
        self.rangemax=self.descriptors.range and self.descriptors.range*1000 or 500*1000
  
        self.ceiling=self.descriptors.Hmax
  
        self.tankertype=select(2, masterunit:IsTanker())
        self.refueltype=select(2, masterunit:IsRefuelable())
  
        --env.info("DCS Unit BOOM_AND_RECEPTACLE="..tostring(Unit.RefuelingSystem.BOOM_AND_RECEPTACLE))
        --env.info("DCS Unit PROBE_AND_DROGUE="..tostring(Unit.RefuelingSystem.PROBE_AND_DROGUE))
  
      end
    end
  end

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()

  -- Init set of detected groups.
  self.detectedgroups=SET_GROUP:New()

  -- Init inzone set.
  self.inzones=SET_ZONE:New()

  -- Set Default altitude.
  self:SetDefaultAltitude()
  
  -- Group will return to its legion when done.
  self:SetReturnToLegion()

  -- Laser.
  self.spot={}
  self.spot.On=false
  self.spot.timer=TIMER:New(self._UpdateLaser, self)
  self.spot.Coordinate=COORDINATE:New(0, 0, 0)
  self:SetLaser(1688, true, false, 0.5)

  -- Cargo.
  self.cargoStatus=OPSGROUP.CargoStatus.NOTCARGO
  self.carrierStatus=OPSGROUP.CarrierStatus.NOTCARRIER
  self:SetCarrierLoaderAllAspect()
  self:SetCarrierUnloaderAllAspect()

  -- Init task counter.
  self.taskcurrent=0
  self.taskcounter=0

  -- Start state.
  self:SetStartState("InUtero")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("InUtero",       "Spawned",          "Spawned")     -- The whole group was spawned.
  self:AddTransition("*",             "Respawn",          "InUtero")     -- Respawn group.
  self:AddTransition("*",             "Dead",             "InUtero")     -- The whole group is dead and goes back to mummy.
  self:AddTransition("*",             "InUtero",          "InUtero")     -- Deactivated group goes back to mummy.
  self:AddTransition("*",             "Stop",             "Stopped")     -- Stop FSM.

  self:AddTransition("*",             "Hit",              "*")           -- Someone in the group was hit.
  self:AddTransition("*",             "Damaged",          "*")           -- Someone in the group took damage.
  self:AddTransition("*",             "Destroyed",        "*")           -- The whole group is dead.

  self:AddTransition("*",             "UpdateRoute",      "*")           -- Update route of group.

  self:AddTransition("*",             "PassingWaypoint",   "*")           -- Group passed a waypoint.
  self:AddTransition("*",             "PassedFinalWaypoint", "*")         -- Group passed the waypoint.
  self:AddTransition("*",             "GotoWaypoint",      "*")           -- Group switches to a specific waypoint.

  self:AddTransition("*",             "Wait",              "*")           -- Group will wait for further orders.
  self:AddTransition("*",             "Stuck",             "*")           -- Group got stuck.

  self:AddTransition("*",             "DetectedUnit",      "*")           -- Unit was detected (again) in this detection cycle.
  self:AddTransition("*",             "DetectedUnitNew",   "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitKnown", "*")           -- A known unit is still detected.
  self:AddTransition("*",             "DetectedUnitLost",  "*")           -- Group lost a detected target.

  self:AddTransition("*",             "DetectedGroup",      "*")          -- Group was detected (again) in this detection cycle.
  self:AddTransition("*",             "DetectedGroupNew",   "*")          -- Add a newly detected Group to the detected Groups set.
  self:AddTransition("*",             "DetectedGroupKnown", "*")          -- A known Group is still detected.
  self:AddTransition("*",             "DetectedGroupLost",  "*")          -- Group lost a detected target group.

  self:AddTransition("*",             "OutOfAmmo",         "*")          -- Group is completely out of ammo.
  self:AddTransition("*",             "OutOfGuns",         "*")          -- Group is out of gun shells.
  self:AddTransition("*",             "OutOfRockets",      "*")          -- Group is out of rockets.
  self:AddTransition("*",             "OutOfBombs",        "*")          -- Group is out of bombs.
  self:AddTransition("*",             "OutOfMissiles",     "*")          -- Group is out of missiles.
  self:AddTransition("*",             "OutOfTorpedos",     "*")          -- Group is out of torpedos.

  self:AddTransition("*",             "OutOfMissilesAA",   "*")          -- Group is out of A2A (air) missiles.
  self:AddTransition("*",             "OutOfMissilesAG",   "*")          -- Group is out of A2G (ground) missiles.
  self:AddTransition("*",             "OutOfMissilesAS",   "*")          -- Group is out of A2S (ship) missiles.

  self:AddTransition("*",             "EnterZone",        "*")           -- Group entered a certain zone.
  self:AddTransition("*",             "LeaveZone",        "*")           -- Group leaves a certain zone.

  self:AddTransition("*",             "LaserOn",          "*")            -- Turn laser on.
  self:AddTransition("*",             "LaserOff",         "*")            -- Turn laser off.
  self:AddTransition("*",             "LaserCode",        "*")            -- Switch laser code.
  self:AddTransition("*",             "LaserPause",       "*")            -- Turn laser off temporarily.
  self:AddTransition("*",             "LaserResume",       "*")           -- Turn laser back on again if it was paused.
  self:AddTransition("*",             "LaserLostLOS",     "*")            -- Lasing element lost line of sight.
  self:AddTransition("*",             "LaserGotLOS",      "*")            -- Lasing element got line of sight.

  self:AddTransition("*",             "TaskExecute",      "*")           -- Group will execute a task.
  self:AddTransition("*",             "TaskPause",        "*")           -- Pause current task. Not implemented yet!
  self:AddTransition("*",             "TaskCancel",       "*")           -- Cancel current task.
  self:AddTransition("*",             "TaskDone",         "*")           -- Task is over.

  self:AddTransition("*",             "MissionStart",     "*")           -- Mission is started.
  self:AddTransition("*",             "MissionExecute",   "*")           -- Mission execution began.
  self:AddTransition("*",             "MissionCancel",    "*")           -- Cancel current mission.
  self:AddTransition("*",             "PauseMission",     "*")           -- Pause the current mission.
  self:AddTransition("*",             "UnpauseMission",   "*")           -- Unpause the the paused mission.
  self:AddTransition("*",             "MissionDone",      "*")           -- Mission is over.

  self:AddTransition("*",             "ElementInUtero",   "*")           -- An element is in utero again.
  self:AddTransition("*",             "ElementSpawned",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementDestroyed", "*")           -- An element was destroyed.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element is dead.
  self:AddTransition("*",             "ElementDamaged",   "*")           -- An element was damaged.
  self:AddTransition("*",             "ElementHit",       "*")           -- An element was hit.

  self:AddTransition("*",             "Board",            "*")           -- Group is ordered to board the carrier.
  self:AddTransition("*",             "Embarked",         "*")           -- Group was loaded into a cargo carrier.
  self:AddTransition("*",             "Disembarked",      "*")           -- Group was unloaded from a cargo carrier.

  self:AddTransition("*",             "Pickup",           "*")           -- Carrier and is on route to pick up cargo.
  self:AddTransition("*",             "Loading",          "*")           -- Carrier is loading cargo.
  self:AddTransition("*",             "Load",             "*")           -- Carrier loads cargo into carrier.
  self:AddTransition("*",             "Loaded",           "*")           -- Carrier loaded cargo into carrier.
  self:AddTransition("*",             "LoadingDone",      "*")           -- Carrier loaded all assigned/possible cargo into carrier.
  self:AddTransition("*",             "Transport",        "*")           -- Carrier is transporting cargo.
  self:AddTransition("*",             "Unloading",        "*")           -- Carrier is unloading the cargo.
  self:AddTransition("*",             "Unload",           "*")           -- Carrier unloads a cargo group.
  self:AddTransition("*",             "Unloaded",         "*")           -- Carrier unloaded a cargo group.
  self:AddTransition("*",             "UnloadingDone",    "*")           -- Carrier unloaded all its current cargo.
  self:AddTransition("*",             "Delivered",        "*")           -- Carrier delivered ALL cargo of the transport assignment.

  self:AddTransition("*",             "TransportCancel",  "*")           -- Cancel (current) transport.

  self:AddTransition("*",             "HoverStart",        "*")           -- Helo group is hovering
  self:AddTransition("*",             "HoverEnd",        "*")           -- Helo group is flying on    
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Stop". Stops the OPSGROUP and all its event handlers.
  -- @function [parent=#OPSGROUP] Stop
  -- @param #OPSGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the OPSGROUP and all its event handlers.
  -- @function [parent=#OPSGROUP] __Stop
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#OPSGROUP] Status
  -- @param #OPSGROUP self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#OPSGROUP] __Status
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "MissionStart".
  -- @function [parent=#OPSGROUP] MissionStart
  -- @param #OPSGROUP self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionStart" after a delay.
  -- @function [parent=#OPSGROUP] __MissionStart
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionStart" event.
  -- @function [parent=#OPSGROUP] OnAfterMissionStart
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionExecute".
  -- @function [parent=#OPSGROUP] MissionExecute
  -- @param #OPSGROUP self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionExecute" after a delay.
  -- @function [parent=#OPSGROUP] __MissionExecute
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionExecute" event.
  -- @function [parent=#OPSGROUP] OnAfterMissionExecute
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionCancel".
  -- @function [parent=#OPSGROUP] MissionCancel
  -- @param #OPSGROUP self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionCancel" after a delay.
  -- @function [parent=#OPSGROUP] __MissionCancel
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionCancel" event.
  -- @function [parent=#OPSGROUP] OnAfterMissionCancel
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionDone".
  -- @function [parent=#OPSGROUP] MissionDone
  -- @param #OPSGROUP self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionDone" after a delay.
  -- @function [parent=#OPSGROUP] __MissionDone
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionDone" event.
  -- @function [parent=#OPSGROUP] OnAfterMissionDone
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "HoverStart" event.
  -- @function [parent=#OPSGROUP] OnAfterHoverStart
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
    --- On after "HoverEnd" event.
  -- @function [parent=#OPSGROUP] OnAfterHoverEnd
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "TransportCancel".
  -- @function [parent=#OPSGROUP] TransportCancel
  -- @param #OPSGROUP self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportCancel" after a delay.
  -- @function [parent=#OPSGROUP] __TransportCancel
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportCancel" event.
  -- @function [parent=#OPSGROUP] OnAfterTransportCancel
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  
    --- On After "DetectedGroup" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedGroup
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#Group Group Detected Group.
  
  --- On After "DetectedGroupNew" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedGroupNew
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#Group Group Newly detected group.
  
  --- On After "DetectedGroupKnown" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedGroupKnown
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#Group Group Known detected group.
  
  --- On After "DetectedGroupLost" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedGroupLost
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#Group Group Lost detected group.
  
  --- On After "DetectedUnit" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedUnit
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#Unit Unit Detected Unit.
  
  --- On After "DetectedUnitNew" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedUnitNew
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#Unit Unit Newly detected unit.
  
  --- On After "DetectedUnitKnown" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedUnitKnown
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#Unit Unit Known detected unit.
  
  --- On After "DetectedUnitLost" event.
  -- @function [parent=#OPSGROUP] OnAfterDetectedUnitLost
  -- @param #OPSGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#Unit Unit Lost detected unit.
  
  -- TODO: Add pseudo functions.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get coalition.
-- @param #OPSGROUP self
-- @return #number Coalition side of carrier.
function OPSGROUP:GetCoalition()
  return self.group:GetCoalition()
end

--- Returns the absolute total life points of the group.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element Element (Optional) Only get life points of this element.
-- @return #number Life points, *i.e.* the sum of life points over all units in the group (unless a specific element was passed).  
-- @return #number Initial life points.
function OPSGROUP:GetLifePoints(Element)

  local life=0
  local life0=0

  if Element then

    local unit=Element.unit

    if unit then
      life=unit:GetLife()
      life0=unit:GetLife0()
      life=math.min(life, life0) -- Some units have more life than life0 returns!
    end

  else

    for _,element in pairs(self.elements) do
      local l,l0=self:GetLifePoints(element)
      life=life+l
      life0=life0+l0
    end

  end

  return life, life0
end

--- Get generalized attribute.
-- @param #OPSGROUP self
-- @return #string Generalized attribute.
function OPSGROUP:GetAttribute()
  return self.attribute
end

--- Set verbosity level.
-- @param #OPSGROUP self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #OPSGROUP self
function OPSGROUP:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set legion this ops group belongs to.
-- @param #OPSGROUP self
-- @param Ops.Legion#LEGION Legion The Legion.
-- @return #OPSGROUP self
function OPSGROUP:_SetLegion(Legion)
  self:T2(self.lid..string.format("Adding opsgroup to legion %s", Legion.alias))
  self.legion=Legion
  return self
end

--- **[GROUND, NAVAL]** Set whether this group should return to its legion once all mission etc are finished. Only for ground and naval groups. Aircraft will 
-- @param #OPSGROUP self
-- @param #boolean Switch If `true` or `nil`, group will return. If `false`, group will not return and stay where it finishes its last mission.
-- @return #OPSGROUP self
function OPSGROUP:SetReturnToLegion(Switch)
  if Switch==false then
    self.legionReturn=false
  else
    self.legionReturn=true
  end
  self:T(self.lid..string.format("Setting ReturnToLegion=%s", tostring(self.legionReturn)))
  return self
end

--- Set default cruise speed.
-- @param #OPSGROUP self
-- @param #number Speed Speed in knots.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultSpeed(Speed)
  if Speed then
    self.speedCruise=UTILS.KnotsToKmph(Speed)
  end
  return self
end

--- Get default cruise speed.
-- @param #OPSGROUP self
-- @return #number Cruise speed (>0) in knots.
function OPSGROUP:GetSpeedCruise()
  local speed=UTILS.KmphToKnots(self.speedCruise or self.speedMax*0.7)
  return speed
end

--- Set default cruise altitude.
-- @param #OPSGROUP self
-- @param #number Altitude Altitude in feet. Default is 10,000 ft for airplanes and 1,500 feet for helicopters.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultAltitude(Altitude)
  if Altitude then
    self.altitudeCruise=UTILS.FeetToMeters(Altitude)
  else
    if self:IsFlightgroup() then
      if self.isHelo then
        self.altitudeCruise=UTILS.FeetToMeters(1500)
      else
        self.altitudeCruise=UTILS.FeetToMeters(10000)
      end
    else
      self.altitudeCruise=0
    end
  end
  return self
end

--- Get default cruise speed.
-- @param #OPSGROUP self
-- @return #number Cruise altitude in feet.
function OPSGROUP:GetCruiseAltitude()
  local alt=UTILS.MetersToFeet(self.altitudeCruise)
  return alt
end

--- Set current altitude.
-- @param #OPSGROUP self
-- @param #number Altitude Altitude in feet. Default is 10,000 ft for airplanes and 1,500 feet for helicopters.
-- @param #boolean Keep If `true` the group will maintain that speed on passing waypoints. If `nil` or `false` the group will return to the speed as defined by their route.
-- @return #OPSGROUP self
function OPSGROUP:SetAltitude(Altitude, Keep, RadarAlt)
  if Altitude then
    Altitude=UTILS.FeetToMeters(Altitude)
  else
    if self:IsFlightgroup() then
      if self.isHelo then
        Altitude=UTILS.FeetToMeters(1500)
      else
        Altitude=UTILS.FeetToMeters(10000)
      end
    else
      Altitude=0
    end
  end
  
  local AltType="BARO"
  if RadarAlt then
    AltType="RADIO"
  end
  
  if self.controller then
    self.controller:setAltitude(Altitude, Keep, AltType)
  end
  
  return self
end

--- Set current altitude.
-- @param #OPSGROUP self
-- @return #number Altitude in feet.
function OPSGROUP:GetAltitude()

  local alt=0
  
  if self.group then

    alt=self.group:GetAltitude()
    
    alt=UTILS.MetersToFeet(alt)
    
  end

  return alt
end

--- Set current speed.
-- @param #OPSGROUP self
-- @param #number Speed Speed in knots. Default is 70% of max speed.
-- @param #boolean Keep If `true` the group will maintain that speed on passing waypoints. If `nil` or `false` the group will return to the speed as defined by their route.
-- @param #boolean AltCorrected If `true`, use altitude corrected indicated air speed.
-- @return #OPSGROUP self
function OPSGROUP:SetSpeed(Speed, Keep, AltCorrected)
  if Speed then
  
  else
    Speed=UTILS.KmphToKnots(self.speedMax)
  end
  
  
  if AltCorrected then
    local altitude=self:GetAltitude()
    Speed=UTILS.KnotsToAltKIAS(Speed, altitude)
  end
  
  Speed=UTILS.KnotsToMps(Speed)
  
  if self.controller then
    self.controller:setSpeed(Speed, Keep)
  end
  
  return self
end

--- Set detection on or off.
-- If detection is on, detected targets of the group will be evaluated and FSM events triggered.
-- @param #OPSGROUP self
-- @param #boolean Switch If `true`, detection is on. If `false` or `nil`, detection is off. Default is off.
-- @return #OPSGROUP self
function OPSGROUP:SetDetection(Switch)
  self:T(self.lid..string.format("Detection is %s", tostring(Switch)))
  self.detectionOn=Switch
  return self
end

--- Get DCS group object.
-- @param #OPSGROUP self
-- @return DCS#Group DCS group object.
function OPSGROUP:GetDCSObject()
  return self.dcsgroup
end

--- Make a target (unit, group, opsgroup) known to this group.
-- This is useing the DCS function `controller.knowTarget`. 
-- @param #OPSGROUP self
-- @param Wrapper.Positionable#POSITIONABLE TargetObject The target object.
-- @param #boolean KnowType Make type known.
-- @param #boolean KnowDist Make distance known.
-- @param #number Delay Delay in seconds before the target is known.
-- @return #OPSGROUP self
function OPSGROUP:KnowTarget(TargetObject, KnowType, KnowDist, Delay)

  if Delay and Delay>0 then
    -- Delayed call.
    self:ScheduleOnce(Delay, OPSGROUP.KnowTarget, self, TargetObject, KnowType, KnowDist, 0)  
  else
  
    if TargetObject:IsInstanceOf("GROUP") then
      TargetObject=TargetObject:GetUnit(1)
    elseif TargetObject:IsInstanceOf("OPSGROUP") then
      TargetObject=TargetObject.group:GetUnit(1)
    end

    -- Get the DCS object.
    local object=TargetObject:GetDCSObject()
    
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element.controller then
        element.controller:knowTarget(object, true, true)
        --self:T(self.lid..string.format("Element %s should now know target %s", element.name, TargetObject:GetName()))
      end
    end
    
    -- Debug info.
    self:T(self.lid..string.format("We should now know target %s", TargetObject:GetName()))
    
  end

  return self
end

--- Check if target is detected.
-- @param #OPSGROUP self
-- @param Wrapper.Positionable#POSITIONABLE TargetObject The target object.
-- @return #boolean If `true`, target was detected.
function OPSGROUP:IsTargetDetected(TargetObject)
    
  local objects={}
  
  if TargetObject:IsInstanceOf("GROUP") then
    for _,unit in pairs(TargetObject:GetUnits()) do
      table.insert(objects, unit:GetDCSObject())
    end
  elseif TargetObject:IsInstanceOf("OPSGROUP") then
    for _,unit in pairs(TargetObject.group:GetUnits()) do
      table.insert(objects, unit:GetDCSObject())
    end    
  elseif TargetObject:IsInstanceOf("UNIT") or TargetObject:IsInstanceOf("STATIC") then
    table.insert(objects, TargetObject:GetDCSObject())
  end
  
  for _,object in pairs(objects or {}) do
  
    -- Check group controller.
    local detected, visible, lastTime, type, distance, lastPos, lastVel = self.controller:isTargetDetected(object, 1, 2, 4, 8, 16, 32)
    
    --env.info(self.lid..string.format("Detected target %s: %s", TargetObject:GetName(), tostring(detected)))
    
    if detected then
      return true
    end
    
    
    -- Check all elements.
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element.controller then
      
        -- Check.
        local detected, visible, lastTime, type, distance, lastPos, lastVel=
        element.controller:isTargetDetected(object, 1, 2, 4, 8, 16, 32)
        
        --env.info(self.lid..string.format("Element %s detected target %s: %s", element.name, TargetObject:GetName(), tostring(detected)))
        
        if detected then
          return true
        end
        
      end
    end
    
  end 

  return false
end

--- Check if a given coordinate is in weapon range.
-- @param #OPSGROUP self
-- @param Core.Point#COORDINATE TargetCoord Coordinate of the target.
-- @param #number WeaponBitType Weapon type.
-- @param Core.Point#COORDINATE RefCoord Reference coordinate.
-- @return #boolean If `true`, coordinate is in range.
function OPSGROUP:InWeaponRange(TargetCoord, WeaponBitType, RefCoord)

  RefCoord=RefCoord or self:GetCoordinate()
  
  local dist=TargetCoord:Get2DDistance(RefCoord)

  if WeaponBitType then
  
    local weapondata=self:GetWeaponData(WeaponBitType)
    
    if weapondata then
    
      if dist>=weapondata.RangeMin and dist<=weapondata.RangeMax then
        return true
      else
        return false
      end
    
    end
    
  else
  
    for _,_weapondata in pairs(self.weaponData or {}) do
      local weapondata=_weapondata --#OPSGROUP.WeaponData

      if dist>=weapondata.RangeMin and dist<=weapondata.RangeMax then
        return true
      end
            
    end

    return false  
  end
    

  return nil
end

--- Get a coordinate, which is in weapon range.
-- @param #OPSGROUP self
-- @param Core.Point#COORDINATE TargetCoord Coordinate of the target.
-- @param #number WeaponBitType Weapon type.
-- @param Core.Point#COORDINATE RefCoord Reference coordinate.
-- @param #table SurfaceTypes Valid surfaces types of the coordinate. Default any (nil).
-- @return Core.Point#COORDINATE Coordinate in weapon range
function OPSGROUP:GetCoordinateInRange(TargetCoord, WeaponBitType, RefCoord, SurfaceTypes)

  local coordInRange=nil --Core.Point#COORDINATE
  
  RefCoord=RefCoord or self:GetCoordinate()

  -- Get weapon range.
  local weapondata=self:GetWeaponData(WeaponBitType)
  
  -- Heading intervals to search for a possible new coordinate in range.
  local dh={0, -5, 5, -10, 10, -15, 15, -20, 20, -25, 25, -30, 30, -35, 35, -40, 40, -45, 45, -50, 50, -55, 55, -60, 60, -65, 65, -70, 70, -75, 75, -80, 80}
  
  -- Function that checks if the given surface type is valid
  local function _checkSurface(point)
    if SurfaceTypes then
      local stype=point:GetSurfaceType()
      for _,sf in pairs(SurfaceTypes) do
        if sf==stype then
          return true
        end
      end
      return false
    else
      return true
    end
  end  
  
  if weapondata then
  
    -- Heading to target.
    local heading=TargetCoord:HeadingTo(RefCoord)
  
    -- Distance to target.
    local dist=RefCoord:Get2DDistance(TargetCoord)
    
    local range=nil
    if dist>weapondata.RangeMax then
      range=weapondata.RangeMax
      self:T(self.lid..string.format("Out of max range = %.1f km by %.1f km for weapon %s", weapondata.RangeMax/1000, (weapondata.RangeMax-dist)/1000, tostring(WeaponBitType)))
    elseif dist<weapondata.RangeMin then
      range=weapondata.RangeMin
      self:T(self.lid..string.format("Out of min range = %.1f km by %.1f km for weapon %s", weapondata.RangeMin/1000, (weapondata.RangeMin-dist)/1000, tostring(WeaponBitType)))
    end
  
    -- Check if we are within range.
    if range then
      
      for _,delta in pairs(dh) do
      
        local h=heading+delta
  
        -- New waypoint coord.
        coordInRange=TargetCoord:Translate(range, h)
        
        if _checkSurface(coordInRange) then
          break
        end
        
      end
      
    else  
      -- Debug info.
      self:T(self.lid..string.format("Already in range for weapon %s", tostring(WeaponBitType)))                    
    end
  
  else
    self:T(self.lid..string.format("No weapon data for weapon type %s", tostring(WeaponBitType)))
  end
  
  return coordInRange
end

--- Set LASER parameters.
-- @param #OPSGROUP self
-- @param #number Code Laser code. Default 1688.
-- @param #boolean CheckLOS Check if lasing unit has line of sight to target coordinate. Default is `true`.
-- @param #boolean IROff If true, then dont switch on the additional IR pointer.
-- @param #number UpdateTime Time interval in seconds the beam gets up for moving targets. Default every 0.5 sec.
-- @return #OPSGROUP self
function OPSGROUP:SetLaser(Code, CheckLOS, IROff, UpdateTime)
  self.spot.Code=Code or 1688
  if CheckLOS~=nil then
    self.spot.CheckLOS=CheckLOS
  else
    self.spot.CheckLOS=true
  end
  self.spot.IRon=not IROff
  self.spot.dt=UpdateTime or 0.5
  return self
end

--- Get LASER code.
-- @param #OPSGROUP self
-- @return #number Current Laser code.
function OPSGROUP:GetLaserCode()
  return self.spot.Code
end

--- Get current LASER coordinate, i.e. where the beam is pointing at if the LASER is on.
-- @param #OPSGROUP self
-- @return Core.Point#COORDINATE Current position where the LASER is pointing at.
function OPSGROUP:GetLaserCoordinate()
  return self.spot.Coordinate
end

--- Get current target of the LASER. This can be a STATIC or UNIT object.
-- @param #OPSGROUP self
-- @return Wrapper.Positionable#POSITIONABLE Current target object.
function OPSGROUP:GetLaserTarget()
  return self.spot.TargetUnit
end

--- Define a SET of zones that trigger and event if the group enters or leaves any of the zones.
-- @param #OPSGROUP self
-- @param Core.Set#SET_ZONE CheckZonesSet Set of zones.
-- @return #OPSGROUP self
function OPSGROUP:SetCheckZones(CheckZonesSet)
  self.checkzones=CheckZonesSet
  return self
end

--- Add a zone that triggers and event if the group enters or leaves any of the zones.
-- @param #OPSGROUP self
-- @param Core.Zone#ZONE CheckZone Zone to check.
-- @return #OPSGROUP self
function OPSGROUP:AddCheckZone(CheckZone)
  if not self.checkzones then
    self.checkzones=SET_ZONE:New()
  end
  self.checkzones:AddZone(CheckZone)
  return self
end


--- Add a weapon range for ARTY auftrag.
-- @param #OPSGROUP self
-- @param #number RangeMin Minimum range in nautical miles. Default 0 NM.
-- @param #number RangeMax Maximum range in nautical miles. Default 10 NM.
-- @param #number BitType Bit mask of weapon type for which the given min/max ranges apply. Default is `ENUMS.WeaponFlag.Auto`, i.e. for all weapon types.
-- @param #function ConversionToMeters Function that converts input units of ranges to meters. Defaul `UTILS.NMToMeters`.
-- @return #OPSGROUP self
function OPSGROUP:AddWeaponRange(RangeMin, RangeMax, BitType, ConversionToMeters)

  ConversionToMeters=ConversionToMeters or UTILS.NMToMeters

  RangeMin=ConversionToMeters(RangeMin or 0)
  RangeMax=ConversionToMeters(RangeMax or 10)

  local weapon={} --#OPSGROUP.WeaponData

  weapon.BitType=BitType or ENUMS.WeaponFlag.Auto
  weapon.RangeMax=RangeMax
  weapon.RangeMin=RangeMin

  self.weaponData=self.weaponData or {}
  self.weaponData[tostring(weapon.BitType)]=weapon

  return self
end

--- Get weapon data.
-- @param #OPSGROUP self
-- @param #number BitType Type of weapon.
-- @return #OPSGROUP.WeaponData Weapon range data.
function OPSGROUP:GetWeaponData(BitType)

  BitType=tostring(BitType or ENUMS.WeaponFlag.Auto)

  if self.weaponData[BitType] then
    return self.weaponData[BitType]
  else
    return self.weaponData[tostring(ENUMS.WeaponFlag.Auto)]
  end

end

--- Get set of detected units.
-- @param #OPSGROUP self
-- @return Core.Set#SET_UNIT Set of detected units.
function OPSGROUP:GetDetectedUnits()
  return self.detectedunits or {}
end

--- Get set of detected groups.
-- @param #OPSGROUP self
-- @return Core.Set#SET_GROUP Set of detected groups.
function OPSGROUP:GetDetectedGroups()
  return self.detectedgroups or {}
end

--- Get inital amount of ammunition.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Ammo Initial ammo table.
function OPSGROUP:GetAmmo0()
  return self.ammo
end

--- Get highest detected threat. Detection must be turned on. The threat level is a number between 0 and 10, where 0 is the lowest, e.g. unarmed units.
-- @param #OPSGROUP self
-- @param #number ThreatLevelMin Only consider threats with level greater or equal to this number. Default 1 (so unarmed units wont be considered).
-- @param #number ThreatLevelMax Only consider threats with level smaller or queal to this number. Default 10.
-- @return Wrapper.Unit#UNIT Highest threat unit detected by the group or `nil` if no threat is currently detected.
-- @return #number Threat level.
function OPSGROUP:GetThreat(ThreatLevelMin, ThreatLevelMax)

  ThreatLevelMin=ThreatLevelMin or 1
  ThreatLevelMax=ThreatLevelMax or 10

  local threat=nil --Wrapper.Unit#UNIT
  local level=0
  for _,_unit in pairs(self.detectedunits:GetSet()) do
    local unit=_unit --Wrapper.Unit#UNIT

    -- Get threatlevel of unit.
    local threatlevel=unit:GetThreatLevel()

    -- Check if withing threasholds.
    if threatlevel>=ThreatLevelMin and threatlevel<=ThreatLevelMax then

      if threatlevel<level then
        level=threatlevel
        threat=unit
      end

    end

  end

  return threat, level
end

--- Get highest threat.
-- @param #OPSGROUP self
-- @return Wrapper.Unit#UNIT The highest threat unit.
-- @return #number Threat level of the unit.
function OPSGROUP:GetHighestThreat()

  local threat=nil
  local levelmax=-1
  for _,_unit in pairs(self.detectedunits:GetSet()) do
    local unit=_unit --Wrapper.Unit#UNIT

    local threatlevel=unit:GetThreatLevel()

    if threatlevel>levelmax then
      threat=unit
      levelmax=threatlevel
    end

  end

  return threat, levelmax
end

--- Enable to automatically engage detected targets.
-- @param #OPSGROUP self
-- @param #number RangeMax Max range in NM. Only detected targets within this radius from the group will be engaged. Default is 25 NM.
-- @param #table TargetTypes Types of target attributes that will be engaged. See [DCS enum attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes). Default "All".
-- @param Core.Set#SET_ZONE EngageZoneSet Set of zones in which targets are engaged. Default is anywhere.
-- @param Core.Set#SET_ZONE NoEngageZoneSet Set of zones in which targets are *not* engaged. Default is nowhere.
-- @return #OPSGROUP self
function OPSGROUP:SetEngageDetectedOn(RangeMax, TargetTypes, EngageZoneSet, NoEngageZoneSet)

  -- Ensure table.
  if TargetTypes then
    if type(TargetTypes)~="table" then
      TargetTypes={TargetTypes}
    end
  else
    TargetTypes={"All"}
  end

  -- Ensure SET_ZONE if ZONE is provided.
  if EngageZoneSet and EngageZoneSet:IsInstanceOf("ZONE_BASE") then
    local zoneset=SET_ZONE:New():AddZone(EngageZoneSet)
    EngageZoneSet=zoneset
  end
  if NoEngageZoneSet and NoEngageZoneSet:IsInstanceOf("ZONE_BASE") then
    local zoneset=SET_ZONE:New():AddZone(NoEngageZoneSet)
    NoEngageZoneSet=zoneset
  end

  -- Set parameters.
  self.engagedetectedOn=true
  self.engagedetectedRmax=UTILS.NMToMeters(RangeMax or 25)
  self.engagedetectedTypes=TargetTypes
  self.engagedetectedEngageZones=EngageZoneSet
  self.engagedetectedNoEngageZones=NoEngageZoneSet

  -- Debug info.
  self:T(self.lid..string.format("Engage detected ON: Rmax=%d NM", UTILS.MetersToNM(self.engagedetectedRmax)))

  -- Ensure detection is ON or it does not make any sense.
  self:SetDetection(true)

  return self
end

--- Disable to automatically engage detected targets.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:SetEngageDetectedOff()
  self:T(self.lid..string.format("Engage detected OFF"))
  self.engagedetectedOn=false
  return self
end

--- Set that group is going to rearm once it runs out of ammo.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:SetRearmOnOutOfAmmo()
  self.rearmOnOutOfAmmo=true
  return self
end

--- Set that group is retreating once it runs out of ammo.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:SetRetreatOnOutOfAmmo()
  self.retreatOnOutOfAmmo=true
  return self
end

--- Set that group is return to legion once it runs out of ammo.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:SetReturnOnOutOfAmmo()
  self.rtzOnOutOfAmmo=true
  return self
end

--- Set max weight that each unit of the group can handle.
-- @param #OPSGROUP self
-- @param #number Weight Max weight of cargo in kg the unit can carry.
-- @param #string UnitName Name of the Unit. If not given, weight is set for all units of the group.
-- @return #OPSGROUP self
function OPSGROUP:SetCargoBayLimit(Weight, UnitName)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    
    if UnitName==nil or UnitName==element.name then
    
      element.weightMaxCargo=Weight
      
      if element.unit then
        element.unit:SetCargoBayWeightLimit(Weight)
      end
      
    end
  
  end

  return self
end

--- Check if an element of the group has line of sight to a coordinate.
-- @param #OPSGROUP self
-- @param Core.Point#COORDINATE Coordinate The position to which we check the LoS. Can also be a DCS#Vec3.
-- @param #OPSGROUP.Element Element The (optinal) element. If not given, all elements are checked.
-- @param DCS#Vec3 OffsetElement Offset vector of the element.
-- @param DCS#Vec3 OffsetCoordinate Offset vector of the coordinate.
-- @return #boolean If `true`, there is line of sight to the specified coordinate.
function OPSGROUP:HasLoS(Coordinate, Element, OffsetElement, OffsetCoordinate)

  if Coordinate then

    -- Target vector.
    local Vec3={x=Coordinate.x, y=Coordinate.y, z=Coordinate.z} --Coordinate:GetVec3()
  
    -- Optional offset.
    if OffsetCoordinate then
      Vec3=UTILS.VecAdd(Vec3, OffsetCoordinate)
    end
  
    --- Function to check LoS for an element of the group.
    local function checklos(vec3)
      if vec3 then
        if OffsetElement then
          vec3=UTILS.VecAdd(vec3, OffsetElement)
        end
        local _los=land.isVisible(vec3, Vec3)
        --self:I({los=_los, source=vec3, target=Vec3})
        return _los
      end
      return nil      
    end
  
    if Element then
      -- Check los for the given element.
      if Element.unit and Element.unit:IsAlive() then
        local vec3=Element.unit:GetVec3()
        local los=checklos(vec3)
        return los
      end
    else
  
      -- Check if any element has los.
      local gotit=false
      for _,_element in pairs(self.elements) do
        local element=_element --#OPSGROUP.Element
        if element and element.unit and element.unit:IsAlive() then
          gotit=true
          local vec3=element.unit:GetVec3()
          -- Get LoS of this element.
          local los=checklos(vec3)
          if los then
            return true
          end
        end
      end
  
      if gotit then
        return false
      end
    end
    
  end

  return nil
end

--- Get MOOSE GROUP object.
-- @param #OPSGROUP self
-- @return Wrapper.Group#GROUP Moose group object.
function OPSGROUP:GetGroup()
  return self.group
end

--- Get the group name.
-- @param #OPSGROUP self
-- @return #string Group name.
function OPSGROUP:GetName()
  return self.groupname
end

--- Get DCS GROUP object.
-- @param #OPSGROUP self
-- @return DCS#Group DCS group object.
function OPSGROUP:GetDCSGroup()
  local DCSGroup=Group.getByName(self.groupname)
  return DCSGroup
end

--- Get MOOSE UNIT object.
-- @param #OPSGROUP self
-- @param #number UnitNumber Number of the unit in the group. Default first unit.
-- @return Wrapper.Unit#UNIT The MOOSE UNIT object.
function OPSGROUP:GetUnit(UnitNumber)

  local DCSUnit=self:GetDCSUnit(UnitNumber)

  if DCSUnit then
    local unit=UNIT:Find(DCSUnit)
    return unit
  end

  return nil
end

--- Get DCS GROUP object.
-- @param #OPSGROUP self
-- @param #number UnitNumber Number of the unit in the group. Default first unit.
-- @return DCS#Unit DCS group object.
function OPSGROUP:GetDCSUnit(UnitNumber)

  local DCSGroup=self:GetDCSGroup()

  if DCSGroup then
    local unit=DCSGroup:getUnit(UnitNumber or 1)
    return unit
  else
    self:E(self.lid..string.format("ERROR: DCS group does not exist! Cannot get unit"))
  end

  return nil
end

--- Get DCS units.
-- @param #OPSGROUP self
-- @return #list<DCS#Unit> DCS units.
function OPSGROUP:GetDCSUnits()

  local DCSGroup=self:GetDCSGroup()

  if DCSGroup then
    local units=DCSGroup:getUnits()
    return units
  end

  return nil
end


--- Get current 2D position vector of the group.
-- @param #OPSGROUP self
-- @param #string UnitName (Optional) Get position of a specifc unit of the group. Default is the first existing unit in the group.
-- @return DCS#Vec2 Vector with x,y components.
function OPSGROUP:GetVec2(UnitName)

  local vec3=self:GetVec3(UnitName)

  if vec3 then
    local vec2={x=vec3.x, y=vec3.z}
    return vec2
  end

  return nil
end


--- Get current 3D position vector of the group.
-- @param #OPSGROUP self
-- @param #string UnitName (Optional) Get position of a specifc unit of the group. Default is the first existing unit in the group.
-- @return DCS#Vec3 Vector with x,y,z components.
function OPSGROUP:GetVec3(UnitName)

  local vec3=nil --DCS#Vec3

  -- First check if this group is loaded into a carrier
  local carrier=self:_GetMyCarrierElement()
  if carrier and carrier.status~=OPSGROUP.ElementStatus.DEAD and self:IsLoaded() then
    local unit=carrier.unit
    if unit and unit:IsExist() then
      vec3=unit:GetVec3()
      return vec3
    end
  end

  if self:IsExist() then

    local unit=nil --DCS#Unit
    if UnitName then
      unit=Unit.getByName(UnitName)
    else
      unit=self:GetDCSUnit()
    end


    if unit then
      local vec3=unit:getPoint()
      return vec3
    end

  end

  -- Return last known position.
  if self.position then
    return self.position
  end

  return nil
end

--- Get current coordinate of the group. If the current position cannot be determined, the last known position is returned.
-- @param #OPSGROUP self
-- @param #boolean NewObject Create a new coordiante object.
-- @param #string UnitName (Optional) Get position of a specifc unit of the group. Default is the first existing unit in the group.
-- @return Core.Point#COORDINATE The coordinate (of the first unit) of the group.
function OPSGROUP:GetCoordinate(NewObject, UnitName)

  local vec3=self:GetVec3(UnitName) or self.position --DCS#Vec3

  if vec3 then

    self.coordinate=self.coordinate or COORDINATE:New(0,0,0)

    self.coordinate.x=vec3.x
    self.coordinate.y=vec3.y
    self.coordinate.z=vec3.z

    if NewObject then
      local coord=COORDINATE:NewFromCoordinate(self.coordinate)
      return coord
    else
      return self.coordinate
    end
  else
    self:T(self.lid.."WARNING: Cannot get coordinate!")
  end

  return nil
end

--- Get current velocity of the group.
-- @param #OPSGROUP self
-- @param #string UnitName (Optional) Get velocity of a specific unit of the group. Default is from the first existing unit in the group.
-- @return #number Velocity in m/s.
function OPSGROUP:GetVelocity(UnitName)

  if self:IsExist() then

    local unit=nil --DCS#Unit

    if UnitName then
      unit=Unit.getByName(UnitName)
    else
      unit=self:GetDCSUnit()
    end

    if unit then

      local velvec3=unit:getVelocity()

      local vel=UTILS.VecNorm(velvec3)

      return vel

    else
      self:T(self.lid.."WARNING: Unit does not exist. Cannot get velocity!")
    end

  else
    self:T(self.lid.."WARNING: Group does not exist. Cannot get velocity!")
  end

  return nil
end

--- Get current heading of the group or (optionally) of a specific unit of the group.
-- @param #OPSGROUP self
-- @param #string UnitName (Optional) Get heading of a specific unit of the group. Default is from the first existing unit in the group.
-- @return #number Current heading of the group in degrees.
function OPSGROUP:GetHeading(UnitName)

  if self:IsExist() then

    local unit=nil --DCS#Unit
    if UnitName then
      unit=Unit.getByName(UnitName)
    else
      unit=self:GetDCSUnit()
    end

    if unit then

      local pos=unit:getPosition()

      local heading=math.atan2(pos.x.z, pos.x.x)

      if heading<0 then
        heading=heading+ 2*math.pi
      end

      heading=math.deg(heading)

      return heading
    end

  else
    self:T(self.lid.."WARNING: Group does not exist. Cannot get heading!")
  end

  return nil
end

--- Get current orientation of the group.
-- @param #OPSGROUP self
-- @param #string UnitName (Optional) Get orientation of a specific unit of the group. Default is the first existing unit of the group.
-- @return DCS#Vec3 Orientation X parallel to where the "nose" is pointing.
-- @return DCS#Vec3 Orientation Y pointing "upwards".
-- @return DCS#Vec3 Orientation Z perpendicular to the "nose".
function OPSGROUP:GetOrientation(UnitName)

  if self:IsExist() then

    local unit=nil --DCS#Unit

    if UnitName then
      unit=Unit.getByName(UnitName)
    else
      unit=self:GetDCSUnit()
    end

    if unit then

      local pos=unit:getPosition()

      return pos.x, pos.y, pos.z
    end

  else
    self:T(self.lid.."WARNING: Group does not exist. Cannot get orientation!")
  end

  return nil
end

--- Get current "X" orientation of the first unit in the group.
-- @param #OPSGROUP self
-- @param #string UnitName (Optional) Get orientation of a specific unit of the group. Default is the first existing unit of the group.
-- @return DCS#Vec3 Orientation X parallel to where the "nose" is pointing.
function OPSGROUP:GetOrientationX(UnitName)

  local X,Y,Z=self:GetOrientation(UnitName)

  return X
end



--- Check if task description is unique.
-- @param #OPSGROUP self
-- @param #string description Task destription
-- @return #boolean If true, no other task has the same description.
function OPSGROUP:CheckTaskDescriptionUnique(description)

  -- Loop over tasks in queue
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.description==description then
      return false
    end
  end

  return true
end


--- Despawn a unit of the group. A "Remove Unit" event is generated by default.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit
-- @param #number Delay Delay in seconds before the group will be despawned. Default immediately.
-- @param #boolean NoEventRemoveUnit If true, no event "Remove Unit" is generated.
-- @return #OPSGROUP self
function OPSGROUP:DespawnUnit(UnitName, Delay, NoEventRemoveUnit)

  -- Debug info.
  self:T(self.lid.."Despawn element "..tostring(UnitName))

  -- Get element.
  local element=self:GetElementByName(UnitName)

  if element then

    -- Get DCS unit object.
    local DCSunit=Unit.getByName(UnitName)

    if DCSunit then

      -- Despawn unit.
      DCSunit:destroy()

      -- Element goes back in utero.
      self:ElementInUtero(element)

      if not NoEventRemoveUnit then
        self:CreateEventRemoveUnit(timer.getTime(), DCSunit)
      end

    end

  end

end

--- Despawn an element/unit of the group.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element Element The element that will be despawned.
-- @param #number Delay Delay in seconds before the element will be despawned. Default immediately.
-- @param #boolean NoEventRemoveUnit If true, no event "Remove Unit" is generated.
-- @return #OPSGROUP self
function OPSGROUP:DespawnElement(Element, Delay, NoEventRemoveUnit)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.DespawnElement, self, Element, 0, NoEventRemoveUnit)
  else

    if Element then

      -- Get DCS unit object.
      local DCSunit=Unit.getByName(Element.name)

      if DCSunit then

        -- Destroy object.
        DCSunit:destroy()

        -- Create a remove unit event.
        if not NoEventRemoveUnit then
          self:CreateEventRemoveUnit(timer.getTime(), DCSunit)
        end

      end

    end

  end

  return self
end

--- Despawn the group. The whole group is despawned and a "`Remove Unit`" event is generated for all current units of the group.
-- If no `Remove Unit` event should be generated, the second optional parameter needs to be set to `true`.
-- If this group belongs to an AIRWING, BRIGADE or FLEET, it will be added to the warehouse stock if the `NoEventRemoveUnit` parameter is `false` or `nil`.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds before the group will be despawned. Default immediately.
-- @param #boolean NoEventRemoveUnit If `true`, **no** event "Remove Unit" is generated.
-- @return #OPSGROUP self
function OPSGROUP:Despawn(Delay, NoEventRemoveUnit)

  if Delay and Delay>0 then
    self.scheduleIDDespawn=self:ScheduleOnce(Delay, OPSGROUP.Despawn, self, 0, NoEventRemoveUnit)
  else

    -- Debug info.
    self:T(self.lid..string.format("Despawning Group!"))

    -- DCS group obejct.
    local DCSGroup=self:GetDCSGroup()

    if DCSGroup then

      -- Clear any task ==> makes DCS crash!
      --self.group:ClearTasks()

      -- Get all units.
      local units=self:GetDCSUnits()

      for i=1,#units do
        local unit=units[i]
        if unit then
          local name=unit:getName()
          if name then
            -- Despawn the unit.
            self:DespawnUnit(name, 0, NoEventRemoveUnit)
          end
        end
      end

    end
  end

  return self
end

--- Return group back to the legion it belongs to.
-- Group is despawned and added back to the stock.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds before the group will be despawned. Default immediately
-- @return #OPSGROUP self
function OPSGROUP:ReturnToLegion(Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.ReturnToLegion, self)
  else

    if self.legion then
      -- Add asset back.
      self:T(self.lid..string.format("Adding asset back to LEGION"))
      self.legion:AddAsset(self.group, 1)
    else
      self:E(self.lid..string.format("ERROR: Group does not belong to a LEGION!"))
    end
    
  end

  return self
end

--- Destroy a unit of the group. A *Unit Lost* for aircraft or *Dead* event for ground/naval units is generated.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit which should be destroyed.
-- @param #number Delay Delay in seconds before the group will be destroyed. Default immediately.
-- @return #OPSGROUP self
function OPSGROUP:DestroyUnit(UnitName, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.DestroyUnit, self, UnitName, 0)
  else

    local unit=Unit.getByName(UnitName)

    if unit then

      -- Create a "Unit Lost" event.
      local EventTime=timer.getTime()

      if self:IsFlightgroup() then
        self:CreateEventUnitLost(EventTime, unit)
      else
        self:CreateEventDead(EventTime, unit)
      end
      
      -- Despawn unit.
      unit:destroy()      

    end

  end

end

--- Destroy group. The whole group is despawned and a *Unit Lost* for aircraft or *Dead* event for ground/naval units is generated for all current units.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds before the group will be destroyed. Default immediately.
-- @return #OPSGROUP self
function OPSGROUP:Destroy(Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.Destroy, self, 0)
  else
  
    self:T(self.lid.."Destroying group!")

    -- Get all units.
    local units=self:GetDCSUnits()

    if units then

      -- Create a "Unit Lost" event.
      for _,unit in pairs(units) do
        if unit then
          self:DestroyUnit(unit:getName())
        end
      end

    end

  end

  return self
end

--- Activate a *late activated* group.
-- @param #OPSGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is activated. Default is immediately.
-- @return #OPSGROUP self
function OPSGROUP:Activate(delay)

  if delay and delay>0 then
    self:T2(self.lid..string.format("Activating late activated group in %d seconds", delay))
    self:ScheduleOnce(delay, OPSGROUP.Activate, self)
  else

    if self:IsAlive()==false then

      self:T(self.lid.."Activating late activated group")
      self.group:Activate()
      self.isLateActivated=false

    elseif self:IsAlive()==true then
      self:T(self.lid.."WARNING: Activating group that is already activated")
    else
      self:T(self.lid.."ERROR: Activating group that is does not exist!")
    end

  end

  return self
end

--- Deactivate the group. Group will be respawned in late activated state.
-- @param #OPSGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is deactivated. Default is immediately.
-- @return #OPSGROUP self
function OPSGROUP:Deactivate(delay)

  if delay and delay>0 then
    self:ScheduleOnce(delay, OPSGROUP.Deactivate, self)
  else

    if self:IsAlive()==true then

      self.template.lateActivation=true

      local template=UTILS.DeepCopy(self.template)

      self:_Respawn(0, template)

    end

  end

  return self
end

--- Self destruction of group. An explosion is created at the position of each element.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds. Default now.
-- @param #number ExplosionPower (Optional) Explosion power in kg TNT. Default 100 kg.
-- @param #string ElementName Name of the element that should be destroyed. Default is all elements.
-- @return #OPSGROUP self
function OPSGROUP:SelfDestruction(Delay, ExplosionPower, ElementName)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.SelfDestruction, self, 0, ExplosionPower, ElementName)
  else

    -- Loop over all elements.
    for i,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      
      if ElementName==nil or ElementName==element.name then

        local unit=element.unit
  
        if unit and unit:IsAlive() then
          unit:Explode(ExplosionPower or 100)
        end
        
      end
    end
  end

  return self
end

--- Use SRS Simple-Text-To-Speech for transmissions.
-- @param #OPSGROUP self
-- @param #string PathToSRS Path to SRS directory.
-- @param #string Gender Gender: "male" or "female" (default).
-- @param #string Culture Culture, e.g. "en-GB" (default).
-- @param #string Voice Specific voice. Overrides `Gender` and `Culture`.
-- @param #number Port SRS port. Default 5002.
-- @param #string PathToGoogleKey Full path to the google credentials JSON file, e.g. `"C:\Users\myUsername\Downloads\key.json"`.
-- @param #string Label Label of the SRS comms for the SRS Radio overlay. Defaults to "ROBOT". No spaces allowed!
-- @param #number Volume Volume to be set, 0.0 = silent, 1.0 = loudest. Defaults to 1.0
-- @return #OPSGROUP self
function OPSGROUP:SetSRS(PathToSRS, Gender, Culture, Voice, Port, PathToGoogleKey, Label, Volume)
  self.useSRS=true
  local path = PathToSRS or MSRS.path
  local port = Port or MSRS.port
  self.msrs=MSRS:New(path, self.frequency, self.modulation)
  self.msrs:SetGender(Gender)
  self.msrs:SetCulture(Culture)
  self.msrs:SetVoice(Voice)
  self.msrs:SetPort(port)
  self.msrs:SetLabel(Label)
  if PathToGoogleKey then
    self.msrs:SetProviderOptionsGoogle(PathToGoogleKey,PathToGoogleKey)
    self.msrs:SetProvider(MSRS.Provider.GOOGLE)
  end
  self.msrs:SetCoalition(self:GetCoalition())
  self.msrs:SetVolume(Volume)
  return self
end

--- Send a radio transmission via SRS Text-To-Speech.
-- @param #OPSGROUP self
-- @param #string Text Text of transmission.
-- @param #number Delay Delay in seconds before the transmission is started.
-- @param #boolean SayCallsign If `true`, the callsign is prepended to the given text. Default `false`.
-- @param #number Frequency Override sender frequency, helpful when you need multiple radios from the same sender. Default is the frequency set for the OpsGroup.
-- @return #OPSGROUP self
function OPSGROUP:RadioTransmission(Text, Delay, SayCallsign, Frequency)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.RadioTransmission, self, Text, 0, SayCallsign)
  else

    if self.useSRS and self.msrs then

      local freq, modu, radioon=self:GetRadio()
      
      local coord = self:GetCoordinate()
      
      self.msrs:SetCoordinate(coord)
      
      if Frequency then
        self.msrs:SetFrequencies(Frequency)
      else
        self.msrs:SetFrequencies(freq)
      end
      self.msrs:SetModulations(modu)
      
      if SayCallsign then
        local callsign=self:GetCallsignName()
        Text=string.format("%s, %s", callsign, Text)
      end

      -- Debug info.
      self:T(self.lid..string.format("Radio transmission on %.3f MHz %s: %s", freq, UTILS.GetModulationName(modu), Text))

      self.msrs:PlayText(Text)
    end

  end

  return self
end

--- Set that this carrier is an all aspect loader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierLoaderAllAspect(Length, Width)
  self.carrierLoader.type="front"
  self.carrierLoader.length=Length or 50
  self.carrierLoader.width=Width or 20
  return self
end

--- Set that this carrier is a front loader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierLoaderFront(Length, Width)
  self.carrierLoader.type="front"
  self.carrierLoader.length=Length or 50
  self.carrierLoader.width=Width or 20
  return self
end

--- Set that this carrier is a back loader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierLoaderBack(Length, Width)
  self.carrierLoader.type="back"
  self.carrierLoader.length=Length or 50
  self.carrierLoader.width=Width or 20
  return self
end

--- Set that this carrier is a starboard (right side) loader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierLoaderStarboard(Length, Width)
  self.carrierLoader.type="right"
  self.carrierLoader.length=Length or 50
  self.carrierLoader.width=Width or 20
  return self
end

--- Set that this carrier is a port (left side) loader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierLoaderPort(Length, Width)
  self.carrierLoader.type="left"
  self.carrierLoader.length=Length or 50
  self.carrierLoader.width=Width or 20
  return self
end


--- Set that this carrier is an all aspect unloader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierUnloaderAllAspect(Length, Width)
  self.carrierUnloader.type="front"
  self.carrierUnloader.length=Length or 50
  self.carrierUnloader.width=Width or 20
  return self
end

--- Set that this carrier is a front unloader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierUnloaderFront(Length, Width)
  self.carrierUnloader.type="front"
  self.carrierUnloader.length=Length or 50
  self.carrierUnloader.width=Width or 20
  return self
end

--- Set that this carrier is a back unloader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierUnloaderBack(Length, Width)
  self.carrierUnloader.type="back"
  self.carrierUnloader.length=Length or 50
  self.carrierUnloader.width=Width or 20
  return self
end

--- Set that this carrier is a starboard (right side) unloader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierUnloaderStarboard(Length, Width)
  self.carrierUnloader.type="right"
  self.carrierUnloader.length=Length or 50
  self.carrierUnloader.width=Width or 20
  return self
end

--- Set that this carrier is a port (left side) unloader.
-- @param #OPSGROUP self
-- @param #number Length Length of loading zone in meters. Default 50 m.
-- @param #number Width Width of loading zone in meters. Default 20 m.
-- @return #OPSGROUP self
function OPSGROUP:SetCarrierUnloaderPort(Length, Width)
  self.carrierUnloader.type="left"
  self.carrierUnloader.length=Length or 50
  self.carrierUnloader.width=Width or 20
  return self
end

--- Check if group is currently inside a zone.
-- @param #OPSGROUP self
-- @param Core.Zone#ZONE Zone The zone.
-- @return #boolean If true, group is in this zone
function OPSGROUP:IsInZone(Zone)
  local vec2=self:GetVec2()
  local is=false
  if vec2 then
    is=Zone:IsVec2InZone(vec2)
  else
    self:T3(self.lid.."WARNING: Cannot get vec2 at IsInZone()!")
  end
  return is
end

--- Get 2D distance to a coordinate.
-- @param #OPSGROUP self
-- @param Core.Point#COORDINATE Coordinate. Can also be a DCS#Vec2 or DCS#Vec3.
-- @return #number Distance in meters.
function OPSGROUP:Get2DDistance(Coordinate)

  local a=self:GetVec2()
  local b={}
  if Coordinate.z then
    b.x=Coordinate.x
    b.y=Coordinate.z
  else
    b.x=Coordinate.x
    b.y=Coordinate.y
  end

  local dist=UTILS.VecDist2D(a, b)

  return dist
end

--- Check if this is a FLIGHTGROUP.
-- @param #OPSGROUP self
-- @return #boolean If true, this is an airplane or helo group.
function OPSGROUP:IsFlightgroup()
  return self.isFlightgroup
end

--- Check if this is a ARMYGROUP.
-- @param #OPSGROUP self
-- @return #boolean If true, this is a ground group.
function OPSGROUP:IsArmygroup()
  return self.isArmygroup
end

--- Check if this is a NAVYGROUP.
-- @param #OPSGROUP self
-- @return #boolean If true, this is a ship group.
function OPSGROUP:IsNavygroup()
  return self.isNavygroup
end


--- Check if group is exists.
-- @param #OPSGROUP self
-- @return #boolean If true, the group exists or false if the group does not exist. If nil, the DCS group could not be found.
function OPSGROUP:IsExist()

  local DCSGroup=self:GetDCSGroup()

  if DCSGroup then
    local exists=DCSGroup:isExist()
    return exists
  end

  return nil
end

--- Check if group is activated.
-- @param #OPSGROUP self
-- @return #boolean If true, the group exists or false if the group does not exist. If nil, the DCS group could not be found.
function OPSGROUP:IsActive()

  if self.group then
    local active=self.group:IsActive()
    return active
  end

  return nil
end

--- Check if group is alive.
-- @param #OPSGROUP self
-- @return #boolean *true* if group is exists and is activated, *false* if group is exist but is NOT activated. *nil* otherwise, e.g. the GROUP object is *nil* or the group is not spawned yet.
function OPSGROUP:IsAlive()

  if self.group then
    local alive=self.group:IsAlive()
    return alive
  end

  return nil
end

--- Check if this group is currently "late activated" and needs to be "activated" to appear in the mission.
-- @param #OPSGROUP self
-- @return #boolean Is this the group late activated?
function OPSGROUP:IsLateActivated()
  return self.isLateActivated
end

--- Check if group is in state in utero. Note that dead groups are also in utero but will return `false` here.
-- @param #OPSGROUP self
-- @return #boolean If true, group is not spawned yet.
function OPSGROUP:IsInUtero()
  local is=self:Is("InUtero") and not self:IsDead()
  return is
end

--- Check if group is in state spawned.
-- @param #OPSGROUP self
-- @return #boolean If true, group is spawned.
function OPSGROUP:IsSpawned()
  local is=self:Is("Spawned")
  return is
end

--- Check if group is dead. Could be destroyed or despawned. FSM state of dead group is `InUtero` though.
-- @param #OPSGROUP self
-- @return #boolean If true, all units/elements of the group are dead.
function OPSGROUP:IsDead()
  return self.isDead
end

--- Check if group was destroyed.
-- @param #OPSGROUP self
-- @return #boolean If true, all units/elements of the group were destroyed.
function OPSGROUP:IsDestroyed()
  return self.isDestroyed
end

--- Check if FSM is stopped.
-- @param #OPSGROUP self
-- @return #boolean If true, FSM state is stopped.
function OPSGROUP:IsStopped()
  local is=self:Is("Stopped")
  return is
end

--- Check if this group is currently "uncontrolled" and needs to be "started" to begin its route.
-- @param #OPSGROUP self
-- @return #boolean If true, this group uncontrolled.
function OPSGROUP:IsUncontrolled()
  return self.isUncontrolled
end

--- Check if this group has passed its final waypoint.
-- @param #OPSGROUP self
-- @return #boolean If true, this group has passed the final waypoint.
function OPSGROUP:HasPassedFinalWaypoint()
  return self.passedfinalwp
end

--- Check if the group is currently rearming or on its way to the rearming place.
-- @param #OPSGROUP self
-- @return #boolean If true, group is rearming.
function OPSGROUP:IsRearming()
  local rearming=self:Is("Rearming") or self:Is("Rearm")
  return rearming
end

--- Check if the group is completely out of ammo.
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is out-of-ammo.
function OPSGROUP:IsOutOfAmmo()
  return self.outofAmmo
end

--- Check if the group is out of bombs.
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is out of bombs.
function OPSGROUP:IsOutOfBombs()
  return self.outofBombs
end

--- Check if the group is out of guns.
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is out of guns.
function OPSGROUP:IsOutOfGuns()
  return self.outofGuns
end

--- Check if the group is out of missiles.
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is out of missiles.
function OPSGROUP:IsOutOfMissiles()
  return self.outofMissiles
end

--- Check if the group is out of torpedos.
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is out of torpedos.
function OPSGROUP:IsOutOfTorpedos()
  return self.outofTorpedos
end

--- Check if the group is out of A2G Ammo
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is out of torpedos.
function OPSGROUP:IsOutOfA2GAmmo()
  if (self.outofMissilesAG and self.outofBombs and self.outofGuns) or self.outofAmmo then
    return true
  end
  return false
end

--- Check if the group has currently switched a LASER on.
-- @param #OPSGROUP self
-- @return #boolean If true, LASER of the group is on.
function OPSGROUP:IsLasing()
  return self.spot.On
end

--- Check if the group is currently retreating or retreated.
-- @param #OPSGROUP self
-- @return #boolean If true, group is retreating or retreated.
function OPSGROUP:IsRetreating()
  local is=self:is("Retreating") or self:is("Retreated")
  return is
end

--- Check if the group is retreated (has reached its retreat zone).
-- @param #OPSGROUP self
-- @return #boolean If true, group is retreated.
function OPSGROUP:IsRetreated()
  local is=self:is("Retreated")
  return is
end


--- Check if the group is currently returning to a zone.
-- @param #OPSGROUP self
-- @return #boolean If true, group is returning.
function OPSGROUP:IsReturning()
  local is=self:is("Returning")
  return is
end

--- Check if the group is engaging another unit or group.
-- @param #OPSGROUP self
-- @return #boolean If true, group is engaging.
function OPSGROUP:IsEngaging()
  local is=self:is("Engaging")
  return is
end

--- Check if group is currently waiting.
-- @param #OPSGROUP self
-- @return #boolean If true, group is currently waiting.
function OPSGROUP:IsWaiting()
  if self.Twaiting then
    return true
  end
  return false
end

--- Check if the group is not a carrier yet.
-- @param #OPSGROUP self
-- @return #boolean If true, group is not a carrier.
function OPSGROUP:IsNotCarrier()
  return self.carrierStatus==OPSGROUP.CarrierStatus.NOTCARRIER
end

--- Check if the group is a carrier.
-- @param #OPSGROUP self
-- @return #boolean If true, group is a carrier.
function OPSGROUP:IsCarrier()
  return not self:IsNotCarrier()
end

--- Check if the group is picking up cargo.
-- @param #OPSGROUP self
-- @return #boolean If true, group is picking up.
function OPSGROUP:IsPickingup()
  return self.carrierStatus==OPSGROUP.CarrierStatus.PICKUP
end

--- Check if the group is loading cargo.
-- @param #OPSGROUP self
-- @return #boolean If true, group is loading.
function OPSGROUP:IsLoading()
  return self.carrierStatus==OPSGROUP.CarrierStatus.LOADING
end

--- Check if the group is transporting cargo.
-- @param #OPSGROUP self
-- @return #boolean If true, group is transporting.
function OPSGROUP:IsTransporting()
  return self.carrierStatus==OPSGROUP.CarrierStatus.TRANSPORTING
end

--- Check if the group is unloading cargo.
-- @param #OPSGROUP self
-- @return #boolean If true, group is unloading.
function OPSGROUP:IsUnloading()
  return self.carrierStatus==OPSGROUP.CarrierStatus.UNLOADING
end


--- Check if the group is assigned as cargo.
-- @param #OPSGROUP self
-- @param #boolean CheckTransport If `true` or `nil`, also check if cargo is associated with a transport assignment. If not, we consider it not cargo.
-- @return #boolean If true, group is cargo.
function OPSGROUP:IsCargo(CheckTransport)
  return not self:IsNotCargo(CheckTransport)
end

--- Check if the group is **not** cargo.
-- @param #OPSGROUP self
-- @param #boolean CheckTransport If `true` or `nil`, also check if cargo is associated with a transport assignment. If not, we consider it not cargo.
-- @return #boolean If true, group is *not* cargo.
function OPSGROUP:IsNotCargo(CheckTransport)
  local notcargo=self.cargoStatus==OPSGROUP.CargoStatus.NOTCARGO

  if notcargo then
    -- Not cargo.
    return true
  else
    -- Is cargo (e.g. loaded or boarding)

    if CheckTransport then
      -- Check if transport UID was set.
      if self.cargoTransportUID==nil then
        return true
      else
        -- Some transport UID was assigned.
        return false
      end
    else
      -- Is cargo.
      return false
    end

  end


  return notcargo
end

--- Check if awaiting a transport.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
-- @return #OPSGROUP self
function OPSGROUP:_AddMyLift(Transport)
  self.mylifts=self.mylifts or {}
  self.mylifts[Transport.uid]=true
  return self
end

--- Remove my lift.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
-- @return #OPSGROUP self
function OPSGROUP:_DelMyLift(Transport)
  if self.mylifts then
    self.mylifts[Transport.uid]=nil
  end
  return self
end


--- Check if awaiting a transport lift.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport (Optional) The transport.
-- @return #boolean If true, group is awaiting transport lift..
function OPSGROUP:IsAwaitingLift(Transport)

  if self.mylifts then

    for uid,iswaiting in pairs(self.mylifts) do
      if Transport==nil or Transport.uid==uid then
        if iswaiting==true then
          return true
        end
      end
    end

  end

  return false
end

--- Get paused mission.
-- @param #OPSGROUP self
-- @return Ops.Auftrag#AUFTRAG Paused mission or nil.
function OPSGROUP:_GetPausedMission()

  if self.pausedmissions and #self.pausedmissions>0 then
    for _,mid in pairs(self.pausedmissions) do
      if mid then
        local mission=self:GetMissionByID(mid)
        if mission and mission:IsNotOver() then
          return mission
        end
      end
    end
  end
  
  return nil
end

--- Count paused mission.
-- @param #OPSGROUP self
-- @return #number Number of paused missions.
function OPSGROUP:_CountPausedMissions()
  local N=0
  if self.pausedmissions and #self.pausedmissions>0 then
    for _,mid in pairs(self.pausedmissions) do
      local mission=self:GetMissionByID(mid)
      if mission and mission:IsNotOver() then
        N=N+1
      end
    end
  end
  
  return N
end

--- Remove paused mission from the table.
-- @param #OPSGROUP self
-- @param #number AuftragsNummer Mission ID of the paused mission to remove.
-- @return #OPSGROUP self
function OPSGROUP:_RemovePausedMission(AuftragsNummer)

  if self.pausedmissions and #self.pausedmissions>0 then
    for i=#self.pausedmissions,1,-1 do
      local mid=self.pausedmissions[i]
      if mid==AuftragsNummer then
        table.remove(self.pausedmissions, i)
        return self
      end
    end
  end
  
  return self
end

--- Check if the group is currently boarding a carrier.
-- @param #OPSGROUP self
-- @param #string CarrierGroupName (Optional) Additionally check if group is boarding this particular carrier group.
-- @return #boolean If true, group is boarding.
function OPSGROUP:IsBoarding(CarrierGroupName)
  if CarrierGroupName then
    local carrierGroup=self:_GetMyCarrierGroup()
    if carrierGroup and carrierGroup.groupname~=CarrierGroupName then
      return false
    end
  end
  return self.cargoStatus==OPSGROUP.CargoStatus.BOARDING
end

--- Check if the group is currently loaded into a carrier.
-- @param #OPSGROUP self
-- @param #string CarrierGroupName (Optional) Additionally check if group is loaded into a particular carrier group(s).
-- @return #boolean If true, group is loaded.
function OPSGROUP:IsLoaded(CarrierGroupName)

  local isloaded=self.cargoStatus==OPSGROUP.CargoStatus.LOADED
  
  -- If not loaded, we can return false
  if not isloaded then
    return false
  end

  if CarrierGroupName then
    if type(CarrierGroupName)~="table" then
      CarrierGroupName={CarrierGroupName}
    end
    for _,CarrierName in pairs(CarrierGroupName) do
      local carrierGroup=self:_GetMyCarrierGroup()
      if carrierGroup and carrierGroup.groupname==CarrierName then
        return isloaded
      end
    end
    -- Not in any specified carrier.
    return false
  end
  
  return isloaded
end

--- Check if the group is currently busy doing something.
--
-- * Boarding
-- * Rearming
-- * Returning
-- * Pickingup, Loading, Transporting, Unloading
-- * Engageing
--
-- @param #OPSGROUP self
-- @return #boolean If `true`, group is busy.
function OPSGROUP:IsBusy()

  if self:IsBoarding() then
    return true
  end

  if self:IsRearming() then
    return true
  end

  if self:IsReturning() then
    return true
  end

  -- Busy as carrier?
  if self:IsPickingup() or self:IsLoading() or self:IsTransporting() or self:IsUnloading() then
    return true
  end

  if self:IsEngaging() then
    return true
  end


  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Waypoint Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the waypoints.
-- @param #OPSGROUP self
-- @return #table Table of all waypoints.
function OPSGROUP:GetWaypoints()
  return self.waypoints
end

--- Mark waypoints on F10 map.
-- @param #OPSGROUP self
-- @param #number Duration Duration in seconds how long the waypoints are displayed before they are automatically removed. Default is that they are never removed.
-- @return #OPSGROUP self
function OPSGROUP:MarkWaypoints(Duration)

  for i,_waypoint in pairs(self.waypoints or {}) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint

    local text=string.format("Waypoint ID=%d of %s", waypoint.uid, self.groupname)
    text=text..string.format("\nSpeed=%.1f kts, Alt=%d ft (%s)", UTILS.MpsToKnots(waypoint.speed), UTILS.MetersToFeet(waypoint.alt or 0), "BARO")

    if waypoint.marker then
      if waypoint.marker.text~=text then
        waypoint.marker.text=text
      end

    else
      waypoint.marker=MARKER:New(waypoint.coordinate, text):ToCoalition(self:GetCoalition())
    end
  end


  if Duration then
    self:RemoveWaypointMarkers(Duration)
  end

  return self
end

--- Remove waypoints markers on the F10 map.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds before the markers are removed. Default is immediately.
-- @return #OPSGROUP self
function OPSGROUP:RemoveWaypointMarkers(Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.RemoveWaypointMarkers, self)
  else

    for i,_waypoint in pairs(self.waypoints or {}) do
      local waypoint=_waypoint --#OPSGROUP.Waypoint

      if waypoint.marker then
        waypoint.marker:Remove()
      end
    end

  end

  return self
end


--- Get the waypoint from its unique ID.
-- @param #OPSGROUP self
-- @param #number uid Waypoint unique ID.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:GetWaypointByID(uid)

  for _,_waypoint in pairs(self.waypoints or {}) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint
    if waypoint.uid==uid then
      return waypoint
    end
  end

  return nil
end

--- Get the waypoint from its index.
-- @param #OPSGROUP self
-- @param #number index Waypoint index.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:GetWaypointByIndex(index)

  for i,_waypoint in pairs(self.waypoints) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint
    if i==index then
      return waypoint
    end
  end

  return nil
end

--- Get the waypoint UID from its index, i.e. its current position in the waypoints table.
-- @param #OPSGROUP self
-- @param #number index Waypoint index.
-- @return #number Unique waypoint ID.
function OPSGROUP:GetWaypointUIDFromIndex(index)

  for i,_waypoint in pairs(self.waypoints) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint
    if i==index then
      return waypoint.uid
    end
  end

  return nil
end

--- Get the waypoint index (its position in the current waypoints table).
-- @param #OPSGROUP self
-- @param #number uid Waypoint unique ID.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:GetWaypointIndex(uid)

  if uid then
    for i,_waypoint in pairs(self.waypoints or {}) do
      local waypoint=_waypoint --#OPSGROUP.Waypoint
      if waypoint.uid==uid then
        return i
      end
    end
  end

  return nil
end

--- Get next waypoint index.
-- @param #OPSGROUP self
-- @param #boolean cyclic If `true`, return first waypoint if last waypoint was reached. Default is patrol ad infinitum value set.
-- @param #number i Waypoint index from which the next index is returned. Default is the last waypoint passed.
-- @return #number Next waypoint index.
function OPSGROUP:GetWaypointIndexNext(cyclic, i)

  -- If not specified, we take the adinititum value.
  if cyclic==nil then
    cyclic=self.adinfinitum
  end

  -- Total number of waypoints.
  local N=#self.waypoints

  -- Default is currentwp.
  i=i or self.currentwp

  -- If no next waypoint exists, because the final waypoint was reached, we return the last waypoint.
  local n=math.min(i+1, N)

  -- If last waypoint was reached, the first waypoint is the next in line.
  if cyclic and i==N then
    n=1
  end

  return n
end

--- Get current waypoint index. This is the index of the last passed waypoint.
-- @param #OPSGROUP self
-- @return #number Current waypoint index.
function OPSGROUP:GetWaypointIndexCurrent()
  return self.currentwp or 1
end

--- Get waypoint index after waypoint with given ID. So if the waypoint has index 3 it will return 4.
-- @param #OPSGROUP self
-- @param #number uid Unique ID of the waypoint. Default is new waypoint index after the last current one.
-- @return #number Index after waypoint with given ID.
function OPSGROUP:GetWaypointIndexAfterID(uid)

  local index=self:GetWaypointIndex(uid)
  if index then
    return index+1
  else
    return #self.waypoints+1
  end

end

--- Get waypoint.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #OPSGROUP.Waypoint Waypoint table.
function OPSGROUP:GetWaypoint(indx)
  return self.waypoints[indx]
end

--- Get final waypoint.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Waypoint Final waypoint table.
function OPSGROUP:GetWaypointFinal()
  return self.waypoints[#self.waypoints]
end

--- Get next waypoint.
-- @param #OPSGROUP self
-- @param #boolean cyclic If true, return first waypoint if last waypoint was reached.
-- @return #OPSGROUP.Waypoint Next waypoint table.
function OPSGROUP:GetWaypointNext(cyclic)

  local n=self:GetWaypointIndexNext(cyclic)

  return self.waypoints[n]
end

--- Get current waypoint.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Waypoint Current waypoint table.
function OPSGROUP:GetWaypointCurrent()
  return self.waypoints[self.currentwp]
end

--- Get current waypoint UID.
-- @param #OPSGROUP self
-- @return #number Current waypoint UID.
function OPSGROUP:GetWaypointCurrentUID()
  local wp=self:GetWaypointCurrent()
  if wp then
    return wp.uid
  end
  return nil
end

--- Get coordinate of next waypoint of the group.
-- @param #OPSGROUP self
-- @param #boolean cyclic If true, return first waypoint if last waypoint was reached.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function OPSGROUP:GetNextWaypointCoordinate(cyclic)

  -- Get next waypoint
  local waypoint=self:GetWaypointNext(cyclic)

  return waypoint.coordinate
end

--- Get waypoint coordinates.
-- @param #OPSGROUP self
-- @param #number index Waypoint index.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function OPSGROUP:GetWaypointCoordinate(index)
  local waypoint=self:GetWaypoint(index)
  if waypoint then
    return waypoint.coordinate
  end
  return nil
end

--- Get waypoint speed.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #number Speed set at waypoint in knots.
function OPSGROUP:GetWaypointSpeed(indx)

  local waypoint=self:GetWaypoint(indx)

  if waypoint then
    return UTILS.MpsToKnots(waypoint.speed)
  end

  return nil
end

--- Get unique ID of waypoint.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint waypoint The waypoint data table.
-- @return #number Unique ID.
function OPSGROUP:GetWaypointUID(waypoint)
  return waypoint.uid
end

--- Get unique ID of waypoint given its index.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #number Unique ID.
function OPSGROUP:GetWaypointID(indx)

  local waypoint=self:GetWaypoint(indx)

  if waypoint then
    return waypoint.uid
  end

  return nil

end

--- Returns a non-zero speed to the next waypoint (even if the waypoint speed is zero).
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #number Speed to next waypoint (>0) in knots.
function OPSGROUP:GetSpeedToWaypoint(indx)

  local speed=self:GetWaypointSpeed(indx)

  if speed<=0.01 then
    speed=self:GetSpeedCruise()
  end

  return speed
end

--- Get distance to waypoint.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index. Default is the next waypoint.
-- @return #number Distance in meters.
function OPSGROUP:GetDistanceToWaypoint(indx)
  local dist=0

  if #self.waypoints>0 then

    indx=indx or self:GetWaypointIndexNext()

    local wp=self:GetWaypoint(indx)

    if wp then

      local coord=self:GetCoordinate()

      dist=coord:Get2DDistance(wp.coordinate)
    end

  end

  return dist
end

--- Get time to waypoint based on current velocity.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index. Default is the next waypoint.
-- @return #number Time in seconds. If velocity is 0
function OPSGROUP:GetTimeToWaypoint(indx)

  local s=self:GetDistanceToWaypoint(indx)

  local v=self:GetVelocity()

  local t=s/v

  if t==math.inf then
    return 365*24*60*60
  elseif t==math.nan then
    return 0
  else
    return t
  end

end

--- Returns the currently expected speed.
-- @param #OPSGROUP self
-- @return #number Expected speed in m/s.
function OPSGROUP:GetExpectedSpeed()

  if self:IsHolding() or self:Is("Rearming") or self:IsWaiting() or self:IsRetreated() then
    --env.info("GetExpectedSpeed - returning ZERO")
    return 0
  else
    --env.info("GetExpectedSpeed - returning self.speedWP = "..self.speedWp)
    return self.speedWp or 0
  end

end

--- Remove a waypoint with a ceratin UID.
-- @param #OPSGROUP self
-- @param #number uid Waypoint UID.
-- @return #OPSGROUP self
function OPSGROUP:RemoveWaypointByID(uid)

  local index=self:GetWaypointIndex(uid)

  if index then
    self:RemoveWaypoint(index)
  end

  return self
end

--- Remove a waypoint.
-- @param #OPSGROUP self
-- @param #number wpindex Waypoint number.
-- @return #OPSGROUP self
function OPSGROUP:RemoveWaypoint(wpindex)

  if self.waypoints then

    -- The waypoitn to be removed.
    local wp=self:GetWaypoint(wpindex)

    -- Is this a temporary waypoint.
    local istemp=wp.temp or wp.detour or wp.astar or wp.missionUID

    -- Number of waypoints before delete.
    local N=#self.waypoints

    -- Always keep at least one waypoint.
    if N==1 then
      self:T(self.lid..string.format("ERROR: Cannot remove waypoint with index=%d! It is the only waypoint and a group needs at least ONE waypoint", wpindex))
      return self
    end

    -- Check that wpindex is not larger than the number of waypoints in the table.
    if wpindex>N then
      self:T(self.lid..string.format("ERROR: Cannot remove waypoint with index=%d as there are only N=%d waypoints!", wpindex, N))
      return self
    end

    -- Remove waypoint marker.
    if wp and wp.marker then
      wp.marker:Remove()
    end

    -- Remove waypoint.
    table.remove(self.waypoints, wpindex)

    -- Number of waypoints after delete.
    local n=#self.waypoints

    -- Debug info.
    self:T(self.lid..string.format("Removing waypoint UID=%d [temp=%s]: index=%d [currentwp=%d]. N %d-->%d", wp.uid, tostring(istemp), wpindex, self.currentwp, N, n))

    -- Waypoint was not reached yet.
    if wpindex > self.currentwp then

      ---
      -- Removed a FUTURE waypoint
      ---

      -- TODO: patrol adinfinitum. Not sure this is handled correctly. If patrol adinfinitum and we have now only one WP left, we should at least go back.

      -- Could be that the waypoint we are currently moving to was the LAST waypoint. Then we now passed the final waypoint.
      if self.currentwp>=n and not (self.adinfinitum or istemp) then
        self:_PassedFinalWaypoint(true, "Removed FUTURE waypoint we are currently moving to and that was the LAST waypoint")
      end

      -- Check if group is done.
      self:_CheckGroupDone(1)

    else

      ---
      -- Removed a waypoint ALREADY PASSED
      ---

      -- If an already passed waypoint was deleted, we do not need to update the route.

      -- If current wp = 1 it stays 1. Otherwise decrease current wp.

      if self.currentwp==1 then

        if self.adinfinitum then
          self.currentwp=#self.waypoints
        else
          self.currentwp=1
        end

      else
        self.currentwp=self.currentwp-1
      end
      
      -- Could be that the waypoint we are currently moving to was the LAST waypoint. Then we now passed the final waypoint.
      if (self.adinfinitum or istemp) then
        self:_PassedFinalWaypoint(false, "Removed PASSED temporary waypoint")
      end
            
    end

  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DCS Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function handling the birth of a unit.
-- @param #OPSGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function OPSGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Set homebase if not already set.
    if self.isFlightgroup then

      if EventData.Place then
        self.homebase=self.homebase or EventData.Place
        self.currbase=EventData.Place
      else
        self.currbase=nil
      end

      if self.homebase and not self.destbase then
        self.destbase=self.homebase
      end

      self:T(self.lid..string.format("EVENT: Element %s born at airbase %s ==> spawned", unitname, self.currbase and self.currbase:GetName() or "unknown"))
    else
      self:T3(self.lid..string.format("EVENT: Element %s born ==> spawned", unitname))
    end

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element and element.status~=OPSGROUP.ElementStatus.SPAWNED then
    
      -- Debug info.
      self:T(self.lid..string.format("EVENT: Element %s born ==> spawned", unitname))
      
      self:T2(self.lid..string.format("DCS unit=%s isExist=%s", tostring(EventData.IniDCSUnit:getName()), tostring(EventData.IniDCSUnit:isExist()) ))

      -- Set element to spawned state.
      self:ElementSpawned(element)

    end

  end

end

--- Event function handling the hit of a unit.
-- @param #OPSGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function OPSGROUP:OnEventHit(EventData)

  -- Check that this is the right group. Here the hit group is stored as target.
  if EventData and EventData.TgtGroup and EventData.TgtUnit and EventData.TgtGroupName and EventData.TgtGroupName==self.groupname then
    self:T2(self.lid..string.format("EVENT: Unit %s hit!", EventData.TgtUnitName))

    local unit=EventData.TgtUnit
    local group=EventData.TgtGroup
    local unitname=EventData.TgtUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)
    
    -- Increase group hit counter.
    self.Nhit=self.Nhit or 0
    self.Nhit=self.Nhit +  1

    if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      -- Trigger Element Hit Event.
      self:ElementHit(element, EventData.IniUnit)
    end

  end

end

--- Event function handling the dead of a unit.
-- @param #OPSGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function OPSGROUP:OnEventDead(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T2(self.lid..string.format("EVENT: Unit %s dead!", EventData.IniUnitName))

    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      self:T(self.lid..string.format("EVENT: Element %s dead ==> destroyed", element.name))
      self:ElementDestroyed(element)
    end

  end

end

--- Event function handling when a unit is removed from the game.
-- @param #OPSGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function OPSGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T2(self.lid..string.format("EVENT: Unit %s removed!", EventData.IniUnitName))

    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      self:T(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

--- Event function handling when a unit is removed from the game.
-- @param #OPSGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function OPSGROUP:OnEventPlayerLeaveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T2(self.lid..string.format("EVENT: Player left Unit %s!", EventData.IniUnitName))

    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      self:T(self.lid..string.format("EVENT: Player left Element %s ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

--- Event function handling the event that a unit achieved a kill.
-- @param #OPSGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function OPSGROUP:OnEventKill(EventData)
  --self:I("FF event kill")
  --self:I(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then

    -- Target name
    local targetname=tostring(EventData.TgtUnitName)

    -- Debug info.
    self:T2(self.lid..string.format("EVENT: Unit %s killed object %s!", tostring(EventData.IniUnitName), targetname))

    -- Check if this was a UNIT or STATIC object.
    local target=UNIT:FindByName(targetname)
    if not target then
      target=STATIC:FindByName(targetname, false)
    end

    -- Only count UNITS and STATICs (not SCENERY)
    if target then

      -- Debug info.
      self:T(self.lid..string.format("EVENT: Unit %s killed unit/static %s!", tostring(EventData.IniUnitName), targetname))

      -- Kill counter.
      self.Nkills=self.Nkills+1

      -- Check if on a mission.
      local mission=self:GetMissionCurrent()
      if mission then
        mission.Nkills=mission.Nkills+1 -- Increase mission kill counter.
      end

    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set DCS task. Enroute tasks are injected automatically.
-- @param #OPSGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #OPSGROUP self
function OPSGROUP:SetTask(DCSTask)

  if self:IsAlive() then

    -- Inject enroute tasks.
    if self.taskenroute and #self.taskenroute>0 then
      if tostring(DCSTask.id)=="ComboTask" then
        for _,task in pairs(self.taskenroute) do
          table.insert(DCSTask.params.tasks, 1, task)
        end
      else
        local tasks=UTILS.DeepCopy(self.taskenroute)
        table.insert(tasks, DCSTask)

        DCSTask=self.group.TaskCombo(self, tasks)
      end
    end

    -- Set task.
    self.controller:setTask(DCSTask)

    -- Debug info.
    local text=string.format("SETTING Task %s", tostring(DCSTask.id))
    if tostring(DCSTask.id)=="ComboTask" then
      for i,task in pairs(DCSTask.params.tasks) do
        text=text..string.format("\n[%d] %s", i, tostring(task.id))
      end
    end
    self:T(self.lid..text)
  end

  return self
end

--- Push DCS task.
-- @param #OPSGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #OPSGROUP self
function OPSGROUP:PushTask(DCSTask)

  if self:IsAlive() then

    -- Inject enroute tasks.
    if self.taskenroute and #self.taskenroute>0 then
      if tostring(DCSTask.id)=="ComboTask" then
        for _,task in pairs(self.taskenroute) do
          table.insert(DCSTask.params.tasks, 1, task)
        end
      else
        local tasks=UTILS.DeepCopy(self.taskenroute)
        table.insert(tasks, DCSTask)

        DCSTask=self.group.TaskCombo(self, tasks)
      end
    end

    -- Push task.
    self.controller:pushTask(DCSTask)

    -- Debug info.
    local text=string.format("PUSHING Task %s", tostring(DCSTask.id))
    if tostring(DCSTask.id)=="ComboTask" then
      for i,task in pairs(DCSTask.params.tasks) do
        text=text..string.format("\n[%d] %s", i, tostring(task.id))
      end
    end
    self:T(self.lid..text)    
  end

  return self
end

--- Returns true if the DCS controller currently has a task.
-- @param #OPSGROUP self
-- @return #boolean True or false if the controller has a task. Nil if no controller.
function OPSGROUP:HasTaskController()
  local hastask=nil
  if self.controller then
    hastask=self.controller:hasTask()
  end
  self:T3(self.lid..string.format("Controller hasTask=%s", tostring(hastask)))
  return hastask
end

--- Clear DCS tasks.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:ClearTasks()
  local hastask=self:HasTaskController()
  if self:IsAlive() and self.controller and self:HasTaskController() then
    self:T(self.lid..string.format("CLEARING Tasks"))
    self.controller:resetTask()
  end
  return self
end



--- Add a *scheduled* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #OPSGROUP.Task The task structure.
function OPSGROUP:AddTask(task, clock, description, prio, duration)

  local newtask=self:NewTaskScheduled(task, clock, description, prio, duration)

  -- Add to table.
  table.insert(self.taskqueue, newtask)

  -- Info.
  self:T(self.lid..string.format("Adding SCHEDULED task %s starting at %s", newtask.description, UTILS.SecondsToClock(newtask.time, true)))
  self:T3({newtask=newtask})

  return newtask
end

--- Create a *scheduled* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #OPSGROUP.Task The task structure.
function OPSGROUP:NewTaskScheduled(task, clock, description, prio, duration)

  -- Increase counter.
  self.taskcounter=self.taskcounter+1

  -- Set time.
  local time=timer.getAbsTime()+5
  if clock then
    if type(clock)=="string" then
      time=UTILS.ClockToSeconds(clock)
    elseif type(clock)=="number" then
      time=timer.getAbsTime()+clock
    end
  end

  -- Task data structure.
  local newtask={} --#OPSGROUP.Task
  newtask.status=OPSGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.description=description or task.id
  newtask.prio=prio or 50
  newtask.time=time
  newtask.id=self.taskcounter
  newtask.duration=duration
  newtask.waypoint=-1
  newtask.type=OPSGROUP.TaskType.SCHEDULED
  newtask.stopflag=USERFLAG:New(string.format("%s StopTaskFlag %d", self.groupname, newtask.id))
  newtask.stopflag:Set(0)

  return newtask
end

--- Add a *waypoint* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
-- @param #OPSGROUP.Waypoint Waypoint where the task is executed. Default is the at *next* waypoint.
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #number prio Priority of the task. Number between 1 and 100. Default is 50.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #OPSGROUP.Task The task structure.
function OPSGROUP:AddTaskWaypoint(task, Waypoint, description, prio, duration)

  -- Waypoint of task.
  Waypoint=Waypoint or self:GetWaypointNext()

  if Waypoint then

    -- Increase counter.
    self.taskcounter=self.taskcounter+1

    -- Task data structure.
    local newtask={} --#OPSGROUP.Task
    newtask.description=description or string.format("Task #%d", self.taskcounter)
    newtask.status=OPSGROUP.TaskStatus.SCHEDULED
    newtask.dcstask=task
    newtask.prio=prio or 50
    newtask.id=self.taskcounter
    newtask.duration=duration
    newtask.time=0
    newtask.waypoint=Waypoint.uid
    newtask.type=OPSGROUP.TaskType.WAYPOINT
    newtask.stopflag=USERFLAG:New(string.format("%s StopTaskFlag %d", self.groupname, newtask.id))
    newtask.stopflag:Set(0)

    -- Add to table.
    table.insert(self.taskqueue, newtask)

    -- Info.
    self:T(self.lid..string.format("Adding WAYPOINT task %s at WP ID=%d", newtask.description, newtask.waypoint))
    self:T3({newtask=newtask})

    -- Update route.
    --self:__UpdateRoute(-1)

    return newtask
  end

  return nil
end

--- Add an *enroute* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
function OPSGROUP:AddTaskEnroute(task)

  if not self.taskenroute then
    self.taskenroute={}
  end

  -- Check not to add the same task twice!
  local gotit=false
  for _,Task in pairs(self.taskenroute) do
    if Task.id==task.id then
      gotit=true
      break
    end
  end

  if not gotit then
    self:T(self.lid..string.format("Adding enroute task"))
    table.insert(self.taskenroute, task)
  end

end

--- Get the unfinished waypoint tasks
-- @param #OPSGROUP self
-- @param #number id Unique waypoint ID.
-- @return #table Table of tasks. Table could also be empty {}.
function OPSGROUP:GetTasksWaypoint(id)

  -- Tasks table.
  local tasks={}

  -- Sort queue.
  self:_SortTaskQueue()

  -- Look for first task that SCHEDULED.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.type==OPSGROUP.TaskType.WAYPOINT and task.status==OPSGROUP.TaskStatus.SCHEDULED and task.waypoint==id then
      table.insert(tasks, task)
    end
  end

  return tasks
end

--- Count remaining waypoint tasks.
-- @param #OPSGROUP self
-- @param #number uid Unique waypoint ID.
-- @return #number Number of waypoint tasks.
function OPSGROUP:CountTasksWaypoint(id)

  -- Tasks table.
  local n=0

  -- Look for first task that SCHEDULED.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.type==OPSGROUP.TaskType.WAYPOINT and task.status==OPSGROUP.TaskStatus.SCHEDULED and task.waypoint==id then
      n=n+1
    end
  end

  return n
end

--- Sort task queue.
-- @param #OPSGROUP self
function OPSGROUP:_SortTaskQueue()

  -- Sort results table wrt prio and then start time.
  local function _sort(a, b)
    local taskA=a --#OPSGROUP.Task
    local taskB=b --#OPSGROUP.Task
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.time<taskB.time)
  end

  --TODO: only needs to be sorted if a task was added, is done, or was removed.
  table.sort(self.taskqueue, _sort)

end


--- Count the number of tasks that still pending in the queue.
-- @param #OPSGROUP self
-- @return #number Total number of tasks remaining.
-- @return #number Number of SCHEDULED tasks remaining.
-- @return #number Number of WAYPOINT tasks remaining.
function OPSGROUP:CountRemainingTasks()

  local Ntot=0
  local Nwp=0
  local Nsched=0

  -- Loop over tasks queue.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task

    -- Task is still scheduled.
    if task.status==OPSGROUP.TaskStatus.SCHEDULED then

      -- Total number of tasks.
      Ntot=Ntot+1

      if task.type==OPSGROUP.TaskType.WAYPOINT then
        Nwp=Nwp+1
      elseif task.type==OPSGROUP.TaskType.SCHEDULED then
        Nsched=Nsched+1
      end

    end

  end

  return Ntot, Nsched, Nwp
end

--- Remove task from task queue.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Task Task The task to be removed from the queue.
-- @return #boolean True if task could be removed.
function OPSGROUP:RemoveTask(Task)

  for i=#self.taskqueue,1,-1 do
    local task=self.taskqueue[i] --#OPSGROUP.Task

    if task.id==Task.id then

      -- Remove task from queue.
      table.remove(self.taskqueue, i)

      -- Update route if this is a waypoint task.
      if task.type==OPSGROUP.TaskType.WAYPOINT and task.status==OPSGROUP.TaskStatus.SCHEDULED then
        self:_CheckGroupDone(1)
      end

      return true
    end
  end

  return false
end

--- Get next task in queue. Task needs to be in state SCHEDULED and time must have passed.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Task The next task in line or `nil`.
function OPSGROUP:_GetNextTask()

  if self.taskpaused then
    --return self.taskpaused
  end

  if #self.taskqueue==0 then
    return nil
  end

  -- Sort queue wrt prio and start time.
  self:_SortTaskQueue()

  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is SCHEDULED.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.type==OPSGROUP.TaskType.SCHEDULED and task.status==OPSGROUP.TaskStatus.SCHEDULED and time>=task.time then
      return task
    end
  end

  return nil
end

--- Get the currently executed task if there is any.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Task Current task or nil.
function OPSGROUP:GetTaskCurrent()
  local task=self:GetTaskByID(self.taskcurrent, OPSGROUP.TaskStatus.EXECUTING)
  return task
end

--- Get task by its id.
-- @param #OPSGROUP self
-- @param #number id Task id.
-- @param #string status (Optional) Only return tasks with this status, e.g. OPSGROUP.TaskStatus.SCHEDULED.
-- @return #OPSGROUP.Task The task or nil.
function OPSGROUP:GetTaskByID(id, status)

  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task

    if task.id==id then
      if status==nil or status==task.status then
        return task
      end
    end

  end

  return nil
end

--- On before "TaskExecute" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP.Task Task The task.
function OPSGROUP:onbeforeTaskExecute(From, Event, To, Task)

  -- Get mission of this task (if any).
  local Mission=self:GetMissionByTaskID(Task.id)

  if Mission and (Mission.Tpush or #Mission.conditionPush>0) then

    if Mission:IsReadyToPush() then

      ---
      -- READY to push yet
      ---

      -- Group is currently waiting.
      if self:IsWaiting() then

        -- Not waiting any more.
        self.Twaiting=nil
        self.dTwait=nil

        -- For a flight group, we must cancel the wait/orbit task.
        if self:IsFlightgroup() then

          -- Set hold flag to 1. This is a condition in the wait/orbit task.
          self.flaghold:Set(1)

          -- Reexecute task in 1 sec to allow to flag to take effect.
          --self:__TaskExecute(-1, Task)

          -- Deny transition for now.
          --return false
        end
      end

    else

      ---
      -- NOT READY to push yet
      ---

      if self:IsWaiting() then
        -- Group is already waiting
      else
        -- Wait indefinitely.
        local alt=Mission.missionAltitude and UTILS.MetersToFeet(Mission.missionAltitude) or nil
        self:Wait(nil, alt)
      end

      -- Time to for the next try. Best guess is when push time is reached or 20 sec when push conditions are not true yet.
      local dt=Mission.Tpush and Mission.Tpush-timer.getAbsTime() or 20

      -- Debug info.
      self:T(self.lid..string.format("Mission %s task execute suspended for %d seconds", Mission.name, dt))

      -- Reexecute task.
      self:__TaskExecute(-dt, Task)

      -- Deny transition.
      return false
    end

  end
  
  if Mission and Mission.opstransport then
  
    local delivered=Mission.opstransport:IsCargoDelivered(self.groupname)
  
    if not delivered then
    
      local dt=30

      -- Debug info.
      self:T(self.lid..string.format("Mission %s task execute suspended for %d seconds because we were not delivered", Mission.name, dt))

      -- Reexecute task.
      self:__TaskExecute(-dt, Task)
      
      if (self:IsArmygroup() or self:IsNavygroup()) and self:IsCruising() then
        self:FullStop()
      end
      
      -- Deny transition.
      return false    
    end
  end

  return true
end

--- On after "TaskExecute" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP.Task Task The task.
function OPSGROUP:onafterTaskExecute(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task %s ID=%d execute", tostring(Task.description), Task.id)

  -- Debug info.  
  self:T(self.lid..text)

  -- Debug info.
  self:T2({Task})
  
  -- Cancel current task if there is any.
  if self.taskcurrent>0 then
    self:TaskCancel()
  end

  -- Set current task.
  self.taskcurrent=Task.id

  -- Set time stamp.
  Task.timestamp=timer.getAbsTime()

  -- Task status executing.
  Task.status=OPSGROUP.TaskStatus.EXECUTING

  -- Insert into task queue. Not sure any more, why I added this. But probably if a task is just executed without having been put into the queue.
  if self:GetTaskCurrent()==nil then
    table.insert(self.taskqueue, Task)
  end

  -- Get mission of this task (if any).
  local Mission=self:GetMissionByTaskID(self.taskcurrent)

  -- Update push DCS task.
  self:_UpdateTask(Task, Mission)

  -- Set AUFTRAG status.
  if Mission then
    self:MissionExecute(Mission)
  end

end

--- Update (DCS) task.
-- @param #OPSGROUP self
-- @param Ops.OpsGroup#OPSGROUP.Task Task The task.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function OPSGROUP:_UpdateTask(Task, Mission)

  Mission=Mission or self:GetMissionByTaskID(self.taskcurrent)

  if Task.dcstask.id==AUFTRAG.SpecialTask.FORMATION then
      
    if Mission.type == AUFTRAG.Type.RESCUEHELO then
      self:T("**********")
      self:T("** RESCUEHELO USED")
      self:T("**********")
      local param=Task.dcstask.params
      local followUnit=UNIT:FindByName(param.unitname)
      local helogroupname = self:GetGroup():GetName()
      Task.formation = RESCUEHELO:New(followUnit,helogroupname)
      Task.formation:SetRespawnOnOff(false)
      Task.formation.respawninair=false
      Task.formation:SetTakeoffCold()
      Task.formation:SetHomeBase(followUnit)
      Task.formation.helo = self:GetGroup() 
      -- Start formation FSM.
      Task.formation:Start()
      if self:IsFlightgroup() then
        self:SetDespawnAfterLanding()
      end
    else  
      
    -- Set of group(s) to follow Mother.
    local followSet=SET_GROUP:New():AddGroup(self.group)

    local param=Task.dcstask.params

    local followUnit=UNIT:FindByName(param.unitname)

    -- Define AI Formation object.
    Task.formation=FORMATION:New(followUnit, followSet, AUFTRAG.SpecialTask.FORMATION)

    -- Formation parameters.
    Task.formation:FormationCenterWing(-param.offsetX, 50, math.abs(param.altitude), 50, param.offsetZ, 50)

    -- Set follow time interval.
    Task.formation:SetFollowTimeInterval(param.dtFollow)

    -- Formation mode.
    --Task.formation:SetFlightModeFormation(self.group)

    -- Start formation FSM.
    Task.formation:Start()
    
    end
    
  elseif Task.dcstask.id==AUFTRAG.SpecialTask.PATROLZONE then

    ---
    -- Task patrol zone.
    ---

    -- Parameters.
    local zone=Task.dcstask.params.zone --Core.Zone#ZONE

    local surfacetypes=nil
    if self:IsArmygroup() then
      surfacetypes={land.SurfaceType.LAND, land.SurfaceType.ROAD}
    elseif self:IsNavygroup() then
      surfacetypes={land.SurfaceType.WATER, land.SurfaceType.SHALLOW_WATER}
    end

    -- Random coordinate in zone.
    local Coordinate=zone:GetRandomCoordinate(nil, nil, surfacetypes)

    --Coordinate:MarkToAll("Random Patrol Zone Coordinate")

    -- Speed and altitude.
    local Speed=Task.dcstask.params.speed and UTILS.MpsToKnots(Task.dcstask.params.speed) or UTILS.KmphToKnots(self.speedCruise)
    local Altitude=Task.dcstask.params.altitude and UTILS.MetersToFeet(Task.dcstask.params.altitude) or nil

    local currUID=self:GetWaypointCurrent().uid

    -- New waypoint.
    local wp=nil --#OPSGROUP.Waypoint
    if self.isFlightgroup then
      wp=FLIGHTGROUP.AddWaypoint(self, Coordinate, Speed, currUID, Altitude)
    elseif self.isArmygroup then
      wp=ARMYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, Task.dcstask.params.formation)
    elseif self.isNavygroup then
      wp=NAVYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, Altitude)
    end

    -- Set mission UID.
    wp.missionUID=Mission and Mission.auftragsnummer or nil

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.RECON then

    ---
    -- Task recon.
    ---

    -- Target
    local target=Task.dcstask.params.target --Ops.Target#TARGET
    
    -- Init a table.
    self.reconindecies={}
    for i=1,#target.targets do
      table.insert(self.reconindecies, i)
    end
    
    local n=1
    if Task.dcstask.params.randomly then
      n=UTILS.GetRandomTableElement(self.reconindecies)
    else    
      table.remove(self.reconindecies, n)
    end        

    -- Target object and zone.
    local object=target.targets[n] --Ops.Target#TARGET.Object
    local zone=object.Object --Core.Zone#ZONE

    -- Random coordinate in zone.
    local Coordinate=zone:GetRandomCoordinate()

    -- Speed and altitude.
    local Speed=Task.dcstask.params.speed and UTILS.MpsToKnots(Task.dcstask.params.speed) or UTILS.KmphToKnots(self.speedCruise)
    local Altitude=Task.dcstask.params.altitude and UTILS.MetersToFeet(Task.dcstask.params.altitude) or nil

    --Coordinate:MarkToAll("Recon Waypoint Execute")

    local currUID=self:GetWaypointCurrent().uid

    -- New waypoint.
    local wp=nil --#OPSGROUP.Waypoint
    if self.isFlightgroup then
      wp=FLIGHTGROUP.AddWaypoint(self, Coordinate, Speed, currUID, Altitude)
    elseif self.isArmygroup then
      wp=ARMYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, Task.dcstask.params.formation)
    elseif self.isNavygroup then
      wp=NAVYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, Altitude)
    end

    -- Set mission UID.
    wp.missionUID=Mission and Mission.auftragsnummer or nil

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.AMMOSUPPLY or Task.dcstask.id==AUFTRAG.SpecialTask.FUELSUPPLY then

    ---
    -- Task "Ammo Supply" or "Fuel Supply" mission.
    ---

    -- Just stay put and wait until something happens.
    
  elseif Task.dcstask.id==AUFTRAG.SpecialTask.REARMING then

    ---
    -- Task "Rearming"
    ---

    -- Check if ammo is full.
    
    local rearmed=self:_CheckAmmoFull()
    
    if rearmed then
      self:T2(self.lid.."Ammo already full ==> reaming task done!")
      self:TaskDone(Task)
    else
      self:T2(self.lid.."Ammo not full ==> Rearm()")
      self:Rearm()
    end


  elseif Task.dcstask.id==AUFTRAG.SpecialTask.ALERT5 then

    ---
    -- Task "Alert 5" mission.
    ---

    -- Just stay put on the airfield and wait until something happens.

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.ONGUARD or Task.dcstask.id==AUFTRAG.SpecialTask.ARMOREDGUARD then

    ---
    -- Task "On Guard" Mission.
    ---

    -- Just stay put.
    --TODO: Change ALARM STATE

    if self:IsArmygroup() or self:IsNavygroup() then
      -- Especially NAVYGROUP needs a full stop as patrol ad infinitum
      self:FullStop()
    else
      -- FLIGHTGROUP not implemented (intended!) for this AUFTRAG type.
    end

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.NOTHING then

    ---
    -- Task "Nothing" Mission.
    ---

    -- Just stay put.
    --TODO: Change ALARM STATE

    if self:IsArmygroup() or self:IsNavygroup() then
      -- Especially NAVYGROUP needs a full stop as patrol ad infinitum
      self:__FullStop(0.1)
    else
      -- FLIGHTGROUP not implemented (intended!) for this AUFTRAG type.
    end

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.AIRDEFENSE or Task.dcstask.id==AUFTRAG.SpecialTask.EWR then

    ---
    -- Task "AIRDEFENSE" or "EWR" Mission.
    ---

    -- Just stay put.
    --TODO: Change ALARM STATE

    if self:IsArmygroup() or self:IsNavygroup() then
      self:FullStop()
    else
      -- FLIGHTGROUP not implemented (intended!) for this AUFTRAG type.
    end

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.GROUNDATTACK or Task.dcstask.id==AUFTRAG.SpecialTask.ARMORATTACK then  

    ---
    -- Task "Ground Attack" Mission.
    ---
    
    -- Engage target.
    local target=Task.dcstask.params.target --Ops.Target#TARGET
    
    -- Set speed. Default max.
    local speed=self.speedMax and UTILS.KmphToKnots(self.speedMax) or nil
    if Task.dcstask.params.speed then
      speed=UTILS.MpsToKnots(Task.dcstask.params.speed)
    end
    
    if target then
      self:EngageTarget(target, speed, Task.dcstask.params.formation)
    end

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.NAVALENGAGEMENT then

    ---
    -- Task "Naval Engagement" Mission.
    ---
    
    -- Engage target.
    local target=Task.dcstask.params.target --Ops.Target#TARGET
    
    -- Set speed. Default max.
    local speed=self.speedMax and UTILS.KmphToKnots(self.speedMax) or nil
    if Task.dcstask.params.speed then
      speed=UTILS.MpsToKnots(Task.dcstask.params.speed)
    end
    
    if target then
      self:EngageTarget(target, speed, Task.dcstask.params.altitude)
    end
  
  elseif Task.dcstask.id==AUFTRAG.SpecialTask.PATROLRACETRACK then
  
    ---
    -- Task "Patrol Race Track" Mission.
    ---
    
    if self.isFlightgroup then
      self:T("We are Special Auftrag Patrol Race Track, starting now ...")
      --self:I({Task.dcstask.params})
      --[[
          Task.dcstask.params.TrackAltitude = self.TrackAltitude
          Task.dcstask.params.TrackSpeed = self.TrackSpeed
          Task.dcstask.params.TrackPoint1 = self.TrackPoint1
          Task.dcstask.params.TrackPoint2 = self.TrackPoint2
          Task.dcstask.params.TrackFormation = self.TrackFormation
      --]]
      local aircraft = self:GetGroup()
      aircraft:PatrolRaceTrack(Task.dcstask.params.TrackPoint1,Task.dcstask.params.TrackPoint2,Task.dcstask.params.TrackAltitude,Task.dcstask.params.TrackSpeed,Task.dcstask.params.TrackFormation,false,1)
    end
    
  elseif Task.dcstask.id==AUFTRAG.SpecialTask.HOVER then

    ---
    -- Task "Hover" Mission.
    ---
    
    if self.isFlightgroup then
      self:T("We are Special Auftrag HOVER, hovering now ...")
      --self:I({Task.dcstask.params})
      local alt = Task.dcstask.params.hoverAltitude
      local time =Task.dcstask.params.hoverTime
      local mSpeed = Task.dcstask.params.missionSpeed or self.speedCruise or 150
      local Speed = UTILS.KmphToKnots(mSpeed)
      local CruiseAlt = UTILS.FeetToMeters(Task.dcstask.params.missionAltitude or 1000)
      local helo = self:GetGroup()
      helo:SetSpeed(0.01,true)
      helo:SetAltitude(alt,true,"BARO")
      self:HoverStart()
      local function FlyOn(Helo,Speed,CruiseAlt,Task)
        if Helo then
          Helo:SetSpeed(Speed,true)
          Helo:SetAltitude(CruiseAlt,true,"BARO")
          self:T("We are Special Auftrag HOVER, end of hovering now ...")
          self:TaskDone(Task)
          self:HoverEnd()
        end
      end
      local timer = TIMER:New(FlyOn,helo,Speed,CruiseAlt,Task)
      timer:Start(time)
    end

  elseif Task.dcstask.id==AUFTRAG.SpecialTask.RELOCATECOHORT then

    ---
    -- Task "RelocateCohort" Mission.
    ---
    
    -- Debug mission.
    self:T(self.lid.."Executing task for relocation mission")
    
    -- The new legion.
    local legion=Task.dcstask.params.legion --Ops.Legion#LEGION
    
    -- Get random coordinate in spawn zone of new legion.
    local Coordinate=legion.spawnzone:GetRandomCoordinate()
    
    -- Get current waypoint ID.
    local currUID=self:GetWaypointCurrent().uid
    
    local wp=nil --#OPSGROUP.Waypoint
    if self.isArmygroup then
      self:T2(self.lid.."Routing group to spawn zone of new legion")
      wp=ARMYGROUP.AddWaypoint(self,   Coordinate, UTILS.KmphToKnots(self.speedCruise), currUID, Mission.optionFormation)     
    elseif self.isFlightgroup then
      self:T2(self.lid.."Routing group to intermediate point near new legion")
      Coordinate=self:GetCoordinate():GetIntermediateCoordinate(Coordinate, 0.8)
      wp=FLIGHTGROUP.AddWaypoint(self, Coordinate, UTILS.KmphToKnots(self.speedCruise), currUID, UTILS.MetersToFeet(self.altitudeCruise))
    elseif self.isNavygroup then
      self:T2(self.lid.."Routing group to spawn zone of new legion")
      wp=NAVYGROUP.AddWaypoint(self,   Coordinate, UTILS.KmphToKnots(self.speedCruise), currUID)         
    else
    
    end
    
    wp.missionUID=Mission and Mission.auftragsnummer or nil
    
  elseif Task.dcstask.id==AUFTRAG.SpecialTask.CAPTUREZONE then

    ---
    -- Task "CaptureZone" Mission.
    -- Check if zone was captured or find new target to engage.
    ---  
    
    -- Not enganging already.
    if self:IsEngaging() then
    
      -- Group is currently engaging an enemy unit to capture the zone.
      self:T2(self.lid..string.format("CaptureZone: Engaging currently!"))
    else
    
      -- Get enemy coalitions. We do not include neutrals.
      local Coalitions=UTILS.GetCoalitionEnemy(self:GetCoalition(), false)
      
      -- Current target object.
      local zoneCurr=Task.target --Ops.OpsZone#OPSZONE
      
      if zoneCurr then
            
        self:T(self.lid..string.format("Current target zone=%s owner=%s", zoneCurr:GetName(), zoneCurr:GetOwnerName()))
        
        if zoneCurr:GetOwner()==self:GetCoalition() then
          -- Current zone captured ==> Find next zone or call it a day!
          
          -- Debug info.
          self:T(self.lid..string.format("Zone %s captured ==> Task DONE!", zoneCurr:GetName()))
          
          -- Task done.
          if Task.StayInZoneTime then
            local stay = Task.StayInZoneTime
            self:__TaskDone(stay,Task)
          else
            self:TaskDone(Task)
          end
          
        else        
          -- Current zone NOT captured yet ==> Find Target
          
          -- Debug info.
          self:T(self.lid..string.format("Zone %s NOT captured!", zoneCurr:GetName()))          
          
          if Mission:GetGroupStatus(self)==AUFTRAG.GroupStatus.EXECUTING then
          
            -- Debug info.
            self:T(self.lid..string.format("Zone %s NOT captured and EXECUTING ==> Find target", zoneCurr:GetName()))          
          
        
            -- Get closest target.
            local targetgroup=zoneCurr:GetScannedGroupSet():GetClosestGroup(self.coordinate, Coalitions)
            
            if targetgroup then
            
              -- Debug info.
              self:T(self.lid..string.format("Zone %s NOT captured: engaging target %s", zoneCurr:GetName(), targetgroup:GetName()))
            
              -- Engage target group.
              self:EngageTarget(targetgroup)
              
            else
              
              if self:IsFlightgroup() then
                -- Debug info.
                self:T(self.lid..string.format("Zone %s not captured but no target group could be found ==> TaskDone as FLIGHTGROUPS cannot capture zones", zoneCurr:GetName()))                
              
                -- Task done.
                self:TaskDone(Task)
              else
                -- Debug info.
                self:T(self.lid..string.format("Zone %s not captured but no target group could be found. Should be captured in the next zone evaluation.", zoneCurr:GetName()))                
              end
              
            end
            
          else
            self:T(self.lid..string.format("Zone %s NOT captured and NOT EXECUTING", zoneCurr:GetName()))            
          end
          
        end        
        
      else
        self:T(self.lid..string.format("NO Current target zone=%s"))
      end
      
    end
        
  else

    -- If task is scheduled (not waypoint) set task.
    if Task.type==OPSGROUP.TaskType.SCHEDULED or Task.ismission then

      -- DCS task.
      local DCSTask=nil

      -- BARRAGE is special!
      if Task.dcstask.id==AUFTRAG.SpecialTask.BARRAGE then
        ---
        -- BARRAGE
      
        -- Current vec2.
        local vec2=self:GetVec2()
        
        -- Task parameters.
        local param=Task.dcstask.params
        
        -- Set heading and altitude.
        local heading=param.heading or math.random(1, 360)
        local Altitude=param.altitude or 500
        local Alpha=param.angle or math.random(45, 85)
        local distance=Altitude/math.tan(math.rad(Alpha))
        local tvec2=UTILS.Vec2Translate(vec2, distance, heading)
        
        -- Debug info.
        self:T(self.lid..string.format("Barrage: Shots=%s, Altitude=%d m, Angle=%dÂ°, heading=%03dÂ°, distance=%d m", tostring(param.shots), Altitude, Alpha, heading, distance))
        
        -- Set fire at point task.
        DCSTask=CONTROLLABLE.TaskFireAtPoint(nil, tvec2, param.radius, param.shots, param.weaponType, Altitude)
        
      elseif Task.ismission and Task.dcstask.id=='FireAtPoint' then
      
        -- Copy DCS task.
        DCSTask=UTILS.DeepCopy(Task.dcstask)
        
        -- Get current ammo.
        local ammo=self:GetAmmoTot()
        
        -- Number of ammo avail.
        local nAmmo=ammo.Total
        
        local weaponType=DCSTask.params.weaponType or -1
        
        -- Adjust max number of ammo for specific weapon types requested.
        if weaponType==ENUMS.WeaponFlag.CruiseMissile then
          nAmmo=ammo.MissilesCR
        elseif weaponType==ENUMS.WeaponFlag.AnyRocket then
          nAmmo=ammo.Rockets
        elseif weaponType==ENUMS.WeaponFlag.Cannons then
          nAmmo=ammo.Cannons
        end
        
        --TODO: Update target location while we're at it anyway.
        --TODO: Adjust mission result evaluation time? E.g. cruise missiles can fly a long time depending on target distance.
        
        -- Number of shots to be fired.
        local nShots=DCSTask.params.expendQty or 1
        
        -- Debug info.
        self:T(self.lid..string.format("Fire at point with nshots=%d of %d", nShots, nAmmo))
        
        if nShots==-1 then
          -- The -1 is for using all available ammo.
          nShots=nAmmo
          self:T(self.lid..string.format("Fire at point taking max amount of ammo = %d", nShots))
        elseif nShots<1 then
          local p=nShots
          nShots=UTILS.Round(p*nAmmo, 0)
          self:T(self.lid..string.format("Fire at point taking %.1f percent amount of ammo = %d", p, nShots))
        else
          -- Fire nShots but at most nAmmo.
          nShots=math.min(nShots, nAmmo)
        end
        
        -- Set quantity of task.
        DCSTask.params.expendQty=nShots
        
      else
        ---
        -- Take DCS task
        ---
        DCSTask=Task.dcstask
      end
      
      self:_SandwitchDCSTask(DCSTask, Task)

    elseif Task.type==OPSGROUP.TaskType.WAYPOINT then
      -- Waypoint tasks are executed elsewhere!
    else
      self:T(self.lid.."ERROR: Unknown task type: ")
    end

  end
  
end

--- Sandwitch DCS task in stop condition and push the task to the group.
-- @param #OPSGROUP self
-- @param DCS#Task DCSTask The DCS task.
-- @param Ops.OpsGroup#OPSGROUP.Task Task
-- @param #boolean SetTask Set task instead of pushing it.
-- @param #number Delay Delay in seconds. Default nil.
function OPSGROUP:_SandwitchDCSTask(DCSTask, Task, SetTask, Delay)

  if Delay and Delay>0 then
    -- Delayed call.
    self:ScheduleOnce(Delay, OPSGROUP._SandwitchDCSTask, self, DCSTask, Task, SetTask)    
  else

    local DCStasks={}
    if DCSTask.id=='ComboTask' then
      -- Loop over all combo tasks.
      for TaskID, Task in ipairs(DCSTask.params.tasks) do
        table.insert(DCStasks, Task)
      end
    else
      table.insert(DCStasks, DCSTask)
    end
    
    -- Combo task.
    local TaskCombo=self.group:TaskCombo(DCStasks)
    
    -- Stop condition!
    local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
    
    -- Controlled task.
    local TaskControlled=self.group:TaskControlled(TaskCombo, TaskCondition)
    
    -- Task done.
    local TaskDone=self.group:TaskFunction("OPSGROUP._TaskDone", self, Task)
    
    -- Final task.
    local TaskFinal=self.group:TaskCombo({TaskControlled, TaskDone})
    
    -- Set task for group.
    -- NOTE: I am pushing the task instead of setting it as it seems to keep the mission task alive.
    --       There were issues that flights did not proceed to a later waypoint because the task did not finish until the fired missiles
    --       impacted (took rather long). Then the flight flew to the nearest airbase and one lost completely the control over the group.
    if SetTask then
      self:SetTask(TaskFinal)
    else
      self:PushTask(TaskFinal)
    end
    
  end

end


--- On after "TaskCancel" event. Cancels the current task or simply sets the status to DONE if the task is not the current one.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Task Task The task to cancel. Default is the current task (if any).
function OPSGROUP:onafterTaskCancel(From, Event, To, Task)

  -- Get current task.
  local currenttask=self:GetTaskCurrent()

  -- If no task, we take the current task. But this could also be *nil*!
  Task=Task or currenttask

  if Task then

    -- Check if the task is the current task?
    if currenttask and Task.id==currenttask.id then

      -- Current stop flag value. I noticed cases, where setting the flag to 1 would not cancel the task, e.g. when firing HARMS on a dead ship.
      local stopflag=Task.stopflag:Get()

      -- Debug info.
      local text=string.format("Current task %s ID=%d cancelled (flag %s=%d)", Task.description, Task.id, Task.stopflag:GetName(), stopflag)
      self:T(self.lid..text)

      -- Set stop flag. When the flag is true, the _TaskDone function is executed and calls :TaskDone()
      Task.stopflag:Set(1)

      local done=false
      if Task.dcstask.id==AUFTRAG.SpecialTask.FORMATION then
        Task.formation:Stop()
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.PATROLZONE then
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.RECON then
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.AMMOSUPPLY then
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.FUELSUPPLY then      
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.REARMING then
        done=true        
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.ALERT5 then
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.ONGUARD or Task.dcstask.id==AUFTRAG.SpecialTask.ARMOREDGUARD then
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.GROUNDATTACK or Task.dcstask.id==AUFTRAG.SpecialTask.ARMORATTACK or Task.dcstask.id==AUFTRAG.SpecialTask.NAVALENGAGEMENT then
        done=true
      elseif Task.dcstask.id==AUFTRAG.SpecialTask.NOTHING then
        done=true        
      elseif stopflag==1 or (not self:IsAlive()) or self:IsDead() or self:IsStopped() then
        -- Manual call TaskDone if setting flag to one was not successful.
        done=true
      end

      if done then
        self:TaskDone(Task)
      end

    else

      -- Debug info.
      self:T(self.lid..string.format("TaskCancel: Setting task %s ID=%d to DONE", Task.description, Task.id))

      -- Call task done function.
      self:TaskDone(Task)

    end

  else

    local text=string.format("WARNING: No (current) task to cancel!")
    self:T(self.lid..text)

  end

end

--- On before "TaskDone" event. Deny transition if task status is PAUSED.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Task Task
function OPSGROUP:onbeforeTaskDone(From, Event, To, Task)

  local allowed=true

  if Task.status==OPSGROUP.TaskStatus.PAUSED then
    allowed=false
  end

  return allowed
end

--- On after "TaskDone" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Task Task
function OPSGROUP:onafterTaskDone(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task done: %s ID=%d", Task.description, Task.id)
  self:T(self.lid..text)

  -- No current task.
  if Task.id==self.taskcurrent then
    self.taskcurrent=0
  end

  -- Task status done.
  Task.status=OPSGROUP.TaskStatus.DONE

  -- Restore old ROE.
  if Task.backupROE then
    self:SwitchROE(Task.backupROE)
  end

  -- Check if this task was the task of the current mission ==> Mission Done!
  local Mission=self:GetMissionByTaskID(Task.id)

  if Mission and Mission:IsNotOver() then
  
    -- Get mission status of this group.
    local status=Mission:GetGroupStatus(self)

    -- Check if mission is paused.
    if status~=AUFTRAG.GroupStatus.PAUSED then
      --- 
      -- Mission is NOT over ==> trigger DONE
      ---

      if Mission.type==AUFTRAG.Type.CAPTUREZONE and Mission:CountMissionTargets()>0 then
      
        -- Remove mission waypoints.
        self:T(self.lid.."Remove mission waypoints")
        self:_RemoveMissionWaypoints(Mission, false)
        
        if self:IsFlightgroup() then
        
          -- A flight cannot capture so we assume done.
        
--          local opszone=Mission:GetTargetData() --Ops.OpsZone#OPSZONE
--          
--          if opszone then
--          
--            local mycoalition=self:GetCoalition()
--            
--            if mycoalition~=opszone:GetOwner() then
--              local nenemy=0
--              if mycoalition==coalition.side.BLUE then
--                nenemy=opszone.Nred
--              else
--                nenemy=opszone.Nblu
--              end
--                
--            end
--            
--          end
        
        else
      
          self:T(self.lid.."Task done ==> Route to mission for next opszone")
          self:MissionStart(Mission)
          
          return
        end      
      end

      -- Get egress waypoint uid.
      local EgressUID=Mission:GetGroupEgressWaypointUID(self)
            
      if EgressUID then
        -- Egress coordinate given ==> wait until we pass that waypoint.
        self:T(self.lid..string.format("Task Done but Egress waypoint defined ==> Will call Mission Done once group passed waypoint UID=%d!", EgressUID))
      else
        -- Mission done!
        self:T(self.lid.."Task Done ==> Mission Done!")
        self:MissionDone(Mission)
      end
    else
      ---
      -- Mission Paused: Do nothing! Just set the current mission to nil so we can launch a new one.
      ---
      if self:IsOnMission(Mission.auftragsnummer) then
        self.currentmission=nil
      end
      -- Remove mission waypoints.
      self:T(self.lid.."Remove mission waypoints")
      self:_RemoveMissionWaypoints(Mission, false)
    end

  else

    if Task.description=="Engage_Target" then
      self:T(self.lid.."Task DONE Engage_Target ==> Cruise")
      self:Disengage()
    end

    if Task.description==AUFTRAG.SpecialTask.ONGUARD or Task.description==AUFTRAG.SpecialTask.ARMOREDGUARD or Task.description==AUFTRAG.SpecialTask.NOTHING then
      self:T(self.lid.."Task DONE OnGuard ==> Cruise")
      self:Cruise()
    end
    
    if Task.description=="Task_Land_At" then
      self:T(self.lid.."Taske DONE Task_Land_At ==> Wait")
      -- After the land task, we set the helo to wait. This is because of an issue that the passing waypoint function is triggered immidiately if we do not do this!
      self:Wait(20, 100)
    else
      self:T(self.lid.."Task Done but NO mission found ==> _CheckGroupDone in 1 sec")
      self:_CheckGroupDone(1)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add mission to queue.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission Mission for this group.
-- @return #OPSGROUP self
function OPSGROUP:AddMission(Mission)

  -- Add group to mission.
  Mission:AddOpsGroup(self)

  -- Set group status to SCHEDULED..
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.SCHEDULED)

  -- Set mission status to SCHEDULED.
  Mission:Scheduled()

  -- Add elements.
  Mission.Nelements=Mission.Nelements+#self.elements
  
  -- Increase number of groups.
  Mission.Ngroups=Mission.Ngroups+1

  -- Add mission to queue.
  table.insert(self.missionqueue, Mission)

  -- ad infinitum?
  self.adinfinitum = Mission.DCStask.params.adinfinitum and Mission.DCStask.params.adinfinitum or false

  -- Info text.
  local text=string.format("Added %s mission %s starting at %s, stopping at %s",
  tostring(Mission.type), tostring(Mission.name), UTILS.SecondsToClock(Mission.Tstart, true), Mission.Tstop and UTILS.SecondsToClock(Mission.Tstop, true) or "INF")
  self:T(self.lid..text)

  return self
end

--- Remove mission from queue.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #OPSGROUP self
function OPSGROUP:RemoveMission(Mission)

  --for i,_mission in pairs(self.missionqueue) do
  for i=#self.missionqueue,1,-1 do
  
    -- Mission.
    local mission=self.missionqueue[i] --Ops.Auftrag#AUFTRAG

    -- Check mission ID.
    if mission.auftragsnummer==Mission.auftragsnummer then

      -- Remove mission waypoint task.
      local Task=Mission:GetGroupWaypointTask(self)

      if Task then
        self:RemoveTask(Task)
      end

      -- Take care of a paused mission.
      for j=#self.pausedmissions,1,-1 do
        local mid=self.pausedmissions[j]
        if Mission.auftragsnummer==mid then
          table.remove(self.pausedmissions, j)
        end
      end

      -- Remove mission from queue.
      table.remove(self.missionqueue, i)

      return self
    end

  end

  return self
end

--- Cancel all missions in mission queue that are not already done or cancelled.
-- @param #OPSGROUP self
function OPSGROUP:CancelAllMissions()
  self:T(self.lid.."Cancelling ALL missions!")

  -- Cancel all missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Current group status.
    local mystatus=mission:GetGroupStatus(self)

    -- Check if mission is already over!
    if not (mystatus==AUFTRAG.GroupStatus.DONE or mystatus==AUFTRAG.GroupStatus.CANCELLED) then        
    --if mission:IsNotOver() then
      self:T(self.lid.."Cancelling mission "..tostring(mission:GetName()))
      self:MissionCancel(mission)
    end
  end

end

--- Count remaining missons.
-- @param #OPSGROUP self
-- @return #number Number of missions to be done.
function OPSGROUP:CountRemainingMissison()

  local N=0

  -- Loop over mission queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission and mission:IsNotOver() then

      -- Get group status.
      local status=mission:GetGroupStatus(self)

      if status~=AUFTRAG.GroupStatus.DONE and status~=AUFTRAG.GroupStatus.CANCELLED then
        N=N+1
      end

    end
  end

  return N
end

--- Count remaining cargo transport assignments.
-- @param #OPSGROUP self
-- @return #number Number of unfinished transports in the queue.
function OPSGROUP:CountRemainingTransports()

  local N=0

  -- Loop over mission queue.
  for _,_transport in pairs(self.cargoqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT

    local mystatus=transport:GetCarrierTransportStatus(self)
    local status=transport:GetState()

    -- Debug info.
    self:T(self.lid..string.format("Transport my status=%s [%s]", mystatus, status))

    -- Count not delivered (executing or scheduled) assignments.
    if transport and mystatus==OPSTRANSPORT.Status.SCHEDULED and status~=OPSTRANSPORT.Status.DELIVERED and status~=OPSTRANSPORT.Status.CANCELLED then
      N=N+1
    end
  end

  -- In case we directly set the cargo transport (not in queue).
  if N==0 and self.cargoTransport and
    self.cargoTransport:GetState()~=OPSTRANSPORT.Status.DELIVERED and self.cargoTransport:GetCarrierTransportStatus(self)~=OPSTRANSPORT.Status.DELIVERED and
    self.cargoTransport:GetState()~=OPSTRANSPORT.Status.CANCELLED and self.cargoTransport:GetCarrierTransportStatus(self)~=OPSTRANSPORT.Status.CANCELLED then
    N=1
  end

  return N
end

--- Get next mission.
-- @param #OPSGROUP self
-- @return Ops.Auftrag#AUFTRAG Next mission or *nil*.
function OPSGROUP:_GetNextMission()

  -- Check if group is acting as carrier or cargo at the moment.
  if self:IsPickingup() or self:IsLoading() or self:IsTransporting() or self:IsUnloading() or self:IsLoaded() then
    return nil
  end

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)

  -- Look for first mission that is SCHEDULED.
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end

  -- Look for first mission that is SCHEDULED.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- TODO: One could think of opsgroup specific start conditions. A legion also checks if "ready" but it can be other criteria for the group to actually start the mission.
    --       Good example is the above transport. The legion should start the mission but the group should only start after the transport is finished.

    -- Escort mission. Check that escorted group is alive.
    local isEscort=true
    if mission.type==AUFTRAG.Type.ESCORT then
      local target=mission:GetTargetData()
      if not target:IsAlive() then
        isEscort=false
      end
    end

    -- Local transport.
    local isTransport=true
    if mission.opstransport then
      local cargos=mission.opstransport:GetCargoOpsGroups(false) or {}
      for _,_opsgroup in pairs(cargos) do
        local opscargo=_opsgroup --Ops.OpsGroup#OPSGROUP
        if opscargo.groupname==self.groupname then
          --isTransport=false
          break
        end
      end
    end

    -- Conditons to start.
    local isScheduled=mission:GetGroupStatus(self)==AUFTRAG.GroupStatus.SCHEDULED
    local isReadyToGo=(mission:IsReadyToGo() or self.legion)
    local isImportant=(mission.importance==nil or mission.importance<=vip)
    
    -- Everything on go?
    local go=isScheduled and isReadyToGo and isImportant and isTransport and isEscort
    
    -- Debug info.
    self:T3(self.lid..string.format("Mission %s [%s]: Go=%s [Scheduled=%s, Ready=%s, Important=%s, Transport=%s, Escort=%s]", mission:GetName(), mission:GetType(), tostring(go), 
    tostring(isScheduled), tostring(isReadyToGo), tostring(isImportant), tostring(isTransport), tostring(isEscort)))

    -- Check necessary conditions.
    if go then
      return mission
    end

  end

  return nil
end

--- Get mission by its id (auftragsnummer).
-- @param #OPSGROUP self
-- @param #number id Mission id (auftragsnummer).
-- @return Ops.Auftrag#AUFTRAG The mission.
function OPSGROUP:GetMissionByID(id)

  if not id then
    return nil
  end

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission.auftragsnummer==id then
      return mission
    end

  end

  return nil
end

--- Check if a given mission is already in the queue.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission the mission to check
-- @return #boolean If `true`, the mission is in the queue.
function OPSGROUP:IsMissionInQueue(Mission)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission.auftragsnummer==Mission.auftragsnummer then
      return true
    end

  end

  return false
end

--- Check if a given mission type is already in the queue.
-- @param #OPSGROUP self
-- @param #string MissionType MissionType Type of mission.
-- @return #boolean If `true`, the mission type is in the queue.
function OPSGROUP:IsMissionTypeInQueue(MissionType)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission:GetType()==MissionType then
      return true
    end

  end

  return false
end

--- Get mission by its task id.
-- @param #OPSGROUP self
-- @param #number taskid The id of the (waypoint) task of the mission.
-- @return Ops.Auftrag#AUFTRAG The mission.
function OPSGROUP:GetMissionByTaskID(taskid)

  if taskid then
    for _,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG

      local task=mission:GetGroupWaypointTask(self)

      if task and task.id and task.id==taskid then
        return mission
      end

    end
  end

  return nil
end

--- Get current mission.
-- @param #OPSGROUP self
-- @return Ops.Auftrag#AUFTRAG The current mission or *nil*.
function OPSGROUP:GetMissionCurrent()
  return self:GetMissionByID(self.currentmission)
end

--- Check if group is currently on a mission.
-- @param #OPSGROUP self
-- @param #number MissionUID (Optional) Check if group is currently on a mission with this UID. Default is to check for any current mission.
-- @return #boolean If `true`, group is currently on a mission.
function OPSGROUP:IsOnMission(MissionUID)
  if self.currentmission==nil then
    -- No current mission.
    return false
  else
    if MissionUID then
      -- Return if on specific mission.
      return MissionUID==self.currentmission
    else
      -- Is on any mission.
      return true    
    end
  end
  -- Is on any mission.
  return true
end

--- On before "MissionStart" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function OPSGROUP:onbeforeMissionStart(From, Event, To, Mission)

  -- Debug info.
  self:T(self.lid..string.format("Starting mission %s, FSM=%s, LateActivated=%s, UnControlled=%s", tostring(Mission.name), self:GetState(), tostring(self:IsLateActivated()), tostring(self:IsUncontrolled())))

  -- Delay for route to mission. Group needs to be activated and controlled.
  local delay=0

  -- Check if group is spawned.
  if self:IsInUtero() then

    -- Activate group if it is late activated.
    if self:IsLateActivated() then
      self:Activate(delay)
      delay=delay+1
    end

  end

  -- Startup group if it is uncontrolled. Alert 5 aircraft will not be started though!
  if self:IsFlightgroup() and self:IsUncontrolled() and Mission.type~=AUFTRAG.Type.ALERT5 then
    local fc=FLIGHTGROUP.GetFlightControl(self)
    if fc and fc:IsControlling(self) then
      FLIGHTGROUP.SetReadyForTakeoff(self, true)
    else
      self:StartUncontrolled(delay)
    end
  end

  return true
end

--- On after "MissionStart" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function OPSGROUP:onafterMissionStart(From, Event, To, Mission)

  -- Debug output.
  local text=string.format("Starting %s Mission %s, target %s", Mission.type, tostring(Mission.name), Mission:GetTargetName())
  self:T(self.lid..text)

  -- Set current mission.
  self.currentmission=Mission.auftragsnummer

  -- Set group mission status to STARTED.
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.STARTED)

  -- Set mission status to STARTED.
  Mission:__Started(3)
  
  -- Set ready for takeoff in case of FLIGHTCONTROL.
  --if self.isFlightgroup and Mission.type~=AUFTRAG.Type.ALERT5 then
  --  FLIGHTGROUP.SetReadyForTakeoff(self, true)
  --end
  
  -- Route group to mission zone.
  if self.speedMax>3.6 or true then

    self:RouteToMission(Mission, 3)

  else
    ---
    -- IMMOBILE Group
    ---

    -- Debug info.
    self:T(self.lid.."Immobile GROUP!")

    -- Add waypoint task. UpdateRoute is called inside.
    local Clock=Mission.Tpush and UTILS.SecondsToClock(Mission.Tpush) or 5
    
    -- Add mission task.
    local Task=self:AddTask(Mission.DCStask, Clock, Mission.name, Mission.prio, Mission.duration)
    Task.ismission=true

    -- Set waypoint task.
    Mission:SetGroupWaypointTask(self, Task)

    -- Execute task. This calls mission execute.
    self:__TaskExecute(3, Task)
  end

end

--- On after "MissionExecute" event. Mission execution began.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function OPSGROUP:onafterMissionExecute(From, Event, To, Mission)

  local text=string.format("Executing %s Mission %s, target %s", Mission.type, tostring(Mission.name), Mission:GetTargetName())
  self:T(self.lid..text)

  -- Set group mission status to EXECUTING.
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.EXECUTING)

  -- Set mission status to EXECUTING.
  Mission:Executing()
  
  -- Group is holding but has waypoints ==> Cruise.
  if self:IsHolding() and not self:HasPassedFinalWaypoint() then
    self:Cruise()
  end

  -- Set auto engage detected targets.
  if Mission.engagedetectedOn then
    self:SetEngageDetectedOn(UTILS.MetersToNM(Mission.engagedetectedRmax), Mission.engagedetectedTypes, Mission.engagedetectedEngageZones, Mission.engagedetectedNoEngageZones)
  end
  
  -- Set AB usage for mission execution based on Mission entry, if the option was set in the mission
  if self.isFlightgroup then
    if Mission.prohibitABExecute == true then
      self:SetProhibitAfterburner()
      self:T(self.lid.."Set prohibit AB")
    elseif Mission.prohibitABExecute == false then
      self:SetAllowAfterburner()
      self:T2(self.lid.."Set allow AB")
    end
  end
  
end

--- On after "PauseMission" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterPauseMission(From, Event, To)

  local Mission=self:GetMissionCurrent()

  if Mission then

    -- Set group mission status to PAUSED.
    Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.PAUSED)

    -- Get mission waypoint task.
    local Task=Mission:GetGroupWaypointTask(self)

    -- Debug message.
    self:T(self.lid..string.format("Pausing current mission %s. Task=%s", tostring(Mission.name), tostring(Task and Task.description or "WTF")))

    -- Cancelling the mission is actually cancelling the current task.
    self:TaskCancel(Task)
    
    self:_RemoveMissionWaypoints(Mission)

    -- Set mission to pause so we can unpause it later.
    table.insert(self.pausedmissions, 1, Mission.auftragsnummer)

  end

end

--- On after "UnpauseMission" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterUnpauseMission(From, Event, To)
  
  -- Get paused mission.
  local mission=self:_GetPausedMission()

  if mission then
  
    -- Debug info.
    self:T(self.lid..string.format("Unpausing mission %s [%s]", mission:GetName(), mission:GetType()))
    
    -- Set state of mission, e.g. for not teleporting again
    mission.unpaused=true
    
    -- Start mission.
    self:MissionStart(mission)
    
    -- Remove mission from pausedmissions queue
    for i,mid in pairs(self.pausedmissions) do
      --self:T(self.lid..string.format("Checking paused mission", mid))
      if mid==mission.auftragsnummer then
        self:T(self.lid..string.format("Removing paused mission id=%d", mid))
        table.remove(self.pausedmissions, i)
        break
      end
    end
    
  else
    self:T(self.lid.."ERROR: No mission to unpause!")
  end

end


--- On after "MissionCancel" event. Cancels the mission.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission to be cancelled.
function OPSGROUP:onafterMissionCancel(From, Event, To, Mission)

  if self:IsOnMission(Mission.auftragsnummer) then

    ---
    -- Current Mission
    ---

    -- Some missions dont have a task set, which could be cancelled.
    --[[
    if Mission.type==AUFTRAG.Type.ALERT5 or 
       Mission.type==AUFTRAG.Type.ONGUARD or 
       Mission.type==AUFTRAG.Type.ARMOREDGUARD or
       --Mission.type==AUFTRAG.Type.NOTHING or 
       Mission.type==AUFTRAG.Type.AIRDEFENSE or
       Mission.type==AUFTRAG.Type.EWR then
       
      -- Trigger mission don task.
      self:MissionDone(Mission)
      
      return
    end
    ]]

    -- Get mission waypoint task.
    local Task=Mission:GetGroupWaypointTask(self)
    
    if Task then

      -- Debug info.
      self:T(self.lid..string.format("Cancel current mission %s. Task=%s", tostring(Mission.name), tostring(Task and Task.description or "WTF")))
  
      -- Cancelling the mission is actually cancelling the current task.
      -- Note that two things can happen.
      -- 1.) Group is still on the way to the waypoint (status should be STARTED). In this case there would not be a current task!
      -- 2.) Group already passed the mission waypoint (status should be EXECUTING).
  
      self:TaskCancel(Task)
      
    else
    
      -- Some missions dont have a task set, which could be cancelled.

      -- Trigger mission don task.
      self:MissionDone(Mission)
    
    end

  else

    ---
    -- NOT the current mission
    ---

    -- Set mission group status.
    Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.CANCELLED)

    -- Remove mission from queue
    self:RemoveMission(Mission)

    -- Send group RTB or WAIT if nothing left to do.
    self:_CheckGroupDone(1)

  end

end

--- On after "MissionDone" event.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission
-- @param #boolean Silently Remove waypoints by `table.remove()` and do not update the route.
function OPSGROUP:_RemoveMissionWaypoints(Mission, Silently)

  for i=#self.waypoints,1,-1 do
    local wp=self.waypoints[i] --#OPSGROUP.Waypoint
    if wp.missionUID==Mission.auftragsnummer then
      if Silently then
        table.remove(self.waypoints, i)
      else
        self:RemoveWaypoint(i)
      end
    end
  end

end

--- On after "MissionDone" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission that is done.
function OPSGROUP:onafterMissionDone(From, Event, To, Mission)

  -- Debug info.
  local text=string.format("Mission DONE %s!", Mission.name)
  self:T(self.lid..text)

  -- Set group status.
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.DONE)

  -- Set current mission to nil.
  if self:IsOnMission(Mission.auftragsnummer) then
    self.currentmission=nil
  end

  -- Remove mission waypoints.
  self:_RemoveMissionWaypoints(Mission)

  -- Decrease patrol data.
  if Mission.patroldata then
    Mission.patroldata.noccupied=Mission.patroldata.noccupied-1
    AIRWING.UpdatePatrolPointMarker(self,Mission.patroldata)
  end

  -- Switch auto engage detected off. This IGNORES that engage detected had been activated for the group!
  if Mission.engagedetectedOn then
    self:SetEngageDetectedOff()
  end

  -- ROE to default.
  if Mission.optionROE then
    self:SwitchROE()
  end
  -- ROT to default
  if self:IsFlightgroup() and Mission.optionROT then
    self:SwitchROT()
  end
  -- Alarm state to default.
  if Mission.optionAlarm then
    self:SwitchAlarmstate()
  end
  -- EPLRS to default.
  if Mission.optionEPLRS then
    self:SwitchEPLRS()
  end
  -- Emission to default.
  if Mission.optionEmission then
    self:SwitchEmission()
  end
  -- Invisible to default.
  if Mission.optionInvisible then
    self:SwitchInvisible()
  end
  -- Immortal to default.
  if Mission.optionImmortal then
    self:SwitchImmortal()
  end
  -- Formation to default.
  if Mission.optionFormation and self:IsFlightgroup() then
    self:SwitchFormation()
  end
  -- Radio freq and modu to default.
  if Mission.radio then
    self:SwitchRadio()
  end

  -- TACAN beacon.
  if Mission.tacan then

    -- Switch to default.
    self:_SwitchTACAN()

    -- Return Cohort's TACAN channel.
    local cohort=self.cohort --Ops.Cohort#COHORT
    if cohort then
      cohort:ReturnTacan(Mission.tacan.Channel)
    end

    -- Set asset TACAN to nil.
    local asset=Mission:GetAssetByName(self.groupname)
    if asset then
      asset.tacan=nil
    end
  end

  -- ICLS beacon to default.
  if Mission.icls then
    self:_SwitchICLS()
  end
  
  -- Return to legion?
  if self.legion and Mission.legionReturn~=nil then
    self:SetReturnToLegion(Mission.legionReturn)
  end

  -- Delay before check if group is done.
  local delay=1
  
  -- Special mission cases.
  if Mission.type==AUFTRAG.Type.ARTY then
    -- We add a 10 sec delay for ARTY. Found that they need some time to readjust the barrel of their gun. Not sure if necessary for all. Needs some more testing!
    delay=60   
  elseif Mission.type==AUFTRAG.Type.RELOCATECOHORT then
  
    -- New legion.
    local legion=Mission.DCStask.params.legion --Ops.Legion#LEGION
    
    -- Debug message.
    self:T(self.lid..string.format("Asset relocated to new legion=%s",tostring(legion.alias)))
    
    -- Get asset and change its warehouse id.
    local asset=Mission:GetAssetByName(self.groupname)
    if asset then
      asset.wid=legion.uid
    end
    
    -- Set new legion.
    self.legion=legion
    
    if self.isArmygroup then
      self:T2(self.lid.."Adding asset via ReturnToLegion()")
      self:ReturnToLegion()
    elseif self.isFlightgroup then
      self:T2(self.lid.."Adding asset via RTB to new legion airbase")
      self:RTB(self.legion.airbase)
    end
    
    return
  end
  
  -- Set AB usage based on Mission entry, if the option was set in the mission
  if self.isFlightgroup then
    if Mission.prohibitAB == true then
      self:T2("Setting prohibit AB")
      self:SetProhibitAfterburner()
    elseif Mission.prohibitAB == false then
      self:T2("Setting allow AB")
      self:SetAllowAfterburner()
    end
  end
  
  if self.legion and self.legionReturn==false and self.waypoints and #self.waypoints==1 then
    ---
    -- This is the case where a group was send on a mission (which is over now), has no addional
    -- waypoints or tasks and should NOT return to its legion.
    -- We create a new waypoint at the current position and let it hold here.
    ---
    
    local Coordinate=self:GetCoordinate()
    
    if self.isArmygroup then
      ARMYGROUP.AddWaypoint(self, Coordinate, 0, nil, nil, false)
    elseif self.isNavygroup then
      NAVYGROUP.AddWaypoint(self,Coordinate, 0, nil, nil, false)
    end
    
    -- Remove original waypoint.
    self:RemoveWaypoint(1)
    
    self:_PassedFinalWaypoint(true, "Passed final waypoint as group is done with mission but should NOT return to its legion")
  end
  
  -- Check if group is done.
  self:_CheckGroupDone(delay)

end

--- Route group to mission.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG mission The mission table.
-- @param #number delay Delay in seconds.
function OPSGROUP:RouteToMission(mission, delay)

  if delay and delay>0 then
    -- Delayed call.
    self:ScheduleOnce(delay, OPSGROUP.RouteToMission, self, mission)
  else

    -- Debug info.
    self:T(self.lid..string.format("Route To Mission"))

    -- Catch dead or stopped groups.
    if self:IsDead() or self:IsStopped() then
      self:T(self.lid..string.format("Route To Mission: I am DEAD or STOPPED! Ooops..."))
      return
    end
    
    -- Check if this group is cargo.
    if self:IsCargo() then
      self:T(self.lid..string.format("Route To Mission: I am CARGO! You cannot route me..."))
      return
    end

    -- OPSTRANSPORT: Just add the ops transport to the queue.
    if mission.type==AUFTRAG.Type.OPSTRANSPORT then
      self:T(self.lid..string.format("Route To Mission: I am OPSTRANSPORT! Add transport and return..."))
      self:AddOpsTransport(mission.opstransport)
      return
    end

    -- ALERT5: Just set the mission to executing.
    if mission.type==AUFTRAG.Type.ALERT5 then
      self:T(self.lid..string.format("Route To Mission: I am ALERT5! Go right to MissionExecute()..."))
      self:MissionExecute(mission)
      return
    end

    -- ID of current waypoint.
    local uid=self:GetWaypointCurrentUID()

    -- Ingress waypoint coordinate where the mission is executed.
    local waypointcoord=nil --Core.Point#COORDINATE
    
    -- Current coordinate of the group.
    local currentcoord=self:GetCoordinate()
    
    -- Road connection.
    local roadcoord=currentcoord:GetClosestPointToRoad()
    
    local roaddist=nil
    if roadcoord then
      roaddist=currentcoord:Get2DDistance(roadcoord)
    end
        
    -- Target zone.
    local targetzone=nil --Core.Zone#ZONE
  
    -- Random radius of 1000 meters.
    local randomradius=mission.missionWaypointRadius or 1000

    -- Surface types.
    local surfacetypes=nil
    if self:IsArmygroup() then
      surfacetypes={land.SurfaceType.LAND, land.SurfaceType.ROAD}
    elseif self:IsNavygroup() then
      surfacetypes={land.SurfaceType.WATER, land.SurfaceType.SHALLOW_WATER}
    end
    
    -- Get target object.
    local targetobject=mission:GetObjective(currentcoord, UTILS.GetCoalitionEnemy(self:GetCoalition(), true))
    
    if targetobject then
      self:T(self.lid..string.format("Route to mission target object %s", targetobject:GetName()))
    end
    
    -- Get ingress waypoint.    
    if mission.opstransport and not mission.opstransport:IsCargoDelivered(self.groupname) then
      
      -- Get transport zone combo.
      local tzc=mission.opstransport:GetTZCofCargo(self.groupname)
      
      local pickupzone=tzc.PickupZone
      
      if self:IsInZone(pickupzone) then
        -- We are already in the pickup zone.      
        self:PauseMission()
        self:FullStop()
        return
      else
        -- Get a random coordinate inside the pickup zone.
        waypointcoord=pickupzone:GetRandomCoordinate()
      end
      
    elseif mission.type==AUFTRAG.Type.PATROLZONE or 
           mission.type==AUFTRAG.Type.BARRAGE    or 
           mission.type==AUFTRAG.Type.AMMOSUPPLY or
           mission.type==AUFTRAG.Type.FUELSUPPLY or
           mission.type==AUFTRAG.Type.REARMING   or 
           mission.type==AUFTRAG.Type.AIRDEFENSE or
           mission.type==AUFTRAG.Type.EWR        then
      ---
      -- Missions with ZONE as target
      ---
      
      -- Get the zone.
      targetzone=targetobject --Core.Zone#ZONE
      
      -- Random coordinate.
      waypointcoord=targetzone:GetRandomCoordinate(nil , nil, surfacetypes)
      
    elseif mission.type==AUFTRAG.Type.ONGUARD or mission.type==AUFTRAG.Type.ARMOREDGUARD then
      ---
      -- Guard
      ---
      
      -- Mission waypoint
      waypointcoord=mission:GetMissionWaypointCoord(self.group, nil, surfacetypes)

    elseif mission.type==AUFTRAG.Type.NOTHING then
      ---
      -- Nothing
      ---

      -- Get the zone.
      targetzone=targetobject --Core.Zone#ZONE
      
      -- Random coordinate.
      waypointcoord=targetzone:GetRandomCoordinate(nil , nil, surfacetypes)
            
    elseif mission.type==AUFTRAG.Type.HOVER then
      ---
      -- Hover
      ---

      local zone=targetobject --Core.Zone#ZONE
      
      waypointcoord=zone:GetCoordinate()
      
    elseif mission.type==AUFTRAG.Type.RELOCATECOHORT then
      ---
      -- Relocation
      ---

      -- Roughly go to the new legion. 
      local ToCoordinate=mission.DCStask.params.legion:GetCoordinate()      
            
      if self.isFlightgroup then
        -- Get mission waypoint coord in direction of the 
        waypointcoord=currentcoord:GetIntermediateCoordinate(ToCoordinate, 0.2):SetAltitude(self.altitudeCruise)
      elseif self.isArmygroup then
        -- Army group: check for road connection.
        if roadcoord then
          waypointcoord=roadcoord
        else
          waypointcoord=currentcoord:GetIntermediateCoordinate(ToCoordinate, 100)
        end
      else
        -- Navy group: Route into direction of the target.
        waypointcoord=currentcoord:GetIntermediateCoordinate(ToCoordinate, 0.05)
      end
    
    elseif mission.type==AUFTRAG.Type.CAPTUREZONE then
    
      -- Get the zone.
      targetzone=targetobject:GetZone()
      
      -- Random coordinate.
      waypointcoord=targetzone:GetRandomCoordinate(nil , nil, surfacetypes)      
      
    else
      ---
      -- Default case
      ---
      
      waypointcoord=mission:GetMissionWaypointCoord(self.group, randomradius, surfacetypes)
    end

    -- Add enroute tasks.
    for _,task in pairs(mission.enrouteTasks) do
      self:AddTaskEnroute(task)
    end

    -- Speed to mission waypoint.
    local SpeedToMission=mission.missionSpeed and UTILS.KmphToKnots(mission.missionSpeed) or self:GetSpeedCruise()

    -- Special for Troop transport.
    if mission.type==AUFTRAG.Type.TROOPTRANSPORT then

      ---
      -- TROOP TRANSPORT
      ---

      -- Refresh DCS task with the known controllable.
      mission.DCStask=mission:GetDCSMissionTask(self.group)
      
      -- Create a pickup zone around the pickup coordinate. The troops will go to a random point inside the zone.
      -- This is necessary so the helos do not try to land at the exact same location where the troops wait.
      local pradius=mission.transportPickupRadius
      local pickupZone=ZONE_RADIUS:New("Pickup Zone", mission.transportPickup:GetVec2(), pradius)

      -- Add task to embark for the troops.
      for _,_group in pairs(mission.transportGroupSet.Set) do
        local group=_group --Wrapper.Group#GROUP

        if group and group:IsAlive() then
          -- Get random coordinate inside the zone.
          local pcoord=pickupZone:GetRandomCoordinate(20, pradius, {land.SurfaceType.LAND, land.SurfaceType.ROAD})
          
          -- Let the troops embark the transport.
          local DCSTask=group:TaskEmbarkToTransport(pcoord, pradius)
          group:SetTask(DCSTask, 5)
        end

      end

    elseif mission.type==AUFTRAG.Type.ARTY then

      ---
      -- ARTY
      ---

      -- Target Coord. 
      local targetcoord=mission:GetTargetCoordinate()
      
      -- In range already?
      local inRange=self:InWeaponRange(targetcoord, mission.engageWeaponType, waypointcoord)
      
      if inRange then
      
        --waypointcoord=self:GetCoordinate(true)
      
      else

        local coordInRange=self:GetCoordinateInRange(targetcoord, mission.engageWeaponType, waypointcoord, surfacetypes)
        
        if coordInRange then
  
          -- Add waypoint at 
          local waypoint=nil --#OPSGROUP.Waypoint
          if self:IsFlightgroup() then
            waypoint=FLIGHTGROUP.AddWaypoint(self, waypointcoord, SpeedToMission, uid, UTILS.MetersToFeet(mission.missionAltitude or self.altitudeCruise), false)
          elseif self:IsArmygroup() then
            waypoint=ARMYGROUP.AddWaypoint(self,   waypointcoord, SpeedToMission, uid, mission.optionFormation, false)
          elseif self:IsNavygroup() then
            waypoint=NAVYGROUP.AddWaypoint(self,   waypointcoord, SpeedToMission, uid, UTILS.MetersToFeet(mission.missionAltitude or self.altitudeCruise), false)
          end
          waypoint.missionUID=mission.auftragsnummer
  
          -- Set waypoint coord to be the one in range. Take care of proper waypoint uid.
          waypointcoord=coordInRange
          uid=waypoint.uid
          
        end
        
      end
      
    end


    -- Distance to waypoint coordinate.
    local d=currentcoord:Get2DDistance(waypointcoord)
    
    -- Debug info.
    self:T(self.lid..string.format("Distance to ingress waypoint=%.1f m", d))
    
    -- Add mission execution (ingress) waypoint.
    local waypoint=nil --#OPSGROUP.Waypoint
    if self:IsFlightgroup() then
      

      local ingresscoord = mission:GetMissionIngressCoord()
      local holdingcoord = mission:GetMissionHoldingCoord()
      
      if holdingcoord then 
        waypoint=FLIGHTGROUP.AddWaypoint(self, holdingcoord, mission.missionHoldingCoordSpeed or SpeedToMission, uid, UTILS.MetersToFeet(mission.missionHoldingCoordAlt or self.altitudeCruise), false)
        uid=waypoint.uid
          -- Orbit until flaghold=1 (true) but max 5 min
        self.flaghold:Set(0)
        local TaskOrbit = self.group:TaskOrbit(holdingcoord, mission.missionHoldingCoordAlt, UTILS.KnotsToMps(mission.missionHoldingCoordSpeed or SpeedToMission))
        local TaskStop  = self.group:TaskCondition(nil, self.flaghold.UserFlagName, 1, nil, mission.missionHoldingDuration or 900)
        local TaskCntr  = self.group:TaskControlled(TaskOrbit, TaskStop)
        local TaskOver  = self.group:TaskFunction("FLIGHTGROUP._FinishedWaiting", self)       
        local DCSTasks=self.group:TaskCombo({TaskCntr, TaskOver})
        -- Add waypoint task. UpdateRoute is called inside.
        local waypointtask=self:AddTaskWaypoint(DCSTasks, waypoint, "Holding")
        waypointtask.ismission=false
        self.isHoldingAtHoldingPoint = true
      end
      
      if ingresscoord then 
        waypoint=FLIGHTGROUP.AddWaypoint(self, ingresscoord, mission.missionIngressCoordSpeed or SpeedToMission, uid, UTILS.MetersToFeet(mission.missionIngressCoordAlt or self.altitudeCruise), false)
        uid=waypoint.uid
      end
     
      waypoint=FLIGHTGROUP.AddWaypoint(self, waypointcoord, SpeedToMission, uid, UTILS.MetersToFeet(mission.missionAltitude or self.altitudeCruise), false)
      
    elseif self:IsArmygroup() then
    
      -- Set formation.
      local formation=mission.optionFormation
      
      -- If distance is < 1 km or RELOCATECOHORT mission, go off-road.
      if d<1000 or mission.type==AUFTRAG.Type.RELOCATECOHORT then
        formation=ENUMS.Formation.Vehicle.OffRoad
      end
      
      waypoint=ARMYGROUP.AddWaypoint(self, waypointcoord, SpeedToMission, uid, formation, false)
      
    elseif self:IsNavygroup() then
    
      waypoint=NAVYGROUP.AddWaypoint(self,   waypointcoord, SpeedToMission, uid, UTILS.MetersToFeet(mission.missionAltitude or self.altitudeCruise), false)
      
    end
    waypoint.missionUID=mission.auftragsnummer

    -- Add waypoint task. UpdateRoute is called inside.
    local waypointtask=self:AddTaskWaypoint(mission.DCStask, waypoint, mission.name, mission.prio, mission.duration)
    waypointtask.ismission=true
    
    waypointtask.target=targetobject

    -- Set waypoint task.
    mission:SetGroupWaypointTask(self, waypointtask)

    -- Set waypoint index.
    mission:SetGroupWaypointIndex(self, waypoint.uid)

    -- Add egress waypoint.
    local egresscoord=mission:GetMissionEgressCoord()
    if egresscoord then
      local Ewaypoint=nil --#OPSGROUP.Waypoint
      if self:IsFlightgroup() then
        Ewaypoint=FLIGHTGROUP.AddWaypoint(self, egresscoord, mission.missionEgressCoordSpeed or SpeedToMission, waypoint.uid, UTILS.MetersToFeet(mission.missionEgressCoordAlt or self.altitudeCruise), false)
      elseif self:IsArmygroup() then
        Ewaypoint=ARMYGROUP.AddWaypoint(self,   egresscoord, SpeedToMission, waypoint.uid, mission.optionFormation, false)
      elseif self:IsNavygroup() then
        Ewaypoint=NAVYGROUP.AddWaypoint(self,   egresscoord, SpeedToMission, waypoint.uid, UTILS.MetersToFeet(mission.missionAltitude or self.altitudeCruise), false)
      end
      Ewaypoint.missionUID=mission.auftragsnummer
      mission:SetGroupEgressWaypointUID(self, Ewaypoint.uid)
    end
    
    -- Check if we are already where we want to be.
    if targetzone and self:IsInZone(targetzone) then
      self:T(self.lid.."Already in mission zone ==> TaskExecute()")
      self:TaskExecute(waypointtask)
      -- TODO: Calling PassingWaypoint here is probably better as it marks the mission waypoint as passed!
      self:PassingWaypoint(waypoint)
      return
    elseif d<25 then
      self:T(self.lid.."Already within 25 meters of mission waypoint ==> TaskExecute()")
      self:TaskExecute(waypointtask)
      self:PassingWaypoint(waypoint)
      return
    end
    
    -- Check if group is mobile. Note that some immobile units report a speed of 1 m/s = 3.6 km/h.
    if (self.speedMax<=3.6 or mission.teleport) and not mission.unpaused then

      -- Teleport to waypoint coordinate. Mission will not be paused.
      self:Teleport(waypointcoord, nil, true)
      
      -- Execute task in one second.
      self:__TaskExecute(-1, waypointtask)
      
    else

      -- Give cruise command/update route.
      if self:IsArmygroup() then
        self:Cruise(SpeedToMission)
      elseif self:IsNavygroup() then
        self:Cruise(SpeedToMission)
      elseif self:IsFlightgroup() then
        self:UpdateRoute()
      end
          
    end
    
    ---
    -- Mission Specific Settings
    ---
    self:_SetMissionOptions(mission)

  end
end

--- Set mission specific options for ROE, Alarm state, etc.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG mission The mission table.
function OPSGROUP:_SetMissionOptions(mission)

  -- ROE
  if mission.optionROE then
    self:SwitchROE(mission.optionROE)
  end
  -- ROT
  if mission.optionROT then
    self:SwitchROT(mission.optionROT)
  end
  -- Alarm state
  if mission.optionAlarm then
    self:SwitchAlarmstate(mission.optionAlarm)
  end
  -- EPLRS
  if mission.optionEPLRS then
    self:SwitchEPLRS(mission.optionEPLRS)
  end
  -- Emission
  if mission.optionEmission then
    self:SwitchEmission(mission.optionEmission)
  end
  -- Invisible
  if mission.optionInvisible then
    self:SwitchInvisible(mission.optionInvisible)
  end
  -- Immortal
  if mission.optionImmortal then
    self:SwitchImmortal(mission.optionImmortal)
  end
  -- Formation
  if mission.optionFormation and self:IsFlightgroup() then
    self:SwitchFormation(mission.optionFormation)
  end
  -- Radio frequency and modulation.
  if mission.radio then
    self:SwitchRadio(mission.radio.Freq, mission.radio.Modu)
  end
  -- TACAN settings.
  if mission.tacan then
    self:SwitchTACAN(mission.tacan.Channel, mission.tacan.Morse, mission.tacan.BeaconName, mission.tacan.Band)
  end
  -- ICLS settings.
  if mission.icls then
    self:SwitchICLS(mission.icls.Channel, mission.icls.Morse, mission.icls.UnitName)
  end
  
  -- Set AB usage based on Mission entry, if the option was set in the mission
  if self.isFlightgroup then
    if mission.prohibitAB == true then
      self:SetProhibitAfterburner()
      self:T2("Set prohibit AB")
    elseif mission.prohibitAB == false then
      self:SetAllowAfterburner()
      self:T2("Set allow AB")
    end
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Queue Update: Missions & Tasks
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "QueueUpdate" event.
-- @param #OPSGROUP self
function OPSGROUP:_QueueUpdate()

  ---
  -- Mission
  ---

  -- First check if group is alive? Late activated groups are activated and uncontrolled units are started automatically.
  if self:IsExist() then

    local mission=self:_GetNextMission()

    if mission then

      local currentmission=self:GetMissionCurrent()

      if currentmission then

        -- Current mission but new mission is urgent with higher prio.
        if mission.urgent and mission.prio<currentmission.prio then
          self:T(self.lid.."FF got urgent mission with higher prio!")
          self:MissionCancel(currentmission)
          self:__MissionStart(1, mission)
        end

      else
        -- No current mission.
        self:MissionStart(mission)
      end
    end
  end

  ---
  -- Tasks
  ---

  local ready=true

  -- For aircraft check airborne.
  if self:IsFlightgroup() then
    ready=self:IsAirborne()
  end

  -- Check no current task.
  if ready and self.taskcurrent<=0 then

    -- Get task from queue.
    local task=self:_GetNextTask()

    -- Execute task if any.
    if task then
      self:TaskExecute(task)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On before "Wait" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Duration Duration how long the group will be waiting in seconds. Default `nil` (=forever).
function OPSGROUP:onbeforeWait(From, Event, To, Duration)

  local allowed=true
  local Tsuspend=nil
  
  local mission=self:GetMissionCurrent()
  if mission then
    self:PauseMission()
    return true
  end

  -- Check for a current task.
  if self.taskcurrent>0 then
    self:T(self.lid..string.format("WARNING: Got current task ==> WAIT event is suspended for 30 sec!"))
    Tsuspend=-30
    allowed=false
  end

  -- Check for a current transport assignment.
  if self.cargoTransport then
    self:T(self.lid..string.format("WARNING: Got current TRANSPORT assignment ==> WAIT event is suspended for 30 sec!"))
    Tsuspend=-30
    allowed=false
  end

  -- Call wait again.
  if Tsuspend and not allowed then
    self:__Wait(Tsuspend, Duration)
  end

  return allowed
end

--- On after "Wait" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Duration Duration in seconds how long the group will be waiting. Default `nil` (for ever).
function OPSGROUP:onafterWait(From, Event, To, Duration)

  -- Order Group to hold.
  self:FullStop()

  -- Set time stamp.
  self.Twaiting=timer.getAbsTime()

  -- Max waiting
  self.dTwait=Duration

end


--- On after "PassingWaypoint" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Waypoint Waypoint Waypoint data passed.
function OPSGROUP:onafterPassingWaypoint(From, Event, To, Waypoint)

  -- Get the current task.
  local task=self:GetTaskCurrent()

  -- Get the corresponding mission.
  local mission=nil  --Ops.Auftrag#AUFTRAG
  if task then
    mission=self:GetMissionByTaskID(task.id)
  end

  if task and task.dcstask.id==AUFTRAG.SpecialTask.PATROLZONE then

    ---
    -- SPECIAL TASK: Patrol Zone
    ---

    -- Remove old waypoint.
    self:RemoveWaypointByID(Waypoint.uid)

    -- Zone object.
    local zone=task.dcstask.params.zone --Core.Zone#ZONE

    -- Surface types.
    local surfacetypes=nil
    if self:IsArmygroup() then
      surfacetypes={land.SurfaceType.LAND, land.SurfaceType.ROAD}
    elseif self:IsNavygroup() then
      surfacetypes={land.SurfaceType.WATER, land.SurfaceType.SHALLOW_WATER}
    end

    -- Random coordinate in zone.
    local Coordinate=zone:GetRandomCoordinate(nil, nil, surfacetypes)

    -- Speed and altitude.
    local Speed=task.dcstask.params.speed and UTILS.MpsToKnots(task.dcstask.params.speed) or UTILS.KmphToKnots(self.speedCruise)
    local Altitude=UTILS.MetersToFeet(task.dcstask.params.altitude or self.altitudeCruise)

    local currUID=self:GetWaypointCurrent().uid

    local wp=nil --#OPSGROUP.Waypoint
    if self.isFlightgroup then
      wp=FLIGHTGROUP.AddWaypoint(self, Coordinate, Speed, currUID, Altitude)
    elseif self.isArmygroup then
      wp=ARMYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, task.dcstask.params.formation)
    elseif self.isNavygroup then
      wp=NAVYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, Altitude)
    end
    wp.missionUID=mission and mission.auftragsnummer or nil

  elseif task and task.dcstask.id==AUFTRAG.SpecialTask.RECON then

    ---
    -- SPECIAL TASK: Recon Mission
    ---

    -- TARGET.
    local target=task.dcstask.params.target --Ops.Target#TARGET
    
    -- Init a table.
    if self.adinfinitum and #self.reconindecies==0 then -- all targets done once
      self.reconindecies={}
      for i=1,#target.targets do
        table.insert(self.reconindecies, i)
      end
    end
    
    if #self.reconindecies>0 then
    
      local n=1
      if task.dcstask.params.randomly then
        n=UTILS.GetRandomTableElement(self.reconindecies)
      else
        n=self.reconindecies[1]
        table.remove(self.reconindecies, 1)
      end
      
      -- Zone object.
      local object=target.targets[n] --Ops.Target#TARGET.Object
      local zone=object.Object --Core.Zone#ZONE

      -- Random coordinate in zone.
      local Coordinate=zone:GetRandomCoordinate()

      -- Speed and altitude.
      local Speed=task.dcstask.params.speed and UTILS.MpsToKnots(task.dcstask.params.speed) or UTILS.KmphToKnots(self.speedCruise)
      local Altitude=task.dcstask.params.altitude and UTILS.MetersToFeet(task.dcstask.params.altitude) or nil

      -- Debug.
      --Coordinate:MarkToAll("Recon Waypoint n="..tostring(n))

      local currUID=self:GetWaypointCurrent().uid

      local wp=nil --#OPSGROUP.Waypoint
      if self.isFlightgroup then
        wp=FLIGHTGROUP.AddWaypoint(self, Coordinate, Speed, currUID, Altitude)
      elseif self.isArmygroup then
        wp=ARMYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, task.dcstask.params.formation)
      elseif self.isNavygroup then
        wp=NAVYGROUP.AddWaypoint(self,   Coordinate, Speed, currUID, Altitude)
      end
      wp.missionUID=mission and mission.auftragsnummer or nil
   
    else

      -- Get waypoint index.
      local wpindex=self:GetWaypointIndex(Waypoint.uid)

      -- Final waypoint reached?
      if wpindex==nil or wpindex==#self.waypoints then

        -- Set switch to true.
        if not self.adinfinitum or #self.waypoints<=1 then
          self:_PassedFinalWaypoint(true, "Passing waypoint and NOT adinfinitum and #self.waypoints<=1")
        end

      end

      -- Final zone reached ==> task done.
      self:TaskDone(task)

    end

  elseif task and task.dcstask.id==AUFTRAG.SpecialTask.RELOCATECOHORT then

    ---
    -- SPECIAL TASK: Relocate Mission
    ---

    -- TARGET.
    local legion=task.dcstask.params.legion --Ops.Legion#LEGION
    
   self:T(self.lid..string.format("Asset arrived at relocation task waypoint ==> Task Done!"))
    
    -- Final zone reached ==> task done.
    self:TaskDone(task)    

  elseif task and task.dcstask.id==AUFTRAG.SpecialTask.REARMING then

    ---
    -- SPECIAL TASK: Rearming Mission
    ---

    -- Debug info.
    self:T(self.lid..string.format("FF Rearming Mission ==> Rearm()"))
    
    -- Call rearm event.
    self:Rearm()

  else

    ---
    -- No special task active
    ---

    -- Apply tasks of this waypoint.
    local ntasks=self:_SetWaypointTasks(Waypoint)

    -- Get waypoint index.
    local wpindex=self:GetWaypointIndex(Waypoint.uid)

    -- Final waypoint reached?
    if wpindex==nil or wpindex==#self.waypoints then

      -- Ad infinitum and not mission waypoint?
      if self.adinfinitum then
        ---
        -- Ad Infinitum
        ---

        if Waypoint.missionUID then
          ---
          -- Last waypoint was a mission waypoint ==> Do nothing (when mission is over, it should take care of this)
          ---
        else

          ---
          -- Last waypoint reached.
          ---

          if #self.waypoints<=1 then
            -- Only one waypoint. Ad infinitum does not really make sense. However, another waypoint could be added later...
            self:_PassedFinalWaypoint(true, "PassingWaypoint: adinfinitum but only ONE WAYPOINT left")
          else

            --[[ Solved now!

            -- Looks like the passing waypoint function is triggered over and over again if the group is near the final waypoint.
            -- So the only good solution is to guide the group away from that waypoint and then update the route.

            -- Get first waypoint.
            local wp1=self:GetWaypointByIndex(1)

            -- Get a waypoint
            local Coordinate=Waypoint.coordinate:GetIntermediateCoordinate(wp1.coordinate, 0.1)
            
            local formation=nil
            if self.isArmygroup then
              formation=ENUMS.Formation.Vehicle.OffRoad
            end
                                    
            self:Detour(Coordinate, self.speedCruise, formation, true)
            
            ]]
            
                  
            -- Send 
            self:__UpdateRoute(-0.01, 1, 1)

          end
        end
      else
        ---
        -- NOT Ad Infinitum
        ---

        -- Final waypoint reached.
        self:_PassedFinalWaypoint(true, "PassingWaypoint: wpindex=#self.waypoints (or wpindex=nil)")
      end
      
    elseif wpindex==1 then

      -- Ad infinitum and not mission waypoint?
      if self.adinfinitum then
        ---
        -- Ad Infinitum
        ---

        if #self.waypoints<=1 then
          -- Only one waypoint. Ad infinitum does not really make sense. However, another waypoint could be added later...
          self:_PassedFinalWaypoint(true, "PassingWaypoint: adinfinitum but only ONE WAYPOINT left")
          
        else
        
          if not Waypoint.missionUID then
            -- Redo the route until the end.
            self:__UpdateRoute(-0.01, 2)
          end
        end
      end

    end

    -- Passing mission waypoint?
    local isEgress=false
    if Waypoint.missionUID then

      -- Debug info.
      self:T2(self.lid..string.format("Passing mission waypoint UID=%s", tostring(Waypoint.uid)))

      -- Get the mission.
      local mission=self:GetMissionByID(Waypoint.missionUID)

      -- Check if this was an Egress waypoint of the mission. If so, call Mission Done! This will call CheckGroupDone.
      local EgressUID=mission and mission:GetGroupEgressWaypointUID(self) or nil
      isEgress=EgressUID and Waypoint.uid==EgressUID
      if isEgress and mission:GetGroupStatus(self)~=AUFTRAG.GroupStatus.DONE then
        self:MissionDone(mission)
      end
    end

    -- Check if all tasks/mission are done?
    -- Note, we delay it for a second to let the OnAfterPassingwaypoint function to be executed in case someone wants to add another waypoint there.
    if ntasks==0 and self:HasPassedFinalWaypoint() and not isEgress then
      self:_CheckGroupDone(0.01)
    end

    -- Debug info.
    local text=string.format("Group passed waypoint %s/%d ID=%d: final=%s detour=%s astar=%s",
    tostring(wpindex), #self.waypoints, Waypoint.uid, tostring(self.passedfinalwp), tostring(Waypoint.detour), tostring(Waypoint.astar))
    self:T(self.lid..text)

  end
  
  -- Set expected speed.
  local wpnext=self:GetWaypointNext()
  if wpnext then
    self.speedWp=wpnext.speed
    self:T(self.lid..string.format("Expected/waypoint speed=%.1f m/s", self.speedWp))
  end

end

--- Set tasks at this waypoint
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint Waypoint The waypoint.
-- @return #number Number of tasks.
function OPSGROUP:_SetWaypointTasks(Waypoint)

  -- Get all waypoint tasks.
  local tasks=self:GetTasksWaypoint(Waypoint.uid)

  -- Debug info.
  local text=string.format("WP uid=%d tasks:", Waypoint.uid)
  local missiontask=nil --Ops.OpsGroup#OPSGROUP.Task
  if #tasks>0 then
    for i,_task in pairs(tasks) do
      local task=_task --#OPSGROUP.Task
      text=text..string.format("\n[%d] %s", i, task.description)
      if task.ismission then
        missiontask=task
      end
    end
  else
    text=text.." None"
  end
  self:T(self.lid..text)

  -- Check if there is mission task
  if missiontask then
    self:T(self.lid.."Executing mission task")
    local mission=self:GetMissionByTaskID(missiontask.id)
    if mission then
      if mission.opstransport and not mission.opstransport:IsCargoDelivered(self.groupname) then
        self:PauseMission()
        return
      end
    end
    self:TaskExecute(missiontask)
    return 1
  end

  -- TODO: maybe set waypoint enroute tasks?

  -- Tasks at this waypoints.
  local taskswp={}

  for _,task in pairs(tasks) do
    local Task=task --Ops.OpsGroup#OPSGROUP.Task

    -- Task execute.
    table.insert(taskswp, self.group:TaskFunction("OPSGROUP._TaskExecute", self, Task))

    -- Stop condition if userflag is set to 1 or task duration over.
    local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)

    -- Controlled task.
    table.insert(taskswp, self.group:TaskControlled(Task.dcstask, TaskCondition))

    -- Task done.
    table.insert(taskswp, self.group:TaskFunction("OPSGROUP._TaskDone", self, Task))

  end

  -- Execute waypoint tasks.
  if #taskswp>0 then
    self:SetTask(self.group:TaskCombo(taskswp))
  end

  return #taskswp
end

--- On after "PassedFinalWaypoint" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterPassedFinalWaypoint(From, Event, To)
  self:T(self.lid..string.format("Group passed final waypoint"))

  -- Check if group is done? No tasks mission running.
  --self:_CheckGroupDone()

end

--- On after "GotoWaypoint" event. Group will got to the given waypoint and execute its route from there.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number UID The goto waypoint unique ID.
-- @param #number Speed (Optional) Speed to waypoint in knots.
function OPSGROUP:onafterGotoWaypoint(From, Event, To, UID, Speed)

  local n=self:GetWaypointIndex(UID)

  if n then

    -- Speed to waypoint.
    Speed=Speed or self:GetSpeedToWaypoint(n)

    -- Debug message
    self:T(self.lid..string.format("Goto Waypoint UID=%d index=%d from %d at speed %.1f knots", UID, n, self.currentwp, Speed))

    -- Update the route.
    self:__UpdateRoute(0.1, n, nil, Speed)

  end

end

--- On after "DetectedUnit" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit.
function OPSGROUP:onafterDetectedUnit(From, Event, To, Unit)

  -- Get unit name.
  local unitname=Unit and Unit:GetName() or "unknown"

  -- Debug.
  self:T2(self.lid..string.format("Detected unit %s", unitname))

  if self.detectedunits:FindUnit(unitname) then
    -- Unit is already in the detected unit set ==> Trigger "DetectedUnitKnown" event.
    self:DetectedUnitKnown(Unit)
  else
    -- Unit is was not detected ==> Trigger "DetectedUnitNew" event.
    self:DetectedUnitNew(Unit)
  end

end

--- On after "DetectedUnitNew" event. Add newly detected unit to detected unit set.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit.
function OPSGROUP:onafterDetectedUnitNew(From, Event, To, Unit)

  -- Debug info.
  self:T(self.lid..string.format("Detected New unit %s", Unit:GetName()))

  -- Add unit to detected unit set.
  self.detectedunits:AddUnit(Unit)
end

--- On after "DetectedGroup" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group The detected Group.
function OPSGROUP:onafterDetectedGroup(From, Event, To, Group)

  -- Get group name.
  local groupname=Group and Group:GetName() or "unknown"

  -- Debug info.
  self:T(self.lid..string.format("Detected group %s", groupname))

  if self.detectedgroups:FindGroup(groupname) then
    -- Group is already in the detected set ==> Trigger "DetectedGroupKnown" event.
    self:DetectedGroupKnown(Group)
  else
    -- Group is was not detected ==> Trigger "DetectedGroupNew" event.
    self:DetectedGroupNew(Group)
  end

end

--- On after "DetectedGroupNew" event. Add newly detected group to detected group set.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group The detected group.
function OPSGROUP:onafterDetectedGroupNew(From, Event, To, Group)

  -- Debug info.
  self:T(self.lid..string.format("Detected New group %s", Group:GetName()))

  -- Add unit to detected unit set.
  self.detectedgroups:AddGroup(Group)
end

--- On after "EnterZone" event. Sets self.inzones[zonename]=true.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone that the group entered.
function OPSGROUP:onafterEnterZone(From, Event, To, Zone)
  local zonename=Zone and Zone:GetName() or "unknown"
  self:T2(self.lid..string.format("Entered Zone %s", zonename))
  self.inzones:Add(Zone:GetName(), Zone)
end

--- On after "LeaveZone" event. Sets self.inzones[zonename]=false.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone that the group entered.
function OPSGROUP:onafterLeaveZone(From, Event, To, Zone)
  local zonename=Zone and Zone:GetName() or "unknown"
  self:T2(self.lid..string.format("Left Zone %s", zonename))
  self.inzones:Remove(zonename, true)
end

--- On before "LaserOn" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Target Target Coordinate. Target can also be any POSITIONABLE from which we can obtain its coordinates.
function OPSGROUP:onbeforeLaserOn(From, Event, To, Target)

  -- Check if LASER is already on.
  if self.spot.On then
    return false
  end

  if Target then

    -- Target specified ==> set target.
    self:SetLaserTarget(Target)

  else
    -- No target specified.
    self:T(self.lid.."ERROR: No target provided for LASER!")
    return false
  end

  -- Get the first element alive.
  local element=self:GetElementAlive()

  if element then

    -- Set element.
    self.spot.element=element

    -- Height offset. No offset for aircraft. We take the height for ground or naval.
    local offsetY=2 --2m for ARMYGROUP, else there might be no LOS
    if self.isFlightgroup or self.isNavygroup then
      offsetY=element.height
    end

    -- Local offset of the LASER source.
    self.spot.offset={x=0, y=offsetY, z=0}

    -- Check LOS.
    if self.spot.CheckLOS then

      -- Check LOS.
      local los=self:HasLoS(self.spot.Coordinate, self.spot.element, self.spot.offset)

      --self:T({los=los, coord=self.spot.Coordinate, offset=self.spot.offset})

      if los then
        self:LaserGotLOS()
      else
        -- Try to switch laser on again in 10 sec.
        self:T(self.lid.."LASER got no LOS currently. Trying to switch the laser on again in 10 sec")
        self:__LaserOn(-10, Target)
        return false
      end

    end

  else
    self:T(self.lid.."ERROR: No element alive for lasing")
    return false
  end

  return true
end

--- On after "LaserOn" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Target Target Coordinate. Target can also be any POSITIONABLE from which we can obtain its coordinates.
function OPSGROUP:onafterLaserOn(From, Event, To, Target)

  -- Start timer that calls the update twice per sec by default.
  if not self.spot.timer:IsRunning() then
    self.spot.timer:Start(nil, self.spot.dt)
  end

  -- Get DCS unit.
  local DCSunit=self.spot.element.unit:GetDCSObject()

  -- Create laser and IR beams.
  self.spot.Laser=Spot.createLaser(DCSunit, self.spot.offset, self.spot.vec3, self.spot.Code or 1688)
  if self.spot.IRon then
    self.spot.IR=Spot.createInfraRed(DCSunit, self.spot.offset, self.spot.vec3)
  end

  -- Laser is on.
  self.spot.On=true

  -- No paused in case it was.
  self.spot.Paused=false

  -- Debug message.
  self:T(self.lid.."Switching LASER on")

end

--- On before "LaserOff" event. Check if LASER is on.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onbeforeLaserOff(From, Event, To)
  return self.spot.On or self.spot.Paused
end

--- On after "LaserOff" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLaserOff(From, Event, To)

  -- Debug message.
  self:T(self.lid.."Switching LASER off")

  -- "Destroy" the laser beam.
  if self.spot.On then
    self.spot.Laser:destroy()
    self.spot.IR:destroy()

    -- Set to nil.
    self.spot.Laser=nil
    self.spot.IR=nil
  end

  -- Stop update timer.
  self.spot.timer:Stop()

  -- No target unit.
  self.spot.TargetUnit=nil

  -- Laser is off.
  self.spot.On=false

  -- Not paused if it was.
  self.spot.Paused=false
end

--- On after "LaserPause" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLaserPause(From, Event, To)

  -- Debug message.
  self:T(self.lid.."Switching LASER off temporarily")

  -- "Destroy" the laser beam.
  self.spot.Laser:destroy()
  self.spot.IR:destroy()

  -- Set to nil.
  self.spot.Laser=nil
  self.spot.IR=nil

  -- Laser is off.
  self.spot.On=false

  -- Laser is paused.
  self.spot.Paused=true

end

--- On before "LaserResume" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onbeforeLaserResume(From, Event, To)
  return self.spot.Paused
end

--- On after "LaserResume" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLaserResume(From, Event, To)

  -- Debug info.
  self:T(self.lid.."Resuming LASER")

  -- Unset paused.
  self.spot.Paused=false

  -- Set target.
  local target=nil
  if self.spot.TargetType==0 then
    target=self.spot.Coordinate
  elseif self.spot.TargetType==1 or self.spot.TargetType==2 then
    target=self.spot.TargetUnit
  elseif self.spot.TargetType==3 then
    target=self.spot.TargetGroup
  end

  -- Switch laser back on.
  if target then

    -- Debug message.
    self:T(self.lid.."Switching LASER on again")

    self:LaserOn(target)
  end

end

--- On after "LaserCode" event. Changes the LASER code.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Code Laser code. Default is 1688.
function OPSGROUP:onafterLaserCode(From, Event, To, Code)

  -- Default is 1688.
  self.spot.Code=Code or 1688

  -- Debug message.
  self:T2(self.lid..string.format("Setting LASER Code to %d", self.spot.Code))

  if self.spot.On then

    -- Debug info.
    self:T(self.lid..string.format("New LASER Code is %d", self.spot.Code))

    -- Set LASER code.
    self.spot.Laser:setCode(self.spot.Code)
  end

end

--- On after "LaserLostLOS" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLaserLostLOS(From, Event, To)

  -- No of sight.
  self.spot.LOS=false

  -- Lost line of sight.
  self.spot.lostLOS=true

  if self.spot.On then

    -- Switch laser off.
    self:LaserPause()

  end

end

--- On after "LaserGotLOS" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLaserGotLOS(From, Event, To)

  -- Has line of sight.
  self.spot.LOS=true

  if self.spot.lostLOS then

    -- Did not loose LOS anymore.
    self.spot.lostLOS=false

    -- Resume laser if currently paused.
    if self.spot.Paused then
      self:LaserResume()
    end

  end

end

--- Set LASER target.
-- @param #OPSGROUP self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to lase. Can also be a COORDINATE object.
function OPSGROUP:SetLaserTarget(Target)

  if Target then

    -- Check object type.
    if Target:IsInstanceOf("SCENERY") then

      -- Scenery as target. Treat it like a coordinate. Set offset to 1 meter above ground.
      self.spot.TargetType=0
      self.spot.offsetTarget={x=0, y=3, z=0}

    elseif Target:IsInstanceOf("POSITIONABLE") then

      local target=Target --Wrapper.Positionable#POSITIONABLE

      if target:IsAlive() then

        if target:IsInstanceOf("GROUP") then
          -- We got a GROUP as target.
          self.spot.TargetGroup=target
          self.spot.TargetUnit=target:GetHighestThreat()
          self.spot.TargetType=3
        else
          -- We got a UNIT or STATIC as target.
          self.spot.TargetUnit=target
          if target:IsInstanceOf("STATIC") then
            self.spot.TargetType=1
          elseif target:IsInstanceOf("UNIT") then
            self.spot.TargetType=2
          end
        end

        -- Get object size.
        local size,x,y,z=self.spot.TargetUnit:GetObjectSize()

        if y then
          self.spot.offsetTarget={x=0, y=y*0.75, z=0}
        else
          self.spot.offsetTarget={x=0, 2, z=0}
        end

      else
        self:T("WARNING: LASER target is not alive!")
        return
      end

    elseif Target:IsInstanceOf("COORDINATE") then

      -- Coordinate as target.
      self.spot.TargetType=0
      self.spot.offsetTarget={x=0, y=0, z=0}

    else
      self:T(self.lid.."ERROR: LASER target should be a POSITIONABLE (GROUP, UNIT or STATIC) or a COORDINATE object!")
      return
    end

    -- Set vec3 and account for target offset.
    self.spot.vec3=UTILS.VecAdd(Target:GetVec3(), self.spot.offsetTarget)

    -- Set coordinate.
    self.spot.Coordinate:UpdateFromVec3(self.spot.vec3)
    
    --self.spot.Coordinate:MarkToAll("Target Laser",ReadOnly,Text)
  end

end

--- Update laser point.
-- @param #OPSGROUP self
function OPSGROUP:_UpdateLaser()

  -- Check if we have a POSITIONABLE to lase.
  if self.spot.TargetUnit then

    ---
    -- Lasing a possibly moving target
    ---

    if self.spot.TargetUnit:IsAlive() then

      -- Get current target position.
      local vec3=self.spot.TargetUnit:GetVec3()

      -- Add target offset.
      vec3=UTILS.VecAdd(vec3, self.spot.offsetTarget)

      -- Calculate distance
      local dist=UTILS.VecDist3D(vec3, self.spot.vec3)

      -- Store current position.
      self.spot.vec3=vec3

      -- Update beam coordinate.
      self.spot.Coordinate:UpdateFromVec3(vec3)

      -- Update laser if target moved more than one meter.
      if dist>1 then

        -- If the laser is ON, set the new laser target point.
        if self.spot.On then
          self.spot.Laser:setPoint(vec3)
          if self.spot.IRon then
            self.spot.IR:setPoint(vec3)
          end
        end

      end

    else

      if self.spot.TargetGroup and self.spot.TargetGroup:IsAlive() then

        -- Get first alive unit in the group.
        local unit=self.spot.TargetGroup:GetHighestThreat()

        if unit then
          self:T(self.lid..string.format("Switching to target unit %s in the group", unit:GetName()))
          self.spot.TargetUnit=unit
          -- We update the laser position in the next update cycle and then check the LOS.
          return
        else
          -- Switch laser off.
          self:T(self.lid.."Target is not alive any more ==> switching LASER off")
          self:LaserOff()
          return
        end

      else

        -- Switch laser off.
        self:T(self.lid.."Target is not alive any more ==> switching LASER off")
        self:LaserOff()
        return
      end

    end
  end

  -- Check LOS.
  if self.spot.CheckLOS then

    -- Check current LOS.
    local los=self:HasLoS(self.spot.Coordinate, self.spot.element, self.spot.offset)

    if los then
      -- Got LOS
      if self.spot.lostLOS then
        --self:T({los=self.spot.LOS, coord=self.spot.Coordinate, offset=self.spot.offset})
        self:LaserGotLOS()
      end

    else
      -- No LOS currently
      if not self.spot.lostLOS then
        self:LaserLostLOS()
      end

    end

  end

end

--- On before "ElementSpawned" event. Check that element is not in status spawned already.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Element Element The flight group element.
function OPSGROUP:onbeforeElementSpawned(From, Event, To, Element)

  if Element and Element.status==OPSGROUP.ElementStatus.SPAWNED then
    self:T2(self.lid..string.format("Element %s is already spawned ==> Transition denied!", Element.name))
    return false
  end

  return true
end

--- On after "ElementInUtero" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Element Element The flight group element.
function OPSGROUP:onafterElementInUtero(From, Event, To, Element)
  self:T(self.lid..string.format("Element in utero %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.INUTERO)

end

--- On after "ElementDamaged" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Element Element The flight group element.
function OPSGROUP:onafterElementDamaged(From, Event, To, Element)
  self:T(self.lid..string.format("Element damaged %s", Element.name))
  
  if Element and (Element.status~=OPSGROUP.ElementStatus.DEAD and Element.status~=OPSGROUP.ElementStatus.INUTERO) then
  
    local lifepoints=0
    
    if Element.DCSunit and Element.DCSunit:isExist() then

      -- Get life of unit
      lifepoints=Element.DCSunit:getLife()
    
      -- Debug output.
      self:T(self.lid..string.format("Element life %s: %.2f/%.2f", Element.name, lifepoints, Element.life0))
        
    else
    
      self:T(self.lid..string.format("Element.DCSunit %s does not exist!", Element.name))
      
    end
    
    if lifepoints<=1.0 then
      self:T(self.lid..string.format("Element %s life %.2f <= 1.0 ==> Destroyed!", Element.name, lifepoints))
      self:ElementDestroyed(Element)
    end
    
  end
    
end

--- On after "ElementHit" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Element Element The flight group element.
-- @param Wrapper.Unit#UNIT Enemy Unit that hit the element or `nil`.
function OPSGROUP:onafterElementHit(From, Event, To, Element, Enemy)

  -- Increase element hit counter.
  Element.Nhit=Element.Nhit+1

  -- Debug message.
  self:T(self.lid..string.format("Element hit %s by %s [n=%d, N=%d]", Element.name, Enemy and Enemy:GetName() or "unknown", Element.Nhit, self.Nhit))

  -- Group was hit.
  self:__Hit(-3, Enemy)

end

--- On after "Hit" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Enemy Unit that hit the element or `nil`.
function OPSGROUP:onafterHit(From, Event, To, Enemy)
  self:T(self.lid..string.format("Group hit by %s", Enemy and Enemy:GetName() or "unknown"))  
end


--- On after "ElementDestroyed" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Element Element The flight group element.
function OPSGROUP:onafterElementDestroyed(From, Event, To, Element)
  self:T(self.lid..string.format("Element destroyed %s", Element.name))

  -- Cancel all missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    mission:ElementDestroyed(self, Element)

  end

  -- Increase counter.
  self.Ndestroyed=self.Ndestroyed+1

  -- Element is dead.
  self:ElementDead(Element)

end

--- On after "ElementDead" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Element Element The flight group element.
function OPSGROUP:onafterElementDead(From, Event, To, Element)

  -- Debug info.
  self:T(self.lid..string.format("Element dead %s at t=%.3f", Element.name, timer.getTime()))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.DEAD)

  -- Check if element was lasing and if so, switch to another unit alive to lase.
  if self.spot.On and self.spot.element.name==Element.name then

    -- Switch laser off.
    self:LaserOff()

    -- If there is another element alive, switch laser on again.
    if self:GetNelements()>0 then

      -- New target if any.
      local target=nil

      if self.spot.TargetType==0 then
        -- Coordinate
        target=self.spot.Coordinate
      elseif self.spot.TargetType==1 or self.spot.TargetType==2 then
        -- Static or unit
        if self.spot.TargetUnit and self.spot.TargetUnit:IsAlive() then
          target=self.spot.TargetUnit
        end
      elseif self.spot.TargetType==3 then
        -- Group
        if self.spot.TargetGroup and self.spot.TargetGroup:IsAlive() then
          target=self.spot.TargetGroup
        end
      end

      -- Switch laser on again.
      if target then
        self:__LaserOn(-1, target)
      end
    end
  end


  -- Clear cargo bay of element.
  for i=#Element.cargoBay,1,-1 do
    local mycargo=Element.cargoBay[i] --#OPSGROUP.MyCargo
    
    if mycargo.group then

      -- Remove from cargo bay.
      self:_DelCargobay(mycargo.group)
  
      if mycargo.group and not (mycargo.group:IsDead() or mycargo.group:IsStopped()) then
  
        -- Remove my carrier
        mycargo.group:_RemoveMyCarrier()
  
        if mycargo.reserved then
  
          -- This group was not loaded yet ==> Not cargo any more.
          mycargo.group:_NewCargoStatus(OPSGROUP.CargoStatus.NOTCARGO)
  
        else
  
          -- Carrier dead ==> cargo dead.
          for _,cargoelement in pairs(mycargo.group.elements) do
  
            -- Debug info.
            self:T2(self.lid.."Cargo element dead "..cargoelement.name)
  
            -- Trigger dead event.
            mycargo.group:ElementDead(cargoelement)
  
          end
        end
  
      end
      
    else
          
      -- Add cargo to lost.
      if self.cargoTZC then
        for _,_cargo in pairs(self.cargoTZC.Cargos) do
          local cargo=_cargo --#OPSGROUP.CargoGroup          
          if cargo.uid==mycargo.cargoUID then          
            cargo.storage.cargoLost=cargo.storage.cargoLost+mycargo.storageAmount
          end
        end      
      end

      -- Remove cargo from cargo bay.
      self:_DelCargobayElement(Element, mycargo)
    
    end
  end

end

--- On after "Respawn" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table Template The template used to respawn the group. Default is the inital template of the group.
function OPSGROUP:onafterRespawn(From, Event, To, Template)

  -- Debug info.
  self:T(self.lid.."Respawning group!")

  -- Copy template.
  local template=UTILS.DeepCopy(Template or self.template)

  -- Late activation off.
  template.lateActivation=false

  self:_Respawn(0, template)

end

--- Teleport the group to a different location.
-- @param #OPSGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate where the group is teleported to.
-- @param #number Delay Delay in seconds before respawn happens. Default 0.
-- @param #boolean NoPauseMission If `true`, dont pause a running mission.
-- @return #OPSGROUP self
function OPSGROUP:Teleport(Coordinate, Delay, NoPauseMission)
    
  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.Teleport, self, Coordinate, 0, NoPauseMission)
  else    

    -- Debug message.
    self:T(self.lid.."FF Teleporting...")
    --Coordinate:MarkToAll("Teleport "..self.groupname)
    
    -- Check if we have a mission running.
    if self:IsOnMission() and not NoPauseMission then
      self:T(self.lid.."Pausing current mission for telport")
      self:PauseMission()
    end

    -- Get copy of template.
    local Template=UTILS.DeepCopy(self.template)  --DCS#Template
    
    -- Set late activation of template to current state.
    Template.lateActivation=self:IsLateActivated()
    
    -- Not uncontrolled.
    Template.uncontrolled=false
    
    -- Set waypoint in air for flighgroups.
    if self:IsFlightgroup() then
      Template.route.points[1]=Coordinate:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, 300, true, nil, nil, "Spawnpoint")
    elseif self:IsArmygroup() then
      Template.route.points[1]=Coordinate:WaypointGround(0)
    elseif self:IsNavygroup() then
      Template.route.points[1]=Coordinate:WaypointNaval(0)
    end

    -- Template units.
    local units=Template.units
    
    -- Table with teleported vectors.
    local d={}
    for i=1,#units do
      local unit=units[i]
      d[i]={x=Coordinate.x+(units[i].x-units[1].x), y=Coordinate.z+units[i].y-units[1].y}
    end    

    for i=#units,1,-1 do
      local unit=units[i]

      -- Get element.      
      local element=self:GetElementByName(unit.name)
      
      if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      
        -- No parking.
        unit.parking=nil
        unit.parking_id=nil
        
        -- Current position.
        local vec3=element.unit:GetVec3()
        
        -- Current heading.
        local heading=element.unit:GetHeading()
        
        -- Set new x,y.
        unit.x=d[i].x
        unit.y=d[i].y
        
        -- Set altitude.
        unit.alt=Coordinate.y
        
        -- Set heading.
        unit.heading=math.rad(heading)
        unit.psi=-unit.heading
      else
        -- Remove unit from spawn template because it is already dead
        table.remove(units, i)
      end
    end

    -- Respawn from new template.  
    self:_Respawn(0, Template, true)
    
  end
end

--- Respawn the group.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds before respawn happens. Default 0.
-- @param DCS#Template Template (optional) The template of the Group retrieved with GROUP:GetTemplate(). If the template is not provided, the template will be retrieved of the group itself.
-- @param #boolean Reset Reset waypoints and reinit group if `true`.
-- @return #OPSGROUP self
function OPSGROUP:_Respawn(Delay, Template, Reset)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP._Respawn, self, 0, Template, Reset)
  else

    -- Debug message.
    self:T2(self.lid.."FF _Respawn")

    -- Given template or get copy of old.
    Template=Template or self:_GetTemplate(true)
    
    -- Number of destroyed units.
    self.Ndestroyed=0
    self.Nhit=0

    -- Check if group is currently alive.
    if self:IsAlive() then

      ---
      -- Group is ALIVE
      ---

      -- Template units.
      local units=Template.units

      for i=#units,1,-1 do
        local unit=units[i]
        
        -- Get the element.
        local element=self:GetElementByName(unit.name)
        
        if element and element.status~=OPSGROUP.ElementStatus.DEAD then
        
          if not Reset then
        
            -- Parking ID.
            unit.parking=element.parking and element.parking.TerminalID or unit.parking
            unit.parking_id=nil
            
            -- Get current position vector.
            local vec3=element.unit:GetVec3()
            
            -- Get heading.
            local heading=element.unit:GetHeading()
            
            -- Set unit position.
            unit.x=vec3.x
            unit.y=vec3.z
            unit.alt=vec3.y
            
            -- Set heading in rad.
            unit.heading=math.rad(heading)
            unit.psi=-unit.heading
            
          end
          
        else
        
          -- Element is dead. Remove from template.
          table.remove(units, i)
          
          self.Ndestroyed=self.Ndestroyed+1
          
        end
      end


      -- Despawn old group. Dont trigger any remove unit event since this is a respawn.
      self:Despawn(0, true)

    end

    -- Ensure elements in utero.
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element and element.status~=OPSGROUP.ElementStatus.DEAD then
        self:ElementInUtero(element)
      end
    end    

    -- Spawn with a little delay (especially Navy groups caused problems if they were instantly respawned)
    self:_Spawn(0.01, Template)

  end

  return self
end

--- Spawn group from a given template.
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds before respawn happens. Default 0.
-- @param DCS#Template Template (optional) The template of the Group retrieved with GROUP:GetTemplate(). If the template is not provided, the template will be retrieved of the group itself.
-- @return #OPSGROUP self
function OPSGROUP:_Spawn(Delay, Template)
  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP._Spawn, self, 0, Template)
  else
    -- Debug output.
    --self:T2({Template=Template})

    if self:IsArmygroup() and self.ValidateAndRepositionGroundUnits then
        UTILS.ValidateAndRepositionGroundUnits(Template.units)
    end

    -- Spawn new group.
    self.group=_DATABASE:Spawn(Template)
    self.group:SetValidateAndRepositionGroundUnits(self.ValidateAndRepositionGroundUnits)
    --local countryID=self.group:GetCountry()
    --local categoryID=self.group:GetCategory()
    --local dcsgroup=coalition.addGroup(countryID, categoryID, Template)

    -- Set DCS group and controller.
    self.dcsgroup=self:GetDCSGroup()
    self.controller=self.dcsgroup:getController()

    -- Set activation and controlled state.
    self.isLateActivated=Template.lateActivation
    self.isUncontrolled=Template.uncontrolled

    -- Not dead or destroyed any more.
    self.isDead=false
    self.isDestroyed=false

    self.groupinitialized=false    
    self.wpcounter=1
    self.currentwp=1

    -- Init waypoints.
    self:_InitWaypoints()

    -- Init Group. This call is delayed because NAVY groups did not like to be initialized just yet (group did not contain any units).
    self:_InitGroup(Template, 0.001)
    
    -- Reset events.
    --self:ResetEvents()  
  end
end

--- On after "InUtero" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterInUtero(From, Event, To)
  self:T(self.lid..string.format("Group inutero at t=%.3f", timer.getTime()))
  --TODO: set element status to inutero
end

--- On after "Damaged" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterDamaged(From, Event, To)
  self:T(self.lid..string.format("Group damaged at t=%.3f", timer.getTime()))
end

--- On after "Destroyed" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterDestroyed(From, Event, To)
  self:T(self.lid..string.format("Group destroyed at t=%.3f", timer.getTime()))
  self.isDestroyed=true
end

--- On before "Dead" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onbeforeDead(From, Event, To)
  if self.Ndestroyed==#self.elements then
    self:Destroyed()
  end
end

--- On after "Dead" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterDead(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Group dead at t=%.3f", timer.getTime()))

  -- Is dead now.
  self.isDead=true

  -- Cancel all missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    self:T(self.lid.."Cancelling mission because group is dead! Mission name "..tostring(mission:GetName()))

    self:MissionCancel(mission)
    mission:GroupDead(self)

  end

  -- Delete waypoints so they are re-initialized at the next spawn.
  self:ClearWaypoints()
  self.groupinitialized=false

  -- Set cargo status to NOTCARGO.
  self.cargoStatus=OPSGROUP.CargoStatus.NOTCARGO
  self.carrierStatus=OPSGROUP.CarrierStatus.NOTCARRIER

  -- Remove from cargo bay of carrier.
  local mycarrier=self:_GetMyCarrierGroup()
  if mycarrier and not mycarrier:IsDead() then
    mycarrier:_DelCargobay(self)
    self:_RemoveMyCarrier()
  end

  -- Inform all transports in the queue that this carrier group is dead now.
  for i,_transport in pairs(self.cargoqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    transport:__DeadCarrierGroup(1, self)
  end

  -- Cargo queue empty
  self.cargoqueue={}

  -- No current cargo transport.
  self.cargoTransport=nil
  self.cargoTZC=nil

  if self.Ndestroyed==#self.elements then
    if self.cohort then
      -- All elements were destroyed ==> Asset group is gone.
      self.cohort:DelGroup(self.groupname)
    end
  else
    -- Not all assets were destroyed (despawn) ==> Add asset back to legion?
  end
  
  
  if self.legion then
    if not self:IsInUtero() then
    
      -- Get asset.
      local asset=self.legion:GetAssetByName(self.groupname)
      
      if asset then
      
      -- Get request.
      local request=self.legion:GetRequestByID(asset.rid)
      
      -- Trigger asset dead event.
      self.legion:AssetDead(asset, request)
      
      end
      
    end
  
    -- Stop in 5 sec to give possible respawn attempts a chance.  
    self:__Stop(-5)
    
  elseif not self.isAI then
    -- Stop player flights.
    self:__Stop(-1)
  end
    
end

--- On before "Stop" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onbeforeStop(From, Event, To)

  -- We check if
  if self:IsAlive() then
    self:T(self.lid..string.format("WARNING: Group is still alive! Will not stop the FSM. Use :Despawn() instead"))
    return false
  end

  return true
end

--- On after "Stop" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterStop(From, Event, To)

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.RemoveUnit)

  -- Handle events:
  if self.isFlightgroup then
    self:UnHandleEvent(EVENTS.EngineStartup)
    self:UnHandleEvent(EVENTS.Takeoff)
    self:UnHandleEvent(EVENTS.Land)
    self:UnHandleEvent(EVENTS.EngineShutdown)
    self:UnHandleEvent(EVENTS.PilotDead)
    self:UnHandleEvent(EVENTS.Ejection)
    self:UnHandleEvent(EVENTS.Crash)
    self.currbase=nil
  elseif self.isArmygroup then
    self:UnHandleEvent(EVENTS.Hit)
  end
  
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    self:MissionCancel(mission)
  end

  -- Stop check timers.
  self.timerCheckZone:Stop()
  self.timerQueueUpdate:Stop()
  self.timerStatus:Stop()

  -- Stop FSM scheduler.
  self.CallScheduler:Clear()
  if self.Scheduler then
    self.Scheduler:Clear()
  end

  -- Flightcontrol.
  if self.flightcontrol then
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element.parking then
        self.flightcontrol:SetParkingFree(element.parking)
      end
    end
    self.flightcontrol:_RemoveFlight(self)
  end

  if self:IsAlive() and not (self:IsDead() or self:IsStopped()) then
    local life, life0=self:GetLifePoints()
    local state=self:GetState()
    local text=string.format("WARNING: Group is still alive! Current state=%s. Life points=%d/%d. Use OPSGROUP:Destroy() or OPSGROUP:Despawn() for a clean stop", state, life, life0)
    self:T(self.lid..text)
  end

  -- Remove flight from data base.
  _DATABASE.FLIGHTGROUPS[self.groupname]=nil

  -- Debug output.
  self:T(self.lid.."STOPPED! Unhandled events, cleared scheduler and removed from _DATABASE")
end

--- On after "OutOfAmmo" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterOutOfAmmo(From, Event, To)
  self:T(self.lid..string.format("Group is out of ammo at t=%.3f", timer.getTime()))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cargo Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check cargo transport assignments.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:_CheckCargoTransport()

  -- Abs. missin time in seconds.
  local Time=timer.getAbsTime()

  -- Cargo bay debug info.
  if self.verbose>=1 then
    local text=""
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      for _,_cargo in pairs(element.cargoBay) do
        local cargo=_cargo --#OPSGROUP.MyCargo
        if cargo.group then
          text=text..string.format("\n- %s in carrier %s, reserved=%s", tostring(cargo.group:GetName()), tostring(element.name), tostring(cargo.reserved))
        else
          text=text..string.format("\n- storage %s=%d kg in carrier %s [UID=%s]", 
          tostring(cargo.storageType), tostring(cargo.storageAmount*cargo.storageWeight), tostring(element.name), tostring(cargo.cargoUID))
        end
      end
    end
    if text=="" then
      text=" empty"
    end
    self:T(self.lid.."Cargo bay:"..text)
  end

  -- Cargo queue debug info.
  if self.verbose>=3 then
    local text=""
    for i,_transport in pairs(self.cargoqueue) do
      local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
      local pickupzone=transport:GetPickupZone()
      local deployzone=transport:GetDeployZone()
      local pickupname=pickupzone and pickupzone:GetName() or "unknown"
      local deployname=deployzone and deployzone:GetName() or "unknown"
      text=text..string.format("\n[%d] UID=%d Status=%s: %s --> %s", i, transport.uid, transport:GetState(), pickupname, deployname)
      for j,_cargo in pairs(transport:GetCargos()) do
        local cargo=_cargo --#OPSGROUP.CargoGroup
        if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then
          local state=cargo.opsgroup:GetState()
          local status=cargo.opsgroup.cargoStatus
          local name=cargo.opsgroup.groupname
          local carriergroup, carrierelement, reserved=cargo.opsgroup:_GetMyCarrier()
          local carrierGroupname=carriergroup and carriergroup.groupname or "none"
          local carrierElementname=carrierelement and carrierelement.name or "none"
          text=text..string.format("\n  (%d) %s [%s]: %s, carrier=%s(%s), delivered=%s", j, name, state, status, carrierGroupname, carrierElementname, tostring(cargo.delivered))
        else
          --TODO: STORAGE
        end
      end
    end
    if text~="" then
      self:T(self.lid.."Cargo queue:"..text)
    end
  end

  if self.cargoTransport and self.cargoTransport:GetCarrierTransportStatus(self)==OPSTRANSPORT.Status.DELIVERED then
    -- Remove transport from queue.
    self:DelOpsTransport(self.cargoTransport)
    -- No current transport any more.
    self.cargoTransport=nil
    self.cargoTZC=nil
  end

  -- Get current mission (if any).  
  local mission=self:GetMissionCurrent()  

  -- Check if there is anything in the queue.
  if (not self.cargoTransport) and (mission==nil or mission.type==AUFTRAG.Type.NOTHING) then
    self.cargoTransport=self:_GetNextCargoTransport()
    if self.cargoTransport and mission then
      self:MissionCancel(mission)
    end
    if self.cargoTransport and not self:IsActive() then
      self:Activate()
    end
  end

  -- Now handle the transport.
  if self.cargoTransport then

    if self:IsNotCarrier() then

      -- Unset time stamps.
      self.Tpickingup=nil
      self.Tloading=nil
      self.Ttransporting=nil
      self.Tunloading=nil

      -- Get transport zone combo (TZC).
      self.cargoTZC=self.cargoTransport:_GetTransportZoneCombo(self)

      if self.cargoTZC then

        -- Found TZC
        self:T(self.lid..string.format("Not carrier ==> pickup at %s [TZC UID=%d]", self.cargoTZC.PickupZone and self.cargoTZC.PickupZone:GetName() or "unknown", self.cargoTZC.uid))

        -- Initiate the cargo transport process.
        self:__Pickup(-1)

      else
        self:T2(self.lid.."Not carrier ==> No TZC found")
      end

    elseif self:IsPickingup() then

      -- Set time stamp.
      self.Tpickingup=self.Tpickingup or Time

      -- Current pickup time.
      local tpickingup=Time-self.Tpickingup

      -- Debug Info.
      self:T(self.lid..string.format("Picking up at %s [TZC UID=%d] for %s sec...", self.cargoTZC.PickupZone and self.cargoTZC.PickupZone:GetName() or "unknown", self.cargoTZC.uid, tpickingup))

    elseif self:IsLoading() then

      -- Set loading time stamp.
      self.Tloading=self.Tloading or Time

      -- Current pickup time.
      local tloading=Time-self.Tloading

      --TODO: Check max loading time. If exceeded ==> abort transport. Time might depend on required cargos, because we need to give them time to arrive.

      -- Debug info.
      self:T(self.lid..string.format("Loading at %s [TZC UID=%d] for %.1f sec...", self.cargoTZC.PickupZone and self.cargoTZC.PickupZone:GetName() or "unknown", self.cargoTZC.uid, tloading))

      local boarding=false
      local gotcargo=false
      for _,_cargo in pairs(self.cargoTZC.Cargos) do
        local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
              
        if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then

          -- Check if anyone is still boarding.
          if cargo.opsgroup and cargo.opsgroup:IsBoarding(self.groupname) then
            boarding=true
          end
  
          -- Check if we have any cargo to transport.
          if cargo.opsgroup and cargo.opsgroup:IsLoaded(self.groupname) then
            gotcargo=true
          end
          
        else
        
          -- Get cargo if it is in the cargo bay of any carrier element.
          local mycargo=self:_GetMyCargoBayFromUID(cargo.uid)
          
          if mycargo and mycargo.storageAmount>0 then
            gotcargo=true
          end
          
        end

      end

      -- Boarding finished ==> Transport cargo.
	  local required=self.cargoTransport:_CheckRequiredCargos(self.cargoTZC, self)
      if gotcargo and required and not boarding then
        self:T(self.lid.."Boarding/loading finished ==> Loaded")
        self.Tloading=nil
        self:LoadingDone()
      else
        -- No cargo and no one is boarding ==> check again if we can make anyone board.
        self:Loading()
      end

    elseif self:IsTransporting() then

      -- Set time stamp.
      self.Ttransporting=self.Ttransporting or Time

      -- Current pickup time.
      local ttransporting=Time-self.Ttransporting

      -- Debug info.
      self:T(self.lid.."Transporting (nothing to do)")

    elseif self:IsUnloading() then

      -- Set time stamp.
      self.Tunloading=self.Tunloading or Time

      -- Current pickup time.
      local tunloading=Time-self.Tunloading

      -- Debug info.
      self:T(self.lid.."Unloading ==> Checking if all cargo was delivered")

      local delivered=true
      for _,_cargo in pairs(self.cargoTZC.Cargos) do
        local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
        
        if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then

          local carrierGroup=cargo.opsgroup:_GetMyCarrierGroup()
  
          -- Check that this group is
          if (carrierGroup and carrierGroup:GetName()==self:GetName()) and not cargo.delivered then
            delivered=false
            break
          end
          
        else
          ---
          -- STORAGE
          ---
          
          -- Get cargo if it is in the cargo bay of any carrier element.
          local mycargo=self:_GetMyCargoBayFromUID(cargo.uid)
          
          if mycargo and not cargo.delivered then
            delivered=false
            break
          end
                    
        end

      end

      -- Unloading finished ==> pickup next batch or call it a day.
      if delivered then
        self:T(self.lid.."Unloading finished ==> UnloadingDone")
        self:UnloadingDone()
      else
        self:Unloading()
      end

    end

    -- Debug info. (At this point, we might not have a current cargo transport ==> hence the check)
    if self.verbose>=2 and self.cargoTransport then
      local pickupzone=self.cargoTransport:GetPickupZone(self.cargoTZC)
      local deployzone=self.cargoTransport:GetDeployZone(self.cargoTZC)
      local pickupname=pickupzone and pickupzone:GetName() or "unknown"
      local deployname=deployzone and deployzone:GetName() or "unknown"
      local text=string.format("Carrier [%s]: %s --> %s", self.carrierStatus, pickupname, deployname)
      for _,_cargo in pairs(self.cargoTransport:GetCargos(self.cargoTZC)) do
        local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
        if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then
          local name=cargo.opsgroup:GetName()
          local gstatus=cargo.opsgroup:GetState()
          local cstatus=cargo.opsgroup.cargoStatus
          local weight=cargo.opsgroup:GetWeightTotal()
          local carriergroup, carrierelement, reserved=cargo.opsgroup:_GetMyCarrier()
          local carrierGroupname=carriergroup and carriergroup.groupname or "none"
          local carrierElementname=carrierelement and carrierelement.name or "none"
          text=text..string.format("\n- %s (%.1f kg) [%s]: %s, carrier=%s (%s), delivered=%s", name, weight, gstatus, cstatus, carrierElementname, carrierGroupname, tostring(cargo.delivered))
        else
          --TODO: Storage
        end
      end
      self:I(self.lid..text)
    end

  end

  return self
end


--- Check if a group is in the cargo bay.
-- @param #OPSGROUP self
-- @param #OPSGROUP OpsGroup Group to check.
-- @return #boolean If `true`, group is in the cargo bay.
function OPSGROUP:_IsInCargobay(OpsGroup)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    for _,_cargo in pairs(element.cargoBay) do
      local cargo=_cargo --#OPSGROUP.MyCargo
      if cargo.group.groupname==OpsGroup.groupname then
        return true
      end
    end
  end

  return false
end

--- Add OPSGROUP to cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP CargoGroup Cargo group.
-- @param #OPSGROUP.Element CarrierElement The element of the carrier.
-- @param #boolean Reserved Only reserve the cargo bay space.
function OPSGROUP:_AddCargobay(CargoGroup, CarrierElement, Reserved)

  --TODO: Check group is not already in cargobay of this carrier or any other carrier.

  local cargo=self:_GetCargobay(CargoGroup)

  if cargo then
    cargo.reserved=Reserved
  else
  
    --cargo=self:_CreateMyCargo(CargoUID, CargoGroup)

    cargo={} --#OPSGROUP.MyCargo
    cargo.group=CargoGroup
    cargo.reserved=Reserved

    table.insert(CarrierElement.cargoBay, cargo)
  end


  -- Set my carrier.
  CargoGroup:_SetMyCarrier(self, CarrierElement, Reserved)

  -- Fill cargo bay (obsolete).
  self.cargoBay[CargoGroup.groupname]=CarrierElement.name

  if not Reserved then

    -- Cargo weight.
    local weight=CargoGroup:GetWeightTotal()

    -- Add weight to carrier.
    self:AddWeightCargo(CarrierElement.name, weight)

  end

  return self
end

--- Add warehouse storage to cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element CarrierElement The element of the carrier.
-- @param #number CargoUID UID of the cargo data.
-- @param #string StorageType Storage type.
-- @param #number StorageAmount Storage amount.
-- @param #number StorageWeight Weight of a single storage item in kg.
function OPSGROUP:_AddCargobayStorage(CarrierElement, CargoUID, StorageType, StorageAmount, StorageWeight)

  local MyCargo=self:_CreateMyCargo(CargoUID, nil, StorageType, StorageAmount, StorageWeight)
  
  self:_AddMyCargoBay(MyCargo, CarrierElement)

  
end

--- Add OPSGROUP to cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #number CargoUID UID of the cargo data.
-- @param #OPSGROUP OpsGroup Cargo group.
-- @param #string StorageType Storage type.
-- @param #number StorageAmount Storage amount.
-- @param #number StorageWeight Weight of a single storage item in kg.
-- @return #OPSGROUP.MyCargo My cargo object.
function OPSGROUP:_CreateMyCargo(CargoUID, OpsGroup, StorageType, StorageAmount, StorageWeight)

  local cargo={} --#OPSGROUP.MyCargo
  
  cargo.cargoUID=CargoUID
  cargo.group=OpsGroup
  cargo.storageType=StorageType
  cargo.storageAmount=StorageAmount
  cargo.storageWeight=StorageWeight
  cargo.reserved=false

  return cargo
end


--- Add storage to cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP.MyCargo MyCargo My cargo.
-- @param #OPSGROUP.Element CarrierElement The element of the carrier.
function OPSGROUP:_AddMyCargoBay(MyCargo, CarrierElement)

  table.insert(CarrierElement.cargoBay, MyCargo)

  if not MyCargo.reserved then

    -- Cargo weight.
    local weight=0
    
    if MyCargo.group then
      weight=MyCargo.group:GetWeightTotal()
    else
      weight=MyCargo.storageAmount*MyCargo.storageWeight
    end

    -- Add weight to carrier.
    self:AddWeightCargo(CarrierElement.name, weight)

  end


end

--- Get cargo bay data from a cargo data id.
-- @param #OPSGROUP self
-- @param #number uid Unique ID of cargo data.
-- @return #OPSGROUP.MyCargo Cargo My cargo.
-- @return #OPSGROUP.Element Element that has loaded the cargo.
function OPSGROUP:_GetMyCargoBayFromUID(uid)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    
    for i,_mycargo in pairs(element.cargoBay) do
      local mycargo=_mycargo --#OPSGROUP.MyCargo
      
      if mycargo.cargoUID and mycargo.cargoUID==uid then
        return mycargo, element, i
      end
    end
  end
  
  return nil, nil, nil
end


--- Get all groups currently loaded as cargo.
-- @param #OPSGROUP self
-- @param #string CarrierName (Optional) Only return cargo groups loaded into a particular carrier unit.
-- @return #table Cargo ops groups.
function OPSGROUP:GetCargoGroups(CarrierName)
  local cargos={}

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if CarrierName==nil or element.name==CarrierName then
      for _,_cargo in pairs(element.cargoBay) do
        local cargo=_cargo --#OPSGROUP.MyCargo
        if not cargo.reserved then
          table.insert(cargos, cargo.group)
        end
      end
    end
  end

  return cargos
end

--- Get cargo bay item.
-- @param #OPSGROUP self
-- @param #OPSGROUP CargoGroup Cargo group.
-- @return #OPSGROUP.MyCargo Cargo bay item or `nil` if the group is not in the carrier.
-- @return #number CargoBayIndex Index of item in the cargo bay table.
-- @return #OPSGROUP.Element Carrier element.
function OPSGROUP:_GetCargobay(CargoGroup)

  -- Loop over elements and their cargo bay items.
  local CarrierElement=nil  --#OPSGROUP.Element
  local cargobayIndex=nil
  local reserved=nil
  for i,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    for j,_cargo in pairs(element.cargoBay) do
      local cargo=_cargo --#OPSGROUP.MyCargo
      if cargo.group and cargo.group.groupname==CargoGroup.groupname then
        return cargo, j, element
      end
    end
  end

  return nil, nil, nil
end

--- Remove OPSGROUP from cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element Element Cargo group.
-- @param #number CargoUID Cargo UID.
-- @return #OPSGROUP.MyCargo MyCargo My cargo data.
function OPSGROUP:_GetCargobayElement(Element, CargoUID)
  self:T3({Element=Element, CargoUID=CargoUID})

  for i,_mycargo in pairs(Element.cargoBay) do
    local mycargo=_mycargo --#OPSGROUP.MyCargo

    if mycargo.cargoUID and mycargo.cargoUID==CargoUID then
      return mycargo
    end
    
  end

  return nil
end

--- Remove OPSGROUP from cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element Element Cargo group.
-- @param #OPSGROUP.MyCargo MyCargo My cargo data.
-- @return #boolean If `true`, cargo could be removed.
function OPSGROUP:_DelCargobayElement(Element, MyCargo)

  for i,_mycargo in pairs(Element.cargoBay) do
    local mycargo=_mycargo --#OPSGROUP.MyCargo
    
    if mycargo.cargoUID and MyCargo.cargoUID and mycargo.cargoUID==MyCargo.cargoUID then
      if MyCargo.group then
        self:RedWeightCargo(Element.name, MyCargo.group:GetWeightTotal())
      else
        self:RedWeightCargo(Element.name, MyCargo.storageAmount*MyCargo.storageWeight)
      end
      table.remove(Element.cargoBay, i)
      return true
    end
    
  end

  return false
end

--- Remove OPSGROUP from cargo bay of a carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP CargoGroup Cargo group.
-- @return #boolean If `true`, cargo could be removed.
function OPSGROUP:_DelCargobay(CargoGroup)

  if self.cargoBay[CargoGroup.groupname] then

    -- Not in cargo bay any more.
    self.cargoBay[CargoGroup.groupname]=nil

  end

  -- Get cargo bay info.
  local cargoBayItem, cargoBayIndex, CarrierElement=self:_GetCargobay(CargoGroup)

  if cargoBayItem and cargoBayIndex then

    -- Debug info.
    self:T(self.lid..string.format("Removing cargo group %s from cargo bay (index=%d) of carrier %s", CargoGroup:GetName(), cargoBayIndex, CarrierElement.name))

    -- Remove
    table.remove(CarrierElement.cargoBay, cargoBayIndex)

    -- Reduce weight (if cargo space was not just reserved).
    if not cargoBayItem.reserved then
      local weight=CargoGroup:GetWeightTotal()
      self:RedWeightCargo(CarrierElement.name, weight)
    end

    return true
  end

  self:T(self.lid.."ERROR: Group is not in cargo bay. Cannot remove it!")
  return false
end

--- Get cargo transport from cargo queue.
-- @param #OPSGROUP self
-- @return Ops.OpsTransport#OPSTRANSPORT The next due cargo transport or `nil`.
function OPSGROUP:_GetNextCargoTransport()

  -- Current position.
  local coord=self:GetCoordinate()

  -- Sort results table wrt prio and distance to pickup zone.
  local function _sort(a, b)
    local transportA=a --Ops.OpsTransport#OPSTRANSPORT
    local transportB=b --Ops.OpsTransport#OPSTRANSPORT
    --TODO: Include distance
    --local distA=transportA.pickupzone:GetCoordinate():Get2DDistance(coord)
    --local distB=transportB.pickupzone:GetCoordinate():Get2DDistance(coord)
    return (transportA.prio<transportB.prio) --or (transportA.prio==transportB.prio and distA<distB)
  end
  table.sort(self.cargoqueue, _sort)

  -- TODO: Find smarter next transport.

  -- Importance.
  local vip=math.huge
  for _,_cargotransport in pairs(self.cargoqueue) do
    local cargotransport=_cargotransport --Ops.OpsTransport#OPSTRANSPORT
    if cargotransport.importance and cargotransport.importance<vip then
      vip=cargotransport.importance
    end
  end

  -- Find next transport assignment.
  for _,_cargotransport in pairs(self.cargoqueue) do
    local cargotransport=_cargotransport --Ops.OpsTransport#OPSTRANSPORT

    local carrierstatusScheduled=cargotransport:GetCarrierTransportStatus(self)==OPSTRANSPORT.Status.SCHEDULED

    if cargotransport:IsReadyToGo() and carrierstatusScheduled and (cargotransport.importance==nil or cargotransport.importance<=vip) and not self:_CheckDelivered(cargotransport) then
      cargotransport:Executing()
      cargotransport:SetCarrierTransportStatus(self, OPSTRANSPORT.Status.EXECUTING)
      return cargotransport
    end

  end

  return nil
end

--- Check if all cargo of this transport assignment was delivered.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT CargoTransport The next due cargo transport or `nil`.
-- @return #boolean If true, all cargo was delivered.
function OPSGROUP:_CheckDelivered(CargoTransport)

  local done=true
  for _,_cargo in pairs(CargoTransport:GetCargos()) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup

    if self:CanCargo(cargo) then

      if cargo.delivered then
        -- This one is delivered.
      elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup==nil then
       
      elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and (cargo.opsgroup:IsDead() or cargo.opsgroup:IsStopped()) then
        -- This one is dead.
      else
        done=false --Someone is not done!
      end
      
    end

  end

  -- Debug info.
  self:T(self.lid..string.format("Cargotransport UID=%d Status=%s: delivered=%s", CargoTransport.uid, CargoTransport:GetState(), tostring(done)))

  return done
end


--- Check if all cargo of this transport assignment was delivered.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT CargoTransport The next due cargo transport or `nil`.
-- @return #boolean If true, all cargo was delivered.
function OPSGROUP:_CheckGoPickup(CargoTransport)

  local done=true

  if CargoTransport then

    for _,_cargo in pairs(CargoTransport:GetCargos()) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup

      if self:CanCargo(cargo) then

        if cargo.delivered then
          -- This one is delivered.
        elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and (cargo.opsgroup==nil or cargo.opsgroup:IsDead() or cargo.opsgroup:IsStopped()) then
          -- This one is dead.
        elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and (cargo.opsgroup:IsLoaded(CargoTransport:_GetCarrierNames())) then
          -- This one is loaded into a(nother) carrier.
        else
          done=false --Someone is not done!
        end

      end

    end

    -- Debug info.
    self:T(self.lid..string.format("Cargotransport UID=%d Status=%s: delivered=%s", CargoTransport.uid, CargoTransport:GetState(), tostring(done)))

  end

  return done
end

--- Create a cargo transport assignment.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT OpsTransport The troop transport assignment.
-- @return #OPSGROUP self
function OPSGROUP:AddOpsTransport(OpsTransport)

  -- Scheduled.
  OpsTransport:Scheduled()

  -- Add this group as carrier for the transport.
  OpsTransport:_AddCarrier(self)

  --Add to cargo queue
  table.insert(self.cargoqueue, OpsTransport)

  -- Debug message.
  self:T(self.lid.."Adding transport to carrier, #self.cargoqueue="..#self.cargoqueue)

  return self
end

--- Delete a cargo transport assignment from the cargo queue.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT CargoTransport Cargo transport do be deleted.
-- @return #OPSGROUP self
function OPSGROUP:DelOpsTransport(CargoTransport)

  for i=#self.cargoqueue,1,-1 do
    local transport=self.cargoqueue[i] --Ops.OpsTransport#OPSTRANSPORT
    if transport.uid==CargoTransport.uid then

      -- Debug info.
      self:T(self.lid..string.format("Removing transport UID=%d", transport.uid))

      -- Remove from queue.
      table.remove(self.cargoqueue, i)

      -- Remove carrier from ops transport.
      CargoTransport:_DelCarrier(self)

      return self
    end
  end

  return self
end

--- Get cargo transport assignment from the cargo queue by its unique ID.
-- @param #OPSGROUP self
-- @param #number uid Unique ID of the transport
-- @return Ops.OpsTransport#OPSTRANSPORT Transport.
function OPSGROUP:GetOpsTransportByUID(uid)

  for i=#self.cargoqueue,1,-1 do
    local transport=self.cargoqueue[i] --Ops.OpsTransport#OPSTRANSPORT
    if transport.uid==uid then
      return transport
    end
  end

  return nil
end


--- Get total weight of the group including cargo. Optionally, the total weight of a specific unit can be requested.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @param #boolean IncludeReserved If `false`, cargo weight that is only *reserved* is **not** counted. By default (`true` or `nil`), the reserved cargo is included.
-- @return #number Total weight in kg.
function OPSGROUP:GetWeightTotal(UnitName, IncludeReserved)

  local weight=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if (UnitName==nil or UnitName==element.name) and element.status~=OPSGROUP.ElementStatus.DEAD then

      weight=weight+element.weightEmpty

      for _,_cargo in pairs(element.cargoBay) do
        local cargo=_cargo --#OPSGROUP.MyCargo

        local wcargo=0

        -- Count cargo that is not reserved or if reserved cargo should be included.
        if (not cargo.reserved) or (cargo.reserved==true and (IncludeReserved==true or IncludeReserved==nil)) then
          wcargo=cargo.group:GetWeightTotal(element.name)
        end

        weight=weight+wcargo

      end

    end

  end

  return weight
end

--- Get free cargo bay weight.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @param #boolean IncludeReserved If `false`, cargo weight that is only *reserved* is **not** counted. By default (`true` or `nil`), the reserved cargo is included.
-- @return #number Free cargo bay in kg.
function OPSGROUP:GetFreeCargobay(UnitName, IncludeReserved)

  -- Max cargo weight.
  local weightCargoMax=self:GetWeightCargoMax(UnitName)

  -- Current cargo weight.
  local weightCargo=self:GetWeightCargo(UnitName, IncludeReserved)

  -- Free cargo.
  local Free=weightCargoMax-weightCargo

  -- Debug info.
  self:T(self.lid..string.format("Free cargo bay=%d kg (unit=%s)", Free, (UnitName or "whole group")))

  return Free
end

--- Get relative free cargo bay in percent.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @param #boolean IncludeReserved If `false`, cargo weight that is only *reserved* is **not** counted. By default (`true` or `nil`), the reserved cargo is included.
-- @return #number Free cargo bay in percent.
function OPSGROUP:GetFreeCargobayRelative(UnitName, IncludeReserved)

  local free=self:GetFreeCargobay(UnitName, IncludeReserved)

  local total=self:GetWeightCargoMax(UnitName)

  local percent=free/total*100

  return percent
end

--- Get relative used (loaded) cargo bay in percent.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @param #boolean IncludeReserved If `false`, cargo weight that is only *reserved* is **not** counted. By default (`true` or `nil`), the reserved cargo is included.
-- @return #number Used cargo bay in percent.
function OPSGROUP:GetUsedCargobayRelative(UnitName, IncludeReserved)
  local free=self:GetFreeCargobayRelative(UnitName, IncludeReserved)
  return 100-free
end

--- Get max weight of cargo (group) this group can load. This is the largest free cargo bay of any (not dead) element of the group.
-- Optionally, you can calculate the current max weight possible, which accounts for currently loaded cargo.
-- @param #OPSGROUP self
-- @param #boolean Currently If true, calculate the max weight currently possible in case there is already cargo loaded.
-- @return #number Max weight in kg.
function OPSGROUP:GetFreeCargobayMax(Currently)

  local maxweight=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if element.status~=OPSGROUP.ElementStatus.DEAD then

      local weight=element.weightMaxCargo

      if Currently then
        weight=weight-element.weightCargo
      end

      -- Check if this element can load more.
      if weight>maxweight then
        maxweight=weight
      end

    end
  end

  return maxweight
end


--- Get weight of the internal cargo the group is carriing right now.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @param #boolean IncludeReserved If `false`, cargo weight that is only *reserved* is **not** counted. By default (`true` or `nil`), the reserved cargo is included.
-- @return #number Cargo weight in kg.
function OPSGROUP:GetWeightCargo(UnitName, IncludeReserved)

  -- Calculate weight based on actual cargo weight.
  local weight=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if (UnitName==nil or UnitName==element.name) and element.status~=OPSGROUP.ElementStatus.DEAD then

      weight=weight+element.weightCargo or 0

    end

  end

  -- Calculate weight from stuff in cargo bay. By default this includes the reserved weight if a cargo group was assigned and is currently boarding.
  local gewicht=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if (UnitName==nil or UnitName==element.name) and (element and element.status~=OPSGROUP.ElementStatus.DEAD) then
      for _,_cargo in pairs(element.cargoBay) do
        local cargo=_cargo --#OPSGROUP.MyCargo
        if (not cargo.reserved) or (cargo.reserved==true and (IncludeReserved==true or IncludeReserved==nil)) then
          if cargo.group then
            gewicht=gewicht+cargo.group:GetWeightTotal()
          else
            gewicht=gewicht+cargo.storageAmount*cargo.storageWeight
          end
          --self:I(self.lid..string.format("unit=%s (reserved=%s): cargo=%s weight=%d, total weight=%d", tostring(UnitName), tostring(IncludeReserved), cargo.group:GetName(), cargoweight, weight))
        end
      end
    end
  end

  -- Debug info.
  self:T3(self.lid..string.format("Unit=%s (reserved=%s): weight=%d, gewicht=%d", tostring(UnitName), tostring(IncludeReserved), weight, gewicht))

  -- Quick check.
  if IncludeReserved==false and gewicht~=weight then
    self:T(self.lid..string.format("ERROR: FF weight!=gewicht: weight=%.1f, gewicht=%.1f", weight, gewicht))
  end

  return gewicht
end

--- Get max weight of the internal cargo the group can carry. Optionally, the max cargo weight of a specific unit can be requested.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @return #number Max cargo weight in kg. This does **not** include any cargo loaded or reserved currently.
function OPSGROUP:GetWeightCargoMax(UnitName)

  local weight=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if (UnitName==nil or UnitName==element.name) and element.status~=OPSGROUP.ElementStatus.DEAD then

      weight=weight+element.weightMaxCargo

    end

  end

  return weight
end

--- Get OPSGROUPs in the cargo bay.
-- @param #OPSGROUP self
-- @return #table Cargo OPSGROUPs.
function OPSGROUP:GetCargoOpsGroups()

  local opsgroups={}
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    for _,_cargo in pairs(element.cargoBay) do
      local cargo=_cargo --#OPSGROUP.MyCargo
      table.insert(opsgroups, cargo.group)
    end
  end

  return opsgroups
end

--- Add weight to the internal cargo of an element of the group.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit. Default is of the whole group.
-- @param #number Weight Cargo weight to be added in kg.
function OPSGROUP:AddWeightCargo(UnitName, Weight)

  local element=self:GetElementByName(UnitName)

  if element then --we do not check if the element is actually alive because we need to remove cargo from dead units

    -- Add weight.
    element.weightCargo=element.weightCargo+Weight

    -- Debug info.
    self:T(self.lid..string.format("%s: Adding %.1f kg cargo weight. New cargo weight=%.1f kg", UnitName, Weight, element.weightCargo))

    -- For airborne units, we set the weight in game.
    if self.isFlightgroup and element.unit and element.unit:IsAlive() then -- #2272 trying to deduct cargo weight from possibly dead units
      trigger.action.setUnitInternalCargo(element.name, element.weightCargo)  --https://wiki.hoggitworld.com/view/DCS_func_setUnitInternalCargo
    end

  end

  return self
end

--- Reduce weight to the internal cargo of an element of the group.
-- @param #OPSGROUP self
-- @param #string UnitName Name of the unit.
-- @param #number Weight Cargo weight to be reduced in kg.
function OPSGROUP:RedWeightCargo(UnitName, Weight)

  -- Reduce weight by adding negative weight.
  self:AddWeightCargo(UnitName, -Weight)

  return self
end

--- Get weight of warehouse storage to transport.
-- @param #OPSGROUP self
-- @param Ops.OpsTransport#OPSTRANSPORT.Storage Storage
-- @param #boolean Total Get total weight. Otherweise the amount left to deliver (total-loaded-lost-delivered).
-- @param #boolean Reserved Reduce weight that is reserved.
-- @param #boolean Amount Return amount not weight.
-- @return #number Weight of cargo in kg or amount in number of items, if `Amount=true`.
function OPSGROUP:_GetWeightStorage(Storage, Total, Reserved, Amount)

  local weight=Storage.cargoAmount
  
  if not Total then
    weight=weight-Storage.cargoLost-Storage.cargoLoaded-Storage.cargoDelivered
  end
  
  if Reserved then
    weight=weight-Storage.cargoReserved
  end
  
  if not Amount then
    weight=weight*Storage.cargoWeight
  end

  return weight
end

--- Check if the group can *in principle* be carrier of a cargo group. This checks the max cargo capacity of the group but *not* how much cargo is already loaded (if any).
-- **Note** that the cargo group *cannot* be split into units, i.e. the largest cargo bay of any element of the group must be able to load the whole cargo group in one piece.
-- @param #OPSGROUP self
-- @param Ops.OpsGroup#OPSGROUP.CargoGroup Cargo Cargo data, which needs a carrier.
-- @return #boolean If `true`, there is an element of the group that can load the whole cargo group.
function OPSGROUP:CanCargo(Cargo)

  if Cargo then
  
    local weight=math.huge
    
    if Cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then

      local weight=Cargo.opsgroup:GetWeightTotal()      

      for _,_element in pairs(self.elements) do
        local element=_element --#OPSGROUP.Element
  
        -- Check that element is not dead and has
        if element and element.status~=OPSGROUP.ElementStatus.DEAD and element.weightMaxCargo>=weight then
          return true
        end
      end


    else
    
      ---
      -- STORAGE
      ---
    
      -- Since storage cargo can be devided onto multiple carriers, we take the weight of a single cargo item (even 1 kg of fuel).
      weight=Cargo.storage.cargoWeight
      
    end
    
    -- Calculate cargo bay space.
    local bay=0
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element

      -- Check that element is not dead and has
      if element and element.status~=OPSGROUP.ElementStatus.DEAD then
        bay=bay+element.weightMaxCargo
      end
      
    end
    
    -- Check if cargo fits into cargo bay(s) of carrier group.
    if bay>=weight then
      return true
    end


  end

  return false
end

--- Find carrier for cargo by evaluating the free cargo bay storage.
-- @param #OPSGROUP self
-- @param #number Weight Weight of cargo in kg.
-- @return #OPSGROUP.Element Carrier able to transport the cargo.
function OPSGROUP:FindCarrierForCargo(Weight)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    local free=self:GetFreeCargobay(element.name)

    if free>=Weight then
      return element
    else
      self:T3(self.lid..string.format("%s: Weight %d>%d free cargo bay", element.name, Weight, free))
    end

  end

  return nil
end

--- Set my carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP CarrierGroup Carrier group.
-- @param #OPSGROUP.Element CarrierElement Carrier element.
-- @param #boolean Reserved If `true`, reserve space for me.
function OPSGROUP:_SetMyCarrier(CarrierGroup, CarrierElement, Reserved)

  -- Debug info.
  self:T(self.lid..string.format("Setting My Carrier: %s (%s), reserved=%s", CarrierGroup:GetName(), tostring(CarrierElement.name), tostring(Reserved)))

  self.mycarrier.group=CarrierGroup
  self.mycarrier.element=CarrierElement
  self.mycarrier.reserved=Reserved

  self.cargoTransportUID=CarrierGroup.cargoTransport and CarrierGroup.cargoTransport.uid or nil

end

--- Get my carrier group.
-- @param #OPSGROUP self
-- @return #OPSGROUP Carrier group.
function OPSGROUP:_GetMyCarrierGroup()
  if self.mycarrier and self.mycarrier.group then
    return self.mycarrier.group
  end
  return nil
end

--- Get my carrier element.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Element Carrier element.
function OPSGROUP:_GetMyCarrierElement()
  if self.mycarrier and self.mycarrier.element then
    return self.mycarrier.element
  end
  return nil
end

--- Is my carrier reserved.
-- @param #OPSGROUP self
-- @return #boolean If `true`, space for me was reserved.
function OPSGROUP:_IsMyCarrierReserved()
  if self.mycarrier then
    return self.mycarrier.reserved
  end
  return nil
end



--- Get my carrier.
-- @param #OPSGROUP self
-- @return #OPSGROUP Carrier group.
-- @return #OPSGROUP.Element Carrier element.
-- @return #boolean If `true`, space is reserved for me
function OPSGROUP:_GetMyCarrier()
  return self.mycarrier.group, self.mycarrier.element, self.mycarrier.reserved
end


--- Remove my carrier.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:_RemoveMyCarrier()
  self:T(self.lid..string.format("Removing my carrier!"))
  self.mycarrier.group=nil
  self.mycarrier.element=nil
  self.mycarrier.reserved=nil
  self.mycarrier={}
  self.cargoTransportUID=nil
  return self
end

--- On after "Pickup" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterPickup(From, Event, To)

  -- Old status.
  local oldstatus=self.carrierStatus

  -- Set carrier status.
  self:_NewCarrierStatus(OPSGROUP.CarrierStatus.PICKUP)

  local TZC=self.cargoTZC

  -- Pickup zone.
  local Zone=TZC.PickupZone

  -- Check if already in the pickup zone.
  local inzone=self:IsInZone(Zone)

  -- Pickup at an airbase.
  local airbasePickup=TZC.PickupAirbase --Wrapper.Airbase#AIRBASE

  -- Check if group is already ready for loading.
  local ready4loading=false
  if self:IsArmygroup() or self:IsNavygroup() then

    -- Army and Navy groups just need to be inside the zone.
    ready4loading=inzone

  else

    -- Aircraft is already parking at the pickup airbase.
    ready4loading=self.currbase and airbasePickup and self.currbase:GetName()==airbasePickup:GetName() and self:IsParking()

    -- If a helo is landed in the zone, we also are ready for loading.
    if ready4loading==false and self.isHelo and self:IsLandedAt() and inzone then
      ready4loading=true
    end
  end

  -- Ready for loading?
  if ready4loading then

    -- We are already in the pickup zone ==> wait and initiate loading.
    if (self:IsArmygroup() or self:IsNavygroup()) and not self:IsHolding() then
      self:FullStop()
    end

    -- Start loading.
    self:__Loading(-5)

  else

    -- Set surface type of random coordinate.
    local surfacetypes=nil
    if self:IsArmygroup() or self:IsFlightgroup() then
      surfacetypes={land.SurfaceType.LAND}
    elseif self:IsNavygroup() then
      surfacetypes={land.SurfaceType.WATER}
    end

    -- Get a random coordinate in the pickup zone and let the carrier go there.
    local Coordinate=Zone:GetRandomCoordinate(nil, nil, surfacetypes)

    -- Current waypoint ID.
    local uid=self:GetWaypointCurrentUID()

    -- Add waypoint.
    if self:IsFlightgroup() then

      ---
      -- Flight Group
      ---

      -- Activate uncontrolled group.
      if self:IsParking() and self:IsUncontrolled() then
        self:StartUncontrolled()
      end

      if airbasePickup then

        ---
        -- Pickup at airbase
        ---

        -- Get a (random) pre-defined transport path.
        local path=self.cargoTransport:_GetPathTransport(self.category, self.cargoTZC)

        -- Get transport path.
        if path and oldstatus~=OPSGROUP.CarrierStatus.NOTCARRIER then

          for i=#path.waypoints,1,-1 do
            local wp=path.waypoints[i]
            local coordinate=COORDINATE:NewFromWaypoint(wp)
            local waypoint=FLIGHTGROUP.AddWaypoint(self, coordinate, nil, uid, nil, false) ; waypoint.temp=true
            uid=waypoint.uid
            if i==1 then
              waypoint.temp=false
              waypoint.detour=1 --Needs to trigger the landatairbase function.
            end
          end

        else

          local coordinate=self:GetCoordinate():GetIntermediateCoordinate(Coordinate, 0.5)

          -- If this is a helo and no ZONE_AIRBASE was given, we make the helo land in the pickup zone.
          local waypoint=FLIGHTGROUP.AddWaypoint(self, coordinate, nil, uid, UTILS.MetersToFeet(self.altitudeCruise), true) ; waypoint.detour=1

        end

      elseif self.isHelo then

        ---
        -- Helo can also land in a zone (NOTE: currently VTOL cannot!)
        ---

        -- If this is a helo and no ZONE_AIRBASE was given, we make the helo land in the pickup zone.
        local waypoint=FLIGHTGROUP.AddWaypoint(self, Coordinate, nil, uid, UTILS.MetersToFeet(self.altitudeCruise), false) ; waypoint.detour=1

      else
        self:T(self.lid.."ERROR: Transportcarrier aircraft cannot land in Pickup zone! Specify a ZONE_AIRBASE as pickup zone")
      end

      -- Cancel landedAt task. This should trigger Cruise once airborne.
      if self.isHelo and self:IsLandedAt() then
        local Task=self:GetTaskCurrent()
        if Task then
          self:TaskCancel(Task)
        else
          self:T(self.lid.."ERROR: No current task but landed at?!")
        end
      end

      if self:IsWaiting() then
        self:__Cruise(-2)
      end

    elseif self:IsNavygroup() then

      ---
      -- Navy Group
      ---

      -- Get a (random) pre-defined transport path.
      local path=self.cargoTransport:_GetPathTransport(self.category, self.cargoTZC)

      -- Get transport path.
      if path then --and oldstatus~=OPSGROUP.CarrierStatus.NOTCARRIER then
        for i=#path.waypoints,1,-1 do
          local wp=path.waypoints[i]
          local coordinate=COORDINATE:NewFromWaypoint(wp)
          local waypoint=NAVYGROUP.AddWaypoint(self, coordinate, nil, uid, nil, false) ; waypoint.temp=true
          uid=waypoint.uid
        end
      end

      -- NAVYGROUP
      local waypoint=NAVYGROUP.AddWaypoint(self, Coordinate, nil, uid, self.altitudeCruise, false) ; waypoint.detour=1

      -- Give cruise command.
      self:__Cruise(-2)


    elseif self:IsArmygroup() then

      ---
      -- Army Group
      ---

      -- Get a (random) pre-defined transport path.
      local path=self.cargoTransport:_GetPathTransport(self.category, self.cargoTZC)

      -- Formation used to go to the pickup zone..
      local Formation=self.cargoTransport:_GetFormationPickup(self.cargoTZC, self)
            
      -- Get transport path.
      if path and oldstatus~=OPSGROUP.CarrierStatus.NOTCARRIER then
        for i=#path.waypoints,1,-1 do
          local wp=path.waypoints[i]
          local coordinate=COORDINATE:NewFromWaypoint(wp)
          local waypoint=ARMYGROUP.AddWaypoint(self, coordinate, nil, uid, wp.action, false) ; waypoint.temp=true
          uid=waypoint.uid
        end
      end

      -- ARMYGROUP
      local waypoint=ARMYGROUP.AddWaypoint(self, Coordinate, nil, uid, Formation, false) ; waypoint.detour=1

      -- Give cruise command.
      self:__Cruise(-2, nil, Formation)

    end

  end

end

--- On after "Loading" event.
-- @param #OPSGROUP self
-- @param #table Cargos Table of cargos.
-- @return #table Table of sorted cargos.
function OPSGROUP:_SortCargo(Cargos)

  -- Sort results table wrt descending weight.
  local function _sort(a, b)
    local cargoA=a --Ops.OpsGroup#OPSGROUP.CargoGroup
    local cargoB=b --Ops.OpsGroup#OPSGROUP.CargoGroup
    local weightA=0
    local weightB=0
    if cargoA.opsgroup then
      weightA=cargoA.opsgroup:GetWeightTotal()
    else
      weightA=self:_GetWeightStorage(cargoA.storage)
    end
    if cargoB.opsgroup then
      weightB=cargoB.opsgroup:GetWeightTotal()
    else
      weightB=self:_GetWeightStorage(cargoB.storage)
    end
    return weightA>weightB
  end
  
  table.sort(Cargos, _sort)

  return Cargos
end


--- On after "Loading" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLoading(From, Event, To)

  -- Set carrier status.
  self:_NewCarrierStatus(OPSGROUP.CarrierStatus.LOADING)

  -- Get valid cargos of the TZC.
  local cargos={}
  for _,_cargo in pairs(self.cargoTZC.Cargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    
    -- Check if this group can carry the cargo.
    local canCargo=self:CanCargo(cargo)

    -- Check if this group is currently acting as carrier.
    local isCarrier=false
    
    
    -- Check if cargo is not already cargo.
    local isNotCargo=true 
    
    -- Check if cargo is holding or loaded
    local isHolding=cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and (cargo.opsgroup:IsHolding() or cargo.opsgroup:IsLoaded()) or true
    
    -- Check if cargo is in embark/pickup zone.
    -- Added InUtero here, if embark zone is moving (ship) and cargo has been spawned late activated and its position is not updated. Not sure if that breaks something else!
    local inZone=cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and (cargo.opsgroup:IsInZone(self.cargoTZC.EmbarkZone) or cargo.opsgroup:IsInUtero()) or true
    
    -- Check if cargo is currently on a mission.
    local isOnMission=cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup:IsOnMission() or false
    
    -- Check if current mission is using this ops transport.
    if isOnMission then
      local mission=cargo.opsgroup:GetMissionCurrent()
      if mission and ((mission.opstransport and mission.opstransport.uid==self.cargoTransport.uid) or mission.type==AUFTRAG.Type.NOTHING) then  
        isOnMission=not isHolding
      end
    end
    
    local isAvail=true
    if cargo.type==OPSTRANSPORT.CargoType.STORAGE then
      local nAvail=cargo.storage.storageFrom:GetAmount(cargo.storage.cargoType)
      if nAvail>0 then
        isAvail=true
      else
        isAvail=false
      end
    else
      isCarrier=cargo.opsgroup:IsPickingup() or cargo.opsgroup:IsLoading() or cargo.opsgroup:IsTransporting() or cargo.opsgroup:IsUnloading()
      isNotCargo=cargo.opsgroup:IsNotCargo(true)
    end
    
    local isDead=cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup:IsDead() or false
    
    -- Debug message.
    self:T(self.lid..string.format("Loading: canCargo=%s, isCarrier=%s, isNotCargo=%s, isHolding=%s, isOnMission=%s",
    tostring(canCargo), tostring(isCarrier), tostring(isNotCargo), tostring(isHolding), tostring(isOnMission)))    

    -- TODO: Need a better :IsBusy() function or :IsReadyForMission() :IsReadyForBoarding() :IsReadyForTransport()
    if canCargo and inZone and isNotCargo and isHolding and isAvail and (not (cargo.delivered or isDead or isCarrier or isOnMission)) then
      table.insert(cargos, cargo)
    end
  end

  -- Sort cargos.
  self:_SortCargo(cargos)

  -- Loop over all cargos.
  for _,_cargo in pairs(cargos) do
    local cargo=_cargo --#OPSGROUP.CargoGroup
    
    local weight=nil
    if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then
    
      -- Get total weight of group.
      weight=cargo.opsgroup:GetWeightTotal()
 
       -- Find a carrier for this cargo.
      local carrier=self:FindCarrierForCargo(weight)
  
      -- Order cargo group to board the carrier.
      if carrier then          
        cargo.opsgroup:Board(self, carrier)        
      end
      
    else
    
      ---
      -- STORAGE
      ---

      -- Get weight of cargo that needs to be transported.
      weight=self:_GetWeightStorage(cargo.storage, false)

      -- Get amount that the warehouse currently has.
      local Amount=cargo.storage.storageFrom:GetAmount(cargo.storage.cargoType)
      local Weight=Amount*cargo.storage.cargoWeight
      
      -- Make sure, we do not take more than the warehouse can provide.
      weight=math.min(weight, Weight)
            
      -- Debug info.
      self:T(self.lid..string.format("Loading storage weight=%d kg (warehouse has %d kg)!", weight, Weight))
      
      -- Loop over all elements of the carrier group.
      for _,_element in pairs(self.elements) do
        local element=_element --#OPSGROUP.Element
    
        -- Get the free cargo space of the carrier.
        local free=self:GetFreeCargobay(element.name)
        
        -- Min of weight or bay.
        local w=math.min(weight, free)
        
        -- Check that weight is >0 and also greater that at least one item. We cannot transport half a missile.
        if w>=cargo.storage.cargoWeight then
    
          -- Calculate item amount.
          local amount=math.floor(w/cargo.storage.cargoWeight)
          
          -- Remove items from warehouse.
          cargo.storage.storageFrom:RemoveAmount(cargo.storage.cargoType, amount)
          
          -- Add amount to loaded cargo.
          cargo.storage.cargoLoaded=cargo.storage.cargoLoaded+amount
  
          -- Add cargo to cargo by of element.        
          self:_AddCargobayStorage(element, cargo.uid, cargo.storage.cargoType, amount, cargo.storage.cargoWeight)
                 
          -- Reduce weight for the next element (if any).
          weight=weight-amount*cargo.storage.cargoWeight
          
          -- Debug info.
          local text=string.format("Element %s: loaded amount=%d (weight=%d) ==> left=%d kg", element.name, amount, amount*cargo.storage.cargoWeight, weight)
          self:T(self.lid..text)
          
          -- If no cargo left, break the loop.
          if weight<=0 then
            break
          end
          
        end
        
      end
      
    end    
  end
  
end

--- Set (new) cargo status.
-- @param #OPSGROUP self
-- @param #string Status New status.
function OPSGROUP:_NewCargoStatus(Status)

  -- Debug info.
  if self.verbose>=2 then
    self:I(self.lid..string.format("New cargo status: %s --> %s", tostring(self.cargoStatus), tostring(Status)))
  end

  -- Set cargo status.
  self.cargoStatus=Status

end

--- Set (new) carrier status.
-- @param #OPSGROUP self
-- @param #string Status New status.
function OPSGROUP:_NewCarrierStatus(Status)

  -- Debug info.
  if self.verbose>=2 then
    self:I(self.lid..string.format("New carrier status: %s --> %s", tostring(self.carrierStatus), tostring(Status)))
  end

  -- Set cargo status.
  self.carrierStatus=Status

end

--- Transfer cargo from to another carrier.
-- @param #OPSGROUP self
-- @param #OPSGROUP CargoGroup The cargo group to be transferred.
-- @param #OPSGROUP CarrierGroup The new carrier group.
-- @param #OPSGROUP.Element CarrierElement The new carrier element.
function OPSGROUP:_TransferCargo(CargoGroup, CarrierGroup, CarrierElement)

  -- Debug info.
  self:T(self.lid..string.format("Transferring cargo %s to new carrier group %s", CargoGroup:GetName(), CarrierGroup:GetName()))

  -- Unload from this and directly load into the other carrier.
  self:Unload(CargoGroup)
  CarrierGroup:Load(CargoGroup, CarrierElement)

end

--- On after "Load" event. Carrier loads a cargo group into ints cargo bay.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP CargoGroup The OPSGROUP loaded as cargo.
-- @param #OPSGROUP.Element Carrier The carrier element/unit.
function OPSGROUP:onafterLoad(From, Event, To, CargoGroup, Carrier)

  -- Debug info.
  self:T(self.lid..string.format("Loading group %s", tostring(CargoGroup.groupname)))

  -- Carrier element.
  local carrier=Carrier or CargoGroup:_GetMyCarrierElement() --#OPSGROUP.Element

  -- No carrier provided.
  if not carrier then
    -- Get total weight of group.
    local weight=CargoGroup:GetWeightTotal()
    -- Try to find a carrier manually.
    carrier=self:FindCarrierForCargo(weight)
  end

  if carrier then

    ---
    -- Embark Cargo
    ---

    -- New cargo status.
    CargoGroup:_NewCargoStatus(OPSGROUP.CargoStatus.LOADED)

    -- Clear all waypoints.
    CargoGroup:ClearWaypoints()

    -- Add into carrier bay.
    self:_AddCargobay(CargoGroup, carrier, false)

    -- Despawn this group.
    if CargoGroup:IsAlive() then
      CargoGroup:Despawn(0, true)
    end

    -- Trigger embarked event for cargo group.
    CargoGroup:Embarked(self, carrier)

    -- Trigger Loaded event.
    self:Loaded(CargoGroup)

    -- Trigger "Loaded" event for current cargo transport.
    if self.cargoTransport then
      CargoGroup:_DelMyLift(self.cargoTransport)
      self.cargoTransport:Loaded(CargoGroup, self, carrier)
    else
      self:T(self.lid..string.format("WARNING: Loaded cargo but no current OPSTRANSPORT assignment!"))
    end

  else
    self:T(self.lid.."ERROR: Cargo has no carrier on Load event!")
  end

end

--- On after "LoadingDone" event. Carrier has loaded all (possible) cargo at the pickup zone.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterLoadingDone(From, Event, To)

  -- Debug info.
  self:T(self.lid.."Carrier Loading Done ==> Transport")

  -- Order group to transport.
  self:__Transport(1)

end

--- On before "Transport" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onbeforeTransport(From, Event, To)

  if self.cargoTransport==nil then
    return false
  elseif self.cargoTransport:IsDelivered() then --could be if all cargo was dead on boarding
    return false
  end

  return true
end


--- On after "Transport" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterTransport(From, Event, To)

  -- Set carrier status.
  self:_NewCarrierStatus(OPSGROUP.CarrierStatus.TRANSPORTING)

  --TODO: This is all very similar to the onafterPickup() function. Could make it general.

  -- Deploy zone.
  local Zone=self.cargoTZC.DeployZone

  -- Check if already in deploy zone.
  local inzone=self:IsInZone(Zone)

  -- Deploy airbase (if any).
  local airbaseDeploy=self.cargoTZC.DeployAirbase --Wrapper.Airbase#AIRBASE

  -- Check if group is already ready for loading.
  local ready2deploy=false
  if self:IsArmygroup() or self:IsNavygroup() then
    ready2deploy=inzone
  else
    -- Aircraft is already parking at the pickup airbase.
    ready2deploy=self.currbase and airbaseDeploy and self.currbase:GetName()==airbaseDeploy:GetName() and self:IsParking()

    -- If a helo is landed in the zone, we also are ready for loading.
    if ready2deploy==false and (self.isHelo or self.isVTOL) and self:IsLandedAt() and inzone then
      ready2deploy=true
    end
  end
  
  --env.info(string.format("FF Transport: Zone=%s inzone=%s, ready2deploy=%s", Zone:GetName(), tostring(inzone), tostring(ready2deploy)))

  if inzone then

    -- We are already in the deploy zone ==> wait and initiate unloading.
    if (self:IsArmygroup() or self:IsNavygroup()) and not self:IsHolding() then
      self:FullStop()
    end

    -- Start unloading.
    self:__Unloading(-5)

  else

    local surfacetypes=nil
    if self:IsArmygroup() or self:IsFlightgroup() then
      surfacetypes={land.SurfaceType.LAND}
    elseif self:IsNavygroup() then
      surfacetypes={land.SurfaceType.WATER, land.SurfaceType.SHALLOW_WATER}
    end

    -- Coord where the carrier goes to unload.
    local Coordinate=Zone:GetRandomCoordinate(nil, nil, surfacetypes) --Core.Point#COORDINATE

    -- Current waypoint UID.
    local uid=self:GetWaypointCurrentUID()

    -- Add waypoint.
    if self:IsFlightgroup() then

      -- Activate uncontrolled group.
      if self:IsParking() and self:IsUncontrolled() then
        self:StartUncontrolled()
      end

      if airbaseDeploy then

        ---
        -- Deploy at airbase
        ---

        -- Get a (random) pre-defined transport path.
        local path=self.cargoTransport:_GetPathTransport(self.category, self.cargoTZC)

        -- Get transport path.
        if path then

          for i=1, #path.waypoints do
            local wp=path.waypoints[i]
            local coordinate=COORDINATE:NewFromWaypoint(wp)
            local waypoint=FLIGHTGROUP.AddWaypoint(self, coordinate, nil, uid, nil, false) ; waypoint.temp=true
            uid=waypoint.uid
            if i==#path.waypoints then
              waypoint.temp=false
              waypoint.detour=1 --Needs to trigger the landatairbase function.
            end
          end

        else

          local coordinate=self:GetCoordinate():GetIntermediateCoordinate(Coordinate, 0.5)

          -- If this is a helo and no ZONE_AIRBASE was given, we make the helo land in the pickup zone.
          local waypoint=FLIGHTGROUP.AddWaypoint(self, coordinate, nil, uid, UTILS.MetersToFeet(self.altitudeCruise), true) ; waypoint.detour=1

        end

      elseif self.isHelo then

        ---
        -- Helo can also land in a zone
        ---

        -- If this is a helo and no ZONE_AIRBASE was given, we make the helo land in the pickup zone.
        local waypoint=FLIGHTGROUP.AddWaypoint(self, Coordinate, nil, uid, UTILS.MetersToFeet(self.altitudeCruise), false) ; waypoint.detour=1

      else
        self:T(self.lid.."ERROR: Aircraft (cargo carrier) cannot land in Deploy zone! Specify a ZONE_AIRBASE as deploy zone")
      end

      -- Cancel landedAt task. This should trigger Cruise once airborne.
      if self.isHelo and self:IsLandedAt() then
        local Task=self:GetTaskCurrent()
        if Task then
          self:TaskCancel(Task)
        else
          self:T(self.lid.."ERROR: No current task but landed at?!")
        end
      end
	  
      if self:IsWaiting() then
        self:__Cruise(-10)
      end	  

    elseif self:IsArmygroup() then

      -- Get transport path.
      local path=self.cargoTransport:_GetPathTransport(self.category, self.cargoTZC)

      -- Formation used for transporting.
      local Formation=self.cargoTransport:_GetFormationTransport(self.cargoTZC, self)

      -- Get transport path.
      if path then
        for i=1,#path.waypoints do
          local wp=path.waypoints[i]
          local coordinate=COORDINATE:NewFromWaypoint(wp)
          local waypoint=ARMYGROUP.AddWaypoint(self, coordinate, nil, uid, wp.action, false) ; waypoint.temp=true
          uid=waypoint.uid
        end
      end

      -- ARMYGROUP
      local waypoint=ARMYGROUP.AddWaypoint(self, Coordinate, nil, uid, Formation, false) ; waypoint.detour=1

      -- Give cruise command.
      self:Cruise(nil, Formation)

    elseif self:IsNavygroup() then

      -- Get a (random) pre-defined transport path.
      local path=self.cargoTransport:_GetPathTransport(self.category, self.cargoTZC)

      -- Get transport path.
      if path then
        for i=1,#path.waypoints do
          local wp=path.waypoints[i]
          local coordinate=COORDINATE:NewFromWaypoint(wp)
          local waypoint=NAVYGROUP.AddWaypoint(self, coordinate, nil, uid, nil, false) ; waypoint.temp=true
          uid=waypoint.uid
        end
      end

      -- NAVYGROUP
      local waypoint=NAVYGROUP.AddWaypoint(self, Coordinate, nil, uid, self.altitudeCruise, false) ; waypoint.detour=1

      -- Give cruise command.
      self:Cruise()

    end

  end

end

--- On after "Unloading" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterUnloading(From, Event, To)

  -- Set carrier status to UNLOADING.
  self:_NewCarrierStatus(OPSGROUP.CarrierStatus.UNLOADING)
  
  self:T(self.lid.."Unloading..")

  -- Deploy zone.
  local zone=self.cargoTZC.DisembarkZone or self.cargoTZC.DeployZone  --Core.Zone#ZONE

  for _,_cargo in pairs(self.cargoTZC.Cargos) do
    local cargo=_cargo --#OPSGROUP.CargoGroup
    
    if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then

      -- Check that cargo is loaded into this group.
      -- NOTE: Could be that the element carriing this cargo group is DEAD, which would mean that the cargo group is also DEAD.
      if cargo.opsgroup:IsLoaded(self.groupname) and not cargo.opsgroup:IsDead() then
  
        -- Disembark to carrier.
        local carrier=nil        --Ops.OpsGroup#OPSGROUP.Element
        local carrierGroup=nil   --Ops.OpsGroup#OPSGROUP
        local disembarkToCarriers=cargo.disembarkCarriers~=nil or self.cargoTZC.disembarkToCarriers
        
        -- Set specifc zone for this cargo.
        if cargo.disembarkZone then
          zone=cargo.disembarkZone
        end
        
        self:T(self.lid..string.format("Unloading cargo %s to zone %s", cargo.opsgroup:GetName(), zone and zone:GetName() or "No Zone Found!"))
  
        -- Try to get the OPSGROUP if deploy zone is a ship.
        if zone and zone:IsInstanceOf("ZONE_AIRBASE") and zone:GetAirbase():IsShip() then
          local shipname=zone:GetAirbase():GetName()
          local ship=UNIT:FindByName(shipname)
          local group=ship:GetGroup()
          carrierGroup=_DATABASE:GetOpsGroup(group:GetName())
          carrier=carrierGroup:GetElementByName(shipname)
        end
  
        if disembarkToCarriers then
        
          -- Debug info.
          self:T(self.lid..string.format("Trying to find disembark carriers in zone %s", zone:GetName()))
          
          -- Disembarkcarriers.
          local disembarkCarriers=cargo.disembarkCarriers or self.cargoTZC.DisembarkCarriers
  
          -- Try to find a carrier that can take the cargo.
          carrier, carrierGroup=self.cargoTransport:FindTransferCarrierForCargo(cargo.opsgroup, zone, disembarkCarriers, self.cargoTZC.DeployAirbase)
  
          --TODO: max unloading time if transfer carrier does not arrive in the zone.
  
        end
  
        if (disembarkToCarriers and carrier and carrierGroup) or (not disembarkToCarriers)  then
  
          -- Cargo was delivered (somehow).
          cargo.delivered=true
  
          -- Increase number of delivered cargos.
          self.cargoTransport.Ndelivered=self.cargoTransport.Ndelivered+1
  
          if carrier and carrierGroup then
  
            ---
            -- Delivered to another carrier group.
            ---
  
            self:_TransferCargo(cargo.opsgroup, carrierGroup, carrier)
  
          elseif zone and zone:IsInstanceOf("ZONE_AIRBASE") and zone:GetAirbase():IsShip() then
  
            ---
            -- Delivered to a ship via helo that landed on its platform
            ---
  
            -- Issue warning.
            self:T(self.lid.."ERROR: Deploy/disembark zone is a ZONE_AIRBASE of a ship! Where to put the cargo? Dumping into the sea, sorry!")
  
            -- Unload but keep "in utero" (no coordinate provided).
            self:Unload(cargo.opsgroup)
  
          else
  
            ---
            -- Delivered to deploy zone
            ---
  
            if self.cargoTransport:GetDisembarkInUtero(self.cargoTZC) then
  
              -- Unload but keep "in utero" (no coordinate provided).
              self:Unload(cargo.opsgroup)
  
            else
  
              -- Get disembark zone of this TZC.
              local DisembarkZone=cargo.disembarkZone or self.cargoTransport:GetDisembarkZone(self.cargoTZC)
  
              local Coordinate=nil
  
  
              if DisembarkZone then
  
                -- Random coordinate in disembark zone.
                Coordinate=DisembarkZone:GetRandomCoordinate()
  
              else
  
                local element=cargo.opsgroup:_GetMyCarrierElement()
  
                if element then
  
                  -- Get random point in disembark zone.
                  local zoneCarrier=self:GetElementZoneUnload(element.name)
  
                  -- Random coordinate/heading in the zone.
                  Coordinate=zoneCarrier:GetRandomCoordinate()
  
                else
                  self:E(self.lid..string.format("ERROR carrier element nil!"))
                end
  
              end
  
              -- Random heading of the group.
              local Heading=math.random(0,359)
  
              -- Activation on/off.
              local activation=self.cargoTransport:GetDisembarkActivation(self.cargoTZC)
              if cargo.disembarkActivation~=nil then
                activation=cargo.disembarkActivation
              end
  
              -- Unload to Coordinate.
              self:Unload(cargo.opsgroup, Coordinate, activation, Heading)
  
            end
  
            -- Trigger "Unloaded" event for current cargo transport
            self.cargoTransport:Unloaded(cargo.opsgroup, self)
  
          end
  
        else
          self:T(self.lid.."Cargo needs carrier but no carrier is avaiable (yet)!")
        end
  
      else
        -- Not loaded or dead
      end
      
    else
      
      ---
      -- STORAGE
      ---
      
      -- TODO: should proabaly move this check to the top to include OPSGROUPS as well?!
      if not cargo.delivered then
      
        for _,_element in pairs(self.elements) do
          local element=_element --#OPSGROUP.Element
          
          -- Get my cargo from cargo bay of element.
          local mycargo=self:_GetCargobayElement(element, cargo.uid)
          
          if mycargo then        
            -- Add cargo to warehouse storage.
            cargo.storage.storageTo:AddAmount(mycargo.storageType, mycargo.storageAmount)
        
            -- Add amount to delivered.    
            cargo.storage.cargoDelivered=cargo.storage.cargoDelivered+mycargo.storageAmount                    
            
            -- Reduce loaded amount.
            cargo.storage.cargoLoaded=cargo.storage.cargoLoaded-mycargo.storageAmount
            
            -- Remove cargo from bay.
            self:_DelCargobayElement(element, mycargo)
            
            -- Debug info
            self:T2(self.lid..string.format("Cargo loaded=%d, delivered=%d, lost=%d", cargo.storage.cargoLoaded, cargo.storage.cargoDelivered, cargo.storage.cargoLost))
            
          end      
        end
        
        -- Get amount that was delivered.
        local amountToDeliver=self:_GetWeightStorage(cargo.storage, false, false, true)
        
        -- Get total amount to be delivered.
        local amountTotal=self:_GetWeightStorage(cargo.storage, true, false, true)
        
        -- Debug info.
        local text=string.format("Amount delivered=%d, total=%d", amountToDeliver, amountTotal)
        self:T(self.lid..text)
        
        if amountToDeliver<=0 then
        
          -- Cargo was delivered (somehow).
          cargo.delivered=true
    
          -- Increase number of delivered cargos.
          self.cargoTransport.Ndelivered=self.cargoTransport.Ndelivered+1
  
          -- Debug info.
          local text=string.format("Ndelivered=%d delivered=%s", self.cargoTransport.Ndelivered, tostring(cargo.delivered))
          self:T(self.lid..text)
          
        end
      end
      
    end

  end -- loop over cargos

end

--- On before "Unload" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP OpsGroup The OPSGROUP loaded as cargo.
-- @param Core.Point#COORDINATE Coordinate Coordinate were the group is unloaded to.
-- @param #number Heading Heading of group.
function OPSGROUP:onbeforeUnload(From, Event, To, OpsGroup, Coordinate, Heading)

  -- Remove group from carrier bay. If group is not in cargo bay, function will return false and transition is denied.
  local removed=self:_DelCargobay(OpsGroup)

  return removed
end

--- On after "Unload" event. Carrier unloads a cargo group from its cargo bay.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP OpsGroup The OPSGROUP loaded as cargo.
-- @param Core.Point#COORDINATE Coordinate Coordinate were the group is unloaded to.
-- @param #boolean Activated If `true`, group is active. If `false`, group is spawned in late activated state.
-- @param #number Heading (Optional) Heading of group in degrees. Default is random heading for each unit.
function OPSGROUP:onafterUnload(From, Event, To, OpsGroup, Coordinate, Activated, Heading)

  -- New cargo status.
  OpsGroup:_NewCargoStatus(OPSGROUP.CargoStatus.NOTCARGO)

  --TODO: Unload flightgroup. Find parking spot etc.

  if Coordinate then

    ---
    -- Respawn at a coordinate.
    ---

    -- Template for the respawned group.
    local Template=UTILS.DeepCopy(OpsGroup.template)  --DCS#Template

    -- No late activation.
    if Activated==false then
      Template.lateActivation=true
    else
      Template.lateActivation=false
    end

    -- Loop over template units.
    for _,Unit in pairs(Template.units) do

      local element=OpsGroup:GetElementByName(Unit.name)

      if element then

        local vec3=element.vec3

        -- Relative pos vector.
        local rvec2={x=Unit.x-Template.x, y=Unit.y-Template.y} --DCS#Vec2

        local cvec2={x=Coordinate.x, y=Coordinate.z} --DCS#Vec2

        -- Position.
        Unit.x=cvec2.x+rvec2.x
        Unit.y=cvec2.y+rvec2.y
        Unit.alt=land.getHeight({x=Unit.x, y=Unit.y})

        -- Heading.
        Unit.heading=Heading and math.rad(Heading) or Unit.heading
        Unit.psi=-Unit.heading

      end

    end

    -- Respawn group.
    OpsGroup:_Respawn(0, Template)

    -- Add current waypoint. These have been cleard on loading.
    if OpsGroup:IsNavygroup() then
      OpsGroup:ClearWaypoints()
      OpsGroup.currentwp=1
      OpsGroup.passedfinalwp=true
      NAVYGROUP.AddWaypoint(OpsGroup, Coordinate, nil, nil, nil, false)
    elseif OpsGroup:IsArmygroup() then
      OpsGroup:ClearWaypoints()
      OpsGroup.currentwp=1
      OpsGroup.passedfinalwp=true
      ARMYGROUP.AddWaypoint(OpsGroup, Coordinate, nil, nil, nil, false)
    end

  else

    ---
    -- Just remove from this carrier.
    ---

    -- Nothing to do.

    OpsGroup.position=self:GetVec3()

  end

  -- Trigger "Disembarked" event.
  OpsGroup:Disembarked(OpsGroup:_GetMyCarrierGroup(), OpsGroup:_GetMyCarrierElement())

  -- Trigger "Unloaded" event.
  self:Unloaded(OpsGroup)

  -- Remove my carrier.
  OpsGroup:_RemoveMyCarrier()

end

--- On after "Unloaded" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP OpsGroupCargo Cargo OPSGROUP that was unloaded from a carrier.
function OPSGROUP:onafterUnloaded(From, Event, To, OpsGroupCargo)
  self:T(self.lid..string.format("Unloaded OPSGROUP %s", OpsGroupCargo:GetName()))
  
  if OpsGroupCargo.legion and OpsGroupCargo:IsInZone(OpsGroupCargo.legion.spawnzone) then
    self:T(self.lid..string.format("Unloaded group %s returned to legion", OpsGroupCargo:GetName()))
    OpsGroupCargo:Returned()
  end
  
  -- Check if there is a paused mission.
  local paused=OpsGroupCargo:_CountPausedMissions()>0
   
  if paused then
    OpsGroupCargo:UnpauseMission()
  end
  
end


--- On after "UnloadingDone" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterUnloadingDone(From, Event, To)

  -- Debug info
  self:T(self.lid.."Cargo unloading done..")

  -- Cancel landedAt task.
  if self:IsFlightgroup() and self:IsLandedAt() then
    local Task=self:GetTaskCurrent()
    self:__TaskCancel(5, Task)
  end

  -- Check everything was delivered (or is dead).
  local delivered=self:_CheckGoPickup(self.cargoTransport)

  if not delivered then

    -- Get new TZC.
    self.cargoTZC=self.cargoTransport:_GetTransportZoneCombo(self)

    if self.cargoTZC then

      -- Pickup the next batch.
      self:T(self.lid.."Unloaded: Still cargo left ==> Pickup")
      self:Pickup()

    else

      -- Debug info.
      self:T(self.lid..string.format("WARNING: Not all cargo was delivered but could not get a transport zone combo ==> setting carrier state to NOT CARRIER"))

      -- This is not a carrier anymore.
      self:_NewCarrierStatus(OPSGROUP.CarrierStatus.NOTCARRIER)

    end

  else

    -- Everything delivered.
    self:T(self.lid.."Unloaded: ALL cargo unloaded ==> Delivered (current)")
    self:Delivered(self.cargoTransport)

  end

end

--- On after "Delivered" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT CargoTransport The cargo transport assignment.
function OPSGROUP:onafterDelivered(From, Event, To, CargoTransport)

  -- Check if this was the current transport.
  if self.cargoTransport and self.cargoTransport.uid==CargoTransport.uid then

    -- Checks
    if self:IsPickingup() then
      -- Delete pickup waypoint?
      local wpindex=self:GetWaypointIndexNext(false)
      if wpindex then
        self:RemoveWaypoint(wpindex)
      end
      -- Remove landing airbase.
      self.isLandingAtAirbase=nil
    elseif self:IsLoading() then
      -- Nothing to do?
    elseif self:IsTransporting() then
      -- This should not happen. Carrier is transporting, how can the cargo be delivered?
    elseif self:IsUnloading() then
      -- Nothing to do?
    end

    -- This is not a carrier anymore.
    self:_NewCarrierStatus(OPSGROUP.CarrierStatus.NOTCARRIER)

    -- Startup uncontrolled aircraft to allow it to go back.
    if self:IsFlightgroup() then

      local function atbase(_airbase)
        local airbase=_airbase --Wrapper.Airbase#AIRBASE
        if airbase and self.currbase then
          if airbase.AirbaseName==self.currbase.AirbaseName then
            return true
          end
        end
        return false
      end

      -- Check if uncontrolled and NOT at destination. If so, start up uncontrolled and let flight return to whereever it wants to go.
      if self:IsUncontrolled() and not atbase(self.destbase) then
        self:StartUncontrolled()
      end
      if self:IsLandedAt() then
        local Task=self:GetTaskCurrent()
        self:TaskCancel(Task)
      end
    else
      -- Army & Navy: give Cruise command to "wake up" from waiting status.
      self:__Cruise(-0.1)
    end

    -- Set carrier transport status.
    self.cargoTransport:SetCarrierTransportStatus(self, OPSTRANSPORT.Status.DELIVERED)

    -- Check group done.
    self:T(self.lid..string.format("All cargo of transport UID=%d delivered ==> check group done in 0.2 sec", self.cargoTransport.uid))
    self:_CheckGroupDone(0.2)


  end

  -- Remove cargo transport from cargo queue.
  --self:DelOpsTransport(CargoTransport)

end

--- On after "TransportCancel" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT The transport to be cancelled.
function OPSGROUP:onafterTransportCancel(From, Event, To, Transport)

  if self.cargoTransport and self.cargoTransport.uid==Transport.uid then

    ---
    -- Current Transport
    ---

    -- Debug info.
    self:T(self.lid..string.format("Cancel current transport %d", Transport.uid))

    -- Call delivered=
    local calldelivered=false

    if self:IsPickingup() then

      -- On its way to the pickup zone. Remove waypoint. Will be done in delivered.
      calldelivered=true

    elseif self:IsLoading() then

      -- Handle cargo groups.
      local cargos=Transport:GetCargoOpsGroups(false)

      for _,_opsgroup in pairs(cargos) do
        local opsgroup=_opsgroup --#OPSGROUP

        if opsgroup:IsBoarding(self.groupname) then

          -- Remove boarding waypoint.
          opsgroup:RemoveWaypoint(self.currentwp+1)

          -- Remove from cargo bay (reserved), remove mycarrier, set cargo status.
          self:_DelCargobay(opsgroup)
          opsgroup:_RemoveMyCarrier()
          opsgroup:_NewCargoStatus(OPSGROUP.CargoStatus.NOTCARGO)

        elseif opsgroup:IsLoaded(self.groupname) then

            -- Get random point in disembark zone.
          local zoneCarrier=self:GetElementZoneUnload(opsgroup:_GetMyCarrierElement().name)

            -- Random coordinate/heading in the zone.
          local Coordinate=zoneCarrier and zoneCarrier:GetRandomCoordinate() or self.cargoTransport:GetEmbarkZone(self.cargoTZC):GetRandomCoordinate()

          -- Random heading of the group.
          local Heading=math.random(0,359)

          -- Unload to Coordinate.
          self:Unload(opsgroup, Coordinate, self.cargoTransport:GetDisembarkActivation(self.cargoTZC), Heading)

          -- Trigger "Unloaded" event for current cargo transport
          self.cargoTransport:Unloaded(opsgroup, self)

        end

      end

      -- Call delivered.
      calldelivered=true

    elseif self:IsTransporting() then

      -- Well, we cannot just unload the cargo anywhere.

      -- TODO: Best would be to bring the cargo back to the pickup zone!

    elseif self:IsUnloading() then
      -- Unloading anyway... delivered will be called when done.
    else

    end

    -- Transport delivered.
    if calldelivered then
      self:__Delivered(-2, Transport)
    end

  else

    ---
    -- NOT the current transport
    ---

    -- Set mission group status.
    Transport:SetCarrierTransportStatus(self, AUFTRAG.GroupStatus.CANCELLED)

    -- Remove transport from queue. This also removes the carrier from the transport.
    self:DelOpsTransport(Transport)

    -- Remove carrier.
    --Transport:_DelCarrier(self)

    -- Send group RTB or WAIT if nothing left to do.
    self:_CheckGroupDone(1)

  end

end


---
-- Cargo Group Functions
---

--- On before "Board" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP CarrierGroup The carrier group.
-- @param #OPSGROUP.Element Carrier The OPSGROUP element
function OPSGROUP:onbeforeBoard(From, Event, To, CarrierGroup, Carrier)

  if self:IsDead() then
    self:T(self.lid.."Group DEAD ==> Deny Board transition!")
    return false
  elseif CarrierGroup:IsDead() then
    self:T(self.lid.."Carrier Group DEAD ==> Deny Board transition!")
    self:_NewCargoStatus(OPSGROUP.CargoStatus.NOTCARGO)
    return false
  elseif Carrier.status==OPSGROUP.ElementStatus.DEAD then
    self:T(self.lid.."Carrier Element DEAD ==> Deny Board transition!")
    self:_NewCargoStatus(OPSGROUP.CargoStatus.NOTCARGO)
    return false
  end

  return true
end

--- On after "Board" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP CarrierGroup The carrier group.
-- @param #OPSGROUP.Element Carrier The OPSGROUP element
function OPSGROUP:onafterBoard(From, Event, To, CarrierGroup, Carrier)

  -- Army or Navy group.
  local CarrierIsArmyOrNavy=CarrierGroup:IsArmygroup() or CarrierGroup:IsNavygroup()
  local CargoIsArmyOrNavy=self:IsArmygroup() or self:IsNavygroup()

  -- Check that carrier is standing still.
  --if (CarrierIsArmyOrNavy and (CarrierGroup:IsHolding() and CarrierGroup:GetVelocity(Carrier.name)<=1)) or (CarrierGroup:IsFlightgroup() and (CarrierGroup:IsParking() or CarrierGroup:IsLandedAt())) then
  if (CarrierIsArmyOrNavy and (CarrierGroup:GetVelocity(Carrier.name)<=1)) or (CarrierGroup:IsFlightgroup() and (CarrierGroup:IsParking() or CarrierGroup:IsLandedAt())) then

    -- Board if group is mobile, not late activated and army or navy. Everything else is loaded directly.
    local board=self.speedMax>0 and CargoIsArmyOrNavy and self:IsAlive() and CarrierGroup:IsAlive()

    -- Armygroup cannot board ship ==> Load directly.
    if self:IsArmygroup() and CarrierGroup:IsNavygroup() then
      board=false
    end

    if self:IsLoaded() then

      -- Debug info.
      self:T(self.lid..string.format("Group is loaded currently ==> Moving directly to new carrier - No Unload(), Disembart() events triggered!"))

      -- Remove old/current carrier.
      self:_RemoveMyCarrier()

      -- Trigger Load event.
      CarrierGroup:Load(self)

    elseif board then

      -- Set cargo status.
      self:_NewCargoStatus(OPSGROUP.CargoStatus.BOARDING)

      -- Debug info.
      self:T(self.lid..string.format("Boarding group=%s [%s], carrier=%s", CarrierGroup:GetName(), CarrierGroup:GetState(), tostring(Carrier.name)))

      -- TODO: Implement embarkzone.
      local Coordinate=Carrier.unit:GetCoordinate()

      -- Clear all waypoints.
      self:ClearWaypoints(self.currentwp+1)

      if self.isArmygroup then
        local waypoint=ARMYGROUP.AddWaypoint(self, Coordinate, nil, nil, ENUMS.Formation.Vehicle.Diamond) ; waypoint.detour=1
        self:Cruise()
      else
        local waypoint=NAVYGROUP.AddWaypoint(self, Coordinate) ; waypoint.detour=1
        self:Cruise()
      end

      -- Set carrier. As long as the group is not loaded, we only reserve the cargo space.
      CarrierGroup:_AddCargobay(self, Carrier, true)

    else

      ---
      -- Direct load into carrier.
      ---

      -- Debug info.
      self:T(self.lid..string.format("Board [loaded=%s] with direct load to carrier group=%s, element=%s", tostring(self:IsLoaded()), CarrierGroup:GetName(), tostring(Carrier.name)))

      -- Get current carrier group.
      local mycarriergroup=self:_GetMyCarrierGroup()
      if mycarriergroup then
        self:T(self.lid..string.format("Current carrier group %s", mycarriergroup:GetName()))
      end
      
      -- Unload cargo first.
      if mycarriergroup and mycarriergroup:GetName()~=CarrierGroup:GetName() then
        -- TODO: Unload triggers other stuff like Disembarked. This can be a problem!
        self:T(self.lid.."Unloading from mycarrier")
        mycarriergroup:Unload(self)
      end

      -- Trigger Load event.
      CarrierGroup:Load(self)
    end

  else

    -- Redo boarding call.
    self:T(self.lid.."Carrier not ready for boarding yet ==> repeating boarding call in 10 sec")
    self:__Board(-10, CarrierGroup, Carrier)

    -- Set carrier. As long as the group is not loaded, we only reserve the cargo space.ï¿½
    CarrierGroup:_AddCargobay(self, Carrier, true)
  end


end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Internal Check Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if group is in zones.
-- @param #OPSGROUP self
function OPSGROUP:_CheckInZones()

  if self.checkzones and self:IsAlive() then

    local Ncheck=self.checkzones:Count()
    local Ninside=self.inzones:Count()

    -- Debug info.
    self:T(self.lid..string.format("Check if group is in %d zones. Currently it is in %d zones.", self.checkzones:Count(), self.inzones:Count()))

    -- Firstly, check if group is still inside zone it was already in. If not, remove zones and trigger LeaveZone() event.
    local leftzones={}
    for inzonename, inzone in pairs(self.inzones:GetSet()) do

      -- Check if group is still inside the zone.
      local isstillinzone=self.group:IsInZone(inzone) --:IsPartlyOrCompletelyInZone(inzone)

      -- If not, trigger, LeaveZone event.
      if not isstillinzone then
        table.insert(leftzones, inzone)
      end
    end

    -- Trigger leave zone event.
    for _,leftzone in pairs(leftzones) do
      self:LeaveZone(leftzone)
    end


    -- Now, run of all check zones and see if the group entered a  zone.
    local enterzones={}
    for checkzonename,_checkzone in pairs(self.checkzones:GetSet()) do
      local checkzone=_checkzone --Core.Zone#ZONE

      -- Is group currtently in this check zone?
      local isincheckzone=self.group:IsInZone(checkzone) --:IsPartlyOrCompletelyInZone(checkzone)

      if isincheckzone and not self.inzones:_Find(checkzonename) then
        table.insert(enterzones, checkzone)
      end
    end

    -- Trigger enter zone event.
    for _,enterzone in pairs(enterzones) do
      self:EnterZone(enterzone)
    end

  end

end

--- Check detected units.
-- @param #OPSGROUP self
function OPSGROUP:_CheckDetectedUnits()

  if self.detectionOn and self.group and not self:IsDead() then

    -- Get detected DCS units.
    local detectedtargets=self.group:GetDetectedTargets()

    local detected={}
    local groups={}
    for DetectionObjectID, Detection in pairs(detectedtargets or {}) do
      local DetectedObject=Detection.object -- DCS#Object

      if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then

        -- Unit.
        local unit=UNIT:Find(DetectedObject)

        if unit and unit:IsAlive() then

          -- Name of detected unit
          local unitname=unit:GetName()

          -- Add unit to detected table of this run.
          table.insert(detected, unit)

          -- Trigger detected unit event ==> This also triggers the DetectedUnitNew and DetectedUnitKnown events.
          self:DetectedUnit(unit)

          -- Get group of unit.
          local group=unit:GetGroup()

          -- Add group to table.
          if group then
            groups[group:GetName()]=group
          end

        end
      end
    end

    -- Call detected group event.
    for groupname, group in pairs(groups) do
      self:DetectedGroup(group)
    end

    -- Loop over units in detected set.
    local lost={}
    for _,_unit in pairs(self.detectedunits:GetSet()) do
      local unit=_unit --Wrapper.Unit#UNIT

      -- Loop over detected units
      local gotit=false
      for _,_du in pairs(detected) do
        local du=_du --Wrapper.Unit#UNIT
        if unit:GetName()==du:GetName() then
          gotit=true
        end
      end

      if not gotit then
        table.insert(lost, unit:GetName())
        self:DetectedUnitLost(unit)
      end

    end

    -- Remove lost units from detected set.
    self.detectedunits:RemoveUnitsByName(lost)


    -- Loop over groups in detected set.
    local lost={}
    for _,_group in pairs(self.detectedgroups:GetSet()) do
      local group=_group --Wrapper.Group#GROUP

      -- Loop over detected units
      local gotit=false
      for _,_du in pairs(groups) do
        local du=_du --Wrapper.Group#GROUP
        if group:GetName()==du:GetName() then
          gotit=true
        end
      end

      if not gotit then
        table.insert(lost, group:GetName())
        self:DetectedGroupLost(group)
      end

    end

    -- Remove lost units from detected set.
    self.detectedgroups:RemoveGroupsByName(lost)

  end

end

--- Check if passed the final waypoint and, if necessary, update route.
-- @param #OPSGROUP self
-- @param #number delay Delay in seconds.
function OPSGROUP:_CheckGroupDone(delay)

  -- FSM state.
  local fsmstate=self:GetState()

  if self:IsAlive() and self.isAI then

    if delay and delay>0 then
      -- Debug info.
      self:T(self.lid..string.format("Check OPSGROUP done? [state=%s] in %.3f seconds...", fsmstate, delay))

      -- Delayed call.
      self:ScheduleOnce(delay, self._CheckGroupDone, self)
    else

      -- Debug info.
      self:T(self.lid..string.format("Check OSGROUP done? [state=%s]", fsmstate))

      -- Group is engaging something.
      if self:IsEngaging() then
        self:T(self.lid.."Engaging! Group NOT done ==> UpdateRoute()")
        self:UpdateRoute()
        return
      end

      -- Group is returning.
      if self:IsReturning() then
        self:T(self.lid.."Returning! Group NOT done...")
        return
      end

      -- Group is rearming.
      if self:IsRearming() then
        self:T(self.lid.."Rearming! Group NOT done...")
        return
      end

      -- Group is retreating.
      if self:IsRetreating() then
        self:T(self.lid.."Retreating! Group NOT done...")
        return
      end
      
      if self:IsBoarding() then
        self:T(self.lid.."Boarding! Group NOT done...")
        return      
      end
      
      -- Group is waiting. We deny all updates.
      if self:IsWaiting() then
        -- If group is waiting, we assume that is the way it is meant to be.
        self:T(self.lid.."Waiting! Group NOT done...")
        return
      end

      -- Number of tasks remaining.
      local nTasks=self:CountRemainingTasks()

      -- Number of mission remaining.
      local nMissions=self:CountRemainingMissison()

      -- Number of cargo transports remaining.
      local nTransports=self:CountRemainingTransports()
      
      -- Number of paused missions.
      local nPaused=self:_CountPausedMissions()

      -- First check if there is a paused mission and that all remaining missions are paused. If there are other missions in the queue, we will run those.
      if nPaused>0 and nPaused==nMissions then
        local missionpaused=self:_GetPausedMission()
        self:T(self.lid..string.format("Found paused mission %s [%s]. Unpausing mission...", missionpaused.name, missionpaused.type))
        self:UnpauseMission()
        return
      end
      
      -- Number of remaining tasks/missions?
      if nTasks>0 or nMissions>0 or nTransports>0 then
        self:T(self.lid..string.format("Group still has tasks, missions or transports ==> NOT DONE"))
        return
      end      

      -- Get current waypoint.
      local waypoint=self:GetWaypoint(self.currentwp)

      if waypoint then

        -- Number of tasks remaining for this waypoint.
        local ntasks=self:CountTasksWaypoint(waypoint.uid)

        -- We only want to update the route if there are no more tasks to be done.
        if ntasks>0 then
          self:T(self.lid..string.format("Still got %d tasks for the current waypoint UID=%d ==> RETURN (no action)", ntasks, waypoint.uid))
          return
        end
      end
      
      if self.adinfinitum then

        ---
        -- Parol Ad Infinitum
        ---

        if #self.waypoints>0 then

          -- Next waypoint index.
          local i=self:GetWaypointIndexNext(true)

          -- Get positive speed to first waypoint.
          local speed=self:GetSpeedToWaypoint(i)

          -- Cruise.
          self:Cruise(speed)

          -- Debug info.
          self:T(self.lid..string.format("Adinfinitum=TRUE ==> Goto WP index=%d at speed=%d knots", i, speed))

        else
          self:T(self.lid..string.format("WARNING: No waypoints left! Commanding a Full Stop"))
          self:__FullStop(-1)
        end

      else

        ---
        -- Finite Patrol
        ---

        if self:HasPassedFinalWaypoint() then

          ---
          -- Passed FINAL waypoint
          ---

          if self.legion and self.legionReturn then

            self:T(self.lid..string.format("Passed final WP, adinfinitum=FALSE, LEGION set ==> RTZ"))
            if self.isArmygroup then
              self:T2(self.lid.."RTZ to legion spawn zone")
              self:RTZ(self.legion.spawnzone)
            elseif self.isNavygroup then
              self:T2(self.lid.."RTZ to legion port zone")
              self:RTZ(self.legion.portzone)
            end

          else

            -- No further waypoints. Command a full stop.
            self:__FullStop(-1)

            self:T(self.lid..string.format("Passed final WP, adinfinitum=FALSE ==> Full Stop"))

          end

        else

          ---
          -- Final waypoint NOT passed yet
          ---

          if #self.waypoints>0 then
            self:T(self.lid..string.format("NOT Passed final WP, #WP>0 ==> Update Route"))
            self:Cruise()
          else
            self:T(self.lid..string.format("WARNING: No waypoints left! Commanding a Full Stop"))
            self:__FullStop(-1)
          end

        end

      end

    end
  end

end

--- Check if group got stuck.
-- @param #OPSGROUP self
function OPSGROUP:_CheckStuck()

  -- Cases we are not stuck.
  if self:IsHolding() or self:Is("Rearming") or self:IsWaiting() or self:HasPassedFinalWaypoint() then
    return
  end

  -- Current time.
  local Tnow=timer.getTime()

  -- Expected speed in m/s.
  local ExpectedSpeed=self:GetExpectedSpeed()

  -- Current speed in m/s.
  local speed=self:GetVelocity()

  -- Check speed.
  if speed<0.1 then

    if ExpectedSpeed>0 and not self.stuckTimestamp then
      self:T2(self.lid..string.format("WARNING: Group came to an unexpected standstill. Speed=%.1f<%.1f m/s expected", speed, ExpectedSpeed))
      self.stuckTimestamp=Tnow
      self.stuckVec3=self:GetVec3()
    end

  else
    -- Moving (again).
    self.stuckTimestamp=nil
  end

  -- Somehow we are not moving...
  if self.stuckTimestamp then

    -- Time we are holding.
    local holdtime=Tnow-self.stuckTimestamp

    if holdtime>=5*60 and holdtime<10*60 then

      -- Debug warning.
      self:T(self.lid..string.format("WARNING: Group came to an unexpected standstill. Speed=%.1f<%.1f m/s expected for %d sec", speed, ExpectedSpeed, holdtime))

      -- Check what is happening.
      if self:IsEngaging() then
        self:__Disengage(1)        
      elseif self:IsReturning() then
        self:T2(self.lid.."RTZ because of stuck")
        self:__RTZ(1)
      else
        self:__Cruise(1)
      end

    elseif holdtime>=10*60 and holdtime<30*60 then

      -- Debug warning.
      self:T(self.lid..string.format("WARNING: Group came to an unexpected standstill. Speed=%.1f<%.1f m/s expected for %d sec", speed, ExpectedSpeed, holdtime))

      --TODO: Stuck event!
      -- Look for a current mission and cancel it as we do not seem to be able to perform it.
      local mission=self:GetMissionCurrent()
      if mission then
        self:T(self.lid..string.format("WARNING: Cancelling mission %s [%s] due to being stuck", mission:GetName(), mission:GetType()))
        self:MissionCancel(mission)
      else
        -- Give cruise command again.
        if self:IsReturning() then
          self:T2(self.lid.."RTZ because of stuck")
          self:__RTZ(1)
        else
          self:__Cruise(1)
        end
      end

    elseif holdtime>=30*60 then

      -- Debug warning.
      self:T(self.lid..string.format("WARNING: Group came to an unexpected standstill. Speed=%.1f<%.1f m/s expected for %d sec", speed, ExpectedSpeed, holdtime))
      
      if self.legion then
        self:T(self.lid..string.format("Asset is returned to its legion after being stuck!"))
        self:ReturnToLegion()
      end

    end

  end

end


--- Check damage.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:_CheckDamage()

  self:T(self.lid..string.format("Checking damage..."))

  self.life=0
  local damaged=false
  
  for _,_element in pairs(self.elements) do
    local element=_element --Ops.OpsGroup#OPSGROUP.Element

    if element.status~=OPSGROUP.ElementStatus.DEAD and element.status~=OPSGROUP.ElementStatus.INUTERO then
  
      -- Current life points.
      local life=element.unit:GetLife()
  
      self.life=self.life+life
  
      if life<element.life then
        element.life=life
        self:ElementDamaged(element)
        damaged=true
      end
    
    end

  end

  -- If anyone in the group was damaged, trigger event.
  if damaged then
    self:Damaged()
  end

  return self
end

--- Check ammo is full.
-- @param #OPSGROUP self
-- @return #boolean If true, ammo is full.
function OPSGROUP:_CheckAmmoFull()

  -- Get current ammo.
  local ammo=self:GetAmmoTot()

  for key,value in pairs(self.ammo) do

    if ammo[key]<value then
      -- At least one type of ammunition is less than when spawned.
      return false
    end

  end

  return true
end

--- Check ammo status.
-- @param #OPSGROUP self
function OPSGROUP:_CheckAmmoStatus()

  -- First check if there was ammo initially.
  if self.ammo.Total>0 then

    -- Get current ammo.
    local ammo=self:GetAmmoTot()

    -- Check if rearming is completed.
    if self:IsRearming() then
      if ammo.Total>=self.ammo.Total then
        self:Rearmed()
      end
    end

    -- Total.
    if self.outofAmmo and ammo.Total>0 then
      self.outofAmmo=false
    end
    if ammo.Total==0 and not self.outofAmmo then
      self.outofAmmo=true
      self:OutOfAmmo()
    end

    -- Guns (changed to shells)
    if self.outofGuns and ammo.Shells>0 then
      self.outofGuns=false
    end
    if ammo.Shells==0 and self.ammo.Shells>0 and not self.outofGuns then
      self.outofGuns=true
      self:OutOfGuns()
    end

    -- Rockets.
    if self.outofRockets and ammo.Rockets>0 then
      self.outofRockets=false
    end
    if ammo.Rockets==0 and self.ammo.Rockets>0 and not self.outofRockets then
      self.outofRockets=true
      self:OutOfRockets()
    end

    -- Bombs.
    if self.outofBombs and ammo.Bombs>0 then
      self.outofBombs=false
    end
    if ammo.Bombs==0 and self.ammo.Bombs>0 and not self.outofBombs then
      self.outofBombs=true
      self:OutOfBombs()
    end

    -- Missiles (All).
    if self.outofMissiles and ammo.Missiles>0 then
      self.outofMissiles=false
    end
    if ammo.Missiles==0 and self.ammo.Missiles>0 and not self.outofMissiles then
      self.outofMissiles=true
      self:OutOfMissiles()
    end

    -- Missiles AA.
    if self.outofMissilesAA and ammo.MissilesAA>0 then
      self.outofMissilesAA=false
    end
    if ammo.MissilesAA==0 and self.ammo.MissilesAA>0 and not self.outofMissilesAA then
      self.outofMissilesAA=true
      self:OutOfMissilesAA()
    end

    -- Missiles AG.
    if self.outofMissilesAG and ammo.MissilesAG>0 then
      self.outofMissilesAG=false
    end
    if ammo.MissilesAG==0 and self.ammo.MissilesAG>0 and not self.outofMissilesAG then
      self.outofMissilesAG=true
      self:OutOfMissilesAG()
    end

    -- Missiles AS.
    if self.outofMissilesAS and ammo.MissilesAS>0 then
      self.outofMissilesAS=false
    end
    if ammo.MissilesAS==0 and self.ammo.MissilesAS>0 and not self.outofMissilesAS then
      self.outofMissilesAS=true
      self:OutOfMissilesAS()
    end

    -- Torpedos.
    if self.outofTorpedos and ammo.Torpedos>0 then
      self.outofTorpedos=false
    end
    if ammo.Torpedos==0 and self.ammo.Torpedos>0 and not self.outofTorpedos then
      self.outofTorpedos=true
      self:OutOfTorpedos()
    end


    -- Check if group is engaging.
    if self:IsEngaging() and ammo.Total==0 then
      self:Disengage()
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Info Common to Air, Land and Sea
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Print info on mission and task status to DCS log file.
-- @param #OPSGROUP self
function OPSGROUP:_PrintTaskAndMissionStatus()

  ---
  -- Tasks: verbose >= 3
  ---

  -- Task queue.
  if self.verbose>=3 and #self.taskqueue>0 then
    local text=string.format("Tasks #%d", #self.taskqueue)
    for i,_task in pairs(self.taskqueue) do
      local task=_task --Ops.OpsGroup#OPSGROUP.Task
      local name=task.description
      local taskid=task.dcstask.id or "unknown"
      local status=task.status
      local clock=UTILS.SecondsToClock(task.time, true)
      local eta=task.time-timer.getAbsTime()
      local started=task.timestamp and UTILS.SecondsToClock(task.timestamp, true) or "N/A"
      local duration=-1
      if task.duration then
        duration=task.duration
        if task.timestamp then
          -- Time the task is running.
          duration=task.duration-(timer.getAbsTime()-task.timestamp)
        else
          -- Time the task is supposed to run.
          duration=task.duration
        end
      end
      -- Output text for element.
      if task.type==OPSGROUP.TaskType.SCHEDULED then
        text=text..string.format("\n[%d] %s (%s): status=%s, scheduled=%s (%d sec), started=%s, duration=%d", i, taskid, name, status, clock, eta, started, duration)
      elseif task.type==OPSGROUP.TaskType.WAYPOINT then
        text=text..string.format("\n[%d] %s (%s): status=%s, waypoint=%d, started=%s, duration=%d, stopflag=%d", i, taskid, name, status, task.waypoint, started, duration, task.stopflag:Get())
      end
    end
    self:I(self.lid..text)
  end

  ---
  -- Missions: verbose>=2
  ---

  -- Current mission name.
  if self.verbose>=2 then
    local Mission=self:GetMissionByID(self.currentmission)

    -- Current status.
    local text=string.format("Missions %d, Current: %s", self:CountRemainingMissison(), Mission and Mission.name or "none")
    for i,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      local Cstart= UTILS.SecondsToClock(mission.Tstart, true)
      local Cstop = mission.Tstop and UTILS.SecondsToClock(mission.Tstop, true) or "INF"
      text=text..string.format("\n[%d] %s (%s) status=%s (%s), Time=%s-%s, prio=%d wp=%s targets=%d",
      i, tostring(mission.name), mission.type, mission:GetGroupStatus(self), tostring(mission.status), Cstart, Cstop, mission.prio, tostring(mission:GetGroupWaypointIndex(self)), mission:CountMissionTargets())
    end
    self:I(self.lid..text)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Waypoints & Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Simple task function. Can be used to call a function which has the warehouse and the executing group as parameters.
-- @param #OPSGROUP self
-- @param #string Function The name of the function to call passed as string.
-- @param #number uid Waypoint UID.
function OPSGROUP:_SimpleTaskFunction(Function, uid)

  -- Task script.
  local DCSScript = {}

  --_DATABASE:FindOpsGroup(groupname)

  DCSScript[#DCSScript+1]   = string.format('local mygroup = _DATABASE:FindOpsGroup(\"%s\") ', self.groupname)  -- The group that executes the task function. Very handy with the "...".
  DCSScript[#DCSScript+1]   = string.format('%s(mygroup, %d)', Function, uid)                                   -- Call the function, e.g. myfunction.(warehouse,mygroup)

  -- Create task.
  local DCSTask=CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))

  return DCSTask
end

--- Enhance waypoint table.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint Waypoint data.
-- @return #OPSGROUP.Waypoint Modified waypoint data.
function OPSGROUP:_CreateWaypoint(waypoint)

  -- Set uid.
  waypoint.uid=self.wpcounter

  -- Waypoint has not been passed yet.
  waypoint.npassed=0

  -- Coordinate.
  waypoint.coordinate=COORDINATE:New(waypoint.x, waypoint.alt, waypoint.y)

  -- Set waypoint name.
  waypoint.name=string.format("Waypoint UID=%d", waypoint.uid)

  -- Set types.
  waypoint.patrol=false
  waypoint.detour=false
  waypoint.astar=false
  waypoint.temp=false

  -- Tasks of this waypoint
  local taskswp={}

  -- At each waypoint report passing.
  local TaskPassingWaypoint=self:_SimpleTaskFunction("OPSGROUP._PassingWaypoint", waypoint.uid)
  table.insert(taskswp, TaskPassingWaypoint)

  -- Waypoint task combo.
  waypoint.task=self.group:TaskCombo(taskswp)

  -- Increase UID counter.
  self.wpcounter=self.wpcounter+1

  return waypoint
end

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint waypoint Waypoint data.
-- @param #number wpnumber Waypoint index/number. Default is as last waypoint.
function OPSGROUP:_AddWaypoint(waypoint, wpnumber)

  -- Index.
  wpnumber=wpnumber or #self.waypoints+1

  -- Add waypoint to table.
  table.insert(self.waypoints, wpnumber, waypoint)

  -- Debug info.
  self:T(self.lid..string.format("Adding waypoint at index=%d with UID=%d", wpnumber, waypoint.uid))

  -- Now we obviously did not pass the final waypoint.
  if self.currentwp and wpnumber>self.currentwp then
    self:_PassedFinalWaypoint(false, string.format("_AddWaypoint: wpnumber/index %d>%d self.currentwp", wpnumber, self.currentwp))
  end

end

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #number WpIndexMin
-- @param #number WpIndexMax
-- @return #OPSGROUP self
function OPSGROUP:_InitWaypoints(WpIndexMin, WpIndexMax)

  -- Waypoints empty!
  self.waypoints={}
  self.waypoints0={}

  -- Get group template
  local template=_DATABASE:GetGroupTemplate(self.groupname)

  if template==nil then
    return self
  end

  -- Template waypoints.
  self.waypoints0=UTILS.DeepCopy(template.route.points) --self.group:GetTemplateRoutePoints()

  WpIndexMin=WpIndexMin or 1
  WpIndexMax=WpIndexMax or #self.waypoints0
  WpIndexMax=math.min(WpIndexMax, #self.waypoints0) --Ensure max is not out of bounce.

  --for index,wp in pairs(self.waypoints0) do

  for i=WpIndexMin,WpIndexMax do

    local wp=self.waypoints0[i] --DCS#Waypoint

    -- Coordinate of the waypoint.
    local Coordinate=COORDINATE:NewFromWaypoint(wp)

    -- Strange!
    wp.speed=wp.speed or 0

    -- Speed at the waypoint.
    local speedknots=UTILS.MpsToKnots(wp.speed)

    -- Expected speed to the first waypoint.
    if i<=2 then
      self.speedWp=wp.speed
      self:T(self.lid..string.format("Expected/waypoint speed=%.1f m/s", self.speedWp))
    end

    -- Speed in knots.
    local Speed=UTILS.MpsToKnots(wp.speed)

    -- Add waypoint.
    local Waypoint=nil
    if self:IsFlightgroup() then
      Waypoint=FLIGHTGROUP.AddWaypoint(self, Coordinate, Speed, nil, Altitude,  false)
    elseif self:IsArmygroup() then
      Waypoint=ARMYGROUP.AddWaypoint(self,   Coordinate, Speed, nil, wp.action, false)
    elseif self:IsNavygroup() then
      Waypoint=NAVYGROUP.AddWaypoint(self,   Coordinate, Speed, nil, Depth,     false)
    end

    -- Get DCS waypoint tasks set in the ME. EXPERIMENTAL!
    local DCStasks=wp.task and wp.task.params.tasks or nil
    if DCStasks and self.useMEtasks then
      for _,DCStask in pairs(DCStasks) do
        -- Wrapped Actions are commands. We do not take those.
        if DCStask.id and DCStask.id~="WrappedAction" then
          self:AddTaskWaypoint(DCStask,Waypoint, "ME Task")
        end
      end
    end

  end

  -- Debug info.
  self:T(self.lid..string.format("Initializing %d waypoints", #self.waypoints))

  -- Flight group specific.
  if self:IsFlightgroup() then

    -- Get home and destination airbases from waypoints.
    self.homebase=self.homebase or self:GetHomebaseFromWaypoints() -- GetHomebaseFromWaypoints() returns carriers or destroyers if no airbase is found.
    local destbase=self:GetDestinationFromWaypoints()
    self.destbase=self.destbase or destbase
    self.currbase=self:GetHomebaseFromWaypoints() -- Skipped To fix RTB issue

    --env.info("FF home base "..(self.homebase and self.homebase:GetName() or "unknown"))
    --env.info("FF dest base "..(self.destbase and self.destbase:GetName() or "unknown"))

    -- Remove the landing waypoint. We use RTB for that. It makes adding new waypoints easier as we do not have to check if the last waypoint is the landing waypoint.
    if destbase and #self.waypoints>1 then
      table.remove(self.waypoints, #self.waypoints)
    end

    -- Set destination to homebase.
    if self.destbase==nil then  -- Skipped To fix RTB issue
      self.destbase=self.homebase
    end

  end

  -- Update route.
  if #self.waypoints>0 then

    -- Check if only 1 wp?
    if #self.waypoints==1 then
      self:_PassedFinalWaypoint(true, "_InitWaypoints: #self.waypoints==1")
    end

  else
    self:T(self.lid.."WARNING: No waypoints initialized. Number of waypoints is 0!")
  end

  return self
end

--- Route group along waypoints.
-- @param #OPSGROUP self
-- @param #table waypoints Table of waypoints.
-- @param #number delay Delay in seconds.
-- @return #OPSGROUP self
function OPSGROUP:Route(waypoints, delay)

  if delay and delay>0 then
    self:ScheduleOnce(delay, OPSGROUP.Route, self, waypoints)
  else

    if self:IsAlive() then

      -- Clear all DCS tasks. NOTE: This can make DCS crash!
      --self:ClearTasks()

      -- DCS mission task.
      local DCSTask = {
        id = 'Mission',
        params = {
          airborne = self:IsFlightgroup(),
          route={points=waypoints},
        },
      }

      -- Set mission task.
      self:SetTask(DCSTask)

    else
      self:T(self.lid.."ERROR: Group is not alive! Cannot route group.")
    end
  end

  return self
end



--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #number n Waypoint
function OPSGROUP:_UpdateWaypointTasks(n)

  local waypoints=self.waypoints or {}
  local nwaypoints=#waypoints

  for i,_wp in pairs(waypoints) do
    local wp=_wp --Ops.OpsGroup#OPSGROUP.Waypoint

    if i>=n or nwaypoints==1 then

      -- Debug info.
      self:T2(self.lid..string.format("Updating waypoint task for waypoint %d/%d ID=%d. Last waypoint passed %d", i, nwaypoints, wp.uid, self.currentwp))

      -- Tasks of this waypoint
      local taskswp={}

      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("OPSGROUP._PassingWaypoint", self, wp.uid)
      table.insert(taskswp, TaskPassingWaypoint)

      -- Waypoint task combo.
      wp.task=self.group:TaskCombo(taskswp)

    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called when a group is passing a waypoint.
--@param #OPSGROUP opsgroup Ops group object.
--@param #number uid Waypoint UID.
function OPSGROUP._PassingWaypoint(opsgroup, uid)

  -- Debug message.
  local text=string.format("Group passing waypoint uid=%d", uid)
  opsgroup:T(opsgroup.lid..text)

  -- Get waypoint data.
  local waypoint=opsgroup:GetWaypointByID(uid)

  if waypoint then

    -- Increase passing counter.
    waypoint.npassed=waypoint.npassed+1

    -- Current wp.
    local currentwp=opsgroup.currentwp

    -- Get the current waypoint index.
    opsgroup.currentwp=opsgroup:GetWaypointIndex(uid)

    local wpistemp=waypoint.temp or waypoint.detour or waypoint.astar

    -- Remove temp waypoints.
    if wpistemp then
      opsgroup:RemoveWaypointByID(uid)
    end

    -- Get next waypoint. Tricky part is that if
    local wpnext=opsgroup:GetWaypointNext()

    if wpnext then --and (opsgroup.currentwp<#opsgroup.waypoints or opsgroup.adinfinitum or wpistemp)

      -- Debug info.
      opsgroup:T(opsgroup.lid..string.format("Next waypoint UID=%d index=%d", wpnext.uid, opsgroup:GetWaypointIndex(wpnext.uid)))

      -- Set formation.
      if opsgroup.isArmygroup then
        opsgroup.option.Formation=wpnext.action
      end

      -- Set speed to next wp.
      opsgroup.speed=wpnext.speed

      if opsgroup.speed<0.01 then
        opsgroup.speed=UTILS.KmphToMps(opsgroup.speedCruise)
      end

    else

      -- Set passed final waypoint.
      opsgroup:_PassedFinalWaypoint(true, "_PassingWaypoint No next Waypoint found")

    end

    -- Check if final waypoint was reached.
    if opsgroup.currentwp==#opsgroup.waypoints and not (opsgroup.adinfinitum or wpistemp) then
      -- Set passed final waypoint.
      opsgroup:_PassedFinalWaypoint(true, "_PassingWaypoint currentwp==#waypoints and NOT adinfinitum and NOT a temporary waypoint")
    end

    -- Trigger PassingWaypoint event.
    if waypoint.temp then

      ---
      -- Temporary Waypoint
      ---

      if (opsgroup:IsNavygroup() or opsgroup:IsArmygroup()) and opsgroup.currentwp==#opsgroup.waypoints then
        --TODO: not sure if this works with FLIGHTGROUPS

        -- Removing this for now.
        opsgroup:Cruise()
      end

    elseif waypoint.astar then

      ---
      -- Pathfinding Waypoint
      ---

      -- Cruise.
      opsgroup:Cruise()

    elseif waypoint.detour then

      ---
      -- Detour Waypoint
      ---

      if opsgroup:IsRearming() then

        -- Trigger Rearming event.
        opsgroup:Rearming()

      elseif opsgroup:IsRetreating() then

        -- Trigger Retreated event.
        opsgroup:Retreated()

      elseif opsgroup:IsReturning() then

        -- Trigger Returned event.
        opsgroup:Returned()

      elseif opsgroup:IsPickingup() then

        if opsgroup:IsFlightgroup() then

          -- Land at current pos and wait for 60 min max.
          if opsgroup.cargoTZC then

            if opsgroup.cargoTZC.PickupAirbase then
              -- Pickup airbase specified. Land there.
              opsgroup:LandAtAirbase(opsgroup.cargoTZC.PickupAirbase)
            else
              -- Land somewhere in the pickup zone. Only helos can do that.
              local coordinate=opsgroup.cargoTZC.PickupZone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND})
              opsgroup:LandAt(coordinate, 60*60)
            end

          else
            local coordinate=opsgroup:GetCoordinate()
            opsgroup:LandAt(coordinate, 60*60)
          end


        else

          -- Wait and load cargo.
          opsgroup:FullStop()
          opsgroup:__Loading(-5)

        end

      elseif opsgroup:IsTransporting() then

       if opsgroup:IsFlightgroup() then

          -- Land at current pos and wait for 60 min max.
          if opsgroup.cargoTZC then

            if opsgroup.cargoTZC.DeployAirbase then
              -- Deploy airbase specified. Land there.
              opsgroup:LandAtAirbase(opsgroup.cargoTZC.DeployAirbase)
            else
              -- Land somewhere in the pickup zone. Only helos can do that.
              local coordinate=opsgroup.cargoTZC.DeployZone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND})
              opsgroup:LandAt(coordinate, 60*60)
            end

          else
            local coordinate=opsgroup:GetCoordinate()
            opsgroup:LandAt(coordinate, 60*60)
          end


        else
          -- Stop and unload.
          opsgroup:FullStop()
          opsgroup:Unloading()
        end

      elseif opsgroup:IsBoarding() then

        local carrierGroup=opsgroup:_GetMyCarrierGroup()
        local carrier=opsgroup:_GetMyCarrierElement()

        if carrierGroup and carrierGroup:IsAlive() then

          if carrier and carrier.unit and carrier.unit:IsAlive() then

            -- Load group into the carrier.
            carrierGroup:Load(opsgroup)

          else
            opsgroup:E(opsgroup.lid.."ERROR: Group cannot board assigned carrier UNIT as it is NOT alive!")
          end

        else
          opsgroup:E(opsgroup.lid.."ERROR: Group cannot board assigned carrier GROUP as it is NOT alive!")
        end

      elseif opsgroup:IsEngaging() then

        -- Nothing to do really.
        opsgroup:T(opsgroup.lid.."Passing engaging waypoint")

      else

        -- Trigger DetourReached event.
        opsgroup:DetourReached()

        if waypoint.detour==0 then
          opsgroup:FullStop()
        elseif waypoint.detour==1 then
          opsgroup:Cruise()
        else
          opsgroup:E("ERROR: waypoint.detour should be 0 or 1")
          opsgroup:FullStop()
        end

      end

    else

      ---
      -- Normal Route Waypoint
      ---

      -- Check if the group is still pathfinding.
      if opsgroup.ispathfinding then
        opsgroup.ispathfinding=false
      end

      -- Call event function.
      opsgroup:PassingWaypoint(waypoint)
    end

  end

end

--- Function called when a task is executed.
--@param Wrapper.Group#GROUP group Group which should execute the task.
--@param #OPSGROUP opsgroup Ops group.
--@param #OPSGROUP.Task task Task.
function OPSGROUP._TaskExecute(group, opsgroup, task)

  -- Debug message.
  local text=string.format("_TaskExecute %s", task.description)
  opsgroup:T3(opsgroup.lid..text)

  -- Set current task to nil so that the next in line can be executed.
  if opsgroup then
    opsgroup:TaskExecute(task)
  end
end

--- Function called when a task is done.
--@param Wrapper.Group#GROUP group Group for which the task is done.
--@param #OPSGROUP opsgroup Ops group.
--@param #OPSGROUP.Task task Task.
function OPSGROUP._TaskDone(group, opsgroup, task)

  -- Debug message.
  local text=string.format("_TaskDone %s", task.description)
  opsgroup:T(opsgroup.lid..text)

  -- Set current task to nil so that the next in line can be executed.
  if opsgroup then
    opsgroup:TaskDone(task)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OPTION FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the default ROE for the group. This is the ROE state gets when the group is spawned or to which it defaults back after a mission.
-- @param #OPSGROUP self
-- @param #number roe ROE of group. Default is `ENUMS.ROE.ReturnFire`.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultROE(roe)
  self.optionDefault.ROE=roe or ENUMS.ROE.ReturnFire
  return self
end

--- Set current ROE for the group.
-- @param #OPSGROUP self
-- @param #string roe ROE of group. Default is value set in `SetDefaultROE` (usually `ENUMS.ROE.ReturnFire`).
-- @return #OPSGROUP self
function OPSGROUP:SwitchROE(roe)

  if self:IsAlive() or self:IsInUtero() then

    self.option.ROE=roe or self.optionDefault.ROE

    if self:IsInUtero() then
      self:T2(self.lid..string.format("Setting current ROE=%d when GROUP is SPAWNED", self.option.ROE))
    else

      self.group:OptionROE(self.option.ROE)

      self:T(self.lid..string.format("Setting current ROE=%d (%s)", self.option.ROE, self:_GetROEName(self.option.ROE)))
    end


  else
    self:T(self.lid.."WARNING: Cannot switch ROE! Group is not alive")
  end

  return self
end

--- Get name of ROE corresponding to the numerical value.
-- @param #OPSGROUP self
-- @return #string Name of ROE.
function OPSGROUP:_GetROEName(roe)
  local name="unknown"
  if roe==0 then
    name="Weapon Free"
  elseif roe==1 then
    name="Open Fire/Weapon Free"
  elseif roe==2 then
    name="Open Fire"
  elseif roe==3 then
    name="Return Fire"
  elseif roe==4 then
    name="Weapon Hold"
  end
  return name
end

--- Get current ROE of the group.
-- @param #OPSGROUP self
-- @return #number Current ROE.
function OPSGROUP:GetROE()
  return self.option.ROE or self.optionDefault.ROE
end

--- Set the default ROT for the group. This is the ROT state gets when the group is spawned or to which it defaults back after a mission.
-- @param #OPSGROUP self
-- @param #number rot ROT of group. Default is `ENUMS.ROT.PassiveDefense`.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultROT(rot)
  self.optionDefault.ROT=rot or ENUMS.ROT.PassiveDefense
  return self
end

--- Set ROT for the group.
-- @param #OPSGROUP self
-- @param #string rot ROT of group. Default is value set in `:SetDefaultROT` (usually `ENUMS.ROT.PassiveDefense`).
-- @return #OPSGROUP self
function OPSGROUP:SwitchROT(rot)

  if self:IsFlightgroup() then

    if self:IsAlive() or self:IsInUtero() then

      self.option.ROT=rot or self.optionDefault.ROT

      if self:IsInUtero() then
        self:T2(self.lid..string.format("Setting current ROT=%d when GROUP is SPAWNED", self.option.ROT))
      else

        self.group:OptionROT(self.option.ROT)

        -- Debug info.
        self:T(self.lid..string.format("Setting current ROT=%d (0=NoReaction, 1=Passive, 2=Evade, 3=ByPass, 4=AllowAbort)", self.option.ROT))
      end


    else
      self:T(self.lid.."WARNING: Cannot switch ROT! Group is not alive")
    end

  end

  return self
end

--- Get current ROT of the group.
-- @param #OPSGROUP self
-- @return #number Current ROT.
function OPSGROUP:GetROT()
  return self.option.ROT or self.optionDefault.ROT
end


--- Set the default Alarm State for the group. This is the state gets when the group is spawned or to which it defaults back after a mission.
-- @param #OPSGROUP self
-- @param #number alarmstate Alarm state of group. Default is `AI.Option.Ground.val.ALARM_STATE.AUTO` (0).
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultAlarmstate(alarmstate)
  self.optionDefault.Alarm=alarmstate or 0
  return self
end

--- Set current Alarm State of the group.
--
-- * 0 = "Auto"
-- * 1 = "Green"
-- * 2 = "Red"
--
-- @param #OPSGROUP self
-- @param #number alarmstate Alarm state of group. Default is 0="Auto".
-- @return #OPSGROUP self
function OPSGROUP:SwitchAlarmstate(alarmstate)

  if self:IsAlive() or self:IsInUtero() then

    if self.isArmygroup or self.isNavygroup  then

      self.option.Alarm=alarmstate or self.optionDefault.Alarm

      if self:IsInUtero() then
        self:T2(self.lid..string.format("Setting current Alarm State=%d when GROUP is SPAWNED", self.option.Alarm))
      else

        if self.option.Alarm==0 then
          self.group:OptionAlarmStateAuto()
        elseif self.option.Alarm==1 then
          self.group:OptionAlarmStateGreen()
        elseif self.option.Alarm==2 then
          self.group:OptionAlarmStateRed()
        else
          self:T("ERROR: Unknown Alarm State! Setting to AUTO")
          self.group:OptionAlarmStateAuto()
          self.option.Alarm=0
        end

        self:T(self.lid..string.format("Setting current Alarm State=%d (0=Auto, 1=Green, 2=Red)", self.option.Alarm))

      end

    end
  else
    self:T(self.lid.."WARNING: Cannot switch Alarm State! Group is not alive.")
  end

  return self
end

--- Get current Alarm State of the group.
-- @param #OPSGROUP self
-- @return #number Current Alarm State.
function OPSGROUP:GetAlarmstate()
  return self.option.Alarm or self.optionDefault.Alarm
end

--- Set the default EPLRS for the group.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true`, EPLRS is on by default. If `false` default EPLRS setting is off. If `nil`, default is on if group has EPLRS and off if it does not have a datalink.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultEPLRS(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionDefault.EPLRS=self.isEPLRS
  else
    self.optionDefault.EPLRS=OnOffSwitch
  end

  return self
end

--- Switch EPLRS datalink on or off.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true` or `nil`, switch EPLRS on. If `false` EPLRS switched off.
-- @return #OPSGROUP self
function OPSGROUP:SwitchEPLRS(OnOffSwitch)

  if self:IsAlive() or self:IsInUtero() then

    if OnOffSwitch==nil then

      self.option.EPLRS=self.optionDefault.EPLRS

    else

      self.option.EPLRS=OnOffSwitch

    end

    if self:IsInUtero() then
      self:T2(self.lid..string.format("Setting current EPLRS=%s when GROUP is SPAWNED", tostring(self.option.EPLRS)))
    else

      self.group:CommandEPLRS(self.option.EPLRS)
      self:T(self.lid..string.format("Setting current EPLRS=%s", tostring(self.option.EPLRS)))

    end
  else
    self:E(self.lid.."WARNING: Cannot switch EPLRS! Group is not alive")
  end

  return self
end

--- Get current EPLRS state.
-- @param #OPSGROUP self
-- @return #boolean If `true`, EPLRS is on.
function OPSGROUP:GetEPLRS()
  return self.option.EPLRS or self.optionDefault.EPLRS
end

--- Set the default emission state for the group.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true`, EPLRS is on by default. If `false` default EPLRS setting is off. If `nil`, default is on if group has EPLRS and off if it does not have a datalink.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultEmission(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionDefault.Emission=true
  else
    self.optionDefault.Emission=OnOffSwitch
  end

  return self
end

--- Switch emission on or off.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true` or `nil`, switch emission on. If `false` emission switched off.
-- @return #OPSGROUP self
function OPSGROUP:SwitchEmission(OnOffSwitch)

  if self:IsAlive() or self:IsInUtero() then

    if OnOffSwitch==nil then

      self.option.Emission=self.optionDefault.Emission

    else

      self.option.Emission=OnOffSwitch

    end

    if self:IsInUtero() then
      self:T2(self.lid..string.format("Setting current EMISSION=%s when GROUP is SPAWNED", tostring(self.option.Emission)))
    else

      self.group:EnableEmission(self.option.Emission)
      self:T(self.lid..string.format("Setting current EMISSION=%s", tostring(self.option.Emission)))

    end
  else
    self:E(self.lid.."WARNING: Cannot switch Emission! Group is not alive")
  end

  return self
end

--- Get current emission state.
-- @param #OPSGROUP self
-- @return #boolean If `true`, emission is on.
function OPSGROUP:GetEmission()
  return self.option.Emission or self.optionDefault.Emission
end

--- Set the default invisible for the group.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true`, group is ivisible by default.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultInvisible(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionDefault.Invisible=true
  else
    self.optionDefault.Invisible=OnOffSwitch
  end

  return self
end

--- Switch invisibility on or off.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true` or `nil`, switch invisibliity on. If `false` invisibility switched off.
-- @return #OPSGROUP self
function OPSGROUP:SwitchInvisible(OnOffSwitch)

  if self:IsAlive() or self:IsInUtero() then

    if OnOffSwitch==nil then

      self.option.Invisible=self.optionDefault.Invisible

    else

      self.option.Invisible=OnOffSwitch

    end

    if self:IsInUtero() then
      self:T2(self.lid..string.format("Setting current INVISIBLE=%s when GROUP is SPAWNED", tostring(self.option.Invisible)))
    else

      self.group:SetCommandInvisible(self.option.Invisible)
      self:T(self.lid..string.format("Setting current INVISIBLE=%s", tostring(self.option.Invisible)))

    end
  else
    self:E(self.lid.."WARNING: Cannot switch Invisible! Group is not alive")
  end

  return self
end


--- Set the default immortal for the group.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true`, group is immortal by default.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultImmortal(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionDefault.Immortal=true
  else
    self.optionDefault.Immortal=OnOffSwitch
  end

  return self
end

--- Switch immortality on or off.
-- @param #OPSGROUP self
-- @param #boolean OnOffSwitch If `true` or `nil`, switch immortality on. If `false` immortality switched off.
-- @return #OPSGROUP self
function OPSGROUP:SwitchImmortal(OnOffSwitch)

  if self:IsAlive() or self:IsInUtero() then

    if OnOffSwitch==nil then

      self.option.Immortal=self.optionDefault.Immortal

    else

      self.option.Immortal=OnOffSwitch

    end

    if self:IsInUtero() then
      self:T2(self.lid..string.format("Setting current IMMORTAL=%s when GROUP is SPAWNED", tostring(self.option.Immortal)))
    else

      self.group:SetCommandImmortal(self.option.Immortal)
      self:T(self.lid..string.format("Setting current IMMORTAL=%s", tostring(self.option.Immortal)))

    end
  else
    self:E(self.lid.."WARNING: Cannot switch Immortal! Group is not alive")
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SETTINGS FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set default TACAN parameters.
-- @param #OPSGROUP self
-- @param #number Channel TACAN channel. Default is 74.
-- @param #string Morse Morse code. Default "XXX".
-- @param #string UnitName Name of the unit acting as beacon.
-- @param #string Band TACAN mode. Default is "X" for ground and "Y" for airborne units.
-- @param #boolean OffSwitch If true, TACAN is off by default.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultTACAN(Channel, Morse, UnitName, Band, OffSwitch)

  self.tacanDefault={}
  self.tacanDefault.Channel=Channel or 74
  self.tacanDefault.Morse=Morse or "XXX"
  self.tacanDefault.BeaconName=UnitName

  if self:IsFlightgroup() then
    Band=Band or "Y"
  else
    Band=Band or "X"
  end
  self.tacanDefault.Band=Band


  if OffSwitch then
    self.tacanDefault.On=false
  else
    self.tacanDefault.On=true
  end

  return self
end


--- Activate/switch TACAN beacon settings.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Beacon Tacan TACAN data table. Default is the default TACAN settings.
-- @return #OPSGROUP self
function OPSGROUP:_SwitchTACAN(Tacan)

  if Tacan then

    self:SwitchTACAN(Tacan.Channel, Tacan.Morse, Tacan.BeaconName, Tacan.Band)

  else

    if self.tacanDefault.On then
      self:SwitchTACAN()
    else
      self:TurnOffTACAN()
    end

  end

end

--- Activate/switch TACAN beacon settings.
-- @param #OPSGROUP self
-- @param #number Channel TACAN Channel.
-- @param #string Morse TACAN morse code. Default is the value set in @{#OPSGROUP.SetDefaultTACAN} or if not set "XXX".
-- @param #string UnitName Name of the unit in the group which should activate the TACAN beacon. Can also be given as #number to specify the unit number. Default is the first unit of the group.
-- @param #string Band TACAN channel mode "X" or "Y". Default is "Y" for aircraft and "X" for ground and naval groups.
-- @return #OPSGROUP self
function OPSGROUP:SwitchTACAN(Channel, Morse, UnitName, Band)

  if self:IsInUtero() then

    self:T(self.lid..string.format("Switching TACAN to DEFAULT when group is spawned"))
    self:SetDefaultTACAN(Channel, Morse, UnitName, Band)

  elseif self:IsAlive() then

    Channel=Channel or self.tacanDefault.Channel
    Morse=Morse or self.tacanDefault.Morse
    Band=Band or self.tacanDefault.Band
    UnitName=UnitName or self.tacanDefault.BeaconName
    local unit=self:GetUnit(1)  --Wrapper.Unit#UNIT

    if UnitName then
      if type(UnitName)=="number" then
        unit=self.group:GetUnit(UnitName)
      else
        unit=UNIT:FindByName(UnitName)
      end
    end

    if not unit then
      self:T(self.lid.."WARNING: Could not get TACAN unit. Trying first unit in the group")
      unit=self:GetUnit(1)
    end

    if unit and unit:IsAlive() then

      -- Unit ID.
      local UnitID=unit:GetID()

      -- Type
      local Type=BEACON.Type.TACAN

      -- System
      local System=BEACON.System.TACAN
      if self:IsFlightgroup() then
        System=BEACON.System.TACAN_TANKER_Y
      end

      -- Tacan frequency.
      local Frequency=UTILS.TACANToFrequency(Channel, Band)

      -- Activate beacon.
      unit:CommandActivateBeacon(Type, System, Frequency, UnitID, Channel, Band, true, Morse, true)

      -- Update info.
      self.tacan.Channel=Channel
      self.tacan.Morse=Morse
      self.tacan.Band=Band
      self.tacan.BeaconName=unit:GetName()
      self.tacan.BeaconUnit=unit
      self.tacan.On=true

      -- Debug info.
      self:T(self.lid..string.format("Switching TACAN to Channel %d%s Morse %s on unit %s", self.tacan.Channel, self.tacan.Band, tostring(self.tacan.Morse), self.tacan.BeaconName))

    else
      self:T(self.lid.."ERROR: Cound not set TACAN! Unit is not alive")
    end

  else
    self:T(self.lid.."ERROR: Cound not set TACAN! Group is not alive and not in utero any more")
  end

  return self
end

--- Deactivate TACAN beacon.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:TurnOffTACAN()

  if self.tacan.BeaconUnit and self.tacan.BeaconUnit:IsAlive() then
    self.tacan.BeaconUnit:CommandDeactivateBeacon()
  end

  self:T(self.lid..string.format("Switching TACAN OFF"))
  self.tacan.On=false

end

--- Get current TACAN parameters.
-- @param #OPSGROUP self
-- @return #number TACAN channel.
-- @return #string TACAN Morse code.
-- @return #string TACAN band ("X" or "Y").
-- @return #boolean TACAN is On (true) or Off (false).
-- @return #string UnitName Name of the unit acting as beacon.
function OPSGROUP:GetTACAN()
  return self.tacan.Channel, self.tacan.Morse, self.tacan.Band, self.tacan.On, self.tacan.BeaconName
end

--- Get current TACAN parameters.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Beacon TACAN beacon.
function OPSGROUP:GetBeaconTACAN()
  return self.tacan
end


--- Set default ICLS parameters.
-- @param #OPSGROUP self
-- @param #number Channel ICLS channel. Default is 1.
-- @param #string Morse Morse code. Default "XXX".
-- @param #string UnitName Name of the unit acting as beacon.
-- @param #boolean OffSwitch If true, TACAN is off by default.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultICLS(Channel, Morse, UnitName, OffSwitch)

  self.iclsDefault={}
  self.iclsDefault.Channel=Channel or 1
  self.iclsDefault.Morse=Morse or "XXX"
  self.iclsDefault.BeaconName=UnitName

  if OffSwitch then
    self.iclsDefault.On=false
  else
    self.iclsDefault.On=true
  end

  return self
end


--- Activate/switch ICLS beacon settings.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Beacon Icls ICLS data table.
-- @return #OPSGROUP self
function OPSGROUP:_SwitchICLS(Icls)

  if Icls then

    self:SwitchICLS(Icls.Channel, Icls.Morse, Icls.BeaconName)

  else

    if self.iclsDefault.On then
      self:SwitchICLS()
    else
      self:TurnOffICLS()
    end

  end

end

--- Activate/switch ICLS beacon settings.
-- @param #OPSGROUP self
-- @param #number Channel ICLS Channel. Default is what is set in `SetDefaultICLS()` so usually channel 1.
-- @param #string Morse ICLS morse code. Default is what is set in `SetDefaultICLS()` so usually "XXX".
-- @param #string UnitName Name of the unit in the group which should activate the ICLS beacon. Can also be given as #number to specify the unit number. Default is the first unit of the group.
-- @return #OPSGROUP self
function OPSGROUP:SwitchICLS(Channel, Morse, UnitName)

  if self:IsInUtero() then

    self:SetDefaultICLS(Channel,Morse,UnitName)

    self:T2(self.lid..string.format("Switching ICLS to Channel %d Morse %s on unit %s when GROUP is SPAWNED", self.iclsDefault.Channel, tostring(self.iclsDefault.Morse), tostring(self.iclsDefault.BeaconName)))

  elseif self:IsAlive() then

    Channel=Channel or self.iclsDefault.Channel
    Morse=Morse or self.iclsDefault.Morse
    local unit=self:GetUnit(1)  --Wrapper.Unit#UNIT

    if UnitName then
      if type(UnitName)=="number" then
        unit=self:GetUnit(UnitName)
      else
        unit=UNIT:FindByName(UnitName)
      end
    end

    if not unit then
      self:T(self.lid.."WARNING: Could not get ICLS unit. Trying first unit in the group")
      unit=self:GetUnit(1)
    end

    if unit and unit:IsAlive() then

      -- Unit ID.
      local UnitID=unit:GetID()

      -- Activate beacon.
      unit:CommandActivateICLS(Channel, UnitID, Morse)

      -- Update info.
      self.icls.Channel=Channel
      self.icls.Morse=Morse
      self.icls.Band=nil
      self.icls.BeaconName=unit:GetName()
      self.icls.BeaconUnit=unit
      self.icls.On=true

      -- Debug info.
      self:T(self.lid..string.format("Switching ICLS to Channel %d Morse %s on unit %s", self.icls.Channel, tostring(self.icls.Morse), self.icls.BeaconName))

    else
      self:T(self.lid.."ERROR: Cound not set ICLS! Unit is not alive.")
    end

  end

  return self
end

--- Deactivate ICLS beacon.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:TurnOffICLS()

  if self.icls.BeaconUnit and self.icls.BeaconUnit:IsAlive() then
    self.icls.BeaconUnit:CommandDeactivateICLS()
  end

  self:T(self.lid..string.format("Switching ICLS OFF"))
  self.icls.On=false

end


--- Set default Radio frequency and modulation.
-- @param #OPSGROUP self
-- @param #number Frequency Radio frequency in MHz. Default 251 MHz.
-- @param #number Modulation Radio modulation. Default `radio.modulation.AM`.
-- @param #boolean OffSwitch If true, radio is OFF by default.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultRadio(Frequency, Modulation, OffSwitch)

  self.radioDefault={}
  self.radioDefault.Freq=Frequency or 251
  self.radioDefault.Modu=Modulation or radio.modulation.AM
  if OffSwitch then
    self.radioDefault.On=false
  else
    self.radioDefault.On=true
  end

  return self
end

--- Get current Radio frequency and modulation.
-- @param #OPSGROUP self
-- @return #number Radio frequency in MHz or nil.
-- @return #number Radio modulation or nil.
-- @return #boolean If true, the radio is on. Otherwise, radio is turned off.
function OPSGROUP:GetRadio()
  return self.radio.Freq, self.radio.Modu, self.radio.On
end

--- Turn radio on or switch frequency/modulation.
-- @param #OPSGROUP self
-- @param #number Frequency Radio frequency in MHz. Default is value set in `SetDefaultRadio` (usually 251 MHz).
-- @param #number Modulation Radio modulation. Default is value set in `SetDefaultRadio` (usually `radio.modulation.AM`).
-- @return #OPSGROUP self
function OPSGROUP:SwitchRadio(Frequency, Modulation)

  if self:IsInUtero() then

    -- Set default radio.
    self:SetDefaultRadio(Frequency, Modulation)

    -- Debug info.
    self:T2(self.lid..string.format("Switching radio to frequency %.3f MHz %s when GROUP is SPAWNED", self.radioDefault.Freq, UTILS.GetModulationName(self.radioDefault.Modu)))

  elseif self:IsAlive() then

    Frequency=Frequency or self.radioDefault.Freq
    Modulation=Modulation or self.radioDefault.Modu

    if self:IsFlightgroup() and not self.radio.On then
      self.group:SetOption(AI.Option.Air.id.SILENCE, false)
    end

    -- Give command
    self.group:CommandSetFrequency(Frequency, Modulation)

    -- Update current settings.
    self.radio.Freq=Frequency
    self.radio.Modu=Modulation
    self.radio.On=true

    -- Debug info.
    self:T(self.lid..string.format("Switching radio to frequency %.3f MHz %s", self.radio.Freq, UTILS.GetModulationName(self.radio.Modu)))

  else
    self:T(self.lid.."ERROR: Cound not set Radio! Group is not alive or not in utero any more")
  end

  return self
end

--- Turn radio off.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:TurnOffRadio()

  if self:IsAlive() then

    if self:IsFlightgroup() then

      -- Set group to be silient.
      self.group:SetOption(AI.Option.Air.id.SILENCE, true)

      -- Radio is off.
      self.radio.On=false

      self:T(self.lid..string.format("Switching radio OFF"))
    else
      self:T(self.lid.."ERROR: Radio can only be turned off for aircraft!")
    end

  end

  return self
end



--- Set default formation.
-- @param #OPSGROUP self
-- @param #number Formation The formation the groups flies in.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultFormation(Formation)

  self.optionDefault.Formation=Formation

  return self
end

--- Switch to a specific formation.
-- @param #OPSGROUP self
-- @param #number Formation New formation the group will fly in. Default is the setting of `SetDefaultFormation()`.
-- @return #OPSGROUP self
function OPSGROUP:SwitchFormation(Formation)

  if self:IsAlive() then

    Formation=Formation or self.optionDefault.Formation

    if self:IsFlightgroup() then

      self.group:SetOption(AI.Option.Air.id.FORMATION, Formation)

    elseif self.isArmygroup then

      -- Polymorphic and overwritten in ARMYGROUP.

    else
      self:T(self.lid.."ERROR: Formation can only be set for aircraft or ground units!")
      return self
    end

    -- Set current formation.
    self.option.Formation=Formation

    -- Debug info.
    self:T(self.lid..string.format("Switching formation to %s", tostring(self.option.Formation)))

  end

  return self
end



--- Set default callsign.
-- @param #OPSGROUP self
-- @param #number CallsignName Callsign name.
-- @param #number CallsignNumber Callsign number. Default 1.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultCallsign(CallsignName, CallsignNumber)

  self:T(self.lid..string.format("Setting Default callsign %s-%s", tostring(CallsignName), tostring(CallsignNumber)))

  self.callsignDefault={} --#OPSGROUP.Callsign
  self.callsignDefault.NumberSquad=CallsignName
  self.callsignDefault.NumberGroup=CallsignNumber or 1
  self.callsignDefault.NameSquad=UTILS.GetCallsignName(self.callsign.NumberSquad)
  
  --self:I(self.lid..string.format("Default callsign=%s", self.callsignDefault.NameSquad))

  return self
end

--- Switch to a specific callsign.
-- @param #OPSGROUP self
-- @param #number CallsignName Callsign name.
-- @param #number CallsignNumber Callsign number.
-- @return #OPSGROUP self
function OPSGROUP:SwitchCallsign(CallsignName, CallsignNumber)

  if self:IsInUtero() then

    -- Set default callsign. We switch to this when group is spawned.
    self:SetDefaultCallsign(CallsignName, CallsignNumber)
    --self.callsign=UTILS.DeepCopy(self.callsignDefault)

  elseif self:IsAlive() then

    CallsignName=CallsignName or self.callsignDefault.NumberSquad
    CallsignNumber=CallsignNumber or self.callsignDefault.NumberGroup

    -- Set current callsign.
    self.callsign.NumberSquad=CallsignName
    self.callsign.NumberGroup=CallsignNumber

    -- Debug.
    self:T(self.lid..string.format("Switching callsign to %d-%d", self.callsign.NumberSquad, self.callsign.NumberGroup))

    -- Give command to change the callsign.
    self.group:CommandSetCallsign(self.callsign.NumberSquad, self.callsign.NumberGroup)

    -- Callsign of the group, e.g. Colt-1
    self.callsignName=UTILS.GetCallsignName(self.callsign.NumberSquad).."-"..self.callsign.NumberGroup
    self.callsign.NameSquad=UTILS.GetCallsignName(self.callsign.NumberSquad)

    -- Set callsign of elements.
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element.status~=OPSGROUP.ElementStatus.DEAD then
        element.callsign=element.unit:GetCallsign()
      end
    end

  else
    self:T(self.lid.."ERROR: Group is not alive and not in utero! Cannot switch callsign")
  end

  return self
end

--- Get callsign of the first element alive.
-- @param #OPSGROUP self
-- @param #boolean ShortCallsign If true, append major flight number only
-- @param #boolean Keepnumber (Player only) If true, and using a customized callsign in the #GROUP name after an #-sign, use all of that information.
-- @param #table CallsignTranslations (optional) Translation table between callsigns
-- @return #string Callsign name, e.g. Uzi11, or "Ghostrider11".
function OPSGROUP:GetCallsignName(ShortCallsign,Keepnumber,CallsignTranslations)

  local element=self:GetElementAlive()

  if element then
    self:T2(self.lid..string.format("Callsign %s", tostring(element.callsign)))
    local name=element.callsign or "Ghostrider11"
    name=name:gsub("-", "")
    if self.group:IsPlayer() or CallsignTranslations then
      name=self.group:GetCustomCallSign(ShortCallsign,Keepnumber,CallsignTranslations)
    end
    return name
  end

  return "Ghostrider11"
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Element and Group Status Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if all elements of the group have the same status (or are dead).
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:_UpdatePosition()

  if self:IsExist() then

    -- Backup last state to monitor differences.
    self.positionLast=self.position or self:GetVec3()
    self.headingLast=self.heading or self:GetHeading()
    self.orientXLast=self.orientX or self:GetOrientationX()
  self.velocityLast=self.velocity or self.group:GetVelocityMPS()

    -- Current state.
    self.position=self:GetVec3()
    self.heading=self:GetHeading()
    self.orientX=self:GetOrientationX()
    self.velocity=self:GetVelocity()

    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      element.vec3=self:GetVec3(element.name)
    end

    -- Update time.
    local Tnow=timer.getTime()
    self.dTpositionUpdate=self.TpositionUpdate and Tnow-self.TpositionUpdate or 0
    self.TpositionUpdate=Tnow

    if not self.traveldist then
      self.traveldist=0
    end

    -- Travel distance since last check.
    self.travelds=UTILS.VecNorm(UTILS.VecSubstract(self.position, self.positionLast))

    -- Add up travelled distance.
    self.traveldist=self.traveldist+self.travelds

  end

  return self
end

--- Check if all elements of the group have the same status (or are dead).
-- @param #OPSGROUP self
-- @param #string unitname Name of unit.
function OPSGROUP:_AllSameStatus(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if element.status==OPSGROUP.ElementStatus.DEAD then
      -- Do nothing. Element is already dead and does not count.
    elseif element.status~=status then
      -- At least this element has a different status.
      return false
    end

  end

  return true
end

--- Check if all elements of the group have the same status (or are dead).
-- @param #OPSGROUP self
-- @param #string status Status to check.
-- @return #boolean If true, all elements have a similar status.
function OPSGROUP:_AllSimilarStatus(status)

  -- Check if all are dead.
  if status==OPSGROUP.ElementStatus.DEAD then
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element.status~=OPSGROUP.ElementStatus.DEAD then
        -- At least one is still alive.
        return false
      end
    end
    return true
  end

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    self:T2(self.lid..string.format("Status=%s, element %s status=%s", status, element.name, element.status))

    -- Dead units dont count ==> We wont return false for those.
    if element.status~=OPSGROUP.ElementStatus.DEAD then

      ----------
      -- ALIVE
      ----------

      if status==OPSGROUP.ElementStatus.INUTERO then

        -- Element INUTERO: Check that ALL others are also INUTERO
        if element.status~=status then
          return false
        end


      elseif status==OPSGROUP.ElementStatus.SPAWNED then

        -- Element SPAWNED: Check that others are not still IN UTERO
        if element.status~=status and
          element.status==OPSGROUP.ElementStatus.INUTERO  then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.PARKING then

        -- Element PARKING: Check that the other are not still SPAWNED
        if element.status~=status or
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.ENGINEON then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.TAXIING then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING or
          element.status==OPSGROUP.ElementStatus.ENGINEON) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.TAKEOFF then

        -- Element TAKEOFF: Check that the other are not still SPAWNED, PARKING or TAXIING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING or
          element.status==OPSGROUP.ElementStatus.ENGINEON or
          element.status==OPSGROUP.ElementStatus.TAXIING) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.AIRBORNE then

        -- Element AIRBORNE: Check that the other are not still SPAWNED, PARKING, TAXIING or TAKEOFF
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING or
          element.status==OPSGROUP.ElementStatus.ENGINEON or
          element.status==OPSGROUP.ElementStatus.TAXIING or
          element.status==OPSGROUP.ElementStatus.TAKEOFF) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.LANDED then

        -- Element LANDED: check that the others are not still AIRBORNE or LANDING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.AIRBORNE or
          element.status==OPSGROUP.ElementStatus.LANDING) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.ARRIVED then

        -- Element ARRIVED: check that the others are not still AIRBORNE, LANDING, or LANDED (taxiing).
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.AIRBORNE or
          element.status==OPSGROUP.ElementStatus.LANDING  or
          element.status==OPSGROUP.ElementStatus.LANDED)  then
          return false
        end

      end

    else
      -- Element is dead. We don't care unless all are dead.
    end --DEAD

  end

  -- Debug info.
  self:T2(self.lid..string.format("All %d elements have similar status %s ==> returning TRUE", #self.elements, status))

  return true
end

--- Check if all elements of the group have the same status or are dead.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element element Element.
-- @param #string newstatus New status of element
-- @param Wrapper.Airbase#AIRBASE airbase Airbase if applicable.
function OPSGROUP:_UpdateStatus(element, newstatus, airbase)

  -- Old status.
  local oldstatus=element.status

  -- Update status of element.
  element.status=newstatus

  -- Debug
  self:T3(self.lid..string.format("UpdateStatus element=%s: %s --> %s", element.name, oldstatus, newstatus))
  for _,_element in pairs(self.elements) do
    local Element=_element -- #OPSGROUP.Element
    self:T3(self.lid..string.format("Element %s: %s", Element.name, Element.status))
  end

  if newstatus==OPSGROUP.ElementStatus.INUTERO then
    ---
    -- INUTERO
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:InUtero()
    end

  elseif newstatus==OPSGROUP.ElementStatus.SPAWNED then
    ---
    -- SPAWNED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Spawned()
    end

  elseif newstatus==OPSGROUP.ElementStatus.PARKING then
    ---
    -- PARKING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Parking()
    end

  elseif newstatus==OPSGROUP.ElementStatus.ENGINEON then
    ---
    -- ENGINEON
    ---

    -- No FLIGHT status. Waiting for taxiing.

  elseif newstatus==OPSGROUP.ElementStatus.TAXIING then
    ---
    -- TAXIING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Taxiing()
    end

  elseif newstatus==OPSGROUP.ElementStatus.TAKEOFF then
    ---
    -- TAKEOFF
    ---

    if self:_AllSimilarStatus(newstatus) then
      -- Trigger takeoff event. Also triggers airborne event.
      self:Takeoff(airbase)
    end

  elseif newstatus==OPSGROUP.ElementStatus.AIRBORNE then
    ---
    -- AIRBORNE
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Airborne()
    end

  elseif newstatus==OPSGROUP.ElementStatus.LANDED then
    ---
    -- LANDED
    ---

    if self:_AllSimilarStatus(newstatus) then
      if self:IsLandingAt() then
        self:LandedAt()
      else
        self:Landed(airbase)
      end
    end

  elseif newstatus==OPSGROUP.ElementStatus.ARRIVED then
    ---
    -- ARRIVED
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsLanded() then
        self:Arrived()
      elseif self:IsAirborne() then
        self:Landed()
        self:Arrived()
      end

    end

  elseif newstatus==OPSGROUP.ElementStatus.DEAD then
    ---
    -- DEAD
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Dead()
    end

  end
end

--- Set status for all elements (except dead ones).
-- @param #OPSGROUP self
-- @param #string status Element status.
function OPSGROUP:_SetElementStatusAll(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if element.status~=OPSGROUP.ElementStatus.DEAD then
      element.status=status
    end
  end

end

--- Get the element of a group.
-- @param #OPSGROUP self
-- @param #string unitname Name of unit.
-- @return #OPSGROUP.Element The element.
function OPSGROUP:GetElementByName(unitname)

  if unitname and type(unitname)=="string" then

    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element

      if element.name==unitname then
        return element
      end

    end

  end

  return nil
end

--- Get the bounding box of the element.
-- @param #OPSGROUP self
-- @param #string UnitName Name of unit.
-- @return Core.Zone#ZONE_POLYGON Bounding box polygon zone.
function OPSGROUP:GetElementZoneBoundingBox(UnitName)

  local element=self:GetElementByName(UnitName)

  if element and element.status~=OPSGROUP.ElementStatus.DEAD then

    -- Create a new zone if necessary.
    element.zoneBoundingbox=element.zoneBoundingbox or ZONE_POLYGON_BASE:New(element.name.." Zone Bounding Box", {})

    -- Length in meters.
    local l=element.length
    -- Width in meters.
    local w=element.width

    -- Orientation vector.
    local X=self:GetOrientationX(element.name)

    -- Heading in degrees.
    local heading=math.deg(math.atan2(X.z, X.x))

    -- Debug info.
    self:T(self.lid..string.format("Element %s bouding box: l=%d w=%d heading=%d", element.name, l, w, heading))

    -- Set of edges facing "North" at the origin of the map.
    local b={}
    b[1]={x=l/2,  y=-w/2} --DCS#Vec2
    b[2]={x=l/2,  y=w/2}  --DCS#Vec2
    b[3]={x=-l/2, y=w/2}  --DCS#Vec2
    b[4]={x=-l/2, y=-w/2} --DCS#Vec2

    -- Rotate box to match current heading of the unit.
    for i,p in pairs(b) do
      b[i]=UTILS.Vec2Rotate2D(p, heading)
    end

    -- Translate the zone to the positon of the unit.
    local vec2=self:GetVec2(element.name)
    local d=UTILS.Vec2Norm(vec2)
    local h=UTILS.Vec2Hdg(vec2)
    for i,p in pairs(b) do
      b[i]=UTILS.Vec2Translate(p, d, h)
    end

    -- Update existing zone.
    element.zoneBoundingbox:UpdateFromVec2(b)

    return element.zoneBoundingbox
  end

  return nil
end

--- Get the loading zone of the element.
-- @param #OPSGROUP self
-- @param #string UnitName Name of unit.
-- @return Core.Zone#ZONE_POLYGON Bounding box polygon zone.
function OPSGROUP:GetElementZoneLoad(UnitName)

  local element=self:GetElementByName(UnitName)

  if element and element.status~=OPSGROUP.ElementStatus.DEAD then

    element.zoneLoad=element.zoneLoad or ZONE_POLYGON_BASE:New(element.name.." Zone Load", {})

    self:_GetElementZoneLoader(element, element.zoneLoad, self.carrierLoader)

    return element.zoneLoad
  end

  return nil
end

--- Get the unloading zone of the element.
-- @param #OPSGROUP self
-- @param #string UnitName Name of unit.
-- @return Core.Zone#ZONE_POLYGON Bounding box polygon zone.
function OPSGROUP:GetElementZoneUnload(UnitName)

  local element=self:GetElementByName(UnitName)

  if element and element.status~=OPSGROUP.ElementStatus.DEAD then

    element.zoneUnload=element.zoneUnload or ZONE_POLYGON_BASE:New(element.name.." Zone Unload", {})

    self:_GetElementZoneLoader(element, element.zoneUnload, self.carrierUnloader)

    return element.zoneUnload
  end

  return nil
end

--- Get/update the (un-)loading zone of the element.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element Element Element.
-- @param Core.Zone#ZONE_POLYGON Zone The zone.
-- @param #OPSGROUP.CarrierLoader Loader Loader parameters.
-- @return Core.Zone#ZONE_POLYGON Bounding box polygon zone.
function OPSGROUP:_GetElementZoneLoader(Element, Zone, Loader)

  if Element.status~=OPSGROUP.ElementStatus.DEAD then

    local l=Element.length
    local w=Element.width

    -- Orientation 3D vector where the "nose" is pointing.
    local X=self:GetOrientationX(Element.name)

    -- Heading in deg.
    local heading=math.deg(math.atan2(X.z, X.x))

    -- Bounding box at the origin of the map facing "North".
    local b={}

    -- Create polygon rectangles.
    if Loader.type:lower()=="front" then
      table.insert(b, {x= l/2,               y=-Loader.width/2}) -- left, low
      table.insert(b, {x= l/2+Loader.length, y=-Loader.width/2}) -- left, up
      table.insert(b, {x= l/2+Loader.length, y= Loader.width/2}) -- right, up
      table.insert(b, {x= l/2,               y= Loader.width/2}) -- right, low
    elseif Loader.type:lower()=="back" then
      table.insert(b, {x=-l/2,               y=-Loader.width/2}) -- left, low
      table.insert(b, {x=-l/2-Loader.length, y=-Loader.width/2}) -- left, up
      table.insert(b, {x=-l/2-Loader.length, y= Loader.width/2}) -- right, up
      table.insert(b, {x=-l/2,               y= Loader.width/2}) -- right, low
    elseif Loader.type:lower()=="left" then
      table.insert(b, {x= Loader.length/2, y= -w/2})              -- right, up
      table.insert(b, {x= Loader.length/2, y= -w/2-Loader.width}) -- left,  up
      table.insert(b, {x=-Loader.length/2, y= -w/2-Loader.width}) -- left,  down
      table.insert(b, {x=-Loader.length/2, y= -w/2})              -- right, down
    elseif Loader.type:lower()=="right" then
      table.insert(b, {x= Loader.length/2, y=  w/2})              -- right, up
      table.insert(b, {x= Loader.length/2, y=  w/2+Loader.width}) -- left,  up
      table.insert(b, {x=-Loader.length/2, y=  w/2+Loader.width}) -- left,  down
      table.insert(b, {x=-Loader.length/2, y=  w/2})              -- right, down
    else
      -- All aspect. Rectangle around the unit but need to cut out the area of the unit itself.
      b[1]={x= l/2, y=-w/2} --DCS#Vec2
      b[2]={x= l/2, y= w/2} --DCS#Vec2
      b[3]={x=-l/2, y= w/2} --DCS#Vec2
      b[4]={x=-l/2, y=-w/2} --DCS#Vec2
      table.insert(b, {x=b[1].x+Loader.length, y=b[1].y-Loader.width})
      table.insert(b, {x=b[2].x+Loader.length, y=b[2].y+Loader.width})
      table.insert(b, {x=b[3].x-Loader.length, y=b[3].y+Loader.width})
      table.insert(b, {x=b[4].x-Loader.length, y=b[4].y-Loader.width})
    end

    -- Rotate edges to match the current heading of the unit.
    for i,p in pairs(b) do
      b[i]=UTILS.Vec2Rotate2D(p, heading)
    end

    -- Translate box to the current position of the unit.
    local vec2=self:GetVec2(Element.name)
    local d=UTILS.Vec2Norm(vec2)
    local h=UTILS.Vec2Hdg(vec2)

    for i,p in pairs(b) do
      b[i]=UTILS.Vec2Translate(p, d, h)
    end

    -- Update existing zone.
    Zone:UpdateFromVec2(b)

    return Zone
  end

  return nil
end


--- Get the first element of a group, which is alive.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Element The element or `#nil` if no element is alive any more.
function OPSGROUP:GetElementAlive()

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if element.status~=OPSGROUP.ElementStatus.DEAD then
      if element.unit and element.unit:IsAlive() then
        return element
      end
    end
  end

  return nil
end


--- Get number of elements alive.
-- @param #OPSGROUP self
-- @param #string status (Optional) Only count number, which are in a special status.
-- @return #number Number of elements.
function OPSGROUP:GetNelements(status)

  local n=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if element.status~=OPSGROUP.ElementStatus.DEAD then
      if element.unit and element.unit:IsAlive() then
        if status==nil or element.status==status then
          n=n+1
        end
      end
    end
  end


  return n
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element element The element.
-- @return #OPSGROUP.Ammo Ammo data.
function OPSGROUP:GetAmmoElement(element)
  return self:GetAmmoUnit(element.unit)
end

--- Get total amount of ammunition of the whole group.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Ammo Ammo data.
function OPSGROUP:GetAmmoTot()

  local units=self.group:GetUnits()

  local Ammo={} --#OPSGROUP.Ammo
  Ammo.Total=0
  Ammo.Shells=0
  Ammo.Guns=0
  Ammo.Cannons=0
  Ammo.Rockets=0
  Ammo.Bombs=0
  Ammo.Torpedos=0
  Ammo.Missiles=0
  Ammo.MissilesAA=0
  Ammo.MissilesAG=0
  Ammo.MissilesAS=0
  Ammo.MissilesCR=0
  Ammo.MissilesSA=0

  for _,_unit in pairs(units or {}) do
    local unit=_unit --Wrapper.Unit#UNIT

    if unit and unit:IsExist() then

      -- Get ammo of the unit.
      local ammo=self:GetAmmoUnit(unit)

      -- Add up total.
      Ammo.Total=Ammo.Total+ammo.Total
      Ammo.Shells=Ammo.Shells+ammo.Shells
      Ammo.Guns=Ammo.Guns+ammo.Guns
      Ammo.Cannons=Ammo.Cannons+ammo.Cannons
      Ammo.Rockets=Ammo.Rockets+ammo.Rockets
      Ammo.Bombs=Ammo.Bombs+ammo.Bombs
      Ammo.Torpedos=Ammo.Torpedos+ammo.Torpedos
      Ammo.Missiles=Ammo.Missiles+ammo.Missiles
      Ammo.MissilesAA=Ammo.MissilesAA+ammo.MissilesAA
      Ammo.MissilesAG=Ammo.MissilesAG+ammo.MissilesAG
      Ammo.MissilesAS=Ammo.MissilesAS+ammo.MissilesAS
      Ammo.MissilesCR=Ammo.MissilesCR+ammo.MissilesCR
      Ammo.MissilesSA=Ammo.MissilesSA+ammo.MissilesSA

    end

  end

  return Ammo
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #OPSGROUP self
-- @param Wrapper.Unit#UNIT unit The unit object.
-- @param #boolean display Display ammo table as message to all. Default false.
-- @return #OPSGROUP.Ammo Ammo data.
function OPSGROUP:GetAmmoUnit(unit, display)

  -- Default is display false.
  if display==nil then
    display=false
  end

  -- Init counter.
  local nammo=0
  local nshells=0
  local nguns=0
  local ncannons=0
  local nrockets=0
  local nmissiles=0
  local nmissilesAA=0
  local nmissilesAG=0
  local nmissilesAS=0
  local nmissilesSA=0
  local nmissilesBM=0
  local nmissilesCR=0
  local ntorps=0
  local nbombs=0

  unit=unit or self.group:GetUnit(1)

  if unit and unit:IsExist() then

    -- Output.
    local text=string.format("OPSGROUP group %s - unit %s:\n", self.groupname, unit:GetName())

    -- Get ammo table.
    local ammotable=unit:GetAmmo()

    if ammotable then
      local weapons=#ammotable
    
      --self:I(ammotable)
      --UTILS.PrintTableToLog(ammotable)

      -- Loop over all weapons.
      for w=1,weapons do

        -- Number of current weapon.
        local Nammo=ammotable[w]["count"]
      
        -- Range in meters. Seems only to exist for missiles (not shells).
        local rmin=ammotable[w]["desc"]["rangeMin"] or 0
        local rmax=ammotable[w]["desc"]["rangeMaxAltMin"] or 0

        -- Type name of current weapon.
        local Tammo=ammotable[w]["desc"]["typeName"]

        local _weaponString = UTILS.Split(Tammo,"%.")
        local _weaponName   = _weaponString[#_weaponString]

        -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3, torpedo=4
        local Category=ammotable[w].desc.category

        -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
        local MissileCategory=nil
        if Category==Weapon.Category.MISSILE then
          MissileCategory=ammotable[w].desc.missileCategory
        end

        -- We are specifically looking for shells or rockets here.
        if Category==Weapon.Category.SHELL then

          -- Add up all shells.
          nshells=nshells+Nammo
      
          -- Add small and large caliber shells for guns and cannons
          if ammotable[w]["desc"]["warhead"] and ammotable[w]["desc"]["warhead"]["caliber"] then
            local caliber=ammotable[w]["desc"]["warhead"]["caliber"]
            if caliber<25 then
              nguns=nguns+Nammo
            else
              ncannons=ncannons+Nammo
            end
          end

          -- Debug info.
          text=text..string.format("- %d shells of type %s, range=%d - %d meters\n", Nammo, _weaponName, rmin, rmax)

        elseif Category==Weapon.Category.ROCKET then

          -- Add up all rockets.
          nrockets=nrockets+Nammo

          -- Debug info.
          text=text..string.format("- %d rockets of type %s, \n", Nammo, _weaponName, rmin, rmax)

        elseif Category==Weapon.Category.BOMB then

          -- Add up all rockets.
          nbombs=nbombs+Nammo

          -- Debug info.
          text=text..string.format("- %d bombs of type %s\n", Nammo, _weaponName)

        elseif Category==Weapon.Category.MISSILE then

          -- Add up all cruise missiles (category 5)
          if MissileCategory==Weapon.MissileCategory.AAM then
            nmissiles=nmissiles+Nammo
            nmissilesAA=nmissilesAA+Nammo
          elseif MissileCategory==Weapon.MissileCategory.SAM then
            nmissiles=nmissiles+Nammo
            nmissilesSA=nmissilesSA+Nammo
          elseif MissileCategory==Weapon.MissileCategory.ANTI_SHIP then
            nmissiles=nmissiles+Nammo
            nmissilesAS=nmissilesAS+Nammo
          elseif MissileCategory==Weapon.MissileCategory.BM then
            nmissiles=nmissiles+Nammo
            nmissilesBM=nmissilesBM+Nammo
          elseif MissileCategory==Weapon.MissileCategory.CRUISE then
            nmissiles=nmissiles+Nammo
            nmissilesCR=nmissilesCR+Nammo
          elseif MissileCategory==Weapon.MissileCategory.OTHER then
            nmissiles=nmissiles+Nammo
            nmissilesAG=nmissilesAG+Nammo
          end

          -- Debug info.
          text=text..string.format("- %d %s missiles of type %s, range=%d - %d meters\n", Nammo, self:_MissileCategoryName(MissileCategory), _weaponName, rmin, rmax)

        elseif Category==Weapon.Category.TORPEDO then

          -- Add up all rockets.
          ntorps=ntorps+Nammo

          -- Debug info.
          text=text..string.format("- %d torpedos of type %s\n", Nammo, _weaponName)

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

  end

  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles+nbombs+ntorps

  local ammo={} --#OPSGROUP.Ammo
  ammo.Total=nammo
  ammo.Shells=nshells
  ammo.Guns=nguns
  ammo.Cannons=ncannons
  ammo.Rockets=nrockets
  ammo.Bombs=nbombs
  ammo.Torpedos=ntorps
  ammo.Missiles=nmissiles
  ammo.MissilesAA=nmissilesAA
  ammo.MissilesAG=nmissilesAG
  ammo.MissilesAS=nmissilesAS
  ammo.MissilesCR=nmissilesCR
  ammo.MissilesBM=nmissilesBM
  ammo.MissilesSA=nmissilesSA

  return ammo
end

--- Returns a name of a missile category.
-- @param #OPSGROUP self
-- @param #number categorynumber Number of missile category from weapon missile category enumerator. See https://wiki.hoggitworld.com/view/DCS_Class_Weapon
-- @return #string Missile category name.
function OPSGROUP:_MissileCategoryName(categorynumber)
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

--- Set passed final waypoint value.
-- @param #OPSGROUP self
-- @param #boolean final If `true`, final waypoint was passed.
-- @param #string comment Some comment as to why the final waypoint was passed.
function OPSGROUP:_PassedFinalWaypoint(final, comment)

  -- Debug info.
  self:T(self.lid..string.format("Passed final waypoint=%s [from %s]: comment \"%s\"", tostring(final), tostring(self.passedfinalwp), tostring(comment)))

  if final==true and not self.passedfinalwp then
    self:PassedFinalWaypoint()
  end

  -- Set value.
  self.passedfinalwp=final
end


--- Get coordinate from an object.
-- @param #OPSGROUP self
-- @param Wrapper.Object#OBJECT Object The object.
-- @return Core.Point#COORDINATE The coordinate of the object.
function OPSGROUP:_CoordinateFromObject(Object)

  if Object then
    if Object:IsInstanceOf("COORDINATE") then
      return Object
    else
      if Object:IsInstanceOf("POSITIONABLE") or Object:IsInstanceOf("ZONE_BASE") then
        self:T(self.lid.."WARNING: Coordinate is not a COORDINATE but a POSITIONABLE or ZONE. Trying to get coordinate")
        local coord=Object:GetCoordinate()
        return coord
      else
        self:T(self.lid.."ERROR: Coordinate is neither a COORDINATE nor any POSITIONABLE or ZONE!")
      end
    end
  else
    self:T(self.lid.."ERROR: Object passed is nil!")
  end

  return nil
end

--- Check if a unit is an element of the flightgroup.
-- @param #OPSGROUP self
-- @param #string unitname Name of unit.
-- @return #boolean If true, unit is element of the flight group or false if otherwise.
function OPSGROUP:_IsElement(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --Ops.OpsGroup#OPSGROUP.Element

    if element.name==unitname then
      return true
    end

  end

  return false
end

--- Count elements of the group.
-- @param #OPSGROUP self
-- @param #table States (Optional) Only count elements in specific states. Can also be a single state passed as #string.
-- @return #number Number of elements.
function OPSGROUP:CountElements(States)

  if States then
    if type(States)=="string" then
      States={States}
    end
  else
    States=OPSGROUP.ElementStatus
  end

  local IncludeDeads=true

  local N=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if element and (IncludeDeads or element.status~=OPSGROUP.ElementStatus.DEAD) then
      for _,state in pairs(States) do
        if element.status==state then
          N=N+1
          break
        end
      end
    end
  end

  return N
end

--- Add a unit/element to the OPS group.
-- @param #OPSGROUP self
-- @param #string unitname Name of unit.
-- @return #OPSGROUP.Element The element or nil.
function OPSGROUP:_AddElementByName(unitname)

  local unit=UNIT:FindByName(unitname)

  if unit then
  
    -- Element table.
    local element=self:GetElementByName(unitname)

    -- Add element to table.
    if element then
      -- We already know this element.
    else
      -- Add a new element.
      element={}
      element.status=OPSGROUP.ElementStatus.INUTERO
      table.insert(self.elements, element)
    end

    -- Name and status.
    element.name=unitname

    -- Unit and group.
    element.unit=unit
    element.DCSunit=Unit.getByName(unitname)
    element.gid=element.DCSunit:getNumber()
    element.uid=element.DCSunit:getID()
    --element.group=unit:GetGroup()
    element.controller=element.DCSunit:getController()
    element.Nhit=0
    element.opsgroup=self

    -- Get unit template.
    local unittemplate=unit:GetTemplate()

    if unittemplate==nil then
      if element.DCSunit:getPlayerName() then
        element.skill="Client"
      end
    else
      element.skill=unittemplate~=nil and unittemplate.skill or "Unknown"
    end

    -- Skill etc.
    if element.skill=="Client" or element.skill=="Player" then
      element.ai=false
      element.client=CLIENT:FindByName(unitname)
      element.playerName=element.DCSunit:getPlayerName()
    else
      element.ai=true
    end

    -- Descriptors and type/category.
    element.descriptors=unit:GetDesc()
    element.category=unit:GetUnitCategory()
    element.categoryname=unit:GetCategoryName()
    element.typename=unit:GetTypeName()

    -- Describtors.
    --self:I({desc=element.descriptors})

    -- Ammo.
    element.ammo0=self:GetAmmoUnit(unit, false)

    -- Life points.
    element.life=unit:GetLife()
    element.life0=math.max(unit:GetLife0(), element.life) -- Some units report a life0 that is smaller than its initial life points.

    -- Size and dimensions.
    element.size, element.length, element.height, element.width=unit:GetObjectSize()

    -- Weight and cargo.
    element.weightEmpty=element.descriptors.massEmpty or 666

    if self.isArmygroup then

      element.weightMaxTotal=element.weightEmpty+10*95 --If max mass is not given, we assume 10 soldiers.

    elseif self.isNavygroup then

      element.weightMaxTotal=element.weightEmpty+10*1000

    else

      -- Looks like only aircraft have a massMax value in the descriptors.
      element.weightMaxTotal=element.descriptors.massMax or element.weightEmpty+8*95 --If max mass is not given, we assume 8 soldiers.

    end

    -- Max cargo weight:
    unit:SetCargoBayWeightLimit()
    element.weightMaxCargo=unit.__.CargoBayWeightLimit

    -- Cargo bay (empty).
    if element.cargoBay then
      -- After a respawn, the cargo bay might not be empty!
      element.weightCargo=self:GetWeightCargo(element.name, false)
    else
      element.cargoBay={}
      element.weightCargo=0
    end
    element.weight=element.weightEmpty+element.weightCargo
    
    -- FLIGHTGROUP specific.
    element.callsign=element.unit:GetCallsign()
    element.fuelmass=element.fuelmass0 or 99999
    element.fuelrel=element.unit:GetFuel() or 1
    
    if self.isFlightgroup and unittemplate then
      element.modex=unittemplate.onboard_num
      element.payload=unittemplate.payload
      element.pylons=unittemplate.payload and unittemplate.payload.pylons or nil
      element.fuelmass0=unittemplate.payload and unittemplate.payload.fuel or 0
    else
      element.callsign="Peter-1-1"
      element.modex="000"
      element.payload={}
      element.pylons={}
    end

    -- Debug text.
    local text=string.format("Adding element %s: status=%s, skill=%s, life=%.1f/%.1f category=%s (%d), type=%s, size=%.1f (L=%.1f H=%.1f W=%.1f), weight=%.1f/%.1f (cargo=%.1f/%.1f)",
    element.name, element.status, element.skill, element.life, element.life0, element.categoryname, element.category, element.typename,
    element.size, element.length, element.height, element.width, element.weight, element.weightMaxTotal, element.weightCargo, element.weightMaxCargo)
    self:T(self.lid..text)

    -- Trigger spawned event if alive.
    if unit:IsAlive() and element.status~=OPSGROUP.ElementStatus.SPAWNED then
      -- This needs to be slightly delayed (or moved elsewhere) or the first element will always trigger the group spawned event as it is not known that more elements are in the group.
      self:__ElementSpawned(0.05, element)
    end

    return element
  end

  return nil
end

--- Set the template of the group.
-- @param #OPSGROUP self
-- @param #table Template Template to set. Default is from the GROUP.
-- @return #OPSGROUP self
function OPSGROUP:_SetTemplate(Template)

  -- Set the template.
  self.template=Template or UTILS.DeepCopy(_DATABASE:GetGroupTemplate(self.groupname))  --self.group:GetTemplate()

  -- Debug info.
  self:T3(self.lid.."Setting group template")

  return self
end

--- Get the template of the group.
-- @param #OPSGROUP self
-- @param #boolean Copy Get a deep copy of the template.
-- @return #table Template table.
function OPSGROUP:_GetTemplate(Copy)

  if self.template then

    if Copy then
      local template=UTILS.DeepCopy(self.template)
      return template
    else
      return self.template
    end

  else
    self:T(self.lid..string.format("ERROR: No template was set yet!"))
  end

  return nil
end

--- Clear waypoints.
-- @param #OPSGROUP self
-- @param #number IndexMin Clear waypoints up to this min WP index. Default 1.
-- @param #number IndexMax Clear waypoints up to this max WP index. Default `#self.waypoints`.
function OPSGROUP:ClearWaypoints(IndexMin, IndexMax)

  IndexMin=IndexMin or 1
  IndexMax=IndexMax or #self.waypoints

  -- Clear all waypoints.
  for i=IndexMax,IndexMin,-1 do
    table.remove(self.waypoints, i)
  end
  --self.waypoints={}
end

--- Get target group.
-- @param #OPSGROUP self
-- @return Wrapper.Group#GROUP Detected target group.
-- @return #number Distance to target.
function OPSGROUP:_GetDetectedTarget()

  -- Target.
  local targetgroup=nil --Wrapper.Group#GROUP
  local targetdist=math.huge

  -- Loop over detected groups.
  for _,_group in pairs(self.detectedgroups:GetSet()) do
    local group=_group --Wrapper.Group#GROUP

    if group and group:IsAlive() then

      -- Get 3D vector of target.
      local targetVec3=group:GetVec3()

      -- Distance to target.
      local distance=UTILS.VecDist3D(self.position, targetVec3)

      if distance<=self.engagedetectedRmax and distance<targetdist then

        -- Check type attribute.
        local righttype=false
        for _,attribute in pairs(self.engagedetectedTypes) do
          local gotit=group:HasAttribute(attribute, false)
          self:T(self.lid..string.format("Group %s has attribute %s = %s", group:GetName(), attribute, tostring(gotit)))
          if gotit then
            righttype=true
            break
          end
        end

        -- We got the right type.
        if righttype then

          local insideEngage=true
          local insideNoEngage=false

          -- Check engage zones.
          if self.engagedetectedEngageZones then
            insideEngage=false
            for _,_zone in pairs(self.engagedetectedEngageZones.Set) do
              local zone=_zone --Core.Zone#ZONE
              local inzone=zone:IsVec3InZone(targetVec3)
              if inzone then
                insideEngage=true
                break
              end
            end
          end

          -- Check no engage zones.
          if self.engagedetectedNoEngageZones then
            for _,_zone in pairs(self.engagedetectedNoEngageZones.Set) do
              local zone=_zone --Core.Zone#ZONE
              local inzone=zone:IsVec3InZone(targetVec3)
              if inzone then
                insideNoEngage=true
                break
              end
            end
          end

          -- If inside engage but not inside no engage zones.
          if insideEngage and not insideNoEngage then
            targetdist=distance
            targetgroup=group
          end

        end

      end
    end
  end

  return targetgroup, targetdist
end

--- This function uses Disposition and other fallback logic to find better ground positions for ground units.
--- NOTE: This is not a spawn randomizer.
--- It will try to find clear ground locations avoiding trees, water, roads, runways, map scenery, statics and other units in the area and modifies the provided positions table.
--- Maintains the original layout and unit positions as close as possible by searching for the next closest valid position to each unit.
--- Uses UTILS.ValidateAndRepositionGroundUnits.
-- @param #boolean Enabled Enable/disable the feature.
function OPSGROUP:SetValidateAndRepositionGroundUnits(Enabled)
    self.ValidateAndRepositionGroundUnits = Enabled
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
