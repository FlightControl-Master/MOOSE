--- **ATC** - (R2.5) - Manage recovery of aircraft at airdromes and FARPS.
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
-- @module ATC.FlightControl
-- @image ATC_FlightControl.png


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
-- @extends Core.Fsm#FSM

--- Be surprised!
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
}

--- Parameters of a flight group.
-- @type FLIGHTCONTROL.FlightGroup
-- @field #string groupname Name of the group.
-- @field Wrapper.Group#GROUP group Flight group.
-- @field #number nunits Number of units in group.
-- @field #number time Timestamp in seconds of timer.getAbsTime() of the last important event, e.g. added to the queue.
-- @field #number dist0 Distance in meters when group was first detected.
-- @field #number flag Flag value describing the current stack.
-- @field #boolean ai If true, flight is purly AI.
-- @field #string actype Aircraft type name.
-- @field #table onboardnumbers Onboard numbers of aircraft in the group.
-- @field #string onboard Onboard number of player or first unit in group.
-- @field #boolean holding If true, flight is in holding zone.
-- @field #boolean inzone If true, flight is inside airbase zone.
-- @field #table elements Flight group elements.

--- Parameters of an element in a flight group.
-- @type FLIGHTCONTROL.FlightElement
-- @field #string unitname Name of the unit.
-- @field Wrapper.Unit#UNIT unit Aircraft unit.
-- @field #boolean ai If true, AI sits inside. If false, human player is flying.
-- @field #string onboard Onboard number of the aircraft.
-- @field #boolean recovered If true, element was successfully recovered.
-- @field #boolean tookoff If true, element took off.
-- @field #boolean parking If true, element is parking.
-- @field #number sizemax Max size (length or width) of aircraft in meters.

--- Parameters of an element in a flight group.
-- @type FLIGHTCONTROL.FlightState
-- @field #string LANDED
-- @field #string PARKED
-- @field #string HOLDING
-- @field #string TAXIING
FLIGHTCONTROL.FlightState={
  LANDED="Landed",
  PARKED="Parked",
  HOLDING="Holding",
  TAXIING="Taxiing",
}

--- Holding point
-- @type FLIGHTCONTROL.HoldingPoint
-- @field Core.Point#COORDINATE pos0 First poosition of racetrack holding point.
-- @field Core.Point#COORDINATE pos1 Second position of racetrack holding point.
-- @field #number angelsmin Smallest holding altitude in angels.
-- @field #number angelsmax Largest holding alitude in angels.

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
FLIGHTCONTROL.version="0.0.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Add FARPS.
-- TODO: Add helos.
-- TODO: Task me down option.
-- TODO: ATIS option.
-- TODO: ATC voice overs.
-- TODO: Check runways and clean up.

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
  
  self.airbase=AIRBASE:FindByName(airbasename)
  
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
    --self.dTstatus=0.1
  end

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
  
  -- Init status updates.
  self:__Status(-1)
end

--- Update status.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:onafterStatus()

  -- Check zone for flights inbound.
  self:_CheckInbound()
  
  --self:_UpdateParkingSpots()
  
  -- Check parking spots.
  self:_CheckParking()
  
  -- Check waiting and landing queue.
  self:_CheckQueues()
  
  -- Get runway.
  local runway=self:_GetActiveRunway()
  
  -- Get free parking spots.
  local nfree=self:_GetFreeParkingSpots()  

  -- Info text.
  local text=string.format("State %s - Active Runway %03d - Free Parking %d", self:GetState(), runway.direction, nfree)
  self:I(self.lid..text)

  -- Next status update in ~30 seconds.
  self:__Status(-30)
end

