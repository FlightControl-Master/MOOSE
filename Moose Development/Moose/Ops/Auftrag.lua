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
-- @field #number mid Mission ID.
-- @field #number prio Mission priority.
-- @field #number Tstart Mission start time in seconds.
-- @field #number Tstop Mission stop time in seconds.
-- @field #number duration Mission duration in seconds.
-- @field #table DCStask DCS task structure.
-- @field Core.Point#COORDINATE waypointcoord Coordinate of the waypoint task.
-- @field #number waypointindex Waypoint number at which the task is executed. 
-- @field Ops.FlightGroup#FLIGHTGROUP.Task waypointtask Waypoint task.
-- @field #number marker F10 map marker ID.
-- @field Core.Point#COORDINATE orbitCoord Coordinate where to orbit.
-- @field #number orbitSpeed Orbit speed in m/s.
-- @field #number orbitHeading Orbit heading in degrees.
-- @field #number orbitLeg Length of orbit leg in meters.
-- @field Core.Zone#ZONE_RADIUS zoneEngage *Circular* engagement zone.
-- @field #table typeTargets Table of target types that are engaged in the engagement zone.
-- @field Core.Point#COORDINATE coordTarget Coordinate of target location.
-- @field Core.Set#SET_GROUP groupsetTargets Set of target groups to attack.
-- @field #string squadname Name of the assigned squadron.
-- @field #table assets Assets assigned for this mission.
-- @field #number nassets Number of required assets.
-- @extends Core.Fsm#FSM

--- *To invent an airplane is nothing. To build one is something. To fly is everything.* -- Otto Lilienthal
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
-- # Tasking
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
-- @field #string SCHEDULED Mission is scheduled in a queue waiting to be assigned.
-- @field #string ASSIGNED Mission was assigned to somebody.
-- @field #string STARTED Mission started but is not executed yet.
-- @field #string EXECUTING Mission is being executed.
-- @field #string DONE Mission is over.
-- @field #string ANY The ANY "*" state.
AUFTRAG.Status={
  PLANNED="planned",
  SCHEDULED="scheduled",
  ASSIGNED="assigned",
  STARTED="started",
  EXECUTING="executing",
  DONE="done",
  ANY="Any",
}


--- AUFTRAG class version.
-- @field #string version
AUFTRAG.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot
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
  
  self.type=Type
  
  self.auftragsnummer=_AUFTRAGSNR
  
  self.status=AUFTRAG.Status.PLANNED
  
  self.name=string.format("Auftrag #%d", self.auftragsnummer)
  
  self.lid=string.format("Auftrag #%d %s | ", self.auftragsnummer, self.type)
  
  self:SetStartState(self.status)
  
  --[[
  self:AddTransition(AUFTRAG.Status.PLANNED,   "Start",    AUFTRAG.Status.STARTED) -- Mission has started.
  self:AddTransition(AUFTRAG.Status.,   "Start",    AUFTRAG.Status.STARTED) -- Mission has started.  
  self:AddTransition("*",   "Done",     "*") -- Mission is over.
  self:AddTransition(AUFTRAG.Status.ANY,       "Update",   AUFTRAG.Status.ANY) -- Mission is updated with latest data.
  self:AddTransition("*",   "Abort",    "*") -- Mission is aborted.
  ]]
  
  return self
end

--- Create a new AUFTRAG object and start the FSM.
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
  mission.zoneEngage=ZoneCAP or ZONE_RADIUS:New("CAP Zone", OrbitCoordinate:GetVec2(), mission.orbitLeg)
  mission.typeTargets=TargetTypes or {"Air"}
  
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
  mission.zoneEngage=ZoneCAS or ZONE_RADIUS:New("CAS Zone", OrbitCoordinate:GetVec2(), Leg)
  mission.typeTargets=TargetTypes or {"Helicopters", "Ground Units", "Light armed ships"}
  
  mission.DCStask=mission:GetDCSMissionTask()
  
  return mission
end



--- Create a STRIKE mission. Flight will attack a specified coordinate.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE Coordinate Target Coordinate.
-- @param #number Altitude Attack altitude in feet. Default 1000.
-- @return #AUFTRAG self
function AUFTRAG:NewSTRIKE(TargetCoordinate, Altitude)

  local mission=AUFTRAG:New(AUFTRAG.Type.STRIKE)
  
  mission.coordTarget=TargetCoordinate
  mission.altitude=UTILS.FeetToMeters(Altitude or 1000)
  
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
  
  mission.groupsetTargets=TargetGroupSet  
  mission.groupsetTargets:FilterDeads():FilterCrashes()
  
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

  mission.groupsetTargets=TargetGroupSet  
  mission.groupsetTargets:FilterDeads():FilterCrashes()
  
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

--- Set mission priority.
-- @param #AUFTRAG self
-- @param #number Prio Priority 1=high, 100=low. Default 50
-- @return #AUFTRAG self
function AUFTRAG:SetPriority(Prio)
  self.prio=Prio or 50
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Count alive mission targets.
-- @param #AUFTRAG self
-- @param #number Number of alive targets.
function AUFTRAG:CountMissionTargets()
  
  local N=0
  if self.groupsetTargets then
    local n=self.groupsetTargets:CountAlive()
    N=N+n
  end

  if self.unitsetTargets then
    local n=self.unitsetTargets:CountAlive()
    N=N+n
  end
  
  return N
