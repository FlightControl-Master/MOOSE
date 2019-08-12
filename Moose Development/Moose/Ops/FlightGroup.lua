--- **Ops** - (R2.5) - AI Flight Group for Ops.
--
-- **Main Features:**
--
--    * Nice stuff.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.FlightGroup
-- @image OPS_FlightGroup.png


--- FLIGHTGROUP class.
-- @type FLIGHTGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string sid Class id string for output to DCS log file.
-- @field #string groupname Name of flight group.
-- @field Wrapper.Group#GROUP flightgroup Flight group object.
-- @field #string type Aircraft type of flight group.
-- @field #table element Table of elements, i.e. units of the group.
-- @field #table taskqueue Queue of tasks.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\FLIGHTGROUP_Main.jpg)
--
-- # The FLIGHTGROUP Concept
--
--
--
-- @field #FLIGHTGROUP
FLIGHTGROUP = {
  ClassName      = "FLIGHTGROUP",
  sid            =   nil,
  groupname      =   nil,
  flightgroup    =   nil,
  type           =   nil,
  element        =    {},
  taskqueue      =    {},
  detectedunits  =   nil,
}


--- Status of flight group element.
-- @type FLIGHTGROUP.ElementStatus
-- @field #string SPAWNED Element was spawned into the world.
-- @field #string PARKING Element is parking after spawned on ramp.
-- @field #string TAXIING Element is taxiing after engine startup.
-- @field #string AIRBORNE Element is airborne after take off.
-- @field #string LANDED Element landed and is taxiing to its parking spot.
-- @field #string ARRIVED Element arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
FLIGHTGROUP.ElementStatus={
  SPAWNED="spawned",
  PARKING="parking",
  TAXIING="taxiing",
  AIRBORNE="airborne",
  LANDED="landed",
  ARRIVED="arrived",
  DEAD="dead",
}


--- Flight group element.
-- @type FLIGHTGROUP.Element
-- @field #string name Name of the element.
-- @field #number modex Tail number.
-- @field #boolean ai If true, element is AI.
-- @field #string skill Skill level.
-- @field Wrapper.Unit#UNIT unit Element unit object.
-- @field #string status Status, i.e. born, parking, taxiing.

--- Flight group tasks.
-- @type FLIGHTGROUP.Task
-- @param #string INTERCEPT Intercept task.
-- @param #string CAP Combat Air Patrol task.s
-- @param #string BAI Battlefield Air Interdiction task.
-- @param #string SEAD Suppression/destruction of enemy air defences.
-- @param #string STRIKE Strike task.
-- @param #string AWACS AWACS task.
-- @param #string TANKER Tanker task.
FLIGHTGROUP.Task={
  INTERCEPT="Intercept",
  CAP="CAP",
  BAI="BAI",
  SEAD="SEAD",
  STRIKE="Strike",
  CAS="CAS",
  AWACS="AWACS",
  TANKER="Tanker",
}

--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTGROUP object and start the FSM.
-- @param #FLIGHTGROUP self
-- @param #string groupname Name of the group.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:New(groupname)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #FLIGHTGROUP
  
  --self.flightgroup=AIGroup
  self.groupname=tostring(groupname)

  -- Set some string id for output to DCS.log file.
  self.sid=string.format("FLIGHTGROUP %s | ", self.groupname)

  -- Start State.
  self:SetStartState("Stopped")
  
  -- Check if the group is already alive and if so, add its elements.
  local group=GROUP:FindByName(groupname)
  if group and group:IsAlive() then
    self.flightgroup=group
    local units=group:GetUnits()
    for _,_unit in pairs(units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local element=self:AddElementByName(unit:GetName())
      if unit:InAir() then
        element.status=FLIGHTGROUP.ElementStatus.AIRBORNE
      else
        element.status=FLIGHTGROUP.ElementStatus.SPAWNED
      end
    end
  end
  
  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()


  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FSM.
  self:AddTransition("*",             "FlightStatus",    "*")           -- FLIGHTGROUP status update.
  self:AddTransition("*",             "ElementDead",     "*")           -- An element crashed, ejected, or pilot dead.
  self:AddTransition("*",             "FlightAirborne",  "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightLanded",    "Landed")      -- The whole flight group has laned.
  self:AddTransition("*",             "FlightArrived",   "Arrived")     -- The whole flight group has arrived.
  self:AddTransition("*",             "FlightDead",      "*")           -- The whole flight group is dead.
  self:AddTransition("*",             "AddDetectedUnit", "*")           -- Add a newly detected unit to the detected units set.


  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] Start
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Start" after a delay. Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] __Start
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the FLIGHTGROUP and all its event handlers.
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the FLIGHTGROUP and all its event handlers.
  -- @function [parent=#FLIGHTGROUP] __Stop
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#FLIGHTGROUP] FlightStatus
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#FLIGHTGROUP] __FlightStatus
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if true then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  
  self:Start()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get set of decteded units.
-- @param #FLIGHTGROUP self
-- @return Core.Set#SET_UNIT Set of detected units.
function FLIGHTGROUP:GetDetectedUnits()
  return self.detectedunits
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group %s.", self.groupname)
  self:I(self.sid..text)

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self.OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self.OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self.OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self.OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self.OnEventEngineShutdown)
  self:HandleEvent(EVENTS.PilotDead,      self.OnEventPilotDead)
  self:HandleEvent(EVENTS.Ejection,       self.OnEventEjection)
  self:HandleEvent(EVENTS.Crash,          self.OnEventCrash)

  -- Start the status monitoring.
  self:__FlightStatus(-1)
