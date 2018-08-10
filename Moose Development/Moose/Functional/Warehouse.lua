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
-- @field DCS#coalition.side coalition Coalition ID the warehouse belongs to.
-- @field DCS#country.id country Country ID the warehouse belongs to.
-- @field Wrapper.Airbase#AIRBASE homebase Airbase the warehouse belongs to.
-- @field DCS#Airbase.Category category Category of the home airbase, i.e. airdrome, helipad/farp or ship.
-- @field Core.Point#COORDINATE coordinate Coordinate of the warehouse.
-- @field Core.Zone#ZONE spawnzone Zone in which assets are spawned.
-- @field #string wid Identifier of the warehouse printed before other output to DCS.log file.
-- @field #number uid Unit identifier of the warehouse. Derived from the associated airbase.
-- @field #number markerid ID of the warehouse marker at the airbase.
-- @field #number assetid Unique id of asset items in stock. Essentially a running number starting at one and incremented when a new asset is added.
-- @field #table stock Table holding all assets in stock. Table entries are of type @{#WAREHOUSE.Stockitem}.
-- @field #table queue Table holding all queued requests. Table entries are of type @{#WAREHOUSE.Queueitem}.
-- @field #table pending Table holding all pending requests, i.e. those that are currently in progress. Table entries are of type @{#WAREHOUSE.Queueitem}.
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
  country    = nil,
  homebase   = nil,
  category   = nil,
  coordinate = nil,
  spawnzone  = nil,
  wid        = nil,
  uid        = nil,
  markerid   = nil,
  warehouse  = nil,
  assetid    = 0,
  queueid    = 0,
  stock      = {},
  queue      = {},
}

--- Item of the warehouse stock table.
-- @type WAREHOUSE.Stockitem
-- @field #number id Unique id of the asset.
-- @field #string templatename Name of the template group.
-- @field #table template The spawn template of the group.
-- @field DCS#Group.Category category Category of the group.
-- @field #string unittype Type of the first unit of the group as obtained by the Object.getTypeName() DCS API function.
-- @field #WAREHOUSE.Attribute attribute Generalized attribute of the group.

--- Item of the warehouse queue table.
-- queueitem={uid=self.qid, prio=Prio, airbase=Airbase, assetdesc=AssetDescriptor, assetdescval=AssetDescriptorValue, nasset=nAsset, transporttype=TransportType, ntransport=nTransport}
-- @type WAREHOUSE.Queueitem
-- @field #number uid Unique id of the queue item.
-- @field #number prio Priority of the request.
-- @field Wrapper.Airbase#AIRBASE airbase Requesting airbase.
-- @field DCS#Airbase.Category category Category of the requesting airbase, i.e. airdrome, helipad/farp or ship.
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

--- Warehouse generalited categories.
-- @type WAREHOUSE.Attribute
-- @field #string TRANSPORT_PLANE Airplane with transport capability. Usually bigger.
-- @field #string TRANSPORT_HELO Helicopter with transport capability.
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
  TRAIN="Train",
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
  SELFPROPELLED = "Selfpropelled",
}

