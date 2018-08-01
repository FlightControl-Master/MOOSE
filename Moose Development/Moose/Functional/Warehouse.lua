--- **Functional** - (R2.4) - Manages assets of an airbase and transportation to other airbases.
-- 
-- 
-- Features:
-- 
--    * Some nice stuff.
-- 
-- # QUICK START GUIDE
-- 
-- ===
-- 
-- ### Authors: **funkyfranky**
-- 
-- @module Functional.Warehouse
-- @image Warehouse.JPG

--- WAREHOUSE class.
-- @type WAREHOUSE
-- @field #string ClassName Name of the class.
-- @field DCS#Coalition coalition Coalition the warehouse belongs to.
-- @field Core.Point#COORDINATE coordinate Coordinate of the warehouse.
-- @field Wrapper.Airbase#AIRBASE airbase Airbase the warehouse belongs to.
-- @field #table stock Table holding all assets in stock. Table entries are of type @{#WAREHOUSE.Stock}.
-- @extends Core.Fsm#FSM

--- Manages ground assets of an airbase and offers the possibility to transport them to another airbase or warehouse.
-- 
-- ===
-- 
-- # Demo Missions
-- 
-- ### None.
-- 
-- ===
-- 
-- # YouTube Channel
-- 
-- ### None.
-- 
-- ===
-- 
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_pic.JPG)
-- 
-- Warehouse
-- 
-- ===
--
-- # USAGE GUIDE
-- 
-- 
-- 
-- @field #WAREHOUSE
WAREHOUSE = {
  ClassName  = "WAREHOUSE",
  coalition  = nil,
  homebase   = nil,
  coordinate = nil,
  stock      = {},
}

--- Type Warehouse stock table. table.insert(self.stock, {templatename=templategroupname, category=DCScategory, type=DCStype, transport=transport, fighther=fighter, tanker=tanker, awacs=awacs, artillery=artillery})
-- @type WAREHOUSE.Stock
-- @field #string templatename Name of the template group.  
-- @field DCS#Category category Category of the group. Airplane, helicopter, ...
-- @field #string type Type of the group
-- @field #boolean fighter If true, group is a fighter airplane.
-- @field #boolean attackhelo If true, group is an attack helicopter.
-- @field #boolean transport If truie, group can transport other units either by air or ground.
-- @field #boolean tanker If true, group is a tanker and can refuel other air units.
-- @field #boolean awacs If true, group has AWACS capabilities.
-- @field #boolean artillery If true, group is an artillery unit.

--- Asset descriptor.
-- @field Warehouse.AssetDescriptor Assetdescriptor
WAREHOUSE.Descriptor = {
  TEMPLATENAME="templatename",
  CATEGORY="category",
  
}

--- Warehouse classes.
-- @field Warehouse.Class Class
WAREHOUSE.Class = {
  TRANSPORT=1,
  FIGHTER=2,
  TANKER=3,
  AWACS=4,
  ARTY=5,
  ATTACKHELO=6,
}

--- Warehouse categories
-- @field Category
WAREHOUSE.Category = {
  AIRPLANE      = "plane",
  HELICOPTER    = "helo",
  GROUND        = "apc",
  SHIP          = "ship",
  TRAIN         = "train",
  SELF          = "self",
}

