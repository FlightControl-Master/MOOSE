--- **Ops** - Auftrag (mission) for Air to Air and Air to Surface Ops.
--
-- **Main Features:**
--
--    * Simplifies setting DCS tasks.
--    * Handy events.
--    * Set mission start/stop times.
--    * Set mission priority and urgency (can cancel running missions).
--    * Specific mission options for ROE, ROT, formation, etc.
--    * Interface to FLIGHTGROUP, AIRWING and WINGCOMMANDER classes.
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
-- @field #table flightdata Flight specific data.
-- @field #string name Mission name.
-- @field #number prio Mission priority.
-- @field #boolean urgent Mission is urgent. Running missions with lower prio might be cancelled.
-- @field #number Tstart Mission start time in seconds.
-- @field #number Tstop Mission stop time in seconds.
-- @field #number duration Mission duration in seconds.
-- @field #number markerID F10 map marker ID.
-- @field #table DCStask DCS task structure.
-- @field #number Ntargets Number of mission targets.
-- @field #number dTevaluate Time interval in seconds before the mission result is evaluated after mission is over.
-- @field #number Tover Mission abs. time stamp, when mission was over. 
-- 
-- @field Core.Point#COORDINATE orbitCoord Coordinate where to orbit.
-- @field #number orbitSpeed Orbit speed in m/s.
-- @field #number orbitHeading Orbit heading in degrees.
-- @field #number orbitLeg Length of orbit leg in meters.
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
-- @field #number refuelSystem For refuel type for TANKER missions.
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
-- 
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander The WINGCOMMANDER managing this mission.
-- @field Ops.AirWing#AIRWING airwing The assigned airwing.
-- @field #string squadname Name of the assigned Airwing squadron.
-- @field #table assets Airwing Assets assigned for this mission.
-- @field #number nassets Number of required assets by the Airwing.
-- @field #number requestID The ID of the queued warehouse request. Necessary to cancel the request if the mission was cancelled before the request is processed.
-- @field #boolean cancelContactLost If true, cancel mission if the contact is lost.
-- 
-- @field #string missionTask Mission task. See `ENUMS.MissionTask`.
-- @field #number missionAltitude Mission altitude in meters.
-- @field #number missionFraction Mission coordiante fraction. Default is 0.5.
-- @field #table enrouteTasks Mission enroute tasks.
-- @field #number missionRange Mission range in meters. Used in AIRWING class.
-- @field #number missionFreq Mission radio frequency in MHz.
-- @field #number missionModu Mission radio modulation. 0=AM and 1=FM.
-- @field #number missionTACANchannel Mission TACAN channel.
-- @field #number missionTACANmorse Mission TACAN morse code.
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
-- Also, a lot of additional useful events are created.
--
-- # Mission Types
-- 
-- ## Anti-Ship
-- 
-- ## AWACS
-- 
-- ## Tanker
-- 
-- ## BAI
-- 
-- ## Bombing
-- 
-- ## Bombing Runway
-- 
-- ## Bombing Carpet
-- 
-- ## CAP
-- 
-- ## CAS
-- 
-- ## Escort
-- 
-- ## FACA
-- 
-- ## Ferry
-- 
-- ## Intercept
-- 
-- ##
-- 
-- 
-- # Events
-- 
-- 
-- # Examples
-- 
-- 
--  
--
--
-- @field #AUFTRAG
AUFTRAG = {
  ClassName          = "AUFTRAG",
  Debug              = false,
  lid                =   nil,
  auftragsnummer     =   nil,
  flightdata         =    {},
  assets             =    {},
  missionFraction    =   0.5,
  enrouteTasks       =    {},
  markerID           =   nil,
  startconditions    =    {},
  stopconditions     =    {},
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
-- @field #string RECOVERYTANKER Recovery tanker mission.
-- @field #string RESCUEHELO Rescue helo.
-- @field #string SEAD Suppression/destruction of enemy air defences.
-- @field #string STRIKE Strike mission.
-- @field #string TANKER Tanker mission.
-- @field #string TRANSPORT Transport mission.
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
  TRANSPORT="Transport",
}

--- Mission status.
-- @type AUFTRAG.Status
-- @field #string PLANNED Mission is at the early planning stage.
-- @field #string QUEUED Mission is queued at an airwing.
-- @field #string REQUESTED Mission assets were requested from the warehouse.
-- @field #string ASSIGNED Mission was assigned to somebody.
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
  ASSIGNED="assigned",
  SCHEDULED="scheduled",
  STARTED="started",
  EXECUTING="executing",
  DONE="done",
  CANCELLED="cancelled",
  SUCCESS="success",
  FAILED="failed",
}

