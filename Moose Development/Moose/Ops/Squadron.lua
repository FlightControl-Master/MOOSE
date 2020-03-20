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
-- @field Wrapper.Group#GROUP templategroup Template group.
-- @field #table assets Squadron assets.
-- @field #table missiontypes Mission types the squadron can perform.
-- @field #string livery Livery of the squadron.
-- @field #number skill Skill of squadron members.
-- @field Ops.AirWing#AIRWING airwing The AIRWING object the squadron belongs to.
-- @field #number Ngroups Number of asset flight groups this squadron has. 
-- @field #number engageRange Engagement range in meters.
-- @field #string attribute Generalized attribute of the squadron template group.
-- @field #number tankerSystem For tanker squads, the refuel system used (boom=0 or probpe=1). Default nil.
-- @field #number refuelSystem For refuelable squads, the refuel system used (boom=0 or probpe=1). Default nil.
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
  engageRange    =   nil,
  tankerSystem   =   nil,
  refuelSystem   =   nil,
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

-- DONE: Engage radius.
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

  -- Name of the template group.
  self.templatename=TemplateGroupName

  -- Squadron name.
  self.name=tostring(SquadronName or TemplateGroupName)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("SQUADRON %s | ", self.name)

  
  -- Template group.
  self.templategroup=GROUP:FindByName(self.templatename)
  
  -- Check if template group exists.
  if not self.templategroup then
    self:E(self.lid..string.format("ERROR: Template group %s does not exist!", tostring(self.templatename)))
    return nil
  end
  
  -- Defaults.
  self.Ngroups=Ngroups or 3  
  self:SetEngagementRange()
  
  self.attribute=self.templategroup:GetAttribute()
  
  _,self.refuelSystem=self.templategroup:GetUnit(1):IsRefuelable()
  _,self.tankerSystem=self.templategroup:GetUnit(1):IsTanker()


  -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- Status update.
  self:AddTransition("Running",       "Pause",              "Paused")      -- Pause squadron.
  self:AddTransition("Paused",        "Unpause",            "Running")     -- Unpause squadron.
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop squadron.


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
-- @param #string Skill Skill of all flights.
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

--- Get mission types this squadron is able to perform.
-- @param #SQUADRON self
-- @param #table MissionTypes Table of mission types.
function SQUADRON:GetMissonTypes()
  return self.missiontypes
end

--- Set max engagement range.
-- @param #SQUADRON self
-- @param #number EngageRange Engagement range in NM. Default 80 NM.
-- @return #SQUADRON self
function SQUADRON:SetEngagementRange(EngageRange)
  self.engageRange=UTILS.NMToMeters(EngageRange or 80)
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

  for _,_asset in pairs(self.assets) do
    local asset=_asset --#SQUADRON.Flight
    
    flight.flightgroup:IsSpawned()
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if there is a squadron that can execute a given mission type. Optionally, the number of required assets can be specified.
-- @param #SQUADRON self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If true, Squadron can do that type of mission.
-- @return #table Assets that can do the required mission.
function SQUADRON:CanMission(Mission)
  
  -- Assets available for this mission.
  local assets={}

  -- WARNING: This assumes that all assets of the squad can do the same mission types!
  local cando=self:CheckMissionType(Mission.type, self.missiontypes)
  
  -- Check that tanker mission
  if cando and Mission.type==AUFTRAG.Type.TANKER then
  
    if Mission.refuelSystem and Mission.refuelSystem==self.tankerSystem then
      -- Correct refueling system.
    else
      self:I(self.lid..string.format("wrong refuling system mi=%s ta=%s", tostring(Mission.refuelSystem), tostring(self.tankerSystem)))
      cando=false
    end
  
  end
  
  if cando then
      
    local TargetDistance=Mission:GetTargetDistance(self.airwing:GetCoordinate())
    
    for _,_asset in pairs(self.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      -- Set range is valid.
      if TargetDistance<=self.engageRange then
      
        -- Check if asset is currently on a mission (STARTED or QUEUED).
        if self.airwing:IsAssetOnMission(asset) then
  
          ---
          -- This asset is already on a mission
          ---
  
          -- Check if this asset is currently on a PATROL mission (STARTED or EXECUTING).
          if self.airwing:IsAssetOnMission(asset, AUFTRAG.Type.PATROL) and Mission.type~=AUFTRAG.Type.PATROL then
  
            -- Check if the payload of this asset is compatible with the mission.
            if self:CheckMissionType(Mission.type, asset.payload.missiontypes) then
              -- TODO: Check if asset actually has weapons left. Difficult!
              table.insert(assets, asset)
            end
            
          end      
        
        else
        
          ---
          -- This asset as no current mission
          ---
  
          if asset.spawned then
          
            local combatready=false
            local flightgroup=asset.flightgroup
            if flightgroup then
            
              if (flightgroup:IsAirborne() or flightgroup:IsWaiting()) and not flightgroup:IsFuelLow() then
                combatready=true
              end
            
            end
          
            -- This asset is "combatready". Let's check if it has the right payload.
            if combatready and self:CheckMissionType(Mission.type, asset.payload.missiontypes) then
              table.insert(assets, asset)
            end
            
          else
          
            if not asset.requested then
          
              -- Check if we got a payload and reserve it for this asset.
              local payload=self.airwing:FetchPayloadFromStock(asset.unittype, Mission.type)
              if payload then
                asset.payload=payload
                table.insert(assets, asset)
              end
              
            end
          end
          
        end
        
      end
    end
  end
  
  -- Check if required assets are present.
  if Mission.nassets and Mission.nassets > #assets then
    cando=false
  end

  return cando, assets
end


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

