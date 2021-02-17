--- **Ops** - Troop transport assignment of OPS groups.
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
-- @field Ops.OpsGroup#OPSGROUP carrierGroup The new carrier group.
-- @field disembarkActivation Activation setting when group is disembared from carrier.
-- @field disembarkInUtero Do not spawn the group in any any state but leave it "*in utero*". For example, to directly load it into another carrier.
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
OPSTRANSPORT.version="0.0.2"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot. 

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
  self.lid=string.format("OPSTRANSPORT [UID=%d] %s --> %s | ", _OPSTRANSPORTID, Pickupzone:GetName(), Deployzone:GetName())
  
  -- Defaults.
  self.uid=_OPSTRANSPORTID
  self.status=OPSTRANSPORT.Status.PLANNING  
  self.pickupzone=Pickupzone
  self.deployzone=Deployzone
  self.embarkzone=Pickupzone
  self.disembarkzone=Deployzone
  self.prio=50
  self.importance=nil
  self.Tstart=timer.getAbsTime()+5
  self.carrierGroup=nil
  self.cargos={}
  self.carriers={}
  
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

  self:AddTransition("*",                      "Status",           "*")
  self:AddTransition("*",                      "Stop",             "*")
  
  -- Call status update
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
    end
    
  else
  
    -- We got a SET_GROUP object.
    
    for _,group in pairs(GroupSet.Set) do
    
      local cargo=self:_CreateCargoGroupData(group, Pickupzone, Deployzone)
      
      if cargo then
        table.insert(self.cargos, cargo)
      end
      
    end
  end
  
  -- Debug info.
  if self.verbose>=0 then
    local text=string.format("Created Cargo Transport (UID=%d) from %s(%s) --> %s(%s)", 
    self.uid, self.pickupzone:GetName(), self.embarkzone:GetName(), self.deployzone:GetName(), self.disembarkzone:GetName())
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
  self.disembarkzone=DisembarkZone or self.deployzone
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


--- Add a carrier assigned for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_AddCarrier(CarrierGroup)

  self:SetCarrierTransportStatus(CarrierGroup, OPSTRANSPORT.Status.SCHEDULED)
  
  self:Scheduled()
  
  table.insert(self.carriers, CarrierGroup) 
  
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

  local fsmstate=self:GetState()

  local text=string.format("State=%s", fsmstate)
  
  for _,_cargo in pairs(self.cargos) do
    local cargo=_cargo  --Ops.OpsGroup#OPSGROUP.CargoGroup
  end
  
  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier
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
  
  -- TODO: Inform all assigned carriers that cargo was delivered. They can have this in the queue or are currently processing this transport.
  
  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier --Ops.OpsGroup#OPSGROUP
    if self:GetCarrierTransportStatus(carrier)~=OPSTRANSPORT.Status.DELIVERED then
      carrier:Delivered(self)
    end 
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- Check if all cargo of this transport assignment was delivered.
-- @param #OPSTRANSPORT self
function OPSTRANSPORT:_CheckDelivered()

  local done=true
  for _,_cargo in pairs(self.cargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    
    if cargo.delivered then
      -- This one is delivered.
    elseif cargo.opsgroup==nil or cargo.opsgroup:IsDead() or cargo.opsgroup:IsStopped() then
      -- This one is dead.
    else
      done=false --Someone is not done!
    end
   
  end
  
  if done then
    self:Delivered()  
  end
  
end
