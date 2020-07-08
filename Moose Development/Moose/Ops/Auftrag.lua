--- **Ops** - Auftrag (mission) for Ops.
--
-- **Main Features:**
--
--    * Simplifies defining and executing DCS tasks.
--    * Additional useful events.
--    * Set mission start/stop times.
--    * Set mission priority and urgency (can cancel running missions).
--    * Specific mission options for ROE, ROT, formation, etc.
--    * Interface to FLIGHTGROUP, AIRWING and WINGCOMMANDER classes.
--    * FSM events when a mission is done, successful or failed.
--    
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Auftrag
-- @image OPS_Auftrag.png


--- AUFTRAG class.
-- @type AUFTRAG
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number auftragsnummer Auftragsnummer.
-- @field #string type Mission type.
-- @field #string status Mission status.
-- @field #table groupdata Group specific data.
-- @field #string name Mission name.
-- @field #number prio Mission priority.
-- @field #boolean urgent Mission is urgent. Running missions with lower prio might be cancelled.
-- @field #number Tstart Mission start time in seconds.
-- @field #number Tstop Mission stop time in seconds.
-- @field #number duration Mission duration in seconds.
-- @field Wrapper.Marker#MARKER marker F10 map marker.
-- @field #table DCStask DCS task structure.
-- @field #number Ntargets Number of mission targets.
-- @field #number dTevaluate Time interval in seconds before the mission result is evaluated after mission is over.
-- @field #number Tover Mission abs. time stamp, when mission was over. 
-- @field #table conditionStart Condition(s) that have to be true, before the mission will be started.
-- @field #table conditionSuccess If all stop conditions are true, the mission is cancelled.
-- @field #table conditionFailure If all stop conditions are true, the mission is cancelled.
-- 
-- @field #number orbitSpeed Orbit speed in m/s.
-- @field #number orbitAltitude Orbit altitude in meters.
-- @field #number orbitHeading Orbit heading in degrees.
-- @field #number orbitLeg Length of orbit leg in meters.
-- @field Core.Point#COORDINATE orbitRaceTrack Race-track orbit coordinate.
-- 
-- @field #AUFTRAG.TargetData engageTarget Target data to engage.
-- 
-- @field Core.Zone#ZONE_RADIUS engageZone *Circular* engagement zone.
-- @field #table engageTargetTypes Table of target types that are engaged in the engagement zone.
-- @field #number engageAltitude Engagement altitude in meters.
-- @field #number engageDirection Engagement direction in degrees.
-- @field #number engageQuantity Number of times a target is engaged.
-- @field #number engageWeaponType Weapon type used.
-- @field #number engageWeaponExpend How many weapons are used.
-- @field #boolean engageAsGroup Group attack.
-- @field #number engageMaxDistance Max engage distance.
-- @field #number refuelSystem Refuel type (boom or probe) for TANKER missions.
-- 
-- @field Wrapper.Group#GROUP escortGroup The group to be escorted.
-- @field DCS#Vec3 escortVec3 The 3D offset vector from the escorted group to the escort group.
-- 
-- @field #number facDesignation FAC designation type.
-- @field #boolean facDatalink FAC datalink enabled.
-- @field #number facFreq FAC radio frequency in MHz.
-- @field #number facModu FAC radio modulation 0=AM 1=FM.
-- 
-- @field Core.Set#SET_GROUP transportGroupSet Groups to be transported.
-- @field Core.Point#COORDINATE transportPickup Coordinate where to pickup the cargo.
-- @field Core.Point#COORDINATE transportDropoff Coordinate where to drop off the cargo.
-- 
-- @field #number artyRadius Radius in meters.
-- @field #number artyShots Number of shots fired.
-- 
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander The WINGCOMMANDER managing this mission.
-- @field Ops.AirWing#AIRWING airwing The assigned airwing.
-- @field #table assets Airwing Assets assigned for this mission.
-- @field #number nassets Number of required assets by the Airwing.
-- @field #number requestID The ID of the queued warehouse request. Necessary to cancel the request if the mission was cancelled before the request is processed.
-- @field #boolean cancelContactLost If true, cancel mission if the contact is lost.
-- @field #table squadrons User specifed airwing squadrons assigned for this mission. Only these will be considered for the job!
-- @field Ops.AirWing#AIRWING.PatrolData patroldata Patrol data.
-- 
-- @field #string missionTask Mission task. See `ENUMS.MissionTask`.
-- @field #number missionAltitude Mission altitude in meters.
-- @field #number missionFraction Mission coordiante fraction. Default is 0.5.
-- @field #number missionRange Mission range in meters. Used in AIRWING class.
-- 
-- @field #table enrouteTasks Mission enroute tasks.
-- 
-- @field #number radioFreq Mission radio frequency in MHz.
-- @field #number radioModu Mission radio modulation (0=AM and 1=FM).
-- @field #number tacanChannel Mission TACAN channel.
-- @field #number tacanMorse Mission TACAN morse code.
-- 
-- @field #number missionRepeated Number of times mission was repeated.
-- @field #number missionRepeatMax Number of times mission is repeated if failed.
-- 
-- @field #number optionROE ROE.
-- @field #number optionROT ROT.
-- @field #number optionCM Counter measures.
-- @field #number optionFormation Formation.
-- @field #number optionRTBammo RTB on out-of-ammo.
-- @field #number optionRTBfuel RTB on out-of-fuel.
-- @field #number optionECM ECM.
-- 
-- @extends Core.Fsm#FSM

