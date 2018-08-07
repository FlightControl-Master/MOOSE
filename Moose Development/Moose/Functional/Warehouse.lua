--- **Functional** - (R2.4) - Manages assets of an airbase and transportation to other airbases upon request.
-- 
-- 
-- Features:
-- 
--    * Holds (virtual) assests such as intrantry groups in stock.
--    * Manages requests of assets from other airbases or warehouses.
--    * Take care of transportation to other airbases.
--    * Different means of automatic transportation (planes, helicopters, selfpropelled).  
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
-- @field #string wid Identifier of the warehouse printed before other output to DCS.log file.
-- @field #number markerid ID of the warehouse marker at the airbase.
-- @field #number assetid Unique id of asset items in stock. Essentially a running number starting at one and incremented when a new asset is added.
-- @field #table stock Table holding all assets in stock. Table entries are of type @{#WAREHOUSE.Stockitem}.
-- @field #table queue Table holding all queued requests. Table entries are of type @{#WAREHOUSE.Queueitem}.
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
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Main.JPG)
-- 
-- # What is a warehouse?
-- A warehouse is an abstract object that can hold virtual assets in stock. It is usually associated with a particular airbase.
-- If another airbase or warehouse requests assets, the corresponding troops are spawned at the warehouse and being transported to the requestor.
-- 
-- ## What assets can be stored?
-- Any kind of ground or airborn asset can be stored. Ships not supported at the moment due to the fact that airbases are bound to airbases which are
-- normally not located near the sea.
-- 
-- 
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
  wid        = nil,
  markerid   = nil,
  assetid    = 0,
  queueid    = 0,
  stock      = {},
  queue      = {},
}

--- Item of the warehouse stock table.
-- @type WAREHOUSE.Stockitem
-- @field #number id Unique id of the asset.
-- @field #string templatename Name of the template group.  
-- @field DCS#Group.Category category Category of the group.
-- @field #string unittype Type of the first unit of the group as obtained by the Object.getTypeName() DCS API function.
-- @field #WAREHOUSE.Attribute attribute Generalized attribute of the group.

--- Item of the warehouse queue table.
-- queueitem={uid=self.qid, prio=Prio, airbase=Airbase, assetdesc=AssetDescriptor, assetdescval=AssetDescriptorValue, nasset=nAsset, transporttype=TransportType, ntransport=nTransport}
-- @type WAREHOUSE.Queueitem
-- @field #number uid Unique id of the queue item.
-- @field #number prio Priority of the request.
-- @field Wrapper.Airbase#AIRBASE airbase Requesting airbase.
-- @field #WAREHOUSE.Descriptor assetdesc Descriptor of the requested asset.
-- @field assetdescval Value of the asset descriptor. Type depends on descriptor.
-- @field #number nasset Number of asset groups requested.
-- @field #WAREHOUSE.TransportType transporttype Transport unit type.
-- @field #number ntransport Number of transport units requested.

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
  TRANSPORT_PLANE="Transport_Plane",
  TRANSPORT_HELO="Transport_Helo",
  TRANSPORT_APC="Transport_APC",
  FIGHTER="Fighter",
  TANKER="Tanker",
  AWACS="AWACS",
  ARTILLERY="Artillery",
  ATTACKHELICOPTER="Attackhelicopter",
  INFANTRY="Infantry",
  BOMBER="Bomber",
  TANK="Tank",
  TRUCK="Truck",
  SHIP="Ship",
  OTHER="Other",
}

--- Cargo transport type.
-- @type WAREHOUSE.TransportType
WAREHOUSE.TransportType = {
  AIRPLANE      = "Transport_Plane",
  HELICOPTER    = "Transport_Helo",
  APC           = "Transport_APC",
  SHIP          = "Ship",
  TRAIN         = "Train",
  SELFPROPELLED = "Selfporpelled",
}

