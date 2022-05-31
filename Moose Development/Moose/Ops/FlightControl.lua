--- **OPS** - Air Traffic Control for AI and human players.
-- 
-- 
--
-- **Main Features:**
--
--    * Manage aircraft departure and arrival
--    * Handles AI and human players
--    * Limit number of AI groups taxiing and landing simultaniously
--    * Immersive voice overs via SRS text-to-speech
--    * Define holding zones for airdromes
--     
-- ===
--
-- ### Author: **funkyfranky**
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
-- @field #table runways Runway table.
-- @field #table flights All flights table.
-- @field #table clients Table with all clients spawning at this airbase.
-- @field Ops.ATIS#ATIS atis ATIS object.
-- @field #number activerwyno Number of active runway.
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
-- @field Sound.SRS#MSRS msrsTower Moose SRS wrapper.
-- @field Sound.SRS#MSRS msrsPilot Moose SRS wrapper.
-- @field #number Tlastmessage Time stamp (abs.) of last radio transmission.
-- @field #number dTmessage Time interval between messages.
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
-- Therefore, it solves (or reduces) a lot of common problems with the DCS implementation (which is barly existing at this point).
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
-- * Only fixed wing aircraft are handled until now, *i.e.* no helos.
-- 
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
  activerwyno    =     1,
  atcfreq        =   nil,
  atcradio       =   nil,
  atcradiounitname = nil,
  Nlanding         = nil,
  dTlanding        = nil,
  Nparkingspots    = nil,
  holdingpatterns    =  {},
  hpcounter        =   0,
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

--- Holding stack.
-- @type FLIGHTCONTROL.HoldingStack
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup Flight group of this stack.
-- @field #number angels Holding altitude in Angels.
-- @field Core.Point#COORDINATE pos0 First position of racetrack holding pattern.
-- @field Core.Point#COORDINATE pos1 Second position of racetrack holding pattern.
-- @field #number heading Heading.

--- Player menu data.
-- @type FLIGHTCONTROL.PlayerMenu
-- @field Core.Menu#MENU_GROUP root Root menu.
-- @field Core.Menu#MENU_GROUP_COMMAND RequestTaxi Request taxi.

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

--- Runway data.
-- @type FLIGHTCONTROL.Runway
-- @field #number direction Direction of the runway.
-- @field #number length Length of runway in meters.
-- @field #number width Width of runway in meters.
-- @field Core.Point#COORDINATE position Position of runway start.

--- FlightControl class version.
-- @field #string version
FLIGHTCONTROL.version="0.5.2"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list