--- Flight status.
-- @type AUFTRAG.FlightStatus
-- @field #string SCHEDULED Mission is scheduled in a FLIGHGROUP queue waiting to be started.
-- @field #string STARTED Flightgroup started this mission but it is not executed yet.
-- @field #string EXECUTING Flightgroup is executing this mission.
-- @field #string PAUSED Flightgroup has paused this mission, e.g. for refuelling.
-- @field #string DONE Mission task of the flightgroup is done.
-- @field #string CANCELLED Mission was cancelled.
AUFTRAG.FlightStatus={
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
AUFTRAG.TargetType={
  GROUP="Group",
  UNIT="Unit",
  STATIC="Static",
  COORDINATE="Coordinate",
  AIRBASE="Airbase",
}

--- Target data.
-- @type AUFTRAG.TargetData
-- @field Wrapper.Positionable#POSITIONABLE Target Target Object.
-- @field #string Type Target type: "Group", "Unit", "Static", "Coordinate", "Airbase.
-- @field #number Ninital Number of initial targets.
-- @field #number Lifepoints Total life points.

--- Mission capability.
-- @type AUFTRAG.Capability
-- @field #string MissionType Type of mission.
-- @field #number Performance Number describing the performance level. The higher the better.

--- Mission success.
-- @type AUFTRAG.Success
-- @field #string ENGAGED Target was engaged.
-- @field #string DAMAGED Target was damaged.
-- @field #string DESTROYED Target was destroyed.

--- Flight specific data. Each flight subscribed to this mission has different data for this.
-- @type AUFTRAG.FlightData
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @field Core.Point#COORDINATE waypointcoordinate Waypoint coordinate.
-- @field #number waypointindex Waypoint index.
-- @field Ops.FlightGroup#FLIGHTGROUP.Task waypointtask Waypoint task.
-- @field #string status Flight mission status.
-- @field Ops.AirWing#AIRWING.SquadronAsset asset The squadron asset.


--- AUFTRAG class version.
-- @field #string version
AUFTRAG.version="0.0.9"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add mission start conditions.
-- TODO: Add recovery tanker mission for boat ops.
-- TODO: Add rescue helo mission for boat ops.
-- TODO: Mission success options damaged, destroyed.
-- DONE: Mission ROE and ROT.
-- TODO: Mission frequency, formation, etc.
-- DONE: FSM events.
-- TODO: F10 marker functions that are updated on Status event.
-- TODO: F10 marker to create new missions.
-- DONE: Evaluate mission result ==> SUCCESS/FAILURE
-- DONE: NewAUTO() NewA2G NewA2A
-- TODO: Transport mission.
-- TODO: Recon mission.
-- TODO: Set mission coalition, e.g. for F10 markers.

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
  self:AddTransition(AUFTRAG.Status.REQUESTED, "Scheduled",     AUFTRAG.Status.SCHEDULED)   -- Mission added to the first flight group queue.
  
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

  self:AddTransition("*",                      "FlightDead",    "*")  
  self:AddTransition("*",                      "AssetDead",     "*")
  
  
  -- Init status update.
  self:__Status(-1)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Missions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a RESCUE HELO mission.
-- @param #AUFTRAG self
-- @param Wrapper.Unit#UNIT Carrier The carrier unit.
-- @return #AUFTRAG self
function AUFTRAG:NewRESCUEHELO(Carrier)

  local mission=AUFTRAG:New(AUFTRAG.Type.RESCUEHELO)
  
  mission.engageTarget=mission:_TargetFromObject(Carrier)
  
  --[[
  mission.engageTarget=mission:_TargetFromObject(Target)
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  
  mission.missionTask=ENUMS.MissionTask.NOTHING
  mission.missionFraction=0.4
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  ]]
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create an ANTI-SHIP mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be passed as a @{Wrapper.Group#GROUP} or @{Wrapper.Unit#UNIT} object.
-- @return #AUFTRAG self
function AUFTRAG:NewANTISHIP(Target)

  local mission=AUFTRAG:New(AUFTRAG.Type.ANTISHIP)
  
  mission.engageTarget=mission:_TargetFromObject(Target)
  mission.engageWeaponType=ENUMS.WeaponFlag.Auto
  
  mission.missionTask=ENUMS.MissionTask.ANTISHIPSTRIKE
  mission.missionFraction=0.4
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create an ORBIT mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit.
-- @param #number Speed Orbit speed in knots. Default 350 KIAS. 
-- @param #number Heading Heading of race-track pattern in degrees. Default *random* in [1,360].
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param #number Altitude Orbit altitude in feet. Default is y component of `Coordinate`.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT(Coordinate, Speed, Heading, Leg, Altitude)

  local auftrag=AUFTRAG:New(AUFTRAG.Type.ORBIT)
  
  auftrag.orbitCoord   = Coordinate
  auftrag.orbitHeading = Heading or math.random(360)
  auftrag.orbitLeg     = UTILS.NMToMeters(Leg or 10)
  auftrag.orbitSpeed   = UTILS.KnotsToMps(Speed or 350)
  
  if Altitude then
    auftrag.orbitCoord.y=UTILS.FeetToMeters(Altitude)
  end  
  
  auftrag.missionAltitude=auftrag.orbitCoord.y*0.9  
  auftrag.missionFraction=0.9  
  auftrag.optionROE=ENUMS.ROE.ReturnFire
  auftrag.optionROT=ENUMS.ROT.PassiveDefense

  auftrag.DCStask=auftrag:GetDCSMissionTask()

  return auftrag
end

--- Create a PATROL mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE OrbitCoordinate Where to orbit. Altitude is also taken from the coordinate. 
-- @param #number OrbitSpeed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param #number Altitude Orbit altitude in feet.
-- @return #AUFTRAG self
function AUFTRAG:NewPATROL(OrbitCoordinate, OrbitSpeed, Heading, Leg, Altitude)

  -- Create ORBIT first.
  local mission=self:NewORBIT(OrbitCoordinate, OrbitSpeed, Heading, Leg, Altitude)
    
  -- Mission type PATROL.
  mission.type=AUFTRAG.Type.PATROL
  
  mission:_SetLogID()
  
  mission.missionTask=ENUMS.MissionTask.INTERCEPT
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  return mission
end

--- Create a TANKER mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE OrbitCoordinate Where to orbit. Altitude is also taken from the coordinate. 
-- @param #number OrbitSpeed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param #number Altitude Orbit altitude in feet.
-- @param #number RefuelSystem Refueling system.
-- @return #AUFTRAG self
function AUFTRAG:NewTANKER(OrbitCoordinate, OrbitSpeed, Heading, Leg, Altitude, RefuelSystem)

  -- Create ORBIT first.
  local mission=self:NewORBIT(OrbitCoordinate, OrbitSpeed, Heading, Leg, Altitude)
    
  -- Mission type PATROL.
  mission.type=AUFTRAG.Type.TANKER
  
  mission:_SetLogID()
  
  mission.refuelSystem=RefuelSystem
  
  mission.missionTask=ENUMS.MissionTask.REFUELING 
  mission.optionROE=ENUMS.ROE.WeaponHold
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a AWACS mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE OrbitCoordinate Where to orbit. Altitude is also taken from the coordinate. 
-- @param #number OrbitSpeed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param #number Altitude Orbit altitude in feet.
-- @return #AUFTRAG self
function AUFTRAG:NewAWACS(OrbitCoordinate, OrbitSpeed, Heading, Leg, Altitude)

  -- Create ORBIT first.
  local mission=self:NewORBIT(OrbitCoordinate, OrbitSpeed, Heading, Leg, Altitude)
    
  -- Mission type PATROL.
  mission.type=AUFTRAG.Type.AWACS
  
  mission:_SetLogID()
  
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
    
  mission.engageTarget=mission:_TargetFromObject(Target)
  
  mission.missionTask=ENUMS.MissionTask.INTERCEPT    
  mission.missionFraction=0.1  
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a CAP mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE OrbitCoordinate Where to orbit. Altitude is also taken from the coordinate. 
-- @param #number OrbitSpeed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param Core.Zone#ZONE_RADIUS ZoneCAP Circular CAP zone. Detected targets in this zone will be engaged.
-- @param #table TargetTypes Table of target types. Default {"Air"}.
-- @return #AUFTRAG self
function AUFTRAG:NewCAP(OrbitCoordinate, OrbitSpeed, Heading, Leg, ZoneCAP, TargetTypes)

  -- Ensure given TargetTypes parameter is a table.
  if TargetTypes then
    if type(TargetTypes)~="table" then
      TargetTypes={TargetTypes}
    end
  end

  -- Create ORBIT first.
  local mission=self:NewORBIT(OrbitCoordinate, OrbitSpeed, Heading, Leg)
  
  -- CAP paramters.
  mission.type=AUFTRAG.Type.CAP
  mission.engageZone=ZoneCAP or ZONE_RADIUS:New("CAP Zone", OrbitCoordinate:GetVec2(), mission.orbitLeg)
  mission.engageTargetTypes=TargetTypes or {"Air"}
  
  mission:_SetLogID()

  mission.missionTask=ENUMS.MissionTask.CAP    
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.EvadeFire
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a CAS mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE OrbitCoordinate Where to orbit. Altitude is also taken from the coordinate. 
-- @param #number OrbitSpeed Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @param Core.Zone#ZONE_RADIUS ZoneCAS Circular CAS zone. Detected targets in this zone will be engaged.
-- @param #table TargetTypes Table of target types. Default {"Helicopters", "Ground Units", "Light armed ships"}.
-- @return #AUFTRAG self
function AUFTRAG:NewCAS(OrbitCoordinate, OrbitSpeed, Heading, Leg, ZoneCAS, TargetTypes)

  -- Ensure given TargetTypes parameter is a table.
  if TargetTypes then
    if type(TargetTypes)~="table" then
      TargetTypes={TargetTypes}
    end
  end

  -- Create ORBIT first.
  local mission=self:NewORBIT(OrbitCoordinate, OrbitSpeed, Heading, Leg)

  -- CAS paramters.
  mission.type=AUFTRAG.Type.CAS
  
  mission.engageZone=ZoneCAS or ZONE_RADIUS:New("CAS Zone", OrbitCoordinate:GetVec2(), Leg)
  mission.engageTargetTypes=TargetTypes or {"Helicopters", "Ground Units", "Light armed ships"}
  
  mission:_SetLogID()
  
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

  mission.engageTarget=mission:_TargetFromObject(Target)
  
  -- TODO: check that target is really a group object!
  
  mission.facDesignation=Designation
  mission.facDatalink=true
  mission.facFreq=Frequency or 133
  mission.facModu=Modulation or radio.modulation.AM
  
  mission.missionTask=ENUMS.MissionTask.AFAC
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense

  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end


--- Create a BAI mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP, UNIT or STATIC object.
-- @return #AUFTRAG self
function AUFTRAG:NewBAI(Target)
  
  local mission=AUFTRAG:New(AUFTRAG.Type.BAI)

  mission.engageTarget=mission:_TargetFromObject(Target)
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyAG
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAsGroup=true
  
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=nil
  mission.missionFraction=0.75
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()  
  
  return mission
end

--- Create a SEAD mission.
-- @param #AUFTRAG self
-- @param Wrapper.Positionable#POSITIONABLE Target The target to attack. Can be a GROUP or UNIT object.
-- @return #AUFTRAG self
function AUFTRAG:NewSEAD(Target)
  
  local mission=AUFTRAG:New(AUFTRAG.Type.SEAD)

  mission.engageTarget=mission:_TargetFromObject(Target)
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyAG
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL
  mission.engageAsGroup=true
  
  mission.missionTask=ENUMS.MissionTask.SEAD
  mission.missionAltitude=nil
  mission.missionFraction=0.4
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.AllowAbortMission
  
  mission.DCStask=mission:GetDCSMissionTask()  
  
  return mission
end

--- Create a STRIKE mission. Flight will attack the closest map object to the specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Target The target coordinate. Can also be given as a GROUP, UNIT or STATIC object.
-- @param #number Altitude Engage altitude in feet. Default 1000 ft.
-- @return #AUFTRAG self
function AUFTRAG:NewSTRIKE(Target, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.STRIKE)
  
  mission.engageTarget=mission:_TargetFromObject(Target)
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 1000)
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyAG
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL  
  
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
  
  -- DCS task options:
  mission.engageTarget=mission:_TargetFromObject(Target)
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyBomb
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL

  -- Mission options:
  mission.missionTask=ENUMS.MissionTask.GROUNDATTACK
  mission.missionAltitude=mission.engageAltitude*0.8  
  mission.missionFraction=0.5
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
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
  
  -- DCS task options:
  mission.engageTarget=mission:_TargetFromObject(Airdrome)
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 25000)
  mission.engageWeaponType=ENUMS.WeaponFlag.AnyBomb
  mission.engageWeaponExpend=AI.Task.WeaponExpend.ALL

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


