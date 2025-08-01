--- **OPS** - Air Traffic Control for AI and human players.
-- 
-- **Main Features:**
--
--    * Manage aircraft departure and arrival
--    * Handles AI and human players
--    * Limit number of AI groups taxiing, taking off and landing simultaneously
--    * Immersive voice overs via SRS text-to-speech
--    * Define holding patterns for airdromes
--     
-- ===
--
-- ## Example Missions:
--
-- Demo missions: None
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module OPS.FlightControl
-- @image OPS_FlightControl.png


--- FLIGHTCONTROL class.
-- @type FLIGHTCONTROL
-- @field #string ClassName Name of the class.
-- @field #boolean verbose Verbosity level.
-- @field #string theatre The DCS map used in the mission.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string airbasename Name of airbase.
-- @field #string alias Radio alias, e.g. "Batumi Tower".
-- @field #number airbasetype Type of airbase.
-- @field Wrapper.Airbase#AIRBASE airbase Airbase object.
-- @field Core.Zone#ZONE zoneAirbase Zone around the airbase.
-- @field #table parking Parking spots table.
-- @field #table flights All flights table.
-- @field #table clients Table with all clients spawning at this airbase.
-- @field Ops.ATIS#ATIS atis ATIS object.
-- @field #number frequency ATC radio frequency in MHz.
-- @field #number modulation ATC radio modulation, *e.g.* `radio.modulation.AM`.
-- @field #number NlandingTot Max number of aircraft groups in the landing pattern.
-- @field #number NlandingTakeoff Max number of groups taking off to allow landing clearance.
-- @field #number NtaxiTot Max number of aircraft groups taxiing to runway for takeoff.
-- @field #boolean NtaxiInbound Include inbound taxiing groups.
-- @field #number NtaxiLanding Max number of aircraft landing for groups taxiing to runway for takeoff.
-- @field #number dTlanding Time interval in seconds between landing clearance.
-- @field #number Tlanding Time stamp (abs.) when last flight got landing clearance.
-- @field #number Nparkingspots Total number of parking spots.
-- @field Core.Spawn#SPAWN parkingGuard Parking guard spawner.
-- @field #table holdingpatterns Holding points.
-- @field #number hpcounter Counter for holding zones.
-- @field Sound.SRS#MSRSQUEUE msrsqueue Queue for TTS transmissions using MSRS class.
-- @field Sound.SRS#MSRS msrsTower Moose SRS wrapper.
-- @field Sound.SRS#MSRS msrsPilot Moose SRS wrapper.
-- @field #number Tlastmessage Time stamp (abs.) of last radio transmission.
-- @field #number dTmessage Time interval between messages.
-- @field #boolean markPatterns If `true`, park holding pattern.
-- @field #number speedLimitTaxi Taxi speed limit in m/s.
-- @field #number runwaydestroyed Time stamp (abs), when runway was destroyed. If `nil`, runway is operational.
-- @field #number runwayrepairtime Time in seconds until runway will be repaired after it was destroyed. Default is 3600 sec (one hour).
-- @field #boolean markerParking If `true`, occupied parking spots are marked.
-- @field #boolean nosubs If `true`, SRS TTS is without subtitles.
-- @field #number Nplayers Number of human players. Updated at each StatusUpdate call.
-- @field #boolean radioOnlyIfPlayers Activate to limit transmissions only if players are active at the airbase.
-- @extends Core.Fsm#FSM