--- Initialize data of runways.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_InitRunwayData()

  -- Get spawn points on runway.
  local runwaycoords=self.airbase:GetParkingSpotsCoordinates(AIRBASE.TerminalType.Runway)
  
  self:E(self.lid..string.format("Runway coords # = %d", #runwaycoords))
  
  for i=1,#runwaycoords,2 do
    
    -- Assuming each runway has two points.
    local j=(i+1)/2
  
    -- Coordinates of the two runway points.
    local c1=runwaycoords[i]   --Core.Point#COORDINATES
    local c2=runwaycoords[i+1] --Core.Point#COORDINATES
    
    -- Debug mark
    c1:MarkToAll("Runway Point 1")
    c2:MarkToAll("Runway Point 2")
   
    -- Heading of runway.
    local hdg=c1:HeadingTo(c2)
    
    -- Debug info.
    self:T(self.lid..string.format("Runway %d heading=%03d�", j, hdg))
    
    -- Runway table.
    local runway={} --#FLIGHTCONTROL.Runway
    runway.direction=hdg    
    runway.length=c1:Get2DDistance(c2)    
    runway.position=c1
    
    -- Add runway.
    table.insert(self.runways, runway)
    
    -- Inverse runway.
    local runway={} --#FLIGHTCONTROL.Runway
    local hdg=hdg-180
    if hdg<0 then
      hdg=hdg+360
    end
    runway.direction=hdg
    runway.length=c1:Get2DDistance(c2)    
    runway.position=c2

    -- Add inverse runway.
    table.insert(self.runways, runway)    
  end

end

--- Get the active runway based on current wind direction.
-- @param #FLIGHTCONTROL self
-- @return #FLIGHTCONTROL.Runway Active runway.
function FLIGHTCONTROL:_GetActiveRunway()
  -- TODO: get runway.
  local i=math.max(self.activerwyno, #self.runways)
  return self.runways[i]
end

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
    parking.markerid=parking.position:MarkToAll(text)
    
    -- Add to table.
    table.insert(self.parking, parking)
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
        parking.markerid=parking.position:MarkToAll(text)
          
        break
      end
      
    end
  end

  self:E(self.lid..message)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event handler for event birth.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventBirth(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("BIRTH: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("BIRTH: group = %s", tostring(EventData.IniGroupName)))
  
end

--- Event handler for event land.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventLand(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("LAND: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("LAND: group = %s", tostring(EventData.IniGroupName)))
  

  -- This would be the closest airbase.
  local airbase=EventData.Place
  
  -- Nil check for airbase. Crashed as player gave me no airbase.
  if airbase==nil then
    return
  end
  
  -- Get airbase name.
  local airbasename=tostring(airbase:GetName())
  
  -- Check if landed at this airbase.
  if airbasename==self.airbasename then
  
    -- AI always lands ==> remove unit from flight group and queues.
    local flight=self:_ElementRecovered(EventData.IniUnit)
    
    if flight then
    
      -- Check if everybody is home.
      local recovered=true
      for _,_elem in pairs(flight.elements) do
        local element=_elem --#FLIGHTCONTROL.FlightElement
        if not element.recovered then
          recovered=false
        end
      end
    
      -- Remove flight.
      if recovered then
        self:_RemoveFlightFromQueue(self.Qlanding, flight)
      end
    
    end
  
  end

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
  
  -- Get airbase name.
  local airbasename=tostring(airbase:GetName())
  
  -- Check if landed at this airbase.
  if airbasename==self.airbasename then
  
    -- AI always lands ==> remove unit from flight group and queues.
    local flight=self:_ElementTookOff(unit)
    
    if flight then
    
      self:T(self.lid..string.format("Flight element %s took off.", EventData.IniUnitName))
    
      -- Check if everybody is in the air.
      local all=true
      for _,_elem in pairs(flight.elements) do
        local element=_elem --#FLIGHTCONTROL.FlightElement        
        if not element.tookoff then
          all=false
        end
      end
    
      -- Remove flight.
      if all then
        self:T(self.lid..string.format("Flight group %s took off.", flight.groupname))
        self:_RemoveFlightFromQueue(self.Qtakeoff, flight)
      end
    
    end
  end
end

--- Event handler for event engine startup.
-- @param #FLIGHTCONTROL self
-- @param Core.Event#EVENTDATA EventData
function FLIGHTCONTROL:OnEventEngineStartup(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("ENGINESTARTUP: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("ENGINESTARTUP: group = %s", tostring(EventData.IniGroupName)))
    
  -- Unit that took off.
  local unit=EventData.IniUnit

  -- Nil check for unit.
  if not unit then
    return
  end
  
  -- Get flight element.
  local element, idx, flight=self:_GetFlightElement(EventData.IniUnitName)
  
  if element then
    local parkingspot=self:_GetElementParkingSpot(element)
    if parkingspot then
      self:_AddFlightToTakeoffQueue(flight)
    end
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
function FLIGHTCONTROL:OnEventEngineCrash(EventData)
  self:F3({EvendData=EventData})
  
  self:T2(self.lid..string.format("CRASH: unit  = %s", tostring(EventData.IniUnitName)))
  self:T2(self.lid..string.format("CRASH: group = %s", tostring(EventData.IniGroupName)))
    
  -- Unit that took off.
  local unit=EventData.IniUnit

  -- Nil check for unit.
  if not unit then
    return
  end

  self:_RemoveFlightElement(EventData.IniUnitName)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Queue Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Scan airbase zone.
-- @param #FLIGHTCONTROL self
function FLIGHTCONTROL:_CheckQueues()

  -- Print queues
  self:_PrintQueue(self.flights,  "All flights")
  self:_PrintQueue(self.Qwaiting, "Waiting")
  self:_PrintQueue(self.Qtakeoff, "Takeoff")
  self:_PrintQueue(self.Qparking, "Parking")

  -- Get next wairing flight.
  local flight=self:_GetNextWaitingFight()
  
  -- Number of groups landing.
  local nlanding=#self.Qlanding
  
  -- Number of groups taking off.
  local ntakeoff=#self.Qtakeoff
  
  if flight and nlanding==0 and ntakeoff==0 then
    self:_LandAI(flight)
    self:_RemoveFlightFromQueue(self.Qwaiting, flight)
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
    
      -- Loop over all elements.
      for _,_element in pairs(_flight.elements) do
        local element=_element --#FLIGHTCONTROL.FlightElement
        
        local unit=element.unit
        
        if unit and unit:IsAlive() then

          -- Distance to parking spot.
          local dist=element.unit:GetCoordinate():Get3DDistance(spot.position)
          
          -- Element is parking on this spot
          if dist<5 and not element.unit:InAir() then
            element.parking=true
            spot.free=false
          end
          
        else
          self:E(self.lid..string.format("ERROR: Element %s is not alive any more!", element.unitname))
          self:_RemoveFlightElement(element.unitname)
        end
        
      end
    
    
    end
  end
end

--- Get next flight waiting for landing clearance.
-- @param #FLIGHTCONTROL self
-- @return #FLIGHTCONTROL.FlightGroup Marshal flight next in line and ready to enter the pattern. Or nil if no flight is ready.
function FLIGHTCONTROL:_GetNextWaitingFight()

  -- Loop over all marshal flights.
  for _,_flight in pairs(self.Qwaiting) do
    local flight=_flight --#FLIGHTCONTROL.FlightGroup
    
    -- Current stack.
    local stack=flight.flag
    
    -- Total marshal time in seconds.
    local Tmarshal=timer.getAbsTime()-flight.time
    
    -- Min time in marshal stack.
    local TmarshalMin=3*60 --Three minutes for human players.
    
    -- Check if conditions are right.
    if flight.holding~=nil and Tmarshal>=TmarshalMin then
      return flight
    end
    
  end

  return nil
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
  
    -- Loop over all flights in queue.
    for i,_flight in ipairs(queue) do
      local flight=_flight --#FLIGHTCONTROL.FlightGroup
      
      -- Gather info.
      local clock=UTILS.SecondsToClock(timer.getAbsTime()-flight.time)
      local fuel=flight.group:GetFuelMin()*100
      local ai=tostring(flight.ai)
      local actype=flight.actype
      local holding=tostring(flight.holding)
      local nunits=flight.nunits
      
      -- Main info.
      text=text..string.format("\n[%d] %s (%s*%d): ai=%s, timestamp=%s, fuel=%d, inzone=%s, holding=%s",
                                 i, flight.groupname, actype, nunits, ai, clock, fuel, tostring(flight.inzone), holding)

      -- Elements info.                                 
      for j,_element in pairs(flight.elements) do
        local element=_element --#FLIGHTCONTROL.FlightElement
        local life=element.unit:GetLife()
        local life0=element.unit:GetLife0()
        text=text..string.format("\n  (%d) %s (%s): ai=%s, parking=%s, recovered=%s, tookoff=%s, airborne=%s life=%.1f/%.1f",
        j, element.onboard, element.unitname, tostring(element.ai), tostring(element.parking), tostring(element.recovered), tostring(element.tookoff), tostring(element.unit:InAir()), life, life0)
      end
    end
  end
  
  -- Display text.
  self:T(self.lid..text)
end

--- Remove a flight group from a queue.
-- @param #FLIGHTCONTROL self
-- @param #table queue The queue from which the group will be removed.
-- @param #FLIGHTCONTROL.FlightGroup flight Flight group that will be removed from queue.
-- @return #boolean True, flight was in Queue and removed. False otherwise.
-- @return #number Table index of removed queue element or nil.
function FLIGHTCONTROL:_RemoveFlightFromQueue(queue, flight)

  -- Loop over all flights in group.
  for i,_flight in pairs(queue) do
    local qflight=_flight --#FLIGHTCONTROL.FlightGroup
    
    -- Check for name.
    if qflight.groupname==flight.groupname then
      self:T(self.lid..string.format("Removing flight group %s from queue.", flight.groupname))
      table.remove(queue, i)
      return true, i
    end
  end
  
  return false, nil
end

--- Sets flag recovered=true and tookoff=false for a flight element, which was successfully recovered (landed).
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Unit#UNIT unit The aircraft unit that was recovered.
-- @return #FLIGHTCONTROL.FlightGroup Flight group of element.
function FLIGHTCONTROL:_ElementRecovered(unit)

  -- Get element of flight.
  local element, idx, flight=self:_GetFlightElement(unit:GetName())  --#FLIGHTCONTROL.FlightElement
  
  -- Nil check. Could be if a helo landed or something else we dont know!
  if element then
    element.recovered=true
    element.tookoff=false
  end
  
  return flight
end

--- Set tookoff to true for the flight element.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Unit#UNIT unit The aircraft unit that was recovered.
-- @return #FLIGHTCONTROL.FlightGroup Flight group of element.
function FLIGHTCONTROL:_ElementTookOff(unit)

  -- Get element of flight.
  local element, idx, flight=self:_GetFlightElement(unit:GetName())  --#FLIGHTCONTROL.FlightElement
  
  -- Nil check. Could be if a helo landed or something else we dont know!
  if element then
    element.tookoff=true
  end
  
  return flight
end

--- Add flight to landing queue and set recovered to false for all elements of the flight and its section members.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.FlightGroup flight Flight group of element.
function FLIGHTCONTROL:_AddFlightToLandingQueue(flight)

  -- Add flight to table.
  table.insert(self.Qlanding, flight)
  
  -- Set flag to -1.
  flight.flag=-1
  
  -- New time stamp for time in pattern.
  flight.time=timer.getAbsTime()
  
  -- Init recovered switch.
  flight.recovered=false
  for _,elem in pairs(flight.elements) do
    elem.recoverd=false
  end
  
end

--- Add flight to takeoff queue.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.FlightGroup flight Flight group of element.
function FLIGHTCONTROL:_AddFlightToTakeoffQueue(flight)

  -- Check if already in queue.
  if self:_InQueue(self.Qtakeoff,flight.group) then
    return
  end

  -- Add flight to table.
  table.insert(self.Qtakeoff, flight)
  
  -- Set flag to -1.
  flight.flag=-1
  
  -- New time stamp for time in pattern.
  flight.time=timer.getAbsTime()
  
  -- Init recovered switch.
  flight.tookoff=false
  for _,elem in pairs(flight.elements) do
    elem.tookoff=false
  end
  
end

--- Check if a group is in a queue.
-- @param #FLIGHTCONTROL self
-- @param #table queue The queue to check.
-- @param Wrapper.Group#GROUP group The group to be checked.
-- @return #boolean If true, group is in the queue. False otherwise.
function FLIGHTCONTROL:_InQueue(queue, group)
  local name=group:GetName()
  for _,_flight in pairs(queue) do
    local flight=_flight  --#FLIGHTCONTROL.FlightGroup
    if name==flight.groupname then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Flight and Element Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new flight group. Usually when a flight appears in the CCA.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #FLIGHTCONTROL.FlightGroup Flight group.
function FLIGHTCONTROL:_CreateFlightGroup(group)
  
  -- Check if not already in flights
  if self:_InQueue(self.flights, group) then
    return
  end
  
  -- Debug info.
  self:T(self.lid..string.format("Creating new flight for group %s of aircraft type %s.", group:GetName(), group:GetTypeName()))    
  
  -- New flight.
  local flight={} --#FLIGHTCONTROL.FlightGroup
  
  -- Flight group name
  local groupname=group:GetName()
  local human, playername=self:_IsHuman(group)
  
  -- Queue table item.    
  flight.group=group
  flight.groupname=group:GetName()
  flight.nunits=#group:GetUnits()
  flight.time=timer.getAbsTime()
  flight.dist0=group:GetCoordinate():Get2DDistance(self:GetCoordinate())
  flight.flag=-100
  flight.ai=not human
  flight.actype=group:GetTypeName()
  flight.onboardnumbers=self:_GetOnboardNumbers(group)
  flight.inzone=flight.group:IsCompletelyInZone(self.zoneAirbase)
  flight.holding=nil
      
  -- Flight elements.
  local text=string.format("Flight elements of group %s:", flight.groupname)
  
  flight.elements={}
  local units=group:GetUnits()
  for i,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    local element={} --#FLIGHTCONTROL.FlightElement
    element.unit=unit
    element.unitname=unit:GetName()
    element.onboard=flight.onboardnumbers[element.unitname]
    element.sizemax=unit:GetObjectSize()
    element.ai=not self:_IsHumanUnit(unit)
    
    -- Debug text.
    text=text..string.format("\n[%d] %s onboard #%s, AI=%s", i, element.unitname, tostring(element.onboard), tostring(element.ai))
    
    -- Add to table.
    table.insert(flight.elements, element)
  end
  self:T(self.lid..text)  
  
  -- Onboard.
  if flight.ai then
    local onboard=flight.onboardnumbers[flight.seclead]
    flight.onboard=onboard
  else
    flight.onboard=self:_GetOnboardNumberPlayer(group)
  end
  
  -- Add to known flights.
  table.insert(self.flights, flight)
    
  return flight
end

--- Get flight from group. 
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Group that will be removed from queue.
-- @param #table queue The queue from which the group will be removed.
-- @return #FLIGHTCONTROL.FlightGroup Flight group or nil.
-- @return #number Queue index or nil.
function FLIGHTCONTROL:_GetFlightFromGroup(group)

  if group then

    -- Group name
    local name=group:GetName()
    
    -- Loop over all flight groups in queue
    for i,_flight in pairs(self.flights) do
      local flight=_flight --#FLIGHTCONTROL.FlightGroup
      
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
-- @return #FLIGHTCONTROL.FlightGroup The Flight group or nil.
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

--- Remove element from flight.
-- @param #FLIGHTCONTROL self
-- @param #string unitname Name of the unit.
-- @return #boolean If true, element could be removed or nil otherwise.
function FLIGHTCONTROL:_RemoveFlightElement(unitname)

  -- Get table index.
  local element,idx, flight=self:_GetFlightElement(unitname)

  if idx then
    table.remove(flight.elements, idx)
    return true
  else
    self:T("WARNING: Flight element could not be removed from flight group. Index=nil!")
    return nil
  end
end

--- Get parking spot of flight element.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.FlightElement element Element of flight group.
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
    local airborne=unit:IsAir()
    local inzone=unit:IsInZone(self.zoneAirbase)
    local friendly=self:GetCoalition()==unit:GetCoalition()
    
    -- Check if this an aircraft and that it is airborne and closing in.
    if airborne and inzone and friendly then
    
      local group=unit:GetGroup()
      local groupname=group:GetName()
      
      -- Add group to table.
      if insideZone[groupname]==nil then
        insideZone[groupname]=group
      end
      
    end
  end
  
  -- Find new flights that are inside CCA.
  for groupname,_group in pairs(insideZone) do
    local group=_group --Wrapper.Group#GROUP
    self:_CreateFlightGroup(group)
  end
  
  for _,_flight in pairs(self.flights) do
    local flight=_flight --#FLIGHTCONTROL.FlightGroup
    
    local inzone=flight.group:IsCompletelyInZone(self.zoneAirbase)
    
    if inzone and not flight.inzone then
      flight.inzone=true
      flight.dist0=flight.group:GetCoordinate():Get2DDistance(self:GetCoordinate())
    end

    -- Set currently in zone or not.    
    flight.inzone=inzone  
  end
  
  
  for _,_flight in pairs(self.flights) do
    local flight=_flight --#FLIGHTCONTROL.FlightGroup
        
    --TODO: Check if aircraft has a landing waypoint for this airbase.
    
    -- Get distance to carrier.
    local dist=flight.group:GetCoordinate():Get2DDistance(self:GetCoordinate())
    
    -- Close in distance. Is >0 if AC comes closer wrt to first detected distance d0.
    local closein=flight.dist0-dist
    
    -- TODO refine for current case.
    
    -- Flight closed in.
    if closein>UTILS.NMToMeters(5) and flight.group:IsAirborne(true) then
    
      -- Debug info.
      self:T3(self.lid..string.format("AI flight group %s closed in by %.1f NM", flight.groupname, UTILS.MetersToNM(closein)))    
      
      -- Send AI to orbit outside 10 NM zone and wait until the next Marshal stack is available.
      if not (self:_InQueue(self.Qwaiting, flight.group) or self:_InQueue(self.Qlanding, flight.group)) then
        self:_WaitAI(flight, 1, true)
      end
      
      -- Break the loop to not have all flights at once! Spams the message screen.
      break
    end
          
  end  

end

--- Command AI flight to orbit.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.FlightGroup flight Flight group.
-- @param #number stack Holding stack.
-- @param #boolean respawn If true respawn the group. Otherwise reset the mission task with new waypoints.
function FLIGHTCONTROL:_WaitAI(flight, stack, respawn)

  -- Set flag to something other than -100 and <0
  flight.flag=stack

  -- Add AI flight to waiting queue.
  table.insert(self.Qwaiting, flight)

  -- Flight group name.
  local group=flight.group
  local groupname=flight.groupname
  
  ----------------
  -- Set Speeds --
  ----------------

  -- Aircraft speed 274 knots TAS ~= 250 KIAS when orbiting the pattern. (Orbit expects m/s.)
  local speedOrbitMps=UTILS.KnotsToMps(274)
  
  -- Orbit speed in km/h for waypoints.
  local speedOrbitKmh=UTILS.KnotsToKmph(274)
  
  -- Aircraft speed 400 knots when transiting to holding zone. (Waypoint expects km/h.)
  local speedTransit=UTILS.KnotsToKmph(370)
  
  ---------------
  -- Waypoints --
  ---------------

  -- Waypoints array to be filled depending on case etc.
  local wp={}

  -- Current position. Always good for as the first waypoint.
  wp[1]=group:GetCoordinate():WaypointAirTurningPoint(nil, speedTransit, {}, "Current Position")
  
  -- Task function when arriving at the holding zone. This will set flight.holding=true.
  local TaskHolding=flight.group:TaskFunction("FLIGHTCONTROL._ReachedHoldingZone", self, flight)
  
  -- Holding point.
  local holding=self:_GetHoldingpoint(flight)
  local altitude=holding.pos0.y
  local angels=UTILS.MetersToFeet(altitude)/1000
  
  -- Set orbit task.
  local TaskOrbit=group:TaskOrbit(holding.pos0, altitude, speedOrbitMps, holding.pos1)
  
  -- Orbit at waypoint.
  wp[#wp+1]=holding.pos0:WaypointAirTurningPoint(nil, speedOrbitKmh, {TaskHolding, TaskOrbit}, string.format("Holding at Angels %d", angels))
  
  -- Debug markers.
  if self.Debug then
    holding.pos0:MarkToAll(string.format("Waiting Orbit of flight %s at Angels %s", groupname, angels))
  end
  
  if respawn then
  
    -- This should clear the landing waypoints.  
    -- Note: This resets the weapons and the fuel state. But not the units fortunately.

    -- Get group template.
    local Template=group:GetTemplate()
    
    -- Set route points.
    Template.route.points=wp
    
    -- Respawn the group.
    group=group:Respawn(Template, true)  
    
  end
  
  -- Reinit waypoints.
  group:WayPointInitialize(wp)
  
  -- Route group.
  group:Route(wp, 1)
  
end

--- Tell AI to land at the airbase. Flight is added to the landing queue.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.FlightGroup flight Flight group.
function FLIGHTCONTROL:_LandAI(flight)

   -- Debug info.
  self:T(self.lid..string.format("Landing AI flight %s.", flight.groupname))
        
  -- Airbase position.
  local airbase=self.airbase:GetCoordinate()
  
  -- Waypoints array.
  local wp={}
  
  -- Current speed.
  local CurrentSpeed=flight.group:GetVelocityKMH()
  
  -- Aircraft speed when flying the pattern.
  local Speed=UTILS.KnotsToKmph(150)

  -- Current positon.
  wp[#wp+1]=flight.group:GetCoordinate():WaypointAirTurningPoint(nil, CurrentSpeed, {}, "Current position")
  
  
  -- Get active runway.
  local runway=self:_GetActiveRunway()
  
  -- TODO: make dependend on AC type helos etc.
  
  -- Approach point: 10 NN in direction of runway.
  local papproach=runway.position:Translate(UTILS.NMToMeters(10), runway.direction):SetAltitude(1000)
  papproach:MarkToAll("Approach Point")
  
  -- Approach waypoint.
  wp[#wp+1]=papproach:WaypointAirTurningPoint(nil ,Speed, {}, "Final Approach")

  -- Landing waypoint.
  wp[#wp+1]=airbase:WaypointAirLanding(Speed, self.airbase, nil, "Landing")

  -- Reinit waypoints.
  flight.group:WayPointInitialize(wp)
  
  -- Route group.
  flight.group:Route(wp, 1)
  
  -- Add flight to landing queue.
  table.insert(self.Qlanding, flight)
end

--- Function called when a group has reached the holding zone.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTCONTROL flightcontrol Flightcontrol object.
--@param #FLIGHTCONTROL.FlightGroup flight Flight group that has reached the holding zone.
function FLIGHTCONTROL._ReachedHoldingZone(group, flightcontrol, flight)

  -- Debug message.
  local text=string.format("Flight %s reached holding zone.", group:GetName())
  MESSAGE:New(text,10):ToAllIf(flightcontrol.Debug)
  flightcontrol:T(flightcontrol.lid..text)
 
  -- Debug mark.
  if flightcontrol.Debug then
    group:GetCoordinate():MarkToAll(text)
  end
  
  -- Set holding flag true and set timestamp for marshal time check.
  if flight then
    flight.holding=true
    flight.time=timer.getAbsTime()
  end
end

--- Get holding point.
-- @param #FLIGHTCONTROL self
-- @param #FLIGHTCONTROL.FlightGroup flight Flight group.
-- @return #FLIGHTCONTROL.HoldingPoint Holding point.
function FLIGHTCONTROL:_GetHoldingpoint(flight)

  local holdingpoint={} --#FLIGHTCONTROL.HoldingPoint
  
  local runway=self:_GetActiveRunway()
  
  local hdg=runway.direction+90
  local dx=UTILS.NMToMeters(5)
  local dz=UTILS.NMToMeters(1)
  
  local angels=UTILS.FeetToMeters(math.random(6,10)*1000)
  
  holdingpoint.pos0=runway.position:Translate(dx, hdg):SetAltitude(angels)
  holdingpoint.pos1=holdingpoint.pos0:Translate(dz, runway.direction):SetAltitude(angels)

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

--- Checks if a human player sits in the unit.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #boolean If true, human player inside the unit.
function FLIGHTCONTROL:_IsHumanUnit(unit)
  
  -- Get player unit or nil if no player unit.
  local playerunit=self:_GetPlayerUnitAndName(unit:GetName())
  
  if playerunit then
    return true
  else
    return false
  end
end

--- Checks if a group has a human player.
-- @param #FLIGHTCONTROL self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #boolean If true, human player inside group.
function FLIGHTCONTROL:_IsHuman(group)

  -- Get all units of the group.
  local units=group:GetUnits()
  
  -- Loop over all units.
  for _,_unit in pairs(units) do
    -- Check if unit is human.
    local human=self:_IsHumanUnit(_unit)
    if human then
      return true
    end
  end

  return false
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FLIGHTCONTROL self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FLIGHTCONTROL:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end