--- Create an ESCORT (or FOLLOW) mission. Flight will escort another group and automatically engage certain target types.
-- @param #AUFTRAG self
-- @param Wrapper.Group#GROUP EscortGroup The group to escort.
-- @param DCS#Vec3 OffsetVector A table with x, y and z components specifying the offset of the flight to the escorted group. Default {x=200, y=0, z=-100} for 200 meters to the right, same alitude, 100 meters behind.
-- @param #number EngageMaxDistance Max engage distance of targets in meters. Default auto (*nil*).
-- @param #table TargetTypes Types of targets to engage automatically. Default is {"Air"}, i.e. all enemy airborne units. Use an empty set {} for a simple "FOLLOW" mission.
-- @return #AUFTRAG self
function AUFTRAG:NewESCORT(EscortGroup, OffsetVector, EngageMaxDistance, TargetTypes)

  local mission=AUFTRAG:New(AUFTRAG.Type.ESCORT)
  
  mission.escortGroup=EscortGroup
  mission.escortVec3=OffsetVector or {x=200, y=0, z=-100}
  mission.engageMaxDistance=EngageMaxDistance
  mission.engageTargetTypes=TargetTypes or {"Air"}
  
  mission.missionTask=ENUMS.MissionTask.ESCORT  
  mission.missionFraction=0.1
  
  -- TODO: what's the best ROE here? Make dependent on ESCORT or FOLLOW!
  mission.optionROE=ENUMS.ROE.OpenFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create an TRANSPORT mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_GROUP TransportGroupSet The set group(s) to be transported.