--- Warehouse class version.
-- @field #string version
WAREHOUSE.version="0.1.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: Warehuse todo list.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add event handlers.
-- DONE: Add AI_CARGO_AIRPLANE
-- DONE: Add AI_CARGO_APC
-- DONE: Add AI_CARGO_HELICOPTER
-- TODO: Write documentation.
-- TODO: Put active groups into the warehouse, e.g. when they were transported to this warehouse.
-- TODO: Spawn warehouse assets as uncontrolled or AI off and activate them when requested.
-- TODO: Handle cases with immobile units.
-- DONE: Add queue.
-- TODO: How to handle multiple units in a transport group?
-- DONE: Switch to AI_CARGO_XXX_DISPATCHER
-- TODO: Add phyical object, if destroyed asssets are gone.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- WAREHOUSE constructor. Creates a new WAREHOUSE object accociated with an airbase.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase at which the warehouse is constructed.
-- @return #WAREHOUSE self
function WAREHOUSE:NewAirbase(airbase)
  BASE:E({airbase=airbase:GetName()})

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
  self.country=airbase:GetCountry()
  self.category=airbase:GetDesc().category
  self.uid=airbase:GetID()
  
  -- Get the closest point on road.
  local _road=self.coordinate:GetClosestPointToRoad():GetVec2()

  -- Define the default spawn zone.
  self.spawnzone=ZONE_RADIUS:New("Spawnzone",_road, 200)

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
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.
 
  --- Triggers the FSM event "Request" after a delay. Executes a request if possible.
  -- @function [parent=#WAREHOUSE] __Request
  -- @param #WAREHOUSE self
  -- @param #number Delay Delay in seconds.
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.


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

--- On after Start event. Starts the warehouse. Addes event handlers and schedules status updates of reqests and queue.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStart(From, Event, To)
  self:E(self.wid..string.format("Starting warehouse at airbase %s, category %d, coalition %d, country %d", self.homebase:GetName(), self.category, self.coalition, self.country))
  
  -- Debug mark spawn zone.
  --self.spawnzone:BoundZone(60, country.id.GERMANY)
  self.spawnzone:BoundZone(60, self.country)
  self.spawnzone:GetCoordinate():MarkToAll("Spawnzone of warehouse "..self.homebase:GetName())

  -- handle events
  -- event takeoff
  -- event landing
  -- event crash/dead
  -- event base captured ==> change coalition ==> add assets to other coalition
  
  self:__Status(5)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Status event. Checks the queue and handles requests.
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
  self:_PrintQueue()

  -- Check queue and handle requests if possible.
  local request=self:_CheckQueue()

  -- Execute the request. If the request is really executed, it is also deleted from the queue.
  if request then
    self:Request(request)
  end

  -- Call status again in 30 sec.
  self:__Status(10)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On before "Request" event. Checks if the request can be fullfilled.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
-- @return #boolean If true, request is granted.
function WAREHOUSE:onbeforeRequest(From, Event, To, Request)
  env.info(self.wid..string.format("Airbase %s requesting %d assets of %s=%s by transport %s", 
  Request.airbase:GetName(), Request.nasset, tostring(Request.assetdesc), tostring(Request.assetdescval), tostring(Request.transporttype)))

  -- Distance from warehouse to requesting airbase.
  local distance=self.coordinate:Get2DDistance(Request.airbase:GetCoordinate())

  -- Filter the requested assets.
  local _assets=self:_FilterStock(self.stock, Request.assetdesc, Request.assetdescval, Request.nasset)

  -- Asset is not in stock ==> request denied.
  if #_assets < Request.nasset then
    local text=string.format("Request denied! Not enough assets currently in stock. Requested %d < %d in stock.", Request.nasset, #_assets)
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
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
function WAREHOUSE:onafterRequest(From, Event, To, Request)
  --env.info(self.wid..string.format("Airbase %s requesting asset %s = %s.", Airbase:GetName(), tostring(AssetDescriptor), tostring(AssetDescriptorValue)))

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Cargo assets.
  ------------------------------------------------------------------------------------------------------------------------------------

  -- New empty cargo set in case we need it.
  local CargoGroups = SET_CARGO:New()

  --TODO: make nearradius depended on transport type and asset type.
  local _loadradius=5000
  local _nearradius=35

  -- Filter the requested cargo assets.
  local _assetstock=self:_FilterStock(self.stock, Request.assetdesc, Request.assetdescval, Request.nasset)

  -- General type and category.
  local _cargotype=_assetstock[1].attribute    --#WAREHOUSE.Attribute
  local _cargocategory=_assetstock[1].category --DCS#Group.Category
  
  -- Now we try to find all parking spots for all cargo groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  if  _cargocategory==Group.Category.AIRPLANE or _cargocategory==Group.Category.HELICOPTER then
    Parking=self:_GetParkingForAssets(_assetstock)    
  end

  -- Spawn the assets.
  local _delid={}
  local _spawngroups={}
  
  -- Loop over cargo requests.
  for i=1,Request.nasset do

    -- Get stock item.
    local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem

    -- Find a random point within the spawn zone.
    local spawncoord=self.spawnzone:GetRandomCoordinate()    
    
    -- Alias of the group. Spawn with ALIAS here or DCS crashes!
    --local _alias=string.format("%s_WID-%02d_AID-%04d_RID-%04d", _assetitem.unittype, self.uid,_assetitem.id,Request.uid)
    local _alias=self:_Alias(_assetitem,Request)
    --local _spawn=SPAWN:NewWithAlias(_assetitem.templatename,_alias)
    local _spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias)

    local _group=nil --Wrapper.Group#GROUP
    
    -- Set a marker for the spawned group.
    spawncoord:MarkToAll(string.format("Spawnpoint %s",_alias))
    
    local _attribute=_assetitem.attribute
      
    if _assetitem.category==Group.Category.GROUND then
    
      -- Spawn ground troops.      
      _group=_spawn:SpawnFromCoordinate(spawncoord)
      env.info(string.format("FF spawning group %s", _alias))
      
    elseif _assetitem.category==Group.Category.AIRPLANE or _assetitem.category==Group.Category.HELICOPTER then
    
      -- Spawn air units.
      local _takeoff=SPAWN.Takeoff.Cold

      _group=_spawn:InitUnControlled(true):SpawnAtAirbase(self.homebase,_takeoff, nil, nil, true, Parking[i])
      
    elseif _assetitem.category==Group.Category.TRAIN then
    
      -- Spawn train.
      local _railroad=self.coordinate:GetClosestPointToRoad(true)
      if _railroad then     
        _group=_spawn:SpawnFromCoordinate(_railroad)
      end
      
    end

    if _group then
      _spawngroups[i]=_group
      table.insert(_delid,_assetitem.id)

      -- Add groups to cargo.
      if Request.transporttype ~= WAREHOUSE.TransportType.SELFPROPELLED then
        local cargogroup = CARGO_GROUP:New(_group, _alias, _alias, _loadradius, _nearradius)
        CargoGroups:AddCargo(cargogroup)
      end
    else
      self:E(self.wid.."ERROR: cargo asset could not be spawned!")
    end
  end

  -- Delete spawned items from warehouse stock.
  for _,_id in pairs(_delid) do
    self:_DeleteStockItem(_id)
  end

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Self propelled assets.
  ------------------------------------------------------------------------------------------------------------------------------------

  -- No transport unit requested. Assets go by themselfes.
  if Request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then

    for _i,_spawngroup in pairs(_spawngroups) do

      local group=_spawngroup --Wrapper.Group#GROUP
      local ToCoordinate=Request.airbase:GetZone():GetRandomCoordinate()
      
      -- Route cargo to their destination.
      if _cargocategory==Group.Category.GROUND then        
        self:_RouteGround(group, ToCoordinate)
      elseif _cargocategory==Group.Category.AIRPLANE then
        self:_RouteAir(group, Request.airbase)
      elseif _cargocategory==Group.Category.HELICOPTER then
        self:_RouteAir(group, Request.airbase)
      elseif _cargocategory==Group.Category.SHIP then
        self:E("ERROR: self propelled ship not implemented yet!")
      elseif _cargocategory==Group.Category.TRAIN then
        self:_RouteTrain(group, ToCoordinate)
      end

    end
    
    -- Delete request from queue.
    table.insert(self.pending, Request)
    self:_DeleteQueueItem(Request.uid)

    -- No cargo transport necessary.
    return
  end
  
  ------------------------------------------------------------------------------------------------------------------------------------
  -- Transport assets and dispachers
  ------------------------------------------------------------------------------------------------------------------------------------

  env.info("FF cargo set name(s) = "..CargoGroups:GetObjectNames())
  ----------------------------------------------------------------

  local TransportSet = SET_GROUP:New()

  -- Pickup and deploy zones/bases.
  local PickupAirbaseSet = SET_AIRBASE:New():AddAirbase(self.homebase)
  local DeployAirbaseSet = SET_AIRBASE:New():AddAirbase(Request.airbase)
  local DeployZoneSet    = SET_ZONE:New():AddZone(Request.airbase:GetZone())
  
  -- Cargo dispatcher.
  local CargoTransport --AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER

  -- Filter the requested transport assets.
  local _assetstock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, Request.transporttype, Request.ntransport)
  
  -- General type and category.
  local _transporttype=_assetstock[1].attribute    --#WAREHOUSE.Attribute
  local _transportcategory=_assetstock[1].category --DCS#Group.Category

  -- Now we try to find all parking spots for all transport groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  
  -- Now we try to find all parking spots for all cargo groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  if  _transportcategory==Group.Category.AIRPLANE or _transportcategory==Group.Category.HELICOPTER then
    Parking=self:_GetParkingForAssets(_assetstock)    
  end  

  -- Dependent on transport type, spawn the transports and set up the dispatchers.
  if Request.transporttype==WAREHOUSE.TransportType.AIRPLANE then
  
    -- Spawn the transport groups.
    local _delid={}
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
      local _parking=Parking[i]

      -- Spawn with ALIAS here or DCS crashes!
      --local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
      local _alias=self:_Alias(_assetitem, Request)

      -- Spawn plane at airport in uncontrolled state.
      local _takeoff=SPAWN.Takeoff.Cold
      --local spawn=SPAWN:NewWithAlias(_assetitem.templatename,_alias)
      local spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias)
      local spawngroup=spawn:InitUnControlled(true):SpawnAtAirbase(self.homebase,_takeoff, nil, nil, false, _parking)

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

  elseif Request.transporttype==WAREHOUSE.TransportType.HELICOPTER then

    -- Spawn the transport groups.
    local _delid={}
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem
      local _parking=Parking[i]
      
      -- Spawn with ALIAS here or DCS crashes!
      --local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
      local _alias=self:_Alias(_assetitem, Request)

      -- Spawn helo at airport.
      local _takeoff=SPAWN.Takeoff.Hot
      --local spawn=SPAWN:NewWithAlias(_assetitem.templatename,_alias)
      local spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias)
      local spawngroup=spawn:InitUnControlled(false):SpawnAtAirbase(self.homebase,_takeoff, nil, nil, false, _parking)

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        table.insert(_delid,_assetitem.id)
      else
        self:E(self.wid.."ERROR: spawngroup helo transport does not exist!")
      end
    end

    -- Delete spawned items from warehouse stock.
    for _,_id in pairs(_delid) do
      self:_DeleteStockItem(_id)
    end

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_HELICOPTER:New(TransportSet, CargoGroups, DeployZoneSet)

    -- Home zone.
    CargoTransport:SetHomeBase(self.homebase)
    --CargoTransport:SetHomeZone(self.spawnzone)

  elseif Request.transporttype==WAREHOUSE.TransportType.APC then

    -- Spawn the transport groups.
    local _delid={}
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem

      -- Spawn with ALIAS here or DCS crashes!
      --local _alias=string.format("%s_%d", _assetitem.templatename,_assetitem.id)
      local _alias=self:_Alias(_assetitem, Request)

      -- Spawn plane at airport in uncontrolled state.
      local spawn=SPAWN:NewWithAlias(_assetitem.templatename,_alias)
      local spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias)
      local spawngroup=spawn:SpawnFromCoordinate(self.spawnzone:GetRandomCoordinate())

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
    
    -- Set home zone.
    CargoTransport:SetHomeZone(self.spawnzone)
    
  elseif Request.transporttype==WAREHOUSE.TransportType.TRAIN then

    self:E(self.wid.."ERROR: transport by train not supported yet!")
    return

  elseif Request.transporttype==WAREHOUSE.TransportType.SHIP then

    self:E(self.wid.."ERROR: transport by ship not supported yet!")
    return

  elseif Request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then

    self:E(self.wid.."ERROR: transport type selfpropelled was already handled above. We should not get here!")
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
  
  --- On after BackHome event.
  function CargoTransport:OnAfterBackHome(From, Event, To, Carrier)
  
    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE
    Carrier:SmokeRed()
    
    -- Add carrier back to warehouse stock. Actual unit is destroyed.
    warehouse:AddAsset(Carrier:GetName(), 1)
    
  end  

  -- Start dispatcher.
  CargoTransport:__Start(5)

  -- Delete request from queue.
  table.insert(self.pending, Request)
  self:_DeleteQueueItem(Request.uid)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Delivered" event.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group that was delivered.