--- Warehouse class version.
-- @field #number version
WAREHOUSE.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: Warehuse todo list.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- WAREHOUSE constructor. Creates a new WAREHOUSE object.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE airbase Airbase.
-- @return #WAREHOUSE self
function WAREHOUSE:NewAirbase(airbase)
  BASE:E({airbase=airbase})
  
  -- Print version.
  env.info(string.format("Adding warehouse v%s for airbase %s", WAREHOUSE.version, airbase:GetName()))
  
  -- Inherit everthing from FSM class.
  local self = BASE:Inherit( self, FSM:New() ) -- #WAREHOUSE

  -- Set some string id for output to DCS.log file.
  self.wid=string.format("WAREHOUSE %s | ", airbase:GetName())
  
  -- Set some variables.  
  self.homebase=airbase
  self.coordinate=airbase:GetCoordinate()
  self.coalition=airbase:GetCoalition()
      
  self:AddTransition("*", "Start",     "Running")
  self:AddTransition("*", "Status",    "*")
  self:AddTransition("*", "Request",   "*")
  self:AddTransition("*", "Delivered", "*")
  
  --- Triggers the FSM event "Start".
  -- @function [parent=#WAREHOUSE] Start
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#WAREHOUSE] __Start
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status".
  -- @function [parent=#WAREHOUSE] Status
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#WAREHOUSE] __Status
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
        

  --- Triggers the FSM event "Request".
  -- @function [parent=#WAREHOUSE] Request
  -- @param #WAREHOUSE self
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #string Asset Asset that is requested.
  -- @param #number nAsset Number of assets requested. Default 1.
  -- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"

  --- Triggers the FSM event "Request" after a delay.
  -- @function [parent=#WAREHOUSE] __Request
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #string Asset Asset that is requested.
  -- @param #number nAsset Number of assets requested. Default 1.
  -- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"

  --- Triggers the FSM event "Delivered".
  -- @function [parent=#WAREHOUSE] Delivered
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group Group that was delivered.

  --- Triggers the FSM event "Delivered" after a delay.
  -- @function [parent=#WAREHOUSE] __Delivered
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group Group that was delivered.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStart(From, Event, To)
  env.info("FF starting warehouse at airbase "..self.homebase:GetName())
  
  -- handle events
  -- event takeoff
  -- event landing
  -- event crash/dead
  -- event base captured
  self:__Status(-5)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStatus(From, Event, To)
  env.info("FF checking warehouse status of airbase "..self.homebase:GetName())
  
  env.info(string.format("FF warehouse at %s: number of stock = %d", self.homebase:GetName(), #self.stock))
  
  self:__Status(30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- On before "Request" event. Checks if the request can be fullfilled.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
-- @param #string AssetDescriptor Asset that is requested. Can be "templatename", ...
-- @param depends AssetDescriptorvalue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, 
-- @param #number nAssed Number of groups of that asset requested.
-- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"
-- @return boolean If true, request is granted.
-- 
-- @usage mywarehouse:Request(AIRBASE:)...
function WAREHOUSE:onbeforeRequest(From, Event, To, Airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType)

  -- Distance from warehouse to 
  local distance=self.coordinate:Get2DDistance(Airbase:GetCoordinate())
  
  -- 
  local _stockrequest=self._FilterStock(self.stock, AssetDescriptor, AssetDescriptorValue)
  
  -- Asset is not in stock ==> request denied.
  if #_stockrequest==0 then
    self:E(self.wid..string.format("Request denied! Asset is currently not in stock."))
    return false
  end
  
  local _TT=TransportType:lower()
  if _TT==nil then
    if AssetDescriptor=="" then
    end
  end
  
  if TransportType:lower() == "plane" then
  
  elseif TransportType:lower() == "helicopter" then
  
  elseif TransportType:lower() == "apc" then
  
  elseif TransportType:lower() == "train" then
  
  elseif TransportType:lower() == "ship" then
  
  elseif TransportType:lower() == "self" then
  
  else
    self:E(self.wid..string.format("ERROR: unknown transport type requested! type = %s", tostring(TransportType)))
  end

end


--- On after "Request" event. 
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
-- @param #string Asset Asset that is requested.
-- @param #number nAssed Number of groups of that asset requested.
-- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"
function WAREHOUSE:onafterRequest(From, Event, To, Airbase, Asset, nAsset, TransportType)
  env.info(string.format("FF airbase %s is requesting asset %s from warehouse %s", Airbase:GetName(), Asset, self.homebase:GetName()))
  
  local nAsset=nAsset or 1
  
  if TransportType=="Air" then
  
    -- Get a random template from the stock list.
    local _chosenone=math.random(#self.stock) --#WAREHOUSE.Stock
    
    
    
    -- Select template group name.
    --TODO: FILTER HERE!
    local template=self.stock[_chosenone].templatename
          
    if template then
    
      -- Spawn plane at warehouse homebase.
      local Plane=SPAWN:New(template):SpawnAtAirbase(Airbase, nil, nil, nil, false)
      
      if Plane==nil then
        -- Plane was not spawned correctly. Try again in 60 seconds.
        self:__Request( 60, Airbase, Asset, nAsset, TransportType)
        return
      else
        -- Remove chosen plane from list.
        table.remove(self.stock,_chosenone)
      end
      
      -- New empty cargo set.
      local CargoGroups = SET_CARGO:New()
      
      -- Spawn requested assets.
      local spawn=SPAWN:New("Infantry Platoon Alpha")
      
      for i=1,nAsset do
        local spawngroup=spawn:SpawnFromVec3(self.homebase:GetZone():GetRandomPointVec3(100,500))
        local cargogroup = CARGO_GROUP:New(spawngroup, "Infantry", string.format( "Infantry Platoon %d", i), 5000, 35)
        CargoGroups:AddCargo(cargogroup)
      end
      
      -- Define cargo airplane.
      local CargoPlane = AI_CARGO_AIRPLANE:New(Plane, CargoGroups)
      
      -- Pickup cargo at homebase.
      CargoPlane:__Pickup(5, self.homebase)
      
      -- Set warehouse state so that we can retreive it later.
      Plane:SetState(Plane, "WAREHOUSE", self)
      
      --- Once the cargo was loaded start off to deploy airbase.
      function CargoPlane:OnAfterLoaded(Airplane, From, Event, To)
        CargoPlane:__Deploy(10, Airbase, 500)
      end
      
      --- Function called when cargo has arrived and was unloaded.
      function CargoPlane:OnAfterUnloaded(Airplane, From, Event, To)
        
        local group=CargoPlane.Cargo:GetObject()
        local Airplane=Airplane --Wrapper.Group#GROUP
        local warehouse=Airplane:GetState(Airplane, "WAREHOUSE") --#WAREHOUSE
        
        -- Trigger Delivered event.
        warehouse:__Delivered(1, group)
      end
                      
    end
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group The group that was delivered.
-- @param #string Asset Asset that is requested.
-- @param #number nAssed Number of groups of that asset requested.
-- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"
function WAREHOUSE:onafterDelivered(From, Event, To, Group)
  local road=Group:GetCoordinate():GetClosestPointToRoad()
  local speed=Group:GetSpeedMax()*0.5
  Group:RouteGroundTo(road, speed, "Off Road")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an airplane group to the warehouse stock.
-- @param #WAREHOUSE self
-- @param #string templategroupname Name of the late activated template group as defined in the mission editor.
-- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
-- @param #boolean istransport If true, this group will act as transport unit to transport other assets to another airbase. If false, this unit will not be used as transport unit. By default the behavior is determined for the group's attributes. 
-- @return #WAREHOUSE self
function WAREHOUSE:AddAsset(templategroupname, ngroups, istransport)

  local n=ngroups or 1
  
  local group=GROUP:FindByName(templategroupname)
  
  if group then
  
    local DCSgroup=group:GetDCSObject()
    local DCSunit=DCSgroup:getUnit(1)
    local DCSdesc=DCSunit:getDesc()
    local DCSdisplay=DCSunit:getDesc().displayName
    local DCScategory=DCSgroup:getCategory()
    local DCStype=DCSunit:getTypeName()
    
    env.info(string.format("group name   = %s", group:GetName()))
    env.info(string.format("display name = %s", DCSdisplay))
    env.info(string.format("category     = %s", DCScategory))
    env.info(string.format("type         = %s", DCStype))
    env.info(string.format("attribute infantry = %s", tostring(group:HasAttribute("Infantry"))))
    self:E({desc=DCSdesc})
    
    local transport=group:HasAttribute("Transport helicopters") or group:HasAttribute("Transports") or group:HasAttribute("Infantry carriers")
    local fighter=group:HasAttribute("Fighters") or group:HasAttribute("Interceptors") or group:HasAttribute("Multirole fighters")
    local tanker=group:HasAttribute("Tankers")
    local awacs=group:HasAttribute("AWACS")
    local apc=group:HasAttribute("Infantry carriers")
    local artillery=group:HasAttribute("Artillery")
    env.info(string.format("attribute transport = %s", tostring(transport)))
    env.info(string.format("attribute apc       = %s", tostring(apc)))    
    env.info(string.format("attribute figther   = %s", tostring(fighter)))
    env.info(string.format("attribute tanker    = %s", tostring(tanker)))
    env.info(string.format("attribute awacs     = %s", tostring(awacs)))
    env.info(string.format("attribute artillery = %s", tostring(artillery)))
  
    -- Add this n times to the table.
    for i=1,n do
      table.insert(self.stock, {templatename=templategroupname, category=DCScategory, type=DCStype, transport=transport, fighther=fighter, tanker=tanker, awacs=awacs, artillery=artillery})
    end
    
  else
    -- Group name does not exist!
    self:E(string.format("ERROR: Template group name not defined in the mission editor. Check the spelling! templategroupname=%s",tostring(templategroupname)))
  end
    
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Filter stock assets by table entry.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Stock stock
-- @param #string item Descriptor
-- @param depends value
function WAREHOUSE:_FilterStock(stock, item, value)

  local filtered={}
  
  for _,_stock in pairs(stock) do
    if _stock[item]==value then
      table.insert(filtered, _stock)
    end
  end
  
  return filtered
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

