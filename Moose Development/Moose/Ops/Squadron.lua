--- **Ops** - Airwing Squadron.
--
-- **Main Features:**
--
--    * Set parameters like livery, skill valid for all squadron members.
--    * Define modex and callsigns.
--    * Define mission types, this squadron can perform (see Ops.Auftrag#AUFTRAG).
--    * Pause/unpause squadron operations.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Squadron
-- @image OPS_Squadron.png


--- SQUADRON class.
-- @type SQUADRON
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the squadron.
-- @field #string templatename Name of the template group.
-- @field #string aircrafttype Type of the airframe the squadron is using.
-- @field Wrapper.Group#GROUP templategroup Template group.
-- @field #number ngrouping User defined number of units in the asset group.
-- @field #table assets Squadron assets.
-- @field #table missiontypes Capabilities (mission types and performances) of the squadron.
-- @field #number fuellow Low fuel threshold.
-- @field #boolean fuellowRefuel If `true`, flight tries to refuel at the nearest tanker.
-- @field #number maintenancetime Time in seconds needed for maintenance of a returned flight.
-- @field #number repairtime Time in seconds for each
-- @field #string livery Livery of the squadron.
-- @field #number skill Skill of squadron members.
-- @field #number modex Modex.
-- @field #number modexcounter Counter to incease modex number for assets.
-- @field #string callsignName Callsign name.
-- @field #number callsigncounter Counter to increase callsign names for new assets.
-- @field Ops.AirWing#AIRWING airwing The AIRWING object the squadron belongs to.
-- @field #number Ngroups Number of asset flight groups this squadron has. 
-- @field #number engageRange Mission range in meters.
-- @field #string attribute Generalized attribute of the squadron template group.
-- @field #number tankerSystem For tanker squads, the refuel system used (boom=0 or probpe=1). Default nil.
-- @field #number refuelSystem For refuelable squads, the refuel system used (boom=0 or probe=1). Default nil.
-- @field #table tacanChannel List of TACAN channels available to the squadron.
-- @field #number radioFreq Radio frequency in MHz the squad uses.
-- @field #number radioModu Radio modulation the squad uses.
-- @extends Core.Fsm#FSM

--- *It is unbelievable what a squadron of twelve aircraft did to tip the balance.* -- Adolf Galland
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\Squadron\_Main.png)
--
-- # The SQUADRON Concept
-- 
-- A SQUADRON is essential part of an AIRWING and consists of **one** type of aircraft. 
--
--
--
-- @field #SQUADRON
SQUADRON = {
  ClassName      = "SQUADRON",
  verbose        =     0,
  lid            =   nil,
  name           =   nil,
  templatename   =   nil,
  aircrafttype   =   nil,
  assets         =    {},
  missiontypes   =    {},
  repairtime     =     0,
  maintenancetime=     0,
  livery         =   nil,
  skill          =   nil,
  modex          =   nil,
  modexcounter   =     0,
  callsignName   =   nil,
  callsigncounter=    11,
  airwing        =   nil,
  Ngroups        =   nil,
  engageRange    =   nil,
  tankerSystem   =   nil,
  refuelSystem   =   nil,
  tacanChannel   =    {},
}