--- Warehouse class version.
-- @field #string version
WAREHOUSE.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: Warehuse todo list.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add event handlers.
-- TODO: Add AI_APC
-- TODO: Add AI_HELICOPTER
-- TODO: Write documentation.
-- TODO: Put active groups into the warehouse.
-- TODO: Spawn warehouse assets as uncontrolled or AI off and activate them when requested.
-- TODO: Handle cases with immobile units.
-- TODO: Add queue.
-- TODO: How to handle multiple units in a transport group?
-- TODO: Switch to AI_XXX_DISPATCHER

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- WAREHOUSE constructor. Creates a new WAREHOUSE object accociated with an airbase.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase at which the warehouse is constructed.
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
  self.spawnzone=ZONE_RADIUS:New("Spawnzone",_road, 200)
  self.spawnzone:BoundZone(60,country.id.GERMANY)
  self.spawnzone:GetCoordinate():MarkToAll("Spawnzone")
  
  -- Add FSM transitions.
  self:AddTransition("*", "Start",     "Running")
  self:AddTransition("*", "Status",    "*")
  self:AddTransition("*", "Request",   "*")
  self:AddTransition("*", "Delivered", "*")
  
  --- Triggers the FSM event "Start". Starts the warehouse.
  -- @function [parent=#WAREHOUSE] Start
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Start" after a delay. Starts the warehouse.
  -- @function [parent=#WAREHOUSE] __Start
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status". Queue is updated and requests are executed.
  -- @function [parent=#WAREHOUSE] Status
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Status" after a delay. Queue is updated and requests are executed.
  -- @function [parent=#WAREHOUSE] __Status
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
        

  --- Triggers the FSM event "Request". Executes a request if possible.
  -- @function [parent=#WAREHOUSE] Request
  -- @param #WAREHOUSE self
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
  -- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
  -- @param #number nAsset Number of groups requested that match the asset specification.
  -- @param #WAREHOUSE.TransportType TransportType Type of transport.

  --- Triggers the FSM event "Request" after a delay. Executes a request if possible.
  -- @function [parent=#WAREHOUSE] __Request
  -- @param #WAREHOUSE self
  -- @param #number Delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
  -- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
  -- @param #number nAsset Number of groups requested that match the asset specification.
  -- @param #WAREHOUSE.TransportType TransportType Type of transport.


  --- Triggers the FSM event "Delivered". A group has been delivered from the warehouse to another airbase or warehouse.
  -- @function [parent=#WAREHOUSE] Delivered
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group Group that was delivered.

  --- Triggers the FSM event "Delivered" after a delay. A group has been delivered from the warehouse to another airbase or warehouse.
  -- @function [parent=#WAREHOUSE] __Delivered
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
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
  self:E(self.wid..string.format("Starting warehouse at airbase %s.", self.homebase:GetName()))
  
  -- handle events
  -- event takeoff
  -- event landing
  -- event crash/dead
  -- event base captured ==> change coalition ==> add assets to other coalition.
  
  self:__Status(5)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStatus(From, Event, To)
  self:E(self.wid..string.format("Checking warehouse status of airbase %s", self.homebase:GetName()))
  
  -- Create a mark with the current assets in stock.
  if self.markerid~=nil then
    trigger.action.removeMark(self.markerid)
  end
  local marktext="Warehouse stock:\n"
  local text="Warehouse stock:\n"
  
  local _data=self:GetStockInfo(self.stock)
  for _attribute,_count in pairs(_data) do
    marktext=marktext..string.format("%s=%d, ", _attribute,_count) -- Dont use \n because too many make DCS crash!
    text=text..string.format("%s = %d\n", _attribute,_count)
  end
  self.markerid=self.coordinate:MarkToCoalition(marktext, self.coalition, true)
  
  -- Debug output.
  self:E(self.wid..text)
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  
  -- Display complete list of stock itmes.
  if self.Debug then
    --self:_DisplayStockItems(self.stock)
  end
  
  -- Print queue.
  env.info(self.wid.."Queue:")
  for _,_qitem in ipairs(self.queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem
    local text=string.format("uid=%d, prio=%d, airbase=%s, descriptor: %s=%s, nasssets=%d, transport=%s, ntransport=%d",
    qitem.uid, qitem.prio, qitem.airbase:GetName(), qitem.assetdesc,tostring(qitem.assetdescval),qitem.nasset,qitem.transporttype,qitem.ntransport)
    env.info(text)
  end
  
  -- Check queue and handle requests if possible.
  self:_WorkQueue()
  
  -- Call status again in 30 sec.
  --self:__Status(10)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On before "Request" event. Checks if the request can be fullfilled.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
-- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
-- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
-- @param #number nAsset Number of groups requested that match the asset specification.
-- @param #WAREHOUSE.TransportType TransportType Type of transport.
-- @param #number nTransport Number of transport units requested.
-- @param #number Prio Priority of the request. Number ranging from 1=high to 100=low.
function WAREHOUSE:AddRequest(Airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType, nTransport, Prio)

  nTransport=nTransport or 1
  Prio=Prio or 50

  -- Increase id.
  self.queueid=self.queueid+1
  
  -- Request queue table item.
  local request={uid=self.queueid, prio=Prio, airbase=Airbase, assetdesc=AssetDescriptor, assetdescval=AssetDescriptorValue, nasset=nAsset, transporttype=TransportType, ntransport=nTransport}
  
  -- Add request to queue.
  table.insert(self.queue, request)
end

--- On before "Request" event. Checks if the request can be fullfilled.
-- @param #WAREHOUSE self
function WAREHOUSE:_WorkQueue()

  -- Sort queue wrt to first prio and then qid.
  self:_SortQueue()
  
  ---@param #WAREHOUSE.Queueitem qitem
  --@return #boolean True if request is okay.
  local function checkrequest(qitem)
    local okay=true
    -- Check if number of requested assets is in stock.
    local _instock=#self:_FilterStock(self.stock, qitem.assetdesc, qitem.assetdescval)
    if qitem.nasset > _instock then
      okay=false      
    end
    -- Check if enough transport units are in stock.
    _instock=#self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, qitem.transporttype)
    if qitem.ntransport > _instock then
      okay=false      
    end
    return okay    
  end
  
  -- Search for a request we can execute.
  local request=nil --#WAREHOUSE.Queueitem
  for _,_qitem in ipairs(self.queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem
    local okay=checkrequest(qitem)
    if okay==true then
      request=qitem
      break
    end
  end
  
  -- Execute request.
  if request then
    self:Request(request.airbase, request.assetdesc, request.assetdescval, request.nasset, request.transporttype, request.ntransport)
  end
end

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
  env.info(self.wid..string.format("Airbase %s requesting asset %s = %s.", Airbase:GetName(), tostring(AssetDescriptor), tostring(AssetDescriptorValue)))
  
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

  -- Get assets in stock which are of the right type. 
  local _instock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, TransportType)
  
  -- Check that a transport unit is available.
  if #_instock==0 and TransportType~=WAREHOUSE.TransportType.SELFPROPELLED then
    local text=string.format("Request denied! No transport unit currently available.")
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    return false
  end
  
  -- TODO: For aircraft check that a parking spot is available.
  
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
function WAREHOUSE:onafterRequest(From, Event, To, Airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType, nTransport)
  env.info(self.wid..string.format("Airbase %s requesting asset %s = %s.", Airbase:GetName(), tostring(AssetDescriptor), tostring(AssetDescriptorValue)))

  ----------------------------------------------------------------

  -- Filter the requested assets.
  local _assetstock=self:_FilterStock(self.stock, AssetDescriptor, AssetDescriptorValue)  
 
  -- Spawn the assets.
  local _delid={}
  local _spawngroups={}
  for i=1,nAsset do
  
    -- Get stock item.
    local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
    table.insert(_delid,_assetitem.id)
    
    -- Find a random point within the spawn zone.
    local spawncoord=self.spawnzone:GetRandomCoordinate()
    spawncoord:MarkToAll(string.format("spawnpoint %d",i))

    -- Spawn with ALIAS here or DCS crashes!
    local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
    _spawngroups[i]=SPAWN:NewWithAlias(_assetitem.templatename, _alias):SpawnFromCoordinate(spawncoord)
  end

  -- Delete spawned items from warehouse stock.
  for _,_id in pairs(_delid) do
    self:_DeleteStockItem(_id)
  end
  
  ----------------------------------------------------------------
  
  -- No transport unit requested. Assets go by themselfes.
  if TransportType==WAREHOUSE.TransportType.SELFPROPELLED then
    for _i,_spawngroup in pairs(_spawngroups) do
      local group=_spawngroup --Wrapper.Group#GROUP
      local ToCoordinate=Airbase:GetZone():GetRandomCoordinate()
      group:RouteGroundOnRoad(ToCoordinate)
    end
  end
  
  ----------------------------------------------------------------  
  -- New empty cargo set.
  local CargoGroups = SET_CARGO:New()
  
  --TODO: make nearradius depended on transport type and asset type.
  local _loadradius=5000
  local _nearradius=35
  
  -- Add spawned groups to cargo group object.
  for _i,_spawngroup in pairs(_spawngroups) do
    local _name=string.format("%s %d",AssetDescriptorValue, _i)
    env.info(string.format("FF cargo group %d: %s",_i,_name))
    local cargogroup = CARGO_GROUP:New(_spawngroup, AssetDescriptorValue, _name, _loadradius, _nearradius)
    CargoGroups:AddCargo(cargogroup)
  end
  
  ----------------------------------------------------------------

  --[[
  -- Filter the requested assets.
  local _transportitem --#WAREHOUSE.Stockitem
  if TransportType ~= WAREHOUSE.TransportType.SELFPROPELLED then
    local _transportstock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, TransportType)
    local _chosenone=math.random(#_transportstock)
    -- Select asset template group name.
    _transportitem=_transportstock[_chosenone]
  end
  ]]

  local TransportSet = SET_GROUP:New() --:AddGroupsByName(Plane:GetName())
  
  -- Pickup and depoly locations.
  local PickupAirbaseSet = SET_AIRBASE:New():AddAirbase(self.homebase)
  local DeployAirbaseSet = SET_AIRBASE:New():AddAirbase(Airbase)
  local DeployZoneSet    = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
  local CargoTransport --AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER

  -- Filter the requested transport assets.
  local _assetstock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, TransportType)  
  
  -- Dependent on transport type, spawn the transports and set up the dispatchers.
  if TransportType==WAREHOUSE.TransportType.AIRPLANE then
    
    -- Spawn the transport groups.
    local _delid={}
    for i=1,nTransport do
    
      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
             
      -- Spawn with ALIAS here or DCS crashes!
      local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
      
      -- Spawn plane at airport in uncontrolled state.
      -- TODO: check terminal type.
      local spawngroup=SPAWN:NewWithAlias(_assetitem.templatename,_alias):InitUnControlled(true):SpawnAtAirbase(self.homebase, SPAWN.Takeoff.Cold, nil, AIRBASE.TerminalType.OpenBig, false)
      
      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)
        
        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)
        
        table.insert(_delid,_assetitem.id)
      end
    end
  
    -- Delete spawned items from warehouse stock.
    for _,_id in pairs(_delid) do
      self:_DeleteStockItem(_id)
    end
        
    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_AIRPLANE:New(TransportSet, CargoGroups, PickupAirbaseSet, DeployAirbaseSet)
    
    
    --[[
    -- Spawn plane at warehouse homebase.
    --TODO: Check available parking spots in onbefore!
    local Plane=SPAWN:New(_transportitem.templatename):InitUnControlled(true):SpawnAtAirbase(self.homebase, SPAWN.Takeoff.Cold, nil, AIRBASE.TerminalType.OpenBig, false)
    
    if Plane==nil then
      -- Plane was not spawned correctly. Try again in 60 seconds.
      local text="Technical problems with the transport plane occurred. Request was cancelled! Try again later."
      MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
      --TODO: Despawn asset units and but them back into the warehouse.
      return
    else
      -- Remove chosen transport asset from list.
      self:_DeleteStockItem(_transportitem.id)
    end
    
    -- Define cargo airplane object.
    local CargoPlane = AI_CARGO_AIRPLANE:New(Plane, CargoGroups)
    
    CargoPlane.Airbase=self.homebase
    
    -- Pickup cargo at homebase.
    CargoPlane:__Load(1, Plane:GetCoordinate())
    
    -- Set warehouse state so that we can retreive it later.
    Plane:SetState(Plane, "WAREHOUSE", self)
    
    --- Once the cargo was loaded start off to deploy airbase.
    function CargoPlane:OnAfterLoaded(Airplane, From, Event, To)
      CargoPlane:__Deploy(10, Airbase)
    end
    
    --- Function called when cargo has arrived and was unloaded.
    function CargoPlane:OnAfterUnloaded(Airplane, From, Event, To)
      
      local group=CargoPlane.Cargo:GetObject()
      local Airplane=Airplane --Wrapper.Group#GROUP
      local warehouse=Airplane:GetState(Airplane, "WAREHOUSE") --#WAREHOUSE
      
      -- Trigger Delivered event.
      warehouse:__Delivered(1, group)
    end
    ]]   
    
  elseif TransportType==WAREHOUSE.TransportType.HELICOPTER then

    -- Spawn the transport groups.
    local _delid={}
    for i=1,nTransport do
    
      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
             
      -- Spawn with ALIAS here or DCS crashes!
      local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
      
      -- Spawn plane at airport in uncontrolled state.
      -- TODO: check terminal type.
      local spawngroup=SPAWN:NewWithAlias(_assetitem.templatename,_alias):InitUnControlled(false):SpawnAtAirbase(self.homebase, SPAWN.Takeoff.Hot, nil, AIRBASE.TerminalType.HelicopterUsable, false)
      
      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)
        
        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)
        
        table.insert(_delid,_assetitem.id)
      end
    end
  
    -- Delete spawned items from warehouse stock.
    for _,_id in pairs(_delid) do
      self:_DeleteStockItem(_id)
    end
        
    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_HELICOPTER:New(TransportSet, CargoGroups, DeployZoneSet)
    
    -- Home zone.
    CargoTransport:SetHomeZone(self.spawnzone)
    
    --CargoTransport = AI_CARGO_DISPATCHER_AIRPLANE:New(TransportSet, CargoGroups, PickupAirbasesSet, DeployAirbasesSet)

    --[[  
    local Helo=SPAWN:New(_transportitem.templatename):SpawnAtAirbase(self.homebase, SPAWN.Takeoff.Cold, nil, AIRBASE.TerminalType.HelicopterUsable, false)
  
    if Helo==nil then
      -- Plane was not spawned correctly. Try again in 60 seconds.
      local text="Technical problems with the transport helicopter occurred. Request was cancelled! Try again later."
      return
    else
      -- Remove chosen transport asset from list.
      self:_DeleteStockItem(_transportitem.id)
    end
    
    -- Define cargo airplane object.
    local CargoHelo = AI_CARGO_HELICOPTER:New(Helo, CargoGroups)
    
    
    -- Pickup cargo from the spawn zone.
    CargoHelo:__Pickup(5, self.spawnzone:GetCoordinate())
    
    --- Once the cargo was loaded start off to deploy airbase.
    function CargoHelo:OnAfterLoaded(Carrier, From, Event, To)
      CargoHelo:__Deploy(10, Airbase:GetZone():GetRandomCoordinate())
    end
    
    --- Function called when cargo has arrived and was unloaded.
    function CargoHelo:OnAfterUnloaded(Airplane, From, Event, To)
      
      local group=CargoHelo.Cargo:GetObject()
      local Airplane=Airplane --Wrapper.Group#GROUP
      local warehouse=Airplane:GetState(Airplane, "WAREHOUSE") --#WAREHOUSE
      
      -- Trigger Delivered event.
      warehouse:__Delivered(1, group)
    end    
    ]]
      
  elseif TransportType==WAREHOUSE.TransportType.APC then

    -- Spawn the transport groups.
    local _delid={}
    for i=1,nTransport do
    
      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
             
      -- Spawn with ALIAS here or DCS crashes!
      local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
      
      -- Spawn plane at airport in uncontrolled state.
      local spawngroup=SPAWN:NewWithAlias(_assetitem.templatename,_alias):SpawnFromCoordinate(self.spawnzone:GetRandomCoordinate())
      
      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)
        
        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)
        
        table.insert(_delid,_assetitem.id)
      end
    end
  
    -- Delete spawned items from warehouse stock.
    for _,_id in pairs(_delid) do
      self:_DeleteStockItem(_id)
    end
        
    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_APC:NewWithZones(TransportSet, CargoGroups, DeployZoneSet, 0)

    --[[    
    -- Spawn APC in spawn zone.
    local APC=SPAWN:New(_transportitem.templatename):SpawnFromCoordinate(self.spawnzone:GetCoordinate())
    
    -- Set up cargo APC.
    local CargoAPC=AI_CARGO_APC:New(APC, CargoGroups, 0)
    
    -- Init pickup/loading of cargo. (No drive-to coordinate given, since we are already at in the spawn zone.)
    CargoAPC:__Pickup(5)
    
    --- Once the cargo was loaded start off to deploy airbase.
    function CargoAPC:OnAfterLoaded(Airplane, From, Event, To)
      CargoAPC:__Deploy(5, Airbase:GetZone():GetCoordinate())
    end
    
    --- Function called when cargo has arrived and was unloaded.
    function CargoAPC:OnAfterUnloaded(Airplane, From, Event, To)
      
      local group=CargoAPC.Cargo:GetObject()
      local Airplane=Airplane --Wrapper.Group#GROUP
      local warehouse=Airplane:GetState(Airplane, "WAREHOUSE") --#WAREHOUSE
      
      -- Trigger Delivered event.
      warehouse:__Delivered(1, group)
    end    
    ]]
  
  elseif TransportType==WAREHOUSE.TransportType.TRAIN then
  
    self:E(self.wid.."ERROR: transport by train not supported yet!")
    return
    
  elseif TransportType==WAREHOUSE.TransportType.SHIP then
  
    self:E(self.wid.."ERROR: transport by ship not supported yet!")
    return
    
  elseif TransportType==WAREHOUSE.TransportType.SELFPROPELLED then
  
    return
        
  else
    self:E(self.wid.."ERROR: unknown transport type!")
    return
  end
  

  --- Function called when cargo has arrived and was unloaded.
  function CargoTransport:OnAfterUnloaded(From, Event, To, Carrier, Cargo)
  
    env.info("FF: OnAfterUnloaded")
    self:E({From=From})
    self:E({Event=Event})
    self:E({To=To})
    self:E({Carrier=Carrier})
    self:E({Cargo=Cargo})
    
    -- Get group obejet.
    local group=Cargo:GetObject() --Wrapper.Group#GROUP
    
    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE
    
    -- Trigger Delivered event.
    warehouse:__Delivered(1, group)
  end
  
  -- Start dispatcher.
  CargoTransport:__Start(5)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group The group that was delivered.
function WAREHOUSE:onafterDelivered(From, Event, To, Group)
  env.info("FF warehouse cargo delivered! Croutine to closest point on road")
  local road=Group:GetCoordinate():GetClosestPointToRoad()
  local speed=Group:GetSpeedMax()*0.6
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
    --[[    
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
    ]]
    
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

--- Returns the number of assets for each generalized attribute.
-- @param #WAREHOUSE self
-- @param #table stock The stock of the warehouse.
-- @return #table Data table holding the numbers.
function WAREHOUSE:GetStockInfo(stock)
  
  local _data={} 
  for _j,_attribute in pairs(WAREHOUSE.Attribute) do
  
    local n=0
    for _i,_item in pairs(stock) do
      local _ite=_item --#WAREHOUSE.Stockitem
      if _ite.attribute==_attribute then
        n=n+1
      end
    end
    
    _data[_attribute]=n   
  end
  
  return _data
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

--- Delete item from queue.
-- @param #WAREHOUSE self
-- @param #number _uid The id of the item to be deleted.
function WAREHOUSE:_DeleteStockItem(_uid)
  for _i,_item in pairs(self.queue) do
    if _item.uid==_uid then
      self.queue[_i]=nil
    end
  end
end

--- Sort requests queue wrt prio and request uid.
-- @param #WAREHOUSE self
function WAREHOUSE:_SortQueue()
  self:F2()
  
  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    return (a.prio < b.prio) or (a.prio==b.prio and a.uid < b.uid)
  end
  table.sort(self.queue, _sort)
  
  -- Debug output.
  self:T3(self.wid.."Sorted queue wrt prio and uid:")
  for i=1,#self.queue do
    local _target=self.queue[i] --#WAREHOUSE#Queueitem
    --self:T3(self.wid)..string.format("Queue %s", self:_TargetInfo(_target)))
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

