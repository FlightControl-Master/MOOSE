--- **Functional** -- Send a truck to supply artillery groups.
--
-- ===
--
-- **AMMOTRUCK** - Send a truck to supply artillery groups.
--
-- ===
--
-- ## Missions:
--
-- ### [tbd](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/tbd)
--
-- ===
--
-- ### Author : **applevangelist **
--
-- @module Functional.AmmoTruck
-- @image Functional.AmmoTruck.jpg
--
-- Date: Sep 2022

-------------------------------------------------------------------------
--- **AMMOTRUCK** class, extends Core.FSM#FSM
-- @type AMMOTRUCK
-- @field #string ClassName Class Name
-- @field #string lid Lid for log entries
-- @field #string version Version string
-- @field #string alias Alias name
-- @field #boolean debug Debug flag
-- @field #table trucklist List of (alive) #AMMOTRUCK.data trucks
-- @field #table targetlist  List of (alive) #AMMOTRUCK.data artillery
-- @field #number coalition Coalition this is for
-- @field Core.Set#SET_GROUP truckset SET of trucks
-- @field Core.Set#SET_GROUP targetset SET of artillery
-- @field #table remunitionqueue List of (alive) #AMMOTRUCK.data artillery to be reloaded
-- @field #table waitingtargets  List of (alive) #AMMOTRUCK.data artillery waiting
-- @field #number ammothreshold Threshold (min) ammo before sending a truck
-- @field #number remunidist Max distance trucks will go
-- @field #number monitor Monitor interval in seconds
-- @field #number unloadtime Unload time in seconds
-- @field #number waitingtime Max waiting time in seconds
-- @field #boolean routeonroad Route truck on road if true (default)
-- @extends Core.FSM#FSM

