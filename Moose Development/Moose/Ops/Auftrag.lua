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
-- @field #string name Mission name.
-- @field #number prio Mission priority.
-- @field #boolean urgent Mission is urgent. Running missions with lower prio might be cancelled.
-- @field #number Tstart Mission start time in seconds.
-- @field #number Tstop Mission stop time in seconds.
-- @field #number duration Mission duration in seconds.
-- @field #number marker F10 map marker ID.
-- @field #table DCStask DCS task structure.
-- 
-- @field Core.Point#COORDINATE waypointcoord Coordinate of the waypoint task.
-- @field #number waypointindex Waypoint number at which the task is executed. 
-- @field Ops.FlightGroup#FLIGHTGROUP.Task waypointtask Waypoint task.
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
-- @field Core.Set#SET_GROUP engageTargetUnitset Set of target units to attack.
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
-- @field Ops.AirWing#AIRWING airwing The assigned airwing.
-- @field #string squadname Name of the assigned Airwing squadron.
-- @field #table assets Airwing Assets assigned for this mission.
-- @field #number nassets Number of required assets by the Airwing.
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
}

--- Global mission counter.
_AUFTRAGSNR=0


--- Mission types.
-- @type AUFTRAG.Type
-- @param #string ANTISHIP Anti-ship mission.
-- @param #string AWACS AWACS mission.
-- @param #string BAI Battlefield Air Interdiction.
-- @param #string BOMBING Bombing mission.
-- @param #string CAP Combat Air Patrol.
-- @param #string CAS Close Air Support.
-- @param #string ESCORT Escort mission.
-- @param #string FACA Forward AirController airborne mission.
-- @param #string FERRY Ferry flight mission.
-- @param #string INTERCEPT Intercept mission.
-- @param #string ORBIT Orbit mission.
-- @param #string RECON Recon mission.
-- @param #string SEAD Suppression/destruction of enemy air defences.
-- @param #string STRIKE Strike mission.
-- @param #string TANKER Tanker mission.
-- @param #string TRANSPORT Transport mission.
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
-- @field #string ASSIGNED Mission was assigned to somebody.
-- @field #string SCHEDULED Mission is scheduled in a FLIGHGROUP queue waiting to be started.
-- @field #string STARTED Mission started but is not executed yet.
-- @field #string EXECUTING Mission is being executed.
-- @field #string DONE Mission is over.
AUFTRAG.Status={
  PLANNED="planned",
  QUEUED="queued",
  ASSIGNED="assigned",
  SCHEDULED="scheduled",
  STARTED="started",
  EXECUTING="executing",
  DONE="done",
}


--- AUFTRAG class version.
-- @field #string version
AUFTRAG.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Mission ROE and ROT
-- TODO: Mission formation, etc.
-- TODO: FSM events.

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
  
  -- FMS start state is PLANNED.
  self:SetStartState(self.status)
  
  -- PLANNED --> (QUEUED) --> (ASSIGNED) --> SCHEDULED --> STARTED --> EXECUTING --> DONE
  
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Queue",    AUFTRAG.Status.QUEUED)    --
  self:AddTransition(AUFTRAG.Status.QUEUED,    "Assign",   AUFTRAG.Status.ASSIGNED)  --
  self:AddTransition(AUFTRAG.Status.ASSIGNED,  "Schedule", AUFTRAG.Status.SCHEDULED) --  
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Schedule", AUFTRAG.Status.SCHEDULED) -- From planned directly to scheduled.  
  self:AddTransition(AUFTRAG.Status.SCHEDULED, "Start",    AUFTRAG.Status.STARTED)   --
  self:AddTransition(AUFTRAG.Status.STARTED,   "Execute",  AUFTRAG.Status.EXECUTING) --
  self:AddTransition(AUFTRAG.Status.EXECUTING, "Done",     AUFTRAG.Status.DONE)      --   
  
  self:AddTransition("*",                      "Cancel",       "Cancelled")
  self:AddTransition("*",                      "Accomplished", "Success")
  self:AddTransition("*",                      "Failed",       "Failure")
    
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Missions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

--- Check if mission is executing.
-- @param #AUFTRAG self
-- @return #boolean If true, mission is currently executing.
function AUFTRAG:IsExecuting()
  return self.status==AUFTRAG.Status.EXECUTING
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Queue" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterQueue(From, Event, To)
  self.status=AUFTRAG.Status.QUEUED
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

--- On after "Schedule" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterSchedule(From, Event, To)
  self.status=AUFTRAG.Status.SCHEDULED
  self:I(self.lid..string.format("New mission status=%s", self.status))  
end

--- On after "Start" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterStart(From, Event, To)
  self.status=AUFTRAG.Status.STARTED
  self:I(self.lid..string.format("New mission status=%s", self.status))  
end

--- On after "Execute" event.
-- @param #AUFTRAG self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFTRAG:onafterExecute(From, Event, To)
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Count alive mission targets.
-- @param #AUFTRAG self
-- @param #number Number of alive targets.
function AUFTRAG:CountMissionTargets()
  
  local N=0
  if self.engageTargetGroupset then
    local n=self.engageTargetGroupset:CountAlive()
    N=N+n
  end

  if self.engageTargetUnitset then
    local n=self.engageTargetUnitset:CountAlive()
    N=N+n
  end
  
  return N
end

--- Get coordinate of target. First unit/group of the set is used.
-- @param #AUFTRAG self
-- @return Core.Point#COORDINATE The target coordinate or nil.
function AUFTRAG:GetTargetCoordinate()

  if self.engageTargetGroupset then  
    local group=self.engageTargetGroupset:GetFirst() --Wrapper.Group#GROUP
    return group:GetCoordinate()
  elseif self.engageTargetUnitset then
    local unit=self.engageTargetUnitset:GetFirst() --Wrapper.Unit#UNIT
    return unit:GetCoordinate()
  elseif self.engageCoord then
    return self.engageCoord
  elseif self.orbitCoord then
    return self.orbitCoord
  end

  return nil
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
  if self.type==AUFTRAG.Type.ORBIT or self.type==AUFTRAG.Type.CAP or self.type==AUFTRAG.Type.CAS or self.type==AUFTRAG.Type.AWACS or self.type==AUFTRAG.Type.TANKER then

    -------------------
    -- ORBIT Mission --
    -------------------
          
    local CoordRaceTrack=self.orbitCoord:Translate(self.orbitLeg, self.orbitHeading, true)
  
    local DCStask=CONTROLLABLE.TaskOrbit(nil, self.orbitCoord, self.orbitCoord.y, self.orbitSpeed, CoordRaceTrack)
    
    table.insert(DCStasks, DCStask)
  
  end
  

  -- Return the task.
  if #DCStasks==1 then
    return DCStasks[1]
  else
    return CONTROLLABLE.TaskCombo(nil, DCStasks)
  end

end



