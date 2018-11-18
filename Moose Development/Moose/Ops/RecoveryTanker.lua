--- **Functional** - (R2.5) - Carrier recovery tanker.
-- 
-- Tanker aircraft flying a racetrack pattern overhead an aircraft carrier.
--
-- Features:
--
--    * Regular pattern update with respect to carrier positon.
--    * Automatic respawning when tanker runs out of fuel.
--    * Tanker can be spawned cold or hot on the carrier or any other airbase or directly in air.
--    * Tanker can operate 24/7.
--
-- Please not that his class is work in progress and in an **alpha** stage.
--
-- ===
--
-- ### Author: **funkyfranky** 
--
-- @module Ops.RecoveryTanker
-- @image MOOSE.JPG

--- RECOVERYTANKER class.
-- @type RECOVERYTANKER
-- @field #string ClassName Name of the class.
-- @field Wrapper.Unit#UNIT carrier The carrier the helo is attached to.
-- @field #string carriertype Carrier type.
-- @field #string tankergroupname Name of the late activated tanker template group.
-- @field Wrapper.Group#GROUP tanker Tanker group.
-- @field Wrapper.Airbase#AIRBASE airbase The home airbase object of the tanker. Normally the aircraft carrier.
-- @field #number speed Tanker speed when flying pattern.
-- @field #number altitude Tanker orbit pattern altitude.
-- @field #number distStern Race-track distance astern.
-- @field #number distBow Race-track distance bow.
-- @field #number dTupdate Time interval for updating pattern position wrt new tanker position.
-- @field #number Tupdate Last time the pattern was updated.
-- @field #number takeoff Takeoff type (cold, hot, air).
-- @field #number lowfuel Low fuel threshold in percent.
-- @extends Core.Fsm#FSM

--- Recovery Tanker.
--
-- ===
--
-- ![Banner Image](..\Presentations\RECOVERYTANKER\RecoveryTanker_Main.jpg)
--
-- # Recovery Tanker
--
-- bla bla
--
-- @field #RECOVERYTANKER
RECOVERYTANKER = {
  ClassName       = "RECOVERYTANKER",
  carrier         = nil,
  carriertype     = nil,
  tankergroupname = nil,
  tanker          = nil,
  airbase         = nil,
  altitude        = nil,
  speed           = nil,
  distStern       = nil,
  distBow         = nil,
  dTupdate        = nil,
  Tupdate         = nil,
  takeoff         = nil,
  lowfuel         = nil,
}


