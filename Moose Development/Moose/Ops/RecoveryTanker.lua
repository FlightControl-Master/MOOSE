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
-- @field #number Dupdate Pattern update when carrier changes its position by more than this distance (meters).
-- @field #number Hupdate Pattern update when carrier changes its heading by more than this number (degrees). 
-- @field #number dTupdate Minimum time interval in seconds before the next pattern update can happen.
-- @field #number Tupdate Last time the pattern was updated.
-- @field #number takeoff Takeoff type (cold, hot, air).
-- @field #number lowfuel Low fuel threshold in percent.
-- @field #boolean respawn If true, tanker be respawned (default). If false, no respawning will happen.
-- @field #boolean respawninair If true, tanker will always be respawned in air. This has no impact on the initial spawn setting.
-- @field #boolean uncontrolledac If true, use and uncontrolled tanker group already present in the mission.
-- @field DCS#Vec3 orientation Orientation of the carrier. Used to monitor changes and update the pattern if heading changes significantly.
-- @field Core.Point#COORDINATE position Positon of carrier. Used to monitor if carrier significantly changed its position and then update the tanker pattern.
-- @field Core.Zone#ZONE_UNIT zoneUpdate Moving zone relative to carrier. Each time the tanker is in this zone, its pattern is updated.
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
-- In the mission editor you have to set up a carrier unit, which will act as "mother". In the following, this unit will be named **"USS Stennis"**.
-- 
-- Secondly, you need to define a recovery tanker group in the mission editor and set it to **"LATE ACTIVATED"**. The name of the group we'll use is **"Texaco"**.
-- 
-- The basic script is very simple and consists of only two lines: 
-- 
--     TexacoStennis=RECOVERYTANKER:New(UNIT:FindByName("USS Stennis"), "Texaco")
--     TexacoStennis:Start()
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
-- # Options and Fine Tuning
-- 
-- Several parameters can be customized by the mission designer.
-- 
-- ## Takeoff Type
-- 
-- By default, the tanker is spawned with running engies on the carrier. The mission designer has set option to set the take off type via the @{#RECOVERYTANKER.SetTakeoff} function.
-- Or via shortcuts
-- 
--    * @{#RECOVERYTANKER.SetTakeoffHot}(): Will set the takeoff to hot, which is also the default.
--    * @{#RECOVERYTANKER.SetTakeoffCold}(): Will set the takeoff type to cold, i.e. with engines off.
--    * @{#RECOVERYTANKER.SetTakeoffAir}(): Will set the takeoff type to air, i.e. the tanker will be spawned in air relatively far behind the carrier.  
-- 
-- For example,
--     TexacoStennis=RECOVERYTANKER:New(UNIT:FindByName("USS Stennis"), "Texaco")
--     TexacoStennis:SetTakeoffAir()
--     TexacoStennis:Start()
-- will spawn the tanker several nautical miles astern the carrier. From there it will start its pattern.
-- 
-- Spawning in air is not as realsitic but can be useful do avoid DCS bugs and shortcomings like aircraft crashing into each other on the flight deck.
-- 
-- **Note** that when spawning in air is set, the tanker will also not return to the boat, once it is out of fuel. Instead it will be respawned directly in air.
-- 
-- If only the first spawning should happen on the carrier, one use the @{#RECOVERYTANKER.SetRespawnInAir}() function to command that all subsequent spawning
-- will happen in air.
-- 
-- If the helo should not be respawned at all, one can set @{#RECOVERYTANKER.SetRespawnOff}().
-- 
-- ## Pattern Parameters
-- 
-- The racetrack pattern parameters can be fine tuned via the following functions:
-- 
--    * @{#RECOVERYTANKER.SetAltitude}(*altitude*), where *altitude* is the pattern altitude in feet. Default 6000 ft.
--    * @{#RECOVERYTANKER.SetSpeed}(*speed*), where *speed* is the pattern speed in knots. Default is 272 knots.
--    * @{#RECOVERYTANKER.SetRacetrackDistances}(*distbow*, *diststern*), where *distbow* and *diststern* are the distances ahead and astern the boat, respectively.
--
-- ## TACAN
-- 
-- A TACAN beacon for the tanker can be activated via scripting, i.e. no need to do this within the mission editor.
-- 
-- The beacon is create with the @{#RECOVERYTANKER.SetTACAN}(*channel*, *mode*, *morse*) function, where *channel* is the TACAN channel (a number), *mode* the TACAN mode (either "X"
-- or "Y") and *morse* a three letter string that is send as morse code to identify the tanker:
-- 
--     TexacoStennis:SetTACAN(10, "Y", "TKR")
--     
-- will activate a TACAN beacon 10Y with more code "TKR".
-- 
-- If you do not set a TACAN beacon explicitly, it is automatically create on channel 1, mode "Y" and morse code "TKR".
-- 
-- In order to completely disable the TACAN beacon, you can use the @{#RECOVERYTANKER.SetTACANoff}() function in your script.
-- 
-- Note to self, I am not sure, if an AA TACAN station *must* be of mode "Y" in order to work. It seems that this was the case in earlier DCS versions.
-- 
-- ## Pattern Update
-- 
-- The pattern of the tanker is updated if at least one of the two following conditions apply:
-- 
--    * The aircraft carrier changes its position by more than ~10 km (see @{#RECOVERYTANKER.SetPatternUpdateDistance}) and/or
--    * The aircraft carrier changes its heading by more than 5 degrees (see @{#RECOVERYTANKER.SetPatternUpdateHeading})
-- 
-- **Note** that updating the pattern always leads to a small disruption in the perfect racetrack pattern of the tanker. This is because a new waypoint and new racetrack points
-- need to be set as DCS task. This is also the reason why the pattern is not contantly updated but rather when the position or heading of the carrier changes significantly.
--
-- The maximum update frequency is set to 15 minutes. You can adjust this by @{#RECOVERYTANKER.SetPatternUpdateInterval}.
--
-- # Finite State Model
-- 
-- The implementation uses a Finite State Model (FSM). This allows the mission designer to hook in to certain events.
-- 
--    * @{#RECOVERYTANKER.Start}: This event starts the FMS process and initialized parameters and spawns the tanker. DCS event handling is started.
--    * @{#RECOVERYTANKER.Status}: This event is called in regular intervals (~60 seconds) and checks the status of the tanker and carrier. It triggers other events if necessary.
--    * @{#RECOVERYTANKER.PatternUpdate}: This event commands the tanker to update its pattern
--    * @{#RECOVERYTANKER.RTB}: This events sends the tanker to its home base (usually the carrier). This is called once the tanker runs low on gas.
--    * @{#RECOVERYTANKER.RefuelStart}: This event is called when a tanker starts to refuel another unit.
--    * @{#RECOVERYTANKER.RefuelStop}: This event is called when a tanker stopped to refuel another unit.
--    * @{#RECOVERYTANKER.Run}: This event is called when the tanker resumes normal operations, e.g. after refueling stopped or tanker finished refueling.
--    * @{#RECOVERYTANKER.Stop}: This event stops the FSM by unhandling DCS events.
--
-- The mission designer can capture these events by RECOVERYTANKER.OnAfter*Eventname* functions, e.g. @{#RECOVERYTANKER.OnAfterPatternUpdate}.
-- 
-- # Debugging
-- 
-- In case you have problems, it is always a good idea to have a look at your DCS log file. You find it in your "Saved Games" folder, so for example in
--     C:\Users\<yourname>\Saved Games\DCS\Logs\dcs.log
-- All output concerning the @{#RECOVERYTANKER} class should have the string "RECOVERYTANKER" in the corresponding line.
-- Searching for lines that contain the string "error" or "nil" can also give you a hint what's wrong.
-- 
-- The verbosity of the output can be increased by adding the following lines to your script:
-- 
--     BASE:TraceOnOff(true)
--     BASE:TraceLevel(1)
--     BASE:TraceClass("RECOVERYTANKER")
-- 
-- To get even more output you can increase the trace level to 2 or even 3, c.f. @{Core.Base#BASE} for more details.
--
-- @field #RECOVERYTANKER
RECOVERYTANKER = {
  ClassName       = "RECOVERYTANKER",
  Debug           = false,
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
  Dupdate         = nil,
  Hupdate         = nil,
  Tupdate         = nil,
  takeoff         = nil,
  lowfuel         = nil,
  respawn         = nil,
  respawninair    = nil,
  uncontrolledac  = nil,
  orientation     = nil,
  position        = nil,
  zoneUpdate      = nil,
}

--- Class version.
-- @field #string version
RECOVERYTANKER.version="0.9.5w"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Seamless change of position update. Get good updated waypoint and update position if tanker position is right!
-- TODO: Check if TACAN mode "X" is allowed for AA TACAN stations.
-- TODO: Check if tanker is going back to "Running" state after RTB and respawn.
-- TODO: Is alive check for tanker necessary?
-- DONE: Write documenation.
-- DONE: Trace functions self:T instead of self:I for less output.
-- DONE: Make pattern update parameters (distance, orientation) input parameters.
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
  self:SetAltitude()
  self:SetSpeed()
  self:SetRacetrackDistances(6, 8)
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffAir()
  self:SetLowFuelThreshold()
  self:SetRespawnOnOff()
  self:SetTACAN()
  self:SetPatternUpdateDistance()
  self:SetPatternUpdateHeading()
  self:SetPatternUpdateInterval()
  
  -- Moving zone: Zone 1 NM astern the carrier with radius of 1.0 km.
  self.zoneUpdate=ZONE_UNIT:New("Pattern Update Zone", self.carrier, 1*1000, {dx=-UTILS.NMToMeters(1), dy=0, relative_to_unit=true})

  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",         "Running")        -- Start the FSM.
  self:AddTransition("*",             "RefuelStart",   "Refueling")      -- Tanker has started to refuel another unit.
  self:AddTransition("*",             "RefuelStop",    "Running")        -- Tanker starts to refuel.
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


  --- Triggers the FSM event "RefuelStart" when the tanker starts refueling another aircraft.
  -- @function [parent=#RECOVERYTANKER] RefuelStart
  -- @param #RECOVERYTANKER self
  -- @param Wrapper.Unit#UNIT receiver Unit receiving fuel from the tanker.

  --- On after "RefuelStart" event user function. Called when a the the tanker started to refuel another unit.
  -- @function [parent=#RECOVERYTANKER] OnAfterRefuelStart
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT receiver Unit receiving fuel from the tanker.


  --- Triggers the FSM event "RefuelStop" when the tanker stops refueling another aircraft.
  -- @function [parent=#RECOVERYTANKER] RefuelStop
  -- @param #RECOVERYTANKER self
  -- @param Wrapper.Unit#UNIT receiver Unit stoped receiving fuel from the tanker.

  --- On after "RefuelStop" event user function. Called when a the the tanker stopped to refuel another unit.
  -- @function [parent=#RECOVERYTANKER] OnAfterRefuelStop
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Unit#UNIT receiver Unit that received fuel from the tanker.


  --- Triggers the FSM event "Run". Simply puts the group into "Running" state.
  -- @function [parent=#RECOVERYTANKER] Run
  -- @param #RECOVERYTANKER self

  --- Triggers delayed the FSM event "Run". Simply puts the group into "Running" state.
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

  --- On after "RTB" event user function. Called when a the the tanker returns to its home base.
  -- @function [parent=#RECOVERYTANKER] OnAfterPatternUpdate
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
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

  --- On after "PatternEvent" event user function. Called when a the pattern of the tanker is updated.
  -- @function [parent=#RECOVERYTANKER] OnAfterPatternUpdate
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


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

--- Set minimum pattern update interval. After a pattern update this time interval has to pass before the next update is allowed.
-- @param #RECOVERYTANKER self
-- @param #number interval Min interval in minutes. Default is 15 minutes.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateInterval(interval)
  self.dTupdate=(interval or 15)*60
  return self
end

--- Set pattern update distance. Tanker will update its pattern when the carrier changes its position by more than this distance.
-- @param #RECOVERYTANKER self
-- @param #number distancechange Distance threshold in km. Default 9.62 km (= 5 NM).
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateDistance(distancechange)
  self.Dupdate=(distancechange or 9.62)*1000
  return self
end

--- Set pattern update heading. Tanker will update its pattern when the carrier changes its heading by more than this value.
-- @param #RECOVERYTANKER self
-- @param #number headingchange Heading threshold in degrees. Default 5 degrees.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateHeading(headingchange)
  self.Hupdate=headingchange or 5
  return self
end

--- Set low fuel state of tanker. When fuel is below this threshold, the tanker will RTB or be respawned if takeoff type is in air.
-- @param #RECOVERYTANKER self
-- @param #number fuelthreshold Low fuel threshold in percent. Default 10 %.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetLowFuelThreshold(fuelthreshold)
  self.lowfuel=fuelthreshold or 10
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

--- Set takeoff in air at the defined pattern altitude and 20 NM astern the carrier.
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

--- Check if FMS was stopped.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, is stopped. 
function RECOVERYTANKER:IsStopped()
  return self:is("Stopped")
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
    
  end

  -- Initialize route.
  self:_InitRoute(15, 1)
  
  -- Create tanker beacon.
  if self.TACANon then
    self:_ActivateTACAN(2)
  end
  
  -- Get initial orientation and position of carrier.
  self.orientation=self.carrier:GetOrientationX()
  self.position=self.carrier:GetCoordinate()

  -- Init status updates in 10 seconds.
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
  self:T(text)
  
  -- Check if tanker flies through pattern update zone.
  -- TODO: Check if this can be used to update the pattern without too much disruption.
  --       Could be a problem when carrier changes course since the tanker might not fligh through the zone any more.
  local inupdatezone=self.tanker:GetUnit(1):IsInZone(self.zoneUpdate)
  if inupdatezone then
    local clock=UTILS.SecondsToClock(timer.getAbsTime())
    self:I(string.format("Recovery tanker is in pattern update zone! Time=%s", clock))
  end
  
  -- Check if tanker is running and not RTBing or refueling.
  if self:IsRunning() then
  
    -- Check fuel.
    if fuel<self.lowfuel then
    
      -- Check if spawn in air is activated.
      if self.takeoff==SPAWN.Takeoff.Air or self.respawninair then
      
        -- Check that respawn should happen.
        if self.respawn then
      
          -- Debug message.
          local text=string.format("Respawning recovery tanker %s in air.", self.tanker:GetName())
          self:T(text)  
          
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
  
  -- Call status again in 30 seconds.
  if not self:IsStopped() then
    self:__Status(-30)
  end
end

--- On after "PatternUpdate" event. Updates the racetrack pattern of the tanker wrt the carrier position.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterPatternUpdate(From, Event, To)

  -- Debug message.
  self:T(string.format("Updating recovery tanker %s orbit.", self.tanker:GetName()))
    
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
  local text=string.format("Recoery tanker %s returning to airbase %s.", self.tanker:GetName(), airbase:GetName())
  self:T(text)
  
  -- Waypoint array.
  local wp={}
  
  -- Set landing waypoint.
  wp[1]=self.tanker:GetCoordinate():WaypointAirTurningPoint(nil, 300, {}, "Current Position")
  wp[2]=airbase:GetCoordinate():SetAltitude(500):WaypointAirLanding(300, airbase, nil, "Land at airbase")
  
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
      self:T(string.format("Respawning recovery tanker group %s.", group:GetName()))
      
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
    local receiver=EventData.IniUnit
    
    -- Get distance to tanker to check that unit is receiving fuel from this tanker.
    local dist=receiver:GetCoordinate():Get2DDistance(self.tanker:GetCoordinate())
    
    -- If distance > 100 meters, this should be another tanker.
    if dist>100 then
      return
    end
  
    -- Info message.
    self:T(string.format("Recovery tanker %s started refueling unit %s", self.tanker:GetName(), receiver:GetName()))
    
    -- FMS state "Refueling".
    self:RefuelStart(receiver)
  
  end

end

--- Event handler for refueling stopped.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:_RefuelingStop(EventData)

  if EventData and EventData.IniUnit and EventData.IniUnit:IsAlive() then
  
    -- Unit receiving fuel.
    local receiver=EventData.IniUnit
    
    -- Get distance to tanker to check that unit is receiving fuel from this tanker.
    local dist=receiver:GetCoordinate():Get2DDistance(self.tanker:GetCoordinate())
    
    -- If distance > 100 meters, this should be another tanker.
    if dist>100 then
      return
    end
  
    -- Info message.
    self:T(string.format("Recovery tanker %s stopped refueling unit %s", self.tanker:GetName(), receiver:GetName()))
    
    -- FSM state "Running".
    self:RefuelStop(receiver)
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
  self:T(string.format("Initializing route for recovery tanker %s.", self.tanker:GetName()))
  
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
  
  -- Set state to Running. Necessary when tanker was RTB and respawned since it is probably in state "Returning".
  self:__Run(1)
  
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
  if self:IsRunning() and dt>self.dTupdate then

    -- Last saved orientation of carrier.
    local vP=self.orientation
    
    -- We only need the X-Z plane.
    vC.y=0 ; vP.y=0
    
    -- Get angle between the two orientation vectors in rad.
    local rhdg=math.deg(math.acos(UTILS.VecDot(vC,vP)/UTILS.VecNorm(vC)/UTILS.VecNorm(vP)))
  
    -- Check if orientation changed.
    if math.abs(rhdg)>self.Hupdate then
      self:T(string.format("Carrier heading changed by %d degrees. Updating recovery tanker pattern.", rhdg))
      update=true
    end
    
    -- Get distance to saved position.
    local dist=pos:Get2DDistance(self.position)
    
    -- Check if carrier moved more than ~10 km.
    if dist>self.Dupdate then
      self:T(string.format("Carrier position changed by %.1f km. Updating recovery tanker pattern.", dist/1000))
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
      self:T(string.format("Activating recovery tanker TACAN beacon: channel=%d mode=%s, morse=%s.", self.TACANchannel, self.TACANmode, self.TACANmorse))
    
      -- Create a new beacon and activate TACAN.
      self.beacon=BEACON:New(unit)
      self.beacon:ActivateTACAN(self.TACANchannel, self.TACANmode, self.TACANmorse, true)
            
    else
      self:E("ERROR: Recovery tanker is not alive!")
    end
    
  end

end

--- Calculate distances between carrier and tanker.
-- @param #AIRBOSS self 
-- @return #number Distance [m] in the direction of the orientation of the carrier.
-- @return #number Distance [m] perpendicular to the orientation of the carrier.
-- @return #number Distance [m] to the carrier.
-- @return #number Angle [Deg] from carrier to plane. Phi=0 if the plane is directly behind the carrier, phi=90 if the plane is starboard, phi=180 if the plane is in front of the carrier.
function RECOVERYTANKER:_GetDistances()

  -- Vector to carrier
  local a=self.carrier:GetVec3()
  
  -- Vector to player
  local b=self.tanker:GetVec3()
  
  -- Vector from carrier to player.
  local c={x=b.x-a.x, y=0, z=b.z-a.z}
  
  -- Orientation of carrier.
  local x=self.carrier:GetOrientationX()
  
  -- Projection of player pos on x component.
  local dx=UTILS.VecDot(x,c)
  
  -- Orientation of carrier.
  local z=self.carrier:GetOrientationZ()
  
  -- Projection of player pos on z component.  
  local dz=UTILS.VecDot(z,c)
  
  -- Polar coordinates
  local rho=math.sqrt(dx*dx+dz*dz)
  local phi=math.deg(math.atan2(dz,dx))
  if phi<0 then
    phi=phi+360
  end
  
  -- phi=0 if the plane is directly behind the carrier, phi=180 if the plane is in front of the carrier
  phi=phi-180

  if phi<0 then
    phi=phi+360
  end
  
  return dx,dz,rho,phi
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