--- SQUADRON class version.
-- @field #string version
SQUADRON.version="0.5.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Engage radius.
-- DONE: Modex.
-- DONE: Call signs.

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
  self:SetMissionRange()
  self:SetSkill(AI.Skill.GOOD)
  --self:SetVerbosity(0)
  
  -- Everyone can ORBIT.
  self:AddMissionCapability(AUFTRAG.Type.ORBIT)
  
  -- Generalized attribute.
  self.attribute=self.templategroup:GetAttribute()
  
  -- Aircraft type.
  self.aircrafttype=self.templategroup:GetTypeName()
  
  -- Refueling system.
  self.refuelSystem=select(2, self.templategroup:GetUnit(1):IsRefuelable())
  self.tankerSystem=select(2, self.templategroup:GetUnit(1):IsTanker())


  -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "OnDuty")      -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- Status update.
  
  self:AddTransition("OnDuty",        "Pause",              "Paused")      -- Pause squadron.
  self:AddTransition("Paused",        "Unpause",            "OnDuty")      -- Unpause squadron.
  
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
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set livery painted on all squadron aircraft.
-- Note that the livery name in general is different from the name shown in the mission editor.
-- 
-- Valid names are the names of the **livery directories**. Check out the folder in your DCS installation for:
-- 
-- * Full modules: `DCS World OpenBeta\CoreMods\aircraft\<Aircraft Type>\Liveries\<Aircraft Type>\<Livery Name>`
-- * AI units: `DCS World OpenBeta\Bazar\Liveries\<Aircraft Type>\<Livery Name>`
-- 
-- The folder name `<Livery Name>` is the string you want.
-- 
-- Or personal liveries you have installed somewhere in your saved games folder.
--  
-- @param #SQUADRON self
-- @param #string LiveryName Name of the livery.
-- @return #SQUADRON self
function SQUADRON:SetLivery(LiveryName)
  self.livery=LiveryName
  return self
end

--- Set skill level of all squadron team members.
-- @param #SQUADRON self
-- @param #string Skill Skill of all flights.
-- @usage mysquadron:SetSkill(AI.Skill.EXCELLENT)
-- @return #SQUADRON self
function SQUADRON:SetSkill(Skill)
  self.skill=Skill
  return self
end

--- Set verbosity level.
-- @param #SQUADRON self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #SQUADRON self
function SQUADRON:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set turnover and repair time. If an asset returns from a mission to the airwing, it will need some time until the asset is available for further missions.
-- @param #SQUADRON self
-- @param #number MaintenanceTime Time in minutes it takes until a flight is combat ready again. Default is 0 min.
-- @param #number RepairTime Time in minutes it takes to repair a flight for each life point taken. Default is 0 min.
-- @return #SQUADRON self
function SQUADRON:SetTurnoverTime(MaintenanceTime, RepairTime)
  self.maintenancetime=MaintenanceTime and MaintenanceTime*60 or 0
  self.repairtime=RepairTime and RepairTime*60 or 0
  return self
end

--- Set radio frequency and modulation the squad uses.
-- @param #SQUADRON self
-- @param #number Frequency Radio frequency in MHz. Default 251 MHz.
-- @param #number Modulation Radio modulation. Default 0=AM.
-- @usage mysquadron:SetSkill(AI.Skill.EXCELLENT)
-- @return #SQUADRON self
function SQUADRON:SetRadio(Frequency, Modulation)
  self.radioFreq=Frequency or 251
  self.radioModu=Modulation or radio.modulation.AM
  return self
end

--- Set number of units in groups.
-- @param #SQUADRON self
-- @param #number nunits Number of units. Must be >=1 and <=4. Default 2.
-- @return #SQUADRON self
function SQUADRON:SetGrouping(nunits)
  self.ngrouping=nunits or 2
  if self.ngrouping<1 then self.ngrouping=1 end
  if self.ngrouping>4 then self.ngrouping=4 end
  return self
end

--- Set mission types this squadron is able to perform.
-- @param #SQUADRON self
-- @param #table MissionTypes Table of mission types. Can also be passed as a #string if only one type.
-- @param #number Performance Performance describing how good this mission can be performed. Higher is better. Default 50. Max 100.
-- @return #SQUADRON self
function SQUADRON:AddMissionCapability(MissionTypes, Performance)

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end
  
  -- Set table.
  self.missiontypes=self.missiontypes or {}
  
  for _,missiontype in pairs(MissionTypes) do
  
    -- Check not to add the same twice.  
    if self:CheckMissionCapability(missiontype, self.missiontypes) then
      self:E(self.lid.."WARNING: Mission capability already present! No need to add it twice.")
      -- TODO: update performance.
    else
  
      local capability={} --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=missiontype
      capability.Performance=Performance or 50
      table.insert(self.missiontypes, capability)
      
    end
  end
  
  -- Debug info.
  self:T2(self.missiontypes)
  
  return self
