---@diagnostic disable: undefined-global
--- **Ops** - Auftrag (mission) for Ops.
--
-- ## Main Features:
--
--    * Simplifies defining and executing DCS tasks
--    * Additional useful events
--    * Set mission start/stop times
--    * Set mission priority and urgency (can cancel running missions)
--    * Specific mission options for ROE, ROT, formation, etc.
--    * Compatible with OPS classes like FLIGHTGROUP, NAVYGROUP, ARMYGROUP, AIRWING, etc.
--    * FSM events when a mission is done, successful or failed
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Auftrag).
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module Ops.Auftrag
-- @image OPS_Auftrag.png


--- AUFTRAG class.
-- @type AUFTRAG
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number auftragsnummer Auftragsnummer.
-- @field #string type Mission type.
-- @field #table categories Mission categories.
-- @field #string status Mission status.
-- @field #table legions Assigned legions.
-- @field #table statusLegion Mission status of all assigned LEGIONs.
-- @field #string statusCommander Mission status of the COMMANDER.
-- @field #string statusChief Mission status of the CHIEF.
-- @field #table groupdata Group specific data.
-- @field #string name Mission name.
-- @field #number prio Mission priority.
-- @field #boolean urgent Mission is urgent. Running missions with lower prio might be cancelled.
-- @field #number importance Importance.
-- @field #number Tstart Mission start time in abs. seconds.
-- @field #number Tstop Mission stop time in abs. seconds.
-- @field #number duration Mission duration in seconds.
-- @field #number durationExe Mission execution time in seconds.
-- @field #number Texecuting Time stamp (abs) when mission is executing. Is `#nil` on start.
-- @field #number Tpush Mission push/execute time in abs. seconds.
-- @field #number Tstarted Time stamp (abs) when mission is started.
-- @field Wrapper.Marker#MARKER marker F10 map marker.
-- @field #boolean markerOn If true, display marker on F10 map with the AUFTRAG status.
-- @field #number markerCoaliton Coalition to which the marker is dispayed.
-- @field #table DCStask DCS task structure.
-- @field #number Ncasualties Number of own casualties during mission.
-- @field #number Nkills Number of (enemy) units killed by assets of this mission.
-- @field #number Ndead Number of assigned groups that are dead.
-- @field #number Nassigned Number of assigned groups.
-- @field #number Nelements Number of elements (units) assigned to mission.
-- @field #number dTevaluate Time interval in seconds before the mission result is evaluated after mission is over.
-- @field #number Tover Mission abs. time stamp, when mission was over.
-- @field #boolean updateDCSTask If `true`, DCS task is updated at every status update of the assigned groups.
-- @field #table conditionStart Condition(s) that have to be true, before the mission will be started.
-- @field #table conditionSuccess If all conditions are true, the mission is cancelled.
-- @field #table conditionFailure If all conditions are true, the mission is cancelled.
-- @field #table conditionPush If all conditions are true, the mission is executed. Before, the group(s) wait at the mission execution waypoint.
-- @field #boolean conditionSuccessSet
-- @field #boolean conditionFailureSet
--
-- @field #number orbitSpeed Orbit speed in m/s.
-- @field #number orbitAltitude Orbit altitude in meters.
-- @field #number orbitHeading Orbit heading in degrees.
-- @field #number orbitLeg Length of orbit leg in meters.
-- @field DCS#Vec2 orbitOffsetVec2 2D offset vector.
-- @field DCS#Vec2 orbitVec2 2D orbit vector.
-- @field #number orbitDeltaR Distance threshold in meters for moving orbit targets.
--
-- @field Ops.Target#TARGET engageTarget Target data to engage.
-- @field #number targetHeading Heading of target in degrees.
-- 
-- @field Ops.Operation#OPERATION operation Operation this mission is part of.
-- 
-- @field #boolean teleport Groups are teleported to the mission ingress waypoint.
--
-- @field Core.Zone#ZONE_RADIUS engageZone *Circular* engagement zone.
-- @field #table engageTargetTypes Table of target types that are engaged in the engagement zone.
-- @field #number engageAltitude Engagement altitude in meters.
-- @field #number engageDirection Engagement direction in degrees.
-- @field #number engageQuantity Number of times a target is engaged.
-- @field #number engageWeaponType Weapon type used.
-- @field #number engageWeaponExpend How many weapons are used.
-- @field #boolean engageAsGroup Group attack.
-- @field #number engageLength Length of engage (carpet or strafing) in meters.
-- @field #number engageMaxDistance Max engage distance.
-- @field #number refuelSystem Refuel type (boom or probe) for TANKER missions.
--
-- @field Wrapper.Group#GROUP escortGroup The group to be escorted.
-- @field #string escortGroupName Name of the escorted group.
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
-- @field #number transportPickupRadius Radius in meters for pickup zone. Default 500 m.
--
-- @field Ops.OpsTransport#OPSTRANSPORT opstransport OPS transport assignment.
-- @field #number NcarriersMin Min number of required carrier assets.
-- @field #number NcarriersMax Max number of required carrier assets.
-- @field Core.Zone#ZONE transportDeployZone Deploy zone of an OPSTRANSPORT.
-- @field Core.Zone#ZONE transportDisembarkZone Disembark zone of an OPSTRANSPORT.
-- @param #table carrierCategories Transport group categories.
-- @field #table carrierAttributes Generalized attribute(s) of transport assets.
-- @field #table carrierProperties DCS attribute(s) of transport assets.
--
-- @field #number artyRadius Radius in meters.
-- @field #number artyShots Number of shots fired.
-- @field #number artyAltitude Altitude in meters. Can be used for a Barrage.
-- @field #number artyHeading Heading in degrees (for Barrage).
-- @field #number artyAngle Shooting angle in degrees (for Barrage).
--
-- @field #string alert5MissionType Alert 5 mission type. This is the mission type, the alerted assets will be able to carry out.
-- 
-- @field #table attributes Generalized attribute(s) of assets.
-- @field #table properties DCS attribute(s) of assets.
--
-- @field Ops.Chief#CHIEF chief The CHIEF managing this mission.
-- @field Ops.Commander#COMMANDER commander The COMMANDER managing this mission.
-- @field #table assets Warehouse assets assigned for this mission.
-- @field #number NassetsMin Min. number of required warehouse assets.
-- @field #number NassetsMax Max. number of required warehouse assets.
-- @field #number NescortMin Min. number of required escort assets for each group the mission is assigned to.
-- @field #number NescortMax Max. number of required escort assets for each group the mission is assigned to.
-- @field #string escortMissionType Escort mission type.
-- @field #table escortTargetTypes Target types that will be engaged.
-- @field #number escortEngageRange Engage range in nautical miles (NM).
-- @field #number Nassets Number of requested warehouse assets.
-- @field #table NassetsLegMin Number of required warehouse assets for each assigned legion.
-- @field #table NassetsLegMax Number of required warehouse assets for each assigned legion.
-- @field #table requestID The ID of the queued warehouse request. Necessary to cancel the request if the mission was cancelled before the request is processed.
-- @field #table payloads User specified airwing payloads for this mission. Only these will be considered for the job!
-- @field Ops.Airwing#AIRWING.PatrolData patroldata Patrol data.
--
-- @field #table specialLegions User specified legions assigned for this mission. Only these will be considered for the job!
-- @field #table specialCohorts User specified cohorts assigned for this mission. Only these will be considered for the job!
-- @field #table transportLegions Legions explicitly requested for providing transport carrier assets.
-- @field #table transportCohorts Cohorts explicitly requested for providing transport carrier assets.
-- @field #table escortLegions Legions explicitly requested for providing escorting assets.
-- @field #table escortCohorts Cohorts explicitly requested for providing escorting assets.
--
-- @field #string missionTask Mission task. See `ENUMS.MissionTask`.
-- @field #number missionAltitude Mission altitude in meters.
-- @field #number missionSpeed Mission speed in km/h.
-- @field #number missionFraction Mission coordiante fraction. Default is 0.5.
-- @field #number missionRange Mission range in meters. Used by LEGION classes (AIRWING, BRIGADE, ...).
-- @field Core.Point#COORDINATE missionWaypointCoord Mission waypoint coordinate.
-- @field Core.Point#COORDINATE missionEgressCoord Mission egress waypoint coordinate.
-- @field Core.Point#COORDINATE missionIngressCoord Mission Ingress waypoint coordinate.
-- @field #number missionWaypointRadius Random radius in meters.
-- @field #boolean legionReturn If `true`, assets return to their legion (default). If `false`, they will stay alive. 
--
-- @field #table enrouteTasks Mission enroute tasks.
--
-- @field #number repeated Number of times mission was repeated.
-- @field #number repeatedSuccess Number of times mission was repeated after a success.
-- @field #number repeatedFailure Number of times mission was repeated after a failure.
-- @field #number Nrepeat Number of times the mission is repeated.
-- @field #number NrepeatFailure Number of times mission is repeated if failed.
-- @field #number NrepeatSuccess Number of times mission is repeated if successful.
--
-- @field Ops.OpsGroup#OPSGROUP.Radio radio Radio freq and modulation.
-- @field Ops.OpsGroup#OPSGROUP.Beacon tacan TACAN setting.
-- @field Ops.OpsGroup#OPSGROUP.Beacon icls ICLS setting.
--
-- @field #number optionROE ROE.
-- @field #number optionROT ROT.
-- @field #number optionAlarm Alarm state.
-- @field #number optionFormation Formation.
-- @field #boolean optionEPLRS EPLRS datalink.
-- @field #number optionCM Counter measures.
-- @field #number optionRTBammo RTB on out-of-ammo.
-- @field #number optionRTBfuel RTB on out-of-fuel.
-- @field #number optionECM ECM.
-- @field #boolean optionEmission Emission is on or off.
-- @field #boolean optionInvisible Invisible is on/off.
-- @field #boolean optionImmortal Immortal is on/off.
--
-- @extends Core.Fsm#FSM