end

--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  -- Short info.
  local text=string.format("Flight group FSM status %s.", fsmstate)
  self:I(self.sid..text)
  
  text="Elements:"
  for i,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element
    local name=element.name
    local status=element.status
    local unit=element.unit
    local fuel=unit:GetFuel() or 0
    local life=unit:GetLifeRelative() or 0
    
    text=text..string.format("\n[%d] %s: status=%s, fuel=%.1f, life=%.1f", i, name, status, fuel*100, life*100)
  end
  if #self.element==0 then
    text=text.." none!"
  end
  self:I(text)
  
  -- Get detected DCS units.
  local detectedtargets=self.flightgroup:GetDetectedTargets()
  
  for DetectionObjectID, Detection in pairs(detectedtargets) do
    local DetectedObject=Detection.object -- DCS#Object
          
    if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then
      local unit=UNIT:Find(DetectedObject)
      if unit and unit:IsAlive() then
        local unitname=unit:GetName()
        if self.detectedunits:FindUnit(unitname) then
          -- Unit is already in the detected unit set.
          self:I(self.sid..string.format("Detected unit %s is already known.", unitname))
        else
          self:AddDetectedUnit(unit)
        end
      end
    end
  end
  
  -- Next check in ~30 seconds.
  self:__FlightStatus(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Flightgroup event function, handling the birth of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName
    
    self.flightgroup=self.flightgroup or EventData.IniGroup
    
    if not self:_IsElement(unitname) then
      local element=self:AddElementByName(unitname)
      element.status=FLIGHTGROUP.ElementStatus.SPAWNED
    end
    
  end
  
end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineStartup(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName  

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then    
      element.status=FLIGHTGROUP.ElementStatus.TAXIING
    end
  
  end
  
end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventTakeOff(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName  

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then    
      element.status=FLIGHTGROUP.ElementStatus.AIRBORNE
    end
  
  end
  
end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventLanding(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName  

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then    
      element.status=FLIGHTGROUP.ElementStatus.LANDED
    end
  
  end
  
end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineShutdown(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName  

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      local coord=unit:GetCoordinate()
      local airbase=coord:GetClosestAirbase()
      local _,_,dist,parking=coord:GetClosestParkingSpot(airbase)
      if dist and dist<10 and unit:InAir()==false then
        element.status=FLIGHTGROUP.ElementStatus.ARRIVED
      else
         element.status=FLIGHTGROUP.ElementStatus.DEAD
      end
    end
  
  end
  
end


--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventCrash(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      element.status=FLIGHTGROUP.ElementStatus.DEAD
    end

  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "DetectedUnit" event. Add newly detected unit to detected units set.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit
-- @parma #string assignment The (optional) assignment for the asset.
function FLIGHTGROUP:onafterAddDetectedUnit(From, Event, To, Unit)
  self:I(self.sid..string.format("Detected unit %s.", Unit:GetName()))
  self.detectedunits:AddUnit(Unit)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an element to the flight group.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element or nil.
function FLIGHTGROUP:AddElementByName(unitname)

  local unit=UNIT:FindByName(unitname)
  
  if unit then
  
    local element={} --#FLIGHTGROUP.Element
    
    element.name=unitname
    element.unit=unit
    element.status="unknown"
    
    table.insert(self.element, element)
    
    return element
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element.
function FLIGHTGROUP:GetElementByName(unitname)

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element
    
    if element.name==unitname then
      return element
    end
  
  end

  return nil
end


--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #boolean If true, unit is element of the flight group or false if otherwise.
function FLIGHTGROUP:_IsElement(unitname)

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element
    
    if element.name==unitname then
      return true
    end
  
  end

  return false
end

--- Check if all elements of the flight group have the same status or are dead.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
function FLIGHTGROUP:_AllStatus(status)

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element
    
    if element.status==FLIGHTGROUP.ElementStatus.DEAD then
      -- Do nothing. Element is already dead and does not count.
    elseif element.status~=status then
      -- At least this element has a different status.
      return false
    end
  
  end
  
  if status==FLIGHTGROUP.ElementStatus.DEAD then
    -- All elements are dead.
    self:FlightDead()
  elseif status==FLIGHTGROUP.ElementStatus.ARRIVED then
    self:FlightArrived()
  elseif status==FLIGHTGROUP.ElementStatus.AIRBORNE then
    self:FlightAirborne()
  end

  return true
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