function WAREHOUSE:onafterDelivered(From, Event, To, group)  
  self:E(self.wid..string.format("Cargo %s delivered!", group:GetName()))
  
  -- Route a ground group to the closest point on road.
  if group:IsGround() and group:GetSpeedMax()>0 then
    local road=group:GetCoordinate():GetClosestPointToRoad()
    local speed=group:GetSpeedMax()*0.6
    group:RouteGroundTo(road, speed, "Off Road")
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an airplane group to the warehouse stock.
-- @param #WAREHOUSE self
-- @param #string templategroupname Name of the late activated template group as defined in the mission editor.
-- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
-- @return #WAREHOUSE self
function WAREHOUSE:AddAsset(templategroupname, ngroups)

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
      stockitem.template=UTILS.DeepCopy(_DATABASE.Templates.Groups[templategroupname].Template)
      stockitem.category=DCScategory
      stockitem.unittype=DCStype
      stockitem.attribute=attribute
      
      -- Modify the template so that the group is spawned with the right coalition.
      stockitem.template.CoalitionID=self.coalition
      stockitem.template.CountryID=self.country
      
      table.insert(self.stock, stockitem)
    end
    
    -- Destroy group if it is alive.
    if group:IsAlive()==true then
      group:Destroy()
    end

  else
    -- Group name does not exist!
    self:E(string.format("ERROR: Template group name not defined in the mission editor. Check the spelling! templategroupname=%s",tostring(templategroupname)))
  end

  return self