end

--- Get mission types this squadron is able to perform.
-- @param #SQUADRON self
-- @return #table Table of mission types. Could be empty {}.
function SQUADRON:GetMissionTypes()

  local missiontypes={}
  
  for _,Capability in pairs(self.missiontypes) do
    local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
    table.insert(missiontypes, capability.MissionType)  
  end

  return missiontypes
end

--- Get mission capabilities of this squadron.
-- @param #SQUADRON self
-- @return #table Table of mission capabilities.
function SQUADRON:GetMissionCapabilities()
  return self.missiontypes
end

--- Get mission performance for a given type of misson.
-- @param #SQUADRON self
-- @param #string MissionType Type of mission.
-- @return #number Performance or -1.
function SQUADRON:GetMissionPeformance(MissionType)

  for _,Capability in pairs(self.missiontypes) do
    local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
    if capability.MissionType==MissionType then
      return capability.Performance
    end
  end

  return -1
end

--- Set max mission range. Only missions in a circle of this radius around the squadron airbase are executed.
-- @param #SQUADRON self
-- @param #number Range Range in NM. Default 100 NM.
-- @return #SQUADRON self
function SQUADRON:SetMissionRange(Range)
  self.engageRange=UTILS.NMToMeters(Range or 100)
  return self
end

--- Set call sign.
-- @param #SQUADRON self
-- @param #number Callsign Callsign from CALLSIGN.Aircraft, e.g. "Chevy" for CALLSIGN.Aircraft.CHEVY.
-- @param #number Index Callsign index, Chevy-**1**.
-- @return #SQUADRON self
function SQUADRON:SetCallsign(Callsign, Index)
  self.callsignName=Callsign
  self.callsignIndex=Index
  return self
end

--- Set modex.
-- @param #SQUADRON self
-- @param #number Modex A number like 100.
-- @param #string Prefix A prefix string, which is put before the `Modex` number.
-- @param #string Suffix A suffix string, which is put after the `Modex` number. 
-- @return #SQUADRON self
function SQUADRON:SetModex(Modex, Prefix, Suffix)
  self.modex=Modex
  self.modexPrefix=Prefix
  self.modexSuffix=Suffix
  return self
end

--- Set low fuel threshold.
-- @param #SQUADRON self
-- @param #number LowFuel Low fuel threshold in percent. Default 25.
-- @return #SQUADRON self
function SQUADRON:SetFuelLowThreshold(LowFuel)
  self.fuellow=LowFuel or 25
  return self
end

--- Set if low fuel threshold is reached, flight tries to refuel at the neares tanker.
-- @param #SQUADRON self
-- @param #boolean switch If true or nil, flight goes for refuelling. If false, turn this off.
-- @return #SQUADRON self
function SQUADRON:SetFuelLowRefuel(switch)
  if switch==false then
    self.fuellowRefuel=false
  else
    self.fuellowRefuel=true
  end
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
  self:T(self.lid..string.format("Adding asset %s of type %s", Asset.spawngroupname, Asset.unittype))
  Asset.squadname=self.name
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
      self:T2(self.lid..string.format("Removing asset %s", asset.spawngroupname))
      table.remove(self.assets, i)
      break
    end
  end
  return self
end

--- Remove airwing asset group from squadron.
-- @param #SQUADRON self
-- @param #string GroupName Name of the asset group.
-- @return #SQUADRON self
function SQUADRON:DelGroup(GroupName)
  for i,_asset in pairs(self.assets) do
    local asset=_asset --Ops.AirWing#AIRWING.SquadronAsset
    if GroupName==asset.spawngroupname then
      self:T2(self.lid..string.format("Removing asset %s", asset.spawngroupname))
      table.remove(self.assets, i)
      break
    end
  end
  return self