-- TODO: Runway destroyed.
-- TODO: Support airwings. Dont give clearance for Alert5 or if mission has not started.
-- TODO: Switch to enable/disable AI messages.
-- TODO: Improve ATC TTS messages.
-- TODO: Talk me down option.
-- TODO: ATIS option.
-- TODO: Check runways and clean up.
-- TODO: Accept and forbit parking spots.
-- TODO: Add FARPS?
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
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:New(AirbaseName, Frequency, Modulation, PathToSRS)

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

  -- Set alias.
  self.alias=self.airbasename.." Tower"
  
  -- Defaults:
  self:SetLimitLanding(2, 0)
  self:SetLimitTaxi(1, false, 0)
  self:SetLandingInterval()
  self:SetFrequency(Frequency, Modulation)
  
  -- SRS for Tower.
  self.msrsTower=MSRS:New(PathToSRS, Frequency, Modulation)
  self.msrsTower:SetLabel(self.alias)
  
  -- SRS for Pilot.
  self.msrsPilot=MSRS:New(PathToSRS, Frequency, Modulation)
  self.msrsPilot:SetGender("male")
  self.msrsPilot:SetCulture("en-US")
  self.msrsPilot:SetLabel("Pilot")
  
  -- Wait at least 10 seconds after last radio message before calling the next status update.
  self.dTmessage=10
    
  -- Init runways.
  self:_InitRunwayData()
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",          "*")           -- Update status.
  self:AddTransition("*",             "Stop",            "Stopped")     -- Stop FSM.
  
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


  --- Triggers the FSM event "Status".
  -- @function [parent=#FLIGHTCONTROL] Status
  -- @param #FLIGHTCONTROL self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#FLIGHTCONTROL] __Status
  -- @param #FLIGHTCONTROL self
  -- @param #number delay Delay in seconds.

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

--- Set the tower frequency.
-- @param #FLIGHTCONTROL self
-- @param #number Frequency Frequency in MHz. Default 305 MHz.
-- @param #number Modulation Modulation `radio.modulation.AM`=0, `radio.modulation.FM`=1. Default `radio.modulation.AM`.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetFrequency(Frequency, Modulation)

  self.frequency=Frequency or 305
  self.modulation=Modulation or radio.modulation.AM

  return self
end

--- Set the number of aircraft groups, that are allowed to land simultaniously.
-- Note that this restricts AI and human players.
-- @param #FLIGHTCONTROL self
-- @param #number Nlanding Max number of aircraft landing simultaniously. Default 2.
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


--- Set the number of **AI** aircraft groups, that are allowed to taxi simultaniously.
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
-- @return #FLIGHTCONTROL.HoldingPattern Holding pattern table.
function FLIGHTCONTROL:AddHoldingPattern(ArrivalZone, Heading, Length, FlightlevelMin, FlightlevelMax)

  -- Get ZONE if passed as string.
  if type(ArrivalZone)=="string" then
    ArrivalZone=ZONE:New(ArrivalZone)
  end
  
  -- Increase counter.
  self.hpcounter=self.hpcounter+1

  local hp={} --#FLIGHTCONTROL.HoldingPattern
  hp.arrivalzone=ArrivalZone  
  hp.uid=self.hpcounter
  hp.name=string.format("%s-%d", ArrivalZone:GetName(), hp.uid)
  hp.pos0=ArrivalZone:GetCoordinate()
  hp.pos1=hp.pos0:Translate(UTILS.NMToMeters(Length or 15), Heading)
  hp.angelsmin=FlightlevelMin or 5
  hp.angelsmax=FlightlevelMax or 15
  
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
  
  -- Mark holding pattern.
  hp.pos0:ArrowToAll(hp.pos1, nil, {1,0,0}, 1, {1,1,0}, 0.5, 2, true)
  ArrivalZone:DrawZone()
  
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
  self:HandleEvent(EVENTS.Crash)
 
  -- Init status updates.
  self:__Status(-1)
end

--- Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onbeforeStatus()

  if self.Tlastmessage then
    local Tnow=timer.getAbsTime()
    
    -- Time interval between last radio message.
    local dT=Tnow-self.Tlastmessage
        
    if dT<self.dTmessage then
    
      -- Time
      local dt=self.dTmessage-dT+1
    
      -- Debug info.
      local text=string.format("Last message sent %d sec ago. Will call status again in %d sec", dT, dt)
      self:T(self.lid..text)
        
      -- Call status again in dt seconds.
      self:__Status(-dt)
      
      -- Deny transition.
      return false
    else
      self:T2(self.lid..string.format("Last radio sent %d>%d sec ago. Status update allowed", dT, self.dTmessage))
    end
  end

  return true
end

--- Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStatus()

  -- Debug message.
  self:T2(self.lid.."Status update")

  -- Check status of all registered flights.
  self:_CheckFlights()
  
  -- Check parking spots.
  --self:_CheckParking()
  
  -- Check waiting and landing queue.
  self:_CheckQueues()
  
  -- Get runway.
  local runway=self:GetActiveRunway()
    
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
    local text=string.format("State %s - Runway %s - Parking F=%d/O=%d/R=%d of %d - Flights=%s: Qpark=%d Qtxout=%d Qready=%d Qto=%d | Qinbound=%d Qhold=%d Qland=%d Qtxinb=%d Qarr=%d", 
    self:GetState(), runway.idx, Nfree, Noccu, Nresv, self.Nparkingspots, Nflights, NQparking, NQtaxiout, NQreadyto, NQtakeoff, NQinbound, NQholding, NQlanding, NQtaxiinb, NQarrived)
    self:I(self.lid..text)
  end
  
  if Nflights==Nqueues then
    --Check!
  else
    self:E(string.format("WARNING: Number of total flights %d!=%d number of flights in all queues!", Nflights, Nqueues))
  end

  -- Next status update in ~30 seconds.
  self:__Status(-30)
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

--- Event handler for event crash.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventCrash(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("CRASH: unit  = %s", tostring(EventData.IniUnitName)))
  self:T3(self.lid..string.format("CRASH: group = %s", tostring(EventData.IniGroupName)))
  
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
          local callsign=flight:GetCallsignName()
          
          -- Runway.
          local runway=self:GetActiveRunwayText()
                
          -- Message.
          local text=string.format("%s, %s, you are cleared to land, runway %s", callsign, self.alias, runway)
                    
          -- Transmit message.
          self:TransmissionTower(text, flight)
          
          -- Message.
          local text=string.format("Runway %s, %s", runway, callsign)
                    
          -- Transmit message.
          self:TransmissionPilot(text, flight, 10)          
    
          -- Give AI the landing signal.
          if flight.isAI then
            self:_LandAI(flight, parking)
          else
            -- TODO: Humans have to confirm via F10 menu.
            self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.LANDING)
            flight:_UpdateMenu(0.5)
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
        local callsign=flight:GetCallsignName()
          
        -- Runway.
        local runway=self:GetActiveRunwayText()
      
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

  local Qholding=self:GetFlights(FLIGHTCONTROL.FlightStatus.HOLDING)

  if #Qholding==0 then
    return nil
  elseif #Qholding==1 then
    local fg=Qholding[1] --Ops.FlightGroup#FLIGHTGROUP
    local T=fg:GetHoldingTime()
    if T>60 then
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
  if T>60 then
    return fg
  end
    
  return nil
