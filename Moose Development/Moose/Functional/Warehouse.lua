--- **Functional** - (R2.4) - Manages assets of an airbase and transportation to other airbases upon request.
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
-- @field #boolean Debug If true, send debug messages to all.
-- @field #boolean Report If true, send status messages to coalition.
-- @field DCS#Coalition coalition Coalition the warehouse belongs to.
-- @field Wrapper.Airbase#AIRBASE homebase Airbase the warehouse belongs to.
-- @field Core.Point#COORDINATE coordinate Coordinate of the warehouse.
-- @field Core.Zone#ZONE spawnzone Zone in which assets are spawned. 
-- @field #number assetid Unique id of asset items in stock. Essentially a running number starting at one and incremented when a new asset is added.
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
  Debug      = false,
  Report     = true,  
  coalition  = nil,
  homebase   = nil,
  coordinate = nil,
  spawnzone  = nil,
  assetid    = 0,
  stock      = {},
}

--- Item of the warehouse stock table.
-- @type WAREHOUSE.Stockitem
-- @field #number id Unique id of the asset.
-- @field #string templatename Name of the template group.  
-- @field DCS#Group.Category category Category of the group.
-- @field #string unittype Type of the first unit of the group as obtained by the Object.getTypeName() DCS API function.
-- @field #WAREHOUSE.Attribute attribute Generalized attribute of the group. 

--- Descriptors enumerator describing the type of the asset in stock.
-- @type WAREHOUSE.Descriptor
WAREHOUSE.Descriptor = {
  ID="id",
  TEMPLATENAME="templatename",
  CATEGORY="category",
  UNITTYPE="unittype",
  ATTRIBUTE="attribute",
}

--- Warehouse unit categories. These are used for
-- @type WAREHOUSE.Attribute
WAREHOUSE.Attribute = {
  TRANSPORT_PLANE="transportplane",
  TRANSPORT_HELO="transporthelo",
  TRANSPORT_APC="transportapc",
  FIGHTER="fighter",
  TANKER="tanker",
  AWACS="awacs",
  ARTILLERY="artillery",
  ATTACKHELICOPTER="attackhelicopter",
  INFANTRY="infantry",
  BOMBER="bomber",
  TANK="tank",
  TRUCK="truck",
  OTHER="other",
}

--- Cargo transport type.
-- @type WAREHOUSE.TransportType
-- @field #string AIRPLANE plane blabla
WAREHOUSE.TransportType = {
  AIRPLANE      = "transportplane",
  HELICOPTER    = "transporthelo",
  APC           = "transportapc",
  SHIP          = "ship",
  TRAIN         = "train",
  SELFPROPELLED = "selfporpelled",
}

