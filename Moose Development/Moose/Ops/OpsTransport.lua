--- **Ops** - Troop transport assignment for OPS groups.
-- 
-- ## Main Features:
--
--    * Transport troops from A to B.
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
-- @field #table cargos Cargos. Each element is a @{#OPSGROUP.Cargo}.
-- @field #table carriers Carriers assigned for this transport.
-- @field #string status Status of the transport. See @{#OPSTRANSPORT.Status}.
-- @field #number prio Priority of this transport. Should be a number between 0 (high prio) and 100 (low prio).
-- @field #number importance Importance of this transport. Smaller=higher.
-- @field #number Tstart Start time in *abs.* seconds.
-- @field #number Tstop Stop time in *abs.* seconds. Default `#nil` (never stops).
-- @field Core.Zone#ZONE pickupzone Zone where the cargo is picked up.
-- @field Core.Zone#ZONE deployzone Zone where the cargo is dropped off.
-- @field Core.Zone#ZONE embarkzone (Optional) Zone where the cargo is supposed to embark. Default is the pickup zone.
-- @field Core.Zone#ZONE disembarkzone (Optional) Zone where the cargo is disembarked. Default is the deploy zone.
-- @field Core.Zone#ZONE unboardzone (Optional) Zone where the cargo is going to after disembarkment.
-- @field Ops.OpsGroup#OPSGROUP carrierGroup The new carrier group.
-- @field #boolean disembarkActivation Activation setting when group is disembared from carrier.
-- @field #boolean disembarkInUtero Do not spawn the group in any any state but leave it "*in utero*". For example, to directly load it into another carrier.
-- @field #number Ncargo Total number of cargo groups.
-- @field #number Ncarrier Total number of assigned carriers.
-- @field #number Ndelivered Total number of cargo groups delivered.
-- @extends Core.Fsm#FSM

--- *Victory is the beautiful, bright-colored flower. Transport is the stem without which it could never have blossomed.* -- Winston Churchill
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\Transport\_Main.png)
--
-- # The OPSTRANSPORT Concept
-- 
-- Transport OPSGROUPS using carriers such as APCs, helicopters or airplanes.
-- 
-- @field #OPSTRANSPORT
OPSTRANSPORT = {
  ClassName       = "OPSTRANSPORT",
  verbose         =  1,
  cargos          = {},
  carriers        = {},
  carrierTransportStatus = {},  
}

--- Cargo transport status.
-- @type OPSTRANSPORT.Status
-- @field #string PLANNING Planning state.
-- @field #string SCHEDULED Transport is scheduled in the cargo queue.
-- @field #string EXECUTING Transport is being executed.
-- @field #string DELIVERED Transport was delivered. 
OPSTRANSPORT.Status={
  PLANNED="planned",
  SCHEDULED="scheduled",
  EXECUTING="executing",
  DELIVERED="delivered",
}

--- Transport ID.
_OPSTRANSPORTID=0

--- Army Group version.
-- @field #string version
OPSTRANSPORT.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add start conditions.
-- TODO: Check carrier(s) dead.

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
  self.status=OPSTRANSPORT.Status.PLANNING
    
  self.pickupzone=Pickupzone
  self.deployzone=Deployzone
  self.embarkzone=Pickupzone
  self.carrierGroup=nil
  self.cargos={}
  self.carriers={}
  self.Ncargo=0
  self.Ncarrier=0
  self.Ndelivered=0

  
  self:SetPriority()
  self:SetTime()
  
  -- Add cargo groups.
  if GroupSet then
    self:AddCargoGroups(GroupSet, Pickupzone, Deployzone)
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
  self:AddTransition("*",                           "Unloaded",         "*")
  

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
function OPSTRANSPORT:AddCargoGroups(GroupSet, Pickupzone, Deployzone)

  -- Check type of GroupSet provided.
  if GroupSet:IsInstanceOf("GROUP") or GroupSet:IsInstanceOf("OPSGROUP") then
  
    -- We got a single GROUP or OPSGROUP object.
    local cargo=self:_CreateCargoGroupData(GroupSet, Pickupzone, Deployzone)
    
    if cargo  then --and self:CanCargo(cargo.opsgroup)
      table.insert(self.cargos, cargo)
      self.Ncargo=self.Ncargo+1
    end
    
  else
  
    -- We got a SET_GROUP object.
    
    for _,group in pairs(GroupSet.Set) do
    
      local cargo=self:_CreateCargoGroupData(group, Pickupzone, Deployzone)
      
      if cargo then
        table.insert(self.cargos, cargo)
        self.Ncargo=self.Ncargo+1
      end
      
    end
  end
  
  -- Debug info.
  if self.verbose>=0 then
    local text=string.format("Created Cargo Transport (UID=%d) from %s(%s) --> %s(%s)", 
    self.uid, self.pickupzone:GetName(), self.embarkzone and self.embarkzone:GetName() or "none", self.deployzone:GetName(), self.disembarkzone and self.disembarkzone:GetName() or "none")
    local Weight=0
    for _,_cargo in pairs(self.cargos) do
      local cargo=_cargo --#OPSGROUP.CargoGroup
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