end

--- Count alive mission targets.
-- @param #AUFTRAG self
-- @param Core.Point#COORDINATE The target coordinate or nil.
function AUFTRAG:GetTargetCoordinate()

  if self.groupsetTargets then
    local group=self.groupsetTargets:GetFirst() --Wrapper.Group#GROUP
    return group:GetCoordinate()
  elseif self.unitsetTargets then
    local unit=self.unitsetTargets:GetFirst() --Wraper.Unit#UNIT
    return unit:GetCoordinate()
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

    local DCStask=CONTROLLABLE.TaskAttackUnit(nil, AttackUnit, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType)
  
  elseif self.type==AUFTRAG.Type.AWACS then
  
    -------------------
    -- AWACS Mission --
    -------------------  
    
  elseif self.type==AUFTRAG.Type.BAI then
  
    -----------------
    -- BAI Mission --
    -----------------  

    for _,_group in pairs(self.groupsetTargets:GetSet()) do
      local TargetGroup=_group
  
      local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, ENUMS.WeaponFlag.Auto, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit)
      
      table.insert(DCStasks, DCStask)
    end

  elseif self.type==AUFTRAG.Type.BOMBING then
  
    ---------------------
    -- BOMBING Mission --
    ---------------------
  
  elseif self.type==AUFTRAG.Type.CAP then
  
    -----------------
    -- CAP Mission --
    -----------------  

    local CoordRaceTrack=self.orbitCoord:Translate(self.orbitLeg, self.orbitHeading, true)
  
    local DCStask=CONTROLLABLE.TaskOrbit(nil, self.orbitCoord, self.orbitCoord.y, self.orbitSpeed, CoordRaceTrack)
    
    -- TODO! Could be added in the same task!
    self:AddTaskEnrouteEngageTargetsInZone(self.zoneEngage, self.typeTargets, self.prio)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.CAS then
  
    -----------------
    -- CAS Mission --
    -----------------

    local CoordRaceTrack=self.orbitCoord:Translate(self.orbitLeg, self.orbitHeading, true)
  
    local DCStask=CONTROLLABLE.TaskOrbit(nil, self.orbitCoord, self.orbitCoord.y, self.orbitSpeed, CoordRaceTrack)
    
    self:AddTaskEnrouteEngageTargetsInZone(self.zoneEngage, self.typeTargets, self.prio)
    
    table.insert(DCStasks, DCStask)

  elseif self.type==AUFTRAG.Type.ESCORT then
  
    --------------------
    -- ESCORT Mission --
    --------------------

    local DCStask=CONTROLLABLE.TaskEscort(nil, FollowControllable, Vec3, LastWaypointIndex, EngagementDistance, TargetTypes)

  elseif self.type==AUFTRAG.Type.FACA then
  
    -----------------
    -- FAC Mission --
    -----------------  

    local DCStask=CONTROLLABLE.TaskFAC_AttackGroup(nil, AttackGroup, WeaponType, Designation, Datalink)
  
  elseif self.type==AUFTRAG.Type.FERRY then
  
    -------------------
    -- FERRY Mission --
    -------------------
  
  elseif self.type==AUFTRAG.Type.INTERCEPT then

    -----------------------
    -- INTERCEPT Mission --
    -----------------------

    for _,group in pairs(self.groupsetTargets:GetSet()) do
      local TargetGroup=group --Wrapper.Group#GROUP
  
      local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, ENUMS.WeaponFlag.Auto, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit)
      
      table.insert(DCStasks, DCStask)
    end
    
  elseif self.type==AUFTRAG.Type.ORBIT then
  
    -------------------
    -- ORBIT Mission --
    -------------------
          
    local CoordRaceTrack=self.orbitCoord:Translate(self.orbitLeg, self.orbitHeading, true)
  
    local DCStask=CONTROLLABLE.TaskOrbit(nil, self.orbitCoord, self.orbitCoord.y, self.orbitSpeed, CoordRaceTrack)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.RECON then
  
    -------------------
    -- RECON Mission --
    -------------------  
  
  elseif self.type==AUFTRAG.Type.STRIKE then
  
    -------------------
    -- STIKE Mission --
    -------------------  

    local Vec2=self.coordtarget:GetVec2()
  
    local DCStask=CONTROLLABLE.TaskAttackMapObject(nil, Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, self.altitude, WeaponType)
    
    table.insert(DCStasks, DCStask)
  
  elseif self.type==AUFTRAG.Type.TANKER then
  
    --------------------
    -- TANKER Mission --
    -------------------- 
  
  elseif self.type==AUFTRAG.Type.TRANSPORT then
  
  else
    self:E(self.lid..string.format("ERROR: Unknown mission task!"))
    return nil
  end

  if #DCStasks==1 then
    return DCStasks[1]
  else
    return CONTROLLABLE.TaskCombo(nil, DCStasks)
  end

end



