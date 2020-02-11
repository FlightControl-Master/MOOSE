--- **Ops** - (R2.5) - AI Squadron for Ops.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Squadron
-- @image OPS_Squadron.png


--- AUFKLAERUNG class.
-- @type AUFKLAERUNG
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string sid Class id string for output to DCS log file.
-- @field #string livery Livery of the squadron.
-- @field #table flights Table of flight groups.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\AUFKLAERUNG_Main.jpg)
--
-- # The AUFKLAERUNG Concept
--
--
--
-- @field #AUFKLAERUNG
AUFKLAERUNG = {
  ClassName      = "AUFKLAERUNG",
  Debug          =   nil,
  lid            =   nil,
  detectionset   =   nil,
  detecteditems  =    {},
}

--- Flight group element.
-- @type AUFKLAERUNG.DetectedItem
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group object.
-- @field #string mission Mission assigned to the flight.

--- AUFKLAERUNG class version.
-- @field #string version
AUFKLAERUNG.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add tasks.
-- TODO:

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AUFKLAERUNG object and start the FSM.
-- @param #AUFKLAERUNG self
-- @param Core.Set#SET_GROUP DetectionSet Set of detection groups.
-- @return #AUFKLAERUNG self
function AUFKLAERUNG:New(DetectionSet)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #AUFKLAERUNG

  --self.flightgroup=AIGroup
  self.detectionset=DetectionSet
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AUFKLAERUNG %s | ", self.squadronname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- AUFKLAERUNG status update
  
  self:AddTransition("*",             "Detect",             "*")           -- AUFKLAERUNG status update
  
  self:AddTransition("*",             "DetectedUnit",       "*")           --

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the AUFKLAERUNG. Initializes parameters and starts event handlers.
  -- @function [parent=#AUFKLAERUNG] Start
  -- @param #AUFKLAERUNG self

  --- Triggers the FSM event "Start" after a delay. Starts the AUFKLAERUNG. Initializes parameters and starts event handlers.
  -- @function [parent=#AUFKLAERUNG] __Start
  -- @param #AUFKLAERUNG self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the AUFKLAERUNG and all its event handlers.
  -- @param #AUFKLAERUNG self

  --- Triggers the FSM event "Stop" after a delay. Stops the AUFKLAERUNG and all its event handlers.
  -- @function [parent=#AUFKLAERUNG] __Stop
  -- @param #AUFKLAERUNG self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#AUFKLAERUNG] SquadronStatus
  -- @param #AUFKLAERUNG self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#AUFKLAERUNG] __SquadronStatus
  -- @param #AUFKLAERUNG self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  self.Debug=true


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set livery.
-- @param #AUFKLAERUNG self
-- @param #string liveryname Name of the livery.
-- @return #AUFKLAERUNG self
function AUFKLAERUNG:SetLivery(liveryname)
  self.livery=liveryname
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #AUFKLAERUNG self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFKLAERUNG:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group %s.", self.groupname)
  self:I(self.sid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "FlightStatus" event.
-- @param #AUFKLAERUNG self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AUFKLAERUNG:onafterSquadronStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckFlightStatus()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d", fsmstate, #self.element, #self.element, self.taskcurrent, #self.taskqueue, self.currentwp or 0, #self.waypoints or 0, self.detectedunits:Count())
  self:I(self.sid..text)
  
  
end


--- On after "FlightStatus" event.
-- @param #AUFKLAERUNG self
function AUFKLAERUNG:_CheckFlightstatus()

  for _,_flight in pairs(self.flights) do
    local flight=_flight --#AUFKLAERUNG.Flight
    
    flight.flightgroup:IsSpawned()
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------