end


--- Get next flight waiting for taxi and takeoff clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightParking()

  -- Get flights ready for take off.
  local QreadyTO=self:GetFlights(FLIGHTCONTROL.FlightStatus.READYTO, OPSGROUP.GroupStatus.TAXIING)

  -- First check human players.
  if #QreadyTO>0 then    
    -- First come, first serve.
    return QreadyTO[1]
  end
  
  -- Get flights ready to taxi.
  local QreadyTX=self:GetFlights(FLIGHTCONTROL.FlightStatus.READYTX, OPSGROUP.GroupStatus.PARKING)

  -- First check human players.
  if #QreadyTX>0 then
    -- First come, first serve.
    return QreadyTX[1]
  end
  
  -- Get AI flights parking.
  local Qparking=self:GetFlights(FLIGHTCONTROL.FlightStatus.PARKING, nil, true)
  
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
      text=text..string.format("\n[%d] %s %.1f", i, flight.groupname, flight:GetParkingTime())
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

  return flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename or false
  
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

--- Initialize data of runways.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_InitRunwayData()
  self.runways=self.airbase:GetRunwayData()
end

--- Get the active runway based on current wind direction.
-- @param #FLIGHTCONTROL self
-- @return Wrapper.Airbase#AIRBASE.Runway Active runway.
function FLIGHTCONTROL:GetActiveRunway()
  return self.airbase:GetActiveRunway()
end

