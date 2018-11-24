--- **Functional** - (R2.5) - Carrier recovery tanker.
-- 
-- Tanker aircraft flying a racetrack pattern overhead an aircraft carrier.
--
-- Features:
--
--    * Regular pattern update with respect to carrier positon.
--    * Automatic respawning when tanker runs out of fuel for 24/7 operations.
--    * Tanker can be spawned cold or hot on the carrier or at any other airbase or directly in air.
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
-- @field #boolean Debug Debug mode.
-- @field Wrapper.Unit#UNIT carrier The carrier the helo is attached to.
-- @field #string carriertype Carrier type.
-- @field #string tankergroupname Name of the late activated tanker template group.
-- @field Wrapper.Group#GROUP tanker Tanker group.
-- @field Wrapper.Airbase#AIRBASE airbase The home airbase object of the tanker. Normally the aircraft carrier.
-- @field Core.Radio#BEACON beacon Tanker TACAN beacon.
-- @field #number TACANchannel TACAN channel. Default 1.
-- @field #string TACANmode TACAN mode, i.e. "X" or "Y". Default "Y".
-- @field #string TACANmorse TACAN morse code. Three letters identifying the TACAN station. Default "TKR".
-- @field #boolean TACANon If true, TACAN is automatically activated. If false, TACAN is disabled.
-- @field #number speed Tanker speed when flying pattern.
-- @field #number altitude Tanker orbit pattern altitude.
-- @field #number distStern Race-track distance astern.
-- @field #number distBow Race-track distance bow.
-- @field #number dTupdate Time interval for updating pattern position wrt new tanker position.
-- @field #number Tupdate Last time the pattern was updated.
-- @field #number takeoff Takeoff type (cold, hot, air).
-- @field #number lowfuel Low fuel threshold in percent.
-- @field #boolean respawn If true, tanker be respawned (default). If false, no respawning will happen.
-- @field #boolean respawninair If true, tanker will always be respawned in air. This has no impact on the initial spawn setting.
-- @field #boolean uncontrolledac If true, use and uncontrolled tanker group already present in the mission.
-- @field DCS#Vec3 orientation Orientation of the carrier. Used to monitor changes and update the pattern if heading changes significantly.
-- @field Core.Point#COORDINATE position Positon of carrier. Used to monitor if carrier significantly changed its position and then update the tanker pattern.
-- @extends Core.Fsm#FSM