-- @param Core.Point#COORDINATE PickupCoordinate Coordinate where the helo will land to pick up the the cargo. Default is the fist transport group.
-- @return #AUFTRAG self
function AUFTRAG:NewTRANSPORT(TransportGroupSet, PickupCoordinate)

  local mission=AUFTRAG:New(AUFTRAG.Type.TRANSPORT)
  
  if TransportGroupSet:IsInstanceOf("GROUP") then
    mission.transportGroupSet=SET_GROUP:New()
    mission.transportGroupSet:AddGroup(TransportGroupSet)
  elseif TransportGroupSet:IsInstanceOf("SET_GROUP") then
    mission.transportGroupSet=TransportGroupSet
  else
    env.info("FF error in TRANSPORT auftrag")
  end
  
  mission.transportPickup=PickupCoordinate or mission.transportGroupSet:GetFirst():GetCoordinate()
  
  mission.transportPickup:MarkToAll("Pickup")

  -- TODO: what's the best ROE here? Make dependent on ESCORT or FOLLOW!
  mission.optionROE=ENUMS.ROE.ReturnFire
  mission.optionROT=ENUMS.ROT.PassiveDefense
  
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
-- @param #string Name Name of the mission.
-- @return #AUFTRAG self
function AUFTRAG:SetName(Name)
  self.name=Name or string.format("Auftragsnummer %d", self.auftragsnummer)
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

--- Set number of weapons to expend.
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

--- Set mission altitude.
-- @param #AUFTRAG self
-- @param #string Altitude Altitude in feet.
-- @return #AUFTRAG self
function AUFTRAG:SetMissionAltitude(Altitude)
  self.missionAltitude=UTILS.FeetToMeters(Altitude)
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