end

--- Get name of the squadron
-- @param #SQUADRON self
-- @return #string Name of the squadron.
function SQUADRON:GetName()
  return self.name
end

--- Get radio frequency and modulation.
-- @param #SQUADRON self
-- @return #number Radio frequency in MHz.
-- @return #number Radio Modulation (0=AM, 1=FM).
function SQUADRON:GetRadio()
  return self.radioFreq, self.radioModu
end

--- Create a callsign for the asset.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The airwing asset.
-- @return #SQUADRON self
function SQUADRON:GetCallsign(Asset)

  if self.callsignName then
  
    Asset.callsign={}
  
    for i=1,Asset.nunits do
    
      local callsign={}
      
      callsign[1]=self.callsignName
      callsign[2]=math.floor(self.callsigncounter / 10)
      callsign[3]=self.callsigncounter % 10
      if callsign[3]==0 then
        callsign[3]=1
        self.callsigncounter=self.callsigncounter+2
      else
        self.callsigncounter=self.callsigncounter+1
      end
    
      Asset.callsign[i]=callsign
      
      self:T3({callsign=callsign})
    
      --TODO: there is also a table entry .name, which is a string.
    end
  
  
  end

end

--- Create a modex for the asset.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The airwing asset.
-- @return #SQUADRON self
function SQUADRON:GetModex(Asset)

  if self.modex then
  
    Asset.modex={}
  
    for i=1,Asset.nunits do
    
      Asset.modex[i]=string.format("%03d", self.modex+self.modexcounter)
      
      self.modexcounter=self.modexcounter+1
      
      self:T3({modex=Asset.modex[i]})
    
    end
    
  end
  
end


--- Add TACAN channels to the squadron. Note that channels can only range from 1 to 126.
-- @param #SQUADRON self
-- @param #number ChannelMin Channel.
-- @param #number ChannelMax Channel.
-- @return #SQUADRON self
-- @usage mysquad:AddTacanChannel(64,69)  -- adds channels 64, 65, 66, 67, 68, 69
function SQUADRON:AddTacanChannel(ChannelMin, ChannelMax)

  ChannelMax=ChannelMax or ChannelMin
  
  if ChannelMin>126 then
    self:E(self.lid.."ERROR: TACAN Channel must be <= 126! Will not add to available channels")
    return self
  end
  if ChannelMax>126 then
    self:E(self.lid.."WARNING: TACAN Channel must be <= 126! Adjusting ChannelMax to 126")
    ChannelMax=126
  end

  for i=ChannelMin,ChannelMax do
    self.tacanChannel[i]=true
  end

  return self
end

--- Get an unused TACAN channel.
-- @param #SQUADRON self
-- @return #number TACAN channel or *nil* if no channel is free.
function SQUADRON:FetchTacan()

  for channel,free in pairs(self.tacanChannel) do
    if free then
      self:T(self.lid..string.format("Checking out Tacan channel %d", channel))
      self.tacanChannel[channel]=false
      return channel
    end
  end

  return nil
end

--- "Return" a used TACAN channel.
-- @param #SQUADRON self
-- @param #number channel The channel that is available again.
function SQUADRON:ReturnTacan(channel)
  self:T(self.lid..string.format("Returning Tacan channel %d", channel))
  self.tacanChannel[channel]=true
end

--- Check if squadron is "OnDuty".
-- @param #SQUADRON self
-- @return #boolean If true, squdron is in state "OnDuty".
function SQUADRON:IsOnDuty()
  return self:Is("OnDuty")
end

--- Check if squadron is "Stopped".
-- @param #SQUADRON self
-- @return #boolean If true, squdron is in state "Stopped".
function SQUADRON:IsStopped()
  return self:Is("Stopped")
end

