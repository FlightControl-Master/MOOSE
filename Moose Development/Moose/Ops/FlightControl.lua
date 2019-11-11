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
-- @field #table flight All flights table.
-- @field #table Qwaiting Queue of aircraft waiting for landing permission.
-- @field #table Qlanding Queue of aircraft currently on final approach.
-- @field #table Qtakeoff Queue of aircraft about to takeoff.
-- @field #table Qparking Queue of aircraft parking.
-- @field #number activerwyno Number of active runway.
-- @field #number atcfreq ATC radio frequency.
-- @field Core.RadioQueue#RADIOQUEUE atcradio ATC radio queue.
-- @field #table playermenu Player Menu.
-- @extends Core.Fsm#FSM

--- **Ground Control**: Airliner X, Good news, you are clear to taxi to the active.
--  **Pilot**: Roger, What’s the bad news?
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
  activerwyno    =     1,
  atcfreq        =   nil,
  atcradio       =   nil,
  atcradiounitname = nil,
  playermenu       = nil,
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
-- @field #number index Parking index.
-- @field #number id Parking id.
-- @field Core.Point#COORDINATE position Coordinate of the spot.
-- @field #number terminal Terminal type.
-- @field #boolean free If true, spot is free.
-- @field #number drunway Distance to runway.
-- @field #boolean reserved If true, reserved.
-- @field #number markerid ID of the marker.

--- Runway data.
-- @type FLIGHTCONTROL.Runway
-- @field #number direction Direction of the runway.
-- @field #number length Length of runway in meters.
-- @field #number width Width of runway in meters.
-- @field Core.Point#COORDINATE position Position of runway start.

--- FlightControl class version.
-- @field #string version
FLIGHTCONTROL.version="0.0.7"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Add FARPS.
-- TODO: Add helos.
-- TODO: Task me down option.
-- TODO: ATIS option.
-- TODO: ATC voice overs.
-- TODO: Check runways and clean up.
-- TODO: Interface with FLIGHTGROUP

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
  self.airbasetype=self.airbase:GetDesc().category
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTCONTROL %s | ", airbasename)
  
  -- Current map.
  self.theatre=env.mission.theatre    
  
  -- 30 NM zone around the airbase.
  self.zoneAirbase=ZONE_RADIUS:New("FC", self:GetCoordinate():GetVec2(), UTILS.NMToMeters(30))
  
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
  if true then
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
  self.atcradio:Start(1, 0.01)
  
  -- Init status updates.
  self:__Status(-1)
end

--- Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStatus()

  -- Check zone for flights inbound.
  --self:_CheckInbound()
  
  -- Check parking spots.
  self:_CheckParking()
  self:_UpdateParkingSpots()
  
  -- Check waiting and landing queue.
  self:_CheckQueues()
  
  -- Get runway.
  local runway=self:GetActiveRunway()
  
  -- Get free parking spots.
  local nfree=self:_GetFreeParkingSpots()  

  -- Info text.
  local text=string.format("State %s - Runway %s - Parking %d/%d - Qpark=%d Qtakeoff=%d Qland=%d Qhold=%d", self:GetState(), runway.idx, nfree, #self.parking, #self.Qparking, #self.Qtakeoff, #self.Qlanding, #self.Qwaiting)
  self:I(self.lid..text)

  -- Next status update in ~30 seconds.
  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for event birth.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventBirth(EventData)
  self:F3({EvendData=EventData})
  
  self:I(self.lid..string.format("BIRTH: unit  = %s", tostring(EventData.IniUnitName)))
  self:I(self.lid..string.format("BIRTH: group = %s", tostring(EventData.IniGroupName)))
  
  if EventData and EventData.IniGroupName and EventData.Place and EventData.Place:GetName()==self.airbasename then
  
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
  self:I(self.lid..string.format("ENGINESTARTUP: group = %s", tostring(EventData.IniGroupName)))
    
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
  
  self:T2(self.lid..string.format("ENGINESHUTDOWN: unit  = %s", tostring(EventData.IniUnitName)))
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
  --self:_PrintQueue(self.flights,  "All flights")
  self:_PrintQueue(self.Qparking, "Parking")
  self:_PrintQueue(self.Qtakeoff, "Takeoff")
  self:_PrintQueue(self.Qwaiting, "Holding")
  self:_PrintQueue(self.Qlanding, "Landing")
  
  -- Number of groups landing.
  local nlanding=#self.Qlanding
    
  -- Number of groups taking off.
  local ntakeoff=#self.Qtakeoff
  
  -- Number of holding groups.
  local nholding=#self.Qwaiting
  
  -- Number of parking groups.
  local nparking=#self.Qparking

  local flight, isholding=self:_GetNextFight()
  

  if flight and ntakeoff==0 and nlanding==0 then  
    
    if isholding then

      -- Message.
      local text=string.format("Flight %s, you are cleared to land.", flight.groupname)
      MESSAGE:New(text, 5, "FLIGHTCONTROL"):ToAll()

      -- Give AI the landing signal.
      -- TODO: Humans have to confirm via F10 menu.
      if flight.ai then      
        flight:FlightLanding()
        self:_LandAI(flight)
      end
    
    else
     
      -- Check if flight is AI. Humans have to request taxi via F10 menu.
      if flight.ai then
      
        -- Message.
        -- TODO: Which runway!
        local text=string.format("Flight %s, you are cleared to taxi to runway.", flight.groupname)
        self:I(self.lid..text)
        MESSAGE:New(text, 5, "FLIGHTCONTROL"):ToAll()
        
        flight.group:StartUncontrolled()
        
        flight:_UpdateRoute(1)
        
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
function FLIGHTCONTROL:_GetNextFight()

  local flightholding=self:_GetNextFightHolding()
  local flightparking=self:_GetNextFightParking()
  
  -- If no flight is waiting for takeoff return the holding flight or nil.
  if not flightparking then
    return flightholding, true
  end
  
  -- If no flight is waiting for landing return the takeoff flight or nil.
  if not flightholding then
    return flightparking, false
  end
  
  -- We got flights waiting for landing and for takeoff.
  if flightholding and flightparking then
  
    -- Return holding flight if fuel is low.
    if flightholding.fuellow then
      return flightholding, true
    end
    
    
    -- Return the flight which is waiting longer.
    if flightholding.Tholding>flightparking.Tparking then
      return flightholding, true
    else
      return flightparking, false
    end
    
  end

  return nil, nil
end


--- Get next flight waiting for landing clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightHolding()

  if #self.Qwaiting==0 then
    return nil
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


--- Get next flight waiting for landing clearance.
-- @param #FLIGHTCONTROL self
-- @return Ops.FlightGroup#FLIGHTGROUP Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextFightParking()

  if #self.Qparking==0 then
    return nil
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
      local holding=flight.Tholding and UTILS.SecondsToClock(flight.Tholding-time, true) or "X"
      local parking=flight.Tparking and UTILS.SecondsToClock(flight.Tparking-time, true) or "X"
      
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parking Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Init parking spots.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_InitParkingSpots()

  -- Parking spots of airbase.
  local parkingdata=self.airbase:GetParkingSpotsTable()
  
  self.parking={}
  
  for _,_spot in pairs(parkingdata) do
    local spot=_spot --Wrapper.Airbase#AIRBASE.ParkingData
    
    local parking={} --#FLIGHTCONTROL.ParkingSpot
    
    parking.position=spot.Coordinate
    parking.drunway=spot.DistToRwy
    parking.terminal=spot.TerminalType
    parking.id=spot.TerminalID
    parking.free=spot.Free
    parking.reserved=spot.TOAC
    
    -- Mark position.
    local text=string.format("ID=%d, Terminal=%d, Free=%s, Reserved=%s, Dist=%.1f", parking.id, parking.terminal, tostring(parking.free), tostring(parking.reserved), parking.drunway)
    --parking.markerid=parking.position:MarkToAll(text)
    
    -- Add to table.
    table.insert(self.parking, parking)
  end

end

--- Check parking spots.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckParking()

  -- Init all elements as NOT parking anywhere.
  for _,_flight in pairs(self.flights) do    
    -- Loop over all elements.
    for _,_element in pairs(_flight.elements) do
      local element=_element --#FLIGHTCONTROL.FlightElement
      element.parking=false
    end
  end

  -- Loop over all parking spots.
  for i,_spot in pairs(self.parking) do
    local spot=_spot --#FLIGHTCONTROL.ParkingSpot
    
    -- Assume spot is free.
    spot.free=true
    
    -- Loop over all flights.
    for _,_flight in pairs(self.flights) do
      local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
      -- Loop over all elements.
      for _,_element in pairs(flight.elements) do
        local element=_element --Ops.FlightGroup#FLIGHTGROUP.Element
        
        if element.unit and element.unit:IsAlive() then

          -- Distance to parking spot.
          local dist=element.unit:GetCoordinate():Get3DDistance(spot.position)
          
          -- Element is parking on this spot
          if dist<5 and not element.unit:InAir() then
            element.parking=true
            spot.free=false
          end
          
        else
          self:E(self.lid..string.format("ERROR: Element %s is not alive any more!", element.name))
        end
        
      end
    
    end
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
    
    if parking.free then
      if terminal==nil or terminal==parking.terminal then
        n=n+1
        table.insert(freespots, parking)
      end
    end
  end

  return n,freespots
end

--- Init parking spots.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_UpdateParkingSpots()

  -- Parking spots of airbase.
  local parkingdata=self.airbase:GetParkingSpotsTable()
  
  local message="Parking Spots:"
  for _,_parkingspot in pairs(self.parking) do
    local parking=_parkingspot --#FLIGHTCONTROL.ParkingSpot
    
    for _,_spot in pairs(parkingdata) do
      local spot=_spot --Wrapper.Airbase#AIRBASE.ParkingSpot 
    
      if parking.id==spot.TerminalID then

        parking.position=spot.Coordinate
        parking.drunway=spot.DistToRwy
        parking.terminal=spot.TerminalType
        parking.id=spot.TerminalID
        parking.free=spot.Free
        parking.reserved=spot.TOAC
        
        -- Mark position.
        if parking.markerid then
          parking.position:RemoveMark(parking.markerid)
        end
        
        local text=string.format("ID=%d, Terminal=%d, Free=%s, Reserved=%s, Dist=%.1f", parking.id, parking.terminal, tostring(parking.free), tostring(parking.reserved), parking.drunway)
        message=message.."\n"..text
        if parking.free==false or parking.reserved then
          parking.markerid=parking.position:MarkToAll(text)
        end
          
        break
      end
      
    end
  end

  self:E(self.lid..message)
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
function FLIGHTCONTROL:_CreatePlayerMenu(flight)
  
  local group=flight.group
  local groupname=flight.groupname
  local gid=group:GetID()
  
  self:I(self.lid..string.format("Creating player menu for flight group %s (ID=%d)", tostring(flight.groupname), gid))
  
  if not self.playermenu[gid] then
    self.playermenu[gid]={}
  end
  
  local playermenu=self.playermenu[gid]  --#FLIGHTCONTROL.PlayerMenu

  playermenu.root           = MENU_GROUP:New(group, "ATC")
  playermenu.MyStatus       = MENU_GROUP_COMMAND:New(group, "My Status",       playermenu.root, self._PlayerMyStatus,       self, groupname)
  playermenu.RequestTaxi    = MENU_GROUP_COMMAND:New(group, "Request Taxi",    playermenu.root, self._PlayerRequestTaxi,    self, groupname)
  playermenu.RequestTakeoff = MENU_GROUP_COMMAND:New(group, "Request Takeoff", playermenu.root, self._PlayerRequestTakeoff, self, groupname)
  playermenu.Inbound        = MENU_GROUP_COMMAND:New(group, "Inbound",         playermenu.root, self._PlayerInbound,        self, groupname)
  

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

    MESSAGE:New(text, 5):ToAll()
  
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
  
    MESSAGE:New("You are cleared to taxi", 5):ToAll()
    
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
  
  if flight.destination and flight.destination:GetName()==self.airbasename then
    flight:SetFlightControl(self)
  end
    
  -- Add to known flights.
  table.insert(self.flights, flight)
  
  -- Create player menu.
  if flight.ai then
    self:E("FF AI no player menu")
  else
    self:E("FF Not purly AI ==> player menu")
    self:_CreatePlayerMenu(flight)
  end
    
  return flight
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

--- Get parking spot of flight element.
-- @param #FLIGHTCONTROL self
-- @param Ops.FlightGroup#FLIGHTGROUP.Element element Element of flight group.
-- @return #FLIGHTCONTROL.ParkingSpot Parking spot of flight element or nil.
function FLIGHTCONTROL:_GetElementParkingSpot(element)

  if element then

    -- Unit object.
    local unit=element.unit
    
    if unit then
    
      local upos=unit:GetCoordinate()
      
      for _,_parkingspot in pairs(self.parking) do
        local parkingspot=_parkingspot --#FLIGHTCONTROL.ParkingSpot
        
        -- Spot position.
        local spos=parkingspot.position
        
        -- 3D distance from unit to spot.
        local dist=spos:Get3DDistance(upos)
        
        -- Distance threshold 5 meters.
        if dist<5 then
          return parkingspot
        end
      
      end
    
    end
  end
  
  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Scan airbase zone and find new flights.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckACstatus()
  
  -- Airbase position.
  local coord=self:GetCoordinate()
  
  -- Scan radius = 20 NM.
  local RCCZ=UTILS.NMToMeters(20)
  
  -- Debug info.
  self:T(self.lid..string.format("Scanning airbase zone. Radius=%.1f NM.", UTILS.MetersToNM(RCCZ)))
  
  -- Scan units in carrier zone.
  local _,_,_,unitscan=coord:ScanObjects(RCCZ, true, false, false)

  -- Make a table with all groups currently in the CCA zone.
  local insideZone={}
  
  for _,_unit in pairs(unitscan) do
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

--- Scan airbase zone and find new flights.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckInbound()
  
  -- Airbase position.
  local coord=self:GetCoordinate()
  
  -- Scan radius = 20 NM.
  local RCCZ=UTILS.NMToMeters(20)
  
  -- Debug info.
  self:T(self.lid..string.format("Scanning airbase zone. Radius=%.1f NM.", UTILS.MetersToNM(RCCZ)))
  
  -- Scan units in carrier zone.
  local _,_,_,unitscan=coord:ScanObjects(RCCZ, true, false, false)

  -- Make a table with all groups currently in the CCA zone.
  local insideZone={}
  
  for _,_unit in pairs(unitscan) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    -- Necessary conditions to be met:
    local aircraft=unit:IsAir()
    local inzone=unit:IsInZone(self.zoneAirbase)
    local friendly=self:GetCoalition()==unit:GetCoalition()
    
    -- Check if this an aircraft and that it is inside the airbase zone and friendly.
    if aircraft and inzone and friendly then
    
      local group=unit:GetGroup()
      local groupname=group:GetName()
      
      -- Add group to table.
      if insideZone[groupname]==nil then
        insideZone[groupname]=group
      end
      
    end
  end


  
  -- Find new flights that are inside the airbase zone.
  for groupname,_group in pairs(insideZone) do
    local group=_group --Wrapper.Group#GROUP
    self:_CreateFlightGroup(group)
  end
  
  for _,_flight in pairs(self.flights) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
    if flight and flight.destination and flight.destination:GetName()==self.airbasename then
 
       -- Send AI to orbit outside 10 NM zone and wait until the next Marshal stack is available.
      if not (self:_InQueue(self.Qwaiting, flight.group) or self:_InQueue(self.Qlanding, flight.group) or flight:IsHolding()) then
        self:_WaitAI(flight, 1, true)
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
function FLIGHTCONTROL:_LandAI(flight)

   -- Debug info.
  self:I(self.lid..string.format("Landing AI flight %s.", flight.groupname))

  -- Add flight to landing queue.
  --table.insert(self.Qlanding, flight)
  self:_AddFlightToLandingQueue(flight)
  
  -- Give signal to land.
  flight.flaghold:Set(1)
  
  -- Remove flight from waiting queue.
  self:_RemoveFlightFromQueue(self.Qwaiting, flight, "holding")
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