--- Get the active runway based on current wind direction.
-- @param #FLIGHTCONTROL self
-- @return #string Runway text, e.g. "31L" or "09".
function FLIGHTCONTROL:GetActiveRunwayText()
  local rwy=""
  local rwyL
  if self.atis then
    rwy, rwyL=self.atis:GetActiveRunway()
    if rwyL==true then
      rwy=rwy.."L"
    elseif rwyL==false then
      rwy=rwy.."R"
    end
  else
    rwy=self.airbase:GetActiveRunway().idx
  end
  return rwy
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
    local text=string.format("Parking ID=%d, Terminal=%d: Free=%s, Client=%s, Dist=%.1f", spot.TerminalID, spot.TerminalType, tostring(spot.Free), tostring(spot.ClientSpot), spot.DistToRwy)
    self:I(self.lid..text)

    -- Add to table.
    self.parking[spot.TerminalID]=spot
    
    -- Marker.
    spot.Marker=MARKER:New(spot.Coordinate, "Spot"):ReadOnly():ToCoalition(self:GetCoalition())
    
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
      
        --env.info(string.format("FF parking spot %d is occupied by unit %s alive=%s", spot.TerminalID, unitname, tostring(isalive)))
      
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
function FLIGHTCONTROL:SetParkingFree(spot)

  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
  spot.Status=AIRBASE.SpotStatus.FREE
  spot.OccupiedBy=nil
  spot.ReservedBy=nil
  
  self:UpdateParkingMarker(spot)

end

--- Set parking spot to RESERVED and update F10 marker.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
-- @param #string unitname Name of the unit occupying the spot. Default "unknown". 
function FLIGHTCONTROL:SetParkingReserved(spot, unitname)

  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
  spot.Status=AIRBASE.SpotStatus.RESERVED
  spot.ReservedBy=unitname or "unknown"
  
  self:UpdateParkingMarker(spot)

end

--- Set parking spot to OCCUPIED and update F10 marker.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
-- @param #string unitname Name of the unit occupying the spot. Default "unknown".
function FLIGHTCONTROL:SetParkingOccupied(spot, unitname)

  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
  spot.Status=AIRBASE.SpotStatus.OCCUPIED
  spot.OccupiedBy=unitname or "unknown"
  
  self:UpdateParkingMarker(spot)

end

