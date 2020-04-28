--- **OPS** - (R2.5) - Manage recovery of aircraft at airdromes.
-- 
-- 
--
-- **Main Features:**
--
--    * Manage aircraft recovery.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module OPS.FlightControl
-- @image OPS_FlightControl.png


--- FLIGHTCONTROL class.
-- @type FLIGHTCONTROL
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string theatre The DCS map used in the mission.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string airbasename Name of airbase.
-- @field #number airbasetype Type of airbase.
-- @field Wrapper.Airbase#AIRBASE airbase Airbase object.
-- @field Core.Zone#ZONE zoneAirbase Zone around the airbase.
-- @field #table parking Parking spots table.
-- @field #table runways Runway table.
-- @field #table flights All flights table.
-- @field #table clients Table with all clients spawning at this airbase.
-- @field #table Qinbound Queue of aircraft inbound and traveling to the holding position.
-- @field #table Qholding Queue of aircraft waiting for landing permission.
-- @field #table Qlanding Queue of aircraft currently on final approach.
-- @field #table Qtaxiinb Queue of aircraft taxiing to parking after landing.
-- @field #table Qarrived Queue of aircraft that have arrived at their parking spot after landing.
-- @field #table Qparking Queue of aircraft parking and waiting for taxi & takeoff clearance.
-- @field #table Qtaxiout Queue of aircraft taxiing from parking to runway for takeoff.
-- @field #table Qreadyto Queue of aircraft ready for takeoff. Only human players.
-- @field #table Qtakeoff Queue of aircraft about to takeoff.
-- @field Ops.ATIS#ATIS atis ATIS object.
-- @field #number activerwyno Number of active runway.
-- @field #number atcfreq ATC radio frequency.
-- @field Core.RadioQueue#RADIOQUEUE atcradio ATC radio queue.
-- @field #table playermenu Player Menu.
-- @field #number Nlanding Max number of aircraft groups in the landing pattern.
-- @field #number dTlanding Time interval in seconds between landing clearance.
-- @field #number Nparkingspots Total number of parking spots.
-- @extends Core.Fsm#FSM

--- **Ground Control**: Airliner X, Good news, you are clear to taxi to the active.
--  **Pilot**: Roger, What's the bad news?
--  **Ground Control**: No bad news at the moment, but you probably want to get gone before I find any.
--
-- ===
--
-- ![Banner Image](..\Presentations\FLIGHTCONTROL\FlightControl_Main.jpg)
--
-- # The FLIGHTCONTROL Concept
-- 
-- 
-- 
-- @field #FLIGHTCONTROL
FLIGHTCONTROL = {
  ClassName      = "FLIGHTCONTROL",
  Debug          = false,
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
  Qinbound       =    {},
  Qholding       =    {},
  Qlanding       =    {},
  Qtaxiinb       =    {},  
  Qarrived       =    {},  
  Qparking       =    {},
  Qtaxiout       =    {},
  Qreadyto       =    {},
  Qtakeoff       =    {},  
  atis           =   nil,
  activerwyno    =     1,
  atcfreq        =   nil,
  atcradio       =   nil,
  atcradiounitname = nil,
  playermenu       = nil,
  Nlanding         = nil,
  dTlanding        = nil,
  Nparkingspots    = nil,
}

--- Holding point
-- @type FLIGHTCONTROL.HoldingPoint
-- @field Core.Point#COORDINATE pos0 First poosition of racetrack holding point.
-- @field Core.Point#COORDINATE pos1 Second position of racetrack holding point.
-- @field #number angelsmin Smallest holding altitude in angels.
-- @field #number angelsmax Largest holding alitude in angels.

--- Player menu data.
-- @type FLIGHTCONTROL.PlayerMenu
-- @field Core.Menu#MENU_GROUP root Root menu.
-- @field Core.Menu#MENU_GROUP_COMMAND RequestTaxi Request taxi.

--- Parking spot data.
-- @type FLIGHTCONTROL.ParkingSpot
-- @field #boolean reserved If true, reserved.
-- @field #number markerid ID of the marker.
-- @extends Wrapper.Airbase#AIRBASE.ParkingSpot

--- Parking spot data.
-- @type FLIGHTCONTROL.FlightStatus
-- @field #string INBOUND Flight is inbound.
-- @field #string HOLDING Flight is holding.
-- @field #string LANDING Flight is landing.
-- @field #string TAXIINB Flight is taxiing to parking area.
-- @field #string ARRIVED Flight arrived at parking spot.
-- @field #string TAXIOUT Flight is taxiing to runway for takeoff.
-- @field #string READYTO Flight is ready for takeoff.
-- @field #string TAKEOFF Flight is taking off.
FLIGHTCONTROL.FlightStatus={
  INBOUND="Inbound",
  HOLDING="Holding",
  LANDING="Landing",
  TAXIINB="Taxi Inbound",
  ARRIVED="Arrived",
  PARKING="Parking",
  TAXIOUT="Taxi to runway",
  READYTO="Ready For Takeoff",
  TAKEOFF="Takeoff",
}


