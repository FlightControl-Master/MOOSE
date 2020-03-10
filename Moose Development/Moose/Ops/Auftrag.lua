--- **Ops** - Auftrag (mission) for Ops.
--
-- **Main Features:**
--
--    * Create mission for ops.
--
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
-- @field #number marker F10 map marker ID.
-- @field #table DCStask DCS task structure.
-- @field #number Ntargets Number of mission targets.
-- 
-- @field Core.Point#COORDINATE waypointcoord Coordinate of the waypoint task.
-- 
-- @field Core.Point#COORDINATE orbitCoord Coordinate where to orbit.
-- @field #number orbitSpeed Orbit speed in m/s.
-- @field #number orbitHeading Orbit heading in degrees.
-- @field #number orbitLeg Length of orbit leg in meters.
-- 
-- @field Core.Zone#ZONE_RADIUS engageZone *Circular* engagement zone.
-- @field #table engageTargetTypes Table of target types that are engaged in the engagement zone.
-- @field Core.Point#COORDINATE engageCoord Coordinate of target location.
-- @field Core.Set#SET_GROUP engageTargetGroupset Set of target groups to attack.
-- @field Core.Set#SET_UNIT engageTargetUnitset Set of target units to attack.
-- @field #number engageAltitude Engagement altitude in meters.
-- @field #number engageDirection Engagement direction in degrees.
-- @field #number engageQuantity Number of times a target is engaged.
-- @field #number engageWeaponType Weapon type used.
-- @field #number engageWeaponExpend How many weapons are used.
-- @field #boolean engageAsGroup Group attack.
-- @field #number engageMaxDistance Max engage distance.
-- 
-- @field Wrapper.Group#GROUP escortGroup The group to be escorted.
-- @field DCS#Vec3 escortVec3 The 3D offset vector from the escorted group to the escort group.
-- 
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander The WINGCOMMANDER managing this mission.
-- @field Ops.AirWing#AIRWING airwing The assigned airwing.
-- @field #string squadname Name of the assigned Airwing squadron.
-- @field #table assets Airwing Assets assigned for this mission.
-- @field #number nassets Number of required assets by the Airwing.
-- @field #number requestID The ID of the queued warehouse request. Necessary to cancel the request if the mission was cancelled before the request is processed.
-- @field #boolean cancelContactLost If true, cancel mission if the contact is lost.
-- 
-- @field #number missionAltitude Mission altitude in meters.
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
-- # Events
-- 
-- 
-- # Missions
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
}

--- Global mission counter.
_AUFTRAGSNR=0


