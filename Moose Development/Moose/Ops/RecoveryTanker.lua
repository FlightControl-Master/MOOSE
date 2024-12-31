--- **Ops** - Recovery tanker for carrier operations.
-- 
-- Tanker aircraft flying a racetrack pattern overhead an aircraft carrier.
--
-- **Main Features:**
--
--    * Regular pattern update with respect to carrier position.
--    * No restrictions regarding carrier waypoints and heading.
--    * Automatic respawning when tanker runs out of fuel for 24/7 operations.
--    * Tanker can be spawned cold or hot on the carrier or at any other airbase or directly in air.
--    * Automatic AA TACAN beacon setting.
--    * Multiple tankers at the same carrier.
--    * Multiple carriers due to object oriented approach.
--    * Finite State Machine (FSM) implementation, which allows the mission designer to hook into certain events.
--
-- ===
--
-- ### Author: **funkyfranky** 
-- ### Special thanks to **HighwaymanEd** for testing and suggesting improvements!
--
-- @module Ops.RecoveryTanker
-- @image Ops_RecoveryTanker.png

--- RECOVERYTANKER class.
-- @type RECOVERYTANKER
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode.
-- @field #string lid Log debug id text.
-- @field Wrapper.Unit#UNIT carrier The carrier the tanker is attached to.
-- @field #string carriertype Carrier type.
-- @field #string tankergroupname Name of the late activated tanker template group.
-- @field Wrapper.Group#GROUP tanker Tanker group.
-- @field Wrapper.Airbase#AIRBASE airbase The home airbase object of the tanker. Normally the aircraft carrier.
-- @field Core.Beacon#BEACON beacon Tanker TACAN beacon.
-- @field #number TACANchannel TACAN channel. Default 1.
-- @field #string TACANmode TACAN mode, i.e. "X" or "Y". Default "Y". Use only "Y" for AA TACAN stations!
-- @field #string TACANmorse TACAN morse code. Three letters identifying the TACAN station. Default "TKR".
-- @field #boolean TACANon If true, TACAN is automatically activated. If false, TACAN is disabled.
-- @field #number RadioFreq Radio frequency in MHz of the tanker. Default 251 MHz.
-- @field #string RadioModu Radio modulation "AM" or "FM". Default "AM".
-- @field #number speed Tanker speed when flying pattern.
-- @field #number altitude Tanker orbit pattern altitude.
-- @field #number distStern Race-track distance astern. distStern is <0.
-- @field #number distBow Race-track distance bow. distBow is >0.
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
-- @field DCS#Vec3 orientlast Orientation of the carrier for checking if carrier is currently turning.
-- @field Core.Point#COORDINATE position Position of carrier. Used to monitor if carrier significantly changed its position and then update the tanker pattern.
-- @field #string alias Alias of the spawn group.
-- @field #number uid Unique ID of this tanker.
-- @field #boolean awacs If true, the groups gets the enroute task AWACS instead of tanker.
-- @field #number callsignname Number for the callsign name.
-- @field #number callsignnumber Number of the callsign name.
-- @field #string modex Tail number of the tanker.
-- @field #boolean eplrs If true, enable data link, e.g. if used as AWACS.
-- @field #boolean recovery If true, tanker will recover using the AIRBOSS marshal pattern.
-- @field #number terminaltype Terminal type of used parking spots on airbases.
-- @field #boolean unlimitedfuel If true, the tanker will have unlimited fuel.
-- @extends Core.Fsm#FSM