--- Runway data.
-- @type FLIGHTCONTROL.Runway
-- @field #number direction Direction of the runway.
-- @field #number length Length of runway in meters.
-- @field #number width Width of runway in meters.
-- @field Core.Point#COORDINATE position Position of runway start.

--- FlightControl class version.
-- @field #string version
FLIGHTCONTROL.version="0.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Accept and forbit parking spots.
-- NOGO: Add FARPS?
-- TODO: Add helos.
-- TODO: Talk me down option.
-- TODO: ATIS option.
-- TODO: ATC voice overs.
-- TODO: Check runways and clean up.
-- DONE: Interface with FLIGHTGROUP.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTCONTROL class object for an associated airbase.
-- @param #FLIGHTCONTROL self
-- @param #string airbasename Name of the airbase.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:New(airbasename)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #FLIGHTCONTROL
  
  -- Try to get the airbase.
  self.airbase=AIRBASE:FindByName(airbasename)
  
  -- Name of the airbase.
  self.airbasename=airbasename  
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTCONTROL %s | ", airbasename)  
  
  -- Check if the airbase exists.
  if not self.airbase then
    self:E(string.format("ERROR: Could not find airbase %s!", tostring(airbasename)))
    return nil
  end
  -- Check if airbase is an airdrome.
  if self.airbase:GetAirbaseCategory()~=Airbase.Category.AIRDROME then
    self:E(string.format("ERROR: Airbase %s is not an AIRDROME! Script does not handle FARPS or ships.", tostring(airbasename)))
    return nil
  end
  

  -- Airbase category airdrome, FARP, SHIP.
  self.airbasetype=self.airbase:GetAirbaseCategory()
  
  -- Current map.
  self.theatre=env.mission.theatre    
  
  -- 5 NM zone around the airbase.
  self.zoneAirbase=ZONE_RADIUS:New("FC", self:GetCoordinate():GetVec2(), UTILS.NMToMeters(5))
  
  -- Defaults
  self:SetLandingMax()
  self:SetLandingInterval()
  
  
  -- Init runways.
  self:_InitRunwayData()
  
  -- Init parking spots.
  self:_InitParkingSpots()  
  
  self.playermenu={}
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",          "*")           -- Update status.

  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  -- Add to data base.
  _DATABASE:AddFlightControl(self)

  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the number of aircraft groups, that are allowed to land simultaniously.
-- @param #FLIGHTCONTROL self
-- @param #number n Max number of aircraft landing simultaniously. Default 2.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetLandingMax(n)

  self.Nlanding=n or 2

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


--- Set runway. This clears all auto generated runways.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.Runway Runway.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetRunway(runway)

  -- Reset table.
  self.runways={}
  
  -- Set runway.
  table.insert(self.runways, runway)

  return self
end

--- Add runway.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.Runway Runway.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:AddRunway(runway)

  -- Set runway.
  table.insert(self.runways, runway)

  return self
end

--- Set active runway number. Counting refers to the position in the table entry.
-- @param #FLIGHTCONTROL self
-- @param #number no Number in the runways table.
-- @return #FLIGHTCONTROL self
function FLIGHTCONTROL:SetActiveRunwayNumber(no)
  self.activerwyno=no
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start FLIGHTCONTROL FSM. Handle events.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStart()

  -- Events are handled my MOOSE.
  self:I(self.lid..string.format("Starting FLIGHTCONTROL v%s for airbase %s of type %d on map %s", FLIGHTCONTROL.version, self.airbasename, self.airbasetype, self.theatre))

  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.EngineStartup)
  self:HandleEvent(EVENTS.Takeoff)
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.EngineShutdown)
  self:HandleEvent(EVENTS.Crash)
  
  self.atcradio=RADIOQUEUE:New(self.atcfreq or 305, nil, string.format("FC %s", self.airbasename))
  self.atcradio:Start(1, 0.1)
  
  -- Init status updates.
  self:__Status(-1)
end

--- Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStatus()

  -- Check status of all registered flights.
  self:_CheckFlights()
  
  -- Check parking spots.
  self:_CheckParking()
  
  -- Check waiting and landing queue.
  self:_CheckQueues()
  
  -- Get runway.
  local runway=self:GetActiveRunway()
    
  local Nflights= self:CountFlights()
  local NQparking=self:CountFlights(FLIGHTCONTROL.FlightStatus.PARKING)
  local NQtaxiout=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIOUT)
  local NQreadyto=self:CountFlights(FLIGHTCONTROL.FlightStatus.READYTO)
  local NQtakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
  local NQinbound=self:CountFlights(FLIGHTCONTROL.FlightStatus.INBOUND)
  local NQholding=self:CountFlights(FLIGHTCONTROL.FlightStatus.HOLDING)
  local NQlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)
  local NQtaxiinb=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIINB)
  local NQarrived=self:CountFlights(FLIGHTCONTROL.FlightStatus.ARRIVED)
  -- =========================================================================================================
  local Nqueues = (NQparking+NQtaxiout+NQreadyto+NQtakeoff) + (NQinbound+NQholding+NQlanding+NQtaxiinb+NQarrived)

  -- Count free parking spots.
  --TODO: get and substract number of reserved parking spots.
  local nfree=self.Nparkingspots-NQarrived-NQparking

  local Nfree=self:CountParking(AIRBASE.SpotStatus.FREE)
  local Noccu=self:CountParking(AIRBASE.SpotStatus.OCCUPIED)
  local Nresv=self:CountParking(AIRBASE.SpotStatus.RESERVED)
  
  if Nfree+Noccu+Nresv~=self.Nparkingspots then
    self:E(self.lid..string.format("WARNING: Number of parking spots does not match! Nfree=%d, Noccu=%d, Nreserved=%d %d != %d total"), Nfree, Noccu, Nresv, self.Nparkingspots)
  end

  -- Info text.
  local text=string.format("State %s - Runway %s - Parking %d/%d/%d of %d - Flights=%s: Qpark=%d Qtxout=%d Qready=%d Qto=%d | Qinbound=%d Qhold=%d Qland=%d Qtxinb=%d Qarr=%d", 
  self:GetState(), runway.idx, Nfree, Noccu, Nresv, self.Nparkingspots, Nflights, NQparking, NQtaxiout, NQreadyto, NQtakeoff, NQinbound, NQholding, NQlanding, NQtaxiinb, NQarrived)
  self:I(self.lid..text)
  
  if Nflights==Nqueues then
    --Check!
  else
    self:E(string.format("WARNING: Number of total flights %d!=%d number of flights in all queues!", Nflights, Nqueues))
  end

  -- Next status update in ~30 seconds.
  self:__Status(-20)
end

--- Start FLIGHTCONTROL FSM. Handle events.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStop()

  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.EngineStartup)
  self:HandleEvent(EVENTS.Takeoff)
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.EngineShutdown)
  self:HandleEvent(EVENTS.Crash)

  self.atcradio:Stop()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for event birth.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventBirth(EventData)
  self:F3({EvendData=EventData})
    
  if EventData and EventData.IniGroupName and EventData.Place and EventData.Place:GetName()==self.airbasename then
  
    self:I(self.lid..string.format("BIRTH: unit  = %s", tostring(EventData.IniUnitName)))
    self:T2(self.lid..string.format("BIRTH: group = %s", tostring(EventData.IniGroupName)))

  
    -- We delay this, to have all elements of the group in the game.
    if EventData.IniUnit:IsAir() then
      self:ScheduleOnce(0.1, self._CreateFlightGroup, self, EventData.IniGroup)
    end
  
  end
  
end

