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


--- SQUADRON class.
-- @type SQUADRON
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string sid Class id string for output to DCS log file.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\SQUADRON_Main.jpg)
--
-- # The SQUADRON Concept
--
--
--
-- @field #SQUADRON
SQUADRON = {
  ClassName      = "SQUADRON",
  Debug          =   nil,
  sid            =   nil,
  assets         =    {},
  livery         =   nil,
  tasks          =    {},
}



--- SQUADRON class version.
-- @field #string version
SQUADRON.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add tasks.
-- TODO:

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SQUADRON object and start the FSM.
-- @param #SQUADRON self
-- @param #string squadronname Name of the squadron, e.g. "VFA-37".
-- @param #table Table of squadron tasks, e.g. {SQUADRON.Task.INTERCEPT, SQUADRON.Task.SEAD}.
-- @return #SQUADRON self
function SQUADRON:New(squadronname, tasks)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #SQUADRON

  --self.flightgroup=AIGroup
  self.squadronname=tostring(name)

  -- Set some string id for output to DCS.log file.
  self.sid=string.format("SQUADRON %s | ", self.squadronname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()
  
  self.assets={}
  
  self.tasks=tasks or {}
  
  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",            "Running")     -- Start FSM.

  self:AddTransition("*",             "FlightStatus",     "*")           -- SQUADRON status update

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the SQUADRON. Initializes parameters and starts event handlers.
  -- @function [parent=#SQUADRON] Start
  -- @param #SQUADRON self

  --- Triggers the FSM event "Start" after a delay. Starts the SQUADRON. Initializes parameters and starts event handlers.
  -- @function [parent=#SQUADRON] __Start
  -- @param #SQUADRON self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the SQUADRON and all its event handlers.
  -- @param #SQUADRON self

  --- Triggers the FSM event "Stop" after a delay. Stops the SQUADRON and all its event handlers.
  -- @function [parent=#SQUADRON] __Stop
  -- @param #SQUADRON self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#SQUADRON] FlightStatus
  -- @param #SQUADRON self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#SQUADRON] __FlightStatus
  -- @param #SQUADRON self
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