--- *A warrior's mission is to foster the success of others.* -- Morihei Ueshiba
--
-- ===
--
-- # The AUFTRAG Concept
--
-- The AUFTRAG class significantly simplifies the workflow of using DCS tasks.
--
-- You can think of an AUFTRAG as document, which contains the mission briefing, i.e. information about the target location, mission altitude, speed and various other parameters.
-- This document can be handed over directly to a pilot (or multiple pilots) via the @{Ops.FlightGroup#FLIGHTGROUP} class. The pilots will then execute the mission.
--
-- The AUFTRAG document can also be given to an AIRWING. The airwing will then determine the best assets (pilots and payloads) available for the job.
--
-- Similarly, an AUFTRAG can be given to ground or navel groups via the @{Ops.ArmyGroup#ARMYGROUP} or @{Ops.NavyGroup#NAVYGROUP} classes, respectively. These classes have also
-- AIRWING analouges, which are called BRIGADE and FLEET. Brigades and fleets will likewise select the best assets they have available and pass on the AUFTRAG to them.
--
--
-- One more up the food chain, an AUFTRAG can be passed to a COMMANDER. The commander will recruit the best assets of AIRWINGs, BRIGADEs and/or FLEETs and pass the job over to it.
--
--
-- # Airborne Missions
--
-- Several mission types are supported by this class.
--
-- ## Anti-Ship
--
-- An anti-ship mission can be created with the @{#AUFTRAG.NewANTISHIP}() function.
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
-- ## Strafing
--
-- A strafing mission can be created with the @{#AUFTRAG.NewSTRAFING}() function.
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
-- ## Ground Escort
--
-- An escort mission can be created with the @{#AUFTRAG.NewGROUNDESCORT}() function.
-- 
-- ## Intercept
--
-- An intercept mission can be created with the @{#AUFTRAG.NewINTERCEPT}() function.
--
-- ## Orbit
--
-- An orbit mission can be created with the @{#AUFTRAG.NewORBIT}() function.
--
-- ## GCICAP
--
-- An patrol mission can be created with the @{#AUFTRAG.NewGCICAP}() function.
--
-- ## RECON
--
-- An reconnaissance mission can be created with the @{#AUFTRAG.NewRECON}() function.
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
-- ## CARGOTRANSPORT
-- 
-- A cargo transport mission can be created with the @{#AUFTRAG.NewCARGOTRANSPORT}() function.
--
-- ## HOVER
--
-- A mission for a helicoptre or VSTOL plane to Hover at a point for a certain amount of time can be created with the @{#AUFTRAG.NewHOVER}() function.
--
-- # Ground Missions
--
-- ## ARTY
--
-- An arty mission can be created with the @{#AUFTRAG.NewARTY}() function.
--
-- ## GROUNDATTACK
--
-- A ground attack mission can be created with the @{#AUFTRAG.NewGROUNDATTACK}() function.
--
-- ## NAVALENGAGEMENT
--
-- A naval engagement mission can be created with the @{#AUFTRAG.NewNAVALENGAGEMENT}() function.
--
-- # Assigning Missions
--
-- An AUFTRAG can be assigned to groups (FLIGHTGROUP, ARMYGROUP, NAVYGROUP), legions (AIRWING, BRIGADE, FLEET) or to a COMMANDER.
--
-- ## Group Level
--
-- ### Flight Group
--
-- Assigning an AUFTRAG to a flight group is done via the @{Ops.FlightGroup#FLIGHTGROUP.AddMission} function. See FLIGHTGROUP docs for details.
--
-- ### Army Group
--
-- Assigning an AUFTRAG to an army group is done via the @{Ops.ArmyGroup#ARMYGROUP.AddMission} function. See ARMYGROUP docs for details.
--
-- ### Navy Group
--
-- Assigning an AUFTRAG to a navy group is done via the @{Ops.NavyGroup#NAVYGROUP.AddMission} function. See NAVYGROUP docs for details.
--
-- ## Legion Level
--
-- Adding an AUFTRAG to an airwing is done via the @{Ops.Airwing#AIRWING.AddMission} function. See AIRWING docs for further details.
-- Similarly, an AUFTRAG can be added to a brigade via the @{Ops.Brigade#BRIGADE.AddMission} function.
--
-- ## Commander Level
--
-- Assigning an AUFTRAG to a commander is done via the @{Ops.Commander#COMMANDER.AddMission} function.
-- The commander will select the best assets available from all the legions under his command. See COMMANDER docs for details.
-- 
-- ## Chief Level
-- 
--  Assigning an AUFTRAG to a commander is done via the @{Ops.Chief#CHIEF.AddMission} function. The chief will simply pass on the mission to his/her commander.
--  
-- # Transportation
-- 
-- TODO
--
--
-- # Events
--
-- The AUFTRAG class creates many useful (FSM) events, which can be used in the mission designers script.
--
-- TODO
--
--
-- # Examples
--
-- TODO
--
--
-- @field #AUFTRAG
AUFTRAG = {
  ClassName          = "AUFTRAG",
  verbose            =     0,
  lid                =   nil,
  auftragsnummer     =   nil,
  groupdata          =    {},
  legions            =    {},
  statusLegion       =    {},
  requestID          =    {},
  assets             =    {},
  NassetsLegMin      =    {},
  NassetsLegMax      =    {},
  missionFraction    =   0.5,
  enrouteTasks       =    {},
  marker             =   nil,
  markerOn           =   nil,
  markerCoalition    =   nil,
  conditionStart     =    {},
  conditionSuccess   =    {},
  conditionFailure   =    {},
  conditionPush      =    {},
  conditionSuccessSet = false,
  conditionFailureSet = false,
  repeatDelay = 1,
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
-- @field #string FAC Forward AirController mission.
-- @field #string FACA Forward AirController airborne mission.
-- @field #string FERRY Ferry mission.
-- @field #string GROUNDESCORT Ground escort mission.
-- @field #string INTERCEPT Intercept mission.
-- @field #string ORBIT Orbit mission.
-- @field #string GCICAP Similar to CAP but no auto engage targets.
-- @field #string RECON Recon mission.
-- @field #string RECOVERYTANKER Recovery tanker mission. Not implemented yet.
-- @field #string RESCUEHELO Rescue helo.
-- @field #string SEAD Suppression/destruction of enemy air defences.
-- @field #string STRIKE Strike mission.
-- @field #string TANKER Tanker mission.
-- @field #string TROOPTRANSPORT Troop transport mission.
-- @field #string ARTY Fire at point.
-- @field #string PATROLZONE Patrol a zone.
-- @field #string OPSTRANSPORT Ops transport.
-- @field #string AMMOSUPPLY Ammo supply.
-- @field #string FUELSUPPLY Fuel supply.
-- @field #string ALERT5 Alert 5.
-- @field #string ONGUARD On guard.
-- @field #string ARMOREDGUARD On guard - with armored groups.
-- @field #string BARRAGE Barrage.
-- @field #string ARMORATTACK Armor attack.
-- @field #string CASENHANCED Enhanced CAS.
-- @field #string HOVER Hover.
-- @field #string LANDATCOORDINATE Land at coordinate.
-- @field #string GROUNDATTACK Ground attack.
-- @field #string NAVALENGAGEMENT Naval engagement (similar to GROUNDATTACK).
-- @field #string CARGOTRANSPORT Cargo transport.
-- @field #string RELOCATECOHORT Relocate a cohort from one legion to another.
-- @field #string AIRDEFENSE Air defense.
-- @field #string EWR Early Warning Radar.
-- @field #string RECOVERYTANKER Recovery tanker.
-- @field #string REARMING Rearming mission.
-- @field #string CAPTUREZONE Capture zone mission.
-- @field #string NOTHING Nothing.
-- @field #string PATROLRACETRACK Patrol Racetrack.
-- @field #string STRAFING Strafing run.
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
  FAC="FAC",
  FACA="FAC-A",
  FERRY="Ferry Flight",
  GROUNDESCORT="Ground Escort",
  INTERCEPT="Intercept",
  ORBIT="Orbit",
  GCICAP="Ground Controlled CAP",
  RECON="Recon",
  RECOVERYTANKER="Recovery Tanker",
  RESCUEHELO="Rescue Helo",
  SEAD="SEAD",
  STRIKE="Strike",
  TANKER="Tanker",
  TROOPTRANSPORT="Troop Transport",
  ARTY="Fire At Point",
  PATROLZONE="Patrol Zone",
  OPSTRANSPORT="Ops Transport",
  AMMOSUPPLY="Ammo Supply",
  FUELSUPPLY="Fuel Supply",
  ALERT5="Alert5",
  ONGUARD="On Guard",
  ARMOREDGUARD="Armored Guard",
  BARRAGE="Barrage",
  ARMORATTACK="Armor Attack",
  CASENHANCED="CAS Enhanced",
  HOVER="Hover",
  LANDATCOORDINATE="Land at Coordinate",
  GROUNDATTACK="Ground Attack",
  NAVALENGAGEMENT="Naval Engagement",
  CARGOTRANSPORT="Cargo Transport",
  RELOCATECOHORT="Relocate Cohort",
  AIRDEFENSE="Air Defence",
  EWR="Early Warning Radar",
  REARMING="Rearming",
  CAPTUREZONE="Capture Zone",
  NOTHING="Nothing",
  PATROLRACETRACK="Patrol Racetrack",
  STRAFING="Strafing",
}

--- Special task description.
-- @type AUFTRAG.SpecialTask
-- @field #string FORMATION AI formation task.
-- @field #string PATROLZONE Patrol zone task.
-- @field #string RECON Recon task.
-- @field #string AMMOSUPPLY Ammo Supply.
-- @field #string FUELSUPPLY Fuel Supply.
-- @field #string ALERT5 Alert 5 task.
-- @field #string ONGUARD On guard.
-- @field #string ARMOREDGUARD On guard with armor.
-- @field #string BARRAGE Barrage.
-- @field #string HOVER Hover.
-- @field #string GROUNDATTACK Ground attack.
-- @field #string NAVALENGAGEMENT Naval engagement.
-- @field #string FERRY Ferry mission.
-- @field #string RELOCATECOHORT Relocate cohort.
-- @field #string AIRDEFENSE Air defense.
-- @field #string EWR Early Warning Radar.
-- @field #string RECOVERYTANKER Recovery tanker.
-- @field #string REARMING Rearming.
-- @field #string CAPTUREZONE Capture OPS zone.
-- @field #string NOTHING Nothing.
-- @field #string PATROLRACETRACK Patrol Racetrack.
AUFTRAG.SpecialTask={
  FORMATION="Formation",
  PATROLZONE="PatrolZone",
  RECON="ReconMission",
  AMMOSUPPLY="Ammo Supply",
  FUELSUPPLY="Fuel Supply",
  ALERT5="Alert5",
  ONGUARD="On Guard",
  ARMOREDGUARD="ArmoredGuard",
  BARRAGE="Barrage",
  ARMORATTACK="AmorAttack",
  HOVER="Hover",
  GROUNDATTACK="Ground Attack",
  NAVALENGAGEMENT="Naval Engagement",
  FERRY="Ferry",
  RELOCATECOHORT="Relocate Cohort",
  AIRDEFENSE="Air Defense",
  EWR="Early Warning Radar",
  RECOVERYTANKER="Recovery Tanker",
  REARMING="Rearming",
  CAPTUREZONE="Capture Zone",  
  NOTHING="Nothing",
  PATROLRACETRACK="Patrol Racetrack",
}

--- Mission status.
-- @type AUFTRAG.Status
-- @field #string PLANNED Mission is at the early planning stage and has not been added to any queue.
-- @field #string QUEUED Mission is queued at a LEGION.
-- @field #string REQUESTED Mission assets were requested from the warehouse.
-- @field #string SCHEDULED Mission is scheduled in an OPSGROUP queue waiting to be started.
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

--- Mission category.
-- @type AUFTRAG.Category
-- @field #string AIRCRAFT Airplanes and helicopters.
-- @field #string AIRPLANE Airplanes.
-- @field #string HELICOPTER Helicopter.
-- @field #string GROUND Ground troops.
-- @field #string NAVAL Naval grous.
AUFTRAG.Category={
  ALL="All",
  AIRCRAFT="Aircraft",
  AIRPLANE="Airplane",
  HELICOPTER="Helicopter",
  GROUND="Ground",
  NAVAL="Naval",
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
-- @field Core.Point#COORDINATE waypointcoordinate Ingress waypoint coordinate.
-- @field #number waypointindex Mission (ingress) Waypoint UID.
-- @field #number waypointEgressUID Egress Waypoint UID.
-- @field Core.Point#COORDINATE wpegresscoordinate Egress waypoint coordinate.
--
-- @field Ops.OpsGroup#OPSGROUP.Task waypointtask Waypoint task.
-- @field #string status Group mission status.
-- @field Functional.Warehouse#WAREHOUSE.Assetitem asset The warehouse asset.


--- AUFTRAG class version.
-- @field #string version
AUFTRAG.version="1.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Replace engageRange by missionRange. Here and in other classes. CTRL+H is your friend!
-- TODO: Mission success options damaged, destroyed.
-- TODO: F10 marker to create new missions.
-- DONE: Add option that assets do not return to their legion.
-- DONE: Add Capture zone task.
-- DONE: Add orbit mission for moving anker points.
-- DONE: Add recovery tanker mission for boat ops.
-- DONE: Added auftrag category.
-- DONE: Missions can be assigned to multiple legions.
-- DONE: Option to assign a specific payload for the mission (requires an AIRWING).
-- NOPE: Clone mission. How? Deepcopy? ==> Create a new auftrag.
-- DONE: Recon mission. What input? Set of coordinates?
-- DONE: Option to assign mission to specific squadrons (requires an AIRWING).
-- DONE: Add mission start conditions.
-- DONE: Add rescue helo mission for boat ops.
-- DONE: Mission ROE and ROT.
-- DONE: Mission frequency and TACAN.
-- DONE: Mission formation, etc.
-- DONE: FSM events.
-- DONE: F10 marker functions that are updated on Status event.
-- DONE: Evaluate mission result ==> SUCCESS/FAILURE
-- DONE: NewAUTO() NewA2G NewA2A
-- DONE: Transport mission.
-- DONE: Set mission coalition, e.g. for F10 markers. Could be derived from target if target has a coalition.

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

  -- Log ID.
  self:_SetLogID()

  -- State is planned.
  self.status=AUFTRAG.Status.PLANNED

  -- Defaults  .
  self:SetName()
  self:SetPriority()
  self:SetTime()
  self:SetRequiredAssets()
  self.engageAsGroup=true
  self.dTevaluate=5

  -- Init counters and stuff.
  self.repeated=0
  self.repeatedSuccess=0
  self.repeatedFailure=0
  self.Nrepeat=0
  self.NrepeatFailure=0
  self.NrepeatSuccess=0
  self.Ncasualties=0
  self.Nkills=0
  self.Nelements=0
  self.Ngroups=0
  self.Nassigned=nil
  self.Ndead=0

  -- FMS start state is PLANNED.
  self:SetStartState(self.status)

  -- PLANNED --> (QUEUED) --> (REQUESTED) --> SCHEDULED --> STARTED --> EXECUTING --> DONE
  self:AddTransition("*",                      "Planned",          AUFTRAG.Status.PLANNED)     -- Mission is in planning stage. Could be in the queue of a COMMANDER or CHIEF.
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Queued",           AUFTRAG.Status.QUEUED)      -- Mission is in queue of a LEGION.
  self:AddTransition(AUFTRAG.Status.QUEUED,    "Requested",        AUFTRAG.Status.REQUESTED)   -- Mission assets have been requested from the warehouse.
  self:AddTransition(AUFTRAG.Status.REQUESTED, "Scheduled",        AUFTRAG.Status.SCHEDULED)   -- Mission added to the first ops group queue.
  
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Scheduled",        AUFTRAG.Status.SCHEDULED)   -- From planned directly to scheduled.

  self:AddTransition(AUFTRAG.Status.SCHEDULED, "Started",          AUFTRAG.Status.STARTED)     -- First asset has started the mission.
  self:AddTransition(AUFTRAG.Status.STARTED,   "Executing",        AUFTRAG.Status.EXECUTING)   -- First asset is executing the mission.
  

  self:AddTransition("*",                      "Done",             AUFTRAG.Status.DONE)        -- All assets have reported that mission is done.

  self:AddTransition("*",                      "Cancel",           AUFTRAG.Status.CANCELLED)   -- Command to cancel the mission.

  self:AddTransition("*",                      "Success",          AUFTRAG.Status.SUCCESS)
  self:AddTransition("*",                      "Failed",           AUFTRAG.Status.FAILED)

  self:AddTransition("*",                      "Status",           "*")
  self:AddTransition("*",                      "Stop",             "*")

  self:AddTransition("*",                      "Repeat",           AUFTRAG.Status.PLANNED)

  self:AddTransition("*",                      "ElementDestroyed", "*")
  self:AddTransition("*",                      "GroupDead",        "*")
  self:AddTransition("*",                      "AssetDead",        "*")

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Status".
  -- @function [parent=#AUFTRAG] Status
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#AUFTRAG] __Status
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop".
  -- @function [parent=#AUFTRAG] Stop
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#AUFTRAG] __Stop
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Planned".
  -- @function [parent=#AUFTRAG] Planned
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Planned" after a delay.
  -- @function [parent=#AUFTRAG] __Planned
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Planned" event.
  -- @function [parent=#AUFTRAG] OnAfterPlanned
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Queued".
  -- @function [parent=#AUFTRAG] Queued
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Queued" after a delay.
  -- @function [parent=#AUFTRAG] __Queued
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Queued" event.
  -- @function [parent=#AUFTRAG] OnAfterQueued
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Requested".
  -- @function [parent=#AUFTRAG] Requested
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Requested" after a delay.
  -- @function [parent=#AUFTRAG] __Requested
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Requested" event.
  -- @function [parent=#AUFTRAG] OnAfterRequested
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Scheduled".
  -- @function [parent=#AUFTRAG] Scheduled
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Scheduled" after a delay.
  -- @function [parent=#AUFTRAG] __Scheduled
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Scheduled" event.
  -- @function [parent=#AUFTRAG] OnAfterScheduled
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Started".
  -- @function [parent=#AUFTRAG] Started
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Started" after a delay.
  -- @function [parent=#AUFTRAG] __Started
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Started" event.
  -- @function [parent=#AUFTRAG] OnAfterStarted
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Executing".
  -- @function [parent=#AUFTRAG] Executing
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Executing" after a delay.
  -- @function [parent=#AUFTRAG] __Executing
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Executing" event.
  -- @function [parent=#AUFTRAG] OnAfterExecuting
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Cancel".
  -- @function [parent=#AUFTRAG] Cancel
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Cancel" after a delay.
  -- @function [parent=#AUFTRAG] __Cancel
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Cancel" event.
  -- @function [parent=#AUFTRAG] OnAfterCancel
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Done".
  -- @function [parent=#AUFTRAG] Done
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Done" after a delay.
  -- @function [parent=#AUFTRAG] __Done
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Done" event.
  -- @function [parent=#AUFTRAG] OnAfterDone
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Success".
  -- @function [parent=#AUFTRAG] Success
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Success" after a delay.
  -- @function [parent=#AUFTRAG] __Success
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Success" event.
  -- @function [parent=#AUFTRAG] OnAfterSuccess
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "Failed".
  -- @function [parent=#AUFTRAG] Failed
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Failed" after a delay.
  -- @function [parent=#AUFTRAG] __Failed
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Failed" event.
  -- @function [parent=#AUFTRAG] OnAfterFailed
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "Repeat".
  -- @function [parent=#AUFTRAG] Repeat
  -- @param #AUFTRAG self

  --- Triggers the FSM event "Repeat" after a delay.
  -- @function [parent=#AUFTRAG] __Repeat
  -- @param #AUFTRAG self
  -- @param #number delay Delay in seconds.

  --- On after "Repeat" event.
  -- @function [parent=#AUFTRAG] OnAfterRepeat
  -- @param #AUFTRAG self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  -- Init status update.
  self:__Status(-1)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Missions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- **[AIR]** Create an ANTI-SHIP mission.
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
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 2000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.ANTISHIPSTRIKE
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.4
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR ROTARY]** Create an HOVER mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to hover.
-- @param #number Altitude Hover altitude in feet AGL. Default is 50 feet above ground.
-- @param #number Time Time in seconds to hold the hover. Default 300 seconds.
-- @param #number Speed Speed in knots to fly to the target coordinate. Default 150kn.
-- @param #number MissionAlt Altitude to fly towards the mission in feet AGL. Default 1000ft.
-- @return #AUFTRAG self
function AUFTRAG:NewHOVER(Coordinate, Altitude, Time, Speed, MissionAlt)

  local mission=AUFTRAG:New(AUFTRAG.Type.HOVER)

  -- Altitude.
  if Altitude then
    mission.hoverAltitude=Coordinate:GetLandHeight()+UTILS.FeetToMeters(Altitude)
  else
    mission.hoverAltitude=Coordinate:GetLandHeight()+UTILS.FeetToMeters(50)
  end

  mission:_TargetFromObject(Coordinate)

  mission.hoverSpeed = 0.1 -- the DCS Task itself will shortly be build with this so MPS
  mission.hoverTime = Time or 300
  self:SetMissionSpeed(Speed or 150)
  self:SetMissionAltitude(MissionAlt or 1000)
  
  -- Mission options:
  mission.missionFraction=0.9
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.HELICOPTER}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR ROTARY]** Create an LANDATCOORDINATE mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to land.
-- @param #number OuterRadius (Optional) Vary the coordinate by this many feet, e.g. get a new random coordinate between OuterRadius and (optionally) avoiding InnerRadius of the coordinate.
-- @param #number InnerRadius (Optional) Vary the coordinate by this many feet, e.g. get a new random coordinate between OuterRadius and (optionally) avoiding InnerRadius of the coordinate.
-- @param #number Time Time in seconds to stay. Default 300 seconds.
-- @param #number Speed Speed in knots to fly to the target coordinate. Default 150kn.
-- @param #number MissionAlt Altitude to fly towards the mission in feet AGL. Default 1000ft.
-- @param #boolean CombatLanding (Optional) If true, set the Combat Landing option.
-- @param #number DirectionAfterLand (Optional) Heading after landing in degrees.
-- @return #AUFTRAG self
function AUFTRAG:NewLANDATCOORDINATE(Coordinate, OuterRadius, InnerRadius, Time, Speed, MissionAlt, CombatLanding, DirectionAfterLand)

  local mission=AUFTRAG:New(AUFTRAG.Type.LANDATCOORDINATE)

  mission:_TargetFromObject(Coordinate)

  mission.stayTime = Time or 300
  mission.stayAt = Coordinate
  mission.combatLand = CombatLanding
  mission.directionAfter = DirectionAfterLand
  self:SetMissionSpeed(Speed or 150)
  self:SetMissionAltitude(MissionAlt or 1000)
  
  if OuterRadius then
    mission.stayAt = Coordinate:GetRandomCoordinateInRadius(UTILS.FeetToMeters(OuterRadius),UTILS.FeetToMeters(InnerRadius or 0))  
  end
  
  -- Mission options:
  mission.missionFraction=0.9
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.HELICOPTER}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create an enhanced orbit race track mission. Planes will keep closer to the track.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to start the race track.
-- @param #number Altitude (Optional) Altitude in feet. Defaults to 20,000ft ASL.
-- @param #number Speed (Optional) Speed in knots. Defaults to 300kn TAS.
-- @param #number Heading (Optional) Heading in degrees, 0 to 360. Defaults to 90 degree (East).
-- @param #number Leg (Optional) Leg of the race track in NM. Defaults to 10nm.
-- @param #number Formation (Optional) Formation to take, e.g. ENUMS.Formation.FixedWing.Trail.Close, also see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_option_formation).
-- @return #AUFTRAG self
function AUFTRAG:NewPATROL_RACETRACK(Coordinate,Altitude,Speed,Heading,Leg,Formation)
  
  local mission = AUFTRAG:New(AUFTRAG.Type.PATROLRACETRACK)
  
    -- Target.
  mission:_TargetFromObject(Coordinate)
  
  -- Set Altitude.  
  if Altitude then
    mission.TrackAltitude=UTILS.FeetToMeters(Altitude)
  else
    mission.TrackAltitude=UTILS.FeetToMeters(20000)
  end
  
  -- Points
  mission.TrackPoint1 = Coordinate
  
  local leg = UTILS.NMToMeters(Leg) or UTILS.NMToMeters(10)
  
  local heading = Heading or 90
  
  if heading < 0 or heading > 360 then heading = 90 end
  
  mission.TrackPoint2 = Coordinate:Translate(leg,heading,true)
  
  -- Orbit speed in m/s TAS.
  mission.TrackSpeed = UTILS.IasToTas(UTILS.KnotsToKmph(Speed or 300), mission.TrackAltitude)
  
  -- Mission speed in km/h and altitude
  mission.missionSpeed = UTILS.KnotsToKmph(Speed or 300)
  mission.missionAltitude = mission.TrackAltitude * 0.9
  mission.missionTask=ENUMS.MissionTask.CAP
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end


--- **[AIR]** Create an ORBIT mission, which can be either a circular orbit or a race-track pattern.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet above sea level. Default is y component of `Coordinate`.
-- @param #number Speed Orbit indicated airspeed in knots at the set altitude ASL. Default 350 KIAS.
-- @param #number Heading Heading of race-track pattern in degrees. If not specified, a circular orbit is performed.
-- @param #number Leg Length of race-track in NM. If not specified, a circular orbit is performed.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT(Coordinate, Altitude, Speed, Heading, Leg)

  local mission=AUFTRAG:New(AUFTRAG.Type.ORBIT)
  
  -- Target.
  mission:_TargetFromObject(Coordinate)
  
  -- Set Altitude.  
  if Altitude then
    mission.orbitAltitude=UTILS.FeetToMeters(Altitude)
  else
    mission.orbitAltitude=Coordinate.y
  end
    
  -- Orbit speed in m/s TAS.
  mission.orbitSpeed = UTILS.IasToTas(UTILS.KnotsToMps(Speed or 350), mission.orbitAltitude)
  
  -- Mission speed in km/h.
  mission.missionSpeed = UTILS.KnotsToKmph(Speed or 350)
  
  if Leg then
    mission.orbitLeg=UTILS.NMToMeters(Leg)

    -- Relative heading
    if Heading and Heading<0 then
      mission.orbitHeadingRel=true
      Heading=-Heading
    end      

    -- Heading if given.
    mission.orbitHeading=Heading    
  end

  -- Mission options:
  mission.missionAltitude=mission.orbitAltitude*0.9
  mission.missionFraction=0.9
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create an ORBIT mission, where the aircraft will go in a circle around the specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Position where to orbit around.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit indicated airspeed in knots at the set altitude ASL. Default 350 KIAS.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT_CIRCLE(Coordinate, Altitude, Speed)

  local mission=AUFTRAG:NewORBIT(Coordinate, Altitude, Speed)

  return mission
end

--- **[AIR]** Create an ORBIT mission, where the aircraft will fly a race-track pattern.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit indicated airspeed in knots at the set altitude ASL. Default 350 KIAS.
-- @param #number Heading Heading of race-track pattern in degrees. Default random in [0, 360) degrees.
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)

  Heading = Heading or math.random(360)
  Leg     = Leg or 10

  local mission=AUFTRAG:NewORBIT(Coordinate, Altitude, Speed, Heading, Leg)

  return mission
end

--- **[AIR]** Create an ORBIT mission, where the aircraft will fly a circular or race-track pattern over a given group or unit.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP Group Group where to orbit around. Can also be a UNIT object.
-- @param #number Altitude Orbit altitude in feet. Default is 6,000 ft.
-- @param #number Speed Orbit indicated airspeed in knots at the set altitude ASL. Default 350 KIAS.
-- @param #number Leg Length of race-track in NM. Default nil.
-- @param #number Heading Heading of race-track pattern in degrees. Default is heading of the group.
-- @param DCS#Vec2 OffsetVec2 Offset 2D-vector {x=0, y=0} in NM with respect to the group. Default directly overhead. Can also be given in polar coordinates `{r=5, phi=45}`.
-- @param #number Distance Threshold distance in NM before orbit pattern is updated. Default 5 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT_GROUP(Group, Altitude, Speed, Leg, Heading, OffsetVec2, Distance)

  -- Set default altitude.
  Altitude = Altitude or 6000

  -- Create orbit mission.
  local mission=AUFTRAG:NewORBIT(Group, Altitude, Speed, Heading, Leg)

  -- DCS tasks needs to be updated from time to time.  
  mission.updateDCSTask=true
  
  -- Convert offset vector to meters.
  if OffsetVec2 then
    if OffsetVec2.x then
      OffsetVec2.x=UTILS.NMToMeters(OffsetVec2.x)
    end
    if OffsetVec2.y then
      OffsetVec2.y=UTILS.NMToMeters(OffsetVec2.y)
    end
    if OffsetVec2.r then
      OffsetVec2.r=UTILS.NMToMeters(OffsetVec2.r)
    end    
  end
  
  -- Offset vector.
  mission.orbitOffsetVec2=OffsetVec2
  
  -- Pattern update distance.
  mission.orbitDeltaR=UTILS.NMToMeters(Distance or 5)

  -- Update task with offset etc.
  mission:GetDCSMissionTask()

  return mission
end


--- **[AIR]** Create a Ground Controlled CAP (GCICAP) mission. Flights with this task are considered for A2A INTERCEPT missions by the CHIEF class. They will perform a combat air patrol but not engage by
-- themselfs. They wait for the CHIEF to tell them whom to engage.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit indicated airspeed in knots at the set altitude ASL. Default 350 KIAS.
-- @param #number Heading Heading of race-track pattern in degrees. Default random in [0, 360) degrees.
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewGCICAP(Coordinate, Altitude, Speed, Heading, Leg)

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)

  -- Mission type GCICAP.
  mission.type=AUFTRAG.Type.GCICAP

  mission:_SetLogID()

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.INTERCEPT
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  return mission
end

--- **[AIR]** Create a TANKER mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @param #number Speed Orbit indicated airspeed in knots at the set altitude ASL. Default 350 KIAS.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM. Set to 0 for a simple circular orbit.
-- @param #number RefuelSystem Refueling system (0=boom, 1=probe). This info is *only* for AIRWINGs so they launch the right tanker type.
-- @return #AUFTRAG self
function AUFTRAG:NewTANKER(Coordinate, Altitude, Speed, Heading, Leg, RefuelSystem)
  
  local mission
  if Leg == 0 then
    mission=AUFTRAG:NewORBIT_CIRCLE(Coordinate,Altitude,Speed)
  else
    mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate,Altitude,Speed,Heading,Leg)
  end
  -- Create ORBIT first.
  --local mission=AUFTRAG:NewORBIT_RACETRACK(Coordinate, Altitude, Speed, Heading, Leg)

  -- Mission type TANKER.
  mission.type=AUFTRAG.Type.TANKER

  mission:_SetLogID()

  mission.refuelSystem=RefuelSystem

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.REFUELING
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a AWACS mission.
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

  -- Mission type AWACS.
  mission.type=AUFTRAG.Type.AWACS

  mission:_SetLogID()

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.AWACS
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end



--- **[AIR]** Create an INTERCEPT mission.
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

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a CAP mission.
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
  TargetTypes=UTILS.EnsureTable(TargetTypes, true)

  -- Set default altitude if not specified.
  Altitude = Altitude or 10000

  -- Create ORBIT first.
  local mission=AUFTRAG:NewORBIT(Coordinate or ZoneCAP:GetCoordinate(), Altitude, Speed or 350, Heading, Leg)

  -- Mission type CAP.
  mission.type=AUFTRAG.Type.CAP
  mission:_SetLogID()

  -- DCS task parameters:
  mission.engageZone=ZoneCAP or Coordinate
  mission.engageTargetTypes=TargetTypes or {"Air"}

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.CAP
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  mission.missionSpeed = UTILS.KnotsToKmph(UTILS.KnotsToAltKIAS(Speed or 350, Altitude))

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a CAP mission over a (moving) group.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP Grp The grp to perform the CAP over.
-- @param #number Altitude Orbit altitude in feet. Default is 6,000 ft.
-- @param #number Speed Orbit speed in knots. Default 250 KIAS.
-- @param #number RelHeading Relative heading [0, 360) of race-track pattern in degrees wrt heading of the carrier. Default is heading of the carrier.
-- @param #number Leg Length of race-track in NM. Default 14 NM.
-- @param #number OffsetDist Relative distance of the first race-track point wrt to the carrier. Default 6 NM.
-- @param #number OffsetAngle Relative angle of the first race-track point wrt. to the carrier. Default 180 (behind the boat).
-- @param #number UpdateDistance Threshold distance in NM before orbit pattern is updated. Default 5 NM.
-- @param #table TargetTypes (Optional) Table of target types. Default `{"Air"}`.
-- @param #number EngageRange Max range in nautical miles that the escort group(s) will engage enemies. Default 32 NM (60 km).
-- @return #AUFTRAG self
function AUFTRAG:NewCAPGROUP(Grp, Altitude, Speed, RelHeading, Leg, OffsetDist, OffsetAngle, UpdateDistance, TargetTypes, EngageRange)

  -- Ensure given TargetTypes parameter is a table.
  TargetTypes=UTILS.EnsureTable(TargetTypes, true)

  -- Six NM astern.
 local OffsetVec2={r=OffsetDist or 6, phi=OffsetAngle or 180}

 -- Default leg.
 Leg=Leg or 14

 local Heading=nil
 if RelHeading then  
   Heading=-math.abs(RelHeading)
 end  

 -- Create orbit mission. 
 local mission=AUFTRAG:NewORBIT_GROUP(Grp, Altitude, Speed, Leg, Heading, OffsetVec2, UpdateDistance)
 -- Mission type CAP.
 mission.type=AUFTRAG.Type.CAP
 mission:_SetLogID()

 -- DCS task parameters:
 local engage = EngageRange or 32
 local zoneCAPGroup = ZONE_GROUP:New("CAPGroup", Grp, UTILS.NMToMeters(engage))
 mission.engageZone=zoneCAPGroup
 mission.engageTargetTypes=TargetTypes or {"Air"}

 -- Mission options:
 mission.missionTask=ENUMS.MissionTask.CAP
 mission.optionROE=ENUMS.ROE.OpenFire
 mission.optionROT=ENUMS.ROT.EvadeFire

 mission.categories={AUFTRAG.Category.AIRCRAFT}

 mission.DCStask=mission:GetDCSMissionTask()

 return mission
end

--- **[AIR]** Create a CAS mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE_RADIUS ZoneCAS Circular CAS zone. Detected targets in this zone will be engaged.
-- @param #number Altitude Altitude at which to orbit. Default is 10,000 ft.
-- @param #number Speed Orbit speed in knots. Default 350 KIAS.
-- @param Core.Point#COORDINATE Coordinate Where to orbit. Default is the center of the CAS zone.
-- @param #number Heading Heading of race-track pattern in degrees. If not specified, a simple circular orbit is performed.
-- @param #number Leg Length of race-track in NM. If not specified, a simple circular orbit is performed.
-- @param #table TargetTypes (Optional) Table of target types. Default `{"Helicopters", "Ground Units", "Light armed ships"}`.
-- @return #AUFTRAG self
function AUFTRAG:NewCAS(ZoneCAS, Altitude, Speed, Coordinate, Heading, Leg, TargetTypes)

  -- Ensure given TargetTypes parameter is a table.
  TargetTypes=UTILS.EnsureTable(TargetTypes, true)

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

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a CASENHANCED mission. Group(s) will go to the zone and patrol it randomly.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE CasZone The CAS zone.
-- @param #number Altitude Altitude in feet. Only for airborne units. Default 2000 feet ASL.
-- @param #number Speed Speed in knots.
-- @param #number RangeMax Max range in NM. Only detected targets within this radius from the group will be engaged. Default is 25 NM.
-- @param Core.Set#SET_ZONE NoEngageZoneSet Set of zones in which targets are *not* engaged. Default is nowhere.
-- @param #table TargetTypes Types of target attributes that will be engaged. See [DCS enum attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes). Default `{"Helicopters", "Ground Units", "Light armed ships"}`.
-- @return #AUFTRAG self
function AUFTRAG:NewCASENHANCED(CasZone, Altitude, Speed, RangeMax, NoEngageZoneSet, TargetTypes)

  local mission=AUFTRAG:New(AUFTRAG.Type.CASENHANCED)

  -- Ensure we got a ZONE and not just the zone name.
  if type(CasZone)=="string" then
    CasZone=ZONE:New(CasZone)
  end

  mission:_TargetFromObject(CasZone)

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.CASENHANCED)

  mission:SetEngageDetected(RangeMax, TargetTypes or {"Helicopters", "Ground Units", "Light armed ships"}, CasZone, NoEngageZoneSet)

  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire

  mission.missionFraction=0.5
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  mission.missionAltitude=Altitude and UTILS.FeetToMeters(Altitude) or nil
  
  -- Evaluate result after x secs. We might need time until targets have been detroyed.
  mission.dTevaluate=15
  
  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()
  

  return mission
end

--- **[AIR, GROUND]** Create a FAC mission. Group(s) will go to the zone and patrol it randomly and act as FAC for detected units.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE FacZone The FAC zone (or name of zone) where to patrol.
-- @param #number Speed Speed in knots.
-- @param #number Altitude Altitude in feet. Only for airborne units. Default 2000 feet ASL. 
-- @param #number Frequency Frequency in MHz.
-- @param #number Modulation Modulation.
-- @return #AUFTRAG self
function AUFTRAG:NewFAC(FacZone, Speed, Altitude, Frequency, Modulation)

  local mission=AUFTRAG:New(AUFTRAG.Type.FAC)

  -- Ensure we got a ZONE and not just the zone name.
  if type(FacZone)=="string" then
    FacZone=ZONE:FindByName(FacZone)
  end

  mission:_TargetFromObject(FacZone)

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.FAC)
  
  mission.facFreq=Frequency or 133
  mission.facModu=Modulation or radio.modulation.AM

  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  mission.missionAltitude=Altitude and UTILS.FeetToMeters(Altitude) or nil

  mission.categories={AUFTRAG.Category.AIRCRAFT, AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()
  

  return mission
end


--- **[AIR]** Create a FACA mission.
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

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- **[AIR]** Create a BAI mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 5000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewBAI(Target, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.BAI)

  mission:_TargetFromObject(Target)

  -- DCS Task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 5000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.75
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a SEAD mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP or UNIT object.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewSEAD(Target, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.SEAD)

  mission:_TargetFromObject(Target)

  -- DCS Task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.SEAD
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.2
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a SEAD in Zone mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE TargetZone The target zone to attack.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @param #table TargetTypes Table of string of DCS known target types, defaults to {"Air Defence"}. See [DCS Target Attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes)
-- @param #number Duration Engage this much time when the AUFTRAG starts executing.
-- @return #AUFTRAG self
function AUFTRAG:NewSEADInZone(TargetZone, Altitude, TargetTypes, Duration)

  local mission=AUFTRAG:New(AUFTRAG.Type.SEAD)

  --mission:_TargetFromObject(TargetZone)

  -- DCS Task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)
  mission.engageZone = TargetZone
  mission.engageTargetTypes = TargetTypes or {"Air Defence"}

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.SEAD
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.2
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()
  
  mission:SetDuration(Duration or 1800)

  return mission
end

--- **[AIR]** Create a STRIKE mission. Flight will attack the closest map object to the specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target The target coordinate. Can also be given as a GROUP, UNIT, STATIC, SET_GROUP, SET_UNIT, SET_STATIC or TARGET object.
-- @param #number Altitude Engage altitude in feet. Default 2000 ft.
-- @param #number EngageWeaponType Which weapon to use. Defaults to auto, ie ENUMS.WeaponFlag.Auto. See ENUMS.WeaponFlag for options.
-- @return #AUFTRAG self
function AUFTRAG:NewSTRIKE(Target, Altitude, EngageWeaponType)

  local mission=AUFTRAG:New(AUFTRAG.Type.STRIKE)

  mission:_TargetFromObject(Target)

  -- DCS Task options:
  mission.engageWeaponType=EngageWeaponType or ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 2000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude
  mission.missionFraction=0.75
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a BOMBING mission. Flight will drop bombs a specified coordinate.
-- See [DCS task bombing](https://wiki.hoggitworld.com/view/DCS_task_bombing).
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Target coordinate. Can also be specified as a GROUP, UNIT, STATIC, SET_GROUP, SET_UNIT, SET_STATIC or TARGET object.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @param #number EngageWeaponType Which weapon to use. Defaults to auto, ie ENUMS.WeaponFlag.Auto. See ENUMS.WeaponFlag for options.
-- @param #boolean Divebomb If true, use a dive bombing attack approach.
-- @return #AUFTRAG self
function AUFTRAG:NewBOMBING(Target, Altitude, EngageWeaponType, Divebomb)

  local mission=AUFTRAG:New(AUFTRAG.Type.BOMBING)

  mission:_TargetFromObject(Target)

  -- DCS task options:
  mission.engageWeaponType=EngageWeaponType or ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude*0.8
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.NoReaction   -- No reaction is better.
  mission.optionDivebomb = Divebomb or nil

  -- Evaluate result after 5 min. We might need time until the bombs have dropped and targets have been detroyed.
  mission.dTevaluate=5*60

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a STRAFING mission. Assigns a point on the ground for which the AI will do a strafing run with guns or rockets.
-- See [DCS task strafing](https://wiki.hoggitworld.com/view/DCS_task_strafing).
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Target coordinate. Can also be specified as a GROUP, UNIT, STATIC or TARGET object.
-- @param #number Altitude Engage altitude in feet. Default 1000 ft.
-- @param #number Length The total length of the strafing target in meters. Default `nil`.
-- @return #AUFTRAG self
function AUFTRAG:NewSTRAFING(Target, Altitude, Length)

  local mission=AUFTRAG:New(AUFTRAG.Type.STRAFING)

  mission:_TargetFromObject(Target)

  -- DCS task options:
  mission.engageWeaponType=805337088 -- Corresponds to guns/cannons (805306368) + any rocket (30720). This is the default when selecting this task in the ME.
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 1000)
  mission.engageLength=Length

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude*0.8
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.NoReaction   -- No reaction is better.

  -- Evaluate result after 5 min. We might need time until the bombs have dropped and targets have been detroyed.
  mission.dTevaluate=5*60

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- **[AIR]** Create a BOMBRUNWAY mission.
-- @param #AUFTRAG self
-- @param Wrapper.Airbase#AIRBASE Airdrome The airbase to bomb. This must be an airdrome (not a FARP or ship) as these do not have a runway.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewBOMBRUNWAY(Airdrome, Altitude)

  if type(Airdrome)=="string" then
    Airdrome=AIRBASE:FindByName(Airdrome)
  end

  local mission=AUFTRAG:New(AUFTRAG.Type.BOMBRUNWAY)

  mission:_TargetFromObject(Airdrome)

  -- DCS task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.RUNWAYATTACK
  mission.missionAltitude=mission.engageAltitude*0.8
  mission.missionFraction=0.75
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  -- Evaluate result after 5 min.
  mission.dTevaluate=5*60

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR]** Create a CARPET BOMBING mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Target coordinate. Can also be specified as a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 25000 ft.
-- @param #number CarpetLength Length of bombing carpet in meters. Default 500 m.
-- @return #AUFTRAG self
function AUFTRAG:NewBOMBCARPET(Target, Altitude, CarpetLength)

  local mission=AUFTRAG:New(AUFTRAG.Type.BOMBCARPET)

  mission:_TargetFromObject(Target)

  -- DCS task options:
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)
  mission.engageLength=CarpetLength or 500
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

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  -- Get DCS task.
  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR/HELO]** Create a GROUNDESCORT (or FOLLOW) mission. Helo will escort a **ground** group and automatically engage certain target types.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP EscortGroup The ground group to escort.
-- @param #number OrbitDistance Orbit to/from the lead unit this many NM. Defaults to 1.5 NM.
-- @param #table TargetTypes Types of targets to engage automatically. Default is {"Ground vehicles"}, i.e. all enemy ground units. Use an empty set {} for a simple "FOLLOW" mission.
-- @return #AUFTRAG self
function AUFTRAG:NewGROUNDESCORT(EscortGroup, OrbitDistance, TargetTypes)

  local mission=AUFTRAG:New(AUFTRAG.Type.GROUNDESCORT)

  -- If only a string is passed we set a variable and check later if the group exists.
  if type(EscortGroup)=="string" then
    mission.escortGroupName=EscortGroup
    mission:_TargetFromObject()
  else
    mission:_TargetFromObject(EscortGroup)
  end

  -- DCS task parameters:
  mission.orbitDistance=OrbitDistance and UTILS.NMToMeters(OrbitDistance) or UTILS.NMToMeters(1.5)
  --mission.engageMaxDistance=EngageMaxDistance and UTILS.NMToMeters(EngageMaxDistance) or UTILS.NMToMeters(5)
  mission.engageTargetTypes=TargetTypes or {"Ground vehicles"}

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDESCORT
  mission.missionFraction=0.1
  mission.missionAltitude=100
  mission.optionROE=ENUMS.ROE.OpenFire       -- TODO: what's the best ROE here? Make dependent on ESCORT or FOLLOW!
  mission.optionROT=ENUMS.ROT.EvadeFire

  mission.categories={AUFTRAG.Category.HELICOPTER}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- **[AIR]** Create an ESCORT (or FOLLOW) mission. Flight will escort another group and automatically engage certain target types.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP EscortGroup The group to escort.
-- @param DCS#Vec3 OffsetVector A table with x, y and z components specifying the offset of the flight to the escorted group. Default {x=-100, y=0, z=200} for z=200 meters to the right, same alitude (y=0), x=-100 meters behind.
-- @param #number EngageMaxDistance Max engage distance of targets in nautical miles. Default auto 32 NM.
-- @param #table TargetTypes Types of targets to engage automatically. Default is {"Air"}, i.e. all enemy airborne units. Use an empty set {} for a simple "FOLLOW" mission.
-- @return #AUFTRAG self
function AUFTRAG:NewESCORT(EscortGroup, OffsetVector, EngageMaxDistance, TargetTypes)

  local mission=AUFTRAG:New(AUFTRAG.Type.ESCORT)

  -- If only a string is passed we set a variable and check later if the group exists.
  if type(EscortGroup)=="string" then
    mission.escortGroupName=EscortGroup
    mission:_TargetFromObject()
  else
    mission:_TargetFromObject(EscortGroup)
  end

  -- DCS task parameters:
  mission.escortVec3=OffsetVector or {x=-100, y=0, z=200}
  mission.engageMaxDistance=EngageMaxDistance and UTILS.NMToMeters(EngageMaxDistance) or UTILS.NMToMeters(32)
  mission.engageTargetTypes=TargetTypes or {"Air"}

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.ESCORT
  mission.missionFraction=0.1
  mission.missionAltitude=1000
  mission.optionROE=ENUMS.ROE.OpenFire       -- TODO: what's the best ROE here? Make dependent on ESCORT or FOLLOW!
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR ROTARY]** Create a RESCUE HELO mission.
-- @param #AUFTRAG self
-- @param Wrapper.Unit#UNIT Carrier The carrier unit.
-- @return #AUFTRAG self
function AUFTRAG:NewRESCUEHELO(Carrier)

  local mission=AUFTRAG:New(AUFTRAG.Type.RESCUEHELO)

  mission:_TargetFromObject(Carrier)

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.NOTHING
  mission.missionFraction=0.9
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.NoReaction

  mission.categories={AUFTRAG.Category.HELICOPTER}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIRPANE]** Create a RECOVERY TANKER mission.
-- @param #AUFTRAG self
-- @param Wrapper.Unit#UNIT Carrier The carrier unit.
-- @param #number Altitude Orbit altitude in feet. Default is 6,000 ft.
-- @param #number Speed Orbit speed in knots. Default 250 KIAS.
-- @param #number Leg Length of race-track in NM. Default 14 NM.
-- @param #number RelHeading Relative heading [0, 360) of race-track pattern in degrees wrt heading of the carrier. Default is heading of the carrier.
-- @param #number OffsetDist Relative distance of the first race-track point wrt to the carrier. Default 6 NM.
-- @param #number OffsetAngle Relative angle of the first race-track point wrt. to the carrier. Default 180 (behind the boat).
-- @param #number UpdateDistance Threshold distance in NM before orbit pattern is updated. Default 5 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewRECOVERYTANKER(Carrier, Altitude, Speed, Leg, RelHeading, OffsetDist, OffsetAngle, UpdateDistance)
 
   -- Six NM astern.
  local OffsetVec2={r=OffsetDist or 6, phi=OffsetAngle or 180}
  
  -- Default leg.
  Leg=Leg or 14
  
  -- Default Speed.
  Speed=Speed or 250
  
  local Heading=nil
  if RelHeading then  
    Heading=-math.abs(RelHeading)
  end  
 
  -- Create orbit mission. 
  local mission=AUFTRAG:NewORBIT_GROUP(Carrier, Altitude, Speed, Leg, Heading, OffsetVec2, UpdateDistance)

  -- Set the type.  
  mission.type=AUFTRAG.Type.RECOVERYTANKER

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.REFUELING
  mission.missionFraction=0.9
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.NoReaction

  mission.categories={AUFTRAG.Category.AIRPLANE}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- **[AIR ROTARY, GROUND]** Create a TROOP TRANSPORT mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_GROUP TransportGroupSet The set group(s) to be transported.
-- @param Core.Point#COORDINATE DropoffCoordinate Coordinate where the helo will land drop off the the troops.
-- @param Core.Point#COORDINATE PickupCoordinate Coordinate where the helo will land to pick up the the cargo. Default is the first transport group.
-- @param #number PickupRadius Radius around the pickup coordinate in meters. Default 100 m.
-- @return #AUFTRAG self
function AUFTRAG:NewTROOPTRANSPORT(TransportGroupSet, DropoffCoordinate, PickupCoordinate, PickupRadius)

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

  mission.transportPickupRadius=PickupRadius or 100

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.TROOPTRANSPORT)

  -- Debug.
  --mission.transportPickup:MarkToAll("Pickup Transport")
  --mission.transportDropoff:MarkToAll("Drop off")

  -- TODO: what's the best ROE here?
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.HELICOPTER, AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR ROTARY]** Create a CARGO TRANSPORT mission.
-- **Important Note:**
-- The dropoff zone has to be a zone defined in the Mission Editor. This is due to a restriction in the used DCS task, which takes the zone ID as input.
-- Only ME zones have an ID that can be referenced.
-- @param #AUFTRAG self
-- @param Wrapper.Static#STATIC StaticCargo Static cargo object.
-- @param Core.Zone#ZONE DropZone Zone where to drop off the cargo. **Has to be a zone defined in the ME!**
-- @return #AUFTRAG self
function AUFTRAG:NewCARGOTRANSPORT(StaticCargo, DropZone)

  local mission=AUFTRAG:New(AUFTRAG.Type.CARGOTRANSPORT)

  mission:_TargetFromObject(StaticCargo)

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.CARGOTRANSPORT)

  -- Set ROE and ROT.
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.HELICOPTER}

  mission.DCStask=mission:GetDCSMissionTask()
  
  mission.DCStask.params.groupId=StaticCargo:GetID()
  mission.DCStask.params.zoneId=DropZone.ZoneID
  mission.DCStask.params.zone=DropZone
  mission.DCStask.params.cargo=StaticCargo
  
  return mission
end

--[[

--- **[AIR, GROUND, NAVAL]** Create a OPS TRANSPORT mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_GROUP CargoGroupSet The set group(s) to be transported.
-- @param Core.Zone#ZONE PickupZone Pick up zone
-- @param Core.Zone#ZONE DeployZone Deploy zone
-- @return #AUFTRAG self
function AUFTRAG:NewOPSTRANSPORT(CargoGroupSet, PickupZone, DeployZone)

  local mission=AUFTRAG:New(AUFTRAG.Type.OPSTRANSPORT)

  mission.transportGroupSet=CargoGroupSet

  mission:_TargetFromObject(mission.transportGroupSet)

  mission.opstransport=OPSTRANSPORT:New(CargoGroupSet, PickupZone, DeployZone)

  function mission.opstransport:OnAfterExecuting(From, Event, To)
    mission:Executing()
  end

  function mission.opstransport:OnAfterDelivered(From, Event, To)
    mission:Done()
  end

  -- TODO: what's the best ROE here?
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.categories={AUFTRAG.Category.ALL}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

]]

--- **[GROUND, NAVAL]** Create an ARTY mission ("Fire at point" task).
-- 
-- If the group has more than one weapon type supporting the "Fire at point" task, the employed weapon type can be set via the `AUFTRAG:SetWeaponType()` function.
-- 
-- **Note** that it is recommended to set the weapon range via the `OPSGROUP:AddWeaponRange()` function as this cannot be retrieved from the DCS API.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target Center of the firing solution.
-- @param #number Nshots Number of shots to be fired. Default `#nil`. If value is in (0,1), it is interpreted as per cent of available ammo.
-- @param #number Radius Radius of the shells in meters. Default 100 meters.
-- @param #number Altitude Altitude in meters. Can be used to setup a Barrage. Default `#nil`.
-- @return #AUFTRAG self
function AUFTRAG:NewARTY(Target, Nshots, Radius, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.ARTY)

  mission:_TargetFromObject(Target)

  mission.artyShots=Nshots or nil
  mission.artyRadius=Radius or 100
  mission.artyAltitude=Altitude

  mission.engageWeaponType=ENUMS.WeaponFlag.Auto

  mission.optionROE=ENUMS.ROE.OpenFire   -- Ground/naval need open fire!
  mission.optionAlarm=0

  mission.missionFraction=0.0
  mission.missionWaypointRadius=0.0

  -- Evaluate after 8 min.
  mission.dTevaluate=8*60

  mission.categories={AUFTRAG.Category.GROUND, AUFTRAG.Category.NAVAL}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[GROUND, NAVAL]** Create an BARRAGE mission. Assigned groups will move to a random coordinate within a given zone and start firing into the air.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone The zone where the unit will go.
-- @param #number Heading Heading in degrees. Default random heading [0, 360).
-- @param #number Angle Shooting angle in degrees. Default random [45, 85].
-- @param #number Radius Radius of the shells in meters. Default 100 meters.
-- @param #number Altitude Altitude in meters. Default 500 m.
-- @param #number Nshots Number of shots to be fired. Default is until ammo is empty (`#nil`).
-- @return #AUFTRAG self
function AUFTRAG:NewBARRAGE(Zone, Heading, Angle, Radius, Altitude, Nshots)

  local mission=AUFTRAG:New(AUFTRAG.Type.BARRAGE)

  mission:_TargetFromObject(Zone)

  mission.artyShots=Nshots
  mission.artyRadius=Radius or 100
  mission.artyAltitude=Altitude
  mission.artyHeading=Heading
  mission.artyAngle=Angle

  mission.engageWeaponType=ENUMS.WeaponFlag.Auto

  mission.optionROE=ENUMS.ROE.OpenFire   -- Ground/naval need open fire!
  mission.optionAlarm=0

  mission.missionFraction=0.0

  -- Evaluate after instantly.
  mission.dTevaluate=10

  mission.categories={AUFTRAG.Category.GROUND, AUFTRAG.Category.NAVAL}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[AIR, GROUND, NAVAL]** Create a PATROLZONE mission. Group(s) will go to the zone and patrol it randomly.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone The patrol zone.
-- @param #number Speed Speed in knots.
-- @param #number Altitude Altitude in feet. Only for airborne units. Default 2000 feet ASL.
-- @param #string Formation Formation used by ground units during patrol. Default "Off Road".
-- @return #AUFTRAG self
function AUFTRAG:NewPATROLZONE(Zone, Speed, Altitude, Formation)

  local mission=AUFTRAG:New(AUFTRAG.Type.PATROLZONE)

  -- Ensure we got a ZONE and not just the zone name.
  if type(Zone)=="string" then
    Zone=ZONE:New(Zone)
  end

  mission:_TargetFromObject(Zone)

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.PATROLZONE)

  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  mission.missionAltitude=Altitude and UTILS.FeetToMeters(Altitude) or nil

  mission.categories={AUFTRAG.Category.ALL}

  mission.DCStask=mission:GetDCSMissionTask()

  mission.DCStask.params.formation=Formation or "Off Road"

  return mission
end

--- **[AIR, GROUND, NAVAL]** Create a CAPTUREZONE mission. Group(s) will go to the zone and patrol it randomly.
-- @param #AUFTRAG self
-- @param Ops.OpsZone#OPSZONE OpsZone The OPS zone to capture.
-- @param #number Coalition The coalition which should capture the zone for the mission to be successful.
-- @param #number Speed Speed in knots.
-- @param #number Altitude Altitude in feet. Only for airborne units. Default 2000 feet ASL.
-- @param #string Formation Formation used by ground units during patrol. Default "Off Road".
-- @param #number StayInZoneTime Stay this many seconds in the zone when done, only then drive back.
-- @return #AUFTRAG self
function AUFTRAG:NewCAPTUREZONE(OpsZone, Coalition, Speed, Altitude, Formation, StayInZoneTime)

  local mission=AUFTRAG:New(AUFTRAG.Type.CAPTUREZONE)


  mission:_TargetFromObject(OpsZone)
  
  mission.coalition=Coalition

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.CAPTUREZONE)

  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  mission.optionAlarm=ENUMS.AlarmState.Auto
  mission.StayInZoneTime = StayInZoneTime

  mission.missionFraction=0.1
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  mission.missionAltitude=Altitude and UTILS.FeetToMeters(Altitude) or nil

  mission.categories={AUFTRAG.Category.ALL}

  mission.DCStask=mission:GetDCSMissionTask()
  
  mission.updateDCSTask=true

  local params={}
  
  params.formation=Formation or "Off Road"  
  params.zone=mission:GetObjective()
  params.altitude=mission.missionAltitude
  params.speed=mission.missionSpeed and UTILS.KmphToMps(mission.missionSpeed) or nil

  mission.DCStask.params=params

  return mission
end


--- **[OBSOLETE]** Create a ARMORATTACK mission.
-- ** Note that this is actually creating a GROUNDATTACK mission!** 
-- @param #AUFTRAG self
-- @param Ops.Target#TARGET Target The target to attack. Can be a GROUP, UNIT or STATIC object.
-- @param #number Speed Speed in knots.
-- @param #string Formation The attack formation, e.g. "Wedge", "Vee" etc.
-- @return #AUFTRAG self
function AUFTRAG:NewARMORATTACK(Target, Speed, Formation)

  local mission=AUFTRAG:NewGROUNDATTACK(Target, Speed, Formation)
  
  -- Mission type.
  mission.type=AUFTRAG.Type.ARMORATTACK  

  return mission
end

--- **[GROUND]** Create a GROUNDATTACK mission. Ground group(s) will go to a target object and attack at their own discretion.
-- Unfortunately, the "Attack Group" and "Attack Unit" tasks do not work for ground and naval groups (only for aircraft).
-- Therefore, we resort to this workaround, which guides the attacking group to the vicinity of the target. Then they start shooting on their own, once they detect the target.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP, UNIT or STATIC object.
-- @param #number Speed Speed in knots. Default max.
-- @param #string Formation The attack formation, e.g. "Wedge", "Vee" etc. Default `ENUMS.Formation.Vehicle.Vee`. Only working for ground, not naval!
-- @return #AUFTRAG self
function AUFTRAG:NewGROUNDATTACK(Target, Speed, Formation)

  local mission=AUFTRAG:New(AUFTRAG.Type.GROUNDATTACK)

  mission:_TargetFromObject(Target)

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.GROUNDATTACK)

  -- Defaults.
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionAlarm=ENUMS.AlarmState.Auto  
  mission.optionFormation="On Road"
  mission.missionFraction=0.70
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil

  mission.categories={AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()
  
  mission.DCStask.params.speed=mission.missionSpeed and UTILS.KmphToMps(mission.missionSpeed) or nil
  mission.DCStask.params.formation=Formation or ENUMS.Formation.Vehicle.Vee
  
  return mission
end

--- **[NAVAL]** Create a NAVALENGAGEMENT mission. Naval group(s) will go to a target object and attack at their own discretion.
-- Unfortunately, the "Attack Group" and "Attack Unit" tasks do not work for ground and naval groups (only for aircraft).
-- Therefore, we resort to this workaround, which guides the attacking group to the vicinity of the target. Then they start shooting on their own, once they detect the target.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP, UNIT or STATIC object.
-- @param #number Speed Speed in knots. Default max.
-- @param #number Depth The attack depth in meters. Only for submarines!
-- @return #AUFTRAG self
function AUFTRAG:NewNAVALENGAGEMENT(Target, Speed, Depth)

  local mission=AUFTRAG:New(AUFTRAG.Type.NAVALENGAGEMENT)

  mission:_TargetFromObject(Target)

  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.NAVALENGAGEMENT)

  -- Defaults.
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionAlarm=ENUMS.AlarmState.Auto
  mission.missionFraction=0.70
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  mission.missionAltitude=Depth or 0

  mission.categories={AUFTRAG.Category.NAVAL}

  mission.DCStask=mission:GetDCSMissionTask()
  
  mission.DCStask.params.speed=mission.missionSpeed and UTILS.KmphToMps(mission.missionSpeed) or nil
  
  return mission
end

--- **[AIR, GROUND, NAVAL]** Create a RECON mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_ZONE ZoneSet The recon zones.
-- @param #number Speed Speed in knots.
-- @param #number Altitude Altitude in feet. Only for airborne units. Default 2000 feet ASL.
-- @param #boolean Adinfinitum If `true`, the group will start over again after reaching the final zone.
-- @param #boolean Randomly If `true`, the group will select a random zone.
-- @param #string Formation Formation used during recon route.
-- @return #AUFTRAG self
function AUFTRAG:NewRECON(ZoneSet, Speed, Altitude, Adinfinitum, Randomly, Formation)

  local mission=AUFTRAG:New(AUFTRAG.Type.RECON)

  mission:_TargetFromObject(ZoneSet)
  
  if ZoneSet:IsInstanceOf("SET_ZONE") then
    mission.missionZoneSet = ZoneSet
  elseif ZoneSet:IsInstanceOf("ZONE_BASE") then
   mission.missionZoneSet = SET_ZONE:New()
   mission.missionZoneSet:AddZone(ZoneSet)
  end
  
  
  mission.missionTask=mission:GetMissionTaskforMissionType(AUFTRAG.Type.RECON)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=0.5
  mission.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  mission.missionAltitude=Altitude and UTILS.FeetToMeters(Altitude) or UTILS.FeetToMeters(2000)

  mission.categories={AUFTRAG.Category.ALL}

  mission.DCStask=mission:GetDCSMissionTask()
  mission.DCStask.params.adinfinitum=Adinfinitum
  mission.DCStask.params.randomly=Randomly
  mission.DCStask.params.formation=Formation

  return mission
end

--- **[GROUND]** Create a AMMO SUPPLY mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone The zone, where supply units go.
-- @return #AUFTRAG self
function AUFTRAG:NewAMMOSUPPLY(Zone)

  local mission=AUFTRAG:New(AUFTRAG.Type.AMMOSUPPLY)

  mission:_TargetFromObject(Zone)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.missionWaypointRadius=0

  mission.categories={AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[GROUND]** Create a FUEL SUPPLY mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone The zone, where supply units go.
-- @return #AUFTRAG self
function AUFTRAG:NewFUELSUPPLY(Zone)

  local mission=AUFTRAG:New(AUFTRAG.Type.FUELSUPPLY)

  mission:_TargetFromObject(Zone)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[GROUND]** Create a REARMING mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone The zone, where units go and look for ammo supply.
-- @return #AUFTRAG self
function AUFTRAG:NewREARMING(Zone)

  local mission=AUFTRAG:New(AUFTRAG.Type.REARMING)

  mission:_TargetFromObject(Zone)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.missionWaypointRadius=0

  mission.categories={AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- **[AIR]** Create an ALERT 5 mission. Aircraft will be spawned uncontrolled and wait for an assignment. You must specify **one** mission type which is performed.
-- This determines the payload and the DCS mission task which are used when the aircraft is spawned.
-- @param #AUFTRAG self
-- @param #string MissionType Mission type `AUFTRAG.Type.XXX`. Determines payload and mission task (intercept, ground attack, etc.).
-- @return #AUFTRAG self
function AUFTRAG:NewALERT5(MissionType)

  local mission=AUFTRAG:New(AUFTRAG.Type.ALERT5)

  mission.missionTask=self:GetMissionTaskforMissionType(MissionType)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.NoReaction

  mission.alert5MissionType=MissionType

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.AIRCRAFT}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[GROUND, NAVAL]** Create an ON GUARD mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Coordinate, where to stand guard.
-- @return #AUFTRAG self
function AUFTRAG:NewONGUARD(Coordinate)

  local mission=AUFTRAG:New(AUFTRAG.Type.ONGUARD)

  mission:_TargetFromObject(Coordinate)

  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.GROUND, AUFTRAG.Category.NAVAL}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[GROUND, NAVAL]** Create an AIRDEFENSE mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone Zone where the air defense group(s) should be stationed.
-- @return #AUFTRAG self
function AUFTRAG:NewAIRDEFENSE(Zone)

  local mission=AUFTRAG:New(AUFTRAG.Type.AIRDEFENSE)

  mission:_TargetFromObject(Zone)

  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.GROUND, AUFTRAG.Category.NAVAL}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- **[GROUND]** Create an EWR mission.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE Zone Zone where the Early Warning Radar group(s) should be stationed.
-- @return #AUFTRAG self
function AUFTRAG:NewEWR(Zone)

  local mission=AUFTRAG:New(AUFTRAG.Type.EWR)

  mission:_TargetFromObject(Zone)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end


--- **[PRIVATE, AIR, GROUND, NAVAL]** Create a mission to relocate all cohort assets to another LEGION.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The new legion.
-- @param Ops.Cohort#COHORT Cohort The cohort to be relocated.
-- @return #AUFTRAG self
function AUFTRAG:_NewRELOCATECOHORT(Legion, Cohort)

  local mission=AUFTRAG:New(AUFTRAG.Type.RELOCATECOHORT)
  
  mission:_TargetFromObject(Legion.spawnzone)

  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=0.0

  mission.categories={AUFTRAG.Category.ALL}

  mission.DCStask=mission:GetDCSMissionTask()
  
  if Cohort.isGround then
    mission.optionFormation=ENUMS.Formation.Vehicle.OnRoad
  end
    
  mission.DCStask.params.legion=Legion
  mission.DCStask.params.cohort=Cohort

  return mission
end

--- **[GROUND, NAVAL]** Create a mission to do NOTHING.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE RelaxZone Zone where the assets are supposed to do nothing.
-- @return #AUFTRAG self
function AUFTRAG:NewNOTHING(RelaxZone)

  local mission=AUFTRAG:New(AUFTRAG.Type.NOTHING)

  mission:_TargetFromObject(RelaxZone)

  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionAlarm=ENUMS.AlarmState.Auto

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.GROUND, AUFTRAG.Category.NAVAL}

  mission.DCStask=mission:GetDCSMissionTask()
    
  return mission
end

--- **[GROUND]** Create an ARMORED ON GUARD mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Coordinate, where to stand guard.
-- @param #string Formation Formation to take, e.g. "On Road", "Vee" etc.
-- @return #AUFTRAG self
function AUFTRAG:NewARMOREDGUARD(Coordinate,Formation)

  local mission=AUFTRAG:New(AUFTRAG.Type.ARMOREDGUARD)

  mission:_TargetFromObject(Coordinate)

  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionAlarm=ENUMS.AlarmState.Auto
  mission.optionFormation=Formation or "On Road"

  mission.missionFraction=1.0

  mission.categories={AUFTRAG.Category.GROUND}

  mission.DCStask=mission:GetDCSMissionTask()

  return mission
end

--- Create a mission to attack a TARGET object.
-- @param #AUFTRAG self
-- @param Ops.Target#TARGET Target The target.
-- @param #string MissionType The mission type.
-- @return #AUFTRAG self
function AUFTRAG:NewFromTarget(Target, MissionType)

  local mission=nil --#AUFTRAG

  if MissionType==AUFTRAG.Type.ANTISHIP then
    mission=self:NewANTISHIP(Target)
  elseif MissionType==AUFTRAG.Type.ARTY then
    mission=self:NewARTY(Target, 0.3) -- use 30% of the available ammo
  elseif MissionType==AUFTRAG.Type.BAI then
    mission=self:NewBAI(Target)
  elseif MissionType==AUFTRAG.Type.BOMBCARPET then
    mission=self:NewBOMBCARPET(Target)
  elseif MissionType==AUFTRAG.Type.BOMBING then
    mission=self:NewBOMBING(Target)
  elseif MissionType==AUFTRAG.Type.BOMBRUNWAY then
    mission=self:NewBOMBRUNWAY(Target)
  elseif MissionType==AUFTRAG.Type.STRAFING then
    mission=self:NewSTRAFING(Target)    
  elseif MissionType==AUFTRAG.Type.CAS then
    mission=self:NewCAS(ZONE_RADIUS:New(Target:GetName(),Target:GetVec2(),1000), nil, nil, Target:GetAverageCoordinate())
  elseif MissionType==AUFTRAG.Type.CASENHANCED then
    mission=self:NewCASENHANCED(ZONE_RADIUS:New(Target:GetName(),Target:GetVec2(),1000))
  elseif MissionType==AUFTRAG.Type.INTERCEPT then
    mission=self:NewINTERCEPT(Target)
  elseif MissionType==AUFTRAG.Type.SEAD then
    mission=self:NewSEAD(Target)
  elseif MissionType==AUFTRAG.Type.STRIKE then
    mission=self:NewSTRIKE(Target)
  elseif MissionType==AUFTRAG.Type.ARMORATTACK then
    mission=self:NewARMORATTACK(Target)
  elseif MissionType==AUFTRAG.Type.GROUNDATTACK then
    mission=self:NewGROUNDATTACK(Target)
  elseif MissionType==AUFTRAG.Type.NAVALENGAGEMENT then
    mission=self:NewNAVALENGAGEMENT(Target)
  else
    return nil
  end

  return mission
end


--- Create a mission to attack a group. Mission type is automatically chosen from the group category.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target Target object.
-- @return #string Auftrag type, e.g. `AUFTRAG.Type.BAI` (="BAI").
function AUFTRAG:_DetermineAuftragType(Target)

  local group=nil      --Wrapper.Group#GROUP
  local airbase=nil    --Wrapper.Airbase#AIRBASE
  local scenery=nil    --Wrapper.Scenery#SCENERY
  local coordinate=nil --Core.Point#COORDINATE
  local auftrag=nil

  if Target:IsInstanceOf("GROUP") then
    group=Target --Target is already a group.
  elseif Target:IsInstanceOf("UNIT") then
    group=Target:GetGroup()
  elseif Target:IsInstanceOf("AIRBASE") then
    airbase=Target
  elseif Target:IsInstanceOf("SCENERY") then
    scenery=Target
  end

  if group then

    local category=group:GetCategory()
    local attribute=group:GetAttribute()

    if category==Group.Category.AIRPLANE or category==Group.Category.HELICOPTER then

      ---
      -- A2A: Intercept
      ---

      auftrag=AUFTRAG.Type.INTERCEPT

    elseif category==Group.Category.GROUND or category==Group.Category.TRAIN then

      ---
      -- GROUND
      ---

      if attribute==GROUP.Attribute.GROUND_SAM then

        -- SEAD/DEAD

        auftrag=AUFTRAG.Type.SEAD

      elseif attribute==GROUP.Attribute.GROUND_AAA then

        auftrag=AUFTRAG.Type.BAI

      elseif attribute==GROUP.Attribute.GROUND_ARTILLERY then

        auftrag=AUFTRAG.Type.BAI

      elseif attribute==GROUP.Attribute.GROUND_INFANTRY then

        auftrag=AUFTRAG.Type.CAS

      elseif attribute==GROUP.Attribute.GROUND_TANK then

        auftrag=AUFTRAG.Type.BAI

      else

        auftrag=AUFTRAG.Type.BAI

      end


    elseif category==Group.Category.SHIP then

      ---
      -- NAVAL
      ---

      auftrag=AUFTRAG.Type.ANTISHIP

    else
      self:T(self.lid.."ERROR: Unknown Group category!")
    end

  elseif airbase then
    auftrag=AUFTRAG.Type.BOMBRUNWAY
  elseif scenery then
    auftrag=AUFTRAG.Type.STRIKE
  elseif coordinate then
    auftrag=AUFTRAG.Type.BOMBING
  end

  return auftrag
end

--- Create a mission to attack a group. Mission type is automatically chosen from the group category.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP EngageGroup Group to be engaged.
-- @return #AUFTRAG self
function AUFTRAG:NewAUTO(EngageGroup)

  local mission=nil --#AUFTRAG

  local Target=EngageGroup

  local auftrag=self:_DetermineAuftragType(EngageGroup)

  if auftrag==AUFTRAG.Type.ANTISHIP then
    mission=AUFTRAG:NewANTISHIP(Target)
  elseif auftrag==AUFTRAG.Type.ARTY then
    mission=AUFTRAG:NewARTY(Target, 0.2)
  elseif auftrag==AUFTRAG.Type.AWACS then
    mission=AUFTRAG:NewAWACS(Coordinate, Altitude,Speed,Heading,Leg)
  elseif auftrag==AUFTRAG.Type.BAI then
    mission=AUFTRAG:NewBAI(Target,Altitude)
  elseif auftrag==AUFTRAG.Type.BOMBING then
    mission=AUFTRAG:NewBOMBING(Target,Altitude)
  elseif auftrag==AUFTRAG.Type.BOMBRUNWAY then
    mission=AUFTRAG:NewBOMBRUNWAY(Airdrome,Altitude)
  elseif auftrag==AUFTRAG.Type.BOMBCARPET then
    mission=AUFTRAG:NewBOMBCARPET(Target,Altitude,CarpetLength)
  elseif auftrag==AUFTRAG.Type.CAP then
    mission=AUFTRAG:NewCAP(ZoneCAP,Altitude,Speed,Coordinate,Heading,Leg,TargetTypes)
  elseif auftrag==AUFTRAG.Type.CAS then
  mission=AUFTRAG:NewCAS(ZoneCAS,Altitude,Speed,Coordinate,Heading,Leg,TargetTypes)
  elseif auftrag==AUFTRAG.Type.ESCORT then
    mission=AUFTRAG:NewESCORT(EscortGroup,OffsetVector,EngageMaxDistance,TargetTypes)
  elseif auftrag==AUFTRAG.Type.FACA then
    mission=AUFTRAG:NewFACA(Target,Designation,DataLink,Frequency,Modulation)
  
  elseif auftrag==AUFTRAG.Type.FERRY then
    -- Not implemented yet.
  elseif auftrag==AUFTRAG.Type.GCICAP then
    mission=AUFTRAG:NewGCICAP(Coordinate,Altitude,Speed,Heading,Leg)
  elseif auftrag==AUFTRAG.Type.INTERCEPT then
    mission=AUFTRAG:NewINTERCEPT(Target)
  elseif auftrag==AUFTRAG.Type.ORBIT then
    mission=AUFTRAG:NewORBIT(Coordinate,Altitude,Speed,Heading,Leg)
  elseif auftrag==AUFTRAG.Type.RECON then
    mission=AUFTRAG:NewRECON(ZoneSet,Speed,Altitude,Adinfinitum,Randomly,Formation)
  elseif auftrag==AUFTRAG.Type.RESCUEHELO then
    mission=AUFTRAG:NewRESCUEHELO(Carrier)
  elseif auftrag==AUFTRAG.Type.SEAD then
    mission=AUFTRAG:NewSEAD(Target,Altitude)
  elseif auftrag==AUFTRAG.Type.STRIKE then
    mission=AUFTRAG:NewSTRIKE(Target,Altitude)
  elseif auftrag==AUFTRAG.Type.TANKER then
    mission=AUFTRAG:NewTANKER(Coordinate,Altitude,Speed,Heading,Leg,RefuelSystem)
  elseif auftrag==AUFTRAG.Type.TROOPTRANSPORT then
    mission=AUFTRAG:NewTROOPTRANSPORT(TransportGroupSet,DropoffCoordinate,PickupCoordinate)
  elseif auftrag==AUFTRAG.Type.PATROLRACETRACK then
    mission=AUFTRAG:NewPATROL_RACETRACK(Coordinate,Altitude,Speed,Heading,Leg,Formation)
  else

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

--- Set time how long the mission is executed. Once this time limit has passed, the mission is cancelled.
-- @param #AUFTRAG self
-- @param #number Duration Duration in seconds.
-- @return #AUFTRAG self
function AUFTRAG:SetDuration(Duration)
  self.durationExe=Duration
  return self
end

--- Set that mission assets are teleported to the mission execution waypoint.
-- @param #AUFTRAG self
-- @param #boolean Switch If `true` or `nil`, teleporting is on. If `false`, teleporting is off.
-- @return #AUFTRAG self
function AUFTRAG:SetTeleport(Switch)
  if Switch==nil then
    Switch=true
  end
  self.teleport=Switch
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set whether assigned assets return to their legion once the mission is over. This is only applicable to **army** and **navy** groups, *i.e.* aircraft 
-- will always return.
-- @param #AUFTRAG self
-- @param #boolean Switch If `true`, assets will return. If `false`, assets will not return and stay where it finishes its last mission. If `nil`, let asset decide.
-- @return #AUFTRAG self
function AUFTRAG:SetReturnToLegion(Switch)
  self.legionReturn=Switch
  self:T(self.lid..string.format("Setting ReturnToLetion=%s", tostring(self.legionReturn)))
  return self
end


--- Set mission push time. This is the time the mission is executed. If the push time is not passed, the group will wait at the mission execution waypoint.
-- @param #AUFTRAG self
-- @param #string ClockPush Time the mission is executed, e.g. "05:00" for 5 am. Can also be given as a `#number`, where it is interpreted as relative push time in seconds.
-- @return #AUFTRAG self
function AUFTRAG:SetPushTime(ClockPush)

  if ClockPush then
    if type(ClockPush)=="string" then
      self.Tpush=UTILS.ClockToSeconds(ClockPush)
    elseif type(ClockPush)=="number" then
      self.Tpush=timer.getAbsTime()+ClockPush
    end
  end

  return self
end

--- Set mission priority and (optional) urgency. Urgent missions can cancel other running missions.
-- @param #AUFTRAG self
-- @param #number Prio Priority 1=high, 100=low. Default 50.
-- @param #boolean Urgent If *true*, another running mission might be cancelled if it has a lower priority.
-- @param #number Importance Number 1-10. If missions with lower value are in the queue, these have to be finished first. Default is `nil`.
-- @return #AUFTRAG self
function AUFTRAG:SetPriority(Prio, Urgent, Importance)
  self.prio=Prio or 50
  self.urgent=Urgent
  self.importance=Importance
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set how many times the mission is repeated. Only valid if the mission is handled by a LEGION (AIRWING, BRIGADE, FLEET) or higher level.
-- @param #AUFTRAG self
-- @param #number Nrepeat Number of repeats. Default 0.
-- @return #AUFTRAG self
function AUFTRAG:SetRepeat(Nrepeat)
  self.Nrepeat=Nrepeat or 0
  return self
end


--- **[LEGION, COMMANDER, CHIEF]** Set the repeat delay in seconds after a mission is successful/failed. Only valid if the mission is handled by a LEGION (AIRWING, BRIGADE, FLEET) or higher level.
-- @param #AUFTRAG self
-- @param #number Nrepeat Repeat delay in seconds. Default 1.
-- @return #AUFTRAG self
function AUFTRAG:SetRepeatDelay(RepeatDelay)
  self.repeatDelay = RepeatDelay
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set how many times the mission is repeated if it fails. Only valid if the mission is handled by a LEGION (AIRWING, BRIGADE, FLEET) or higher level.
-- @param #AUFTRAG self
-- @param #number Nrepeat Number of repeats. Default 0.
-- @return #AUFTRAG self
function AUFTRAG:SetRepeatOnFailure(Nrepeat)
  self.NrepeatFailure=Nrepeat or 0
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set how many times the mission is repeated if it was successful. Only valid if the mission is handled by a LEGION (AIRWING, BRIGADE, FLEET) or higher level.
-- @param #AUFTRAG self
-- @param #number Nrepeat Number of repeats. Default 0.
-- @return #AUFTRAG self
function AUFTRAG:SetRepeatOnSuccess(Nrepeat)
  self.NrepeatSuccess=Nrepeat or 0
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set that mission assets get reinforced if their number drops below the minimum number of required assets of the mission (*c.f.* SetRequiredAssets() function).
-- 
-- **Note** that reinforcement groups are only recruited from the legion (airwing, brigade, fleet) the mission was assigned to. If the legion does not have any more of these assets, 
-- no reinforcement can take place, even if the mission is submitted to a COMMANDER or CHIEF. 
-- @param #AUFTRAG self
-- @param #number Nreinforce Number of max asset groups used to reinforce.
-- @return #AUFTRAG self
function AUFTRAG:SetReinforce(Nreinforce)
  self.reinforce=Nreinforce
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Define how many assets are required to do the job. Only used if the mission is handled by a **LEGION** (AIRWING, BRIGADE, ...) or higher level.
-- @param #AUFTRAG self
-- @param #number NassetsMin Minimum number of asset groups. Default 1.
-- @param #number NassetsMax Maximum Number of asset groups. Default is same as `NassetsMin`.
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredAssets(NassetsMin, NassetsMax)

  self.NassetsMin=NassetsMin or 1

  self.NassetsMax=NassetsMax or self.NassetsMin

  -- Ensure that max is at least equal to min.
  if self.NassetsMax<self.NassetsMin then
    self.NassetsMax=self.NassetsMin
  end

  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Get number of required assets.
-- @param #AUFTRAG self
-- @return #number Min. number of required assets.
-- @return #number Max. number of required assets.
function AUFTRAG:GetRequiredAssets()
  
  local Nmin=self.NassetsMin
  local Nmax=self.NassetsMax
    
  if self.type==AUFTRAG.Type.RELOCATECOHORT then

    -- Relocation gets all the assets.
    local cohort=self.DCStask.params.cohort --Ops.Cohort#COHORT
    Nmin=#cohort.assets
    Nmax=Nmin
    
  else

    -- Check if this is an reinforcement.
    if self:IsExecuting() and self.reinforce and self.reinforce>0 then
      local N=self:CountOpsGroups()
      if N<Nmin then
        Nmin=math.min(Nmin-N, self.reinforce)
        Nmax=Nmin
        self:T(self.lid..string.format("FF Executing Nmin=%d, N=%d, Nreinfoce=%d ==> Nmin=%d", self.NassetsMin, N, self.reinforce, Nmin))
      end
    end
  
  end

  return Nmin, Nmax
end

--- **[LEGION, COMMANDER, CHIEF]** Set that only alive (spawned) assets are considered.
-- @param #AUFTRAG self
-- @param #boolean Switch If true or nil, only active assets. If false
-- @return #AUFTRAG self
function AUFTRAG:SetAssetsStayAlive(Switch)

  if Switch==nil then
    Switch=true
  end

  self.assetStayAlive=Switch

  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Define how many assets are required that escort the mission assets. 
-- Only used if the mission is handled by a **LEGION** (AIRWING, BRIGADE, FLEET) or higher level.
-- @param #AUFTRAG self
-- @param #number NescortMin Minimum number of asset groups. Default 1.
-- @param #number NescortMax Maximum Number of asset groups. Default is same as `NassetsMin`.
-- @param #string MissionType Mission type assets will be optimized for and payload selected, *e.g.* `AUFTRAG.Type.SEAD`. Default nil.
-- @param #table TargetTypes Target Types that will be engaged by the escort group(s). Default `{"Air"}` for aircraft and `{"Ground Units"}` for helos. Set, *e.g.*, `{"Air Defence"}` for SEAD.
-- @param #number EngageRange Max range in nautical miles that the escort group(s) will engage enemies. Default 32 NM (60 km).
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredEscorts(NescortMin, NescortMax, MissionType, TargetTypes, EngageRange)

  -- Set number of escort assets.
  self.NescortMin=NescortMin or 1
  self.NescortMax=NescortMax or self.NescortMin

  -- Ensure that max is at least equal to min.
  if self.NescortMax<self.NescortMin then
    self.NescortMax=self.NescortMin
  end
  
  -- Set parameters.
  self.escortMissionType=MissionType
  self.escortTargetTypes=TargetTypes
  self.escortEngageRange=EngageRange or 32

  -- Debug info.
  self:T(self.lid..string.format("NescortMin=%s, NescortMax=%s", tostring(self.NescortMin), tostring(self.NescortMax)))

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

--- Enable markers, which dispay the mission status on the F10 map.
-- @param #AUFTRAG self
-- @param #number Coalition The coaliton side to which the markers are dispayed. Default is to all.
-- @return #AUFTRAG self
function AUFTRAG:SetEnableMarkers(Coalition)
  self.markerOn=true
  self.markerCoaliton=Coalition or -1
  return self
end

--- Set verbosity level.
-- @param #AUFTRAG self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #AUFTRAG self
function AUFTRAG:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set weapon type used for the engagement.
-- @param #AUFTRAG self
-- @param #number WeaponType Weapon type. Default is `ENUMS.WeaponFlag.Auto`.
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

--- Set engage altitude. This is the altitude passed to the DCS task. In the ME it is the tickbox ALTITUDE ABOVE.
-- @param #AUFTRAG self
-- @param #string Altitude Altitude in feet. Default 6000 ft.
-- @return #AUFTRAG self
function AUFTRAG:SetEngageAltitude(Altitude)

  self.engageAltitude=UTILS.FeetToMeters(Altitude or 6000)

   -- Update the DCS task parameter.
  self.DCStask=self:GetDCSMissionTask()

  return self
end

--- Enable to automatically engage detected targets.
-- @param #AUFTRAG self
-- @param #number RangeMax Max range in NM. Only detected targets within this radius from the group will be engaged. Default is 25 NM.
-- @param #table TargetTypes Types of target attributes that will be engaged. See [DCS enum attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes). Default "All".
-- @param Core.Set#SET_ZONE EngageZoneSet Set of zones in which targets are engaged. Default is anywhere.
-- @param Core.Set#SET_ZONE NoEngageZoneSet Set of zones in which targets are *not* engaged. Default is nowhere.
-- @return #AUFTRAG self
function AUFTRAG:SetEngageDetected(RangeMax, TargetTypes, EngageZoneSet, NoEngageZoneSet)

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

  return self
end

--- Set mission altitude. This is the altitude of the waypoint create where the DCS task is executed.
-- @param #AUFTRAG self
-- @param #string Altitude Altitude in feet.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionAltitude(Altitude)
  self.missionAltitude=UTILS.FeetToMeters(Altitude)
  return self
end

--- Set mission speed. That is the speed the group uses to get to the mission waypoint.
-- @param #AUFTRAG self
-- @param #string Speed Mission speed in knots.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionSpeed(Speed)
  self.missionSpeed=Speed and UTILS.KnotsToKmph(Speed) or nil
  return self
end

--- Set max mission range. Only applies if the AUFTRAG is handled by an AIRWING or CHIEF. This is the max allowed distance from the airbase to the target.
-- @param #AUFTRAG self
-- @param #number Range Max range in NM. Default 100 NM.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionRange(Range)
  self.engageRange=UTILS.NMToMeters(Range or 100)
  return self
end

--- Attach OPS transport to the mission. Mission assets will be transported before the mission is started at the OPSGROUP level.
-- @param #AUFTRAG self
-- @param Ops.OpsTransport#OPSTRANSPORT OpsTransport The OPS transport assignment attached to the mission.
-- @return #AUFTRAG self
function AUFTRAG:SetOpsTransport(OpsTransport)
  self.opstransport=OpsTransport
  return self
end

--- Get the attach OPS transport of the mission.
-- @param #AUFTRAG self
-- @return Ops.OpsTransport#OPSTRANSPORT The OPS transport assignment attached to the mission.
function AUFTRAG:GetOpsTransport()
  return self.opstransport
end

--- **[LEGION, COMMANDER, CHIEF]** Attach OPS transport to the mission. Mission assets will be transported before the mission is started at the OPSGROUP level.
-- @param #AUFTRAG self
-- @param Core.Zone#ZONE DeployZone Zone where assets are deployed.
-- @param #number NcarriersMin Number of carriers *at least* required. Default 1.
-- @param #number NcarriersMax Number of carriers *at most* used for transportation. Default is same as `NcarriersMin`.
-- @param Core.Zone#ZONE DisembarkZone Zone where assets are disembarked to.
-- @param #table Categories Group categories.
-- @param #table Attributes Generalizes group attributes.
-- @param #table Properties DCS attributes.
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredTransport(DeployZone, NcarriersMin, NcarriersMax, DisembarkZone, Categories, Attributes, Properties)

  -- OPS transport from pickup to deploy zone.
  self.transportDeployZone=DeployZone
  self.transportDisembarkZone=DisembarkZone

  -- Set required carriers.
  self:SetRequiredCarriers(NcarriersMin, NcarriersMax, Categories, Attributes, Properties)

  return self
end

--- Add carriers for a transport of mission assets.
-- @param #AUFTRAG self
-- @param Core.Set#SET_OPSGROUP Carriers Set of carriers. Can also be a single group.
-- @return #AUFTRAG self
function AUFTRAG:AddTransportCarriers(Carriers)

  if self.opstransport then
    if Carriers:IsInstanceOf("SET_OPSGROUP") then

      for _,_carrier in pairs(Carriers.Set) do
        local carrier=_carrier --Ops.OpsGroup#OPSGROUP
        carrier:AddOpsTransport(self.opstransport)
      end

    elseif Carriers:IsInstanceOf("OPSGROUP") then
      Carriers:AddOpsTransport(self.opstransport)
    end

  end

  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set required attribute(s) the assets must have.
-- @param #AUFTRAG self
-- @param #table Attributes Generalized attribute(s).
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredAttribute(Attributes)
  self.attributes=UTILS.EnsureTable(Attributes, true)
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set required property or properties the assets must have.
-- These are [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes).
-- @param #AUFTRAG self
-- @param #table Properties Property or table of properties.
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredProperty(Properties)
  self.properties=UTILS.EnsureTable(Properties, true)
  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Set number of required carrier groups if an OPSTRANSPORT assignment is required.
-- @param #AUFTRAG self
-- @param #number NcarriersMin Number of carriers *at least* required. Default 1.
-- @param #number NcarriersMax Number of carriers *at most* used for transportation. Default is same as `NcarriersMin`.
-- @param #table Categories Group categories.
-- @param #table Attributes Group attributes. See `GROUP.Attribute.`
-- @param #table Properties DCS attributes.
-- @return #AUFTRAG self
function AUFTRAG:SetRequiredCarriers(NcarriersMin, NcarriersMax, Categories, Attributes, Properties)

  self.NcarriersMin=NcarriersMin or 1

  self.NcarriersMax=NcarriersMax or self.NcarriersMin

  -- Ensure that max is at least equal to min.
  if self.NcarriersMax<self.NcarriersMin then
    self.NcarriersMax=self.NcarriersMin
  end

  self.carrierCategories = UTILS.EnsureTable(Categories, true)
  self.carrierAttributes = UTILS.EnsureTable(Attributes, true)
  self.carrierProperties = UTILS.EnsureTable(Properties, true)

  return self
end

--- Set that (jet) aircraft are generally **not** allowed to use afterburner. Default is use of afterburner is allowed.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:SetProhibitAfterburner()
  self.prohibitAB = true
  return self 
end

--- Set that (jet) aircraft are generally allowed to use afterburner. Default is use of afterburner is allowed.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:SetAllowAfterburner()
  self.prohibitAB = false
  return self 
end

--- Set that (jet) aircraft are **not** allowed to use afterburner in mission execution phase. Default is use of afterburner is allowed.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:SetProhibitAfterburnerExecutePhase()
  self.prohibitABExecute = true
  return self 
end

--- Set that (jet) aircraft are allowed to use afterburner in mission execution phase. Default is use of afterburner is allowed.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:SetAllowAfterburnerExecutePhase()
  self.prohibitABExecute = false
  return self 
end

-- prohibitABExecute

--- **[LEGION, COMMANDER, CHIEF]** Assign a legion cohort to the mission. Only these cohorts will be considered for the job.
-- @param #AUFTRAG self
-- @param Ops.Cohort#COHORT Cohort The cohort.
-- @return #AUFTRAG self
function AUFTRAG:AssignCohort(Cohort)

  self.specialCohorts=self.specialCohorts or {}

  self:T3(self.lid..string.format("Assigning cohort %s", tostring(Cohort.name)))

  -- Add cohort to table.
  table.insert(self.specialCohorts, Cohort)

  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Assign a legion to the mission. Only cohorts of this legion will be considered for the job. You can assign multiple legions.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #AUFTRAG self
function AUFTRAG:AssignLegion(Legion)

  self.specialLegions=self.specialLegions or {}

  self:T3(self.lid..string.format("Assigning Legion %s", tostring(Legion.alias)))

  -- Add Legion to table.
  table.insert(self.specialLegions, Legion)

  return self
end


--- **[LEGION, COMMANDER, CHIEF]** Assign airwing squadron(s) to the mission. Only these squads will be considered for the job.
-- @param #AUFTRAG self
-- @param #table Squadrons A table of SQUADRON(s). **Has to be a table {}** even if a single squad is given.
-- @return #AUFTRAG self
function AUFTRAG:AssignSquadrons(Squadrons)

  for _,_squad in pairs(Squadrons) do
    local squadron=_squad --Ops.Squadron#SQUADRON
    self:T(self.lid..string.format("Assigning squadron %s", tostring(squadron.name)))
    self:AssignCohort(squadron)
  end

  return self
end


--- **[LEGION, COMMANDER, CHIEF]** Assign a transport Legion.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
function AUFTRAG:AssignTransportLegion(Legion)

  self.transportLegions=self.transportLegions or {}

  table.insert(self.transportLegions, Legion)

  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Assign a transport cohort.
-- @param #AUFTRAG self
-- @param Ops.Cohort#Cohort Cohort The cohort.
function AUFTRAG:AssignTransportCohort(Cohort)

  self.transportCohorts=self.transportCohorts or {}

  table.insert(self.transportCohorts, Cohort)

  return self
end


--- **[LEGION, COMMANDER, CHIEF]** Add an escort Legion.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
function AUFTRAG:AssignEscortLegion(Legion)

  self.escortLegions=self.escortLegions or {}

  table.insert(self.escortLegions, Legion)

  return self
end

--- **[LEGION, COMMANDER, CHIEF]** Assign an escort cohort.
-- @param #AUFTRAG self
-- @param Ops.Cohort#Cohort Cohort The cohort.
function AUFTRAG:AssignEscortCohort(Cohort)

  self.escortCohorts=self.escortCohorts or {}

  table.insert(self.escortCohorts, Cohort)

  return self
end



--- Set Rules of Engagement (ROE) for this mission.
-- @param #AUFTRAG self
-- @param #number roe Mission ROE, e.g. `ENUMS.ROE.ReturnFire` (whiche equals 3)
-- @return #AUFTRAG self
function AUFTRAG:SetROE(roe)

  self.optionROE=roe

  return self
end


--- Set Reaction on Threat (ROT) for this mission.
-- @param #AUFTRAG self
-- @param #number rot Mission ROT, e.g. `ENUMS.ROT.NoReaction` (whiche equals 0)
-- @return #AUFTRAG self
function AUFTRAG:SetROT(rot)

  self.optionROT=rot

  return self
end

--- Set alarm state for this mission.
-- @param #AUFTRAG self
-- @param #number Alarmstate Alarm state 0=Auto, 1=Green, 2=Red.
-- @return #AUFTRAG self
function AUFTRAG:SetAlarmstate(Alarmstate)

  self.optionAlarm=Alarmstate

  return self
end

--- Set EPLRS datalink setting for this mission.
-- @param #AUFTRAG self
-- @param #boolean OnOffSwitch If `true` or `nil`, EPLRS is on. If `false`, EPLRS is off.
-- @return #AUFTRAG self
function AUFTRAG:SetEPLRS(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionEPLRS=true
  else
    self.optionEPLRS=OnOffSwitch
  end

  return self
end

--- Set emission setting for this mission.
-- @param #AUFTRAG self
-- @param #boolean OnOffSwitch If `true` or `nil`, emission is on. If `false`, emission is off.
-- @return #AUFTRAG self
function AUFTRAG:SetEmission(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionEmission=true
  else
    self.optionEmission=OnOffSwitch
  end

  return self
end

--- Set invisibility setting for this mission.
-- @param #AUFTRAG self
-- @param #boolean OnOffSwitch If `true` or `nil`, invisible is on. If `false`, invisible is off.
-- @return #AUFTRAG self
function AUFTRAG:SetInvisible(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionInvisible=true
  else
    self.optionInvisible=OnOffSwitch
  end

  return self
end

--- Set immortality setting for this mission.
-- @param #AUFTRAG self
-- @param #boolean OnOffSwitch If `true` or `nil`, immortal is on. If `false`, immortal is off.
-- @return #AUFTRAG self
function AUFTRAG:SetImmortal(OnOffSwitch)

  if OnOffSwitch==nil then
    self.optionImmortal=true
  else
    self.optionImmortal=OnOffSwitch
  end

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

  self.radio={}
  self.radio.Freq=Frequency
  self.radio.Modu=Modulation

  return self
end

--- Set TACAN beacon channel and Morse code for this mission.
-- @param #AUFTRAG self
-- @param #number Channel TACAN channel.
-- @param #string Morse Morse code. Default "XXX".
-- @param #string UnitName Name of the unit in the group for which acts as TACAN beacon. Default is the first unit in the group.
-- @param #string Band Tacan channel mode ("X" or "Y"). Default is "X" for ground/naval and "Y" for aircraft.
-- @return #AUFTRAG self
function AUFTRAG:SetTACAN(Channel, Morse, UnitName, Band)

  self.tacan={}
  self.tacan.Channel=Channel
  self.tacan.Morse=Morse or "XXX"
  self.tacan.UnitName=UnitName
  self.tacan.Band=Band

  return self
end

--- Set ICLS beacon channel and Morse code for this mission.
-- @param #AUFTRAG self
-- @param #number Channel ICLS channel.
-- @param #string Morse Morse code. Default "XXX".
-- @param #string UnitName Name of the unit in the group for which acts as ICLS beacon. Default is the first unit in the group.
-- @return #AUFTRAG self
function AUFTRAG:SetICLS(Channel, Morse, UnitName)

  self.icls={}
  self.icls.Channel=Channel
  self.icls.Morse=Morse or "XXX"
  self.icls.UnitName=UnitName

  return self
end

--- Set time interval between mission done and success/failure evaluation.
-- @param #AUFTRAG self
-- @param #number Teval Time in seconds before the mission result is evaluated. Default depends on mission type.
-- @return #AUFTRAG self
function AUFTRAG:SetEvaluationTime(Teval)

  self.dTevaluate=Teval or 60

  return self
end

--- Get mission type.
-- @param #AUFTRAG self
-- @return #string Mission type, e.g. "BAI".
function AUFTRAG:GetType()
  return self.type
end

--- Get mission name.
-- @param #AUFTRAG self
-- @return #string Mission name, e.g. "Auftrag Nr.1".
function AUFTRAG:GetName()
  return self.name
end

--- Get number of required assets.
-- @param #AUFTRAG self
-- @return #number Numer of required assets.
function AUFTRAG:GetNumberOfRequiredAssets()
  return self.Nassets or self.NassetsMin
end

--- Get mission priority.
-- @param #AUFTRAG self
-- @return #number Priority. Smaller is higher.
function AUFTRAG:GetPriority()
  return self.prio
end

--- Get casualties, *i.e.* number of own units that died during this mission.
-- @param #AUFTRAG self
-- @return #number Number of dead units.
function AUFTRAG:GetCasualties()
  return self.Ncasualties or 0
end

--- Get kills, i.e. number of units that were destroyed by assets of this mission.
-- @param #AUFTRAG self
-- @return #number Number of units destroyed.
function AUFTRAG:GetKills()
  return self.Nkills or 0
end


--- Check if mission is "urgent".
-- @param #AUFTRAG self
-- @return #boolean If `true`, mission is "urgent".
function AUFTRAG:IsUrgent()
  return self.urgent
end

--- Get mission importance.
-- @param #AUFTRAG self
-- @return #number Importance. Smaller is higher.
function AUFTRAG:GetImportance()
  return self.importance
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
  
  self.conditionSuccessSet = true
  
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
  
  self.conditionFailureSet = true
  
  return self
end

--- Add push condition.
-- @param #AUFTRAG self
-- @param #function ConditionFunction If this function returns `true`, the mission is executed.
-- @param ... Condition function arguments if any.
-- @return #AUFTRAG self
function AUFTRAG:AddConditionPush(ConditionFunction, ...)

  local condition={} --#AUFTRAG.Condition

  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end

  table.insert(self.conditionPush, condition)

  return self
end

--- Add a required payload for this mission. Only these payloads will be used for this mission. If they are not available, the mission cannot start. Only available for use with an AIRWING.
-- @param #AUFTRAG self
-- @param Ops.Airwing#AIRWING.Payload Payload Required payload.
-- @return #AUFTRAG self
function AUFTRAG:AddRequiredPayload(Payload)

  self.payloads=self.payloads or {}

  table.insert(self.payloads, Payload)

  return self
end


--- Add a Ops group to the mission.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPSGROUP object.
-- @return #AUFTRAG self
function AUFTRAG:AddOpsGroup(OpsGroup)
  self:T(self.lid..string.format("Adding Ops group %s", OpsGroup.groupname))

  local groupdata={} --#AUFTRAG.GroupData
  groupdata.opsgroup=OpsGroup
  groupdata.status=AUFTRAG.GroupStatus.SCHEDULED
  groupdata.waypointcoordinate=nil
  groupdata.waypointindex=nil
  groupdata.waypointtask=nil

  self.groupdata[OpsGroup.groupname]=groupdata

  -- Add ops transport to new group.
  if self.opstransport then
    for _,_tzc in pairs(self.opstransport.tzCombos) do
      local tzc=_tzc --Ops.OpsTransport#OPSTRANSPORT.TransportZoneCombo

      if tzc.assetsCargo and tzc.assetsCargo[OpsGroup:GetName()] then
        self.opstransport:AddCargoGroups(OpsGroup, tzc)
      end

    end
  end

  return self
end

--- Remove an Ops group from the mission.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPSGROUP object.
-- @return #AUFTRAG self
function AUFTRAG:DelOpsGroup(OpsGroup)
  self:T(self.lid..string.format("Removing OPS group %s", OpsGroup and OpsGroup.groupname or "nil (ERROR)!"))

  if OpsGroup then

    -- Remove mission form queue.
    OpsGroup:RemoveMission(self)

    self.groupdata[OpsGroup.groupname]=nil

  end

  return self
end

--- Check if mission is PLANNED.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is in the planning state.
function AUFTRAG:IsPlanned()
  return self.status==AUFTRAG.Status.PLANNED
end

--- Check if mission is QUEUED at a LEGION mission queue.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion (Optional) Check if mission is queued at this legion.
-- @return #boolean If true, mission is queued.
function AUFTRAG:IsQueued(Legion)
  local is=self.status==AUFTRAG.Status.QUEUED
  if Legion then
    is=self:GetLegionStatus(Legion)==AUFTRAG.Status.QUEUED
  end
  return is
end

--- Check if mission is REQUESTED. The mission request out to the WAREHOUSE.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion (Optional) Check if mission is requested at this legion.
-- @return #boolean If true, mission is requested.
function AUFTRAG:IsRequested(Legion)
  local is=self.status==AUFTRAG.Status.REQUESTED
  if Legion then
    is=self:GetLegionStatus(Legion)==AUFTRAG.Status.REQUESTED
  end
  return is
end

--- Check if mission is SCHEDULED. The first OPSGROUP has been assigned.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is queued.
function AUFTRAG:IsScheduled()
  return self.status==AUFTRAG.Status.SCHEDULED
end

--- Check if mission is STARTED. The first OPSGROUP is on its way to the mission execution waypoint.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is started.
function AUFTRAG:IsStarted()
  return self.status==AUFTRAG.Status.STARTED
end

--- Check if mission is EXECUTING. The first OPSGROUP has reached the mission execution waypoint and is not executing the mission task.
-- @param #AUFTRAG self
-- @param #boolean AllGroups (Optional) Check that all groups are currently executing the mission.
-- @return #boolean If true, mission is currently executing.
function AUFTRAG:IsExecuting(AllGroups)

  local isExecuting=self.status==AUFTRAG.Status.EXECUTING

  if AllGroups and isExecuting then
  
    -- Number of groups executing.
    local n=self:CountOpsGroupsInStatus(AUFTRAG.GroupStatus.EXECUTING)

    local N    
    if self.Nassigned then
      N=self.Nassigned-self.Ndead
    else
      N=self:CountOpsGroups()   
    end
    
    if n==N then
      return true
    else
      return false
    end
         
  end

  return isExecuting
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

--- Check if mission is over. This could be state DONE, CANCELLED, SUCCESS, FAILED.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is over.
function AUFTRAG:IsOver()
  local over = self.status==AUFTRAG.Status.DONE or self.status==AUFTRAG.Status.CANCELLED or self.status==AUFTRAG.Status.SUCCESS or self.status==AUFTRAG.Status.FAILED
  return over
end

--- Check if mission is repeatable.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is repeatable.
function AUFTRAG:IsRepeatable()
  local repeatmeS=self.repeatedSuccess<self.NrepeatSuccess or self.repeated<self.Nrepeat
  local repeatmeF=self.repeatedFailure<self.NrepeatFailure or self.repeated<self.Nrepeat
  if repeatmeS==true or repeatmeF==true then return true else return false end
  return false
end

--- Check if mission is NOT repeatable.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is NOT repeatable.
function AUFTRAG:IsNotRepeatable()
  return not self:IsRepeatable()
end

--- Check if mission is NOT over.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is NOT over yet.
function AUFTRAG:IsNotOver()
  return not self:IsOver()
end

--- Check if mission is for aircarft (airplanes and/or helicopters).
-- @param #AUFTRAG self
-- @return #boolean If `true`, mission is for aircraft.
function AUFTRAG:IsAircraft()
  for _,category in pairs(self.categories) do
    if category==AUFTRAG.Category.AIRCRAFT or category==AUFTRAG.Category.AIRPLANE or category==AUFTRAG.Category.HELICOPTER then
      return true
    end
  end
  return false
end

--- Check if mission is for airplanes.
-- @param #AUFTRAG self
-- @return #boolean If `true`, mission is for airplanes.
function AUFTRAG:IsAirplane()
  for _,category in pairs(self.categories) do
    if category==AUFTRAG.Category.AIRPLANE then
      return true
    end
  end
  return false
end

--- Check if mission is for helicopters.
-- @param #AUFTRAG self
-- @return #boolean If `true`, mission is for helicopters.
function AUFTRAG:IsHelicopters()
  for _,category in pairs(self.categories) do
    if category==AUFTRAG.Category.HELICOPTER then
      return true
    end
  end
  return false
end

--- Check if mission is for ground units.
-- @param #AUFTRAG self
-- @return #boolean If `true`, mission is for ground units.
function AUFTRAG:IsGround()
  for _,category in pairs(self.categories) do
    if category==AUFTRAG.Category.GROUND then
      return true
    end
  end
  return false
end

--- Check if mission is for naval units.
-- @param #AUFTRAG self
-- @return #boolean If `true`, mission is for naval units.
function AUFTRAG:IsNaval()
  for _,category in pairs(self.categories) do
    if category==AUFTRAG.Category.NAVAL then
      return true
    end
  end
  return false
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
  if self.Tstart and Tnow<self.Tstart then
    return false
  end

  -- Stop time already passed.
  if self.Tstop and Tnow>self.Tstop then
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

--- Check if mission is ready to be cancelled.
-- * Mission stop already passed.
-- * Any stop condition is true.
-- @param #AUFTRAG self
-- @return #boolean If true, mission should be cancelled.
function AUFTRAG:IsReadyToCancel()

  local Tnow=timer.getAbsTime()

  -- Stop time already passed.
  if self.Tstop and Tnow>=self.Tstop then
    return true
  end

  -- Evaluate failure condition. One is enough.
  local failure=self:EvalConditionsAny(self.conditionFailure)

  if failure then
    self.failurecondition=true
    return true
  end

  -- Evaluate success consitions. One is enough.
  local success=self:EvalConditionsAny(self.conditionSuccess)

  if success then
    self.successcondition=true
    return true
  end

  -- No criterion matched.
  return false
end

--- Check if mission is ready to be pushed.
-- * Mission push time already passed.
-- * **All** push conditions are true.
-- @param #AUFTRAG self
-- @return #boolean If true, mission groups can push.
function AUFTRAG:IsReadyToPush()

  local Tnow=timer.getAbsTime()

  -- Push time passed?
  if self.Tpush and Tnow<=self.Tpush then
    return false
  end

  -- Evaluate push condition(s) if any. All need to be true.
  local push=self:EvalConditionsAll(self.conditionPush)

  return push
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

  -- Current abs. mission time.
  local Tnow=timer.getAbsTime()

  -- ESCORT: Check if only the group NAME of an escort had been specified.
  if self.escortGroupName then
    -- Try to find the group.
    local group=GROUP:FindByName(self.escortGroupName)
    if group and group:IsAlive() then

      -- Debug info.
      self:T(self.lid..string.format("ESCORT group %s is now alive. Updating DCS task and adding group to TARGET", tostring(self.escortGroupName)))

      -- Add TARGET object.
      self.engageTarget:AddObject(group)

      -- Update DCS task with the known group ID.
      self.DCStask=self:GetDCSMissionTask()

      -- Set value to nil so we do not do this again in the next cycle.
      self.escortGroupName=nil
    end
  end

  -- Number of alive mission targets.
  local Ntargets=self:CountMissionTargets()
  local Ntargets0=self:GetTargetInitialNumber()

  -- Number of alive groups attached to this mission.
  local Ngroups=self:CountOpsGroups()
  
  local Nassigned=self.Nassigned and self.Nassigned-self.Ndead or 0
  
  -- check conditions if set
  local conditionDone=false
  if self.conditionFailureSet then
    conditionDone = self:EvalConditionsAny(self.conditionFailure)
  end  
  if self.conditionSuccessSet and not conditionDone then
    conditionDone = self:EvalConditionsAny(self.conditionSuccess)
  end  

  -- Check if mission is not OVER yet.
  if self:IsNotOver() then

    if self:CheckGroupsDone() then

      -- All groups have reported MISSON DONE.
      self:Done()

    elseif (self.Tstop and Tnow>self.Tstop+10) then

      -- Cancel mission if stop time passed.
      self:Cancel()
      
    elseif conditionDone then
    
      -- Cancel mission if conditions were met.
      self:Cancel()    

    elseif self.durationExe and self.Texecuting and Tnow-self.Texecuting>self.durationExe then

      -- Backup repeat values
      local Nrepeat=self.Nrepeat
      local NrepeatS=self.NrepeatSuccess
      local NrepeatF=self.NrepeatFailure

      -- Cancel mission if stop time passed.
      self:Cancel()

      self.Nrepeat=Nrepeat
      self.NrepeatSuccess=NrepeatS
      self.NrepeatFailure=NrepeatF

    elseif (Ntargets0>0 and Ntargets==0) then

      -- Cancel mission if mission targets are gone (if there were any in the beginning).
      -- TODO: I commented this out for some reason but I forgot why...
      self:T(self.lid.."No targets left cancelling mission!")
      self:Cancel()

    elseif self:IsExecuting() and self:_IsNotReinforcing() then
    
--      env.info("Mission Done:")
--      env.info(string.format("Nreinforce= %d", self.reinforce or 0))      
--      env.info(string.format("Nassigned = %d", self.Nassigned))
--      env.info(string.format("Ndead     = %d", self.Ndead))
--      env.info(string.format("Nass-Ndead= %d", Nassigned))

      -- Had the case that mission was in state Executing but all assigned groups were dead.
      -- TODO: might need to loop over all assigned groups
      if Ngroups==0 then
        self:Done()
      else
        local done=true
        for groupname,data in pairs(self.groupdata or {}) do
          local groupdata=data --#AUFTRAG.GroupData
          local opsgroup=groupdata.opsgroup
          if opsgroup:IsAlive() then
            done=false
          end
        end
        if done then
          self:Done()
        end
      end

    end

  end

  -- Current FSM state.
  local fsmstate=self:GetState()

  -- Check for error.
  if fsmstate~=self.status then
    self:T(self.lid..string.format("ERROR: FSM state %s != %s mission status!", fsmstate, self.status))
  end

  -- General info.
  if self.verbose>=1 then

    -- Mission start stop time.
    local Cstart=UTILS.SecondsToClock(self.Tstart, true)
    local Cstop=self.Tstop and UTILS.SecondsToClock(self.Tstop, true) or "INF"

    local targetname=self:GetTargetName() or "unknown"

    local Nlegions=#self.legions
    local commander=self.commander and self.statusCommander or "N/A"
    local chief=self.chief and self.statusChief or "N/A"

    -- Info message.
    self:T(self.lid..string.format("Status %s: Target=%s, T=%s-%s, assets=%d, groups=%d, targets=%d, legions=%d, commander=%s, chief=%s",
    self.status, targetname, Cstart, Cstop, #self.assets, Ngroups, Ntargets, Nlegions, commander, chief))
  end

  -- Group info.
  if self.verbose>=2 then
    -- Data on assigned groups.
    local text="Group data:"
    for groupname,_groupdata in pairs(self.groupdata) do
      local groupdata=_groupdata --#AUFTRAG.GroupData
      text=text..string.format("\n- %s: status mission=%s opsgroup=%s", groupname, groupdata.status, groupdata.opsgroup and groupdata.opsgroup:GetState() or "N/A")
    end
    self:I(self.lid..text)
  end
  
  -- Group info.
  if self.verbose>=3 then
    -- Data on assigned groups.
    local text=string.format("Assets [N=%d, Nassigned=%s, Ndead=%s]:", self.Nassets or 0, self.Nassigned or 0, self.Ndead or 0)
    for i,_asset in pairs(self.assets or {}) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      text=text..string.format("\n[%d] %s: spawned=%s, requested=%s, reserved=%s", i, asset.spawngroupname, tostring(asset.spawned), tostring(asset.requested), tostring(asset.reserved))
    end
    self:I(self.lid..text)
  end  
    
  -- Ready to evaluate mission outcome?
  local ready2evaluate=self.Tover and Tnow-self.Tover>=self.dTevaluate or false

  -- Check if mission is OVER (done or cancelled) and enough time passed to evaluate the result.
  if self:IsOver() and ready2evaluate then
    -- Evaluate success or failure of the mission.
    self:Evaluate()
  else
    self:__Status(-30)
  end

  -- Update F10 marker.
  if self.markerOn then
    self:UpdateMarker()
  end

end

--- Evaluate mission outcome - success or failure.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:Evaluate()

  -- Assume success and check if any failed condition applies.
  local failed=false

  -- Target damage in %.
  local targetdamage=self:GetTargetDamage()

  -- Own damage in %.
  local owndamage=self.Ncasualties/self.Nelements*100

  -- Current number of mission targets.
  local Ntargets=self:CountMissionTargets(true)
  local Ntargets0=self:GetTargetInitialNumber()

  local Life=self:GetTargetLife()
  local Life0=self:GetTargetInitialLife()


  if Ntargets0>0 then

    ---
    -- Mission had targets
    ---

    -- Check if failed.
    if self.type==AUFTRAG.Type.TROOPTRANSPORT or self.type==AUFTRAG.Type.ESCORT then

      -- Transported or escorted groups have to survive.
      if Ntargets<Ntargets0 then
        failed=true
      end
      
    elseif self.type==AUFTRAG.Type.CARGOTRANSPORT then
    
      -- Get zone and cargo.
      local zone=self.DCStask.params.zone   --Core.Zone#ZONE
      local cargo=self.DCStask.params.cargo --Wrapper.Static#STATIC
      
      --Check that cargo is in drop zone.
      if cargo and zone then
        failed=not cargo:IsInZone(zone)
      else
        failed=true
      end

    elseif self.type==AUFTRAG.Type.RESCUEHELO then

      -- Rescue helo has to survive.
      if self.Nelements==self.Ncasualties then
        failed=true
      end

    else

      -- Still targets left.
      if Ntargets>0 then
        failed=true
      end

    end

  else

    ---
    -- Mission had NO targets
    ---

      -- No targets and everybody died ==> mission failed. Well, unless success condition is true.
      if self.Nelements==self.Ncasualties then
        failed=true
      end

  end


  -- Any success condition true?
  local successCondition=self:EvalConditionsAny(self.conditionSuccess)

  -- Any failure condition true?
  local failureCondition=self:EvalConditionsAny(self.conditionFailure)

  if failureCondition then
    failed=true
  elseif successCondition then
    failed=false
  end

  -- Debug text.
  if self.verbose > 0 then
    local text=string.format("Evaluating mission:\n")
    text=text..string.format("Own casualties = %d/%d\n", self.Ncasualties, self.Nelements)
    text=text..string.format("Own losses     = %.1f %%\n", owndamage)
    text=text..string.format("Killed units   = %d\n", self.Nkills)
    text=text..string.format("--------------------------\n")
    text=text..string.format("Targets left   = %d/%d\n", Ntargets, Ntargets0)
    text=text..string.format("Targets life   = %.1f/%.1f\n", Life, Life0)
    text=text..string.format("Enemy losses   = %.1f %%\n", targetdamage)
    text=text..string.format("--------------------------\n")
    text=text..string.format("Success Cond   = %s\n", tostring(successCondition))
    text=text..string.format("Failure Cond   = %s\n", tostring(failureCondition))
    text=text..string.format("--------------------------\n")
    text=text..string.format("Final Success  = %s\n", tostring(not failed))
    text=text..string.format("=========================")
    self:I(self.lid..text)
  end

  -- Trigger events.
  if failed then
    self:I(self.lid..string.format("Mission %d [%s] failed!", self.auftragsnummer, self.type))
    if self.chief then
      self.chief.Nfailure=self.chief.Nfailure+1
    end
    self:Failed()
  else
    self:I(self.lid..string.format("Mission %d [%s] success!", self.auftragsnummer, self.type))
    if self.chief then
      self.chief.Nsuccess=self.chief.Nsuccess+1
    end
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
-- @return #AUFTRAG self
function AUFTRAG:SetGroupStatus(opsgroup, status)

  -- Current status.
  local oldstatus=self:GetGroupStatus(opsgroup)

  -- Debug info.
  self:T(self.lid..string.format("Setting OPSGROUP %s to status %s-->%s", opsgroup and opsgroup.groupname or "nil", tostring(oldstatus), tostring(status)))

  if oldstatus==AUFTRAG.GroupStatus.CANCELLED and status==AUFTRAG.GroupStatus.DONE then
    -- Do not overwrite a CANCELLED status with a DONE status.
  else
    local groupdata=self:GetGroupData(opsgroup)
    if groupdata then
      groupdata.status=status
    else
      self:T(self.lid.."WARNING: Could not SET flight data for flight group. Setting status to DONE")
    end
  end

  -- Check if mission is NOT over.
  local isNotOver=self:IsNotOver()

  -- Check if all assigned groups are done.
  local groupsDone=self:CheckGroupsDone()

  -- Debug info.
  self:T2(self.lid..string.format("Setting OPSGROUP %s status to %s. IsNotOver=%s  CheckGroupsDone=%s", opsgroup.groupname, self:GetGroupStatus(opsgroup), tostring(self:IsNotOver()), tostring(groupsDone)))

  -- Check if ALL flights are done with their mission.
  if isNotOver and groupsDone then
    self:T3(self.lid.."All assigned OPSGROUPs done ==> mission DONE!")
    self:Done()
  else
    self:T3(self.lid.."Mission NOT DONE yet!")
  end

  return self
end

--- Get ops group mission status.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @return #string The group status.
function AUFTRAG:GetGroupStatus(opsgroup)
  self:T3(self.lid..string.format("Trying to get Flight status for flight group %s", opsgroup and opsgroup.groupname or "nil"))

  local groupdata=self:GetGroupData(opsgroup)

  if groupdata then
    return groupdata.status
  else

    self:T(self.lid..string.format("WARNING: Could not GET groupdata for opsgroup %s. Returning status DONE.", opsgroup and opsgroup.groupname or "nil"))
    return AUFTRAG.GroupStatus.DONE

  end
end

--- Add LEGION to mission.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #AUFTRAG self
function AUFTRAG:AddLegion(Legion)

  -- Debug info.
  self:T(self.lid..string.format("Adding legion %s", Legion.alias))

  -- Add legion to table.
  table.insert(self.legions, Legion)

  return self
end

--- Remove LEGION from mission.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #AUFTRAG self
function AUFTRAG:RemoveLegion(Legion)

  -- Loop over legions
  for i=#self.legions,1,-1 do
    local legion=self.legions[i] --Ops.Legion#LEGION
    
    if legion.alias==Legion.alias then
    
      -- Debug info.
      self:T(self.lid..string.format("Removing legion %s", Legion.alias))
      table.remove(self.legions, i)
      
      -- Set legion status to nil.
      self.statusLegion[Legion.alias]=nil
      
      return self
    end
    
  end

  self:T(self.lid..string.format("ERROR: Legion %s not found and could not be removed!", Legion.alias))
  return self
end

--- Set LEGION mission status.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
-- @param #string Status New status.
-- @return #AUFTRAG self
function AUFTRAG:SetLegionStatus(Legion, Status)

  -- Old status
  local status=self:GetLegionStatus(Legion)

  -- Debug info.
  self:T(self.lid..string.format("Setting LEGION %s to status %s-->%s", Legion.alias, tostring(status), tostring(Status)))

  -- New status.
  self.statusLegion[Legion.alias]=Status

  return self
end

--- Get LEGION mission status.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #string status Current status.
function AUFTRAG:GetLegionStatus(Legion)

  -- New status.
  local status=self.statusLegion[Legion.alias] or "unknown"

  return status
end


--- Set mission (ingress) waypoint coordinate for OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @param Core.Point#COORDINATE coordinate Waypoint Coordinate.
-- @return #AUFTRAG self
function AUFTRAG:SetGroupWaypointCoordinate(opsgroup, coordinate)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointcoordinate=coordinate
  end
  return self
end

--- [Air] Set mission (ingress) waypoint coordinate for FLIGHT group.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE coordinate Waypoint Coordinate.
-- @return #AUFTRAG self
function AUFTRAG:SetIngressCoordinate(coordinate)
  self.missionIngressCoord = coordinate
  self.missionIngressCoordAlt = UTILS.MetersToFeet(coordinate.y) or 10000
  return self
end

--- Get mission (ingress) waypoint coordinate of OPS group
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @return Core.Point#COORDINATE Waypoint Coordinate.
function AUFTRAG:GetGroupWaypointCoordinate(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointcoordinate
  end
end


--- Set mission waypoint task for OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @param Ops.OpsGroup#OPSGROUP.Task task Waypoint task.
function AUFTRAG:SetGroupWaypointTask(opsgroup, task)
  self:T2(self.lid..string.format("Setting waypoint task %s", task and task.description or "WTF"))
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointtask=task
  end
end

--- Get mission waypoint task of OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @return Ops.OpsGroup#OPSGROUP.Task task Waypoint task. Waypoint task.
function AUFTRAG:GetGroupWaypointTask(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointtask
  end
end

--- Set mission (ingress) waypoint UID for OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @param #number waypointindex Waypoint UID.
-- @return #AUFTRAG self
function AUFTRAG:SetGroupWaypointIndex(opsgroup, waypointindex)
  self:T2(self.lid..string.format("Setting Mission waypoint UID=%d", waypointindex))
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointindex=waypointindex
  end
  return self
end

--- Get mission (ingress) waypoint UID of OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @return #number Waypoint UID.
function AUFTRAG:GetGroupWaypointIndex(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointindex
  end
end

--- Set Egress waypoint UID for OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @param #number waypointindex Waypoint UID.
-- @return #AUFTRAG self
function AUFTRAG:SetGroupEgressWaypointUID(opsgroup, waypointindex)
  self:T2(self.lid..string.format("Setting Egress waypoint UID=%d", waypointindex))
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    groupdata.waypointEgressUID=waypointindex
  end
  return self
end

--- Get Egress waypoint UID of OPS group.
-- @param #AUFTRAG self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group.
-- @return #number Waypoint UID.
function AUFTRAG:GetGroupEgressWaypointUID(opsgroup)
  local groupdata=self:GetGroupData(opsgroup)
  if groupdata then
    return groupdata.waypointEgressUID
  end
end

--- Check if all groups are done with their mission (or dead).
-- @param #AUFTRAG self
-- @return #boolean If `true`, all groups are done with the mission.
function AUFTRAG:CheckGroupsDone()

  local fsmState = self:GetState()

  -- Check status of all OPS groups.
  for groupname,data in pairs(self.groupdata) do
    local groupdata=data --#AUFTRAG.GroupData
    if groupdata then
      if not (groupdata.status==AUFTRAG.GroupStatus.DONE or groupdata.status==AUFTRAG.GroupStatus.CANCELLED) then
        -- At least this group is not DONE or CANCELLED.
        self:T2(self.lid..string.format("CheckGroupsDone: OPSGROUP %s is not DONE or CANCELLED but in state %s. Mission NOT DONE!", groupdata.opsgroup.groupname, groupdata.status:upper()))
        return false
      end
    end
  end

  -- Check status of all LEGIONs.
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    local status=self:GetLegionStatus(legion)
    if not status==AUFTRAG.Status.CANCELLED then
      -- At least one LEGION has not CANCELLED.
      self:T2(self.lid..string.format("CheckGroupsDone: LEGION %s is not CANCELLED but in state %s. Mission NOT DONE!", legion.alias, status))
      return false
    end
  end

  -- Check commander status.
  if self.commander then
    if not self.statusCommander==AUFTRAG.Status.CANCELLED then
      self:T2(self.lid..string.format("CheckGroupsDone: COMMANDER is not CANCELLED but in state %s. Mission NOT DONE!", self.statusCommander))
      return false
    end
  end

  -- Check chief status.
  if self.chief then
    if not self.statusChief==AUFTRAG.Status.CANCELLED then
      self:T2(self.lid..string.format("CheckGroupsDone: CHIEF is not CANCELLED but in state %s. Mission NOT DONE!", self.statusChief))
      return false
    end
  end

  -- These are early stages, where we might not even have a opsgroup defined to be checked. If there were any groups, we checked above.
  if self:IsPlanned() or self:IsQueued() or self:IsRequested() then
    self:T2(self.lid..string.format("CheckGroupsDone: Mission is still in state %s [FSM=%s] (PLANNED or QUEUED or REQUESTED). Mission NOT DONE!", self.status, self:GetState()))
    return false
  end
  
  -- Check if there is still reinforcement to be expected.
  if self:IsExecuting() and self:_IsReinforcing() then
    self:T2(self.lid..string.format("CheckGroupsDone: Mission is still in state %s [FSM=%s] and reinfoce=%d. Mission NOT DONE!", self.status, self:GetState(), self.reinforce))
    return false  
  end
  
  local NopsgroupsAlive=self:CountOpsGroups()
  local NopsgroupsDone=self:CountOpsGroupsInStatus(AUFTRAG.GroupStatus.DONE)+self:CountOpsGroupsInStatus(AUFTRAG.GroupStatus.CANCELLED)

  -- It could be that all groups were destroyed on the way to the mission execution waypoint.
  -- TODO: would be better to check if everybody is dead by now.
  if self:IsStarted() and NopsgroupsAlive==0 then
    self:T(self.lid..string.format("CheckGroupsDone: Mission is STARTED state %s [FSM=%s] but count of alive OPSGROUP is zero. Mission DONE!", self.status, self:GetState()))
    return true
  end
  
  -- Every group alive is done or cancelled
  if NopsgroupsAlive==NopsgroupsDone then
    self:T(self.lid..string.format("CheckGroupsDone: Mission is in state %s [FSM=%s] but all groups [=%d] are done or cancelled. Mission DONE!", self.status, self:GetState(), NopsgroupsAlive))
    return true
  end
  
  if (self:IsStarted() or self:IsExecuting()) and (fsmState == AUFTRAG.Status.STARTED or fsmState == AUFTRAG.Status.EXECUTING) and NopsgroupsAlive>0 then
    self:T(self.lid..string.format("CheckGroupsDone: Mission is in state %s [FSM=%s] and count of alive OPSGROUP > zero. Mission NOT DONE!", self.status, self:GetState()))
    return false
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
        self:T(self.lid..string.format("UNIT LOST event for opsgroup %s unit %s", groupdata.opsgroup.groupname, EventData.IniUnitName))
      end
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- On after "Planned" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterPlanned(From, Event, To)
  self.status=AUFTRAG.Status.PLANNED
  self:T(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "Queue" event. Mission is added to the mission queue of a LEGION.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterQueued(From, Event, To, Airwing)
  self.status=AUFTRAG.Status.QUEUED
  self:T(self.lid..string.format("New mission status=%s", self.status))
end


--- On after "Requested" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterRequested(From, Event, To)
  self.status=AUFTRAG.Status.REQUESTED
  self:T(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "Assign" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterAssign(From, Event, To)
  self.status=AUFTRAG.Status.ASSIGNED
  self:T(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "Schedule" event. Mission is added to the mission queue of an OPSGROUP.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterScheduled(From, Event, To)
  self.status=AUFTRAG.Status.SCHEDULED
  self:T(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "Start" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStarted(From, Event, To)
  self.status=AUFTRAG.Status.STARTED
  self.Tstarted=timer.getAbsTime()
  self:T(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "Execute" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterExecuting(From, Event, To)
  self.status=AUFTRAG.Status.EXECUTING
  self.Texecuting=timer.getAbsTime()
  self:T(self.lid..string.format("New mission status=%s", self.status))
end

--- On after "ElementDestroyed" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup The ops group to which the element belongs.
-- @param Ops.OpsGroup#OPSGROUP.Element Element The element that got destroyed.
function AUFTRAG:onafterElementDestroyed(From, Event, To, OpsGroup, Element)
  -- Increase number of own casualties.
  self.Ncasualties=self.Ncasualties+1
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
  
  -- Number of dead groups.
  self.Ndead=self.Ndead+1

end

--- On after "AssetDead" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset.
function AUFTRAG:onafterAssetDead(From, Event, To, Asset)

  -- Number of groups alive.
  local N=self:CountOpsGroups()
  
  local notreinforcing=self:_IsNotReinforcing()

  self:T(self.lid..string.format("Asset %s dead! Number of ops groups remaining %d (reinforcing=%s)", tostring(Asset.spawngroupname), N, tostring(not notreinforcing)))

  -- All assets dead?
  if N==0 and notreinforcing then

    if self:IsNotOver() then

      -- Cancel mission. Wait for next mission update to evaluate SUCCESS or FAILURE.
      self:Cancel()

    else

      --self:E(self.lid.."ERROR: All assets are dead not but mission was already over... Investigate!")
      -- Now this can happen, because when a opsgroup dies (sometimes!), the mission is DONE

    end
  end

  -- Delete asset from mission.
  self:DelAsset(Asset)

end

--- On after "Cancel" event. Cancells the mission.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterCancel(From, Event, To)

  -- Number of OPSGROUPS assigned and alive.
  local Ngroups = self:CountOpsGroups()

  -- Debug info.
  self:T(self.lid..string.format("CANCELLING mission in status %s. Will wait for %d groups to report mission DONE before evaluation", self.status, Ngroups))

  -- Time stamp.
  self.Tover=timer.getAbsTime()

  -- No more repeats.
  self.Nrepeat=self.repeated
  self.NrepeatFailure=self.repeatedFailure
  self.NrepeatSuccess=self.repeatedSuccess

  -- Not necessary to delay the evaluaton?!
  self.dTevaluate=0

  if self.chief then

    -- Debug info.
    self:T(self.lid..string.format("CHIEF will cancel the mission. Will wait for mission DONE before evaluation!"))

    -- CHIEF will cancel the mission.
    self.chief:MissionCancel(self)

  elseif self.commander then

    -- Debug info.
    self:T(self.lid..string.format("COMMANDER will cancel the mission. Will wait for mission DONE before evaluation!"))

    -- COMMANDER will cancel the mission.
    self.commander:MissionCancel(self)

  elseif self.legions and #self.legions>0 then

    -- Loop over all LEGIONs.
    for _,_legion in pairs(self.legions or {}) do
      local legion=_legion --Ops.Legion#LEGION

      -- Debug info.
      self:T(self.lid..string.format("LEGION %s will cancel the mission. Will wait for mission DONE before evaluation!", legion.alias))

      -- Legion will cancel all group's missions and remove queued request from warehouse queue.
      legion:MissionCancel(self)

    end

  else

    -- Debug info.
    self:T(self.lid..string.format("No legion, commander or chief. Attached groups will cancel the mission on their own. Will wait for mission DONE before evaluation!"))

    -- Loop over all groups.
    for _,_groupdata in pairs(self.groupdata or {}) do
      local groupdata=_groupdata --#AUFTRAG.GroupData
      groupdata.opsgroup:MissionCancel(self)
    end

  end

  -- Special mission states.
  if self:IsPlanned() or self:IsQueued() or self:IsRequested() or Ngroups==0 then
    self:T(self.lid..string.format("Cancelled mission was in %s stage with %d groups assigned and alive. Call it done!", self.status, Ngroups))
    self:Done()
  end

end

--- On after "Done" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterDone(From, Event, To)
  self.status=AUFTRAG.Status.DONE
  self:T(self.lid..string.format("New mission status=%s", self.status))

  -- Set time stamp.
  self.Tover=timer.getAbsTime()

  -- Not executing any more.
  self.Texecuting=nil
  
  -- Set status for CHIEF.
  self.statusChief=AUFTRAG.Status.DONE
  
  -- Set status for COMMANDER.
  self.statusCommander=AUFTRAG.Status.DONE
  
  -- Set status for LEGIONs.
  for _,_legion in pairs(self.legions) do
    local Legion=_legion --Ops.Legion#LEGION
    
    self:SetLegionStatus(Legion, AUFTRAG.Status.DONE)
    
    -- Remove pending request from legion queue.
    if self.type==AUFTRAG.Type.RELOCATECOHORT then
    
      -- Get request ID
      local requestid=self.requestID[Legion.alias]
      
      if requestid then
      
        -- Debug info.
        self:T(self.lid.."Removing request from pending queue")
        
        -- Remove request from pending queue.
        Legion:_DeleteQueueItemByID(requestid, Legion.pending)
        
        -- Remove cohort from old legion.
        local Cohort=self.DCStask.params.cohort --Ops.Cohort#COHORT
        Legion:DelCohort(Cohort)
        
      else
        self:E(self.lid.."WARNING: Could NOT remove relocation request from from pending queue (all assets were spawned?)")
      end
    end
  end
  
  -- Trigger relocated event.
  if self.type==AUFTRAG.Type.RELOCATECOHORT then
    local cohort=self.DCStask.params.cohort --Ops.Cohort#COHORT
    cohort:Relocated()
  end
end

--- On after "Success" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterSuccess(From, Event, To)

  self.status=AUFTRAG.Status.SUCCESS
  self:T(self.lid..string.format("New mission status=%s", self.status))

  -- Set status for CHIEF, COMMANDER and LEGIONs
  self.statusChief=self.status
  self.statusCommander=self.status
  for _,_legion in pairs(self.legions) do
    local Legion=_legion --Ops.Legion#LEGION
    self:SetLegionStatus(Legion, self.status)
  end

  local repeatme=self.repeatedSuccess<self.NrepeatSuccess or self.repeated<self.Nrepeat

  if repeatme then

    -- Increase counter.
    self.repeatedSuccess=self.repeatedSuccess+1

    -- Number of repeats.
    local N=math.max(self.NrepeatSuccess, self.Nrepeat)

    -- Repeat mission.
    self:T(self.lid..string.format("Mission SUCCESS! Repeating mission for the %d time (max %d times) ==> Repeat mission!", self.repeated+1, N))
    self:__Repeat(self.repeatDelay)

  else

    -- Stop mission.
    self:T(self.lid..string.format("Mission SUCCESS! Number of max repeats %d reached  ==> Stopping mission!", self.repeated+1))
    self:Stop()

  end

end

--- On after "Failed" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterFailed(From, Event, To)

  self.status=AUFTRAG.Status.FAILED
  self:T(self.lid..string.format("New mission status=%s", self.status))

  -- Set status for CHIEF, COMMANDER and LEGIONs
  self.statusChief=self.status
  self.statusCommander=self.status
  for _,_legion in pairs(self.legions) do
    local Legion=_legion --Ops.Legion#LEGION
    self:SetLegionStatus(Legion, self.status)
  end

  local repeatme=self.repeatedFailure<self.NrepeatFailure or self.repeated<self.Nrepeat

  if repeatme then

    -- Increase counter.
    self.repeatedFailure=self.repeatedFailure+1

    -- Number of repeats.
    local N=math.max(self.NrepeatFailure, self.Nrepeat)

    -- Repeat mission.
    self:T(self.lid..string.format("Mission FAILED! Repeating mission for the %d time (max %d times) ==> Repeat mission!", self.repeated+1, N))
    self:__Repeat(self.repeatDelay)

  else

    -- Stop mission.
    self:T(self.lid..string.format("Mission FAILED! Number of max repeats %d reached ==> Stopping mission!", self.repeated+1))
    self:Stop()

  end

end

--- On before "Repeat" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onbeforeRepeat(From, Event, To)

  if not (self.chief or self.commander or #self.legions>0) then
    self:E(self.lid.."ERROR: Mission can only be repeated by a CHIEF, COMMANDER or LEGION! Stopping AUFTRAG")
    self:Stop()
    return false
  end

  return true
end

--- On after "Repeat" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterRepeat(From, Event, To)

  -- Set mission status to PLANNED.
  self.status=AUFTRAG.Status.PLANNED

  -- Debug info.
  self:T(self.lid..string.format("New mission status=%s (on Repeat)", self.status))

  -- Set status for CHIEF, COMMANDER and LEGIONs
  self.statusChief=self.status
  self.statusCommander=self.status
  for _,_legion in pairs(self.legions) do
    local Legion=_legion --Ops.Legion#LEGION
    self:SetLegionStatus(Legion, self.status)
  end

  -- Increase repeat counter.
  self.repeated=self.repeated+1

  if self.chief then

    -- Set status for chief.
    self.statusChief=AUFTRAG.Status.PLANNED

    -- Remove mission from wingcommander because Chief will assign it again.
    if self.commander then
      self.statusCommander=AUFTRAG.Status.PLANNED
    end

    -- Remove mission from legions because commander will assign it again but maybe to different legion(s).
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      legion:RemoveMission(self)
    end

  elseif self.commander then

    -- Set status for commander.
    self.statusCommander=AUFTRAG.Status.PLANNED

    -- Remove mission from legion(s) because commander will assign it again but maybe to different legion(s).
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      legion:RemoveMission(self)
      self:SetLegionStatus(legion, AUFTRAG.Status.PLANNED)
    end

  elseif #self.legions>0 then

    -- Remove mission from airwing because WC will assign it again but maybe to a different wing.
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      legion:RemoveMission(self)
      self:SetLegionStatus(legion, AUFTRAG.Status.PLANNED)
      legion:AddMission(self)
    end

  else
    self:E(self.lid.."ERROR: Mission can only be repeated by a CHIEF, COMMANDER or LEGION! Stopping AUFTRAG")
    self:Stop()
    return
  end


  -- No mission assets.
  self.assets={}


  -- Remove OPS groups. This also removes the mission from the OPSGROUP mission queue.
  for groupname,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    local opsgroup=groupdata.opsgroup
    if opsgroup then
      self:DelOpsGroup(opsgroup)
    end

  end
  -- No group data.
  self.groupdata={}

  -- Reset casualties and units assigned.
  self.Ncasualties=0
  self.Nelements=0
  self.Ngroups=0
  self.Nassigned=nil
  self.Ndead=0

  -- Update DCS mission task. Could be that the initial task (e.g. for bombing) was destroyed. Then we need to update the coordinate.
  self.DCStask=self:GetDCSMissionTask()

  -- Call status again.
  self:__Status(-30)

end

--- On after "Stop" event. Remove mission from LEGION and OPSGROUP mission queues.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStop(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("STOPPED mission in status=%s. Removing missions from queues. Stopping CallScheduler!", self.status))

  -- TODO: Mission should be OVER! we dont want to remove running missions from any queues.

  -- Remove mission from CHIEF queue.
  if self.chief then
    self.chief:RemoveMission(self)
  end

  -- Remove mission from WINGCOMMANDER queue.
  if self.commander then
    self.commander:RemoveMission(self)
  end

  -- Remove mission from LEGION queues.
  if #self.legions>0 then
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      legion:RemoveMission(self)
    end
  end

  -- Remove mission from OPSGROUP queue
  for _,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    groupdata.opsgroup:RemoveMission(self)
  end

  -- No mission assets.
  self.assets={}

  -- No group data.
  self.groupdata={}

  -- Clear pending scheduler calls.
  self.CallScheduler:Clear()

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Target Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create target data from a given object.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Object The target GROUP, UNIT, STATIC.
function AUFTRAG:_TargetFromObject(Object)

  if not self.engageTarget then

    if Object and Object:IsInstanceOf("TARGET") then

      self.engageTarget=Object

    else --if Object then

      self.engageTarget=TARGET:New(Object)

    end

  else

    -- Target was already specified elsewhere.

  end

  -- Debug info.
  --self:T2(self.lid..string.format("Mission Target %s Type=%s, Ntargets=%d, Lifepoints=%d", self.engageTarget.lid, self.engageTarget.lid, self.engageTarget.N0, self.engageTarget:GetLife()))

  return self
end


--- Count alive mission targets.
-- @param #AUFTRAG self
-- @param #boolean OnlyReallyAlive (Optional) If `true`, count only really alive targets (units, groups) but not coordinates or zones.
-- @return #number Number of alive target units.
function AUFTRAG:CountMissionTargets(OnlyReallyAlive)

  local N=0

  -- Count specific coalitions.  
  local Coalitions=self.coalition and UTILS.GetCoalitionEnemy(self.coalition, true) or nil

  if self.engageTarget then
    N=self.engageTarget:CountTargets(Coalitions, OnlyReallyAlive)
  end

  return N
end

--- Get initial number of targets.
-- @param #AUFTRAG self
-- @return #number Number of initial life points when mission was planned.
function AUFTRAG:GetTargetInitialNumber()
  local target=self:GetTargetData()
  if target then
    return target.N0
  else
    return 0
  end
end


--- Get target life points.
-- @param #AUFTRAG self
-- @return #number Number of initial life points when mission was planned.
function AUFTRAG:GetTargetInitialLife()
  local target=self:GetTargetData()
  if target then
    return target.life0
  else
    return 0
  end
end

--- Get target damage.
-- @param #AUFTRAG self
-- @return #number Damage in percent.
function AUFTRAG:GetTargetDamage()
  local target=self:GetTargetData()
  if target then
    return target:GetDamage()
  else
    return 0
  end
end


--- Get target life points.
-- @param #AUFTRAG self
-- @return #number Life points of target.
function AUFTRAG:GetTargetLife()
  local target=self:GetTargetData()
  if target then
    return target:GetLife()
  else
    return 0
  end
end

--- Get target.
-- @param #AUFTRAG self
-- @return Ops.Target#TARGET The target object. Could be many things.
function AUFTRAG:GetTargetData()
  return self.engageTarget
end

--- Get mission objective object. Could be many things depending on the mission type.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE RefCoordinate (Optional) Reference coordinate from which the closest target is determined.
-- @param #table Coalitions (Optional) Only consider targets of the given coalition(s). 
-- @return Wrapper.Positionable#POSITIONABLE The target object. Could be many things.
function AUFTRAG:GetObjective(RefCoordinate, Coalitions)
  
  local objective=self:GetTargetData():GetObject(RefCoordinate, Coalitions)
  
  return objective
end

--- Get type of target.
-- @param #AUFTRAG self
-- @return #string The target type.
function AUFTRAG:GetTargetType()
  local target=self.engageTarget
  if target then
    local to=target:GetObjective()
    if to then
      return to.Type
    else
      return "Unknown"
    end
  else
    return "Unknown"
  end
end

--- Get 2D vector of target.
-- @param #AUFTRAG self
-- @return DCS#VEC2 The target 2D vector or *nil*.
function AUFTRAG:GetTargetVec2()
  local coord=self:GetTargetCoordinate()
  if coord then
    local vec2=coord:GetVec2()
    return vec2
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
    
  elseif self.missionZoneSet and self.type == AUFTRAG.Type.RECON then
  
    return self.missionZoneSet:GetAverageCoordinate()

  elseif self.engageTarget then

    local coord=self.engageTarget:GetCoordinate()
    return coord

  elseif self.type==AUFTRAG.Type.ALERT5 then

    -- For example, COMMANDER will not assign a coordiante. This will be done later, when the mission is assigned to an airwing.
    return nil

  else
    self:T(self.lid.."ERROR: Cannot get target coordinate!")
  end

  return nil
end

--- Get heading of target.
-- @param #AUFTRAG self
-- @return #number Heading of target in degrees.
function AUFTRAG:GetTargetHeading()
  if self.engageTarget then
    local heading=self.engageTarget:GetHeading()
    return heading
  end
  return nil
end

--- Get name of the target.
-- @param #AUFTRAG self
-- @return #string Name of the target or "N/A".
function AUFTRAG:GetTargetName()

  if self.engageTarget then
    local name=self.engageTarget:GetName()
    return name
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
    self:T(self.lid.."ERROR: TargetCoord or FromCoord does not exist in AUFTRAG:GetTargetDistance() function! Returning 0")
  end

  return 0
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add asset to mission.
-- @param #AUFTRAG self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset to be added to the mission.
-- @return #AUFTRAG self
function AUFTRAG:AddAsset(Asset)

  -- Debug info
  self:T(self.lid..string.format("Adding asset \"%s\" to mission", tostring(Asset.spawngroupname)))

  -- Add to table.
  self.assets=self.assets or {}
  
  -- Get asset if it was already added.
  local asset=self:GetAssetByName(Asset.spawngroupname)
  
  -- Only add an asset is not already in.
  if not asset then
  
    -- Add to table.
    table.insert(self.assets, Asset)
    
    self.Nassigned=self.Nassigned or 0
    
    self.Nassigned=self.Nassigned+1
    
  end

  return self
end

--- Add assets to mission.
-- @param #AUFTRAG self
-- @param #table Assets List of assets.
-- @return #AUFTRAG self
function AUFTRAG:_AddAssets(Assets)

  for _,asset in pairs(Assets) do
    self:AddAsset(asset)
  end

  return self
end

--- Delete asset from mission.
-- @param #AUFTRAG self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset  The asset to be removed.
-- @return #AUFTRAG self
function AUFTRAG:DelAsset(Asset)

  for i,_asset in pairs(self.assets or {}) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

    if asset.uid==Asset.uid then
      self:T(self.lid..string.format("Removing asset \"%s\" from mission", tostring(Asset.spawngroupname)))
      table.remove(self.assets, i)
      return self
    end

  end

  return self
end

--- Get asset by its spawn group name.
-- @param #AUFTRAG self
-- @param #string Name Asset spawn group name.
-- @return Functional.Warehouse#WAREHOUSE.Assetitem Asset.
function AUFTRAG:GetAssetByName(Name)

  for i,_asset in pairs(self.assets or {}) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

    if asset.spawngroupname==Name then
      return asset
    end

  end

  return nil
end

--- Count alive OPS groups assigned for this mission.
-- @param #AUFTRAG self
-- @return #number Number of alive OPS groups.
function AUFTRAG:CountOpsGroups()
  local N=0
  for _,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    if groupdata and groupdata.opsgroup and groupdata.opsgroup:IsAlive() and not groupdata.opsgroup:IsDead() then
      N=N+1
    end
  end
  return N
end

--- Count OPS groups in a certain status.
-- @param #AUFTRAG self
-- @param #string Status Status of group, e.g. `AUFTRAG.GroupStatus.EXECUTING`.
-- @return #number Number of alive OPS groups.
function AUFTRAG:CountOpsGroupsInStatus(Status)
  local N=0
  for _,_groupdata in pairs(self.groupdata) do
    local groupdata=_groupdata --#AUFTRAG.GroupData
    if groupdata and groupdata.status==Status then
      N=N+1
    end
  end
  return N
end



--- Get coordinate of target. First unit/group of the set is used.
-- @param #AUFTRAG self
-- @param #table MissionTypes A table of mission types.
-- @return #string Comma separated list of mission types.
function AUFTRAG:GetMissionTypesText(MissionTypes)

  local text=""
  for _,missiontype in pairs(MissionTypes) do
    text=text..string.format("%s, ", missiontype)
  end

  return text
end

--- [NON-AIR] Set the mission waypoint coordinate from where the mission is executed. Note that altitude is set via `:SetMissionAltitude`.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Coordinate where the mission is executed.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionWaypointCoord(Coordinate)

  -- Obviously a zone was passed. We get the coordinate.
  if Coordinate:IsInstanceOf("ZONE_BASE") then
    Coordinate=Coordinate:GetCoordinate()
  end

  self.missionWaypointCoord=Coordinate
  return self
end

--- Set randomization of the mission waypoint coordinate. Each assigned group will get a random ingress coordinate, where the mission is executed.
-- @param #AUFTRAG self
-- @param #number Radius Distance in meters. Default `#nil`.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionWaypointRandomization(Radius)
  self.missionWaypointRadius=Radius
  return self
end

--- Set the mission egress coordinate. This is the coordinate where the assigned group will go once the mission is finished.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Egrees coordinate.
-- @param #number Altitude (Optional) Altitude in feet. Default is y component of coordinate.
-- @param #number Speed (Optional) Speed in knots to reach this waypoint. Defaults to mission speed.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionEgressCoord(Coordinate, Altitude, Speed)

  -- Obviously a zone was passed. We get the coordinate.
  if Coordinate:IsInstanceOf("ZONE_BASE") then
    Coordinate=Coordinate:GetCoordinate()
  end

  self.missionEgressCoord=Coordinate

  if Altitude then
    self.missionEgressCoord.y=UTILS.FeetToMeters(Altitude)
    self.missionEgressCoordAlt = UTILS.FeetToMeters(Altitude)
  end
  
  self.missionEgressCoordSpeed=Speed and Speed or nil
  
  return self
end

--- [Air] Set the mission ingress coordinate. This is the coordinate where the assigned group will fly before the actual mission coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Ingrees coordinate.
-- @param #number Altitude (Optional) Altitude in feet. Default is y component of coordinate.
-- @param #number Speed (Optional) Speed in knots to reach this waypoint. Defaults to mission speed.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionIngressCoord(Coordinate, Altitude, Speed)

  -- Obviously a zone was passed. We get the coordinate.
  if Coordinate:IsInstanceOf("ZONE_BASE") then
    Coordinate=Coordinate:GetCoordinate()
  end

  self.missionIngressCoord=Coordinate

  if Altitude then
    self.missionIngressCoord.y=UTILS.FeetToMeters(Altitude)
    self.missionIngressCoordAlt = UTILS.FeetToMeters(Altitude or 10000)
  end
  
  self.missionIngressCoordSpeed=Speed and Speed or nil
  
  return self
end

--- [Air] Set the mission holding coordinate. This is the coordinate where the assigned group will fly before the actual mission execution starts. Do not forget to add a push condition, too!
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Holding coordinate.
-- @param #number Altitude (Optional) Altitude in feet. Default is y component of coordinate.
-- @param #number Speed (Optional) Speed in knots to reach this waypoint and hold there. Defaults to mission speed.
-- @param #number Duration (Optional) Duration in seconds on how long to hold, defaults to 15 minutes. Mission continues if either a push condition is met or the time is up.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionHoldingCoord(Coordinate, Altitude, Speed, Duration)

  -- Obviously a zone was passed. We get the coordinate.
  if Coordinate:IsInstanceOf("ZONE_BASE") then
    Coordinate=Coordinate:GetCoordinate()
  end
  
  self.missionHoldingCoord=Coordinate
  self.missionHoldingDuration=Duration or 900

  if Altitude then
    self.missionHoldingCoord.y=UTILS.FeetToMeters(Altitude)
    self.missionHoldingCoordAlt = UTILS.FeetToMeters(Altitude or 10000)
  end
  
  self.missionHoldingCoordSpeed=Speed and Speed or nil

  return self
end

--- Get the mission egress coordinate if this was defined.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Coordinate Coordinate or nil.
function AUFTRAG:GetMissionEgressCoord()
  return self.missionEgressCoord
end

--- Get the mission ingress coordinate if this was defined.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Coordinate Coordinate or nil.
function AUFTRAG:GetMissionIngressCoord()
  return self.missionIngressCoord
end

--- Get the mission holding coordinate if this was defined.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Coordinate Coordinate or nil.
function AUFTRAG:GetMissionHoldingCoord()
  return self.missionHoldingCoord
end

--- Get coordinate which was set as mission waypoint coordinate.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Coordinate where the mission is executed or `#nil`.
function AUFTRAG:_GetMissionWaypointCoordSet()

  -- Check if a coord has been explicitly set.
  if self.missionWaypointCoord then
    local coord=self.missionWaypointCoord
    if self.missionAltitude then
      coord.y=self.missionAltitude
    end
    
    
    return coord
  end

end

--- Get coordinate of target. First unit/group of the set is used.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP group Group.
-- @param #number randomradius Random radius in meters.
-- @param #table surfacetypes Surface types of random zone.
-- @return Core.Point#COORDINATE Coordinate where the mission is executed.
function AUFTRAG:GetMissionWaypointCoord(group, randomradius, surfacetypes)

  -- Check if a coord has been explicitly set.
  if self.missionWaypointCoord then
    local coord=self.missionWaypointCoord
    if self.missionAltitude then
      coord.y=self.missionAltitude
    end
    return coord
  end
  
  local coord=group:GetCoordinate()
  
  -- Check if an ingress or holding coord has been explicitly set.
  if self.missionHoldingCoord then
    coord=self.missionHoldingCoord
    if self.missionHoldingCoorddAlt then
      coord:SetAltitude(self.missionHoldingCoordAlt, true)
    end
  end
  
  if self.missionIngressCoord then
    coord=self.missionIngressCoord
    if self.missionIngressCoordAlt then
      coord:SetAltitude(self.missionIngressCoordAlt, true)
    end
  end

  -- Create waypoint coordinate half way between us and the target.
  local waypointcoord=COORDINATE:New(0,0,0)
  
  if coord then
    waypointcoord=coord:GetIntermediateCoordinate(self:GetTargetCoordinate(), self.missionFraction)
  else
    self:E(self.lid..string.format("ERROR: Cannot get coordinate of group %s (alive=%s)!", tostring(group:GetName()), tostring(group:IsAlive())))
  end
  local alt=waypointcoord.y

  -- Add some randomization.
  if randomradius then
    waypointcoord=ZONE_RADIUS:New("Temp", waypointcoord:GetVec2(), randomradius):GetRandomCoordinate(nil, nil, surfacetypes):SetAltitude(alt, false)
  end

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


--- Get request ID from legion this mission requested assets from
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion from which to get the request ID.
-- @return #number Request ID (if any).
function AUFTRAG:_GetRequestID(Legion)

  local requestid=nil
  local name=nil
  
  if type(Legion)=="string" then
    name=Legion
  else
    name=Legion.alias
  end

  if name then
    requestid=self.requestID[name]
  end  

  return nil
end


--- Get request from legion this mission requested assets from.
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion from which to get the request ID.
-- @return Functional.Warehouse#WAREHOUSE.PendingItem Request.
function AUFTRAG:_GetRequest(Legion)

  local request=nil
  
  local requestID=self:_GetRequestID(Legion)
  
  if requestID then
    request=Legion:GetRequestByID(requestID)
  end

  return request
end

--- Set request ID from legion this mission requested assets from
-- @param #AUFTRAG self
-- @param Ops.Legion#LEGION Legion The legion from which to get the request ID.
-- @param #number RequestID Request ID.
-- @return #AUFTRAG self
function AUFTRAG:_SetRequestID(Legion, RequestID)

  local requestid=nil
  local name=nil
  
  if type(Legion)=="string" then
    name=Legion
  else
    name=Legion.alias
  end

  if name then
    if self.requestID[name] then
      self:I(self.lid..string.format("WARNING: Mission already has a request ID=%d!", self.requestID[name]))
    end
    self.requestID[name]=RequestID
  end  

  return self
end

--- Check if reinforcement is done.
-- @param #AUFTRAG self
-- @return #boolean If `true`, reinforcing is over.
function AUFTRAG:_IsNotReinforcing()

  -- Number of assigned assets that are still alive.
  local Nassigned=self.Nassigned and self.Nassigned-self.Ndead or 0
  
  -- Not reinforcing?
  local notreinforcing=((not self.reinforce) or (self.reinforce==0 and Nassigned<=0))
  
  return notreinforcing
end

--- Check if reinforcement is still ongoing.
-- @param #AUFTRAG self
-- @return #boolean If `true`, reinforcing is ongoing.
function AUFTRAG:_IsReinforcing()

  local reinforcing=not self:_IsNotReinforcing()
  
  return reinforcing
end



--- Update mission F10 map marker.
-- @param #AUFTRAG self
-- @return #AUFTRAG self
function AUFTRAG:UpdateMarker()

  -- Marker text.
  local text=string.format("%s %s: %s", self.name, self.type:upper(), self.status:upper())
  text=text..string.format("\n%s", self:GetTargetName())
  text=text..string.format("\nTargets %d/%d, Life Points=%d/%d", self:CountMissionTargets(), self:GetTargetInitialNumber(), self:GetTargetLife(), self:GetTargetInitialLife())
  text=text..string.format("\nOpsGroups %d/%d", self:CountOpsGroups(), self:GetNumberOfRequiredAssets())

  if not self.marker then

    -- Get target coordinates. Can be nil!
    local targetcoord=self:GetTargetCoordinate()

    if targetcoord then
        if self.markerCoaliton and self.markerCoaliton>=0 then
        self.marker=MARKER:New(targetcoord, text):ReadOnly():ToCoalition(self.markerCoaliton)
        else
        self.marker=MARKER:New(targetcoord, text):ReadOnly():ToAll()
        end
    end

  else

    if self.marker:GetText()~=text then
      self.marker:UpdateText(text)
    end

  end

  return self
end

--- Get DCS task table for the given mission.
-- @param #AUFTRAG self
-- @return DCS#Task The DCS task table. If multiple tasks are necessary, this is returned as a combo task.
function AUFTRAG:GetDCSMissionTask()

  local DCStasks={}

  -- Create DCS task based on current self.
  if self.type==AUFTRAG.Type.ANTISHIP then

    ----------------------
    -- ANTISHIP Mission --
    ----------------------

    -- Add enroute anti-ship task.
    local DCStask=CONTROLLABLE.EnRouteTaskAntiShip(nil)
    table.insert(self.enrouteTasks, DCStask)

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

    local coords = self.engageTarget:GetCoordinates()
    for _, coord in pairs(coords) do
        local DCStask = CONTROLLABLE.TaskBombing(nil, coord:GetVec2(), self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, self.optionDivebomb)

        table.insert(DCStasks, DCStask)
    end

  elseif self.type==AUFTRAG.Type.STRAFING then

    ----------------------
    -- STRAFING Mission --
    ----------------------

    local DCStask=CONTROLLABLE.TaskStrafing(nil,self:GetTargetVec2(), self.engageQuantity, self.engageLength,self.engageWeaponType,self.engageWeaponExpend,self.engageDirection,self.engageAsGroup)

    table.insert(DCStasks, DCStask)    

  elseif self.type==AUFTRAG.Type.BOMBRUNWAY then

    ------------------------
    -- BOMBRUNWAY Mission --
    ------------------------

    local DCStask=CONTROLLABLE.TaskBombingRunway(nil, self.engageTarget:GetObject(), self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAsGroup)

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.BOMBCARPET then

    ------------------------
    -- BOMBCARPET Mission --
    ------------------------

    local DCStask=CONTROLLABLE.TaskCarpetBombing(nil, self:GetTargetVec2(), self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, self.engageLength)

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.CAP then

    -----------------
    -- CAP Mission --
    -----------------
    
    local Vec2 = self.engageZone:GetVec2()
    local Radius
    if self.engageZone:IsInstanceOf("COORDINATE") then
      Radius = UTILS.NMToMeters(20)
    else
      Radius = self.engageZone:GetRadius()
    end
        
    local DCStask=CONTROLLABLE.EnRouteTaskEngageTargetsInZone(nil, Vec2, Radius, self.engageTargetTypes, Priority)

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

    local DCStask=CONTROLLABLE.TaskEscort(nil, self.engageTarget:GetObject(), self.escortVec3, nil, self.engageMaxDistance, self.engageTargetTypes)

    table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.GROUNDESCORT then

    --------------------
    -- GROUNDESCORT Mission --
    --------------------

    local DCSTask=CONTROLLABLE.TaskGroundEscort(nil,self.engageTarget:GetObject(),nil,self.orbitDistance,self.engageTargetTypes)
    
    table.insert(DCStasks, DCSTask)
    
  elseif self.type==AUFTRAG.Type.FACA then

    ------------------
    -- AFAC Mission --
    ------------------

    local DCStask=CONTROLLABLE.TaskFAC_AttackGroup(nil, self.engageTarget:GetObject(), self.engageWeaponType, self.facDesignation, self.facDatalink, self.facFreq, self.facModu, CallsignName, CallsignNumber)

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.FAC then

    -----------------
    -- FAC Mission --
    -----------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.PATROLZONE

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()
    param.altitude=self.missionAltitude
    param.speed=self.missionSpeed and UTILS.KmphToMps(self.missionSpeed) or nil

    DCStask.params=param

    table.insert(DCStasks, DCStask)

    -- Enroute task FAC
    local DCSenroute=CONTROLLABLE.EnRouteTaskFAC(self, self.facFreq, self.facModu)
    table.insert(self.enrouteTasks, DCSenroute)

  elseif self.type==AUFTRAG.Type.FERRY then

    -------------------
    -- FERRY Mission --
    -------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.FERRY

    -- We create a "fake" DCS task.
    local param={}
    DCStask.params=param

    table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.RELOCATECOHORT then

    ----------------------
    -- RELOCATE Mission --
    ----------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.RELOCATECOHORT

    -- We create a "fake" DCS task.
    local param={}
    DCStask.params=param

    table.insert(DCStasks, DCStask)
     
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

  elseif self.type==AUFTRAG.Type.GCICAP then

    --------------------
    -- GCICAP Mission --
    --------------------

    -- Done below as also other mission types use the orbit task.

  elseif self.type==AUFTRAG.Type.RECON then

    -------------------
    -- RECON Mission --
    -------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.RECON

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.target=self.engageTarget
    param.altitude=self.missionAltitude
    param.speed=self.missionSpeed and UTILS.KmphToMps(self.missionSpeed) or nil
    param.lastindex=nil

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.SEAD then

    ------------------
    -- SEAD Mission --
    ------------------

    -- Add enroute task SEAD. Disabled that here because the group enganges everything on its route.
    --local DCStask=CONTROLLABLE.EnRouteTaskSEAD(nil, self.TargetType)
    --table.insert(self.enrouteTasks, DCStask)
    
    if self.engageZone then
    
      --local DCStask=CONTROLLABLE.EnRouteTaskSEAD(nil, self.engageTargetTypes)
      --table.insert(self.enrouteTasks, DCStask)
      self.engageZone:Scan({Object.Category.UNIT},{Unit.Category.GROUND_UNIT})
      local ScanUnitSet = self.engageZone:GetScannedSetUnit()
      local SeadUnitSet = SET_UNIT:New()
      for _,_unit in pairs (ScanUnitSet.Set) do
        local unit = _unit -- Wrapper.Unit#UNTI
        if unit and unit:IsAlive() and unit:HasSEAD() then
          self:T("Adding UNIT for SEAD: "..unit:GetName())
          local task = CONTROLLABLE.TaskAttackUnit(nil,unit,GroupAttack,AI.Task.WeaponExpend.ALL,1,Direction,self.engageAltitude,2956984318)
          table.insert(DCStasks, task)
          SeadUnitSet:AddUnit(unit)
        end
      end
      self.engageTarget = TARGET:New(SeadUnitSet)
      --local OrbitTask = CONTROLLABLE.TaskOrbitCircle(nil,self.engageAltitude,self.missionSpeed,self.engageZone:GetCoordinate())
      --local Point = self.engageZone:GetVec2()
      --local OrbitTask = CONTROLLABLE.TaskOrbitCircleAtVec2(nil,Point,self.engageAltitude,self.missionSpeed)
      --table.insert(DCStasks, OrbitTask)
     
    else
    
      self:_GetDCSAttackTask(self.engageTarget, DCStasks)
    
    end
    
  elseif self.type==AUFTRAG.Type.STRIKE then

    --------------------
    -- STRIKE Mission --
    --------------------

    local coords = self.engageTarget:GetCoordinates()
    for _, coord in pairs(coords) do
        local DCStask=CONTROLLABLE.TaskAttackMapObject(nil, coord:GetVec2(), self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)

        table.insert(DCStasks, DCStask)
    end

  elseif self.type==AUFTRAG.Type.TANKER or self.type==AUFTRAG.Type.RECOVERYTANKER then

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

  elseif self.type==AUFTRAG.Type.OPSTRANSPORT then

    --------------------------
    -- OPSTRANSPORT Mission --
    --------------------------

    local DCStask={}

    DCStask.id="OpsTransport"

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.CARGOTRANSPORT then

    ----------------------------
    -- CARGOTRANSPORT Mission --
    ----------------------------

    -- Task to transport cargo.
    local TaskCargoTransportation={
      id = "CargoTransportation",
      params = {}
    }
    
    table.insert(DCStasks, TaskCargoTransportation)

  elseif self.type==AUFTRAG.Type.RESCUEHELO then

    -------------------------
    -- RESCUE HELO Mission --
    -------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.FORMATION

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
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

    
    if self.artyShots==1 or self.artyRadius<10 or true then
    
      local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, self:GetTargetVec2(), self.artyRadius, self.artyShots, self.engageWeaponType, self.artyAltitude)
      table.insert(DCStasks, DCStask)
    
    else
    
      local Vec2=self:GetTargetVec2()
      
      local zone=ZONE_RADIUS:New("temp", Vec2, self.artyRadius)
      
      for i=1,self.artyShots do
      
        local vec2=zone:GetRandomVec2()

        local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, vec2, 0, 1, self.engageWeaponType, self.artyAltitude)
        table.insert(DCStasks, DCStask)
  
      end
    
    end

  elseif self.type==AUFTRAG.Type.BARRAGE then

    ---------------------
    -- BARRAGE Mission --
    ---------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.BARRAGE

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()
    param.altitude=self.artyAltitude
    param.radius=self.artyRadius
    param.heading=self.artyHeading
    param.angle=self.artyAngle
    param.shots=self.artyShots
    param.weaponTypoe=self.engageWeaponType

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.PATROLZONE then

    -------------------------
    -- PATROL ZONE Mission --
    -------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.PATROLZONE

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()
    param.altitude=self.missionAltitude
    param.speed=self.missionSpeed and UTILS.KmphToMps(self.missionSpeed) or nil

    DCStask.params=param

    table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.CAPTUREZONE then

    --------------------------
    -- CAPTURE ZONE Mission --
    --------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.CAPTUREZONE

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    DCStask.params=param

    table.insert(DCStasks, DCStask)    

  elseif self.type==AUFTRAG.Type.CASENHANCED then

    -------------------------
    -- CAS ENHANCED Mission --
    -------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.PATROLZONE

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()
    param.altitude=self.missionAltitude
    param.speed=self.missionSpeed and UTILS.KmphToMps(self.missionSpeed) or nil

    DCStask.params=param

    table.insert(DCStasks, DCStask)

   elseif self.type==AUFTRAG.Type.GROUNDATTACK then

    ---------------------------
    -- GROUND ATTACK Mission --
    ---------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.GROUNDATTACK

    -- We create a "fake" DCS task and pass the parameters to the ARMYGROUP.
    local param={}
    param.target=self:GetTargetData()
    param.action="Wedge"
    param.speed=self.missionSpeed and UTILS.KmphToMps(self.missionSpeed) or nil

    DCStask.params=param

    table.insert(DCStasks, DCStask)

   elseif self.type==AUFTRAG.Type.NAVALENGAGEMENT then

    ---------------------------
    -- NAVAL ENGAGEMENT Mission --
    ---------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.NAVALENGAGEMENT

    -- We create a "fake" DCS task and pass the parameters to the NAVYGROUP.
    local param={}
    param.target=self:GetTargetData()
    param.speed=self.missionSpeed and UTILS.KmphToMps(self.missionSpeed) or nil
    param.altitude=self.missionAltitude or 0

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.AMMOSUPPLY then

    -------------------------
    -- AMMO SUPPLY Mission --
    -------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.AMMOSUPPLY

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.FUELSUPPLY then

    -------------------------
    -- FUEL SUPPLY Mission --
    -------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.FUELSUPPLY

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.REARMING then

    ----------------------
    -- REARMING Mission --
    ----------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.REARMING

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.ALERT5 then

    ---------------------
    -- ALERT 5 Mission --
    ---------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.ALERT5

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}

    DCStask.params=param

    table.insert(DCStasks, DCStask)
 
   elseif self.type==AUFTRAG.Type.NOTHING then

    ---------------------
    -- NOTHING Mission --
    ---------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.NOTHING

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}

    DCStask.params=param

    table.insert(DCStasks, DCStask)
       
  elseif self.type==AUFTRAG.Type.PATROLRACETRACK then

    ---------------------
    -- Enhanced Orbit Racetrack --
    ---------------------

    local DCStask={}
    DCStask.id=AUFTRAG.SpecialTask.PATROLRACETRACK

    local param={}
    -- ONTROLLABLE:PatrolRaceTrack(Point1, Point2, Altitude, Speed, Formation, Delay)
    
    param.TrackAltitude = self.TrackAltitude
    param.TrackSpeed = self.TrackSpeed
    param.TrackPoint1 = self.TrackPoint1
    param.TrackPoint2 = self.TrackPoint2
    param.missionSpeed = self.missionSpeed
    param.missionAltitude = self.missionAltitude
    param.TrackFormation = self.TrackFormation

    DCStask.params=param

    table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.HOVER then

    ---------------------
    -- HOVER Mission --
    ---------------------

    local DCStask={}
    DCStask.id=AUFTRAG.SpecialTask.HOVER

    local param={}

    param.hoverAltitude=self.hoverAltitude
    param.hoverTime = self.hoverTime
    param.missionSpeed = self.missionSpeed
    param.missionAltitude = self.missionAltitude

    DCStask.params=param
  
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.LANDATCOORDINATE then

    ---------------------
    -- LANDATCOORDINATE Mission
    ---------------------

    local DCStask={}
    local Vec2 = self.stayAt:GetVec2()  
    local DCStask = CONTROLLABLE.TaskLandAtVec2(nil,Vec2,self.stayTime, self.combatLand, self.directionAfter)
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.ONGUARD or self.type==AUFTRAG.Type.ARMOREDGUARD then

    ----------------------
    -- ON GUARD Mission --
    ----------------------

    local DCStask={}

    DCStask.id= self.type==AUFTRAG.Type.ONGUARD and AUFTRAG.SpecialTask.ONGUARD or AUFTRAG.SpecialTask.ARMOREDGUARD

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.coordinate=self:GetObjective()

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.AIRDEFENSE then

    ------------------------
    -- AIRDEFENSE Mission --
    ------------------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.AIRDEFENSE

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()

    DCStask.params=param

    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.EWR then

    -----------------
    -- EWR Mission --
    -----------------

    local DCStask={}

    DCStask.id=AUFTRAG.SpecialTask.EWR

    -- We create a "fake" DCS task and pass the parameters to the OPSGROUP.
    local param={}
    param.zone=self:GetObjective()

    DCStask.params=param

    table.insert(DCStasks, DCStask)

    -- EWR is an enroute task
    local Enroutetask=CONTROLLABLE.EnRouteTaskEWR()
    table.insert(self.enrouteTasks, Enroutetask)

  else
    self:T(self.lid..string.format("ERROR: Unknown mission task!"))
    return nil
  end


  -- Set ORBIT task. Also applies to other missions: AWACS, TANKER, CAP, CAS.
  if self.type==AUFTRAG.Type.ORBIT  or
     self.type==AUFTRAG.Type.CAP    or
     self.type==AUFTRAG.Type.CAS    or
     self.type==AUFTRAG.Type.GCICAP or
     self.type==AUFTRAG.Type.AWACS  or
     self.type==AUFTRAG.Type.TANKER or
     self.type==AUFTRAG.Type.RECOVERYTANKER then

    -------------------
    -- ORBIT Mission --
    -------------------

    -- Get/update orbit vector.
    self.orbitVec2=self:GetTargetVec2()
    
    if self.orbitVec2 then
    
      -- Heading of the target.
      self.targetHeading=self:GetTargetHeading()

      local OffsetVec2=nil --DCS#Vec2
      if (self.orbitOffsetVec2~=nil) then
        OffsetVec2=UTILS.DeepCopy(self.orbitOffsetVec2)
      end
      
      if OffsetVec2 then
        
        if self.orbitOffsetVec2.r then
          -- Polar coordinates
          local r=self.orbitOffsetVec2.r
          local phi=(self.orbitOffsetVec2.phi or 0) + self.targetHeading
          
          OffsetVec2.x=r*math.cos(math.rad(phi))
          OffsetVec2.y=r*math.sin(math.rad(phi))
        else
          -- Cartesian coordinates
          OffsetVec2.x=self.orbitOffsetVec2.x
          OffsetVec2.y=self.orbitOffsetVec2.y
        end
        
      end
      
      -- Actual orbit position with possible offset.
      local orbitVec2=OffsetVec2 and UTILS.Vec2Add(self.orbitVec2, OffsetVec2) or self.orbitVec2      
      
      -- Check for race-track pattern.
      local orbitRaceTrack=nil --DCS#Vec2
      if self.orbitLeg then
      
        -- Default heading is due North. 
        local heading=0
        
        -- Check if specific heading was specified.
        if self.orbitHeading then
        
          -- Is heading realtive to target?
          if self.orbitHeadingRel then
            -- Relative heading wrt target.
            heading=self.targetHeading+self.orbitHeading
          else
            -- Take given heading.
            heading=self.orbitHeading
          end
          
        else
          -- Not specific heading specified ==> Take heading of target.
          heading=self.targetHeading or 0        
        end
                
        -- Race-track vector.
        orbitRaceTrack=UTILS.Vec2Translate(orbitVec2, self.orbitLeg, heading)
      end      
              
      local orbitRaceTrackCoord = nil    
      if orbitRaceTrack then
        orbitRaceTrackCoord = COORDINATE:NewFromVec2(orbitRaceTrack)
      end
      
      -- Create orbit task.
      local DCStask=CONTROLLABLE.TaskOrbit(nil, COORDINATE:NewFromVec2(orbitVec2), self.orbitAltitude, self.orbitSpeed, orbitRaceTrackCoord)
            
      -- Add DCS task.
      table.insert(DCStasks, DCStask)
      
    end

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
-- @param Ops.Target#TARGET Target Target data.
-- @param #table DCStasks DCS DCS tasks table to which the task is added.
-- @return DCS#Task The DCS task table.
function AUFTRAG:_GetDCSAttackTask(Target, DCStasks)

  DCStasks=DCStasks or {}

  for _,_target in pairs(Target.targets) do
    local target=_target --Ops.Target#TARGET.Object

    if target.Type==TARGET.ObjectType.GROUP then

      local DCStask=CONTROLLABLE.TaskAttackGroup(nil, target.Object, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageAsGroup)

      table.insert(DCStasks, DCStask)

    elseif target.Type==TARGET.ObjectType.UNIT or target.Type==TARGET.ObjectType.STATIC then

      local DCStask=CONTROLLABLE.TaskAttackUnit(nil, target.Object, self.engageAsGroup, self.WeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)

      table.insert(DCStasks, DCStask)

    end

  end

  return DCStasks
end

--- Get DCS task table for an attack group or unit task.
-- @param #AUFTRAG self
-- @param #string MissionType Mission (AUFTAG) type.
-- @return #string DCS mission task for the auftrag type.
function AUFTRAG:GetMissionTaskforMissionType(MissionType)

  local mtask=ENUMS.MissionTask.NOTHING

  if MissionType==AUFTRAG.Type.ANTISHIP then
    mtask=ENUMS.MissionTask.ANTISHIPSTRIKE
  elseif MissionType==AUFTRAG.Type.AWACS then
    mtask=ENUMS.MissionTask.AWACS
  elseif MissionType==AUFTRAG.Type.BAI then
    mtask=ENUMS.MissionTask.GROUNDATTACK
  elseif MissionType==AUFTRAG.Type.BOMBCARPET then
    mtask=ENUMS.MissionTask.GROUNDATTACK
  elseif MissionType==AUFTRAG.Type.BOMBING then
    mtask=ENUMS.MissionTask.GROUNDATTACK
  elseif MissionType==AUFTRAG.Type.BOMBRUNWAY then
    mtask=ENUMS.MissionTask.RUNWAYATTACK
  elseif MissionType==AUFTRAG.Type.CAP then
    mtask=ENUMS.MissionTask.CAP
  elseif MissionType==AUFTRAG.Type.GCICAP then
    mtask=ENUMS.MissionTask.CAP
  elseif MissionType==AUFTRAG.Type.CAS then
    mtask=ENUMS.MissionTask.CAS
  elseif MissionType==AUFTRAG.Type.PATROLZONE then
    mtask=ENUMS.MissionTask.CAS
  elseif MissionType==AUFTRAG.Type.CASENHANCED then
    mtask=ENUMS.MissionTask.CAS
  elseif MissionType==AUFTRAG.Type.ESCORT then
    mtask=ENUMS.MissionTask.ESCORT
  elseif MissionType==AUFTRAG.Type.FACA then
    mtask=ENUMS.MissionTask.AFAC
  elseif MissionType==AUFTRAG.Type.FAC then
    mtask=ENUMS.MissionTask.AFAC    
  elseif MissionType==AUFTRAG.Type.FERRY then
    mtask=ENUMS.MissionTask.NOTHING
  elseif MissionType==AUFTRAG.Type.GROUNDESCORT then
    mtask=ENUMS.MissionTask.GROUNDESCORT
  elseif MissionType==AUFTRAG.Type.INTERCEPT then
    mtask=ENUMS.MissionTask.INTERCEPT
  elseif MissionType==AUFTRAG.Type.RECON then
    mtask=ENUMS.MissionTask.RECONNAISSANCE
  elseif MissionType==AUFTRAG.Type.SEAD then
    mtask=ENUMS.MissionTask.SEAD
  elseif MissionType==AUFTRAG.Type.STRIKE then
    mtask=ENUMS.MissionTask.GROUNDATTACK
  elseif MissionType==AUFTRAG.Type.TANKER then
    mtask=ENUMS.MissionTask.REFUELING
  elseif MissionType==AUFTRAG.Type.TROOPTRANSPORT then
    mtask=ENUMS.MissionTask.TRANSPORT
  elseif MissionType==AUFTRAG.Type.CARGOTRANSPORT then
    mtask=ENUMS.MissionTask.TRANSPORT
  elseif MissionType==AUFTRAG.Type.ARMORATTACK then
    mtask=ENUMS.MissionTask.NOTHING
  elseif MissionType==AUFTRAG.Type.HOVER then
    mtask=ENUMS.MissionTask.NOTHING
  elseif MissionType==AUFTRAG.Type.PATROLRACETRACK then
    mtask=ENUMS.MissionTask.CAP
  end

  return mtask
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Checks if a mission type is contained in a table of possible types.
-- @param #string MissionType The requested mission type.
-- @param #table PossibleTypes A table with possible mission types.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AUFTRAG.CheckMissionType(MissionType, PossibleTypes)

  if type(PossibleTypes)=="string" then
    PossibleTypes={PossibleTypes}
  end

  for _,canmission in pairs(PossibleTypes) do
    if canmission==MissionType then
      return true
    end
  end

  return false
end

--- Check if a mission type is contained in a list of possible capabilities.
-- @param #table MissionTypes The requested mission type. Can also be passed as a single mission type `#string`.
-- @param #table Capabilities A table with possible capabilities `Ops.Auftrag#AUFTRAG.Capability`.
-- @param #boolean All If `true`, given mission type must be includedin ALL capabilities. If `false` or `nil`, it must only match one.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AUFTRAG.CheckMissionCapability(MissionTypes, Capabilities, All)

  -- Ensure table.
  if type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end

  for _,cap in pairs(Capabilities) do
    local capability=cap --Ops.Auftrag#AUFTRAG.Capability
    for _,MissionType in pairs(MissionTypes) do
      if All==true then
        if capability.MissionType~=MissionType then
          return false
        end
      else
        if capability.MissionType==MissionType then
          return true
        end
      end
    end
  end

  if All==true then
    return true
  else
    return false
  end
end


--- Check if a mission type is contained in a list of possible capabilities.
-- @param #table MissionTypes The requested mission type. Can also be passed as a single mission type `#string`.
-- @param #table Capabilities A table with possible capabilities `Ops.Auftrag#AUFTRAG.Capability`.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AUFTRAG.CheckMissionCapabilityAny(MissionTypes, Capabilities)

  local res=AUFTRAG.CheckMissionCapability(MissionTypes, Capabilities, false)

  return res
end


--- Check if a mission type is contained in a list of possible capabilities.
-- @param #table MissionTypes The requested mission type. Can also be passed as a single mission type `#string`.
-- @param #table Capabilities A table with possible capabilities `Ops.Auftrag#AUFTRAG.Capability`.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AUFTRAG.CheckMissionCapabilityAll(MissionTypes, Capabilities)

  local res=AUFTRAG.CheckMissionCapability(MissionTypes, Capabilities, true)

  return res
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
