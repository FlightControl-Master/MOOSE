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
-- @field #string name Name of the squadron.
-- @field #string templatename Name of the template group.
-- @field #table assets Squadron assets.
-- @field #table missiontypes Mission types the squadron can perform.
-- @field #string livery Livery of the squadron.
-- @field #number skill Skill of squadron members.
-- @field Ops.AirWing#AIRWING airwing The AIRWING object the squadron belongs to.
-- @field #number Ngroups Number of asset flight groups this squadron has. 
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
  missiontypes   =    {},
  livery         =   nil,
  skill          =   nil,
  airwing        =   nil,
  Ngroups        =   nil,
}

--- Flight group element.
-- @type SQUADRON.Flight
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flight group object.
-- @field #string mission Mission assigned to the flight.

--- SQUADRON class version.
-- @field #string version
SQUADRON.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Engage radius.
-- TODO: Modex.
-- TODO: Call signs.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SQUADRON object and start the FSM.
-- @param #SQUADRON self
-- @param #string TemplateGroupName Name of the template group.
-- @param #number Ngroups Number of asset groups of this squadron. Default 3.
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @return #SQUADRON self
function SQUADRON:New(TemplateGroupName, Ngroups, SquadronName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #SQUADRON

  self.templatename=TemplateGroupName
  
  self.Ngroups=Ngroups or 3

  --self.flightgroup=AIGroup
  self.name=tostring(SquadronName or TemplateGroupName)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("SQUADRON %s | ", self.name)

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
-- @param #string LiveryName Name of the livery.
-- @return #SQUADRON self
function SQUADRON:SetLivery(LiveryName)
  self.livery=LiveryName
  return self
end

--- Set skill.
-- @param #SQUADRON self
-- @param #string skill Skill of all flights.
-- @return #SQUADRON self
function SQUADRON:SetSkill(Skill)
  self.skill=Skill
  return self
end

--- Set mission types this squadron is able to perform.
-- @param #SQUADRON self
-- @param #table MissionTypes Table of mission types. Can also be passed as a #string if only one type.
-- @return #SQUADRON self
function SQUADRON:SetMissonTypes(MissionTypes)

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end
  
  -- Add ORBIT for all.  
  if not self:CheckMissionType(AUFTRAG.Type.ORBIT, MissionTypes) then
    table.insert(MissionTypes, AUFTRAG.Type.ORBIT)
  end

  -- Set table.
  self.missiontypes=MissionTypes
  
  self:I(self.missiontypes)
  
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
  --self:_CheckAssetStatus()

  -- Short info.
  local text=string.format("Status %s", fsmstate)
  self:I(self.sid..text)
  
  
  self:__Status(-30)
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
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Checks if a mission type is contained in a table of possible types.
-- @param #SQUADRON self
-- @param #string MissionType The requested mission type.
-- @param #table PossibleTypes A table with possible mission types.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function SQUADRON:CheckMissionType(MissionType, PossibleTypes)

  if type(PossibleTypes)=="string" then
    PossibleTypes={PossibleTypes}
  end

  for _,canmission in pairs(PossibleTypes) do
    if canmission==MissionType then
      return true
    end   
  end

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