--- Update parking markers.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
function FLIGHTCONTROL:UpdateParkingMarker(spot)

  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
  --env.info(string.format("FF updateing spot %d  status=%s", spot.TerminalID, spot.Status))
  
  -- Only mark OCCUPIED and RESERVED spots.
  if spot.Status==AIRBASE.SpotStatus.FREE then
  
    if spot.Marker then
      spot.Marker:Remove()
    end
  
  else
  
    local text=string.format("Spot %d (type %d): %s", spot.TerminalID, spot.TerminalType, spot.Status:upper())
    if spot.OccupiedBy then
      text=text..string.format("\nOccupied by %s", spot.OccupiedBy)
    end
    if spot.ReservedBy then
      text=text..string.format("\nReserved for %s", spot.ReservedBy)
    end  
    if spot.ClientSpot then
      text=text..string.format("\nClient %s", tostring(spot.ClientSpot))
    end
    
    if spot.Marker then
    
      if text~=spot.Marker.text then
        spot.Marker:UpdateText(text)
      end
      
    else
    
      spot.Marker=MARKER:New(spot.Coordinate, text):ToAll()
    
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

  -- Init all elements as NOT parking anywhere.
  for _,_flight in pairs(self.flights) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    -- Loop over all elements.
    for _,_element in pairs(flight.elements) do
      local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
      local parking=element.parking
      if parking and parking.TerminalID==spot.TerminalID then
        return element.name
      end
    end
  end

  return nil
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
-- Payer Menu
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
  
  -- Debug info.
  self:T(self.lid..string.format("Creating ATC player menu for flight %s: in state=%s status=%s, gotcontrol=%s", tostring(flight.groupname), flight:GetState(), flightstatus, tostring(gotcontrol)))


  -- Airbase root menu.  
  local rootmenu=MENU_GROUP:New(group, self.airbasename, mainmenu)
  
  ---
  -- Help Menu
  ---
  local helpmenu=MENU_GROUP:New(group, "Help",  rootmenu)
  MENU_GROUP_COMMAND:New(group, "Radio Check",     helpmenu, self._PlayerRadioCheck,     self, groupname)
  MENU_GROUP_COMMAND:New(group, "Confirm Status",  helpmenu, self._PlayerConfirmStatus,  self, groupname)
  MENU_GROUP_COMMAND:New(group, "Mark Holding",    helpmenu, self._PlayerNotImplemented, self, groupname)
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
  
    if flight:IsParking() then
      ---
      -- Parking
      ---
      
      if status==FLIGHTCONTROL.FlightStatus.READYTX then
        MENU_GROUP_COMMAND:New(group, "Abort Taxi",    rootmenu, self._PlayerAbortTaxi,   self, groupname)
      else
        MENU_GROUP_COMMAND:New(group, "Request Taxi",  rootmenu, self._PlayerRequestTaxi, self, groupname)
      end
      
    elseif flight:IsTaxiing() then
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
        MENU_GROUP_COMMAND:New(group, "Request Parking",    rootmenu, self._PlayerRequestParking, self, groupname)
        MENU_GROUP_COMMAND:New(group, "Arrived at Parking", rootmenu, self._PlayerArrived,        self, groupname)          
      end
      
    elseif flight:IsAirborne() then
      ---
      -- Airborne
      ---
      
    elseif flight:IsInbound() then
      ---
      -- Inbound
      ---

      MENU_GROUP_COMMAND:New(group, "Holding",       rootmenu, self._PlayerHolding,      self, groupname)
      MENU_GROUP_COMMAND:New(group, "Abort Inbound", rootmenu, self._PlayerAbortInbound, self, groupname)
      MENU_GROUP_COMMAND:New(group, "Request Parking", rootmenu, self._PlayerRequestParking, self, groupname)

      
    elseif flight:IsHolding() then
      ---
      -- Holding
      ---

      MENU_GROUP_COMMAND:New(group, "Landing",       rootmenu, self._PlayerConfirmLanding, self, groupname)
      MENU_GROUP_COMMAND:New(group, "Abort Holding", rootmenu, self._PlayerAbortHolding,   self, groupname)
      MENU_GROUP_COMMAND:New(group, "Request Parking", rootmenu, self._PlayerRequestParking, self, groupname)

    elseif flight:IsLanding() then
      ---
      -- Landing
      ---

      MENU_GROUP_COMMAND:New(group, "Abort Landing", rootmenu, self._PlayerAbortLanding, self, groupname)
      MENU_GROUP_COMMAND:New(group, "Request Parking", rootmenu, self._PlayerRequestParking, self, groupname)
      
    elseif flight:IsLanded() then
      ---
      -- Landed
      ---      
      
      MENU_GROUP_COMMAND:New(group, "Arrived at Parking", rootmenu, self._PlayerArrived,        self, groupname)
      MENU_GROUP_COMMAND:New(group, "Request Parking",    rootmenu, self._PlayerRequestParking, self, groupname)
      
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
    local callsign=flight:GetCallsignName()
    
    -- Pilot calls inbound for landing.
    local text=string.format("%s, %s, radio check %.3f", self.alias, callsign, self.frequency)
    
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
    local callsign=flight:GetCallsignName()
    
    -- Pilot calls inbound for landing.
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
    text=text..string.format("\nFrequency: %.3f %s", self.frequency, UTILS.GetModulationName(self.modulation))
    text=text..string.format("\nActive Runway: %s", self:GetActiveRunwayText())

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
    
    if self.atis then
      text=text..string.format("\nATIS %.3f MHz %s", self.atis.frequency, UTILS.GetModulationName(self.atis.modulation))
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
      
    end

    -- Message to flight
    self:TextMessageToFlight(text, flight, 10, true)
    
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
      local callsign=flight:GetCallsignName()
            
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
      
        -- Call RTB event. This also sets the flight control and flight status to INBOUND and updates the menu.
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
          local text=string.format("%s, %s, roger, fly heading %03d for %d nautical miles, hold at angels %d. Report status when entering the pattern", 
          callsign, self.alias, heading, dist, stack.angels)
          
          -- Send message.
          self:TransmissionTower(text, flight, 15)
            
        else
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
      local callsign=flight:GetCallsignName()
            
      -- Get player element.
      local player=flight:GetPlayerElement()
      
      -- Current player coord.
      local flightcoord=flight:GetCoordinate(nil, player.name)
      
      -- Distance from player to airbase.
      local dist=flightcoord:Get2DDistance(self:GetCoordinate())
      
      -- Call sign.
      local callsign=flight:GetCallsignName()

      -- Heading to holding point.
      local heading=flightcoord:HeadingTo(flight.stack.pos0)
      
      -- Distance to holding point in meters.
      local distance=flightcoord:Get2DDistance(flight.stack.pos0)
      
      -- Distance in NM.
      local dist=UTILS.MetersToNM(distance)
  
      -- Message text.
      local text=string.format("%s, fly heading %03d for %d nautical miles, hold at angels %d.", 
      callsign, self.alias, heading, dist, flight.stack.angels)
      
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
      local callsign=flight:GetCallsignName()
      
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
        local callsign=flight:GetCallsignName()
      
        -- Player element.
        local player=flight:GetPlayerElement()      
      
        -- Holding stack.
        local stack=flight.stack
        
        if stack then
        
          -- Current coordinate.
          local Coordinate=flight:GetCoordinate(nil, player.name)
        
          -- Distance.
          local dist=stack.pos0:Get2DDistance(Coordinate)
          
          if dist<5000 then
        
            -- Message to flight
            local text=string.format("%s, roger, you are added to the holding queue!", callsign)
            self:TextMessageToFlight(text, flight, 10, true)
    
            -- Call holding event.        
            flight:Holding()
            
          else

            -- Message to flight
            local text=string.format("Negative, you have to be within 5 km!")         
            self:TextMessageToFlight(text, flight, 10, true)
          
          end
          
        else
          --TODO: Error not holding stack.
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
      local callsign=flight:GetCallsignName()
      
      -- Pilot calls inbound for landing.
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
      
    if flight:IsHolding() and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=flight:GetCallsignName()
      
      -- Pilot calls inbound for landing.
      local text=string.format("%s, %s, leaving pattern for landing", self.alias, callsign)
      
      -- Radio message.
      self:TransmissionPilot(text, flight)
       
      -- Set flight.
      if flight.stack then
        flight.stack.flightgroup=nil
        flight.stack=nil
      else
        self:E(self.lid.."ERROR: No stack!")
      end
      
      -- Not holding any more.
      flight.Tholding=nil
      
      -- Set flight to landing.
      flight:Landing()
      
      -- Message text.
      local text=string.format("%s, continue approach",  callsign)
          
      -- Send message.
      self:TransmissionTower(text, flight, 10)
      
      -- Create player menu.
      flight:_UpdateMenu(0.5)
            
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