--- Recovery Tanker.
--
-- ===
--
-- ![Banner Image](..\Presentations\RECOVERYTANKER\RecoveryTanker_Main.png)
--
-- # Recovery Tanker
--
-- A recovery tanker acts as refueling unit flying overhead an aircraft carrier in order to supply incoming flights with gas if they go "*Bingo on the Ball*".
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
-- With this setup, the tanker will be spawned on the USS Stennis with running engines. After it takes off, it will fly a position ~10 NM astern of the boat and from there start its
-- pattern. This is a counter clockwise racetrack pattern at angels 6.
-- 
-- A TACAN beacon will be automatically activated at channel 1Y with morse code "TKR". See below how to change this setting.
-- 
-- Note that the Tanker entry in the F10 radio menu will appear once the tanker is on station and not before. If you spawn the tanker cold or hot on the carrier, this will take ~10 minutes.
-- 
-- Also note, that currently the only carrier capable aircraft in DCS is the S-3B Viking (tanker version). If you want to use another refueling aircraft, you need to activate air spawn
-- or set a different land based airport of the map. This will be explained below.
-- 
-- ![Banner Image](..\Presentations\RECOVERYTANKER\RecoveryTanker_Pattern.jpg)
-- 
-- The "downwind" leg of the pattern is normally used for refueling.
-- 
-- Once the tanker runs out of fuel itself, it will return to the carrier, respawn with full fuel and take up its pattern again.
-- 
-- # Options and Fine Tuning
-- 
-- Several parameters can be customized by the mission designer via user API functions.
-- 
-- ## Takeoff Type
-- 
-- By default, the tanker is spawned with running engines on the carrier. The mission designer has set option to set the take off type via the @{#RECOVERYTANKER.SetTakeoff} function.
-- Or via shortcuts
-- 
--    * @{#RECOVERYTANKER.SetTakeoffHot}(): Will set the takeoff to hot, which is also the default.
--    * @{#RECOVERYTANKER.SetTakeoffCold}(): Will set the takeoff type to cold, i.e. with engines off.
--    * @{#RECOVERYTANKER.SetTakeoffAir}(): Will set the takeoff type to air, i.e. the tanker will be spawned in air ~10 NM astern the carrier.  
-- 
-- For example,
--     TexacoStennis=RECOVERYTANKER:New(UNIT:FindByName("USS Stennis"), "Texaco")
--     TexacoStennis:SetTakeoffAir()
--     TexacoStennis:Start()
-- will spawn the tanker several nautical miles astern the carrier. From there it will start its pattern.
-- 
-- Spawning in air is not as realistic but can be useful do avoid DCS bugs and shortcomings like aircraft crashing into each other on the flight deck.
-- 
-- **Note** that when spawning in air is set, the tanker will also not return to the boat, once it is out of fuel. Instead it will be respawned directly in air.
-- 
-- If only the first spawning should happen on the carrier, one use the @{#RECOVERYTANKER.SetRespawnInAir}() function to command that all subsequent spawning
-- will happen in air.
-- 
-- If the tanker should not be respawned at all, one can set @{#RECOVERYTANKER.SetRespawnOff}().
-- 
-- ## Pattern Parameters
-- 
-- The racetrack pattern parameters can be fine tuned via the following functions:
-- 
--    * @{#RECOVERYTANKER.SetAltitude}(*altitude*), where *altitude* is the pattern altitude in feet. Default 6000 ft.
--    * @{#RECOVERYTANKER.SetSpeed}(*speed*), where *speed* is the pattern speed in knots. Default is 274 knots TAS which results in ~250 KIAS.
--    * @{#RECOVERYTANKER.SetRacetrackDistances}(*distbow*, *diststern*), where *distbow* and *diststern* are the distances ahead and astern the boat (default 10 and 4 NM), respectively.
--    In principle, these number should be more like 8 and 6 NM but since the carrier is moving, we give translate the pattern points a bit forward.
--    
-- ## Home Base
-- 
-- The home base is the airbase where the tanker is spawned (if not in air) and where it will go once it is running out of fuel. The default home base is the carrier itself.
-- The home base can be changed via the @{#RECOVERYTANKER.SetHomeBase}(*airbase*) function, where *airbase* can be a MOOSE @{Wrapper.Airbase#AIRBASE} object or simply the 
-- name of the airbase passed as string.
-- 
-- Note that only the S3B Viking is a refueling aircraft that is carrier capable. You can use other tanker aircraft types, e.g. the KC-130, but in this case you must either 
-- set an airport of the map as home base or activate spawning in air via @{#RECOVERYTANKER.SetTakeoffAir}.
--
-- ## TACAN
-- 
-- A TACAN beacon for the tanker can be activated via scripting, i.e. no need to do this within the mission editor.
-- 
-- The beacon is create with the @{#RECOVERYTANKER.SetTACAN}(*channel*, *morse*) function, where *channel* is the TACAN channel (a number), 
-- and *morse* a three letter string that is send as morse code to identify the tanker:
-- 
--     TexacoStennis:SetTACAN(10, "TKR")
--     
-- will activate a TACAN beacon 10Y with more code "TKR".
-- 
-- If you do not set a TACAN beacon explicitly, it is automatically create on channel 1Y and morse code "TKR".
-- The mode is *always* "Y" for AA TACAN stations since mode "X" does not work!
-- 
-- In order to completely disable the TACAN beacon, you can use the @{#RECOVERYTANKER.SetTACANoff}() function in your script.
-- 
-- ## Radio
-- 
-- The radio frequency on optionally modulation can be set via the @{#RECOVERYTANKER.SetRadio}(*frequency*, *modulation*) function. The first parameter denotes the radio frequency the tanker uses in MHz.
-- The second parameter is *optional* and sets the modulation to either AM (default) or FM.
-- 
-- For example,
-- 
--     TexacoStennis:SetRadio(260)
--
-- will set the frequency of the tanker to 260 MHz AM.
-- 
-- **Note** that if this is not set, the tanker frequency will be automatically set to **251 MHz AM**.
--
-- ## Pattern Update
-- 
-- The pattern of the tanker is updated if at least one of the two following conditions apply:
-- 
--    * The aircraft carrier changes its position by more than 5 NM (see @{#RECOVERYTANKER.SetPatternUpdateDistance}) and/or
--    * The aircraft carrier changes its heading by more than 5 degrees (see @{#RECOVERYTANKER.SetPatternUpdateHeading})
-- 
-- **Note** that updating the pattern often leads to a more or less small disruption of the perfect racetrack pattern of the tanker. This is because a new waypoint and new racetrack points
-- need to be set as DCS task. This is the reason why the pattern is not constantly updated but rather when the position or heading of the carrier changes significantly.
--
-- The maximum update frequency is set to 10 minutes. You can adjust this by @{#RECOVERYTANKER.SetPatternUpdateInterval}.
-- Also the pattern will not be updated whilst the carrier is turning or the tanker is currently refueling another unit.
-- 
-- ## Callsign
-- 
-- The callsign of the tanker can be set via the @{#RECOVERYTANKER.SetCallsign}(*callsignname*, *callsignnumber*) function. Both parameters are *numbers*.
-- The first parameter *callsignname* defines the name (1=Texaco, 2=Arco, 3=Shell). The second (optional) parameter specifies the first number and has to be between 1-9.
-- Also see [DCS_enum_callsigns](https://wiki.hoggitworld.com/view/DCS_enum_callsigns) and [DCS_command_setCallsign](https://wiki.hoggitworld.com/view/DCS_command_setCallsign).
-- 
--     TexacoStennis:SetCallsign(CALLSIGN.Tanker.Arco)
--
-- For convenience, MOOSE has a CALLSIGN enumerator introduced.
-- 
-- ## AWACS
-- 
-- You can use the class also to have an AWACS orbiting overhead the carrier. This requires to add the @{#RECOVERYTANKER.SetAWACS}(*switch*, *eplrs*) function to the script, which sets the enroute tasks AWACS 
-- as soon as the aircraft enters its pattern. Note that the EPLRS data link is enabled by default. To disable it, the second parameter *eplrs* must be set to *false*.
-- 
-- A simple script could look like this:
-- 
--     -- E-2D at USS Stennis spawning in air.
--     local awacsStennis=RECOVERYTANKER:New("USS Stennis", "E2D Group")
--     
--     -- Custom settings:
--     awacsStennis:SetAWACS()
--     awacsStennis:SetCallsign(CALLSIGN.AWACS.Wizard, 1)
--     awacsStennis:SetTakeoffAir()
--     awacsStennis:SetAltitude(20000)
--     awacsStennis:SetRadio(262)
--     awacsStennis:SetTACAN(2, "WIZ")
--     
--     -- Start AWACS.
--     awacsStennis:Start()
--
-- # Finite State Machine
-- 
-- The implementation uses a Finite State Machine (FSM). This allows the mission designer to hook in to certain events.
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
-- ## Debug Mode
-- 
-- You have the option to enable the debug mode for this class via the @{#RECOVERYTANKER.SetDebugModeON} function.
-- If enabled, text messages about the tanker status will be displayed on screen and marks of the pattern created on the F10 map.
--
-- @field #RECOVERYTANKER
RECOVERYTANKER = {
  ClassName       = "RECOVERYTANKER",
  Debug           = false,
  lid             = nil,
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
  RadioFreq       = nil,
  RadioModu       = nil,
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
  orientlast      = nil,
  position        = nil,
  alias           = nil,
  uid             =   0,
  awacs           = nil,
  callsignname    = nil,
  callsignnumber  = nil,
  modex           = nil,
  eplrs           = nil,
  recovery        = nil,
  terminaltype    = nil,
  unlimitedfuel   = false,
}

--- Unique ID (global).
-- @field #number UID Unique ID (global).
_RECOVERYTANKERID=0

--- Class version.
-- @field #string version
RECOVERYTANKER.version="1.0.10"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Is alive check for tanker necessary?
-- DONE: Seamless change of position update. Get good updated waypoint and update position if tanker position is right. Not really possiple atm.
-- DONE: Check if TACAN mode "X" is allowed for AA TACAN stations. Nope
-- DONE: Check if tanker is going back to "Running" state after RTB and respawn.
-- DONE: Write documentation.
-- DONE: Trace functions self:T instead of self:I for less output.
-- DONE: Make pattern update parameters (distance, orientation) input parameters.
-- DONE: Add FSM event for pattern update.
-- DONE: Smarter pattern update function. E.g. (small) zone around carrier. Only update position when carrier leaves zone or changes heading?
-- DONE: Set AA TACAN.
-- DONE: Add refueling event/state.
-- DONE: Possibility to add already present/spawned aircraft, e.g. for warehouse.
-- DONE: Add unlimited fuel

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
  
  -- Increase unique ID.
  _RECOVERYTANKERID=_RECOVERYTANKERID+1
  
  -- Unique ID of this tanker.
  self.uid=_RECOVERYTANKERID

  -- Save self in static object. Easier to retrieve later.
  self.carrier:SetState(self.carrier, string.format("RECOVERYTANKER_%d", self.uid) , self)    
  
  -- Set unique spawn alias.
  self.alias=string.format("%s_%s_%02d", self.carrier:GetName(), self.tankergroupname, _RECOVERYTANKERID)
  
  -- Log ID.
  self.lid=string.format("RECOVERYTANKER %s | ", self.alias)
  
  -- Init default parameters.
  self:SetAltitude()
  self:SetSpeed()
  self:SetRacetrackDistances()
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffHot()
  self:SetLowFuelThreshold()
  self:SetRespawnOnOff()
  self:SetTACAN()
  self:SetRadio()
  self:SetPatternUpdateDistance()
  self:SetPatternUpdateHeading()
  self:SetPatternUpdateInterval()
  self:SetAWACS(false)
  self:SetRecoveryAirboss(false)
  self.terminaltype=AIRBASE.TerminalType.OpenMedOrBig
  
  -- Debug trace.
  if false then
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
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
  self:AddTransition("Returning",     "Returned",      "Returned")       -- Tanker has returned to its airbase (i.e. landed).
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

  --- On after "Start" event function. Called when FSM is started.
  -- @function [parent=#RECOVERYTANKER] OnAfterStart
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


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
  -- @function [parent=#RECOVERYTANKER] OnAfterRTB
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase where the tanker should return to.


  --- Triggers the FSM event "Returned" after the tanker has landed.
  -- @function [parent=#RECOVERYTANKER] Returned
  -- @param #RECOVERYTANKER self
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase the tanker has landed.

  --- Triggers the delayed FSM event "Returned" after the tanker has landed.
  -- @function [parent=#RECOVERYTANKER] __Returned
  -- @param #RECOVERYTANKER self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase the tanker has landed.

  --- On after "Returned" event user function. Called when a the the tanker has landed at an airbase.
  -- @function [parent=#RECOVERYTANKER] OnAfterReturned
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase the tanker has landed.


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

--- Set the tanker to have unlimited fuel.
-- @param #RECOVERYTANKER self
-- @param #boolean OnOff If true, the tanker will have unlimited fuel.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetUnlimitedFuel(OnOff)
  self.unlimitedfuel = OnOff
  return self
end

--- Set the speed the tanker flys in its orbit pattern.
-- @param #RECOVERYTANKER self
-- @param #number speed True air speed (TAS) in knots. Default 274 knots, which results in ~250 KIAS.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetSpeed(speed)
  self.speed=UTILS.KnotsToMps(speed or 274)
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
-- @param #number distbow Distance [NM] in front of the carrier. Default 10 NM.
-- @param #number diststern Distance [NM] behind the carrier. Default 4 NM.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRacetrackDistances(distbow, diststern)
  self.distBow=UTILS.NMToMeters(distbow or 10)
  self.distStern=-UTILS.NMToMeters(diststern or 4)
  return self
end

--- Set minimum pattern update interval. After a pattern update this time interval has to pass before the next update is allowed.
-- @param #RECOVERYTANKER self
-- @param #number interval Min interval in minutes. Default is 10 minutes.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateInterval(interval)
  self.dTupdate=(interval or 10)*60
  return self
end

--- Set pattern update distance threshold. Tanker will update its pattern when the carrier changes its position by more than this distance.
-- @param #RECOVERYTANKER self
-- @param #number distancechange Distance threshold in NM. Default 5 NM (=9.62 km).
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateDistance(distancechange)
  self.Dupdate=UTILS.NMToMeters(distancechange or 5)
  return self
end

--- Set pattern update heading threshold. Tanker will update its pattern when the carrier changes its heading by more than this value.
-- @param #RECOVERYTANKER self
-- @param #number headingchange Heading threshold in degrees. Default 5 degrees.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetPatternUpdateHeading(headingchange)
  self.Hupdate=headingchange or 5
  return self
end

--- Set low fuel state of tanker. When fuel is below this threshold, the tanker will RTB or be respawned if takeoff type is in air.
-- @param #RECOVERYTANKER self
-- @param #number fuelthreshold Low fuel threshold in percent. Default 10 % of max fuel.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetLowFuelThreshold(fuelthreshold)
  self.lowfuel=fuelthreshold or 10
  return self
end

--- Set home airbase of the tanker. This is the airbase where the tanker will go when it is out of fuel.
-- @param #RECOVERYTANKER self
-- @param Wrapper.Airbase#AIRBASE airbase The home airbase. Can be the airbase name or a Moose AIRBASE object.
-- @param #number terminaltype (Optional) The terminal type of parking spots used for spawning at airbases. Default AIRBASE.TerminalType.OpenMedOrBig.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetHomeBase(airbase, terminaltype)
  if type(airbase)=="string" then
    self.airbase=AIRBASE:FindByName(airbase)
  else
    self.airbase=airbase
  end
  if not self.airbase then
    self:E(self.lid.."ERROR: Airbase is nil!")
  end
  if terminaltype then
    self.terminaltype=terminaltype
  end
  return self
end

--- Activate recovery by the AIRBOSS class. Tanker will get a Marshal stack and perform a CASE I, II or III recovery when RTB.
-- @param #RECOVERYTANKER self
-- @param #boolean switch If true or nil, recovery is done by AIRBOSS.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRecoveryAirboss(switch)
  if switch==true or switch==nil then
    self.recovery=true
  else
    self.recovery=false
  end
  return self
end

--- Set that the group takes the role of an AWACS instead of a refueling tanker.
-- @param #RECOVERYTANKER self
-- @param #boolean switch If true or nil, set role AWACS.
-- @param #boolean eplrs If true or nil, enable EPLRS. If false, EPLRS will be off.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetAWACS(switch, eplrs)
  if switch==nil or switch==true then
    self.awacs=true
  else
    self.awacs=false
  end
  if eplrs==nil or eplrs==true then
    self.eplrs=true
  else
    self.eplrs=false
  end
  
  return self
end


--- Set callsign of the tanker group.
-- @param #RECOVERYTANKER self
-- @param #number callsignname Number
-- @param #number callsignnumber Number
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetCallsign(callsignname, callsignnumber)
  self.callsignname=callsignname
  self.callsignnumber=callsignnumber
  return self
end

--- Set modex (tail number) of the tanker.
-- @param #RECOVERYTANKER self
-- @param #number modex Tail number.
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetModex(modex)
  self.modex=modex
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

--- Set takeoff in air at the defined pattern altitude and ~10 NM astern the carrier.
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
-- This can be useful when interfaced with, e.g., a MOOSE @{Functional.Warehouse#WAREHOUSE}.
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

--- Set TACAN channel of tanker. Note that mode is automatically set to "Y" for AA TACAN since only that works.
-- @param #RECOVERYTANKER self
-- @param #number channel TACAN channel. Default 1.
-- @param #string morse TACAN morse code identifier. Three letters. Default "TKR".
-- @param #string mode TACAN mode, which can be either "Y" (default) or "X".
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetTACAN(channel, morse, mode)
  self.TACANchannel=channel or 1
  self.TACANmode=mode or "Y"
  self.TACANmorse=morse or "TKR"
  self.TACANon=true
  return self
end

--- Set radio frequency and optionally modulation of the tanker.
-- @param #RECOVERYTANKER self
-- @param #number frequency Radio frequency in MHz. Default 251 MHz.
-- @param #string modulation Radio modulation, either "AM" or "FM". Default "AM".
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetRadio(frequency, modulation)
  self.RadioFreq=frequency or 251
  self.RadioModu=modulation or "AM"
  return self
end

--- Activate debug mode. Marks of pattern on F10 map and debug messages displayed on screen.
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetDebugModeON()
  self.Debug=true
  return self
end

--- Deactivate debug mode. This is also the default setting.
-- @param #RECOVERYTANKER self
-- @return #RECOVERYTANKER self
function RECOVERYTANKER:SetDebugModeOFF()
  self.Debug=false
  return self
end

--- Check if tanker is currently returning to base.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker is returning to base. 
function RECOVERYTANKER:IsReturning()
  return self:is("Returning")
end

--- Check if tanker has returned to base.
-- @param #RECOVERYTANKER self
-- @return #boolean If true, tanker has returned to base. 
function RECOVERYTANKER:IsReturned()
  return self:is("Returned")
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

--- Alias of tanker spawn group.
-- @param #RECOVERYTANKER self
-- @return #string Alias of the tanker. 
function RECOVERYTANKER:GetAlias()
  return self.alias
end

--- Get unit name of the spawned tanker.
-- @param #RECOVERYTANKER self
-- @return #string Name of the tanker unit or nil if it does not exist. 
function RECOVERYTANKER:GetUnitName()
  local unit=self.tanker:GetUnit(1)
  if unit then
    return unit:GetName()
  end
  return nil
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
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.Refueling,     self._RefuelingStart)      --Need explicit functions since OnEventRefueling and OnEventRefuelingStop did not hook!
  self:HandleEvent(EVENTS.RefuelingStop, self._RefuelingStop)
  self:HandleEvent(EVENTS.Crash,         self._OnEventCrashOrDead)
  self:HandleEvent(EVENTS.Dead,          self._OnEventCrashOrDead)
  
  -- Spawn tanker. We need to introduce an alias in case this class is used twice. This would confuse the spawn routine.
  local Spawn=SPAWN:NewWithAlias(self.tankergroupname, self.alias)
  
  if self.unlimitedfuel then
    Spawn:OnSpawnGroup(
      function (grp)
        grp:CommandSetUnlimitedFuel(self.unlimitedfuel)
      end
    )
  end
  
  -- Set radio frequency and modulation.
  Spawn:InitRadioCommsOnOff(true)
  Spawn:InitRadioFrequency(self.RadioFreq)
  Spawn:InitRadioModulation(self.RadioModu)
  Spawn:InitModex(self.modex)
  
  -- Spawn on carrier.
  if self.takeoff==SPAWN.Takeoff.Air then
  
    -- Carrier heading
    local hdg=self.carrier:GetHeading()
    
    -- Spawn distance behind the carrier.
    local dist=-self.distStern+UTILS.NMToMeters(4)
    
    -- Coordinate behind the carrier and slightly port.
    local Carrier=self.carrier:GetCoordinate():Translate(dist, hdg+190):SetAltitude(self.altitude)
    
    -- Orientation of spawned group.
    Spawn:InitHeading(hdg+10)
    
    -- Spawn at coordinate.
    self.tanker=Spawn:SpawnFromCoordinate(Carrier)
    
  else
  
    -- Check if an uncontrolled tanker group was requested.
    if self.uncontrolledac then
    
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
      self.tanker=Spawn:SpawnAtAirbase(self.airbase, self.takeoff, nil, self.terminaltype)
      
    end
    
  end

  -- Initialize route. self.distStern<0!
  self:ScheduleOnce(1, self._InitRoute, self, -self.distStern+UTILS.NMToMeters(3))
  
  -- Create tanker beacon.
  if self.TACANon then
    self:_ActivateTACAN(2)
  end
  
  -- Set callsign.
  if self.callsignname then
    self.tanker:CommandSetCallsign(self.callsignname, self.callsignnumber, 2)
  end
  
  -- Turn EPLRS datalink on.
  if self.eplrs then
    self.tanker:CommandEPLRS(true, 3)
  end
  
  
  -- Get initial orientation and position of carrier.
  self.orientation=self.carrier:GetOrientationX()
  self.orientlast=self.carrier:GetOrientationX()
  self.position=self.carrier:GetCoordinate()

  -- Init status updates in 10 seconds.
  self:__Status(10)
  
  return self
end


--- On after Status event. Checks player status.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterStatus(From, Event, To)

  -- Get current time.
  local time=timer.getTime()
  
  if self.tanker and self.tanker:IsAlive() then
  
    ---------------------
    -- TANKER is ALIVE --
    --------------------- 
  
    -- Get fuel of tanker.
    local fuel=self.tanker:GetFuel()*100
    local life=self.tanker:GetUnit(1):GetLife()
    local life0=self.tanker:GetUnit(1):GetLife0()
    local lifeR=self.tanker:GetUnit(1):GetLifeRelative()    
    
    -- Report fuel and life.
    local text=string.format("Recovery tanker %s: state=%s fuel=%.1f, life=%.1f/%.1f=%d", self.tanker:GetName(), self:GetState(), fuel, life, life0, lifeR*100)
    self:T(self.lid..text)
    MESSAGE:New(text, 10):ToAllIf(self.Debug)
    
    -- Check if tanker is running and not RTBing or refueling.
    if self:IsRunning() then
    
      -- Check fuel.
      if fuel<self.lowfuel then
      
        -- Check if spawn in air is activated.
        if (self.takeoff==SPAWN.Takeoff.Air or self.respawninair) and not self.recovery then
        
          -- Check that respawn should happen.
          if self.respawn then
        
            -- Debug message.
            local text=string.format("Respawning recovery tanker %s in air.", self.tanker:GetName())
            MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
            self:T(self.lid..text)  
            
            -- Set heading for respawn template.
            self.tanker:InitHeading(self.tanker:GetHeading())
            
            -- Set radio for respawn template.
            self.tanker:InitRadioCommsOnOff(true)
            self.tanker:InitRadioFrequency(self.RadioFreq)
            self.tanker:InitRadioModulation(self.RadioModu)
            self.tanker:InitModex(self.modex)
            
            -- Respawn tanker.
            self.tanker=self.tanker:Respawn(nil, true)
            
            -- Update Pattern in 2 seconds. Need to give a bit time so that the respawned group is in the game.
            self:__PatternUpdate(2)
            
            -- Create tanker beacon and activate TACAN.
            if self.TACANon then
              self:_ActivateTACAN(3)
            end
            
            -- Set callsign.
            if self.callsignname then
              self.tanker:CommandSetCallsign(self.callsignname, self.callsignnumber, 3)
            end
            
            -- Turn EPLRS datalink on.
            if self.eplrs then
              self.tanker:CommandEPLRS(true, 4)
            end                        
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
      
    elseif self:IsReturning() then
    
      -- Tanker is returning to its base.
      self:T2(self.lid.."Tanker is returning.")
      
    elseif self:IsReturned() then
    
      -- Tanker landed. Waiting for engine shutdown...
      self:T2(self.lid.."Tanker returned. waiting for engine shutdown.")
      
    end
    
    -- Call status again in 30 seconds.
    if not self:IsStopped() then
      self:__Status(-30)
    end
    
  else
  
    --------------------
    -- TANKER is DEAD --
    --------------------

    if not self:IsStopped() then
    
      self:E(self.lid.."Recovery tanker is NOT alive (and not stopped)!")
    
      -- Stop FSM.
      self:Stop()
    
      -- Restart FSM after 5 seconds.
      if self.respawn then
        self:__Start(5)
      end
      
    end
    
  end

end

--- On after "PatternUpdate" event. Updates the racetrack pattern of the tanker wrt the carrier position.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterPatternUpdate(From, Event, To)
  -- Debug message.
  local text=string.format("Updating recovery tanker %s racetrack pattern.", self.tanker:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:T(self.lid..text)
    
  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  -- Define race-track pattern.
  local p0=self.tanker:GetCoordinate():Translate(UTILS.NMToMeters(1), self.tanker:GetHeading(), true)
  
  -- Racetrack pattern points.
  local p1=Carrier:Translate(self.distStern, hdg):SetAltitude(self.altitude)
  local p2=Carrier:Translate(self.distBow, hdg):SetAltitude(self.altitude)
  
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
    
  -- New waypoint with orbit pattern task. Speed expected in km/h.
  wp[1]=self.tanker:GetCoordinate():WaypointAirTurningPoint(nil , UTILS.MpsToKmph(self.speed), {}, "Current Position")
  wp[2]=p0:WaypointAirTurningPoint(nil, UTILS.MpsToKmph(self.speed), {taskorbit}, "Tanker Orbit")
  
  -- Initialize WP and route tanker.
  self.tanker:WayPointInitialize(wp)
  
  -- Task combo.
  
  -- Be a tanker or be an AWACS.
  local taskroll = self.tanker:EnRouteTaskTanker()
  if self.awacs then
    taskroll=self.tanker:EnRouteTaskAWACS()
  end
  
  --local taskeplrs=self.tanker:TaskEPLRS(true, 2)
  
  -- Route task.
  local taskroute  = self.tanker:TaskRoute(wp)
  
  -- Note that the order is important here! tasktanker has to come first. Otherwise it does not work.
  local taskcombo  = self.tanker:TaskCombo({taskroll, taskroute})

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
  local text=string.format("Recovery tanker %s returning to airbase %s.", self.tanker:GetName(), airbase:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:T(self.lid..text)
  
  -- Waypoint array.
  local wp={}
  
  -- Set speed ot 75% max.
  local speed=self.tanker:GetSpeedMax()*0.75
  
  -- Set landing waypoint.
  wp[1]=self.tanker:GetCoordinate():WaypointAirTurningPoint(nil, speed, {}, "Current Position")
  
  
  if self.recovery then
    -- Fly a bit until the airboss takes over.
    wp[2]=self.tanker:GetCoordinate():Translate(UTILS.NMToMeters(10), self.tanker:GetHeading(), true):WaypointAirTurningPoint(nil, speed, {}, "WP")
  else  
    wp[2]=airbase:GetCoordinate():SetAltitude(500):WaypointAirLanding(speed, airbase, nil, "Land at airbase")
  end
  
  -- Initialize WP and route tanker.
  self.tanker:WayPointInitialize(wp)
  
  -- Set task.
  self.tanker:Route(wp, 1)
end


--- On after Returned event. The tanker has landed.
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The base at which the tanker landed.
function RECOVERYTANKER:onafterReturned(From, Event, To, airbase)

  if airbase then
    local airbasename=airbase:GetName()
    self:I(self.lid..string.format("Tanker returned to airbase %s", tostring(airbasename)))
  else
    self:E(self.lid..string.format("WARNING: Tanker landed but airbase (EventData.Place) is nil!"))
  end
  
end


--- On after Stop event. Unhandle events and stop status updates. 
-- @param #RECOVERYTANKER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RECOVERYTANKER:onafterStop(From, Event, To)

  -- Unhandle events.
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.Refueling)
  self:UnHandleEvent(EVENTS.RefuelingStop)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.Crash)
  
  -- Clear all pending FSM events.
  self.CallScheduler:Clear()
  
  -- If tanker is alive, despawn it.
  if self.tanker and self.tanker:IsAlive() then
    self:I(self.lid.."Stopping FSM and despawning tanker.")
    self.tanker:Destroy()
  else
    self:I(self.lid.."Stopping FSM. Tanker was not alive.")
  end
    
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for landing of recovery tanker.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:OnEventLand(EventData)

  -- Group that shut down the engine.
  local group=EventData.IniGroup --Wrapper.Group#GROUP
  
  -- Check if group is alive.
  if group and group:IsAlive() then
  
    -- Group name. When spawning it will have #001 attached.
    local groupname=group:GetName()
    
    -- Check that we have the right group and that it should be respawned.
    if groupname==self.tanker:GetName() then
    
      local airbase=nil --Wrapper.Airbase#AIRBASE
      local airbasename="unknown"
      if EventData.Place then
        airbase=EventData.Place
        airbasename=airbase:GetName()
      end
  
      -- Debug info.
      local text=string.format("Recovery tanker group %s landed at airbase %s.", group:GetName(), airbasename)
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
      self:T(self.lid..text)
      
      -- Trigger returned event.
      self:__Returned(1, airbase)      
    end
  end
end


--- Event handler for engine shutdown of recovery tanker.
-- Respawn tanker group once it landed because it was out of fuel.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:OnEventEngineShutdown(EventData)

  -- Group that shut down the engine.
  local group=EventData.IniGroup --Wrapper.Group#GROUP
  
  -- Check if group is alive.
  if group and group:IsAlive() then
  
    -- Group name. When spawning it will have #001 attached.
    local groupname=group:GetName()
    
    -- Check that we have the right group and that it should be respawned.
    if groupname==self.tanker:GetName() and self.respawn then
  
      -- Debug info.
      local text=string.format("Respawning recovery tanker group %s.", group:GetName())
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
      self:T(self.lid..text)
      
      -- Set radio for respawn template.
      group:InitRadioCommsOnOff(true)
      group:InitRadioFrequency(self.RadioFreq)
      group:InitRadioModulation(self.RadioModu)
      group:InitModex(self.modex)
           
      -- Respawn tanker. Delaying respawn due to DCS bug https://github.com/FlightControl-Master/MOOSE/issues/1076
      self:ScheduleOnce(1, GROUP.RespawnAtCurrentAirbase, group)
      
      -- Create tanker beacon and activate TACAN.
      if self.TACANon then
        self:_ActivateTACAN(3)
      end
      
      -- Set callsign.
      if self.callsignname then
        self.tanker:CommandSetCallsign(self.callsignname, self.callsignnumber, 3)
      end
      
      -- Turn EPLRS datalink on.
      if self.eplrs then
        self.tanker:CommandEPLRS(true, 4)
      end       

      -- Initial route.
      self:ScheduleOnce(2, RECOVERYTANKER._InitRoute, self, -self.distStern+UTILS.NMToMeters(3))     
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
    local text=string.format("Recovery tanker %s started refueling unit %s", self.tanker:GetName(), receiver:GetName())
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:T(self.lid..text)    
    
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
    local text=string.format("Recovery tanker %s stopped refueling unit %s", self.tanker:GetName(), receiver:GetName())
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:T(self.lid..text)
        
    -- FSM state "Running".
    self:RefuelStop(receiver)
  end

end

--- A unit crashed or died.
-- @param #RECOVERYTANKER self
-- @param Core.Event#EVENTDATA EventData Event data.
function RECOVERYTANKER:_OnEventCrashOrDead(EventData)
  self:F2({eventdata=EventData})
  
  -- Check that there is an initiating unit in the event data.
  if EventData and EventData.IniUnit then

    -- Crashed or dead unit.
    local unit=EventData.IniUnit  
    local unitname=tostring(EventData.IniUnitName)
    
    -- Check that it was the tanker that crashed.
    if EventData.IniGroupName==self.tanker:GetName() then
    
      -- Error message.
      self:E(self.lid..string.format("Recovery tanker %s crashed!", unitname))
      
      -- Stop FSM.
      self:Stop()
      
      -- Restart.
      if self.respawn then
        self:__Start(5)
      end
    
    end
    
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
  DCSScript[#DCSScript+1] = string.format('local mycarrier = UNIT:FindByName(\"%s\") ', carriername)                           -- The carrier unit that holds the self object.
  DCSScript[#DCSScript+1] = string.format('local mytanker  = mycarrier:GetState(mycarrier, \"RECOVERYTANKER_%d\") ', self.uid) -- Get the RECOVERYTANKER self object.
  DCSScript[#DCSScript+1] = string.format('mytanker:PatternUpdate()')                                                          -- Call the function, e.g. mytanker.(self)

  -- Create task.
  local DCSTask = CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))

  return DCSTask
end

--- Init waypoint after spawn. Tanker is first guided to a position astern the carrier and starts its racetrack pattern from there.
-- @param #RECOVERYTANKER self
-- @param #number dist Distance [NM] of initial waypoint astern carrier. Default 8 NM.
-- @param #number delay Delay before routing in seconds. Default 1 second.
function RECOVERYTANKER:_InitRoute(dist, delay)

  -- Defaults.
  dist=dist or UTILS.NMToMeters(8)
  delay=delay or 1
  
  -- Debug message.
  self:T(self.lid..string.format("Initializing route of recovery tanker %s.", self.tanker:GetName()))
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- First waypoint is ~10 NM behind and slightly port the boat.
  local p=Carrier:Translate(dist, hdg+190):SetAltitude(self.altitude)
  
  -- Speed for waypoints in km/h.
  -- This causes a problem, because the tanker might not be alive yet ==> We schedule the call of _InitRoute
  local speed=self.tanker:GetSpeedMax()*0.8
  
  -- Set to 280 knots and convert to km/h.
  --local speed=280/0.539957
  
  -- Debug mark.
  if self.Debug then
    p:MarkToAll(string.format("Enter Pattern WP: alt=%d ft, speed=%d kts", UTILS.MetersToFeet(self.altitude), speed*0.539957))
  end
  
  -- Task to update pattern when wp 2 is reached.
  local task=self:_InitPatternTaskFunction()

  -- Waypoints.
  local wp={}
  if self.takeoff==SPAWN.Takeoff.Air then
    wp[#wp+1]=self.tanker:GetCoordinate():SetAltitude(self.altitude):WaypointAirTurningPoint(nil, speed, {}, "Spawn Position")
  else
    wp[#wp+1]=Carrier:WaypointAirTakeOffParking()
  end
  wp[#wp+1]=p:WaypointAirTurningPoint(nil, speed, {task}, "Enter Pattern")
    
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
-- @return #boolean If true, heading and/or position have changed more than 5 degrees or 10 km, respectively.
function RECOVERYTANKER:_CheckPatternUpdate(dt)

  -- Get current position and orientation of carrier.
  local pos=self.carrier:GetCoordinate()
  
  -- Current orientation of carrier.
  local vNew=self.carrier:GetOrientationX()
  
  -- Reference orientation of carrier after the last update
  local vOld=self.orientation
  
  -- Last orientation from 30 seconds ago.
  local vLast=self.orientlast
  
  -- We only need the X-Z plane.
  vNew.y=0 ; vOld.y=0 ; vLast.y=0
  
  -- Get angle between old and new orientation vectors in rad and convert to degrees.
  local deltaHeading=math.deg(math.acos(UTILS.VecDot(vNew,vOld)/UTILS.VecNorm(vNew)/UTILS.VecNorm(vOld)))
  
  -- Angle between current heading and last time we checked ~30 seconds ago.
  local deltaLast=math.deg(math.acos(UTILS.VecDot(vNew,vLast)/UTILS.VecNorm(vNew)/UTILS.VecNorm(vLast)))
  
  -- Last orientation becomes new orientation
  self.orientlast=vNew
  
  -- Carrier is turning when its heading changed by at least one degree since last check.
  local turning=deltaLast>=1
  
  -- Debug output if turning
  if turning then
    self:T2(self.lid..string.format("Carrier is turning. Delta Heading = %.1f", deltaLast))
  end

  -- Check if orientation changed.
  local Hchange=false
  if math.abs(deltaHeading)>=self.Hupdate then
    self:T(self.lid..string.format("Carrier heading changed by %d degrees. Turning=%s.", deltaHeading, tostring(turning)))
    Hchange=true
  end
  
  -- Get distance to saved position.
  local dist=pos:Get2DDistance(self.position)
  
  -- Check if carrier moved more than ~5 NM.
  local Dchange=false
  if dist>self.Dupdate then
    self:T(self.lid..string.format("Carrier position changed by %.1f NM. Turning=%s.", UTILS.MetersToNM(dist), tostring(turning)))
    Dchange=true
  end
  
  -- Assume no update necessary.
  local update=false
  
  -- No update if currently turning! Also must be running (not RTB or refueling) and T>~10 min since last position update.
  if self:IsRunning() and dt>self.dTupdate and not turning then
  
    -- Update if heading or distance changed.
    if Hchange or Dchange then
      -- Debug message.
      local text=string.format("Updating tanker %s pattern due to carrier position=%s or heading=%s change.", self.tanker:GetName(), tostring(Dchange), tostring(Hchange))
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
      self:T(self.lid..text)
      
      -- Update pos and orientation.
      self.orientation=vNew
      self.position=pos
      update=true
    end
    
  end
    
  return update
end

--- Activate TACAN of tanker.
-- @param #RECOVERYTANKER self
-- @param #number delay Delay in seconds.
function RECOVERYTANKER:_ActivateTACAN(delay)

  if delay and delay>0 then
  
    -- Schedule TACAN activation.
    self:ScheduleOnce(delay, RECOVERYTANKER._ActivateTACAN, self)
    
  else

    -- Get tanker unit.
    local unit=self.tanker:GetUnit(1)
    
    -- Check if unit is alive.
    if unit and unit:IsAlive() then
    
      -- Debug message.
      local text=string.format("Activating TACAN beacon: channel=%d mode=%s, morse=%s.", self.TACANchannel, self.TACANmode, self.TACANmorse)
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
      self:T(self.lid..text)      
    
      -- Create a new beacon and activate TACAN.
      self.beacon=BEACON:New(unit)
      self.beacon:ActivateTACAN(self.TACANchannel, self.TACANmode, self.TACANmorse, true)
            
    else
      self:E(self.lid.."ERROR: Recovery tanker is not alive!")
    end
    
  end

end

--- Self made race track pattern. Not working as desired, since tanker changes course too rapidly after each waypoint.
-- @param #RECOVERYTANKER self
-- @return #table Table of pattern waypoints.
function RECOVERYTANKER:_Pattern()

  -- Carrier heading.
  local hdg=self.carrier:GetHeading()
  
  -- Pattern altitude
  local alt=self.altitude
  
  -- Carrier position.
  local Carrier=self.carrier:GetCoordinate()
  
  local width=UTILS.NMToMeters(8)
  
  -- Define race-track pattern.
  local p={}
  p[1]=self.tanker:GetCoordinate()                      -- Tanker position
  p[2]=Carrier:SetAltitude(alt)                         -- Carrier position
  p[3]=p[2]:Translate(self.distBow, hdg)                -- In front of carrier
  p[4]=p[3]:Translate(width/math.sqrt(2), hdg-45)       -- Middle front for smoother curve
  -- Probably need one more to make it go -hdg at the waypoint.
  p[5]=p[3]:Translate(width, hdg-90)                    -- In front on port
  p[6]=p[5]:Translate(self.distStern-self.distBow, hdg) -- Behind on port (sterndist<0!)
  p[7]=p[2]:Translate(self.distStern, hdg)              -- Behind carrier
  
  local wp={}
  for i=1,#p do
    local coord=p[i] --Core.Point#COORDINATE
    coord:MarkToAll(string.format("Waypoint %d", i))
    --table.insert(wp, coord:WaypointAirFlyOverPoint(nil , self.speed))
    table.insert(wp, coord:WaypointAirTurningPoint(nil , UTILS.MpsToKmph(self.speed)))
  end

  return wp
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
