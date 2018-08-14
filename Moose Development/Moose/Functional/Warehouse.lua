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
-- @field Wrapper.Static#STATIC warehouse The phyical warehouse structure. 
-- @field DCS#coalition.side coalition Coalition ID the warehouse belongs to.
-- @field DCS#country.id country Country ID the warehouse belongs to.
-- @field Wrapper.Airbase#AIRBASE airbase Airbase the warehouse belongs to.
-- @field #string airbasename Name of the airbase associated to the warehouse.
-- @field DCS#Airbase.Category category Category of the home airbase, i.e. airdrome, helipad/farp or ship.
-- @field Core.Point#COORDINATE coordinate Coordinate of the warehouse.
-- @field Core.Point#COORDINATE road Closest point to warehouse on road.
-- @field Core.Point#COORDINATE rail Closest point to warehouse on rail.
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
-- A warehouse is an abstract object represented by a physical (static) building that can hold virtual assets in stock.
-- It can but it must not be associated with a particular airbase. The associated airbase can be an airdrome, a Helipad/FARP or a ship.
-- 
-- If another another warehouse requests assets, the corresponding troops are spawned at the warehouse and being transported to the requestor or go their
-- by themselfs. Once arrived at the requesting warehouse, the assets go into the stock of the requestor and can be reactivated when necessary.
--
-- ## What assets can be stored?
-- Any kind of ground or airborn asset can be stored. Ships not supported at the moment due to the fact that airbases are bound to airbases which are
-- normally not located near the sea.
-- 
-- # Adding Assets
--
-- # Requests
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
  warehouse  = nil,
  coalition  = nil,
  country    = nil,
  airbase    = nil,
  airbasename = nil,
  category   = -1,
  coordinate = nil,
  road       = nil,
  rail       = nil,
  spawnzone  = nil,
  wid        = nil,
  uid        = nil,
  markerid   = nil,
  assetid    = 0,
  queueid    = 0,
  stock      = {},
  queue      = {},
  pending    = {},
}

--- Item of the warehouse stock table.
-- @type WAREHOUSE.Stockitem
-- @field #number uid Unique id of the asset.
-- @field #string templatename Name of the template group.
-- @field #table template The spawn template of the group.
-- @field DCS#Group.Category category Category of the group.
-- @field #string unittype Type of the first unit of the group as obtained by the Object.getTypeName() DCS API function.
-- @field #number nunits Number of units in the group.
-- @field #number range Range of the unit in meters.
-- @field #number speedmax Maximum speed in km/h the unit can do.
-- @field #WAREHOUSE.Attribute attribute Generalized attribute of the group.

--- Item of the warehouse queue table.
-- @type WAREHOUSE.Queueitem
-- @field #number uid Unique id of the queue item.
-- @field #number prio Priority of the request.
-- @field #WAREHOUSE warehouse Requesting warehouse.
-- @field Wrapper.Airbase#AIRBASE airbase Requesting airbase or airbase beloning to requesting warehouse.
-- @field DCS#Airbase.Category category Category of the requesting airbase, i.e. airdrome, helipad/farp or ship.
-- @field #WAREHOUSE.Descriptor assetdesc Descriptor of the requested asset.
-- @field assetdescval Value of the asset descriptor. Type depends on descriptor.
-- @field #number nasset Number of asset groups requested.
-- @field #WAREHOUSE.TransportType transporttype Transport unit type.
-- @field #number ntransport Number of transport units requested.