--- *A warrior's mission is to foster the success of others.* --- Morihei Ueshiba
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\AUFTRAG_Main.jpg)
--
-- # The AUFTRAG Concept
-- 
-- As you probably know, setting tasks in DCS is often tedious. The AUFTRAG class significantly simplifies the necessary workflow by using optimized default parameters.
--
-- You can think of an AUFTRAG as document, which contains the mission briefing, i.e. information about the target location, mission altitude, speed and various other parameters.
-- This document can be handed over directly to a pilot (or multiple pilots) via the FLIGHTGROUP class. The pilots will then execute the mission.
-- The AUFTRAG document can also be given to an AIRWING. The airwing will then determine the best assets (pilots and payloads) available for the job. 
-- One more up the food chain, an AUFTRAG can be passed to a WINGCOMMANDER. The wing commander will find the best AIRWING and pass the job over to it.
--
-- # Airborne Missions
-- 
-- Several mission types are supported by this class.
-- 
-- ## Anti-Ship
-- 
-- An anti-ship mission can be created with the @{#AUFTRAG.NewANTISHIP}(*Target, Altitude*) function.
-- 
-- ## AWACS
-- 
-- An AWACS mission can be created with the @{#AUFTRAG.NewAWACS}() function.
-- 
-- ## BAI
-- 
-- A BAI mission can be created with the @{#AUFTRAG.NewBAI}() function.
-- 
-- ## Bombing
-- 
-- A bombing mission can be created with the @{#AUFTRAG.NewBOMBING}() function.
-- 
-- ## Bombing Runway
-- 
-- A bombing runway mission can be created with the @{#AUFTRAG.NewBOMBRUNWAY}() function.
-- 
-- ## Bombing Carpet
-- 
-- A carpet bombing mission can be created with the @{#AUFTRAG.NewBOMBCARPET}() function.
-- 
-- ## CAP
-- 
-- A CAP mission can be created with the @{#AUFTRAG.NewCAP}() function.
-- 
-- ## CAS
-- 
-- A CAS mission can be created with the @{#AUFTRAG.NewCAS}() function.
-- 
-- ## Escort
-- 
-- An escort mission can be created with the @{#AUFTRAG.NewESCORT}() function.
-- 
-- ## FACA
-- 
-- An FACA mission can be created with the @{#AUFTRAG.NewFACA}() function.
-- 
-- ## Ferry
-- 
-- Not implemented yet.
-- 
-- ## Intercept
-- 
-- An intercept mission can be created with the @{#AUFTRAG.NewINTERCEPT}() function.
-- 
-- ## Orbit
-- 
-- An orbit mission can be created with the @{#AUFTRAG.NewORBIT}() function.
-- 
-- ## PATROL
-- 
-- An patrol mission can be created with the @{#AUFTRAG.NewPATROL}() function.
-- 
-- ## RECON
-- 
-- Not implemented yet.
-- 
-- ## RESCUE HELO
-- 
-- An rescue helo mission can be created with the @{#AUFTRAG.NewRESCUEHELO}() function.
-- 
-- ## SEAD
-- 
-- An SEAD mission can be created with the @{#AUFTRAG.NewSEAD}() function.
-- 
-- ## STRIKE
-- 
-- An strike mission can be created with the @{#AUFTRAG.NewSTRIKE}() function.
-- 
-- ## Tanker
-- 
-- A refueling tanker mission can be created with the @{#AUFTRAG.NewTANKER}() function.
-- 
-- ## TROOPTRANSPORT
-- 
-- A troop transport mission can be created with the @{#AUFTRAG.NewTROOPTRANSPORT}() function.
-- 
-- # Ground Missions
-- 
-- ## ARTY
-- 
-- An arty mission can be created with the @{#AUFTRAG.NewARTY}() function.
-- 
-- # Options and Parameters
-- 
-- 
-- # Assigning Missions
-- 
-- An AUFTRAG can be assigned to groups, airwings or wingcommanders
-- 
-- ## Group Level
-- 
-- ### Flight Group
-- 
-- Assigning an AUFTRAG to a flight groups is done via the @{Ops.FlightGroup#FLIGHTGROUP.AddMission} function. See FLIGHTGROUP docs for details.
-- 
-- ### Navy Group
-- 
-- Assigning an AUFTRAG to a navy groups is done via the @{Ops.NavyGroup#NAVYGROUP.AddMission} function. See NAVYGROUP docs for details.
-- 
-- ## Airwing Level
-- 
-- Adding an AUFTRAG to an airwing is done via the @{Ops.AirWing#AIRWING.AddMission} function. See AIRWING docs for further details.
-- 
-- ## Wing Commander Level
-- 
-- Assigning an AUFTRAG to a wing commander is done via the @{Ops.WingCommander#WINGCOMMANDER.AddMission} function. See WINGCOMMADER docs for details. 
-- 
-- 
-- # Events
-- 
-- The AUFTRAG class creates many useful (FSM) events, which can be used in the mission designers script.  
-- 
-- 
-- # Examples
-- 
--
-- @field #AUFTRAG
AUFTRAG = {
  ClassName          = "AUFTRAG",
  Debug              = false,
  lid                =   nil,
  auftragsnummer     =   nil,
  groupdata         =    {},
  assets             =    {},
  missionFraction    =   0.5,
  enrouteTasks       =    {},
  marker             =   nil,
  conditionStart     =    {},
  conditionSuccess   =    {},
  conditionFailure   =    {},
}

--- Global mission counter.
_AUFTRAGSNR=0


--- Mission types.
-- @type AUFTRAG.Type
-- @field #string ANTISHIP Anti-ship mission.
-- @field #string AWACS AWACS mission.
-- @field #string BAI Battlefield Air Interdiction.
-- @field #string BOMBING Bombing mission.
-- @field #string BOMBRUNWAY Bomb runway of an airbase.
-- @field #string BOMBCARPET Carpet bombing.
-- @field #string CAP Combat Air Patrol.
-- @field #string CAS Close Air Support.
-- @field #string ESCORT Escort mission.
-- @field #string FACA Forward AirController airborne mission.
-- @field #string FERRY Ferry flight mission.
-- @field #string INTERCEPT Intercept mission.
-- @field #string ORBIT Orbit mission.
-- @field #string PATROL Similar to CAP but no auto engage targets.
-- @field #string RECON Recon mission.
-- @field #string RECOVERYTANKER Recovery tanker mission. Not implemented yet.
-- @field #string RESCUEHELO Rescue helo.
-- @field #string SEAD Suppression/destruction of enemy air defences.
-- @field #string STRIKE Strike mission.
-- @field #string TANKER Tanker mission.
-- @field #string TROOPTRANSPORT Troop transport mission.
-- @field #string ARTY Fire at point.
AUFTRAG.Type={
  ANTISHIP="Anti Ship",
  AWACS="AWACS",  
  BAI="BAI",
  BOMBING="Bombing",
  BOMBRUNWAY="Bomb Runway",
  BOMBCARPET="Carpet Bombing",
  CAP="CAP",
  CAS="CAS",
  ESCORT="Escort",
  FACA="FAC-A",
  FERRY="Ferry Flight",
  INTERCEPT="Intercept",
  ORBIT="Orbit",
  PATROL="Patrol",
  RECON="Recon",
  RECOVERYTANKER="Recovery Tanker",
  RESCUEHELO="Rescue Helo",
  SEAD="SEAD",
  STRIKE="Strike",
  TANKER="Tanker",
  TROOPTRANSPORT="Troop Transport",
  ARTY="Fire At Point",
}

--- Mission status.
-- @type AUFTRAG.Status
-- @field #string PLANNED Mission is at the early planning stage.
-- @field #string QUEUED Mission is queued at an airwing.
-- @field #string REQUESTED Mission assets were requested from the warehouse.
-- @field #string SCHEDULED Mission is scheduled in a FLIGHGROUP queue waiting to be started.
-- @field #string STARTED Mission has started but is not executed yet.
-- @field #string EXECUTING Mission is being executed.
-- @field #string DONE Mission is over.
-- @field #string CANCELLED Mission was cancelled.
-- @field #string SUCCESS Mission was a success.
-- @field #string FAILED Mission failed.
AUFTRAG.Status={
  PLANNED="planned",
  QUEUED="queued",
  REQUESTED="requested",
  SCHEDULED="scheduled",
  STARTED="started",
  EXECUTING="executing",
  DONE="done",
  CANCELLED="cancelled",
  SUCCESS="success",
  FAILED="failed",
}

--- Mission status of an assigned group.
-- @type AUFTRAG.GroupStatus
-- @field #string SCHEDULED Mission is scheduled in a FLIGHGROUP queue waiting to be started.
-- @field #string STARTED Ops group started this mission but it is not executed yet.
-- @field #string EXECUTING Ops group is executing this mission.
-- @field #string PAUSED Ops group has paused this mission, e.g. for refuelling.
-- @field #string DONE Mission task of the Ops group is done.
-- @field #string CANCELLED Mission was cancelled.
AUFTRAG.GroupStatus={
  SCHEDULED="scheduled",
  STARTED="started",
  EXECUTING="executing",
  PAUSED="paused",
  DONE="done",
  CANCELLED="cancelled",
}

--- Target type.
-- @type AUFTRAG.TargetType
-- @field #string GROUP Target is a GROUP object.
-- @field #string UNIT Target is a UNIT object.
-- @field #string STATIC Target is a STATIC object.
-- @field #string COORDINATE Target is a COORDINATE.
-- @field #string AIRBASE Target is an AIRBASE.
-- @field #string SETGROUP Target is a SET of GROUPs.
-- @field #string SETUNIT Target is a SET of UNITs.
AUFTRAG.TargetType={
  GROUP="Group",
  UNIT="Unit",
  STATIC="Static",
  COORDINATE="Coordinate",
  AIRBASE="Airbase",
  SETGROUP="SetGroup",
  SETUNIT="SetUnit",
}

--- Target data.
-- @type AUFTRAG.TargetData
-- @field Wrapper.Positionable#POSITIONABLE Target Target Object.
-- @field #string Type Target type: "Group", "Unit", "Static", "Coordinate", "Airbase", "SetGroup", "SetUnit".
-- @field #string Name Target name.
-- @field #number Ninital Number of initial targets.
-- @field #number Lifepoints Total life points.
-- @field #number Lifepoints0 Inital life points.

--- Mission capability.
-- @type AUFTRAG.Capability
-- @field #string MissionType Type of mission.
-- @field #number Performance Number describing the performance level. The higher the better.

--- Mission success.
-- @type AUFTRAG.Success
-- @field #string SURVIVED Group did survive.
-- @field #string ENGAGED Target was engaged.
-- @field #string DAMAGED Target was damaged.
-- @field #string DESTROYED Target was destroyed.

--- Generic mission condition.
-- @type AUFTRAG.Condition
-- @field #function func Callback function to check for a condition. Should return a #boolean.
-- @field #table arg Optional arguments passed to the condition callback function.

--- Group specific data. Each ops group subscribed to this mission has different data for this.
-- @type AUFTRAG.GroupData
-- @field Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @field Core.Point#COORDINATE waypointcoordinate Waypoint coordinate.
-- @field #number waypointindex Waypoint index.
-- @field Ops.OpsGroup#OPSGROUP.Task waypointtask Waypoint task.
-- @field #string status Group mission status.
-- @field Ops.AirWing#AIRWING.SquadronAsset asset The squadron asset.


--- AUFTRAG class version.
-- @field #string version
AUFTRAG.version="0.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Clone mission. How? Deepcopy?
-- DONE: Option to assign mission to specific squadrons (requires an AIRWING).
-- TODO: Option to assign a specific payload for the mission (requires an AIRWING).
-- DONE: Add mission start conditions.
-- TODO: Add recovery tanker mission for boat ops.
-- DONE: Add rescue helo mission for boat ops.
-- TODO: Mission success options damaged, destroyed.
-- DONE: Mission ROE and ROT.
-- DONE: Mission frequency and TACAN.
-- TODO: Mission formation, etc.
-- DONE: FSM events.
-- DONE: F10 marker functions that are updated on Status event.
-- TODO: F10 marker to create new missions.
-- DONE: Evaluate mission result ==> SUCCESS/FAILURE
-- DONE: NewAUTO() NewA2G NewA2A
-- DONE: Transport mission.
-- TODO: Recon mission. What input? Set of coordinates?
-- TODO: Set mission coalition, e.g. for F10 markers. Could be derived from target if target has a coalition.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new generic AUFTRAG object.
-- @param #AUFTRAG self
-- @param #string Type Mission type.
-- @return #AUFTRAG self
function AUFTRAG:New(Type)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #AUFTRAG
  
  -- Increase global counter.
  _AUFTRAGSNR=_AUFTRAGSNR+1
  
  -- Mission type.
  self.type=Type
  
  -- Auftragsnummer.
  self.auftragsnummer=_AUFTRAGSNR
  
  -- Log id.
  self:_SetLogID()
  
  -- State is planned.
  self.status=AUFTRAG.Status.PLANNED
  
  -- Defaults
  self:SetName()
  self:SetPriority()
  self:SetTime()
  self.engageAsGroup=true
  self.missionRepeated=0
  self.missionRepeatMax=0
  self.nassets=1
  self.dTevaluate=0
  
  -- FMS start state is PLANNED.
  self:SetStartState(self.status)
  
  -- PLANNED --> (QUEUED) --> (REQUESTED) --> SCHEDULED --> STARTED --> EXECUTING --> DONE
  
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Queued",        AUFTRAG.Status.QUEUED)      -- Mission is in queue of an AIRWING.
  self:AddTransition(AUFTRAG.Status.QUEUED,    "Requested",     AUFTRAG.Status.REQUESTED)   -- Mission assets have been requested from the warehouse.
  self:AddTransition(AUFTRAG.Status.REQUESTED, "Scheduled",     AUFTRAG.Status.SCHEDULED)   -- Mission added to the first ops group queue.
  
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Scheduled",     AUFTRAG.Status.SCHEDULED)   -- From planned directly to scheduled.
  
  self:AddTransition(AUFTRAG.Status.SCHEDULED, "Started",       AUFTRAG.Status.STARTED)     -- First asset has started the mission
  self:AddTransition(AUFTRAG.Status.STARTED,   "Executing",     AUFTRAG.Status.EXECUTING)   -- First asset is executing the mission.
  
  self:AddTransition("*",                      "Done",          AUFTRAG.Status.DONE)        -- All assets have reported that mission is done.
  
  self:AddTransition("*",                      "Cancel",        "*")                        -- Command to cancel the mission.
  
  self:AddTransition("*",                      "Success",       AUFTRAG.Status.SUCCESS)
  self:AddTransition("*",                      "Failed",        AUFTRAG.Status.FAILED)
    
  self:AddTransition("*",                      "Status",        "*")
  self:AddTransition("*",                      "Stop",          "*")
  
  self:AddTransition("*",                      "Repeat",        AUFTRAG.Status.PLANNED)

  self:AddTransition("*",                      "GroupDead",    "*")  
  self:AddTransition("*",                      "AssetDead",     "*")
  
  -- Init status update.
  self:__Status(-1)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Missions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create an ANTI-SHIP mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be passed as a @{Wrapper.Group#GROUP} or @{Wrapper.Unit#UNIT} object.
-- @param #number Altitude Engage altitude in feet. Default 2000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewANTISHIP(Target, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.ANTISHIP)
  
  mission:_TargetFromObject(Target)
  
  -- DCS task parameters:
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=Altitude or UTILS.FeetToMeters(2000)
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.ANTISHIPSTRIKE
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.4
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create an ORBIT mission, which can be either a circular orbit or a race-track pattern.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 KIAS. 
-- @param #number Heading Heading of race-track pattern in degrees. If not specified, a circular orbit is performed.
-- @param #number Leg Length of race-track in NM. If not specified, a circular orbit is performed.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT(Coordinate, Altitude, Speed, Heading, Leg)

  local mission=AUFTRAG:New(AUFTRAG.Type.ORBIT)
  
  -- Altitude.
  if Altitude then
    mission.orbitAltitude=UTILS.FeetToMeters(Altitude)
  else
    mission.orbitAltitude=Coordinate.y
  end  
  Coordinate.y=mission.orbitAltitude
  
  mission:_TargetFromObject(Coordinate)

  mission.orbitSpeed = UTILS.KnotsToMps(Speed or 350)

  if Heading and Leg then
    mission.orbitHeading=Heading
    mission.orbitLeg=UTILS.NMToMeters(Leg)
    mission.orbitRaceTrack=Coordinate:Translate(mission.orbitLeg, mission.orbitHeading, true)
  end

  
  -- Mission options:
  mission.missionAltitude=mission.orbitAltitude*0.9  
  mission.missionFraction=0.9  
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- Create an ORBIT mission, where the aircraft will go in a circle around the specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Position where to orbit around.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 KIAS. 
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT_CIRCLE(Coordinate, Altitude, Speed)

  local mission=AUFTRAG:NewORBIT(Coordinate, Altitude, Speed)

  return mission
end

--- Create an ORBIT mission, where the aircraft will fly a race-track pattern.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 KIAS.
-- @param #number Heading Heading of race-track pattern in degrees. Default random in [0, 360) degrees.
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)

  Heading = Heading or math.random(360)
  Leg     = Leg or 10

  local mission=AUFTRAG:NewORBIT(Coordinate, Altitude, Speed, Heading, Leg)
  
  return mission
end

--- Create a PATROL mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default random in [0, 360) degrees.
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewPATROL(Coordinate, Altitude, Speed, Heading, Leg)

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)
    
  -- Mission type PATROL.
  mission.type=AUFTRAG.Type.PATROL
  
  mission:_SetLogID()

  -- Mission options:  
  mission.missionTask=ENUMS.MissionTask.INTERCEPT
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  return mission
end

--- Create a TANKER mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param #number RefuelSystem Refueling system.
-- @return #AUFTRAG self
function AUFTRAG:NewTANKER(Coordinate, Altitude, Speed, Heading, Leg, RefuelSystem)

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)
    
  -- Mission type PATROL.
  mission.type=AUFTRAG.Type.TANKER
  
  mission:_SetLogID()
  
  mission.refuelSystem=RefuelSystem
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.REFUELING 
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a AWACS mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit. Altitude is also taken from the coordinate.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewAWACS(Coordinate, Altitude, Speed, Heading, Leg)

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)
    
  -- Mission type PATROL.
  mission.type=AUFTRAG.Type.AWACS
  
  mission:_SetLogID()
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.AWACS  
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end



--- Create an INTERCEPT mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to intercept. Can also be passed as simple @{Wrapper.Group#GROUP} or @{Wrapper.Unit#UNIT} object.
-- @return #AUFTRAG self
function AUFTRAG:NewINTERCEPT(Target)
  
  local mission=AUFTRAG:New(AUFTRAG.Type.INTERCEPT)
    
  mission:_TargetFromObject(Target)
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.INTERCEPT    
  mission.missionFraction=0.1  
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a CAP mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE_RADIUS ZoneCAP Circular CAP zone. Detected targets in this zone will be engaged.
-- @param #number Altitude Altitude at which to orbit in feet. Default is 10,000 ft.
-- @param #number Speed Orbit speed in knots. Default 350 kts.
-- @param Core.Point#COORDINATE Coordinate Where to orbit. Default is the center of the CAP zone.
-- @param #number Heading Heading of race-track pattern in degrees. If not specified, a simple circular orbit is performed.
-- @param #number Leg Length of race-track in NM. If not specified, a simple circular orbit is performed.
-- @param #table TargetTypes Table of target types. Default {"Air"}.
-- @return #AUFTRAG self
function AUFTRAG:NewCAP(ZoneCAP, Altitude, Speed, Coordinate, Heading, Leg, TargetTypes)

  -- Ensure given TargetTypes parameter is a table.
  if TargetTypes then
    if type(TargetTypes)~="table" then
      TargetTypes={TargetTypes}
    end
  end

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT(Coordinate or ZoneCAP:GetCoordinate(), Altitude or 10000, Speed, Heading, Leg)
  
  -- Mission type CAP.
  mission.type=AUFTRAG.Type.CAP
  mission:_SetLogID()
  
  -- DCS task parameters:
  mission.engageZone=ZoneCAP
  mission.engageTargetTypes=TargetTypes or {"Air"}

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.CAP    
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a CAS mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE_RADIUS ZoneCAS Circular CAS zone. Detected targets in this zone will be engaged.
-- @param #number Altitude Altitude at which to orbit. Default is 10,000 ft.
-- @param #number Speed Orbit speed in knots. Default 350 KIAS.
-- @param Core.Point#COORDINATE Coordinate Where to orbit. Default is the center of the CAS zone.
-- @param #number Heading Heading of race-track pattern in degrees. If not specified, a simple circular orbit is performed.
-- @param #number Leg Length of race-track in NM. If not specified, a simple circular orbit is performed.
-- @param #table TargetTypes (Optional) Table of target types. Default {"Helicopters", "Ground Units", "Light armed ships"}.
-- @return #AUFTRAG self
function AUFTRAG:NewCAS(ZoneCAS, Altitude, Speed, Coordinate, Heading, Leg, TargetTypes)

  -- Ensure given TargetTypes parameter is a table.
  if TargetTypes then
    if type(TargetTypes)~="table" then
      TargetTypes={TargetTypes}
    end
  end

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT(Coordinate or ZoneCAS:GetCoordinate(), Altitude or 10000, Speed, Heading, Leg)
  
  -- Mission type CAS.
  mission.type=AUFTRAG.Type.CAS
  mission:_SetLogID()
  
  -- DCS Task options:
  mission.engageZone=ZoneCAS
  mission.engageTargetTypes=TargetTypes or {"Helicopters", "Ground Units", "Light armed ships"}
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.CAS  
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire

  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a FACA mission.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP Target Target group. Must be a GROUP object.
-- @param #string Designation Designation of target. See `AI.Task.Designation`. Default `AI.Task.Designation.AUTO`.
-- @param #boolean DataLink Enable data link. Default `true`.
-- @param #number Frequency Radio frequency in MHz the FAC uses for communication. Default is 133 MHz.
-- @param #number Modulation Radio modulation band. Default 0=AM. Use 1 for FM. See radio.modulation.AM or radio.modulaton.FM.
-- @return #AUFTRAG self
function AUFTRAG:NewFACA(Target, Designation, DataLink, Frequency, Modulation)

  local mission=AUFTRAG:New(AUFTRAG.Type.FACA)

  mission:_TargetFromObject(Target)
  
  -- TODO: check that target is really a group object!
  
  -- DCS Task options:
  mission.facDesignation=Designation --or AI.Task.Designation.AUTO
  mission.facDatalink=true
  mission.facFreq=Frequency or 133
  mission.facModu=Modulation or radio.modulation.AM
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.AFAC
  mission.missionAltitude=nil
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end


--- Create a BAI mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 2000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewBAI(Target, Altitude)
  
  local mission=AUFTRAG:New(AUFTRAG.Type.BAI)

  mission:_TargetFromObject(Target)
  
  -- DCS Task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyAG
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=Altitude or UTILS.FeetToMeters(2000)
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.75
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()  
  
  return mission
end

--- Create a SEAD mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP or UNIT object.
-- @param #number Altitude Engage altitude in feet. Default 2000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewSEAD(Target, Altitude)
  
  local mission=AUFTRAG:New(AUFTRAG.Type.SEAD)

  mission:_TargetFromObject(Target)
  
  -- DCS Task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyAG  --ENUMS.WeaponFlag.Cannons
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=Altitude or UTILS.FeetToMeters(2000)
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.SEAD
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.2
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  --mission.optionROT=ENUMS.ROT.AllowAbortMission
  
  mission.DCStask=mission:GetDCSMissionTask()  
  
  return mission
end

--- Create a STRIKE mission. Flight will attack the closest map object to the specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target The target coordinate. Can also be given as a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 2000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewSTRIKE(Target, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.STRIKE)
  
  mission:_TargetFromObject(Target)
  
  -- DCS Task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyAG
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 2000)  
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.75
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a BOMBING mission. Flight will drop bombs a specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Target coordinate. Can also be specified as a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewBOMBING(Target, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.BOMBING)
  
  mission:_TargetFromObject(Target)
  
  -- DCS task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyBomb
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude*0.8  
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.NoReaction   -- No reaction is better.
  
  -- Evaluate result after 5 min. We might need time until the bombs have dropped and targets have been detroyed.
  mission.dTevaluate=5*60
  
  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a BOMBRUNWAY mission.
-- @param #AUFTRAG self
-- @param Wrapper.Airbase#AIRBASE Airdrome The airbase to bomb. This must be an airdrome (not a FARP or ship) as these to not have a runway.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewBOMBRUNWAY(Airdrome, Altitude)

  if type(Airdrome)=="string" then
    Airdrome=AIRBASE:FindByName(Airdrome)
  end

  local mission=AUFTRAG:New(AUFTRAG.Type.BOMBRUNWAY)
  
  mission:_TargetFromObject(Airdrome)  
  
  -- DCS task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyBomb
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.RUNWAYATTACK
  mission.missionAltitude=mission.engageAltitude*0.8  
  mission.missionFraction=0.2
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  -- Evaluate result after 5 min.
  mission.dTevaluate=5*60
  
  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a CARPET BOMBING mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Target coordinate. Can also be specified as a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @param #number CarpetLength Length of bombing carpet in meters. Default 500 m.
-- @return #AUFTRAG self
function AUFTRAG:NewBOMBCARPET(Target, Altitude, CarpetLength)

  local mission=AUFTRAG:New(AUFTRAG.Type.BOMBCARPET)
  
  mission:_TargetFromObject(Target)  
  
  -- DCS task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyBomb
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)
  mission.engageCarpetLength=CarpetLength or 500
  mission.engageAsGroup=false  -- Looks like this must be false or the task is not executed. It is not available in the ME anyway but in the task of the mission file.
  mission.engageDirection=nil  -- This is also not available in the ME.

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude*0.8  
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.NoReaction
  
  -- Evaluate result after 5 min.
  mission.dTevaluate=5*60
  
  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end


--- Create an ESCORT (or FOLLOW) mission. Flight will escort another group and automatically engage certain target types.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP EscortGroup The group to escort.
-- @param DCS#Vec3 OffsetVector A table with x, y and z components specifying the offset of the flight to the escorted group. Default {x=200, y=0, z=-100} for 200 meters to the right, same alitude, 100 meters behind.
-- @param #number EngageMaxDistance Max engage distance of targets in meters. Default auto (*nil*).
-- @param #table TargetTypes Types of targets to engage automatically. Default is {"Air"}, i.e. all enemy airborne units. Use an empty set {} for a simple "FOLLOW" mission.
-- @return #AUFTRAG self
function AUFTRAG:NewESCORT(EscortGroup, OffsetVector, EngageMaxDistance, TargetTypes)

  local mission=AUFTRAG:New(AUFTRAG.Type.ESCORT)
  
  mission:_TargetFromObject(EscortGroup)
  
  -- DCS task parameters:
  mission.escortVec3=OffsetVector or {x=200, y=0, z=-100}
  mission.engageMaxDistance=EngageMaxDistance
  mission.engageTargetTypes=TargetTypes or {"Air"}
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.ESCORT  
  mission.missionFraction=0.1
  mission.missionAltitude=1000
  mission.optionROE=ENUMS.ROE.OpenFire       -- TODO: what's the best ROE here? Make dependent on ESCORT or FOLLOW!
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a RESCUE HELO mission.
-- @param #AUFTRAG self
-- @param Wrapper.Unit#UNIT Carrier The carrier unit.
-- @return #AUFTRAG self
function AUFTRAG:NewRESCUEHELO(Carrier)

  local mission=AUFTRAG:New(AUFTRAG.Type.RESCUEHELO)
  
  mission:_TargetFromObject(Carrier)
  
  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.NOTHING
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.NoReaction
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end


--- Create a TROOP TRANSPORT mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_GROUP TransportGroupSet The set group(s) to be transported.
-- @param Core.Point#COORDINATE DropoffCoordinate Coordinate where the helo will land drop off the the troops.
-- @param Core.Point#COORDINATE PickupCoordinate Coordinate where the helo will land to pick up the the cargo. Default is the fist transport group.
-- @return #AUFTRAG self
function AUFTRAG:NewTROOPTRANSPORT(TransportGroupSet, DropoffCoordinate, PickupCoordinate)

  local mission=AUFTRAG:New(AUFTRAG.Type.TROOPTRANSPORT)
  
  if TransportGroupSet:IsInstanceOf("GROUP") then
    mission.transportGroupSet=SET_GROUP:New()
    mission.transportGroupSet:AddGroup(TransportGroupSet)
  elseif TransportGroupSet:IsInstanceOf("SET_GROUP") then
    mission.transportGroupSet=TransportGroupSet
  else
    mission:E(mission.lid.."ERROR: TransportGroupSet must be a GROUP or SET_GROUP object!")
    return nil
  end
  
  mission:_TargetFromObject(mission.transportGroupSet)
  
  mission.transportPickup=PickupCoordinate or mission:GetTargetCoordinate()  
  mission.transportDropoff=DropoffCoordinate
  
  -- Debug.
  mission.transportPickup:MarkToAll("Pickup")
  mission.transportDropoff:MarkToAll("Drop off")

  -- TODO: what's the best ROE here?
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- Create an ARTY mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Center of the firing solution.
-- @param #number Nshots Number of shots to be fired. Default 3.
-- @param #number Radius Radius of the shells in meters. Default 100 meters.
-- @return #AUFTRAG self
function AUFTRAG:NewARTY(Target, Nshots, Radius)

  local mission=AUFTRAG:New(AUFTRAG.Type.ARTY)
  
  mission:_TargetFromObject(Target)
  
  mission.artyShots=Nshots or 3
  mission.artyRadius=Radius or 100
  
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.missionFraction=0.1
  
  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- Create a mission to attack a group. Mission type is automatically chosen from the group category.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP EngageGroup Group to be engaged.
-- @return #AUFTRAG self
function AUFTRAG:NewAUTO(EngageGroup)

  local mission=nil --#AUFTRAG
  
  local group=EngageGroup

  if group and group:IsAlive() then
  
    local category=group:GetCategory()
    local attribute=group:GetAttribute()
    local threatlevel=group:GetThreatLevel()
  
    if category==Group.Category.AIRPLANE or category==Group.Category.HELICOPTER then
    
      ---
      -- AIR
      ---
              
      mission=AUFTRAG:NewINTERCEPT(group)
      
    elseif category==Group.Category.GROUND then
    
      ---
      -- GROUND
      ---
    
      --TODO: action depends on type
      -- AA/SAM ==> SEAD
      -- Tanks ==>
      -- Artillery ==>
      -- Infantry ==>
      -- 
              
      if attribute==GROUP.Attribute.GROUND_AAA or attribute==GROUP.Attribute.GROUND_SAM then
          
        -- SEAD/DEAD
        
        -- TODO: Attack radars first? Attack launchers?  
          
        mission=AUFTRAG:NewSEAD(group)
        
      elseif attribute==GROUP.Attribute.GROUND_ARTILLERY then
      
        mission=AUFTRAG:NewBAI(group)
      
      elseif attribute==GROUP.Attribute.GROUND_INFANTRY then
      
        mission=AUFTRAG:NewBAI(group)
          
      else

        mission=AUFTRAG:NewBAI(group)
      
      end
      
    elseif category==Group.Category.SHIP then
    
      ---
      -- NAVAL
      ---
      
       mission=AUFTRAG:NewANTISHIP(group)
            
    end
  end
  
  if mission then
    mission:SetPriority(10, true)
  end

  return mission
end



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set mission start and stop time.
-- @param #AUFTRAG self
-- @param #string ClockStart Time the mission is started, e.g. "05:00" for 5 am. If specified as a #number, it will be relative (in seconds) to the current mission time. Default is 5 seconds after mission was added.
-- @param #string ClockStop (Optional) Time the mission is stopped, e.g. "13:00" for 1 pm. If mission could not be started at that time, it will be removed from the queue. If specified as a #number it will be relative (in seconds) to the current mission time.
-- @return #AUFTRAG self
function AUFTRAG:SetTime(ClockStart, ClockStop)

  -- Current mission time.
  local Tnow=timer.getAbsTime()
  
  -- Set start time. Default in 5 sec.
  local Tstart=Tnow+5
  if ClockStart and type(ClockStart)=="number" then
    Tstart=Tnow+ClockStart
  elseif ClockStart and type(ClockStart)=="string" then
    Tstart=UTILS.ClockToSeconds(ClockStart)
  end

  -- Set stop time. Default nil.
  local Tstop=nil
  if ClockStop and type(ClockStop)=="number" then
    Tstop=Tnow+ClockStop
  elseif ClockStop and type(ClockStop)=="string" then
    Tstop=UTILS.ClockToSeconds(ClockStop)
  end
  
  self.Tstart=Tstart
  self.Tstop=Tstop

  if Tstop then
    self.duration=self.Tstop-self.Tstart
  end  

  return self
end

--- Set mission priority and (optional) urgency. Urgent missions can cancel other running missions. 
-- @param #AUFTRAG self
-- @param #number Prio Priority 1=high, 100=low. Default 50.
-- @param #boolean Urgent If *true*, another running mission might be cancelled if it has a lower priority.
-- @return #AUFTRAG self
function AUFTRAG:SetPriority(Prio, Urgent)
  self.prio=Prio or 50
  self.urgent=Urgent
  return self
end

--- Set how many times the mission is repeated if it fails. 
-- @param #AUFTRAG self
-- @param #number Nrepeat Number of repeats. Default 0.
-- @return #AUFTRAG self
function AUFTRAG:SetRepeatOnFailure(Nrepeat)
  self.missionRepeatMax=Nrepeat or 0
  return self
end

--- Define how many assets are required to do the job.
-- @param #AUFTRAG self
-- @param #number Nassets Number of asset groups. Default 1.
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredAssets(Nassets)
  self.nassets=Nassets or 1
  return self
end

--- Set mission name.
-- @param #AUFTRAG self
-- @param #string Name Name of the mission. Default is "Auftrag Nr. X", where X is a running number, which is automatically increased.
-- @return #AUFTRAG self
function AUFTRAG:SetName(Name)
  self.name=Name or string.format("Auftrag Nr. %d", self.auftragsnummer)
  return self
end

--- Set weapon type used for the engagement.
-- @param #AUFTRAG self
-- @param #number WeaponType Weapon type. Default is ENUMS.WeaponFlag.Auto
-- @return #AUFTRAG self
function AUFTRAG:SetWeaponType(WeaponType)
  
  self.engageWeaponType=WeaponType or ENUMS.WeaponFlag.Auto
  
  -- Update the DCS task parameter.
  self.DCStask=self:GetDCSMissionTask()
  
  return self
end

--- Set number of weapons to expend.
-- @param #AUFTRAG self
-- @param #number WeaponExpend How much of the weapon load is expended during the attack, e.g. `AI.Task.WeaponExpend.ALL`. Default "Auto". 
-- @return #AUFTRAG self
function AUFTRAG:SetWeaponExpend(WeaponExpend)
  
  self.engageWeaponExpend=WeaponExpend or "Auto"
  
  -- Update the DCS task parameter.
  self.DCStask=self:GetDCSMissionTask()
  
  return self
end

--- Set whether target will be attack as group.
-- @param #AUFTRAG self
-- @param #boolean Switch If true or nil, engage as group. If false, not.
-- @return #AUFTRAG self
function AUFTRAG:SetEngageAsGroup(Switch)

  if Switch==nil then
    Switch=true
  end
  
  self.engageAsGroup=Switch
  
  -- Update the DCS task parameter.
  self.DCStask=self:GetDCSMissionTask()
  
  return self
end

--- Set engage altitude.
-- @param #AUFTRAG self
-- @param #string Altitude Altitude in feet. Default 6000 ft.
-- @return #AUFTRAG self
function AUFTRAG:SetEngageAltitude(Altitude)
  
  self.engageAltitude=UTILS.FeetToMeters(Altitude or 6000)
  
   -- Update the DCS task parameter.
  self.DCStask=self:GetDCSMissionTask()
   
  return self
end

--- Set mission altitude.
-- @param #AUFTRAG self
-- @param #string Altitude Altitude in feet.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionAltitude(Altitude)
  self.missionAltitude=UTILS.FeetToMeters(Altitude)
  return self
end

--- Set max engage range.
-- @param #AUFTRAG self
-- @param #number Range Max range in NM. Default 100 NM.
-- @return #AUFTRAG self
function AUFTRAG:SetEngageRange(Range)
  self.engageRange=UTILS.NMToMeters(Range or 100)
  return self
end

--- Set Rules of Engagement (ROE) for this mission.
-- @param #AUFTRAG self
-- @param #string roe Mission ROE.
-- @return #AUFTRAG self
function AUFTRAG:SetROE(roe)
  
  self.optionROE=roe
  
  return self
end


--- Set Reaction on Threat (ROT) for this mission.
-- @param #AUFTRAG self
-- @param #string roe Mission ROT.
-- @return #AUFTRAG self
function AUFTRAG:SetROT(rot)
  
  self.optionROT=rot
  
  return self
end

--- Set formation for this mission.
-- @param #AUFTRAG self
-- @param #number Formation Formation.
-- @return #AUFTRAG self
function AUFTRAG:SetFormation(Formation)
  
  self.optionFormation=Formation
  
  return self
end

--- Set radio frequency and modulation for this mission.
-- @param #AUFTRAG self
-- @param #number Frequency Frequency in MHz.
-- @param #number Modulation Radio modulation. Default 0=AM.
-- @return #AUFTRAG self
function AUFTRAG:SetRadio(Frequency, Modulation)
  
  self.radioFreq=Frequency
  self.radioModu=Modulation or 0
  
  return self
end

--- Set TACAN beacon channel and Morse code for this mission.
-- @param #AUFTRAG self
-- @param #number Channel TACAN channel.
-- @param #string Morse Morse code. Default "XXX".
-- @return #AUFTRAG self
function AUFTRAG:SetTACAN(Channel, Morse)
  
  self.tacanChannel=Channel
  self.tacanMorse=Morse or "XXX"
  
  return self
end


--- Add start condition.
-- @param #AUFTRAG self
-- @param #function ConditionFunction Function that needs to be true before the mission can be started. Must return a #boolean.
-- @param ... Condition function arguments if any.
-- @return #AUFTRAG self
function AUFTRAG:AddConditionStart(ConditionFunction, ...)
  
  local condition={} --#AUFTRAG.Condition
  
  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end
  
  table.insert(self.conditionStart, condition)
  
  return self
end

--- Add success condition.
-- @param #AUFTRAG self
-- @param #function ConditionFunction If this function returns `true`, the mission is cancelled.
-- @param ... Condition function arguments if any.
-- @return #AUFTRAG self
function AUFTRAG:AddConditionSuccess(ConditionFunction, ...)
  
  local condition={} --#AUFTRAG.Condition
  
  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end
  
  table.insert(self.conditionSuccess, condition)
  
  return self
end

--- Add failure condition.
-- @param #AUFTRAG self
-- @param #function ConditionFunction If this function returns `true`, the mission is cancelled.
-- @param ... Condition function arguments if any.
-- @return #AUFTRAG self
function AUFTRAG:AddConditionFailure(ConditionFunction, ...)
  
  local condition={} --#AUFTRAG.Condition
  
  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end
  
  table.insert(self.conditionFailure, condition)
  
  return self
end


--- Assign airwing squadron(s) to the mission. Only these squads will be considered for the job.
-- @param #AUFTRAG self
-- @param #table Squadrons A table of SQUADRONs or a single SQUADRON object. 
-- @return #AUFTRAG self
function AUFTRAG:AssignSquadrons(Squadrons)

  if Squadrons:IsInstanceOf("SQUADRON") then
    Squadrons={Squadrons}
  end
  
  for _,_squad in pairs(Squadrons) do
    local squadron=_squad --Ops.Squadron#SQUADRON
    self:I(self.lid..string.format("Assigning squadron %s", tostring(squadron.name)))
  end

  self.squadrons=Squadrons
end


--- Add a Ops group to the mission.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPSGROUP object.
function AUFTRAG:AddOpsGroup(OpsGroup)
  self:I(self.lid..string.format("Adding Ops group %s", OpsGroup.groupname))

  local groupdata={} --#AUFTRAG.GroupData
  groupdata.opsgroup=OpsGroup
  groupdata.status=AUFTRAG.GroupStatus.SCHEDULED
  groupdata.waypointcoordinate=nil
  groupdata.waypointindex=nil
  groupdata.waypointtask=nil

  self.groupdata[OpsGroup.groupname]=groupdata

end

--- Remove an Ops  group from the mission.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPSGROUP object.
function AUFTRAG:DelOpsGroup(OpsGroup)
  self:I(self.lid..string.format("Removing OPS group %s", OpsGroup and OpsGroup.groupname or "nil (ERROR)!"))

  if OpsGroup then
    
    -- Remove mission form queue.
    OpsGroup:RemoveMission(self)
  
    self.groupdata[OpsGroup.groupname]=nil
    
  end

end

--- Check if mission is PLANNED.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is in the planning state.
function AUFTRAG:IsPlanned()
  return self.status==AUFTRAG.Status.PLANNED
end

--- Check if mission is QUEUED at an AIRWING mission queue.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is queued.
function AUFTRAG:IsQueued()
  return self.status==AUFTRAG.Status.QUEUED
end

--- Check if mission is REQUESTED, i.e. request for WAREHOUSE assets is done.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is requested.
function AUFTRAG:IsRequested()
  return self.status==AUFTRAG.Status.REQUESTED
end

--- Check if mission is SCHEDULED, i.e. request for WAREHOUSE assets is done.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is queued.
function AUFTRAG:IsScheduled()
  return self.status==AUFTRAG.Status.SCHEDULED
end

--- Check if mission is STARTED, i.e. group is on its way to the mission execution waypoint.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is started.
function AUFTRAG:IsStarted()
  return self.status==AUFTRAG.Status.STARTED
end

--- Check if mission is executing.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is currently executing.
function AUFTRAG:IsExecuting()
  return self.status==AUFTRAG.Status.EXECUTING
end

--- Check if mission was cancelled.
-- @param #AUFTRAG self
-- @return #boolean If true, mission was cancelled.
function AUFTRAG:IsCancelled()
  return self.status==AUFTRAG.Status.CANCELLED
end

--- Check if mission is done.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is done.
function AUFTRAG:IsDone()
  return self.status==AUFTRAG.Status.DONE
end

--- Check if mission was a success.
-- @param #AUFTRAG self
-- @return #boolean If true, mission was successful.
function AUFTRAG:IsSuccess()
  return self.status==AUFTRAG.Status.SUCCESS
end

--- Check if mission is over. This could be state DONE or CANCELLED.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is currently executing.
function AUFTRAG:IsOver()
  local over = self.status==AUFTRAG.Status.DONE or self.status==AUFTRAG.Status.CANCELLED or self.status==AUFTRAG.Status.SUCCESS or self.status==AUFTRAG.Status.FAILED
  return over
end

--- Check if mission is NOT over.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is NOT over yet.
function AUFTRAG:IsNotOver()
  return not self:IsOver()
end

--- Check if mission is ready to be started.
-- * Mission start time passed.
-- * Mission stop time did not pass already.
-- * All start conditions are true.
-- @param #AUFTRAG self
-- @return #boolean If true, mission can be started.
function AUFTRAG:IsReadyToGo()
  
  local Tnow=timer.getAbsTime()

  -- Start time did not pass yet.
  if self.Tstart and Tnow<self.Tstart or false then
    return false
  end
  
  -- Stop time already passed.
  if self.Tstop and Tnow>self.Tstop or false then
    return false
  end
  
  -- All start conditions true?
  local startme=self:EvalConditionsAll(self.conditionStart)
  
  if not startme then
    return false
  end
  

  -- We're good to go!
  return true
end

--- Check if mission is ready to be started.
-- * Mission stop already passed.
-- * Any stop condition is true.
-- @param #AUFTRAG self
-- @return #boolean If true, mission should be cancelled.
function AUFTRAG:IsReadyToCancel()
  
  local Tnow=timer.getAbsTime()

  -- Stop time already passed.
  if self.Tstop and Tnow>self.Tstop then
    return true
  end


  local failure=self:EvalConditionsAny(self.conditionFailure)
  
  if failure then
    self.failurecondition=true
    return true
  end  
  
  local success=self:EvalConditionsAny(self.conditionSuccess)
  
  if success then
    self.successcondition=true
    return true
  end
  
  -- No criterion matched.
  return false
end

--- Check if all given condition are true.
-- @param #AUFTRAG self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, all conditions were true. Returns false if at least one condition returned false.
function AUFTRAG:EvalConditionsAll(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --#AUFTRAG.Condition
  
    -- Call function.
    local istrue=condition.func(unpack(condition.arg))
    
    -- Any false will return false.
    if not istrue then
      return false
    end
    
  end

  -- All conditions were true.
  return true
end


--- Check if any of the given conditions is true.
-- @param #AUFTRAG self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, at least one condition is true.
function AUFTRAG:EvalConditionsAny(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --#AUFTRAG.Condition
  
    -- Call function.
    local istrue=condition.func(unpack(condition.arg))
    
    -- Any true will return true.
    if istrue then
      return true
    end
    
  end

  -- No condition was true.
  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Status" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStatus(From, Event, To)

  -- Number of alive mission targets.
  local Ntargets=self:CountMissionTargets()
  
  -- Number of alive groups attached to this mission.
  local Ngroups=self:CountOpsGroups()

  -- Check if mission is not OVER yet.
  if self:IsNotOver() then
 
    if self:CheckGroupsDone() then
    
      -- All groups have reported MISSON DONE.
      self:Done()
      
    elseif (self.Tstop and timer.getAbsTime()>self.Tstop+10) or (self.Ntargets>0 and Ntargets==0) then
    
      -- Cancel mission if stop time passed.
      self:Cancel()
            
    end
    
  end

  
  -- Current FSM state.
  local fsmstate=self:GetState()
  local Tnow=timer.getAbsTime()
  
  -- Mission start stop time.
  local Cstart=UTILS.SecondsToClock(self.Tstart, true)
  local Cstop=self.Tstop and UTILS.SecondsToClock(self.Tstop, true) or "INF"
  
  local targetname=self:GetTargetName() or "unknown"
  
  local airwing=self.airwing and self.airwing.alias or "N/A"
  local commander=self.wingcommander and tostring(self.wingcommander.coalition) or "N/A"

  -- Info message.
  self:I(self.lid..string.format("Status %s: Target=%s, T=%s-%s, assets=%d, groups=%d, targets=%d, wing=%s, commander=%s", self.status, targetname, Cstart, Cstop, #self.assets, Ngroups, Ntargets, airwing, commander))

  -- Check for error.  
  if fsmstate~=self.status then
    self:E(self.lid..string.format("ERROR: FSM state %s != %s mission status!", fsmstate, self.status))
  end

  local text="Group data:"  
  for groupname,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    text=text..string.format("\n- %s: status mission=%s opsgroup=%s", groupname, groupdata.status, groupdata.opsgroup and groupdata.opsgroup:GetState() or "N/A")
  end
  self:I(self.lid..text)

  local ready2evaluate=self.Tover and Tnow-self.Tover>=self.dTevaluate or false

  -- Check if mission is OVER (done or cancelled) and enough time passed to evaluate the result.
  if self:IsOver() and ready2evaluate then
    -- Evaluate success or failure of the mission.
    self:Evaluate()
  else
    self:__Status(-30)
  end
  
  -- Update F10 marker.
  self:UpdateMarker()
end

--- Evaluate mission outcome - success or failure.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:Evaluate()

  -- Assume success and check if any failed condition applies.
  local failed=false
  
  -- Any success condition true?
  local successCondition=self:EvalConditionsAny(self.conditionSuccess)
  
  -- Any failure condition true?
  local failureCondition=self:EvalConditionsAny(self.conditionFailure)
  
  -- Target damage in %.
  local targetdamage=self:GetTargetDamage()

  -- Current number of mission targets.
  local Ntargets=self:CountMissionTargets()
  
  -- Number of current targets is still >0 ==> Not everything was destroyed.
  if self.type==AUFTRAG.Type.TROOPTRANSPORT then

    if self.Ntargets>0 and Ntargets<self.Ntargets then
      failed=true
    end
  
  else
  
    if self.Ntargets>0 and Ntargets>0 then
      failed=true
    end
    
  end
  
  --TODO: all assets dead? Is this a FAILED criterion even if all targets have been destroyed? What if there are no initial targets (e.g. when ORBIT, PATROL, RECON missions).

  if failureCondition then
    failed=true
  elseif successCondition then
    failed=false
  end  
  
  -- Debug text.
  local text=string.format("Evaluating mission:\n")
  text=text..string.format("Targets      = %d/%d\n", self.Ntargets, Ntargets)
  text=text..string.format("Damage       = %.1f %%\n", targetdamage)
  text=text..string.format("Success Cond = %s\n", tostring(successCondition))
  text=text..string.format("Failure Cond = %s\n", tostring(failureCondition))
  text=text..string.format("Failed       = %s",   tostring(failed))
  self:I(self.lid..text)  
  
  if failed then
    self:Failed()
  else
    self:Success()
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Asset Data
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get all OPS groups.
-- @param #AUFTRAG self
-- @return #table Table of Ops.OpsGroup#OPSGROUP or {}.
function AUFTRAG:GetOpsGroups()
  local opsgroups={}
  for _,_groupdata in pairs(self.groupdata or {}) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    table.insert(opsgroups, groupdata.opsgroup)
  end
  return opsgroups
end

--- Get asset data table.
-- @param #AUFTRAG self
-- @param #string AssetName Name of the asset.
-- @return #AUFTRAG.GroupData Group data or *nil* if OPS group does not exist.
function AUFTRAG:GetAssetDataByName(AssetName)
  return self.groupdata[tostring(AssetName)]
end

--- Get flight data table.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @return #AUFTRAG.GroupData Flight data or nil if opsgroup does not exist.
function AUFTRAG:GetGroupData(opsgroup)
  if opsgroup and self.groupdata then
    return self.groupdata[opsgroup.groupname]
  end
  return nil
end

--- Set opsgroup mission status.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @param #string status New status.
function AUFTRAG:SetGroupStatus(opsgroup, status)
  self:T(self.lid..string.format("Setting flight %s to status %s", opsgroup and opsgroup.groupname or "nil", tostring(status)))

  if self:GetGroupStatus(opsgroup)==AUFTRAG.GroupStatus.CANCELLED and status==AUFTRAG.GroupStatus.DONE then
    -- Do not overwrite a CANCELLED status with a DONE status.
  else
    local groupdata=self:GetGroupData(opsgroup)
    if groupdata then
      groupdata.status=status
    else
      self:E(self.lid.."WARNING: Could not SET flight data for flight group. Setting status to DONE")
    end
  end
  
  -- Debug info.
  self:T2(self.lid..string.format("Setting flight %s status to %s. IsNotOver=%s  CheckGroupsDone=%s", opsgroup.groupname, self:GetGroupStatus(opsgroup), tostring(self:IsNotOver()), tostring(self:CheckGroupsDone())))

  -- Check if ALL flights are done with their mission.
  if self:IsNotOver() and self:CheckGroupsDone() then
    self:T3(self.lid.."All flights done ==> mission DONE!")
    self:Done()
  else
    self:T3(self.lid.."Mission NOT DONE yet!")
  end  
  
end

--- Get ops group mission status.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
function AUFTRAG:GetGroupStatus(opsgroup)
  self:T3(self.lid..string.format("Trying to get Flight status for flight group %s", opsgroup and opsgroup.groupname or "nil"))
  
  local groupdata=self:GetGroupData(opsgroup)
  
  if groupdata then
    return groupdata.status
  else
  
    self:E(self.lid..string.format("WARNING: Could not GET groupdata for opsgroup %s. Returning status DONE.", opsgroup and opsgroup.groupname or "nil"))
    return AUFTRAG.GroupStatus.DONE
    
  end
end


--- Set Ops group waypoint coordinate.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @param Core.Point#COORDINATE coordinate Waypoint Coordinate.
function AUFTRAG:SetGroupWaypointCoordinate(opsgroup, coordinate)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointcoordinate=coordinate
  end
end

--- Get opsgroup waypoint coordinate.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Waypoint Coordinate.
function AUFTRAG:GetGroupWaypointCoordinate(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointcoordinate
  end
end


--- Set Ops group waypoint task.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @param Ops.OpsGroup#OPSGROUP.Task task Waypoint task.
function AUFTRAG:SetGroupWaypointTask(opsgroup, task)
  self:I(self.lid..string.format("Setting waypoint task %s", task and task.description or "WTF"))
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointtask=task
  end
end

--- Get opsgroup waypoint task.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @return Ops.OpsGroup#OPSGROUP.Task task Waypoint task. Waypoint task.
function AUFTRAG:GetGroupWaypointTask(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointtask
  end
end

--- Set opsgroup waypoint index.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @param #number waypointindex Waypoint index.
function AUFTRAG:SetGroupWaypointIndex(opsgroup, waypointindex)
  self:I(self.lid..string.format("Setting waypoint index %d", waypointindex))
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointindex=waypointindex
  end
end

--- Get opsgroup waypoint index.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The flight group.
-- @return #number Waypoint index
function AUFTRAG:GetGroupWaypointIndex(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointindex
  end
end


--- Check if all flights are done with their mission (or dead).
-- @param #AUFTRAG self
-- @return #boolean If true, all flights are done with the mission.
function AUFTRAG:CheckGroupsDone()

  -- These are early stages, where we might not even have a opsgroup defined to be checked.
  if self:IsPlanned() or self:IsQueued() or self:IsRequested() then 
    return false
  end
  
  -- It could be that all flights were destroyed on the way to the mission execution waypoint.
  -- TODO: would be better to check if everybody is dead by now.
  if self:IsStarted() and self:CountOpsGroups()==0 then
    return true
  end
  
  -- Check status of all flight groups.
  for groupname,data in pairs(self.groupdata) do
    local groupdata=data --#AUFTRAG.GroupData
    if groupdata then
      if groupdata.status==AUFTRAG.GroupStatus.DONE or groupdata.status==AUFTRAG.GroupStatus.CANCELLED then
        -- This one is done or cancelled.
      else
        -- At least this flight is not DONE or CANCELLED.
        return false      
      end
    end
  end

  return true
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Unit lost event.
-- @param #AUFTRAG self
-- @param Core.Event#EVENTDATA EventData Event data.
function AUFTRAG:OnEventUnitLost(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName
    
    for _,_groupdata in pairs(self.groupdata) do
      local groupdata=_groupdata --#AUFTRAG.GroupData
      if groupdata and groupdata.opsgroup and groupdata.opsgroup.groupname==EventData.IniGroupName then
        self:I(self.lid..string.format("UNIT LOST event for opsgroup %s unit %s", groupdata.opsgroup.groupname, EventData.IniUnitName))
      end
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Queue" event. Mission is added to the mission queue of an AIRWING.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.AirWing#AIRWING Airwing The airwing.
function AUFTRAG:onafterQueued(From, Event, To, Airwing)
  self.status=AUFTRAG.Status.QUEUED
  self.airwing=Airwing
  self:I(self.lid..string.format("New mission status=%s at airwing %s", self.status, tostring(Airwing.alias)))
end


--- On after "Requested" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterRequested(From, Event, To)
  self.status=AUFTRAG.Status.REQUESTED
  self:I(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "Assign" event. 
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterAssign(From, Event, To)
  self.status=AUFTRAG.Status.ASSIGNED
  self:I(self.lid..string.format("New mission status=%s", self.status))  
end

--- On after "Schedule" event. Mission is added to the mission queue of a FLIGHTGROUP.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP FlightGroup
function AUFTRAG:onafterScheduled(From, Event, To, FlightGroup)
  self.status=AUFTRAG.Status.SCHEDULED
  self:I(self.lid..string.format("New mission status=%s", self.status))  
end

--- On after "Start" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStarted(From, Event, To)
  self.status=AUFTRAG.Status.STARTED
  self:I(self.lid..string.format("New mission status=%s", self.status))  
end

--- On after "Execute" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterExecuting(From, Event, To)
  self.status=AUFTRAG.Status.EXECUTING
  self:I(self.lid..string.format("New mission status=%s", self.status))  
end

--- On after "Done" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterDone(From, Event, To)
  self.status=AUFTRAG.Status.DONE
  self:I(self.lid..string.format("New mission status=%s", self.status))
  
  -- Set time stamp.
  self.Tover=timer.getAbsTime()
  
end


--- On after "GroupDead" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup The ops group that is dead now.
function AUFTRAG:onafterGroupDead(From, Event, To, OpsGroup)

  local asset=self:GetAssetByName(OpsGroup.groupname)
  if asset then
    self:AssetDead(asset)
  end
  
end

--- On after "AssetDead" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The asset.
function AUFTRAG:onafterAssetDead(From, Event, To, Asset)
    
  -- Remove opsgroup from mission.
  --self:DelOpsGroup(Asset.opsgroup)
  
  local N=self:CountOpsGroups()
  
  -- All assets dead?
  if N==0 then
  
    if self:IsNotOver() then
    
      -- Cancel mission. Wait for next mission update to evaluate SUCCESS or FAILURE.
      self:Cancel()
      
    else
      
      self:E(self.lid.."ERROR: All assets are dead not but mission was already over... Investigate!")
      -- Now this can happen, because when a opsgroup dies (sometimes!), the mission is DONE
      
    end
  end
  
  -- Remove asset from airwing.
  if self.airwing then
    self.airwing:RemoveAssetFromSquadron(Asset)
  end

  -- Delete asset from mission.
  self:DelAsset(Asset)

end

--- On after "Success" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterSuccess(From, Event, To)

  self.status=AUFTRAG.Status.SUCCESS
  self:I(self.lid..string.format("New mission status=%s", self.status))
  
  -- Stop mission.
  self:Stop()

end

--- On after "Cancel" event. Cancells the mission.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterCancel(From, Event, To)

  -- Debug info.
  self:I(self.lid..string.format("CANCELLING mission in status %s. Will wait for groups to report mission DONE before evaluation.", self.status))
  
  -- Time stamp.
  self.Tover=timer.getAbsTime()
  
  -- No more repeats.
  self.missionRepeatMax=self.missionRepeated
  
  -- Not necessary to delay the evaluaton?!
  self.dTevaluate=0
  
  if self.wingcommander then
  
    self:I(self.lid..string.format("Wingcommander will cancel the mission. Will wait for mission DONE before evaluation!"))
    
    self.wingcommander:CancelMission(self)

  elseif self.airwing then
    
    self:I(self.lid..string.format("Airwing %s will cancel the mission. Will wait for mission DONE before evaluation!", self.airwing.alias))
    
    -- Airwing will cancel all flight missions and remove queued request from warehouse queue.
    self.airwing:MissionCancel(self)
  
  else
  
    self:I(self.lid..string.format("No airwing or wingcommander. Attached flights will cancel the mission on their own. Will wait for mission DONE before evaluation!"))
  
    for _,_groupdata in pairs(self.groupdata) do
      local groupdata=_groupdata --#AUFTRAG.GroupData
      groupdata.opsgroup:MissionCancel(self)
    end
    
  end
  
  -- Special mission states.
  if self.status==AUFTRAG.Status.PLANNED then
    self:I(self.lid..string.format("Cancelled mission was in planned stage. Call it done!"))
    self:Done()
  end

end

--- On after "Failed" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterFailed(From, Event, To)

  self.status=AUFTRAG.Status.FAILED
  self:I(self.lid..string.format("New mission status=%s", self.status))
  
  if self.missionRepeated>=self.missionRepeatMax then
  
    self:I(self.lid..string.format("Mission FAILED! Number of max repeats reached [%d>=%d] ==> Stopping mission!", self.missionRepeated, self.missionRepeatMax))
    self:Stop()
    
  else
        
    -- Repeat mission.
    self:I(self.lid..string.format("Mission failed! Repeating mission for the %d time (max %d times) ==> Repeat mission!", self.missionRepeated+1, self.missionRepeatMax))
    self:Repeat()
    
  end  

end


--- On after "Repeat" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterRepeat(From, Event, To)

  -- Set mission status to PLANNED.
  self.status=AUFTRAG.Status.PLANNED
  
  self:I(self.lid..string.format("New mission status=%s (on Repeat)", self.status))

  -- Increase repeat counter.
  self.missionRepeated=self.missionRepeated+1
  
  if self.wingcommander then
    
  elseif self.airwing then
  
    -- Already at the airwing ==> Queued()
    self:Queued(self.airwing)  
    
  else
  
  end
  
  
  -- No mission assets.
  self.assets={}
  
  for _,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    local opsgroup=groupdata.opsgroup
    if opsgroup then
      self:DelOpsGroup(opsgroup)
    end
    
  end  
  -- No flight data.
  self.groupdata={}
  
  -- Call status again.
  self:__Status(-30)

end

--- On after "Stop" event. Remove mission from AIRWING and FLIGHTGROUP mission queues.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStop(From, Event, To)

  self:I(self.lid..string.format("STOPPED mission in status=%s. Removing missions from queues. Stopping CallScheduler!", self.status))

  -- TODO: remove missions from queues in WINGCOMMANDER, AIRWING and FLIGHGROUPS!  
  -- TODO: Mission should be OVER! we dont want to remove running missions from any queues.
  
  if self.wingcommander then
    self.wingcommander:RemoveMission(self)
  end
  
  if self.airwing then
    self.airwing:RemoveMission(self)
  end

  for _,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    groupdata.opsgroup:RemoveMission(self)
  end

  -- No mission assets.
  self.assets={}
  
  -- No flight data.
  self.groupdata={}

  -- Clear pending scheduler calls.
  self.CallScheduler:Clear()
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add asset to mission.
-- @param #AUFTRAG self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The asset to be added to the mission.
-- @return #AUFTRAG self
function AUFTRAG:AddAsset(Asset)

  self.assets=self.assets or {}
  
  table.insert(self.assets, Asset)

  return self
end

--- Delete asset from mission.
-- @param #AUFTRAG self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset  The asset to be removed.
-- @return #AUFTRAG self
function AUFTRAG:DelAsset(Asset)

  for i,_asset in pairs(self.assets or {}) do
    local asset=_asset --Ops.AirWing#AIRWING.SquadronAsset
    
    if asset.uid==Asset.uid then
      self:I(self.lid..string.format("Removing asset \"%s\" from mission", tostring(asset.spawngroupname)))
      table.remove(self.assets, i)
      return self
    end
    
  end

  return self
end

--- Get asset by its spawn group name.
-- @param #AUFTRAG self
-- @param #string Name Asset spawn group name.
-- @return Ops.AirWing#AIRWING.SquadronAsset
function AUFTRAG:GetAssetByName(Name)

  for i,_asset in pairs(self.assets or {}) do
    local asset=_asset --Ops.AirWing#AIRWING.SquadronAsset
    
    if asset.spawngroupname==Name then
      return asset
    end
    
  end

  return nil
end


--- Count alive mission targets.
-- @param #AUFTRAG self
-- @param #AUFTRAG.TargetData Target (Optional) The target object.
-- @return #number Number of alive target units.
function AUFTRAG:CountMissionTargets(Target)
  
  local N=0
  
  Target=Target or self:GetTargetData()
  
  if Target then
  
    if Target.Type==AUFTRAG.TargetType.GROUP then
    
      local target=Target.Target --Wrapper.Group#GROUP
      
      local units=target:GetUnits()
      
      for _,_unit in pairs(units or {}) do
        local unit=_unit --Wrapper.Unit#UNIT
        
        -- We check that unit is "alive" and has health >1. Somtimes units get heavily damanged but are still alive.
        -- TODO: here I could introduce and count that if units have only health < 50% if mission objective is to just "damage" the units.
        if unit and unit:IsAlive() and unit:GetLife()>1 then
          N=N+1
        end
      end      
      
    elseif Target.Type==AUFTRAG.TargetType.UNIT then
    
      local target=Target.Target --Wrapper.Unit#UNIT        
      
      if target and target:IsAlive() and target:GetLife()>1 then
        N=N+1
      end
      
    elseif Target.Type==AUFTRAG.TargetType.STATIC then
    
      local target=Target.Target --Wrapper.Static#STATIC
      
      if target and target:IsAlive() then
        N=N+1
      end
      
    elseif Target.Type==AUFTRAG.TargetType.AIRBASE then
    
      -- TODO: any (good) way to tell whether an airbase was "destroyed" or at least damaged? Is :GetLive() working?
      
    elseif Target.Type==AUFTRAG.TargetType.COORDINATE then
    
      -- No target!

    elseif Target.Type==AUFTRAG.TargetType.SETGROUP then
    
      for _,_group in pairs(Target.Target.Set or {}) do
        local group=_group --Wrapper.Group#GROUP
        
        local units=group:GetUnits()
        
        for _,_unit in pairs(units or {}) do
          local unit=_unit --Wrapper.Unit#UNIT
          
          -- We check that unit is "alive".
          if unit and unit:IsAlive() and unit:GetLife()>1 then
            N=N+1
          end
        end              
        
      end
    
    elseif Target.Type==AUFTRAG.TargetType.SETUNIT then

      for _,_unit in pairs(Target.Target.Set or {}) do
        local unit=_unit --Wrapper.Unit#UNIT

        -- We check that unit is "alive".
        if unit and unit:IsAlive() and unit:GetLife()>1 then
          N=N+1
        end
                
      end

    else
      self:E("ERROR unknown target type")      
    end
  end
  
  return N
end

--- Get target life points.
-- @param #AUFTRAG self
-- @return #number Number of initial life points when mission was planned.
function AUFTRAG:GetTargetInitialLife()
  return self:GetTargetData().Lifepoints
end

--- Get target damage.
-- @param #AUFTRAG self
-- @return #number Damage in percent.
function AUFTRAG:GetTargetDamage()
  local target=self:GetTargetData()
  local life=self:GetTargetLife()/self:GetTargetInitialLife()
  local damage=1-life
  return damage*100
end


--- Get target life points.
-- @param #AUFTRAG self
-- @return #number Life points of target.
function AUFTRAG:GetTargetLife()
  return self:_GetTargetLife(nil, false)
end

--- Get target life points.
-- @param #AUFTRAG self
-- @param #AUFTRAG.TargetData Target (Optional) The target object.
-- @param #boolean Healthy Get the life points of the healthy target. 
-- @return #number Life points of target.
function AUFTRAG:_GetTargetLife(Target, Healthy)
  
  local N=0
  
  Target=Target or self:GetTargetData()
  
  local function _GetLife(unit)
    local unit=unit --Wrapper.Unit#UNIT
    if Healthy then
      local life=unit:GetLife()
      local life0=unit:GetLife0()
      
      return math.max(life, life0)
    else
      return unit:GetLife()
    end
  end
  
  if Target then
  
    if Target.Type==AUFTRAG.TargetType.GROUP then
    
      local target=Target.Target --Wrapper.Group#GROUP
      
      local units=target:GetUnits()
      
      for _,_unit in pairs(units or {}) do
        local unit=_unit --Wrapper.Unit#UNIT
        
        -- We check that unit is "alive".
        if unit and unit:IsAlive() then
          N=N+_GetLife(unit)
        end
      end      
      
    elseif Target.Type==AUFTRAG.TargetType.UNIT then
    
      local target=Target.Target --Wrapper.Unit#UNIT        
      
      if target and target:IsAlive() then
        N=N+_GetLife(target)
      end
      
    elseif Target.Type==AUFTRAG.TargetType.STATIC then
    
      local target=Target.Target --Wrapper.Static#STATIC
      
      -- Statics are alive or not.
      if target and target:IsAlive() then
        N=N+1 --_GetLife(target)
      else
        N=N+0
      end
      
    elseif Target.Type==AUFTRAG.TargetType.AIRBASE then
    
      -- TODO: any (good) way to tell whether an airbase was "destroyed" or at least damaged? Is :GetLive() working?
      N=N+1

    elseif Target.Type==AUFTRAG.TargetType.COORDINATE then
    
      -- A coordinate does not live.
      N=N+1
      
    elseif Target.Type==AUFTRAG.TargetType.SETGROUP then
    
      for _,_group in pairs(Target.Target.Set or {}) do
        local group=_group --Wrapper.Group#GROUP
        
        local units=group:GetUnits()
        
        for _,_unit in pairs(units or {}) do
          local unit=_unit --Wrapper.Unit#UNIT
          
          -- We check that unit is "alive".
          if unit and unit:IsAlive() then
            N=N+_GetLife(unit)
          end
        end              
        
      end
    
    elseif Target.Type==AUFTRAG.TargetType.SETUNIT then

      for _,_unit in pairs(Target.Target.Set or {}) do
        local unit=_unit --Wrapper.Unit#UNIT

        -- We check that unit is "alive".
        if unit and unit:IsAlive() then
          N=N+_GetLife(unit)
        end
                
      end

    else
      self:E(self.lid.."ERROR unknown target type")      
    end
  end
  
  return N
end

--- Count alive flight groups assigned for this mission.
-- @param #AUFTRAG self
-- @return #number Number of alive flight groups.
function AUFTRAG:CountOpsGroups()
  local N=0
  for _,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    if groupdata and groupdata.opsgroup and groupdata.opsgroup:IsAlive() then
      N=N+1
    end
  end
  return N
end

--- Get coordinate of target.
-- @param #AUFTRAG self
-- @return #AUFTRAG.TargetData The target object. Could be many things.
function AUFTRAG:GetTargetData()
  return self.engageTarget
end

--- Get mission objective object. Could be many things depending on the mission type.
-- @param #AUFTRAG self
-- @return Wrapper.Positionable#POSITIONABLE The target object. Could be many things.
function AUFTRAG:GetObjective()
  return self:GetTargetData().Target
end

--- Get type of target.
-- @param #AUFTRAG self
-- @return #string The target type.
function AUFTRAG:GetTargetType()
  return self:GetTargetData().Type
end

--- Get 2D vector of target.
-- @param #AUFTRAG self
-- @return DCS#VEC2 The target 2D vector or *nil*.
function AUFTRAG:GetTargetVec2()
  local coord=self:GetTargetCoordinate()
  if coord then
    return coord:GetVec2()
  end
  return nil
end

--- Get coordinate of target.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE The target coordinate or *nil*.
function AUFTRAG:GetTargetCoordinate()
  
  if self.transportPickup then
  
    -- Special case where we defined a 
    return self.transportPickup
    
  else
  
    local target
  
    if self:GetTargetType()==AUFTRAG.TargetType.COORDINATE then
    
      -- Here the objective itself is a COORDINATE.
      return self:GetObjective()
      
    elseif self:GetTargetType()==AUFTRAG.TargetType.SETGROUP then
    
      -- Return the first group in the set.
      -- TODO: does this only return ALIVE groups?!
      return self:GetObjective():GetFirst():GetCoordinate()
      
    elseif self:GetTargetType()==AUFTRAG.TargetType.SETUNIT then
    
      -- Return the first unit in the set.
      -- TODO: does this only return ALIVE units?!
      return self:GetObjective():GetFirst():GetCoordinate()
      
    else
    
      -- In all other cases the GetCoordinate() function should work.
      return self:GetObjective():GetCoordinate()
      
    end  
  end

  return nil
end

--- Get name of the target.
-- @param #AUFTRAG self
-- @return #string Name of the target or "N/A".
function AUFTRAG:GetTargetName()
  
  if self.engageTarget.Target then
    return self.engageTarget.Name
  end
    
  return "N/A"
end


--- Get distance to target.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE FromCoord The coordinate from which the distance is measured.
-- @return #number Distance in meters or 0.
function AUFTRAG:GetTargetDistance(FromCoord)

  local TargetCoord=self:GetTargetCoordinate()
  
  if TargetCoord and FromCoord then
    return TargetCoord:Get2DDistance(FromCoord)
  else
    self:E(self.lid.."ERROR: TargetCoord or FromCoord does not exist in AUFTRAG:GetTargetDistance() function! Returning 0")
  end
  
  return 0
end

--- Get coordinate of target. First unit/group of the set is used.
-- @param #AUFTRAG self
-- @return #string
function AUFTRAG:GetMissionTypesText(MissionTypes)

  local text=""
  for _,missiontype in pairs(MissionTypes) do
    text=text..string.format("%s, ", missiontype)
  end

  return text
end

--- Get coordinate of target. First unit/group of the set is used.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP group Group.
-- @return Core.Point#COORDINATE Coordinate where the mission is executed.
function AUFTRAG:GetMissionWaypointCoord(group)

  -- Create waypoint coordinate half way between us and the target.
  local waypointcoord=group:GetCoordinate():GetIntermediateCoordinate(self:GetTargetCoordinate(), self.missionFraction)
  local alt=waypointcoord.y
  
  -- Add some randomization.
  waypointcoord=ZONE_RADIUS:New("Temp", waypointcoord:GetVec2(), 1000):GetRandomCoordinate():SetAltitude(alt, false)
  
  -- Set altitude of mission waypoint.
  if self.missionAltitude then
    waypointcoord:SetAltitude(self.missionAltitude, true)
  end

  return waypointcoord
end


--- Set log ID string.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:_SetLogID()
  self.lid=string.format("Auftrag #%d %s | ", self.auftragsnummer, tostring(self.type))
  return self
end

--- Update mission F10 map marker.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:UpdateMarker()

  -- Marker text.
  local text=string.format("%s %s: %s", self.name, self.type:upper(), self.status:upper())
  text=text..string.format("\n%s", self:GetTargetName())
  text=text..string.format("\nTargets %d/%d, Life Points=%d/%d", self:CountMissionTargets(), self.Ntargets, self:GetTargetLife(), self:GetTargetInitialLife())
  text=text..string.format("\nFlights %d/%d", self:CountOpsGroups(), self.nassets)

  if not self.marker then
  
    -- Get target coordinates. Can be nil!
    local targetcoord=self:GetTargetCoordinate()
    
    self.marker=MARKER:New(targetcoord, text):ReadOnly():ToAll()
    
  else
  
    if self.marker:GetText()~=text then
      self.marker:UpdateText(text)
    end
    
  end

  return self
end

--- Get DCS task table for the given mission.
-- @param #AUFTRAG self
-- @param Wrapper.Controllable#CONTROLLABLE TaskControllable The controllable for which this task is set. Most tasks don't need it.
-- @return DCS#Task The DCS task table. If multiple tasks are necessary, this is returned as a combo task.
function AUFTRAG:GetDCSMissionTask(TaskControllable)

  local DCStasks={}

  -- Create DCS task based on current self.
  if self.type==AUFTRAG.Type.ANTISHIP then
  
    ----------------------
    -- ANTISHIP Mission --
    ----------------------

    self:_GetDCSAttackTask(self.engageTarget, DCStasks)
  
  elseif self.type==AUFTRAG.Type.AWACS then
  
    -------------------
    -- AWACS Mission --
    -------------------  

    local DCStask=CONTROLLABLE.EnRouteTaskAWACS(nil)
    
    table.insert(self.enrouteTasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.BAI then
  
    -----------------
    -- BAI Mission --
    -----------------  

    self:_GetDCSAttackTask(self.engageTarget, DCStasks)

  elseif self.type==AUFTRAG.Type.BOMBING then
  
    ---------------------
    -- BOMBING Mission --
    ---------------------
  
    local DCStask=CONTROLLABLE.TaskBombing(nil, self:GetTargetVec2(), self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, Divebomb)
  
    table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.BOMBRUNWAY then
  
    ------------------------
    -- BOMBRUNWAY Mission --
    ------------------------
    
    local DCStask=CONTROLLABLE.TaskBombingRunway(nil, self.engageTarget.Target, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAsGroup)
  
    table.insert(DCStasks, DCStask)    

  elseif self.type==AUFTRAG.Type.BOMBCARPET then
  
    ------------------------
    -- BOMBCARPET Mission --
    ------------------------
    
    local DCStask=CONTROLLABLE.TaskCarpetBombing(nil, self:GetTargetVec2(), self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, self.engageCarpetLength)
  
    table.insert(DCStasks, DCStask)    

  elseif self.type==AUFTRAG.Type.CAP then
  
    -----------------
    -- CAP Mission --
    -----------------  

    local DCStask=CONTROLLABLE.EnRouteTaskEngageTargetsInZone(nil, self.engageZone:GetVec2(), self.engageZone:GetRadius(), self.engageTargetTypes, Priority)
    
    table.insert(self.enrouteTasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.CAS then
  
    -----------------
    -- CAS Mission --
    -----------------

    local DCStask=CONTROLLABLE.EnRouteTaskEngageTargetsInZone(nil, self.engageZone:GetVec2(), self.engageZone:GetRadius(), self.engageTargetTypes, Priority)
    
    table.insert(self.enrouteTasks, DCStask)

  elseif self.type==AUFTRAG.Type.ESCORT then
  
    --------------------
    -- ESCORT Mission --
    --------------------

    local DCStask=CONTROLLABLE.TaskEscort(nil, self.engageTarget.Target, self.escortVec3, LastWaypointIndex, self.engageMaxDistance, self.engageTargetTypes)
    
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.FACA then
  
    -----------------
    -- FAC Mission --
    -----------------  

    local DCStask=CONTROLLABLE.TaskFAC_AttackGroup(nil, self.engageTarget.Target, self.engageWeaponType, self.facDesignation, self.facDatalink, self.facFreq, self.facModu, CallsignName, CallsignNumber)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.FERRY then
  
    -------------------
    -- FERRY Mission --
    -------------------
  
    -- TODO: Ferry mission type. How?
  
  elseif self.type==AUFTRAG.Type.INTERCEPT then

    -----------------------
    -- INTERCEPT Mission --
    -----------------------

    self:_GetDCSAttackTask(self.engageTarget, DCStasks)

  elseif self.type==AUFTRAG.Type.ORBIT then
  
    -------------------
    -- ORBIT Mission --
    -------------------
  
    -- Done below as also other mission types use the orbit task.

  elseif self.type==AUFTRAG.Type.PATROL then
  
    --------------------
    -- PATROL Mission --
    --------------------
  
    -- Done below as also other mission types use the orbit task.
  
  elseif self.type==AUFTRAG.Type.RECON then
  
    -------------------
    -- RECON Mission --
    -------------------  

    -- TODO: What? Table of coordinates?

  elseif self.type==AUFTRAG.Type.SEAD then
  
    ------------------
    -- SEAD Mission --
    ------------------  

    --[[
    local DCStask=CONTROLLABLE.EnRouteTaskEngageTargets(nil, nil ,{"Air Defence"} , 0)
    table.insert(self.enrouteTasks, DCStask)
    DCStask.key="SEAD"
    ]]
    
    self:_GetDCSAttackTask(self.engageTarget, DCStasks)
  
  elseif self.type==AUFTRAG.Type.STRIKE then
  
    --------------------
    -- STRIKE Mission --
    -------------------- 
  
    local DCStask=CONTROLLABLE.TaskAttackMapObject(nil, self:GetTargetVec2(), self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.TANKER then
  
    --------------------
    -- TANKER Mission --
    -------------------- 

    local DCStask=CONTROLLABLE.EnRouteTaskTanker(nil)
    
    table.insert(self.enrouteTasks, DCStask)    
  
  elseif self.type==AUFTRAG.Type.TROOPTRANSPORT then

    ----------------------------
    -- TROOPTRANSPORT Mission --
    ----------------------------
  
    -- Task to embark the troops at the pick up point.
    local TaskEmbark=CONTROLLABLE.TaskEmbarking(TaskControllable, self.transportPickup,  self.transportGroupSet, self.transportWaitForCargo)
    
    -- Task to disembark the troops at the drop off point.
    local TaskDisEmbark=CONTROLLABLE.TaskDisembarking(TaskControllable, self.transportDropoff, self.transportGroupSet)    
    
    table.insert(DCStasks, TaskEmbark)
    table.insert(DCStasks, TaskDisEmbark)

  elseif self.type==AUFTRAG.Type.RESCUEHELO then

    -------------------------
    -- RESCUE HELO Mission --
    -------------------------
  
    local DCStask={}
    
    DCStask.id="Formation"
    
    -- We create a "fake" DCS task and pass the parameters to the FLIGHTGROUP.
    local param={}
    param.unitname=self:GetTargetName()
    param.offsetX=200
    param.offsetZ=240
    param.altitude=70
    param.dtFollow=1.0
    
    DCStask.params=param
    
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.ARTY then

    ------------------
    -- ARTY Mission --
    ------------------
  
    local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, self:GetTargetVec2(), self.artyRadius, self.artyShots, self.engageWeaponType)
    
    table.insert(DCStasks, DCStask)    
  
  else
    self:E(self.lid..string.format("ERROR: Unknown mission task!"))
    return nil
  end
  
  
  -- Set ORBIT task. Also applies to other missions: AWACS, TANKER, CAP, CAS.
  if self.type==AUFTRAG.Type.ORBIT  or 
     self.type==AUFTRAG.Type.CAP    or
     self.type==AUFTRAG.Type.CAS    or
     self.type==AUFTRAG.Type.PATROL or
     self.type==AUFTRAG.Type.AWACS  or 
     self.type==AUFTRAG.Type.TANKER then

    -------------------
    -- ORBIT Mission --
    -------------------
  
    local Coordinate=self:GetTargetCoordinate()
  
    local DCStask=CONTROLLABLE.TaskOrbit(nil, Coordinate, self.orbitAltitude, self.orbitSpeed, self.orbitRaceTrack)
    
    table.insert(DCStasks, DCStask)
  
  end
  
  -- Debug info.
  self:T3({missiontask=DCStasks})

  -- Return the task.
  if #DCStasks==1 then
    return DCStasks[1]
  else
    return CONTROLLABLE.TaskCombo(nil, DCStasks)
  end

end

--- Get DCS task table for an attack group or unit task.
-- @param #AUFTRAG self
-- @param #AUFTRAG.TargetData target Target data.
-- @param #table DCStasks DCS DCS tasks table to which the task is added.
-- @return DCS#Task The DCS task table.
function AUFTRAG:_GetDCSAttackTask(target, DCStasks)

  local DCStask=nil

  if target.Type==AUFTRAG.TargetType.GROUP then

    DCStask=CONTROLLABLE.TaskAttackGroup(nil, target.Target, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageAsGroup)
    
    table.insert(DCStasks, DCStask)
  
  elseif target.Type==AUFTRAG.TargetType.UNIT or target.Type==AUFTRAG.TargetType.STATIC then
  
    DCStask=CONTROLLABLE.TaskAttackUnit(nil, target.Target, self.engageAsGroup, self.WeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
    
    table.insert(DCStasks, DCStask)
  
  elseif target.Type==AUFTRAG.TargetType.SETGROUP then
  
    -- Add all groups.
    for _,group in pairs(target.Target.Set or {}) do
      DCStask=CONTROLLABLE.TaskAttackGroup(nil, group, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageAsGroup)
      table.insert(DCStasks, DCStask)
    end
  
  elseif target.Type==AUFTRAG.TargetType.SETUNIT then

    -- Add tasks to attack all units.
    for _,unit in pairs(target.Target.Set or {}) do
      DCStask=CONTROLLABLE.TaskAttackUnit(nil, unit, self.engageAsGroup, self.WeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
      table.insert(DCStasks, DCStask)
    end
  
  end

  return DCStasks
end

--- Create target data from a given object.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Object The target GROUP, UNIT, STATIC.
-- @return #AUFTRAG.TargetData Target.
function AUFTRAG:_TargetFromObject(Object)
  
  local target={} --#AUFTRAG.TargetData
  
  -- The object.
  target.Target=Object
  
  if Object:IsInstanceOf("GROUP") then
  
    target.Type=AUFTRAG.TargetType.GROUP
    
    local object=Object --Wrapper.Group#GROUP
    
    target.Name=object:GetName()
    
  elseif Object:IsInstanceOf("UNIT") then
  
    target.Type=AUFTRAG.TargetType.UNIT
    
    local object=Object --Wrapper.Unit#UNIT
    
    target.Name=object:GetName()  
  
  elseif Object:IsInstanceOf("STATIC") then
  
    target.Type=AUFTRAG.TargetType.STATIC
    
    target.Name=Object:GetName()
  
  elseif Object:IsInstanceOf("COORDINATE") then
  
    target.Type=AUFTRAG.TargetType.COORDINATE
    
    local object=Object --Core.Point#COORDINATE
    
    target.Name=object:ToStringLLDMS()
    
  elseif Object:IsInstanceOf("AIRBASE") then
  
    target.Type=AUFTRAG.TargetType.AIRBASE
    
    local object=Object --Wrapper.Airbase#AIRBASE
    
    target.Name=object:GetName()
    
  elseif Object:IsInstanceOf("SET_GROUP") then
  
    target.Type=AUFTRAG.TargetType.SETGROUP
    
    local object=Object --Core.Set#SET_GROUP
    
    target.Name=object:GetFirst():GetName()
  
  elseif Object:IsInstanceOf("SET_UNIT") then
  
    target.Type=AUFTRAG.TargetType.SETUNIT
    
    local object=Object --Core.Set#SET_UNIT
    
    target.Name=object:GetFirst():GetName()
  
  else
    self:E(self.lid.."ERROR: Unknown object given as target. Needs to be a GROUP, UNIT, STATIC, COORDINATE")
    return nil
  end
  
  
  -- Number of initial targets.
  local Ninitial=self:CountMissionTargets(target)
  
  -- Initial total life point.
  local Lifepoints=self:_GetTargetLife(target, true)
    
  -- Set engage Target.
  self.engageTarget=target  
  self.engageTarget.Ninital=Ninitial  
  self.engageTarget.Lifepoints=Lifepoints
  
  -- TODO: get rid of this.
  self.Ntargets=Ninitial
  
  -- Debug info.
  self:I(self.lid..string.format("Mission Target %s Type=%s, Ntargets=%d, Lifepoints=%d", target.Name, target.Type, Ninitial, Lifepoints))
  
  return target
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
