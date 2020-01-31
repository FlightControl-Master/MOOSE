--- **Ops** - (R2.5) - Aerial refueling tanker.
--
-- **Main Features:**
--
--    * Monitor flight status of elements or entire group.
--    * Create a mission queue.
--    * Inherits FLIGHTGROUP class.
--
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.TankerGroup
-- @image OPS_TankerGroup.png


--- TANKERGROUP class.
-- @type TANKERGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table Qmissions Mission queue.
-- @field #table Qclients Client queue.
-- @field #TANKERGROUP.Mission currentmission Currently assigned mission.
-- @field #number missioncounter Counter of total missions.
-- @extends Ops.FlightGroup#FLIGHTGROUP

--- *To invent an airplane is nothing. To build one is something. To fly is everything.* -- Otto Lilienthal
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\TANKERGROUP_Main.jpg)
--
-- # The TANKERGROUP Concept
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
-- @field #TANKERGROUP
TANKERGROUP = {
  ClassName          = "TANKERGROUP",
  Debug              = false,
  lid                =   nil,
  Qmissions          =    {},
  Qclients           =    {},
  currentmission     =   nil,
  missioncounter     =   nil,
}

--- Tanker mission table.
-- @type TANKERGROUP.Mission
-- @field #string name Name of the mission.
-- @field #number mid ID of the mission.
-- @field #number tid ID of the assigned FLIGHTGROUP task.
-- @field Core.Zone#ZONE zone Mission zone.
-- @field #number duration Duration of mission.
-- @field #number altitude Altitude of orbit in meters ASL.
-- @field #number distance Length of orbit leg in meters.
-- @field #number heading Heading of orbit in degrees.
-- @field #number speed Speed in m/s.
-- @field #number Tadded Time the mission was added.
-- @field #number Tstart Start time in seconds.
-- @field #number Tstarted Time the mission was started.
-- @field #number Tstop Time the mission is stopped.
-- @field #number Tsopped Time the mission was stopped.

--- TANKERGROUP class version.
-- @field #string version
TANKERGROUP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add orbit task.
-- TODO: Add client queue.
-- TODO: Add menu?

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TANKERGROUP object and start the FSM.
-- @param #TANKERGROUP self
-- @param #string groupname Name of the group.
-- @return #TANKERGROUP self
function TANKERGROUP:New(groupname)

  -- Inherit everything from TANKERGROUP class.
  local self=BASE:Inherit(self, FLIGHTGROUP:New(groupname)) -- #TANKERGROUP
  
  
  -- Add FSM transitions.
  --                 From State     -->     Event     -->          To State
  self:AddTransition("*",                 "OnStation",            "Ready2Refuel")   -- Tanker is on station and ready to refuel.
  self:AddTransition("*",                 "MissionStart",         "*")              -- Tanker is on station and ready to refuel.
  
  self.missioncounter=0
  
  self.lid=string.format("TANKERGROUP %s | ", groupname)
  
  --[[
  BASE:TraceOn()
  BASE:TraceLevel(3)
  BASE:TraceClass(self.ClassName)
  ]]
  
  env.info("FF NEW Tanker!")
  
  
  -- Call status update.
  -- TODO: WARNING, if the call is delayed, it is NOT executed!
  self:FlightStatus()
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add mission for tanker.
-- @param #TANKERGROUP self
-- @param Core.Zone#ZONE Zone The mission zone. Orbit is picked at a random location.
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Distance Length of the race-track pattern leg in NM.
-- @param #number Speed Orbit speed in knots.
-- @return #TANKERGROUP.Mission The mission table.
function TANKERGROUP:AddMission(Zone, Altitude, Distance, Speed)

  -- Increase mission counter.
  self.missioncounter=self.missioncounter+1
  
  -- Make mission table.
  local mission={} --#TANKERGROUP.Mission  
  mission.zone=Zone
  mission.mid=self.missioncounter
  mission.altitude=UTILS.FeetToMeters(Altitude or 10000)
  mission.distance=UTILS.NMToMeters(Distance or 25)
  mission.name="Aerial Refueling"
  mission.speed=UTILS.KnotsToMps(Speed or 280)
  mission.heading=270
  mission.tid=nil

  -- Add mission to queue.
  table.insert(self.Qmissions, mission)
  
  self:I(self.lid..string.format("Added mission"))
  
  return mission
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "TankerStatus" event.
-- @param #TANKERGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TANKERGROUP:onafterFlightStatus(From, Event, To)

  -- First call flight status.
  self:GetParent(self).onafterFlightStatus(self, From, Event, To)

  env.info("FF Tanker status!")
  env.info(string.format("FF current wp=%s", tostring(self.currentwp)))

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- First check if group is alive?
  if self.group and self.group:IsAlive()==true and not self.currentmission then
  
    local mission=self:_GetNextMission()
    
    if mission then
      
      env.info("FF starting mission")
      self:MissionStart(mission)
      
    end
  end
  
  -- Current mission name.
  local mymission=self.currentmission and self.currentmission.name or "N/A"
  
  local text=string.format("Tanker Status %s: Mission=%s (%d)", fsmstate, mymission, #self.Qmissions)
  self:I(self.lid..text)
  
  self:__FlightStatus(-30)
end

--- On after "MissionStart" event.
-- @param #TANKERGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #TANKERGROUP.Mission Mission The mission table.
function TANKERGROUP:onafterMissionStart(From, Event, To, Mission)

  -- TODO: figure out in which state the AC is in.
  -- Cound be:
  -- * late activated
  -- * late activated and uncontrolled
  -- * parking cold
  -- * parking hot
  -- * on the runway
  -- * in air 

  if self:IsInUtero() then
  
  elseif self:IsSpawned() then
  
  elseif self:IsParking() then
  
  end
  
  self.currentmission=Mission

  --
  self:RouteToMission(Mission)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MISC functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get next mission.
-- @param #TANKERGROUP self
-- @return #TANKERGROUP.Mission Next mission or *nil*.
function TANKERGROUP:_GetNextMission()

  if #self.Qmissions==0 then
    return nil
  end

  --TODO: Sort wrt start time and priority.

  local mission=self.Qmissions[1]

  return mission
end

--- Route group to mission. Also sets the 
-- @param #TANKERGROUP self
-- @param #TANKERGROUP.Mission mission The mission table.
-- @return #TANKERGROUP.Mission Next mission or *nil*.
function TANKERGROUP:RouteToMission(mission)

  local Coordinate=mission.zone:GetRandomCoordinate():SetAltitude(mission.altitude, true)
  
  local CoordRaceTrack=Coordinate:Translate(mission.distance, mission.heading, true)

  self:AddWaypointAir(Coordinate, nil, self.speedmax*0.8)
  
  local taskorbit=self.group:TaskOrbit(Coordinate, mission.altitude, mission.speed, CoordRaceTrack)
  
  self:AddTaskWaypoint(taskorbit, 1, "Mission Refuel", 10, mission.duration)

end