--- Player aborts landing.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortLanding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
    if flight:IsLanding() and self:IsControlling(flight) then
      
      -- Call sign.
      local callsign=flight:GetCallsignName()
      
      -- Pilot calls inbound for landing.
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
    local callsign=flight:GetCallsignName()
    
    -- Pilot request for taxi.
    local text=string.format("%s, %s, request taxi to runway.", self.alias, callsign)        
    self:TransmissionPilot(text, flight)
        
    if flight:IsParking() or flight:IsTaxiing() then
        
      -- Tell pilot to wait until cleared.
      local text=string.format("%s, %s, hold position until further notice.", callsign, self.alias)
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight status to "Ready to Taxi".
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTX)
      
      -- Update menu.
      flight:_UpdateMenu(0.5)
      
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
    local callsign=flight:GetCallsignName()
    
    -- Pilot request for taxi.
    local text=string.format("%s, %s, abort taxi request.", self.alias, callsign)
    self:TransmissionPilot(text, flight)
        
    if flight:IsParking() then
        
      -- Tell pilot remain parking.
      local text=string.format("%s, %s, roger, remain on your parking position.", callsign, self.alias)
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight status to "Ready for Take-off".
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.PARKING)
      
      -- Update menu.
      flight:_UpdateMenu(0.5)
      
    elseif flight:IsTaxiing() then
    
      -- Tell pilot to return to parking.
      local text=string.format("%s, %s, roger, return to your parking position.", callsign, self.alias)
      self:TransmissionTower(text, flight, 10)
      
      -- Set flight status to "Taxi Inbound".
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAXIINB)
      
      -- Update menu.
      flight:_UpdateMenu(0.5)
            
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
      local callsign=flight:GetCallsignName()
      
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
        text=text.."no current traffic. You are cleared for takeoff."
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
            
      -- Update menu.
      flight:_UpdateMenu(0.5)
      
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
      local callsign=flight:GetCallsignName()
      
      -- Pilot request for taxi.
      local text=string.format("%s, %s, abort takeoff.", self.alias, callsign)
      self:TransmissionPilot(text, flight)        
    
      if flight:IsParking() then
        text=string.format("%s, %s, affirm, remain on your parking position.", callsign, self.alias)
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.PARKING)
      elseif flight:IsTaxiing() then
        text=string.format("%s, %s, roger, report whether you want to taxi back or takeoff later.", callsign, self.alias)
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAXIOUT)
      else
        env.info(self.lid.."ERROR")
      end
      
      -- Message from tower.
      self:TransmissionTower(text, flight, 10)      
      
      -- Update menu.
      flight:_UpdateMenu(0.5)
      
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