--- Item of the warehouse pending queue table.
-- @type WAREHOUSE.Pendingitem
-- @extends #WAREHOUSE.Queueitem
-- @field #table assetlist Table of assets to be delivered. Each element of the table is a @{#WAREHOUSE.Stockitem}.
-- @field #number ndelivered Number of groups delivered to destination. Is managed automatically.
-- @field #number ntransporthome Number of transports back home. Is managed automatically.
-- @field Core.Set#SET_GROUP cargogroupset Set of cargo groups do be delivered. Is managed automatically.
-- @field Core.Set#SET_GROUP transportgroupset Set of cargo transport groups. Is managed automatically.

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
WAREHOUSE.version="0.1.7"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: Warehouse todo list.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add event handlers.
-- DONE: Add AI_CARGO_AIRPLANE
-- DONE: Add AI_CARGO_APC
-- DONE: Add AI_CARGO_HELICOPTER
-- DONE: Switch to AI_CARGO_XXX_DISPATCHER
-- DONE: Add queue.
-- TODO: Write documentation.
-- TODO: Put active groups into the warehouse, e.g. when they were transported to this warehouse.
-- TODO: Spawn warehouse assets as uncontrolled or AI off and activate them when requested.
-- TODO: Handle cases with immobile units.
-- TODO: How to handle multiple units in a transport group?
-- DONE: Add phyical object
-- TODO: If warehouse is destoyed, all asssets are gone.
-- TODO: If warehosue is captured, change warehouse and assets to other coalition.
-- TODO: Handle cases for aircraft carriers and other ships. Place warehouse on carrier possible? On others probably not - exclude them?
-- TODO: Handle cargo crates.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- WAREHOUSE constructor. Creates a new WAREHOUSE object accociated with an airbase.
-- @param #WAREHOUSE self
-- @param Wrapper.Static#STATIC warehouse The physical structure of the warehouse.
-- @param Core.Zone#ZONE spawnzone (Optional) The zone in which units are spawned and despawned when they leave or arrive the warehouse. Default is a zone of 200 meters around the warehouse.
-- @param Wrapper.Airbase#AIRBASE airbase (Optional) The airbase belonging to the warehouse. Default is the closest airbase to the warehouse structure as long as it within a range of 3 km. 
-- @return #WAREHOUSE self
function WAREHOUSE:New(warehouse, spawnzone, airbase)
  BASE:E({warehouse=warehouse:GetName()})
  
  -- Nil check.
  if warehouse==nil then
    BASE:E("ERROR: Warehouse does not exist!")
    return nil
  end

  -- Print version.
  env.info(string.format("Adding warehouse v%s for structure %s", WAREHOUSE.version, warehouse:GetName()))

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit( self, FSM:New() ) -- #WAREHOUSE

  -- Set some string id for output to DCS.log file.
  self.wid=string.format("WAREHOUSE %s | ", warehouse:GetName())

  -- Set some variables.
  self.warehouse=warehouse
  self.uid=warehouse:GetID()
  self.coalition=warehouse:GetCoalition()
  self.country=warehouse:GetCountry()
  self.coordinate=warehouse:GetCoordinate()
  
  -- Set airbase.
  if airbase then
    -- User requested.
    self.airbase=airbase
    self.airbasename=self.airbase:GetName()
  else
    -- Closest of the same coalition but within a certain range.
    local _airbase=self.coordinate:GetClosestAirbase(nil, self.coalition)
    if _airbase and _airbase:GetCoordinate():Get2DDistance(self.coordinate) < 3000 then
      self.airbase=_airbase
      self.airbasename=self.airbase:GetName()
      self.category=self.airbase:GetDesc().category
    end
  end
      
  -- Get the closest point on road and rail.
  local _road=self.coordinate:GetClosestPointToRoad()
  local _rail=self.coordinate:GetClosestPointToRoad(true)

  -- Set connections.  
  if _road and _road:Get2DDistance(self.coordinate) < 3000 then
    self.road=_road
    _road:MarkToAll(string.format("%s road connection.", self.warehouse:GetName()), true)
  end
  if _rail and _rail:Get2DDistance(self.coordinate) < 3000 then
    self.rail=_rail
    _rail:MarkToAll(string.format("%s rail connection.", self.warehouse:GetName()), true)
  end

  -- Define the default spawn zone.
  self.spawnzone=ZONE_RADIUS:New(string.format("Spawnzone %s",warehouse:GetName()), warehouse:GetVec2(), 200)
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  self:AddTransition("Stopped", "Load",          "Stopped")
  self:AddTransition("Stopped", "Start",         "Running")
  self:AddTransition("Running", "Status",        "*")
  self:AddTransition("Paused",  "Status",        "*")
  self:AddTransition("*",       "AddAsset",      "*")
  self:AddTransition("*",       "AddRequest",    "*")
  self:AddTransition("Running", "Request",       "*")
  self:AddTransition("*",       "Unloaded",      "*")  -- Cargo has been unloaded from the carrier.
  self:AddTransition("*",       "Arrived",       "*")
  self:AddTransition("*",       "Delivered",     "*")
  self:AddTransition("*",       "SelfDelivered", "*")
  self:AddTransition("Running", "Pause",         "Paused")
  self:AddTransition("Paused",  "Unpause",       "Running")
  self:AddTransition("*",       "Stop",          "Stopped")
  self:AddTransition("*",       "Save",          "*")

  -- Pseudo Functions
  
  --- Triggers the FSM event "Start". Starts the warehouse.
  -- @function [parent=#WAREHOUSE] Start
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Start" after a delay. Starts the warehouse.
  -- @function [parent=#WAREHOUSE] __Start
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the warehouse.
  -- @function [parent=#WAREHOUSE] Stop
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Stop" after a delay. Stops the warehouse.
  -- @function [parent=#WAREHOUSE] __Stop
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Pause". Pauses the warehouse.
  -- @function [parent=#WAREHOUSE] Pauses
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Pause" after a delay. Pause the warehouse.
  -- @function [parent=#WAREHOUSE] __Pause
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Unpause". Pauses the warehouse.
  -- @function [parent=#WAREHOUSE] UnPause
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Unpause" after a delay. Pause the warehouse.
  -- @function [parent=#WAREHOUSE] __Unpause
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.



  --- Triggers the FSM event "Status". Queue is updated and requests are executed.
  -- @function [parent=#WAREHOUSE] Status
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Status" after a delay. Queue is updated and requests are executed.
  -- @function [parent=#WAREHOUSE] __Status
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.


  --- Trigger the FSM event "AddAsset". Add an airplane group to the warehouse stock.
  -- @function [parent=#WAREHOUSE] AddAsset
  -- @param #WAREHOUSE self
  -- @param #string templategroupname Name of the late activated template group as defined in the mission editor.
  -- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.

  --- Trigger the FSM event "AddAsset" with a delay. Add an airplane group to the warehouse stock.
  -- @function [parent=#WAREHOUSE] __AddAsset
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #string templategroupname Name of the late activated template group as defined in the mission editor.
  -- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.


  --- Triggers the FSM event "AddRequest". Add a request to the warehouse queue, which is processed when possible.
  -- @function [parent=#WAREHOUSE] AddRequest
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE warehouse The warehouse requesting supply.
  -- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
  -- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
  -- @param #number nAsset Number of groups requested that match the asset specification.
  -- @param #WAREHOUSE.TransportType TransportType Type of transport.
  -- @param #number nTransport Number of transport units requested.
  -- @param #number Prio Priority of the request. Number ranging from 1=high to 100=low.

  --- Triggers the FSM event "AddRequest" with a delay. Add a request to the warehouse queue, which is processed when possible.
  -- @function [parent=#WAREHOUSE] __AddRequest
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE warehouse The warehouse requesting supply.
  -- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
  -- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
  -- @param #number nAsset Number of groups requested that match the asset specification.
  -- @param #WAREHOUSE.TransportType TransportType Type of transport.
  -- @param #number nTransport Number of transport units requested.
  -- @param #number Prio Priority of the request. Number ranging from 1=high to 100=low.


  --- Triggers the FSM event "Request". Executes a request from the queue if possible.
  -- @function [parent=#WAREHOUSE] Request
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.
 
  --- Triggers the FSM event "Request" after a delay. Executes a request from the queue if possible.
  -- @function [parent=#WAREHOUSE] __Request
  -- @param #WAREHOUSE self
  -- @param #number Delay Delay in seconds.
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.


  --- Triggers the FSM event "Arrived", i.e. when a group has arrived at the destination.
  -- @function [parent=#WAREHOUSE] Arrived
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group Group that has arrived.

  --- Triggers the FSM event "Arrived" after a delay, i.e. when a group has arrived at the destination.
  -- @function [parent=#WAREHOUSE] __Arrived
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Group#GROUP group Group that has arrived.


  --- Triggers the FSM event "Delivered". A group has been delivered from the warehouse to another airbase or warehouse.
  -- @function [parent=#WAREHOUSE] Delivered
  -- @param #WAREHOUSE self
  -- @param Core.Set#SET_GROUP groupset Set of groups that were delivered.

  --- Triggers the FSM event "Delivered" after a delay. A group has been delivered from the warehouse to another airbase or warehouse.
  -- @function [parent=#WAREHOUSE] __Delivered
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Core.Set#SET_GROUP groupset Set of groups that were delivered.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set a zone where the (ground) assets of the warehouse are spawned once requested.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The spawn zone.
-- @return #WAREHOUSE self
function WAREHOUSE:SetSpawnZone(zone)
  self.spawnzone=zone
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

  -- Short info.  
  local text=string.format("Starting warehouse %s:\n",self.warehouse:GetName())
  text=text..string.format("Coaliton = %d\n", self.coalition)
  text=text..string.format("Country  = %d\n", self.country)
  text=text..string.format("Airbase  = %s (%s)\n", tostring(self.airbase:GetName()), tostring(self.category))
  env.info(text)
  
  -- Save self in static object. Easier to retrieve later.
  self.warehouse:SetState(self.warehouse, "WAREHOUSE", self)
  
  -- Debug mark spawn zone.
  self.spawnzone:BoundZone(60, self.country)
  self.spawnzone:GetCoordinate():MarkToAll("Spawnzone of warehouse "..self.warehouse:GetName())

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self._OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self._OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self._OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self._OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEventEngineShutdown)
  self:HandleEvent(EVENTS.Crash,          self._OnEventCrashOrDead)
  self:HandleEvent(EVENTS.Dead,           self._OnEventCrashOrDead)
  self:HandleEvent(EVENTS.BaseCaptured,   self._OnEventBaseCaptured)
  
  self:__Status(5)
end

--- On after "Stop" event. Stops the warehouse, unhandles all events.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStop(From, Event, To)
  self:E(self.wid..string.format("Warehouse stopped"))
  
  -- Unhandle event.
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.EngineStartup)
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.BaseCaptured)
end

--- On after "Pause" event. Pauses the warehouse, i.e. no requests are processed. However, new requests and new assets can be added in this state.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterPause(From, Event, To)
  self:E(self.wid..string.format("Warehouse paused! Queued requests are not processed in this state."))
end

--- On after "Unpause" event. Unpauses the warehouse, i.e. requests in queue are processed again.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterUnpause(From, Event, To)
  self:E(self.wid..string.format("Warehouse unpaused! Processing of requests is resumed again."))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Status event. Checks the queue and handles requests.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStatus(From, Event, To)
  self:E(self.wid..string.format("Checking warehouse status of %s", self.warehouse:GetName()))
  
    -- Print queue.
  self:_PrintQueue(self.queue, "Queue0:")
  self:_PrintQueue(self.pending, "Pending0:")

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
  self:_PrintQueue(self.queue, "Queue:")
  self:_PrintQueue(self.pending, "Pending:")
  
  -- Check queue and handle requests if possible.
  local request=self:_CheckQueue()

  -- Execute the request. If the request is really executed, it is also deleted from the queue.
  if request then
    self:Request(request)
  end

  -- Print queue.
  self:_PrintQueue(self.queue, "Queue2:")
  self:_PrintQueue(self.pending, "Pending2:")

  -- Call status again in 30 sec.
  self:__Status(30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "AddAsset" event. Add an airplane group to the warehouse stock.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string templategroupname Name of the late activated template group as defined in the mission editor.
-- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
function WAREHOUSE:onafterAddAsset(From, Event, To, templategroupname, ngroups)

  -- Set default.
  local n=ngroups or 1

  local group=GROUP:FindByName(templategroupname)

  if group then

    local DCSgroup=group:GetDCSObject()
    local DCSunit=DCSgroup:getUnit(1)
    local DCSdesc=DCSunit:getDesc()
    local DCSdisplay=DCSdesc.displayName
    local DCScategory=DCSgroup:getCategory()
    local DCStype=DCSunit:getTypeName()
    local SpeedMax=group:GetSpeedMax()
    local RangeMin=group:GetRange()

    env.info(string.format("New asset:"))
    env.info(string.format("Group name   = %s", group:GetName()))
    env.info(string.format("Display name = %s", DCSdisplay))
    env.info(string.format("Category     = %s", DCScategory))
    env.info(string.format("Type         = %s", DCStype))
    env.info(string.format("Speed max    = %s km/h", tostring(SpeedMax)))
    env.info(string.format("Range min    = %s m", tostring(RangeMin)))
    self:E({fullassetdesc=DCSdesc})

    -- Get the generalized attribute.
    local attribute=self:_GetAttribute(templategroupname)

    -- Add this n times to the table.
    for i=1,n do
      local stockitem={} --#WAREHOUSE.Stockitem
      
      self.assetid=self.assetid+1
      
      stockitem.uid=self.assetid
      stockitem.templatename=templategroupname
      stockitem.template=UTILS.DeepCopy(_DATABASE.Templates.Groups[templategroupname].Template)
      stockitem.category=DCScategory
      stockitem.unittype=DCStype
      stockitem.attribute=attribute
      stockitem.range=RangeMin
      stockitem.speedmax=SpeedMax
      
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

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "AddRequest" event. Add a request to the warehouse queue, which is processed when possible.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE warehouse The warehouse requesting supply.
-- @param #WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
-- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
-- @param #number nAsset Number of groups requested that match the asset specification.
-- @param #WAREHOUSE.TransportType TransportType Type of transport.
-- @param #number nTransport Number of transport units requested.
-- @param #number Prio Priority of the request. Number ranging from 1=high to 100=low.
function WAREHOUSE:onafterAddRequest(From, Event, To, warehouse, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType, nTransport, Prio)

  -- Defaults.
  nAsset=nAsset or 1
  TransportType=TransportType or WAREHOUSE.TransportType.SELFPROPELLED
  Prio=Prio or 50
  if nTransport==nil then
    if TransportType==WAREHOUSE.TransportType.SELFPROPELLED then
      nTransport=0
    else
      nTransport=1
    end
  end
  
  -- Increase id.
  self.queueid=self.queueid+1

  -- Request queue table item.
  local request={
  uid=self.queueid,
  prio=Prio,
  warehouse=warehouse,
  airbase=warehouse.airbase,
  category=warehouse.category,
  assetdesc=AssetDescriptor,
  assetdescval=AssetDescriptorValue,
  nasset=nAsset,
  transporttype=TransportType,
  ntransport=nTransport,
  ndelivered=0,
  ntransporthome=0
  } --#WAREHOUSE.Queueitem
  
  -- Add request to queue.
  table.insert(self.queue, request)

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
  --env.info(self.wid..string.format("Warehouse %s requesting %d assets of %s=%s by transport %s", 
  --Request.warehouse:GetName(), Request.nasset, tostring(Request.assetdesc), tostring(Request.assetdescval), tostring(Request.transporttype)))

  -- Distance from warehouse to requesting airbase.
  local distance=self.coordinate:Get2DDistance(Request.airbase:GetCoordinate())

  -- Filter the requested assets.
  local _assets=self:_FilterStock(self.stock, Request.assetdesc, Request.assetdescval, Request.nasset)
  
  -- Check if destination is in range for all requested assets.
  for _,_asset in pairs(_assets) do
    local asset=_asset --#WAREHOUSE.Stockitem
    if asset.range<distance then
    local text=string.format("Request denied! Destination %s is out of range for asset %s", Request.airbase:GetName(), asset.templatename)
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    --TODO Delete request from queue because it will never be possible!
    return false
    end
  end

  -- Asset is not in stock ==> request denied.
  if #_assets < Request.nasset then
    local text=string.format("Request denied! Not enough assets currently in stock. Requested %d < %d in stock.", Request.nasset, #_assets)
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    return false
  end

  return true
end


--- On after "Request" event. Initiates the transport of the assets to the requesting warehouse.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
function WAREHOUSE:onafterRequest(From, Event, To, Request)

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Cargo assets.
  ------------------------------------------------------------------------------------------------------------------------------------
  
  -- Pending request.
  local Pending=Request  --#WAREHOUSE.Pendingitem

  -- Spawn assets.    
  local _spawngroups,_cargotype,_cargocategory,_cargoassets=self:_SpawnAssetRequest(Request) --Core.Set#SET_GROUP
  
  -- Add cargo groups to request.
  Pending.cargogroupset=_spawngroups
  Pending.cargoassets=_cargoassets
  --Request.cargogroupset=_spawngroups
  --Request.ndelivered=0  
  
  -- Add groups to cargo if they don't go by themselfs.
  local CargoGroups --Core.Set#SET_CARGO
  if Request.transporttype ~= WAREHOUSE.TransportType.SELFPROPELLED then
  
    --TODO: make nearradius depended on transport type and asset type.
    local _loadradius=5000
    local _nearradius=35
    
    if Request.transporttype==WAREHOUSE.TransportType.AIRPLANE then
      _loadradius=5000
    elseif Request.transporttype==WAREHOUSE.TransportType.HELICOPTER then
      _loadradius=500
    elseif Request.transporttype==WAREHOUSE.TransportType.APC then
      _loadradius=100
    end
    
    -- Empty cargo group set.
    CargoGroups = SET_CARGO:New()
    
    -- Add cargo groups to set.
    for _i,_group in pairs(_spawngroups:GetSetObjects()) do
      local group=_group --Wrapper.Group#GROUP
      local _wid,_aid,_rid=self:_GetIDsFromGroup(group)
      local _alias=self:_alias(group:GetTypeName(),_wid,_aid,_rid)
      local cargogroup = CARGO_GROUP:New(_group, _cargotype,_alias,_loadradius,_nearradius)
      CargoGroups:AddCargo(cargogroup)
    end
    
  end

  -- Self request! Assets are only spawned but not routed or transported anywhere.  
  if self.warehouse:GetName()==Request.warehouse.warehouse:GetName() then
    env.info("FF selfrequest!")
    self:__SelfDelivered(_spawngroups)
    return
  end

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Self propelled assets.
  ------------------------------------------------------------------------------------------------------------------------------------

  -- No transport unit requested. Assets go by themselfes.
  if Request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
    env.info("FF selfpropelled")

    for _,_spawngroup in pairs(_spawngroups:GetSetObjects()) do
      
      local group=_spawngroup --Wrapper.Group#GROUP
            
      local ToCoordinate=Request.warehouse.spawnzone:GetRandomCoordinate(50)      
      ToCoordinate:MarkToAll("Destination")
            
      -- Route cargo to their destination.
      if _cargocategory==Group.Category.GROUND then
        env.info("FF route ground "..group:GetName())
        self:_RouteGround(group, ToCoordinate)
      elseif _cargocategory==Group.Category.AIRPLANE then
        env.info("FF route plane "..group:GetName())
        self:_RouteAir(group, Request.airbase)
      elseif _cargocategory==Group.Category.HELICOPTER then
        env.info("FF route helo "..group:GetName())
        self:_RouteAir(group, Request.airbase)
      elseif _cargocategory==Group.Category.SHIP then
        self:E("ERROR: self propelled ship not implemented yet!")
      elseif _cargocategory==Group.Category.TRAIN then
        env.info("FF route train "..group:GetName())
        self:_RouteTrain(group, ToCoordinate)
      else
        self:E(self.wid..string.format("ERROR: unknown category %s for self propelled cargo %s!",tostring(_cargocategory), tostring(group:GetName())))
      end

    end
    
    -- Add request to pending queue.
    table.insert(self.pending, Request)
    
    -- Delete request from queue.
    self:_DeleteQueueItem(Request.uid)
    
    -- No cargo transport necessary.
    return
  end
  
  ------------------------------------------------------------------------------------------------------------------------------------
  -- Transport assets and dispachers
  ------------------------------------------------------------------------------------------------------------------------------------

  -- Set of cargo carriers.
  local TransportSet = SET_GROUP:New():FilterDeads()

  -- Pickup and deploy zones/bases.
  local PickupAirbaseSet = SET_AIRBASE:New():AddAirbase(self.airbase)
  local DeployAirbaseSet = SET_AIRBASE:New():AddAirbase(Request.airbase)
  local DeployZoneSet    = SET_ZONE:New():AddZone(Request.warehouse.spawnzone)
  
  -- Cargo dispatcher.
  local CargoTransport --AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER

  -- Filter the requested transport assets.
  local _assetstock=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, Request.transporttype, Request.ntransport)
  
  -- General type and category.
  local _transporttype=_assetstock[1].attribute    --#WAREHOUSE.Attribute
  local _transportcategory=_assetstock[1].category --DCS#Group.Category

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
      local spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias):InitCoalition(self.coalition):InitCountry(self.country)
      local spawngroup=spawn:InitUnControlled(true):SpawnAtAirbase(self.airbase,_takeoff, nil, nil, false, _parking)

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        table.insert(_delid,_assetitem.uid)
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
      local spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias):InitCoalition(self.coalition):InitCountry(self.country)
      local spawngroup=spawn:InitUnControlled(false):SpawnAtAirbase(self.airbase,_takeoff, nil, nil, false, _parking)

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        table.insert(_delid,_assetitem.uid)
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
    CargoTransport:Setairbase(self.airbase)
    --CargoTransport:SetHomeZone(self.spawnzone)

  elseif Request.transporttype==WAREHOUSE.TransportType.APC then

    -- Spawn the transport groups.
    local _delid={}
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem

      -- Spawn with ALIAS here or DCS crashes!
      local _alias=self:_Alias(_assetitem, Request)

      -- Spawn plane at airport in uncontrolled state.
      --local spawn=SPAWN:NewWithAlias(_assetitem.templatename,_alias)
      local spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias):InitCoalition(self.coalition):InitCountry(self.country)
      local spawngroup=spawn:SpawnFromCoordinate(self.spawnzone:GetRandomCoordinate())

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        table.insert(_delid,_assetitem.uid)
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

    self:E(self.wid.."ERROR: cargo transport by train not supported yet!")
    return

  elseif Request.transporttype==WAREHOUSE.TransportType.SHIP then

    self:E(self.wid.."ERROR: cargo transport by ship not supported yet!")
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

    -- Trigger Arrived event.
    warehouse:__Arrived(1, group)
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

  -- Add request to pending queue.
  table.insert(self.pending, Request)

  -- Delete request from queue.
  self:_DeleteQueueItem(Request.uid)

end


--- Spawns requested asset at warehouse or associated airbase.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
-- @return Core.Set#SET_GROUP Set of groups that were spawned.
-- @return #WAREHOUSE.Attribute Generalized attribute of asset.
-- @return DCS#Group.Category Category of asset, i.e. ground, air, ship, ...
function WAREHOUSE:_SpawnAssetRequest(Request)

  -- Filter the requested cargo assets.
  local _assetstock=self:_FilterStock(self.stock, Request.assetdesc, Request.assetdescval, Request.nasset)
  
  -- No assets in stock :(
  if #_assetstock==0 then
    return nil,nil,nil
  end

  -- General type and category.
  local _cargotype=_assetstock[1].attribute    --#WAREHOUSE.Attribute
  local _cargocategory=_assetstock[1].category --DCS#Group.Category
  
  -- Now we try to find all parking spots for all cargo groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  if  _cargocategory==Group.Category.AIRPLANE or _cargocategory==Group.Category.HELICOPTER then
    Parking=self:_GetParkingForAssets(_assetstock)    
  end
  
  -- Spawn aircraft in uncontrolled state if request comes from the same warehouse.
  local UnControlled=false
  local AIOnOff=true
  if self.warehouse:GetName()==Request.warehouse.warehouse:GetName() then
    UnControlled=true
    AIOnOff=false
  end
  
  -- Create an empty set.
  local groupset=SET_GROUP:New():FilterDeads()

  -- Spawn the assets.
  local _delid={}
  local _spawngroups={}
  local _assets={}
  
  -- Loop over cargo requests.
  for i=1,Request.nasset do

    -- Get stock item.
    local _assetitem=_assetstock[i] --#WAREHOUSE.Stockitem

    -- Find a random point within the spawn zone.
    local spawncoord=self.spawnzone:GetRandomCoordinate()    
    
    -- Alias of the group.
    local _alias=self:_Alias(_assetitem, Request)
    
    -- Spawn object. Spawn with ALIAS here or DCS crashes!
    --local _spawn=SPAWN:NewFromTemplate(_assetitem.template,_assetitem.templatename,_alias):InitCoalition(self.coalition):InitCountry(self.country)
    local _spawn=SPAWN:NewWithAlias(_assetitem.templatename,_alias):InitCoalition(self.coalition):InitCountry(self.country):InitUnControlled(UnControlled):InitAIOnOff(AIOnOff)

    local _group=nil --Wrapper.Group#GROUP    
    local _attribute=_assetitem.attribute
      
    if _assetitem.category==Group.Category.GROUND then
    
      -- Spawn ground troops.      
      _group=_spawn:SpawnFromCoordinate(spawncoord)
      
    elseif _assetitem.category==Group.Category.AIRPLANE or _assetitem.category==Group.Category.HELICOPTER then
    
      --TODO: spawn only so many groups as there are parking spots. Adjust request and create a new one with the reduced number!
    
      -- Spawn air units.
      _group=_spawn:SpawnAtAirbase(self.airbase, SPAWN.Takeoff.Cold, nil, nil, true, Parking[i])
      
    elseif _assetitem.category==Group.Category.TRAIN then
    
      -- Spawn train.
      if self.rail then
        --TODO: Rail should only get one asset because they would spawn on top!
        _group=_spawn:SpawnFromCoordinate(self.rail)
      end
      
    end

    if _group then
      --_spawngroups[i]=_group
      groupset:AddGroup(_group)
      table.insert(_assets, _assetitem)
      table.insert(_delid,_assetitem.uid)
    else
      self:E(self.wid.."ERROR: cargo asset could not be spawned!")
    end
    
  end

  -- Delete spawned items from warehouse stock.
  for _,_id in pairs(_delid) do
    self:_DeleteStockItem(_id)
  end

  return groupset,_cargotype,_cargocategory,_assets
end 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Unloaded" event. Triggered when a group was unloaded from the carrier.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group that was delivered.
function WAREHOUSE:onafterUnloaded(From, Event, To, group)
  -- Debug info.
  self:E(self.wid..string.format("Cargo %s unloaded!", tostring(group:GetName())))
  group:SmokeWhite()

  -- Get max speed of group.
  local speedmax=group:GetSpeedMax()
  
  if group:IsGround() then
    if speedmax>1 then
      group:RouteGroundTo(self.spawnzone:GetRandomCoordinate(50), speedmax*0.5, AI.Task.VehicleFormation.RANK, 3)
    else
      -- Immobile ground unit ==> directly put it into the warehouse.
      self:Arrived(group)
    end
  elseif group:IsAir() then
    -- Not sure if air units will be allowed as cargo even though it might be possible. Best put them into warehouse immediately.
    self:Arrived(group)
  elseif group:IsShip() then
    -- Not sure if naval units will be allowed as cargo even though it might be possible. Best put them into warehouse immediately.
    self:Arrived(group)    
  end  
  
end

--- On after "Arrived" event. Triggered when a group has arrived at its destination.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group that was delivered.
function WAREHOUSE:onafterArrived(From, Event, To, group)
   
  self:E(self.wid..string.format("Cargo %s arrived!", tostring(group:GetName())))
  group:SmokeOrange()
  
  -- Update pending request.
  local request=self:_UpdatePending(group)
  
    -- All cargo delivered.
  if request and request.cargogroupset:Count()==0 then
    self:__Delivered(5, request.cargogroupset, request)
  end
  
end

--- Update the pending requests by removing assets that have arrived.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that has arrived at its destination.
-- @return #WAREHOUSE.Pendingitem The updated request from the pending queue.
function WAREHOUSE:_UpdatePending(group)
  
  -- Get request from group name.
  local request=self:_GetRequestOfGroup(group, self.pending)
  
  -- Get the IDs for this group. In particular, we use the asset ID to figure out which group was delivered.
  local wid,aid,rid=self:_GetIDsFromGroup(group)
  
  if request then
  
    -- Loop over cargo groups.
    for _,_cargogroup in pairs(request.cargogroupset) do
      local cargogroup=_cargogroup --Wrapper.Group#GROUP
      
      -- IDs of cargo group.
      local cwid,caid,crid=self:_GetIDsFromGroup(cargogroup)
      
      -- Remove group from cargo group set.
      if caid==aid then
        request.cargogroupset:Remove(cargogroup:GetName())
        request.ndelivered=request.ndelivered+1
        break
      end
    end
  else
    self:E(self.wid..string.format("ERROR: pending request could not be updated since request did not exist in pending queue!"))
  end
  
  return request
end


--- On after "Delivered" event.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Pendingitem request
function WAREHOUSE:onafterDelivered(From, Event, To, request)

  env.info("FF all assets delivered!")
  
  -- Put assets in new warehouse.
  for _,_group in pairs(groupset:GetSetObjects()) do
    local group=_group --Wrapper.Group#GROUP
    request.warehouse:AddAsset(group:GetName(), 1)
  end
  
end

--- On after "SelfDelivered" event. Request was initiated to the warehouse itself. Groups are just spawned at the warehouse or the associated airbase.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered.
-- @param #WAREHOUSE.Pendingitem request
function WAREHOUSE:onafterSelfDelivered(From, Event, To, groupset, request)

  env.info("FF all assets delivered!")
  
  -- Put assets in new warehouse.
  for _,_group in pairs(groupset:GetSetObjects()) do
    local group=_group --Wrapper.Group#GROUP
    group:SmokeGreen()
  end
  
  --TODO: delete pending queue item.
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Route ground units to destination.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP Group The ground group.
-- @param Core.Point#COORDINATE Coordinate of the destination.
-- @param #number Speed Speed in km/h to drive to the destination coordinate. Default is 60% of max possible speed the unit can go.
function WAREHOUSE:_RouteGround(Group, Coordinate, Speed)

  if Group and Group:IsAlive() then

    -- Set speed.
    local _speed=Speed or Group:GetSpeedMax()*0.6

    -- Create task.
    local Waypoints, canroad = Group:TaskGroundOnRoad(Coordinate, _speed, "Off Road", true)

    -- Task function triggering the arrived event.
    local TaskFunction = Group:TaskFunction("WAREHOUSE._Arrived", self)

    -- Put task function on last waypoint.
    local Waypoint = Waypoints[#Waypoints]
    Group:SetTaskWaypoint(Waypoint, TaskFunction)

    -- Route group to destination.
    Group:Route(Waypoints, 1)
  end
end

--- Route the airplane from one airbase another.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP Aircraft Airplane group to be routed.
-- @param Wrapper.Airbase#AIRBASE ToAirbase Destination airbase.
-- @param #number Speed Speed in km/h. Default is 80% of max possible speed the group can do.
function WAREHOUSE:_RouteAir(Aircraft, ToAirbase, Speed)

  if Aircraft and Aircraft:IsAlive()~=nil then

    -- Set takeoff type.
    local Takeoff = SPAWN.Takeoff.Cold

    -- Get template of group.
    local Template = Aircraft:GetTemplate()

    -- Nil check
    if Template==nil then
      self:E(self.wid.."ERROR: Template nil in RouteAir!")
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
    
    -- Second point of the route. First point is done in RespawnAtCurrentAirbase() routine.
    Template.route.points[2] = ToWaypoint
        
    -- Respawn group at the current airbase.    
    env.info("FF Respawn at current airbase group = "..Aircraft:GetName().." name before")
    local newAC=Aircraft:RespawnAtCurrentAirbase(Template, Takeoff, false)
    env.info("FF Respawn at current airbase group = "..newAC:GetName().." name after")
    
    -- Handle event engine shutdown and trigger delivered event.
    newAC:HandleEvent(EVENTS.EngineShutdown, self._OnEventArrived)
  else
    self:E(string.format("ERROR: aircraft %s cannot be routed since it does not exist or is not alive %s!", tostring(Aircraft:GetName()), tostring(Aircraft:IsAlive())))
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

--- Task function for last waypoint. Triggering the "Arrived" event.
-- @param Wrapper.Group#GROUP group The group that arrived.
-- @param #WAREHOUSE self
function WAREHOUSE._Arrived(group, warehouse)
  env.info(warehouse.wid..string.format("Group %s arrived", tostring(group:GetName())))
  
  --Trigger delivered event.
  warehouse:__Arrived(1, group)
  
end

--- Simple task function for last waypoint. Triggering the "Arrived" event.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that arrived.
function WAREHOUSE:_ArrivedSimple(group)

  if group then
    --local self:_GetIDsFromGroup(group)
    env.info(self.wid..string.format("Group %s arrived at warehouse ", tostring(group:GetName())))
  
    --Trigger delivered event.
    self:__Arrived(1, group)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event handler functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Arrived event if an air unit/group arrived at its destination.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data table.
function WAREHOUSE:_OnEventArrived(EventData)

  local unit=EventData.IniUnit
  unit:SmokeBlue()
  
  local group=EventData.IniGroup
  self:__Arrived(1, group)

end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventBirth(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event birth!",self.warehouse:GetName()))
  
  if EventData and EventData.id==world.event.S_EVENT_BIRTH then
    if EventData.IniGroup then
      local group=EventData.IniGroup
      
    end
  end
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventEngineStartup(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event engine startup!",self.warehouse:GetName()))
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventTakeOff(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event takeoff!",self.warehouse:GetName()))
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventLanding(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event landing!",self.warehouse:GetName()))
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventEngineShutdown(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event engine shutdown!",self.warehouse:GetName()))
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventCrashOrDead(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event birth!",self.warehouse:GetName()))
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA Eventdata Event data.
function WAREHOUSE:_OnEventBaseCaptured(EventData)
  self:E(self.wid..string.format("Warehouse %s captured event base captured!",self.warehouse:GetName()))
  
  -- This warehouse does not have an airbase and never had one. So i could not be captured.
  if self.airbasename==nil then
    return
  end
  
  if EventData and EventData.id==world.event.S_EVENT_BASE_CAPTURED then
    if EventData.Place then
    
      local airbase=EventData.Place --Wrapper.Airbase#AIRBASE
      
      if EventData.PlaceName==self.airbasename then
        -- Okay, this airbase belongs or did belong to this warehouse.
        
        -- New coalition of airbase after it was captured.
        local coalitionAirbase=airbase:GetCoalition()
        
        -- what can happen?
        -- warehouse is blue, airbase is blue and belongs to warehouse and red captures it. ==> self.airbase=nil
        -- warehouse is blue, airbase is blue self.airbase is nil and blue (re-)captures it ==> self.airbase=Event.Place        
        if self.airbase==nil then
          -- Warehouse lost this airbase previously and not it was re-captured.
          if coalitionAirbase == self.coalition then
            self.airbase=airbase
          end
        else
          -- Captured airbase belongs to this warehouse but was captured by other coaltion.
          if coalitionAirbase ~= self.coalition then
            self.airbase=nil
          end
        end
        
      end
    end
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Checks if the request can be fulfilled in general. If not, it is removed from the queue.
-- Check if departure and destination bases are of the right type. 
-- @param #WAREHOUSE self
-- @param #table queue The queue which is holding the requests to check.
-- @param #WAREHOUSE.Queueitem qitem The request to be checked.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequestValid(queue)

  -- Requests to delete.
  local delid={}
  
  for _,_request in pairs(queue) do
    local request=_request --#WAREHOUSE.Queueitem
    
    local valid=true
    
  --TODO: check that
  -- if warehouse or requestor is a FARP, plane asset and transport not possible.
  -- if requestor or warehouse is a SHIP, APC transport not possible, SELFPROPELLED only for AIR/SHIP
  -- etc. etc...
 
    local asset_air=false
    local asset_plane=false
    local asset_helo=false
    local asset_ground=false
    local asset_train=false
    local asset_naval=false
    
    -- Check if category was provided.
    if request.assetdesc==WAREHOUSE.Descriptor.CATEGORY then
    
      if request.assetdescval==Group.Category.AIRPLANE then
        asset_plane=true
      elseif request.assetdescval==Group.Category.HELICOPTER then
        asset_helo=true
      elseif request.assetdescval==Group.Category.GROUND then
        asset_ground=true
      elseif request.assetdescval==Group.Category.SHIP then
        asset_naval=true
      elseif request.assetdescval==Group.Category.TRAIN then
        asset_ground=true
        asset_train=true
        -- Only one train due to finding spawn placen on rail!
        --nAsset=1
      else
        self:E("ERROR: incorrect request. Asset Descriptor missmatch! Has to be Group.Cagetory.AIRPLANE, ...")
        valid=false
      end
      
    end
    
    -- Check attribute is matching
    if request.assetdesc==WAREHOUSE.Descriptor.ATTRIBUTE then
      if request.assetdescval==WAREHOUSE.Attribute.ARTILLERY then
        asset_ground=true
      elseif request.assetdescval==WAREHOUSE.Attribute.ATTACKHELICOPTER then
        asset_helo=true
      elseif request.assetdescval==WAREHOUSE.Attribute.AWACS then
        asset_plane=true
      elseif request.assetdescval==WAREHOUSE.Attribute.BOMBER then
        asset_plane=true
      elseif request.assetdescval==WAREHOUSE.Attribute.FIGHTER then
        asset_plane=true
      elseif request.assetdescval==WAREHOUSE.Attribute.INFANTRY then
        asset_ground=true
      elseif request.assetdescval==WAREHOUSE.Attribute.OTHER then
        self:E("ERROR: incorrect request. Asset attribute WAREHOUSE.Attribute.OTHER is not valid!")
        valid=false      
      elseif request.assetdescval==WAREHOUSE.Attribute.SHIP then
        asset_naval=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TANK then
        asset_ground=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TANKER then
        asset_plane=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TRAIN then
        asset_ground=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TRANSPORT_APC then
        asset_ground=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TRANSPORT_HELO then
        asset_helo=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TRANSPORT_PLANE then
        asset_plane=true
      elseif request.assetdescval==WAREHOUSE.Attribute.TRUCK then
        asset_ground=true
      else
        self:E("ERROR: incorrect request. Unknown asset attribute!")
        valid=false 
      end
    end
    
    -- General air request.
    asset_air=asset_helo or asset_plane
    
    if request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
    
      if asset_air then
      
        if asset_plane then
        
          -- No airplane to or from FARPS.
          if request.category==Airbase.Category.HELIPAD or self.category==Airbase.Category.HELIPAD then
            self:E("ERROR: incorrect request. Asset aircraft requestst but warehouse or requestor is HELIPAD/FARP!")
            valid=false
          end
          
          -- Category SHIP is not general enough! Fighters can go to carriers. Which fighters, is there an attibute?
          -- Also for carriers, attibute?
          
        elseif asset_helo then
        
          -- Helos need a FARP or AIRBASE or SHIP for spawning. Event if they go there they "cannot" be spawned again.
          -- Unless I allow spawning of helos in the the spawn zone. But one should place at least a FARP there.
          if self.category==-1 or request.category==-1 then
            self:E("ERROR: incorrect request. Helos need a AIRBASE/HELIPAD/SHIP as home/destinaion base!")
            valid=false     
          end
          
        end
        
      elseif asset_ground then
        
        -- No ground assets directly to or from ships.
        -- TODO: May needs refinement if warehouse is on land and requestor is ship in harbour?!
        if (request.category==Airbase.Category.SHIP or self.category==Airbase.Category.SHIP) then
          self:E("ERROR: incorrect request. Ground asset requested but warehouse or requestor is SHIP!")
          valid=false
        end
        
      elseif asset_naval then
    
        self:E("ERROR: incorrect request. Naval units not supported yet!")
        valid=false
      
      end
      
    else
      
      -- Assests need a transport.
        
      if request.transporttype==WAREHOUSE.TransportType.AIRPLANE then
      
        -- Airplanes only to AND from airdromes.
        if self.category~=Airbase.Category.AIRDROME or request.category~=Airbase.Category.AIRDROME then
          self:E("ERROR: incorrect request. Warehouse or requestor does not have an airdrome. No transport by plane possible!")
          valid=false
        end
        
        --TODO: Not sure if there are any transport planes that can land on a carrier?
          
      elseif request.transporttype==WAREHOUSE.TransportType.APC then
      
        -- Transport by ground units.
        
        -- No transport to or from ships
        if self.category==Airbase.Category.SHIP or request.category==Airbase.Category.SHIP then
          self:E("ERROR: incorrect request. Warehouse or requestor is SHIP. No transport by APC possible!")
          valid=false
        end

      elseif request.transporttype==WAREHOUSE.TransportType.HELICOPTER then
      
        -- Transport by helicopters ==> need airbase for spawning but not for delivering to the zone.
        if self.category==-1 then
          self:E("ERROR: incorrect request. Warehouse has no airbase. Transport by helicopter not possible!")
          valid=false
        end
      
      elseif request.transporttype==WAREHOUSE.TransportType.SHIP then
      
        -- Transport by ship.
        self:E("ERROR: incorrect request. Transport by SHIP not implemented yet!")
        valid=false
      
      elseif request.transporttype==WAREHOUSE.TransportType.TRAIN then
      
        -- Only one train due to limited spawn place.
        --nTransport=1
      
        -- Transport by train.
        self:E("ERROR: incorrect request. Transport by TRAIN not implemented yet!")
        valid=false
       
      else
        -- No match.
        self:E("ERROR: incorrect request. Transport type unknown!")
        valid=false
      end
  
    end
    
    -- Add request as unvalid and delete it later.
    if not valid then
      table.insert(delid, request.id)
    end   
 
  end -- loop queue items.


   -- Delete invalid requests.
  for _,_uid in pairs(delid) do
    self:_DeleteQueueItem(_uid)
  end   
 
end

--- Checks if the request can be fullfilled right now.
-- Check for current parking situation, number of assets and transports currently in stock
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem request The request to be checked.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequestNow(request)
    
  local okay=true
  
  -- Check if number of requested assets is in stock.
  local _assets=self:_FilterStock(self.stock, request.assetdesc, request.assetdescval, request.nasset)
  
  -- Nothing in stock.
  if #_assets==0 then
    local text=string.format("Request denied! No assets for this request currently available.")
    MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    return false
  end
  
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
  local Parkingdata
  local Parking
  if self.airbase and (_assetcategory==Group.Category.AIRPLANE or _assetcategory==Group.Category.HELICOPTER) then
    Parkingdata=self.airbase:GetParkingSpotsTable()
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
    if self.airbase and (_transportcategory==Group.Category.AIRPLANE or _transportcategory==Group.Category.HELICOPTER) then
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
    local okay=self:_CheckRequestNow(qitem)
    if okay==true then
      request=qitem
      break
    end
  end

  -- Execute request.
  return request
end

--- Simple task function. Can be used to call a function which has the warehouse and the executing group as parameters.
-- @param #WAREHOUSE self
-- @param #string Function The name of the function to call passed as string.
function WAREHOUSE:_SimpleTaskFunction(Function)
  self:F2({Function})

  -- Name of the warehouse (static) object.
  local warehouse=self.warehouse:GetName()

  -- Task script.
  local DCSScript = {}
  DCSScript[#DCSScript+1] = string.format('env.info("WAREHOUSE: Simple task function called!") ')
  DCSScript[#DCSScript+1] = string.format('local mygroup = GROUP:Find( ... ) ')                         -- The group that executes the task function. Very handy with the "...".
  DCSScript[#DCSScript+1] = string.format('local mystatic=STATIC:FindByName(%s) ', warehouse)           -- The static that holds the warehouse self object.
  DCSScript[#DCSScript+1] = string.format('local warehouse = mygroup:GetState(mystatic, "WAREHOUSE") ') -- Get the warehouse self object from the static.
  DCSScript[#DCSScript+1] = string.format('%s(warehouse, mygroup)', Function)                           -- Call the function, e.g. myfunction.(warehouse,mygroup)  

  -- Create task.
  local DCSTask = CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))
  
  return DCSTask
end

--- Get the proper terminal type based on generalized attribute of the group.
--@param #WAREHOUSE self
--@param #WAREHOUSE.Attribute _attribute Generlized attibute of unit.
--@return Wrapper.Airbase#AIRBASE.TerminalType Terminal type for this group.
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
  
  return _terminal
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
          table.remove(parkingdata, i)
          break
        end
      end
    end
  end
  
  -- Get complete parking data of the airbase.
  parkingdata=parkingdata or self.airbase:GetParkingSpotsTable()
  
  local assetparking={}
  for i=1,#assetlist do
  
    -- Asset specifics.
    local asset=assetlist[i] --#WAREHOUSE.Stockitem
    local group=GROUP:FindByName(asset.templatename)
    local nunits=#group:GetUnits()
    local terminal=self:_GetTerminal(asset.attribute)
    
    --[[
    env.info("asset name      = "..tostring(asset.templatename))
    env.info("asset attribute = "..tostring(asset.attribute))
    env.info("terminal type   = "..tostring(terminal))
    env.info("parking spots   = "..tostring(#parkingdata))
    ]]
    
    -- Find appropiate parking spots for this group.
    local spots=self.airbase:FindFreeParkingSpotForAircraft(group, terminal, nil, nil, nil, nil, nil, nil, parkingdata)
    
    for _,spot in pairs(spots) do
      if spot then
        local coord=spot.Coordinate --Core.Point#COORDINATE
        coord:MarkToAll("Parking spot for "..asset.templatename.." id "..asset.uid.." terminal id "..spot.TerminalID)
      end
    end
    
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

--- Get the request belonging to a group.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which the info is gathered.
-- @param #table queue Queue holding all requests.
-- @return #WAREHOUSE.Pendingitem The request belonging to this group.
function WAREHOUSE:_GetRequestOfGroup(group, queue)

  -- Get warehouse, asset and request ID from group name.
  local wid,aid,rid=self:_GetIDsFromGroup(group)
  
  -- Find the request.
  for _,_request in pairs(queue) do
    local request=_request --#WAREHOUSE.Queueitem
    if request.uid==rid then
      return request
    end
  end
    
end

--- Creates a unique name for spawned assets.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Stockitem _assetitem Asset for which the name is created.
-- @param #WAREHOUSE.Queueitem _queueitem (Optional) Request specific name.
-- @return #string Alias name "UnitType\_WID-%d\_AID-%d\_RID-%d"
function WAREHOUSE:_Alias(_assetitem,_queueitem)
  local _alias=string.format("%s_WID-%d_AID-%d", _assetitem.unittype, self.uid,_assetitem.uid)
  if _queueitem then
    _alias=_alias..string.format("_RID-%d",_queueitem.uid)
  end
  return _alias
end

--- Creates a unique name for spawned assets.
-- @param #WAREHOUSE self
-- @param #string unittype Type of unit.
-- @param #number wid Warehouse id.
-- @param #number aid Asset item id.
-- @param #number qid Queue/request item id.
-- @return #string Alias name "UnitType\_WID-%d\_AID-%d\_RID-%d"
function WAREHOUSE:_alias(unittype, wid, aid, qid)
  local _alias=string.format("%s_WID-%d_AID-%d", unittype, wid, aid)
  if qid then
    _alias=_alias..string.format("_RID-%d", qid)
  end
  return _alias
end

--- Get warehouse id, asset id and request id from group name (alias).
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which the info is gathered.
-- @return #number Warehouse ID.
-- @return #number Asset ID.
-- @return #number Request ID.
function WAREHOUSE:_GetIDsFromGroup(group)

  ---@param #string text The text to analyse.
  local function analyse(text)
  
    -- Get rid of #0001 tail from spawn.
    local unspawned=UTILS.Split(text, "#")[1]
  
    -- Split keywords.  
    local keywords=UTILS.Split(unspawned, "_")
    local _wid=nil  -- warehouse UID
    local _aid=nil  -- asset UID
    local _rid=nil  -- request UID
    
    -- Loop over keys.
    for _,keys in pairs(keywords) do
      local str=UTILS.Split(keys, "-")
      local key=str[1]
      local val=str[2]
      if key:find("WID") then
        _wid=tonumber(val)
      elseif key:find("AID") then
        _aid=tonumber(val)
      elseif key:find("RID") then
        _rid=tonumber(val)
      end      
    end
    
    return _wid,_aid,_rid
  end
  
  if group then
  
    -- Group name
    local name=group:GetName()
      
    -- Get ids
    local wid,aid,rid=analyse(name)
    
    -- Debug info
    self:E(self.wid..string.format("Group Name   = %s", tostring(name)))  
    self:E(self.wid..string.format("Warehouse ID = %s", tostring(wid)))
    self:E(self.wid..string.format("Asset     ID = %s", tostring(aid)))
    self:E(self.wid..string.format("Request   ID = %s", tostring(rid)))
    
    return wid,aid,rid
  else
    self:E("WARNING: Group not found in GetIDsFromGroup() function!")
  end
      
  
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

  local text=self.wid..string.format("Warehouse %s stock assets:\n", self.airbase:GetName())
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
    if item.uid==_uid then
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
-- @param #table queue Queue to print.
-- @param #string name Name of the queue for info reasons.
function WAREHOUSE:_PrintQueue(queue, name)
  env.info(self.wid..name)
  for _,_qitem in ipairs(queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem
    local text=string.format("uid=%d, prio=%d, airbase=%s (category=%d), descriptor: %s=%s, nasssets=%d, transport=%s, ntransport=%d",
    qitem.uid, qitem.prio, qitem.airbase:GetName(),qitem.category, qitem.assetdesc,tostring(qitem.assetdescval),qitem.nasset,qitem.transporttype,qitem.ntransport)
    env.info(text)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

