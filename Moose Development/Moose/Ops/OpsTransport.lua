--- **Ops** - Troop transport assignment for OPS groups.
-- 
-- ## Main Features:
--
--    * Transport troops from A to B.
--    * Supports ground, naval and airborne (airplanes and helicopters) units as carriers
--    * Use combined forces (ground, naval, air) to transport the troops.
--    * Additional FSM events to hook into and customize your mission design. 
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Transport).
--    
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ==
-- 
-- @module Ops.OpsTransport
-- @image OPS_OpsTransport.png


--- OPSTRANSPORT class.
-- @type OPSTRANSPORT
-- @field #string ClassName Name of the class.
-- @field #string lid Log ID.
-- @field #number uid Unique ID of the transport.
-- @field #number verbose Verbosity level.
-- @field #table cargos Cargos. Each element is a @{Ops.OpsGroup#OPSGROUP.CargoGroup}.
-- @field #table carriers Carriers assigned for this transport.
-- @field #number prio Priority of this transport. Should be a number between 0 (high prio) and 100 (low prio).
-- @field #boolean urgent If true, transport is urgent.
-- @field #number importance Importance of this transport. Smaller=higher.
-- @field #number Tstart Start time in *abs.* seconds.
-- @field #number Tstop Stop time in *abs.* seconds. Default `#nil` (never stops).
-- @field #number duration Duration (`Tstop-Tstart`) of the transport in seconds.
-- @field #table conditionStart Start conditions.
-- @field Core.Zone#ZONE pickupzone Zone where the cargo is picked up.
-- @field Core.Zone#ZONE deployzone Zone where the cargo is dropped off.
-- @field Core.Zone#ZONE embarkzone (Optional) Zone where the cargo is supposed to embark. Default is the pickup zone.
-- @field Core.Zone#ZONE disembarkzone (Optional) Zone where the cargo is disembarked. Default is the deploy zone.
-- @field Core.Zone#ZONE unboardzone (Optional) Zone where the cargo is going to after disembarkment.
-- @field #boolean disembarkActivation Activation setting when group is disembared from carrier.
-- @field #boolean disembarkInUtero Do not spawn the group in any any state but leave it "*in utero*". For example, to directly load it into another carrier.
-- @field #table disembarkCarriers Table of carriers to which the cargo is disembared. This is a direct transfer from the old to the new carrier.
-- @field #table requiredCargos Table of cargo groups that must be loaded before the first transport is started.
-- @field #number Ncargo Total number of cargo groups.
-- @field #number Ncarrier Total number of assigned carriers.
-- @field #number Ndelivered Total number of cargo groups delivered.
-- @field #table pathsTransport Paths of `#OPSGROUP.Path`. 
-- @extends Core.Fsm#FSM

--- *Victory is the beautiful, bright-colored flower. Transport is the stem without which it could never have blossomed.* -- Winston Churchill
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\Transport\_Main.png)
--
-- # The OPSTRANSPORT Concept
-- 
-- This class simulates troop transport using carriers such as APCs, ships, helicopters or airplanes. The carriers and transported groups need to be OPSGROUPS (see ARMYGROUP, NAVYGROUP and FLIGHTGROUP classes).
-- 
-- **IMPORTANT NOTES**
-- 
-- * Cargo groups are **not** split and distributed into different carrier *units*. That means that the whole cargo group **must fit** into one of the carrier units.
-- * Cargo groups must be inside the pickup zones to be considered for loading. Groups not inside the pickup zone will not get the command to board. 
-- 
-- 
-- @field #OPSTRANSPORT
OPSTRANSPORT = {
  ClassName       = "OPSTRANSPORT",
  verbose         =  0,
  cargos          = {},
  carriers        = {},
  carrierTransportStatus = {},
  conditionStart  =  {},
  pathsTransport  =  {},
  requiredCargos  =  {},
}

--- Cargo transport status.
-- @type OPSTRANSPORT.Status
-- @field #string PLANNED Planning state.
-- @field #string SCHEDULED Transport is scheduled in the cargo queue.
-- @field #string EXECUTING Transport is being executed.
-- @field #string DELIVERED Transport was delivered. 
OPSTRANSPORT.Status={
  PLANNED="planned",
  SCHEDULED="scheduled",
  EXECUTING="executing",
  DELIVERED="delivered",
}