--- Class version.
-- @field #string version
RECOVERYTANKER.version="0.9.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Possibility to add already present/spawned aircraft, e.g. for warehouse. 
-- TODO: Write documenation.
-- TODO: Smarter pattern update function. E.g. (small) zone around carrier. Only update position when carrier leaves zone or changes heading?
-- TODO: Maybe rework pattern update implementation altogether to make it smoother. 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create new RECOVERYTANKER object.
-- @param #RECOVERYTANKER self
-- @param Wrapper.Unit#UNIT carrierunit Carrier unit.
-- @param #string tankergroupname Name of the late activated tanker aircraft template group.
-- @return #RECOVERYTANKER RECOVERYTANKER object.
function RECOVERYTANKER:New(carrierunit, tankergroupname)

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #RECOVERYTANKER
  
  if type(carrierunit)=="string" then
    self.carrier=UNIT:FindByName(carrierunit)
  else
    self.carrier=carrierunit
  end
  
  -- Carrier type.
  self.carriertype=self.carrier:GetTypeName()
  
  -- Tanker group name.
  self.tankergroupname=tankergroupname
  
  -- Default parameters.
  self:SetPatternUpdateInterval()
  self:SetAltitude()
  self:SetSpeed()
  self:SetRacetrackDistances(6, 8)
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffAir()
  self:SetLowFuelThreshold()

  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("Running",       "RTB",        "Returning")
  self:AddTransition("Running",       "Status",     "*")
  self:AddTransition("Returning",     "Status",     "*")
  self:AddTransition("Running",       "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the recovery tanker. Initializes parameters and starts event handlers.
  -- @function [parent=#RECOVERYTANKER] Start
  -- @param #RECOVERYTANKER self

  --- Triggers the FSM event "Start" that starts the recovery tanker after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#RECOVERYTANKER] __Start
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "RTB" that sends the tanker home.
  -- @function [parent=#RECOVERYTANKER] RTB
  -- @param #RECOVERYTANKER self

  --- Triggers the FSM event "RTB" that sends the tanker home after a delay.
  -- @function [parent=#RECOVERYTANKER] __RTB
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop" that stops the recovery tanker. Event handlers are stopped.
  -- @function [parent=#RECOVERYTANKER] Stop
  -- @param #RECOVERYTANKER self

  --- Triggers the FSM event "Stop" that stops the recovery tanker after a delay. Event handlers are stopped.
  -- @function [parent=#RECOVERYTANKER] __Stop
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the speed the tanker flys in its orbit pattern.
-- @param #RECOVERYTANKER self
-- @param #number speed Tanker speed in knots. Default 272 knots.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetSpeed(speed)
  self.speed=UTILS.KnotsToMps(speed or 272)
  return self
end

--- Set orbit pattern altitude of the tanker.
-- @param #RECOVERYTANKER self
-- @param #number altitude Tanker altitude in feet. Default 6000 ft.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetAltitude(altitude)
  self.altitude=UTILS.FeetToMeters(altitude or 6000)
  return self
end

--- Set race-track distances.
-- @param #RECOVERYTANKER self
-- @param #number distbow Distance [NM] in front of the carrier. Default 6 NM.
-- @param #number diststern Distance [NM] behind the carrier. Default 8 NM.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRacetrackDistances(distbow, diststern)
  self.distBow=UTILS.NMToMeters(distbow or 6)
  self.distStern=-UTILS.NMToMeters(diststern or 8)
  return self
end

--- Set pattern update interval. Note that this update causes a slight disruption in the race track pattern.
-- Therefore, the interval should be as long as possible but short enough to keep the tanker overhead the carrier.
-- @param #RECOVERYTANKER self
-- @param #number interval Interval in minutes. Default is every 30 minutes.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateInterval(interval)
  self.dTupdate=(interval or 30)*60
  return self
end

--- Set low fuel state of tanker. When fuel is below this threshold, the tanker will RTB or be respawned if takeoff type is in air.
-- @param #RECOVERYTANKER self
-- @param #number threshold Low fuel threshold in percent. Default 10.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetLowFuelThreshold(threshold)
  self.lowfuel=threshold or 10
  return self
end

--- Set home airbase of the tanker. Default is the carrier.
-- @param #RECOVERYTANKER self
-- @param Wrapper.Airbase#AIRBASE airbase
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetHomeBase(airbase)
  self.airbase=airbase
  return self
end

--- Set takeoff type.
-- @param #RECOVERYTANKER self
-- @param #number takeofftype Takeoff type.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetTakeoff(takeofftype)
  self.takeoff=takeofftype
  return self
end

--- Set takeoff with engines running (hot).
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetTakeoffHot()
  self:SetTakeoff(SPAWN.Takeoff.Hot)
  return self
end

--- Set takeoff with engines off (cold).
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetTakeoffCold()
  self:SetTakeoff(SPAWN.Takeoff.Cold)
  return self
end

--- Set takeoff in air at pattern altitude 30 NM behind the carrier.
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetTakeoffAir()
  self:SetTakeoff(SPAWN.Takeoff.Air)
  return self
end


--- Check if tanker is returning to base.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker is returning to base. 
function RECOVERYTANKER:IsReturning()
  return self:is("Returning")
end

--- Check if tanker is operating.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker is operating. 
function RECOVERYTANKER:IsRunning()
  return self:is("Running")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the warehouse. Addes event handlers and schedules status updates of reqests and queue.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterStart(From, Event, To)

  -- Info on start.
  self:I(string.format("Starting Recovery Tanker v%s for carrier unit %s of type %s for tanker group %s.", RECOVERYTANKER.version, self.carrier:GetName(), self.carriertype, self.tankergroupname))
  
  -- Handle events.
  self:HandleEvent(EVENTS.EngineShutdown)
  --TODO: Handle event crash and respawn.
  
  -- Spawn tanker.
  local Spawn=SPAWN:New(self.tankergroupname):InitUnControlled(false)
  
  -- Spawn on carrier.
  if self.takeoff==SPAWN.Takeoff.Air then
  
    -- Carrier heading
    local hdg=self.carrier:GetHeading()
    
    local dist=UTILS.NMToMeters(20)
    
    -- Coordinate behind the carrier
    local Carrier=self.carrier:GetCoordinate():SetAltitude(self.altitude):Translate(-dist, hdg)
    
    -- Orientation of spawned group.
    Spawn:InitHeading(hdg)
    
    -- Spawn at coordinate.
    self.tanker=Spawn:SpawnFromCoordinate(Carrier)
    
    self:_InitRoute(15, 1, 2)
  else
  
    -- Spawn tanker at airbase.
    self.tanker=Spawn:SpawnAtAirbase(self.airbase, self.takeoff)
    self:_InitRoute(30, 10, 1)
    
  end  
  
  -- Init status check.
  self:__Status(10)
end

--- On after Status event. Checks player status.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterStatus(From, Event, To)

  -- Get current time.
  local time=timer.getTime()
  
  -- Get fuel of tanker.
  local fuel=self.tanker:GetFuel()*100
  local text=string.format("Tanker %s: state=%s fuel=%.1f", self.tanker:GetName(), self:GetState(), fuel)
  self:I(text)
  
  
  if self:IsRunning() then
  
    -- Check fuel.
    if fuel<self.lowfuel then
    
      -- Send tanker home if fuel runs low.
      self:RTB()
      
    else
    
      if self.Tupdate then
      
        --Time since last pattern update.
        local dt=time-self.Tupdate
        
        if dt>self.dTupdate then
          self:_PatternUpdate()
        end
        
      end
    end
    
  end
  
  -- Call status again in 1 minute.
  self:__Status(-60)
end

--- On after Stop event. Unhandle events and stop status updates. 
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterStop(From, Event, To)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  --self:UnHandleEvent(EVENTS.Land)
end

--- On before RTB event. Check if takeoff type is air and if so respawn the tanker and deny RTB transition.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, transition is allowed.
function RECOVERYTANKER:onbeforeRTB(From, Event, To)

  if self.takeoff==SPAWN.Takeoff.Air then
  
    -- Debug message.
    local text=string.format("Respawning tanker %s.", self.tanker:GetName())
    self:I(text)  
    
    -- Respawn tanker.
    self.tanker:InitHeading(self.tanker:GetHeading())
    self.tanker=self.tanker:Respawn(nil, true)
    
    -- Update Pattern in 2 seconds. Need to give a bit time so that the respawned group is in the game.
    SCHEDULER:New(nil, self._PatternUpdate, {self}, 2)
    
    -- Deny transition to RTB.
    return false
  end
  
  return true
end

--- On after RTB event. Send tanker back to carrier.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterRTB(From, Event, To)

    -- Debug message.
    local text=string.format("Tanker %s returning to airbase %s.", self.tanker:GetName(), self.airbase:GetName())
    self:I(text)
    
    local waypoints={}
    
    -- Set landingwaypoint
    local wp=self.carrier:GetCoordinate():WaypointAirLanding(300, self.airbase, nil, "Landing")
    table.insert(waypoints, wp)

    -- Initialize WP and route tanker.
    self.tanker:WayPointInitialize(waypoints)
  
    -- Set task.
    self.tanker:Route(waypoints, 1)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for engine shutdown of recovery tanker.
-- Respawn tanker group once it landed because it was out of fuel.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:OnEventEngineShutdown(EventData)

  local group=EventData.IniGroup --Wrapper.Group#GROUP
  
  if group:IsAlive() then
  
    -- Group name. When spawning it will have #001 attached.
    local groupname=group:GetName()
    
    if groupname:match(self.tankergroupname) then
  
      -- Debug info.
      self:I(string.format("Respawning recovery tanker group %s.", group:GetName()))
      
      -- Respawn tanker.
      self.tanker=group:RespawnAtCurrentAirbase()
      
      --group:StartUncontrolled(60)
      
      -- Initial route.
      self:_InitRoute()
    end
    
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ROUTE functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Init waypoint after spawn.
-- @param #RECOVERYTANKER self
-- @param #number dist Distance [NM] of initial waypoint astern carrier. Default 30 NM.
-- @param #number Tstart Time in minutes before the tanker starts its pattern. Default 10 min.
-- @param #number delay Delay before routing in seconds. Default 1 second.
function RECOVERYTANKER:_InitRoute(dist, Tstart, delay)

  -- Defaults.
  dist=UTILS.NMToMeters(dist or 30)
  Tstart=(Tstart or 10)*60
  delay=delay or 1
  
  -- Debug message.
  self:I(string.format("Initializing route for tanker %s.", self.tanker:GetName()))
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- First waypoint is 50 km behind the boat.
  local p=Carrier:Translate(-dist, hdg):SetAltitude(self.altitude)
  
  -- Debug mark
  p:MarkToAll(string.format("Init WP: alt=%d ft, speed=%d kts", UTILS.MetersToFeet(self.altitude), UTILS.MpsToKnots(self.speed)))

  -- Waypoints.
  local wp={}
  wp[1]=Carrier:WaypointAirTakeOffParking()
  wp[2]=p:WaypointAirTurningPoint(nil, self.speed, nil, "Stern")
  
  -- Set route.
  self.tanker:Route(wp, delay)
  
  -- No update yet.
  self.Tupdate=nil
  
  -- Update pattern in ~10 minutes.
  SCHEDULER:New(nil, self._PatternUpdate, {self}, Tstart)
end


--- Function to update the race-track pattern of the tanker wrt to the carrier position.
-- @param #RECOVERYTANKER self
function RECOVERYTANKER:_PatternUpdate()
    
  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  -- Define race-track pattern.
  local p1=Carrier:SetAltitude(self.altitude):Translate(self.distStern, hdg)
  local p2=Carrier:SetAltitude(self.altitude):Translate(self.distBow, hdg)
  
  -- Set orbit task.
  local taskorbit=self.tanker:TaskOrbit(p1, self.altitude, self.speed, p2)
  
  -- New waypoint.
  local p0=self.tanker:GetCoordinate():Translate(1000, self.tanker:GetHeading())
  
  -- Debug markers.
  if self.Debug then
    p0:MarkToAll("p0")
    p1:MarkToAll("p1")
    p2:MarkToAll("p2")
  end
  
  -- Debug message.
  self:I(string.format("Updating tanker %s orbit.", self.tanker:GetName()))
  
  -- Waypoints array.
  local waypoints={}
    
  -- New waypoint with orbit pattern task.
  local wp=p0:WaypointAirTurningPoint(nil, self.speed, {taskorbit}, "Tanker Orbit")      
  waypoints[1]=wp
  
  -- Initialize WP and route tanker.
  self.tanker:WayPointInitialize(waypoints)
  
  -- Task combo.
  local tasktanker = self.tanker:EnRouteTaskTanker()
  local taskroute  = self.tanker:TaskRoute(waypoints)
  local taskcombo  = self.tanker:TaskCombo({tasktanker, taskroute})

  -- Set task.
  self.tanker:SetTask(taskcombo, 1)
  
  -- Set update time.
  self.Tupdate=timer.getTime()
end