--- Player menu request info.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestParking(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetOpsGroup(groupname) --Ops.FlightGroup#FLIGHTGROUP
  
  if flight then
      
     -- Get callsign.
    local callsign=flight:GetCallsignName()
    
    -- Get player element.
    local player=flight:GetPlayerElement()
    
    --TODO: Check if player has already a parking spot assigned. If so, remind him. Should we stick to it or give him a new position?
    
    --TODO: Check if player is currently parking on a spot. If so, he first needs to leave it.
    
    -- Set terminal type.
    local TerminalType=AIRBASE.TerminalType.FighterAircraft
    if flight.isHelo then
      TerminalType=AIRBASE.TerminalType.HelicopterUsable
    end    
        -- Current coordinate.
    local coord=flight:GetCoordinate(nil, player.name)

    -- Get closest FREE parking spot.    
    local spot=self:GetClosestParkingSpot(coord, TerminalType, AIRBASE.SpotStatus.FREE)
    
    if spot then
      
      -- Message text.
      local text=string.format("%s, your assigned parking position is terminal ID %d. Check the F10 map for details.", callsign, spot.TerminalID)
      
      -- Transmit message.
      self:TransmissionTower(text, flight)
      
      -- Create mark on F10 map.
      --[[
      if spot.Marker then
        spot.Marker:Remove()
      end
      spot.Marker:SetText("Your assigned parking spot!"):ReadWrite():ToGroup(flight.group)
      ]]
      
      -- If player already has a spot.
      if player.parking then
        self:SetParkingFree(player.parking)
      end
      
      -- Reserve parking for player.
      player.parking=spot
      self:SetParkingReserved(spot, player.name)
      
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

    --Closest parking spot.
    local spot=self:GetClosestParkingSpot(coord)
    
    if spot then
    
      -- Get callsign.
      local callsign=flight:GetCallsignName()
      
      -- Distance to parking spot.
      local dist=coord:Get2DDistance(spot.Coordinate)
      
      if dist<20 then
      
        -- Message text.
        local text=string.format("%s, %s, arrived at parking position. Terminal ID %d.", self.alias, callsign, spot.TerminalID)
        
        -- Transmit message.
        self:TransmissionPilot(text, flight)
        
        -- Set flight status to PARKING.
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.PARKING)
        
        -- Create player menu.
        flight:_UpdateMenu(0.5)
        
        -- Create mark on F10 map.
        --[[
        if spot.Marker then
          spot.Marker:Remove()
        end
        spot.Marker:ReadWrite():SetText("Your current parking spot!"):ToGroup(flight.group)
        ]]
            
        -- Set parking of player element.
        player.parking=spot
        self:SetParkingOccupied(spot, player.name)
        
        -- Message text.
        local text=string.format("%s, %s, roger. Enjoy a cool bevarage in the officers' club.", callsign, self.alias)
        
        -- Transmit message.
        self:TransmissionTower(text, flight, 10)
        
      else
      
        -- Message text.
        local text=string.format("%s, %s, arrived at parking position", self.alias, callsign)
        
        -- Transmit message.
        self:TransmissionPilot(text, flight)
        
        -- Message text.
        local text=string.format("%s, %s, you are still %d meters away from the closest parking position. Continue taxiing to a proper spot!", callsign, self.alias, dist)
        
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
  
  --if flight.destination and flight.destination:GetName()==self.airbasename then
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
      
      -- Update menu.
      if not flight.isAI then      
        flight:_UpdateMenu(0.5)
      end
      
    end
  end
  
  --
  self:E(self.lid..string.format("WARNING: Could NOT remove flight group %s from %s queue", flight.groupname, queuename))
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
  
  --TODO: check parking?
  
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
  
  -- Set flight status to LANDING.
  self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.LANDING)
  
  -- Flight is not holding any more.
  flight.Tholding=nil
   
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

  --[[
  local holdingpattern={} --#FLIGHTCONTROL.HoldingPattern
  
  local runway=self:GetActiveRunway()
  
  local hdg=runway.heading+90
  local dx=UTILS.NMToMeters(5)
  local dz=UTILS.NMToMeters(1)
  
  local angels=UTILS.FeetToMeters(math.random(6,10)*1000)
  
  holdingpattern.pos0=runway.position:Translate(dx, hdg):SetAltitude(angels)
  holdingpattern.pos1=holdingpattern.pos0:Translate(dz, runway.heading):SetAltitude(angels)
  
  ]]
  
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Radio Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Radio transmission from tower.
-- @param #FLIGHTCONTROL self
-- @param #string Text The text to transmit.
-- @param Ops.FlightGroup#FLIGHTGROUP Flight The flight.
-- @param #number Delay Delay in seconds before the text is transmitted. Default 0 sec.
function FLIGHTCONTROL:TransmissionTower(Text, Flight, Delay)
  
  -- Tower radio call.
  self.msrsTower:PlayText(Text, Delay)
  
  -- "Subtitle".
  if Flight and not Flight.isAI then
    self:TextMessageToFlight(Text, Flight, 5, false, Delay)
  end
  
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
  
  -- Pilot radio call.
  self.msrsPilot:PlayText(Text, Delay)
  
  -- "Subtitle".
  if Flight and not Flight.isAI then
    self:TextMessageToFlight(Text, Flight, 5, false, Delay)
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