--- Warehouse class version.
-- @field #string version
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
  
  -- Get the closest point on road.
  local _road=self.coordinate:GetClosestPointToRoad():GetVec2()
  
  -- Define the default spawn zone.
  self.spawnzone=ZONE:New("Spawnzone",_road, 200)
  
  -- Add FSM transitions.
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
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
  -- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
  -- @param #number nAsset Number of groups requested that match the asset specification.
  -- @param #WAREHOUSE.TransportType TransportType Type of transport.
  -- @return boolean If true, request is granted.
  -- 
  -- @usage mywarehouse:Request(AIRBASE:)...

  --- Triggers the FSM event "Request" after a delay.
  -- @function [parent=#WAREHOUSE] __Request
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
  -- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
  -- @param #number nAsset Number of groups requested that match the asset specification.
  -- @param #WAREHOUSE.TransportType TransportType Type of transport.

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
  
  --env.info(string.format("FF warehouse at %s: number of stock = %d", self.homebase:GetName(), #self.stock))
  self:_DisplayStockItems(self.stock)
  self:__Status(30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- On before "Request" event. Checks if the request can be fullfilled.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
-- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
-- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
-- @param #number nAsset Number of groups requested that match the asset specification.
-- @param #WAREHOUSE.TransportType TransportType Type of transport.
-- @return #boolean If true, request is granted.
function WAREHOUSE:onbeforeRequest(From, Event, To, Airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType)

  -- Default.
  nAsset=nAsset or 1
  TransportType=TransportType or WAREHOUSE.TransportType.SELFPROPELLED

  -- Distance from warehouse to 
  local distance=self.coordinate:Get2DDistance(Airbase:GetCoordinate())

  -- Filter the requested assets.
  local _stockrequest=self:_FilterStock(self.stock, AssetDescriptor, AssetDescriptorValue)
  
  -- Asset is not in stock ==> request denied.
  if #_stockrequest < nAsset then
    local text=string.format("Request denied! Not enought assets currently in stock. Requested %d < %d in stock.", nAsset, #_stockrequest)
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    return false
  end
  
  -- Get the attibute of the requested asset.
  local _stockitem=_stockrequest[1] --#WAREHOUSE.Stockitem
  local _assetattribute=self:_GetAttribute(_stockitem.templatename)
  
  --if _assetattribute==WAREHOUSE.Attribute.
  
  -- Shortcut
  local _TT=TransportType:lower()
  local _instock
  
  -- Check the availability of transport units.
  if _TT == WAREHOUSE.TransportType.AIRPLANE then
    _instock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.TRANSPORT_PLANE)
  elseif _TT == WAREHOUSE.TransportType.HELICOPTER then
    _instock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.TRANSPORT_HELO)
  elseif _TT == WAREHOUSE.TransportType.GROUND then
    _instock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.TRANSPORT_APC)
  elseif _TT == WAREHOUSE.TransportType.SHIP then
    _instock=0
  elseif _TT == WAREHOUSE.TransportType.TRAIN then
    _instock=0
  elseif _TT == WAREHOUSE.TransportType.SELFPROPELLED then
    _instock=_stockrequest
  else
    self:E(self.wid..string.format("ERROR: unknown transport type requested! type = %s", tostring(TransportType)))
    return false
  end
  
  if #_instock==0 then
    local text=string.format("Request denied! No transport unit currently available.")
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    return false
  end
  

  return true
end


--- On after "Request" event. Initiates the transport of the assets to the requesting airbase.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
-- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
-- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
-- @param #number nAsset Number of groups requested that match the asset specification.
-- @param #WAREHOUSE.TransportType TransportType Type of transport.
function WAREHOUSE:onafterRequest(From, Event, To, Airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType)
  env.info(self.wid..string.format("Airbase %s requesting asset %s = %s.", Airbase:GetName(), tostring(AssetDescriptor), tostring(AssetDescriptorValue)))
  
  -- Filter the requested assets.
  local _assetstock=self:_FilterStock(self.stock, AssetDescriptor, AssetDescriptorValue)  
  
  -- Get a random template from the stock list.
  local _chosenone=math.random(#_assetstock)
    
  -- Select asset template group name.
  local assettemplate=_assetstock[_chosenone].templatename
  
  
  -- New empty cargo set.
  local CargoGroups = SET_CARGO:New()
  
  -- Spawn the assets.
  local _delid={}
  for i=1,nAsset do
  
    -- Get stock item.
    local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
    table.insert(_delid,_assetitem.id)
    
    -- Spawn group in spawn zone.
    local spawn=SPAWN(_assetitem.templatename)
    local spawngroup=spawn:SpawnFromVec3(self.spawnzone:GetRandomPointVec3())
    
    -- Add spawned group to cargo group object.
    --TODO: check near and load radius.
    local cargogroup = CARGO_GROUP:New(spawngroup, "Infantry", string.format( "Infantry Platoon %d", i), 5000, 35)
    CargoGroups:AddCargo(cargogroup)
  end
  
  -- Delete spawned items from warehouse stock.
  for _,_id in pairs(_delid) do
   self:_DeleteStockItem(_id)
  end
     
  --[[
  -- Spawn requested assets.
  local spawn=SPAWN:New("Infantry Platoon Alpha")
  self.homebase:GetZone():GetRandomCoordinate(inner,outer)
  local spawngroup=spawn:SpawnFromVec3(self.homebase:GetZone():GetRandomPointVec3(100,500))
  for i=1,nAsset do
    local spawngroup=spawn:SpawnFromVec3(self.homebase:GetZone():GetRandomPointVec3(100,500))
    local cargogroup = CARGO_GROUP:New(spawngroup, "Infantry", string.format( "Infantry Platoon %d", i), 5000, 35)
    CargoGroups:AddCargo(cargogroup)
  end
  ]]
  
  
  -- Filter the requested assets.
  local _transportstock
  local _transportitem --#WAREHOUSE.Stockitem
  if TransportType~=WAREHOUSE.TransportType.SELFPROPELLED then
    _transportstock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, TransportType)
    _chosenone=math.random(#_transportstock)
    -- Select asset template group name.
    _transportitem=_transportstock[_chosenone]
  end
  
  
  if TransportType==WAREHOUSE.TransportType.AIRPLANE then
    
    -- Spawn plane at warehouse homebase.
    --TODO: Check available parking spots in onbefore!
    local Plane=SPAWN:New(_transportitem.templatename):SpawnAtAirbase(Airbase, SPAWN.Takeoff.Cold, nil, AIRBASE.TerminalType.OpenBig, false)
    
    if Plane==nil then
      -- Plane was not spawned correctly. Try again in 60 seconds.
      local text="Technical problems with the transport plane occurred. Request was cancelled! Try again later."
      --self:__Request(60, Airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType)
      --TODO: despawn units and but them back into the warehouse.
      return
    else
      -- Remove chosen transport asset from list.
      self:_DeleteStockItem()
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
    
  elseif TransportType==WAREHOUSE.TransportType.HELICOPTER then
  
  elseif TransportType==WAREHOUSE.TransportType.APC then
  
  elseif TransportType==WAREHOUSE.TransportType.TRAIN then
  
  elseif TransportType==WAREHOUSE.TransportType.SHIP then
    
  elseif TransportType==WAREHOUSE.TransportType.SELFPROPELLED then
        
  else
    self:E(self.wid.."ERROR: unknown transport type!")
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

  -- Set default.
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
    self:E({desc=DCSdesc})
    
    local attribute=self:_GetAttribute(templategroupname)
  
    -- Add this n times to the table.
    for i=1,n do
      local stockitem={} --#WAREHOUSE.Stockitem
      self.assetid=self.assetid+1
      stockitem.id=self.assetid
      stockitem.templatename=templategroupname
      stockitem.category=DCScategory
      stockitem.unittype=DCStype
      stockitem.attribute=attribute   
      table.insert(self.stock, stockitem)
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
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Stockitem}.
-- @param #string item Descriptor
-- @param value Value of the descriptor.
-- @return #table Filtered stock items table.
function WAREHOUSE:_FilterStock(stock, item, value)

  -- Filtered array.
  local filtered={}
  
  -- Loop over stock items.
  for _i,_stock in ipairs(stock) do
    if _stock[item]==value then
      _stock.pos=_i
      table.insert(filtered, _stock)
    end
  end
  
  return filtered
end

--- Filter stock assets by table entry.
-- @param #WAREHOUSE self
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Stockitem}.
function WAREHOUSE:_DisplayStockItems(stock)
  
  local text=self.wid..string.format("Warehouse %s stock assets:\n", self.homebase:GetName())
  for _,_stock in pairs(stock) do
    local mystock=_stock --#WAREHOUSE.Stockitem
    text=text..string.format("template = %s, category = %d, unittype = %s, attribute = %s\n", mystock.templatename, mystock.category, mystock.unittype, mystock.attribute)  
  end
  
  env.info(text)
  MESSAGE:New(text, 10):ToAll()
end

--- Check if a group has a generalized attribute.
-- @param #WAREHOUSE self
-- @param #string groupname Name of the group.
-- @param #WAREHOUSE.Attribute attribute Attribute to check.
-- @return #boolean True if group has the specified attribute.
function WAREHOUSE:_HasAttribute(groupname, attribute)

  local group=GROUP:FindByName(groupname)
  
  if group then
    local groupattribute=self:_HasAttribute(groupname,attribute)
    return groupattribute==attribute
  end
  
  return false  
end

--- Get the generalized attribute of a group.
-- @param #WAREHOUSE self
-- @param #string groupname Name of the group.
-- @return #WAREHOUSE.Attribute Generalized attribute of the group.
function WAREHOUSE:_GetAttribute(groupname)

  local group=GROUP:FindByName(groupname)
  
  local attribute=WAREHOUSE.Attribute.OTHER --#WAREHOUSE.Attribute
  
  if group then

    -- Get generalized attributes.
    -- Transports: Helos, planes and APCs
    local transportplane=group:HasAttribute("Transports") and group:HasAttribute("Planes")    
    local transporthelo=group:HasAttribute("Transport helicopters")    
    local transportapc=group:HasAttribute("Infantry carriers")
    local fighter=group:HasAttribute("Fighters") or group:HasAttribute("Interceptors") or group:HasAttribute("Multirole fighters")
    local tanker=group:HasAttribute("Tankers")
    local awacs=group:HasAttribute("AWACS")
    local artillery=group:HasAttribute("Artillery")
    local infantry=group:HasAttribute("Infantry")
    local attackhelicopter=group:HasAttribute("Attack helicopters")
    local bomber=group:HasAttribute("Bombers")
    local tank=group:HasAttribute("Old Tanks") or group:HasAttribute("Modern Tanks")
    local truck=group:HasAttribute("Trucks")
    
        -- Debug output.
    env.info(string.format("transport pane = %s", tostring(transportplane)))    
    env.info(string.format("transport helo = %s", tostring(transporthelo)))
    env.info(string.format("transport apc  = %s", tostring(transportapc)))
    env.info(string.format("figther        = %s", tostring(fighter)))
    env.info(string.format("tanker         = %s", tostring(tanker)))
    env.info(string.format("awacs          = %s", tostring(awacs)))
    env.info(string.format("artillery      = %s", tostring(artillery)))
    env.info(string.format("infantry       = %s", tostring(infantry)))
    env.info(string.format("attack helo    = %s", tostring(attackhelicopter)))
    env.info(string.format("bomber         = %s", tostring(bomber)))
    env.info(string.format("tank           = %s", tostring(tank)))
    env.info(string.format("truck          = %s", tostring(truck)))
  
    if transportplane then
      attribute=WAREHOUSE.Attribute.TRANSPORT_PLANE
    elseif transporthelo then
      attribute=WAREHOUSE.Attribute.TRANSPORT_HELO
    elseif transportapc then
      attribute=WAREHOUSE.Attribute.TRANSPORT_APC      
    elseif fighter then
      attribute=WAREHOUSE.Attribute.FIGHTER
    elseif tanker then
      attribute=WAREHOUSE.Attribute.TANKER
    elseif awacs then
      attribute=WAREHOUSE.Attribute.AWACS
    elseif artillery then
      attribute=WAREHOUSE.Attribute.ARTILLERY
    elseif infantry then
      attribute=WAREHOUSE.Attribute.INFANTRY
    elseif attackhelicopter then
      attribute=WAREHOUSE.Attribute.ATTACKHELICOPTER
    elseif bomber then
      attribute=WAREHOUSE.Attribute.BOMBER
    elseif tank then
      attribute=WAREHOUSE.Attribute.TANK
    elseif truck then
      attribute=WAREHOUSE.Attribute.TRUCK
    else
      attribute=WAREHOUSE.Attribute.OTHER
    end  
  
  end

  return attribute
end

--- Delete item from stock.
-- @param #WAREHOUSE self
-- @param #number uid The id of the item to be deleted.
function WAREHOUSE:_DeleteStockItem(uid)
  for _i,_item in pairs(self.stock) do
    if _item.id==uid then
      self.stock[_i]=nil
    end
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

