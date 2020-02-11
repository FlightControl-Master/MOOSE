--- **Ops** - (R2.5) - Wing Commander for Ops.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.WingCommander
-- @image OPS_WingCommander.png


--- WINGCOMMANDER class.
-- @type WINGCOMMANDER
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
-- ![Banner Image](..\Presentations\CarrierAirWing\WINGCOMMANDER_Main.jpg)
--
-- # The WINGCOMMANDER Concept
--
--
--
-- @field #WINGCOMMANDER
WINGCOMMANDER = {
  ClassName      = "WINGCOMMANDER",
  Debug          =   nil,
  lid            =   nil,
  airwings       =    {},
}

--- Flight group element.
-- @type WINGCOMMANDER.Flight
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group object.
-- @field #string mission Mission assigned to the flight.

--- WINGCOMMANDER class version.
-- @field #string version
WINGCOMMANDER.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add tasks.
-- TODO:

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new WINGCOMMANDER object and start the FSM.
-- @param #WINGCOMMANDER self
-- @param #string squadronname Name of the squadron, e.g. "VFA-37".
-- @param Wrapper.Airbase#AIRBASE airbase Home airbase object of the squadron.
-- @param #table Table of squadron tasks, e.g. {WINGCOMMANDER.Task.INTERCEPT, WINGCOMMANDER.Task.SEAD}.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:New(detection)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #WINGCOMMANDER

  --self.flightgroup=AIGroup
  self.squadronname=tostring(squadronname)
  
  -- Set home airbase.
  self.homebase=airbase

  -- Set some string id for output to DCS.log file.
  self.sid=string.format("WINGCOMMANDER %s | ", self.squadronname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()

  -- TODO Tasks?
  self.tasks=tasks or {}
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.

  self:AddTransition("*",             "WingCommanderStatus",     "*")           -- WINGCOMMANDER status update
  
  self:AddTransition("*",             "DetectedUnit",       "*")           --
  
  self:AddTransition("*",             "FlightSpawned",      "*")           --
  self:AddTransition("*",             "FlightAirborne",     "*")           --
  self:AddTransition("*",             "FlightDead",         "*")           --

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the WINGCOMMANDER. Initializes parameters and starts event handlers.
  -- @function [parent=#WINGCOMMANDER] Start
  -- @param #WINGCOMMANDER self

  --- Triggers the FSM event "Start" after a delay. Starts the WINGCOMMANDER. Initializes parameters and starts event handlers.
  -- @function [parent=#WINGCOMMANDER] __Start
  -- @param #WINGCOMMANDER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the WINGCOMMANDER and all its event handlers.
  -- @param #WINGCOMMANDER self

  --- Triggers the FSM event "Stop" after a delay. Stops the WINGCOMMANDER and all its event handlers.
  -- @function [parent=#WINGCOMMANDER] __Stop
  -- @param #WINGCOMMANDER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#WINGCOMMANDER] WingCommanderStatus
  -- @param #WINGCOMMANDER self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#WINGCOMMANDER] __WingCommanderStatus
  -- @param #WINGCOMMANDER self
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
-- @param #WINGCOMMANDER self
-- @param #string liveryname Name of the livery.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetLivery(liveryname)
  self.livery=liveryname
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WINGCOMMANDER:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group %s.", self.groupname)
  self:I(self.sid..text)

  -- Start the status monitoring.
  self:__WingCommanderStatus(-1)
end

--- On after "FlightStatus" event.
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WINGCOMMANDER:onafterWingCommanderStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckFlightStatus()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d", fsmstate, #self.element, #self.element, self.taskcurrent, #self.taskqueue, self.currentwp or 0, #self.waypoints or 0, self.detectedunits:Count())
  self:I(self.sid..text)
  
  
end