--- Add a carrier assigned for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_AddCarrier(CarrierGroup)

  if not self:IsCarrier(CarrierGroup) then
  
    -- Increase carrier count.
    self.Ncarrier=self.Ncarrier+1

    -- Set trans
    self:SetCarrierTransportStatus(CarrierGroup, OPSTRANSPORT.Status.SCHEDULED)
    
    self:Scheduled()
    
    table.insert(self.carriers, CarrierGroup)
    
  end 
  
  return self
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



--- Create a cargo group data structure.
-- @param #OPSTRANSPORT self
-- @param Wrapper.Group#GROUP group The GROUP object.
-- @param Core.Zone#ZONE Pickupzone Pickup zone.
-- @param Core.Zone#ZONE Deployzone Deploy zone.
-- @return #OPSGROUP.CargoGroup Cargo group data.
function OPSTRANSPORT:_CreateCargoGroupData(group, Pickupzone, Deployzone)

  local opsgroup=nil
  
  if group:IsInstanceOf("OPSGROUP") then
    opsgroup=group
  elseif group:IsInstanceOf("GROUP") then
  
    opsgroup=_DATABASE:GetOpsGroup(group)
    
    if not opsgroup then
      if group:IsAir() then
        opsgroup=FLIGHTGROUP:New(group)
      elseif group:IsShip() then
        opsgroup=NAVYGROUP:New(group)
      else
        opsgroup=ARMYGROUP:New(group)
      end
    end
    
  else
    self:E(self.lid.."ERROR: Cargo must be a GROUP or OPSGROUP object!")
    return nil
  end

  local cargo={} --#OPSGROUP.CargoGroup
  
  cargo.opsgroup=opsgroup
  cargo.delivered=false
  cargo.status="Unknown"
  cargo.pickupzone=Pickupzone
  cargo.deployzone=Deployzone

  return cargo
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
  

  local text=string.format("%s [%s --> %s]: Ncargo=%d/%d, Ncarrier=%d", fsmstate:upper(), self.pickupzone:GetName(), self.deployzone:GetName(), self.Ncargo, self.Ndelivered, self.Ncarrier)
  
  text=text..string.format("\nCargos:")
  for _,_cargo in pairs(self.cargos) do
    local cargo=_cargo  --Ops.OpsGroup#OPSGROUP.CargoGroup
    local name=cargo.opsgroup.carrier and cargo.opsgroup.carrier.name or "none"
    text=text..string.format("\n- %s: %s [%s], weight=%d kg, carrier=%s", cargo.opsgroup:GetName(), cargo.opsgroup.cargoStatus:upper(), cargo.opsgroup:GetState(), cargo.opsgroup:GetWeightTotal(), name)
  end
  
  text=text..string.format("\nCarriers:")
  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier --Ops.OpsGroup#OPSGROUP
    text=text..string.format("\n- %s: %s [%s], cargo=%d/%d kg, free cargo bay %d/%d kg", 
    carrier:GetName(), carrier.carrierStatus:upper(), carrier:GetState(), carrier:GetWeightCargo(), carrier:GetWeightCargoMax(), carrier:GetFreeCargobayMax(true), carrier:GetFreeCargobayMax())
  end  
  
  self:I(self.lid..text)
  
  -- Check if all cargo was delivered (or is dead).
  self:_CheckDelivered()

  self:__Status(-30)
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

--- On after "Unloaded" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup OPSGROUP that was unloaded from a carrier.
function OPSTRANSPORT:onafterUnloaded(From, Event, To, OpsGroup)
  self:I(self.lid..string.format("Unloaded OPSGROUP %s", OpsGroup:GetName()))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if all cargo of this transport assignment was delivered.
-- @param #OPSTRANSPORT self
function OPSTRANSPORT:_CheckDelivered()

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