end

--- Set a zone where the (ground) assets of the warehouse are spawned once requested.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The spawn zone.
-- @return #WAREHOUSE self
function WAREHOUSE:SetSpawnZone(zone)
  self.spawnzone=zone
  return self
end

--- Add a request for the warehouse.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE Airbase airbase requesting supply.
-- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
-- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
-- @param #number nAsset Number of groups requested that match the asset specification.
-- @param #WAREHOUSE.TransportType TransportType Type of transport.
-- @param #number nTransport Number of transport units requested.
-- @param #number Prio Priority of the request. Number ranging from 1=high to 100=low.
function WAREHOUSE:AddRequest(airbase, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType, nTransport, Prio)

  nAsset=nAsset or 1
  TransportType=TransportType or WAREHOUSE.TransportType.SELFPROPELLED
  nTransport=nTransport or 1
  Prio=Prio or 50
  
  --TODO: check that
  -- if warehouse or requestor is a FARP, plane asset and transport not possible.
  -- if requestor or warehouse is a SHIP, APC transport not possible, SELFPROPELLED only for AIR/SHIP
  -- etc. etc...
  
  local request_category=airbase:GetDesc().category  --DCS#Airbase.Category

  -- No airplanes from to to FARPS.
  if self.category==Airbase.Category.HELIPAD or request_category==Airbase.Category.HELIPAD then
    if TransportType==WAREHOUSE.TransportType.AIRPLANE then
      self:E("ERROR: incorrect request. Warehouse or requestor is FARP. No transport by plane possible!")
      return
    end
  end
  
  local request_air=false
  local request_plane=false
  local request_helo=false
  local request_ground=false
  local request_naval=false
  
  -- Check if category is matching
  if AssetDescriptor==WAREHOUSE.Descriptor.CATEGORY then
    if AssetDescriptorValue==Group.Category.AIRPLANE then
      request_plane=true
    elseif AssetDescriptorValue==Group.Category.HELICOPTER then
      request_helo=true
    elseif AssetDescriptorValue==Group.Category.GROUND then
      request_ground=true
    elseif AssetDescriptorValue==Group.Category.SHIP then
      request_naval=true
    elseif AssetDescriptorValue==Group.Category.TRAIN then
      request_ground=true
    else
      self:E("ERROR: incorrect request. Asset Descriptor missmatch! Has to be Group.Cagetory.AIRPLANE, ...")
      return
    end
  end
  
  -- Check attribute is matching
  if AssetDescriptor==WAREHOUSE.Descriptor.ATTRIBUTE then
    if AssetDescriptorValue==WAREHOUSE.Attribute.ARTILLERY then
      request_ground=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.ATTACKHELICOPTER then
      request_helo=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.AWACS then
      request_plane=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.BOMBER then
      request_plane=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.FIGHTER then
      request_plane=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.INFANTRY then
      request_ground=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.OTHER then
      self:E("ERROR: incorrect request. Asset attribute WAREHOUSE.Attribute.OTHER is not valid!")
      return          
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.SHIP then
      request_naval=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TANK then
      request_ground=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TANKER then
      request_plane=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TRAIN then
      request_ground=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TRANSPORT_APC then
      request_ground=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TRANSPORT_HELO then
      request_helo=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TRANSPORT_PLANE then
      request_plane=true
    elseif AssetDescriptorValue==WAREHOUSE.Attribute.TRUCK then
      request_ground=true
    else
      self:E("ERROR: incorrect request. Unknown asset attribute!")
      return    
    end
  end
  
  request_air=request_helo or request_plane
  
  if request_air then
  
    if request_plane then
      -- No airplane to or from FARPS.
      if request_category==Airbase.Category.HELIPAD or self.category==Airbase.Category.HELIPAD then
        self:E("ERROR: incorrect request. Asset aircraft requestst but warehouse or requestor is HELIPAD/FARP!")
        return
      end
    elseif request_helo then
      
    end
    
  elseif request_ground then
    
    -- No ground assets directly to ships.
    if (request_category==Airbase.Category.SHIP or self.category==Airbase.Category.SHIP)
    and not (TransportType==WAREHOUSE.TransportType.AIRPLANE or TransportType==WAREHOUSE.TransportType.HELICOPTER) then
      self:E("ERROR: incorrect request. Ground asset requested but warehouse or requestor is SHIP!")
      return
    end
    
  elseif request_naval then
  
  end

  -- Increase id.
  self.queueid=self.queueid+1

  -- Request queue table item.
  local request={uid=self.queueid, prio=Prio, airbase=airbase, category=request_category, assetdesc=AssetDescriptor, assetdescval=AssetDescriptorValue, nasset=nAsset, transporttype=TransportType, ntransport=nTransport}

  -- Add request to queue.
  table.insert(self.queue, request)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Checks if the request can be fullfilled.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem qitem The request to be checked.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequest(request)
    
  local okay=true
  
  -- Check if number of requested assets is in stock.
  local _assets=self:_FilterStock(self.stock, request.assetdesc, request.assetdescval, request.nasset)
  
  -- Get the attibute of the requested asset.
  local _assetattribute=_assets[1].attribute
  local _assetcategory=_assets[1].category  
  
  -- Check if enough assets are in stock.
  if request.nasset > #_assets then
    local text=string.format("Request denied! Not enough assets currently available.")
    MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    okay=false
  end

  -- Check available parking for asset units.
  local Parkingdata=self.homebase:GetParkingSpotsTable()
  local Parking
  if  _assetcategory==Group.Category.AIRPLANE or _assetcategory==Group.Category.HELICOPTER then
    Parking, Parkingdata=self:_GetParkingForAssets(_assets, Parkingdata)
    if Parking==nil then
      local text=string.format("Request denied! Not enough free parking spots for all assets at the moment.")
      MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
      self:E(self.wid..text)
      okay=false
    end
  end
  
  
  -- Check that a transport units.
  if request.transporttype~=WAREHOUSE.TransportType.SELFPROPELLED then
  
    -- Transports in stock.
    local _transports=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, request.transporttype, request.ntransport)
    
    -- Get the attibute of the transport units.
    local _transportattribute=_transports[1].attribute
    local _transportcategory=_transports[1].category
    
    -- Check if enough transport units are available.
    if request.ntransport > #_transports then
      local text=string.format("Request denied! Not enough transport units currently available.")
      MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
      self:E(self.wid..text)
      okay=false
    end

    -- Check available parking for transport units.
    if  _transportcategory==Group.Category.AIRPLANE or _transportcategory==Group.Category.HELICOPTER then
      Parking, Parkingdata=self:_GetParkingForAssets(_transports, Parkingdata)
      if Parking==nil then
        local text=string.format("Request denied! Not enough free parking spots for all transports at the moment.")
        MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
        self:E(self.wid..text)
        okay=false
      end
    end
        
  else
    -- self propelled case.
  
  end
    
  return okay  