--- Mission types.
-- @type AUFTRAG.Type
-- @field #string ANTISHIP Anti-ship mission.
-- @field #string AWACS AWACS mission.
-- @field #string BAI Battlefield Air Interdiction.
-- @field #string BOMBING Bombing mission.
-- @field #string CAP Combat Air Patrol.
-- @field #string CAS Close Air Support.
-- @field #string ESCORT Escort mission.
-- @field #string FACA Forward AirController airborne mission.
-- @field #string FERRY Ferry flight mission.
-- @field #string INTERCEPT Intercept mission.
-- @field #string ORBIT Orbit mission.
-- @field #string PATROL Similar to CAP but no auto engage targets.
-- @field #string RECON Recon mission.
-- @field #string SEAD Suppression/destruction of enemy air defences.
-- @field #string STRIKE Strike mission.
-- @field #string TANKER Tanker mission.
-- @field #string TRANSPORT Transport mission.
AUFTRAG.Type={
  ANTISHIP="Anti Ship",
  AWACS="AWACS",  
  BAI="BAI",
  BOMBING="Bombing",
  CAP="CAP",
  CAS="CAS",
  ESCORT="Escort",
  FACA="FAC-A",
  FERRY="Ferry Flight",
  INTERCEPT="Intercept",
  ORBIT="Orbit",
  PATROL="Patrol",
  RECON="Recon",
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

--- FlightStatus
-- @type AUFTRAG.FlightStatus
-- @field #string SCHEDULED Mission is scheduled in a FLIGHGROUP queue waiting to be started.
-- @field #string STARTED Flightgroup started this mission but it is not executed yet.
-- @field #string EXECUTING Flightgroup is executing this mission.
-- @field #string DONE Mission task of the flightgroup is done.
-- @field #string CANCELLED Mission was cancelled.
AUFTRAG.FlightStatus={
  SCHEDULED="scheduled",
  STARTED="started",
  EXECUTING="executing",
  DONE="done",
  CANCELLED="cancelled",
}

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


--- AUFTRAG class version.
-- @field #string version
AUFTRAG.version="0.0.5"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Mission ROE and ROT
-- TODO: Mission formation, etc.
-- DONE: FSM events.
-- TODO: F10 marker functions that are updated on Status event.
-- TODO: Evaluate mission result ==> SUCCESS/FAILURE
-- TODO: NewAUTO() NewA2G NewA2A

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AUFTRAG object.
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
  self.lid=string.format("Auftrag #%d %s | ", self.auftragsnummer, tostring(self.type))
  
  -- State is planned.
  self.status=AUFTRAG.Status.PLANNED
  
  -- Defaults
  self:SetName()
  self:SetPriority()
  self:SetMissionTime()
  
  self.missionRepeated=0
  self.missionRepeatMax=1
  
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
  self:AddTransition("*",                      "Cancel",        AUFTRAG.Status.CANCELLED)   -- Command to cancel the mission.
  
  self:AddTransition("*",                      "Success",       AUFTRAG.Status.SUCCESS)
  self:AddTransition("*",                      "Failed",        AUFTRAG.Status.FAILED)
    
  self:AddTransition("*",                      "Status",        "*")
  self:AddTransition("*",                      "Stop",          "Stopped")
  
  self:AddTransition("*",                      "Repeat",        AUFTRAG.Status.PLANNED)
  
  self:AddTransition("*",                      "AssetDead",     "*")

  --[[
  self:HandleEvent(EVENTS.PilotDead,      self._UnitDead)
  self:HandleEvent(EVENTS.Ejection,       self._UnitDead)
  self:HandleEvent(EVENTS.Crash,          self._UnitDead)
  ]]
  
  self:__Status(-1)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Missions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create an ANTI-SHIP mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_UNIT TargetGroupSet The set of target units.
-- @return #AUFTRAG self
function AUFTRAG:NewANTISHIP(TargetUnitSet)
  
  if TargetUnitSet:IsInstanceOf("UNIT") then
    TargetUnitSet=SET_UNIT:New():AddGroup(TargetUnitSet)
  end

  local mission=AUFTRAG:New(AUFTRAG.Type.ANTISHIP)
  
  mission.engageTargetUnitset=TargetUnitSet
  mission.engageTargetUnitset:FilterDeads():FilterCrashes()
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create an ORBIT mission.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Where to orbit. Altitude is also taken from the coordinate.
-- @param #number Speed Orbit speed in knots. Default 350 kts. 
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AUFTRAG self
function AUFTRAG:NewORBIT(Coordinate, Speed, Heading, Leg)

  local auftrag=AUFTRAG:New(AUFTRAG.Type.ORBIT)
  
  auftrag.orbitCoord   = Coordinate
  auftrag.orbitHeading = Heading or 270
  auftrag.orbitLeg     = UTILS.NMToMeters(Leg or 10)
  auftrag.orbitSpeed   = UTILS.KnotsToMps(Speed or 350)  

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
  local mission=self:NewORBIT(OrbitCoordinate, OrbitSpeed, Heading, Leg)
  
  if Altitude then
    mission.orbitCoord.y=UTILS.FeetToMeters(Altitude)
  end
  
  -- CAP paramters.
  mission.type=AUFTRAG.Type.PATROL
  
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
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end



--- Create a STRIKE mission. Flight will attack a specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Target Coordinate.
-- @param #number Altitude Engage altitude in feet. Default 1000.
-- @return #AUFTRAG self
function AUFTRAG:NewSTRIKE(TargetCoordinate, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.STRIKE)
  
  mission.engageCoord=TargetCoordinate
  mission.engageAltitude=UTILS.FeetToMeters(Altitude or 1000)
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create an INTERCEPT mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_GROUP TargetGroupSet The set of target groups to intercept.
-- @return #AUFTRAG self
function AUFTRAG:NewINTERCEPT(TargetGroupSet)
  
  if TargetGroupSet:IsInstanceOf("GROUP") then
    env.info("Converting group to set!")
    TargetGroupSet=SET_GROUP:New():AddGroup(TargetGroupSet)
  end

  local mission=AUFTRAG:New(AUFTRAG.Type.INTERCEPT)
  
  mission.engageTargetGroupset=TargetGroupSet  
  mission.engageTargetGroupset:FilterDeads():FilterCrashes()
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end

--- Create a BAI mission.
-- @param #AUFTRAG self
-- @param Core.Set#SET_GROUP TargetGroupSet The set of target groups to attack. Instead of a SET an ordinary GROUP object can also be given if only a single group needs to be attacked.
-- @return #AUFTRAG self
function AUFTRAG:NewBAI(TargetGroupSet)
  
  if TargetGroupSet:IsInstanceOf("GROUP") then
    env.info("Converting group to set!")
    TargetGroupSet=SET_GROUP:New():AddGroup(TargetGroupSet)
  end

  local mission=AUFTRAG:New(AUFTRAG.Type.BAI)

  mission.engageTargetGroupset=TargetGroupSet  
  mission.engageTargetGroupset:FilterDeads():FilterCrashes()
  
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
              
      mission=AUFTRAG:NewINTERCEPT(group)
      
    elseif category==Group.Category.GROUND then
    
      --TODO: action depends on type
      -- AA/SAM ==> SEAD
      -- Tanks ==>
      -- Artillery ==>
      -- Infantry ==>
      -- 
              
      if attribute==GROUP.Attribute.GROUND_AAA or attribute==GROUP.Attribute.GROUND_SAM then
          
          --TODO: SEAD/DEAD
      
      end
      
      mission=AUFTRAG:NewBAI(group)
      
    
    elseif category==Group.Category.SHIP then
    
      --TODO: ANTISHIP
      
      local TargetUnitSet=SET_UNIT:New()
      
      for _,_unit in pairs(group:GetUnits()) do
        local unit=_unit --Wrapper.Unit#UNIT
        if unit and unit:IsAlive() and unit:GetThreatLevel()>0 then
          TargetUnitSet:AddUnit(unit)
        end
      end
      
      if TargetUnitSet:Count()>0 then
        mission=AUFTRAG:NewANTISHIP(TargetUnitSet)
      end
            
    end
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
function AUFTRAG:SetMissionTime(ClockStart, ClockStop)

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
-- @param #number WeaponType Weapon type. Default is ENUMS.WeaponFlag.Auto
-- @return #AUFTRAG self
function AUFTRAG:SetWeaponExpend(WeaponExpend)
  
  self.engageWeaponExpend=WeaponExpend or "Auto"
  
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
-- @param #string roe Mision ROE.
-- @return #AUFTRAG self
function AUFTRAG:SetROE(roe)
  
  self.optionROE=roe
  
  return self
end


--- Set Reaction on Threat (ROT) for this mission.
-- @param #AUFTRAG self
-- @param #string roe Mision ROT.
-- @return #AUFTRAG self
function AUFTRAG:SetROE(rot)
  
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

  -- Cancel mission if stop time passed.
  if self.Tstop and timer.getAbsTime()>self.Tstop+10 then
    self:Cancel()
  end

  -- Cancel mission if number of targest is 0 (and was >0 before as some missions, e.g. orbit, don't have any target).
  if self:IsNotOver() and self.Ntargets>0 and Ntargets==0 then
    self:Cancel()
  end
  
  if self:IsNotOver() and #self.assets==0 then
    self:Cancel()
  end
  
  -- Check if ALL flights are done with their mission.
  if self:IsNotOver() and self:CheckFlightsDone() then
    self:Done()
  end
  
  -- Current FSM state.
  local fsmstate=self:GetState()
  
  -- Mission start stop time.
  local Cstart=UTILS.SecondsToClock(self.Tstart, true)
  local Cstop=self.Tstop and UTILS.SecondsToClock(self.Tstop, true) or "INF"

  -- Info message.
  self:I(self.lid..string.format("Status \"%s\": T=%s-%s flights=%d, targets=%d", self.status, Cstart, Cstop, Nflights, Ntargets))

  -- Check for error.  
  if fsmstate~=self.status then
    self:E(self.lid..string.format("ERROR: FSM state %s != %s mission status!", fsmstate, self.status))
  end

  -- Check if mission is OVER.
  if self:IsOver() then
    -- TODO: evaluate mission result. self.Ntargets>0 and Ntargets=?
    -- TODO: if failed, repeat mission, i.e. set status to PLANNED? if success, stop and remove from ALL queues.
    --self:Stop()
    
    self:Evaluate()
  else
    self:__Status(-30)
  end
end

--- Set flightgroup mission status.
-- @param #AUFTRAG self
-- @return #string status New status.
function AUFTRAG:Evaluate()

  local Ntargets=self:CountMissionTargets()
  
  if self.Ntargets>Ntargets then
    self:Failed()
  else
    self:Success()
  end

end


--- Set flightgroup mission status.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @param #string status New status.
function AUFTRAG:SetFlightStatus(flightgroup, status)

  if self:GetFlightStatus(flightgroup)==AUFTRAG.FlightStatus.CANCELLED and status==AUFTRAG.FlightStatus.DONE then
    -- Do not overwrite a CANCELLED status with a DONE status.
  else
    self.flightdata[flightgroup.groupname].status=status
  end

  -- Check if ALL flights are done with their mission.
  if self:IsNotOver() and self:CheckFlightsDone() then
    self:Done()
  end  
  
end

--- Get flightgroup mission status.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
function AUFTRAG:GetFlightStatus(flightgroup)
  return self.flightdata[flightgroup.groupname].status
end


--- Set flightgroup waypoint coordinate.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @param Core.Point#COORDINATE coordinate Waypoint Coordinate.
function AUFTRAG:SetFlightWaypointCoordinate(flightgroup, coordinate)
  self.flightdata[flightgroup.groupname].waypointcoordinate=coordinate
end

--- Get flightgroup waypoint coordinate.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE Waypoint Coordinate.
function AUFTRAG:GetFlightWaypointCoordinate(flightgroup)
  return self.flightdata[flightgroup.groupname].waypointcoordinate
end


--- Set flightgroup waypoint task.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @param Ops.FlightGroup#FLIGHTGROUP.Task task Waypoint task.
function AUFTRAG:SetFlightWaypointTask(flightgroup, task)
  self:I(self.lid..string.format("Setting waypoint task %s", task and task.description or "WTF"))
  self.flightdata[flightgroup.groupname].waypointtask=task
end

--- Get flightgroup waypoint task.
-- @param #AUFTRAG self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group.
-- @return Ops.FlightGroup#FLIGHTGROUP.Task task Waypoint task. Waypoint task.
function AUFTRAG:GetFlightWaypointTask(flightgroup)
  return self.flightdata[flightgroup.groupname].waypointtask
end


--- Get flightgroup mission status.
-- @param #AUFTRAG self
-- @return #boolean If true, all flights are done with the mission.
function AUFTRAG:CheckFlightsDone()

  -- These are early stages, where we might not even have a flightgroup defined to be checked.
  if self:IsPlanned() or self:IsQueued() or self:IsRequested() then 
    return false
  end
  
  -- Assume we are done.
  local done=true
  
  for groupname,data in pairs(self.flightdata) do
    local flightdata=data --#AUFTRAG.FlightData
    if flightdata.status~=AUFTRAG.FlightStatus.DONE and flightdata.status~=AUFTRAG.FlightStatus.CANCELLED then
      -- At least one flight group is not DONE or CANCELLED yet!
      done=false
    end
  end

  return done
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function AUFTRAG:OnEventCrash(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.lid..string.format("EVENT: Element %s crashed ==> dead", element.name))
      self:ElementDead(element)
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
end

--- On after "AssetDead" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.AirWing#AIRWING.SquadronAsset
function AUFTRAG:onafterAssetDead(From, Event, To, Asset)
  
  -- Delete asset from mission.
  self:DelAsset(Asset)
  
  -- All assets dead?
  if #self.assets==0 then
  
    if self:IsNotOver() then
    
      -- Mission failed.
      self:Failed()
      
    else
    
      self:Stop()
      
    end
  end

end


--- On after "Cancel" event. Cancells the mission.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterCancel(From, Event, To)

  self.status=AUFTRAG.Status.CANCELLED
  self:I(self.lid..string.format("New mission status=%s", self.status))

  if self.airwing then
    
    -- Airwing will cancel all flight missions and remove queued request from warehouse queue.
    self.airwing:MissionCancel(self)
  
  else
  
    for _,_flightdata in pairs(self.flightdata) do
      local flightdata=_flightdata --#AUFTRAG.FlightData
      flightdata.flightgroup:MissionCancel(self)
    end
    
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
  
    self:Stop()
    
  else
        
    -- Repeat mission.
    self:Repeat()
    
  end  

end


--- On after "Repeat" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterRepeat(From, Event, To)

  -- Increase repeat counter.
  self.missionRepeated=self.missionRepeated+1
  
  if self.wingcommander then
  
  elseif self.airwing then
  
  
  end

end

--- On after "Success" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterSuccess(From, Event, To)

  self.status=AUFTRAG.Status.SUCCESS
  self:I(self.lid..string.format("New mission status=%s", self.status))

end

--- On after "Stop" event. Remove mission from AIRWING and FLIGHTGROUP mission queues.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStop(From, Event, To)

  -- TODO: remove missions from queues in WINGCOMMANDER, AIRWING and FLIGHGROUPS!
  
  -- TODO: Mission should be OVER! we dont want to remove running missions from any queues.
  
  if self.wingcommander then
    
  end
  
  if self.airwing then
    self.airwing:RemoveMission(self)
  end

  for _,_flightdata in pairs(self.flightdata) do
    local flightdata=_flightdata --#AUFTRAG.FlightData
    flightdata.flightgroup:RemoveMission(self)
  end

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
  if self.engageTargetGroupset then
    --local n=self.engageTargetGroupset:CountAlive()
    
    for _,_group in pairs(self.engageTargetGroupset.Set) do
      local group=_group --Wrapper.Group#GROUP
      
      if group and group:IsAlive() then
      
        for _,_unit in pairs(group:GetUnits()) do
          local unit=_unit --Wrapper.Unit#UNIT
          if unit and unit:IsAlive() then
            N=N+1
          end          
        end
        
      end
    end
  end

  if self.engageTargetUnitset then
    local n=self.engageTargetUnitset:Count()
    N=N+n
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

--- Get coordinate of target. First unit/group of the set is used.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE The target coordinate or nil.
function AUFTRAG:GetTargetCoordinate()

  if self.engageTargetGroupset then  
    local group=self.engageTargetGroupset:GetFirst() --Wrapper.Group#GROUP
    if group and group:IsAlive() then
      return group:GetCoordinate()
    end
  elseif self.engageTargetUnitset then
    local unit=self.engageTargetUnitset:GetFirst() --Wrapper.Unit#UNIT
    if unit and unit:IsAlive() then
      return unit:GetCoordinate()
    end
  elseif self.engageCoord then
    return self.engageCoord
  elseif self.orbitCoord then
    return self.orbitCoord
  end

  return nil
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

    for _,_unit in pairs(self.engageTargetUnitset:GetSet()) do
      local TargetUnit=_unit

      local DCStask=CONTROLLABLE.TaskAttackUnit(nil, TargetUnit, self.engageAltitude, self.WeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
      
      table.insert(DCStasks, DCStask)
      
    end
  
  elseif self.type==AUFTRAG.Type.AWACS then
  
    -------------------
    -- AWACS Mission --
    -------------------  

    local DCStask=CONTROLLABLE.EnRouteTaskAWACS(nil)
    
    table.insert(DCStasks, DCStask)
    
  elseif self.type==AUFTRAG.Type.BAI then
  
    -----------------
    -- BAI Mission --
    -----------------  

    for _,_group in pairs(self.engageTargetGroupset:GetSet()) do
      local TargetGroup=_group
  
      local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude)
      
      table.insert(DCStasks, DCStask)
    end

  elseif self.type==AUFTRAG.Type.BOMBING then
  
    ---------------------
    -- BOMBING Mission --
    ---------------------
  
    local Vec2=self.engageCoord:GetVec2()
  
    local DCStask=CONTROLLABLE.TaskBombing(self,Vec2, self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType, Divebomb)
  
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.CAP then
  
    -----------------
    -- CAP Mission --
    -----------------  

    local DCStask=CONTROLLABLE.EnRouteTaskEngageTargetsInZone(self.engageZone:GetVec2(), self.engageZone:GetRadius(), self.engageTargetTypes, Priority)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.CAS then
  
    -----------------
    -- CAS Mission --
    -----------------

    local DCStask=CONTROLLABLE.EnRouteTaskEngageTargetsInZone(self.engageZone:GetVec2(), self.engageZone:GetRadius(), self.engageTargetTypes, Priority)
    
    table.insert(DCStasks, DCStask)

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

    local DCStask=CONTROLLABLE.TaskFAC_AttackGroup(nil, self.engageAsGroup, self.engageWeaponType, Designation, Datalink)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.FERRY then
  
    -------------------
    -- FERRY Mission --
    -------------------
  
  elseif self.type==AUFTRAG.Type.INTERCEPT then

    -----------------------
    -- INTERCEPT Mission --
    -----------------------

    for _,group in pairs(self.engageTargetGroupset:GetSet()) do
      local TargetGroup=group --Wrapper.Group#GROUP
  
      local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, self.engageWeaponType, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude)
      
      table.insert(DCStasks, DCStask)
    end
    
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
  
  elseif self.type==AUFTRAG.Type.STRIKE then
  
    -------------------
    -- STIKE Mission --
    -------------------  

    local Vec2=self.engageCoord:GetVec2()
  
    local DCStask=CONTROLLABLE.TaskAttackMapObject(nil, Vec2, self.engageAsGroup, self.engageWeaponExpend, self.engageQuantity, self.engageDirection, self.engageAltitude, self.engageWeaponType)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.TANKER then
  
    --------------------
    -- TANKER Mission --
    -------------------- 

    local DCStask=CONTROLLABLE.EnRouteTaskTanker(nil)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.TRANSPORT then

    -----------------------
    -- TRANSPORT Mission --
    ----------------------- 
  
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

  -- Return the task.
  if #DCStasks==1 then
    return DCStasks[1]
  else
    return CONTROLLABLE.TaskCombo(nil, DCStasks)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
