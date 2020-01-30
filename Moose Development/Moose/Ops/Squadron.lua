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
-- @field #string livery Livery of the squadron.
-- @field #table flights Table of flight groups.
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
  flights        =    {},
  tasks          =    {},
  livery         =   nil,  
}

--- Flight group element.
-- @type SQUADRON.Flight
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group object.
-- @field #string mission Mission assigned to the flight.

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
-- @param Wrapper.Airbase#AIRBASE airbase Home airbase object of the squadron.
-- @param #table Table of squadron tasks, e.g. {SQUADRON.Task.INTERCEPT, SQUADRON.Task.SEAD}.
-- @return #SQUADRON self
function SQUADRON:New(squadronname, airbase, tasks)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #SQUADRON

  --self.flightgroup=AIGroup
  self.squadronname=tostring(squadronname)
  
  -- Set home airbase.
  self.homebase=airbase

  -- Set some string id for output to DCS.log file.
  self.sid=string.format("SQUADRON %s | ", self.squadronname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()

  -- TODO Tasks?
  self.tasks=tasks or {}
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.

  self:AddTransition("*",             "SquadronStatus",     "*")           -- SQUADRON status update
  
  self:AddTransition("*",             "DetectedUnit",       "*")           --
  
  self:AddTransition("*",             "FlightSpawned",      "*")           --
  self:AddTransition("*",             "FlightAirborne",     "*")           --
  self:AddTransition("*",             "FlightDead",         "*")           --

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
  -- @function [parent=#SQUADRON] SquadronStatus
  -- @param #SQUADRON self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#SQUADRON] __SquadronStatus
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set livery.
-- @param #SQUADRON self
-- @param #string liveryname Name of the livery.
-- @return #SQUADRON self
function SQUADRON:SetLivery(liveryname)
  self.livery=liveryname
end

--- Add a group to the squadron.
-- @param #SQUADRON self
-- @param #string groupname Name of the group as defined in the mission editor.
-- @param #number n Number of groups that is added.
-- @return #SQUADRON self
function SQUADRON:AddGroup(groupname, n)

  
  

end


--- Add flight group(s) to squadron.
-- @param #SQUADRON self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup Flight group.
-- @return #SQUADRON self
function SQUADRON:AddFlightGroup(flightgroup)

  local text=string.format("Adding flight group %s to squadron", flightgroup:GetName())
  self:I(self.sid..text)
  
  -- Set squadron.
  flightgroup:SetSquadron(self)
  
  table.insert(self.flightgroups, flightgroup)  

  function flightgroup:OnAfterDetectedUnit(From,Event,To,Unit)
    self:GetSquadron():DetectedUnit(Unit)
  end
  
  function flightgroup:OnAfterFlightAirborne(From,Event,To)
    self:GetSquadron():FlightAirborne(self)
  end  
  
  function flightgroup:OnAfterFlightDead(From,Event,To)
    self:GetSquadron():FlightDead(self)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #SQUADRON self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group %s.", self.groupname)
  self:I(self.sid..text)

  -- Start the status monitoring.
  self:__SquadronStatus(-1)
end

--- On after "FlightStatus" event.
-- @param #SQUADRON self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterSquadronStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckFlightStatus()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d", fsmstate, #self.element, #self.element, self.taskcurrent, #self.taskqueue, self.currentwp or 0, #self.waypoints or 0, self.detectedunits:Count())
  self:I(self.sid..text)
  
  
end


--- On after "FlightStatus" event.
-- @param #SQUADRON self
function SQUADRON:_CheckFlightstatus()

  for _,_flight in pairs(self.flights) do
    local flight=_flight --#SQUADRON.Flight
    
    flight.flightgroup:IsSpawned()
    
  end

end

