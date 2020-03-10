--- **Ops** - Airwing Squadron.
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
-- @field #string lid Class id string for output to DCS log file.
-- @field #string livery Livery of the squadron.
-- @field #table assets Table of assets.
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
  lid            =   nil,
  name           =   nil,
  templatename   =   nil,
  assets         =    {},
  livery         =   nil,
  skill          =   nil,
  airwing        =   nil,
}

--- Flight group element.
-- @type SQUADRON.Flight
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group object.
-- @field #string mission Mission assigned to the flight.

--- SQUADRON class version.
-- @field #string version
SQUADRON.version="0.0.2"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add tasks.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SQUADRON object and start the FSM.
-- @param #SQUADRON self
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @param #string TemplateGroupName Name of the template group.
-- @return #SQUADRON self
function SQUADRON:New(SquadronName, TemplateGroupName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #SQUADRON

  self.templatename=TemplateGroupName

  --self.flightgroup=AIGroup
  self.name=tostring(SquadronName or TemplateGroupName)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("SQUADRON %s | ", self.squadronname)

  -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- SQUADRON status update


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

  --- Triggers the FSM event "Status".
  -- @function [parent=#SQUADRON] Status
  -- @param #SQUADRON self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#SQUADRON] __Status
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
  return self
end

--- Set airwing.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING Airwing The airwing.
-- @return #SQUADRON self
function SQUADRON:SetAirwing(Airwing)
  self.airwing=Airwing
  return self
end

--- Add airwing asset to squadron.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The airwing asset.
-- @return #SQUADRON self
function SQUADRON:AddAsset(Asset)
  table.insert(self.assets, Asset)
  return self
end

--- Remove airwing asset from squadron.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The airwing asset.
-- @return #SQUADRON self
function SQUADRON:DelAsset(Asset)
  for i,_asset in pairs(self.assets) do
    local asset=_asset --Ops.AirWing#AIRWING.SquadronAsset
    if Asset.uid==asset.uid then
      table.remove(self.assets, i)
      break
    end
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
  local text=string.format("Starting SQUADRON %s.", self.name)
  self:I(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "Status" event.
-- @param #SQUADRON self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckAssetStatus()

  -- Short info.
  --local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d", fsmstate, #self.element, #self.element, self.taskcurrent, #self.taskqueue, self.currentwp or 0, #self.waypoints or 0, self.detectedunits:Count())
  --self:I(self.sid..text)
  
end


--- Check asset status.
-- @param #SQUADRON self
function SQUADRON:_CheckAssetStatus()

  for _,_assets in pairs(self.assets) do
    local asset=_asset --#SQUADRON.Flight
    
    flight.flightgroup:IsSpawned()
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