--- Add a flight group to the mission.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FLIGHTGROUP object.
function AUFTRAG:AddFlightGroup(FlightGroup)
  self:I(self.lid..string.format("Adding flight group %s", FlightGroup.groupname))

  local flightdata={} --#AUFTRAG.FlightData
  flightdata.flightgroup=FlightGroup
  flightdata.status=AUFTRAG.FlightStatus.SCHEDULED
  flightdata.waypointcoordinate=nil
  flightdata.waypointindex=nil
  flightdata.waypointtask=nil

  self.flightdata[FlightGroup.groupname]=flightdata

end

--- Remove a flight group to the mission.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FLIGHTGROUP object.
function AUFTRAG:DelFlightGroup(FlightGroup)
  self:I(self.lid..string.format("Removing flight group %s", FlightGroup and FlightGroup.groupname or "nil (ERROR)!"))

  if FlightGroup then
    
    -- Remove mission form flightgroup queue.
    FlightGroup:RemoveMission(self)
  
    self.flightdata[FlightGroup.groupname]=nil
    
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Status" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.AirWing#AIRWING Airwing The airwing.
function AUFTRAG:onafterStatus(From, Event, To)

  -- Number of alive mission targets.
  local Ntargets=self:CountMissionTargets()
  
  -- Number of alive flights attached to this mission.
  local Nflights=self:CountFlightGroups()

  -- Check if mission is not OVER yet.
  if self:IsNotOver() then

    if self:CheckFlightsDone() then
    
      -- All flights have reported MISSON DONE.
      self:Done()
      
    elseif self.Tstop and timer.getAbsTime()>self.Tstop+10 then
    
      -- Cancel mission if stop time passed.
      self:Cancel()
      
    elseif self.Ntargets>0 and Ntargets==0 then
    
      -- Cancel mission if all targets were destroyed.
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
  self:I(self.lid..string.format("Status %s: Target=%s, T=%s-%s, assets=%d, flights=%d, targets=%d, wing=%s, commander=%s", self.status, targetname, Cstart, Cstop, #self.assets, Nflights, Ntargets, airwing, commander))

  -- Check for error.  
  if fsmstate~=self.status then
    self:E(self.lid..string.format("ERROR: FSM state %s != %s mission status!", fsmstate, self.status))
  end
  
  if #self.flightdata>0 then
    local text="Flight data:"
    for groupname,_flightdata in pairs(self.flightdata) do
      local flightdata=_flightdata --#AUFTRAG.FlightData
      text=text..string.format("\n- %s: status mission=%s flightgroup=%s", groupname, flightdata.status, flightdata.flightgroup and flightdata.flightgroup:GetState() or "N/A")
    end
    self:I(self.lid..text)
  end

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

  -- Current number of mission targets.
  local Ntargets=self:CountMissionTargets()
  
  -- Number of current targets is still >0 ==> Not everything was destroyed.
  if self.Ntargets>0 and Ntargets>0 then
    failed=true
  end
  
  --TODO: all assets dead? Is this a FAILED criterion even if all targets have been destroyed? What if there are no initial targets (e.g. when ORBIT, PATROL, RECON missions).
  
  self:I(self.lid..string.format("Evaluating mission: Initial Targets=%d, current targets=%d ==> success=%s", self.Ntargets, Ntargets, tostring(not failed)))
  
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

--- Get asset data table.
-- @param #AUFTRAG self
-- @param #string AssetName Name of the asset.
-- @return #AUFTRAG.FlightData Flight data or nil if flightgroup does not exist.
function AUFTRAG:GetAssetDataByName(AssetName)
  return self.flightdata[tostring(AssetName)]
end

--- Get asset data table.
-- @param #AUFTRAG self
-- @param #string AssetName Name of the asset.
-- @return #AUFTRAG.FlightData Flight data or nil if flightgroup does not exist.
function AUFTRAG:NewMissionAsset(AssetName)

  local assetdata={} --#AUFTRAG.FlightData
  
  --assetdata.status==AUFTRAG.FlightStatus.SCHEDULED

  return self.flightdata[tostring(AssetName)]
end


--- Get flight data table.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @return #AUFTRAG.FlightData Flight data or nil if flightgroup does not exist.
function AUFTRAG:GetFlightData(flightgroup)
  if flightgroup and self.flightdata then
    return self.flightdata[flightgroup.groupname]
  end
  return nil
end

--- Set flightgroup mission status.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @param #string status New status.
function AUFTRAG:SetFlightStatus(flightgroup, status)
  self:I(self.lid..string.format("Setting flight %s to status %s", flightgroup and flightgroup.groupname or "nil", tostring(status)))

  --env.info("FF trying to get flight status in AUFTRAG:GetFlightStatus")
  if self:GetFlightStatus(flightgroup)==AUFTRAG.FlightStatus.CANCELLED and status==AUFTRAG.FlightStatus.DONE then
    -- Do not overwrite a CANCELLED status with a DONE status.
  else
    local flightdata=self:GetFlightData(flightgroup)
    if flightdata then
      flightdata.status=status
    else
      self:E(self.lid.."WARNING: Could not SET flight data for flight group. Setting status to DONE")
    end
  end
  
  -- Debug info.
  self:I(self.lid..string.format("Setting flight %s status to %s. IsNotOver=%s  CheckFlightsDone=%s", flightgroup.groupname, self:GetFlightStatus(flightgroup), tostring(self:IsNotOver()), tostring(self:CheckFlightsDone())))

  -- Check if ALL flights are done with their mission.
  if self:IsNotOver() and self:CheckFlightsDone() then
    self:I(self.lid.."All flights done ==> mission DONE!")
    self:Done()
  else
    self:T3(self.lid.."Mission NOT DONE yet!")
  end  
  
end

--- Get flightgroup mission status.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
function AUFTRAG:GetFlightStatus(flightgroup)
  self:T3(self.lid..string.format("Trying to get Flight status for flight group %s", flightgroup and flightgroup.groupname or "nil"))
  
  local flightdata=self:GetFlightData(flightgroup)
  
  if flightdata then
    return flightdata.status
  else
  
    self:E(self.lid..string.format("WARNING: Could not GET flightdata for flightgroup %s. Returning status DONE.", flightgroup and flightgroup.groupname or "nil"))
    return AUFTRAG.FlightStatus.DONE
    
  end
end


--- Set flightgroup waypoint coordinate.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @param Core.Point#COORDINATE coordinate Waypoint Coordinate.
function AUFTRAG:SetFlightWaypointCoordinate(flightgroup, coordinate)
  local flightdata=self:GetFlightData(flightgroup)
  if flightdata then
    flightdata.waypointcoordinate=coordinate
  end
end

--- Get flightgroup waypoint coordinate.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Waypoint Coordinate.
function AUFTRAG:GetFlightWaypointCoordinate(flightgroup)
  local flightdata=self:GetFlightData(flightgroup)
  if flightdata then
    return flightdata.waypointcoordinate
  end
end


--- Set flightgroup waypoint task.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @param Ops.FlightGroup#FLIGHTGROUP.Task task Waypoint task.
function AUFTRAG:SetFlightWaypointTask(flightgroup, task)
  self:I(self.lid..string.format("Setting waypoint task %s", task and task.description or "WTF"))
  local flightdata=self:GetFlightData(flightgroup)
  if flightdata then
    flightdata.waypointtask=task
  end
end

--- Get flightgroup waypoint task.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @return Ops.FlightGroup#FLIGHTGROUP.Task task Waypoint task. Waypoint task.
function AUFTRAG:GetFlightWaypointTask(flightgroup)
  local flightdata=self:GetFlightData(flightgroup)
  if flightdata then
    return flightdata.waypointtask
  end
end


--- Check if all flights are done with their mission (or dead).
-- @param #AUFTRAG self
-- @return #boolean If true, all flights are done with the mission.
function AUFTRAG:CheckFlightsDone()

  -- These are early stages, where we might not even have a flightgroup defined to be checked.
  if self:IsPlanned() or self:IsQueued() or self:IsRequested() then 
    return false
  end
  
  
  -- Check status of all flight groups.
  for groupname,data in pairs(self.flightdata) do
    local flightdata=data --#AUFTRAG.FlightData
    if flightdata then
      if flightdata.status==AUFTRAG.FlightStatus.DONE or flightdata.status==AUFTRAG.FlightStatus.CANCELLED then
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

--- Flightgroup event function handling the crash of a unit.
-- @param #AUFTRAG self
-- @param Core.Event#EVENTDATA EventData Event data.
function AUFTRAG:OnEventCrash(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName
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
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup
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


--- On after "FlightDead" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The flightgroup that is dead now.
function AUFTRAG:onafterFlightDead(From, Event, To, FlightGroup)

  --self:SetFlightStatus(FlightGroup, AUFTRAG.FlightStatus.DONE)

  local asset=self:GetAssetByName(FlightGroup.groupname)
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
    
  -- Remove flightgroup from mission.
  --self:DelFlightGroup(Asset.flightgroup)
  
  local N=self:CountFlightGroups()
  
  -- All assets dead?
  if N==0 then
  
    if self:IsNotOver() then
    
      -- Cancel mission. Wait for next mission update to evaluate SUCCESS or FAILURE.
      self:Cancel()
      
    else
      
      self:E(self.lid.."ERROR: All assets are dead not but mission was already over... Investigate!")
      -- Now this can happen, because when a flightgroup dies (sometimes!), the mission is DONE
      
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
  self:I(self.lid..string.format("CANCELLING mission in status %s. Will wait for flights to report mission DONE before evaluation.", self.status))
  
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
  
    for _,_flightdata in pairs(self.flightdata) do
      local flightdata=_flightdata --#AUFTRAG.FlightData
      flightdata.flightgroup:MissionCancel(self)
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
  
  for _,_flightdata in pairs(self.flightdata) do
    local flightdata=_flightdata --#AUFTRAG.FlightData
    local flightgroup=flightdata.flightgroup
    if flightgroup then
      self:DelFlightGroup(flightgroup)
    end
    
  end  
  -- No flight data.
  self.flightdata={}
  
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

  for _,_flightdata in pairs(self.flightdata) do
    local flightdata=_flightdata --#AUFTRAG.FlightData
    flightdata.flightgroup:RemoveMission(self)
  end

  -- No mission assets.
  self.assets={}
  
  -- No flight data.
  self.flightdata={}

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
-- @return #number Number of alive target units.
function AUFTRAG:CountMissionTargets()
  
  local N=0
  
  if self.engageTarget then
  
    if self.engageTarget.Type==AUFTRAG.TargetType.GROUP then
    
      local target=self.engageTarget.Target --Wrapper.Group#GROUP
      
      local units=target:GetUnits()
      
      for _,_unit in pairs(units or {}) do
        local unit=_unit --Wrapper.Unit#UNIT
        
        -- We check that unit is "alive" and has health >1. Somtimes units get heavily damanged but are still alive.
        -- TODO: here I could introduce and count that if units have only health < 50% if mission objective is to just "damage" the units.
        if unit and unit:IsAlive() and unit:GetLife()>1 then
          N=N+1
        end
      end      
      
    elseif self.engageTarget.Type==AUFTRAG.TargetType.UNIT then
    
      local target=self.engageTarget.Target --Wrapper.Unit#UNIT        
      
      if target and target:IsAlive() and target:GetLife()>1 then
        N=N+1
      end
      
    elseif self.engageTarget.Type==AUFTRAG.TargetType.STATIC then
    
      local target=self.engageTarget.Target --Wrapper.Static#STATIC
      
      if target and target:IsAlive() then
        N=N+1
      end
      
    elseif self.engageTarget.Type==AUFTRAG.TargetType.AIRBASE then
    
      -- TODO: any (good) way to tell whether an airbase was "destroyed" or at least damaged? Is :GetLive() working?
      
    end
  end
  
  return N
end

--- Get target life points.
-- @param #AUFTRAG self
-- @return #number Number of alive target units.
function AUFTRAG:GetTargetLife()
  
  local N=0
  
  if self.engageTarget then
  
    if self.engageTarget.Type==AUFTRAG.TargetType.GROUP then
    
      local target=self.engageTarget.Target --Wrapper.Group#GROUP
      
      local units=target:GetUnits()
      
      for _,_unit in pairs(units or {}) do
        local unit=_unit --Wrapper.Unit#UNIT
        
        -- We check that unit is "alive".
        if unit and unit:IsAlive() then
          N=N+unit:GetLife()
        end
      end      
      
    elseif self.engageTarget.Type==AUFTRAG.TargetType.UNIT then
    
      local target=self.engageTarget.Target --Wrapper.Unit#UNIT        
      
      if target and target:IsAlive() then
        N=N+target:GetLife()
      end
      
    elseif self.engageTarget.Type==AUFTRAG.TargetType.STATIC then
    
      local target=self.engageTarget.Target --Wrapper.Static#STATIC
      
      if target and target:IsAlive() then
        N=N+1 --target:GetLife()
      end
      
    elseif self.engageTarget.Type==AUFTRAG.TargetType.AIRBASE then
    
      -- TODO: any (good) way to tell whether an airbase was "destroyed" or at least damaged? Is :GetLive() working?
      
    end
  end
  
  return N
end

--- Count alive flight groups assigned for this mission.
-- @param #AUFTRAG self
-- @return #number Number of alive flight groups.
function AUFTRAG:CountFlightGroups()
  local N=0
  for _,_flightdata in pairs(self.flightdata) do
    local flightdata=_flightdata --#AUFTRAG.FlightData
    if flightdata and flightdata.flightgroup and flightdata.flightgroup:IsAlive() then
      N=N+1
    end
  end
  return N
end

--- Get coordinate of target.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE The target coordinate or nil.
function AUFTRAG:GetTargetCoordinate()

  if self.engageTarget then
    if self.engageTarget.Type==AUFTRAG.TargetType.COORDINATE then
      return self.engageTarget.Target
    else
      return self.engageTarget.Target:GetCoordinate()
    end
  elseif self.orbitCoord then
    return self.orbitCoord
  elseif self.escortGroup then
    return self.escortGroup:GetCoordinate()
  elseif self.transportPi1ckup then
    return self.transportPickup
  end  

  return nil
end

--- Get coordinate of target.
-- @param #AUFTRAG self
-- @return #string
function AUFTRAG:GetTargetName()

  if self.engageTarget then
    if self.engageTarget.Type==AUFTRAG.TargetType.COORDINATE then
      local coord=self.engageTarget.Target --Core.Point#COORDINATE
      return coord:ToStringMGRS()
      --return coord:ToStringLLDMS()
    else
      return self.engageTarget.Target:GetName()
    end
  elseif self.orbitCoord then
    return self.orbitCoord:ToStringLLDMS()
  elseif self.escortGroup then
    return self.escortGroup:GetName()
  elseif self.transportPickup then
    return self.transportPickup:ToStringLLDMS()
  end  

  return nil
end


--- Get distance to target.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE FromCoord The coordinate from which the distance is measured.
-- @return #number Distance in meters.
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
  local text=string.format("%s %s", self.name, self.status:upper())
  text=text..string.format("\nTargets=%d", self:CountMissionTargets())
  text=text..string.format("\nFlights=%d", self:CountFlightGroups())

  -- Remove old marker.
  if self.markerID then
    COORDINATE.RemoveMark(nil, self.markerID)
  end
  
  -- Get target coordinates. Can be nil!
  local targetcoord=self:GetTargetCoordinate()
  
  -- New marker!
  if targetcoord then
    self.markerID=targetcoord:MarkToAll(text, true)
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

    local DCStask=self:_GetDCSAttackTask(self.engageTarget)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.AWACS then
  
    -------------------
    -- AWACS Mission --
    -------------------  

    local DCStask=CONTROLLABLE.EnRouteTaskAWACS(nil)
    
    table.insert(self.enrouteTasks, DCStask)
    --table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.BAI then
  
    -----------------
    -- BAI Mission --
    -----------------  

    local DCStask=self:_GetDCSAttackTask(self.engageTarget)
    
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.BOMBING then
  
    ---------------------
    -- BOMBING Mission --
    ---------------------
  
    local Vec2=self:GetTargetCoordinate():GetVec2()
  
    local DCStask=CONTROLLABLE.TaskBombing(nil, Vec2, self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, Divebomb)
  
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
    
    local Vec2=self:GetTargetCoordinate():GetVec2()
    
    local DCStask=CONTROLLABLE.TaskCarpetBombing(nil, Vec2, self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, CarpetLength)
  
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

    local DCStask=CONTROLLABLE.TaskEscort(nil, self.escortGroup, self.escortVec3, LastWaypointIndex, self.engageMaxDistance, self.engageTargetTypes)
    
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.FACA then
  
    -----------------
    -- FAC Mission --
    -----------------  

    -- TODO
    local DCStask=CONTROLLABLE.TaskFAC_AttackGroup(nil, self.engageTarget.Target, self.engageWeaponType, self.facDesignation, self.facDatalink, self.facFrequency, self.facModulation, CallsignName, CallsignNumber)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.FERRY then
  
    -------------------
    -- FERRY Mission --
    -------------------
  
  elseif self.type==AUFTRAG.Type.INTERCEPT then

    -----------------------
    -- INTERCEPT Mission --
    -----------------------

    local DCStask=self:_GetDCSAttackTask(self.engageTarget)
    
    table.insert(DCStasks, DCStask)
    
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

    -- TODO: What?

  elseif self.type==AUFTRAG.Type.SEAD then
  
    ------------------
    -- SEAD Mission --
    ------------------  

    local DCStask=self:_GetDCSAttackTask(self.engageTarget)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.STRIKE then
  
    -------------------
    -- STIKE Mission --
    -------------------  

    local Vec2=self:GetTargetCoordinate():GetVec2()
  
    local DCStask=CONTROLLABLE.TaskAttackMapObject(nil, Vec2, self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.TANKER then
  
    --------------------
    -- TANKER Mission --
    -------------------- 

    local DCStask=CONTROLLABLE.EnRouteTaskTanker(nil)
    
    table.insert(self.enrouteTasks, DCStask)    
  
  elseif self.type==AUFTRAG.Type.TRANSPORT then

    -----------------------
    -- TRANSPORT Mission --
    ----------------------- 
  
    -- TODO: What about the groups to embark?
    
    local Vec2=self.transportPickup:GetVec2()
    
    local DCStask=CONTROLLABLE.TaskEmbarking(self, Vec2, self.transportGroupSet, Duration, DistributionGroupSet)
    
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.RESCUEHELO then

    -------------------------
    -- RESCUE HELO Mission --
    -------------------------
  
    local DCStask={}
    
    DCStask.id="Formation"
    
    local param={}
    param.unitname=self:GetTargetName()
    param.offsetX=20
    param.offsetY=20
    param.offsetZ=20
    param.altitude=70
    
    DCStask.params=param
    
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
          
    local CoordRaceTrack=self.orbitCoord:Translate(self.orbitLeg, self.orbitHeading, true)
  
    local DCStask=CONTROLLABLE.TaskOrbit(nil, self.orbitCoord, self.orbitCoord.y, self.orbitSpeed, CoordRaceTrack)
    
    table.insert(DCStasks, DCStask)
  
  end
  
  -- Count mission targets.
  self.Ntargets=self:CountMissionTargets()
  
  self:T({Ntargets=self.Ntargets, missiontask=DCStasks})

  -- Return the task.
  if #DCStasks==1 then
    return DCStasks[1]
  else
    return CONTROLLABLE.TaskCombo(nil, DCStasks)
  end

end

--- Get DCS task table for an attack task.
-- @param #AUFTRAG self
-- @param #AUFTRAG.TargetData target Target data.
-- @return DCS#Task The DCS task table.
function AUFTRAG:_GetDCSAttackTask(target)

  local DCStask=nil

  if target.Type==AUFTRAG.TargetType.GROUP then

    DCStask=CONTROLLABLE.TaskAttackGroup(nil, target.Target, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageAsGroup)
  
  elseif target.Type==AUFTRAG.TargetType.UNIT or target.Type==AUFTRAG.TargetType.STATIC then
  
    DCStask=CONTROLLABLE.TaskAttackUnit(nil, target.Target, self.engageAsGroup, self.WeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
  
  end

  return DCStask
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
    
  elseif Object:IsInstanceOf("UNIT") then
  
    target.Type=AUFTRAG.TargetType.UNIT  
  
  elseif Object:IsInstanceOf("STATIC") then
  
    target.Type=AUFTRAG.TargetType.STATIC
  
  elseif Object:IsInstanceOf("COORDINATE") then
  
    target.Type=AUFTRAG.TargetType.COORDINATE
    
  elseif Object:IsInstanceOf("AIRBASE") then
  
    target.Type=AUFTRAG.TargetType.AIRBASE
  
  else
    self:E(self.lid.."ERROR: Unknown object given as target. Needs to be a GROUP, UNIT, STATIC, COORDINATE")
    return nil
  end
  
  self:I(self.lid..string.format("Mission Target Type=%s", target.Type))
  
  return target
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
