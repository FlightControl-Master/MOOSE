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
-- @field #table Qwaiting Queue of aircraft waiting for landing permission.
-- @field #table Qlanding Queue of aircraft currently on final approach.
-- @field #table Qtakeoff Queue of aircraft about to takeoff.
-- @field #table QtaxiInb Queue of aircraft taxiing to parking after landing.
-- @field #table Qparking Queue of aircraft parking.
-- @field Ops.ATIS#ATIS atis ATIS object.
-- @field #number activerwyno Number of active runway.
-- @field #number atcfreq ATC radio frequency.
-- @field Core.RadioQueue#RADIOQUEUE atcradio ATC radio queue.
-- @field #table playermenu Player Menu.
-- @field #number Nlading Max number of aircraft groups in the landing pattern.
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
  Qwaiting       =    {},
  Qlanding       =    {},
  Qtakeoff       =    {},
  Qparking       =    {},
  QtaxiInb       =    {},
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

--- Runway data.
-- @type FLIGHTCONTROL.Runway
-- @field #number direction Direction of the runway.
-- @field #number length Length of runway in meters.
-- @field #number width Width of runway in meters.
-- @field Core.Point#COORDINATE position Position of runway start.

--- FlightControl class version.
-- @field #string version
FLIGHTCONTROL.version="0.1.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Add FARPS?
-- TODO: Add helos.
-- TODO: Take me down option.
-- TODO: ATIS option.
-- TODO: ATC voice overs.
-- TODO: Check runways and clean up.
-- TODO: Interface with FLIGHTGROUP.

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
  
  -- Name of the airbase.
  self.airbasename=airbasename
  
  -- Airbase category airdrome, FARP, SHIP.
  self.airbasetype=self.airbase:GetAirbaseCategory()
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTCONTROL %s | ", airbasename)
  
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

  -- Scan airbase for units, statics, and scenery.
  --self:_CheckAirbase()

  -- Update parking spots.
  --self:_UpdateParkingSpots()
  
  -- Check waiting and landing queue.
  self:_CheckQueues()
  
  -- Get runway.
  local runway=self:GetActiveRunway()
  
  -- Get free parking spots.
  --local nfree=self:_GetFreeParkingSpots()
  local nfree=self.Nparkingspots

  -- Info text.
  local text=string.format("State %s - Runway %s - Parking %d/%d - Flights=%s: Qpark=%d Qtakeoff=%d Qland=%d Qhold=%d", 
  self:GetState(), runway.idx, nfree, self.Nparkingspots, #self.flights, #self.Qparking, #self.Qtakeoff, #self.Qlanding, #self.Qwaiting)
  self:I(self.lid..text)

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
    self:ScheduleOnce(0.1, self._CreateFlightGroup, self, EventData.IniGroup)
  
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

  -- Print queues
  if false then
    self:_PrintQueue(self.flights,  "All flights")
    self:_PrintQueue(self.Qparking, "Parking")
    self:_PrintQueue(self.Qtakeoff, "Takeoff")
    self:_PrintQueue(self.Qwaiting, "Holding")
    self:_PrintQueue(self.Qlanding, "Landing")
  end

  -- Number of holding groups.
  local nholding=#self.Qwaiting
      
  -- Number of groups landing.
  local nlanding=#self.Qlanding

  -- Number of parking groups.
  local nparking=#self.Qparking
    
  -- Number of groups taking off.
  local ntakeoff=#self.Qtakeoff
    

  -- Get next flight in line: either holding or parking.
  local flight, isholding, parking=self:_GetNextFlight()
  

  -- Check if somebody wants something.
  if flight and ntakeoff==0 and nlanding<self.Nlanding then
      
    if isholding then

      --------------------
      -- Holding flight --
      --------------------

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
          flight:FlightLanding()
          self:_LandAI(flight, parking)
        end
      
        -- Set time last flight got landing clearance.  
        self.Tlanding=timer.getAbsTime()
        
      end
    
    else
    
      --------------------
      -- Takeoff flight --
      --------------------
     
      -- Check if flight is AI. Humans have to request taxi via F10 menu.
      if flight.ai then       
      
        -- Message.
        local text=string.format("Flight %s, you are cleared to taxi to runway.", flight.groupname)
        self:I(self.lid..text)
        MESSAGE:New(text, 5, "FLIGHTCONTROL"):ToAll()
        
        -- Start uncontrolled aircraft.
        -- TODO: handle case with engines hot. That does not trigger a ENGINE_START event. More a FLIGHTGROUP issue.
        flight.group:StartUncontrolled()
        
        
        -- TODO: is this really necessary here?
        flight:__UpdateRoute(-1)
        
        env.info("FF remove flight from parking queue - if possible.")
        self:_RemoveFlightFromQueue(self.Qparking, flight, "parking")
        
        self:_AddFlightToTakeoffQueue(flight)
        
      end
    
    end
    
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

  if #self.Qwaiting==0 then
    return nil
  elseif #self.Qwaiting==1 then
    return self.Qwaiting[1]
  end

  -- Sort flights by low fuel
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
    return flightA.Tholding<flightB.Tholding
  end


  -- Sort flights by fuel.
  table.sort(self.Qwaiting, _sortByFuel)
  
  -- Loop over all marshal flights.
  for _,_flight in pairs(self.Qwaiting) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
    -- Return flight that is lowest on fuel.
    if flight.fuellow then  
      return flight
    end
    
  end
  

  -- Return flight waiting longest.
  table.sort(self.Qwaiting, _sortByTholding)
    
  return self.Qwaiting[1]
end


--- Get next flight waiting for taxi and takeoff clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightParking()

  if #self.Qparking==0 then
    return nil
  elseif #self.Qparking==1 then
    return self.Qparking[1]
  end

  -- Sort flights parking time.
  local function _sortByTparking(a, b)
    local flightA=a --Ops.FlightGroup#FLIGHTGROUP
    local flightB=b --Ops.FlightGroup#FLIGHTGROUP
    return flightA.Tparking<flightB.Tparking
  end

  -- Return flight waiting longest.
  table.sort(self.Qparking, _sortByTparking)  
  return self.Qparking[1]
end

--- Print queue.
-- @param #FLIGHTCONTROL self
-- @param #table queue Queue to print.
-- @param #string name Queue name.
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
  self:T(self.lid..text)
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
      return true, i
    end
  end
  
  self:I(self.lid..string.format("Could NOT remove flight group %s from %s queue.", flight.groupname, queuename))
  return false, nil
end

--- Add flight to holding queue.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #boolean If true, flight was added. False otherwise.
function FLIGHTCONTROL:_AddFlightToHoldingQueue(flight)

  -- Check if already in queue.
  if self:_InQueue(self.Qwaiting, flight.group) then
    return false
  end

  -- Add flight to table.
  table.insert(self.Qwaiting, flight)
  
  -- Flight is not holding any more.
  flight.Tholding=timer.getAbsTime()
  
  return true
end


--- Add flight to landing queue and set recovered to false for all elements of the flight and its section members.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #boolean If true, flight was added. False otherwise.
function FLIGHTCONTROL:_AddFlightToLandingQueue(flight)

  -- Check if already in queue.
  if self:_InQueue(self.Qlanding, flight.group) then
    return false
  end

  -- Add flight to table.
  table.insert(self.Qlanding, flight)
  
  -- Flight is not holding any more.
  flight.Tholding=nil
  
  return true
end

--- Add flight to parking queue.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #boolean If true, flight was added. False otherwise.
function FLIGHTCONTROL:_AddFlightToParkingQueue(flight)

  -- Check if already in queue.
  if self:_InQueue(self.Qparking, flight.group) then
    return false
  end

  -- Add flight to table.
  table.insert(self.Qparking, flight)
  
  -- Flight is not holding any more.
  flight.Tparking=timer.getAbsTime()
  
  return true
end

--- Add flight to takeoff queue.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @return #boolean If true, flight was added. False otherwise.
function FLIGHTCONTROL:_AddFlightToTakeoffQueue(flight)

  -- Check if already in queue.
  if self:_InQueue(self.Qtakeoff, flight.group) then
    return false
  end

  -- Add flight to table.
  table.insert(self.Qtakeoff, flight)
  
  -- New time stamp for time waiting for takeoff.
  flight.Tparking=nil
  
  return true
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
    
    local parking=spot --#FLIGHTCONTROL.ParkingSpot
    parking.reserved="none"
    
    -- Mark position.
    local text=string.format("ID=%d, Terminal=%d, Free=%s, Reserved=%s, Dist=%.1f", parking.TerminalID, parking.TerminalType, tostring(parking.Free), tostring(parking.reserved), parking.DistToRwy)
    
    -- Add to table.
    self.parking[parking.TerminalID]=parking
    
    self.Nparkingspots=self.Nparkingspots+1
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
    local parking=_parking --#FLIGHTCONTROL.ParkingSpot
    
    if parking.Free and parking.TOAC==false and parking.reserved=="none" then
      if terminal==nil or terminal==parking.terminal then
        n=n+1
        table.insert(freespots, parking)
      end
    end
  end
  
  return n,freespots
end

--- Update parking spots.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_UpdateParkingSpots()

  -- Parking spots of airbase.
  local parkingdata=self.airbase:GetParkingSpotsTable()
  
  for _,_parking in pairs(self.parking) do
    local parking=_parking --#FLIGHTCONTROL.ParkingSpot
    if parking.markerid then
      parking.Coordinate:RemoveMark(parking.markerid)
      parking.markerid=nil    
    end
  end
  
  -- Loop over all spots.
  local message="Parking Spots:"    
  for _,_spot in pairs(parkingdata) do
    local spot=_spot --Wrapper.Airbase#AIRBASE.ParkingSpot
    
    -- Parking.
    local parking=self.parking[spot.TerminalID] --#FLIGHTCONTROL.ParkingSpot
    
    -- Check if any known flight has reserved this spot.
    local reserved=self:IsParkingReserved(spot)

    -- Message text.    
    --local text=string.format("ID=%03d, Terminal=%03d, Free=%s, TOAC=%s, reserved=%s", parking.TerminalID, parking.TerminalType, tostring(parking.Free), tostring(parking.TOAC), tostring(reserved))
    local text=string.format("ID=%03d, Terminal=%03d, Free=%s, TOAC=%s, reserved=%s", spot.TerminalID, spot.TerminalType, tostring(spot.Free), tostring(spot.TOAC), tostring(reserved))
    
    -- Place marker on non-free spots.
    if parking.Free==false or parking.TOAC or reserved~=nil then
      parking.markerid=parking.Coordinate:MarkToAll(text)
      message=message.."\n"..text
    end
    
  end
  
  -- Debug message.
  self:I(self.lid..message)
end

--- Check if a parking spot is reserved by a flight group.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot Parking spot to check.
-- @return #string Name of element or nil.
function FLIGHTCONTROL:IsParkingReserved(spot)

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

  -- Commands
  MENU_GROUP_COMMAND_DELAYED:New(group, "Request Info",    rootmenu, self._PlayerRequestInfo,    self, groupname):SetTime(Tnow):SetTag(Tag)
  if flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename then
  MENU_GROUP_COMMAND_DELAYED:New(group, "Request Taxi",    rootmenu, self._PlayerRequestTaxi,    self, groupname):SetTime(Tnow):SetTag(Tag)
  MENU_GROUP_COMMAND_DELAYED:New(group, "Request Takeoff", rootmenu, self._PlayerRequestTakeoff, self, groupname):SetTime(Tnow):SetTag(Tag)
  MENU_GROUP_COMMAND_DELAYED:New(group, "Request Parking", rootmenu, self._PlayerRequestParking, self, groupname):SetTime(Tnow):SetTag(Tag)
  end
  MENU_GROUP_COMMAND_DELAYED:New(group, "Inbound",         rootmenu, self._PlayerInbound,        self, groupname):SetTime(Tnow):SetTag(Tag)
  if flight.flightcontrol and flight.flightcontrol.airbasename==self.airbasename then
  MENU_GROUP_COMMAND_DELAYED:New(group, "My Status",       rootmenu, self._PlayerMyStatus,       self, groupname):SetTime(Tnow):SetTag(Tag)
  end

  
  rootmenu:Remove(Tnow, Tag)
  rootmenu:Set()  
  
  --[[
  atcmenu[airbasename].MyStatus       = MENU_GROUP_COMMAND:New(group, "My Status",       atcmenu[airbasename].root, self._PlayerMyStatus,       self, groupname)
  atcmenu[airbasename].RequestTaxi    = MENU_GROUP_COMMAND:New(group, "Request Taxi",    atcmenu[airbasename].root, self._PlayerRequestTaxi,    self, groupname)
  atcmenu[airbasename].RequestTakeoff = MENU_GROUP_COMMAND:New(group, "Request Takeoff", atcmenu[airbasename].root, self._PlayerRequestTakeoff, self, groupname)
  atcmenu[airbasename].RequestParking = MENU_GROUP_COMMAND:New(group, "Request Parking", atcmenu[airbasename].root, self._PlayerRequestParking, self, groupname)  
  atcmenu[airbasename].Inbound        = MENU_GROUP_COMMAND:New(group, "Inbound",         atcmenu[airbasename].root, self._PlayerInbound,        self, groupname)
  ]]
end

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerRequestInfo(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    --
    local text=string.format("Airbase %s Status:", self.airbasename)
    text=text..string.format("\nFlights %d", #self.flights)
    text=text..string.format("\nQlanding %d", #self.Qlanding)
    text=text..string.format("\nQholding %d", #self.Qwaiting)
    text=text..string.format("\nQparking %d", #self.Qparking)
    text=text..string.format("\nQtakeoff %d", #self.Qtakeoff)
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

      -- TODO: Better check in holding zone and then add to queue.
      self:_AddFlightToHoldingQueue(flight)

      local text=string.format("You have been added to the holding queue!")
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

--- Create player menu.
-- @param #FLIGHTCONTROL self
-- @param #string groupname Name of the flight group.
function FLIGHTCONTROL:_PlayerMyStatus(groupname)

  -- Get flight group.
  local flight=_DATABASE:GetFlightGroup(groupname)
  
  if flight then
  
    local text=string.format("My Status:\n")
    text=text..string.format("Flight status: %s", tostring(flight:GetState()))

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
    
    local runway=self:GetActiveRunwayText()
  
    MESSAGE:New(string.format("You are cleared to taxi to runway %s", runway), 5):ToAll()
    
    for _,_element in pairs(flight.elements) do
      local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
      flight:ElementTaxiing(element)
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
    
      if #self.Qlanding==0 and self.Qtakeoff==0 then
        MESSAGE:New("You are cleared for takeoff as there is no one else landing or queueing for takeoff", 5):ToAll()
      elseif #self.Qlanding>0 then
        MESSAGE:New("Negative ghostrider, other flights are currently landing.", 5):ToAll()
      elseif #self.Qtakeoff>0 then
        MESSAGE:New("Negative ghostrider, other flights are ahead of you.", 5):ToAll()
      end
      
      self:_AddFlightToTakeoffQueue(flight)
    
    else
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
    
  -- Add to known flights.
  table.insert(self.flights, flight)
    
  return flight
end

--- Remove flight from all queues.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight The flight to be removed.
function FLIGHTCONTROL:_RemoveFlight(flight)

  self:_RemoveFlightFromQueue(self.Qwaiting, flight, "holding")
  self:_RemoveFlightFromQueue(self.Qlanding, flight, "landing")
  self:_RemoveFlightFromQueue(self.Qparking, flight, "parking")
  self:_RemoveFlightFromQueue(self.Qtakeoff, flight, "takeoff")
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
-- Routing Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Scan airbase zone for units, statics and scenery.
-- @param #FLIGHTCONTROL self
-- @return Core.Set#SET_UNIT Set of scanned units.
-- @return Core.Set#SET_STATIC Set of scanned static objects.
function FLIGHTCONTROL:_CheckAirbase()
  
  -- Airbase position.
  local coord=self:GetCoordinate()
  
  -- Scan radius = 5 NM.
  local RCCZ=UTILS.NMToMeters(1)
  
  self.scenery=self.scenery or {}
  
  local scanscenery=true
  if #self.scenery>0 then
    scanscenery=false
  end
  
  -- Debug info.
  self:T(self.lid..string.format("Scanning airbase zone. Radius=%.1f NM.", UTILS.MetersToNM(RCCZ)))
  
  -- Scan units in carrier zone.
  local _,_,_,unitscan,staticscan,sceneryscan=coord:ScanObjects(RCCZ, true, true, scanscenery)
  
  local su=SET_UNIT:New():FilterActive(true)
  for _,_unit in pairs(unitscan) do
    local unit=_unit --Wrapper.Unit#UNIT
    if unit and unit:IsAlive() and unit:InAir()==false then
      su:AddUnit(unit)
      
    end  
  end
  
  local setstatic=SET_STATIC:New()
  for _,static in pairs(staticscan) do
    local static=STATIC:Find(static)
    setstatic:AddStatic(static)
    static:GetCoordinate():MarkToAll("Static")    
  end
  
  
  if scanscenery then
    for _,scen in pairs(sceneryscan) do
      --local static=SCENERY:
      local s=SCENERY:Register(scen:getName(), scen)
      --s:GetCoordinate():MarkToAll("Scenery")
      table.insert(self.scenery, s)
    end
  end
    
  -- Debug info.
  local text=string.format("Scan found: units=%d, statics=%d, scenery=%d", su:Count(), setstatic:Count(), #self.scenery)
  self:I(self.lid..text)
  
  return su,setstatic  
end


--- Scan airbase zone and find new flights.
-- @param #FLIGHTCONTROL self
-- @param Core.Set#SET_UNIT unitset Set of units.
function FLIGHTCONTROL:_CheckACstatus(unitset)
  
  -- Make a table with all groups currently in the CCA zone.
  local insideZone={}
  
  for _,_unit in pairs(unitset:GetSetObjects()) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    -- Necessary conditions to be met:
    local aircraft=unit:IsAir()
    local inzone=unit:IsInZone(self.zoneAirbase)
    local friendly=self:GetCoalition()==unit:GetCoalition()
    
    -- Check if this an aircraft and that it is inside the airbase zone and friendly.
    if aircraft and inzone then
    
      local group=unit:GetGroup()
      local groupname=group:GetName()
      
      -- Add group to table.
      if insideZone[groupname]==nil then
        insideZone[groupname]=groupname
      end
      
    end
  end
  
  -- Find new flights that are inside the airbase zone.
  for groupname,_ in pairs(insideZone) do
    local flight=_DATABASE:GetFlightGroup(groupname)

    if flight then
    
      for _,_element in pairs(flight.elements) do
        local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
        
        local unit=element.unit
        
        if unit and unit:IsAlive() then
        
          if unit:InAir() then
          
          else
          
            if element.status==FLIGHTGROUP.ElementStatus.PARKING then
              if element.parking then
              
              end
            end
          
          end
        
        end
        
      end
    
    end

  end
  
end

--- Command AI flight to orbit.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param #number stack Holding stack.
-- @param #boolean respawn If true respawn the group. Otherwise reset the mission task with new waypoints.
function FLIGHTCONTROL:_WaitAI(flight, stack, respawn)

  -- Set flag to something other than -100 and <0
  flight.flag=stack

  -- Holding point.
  local holding=self:_GetHoldingpoint(flight)
  local altitude=holding.pos0.y
  local angels=UTILS.MetersToFeet(altitude)/1000
  
  flight:Hold(self.airbase, holding.pos0)
  
end

--- Tell AI to land at the airbase. Flight is added to the landing queue.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP flight Flight group.
-- @param #table parking Free parking spots table.
function FLIGHTCONTROL:_LandAI(flight, parking)

   -- Debug info.
  self:I(self.lid..string.format("Landing AI flight %s.", flight.groupname))

  -- Add flight to landing queue.
  self:_AddFlightToLandingQueue(flight)

  -- Remove flight from waiting queue.
  self:_RemoveFlightFromQueue(self.Qwaiting, flight, "holding")
 
   -- Altitude above ground for a glide slope of 3�.
  local alpha=math.rad(3)
  local x1=UTILS.NMToMeters(10)
  local x2=UTILS.NMToMeters(5)
  local h1=x1*math.tan(alpha)
  local h2=x2*math.tan(alpha)
  local SpeedLand=140
  local SpeedTo=180
  
  local runway=self:GetActiveRunway()
  
  -- Waypoints.
  local wp={}
  
  -- Current pos.
  wp[#wp+1]=flight.group:GetCoordinate():WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {}, "Current Pos")
  
  -- Approach point: 10 NN in direction of runway.
  local papp=self.airbase:GetCoordinate():Translate(x1, runway.heading-180):SetAltitude(h1)
  wp[#wp+1]=papp:WaypointAirTurningPoint(nil, UTILS.KnotsToKmph(SpeedLand), {}, "Final Approach")  
  
  -- Okay, it looks like it's best to specify the coordinates not at the airbase but a bit away. This causes a more direct landing approach.
  local pland=self.airbase:GetCoordinate():Translate(x2, runway.heading-180):SetAltitude(h2)  
  wp[#wp+1]=pland:WaypointAirLanding(UTILS.KnotsToKmph(SpeedLand), self.airbase, {}, "Landing")
  

  if self.Debug then
    papp:MarkToAll(string.format("Final Approach: d=%d m, h=%d m", x1, h1))
    pland:MarkToAll(string.format("Landing: d=%d m, h=%d m", x2, h2))
  end      
  
  -- Give signal to land.
  flight.flaghold:Set(1)
  
  -- Get group template.
  local Template=flight.group:GetTemplate()

  -- Set route points.
  Template.route.points=wp
  
  for i,unit in pairs(Template.units) do
    local spot=parking[i] --Ops.FlightControl#FLIGHTCONTROL.ParkingSpot
    
    local element=flight:GetElementByName(unit.name)
    if element then
      element.parking=spot
      unit.parking_landing=spot.TerminalID
      local text=string.format("FF Reserving parking spot %d for unit %s", spot.TerminalID, tostring(unit.name))
      self:I(self.lid..text)
    else
      env.info("FF error could not get element to assign parking!")      
    end
  end      
  
  -- Debug message.
  MESSAGE:New(string.format("Respawning group %s", flight.groupname)):ToAll()

  --Respawn the group.
  flight.group=flight.group:Respawn(Template, true)
      
  -- Route the group.
  --flight.group:Route(wp, 1)
  
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

--TODO: Get landing waypoint to check whether flight is meant to land at this airbase.

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

--- Get onboard number of player or client.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #string Onboard number as string.
function FLIGHTCONTROL:_GetOnboardNumberPlayer(group)
  return self:_GetOnboardNumbers(group, true)
end

--- Get onboard numbers of all units in a group.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @param #boolean playeronly If true, return the onboard number for player or client skill units.
-- @return #table Table of onboard numbers.
function FLIGHTCONTROL:_GetOnboardNumbers(group, playeronly)
  
  -- Get group name.
  local groupname=group:GetName()
  
  -- Debug text.
  local text=string.format("Onboard numbers of group %s:", groupname)
  
  -- Units of template group.
  local units=group:GetTemplate().units
  
  -- Get numbers.
  local numbers={}
  for _,unit in pairs(units) do
  
    -- Onboard number and unit name.
    local n=tostring(unit.onboard_num)
    local name=unit.name
    local skill=unit.skill

    -- Debug text.
    text=text..string.format("\n- unit %s: onboard #=%s  skill=%s", name, n, skill)

    if playeronly and skill=="Client" or skill=="Player" then
      -- There can be only one player in the group, so we skip everything else.
      return n
    end
    
    -- Table entry.
    numbers[name]=n
  end
  
  -- Debug info.
  self:T2(self.lid..text)
  
  return numbers
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
