--- **Functional** - Simulation of logistic operations.
--
-- ===
--
-- ## Features:
--
--    * Holds (virtual) assets in stock and spawns them upon request.
--    * Manages requests of assets from other warehouses.
--    * Queueing system with optional prioritization of requests.
--    * Realistic transportation of assets between warehouses.
--    * Different means of automatic transportation (planes, helicopters, APCs, self propelled).
--    * Strategic components such as capturing, defending and destroying warehouses and their associated infrastructure.
--    * Intelligent spawning of aircraft on airports (only if enough parking spots are available).
--    * Possibility to hook into events and customize actions.
--    * Persistence of assets. Warehouse assets can be saved and loaded from file.
--    * Can be easily interfaced to other MOOSE classes.
--
-- ===
--
-- ## Youtube Videos:
--
--    * [Warehouse Trailer](https://www.youtube.com/watch?v=e98jzLi5fGk)
--    * [DCS Warehouse Airbase Resources Proof Of Concept](https://www.youtube.com/watch?v=YeuGL0duEgY)
--
-- ===
--
-- ## Missions:
--
-- ===
--
-- The MOOSE warehouse concept simulates the organization and implementation of complex operations regarding the flow of assets between the point of origin and the point of consumption
-- in order to meet requirements of a potential conflict. In particular, this class is concerned with maintaining army supply lines while disrupting those of the enemy, since an armed
-- force without resources and transportation is defenseless.
--
-- ===
--
-- ### Author: **funkyfranky**
-- ### Co-author: FlightControl (cargo dispatcher classes)
--
-- ===
--
-- @module Functional.Warehouse
-- @image Warehouse.JPG

--- WAREHOUSE class.
-- @type WAREHOUSE
-- @field #string ClassName Name of the class.
-- @field #boolean Debug If true, send debug messages to all.
-- @field #number verbosity Verbosity level.
-- @field #string wid Identifier of the warehouse printed before other output to DCS.log file.
-- @field #boolean Report If true, send status messages to coalition.
-- @field Wrapper.Static#STATIC warehouse The phyical warehouse structure.
-- @field #string alias Alias of the warehouse. Name its called when sending messages.
-- @field Core.Zone#ZONE zone Zone around the warehouse. If this zone is captured, the warehouse and all its assets goes to the capturing coalition.
-- @field Wrapper.Airbase#AIRBASE airbase Airbase the warehouse belongs to.
-- @field #string airbasename Name of the airbase associated to the warehouse.
-- @field Core.Point#COORDINATE road Closest point to warehouse on road.
-- @field Core.Point#COORDINATE rail Closest point to warehouse on rail.
-- @field Core.Zone#ZONE spawnzone Zone in which assets are spawned.
-- @field #number uid Unique ID of the warehouse.
-- @field #boolean markerOn If true, markers are displayed on the F10 map.
-- @field Wrapper.Marker#MARKER markerWarehouse Marker warehouse.
-- @field Wrapper.Marker#MARKER markerRoad Road connection.
-- @field Wrapper.Marker#MARKER markerRail Rail road connection.
-- @field #number markerid ID of the warehouse marker at the airbase.
-- @field #number dTstatus Time interval in seconds of updating the warehouse status and processing new events. Default 30 seconds.
-- @field #number queueid Unit id of each request in the queue. Essentially a running number starting at one and incremented when a new request is added.
-- @field #table stock Table holding all assets in stock. Table entries are of type @{#WAREHOUSE.Assetitem}.
-- @field #table queue Table holding all queued requests. Table entries are of type @{#WAREHOUSE.Queueitem}.
-- @field #table pending Table holding all pending requests, i.e. those that are currently in progress. Table elements are of type @{#WAREHOUSE.Pendingitem}.
-- @field #table transporting Table holding assets currently transporting cargo assets.
-- @field #table delivered Table holding all delivered requests. Table elements are #boolean. If true, all cargo has been delivered.
-- @field #table defending Table holding all defending requests, i.e. self requests that were if the warehouse is under attack. Table elements are of type @{#WAREHOUSE.Pendingitem}.
-- @field Core.Zone#ZONE portzone Zone defining the port of a warehouse. This is where naval assets are spawned.
-- @field #table shippinglanes Table holding the user defined shipping between warehouses.
-- @field #table offroadpaths Table holding user defined paths from one warehouse to another.
-- @field #boolean autodefence When the warehouse is under attack, automatically spawn assets to defend the warehouse.
-- @field #number spawnzonemaxdist Max distance between warehouse and spawn zone. Default 5000 meters.
-- @field #boolean autosave Automatically save assets to file when mission ends.
-- @field #string autosavepath Path where the asset file is saved on auto save.
-- @field #string autosavefile File name of the auto asset save file. Default is auto generated from warehouse id and name.
-- @field #boolean safeparking If true, parking spots for aircraft are considered as occupied if e.g. a client aircraft is parked there. Default false.
-- @field #boolean isUnit If `true`, warehouse is represented by a unit instead of a static.
-- @field #boolean isShip If `true`, warehouse is represented by a ship unit.
-- @field #number lowfuelthresh Low fuel threshold. Triggers the event AssetLowFuel if for any unit fuel goes below this number.
-- @field #boolean respawnafterdestroyed If true, warehouse is respawned after it was destroyed. Assets are kept.
-- @field #number respawndelay Delay before respawn in seconds.
-- @field #number runwaydestroyed Time stamp timer.getAbsTime() when the runway was destroyed.
-- @field #number runwayrepairtime Time in seconds until runway will be repaired after it was destroyed. Default is 3600 sec (one hour).
-- @field OPS.FlightControl#FLIGHTCONTROL flightcontrol Flight control of this warehouse.
-- @extends Core.Fsm#FSM

--- Have your assets at the right place at the right time - or not!
--
-- ===
--
-- # The Warehouse Concept
--
-- The MOOSE warehouse adds a new logistic component to the DCS World. *Assets*, i.e. ground, airborne and naval units, can be transferred from one place
-- to another in a realistic and highly automatic fashion. In contrast to a "DCS warehouse" these assets have a physical representation in game. In particular,
-- this means they can be destroyed during the transport and add more life to the DCS world.
--
-- This comes along with some additional interesting strategic aspects since capturing/defending and destroying/protecting an enemy or your
-- own warehouse becomes of critical importance for the development of a conflict.
--
-- In essence, creating an efficient network of warehouses is vital for the success of a battle or even the whole war. Likewise, of course, cutting off the enemy
-- of important supply lines by capturing or destroying warehouses or their associated infrastructure is equally important.
--
-- ## What is a warehouse?
--
-- A warehouse is an abstract object represented by a physical (static) building that can hold virtual assets in stock.
-- It can (but it must not) be associated with a particular airbase. The associated airbase can be an airdrome, a Helipad/FARP or a ship.
--
-- If another warehouse requests assets, the corresponding troops are spawned at the warehouse and being transported to the requestor or go their
-- by themselfs. Once arrived at the requesting warehouse, the assets go into the stock of the requestor and can be activated/deployed when necessary.
--
-- ## What assets can be stored?
--
-- Any kind of ground, airborne or naval asset can be stored and are spawned upon request.
-- The fact that the assets live only virtually in stock and are put into the game only when needed has a positive impact on the game performance.
-- It also alliviates the problem of limited parking spots at smaller airbases.
--
-- ## What means of transportation are available?
--
-- Firstly, all mobile assets can be send from warehouse to another on their own.
--
-- * Ground vehicles will use the road infrastructure. So a good road connection for both warehouses is important but also off road connections can be added if necessary.
-- * Airborne units get a flightplan from the airbase of the sending warehouse to the airbase of the receiving warehouse. This already implies that for airborne
-- assets both warehouses need an airbase. If either one of the warehouses does not have an associated airbase, direct transportation of airborne assets is not possible.
-- * Naval units can be exchanged between warehouses which possess a port, which can be defined by the user. Also shipping lanes must be specified manually but the user since DCS does not provide these.
-- * Trains (would) use the available railroad infrastructure and both warehouses must have a connection to the railroad. Unfortunately, however, trains are not yet implemented to
-- a reasonable degree in DCS at the moment and hence cannot be used yet.
--
-- Furthermore, ground assets can be transferred between warehouses by transport units. These are APCs, helicopters and airplanes. The transportation process is modeled
-- in a realistic way by using the corresponding cargo dispatcher classes, i.e.
--
-- * @{AI.AI_Cargo_Dispatcher_APC#AI_DISPATCHER_APC}
-- * @{AI.AI_Cargo_Dispatcher_Helicopter#AI_DISPATCHER_HELICOPTER}
-- * @{AI.AI_Cargo_Dispatcher_Airplane#AI_DISPATCHER_AIRPLANE}
--
-- Depending on which cargo dispatcher is used (ground or airbore), similar considerations like in the self propelled case are necessary. Howver, note that
-- the dispatchers as of yet cannot use user defined off road paths for example since they are classes of their own and use a different routing logic.
--
-- ===
--
-- # Creating a Warehouse
--
-- A MOOSE warehouse must be represented in game by a physical *static* object. For example, the mission editor already has warehouse as static object available.
-- This would be a good first choice but any static object will do.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Static.png)
--
-- The positioning of the warehouse static object is very important for a couple of reasons. Firstly, a warehouse needs a good infrastructure so that spawned assets
-- have a proper road connection or can reach the associated airbase easily.
--
-- ## Constructor and Start
--
-- Once the static warehouse object is placed in the mission editor it can be used as a MOOSE warehouse by the @{#WAREHOUSE.New}(*warehousestatic*, *alias*) constructor,
-- like for example:
--
--     warehouseBatumi=WAREHOUSE:New(STATIC:FindByName("Warehouse Batumi"), "My optional Warehouse Alias")
--     warehouseBatumi:Start()
--
-- The first parameter *warehousestatic* is the static MOOSE object. By default, the name of the warehouse will be the same as the name given to the static object.
-- The second parameter *alias* is optional and can be used to choose a more convenient name if desired. This will be the name the warehouse calls itself when reporting messages.
--
-- Note that a warehouse also needs to be started in order to be in service. This is done with the @{#WAREHOUSE.Start}() or @{#WAREHOUSE.__Start}(*delay*) functions.
-- The warehouse is now fully operational and requests are being processed.
--
-- # Adding Assets
--
-- Assets can be added to the warehouse stock by using the @{#WAREHOUSE.AddAsset}(*group*, *ngroups*, *forceattribute*, *forcecargobay*, *forceweight*, *loadradius*, *skill*, *liveries*, *assignment*) function.
-- The parameter *group* has to be a MOOSE @{Wrapper.Group#GROUP}. This is also the only mandatory parameters. All other parameters are optional and can be used for fine tuning if
-- nessary. The parameter *ngroups* specifies how many clones of this group are added to the stock.
--
--     infrantry=GROUP:FindByName("Some Infantry Group")
--     warehouseBatumi:AddAsset(infantry, 5)
--
-- This will add five infantry groups to the warehouse stock. Note that the group should normally be a late activated template group,
-- which was defined in the mission editor. But you can also add other groups which are already spawned and present in the mission.
--
-- Also note that the coalition of the template group (red, blue or neutral) does not matter. The coalition of the assets is determined by the coalition of the warehouse owner.
-- In other words, it is no problem to add red groups to blue warehouses and vice versa. The assets will automatically have the coalition of the warehouse.
--
-- You can add assets with a delay by using the @{#WAREHOUSE.__AddAsset}(*delay*, *group*, *ngroups*, *forceattribute*, *forcecargobay*, *forceweight*, *loadradius*,  *skill*, *liveries*, *assignment*),
-- where *delay* is the delay in seconds before the asset is added.
--
-- In game, the warehouse will get a mark which is regularly updated and showing the currently available assets in stock.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Stock-Marker.png)
--
-- ## Optional Parameters for Fine Tuning
--
-- By default, the generalized attribute of the asset is determined automatically from the DCS descriptor attributes. However, this might not always result in the desired outcome.
-- Therefore, it is possible, to force a generalized attribute for the asset with the third optional parameter *forceattribute*, which is of type @{#WAREHOUSE.Attribute}.
--
-- ### Setting the Generalized Attibute
-- For example, a UH-1H Huey has in DCS the attibute of an attack helicopter. But of course, it can also transport cargo. If you want to use it for transportation, you can specify this
-- manually when the asset is added
--
--     warehouseBatumi:AddAsset("Huey", 5, WAREHOUSE.Attribute.AIR_TRANSPORTHELO)
--
-- This becomes important when assets are requested from other warehouses as described below. In this case, the five Hueys are now marked as transport helicopters and
-- not attack helicopters. This is also particularly useful when adding assets to a warehouse with the intention of using them to transport other units that are part of 
-- a subsequent request (see below). Setting the attribute will help to ensure that warehouse module can find the correct unit when attempting to service a request in its
-- queue. For example, if we want to add an Amphibious Landing Ship, even though most are indeed armed, it's recommended to do the following:
-- 
--     warehouseBatumi:AddAsset("Landing Ship", 1, WAREHOUSE.Attribute.NAVAL_UNARMEDSHIP)
--
-- Then when adding the request, you can simply specify WAREHOUSE.TransportType.SHIP (which corresponds to NAVAL_UNARMEDSHIP) as the TransportType.
--
-- ### Setting the Cargo Bay Weight Limit
-- You can ajust the cargo bay weight limit, in case it is not calculated correctly automatically. For example, the cargo bay of a C-17A is much smaller in DCS than that of a C-130, which is
-- unrealistic. This can be corrected by the *forcecargobay* parmeter which is here set to 77,000 kg
--
--     warehouseBatumi:AddAsset("C-17A", nil, nil, 77000)
--
-- The size of the cargo bay is only important when the group is used as transport carrier for other assets.
--
-- ### Setting the Weight
-- If an asset shall be transported by a carrier it important to note that - as in real life - a carrier can only carry cargo up to a certain weight. The weight of the
-- units is automatically determined from the DCS descriptor table.
-- However, in the current DCS version (2.5.3) a mortar unit has a weight of 5 tons. This confuses the transporter logic, because it appears to be too have for, e.g. all APCs.
--
-- As a workaround, you can manually adjust the weight by the optional *forceweight* parameter:
--
--     warehouseBatumi:AddAsset("Mortar Alpha", nil, nil, nil, 210)
--
--  In this case we set it to 210 kg. Note, the weight value set is meant for *each* unit in the group. Therefore, a group consisting of three mortars will have a total weight
--  of 630 kg. This is important as groups cannot be split between carrier units when transporting, i.e. the total weight of the whole group must be smaller than the
--  cargo bay of the transport carrier.
--
-- ### Setting the Load Radius
-- Boading and loading of cargo into a carrier is modeled in a realistic fashion in the AI\_CARGO\DISPATCHER classes, which are used inernally by the WAREHOUSE class.
-- Meaning that troops (cargo) will board, i.e. run or drive to the carrier, and only once they are in close proximity to the transporter they will be loaded (disappear).
--
-- Unfortunately, there are some situations where problems can occur. For example, in DCS tanks have the strong tentendcy not to drive around obstacles but rather to roll over them.
-- I have seen cases where an aircraft of the same coalition as the tank was in its way and the tank drove right through the plane waiting on a parking spot and destroying it.
--
-- As a workaround it is possible to set a larger load radius so that the cargo units are despawned further away from the carrier via the optional **loadradius** parameter:
--
--     warehouseBatumi:AddAsset("Leopard 2", nil, nil, nil, nil, 250)
--
-- Adding the asset like this will cause the units to be loaded into the carrier already at a distance of 250 meters.
--
-- ### Setting the AI Skill
--
-- By default, the asset has the skill of its template group. The optional parameter *skill* allows to set a different skill when the asset is added. See the
-- [hoggit page](https://wiki.hoggitworld.com/view/DCS_enum_AI) possible values of this enumerator.
-- For example you can use
--
--     warehouseBatumi:AddAsset("Leopard 2", nil, nil, nil, nil, nil, AI.Skill.EXCELLENT)
--
-- do set the skill of the asset to excellent.
--
-- ### Setting Liveries
--
-- By default ,the asset uses the livery of its template group. The optional parameter *liveries* allows to define one or multiple liveries.
-- If multiple liveries are given in form of a table of livery names, each asset gets a random one.
--
-- For example
--
--     warehouseBatumi:AddAsset("Mi-8", nil, nil, nil, nil, nil, nil, "China UN")
--
-- would spawn the asset with a Chinese UN livery.
--
-- Or
--
--     warehouseBatumi:AddAsset("Mi-8", nil, nil, nil, nil, nil, nil, {"China UN", "German"})
--
-- would spawn the asset with either a Chinese UN or German livery. Mind the curly brackets **{}** when you want to specify multiple liveries.
--
-- Four each unit type, the livery names can be found in the DCS root folder under Bazar\Liveries. You have to use the name of the livery subdirectory. The names of the liveries
-- as displayed in the mission editor might be different and won't work in general.
--
-- ### Setting an Assignment
--
-- Assets can be added with a specific assignment given as a text, e.g.
--
--     warehouseBatumi:AddAsset("Mi-8", nil, nil, nil, nil, nil, nil, nil, "Go to Warehouse Kobuleti")
--
-- This is helpful to establish supply chains once an asset has arrived at its (first) destination and is meant to be forwarded to another warehouse.
--
-- ## Retrieving the Asset
--
-- Once a an asset is added to a warehouse, the @{#WAREHOUSE.NewAsset} event is triggered. You can hook into this event with the @{#WAREHOUSE.OnAfterNewAsset}(*asset*, *assignment*) function.
--
-- The first parameter *asset* is a table of type @{#WAREHOUSE.Assetitem} and contains a lot of information about the asset. The seconed parameter *assignment* is optional and is the specific
-- assignment the asset got when it was added.
--
-- Note that the assignment is can also be the assignment that was specified when adding a request (see next section). Once an asset that was requested from another warehouse and an assignment
-- was specified in the @{#WAREHOUSE.AddRequest} function, the assignment can be checked when the asset has arrived and is added to the receiving warehouse.
--
-- ===
--
-- # Requesting Assets
--
-- Assets of the warehouse can be requested by other MOOSE warehouses. A request will first be scrutinized to check if can be fulfilled at all. If the request is valid, it is
-- put into the warehouse queue and processed as soon as possible.
--
-- Requested assets spawn in various "Rule of Engagement Rules" (ROE) and Alerts modes. If your assets will cross into dangerous areas, be sure to change these states. You can do this in @{#WAREHOUSE:OnAfterAssetSpawned}(*From, *Event, *To, *group, *asset, *request)) function.
--
-- Initial Spawn states is as follows:
--    GROUND: ROE, "Return Fire" Alarm, "Green"
--    AIR:  ROE, "Return Fire" Reaction to Threat, "Passive Defense"
--    NAVAL ROE, "Return Fire" Alarm,"N/A"
--
-- A request can be added by the @{#WAREHOUSE.AddRequest}(*warehouse*, *AssetDescriptor*, *AssetDescriptorValue*, *nAsset*, *TransportType*, *nTransport*, *Prio*, *Assignment*) function.
-- The parameters are
--
-- * *warehouse*: The requesting MOOSE @{#WAREHOUSE}. Assets will be delivered there.
-- * *AssetDescriptor*: The descriptor to describe the asset "type". See the @{#WAREHOUSE.Descriptor} enumerator. For example, assets requested by their generalized attibute.
-- * *AssetDescriptorValue*: The value of the asset descriptor.
-- * *nAsset*: (Optional) Number of asset group requested. Default is one group.
-- * *TransportType*: (Optional) The transport method used to deliver the assets to the requestor. Default is that assets go to the requesting warehouse on their own.
-- * *nTransport*: (Optional) Number of asset groups used to transport the cargo assets from A to B. Default is one group.
-- * *Prio*: (Optional) A number between 1 (high) and 100 (low) describing the priority of the request. Request with high priority are processed first. Default is 50, i.e. medium priority.
-- * *Assignment*: (Optional) A free to choose string describing the assignment. For self requests, this can be used to assign the spawned groups to specific tasks.
--
-- ## Requesting by Generalized Attribute
--
-- Generalized attributes are similar to [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes). However, they are a bit more general and
-- an asset can only have one generalized attribute by which it is characterized.
--
-- For example:
--
--     warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 5, WAREHOUSE.TransportType.APC, 2)
--
-- Here, warehouse Kobuleti requests 5 infantry groups from warehouse Batumi. These "cargo" assets should be transported from Batumi to Kobuleti by 2 APCS.
-- Note that the warehouse at Batumi needs to have at least five infantry groups and two APC groups in their stock if the request can be processed.
-- If either to few infantry or APC groups are available when the request is made, the request is held in the warehouse queue until enough cargo and
-- transport assets are available.
--
-- Also note that the above request is for five infantry groups. So any group in stock that has the generalized attribute "GROUND_INFANTRY" can be selected for the request.
--
-- ### Generalized Attributes
--
-- Currently implemented are:
--
-- * @{#WAREHOUSE.Attribute.AIR_TRANSPORTPLANE} Airplane with transport capability. This can be used to transport other assets.
-- * @{#WAREHOUSE.Attribute.AIR_AWACS} Airborne Early Warning and Control System.
-- * @{#WAREHOUSE.Attribute.AIR_FIGHTER} Fighter, interceptor, ... airplane.
-- * @{#WAREHOUSE.Attribute.AIR_BOMBER} Aircraft which can be used for strategic bombing.
-- * @{#WAREHOUSE.Attribute.AIR_TANKER} Airplane which can refuel other aircraft.
-- * @{#WAREHOUSE.Attribute.AIR_TRANSPORTHELO} Helicopter with transport capability. This can be used to transport other assets.
-- * @{#WAREHOUSE.Attribute.AIR_ATTACKHELO} Attack helicopter.
-- * @{#WAREHOUSE.Attribute.AIR_UAV} Unpiloted Aerial Vehicle, e.g. drones.
-- * @{#WAREHOUSE.Attribute.AIR_OTHER} Any airborne unit that does not fall into any other airborne category.
-- * @{#WAREHOUSE.Attribute.GROUND_APC} Infantry carriers, in particular Amoured Personell Carrier. This can be used to transport other assets.
-- * @{#WAREHOUSE.Attribute.GROUND_TRUCK} Unarmed ground vehicles, which has the DCS "Truck" attribute.
-- * @{#WAREHOUSE.Attribute.GROUND_INFANTRY} Ground infantry assets.
-- * @{#WAREHOUSE.Attribute.GROUND_IFV} Ground infantry fighting vehicle.
-- * @{#WAREHOUSE.Attribute.GROUND_ARTILLERY} Artillery assets.
-- * @{#WAREHOUSE.Attribute.GROUND_TANK} Tanks (modern or old).
-- * @{#WAREHOUSE.Attribute.GROUND_TRAIN} Trains. Not that trains are **not** yet properly implemented in DCS and cannot be used currently.
-- * @{#WAREHOUSE.Attribute.GROUND_EWR} Early Warning Radar.
-- * @{#WAREHOUSE.Attribute.GROUND_AAA} Anti-Aircraft Artillery.
-- * @{#WAREHOUSE.Attribute.GROUND_SAM} Surface-to-Air Missile system or components.
-- * @{#WAREHOUSE.Attribute.GROUND_OTHER} Any ground unit that does not fall into any other ground category.
-- * @{#WAREHOUSE.Attribute.NAVAL_AIRCRAFTCARRIER} Aircraft carrier.
-- * @{#WAREHOUSE.Attribute.NAVAL_WARSHIP} War ship, i.e. cruisers, destroyers, firgates and corvettes.
-- * @{#WAREHOUSE.Attribute.NAVAL_ARMEDSHIP} Any armed ship that is not an aircraft carrier, a cruiser, destroyer, firgatte or corvette.
-- * @{#WAREHOUSE.Attribute.NAVAL_UNARMEDSHIP} Any unarmed naval vessel.
-- * @{#WAREHOUSE.Attribute.NAVAL_OTHER} Any naval unit that does not fall into any other naval category.
-- * @{#WAREHOUSE.Attribute.OTHER_UNKNOWN} Anything that does not fall into any other category.
--
-- ## Requesting a Specific Unit Type
--
-- A more specific request could look like:
--
--     warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.UNITTYPE, "A-10C", 2)
--
-- Here, Kobuleti requests a specific unit type, in particular two groups of A-10Cs. Note that the spelling is important as it must exacly be the same as
-- what one get's when using the DCS unit type.
--
-- ## Requesting a Specific Group
--
-- An even more specific request would be:
--
--     warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.GROUPNAME, "Group Name as in ME", 3)
--
-- In this case three groups named "Group Name as in ME" are requested. This explicitly request the groups named like that in the Mission Editor.
--
-- ## Requesting a General Category
--
-- On the other hand, very general and unspecifc requests can be made by the categroy descriptor. The descriptor value parameter can be any [group category](https://wiki.hoggitworld.com/view/DCS_Class_Group), i.e.
--
-- * Group.Category.AIRPLANE for fixed wing aircraft,
-- * Group.Category.HELICOPTER for helicopters,
-- * Group.Category.GROUND for all ground troops,
-- * Group.Category.SHIP for naval assets,
-- * Group.Category.TRAIN for trains (not implemented and not working in DCS yet).
--
-- For example,
--
--     warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.CATEGORY, Group.Category.GROUND, 10)
--
-- means that Kubuleti requests 10 ground groups and does not care which ones. This could be a mix of infantry, APCs, trucks etc.
--
-- **Note** that these general requests should be made with *great care* due to the fact, that depending on what a warehouse has in stock a lot of different unit types can be spawned.
--
-- ## Requesting Relative Quantities
--
-- In addition to requesting absolute numbers of assets it is possible to request relative amounts of assets currently in stock. To this end the @{#WAREHOUSE.Quantity} enumerator
-- was introduced:
--
-- * @{#WAREHOUSE.Quantity.ALL}
-- * @{#WAREHOUSE.Quantity.HALF}
-- * @{#WAREHOUSE.Quantity.QUARTER}
-- * @{#WAREHOUSE.Quantity.THIRD}
-- * @{#WAREHOUSE.Quantity.THREEQUARTERS}
--
-- For example,
--
--     warehouseBatumi:AddRequest(warehouseKobuleti, WAREHOUSE.Descriptor.CATEGORY, Group.Category.HELICOPTER, WAREHOUSE.Quantity.HALF)
--
-- means that Kobuleti warehouse requests half of all available helicopters which Batumi warehouse currently has in stock.
--
-- # Employing Assets - The Self Request
--
-- Transferring assets from one warehouse to another is important but of course once the the assets are at the "right" place it is equally important that they
-- can be employed for specific tasks and assignments.
--
-- Assets in the warehouses stock can be used for user defined tasks quite easily. They can be spawned into the game by a "***self request***", i.e. the warehouse
-- requests the assets from itself:
--
--     warehouseBatumi:AddRequest(warehouseBatumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 5)
--
-- Note that the *sending* and *requesting* warehouses are *identical* in this case.
--
-- This would simply spawn five infantry groups in the spawn zone of the Batumi warehouse if/when they are available.
--
-- ## Accessing the Assets
--
-- If a warehouse requests assets from itself, it triggers the event **SelfReqeuest**. The mission designer can capture this event with the associated
-- @{#WAREHOUSE.OnAfterSelfRequest}(*From*, *Event*, *To*, *groupset*, *request*) function.
--
--     --- OnAfterSelfRequest user function. Access groups spawned from the warehouse for further tasking.
--     -- @param #WAREHOUSE self
--     -- @param #string From From state.
--     -- @param #string Event Event.
--     -- @param #string To To state.
--     -- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
--     -- @param #WAREHOUSE.Pendingitem request Pending self request.
--     function WAREHOUSE:OnAfterSelfRequest(From, Event, To, groupset, request)
--       local groupset=groupset --Core.Set#SET_GROUP
--       local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--       for _,group in pairs(groupset:GetSetObjects()) do
--         local group=group --Wrapper.Group#GROUP
--         group:SmokeGreen()
--       end
--
--     end
--
-- The variable *groupset* is a @{Core.Set#SET_GROUP} object and holds all asset groups from the request. The code above shows, how the mission designer can access the groups
-- for further tasking. Here, the groups are only smoked but, of course, you can use them for whatever assignment you fancy.
--
-- Note that airborne groups are spawned in **uncontrolled state** and need to be activated first before they can begin with their assigned tasks and missions.
-- This can be done with the @{Wrapper.Controllable#CONTROLLABLE.StartUncontrolled} function as demonstrated in the example section below.
--
-- ===
--
-- # Infrastructure
--
-- A good infrastructure is important for a warehouse to be efficient. Therefore, the location of a warehouse should be chosen with care.
-- This can also help to avoid many DCS related issues such as units getting stuck in buildings, blocking taxi ways etc.
--
-- ## Spawn Zone
--
-- By default, the zone were ground assets are spawned is a circular zone around the physical location of the warehouse with a radius of 200 meters. However, the location of the
-- spawn zone can be set by the @{#WAREHOUSE.SetSpawnZone}(*zone*) functions. It is advisable to choose a zone which is clear of obstacles.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Batumi.png)
--
-- The parameter *zone* is a MOOSE @{Core.Zone#ZONE} object. So one can, e.g., use trigger zones defined in the mission editor. If a cicular zone is not desired, one
-- can use a polygon zone (see @{Core.Zone#ZONE_POLYGON}).
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_SpawnPolygon.png)
--
-- ## Road Connections
--
-- Ground assets will use a road connection to travel from one warehouse to another. Therefore, a proper road connection is necessary.
--
-- By default, the closest point on road to the center of the spawn zone is chosen as road connection automatically. But only, if distance between the spawn zone
-- and the road connection is less than 3 km.
--
-- The user can set the road connection manually with the @{#WAREHOUSE.SetRoadConnection} function. This is only functional for self propelled assets at the moment
-- and not if using the AI dispatcher classes since these have a different logic to find the route.
--
-- ## Off Road Connections
--
-- For ground troops it is also possible to define off road paths between warehouses if no proper road connection is available or should not be used.
--
-- An off road path can be defined via the @{#WAREHOUSE.AddOffRoadPath}(*remotewarehouse*, *group*, *oneway*) function, where
-- *remotewarehouse* is the warehouse to which the path leads.
-- The parameter *group* is a *late activated* template group. The waypoints of this group are used to define the path between the two warehouses.
-- By default, the reverse paths is automatically added to get *from* the remote warehouse *to* this warehouse unless the parameter *oneway* is set to *true*.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Off-Road_Paths.png)
--
-- **Note** that if an off road connection is defined between two warehouses this becomes the default path, i.e. even if there is a path *on road* possible
-- this will not be used.
--
-- Also note that you can define multiple off road connections between two warehouses. If there are multiple paths defined, the connection is chosen randomly.
-- It is also possible to add the same path multiple times. By this you can influence the probability of the chosen path. For example Path1(A->B) has been
-- added two times while Path2(A->B) was added only once. Hence, the group will choose Path1 with a probability of 66.6 % while Path2 is only chosen with
-- a probability of 33.3 %.
--
-- ## Rail Connections
--
-- A rail connection is automatically defined as the closest point on a railway measured from the center of the spawn zone. But only, if the distance is less than 3 km.
--
-- The mission designer can manually specify a rail connection with the @{#WAREHOUSE.SetRailConnection} function.
--
-- **NOTE** however, that trains in DCS are currently not implemented in a way so that they can be used.
--
-- ## Air Connections
--
-- In order to use airborne assets, a warehouse needs to have an associated airbase. This can be an airdrome, a FARP/HELOPAD or a ship.
--
-- If there is an airbase within 3 km range of the warehouse it is automatically set as the associated airbase. A user can set an airbase manually
-- with the @{#WAREHOUSE.SetAirbase} function. Keep in mind that sometimes ground units need to walk/drive from the spawn zone to the airport
-- to get to their transport carriers.
--
-- ## Naval Connections
--
-- Natively, DCS does not have the concept of a port/habour or shipping lanes. So in order to have a meaningful transfer of naval units between warehouses, these have to be
-- defined by the mission designer.
--
-- ### Defining a Port
--
-- A port in this context is the zone where all naval assets are spawned. This zone can be defined with the function @{#WAREHOUSE.SetPortZone}(*zone*), where the parameter
-- *zone* is a MOOSE zone. So again, this can be create from a trigger zone defined in the mission editor or if a general shape is desired by a @{Core.Zone#ZONE_POLYGON}.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_PortZone.png)
--
-- ### Defining Shipping Lanes
--
-- A shipping lane between to warehouses can be defined by the @{#WAREHOUSE.AddShippingLane}(*remotewarehouse*, *group*, *oneway*) function. The first parameter *remotewarehouse*
-- is the warehouse which should be connected to the present warehouse.
--
-- The parameter *group* should be a late activated group defined in the mission editor. The waypoints of this group are used as waypoints of the shipping lane.
--
-- By default, the reverse lane is automatically added to the remote warehouse. This can be disabled by setting the *oneway* parameter to *true*.
--
-- Similar to off road connections, you can also define multiple shipping lanes between two warehouse ports. If there are multiple lanes defined, one is chosen randomly.
-- It is possible to add the same lane multiple times. By this you can influence the probability of the chosen lane. For example Lane_1(A->B) has been
-- added two times while Lane_2(A->B) was added only once. Therefore, the ships will choose Lane_1 with a probability of 66.6 % while Path_2 is only chosen with
-- a probability of 33.3 %.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_ShippingLane.png)
--
-- ===
--
-- # Why is my request not processed?
--
-- For each request, the warehouse class logic does a lot of consistency and validation checks under the hood.
-- This helps to circumvent a lot of DCS issues and shortcomings. For example, it is checked that enough free
-- parking spots at an airport are available *before* the assets are spawned.
-- However, this also means that sometimes a request is deemed to be *invalid* in which case they are deleted
-- from the queue or considered to be valid but cannot be executed at this very moment.
--
-- ## Invalid Requests
--
-- Invalid request are requests which can **never** be processes because there is some logical or physical argument against it.
-- (Or simply because that feature was not implemented (yet).)
--
-- * All airborne assets need an associated airbase of any kind on the sending *and* receiving warehouse.
-- * Airplanes need an airdrome at the sending and receiving warehouses.
-- * Not enough parking spots of the right terminal type at the sending warehouse. This avoids planes spawning on runways or on top of each other.
-- * No parking spots of the right terminal type at the receiving warehouse. This avoids DCS despawning planes on landing if they have no valid parking spot.
-- * Ground assets need a road connection between both warehouses or an off-road path needs to be added manually.
-- * Ground assets cannot be send directly to ships, i.e. warehouses on ships.
-- * Naval units need a user defined shipping lane between both warehouses.
-- * Warehouses need a user defined port zone to spawn naval assets.
-- * The receiving warehouse is destroyed or stopped.
-- * If transport by airplane, both warehouses must have and airdrome.
-- * If transport by APC, both warehouses must have a road connection.
-- * If transport by helicopter, the sending airbase must have an associated airbase (airdrome or FARP).
--
-- All invalid requests are cancelled and **removed** from the warehouse queue!
--
-- ## Temporarily Unprocessable Requests
--
-- Temporarily unprocessable requests are possible in principle, but cannot be processed at the given time the warehouse checks its queue.
--
-- * No enough parking spaces are available for all requested assets but the airbase has enough parking spots in total so that this request is possible once other aircraft have taken off.
-- * The requesting warehouse is not in state "Running" (could be paused, not yet started or under attack).
-- * Not enough cargo assets available at this moment.
-- * Not enough free parking spots for all cargo or transport airborne assets at the moment.
-- * Not enough transport assets to carry all cargo assets.
--
-- Temporarily unprocessable requests are held in the queue. If at some point in time, the situation changes so that these requests can be processed, they are executed.
--
-- ## Cargo Bay and Weight Limitations
--
-- The transportation of cargo is handled by the AI\_Dispatcher classes. These take the cargo bay of a carrier and the weight of
-- the cargo into account so that a carrier can only load a realistic amount of cargo.
--
-- However, if troops are supposed to be transported between warehouses, there is one important limitations one has to keep in mind.
-- This is that **cargo asset groups cannot be split** and divided into separate carrier units!
--
-- For example, a TPz Fuchs has a cargo bay large enough to carry up to 10 soldiers at once, which is a realistic number.
-- If a group consisting of more than ten soldiers needs to be transported, it cannot be loaded into the APC.
-- Even if two APCs are available, which could in principle carry up to 20 soldiers, a group of, let's say 12 soldiers will not
-- be split into a group of ten soldiers using the first APC and a group two soldiers using the second APC.
--
-- In other words, **there must be at least one carrier unit available that has a cargo bay large enough to load the heaviest cargo group!**
-- The warehouse logic will automatically search all available transport assets for a large enough carrier.
-- But if none is available, the request will be queued until a suitable carrier becomes available.
--
-- The only realistic solution in this case is to either provide a transport carrier with a larger cargo bay or to reduce the number of soldiers
-- in the group.
--
-- A better way would be to have two groups of max. 10 soldiers each and one TPz Fuchs for transport. In this case, the first group is
-- loaded and transported to the receiving warehouse. Once this is done, the carrier will drive back and pick up the remaining
-- group.
--
-- As an artificial workaround one can manually set the cargo bay size to a larger value or alternatively reduce the weight of the cargo
-- when adding the assets via the @{#WAREHOUSE.AddAsset} function. This might even be unavoidable if, for example, a SAM group
-- should be transported since SAM sites only work when all units are in the same group.
--
-- ## Processing Speed
--
-- A warehouse has a limited speed to process requests. Each time the status of the warehouse is updated only one requests is processed.
-- The time interval between status updates is 30 seconds by default and can be adjusted via the @{#WAREHOUSE.SetStatusUpdate}(*interval*) function.
-- However, the status is also updated on other occasions, e.g. when a new request was added.
--
-- ===
--
-- # Strategic Considerations
--
-- Due to the fact that a warehouse holds (or can hold) a lot of valuable assets, it makes a (potentially) juicy target for enemy attacks.
-- There are several interesting situations, which can occur.
--
-- ## Capturing a Warehouses Airbase
--
-- If a warehouse has an associated airbase, it can be captured by the enemy. In this case, the warehouse looses its ability so employ all airborne assets and is also cut-off
-- from supply by airplanes. Supply of ground troops via helicopters is still possible, because they deliver the troops into the spawn zone.
--
-- Technically, the capturing of the airbase is triggered by the DCS [S\_EVENT\_BASE\_CAPTURED](https://wiki.hoggitworld.com/view/DCS_event_base_captured) event.
-- So the capturing takes place when only enemy ground units are in the airbase zone whilst no ground units of the present airbase owner are in that zone.
--
-- The warehouse will also create an event **AirbaseCaptured**, which can be captured by the @{#WAREHOUSE.OnAfterAirbaseCaptured} function. So the warehouse chief can react on
-- this attack and for example deploy ground groups to re-capture its airbase.
--
-- When an airbase is re-captured the event **AirbaseRecaptured** is triggered and can be captured by the @{#WAREHOUSE.OnAfterAirbaseRecaptured} function.
-- This can be used to put the defending assets back into the warehouse stock.
--
-- ## Capturing the Warehouse
--
-- A warehouse can be captured by the enemy coalition. If enemy ground troops enter the warehouse zone the event **Attacked** is triggered which can be captured by the
-- @{#WAREHOUSE.OnAfterAttacked} event. By default the warehouse zone circular zone with a radius of 500 meters located at the center of the physical warehouse.
-- The warehouse zone can be set via the @{#WAREHOUSE.SetWarehouseZone}(*zone*) function. The parameter *zone* must also be a circular zone.
--
-- The @{#WAREHOUSE.OnAfterAttacked} function can be used by the mission designer to react to the enemy attack. For example by deploying some or all ground troops
-- currently in stock to defend the warehouse. Note that the warehouse also has a self defence option which can be enabled by the @{#WAREHOUSE.SetAutoDefenceOn}()
-- function. In this case, the warehouse will automatically spawn all ground troops. If the spawn zone is further away from the warehouse zone, all mobile troops
-- are routed to the warehouse zone. The self request which is triggered on an automatic defence has the assignment "AutoDefence". So you can use this to
-- give orders to the groups that were spawned using the @{#WAREHOUSE.OnAfterSelfRequest} function.
--
-- If only ground troops of the enemy coalition are present in the warehouse zone, the warehouse and all its assets falls into the hands of the enemy.
-- In this case the event **Captured** is triggered which can be captured by the @{#WAREHOUSE.OnAfterCaptured} function.
--
-- The warehouse turns to the capturing coalition, i.e. its physical representation, and all assets as well. In particular, all requests to the warehouse will
-- spawn assets belonging to the new owner.
--
-- If the enemy troops could be defeated, i.e. no more troops of the opposite coalition are in the warehouse zone, the event **Defeated** is triggered and
-- the @{#WAREHOUSE.OnAfterDefeated} function can be used to adapt to the new situation. For example putting back all spawned defender troops back into
-- the warehouse stock. Note that if the automatic defence is enabled, all defenders are automatically put back into the warehouse on the **Defeated** event.
--
-- ## Destroying a Warehouse
--
-- If an enemy destroy the physical warehouse structure, the warehouse will of course stop all its services. In principle, all assets contained in the warehouse are
-- gone as well. So a warehouse should be properly defended.
--
-- Upon destruction of the warehouse, the event **Destroyed** is triggered, which can be captured by the @{#WAREHOUSE.OnAfterDestroyed} function.
-- So the mission designer can intervene at this point and for example choose to spawn all or particular types of assets before the warehouse is gone for good.
--
-- ===
--
-- # Hook in and Take Control
--
-- The Finite State Machine implementation allows mission designers to hook into important events and add their own code.
-- Most of these events have already been mentioned but here is the list at a glance:
--
-- * "NotReadyYet" --> "Start" --> "Running" (Starting the warehouse)
-- * "*" --> "Status" --> "*" (status updated in regular intervals)
-- * "*" --> "AddAsset" --> "*" (adding a new asset to the warehouse stock)
-- * "*" --> "NewAsset" --> "*" (a new asset has been added to the warehouse stock)
-- * "*" --> "AddRequest" --> "*" (adding a request for the warehouse assets)
-- * "Running" --> "Request" --> "*" (a request is processed when the warehouse is running)
-- * "Attacked" --> "Request" --> "*" (a request is processed when the warehouse is attacked)
-- * "*" --> "Arrived" --> "*" (asset group has arrived at its destination)
-- * "*" --> "Delivered" --> "*" (all assets of a request have been delivered)
-- * "Running" --> "SelfRequest" --> "*" (warehouse is requesting asset from itself when running)
-- * "Attacked" --> "SelfRequest" --> "*" (warehouse is requesting asset from itself while under attack)
-- * "*" --> "Attacked" --> "Attacked" (warehouse is being attacked)
-- * "Attacked" --> "Defeated" --> "Running" (an attack was defeated)
-- * "Attacked" --> "Captured" --> "Running" (warehouse was captured by the enemy)
-- * "*" --> "AirbaseCaptured" --> "*" (airbase belonging to the warehouse was captured by the enemy)
-- * "*" --> "AirbaseRecaptured" --> "*" (airbase was re-captured)
-- * "*" --> "AssetSpawned" --> "*" (an asset has been spawned into the world)
-- * "*" --> "AssetLowFuel" --> "*" (an asset is running low on fuel)
-- * "*" --> "AssetDead" --> "*" (a whole asset, i.e. all its units/groups, is dead)
-- * "*" --> "Destroyed" --> "Destroyed" (warehouse was destroyed)
-- * "Running" --> "Pause" --> "Paused" (warehouse is paused)
-- * "Paused" --> "Unpause" --> "Running" (warehouse is unpaused)
-- * "*" --> "Stop" --> "Stopped" (warehouse is stopped)
--
-- The transitions are of the general form "From State" --> "Event" --> "To State". The "*" star denotes that the transition is possible from *any* state.
-- Some transitions, however, are only allowed from certain "From States". For example, no requests can be processed if the warehouse is in "Paused" or "Destroyed" or "Stopped" state.
--
-- Mission designers can capture the events with OnAfterEvent functions, e.g. @{#WAREHOUSE.OnAfterDelivered} or @{#WAREHOUSE.OnAfterAirbaseCaptured}.
--
-- ===
--
-- # Persistence of Assets
--
-- Assets in stock of a warehouse can be saved to a file on your hard drive and then loaded from that file at a later point. This enables to restart the mission
-- and restore the warehouse stock.
--
-- ## Prerequisites
--
-- **Important** By default, DCS does not allow for writing data to files. Therefore, one first has to comment out the line "sanitizeModule('io')", i.e.
--
--     do
--       sanitizeModule('os')
--       --sanitizeModule('io')
--       sanitizeModule('lfs')
--       require = nil
--       loadlib = nil
--     end
--
-- in the file "MissionScripting.lua", which is located in the subdirectory "Scripts" of your DCS installation root directory.
--
-- ### Don't!
--
-- Do not use **semi-colons** or **equal signs** in the group names of your assets as these are used as separators in the saved and loaded files texts.
-- If you do, it will cause problems and give you a headache!
--
-- ## Save Assets
--
-- Saving asset data to file is achieved by the @{#WAREHOUSE.Save}(*path*, *filename*) function. The parameter *path* specifies the path on the file system where the
-- warehouse data is saved. If you do not specify a path, the file is saved your the DCS installation root directory.
-- The parameter *filename* is optional and defines the name of the saved file. By default this is automatically created from the warehouse id and name, for example
-- "Warehouse-1234_Batumi.txt".
--
--     warehouseBatumi:Save("D:\\My Warehouse Data\\")
--
-- This will save all asset data to in "D:\\My Warehouse Data\\Warehouse-1234_Batumi.txt".
--
-- ### Automatic Save at Mission End
--
-- The assets can be saved automatically when the mission is ended via the @{#WAREHOUSE.SetSaveOnMissionEnd}(*path*, *filename*) function, i.e.
--
--     warehouseBatumi:SetSaveOnMissionEnd("D:\\My Warehouse Data\\")
--
-- ## Load Assets
--
-- Loading assets data from file is achieved by the @{#WAREHOUSE.Load}(*path*, *filename*) function. The parameter *path* specifies the path on the file system where the
-- warehouse data is loaded from. If you do not specify a path, the file is loaded from your the DCS installation root directory.
-- The parameter *filename* is optional and defines the name of the file to load. By default this is automatically generated from the warehouse id and name, for example
-- "Warehouse-1234_Batumi.txt".
--
-- Note that the warehouse **must not be started** and in the *Running* state in order to load the assets. In other words, loading should happen after the
-- @{#WAREHOUSE.New} command is specified in the code but before the @{#WAREHOUSE.Start} command is given.
--
-- Loading the assets is done by
--
--     warehouseBatumi:New(STATIC:FindByName("Warehouse Batumi"))
--     warehouseBatumi:Load("D:\\My Warehouse Data\\")
--     warehouseBatumi:Start()
--
-- This sequence loads all assets from file. If a warehouse was captured in the last mission, it also respawns the static warehouse structure with the right coalition.
-- However, it due to DCS limitations it is not possible to set the airbase coalition. This has to be done manually in the mission editor. Or alternatively, one could
-- spawn some ground units via a self request and let them capture the airbase.
--
-- ===
--
-- # Examples
--
-- This section shows some examples how the WAREHOUSE class is used in practice. This is one of the best ways to explain things, in my opinion.
--
-- But first, let me introduce a convenient way to define several warehouses in a table. This is absolutely *not necessary* but quite handy if you have
-- multiple WAREHOUSE objects in your mission.
--
-- ## Example 0: Setting up a Warehouse Array
--
-- If you have multiple warehouses, you can put them in a table. This makes it easier to access them or to loop over them.
--
--     -- Define Warehouses.
--     local warehouse={}
--     -- Blue warehouses
--     warehouse.Senaki   = WAREHOUSE:New(STATIC:FindByName("Warehouse Senaki"),   "Senaki")   --Functional.Warehouse#WAREHOUSE
--     warehouse.Batumi   = WAREHOUSE:New(STATIC:FindByName("Warehouse Batumi"),   "Batumi")   --Functional.Warehouse#WAREHOUSE
--     warehouse.Kobuleti = WAREHOUSE:New(STATIC:FindByName("Warehouse Kobuleti"), "Kobuleti") --Functional.Warehouse#WAREHOUSE
--     warehouse.Kutaisi  = WAREHOUSE:New(STATIC:FindByName("Warehouse Kutaisi"),  "Kutaisi")  --Functional.Warehouse#WAREHOUSE
--     warehouse.Berlin   = WAREHOUSE:New(STATIC:FindByName("Warehouse Berlin"),   "Berlin")   --Functional.Warehouse#WAREHOUSE
--     warehouse.London   = WAREHOUSE:New(STATIC:FindByName("Warehouse London"),   "London")   --Functional.Warehouse#WAREHOUSE
--     warehouse.Stennis  = WAREHOUSE:New(STATIC:FindByName("Warehouse Stennis"),  "Stennis")  --Functional.Warehouse#WAREHOUSE
--     warehouse.Pampa    = WAREHOUSE:New(STATIC:FindByName("Warehouse Pampa"),    "Pampa")    --Functional.Warehouse#WAREHOUSE
--     -- Red warehouses
--     warehouse.Sukhumi  = WAREHOUSE:New(STATIC:FindByName("Warehouse Sukhumi"),  "Sukhumi")  --Functional.Warehouse#WAREHOUSE
--     warehouse.Gudauta  = WAREHOUSE:New(STATIC:FindByName("Warehouse Gudauta"),  "Gudauta")  --Functional.Warehouse#WAREHOUSE
--     warehouse.Sochi    = WAREHOUSE:New(STATIC:FindByName("Warehouse Sochi"),    "Sochi")    --Functional.Warehouse#WAREHOUSE
--
-- Remarks:
--
-- * I defined the array as local, i.e. local warehouse={}. This is personal preference and sometimes causes trouble with the lua garbage collection. You can also define it as a global array/table!
-- * The "--Functional.Warehouse#WAREHOUSE" at the end is only to have the LDT intellisense working correctly. If you don't use LDT (which you should!), it can be omitted.
--
-- **NOTE** that all examples below need this bit or code at the beginning - or at least the warehouses which are used.
--
-- The example mission is based on the same template mission, which has defined a lot of airborne, ground and naval assets as templates. Only few of those are used here.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Assets.png)
--
-- ## Example 1: Self Request
--
-- Ground troops are taken from the Batumi warehouse stock and spawned in its spawn zone. After a short delay, they are added back to the warehouse stock.
-- Also a new request is made. Hence, the groups will be spawned, added back to the warehouse, spawned again and so on and so forth...
--
--     -- Start warehouse Batumi.
--     warehouse.Batumi:Start()
--
--     -- Add five groups of infantry as assets.
--     warehouse.Batumi:AddAsset(GROUP:FindByName("Infantry Platoon Alpha"), 5)
--
--     -- Add self request for three infantry at Batumi.
--     warehouse.Batumi:AddRequest(warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 3)
--
--
--     --- Self request event. Triggered once the assets are spawned in the spawn zone or at the airbase.
--     function warehouse.Batumi:OnAfterSelfRequest(From, Event, To, groupset, request)
--       local mygroupset=groupset --Core.Set#SET_GROUP
--
--       -- Loop over all groups spawned from that request.
--       for _,group in pairs(mygroupset:GetSetObjects()) do
--         local group=group --Wrapper.Group#GROUP
--
--         -- Gree smoke on spawned group.
--         group:SmokeGreen()
--
--         -- Put asset back to stock after 10 seconds.
--         warehouse.Batumi:__AddAsset(10, group)
--       end
--
--       -- Add new self request after 20 seconds.
--       warehouse.Batumi:__AddRequest(20, warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 3)
--
--     end
--
-- ## Example 2: Self propelled Ground Troops
--
-- Warehouse Berlin, which is a FARP near Batumi, requests infantry and troop transports from the warehouse at Batumi.
-- The groups are spawned at Batumi and move by themselves from Batumi to Berlin using the roads.
-- Once the troops have arrived at Berlin, the troops are automatically added to the warehouse stock of Berlin.
-- While on the road, Batumi has requested back two APCs from Berlin. Since Berlin does not have the assets in stock,
-- the request is queued. After the troops have arrived, Berlin is sending back the APCs to Batumi.
--
--     -- Start Warehouse at Batumi.
--     warehouse.Batumi:Start()
--
--     -- Add 20 infantry groups and ten APCs as assets at Batumi.
--     warehouse.Batumi:AddAsset("Infantry Platoon Alpha", 20)
--     warehouse.Batumi:AddAsset("TPz Fuchs", 10)
--
--     -- Start Warehouse Berlin.
--     warehouse.Berlin:Start()
--
--     -- Warehouse Berlin requests 10 infantry groups and 5 APCs from warehouse Batumi.
--     warehouse.Batumi:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 10)
--     warehouse.Batumi:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_APC, 5)
--
--     -- Request from Batumi for 2 APCs. Initially these are not in stock. When they become available, the request is executed.
--     warehouse.Berlin:AddRequest(warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_APC, 2)
--
-- ## Example 3: Self Propelled Airborne Assets
--
-- Warehouse Senaki receives a high priority request from Kutaisi for one Yak-52s. At the same time, Kobuleti requests half of
-- all available Yak-52s. Request from Kutaisi is first executed and then Kobuleti gets half of the remaining assets.
-- Additionally, London requests one third of all available UH-1H Hueys from Senaki.
-- Once the units have arrived they are added to the stock of the receiving warehouses and can be used for further assignments.
--
--     -- Start warehouses
--     warehouse.Senaki:Start()
--     warehouse.Kutaisi:Start()
--     warehouse.Kobuleti:Start()
--     warehouse.London:Start()
--
--     -- Add assets to Senaki warehouse.
--     warehouse.Senaki:AddAsset("Yak-52", 10)
--     warehouse.Senaki:AddAsset("Huey", 6)
--
--     -- Kusaisi requests 3 Yak-52 form Senaki while Kobuleti wants all the rest.
--     warehouse.Senaki:AddRequest(warehouse.Kutaisi,  WAREHOUSE.Descriptor.GROUPNAME, "Yak-52", 1, nil, nil, 10)
--     warehouse.Senaki:AddRequest(warehouse.Kobuleti, WAREHOUSE.Descriptor.GROUPNAME, "Yak-52", WAREHOUSE.Quantity.HALF,  nil, nil, 70)
--
--     -- FARP London wants 1/3 of the six available Hueys.
--     warehouse.Senaki:AddRequest(warehouse.London,  WAREHOUSE.Descriptor.GROUPNAME, "Huey", WAREHOUSE.Quantity.THIRD)
--
-- ## Example 4: Transport of Assets by APCs
--
-- Warehouse at FARP Berlin requests five infantry groups from Batumi. These assets shall be transported using two APC groups.
-- Infantry and APC are spawned in the spawn zone at Batumi. The APCs have a cargo bay large enough to pick up four of the
-- five infantry groups in the first run and will bring them to Berlin. There, they unboard and walk to the warehouse where they will be added to the stock.
-- Meanwhile the APCs go back to Batumi and one will pick up the last remaining soldiers.
-- Once the APCs have completed their mission, they return to Batumi and are added back to stock.
--
--     -- Start Warehouse at Batumi.
--     warehouse.Batumi:Start()
--
--     -- Start Warehouse Berlin.
--     warehouse.Berlin:Start()
--
--     -- Add 20 infantry groups and five APCs as assets at Batumi.
--     warehouse.Batumi:AddAsset("Infantry Platoon Alpha", 20)
--     warehouse.Batumi:AddAsset("TPz Fuchs", 5)
--
--     -- Warehouse Berlin requests 5 infantry groups from warehouse Batumi using 2 APCs for transport.
--     warehouse.Batumi:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 5, WAREHOUSE.TransportType.APC, 2)
--
--## Example 5: Transport of Assets by Helicopters
--
--  Warehouse at FARP Berlin requests five infantry groups from Batumi. They shall be transported by all available transport helicopters.
--  Note that the UH-1H Huey in DCS is an attack and not a transport helo. So the warehouse logic would be default also
--  register it as an @{#WAREHOUSE.Attribute.AIR_ATTACKHELICOPTER}. In order to use it as a transport we need to force
--  it to be added as transport helo.
--  Also note that even though all (here five) helos are requested, only two of them are employed because this number is sufficient to
--  transport all requested assets in one go.
--
--     -- Start Warehouses.
--     warehouse.Batumi:Start()
--     warehouse.Berlin:Start()
--
--     -- Add 20 infantry groups as assets at Batumi.
--     warehouse.Batumi:AddAsset("Infantry Platoon Alpha", 20)
--
--     -- Add five Hueys for transport. Note that a Huey in DCS is an attack and not a transport helo. So we force this attribute!
--     warehouse.Batumi:AddAsset("Huey", 5, WAREHOUSE.Attribute.AIR_TRANSPORTHELO)
--
--     -- Warehouse Berlin requests 5 infantry groups from warehouse Batumi using all available helos for transport.
--     warehouse.Batumi:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 5, WAREHOUSE.TransportType.HELICOPTER, WAREHOUSE.Quantity.ALL)
--
--## Example 6: Transport of Assets by Airplanes
--
-- Warehoues Kobuleti requests all (three) APCs from Batumi using one airplane for transport.
-- The available C-130 is able to carry one APC at a time. So it has to commute three times between Batumi and Kobuleti to deliver all requested cargo assets.
-- Once the cargo is delivered, the C-130 transport returns to Batumi and is added back to stock.
--
--     -- Start warehouses.
--     warehouse.Batumi:Start()
--     warehouse.Kobuleti:Start()
--
--     -- Add assets to Batumi warehouse.
--     warehouse.Batumi:AddAsset("C-130", 1)
--     warehouse.Batumi:AddAsset("TPz Fuchs", 3)
--
--     warehouse.Batumi:AddRequest(warehouse.Kobuleti, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_APC, WAREHOUSE.Quantity.ALL, WAREHOUSE.TransportType.AIRPLANE)
--
-- ## Example 7: Capturing Airbase and Warehouse
--
-- A red BMP has made it through our defence lines and drives towards our unprotected airbase at Senaki.
-- Once the BMP captures the airbase (DCS [S\_EVENT\_BASE\_CAPTURED](https://wiki.hoggitworld.com/view/DCS_event_base_captured) is evaluated)
-- the warehouse at Senaki lost its air infrastructure and it is not possible any more to spawn airborne units. All requests for airborne units are rejected and cancelled in this case.
--
-- The red BMP then drives further to the warehouse. Once it enters the warehouse zone (500 m radius around the warehouse building), the warehouse is
-- considered to be under attack. This triggers the event **Attacked**. The @{#WAREHOUSE.OnAfterAttacked} function can be used to react to this situation.
-- Here, we only broadcast a distress call and launch a flare. However, it would also be reasonable to spawn all or selected ground troops in order to defend
-- the warehouse. Note, that the warehouse has a self defence option which can be activated via the @{#WAREHOUSE.SetAutoDefenceOn}() function. If activated,
-- *all* ground assets are automatically spawned and assigned to defend the warehouse. Once/if the attack is defeated, these assets go automatically back
-- into the warehouse stock.
--
-- If the red coalition manages to capture our warehouse, all assets go into their possession. Now red tries to steal three F/A-18 flights and send them to
-- Sukhumi. These aircraft will be spawned and begin to taxi. However, ...
--
-- A blue Bradley is in the area and will attempt to recapture the warehouse. It might also catch the red F/A-18s before they take off.
--
--     -- Start warehouses.
--     warehouse.Senaki:Start()
--     warehouse.Sukhumi:Start()
--
--     -- Add some assets.
--     warehouse.Senaki:AddAsset("TPz Fuchs", 5)
--     warehouse.Senaki:AddAsset("Infantry Platoon Alpha", 10)
--     warehouse.Senaki:AddAsset("F/A-18C 2ship", 10)
--
--     -- Enable auto defence, i.e. spawn all group troups into the spawn zone.
--     --warehouse.Senaki:SetAutoDefenceOn()
--
--     -- Activate Red BMP trying to capture the airfield and the warehouse.
--     local red1=GROUP:FindByName("Red BMP-80 Senaki"):Activate()
--
--     -- The red BMP first drives to the airbase which gets captured and changes from blue to red.
--     -- This triggers the "AirbaseCaptured" event where you can hook in and do things.
--     function warehouse.Senaki:OnAfterAirbaseCaptured(From, Event, To, Coalition)
--       -- This request cannot be processed since the warehouse has lost its airbase. In fact it is deleted from the queue.
--       warehouse.Senaki:AddRequest(warehouse.Senaki,WAREHOUSE.Descriptor.CATEGORY, Group.Category.AIRPLANE, 1)
--     end
--
--     -- Now the red BMP also captures the warehouse. This triggers the "Captured" event where you can hook in.
--     -- So now the warehouse and the airbase are both red and aircraft can be spawned again.
--     function warehouse.Senaki:OnAfterCaptured(From, Event, To, Coalition, Country)
--       -- These units will be spawned as red units because the warehouse has just been captured.
--       if Coalition==coalition.side.RED then
--         -- Sukhumi tries to "steals" three F/A-18 from Senaki and brings them to Sukhumi.
--         -- Well, actually the aircraft wont make it because blue1 will kill it on the taxi way leaving a blood bath. But that's life!
--         warehouse.Senaki:AddRequest(warehouse.Sukhumi, WAREHOUSE.Descriptor.CATEGORY, Group.Category.AIRPLANE, 3)
--         warehouse.Senaki.warehouse:SmokeRed()
--       elseif Coalition==coalition.side.BLUE then
--         warehouse.Senaki.warehouse:SmokeBlue()
--       end
--
--       -- Activate a blue vehicle to re-capture the warehouse. It will drive to the warehouse zone and kill the red intruder.
--       local blue1=GROUP:FindByName("blue1"):Activate()
--     end
--
-- ## Example 8: Destroying a Warehouse
--
-- FARP Berlin requests a Huey from Batumi warehouse. This helo is deployed and will be delivered.
-- After 30 seconds into the mission we create and (artificial) big explosion - or a terrorist attack if you like - which completely destroys the
-- the warehouse at Batumi. All assets are gone and requests cannot be processed anymore.
--
--     -- Start Batumi and Berlin warehouses.
--     warehouse.Batumi:Start()
--     warehouse.Berlin:Start()
--
--     -- Add some assets.
--     warehouse.Batumi:AddAsset("Huey", 5, WAREHOUSE.Attribute.AIR_TRANSPORTHELO)
--     warehouse.Berlin:AddAsset("Huey", 5, WAREHOUSE.Attribute.AIR_TRANSPORTHELO)
--
--     -- Big explosion at the warehose. It has a very nice damage model by the way :)
--     local function DestroyWarehouse()
--       warehouse.Batumi:GetCoordinate():Explosion(999)
--     end
--     SCHEDULER:New(nil, DestroyWarehouse, {}, 30)
--
--     -- First request is okay since warehouse is still alive.
--     warehouse.Batumi:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.AIR_TRANSPORTHELO, 1)
--
--     -- These requests should both not be processed any more since the warehouse at Batumi is destroyed.
--     warehouse.Batumi:__AddRequest(35, warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.AIR_TRANSPORTHELO, 1)
--     warehouse.Berlin:__AddRequest(40, warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.AIR_TRANSPORTHELO, 1)
--
-- ## Example 9: Self Propelled Naval Assets
--
-- Kobuleti requests all naval assets from Batumi.
-- However, before naval assets can be exchanged, both warehouses need a port and at least one shipping lane defined by the user.
-- See the @{#WAREHOUSE.SetPortZone}() and @{#WAREHOUSE.AddShippingLane}() functions.
-- We do not want to spawn them all at once, because this will probably be a disaster
-- in the port zone. Therefore, each ship is spawned with a delay of five minutes.
--
-- Batumi has quite a selection of different ships (for testing).
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Naval_Assets.png)
--
--     -- Start warehouses.
--     warehouse.Batumi:Start()
--     warehouse.Kobuleti:Start()
--
--     -- Define ports. These are polygon zones created by the waypoints of late activated units.
--     warehouse.Batumi:SetPortZone(ZONE_POLYGON:NewFromGroupName("Warehouse Batumi Port Zone", "Warehouse Batumi Port Zone"))
--     warehouse.Kobuleti:SetPortZone(ZONE_POLYGON:NewFromGroupName("Warehouse Kobuleti Port Zone", "Warehouse Kobuleti Port Zone"))
--
--     -- Shipping lane. Again, the waypoints of late activated units are taken as points defining the shipping lane.
--     -- Some units will take lane 1 while others will take lane two. But both lead from Batumi to Kobuleti port.
--     warehouse.Batumi:AddShippingLane(warehouse.Kobuleti, GROUP:FindByName("Warehouse Batumi-Kobuleti Shipping Lane 1"))
--     warehouse.Batumi:AddShippingLane(warehouse.Kobuleti, GROUP:FindByName("Warehouse Batumi-Kobuleti Shipping Lane 2"))
--
--     -- Large selection of available naval units in DCS.
--     warehouse.Batumi:AddAsset("Speedboat")
--     warehouse.Batumi:AddAsset("Perry")
--     warehouse.Batumi:AddAsset("Normandy")
--     warehouse.Batumi:AddAsset("Stennis")
--     warehouse.Batumi:AddAsset("Carl Vinson")
--     warehouse.Batumi:AddAsset("Tarawa")
--     warehouse.Batumi:AddAsset("SSK 877")
--     warehouse.Batumi:AddAsset("SSK 641B")
--     warehouse.Batumi:AddAsset("Grisha")
--     warehouse.Batumi:AddAsset("Molniya")
--     warehouse.Batumi:AddAsset("Neustrashimy")
--     warehouse.Batumi:AddAsset("Rezky")
--     warehouse.Batumi:AddAsset("Moskva")
--     warehouse.Batumi:AddAsset("Pyotr Velikiy")
--     warehouse.Batumi:AddAsset("Kuznetsov")
--     warehouse.Batumi:AddAsset("Zvezdny")
--     warehouse.Batumi:AddAsset("Yakushev")
--     warehouse.Batumi:AddAsset("Elnya")
--     warehouse.Batumi:AddAsset("Ivanov")
--     warehouse.Batumi:AddAsset("Yantai")
--     warehouse.Batumi:AddAsset("Type 052C")
--     warehouse.Batumi:AddAsset("Guangzhou")
--
--     -- Get Number of ships at Batumi.
--     local nships=warehouse.Batumi:GetNumberOfAssets(WAREHOUSE.Descriptor.CATEGORY, Group.Category.SHIP)
--
--     -- Send one ship every 3 minutes (ships do not evade each other well, so we need a bit space between them).
--     for i=1, nships do
--       warehouse.Batumi:__AddRequest(180*(i-1)+10, warehouse.Kobuleti, WAREHOUSE.Descriptor.CATEGORY, Group.Category.SHIP, 1)
--     end
--
-- ## Example 10: Warehouse on Aircraft Carrier
--
-- This example shows how to spawn assets from a warehouse located on an aircraft carrier. The warehouse must still be represented by a
-- physical static object. However, on a carrier space is limit so we take a smaller static. In priciple one could also take something
-- like a windsock.
--
-- ![Banner Image](..\Presentations\WAREHOUSE\Warehouse_Carrier.png)
--
-- USS Stennis requests F/A-18s from Batumi. At the same time Kobuleti requests F/A-18s from the Stennis which currently does not have any.
-- So first, Batumi delivers the fighters to the Stennis. After they arrived they are deployed again and send to Kobuleti.
--
--     -- Start warehouses.
--     warehouse.Batumi:Start()
--     warehouse.Stennis:Start()
--     warehouse.Kobuleti:Start()
--
--     -- Add F/A-18 2-ship flight to Batmi.
--     warehouse.Batumi:AddAsset("F/A-18C 2ship", 1)
--
--     -- USS Stennis requests F/A-18 from Batumi.
--     warehouse.Batumi:AddRequest(warehouse.Stennis, WAREHOUSE.Descriptor.GROUPNAME, "F/A-18C 2ship")
--
--     -- Kobuleti requests F/A-18 from USS Stennis.
--     warehouse.Stennis:AddRequest(warehouse.Kobuleti, WAREHOUSE.Descriptor.GROUPNAME, "F/A-18C 2ship")
--
-- ## Example 11: Aircraft Carrier - Rescue Helo and Escort
--
-- After 10 seconds we make a self request for a rescue helicopter. Note, that the @{#WAREHOUSE.AddRequest} function has a parameter which lets you
-- specify an "Assignment". This can be later used to identify the request and take the right actions.
--
-- Once the request is processed, the @{#WAREHOUSE.OnAfterSelfRequest} function is called. This is where we hook in and postprocess the spawned assets.
-- In particular, we use the @{AI.AI_Formation#AI_FORMATION} class to make some nice escorts for our carrier.
--
-- When the resue helo is spawned, we can check that this is the correct asset and make the helo go into formation with the carrier.
-- Once the helo runs out of fuel, it will automatically return to the ship and land. For the warehouse, this means that the "cargo", i.e. the helicopter
-- has been delivered - assets can be delivered to other warehouses and to the same warehouse - hence a *self* request.
-- When that happens, the **Delivered** event is triggered and the @{#WAREHOUSE.OnAfterDelivered} function called. This can now be used to spawn
-- a fresh helo. Effectively, there we created an infinite, never ending loop. So a rescue helo will be up at all times.
--
-- After 30 and 45 seconds requests for five groups of armed speedboats are made. These will be spawned in the port zone right behind the carrier.
-- The first five groups will go port of the carrier an form a left wing formation. The seconds groups will to the analogue on the starboard side.
-- **Note** that in order to spawn naval assets a warehouse needs a port (zone). Since the carrier and hence the warehouse is mobile, we define a moving
-- zone as @{Core.Zone#ZONE_UNIT} with the carrier as reference unit. The "port" of the Stennis at its stern so all naval assets are spawned behind the carrier.
--
--     -- Start warehouse on USS Stennis.
--     warehouse.Stennis:Start()
--
--     -- Aircraft carrier gets a moving zone right behind it as port.
--     warehouse.Stennis:SetPortZone(ZONE_UNIT:New("Warehouse Stennis Port Zone", UNIT:FindByName("USS Stennis"), 100, {rho=250, theta=180, relative_to_unit=true}))
--
--     -- Add speedboat assets.
--     warehouse.Stennis:AddAsset("Speedboat", 10)
--     warehouse.Stennis:AddAsset("CH-53E", 1)
--
--     -- Self request of speed boats.
--     warehouse.Stennis:__AddRequest(10, warehouse.Stennis, WAREHOUSE.Descriptor.GROUPNAME, "CH-53E", 1, nil, nil, nil, "Rescue Helo")
--     warehouse.Stennis:__AddRequest(30, warehouse.Stennis, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.NAVAL_ARMEDSHIP, 5, nil, nil, nil, "Speedboats Left")
--     warehouse.Stennis:__AddRequest(45, warehouse.Stennis, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.NAVAL_ARMEDSHIP, 5, nil, nil, nil, "Speedboats Right")
--
--     --- Function called after self request
--     function warehouse.Stennis:OnAfterSelfRequest(From, Event, To,_groupset, request)
--       local groupset=_groupset --Core.Set#SET_GROUP
--       local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--       -- USS Stennis is the mother ship.
--       local Mother=UNIT:FindByName("USS Stennis")
--
--       -- Get assignment of the request.
--       local assignment=warehouse.Stennis:GetAssignment(request)
--
--       if assignment=="Speedboats Left" then
--
--         -- Define AI Formation object.
--         -- Note that this has to be a global variable or the garbage collector will remove it for some reason!
--         CarrierFormationLeft = AI_FORMATION:New(Mother, groupset, "Left Formation with Carrier", "Escort Carrier.")
--
--         -- Formation parameters.
--         CarrierFormationLeft:FormationLeftWing(200 ,50, 0, 0, 500, 50)
--         CarrierFormationLeft:__Start(2)
--
--         for _,group in pairs(groupset:GetSetObjects()) do
--           local group=group --Wrapper.Group#GROUP
--           group:FlareRed()
--         end
--
--       elseif assignment=="Speedboats Right" then
--
--         -- Define AI Formation object.
--         -- Note that this has to be a global variable or the garbage collector will remove it for some reason!
--         CarrierFormationRight = AI_FORMATION:New(Mother, groupset, "Right Formation with Carrier", "Escort Carrier.")
--
--         -- Formation parameters.
--         CarrierFormationRight:FormationRightWing(200 ,50, 0, 0, 500, 50)
--         CarrierFormationRight:__Start(2)
--
--         for _,group in pairs(groupset:GetSetObjects()) do
--           local group=group --Wrapper.Group#GROUP
--           group:FlareGreen()
--         end
--
--       elseif assignment=="Rescue Helo" then
--
--         -- Start uncontrolled helo.
--         local group=groupset:GetFirst() --Wrapper.Group#GROUP
--         group:StartUncontrolled()
--
--         -- Define AI Formation object.
--         CarrierFormationHelo = AI_FORMATION:New(Mother, groupset, "Helo Formation with Carrier", "Fly Formation.")
--
--         -- Formation parameters.
--         CarrierFormationHelo:FormationCenterWing(-150, 50, 20, 50, 100, 50)
--         CarrierFormationHelo:__Start(2)
--
--       end
--
--       --- When the helo is out of fuel, it will return to the carrier and should be delivered.
--       function warehouse.Stennis:OnAfterDelivered(From,Event,To,request)
--         local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--         -- So we start another request.
--         if request.assignment=="Rescue Helo" then
--           warehouse.Stennis:__AddRequest(10, warehouse.Stennis, WAREHOUSE.Descriptor.GROUPNAME, "CH-53E", 1, nil, nil, nil, "Rescue Helo")
--         end
--       end
--
--     end
--
-- ## Example 12: Pause a Warehouse
--
-- This example shows how to pause and unpause a warehouse. In paused state, requests will not be processed but assets can be added and requests be added.
--
--    * Warehouse Batumi is paused after 10 seconds.
--    * Request from Berlin after 15 which will not be processed.
--    * New tank assets for Batumi after 20 seconds. This is possible also in paused state.
--    * Batumi unpaused after 30 seconds. Queued request from Berlin can be processed.
--    * Berlin is paused after 60 seconds.
--    * Berlin requests tanks from Batumi after 90 seconds. Request is not processed because Berlin is paused and not running.
--    * Berlin is unpaused after 120 seconds. Queued request for tanks from Batumi can not be processed.
--
-- Here is the code:
--
--     -- Start Warehouse at Batumi.
--     warehouse.Batumi:Start()
--
--     -- Start Warehouse Berlin.
--     warehouse.Berlin:Start()
--
--     -- Add 20 infantry groups and 5 tank platoons as assets at Batumi.
--     warehouse.Batumi:AddAsset("Infantry Platoon Alpha", 20)
--
--     -- Pause the warehouse after 10 seconds
--     warehouse.Batumi:__Pause(10)
--
--     -- Add a request from Berlin after 15 seconds. A request can be added but not be processed while warehouse is paused.
--     warehouse.Batumi:__AddRequest(15, warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 1)
--
--     -- New asset added after 20 seconds. This is possible even if the warehouse is paused.
--     warehouse.Batumi:__AddAsset(20, "Abrams", 5)
--
--     -- Unpause warehouse after 30 seconds. Now the request from Berlin can be processed.
--     warehouse.Batumi:__Unpause(30)
--
--     -- Pause warehouse Berlin
--     warehouse.Berlin:__Pause(60)
--
--     -- After 90 seconds request from Berlin for tanks.
--     warehouse.Batumi:__AddRequest(90, warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_TANK, 1)
--
--     -- After 120 seconds unpause Berlin.
--     warehouse.Berlin:__Unpause(120)
--
-- ## Example 13: Battlefield Air Interdiction
--
-- This example show how to couple the WAREHOUSE class with the @{AI.AI_BAI} class.
-- Four enemy targets have been located at the famous Kobuleti X. All three available Viggen 2-ship flights are assigned to kill at least one of the BMPs to complete their mission.
--
--     -- Start Warehouse at Kobuleti.
--     warehouse.Kobuleti:Start()
--
--     -- Add three 2-ship groups of Viggens.
--     warehouse.Kobuleti:AddAsset("Viggen 2ship", 3)
--
--     -- Self request for all Viggen assets.
--     warehouse.Kobuleti:AddRequest(warehouse.Kobuleti, WAREHOUSE.Descriptor.GROUPNAME, "Viggen 2ship", WAREHOUSE.Quantity.ALL, nil, nil, nil, "BAI")
--
--     -- Red targets at Kobuleti X (late activated).
--     local RedTargets=GROUP:FindByName("Red IVF Alpha")
--
--     -- Activate the targets.
--     RedTargets:Activate()
--
--     -- Do something with the spawned aircraft.
--     function warehouse.Kobuleti:OnAfterSelfRequest(From,Event,To,groupset,request)
--       local groupset=groupset --Core.Set#SET_GROUP
--       local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--       if request.assignment=="BAI" then
--
--         for _,group in pairs(groupset:GetSetObjects()) do
--           local group=group --Wrapper.Group#GROUP
--
--           -- Start uncontrolled aircraft.
--           group:StartUncontrolled()
--
--           local BAI=AI_BAI_ZONE:New(ZONE:New("Patrol Zone Kobuleti"), 500, 1000, 500, 600, ZONE:New("Patrol Zone Kobuleti"))
--
--           -- Tell the program to use the object (in this case called BAIPlane) as the group to use in the BAI function
--           BAI:SetControllable(group)
--
--           -- Function checking if targets are still alive
--           local function CheckTargets()
--             local nTargets=RedTargets:GetSize()
--             local nInitial=RedTargets:GetInitialSize()
--             local nDead=nInitial-nTargets
--             local nRequired=1  -- Let's make this easy.
--             if RedTargets:IsAlive() and nDead < nRequired then
--               MESSAGE:New(string.format("BAI Mission: %d of %d red targets still alive. At least %d targets need to be eliminated.", nTargets, nInitial, nRequired), 5):ToAll()
--             else
--               MESSAGE:New("BAI Mission: The required red targets are destroyed.", 30):ToAll()
--               BAI:__Accomplish(1) -- Now they should fly back to the patrolzone and patrol.
--             end
--           end
--
--           -- Start scheduler to monitor number of targets.
--           local Check, CheckScheduleID = SCHEDULER:New(nil, CheckTargets, {}, 60, 60)
--
--           -- When the targets in the zone are destroyed, (see scheduled function), the planes will return home ...
--           function BAI:OnAfterAccomplish( Controllable, From, Event, To )
--             MESSAGE:New( "BAI Mission: Sending the Viggens back to base.", 30):ToAll()
--             Check:Stop(CheckScheduleID)
--             BAI:__RTB(1)
--           end
--
--           -- Start BAI
--           BAI:Start()
--
--           -- Engage after 5 minutes.
--           BAI:__Engage(300)
--
--           -- RTB after 30 min max.
--           BAI:__RTB(-30*60)
--
--         end
--       end
--
--     end
--
-- ## Example 14: Strategic Bombing
--
-- This example shows how to employ strategic bombers in a mission. Three B-52s are launched at Kobuleti with the assignment to wipe out the enemy warehouse at Sukhumi.
-- The bombers will get a flight path and make their approach from the South at an altitude of 5000 m ASL. After their bombing run, they will return to Kobuleti and
-- added back to stock.
--
--     -- Start warehouses
--     warehouse.Kobuleti:Start()
--     warehouse.Sukhumi:Start()
--
--     -- Add a strategic bomber assets
--     warehouse.Kobuleti:AddAsset("B-52H", 3)
--
--     -- Request bombers for specific task of bombing Sukhumi warehouse.
--     warehouse.Kobuleti:AddRequest(warehouse.Kobuleti, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.AIR_BOMBER, WAREHOUSE.Quantity.ALL, nil, nil, nil, "Bomb Sukhumi")
--
--     -- Specify assignment after bombers have been spawned.
--     function warehouse.Kobuleti:OnAfterSelfRequest(From, Event, To, groupset, request)
--       local groupset=groupset --Core.Set#SET_GROUP
--
--       -- Get assignment of this request.
--       local assignment=warehouse.Kobuleti:GetAssignment(request)
--
--       if assignment=="Bomb Sukhumi" then
--
--         for _,_group in pairs(groupset:GetSet()) do
--           local group=_group --Wrapper.Group#GROUP
--
--           -- Start uncontrolled aircraft.
--           group:StartUncontrolled()
--
--           -- Target coordinate!
--           local ToCoord=warehouse.Sukhumi:GetCoordinate():SetAltitude(5000)
--
--           -- Home coordinate.
--           local HomeCoord=warehouse.Kobuleti:GetCoordinate():SetAltitude(3000)
--
--           -- Task bomb Sukhumi warehouse using all bombs (2032) from direction 180 at altitude 5000 m.
--           local task=group:TaskBombing(warehouse.Sukhumi:GetCoordinate():GetVec2(), false, "All", nil , 180, 5000, 2032)
--
--           -- Define waypoints.
--           local WayPoints={}
--
--           -- Take off position.
--           WayPoints[1]=warehouse.Kobuleti:GetCoordinate():WaypointAirTakeOffParking()
--           -- Begin bombing run 20 km south of target.
--           WayPoints[2]=ToCoord:Translate(20*1000, 180):WaypointAirTurningPoint(nil, 600, {task}, "Bombing Run")
--           -- Return to base.
--           WayPoints[3]=HomeCoord:WaypointAirTurningPoint()
--           -- Land at homebase. Bombers are added back to stock and can be employed in later assignments.
--           WayPoints[4]=warehouse.Kobuleti:GetCoordinate():WaypointAirLanding()
--
--           -- Route bombers.
--           group:Route(WayPoints)
--         end
--
--       end
--     end
--
-- ## Example 15: Defining Off-Road Paths
--
-- For self propelled assets it is possible to define custom off-road paths from one warehouse to another via the @{#WAREHOUSE.AddOffRoadPath} function.
-- The waypoints of a path are taken from late activated units. In this example, two paths have been defined between the warehouses Kobuleti and FARP London.
-- Trucks are spawned at each warehouse and are guided along the paths to the other warehouse.
-- Note that if more than one path was defined, each asset group will randomly select its route.
--
--     -- Start warehouses
--     warehouse.Kobuleti:Start()
--     warehouse.London:Start()
--
--     -- Define a polygon zone as spawn zone at Kobuleti.
--     warehouse.Kobuleti:SetSpawnZone(ZONE_POLYGON:New("Warehouse Kobuleti Spawn Zone", GROUP:FindByName("Warehouse Kobuleti Spawn Zone")))
--
--     -- Add assets.
--     warehouse.Kobuleti:AddAsset("M978", 20)
--     warehouse.London:AddAsset("M818", 20)
--
--     -- Off two road paths from Kobuleti to London. The reverse path from London to Kobuleti is added automatically.
--     warehouse.Kobuleti:AddOffRoadPath(warehouse.London, GROUP:FindByName("Warehouse Kobuleti-London OffRoad Path 1"))
--     warehouse.Kobuleti:AddOffRoadPath(warehouse.London, GROUP:FindByName("Warehouse Kobuleti-London OffRoad Path 2"))
--
--     -- London requests all available trucks from Kobuleti.
--     warehouse.Kobuleti:AddRequest(warehouse.London, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_TRUCK, WAREHOUSE.Quantity.ALL)
--
--     -- Kobuleti requests all available trucks from London.
--     warehouse.London:AddRequest(warehouse.Kobuleti, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_TRUCK, WAREHOUSE.Quantity.HALF)
--
-- ## Example 16: Resupply of Dead Assets
--
-- Warehouse at FARP Berlin is located at the front line and sends infantry groups to the battle zone.
-- Whenever a group dies, a new group is send from the warehouse to the battle zone.
-- Additionally, for each dead group, Berlin requests resupply from Batumi.
--
--     -- Start warehouses.
--     warehouse.Batumi:Start()
--     warehouse.Berlin:Start()
--
--     -- Front line warehouse.
--     warehouse.Berlin:AddAsset("Infantry Platoon Alpha", 6)
--
--     -- Resupply warehouse.
--     warehouse.Batumi:AddAsset("Infantry Platoon Alpha", 50)
--
--     -- Battle zone near FARP Berlin. This is where the action is!
--     local BattleZone=ZONE:New("Virtual Battle Zone")
--
--     -- Send infantry groups to the battle zone. Two groups every ~60 seconds.
--     for i=1,2 do
--       local time=(i-1)*60+10
--       warehouse.Berlin:__AddRequest(time, warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 2, nil, nil, nil, "To Battle Zone")
--     end
--
--     -- Take care of the spawned units.
--     function warehouse.Berlin:OnAfterSelfRequest(From,Event,To,groupset,request)
--       local groupset=groupset --Core.Set#SET_GROUP
--       local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--       -- Get assignment of this request.
--       local assignment=warehouse.Berlin:GetAssignment(request)
--
--       if assignment=="To Battle Zone" then
--
--         for _,group in pairs(groupset:GetSet()) do
--           local group=group --Wrapper.Group#GROUP
--
--           -- Route group to Battle zone.
--           local ToCoord=BattleZone:GetRandomCoordinate()
--           group:RouteGroundOnRoad(ToCoord, group:GetSpeedMax()*0.8)
--
--           -- After 3-5 minutes we create an explosion to destroy the group.
--           SCHEDULER:New(nil, Explosion, {group, 50}, math.random(180, 300))
--         end
--
--       end
--
--     end
--
--     -- An asset has died ==> request resupply for it.
--     function warehouse.Berlin:OnAfterAssetDead(From, Event, To, asset, request)
--       local asset=asset       --Functional.Warehouse#WAREHOUSE.Assetitem
--       local request=request   --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--       -- Get assignment.
--       local assignment=warehouse.Berlin:GetAssignment(request)
--
--       -- Request resupply for dead asset from Batumi.
--       warehouse.Batumi:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, asset.attribute, nil, nil, nil, nil, "Resupply")
--
--       -- Send asset to Battle zone either now or when they arrive.
--       warehouse.Berlin:AddRequest(warehouse.Berlin, WAREHOUSE.Descriptor.ATTRIBUTE, asset.attribute, 1, nil, nil, nil, assignment)
--     end
--
-- ## Example 17: Supply Chains
--
-- Our remote warehouse "Pampa" south of Batumi needs assets but does not have any air infrastructure (FARP or airdrome).
-- Leopard 2 tanks are transported from Kobuleti to Batumi using two C-17As. From there they go be themselfs to Pampa.
-- Eight infantry groups and two mortar groups are also being transferred from Kobuleti to Batumi by helicopter.
-- The infantry has a higher priority and will be transported first using all available Mi-8 helicopters.
-- Once infantry has arrived at Batumi, it will walk by itself to warehouse Pampa.
-- The mortars can only be transported once the Mi-8 helos are available again, i.e. when the infantry has been delivered.
-- Once the mortars arrive at Batumi, they will be transported by APCs to Pampa.
--
--     -- Start warehouses.
--     warehouse.Kobuleti:Start()
--     warehouse.Batumi:Start()
--     warehouse.Pampa:Start()
--
--     -- Add assets to Kobuleti warehouse, which is our main hub.
--     warehouse.Kobuleti:AddAsset("C-130",  2)
--     warehouse.Kobuleti:AddAsset("C-17A",  2, nil, 77000)
--     warehouse.Kobuleti:AddAsset("Mi-8",  2, WAREHOUSE.Attribute.AIR_TRANSPORTHELO, nil, nil, nil, AI.Skill.EXCELLENT, {"Germany", "United Kingdom"})
--     warehouse.Kobuleti:AddAsset("Leopard 2", 10, nil, nil, 62000, 500)
--     warehouse.Kobuleti:AddAsset("Mortar Alpha", 10, nil, nil, 210)
--     warehouse.Kobuleti:AddAsset("Infantry Platoon Alpha", 20)
--
--     -- Transports at Batumi.
--     warehouse.Batumi:AddAsset("SPz Marder", 2)
--     warehouse.Batumi:AddAsset("TPz Fuchs", 2)
--
--     -- Tanks transported by plane from from Kobuleti to Batumi.
--     warehouse.Kobuleti:AddRequest(warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_TANK, 2, WAREHOUSE.TransportType.AIRPLANE, 2, 10, "Assets for Pampa")
--     -- Artillery transported by helicopter from Kobuleti to Batumi.
--     warehouse.Kobuleti:AddRequest(warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_ARTILLERY, 2, WAREHOUSE.TransportType.HELICOPTER, 2, 30, "Assets for Pampa via APC")
--     -- Infantry transported by helicopter from Kobuleti to Batumi.
--     warehouse.Kobuleti:AddRequest(warehouse.Batumi, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.GROUND_INFANTRY, 8, WAREHOUSE.TransportType.HELICOPTER, 2, 20, "Assets for Pampa")
--
--     --- Function handling assets delivered from Kobuleti warehouse.
--     function warehouse.Kobuleti:OnAfterDelivered(From, Event, To, request)
--       local request=request --Functional.Warehouse#WAREHOUSE.Pendingitem
--
--       -- Get assignment.
--       local assignment=warehouse.Kobuleti:GetAssignment(request)
--
--       -- Check if these assets were meant for Warehouse Pampa.
--       if assignment=="Assets for Pampa via APC" then
--         -- Forward everything that arrived at Batumi to Pampa via APC.
--         warehouse.Batumi:AddRequest(warehouse.Pampa, WAREHOUSE.Descriptor.ATTRIBUTE, request.cargoattribute, request.ndelivered, WAREHOUSE.TransportType.APC, WAREHOUSE.Quantity.ALL)
--       end
--     end
--
--     -- Forward all mobile ground assets to Pampa once they arrived.
--     function warehouse.Batumi:OnAfterNewAsset(From, Event, To, asset, assignment)
--       local asset=asset --Functional.Warehouse#WAREHOUSE.Assetitem
--       if assignment=="Assets for Pampa" then
--         if asset.category==Group.Category.GROUND and asset.speedmax>0 then
--           warehouse.Batumi:AddRequest(warehouse.Pampa, WAREHOUSE.Descriptor.GROUPNAME, asset.templatename)
--         end
--       end
--     end
--
--
-- @field #WAREHOUSE
WAREHOUSE = {
  ClassName     = "WAREHOUSE",
  Debug         = false,
  verbosity     =     0,
  lid           =   nil,
  Report        =  true,
  warehouse     =   nil,
  alias         =   nil,
  zone          =   nil,
  airbase       =   nil,
  airbasename   =   nil,
  road          =   nil,
  rail          =   nil,
  spawnzone     =   nil,
  uid           =   nil,
  dTstatus      =    30,
  queueid       =     0,
  stock         =    {},
  queue         =    {},
  pending       =    {},
  transporting  =    {},
  delivered     =    {},
  defending     =    {},
  portzone      =   nil,
  harborzone    =   nil,
  shippinglanes =    {},
  offroadpaths  =    {},
  autodefence   = false,
  spawnzonemaxdist = 5000,
  autosave      = false,
  autosavepath  =   nil,
  autosavefile  =   nil,
  saveparking   = false,
  isUnit        = false,
  isShip        = false,
  lowfuelthresh =  0.15,
  respawnafterdestroyed=false,
  respawndelay  =   nil,
}

--- Item of the warehouse stock table.
-- @type WAREHOUSE.Assetitem
-- @field #number uid Unique id of the asset.
-- @field #number wid ID of the warehouse this asset belongs to.
-- @field #number rid Request ID of this asset (if any).
-- @field #string templatename Name of the template group.
-- @field #table template The spawn template of the group.
-- @field DCS#Group.Category category Category of the group.
-- @field #string unittype Type of the first unit of the group as obtained by the Object.getTypeName() DCS API function.
-- @field #number nunits Number of units in the group.
-- @field #number range Range of the unit in meters.
-- @field #number speedmax Maximum speed in km/h the group can do.
-- @field #number size Maximum size in length and with of the asset in meters.
-- @field #number weight The weight of the whole asset group in kilograms.
-- @field DCS#Object.Desc DCSdesc All DCS descriptors.
-- @field #WAREHOUSE.Attribute attribute Generalized attribute of the group.
-- @field #table cargobay Array of cargo bays of all units in an asset group.
-- @field #number cargobaytot Total weight in kg that fits in the cargo bay of all asset group units.
-- @field #number cargobaymax Largest cargo bay of all units in the group.
-- @field #number loadradius Distance when cargo is loaded into the carrier.
-- @field DCS#AI.Skill skill Skill of AI unit.
-- @field #string livery Livery of the asset.
-- @field #string assignment Assignment of the asset. This could, e.g., be used in the @{#WAREHOUSE.OnAfterNewAsset) function.
-- @field #boolean spawned If true, asset was spawned into the cruel world. If false, it is still in stock.
-- @field #string spawngroupname Name of the spawned group.
-- @field #boolean iscargo If true, asset is cargo. If false asset is transport. Nil if in stock.
-- @field #boolean arrived If true, asset arrived at its destination.
-- 
-- @field #number damage Damage of asset group in percent.
-- @field Ops.Airwing#AIRWING.Payload payload The payload of the asset.
-- @field Ops.OpsGroup#OPSGROUP flightgroup The flightgroup object.
-- @field Ops.Cohort#COHORT cohort The cohort this asset belongs to.
-- @field Ops.Legion#LEGION legion The legion this asset belonts to.
-- @field #string squadname Name of the squadron this asset belongs to.
-- @field #number Treturned Time stamp when asset returned to its legion (airwing, brigade).
-- @field #boolean requested If `true`, asset was requested and cannot be selected by another request.
-- @field #boolean isReserved If `true`, asset was reserved and cannot be selected by another request.

--- Item of the warehouse queue table.
-- @type WAREHOUSE.Queueitem
-- @field #number uid Unique id of the queue item.
-- @field #WAREHOUSE warehouse Requesting warehouse.
-- @field #WAREHOUSE.Descriptor assetdesc Descriptor of the requested asset. Enumerator of type @{#WAREHOUSE.Descriptor}.
-- @field assetdescval Value of the asset descriptor. Type depends on "assetdesc" descriptor.
-- @field #number nasset Number of asset groups requested.
-- @field #WAREHOUSE.TransportType transporttype Transport unit type.
-- @field #number ntransport Max. number of transport units requested.
-- @field #string assignment A keyword or text that later be used to identify this request and postprocess the assets.
-- @field #number prio Priority of the request. Number between 1 (high) and 100 (low).
-- @field Wrapper.Airbase#AIRBASE airbase The airbase beloning to requesting warehouse if any.
-- @field DCS#Airbase.Category category Category of the requesting airbase, i.e. airdrome, helipad/farp or ship.
-- @field #boolean toself Self request, i.e. warehouse requests assets from itself.
-- @field #table assets Table of self propelled (or cargo) and transport assets. Each element of the table is a @{#WAREHOUSE.Assetitem} and can be accessed by their asset ID.
-- @field #table cargoassets Table of cargo (or self propelled) assets. Each element of the table is a @{#WAREHOUSE.Assetitem}.
-- @field #number cargoattribute Attribute of cargo assets of type @{#WAREHOUSE.Attribute}.
-- @field #number cargocategory Category of cargo assets of type @{#WAREHOUSE.Category}.
-- @field #table transportassets Table of transport carrier assets. Each element of the table is a @{#WAREHOUSE.Assetitem}.
-- @field #number transportattribute Attribute of transport assets of type @{#WAREHOUSE.Attribute}.
-- @field #number transportcategory Category of transport assets of type @{#WAREHOUSE.Category}.
-- @field #boolean lateActivation Assets are spawned in late activated state.

--- Item of the warehouse pending queue table.
-- @type WAREHOUSE.Pendingitem
-- @field #number timestamp Absolute mission time in seconds when the request was processed.
-- @field #table assetproblem Table with assets that might have problems (damage or stuck).
-- @field Core.Set#SET_GROUP cargogroupset Set of cargo groups do be delivered.
-- @field #number ndelivered Number of groups delivered to destination.
-- @field Core.Set#SET_GROUP transportgroupset Set of cargo transport carrier groups.
-- @field Core.Set#SET_CARGO transportcargoset Set of cargo objects.
-- @field #table carriercargo Table holding the cargo groups of each carrier unit.
-- @field #number ntransporthome Number of transports back home.
-- @field #boolean lowfuel If true, at least one asset group is low on fuel.
-- @extends #WAREHOUSE.Queueitem

--- Descriptors enumerator describing the type of the asset.
-- @type WAREHOUSE.Descriptor
-- @field #string GROUPNAME Name of the asset template.
-- @field #string UNITTYPE Typename of the DCS unit, e.g. "A-10C".
-- @field #string ATTRIBUTE Generalized attribute @{#WAREHOUSE.Attribute}.
-- @field #string CATEGORY Asset category of type DCS#Group.Category, i.e. GROUND, AIRPLANE, HELICOPTER, SHIP, TRAIN.
-- @field #string ASSIGNMENT Assignment of asset when it was added.
-- @field #string ASSETLIST List of specific assets gives as a table of assets. Mind the curly brackets {}.
WAREHOUSE.Descriptor = {
  GROUPNAME="templatename",
  UNITTYPE="unittype",
  ATTRIBUTE="attribute",
  CATEGORY="category",
  ASSIGNMENT="assignment",
  ASSETLIST="assetlist,"
}

--- Generalized asset attributes. Can be used to request assets with certain general characteristics. See [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes) on hoggit.
-- @type WAREHOUSE.Attribute
-- @field #string AIR_TRANSPORTPLANE Airplane with transport capability. This can be used to transport other assets.
-- @field #string AIR_AWACS Airborne Early Warning and Control System.
-- @field #string AIR_FIGHTER Fighter, interceptor, ... airplane.
-- @field #string AIR_BOMBER Aircraft which can be used for strategic bombing.
-- @field #string AIR_TANKER Airplane which can refuel other aircraft.
-- @field #string AIR_TRANSPORTHELO Helicopter with transport capability. This can be used to transport other assets.
-- @field #string AIR_ATTACKHELO Attack helicopter.
-- @field #string AIR_UAV Unpiloted Aerial Vehicle, e.g. drones.
-- @field #string AIR_OTHER Any airborne unit that does not fall into any other airborne category.
-- @field #string GROUND_APC Infantry carriers, in particular Amoured Personell Carrier. This can be used to transport other assets.
-- @field #string GROUND_TRUCK Unarmed ground vehicles, which has the DCS "Truck" attribute.
-- @field #string GROUND_INFANTRY Ground infantry assets.
-- @field #string GROUND_IFV Ground infantry fighting vehicle.
-- @field #string GROUND_ARTILLERY Artillery assets.
-- @field #string GROUND_TANK Tanks (modern or old).
-- @field #string GROUND_TRAIN Trains. Not that trains are **not** yet properly implemented in DCS and cannot be used currently.
-- @field #string GROUND_EWR Early Warning Radar.
-- @field #string GROUND_AAA Anti-Aircraft Artillery.
-- @field #string GROUND_SAM Surface-to-Air Missile system or components.
-- @field #string GROUND_OTHER Any ground unit that does not fall into any other ground category.
-- @field #string NAVAL_AIRCRAFTCARRIER Aircraft carrier.
-- @field #string NAVAL_WARSHIP War ship, i.e. cruisers, destroyers, firgates and corvettes.
-- @field #string NAVAL_ARMEDSHIP Any armed ship that is not an aircraft carrier, a cruiser, destroyer, firgatte or corvette.
-- @field #string NAVAL_UNARMEDSHIP Any unarmed naval vessel.
-- @field #string NAVAL_OTHER Any naval unit that does not fall into any other naval category.
-- @field #string OTHER_UNKNOWN Anything that does not fall into any other category.
WAREHOUSE.Attribute = {
  AIR_TRANSPORTPLANE="Air_TransportPlane",
  AIR_AWACS="Air_AWACS",
  AIR_FIGHTER="Air_Fighter",
  AIR_BOMBER="Air_Bomber",
  AIR_TANKER="Air_Tanker",
  AIR_TRANSPORTHELO="Air_TransportHelo",
  AIR_ATTACKHELO="Air_AttackHelo",
  AIR_UAV="Air_UAV",
  AIR_OTHER="Air_OtherAir",
  GROUND_APC="Ground_APC",
  GROUND_TRUCK="Ground_Truck",
  GROUND_INFANTRY="Ground_Infantry",
  GROUND_IFV="Ground_IFV",
  GROUND_ARTILLERY="Ground_Artillery",
  GROUND_TANK="Ground_Tank",
  GROUND_TRAIN="Ground_Train",
  GROUND_EWR="Ground_EWR",
  GROUND_AAA="Ground_AAA",
  GROUND_SAM="Ground_SAM",
  GROUND_OTHER="Ground_OtherGround",
  NAVAL_AIRCRAFTCARRIER="Naval_AircraftCarrier",
  NAVAL_WARSHIP="Naval_WarShip",
  NAVAL_ARMEDSHIP="Naval_ArmedShip",
  NAVAL_UNARMEDSHIP="Naval_UnarmedShip",
  NAVAL_OTHER="Naval_OtherNaval",
  OTHER_UNKNOWN="Other_Unknown",
}

--- Cargo transport type. Defines how assets are transported to their destination.
-- @type WAREHOUSE.TransportType
-- @field #string AIRPLANE Transports are carried out by airplanes.
-- @field #string HELICOPTER Transports are carried out by helicopters.
-- @field #string APC Transports are conducted by APCs.
-- @field #string SHIP Transports are conducted by ships. Not implemented yet.
-- @field #string TRAIN Transports are conducted by trains. Not implemented yet. Also trains are buggy in DCS.
-- @field #string SELFPROPELLED Assets go to their destination by themselves. No transport carrier needed.
WAREHOUSE.TransportType = {
  AIRPLANE         = "Air_TransportPlane",
  HELICOPTER       = "Air_TransportHelo",
  APC              = "Ground_APC",
  TRAIN            = "Ground_Train",
  SHIP             = "Naval_UnarmedShip",
  AIRCRAFTCARRIER  = "Naval_AircraftCarrier",
  WARSHIP          = "Naval_WarShip",
  ARMEDSHIP        = "Naval_ArmedShip",
  SELFPROPELLED    = "Selfpropelled",
}

--- Warehouse quantity enumerator for selecting number of assets, e.g. all, half etc. of what is in stock rather than an absolute number.
-- @type WAREHOUSE.Quantity
-- @field #string ALL All "all" assets currently in stock.
-- @field #string THREEQUARTERS Three quarters "3/4" of assets in stock.
-- @field #string HALF Half "1/2" of assets in stock.
-- @field #string THIRD One third "1/3" of assets in stock.
-- @field #string QUARTER One quarter "1/4" of assets in stock.
WAREHOUSE.Quantity = {
  ALL           = "all",
  THREEQUARTERS = "3/4",
  HALF          = "1/2",
  THIRD         = "1/3",
  QUARTER       = "1/4",
}

--- Warehouse database. Note that this is a global array to have easier exchange between warehouses.
-- @type _WAREHOUSEDB
-- @field #number AssetID Unique ID of each asset. This is a running number, which is increased each time a new asset is added.
-- @field #table Assets Table holding registered assets, which are of type @{Functional.Warehouse#WAREHOUSE.Assetitem}.#
-- @field #number WarehouseID Unique ID of the warehouse. Running number.
-- @field #table Warehouses Table holding all defined @{#WAREHOUSE} objects by their unique ids.
_WAREHOUSEDB  = {
  AssetID     = 0,
  Assets      = {},
  WarehouseID = 0,
  Warehouses  = {}
}

--- Warehouse class version.
-- @field #string version
WAREHOUSE.version="1.0.2a"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO: Warehouse todo list.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add check if assets "on the move" are stationary. Can happen if ground units get stuck in buildings. If stationary auto complete transport by adding assets to request warehouse? Time?
-- TODO: Optimize findpathonroad. Do it only once (first time) and safe paths between warehouses similar to off-road paths.
-- NOGO: Spawn assets only virtually, i.e. remove requested assets from stock but do NOT spawn them ==> Interface to A2A dispatcher! Maybe do a negative sign on asset number?
-- TODO: Make more examples: ARTY, CAP, ...
-- TODO: Check also general requests like all ground. Is this a problem for self propelled if immobile units are among the assets? Check if transport.
-- TODO: Handle the case when units of a group die during the transfer.
-- DONE: Added harbours as interface for transport to/from warehouses. Simplifies process of spawning units near the ship, especially if cargo not self-propelled.
-- DONE: Test capturing a neutral warehouse.
-- DONE: Add save/load capability of warehouse <==> persistance after mission restart. Difficult in lua!
-- DONE: Get cargo bay and weight from CARGO_GROUP and GROUP. No necessary any more!
-- DONE: Add possibility to set weight and cargo bay manually in AddAsset function as optional parameters.
-- DONE: Check overlapping aircraft sometimes.
-- DONE: Case when all transports are killed and there is still cargo to be delivered. Put cargo back into warehouse. Should be done now!
-- DONE: Add transport units from dispatchers back to warehouse stock once they completed their mission.
-- DONE: Write documentation.
-- DONE: Add AAA, SAMs and UAVs to generalized attributes.
-- DONE: Add warehouse quantity enumerator.
-- DONE: Test mortars. Immobile units need a transport.
-- DONE: Set ROE for spawned groups.
-- DONE: Add offroad lanes between warehouses if road connection is not available.
-- DONE: Add possibility to add active groups. Need to create a pseudo template before destroy. <== Does not seem to be necessary any more.
-- DONE: Add a time stamp when an asset is added to the stock and for requests.
-- DONE: How to get a specific request once the cargo is delivered? Make addrequest addasset non FSM function? Callback for requests like in SPAWN?
-- DONE: Add autoselfdefence switch and user function. Default should be off.
-- DONE: Warehouse re-capturing not working?!
-- DONE: Naval assets dont go back into stock once arrived.
-- DONE: Take cargo weight into consideration, when selecting transport assets.
-- DONE: Add ports for spawning naval assets.
-- DONE: Add shipping lanes between warehouses.
-- DONE: Handle cases with immobile units <== should be handled by dispatcher classes.
-- DONE: Handle cases for aircraft carriers and other ships. Place warehouse on carrier possible? On others probably not - exclude them?
-- DONE: Add general message function for sending to coalition or debug.
-- DONE: Fine tune event handlers.
-- DONE: Improve generalized attributes.
-- DONE: If warehouse is destroyed, all asssets are gone.
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
-- @param Wrapper.Static#STATIC warehouse The physical structure representing the warehouse. Can also be a @{Wrapper.Unit#UNIT}.
-- @param #string alias (Optional) Alias of the warehouse, i.e. the name it will be called when sending messages etc. Default is the name of the static/unit representing the warehouse.
-- @return #WAREHOUSE self
function WAREHOUSE:New(warehouse, alias)

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #WAREHOUSE

  -- Check if just a string was given and convert to static.
  if type(warehouse)=="string" then
    local warehousename=warehouse    
    warehouse=UNIT:FindByName(warehousename)
    if warehouse==nil then
      warehouse=STATIC:FindByName(warehousename, true)
    end
  end

  -- Nil check.
  if warehouse==nil then
    env.error("ERROR: Warehouse does not exist!")
    return nil
  end
  
  -- Check if we have a STATIC or UNIT object.
  if warehouse:IsInstanceOf("STATIC") then
    self.isUnit=false
  elseif warehouse:IsInstanceOf("UNIT") then
    self.isUnit=true
    if warehouse:IsShip() then
      self.isShip=true
    end  
  else
    env.error("ERROR: Warehouse is neither STATIC nor UNIT object!")
    return nil    
  end

  -- Set alias.
  self.alias=alias or warehouse:GetName()

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("WAREHOUSE %s | ", self.alias)
  
  -- Print version.
  self:I(self.lid..string.format("Adding warehouse v%s for structure %s [isUnit=%s, isShip=%s]", WAREHOUSE.version, warehouse:GetName(), tostring(self:IsUnit()), tostring(self:IsShip())))  

  -- Set some variables.
  self.warehouse=warehouse

  -- Increase global warehouse counter.
  _WAREHOUSEDB.WarehouseID=_WAREHOUSEDB.WarehouseID+1

  -- Set unique ID for this warehouse.
  self.uid=_WAREHOUSEDB.WarehouseID

  -- Coalition of the warehouse.
  self.coalition=self.warehouse:GetCoalition()

  -- Country of the warehouse.
  self.countryid=self.warehouse:GetCountry()

  -- Closest of the same coalition but within 5 km range.
  local _airbase=self:GetCoordinate():GetClosestAirbase(nil, self:GetCoalition())
  if _airbase and _airbase:GetCoordinate():Get2DDistance(self:GetCoordinate()) <= 5000 then
    self:SetAirbase(_airbase)
  end

  -- Define warehouse and default spawn zone.
  if self.isShip then
    self.zone=ZONE_AIRBASE:New(self.warehouse:GetName(), 1000)
    self.spawnzone=ZONE_AIRBASE:New(self.warehouse:GetName(), 1000)  
  else
    self.zone=ZONE_RADIUS:New(string.format("Warehouse zone %s", self.warehouse:GetName()), warehouse:GetVec2(), 500)
    self.spawnzone=ZONE_RADIUS:New(string.format("Warehouse %s spawn zone", self.warehouse:GetName()), warehouse:GetVec2(), 250)
  end
    

  -- Defaults
  self:SetMarker(true)
  self:SetReportOff()
  self:SetRunwayRepairtime()
  self.allowSpawnOnClientSpots=false

  -- Add warehouse to database.
  _WAREHOUSEDB.Warehouses[self.uid]=self

  -----------------------
  --- FSM Transitions ---
  -----------------------

  -- Start State.
  self:SetStartState("NotReadyYet")

  -- Add FSM transitions.
  --                 From State   -->   Event        -->     To State
  self:AddTransition("NotReadyYet",     "Load",              "Loaded")      -- Load the warehouse state from scatch.
  self:AddTransition("Stopped",         "Load",              "Loaded")      -- Load the warehouse state stopped state.

  self:AddTransition("NotReadyYet",     "Start",             "Running")     -- Start the warehouse from scratch.
  self:AddTransition("Loaded",          "Start",             "Running")     -- Start the warehouse when loaded from disk.

  self:AddTransition("*",               "Status",            "*")           -- Status update.

  self:AddTransition("*",               "AddAsset",          "*")           -- Add asset to warehouse stock.
  self:AddTransition("*",               "NewAsset",          "*")           -- New asset was added to warehouse stock.

  self:AddTransition("*",               "AddRequest",        "*")           -- New request from other warehouse.
  self:AddTransition("Running",         "Request",           "*")           -- Process a request. Only in running mode.
  self:AddTransition("Running",         "RequestSpawned",    "*")           -- Assets of request were spawned.
  self:AddTransition("Attacked",        "Request",           "*")           -- Process a request. Only in running mode.

  self:AddTransition("*",               "Unloaded",          "*")           -- Cargo has been unloaded from the carrier (unused ==> unnecessary?).
  self:AddTransition("*",               "AssetSpawned",      "*")           -- Asset has been spawned into the world.
  self:AddTransition("*",               "AssetLowFuel",      "*")           -- Asset is low on fuel.

  self:AddTransition("*",               "Arrived",           "*")           -- Cargo or transport group has arrived.

  self:AddTransition("*",               "Delivered",         "*")           -- All cargo groups of a request have been delivered to the requesting warehouse.
  self:AddTransition("Running",         "SelfRequest",       "*")           -- Request to warehouse itself. Requested assets are only spawned but not delivered anywhere.
  self:AddTransition("Attacked",        "SelfRequest",       "*")           -- Request to warehouse itself. Also possible when warehouse is under attack!
  self:AddTransition("Running",         "Pause",             "Paused")      -- Pause the processing of new requests. Still possible to add assets and requests.
  self:AddTransition("Paused",          "Unpause",           "Running")     -- Unpause the warehouse. Queued requests are processed again.
  self:AddTransition("*",               "Stop",              "Stopped")     -- Stop the warehouse.
  self:AddTransition("Stopped",         "Restart",           "Running")     -- Restart the warehouse when it was stopped before.
  self:AddTransition("Loaded",          "Restart",           "Running")     -- Restart the warehouse when assets were loaded from file before.
  self:AddTransition("*",               "Save",              "*")           -- Save the warehouse state to disk.
  self:AddTransition("*",               "Attacked",          "Attacked")    -- Warehouse is under attack by enemy coalition.
  self:AddTransition("Attacked",        "Defeated",          "Running")     -- Attack by other coalition was defeated!
  self:AddTransition("*",               "ChangeCountry",     "*")           -- Change country (and coalition) of the warehouse. Warehouse is respawned!
  self:AddTransition("Attacked",        "Captured",          "Running")     -- Warehouse was captured by another coalition. It must have been attacked first.
  self:AddTransition("*",               "AirbaseCaptured",   "*")           -- Airbase was captured by other coalition.
  self:AddTransition("*",               "AirbaseRecaptured", "*")           -- Airbase was re-captured from other coalition.
  self:AddTransition("*",               "RunwayDestroyed",   "*")           -- Runway of the airbase was destroyed.
  self:AddTransition("*",               "RunwayRepaired",    "*")           -- Runway of the airbase was repaired.
  self:AddTransition("*",               "AssetDead",         "*")           -- An asset group died.
  self:AddTransition("*",               "Destroyed",         "Destroyed")   -- Warehouse was destroyed. All assets in stock are gone and warehouse is stopped.
  self:AddTransition("Destroyed",       "Respawn",           "Running")     -- Respawn warehouse after it was destroyed.

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

  --- Triggers the FSM event "Stop". Stops the warehouse and all its event handlers. All waiting and pending queue items are deleted as well and all assets are removed from stock.
  -- @function [parent=#WAREHOUSE] Stop
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Stop" after a delay. Stops the warehouse and all its event handlers. All waiting and pending queue items are deleted as well and all assets are removed from stock.
  -- @function [parent=#WAREHOUSE] __Stop
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Restart". Restarts the warehouse from stopped state by reactivating the event handlers *only*.
  -- @function [parent=#WAREHOUSE] Restart
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Restart" after a delay. Restarts the warehouse from stopped state by reactivating the event handlers *only*.
  -- @function [parent=#WAREHOUSE] __Restart
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Respawn".
  -- @function [parent=#WAREHOUSE] Respawn
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Respawn" after a delay.
  -- @function [parent=#WAREHOUSE] __Respawn
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- On after "Respawn" event user function.
  -- @function [parent=#WAREHOUSE] OnAfterRespawn
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "Pause". Pauses the warehouse. Assets can still be added and requests be made. However, requests are not processed.
  -- @function [parent=#WAREHOUSE] Pause
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


  --- Trigger the FSM event "AddAsset". Add a group to the warehouse stock.
  -- @function [parent=#WAREHOUSE] AddAsset
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group Group to be added as new asset.
  -- @param #number ngroups (Optional) Number of groups to add to the warehouse stock. Default is 1.
  -- @param #WAREHOUSE.Attribute forceattribute (Optional) Explicitly force a generalized attribute for the asset. This has to be an @{#WAREHOUSE.Attribute}.
  -- @param #number forcecargobay (Optional) Explicitly force cargobay weight limit in kg for cargo carriers. This is for each *unit* of the group.
  -- @param #number forceweight (Optional) Explicitly force weight in kg of each unit in the group.
  -- @param #number loadradius (Optional) The distance in meters when the cargo is loaded into the carrier. Default is the bounding box size of the carrier.
  -- @param DCS#AI.Skill skill Skill of the asset.
  -- @param #table liveries Table of livery names. When the asset is spawned one livery is chosen randomly.
  -- @param #string assignment A free to choose string specifying an assignment for the asset. This can be used with the @{#WAREHOUSE.OnAfterNewAsset} function.

  --- Trigger the FSM event "AddAsset" with a delay. Add a group to the warehouse stock.
  -- @function [parent=#WAREHOUSE] __AddAsset
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Group#GROUP group Group to be added as new asset.
  -- @param #number ngroups (Optional) Number of groups to add to the warehouse stock. Default is 1.
  -- @param #WAREHOUSE.Attribute forceattribute (Optional) Explicitly force a generalized attribute for the asset. This has to be an @{#WAREHOUSE.Attribute}.
  -- @param #number forcecargobay (Optional) Explicitly force cargobay weight limit in kg for cargo carriers. This is for each *unit* of the group.
  -- @param #number forceweight (Optional) Explicitly force weight in kg of each unit in the group.
  -- @param #number loadradius (Optional) The distance in meters when the cargo is loaded into the carrier. Default is the bounding box size of the carrier.
  -- @param DCS#AI.Skill skill Skill of the asset.
  -- @param #table liveries Table of livery names. When the asset is spawned one livery is chosen randomly.
  -- @param #string assignment A free to choose string specifying an assignment for the asset. This can be used with the @{#WAREHOUSE.OnAfterNewAsset} function.


  --- Triggers the FSM delayed event "NewAsset" when a new asset has been added to the warehouse stock.
  -- @function [parent=#WAREHOUSE] NewAsset
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE.Assetitem asset The new asset.
  -- @param #string assignment (Optional) Assignment text for the asset.

  --- Triggers the FSM delayed event "NewAsset" when a new asset has been added to the warehouse stock.
  -- @function [parent=#WAREHOUSE] __NewAsset
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE.Assetitem asset The new asset.
  -- @param #string assignment (Optional) Assignment text for the asset.

  --- On after "NewAsset" event user function. A new asset has been added to the warehouse stock.
  -- @function [parent=#WAREHOUSE] OnAfterNewAsset
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #WAREHOUSE.Assetitem asset The asset that has just been added.
  -- @param #string assignment (Optional) Assignment text for the asset.


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
  -- @param #string Assignment A keyword or text that later be used to identify this request and postprocess the assets.

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
  -- @param #string Assignment A keyword or text that later be used to identify this request and postprocess the assets.


  --- Triggers the FSM event "Request". Executes a request from the queue if possible.
  -- @function [parent=#WAREHOUSE] Request
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.

  --- Triggers the FSM event "Request" after a delay. Executes a request from the queue if possible.
  -- @function [parent=#WAREHOUSE] __Request
  -- @param #WAREHOUSE self
  -- @param #number Delay Delay in seconds.
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.

  --- On before "Request" user function. The necessary cargo and transport assets will be spawned. Time to set some additional asset parameters.
  -- @function [parent=#WAREHOUSE] OnBeforeRequest
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.

  --- On after "Request" user function. The necessary cargo and transport assets were spawned.
  -- @function [parent=#WAREHOUSE] OnAfterRequest
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #WAREHOUSE.Queueitem Request Information table of the request.


  --- Triggers the FSM event "Arrived" when a group has arrived at the destination warehouse.
  -- This function should always be called from the sending and not the receiving warehouse.
  -- If the group is a cargo asset, it is added to the receiving warehouse. If the group is a transporter it
  -- is added to the sending warehouse since carriers are supposed to return to their home warehouse once
  -- all cargo was delivered.
  -- @function [parent=#WAREHOUSE] Arrived
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group Group that has arrived.

  --- Triggers the FSM event "Arrived" after a delay when a group has arrived at the destination.
  -- This function should always be called from the sending and not the receiving warehouse.
  -- If the group is a cargo asset, it is added to the receiving warehouse. If the group is a transporter it
  -- is added to the sending warehouse since carriers are supposed to return to their home warehouse once
  -- @function [parent=#WAREHOUSE] __Arrived
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Group#GROUP group Group that has arrived.

  --- On after "Arrived" event user function. Called when a group has arrived at its destination.
  -- @function [parent=#WAREHOUSE] OnAfterArrived
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP group Group that has arrived.


  --- Triggers the FSM event "Delivered". All (cargo) assets of a request have been delivered to the receiving warehouse.
  -- @function [parent=#WAREHOUSE] Delivered
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE.Pendingitem request Pending request that was now delivered.

  --- Triggers the FSM event "Delivered" after a delay. A group has been delivered from the warehouse to another warehouse.
  -- @function [parent=#WAREHOUSE] __Delivered
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE.Pendingitem request Pending request that was now delivered.

  --- On after "Delivered" event user function. Called when a group has been delivered from the warehouse to another warehouse.
  -- @function [parent=#WAREHOUSE] OnAfterDelivered
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #WAREHOUSE.Pendingitem request Pending request that was now delivered.


  --- Triggers the FSM event "SelfRequest". Request was initiated from the warehouse to itself. Groups are just spawned at the warehouse or the associated airbase.
  -- If the warehouse is currently under attack when the self request is made, the self request is added to the defending table. One the attack is defeated,
  -- this request is used to put the groups back into the warehouse stock.
  -- @function [parent=#WAREHOUSE] SelfRequest
  -- @param #WAREHOUSE self
  -- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
  -- @param #WAREHOUSE.Pendingitem request Pending self request.

  --- Triggers the FSM event "SelfRequest" with a delay. Request was initiated from the warehouse to itself. Groups are just spawned at the warehouse or the associated airbase.
  -- If the warehouse is currently under attack when the self request is made, the self request is added to the defending table. One the attack is defeated,
  -- this request is used to put the groups back into the warehouse stock.
  -- @function [parent=#WAREHOUSE] __SelfRequest
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Core.Set#SET_GROUP groupset The set of cargo groups that was delivered to the warehouse itself.
  -- @param #WAREHOUSE.Pendingitem request Pending self request.

  --- On after "SelfRequest" event. Request was initiated from the warehouse to itself. Groups are simply spawned at the warehouse or the associated airbase.
  -- All requested assets are passed as a @{Core.Set#SET_GROUP} and can be used for further tasks or in other MOOSE classes.
  -- Note that airborne assets are spawned in uncontrolled state so they do not simply "fly away" after spawning.
  --
  -- @usage
  -- --- Self request event. Triggered once the assets are spawned in the spawn zone or at the airbase.
  -- function mywarehouse:OnAfterSelfRequest(From, Event, To, groupset, request)
  --   local groupset=groupset --Core.Set#SET_GROUP
  --
  --   -- Loop over all groups spawned from that request.
  --   for _,group in pairs(groupset:GetSetObjects()) do
  --     local group=group --Wrapper.Group#GROUP
  --
  --     -- Gree smoke on spawned group.
  --     group:SmokeGreen()
  --
  --     -- Activate uncontrolled airborne group if necessary.
  --     group:StartUncontrolled()
  --   end
  -- end
  --
  -- @function [parent=#WAREHOUSE] OnAfterSelfRequest
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Set#SET_GROUP groupset The set of (cargo) groups that was delivered to the warehouse itself.
  -- @param #WAREHOUSE.Pendingitem request Pending self request.


  --- Triggers the FSM event "Attacked" when a warehouse is under attack by an another coalition.
  -- @function [parent=#WAREHOUSE] Attacked
  -- @param #WAREHOUSE self
  -- @param DCS#coalition.side Coalition Coalition side which is attacking the warehouse, i.e. a number of @{DCS#coalition.side} enumerator.
  -- @param DCS#country.id Country Country ID, which is attacking the warehouse, i.e. a number @{DCS#country.id} enumerator.

  --- Triggers the FSM event "Attacked" with a delay when a warehouse is under attack by an another coalition.
  -- @function [parent=#WAREHOUSE] __Attacked
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition Coalition side which is attacking the warehouse, i.e. a number of @{DCS#coalition.side} enumerator.
  -- @param DCS#country.id Country Country ID, which is attacking the warehouse, i.e. a number @{DCS#country.id} enumerator.

  --- On after "Attacked" event user function. Called when a warehouse (zone) is under attack by an enemy.
  -- @function [parent=#WAREHOUSE] OnAfterAttacked
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param DCS#coalition.side Coalition Coalition side which is attacking the warehouse, i.e. a number of @{DCS#coalition.side} enumerator.
  -- @param DCS#country.id Country Country ID, which is attacking the warehouse, i.e. a number @{DCS#country.id} enumerator.


  --- Triggers the FSM event "Defeated" when an attack from an enemy was defeated.
  -- @function [parent=#WAREHOUSE] Defeated
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Defeated" with a delay when an attack from an enemy was defeated.
  -- @function [parent=#WAREHOUSE] __Defeated
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- On after "Defeated" event user function. Called when an enemy attack was defeated.
  -- @function [parent=#WAREHOUSE] OnAfterDefeate
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "ChangeCountry" so the warehouse is respawned with the new country.
  -- @function [parent=#WAREHOUSE] ChangeCountry
  -- @param #WAREHOUSE self
  -- @param DCS#country.id Country New country id of the warehouse.

  --- Triggers the FSM event "ChangeCountry" after a delay so the warehouse is respawned with the new country.
  -- @function [parent=#WAREHOUSE] __ChangeCountry
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param DCS#country.id Country Country id which has captured the warehouse.

  --- On after "ChangeCountry" event user function. Called when the warehouse has changed its country.
  -- @function [parent=#WAREHOUSE] OnAfterChangeCountry
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param DCS#country.id Country New country id of the warehouse, i.e. a number @{DCS#country.id} enumerator.


  --- Triggers the FSM event "Captured" when a warehouse has been captured by another coalition.
  -- @function [parent=#WAREHOUSE] Captured
  -- @param #WAREHOUSE self
  -- @param DCS#coalition.side Coalition Coalition side which captured the warehouse.
  -- @param DCS#country.id Country Country id which has captured the warehouse.

  --- Triggers the FSM event "Captured" with a delay when a warehouse has been captured by another coalition.
  -- @function [parent=#WAREHOUSE] __Captured
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition Coalition side which captured the warehouse.
  -- @param DCS#country.id Country Country id which has captured the warehouse.

  --- On after "Captured" event user function. Called when the warehouse has been captured by an enemy coalition.
  -- @function [parent=#WAREHOUSE] OnAfterCaptured
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param DCS#coalition.side Coalition Coalition side which captured the warehouse, i.e. a number of @{DCS#coalition.side} enumerator.
  -- @param DCS#country.id Country Country id which has captured the warehouse, i.e. a number @{DCS#country.id} enumerator.
  --

  --- Triggers the FSM event "AirbaseCaptured" when the airbase of the warehouse has been captured by another coalition.
  -- @function [parent=#WAREHOUSE] AirbaseCaptured
  -- @param #WAREHOUSE self
  -- @param DCS#coalition.side Coalition Coalition side which captured the airbase, i.e. a number of @{DCS#coalition.side} enumerator.

  --- Triggers the FSM event "AirbaseCaptured" with a delay when the airbase of the warehouse has been captured by another coalition.
  -- @function [parent=#WAREHOUSE] __AirbaseCaptured
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition Coalition side which captured the airbase, i.e. a number of @{DCS#coalition.side} enumerator.

  --- On after "AirbaseCaptured" even user function. Called when the airbase of the warehouse has been captured by another coalition.
  -- @function [parent=#WAREHOUSE] OnAfterAirbaseCaptured
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param DCS#coalition.side Coalition Coalition side which captured the airbase, i.e. a number of @{DCS#coalition.side} enumerator.


  --- Triggers the FSM event "AirbaseRecaptured" when the airbase of the warehouse has been re-captured from the other coalition.
  -- @param #WAREHOUSE self
  -- @function [parent=#WAREHOUSE] AirbaseRecaptured
  -- @param DCS#coalition.side Coalition Coalition which re-captured the airbase, i.e. the same as the current warehouse owner coalition.

  --- Triggers the FSM event "AirbaseRecaptured" with a delay when the airbase of the warehouse has been re-captured from the other coalition.
  -- @function [parent=#WAREHOUSE] __AirbaseRecaptured
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param DCS#coalition.side Coalition Coalition which re-captured the airbase, i.e. the same as the current warehouse owner coalition.

  --- On after "AirbaseRecaptured" event user function. Called when the airbase of the warehouse has been re-captured from the other coalition.
  -- @function [parent=#WAREHOUSE] OnAfterAirbaseRecaptured
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param DCS#coalition.side Coalition Coalition which re-captured the airbase, i.e. the same as the current warehouse owner coalition.


  --- Triggers the FSM event "AssetDead" when an asset group has died.
  -- @function [parent=#WAREHOUSE] AssetDead
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE.Assetitem asset The asset that is dead.
  -- @param #WAREHOUSE.Pendingitem request The request of the dead asset.

  --- Triggers the delayed FSM event "AssetDead" when an asset group has died.
  -- @function [parent=#WAREHOUSE] __AssetDead
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE.Assetitem asset The asset that is dead.
  -- @param #WAREHOUSE.Pendingitem request The request of the dead asset.

  --- On after "AssetDead" event user function. Called when an asset group died.
  -- @function [parent=#WAREHOUSE] OnAfterAssetDead
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #WAREHOUSE.Assetitem asset The asset that is dead.
  -- @param #WAREHOUSE.Pendingitem request The request of the dead asset.


  --- Triggers the FSM event "Destroyed" when the warehouse was destroyed. Services are stopped.
  -- @function [parent=#WAREHOUSE] Destroyed
  -- @param #WAREHOUSE self

  --- Triggers the FSM event "Destroyed" with a delay when the warehouse was destroyed. Services are stopped.
  -- @function [parent=#WAREHOUSE] __Destroyed
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.

  --- On after "Destroyed" event user function. Called when the warehouse was destroyed. Services are stopped.
  -- @function [parent=#WAREHOUSE] OnAfterDestroyed
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "AssetSpawned" when the warehouse has spawned an asset.
  -- @function [parent=#WAREHOUSE] AssetSpawned
  -- @param #WAREHOUSE self
  -- @param Wrapper.Group#GROUP group the group that was spawned.
  -- @param #WAREHOUSE.Assetitem asset The asset that was spawned.
  -- @param #WAREHOUSE.Pendingitem request The request of the spawned asset.

  --- Triggers the FSM event "AssetSpawned" with a delay when the warehouse has spawned an asset.
  -- @function [parent=#WAREHOUSE] __AssetSpawned
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Group#GROUP group the group that was spawned.
  -- @param #WAREHOUSE.Assetitem asset The asset that was spawned.
  -- @param #WAREHOUSE.Pendingitem request The request of the spawned asset.

  --- On after "AssetSpawned" event user function. Called when the warehouse has spawned an asset.
  -- @function [parent=#WAREHOUSE] OnAfterAssetSpawned
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP group the group that was spawned.
  -- @param #WAREHOUSE.Assetitem asset The asset that was spawned.
  -- @param #WAREHOUSE.Pendingitem request The request of the spawned asset.


  --- Triggers the FSM event "AssetLowFuel" when an asset runs low on fuel
  -- @function [parent=#WAREHOUSE] AssetLowFuel
  -- @param #WAREHOUSE self
  -- @param #WAREHOUSE.Assetitem asset The asset that is low on fuel.
  -- @param #WAREHOUSE.Pendingitem request The request of the asset that is low on fuel.

  --- Triggers the FSM event "AssetLowFuel" with a delay when an asset  runs low on fuel.
  -- @function [parent=#WAREHOUSE] __AssetLowFuel
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #WAREHOUSE.Assetitem asset The asset that is low on fuel.
  -- @param #WAREHOUSE.Pendingitem request The request of the asset that is low on fuel.

  --- On after "AssetLowFuel" event user function. Called when the an asset is low on fuel.
  -- @function [parent=#WAREHOUSE] OnAfterAssetLowFuel
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #WAREHOUSE.Assetitem asset The asset that is low on fuel.
  -- @param #WAREHOUSE.Pendingitem request The request of the asset that is low on fuel.


  --- Triggers the FSM event "Save" when the warehouse assets are saved to file on disk.
  -- @function [parent=#WAREHOUSE] Save
  -- @param #WAREHOUSE self
  -- @param #string path Path where the file is saved. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is WAREHOUSE-<UID>_<ALIAS>.txt.

  --- Triggers the FSM event "Save" with a delay when the warehouse assets are saved to a file.
  -- @function [parent=#WAREHOUSE] __Save
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #string path Path where the file is saved. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is WAREHOUSE-<UID>_<ALIAS>.txt.

  --- On after "Save" event user function. Called when the warehouse assets are saved to disk.
  -- @function [parent=#WAREHOUSE] OnAfterSave
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path Path where the file is saved. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is WAREHOUSE-<UID>_<ALIAS>.txt.


  --- Triggers the FSM event "Load" when the warehouse is loaded from a file on disk.
  -- @function [parent=#WAREHOUSE] Load
  -- @param #WAREHOUSE self
  -- @param #string path Path where the file is located. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is WAREHOUSE-<UID>_<ALIAS>.txt.

  --- Triggers the FSM event "Load" with a delay when the warehouse assets are loaded from disk.
  -- @function [parent=#WAREHOUSE] __Load
  -- @param #WAREHOUSE self
  -- @param #number delay Delay in seconds.
  -- @param #string path Path where the file is located. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is WAREHOUSE-<UID>_<ALIAS>.txt.

  --- On after "Load" event user function. Called when the warehouse assets are loaded from disk.
  -- @function [parent=#WAREHOUSE] OnAfterLoad
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path Path where the file is located. Default is the DCS installation root directory.
  -- @param #string filename (Optional) File name. Default is WAREHOUSE-<UID>_<ALIAS>.txt.


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set debug mode on. Error messages will be displayed on screen, units will be smoked at some events.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetDebugOn()
  self.Debug=true
  return self
end

--- Set debug mode off. This is the default
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetDebugOff()
  self.Debug=false
  return self
end

--- Set report on. Messages at events will be displayed on screen to the coalition owning the warehouse.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetReportOn()
  self.Report=true
  return self
end

--- Set report off. Warehouse does not report about its status and at certain events.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetReportOff()
  self.Report=false
  return self
end

--- Enable safe parking option, i.e. parking spots at an airbase will be considered as occupied when a client aircraft is parked there (even if the client slot is not taken by a player yet).
-- Note that also incoming aircraft can reserve/occupie parking spaces.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetSafeParkingOn()
  self.safeparking=true
  return self
end

--- Disable safe parking option. Note that is the default setting.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetSafeParkingOff()
  self.safeparking=false
  return self
end

--- Set wether client parking spots can be used for spawning.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetAllowSpawnOnClientParking()
  self.allowSpawnOnClientSpots=true
  return self
end

--- Set low fuel threshold. If one unit of an asset has less fuel than this number, the event AssetLowFuel will be fired.
-- @param #WAREHOUSE self
-- @param #number threshold Relative low fuel threshold, i.e. a number in [0,1]. Default 0.15 (15%).
-- @return #WAREHOUSE self
function WAREHOUSE:SetLowFuelThreshold(threshold)
  self.lowfuelthresh=threshold or 0.15
  return self
end

--- Set interval of status updates. Note that normally only one request can be processed per time interval.
-- @param #WAREHOUSE self
-- @param #number timeinterval Time interval in seconds.
-- @return #WAREHOUSE self
function WAREHOUSE:SetStatusUpdate(timeinterval)
  self.dTstatus=timeinterval
  return self
end

--- Set verbosity level.
-- @param #WAREHOUSE self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #WAREHOUSE self
function WAREHOUSE:SetVerbosityLevel(VerbosityLevel)
  self.verbosity=VerbosityLevel or 0
  return self
end

--- Set a zone where the (ground) assets of the warehouse are spawned once requested.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The spawn zone.
-- @param #number maxdist (Optional) Maximum distance in meters between spawn zone and warehouse. Units are not spawned if distance is larger. Default is 5000 m.
-- @return #WAREHOUSE self
function WAREHOUSE:SetSpawnZone(zone, maxdist)
  self.spawnzone=zone
  self.spawnzonemaxdist=maxdist or 5000
  return self
end

--- Get the spawn zone.
-- @param #WAREHOUSE self
-- @return Core.Zone#ZONE The spawn zone.
function WAREHOUSE:GetSpawnZone()
  return self.spawnzone
end

--- Set a warehouse zone. If this zone is captured, the warehouse and all its assets fall into the hands of the enemy.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The warehouse zone. Note that this **cannot** be a polygon zone!
-- @return #WAREHOUSE self
function WAREHOUSE:SetWarehouseZone(zone)
  self.zone=zone
  return self
end

--- Get the warehouse zone.
-- @param #WAREHOUSE self
-- @return Core.Zone#ZONE The warehouse zone.
function WAREHOUSE:GetWarehouseZone()
  return self.zone
end

--- Set auto defence on. When the warehouse is under attack, all ground assets are spawned automatically and will defend the warehouse zone.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetAutoDefenceOn()
  self.autodefence=true
  return self
end

--- Set auto defence off. This is the default.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetAutoDefenceOff()
  self.autodefence=false
  return self
end

--- Set valid parking spot IDs.
-- @param #WAREHOUSE self
-- @param #table ParkingIDs Table of numbers.
-- @return #WAREHOUSE self
function WAREHOUSE:SetParkingIDs(ParkingIDs)
  if type(ParkingIDs)~="table" then
    ParkingIDs={ParkingIDs}
  end
  self.parkingIDs=ParkingIDs
  return self
end

--- Check parking ID.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot Parking spot.
-- @return #boolean If true, parking is valid.
function WAREHOUSE:_CheckParkingValid(spot)

  if self.parkingIDs==nil then
    return true
  end

  for _,id in pairs(self.parkingIDs or {}) do
    if spot.TerminalID==id then
      return true
    end
  end

  return false
end

--- Check parking ID for an asset.
-- @param #WAREHOUSE self
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot spot Parking spot.
-- @return #boolean If true, parking is valid.
function WAREHOUSE:_CheckParkingAsset(spot, asset)

  if asset.parkingIDs==nil then
    return true
  end

  for _,id in pairs(asset.parkingIDs or {}) do
    if spot.TerminalID==id then
      return true
    end
  end

  return false
end


--- Enable auto save of warehouse assets at mission end event.
-- @param #WAREHOUSE self
-- @param #string path Path where to save the asset data file.
-- @param #string filename File name. Default is generated automatically from warehouse id.
-- @return #WAREHOUSE self
function WAREHOUSE:SetSaveOnMissionEnd(path, filename)
  self.autosave=true
  self.autosavepath=path
  self.autosavefile=filename
  return self
end

--- Show or don't show markers on the F10 map displaying the Warehouse stock and road/rail connections.
-- @param #WAREHOUSE self
-- @param #boolean switch If true (or nil), markers are on. If false, markers are not displayed.
-- @return #WAREHOUSE self
function WAREHOUSE:SetMarker(switch)
  if switch==false then
    self.markerOn=false
  else
    self.markerOn=true
  end
  return self
end

--- Set respawn after destroy.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE self
function WAREHOUSE:SetRespawnAfterDestroyed(delay)
  self.respawnafterdestroyed=true
  self.respawndelay=delay
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
  if airbase~=nil then
    self.airbasename=airbase:GetName()
  else
    self.airbasename=nil
  end
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

--- Set the port zone for this warehouse.
-- The port zone is the zone, where all naval assets of the warehouse are spawned.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The zone defining the naval port of the warehouse.
-- @return #WAREHOUSE self
function WAREHOUSE:SetPortZone(zone)
  self.portzone=zone
  return self
end

--- Add a Harbor Zone for this warehouse where naval cargo units will spawn and be received.
-- Both warehouses must have the harbor zone defined for units to properly spawn on both the 
-- sending and receiving side. The harbor zone should be within 3km of the port zone used for 
-- warehouse in order to facilitate the boarding process.
-- @param #WAREHOUSE self
-- @param Core.Zone#ZONE zone The zone defining the naval embarcation/debarcation point for cargo units
-- @return #WAREHOUSE self
function WAREHOUSE:SetHarborZone(zone)
  self.harborzone=zone
  return self
end

--- Add a shipping lane from this warehouse to another remote warehouse.
-- Note that both warehouses must have a port zone defined before a shipping lane can be added!
-- Shipping lane is taken from the waypoints of a (late activated) template group. So set up a group, e.g. a ship or a helicopter, and place its
-- waypoints along the shipping lane you want to add.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE remotewarehouse The remote warehouse to where the shipping lane is added
-- @param Wrapper.Group#GROUP group Waypoints of this group will define the shipping lane between to warehouses.
-- @param #boolean oneway (Optional) If true, the lane can only be used from this warehouse to the other but not other way around. Default false.
-- @return #WAREHOUSE self
function WAREHOUSE:AddShippingLane(remotewarehouse, group, oneway)

  -- Check that port zones are defined.
  if self.portzone==nil or remotewarehouse.portzone==nil then
    local text=string.format("ERROR: Sending or receiving warehouse does not have a port zone defined. Adding shipping lane not possible!")
    self:_ErrorMessage(text, 5)
    return self
  end

  -- Initial and final coordinates are random points within the port zones.
  local startcoord=self.portzone:GetRandomCoordinate()
  local finalcoord=remotewarehouse.portzone:GetRandomCoordinate()

  -- Create new lane from waypoints of the template group.
  local lane=self:_NewLane(group, startcoord, finalcoord)

  -- Debug info. Marks along shipping lane.
  if self.Debug then
    for i=1,#lane do
      local coord=lane[i] --Core.Point#COORDINATE
      local text=string.format("Shipping lane %s to %s. Point %d.", self.alias, remotewarehouse.alias, i)
      coord:MarkToCoalition(text, self:GetCoalition())
    end
  end

  -- Name of the remote warehouse.
  local remotename=remotewarehouse.warehouse:GetName()

  -- Create new table if no shipping lane exists yet.
  if self.shippinglanes[remotename]==nil then
    self.shippinglanes[remotename]={}
  end

  -- Add shipping lane.
  table.insert(self.shippinglanes[remotename], lane)

  -- Add shipping lane in the opposite direction.
  if not oneway then
    remotewarehouse:AddShippingLane(self, group, true)
  end

  return self
end


--- Add an off-road path from this warehouse to another and back.
-- The start and end points are automatically set to one random point in the respective spawn zones of the two warehouses.
-- By default, the reverse path is also added as path from the remote warehouse to this warehouse.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE remotewarehouse The remote warehouse to which the path leads.
-- @param Wrapper.Group#GROUP group Waypoints of this group will define the path between to warehouses.
-- @param #boolean oneway (Optional) If true, the path can only be used from this warehouse to the other but not other way around. Default false.
-- @return #WAREHOUSE self
function WAREHOUSE:AddOffRoadPath(remotewarehouse, group, oneway)

  -- Initial and final points are random points within the spawn zone.
  local startcoord=self.spawnzone:GetRandomCoordinate()
  local finalcoord=remotewarehouse.spawnzone:GetRandomCoordinate()

  -- Create new path from template group waypoints.
  local path=self:_NewLane(group, startcoord, finalcoord)

  if path==nil then
    self:E(self.lid.."ERROR: Offroad path could not be added. Group present in ME?")
    return
  end

  -- Debug info. Marks along path.
  if path and self.Debug then
    for i=1,#path do
      local coord=path[i] --Core.Point#COORDINATE
      local text=string.format("Off road path from %s to %s. Point %d.", self.alias, remotewarehouse.alias, i)
      coord:MarkToCoalition(text, self:GetCoalition())
    end
  end

  -- Name of the remote warehouse.
  local remotename=remotewarehouse.warehouse:GetName()

  -- Create new table if no shipping lane exists yet.
  if self.offroadpaths[remotename]==nil then
    self.offroadpaths[remotename]={}
  end

  -- Add off road path.
  table.insert(self.offroadpaths[remotename], path)

  -- Add off road path in the opposite direction (if not forbidden).
  if not oneway then
    remotewarehouse:AddOffRoadPath(self, group, true)
  end

  return self
end

--- Create a new path from a template group.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group Group used for extracting the waypoints.
-- @param Core.Point#COORDINATE startcoord First coordinate.
-- @param Core.Point#COORDINATE finalcoord Final coordinate.
-- @return #table Table with route points.
function WAREHOUSE:_NewLane(group, startcoord, finalcoord)

  local lane=nil

  if group then

    -- Get route from template.
    local lanepoints=group:GetTemplateRoutePoints()

    -- First and last waypoints
    local laneF=lanepoints[1]
    local laneL=lanepoints[#lanepoints]

    -- Get corresponding coordinates.
    local coordF=COORDINATE:New(laneF.x, 0, laneF.y)
    local coordL=COORDINATE:New(laneL.x, 0, laneL.y)

    -- Figure out which point is closer to the port of this warehouse.
    local distF=startcoord:Get2DDistance(coordF)
    local distL=startcoord:Get2DDistance(coordL)

    -- Add the lane. Need to take care of the wrong "direction".
    lane={}
    if distF<distL then
      for i=1,#lanepoints do
        local point=lanepoints[i]
        local coord=COORDINATE:New(point.x,0, point.y)
        table.insert(lane, coord)
      end
    else
      for i=#lanepoints,1,-1 do
        local point=lanepoints[i]
        local coord=COORDINATE:New(point.x,0, point.y)
        table.insert(lane, coord)
      end
    end

    -- Automatically add end point which is a random point inside the final port zone.
    table.insert(lane, #lane, finalcoord)

  end

  return lane
end


--- Check if the warehouse has not been started yet, i.e. is in the state "NotReadyYet".
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse object has been created but the warehouse has not been started yet.
function WAREHOUSE:IsNotReadyYet()
  return self:is("NotReadyYet")
end

--- Check if the warehouse has been loaded from disk via the "Load" event.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse was loaded from disk.
function WAREHOUSE:IsLoaded()
  return self:is("Loaded")
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

--- Check if the warehouse has been destroyed.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse had been destroyed.
function WAREHOUSE:IsDestroyed()
  return self:is("Destroyed")
end

--- Check if the warehouse is stopped.
-- @param #WAREHOUSE self
-- @return #boolean If true, the warehouse is stopped.
function WAREHOUSE:IsStopped()
  return self:is("Stopped")
end

--- Check if the warehouse has a road connection to another warehouse. Both warehouses need to be started!
-- @param #WAREHOUSE self
-- @param #WAREHOUSE warehouse The remote warehouse to where the connection is checked.
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
-- @param #WAREHOUSE warehouse The remote warehouse to where the connection is checked.
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

--- Check if the warehouse has a shipping lane defined to another warehouse.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE warehouse The remote warehouse to where the connection is checked.
-- @param #boolean markpath If true, place markers of path segments on the F10 map.
-- @param #boolean smokepath If true, put green smoke on path segments.
-- @return #boolean If true, the two warehouses are connected by road.
-- @return #number Path length in meters. Negative distance -1 meter indicates no connection.
function WAREHOUSE:HasConnectionNaval(warehouse, markpath, smokepath)

  if warehouse then

    -- Self request
    if warehouse.warehouse:GetName()==self.warehouse:GetName() then
      return true,1
    end

    -- Get shipping lane.
    local shippinglane=self.shippinglanes[warehouse.warehouse:GetName()]

    if shippinglane then
      return true,1
    else
      self:T2(string.format("No shipping lane defined between warehouse %s and %s!", self.alias, warehouse.alias))
    end

  end

  return nil, -1
end

--- Check if the warehouse has an off road path defined to another warehouse.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE warehouse The remote warehouse to where the connection is checked.
-- @param #boolean markpath If true, place markers of path segments on the F10 map.
-- @param #boolean smokepath If true, put green smoke on path segments.
-- @return #boolean If true, the two warehouses are connected by road.
-- @return #number Path length in meters. Negative distance -1 meter indicates no connection.
function WAREHOUSE:HasConnectionOffRoad(warehouse, markpath, smokepath)

  if warehouse then

    -- Self request
    if warehouse.warehouse:GetName()==self.warehouse:GetName() then
      return true,1
    end

    -- Get shipping lane.
    local offroadpath=self.offroadpaths[warehouse.warehouse:GetName()]

    if offroadpath~=nil then
      return true,1
    else
      self:T2(string.format("No off-road path defined between warehouse %s and %s!", self.alias, warehouse.alias))
    end

  end

  return nil, -1
end


--- Get number of assets in warehouse stock. Optionally, only specific assets can be counted.
-- @param #WAREHOUSE self
-- @param #string Descriptor (Optional) Descriptor return the number of a specifc asset type. See @{#WAREHOUSE.Descriptor} for possible values.
-- @param DescriptorValue (Optional) Descriptor value selecting the type of assets.
-- @param #boolean OnlyMobile (Optional) If true only mobile units are considered.
-- @return #number Number of assets in stock.
function WAREHOUSE:GetNumberOfAssets(Descriptor, DescriptorValue, OnlyMobile)

  if Descriptor==nil or DescriptorValue==nil then
    -- All assets.
    return #self.stock
  else
    -- Selected assets.
    local _stock,_nstock=self:_FilterStock(self.stock, Descriptor, DescriptorValue, nil, OnlyMobile)
    return _nstock
  end

end

--- Get coordinate of warehouse static.
-- @param #WAREHOUSE self
-- @return Core.Point#COORDINATE The coordinate of the warehouse.
function WAREHOUSE:GetCoordinate()
  return self.warehouse:GetCoordinate()
end

--- Get 3D vector of warehouse static.
-- @param #WAREHOUSE self
-- @return DCS#Vec3 The 3D vector of the warehouse.
function WAREHOUSE:GetVec3()
  local vec3=self.warehouse:GetVec3()
  return vec3
end

--- Get 2D vector of warehouse static.
-- @param #WAREHOUSE self
-- @return DCS#Vec2 The 2D vector of the warehouse.
function WAREHOUSE:GetVec2()
  local vec2=self.warehouse:GetVec2()
  return vec2
end


--- Get coalition side of warehouse static.
-- @param #WAREHOUSE self
-- @return #number Coalition side, i.e. number of @{DCS#coalition.side}.
function WAREHOUSE:GetCoalition()
  return self.warehouse:GetCoalition()
end

--- Get coalition name of warehouse static.
-- @param #WAREHOUSE self
-- @return #number Coalition side, i.e. number of @{DCS#coalition.side}.
function WAREHOUSE:GetCoalitionName()
  return self.warehouse:GetCoalitionName()
end

--- Get country id of warehouse static.
-- @param #WAREHOUSE self
-- @return #number Country id, i.e. number of @{DCS#country.id}.
function WAREHOUSE:GetCountry()
  return self.warehouse:GetCountry()
end

--- Get country name of warehouse static.
-- @param #WAREHOUSE self
-- @return #number Country id, i.e. number of @{DCS#coalition.side}.
function WAREHOUSE:GetCountryName()
  return self.warehouse:GetCountryName()
end

--- Get airbase associated to the warehouse.
-- @param #WAREHOUSE self
-- @return Wrapper.Airbase#AIRBASE Airbase object or nil if warehouse has no airbase connection.
function WAREHOUSE:GetAirbase()
  return self.airbase
end

--- Get name airbase associated to the warehouse.
-- @param #WAREHOUSE self
-- @return #string name of the airbase assosicated to the warehouse or "none" if the airbase has not airbase connection currently.
function WAREHOUSE:GetAirbaseName()
  local name="none"
  if self.airbase then
    name=self.airbase:GetName()
  end
  return name
end

--- Get category of airbase associated to the warehouse.
-- @param #WAREHOUSE self
-- @return #number Category of airbase or -1 if warehouse has (currently) no airbase.
function WAREHOUSE:GetAirbaseCategory()
  local category=-1
  if self.airbase then
    category=self.airbase:GetAirbaseCategory()
  end
  return category
end

--- Get assignment of a request.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Pendingitem request The request from which the assignment is extracted.
-- @return #string The assignment text.
function WAREHOUSE:GetAssignment(request)
  return tostring(request.assignment)
end

--- Find a warehouse in the global warehouse data base.
-- @param #WAREHOUSE self
-- @param #number uid The unique ID of the warehouse.
-- @return #WAREHOUSE The warehouse object or nil if no warehouse exists.
function WAREHOUSE:FindWarehouseInDB(uid)
  return _WAREHOUSEDB.Warehouses[uid]
end

--- Find nearest warehouse in service, i.e. warehouses which are not started, stopped or destroyed are not considered.
-- Optionally, only warehouses with (specific) assets can be included in the search or warehouses of a certain coalition.
-- @param #WAREHOUSE self
-- @param MinAssets (Optional) Minimum number of assets the warehouse should have. Default 0.
-- @param #string Descriptor (Optional) Descriptor describing the selected assets which should be in stock. See @{#WAREHOUSE.Descriptor} for possible values.
-- @param DescriptorValue (Optional) Descriptor value selecting the type of assets which should be in stock.
-- @param DCS#Coalition.side Coalition (Optional) Coalition side of the warehouse. Default is the same coalition as the present warehouse. Set to false for any coalition.
-- @param Core.Point#COORDINATE RefCoordinate (Optional) Coordinate to which the closest warehouse is searched. Default is the warehouse calling this function.
-- @return #WAREHOUSE The the nearest warehouse object. Or nil if no warehouse is found.
-- @return #number The distance to the nearest warehouse in meters. Or nil if no warehouse is found.
function WAREHOUSE:FindNearestWarehouse(MinAssets, Descriptor, DescriptorValue, Coalition, RefCoordinate)

  -- Defaults
  if Descriptor~=nil and DescriptorValue~=nil then
    MinAssets=MinAssets or 1
  else
    MinAssets=MinAssets or 0
  end

  -- Coalition - default only the same as this warehouse.
  local anycoalition=nil
  if Coalition~=nil then
    if Coalition==false then
      anycoalition=true
    else
      -- Nothing to do
    end
  else
    if self~=nil then
      Coalition=self:GetCoalition()
    else
      anycoalition=true
    end
  end

  -- Coordinate of this warehouse or user specified reference.
  local coord=RefCoordinate or self:GetCoordinate()

  -- Loop over all warehouses.
  local nearest=nil
  local distmin=nil
  for wid,warehouse in pairs(_WAREHOUSEDB.Warehouses) do
    local warehouse=warehouse --#WAREHOUSE

    -- Distance from this warehouse to the other warehouse.
    local dist=coord:Get2DDistance(warehouse:GetCoordinate())

    if dist>0 then

      -- Check if coalition is right.
      local samecoalition=anycoalition or Coalition==warehouse:GetCoalition()

      -- Check that warehouse is in service.
      if samecoalition and not (warehouse:IsNotReadyYet() or warehouse:IsStopped() or warehouse:IsDestroyed()) then

        -- Get number of assets. Whole stock is returned if no descriptor/value is given.
        local nassets=warehouse:GetNumberOfAssets(Descriptor, DescriptorValue)

        --env.info(string.format("FF warehouse %s nassets = %d  for %s=%s", warehouse.alias, nassets, tostring(Descriptor), tostring(DescriptorValue)))

        -- Assume we have enough.
        local enough=true
        -- If specifc assets need to be present...
        if Descriptor and DescriptorValue then
          -- Check that enough assets (default 1) are available.
          enough = nassets>=MinAssets
        end

        -- Check distance.
        if enough and (distmin==nil or dist<distmin) then
          distmin=dist
          nearest=warehouse
        end
      end
    end
  end

  return nearest, distmin
end


--- Find an asset in the the global warehouse data base. Parameter is the MOOSE group object.
-- Note that the group name must contain they "AID" keyword.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which it is assumed that it has a registered asset.
-- @return #WAREHOUSE.Assetitem The asset from the data base or nil if it could not be found.
function WAREHOUSE:FindAssetInDB(group)

  -- Get unique ids from group name.
  local wid,aid,rid=self:_GetIDsFromGroup(group)

  if aid~=nil then

    local asset=_WAREHOUSEDB.Assets[aid]
    self:T2({asset=asset})
    if asset==nil then
      self:_ErrorMessage(string.format("ERROR: Asset for group %s not found in the data base!", group:GetName()), 0)
    end
    return asset
  end

  self:_ErrorMessage(string.format("ERROR: Group %s does not contain an asset ID in its name!", group:GetName()), 0)
  return nil
end

--- Check if runway is operational.
-- @param #WAREHOUSE self
-- @return #boolean If `true`, runway is operational.
function WAREHOUSE:IsRunwayOperational()
  if self.airbase then
    if self.runwaydestroyed then
      return false
    else
      return true
    end
  end
  return nil
end

--- Set the time until the runway(s) of an airdrome are repaired after it has been destroyed.
-- Note that this is the time, the DCS engine uses not something we can control on a user level or we could get via scripting.
-- You need to input the value. On the DCS forum it was stated that this is currently one hour. Hence this is the default value.
-- @param #WAREHOUSE self
-- @param #number RepairTime Time in seconds until the runway is repaired. Default 3600 sec (one hour).
-- @return #WAREHOUSE self
function WAREHOUSE:SetRunwayRepairtime(RepairTime)
  self.runwayrepairtime=RepairTime or 3600
  return self
end

--- Check if runway is operational.
-- @param #WAREHOUSE self
-- @return #number Time in seconds until the runway is repaired. Will return 0 if runway is repaired.
function WAREHOUSE:GetRunwayRepairtime()
  if self.runwaydestroyed then
    local Tnow=timer.getAbsTime()
    local Tsince=Tnow-self.runwaydestroyed
    local Trepair=math.max(self.runwayrepairtime-Tsince, 0)
    return Trepair
  end
  return 0
end

--- Check if warehouse physical representation is a unit (not a static) object.
-- @param #WAREHOUSE self
-- @return #boolean If `true`, warehouse object is a unit.
function WAREHOUSE:IsUnit()
  return self.isUnit
end

--- Check if warehouse physical representation is a static (not a unit) object.
-- @param #WAREHOUSE self
-- @return #boolean If `true`, warehouse object is a static.
function WAREHOUSE:IsStatic()
  return not self.isUnit
end

--- Check if warehouse physical representation is a ship.
-- @param #WAREHOUSE self
-- @return #boolean If `true`, warehouse object is a ship.
function WAREHOUSE:IsShip()
  return self.isShip
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the warehouse. Adds event handlers and schedules status updates of reqests and queue.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting warehouse %s alias %s:\n",self.warehouse:GetName(), self.alias)
  text=text..string.format("Coalition = %s\n", self:GetCoalitionName())
  text=text..string.format("Country  = %s\n", self:GetCountryName())
  text=text..string.format("Airbase  = %s (category=%d)\n", self:GetAirbaseName(), self:GetAirbaseCategory())
  env.info(text)

  -- Save self in static object. Easier to retrieve later.
  self.warehouse:SetState(self.warehouse, "WAREHOUSE", self)

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
  if self.road and self.markerOn then
    self.markroad=self.road:MarkToCoalition(string.format("%s road connection.",self.alias), self:GetCoalition(), true)
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
  if self.rail and self.markerOn then
    self.markrail=self.rail:MarkToCoalition(string.format("%s rail connection.", self.alias), self:GetCoalition(), true)
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
  self:HandleEvent(EVENTS.MissionEnd,     self._OnEventMissionEnd)

  -- This event triggers the arrived event for air assets.
  -- TODO Might need to make this landing or optional!
  -- In fact, it would be better if the type could be defined for only for the warehouse which receives stuff,
  -- since there will be warehouses with small airbases and little space or other problems!
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEventArrived)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "Restart" event. Restarts the warehouse when it was in stopped state by reactivating the event handlers *only*.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterRestart(From, Event, To)

  self:I(self.lid..string.format("Restarting Warehouse %s.", self.alias))

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
  self:__Status(-1)

end

--- On after "Stop" event. Stops the warehouse, unhandles all events.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStop(From, Event, To)
  self:_InfoMessage(string.format("Warehouse %s stopped!", self.alias))

  -- Unhandle event.
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.EngineStartup)
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.BaseCaptured)

  self.pending=nil
  self.pending={}

  self.queue=nil
  self.queue={}

  self.stock=nil
  self.stock={}

  self:_UpdateWarehouseMarkText()

  -- Clear all pending schedules.
  self.CallScheduler:Clear()
end

--- On after "Pause" event. Pauses the warehouse, i.e. no requests are processed. However, new requests and new assets can be added in this state.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterPause(From, Event, To)
  self:I(self.lid..string.format("Warehouse %s paused! Queued requests are not processed in this state.", self.alias))
end

--- On after "Unpause" event. Unpauses the warehouse, i.e. requests in queue are processed again.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterUnpause(From, Event, To)
  self:I(self.lid..string.format("Warehouse %s unpaused! Processing of requests is resumed.", self.alias))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Status event. Checks the queue and handles requests.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterStatus(From, Event, To)

  -- General info.
  if self.verbosity>=1 then
  
    local FSMstate=self:GetState()
  
    local coalition=self:GetCoalitionName()
    local country=self:GetCountryName()
  
    -- Info.
    self:I(self.lid..string.format("State=%s %s [%s]: Assets=%d,  Requests: waiting=%d, pending=%d", FSMstate, country, coalition, #self.stock, #self.queue, #self.pending))
  end

  -- Check if any pending jobs are done and can be deleted from the queue.
  self:_JobDone()

  -- Print status.
  self:_DisplayStatus()

  -- Check if warehouse is being attacked or has even been captured.
  self:_CheckConquered()
  
  if self:IsRunwayOperational()==false then
    local Trepair=self:GetRunwayRepairtime()
    self:I(self.lid..string.format("Runway destroyed! Will be repaired in %d sec", Trepair))
    if Trepair==0 then
      self.runwaydestroyed = nil
      self:RunwayRepaired()
    end
  end

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

  end

  -- Print queue after processing requests.
  if self.verbosity > 2 then
    self:_PrintQueue(self.queue, "Queue waiting")
    self:_PrintQueue(self.pending, "Queue pending")
  end
  -- Check fuel for all assets.
  --self:_CheckFuel()

  -- Update warhouse marker on F10 map.
  self:_UpdateWarehouseMarkText()

  -- Display complete list of stock itmes.
  if self.Debug then
    self:_DisplayStockItems(self.stock)
  end

  -- Call status again in ~30 sec (user choice).
  self:__Status(-self.dTstatus)
end


--- Function that checks if a pending job is done and can be removed from queue.
-- @param #WAREHOUSE self
function WAREHOUSE:_JobDone()

  -- For jobs that are done, i.e. all cargo and transport assets are delivered, home or dead!
  local done={}

  -- Loop over all pending requests of this warehouse.
  for _,request in pairs(self.pending) do
    local request=request --#WAREHOUSE.Pendingitem
    
    if request.born then

      -- Count number of cargo groups.
      local ncargo=0
      if request.cargogroupset then
        ncargo=request.cargogroupset:Count()
      end
  
      -- Count number of transport groups (if any).
      local ntransport=0
      if request.transportgroupset then
        ntransport=request.transportgroupset:Count()
      end
  
      local ncargotot=request.nasset
      local ncargodelivered=request.ndelivered
  
      -- Dead cargo: Ndead=Ntot-Ndeliverd-Nalive,
      local ncargodead=ncargotot-ncargodelivered-ncargo
  
  
      local ntransporttot=request.ntransport
      local ntransporthome=request.ntransporthome
  
      -- Dead transport: Ndead=Ntot-Nhome-Nalive.
      local ntransportdead=ntransporttot-ntransporthome-ntransport
  
      local text=string.format("Request id=%d: Cargo: Ntot=%d, Nalive=%d, Ndelivered=%d, Ndead=%d  |  Transport: Ntot=%d, Nalive=%d, Nhome=%d, Ndead=%d",
      request.uid, ncargotot, ncargo, ncargodelivered, ncargodead, ntransporttot, ntransport, ntransporthome, ntransportdead)
      self:T(self.lid..text)
  
  
      -- Handle different cases depending on what asset are still around.
      if ncargo==0 then
        ---------------------
        -- Cargo delivered --
        ---------------------
  
        -- Trigger delivered event.
        if not self.delivered[request.uid] then
          self:Delivered(request)
        end
  
        -- Check if transports are back home?
        if ntransport==0 then
          ---------------
          -- Job done! --
          ---------------
  
          -- Info on job.
          if self.verbosity>=1 then
            local text=string.format("Warehouse %s: Job on request id=%d for warehouse %s done!\n", self.alias, request.uid, request.warehouse.alias)
            text=text..string.format("- %d of %d assets delivered. Casualties %d.", ncargodelivered, ncargotot, ncargodead)
            if request.ntransport>0 then
              text=text..string.format("\n- %d of %d transports returned home. Casualties %d.", ntransporthome, ntransporttot, ntransportdead)
            end
            self:_InfoMessage(text, 20)
          end
  
          -- Mark request for deletion.
          table.insert(done, request)
  
        else
          -----------------------------------
          -- No cargo but still transports --
          -----------------------------------
  
          -- This is difficult! How do I know if transports were unused? They could also be just on their way back home.
          -- ==> Need to do a lot of checks.
  
          -- All transports are dead but there is still cargo left ==> Put cargo back into stock.
          for _,_group in pairs(request.transportgroupset:GetSetObjects()) do
            local group=_group --Wrapper.Group#GROUP
  
            -- Check if group is alive.
            if group and group:IsAlive() then
  
              -- Check if group is in the spawn zone?
              local category=group:GetCategory()
  
              -- Get current speed.
              local speed=group:GetVelocityKMH()
              local notmoving=speed<1
  
              -- Closest airbase.
              local airbase=group:GetCoordinate():GetClosestAirbase():GetName()
              local athomebase=self.airbase and self.airbase:GetName()==airbase
  
              -- On ground
              local onground=not group:InAir()
  
              -- In spawn zone.
              local inspawnzone=group:IsPartlyOrCompletelyInZone(self.spawnzone)
  
              -- Check conditions for being back home.
              local ishome=false
              if category==Group.Category.GROUND or category==Group.Category.HELICOPTER then
                -- Units go back to the spawn zone, helicopters land and they should not move any more.
                ishome=inspawnzone and onground and notmoving
              elseif category==Group.Category.AIRPLANE then
                -- Planes need to be on ground at their home airbase and should not move any more.
                ishome=athomebase and onground and notmoving
              end
  
              -- Debug text.
              local text=string.format("Group %s: speed=%d km/h, onground=%s , airbase=%s, spawnzone=%s ==> ishome=%s", group:GetName(), speed, tostring(onground), airbase, tostring(inspawnzone), tostring(ishome))
              self:T(self.lid..text)
  
              if ishome then
  
                -- Info message.
                local text=string.format("Warehouse %s: Transport group arrived back home and no cargo left for request id=%d.\nSending transport group %s back to stock.", self.alias, request.uid, group:GetName())
                self:T(self.lid..text)
  
                -- Debug smoke.
                if self.Debug then
                  group:SmokeRed()
                end
  
                -- Group arrived.
                self:Arrived(group)
              end
            end
          end
  
        end
  
      else
  
        if ntransport==0 and request.ntransport>0 then
          -----------------------------------
          -- Still cargo but no transports --
          -----------------------------------
  
          local ncargoalive=0
  
          -- All transports are dead but there is still cargo left ==> Put cargo back into stock.
          for _,_group in pairs(request.cargogroupset:GetSetObjects()) do
            --local group=group --Wrapper.Group#GROUP
  
            -- These groups have been respawned as cargo, i.e. their name changed!
            local groupname=_group:GetName()
            local group=GROUP:FindByName(groupname.."#CARGO")
  
            -- Check if group is alive.
            if group and group:IsAlive() then
  
              -- Check if group is in spawn zone?
              if group:IsPartlyOrCompletelyInZone(self.spawnzone) then
                -- Debug smoke.
                if self.Debug then
                  group:SmokeBlue()
                end
                -- Add asset group back to stock.
                self:AddAsset(group)
                ncargoalive=ncargoalive+1
              end
            end
  
          end
  
          -- Info message.
          self:_InfoMessage(string.format("Warehouse %s: All transports of request id=%s dead! Putting remaining %s cargo assets back into warehouse!", self.alias, request.uid, ncargoalive))
        end
  
      end
    end -- born check
  end -- loop over requests

  -- Remove pending requests if done.
  for _,request in pairs(done) do
    self:_DeleteQueueItem(request, self.pending)
  end
end

--- Function that checks if an asset group is still okay.
-- @param #WAREHOUSE self
function WAREHOUSE:_CheckAssetStatus()

  -- Check if a unit of the group has problems.
  local function _CheckGroup(_request, _group)
    local request=_request --#WAREHOUSE.Pendingitem
    local group=_group     --Wrapper.Group#GROUP

    if group and group:IsAlive() then

      -- Category of group.
      local category=group:GetCategory()

      for _,_unit in pairs(group:GetUnits()) do
        local unit=_unit --Wrapper.Unit#UNIT

        if unit and unit:IsAlive() then
          local unitid=unit:GetID()
          local life9=unit:GetLife()
          local life0=unit:GetLife0()
          local life=life9/life0*100
          local speed=unit:GetVelocityMPS()
          local onground=unit:InAir()

          local problem=false
          if life<10 then
            self:T(string.format("Unit %s is heavily damaged!", unit:GetName()))
          end
          if speed<1 and unit:GetSpeedMax()>1 and onground then
            self:T(string.format("Unit %s is not moving!", unit:GetName()))
            problem=true
          end

          if problem then
            if request.assetproblem[unitid] then
              local deltaT=timer.getAbsTime()-request.assetproblem[unitid]
              if deltaT>300 then
                --Todo: which event to generate? Removeunit or Dead/Creash or both?
                unit:Destroy()
              end
            else
              request.assetproblem[unitid]=timer.getAbsTime()
            end
          end
        end

      end
    end
  end


  for _,request in pairs(self.pending) do
    local request=request --#WAREHOUSE.Pendingitem

    -- Cargo groups.
    if request.cargogroupset then
      for _,_group in pairs(request.cargogroupset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP

        _CheckGroup(request, group)

      end
    end

    -- Transport groups.
    if request.transportgroupset then
      for _,group in pairs(request.transportgroupset:GetSet()) do

        _CheckGroup(request, group)
      end
    end

  end

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
-- @param #number forcecargobay (Optional) Explicitly force cargobay weight limit in kg for cargo carriers. This is for each *unit* of the group.
-- @param #number forceweight (Optional) Explicitly force weight in kg of each unit in the group.
-- @param #number loadradius (Optional) Radius in meters when the cargo is loaded into the carrier.
-- @param DCS#AI.Skill skill Skill of the asset.
-- @param #table liveries Table of livery names. When the asset is spawned one livery is chosen randomly.
-- @param #string assignment A free to choose string specifying an assignment for the asset. This can be used with the @{#WAREHOUSE.OnAfterNewAsset} function.
-- @param #table other (Optional) Table of other useful data. Can be collected via WAREHOUSE.OnAfterNewAsset() function for example
function WAREHOUSE:onafterAddAsset(From, Event, To, group, ngroups, forceattribute, forcecargobay, forceweight, loadradius, skill, liveries, assignment, other)
  self:T({group=group, ngroups=ngroups, forceattribute=forceattribute, forcecargobay=forcecargobay, forceweight=forceweight})

  -- Set default.
  local n=ngroups or 1

  -- Handle case where just a string is passed.
  if type(group)=="string" then
    group=GROUP:FindByName(group)
  end

  if liveries and type(liveries)=="string" then
    liveries={liveries}
  end

  if group then

    -- Try to get UIDs from group name. Is this group a known or a new asset?
    local wid,aid,rid=self:_GetIDsFromGroup(group)

    if wid and aid and rid then

      ---------------------------
      -- This is a KNOWN asset --
      ---------------------------

      -- Get the original warehouse this group belonged to.
      local warehouse=self:FindWarehouseInDB(wid)

      if warehouse then

        local request=warehouse:_GetRequestOfGroup(group, warehouse.pending)

        if request then

          -- Increase number of cargo delivered and transports home.
          local istransport=warehouse:_GroupIsTransport(group,request)

          if istransport==true then
            request.ntransporthome=request.ntransporthome+1
            request.transportgroupset:Remove(group:GetName(), true)
            local ntrans=request.transportgroupset:Count()
            self:T2(warehouse.lid..string.format("Transport %d of %s returned home. TransportSet=%d", request.ntransporthome, tostring(request.ntransport), ntrans))
          elseif istransport==false then
            request.ndelivered=request.ndelivered+1
            local namewo=self:_GetNameWithOut(group)
            request.cargogroupset:Remove(namewo, true)
            local ncargo=request.cargogroupset:Count()
            self:T2(warehouse.lid..string.format("Cargo %s: %d of %s delivered. CargoSet=%d", namewo, request.ndelivered, tostring(request.nasset), ncargo))
          else
            self:E(warehouse.lid..string.format("WARNING: Group %s is neither cargo nor transport! Need to investigate...", group:GetName()))
          end

          -- If no assignment was given we take the assignment of the request if there is any.
          if assignment==nil and request.assignment~=nil then
            assignment=request.assignment
          end

        end
      end

      -- Get the asset from the global DB.
      local asset=self:FindAssetInDB(group)

      -- Note the group is only added once, i.e. the ngroups parameter is ignored here.
      -- This is because usually these request comes from an asset that has been transfered from another warehouse and hence should only be added once.
      if asset~=nil then
        self:_DebugMessage(string.format("Warehouse %s: Adding KNOWN asset uid=%d with attribute=%s to stock.", self.alias, asset.uid, asset.attribute), 5)

        -- Set livery.
        if liveries then
          if type(liveries)=="table" then
            asset.livery=liveries[math.random(#liveries)]
          else
            asset.livery=liveries
          end
        end

        -- Set skill.
        asset.skill=skill or asset.skill

        -- Asset now belongs to this warehouse. Set warehouse ID.
        asset.wid=self.uid

        -- No request associated with this asset.
        asset.rid=nil

        -- Asset is not spawned.
        asset.spawned=false
        asset.requested=false
        asset.isReserved=false
        asset.iscargo=nil
        asset.arrived=nil
        
        -- Destroy group if it is alive.
        if group:IsAlive()==true then
          asset.damage=asset.life0-group:GetLife()
        end

        -- Add asset to stock.
        table.insert(self.stock, asset)

        -- Trigger New asset event.
        self:__NewAsset(0.1, asset, assignment or "")
      else
        self:_ErrorMessage(string.format("ERROR: Known asset could not be found in global warehouse db!"), 0)
      end

    else

      -------------------------
      -- This is a NEW asset --
      -------------------------

      -- Debug info.
      self:_DebugMessage(string.format("Warehouse %s: Adding %d NEW assets of group %s to stock", self.alias, n, tostring(group:GetName())), 5)

      -- This is a group that is not in the db yet. Add it n times.
      local assets=self:_RegisterAsset(group, n, forceattribute, forcecargobay, forceweight, loadradius, liveries, skill, assignment)

      -- Add created assets to stock of this warehouse.
      for _,asset in pairs(assets) do

        -- Asset belongs to this warehouse. Set warehouse ID.
        asset.wid=self.uid

        -- No request associated with this asset.
        asset.rid=nil

        -- Add asset to stock.
        table.insert(self.stock, asset)

        -- Trigger NewAsset event. Delay a bit for OnAfterNewAsset functions to work properly.
        self:__NewAsset(0.1, asset, assignment or "")
      end

    end

    -- Destroy group if it is alive.
    if group:IsAlive()==true then
      self:_DebugMessage(string.format("Removing group %s", group:GetName()), 5)

      local opsgroup=_DATABASE:GetOpsGroup(group:GetName())
      if opsgroup then      
        opsgroup:Despawn(0, true)
        opsgroup:__Stop(-0.01)
      else
        -- Setting parameter to false, i.e. creating NO dead or remove unit event, seems to not confuse the dispatcher logic.
        -- TODO: It would be nice, however, to have the remove event.      
        group:Destroy() --(false)
      end
    else
      local opsgroup=_DATABASE:GetOpsGroup(group:GetName())
      if opsgroup then
        opsgroup:Stop()
      end
    end

  else
    self:E(self.lid.."ERROR: Unknown group added as asset!")
    self:E({unknowngroup=group})
  end

end

--- Register new asset in globase warehouse data base.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that will be added to the warehouse stock.
-- @param #number ngroups Number of groups to be added.
-- @param #string forceattribute Forced generalized attribute.
-- @param #number forcecargobay Cargo bay weight limit in kg.
-- @param #number forceweight Weight of units in kg.
-- @param #number loadradius Radius in meters when cargo is loaded into the carrier.
-- @param #table liveries Table of liveries.
-- @param DCS#AI.Skill skill Skill of AI.
-- @param #string assignment Assignment attached to the asset item.
-- @return #table A table containing all registered assets.
function WAREHOUSE:_RegisterAsset(group, ngroups, forceattribute, forcecargobay, forceweight, loadradius, liveries, skill, assignment)
  self:F({groupname=group:GetName(), ngroups=ngroups, forceattribute=forceattribute, forcecargobay=forcecargobay, forceweight=forceweight})

  -- Set default.
  local n=ngroups or 1

  -- Get the size of an object.
  local function _GetObjectSize(DCSdesc)
    if DCSdesc.box then
      local x=DCSdesc.box.max.x-DCSdesc.box.min.x  --length
      local y=DCSdesc.box.max.y-DCSdesc.box.min.y  --height
      local z=DCSdesc.box.max.z-DCSdesc.box.min.z  --width
      return math.max(x,z), x , y, z
    end
    return 0,0,0,0
  end

  -- Get name of template group.
  local templategroupname=group:GetName()

  local Descriptors=group:GetUnit(1):GetDesc()
  local Category=group:GetCategory()
  local TypeName=group:GetTypeName()
  local SpeedMax=group:GetSpeedMax()
  local RangeMin=group:GetRange()
  local smax,sx,sy,sz=_GetObjectSize(Descriptors)

  --self:E(Descriptors)

  -- Get weight and cargo bay size in kg.
  local weight=0
  local cargobay={}
  local cargobaytot=0
  local cargobaymax=0
  local weights={}
  for _i,_unit in pairs(group:GetUnits()) do
    local unit=_unit --Wrapper.Unit#UNIT
    local Desc=unit:GetDesc()

    -- Weight. We sum up all units in the group.
    local unitweight=forceweight or Desc.massEmpty
    if unitweight then
      weight=weight+unitweight
      weights[_i]=unitweight
    end
    
    local cargomax=0
    local massfuel=Desc.fuelMassMax or 0
    local massempty=Desc.massEmpty or 0
    local massmax=Desc.massMax or 0

    -- Calcuate cargo bay limit value.
    cargomax=massmax-massfuel-massempty
    self:T3(self.lid..string.format("Unit name=%s: mass empty=%.1f kg, fuel=%.1f kg, max=%.1f kg ==> cargo=%.1f kg", unit:GetName(), unitweight, massfuel, massmax, cargomax))

    -- Cargo bay size.
    local bay=forcecargobay or unit:GetCargoBayFreeWeight()

    -- Add bay size to table.
    table.insert(cargobay, bay)

    -- Sum up total bay size.
    cargobaytot=cargobaytot+bay

    -- Get max bay size.
    if bay>cargobaymax then
      cargobaymax=bay
    end
  end

  -- Set/get the generalized attribute.
  local attribute=forceattribute or self:_GetAttribute(group)

  -- Table for returned assets.
  local assets={}

  -- Add this n times to the table.
  for i=1,n do
    local asset={} --#WAREHOUSE.Assetitem

    -- Increase asset unique id counter.
    _WAREHOUSEDB.AssetID=_WAREHOUSEDB.AssetID+1

    -- Set parameters.
    asset.uid=_WAREHOUSEDB.AssetID
    asset.templatename=templategroupname
    asset.template=UTILS.DeepCopy(_DATABASE.Templates.Groups[templategroupname].Template)
    asset.category=Category
    asset.unittype=TypeName
    asset.nunits=#asset.template.units
    asset.range=RangeMin
    asset.speedmax=SpeedMax
    asset.size=smax
    asset.weight=weight
    asset.weights=weights
    asset.DCSdesc=Descriptors
    asset.attribute=attribute
    asset.cargobay=cargobay
    asset.cargobaytot=cargobaytot
    asset.cargobaymax=cargobaymax
    asset.loadradius=loadradius
    if liveries then
      asset.livery=liveries[math.random(#liveries)]
    end
    asset.skill=skill
    asset.assignment=assignment
    asset.spawned=false
    asset.requested=false
    asset.isReserved=false
    asset.life0=group:GetLife0()
    asset.damage=0
    asset.spawngroupname=string.format("%s_AID-%d", templategroupname, asset.uid)

    if i==1 then
      self:_AssetItemInfo(asset)
    end

    -- Add asset to global db.
    _WAREHOUSEDB.Assets[asset.uid]=asset

    -- Add asset to the table that is retured.
    table.insert(assets,asset)
  end

  return assets
end

--- Asset item characteristics.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset The asset for which info in printed in trace mode.
function WAREHOUSE:_AssetItemInfo(asset)
  -- Info about asset:
  local text=string.format("\nNew asset with id=%d for warehouse %s:\n", asset.uid, self.alias)
  text=text..string.format("Spawngroup name= %s\n", asset.spawngroupname)
  text=text..string.format("Template name  = %s\n", asset.templatename)
  text=text..string.format("Unit type      = %s\n", asset.unittype)
  text=text..string.format("Attribute      = %s\n", asset.attribute)
  text=text..string.format("Category       = %d\n", asset.category)
  text=text..string.format("Units #        = %d\n", asset.nunits)
  text=text..string.format("Speed max      = %5.2f km/h\n", asset.speedmax)
  text=text..string.format("Range max      = %5.2f km\n", asset.range/1000)
  text=text..string.format("Size  max      = %5.2f m\n", asset.size)
  text=text..string.format("Weight total   = %5.2f kg\n", asset.weight)
  text=text..string.format("Cargo bay tot  = %5.2f kg\n", asset.cargobaytot)
  text=text..string.format("Cargo bay max  = %5.2f kg\n", asset.cargobaymax)
  text=text..string.format("Load radius    = %s m\n", tostring(asset.loadradius))
  text=text..string.format("Skill          = %s\n", tostring(asset.skill))
  text=text..string.format("Livery         = %s", tostring(asset.livery))  
  self:I(self.lid..text)
  self:T({DCSdesc=asset.DCSdesc})
  self:T3({Template=asset.template})
end

--- On after "NewAsset" event. A new asset has been added to the warehouse stock.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Assetitem asset The asset that has just been added.
-- @param #string assignment The (optional) assignment for the asset.
function WAREHOUSE:onafterNewAsset(From, Event, To, asset, assignment)
  self:T(self.lid..string.format("New asset %s id=%d with assignment %s.", tostring(asset.templatename), asset.uid, tostring(assignment)))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On before "AddRequest" event. Checks some basic properties of the given parameters.
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
-- @param #string Assignment A keyword or text that later be used to identify this request and postprocess the assets.
-- @return #boolean If true, request is okay at first glance.
function WAREHOUSE:onbeforeAddRequest(From, Event, To, warehouse, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType, nTransport, Assignment, Prio)

  -- Request is okay.
  local okay=true

  if AssetDescriptor==WAREHOUSE.Descriptor.ATTRIBUTE then

    -- Check if a valid attibute was given.
    local gotit=false
    for _,attribute in pairs(WAREHOUSE.Attribute) do
      if AssetDescriptorValue==attribute then
        gotit=true
      end
    end
    if not gotit then
      self:_ErrorMessage("ERROR: Invalid request. Asset attribute is unknown!", 5)
      okay=false
    end

  elseif AssetDescriptor==WAREHOUSE.Descriptor.CATEGORY then

    -- Check if a valid category was given.
    local gotit=false
    for _,category in pairs(Group.Category) do
      if AssetDescriptorValue==category then
        gotit=true
      end
    end
    if not gotit then
      self:_ErrorMessage("ERROR: Invalid request. Asset category is unknown!", 5)
      okay=false
    end

  elseif AssetDescriptor==WAREHOUSE.Descriptor.GROUPNAME then

    if type(AssetDescriptorValue)~="string" then
      self:_ErrorMessage("ERROR: Invalid request. Asset template name must be passed as a string!", 5)
      okay=false
    end

  elseif AssetDescriptor==WAREHOUSE.Descriptor.UNITTYPE then

    if type(AssetDescriptorValue)~="string" then
      self:_ErrorMessage("ERROR: Invalid request. Asset unit type must be passed as a string!", 5)
      okay=false
    end

  elseif AssetDescriptor==WAREHOUSE.Descriptor.ASSIGNMENT then

    if type(AssetDescriptorValue)~="string" then
      self:_ErrorMessage("ERROR: Invalid request. Asset assignment type must be passed as a string!", 5)
      okay=false
    end

  elseif AssetDescriptor==WAREHOUSE.Descriptor.ASSETLIST then

    if type(AssetDescriptorValue)~="table" then
      self:_ErrorMessage("ERROR: Invalid request. Asset assignment type must be passed as a table!", 5)
      okay=false
    end

  else
    self:_ErrorMessage("ERROR: Invalid request. Asset descriptor is not ATTRIBUTE, CATEGORY, GROUPNAME, UNITTYPE or ASSIGNMENT!", 5)
    okay=false
  end

  -- Warehouse is stopped?
  if self:IsStopped() then
    self:_ErrorMessage("ERROR: Invalid request. Warehouse is stopped!", 0)
    okay=false
  end

  -- Warehouse is destroyed?
  if self:IsDestroyed() and not self.respawnafterdestroyed then
    self:_ErrorMessage("ERROR: Invalid request. Warehouse is destroyed!", 0)
    okay=false
  end

  return okay
end

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
-- @param #string Assignment A keyword or text that can later be used to identify this request and postprocess the assets.
function WAREHOUSE:onafterAddRequest(From, Event, To, warehouse, AssetDescriptor, AssetDescriptorValue, nAsset, TransportType, nTransport, Prio, Assignment)

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

  -- Self request?
  local toself=false
  if self.warehouse:GetName()==warehouse.warehouse:GetName() then
    toself=true
  end

  -- Increase id.
  self.queueid=self.queueid+1

  -- Request queue table item.
  local request={
  uid=self.queueid,
  prio=Prio,
  warehouse=warehouse,
  assetdesc=AssetDescriptor,
  assetdescval=AssetDescriptorValue,
  nasset=nAsset,
  transporttype=TransportType,
  ntransport=nTransport,
  assignment=tostring(Assignment),
  airbase=warehouse:GetAirbase(),
  category=warehouse:GetAirbaseCategory(),
  ndelivered=0,
  ntransporthome=0,
  assets={},
  toself=toself,
  } --#WAREHOUSE.Queueitem

  -- Add request to queue.
  table.insert(self.queue, request)
  
  local descval="assetlist"
  if request.assetdesc==WAREHOUSE.Descriptor.ASSETLIST then
  
  else
    descval=tostring(request.assetdescval)
  end

  local text=string.format("Warehouse %s: New request from warehouse %s.\nDescriptor %s=%s, #assets=%s; Transport=%s, #transports=%s.",
  self.alias, warehouse.alias, request.assetdesc, descval, tostring(request.nasset), request.transporttype, tostring(request.ntransport))
  self:_DebugMessage(text, 5)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On before "Request" event. Checks if the request can be fulfilled.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
-- @return #boolean If true, request is granted.
function WAREHOUSE:onbeforeRequest(From, Event, To, Request)
  self:T3({warehouse=self.alias, request=Request})

  -- Distance from warehouse to requesting warehouse.
  local distance=self:GetCoordinate():Get2DDistance(Request.warehouse:GetCoordinate())

  -- Shortcut to cargoassets.
  local _assets=Request.cargoassets

  if Request.nasset==0 then
    local text=string.format("Warehouse %s: Request denied! Zero assets were requested.", self.alias)
    self:_InfoMessage(text, 10)
    return false
  end

  -- Check if destination is in range for all requested assets.
  for _,_asset in pairs(_assets) do
    local asset=_asset --#WAREHOUSE.Assetitem

    -- Check if destination is in range.
    if asset.range<distance then
      local text=string.format("Request denied! Destination %s is out of range for asset %s.", Request.airbase:GetName(), asset.templatename)
      self:_InfoMessage(text, 10)

      -- Delete request from queue because it will never be possible.
      -- Unless(!) at least one is a moving warehouse, which could, e.g., be an aircraft carrier.
      if not (self.isUnit or Request.warehouse.isUnit) then
        self:_DeleteQueueItem(Request, self.queue)
      end

      return false
    end

  end

  return true
end


--- On after "Request" event. Spawns the necessary cargo and transport assets.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
function WAREHOUSE:onafterRequest(From, Event, To, Request)

  -- Info message.
  if self.verbosity>=1 then
    local text=string.format("Warehouse %s: Processing request id=%d from warehouse %s.\n", self.alias, Request.uid, Request.warehouse.alias)
    text=text..string.format("Requested %s assets of %s=%s.\n", tostring(Request.nasset), Request.assetdesc, Request.assetdesc==WAREHOUSE.Descriptor.ASSETLIST and "Asset list" or Request.assetdescval)
    text=text..string.format("Transports %s of type %s.", tostring(Request.ntransport), tostring(Request.transporttype))
    self:_InfoMessage(text, 5)
  end

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Cargo assets.
  ------------------------------------------------------------------------------------------------------------------------------------

  -- Set time stamp.
  Request.timestamp=timer.getAbsTime()

  -- Spawn assets of this request.
  self:_SpawnAssetRequest(Request)

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Transport assets
  ------------------------------------------------------------------------------------------------------------------------------------

  -- Shortcut to transport assets.
  local _assetstock=Request.transportassets

  -- Now we try to find all parking spots for all cargo groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  if Request.transportcategory==Group.Category.AIRPLANE or Request.transportcategory==Group.Category.HELICOPTER then
    Parking=self:_FindParkingForAssets(self.airbase,_assetstock)
  end

  -- Transport assets table.
  local _transportassets={}

  ----------------------------
  -- Spawn Transport Groups --
  ----------------------------

  -- Spawn the transport groups.
  for i=1,Request.ntransport do

    -- Get stock item.
    local _assetitem=_assetstock[i] --#WAREHOUSE.Assetitem

    -- Spawn group name
    local _alias=_assetitem.spawngroupname

    -- Set Request ID.
    _assetitem.rid=Request.uid

    -- Asset is transport.
    _assetitem.spawned=false
    _assetitem.iscargo=false
    _assetitem.arrived=false

    local spawngroup=nil --Wrapper.Group#GROUP

    -- Add asset by id to all assets table.
    Request.assets[_assetitem.uid]=_assetitem

    -- Spawn assets depending on type.
    if Request.transporttype==WAREHOUSE.TransportType.AIRPLANE then

      -- Spawn plane at airport in uncontrolled state. Will get activated when cargo is loaded.
      spawngroup=self:_SpawnAssetAircraft(_alias,_assetitem, Request, Parking[_assetitem.uid], true)

    elseif Request.transporttype==WAREHOUSE.TransportType.HELICOPTER then

      -- Spawn helos at airport in controlled state. They need to fly to the spawn zone.
      spawngroup=self:_SpawnAssetAircraft(_alias,_assetitem, Request, Parking[_assetitem.uid], false)

    elseif Request.transporttype==WAREHOUSE.TransportType.APC then

      -- Spawn APCs in spawn zone.
      spawngroup=self:_SpawnAssetGroundNaval(_alias, _assetitem, Request, self.spawnzone)

    elseif Request.transporttype==WAREHOUSE.TransportType.TRAIN then

      self:_ErrorMessage("ERROR: Cargo transport by train not supported yet!")
      return

    elseif Request.transporttype==WAREHOUSE.TransportType.SHIP or Request.transporttype==WAREHOUSE.TransportType.NAVALCARRIER
      or Request.transporttype==WAREHOUSE.TransportType.ARMEDSHIP or Request.transporttype==WAREHOUSE.TransportType.WARSHIP then

      -- Spawn Ship in port zone
      spawngroup=self:_SpawnAssetGroundNaval(_alias, _assetitem, Request, self.portzone)

    elseif Request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then

      self:_ErrorMessage("ERROR: Transport type selfpropelled was already handled above. We should not get here!")
      return

    else
      self:_ErrorMessage("ERROR: Unknown transport type!")
      return
    end

    -- Trigger event.
    if spawngroup then
      self:__AssetSpawned(0.01, spawngroup, _assetitem, Request)
    end

  end

  -- Init problem table.
  Request.assetproblem={}

  -- Add request to pending queue.
  table.insert(self.pending, Request)

  -- Delete request from queue.
  self:_DeleteQueueItem(Request, self.queue)

end

--- On after "RequestSpawned" event. Initiates the transport of the assets to the requesting warehouse.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Pendingitem Request Information table of the request.
-- @param Core.Set#SET_GROUP CargoGroupSet Set of cargo groups.
-- @param Core.Set#SET_GROUP TransportGroupSet Set of transport groups if any.
function WAREHOUSE:onafterRequestSpawned(From, Event, To, Request, CargoGroupSet, TransportGroupSet)

  -- General type and category.
  local _cargotype=Request.cargoattribute    --#WAREHOUSE.Attribute
  local _cargocategory=Request.cargocategory --DCS#Group.Category

  -- Add groups to pending item.
  --Request.cargogroupset=CargoGroupSet

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Self request: assets are spawned at warehouse but not transported anywhere.
  ------------------------------------------------------------------------------------------------------------------------------------

  -- Self request! Assets are only spawned but not routed or transported anywhere.
  if Request.toself then
    self:_DebugMessage(string.format("Selfrequest! Current status %s", self:GetState()))

    -- Start self request.
    self:__SelfRequest(1, CargoGroupSet, Request)

    return
  end

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Self propelled: assets go to the requesting warehouse by themselfs.
  ------------------------------------------------------------------------------------------------------------------------------------

  -- No transport unit requested. Assets go by themselfes.
  if Request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
    self:T2(self.lid..string.format("Got selfpropelled request for %d assets.", CargoGroupSet:Count()))

    for _,_group in pairs(CargoGroupSet:GetSetObjects()) do
      local group=_group --Wrapper.Group#GROUP

      -- Route cargo to their destination.
      if _cargocategory==Group.Category.GROUND then
        self:T2(self.lid..string.format("Route ground group %s.", group:GetName()))

        -- Random place in the spawn zone of the requesting warehouse.
        local ToCoordinate=Request.warehouse.spawnzone:GetRandomCoordinate()

        -- Debug marker.
        if self.Debug then
          ToCoordinate:MarkToAll(string.format("Destination of group %s", group:GetName()))
        end

        -- Route ground.
        self:_RouteGround(group, Request)

      elseif _cargocategory==Group.Category.AIRPLANE or _cargocategory==Group.Category.HELICOPTER then
        self:T2(self.lid..string.format("Route airborne group %s.", group:GetName()))

        -- Route plane to the requesting warehouses airbase.
        -- Actually, the route is already set. We only need to activate the uncontrolled group.
        self:_RouteAir(group)

      elseif _cargocategory==Group.Category.SHIP then
        self:T2(self.lid..string.format("Route naval group %s.", group:GetName()))

        -- Route plane to the requesting warehouses airbase.
        self:_RouteNaval(group, Request)

      elseif _cargocategory==Group.Category.TRAIN then
        self:T2(self.lid..string.format("Route train group %s.", group:GetName()))

        -- Route train to the rail connection of the requesting warehouse.
        self:_RouteTrain(group, Request.warehouse.rail)

      else
        self:E(self.lid..string.format("ERROR: unknown category %s for self propelled cargo %s!", tostring(_cargocategory), tostring(group:GetName())))
      end

    end

    -- Transport group set.
    Request.transportgroupset=TransportGroupSet

    -- No cargo transport necessary.
    return
  end

  ------------------------------------------------------------------------------------------------------------------------------------
  -- Prepare cargo groups for transport
  ------------------------------------------------------------------------------------------------------------------------------------

  -- Board radius, i.e. when the cargo will begin to board the carrier
  local _boardradius=500

  if Request.transporttype==WAREHOUSE.TransportType.AIRPLANE then
    _boardradius=5000
  elseif Request.transporttype==WAREHOUSE.TransportType.HELICOPTER then
    --_loadradius=1000
    --_boardradius=nil
  elseif Request.transporttype==WAREHOUSE.TransportType.APC then
    --_boardradius=nil
  elseif Request.transporttype==WAREHOUSE.TransportType.SHIP or Request.transporttype==WAREHOUSE.TransportType.AIRCRAFTCARRIER 
      or Request.transporttype==WAREHOUSE.TransportType.ARMEDSHIP or Request.transporttype==WAREHOUSE.TransportType.WARSHIP then
    _boardradius=6000
  end

  -- Empty cargo group set.
  local CargoGroups=SET_CARGO:New()

  -- Add cargo groups to set.
  for _,_group in pairs(CargoGroupSet:GetSetObjects()) do

    -- Find asset belonging to this group.
    local asset=self:FindAssetInDB(_group)
    -- New cargo group object.
    local cargogroup=CARGO_GROUP:New(_group, _cargotype,_group:GetName(),_boardradius, asset.loadradius)

    -- Set weight for this group.
    cargogroup:SetWeight(asset.weight)

    -- Add group to group set.
    CargoGroups:AddCargo(cargogroup)

  end

  ------------------------
  -- Create Dispatchers --
  ------------------------

  -- Cargo dispatcher.
  local CargoTransport --AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER

  if Request.transporttype==WAREHOUSE.TransportType.AIRPLANE then

    -- Pickup and deploy zones.
    local PickupAirbaseSet = SET_ZONE:New():AddZone(ZONE_AIRBASE:New(self.airbase:GetName()))
    local DeployAirbaseSet = SET_ZONE:New():AddZone(ZONE_AIRBASE:New(Request.airbase:GetName()))

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_AIRPLANE:New(TransportGroupSet, CargoGroups, PickupAirbaseSet, DeployAirbaseSet)

    -- Set home zone.
    CargoTransport:SetHomeZone(ZONE_AIRBASE:New(self.airbase:GetName()))

  elseif Request.transporttype==WAREHOUSE.TransportType.HELICOPTER then

    -- Pickup and deploy zones.
    local PickupZoneSet = SET_ZONE:New():AddZone(self.spawnzone)
    local DeployZoneSet = SET_ZONE:New():AddZone(Request.warehouse.spawnzone)

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_HELICOPTER:New(TransportGroupSet, CargoGroups, PickupZoneSet, DeployZoneSet)

    -- Home zone.
    CargoTransport:SetHomeZone(self.spawnzone)

  elseif Request.transporttype==WAREHOUSE.TransportType.APC then

    -- Pickup and deploy zones.
    local PickupZoneSet = SET_ZONE:New():AddZone(self.spawnzone)
    local DeployZoneSet = SET_ZONE:New():AddZone(Request.warehouse.spawnzone)

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_APC:New(TransportGroupSet, CargoGroups, PickupZoneSet, DeployZoneSet, 0)

    -- Set home zone.
    CargoTransport:SetHomeZone(self.spawnzone)

  elseif Request.transporttype==WAREHOUSE.TransportType.SHIP or Request.transporttype==WAREHOUSE.TransportType.AIRCRAFTCARRIER 
      or Request.transporttype==WAREHOUSE.TransportType.ARMEDSHIP or Request.transporttype==WAREHOUSE.TransportType.WARSHIP then

    -- Pickup and deploy zones.
    local PickupZoneSet = SET_ZONE:New():AddZone(self.portzone)
    PickupZoneSet:AddZone(self.harborzone)
    local DeployZoneSet = SET_ZONE:New():AddZone(Request.warehouse.harborzone)


    -- Get the shipping lane to use and pass it to the Dispatcher
    local remotename = Request.warehouse.warehouse:GetName()
    local ShippingLane = self.shippinglanes[remotename][math.random(#self.shippinglanes[remotename])]

    -- Define dispatcher for this task.
    CargoTransport = AI_CARGO_DISPATCHER_SHIP:New(TransportGroupSet, CargoGroups, PickupZoneSet, DeployZoneSet, ShippingLane)

    -- Set home zone
    CargoTransport:SetHomeZone(self.portzone)

  else
    self:E(self.lid.."ERROR: Unknown transporttype!")
  end

  -- Set pickup and deploy radii.
  -- The 20 m inner radius are to ensure that the helo does not land on the warehouse itself in the middle of the default spawn zone.
  local pickupouter = 200
  local pickupinner = 0
  local deployouter = 200
  local deployinner = 0
  if Request.transporttype==WAREHOUSE.TransportType.SHIP or Request.transporttype==WAREHOUSE.TransportType.AIRCRAFTCARRIER 
    or Request.transporttype==WAREHOUSE.TransportType.ARMEDSHIP or Request.transporttype==WAREHOUSE.TransportType.WARSHIP then
    pickupouter=1000
    pickupinner=20
    deployouter=1000
    deployinner=0
  else 
    pickupouter=200
    pickupinner=0
    if self.spawnzone.Radius~=nil then
      pickupouter=self.spawnzone.Radius
      pickupinner=20
    end
    deployouter=200
    deployinner=0
    if self.spawnzone.Radius~=nil then
      deployouter=Request.warehouse.spawnzone.Radius
      deployinner=20
    end
  end
  CargoTransport:SetPickupRadius(pickupouter, pickupinner)
  CargoTransport:SetDeployRadius(deployouter, deployinner)


  -- Adjust carrier units. This has to come AFTER the dispatchers have been defined because they set the cargobay free weight!
  Request.carriercargo={}
  for _,carriergroup in pairs(TransportGroupSet:GetSetObjects()) do
    local asset=self:FindAssetInDB(carriergroup)
    for _i,_carrierunit in pairs(carriergroup:GetUnits()) do
      local carrierunit=_carrierunit --Wrapper.Unit#UNIT

      -- Create empty tables which will be filled with the cargo groups of each carrier unit. Needed in case a carrier unit dies.
      Request.carriercargo[carrierunit:GetName()]={}

      -- Adjust cargo bay of carrier unit.
      local cargobay=asset.cargobay[_i]
      carrierunit:SetCargoBayWeightLimit(cargobay)

      -- Debug info.
      self:T2(self.lid..string.format("Cargo bay weight limit of carrier unit %s: %.1f kg.", carrierunit:GetName(), carrierunit:GetCargoBayFreeWeight()))
    end
  end

  --------------------------------
  -- Dispatcher Event Functions --
  --------------------------------

  --- Function called after carrier picked up something.
  function CargoTransport:OnAfterPickedUp(From, Event, To, Carrier, PickupZone)

    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE

    -- Debug message.
    local text=string.format("Carrier group %s picked up at pickup zone %s.", Carrier:GetName(), PickupZone:GetName())
    warehouse:T(warehouse.lid..text)

  end

  --- Function called if something was deployed.
  function CargoTransport:OnAfterDeployed(From, Event, To, Carrier, DeployZone)

    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE

    -- Debug message.
    -- TODO: Depoloy zone is nil!
    --local text=string.format("Carrier group %s deployed at deploy zone %s.", Carrier:GetName(), DeployZone:GetName())
    --warehouse:T(warehouse.lid..text)

  end

  --- Function called if carrier group is going home.
  function CargoTransport:OnAfterHome(From, Event, To, Carrier, Coordinate, Speed, Height, HomeZone)

    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE

    -- Debug message.
    local text=string.format("Carrier group %s going home to zone %s.", Carrier:GetName(), HomeZone:GetName())
    warehouse:T(warehouse.lid..text)

  end

  --- Function called when a carrier unit has loaded a cargo group.
  function CargoTransport:OnAfterLoaded(From, Event, To, Carrier, Cargo, CarrierUnit, PickupZone)

    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE

    -- Debug message.
    local text=string.format("Carrier group %s loaded cargo %s into unit %s in pickup zone %s", Carrier:GetName(), Cargo:GetName(), CarrierUnit:GetName(), PickupZone:GetName())
    warehouse:T(warehouse.lid..text)

    -- Get cargo group object.
    local group=Cargo:GetObject() --Wrapper.Group#GROUP

     -- Get request.
    local request=warehouse:_GetRequestOfGroup(group, warehouse.pending)

    -- Add cargo group to this carrier.
    table.insert(request.carriercargo[CarrierUnit:GetName()], warehouse:_GetNameWithOut(Cargo:GetName()))

  end

  --- Function called when cargo has arrived and was unloaded.
  function CargoTransport:OnAfterUnloaded(From, Event, To, Carrier, Cargo, CarrierUnit, DeployZone)

    -- Get warehouse state.
    local warehouse=Carrier:GetState(Carrier, "WAREHOUSE") --#WAREHOUSE

    -- Get group obejet.
    local group=Cargo:GetObject() --Wrapper.Group#GROUP

    -- Debug message.
    local text=string.format("Cargo group %s was unloaded from carrier unit %s.", tostring(group:GetName()), tostring(CarrierUnit:GetName()))
    warehouse:T(warehouse.lid..text)

    -- Load the cargo in the warehouse.
    --Cargo:Load(warehouse.warehouse)

    -- Trigger Arrived event.
    warehouse:Arrived(group)
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
    warehouse:I(warehouse.lid..text)

    -- Call arrived event for carrier.
    warehouse:__Arrived(1, Carrier)

  end

  -- Start dispatcher.
  CargoTransport:__Start(5)

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
  self:_DebugMessage(string.format("Cargo %s unloaded!", tostring(group:GetName())), 5)

  if group and group:IsAlive() then

    -- Debug smoke.
    if self.Debug then
      group:SmokeWhite()
    end

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
    self:E(self.lid..string.format("ERROR unloaded Cargo group is not alive!"))
  end
end

--- On before "Arrived" event. Triggered when a group has arrived at its destination warehouse.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group that was delivered.
function WAREHOUSE:onbeforeArrived(From, Event, To, group)

  local asset=self:FindAssetInDB(group)

  if asset then

    if asset.flightgroup and not asset.arrived then
      --env.info("FF asset has a flightgroup. arrival will be handled there!")
      asset.arrived=true
      return false
    end  
  
    if asset.arrived==true then
      -- Asset already arrived (e.g. if multiple units trigger the event via landing).
      return false
    else
      asset.arrived=true  --ensure this is not called again from the same asset group.
      return true
    end
    
  end

end

--- On after "Arrived" event. Triggered when a group has arrived at its destination warehouse.
-- The routine should be called by the warehouse sending this asset and not by the receiving warehouse.
-- It is checked if this asset is cargo (or self propelled) or transport. If it is cargo it is put into the stock of receiving warehouse.
-- If it is a transporter it is put back into the sending warehouse since transports are supposed to return their home warehouse.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group that was delivered.
function WAREHOUSE:onafterArrived(From, Event, To, group)

  -- Debug message and smoke.
  if self.Debug then
    group:SmokeOrange()
  end

  -- Get pending request this group belongs to.
  local request=self:_GetRequestOfGroup(group, self.pending)

  if request then

    -- Get the right warehouse to put the asset into
    -- Transports go back to the warehouse which called this function while cargo goes into the receiving warehouse.
    local warehouse=request.warehouse
    local istransport=self:_GroupIsTransport(group,request)
    if istransport==true then
      warehouse=self
    elseif istransport==false then
      warehouse=request.warehouse
    else
      self:E(self.lid..string.format("ERROR: Group %s is neither cargo nor transport", group:GetName()))
      return
    end

    -- Debug message.
    self:_DebugMessage(string.format("Group %s arrived at warehouse %s!", tostring(group:GetName()), warehouse.alias), 5)

    -- Route mobile ground group to the warehouse. Group has 60 seconds to get there or it is despawned and added as asset to the new warehouse regardless.
    if group:IsGround() and group:GetSpeedMax()>1 then
      group:RouteGroundTo(warehouse:GetCoordinate(), group:GetSpeedMax()*0.3, "Off Road")
    end

    -- Move asset from pending queue into new warehouse.
    self:T(self.lid.."Asset arrived at warehouse adding in 60 sec")
    warehouse:__AddAsset(60, group)
  end

end

--- On after "Delivered" event. Triggered when all asset groups have reached their destination. Corresponding request is deleted from the pending queue.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Pendingitem request The pending request that is finished and deleted from the pending queue.
function WAREHOUSE:onafterDelivered(From, Event, To, request)

  -- Debug info
  if self.verbosity>=1 then
    local text=string.format("Warehouse %s: All assets delivered to warehouse %s!", self.alias, request.warehouse.alias)
    self:_InfoMessage(text, 5)
  end

  -- Make some noise :)
  if self.Debug then
    self:_Fireworks(request.warehouse:GetCoordinate())
  end

  -- Set delivered status for this request uid.
  self.delivered[request.uid]=true

end


--- On after "SelfRequest" event. Request was initiated to the warehouse itself. Groups are just spawned at the warehouse or the associated airbase.
-- If the warehouse is currently under attack when the self request is made, the self request is added to the defending table. One the attack is defeated,
-- this request is used to put the groups back into the warehouse stock.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of asset groups that was delivered to the warehouse itself.
-- @param #WAREHOUSE.Pendingitem request Pending self request.
function WAREHOUSE:onafterSelfRequest(From, Event, To, groupset, request)

  -- Debug info.
  self:_DebugMessage(string.format("Assets spawned at warehouse %s after self request!", self.alias))

  -- Debug info.
  for _,_group in pairs(groupset:GetSetObjects()) do
    local group=_group --Wrapper.Group#GROUP
    if self.Debug then
      group:FlareGreen()
    end
  end

  -- Add a "defender request" to be able to despawn all assets once defeated.
  if self:IsAttacked() then

    -- Route (mobile) ground troops to warehouse zone if they are not alreay there.
    if self.autodefence then
      for _,_group in pairs(groupset:GetSetObjects()) do
        local group=_group --Wrapper.Group#GROUP
        local speedmax=group:GetSpeedMax()
        if group:IsGround() and speedmax>1 and group:IsNotInZone(self.zone) then
          group:RouteGroundTo(self.zone:GetRandomCoordinate(), 0.8*speedmax, "Off Road")
        end
      end
    end

    -- Add request to defenders.
    table.insert(self.defending, request)
  end

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
  self:_InfoMessage(text)

  -- Debug smoke.
  if self.Debug then
    self:GetCoordinate():SmokeOrange()
  end

  -- Spawn all ground units in the spawnzone?
  if self.autodefence then
    local nground=self:GetNumberOfAssets(WAREHOUSE.Descriptor.CATEGORY, Group.Category.GROUND)
    local text=string.format("Warehouse auto defence activated.\n")

    if nground>0 then
      text=text..string.format("Deploying all %d ground assets.", nground)

      -- Add self request.
      self:AddRequest(self, WAREHOUSE.Descriptor.CATEGORY, Group.Category.GROUND, WAREHOUSE.Quantity.ALL, nil, nil , 0, "AutoDefence")
    else
      text=text..string.format("No ground assets currently available.")
    end
    self:_InfoMessage(text)
  else
    local text=string.format("Warehouse auto defence inactive.")
    self:I(self.lid..text)
  end
end

--- On after "Defeated" event. Warehouse defeated an attack by another coalition. Defender assets are added back to warehouse stock.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterDefeated(From, Event, To)

  -- Message.
  local text=string.format("Warehouse %s: Enemy attack was defeated!", self.alias)
  self:_InfoMessage(text)

  -- Debug smoke.
  if self.Debug then
    self:GetCoordinate():SmokeGreen()
  end

  -- Auto defence: put assets back into stock.
  if self.autodefence then
    for _,request in pairs(self.defending) do

      -- Route defenders back to warehoue (for visual reasons only) and put them back into stock.
      for _,_group in pairs(request.cargogroupset:GetSetObjects()) do
        local group=_group --Wrapper.Group#GROUP

        -- Get max speed of group and route it back slowly to the warehouse.
        local speed=group:GetSpeedMax()
        if group:IsGround() and speed>1 then
          group:RouteGroundTo(self:GetCoordinate(), speed*0.3)
        end

        -- Add asset group back to stock after 60 seconds.
        self:__AddAsset(60, group)
      end

    end

    self.defending=nil
    self.defending={}
  end
end

--- Respawn warehouse.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterRespawn(From, Event, To)

  -- Info message.
  local text=string.format("Respawning warehouse %s", self.alias)
  self:_InfoMessage(text)

  -- Respawn warehouse.
  self.warehouse:ReSpawn()

end

--- On before "ChangeCountry" event. Checks whether a change of country is necessary by comparing the actual country to the the requested one.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#country.id Country which has captured the warehouse.
function WAREHOUSE:onbeforeChangeCountry(From, Event, To, Country)

  local currentCountry=self:GetCountry()

  -- Message.
  local text=string.format("Warehouse %s: request to change country %d-->%d", self.alias, currentCountry, Country)
  self:_DebugMessage(text, 10)

  -- Check if current or requested coalition or country match.
  if currentCountry~=Country then
    return true
  end

  return false
end

--- On after "ChangeCountry" event. Warehouse is respawned with the specified country. All queued requests are deleted and the owned airbase is reset if the coalition is changed by changing the
-- country.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#country.id Country Country which has captured the warehouse.
function WAREHOUSE:onafterChangeCountry(From, Event, To, Country)

  local CoalitionOld=self:GetCoalition()

  self.warehouse:ReSpawn(Country)

  local CoalitionNew=self:GetCoalition()

  -- Delete all waiting requests because they are not valid any more.
  self.queue=nil
  self.queue={}

  if self.airbasename then

    -- Get airbase of this warehouse.
    local airbase=AIRBASE:FindByName(self.airbasename)

    -- Get coalition of the airbase.
    local airbaseCoalition=airbase:GetCoalition()

    if CoalitionNew==airbaseCoalition then
      -- Airbase already owned by the coalition that captured the warehouse. Airbase can be used by this warehouse.
      self.airbase=airbase
    else
      -- Airbase is owned by other coalition. So this warehouse does not have an airbase until it is captured.
      self.airbase=nil
    end

  end

  -- Debug smoke.
  if self.Debug then
    if CoalitionNew==coalition.side.RED then
      self:GetCoordinate():SmokeRed()
    elseif CoalitionNew==coalition.side.BLUE then
      self:GetCoordinate():SmokeBlue()
    end
  end

end

--- On before "Captured" event. Warehouse has been captured by another coalition.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition which captured the warehouse.
-- @param DCS#country.id Country which has captured the warehouse.
function WAREHOUSE:onbeforeCaptured(From, Event, To, Coalition, Country)

  -- Warehouse respawned.
  self:ChangeCountry(Country)

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
  local text=string.format("Warehouse %s: We were captured by enemy coalition (side=%d)!", self.alias, Coalition)
  self:_InfoMessage(text)

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
  self:_InfoMessage(text)

  -- Debug smoke.
  if self.Debug then
    if Coalition==coalition.side.RED then
      self.airbase:GetCoordinate():SmokeRed()
    elseif Coalition==coalition.side.BLUE then
      self.airbase:GetCoordinate():SmokeBlue()
    end
  end

  -- Set airbase to nil and category to no airbase.
  self.airbase=nil
end

--- On after "AirbaseRecaptured" event. Airbase of warehouse has been re-captured from other coalition.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition Coalition side which originally captured the warehouse.
function WAREHOUSE:onafterAirbaseRecaptured(From, Event, To, Coalition)

  -- Message.
  local text=string.format("Warehouse %s: We recaptured our airbase %s from the enemy (coalition=%d)!", self.alias, self.airbasename, Coalition)
  self:_InfoMessage(text)

  -- Set airbase and category.
  self.airbase=AIRBASE:FindByName(self.airbasename)

  -- Debug smoke.
  if self.Debug then
    if Coalition==coalition.side.RED then
      self.airbase:GetCoordinate():SmokeRed()
    elseif Coalition==coalition.side.BLUE then
      self.airbase:GetCoordinate():SmokeBlue()
    end
  end

end

--- On after "RunwayDestroyed" event.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterRunwayDestroyed(From, Event, To)

  -- Message.
  local text=string.format("Warehouse %s: Runway %s destroyed!", self.alias, self.airbasename)
  self:_InfoMessage(text)

  self.runwaydestroyed=timer.getAbsTime()
  
  return self
end

--- On after "RunwayRepaired" event.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterRunwayRepaired(From, Event, To)

  -- Message.
  local text=string.format("Warehouse %s: Runway %s repaired!", self.alias, self.airbasename)
  self:_InfoMessage(text)

  self.runwaydestroyed=nil
  
  return self
end


--- On after "AssetSpawned" event triggered when an asset group is spawned into the cruel world.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group spawned.
-- @param #WAREHOUSE.Assetitem asset The asset that is dead.
-- @param #WAREHOUSE.Pendingitem request The request of the dead asset.
function WAREHOUSE:onafterAssetSpawned(From, Event, To, group, asset, request)
  local text=string.format("Asset %s from request id=%d was spawned!", asset.spawngroupname, request.uid)
  self:T(self.lid..text)

  -- Sete asset state to spawned.
  asset.spawned=true
  
  -- Set spawn group name.
  asset.spawngroupname=group:GetName()
  
  -- Remove asset from stock.
  self:_DeleteStockItem(asset)          

  -- Add group.
  if asset.iscargo==true then
    request.cargogroupset=request.cargogroupset or SET_GROUP:New()
    request.cargogroupset:AddGroup(group)
  else
    request.transportgroupset=request.transportgroupset or SET_GROUP:New()
    request.transportgroupset:AddGroup(group)
  end

  -- Set warehouse state.
  group:SetState(group, "WAREHOUSE", self)  

  -- Check if all assets groups are spawned and trigger events.
  local n=0
  for _,_asset in pairs(request.assets) do
    local assetitem=_asset --#WAREHOUSE.Assetitem

    -- Debug info.
    self:T(self.lid..string.format("Asset %s spawned %s as %s", assetitem.templatename, tostring(assetitem.spawned), tostring(assetitem.spawngroupname)))

    if assetitem.spawned then
      n=n+1
    else
      -- Now this can happend if multiple groups need to be spawned in one request.
      --self:I(self.lid.."FF What?! This should not happen!")
    end

  end

  -- Trigger event.
  if n==request.nasset+request.ntransport then
    self:T(self.lid..string.format("All assets %d (ncargo=%d + ntransport=%d) of request rid=%d spawned. Calling RequestSpawned", n, request.nasset, request.ntransport, request.uid))
    self:RequestSpawned(request, request.cargogroupset, request.transportgroupset)
  else
    self:T(self.lid..string.format("Not all assets %d (ncargo=%d + ntransport=%d) of request rid=%d spawned YET", n, request.nasset, request.ntransport, request.uid))
  end

end

--- On after "AssetDead" event triggered when an asset group died.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #WAREHOUSE.Assetitem asset The asset that is dead.
-- @param #WAREHOUSE.Pendingitem request The request of the dead asset.
function WAREHOUSE:onafterAssetDead(From, Event, To, asset, request)

  if asset and request then

    -- Debug message.
    local text=string.format("Asset %s from request id=%d is dead!", asset.templatename, request.uid)
    self:T(self.lid..text)
  
    -- Here I need to get rid of the #CARGO at the end to obtain the original name again!
    local groupname=asset.spawngroupname --self:_GetNameWithOut(group)
  
    -- Dont trigger a Remove event for the group sets.
    local NoTriggerEvent=true
  
    if request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
  
      ---
      -- Easy case: Group can simply be removed from the cargogroupset.
      ---
  
      -- Remove dead group from cargo group set.
      if request.cargogroupset then
        -- cargogroupset was nil for user case. Difficult to reproduce so we add a nil check.
        request.cargogroupset:Remove(groupname, NoTriggerEvent)
        self:T(self.lid..string.format("Removed selfpropelled cargo %s: ncargo=%d.", groupname, request.cargogroupset:Count()))
      else
        self:E(self.lid..string.format("ERROR: cargogroupset is nil for request ID=%s!", tostring(request.uid)))
      end
  
    else
  
      ---
      -- Complicated case: Dead unit could be:
      -- 1.) A Cargo unit (e.g. waiting to be picked up).
      -- 2.) A Transport unit which itself holds cargo groups.
      ---
  
      -- Check if this a cargo or transport group.
      local istransport=not asset.iscargo --self:_GroupIsTransport(group, request)
  
      if istransport==true then
  
        -- Whole carrier group is dead. Remove it from the carrier group set.
        request.transportgroupset:Remove(groupname, NoTriggerEvent)
        self:T(self.lid..string.format("Removed transport %s: ntransport=%d", groupname, request.transportgroupset:Count()))
  
      elseif istransport==false then
  
        -- This must have been an alive cargo group that was killed outside the carrier, e.g. waiting to be transported or waiting to be put back.
        -- Remove dead group from cargo group set.
        request.cargogroupset:Remove(groupname, NoTriggerEvent)
        self:T(self.lid..string.format("Removed transported cargo %s outside carrier: ncargo=%d", groupname, request.cargogroupset:Count()))
        -- This as well?
        --request.transportcargoset:RemoveCargosByName(RemoveCargoNames)
        
      else
        --self:E(self.lid..string.format("ERROR: Group %s is neither cargo nor transport!", group:GetName()))
      end
    end
    
  else
    self:E(self.lid.."ERROR: Asset and/or Request is nil in onafterAssetDead")
  
  end
  
end


--- On after "Destroyed" event. Warehouse was destroyed. All services are stopped. Warehouse is going to "Stopped" state in one minute.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WAREHOUSE:onafterDestroyed(From, Event, To)

  -- Message.
  local text=string.format("Warehouse %s was destroyed! Assets lost %d. Respawn=%s", self.alias, #self.stock, tostring(self.respawnafterdestroyed))
  self:_InfoMessage(text)

  if self.respawnafterdestroyed then

    if self.respawndelay then
      self:Pause()
      self:__Respawn(self.respawndelay)
    else
      self:Respawn()
    end

  else

    -- Remove all table entries from waiting queue and stock.
    for k,_ in pairs(self.queue) do
      self.queue[k]=nil
    end

    for k,_ in pairs(self.stock) do
      --self.stock[k]=nil
    end

    for k=#self.stock,1,-1 do
      --local asset=self.stock[k] --#WAREHOUSE.Assetitem
      --self:AssetDead(asset, nil)
      self.stock[k]=nil
    end

    --self.queue=nil
    --self.queue={}

    --self.stock=nil
    --self.stock={}
  end

end


--- On after "Save" event. Warehouse assets are saved to file on disk.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is saved. If nil, file is saved in the DCS root installtion directory.
-- @param #string filename (Optional) Name of the file containing the asset data.
function WAREHOUSE:onafterSave(From, Event, To, path, filename)

  local function _savefile(filename, data)
    local f = assert(io.open(filename, "wb"))
    f:write(data)
    f:close()
  end

  -- Set file name.
  filename=filename or string.format("WAREHOUSE-%d_%s.txt", self.uid, self.alias)

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end

  -- Info
  local text=string.format("Saving warehouse assets to file %s", filename)
  MESSAGE:New(text,30):ToAllIf(self.Debug or self.Report)
  self:I(self.lid..text)

  local warehouseassets=""
  warehouseassets=warehouseassets..string.format("coalition=%d\n", self:GetCoalition())
  warehouseassets=warehouseassets..string.format("country=%d\n", self:GetCountry())

  -- Loop over all assets in stock.
  for _,_asset in pairs(self.stock) do
    local asset=_asset -- #WAREHOUSE.Assetitem

    -- Loop over asset parameters.
    local assetstring=""
    for key,value in pairs(asset) do

      -- Only save keys which are needed to restore the asset.
      if key=="templatename" or key=="attribute" or key=="cargobay" or key=="weight" or key=="loadradius" or key=="livery" or key=="skill" or key=="assignment" then
        local name
        if type(value)=="table" then
          name=string.format("%s=%s;", key, value[1])
        else
          name=string.format("%s=%s;", key, value)
        end
        assetstring=assetstring..name
      end
      self:I(string.format("Loaded asset: %s", assetstring))
    end

    -- Add asset string.
    warehouseassets=warehouseassets..assetstring.."\n"
  end

  -- Save file.
  _savefile(filename, warehouseassets)

end


--- On before "Load" event. Checks if the file the warehouse data should be loaded from exists.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is loaded from.
-- @param #string filename (Optional) Name of the file containing the asset data.
function WAREHOUSE:onbeforeLoad(From, Event, To, path, filename)


  local function _fileexists(name)
     local f=io.open(name,"r")
     if f~=nil then
      io.close(f)
      return true
    else
      return false
    end
  end

  -- Set file name.
  filename=filename or string.format("WAREHOUSE-%d_%s.txt", self.uid, self.alias)

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end

  -- Check if file exists.
  local exists=_fileexists(filename)

  if exists then
    return true
  else
    self:_ErrorMessage(string.format("ERROR: file %s does not exist! Cannot load assets.", filename), 60)
    return false
  end

end


--- On after "Load" event. Warehouse assets are loaded from file on disk.
-- @param #WAREHOUSE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is loaded from.
-- @param #string filename (Optional) Name of the file containing the asset data.
function WAREHOUSE:onafterLoad(From, Event, To, path, filename)

  local function _loadfile(filename)
    local f = assert(io.open(filename, "rb"))
    local data = f:read("*all")
    f:close()
    return data
  end

  -- Set file name.
  filename=filename or string.format("WAREHOUSE-%d_%s.txt", self.uid, self.alias)

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end

  -- Info
  local text=string.format("Loading warehouse assets from file %s", filename)
  MESSAGE:New(text,30):ToAllIf(self.Debug or self.Report)
  self:I(self.lid..text)

  -- Load asset data from file.
  local data=_loadfile(filename)

  -- Split by line break.
  local assetdata=UTILS.Split(data,"\n")

  -- Coalition and coutrny.
  local Coalition
  local Country

  -- Loop over asset lines.
  local assets={}
  for _,asset in pairs(assetdata) do

    -- Parameters are separated by semi-colons
    local descriptors=UTILS.Split(asset,";")

    local asset={}
    local isasset=false
    for _,descriptor in pairs(descriptors) do

      local keyval=UTILS.Split(descriptor,"=")

      if #keyval==2 then

        if keyval[1]=="coalition" then
          -- Get coalition side.
          Coalition=tonumber(keyval[2])
        elseif keyval[1]=="country" then
          -- Get country id.
          Country=tonumber(keyval[2])
        else

          -- This is an asset.
          isasset=true

          local key=keyval[1]
          local val=keyval[2]

          --env.info(string.format("FF asset key=%s val=%s", key, val))

          -- Livery or skill could be "nil".
          if val=="nil" then
            val=nil
          end

          -- Convert string to number where necessary.
          if key=="cargobay" or key=="weight" or key=="loadradius" then
            asset[key]=tonumber(val)
          else
            asset[key]=val
          end
        end

      end
    end

    -- Add to table.
    if isasset then
      table.insert(assets, asset)
    end
  end

  -- Respawn warehouse with prev coalition if necessary.
  if Country~=self:GetCountry() then
    self:T(self.lid..string.format("Changing warehouse country %d-->%d on loading assets.", self:GetCountry(), Country))
    self:ChangeCountry(Country)
  end

  for _,_asset in pairs(assets) do
    local asset=_asset --#WAREHOUSE.Assetitem

    local group=GROUP:FindByName(asset.templatename)
    if group then
      self:AddAsset(group, 1, asset.attribute, asset.cargobay, asset.weight, asset.loadradius, asset.skill, asset.livery, asset.assignment)
    else
      self:E(string.format("ERROR: Group %s doest not exit. Cannot be loaded as asset.", tostring(asset.templatename)))
    end
  end

end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Spawn functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Spawns requested assets at warehouse or associated airbase.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem Request Information table of the request.
function WAREHOUSE:_SpawnAssetRequest(Request)
  self:F2({requestUID=Request.uid})

  -- Shortcut to cargo assets.
  local cargoassets=Request.cargoassets

  -- Now we try to find all parking spots for all cargo groups in advance. Due to the for loop, the parking spots do not get updated while spawning.
  local Parking={}
  if Request.cargocategory==Group.Category.AIRPLANE or Request.cargocategory==Group.Category.HELICOPTER then
    --TODO: Check for airstart. Should be a request property.
    Parking=self:_FindParkingForAssets(self.airbase, cargoassets) or {}
  end

  -- Spawn aircraft in uncontrolled state.
  local UnControlled=true

  -- Loop over cargo requests.
  for i=1,#cargoassets do

    -- Get stock item.
    local asset=cargoassets[i] --#WAREHOUSE.Assetitem
    
    if not asset.spawned then

      -- Set asset status to not spawned until we capture its birth event.
      asset.iscargo=true
  
      -- Set request ID.
      asset.rid=Request.uid
  
      -- Spawn group name.
      local _alias=asset.spawngroupname
  
      --Request add asset by id.
      Request.assets[asset.uid]=asset
  
      -- Spawn an asset group.
      local _group=nil --Wrapper.Group#GROUP
      if asset.category==Group.Category.GROUND then
  
        -- Spawn ground troops.
        _group=self:_SpawnAssetGroundNaval(_alias, asset, Request, self.spawnzone, Request.lateActivation)
  
      elseif asset.category==Group.Category.AIRPLANE or asset.category==Group.Category.HELICOPTER then
  
        -- Spawn air units.
        if Parking[asset.uid] then
          _group=self:_SpawnAssetAircraft(_alias, asset, Request, Parking[asset.uid], UnControlled, Request.lateActivation)
        else
          _group=self:_SpawnAssetAircraft(_alias, asset, Request, nil, UnControlled, Request.lateActivation)
        end
  
      elseif asset.category==Group.Category.TRAIN then
  
        -- Spawn train.
        if self.rail then
          --TODO: Rail should only get one asset because they would spawn on top!
  
          -- Spawn naval assets.
          _group=self:_SpawnAssetGroundNaval(_alias, asset, Request, self.spawnzone, Request.lateActivation)
        end
  
        --self:E(self.lid.."ERROR: Spawning of TRAIN assets not possible yet!")
  
      elseif asset.category==Group.Category.SHIP then
  
        -- Spawn naval assets.
        _group=self:_SpawnAssetGroundNaval(_alias, asset, Request, self.portzone, Request.lateActivation)
  
      else
        self:E(self.lid.."ERROR: Unknown asset category!")
      end
      
      -- Trigger event.
      if _group then
        self:__AssetSpawned(0.01, _group, asset, Request)
      end    
  
    end
    
  end

end


--- Spawn a ground or naval asset in the corresponding spawn zone of the warehouse.
-- @param #WAREHOUSE self
-- @param #string alias Alias name of the asset group.
-- @param #WAREHOUSE.Assetitem asset Ground asset that will be spawned.
-- @param #WAREHOUSE.Queueitem request Request belonging to this asset. Needed for the name/alias.
-- @param Core.Zone#ZONE spawnzone Zone where the assets should be spawned.
-- @param #boolean lateactivated If true, groups are spawned late activated.
-- @return Wrapper.Group#GROUP The spawned group or nil if the group could not be spawned.
function WAREHOUSE:_SpawnAssetGroundNaval(alias, asset, request, spawnzone, lateactivated)

  if asset and (asset.category==Group.Category.GROUND or asset.category==Group.Category.SHIP or asset.category==Group.Category.TRAIN) then

    -- Prepare spawn template.
    local template=self:_SpawnAssetPrepareTemplate(asset, alias)

    -- Initial spawn point.
    template.route.points[1]={}

    -- Get a random coordinate in the spawn zone.
    local coord=spawnzone:GetRandomCoordinate()

    -- For trains, we use the rail connection point.
    if asset.category==Group.Category.TRAIN then
      coord=self.rail
    end

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

      if asset.livery then
        unit.livery_id = asset.livery
      end
      if asset.skill then
        unit.skill= asset.skill
      end

    end
    
    -- Late activation.
    template.lateActivation=lateactivated

    template.route.points[1].x = coord.x
    template.route.points[1].y = coord.z

    template.x   = coord.x
    template.y   = coord.z
    template.alt = coord.y

    -- Spawn group.
    local group=_DATABASE:Spawn(template) --Wrapper.Group#GROUP

    return group
  end

  return nil
end

--- Spawn an aircraft asset (plane or helo) at the airbase associated with the warehouse.
-- @param #WAREHOUSE self
-- @param #string alias Alias name of the asset group.
-- @param #WAREHOUSE.Assetitem asset Ground asset that will be spawned.
-- @param #WAREHOUSE.Queueitem request Request belonging to this asset. Needed for the name/alias.
-- @param #table parking Parking data for this asset.
-- @param #boolean uncontrolled Spawn aircraft in uncontrolled state.
-- @param #boolean lateactivated If true, groups are spawned late activated.
-- @return Wrapper.Group#GROUP The spawned group or nil if the group could not be spawned.
function WAREHOUSE:_SpawnAssetAircraft(alias, asset, request, parking, uncontrolled, lateactivated)

  if asset and asset.category==Group.Category.AIRPLANE or asset.category==Group.Category.HELICOPTER then

    -- Prepare the spawn template.
    local template=self:_SpawnAssetPrepareTemplate(asset, alias)

    -- Cold start (default).
    local _type=COORDINATE.WaypointType.TakeOffParking
    local _action=COORDINATE.WaypointAction.FromParkingArea

    -- Hot start.
    if asset.takeoffType and asset.takeoffType==COORDINATE.WaypointType.TakeOffParkingHot then
      _type=COORDINATE.WaypointType.TakeOffParkingHot
      _action=COORDINATE.WaypointAction.FromParkingAreaHot
      uncontrolled=false
    end
    
    local airstart=asset.takeoffType and asset.takeoffType==COORDINATE.WaypointType.TurningPoint or false
    
    if airstart then
      _type=COORDINATE.WaypointType.TurningPoint
      _action=COORDINATE.WaypointAction.TurningPoint
      uncontrolled=false    
    end


    -- Set route points.
    if request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then

      -- Get flight path if the group goes to another warehouse by itself.
      if request.toself then
      
        local coord=self.airbase:GetCoordinate()
        
        if airstart then
          coord:SetAltitude(math.random(1000, 2000))
        end
        
        -- Single waypoint.
        local wp=coord:WaypointAir("RADIO", _type, _action, 0, false, self.airbase, {}, "Parking")
        template.route.points={wp}
      else
        template.route.points=self:_GetFlightplan(asset, self.airbase, request.warehouse.airbase)
      end

    else

      -- First route point is the warehouse airbase.
      template.route.points[1]=self.airbase:GetCoordinate():WaypointAir("BARO", _type, _action, 0, true, self.airbase, nil, "Spawnpoint")

    end

    -- Get airbase ID and category.
    local AirbaseID = self.airbase:GetID()
    local AirbaseCategory = self:GetAirbaseCategory()

    -- Check enough parking spots.
    if AirbaseCategory==Airbase.Category.HELIPAD or AirbaseCategory==Airbase.Category.SHIP then

      --TODO Figure out what's necessary in this case.

    else

      if #parking<#template.units and not airstart then
        local text=string.format("ERROR: Not enough parking! Free parking = %d < %d aircraft to be spawned.", #parking, #template.units)
        self:_DebugMessage(text)
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
        
        if airstart then
          unit.alt=math.random(1000, 2000)
        end

        unit.parking_id = nil
        unit.parking    = nil

      else

        local coord=nil    --Core.Point#COORDINATE
        local terminal=nil --#number
        
        if airstart then
          coord=self.airbase:GetCoordinate():SetAltitude(math.random(1000, 2000))
        else
          coord=parking[i].Coordinate
          terminal=parking[i].TerminalID
        end

        if self.Debug and terminal then
          local text=string.format("Spawnplace unit %s terminal %d.", unit.name, terminal)
          coord:MarkToAll(text)
          env.info(text)
        end

        unit.x=coord.x
        unit.y=coord.z
        unit.alt=coord.y

        unit.parking_id = nil
        unit.parking    = terminal

      end

      if asset.livery then
        unit.livery_id = asset.livery
      end

      if asset.skill then
        unit.skill= asset.skill
      end

      if asset.payload then
        unit.payload=asset.payload.pylons
      end

      if asset.modex then
        unit.onboard_num=asset.modex[i]
      end
      if asset.callsign then
        unit.callsign=asset.callsign[i]
      end

    end

    -- And template position.
    template.x = template.units[1].x
    template.y = template.units[1].y

    -- DCS bug workaround. Spawning helos in uncontrolled state on carriers causes a big spash!
    -- See https://forums.eagle.ru/showthread.php?t=219550
    -- Should be solved in latest OB update 2.5.3.21708
    --if AirbaseCategory == Airbase.Category.SHIP and asset.category==Group.Category.HELICOPTER then
    --  uncontrolled=false
    --end

    -- Uncontrolled spawning.
    template.uncontrolled=uncontrolled

    -- Debug info.
    self:T2({airtemplate=template})

    -- Spawn group.
    local group=_DATABASE:Spawn(template) --Wrapper.Group#GROUP

    return group
  end

  return nil
end


--- Prepare a spawn template for the asset. Deep copy of asset template, adjusting template and unit names, nillifying group and unit ids.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset Ground asset that will be spawned.
-- @param #string alias Alias name of the group.
-- @return #table Prepared new spawn template.
function WAREHOUSE:_SpawnAssetPrepareTemplate(asset, alias)

  -- Create an own copy of the template!
  local template=UTILS.DeepCopy(asset.template)

  -- Set unique name.
  template.name=alias

  -- Set current(!) coalition and country.
  template.CoalitionID=self:GetCoalition()
  template.CountryID=self:GetCountry()

  -- Nillify the group ID.
  template.groupId=nil

  -- No late activation.
  template.lateActivation=false

  if asset.missionTask then
    self:T(self.lid..string.format("Setting mission task to %s", tostring(asset.missionTask)))
    template.task=asset.missionTask
  end

  -- No predefined task.
  --template.taskSelected=false

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
-- Routing functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Route ground units to destination. ROE is set to return fire and alarm state to green.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The ground group to be routed
-- @param #WAREHOUSE.Queueitem request The request for this group.
function WAREHOUSE:_RouteGround(group, request)

  if group and group:IsAlive() then

    -- Set speed to 70% of max possible.
    local _speed=group:GetSpeedMax()*0.7

    -- Route waypoints.
    local Waypoints={}

    -- Check if an off road path has been defined.
    local hasoffroad=self:HasConnectionOffRoad(request.warehouse, self.Debug)

    -- Check if any off road paths have be defined. They have priority!
    if hasoffroad then

      -- Get off road path to remote warehouse. If more have been defined, pick one randomly.
      local remotename=request.warehouse.warehouse:GetName()
      local path=self.offroadpaths[remotename][math.random(#self.offroadpaths[remotename])]

      -- Loop over user defined shipping lanes.
      for i=1,#path do

        -- Shortcut and coordinate intellisense.
        local coord=path[i] --Core.Point#COORDINATE

        -- Get waypoint for coordinate.
        local Waypoint=coord:WaypointGround(_speed, "Off Road")

        -- Add waypoint to route.
        table.insert(Waypoints, Waypoint)
      end

    else

      -- Waypoints for road-to-road connection.
      Waypoints = group:TaskGroundOnRoad(request.warehouse.road, _speed, "Off Road", false, self.road)

      -- First waypoint = current position of the group.
      local FromWP=group:GetCoordinate():WaypointGround(_speed, "Off Road")
      table.insert(Waypoints, 1, FromWP)

      -- Final coordinate. Note, this can lead to errors if the final WP is too close the the point on the road. The vehicle will stop driving and not reach the final WP!
      --local ToCO=request.warehouse.spawnzone:GetRandomCoordinate()
      --local ToWP=ToCO:WaypointGround(_speed, "Off Road")
      --table.insert(Waypoints, #Waypoints+1, ToWP)

    end

    for n,wp in ipairs(Waypoints) do
      local tf=self:_SimpleTaskFunctionWP("warehouse:_PassingWaypoint",group, n, #Waypoints)
      group:SetTaskWaypoint(wp, tf)
    end

    -- Route group to destination.
    group:Route(Waypoints, 1)

    -- Set ROE and alaram state.
    group:OptionROEReturnFire()
    group:OptionAlarmStateGreen()
  end
end

--- Route naval units along user defined shipping lanes to destination warehouse. ROE is set to return fire.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The naval group to be routed
-- @param #WAREHOUSE.Queueitem request The request for this group.
function WAREHOUSE:_RouteNaval(group, request)

  -- Check if we have a group and it is alive.
  if group and group:IsAlive() then

    -- Set speed to 80% of max possible.
    local _speed=group:GetSpeedMax()*0.8

    -- Get shipping lane to remote warehouse. If more have been defined, pick one randomly.
    local remotename=request.warehouse.warehouse:GetName()
    local lane=self.shippinglanes[remotename][math.random(#self.shippinglanes[remotename])]

    if lane then

      -- Route waypoints.
      local Waypoints={}

      -- Loop over user defined shipping lanes.
      for i=1,#lane do

        -- Shortcut and coordinate intellisense.
        local coord=lane[i] --Core.Point#COORDINATE

        -- Get waypoint for coordinate.
        local Waypoint=coord:WaypointGround(_speed)

        -- Add waypoint to route.
        table.insert(Waypoints, Waypoint)
      end

      -- Task function triggering the arrived event at the last waypoint.
      local TaskFunction = self:_SimpleTaskFunction("warehouse:_Arrived", group)

      -- Put task function on last waypoint.
      local Waypoint = Waypoints[#Waypoints]
      group:SetTaskWaypoint(Waypoint, TaskFunction)

      -- Route group to destination.
      group:Route(Waypoints, 1)

      -- Set ROE (Naval units dont have and alaram state.)
      group:OptionROEReturnFire()

    else
      -- This should not happen! Existance of shipping lane was checked before executing this request.
      self:E(self.lid..string.format("ERROR: No shipping lane defined for Naval asset!"))
    end

  end
end


--- Route the airplane from one airbase another. Activates uncontrolled aircraft and sets ROE/ROT for ferry flights.
-- ROE is set to return fire and ROT to passive defence.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP aircraft Airplane group to be routed.
function WAREHOUSE:_RouteAir(aircraft)

  if aircraft and aircraft:IsAlive()~=nil then

    -- Debug info.
    self:T2(self.lid..string.format("RouteAir aircraft group %s alive=%s", aircraft:GetName(), tostring(aircraft:IsAlive())))

    -- Give start command to activate uncontrolled aircraft within the next 60 seconds.
    if self.flightcontrol then
      local fg=FLIGHTGROUP:New(aircraft)
      fg:SetReadyForTakeoff(true)    
    else
      aircraft:StartUncontrolled(math.random(60))
    end

    -- Debug info.
    self:T2(self.lid..string.format("RouteAir aircraft group %s alive=%s (after start command)", aircraft:GetName(), tostring(aircraft:IsAlive())))

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

    -- Task function triggering the arrived event at the last waypoint.
    local TaskFunction = self:_SimpleTaskFunction("warehouse:_Arrived", Group)

    -- Put task function on last waypoint.
    local Waypoint = Waypoints[#Waypoints]
    Group:SetTaskWaypoint( Waypoint, TaskFunction )

    -- Route group to destination.
    Group:Route(Waypoints, 1)
  end
end

--- Task function for last waypoint. Triggering the "Arrived" event.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that arrived.
function WAREHOUSE:_Arrived(group)
  self:_DebugMessage(string.format("Group %s arrived!", tostring(group:GetName())))

  if group then
    --Trigger "Arrived event.
    self:__Arrived(1, group)
  end

end

--- Task function for when passing a waypoint.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group that arrived.
-- @param #number n Waypoint passed.
-- @param #number N Final waypoint.
function WAREHOUSE:_PassingWaypoint(group, n, N)
  self:T(self.lid..string.format("Group %s passing waypoint %d of %d!", tostring(group:GetName()), n, N))

  -- Final waypoint reached.
  if n==N then
    self:__Arrived(1, group)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event handler functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get a warehouse asset from its unique id.
-- @param #WAREHOUSE self
-- @param #number id Asset ID.
-- @return #WAREHOUSE.Assetitem The warehouse asset.
function WAREHOUSE:GetAssetByID(id)
  if id then
    return _WAREHOUSEDB.Assets[id]
  else
    return nil
  end
end

--- Get a warehouse asset from its name.
-- @param #WAREHOUSE self
-- @param #string GroupName Spawn group name.
-- @return #WAREHOUSE.Assetitem The warehouse asset.
function WAREHOUSE:GetAssetByName(GroupName)

  local name=self:_GetNameWithOut(GroupName)
  local _,aid,_=self:_GetIDsFromGroup(GROUP:FindByName(name))

  if aid then
    return _WAREHOUSEDB.Assets[aid]
  else
    return nil
  end
end

--- Get a warehouse request from its unique id.
-- @param #WAREHOUSE self
-- @param #number id Request ID.
-- @return #WAREHOUSE.Pendingitem The warehouse requested - either queued or pending.
-- @return #boolean If *true*, request is queued, if *false*, request is pending, if *nil*, request could not be found.
function WAREHOUSE:GetRequestByID(id)

  if id then

    for _,_request in pairs(self.queue) do
      local request=_request --#WAREHOUSE.Queueitem
      if request.uid==id then
        return request, true
      end
    end

    for _,_request in pairs(self.pending) do
      local request=_request --#WAREHOUSE.Pendingitem
      if request.uid==id then
        return request, false
      end
    end

  end

  return nil,nil
end

--- Warehouse event function, handling the birth of a unit.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventBirth(EventData)
  self:T3(self.lid..string.format("Warehouse %s (id=%s) captured event birth!", self.alias, self.uid))

  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup

    -- Note: Remember, group:IsAlive might(?) not return true here.
    local wid,aid,rid=self:_GetIDsFromGroup(group)

    if wid==self.uid then

      -- Get asset and request from id.
      local asset=self:GetAssetByID(aid)
      local request=self:GetRequestByID(rid)
            
      if asset and request then

        -- Debug message.
        self:T(self.lid..string.format("Warehouse %s captured event birth of request ID=%d, asset ID=%d, unit %s spawned=%s", self.alias, request.uid, asset.uid, EventData.IniUnitName, tostring(asset.spawned)))
        
        -- Set born to true.
        request.born=true
        
      else
        self:E(self.lid..string.format("ERROR: Either asset AID=%s or request RID=%s are nil in event birth of unit %s", tostring(aid), tostring(rid), tostring(EventData.IniUnitName)))
      end

    else
      --self:T3({wid=wid, uid=self.uid, match=(wid==self.uid), tw=type(wid), tu=type(self.uid)})
    end

  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function handling the event when a (warehouse) unit starts its engines.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventEngineStartup(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event engine startup!",self.alias))

  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:T(self.lid..string.format("Warehouse %s captured event engine startup of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function handling the event when a (warehouse) unit takes off.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventTakeOff(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event takeoff!",self.alias))

  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:T(self.lid..string.format("Warehouse %s captured event takeoff of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function handling the event when a (warehouse) unit lands.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventLanding(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event landing!", self.alias))

  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup

    -- Try to get UIDs from group name.
    local wid,aid,rid=self:_GetIDsFromGroup(group)

    -- Check that this group belongs to this warehouse.
    if wid~=nil and wid==self.uid then

      -- Debug info.
      self:T(self.lid..string.format("Warehouse %s captured event landing of its asset unit %s.", self.alias, EventData.IniUnitName))

    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function handling the event when a (warehouse) unit shuts down its engines.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventEngineShutdown(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event engine shutdown!", self.alias))

  if EventData and EventData.IniGroup then
    local group=EventData.IniGroup
    local wid,aid,rid=self:_GetIDsFromGroup(group)
    if wid==self.uid then
      self:T(self.lid..string.format("Warehouse %s captured event engine shutdown of its asset unit %s.", self.alias, EventData.IniUnitName))
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Arrived event if an air unit/group arrived at its destination. This can be an engine shutdown or a landing event.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data table.
function WAREHOUSE:_OnEventArrived(EventData)

  if EventData and EventData.IniUnit then

    -- Unit that arrived.
    local unit=EventData.IniUnit

    -- Check if unit is alive and on the ground. Engine shutdown can also be triggered in other situations!
    if unit and unit:IsAlive()==true and unit:InAir()==false then

      -- Get group.
      local group=EventData.IniGroup

      -- Get unique IDs from group name.
      local wid,aid,rid=self:_GetIDsFromGroup(group)

      -- If all IDs are good we can assume it is a warehouse asset.
      if wid~=nil and aid~=nil and rid~=nil then

        -- Check that warehouse ID is right.
        if self.uid==wid then

          local request=self:_GetRequestOfGroup(group, self.pending)

          -- Better check that the request still exists, because for a group with more units, the
          if request then

            local istransport=self:_GroupIsTransport(group, request)

            -- Get closest airbase.
            local closest=group:GetCoordinate():GetClosestAirbase()

            -- Check if engine shutdown happend at right airbase because the event is also triggered in other situations.
            local rightairbase=closest:GetName()==request.warehouse:GetAirbase():GetName()

            -- Check that group is cargo and not transport.
            if istransport==false and rightairbase then

              -- Trigger arrived event for this group. Note that each unit of a group will trigger this event. So the onafterArrived function needs to take care of that.
              -- Actually, we only take the first unit of the group that arrives. If it does, we assume the whole group arrived, which might not be the case, since
              -- some units might still be taxiing or whatever. Therefore, we add 10 seconds for each additional unit of the group until the first arrived event is triggered.
              local nunits=#group:GetUnits()
              local dt=10*(nunits-1)+1  -- one unit = 1 sec, two units = 11 sec, three units = 21 sec before we call the group arrived.
              
              -- Debug info.
              if self.verbosity>=1 then
                local text=string.format("Air asset group %s from warehouse %s arrived at its destination. Trigger Arrived event in %d sec", group:GetName(), self.alias, dt)
                self:_InfoMessage(text)
              end              
              
              -- Arrived event.
              self:__Arrived(dt, group)
            end

          end
        end

      else
        self:T3(string.format("Group that arrived did not belong to a warehouse. Warehouse ID=%s, Asset ID=%s, Request ID=%s.", tostring(wid), tostring(aid), tostring(rid)))
      end
    end
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse event handling function.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventCrashOrDead(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event dead or crash!", self.alias))

  if EventData then

    -- Check if warehouse was destroyed. We compare the name of the destroyed unit.
    if EventData.IniUnitName then
      local warehousename=self.warehouse:GetName()
      if EventData.IniUnitName==warehousename then
        self:_DebugMessage(string.format("Warehouse %s alias %s was destroyed!", warehousename, self.alias))

        -- Trigger Destroyed event.
        self:Destroyed()
      end
      if self.airbase and self.airbasename and self.airbasename==EventData.IniUnitName then
        if self:IsRunwayOperational() then
          -- Trigger RunwayDestroyed event (only if it is not destroyed already)
          self:RunwayDestroyed()
        else
          -- Reset the time stamp.
          self.runwaydestroyed=timer.getAbsTime()
        end        
      end
    end

    -- Debug info.
    self:T2(self.lid..string.format("Warehouse %s captured event dead or crash or unit %s", self.alias, tostring(EventData.IniUnitName)))

    -- Check if an asset unit was destroyed.
    if EventData.IniGroup then

      -- Group initiating the event.
      local group=EventData.IniGroup

      -- Get warehouse, asset and request IDs from the group name.
      local wid,aid,rid=self:_GetIDsFromGroup(group)

      -- Check that we have the right warehouse.
      if wid==self.uid then

        -- Debug message.
        self:T(self.lid..string.format("Warehouse %s captured event dead or crash of its asset unit %s", self.alias, EventData.IniUnitName))

        -- Loop over all pending requests and get the one belonging to this unit.
        for _,request in pairs(self.pending) do
          local request=request --#WAREHOUSE.Pendingitem

          -- This is the right request.
          if request.uid==rid then

            -- Update cargo and transport group sets of this request. We need to know if this job is finished.
            self:_UnitDead(EventData.IniUnit, EventData.IniGroup, request)

          end
        end
      end
    end
  end
end

--- A unit of a group just died. Update group sets in request.
-- This is important in order to determine if a job is done and can be removed from the (pending) queue.
-- @param #WAREHOUSE self
-- @param Wrapper.Unit#UNIT deadunit Unit that died.
-- @param Wrapper.Group#GROUP deadgroup Group of unit that died.
-- @param #WAREHOUSE.Pendingitem request Request that needs to be updated.
function WAREHOUSE:_UnitDead(deadunit, deadgroup, request)
  --self:F(self.lid.."FF unit dead "..deadunit:GetName())

  -- Find opsgroup.
  local opsgroup=_DATABASE:FindOpsGroup(deadgroup)
  
  -- Check if we have an opsgroup.
  if opsgroup then  
    -- Handled in OPSGROUP:onafterDead() now.
    return nil  
  end

  -- Number of alive units in group.
  local nalive=deadgroup:CountAliveUnits()

  -- Whole group is dead?
  local groupdead=false
  if nalive>0 then
    groupdead=false
  else
    groupdead=true
  end
  
  -- Find asset.  
  local asset=self:FindAssetInDB(deadgroup)  

  -- Here I need to get rid of the #CARGO at the end to obtain the original name again!
  local unitname=self:_GetNameWithOut(deadunit)
  local groupname=self:_GetNameWithOut(deadgroup)

  -- Group is dead!
  if groupdead then
    -- Debug output.
    self:T(self.lid..string.format("Group %s (transport=%s) is dead!", groupname, tostring(self:_GroupIsTransport(deadgroup,request))))
    if self.Debug then
      deadgroup:SmokeWhite()
    end
    -- Trigger AssetDead event.    
    self:AssetDead(asset, request)
  end


  -- Dont trigger a Remove event for the group sets.
  local NoTriggerEvent=true

  if request.transporttype~=WAREHOUSE.TransportType.SELFPROPELLED then

    ---
    -- Complicated case: Dead unit could be:
    -- 1.) A Cargo unit (e.g. waiting to be picked up).
    -- 2.) A Transport unit which itself holds cargo groups.
    ---

    if not asset.iscargo then

      -- Get the carrier unit table holding the cargo groups inside this carrier.
      local cargogroupnames=request.carriercargo[unitname]

      if cargogroupnames then

        -- Loop over all groups inside the destroyed carrier ==> all dead.
        for _,cargoname in pairs(cargogroupnames) do
          request.cargogroupset:Remove(cargoname, NoTriggerEvent)
          self:T(self.lid..string.format("Removed transported cargo %s inside dead carrier %s: ncargo=%d", cargoname, unitname, request.cargogroupset:Count()))
        end

      end

    else
      self:E(self.lid..string.format("ERROR: Group %s is neither cargo nor transport!", deadgroup:GetName()))
    end
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Warehouse event handling function.
-- Handles the case when the airbase associated with the warehous is captured.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventBaseCaptured(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event base captured!",self.alias))

  -- This warehouse does not have an airbase and never had one. So it could not have been captured.
  if self.airbasename==nil then
    return
  end

  if EventData and EventData.Place then

    -- Place is the airbase that was captured.
    local airbase=EventData.Place --Wrapper.Airbase#AIRBASE

    -- Check that this airbase belongs or did belong to this warehouse.
    if EventData.PlaceName==self.airbasename then

      -- New coalition of airbase after it was captured.
      local NewCoalitionAirbase=airbase:GetCoalition()

      -- Debug info
      self:T(self.lid..string.format("Airbase of warehouse %s (coalition ID=%d) was captured! New owner coalition ID=%d.",self.alias, self:GetCoalition(), NewCoalitionAirbase))

      -- So what can happen?
      -- Warehouse is blue, airbase is blue and belongs to warehouse and red captures it  ==> self.airbase=nil
      -- Warehouse is blue, airbase is blue self.airbase is nil and blue (re-)captures it ==> self.airbase=Event.Place
      if self.airbase==nil then
        -- New coalition is the same as of the warehouse ==> warehouse previously lost this airbase and now it was re-captured.
        if NewCoalitionAirbase == self:GetCoalition() then
          self:AirbaseRecaptured(NewCoalitionAirbase)
        end
      else
        -- Captured airbase belongs to this warehouse but was captured by other coalition.
        if NewCoalitionAirbase ~= self:GetCoalition() then
          self:AirbaseCaptured(NewCoalitionAirbase)
        end
      end

    end
  end
end

--- Warehouse event handling function.
-- Handles the case when the mission is ended.
-- @param #WAREHOUSE self
-- @param Core.Event#EVENTDATA EventData Event data.
function WAREHOUSE:_OnEventMissionEnd(EventData)
  self:T3(self.lid..string.format("Warehouse %s captured event mission end!",self.alias))

  if self.autosave then
    self:Save(self.autosavepath, self.autosavefile)
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
        self:T2(self.lid..string.format("Unit %s in warehouse zone of radius=%d m. Coalition=%d, country=%d. Distance = %d m.",unit:GetName(), radius,_coalition,_country, distance))

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
  self:T(self.lid..string.format("Ground troops in warehouse zone: blue=%d, red=%d, neutral=%d", Nblue, Nred, Nneutral))


  -- Figure out the new coalition if any.
  -- Condition is that only units of one coalition are within the zone.
  local newcoalition=self:GetCoalition()
  local newcountry=self:GetCountry()
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
  if self:IsAttacked() and newcoalition ~= self:GetCoalition() then
    self:Captured(newcoalition, newcountry)
    return
  end

  -- Before a warehouse can be captured, it has to be attacked.
  -- That is, even if only enemy units are present it is not immediately captured in order to spawn all ground assets for defence.
  if self:GetCoalition()==coalition.side.BLUE then
    -- Blue warehouse is running and we have red units in the zone.
    if self:IsRunning() and Nred>0 then
      self:Attacked(coalition.side.RED, CountryRed)
    end
    -- Blue warehouse was under attack by blue but no more blue units in zone.
    if self:IsAttacked() and Nred==0 then
      self:Defeated()
    end
  elseif self:GetCoalition()==coalition.side.RED then
    -- Red Warehouse is running and we have blue units in the zone.
    if self:IsRunning() and Nblue>0 then
      self:Attacked(coalition.side.BLUE, CountryBlue)
    end
    -- Red warehouse was under attack by blue but no more blue units in zone.
    if self:IsAttacked() and Nblue==0 then
      self:Defeated()
    end
  elseif self:GetCoalition()==coalition.side.NEUTRAL then
    -- Neutrals dont attack!
    if self:IsRunning() and Nred>0 then
      self:Attacked(coalition.side.RED, CountryRed)
    elseif self:IsRunning() and Nblue>0 then
      self:Attacked(coalition.side.BLUE, CountryBlue)
    end
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
      if self:GetCoalition()~=airbasecurrentcoalition then
        self.airbase=nil
      end

    else

      -- Warehouse has re-captured the airbase.
      if self:GetCoalition()==airbasecurrentcoalition then
        self.airbase=airbase
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
  self:T3(self.lid..string.format("Number of queued requests = %d", #queue))

  -- Requests to delete.
  local invalid={}

  for _,_request in pairs(queue) do
    local request=_request --#WAREHOUSE.Queueitem

    -- Debug info.
    self:T2(self.lid..string.format("Checking request id=%d.", request.uid))

    -- Let's assume everything is fine.
    local valid=true

    -- Check if at least one asset was requested.
    if request.nasset==0 then
      self:E(self.lid..string.format("ERROR: INVALID request. Request for zero assets not possible. Can happen when, e.g. \"all\" ground assets are requests but none in stock."))
      valid=false
    end

    -- Request from enemy coalition?
    if self:GetCoalition()~=request.warehouse:GetCoalition() then
      self:E(self.lid..string.format("ERROR: INVALID request. Requesting warehouse is of wrong coalition! Own coalition %s != %s of requesting warehouse.", self:GetCoalitionName(), request.warehouse:GetCoalitionName()))
      valid=false
    end

    -- Is receiving warehouse stopped?
    if request.warehouse:IsStopped() then
      self:E(self.lid..string.format("ERROR: INVALID request. Requesting warehouse is stopped!"))
      valid=false
    end

    -- Is receiving warehouse destroyed?
    if request.warehouse:IsDestroyed() and not self.respawnafterdestroyed then
      self:E(self.lid..string.format("ERROR: INVALID request. Requesting warehouse is destroyed!"))
      valid=false
    end

    -- Add request as unvalid and delete it later.
    if valid==false then
      self:E(self.lid..string.format("Got invalid request id=%d.", request.uid))
      table.insert(invalid, request)
    else
      self:T3(self.lid..string.format("Got valid request id=%d.", request.uid))
    end
  end

  -- Delete invalid requests.
  for _,_request in pairs(invalid) do
    self:E(self.lid..string.format("Deleting INVALID request id=%d.",_request.uid))
    self:_DeleteQueueItem(_request, self.queue)
  end

end

--- Check if a request is valid in general. If not, it will be removed from the queue.
-- This routine needs to have at least one asset in stock that matches the request descriptor in order to determine whether the request category of troops.
-- If no asset is in stock, the request will remain in the queue but cannot be executed.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem request The request to be checked.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequestValid(request)

  -- Check if number of requested assets is in stock.
  local _assets,_nassets,_enough=self:_FilterStock(self.stock, request.assetdesc, request.assetdescval, request.nasset)

  -- No assets in stock? Checks cannot be performed.
  if #_assets==0 then
    return true
  end

  -- Convert relative to absolute number if necessary.
  local nasset=request.nasset
  if type(request.nasset)=="string" then
    nasset=self:_QuantityRel2Abs(request.nasset,_nassets)
  end

  -- Debug check, request.nasset might be a string Quantity enumerator.
  local text=string.format("Request valid? Number of assets: requested=%s=%d, selected=%d, total=%d, enough=%s.", tostring(request.nasset), nasset,#_assets,_nassets, tostring(_enough))
  self:T(text)

  -- First asset. Is representative for all filtered items in stock.
  local asset=_assets[1] --#WAREHOUSE.Assetitem

  -- Asset is air, ground etc.
  local asset_plane  = asset.category==Group.Category.AIRPLANE
  local asset_helo   = asset.category==Group.Category.HELICOPTER
  local asset_ground = asset.category==Group.Category.GROUND
  local asset_train  = asset.category==Group.Category.TRAIN
  local asset_naval  = asset.category==Group.Category.SHIP

  -- General air request.
  local asset_air=asset_helo or asset_plane

  -- Assume everything is okay.
  local valid=true

  -- Category of the requesting warehouse airbase.
  local requestcategory=request.warehouse:GetAirbaseCategory()

  if request.transporttype==WAREHOUSE.TransportType.SELFPROPELLED then
    -------------------------------------------
    -- Case where the units go my themselves --
    -------------------------------------------

    if asset_air then

      if asset_plane then

        -- No airplane to or from FARPS.
        if requestcategory==Airbase.Category.HELIPAD or self:GetAirbaseCategory()==Airbase.Category.HELIPAD then
          self:E("ERROR: Incorrect request. Asset airplane requested but warehouse or requestor is HELIPAD/FARP!")
          valid=false
        end

        -- Category SHIP is not general enough! Fighters can go to carriers. Which fighters, is there an attibute?
        -- Also for carriers, attibute?

      elseif asset_helo then

        -- Helos need a FARP or AIRBASE or SHIP for spawning. Also at the the receiving warehouse. So even if they could go there they "cannot" be spawned again.
        -- Unless I allow spawning of helos in the the spawn zone. But one should place at least a FARP there.
        if self:GetAirbaseCategory()==-1 or requestcategory==-1 then
          self:E("ERROR: Incorrect request. Helos need a AIRBASE/HELIPAD/SHIP as home/destination base!")
          valid=false
        end

      end

      -- All aircraft need an airbase of any type at depature and destination.
      if self.airbase==nil or request.airbase==nil then

        self:E("ERROR: Incorrect request. Either warehouse or requesting warehouse does not have any kind of airbase!")
        valid=false

      else

        -- Check if enough parking spots are available. This checks the spots available in general, i.e. not the free spots.
        -- TODO: For FARPS/ships, is it possible to send more assets than parking spots? E.g. a FARPS has only four (or even one).
        -- TODO: maybe only check if spots > 0 for the necessary terminal type? At least for FARPS.

        -- Get necessary terminal type.
        local termtype_dep=asset.terminalType or self:_GetTerminal(asset.attribute, self:GetAirbaseCategory())
        local termtype_des=asset.terminalType or self:_GetTerminal(asset.attribute, request.warehouse:GetAirbaseCategory())

        -- Get number of parking spots.
        local np_departure=self.airbase:GetParkingSpotsNumber(termtype_dep)
        local np_destination=request.airbase:GetParkingSpotsNumber(termtype_des)

        -- Debug info.
        self:T(string.format("Asset attribute = %s, DEPARTURE: terminal type = %d, spots = %d, DESTINATION: terminal type = %d, spots = %d", asset.attribute, termtype_dep, np_departure, termtype_des, np_destination))

        -- Not enough parking at sending warehouse.
        --if (np_departure < request.nasset) and not (self.category==Airbase.Category.SHIP or self.category==Airbase.Category.HELIPAD) then
        if np_departure < nasset then
          self:E(string.format("ERROR: Incorrect request. Not enough parking spots of terminal type %d at warehouse. Available spots %d < %d necessary.", termtype_dep, np_departure, nasset))
          valid=false
        end

        -- No parking at requesting warehouse.
        if np_destination == 0 then
          self:E(string.format("ERROR: Incorrect request. No parking spots of terminal type %d at requesting warehouse. Available spots = %d!", termtype_des, np_destination))
          valid=false
        end

      end

    elseif asset_ground then

      -- Check that both spawn zones are not in water.
      local inwater=self.spawnzone:GetCoordinate():IsSurfaceTypeWater() or request.warehouse.spawnzone:GetCoordinate():IsSurfaceTypeWater()

      if inwater and not request.lateActivation then
        self:E("ERROR: Incorrect request. Ground asset requested but at least one spawn zone is in water!")
        return false
      end

      -- No ground assets directly to or from ships.
      -- TODO: May needs refinement if warehouse is on land and requestor is ship in harbour?!
      --if (requestcategory==Airbase.Category.SHIP or self:GetAirbaseCategory()==Airbase.Category.SHIP) then
      --  self:E("ERROR: Incorrect request. Ground asset requested but warehouse or requestor is SHIP!")
      --  valid=false
      --end

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

          -- Check if there is a valid off road path.
          local hasoffroad=self:HasConnectionOffRoad(request.warehouse)

          if not (hasroad or hasoffroad) then
            self:E("ERROR: Incorrect request. No valid path on or off road for ground assets!")
            valid=false
          end

        end

      end

    elseif asset_naval then

        -- Check shipping lane.
        local shippinglane=self:HasConnectionNaval(request.warehouse)

        if not shippinglane then
          self:E("ERROR: Incorrect request. No shipping lane has been defined between warehouses!")
          valid=false
        end

    end

  else
    -------------------------------
    -- Assests need a transport ---
    -------------------------------

    if request.transporttype==WAREHOUSE.TransportType.AIRPLANE then

      -- Airplanes only to AND from airdromes.
      if self:GetAirbaseCategory()~=Airbase.Category.AIRDROME or requestcategory~=Airbase.Category.AIRDROME then
        self:E("ERROR: Incorrect request. Warehouse or requestor does not have an airdrome. No transport by plane possible!")
        valid=false
      end

      --TODO: Not sure if there are any transport planes that can land on a carrier?

    elseif request.transporttype==WAREHOUSE.TransportType.APC then

      -- Transport by ground units.

      -- No transport to or from ships
      if self:GetAirbaseCategory()==Airbase.Category.SHIP or requestcategory==Airbase.Category.SHIP then
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
      if self:GetAirbaseCategory()==-1 then
        self:E("ERROR: Incorrect request. Warehouse has no airbase. Transport by helicopter not possible!")
        valid=false
      end

    elseif request.transporttype==WAREHOUSE.TransportType.SHIP or request.transporttype==WAREHOUSE.TransportType.AIRCRAFTCARRIER 
        or request.transporttype==WAREHOUSE.TransportType.ARMEDSHIP or request.transporttype==WAREHOUSE.TransportType.WARSHIP then

      -- Transport by ship.
      local shippinglane=self:HasConnectionNaval(request.warehouse)

      if not shippinglane then
        self:E("ERROR: Incorrect request. No shipping lane has been defined between warehouses!")
        valid=false
      end

    elseif request.transporttype==WAREHOUSE.TransportType.TRAIN then

      -- Transport by train.
      self:E("ERROR: Incorrect request. Transport by TRAIN not implemented yet!")
      valid=false

    else
      -- No match.
      self:E("ERROR: Incorrect request. Transport type unknown!")
      valid=false
    end

    -- Airborne assets: check parking situation.
    if request.transporttype==WAREHOUSE.TransportType.AIRPLANE or request.transporttype==WAREHOUSE.TransportType.HELICOPTER then

      -- Check if number of requested assets is in stock.
      local _assets,_nassets,_enough=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, request.transporttype, request.ntransport, true)

      -- Convert relative to absolute number if necessary.
      local nasset=request.ntransport
      if type(request.ntransport)=="string" then
        nasset=self:_QuantityRel2Abs(request.ntransport,_nassets)
      end

      -- Debug check, request.nasset might be a string Quantity enumerator.
      local text=string.format("Request valid? Number of transports: requested=%s=%d, selected=%d, total=%d, enough=%s.", tostring(request.ntransport), nasset,#_assets,_nassets, tostring(_enough))
      self:T(text)

      -- Get necessary terminal type for helos or transport aircraft.
      local termtype=self:_GetTerminal(request.transporttype, self:GetAirbaseCategory())

      -- Get number of parking spots.
      local np_departure=self.airbase:GetParkingSpotsNumber(termtype)

      -- Debug info.
      self:T(self.lid..string.format("Transport attribute = %s, terminal type = %d, spots at departure = %d.", request.transporttype, termtype, np_departure))

      -- Not enough parking at sending warehouse.
      --if (np_departure < request.nasset) and not (self.category==Airbase.Category.SHIP or self.category==Airbase.Category.HELIPAD) then
      if np_departure < nasset then
        self:E(self.lid..string.format("ERROR: Incorrect request. Not enough parking spots of terminal type %d at warehouse. Available spots %d < %d necessary.", termtype, np_departure, nasset))
        valid=false
      end

      -- Planes also need parking at the receiving warehouse.
      if request.transporttype==WAREHOUSE.TransportType.AIRPLANE then

        -- Total number of parking spots for transport planes at destination.
        termtype=self:_GetTerminal(request.transporttype, request.warehouse:GetAirbaseCategory())
        local np_destination=request.airbase:GetParkingSpotsNumber(termtype)

        -- Debug info.
        self:T(self.lid..string.format("Transport attribute = %s: total # of spots (type=%d) at destination = %d.", asset.attribute, termtype, np_destination))

        -- No parking at requesting warehouse.
        if np_destination == 0 then
          self:E(string.format("ERROR: Incorrect request. No parking spots of terminal type %d at requesting warehouse for transports. Available spots = %d!", termtype, np_destination))
          valid=false
        end
      end

    end


  end

  -- Add request as unvalid and delete it later.
  if valid==false then
    self:E(self.lid..string.format("ERROR: Got invalid request id=%d.", request.uid))
  else
    self:T3(self.lid..string.format("Request id=%d valid :)", request.uid))
  end

  return valid
end


--- Checks if the request can be fulfilled right now.
-- Check for current parking situation, number of assets and transports currently in stock.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Queueitem request The request to be checked.
-- @return #boolean If true, request can be executed. If false, something is not right.
function WAREHOUSE:_CheckRequestNow(request)

  -- Check if receiving warehouse is running. We do allow self requests if the warehouse is under attack though!
  if (request.warehouse:IsRunning()==false) and not (request.toself and self:IsAttacked()) then
    local text=string.format("Warehouse %s: Request denied! Receiving warehouse %s is not running. Current state %s.", self.alias, request.warehouse.alias, request.warehouse:GetState())
    self:_InfoMessage(text, 5)

    return false
  end

  -- If no transport is requested, assets need to be mobile unless it is a self request.
  local onlymobile=false
  if type(request.ntransport)=="number" and request.ntransport==0 and not request.toself then
    onlymobile=true
  end

  -- Check if number of requested assets is in stock.
  local _assets,_nassets,_enough=self:_FilterStock(self.stock, request.assetdesc, request.assetdescval, request.nasset, onlymobile)


  -- Check if enough assets are in stock.
  if not _enough then
    local text=string.format("Warehouse %s: Request ID=%d denied! Not enough (cargo) assets currently available.", self.alias, request.uid)
    self:_InfoMessage(text, 5)
    text=string.format("Enough=%s, #assets=%d, nassets=%d, request.nasset=%s", tostring(_enough), #_assets,_nassets, tostring(request.nasset))
    self:T(self.lid..text)
    return false
  end

  local _transports
  local _assetattribute
  local _assetcategory
  local _assetairstart=false

  -- Check if at least one (cargo) asset is available.
  if _nassets>0 then
  
    local asset=_assets[1] --#WAREHOUSE.Assetitem

    -- Get the attibute of the requested asset.
    _assetattribute=_assets[1].attribute
    _assetcategory=_assets[1].category
    _assetairstart=_assets[1].takeoffType and _assets[1].takeoffType==COORDINATE.WaypointType.TurningPoint or false

    -- Check available parking for air asset units.
    if _assetcategory==Group.Category.AIRPLANE or _assetcategory==Group.Category.HELICOPTER then
    
      if self.airbase and self.airbase:GetCoalition()==self:GetCoalition() then
      
        -- Check if DCS warehouse of airbase has enough assets        
        if self.airbase.storage then
          local nS=self.airbase.storage:GetAmount(asset.unittype)
          local nA=asset.nunits*request.nasset  -- Number of units requested
          if nS<nA then
            local text=string.format("Warehouse %s: Request denied! DCS Warehouse has only %d assets of type %s ==> NOT enough to spawn the requested %d asset units (%d groups)", 
            self.alias, nS, asset.unittype, nA, request.nasset)
            self:_InfoMessage(text, 5)            
            return false
          end
        end
        
    
        if self:IsRunwayOperational() or _assetairstart then
  
          if _assetairstart then
            -- Airstart no need to check parking
          else
          
            -- Check parking.
            local Parking=self:_FindParkingForAssets(self.airbase,_assets)
      
            -- No parking?
            if Parking==nil then
              local text=string.format("Warehouse %s: Request denied! Not enough free parking spots for all requested assets at the moment.", self.alias)
              self:_InfoMessage(text, 5)
              return false
            end
          end
          
        else
          -- Runway destroyed.
          local text=string.format("Warehouse %s: Request denied! Runway is still destroyed", self.alias)
          self:_InfoMessage(text, 5)
          return false                
        end
        
      else
      
        -- No airbase!
        local text=string.format("Warehouse %s: Request denied! No airbase", self.alias)
        self:_InfoMessage(text, 5)
        return false                
      
      end

    end

    -- Add this here or gettransport fails
    request.cargoassets=_assets

  end

  -- Check that a transport units.
  if request.transporttype ~= WAREHOUSE.TransportType.SELFPROPELLED then

    -- Get best transports for this asset pack.
    _transports=self:_GetTransportsForAssets(request)

    -- Check if at least one transport asset is available.
    if #_transports>0 then

      -- Get the attibute of the transport units.
      local _transportattribute=_transports[1].attribute
      local _transportcategory=_transports[1].category

      -- Check available parking for transport units.
      if _transportcategory==Group.Category.AIRPLANE or _transportcategory==Group.Category.HELICOPTER then
      
        if self.airbase and self.airbase:GetCoalition()==self:GetCoalition() then
        
          if self:IsRunwayOperational() then        
      
            local Parking=self:_FindParkingForAssets(self.airbase,_transports)
            
            -- No parking ==> return false
            if Parking==nil then           
              local text=string.format("Warehouse %s: Request denied! Not enough free parking spots for all transports at the moment.", self.alias)
              self:_InfoMessage(text, 5)  
              return false
            end
            
          else
          
             -- Runway destroyed.
            local text=string.format("Warehouse %s: Request denied! Runway is still destroyed", self.alias)
            self:_InfoMessage(text, 5)
            return false
                                     
          end
          
        else
          -- No airbase
          local text=string.format("Warehouse %s: Request denied! No airbase currently!", self.alias)
          self:_InfoMessage(text, 5)  
          return false        
        end
          
      end

    else

      -- Not enough or the right transport carriers.
      local text=string.format("Warehouse %s: Request denied! Not enough transport carriers available at the moment.", self.alias)
      self:_InfoMessage(text, 5)

      return false
    end

  else

    ---
    -- Self propelled case
    ---

    -- Ground asset checks.
    if _assetcategory==Group.Category.GROUND then

      -- Distance between warehouse and spawn zone.
      local dist=self.warehouse:GetCoordinate():Get2DDistance(self.spawnzone:GetCoordinate())

      -- Check min dist to spawn zone.
      if dist>self.spawnzonemaxdist then
        -- Not close enough to spawn zone.
        local text=string.format("Warehouse %s: Request denied! Not close enough to spawn zone. Distance = %d m. We need to be at least within %d m range to spawn.", self.alias, dist, self.spawnzonemaxdist)
        self:_InfoMessage(text, 5)
        return false
      end
      
    elseif _assetcategory==Group.Category.AIRPLANE or _assetcategory==Group.Category.HELICOPTER then


    end

  end


  -- Set chosen cargo assets.
  request.cargoassets=_assets
  request.cargoattribute=_assets[1].attribute
  request.cargocategory=_assets[1].category
  request.nasset=#_assets

  -- Debug info:
  local text=string.format("Selected cargo assets, attibute=%s, category=%d:\n", request.cargoattribute, request.cargocategory)
  for _i,_asset in pairs(_assets) do
    local asset=_asset --#WAREHOUSE.Assetitem
    text=text..string.format("%d) name=%s, type=%s, category=%d, #units=%d",_i, asset.templatename, asset.unittype, asset.category, asset.nunits)
  end
  self:T(self.lid..text)

  if request.transporttype ~= WAREHOUSE.TransportType.SELFPROPELLED then

    -- Set chosen transport assets.
    request.transportassets=_transports
    request.transportattribute=_transports[1].attribute
    request.transportcategory=_transports[1].category
    request.ntransport=#_transports

    -- Debug info:
    local text=string.format("Selected transport assets, attibute=%s, category=%d:\n", request.transportattribute, request.transportcategory)
    for _i,_asset in pairs(_transports) do
      local asset=_asset --#WAREHOUSE.Assetitem
      text=text..string.format("%d) name=%s, type=%s, category=%d, #units=%d\n",_i, asset.templatename, asset.unittype, asset.category, asset.nunits)
    end
    self:T(self.lid..text)

  end

  return true
end

---Get (optimized) transport carriers for the given assets to be transported.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Pendingitem Chosen request.
function WAREHOUSE:_GetTransportsForAssets(request)

  -- Get all transports of the requested type in stock.
  local transports=self:_FilterStock(self.stock, WAREHOUSE.Descriptor.ATTRIBUTE, request.transporttype, nil, true)

  -- Copy asset.
  local cargoassets=UTILS.DeepCopy(request.cargoassets)
  local cargoset=request.transportcargoset

  -- TODO: Get weight and cargo bay from CARGO_GROUP
  --local cargogroup=CARGO_GROUP:New(CargoGroup,Type,Name,LoadRadius,NearRadius)
  --cargogroup:GetWeight()

  -- Sort transport carriers w.r.t. cargo bay size.
  local function sort_transports(a,b)
    return a.cargobaymax>b.cargobaymax
  end

  -- Sort cargo assets w.r.t. weight in assending order.
  local function sort_cargoassets(a,b)
    return a.weight>b.weight
  end

  -- Sort tables.
  table.sort(transports, sort_transports)
  table.sort(cargoassets, sort_cargoassets)

  -- Total cargo bay size of all groups.
  self:T2(self.lid.."Transport capability:")
  local totalbay=0
  for i=1,#transports do
    local transport=transports[i] --#WAREHOUSE.Assetitem
    for j=1,transport.nunits do
      totalbay=totalbay+transport.cargobay[j]
      self:T2(self.lid..string.format("Cargo bay = %d  (unit=%d)", transport.cargobay[j], j))
    end
  end
  self:T2(self.lid..string.format("Total capacity = %d", totalbay))

  -- Total cargo weight of all assets to transports.
  self:T2(self.lid.."Cargo weight:")
  local totalcargoweight=0
  for i=1,#cargoassets do
    local asset=cargoassets[i] --#WAREHOUSE.Assetitem
    totalcargoweight=totalcargoweight+asset.weight
    self:T2(self.lid..string.format("weight = %d", asset.weight))
  end
  self:T2(self.lid..string.format("Total weight = %d", totalcargoweight))

  -- Transports used.
  local used_transports={}

  -- Loop over all transport groups, largest cargobaymax to smallest.
  for i=1,#transports do

    -- Shortcut for carrier and cargo bay
    local transport=transports[i]

    -- Cargo put into carrier.
    local putintocarrier={}

    -- Cargo assigned to this transport group?
    local used=false

    -- Loop over all units
    for k=1,transport.nunits do

      -- Get cargo bay of this carrier.
      local cargobay=transport.cargobay[k]

      -- Loop over cargo assets.
      for j,asset in pairs(cargoassets) do
        local asset=asset --#WAREHOUSE.Assetitem

        -- How many times does the cargo fit into the carrier?
        local delta=cargobay-asset.weight
        --env.info(string.format("k=%d, j=%d delta=%d  cargobay=%d  weight=%d", k, j, delta, cargobay, asset.weight))

        --self:E(self.lid..string.format("%s unit %d loads cargo uid=%d: bayempty=%02d, bayloaded = %02d - weight=%02d", transport.templatename, k, asset.uid, transport.cargobay[k], cargobay, asset.weight))

        -- Cargo fits into carrier
        if delta>=0 then
          -- Reduce remaining cargobay.
          cargobay=cargobay-asset.weight
          self:T3(self.lid..string.format("%s unit %d loads cargo uid=%d: bayempty=%02d, bayloaded = %02d - weight=%02d", transport.templatename, k, asset.uid, transport.cargobay[k], cargobay, asset.weight))

          -- Remember this cargo and remove it so it does not get loaded into other carriers.
          table.insert(putintocarrier, j)

          -- This transport group is used.
          used=true
        else
          self:T2(self.lid..string.format("Carrier unit %s too small for cargo asset %s ==> cannot be used! Cargo bay - asset weight = %d kg", transport.templatename, asset.templatename, delta))
        end

      end -- loop over assets
    end   -- loop over units

    -- Remove cargo assets from list. Needs to be done back-to-front in order not to confuse the loop.
    for j=#putintocarrier,1, -1 do

      local nput=putintocarrier[j]
      local cargo=cargoassets[nput]

      -- Need to check if multiple units in a group and the group has already been removed!
      -- TODO: This might need to be improved but is working okay so far.
      if cargo then
        -- Remove this group because it was used.
        self:T2(self.lid..string.format("Cargo id=%d assigned for carrier id=%d", cargo.uid, transport.uid))
        table.remove(cargoassets, nput)
      end
    end

    -- Cargo was assined for this carrier.
    if used then
      table.insert(used_transports, transport)
    end

    -- Convert relative quantity (all, half) to absolute number if necessary.
    local ntrans=self:_QuantityRel2Abs(request.ntransport, #transports)

    -- Max number of transport groups reached?
    if #used_transports >= ntrans then
      request.ntransport=#used_transports
      break
    end
  end

  -- Debug info.
  local text=string.format("Used Transports for request %d to warehouse %s:\n", request.uid, request.warehouse.alias)
  local totalcargobay=0
  for _i,_transport in pairs(used_transports) do
    local transport=_transport --#WAREHOUSE.Assetitem
    text=text..string.format("%d) %s: cargobay tot = %d kg, cargobay max = %d kg, nunits=%d\n", _i, transport.unittype, transport.cargobaytot, transport.cargobaymax, transport.nunits)
    totalcargobay=totalcargobay+transport.cargobaytot
    --for _,cargobay in pairs(transport.cargobay) do
    --  env.info(string.format("cargobay %d", cargobay))
    --end
  end
  text=text..string.format("Total cargo bay capacity = %.1f kg\n", totalcargobay)
  text=text..string.format("Total cargo weight       = %.1f kg\n", totalcargoweight)
  text=text..string.format("Minimum number of runs   = %.1f", totalcargoweight/totalcargobay)
  self:_DebugMessage(text)

  return used_transports
end

---Relative to absolute quantity.
-- @param #WAREHOUSE self
-- @param #string relative Relative number in terms of @{#WAREHOUSE.Quantity}.
-- @param #number ntot Total number.
-- @return #number Absolute number.
function WAREHOUSE:_QuantityRel2Abs(relative, ntot)

  local nabs=0

  -- Handle string input for nmax.
  if type(relative)=="string" then
    if relative==WAREHOUSE.Quantity.ALL then
      nabs=ntot
    elseif relative==WAREHOUSE.Quantity.THREEQUARTERS then
      nabs=UTILS.Round(ntot*3/4)
    elseif relative==WAREHOUSE.Quantity.HALF then
      nabs=UTILS.Round(ntot/2)
    elseif relative==WAREHOUSE.Quantity.THIRD then
      nabs=UTILS.Round(ntot/3)
    elseif relative==WAREHOUSE.Quantity.QUARTER then
      nabs=UTILS.Round(ntot/4)
    else
      nabs=math.min(1, ntot)
    end
  else
    nabs=relative
  end

  self:T2(self.lid..string.format("Relative %s: tot=%d, abs=%.2f", tostring(relative), ntot, nabs))

  return nabs
end

---Sorts the queue and checks if the request can be fulfilled.
-- @param #WAREHOUSE self
-- @return #WAREHOUSE.Queueitem Chosen request.
function WAREHOUSE:_CheckQueue()

  -- Sort queue wrt to first prio and then qid.
  self:_SortQueue()

  -- Search for a request we can execute.
  local request=nil --#WAREHOUSE.Queueitem

  local invalid={}
  local gotit=false
  for _,_qitem in ipairs(self.queue) do
    local qitem=_qitem --#WAREHOUSE.Queueitem

    -- Check if request is valid in general.
    local valid=self:_CheckRequestValid(qitem)

    -- Check if request is possible now.
    local okay=false
    if valid then    
      okay=self:_CheckRequestNow(qitem)
    else
      -- Remember invalid request and delete later in order not to confuse the loop.
      table.insert(invalid, qitem)
    end

    -- Get the first valid request that can be executed now.
    if okay and valid and not gotit then
      request=qitem
      gotit=true
      break
    end
  end

  -- Delete invalid requests.
  for _,_request in pairs(invalid) do
    self:T(self.lid..string.format("Deleting invalid request id=%d.",_request.uid))
    self:_DeleteQueueItem(_request, self.queue)
  end

  -- Execute request.
  return request
end

--- Simple task function. Can be used to call a function which has the warehouse and the executing group as parameters.
-- @param #WAREHOUSE self
-- @param #string Function The name of the function to call passed as string.
-- @param Wrapper.Group#GROUP group The group which is meant.
function WAREHOUSE:_SimpleTaskFunction(Function, group)
  self:F2({Function})

  -- Name of the warehouse (static) object.
  local warehouse=self.warehouse:GetName()
  local groupname=group:GetName()

  -- Task script.
  local DCSScript = {}

  DCSScript[#DCSScript+1]   = string.format('local mygroup     = GROUP:FindByName(\"%s\") ', groupname)               -- The group that executes the task function. Very handy with the "...".
  if self.isUnit then
    DCSScript[#DCSScript+1] = string.format("local mywarehouse = UNIT:FindByName(\"%s\") ", warehouse)                -- The unit that holds the warehouse self object.
  else
    DCSScript[#DCSScript+1] = string.format("local mywarehouse = STATIC:FindByName(\"%s\") ", warehouse)              -- The static that holds the warehouse self object.
  end
  DCSScript[#DCSScript+1]   = string.format('local warehouse   = mywarehouse:GetState(mywarehouse, \"WAREHOUSE\") ')  -- Get the warehouse self object from the static.
  DCSScript[#DCSScript+1]   = string.format('%s(mygroup)', Function)                                                  -- Call the function, e.g. myfunction.(warehouse,mygroup)

  -- Create task.
  local DCSTask = CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))

  return DCSTask
end

--- Simple task function. Can be used to call a function which has the warehouse and the executing group as parameters.
-- @param #WAREHOUSE self
-- @param #string Function The name of the function to call passed as string.
-- @param Wrapper.Group#GROUP group The group which is meant.
-- @param #number n Waypoint passed.
-- @param #number N Final waypoint number.
function WAREHOUSE:_SimpleTaskFunctionWP(Function, group, n, N)
  self:F2({Function})

  -- Name of the warehouse (static) object.
  local warehouse=self.warehouse:GetName()
  local groupname=group:GetName()

  -- Task script.
  local DCSScript = {}

  DCSScript[#DCSScript+1]   = string.format('local mygroup     = GROUP:FindByName(\"%s\") ', groupname)               -- The group that executes the task function. Very handy with the "...".
  if self.isUnit then
    DCSScript[#DCSScript+1] = string.format("local mywarehouse = UNIT:FindByName(\"%s\") ", warehouse)                -- The unit that holds the warehouse self object.
  else
    DCSScript[#DCSScript+1] = string.format("local mywarehouse = STATIC:FindByName(\"%s\") ", warehouse)              -- The static that holds the warehouse self object.
  end
  DCSScript[#DCSScript+1]   = string.format('local warehouse   = mywarehouse:GetState(mywarehouse, \"WAREHOUSE\") ')  -- Get the warehouse self object from the static.
  DCSScript[#DCSScript+1]   = string.format('%s(mygroup, %d, %d)', Function, n ,N)                                    -- Call the function, e.g. myfunction.(warehouse,mygroup)

  -- Create task.
  local DCSTask = CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))

  return DCSTask
end

--- Get the proper terminal type based on generalized attribute of the group.
--@param #WAREHOUSE self
--@param #WAREHOUSE.Attribute _attribute Generlized attibute of unit.
--@param #number _category Airbase category.
--@return Wrapper.Airbase#AIRBASE.TerminalType Terminal type for this group.
function WAREHOUSE:_GetTerminal(_attribute, _category)

  -- Default terminal is "large".
  local _terminal=AIRBASE.TerminalType.OpenBig

  if _attribute==WAREHOUSE.Attribute.AIR_FIGHTER or _attribute==WAREHOUSE.Attribute.AIR_UAV then
    -- Fighter ==> small.
    _terminal=AIRBASE.TerminalType.FighterAircraft
  elseif _attribute==WAREHOUSE.Attribute.AIR_BOMBER or _attribute==WAREHOUSE.Attribute.AIR_TRANSPORTPLANE or _attribute==WAREHOUSE.Attribute.AIR_TANKER or _attribute==WAREHOUSE.Attribute.AIR_AWACS then
    -- Bigger aircraft.
    _terminal=AIRBASE.TerminalType.OpenBig
  elseif _attribute==WAREHOUSE.Attribute.AIR_TRANSPORTHELO or _attribute==WAREHOUSE.Attribute.AIR_ATTACKHELO then
    -- Helicopter.
    _terminal=AIRBASE.TerminalType.HelicopterUsable
  else
    --_terminal=AIRBASE.TerminalType.OpenMedOrBig
  end

  -- For ships, we allow medium spots for all fixed wing aircraft. There are smaller tankers and AWACS aircraft that can use a carrier.
  if _category==Airbase.Category.SHIP then
    if not (_attribute==WAREHOUSE.Attribute.AIR_TRANSPORTHELO or _attribute==WAREHOUSE.Attribute.AIR_ATTACKHELO) then
      _terminal=AIRBASE.TerminalType.OpenMedOrBig
    end
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
  local scanradius=25
  local scanunits=true
  local scanstatics=true
  local scanscenery=false
  local verysafe=false

  -- Function calculating the overlap of two (square) objects.
  local function _overlap(l1,l2,dist)
    local safedist=(l1/2+l2/2)*1.05  -- 5% safety margine added to safe distance!
    local safe = (dist > safedist)
    self:T3(string.format("l1=%.1f l2=%.1f s=%.1f d=%.1f ==> safe=%s", l1,l2,safedist,dist,tostring(safe)))
    return safe
  end

  -- Get client coordinates.
  local function _clients()
    local coords={}
    if not self.allowSpawnOnClientSpots then  
      local clients=_DATABASE.CLIENTS
      for clientname, client in pairs(clients) do
        local template=_DATABASE:GetGroupTemplateFromUnitName(clientname)
        if template then
          local units=template.units
          for i,unit in pairs(units) do
            local coord=COORDINATE:New(unit.x, unit.alt, unit.y)
            coords[unit.name]=coord
          end
        end
      end
    end
    return coords
  end

  -- Get parking spot data table. This contains all free and "non-free" spots.
  local parkingdata=airbase.parking --airbase:GetParkingSpotsTable()
  
  ---
  -- Find all obstacles
  ---

  -- List of obstacles.
  local obstacles={}
  
  -- Check all clients. Clients dont change so we can put that out of the loop.
  self.clientcoords=self.clientcoords or _clients()
  for clientname,_coord in pairs(self.clientcoords) do
    table.insert(obstacles, {coord=_coord, size=15, name=clientname, type="client"})
  end

  -- Loop over all parking spots and get the currently present obstacles.
  -- How long does this take on very large airbases, i.e. those with hundereds of parking spots? Seems to be okay!
  for _,parkingspot in pairs(parkingdata) do

    -- Coordinate of the parking spot.
    local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
    local _termid=parkingspot.TerminalID

    -- Scan a radius of 100 meters around the spot.
    local _,_,_,_units,_statics,_sceneries=_spot:ScanObjects(scanradius, scanunits, scanstatics, scanscenery)

    -- Check all units.
    for _,_unit in pairs(_units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local _coord=unit:GetVec3()
      local _size=self:_GetObjectSize(unit:GetDCSObject())
      local _name=unit:GetName()
      if unit and unit:IsAlive() then
        table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="unit"})
      end
    end

    -- Check all statics.
    for _,static in pairs(_statics) do
      local _coord=static:getPoint()
      --local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=static:getName()
      local _size=self:_GetObjectSize(static)
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="static"})
    end

    -- Check all scenery.
    for _,scenery in pairs(_sceneries) do
      local _coord=scenery:getPoint()
      --local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=scenery:getTypeName()
      local _size=self:_GetObjectSize(scenery)
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="scenery"})
    end

  end
  
  ---
  -- Get Parking Spots
  ---

  -- Parking data for all assets.
  local parking={}

  -- Loop over all assets that need a parking psot.
  for _,asset in pairs(assets) do
    local _asset=asset --#WAREHOUSE.Assetitem
    
    if not _asset.spawned then

      -- Get terminal type of this asset
      local terminaltype=asset.terminalType or self:_GetTerminal(asset.attribute, self:GetAirbaseCategory())
  
      -- Asset specific parking.
      parking[_asset.uid]={}
  
      -- Loop over all units - each one needs a spot.
      for i=1,_asset.nunits do
      
        -- Asset name
        local assetname=_asset.spawngroupname.."-"..tostring(i)
  
        -- Loop over all parking spots.
        local gotit=false
        for _,_parkingspot in pairs(parkingdata) do
          local parkingspot=_parkingspot --Wrapper.Airbase#AIRBASE.ParkingSpot
          
          -- Parking valid?
          local valid=true
          
          if asset.parkingIDs then
            -- If asset has assigned parking spots, we take these no matter what.
            valid=self:_CheckParkingAsset(parkingspot, asset)
          else
  
            -- Valid terminal type depending on attribute.
            local validTerminal=AIRBASE._CheckTerminalType(parkingspot.TerminalType, terminaltype)
            
            -- Valid parking list.
            local validParking=self:_CheckParkingValid(parkingspot)
            
            -- Black and white list.
            local validBWlist=airbase:_CheckParkingLists(parkingspot.TerminalID)        
  
            -- Debug info.
            --env.info(string.format("FF validTerminal = %s", tostring(validTerminal)))
            --env.info(string.format("FF validParking  = %s", tostring(validParking)))
            --env.info(string.format("FF validBWlist   = %s", tostring(validBWlist)))
          
            -- Check if all are true
            valid=validTerminal and validParking and validBWlist
          end
          
  
          -- Check correct terminal type for asset. We don't want helos in shelters etc.
          if valid then
  
            -- Coordinate of the parking spot.
            local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
            local _termid=parkingspot.TerminalID
            local free=true
            local problem=nil
  
            -- Loop over all obstacles.
            for _,obstacle in pairs(obstacles) do
  
              -- Check if aircraft overlaps with any obstacle.
              local dist=_spot:Get2DDistance(obstacle.coord)
              local safe=_overlap(_asset.size, obstacle.size, dist)
  
              -- Spot is blocked.
              if not safe then
                self:T3(self.lid..string.format("FF asset=%s (id=%d): spot id=%d dist=%.1fm is NOT SAFE", assetname, _asset.uid, _termid, dist))
                free=false
                problem=obstacle
                problem.dist=dist
                break
              else
                --env.info(string.format("FF asset=%s (id=%d): spot id=%d dist=%.1fm is SAFE", assetname, _asset.uid, _termid, dist))
              end
  
            end
  
            -- Check if spot is free
            if free then
  
              -- Add parkingspot for this asset unit.
              table.insert(parking[_asset.uid], parkingspot)
  
              -- Debug
              self:T(self.lid..string.format("Parking spot %d is free for asset %s [id=%d]!", _termid, assetname, _asset.uid))
  
              -- Add the unit as obstacle so that this spot will not be available for the next unit.
              table.insert(obstacles, {coord=_spot, size=_asset.size, name=assetname, type="asset"})
  
              gotit=true
              break
  
            else
  
              -- Debug output for occupied spots.            
              if self.Debug then
                local coord=problem.coord --Core.Point#COORDINATE
                if coord then
                    local text=string.format("Obstacle %s [type=%s] blocking spot=%d! Size=%.1f m and distance=%.1f m.", problem.name, problem.type, _termid, problem.size, problem.dist)
                    self:I(self.lid..text)
                    coord:MarkToAll(text)
                end
              else
                self:T(self.lid..string.format("Parking spot %d is occupied or not big enough!", _termid))
              end
  
            end
  
          else
            self:T2(self.lid..string.format("Terminal ID=%d: type=%s not supported", parkingspot.TerminalID, parkingspot.TerminalType))
          end -- check terminal type
        end -- loop over parking spots
  
        -- No parking spot for at least one asset :(
        if not gotit then
          self:I(self.lid..string.format("WARNING: No free parking spot for asset %s [id=%d]", assetname, _asset.uid))
          return nil
        end
      end -- loop over asset units
    end -- Asset spawned check
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

--- Is the group a used as transporter for a given request?
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which the info is gathered.
-- @param #WAREHOUSE.Pendingitem request Request.
-- @return #boolean True if group is transport, false if group is cargo and nil otherwise.
function WAREHOUSE:_GroupIsTransport(group, request)

  local asset=self:FindAssetInDB(group)

  if asset and asset.iscargo~=nil then
    return not asset.iscargo
  else

    -- Name of the group under question.
    local groupname=self:_GetNameWithOut(group)

    if request.transportgroupset then
      local transporters=request.transportgroupset:GetSetObjects()

      for _,transport in pairs(transporters) do
        if transport:GetName()==groupname then
          return true
        end
      end
    end

    if request.cargogroupset then
      local cargos=request.cargogroupset:GetSetObjects()

      for _,cargo in pairs(cargos) do
        if self:_GetNameWithOut(cargo)==groupname then
          return false
        end
      end
    end
  end

  return nil
end


--- Get group name without any spawn or cargo suffix #CARGO etc.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which the info is gathered.
-- @return #string Name of the object without trailing #...
function WAREHOUSE:_GetNameWithOut(group)

  local groupname=type(group)=="string" and group or group:GetName()

  if groupname:find("CARGO") then
    local name=groupname:gsub("#CARGO", "")
    return name
  else
    return groupname
  end

end


--- Get warehouse id, asset id and request id from group name (alias).
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group The group from which the info is gathered.
-- @return #number Warehouse ID.
-- @return #number Asset ID.
-- @return #number Request ID.
function WAREHOUSE:_GetIDsFromGroup(group)

  if group then
  
    -- Group name
    local groupname=group:GetName()
    
    local wid, aid, rid=self:_GetIDsFromGroupName(groupname)

    return wid,aid,rid
  else
    self:E("WARNING: Group not found in GetIDsFromGroup() function!")
  end

end

--- Get warehouse id, asset id and request id from group name (alias).
-- @param #WAREHOUSE self
-- @param #string groupname Name of the group from which the info is gathered.
-- @return #number Warehouse ID.
-- @return #number Asset ID.
-- @return #number Request ID.
function WAREHOUSE:_GetIDsFromGroupName(groupname)

  -- @param #string text The text to analyse.
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


  -- Get asset id from group name.
  local wid,aid,rid=analyse(groupname)

  -- Get Asset.
  local asset=self:GetAssetByID(aid)

  -- Get warehouse and request id from asset table.
  if asset then
    wid=asset.wid
    rid=asset.rid
  end

  -- Debug info
  self:T3(self.lid..string.format("Group Name   = %s", tostring(groupname)))
  self:T3(self.lid..string.format("Warehouse ID = %s", tostring(wid)))
  self:T3(self.lid..string.format("Asset     ID = %s", tostring(aid)))
  self:T3(self.lid..string.format("Request   ID = %s", tostring(rid)))

  return wid,aid,rid
end

--- Filter stock assets by descriptor and attribute.
-- @param #WAREHOUSE self
-- @param #string descriptor Descriptor describing the filtered assets.
-- @param attribute Value of the descriptor.
-- @param #number nmax (Optional) Maximum number of items that will be returned. Default nmax=nil is all matching items are returned.
-- @param #boolean mobile (Optional) If true, filter only mobile assets.
-- @return #table Filtered assets in stock with the specified descriptor value.
-- @return #number Total number of (requested) assets available.
-- @return #boolean If true, enough assets are available.
function WAREHOUSE:FilterStock(descriptor, attribute, nmax, mobile)
  return self:_FilterStock(self.stock, descriptor, attribute, nmax, mobile)
end

--- Filter stock assets by table entry.
-- @param #WAREHOUSE self
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Assetitem}.
-- @param #string descriptor Descriptor describing the filtered assets.
-- @param attribute Value of the descriptor.
-- @param #number nmax (Optional) Maximum number of items that will be returned. Default nmax=nil is all matching items are returned.
-- @param #boolean mobile (Optional) If true, filter only mobile assets.
-- @return #table Filtered stock items table.
-- @return #number Total number of (requested) assets available.
-- @return #boolean If true, enough assets are available.
function WAREHOUSE:_FilterStock(stock, descriptor, attribute, nmax, mobile)

  -- Default all.
  nmax=nmax or WAREHOUSE.Quantity.ALL
  if mobile==nil then
    mobile=false
  end

  -- Filtered array.
  local filtered={}

  -- A specific list of assets was required.
  if descriptor==WAREHOUSE.Descriptor.ASSETLIST then

    -- Count total number in stock.
    local ntot=0
    for _,_rasset in pairs(attribute) do
      local rasset=_rasset --#WAREHOUSE.Assetitem
      for _,_asset in ipairs(stock) do
        local asset=_asset --#WAREHOUSE.Assetitem
        if rasset.uid==asset.uid then
          table.insert(filtered, asset)
          break
        end
      end
    end

    return filtered, #filtered, #filtered>=#attribute
  end

  -- Count total number in stock.
  local ntot=0
  for _,_asset in ipairs(stock) do
    local asset=_asset --#WAREHOUSE.Assetitem
    local ismobile=asset.speedmax>0
    if asset[descriptor]==attribute then
      if (mobile==true and ismobile) or mobile==false then
        ntot=ntot+1
      end
    end
  end

  -- Treat case where ntot=0, i.e. no assets at all.
  if ntot==0 then
    return filtered, ntot, false
  end

  -- Convert relative to absolute number if necessary.
  nmax=self:_QuantityRel2Abs(nmax,ntot)

  -- Loop over stock items.
  for _i,_asset in ipairs(stock) do
    local asset=_asset --#WAREHOUSE.Assetitem

    -- Check if asset has the right attribute.
    if asset[descriptor]==attribute then

      -- Check if asset has to be mobile.
      if (mobile and asset.speedmax>0) or (not mobile) then

        -- Add asset to filtered table.
        table.insert(filtered, asset)

        -- Break loop if nmax was reached.
        if nmax~=nil and #filtered>=nmax then
          return filtered, ntot, true
        end

      end
    end
  end

  return filtered, ntot, ntot>=nmax
end

--- Check if a group has a generalized attribute.
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group MOOSE group object.
-- @param #WAREHOUSE.Attribute attribute Attribute to check.
-- @return #boolean True if group has the specified attribute.
function WAREHOUSE:_HasAttribute(group, attribute)

  if group then
    local groupattribute=self:_GetAttribute(group)
    return groupattribute==attribute
  end

  return false
end

--- Get the generalized attribute of a group.
-- Note that for a heterogenious group, the attribute is determined from the attribute of the first unit!
-- @param #WAREHOUSE self
-- @param Wrapper.Group#GROUP group MOOSE group object.
-- @return #WAREHOUSE.Attribute Generalized attribute of the group.
function WAREHOUSE:_GetAttribute(group)

  -- Default
  local attribute=WAREHOUSE.Attribute.OTHER_UNKNOWN --#WAREHOUSE.Attribute

  if group then
  
    local groupCat=group:GetCategory()

    -----------
    --- Air ---
    -----------
    -- Planes
    local transportplane=group:HasAttribute("Transports") and group:HasAttribute("Planes") and groupCat==Group.Category.AIRPLANE
    local awacs=group:HasAttribute("AWACS")
    local fighter=group:HasAttribute("Fighters") or group:HasAttribute("Interceptors") or group:HasAttribute("Multirole fighters") or (group:HasAttribute("Bombers") and not group:HasAttribute("Strategic bombers"))
    local bomber=group:HasAttribute("Strategic bombers")
    local tanker=group:HasAttribute("Tankers")
    local uav=group:HasAttribute("UAVs")
    -- Helicopters
    local transporthelo=group:HasAttribute("Transport helicopters")
    local attackhelicopter=group:HasAttribute("Attack helicopters")

    --------------
    --- Ground ---
    --------------
    -- Ground
    local apc=group:HasAttribute("APC") --("Infantry carriers")
    local truck=group:HasAttribute("Trucks") and group:GetCategory()==Group.Category.GROUND
    local infantry=group:HasAttribute("Infantry")
    local ifv=group:HasAttribute("IFV")
    local artillery=group:HasAttribute("Artillery")
    local tank=group:HasAttribute("Old Tanks") or group:HasAttribute("Modern Tanks")
    local aaa=group:HasAttribute("AAA")
    local ewr=group:HasAttribute("EWR")
    local sam=group:HasAttribute("SAM elements") and (not group:HasAttribute("AAA"))
    -- Train
    local train=group:GetCategory()==Group.Category.TRAIN

    -------------
    --- Naval ---
    -------------
    -- Ships
    local aircraftcarrier=group:HasAttribute("Aircraft Carriers")
    local warship=group:HasAttribute("Heavy armed ships")
    local armedship=group:HasAttribute("Armed ships") or group:HasAttribute("Armed Ship")
    local unarmedship=group:HasAttribute("Unarmed ships")

    -- Define attribute. Order is important.
    if transportplane then
      attribute=WAREHOUSE.Attribute.AIR_TRANSPORTPLANE
    elseif awacs then
      attribute=WAREHOUSE.Attribute.AIR_AWACS
    elseif fighter then
      attribute=WAREHOUSE.Attribute.AIR_FIGHTER
    elseif bomber then
      attribute=WAREHOUSE.Attribute.AIR_BOMBER
    elseif tanker then
      attribute=WAREHOUSE.Attribute.AIR_TANKER
    elseif transporthelo then
      attribute=WAREHOUSE.Attribute.AIR_TRANSPORTHELO
    elseif attackhelicopter then
      attribute=WAREHOUSE.Attribute.AIR_ATTACKHELO
    elseif uav then
      attribute=WAREHOUSE.Attribute.AIR_UAV
    elseif apc then
      attribute=WAREHOUSE.Attribute.GROUND_APC
    elseif ifv then
      attribute=WAREHOUSE.Attribute.GROUND_IFV
    elseif infantry then
      attribute=WAREHOUSE.Attribute.GROUND_INFANTRY
    elseif artillery then
      attribute=WAREHOUSE.Attribute.GROUND_ARTILLERY
    elseif tank then
      attribute=WAREHOUSE.Attribute.GROUND_TANK
    elseif aaa then
      attribute=WAREHOUSE.Attribute.GROUND_AAA
    elseif ewr then
      attribute=WAREHOUSE.Attribute.GROUND_EWR
    elseif sam then
      attribute=WAREHOUSE.Attribute.GROUND_SAM
    elseif truck then
      attribute=WAREHOUSE.Attribute.GROUND_TRUCK
    elseif train then
      attribute=WAREHOUSE.Attribute.GROUND_TRAIN
    elseif aircraftcarrier then
      attribute=WAREHOUSE.Attribute.NAVAL_AIRCRAFTCARRIER
    elseif warship then
      attribute=WAREHOUSE.Attribute.NAVAL_WARSHIP
    elseif armedship then
      attribute=WAREHOUSE.Attribute.NAVAL_ARMEDSHIP
    elseif unarmedship then
      attribute=WAREHOUSE.Attribute.NAVAL_UNARMEDSHIP
    else
      if group:IsGround() then
        attribute=WAREHOUSE.Attribute.GROUND_OTHER
      elseif group:IsShip() then
        attribute=WAREHOUSE.Attribute.NAVAL_OTHER
      elseif group:IsAir() then
        attribute=WAREHOUSE.Attribute.AIR_OTHER
      else
        attribute=WAREHOUSE.Attribute.OTHER_UNKNOWN
      end
    end
  end

  return attribute
end

--- Size of the bounding box of a DCS object derived from the DCS descriptor table. If boundinb box is nil, a size of zero is returned.
-- @param #WAREHOUSE self
-- @param DCS#Object DCSobject The DCS object for which the size is needed.
-- @return #number Max size of object in meters (length (x) or width (z) components not including height (y)).
-- @return #number Length (x component) of size.
-- @return #number Height (y component) of size.
-- @return #number Width (z component) of size.
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
-- @return #table Data table holding the numbers, i.e. data[attibute]=n.
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

  for i=1,#queue do
    local _item=queue[i] --#WAREHOUSE.Queueitem
    if _item.uid==qitem.uid then
      self:T(self.lid..string.format("Deleting queue item id=%d.", qitem.uid))
      table.remove(queue,i)
      break
    end
  end
end

--- Delete item from queue.
-- @param #WAREHOUSE self
-- @param #number qitemID ID of queue item to be removed.
-- @param #table queue The queue from which the item should be deleted.
function WAREHOUSE:_DeleteQueueItemByID(qitemID, queue)

  for i=1,#queue do
    local _item=queue[i] --#WAREHOUSE.Queueitem
    if _item.uid==qitemID then
      self:T(self.lid..string.format("Deleting queue item id=%d.", qitemID))
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

--- Checks fuel on all pening assets.
-- @param #WAREHOUSE self
function WAREHOUSE:_CheckFuel()

  for i,qitem in ipairs(self.pending) do
    local qitem=qitem --#WAREHOUSE.Pendingitem

    if qitem.transportgroupset then
      for _,_group in pairs(qitem.transportgroupset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP

        if group and group:IsAlive() then

          -- Get min fuel of group.
          local fuel=group:GetFuelMin()

          -- Debug info.
          self:T2(self.lid..string.format("Transport group %s min fuel state = %.2f", group:GetName(), fuel))

          -- Check if fuel is below threshold for first time.
          if fuel<self.lowfuelthresh and not qitem.lowfuel then

            -- Set low fuel flag.
            self:I(self.lid..string.format("Transport group %s is low on fuel! Min fuel state = %.2f", group:GetName(), fuel))
            qitem.lowfuel=true

            -- Trigger low fuel event.
            local asset=self:FindAssetInDB(group)
            self:AssetLowFuel(asset, qitem)
            break
          end

        end
      end
    end

    if qitem.cargogroupset then
      for _,_group in pairs(qitem.cargogroupset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP

        if group and group:IsAlive() then

          -- Get min fuel of group.
          local fuel=group:GetFuelMin()

          -- Debug output.
          self:T2(self.lid..string.format("Cargo group %s min fuel state = %.2f. Threshold = %.2f", group:GetName(), fuel, self.lowfuelthresh))

          -- Check if fuel is below threshold for first time.
          if fuel<self.lowfuelthresh and not qitem.lowfuel then

            -- Set low fuel flag.
            self:I(self.lid..string.format("Cargo group %s is low on fuel! Min fuel state = %.2f", group:GetName(), fuel))
            qitem.lowfuel=true

            -- Trigger low fuel event.
            local asset=self:FindAssetInDB(group)
            self:AssetLowFuel(asset, qitem)
            break
          end

        end
      end
    end

  end
end


--- Prints the queue to DCS.log file.
-- @param #WAREHOUSE self
-- @param #table queue Queue to print.
-- @param #string name Name of the queue for info reasons.
function WAREHOUSE:_PrintQueue(queue, name)

  if self.verbosity>=2 then

    local total="Empty"
    if #queue>0 then
      total=string.format("Total = %d", #queue)
    end
  
    -- Init string.
    local text=string.format("%s at %s: %s",name, self.alias, total)
  
    for i,qitem in ipairs(queue) do
      local qitem=qitem --#WAREHOUSE.Pendingitem
  
      local uid=qitem.uid
      local prio=qitem.prio
      local clock="N/A"
      if qitem.timestamp then
        clock=tostring(UTILS.SecondsToClock(qitem.timestamp))
      end
      local assignment=tostring(qitem.assignment)
      local requestor=qitem.warehouse.alias
      local airbasename=qitem.warehouse:GetAirbaseName()
      local requestorAirbaseCat=qitem.warehouse:GetAirbaseCategory()
      local assetdesc=qitem.assetdesc
      local assetdescval=qitem.assetdescval
      if assetdesc==WAREHOUSE.Descriptor.ASSETLIST then
        assetdescval="Asset list"
      end
      local nasset=tostring(qitem.nasset)
      local ndelivered=tostring(qitem.ndelivered)
      local ncargogroupset="N/A"
      if qitem.cargogroupset then
        ncargogroupset=tostring(qitem.cargogroupset:Count())
      end
      local transporttype="N/A"
      if qitem.transporttype then
        transporttype=qitem.transporttype
      end
      local ntransport="N/A"
      if qitem.ntransport then
        ntransport=tostring(qitem.ntransport)
      end
      local ntransportalive="N/A"
      if qitem.transportgroupset then
        ntransportalive=tostring(qitem.transportgroupset:Count())
      end
      local ntransporthome="N/A"
      if qitem.ntransporthome then
        ntransporthome=tostring(qitem.ntransporthome)
      end
  
      -- Output text:
      text=text..string.format(
      "\n%d) UID=%d, Prio=%d, Clock=%s, Assignment=%s | Requestor=%s [Airbase=%s, category=%d] | Assets(%s)=%s: #requested=%s / #alive=%s / #delivered=%s | Transport=%s: #requested=%s / #alive=%s / #home=%s",
      i, uid, prio, clock, assignment, requestor, airbasename, requestorAirbaseCat, assetdesc, assetdescval, nasset, ncargogroupset, ndelivered, transporttype, ntransport, ntransportalive, ntransporthome)
  
    end
  
    if #queue==0 then
      self:I(self.lid..text)
    else
      if total~="Empty" then
        self:I(self.lid..text)
      end
    end
  end
end

--- Display status of warehouse.
-- @param #WAREHOUSE self
function WAREHOUSE:_DisplayStatus()
  if self.verbosity>=3 then
    local text=string.format("\n------------------------------------------------------\n")
    text=text..string.format("Warehouse %s status: %s\n", self.alias, self:GetState())
    text=text..string.format("------------------------------------------------------\n")
    text=text..string.format("Coalition name   = %s\n", self:GetCoalitionName())
    text=text..string.format("Country name     = %s\n", self:GetCountryName())
    text=text..string.format("Airbase name     = %s (category=%d)\n", self:GetAirbaseName(), self:GetAirbaseCategory())
    text=text..string.format("Queued requests  = %d\n", #self.queue)
    text=text..string.format("Pending requests = %d\n", #self.pending)
    text=text..string.format("------------------------------------------------------\n")
    text=text..self:_GetStockAssetsText()
    self:I(text)
  end
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
  local total=0
  for _attribute,_count in pairs(_data) do
    if _count>0 then
      local attribute=tostring(UTILS.Split(_attribute, "_")[2])
      text=text..string.format("%s = %d\n", attribute,_count)
      total=total+_count
    end
  end
  text=text..string.format("===================\n")
  text=text..string.format("Total = %d\n", total)
  text=text..string.format("------------------------------------------------------\n")

  -- Send message?
  MESSAGE:New(text, 10):ToAllIf(messagetoall)

  return text
end

--- Create or update mark text at warehouse, which is displayed in F10 map showing how many assets of each type are in stock.
-- Only the coalition of the warehouse owner is able to see it.
-- @param #WAREHOUSE self
-- @return #string Text about warehouse stock
function WAREHOUSE:_UpdateWarehouseMarkText()

  if self.markerOn then

    -- Marker text.
    local text=string.format("Warehouse state: %s\nTotal assets in stock %d:\n", self:GetState(), #self.stock)
    for _attribute,_count in pairs(self:GetStockInfo(self.stock) or {}) do
      if _count>0 then
        local attribute=tostring(UTILS.Split(_attribute, "_")[2])
        text=text..string.format("%s=%d, ", attribute,_count)
      end
    end
    
    local coordinate=self:GetCoordinate()
    local coalition=self:GetCoalition()

    if not self.markerWarehouse then
    
      -- Create a new marker.
      self.markerWarehouse=MARKER:New(coordinate, text):ToCoalition(coalition)
          
    else
  
      local refresh=false
    
      if self.markerWarehouse.text~=text then
        self.markerWarehouse.text=text
        refresh=true
      end
      
      if self.markerWarehouse.coordinate~=coordinate then
        self.markerWarehouse.coordinate=coordinate
        refresh=true
      end
      
      if self.markerWarehouse.coalition~=coalition then
        self.markerWarehouse.coalition=coalition
        refresh=true
      end
      
      if refresh then
        self.markerWarehouse:Refresh()
      end
  
    end
  end

end

--- Display stock items of warehouse.
-- @param #WAREHOUSE self
-- @param #table stock Table holding all assets in stock of the warehouse. Each entry is of type @{#WAREHOUSE.Assetitem}.
function WAREHOUSE:_DisplayStockItems(stock)

  local text=self.lid..string.format("Warehouse %s stock assets:", self.alias)
  for _i,_stock in pairs(stock) do
    local mystock=_stock --#WAREHOUSE.Assetitem
    local name=mystock.templatename
    local category=mystock.category
    local cargobaymax=mystock.cargobaymax
    local cargobaytot=mystock.cargobaytot
    local nunits=mystock.nunits
    local range=mystock.range
    local size=mystock.size
    local speed=mystock.speedmax
    local uid=mystock.uid
    local unittype=mystock.unittype
    local weight=mystock.weight
    local attribute=mystock.attribute
    text=text..string.format("\n%02d) uid=%d, name=%s, unittype=%s, category=%d, attribute=%s, nunits=%d, speed=%.1f km/h, range=%.1f km, size=%.1f m, weight=%.1f kg, cargobax max=%.1f kg tot=%.1f kg",
    _i, uid, name, unittype, category, attribute, nunits, speed, range/1000, size, weight, cargobaymax, cargobaytot)
  end

  self:T3(text)
end

--- Fireworks!
-- @param #WAREHOUSE self
-- @param Core.Point#COORDINATE coord
function WAREHOUSE:_Fireworks(coord)

  -- Place.
  coord=coord or self:GetCoordinate()

  -- Fireworks!
  for i=1,91 do
    local color=math.random(0,3)
    coord:Flare(color, i-1)
  end
end

--- Info Message. Message send to coalition if reports or debug mode activated (and duration > 0). Text self:I(text) added to DCS.log file.
-- @param #WAREHOUSE self
-- @param #string text The text of the error message.
-- @param #number duration Message display duration in seconds. Default 20 sec. If duration is zero, no message is displayed.
function WAREHOUSE:_InfoMessage(text, duration)
  duration=duration or 20
  if duration>0 and self.Debug or self.Report then
    MESSAGE:New(text, duration):ToCoalition(self:GetCoalition())
  end
  self:I(self.lid..text)
end


--- Debug message. Message send to all if debug mode is activated (and duration > 0). Text self:T(text) added to DCS.log file.
-- @param #WAREHOUSE self
-- @param #string text The text of the error message.
-- @param #number duration Message display duration in seconds. Default 20 sec. If duration is zero, no message is displayed.
function WAREHOUSE:_DebugMessage(text, duration)
  duration=duration or 20
  if self.Debug and duration>0 then
    MESSAGE:New(text, duration):ToAllIf(self.Debug)
  end
  self:T(self.lid..text)
end

--- Error message. Message send to all (if duration > 0). Text self:E(text) added to DCS.log file.
-- @param #WAREHOUSE self
-- @param #string text The text of the error message.
-- @param #number duration Message display duration in seconds. Default 20 sec. If duration is zero, no message is displayed.
function WAREHOUSE:_ErrorMessage(text, duration)
  duration=duration or 20
  if duration>0 then
    MESSAGE:New(text, duration):ToAll()
  end
  self:E(self.lid..text)
end


--- Calculate the maximum height an aircraft can reach for the given parameters.
-- @param #WAREHOUSE self
-- @param #number D Total distance in meters from Departure to holding point at destination.
-- @param #number alphaC Climb angle in rad.
-- @param #number alphaD Descent angle in rad.
-- @param #number Hdep AGL altitude of departure point.
-- @param #number Hdest AGL altitude of destination point.
-- @param #number Deltahhold Relative altitude of holding point above destination.
-- @return #number Maximum height the aircraft can reach.
function WAREHOUSE:_GetMaxHeight(D, alphaC, alphaD, Hdep, Hdest, Deltahhold)

  local Hhold=Hdest+Deltahhold
  local hdest=Hdest-Hdep
  local hhold=hdest+Deltahhold

  local Dp=math.sqrt(D^2 + hhold^2)

  local alphaS=math.atan(hdest/D) -- slope angle
  local alphaH=math.atan(hhold/D) -- angle to holding point (could be necative!)

  local alphaCp=alphaC-alphaH  -- climb angle with slope
  local alphaDp=alphaD+alphaH  -- descent angle with slope

  -- ASA triangle.
  local gammap=math.pi-alphaCp-alphaDp
  local sCp=Dp*math.sin(alphaDp)/math.sin(gammap)
  local sDp=Dp*math.sin(alphaCp)/math.sin(gammap)

  -- Max height from departure.
  local hmax=sCp*math.sin(alphaC)

  -- Debug info.
  if self.Debug then
    env.info(string.format("Hdep    = %.3f km", Hdep/1000))
    env.info(string.format("Hdest   = %.3f km", Hdest/1000))
    env.info(string.format("DetaHold= %.3f km", Deltahhold/1000))
    env.info()
    env.info(string.format("D       = %.3f km", D/1000))
    env.info(string.format("Dp      = %.3f km", Dp/1000))
    env.info()
    env.info(string.format("alphaC  = %.3f Deg", math.deg(alphaC)))
    env.info(string.format("alphaCp = %.3f Deg", math.deg(alphaCp)))
    env.info()
    env.info(string.format("alphaD  = %.3f Deg", math.deg(alphaD)))
    env.info(string.format("alphaDp = %.3f Deg", math.deg(alphaDp)))
    env.info()
    env.info(string.format("alphaS  = %.3f Deg", math.deg(alphaS)))
    env.info(string.format("alphaH  = %.3f Deg", math.deg(alphaH)))
    env.info()
    env.info(string.format("sCp      = %.3f km", sCp/1000))
    env.info(string.format("sDp      = %.3f km", sDp/1000))
    env.info()
    env.info(string.format("hmax     = %.3f km", hmax/1000))
    env.info()

    -- Descent height
    local hdescent=hmax-hhold

    local dClimb   = hmax/math.tan(alphaC)
    local dDescent = (hmax-hhold)/math.tan(alphaD)
    local dCruise  = D-dClimb-dDescent

    env.info(string.format("hmax     = %.3f km", hmax/1000))
    env.info(string.format("hdescent = %.3f km", hdescent/1000))
    env.info(string.format("Dclimb   = %.3f km", dClimb/1000))
    env.info(string.format("Dcruise  = %.3f km", dCruise/1000))
    env.info(string.format("Ddescent = %.3f km", dDescent/1000))
    env.info()
  end

  return hmax
end


--- Make a flight plan from a departure to a destination airport.
-- @param #WAREHOUSE self
-- @param #WAREHOUSE.Assetitem asset
-- @param Wrapper.Airbase#AIRBASE departure Departure airbase.
-- @param Wrapper.Airbase#AIRBASE destination Destination airbase.
-- @return #table Table of flightplan waypoints.
-- @return #table Table of flightplan coordinates.
function WAREHOUSE:_GetFlightplan(asset, departure, destination)

  -- Parameters in SI units (m/s, m).
  local Vmax=asset.speedmax/3.6
  local Range=asset.range
  local category=asset.category
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
  --local AlphaClimb=math.asin(VyClimb/VxClimb)
  local AlphaClimb=math.rad(4)

  -- Descent angle in rad. Moderate 4 degrees.
  local AlphaDescent=math.rad(4)

  -- Expected cruise level (peak of Gaussian distribution)
  local FLcruise_expect=150*RAT.unit.FL2m
  if category==Group.Category.HELICOPTER then
    FLcruise_expect=1000 -- 1000 m ASL
  end

  -------------------------
  --- DEPARTURE AIRPORT ---
  -------------------------

  -- Coordinates of departure point.
  local Pdeparture=departure:GetCoordinate()

  -- Height ASL of departure point.
  local H_departure=Pdeparture.y

  ---------------------------
  --- DESTINATION AIRPORT ---
  ---------------------------

  -- Position of destination airport.
  local Pdestination=destination:GetCoordinate()

  -- Height ASL of destination airport/zone.
  local H_destination=Pdestination.y

  -----------------------------
  --- DESCENT/HOLDING POINT ---
  -----------------------------

  -- Get a random point between 5 and 10 km away from the destination.
  local Rhmin=5000
  local Rhmax=10000

  -- For helos we set a distance between 500 to 1000 m.
  if category==Group.Category.HELICOPTER then
    Rhmin=500
    Rhmax=1000
  end

  -- Coordinates of the holding point. y is the land height at that point.
  local Pholding=Pdestination:GetRandomCoordinateInRadius(Rhmax, Rhmin)

  -- Distance from holding point to final destination (not used).
  local d_holding=Pholding:Get2DDistance(Pdestination)

  -- AGL height of holding point.
  local H_holding=Pholding.y

  ---------------
  --- GENERAL ---
  ---------------

  -- We go directly to the holding point not the destination airport. From there, planes are guided by DCS to final approach.
  local heading=Pdeparture:HeadingTo(Pholding)
  local d_total=Pdeparture:Get2DDistance(Pholding)

  ------------------------------
  --- Holding Point Altitude ---
  ------------------------------

  -- Holding point altitude. For planes between 1600 and 2400 m AGL. For helos 160 to 240 m AGL.
  local h_holding=1200
  if category==Group.Category.HELICOPTER then
    h_holding=150
  end
  h_holding=UTILS.Randomize(h_holding, 0.2)

  -- Max holding altitude.
  local DeltaholdingMax=self:_GetMaxHeight(d_total, AlphaClimb, AlphaDescent, H_departure, H_holding, 0)

  if h_holding>DeltaholdingMax then
    h_holding=math.abs(DeltaholdingMax)
  end

  -- This is the height ASL of the holding point we want to fly to.
  local Hh_holding=H_holding+h_holding

  ---------------------------
  --- Max Flight Altitude ---
  ---------------------------

  -- Get max flight altitude relative to H_departure.
  local h_max=self:_GetMaxHeight(d_total, AlphaClimb, AlphaDescent, H_departure, H_holding, h_holding)

  -- Max flight level ASL aircraft can reach for given angles and distance.
  local FLmax = h_max+H_departure

  --CRUISE
  -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
  local FLmin=math.max(H_departure, Hh_holding)

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

  -- Get distances.
  local d_climb   = h_climb/math.tan(AlphaClimb)
  local d_descent = h_descent/math.tan(AlphaDescent)
  local d_cruise  = d_total-d_climb-d_descent

  -- Debug.
  local text=string.format("Flight plan:\n")
  text=text..string.format("Vx max        = %.2f km/h\n", Vmax*3.6)
  text=text..string.format("Vx climb      = %.2f km/h\n", VxClimb*3.6)
  text=text..string.format("Vx cruise     = %.2f km/h\n", VxCruise*3.6)
  text=text..string.format("Vx descent    = %.2f km/h\n", VxDescent*3.6)
  text=text..string.format("Vx holding    = %.2f km/h\n", VxHolding*3.6)
  text=text..string.format("Vx final      = %.2f km/h\n", VxFinal*3.6)
  text=text..string.format("Vy max        = %.2f m/s\n",  Vymax)
  text=text..string.format("Vy climb      = %.2f m/s\n",  VyClimb)
  text=text..string.format("Alpha Climb   = %.2f Deg\n",  math.deg(AlphaClimb))
  text=text..string.format("Alpha Descent = %.2f Deg\n",  math.deg(AlphaDescent))
  text=text..string.format("Dist climb    = %.3f km\n",   d_climb/1000)
  text=text..string.format("Dist cruise   = %.3f km\n",   d_cruise/1000)
  text=text..string.format("Dist descent  = %.3f km\n",   d_descent/1000)
  text=text..string.format("Dist total    = %.3f km\n",   d_total/1000)
  text=text..string.format("h_climb       = %.3f km\n",   h_climb/1000)
  text=text..string.format("h_desc        = %.3f km\n",   h_descent/1000)
  text=text..string.format("h_holding     = %.3f km\n",   h_holding/1000)
  text=text..string.format("h_max         = %.3f km\n",   h_max/1000)
  text=text..string.format("FL min        = %.3f km\n",   FLmin/1000)
  text=text..string.format("FL expect     = %.3f km\n",   FLcruise_expect/1000)
  text=text..string.format("FL cruise *   = %.3f km\n",   FLcruise/1000)
  text=text..string.format("FL max        = %.3f km\n",   FLmax/1000)
  text=text..string.format("Ceiling       = %.3f km\n",   ceiling/1000)
  text=text..string.format("Max range     = %.3f km\n",   Range/1000)
  self:T(self.lid..text)

  -- Ensure that cruise distance is positve. Can be slightly negative in special cases. And we don't want to turn back.
  if d_cruise<0 then
    d_cruise=100
  end

  ------------------------
  --- Create Waypoints ---
  ------------------------

  -- Waypoints and coordinates
  local wp={}
  local c={}

  -- Cold start (default).
  local _type=COORDINATE.WaypointType.TakeOffParking
  local _action=COORDINATE.WaypointAction.FromParkingArea

  -- Hot start.
  if asset.takeoffType and asset.takeoffType==COORDINATE.WaypointType.TakeOffParkingHot then
    --env.info("FF hot")
    _type=COORDINATE.WaypointType.TakeOffParkingHot
    _action=COORDINATE.WaypointAction.FromParkingAreaHot
  else
    --env.info("FF cold")      
  end


  --- Departure/Take-off
  c[#c+1]=Pdeparture
  wp[#wp+1]=Pdeparture:WaypointAir("RADIO", _type, _action, VxClimb*3.6, true, departure, nil, "Departure")

  --- Begin of Cruise
  local Pcruise=Pdeparture:Translate(d_climb, heading)
  Pcruise.y=FLcruise
  c[#c+1]=Pcruise
  wp[#wp+1]=Pcruise:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxCruise*3.6, true, nil, nil, "Cruise")

  --- Descent
  local Pdescent=Pcruise:Translate(d_cruise, heading)
  Pdescent.y=FLcruise
  c[#c+1]=Pdescent
  wp[#wp+1]=Pdescent:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxDescent*3.6, true, nil, nil, "Descent")

  --- Holding point
  Pholding.y=H_holding+h_holding
  c[#c+1]=Pholding
  wp[#wp+1]=Pholding:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, VxHolding*3.6, true, nil, nil, "Holding")

  --- Final destination.
  c[#c+1]=Pdestination
  wp[#wp+1]=Pdestination:WaypointAir("RADIO", COORDINATE.WaypointType.Land, COORDINATE.WaypointAction.Landing, VxFinal*3.6, true,  destination, nil, "Final Destination")


  -- Mark points at waypoints for debugging.
  if self.Debug then
    for i,coord in pairs(c) do
      local coord=coord --Core.Point#COORDINATE
      local dist=0
      if i>1 then
        dist=coord:Get2DDistance(c[i-1])
      end
      coord:MarkToAll(string.format("Waypoint %i, distance = %.2f km",i, dist/1000))
    end
  end

  return wp,c
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
