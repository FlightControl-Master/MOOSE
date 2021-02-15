--- **Ops** - Troop transport assignment of OPS groups.
-- 
-- ## Main Features:
--
--    * Patrol waypoints *ad infinitum*
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Armygroup).
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
-- @field #table cargos Cargos. Each element is a @{#OPSGROUP.Cargo}.
-- @field #string status Status of the transport. See @{#OPSTRANSPORT.Status}.
-- @field #number prio Priority of this transport. Should be a number between 0 (high prio) and 100 (low prio).
-- @field #number importance Importance of this transport. Smaller=higher.
-- @field #number Tstart Start time in *abs.* seconds.
-- @field Core.Zone#ZONE pickupzone Zone where the cargo is picked up.
-- @field Core.Zone#ZONE deployzone Zone where the cargo is dropped off.
-- @field Core.Zone#ZONE embarkzone (Optional) Zone where the cargo is supposed to embark. Default is the pickup zone.
-- @field Core.Zone#ZONE disembarkzone (Optional) Zone where the cargo is disembarked. Default is the deploy zone.
-- @field Ops.OpsGroup#OPSGROUP carrierGroup The new carrier group.
-- @extends Core.Fsm#FSM

--- *Your soul may belong to Jesus, but your ass belongs to the marines.* -- Eugene B. Sledge
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\ArmyGroup\_Main.png)
--
-- # The OPSTRANSPORT Concept
-- 
-- This class enhances naval groups.
-- 
-- @field #OPSTRANSPORT
OPSTRANSPORT = {
  ClassName       = "OPSTRANSPORT",
  verbose         =  1,
  cargos          = {},
}

--- Cargo transport status.
-- @type OPSTRANSPORT.Status
-- @field #string PLANNING Planning state.
-- @field #string SCHEDULED Transport is scheduled in the cargo queue.
-- @field #string EXECUTING Transport is being executed.
-- @field #string DELIVERED Transport was delivered. 
OPSTRANSPORT.Status={
  PLANNING="planning",
  SCHEDULED="scheduled",
  EXECUTING="executing",
  DELIVERED="delivered",
}

_OPSTRANSPORTID=0

--- Army Group version.
-- @field #string version
OPSTRANSPORT.version="0.0.1"

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
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSTRANSPORT %s --> %s | ", Pickupzone:GetName(), Deployzone:GetName())

  _OPSTRANSPORTID=_OPSTRANSPORTID+1
  
  self.uid=_OPSTRANSPORTID
  self.status=OPSTRANSPORT.Status.PLANNING  
  self.pickupzone=Pickupzone
  self.deployzone=Deployzone
  self.embarkzone=Pickupzone
  self.disembarkzone=Deployzone
  self.prio=50
  self.importance=nil
  self.Tstart=timer.getAbsTime()
  self.carrierGroup=nil
  self.cargos={}  


  -- Check type of GroupSet provided.
  if GroupSet:IsInstanceOf("GROUP") or GroupSet:IsInstanceOf("OPSGROUP") then
  
    -- We got a single GROUP or OPSGROUP objectg.
    local cargo=self:CreateCargoGroupData(GroupSet, Pickupzone, Deployzone)
    
    if cargo  then --and self:CanCargo(cargo.opsgroup)
      table.insert(self.cargos, cargo)
    end
    
  else
  
    -- We got a SET_GROUP object.
    
    for _,group in pairs(GroupSet.Set) do
    
      local cargo=self:_CreateCargoGroupData(group, Pickupzone, Deployzone)
      
      if cargo then --and self:CanCargo(cargo.opsgroup) then
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSTRANSPORT class object.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE EmbarkZone Zone where the troops are embarked.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetEmbarkZone(EmbarkZone)
  self.embarkzone=EmbarkZone or self.pickupzone
  return self
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
  else
  
    opsgroup=_DATABASE:GetOpsGroup(group)
    
    if not opsgroup then
      if group:IsAir() then
        opsgroup=FLIGHTGROUP:New(group)
      elseif group:IsShip() then
        opsgroup=NAVYGROUP:New(group)
      else
        opsgroup=ARMYGROUP:New(group)
      end
    else
      --env.info("FF found opsgroup in createcargo")
    end
    
  end

  local cargo={} --#OPSGROUP.CargoGroup
  
  cargo.opsgroup=opsgroup
  cargo.delivered=false
  cargo.status="Unknown"
  cargo.pickupzone=Pickupzone
  cargo.deployzone=Deployzone

  return cargo
end