end


--- Creates a unique name for spawned assets.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Stockitem _assetitem Asset for which the name is created.
-- @param #WAREHOUSE.Queueitem _queueitem (Optional) Request specific name.
-- @return #string Alias name "UnitType\_WID-%02d\_AID-%04d"
function WAREHOUSE:_Alias(_assetitem,_queueitem)
  local _alias=string.format("%s_WID-%02d_AID-%04d", _assetitem.unittype, self.uid,_assetitem.id)
  if _queueitem then
    _alias=_alias..string.format("_RID-%04d",_queueitem.uid)
  end
  return _alias
end

---Sorts the queue and checks if the request can be fullfilled.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE.Queueitem Chosen request.
function WAREHOUSE:_CheckQueue()

  -- Sort queue wrt to first prio and then qid.
  self:_SortQueue()

  -- Search for a request we can execute.
  local request=nil --#WAREHOUSE.Queueitem
  for _,_qitem in ipairs(self.queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem
    local okay=self:_CheckRequest(qitem)
    if okay==true then
      request=qitem
      break
    end
  end

  -- Execute request.
  return request
end

--- Route ground units to destination.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP Group The ground group.
-- @param Core.Point#COORDINATE Coordinate of the destination.
-- @param #number Speed Speed in km/h to drive to the destination coordinate. Default is 60% of max possible speed the unit can go.
function WAREHOUSE:_RouteGround(Group, Coordinate, Speed)

  if Group and Group:IsAlive() then

    local _speed=Speed or Group:GetSpeedMax()*0.6

    -- Create a
    local Waypoints = Group:TaskGroundOnRoad(Coordinate, _speed, "Off Road", true)

    -- Task function triggering the arrived event.
    local TaskFunction = Group:TaskFunction("WAREHOUSE._Arrived", self)

    -- Put task function on last waypoint.
    local Waypoint = Waypoints[#Waypoints]
    Group:SetTaskWaypoint( Waypoint, TaskFunction )

    -- Route group to destination.
    Group:Route(Waypoints, 1)
  end
end

--- Task function for last waypoint. Triggering the Delivered event.
-- @param Wrapper.Group#GROUP Group The group that arrived.
-- @param #WAREHOUSE self
function WAREHOUSE._Arrived(Group, self)
  --Trigger delivered event.
  self:__Delivered(1, Group)
end

--- Route the airplane from one airbase another.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Airplane group to be routed.
-- @param Wrapper.Airbase#AIRBASE ToAirbase Destination airbase.
-- @param #number Speed Speed in km/h. Default is 80% of max possible speed the group can do.
function WAREHOUSE:_RouteAir(Aircraft, ToAirbase, Speed)

  if Aircraft and Aircraft:IsAlive() then

    -- Set takeoff type.
    local Takeoff = SPAWN.Takeoff.Cold

    -- Get template of group.
    local Template = Aircraft:GetTemplate()

    -- Nil check
    if Template==nil then
      return
    end

    -- Waypoints of the route.
    local Points={}

    -- To point.
    local AirbasePointVec2 = ToAirbase:GetPointVec2()
    local ToWaypoint = AirbasePointVec2:WaypointAir(
      POINT_VEC3.RoutePointAltType.BARO,
      "Land",
      "Landing",
      Speed or Aircraft:GetSpeedMax()*0.8
    )
    ToWaypoint["airdromeId"]   = ToAirbase:GetID()
    ToWaypoint["speed_locked"] = true

    -- Aibase id and category.
    local AirbaseID       = ToAirbase:GetID()
    local AirbaseCategory = ToAirbase:GetDesc().category

    if AirbaseCategory == Airbase.Category.SHIP or AirbaseCategory == Airbase.Category.HELIPAD then
      ToWaypoint.linkUnit   = AirbaseID
      ToWaypoint.helipadId  = AirbaseID
      ToWaypoint.airdromeId = nil
    elseif AirbaseCategory == Airbase.Category.AIRDROME then
      ToWaypoint.airdromeId = AirbaseID
      ToWaypoint.helipadId  = nil
      ToWaypoint.linkUnit   = nil
    end

    -- Task function triggering the arrived event.
    local Task = Aircraft:TaskFunction("WAREHOUSE._Arrived", self)

    --or
    ToWaypoint.task=Aircraft:TaskCombo({Task})
    --ToWaypoint.task={Task}

    -- Second point of the route. First point is done in RespawnAtCurrentAirbase() routine.
    Template.route.points[2] = ToWaypoint

    -- Respawn group at the current airbase.
    Aircraft:RespawnAtCurrentAirbase(Template, Takeoff, false)

  end
end

--- Route trains to their destination - or at least to the closest point on rail of the desired final destination.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP Group The train group.
-- @param Core.Point#COORDINATE Coordinate of the destination. Tail will be routed to the closest point
-- @param #number Speed Speed in km/h to drive to the destination coordinate. Default is 60% of max possible speed the unit can go.
function WAREHOUSE:_RouteTrain(Group, Coordinate, Speed)

  if Group and Group:IsAlive() then

    local _speed=Speed or Group:GetSpeedMax()*0.6

    -- Create a
    local Waypoints = Group:TaskGroundOnRailRoads(Coordinate, Speed)

    -- Task function triggering the arrived event.
    local TaskFunction = Group:TaskFunction("WAREHOUSE._Arrived", self)

    -- Put task function on last waypoint.
    local Waypoint = Waypoints[#Waypoints]
    Group:SetTaskWaypoint( Waypoint, TaskFunction )

    -- Route group to destination.
    Group:Route(Waypoints, 1)
  end
end

--- Get the proper terminal type based on generalized attribute of the group.
--@param #WAREHOUSE self
--@param #WAREHOUSE.Attribute _attribute Generlized attibute of unit.
function WAREHOUSE:_GetTerminal(_attribute)

  local _terminal=AIRBASE.TerminalType.OpenBig
  if _attribute==WAREHOUSE.Attribute.FIGHTER then
    -- Fighter ==> small.
    _terminal=AIRBASE.TerminalType.FighterAircraft
  elseif _attribute==WAREHOUSE.Attribute.BOMBER or _attribute==WAREHOUSE.Attribute.TRANSPORT_PLANE or _attribute==WAREHOUSE.Attribute.TANKER or _attribute==WAREHOUSE.Attribute.AWACS then
    -- Bigger aircraft.
    _terminal=AIRBASE.TerminalType.OpenBig
  elseif _attribute==WAREHOUSE.Attribute.TRANSPORT_HELO or _attribute==WAREHOUSE.Attribute.ATTACKHELICOPTER then
    -- Helicopter.
    _terminal=AIRBASE.TerminalType.HelicopterUsable
  end
  
end

--- Get parking data for all air assets that need to be spawned at an airbase.
--@param #WAREHOUSE self
--@param #table assetlist A list of assets for which parking spots are required.
--@param #table parkingdata Table of the complete parking data to check. Default is to take it from the @{Wrapper.Airbase#AIRBASE.GetParkingSpotsTable}() function.
--@return #table A table with parking spots for each asset group.
--@return #table The reduced parking data table of the spots that have not been assigned.
function WAREHOUSE:_GetParkingForAssets(assetlist, parkingdata)
  
  --- Remove selected spots from parking data table.
  local function removeparking(parkingdata,spots)
    for j=1,#spots do
      for i=1,#parkingdata do      
        if parkingdata[i].TerminalID==spots[j].TerminalID then
          table.remove(parkingdata,j)
          break
        end
      end
    end
  end
  
  -- Get complete parking data of the airbase.
  parkingdata=parkingdata or self.homebase:GetParkingSpotsTable()
  
  local assetparking={}
  for i=1,#assetlist do
  
    -- Asset specifics.
    local asset=assetlist[i] --#WAREHOUSE.Stockitem
    local group=GROUP:FindByName(asset.templatename)
    local nunits=#group:GetUnits()
    local terminal=self:_GetTerminal(asset.attribute)
    
    -- Find appropiate parking spots for this group.
    local spots=self.homebase:FindFreeParkingSpotForAircraft(group, terminal, nil, nil, nil, nil, nil, nil, parkingdata)
    
    -- Not enough parking spots for this group.
    if #spots<nunits then
      return nil,nil
    end
    
    -- Put result in table.
    table.insert(assetparking, spots)
    
    -- Remove parking spots from table so that will not be available in the next iteration.
    removeparking(parkingdata,spots)
  end
  
  return assetparking, parkingdata
end

--- Filter stock assets by table entry.
-- @param #WAREHOUSE self
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Stockitem}.
-- @param #string item Descriptor
-- @param value Value of the descriptor.
-- @param #number nmax (Optional) Maximum number of items that will be returned. Default is all matching items are returned.
-- @return #table Filtered stock items table.
function WAREHOUSE:_FilterStock(stock, item, value, nmax)

  -- Filtered array.
  local filtered={}

  -- Loop over stock items.
  for _i,_stock in ipairs(stock) do
    if _stock[item]==value then
      _stock.pos=_i
      table.insert(filtered, _stock)
      if nmax~=nil and #filtered>=nmax then
        return filtered
      end
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
    local truck=group:HasAttribute("Trucks") and not group:GetCategory()==Group.Category.TRAIN
    local train=group:GetCategory()==Group.Category.TRAIN

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
    elseif train then
      attribute=WAREHOUSE.Attribute.TRAIN
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
-- @param #number _uid The unique id of the item to be deleted.
function WAREHOUSE:_DeleteStockItem(_uid)
  for i=1,#self.stock do
    local item=self.stock[i] --#WAREHOUSE.Stockitem
    if item.id==_uid then
      table.remove(self.stock,i)
      break
    end
  end
end

--- Delete item from queue.
-- @param #WAREHOUSE self
-- @param #number _uid The id of the item to be deleted.
function WAREHOUSE:_DeleteQueueItem(_uid)
  for i=1,#self.queue do
    local item=self.queue[i] --#WAREHOUSE.Queueitem
    if item.uid==_uid then
      table.remove(self.queue,i)
      break
    end
  end
end

--- Sort requests queue wrt prio and request uid.
-- @param #WAREHOUSE self
function WAREHOUSE:_SortQueue()
  self:F3()
  -- Sort.
  local function _sort(a, b)
    return (a.prio < b.prio) or (a.prio==b.prio and a.uid < b.uid)
  end
  table.sort(self.queue, _sort)
end

--- Prints the queue to DCS.log file.
-- @param #WAREHOUSE self
function WAREHOUSE:_PrintQueue()
  env.info(self.wid.."Queue:")
  for _,_qitem in ipairs(self.queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem
    local text=string.format("uid=%d, prio=%d, airbase=%s (category=%d), descriptor: %s=%s, nasssets=%d, transport=%s, ntransport=%d",
      qitem.uid, qitem.prio, qitem.airbase:GetName(),qitem.category, qitem.assetdesc,tostring(qitem.assetdescval),qitem.nasset,qitem.transporttype,qitem.ntransport)
    env.info(text)
  end
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