--- Add parking guard in front of a parking aircraft.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Unit#UNIT unit The aircraft.
function FLIGHTCONTROL:SpawnParkingGuard(unit)
  
  if unit and self.parkingGuard then
  
    -- Position of the unit.
    local coordinate=unit:GetCoordinate()

    -- Parking spot.
    local spot=self:GetClosestParkingSpot(coordinate)
    
    -- Current heading of the unit.
    local heading=unit:GetHeading()
    
    -- Length of the unit + 3 meters.
    local size, x, y, z=unit:GetObjectSize()
    
    -- Debug message.
    self:T2(self.lid..string.format("Parking guard for %s: heading=%d, distance x=%.1f m", unit:GetName(), heading, x))
    
    -- Coordinate for the guard.
    local Coordinate=coordinate:Translate(0.75*x+3, heading)
    
    -- Let him face the aircraft.
    local lookat=heading-180
    
    -- Set heading and AI off to save resources.
    self.parkingGuard:InitHeading(lookat)
    
    -- Turn AI Off.
    if self.parkingGuard:IsInstanceOf("SPAWN") then
      self.parkingGuard:InitAIOff()
    end
    
    -- Group that is spawned.
    spot.ParkingGuard=self.parkingGuard:SpawnFromCoordinate(Coordinate)
    
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


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
