--- **Functional** - (R2.5) - Simulation of logistics.
--
--
-- Features:
--
--    * Holds (virtual) assests such as intrantry groups in stock.
--    * Manages requests of assets from other warehouses.
--    * Take care of transportation to other warehouses and its accociated airbases.
--    * Different means of automatic transportation (planes, helicopters, APCs, selfpropelled).
--
-- # QUICK START GUIDE
-- 
-- **WIP**
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
-- @field DCS#coalition.side coalition Coalition side the warehouse belongs to.
-- @field DCS#country.id country Country ID the warehouse belongs to.
-- @field #string alias Alias of the warehouse. Name its called when sending messages.
-- @field Core.Zone#ZONE zone Zone around the warehouse. If this zone is captured, the warehouse and all its assets goes to the capturing coaliton.
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
-- @field #number dTstatus Time interval in seconds of updating the warehouse status and processing new events. Default 30 seconds.
-- @field #number queueid Unit id of each request in the queue. Essentially a running number starting at one and incremented when a new request is added.
-- @field #table stock Table holding all assets in stock. Table entries are of type @{#WAREHOUSE.Assetitem}.
-- @field #table queue Table holding all queued requests. Table entries are of type @{#WAREHOUSE.Queueitem}.
-- @field #table pending Table holding all pending requests, i.e. those that are currently in progress. Table elements are of type @{#WAREHOUSE.Pendingitem}.
-- @field #table defending Table holding all defending requests, i.e. self requests that were if the warehouse is under attack. Table elements are of type @{#WAREHOUSE.Pendingitem}.
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
-- # The Warehouse Concept
-- 
-- The MOOSE warehouse adds a new logistic component to the DCS World. *Assets*, i.e. ground, airborne and naval units, can be transferred from one place
-- to another in a realistic and highly automatic fashion. In contrast to a "DCS warehouse" these assets have a physical representation in game. In particular,
-- this means they can be destroyed during the transport and add more life to the DCS world.
-- 
-- Or, in other words, on a scale between 1 and 10, how important do you reckon it is to have the right assets at the right place in a conflict?
-- 
-- The warehouse adresses exactly this "problem" by simulating it in a realistic way while at the same time adding more life and dynamics to the DCS World. 
-- 
-- This comes along with some additional interesting stategic aspects since capturing/defending and destroying/protecting an enemy or your
-- own warehous becomes of critical importance for the development of a conflict.
-- 
-- In essence, creating an efficient network of warehouses is vital for the success of a battle or even the whole war. Likewise, of course, cutting off the enemy
-- of important supply lines by capturing or destroying warehouses or their associated infrastructure is equally important. 
-- 
-- ## What is a warehouse?
-- A warehouse is an abstract object represented by a physical (static) building that can hold virtual assets in stock.
-- It can but it must not be associated with a particular airbase. The associated airbase can be an airdrome, a Helipad/FARP or a ship.
-- 
-- If another warehouse requests assets, the corresponding troops are spawned at the warehouse and being transported to the requestor or go their
-- by themselfs. Once arrived at the requesting warehouse, the assets go into the stock of the requestor and can be activated/deployed when necessary.
-- 
-- ## What assets can be stored?
-- Any kind of ground or airborne asset can be stored. Ships not supported at the moment due to the fact that airbases are bound to airbases which are
-- normally not located near the sea.
-- 
-- ## What means of transportation are available?
-- Firstly, all mobile assets can be send from warehouse to another on their own.
-- 
-- * Ground vehicles will use the road infrastructure
-- * Airborne units are get a flightplan from the airbase the sending warehouse to the airbase of the receiving warehouse. This already implies that for airborne
-- assets both warehouses need an airbase. If either one of the warehouses does not have an associated airbase, transportation of airborne assest is not possible.
-- * Naval units can be exchanged between warehouses which posses a port/habour. Also shipping lanes must be specified manually but the user since DCS does not provide these.
-- * Trains use the available railroad infrastructure and both warehouses must have a connection to the railroad. Unfortunately, however, trains are not yet implemented to 
-- a reasonable degree in DCS at the moment and hence cannot be used yet.
-- 
-- Furthermore, ground assets can be transferred between warehouses by transport units. These are APCs, helicopters and airplanes. The transportation process is modelled
-- in a realistic way by using the corresponding cargo dispatcher classes, i.e. @{AI.AI_Cargo_Dispatcher_APC#AI_DISPATCHER_APC}, 
-- @{AI.AI_Cargo_Dispatcher_Helicopter#AI_DISPATCHER_HELICOPTER} and @{AI.AI_Cargo_Dispatcher_Airplane#AI_DISPATCHER_AIRPLANE}.
-- 
-- # Creating a Warehouse
-- 
-- A MOOSE warehouse must be represented in game by a phyical *static* object. For example, the mission editor already has warehouse as static object available.
-- This would be a good first choice but any static object will do.
-- 
-- The positioning of the warehouse static object is very important for a couple of reasons. Firtly, a warehouse needs a good infrastructure so that spawned assets
-- have a proper road connection or can reach the associated airbase easily.
-- 
-- Once the static warehouse object is placed in the mission editor it can be used as a MOOSE warehouse by the @{#WAREHOUSE.New}(*warehousestatic*, *alias*) constructor,
-- like for example:
-- 
--      warehouse=WAREHOUSE:New(STATIC:FindByName("Warehouse Static Batumi"), "My Warehouse Alias")
--      warehouse:Start()
-- 
-- So the first parameter *warehousestatic* is the static MOOSE object. By default, the name of the warehouse will be the same as the name given to the static object.
-- The second parameter *alias* can be used to choose a more convenient name if desired. This will be the name the warehouse calls itself when reporting messages. 
-- 
-- # Adding Assets
-- 
-- Assets can be added to the warehouse stock by using the @{#WAREHOUSE.AddAsset}(*group*, *ngroups*, *forceattribute*) function. The parameter *group* has to be a MOOSE @{Wrapper.Group#GROUP}.
-- The parameter *ngroups* specifies how many clones of this group are added to the stock.
-- 
-- Note that the group should be a late activated template group, which was defined in the mission editor.
-- 
--      infrantry=GROUP:FindByName("Some Infantry Group")
--      warehouse:AddAsset(infantry, 5)
-- 
-- This will add five infantry groups to the warehouse stock.
-- 
-- Note that you can also add assets with a delay by using the @{#WAREHOUSE.__AddAsset}(*delay*, *group*, *ngroups*, *foceattribute*), where *delay* is the delay in seconds before the asset is added.
-- 
-- By default, the generalized attribute of the asset is determined automatically from the DCS descriptor attributes. However, this might not always result in the desired outcome.
-- Therefore, it is possible, to force a generalized attribute for the asset with the third optional parameter *forceattribute*, which is of type @{#WAREHOUSE.Attribute}. 
--
-- # Requesting Assets
-- 
-- Assets of the warehouse can be requested by other MOOSE warehouses. A request will first be scrutinize to check if can be fullfilled at all. If the request is valid, it is
-- put into the warehouse queue and processed as soon as possible.
-- 
-- A request can be assed by the @{#WAREHOUSE.AddRequest}(*warehouse*, *AssetDescriptor*, *AssetDescriptorValue*, *nAsset*, *TransportType*, *nTransport*, *Prio*) function.
-- The parameters are
-- 
-- * *warehouse*: The requesting MOOSE @{#WAREHOUSE}. Assets will be delivered there.
-- * *AssetDescriptor*: The descriptor to describe the asset "type". See the @{#WAREHOUSE.Descriptor} enumerator. For example, assets requested by their generalized attibute. 
-- * *AssetDescriptorValue*: The value of the asset descriptor.
-- * *nAsset*: (Optional) Number of asset group requested. Default is one group.
-- * *TransportType*: (Optional) The transport method used to deliver the assets to the requestor. Default is that assets go to the requesting warehouse on their own.
-- * *nTransport*: (Optional) Number of asset groups used to transport the cargo assets from A to B. Default is one group.
-- * *Prio*: A number between 1 (high) and 100 (low) describing the priority of the request. Request with high priority are processed first. Default is 50, i.e. medium priority.
-- 
--  So for example:
--  
--       warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.INFANTRY, 5, WAREHOUSE.TransportType.APC, 2, 20)
--
-- Here, warehouse Kobuleti requests 5 infantry groups from warehouse Batumi. These "cargo" assets should be transported from Batumi to Kobuleti by 2 APCS.
-- Note that the warehouse at Batumi needs to have at least five infantry groups and two APC groups in their stock if the request can be processed.
-- If either to few infantry or APC groups are available when the request is made, the request is held in the warehouse queue until enough cargo and
-- transport assets are available.
-- 
-- Also not that the above request is for five infantry units. So any group in stock that has the generalized attribute "INFANTRY" can be selected.
-- 
-- ### Requesting a Specific Unit Type
-- 
-- A more specific request could look like:
-- 
--      warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.UNITTYPE, "A-10C", 2)
--      
-- Here, Kobuleti requests a specific unit type, in particular two groups of A-10Cs. Note that the spelling is important as it must exacly be the same as
-- what one get's when using the DCS unit type.
-- 
-- ### Requesting a Specifc Group
-- 
-- An even more specific request would be:
-- 
--      warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.TEMPLATENAME, "Group Name as in ME", 3)
--      
-- In this case three groups named "Group Name as in ME" are requested. So this explicitly request the groups named like that in the Mission Editor.
-- 
-- ### Requesting a general category
-- 
-- On the other hand, very general unspecifc requests can be made as
-- 
--      warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.CATEGORY, Group.Category.Ground, 10)
--      
-- Here, Kubuleti requests 10 ground groups and does not care which ones. This could be a mix of infantry, APCs, trucks etc.
-- 
-- # Employing Assets
-- 
-- Assets in the warehouse' stock can used for user defined tasks realtively easily. They can be spawned into the game by a "self request", i.e. the warehouse
-- requests the assets from itself:
-- 
--      warehouseBatumi:AddRequest(warehouseBatumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.INFANTRY, 5)
--      
-- This would simply spawn five infantry groups in the spawn zone of the Batumi warehouse if/when they are available.
-- 
-- ## Accessing the Assets
-- 
-- If a warehouse requests assets from itself, it triggers the event **SelfReqeuest**. The mission designer can capture this event with the associated 
-- @{#WAREHOUSE.OnAfterSelfRequest}(*From*, *Event*, *To*, *groupset*, *request*) function.
-- 
--      --- OnAfterSelfRequest user function. Access groups spawned from the warehouse for further tasking.
--      -- @param #WAREHOUSE self
--      -- @param #string From From state.
--      -- @param #string Event Event.
--      -- @param #string To To state.
--      -- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
--      -- @param #WAREHOUSE.Pendingitem request Pending self request.
--      function WAREHOUSE:onafterSelfRequest(From, Event, To, groupset, request)
--       
--        for _,_group in pairs(groupset:GetSetObjects()) do
--          local group=_group --Wrapper.Group#GROUP
--          group:SmokeGreen()
--        end
--        
--      end
--       
-- The variable *groupset* is a @{Core.Set#SET_GOUP} object and holds all asset groups from the request. The code above shows, how the mission designer can access the groups
-- for further tasking. Here, the groups are only smoked but, of course, you can use them for whatever task you imagine.
-- 
-- Note that airborne groups are spawned in uncontrolled state and need to be activated first before they can start their assigned mission.
-- 
-- # Strategic Considerations
-- 
-- Due to the fact that a warehouse holds (or can hold) a lot of valuable assets, it makes a (potentially) juicy target for enemy attacks.
-- There are several interesting situations, which can occurr.
-- 
-- ## Capturing a Warehouse' Airbase
-- 
-- If a warehouse has an associated airbase, it can be captured by the enemy. In this case, the warehouse looses it ability so employ all airborne assets and is also cut-off
-- from supply by airborne units.
-- 
-- Technically, the capturing of the airbase is triggered by the DCS S_EVENT_CAPTURE_BASE event. So the capturing takes place when only enemy ground units are in the 
-- airbase zone whilst no ground units of the present airbase owner are in that zone.
-- 
-- The warehouse will also create an event named "AirbaseCaptured", which can be captured by the @{#WAREHOUSE.OnAfterAirbaseCaptured} function. So the warehouse can react on
-- this attack and for example spawn ground groups to re-capture its airbase.
-- 
-- When an airbase is re-captured the event "AirbaseRecaptured" is triggered and can be captured by the @{#WAREHOUSE.OnAfterAirbaseRecaptured} function.
-- This can be used to put the defending assets back into the warehouse stock.
-- 
-- ## Capturing the Warehouse
-- 
-- A warehouse can also be captured by the enemy coalition. If enemy ground troops enter the warehouse zone the event **Attacked** is triggered which can be captured by the
-- @{#WAREHOUSE.OnAfterAttacked} event.
-- 
-- If a warehouse is attacked it will spawn all its ground assets in the spawn zone which can than be used to defend the warehouse zone.
-- 
-- If only ground troops of the enemy coalition are present in the warehouse zone, the warehouse and all its assets falls into the hands of the enemy.
-- In this case the event **Captured** is triggered which can be captured by the @{#WAREHOUSE.OnAfterCaptured} function.
-- 
-- The warehouse turn to the capturing coalition, i.e. its physical representation, and all assets as well. In paticular, all requests to the warehouse will
-- spawn assets beloning to the new owner.
-- 
-- ## Destroying a Warehouse
-- 
-- If an enemy destroy the physical warehouse structure, the warehouse will of course stop all its services. In priciple, all assets contained in the warehouse are
-- gone as well. So a warehouse should be properly defended.
-- 
-- Upon destruction of the warehouse, the event **Destroyed** is triggered, which can be captured by the @{#WAREHOUSE.OnAfterDestroyed} function.
-- So the mission designer can intervene at this point and for example choose to spawn all or paricular types of assets before the warehouse is gone for good.
--
-- ===
--
-- # Examples
--
-- **WIP**
--
--
-- @field #WAREHOUSE
WAREHOUSE = {
  ClassName   = "WAREHOUSE",
  Debug       = false,
  Report      =  true,
  warehouse   =   nil,
  coalition   =   nil,
  country     =   nil,
  alias       =   nil,
  zone        =   nil,
  airbase     =   nil,
  airbasename =   nil,
  category    =    -1,
  coordinate  =   nil,
  road        =   nil,
  rail        =   nil,
  spawnzone   =   nil,
  wid         =   nil,
  uid         =   nil,
  markerid    =   nil,
  dTstatus    =    30,
  queueid     =     0,
  stock       =    {},
  queue       =    {},
  pending     =    {},
  defending   =    {},
}

--- Item of the warehouse stock table.
-- @type WAREHOUSE.Assetitem
-- @field #number uid Unique id of the asset.
-- @field #string templatename Name of the template group.
-- @field #table template The spawn template of the group.
-- @field DCS#Group.Category category Category of the group.
-- @field #string unittype Type of the first unit of the group as obtained by the Object.getTypeName() DCS API function.
-- @field #number nunits Number of units in the group.
-- @field #number range Range of the unit in meters.
-- @field #number size Maximum size in length and with of the asset in meters.
-- @field #number speedmax Maximum speed in km/h the unit can do.
-- @field DCS#Object.Desc DCSdesc All DCS descriptors.
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
-- @field #table assets Table of assets - cargo or transport. Each element of the table is a @{#WAREHOUSE.Assetitem}.
-- @field Core.Set#SET_GROUP cargogroupset Set of cargo groups do be delivered.
-- @field #number ndelivered Number of groups delivered to destination.
-- @field #number cargoattribute Attribute of cargo assets of type @{#WAREHOUSE.Attribute}.
-- @field #number cargocategory Category of cargo assets of type @{#WAREHOUSE.Category}.
-- @field Core.Set#SET_GROUP transportgroupset Set of cargo transport groups.
-- @field #number transportattribute Attribute of transport assets of type @{#WAREHOUSE.Attribute}.
-- @field #number transportcategory Category of transport assets of type @{#WAREHOUSE.Category}.
-- @field #number ntransporthome Number of transports back home. transportattribute

--- Descriptors enumerator describing the type of the asset.
-- @type WAREHOUSE.Descriptor
-- @field #string TEMPLATENAME Name of the asset template.
-- @field #string UNITTYPE Typename of the DCS unit, e.g. "A-10C".
-- @field #string ATTRIBUTE Generalized attribute @{#WAREHOUSE.Attribute}.
-- @field #string CATEGORY Asset category of type DCS#Group.Category, i.e. GROUND, AIRPLANE, HELICOPTER, SHIP, TRAIN.
WAREHOUSE.Descriptor = {
  TEMPLATENAME="templatename",
  UNITTYPE="unittype",
  ATTRIBUTE="attribute",
  CATEGORY="category",
}

--- Generalized asset attributes. Can be used to request assets with certain general characteristics.
-- @type WAREHOUSE.Attribute
-- @field #string TRANSPORT_PLANE Airplane with transport capability. Usually bigger, i.e. needs larger airbases and parking spots.
-- @field #string TRANSPORT_HELO Helicopter with transport capability.
-- @field #string TRANSPORT_APC Amoured Personell Carrier.
-- @field #string FIGHER Fighter, interceptor, ... airplane.
-- @field #string TANKER Airplane which can refuel other aircraft.
-- @field #string AWACS Airborne Early Warning and Control System.
-- @field #string ARTILLERY Artillery assets.
-- @field #string INFANTRY Ground infantry assets.
-- @field #string BOMBER Aircraft which can be used for bombing.
-- @field #string TANK Tanks.
-- @field #string TRUCK Unarmed ground vehicles.
-- @field #string TRAIN Trains.
-- @field #string SHIP Naval assets.
-- @field #string OTHER Anything that does not fall into any other category.
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

--- Cargo transport type. Defines how assets are transported to their destination.
-- @type WAREHOUSE.TransportType
-- @field #string AIRPLANE Transports are conducted by airplanes.
-- @field #string HELICOPTER Transports are conducted by helicopters.
-- @field #string APC Transports are conducted by APCs.
-- @field #string SHIP Transports are conducted by ships.
-- @field #string TRAIN Transports are conducted by trains.
-- @field #string SELFPROPELLED Assets go to their destination by themselves. No transport carrier needed.
WAREHOUSE.TransportType = {
  AIRPLANE      = "Transport_Plane",
  HELICOPTER    = "Transport_Helo",
  APC           = "Transport_APC",
  SHIP          = "Ship",
  TRAIN         = "Train",
  SELFPROPELLED = "Selfpropelled",
}

--- Warehouse database. Note that this is a global array to have easier exchange between warehouses.
-- @type WAREHOUSE.db
-- @field #number AssetID Unique ID of each asset. This is a running number, which is increased each time a new asset is added.
-- @field #table Assets Table holding registered assets, which are of type @{Functional.Warehouse#WAREHOUSE.Assetitem}.
WAREHOUSE.db = {
  AssetID = 0,
  Assets  = {},
}

--- Warehouse class version.
-- @field #string version
WAREHOUSE.version="0.2.7"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: Warehouse todo list.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add transport units from dispatchers back to warehouse stock once they completed their mission.
-- TODO: Add harbours and ports.
-- TODO: Add shipping lanes between warehouses.
-- TODO: Set ROE for spawned groups.
-- TODO: Add possibility to add active groups. Need to create a pseudo template before destroy.
-- TODO: Write documentation.
-- TODO: Handle the case when units of a group die during the transfer. Adjust template?! See Grouping in SPAWN.
-- TODO: Handle cases with immobile units.
-- TODO: Handle cargo crates.
-- TODO: Handle cases for aircraft carriers and other ships. Place warehouse on carrier possible? On others probably not - exclude them?
-- TODO: Add general message function for sending to coaliton or debug.
-- TODO: Fine tune event handlers.
-- TODO: Add save/load capability of warehouse <==> percistance after mission restart.
-- TODO: Improve generalized attributes.
-- TODO: Add a time stamp when an asset is added to the stock and for requests
-- DONE: If warehouse is destoyed, all asssets are gone.
-- DONE: Add event handlers.
-- DONE: Add AI_CARGO_AIRPLANE
-- DONE: Add AI_CARGO_APC
-- DONE: Add AI_CARGO_HELICOPTER
-- DONE: Switch to AI_CARGO_XXX_DISPATCHER
-- DONE: Add queue.
-- DONE: Put active groups into the warehouse, e.g. when they were transported to this warehouse.
-- NOGO: Spawn warehouse assets as uncontrolled or AI off and activate them when requested.
-- DONE: How to handle multiple units in a transport group? <== Cargo dispatchers.
-- DONE: Add phyical object.
-- DONE: If warehosue is captured, change warehouse and assets to other coalition.
-- NOGO: Use RAT for routing air units. Should be possible but might need some modifications of RAT, e.g. explit spawn place. But flight plan should be better.
-- DONE: Can I make a request with specific assets? E.g., once delivered, make a request for exactly those assests that were in the original request.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- The WAREHOUSE constructor. Creates a new WAREHOUSE object from a static object. Parameters like the coalition and country are taken from the static object structure.
-- @param #WAREHOUSE self
-- @param Wrapper.Static#STATIC warehouse The physical structure of the warehouse.
-- @param #string alias (Optional) Alias of the warehouse, i.e. the name it will be called when sending messages etc. Default is the name of the static  
-- @return #WAREHOUSE self
function WAREHOUSE:New(warehouse, alias)
  BASE:E({warehouse=warehouse:GetName()})
  
  -- Nil check.
  if warehouse==nil then
    BASE:E("ERROR: Warehouse does not exist!")
    return nil
  end
  
  -- Set alias.
  self.alias=alias or warehouse:GetName()

  -- Print version.
  env.info(string.format("Adding warehouse v%s for structure %s with alias %s", WAREHOUSE.version, warehouse:GetName(), self.alias))

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #WAREHOUSE

  -- Set some string id for output to DCS.log file.
  self.wid=string.format("WAREHOUSE %s | ", self.alias)

  -- Set some variables.
  self.warehouse=warehouse
  self.uid=tonumber(warehouse:GetID())
  self.coalition=warehouse:GetCoalition()
  self.country=warehouse:GetCountry()
  self.coordinate=warehouse:GetCoordinate()

  -- Closest of the same coalition but within a certain range.
  local _airbase=self.coordinate:GetClosestAirbase(nil, self.coalition)
  if _airbase and _airbase:GetCoordinate():Get2DDistance(self.coordinate) < 3000 then
    self.airbase=_airbase
    self.airbasename=self.airbase:GetName()
    self.category=self.airbase:GetDesc().category
  end
      
  -- Define warehouse and default spawn zone.
  self.zone=ZONE_RADIUS:New(string.format("Warehouse zone %s", self.warehouse:GetName()), warehouse:GetVec2(), 500)
  self.spawnzone=ZONE_RADIUS:New(string.format("Warehouse %s spawn zone", self.warehouse:GetName()), warehouse:GetVec2(), 200)
  
  -- Start State.
  self:SetStartState("NotReadyYet")

  -- Add FSM transitions.
  --                 From State   -->   Event        -->     To State
  self:AddTransition("NotReadyYet",     "Load",              "NotReadyYet") -- TODO Load the warehouse state. No sure if it should be in stopped state.
  self:AddTransition("NotReadyYet",     "Start",             "Running")     -- Start the warehouse.
  self:AddTransition("*",               "Status",            "*")           -- Status update.
  self:AddTransition("*",               "AddAsset",          "*")           -- Add asset to warehouse stock.
  self:AddTransition("*",               "AddRequest",        "*")           -- New request from other warehouse.
  self:AddTransition("Running",         "Request",           "*")           -- Process a request. Only in running mode.
  self:AddTransition("Attacked",        "Request",           "*")           -- Process a request. Only in running mode.
  self:AddTransition("*",               "Unloaded",          "*")           -- Cargo has been unloaded from the carrier.
  self:AddTransition("*",               "Arrived",           "*")           -- Cargo or transport group has arrived.
  self:AddTransition("*",               "Delivered",         "*")           -- All cargo groups of a request have been delivered to the requesting warehouse.
  self:AddTransition("Running",         "SelfRequest",       "*")           -- Request to warehouse itself. Requested assets are only spawned but not delivered anywhere.
  self:AddTransition("Attacked",        "SelfRequest",       "*")           -- Request to warehouse itself. Also possible when warehouse is under attack!
  self:AddTransition("Running",         "Pause",             "Paused")      -- TODO Pause the processing of new requests. Still possible to add assets and requests. 
  self:AddTransition("Paused",          "Unpause",           "Running")     -- TODO Unpause the warehouse. Queued requests are processed again. 
  self:AddTransition("*",               "Stop",              "Stopped")     -- TODO Stop the warehouse.
  self:AddTransition("*",               "Save",              "*")           -- TODO Save the warehouse state to disk.
  self:AddTransition("*",               "Attacked",          "Attacked")    -- TODO Warehouse is under attack by enemy coalition.
  self:AddTransition("Attacked",        "Defeated",          "Running")     -- TODO Attack by other coalition was defeated!
  self:AddTransition("Attacked",        "Captured",          "Running")     -- TODO Warehouse was captured by another coalition. It must have been attacked first.
  self:AddTransition("*",               "AirbaseCaptured",   "*")           -- TODO Airbase was captured by other coalition.
  self:AddTransition("*",               "AirbaseRecaptured", "*")           -- TODO Airbase was re-captured from other coalition. 
  self:AddTransition("*",               "Destroyed",         "*")           -- TODO Warehouse was destoryed. All assets in stock are gone and warehouse is stopped.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
  --- Triggers the FSM event "Start". Starts the warehouse. Initializes parameters and starts event handlers.
  -- @function [parent=#WAREHOUSE] Start
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Start" after a delay. Starts the warehouse. Initializes parameters and starts event handlers.
  -- @function [parent=#WAREHOUSE] __Start
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the warehouse and all its event handlers.
  -- @function [parent=#WAREHOUSE] Stop
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Stop" after a delay. Stops the warehouse and all its event handlers.
  -- @function [parent=#WAREHOUSE] __Stop
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Pause". Pauses the warehouse. Assets can still be added and requests be made. However, requests are not processed.
  -- @function [parent=#WAREHOUSE] Pauses
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Pause" after a delay. Pauses the warehouse. Assets can still be added and requests be made. However, requests are not processed.
  -- @function [parent=#WAREHOUSE] __Pause
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Unpause". Unpauses the warehouse. Processing of queued requests is resumed.
  -- @function [parent=#WAREHOUSE] UnPause
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Unpause" after a delay. Unpauses the warehouse. Processing of queued requests is resumed.
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
  -- @param Wrapper.Group#GROUP group Group to be added as new asset.
  -- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
  -- @param #WAREHOUSE.Attribute forceattribute (Optional) Explicitly force a generalized attribute for the asset. This has to be an @{#WAREHOUSE.Attribute}.

  --- Trigger the FSM event "AddAsset" with a delay. Add an airplane group to the warehouse stock.
  -- @function [parent=#WAREHOUSE] __AddAsset
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Group#GROUP group Group to be added as new asset.
  -- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
  -- @param #WAREHOUSE.Attribute forceattribute (Optional) Explicitly force a generalized attribute for the asset. This has to be an @{#WAREHOUSE.Attribute}.


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
  -- @param #WAREHOUSE.Pendingitem request Pending request that was now delivered.

  --- Triggers the FSM event "Delivered" after a delay. A group has been delivered from the warehouse to another airbase or warehouse.
  -- @function [parent=#WAREHOUSE] __Delivered
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE.Pendingitem request Pending request that was now delivered.


  --- Triggers the FSM event "SelfRequest". Request was initiated to the warehouse itself. Groups are just spawned at the warehouse or the associated airbase.
  -- If the warehouse is currently under attack when the self request is made, the self request is added to the defending table. One the attack is defeated,
  -- this request is used to put the groups back into the warehouse stock.
  -- @function [parent=#WAREHOUSE] SelfRequest
  -- @param #WAREHOUSE self
  -- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
  -- @param #WAREHOUSE.Pendingitem request Pending self request.

  --- Triggers the FSM event "SelfRequest" with a delay. Request was initiated to the warehouse itself. Groups are just spawned at the warehouse or the associated airbase.
  -- If the warehouse is currently under attack when the self request is made, the self request is added to the defending table. One the attack is defeated,
  -- this request is used to put the groups back into the warehouse stock.
  -- @function [parent=#WAREHOUSE] __SelfRequest
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
  -- @param #WAREHOUSE.Pendingitem request Pending self request.

  --- On after "SelfRequest" event. Request was initiated to the warehouse itself. Groups are just spawned at the warehouse or the associated airbase.
  -- @function [parent=#WAREHOUSE] OnAfterSelfRequest
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Set#SET_GROUP groupset The set of (cargo) groups that was delivered to the warehouse itself.
  -- @param #WAREHOUSE.Pendingitem request Pending self request.


  --- Triggers the FSM event "Attacked" when a warehouse is under attack by an another coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] Attacked
  -- @param DCS#coalition.side Coalition which is attacking the warehouse.
  -- @param DCS#country.id Country which is attacking the warehouse.

  --- Triggers the FSM event "Attacked" with a delay when a warehouse is under attack by an another coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] __Attacked
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition which is attacking the warehouse.
  -- @param DCS#country.id Country which is attacking the warehouse.


  --- Triggers the FSM event "Defeated" when an attack from an enemy was defeated.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] Defeated
  -- @param DCS#coalition.side Coalition which is attacking the warehouse.
  -- @param DCS#country.id Country which is attacking the warehouse.

  --- Triggers the FSM event "Defeated" with a delay when an attack from an enemy was defeated.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] __Defeated
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition which is attacking the warehouse.
  -- @param DCS#country.id Country which is attacking the warehouse.


  --- Triggers the FSM event "Captured" when a warehouse has been captured by another coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] Captured
  -- @param DCS#coalition.side Coalition which captured the warehouse.
  -- @param DCS#country.id Country which has captured the warehouse.
  
  --- Triggers the FSM event "Captured" with a delay when a warehouse has been captured by another coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] __Captured
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition which captured the warehouse.
  -- @param DCS#country.id Country which has captured the warehouse.


  --- Triggers the FSM event "AirbaseCaptured" when the airbase of the warehouse has been captured by another coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] AirbaseCaptured
  -- @param DCS#coalition.side Coalition which captured the airbase.
  
  --- Triggers the FSM event "AirbaseCaptured" with a delay when the airbase of the warehouse has been captured by another coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] __AirbaseCaptured
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition which captured the airbase.


  --- Triggers the FSM event "AirbaseRecaptured" when the airbase of the warehouse has been re-captured from the other coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] AirbaseRecaptured
  -- @param DCS#coalition.side Coalition which re-captured the airbase.
  
  --- Triggers the FSM event "AirbaseRecaptured" with a delay when the airbase of the warehouse has been re-captured from the other coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] __AirbaseRecaptured
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition which re-captured the airbase.


  --- Triggers the FSM event "Destroyed" when the warehouse was destroyed. All services are stopped.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] Destroyed
  
  --- Triggers the FSM event "Destroyed" with a delay when the warehouse was destroyed. All services are stopped.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] Destroyed
  -- @param #number delay Delay in seconds.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set interval of status updates
-- @param #WAREHOUSE self
-- @param #number timeinterval Time interval in seconds.
-- @return #WAREHOUSE self
function WAREHOUSE:SetStatusUpdate(timeinterval)
  self.dTstatus=timeinterval
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

--- Set a warehouse zone. If this zone is captured, the warehouse and all its assets fall into the hands of the enemy.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The warehouse zone. Note that this **cannot** be a polygon zone!
-- @return #WAREHOUSE self
function WAREHOUSE:SetWarehouseZone(zone)
  self.zone=zone
  return self
end

--- Set the airbase belonging to this warehouse.
-- Note that it has to be of the same coalition as the warehouse.
-- Also, be reasonable and do not put it too far from the phyiscal warehouse structure because you troops might have a long way to get to their transports.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase object associated to this warehouse.
-- @return #WAREHOUSE self
function WAREHOUSE:SetAirbase(airbase)
  self.airbase=airbase
  return self
end

--- Set the connection of the warehouse to the road.
-- Ground assets spawned in the warehouse spawn zone will first go to this point and from there travel on road to the requesting warehouse.
-- Note that by default the road connection is set to the closest point on road from the center of the spawn zone if it is withing 3000 meters.
-- Also note, that if the parameter "coordinate" is passed as nil, any road connection is disabled and ground assets cannot travel of be transportet on the ground.  
-- @param #WAREHOUSE self
-- @param Core.Point#COORDINATE coordinate The road connection. Technically, the closest point on road from this coordinate is determined by DCS API function. So this point must not be exactly on the road.
-- @return #WAREHOUSE self
function WAREHOUSE:SetRoadConnection(coordinate)
  if coordinate then
    self.road=coordinate:GetClosestPointToRoad()
  else
    self.road=false
  end
  return self
end

--- Set the connection of the warehouse to the railroad.
-- This is the place where train assets or transports will be spawned.
-- @param #WAREHOUSE self
-- @param Core.Point#COORDINATE coordinate The railroad connection. Technically, the closest point on rails from this coordinate is determined by DCS API function. So this point must not be exactly on the a railroad connection.
-- @return #WAREHOUSE self
function WAREHOUSE:SetRailConnection(coordinate)
  if coordinate then
    self.rail=coordinate:GetClosestPointToRoad(true)
  else
    self.rail=false
  end
  return self
end

--- Check if the warehouse is running.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse is running and requests are processed.
function WAREHOUSE:IsRunning()
  return self:is("Running")
end

--- Check if the warehouse is paused. In this state, requests are not processed.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse is paused.
function WAREHOUSE:IsPaused()
  return self:is("Paused")
end

--- Check if the warehouse is under attack by another coalition.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse is attacked.
function WAREHOUSE:IsAttacked()
  return self:is("Attacked")
end

--- Check if the warehouse is stopped.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse is stopped.
function WAREHOUSE:IsStopped()
  return self:is("Stopped")
end

--- Check if the warehouse has a road connection to another warehouse. Both warehouses need to be started!
-- @param #WAREHOUSE self
-- @param #WAREHOUSE warehouse The remote warehose to where the connection is checked.
-- @param #boolean markpath If true, place markers of path segments on the F10 map.
-- @param #boolean smokepath If true, put green smoke on path segments.
-- @return #boolean If true, the two warehouses are connected by road.
-- @return #number Path length in meters. Negative distance -1 meter indicates no connection.
function WAREHOUSE:HasConnectionRoad(warehouse, markpath, smokepath)
  if warehouse then
    if self.road and warehouse.road then
      local _,length,gotpath=self.road:GetPathOnRoad(warehouse.road, false, false, markpath, smokepath)
      return gotpath, length or -1
    else
      -- At least one of the warehouses has no road connection.
      return false, -1
    end
  end
  return nil, -1
end

--- Check if the warehouse has a railroad connection to another warehouse. Both warehouses need to be started!
-- @param #WAREHOUSE self
-- @param #WAREHOUSE warehouse The remote warehose to where the connection is checked.
-- @param #boolean markpath If true, place markers of path segments on the F10 map.
-- @param #boolean smokepath If true, put green smoke on path segments.
-- @return #boolean If true, the two warehouses are connected by road.
-- @return #number Path length in meters. Negative distance -1 meter indicates no connection.
function WAREHOUSE:HasConnectionRail(warehouse, markpath, smokepath)
  if warehouse then
    if self.rail and warehouse.rail then
      local _,length,gotpath=self.road:GetPathOnRoad(warehouse.road, false, true, markpath, smokepath)
      return gotpath, length or -1
    else
      -- At least one of the warehouses has no rail connection.
      return false, -1
    end
  end
  return nil, -1
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
  local text=string.format("Starting warehouse %s alias %s:\n",self.warehouse:GetName(), self.alias)
  text=text..string.format("Coaliton = %d\n", self.coalition)
  text=text..string.format("Country  = %d\n", self.country)
  text=text..string.format("Airbase  = %s (%s)\n", tostring(self.airbase:GetName()), tostring(self.category))
  env.info(text)

  -- Save self in static object. Easier to retrieve later.
  self.warehouse:SetState(self.warehouse, "WAREHOUSE", self)
 
  -- Set airbase name and category.
  if self.airbase and self.airbase:GetCoalition()==self.coalition then
    self.airbasename=self.airbase:GetName()
    self.category=self.airbase:GetDesc().category
  else
    self.airbasename=nil
    self.category=-1  -- The -1 indicates that we dont have an airbase at this warehouse.
  end

  -- THIS! caused aircraft to be spawned and started but they would never begin their route!
  -- VERY strange. Need to test more.
  --[[  
  -- Debug mark warehouse & spawn zone.
  self.zone:BoundZone(30, self.country)
  self.spawnzone:BoundZone(30, self.country)
  ]]
  
  -- Get the closest point on road wrt spawnzone of ground assets.
  local _road=self.spawnzone:GetCoordinate():GetClosestPointToRoad()
  if _road and self.road==nil then  
    -- Set connection to road if distance is less than 3 km.
    local _Droad=_road:Get2DDistance(self.spawnzone:GetCoordinate())      
    if _Droad < 3000 then
      self.road=_road
    end
  end
  -- Mark point at road connection.
  if self.road then
    self.road:MarkToAll(string.format("%s road connection.", self.alias), true)
  end
  
  -- Get the closest point on railroad wrt spawnzone of ground assets.
  local _rail=self.spawnzone:GetCoordinate():GetClosestPointToRoad(true)
  if _rail and self.rail==nil then
    -- Set rail conection if it is less than 3 km away. 
    local _Drail=_rail:Get2DDistance(self.spawnzone:GetCoordinate())
    if _Drail < 3000 then
      self.rail=_rail
    end
  end
  -- Mark point at rail connection.
  if self.rail then
    self.rail:MarkToAll(string.format("%s rail connection.", self.alias), true)
  end 

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self._OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self._OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self._OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self._OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEventEngineShutdown)
  self:HandleEvent(EVENTS.Crash,          self._OnEventCrashOrDead)
  self:HandleEvent(EVENTS.Dead,           self._OnEventCrashOrDead)
  self:HandleEvent(EVENTS.BaseCaptured,   self._OnEventBaseCaptured)
  
  -- This event triggers the arrived event for air assets.
  -- TODO Might need to make this landing or optional!
  -- In fact, it would be better if the type could be defined for only for the warehouse which receives stuff,
  -- since there will be warehouses with small airbases and little space or other problems!
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEventArrived)
  
  -- Start the status monitoring.
  self:__Status(1)

end

--- On after "Stop" event. Stops the warehouse, unhandles all events.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStop(From, Event, To)
  self:E(self.wid..string.format("Warehouse stopped!"))
  
  -- Unhandle event.
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.EngineStartup)
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.BaseCaptured)
  
  -- Clear all pending schedules.
  self.CallScheduler:Clear()  
end

--- On after "Pause" event. Pauses the warehouse, i.e. no requests are processed. However, new requests and new assets can be added in this state.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterPause(From, Event, To)
  self:E(self.wid..string.format("Warehouse %s paused! Queued requests are not processed in this state.", self.alias))
end

--- On after "Unpause" event. Unpauses the warehouse, i.e. requests in queue are processed again.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterUnpause(From, Event, To)
  self:E(self.wid..string.format("Warehouse %s unpaused! Processing of requests is resumed.", self.alias))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Status event. Checks the queue and handles requests.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStatus(From, Event, To)
  self:E(self.wid..string.format("Checking status of warehouse %s. Current FSM state %s. Global warehouse assets = %d.", self.alias, self:GetState(), #WAREHOUSE.db.Assets))
  
  -- Print status.
  self:_DisplayStatus()
    
  -- Check if warehouse is being attacked or has even been captured.
  self:_CheckConquered()

  -- Print queue.
  self:_PrintQueue(self.queue, "Queue waiting - before request")
  self:_PrintQueue(self.pending, "Queue pending - before request")
  
  -- Check if requests are valid and remove invalid one.
  self:_CheckRequestConsistancy(self.queue)
    
  -- If warehouse is running than requests can be processed.
  if self:IsRunning() or self:IsAttacked() then
  
    -- Check queue and handle requests if possible.
    local request=self:_CheckQueue()

    -- Execute the request. If the request is really executed, it is also deleted from the queue.
    if request then
      self:Request(request)
    end
    
    -- Print queue after processing requests.
    self:_PrintQueue(self.queue, "Queue waiting - after  request")
    self:_PrintQueue(self.pending, "Queue pending - after  request")
    
  end

  -- Update warhouse marker on F10 map.
  self:_UpdateWarehouseMarkText()
  
  -- Display complete list of stock itmes.
  if self.Debug then
  --self:_DisplayStockItems(self.stock)
  end  

  -- Call status again in ~30 sec (user choice).
  self:__Status(self.dTstatus)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "AddAsset" event. Add a group to the warehouse stock. If the group is alive, it is destroyed.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group Group or template group to be added to the warehouse stock.
-- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
-- @param #WAREHOUSE.Attribute forceattribute (Optional) Explicitly force a generalized attribute for the asset. This has to be an @{#WAREHOUSE.Attribute}.
function WAREHOUSE:onafterAddAsset(From, Event, To, group, ngroups, forceattribute)

  -- Set default.
  local n=ngroups or 1
  
  -- Handle case where just a string is passed.
  if type(group)=="string" then
    group=GROUP:FindByName(group)
  end
  
  self:E(string.format("Adding %d assets of group %s.", n, group:GetName()))
  
  if group then
    
    -- Get unique ids from group name.
    local wid,aid,rid=self:_GetIDsFromGroup(group)
  
    -- Check if this is an known or a new asset group.
    if aid~=nil and wid~=nil then
    
      -- We got a warehouse and asset id ==> this is an "old" group.
      local asset=self:_FindAssetInDB(group)
      
      -- Note the group is only added once, i.e. the ngroups parameter is ignored here.
      -- This is because usually these request comes from an asset that has been transfered from another warehouse and hence should only be added once.
      if asset~=nil then
        self:E(string.format("Adding new asset with id = %d, attribute = %s to warehouse stock.", asset.uid, asset.attribute))
        table.insert(self.stock, asset)
      else
        env.error("ERROR known asset could not be found in global warehouse db!")
      end
      
    else
    
      -- This is a group that is not in the db yet. Add it n times.
      local assets=self:_RegisterAsset(group, n, forceattribute)
      
      -- Add created assets to stock of this warehouse.
      for _,asset in pairs(assets) do
        table.insert(self.stock, asset)
      end
    end
    
    -- Destroy group if it is alive.
    -- TODO: This causes a problem, when a completely new asset is added, i.e. not from a template group.
    -- Need to create a "zombie" template group maybe?
    if group:IsAlive()==true then
      self:E(self.wid..string.format("Destroying group %s.", group:GetName()))
      group:Destroy()
    end
    
  end
  
end

--- Find an asset in the the global warehouse db.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which it is assumed that it has a registered asset.
-- @return #WAREHOUSE.Assetitem The asset from the data base or nil if it could not be found.
function WAREHOUSE:_FindAssetInDB(group)

  -- Get unique ids from group name.
  local wid,aid,rid=self:_GetIDsFromGroup(group)
  
  if aid~=nil then
  
    local asset=WAREHOUSE.db.Assets[aid]
    self:E({asset=asset})
    if asset==nil then
      self:E(string.format("ERROR: Asset for group %s not found in the data base!", group:GetName()))
    end
    return asset
  end
  
  self:E(string.format("ERROR: Group %s does not contain an asset ID in its name!", group:GetName()))
  return nil  
end

--- Register new asset in globase warehouse data base.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that will be added to the warehouse stock.
-- @param #number ngroups Number of groups to be added.
-- @param #string forceattribute Forced generalized attribute.
-- @return #table A table containing all registered assets.
function WAREHOUSE:_RegisterAsset(group, ngroups, forceattribute)

  -- Set default.
  local n=ngroups or 1
  
  -- Get the size of an object.
  local function _GetObjectSize(DCSdesc)
    if DCSdesc.box then
      local x=DCSdesc.box.max.x+math.abs(DCSdesc.box.min.x)  --length
      local y=DCSdesc.box.max.y+math.abs(DCSdesc.box.min.y)  --height
      local z=DCSdesc.box.max.z+math.abs(DCSdesc.box.min.z)  --width
      return math.max(x,z), x , y, z
    end
    return 0,0,0,0
  end  
  
  local templategroupname=group:GetName()

  local DCSgroup=group:GetDCSObject()
    
  local DCSunit=DCSgroup:getUnit(1)
  local DCSdesc=DCSunit:getDesc()
  local DCSdisplay=DCSdesc.displayName
  local DCScategory=DCSgroup:getCategory()
  local DCStype=DCSunit:getTypeName()
  local SpeedMax=group:GetSpeedMax()
  local RangeMin=group:GetRange()
  local smax,sx,sy,sz=_GetObjectSize(DCSdesc)

  -- Set/get the generalized attribute.
  local attribute=forceattribute or self:_GetAttribute(templategroupname)

  -- Table for returned assets.
  local assets={}

  -- Add this n times to the table.
  for i=1,n do
    local asset={} --#WAREHOUSE.Assetitem
    
    -- Increase asset unique id counter.
    WAREHOUSE.db.AssetID=WAREHOUSE.db.AssetID+1
    
    -- Set parameters.
    asset.uid=WAREHOUSE.db.AssetID
    asset.templatename=templategroupname
    asset.template=UTILS.DeepCopy(_DATABASE.Templates.Groups[templategroupname].Template)
    asset.category=DCScategory
    asset.unittype=DCStype
    asset.nunits=#asset.template.units
    asset.attribute=attribute
    asset.range=RangeMin
    asset.speedmax=SpeedMax
    asset.size=smax
    asset.DCSdesc=DCSdesc
    
    if i==1 then
      self:_AssetItemInfo(asset)
    end
    
    -- Add asset to global db.
    WAREHOUSE.db.Assets[asset.uid]=asset
    
    -- Add asset to the table that is retured.
    table.insert(assets,asset)
  end

  return assets
end

--- Asset item characteristics.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset
function WAREHOUSE:_AssetItemInfo(asset)
  -- Info about asset:
  local text=string.format("\nNew asset with id=%d for warehouse %s:\n", asset.uid, self.alias)
  text=text..string.format("Template name = %s\n", asset.templatename)
  text=text..string.format("Unit type     = %s\n", asset.unittype)
  text=text..string.format("Attribute     = %s\n", asset.attribute)
  text=text..string.format("Category      = %d\n", asset.category)
  text=text..string.format("Units #       = %d\n", asset.nunits)
  text=text..string.format("Size  max     = %5.2f m\n", asset.size)
  text=text..string.format("Speed max     = %5.2f km/h\n", asset.speedmax)
  text=text..string.format("Range max     = %5.2f km\n", asset.range/1000)
  self:E(self.wid..text)
  self:E({DCSdesc=asset.DCSdesc})
  self:E({Template=asset.template})
end

--- On after "AddAsset" event. Add a group to the warehouse stock. If the group is alive, it is destroyed.
-- @param #WAREHOUSE self
-- @param #string templategroupname Name of the late activated template group as defined in the mission editor.
-- @param #number ngroups Number of groups to add to the warehouse stock. Default is 1.
function WAREHOUSE:_AddAssetFromZombie(group, ngroups)

end


--- Spawn a ground asset in the spawnzone of the warehouse.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset Ground asset that will be spawned.
-- @param #WAREHOUSE.Queueitem request Request belonging to this asset. Needed for the name/alias.
-- @param boolean aioff If true, AI of ground units are set to off.
-- @return Wrapper.Group#GROUP The spawned group or nil if the group could not be spawned.
function WAREHOUSE:_SpawnAssetGround(asset, request, aioff)

  if asset and asset.category==Group.Category.GROUND then
  
    -- Prepare spawn template.
    local template=self:_SpawnAssetPrepareTemplate(asset, request)  
 
    -- Initial spawn point.
    template.route.points[1]={} 
    
    -- Get a random coordinate in the spawn zone.
    local coord=self.spawnzone:GetRandomCoordinate()

    -- Translate the position of the units.
    for i=1,#template.units do
      
      -- Unit template.
      local unit = template.units[i]
      
      -- Translate position.
      local SX = unit.x or 0
      local SY = unit.y or 0
      local BX = asset.template.route.points[1].x
      local BY = asset.template.route.points[1].y
      local TX = coord.x + (SX-BX)
      local TY = coord.z + (SY-BY)
      
      template.units[i].x = TX
      template.units[i].y = TY
             
    end
    
    template.route.points[1].x = coord.x
    template.route.points[1].y = coord.z
    
    template.x   = coord.x
    template.y   = coord.z
    template.alt = coord.y    
  
    -- Spawn group.
    local group=_DATABASE:Spawn(template) --Wrapper.Group#GROUP
    
    -- Activate group. Should only be necessary for late activated groups.
    --group:Activate()
    
    -- Switch AI off if desired. This works only for ground and naval groups.
    if aioff then
      group:SetAIOff()
    end
    
    return group
  end
    
  return nil
end

--- Spawn an aircraft asset (plane or helo) at the airbase associated with the warehouse.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset Ground asset that will be spawned.
-- @param #WAREHOUSE.Queueitem request Request belonging to this asset. Needed for the name/alias.
-- @param #table parking Parking data for this asset.
-- @param #boolean uncontrolled Spawn aircraft in uncontrolled state.
-- @return Wrapper.Group#GROUP The spawned group or nil if the group could not be spawned.
function WAREHOUSE:_SpawnAssetAircraft(asset, request, parking, uncontrolled)

  if asset and asset.category==Group.Category.AIRPLANE or asset.category==Group.Category.HELICOPTER then
  
    -- Prepare the spawn template.
    local template=self:_SpawnAssetPrepareTemplate(asset, request)
    
    -- Set route points.
    if request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
    
      -- Get flight path if the group goes to another warehouse by itself.
      template.route.points=self:_GetFlightplan(asset, self.airbase, request.warehouse.airbase)
      
    else
    
      local hotstart=true
      
      -- Cold start (default).
      local _type=COORDINATE.WaypointType.TakeOffParking
      local _action=COORDINATE.WaypointAction.FromParkingArea
      
      -- Hot start.
      if hotstart then
        _type=COORDINATE.WaypointType.TakeOffParkingHot
        _action=COORDINATE.WaypointAction.FromParkingAreaHot
      end
    
      -- First route point is the warehouse airbase.
      template.route.points[1]=self.airbase:GetCoordinate():WaypointAir("BARO",_type,_action, 0, true, self.airbase, nil, "Spawnpoint")
      
    end
    
    -- Get airbase ID and category.
    local AirbaseID = self.airbase:GetID()
    local AirbaseCategory = self.category
    
    -- Check enough parking spots.
    if AirbaseCategory == Airbase.Category.HELIPAD or AirbaseCategory == Airbase.Category.SHIP then
      --TODO Figure out what's necessary in this case.
    
    else
    
      if #parking<#template.units then
        local text=string.format("ERROR: Not enough parking! Free parking = %d < %d aircraft to be spawned.", #parking, #template.units)
        self:E(text)
        return nil
      end
    end
        
    -- Position the units.
    for i=1,#template.units do
    
      -- Unit template.
      local unit = template.units[i]

      if AirbaseCategory == Airbase.Category.HELIPAD or AirbaseCategory == Airbase.Category.SHIP then

        -- Helipads we take the position of the airbase location, since the exact location of the spawn point does not make sense.
        local coord=self.airbase:GetCoordinate()
        
        unit.x=coord.x
        unit.y=coord.z
        unit.alt=coord.y
  
        unit.parking_id = nil
        unit.parking    = nil
      
      else
    
        local coord=parking[i].Coordinate    --Core.Point#COORDINATE
        local terminal=parking[i].TerminalID --#number
        
        coord:MarkToAll(string.format("Spawnplace unit %s terminal %d", unit.name, terminal))
        
        unit.x=coord.x
        unit.y=coord.z
        unit.alt=coord.y
  
        unit.parking_id = nil
        unit.parking    = terminal
        
      end
    end
    
    -- Set general spawnpoint position.
    --local abc=self.airbase:GetCoordinate()
    --spawnpoint.x   = template.units[1].x
    --spawnpoint.y   = template.units[1].y
    --spawnpoint.alt = template.units[1].alt
    
    -- And template position.
    template.x = template.units[1].x
    template.y = template.units[1].y
    
    -- Uncontrolled spawning.
    template.uncontrolled=uncontrolled
    
    -- Debug info.
    self:T2({airtemplate=template})
    
    -- Spawn group.
    local group=_DATABASE:Spawn(template) --Wrapper.Group#GROUP
    
    -- Activate group - should only be necessary for late activated groups.
    --group:Activate()
    
    return group
  end
  
  return nil
end


--- Prepare a spawn template for the asset. Deep copy of asset template, adjusting template and unit names, nillifying group and unit ids.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset Ground asset that will be spawned.
-- @param #WAREHOUSE.Queueitem request Request belonging to this asset. Needed for the name/alias.
-- @return #table Prepared new spawn template.
function WAREHOUSE:_SpawnAssetPrepareTemplate(asset, request)

  -- Create an own copy of the template!
  local template=UTILS.DeepCopy(asset.template)
  --local template=asset.template
  
  -- Set unique name.
  template.name=self:_Alias(asset, request)
  
  -- Set current(!) coalition and country. 
  template.CoalitionID=self.coalition
  template.CountryID=self.country
  
  -- Nillify the group ID.
  template.groupId=nil

  -- For group units, visible needs to be false.
  if asset.category==Group.Category.GROUND then
    template.visible=false
  end
  
  -- No late activation.
  template.lateActivation=false

  -- Set and empty route.
  template.route = {}
  template.route.routeRelativeTOT=true
  template.route.points = {}

  -- Handle units.
  for i=1,#template.units do
  
    -- Unit template.
    local unit = template.units[i]
    
    -- Nillify the unit ID.
    unit.unitId=nil
    
    -- Set unit name: <alias>-01, <alias>-02, ...
    unit.name=string.format("%s-%02d", template.name , i)
  
  end

  return template
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
  self:E({warehouse=self.alias, request=Request})

  -- Distance from warehouse to requesting warehouse.
  local distance=self.coordinate:Get2DDistance(Request.warehouse.coordinate)

  -- Filter the requested assets.
  local _assets,_nasset,_enough=self:_FilterStock(self.stock, Request.assetdesc, Request.assetdescval, Request.nasset)
  
  if Request.nasset==0 then
    local text=string.format("Request denied! Zero assets were requested.")
    MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)  
    return false
  end
  
  -- Check if destination is in range for all requested assets.
  for _,_asset in pairs(_assets) do
    local asset=_asset --#WAREHOUSE.Assetitem

    -- Check if destination is in range.    
    if asset.range<distance then
      local text=string.format("Request denied! Destination %s is out of range for asset %s", Request.airbase:GetName(), asset.templatename)
      MESSAGE:New(text, 10):ToCoalitionIf(self.coalition, self.Report or self.Debug)
      self:E(self.wid..text)
      
      -- Delete request from queue because it will never be possible.
      --TODO: Unless(!) this is a moving warehouse which could, e.g., be an aircraft carrier. 
      self:_DeleteQueueItem(Request, self.queue)
      
      return false
    end
    
  end

  -- Asset is not in stock ==> request denied.
  if not _enough then
    local text=string.format("Request denied! Not enough assets currently in stock. Requested %s < %d in stock.", tostring(Request.nasset), _nasset)
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

 -- Pending request. Add cargo groups to request.
  local Pending=Request  --#WAREHOUSE.Pendingitem
  Pending.assets={}
  
  -- Spawn assets of this request.
  local _spawngroups,_cargoassets=self:_SpawnAssetRequest(Pending) --Core.Set#SET_GROUP
  
  -- Check if any group was spawned. If not, delete the request.
  if _spawngroups:Count()==0 then
    -- Delete request from queue.
    self:_DeleteQueueItem(Request, self.queue)
    self:E(self.wid..string.format("ERROR: Groups or request %d could not be spawned. Request is rejected and deleted from queue!", Request.uid))
    return
  end
  
  -- General type and category.
  local _cargotype=_cargoassets[1].attribute    --#WAREHOUSE.Attribute
  local _cargocategory=_cargoassets[1].category --DCS#Group.Category
   
  Pending.cargogroupset=_spawngroups
  Pending.cargoattribute=_cargotype
  Pending.cargocategory=_cargocategory

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Self request: assets are spawned at warehouse but not transported anywhere.
  ------------------------------------------------------------------------------------------------------------------------------------  
  
  -- Self request! Assets are only spawned but not routed or transported anywhere.  
  if self.warehouse:GetName()==Request.warehouse.warehouse:GetName() then
    self:E(self.wid..string.format("Selfrequest! Current status %s", self:GetState()))
    
    -- Add request to pending queue.
    table.insert(self.pending, Pending)
    
    -- Delete request from queue.
    self:_DeleteQueueItem(Request, self.queue)
        
    -- Start self request.
    self:__SelfRequest(1,_spawngroups, Pending)
    
    return
  end  
  
  ------------------------------------------------------------------------------------------------------------------------------------
  -- Self propelled: assets go to the requesting warehouse by themselfs. 
  ------------------------------------------------------------------------------------------------------------------------------------

  -- No transport unit requested. Assets go by themselfes.
  if Request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
    self:I(self.wid..string.format("Got selfpropelled request for %d assets.",_spawngroups:Count()))

    for _,_spawngroup in pairs(_spawngroups:GetSetObjects()) do
      
      -- Group intellisense.
      local group=_spawngroup --Wrapper.Group#GROUP
            
            
      -- Route cargo to their destination.
      if _cargocategory==Group.Category.GROUND then      
        self:I(self.wid..string.format("Route ground group %s.", group:GetName()))

        -- Random place in the spawn zone of the requesting warehouse.
        local ToCoordinate=Request.warehouse.spawnzone:GetRandomCoordinate()
        ToCoordinate:MarkToAll(string.format("Destination of group %s", group:GetName()))

        -- Route ground.
        self:_RouteGround(group, Request)
        
      elseif _cargocategory==Group.Category.AIRPLANE or _cargocategory==Group.Category.HELICOPTER then
        self:I(self.wid..string.format("Route airborne group %s.", group:GetName()))
        
        -- Route plane the the requesting warehouses airbase.
        -- Actually, the route is already set. We only need to activate the uncontrolled group.
        self:_RouteAir(group, Request.airbase)
        
      elseif _cargocategory==Group.Category.SHIP then
      
        self:E("ERROR: self propelled ship not implemented yet!")
        
      elseif _cargocategory==Group.Category.TRAIN then
        self:I(self.wid..string.format("Route train group %s.", group:GetName()))
        
        -- Route train to the rail connection of the requesting warehouse.
        self:_RouteTrain(group, Request.warehouse.rail)
      else
        self:E(self.wid..string.format("ERROR: unknown category %s for self propelled cargo %s!", tostring(_cargocategory), tostring(group:GetName())))
      end

    end
    
    -- Add request to pending queue.
    table.insert(self.pending, Pending)
    
    -- Delete request from queue.
    self:_DeleteQueueItem(Request, self.queue)
    
    -- No cargo transport necessary.
    return
  end

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Prepare cargo groups for transport
  ------------------------------------------------------------------------------------------------------------------------------------
  
  -- Add groups to cargo if they don't go by themselfs.
  local CargoGroups --Core.Set#SET_CARGO
  
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
  
  ------------------------------------------------------------------------------------------------------------------------------------
  -- Transport assets and dispatchers
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
    Parking=self:_FindParkingForAssets(self.airbase,_assetstock)
  end  
  
  -- Transport assets table.
  local _transportassets={}

  -- Dependent on transport type, spawn the transports and set up the dispatchers.
  if Request.transporttype==WAREHOUSE.TransportType.AIRPLANE then
    ----------------
    --- AIRPLANE ---
    ----------------
  
    -- Spawn the transport groups.    
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Assetitem

      -- Spawn with ALIAS here or DCS crashes!
      local _alias=self:_Alias(_assetitem, Request)
      
      -- Spawn plane at airport in uncontrolled state. 
      local spawngroup=self:_SpawnAssetAircraft(_assetitem, Pending, Parking[_assetitem.uid], true)

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        Pending.assets[_assetitem.uid]=_assetitem
        table.insert(_transportassets,_assetitem)
      end
    end

    -- Delete spawned items from warehouse stock.
    for _,_item in pairs(_transportassets) do
      self:_DeleteStockItem(_item)
    end

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_AIRPLANE:New(TransportSet, CargoGroups, PickupAirbaseSet, DeployAirbaseSet)

  elseif Request.transporttype==WAREHOUSE.TransportType.HELICOPTER then
    ------------------
    --- HELICOPTER ---
    ------------------

    -- Spawn the transport groups.
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Assetitem
      
      -- Spawn with ALIAS here or DCS crashes!
      local _alias=self:_Alias(_assetitem, Request)

      -- Spawn plane at airport in controlled state. They need to fly to the spawn zone. 
      local spawngroup=self:_SpawnAssetAircraft(_assetitem, Pending, Parking[_assetitem.uid], false)      

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        Pending.assets[_assetitem.uid]=_assetitem
        table.insert(_transportassets,_assetitem)
      else
        self:E(self.wid.."ERROR: spawngroup helo transport does not exist!")
      end
    end

    -- Delete spawned items from warehouse stock.
    for _,_item in pairs(_transportassets) do
      self:_DeleteStockItem(_item)
    end

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_HELICOPTER:New(TransportSet, CargoGroups, DeployZoneSet)

    -- Home zone.
    --CargoTransport:Setairbase(self.airbase)
    CargoTransport:SetHomeZone(self.spawnzone)

  elseif Request.transporttype==WAREHOUSE.TransportType.APC then
    -----------
    --- APC ---
    -----------

    -- Spawn the transport groups.
    for i=1,Request.ntransport do

      -- Get stock item.
      local _assetitem=_assetstock[i] --#WAREHOUSE.Assetitem

      -- Spawn with ALIAS here or DCS crashes!
      local _alias=self:_Alias(_assetitem, Request)

      -- Spawn ground asset.      
      local spawngroup=self:_SpawnAssetGround(_assetitem, Request)

      if spawngroup then
        -- Set state of warehouse so we can retrieve it later.
        spawngroup:SetState(spawngroup, "WAREHOUSE", self)

        -- Add group to transportset.
        TransportSet:AddGroup(spawngroup)

        Pending.assets[_assetitem.uid]=_assetitem
        table.insert(_transportassets,_assetitem)
      end
    end

    -- Delete spawned items from warehouse stock.
    for _,_item in pairs(_transportassets) do
      self:_DeleteStockItem(_item)
    end

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_APC:New(TransportSet, CargoGroups, DeployZoneSet, 0)
    
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

    self:I("FF OnAfterUnloaded:")
    self:I({From=From})
    self:I({Event=Event})
    self:I({To=To})
    self:I({Carrier=Carrier})
    self:I({Cargo=Cargo})

    -- Get group obejet.
    local group=Cargo:GetObject() --Wrapper.Group#GROUP

    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE

    -- Trigger Arrived event.
    warehouse:__Arrived(1, group)
  end
  
  --- On after BackHome event.
  function CargoTransport:OnAfterBackHome(From, Event, To, Carrier)
  
    -- Intellisense.
    local carrier=Carrier --Wrapper.Group#GROUP
  
    -- Get warehouse state.
    local warehouse=carrier:GetState(carrier, "WAREHOUSE") --#WAREHOUSE
    carrier:SmokeWhite()
    
    -- Debug info.
    local text=string.format("Carrier %s is back home at warehouse %s.", tostring(Carrier:GetName()), tostring(warehouse.warehouse:GetName()))
    MESSAGE:New(text, 5):ToAllIf(warehouse.Debug)
    warehouse:I(warehouse.wid..text)
    
    -- Add carrier back to warehouse stock. Actual unit is destroyed.
    warehouse:AddAsset(Carrier)
    
  end  

  -- Start dispatcher.
  CargoTransport:__Start(5)
    
  -- Add cargo groups to request.
  Pending.transportgroupset=TransportSet
  Pending.transportattribute=_transporttype
  Pending.transportcategory=_transportcategory

  -- Add request to pending queue.
  table.insert(self.pending, Pending)

  -- Delete request from queue.
  self:_DeleteQueueItem(Request, self.queue)

end


--- Spawns requested assets at warehouse or associated airbase.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
-- @return Core.Set#SET_GROUP Set of groups that were spawned.
-- @return #table List of spawned assets.
function WAREHOUSE:_SpawnAssetRequest(Request)
  self:E({requestUID=Request.uid})

  -- Filter the requested cargo assets.
  local _assetstock,_nasset,_enough=self:_FilterStock(self.stock, Request.assetdesc, Request.assetdescval, Request.nasset)
  
  self:E({num_assetstoc=#_assetstock, nasset=_nasset, enough=_enough})
  
  -- No assets in stock :(
  if not _enough then
    return nil,nil,nil
  end

  -- General type and category.
  local _cargotype=_assetstock[1].attribute    --#WAREHOUSE.Attribute
  local _cargocategory=_assetstock[1].category --DCS#Group.Category
  
  -- Now we try to find all parking spots for all cargo groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  if  _cargocategory==Group.Category.AIRPLANE or _cargocategory==Group.Category.HELICOPTER then
    Parking=self:_FindParkingForAssets(self.airbase,_assetstock) 
  end
  
  -- Spawn aircraft in uncontrolled state if request comes from the same warehouse.
  local UnControlled=false
  local AIOnOff=true
  if self.warehouse:GetName()==Request.warehouse.warehouse:GetName() then
    UnControlled=true
    AIOnOff=false
  end
  
  -- Create an empty group set.
  local _groupset=SET_GROUP:New():FilterDeads()

  -- Table for all spawned assets.
  local _assets={}
  
  -- Loop over cargo requests.
  for i=1,#_assetstock do

    -- Get stock item.
    local _assetitem=_assetstock[i] --#WAREHOUSE.Assetitem
    
    -- Alias of the group.
    local _alias=self:_Alias(_assetitem, Request)

    -- Spawn an asset group.
    local _group=nil --Wrapper.Group#GROUP          
    if _assetitem.category==Group.Category.GROUND then
    
      -- Spawn ground troops.      
      _group=self:_SpawnAssetGround(_assetitem, Request)
      
    elseif _assetitem.category==Group.Category.AIRPLANE or _assetitem.category==Group.Category.HELICOPTER then
    
      --TODO: spawn only so many groups as there are parking spots. Adjust request and create a new one with the reduced number!
    
      -- Spawn air units.
      _group=self:_SpawnAssetAircraft(_assetitem, Request, Parking[_assetitem.uid], UnControlled)
      
    elseif _assetitem.category==Group.Category.TRAIN then
    
      -- Spawn train.
      if self.rail then
        --TODO: Rail should only get one asset because they would spawn on top!
        --_group=_spawn:SpawnFromCoordinate(self.rail)
      end
      
      self:E(self.wid.."ERROR: Spawning of TRAIN assets not possible yet!")
      
    elseif _assetitem.category==Group.Category.SHIP then
      self:E(self.wid.."ERROR: Spawning of SHIP assets not possible yet!")
    else
      
    end

    -- Add group to group set and asset list.
    if _group then
      _groupset:AddGroup(_group)
      table.insert(_assets, _assetitem)
    else
      self:E(self.wid.."ERROR: Cargo asset could not be spawned!")
    end
    
  end

  -- Delete spawned items from warehouse stock.
  for _,_asset in pairs(_assets) do
    local asset=_asset --#WAREHOUSE.Assetitem
    Request.assets[asset.uid]=asset
    self:_DeleteStockItem(asset)
  end

  return _groupset,_assets
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
  
  if group and group:IsAlive() then

    -- Debug smoke.
    group:SmokeWhite()
  
    -- Get max speed of group.
    local speedmax=group:GetSpeedMax()
    
    if group:IsGround() then
      -- Route group to spawn zone.
      if speedmax>1 then
        group:RouteGroundTo(self.spawnzone:GetRandomCoordinate(), speedmax*0.5, AI.Task.VehicleFormation.RANK, 3)
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
    
  else
    self:E(self.wid..string.format("ERROR unloaded Cargo group is not alive!"))
  end  
end

--- On after "Arrived" event. Triggered when a group has arrived at its destination.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group that was delivered.
function WAREHOUSE:onafterArrived(From, Event, To, group)
   
  self:I(self.wid..string.format("Cargo %s arrived!", tostring(group:GetName())))
  group:SmokeOrange()
    
  -- Update pending request.
  local request=self:_UpdatePending(group)
  
  if request then
  
    -- Number of cargo assets still in group set.
    local ncargo=request.cargogroupset:Count()
    
    -- Debug message.
    local text=string.format("Cargo %d of %s arrived at warehouse %s. Assets still to deliver %d.",request.ndelivered, tostring(request.nasset), request.warehouse.alias, ncargo)
    MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Debug)
    self:I(self.wid..text)
    
    -- Route mobile ground group to the warehouse. Group has 60 seconds to get there or it is despawned and added as asset to the new warehouse regardless.
    if group:IsGround() and group:GetSpeedMax()>1 then
      group:RouteGroundTo(request.warehouse.coordinate, group:GetSpeedMax()*0.3, "Off Road")
    end
    
    -- Move asset from pending queue into new warehouse.
    request.warehouse:__AddAsset(60, group)
    
    -- All cargo delivered.
    if request and ncargo==0 then
      self:__Delivered(5, request)
    end
    
  end
    
end

--- Get asset from group and request.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that has arrived at its destination.
-- @param #WAREHOUSE.Pendingitem request Pending request.
-- @return #WAREHOUSE.Assetitem The asset.
function WAREHOUSE:_GetAssetFromGroupRequest(group,request)

  -- Get the IDs for this group. In particular, we use the asset ID to figure out which group was delivered.
  local wid,aid,rid=self:_GetIDsFromGroup(group)
  
  -- Retrieve asset from request.
  local asset=request.assets[aid]
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
    for _,_cargogroup in pairs(request.cargogroupset:GetSetObjects()) do
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
    self:E(self.wid..string.format("WARNING: pending request could not be updated since request did not exist in pending queue!"))
  end
  
  return request,wid,aid,rid
end


--- On after "Delivered" event. Triggered when all asset groups have reached their destination. Corresponding request is deleted from the pending queue.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Pendingitem request The pending request that is finished and deleted from the pending queue.
function WAREHOUSE:onafterDelivered(From, Event, To, request)

  -- Debug info
  local text=string.format("Warehouse %s: All assets delivered to warehouse %s!", self.alias, request.warehouse.alias)
  MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)

  -- Make some noice :)  
  self:_Fireworks(request.warehouse.coordinate)

  -- Remove pending request:
  self:_DeleteQueueItem(request, self.pending)
  
end


--- On after "SelfRequest" event. Request was initiated to the warehouse itself. Groups are just spawned at the warehouse or the associated airbase.
-- If the warehouse is currently under attack when the self request is made, the self request is added to the defending table. One the attack is defeated,
-- this request is used to put the groups back into the warehouse stock.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
-- @param #WAREHOUSE.Pendingitem request Pending self request.
function WAREHOUSE:onafterSelfRequest(From, Event, To, groupset, request)

  -- Debug info.
  self:I(self.wid..string.format("Assets spawned at warehouse %s after self request!", self.alias))
  
  -- Debug info.
  for _,_group in pairs(groupset:GetSetObjects()) do
    local group=_group --Wrapper.Group#GROUP
    local text=string.format("Group name = %s, IsAlive=%s.", tostring(group:GetName()), tostring(group:IsAlive()))
    env.info(text)
    --group:SmokeGreen()
  end
  
  -- Add a "defender request" to be able to despawn all assets once defeated.
  if self:IsAttacked() then
    --self.defenderrequest=request    
    table.insert(self.defending, request)
  end
  
  -- Remove pending request.
  self:_DeleteQueueItem(request, self.pending)
end

--- On after "Attacked" event. Warehouse is under attack by an another coalition.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition which is attacking the warehouse.
-- @param DCS#country.id Country which is attacking the warehouse.
function WAREHOUSE:onafterAttacked(From, Event, To, Coalition, Country)

  -- Warning.
  local text=string.format("Warehouse %s: We are under attack!", self.alias)
  MESSAGE:New(text, 20):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)
  
  -- Spawn all ground units in the spawnzone?
  self:AddRequest(self, WAREHOUSE.Descriptor.CATEGORY, Group.Category.GROUND, "all", nil, nil , 0)
end

--- On after "Defeated" event. Warehouse defeated an attack by another coalition. Defender assets are added back to warehouse stock.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterDefeated(From, Event, To)

  -- Message.
  local text=string.format("Warehouse %s: Enemy attack was defeated!", self.alias)
  MESSAGE:New(text, 20):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)

  --if self.defenderrequest then
  for _,request in pairs(self.defending) do
    
    -- Get all assets that were deployed for defending the warehouse.
    --local request=self.defenderrequest --#WAREHOUSE.Pendingitem
  
    -- Route defenders back to warehoue (for visual reasons only) and put them back into stock.  
    for _,_group in pairs(request.cargogroupset:GetSetObjects()) do
      local group=_group --Wrapper.Group#GROUP
      
      -- Get max speed of group and route it back slowly to the warehouse.
      local speed=group:GetSpeedMax()
      if group:IsGround() and speed>1 then
        group:RouteGroundTo(self.coordinate, speed*0.3)
      end 
      
      -- Add asset group back to stock after 60 seconds.
      self:__AddAsset(60, group)
    end
    
    -- Set defender request back to nil. 
    --self.defenderrequest=nil
  
    --self:_DeleteQueueItem(request, self.defending)  
  end
  
  self.defending=nil
  self.defending={}
end

--- On after "Captured" event. Warehouse has been captured by another coalition.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition which captured the warehouse.
-- @param DCS#country.id Country which has captured the warehouse.
function WAREHOUSE:onafterCaptured(From, Event, To, Coalition, Country)

  -- Message.
  local text=string.format("Warehouse %s: We were captured by enemy coalition (%d)!", self.alias, Coalition)
  MESSAGE:New(text, 20):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)
  
  -- Respawn warehouse with new coalition/country.
  self.warehouse:ReSpawn(Country)
  
  -- Set new country and coalition
  self.coalition=Coalition
  self.country=Country
  
  -- Delete all waiting requests because they are not valid any more
  self.queue=nil
  self.queue={}
  
  --TODO: What about pending items? Is there any problem due to the coalition change?
  --TODO: Maybe if the receiving warehouse gets captured! Oh, oh :(
  --      What to do? send the items back? Impossible.
    
  -- Airbase could have been captured before and already belongs to the new coalition.
  local airbase=AIRBASE:FindByName(self.airbasename)
  local airbasecoaltion=airbase:GetCoalition()
  
  if self.coalition==airbasecoaltion then
    -- Airbase already owned by the coalition that captured the warehouse. Airbase can be used by this warehouse.
    self.airbase=airbase
    self.category=airbase:GetDesc().category
  else
    -- Airbase is owned by other coalition. So this warehouse does not have an airbase unil it is captured.
    self.airbase=nil
    self.category=-1
  end
    
end

--- On after "AirbaseCaptured" event. Airbase of warehouse has been captured by another coalition.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition which captured the warehouse.
function WAREHOUSE:onafterAirbaseCaptured(From, Event, To, Coalition)

  -- Message.
  local text=string.format("Warehouse %s: Our airbase %s was captured by the enemy (coalition=%d)!", self.alias, self.airbasename, Coalition)
  MESSAGE:New(text, 20):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)

  -- Debug smoke.
  self.airbase:GetCoordinate():SmokeRed()
  
  -- Set airbase to nil and category to no airbase.
  self.airbase=nil
  self.category=-1  -- -1 indicates no airbase.
end

--- On after "AirbaseRecaptured" event. Airbase of warehouse has been re-captured from other coalition.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition which captured the warehouse.
function WAREHOUSE:onafterAirbaseRecaptured(From, Event, To, Coalition)

  -- Message.
  local text=string.format("Warehouse %s: We recaptured our airbase %d from the enemy (coalition=%d)!", self.alias, self.airbasename, Coalition)
  MESSAGE:New(text, 20):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)

  -- Set airbase and category.  
  self.airbase=AIRBASE:FindByName(self.airbasename)
  self.category=self.airbase:GetDesc().category
  
  -- Debug smoke.
  self.airbase:GetCoordinate():SmokeGreen()
end


--- On after "Destroyed" event. Warehouse was destroyed. All services are stopped.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterDestroyed(From, Event, To)

  -- Message.
  local text=string.format("Warehouse %s was destroyed!", self.alias)
  MESSAGE:New(text, 20):ToCoalitionIf(self.coalition, self.Report or self.Debug)
  self:I(self.wid..text)

  -- Stop warehouse FSM.
  self:Stop()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Route ground units to destination.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The ground group to be routed
-- @param #WAREHOUSE.Queueitem request The request for this group.
-- @param #number Speed Speed in km/h to drive to the destination coordinate. Default is 60% of max possible speed the unit can go.
function WAREHOUSE:_RouteGround(group, request)

  if group and group:IsAlive() then

    -- Set speed to 70% of max possible.
    local _speed=group:GetSpeedMax()*0.7

    -- Create task.
    
    -- Waypoints for road-to-road connection.
    local Waypoints, canroad = group:TaskGroundOnRoad(request.warehouse.road, _speed, "Off Road", false, self.road)
    
    -- First waypoint = current position of the group.
    local FromWP=group:GetCoordinate():WaypointGround(_speed, "Off Road")
    table.insert(Waypoints, 1, FromWP)
    
    -- Final coordinate.
    local ToWP=request.warehouse.spawnzone:GetRandomCoordinate():WaypointGround(_speed, "Off Road")
    table.insert(Waypoints, #Waypoints+1, ToWP)

    -- Task function triggering the arrived event.
    local TaskFunction = group:TaskFunction("WAREHOUSE._Arrived", self)

    -- Put task function on last waypoint.
    local Waypoint = Waypoints[#Waypoints]
    group:SetTaskWaypoint(Waypoint, TaskFunction)

    -- Route group to destination.
    group:Route(Waypoints, 1)
    
    -- Set ROE and alaram state.
    group:OptionROEReturnFire()
    group:OptionAlarmStateGreen()
  end
end


--- Route the airplane from one airbase another. Activates uncontrolled aircraft and sets ROE/ROT for ferry flights.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP Aircraft Airplane group to be routed.
function WAREHOUSE:_RouteAir(aircraft)

  if aircraft and aircraft:IsAlive()~=nil then
    
    -- Debug info.
    self:T2(self.wid..string.format("RouteAir aircraft group %s alive=%s", aircraft:GetName(), tostring(aircraft:IsAlive())))
    
    -- Give start command to activate uncontrolled aircraft. 
    aircraft:SetCommand({id='Start', params={}})

    -- Debug info.
    self:T2(self.wid..string.format("RouteAir aircraft group %s alive=%s (after start command)", aircraft:GetName(), tostring(aircraft:IsAlive())))
    
    -- Set ROE and alaram state.
    aircraft:OptionROEReturnFire()
    aircraft:OptionROTPassiveDefense()
    
  else
    self:E(string.format("ERROR: aircraft %s cannot be routed since it does not exist or is not alive %s!", tostring(aircraft:GetName()), tostring(aircraft:IsAlive())))
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
  env.info(warehouse.wid..string.format("Group %s arrived at destination.", tostring(group:GetName())))
  
  --Trigger "Arrived" event.
  warehouse:__Arrived(1, group)
  
end

--- Simple task function for last waypoint. Triggering the "Arrived" event.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that arrived.
function WAREHOUSE:_ArrivedSimple(group)

  if group then
    --local self:_GetIDsFromGroup(group)
    env.info(self.wid..string.format("Group %s arrived at warehouse ", tostring(group:GetName())))
  
    --Trigger "Arrived event.
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

  if EventData and EventData.IniUnit then
  
    -- Unit that arrived.
    local unit=EventData.IniUnit
    
    -- Check if unit is alive and on the ground. Engine shutdown can also be triggered in other situations!
    if unit and unit:IsAlive()==true and unit:InAir()==false then
    
      -- Smoke unit that arrived.
      unit:SmokeBlue()
    
      -- Get group.
      local group=EventData.IniGroup
      
      -- Get unique IDs from group name. 
      local wid,aid,rid=self:_GetIDsFromGroup(group)
      
      -- If all IDs are good we can assume it is a warehouse asset.
      if wid~=nil and aid~=nil and rid~=nil then
      
        -- Debug info.
        local text=string.format("Air asset group %s arrived at warehouse %s.", group:GetName(), self.alias)
        --MESSAGE:New
        self:E(self.wid..text)
        
        -- Trigger arrived event for this group. Note that each unit of a group will trigger this event. So the onafterArrived function needs to take care of that.
        -- Actually, we only take the first unit of the group that arrives. If it does, we assume the whole group arrived, which might not be the case, since
        -- some units might still be taxiing or whatever. Therefore, we add 10 seconds for each additional unit of the group until the first arrived event is triggered.
        local nunits=#group:GetUnits()
        local dt=10*(nunits-1)+1  -- one unit = 1 sec, two units = 11 sec, three units = 21 sec before we call the group arrived.
        self:__Arrived(dt, group)
        
      else
        self:T3(string.format("Group that arrived did not belong to a warehouse. Warehouse ID=%s, Asset ID=%s, Request ID=%s.", tostring(wid), tostring(aid), tostring(rid)))
      end
    end
  end

end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventBirth(EventData)
  self:T3(self.wid..string.format("Warehouse %s (id=%s) captured event birth!", self.alias, self.uid))
  
  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    -- env.info(string.format("FF birth of group %s (alive=%s) unit %s", tostring(EventData.IniGroupName), tostring(EventData.IniGroup:IsAlive()), tostring(EventData.IniUnitName)))
    -- Note: Remember, group:IsAlive might(?) not return true here.
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:E(self.wid..string.format("Warehouse %s captured event birth of its asset unit %s.", self.alias, EventData.IniUnitName))
    else
      --self:T3({wid=wid, uid=self.uid, match=(wid==self.uid), tw=type(wid), tu=type(self.uid)})
    end
  end
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventEngineStartup(EventData)
  self:T3(self.wid..string.format("Warehouse %s captured event engine startup!",self.alias))

  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:E(self.wid..string.format("Warehouse %s captured event engine startup of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end  
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventTakeOff(EventData)
  self:T3(self.wid..string.format("Warehouse %s captured event takeoff!",self.alias))
  
  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:E(self.wid..string.format("Warehouse %s captured event takeoff of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end  
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventLanding(EventData)
  self:T3(self.wid..string.format("Warehouse %s captured event landing!",self.alias))
  
  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:E(self.wid..string.format("Warehouse %s captured event landing of its asset unit %s.", self.alias, EventData.IniUnitName))
      
      -- Get request of this group
      local request=self:_GetRequestOfGroup(group,self.pending)
      
      -- If request is nil, the cargo has been delivered.
      -- TODO: I might need to add a delivered table, to be better able to get this right.
      if request==nil then
      
        -- Check if helicopter landed in spawn zone. If so, we call it a day and add it back to stock. 
        if group:GetCategory()==Group.Category.HELICOPTER then
          if self.spawnzone:IsCoordinateInZone(EventData.IniUnit:GetCoordinate()) then
            group:SmokeWhite()
            self:__AddAsset(30, group)   
          end
        end
        
      end
      
    end
  end
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventEngineShutdown(EventData)
  self:T3(self.wid..string.format("Warehouse %s captured event engine shutdown!", self.alias))
  
  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:E(self.wid..string.format("Warehouse %s captured event engine shutdown of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end  
end

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventCrashOrDead(EventData)
  self:T3(self.wid..string.format("Warehouse %s captured event dead or crash!",self.alias))
  
  if EventData and EventData.IniUnit then
  
    -- Check if warehouse was destroyed.
    local warehousename=self.warehouse:GetName()
    if EventData.IniUnitName==warehousename then
      env.info(self.wid..string.format("Warehouse %s alias %s was destroyed!", warehousename, self.alias))
      self:Destroyed()
    end
  end

  -- Check if an asset unit was destroyed.
  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:E(self.wid..string.format("Warehouse %s captured event dead or crash of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end  
  
end

--- Warehouse event handling function.
-- Handles the case when the airbase associated with the warehous is captured.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventBaseCaptured(EventData)
  
  -- This warehouse does not have an airbase and never had one. So i could not be captured.
  if self.airbasename==nil then
    -- This warehouse never had an airbase so I cannot have been captured.
    return
  end
  
  self:E(self.wid..string.format("Warehouse %s captured event base captured!",self.alias))
  
  if EventData and EventData.Place then
      
    -- Place is the airbase that was captured.
    local airbase=EventData.Place --Wrapper.Airbase#AIRBASE
    
    if EventData.PlaceName==self.airbasename then
      -- Okay, this airbase belongs or did belong to this warehouse.
      
      self:I(self.wid..string.format("Airbase of warehouse %s was captured! ",self.alias))
      
      -- New coalition of airbase after it was captured.
      local coalitionAirbase=airbase:GetCoalition()
      
      -- So what can happen?
      -- Warehouse is blue, airbase is blue and belongs to warehouse and red captures it  ==> self.airbase=nil
      -- Warehouse is blue, airbase is blue self.airbase is nil and blue (re-)captures it ==> self.airbase=Event.Place        
      if self.airbase==nil then
        -- Warehouse lost this airbase previously and not it was re-captured.
        if coalitionAirbase == self.coalition then
          self:AirbaseRecaptured(coalitionAirbase)
        end
      else
        -- Captured airbase belongs to this warehouse but was captured by other coaltion.
        if coalitionAirbase ~= self.coalition then
          self:AirbaseCaptured(coalitionAirbase)
        end
      end
        
    end
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Checks if the warehouse zone was conquered by antoher coalition.
-- @param #WAREHOUSE self
function WAREHOUSE:_CheckConquered()

  -- Get coordinate and radius to check.
  local coord=self.zone:GetCoordinate()
  local radius=self.zone:GetRadius()
  
  -- Scan units in zone.
  --TODO: need to check if scan radius does what it should!
  -- It seems to return units that are further away than the radius.
  local gotunits,_,_,units,_,_=coord:ScanObjects(radius, true, false, false)
  
  local Nblue=0
  local Nred=0
  local Nneutral=0
  
  local CountryBlue=nil
  local CountryRed=nil
  local CountryNeutral=nil
  
  if gotunits then
    -- Loop over all units.
    for _,_unit in pairs(units) do
      local unit=_unit --Wrapper.Unit#UNIT
      
      local distance=coord:Get2DDistance(unit:GetCoordinate())
      
      -- Filter only alive groud units. Also check distance again, because the scan routine might give some larger distances.
      if unit:IsGround() and unit:IsAlive() and distance <= radius then
      
        -- Get coalition and country.
        local _coalition=unit:GetCoalition()
        local _country=unit:GetCountry()
        
        -- Debug info.
        self:T2(self.wid..string.format("Unit %s in warehouse zone of radius=%d m. Coalition=%d, country=%d. Distance = %d m.",unit:GetName(), radius,_coalition,_country, distance))
        
        -- Add up units for each side.
        if _coalition==coalition.side.BLUE then
          Nblue=Nblue+1
          CountryBlue=_country
        elseif _coalition==coalition.side.RED then
          Nred=Nred+1
          CountryRed=_country
        else
          Nneutral=Nneutral+1
          CountryNeutral=_country
        end
        
      end      
    end
  end
  
  -- Debug info.
  self:T(self.wid..string.format("Ground troops in warehouse zone: blue=%d, red=%d, neutral=%d", Nblue, Nred, Nneutral))
 
 
  -- Figure out the new coalition if any.
  -- Condition is that only units of one coalition are within the zone.
  local newcoalition=self.coalition
  local newcountry=self.country
  if Nblue>0 and Nred==0 and Nneutral==0 then
    -- Only blue units in zone ==> Zone goes to blue.
    newcoalition=coalition.side.BLUE
    newcountry=CountryBlue
  elseif Nblue==0 and Nred>0 and Nneutral==0 then
    -- Only red units in zone ==> Zone goes to red.
    newcoalition=coalition.side.RED
    newcountry=CountryRed
  elseif Nblue==0 and Nred==0 and Nneutral>0 then
    -- Only neutral units in zone but neutrals do not attack or even capture!
    --newcoalition=coalition.side.NEUTRAL
    --newcountry=CountryNeutral
  end

  -- Coalition has changed ==> warehouse was captured! This should be before the attack check.
  if self:IsAttacked() and newcoalition ~= self.coalition then
    self:Captured(newcoalition, newcountry)
    return
  end
  
  -- Before a warehouse can be captured, it has to be attacked.
  -- That is, even if only enemy units are present it is not immediately captured in order to spawn all ground assets for defence.
  if self.coalition==coalition.side.BLUE then
    -- Blue warehouse is running and we have red units in the zone.
    if self:IsRunning() and Nred>0 then
      self:Attacked(coalition.side.RED, CountryRed)
    end
    -- Blue warehouse was under attack by blue but no more blue units in zone.
    if self:IsAttacked() and Nred==0 then
      self:Defeated()
    end    
  elseif self.coalition==coalition.side.RED then
    -- Red Warehouse is running and we have blue units in the zone.
    if self:IsRunning() and Nblue>0 then
      self:Attacked(coalition.side.BLUE, CountryBlue)
    end
    -- Red warehouse was under attack by blue but no more blue units in zone.
    if self:IsAttacked() and Nblue==0 then
      self:Defeated()
    end
  elseif self.coalition==coalition.side.NEUTRAL then
    -- Neutrals dont attack!
  end
  
end

--- Checks if the associated airbase still belongs to the warehouse.
-- @param #WAREHOUSE self
function WAREHOUSE:_CheckAirbaseOwner()
  -- The airbasename is set at start and not deleted if the airbase was captured.
  if self.airbasename then
  
    local airbase=AIRBASE:FindByName(self.airbasename)
    local airbasecurrentcoalition=airbase:GetCoalition()
    
    if self.airbase then
    
      -- Warehouse has lost its airbase.
      if self.coalition~=airbasecurrentcoalition then
        self.airbase=nil
        self.category=-1
      end
      
    else
      
      -- Warehouse has re-captured the airbase.
      if self.coalition==airbasecurrentcoalition then
        self.airbase=airbase
        self.category=airbase:GetDesc().category
      end      
      
    end
    
  end
end

--- Checks if the request can be fulfilled in general. If not, it is removed from the queue.
-- Check if departure and destination bases are of the right type.
-- @param #WAREHOUSE self
-- @param #table queue The queue which is holding the requests to check.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequestConsistancy(queue)
  self:T3(self.wid..string.format("Number of queued requests = %d", #queue))

  -- Requests to delete.
  local invalid={}
  
  for _,_request in pairs(queue) do
    local request=_request --#WAREHOUSE.Queueitem
    
    -- Debug info.
    self:T2(self.wid..string.format("Checking request = %d.", request.uid))
    
    -- Let's assume everything is fine.
    local valid=true
    
    --TODO: check that
    -- if warehouse or requestor is a FARP, plane asset and transport not possible.
    -- if requestor or warehouse is a SHIP, APC transport not possible, SELFPROPELLED only for AIR/SHIP
    -- etc. etc...
    
    -- Check if at least one asset was requested.
    if request.nasset==0 then
      self:E(self.wid..string.format("ERROR: Incorrect request. Request for zero assets not possible. Can happen when, e.g. \"all\" ground assets are requests but none in stock."))
      valid=false
    end
  
    -- Request from enemy coalition?
    if self.coalition~=request.warehouse.coalition then
      self:E(self.wid..string.format("ERROR: Incorrect request. Requesting warehouse is of wrong coaltion! Own coalition %d. Requesting warehouse %d", self.coalition, request.warehouse.coalition))
      valid=false
    end
    
    -- Is receiving warehouse stopped? Actually, running state is checked later. So I leave this for now in case the warehouse was not started yet.
    -- TODO: Introduce another FSM start state to be able to distinguish between a warehouse that was not started yet or was started and then stopped!
    if request.warehouse:IsStopped() then
      self:E(self.wid..string.format("ERROR: Incorrect request. Requesting warehouse is stopped!"))
      valid=false    
    end
    
    -- Asset is air, ground etc.
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
        self:E("ERROR: Incorrect request. Asset Descriptor missmatch! Has to be Group.Cagetory.AIRPLANE, ...")
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
        self:E("ERROR: Incorrect request. Asset attribute WAREHOUSE.Attribute.OTHER is not valid!")
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
        self:E("ERROR: Incorrect request. Unknown asset attribute!")
        valid=false 
      end
    end
    
    -- General air request.
    asset_air=asset_helo or asset_plane
    
    if request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
      -------------------------------------------
      -- Case where the units go my themselves --
      -------------------------------------------

      if asset_air then
      
        if asset_plane then
        
          -- No airplane to or from FARPS.
          if request.category==Airbase.Category.HELIPAD or self.category==Airbase.Category.HELIPAD then
            self:E("ERROR: Incorrect request. Asset airplane requested but warehouse or requestor is HELIPAD/FARP!")
            valid=false
          end
          
          -- Category SHIP is not general enough! Fighters can go to carriers. Which fighters, is there an attibute?
          -- Also for carriers, attibute?
          
        elseif asset_helo then
        
          -- Helos need a FARP or AIRBASE or SHIP for spawning. Also at the the receiving warehouse. So even if they could go there they "cannot" be spawned again.
          -- Unless I allow spawning of helos in the the spawn zone. But one should place at least a FARP there.
          if self.category==-1 or request.category==-1 then
            self:E("ERROR: Incorrect request. Helos need a AIRBASE/HELIPAD/SHIP as home/destination base!")
            valid=false     
          end
          
        end
        
        -- All aircraft need an airbase of any type as depature or destination.
        if self.airbase==nil or request.airbase==nil then
          self:E("ERROR: Incorrect request. Either warehouse or requesting warehouse does not have any kind of airbase!")
          valid=false     
        end
        
      elseif asset_ground then
        
        -- No ground assets directly to or from ships.
        -- TODO: May needs refinement if warehouse is on land and requestor is ship in harbour?!
        if (request.category==Airbase.Category.SHIP or self.category==Airbase.Category.SHIP) then
          self:E("ERROR: Incorrect request. Ground asset requested but warehouse or requestor is SHIP!")
          --valid=false
        end
        
        if asset_train then
          -- Check if there is a valid path on rail.
          local hasrail=self:HasConnectionRail(request.warehouse)
          if not hasrail then
            self:E("ERROR: Incorrect request. No valid path on rail for train assets!")
            valid=false
          end
        else
          if self.warehouse:GetName()~=request.warehouse.warehouse:GetName() then
            -- Check if there is a valid path on road.
            local hasroad=self:HasConnectionRoad(request.warehouse)
            if not hasroad then
              self:E("ERROR: Incorrect request. No valid path on road for ground assets!")
              valid=false
            end
          end
        end        
      elseif asset_naval then
    
        self:E("ERROR: Incorrect request. Naval units not supported yet!")
        valid=false
      
      end
      
    else     
      -------------------------------
      -- Assests need a transport ---
      -------------------------------

      if request.transporttype==WAREHOUSE.TransportType.AIRPLANE then
      
        -- Airplanes only to AND from airdromes.
        if self.category~=Airbase.Category.AIRDROME or request.category~=Airbase.Category.AIRDROME then
          self:E("ERROR: Incorrect request. Warehouse or requestor does not have an airdrome. No transport by plane possible!")
          valid=false
        end
        
        --TODO: Not sure if there are any transport planes that can land on a carrier?
          
      elseif request.transporttype==WAREHOUSE.TransportType.APC then
      
        -- Transport by ground units.
        
        -- No transport to or from ships
        if self.category==Airbase.Category.SHIP or request.category==Airbase.Category.SHIP then
          self:E("ERROR: Incorrect request. Warehouse or requestor is SHIP. No transport by APC possible!")
          valid=false
        end
        
        -- Check if there is a valid path on road.
        local hasroad=self:HasConnectionRoad(request.warehouse)
        if not hasroad then
          self:E("ERROR: Incorrect request. No valid path on road for ground transport assets!")
          valid=false
        end

      elseif request.transporttype==WAREHOUSE.TransportType.HELICOPTER then
      
        -- Transport by helicopters ==> need airbase for spawning but not for delivering to the spawn zone of the receiver.
        if self.category==-1 then
          self:E("ERROR: Incorrect request. Warehouse has no airbase. Transport by helicopter not possible!")
          valid=false
        end
      
      elseif request.transporttype==WAREHOUSE.TransportType.SHIP then
      
        -- Transport by ship.
        self:E("ERROR: Incorrect request. Transport by SHIP not implemented yet!")
        valid=false
      
      elseif request.transporttype==WAREHOUSE.TransportType.TRAIN then
      
        -- Transport by train.
        self:E("ERROR: Incorrect request. Transport by TRAIN not implemented yet!")
        valid=false
       
      else
        -- No match.
        self:E("ERROR: Incorrect request. Transport type unknown!")
        valid=false
      end
  
    end
    
    -- Add request as unvalid and delete it later.
    if valid==false then
      self:E(self.wid..string.format("Got invalid request id=%d.", request.uid)) 
      table.insert(invalid, request)
    else
      self:T3(self.wid..string.format("Got valid request id=%d.", request.uid))
    end   
 
  end -- loop queue items.


   -- Delete invalid requests.
  for _,_request in pairs(invalid) do
    self:E(self.wid..string.format("Deleting invalid request id=%d.",_request.uid))
    self:_DeleteQueueItem(_request, self.queue)
  end
 
end

--- Checks if the request can be fullfilled right now.
-- Check for current parking situation, number of assets and transports currently in stock.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem request The request to be checked.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequestNow(request)
    
  -- Assume request is okay and check scenarios.
  local okay=true
  
  -- Check if receiving warehouse is running.
  if not request.warehouse:IsRunning() then
    local text=string.format("Warehouse %s: Request denied! Receiving warehouse %s is not running. Current state %s.", self.alias, request.warehouse.alias, request.warehouse:GetState())
    MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    okay=false
  end
    
  -- Check if number of requested assets is in stock.
  local _assets,_nassets,_enough=self:_FilterStock(self.stock, request.assetdesc, request.assetdescval, request.nasset)
  
  -- Check if enough assets are in stock.
  if not _enough then
    local text=string.format("Warehouse %s: Request denied! Not enough (cargo) assets currently available.", self.alias)
    MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
    self:E(self.wid..text)
    okay=false
  end

  -- Check if at least one transport asset is available.
  if _nassets>0 then

    -- Get the attibute of the requested asset.
    local _assetattribute=_assets[1].attribute
    local _assetcategory=_assets[1].category  
    
    -- Check available parking for air asset units.    
    if self.airbase and (_assetcategory==Group.Category.AIRPLANE or _assetcategory==Group.Category.HELICOPTER) then
      local Parking=self:_FindParkingForAssets(self.airbase,_assets)
      if Parking==nil then
        local text=string.format("Warehouse %s: Request denied! Not enough free parking spots for all assets at the moment.", self.alias)
        MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
        self:E(self.wid..text)
        okay=false
      end
    end
    
  end  
  
  -- Check that a transport units.
  if request.transporttype ~= WAREHOUSE.TransportType.SELFPROPELLED then
  
    -- Transports in stock.
    local _transports,_ntransports,_enough=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, request.transporttype, request.ntransport)

    -- Check if enough transport units are available.
    if not _enough then
      local text=string.format("Warehouse %s: Request denied! Not enough transport assets currently available.", self.alias)
      MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
      self:E(self.wid..text)
      okay=false
    end
    
    -- Check if at least one transport asset is available.
    if _ntransports>0 then
    
      -- Get the attibute of the transport units.
      local _transportattribute=_transports[1].attribute
      local _transportcategory=_transports[1].category
      
      -- Check available parking for transport units.
      if self.airbase and (_transportcategory==Group.Category.AIRPLANE or _transportcategory==Group.Category.HELICOPTER) then
        local Parking=self:_FindParkingForAssets(self.airbase,_transports)
        if Parking==nil then
          local text=string.format("Warehouse %s: Request denied! Not enough free parking spots for all transports at the moment.", self.alias)
          MESSAGE:New(text, 5):ToCoalitionIf(self.coalition, self.Report or self.Debug)
          self:E(self.wid..text)
          okay=false
        end
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


--- Seach unoccupied parking spots at the airbase for a list of assets. For each asset group a list of parking spots is returned.
-- During the search also the not yet spawned asset aircraft are considered.
-- If not enough spots for all asset units could be found, the routine returns nil!
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase where we search for parking spots.
-- @param #table assets A table of assets for which the parking spots are needed.
-- @return #table Table of coordinates and terminal IDs of free parking spots. Each table entry has the elements .Coordinate and .TerminalID.
function WAREHOUSE:_FindParkingForAssets(airbase, assets)

  -- Init default
  local scanradius=50
  local scanunits=true
  local scanstatics=true
  local scanscenery=false
  local verysafe=false

  -- Function calculating the overlap of two (square) objects.
  local function _overlap(l1,l2,dist)
    local safedist=(l1/2+l2/2)*1.1
    local safe = (dist > safedist)
    self:T3(string.format("l1=%.1f l2=%.1f s=%.1f d=%.1f ==> safe=%s", l1,l2,safedist,dist,tostring(safe)))
    return safe    
  end
  
  -- Get parking spot data table. This contains all free and "non-free" spots.
  local parkingdata=airbase:GetParkingSpotsTable()
  
  -- List of obstacles.
  local obstacles={}
  
  -- Loop over all parking spots and get the obstacles.
  -- TODO: How long does this take on very large airbases, i.e. those with hundereds of parking spots?
  for _,parkingspot in pairs(parkingdata) do
  
    -- Coordinate of the parking spot.
    local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
    local _termid=parkingspot.TerminalID
    
    -- Obstacles at or around this parking spot.
    obstacles[_termid]={}
            
    -- Scan a radius of 50 meters around the spot.
    local _,_,_,_units,_statics,_sceneries=_spot:ScanObjects(scanradius, scanunits, scanstatics, scanscenery)

    -- Check all units.    
    for _,_unit in pairs(_units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local _coord=unit:GetCoordinate()
      local _size=self:_GetObjectSize(unit:GetDCSObject())
      local _name=unit:GetName()
      table.insert(obstacles[_termid],{coord=_coord, size=_size, name=_name, type="unit"})  
    end
  
    -- Check all statics.
    for _,static in pairs(_statics) do
      local _vec3=static:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=static:getName()
      --env.info("FF static name = "..tostring(_name))
      local _size=self:_GetObjectSize(static)
      table.insert(obstacles[_termid],{coord=_coord, size=_size, name=_name, type="static"})  
    end
    
    -- Check all scenery.
    for _,scenery in pairs(_sceneries) do
      local _vec3=scenery:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=scenery:getTypeName()
      local _size=self:_GetObjectSize(scenery)
      table.insert(obstacles[_termid],{coord=_coord, size=_size, name=_name, type="scenery"})
    end
    
    -- TODO Clients? Unoccupied client aircraft are also important! Are they already included in scanned units maybe?
    --[[
    local clients=_DATABASE.CLIENTS
    for _,_client in pairs(clients) do
      local client=_client --Wrapper.Client#CLIENT
      local unit=client:GetClientGroupUnit()      
      local _coord=unit:GetCoordinate()
      local _name=unit:GetName()
      local _size=self:_GetObjectSize(client:GetClientGroupDCSUnit())
      table.insert(obstacles[_termid],{coord=_coord, size=_size, name=_name, type="client"})
    end
    ]]     
  end
  
  -- Parking data for all assets.
  local parking={}

  -- Loop over all assets that need a parking psot.
  for _,asset in pairs(assets) do
  
    local _asset=asset --#WAREHOUSE.Assetitem
    
    local terminaltype=self:_GetTerminal(asset.attribute)
    
    -- Asset specific parking.
    parking[_asset.uid]={}
    
    -- Loop over all units - each one needs a spot.
    for i=1,_asset.nunits do
  
      -- Loop over all parking spots.
      local gotit=false
      for _,parkingspot in pairs(parkingdata) do
      
        -- Check correct terminal type for asset. We don't want helos in shelters etc.
        if AIRBASE._CheckTerminalType(parkingspot.TerminalType, terminaltype) then
  
          -- Coordinate of the parking spot.
          local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
          local _termid=parkingspot.TerminalID
          local _toac=parkingspot.TOAC
           
          -- Loop over all obstacles.
          local free=true
          local problem=nil
          for _,obstacle in pairs(obstacles[_termid]) do
          
            -- Check if aircraft overlaps with any obstacle.
            local dist=_spot:Get2DDistance(obstacle.coord)
            local safe=_overlap(_asset.size, obstacle.size, dist)
            
            -- Spot is blocked.
            if not safe then
              free=false
              problem=obstacle
              problem.dist=dist
              break
            end
          
          end
          
          if free then
          
            -- Add parkingspot for this asset unit.
            table.insert(parking[_asset.uid], parkingspot)
            
            self:E(self.wid..string.format("Parking spot #%d is free for asset id=%d!", _termid, _asset.uid))
            
            -- Add the unit as obstacle so that this spot will not be available for the next unit.
            -- TODO Alternatively, I could remove this parking spot from the table, right?
            table.insert(obstacles[_termid], {coord=_spot, size=_asset.size, name=_asset.templatename, type="asset"})
            
            gotit=true
            break
          else
            self:E(self.wid..string.format("Parking spot #%d is occupied or not big enough!", _termid))
            local coord=problem.coord --Core.Point#COORDINATE
            local text=string.format("Obstacle blocking spot #%d is %s type %s with size=%.1f m and distance=%.1f m.", _termid, problem.name, problem.type, problem.size, problem.dist)
            coord:MarkToAll(string.format(text))
          end
          
        end -- check terminal type
      end -- loop over parking spots
      
      
      if not gotit then
        self:E(self.wid..string.format("WARNING: No free parking spot for asset id=%d",_asset.uid))
        return nil
      end      
    end -- loop over asset units
  end -- loop over asset groups
    
  return parking
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

--- Creates a unique name for spawned assets. From the group name the original warehouse, global asset and the request can be derived. 
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem _assetitem Asset for which the name is created.
-- @param #WAREHOUSE.Queueitem _queueitem (Optional) Request specific name.
-- @return #string Alias name "UnitType\_WID-%d\_AID-%d\_RID-%d"
function WAREHOUSE:_Alias(_assetitem,_queueitem)
  return self:_alias(_assetitem.unittype, self.uid, _assetitem.uid,_queueitem.uid)
end

--- Creates a unique name for spawned assets. From the group name the original warehouse, global asset and the request can be derived.
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
    self:T3(self.wid..string.format("Group Name   = %s", tostring(name)))  
    self:T3(self.wid..string.format("Warehouse ID = %s", tostring(wid)))
    self:T3(self.wid..string.format("Asset     ID = %s", tostring(aid)))
    self:T3(self.wid..string.format("Request   ID = %s", tostring(rid)))
    
    return wid,aid,rid
  else
    self:E("WARNING: Group not found in GetIDsFromGroup() function!")
  end
      
  
end

--- Filter stock assets by table entry.
-- @param #WAREHOUSE self
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Assetitem}.
-- @param #string item Descriptor
-- @param value Value of the descriptor.
-- @param #number nmax (Optional) Maximum number of items that will be returned. Default nmax=nil is all matching items are returned.
-- @return #table Filtered stock items table.
-- @return #number Total number of (requested) assets available.
-- @return #boolean If true, enough assets are available.
function WAREHOUSE:_FilterStock(stock, item, value, nmax)

  -- Default all.
  nmax=nmax or "all"

  -- Filtered array.
  local filtered={}

  -- Count total number in stock.
  local ntot=0
  for _,_stock in ipairs(stock) do
    if _stock[item]==value then
      ntot=ntot+1
    end
  end
  
  -- Treat case where ntot=0, i.e. no assets at all.
  if ntot==0 then
    return filtered, ntot, false
  end
  
  -- Handle string input for nmax.
  if type(nmax)=="string" then
    if nmax:lower()=="all" then
      nmax=ntot
    elseif nmax:lower()=="half" then
      nmax=ntot/2
    elseif nmax:lower()=="third" then
      nmax=ntot/3      
    elseif nmax:lower()=="quarter" then
      nmax=ntot/4
    elseif nmax:lower()=="fivth" then
      nmax=ntot/5
    else
      nmax=math.min(1,ntot)
    end
  end

  -- Loop over stock items.
  for _i,_stock in ipairs(stock) do
    if _stock[item]==value then
      _stock.pos=_i
      table.insert(filtered, _stock)
      if nmax~=nil and #filtered>=nmax then
        return filtered, ntot, true
      end
    end
  end

  return filtered, ntot, ntot>=nmax
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
    -- TODO: need to work on ships and trucks and SAMs and ...
    -- Also the Yak-52 for example is OTHER since it only has the attribute "Battleplanes".
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
    elseif bomber then
      attribute=WAREHOUSE.Attribute.BOMBER
    elseif artillery then
      attribute=WAREHOUSE.Attribute.ARTILLERY
    elseif infantry then
      attribute=WAREHOUSE.Attribute.INFANTRY
    elseif attackhelicopter then
      attribute=WAREHOUSE.Attribute.ATTACKHELICOPTER
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

--- Size of the bounding box of a DCS object derived from the DCS descriptor table. If boundinb box is nil, a size of zero is returned.
-- @param #WAREHOUSE self
-- @param DCS#Object DCSobject The DCS object for which the size is needed.
-- @return #number Max size of object in meters.
function WAREHOUSE:_GetObjectSize(DCSobject)
  local DCSdesc=DCSobject:getDesc()
  if DCSdesc.box then
    local x=DCSdesc.box.max.x+math.abs(DCSdesc.box.min.x)  --length
    local y=DCSdesc.box.max.y+math.abs(DCSdesc.box.min.y)  --height
    local z=DCSdesc.box.max.z+math.abs(DCSdesc.box.min.z)  --width
    return math.max(x,z), x , y, z
  end
  return 0,0,0,0
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
      local _ite=_item --#WAREHOUSE.Assetitem
      if _ite.attribute==_attribute then
        n=n+1
      end
    end

    _data[_attribute]=n
  end

  return _data
end

--- Delete an asset item from stock.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem stockitem Asset item to delete from stock table.
function WAREHOUSE:_DeleteStockItem(stockitem)
  for i=1,#self.stock do
    local item=self.stock[i] --#WAREHOUSE.Assetitem
    if item.uid==stockitem.uid then
      table.remove(self.stock,i)
      break
    end
  end
end

--- Delete item from queue.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem qitem Item of queue to be removed.
-- @param #table queue The queue from which the item should be deleted.
function WAREHOUSE:_DeleteQueueItem(qitem, queue)
  self:F({qitem=qitem, queue=queue})
  
  for i=1,#queue do
    local _item=queue[i] --#WAREHOUSE.Queueitem
    if _item.uid==qitem.uid then
      self:E(self.wid..string.format("Deleting queue item %d.", qitem.uid))
      table.remove(queue,i)
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
  local text=string.format("%s at %s: ",name, self.alias)
  for _,_qitem in ipairs(queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem
    -- Set airbase:
    local airbasename="none"
    if qitem.airbase then
      airbasename=qitem.airbase:GetName()
    end      
    text=text..string.format("\nUID=%d, Prio=%d, Requestor=%s, Airbase=%s (category=%d), Descriptor: %s=%s, Nasssets=%s, Transport=%s, Ntransport=%d.",
    qitem.uid, qitem.prio, qitem.warehouse.alias, airbasename, qitem.category, qitem.assetdesc,tostring(qitem.assetdescval), tostring(qitem.nasset), qitem.transporttype, qitem.ntransport)
  end
  if #queue==0 then
    text=text.."Empty."
  end
  self:E(self.wid..text)
end

--- Display status of warehouse.
-- @param #WAREHOUSE self
function WAREHOUSE:_DisplayStatus()

  -- Set airbase name.
  local airbasename="none"
  if self.airbase then
    airbasename=self.airbase:GetName()
  end
  
  local text=string.format("\n------------------------------------------------------\n")
  text=text..string.format("Warehouse %s status:\n", self.alias)
  text=text..string.format("------------------------------------------------------\n")
  text=text..string.format("Current status   = %s\n", self:GetState())
  text=text..string.format("Coalition side   = %d\n", self.coalition)
  text=text..string.format("Country name     = %d\n", self.country)
  text=text..string.format("Airbase name     = %s\n", airbasename)
  text=text..string.format("Queued requests  = %d\n", #self.queue)
  text=text..string.format("Pending requests = %d\n", #self.pending)
  text=text..string.format("------------------------------------------------------\n")
  text=text..self:_GetStockAssetsText()
  env.info(text)
  --TODO: number of ground, air, naval assets.
end

--- Get text about warehouse stock.
-- @param #WAREHOUSE self
-- @param #boolean messagetoall If true, send message to all.
-- @return #string Text about warehouse stock
function WAREHOUSE:_GetStockAssetsText(messagetoall)

  -- Get assets in stock.
  local _data=self:GetStockInfo(self.stock)
  
  -- Text.  
  local text="Stock:\n"
  for _attribute,_count in pairs(_data) do
    text=text..string.format("%s = %d\n", _attribute,_count)
  end
  text=text..string.format("------------------------------------------------------\n")
  
  -- Send message?
  MESSAGE:New(text, 10):ToAllIf(messagetoall)
  
  return text
end

--- Create or update mark text at warehouse, which is displayed in F10 map.
-- Only the coaliton of the warehouse owner is able to see it.
-- @param #WAREHOUSE self
-- @return #string Text about warehouse stock
function WAREHOUSE:_UpdateWarehouseMarkText()

  -- Create a mark with the current assets in stock.
  if self.markerid~=nil then
    trigger.action.removeMark(self.markerid)
  end
  
  -- Get assets in stock.
  local _data=self:GetStockInfo(self.stock)
  
  -- Create mark text.
  local marktext="Warehouse stock:\n"
  for _attribute,_count in pairs(_data) do
    marktext=marktext..string.format("%s=%d, ", _attribute,_count) -- Dont use \n because too many make DCS crash!
  end

  -- Create/update marker at warehouse in F10 map.
  self.markerid=self.coordinate:MarkToCoalition(marktext, self.coalition, true)
end

--- Display stock items of warehouse.
-- @param #WAREHOUSE self
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Assetitem}.
function WAREHOUSE:_DisplayStockItems(stock)

  local text=self.wid..string.format("Warehouse %s stock assets:\n", self.airbase:GetName())
  for _,_stock in pairs(stock) do
    local mystock=_stock --#WAREHOUSE.Assetitem
    text=text..string.format("template = %s, category = %d, unittype = %s, attribute = %s\n", mystock.templatename, mystock.category, mystock.unittype, mystock.attribute)
  end

  env.info(text)
  MESSAGE:New(text, 10):ToAll()
end

--- Fireworks!
-- @param #WAREHOUSE self
-- @param Core.Point#COORDINATE coord
function WAREHOUSE:_Fireworks(coord)

  -- Place.
  coord=coord or self.coordinate

  -- Fireworks!
  for i=1,91 do
    local color=math.random(0,3)
    coord:Flare(color, i-1)
  end
end

--- Make a flight plan from a departure to a destination airport. 
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset 
-- @param Wrapper.Airbase#AIRBASE departure Departure airbase.
-- @param Wrapper.Airbase#AIRBASE destination Destination airbase.
-- @return #table Table of flightplan waypoints.
-- @return #table Table of flightplan coordinates. 
function WAREHOUSE:_GetFlightplan(asset, departure, destination)
  
  -- Parameters in SI units.
  local Vmax=asset.speedmax/3.6
  local Range=asset.range
  local _category=asset.category
  local ceiling=asset.DCSdesc.Hmax
  local Vymax=asset.DCSdesc.VyMax
    
  -- Max cruise speed 90% of max speed.
  local VxCruiseMax=0.90*Vmax

  -- Min cruise speed 70% of max cruise or 600 km/h whichever is lower.
  local VxCruiseMin = math.min(VxCruiseMax*0.70, 166)
  
  -- Cruise speed (randomized). Expectation value at midpoint between min and max.
  local VxCruise = UTILS.RandomGaussian((VxCruiseMax-VxCruiseMin)/2+VxCruiseMin, (VxCruiseMax-VxCruiseMax)/4, VxCruiseMin, VxCruiseMax)
  
  -- Climb speed 90% ov Vmax but max 720 km/h.
  local VxClimb = math.min(Vmax*0.90, 200)
  
  -- Descent speed 60% of Vmax but max 500 km/h.
  local VxDescent = math.min(Vmax*0.60, 140)
  
  -- Holding speed is 90% of descent speed.
  local VxHolding = VxDescent*0.9
  
  -- Final leg is 90% of holding speed.
  local VxFinal = VxHolding*0.9
  
  -- Reasonably civil climb speed Vy=1500 ft/min = 7.6 m/s but max aircraft specific climb rate.
  local VyClimb=math.min(7.6, Vymax)
  
  -- Climb angle in rad.
  local AlphaClimb=math.asin(VyClimb/VxClimb)
  
  -- Descent angle in rad. Moderate 4 degrees.
  local AlphaDescent=math.rad(4)
  
  -- Expected cruise level (peak of Gaussian distribution)
  local FLcruise_expect=150*RAT.unit.FL2m
  
  --- DEPARTURE AIRPORT
  
  -- Coordinates of departure point.
  local Pdeparture=departure:GetCoordinate()
  
  -- Height ASL of departure point.
  local H_departure=Pdeparture.y
   
  --- DESTINATION AIRPORT
  
  -- Position of destination airport.
  local Pdestination=destination:GetCoordinate()
  
  -- Height ASL of destination airport/zone.
  local H_destination=Pdestination.y
    
  --- DESCENT/HOLDING POINT

  -- Get a random point between 5 and 10 km away from the destination.
  local Rhmin=5000
  local Rhmax=10000
  if _category==Group.Category.HELICOPTER then
    -- For helos we set a distance between 500 to 1000 m.
    Rhmin=500
    Rhmax=1000
  end
  
  -- Coordinates of the holding point. y is the land height at that point.
  --local Vholding=Pdestination:GetRandomVec2InRadius(Rhmax, Rhmin)
  --local Pholding=COORDINATE:NewFromVec2(Vholding)
  local Pholding=Pdestination:GetRandomCoordinateInRadius(Rhmax, Rhmin)
  
  -- AGL height of holding point.
  local H_holding=Pholding.y
  
  -- Holding point altitude. For planes between 1600 and 2400 m AGL. For helos 160 to 240 m AGL.
  local h_holding=1200
  if _category==Group.Category.HELICOPTER then
    h_holding=150
  end
  h_holding=UTILS.Randomize(h_holding, 0.2)
  
  -- This is the actual height ASL of the holding point we want to fly to
  local Hh_holding=H_holding+h_holding
    
  -- Distance from holding point to final destination.
  local d_holding=Pholding:Get2DDistance(Pdestination)
  
  -- GENERAL
  local heading=Pdeparture:HeadingTo(Pdestination)
  local d_total=Pdeparture:Get2DDistance(Pholding)

  --------------------------------------------
  
  -- Height difference between departure and destination.
  local deltaH=math.abs(H_departure-Hh_holding)
  
  -- Slope between departure and destination.
  local phi = math.atan(deltaH/d_total)
  
  -- Adjusted climb/descent angles.
  local phi_climb
  local phi_descent
  if (H_departure > Hh_holding) then
    phi_climb=AlphaClimb+phi
    phi_descent=AlphaDescent-phi
  else
    phi_climb=AlphaClimb-phi
    phi_descent=AlphaDescent+phi
  end

  -- Total distance including slope.
  local D_total=math.sqrt(deltaH*deltaH+d_total*d_total)
  
  -- SSA triangle for sloped case.
  local gamma=math.rad(180)-phi_climb-phi_descent
  local a = D_total*math.sin(phi_climb)/math.sin(gamma)
  local b = D_total*math.sin(phi_descent)/math.sin(gamma)
  local hphi_max  = b*math.sin(phi_climb)
  local hphi_max2 = a*math.sin(phi_descent)
  
  -- Height of triangle.
  local h_max1 = b*math.sin(AlphaClimb)
  local h_max2 = a*math.sin(AlphaDescent)
  
  -- Max height relative to departure or destination.
  local h_max
  if (H_departure > Hh_holding) then
    h_max=math.min(h_max1, h_max2)
  else
    h_max=math.max(h_max1, h_max2)
  end
  
  -- Max flight level aircraft can reach for given angles and distance.
  local FLmax = h_max+H_departure
      
  --CRUISE  
  -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
  local FLmin=math.max(H_departure, Hh_holding)
   
  -- For helicopters we take cruise alt between 50 to 1000 meters above ground. Default cruise alt is ~150 m.
  if _category==Group.Category.HELICOPTER then  
    FLmin=math.max(H_departure, H_destination)+50
    FLmax=math.max(H_departure, H_destination)+1000
  end
  
  -- Ensure that FLmax not above its service ceiling.
  FLmax=math.min(FLmax, ceiling)
  
  -- If the route is very short we set FLmin a bit lower than FLmax.
  if FLmin>FLmax then
    FLmin=FLmax
  end
  
  -- Expected cruise altitude - peak of gaussian distribution.
  if FLcruise_expect<FLmin then
    FLcruise_expect=FLmin
  end
  if FLcruise_expect>FLmax then
    FLcruise_expect=FLmax
  end
    
  -- Set cruise altitude. Selected from Gaussian distribution but limited to FLmin and FLmax.
  local FLcruise=UTILS.RandomGaussian(FLcruise_expect, math.abs(FLmax-FLmin)/4, FLmin, FLmax)

  -- Climb and descent heights.
  local h_climb   = FLcruise - H_departure
  local h_descent = FLcruise - Hh_holding
  
  -- Distances.
  local d_climb   = h_climb/math.tan(AlphaClimb)
  local d_descent = h_descent/math.tan(AlphaDescent)
  local d_cruise  = d_total-d_climb-d_descent
  
  -- Debug.
  local text=string.format("Flight plan:\n")
  text=text..string.format("Vx max       = %d\n", Vmax)
  text=text..string.format("Vx climb     = %d\n", VxClimb)
  text=text..string.format("Vx cruise    = %d\n", VxCruise)
  text=text..string.format("Vx descent   = %d\n", VxDescent)
  text=text..string.format("Vx holding   = %d\n", VxHolding)
  text=text..string.format("Vx final     = %d\n", VxFinal)
  text=text..string.format("Dist climb   = %d\n", d_climb)
  text=text..string.format("Dist cruise  = %d\n", d_cruise)
  text=text..string.format("Dist descent = %d\n", d_descent)
  text=text..string.format("Dist total   = %d\n", d_total)
  text=text..string.format("FL min       = %d\n", FLmin)
  text=text..string.format("FL cruise *  = %d\n", FLcruise)
  text=text..string.format("FL max       = %d\n", FLmax)
  text=text..string.format("Ceiling      = %d\n", ceiling)
  env.info(text)
    
  -- Ensure that cruise distance is positve. Can be slightly negative in special cases. And we don't want to turn back.
  if d_cruise<0 then
    d_cruise=100
  end

  -- Waypoints and coordinates
  local wp={}
  local c={}
  
  --- Departure/Take-off
  c[#c+1]=Pdeparture
  wp[#wp+1]=Pdeparture:WaypointAir("RADIO", COORDINATE.WaypointType.TakeOffParking, COORDINATE.WaypointAction.FromParkingArea, VxClimb, true, departure, nil, "Departure")
  
  --- Climb 
  local Pclimb=Pdeparture:Translate(d_climb/2, heading)
  Pclimb.y=H_departure+(FLcruise-H_departure)/2
  c[#c+1]=Pclimb
  wp[#wp+1]=Pclimb:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxClimb, true, nil, nil, "Climb")
  
  --- Begin of Cruise
  local Pcruise1=Pclimb:Translate(d_climb/2, heading)
  Pcruise1.y=FLcruise
  c[#c+1]=Pcruise1
  wp[#wp+1]=Pcruise1:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxCruise, true, nil, nil, "Begin of Cruise")

  --- End of Cruise    
  local Pcruise2=Pcruise1:Translate(d_cruise, heading)
  Pcruise2.y=FLcruise
  c[#c+1]=Pcruise2
  wp[#wp+1]=Pcruise2:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxCruise, true, nil, nil, "End of Cruise")

  --- Descent  
  local Pdescent=Pcruise2:Translate(d_descent/2, heading)
  Pdescent.y=FLcruise-(FLcruise-(h_holding+H_holding))/2
  c[#c+1]=Pdescent
  wp[#wp+1]=Pcruise2:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxDescent, true, nil, nil, "Descent")
    
  --- Holding point
   Pholding.y=H_holding+h_holding  
  c[#c+1]=Pholding
  wp[#wp+1]=Pholding:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxHolding, true, nil, nil, "Holding")  

  --- Final destination.  
  c[#c+1]=Pdestination
  wp[#wp+1]=Pcruise2:WaypointAir("RADIO", COORDINATE.WaypointType.Land, COORDINATE.WaypointAction.Landing, VxFinal, true,  destination, nil, "Final Destination")
    
  return wp,c
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