--- *Amateurs talk about tactics, but professionals study logistics.* - Gen. Robert H. Barrow, USMC
--
-- Simple Class to re-arm your artillery with trucks.
--
-- #AMMOTRUCK
-- 
-- * Controls a SET\_GROUP of trucks which will re-arm a SET\_GROUP of artillery groups when they run out of ammunition. 
-- 
-- ## 1 The AMMOTRUCK concept
-- 
-- A SET\_GROUP of trucks which will re-arm a SET\_GROUP of artillery groups when they run out of ammunition. They will be based on a
-- homebase and drive from there to the artillery groups and then back home.
-- Trucks are the **only known in-game mechanic** to re-arm artillery and other units in DCS. Working units are e.g.: M-939 (blue), Ural-375 and ZIL-135 (both red).
-- 
-- ## 2 Set-up
--
-- Define a set of trucks and a set of artillery:  
-- 
--            local truckset = SET_GROUP:New():FilterCoalitions("blue"):FilterActive(true):FilterCategoryGround():FilterPrefixes("Ammo Truck"):FilterStart()
--            local ariset = SET_GROUP:New():FilterCoalitions("blue"):FilterActive(true):FilterCategoryGround():FilterPrefixes("Artillery"):FilterStart()
--
-- Create an AMMOTRUCK object to take care of the artillery using the trucks, with a homezone:  
-- 
--            local ammotruck = AMMOTRUCK:New(truckset,ariset,coalition.side.BLUE,"Logistics",ZONE:FindByName("HomeZone") 
--            
-- ## 2 Options
-- 
--            ammotruck.ammothreshold = 5 -- send a truck when down to this many rounds
--            ammotruck.remunidist = 20000 -- 20km - send trucks max this far from home
--            ammotruck.unloadtime = 600 -- 10 minutes - min time to unload ammunition
--            ammotruck.waitingtime = 1800 -- 30 mintes - wait max this long until remunition is done
--            ammotruck.monitor = -60 - 1 minute - AMMOTRUCK checks on things every 1 minute
--            ammotruck.routeonroad = true - Trucks will **try** to drive on roads
-- 
-- ## 3 FSM Events to shape mission
-- 
-- Truck has been sent off:
-- 
--            function ammotruck:OnAfterRouteTruck(From, Event, To, Truckdata, Aridata)
--              ...
--            end
--            
-- Truck has arrived:
-- 
--            function ammotruck:OnAfterTruckArrived(From, Event, To, Truckdata)
--              ...
--            end 
-- 
-- Truck is unloading:
-- 
--            function ammotruck:OnAfterTruckUnloading(From, Event, To, Truckdata)
--              ...
--            end 
-- 
-- Truck is returning home:
-- 
--            function ammotruck:OnAfterTruckReturning(From, Event, To, Truckdata)
--              ...
--            end  
-- 
-- Truck is arrived at home:
-- 
--            function ammotruck:OnAfterTruckHome(From, Event, To, Truckdata)
--              ...
--            end 
--                        
-- @field #AMMOTRUCK
AMMOTRUCK = {
  ClassName = "AMMOTRUCK",
  lid = "",
  version = "0.0.1",
  alias = "",
  debug = false,
  trucklist = {},
  targetlist = {},
  coalition = nil,
  truckset = nil,
  targetset = nil,
  remunitionqueue = {},
  waitingtargets = {},
  ammothreshold = 5,
  remunidist = 20000,
  monitor = -60,
  unloadtime = 600,
  waitingtime = 1800,
  routeonroad = true
}

---
-- @type AMMOTRUCK.State
AMMOTRUCK.State = {
  IDLE = "idle",
  DRIVING = "driving",
  ARRIVED = "arrived",
  UNLOADING = "unloading",
  RETURNING = "returning",
  WAITING = "waiting",
  RELOADING = "reloading",
  OUTOFAMMO = "outofammo",
  REQUESTED = "requested",
}

---
--@type AMMOTRUCK.data
--@field Wrapper.Group#GROUP group
--@field #string name
--@field #AMMOTRUCK.State state
--@field #number timestamp
--@field #number ammo
--@field Core.Point#COORDINATE coordinate
--@field #string targetname
--@field Wrapper.Group#GROUP targetgroup
--@field Core.Point#COORDINATE targetcoordinate

---
-- @param #AMMOTRUCK self
-- @param Core.Set#SET_GROUP Truckset Set of truck groups
-- @param Core.Set#SET_GROUP Targetset Set of artillery groups
-- @param #number Coalition Coalition
-- @param #string Alias Alias Name
-- @param Core.Zone#ZONE Homezone Home, return zone for trucks 
-- @return #AMMOTRUCK self
-- @usage
-- Define a set of trucks and a set of artillery:  
--            local truckset = SET_GROUP:New():FilterCoalitions("blue"):FilterActive(true):FilterCategoryGround():FilterPrefixes("Ammo Truck"):FilterStart()
--            local ariset = SET_GROUP:New():FilterCoalitions("blue"):FilterActive(true):FilterCategoryGround():FilterPrefixes("Artillery"):FilterStart()
--
-- Create an AMMOTRUCK object to take care of the artillery using the trucks, with a homezone:  
--            local ammotruck = AMMOTRUCK:New(truckset,ariset,coalition.side.BLUE,"Logistics",ZONE:FindByName("HomeZone") 
function AMMOTRUCK:New(Truckset,Targetset,Coalition,Alias,Homezone)
  
    -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, FSM:New()) -- #AMMOTRUCK
  
  self.truckset = Truckset -- Core.Set#SET_GROUP
  self.targetset = Targetset -- Core.Set#SET_GROUP
  self.coalition = Coalition -- #number
  self.alias = Alias -- #string
  self.debug = false
  self.remunitionqueue = {}
  self.trucklist = {}
  self.targetlist = {}
  self.ammothreshold = 5
  self.remunidist = 20000
  self.homezone = Homezone -- Core.Zone#ZONE
  self.waitingtime = 1800 
  
  -- Log id.
  self.lid=string.format("AMMOTRUCK %s | %s | ", self.version, self.alias)
  
  self:SetStartState("Stopped")
  self:AddTransition("Stopped",     "Start",               "Running")
  self:AddTransition("*",           "Monitor",             "*")
  self:AddTransition("*",           "RouteTruck",          "*")
  self:AddTransition("*",           "TruckArrived",        "*")
  self:AddTransition("*",           "TruckUnloading",      "*")
  self:AddTransition("*",           "TruckReturning",      "*")
  self:AddTransition("*",           "TruckHome",           "*")
  self:AddTransition("*",           "Stop",                "Stopped")
  
  self:__Start(math.random(5,10))
  
  self:I(self.lid .. "Started")
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #table dataset table of #AMMOTRUCK.data entries
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckDrivingTrucks(dataset)
  self:T(self.lid .. " CheckDrivingTrucks")
  local data = dataset 
  for _,_data in pairs (data) do
    local truck = _data -- #AMMOTRUCK.data
    -- see if we arrived at destination
    local coord = truck.group:GetCoordinate()
    local tgtcoord = truck.targetcoordinate
    local dist = coord:Get2DDistance(tgtcoord)
    if dist <= 150 then
      -- arrived
      truck.state = AMMOTRUCK.State.ARRIVED
      truck.timestamp = timer.getAbsTime()
      truck.coordinate = coord
      self:__TruckArrived(1,truck)
    end
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @param Wrapper.Group#GROUP Group
-- @return #AMMOTRUCK self 
function AMMOTRUCK:GetAmmoStatus(Group)
  local ammotot, shells, rockets, bombs, missiles, narti  = Group:GetAmmunition()
  --self:I({ammotot, shells, rockets, bombs, missiles, narti})
  return rockets+missiles+narti
end

---
-- @param #AMMOTRUCK self
-- @param #table dataset table of #AMMOTRUCK.data entries
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckWaitingTargets(dataset)
  self:T(self.lid .. " CheckWaitingTargets")
  local data = dataset 
  for _,_data in pairs (data) do
    local truck = _data -- #AMMOTRUCK.data
    -- see how long we're waiting - maybe ammo truck is dead?
    local Tnow = timer.getAbsTime()
    local Tdiff = Tnow - truck.timestamp
    if Tdiff > self.waitingtime then
      local hasammo = self:GetAmmoStatus(truck.group)
      --if truck.group:GetAmmunition() <= self.ammothreshold then
      if hasammo <= self.ammothreshold then
        truck.state = AMMOTRUCK.State.OUTOFAMMO
      else
        truck.state = AMMOTRUCK.State.IDLE
      end
    end
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #table dataset table of #AMMOTRUCK.data entries
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckReturningTrucks(dataset)
  self:T(self.lid .. " CheckReturningTrucks")
  local data = dataset
  local tgtcoord = self.homezone:GetCoordinate()
  local radius = self.homezone:GetRadius()
  for _,_data in pairs (data) do
    local truck = _data -- #AMMOTRUCK.data
    -- see if we arrived at destination
    local coord = truck.group:GetCoordinate()
    local dist = coord:Get2DDistance(tgtcoord)
    self:T({name=truck.name,radius=radius,distance=dist})
    if dist <= radius then
      -- arrived
      truck.state = AMMOTRUCK.State.IDLE
      truck.timestamp = timer.getAbsTime()
      truck.coordinate = coord
      self:__TruckHome(1,truck)
    end
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #string name Artillery group name to find
-- @return #AMMOTRUCK.data Data
function AMMOTRUCK:FindTarget(name)
  self:T(self.lid .. " FindTarget")
  local data = nil
  local dataset = self.targetlist
  for _,_entry in pairs(dataset) do
    local entry = _entry -- #AMMOTRUCK.data
    if entry.name == name then
      data = entry
      break
    end
  end
  return data
end

---
-- @param #AMMOTRUCK self
-- @param #string name Truck group name to find
-- @return #AMMOTRUCK.data Data
function AMMOTRUCK:FindTruck(name)
  self:T(self.lid .. " FindTruck")
  local data = nil
  local dataset = self.trucklist
  for _,_entry in pairs(dataset) do
    local entry = _entry -- #AMMOTRUCK.data
    if entry.name == name then
      data = entry
      break
    end
  end
  return data
end

---
-- @param #AMMOTRUCK self
-- @param #table dataset table of #AMMOTRUCK.data entries
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckArrivedTrucks(dataset)
  self:T(self.lid .. " CheckArrivedTrucks")
  local data = dataset 
  for _,_data in pairs (data) do
    -- set to unloading
    local truck = _data -- #AMMOTRUCK.data
    truck.state = AMMOTRUCK.State.UNLOADING
    truck.timestamp = timer.getAbsTime()
    self:__TruckUnloading(2,truck)
    -- set target to reloading
    local aridata = self:FindTarget(truck.targetname) -- #AMMOTRUCK.data
    if aridata then
      aridata.state = AMMOTRUCK.State.RELOADING
      aridata.timestamp = timer.getAbsTime()
    end
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #table dataset table of #AMMOTRUCK.data entries
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckUnloadingTrucks(dataset)
  self:T(self.lid .. " CheckUnloadingTrucks")
  local data = dataset 
  for _,_data in pairs (data) do
    -- check timestamp
    local truck = _data -- #AMMOTRUCK.data
    local Tnow = timer.getAbsTime()
    local Tpassed = Tnow - truck.timestamp
    local hasammo = self:GetAmmoStatus(truck.targetgroup)
    --local ammostate = truck.targetgroup:GetAmmunition()
    if Tpassed > self.unloadtime and hasammo > self.ammothreshold then
      truck.state = AMMOTRUCK.State.RETURNING
      truck.timestamp = timer.getAbsTime()
      self:__TruckReturning(2,truck)
      -- set target to reloaded     
      local aridata = self:FindTarget(truck.targetname) -- #AMMOTRUCK.data
      if aridata then
        aridata.state = AMMOTRUCK.State.IDLE
        aridata.timestamp = timer.getAbsTime()
      end
    end
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckTargetsAlive()
  self:T(self.lid .. " CheckTargetsAlive")
  local arilist = self.targetlist
  for _,_ari in pairs(arilist) do
    local ari = _ari -- #AMMOTRUCK.data
    if ari.group and ari.group:IsAlive() then
      -- everything fine
    else
      -- ari dead
      self.targetlist[ari.name] = nil
    end
  end
  -- new arrivals?
  local aritable = self.targetset:GetSetObjects() --#table
  for _,_ari in pairs(aritable) do
    local ari = _ari -- Wrapper.Group#GROUP
    if ari and ari:IsAlive() and not self.targetlist[ari:GetName()] then
      local name = ari:GetName()
      local newari = {} -- #AMMOTRUCK.data
      newari.name = name
      newari.group = ari
      newari.state = AMMOTRUCK.State.IDLE
      newari.timestamp = timer.getAbsTime()
      newari.coordinate = ari:GetCoordinate()
      local hasammo = self:GetAmmoStatus(ari)
      --newari.ammo = ari:GetAmmunition()
      newari.ammo = hasammo
      self.targetlist[name] = newari
    end 
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @return #AMMOTRUCK self 
function AMMOTRUCK:CheckTrucksAlive()
  self:T(self.lid .. " CheckTrucksAlive")
  local trucklist = self.trucklist
  for _,_truck in pairs(trucklist) do
    local truck = _truck -- #AMMOTRUCK.data
    if truck.group and truck.group:IsAlive() then
      -- everything fine
    else
      -- truck dead
      local tgtname = truck.targetname
      local targetdata = self:FindTarget(tgtname) -- #AMMOTRUCK.data
      if targetdata then
        if targetdata.state ~= AMMOTRUCK.State.IDLE then
          targetdata.state = AMMOTRUCK.State.IDLE
        end
      end
      self.trucklist[truck.name] = nil
    end
  end
  -- new arrivals?
  local trucktable = self.truckset:GetSetObjects() --#table
  for _,_truck in pairs(trucktable) do
    local truck = _truck -- Wrapper.Group#GROUP
    if truck and truck:IsAlive() and not self.trucklist[truck:GetName()] then
      local name = truck:GetName()
      local newtruck = {} -- #AMMOTRUCK.data
      newtruck.name = name
      newtruck.group = truck
      newtruck.state = AMMOTRUCK.State.IDLE
      newtruck.timestamp = timer.getAbsTime()
      newtruck.coordinate = truck:GetCoordinate()
      self.trucklist[name] = newtruck
    end 
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #AMMOTRUCK self 
function AMMOTRUCK:onafterStart(From, Event, To)
  self:T({From, Event, To})
  self:CheckTargetsAlive()
  self:CheckTrucksAlive()
  self:__Monitor(-30)
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #AMMOTRUCK self 
function AMMOTRUCK:onafterMonitor(From, Event, To)
  self:T({From, Event, To})
  self:CheckTargetsAlive()
  self:CheckTrucksAlive()
  -- update ammo state
  local remunition = false
  local remunitionqueue = {}
  local waitingtargets = {}
  for _,_ari in pairs(self.targetlist) do
    local data = _ari -- #AMMOTRUCK.data
    if data.group and data.group:IsAlive() then
      --data.ammo = data.group:GetAmmunition()
      data.ammo = self:GetAmmoStatus(data.group)
      data.timestamp = timer.getAbsTime()
      local text = string.format("Ari %s | Ammo %d | State %s",data.name,data.ammo,data.state)
      self:T(text)
      if data.ammo <= self.ammothreshold and (data.state == AMMOTRUCK.State.IDLE or data.state == AMMOTRUCK.State.OUTOFAMMO) then
        -- add to remu queue
        data.state = AMMOTRUCK.State.OUTOFAMMO
        remunitionqueue[#remunitionqueue+1] = data
        remunition = true
      elseif data.state == AMMOTRUCK.State.WAITING then
        waitingtargets[#waitingtargets+1] = data
      end
    else
      self.targetlist[data.name] = nil
    end
  end
  -- sort trucks in buckets
  local idletrucks = {}
  local drivingtrucks = {}
  local unloadingtrucks = {}
  local arrivedtrucks = {}
  local returningtrucks = {}
  local found = false
  for _,_truckdata in pairs(self.trucklist) do
    local data = _truckdata -- #AMMOTRUCK.data
    if data.group and data.group:IsAlive() then
        -- check state
        local text = string.format("Truck %s | State %s",data.name,data.state)
        self:T(text)
        if data.state == AMMOTRUCK.State.IDLE then
          idletrucks[#idletrucks+1] = data
          found = true
        elseif data.state == AMMOTRUCK.State.DRIVING then
          drivingtrucks[#drivingtrucks+1] = data
        elseif data.state == AMMOTRUCK.State.ARRIVED then
          arrivedtrucks[#arrivedtrucks+1] = data
        elseif data.state == AMMOTRUCK.State.UNLOADING then
          unloadingtrucks[#unloadingtrucks+1] = data
        elseif data.state == AMMOTRUCK.State.RETURNING then
          returningtrucks[#returningtrucks+1] = data
          idletrucks[#idletrucks+1] = data
          found = true
        end
    else
      self.truckset[data.name] = nil
    end
  end
  -- see if we can/need route one
  local n=0
  if found and remunition then
    -- match
    local match = false
    for _,_truckdata in pairs(idletrucks) do
      local truckdata = _truckdata -- #AMMOTRUCK.data
      local truckcoord = truckdata.group:GetCoordinate() -- Core.Point#COORDINATE
      for _,_aridata in pairs(remunitionqueue) do
        local aridata = _aridata -- #AMMOTRUCK.data
        local aricoord = aridata.coordinate
        local distance = truckcoord:Get2DDistance(aricoord)
        if distance <= self.remunidist and aridata.state == AMMOTRUCK.State.OUTOFAMMO and n <= #idletrucks then
          n = n + 1
          aridata.state = AMMOTRUCK.State.REQUESTED
          self:__RouteTruck(n*5,truckdata,aridata)
          break
        end
      end
    end
  end
  
  -- check driving trucks
  if #drivingtrucks > 0 then
    self:CheckDrivingTrucks(drivingtrucks)
  end
  
  -- check arrived trucks
  if #arrivedtrucks > 0 then
    self:CheckArrivedTrucks(arrivedtrucks)
  end
  
  -- check unloading trucks
  if #unloadingtrucks > 0 then
    self:CheckUnloadingTrucks(unloadingtrucks)
  end
  
  -- check returningtrucks trucks
  if #returningtrucks > 0 then
    self:CheckReturningTrucks(returningtrucks)
  end
  
  -- check waiting targets
  if #waitingtargets > 0 then
    self:CheckWaitingTargets(waitingtargets)
  end
  
  self:__Monitor(self.monitor)
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #AMMOTRUCK.data Truckdata
-- @param #AMMOTRUCK.data Aridata
-- @return #AMMOTRUCK self 
function AMMOTRUCK:onafterRouteTruck(From, Event, To, Truckdata, Aridata)
  self:T({From, Event, To, Truckdata.name, Aridata.name})
  local truckdata = Truckdata -- #AMMOTRUCK.data
  local aridata = Aridata -- #AMMOTRUCK.data
  local tgtgrp = aridata.group
  local tgtzone = ZONE_GROUP:New(aridata.name,tgtgrp,30)
  local tgtcoord = tgtzone:GetRandomCoordinate(15)
  if self.routeonroad then
    truckdata.group:RouteGroundOnRoad(tgtcoord,30,1,"Cone")
  else
    truckdata.group:RouteGroundTo(tgtcoord,30,"Cone",1)
  end
  truckdata.state = AMMOTRUCK.State.DRIVING
  truckdata.targetgroup = tgtgrp
  truckdata.targetname = aridata.name
  truckdata.targetcoordinate = tgtcoord
  aridata.state = AMMOTRUCK.State.WAITING
  aridata.timestamp = timer.getAbsTime()
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #AMMOTRUCK.data Truckdata
-- @return #AMMOTRUCK self 
 function AMMOTRUCK:onafterTruckUnloading(From, Event, To, Truckdata)
   local m = MESSAGE:New("Truck "..Truckdata.name.." unloading!",15,"AmmoTruck"):ToCoalitionIf(self.coalition,self.debug)
   local truck = Truckdata -- Functional.AmmoTruck#AMMOTRUCK.data
   local coord = truck.group:GetCoordinate()
   local heading = truck.group:GetHeading()
   heading = heading < 180 and (360-heading) or (heading - 180)
   local cid = self.coalition == coalition.side.BLUE and country.id.USA or country.id.RUSSIA
   cid = self.coalition == coalition.side.NEUTRAL and country.id.UN_PEACEKEEPERS or cid
   local ammo = {}
   for i=1,5 do
     ammo[i] = SPAWNSTATIC:NewFromType("ammo_cargo","Cargos",cid)
      :InitCoordinate(coord:Translate((15+((i-1)*4)),heading))
      :Spawn(0,"AmmoCrate-"..math.random(1,10000))
    end
    
    local function destroyammo(ammo)
      for _,_crate in pairs(ammo) do
        _crate:Destroy(false)
      end
    end
    
    local scheduler = SCHEDULER:New(nil,destroyammo,{ammo},self.waitingtime)
 end 

---
-- @param #AMMOTRUCK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #AMMOTRUCK.data Truck
-- @return #AMMOTRUCK self 
function AMMOTRUCK:onafterTruckReturning(From, Event, To, Truck)
  self:T({From, Event, To, Truck.name})
  -- route home
  local truckdata = Truck -- #AMMOTRUCK.data
  local tgtzone = self.homezone
  local tgtcoord = tgtzone:GetRandomCoordinate()
  if self.routeonroad then
    truckdata.group:RouteGroundOnRoad(tgtcoord,30,1,"Cone")
  else
    truckdata.group:RouteGroundTo(tgtcoord,30,"Cone",1)
  end
  return self
end

---
-- @param #AMMOTRUCK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #AMMOTRUCK self 
function AMMOTRUCK:onafterStop(From, Event, To)
  self:T({From, Event, To})
  return self
end