--- Path.
-- @type OPSTRANSPORT.Path
-- @field #table coords Table of coordinates.
-- @field #number radius Radomization radius in meters. Default 0 m.
-- @field #number altitude Altitude in feet AGL. Only for aircraft.

--- Generic mission condition.
-- @type OPSTRANSPORT.Condition
-- @field #function func Callback function to check for a condition. Should return a #boolean.
-- @field #table arg Optional arguments passed to the condition callback function.

--- Transport ID.
_OPSTRANSPORTID=0

--- Army Group version.
-- @field #string version
OPSTRANSPORT.version="0.0.8"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Stop/abort transport.
-- DONE: Add start conditions.
-- DONE: Check carrier(s) dead.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSTRANSPORT class object. Essential input are the troops that should be transported and the zones where the troops are picked up and deployed.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP GroupSet Set of groups to be transported. Can also be a single @{Wrapper.Group#GROUP} or @{Ops.OpsGroup#OPSGROUP} object.
-- @param Core.Zone#ZONE Pickupzone Pickup zone. This is the zone, where the carrier is going to pickup the cargo. **Important**: only cargo is considered, if it is in this zone when the carrier starts loading!
-- @param Core.Zone#ZONE Deployzone Deploy zone. This is the zone, where the carrier is going to drop off the cargo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:New(GroupSet, Pickupzone, Deployzone)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPSTRANSPORT
  
  -- Increase ID counter.
  _OPSTRANSPORTID=_OPSTRANSPORTID+1
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSTRANSPORT [UID=%d] | ", _OPSTRANSPORTID)
  
  -- Defaults.
  self.uid=_OPSTRANSPORTID
    
  self.pickupzone=Pickupzone
  self.deployzone=Deployzone
  self.embarkzone=Pickupzone
  self.cargos={}
  self.carriers={}
  self.Ncargo=0
  self.Ncarrier=0
  self.Ndelivered=0
  
  self:SetPriority()
  self:SetTime()
  
  -- Add cargo groups (could also be added later).
  if GroupSet then
    self:AddCargoGroups(GroupSet)
  end
  

  -- FMS start state is PLANNED.
  self:SetStartState(OPSTRANSPORT.Status.PLANNED)
  
  -- PLANNED --> SCHEDULED --> EXECUTING --> DELIVERED  
  self:AddTransition("*",                           "Planned",          OPSTRANSPORT.Status.PLANNED)     -- Cargo transport was planned.
  self:AddTransition(OPSTRANSPORT.Status.PLANNED,   "Scheduled",        OPSTRANSPORT.Status.SCHEDULED)   -- Cargo is queued at at least one carrier.
  self:AddTransition(OPSTRANSPORT.Status.SCHEDULED, "Executing",        OPSTRANSPORT.Status.EXECUTING)   -- Cargo is being transported.
  self:AddTransition(OPSTRANSPORT.Status.EXECUTING, "Delivered",        OPSTRANSPORT.Status.DELIVERED)   -- Cargo was delivered.
  
  self:AddTransition("*",                           "Status",           "*")
  self:AddTransition("*",                           "Stop",             "*")
  
  self:AddTransition("*",                           "Loaded",           "*")
  self:AddTransition("*",                           "Unloaded",         "*")
  
  self:AddTransition("*",                           "DeadCarrierUnit",  "*")
  self:AddTransition("*",                           "DeadCarrierGroup", "*")
  self:AddTransition("*",                           "DeadCarrierAll",   "*")

  -- Call status update.
  self:__Status(-1)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add cargo groups to be transported.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP GroupSet Set of groups to be transported. Can also be passed as a single GROUP or OPSGROUP object.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddCargoGroups(GroupSet)

  -- Check type of GroupSet provided.
  if GroupSet:IsInstanceOf("GROUP") or GroupSet:IsInstanceOf("OPSGROUP") then
  
    -- We got a single GROUP or OPSGROUP object.
    local cargo=self:_CreateCargoGroupData(GroupSet)
    
    if cargo  then --and self:CanCargo(cargo.opsgroup)
      table.insert(self.cargos, cargo)
      self.Ncargo=self.Ncargo+1
    end
    
  else
  
    -- We got a SET_GROUP object.
    
    for _,group in pairs(GroupSet.Set) do
    
      local cargo=self:_CreateCargoGroupData(group)
      
      if cargo then
        table.insert(self.cargos, cargo)
        self.Ncargo=self.Ncargo+1
      end
      
    end
  end
  
  -- Debug info.
  if self.verbose>=0 then
    local text=string.format("Added cargo groups:")
    local Weight=0
    for _,_cargo in pairs(self.cargos) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      local weight=cargo.opsgroup:GetWeightTotal()
      Weight=Weight+weight
      text=text..string.format("\n- %s [%s] weight=%.1f kg", cargo.opsgroup:GetName(), cargo.opsgroup:GetState(), weight)
    end
    text=text..string.format("\nTOTAL: Ncargo=%d, Weight=%.1f kg", #self.cargos, Weight)
    self:I(self.lid..text)
  end


  return self
end

--- Set embark zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE EmbarkZone Zone where the troops are embarked.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetEmbarkZone(EmbarkZone)
  self.embarkzone=EmbarkZone or self.pickupzone
  return self
end

--- Set disembark zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE DisembarkZone Zone where the troops are disembarked.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkZone(DisembarkZone)
  self.disembarkzone=DisembarkZone
  return self
end

--- Set activation status of group when disembarked from transport carrier.
-- @param #OPSTRANSPORT self
-- @param #boolean Active If `true` or `nil`, group is activated when disembarked. If `false`, group is late activated and needs to be activated manually.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkActivation(Active)
  if Active==true or Active==nil then
    self.disembarkActivation=true
  else
    self.disembarkActivation=false
  end  
  return self
end

--- Set transfer carrier(s). These are carrier groups, where the cargo is directly loaded into when disembarked.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP Carriers Carrier set. Can also be passed as a #GROUP, #OPSGROUP or #SET_OPSGROUP object.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkCarriers(Carriers)

  -- Debug info.
  self:T(self.lid.."Setting transfer carriers!")

  -- Create table.
  self.disembarkCarriers=self.disembarkCarriers or {}

  if Carriers:IsInstanceOf("GROUP") or Carriers:IsInstanceOf("OPSGROUP") then
  
    local carrier=self:_GetOpsGroupFromObject(Carriers)
    if  carrier then
      table.insert(self.disembarkCarriers, carrier)
    end
      
  elseif Carriers:IsInstanceOf("SET_GROUP") or Carriers:IsInstanceOf("SET_OPSGROUP") then
  
    for _,object in pairs(Carriers:GetSet()) do
      local carrier=self:_GetOpsGroupFromObject(object)
      if carrier then
        table.insert(self.disembarkCarriers, carrier)
      end
    end
    
  else  
    self:E(self.lid.."ERROR: Carriers must be a GROUP, OPSGROUP, SET_GROUP or SET_OPSGROUP object!")    
  end

  return self
end


--- Set if group remains *in utero* after disembarkment from carrier. Can be used to directly load the group into another carrier. Similar to disembark in late activated state.
-- @param #OPSTRANSPORT self
-- @param #boolean InUtero If `true` or `nil`, group remains *in utero* after disembarkment.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkInUtero(InUtero)
  if InUtero==true or InUtero==nil then
    self.disembarkInUtero=true
  else
    self.disembarkInUtero=false
  end  
  return self
end


--- Set required cargo. This is a list of cargo groups that need to be loaded before the **first** transport will start.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP Cargos Required cargo set. Can also be passed as a #GROUP, #OPSGROUP or #SET_OPSGROUP object.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetRequiredCargos(Cargos)

  -- Debug info.
  self:T(self.lid.."Setting required cargos!")

  -- Create table.
  self.requiredCargos=self.requiredCargos or {}

  if Cargos:IsInstanceOf("GROUP") or Cargos:IsInstanceOf("OPSGROUP") then
  
    local cargo=self:_GetOpsGroupFromObject(Cargos)
    if cargo then
      table.insert(self.requiredCargos, cargo)
    end
      
  elseif Cargos:IsInstanceOf("SET_GROUP") or Cargos:IsInstanceOf("SET_OPSGROUP") then
  
    for _,object in pairs(Cargos:GetSet()) do
      local cargo=self:_GetOpsGroupFromObject(object)
      if cargo then
        table.insert(self.requiredCargos, cargo)
      end
    end
    
  else  
    self:E(self.lid.."ERROR: Required Cargos must be a GROUP, OPSGROUP, SET_GROUP or SET_OPSGROUP object!")    
  end

  return self
end



--- Add a carrier assigned for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_AddCarrier(CarrierGroup)

  -- Check that this is not already an assigned carrier.
  if not self:IsCarrier(CarrierGroup) then
  
    -- Increase carrier count.
    self.Ncarrier=self.Ncarrier+1

    -- Set transport status to SCHEDULED.
    self:SetCarrierTransportStatus(CarrierGroup, OPSTRANSPORT.Status.SCHEDULED)
    
    -- Call scheduled event.
    self:Scheduled()
    
    -- Add carrier to table.
    table.insert(self.carriers, CarrierGroup)
    
  end 
  
  return self
end

--- Remove group from the current carrier list/table.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_DelCarrier(CarrierGroup)

  if self:IsCarrier(CarrierGroup) then
 
    for i=#self.carriers,1,-1 do
      local carrier=self.carriers[i] --Ops.OpsGroup#OPSGROUP
      if carrier.groupname==CarrierGroup.groupname then
        self:T(self.lid..string.format("Removing carrier %s", CarrierGroup.groupname))
        table.remove(self.carriers, i)
      end
    end    
  
    if #self.carriers==0 then  
      self:DeadCarrierAll()
    end
    
  end 
  
  return self
end

--- Get a list of alive carriers.
-- @param #OPSTRANSPORT self
-- @return #table Names of all carriers
function OPSTRANSPORT:_GetCarrierNames()

  local names={}
  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier --Ops.OpsGroup#OPSGROUP
    if carrier:IsAlive()~=nil then
      table.insert(names, carrier.groupname)
    end
  end
  
  return names
end

--- Get (all) cargo @{Ops.OpsGroup#OPSGROUP}s. Optionally, only delivered or undelivered groups can be returned.
-- @param #OPSTRANSPORT self
-- @param #boolean Delivered If `true`, only delivered groups are returned. If `false` only undelivered groups are returned. If `nil`, all groups are returned.
-- @return #table Ops groups.
function OPSTRANSPORT:GetCargoOpsGroups(Delivered)

  local opsgroups={}
  for _,_cargo in pairs(self.cargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    if Delivered==nil or cargo.delivered==Delivered then
      table.insert(opsgroups, cargo.opsgroup)
    end
  end
  
  return opsgroups
end


--- Set transport start and stop time.
-- @param #OPSTRANSPORT self
-- @param #string ClockStart Time the transport is started, e.g. "05:00" for 5 am. If specified as a #number, it will be relative (in seconds) to the current mission time. Default is 5 seconds after mission was added.
-- @param #string ClockStop (Optional) Time the transport is stopped, e.g. "13:00" for 1 pm. If mission could not be started at that time, it will be removed from the queue. If specified as a #number it will be relative (in seconds) to the current mission time.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetTime(ClockStart, ClockStop)

  -- Current mission time.
  local Tnow=timer.getAbsTime()
  
  -- Set start time. Default in 5 sec.
  local Tstart=Tnow+5
  if ClockStart and type(ClockStart)=="number" then
    Tstart=Tnow+ClockStart
  elseif ClockStart and type(ClockStart)=="string" then
    Tstart=UTILS.ClockToSeconds(ClockStart)
  end

  -- Set stop time. Default nil.
  local Tstop=nil
  if ClockStop and type(ClockStop)=="number" then
    Tstop=Tnow+ClockStop
  elseif ClockStop and type(ClockStop)=="string" then
    Tstop=UTILS.ClockToSeconds(ClockStop)
  end
  
  self.Tstart=Tstart
  self.Tstop=Tstop

  if Tstop then
    self.duration=self.Tstop-self.Tstart
  end  

  return self
end

--- Set mission priority and (optional) urgency. Urgent missions can cancel other running missions. 
-- @param #OPSTRANSPORT self
-- @param #number Prio Priority 1=high, 100=low. Default 50.
-- @param #number Importance Number 1-10. If missions with lower value are in the queue, these have to be finished first. Default is `nil`.
-- @param #boolean Urgent If *true*, another running mission might be cancelled if it has a lower priority.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetPriority(Prio, Importance, Urgent)
  self.prio=Prio or 50
  self.urgent=Urgent
  self.importance=Importance
  return self
end

--- Set verbosity. 
-- @param #OPSTRANSPORT self
-- @param #number Verbosity Be more verbose. Default 0
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetVerbosity(Verbosity)
  self.verbose=Verbosity or 0
  return self
end

--- Add start condition.
-- @param #OPSTRANSPORT self
-- @param #function ConditionFunction Function that needs to be true before the transport can be started. Must return a #boolean.
-- @param ... Condition function arguments if any.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddConditionStart(ConditionFunction, ...)

  if ConditionFunction then
  
    local condition={} --#OPSTRANSPORT.Condition
    
    condition.func=ConditionFunction
    condition.arg={}
    if arg then
      condition.arg=arg
    end
    
    table.insert(self.conditionStart, condition)
    
  end
  
  return self
end

--- Add path used for transportation from the pickup to the deploy zone. If multiple paths are defined, a random one is chosen.
-- @param #OPSTRANSPORT self
-- @param Wrapper.Group#GROUP PathGroup A (late activated) GROUP defining a transport path by their waypoints.
-- @param #number Radius Randomization radius in meters. Default 0 m.
-- @param #number Altitude Altitude in feet AGL. Only for aircraft.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddPathTransport(PathGroup, Radius, Altitude)

  local path={} --#OPSTRANSPORT.Path
  path.coords={}
  path.radius=Radius or 0
  path.altitude=Altitude

  -- Get route points.  
  local waypoints=PathGroup:GetTaskRoute()
  
  for _,wp in pairs(waypoints) do
    local coord=COORDINATE:New(wp.x, wp.alt, wp.y)
    table.insert(path.coords, coord)
  end

  -- Add path.
  table.insert(self.pathsTransport, path)

  return self
end

--- Get a path for transportation.
-- @param #OPSTRANSPORT self
-- @return #table The path of COORDINATEs.
function OPSTRANSPORT:_GetPathTransport()

  if self.pathsTransport and #self.pathsTransport>0 then
  
    -- Get a random path for transport.
    local path=self.pathsTransport[math.random(#self.pathsTransport)] --#OPSTRANSPORT.Path

    
    local coordinates={}
    for _,coord in ipairs(path.coords) do
    
      -- TODO: Add randomization.
    
      table.insert(coordinates, coord)
    end
        
    return coordinates
  end

  return nil
end


--- Add a carrier assigned for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @param #string Status Carrier Status.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetCarrierTransportStatus(CarrierGroup, Status)

  self.carrierTransportStatus[CarrierGroup.groupname]=Status
    
  return self
end

--- Get carrier transport status.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #string Carrier status.
function OPSTRANSPORT:GetCarrierTransportStatus(CarrierGroup)
  return self.carrierTransportStatus[CarrierGroup.groupname]
end

--- Get unique ID of the transport assignment.
-- @param #OPSTRANSPORT self
-- @return #number UID.
function OPSTRANSPORT:GetUID()
  return self.uid
end

--- Get number of delivered cargo groups.
-- @param #OPSTRANSPORT self
-- @return #number Total number of delivered cargo groups.
function OPSTRANSPORT:GetNcargoDelivered()
  return self.Ndelivered
end

--- Get number of cargo groups.
-- @param #OPSTRANSPORT self
-- @return #number Total number of cargo groups.
function OPSTRANSPORT:GetNcargoTotal()
  return self.Ncargo
end

--- Get number of carrier groups assigned for this transport.
-- @param #OPSTRANSPORT self
-- @return #number Total number of carrier groups.
function OPSTRANSPORT:GetNcarrier()
  return self.Ncarrier
end

--- Check if an OPS group is assigned as carrier for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Potential carrier OPSGROUP.
-- @return #boolean If true, group is an assigned carrier. 
function OPSTRANSPORT:IsCarrier(CarrierGroup)

  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier --Ops.OpsGroup#OPSGROUP
    if carrier.groupname==CarrierGroup.groupname then
      return true
    end
  end

  return false
end

--- Check if transport is ready to be started.
-- * Start time passed.
-- * Stop time did not pass already.
-- * All start conditions are true.
-- @param #OPSTRANSPORT self
-- @return #boolean If true, mission can be started.
function OPSTRANSPORT:IsReadyToGo()

  -- Debug text.
  local text=self.lid.."Is ReadyToGo? "
  
  -- Current abs time.
  local Tnow=timer.getAbsTime()

  -- Start time did not pass yet.
  if self.Tstart and Tnow<self.Tstart or false then
    text=text.."No, start time not passed!"
    return false
  end
  
  -- Stop time already passed.
  if self.Tstop and Tnow>self.Tstop or false then
    text=text.."Nope, stop time already passed!"
    self:T(text)
    return false
  end
  
  -- All start conditions true?
  local startme=self:EvalConditionsAll(self.conditionStart)
  
  -- Nope, not yet.
  if not startme then
    text=text..("No way, at least one start condition is not true!")
    self:I(text)
    return false
  end
  
  -- We're good to go!
  text=text.."Yes!"
  self:T(text)
  return true
end

--- Check if all cargo was delivered (or is dead).
-- @param #OPSTRANSPORT self
-- @return #boolean If true, all possible cargo was delivered. 
function OPSTRANSPORT:IsDelivered()
  return self:is(OPSTRANSPORT.Status.DELIVERED)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Update
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Status" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterStatus(From, Event, To)

  -- Current FSM state.
  local fsmstate=self:GetState()
  
  if self.verbose>=1 then  
  
    -- Info text.
    local text=string.format("%s [%s --> %s]: Ncargo=%d/%d, Ncarrier=%d/%d", fsmstate:upper(), self.pickupzone:GetName(), self.deployzone:GetName(), self.Ncargo, self.Ndelivered, #self.carriers,self.Ncarrier)

    -- Info about cargo and carrier.    
    if self.verbose>=2 then
    
      text=text..string.format("\nCargos:")
      for _,_cargo in pairs(self.cargos) do
        local cargo=_cargo  --Ops.OpsGroup#OPSGROUP.CargoGroup
        local carrier=cargo.opsgroup:_GetMyCarrierElement()
        local name=carrier and carrier.name or "none"
        local cstate=carrier and carrier.status or "N/A"
        text=text..string.format("\n- %s: %s [%s], weight=%d kg, carrier=%s [%s], delivered=%s", 
        cargo.opsgroup:GetName(), cargo.opsgroup.cargoStatus:upper(), cargo.opsgroup:GetState(), cargo.opsgroup:GetWeightTotal(), name, cstate, tostring(cargo.delivered))
      end
      
      text=text..string.format("\nCarriers:")
      for _,_carrier in pairs(self.carriers) do
        local carrier=_carrier --Ops.OpsGroup#OPSGROUP
        text=text..string.format("\n- %s: %s [%s], Cargo Bay [current/reserved/total]=%d/%d/%d kg [free %d/%d/%d kg]", 
        carrier:GetName(), carrier.carrierStatus:upper(), carrier:GetState(), 
        carrier:GetWeightCargo(nil, false), carrier:GetWeightCargo(), carrier:GetWeightCargoMax(), 
        carrier:GetFreeCargobay(nil, false), carrier:GetFreeCargobay(), carrier:GetFreeCargobayMax())
      end
    end
    
    self:I(self.lid..text)
  end
  
  -- Check if all cargo was delivered (or is dead).
  self:_CheckDelivered()

  -- Update status again.
  if not self:IsDelivered() then
    self:__Status(-30)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Planned" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterPlanned(From, Event, To)
  self:I(self.lid..string.format("New status %s", OPSTRANSPORT.Status.PLANNED))
end

--- On after "Scheduled" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterScheduled(From, Event, To)
  self:I(self.lid..string.format("New status %s", OPSTRANSPORT.Status.SCHEDULED))
end

--- On after "Executing" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterExecuting(From, Event, To)
  self:I(self.lid..string.format("New status %s", OPSTRANSPORT.Status.EXECUTING))
end

--- On after "Delivered" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterDelivered(From, Event, To)
  self:I(self.lid..string.format("New status %s", OPSTRANSPORT.Status.DELIVERED))
  
  -- Inform all assigned carriers that cargo was delivered. They can have this in the queue or are currently processing this transport.  
  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier --Ops.OpsGroup#OPSGROUP
    if self:GetCarrierTransportStatus(carrier)~=OPSTRANSPORT.Status.DELIVERED then
      carrier:Delivered(self)
    end 
  end
  
end

--- On after "Loaded" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo OPSGROUP that was loaded into a carrier.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier OPSGROUP that was loaded into a carrier.
-- @param Ops.OpsGroup#OPSGROUP.Element CarrierElement Carrier element.
function OPSTRANSPORT:onafterLoaded(From, Event, To, OpsGroupCargo, OpsGroupCarrier, CarrierElement)
  self:I(self.lid..string.format("Loaded OPSGROUP %s into carrier %s", OpsGroupCargo:GetName(), tostring(CarrierElement.name)))
end

--- On after "Unloaded" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo OPSGROUP that was unloaded from a carrier.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier Carrier OPSGROUP that unloaded the cargo.
function OPSTRANSPORT:onafterUnloaded(From, Event, To, OpsGroupCargo, OpsGroupCarrier)
  self:I(self.lid..string.format("Unloaded OPSGROUP %s", OpsGroupCargo:GetName()))
end

--- On after "DeadCarrierGroup" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup Carrier OPSGROUP that is dead. 
function OPSTRANSPORT:onafterDeadCarrierGroup(From, Event, To, OpsGroup)
  self:I(self.lid..string.format("Carrier OPSGROUP %s dead!", OpsGroup:GetName()))
  -- Remove group from carrier list/table.
  self:_DelCarrier(OpsGroup)
end

--- On after "DeadCarrierAll" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state. 
function OPSTRANSPORT:onafterDeadCarrierAll(From, Event, To)
  self:I(self.lid..string.format("ALL Carrier OPSGROUPs are dead! Setting stage to PLANNED if not all cargo was delivered."))
  if not self:IsDelivered() then
    self:Planned()
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if all cargo of this transport assignment was delivered.
-- @param #OPSTRANSPORT self
function OPSTRANSPORT:_CheckDelivered()

  -- First check that at least one cargo was added (as we allow to do that later).
  if self.Ncargo>0 then

    local done=true
    local dead=true
    for _,_cargo in pairs(self.cargos) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      
      if cargo.delivered then
        -- This one is delivered.
        dead=false
      elseif cargo.opsgroup==nil then
        -- This one is nil?!
        dead=false
      elseif cargo.opsgroup:IsDestroyed() then
        -- This one was destroyed.
      elseif cargo.opsgroup:IsDead() then
        -- This one is dead.
        dead=false
      elseif cargo.opsgroup:IsStopped() then
        -- This one is stopped.
        dead=false
      else
        done=false --Someone is not done!
        dead=false
      end
     
    end
    
    if dead then
      --self:CargoDead()
      self:I(self.lid.."All cargo DEAD!")
      self:Delivered()
    elseif done then
      self:I(self.lid.."All cargo delivered")
      self:Delivered()  
    end
    
  end
  
end

--- Check if all required cargos are loaded.
-- @param #OPSTRANSPORT self
-- @return #boolean If true, all required cargos are loaded or there is no required cargo.
function OPSTRANSPORT:_CheckRequiredCargos()
  
  if self.requiredCargos==nil or #self.requiredCargos==0 then
    return true
  end
  
  local carrierNames=self:_GetCarrierNames()
  
  local gotit=true
  for _,_cargo in pairs(self.requiredCargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP
    
    
    if not cargo:IsLoaded(carrierNames) then
      return false
    end
    
  end
  
  return true
end

--- Check if all given condition are true.
-- @param #OPSTRANSPORT self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, all conditions were true. Returns false if at least one condition returned false.
function OPSTRANSPORT:EvalConditionsAll(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --#OPSTRANSPORT.Condition
  
    -- Call function.
    local istrue=condition.func(unpack(condition.arg))
    
    -- Any false will return false.
    if not istrue then
      return false
    end
    
  end

  -- All conditions were true.
  return true
end



--- Find transfer carrier element for cargo group.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CargoGroup The cargo group that needs to be loaded into a carrier unit/element of the carrier group.
-- @param Core.Zone#ZONE Zone (Optional) Zone where the carrier must be in.
-- @return Ops.OpsGroup#OPSGROUP.Element New carrier element for cargo or nil.
-- @return Ops.OpsGroup#OPSGROUP New carrier group for cargo or nil.
function OPSTRANSPORT:FindTransferCarrierForCargo(CargoGroup, Zone)

  local carrier=nil --Ops.OpsGroup#OPSGROUP.Element
  local carrierGroup=nil --Ops.OpsGroup#OPSGROUP
  
  --TODO: maybe sort the carriers wrt to largest free cargo bay. Or better smallest free cargo bay that can take the cargo group weight.
  
  for _,_carrier in pairs(self.disembarkCarriers or {}) do
    local carrierGroup=_carrier --Ops.OpsGroup#OPSGROUP
    
    -- First check if carrier is alive and loading cargo.
    if carrierGroup and carrierGroup:IsAlive() and carrierGroup:IsLoading() then
    
      -- Find an element of the group that has enough free space.
      carrier=carrierGroup:FindCarrierForCargo(CargoGroup)
      
      if carrier then
        if Zone==nil or Zone:IsCoordinateInZone(carrier.unit:GetCoordinate()) then
          return carrier, carrierGroup      
        else
          self:T3(self.lid.."Got transfer carrier but carrier not in zone (yet)!")
        end
      else
        self:T3(self.lid.."No transfer carrier available!")
      end
      
    end
  end

  return nil, nil
end

--- Create a cargo group data structure.
-- @param #OPSTRANSPORT self
-- @param Wrapper.Group#GROUP group The GROUP or OPSGROUP object.
-- @return Ops.OpsGroup#OPSGROUP.CargoGroup Cargo group data.
function OPSTRANSPORT:_CreateCargoGroupData(group)

  local opsgroup=self:_GetOpsGroupFromObject(group)

  local cargo={} --Ops.OpsGroup#OPSGROUP.CargoGroup
  
  cargo.opsgroup=opsgroup
  cargo.delivered=false
  cargo.status="Unknown"
  cargo.disembarkCarrierElement=nil
  cargo.disembarkCarrierGroup=nil

  return cargo
end

--- Get an OPSGROUP from a given OPSGROUP or GROUP object. If the object is a GROUUP, an OPSGROUP is created automatically. 
-- @param #OPSTRANSPORT self
-- @param Core.Base#BASE Object The object, which can be a GROUP or OPSGROUP.
-- @return Ops.OpsGroup#OPSGROUP Ops Group.
function OPSTRANSPORT:_GetOpsGroupFromObject(Object)

  local opsgroup=nil

  if Object:IsInstanceOf("OPSGROUP") then
    -- We already have an OPSGROUP
    opsgroup=Object
  elseif Object:IsInstanceOf("GROUP") then
  
    -- Look into DB and try to find an existing OPSGROUP.
    opsgroup=_DATABASE:GetOpsGroup(Object)
    
    if not opsgroup then
      if Object:IsAir() then
        opsgroup=FLIGHTGROUP:New(Object)
      elseif Object:IsShip() then
        opsgroup=NAVYGROUP:New(Object)
      else
        opsgroup=ARMYGROUP:New(Object)
      end
    end
    
  else
    self:E(self.lid.."ERROR: Object must be a GROUP or OPSGROUP object!")
    return nil
  end

  return opsgroup
end