--- **Ground Control**: Airliner X, Good news, you are clear to taxi to the active.
--  **Pilot**: Roger, What's the bad news?
--  **Ground Control**: No bad news at the moment, but you probably want to get gone before I find any.
--
-- ===
--
-- # The FLIGHTCONTROL Concept
-- 
-- This class implements an ATC for human and AI controlled aircraft. It gives permission for take-off and landing based on a sophisticated queueing system.
-- Therefore, it solves (or reduces) a lot of common problems with the DCS implementation.
-- 
-- You might be familiar with the `AIRBOSS` class. This class is the analogue for land based airfields. One major difference is that no pre-recorded sound files are 
-- necessary. The radio transmissions use the SRS text-to-speech feature.
-- 
-- ## Prerequisites
-- 
-- * SRS is used for radio communications
-- 
-- ## Limitations
-- 
-- Some (DCS) limitations you should be aware of:
-- 
-- * As soon as AI aircraft taxi or land, we completely loose control. All is governed by the internal DCS AI logic.
-- * We have no control over the active runway or which runway is used by the AI if there are multiple.
-- * Only one player/client per group as we can create menus only for a group and not for a specific unit.
-- * Only FLIGHTGROUPS are controlled. This means some older classes, *e.g.* RAT are not supported (yet).
-- * So far only airdromes are handled, *i.e.* no FARPs or ships.
-- * Helicopters are not treated differently from fixed wing aircraft until now.
-- * The active runway can only be determined by the wind direction. So at least set a very light wind speed in your mission.
-- 
-- # Basic Usage
-- 
-- A flight control for a given airdrome can be created with the @{#FLIGHTCONTROL.New}(*AirbaseName, Frequency, Modulation, PathToSRS*) function. You need to specify the name of the airbase, the 
-- tower radio frequency, its modulation and the path, where SRS is located on the machine that is running this mission.
-- 
-- For the FC to be operating, it needs to be started with the @{#FLIGHTCONTROL.Start}() function.
-- 
-- ## Simple Script
-- 
-- The simplest script looks like
-- 
--      local FC_BATUMI=FLIGHTCONTROL:New(AIRBASE.Caucasus.Batumi, 251, nil, "D:\\SomeDirectory\\_SRS")
--      FC_BATUMI:Start()
-- 
-- This will start the FC for at the Batumi airbase with tower frequency 251 MHz AM. SRS needs to be in the given directory.
-- 
-- Like this, a default holding pattern (see below) is parallel to the direction of the active runway.
-- 
-- # Holding Patterns
-- 
-- Holding pattern are air spaces where incoming aircraft are guided to and have to hold until they get landing clearance.
-- 
-- You can add a holding pattern with the @{#FLIGHTCONTROL.AddHoldingPattern}(*ArrivalZone, Heading, Length, FlightlevelMin, FlightlevelMax, Prio*) function, where
-- 
-- * `ArrivalZone` is the zone where the aircraft enter the pattern.
-- * `Heading` is the direction into which the aircraft have to fly from the arrival zone.
-- * `Length` is the length of the pattern.
-- * `FlightLevelMin` is the lowest altitude at which aircraft can hold.
-- * `FlightLevelMax` is the highest altitude at which aircraft can hold.
-- * `Prio` is the priority of this holding stacks. If multiple patterns are defined, patterns with higher prio will be filled first.
-- 
-- # Parking Guard
-- 
-- A "parking guard" is a group or static object, that is spawned in front of parking aircraft. This is useful to stop AI groups from taxiing if they are spawned with hot engines.
-- It is also handy to forbid human players to taxi until they ask for clearance.
-- 
-- You can activate the parking guard with the @{#FLIGHTCONTROL.SetParkingGuard}(*GroupName*) function, where the parameter `GroupName` is the name of a late activated template group.
-- This should consist of only *one* unit, *e.g.* a single infantry soldier.
-- 
-- You can also use static objects as parking guards with the @{#FLIGHTCONTROL.SetParkingGuardStatic}(*StaticName*), where the parameter `StaticName` is the name of a static object placed
-- somewhere in the mission editor.
-- 
-- # Limits for Inbound and Outbound Flights
-- 
-- You can define limits on how many aircraft are simultaneously landing and taking off. This avoids (DCS) problems where taxiing aircraft cause a "traffic jam" on the taxi way(s)
-- and bring the whole airbase effectively to a stand still.
-- 
-- ## Landing Limits
-- 
-- The number of groups getting landing clearance can be set with the @{#FLIGHTCONTROL.SetLimitLanding}(*Nlanding, Ntakeoff*) function. 
-- The first parameter, `Nlanding`, defines how many groups get clearance simultaneously.
-- 
-- The second parameter, `Ntakeoff`, sets a limit on how many flights can take off whilst inbound flights still get clearance. By default, this is set to zero because the runway can only be used for takeoff *or*
-- landing. So if you have a flight taking off, inbound fights will have to wait until the runway is clear. 
-- If you have an airport with more than one runway, *e.g.* Nellis AFB, you can allow simultanious landings and takeoffs by setting this number greater zero.
-- 
-- The time interval between clerances can be set with the @{#FLIGHTCONTROL.SetLandingInterval}(`dt`) function, where the parameter `dt` specifies the time interval in seconds before 
-- the next flight get clearance. This only has an effect if `Nlanding` is greater than one.
-- 
-- ## Taxiing/Takeoff Limits
-- 
-- The number of AI flight groups getting clearance to taxi to the runway can be set with the @{#FLIGHTCONTROL.SetLimitTaxi}(*Nlanding, Ntakeoff*) function. 
-- The first parameter, `Ntaxi`, defines how many groups are allowed to taxi to the runway simultaneously. Note that once the AI starts to taxi, we loose complete control over it.
-- They will follow their internal logic to get the the runway and take off. Therefore, giving clearance to taxi is equivalent to giving them clearance for takeoff.
-- 
-- By default, the parameter only counts the number of flights taxiing *to* the runway. If you set the second parameter, `IncludeInbound`, to `true`, this will also count the flights
-- that are taxiing to their parking spot(s) after they landed.
-- 
-- The third parameter, `Nlanding`, defines how many aircraft can land whilst outbound fights still get taxi/takeoff clearance. By default, this is set to zero because the runway
-- can only be used for takeoff *or* landing. If you have an airport with more than one runway, *e.g.* Nellis AFB, you can allow aircraft to taxi to the runway while other flights are landing
-- by setting this number greater zero.  
--
-- Note that the limits here are only affecting **AI** aircraft groups. *Human players* are assumed to be a lot more well behaved and capable as they are able to taxi around obstacles, *e.g.*
-- other aircraft etc. Therefore, players will get taxi clearance independent of the number of inbound and/or outbound flights. Players will, however, still need to ask for takeoff clearance once
-- they are holding short of the runway.
-- 
-- # Speeding Violations
-- 
-- You can set a speed limit for taxiing players with the @{#FLIGHTCONTROL.SetSpeedLimitTaxi}(*SpeedLimit*) function, where the parameter `SpeedLimit` is the max allowed speed in knots.
-- If players taxi faster, they will get a radio message. Additionally, the FSM event `PlayerSpeeding` is triggered and can be captured with the `OnAfterPlayerSpeeding` function.
-- For example, this can be used to kick players that do not behave well.
-- 
-- # Runway Destroyed
-- 
-- Once a runway is damaged, DCS AI will stop taxiing. Therefore, this class monitors if a runway is destroyed. If this is the case, all AI taxi and landing clearances will be suspended for
-- one hour. This is the hard coded time in DCS until the runway becomes operational again. If that ever changes, you can manually set the repair time with the 
-- @{#FLIGHTCONTROL.SetRunwayRepairtime} function.
-- 
-- Note that human players we still get taxi, takeoff and landing clearances.
-- 
-- If the runway is destroyed, the FSM event `RunwayDestroyed` is triggered and can be captured with the @{#FLIGHTCONTROL.OnAfterRunwayDestroyed} function.
-- 
-- If the runway is repaired, the FSM event `RunwayRepaired` is triggered and can be captured with the @{#FLIGHTCONTROL.OnAfterRunwayRepaired} function.
-- 
-- # SRS
-- 
-- SRS text-to-speech is used to send radio messages from the tower and pilots.
-- 
-- ## Tower
-- 
-- You can set the options for the tower SRS voice with the @{#FLIGHTCONTROL.SetSRSTower}() function.
-- 
-- ## Pilot
-- 
-- You can set the options for the pilot SRS voice with the @{#FLIGHTCONTROL.SetSRSPilot}() function.
-- 
-- # Runways
-- 
-- First note, that we have extremely limited control over which runway the DCS AI groups use. The only parameter we can adjust is the direction of the wind. In many cases, the AI will try to takeoff and land
-- against the wind, which therefore determines the active runway. There are, however, cases where this does not hold true. For example, at Nellis AFB the runway for takeoff is `03L` while the runway for
-- landing is `21L`.
-- 
-- By default, the runways for landing and takeoff are determined from the wind direction as described above. For cases where this gives wrong results, you can set the active runways manually. This is
-- done via @{Wrapper.Airbase#AIRBASE} class.
-- 
-- More specifically, you can use the @{Wrapper.Airbase#AIRBASE.SetActiveRunwayLanding} function to set the landing runway and the @{Wrapper.Airbase#AIRBASE.SetActiveRunwayTakeoff} function to set
-- the runway for takeoff.
-- 
-- ## Example for Nellis AFB
-- 
-- For Nellis, you can use:
-- 
--     -- Nellis AFB.
--     local Nellis=AIRBASE:FindByName(AIRBASE.Nevada.Nellis_AFB)
--     Nellis:SetActiveRunwayLanding("21L")
--     Nellis:SetActiveRunwayTakeoff("03L")
-- 
-- # DCS ATC
-- 
-- You can disable the DCS ATC with the @{Wrapper.Airbase#AIRBASE.SetRadioSilentMode}(*true*). This does not remove the DCS ATC airbase from the F10 menu but makes the ATC unresponsive.
-- 
-- 
-- # Examples
-- 
-- In this section, you find examples for different airdromes.
-- 
-- ## Nellis AFB
--     
--     -- Create a new FLIGHTCONTROL object at Nellis AFB. The tower frequency is 251 MHz AM. Path to SRS has to be adjusted. 
--     local atcNellis=FLIGHTCONTROL:New(AIRBASE.Nevada.Nellis_AFB, 251, nil, "D:\\My SRS Directory")
--     -- Set a parking guard from a static named "Static Generator F Template".
--     atcNellis:SetParkingGuardStatic("Static Generator F Template")
--     -- Set taxi speed limit to 25 knots.
--     atcNellis:SetSpeedLimitTaxi(25)
--     -- Set that max 3 groups are allowed to taxi simultaneously.
--     atcNellis:SetLimitTaxi(3, false, 1)
--     -- Set that max 2 groups are allowd to land simultaneously and unlimited number (99) groups can land, while other groups are taking off.
--     atcNellis:SetLimitLanding(2, 99)
--     -- Use Google for text-to-speech.
--     atcNellis:SetSRSTower(nil, nil, "en-AU-Standard-A", nil, nil, "D:\\Path To Google\\GoogleCredentials.json")
--     atcNellis:SetSRSPilot(nil, nil, "en-US-Wavenet-I",  nil, nil, "D:\\Path To Google\\GoogleCredentials.json")
--     -- Define two holding zones.
--     atcNellis:AddHoldingPattern(ZONE:New("Nellis Holding Alpha"), 030, 15, 6, 10, 10)
--     atcNellis:AddHoldingPattern(ZONE:New("Nellis Holding Bravo"), 090, 15, 6, 10, 20)
--     -- Start the ATC.
--     atcNellis:Start()
-- 
-- @field #FLIGHTCONTROL
FLIGHTCONTROL = {
  ClassName      = "FLIGHTCONTROL",
  verbose        =     0,
  lid            =   nil,
  theatre        =   nil,
  airbasename    =   nil,
  airbase        =   nil,
  airbasetype    =   nil,
  zoneAirbase    =   nil,
  parking        =    {},
  runways        =    {},
  flights        =    {},
  clients        =    {},
  atis           =   nil,
  Nlanding         = nil,
  dTlanding        = nil,
  Nparkingspots    = nil,
  holdingpatterns  =  {},
  hpcounter        =   0,
  nosubs         =  false,
  Nplayers       =     0,
}

--- Holding point. Contains holding stacks.
-- @type FLIGHTCONTROL.HoldingPattern
-- @field Core.Zone#ZONE arrivalzone Zone where aircraft should arrive.
-- @field #number uid Unique ID.
-- @field #string name Name of the zone, which is <zonename>-<uid>.
-- @field Core.Point#COORDINATE pos0 First position of racetrack holding pattern.
-- @field Core.Point#COORDINATE pos1 Second position of racetrack holding pattern.
-- @field #number angelsmin Smallest holding altitude in angels.
-- @field #number angelsmax Largest holding alitude in angels.
-- @field #table stacks Holding stacks.
-- @field #number markArrival Marker ID of the arrival zone.
-- @field #number markArrow Marker ID of the direction.

--- Holding stack.
-- @type FLIGHTCONTROL.HoldingStack
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup Flight group of this stack.
-- @field #number angels Holding altitude in Angels.
-- @field Core.Point#COORDINATE pos0 First position of racetrack holding pattern.
-- @field Core.Point#COORDINATE pos1 Second position of racetrack holding pattern.
-- @field #number heading Heading.


--- Parking spot data.
-- @type FLIGHTCONTROL.ParkingSpot
-- @field Wrapper.Group#GROUP ParkingGuard Parking guard for this spot.
-- @extends Wrapper.Airbase#AIRBASE.ParkingSpot

--- Flight status.
-- @type FLIGHTCONTROL.FlightStatus
-- @field #string UNKNOWN Flight is unknown.
-- @field #string INBOUND Flight is inbound.
-- @field #string HOLDING Flight is holding.
-- @field #string LANDING Flight is landing.
-- @field #string TAXIINB Flight is taxiing to parking area.
-- @field #string ARRIVED Flight arrived at parking spot.
-- @field #string TAXIOUT Flight is taxiing to runway for takeoff.
-- @field #string READYTX Flight is ready to taxi.
-- @field #string READYTO Flight is ready for takeoff.
-- @field #string TAKEOFF Flight is taking off.
FLIGHTCONTROL.FlightStatus={
  UNKNOWN="Unknown",
  PARKING="Parking",
  READYTX="Ready To Taxi",
  TAXIOUT="Taxi To Runway",
  READYTO="Ready For Takeoff",
  TAKEOFF="Takeoff",          
  INBOUND="Inbound",
  HOLDING="Holding",
  LANDING="Landing",
  TAXIINB="Taxi To Parking",
  ARRIVED="Arrived",
}

--- FlightControl class version.
-- @field #string version
FLIGHTCONTROL.version="0.7.7"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list

-- TODO: Switch to enable/disable AI messages.
-- TODO: Talk me down option.
-- TODO: Check runways and clean up.
-- TODO: Add FARPS?
-- DONE: Improve ATC TTS messages.
-- DONE: ATIS option.
-- DONE: Runway destroyed.
-- DONE: Accept and forbit parking spots. DONE via AIRBASE black/white lists and airwing features.
-- DONE: Support airwings. Dont give clearance for Alert5 or if mission has not started.
-- DONE: Define holding zone.
-- DONE: Basic ATC voice overs.
-- DONE: Add SRS TTS.
-- DONE: Add parking guard.
-- DONE: Interface with FLIGHTGROUP.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTCONTROL class object for an associated airbase.
-- @param #FLIGHTCONTROL self
-- @param #string AirbaseName Name of the airbase.
-- @param #number Frequency Radio frequency in MHz. Default 143.00 MHz. Can also be given as a `#table` of multiple frequencies.
-- @param #number Modulation Radio modulation: 0=AM (default), 1=FM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators. Can also be given as a `#table` of multiple modulations.
-- @param #string PathToSRS Path to the directory, where SRS is located.
-- @param #number Port Port of SRS Server, defaults to 5002
-- @param #string GoogleKey Path to the Google JSON-Key.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:New(AirbaseName, Frequency, Modulation, PathToSRS, Port, GoogleKey)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #FLIGHTCONTROL
  
  -- Try to get the airbase.
  self.airbase=AIRBASE:FindByName(AirbaseName)
  
  -- Name of the airbase.
  self.airbasename=AirbaseName  
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTCONTROL %s | ", AirbaseName)  
  
  -- Check if the airbase exists.
  if not self.airbase then
    self:E(string.format("ERROR: Could not find airbase %s!", tostring(AirbaseName)))
    return nil
  end
  -- Check if airbase is an airdrome.
  if self.airbase:GetAirbaseCategory()~=Airbase.Category.AIRDROME then
    self:E(string.format("ERROR: Airbase %s is not an AIRDROME! Script does not handle FARPS or ships.", tostring(AirbaseName)))
    return nil
  end
  
  -- Airbase category airdrome, FARP, SHIP.
  self.airbasetype=self.airbase:GetAirbaseCategory()
  
  -- Current map.
  self.theatre=env.mission.theatre    
  
  -- 5 NM zone around the airbase.
  self.zoneAirbase=ZONE_RADIUS:New("FC", self:GetCoordinate():GetVec2(), UTILS.NMToMeters(5))
  
  -- Add backup holding pattern.
  self:_AddHoldingPatternBackup()

  -- Set alias.
  self.alias=self.airbasename.." Tower"
  
  -- Defaults:
  self:SetLimitLanding(2, 0)
  self:SetLimitTaxi(2, false, 0)
  self:SetLandingInterval()
  self:SetFrequency(Frequency, Modulation)
  self:SetMarkHoldingPattern(true)
  self:SetRunwayRepairtime()
  self.nosubs = false
  
  -- Set Callsign Options
  self:SetCallSignOptions(true,true)
  
  -- Init msrs queue.
  self.msrsqueue=MSRSQUEUE:New(self.alias)
  
  -- Set that transmission is only if alive players on the server.
  self:SetTransmitOnlyWithPlayers(true)
  
  -- Init msrs bases
  local path = PathToSRS or MSRS.path
  local port = Port or MSRS.port or 5002
  
  -- Set SRS Port
  self:SetSRSPort(port)
  
  -- SRS for Tower.
  self.msrsTower=MSRS:New(path, Frequency, Modulation)
  self.msrsTower:SetPort(port)
  if GoogleKey then
    self.msrsTower:SetProviderOptionsGoogle(GoogleKey,GoogleKey)
    self.msrsTower:SetProvider(MSRS.Provider.GOOGLE)
  end  
  self.msrsTower:SetCoordinate(self:GetCoordinate())
  self:SetSRSTower()
  
  -- SRS for Pilot.
  self.msrsPilot=MSRS:New(PathToSRS, Frequency, Modulation)
  self.msrsPilot:SetPort(self.Port)
  if GoogleKey then
    self.msrsPilot:SetProviderOptionsGoogle(GoogleKey,GoogleKey)
    self.msrsPilot:SetProvider(MSRS.Provider.GOOGLE)
  end  
  self.msrsTower:SetCoordinate(self:GetCoordinate())
  self:SetSRSPilot()
  
  -- Wait at least 10 seconds after last radio message before calling the next status update.
  self.dTmessage=10
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event         -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "StatusUpdate",       "*")           -- Update status.
  
  self:AddTransition("*",             "PlayerKilledGuard",  "*")           -- Player killed parking guard
  self:AddTransition("*",             "PlayerSpeeding",     "*")           -- Player speeding on taxi way.

  self:AddTransition("*",             "RunwayDestroyed",    "*")           -- Runway of the airbase was destroyed.
  self:AddTransition("*",             "RunwayRepaired",     "*")           -- Runway of the airbase was repaired.
  
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.
  
  -- Add to data base.
  _DATABASE:AddFlightControl(self)


  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start".
  -- @function [parent=#FLIGHTCONTROL] Start
  -- @param #FLIGHTCONTROL self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __Start
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop".
  -- @function [parent=#FLIGHTCONTROL] Stop
  -- @param #FLIGHTCONTROL self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __Stop
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "StatusUpdate".
  -- @function [parent=#FLIGHTCONTROL] StatusUpdate
  -- @param #FLIGHTCONTROL self

  --- Triggers the FSM event "StatusUpdate" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __StatusUpdate
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "RunwayDestroyed".
  -- @function [parent=#FLIGHTCONTROL] RunwayDestroyed
  -- @param #FLIGHTCONTROL self

  --- Triggers the FSM event "RunwayDestroyed" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __RunwayDestroyed
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.

  --- On after "RunwayDestroyed" event.
  -- @function [parent=#FLIGHTCONTROL] OnAfterRunwayDestroyed
  -- @param #FLIGHTCONTROL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "RunwayRepaired".
  -- @function [parent=#FLIGHTCONTROL] RunwayRepaired
  -- @param #FLIGHTCONTROL self

  --- Triggers the FSM event "RunwayRepaired" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __RunwayRepaired
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.

  --- On after "RunwayRepaired" event.
  -- @function [parent=#FLIGHTCONTROL] OnAfterRunwayRepaired
  -- @param #FLIGHTCONTROL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "PlayerSpeeding".
  -- @function [parent=#FLIGHTCONTROL] PlayerSpeeding
  -- @param #FLIGHTCONTROL self
  -- @param Ops.FlightGroup#FLIGHTGROUP.PlayerData Player data.

  --- Triggers the FSM event "PlayerSpeeding" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __PlayerSpeeding
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.
  -- @param Ops.FlightGroup#FLIGHTGROUP.PlayerData Player data.

  --- On after "PlayerSpeeding" event.
  -- @function [parent=#FLIGHTCONTROL] OnAfterPlayerSpeeding
  -- @param #FLIGHTCONTROL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP.PlayerData Player data.


  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #FLIGHTCONTROL self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Limit radio transmissions only if human players are registered at the airbase.
-- This can be used to reduce TTS messages on heavy missions.
-- @param #FLIGHTCONTROL self
-- @param #boolean Switch If `true` or `nil` no transmission if there are no players. Use `false` enable TTS with no players.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetRadioOnlyIfPlayers(Switch)
  if Switch==nil or Switch==true then
    self.radioOnlyIfPlayers=true
  else
    self.radioOnlyIfPlayers=false
  end
  return self
end


--- Set whether to only transmit TTS messages if there are players on the server.
-- @param #FLIGHTCONTROL self
-- @param #boolean Switch If `true`, only send TTS messages if there are alive Players. If `false` or `nil`, transmission are done also if no players are on the server.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetTransmitOnlyWithPlayers(Switch)
  self.msrsqueue:SetTransmitOnlyWithPlayers(Switch)
  return self
end


--- Set subtitles to appear on SRS TTS messages.
-- @param #FLIGHTCONTROL self
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SwitchSubtitlesOn()
  self.nosubs = false
  return self
end

--- Set subtitles to appear on SRS TTS messages.
-- @param #FLIGHTCONTROL self
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SwitchSubtitlesOff()
  self.nosubs = true
  return self
end

--- Set the tower frequency.
-- @param #FLIGHTCONTROL self
-- @param #number Frequency Frequency in MHz. Default 305 MHz.
-- @param #number Modulation Modulation `radio.modulation.AM`=0, `radio.modulation.FM`=1. Default `radio.modulation.AM`.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetFrequency(Frequency, Modulation)

  self.frequency=Frequency or 305
  self.modulation=Modulation or radio.modulation.AM
  
  if self.msrsPilot then
    self.msrsPilot:SetFrequencies(Frequency)
    self.msrsPilot:SetModulations(Modulation)
  end

  if self.msrsTower then
    self.msrsTower:SetFrequencies(Frequency)
    self.msrsTower:SetModulations(Modulation)
  end
  
  return self
end

--- Set the SRS server port.
-- @param #FLIGHTCONTROL self
-- @param #number Port Port to be used. Defaults to 5002.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetSRSPort(Port)
  self.Port = Port or 5002
  return self
end

--- Set SRS options for a given MSRS object.
-- @param #FLIGHTCONTROL self
-- @param Sound.SRS#MSRS msrs Moose SRS object.
-- @param #string Gender Gender: "male" or "female" (default).
-- @param #string Culture Culture, e.g. "en-GB" (default).
-- @param #string Voice Specific voice. Overrides `Gender` and `Culture`.
-- @param #number Volume Volume. Default 1.0.
-- @param #string Label Name under which SRS transmits.
-- @param #string PathToGoogleCredentials Path to google credentials json file.
-- @param #number Port Server port for SRS
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:_SetSRSOptions(msrs, Gender, Culture, Voice, Volume, Label, PathToGoogleCredentials, Port)

  -- Defaults:
  Gender=Gender or "female"
  Culture=Culture or "en-GB"
  Volume=Volume or 1.0

  if msrs then
    msrs:SetGender(Gender)
    msrs:SetCulture(Culture)
    msrs:SetVoice(Voice)
    msrs:SetVolume(Volume)
    msrs:SetLabel(Label)
    msrs:SetCoalition(self:GetCoalition())
    msrs:SetPort(Port or self.Port or 5002)
  end

  return self
end

--- Set SRS options for tower voice.
-- @param #FLIGHTCONTROL self
-- @param #string Gender Gender: "male" or "female" (default).
-- @param #string Culture Culture, e.g. "en-GB" (default).
-- @param #string Voice Specific voice. Overrides `Gender` and `Culture`. See [Google Voices](https://cloud.google.com/text-to-speech/docs/voices).
-- @param #number Volume Volume. Default 1.0.
-- @param #string Label Name under which SRS transmits. Default `self.alias`.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetSRSTower(Gender, Culture, Voice, Volume, Label)

  if self.msrsTower then
    self:_SetSRSOptions(self.msrsTower, Gender or "female", Culture or "en-GB", Voice, Volume, Label or self.alias)
  end

  return self
end

--- Set SRS options for pilot voice.
-- @param #FLIGHTCONTROL self
-- @param #string Gender Gender: "male" (default) or "female".
-- @param #string Culture Culture, e.g. "en-US" (default).
-- @param #string Voice Specific voice. Overrides `Gender` and `Culture`.
-- @param #number Volume Volume. Default 1.0.
-- @param #string Label Name under which SRS transmits. Default "Pilot".
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetSRSPilot(Gender, Culture, Voice, Volume, Label)

  if self.msrsPilot then
    self:_SetSRSOptions(self.msrsPilot, Gender or "male", Culture or "en-US", Voice, Volume, Label or "Pilot")
  end

  return self
end


--- Set the number of aircraft groups, that are allowed to land simultaneously.
-- Note that this restricts AI and human players.
-- 
-- By default, up to two groups get landing clearance. They are spaced out in time, i.e. after the first one got cleared, the second has to wait a bit.
-- This
-- 
-- By default, landing clearance is only given when **no** other flight is taking off. You can adjust this for airports with more than one runway or 
-- in cases where simultaneous takeoffs and landings are unproblematic. Note that only because there are multiple runways, it does not mean the AI uses them.
--  
-- @param #FLIGHTCONTROL self
-- @param #number Nlanding Max number of aircraft landing simultaneously. Default 2.
-- @param #number Ntakeoff Allowed number of aircraft taking off for groups to get landing clearance. Default 0. 
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetLimitLanding(Nlanding, Ntakeoff)

  self.NlandingTot=Nlanding or 2
  
  self.NlandingTakeoff=Ntakeoff or 0

  return self
end

--- Set time interval between landing clearance of groups.
-- @param #FLIGHTCONTROL self
-- @param #number dt Time interval in seconds. Default 180 sec (3 min).
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetLandingInterval(dt)

  self.dTlanding=dt or 180

  return self
end


--- Set the number of **AI** aircraft groups, that are allowed to taxi simultaneously.
-- If the limit is reached, other AI groups not get taxi clearance to taxi to the runway.
-- 
-- By default, this only counts the number of AI that taxi from their parking position to the runway.
-- You can also include inbound AI that taxi from the runway to their parking position.
-- This can be handy for problematic (usually smaller) airdromes, where there is only one taxiway inbound and outbound flights.
-- 
-- By default, AI will not get cleared for taxiing if at least one other flight is currently landing. If this is an unproblematic airdrome, you can 
-- also allow groups to taxi if planes are landing, *e.g.* if there are two separate runways.
-- 
-- NOTE that human players are *not* restricted as they should behave better (hopefully) than the AI.
-- 
-- @param #FLIGHTCONTROL self
-- @param #number Ntaxi Max number of groups allowed to taxi. Default 2.
-- @param #boolean IncludeInbound If `true`, the above
-- @param #number Nlanding Max number of landing flights. Default 0.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetLimitTaxi(Ntaxi, IncludeInbound, Nlanding)

  self.NtaxiTot=Ntaxi or 2
  
  self.NtaxiInbound=IncludeInbound
  
  self.NtaxiLanding=Nlanding or 0

  return self
end

--- Add a holding pattern.
-- This is a zone where the aircraft...
-- @param #FLIGHTCONTROL self
-- @param Core.Zone#ZONE ArrivalZone Zone where planes arrive.
-- @param #number Heading Heading in degrees.
-- @param #number Length Length in nautical miles. Default 15 NM.
-- @param #number FlightlevelMin Min flight level. Default 5.
-- @param #number FlightlevelMax Max flight level. Default 15.
-- @param #number Prio Priority. Lower is higher. Default 50.
-- @return #FLIGHTCONTROL.HoldingPattern Holding pattern table.
function FLIGHTCONTROL:AddHoldingPattern(ArrivalZone, Heading, Length, FlightlevelMin, FlightlevelMax, Prio)

  -- Get ZONE if passed as string.
  if type(ArrivalZone)=="string" then
    ArrivalZone=ZONE:New(ArrivalZone)
  end
  
  -- Increase counter.
  self.hpcounter=self.hpcounter+1

  local hp={} --#FLIGHTCONTROL.HoldingPattern
  hp.uid=self.hpcounter
  hp.arrivalzone=ArrivalZone  
  hp.name=string.format("%s-%d", ArrivalZone:GetName(), hp.uid)
  hp.pos0=ArrivalZone:GetCoordinate()
  hp.pos1=hp.pos0:Translate(UTILS.NMToMeters(Length or 15), Heading)
  hp.angelsmin=FlightlevelMin or 5
  hp.angelsmax=FlightlevelMax or 15
  hp.prio=Prio or 50
  
  hp.stacks={}
  for i=hp.angelsmin, hp.angelsmax do
    local stack={} --#FLIGHTCONTROL.HoldingStack
    stack.angels=i
    stack.flightgroup=nil
    stack.pos0=UTILS.DeepCopy(hp.pos0)
    stack.pos0:SetAltitude(UTILS.FeetToMeters(i*1000))
    stack.pos1=UTILS.DeepCopy(hp.pos1)
    stack.pos1:SetAltitude(UTILS.FeetToMeters(i*1000))
    stack.heading=Heading
    table.insert(hp.stacks, stack)
  end
  
  -- Add to table.
  table.insert(self.holdingpatterns, hp)

  -- Sort holding patterns wrt to prio.  
  local function _sort(a,b)
    return a.prio<b.prio
  end
  table.sort(self.holdingpatterns, _sort)
  
  return self
end

--- Remove a holding pattern.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.HoldingPattern HoldingPattern Holding pattern to be removed.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:RemoveHoldingPattern(HoldingPattern)

  for i,_holdingpattern in pairs(self.holdingpatterns) do
    local hp=_holdingpattern --#FLIGHTCONTROL.HoldingPattern
    
    if hp.uid==HoldingPattern.uid then
      self:_UnMarkHoldingPattern(HoldingPattern)
      table.remove(self.holdingpatterns, i)
      return self
    end
  end

  return self
end


--- Set to mark the holding patterns on the F10 map.
-- @param #FLIGHTCONTROL self
-- @param #boolean Switch If `true` (or `nil`), mark holding patterns.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetMarkHoldingPattern(Switch)

  if Switch==nil then
    Switch=true
  end
  
  self.markPatterns=Switch

  return self
end

--- Set speed limit for taxiing.
-- @param #FLIGHTCONTROL self
-- @param #number SpeedLimit Speed limit in knots. If `nil`, no speed limit.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetSpeedLimitTaxi(SpeedLimit)

  if SpeedLimit then
    self.speedLimitTaxi=UTILS.KnotsToMps(SpeedLimit)
  else
    self.speedLimitTaxi=nil
  end

  return self
end


--- Set the parking guard group. This group is used to block (AI) aircraft from taxiing until they get clearance. It should contain of only one unit, *e.g.* a simple soldier.
-- @param #FLIGHTCONTROL self
-- @param #string TemplateGroupName Name of the template group.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetParkingGuard(TemplateGroupName)

  local alias=string.format("Parking Guard %s", self.airbasename)

  -- Need spawn with alias for multiple FCs.  
  self.parkingGuard=SPAWN:NewWithAlias(TemplateGroupName, alias)

  return self
end

--- Set the parking guard static. This static is used to block (AI) aircraft from taxiing until they get clearance.
-- @param #FLIGHTCONTROL self
-- @param #string TemplateStaticName Name of the template static.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetParkingGuardStatic(TemplateStaticName)

  local alias=string.format("Parking Guard %s", self.airbasename)

  -- Need spawn with alias for multiple FCs.    
  self.parkingGuard=SPAWNSTATIC:NewFromStatic(TemplateStaticName):InitNamePrefix(alias)

  return self
end

--- Set ATIS.
-- @param #FLIGHTCONTROL self
-- @param Ops.ATIS#ATIS Atis ATIS.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetATIS(Atis)
  self.atis=Atis
  return self
end

--- Get coordinate of the airbase.
-- @param #FLIGHTCONTROL self
-- @return Core.Point#COORDINATE Coordinate of the airbase.
function FLIGHTCONTROL:GetCoordinate()
  return self.airbase:GetCoordinate()
end

--- Get coalition of the airbase.
-- @param #FLIGHTCONTROL self
-- @return #number Coalition ID.
function FLIGHTCONTROL:GetCoalition()
  return self.airbase:GetCoalition()
end

--- Get country of the airbase.
-- @param #FLIGHTCONTROL self
-- @return #number Country ID.
function FLIGHTCONTROL:GetCountry()
  return self.airbase:GetCountry()
end

--- Set the time until the runway(s) of an airdrome are repaired after it has been destroyed.
-- Note that this is the time, the DCS engine uses not something we can control on a user level or we could get via scripting.
-- You need to input the value. On the DCS forum it was stated that this is currently one hour. Hence this is the default value.
-- @param #FLIGHTCONTROL self
-- @param #number RepairTime Time in seconds until the runway is repaired. Default 3600sec (one hour).
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetRunwayRepairtime(RepairTime)
  self.runwayrepairtime=RepairTime or 3600
  return self
end

--- Check if runway is operational.
-- @param #FLIGHTCONTROL self
-- @return #number Time in seconds until the runway is repaired. Will return 0 if runway is repaired.
function FLIGHTCONTROL:GetRunwayRepairtime()
  if self.runwaydestroyed then
    local Tnow=timer.getAbsTime()
    local Tsince=Tnow-self.runwaydestroyed
    local Trepair=math.max(self.runwayrepairtime-Tsince, 0)
    return Trepair
  end
  return 0
end

--- Check if runway is operational.
-- @param #FLIGHTCONTROL self
-- @return #boolean If `true`, runway is operational.
function FLIGHTCONTROL:IsRunwayOperational()
  if self.airbase then
    if self.runwaydestroyed then
      return false
    else
      return true
    end
  end
  return nil
end

--- Check if runway is destroyed.
-- @param #FLIGHTCONTROL self
-- @return #boolean If `true`, runway is destroyed.
function FLIGHTCONTROL:IsRunwayDestroyed()
  if self.airbase then
    if self.runwaydestroyed then
      return true
    else
      return false
    end
  end
  return nil
end

--- Is flight in queue of this flightcontrol.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP Flight Flight group.
-- @return #boolean If `true`, flight is in queue.
function FLIGHTCONTROL:IsFlight(Flight)

  for _,_flight in pairs(self.flights) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    if flight.groupname==Flight.groupname then
      return true
    end
  end

  return false
end

--- Check if coordinate is on runway.
-- @param #FLIGHTCONTROL self
-- @param Core.Point#COORDINATE Coordinate
-- @return #boolean If `true`, coordinate is on a runway.
function FLIGHTCONTROL:IsCoordinateRunway(Coordinate)

  -- Get runways.
  local runways=self.airbase:GetRunways()
  
  -- Check all runways.
  for _,_runway in pairs(runways) do
    local runway=_runway --Wrapper.Airbase#AIRBASE.Runway
    
    -- Check if coordinate is in zone.
    if runway.zone:IsCoordinateInZone(Coordinate) then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start FLIGHTCONTROL FSM. Handle events.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStart()

  -- Events are handled my MOOSE.
  self:I(self.lid..string.format("Starting FLIGHTCONTROL v%s for airbase %s of type %d on map %s", FLIGHTCONTROL.version, self.airbasename, self.airbasetype, self.theatre))
  
  -- Init parking spots.
  self:_InitParkingSpots()  

  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.EngineStartup)
  self:HandleEvent(EVENTS.Takeoff)
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.EngineShutdown)
  self:HandleEvent(EVENTS.Crash, FLIGHTCONTROL.OnEventCrashOrDead)
  self:HandleEvent(EVENTS.Dead,  FLIGHTCONTROL.OnEventCrashOrDead)
  self:HandleEvent(EVENTS.Kill)
 
  -- Init status updates.
  self:__StatusUpdate(-1)
end

--- On Before Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onbeforeStatusUpdate()
  
  local Tqueue=self.msrsqueue:CalcTransmisstionDuration()
  
  if Tqueue>0 then
      -- Debug info.
      local text=string.format("Still got %d messages in the radio queue. Will call status again in %.1f sec", #self.msrsqueue, Tqueue)
      self:T(self.lid..text)
        
      -- Call status again in dt seconds.
      self:__StatusUpdate(-Tqueue)

      -- Deny transition.
      return false  
  end

  return true
end

--- Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStatusUpdate()

  -- Debug message.
  self:T2(self.lid.."Status update")
  
  -- Check markers of holding patterns.
  self:_CheckMarkHoldingPatterns()
  
  -- Check if runway was repaired.
  if self:IsRunwayOperational()==false then
    local Trepair=self:GetRunwayRepairtime()
    if Trepair==0 then
      self:RunwayRepaired()
    else
      self:I(self.lid..string.format("Runway still destroyed! Will be repaired in %d sec", Trepair))
    end
  end  

  -- Check status of all registered flights.
  self:_CheckFlights()
  
  -- Check parking spots.
  --self:_CheckParking()
  
  -- Check waiting and landing queue.
  self:_CheckQueues()
  
  -- Get runway.
  local rwyLanding=self:GetActiveRunwayText()
  local rwyTakeoff=self:GetActiveRunwayText(true)
    
  -- Count flights.
  local Nflights= self:CountFlights()
  local NQparking=self:CountFlights(FLIGHTCONTROL.FlightStatus.PARKING)
  local NQreadytx=self:CountFlights(FLIGHTCONTROL.FlightStatus.READYTX)
  local NQtaxiout=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIOUT)
  local NQreadyto=self:CountFlights(FLIGHTCONTROL.FlightStatus.READYTO)
  local NQtakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
  local NQinbound=self:CountFlights(FLIGHTCONTROL.FlightStatus.INBOUND)
  local NQholding=self:CountFlights(FLIGHTCONTROL.FlightStatus.HOLDING)
  local NQlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)
  local NQtaxiinb=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIINB)
  local NQarrived=self:CountFlights(FLIGHTCONTROL.FlightStatus.ARRIVED)
  -- =========================================================================================================
  local Nqueues = (NQparking+NQreadytx+NQtaxiout+NQreadyto+NQtakeoff) + (NQinbound+NQholding+NQlanding+NQtaxiinb+NQarrived)

  -- Count free parking spots.
  --TODO: get and substract number of reserved parking spots.
  local nfree=self.Nparkingspots-NQarrived-NQparking

  local Nfree=self:CountParking(AIRBASE.SpotStatus.FREE)
  local Noccu=self:CountParking(AIRBASE.SpotStatus.OCCUPIED)
  local Nresv=self:CountParking(AIRBASE.SpotStatus.RESERVED)
  
  if Nfree+Noccu+Nresv~=self.Nparkingspots then
    self:E(self.lid..string.format("WARNING: Number of parking spots does not match! Nfree=%d, Noccu=%d, Nreserved=%d != %d total", Nfree, Noccu, Nresv, self.Nparkingspots))
  end

  -- Info text.
  if self.verbose>=1 then
    local text=string.format("State %s - Runway Landing=%s, Takeoff=%s  - Parking F=%d/O=%d/R=%d of %d - Flights=%s: Qpark=%d Qtxout=%d Qready=%d Qto=%d | Qinbound=%d Qhold=%d Qland=%d Qtxinb=%d Qarr=%d", 
    self:GetState(), rwyLanding, rwyTakeoff, Nfree, Noccu, Nresv, self.Nparkingspots, Nflights, NQparking, NQtaxiout, NQreadyto, NQtakeoff, NQinbound, NQholding, NQlanding, NQtaxiinb, NQarrived)
    self:I(self.lid..text)
  end
  
  if Nflights==Nqueues then
    --Check!
  else
    self:E(string.format("WARNING: Number of total flights %d!=%d number of flights in all queues!", Nflights, Nqueues))
  end
  
  if self.verbose>=2 then
    local text="Holding Patterns:"
    for i,_pattern in pairs(self.holdingpatterns) do
      local pattern=_pattern --#FLIGHTCONTROL.HoldingPattern
      
      -- Pattern info.
      text=text..string.format("\n[%d] Pattern %s [Prio=%d, UID=%d]: Stacks=%d, Angels %d - %d", i, pattern.name, pattern.prio, pattern.uid, #pattern.stacks, pattern.angelsmin, pattern.angelsmax)
      
      if self.verbose>=4 then
        -- Explicit stack info.
        for _,_stack in pairs(pattern.stacks) do
          local stack=_stack --#FLIGHTCONTROL.HoldingStack
          local text=string.format("", stack.angels, stack)
        end
      end
    end
    self:I(self.lid..text)
  end

  -- Next status update in ~30 seconds.
  self:__StatusUpdate(-30)
end

--- Stop FLIGHTCONTROL FSM.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStop()

  -- Unhandle events.
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.EngineStartup)
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Kill)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for event birth.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventBirth(EventData)
  self:F3({EvendData=EventData})
    
  if EventData and EventData.IniGroupName and EventData.IniUnit then
  
    self:T3(self.lid..string.format("BIRTH: unit  = %s", tostring(EventData.IniUnitName)))
    self:T3(self.lid..string.format("BIRTH: group = %s", tostring(EventData.IniGroupName)))

    -- Unit that was born.
    local unit=EventData.IniUnit    
  
    -- We delay this, to have all elements of the group in the game.
    if unit:IsAir() then
    
      local bornhere=EventData.Place and EventData.Place:GetName()==self.airbasename or false
      --env.info("FF born here ".. tostring(bornhere))
    
      -- We got a player?
      local playerunit, playername=self:_GetPlayerUnitAndName(EventData.IniUnitName)
      
      if playername or bornhere then
    
        -- Create player menu.
        self:ScheduleOnce(0.5, self._CreateFlightGroup, self, EventData.IniGroup)
        
      end
      
      -- Spawn parking guard.
      if bornhere then
        self:SpawnParkingGuard(unit)
      end

    end
      
  end
  
end

--- Event handling function.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTCONTROL:OnEventCrashOrDead(EventData)

  if EventData then

    -- Check if out runway was destroyed.
    if EventData.IniUnitName then
      if self.airbase and self.airbasename and self.airbasename==EventData.IniUnitName then
        self:RunwayDestroyed()      
      end
    end
    
  end
  
end

--- Event handler for event land.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventLand(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("LAND: unit  = %s", tostring(EventData.IniUnitName)))
  self:T3(self.lid..string.format("LAND: group = %s", tostring(EventData.IniGroupName)))
  
end

--- Event handler for event takeoff.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventTakeoff(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("TAKEOFF: unit  = %s", tostring(EventData.IniUnitName)))
  self:T3(self.lid..string.format("TAKEOFF: group = %s", tostring(EventData.IniGroupName)))
  
  -- This would be the closest airbase.
  local airbase=EventData.Place
  
  -- Unit that took off.
  local unit=EventData.IniUnit
  
  -- Nil check for airbase. Crashed as player gave me no airbase.
  if not (airbase or unit) then
    self:E(self.lid.."WARNING: Airbase or IniUnit is nil in takeoff event!")
    return
  end
  
end

--- Event handler for event engine startup.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventEngineStartup(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("ENGINESTARTUP: unit  = %s", tostring(EventData.IniUnitName)))
  self:T3(self.lid..string.format("ENGINESTARTUP: group = %s", tostring(EventData.IniGroupName)))
  
end

--- Event handler for event engine shutdown.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventEngineShutdown(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("ENGINESHUTDOWN: unit  = %s", tostring(EventData.IniUnitName)))
  self:T3(self.lid..string.format("ENGINESHUTDOWN: group = %s", tostring(EventData.IniGroupName)))
  
end

--- Event handler for event kill.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventKill(EventData)
  self:F3({EvendData=EventData})
  
  -- Debug info.
  self:T2(self.lid..string.format("KILL: ini unit  = %s", tostring(EventData.IniUnitName)))
  self:T3(self.lid..string.format("KILL: ini group = %s", tostring(EventData.IniGroupName)))
  self:T2(self.lid..string.format("KILL: tgt unit  = %s", tostring(EventData.TgtUnitName)))
  self:T3(self.lid..string.format("KILL: tgt group = %s", tostring(EventData.TgtGroupName)))
  
  -- Parking guard name prefix.
  local guardPrefix=string.format("Parking Guard %s", self.airbasename)
  
  local victimName=EventData.IniUnitName
  local killerName=EventData.TgtUnitName
  
  if victimName and victimName:find(guardPrefix) then
    
    env.info(string.format("Parking guard %s killed!", victimName))
    
    for _,_flight in pairs(self.flights) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      local element=flight:GetElementByName(killerName)
      if element then
        env.info(string.format("Parking guard %s killed by %s!", victimName, killerName))
        return
      end
    end
    
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "RunwayDestroyed" event.
-- @param #FLIGHTCONTROL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTCONTROL:onafterRunwayDestroyed(From, Event, To)

  -- Debug Message.
  self:T(self.lid..string.format("Runway destoyed!"))

  -- Set time stamp.
  self.runwaydestroyed=timer.getAbsTime()
  
  self:TransmissionTower("All flights, our runway was destroyed. All operations are suspended for one hour.",Flight,Delay)
  
end

--- On after "RunwayRepaired" event.
-- @param #FLIGHTCONTROL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTCONTROL:onafterRunwayRepaired(From, Event, To)

  -- Debug Message.
  self:T(self.lid..string.format("Runway repaired!"))

  -- Set parameter.
  self.runwaydestroyed=nil

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Queue Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check takeoff and landing queues.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckQueues()

  -- Print queue.
  if self.verbose>=2 then
    self:_PrintQueue(self.flights,  "All flights")
  end

  -- Get next flight in line: either holding or parking.
  local flight, isholding, parking=self:_GetNextFlight()
  

  -- Check if somebody wants something.
  if flight then
      
    if isholding then

      --------------------
      -- Holding flight --
      --------------------

      -- No other flight is taking off and number of landing flights is below threshold.      
      if self:_CheckFlightLanding(flight) then

        -- Get interval to last flight that got landing clearance.
        local dTlanding=99999
        if self.Tlanding then
          dTlanding=timer.getAbsTime()-self.Tlanding
        end
      
        if parking and dTlanding>=self.dTlanding then
        
          -- Get callsign.
          local callsign=self:_GetCallsignName(flight)
          
          -- Runway.
          local runway=self:GetActiveRunwayText()
                
          -- Message.
          local text=string.format("%s, %s, you are cleared to land, runway %s", callsign, self.alias, runway)
                    
          -- Transmit message.
          self:TransmissionTower(text, flight)
              
          -- Give AI the landing signal.
          if flight.isAI then
          
            -- Message.
            local text=string.format("Runway %s, cleared to land, %s", runway, callsign)
                      
            -- Transmit message.
            self:TransmissionPilot(text, flight, 10)
          
            -- Land AI.          
            self:_LandAI(flight, parking)
          else
          
            -- We set this flight to landing. With this he is allowed to leave the pattern.
            self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.LANDING)
                        
          end
        
          -- Set time last flight got landing clearance.  
          self.Tlanding=timer.getAbsTime()
          
        end
      else
        self:T3(self.lid..string.format("FYI: Landing clearance for flight %s denied", flight.groupname))
      end
    
    else
    
      --------------------
      -- Takeoff flight --
      --------------------
     
      -- No other flight is taking off or landing.
      if self:_CheckFlightTakeoff(flight) then
      
        -- Get callsign.
        local callsign=self:_GetCallsignName(flight)
          
        -- Runway.
        local runway=self:GetActiveRunwayText(true)
      
        -- Message.
        local text=string.format("%s, %s, taxi to runway %s, hold short", callsign, self.alias, runway)
        
        if self:GetFlightStatus(flight)==FLIGHTCONTROL.FlightStatus.READYTO then
          text=string.format("%s, %s, cleared for take-off, runway %s", callsign, self.alias, runway)
        end
          
        -- Transmit message.
        self:TransmissionTower(text, flight)
     
        -- Check if flight is AI. Humans have to request taxi via F10 menu.
        if flight.isAI then
        
          ---
          -- AI
          ---
                  
          -- Message.
          local text="Wilco, "
          
          -- Start uncontrolled aircraft.
          if flight:IsUncontrolled() then

          -- Message.
            text=text..string.format("starting engines, ")
            
            -- Start uncontrolled aircraft.          
            flight:StartUncontrolled()
          end
          
          -- Message.
          text=text..string.format("runway %s, %s", runway, callsign)
          
          -- Transmit message.
          self:TransmissionPilot(text, flight, 10)             
          
          -- Remove parking guards.
          for _,_element in pairs(flight.elements) do
            local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
            if element and element.parking then
              local spot=self:GetParkingSpotByID(element.parking.TerminalID)
              self:RemoveParkingGuard(spot)
            end
          end
          
          -- Set flight to takeoff. No way we can stop the AI now.
          self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAKEOFF)
          
        else

          ---
          -- PLAYER
          ---

          if self:GetFlightStatus(flight)==FLIGHTCONTROL.FlightStatus.READYTO then

            -- Player is ready for takeoff
            self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAKEOFF)
            
          else

            -- Remove parking guards.
            for _,_element in pairs(flight.elements) do
              local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
              if element.parking then
                local spot=self:GetParkingSpotByID(element.parking.TerminalID)
                if element.ai then
                  self:RemoveParkingGuard(spot, 15)
                else
                  self:RemoveParkingGuard(spot, 10)
                end
              end        
            end
            
          end
          
        end
        
      else
        -- Debug message.
        self:T3(self.lid..string.format("FYI: Take off for flight %s denied", flight.groupname))
      end
    end
  else
    -- Debug message.
    self:T2(self.lid..string.format("FYI: No flight in queue for takeoff or landing"))
  end
  
end

--- Check if a flight can get clearance for taxi/takeoff.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight..
-- @return #boolean If true, flight can.
function FLIGHTCONTROL:_CheckFlightTakeoff(flight)

  -- Number of groups landing.
  local nlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)
    
  -- Number of groups taking off.
  local ntakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF, nil, true)
  
  -- Current status.
  local status=self:GetFlightStatus(flight)
  
  if flight.isAI then
    ---
    -- AI
    ---
      
    if nlanding>self.NtaxiLanding then
      self:T(self.lid..string.format("AI flight %s [status=%s] NOT cleared for taxi/takeoff as %d>%d flight(s) landing", flight.groupname, status, nlanding, self.NtaxiLanding))
      return false
    end
    
    local ninbound=0
    if self.NtaxiInbound then
      ninbound=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIINB, nil, true)
    end

    if ntakeoff+ninbound>=self.NtaxiTot then
      self:T(self.lid..string.format("AI flight %s [status=%s] NOT cleared for taxi/takeoff as %d>=%d flight(s) taxi/takeoff", flight.groupname, status, ntakeoff, self.NtaxiTot))
      return false
    end
  
    self:T(self.lid..string.format("AI flight %s [status=%s] cleared for taxi/takeoff! nLanding=%d, nTakeoff=%d", flight.groupname, status, nlanding, ntakeoff))
    return true
  else
    ---
    -- Player
    -- 
    -- We allow unlimited number of players to taxi to runway.
    -- We do not allow takeoff if at least one flight is landing.
    ---
  
    if status==FLIGHTCONTROL.FlightStatus.READYTO then
    
      if nlanding>self.NtaxiLanding then
        -- Traffic landing. No permission to
        self:T(self.lid..string.format("Player flight %s [status=%s] not cleared for taxi/takeoff as %d>%d flight(s) landing", flight.groupname, status, nlanding, self.NtaxiLanding))
        return false
      end      
    
    end
  
    self:T(self.lid..string.format("Player flight %s [status=%s] cleared for taxi/takeoff", flight.groupname, status))
    return true  
  end
  

end

--- Check if a flight can get clearance for taxi/takeoff.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight..
-- @return #boolean If true, flight can.
function FLIGHTCONTROL:_CheckFlightLanding(flight)

  -- Number of groups landing.
  local nlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)

  -- Number of groups taking off.
  local ntakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF, nil, true)
  
  -- Current status.
  local status=self:GetFlightStatus(flight)
  
  if flight.isAi then
    ---
    -- AI
    ---

    if ntakeoff<=self.NlandingTakeoff and nlanding<self.NlandingTot then
      return true
    end

    return false
  else
    ---
    -- Player
    ---


    if ntakeoff<=self.NlandingTakeoff and nlanding<self.NlandingTot then
      return true
    end

    return false      
  end
  
end

--- Get next flight in line, either waiting for landing or waiting for takeoff.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Flight next in line and ready to enter the pattern. Or nil if no flight is ready.
-- @return #boolean If true, flight is holding and waiting for landing, if false, flight is parking and waiting for takeoff.
-- @return #table Parking data for holding flights or nil.
function FLIGHTCONTROL:_GetNextFlight()

  -- Get flight that is holding.
  local flightholding=self:_GetNextFightHolding()
  
  -- Get flight that is parking.
  local flightparking=self:_GetNextFightParking()
  
  -- If no flight is waiting for landing just return the takeoff flight or nil.
  if not flightholding then
    --self:T(self.lid..string.format("Next flight that is not holding"))
    return flightparking, false, nil
  end
  
  -- Get number of alive elements of the holding flight.
  local nH=flightholding:GetNelements()  
  
  -- Free parking spots.
  local parking=flightholding:GetParking(self.airbase)      
    
  -- If no flight is waiting for takeoff return the holding flight or nil.
  if not flightparking then
    if parking then
      return flightholding, true, parking
    else
      self:E(self.lid..string.format("WARNING: No flight parking but not enough parking spots for holding flight nH=%d!", nH))
      return nil, nil, nil
    end
  end
   
  -- We got flights waiting for landing and for takeoff.
  if flightholding and flightparking then
  
    local text=string.format("We got a flight holding %s [%s] and parking %s [%s]", flightholding:GetName(), flightholding:GetState(), flightparking:GetName(), flightparking:GetState())
    self:T(self.lid..text)
  
    -- Return holding flight if fuel is low.
    if flightholding.fuellow then
      if parking then
        -- Enough parking ==> land
        return flightholding, true, parking
      else
        -- Not enough parking ==> take off
        return flightparking, false, nil
      end
    end
    
    local text=string.format("Flight holding for %d sec, flight parking for %d sec", flightholding:GetHoldingTime(), flightparking:GetParkingTime())
    self:T(self.lid..text)
       
    -- Return the flight which is waiting longer. NOTE that Tholding and Tparking are abs. mission time. So a smaller value means waiting longer.
    if flightholding.Tholding and flightparking.Tparking and flightholding.Tholding<flightparking.Tparking and parking then
      return flightholding, true, parking
    else
      return flightparking, false, nil
    end
    
  end

  return nil, nil, nil
end


--- Get next flight waiting for landing clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightHolding()

  -- Return only AI or human player flights.
  local OnlyAI=nil  
  if self:IsRunwayDestroyed() then
    OnlyAI=false -- If false, we return only player flights.
  end

  -- Get all flights holding.
  local Qholding=self:GetFlights(FLIGHTCONTROL.FlightStatus.HOLDING, nil, OnlyAI)
  
  -- Min holding time in seconds.
  local TholdingMin=30

  if #Qholding==0 then
    return nil
  elseif #Qholding==1 then
    local fg=Qholding[1] --Ops.FlightGroup#FLIGHTGROUP
    local T=fg:GetHoldingTime()
    if T>TholdingMin then
      return fg
    end
  end

  -- Sort flights by low fuel.
  local function _sortByFuel(a, b)
    local flightA=a --Ops.FlightGroup#FLIGHTGROUP
    local flightB=b --Ops.FlightGroup#FLIGHTGROUP
    local fuelA=flightA.group:GetFuelMin()
    local fuelB=flightB.group:GetFuelMin()
    return fuelA<fuelB
  end

  -- Sort flights by holding time.
  local function _sortByTholding(a, b)
    local flightA=a --Ops.FlightGroup#FLIGHTGROUP
    local flightB=b --Ops.FlightGroup#FLIGHTGROUP
    return flightA.Tholding<flightB.Tholding  -- Tholding is the abs. timestamp. So the one with the smallest time is holding the longest.
  end


  -- Sort flights by fuel.
  table.sort(Qholding, _sortByFuel)
  
  -- Loop over all holding flights.
  for _,_flight in pairs(Qholding) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
    -- Return flight that is lowest on fuel.
    if flight.fuellow then  
      return flight
    end
    
  end
  

  -- Return flight waiting longest.
  table.sort(Qholding, _sortByTholding)
  
  -- First flight in line.
  local fg=Qholding[1] --Ops.FlightGroup#FLIGHTGROUP
  
  -- Check holding time.
  local T=fg:GetHoldingTime()
  if T>TholdingMin then
    return fg
  end
  
  return nil
end


--- Get next flight waiting for taxi and takeoff clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightParking()

  -- Return only AI or human player flights.
  local OnlyAI=nil  
  if self:IsRunwayDestroyed() then
    OnlyAI=false -- If false, we return only player flights.
  end

  -- Get flights ready for take off.
  local QreadyTO=self:GetFlights(FLIGHTCONTROL.FlightStatus.READYTO, OPSGROUP.GroupStatus.TAXIING, OnlyAI)

  -- First check human players.
  if #QreadyTO>0 then    
    -- First come, first serve.
    return QreadyTO[1]
  end
  
  -- Get flights ready to taxi.
  local QreadyTX=self:GetFlights(FLIGHTCONTROL.FlightStatus.READYTX, OPSGROUP.GroupStatus.PARKING, OnlyAI)

  -- First check human players.
  if #QreadyTX>0 then
    -- First come, first serve.
    return QreadyTX[1]
  end
  
  -- Check if runway is destroyed.
  if self:IsRunwayDestroyed() then
    -- Runway destroyed. As we only look for AI later on, we return nil here.
    return nil
  end
  
  -- Get AI flights parking.
  local Qparking=self:GetFlights(FLIGHTCONTROL.FlightStatus.PARKING, nil, true)
  
  -- Number of flights parking.
  local Nparking=#Qparking

  -- Check special cases where only up to one flight is waiting for takeoff.
  if Nparking==0 then
    return nil
  end

  -- Sort flights parking time.
  local function _sortByTparking(a, b)
    local flightA=a --Ops.FlightGroup#FLIGHTGROUP
    local flightB=b --Ops.FlightGroup#FLIGHTGROUP
    return flightA.Tparking<flightB.Tparking -- Tparking is the abs. timestamp. So the one with the smallest time is parking the longest.
  end

  -- Return flight waiting longest.
  table.sort(Qparking, _sortByTparking)
  
  -- Debug.
  if self.verbose>=2 then
    local text="Parking flights:"
    for i,_flight in pairs(Qparking) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      text=text..string.format("\n[%d] %s [%s], state=%s [%s]: Tparking=%.1f sec", i, flight.groupname, tostring(flight.actype), flight:GetState(), self:GetFlightStatus(flight), flight:GetParkingTime())
    end
    self:I(self.lid..text)
  end

  -- Get the first AI flight.
  for i,_flight in pairs(Qparking) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    if flight.isAI and flight.isReadyTO then
      return flight
    end
  end
  
  return nil
end

--- Print queue.
-- @param #FLIGHTCONTROL self
-- @param #table queue Queue to print.
-- @param #string name Queue name.
-- @return #string Queue text.
function FLIGHTCONTROL:_PrintQueue(queue, name)

  local text=string.format("%s Queue N=%d:", name, #queue)
  if #queue==0 then
    -- Queue is empty.
    text=text.." empty."
  else
    
    local time=timer.getAbsTime()
  
    -- Loop over all flights in queue.
    for i,_flight in ipairs(queue) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      
      -- Gather info.
      local fuel=flight.group:GetFuelMin()*100
      local ai=tostring(flight.isAI)
      local actype=tostring(flight.actype)
      
      -- Holding and parking time.
      local holding=flight.Tholding and UTILS.SecondsToClock(time-flight.Tholding, true) or "X"
      local parking=flight.Tparking and UTILS.SecondsToClock(time-flight.Tparking, true) or "X"
      
      local holding=flight:GetHoldingTime()
      if holding>=0 then
        holding=UTILS.SecondsToClock(holding, true)
      else
        holding="X"
      end
      local parking=flight:GetParkingTime()
      if parking>=0 then
        parking=UTILS.SecondsToClock(parking, true)
      else
        parking="X"
      end      
      
      -- Number of elements.
      local nunits=flight:CountElements()
      
      -- Status.
      local state=flight:GetState()
      local status=self:GetFlightStatus(flight)
      
      -- Main info.
      text=text..string.format("\n[%d] %s (%s*%d): status=%s | %s, ai=%s, fuel=%d, holding=%s, parking=%s",
                                 i, flight.groupname, actype, nunits, state, status, ai, fuel, holding, parking)

      -- Elements info.                                 
      for j,_element in pairs(flight.elements) do
        local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
        local life=element.unit:GetLife()
        local life0=element.unit:GetLife0()
        local park=element.parking and tostring(element.parking.TerminalID) or "N/A"
        text=text..string.format("\n  (%d) %s (%s): status=%s, ai=%s, airborne=%s life=%d/%d spot=%s",
        j, tostring(element.modex), element.name, tostring(element.status), tostring(element.ai), tostring(element.unit:InAir()), life, life0, park)
      end
    end
  end
  
  -- Display text.
  self:I(self.lid..text)
  
  return text
end

--- Set flight status.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param #string status New status.
function FLIGHTCONTROL:SetFlightStatus(flight, status)
  
  -- Debug message.
  self:T(self.lid..string.format("New status %s-->%s for flight %s", flight.controlstatus or "unknown", status, flight:GetName()))
  
  -- Update menu when flight status changed.
  if flight.controlstatus~=status and not flight.isAI then
    self:T(self.lid.."Updating menu in 0.2 sec after flight status change")
    flight:_UpdateMenu(0.2)
  end
  
  -- Set new status
  flight.controlstatus=status

end

--- Get flight status.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #string Flight status
function FLIGHTCONTROL:GetFlightStatus(flight)

  if flight then
    return flight.controlstatus or "unkonwn"
  end
  
  return "unknown"
end

--- Check if FC has control over this flight.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #boolean 
function FLIGHTCONTROL:IsControlling(flight)

  -- Check that we are controlling this flight.
  local is=flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename or false

  return is
end

--- Check if a group is in a queue.
-- @param #FLIGHTCONTROL self
-- @param #table queue The queue to check.
-- @param Wrapper.Group#GROUP group The group to be checked.
-- @return #boolean If true, group is in the queue. False otherwise.
function FLIGHTCONTROL:_InQueue(queue, group)
  local name=group:GetName()
  
  for _,_flight in pairs(queue) do
    local flight=_flight  --Ops.FlightGroup#FLIGHTGROUP
    if name==flight.groupname then
      return true
    end
  end
  
  return false
end

--- Get flights.
-- @param #FLIGHTCONTROL self
-- @param #string Status Return only flights in this flightcontrol status, e.g. `FLIGHTCONTROL.Status.XXX`.
-- @param #string GroupStatus Return only flights in this FSM status, e.g. `OPSGROUP.GroupStatus.TAXIING`.
-- @param #boolean AI If `true` only AI flights are returned. If `false`, only flights with clients are returned. If `nil` (default), all flights are returned.
-- @return #table Table of flights.
function FLIGHTCONTROL:GetFlights(Status, GroupStatus, AI)

  if Status~=nil or GroupStatus~=nil or AI~=nil then
  
    local flights={}
  
    for _,_flight in pairs(self.flights) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      
      local status=self:GetFlightStatus(flight, Status)
      
      if status==Status then
        if AI==nil or AI==flight.isAI then
          if GroupStatus==nil or GroupStatus==flight:GetState() then
            table.insert(flights, flight)
          end
        end
      end
    
    end
    
    return flights
  else
    return self.flights
  end

end

--- Count flights in a given status.
-- @param #FLIGHTCONTROL self
-- @param #string Status Return only flights in this status.
-- @param #string GroupStatus Count only flights in this FSM status, e.g. `OPSGROUP.GroupStatus.TAXIING`.
-- @param #boolean AI If `true` only AI flights are counted. If `false`, only flights with clients are counted. If `nil` (default), all flights are counted.
-- @return #number Number of flights.
function FLIGHTCONTROL:CountFlights(Status, GroupStatus, AI)
  
  if Status~=nil or GroupStatus~=nil or AI~=nil then
  
    local flights=self:GetFlights(Status, GroupStatus, AI)
    
    return #flights
  
  else
    return #self.flights
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Runway Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the active runway based on current wind direction.
-- @param #FLIGHTCONTROL self
-- @return Wrapper.Airbase#AIRBASE.Runway Active runway.
function FLIGHTCONTROL:GetActiveRunway()
  local rwy=self.airbase:GetActiveRunway()
  return rwy
end

--- Get the active runway for landing.
-- @param #FLIGHTCONTROL self
-- @return Wrapper.Airbase#AIRBASE.Runway Active runway.
function FLIGHTCONTROL:GetActiveRunwayLanding()
  local rwy=self.airbase:GetActiveRunwayLanding()
  return rwy
end

--- Get the active runway for takeoff.
-- @param #FLIGHTCONTROL self
-- @return Wrapper.Airbase#AIRBASE.Runway Active runway.
function FLIGHTCONTROL:GetActiveRunwayTakeoff()
  local rwy=self.airbase:GetActiveRunwayTakeoff()
  return rwy
end


--- Get the name of the active runway.
-- @param #FLIGHTCONTROL self
-- @param #boolean Takeoff If true, return takeoff runway name. Default is landing.
-- @return #string Runway text, e.g. "31L" or "09".
function FLIGHTCONTROL:GetActiveRunwayText(Takeoff)

  local runway
  if Takeoff then
    runway=self:GetActiveRunwayTakeoff()
  else
    runway=self:GetActiveRunwayLanding()
  end

  local name=self.airbase:GetRunwayName(runway, true)
  
  return name or "XX"
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parking Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Init parking spots.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_InitParkingSpots()

  -- Parking spots of airbase.
  local parkingdata=self.airbase:GetParkingSpotsTable()
  
  -- Init parking spots table.
  self.parking={}
  
  self.Nparkingspots=0
  for _,_spot in pairs(parkingdata) do
    local spot=_spot --Wrapper.Airbase#AIRBASE.ParkingSpot
       
    -- Mark position.
    local text=string.format("Parking ID=%d, Terminal=%d: Free=%s, Client=%s, Dist=%.1f", spot.TerminalID, spot.TerminalType, tostring(spot.Free), tostring(spot.ClientName), spot.DistToRwy)
    self:T3(self.lid..text)

    -- Add to table.
    self.parking[spot.TerminalID]=spot
    
    -- Marker.
    --spot.Marker=MARKER:New(spot.Coordinate, "Spot"):ReadOnly():ToCoalition(self:GetCoalition())
    
    -- Check if spot is initially free or occupied.
    if spot.Free then
    
      -- Parking spot is free.
      self:SetParkingFree(spot)
      
    else
    
      -- Scan for the unit sitting here.
      local unit=spot.Coordinate:FindClosestUnit(20)
      
      
      if unit then

        local unitname=unit and unit:GetName() or "unknown"
      
        local isalive=unit:IsAlive()
      
        self:T2(self.lid..string.format("FF parking spot %d is occupied by unit %s alive=%s", spot.TerminalID, unitname, tostring(isalive)))
      
        if isalive then
      
          -- Set parking occupied.
          self:SetParkingOccupied(spot, unitname)
          
          -- Spawn parking guard.
          self:SpawnParkingGuard(unit)
        
        else
        
          -- TODO
          --env.info(string.format("FF parking spot %d is occupied by NOT ALIVE unit %s", spot.TerminalID, unitname))
          
          -- Parking spot is free.
          self:SetParkingFree(spot)
          
        end
        
      else
        self:E(self.lid..string.format("ERROR: Parking spot is NOT FREE but no unit could be found there!"))
      end
    end

    -- Increase counter
    self.Nparkingspots=self.Nparkingspots+1
  end
  
end

--- Get parking spot by its Terminal ID.
-- @param #FLIGHTCONTROL self
-- @param #number TerminalID
-- @return #FLIGHTCONTROL.ParkingSpot Parking spot data table.
function FLIGHTCONTROL:GetParkingSpotByID(TerminalID)
  return self.parking[TerminalID]
end

--- Set parking spot to FREE and update F10 marker.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
-- @param #string status New status.
-- @param #string unitname Name of the unit.
function FLIGHTCONTROL:_UpdateSpotStatus(spot, status, unitname)

  -- Debug message.
  self:T2(self.lid..string.format("Updating parking spot %d status: %s --> %s (unit=%s)", spot.TerminalID, tostring(spot.Status), status, tostring(unitname)))
  
  -- Set new status.
  spot.Status=status

end

--- Set parking spot to FREE and update F10 marker.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
function FLIGHTCONTROL:SetParkingFree(spot)

  -- Get spot.
  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
  -- Update spot status.
  self:_UpdateSpotStatus(spot, AIRBASE.SpotStatus.FREE, spot.OccupiedBy or spot.ReservedBy)
  
  -- Not occupied or reserved.
  spot.OccupiedBy=nil
  spot.ReservedBy=nil
  
  -- Remove parking guard.
  self:RemoveParkingGuard(spot)
  
  -- Update marker.
  self:UpdateParkingMarker(spot)

end

--- Set parking spot to RESERVED and update F10 marker.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
-- @param #string unitname Name of the unit occupying the spot. Default "unknown". 
function FLIGHTCONTROL:SetParkingReserved(spot, unitname)

  -- Get spot.
  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
  -- Update spot status.
  self:_UpdateSpotStatus(spot, AIRBASE.SpotStatus.RESERVED, unitname)
  
  -- Reserved.
  spot.ReservedBy=unitname or "unknown"
  
  -- Update marker.
  self:UpdateParkingMarker(spot)

end

--- Set parking spot to OCCUPIED and update F10 marker.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
-- @param #string unitname Name of the unit occupying the spot. Default "unknown".
function FLIGHTCONTROL:SetParkingOccupied(spot, unitname)

  -- Get spot.
  local spot=self:GetParkingSpotByID(spot.TerminalID)

  -- Update spot status.
  self:_UpdateSpotStatus(spot, AIRBASE.SpotStatus.OCCUPIED, unitname)
  
  -- Occupied.
  spot.OccupiedBy=unitname or "unknown"
  
  -- Update marker.
  self:UpdateParkingMarker(spot)

end

--- Update parking markers.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
function FLIGHTCONTROL:UpdateParkingMarker(spot)

  if self.markerParking then

    -- Get spot.
    local spot=self:GetParkingSpotByID(spot.TerminalID)
    
    -- Only mark OCCUPIED and RESERVED spots.
    if spot.Status==AIRBASE.SpotStatus.FREE then
    
      if spot.Marker then
        spot.Marker:Remove()
      end
    
    else
    
      local text=string.format("Spot %d (type %d): %s", spot.TerminalID, spot.TerminalType, spot.Status:upper())
      if spot.OccupiedBy then
        text=text..string.format("\nOccupied by %s", tostring(spot.OccupiedBy))
      end
      if spot.ReservedBy then
        text=text..string.format("\nReserved for %s", tostring(spot.ReservedBy))
      end  
      if spot.ClientSpot then
        text=text..string.format("\nClient %s", tostring(spot.ClientName))
      end
      
      if spot.Marker then
      
        if text~=spot.Marker.text or not spot.Marker.shown then
          spot.Marker:UpdateText(text)
        end
        
      else
      
        spot.Marker=MARKER:New(spot.Coordinate, text):ToAll()
      
      end
      
    end
  end
  
end

--- Check if parking spot is free.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot Parking spot data.
-- @return #boolean If true, parking spot is free.
function FLIGHTCONTROL:IsParkingFree(spot)
  return spot.Status==AIRBASE.SpotStatus.FREE
end

--- Check if a parking spot is reserved by a flight group.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot Parking spot to check.
-- @return #string Name of element or nil.
function FLIGHTCONTROL:IsParkingOccupied(spot)

  if spot.Status==AIRBASE.SpotStatus.OCCUPIED then
    return tostring(spot.OccupiedBy)
  else
    return false
  end
end

--- Check if a parking spot is reserved by a flight group.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot Parking spot to check.
-- @return #string Name of element or *nil*.
function FLIGHTCONTROL:IsParkingReserved(spot)

  if spot.Status==AIRBASE.SpotStatus.RESERVED then
    return tostring(spot.ReservedBy)
  else
    return false
  end
end

--- Get free parking spots.
-- @param #FLIGHTCONTROL self
-- @param #number terminal Terminal type or nil.
-- @return #number Number of free spots. Total if terminal=nil or of the requested terminal type.
-- @return #table Table of free parking spots of data type #FLIGHCONTROL.ParkingSpot.
function FLIGHTCONTROL:_GetFreeParkingSpots(terminal)
  
  local freespots={}
  
  local n=0
  for _,_parking in pairs(self.parking) do
    local parking=_parking --Wrapper.Airbase#AIRBASE.ParkingSpot
    
    if self:IsParkingFree(parking) then
      if terminal==nil or terminal==parking.terminal then
        n=n+1
        table.insert(freespots, parking)
      end
    end
  end
  
  return n,freespots
end

--- Get closest parking spot.
-- @param #FLIGHTCONTROL self
-- @param Core.Point#COORDINATE Coordinate Reference coordinate.
-- @param #number TerminalType (Optional) Check only this terminal type.
-- @param #boolean Status (Optional) Only consider spots that have this status.
-- @return #FLIGHTCONTROL.ParkingSpot Closest parking spot.
function FLIGHTCONTROL:GetClosestParkingSpot(Coordinate, TerminalType, Status)

  local distmin=math.huge
  local spotmin=nil
  
  for TerminalID, Spot in pairs(self.parking) do
    local spot=Spot --Wrapper.Airbase#AIRBASE.ParkingSpot
    
    --env.info(self.lid..string.format("FF Spot %d: %s", spot.TerminalID, spot.Status))
    
    if (Status==nil or Status==spot.Status) and AIRBASE._CheckTerminalType(spot.TerminalType, TerminalType) then
      
      -- Get distance from coordinate to spot.
      local dist=Coordinate:Get2DDistance(spot.Coordinate)
      
      -- Check if distance is smaller.
      if dist<distmin then
        distmin=dist
        spotmin=spot
      end
      
    end
  end
  
  return spotmin
end


--- Get parking spot this player was initially spawned on.
-- @param #FLIGHTCONTROL self
-- @param #string UnitName Name of the player unit.
-- @return #FLIGHTCONTROL.ParkingSpot Player spot or nil.
function FLIGHTCONTROL:_GetPlayerSpot(UnitName)

  for TerminalID, Spot in pairs(self.parking) do
    local spot=Spot --Wrapper.Airbase#AIRBASE.ParkingSpot
    
    if spot.ClientName and spot.ClientName==UnitName and (spot.Status==AIRBASE.SpotStatus.FREE or spot.ReservedBy==UnitName) then
      return spot
    end
    
  end
  
  return nil
end

--- Count number of parking spots.
-- @param #FLIGHTCONTROL self
-- @param #string SpotStatus (Optional) Status of spot.
-- @return #number Number of parking spots.
function FLIGHTCONTROL:CountParking(SpotStatus)

  local n=0
  for _,_spot in pairs(self.parking) do
    local spot=_spot --Wrapper.Airbase#AIRBASE.ParkingSpot
    if SpotStatus==nil or SpotStatus==spot.Status then
      n=n+1
    end
  
  end

  return n
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ATIS Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ATC Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param Core.Menu#MENU_GROUP mainmenu ATC root menu table.
function FLIGHTCONTROL:_CreatePlayerMenu(flight, mainmenu)
  
  -- Group info.
  local group=flight.group
  local groupname=flight.groupname
  local gid=group:GetID()
  
  -- Flight status.
  local flightstatus=self:GetFlightStatus(flight)
  
  -- Are we controlling this flight.
  local gotcontrol=self:IsControlling(flight)
  
  -- Get player element.
  local player=flight:GetPlayerElement()
  
  -- Debug info.
  local text=string.format("Creating ATC player menu for flight %s: in state=%s status=%s, gotcontrol=%s, player=%s", 
  tostring(flight.groupname), flight:GetState(), flightstatus, tostring(gotcontrol), player.status)
  self:T(self.lid..text)


  -- Airbase root menu.  
  local rootmenu=MENU_GROUP:New(group, self.airbasename, mainmenu)
  
  ---
  -- Help Menu
  ---
  local helpmenu=MENU_GROUP:New(group, "Help",  rootmenu)
  MENU_GROUP_COMMAND:New(group, "Radio Check",     helpmenu, self._PlayerRadioCheck,     self, groupname)
  MENU_GROUP_COMMAND:New(group, "Confirm Status",  helpmenu, self._PlayerConfirmStatus,  self, groupname)
  if gotcontrol and flight:IsInbound() and flight.stack then
  MENU_GROUP_COMMAND:New(group, "Vector Holding",  helpmenu, self._PlayerVectorInbound,  self, groupname)
  end  

  ---
  -- Info Menu
  ---
  local infomenu=MENU_GROUP:New(group, "Info",  rootmenu)
  MENU_GROUP_COMMAND:New(group, "Airbase", infomenu, self._PlayerInfoAirbase, self, groupname)
  MENU_GROUP_COMMAND:New(group, "Traffic", infomenu, self._PlayerInfoTraffic, self, groupname)
  MENU_GROUP_COMMAND:New(group, "ATIS",    infomenu, self._PlayerInfoATIS,    self, groupname)

  ---
  -- Root Menu
  ---
  if gotcontrol then
  
    local status=self:GetFlightStatus(flight)

    ---
    -- FC is controlling this flight
    ---
  
    if flight:IsParking(player) or player.status==OPSGROUP.ElementStatus.ENGINEON then
      ---
      -- Parking
      ---
      
      if status==FLIGHTCONTROL.FlightStatus.READYTX then
        MENU_GROUP_COMMAND:New(group, "Cancel Taxi",    rootmenu, self._PlayerAbortTaxi,   self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Request Taxi",  rootmenu, self._PlayerRequestTaxi, self, groupname)
      end
      
    elseif flight:IsTaxiing(player) then
      ---
      -- Taxiing
      ---

      if status==FLIGHTCONTROL.FlightStatus.READYTX or status==FLIGHTCONTROL.FlightStatus.TAXIOUT then
        -- Flight is "ready to taxi" (awaiting clearance) or "taxiing to runway".
        MENU_GROUP_COMMAND:New(group, "Request Takeoff", rootmenu, self._PlayerRequestTakeoff, self, groupname)
        MENU_GROUP_COMMAND:New(group, "Abort Taxi",      rootmenu, self._PlayerAbortTaxi,      self, groupname)              
      elseif status==FLIGHTCONTROL.FlightStatus.READYTO then
        -- Flight is ready for take off.
        MENU_GROUP_COMMAND:New(group, "Abort Takeoff",   rootmenu, self._PlayerAbortTakeoff,   self, groupname)
      elseif status==FLIGHTCONTROL.FlightStatus.TAKEOFF then
        -- Flight is taking off.
        MENU_GROUP_COMMAND:New(group, "Abort Takeoff",   rootmenu, self._PlayerAbortTakeoff,   self, groupname)
      elseif status==FLIGHTCONTROL.FlightStatus.TAXIINB then
        -- Could be after "abort taxi" call and we changed our mind (again)
        MENU_GROUP_COMMAND:New(group, "Request Taxi",       rootmenu, self._PlayerRequestTaxi,    self, groupname)
        if player.parking then
          MENU_GROUP_COMMAND:New(group, "Cancel Parking",    rootmenu, self._PlayerCancelParking, self, groupname)          
        else
          MENU_GROUP_COMMAND:New(group, "Reserve Parking",    rootmenu, self._PlayerRequestParking, self, groupname)
        end
        MENU_GROUP_COMMAND:New(group, "Arrived at Parking", rootmenu, self._PlayerArrived,        self, groupname)          
      end
      
    elseif flight:IsInbound() then
      ---
      -- Inbound
      ---

      if status==FLIGHTCONTROL.FlightStatus.LANDING then
        -- After direct approach.
        MENU_GROUP_COMMAND:New(group, "Confirm Landing!", rootmenu, self._PlayerConfirmLanding, self, groupname)
        MENU_GROUP_COMMAND:New(group, "Abort Landing",   rootmenu, self._PlayerAbortLanding,   self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Holding!",        rootmenu, self._PlayerHolding,        self, groupname)
        MENU_GROUP_COMMAND:New(group, "Direct Approach", rootmenu, self._PlayerRequestDirectLanding, self, groupname)      
        MENU_GROUP_COMMAND:New(group, "Abort Inbound",   rootmenu, self._PlayerAbortInbound,   self, groupname)
      end
      if player.parking then
        MENU_GROUP_COMMAND:New(group, "Cancel Parking",    rootmenu, self._PlayerCancelParking, self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Reserve Parking", rootmenu, self._PlayerRequestParking, self, groupname)
      end

      
    elseif flight:IsHolding() then
      ---
      -- Holding
      ---

      MENU_GROUP_COMMAND:New(group, "Confirm Landing!", rootmenu, self._PlayerConfirmLanding, self, groupname)
      MENU_GROUP_COMMAND:New(group, "Abort Holding",    rootmenu, self._PlayerAbortHolding,   self, groupname)
      if player.parking then
        MENU_GROUP_COMMAND:New(group, "Cancel Parking",    rootmenu, self._PlayerCancelParking, self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Reserve Parking",  rootmenu, self._PlayerRequestParking, self, groupname)
      end

    elseif flight:IsLanding(player) then
      ---
      -- Landing
      ---

      MENU_GROUP_COMMAND:New(group, "Abort Landing",   rootmenu, self._PlayerAbortLanding,   self, groupname)
      if player.parking then
        MENU_GROUP_COMMAND:New(group, "Cancel Parking",    rootmenu, self._PlayerCancelParking, self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Reserve Parking", rootmenu, self._PlayerRequestParking, self, groupname)
      end
      
    elseif flight:IsLanded(player) then
      ---
      -- Landed
      ---      
      
      MENU_GROUP_COMMAND:New(group, "Arrived at Parking", rootmenu, self._PlayerArrived,        self, groupname)
      if player.parking then
        MENU_GROUP_COMMAND:New(group, "Cancel Parking",    rootmenu, self._PlayerCancelParking, self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Reserve Parking",    rootmenu, self._PlayerRequestParking, self, groupname)
      end
      
    elseif flight:IsArrived(player) then
      ---
      -- Arrived (at Parking)
      ---      
      
      if status==FLIGHTCONTROL.FlightStatus.READYTX then
        MENU_GROUP_COMMAND:New(group, "Abort Taxi",    rootmenu, self._PlayerAbortTaxi,   self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Request Taxi",  rootmenu, self._PlayerRequestTaxi, self, groupname)
      end
      
    elseif flight:IsAirborne(player) then
      ---
      -- Airborne
      ---
      
      -- Nothing to do.      
      
    end
    
  else
  
    ---
    -- FC is NOT controlling this flight
    ---
  
    if flight:IsAirborne() then
      MENU_GROUP_COMMAND:New(group, "Inbound", rootmenu, self._PlayerRequestInbound, self, groupname)
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Help
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player menu not implemented.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerNotImplemented(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    local text=string.format("Sorry, this feature is not implemented yet!")
    self:TextMessageToFlight(text, flight)
  
  end
  
end

--- Player radio check.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRadioCheck(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    -- Call sign.
    local callsign=self:_GetCallsignName(flight)
    
    -- Pilot radio check.
    local text = ""
    
    if type(self.frequency) == "table" then
      local multifreq = ""
      for _,_entry in pairs(self.frequency) do
        multifreq = string.format("%s%.2f, ",multifreq,_entry)
      end
      multifreq = string.gsub(multifreq,", $","")
      text=string.format("%s, %s, radio check %s", self.alias, callsign, multifreq)
    else
      text=string.format("%s, %s, radio check %.3f", self.alias, callsign, self.frequency)
    end
    -- Radio message.
    self:TransmissionPilot(text, flight)
        
    -- Message text.
    local text=string.format("%s, %s, reading you 5",  callsign, self.alias)
        
    -- Send message.
    self:TransmissionTower(text, flight, 10)
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player confirm status.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerConfirmStatus(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    -- Call sign.
    local callsign=self:_GetCallsignName(flight)
    
    -- Pilot requests status.
    local text=string.format("%s, %s, confirm my status", self.alias, callsign)
    
    -- Radio message.
    self:TransmissionPilot(text, flight)
    
    -- Flight status.
    local s1=flight:GetState()
            
    -- Message text.
    local text=string.format("%s, %s, your current flight status is %s.",  callsign, self.alias, s1)
    
    if flight.flightcontrol then
      -- FC status.
      local s2=flight.flightcontrol:GetFlightStatus(flight)
      
      if flight.flightcontrol.airbasename==self.airbasename then
        text=text..string.format(" You are controlled by us with status %s", s2)
      else
        text=text..string.format(" You are controlled by %s with status %s", flight.flightcontrol.airbasename, s2)
      end
    else
      text=text..string.format(" You are not controlled by anyone.")
    end
        
    -- Send message.
    self:TransmissionTower(text, flight, 10)
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Info
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player info about airbase.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerInfoAirbase(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
 
    local text=string.format("Airbase %s Info:", self.airbasename) 
    text=text..string.format("\nATC Status: %s", self:GetState())
    
    if type(self.frequency) == "table" then
      local multifreq = ""
      for i=1,#self.frequency do
        multifreq=string.format("%s%.2f %s, ",multifreq,self.frequency[i],UTILS.GetModulationName(self.modulation[i] or 0))
      end
      text=string.gsub(text,", $","")
      text=text..string.format("\nFrequencies: %s", multifreq)
    else
      text=text..string.format("\nFrequency: %.3f %s", self.frequency, UTILS.GetModulationName(self.modulation)) 
    end
    text=text..string.format("\nRunway Landing: %s", self:GetActiveRunwayText())
    text=text..string.format("\nRunway Takeoff: %s", self:GetActiveRunwayText(true))

    -- Message to flight
    self:TextMessageToFlight(text, flight, 10, true)
  
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player info about ATIS.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerInfoATIS(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    local text=string.format("Airbase %s ATIS:", self.airbasename)
    local srstxt = string.format("Airbase %s ", self.airbasename)
    if self.atis then
      text=text..string.format("\nATIS %.3f MHz %s", self.atis.frequency, UTILS.GetModulationName(self.atis.modulation))
      srstxt=srstxt..string.format("ATIS %.3f Megahertz %s", self.atis.frequency, UTILS.GetModulationName(self.atis.modulation))
      if self.atis.towerfrequency then
        local tower=""
        for _,freq in pairs(self.atis.towerfrequency) do
          tower=tower..string.format("%.3f, ", freq)
        end
        text=text..string.format("\nTower %.3f MHz", self.atis.towerfrequency[1])
      end
      if self.atis.ils then
      end
      if self.atis.tacan then
        --TACAN
      end
      if self.atis.ndbinner then
      end
      if self.atis.ndbouter then
      
      end
      
    else
      text=text.." Not defined"      
    end

    -- Message to flight
    
    --self:TextMessageToFlight(text, flight, 10, true)
    -- Call sign.
    local callsign=self:_GetCallsignName(flight)
           
    -- Pilot calls inbound for landing.
    local rtext=string.format("%s, %s, request ATIS frequency.", self.alias, callsign)
    
    -- Radio message.
    self:TransmissionPilot(rtext, flight)
    if self.atis then
      self:TransmissionTower(srstxt,flight,10)
    else
      self:TransmissionTower(text,flight,10)
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player info about traffic.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerInfoTraffic(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    local Nflights= self:CountFlights()
    local NQparking=self:CountFlights(FLIGHTCONTROL.FlightStatus.PARKING)
    local NQreadytx=self:CountFlights(FLIGHTCONTROL.FlightStatus.READYTX)
    local NQtaxiout=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIOUT)
    local NQreadyto=self:CountFlights(FLIGHTCONTROL.FlightStatus.READYTO)
    local NQtakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
    local NQinbound=self:CountFlights(FLIGHTCONTROL.FlightStatus.INBOUND)
    local NQholding=self:CountFlights(FLIGHTCONTROL.FlightStatus.HOLDING)
    local NQlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)
    local NQtaxiinb=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIINB)
    local NQarrived=self:CountFlights(FLIGHTCONTROL.FlightStatus.ARRIVED)
  
    --
    local text=string.format("Traffic %s airbase:", self.airbasename)
    text = text..string.format("\n- Total Flights %d", Nflights)
    if NQparking>0 then
      text=text..string.format("\n- Parking %d", NQparking)
    end
    if NQreadytx>0 then
      text=text..string.format("\n- Ready to taxi %d", NQreadytx)
    end
    if NQtaxiout>0 then
      text=text..string.format("\n- Taxi to runway %d", NQtaxiout)
    end
    if NQreadyto>0 then
      text=text..string.format("\n- Ready for takeoff %d", NQreadyto)
    end
    if NQtakeoff>0 then
      text=text..string.format("\n- Taking off %d", NQtakeoff)
    end
    if NQinbound>0 then
      text=text..string.format("\n- Inbound %d", NQinbound)
    end
    if NQholding>0 then
      text=text..string.format("\n- Holding pattern %d", NQholding)
    end
    if NQlanding>0 then
      text=text..string.format("\n- Landing %d", NQlanding)
    end
    if NQtaxiinb>0 then
      text=text..string.format("\n- Taxi to parking %d", NQtaxiinb)
    end
    if NQarrived>0 then
      text=text..string.format("\n- Arrived at parking %d", NQarrived)
    end
    
    -- Message to flight
    self:TextMessageToFlight(text, flight, 15, true)
  
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Inbound
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player calls inbound.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestInbound(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if flight:IsAirborne() then
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
            
      -- Get player element.
      local player=flight:GetPlayerElement()      
      
      -- Pilot calls inbound for landing.
      local text=string.format("%s, %s, inbound for landing", self.alias, callsign)
      
      -- Radio message.
      self:TransmissionPilot(text, flight)
      
      -- Current player coord.
      local flightcoord=flight:GetCoordinate(nil, player.name)
      
      -- Distance from player to airbase.
      local dist=flightcoord:Get2DDistance(self:GetCoordinate())
      
      if dist<UTILS.NMToMeters(50) then
      
        -- Call RTB event. This only sets the FC for AI.
        flight:RTB(self.airbase)
                
        -- Get holding point.
        local stack=self:_GetHoldingStack(flight)        
        
        if stack then
        
          -- Set flight.
          stack.flightgroup=flight
          
          -- Stack.
          flight.stack=stack
          
          -- Heading to holding point.
          local heading=flightcoord:HeadingTo(stack.pos0)
          
          -- Distance to holding point.
          local distance=flightcoord:Get2DDistance(stack.pos0)
          
          local dist=UTILS.MetersToNM(distance)
      
          -- Message text.
          local text=string.format("%s, %s, roger, fly heading %03d for %d nautical miles, hold at angels %d. Report entering the pattern.", 
          callsign, self.alias, heading, dist, stack.angels)
          
          -- Send message.
          self:TransmissionTower(text, flight, 10)

          -- Set flightcontrol for this flight. This also updates the menu.
          flight:SetFlightControl(self)

          -- Add flight to inbound queue.
          self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.INBOUND)
            
        else
        
          -- Message text.
          local text=string.format("Negative, could not get a holding stack for you! Try again later...")
          
          -- Send message.
          self:TextMessageToFlight(text, flight, 10)        
        
          -- Debug message.
          self:E(self.lid..string.format("WARNING: Could not get holding stack for flight %s", flight:GetName()))
        end
        
      else

          -- Message text.
          local text=string.format("Negative, you have to be withing 50 nautical miles of the airbase to request inbound!")
          
          -- Send message.
          self:TextMessageToFlight(text, flight, 10)
      
      end
      
    else  
      -- Error you are not airborne!
      local text=string.format("Negative, you must be AIRBORNE to call INBOUND!")
      
      -- Send message.
      self:TextMessageToFlight(text, flight, 10)
    end
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end


--- Player vector to inbound
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerVectorInbound(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    -- Check if inbound, controlled and have a stack.
    if flight:IsInbound() and self:IsControlling(flight) and flight.stack then
    
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
            
      -- Get player element.
      local player=flight:GetPlayerElement()
      
      -- Current player coord.
      local flightcoord=flight:GetCoordinate(nil, player.name)
      
      -- Distance from player to airbase.
      local dist=flightcoord:Get2DDistance(self:GetCoordinate())
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)

      -- Heading to holding point.
      local heading=flightcoord:HeadingTo(flight.stack.pos0)
      
      -- Distance to holding point in meters.
      local distance=flightcoord:Get2DDistance(flight.stack.pos0)
      
      -- Distance in NM.
      local dist=UTILS.MetersToNM(distance)
  
      -- Message text.
      local text=string.format("%s, fly heading %03d for %d nautical miles, hold at angels %d.", callsign, heading, dist, flight.stack.angels)
      
      -- Send message.
      self:TextMessageToFlight(text, flight)
      
    else
      -- Send message.
      local text="Negative, you must be INBOUND, CONTROLLED by us and have an assigned STACK!"
      self:TextMessageToFlight(text, flight)      
    end
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player aborts inbound.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortInbound(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if flight:IsInbound() and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Pilot calls inbound for landing.
      local text=string.format("%s, %s, abort inbound", self.alias, callsign)
      
      -- Radio message.
      self:TransmissionPilot(text, flight)
        
      -- Message text.
      local text=string.format("%s, %s, roger, have a nice day!",  callsign, self.alias)
          
      -- Send message.
      self:TransmissionTower(text, flight, 5)
              
      -- Set flight.
      if flight.stack then
        flight.stack.flightgroup=nil
        flight.stack=nil
      else
        self:E(self.lid.."ERROR: No stack!")
      end
            
      -- Remove flight. This also updates the menu.
      self:_RemoveFlight(flight)      
      
      -- Set flight to cruise.
      flight:Cruise()      

      -- Current base is nil.
      flight.currbase=nil
            
      -- Create player menu.
      --flight:_UpdateMenu()
            
    else
    
      -- Error you are not airborne!
      local text=string.format("Negative, you must be INBOUND and CONTROLLED by us!")
      
      -- Send message.
      self:TextMessageToFlight(text, flight, 10)
    end
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Holding
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player calls holding.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerHolding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if flight:IsInbound() then

      if self:IsControlling(flight) then
      
        -- Callsign.
        local callsign=self:_GetCallsignName(flight)
      
        -- Player element.
        local player=flight:GetPlayerElement()      
      
        -- Holding stack.
        local stack=flight.stack
        
        if stack then
        
          -- Pilot arrived at holding pattern.
          local text=string.format("%s, %s, arrived at holding pattern", self.alias, callsign)
          
          -- Radio message.
          self:TransmissionPilot(text, flight)        
        
          -- Current coordinate.
          local Coordinate=flight:GetCoordinate(nil, player.name)
        
          -- Distance.
          local dist=stack.pos0:Get2DDistance(Coordinate)
          
          local dmax=UTILS.NMToMeters(500)
          
          if dist<dmax then
        
            -- Message to flight
            local text=string.format("%s, roger, fly heading %d at angels %d and wait for landing clearance", callsign, stack.heading, stack.angels)
            
            -- Radio message from tower.
            self:TransmissionTower(text, flight, 10)
    
            -- Call holding event.        
            flight:Holding()
            
          else

            -- Message to flight
            local text=string.format("Negative, you have to be within %d NM of the arrival zone! You still %d NM away.", UTILS.MetersToNM(dmax), UTILS.MetersToNM(dist))
            self:TextMessageToFlight(text, flight, 10, true)
          
          end
          
        else
          -- Message to flight
          local text=string.format("Negative, we have no holding stack for you!")         
          self:TextMessageToFlight(text, flight, 10, true)
        end
                
      else
      
        -- Error: Not controlled by this FC.
        local text=string.format("Negative, you are not controlled by us!")
        
        -- Message to flight
        self:TextMessageToFlight(text, flight, 10, true)        
      
      end
    else
      -- Error you are not airborne!
      local text=string.format("Negative, you must be INBOUND to call HOLDING!")
      
          -- Message to flight
      self:TextMessageToFlight(text, flight, 10, true)
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player aborts holding.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortHolding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if flight:IsHolding() and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Pilot aborts holding
      local text=string.format("%s, %s, abort holding", self.alias, callsign)
      
      -- Radio message.
      self:TransmissionPilot(text, flight)
        
      -- Message text.
      local text=string.format("%s, %s, roger, have a nice day!",  callsign, self.alias)
          
      -- Send message.
      self:TransmissionTower(text, flight, 10)

      -- Not holding any more.
      flight.Tholding=nil
      
      -- Set flight to cruise. This also updates the menu.
      flight:Cruise()
      
      flight.currbase=nil

      -- Set flight.
      if flight.stack then
        flight.stack.flightgroup=nil
        flight.stack=nil
      else
        self:E(self.lid.."ERROR: No stack!")
      end

      -- Remove flight. This also updates the menu.
      self:_RemoveFlight(flight)
            
    else
    
      -- Error you are not airborne!
      local text=string.format("Negative, you must be HOLDING and CONTROLLED by us!")
      
      -- Send message.
      self:TextMessageToFlight(text, flight, 10)
    end
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Landing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player confirms landing.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerConfirmLanding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if (flight:IsHolding() or flight:IsInbound()) and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
      
      
      if self:GetFlightStatus(flight)==FLIGHTCONTROL.FlightStatus.LANDING then
      
        -- Runway.
        local runway=self:GetActiveRunwayText()
      
        -- Message.
        local text=string.format("Runway %s, cleared to land, %s", runway, callsign)
                  
        -- Transmit message.
        self:TransmissionPilot(text, flight)                
        
        -- Set flight to landing. This clears the stack and Tholding.
        flight:Landing()
        
        -- Message text.
        --local text=string.format("%s, continue approach.",  callsign)
            
        -- Send message.
        --self:TransmissionTower(text, flight, 10)
        
        -- Create player menu.
        flight:_UpdateMenu(0.5)
        
      else

        -- Pilot leaves pattern for landing
        local text=string.format("%s, %s, leaving pattern for landing.", self.alias, callsign)
        
        -- Radio message.
        self:TransmissionPilot(text, flight)

        -- Message text.
        local text=string.format("%s, negative! Hold position until you get clearance.",  callsign)
            
        -- Send message.
        self:TransmissionTower(text, flight, 10)            
      end
            
    else
    
      -- Error you are not airborne!
      local text=string.format("Negative, you must be HOLDING or INBOUND and CONTROLLED by us!")
      
      -- Send message.
      self:TextMessageToFlight(text, flight, 10)
    end
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player aborts landing.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortLanding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    local flightstatus=self:GetFlightStatus(flight)
      
    if (flight:IsLanding() or flightstatus==FLIGHTCONTROL.FlightStatus.LANDING) and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Pilot aborts landing.
      local text=string.format("%s, %s, abort landing", self.alias, callsign)
      
      -- Radio message.
      self:TransmissionPilot(text, flight)
                
      -- Message text.
      local text=string.format("%s, %s, roger, have a nice day!",  callsign, self.alias)
          
      -- Send message.
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight.
      if flight.stack then
        flight.stack.flightgroup=nil
        flight.stack=nil
      end
      
      -- Not holding any more.
      flight.Tholding=nil
      
      -- Set flight to cruise.
      flight:Cruise()
      
      flight.currbase=nil
      
      -- Remove flight. This also updates the menu.
      self:_RemoveFlight(flight)
                  
    else
    
      -- Error you are not airborne!
      local text=string.format("Negative, you must be LANDING and CONTROLLED by us!")
      
      -- Send message.
      self:TextMessageToFlight(text, flight, 10)
    end
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player request direct approach.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestDirectLanding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if flight:IsInbound() and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Number of flights taking off.
      local nTakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
      

      -- Message.
      local text=string.format("%s, request direct approach.", callsign)
                
      -- Transmit message.
      self:TransmissionPilot(text, flight)      
      
      if nTakeoff>self.NlandingTakeoff then

        -- Message text.
        local text=string.format("%s, negative! We have currently traffic taking off!",  callsign)
            
        -- Send message.
        self:TransmissionTower(text, flight, 10)
      
      else
      
        -- Runway.
        local runway=self:GetActiveRunwayText()      

        -- Message text.
        local text=string.format("%s, affirmative, runway %s. Confirm approach!",  callsign, runway)
            
        -- Send message.
        self:TransmissionTower(text, flight, 10)
        
        -- Set flight status to landing.
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.LANDING)
      
      end
            
    else
    
      -- Error you are not airborne!
      local text=string.format("Negative, you must be INBOUND and CONTROLLED by us!")
      
      -- Send message.
      self:TextMessageToFlight(text, flight, 10)
    end
      
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Taxi
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player requests taxi.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestTaxi(groupname)
  
  -- Get flight.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    -- Get callsign.
    local callsign=self:_GetCallsignName(flight)
    
    -- Pilot request for taxi.
    local text=string.format("%s, %s, request taxi to runway.", self.alias, callsign)        
    self:TransmissionPilot(text, flight)
        
    if flight:IsParking() then
        
      -- Tell pilot to wait until cleared.
      local text=string.format("%s, %s, hold position until further notice.", callsign, self.alias)
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight status to "Ready to Taxi".
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTX)
      
    elseif flight:IsTaxiing() then
    
      -- Runway for takeoff.
      local runway=self:GetActiveRunwayText(true)

      -- Tell pilot to wait until cleared.
      local text=string.format("%s, %s, taxi to runway %s, hold short.", callsign, self.alias, runway)
      self:TransmissionTower(text, flight, 10)

      -- Taxi out.    
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAXIOUT)
      
      -- Get player element.
      local playerElement=flight:GetPlayerElement()
      
      -- Set parking to free. Could be reserved.
      if playerElement and playerElement.parking then
        self:SetParkingFree(playerElement.parking)
      end
      
    else
      self:TextMessageToFlight(string.format("Negative, you must be PARKING to request TAXI!"), flight)
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end  

end

--- Player aborts taxi.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortTaxi(groupname)
  
  -- Get flight.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    -- Get callsign.
    local callsign=self:_GetCallsignName(flight)
    
    -- Pilot request for taxi.
    local text=string.format("%s, %s, cancel my taxi request.", self.alias, callsign)
    self:TransmissionPilot(text, flight)
        
    if flight:IsParking() then
        
      -- Tell pilot remain parking.
      local text=string.format("%s, %s, roger, remain on your parking position.", callsign, self.alias)
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight status to "Parking".
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.PARKING)
      
      -- Get player element.
      local playerElement=flight:GetPlayerElement()
      
      -- Set parking guard.
      if playerElement then
        self:SpawnParkingGuard(playerElement.unit)
      end
      
    elseif flight:IsTaxiing() then
    
      -- Tell pilot to return to parking.
      local text=string.format("%s, %s, roger, return to your parking position.", callsign, self.alias)
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight status to "Taxi Inbound".
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAXIINB)
            
    else
      self:TextMessageToFlight(string.format("Negative, you must be PARKING or TAXIING to abort TAXI!"), flight)
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end  

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Takeoff
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player requests takeoff.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestTakeoff(groupname)
      
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
  
    if flight:IsTaxiing() then
    
      -- Get callsign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Pilot request for taxi.
      local text=string.format("%s, %s, ready for departure. Request takeoff.", self.alias, callsign)
      self:TransmissionPilot(text, flight)    
    
      -- Get number of flights landing.
      local Nlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)
      
      -- Get number of flights taking off.
      local Ntakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
      
      --[[
      local text=""
      if Nlanding==0 and Ntakeoff==0 then
        text="No current traffic. You are cleared for takeoff."
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAKEOFF)
      elseif Nlanding>0 and Ntakeoff>0 then
        text=string.format("Negative, we got %d flights inbound and %d outbound ahead of you. Hold position until futher notice.", Nlanding, Ntakeoff)
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTO)      
      elseif Nlanding>0 then
        if Nlanding==1 then
          text=string.format("Negative, we got %d flight inbound before it's your turn. Wait until futher notice.", Nlanding)
        else
          text=string.format("Negative, we got %d flights inbound. Wait until futher notice.", Nlanding)
        end
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTO)
      elseif Ntakeoff>0 then
        text=string.format("Negative, %d flights ahead of you are waiting for takeoff. Talk to you soon.", Ntakeoff)
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTO)
      end
      ]]
      
      -- We only check for landing flights.
      local text=string.format("%s, %s, ", callsign, self.alias)
      if Nlanding==0 then
      
        -- No traffic.
        text=text.."no current traffic. You are cleared for takeoff."
        
        -- Set status to "Take off".
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAKEOFF)
      elseif Nlanding>0 then
        if Nlanding==1 then
          text=text..string.format("negative, we got %d flight inbound before it's your turn. Hold position until futher notice.", Nlanding)
        else
          text=text..string.format("negative, we got %d flights inbound. Hold positon until futher notice.", Nlanding)
        end
      end      
      
      -- Message from tower.
      self:TransmissionTower(text, flight, 10)
      
    else
      self:TextMessageToFlight(string.format("Negative, you must request TAXI before you can request TAKEOFF!"), flight)  
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player wants to abort takeoff.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortTakeoff(groupname)

  -- Get flight group.    
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then

    -- Flight status.  
    local status=self:GetFlightStatus(flight)

    -- Check that we are taking off or ready for takeoff.  
    if status==FLIGHTCONTROL.FlightStatus.TAKEOFF or status==FLIGHTCONTROL.FlightStatus.READYTO then
    
      -- Get callsign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Pilot request for taxi.
      local text=string.format("%s, %s, abort takeoff.", self.alias, callsign)
      self:TransmissionPilot(text, flight)        
    
      -- Set new flight status.
      if flight:IsParking() then
      
        text=string.format("%s, %s, affirm, remain on your parking position.", callsign, self.alias)
        
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.PARKING)
        
        -- Get player element.
        local playerElement=flight:GetPlayerElement()
        
        -- Set parking guard.
        if playerElement then
          self:SpawnParkingGuard(playerElement.unit)
        end
        
      elseif flight:IsTaxiing() then
        text=string.format("%s, %s, roger, report whether you want to taxi back or takeoff later.", callsign, self.alias)
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAXIOUT)
      else
        env.info(self.lid.."ERROR")
      end
      
      -- Message from tower.
      self:TransmissionTower(text, flight, 10)
      
    else
      self:TextMessageToFlight("Negative, You are NOT in the takeoff queue", flight)
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Player Menu: Parking
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Player reserves a parking spot.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestParking(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
     -- Get callsign.
    local callsign=self:_GetCallsignName(flight)
    
    -- Get player element.
    local player=flight:GetPlayerElement()
     
    -- Set terminal type.
    local TerminalType=AIRBASE.TerminalType.FighterAircraft
    if flight.isHelo then
      TerminalType=AIRBASE.TerminalType.HelicopterUsable
    end    
        -- Current coordinate.
    local coord=flight:GetCoordinate(nil, player.name)

    -- Get spawn position if any.    
    local spot=self:_GetPlayerSpot(player.name)
    
    -- Get closest FREE parking spot if player was not spawned here or spot is already taken.
    if not spot then 
      spot=self:GetClosestParkingSpot(coord, TerminalType, AIRBASE.SpotStatus.FREE)
    end
    
    if spot then
      
      -- Message text.
      local text=string.format("%s, your assigned parking position is terminal ID %d.", callsign, spot.TerminalID)
      
      -- Transmit message.
      self:TransmissionTower(text, flight)
    
      -- If player already has a spot.
      if player.parking then
        self:SetParkingFree(player.parking)
      end
      
      -- Reserve parking for player.
      player.parking=spot
      self:SetParkingReserved(spot, player.name)
      
      -- Update menu ==> Cancel Parking.
      flight:_UpdateMenu(0.2)
      
    else
    
      -- Message text.
      local text=string.format("%s, no free parking spot available. Try again later.", callsign)
      
      -- Transmit message.
      self:TransmissionTower(text, flight)
      
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player cancels parking spot reservation.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerCancelParking(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
     -- Get callsign.
    local callsign=self:_GetCallsignName(flight)
    
    -- Get player element.
    local player=flight:GetPlayerElement()
    
    -- If player already has a spot.
    if player.parking then
      self:SetParkingFree(player.parking)
      player.parking=nil
      self:TextMessageToFlight(string.format("%s, your parking spot reservation at terminal ID %d was cancelled.", callsign, player.parking.TerminalID), flight)
    else
      self:TextMessageToFlight("You did not have a valid parking spot reservation.", flight)
    end
    
    -- Update menu ==> Reserve Parking.
    flight:_UpdateMenu(0.2)
        
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

--- Player arrived at parking position.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerArrived(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    -- Player element.
    local player=flight:GetPlayerElement()

    -- Get current coordinate.
    local coord=flight:GetCoordinate(nil, player.name)
    
    -- Parking spot.
    local spot=self:_GetPlayerSpot(player.name) --#FLIGHTCONTROL.ParkingSpot
    if player.parking then
      spot=self:GetParkingSpotByID(player.parking.TerminalID)
    else
      if not spot then
        spot=self:GetClosestParkingSpot(coord)
      end
    end
        
    if spot then
    
      -- Get callsign.
      local callsign=self:_GetCallsignName(flight)
      
      -- Distance to parking spot.
      local dist=coord:Get2DDistance(spot.Coordinate)
      
      if dist<12 then
      
        -- Message text.
        local text=string.format("%s, %s, arrived at parking position. Terminal ID %d.", self.alias, callsign, spot.TerminalID)
        
        -- Transmit message.
        self:TransmissionPilot(text, flight)
        -- Message text.
        local text=""        
        if spot.ReservedBy and spot.ReservedBy~=player.name then
        
          -- Reserved by someone else.
          text=string.format("%s, this spot is already reserved for %s. Find yourself a different parking position.", callsign, self.alias, spot.ReservedBy)
        
        else
        
          -- Okay, have a drink...
          text=string.format("%s, %s, roger. Enjoy a cool bevarage in the officers' club.", callsign, self.alias)
        
          -- Set player element to parking.
          flight:ElementParking(player, spot)
          
          -- Set flight status to PARKING.
          self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.PARKING)
                
          -- Set parking guard.
          if player then
            self:SpawnParkingGuard(player.unit)
          end
          
        end        
                
        -- Transmit message.
        self:TransmissionTower(text, flight, 10)
        
      else
      
        -- Message text.
        local text=string.format("%s, %s, arrived at parking position.", self.alias, callsign)
        
        -- Transmit message.
        self:TransmissionPilot(text, flight)
        
        local text=""
        if spot.ReservedBy then
          if spot.ReservedBy==player.name then
            -- To far from reserved spot.
            text=string.format("%s, %s, you are still %d meters away from your reserved parking position at terminal ID %d. Continue taxiing!", callsign, self.alias, dist, spot.TerminalID)
          else
            -- Closest spot is reserved by someone else.
            --local spotFree=self:GetClosestParkingSpot(coord, nil, AIRBASE.SpotStatus.Free)          
            text=string.format("%s, %s, the closest parking spot is already reserved. Continue taxiing to a free spot!", callsign, self.alias)
          end        
        else
          -- Too far from closest spot.
          text=string.format("%s, %s, you are still %d meters away from the closest parking position. Continue taxiing to a proper spot!", callsign, self.alias, dist)
        end
        
        -- Transmit message.
        self:TransmissionTower(text, flight, 10)        
      
      end
      
    else
      -- TODO: No spot
    end
    
  else
    self:E(self.lid..string.format("Cannot find flight group %s.", tostring(groupname)))
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Flight and Element Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new flight group.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return Ops.FlightGroup#FLIGHTGROUP Flight group.
function FLIGHTCONTROL:_CreateFlightGroup(group)
  
  -- Check if not already in flights
  if self:_InQueue(self.flights, group) then
    self:E(self.lid..string.format("WARNING: Flight group %s does already exist!", group:GetName()))
    return
  end
  
  -- Debug info.
  self:T(self.lid..string.format("Creating new flight for group %s of aircraft type %s.", group:GetName(), group:GetTypeName()))
  
  -- Get flightgroup from data base.
  local flight=_DATABASE:GetOpsGroup(group:GetName())
  
  -- If it does not exist yet, create one.
  if not flight then
    flight=FLIGHTGROUP:New(group:GetName())
  end
  
  -- Set flightcontrol.
  if flight.homebase and flight.homebase:GetName()==self.airbasename then
    flight:SetFlightControl(self)
  end

  return flight
end

--- Remove flight from all queues.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP Flight The flight to be removed.
function FLIGHTCONTROL:_RemoveFlight(Flight)
  
  -- Loop over all flights in group.
  for i,_flight in pairs(self.flights) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
    -- Check for name.
    if flight.groupname==Flight.groupname then
    
      -- Debug message.
      self:T(self.lid..string.format("Removing flight group %s", flight.groupname))
      
      -- Remove table entry.
      table.remove(self.flights, i)
      
      -- Remove myself.
      Flight.flightcontrol=nil
      
      -- Set flight status to unknown.
      self:SetFlightStatus(Flight, FLIGHTCONTROL.FlightStatus.UNKNOWN)
      
      return true  
    end
  end
  
  -- Debug message.
  self:E(self.lid..string.format("WARNING: Could NOT remove flight group %s", Flight.groupname))
end

--- Get flight from group. 
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Group that will be removed from queue.
-- @param #table queue The queue from which the group will be removed.
-- @return Ops.FlightGroup#FLIGHTGROUP Flight group or nil.
-- @return #number Queue index or nil.
function FLIGHTCONTROL:_GetFlightFromGroup(group)

  if group then

    -- Group name
    local name=group:GetName()
    
    -- Loop over all flight groups in queue
    for i,_flight in pairs(self.flights) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      
      if flight.groupname==name then
        return flight, i
      end
    end
  
    self:T2(self.lid..string.format("WARNING: Flight group %s could not be found in queue.", name))  
  end
  
  self:T2(self.lid..string.format("WARNING: Flight group could not be found in queue. Group is nil!"))
  return nil, nil
end

--- Get element of flight from its unit name. 
-- @param #FLIGHTCONTROL self
-- @param #string unitname Name of the unit.
-- @return Ops.OpsGroup#OPSGROUP.Element Element of the flight or nil.
-- @return #number Element index or nil.
-- @return Ops.FlightGroup#FLIGHTGROUP The Flight group or nil.
function FLIGHTCONTROL:_GetFlightElement(unitname)

  -- Get the unit.
  local unit=UNIT:FindByName(unitname)
  
  -- Check if unit exists.
  if unit then
  
    -- Get flight element from all flights.
    local flight=self:_GetFlightFromGroup(unit:GetGroup())
        
    -- Check if fight exists.
    if flight then

      -- Loop over all elements in flight group.
      for i,_element in pairs(flight.elements) do
        local element=_element --Ops.OpsGroup#OPSGROUP.Element
        
        if element.unit:GetName()==unitname then
          return element, i, flight
        end
      end
      
      self:T2(self.lid..string.format("WARNING: Flight element %s could not be found in flight group.", unitname, flight.groupname))
    end
  end
    
  return nil, nil, nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check Sanity Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check status of all registered flights and do some sanity checks.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckFlights()

  -- First remove all dead flights.
  for i=#self.flights,1,-1 do
    local flight=self.flights[i] --Ops.FlightGroup#FLIGHTGROUP    
    if flight:IsDead() then
      self:T(self.lid..string.format("Removing DEAD flight %s", tostring(flight.groupname)))
      self:_RemoveFlight(flight)
    end  
  end

  -- Count number of players
  self.Nplayers=0
  for _,_flight in pairs(self.flights) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP    
    if not flight.isAI then
      self.Nplayers=self.Nplayers+1
    end    
  end

  -- Check speeding.  
  if self.speedLimitTaxi then

    for _,_flight in pairs(self.flights) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      
      if not flight.isAI then
      
        -- Get player element.
        local playerElement=flight:GetPlayerElement()
        
        -- Current flight status.
        local flightstatus=self:GetFlightStatus(flight)
        
        if playerElement then
        
          -- Check if speeding while taxiing.
          if (flightstatus==FLIGHTCONTROL.FlightStatus.TAXIINB or flightstatus==FLIGHTCONTROL.FlightStatus.TAXIOUT) and self.speedLimitTaxi then
        
            -- Current speed in m/s.
            local speed=playerElement.unit:GetVelocityMPS()
            
            -- Current position.
            local coord=playerElement.unit:GetCoord()
            
            -- We do not want to check speed on runways.
            local onRunway=self:IsCoordinateRunway(coord)
                                   
            -- Debug output.
            self:T(self.lid..string.format("Player %s speed %.1f knots (max=%.1f) onRunway=%s", playerElement.playerName, UTILS.MpsToKnots(speed), UTILS.MpsToKnots(self.speedLimitTaxi), tostring(onRunway)))
            
            if speed and speed>self.speedLimitTaxi and not onRunway then
            
              -- Callsign.
              local callsign=self:_GetCallsignName(flight)            
            
              -- Radio text.
              local text=string.format("%s, slow down, you are taxiing too fast!", callsign)
              
              -- Radio message to player.
              self:TransmissionTower(text, flight)
              
              -- Get player data.
              local PlayerData=flight:_GetPlayerData()
              
              -- Trigger FSM speeding event.              
              self:PlayerSpeeding(PlayerData)
                        
            end
            
          end
          
        end
      end
    end
    
  end
  
end

--- Check status of all registered flights and do some sanity checks.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckParking()

  for TerminalID,_spot in pairs(self.parking) do
    local spot=_spot --Wrapper.Airbase#AIRBASE.ParkingSpot
  
    if spot.Reserved then
      if spot.MarkerID then
        spot.Coordinate:RemoveMark(spot.MarkerID)
      end
      spot.MarkerID=spot.Coordinate:MarkToCoalition(string.format("Parking reserved for %s", tostring(spot.Reserved)), self:GetCoalition())
    end

    -- First remove all dead flights.
    for i=1,#self.flights do
      local flight=self.flights[i] --Ops.FlightGroup#FLIGHTGROUP    
      for _,_element in pairs(flight.elements) do
        local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
        if element.parking and element.parking.TerminalID==TerminalID then
          if spot.MarkerID then
            spot.Coordinate:RemoveMark(spot.MarkerID)            
          end
          spot.MarkerID=spot.Coordinate:MarkToCoalition(string.format("Parking spot occupied by %s", tostring(element.name)), self:GetCoalition())
        end
      end
    end  

  end  
  

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Tell AI to land at the airbase. Flight is added to the landing queue.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param #table parking Free parking spots table.
function FLIGHTCONTROL:_LandAI(flight, parking)

   -- Debug info.
  self:T(self.lid..string.format("Landing AI flight %s.", flight.groupname))
  

  -- Respawn?   
  local respawn=false
    
  if respawn then
  
    -- Get group template.
    local Template=flight.group:GetTemplate()
    
    -- TODO: get landing waypoints from flightgroup.
  
    -- Set route points.
    Template.route.points=wp
    
    for i,unit in pairs(Template.units) do
      local spot=parking[i] --Wrapper.Airbase#AIRBASE.ParkingSpot
      
      local element=flight:GetElementByName(unit.name)
      if element then
      
        -- Set the parking spot at the destination airbase.
        unit.parking_landing=spot.TerminalID
        
        local text=string.format("Reserving parking spot %d for unit %s", spot.TerminalID, tostring(unit.name))
        self:T(self.lid..text)
        
        -- Set parking to RESERVED.
        self:SetParkingReserved(spot, element.name)
        
      else
        env.info("FF error could not get element to assign parking!")      
      end
    end
         
    -- Debug message.
    self:TextMessageToFlight(string.format("Respawning group %s", flight.groupname), flight)
  
    --Respawn the group.
    flight:Respawn(Template)
    
  else
       
    -- Give signal to land.
    flight:ClearToLand()
    
  end
  
end

--- Get holding stack.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #FLIGHTCONTROL.HoldingStack Holding point.
function FLIGHTCONTROL:_GetHoldingStack(flight)

  -- Debug message.
  self:T(self.lid..string.format("Getting holding point for flight %s", flight:GetName()))
  
  for i,_hp in pairs(self.holdingpatterns) do
    local holdingpattern=_hp --#FLIGHTCONTROL.HoldingPattern
    
    self:T(self.lid..string.format("Checking holding point %s", holdingpattern.name))
    
    for j,_stack in pairs(holdingpattern.stacks) do
      local stack=_stack --#FLIGHTCONTROL.HoldingStack
      local name=stack.flightgroup and stack.flightgroup:GetName() or "empty"
      self:T(self.lid..string.format("Stack %d: %s", j, name))
      if not stack.flightgroup then
        return stack
      end
    end
  
  end

  return nil
end


--- Count flights in holding pattern.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.HoldingPattern Pattern The pattern.
-- @return #FLIGHTCONTROL.HoldingStack Holding point.
function FLIGHTCONTROL:_CountFlightsInPattern(Pattern)

  local N=0
        
  for _,_stack in pairs(Pattern.stacks) do
    local stack=_stack --#FLIGHTCONTROL.HoldingStack
    if stack.flightgroup then
      N=N+1
    end
  end
  
  return N
end


--- AI flight on final.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:_FlightOnFinal(flight)

  -- Callsign.
  local callsign=self:_GetCallsignName(flight)

  -- Message text.
  local text=string.format("%s, final", callsign)
  
  -- Transmit message.
  self:TransmissionPilot(text, flight)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Radio Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Radio transmission from tower.
-- @param #FLIGHTCONTROL self
-- @param #string Text The text to transmit.
-- @param Ops.FlightGroup#FLIGHTGROUP Flight The flight.
-- @param #number Delay Delay in seconds before the text is transmitted. Default 0 sec.
function FLIGHTCONTROL:TransmissionTower(Text, Flight, Delay)

  if self.radioOnlyIfPlayers==true and self.Nplayers==0 then
    self:T(self.lid.."No players ==> skipping TOWER radio transmission")
    return
  end 

  -- Spoken text.
  local text=self:_GetTextForSpeech(Text)
    
  -- "Subtitle".
  local subgroups=nil
  if Flight and not Flight.isAI then
    local playerData=Flight:_GetPlayerData()
    if playerData.subtitles and (not self.nosubs) then
      subgroups=subgroups or {}
      table.insert(subgroups, Flight.group)
    end
  end
  
  -- New transmission.  
  local transmission=self.msrsqueue:NewTransmission(text, nil, self.msrsTower, nil, 1, subgroups, Text)
  
  -- Set time stamp. Can be in the future.
  self.Tlastmessage=timer.getAbsTime() + (Delay or 0)
  
  -- Debug message.
  self:T(self.lid..string.format("Radio Tower: %s", Text))

end

--- Radio transmission.
-- @param #FLIGHTCONTROL self
-- @param #string Text The text to transmit.
-- @param Ops.FlightGroup#FLIGHTGROUP Flight The flight.
-- @param #number Delay Delay in seconds before the text is transmitted. Default 0 sec.
function FLIGHTCONTROL:TransmissionPilot(Text, Flight, Delay)

  if self.radioOnlyIfPlayers==true and self.Nplayers==0 then
    self:T(self.lid.."No players ==> skipping PILOT radio transmission")
    return
  end 


  -- Get player data.
  local playerData=Flight:_GetPlayerData()
    
  -- Check if player enabled his "voice".
  if playerData==nil or playerData.myvoice then

    -- Spoken text.
    local text=self:_GetTextForSpeech(Text)
    
    -- MSRS instance to use.
    local msrs=self.msrsPilot -- Sound.SRS#MSRS
 
    if Flight.useSRS and Flight.msrs then
      
      -- Pilot radio call using settings of the FLIGHTGROUP. We just overwrite the frequency.
      msrs=Flight.msrs
       
    end
        
    -- "Subtitle".
    local subgroups=nil
    if Flight and not Flight.isAI then
      local playerData=Flight:_GetPlayerData()
      if playerData.subtitles and (not self.nosubs) then
        subgroups=subgroups or {}
        table.insert(subgroups, Flight.group)
      end
    end      
    
    -- Add transmission to msrsqueue.
    local coordinate = Flight:GetCoordinate(true)
    msrs:SetCoordinate()
    self.msrsqueue:NewTransmission(text, nil, msrs, nil, 1, subgroups, Text, nil, self.frequency, self.modulation)
    
  end

  -- Set time stamp.
  self.Tlastmessage=timer.getAbsTime() + (Delay or 0)

  -- Debug message.
  self:T(self.lid..string.format("Radio Pilot: %s", Text))
  
end


--- Text message to group.
-- @param #FLIGHTCONTROL self
-- @param #string Text The text to transmit.
-- @param Ops.FlightGroup#FLIGHTGROUP Flight The flight.
-- @param #number Duration Duration in seconds. Default 5.
-- @param #boolean Clear Clear screen.
-- @param #number Delay Delay in seconds before the text is transmitted. Default 0 sec.
function FLIGHTCONTROL:TextMessageToFlight(Text, Flight, Duration, Clear, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, FLIGHTCONTROL.TextMessageToFlight, self, Text, Flight, Duration, Clear, 0)
  else

    if Flight and Flight.group and Flight.group:IsAlive() then
    
      -- Group ID.
      local gid=Flight.group:GetID()
    
      -- Out text.
      trigger.action.outTextForGroup(gid, self:_CleanText(Text), Duration or 5, Clear)
      
    end
    
  end

end

--- Clean text. Remove control sequences.
-- @param #FLIGHTCONTROL self
-- @param #string Text The text.
-- @param #string Cleaned text.
function FLIGHTCONTROL:_CleanText(Text)

  local text=Text:gsub("\n$",""):gsub("\n$","")

  return text
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [INTERNAL] Add parking guard in front of a parking aircraft - delayed for MP.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Unit#UNIT unit The aircraft.
function FLIGHTCONTROL:_SpawnParkingGuard(unit)
      -- Position of the unit.
    local coordinate=unit:GetCoordinate()

    -- Parking spot.
    local spot=self:GetClosestParkingSpot(coordinate)
    
    if not spot.ParkingGuard then
    
      -- Current heading of the unit.
      local heading=unit:GetHeading()
      
      -- Length of the unit + 3 meters.
      local size, x, y, z=unit:GetObjectSize()
      
      local xdiff = 3
      --Fix for hangars, puts the guy out front and not on top.
      if AIRBASE._CheckTerminalType(spot.TerminalType, AIRBASE.TerminalType.Shelter) then 
          xdiff = 27-(x*0.5)              
      end
      
      if (AIRBASE._CheckTerminalType(spot.TerminalType, AIRBASE.TerminalType.OpenMed) or AIRBASE._CheckTerminalType(spot.TerminalType, AIRBASE.TerminalType.Shelter)) and self.airbasename == AIRBASE.Sinai.Ramon_Airbase then 
          xdiff = 12          
      end      
      
      -- Debug message.
      self:T2(self.lid..string.format("Parking guard for %s: heading=%d, length x=%.1f m, xdiff=%.1f m", unit:GetName(), heading, x, xdiff))
      
      -- Coordinate for the guard.
      local Coordinate=coordinate:Translate(x*0.5+xdiff, heading)
      
      -- Let him face the aircraft.
      local lookat=heading-180
      
      -- Set heading and AI off to save resources.
      self.parkingGuard:InitHeading(lookat)
      
      -- Turn AI Off.
      if self.parkingGuard:IsInstanceOf("SPAWN") then
        --self.parkingGuard:InitAIOff()
      end
      
      -- Group that is spawned.
      spot.ParkingGuard=self.parkingGuard:SpawnFromCoordinate(Coordinate)
      
    else
      self:E(self.lid.."ERROR: Parking Guard already exists!")
    end
end

--- Add parking guard in front of a parking aircraft.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Unit#UNIT unit The aircraft.
function FLIGHTCONTROL:SpawnParkingGuard(unit)
  
  if unit and self.parkingGuard then
    
    -- Schedule delay so in MP we get the heading of the client's plane
    self:ScheduleOnce(1,FLIGHTCONTROL._SpawnParkingGuard,self,unit)
    
  end
    
end

--- Remove parking guard.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.ParkingSpot spot
-- @param #number delay Delay in seconds.
function FLIGHTCONTROL:RemoveParkingGuard(spot, delay)

  if delay and delay>0 then
    self:ScheduleOnce(delay, FLIGHTCONTROL.RemoveParkingGuard, self, spot)
  else
  
    if spot.ParkingGuard then
      spot.ParkingGuard:Destroy()
      spot.ParkingGuard=nil
    end
    
  end

end

--- Check if a flight is on a runway
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight
-- @param Wrapper.Airbase#AIRBASE.Runway Runway or nil.
function FLIGHTCONTROL:_IsFlightOnRunway(flight)

  for _,_runway in pairs(self.airbase.runways) do
    local runway=_runway --Wrapper.Airbase#AIRBASE.Runway
    
    local inzone=flight:IsInZone(runway.zone)
    
    if inzone then
      return runway
    end
    
  end

  return nil
end

--- [User] Set callsign options for TTS output. See @{Wrapper.Group#GROUP.GetCustomCallSign}() on how to set customized callsigns.
-- @param #FLIGHTCONTROL self
-- @param #boolean ShortCallsign If true, only call out the major flight number. Default = `true`.
-- @param #boolean Keepnumber If true, keep the **customized callsign** in the #GROUP name for players as-is, no amendments or numbers. Default = `true`.
-- @param #table CallsignTranslations (optional) Table to translate between DCS standard callsigns and bespoke ones. Does not apply if using customized
-- callsigns from playername or group name.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetCallSignOptions(ShortCallsign,Keepnumber,CallsignTranslations)
  if not ShortCallsign or ShortCallsign == false then
   self.ShortCallsign = false
  else
   self.ShortCallsign = true
  end
  self.Keepnumber = Keepnumber or false
  self.CallsignTranslations = CallsignTranslations
  return self  
end

--- Get callsign name of a given flight.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #string Callsign or "Ghostrider 1-1".
function FLIGHTCONTROL:_GetCallsignName(flight)

  local callsign=flight:GetCallsignName(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations)
  
  --local name=string.match(callsign, "%a+")
  --local number=string.match(callsign, "%d+")
  
  return callsign
end


--- Get text for text-to-speech.
-- Numbers are spaced out, e.g. "Heading 180" becomes "Heading 1 8 0 ".
-- @param #FLIGHTCONTROL self
-- @param #string text Original text.
-- @return #string Spoken text.
function FLIGHTCONTROL:_GetTextForSpeech(text)

  --- Function to space out text.
  local function space(text)
    
    local res=""
    
    for i=1, #text do
      local char=text:sub(i,i)
      res=res..char.." "
    end
  
    return res
  end
  
  -- Space out numbers.
  local t=text:gsub("(%d+)", space)
  
  --TODO: 9 to niner.
  
  return t
end


--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned.
-- @param #FLIGHTCONTROL self
-- @param #string unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FLIGHTCONTROL:_GetPlayerUnitAndName(unitName)

  if unitName then

    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(unitName)

    if DCSunit then

      -- Get player name if any.
      local playername=DCSunit:getPlayerName()

      -- Unit object.
      local unit=UNIT:Find(DCSunit)

      -- Check if enverything is there.
      if DCSunit and unit and playername then
        self:T(self.lid..string.format("Found DCS unit %s with player %s", tostring(unitName), tostring(playername)))
        return unit, playername
      end

    end

  end

  -- Return nil if we could not find a player.
  return nil,nil
end

--- Check holding pattern markers. Draw if they should exists and remove if they should not.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckMarkHoldingPatterns()

  for _,pattern in pairs(self.holdingpatterns) do
    local Pattern=pattern

    if self.markPatterns then
    
      self:_MarkHoldingPattern(Pattern)
    
    else
  
      self:_UnMarkHoldingPattern(Pattern)
  
    end

  end

end

--- Draw marks of holding pattern (if they do not exist.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.HoldingPattern Pattern Holding pattern table.
function FLIGHTCONTROL:_MarkHoldingPattern(Pattern)
  
  if not Pattern.markArrow then
    Pattern.markArrow=Pattern.pos0:ArrowToAll(Pattern.pos1, nil, {1,0,0}, 1, {1,1,0}, 0.5, 2, true)      
  end
  
  if not Pattern.markArrival then
    Pattern.markArrival=Pattern.arrivalzone:DrawZone()
  end
    
end

--- Removem markers of holding pattern (if they exist).
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.HoldingPattern Pattern Holding pattern table.
function FLIGHTCONTROL:_UnMarkHoldingPattern(Pattern)
  
  if Pattern.markArrow then
    UTILS.RemoveMark(Pattern.markArrow)
    Pattern.markArrow=nil    
  end

  if Pattern.markArrival then
    UTILS.RemoveMark(Pattern.markArrival)
    Pattern.markArrival=nil    
  end
  
end

--- Add a holding pattern.
-- @param #FLIGHTCONTROL self
-- @return #FLIGHTCONTROL.HoldingPattern Holding pattern table.
function FLIGHTCONTROL:_AddHoldingPatternBackup()

  local runway=self:GetActiveRunway()
  
  local heading=runway.heading
  
  local vec2=self.airbase:GetVec2()
  
  local Vec2=UTILS.Vec2Translate(vec2, UTILS.NMToMeters(5), heading+90)
  
  local ArrivalZone=ZONE_RADIUS:New("Arrival Zone", Vec2, 5000)

  -- Add holding pattern with very low priority.
  self.holdingBackup=self:AddHoldingPattern(ArrivalZone, heading, 15, 5, 25, 999)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