--- Check if squadron is "Paused".
-- @param #SQUADRON self
-- @return #boolean If true, squdron is in state "Paused".
function SQUADRON:IsPaused()
  return self:Is("Paused")
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #SQUADRON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting SQUADRON", self.name)
  self:T(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "Status" event.
-- @param #SQUADRON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStatus(From, Event, To)

  if self.verbose>=1 then

    -- FSM state.
    local fsmstate=self:GetState()
  
    local callsign=self.callsignName and UTILS.GetCallsignName(self.callsignName) or "N/A"
    local modex=self.modex and self.modex or -1
    local skill=self.skill and tostring(self.skill) or "N/A"
    
    local NassetsTot=#self.assets
    local NassetsInS=self:CountAssetsInStock()
    local NassetsQP=0 ; local NassetsP=0 ; local NassetsQ=0  
    if self.airwing then
      NassetsQP, NassetsP, NassetsQ=self.airwing:CountAssetsOnMission(nil, self)
    end
    
    -- Short info.
    local text=string.format("%s [Type=%s, Call=%s, Modex=%d, Skill=%s]: Assets Total=%d, Stock=%d, Mission=%d [Active=%d, Queue=%d]", 
    fsmstate, self.aircrafttype, callsign, modex, skill, NassetsTot, NassetsInS, NassetsQP, NassetsP, NassetsQ)
    self:I(self.lid..text)
    
    -- Check if group has detected any units.
    self:_CheckAssetStatus()
    
  end  
  
  if not self:IsStopped() then
    self:__Status(-60)
  end
end


--- Check asset status.
-- @param #SQUADRON self
function SQUADRON:_CheckAssetStatus()

  if self.verbose>=2 and #self.assets>0 then
  
    local text=""
    for j,_asset in pairs(self.assets) do
      local asset=_asset  --Ops.AirWing#AIRWING.SquadronAsset
  
      -- Text.
      text=text..string.format("\n[%d] %s (%s*%d): ", j, asset.spawngroupname, asset.unittype, asset.nunits)
      
      if asset.spawned then
      
        ---
        -- Spawned
        ---
  
        -- Mission info.
        local mission=self.airwing and self.airwing:GetAssetCurrentMission(asset) or false
        if mission then
          local distance=asset.flightgroup and UTILS.MetersToNM(mission:GetTargetDistance(asset.flightgroup.group:GetCoordinate())) or 0
          text=text..string.format("Mission %s - %s: Status=%s, Dist=%.1f NM", mission.name, mission.type, mission.status, distance)
        else
          text=text.."Mission None"
        end
          
        -- Flight status.
        text=text..", Flight: "
        if asset.flightgroup and asset.flightgroup:IsAlive() then
          local status=asset.flightgroup:GetState()
          local fuelmin=asset.flightgroup:GetFuelMin()
          local fuellow=asset.flightgroup:IsFuelLow()
          local fuelcri=asset.flightgroup:IsFuelCritical()
          
          text=text..string.format("%s Fuel=%d", status, fuelmin)
          if fuelcri then
            text=text.." (Critical!)"
          elseif fuellow then
            text=text.." (Low)"
          end
          
          local lifept, lifept0=asset.flightgroup:GetLifePoints()
          text=text..string.format(", Life=%d/%d", lifept, lifept0)
          
          local ammo=asset.flightgroup:GetAmmoTot()
          text=text..string.format(", Ammo=%d [G=%d, R=%d, B=%d, M=%d]", ammo.Total,ammo.Guns, ammo.Rockets, ammo.Bombs, ammo.Missiles)
        else
          text=text.."N/A"
        end

        -- Payload info.
        local payload=asset.payload and table.concat(self.airwing:GetPayloadMissionTypes(asset.payload), ", ") or "None"
        text=text..", Payload={"..payload.."}"
     
      else
  
        ---
        -- In Stock
        ---
        
        text=text..string.format("In Stock")
        
        if self:IsRepaired(asset) then
          text=text..", Combat Ready"
        else
        
          text=text..string.format(", Repaired in %d sec", self:GetRepairTime(asset))

          if asset.damage then
            text=text..string.format(" (Damage=%.1f)", asset.damage)
          end
        end
  
        if asset.Treturned then
          local T=timer.getAbsTime()-asset.Treturned
          text=text..string.format(", Returned for %d sec", T)
        end
      
      end
    end
    self:I(self.lid..text)
  end

end

--- On after "Stop" event.
-- @param #SQUADRON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStop(From, Event, To)

  self:I(self.lid.."STOPPING Squadron!")

  -- Remove all assets.
  for i=#self.assets,1,-1 do
    local asset=self.assets[i]
    self:DelAsset(asset)
  end

  self.CallScheduler:Clear()
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if there is a squadron that can execute a given mission.
-- We check the mission type, the refuelling system, engagement range
-- @param #SQUADRON self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If true, Squadron can do that type of mission.
function SQUADRON:CanMission(Mission)
  
  local cando=true
  
  -- On duty?=  
  if not self:IsOnDuty() then
    self:T(self.lid..string.format("Squad in not OnDuty but in state %s. Cannot do mission %s with target %s", self:GetState(), Mission.name, Mission:GetTargetName()))
    return false
  end

  -- Check mission type. WARNING: This assumes that all assets of the squad can do the same mission types!
  if not self:CheckMissionType(Mission.type, self:GetMissionTypes()) then
    self:T(self.lid..string.format("INFO: Squad cannot do mission type %s (%s, %s)", Mission.type, Mission.name, Mission:GetTargetName()))
    return false
  end
  
  -- Check that tanker mission
  if Mission.type==AUFTRAG.Type.TANKER then
  
    if Mission.refuelSystem and Mission.refuelSystem==self.tankerSystem then
      -- Correct refueling system.
    else
      self:T(self.lid..string.format("INFO: Wrong refueling system requested=%s != %s=available", tostring(Mission.refuelSystem), tostring(self.tankerSystem)))
      return false
    end
  
  end
  
  -- Distance to target.
  local TargetDistance=Mission:GetTargetDistance(self.airwing:GetCoordinate())
  
  -- Max engage range.
  local engagerange=Mission.engageRange and math.max(self.engageRange, Mission.engageRange) or self.engageRange
      
  -- Set range is valid. Mission engage distance can overrule the squad engage range.
  if TargetDistance>engagerange then
    self:I(self.lid..string.format("INFO: Squad is not in range. Target dist=%d > %d NM max mission Range", UTILS.MetersToNM(TargetDistance), UTILS.MetersToNM(engagerange)))
    return false
  end
  
  return true
end

--- Count assets in airwing (warehous) stock.
-- @param #SQUADRON self
-- @return #number Assets not spawned.
function SQUADRON:CountAssetsInStock()

  local N=0
  for _,_asset in pairs(self.assets) do
    local asset=_asset --Ops.AirWing#AIRWING.SquadronAsset
    if asset.spawned then
    
    else
      N=N+1
    end
  end

  return N
end

--- Get assets for a mission.
-- @param #SQUADRON self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #number Nplayloads Number of payloads available.
-- @return #table Assets that can do the required mission.
function SQUADRON:RecruitAssets(Mission, Npayloads)

  -- Number of payloads available.
  Npayloads=Npayloads or self.airwing:CountPayloadsInStock(Mission.type, self.aircrafttype, Mission.payloads)      

  local assets={}

  -- Loop over assets.
  for _,_asset in pairs(self.assets) do  
    local asset=_asset --Ops.AirWing#AIRWING.SquadronAsset
    
    
    -- Check if asset is currently on a mission (STARTED or QUEUED).
    if self.airwing:IsAssetOnMission(asset) then

      ---
      -- Asset is already on a mission.
      ---

      -- Check if this asset is currently on a GCICAP mission (STARTED or EXECUTING).
      if self.airwing:IsAssetOnMission(asset, AUFTRAG.Type.GCICAP) and Mission.type==AUFTRAG.Type.INTERCEPT then

        -- Check if the payload of this asset is compatible with the mission.
        -- Note: we do not check the payload as an asset that is on a GCICAP mission should be able to do an INTERCEPT as well!
        self:I(self.lid.."Adding asset on GCICAP mission for an INTERCEPT mission")
        table.insert(assets, asset)
        
      end      
    
    else
    
      ---
      -- Asset as NO current mission
      ---

      if asset.spawned then
      
        ---
        -- Asset is already SPAWNED (could be uncontrolled on the airfield or inbound after another mission)
        ---
      
        local flightgroup=asset.flightgroup
      
        -- Firstly, check if it has the right payload.
        if self:CheckMissionCapability(Mission.type, asset.payload.capabilities) and flightgroup and flightgroup:IsAlive() then
      
          -- Assume we are ready and check if any condition tells us we are not.
          local combatready=true
  
          if Mission.type==AUFTRAG.Type.INTERCEPT then
            combatready=flightgroup:CanAirToAir()
          else
            local excludeguns=Mission.type==AUFTRAG.Type.BOMBING or Mission.type==AUFTRAG.Type.BOMBRUNWAY or Mission.type==AUFTRAG.Type.BOMBCARPET or Mission.type==AUFTRAG.Type.SEAD or Mission.type==AUFTRAG.Type.ANTISHIP
            combatready=flightgroup:CanAirToGround(excludeguns)
          end
          
          -- No more attacks if fuel is already low. Safety first!
          if flightgroup:IsFuelLow() then
            combatready=false
          end
          
          -- Check if in a state where we really do not want to fight any more.
          if flightgroup:IsHolding() or flightgroup:IsLanding() or flightgroup:IsLanded() or flightgroup:IsArrived() or flightgroup:IsDead() or flightgroup:IsStopped() then
            combatready=false
          end
      
          -- This asset is "combatready".
          if combatready then
            self:I(self.lid.."Adding SPAWNED asset to ANOTHER mission as it is COMBATREADY")
            table.insert(assets, asset)
          end
        
        end
        
      else
      
        ---
        -- Asset is still in STOCK
        ---          
      
        -- Check that asset is not already requested for another mission.
        if Npayloads>0 and self:IsRepaired(asset) and (not asset.requested) then
                    
          -- Add this asset to the selection.
          table.insert(assets, asset)
          
          -- Reduce number of payloads so we only return the number of assets that could do the job.
          Npayloads=Npayloads-1
          
        end
        
      end      
    end    
  end -- loop over assets

  return assets
end


--- Get the time an asset needs to be repaired.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The asset.
-- @return #number Time in seconds until asset is repaired.
function SQUADRON:GetRepairTime(Asset)

  if Asset.Treturned then
  
    local t=self.maintenancetime    
    t=t+Asset.damage*self.repairtime
    
    -- Seconds after returned.
    local dt=timer.getAbsTime()-Asset.Treturned
  
    local T=t-dt
    
    return T
  else
    return 0
  end

end

--- Checks if a mission type is contained in a table of possible types.
-- @param #SQUADRON self
-- @param Ops.AirWing#AIRWING.SquadronAsset Asset The asset.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function SQUADRON:IsRepaired(Asset)

  if Asset.Treturned then
    local Tnow=timer.getAbsTime()
    local Trepaired=Asset.Treturned+self.maintenancetime
    if Tnow>=Trepaired then
      return true
    else
      return false
    end
  
  else
    return true
  end

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

--- Check if a mission type is contained in a list of possible capabilities.
-- @param #SQUADRON self
-- @param #string MissionType The requested mission type.
-- @param #table Capabilities A table with possible capabilities.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function SQUADRON:CheckMissionCapability(MissionType, Capabilities)

  for _,cap in pairs(Capabilities) do
    local capability=cap --Ops.Auftrag#AUFTRAG.Capability
    if capability.MissionType==MissionType then
      return true
    end   
  end

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