--- Event handler for event land.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventLand(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("LAND: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("LAND: group = %s", tostring(EventData.IniGroupName)))
  
end

--- Event handler for event takeoff.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventTakeoff(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("TAKEOFF: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("TAKEOFF: group = %s", tostring(EventData.IniGroupName)))
  
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
  
  self:I(self.lid..string.format("ENGINESTARTUP: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("ENGINESTARTUP: group = %s", tostring(EventData.IniGroupName)))
    
  -- Unit that took off.
  local unit=EventData.IniUnit

  -- Nil check for unit.
  if not unit then
    return
  end

end

--- Event handler for event engine shutdown.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventEngineShutdown(EventData)
  self:F3({EvendData=EventData})
  
  self:I(self.lid..string.format("ENGINESHUTDOWN: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("ENGINESHUTDOWN: group = %s", tostring(EventData.IniGroupName)))
    
  -- Unit that took off.
  local unit=EventData.IniUnit

  -- Nil check for unit.
  if not unit then
    return
  end
  
end

--- Event handler for event crash.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventCrash(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("CRASH: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("CRASH: group = %s", tostring(EventData.IniGroupName)))
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Queue Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Scan airbase zone.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckQueues()

  -- Print queue.
  if true then
    self:_PrintQueue(self.flights,  "All flights")
  end

  -- Number of holding groups.
  local nholding=self:CountFlights(FLIGHTCONTROL.FlightStatus.HOLDING)
      
  -- Number of groups landing.
  local nlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)

  -- Number of parking groups.
  local nparking=self:CountFlights(FLIGHTCONTROL.FlightStatus.PARKING)
    
  -- Number of groups taking off.
  local ntakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
    

  -- Get next flight in line: either holding or parking.
  local flight, isholding, parking=self:_GetNextFlight()
  

  -- Check if somebody wants something.
  if flight then
      
    if isholding then

      --------------------
      -- Holding flight --
      --------------------

      -- No other flight is taking off and number of landing flights is below threshold.
      if ntakeoff==0 and nlanding<self.Nlanding then

        -- Get interval to last flight that got landing clearance.
        local dTlanding=99999
        if self.Tlanding then
          dTlanding=timer.getAbsTime()-self.Tlanding
        end
      
        if parking and dTlanding>=self.dTlanding then
                
          -- Message.
          local text=string.format("Flight %s, you are cleared to land.", flight.groupname)
          MESSAGE:New(text, 5, "FLIGHTCONTROL"):ToAll()
    
          -- Give AI the landing signal.
          -- TODO: Humans have to confirm via F10 menu.
          if flight.ai then
            self:_LandAI(flight, parking)
          end
        
          -- Set time last flight got landing clearance.  
          self.Tlanding=timer.getAbsTime()
          
        end
      else
        self:I(self.lid..string.format("FYI: Landing clearance for flight %s denied as other flights are taking off (N=%d) or max. landing reached (N=%d/%d).", flight.groupname, ntakeoff, nlanding, self.Nlanding))
      end
    
    else
    
      --------------------
      -- Takeoff flight --
      --------------------    
      
      -- No other flight is taking of or landing.
      if ntakeoff==0 and nlanding==0 then
     
        -- Check if flight is AI. Humans have to request taxi via F10 menu.
        if flight.ai then
        
          -- NOTE that AI will start taxiing once they started their engine.
        
          -- Message.
          local text=string.format("Flight %s, you are cleared to taxi to runway.", flight.groupname)
          self:I(self.lid..text)
          MESSAGE:New(text, 5, "FLIGHTCONTROL"):ToAll()
          
          -- Start uncontrolled aircraft.
          -- TODO: handle case with engines hot. That does not trigger a ENGINE_START event. More a FLIGHTGROUP issue.
          flight.group:StartUncontrolled()
          
          -- Add flight to takeoff queue.
          self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAKEOFF)
          
        else
          local text=string.format("HUMAN Flight %s, you are cleared for takeoff.", flight.groupname)
          self:I(self.lid..text)
          MESSAGE:New(text, 5, "FLIGHTCONTROL"):ToAll()
          
        end
      else
       self:I(self.lid..string.format("FYI: Take of for flight %s denied as other flights are taking off (N=%d) or landing (N=%d).", flight.groupname, ntakeoff, nlanding))
      end
    end
  else
    self:I(self.lid..string.format("FYI: No flight in queue for takeoff or landing."))
  end
  
end

--- Get next flight in line, either waiting for landing or waiting for takeoff.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
-- @return #boolean If true, flight is holding and waiting for landing, if false, flight is parking and waiting for takeoff.
-- @return #table Parking data for holding flights or nil.
function FLIGHTCONTROL:_GetNextFlight()

  local flightholding=self:_GetNextFightHolding()
  local flightparking=self:_GetNextFightParking()
  
  -- If no flight is waiting for landing just return the takeoff flight or nil.
  if not flightholding then
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
      self:E(string.format("WARNING: No flight parking but no parking spots! nP=%d nH=%d", #parking, nH))
      return nil, nil, nil
    end
  end
  

  
  -- We got flights waiting for landing and for takeoff.
  if flightholding and flightparking then
  
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
       
    -- Return the flight which is waiting longer.
    if flightholding.Tholding>flightparking.Tparking and parking then
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
    return Qholding[1]
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
    
  return Qholding[1]
end


--- Get next flight waiting for taxi and takeoff clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightParking()

  local Qtaxiout=self:GetFlights(FLIGHTCONTROL.FlightStatus.TAXIOUT)

  -- First check human players.
  if #Qtaxiout>0 then
    -- TODO: Could be sorted by distance to active runway! Take the runway spawn point for distance measure.
    
    -- First come, first serve.
    return Qtaxiout[1]
  end
  
  local Qparking=self:GetFlights(FLIGHTCONTROL.FlightStatus.PARKING)

  -- Check special cases where only up to one flight is waiting for takeoff.
  if #Qparking==0 then
    return nil
  elseif #Qparking==1 then
    return Qparking[1]
  end

  -- Sort flights parking time.
  local function _sortByTparking(a, b)
    local flightA=a --Ops.FlightGroup#FLIGHTGROUP
    local flightB=b --Ops.FlightGroup#FLIGHTGROUP
    return flightA.Tparking<flightB.Tparking -- Tholding is the abs. timestamp. So the one with the smallest time is holding the longest.
  end

  -- Return flight waiting longest.
  table.sort(Qparking, _sortByTparking)
  
  for i,_flight in pairs(Qparking) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    env.info(string.format("%d %s %.1f", i, flight.groupname, flight.Tparking))
  end
  
  return Qparking[1]
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
      local ai=tostring(flight.ai)
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
      
      
      local nunits=flight.nunits or 1
      
      -- Main info.
      text=text..string.format("\n[%d] %s (%s*%d): status=%s, ai=%s, fuel=%d, holding=%s, parking=%s",
                                 i, flight.groupname, actype, nunits, flight:GetState(), ai, fuel, holding, parking)

      -- Elements info.                                 
      for j,_element in pairs(flight.elements) do
        local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
        local life=element.unit:GetLife()
        local life0=element.unit:GetLife0()
        text=text..string.format("\n  (%d) %s (%s): status=%s, ai=%s, airborne=%s life=%.1f/%.1f",
        j, tostring(element.modex), element.name, tostring(element.status), tostring(element.ai), tostring(element.unit:InAir()), life, life0)
      end
    end
  end
  
  -- Display text.
  self:I(self.lid..text)
  
  return text
end

--- Remove a flight group from a queue.
-- @param #FLIGHTCONTROL self
-- @param #table queue The queue from which the group will be removed.
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group that will be removed from queue.
-- @param #string queuename Name of the queue.
-- @return #boolean True, flight was in Queue and removed. False otherwise.
-- @return #number Table index of removed queue element or nil.
function FLIGHTCONTROL:_RemoveFlightFromQueue(queue, flight, queuename)

  queuename=queuename or "unknown"

  -- Loop over all flights in group.
  for i,_flight in pairs(queue) do
    local qflight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
    -- Check for name.
    if qflight.groupname==flight.groupname then
      self:I(self.lid..string.format("Removing flight group %s from %s queue.", flight.groupname, queuename))
      table.remove(queue, i)
      
      if not flight.ai then      
        flight:_UpdateMenu()
      end
      
      return true, i
    end
  end
  
  self:I(self.lid..string.format("Could NOT remove flight group %s from %s queue.", flight.groupname, queuename))
  return false, nil
end


--- Set flight status.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param #string status New status.
function FLIGHTCONTROL:SetFlightStatus(flight, status)

  flight.controlstatus=status

end

--- Get flight status.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #string status New status.
function FLIGHTCONTROL:GetFlightStatus(flight)

  if flight then
    return flight.controlstatus or "unkonwn"
  end
  
  return "unknown"
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
-- @param #string Status Return only flights in this status.
-- @return #table Table of flights.
function FLIGHTCONTROL:GetFlights(Status)

  if Status then
  
    local flights={}
  
    for _,_flight in pairs(self.flights) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
      
      local status=self:GetFlightStatus(flight, Status)
      
      if status==Status then
        table.insert(flights, flight)
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
-- @return #number 
function FLIGHTCONTROL:CountFlights(Status)
  
  if Status then
  
    local flights=self:GetFlights(Status)
    
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
    
    -- Set spot to occupied.
    if spot.Free then
      self:SetParkingFree(spot)
    else
      self:SetParkingOccupied(spot, "unknown")
    end
    
    --TODO: scan spot for objects.
    
    -- Increase counter
    self.Nparkingspots=self.Nparkingspots+1
  end
  
end

--- Get parking spot by its Terminal ID.
-- @param #FLIGHTCONTROL self
-- @param #number TerminalID
-- @return Wrapper.Airbase#AIRBASE.ParkingSpot Parking spot data table.
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

--- Get free parking spots.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot The parking spot data table.
function FLIGHTCONTROL:UpdateParkingMarker(spot)

  local spot=self:GetParkingSpotByID(spot.TerminalID)
  
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
    
      spot.Marker:UpdateText(text)
      
    else
    
      spot.Marker=MARKER:New(spot.Coordinate, text):ToAll(Delay)
    
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
-- @param Core.Point#COORDINATE coordinate Reference coordinate.
-- @param #number terminaltype (Optional) Check only this terminal type.
-- @param #boolean free (Optional) If true, check only free spots.
-- @return Wrapper.Airbase#AIRBASE.ParkingSpot Closest parking spot.
function FLIGHTCONTROL:GetClosestParkingSpot(coordinate, terminaltype, free)

  local distmin=math.huge
  local spotmin=nil
  
  for TerminalID, Spot in pairs(self.parking) do
    local spot=Spot --Wrapper.Airbase#AIRBASE.ParkingSpot
    
    if (not free) or (free==true and not (self:IsParkingReserved(spot) or self:IsParkingOccupied(spot))) then 
      if terminaltype==nil or terminaltype==spot.TerminalType then
      
        -- Get distance from coordinate to spot.
        local dist=coordinate:Get2DDistance(spot.Coordinate)
        
        -- Check if distance is smaller.
        if dist<distmin then
          distmin=dist
          spotmin=spot
        end
        
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
-- Human Player Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param #table atcmenu ATC root menu table.
function FLIGHTCONTROL:_CreatePlayerMenu(flight, atcmenu)
  
  local group=flight.group
  local groupname=flight.groupname
  local gid=group:GetID()
  
  self:I(self.lid..string.format("Creating ATC player menu for flight group %s (ID=%d)", tostring(flight.groupname), gid))  
  
  
  local airbasename=self.airbasename
  local Tag=airbasename
  local Tnow=timer.getTime()
   
  atcmenu[airbasename] = atcmenu[airbasename] or {}
  
  -- Airbase root menu.
  atcmenu[airbasename].root = MENU_GROUP_DELAYED:New(group, airbasename, atcmenu.root):SetTime(Tnow):SetTag(Tag)
  
  local rootmenu=atcmenu[airbasename].root --Core.Menu#MENU_GROUP_DELAYED

  -- Some info.
  local helpmenu=MENU_GROUP_DELAYED:New(group, "Help",  rootmenu):SetTime(Tnow):SetTag(Tag)

  -- Some info.
  local infomenu=MENU_GROUP_DELAYED:New(group, "Info",  rootmenu):SetTime(Tnow):SetTag(Tag)
  MENU_GROUP_COMMAND_DELAYED:New(group, "Airbase", infomenu, self._PlayerRequestInfo,       self, groupname):SetTime(Tnow):SetTag(Tag)
  MENU_GROUP_COMMAND_DELAYED:New(group, "Queues",  infomenu, self._PlayerRequestInfoQueues, self, groupname):SetTime(Tnow):SetTag(Tag)
  MENU_GROUP_COMMAND_DELAYED:New(group, "ATIS",    infomenu, self._PlayerRequestInfoATIS,   self, groupname):SetTime(Tnow):SetTag(Tag)

  -- Root Commands  
  if flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename then
    if flight:IsParking() then
      MENU_GROUP_COMMAND_DELAYED:New(group, "Request Taxi",    rootmenu, self._PlayerRequestTaxi,    self, groupname):SetTime(Tnow):SetTag(Tag)
    elseif flight:IsTaxiing() then
      MENU_GROUP_COMMAND_DELAYED:New(group, "Request Takeoff", rootmenu, self._PlayerRequestTakeoff, self, groupname):SetTime(Tnow):SetTag(Tag)
      MENU_GROUP_COMMAND_DELAYED:New(group, "Abort Takeoff",   rootmenu, self._PlayerAbortTakeoff,   self, groupname):SetTime(Tnow):SetTag(Tag)
    elseif flight:IsAirborne() then
    end
  
    if flight:IsInbound() or flight:IsHolding() or flight:IsLanding() or flight:IsLanded() or true then
      MENU_GROUP_COMMAND_DELAYED:New(group, "Request Parking", rootmenu, self._PlayerRequestParking, self, groupname):SetTime(Tnow):SetTag(Tag)
    end
  else
    if flight:IsAirborne() then
      if self:GetFlightStatus(flight)==FLIGHTCONTROL.FlightStatus.INBOUND then
        MENU_GROUP_COMMAND_DELAYED:New(group, "Holding", rootmenu, self._PlayerInbound, self, groupname):SetTime(Tnow):SetTag(Tag)
        
      else
        MENU_GROUP_COMMAND_DELAYED:New(group, "Inbound", rootmenu, self._PlayerHolding, self, groupname):SetTime(Tnow):SetTag(Tag)
      end
    end  
  end
  
  if flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename then
    MENU_GROUP_COMMAND_DELAYED:New(group, "My Status",       rootmenu, self._PlayerMyStatus,       self, groupname):SetTime(Tnow):SetTag(Tag)
  end

  -- Reset the menu.
  rootmenu:Remove(Tnow, Tag)
  rootmenu:Set()  

end

--- Player menu request info.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestParking(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    local group=flight:GetGroup()
    local coord=flight:GetGroup():GetCoordinate()

    --TODO: terminal type for helos!    
    local spot=self:GetClosestParkingSpot(coord, AIRBASE.TerminalType.FighterAircraft, true)
    
    --TODO: voice over.
    local text=string.format("Flight XYZ, tower, your assigned parking position is terminal ID %d.\nCheck your F10 map for details.", spot.TerminalID)
    MESSAGE:New(text, 10, "FLIGHCONTROL", true):ToAll()
    
    -- Create mark on F10 map.
    if spot.MarkerID then
      coord:RemoveMark(spot.MarkerID)
    end
    spot.MarkerID=spot.Coordinate:MarkToGroup("Your assigned parking spot!", group)
        
    -- TODO: get element of human player.
    local element=flight.elements[1] --Ops.FlightGroup#FLIGHTGROUP.Element    
    element.parking=spot
    
    -- TODO: what about AI wingmen? I guess there is no way to set parking for those, right?!
  end
  
end

--- Player menu request info.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestInfo(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    
  
  end
  
end


--- Player menu request info.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestInfo(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    --
    local text=string.format("Airbase %s Status:", self.airbasename)
    text=text..string.format("\nFlights %d", #self.flights)
    text=text..string.format("\nQinbound %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.INBOUND))
    text=text..string.format("\nQholding %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.HOLDING))
    text=text..string.format("\nQlanding %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING))
    text=text..string.format("\nQtaxiInb %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIINB))
    text=text..string.format("\nQarrived %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.ARRIVED))
    text=text..string.format("\nQparking %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.PARKING))
    text=text..string.format("\nQtaxiOut %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.TAXIOUT))
    text=text..string.format("\nQreadiTO %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.READYTO))    
    text=text..string.format("\nQtakeoff %d", self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF))
    text=text..string.format("\nRunway %s", self:GetActiveRunwayText())
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

    MESSAGE:New(text, 5):ToGroup(flight.group)
  
  else
    MESSAGE:New(string.format("Cannot find flight group %s.", tostring(groupname)), 5):ToAll()
  end
  
end

--- Player calls inbound.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerInbound(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
      
    if flight:IsAirborne() then

      if flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename then
        -- Nothing to do as this flight has already the right flightcontrol.
      else
      
        -- Set FC controlling this flight.
        flight:SetFlightControl(self)
      
      end    

      -- Add flight to inbound queue.
      self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.INBOUND)

      local text=string.format("You have been added to the inbound queue!\nFly heading XYZ for ABC and report status when entering the holding pattern")
      MESSAGE:New(text, 5):ToGroup(flight.group)
      
    else
      -- Error you are not airborne!
      local text=string.format("Negative, you must be AIRBORNE to call INBOUND!")
      MESSAGE:New(text, 5):ToGroup(flight.group)      
    end
      
  else
    MESSAGE:New(string.format("Cannot find flight group %s.", tostring(groupname)), 5):ToAll()
  end
  
end

--- Player calls holding.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerHolding(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
      
    if flight:IsAirborne() then

      if flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename then
        
        --TODO: create holding zone and check inside zone.
        -- Error you are not airborne!
        local text=string.format("Roger, you are added to the holding queue!")
        MESSAGE:New(text, 5):ToGroup(flight.group)              

        -- Call holding event.        
        flight:Holding()
        
      else
      
        -- Error you are not airborne!
        local text=string.format("Negative, you are not controlled by us!")
        MESSAGE:New(text, 5):ToGroup(flight.group)              
      
      end
    else
      -- Error you are not airborne!
      local text=string.format("Negative, you must be AIRBORNE to call HOLDING!")
      MESSAGE:New(text, 5):ToGroup(flight.group)              
    end
  else
  end
end

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerMyStatus(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    local text=string.format("My Status:")
    text=text..string.format("\nFlight control: %s", tostring(flight.flightcontrol and flight.flightcontrol.airbasename or "N/A"))
    text=text..string.format("\nFlight status: %s", tostring(flight:GetState()))

    MESSAGE:New(text, 5):ToGroup(flight.group)
  
  else
    MESSAGE:New(string.format("Cannot find flight group %s.", tostring(groupname)), 5):ToAll()
  end
  
end

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestTaxi(groupname)

  MESSAGE:New("Request taxi to runway", 5):ToAll()
  
    
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
    
    if flight:IsParking() then
    
      local runway=self:GetActiveRunwayText()
    
      MESSAGE:New(string.format("You are cleared to taxi to runway %s", runway), 5):ToAll()
      
      for _,_element in pairs(flight.elements) do
        local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
        flight:ElementTaxiing(element)
      end
      
    else
      MESSAGE:New(string.format("Negative, you must be PARKING to request TAXI!"), 5):ToAll()
    end
    
  else
    MESSAGE:New(string.format("Could not clear group %s for taxi!", groupname), 5):ToAll()
  end  

end

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestTakeoff(groupname)

  MESSAGE:New("Request takeoff", 5):ToAll()
      
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    if flight:IsTaxiing() then
    
      local Nlanding=self:CountFlights(FLIGHTCONTROL.FlightStatus.LANDING)
      local Ntakeoff=self:CountFlights(FLIGHTCONTROL.FlightStatus.TAKEOFF)
    
      if Nlanding==0 and Ntakeoff==0 then
        MESSAGE:New("You are cleared for takeoff as there is no one else landing or queueing for takeoff", 5):ToAll()
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.TAKEOFF)
      elseif Nlanding>0 then
        MESSAGE:New("Negative ghostrider, other flights are currently landing. Talk to you soon.", 5):ToAll()
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTO)
      elseif Ntakeoff>0 then
        MESSAGE:New("Negative ghostrider, other flights are ahead of you. Talk to you soon.", 5):ToAll()
        self:SetFlightStatus(flight, FLIGHTCONTROL.FlightStatus.READYTO)
      end
      
      
    
    else
      MESSAGE:New(string.format("Negative, you must request TAXI before you can request TAKEOFF!"), 5):ToAll()  
    end
  end
  
end

--- Player wants to abort takeoff.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerAbortTakeoff(groupname)

  MESSAGE:New("Abort takeoff", 5):ToAll()
      
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    if self:GetFlightStatus(flight)==FLIGHTCONTROL.FlightStatus.TAKEOFF then
    
    
      MESSAGE:New("Afirm, You are removed from takeoff queue", 5):ToAll()      
      
      --TODO: what now? taxi inbound? or just another later attempt to takeoff.
      self:SetFlightStatus(flight,FLIGHTCONTROL.FlightStatus.READYTO)
      
      
    else
      MESSAGE:New("Negative, You are NOT in the takeoff queue", 5):ToAll()
    end
  
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
  self:I(self.lid..string.format("Creating new flight for group %s of aircraft type %s.", group:GetName(), group:GetTypeName()))
  
  -- Get flightgroup from data base.
  local flight=_DATABASE:GetFlightGroup(group:GetName())
  
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
-- @param Ops.FlightGroup#FLIGHTGROUP flight The flight to be removed.
function FLIGHTCONTROL:_RemoveFlight(flight)

  self:_RemoveFlightFromQueue(self.flights,  flight, "flights")

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
-- @return #FLIGHTCONTROL.FlightElement Element of the flight or nil.
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
        local element=_element --#FLIGHTCONTROL.FlightElement
        
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
      self:I(self.lid..string.format("Removing DEAD flight %s", tostring(flight.groupname)))
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
  self:I(self.lid..string.format("Landing AI flight %s.", flight.groupname))
  
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
        
        local text=string.format("FF Reserving parking spot %d for unit %s", spot.TerminalID, tostring(unit.name))
        self:I(self.lid..text)
        
        -- Set parking to RESERVED.
        self:SetParkingReserved(spot, element.name)
        
      else
        env.info("FF error could not get element to assign parking!")      
      end
    end
         
    -- Debug message.
    MESSAGE:New(string.format("Respawning group %s", flight.groupname)):ToAll()
  
    --Respawn the group.
    flight:Respawn(Template)
    
  else
       
    -- Give signal to land.
    flight:ClearToLand()
    
  end
  
end

--- Get holding point.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #FLIGHTCONTROL.HoldingPoint Holding point.
function FLIGHTCONTROL:_GetHoldingpoint(flight)

  local holdingpoint={} --#FLIGHTCONTROL.HoldingPoint
  
  local runway=self:GetActiveRunway()
  
  local hdg=runway.heading+90
  local dx=UTILS.NMToMeters(5)
  local dz=UTILS.NMToMeters(1)
  
  local angels=UTILS.FeetToMeters(math.random(6,10)*1000)
  
  holdingpoint.pos0=runway.position:Translate(dx, hdg):SetAltitude(angels)
  holdingpoint.pos1=holdingpoint.pos0:Translate(dz, runway.heading):SetAltitude(angels)

  return holdingpoint
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
