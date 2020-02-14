--- **Ops** - Office of Military Intelligence.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Intel
-- @image OPS_Intel.png


--- INTEL class.
-- @type INTEL
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\INTEL_Main.jpg)
--
-- # The INTEL Concept
--
--
--
-- @field #INTEL
INTEL = {
  ClassName      = "INTEL",
  Debug          =   nil,
  lid            =   nil,
  filter         =   nil,
  detectionset   =   nil,
  detecteditems  =    {},
  DetectedGroups =    {}
}

--- Detected item info.
-- @type INTEL.DetectedItem
-- @field #string typename Type name of detected item.
-- @field #number category
-- @field #string categeryname
-- @field #number Tdetected Time stamp when this item was last detected.

--- INTEL class version.
-- @field #string version
INTEL.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new INTEL object and start the FSM.
-- @param #INTEL self
-- @param Core.Set#SET_GROUP DetectionSet Set of detection groups.
-- @return #INTEL self
function INTEL:New(DetectionSet)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #INTEL

  --self.flightgroup=AIGroup
  self.detectionset=DetectionSet
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("INTEL %s | ", "KGB")

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "Detect",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "DetectedUnit",       "*")           --
  
  self:AddTransition("*",             "DetectedGroups",        "*")        -- All groups that are currently detected.
  self:AddTransition("*",             "DetectedGroupsUnknown", "*")        -- Newly detected groups, which were previously unknown.
  self:AddTransition("*",             "DetectedGroupsDead",     "*")       -- Previously detected groups that could not be detected any more.
  self:AddTransition("*",             "DetectedGroupsLost",    "*")        -- Previously detected groups that could not be detected any more.
  

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the INTEL. Initializes parameters and starts event handlers.
  -- @function [parent=#INTEL] Start
  -- @param #INTEL self

  --- Triggers the FSM event "Start" after a delay. Starts the INTEL. Initializes parameters and starts event handlers.
  -- @function [parent=#INTEL] __Start
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the INTEL and all its event handlers.
  -- @param #INTEL self

  --- Triggers the FSM event "Stop" after a delay. Stops the INTEL and all its event handlers.
  -- @function [parent=#INTEL] __Stop
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#INTEL] Status
  -- @param #INTEL self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#INTEL] __Status
  -- @param #INTEL self
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
-- @param #INTEL self
-- @param #string liveryname Name of the livery.
-- @return #INTEL self
function INTEL:SetLivery(liveryname)
  self.livery=liveryname
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #INTEL self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function INTEL:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group %s.", self.groupname)
  self:I(self.sid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "Status" event.
-- @param #INTEL self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function INTEL:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:UpdateIntel()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d", fsmstate, #self.element, #self.element, self.taskcurrent, #self.taskqueue, self.currentwp or 0, #self.waypoints or 0, self.detectedunits:Count())
  self:I(self.sid..text)
  

  self:__Status(-30) 
end


--- Update detected items.
-- @param #INTEL self
function INTEL:UpdateIntel()

  -- Set of all detected units.
  local DetectedSet=SET_UNIT:New()

  -- Loop over all units providing intel.
  for _,_recce in pairs(self.detectionset:GetSet()) do
    local recce=_recce --Wrapper.Unit#UNIT
    
    -- Get set of detected units.
    local detectedunitset=recce:GetDetectedUnitSet()
    
    -- Add detected units to all set.
    DetectedSet=DetectedSet:GetSetUnion(detectedunitset)
    
  end
  
  -- Newly detected units.
  local detectednew=DetectedSet:GetSetComplement(self.detectedunits)
  
  -- Previously detected units which got lost.
  local detectedlost=self.detectedunits:GetSetComplement(DetectedSet)
  
  -- TODO: Loose units only if they remain undetected for a given time interval. We want to avoid fast oscillation between detected/lost states. Maybe 1-5 min would be a good time interval?!
  -- TODO: Combine units to groups for all, new and lost.
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------