--- Recovery Tanker.
--
-- ===
--
-- ![Banner Image](..\Presentations\RECOVERYTANKER\RecoveryTanker_Main.jpg)
--
-- # Recovery Tanker
--
-- A recovery tanker acts as refueling unit flying overhead an aircraft carrier in order to supply incoming flights with gas if necessary.
-- 
-- # Simple Script
-- 
-- In the mission editor you have to set up a carrier unit, which will act as "mother". In the following, this unit will be named "USS Stennis".
-- 
-- Secondly, you need to define a recovery tanker group in the mission editor and set it to "LATE ACTIVATED". The name of the group we'll use is "Texaco".
-- 
-- The basic script is very simple and consists of only two lines. 
-- 
--      TexacoStennis=RECOVERYTANKER:New(UNIT:FindByName("USS Stennis"), "Texaco")
--      TexacoStennis:Start()
--
-- The first line will create a new RECOVERYTANKER object and the second line starts the process.
-- 
-- With this setup, the tanker will be spawned on the USS Stennis with running engines. After it takes off, it will fly a position astern of the boat and from there start its
-- pattern. This is a counter clockwise racetrack pattern at angels 6.
-- 
-- ![Banner Image](..\Presentations\RECOVERYTANKER\RecoveryTanker_Pattern.jpg)
-- 
-- The "downwind" leg of the pattern is normally used for refueling.
-- 
-- Once the tanker runs out of fuel itself, it will return to the carrier and be respawned.
-- 
-- # Fine Tuning
-- 
-- Several parameters can be customized by the mission designer.
-- 
-- ## Adjusting the Takeoff Type
-- 
-- By default, the tanker is spawned with running engies on the carrier. The mission designer has set option to set the take off type via the @{#RECOVERYTANKER.SetTakeoff} function.
-- Or via shortcuts
-- 
--    * @{#RECOVERYTANKER.SetTakeoffHot}(): Will set the takeoff to hot, which is also the default.
--    * @{#RECOVERYTANKER.SetTakeoffCold}(): Will set the takeoff type to cold, i.e. with engines off.
--    * @{#RECOVERYTANKER.SetTakeoffAir}(): Will set the takeoff type to air, i.e. the tanker will be spawned in air relatively far behind the carrier.  
-- 
-- For example,
--      TexacoStennis=RECOVERYTANKER:New(UNIT:FindByName("USS Stennis"), "Texaco")
--      TexacoStennis:SetTakeoffAir()
--      TexacoStennis:Start()
-- will spawn the tanker several nautical miles astern the carrier. From there it will start its pattern.
-- 
-- Spawning in air is not as realsitic but can be useful do avoid DCS bugs and shortcomings like aircraft crashing into each other on the flight deck.
-- 
-- **Note** that when spawning in air is set, the tanker will also not return to the boat, once it is out of fuel. Instead it will be respawned directly in air.
-- 
-- If only the first spawning should happen on the carrier, one use the @{#RECOVERYTANKER.SetRespawnInAir}() function to command that all subsequent spawning
-- will happen in air.
-- 
-- If the helo should no be respawned at all, one can set @{#RECOVERYTANKER.SetRespawnOff}().
-- 
-- ## Adjusting the Pattern
-- 
-- The racetrack pattern parameters can be fine tuned via the following functions:
-- 
--    * @{#RECOVERYTANKER.SetAltitude}(*altitude*), where *altitude* is the pattern altitude in feet. Default 6000 ft.
--    * @{#RECOVERYTANKER.SetSpeed}(*speed*), where *speed* is the pattern speed in knots. Default is 272 knots.
--    * @{#RECOVERYTANKER.SetRacetrackDistances}(*distbow*, *diststern*), where *distbow* and *diststern* are the distances ahead and astern the boat, respectively.
--
-- @field #RECOVERYTANKER
RECOVERYTANKER = {
  ClassName       = "RECOVERYTANKER",
  Debug           = true,
  carrier         = nil,
  carriertype     = nil,
  tankergroupname = nil,
  tanker          = nil,
  airbase         = nil,
  beacon          = nil,
  TACANchannel    = nil,
  TACANmode       = nil,
  TACANmorse      = nil,
  TACANon         = nil,
  altitude        = nil,
  speed           = nil,
  distStern       = nil,
  distBow         = nil,
  dTupdate        = nil,
  Tupdate         = nil,
  takeoff         = nil,
  lowfuel         = nil,
  respawn         = nil,
  respawninair    = nil,
  uncontrolledac  = nil,
  orientation     = nil,
  position        = nil,
}

--- Class version.
-- @field #string version
RECOVERYTANKER.version="0.9.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Is alive check for tanker.
-- TODO: Trace functions self:T instead of self:I for less output.
-- TODO: Make pattern update parameters (distance, orientation) input parameters.
-- TODO: Write documenation.
-- DONE: Add FSM event for pattern update.
-- DONE: Smarter pattern update function. E.g. (small) zone around carrier. Only update position when carrier leaves zone or changes heading?
-- DONE: Set AA TACAN.
-- DONE: Add refueling event/state.
-- DONE: Possibility to add already present/spawned aircraft, e.g. for warehouse.

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
  
  -- Save self in static object. Easier to retrieve later.
  self.carrier:SetState(self.carrier, "RECOVERYTANKER", self)
  
  -- Init default parameters.
  self:SetPatternUpdateInterval()
  self:SetAltitude()
  self:SetSpeed()
  self:SetRacetrackDistances(6, 8)
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffAir()
  self:SetLowFuelThreshold()
  self:SetRespawnOnOff()
  self:SetTACAN()

  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",         "Running")        -- Start the FSM.
  self:AddTransition("*",             "Refuel",        "Refueling")      -- Tanker starts to refuel.
  self:AddTransition("*",             "Run",           "Running")        -- Tanker starts normal operation again.
  self:AddTransition("Running",       "RTB",           "Returning")      -- Tanker is returning to base (for fuel).
  self:AddTransition("*",             "Status",        "*")              -- Status update.
  self:AddTransition("Running",       "PatternUpdate", "*")              -- Update pattern wrt to carrier.
  self:AddTransition("*",             "Stop",          "Stopped")        -- Stop the FSM.


  --- Triggers the FSM event "Start" that starts the recovery tanker. Initializes parameters and starts event handlers.
  -- @function [parent=#RECOVERYTANKER] Start
  -- @param #RECOVERYTANKER self

  --- Triggers the FSM event "Start" that starts the recovery tanker after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#RECOVERYTANKER] __Start
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Refuel" when the tanker is refueling another aircraft.
  -- @function [parent=#RECOVERYTANKER] Refuel
  -- @param #RECOVERYTANKER self
  -- @param Wrapper.Unit#UNIT receiver Unit receiving fuel from the tanker.

  --- Triggers delayed the FSM event "Refuel" when the tanker is refueling another aircraft.
  -- @function [parent=#RECOVERYTANKER] __Refuel
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Unit#UNIT receiver Unit receiving fuel from the tanker.


  --- Triggers the FSM event "Run". Simply puts the group into "Running" state, e.g. after refueling ended.
  -- @function [parent=#RECOVERYTANKER] Run
  -- @param #RECOVERYTANKER self

  --- Triggers delayed the FSM event "Run". Simply puts the group into "Running" state, e.g. after refueling ended.
  -- @function [parent=#RECOVERYTANKER] __Run
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "RTB" that sends the tanker home.
  -- @function [parent=#RECOVERYTANKER] RTB
  -- @param #RECOVERYTANKER self
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase where the tanker should return to.

  --- Triggers the FSM event "RTB" that sends the tanker home after a delay.
  -- @function [parent=#RECOVERYTANKER] __RTB
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase where the tanker should return to.


  --- Triggers the FSM event "Status" that updates the tanker status.
  -- @function [parent=#RECOVERYTANKER] Status
  -- @param #RECOVERYTANKER self

  --- Triggers the delayed FSM event "Status" that updates the tanker status.
  -- @function [parent=#RECOVERYTANKER] __Status
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "PatternUpdate" that updates the pattern of the tanker wrt to the carrier position.
  -- @function [parent=#RECOVERYTANKER] PatternUpdate
  -- @param #RECOVERYTANKER self

  --- Triggers the delayed FSM event "PatternUpdate" that updates the pattern of the tanker wrt to the carrier position.
  -- @function [parent=#RECOVERYTANKER] __PatternUpdate
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


--- Enable respawning of tanker. Note that this is the default behaviour. 
-- @param #RECOVERYTANKER self 
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRespawnOn()
  self.respawn=true
  return self
end

--- Disable respawning of tanker.
-- @param #RECOVERYTANKER self 
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRespawnOff()
  self.respawn=false
  return self
end

--- Set whether tanker shall be respawned or not.
-- @param #RECOVERYTANKER self
-- @param #boolean switch If true (or nil), tanker will be respawned. If false, tanker will not be respawned. 
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRespawnOnOff(switch)
  if switch==nil or switch==true then
    self.respawn=true
  else
    self.respawn=false
  end
  return self
end

--- Tanker will be respawned in air, even it was initially spawned on the carrier.
-- So only the first spawn will be on the carrier while all subsequent spawns will happen in air.
-- This allows for undisrupted operations and less problems on the carrier deck.
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRespawnInAir()
  self.respawninair=true
  return self
end

--- Use an uncontrolled aircraft already present in the mission rather than spawning a new tanker as initial recovery thanker.
-- This can be useful when interfaced with, e.g., a warehouse.
-- The group name is the one specified in the @{#RECOVERYTANKER.New} function.
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetUseUncontrolledAircraft()
  self.uncontrolledac=true
  return self
end


--- Disable automatic TACAN activation.
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self 
function RECOVERYTANKER:SetTACANoff()
  self.TACANon=false
  return self
end

--- Set TACAN channel of tanker.
-- @param #RECOVERYTANKER self
-- @param #number channel TACAN channel. Default 1.
-- @param #string mode TACAN mode, i.e. "X" or "Y". Default "Y".
-- @param #string morse TACAN morse code identifier. Three letters. Default "TKR".
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetTACAN(channel, mode, morse)
  self.TACANchannel=channel or 1
  self.TACANmode=mode or "Y"
  self.TACANmorse=morse or "TKR"
  self.TACANon=true
  return self
end

--- Check if tanker is currently returning to base.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker is returning to base. 
function RECOVERYTANKER:IsReturning()
  return self:is("Returning")
end

--- Check if tanker is currently operating.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker is operating. 
function RECOVERYTANKER:IsRunning()
  return self:is("Running")
end

--- Check if tanker is currently refueling another aircraft.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker is refueling. 
function RECOVERYTANKER:IsRefueling()
  return self:is("Refueling")
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
  self:HandleEvent(EVENTS.Refueling,     self._RefuelingStart)  --Need explcit functions sice OnEventRefueling and OnEventRefuelingStop did not hook.
  self:HandleEvent(EVENTS.RefuelingStop, self._RefuelingStop)
  --self:HandleEvent(EVENTS.Crash)
  
  -- Spawn tanker.
  local Spawn=SPAWN:New(self.tankergroupname):InitUnControlled(false)
  
  -- Spawn on carrier.
  if self.takeoff==SPAWN.Takeoff.Air then
  
    -- Carrier heading
    local hdg=self.carrier:GetHeading()
    
    -- Spawn distance behind the carrier.
    local dist=UTILS.NMToMeters(20)
    
    -- Coordinate behind the carrier
    local Carrier=self.carrier:GetCoordinate():SetAltitude(self.altitude):Translate(-dist, hdg)
    
    -- Orientation of spawned group.
    Spawn:InitHeading(hdg)
    
    -- Spawn at coordinate.
    self.tanker=Spawn:SpawnFromCoordinate(Carrier)
    
    -- Initial route.
    self:_InitRoute(15, 1)
  else
  
    -- Check if an uncontrolled tanker group was requested.
    if self.useuncontrolled then
    
      -- Use an uncontrolled aircraft group.
      self.tanker=GROUP:FindByName(self.tankergroupname)
      
      if self.tanker:IsAlive() then
      
        -- Start uncontrolled group.
        self.tanker:StartUncontrolled()
        
      else
        -- No group by that name!
        self:E(string.format("ERROR: No uncontrolled (alive) tanker group with name %s could be found!", self.tankergroupname))
        return
      end
      
    else
    
      -- Spawn tanker at airbase.
      self.tanker=Spawn:SpawnAtAirbase(self.airbase, self.takeoff)
      
    end
    
    -- Initialize route.
    self:_InitRoute(15, 1)
    
  end
  
  -- Create tanker beacon.
  if self.TACANon then
    self:_ActivateTACAN(2)
  end
  
  -- Get initial orientation and position of carrier.
  self.orientation=self.carrier:GetOrientationX()
  self.position=self.carrier:GetCoordinate()

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
  local text=string.format("Recovery tanker %s: state=%s fuel=%.1f", self.tanker:GetName(), self:GetState(), fuel)
  self:I(text)
  
  -- Check if tanker is running and not RTBing or refueling.
  if self:IsRunning() then
  
    -- Check fuel.
    if fuel<self.lowfuel then
    
      -- Check if spawn in air is activated.
      if self.takeoff==SPAWN.Takeoff.Air or self.respawninair then
      
        -- Check that respawn should happen.
        if self.respawn then
      
          -- Debug message.
          local text=string.format("Respawning tanker %s.", self.tanker:GetName())
          self:I(text)  
          
          -- Respawn tanker.
          self.tanker:InitHeading(self.tanker:GetHeading())
          self.tanker=self.tanker:Respawn(nil, true)
          
          -- Create tanker beacon and activate TACAN.
          if self.TACANon then
            self:_ActivateTACAN(3)
          end
          
          -- Update Pattern in 2 seconds. Need to give a bit time so that the respawned group is in the game.
          self:__PatternUpdate(2)
        end
        
      else

        -- Send tanker home if fuel runs low.
        self:RTB(self.airbase)
                
      end
                
    else
    
      if self.Tupdate then
      
        --Time since last pattern update.
        local dt=time-self.Tupdate
        
        -- Check if pattern needs to be updated.
        local updatepattern=self:_CheckPatternUpdate(dt)
        
        -- Update pattern.
        if updatepattern then
          self:PatternUpdate()
        end
        
      end
    end
    
  end
  
  -- Call status again in 1 minute.
  self:__Status(-60)
end

--- On after "PatternUpdate" event. Updates the racetrack pattern of the tanker wrt the carrier position.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterPatternUpdate(From, Event, To)

  -- Debug message.
  self:I(string.format("Updating recovery tanker %s orbit.", self.tanker:GetName()))
    
  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  -- Define race-track pattern.
  local p0=self.tanker:GetCoordinate():Translate(2000, self.tanker:GetHeading())
  local p1=Carrier:SetAltitude(self.altitude):Translate(self.distStern, hdg)
  local p2=Carrier:SetAltitude(self.altitude):Translate(self.distBow, hdg)
  
  -- Set orbit task.
  local taskorbit=self.tanker:TaskOrbit(p1, self.altitude, self.speed, p2)
  
  -- Debug markers.
  if self.Debug then
    p0:MarkToAll("Waypoint P0 " ..self.tanker:GetName())
    p1:MarkToAll("Racetrack P1 "..self.tanker:GetName())
    p2:MarkToAll("Racetrack P2 "..self.tanker:GetName())
    self.tanker:SmokeRed()
  end
    
  -- Waypoints array.
  local wp={}
    
  -- New waypoint with orbit pattern task.
  wp[1]=self.tanker:GetCoordinate():WaypointAirTurningPoint(nil , self.speed, {}, "Current Position")
  wp[2]=p0:WaypointAirTurningPoint(nil, self.speed, {taskorbit}, "Tanker Orbit")
  
  -- Initialize WP and route tanker.
  self.tanker:WayPointInitialize(wp)
  
  -- Task combo.
  local tasktanker = self.tanker:EnRouteTaskTanker()
  local taskroute  = self.tanker:TaskRoute(wp)
  -- Note that tasktanker has to come first. Otherwise it does not work!
  local taskcombo  = self.tanker:TaskCombo({tasktanker, taskroute})

  -- Set task.
  self.tanker:SetTask(taskcombo, 1)
  
  -- Set update time.
  self.Tupdate=timer.getTime()
end

--- On after "RTB" event. Send tanker back to carrier.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase where the tanker should return to.
function RECOVERYTANKER:onafterRTB(From, Event, To, airbase)

  -- Default is the home base.
  airbase=airbase or self.airbase

  -- Debug message.
  local text=string.format("Tanker %s returning to airbase %s.", self.tanker:GetName(), airbase:GetName())
  self:I(text)
  
  -- Waypoint array.
  local wp={}
  
  -- Set landing waypoint.
  wp[1]=self.tanker:GetCoordinate():WaypointAirTurningPoint(nil, 300, {}, "Current Position")
  wp[2]=airbase:GetCoordinate():WaypointAirLanding(300, airbase, nil, "Land at airbase")
  
  -- Initialize WP and route tanker.
  self.tanker:WayPointInitialize(wp)
  
  -- Set task.
  self.tanker:Route(wp, 1)
end

--- On after Stop event. Unhandle events and stop status updates. 
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterStop(From, Event, To)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.Refueling)
  self:UnHandleEvent(EVENTS.RefuelingStop)
  --self:UnHandleEvent(EVENTS.Land)
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
  
  -- Check if group is alive and should be respawned.
  if group:IsAlive() and self.respawn then
  
    -- Group name. When spawning it will have #001 attached.
    local groupname=group:GetName()
    
    if groupname:match(self.tankergroupname) then
  
      -- Debug info.
      self:I(string.format("Respawning recovery tanker group %s.", group:GetName()))
      
      -- Respawn tanker.
      self.tanker=group:RespawnAtCurrentAirbase()
      
      -- Create tanker beacon and activate TACAN.
      if self.TACANon then
        self:_ActivateTACAN(2)
      end

      -- Initial route.
      self:_InitRoute(15, 1)
    end
    
  end
end

--- Event handler for refueling started.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:_RefuelingStart(EventData)

  if EventData and EventData.IniUnit and EventData.IniUnit:IsAlive() then
  
    -- Unit receiving fuel.
    local unit=EventData.IniUnit
    
    -- Get distance to tanker to check that unit is receiving fuel from this tanker.
    local dist=unit:GetCoordinate():Get2DDistance(self.tanker:GetCoordinate())
    
    -- If distance > 100 meters, this should be another tanker.
    if dist>100 then
      return
    end
  
    -- Info message.
    self:I(string.format("Recovery tanker %s started refueling unit %s", self.tanker:GetName(), unit:GetName()))
    
    -- FMS state "Refueling".
    self:Refuel(unit)
  
  end

end

--- Event handler for refueling stopped.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:_RefuelingStop(EventData)

  if EventData and EventData.IniUnit and EventData.IniUnit:IsAlive() then
  
    -- Unit receiving fuel.
    local unit=EventData.IniUnit
    
    -- Get distance to tanker to check that unit is receiving fuel from this tanker.
    local dist=unit:GetCoordinate():Get2DDistance(self.tanker:GetCoordinate())
    
    -- If distance > 100 meters, this should be another tanker.
    if dist>100 then
      return
    end
  
    -- Info message.
    self:I(string.format("Recovery tanker %s stopped refueling unit %s", self.tanker:GetName(), unit:GetName()))
    
    -- FSM state "Running".
    self:Run()
  end

end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MISC functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Task function to
-- @param #RECOVERYTANKER self
function RECOVERYTANKER:_InitPatternTaskFunction()

  -- Name of the warehouse (static) object.
  local carriername=self.carrier:GetName()

  -- Task script.
  local DCSScript = {}
  DCSScript[#DCSScript+1] = string.format('local mycarrier = UNIT:FindByName(\"%s\") ', carriername)              -- The carrier unit that holds the self object.
  DCSScript[#DCSScript+1] = string.format('local mytanker  = mycarrier:GetState(mycarrier, \"RECOVERYTANKER\") ') -- Get the RECOVERYTANKER self object.
  DCSScript[#DCSScript+1] = string.format('mytanker:PatternUpdate()')                                             -- Call the function, e.g. mytanker.(self)

  -- Create task.
  local DCSTask = CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))

  return DCSTask
end


--- Init waypoint after spawn.
-- @param #RECOVERYTANKER self
-- @param #number dist Distance [NM] of initial waypoint astern carrier. Default 15 NM.
-- @param #number delay Delay before routing in seconds. Default 1 second.
function RECOVERYTANKER:_InitRoute(dist, delay)

  -- Defaults.
  dist=UTILS.NMToMeters(dist or 15)
  delay=delay or 1
  
  -- Debug message.
  self:I(string.format("Initializing route for recovery tanker %s.", self.tanker:GetName()))
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- First waypoint is ~15 NM behind the boat.
  local p=Carrier:Translate(-dist, hdg):SetAltitude(self.altitude)
  
  -- Debug mark.
  if self.Debug then
    p:MarkToAll(string.format("Init WP: alt=%d ft, speed=%d kts", UTILS.MetersToFeet(self.altitude), UTILS.MpsToKnots(self.speed)))
  end
  
  -- Task to update pattern when wp 2 is reached.
  local task=self:_InitPatternTaskFunction()  

  -- Waypoints.
  local wp={}
  if self.takeoff==SPAWN.Takeoff.Air then
    wp[#wp+1]=self.tanker:GetCoordinate():SetAltitude(self.altitude):WaypointAirTurningPoint(nil, self.speed, {}, "Spawn Position")   
  else
    wp[#wp+1]=Carrier:WaypointAirTakeOffParking()
  end
  wp[#wp+1]=p:WaypointAirTurningPoint(nil, self.speed, {task}, "Begin Pattern")
    
  -- Set route.
  self.tanker:Route(wp, delay)
  
  -- No update yet, wait until the function is called (avoids checks if pattern update is needed).
  self.Tupdate=nil
end

--- Check if heading or position have changed significantly.
-- @param #RECOVERYTANKER self
-- @param #number dt Time since last update in seconds.
-- @return #boolean If true, heading and/or position have changed more than 10 degrees or 10 km, respectively.
function RECOVERYTANKER:_CheckPatternUpdate(dt)

  -- Assume no update necessary.
  local update=false

  -- Get current position and orientation of carrier.
  local pos=self.carrier:GetCoordinate()
  local vC=self.carrier:GetOrientationX()
  
  -- Check if tanker is running and last updated is more than 10 minutes ago.
  if self:IsRunning() and dt>10*60 then

    -- Last saved orientation of carrier.
    local vP=self.orientation
    
    -- We only need the X-Z plane.
    vC.y=0 ; vP.y=0
    
    -- Get angle between the two orientation vectors in rad.
    local rhdg=math.deg(math.acos(UTILS.VecDot(vC,vP)/UTILS.VecNorm(vC)/UTILS.VecNorm(vP)))
  
    -- Check if orientation changed.
    -- TODO: make 5 deg input variable.
    if math.abs(rhdg)>5 then
      self:I(string.format("Carrier heading changed by %d degrees. Updating recovery tanker pattern.", rhdg))
      update=true
    end
    
    -- Get distance to saved position.
    local dist=pos:Get2DDistance(self.position)
    
    -- Check if carrier moved more than 10 km.
    -- TODO: make 10 km input variable.
    if dist/1000>10 then
      self:I(string.format("Carrier position changed by %.1f km. Updating recovery tanker pattern.", dist/1000))
      update=true
    end
    
  end
  
  -- If pattern is updated then update orientation AND positon.
  -- But only if last update is less then 10 minutes ago.
  if update then
    self.orientation=vC
    self.position=pos
  end
    
  return update
end

--- Activate TACAN of tanker.
-- @param #RECOVERYTANKER self
-- @param #number delay Delay in seconds.
function RECOVERYTANKER:_ActivateTACAN(delay)

  if delay and delay>0 then
  
    -- Schedule TACAN activation.
    SCHEDULER:New(nil,self._ActivateTACAN, {self}, delay)
    
  else

    -- Get tanker unit.
    local unit=self.tanker:GetUnit(1)
    
    -- Check if unit is alive.
    if unit:IsAlive() then
    
      -- Debug message.
      self:I(string.format("Activating recovery tanker TACAN beacon: channel=%d mode=%s, morse=%s.", self.TACANchannel, self.TACANmode, self.TACANmorse))
    
      -- Create a new beacon and activate TACAN.
      self.beacon=BEACON:New(unit)
      self.beacon:ActivateTACAN(self.TACANchannel, self.TACANmode, self.TACANmorse, true)
            
    else
      self:E("ERROR: Recovery tanker is not alive!")
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

