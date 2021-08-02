--- **AI** - Models the intelligent transportation of infantry and other cargo.
--
-- ## Features:
-- 
--   * AI_CARGO_DISPATCHER is the **base class** for:
--   
--     * @{AI.AI_Cargo_Dispatcher_APC#AI_CARGO_DISPATCHER_APC}
--     * @{AI.AI_Cargo_Dispatcher_Helicopter#AI_CARGO_DISPATCHER_HELICOPTER}
--     * @{AI.AI_Cargo_Dispatcher_Airplane#AI_CARGO_DISPATCHER_AIRPLANE}
--     
--   * Provides the facilities to transport cargo over the battle field for the above classes.
--   * Dispatches transport tasks to a common set of cargo transporting groups.
--   * Different options can be setup to tweak the cargo transporation behaviour.
-- 
-- ===
-- 
-- ## Test Missions:
-- 
-- Test missions can be located on the main GITHUB site.
-- 
-- [FlightControl-Master/MOOSE_MISSIONS/AID - AI Dispatching/AID-CGO - AI Cargo Dispatching/](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/AID%20-%20AI%20Dispatching/AID-CGO%20-%20AI%20Cargo%20Dispatching)
-- 
-- ===
-- 
-- # The dispatcher concept.
-- 
-- Carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI_CARGO_DISPATCHER module uses the @{Cargo.Cargo} capabilities within the MOOSE framework, to enable Carrier GROUP objects 
-- to transport @{Cargo.Cargo} towards several deploy zones.
-- @{Cargo.Cargo} must be declared within the mission to make the AI_CARGO_DISPATCHER object recognize the cargo.
-- Please consult the @{Cargo.Cargo} module for more information. 
-- 
-- 
-- ## Why cargo dispatching?
-- 
-- It provides a realistic way of distributing your army forces around the battlefield, and to provide a quick means of cargo transportation.
-- Instead of having troops or cargo to "appear" suddenly at certain locations, the dispatchers will pickup the cargo and transport it.
-- It also allows to enforce or retreat your army from certain zones when needed, using helicopters or APCs.
-- Airplanes can transport cargo over larger distances between the airfields.
-- 
-- 
-- ## What is a cargo object then?
-- 
-- In order to make use of the MOOSE cargo system, you need to **declare** the DCS objects as MOOSE cargo objects!
-- This sounds complicated, but it is actually quite simple.
-- 
-- See here an example:
-- 
--     local EngineerCargoGroup = CARGO_GROUP:New( GROUP:FindByName( "Engineers" ), "Workmaterials", "Engineers", 250 )
--     
-- The above code declares a MOOSE cargo object called `EngineerCargoGroup`.
-- It actually just refers to an infantry group created within the sim called `"Engineers"`.
-- The infantry group now becomes controlled by the MOOSE cargo object `EngineerCargoGroup`.
-- A MOOSE cargo object also has properties, like the type of cargo, the logical name, and the reporting range.
-- 
-- For more information, please consult the @{Cargo.Cargo} module documentation. Please read through it, because it will explain how to setup the cargo objects for use
-- within your dispatchers.
-- 
-- 
-- ## Do I need to do a lot of coding to setup a dispatcher?
-- 
-- No! It requires a bit of studying to set it up, but once you understand the different components that use the cargo dispatcher, it becomes very easy.
-- Also, the dispatchers work in a true dynamic environment. The carriers and cargo, pickup and deploy zones can be created dynamically in your mission,
-- and will automatically be recognized by the dispatcher.
-- 
-- 
-- ## Is the dispatcher causing a lot of CPU overhead?
-- 
-- A little yes, but once the cargo is properly loaded into the carrier, the CPU consumption is very little.
-- When infantry or vehicles board into a carrier, or unboard from a carrier, you may perceive certain performance lags.
-- We are working to minimize the impact of those.
-- That being said, the DCS simulator is limited. It is just impossible to deploy hundreds of cargo over the battlefield, hundreds of helicopters transporting, 
-- without any performance impact. The amount of helicopters that are active and flying in your simulation influences more the performance than the dispatchers.
-- It really comes down to trying it out and getting experienced with what is possible and what is not (or too much).
-- 
-- 
-- ## Are the dispatchers a "black box" in terms of the logic?
-- 
-- No. You can tailor the dispatcher mechanisms using event handlers, and create additional logic to enhance the behaviour and dynamism in your own mission.
-- The events are listed below, and so are the options, but here are a couple of examples of what is possible:
-- 
--    * You could handle the **Deployed** event, when all the cargo is unloaded from a carrier in the dispatcher.
--      Adding your own code to the event handler, you could move the deployed cargo (infantry) to specific points to engage in the battlefield.
--    
--    * When a carrier is picking up cargo, the *Pickup** event is triggered, and you can inform the coalition of this event, 
--      because it is an indication that troops are planned to join.
-- 
--    
-- ## Are there options that you can set to modify the behaviour of the carries?
-- 
-- Yes, there are options to configure:
-- 
--    * the location where carriers will park or land near the cargo for pickup. 
--    * the location where carriers will park or land in the deploy zone for cargo deployment.
--    * the height for airborne carriers when they fly to and from pickup and deploy zones.
--    * the speed of the carriers. This is an important parameter, because depending on the tactication situation, speed will influence the detection by radars.
-- 
-- 
-- ## Can the zones be of any zone type?
-- 
-- Yes, please ensure that the zones are declared using the @{Core.Zone} classes.
-- Possible zones that function at the moment are ZONE, ZONE_GROUP, ZONE_UNIT, ZONE_POLYGON.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Dispatcher
-- @image AI_Cargo_Dispatcher.JPG


--- @type AI_CARGO_DISPATCHER
-- @field Core.Set#SET_GROUP CarrierSet The set of @{Wrapper.Group#GROUP} objects of carriers that will transport the cargo. 
-- @field Core.Set#SET_CARGO CargoSet The set of @{Cargo.Cargo#CARGO} objects, which can be CARGO_GROUP, CARGO_CRATE, CARGO_SLINGLOAD objects.
-- @field Core.Zone#SET_ZONE PickupZoneSet The set of pickup zones, which are used to where the cargo can be picked up by the carriers. If nil, then cargo can be picked up everywhere. 
-- @field Core.Zone#SET_ZONE DeployZoneSet The set of deploy zones, which are used to where the cargo will be deployed by the carriers. 
-- @field #number PickupMaxSpeed The maximum speed to move to the cargo pickup location.
-- @field #number PickupMinSpeed The minimum speed to move to the cargo pickup location.
-- @field #number DeployMaxSpeed The maximum speed to move to the cargo deploy location.
-- @field #number DeployMinSpeed The minimum speed to move to the cargo deploy location.
-- @field #number PickupMaxHeight The maximum height to fly to the cargo pickup location.
-- @field #number PickupMinHeight The minimum height to fly to the cargo pickup location.
-- @field #number DeployMaxHeight The maximum height to fly to the cargo deploy location.
-- @field #number DeployMinHeight The minimum height to fly to the cargo deploy location.
-- @field #number PickupOuterRadius The outer radius in meters around the cargo coordinate to pickup the cargo.
-- @field #number PickupInnerRadius The inner radius in meters around the cargo coordinate to pickup the cargo.
-- @field #number DeployOuterRadius The outer radius in meters around the cargo coordinate to deploy the cargo.
-- @field #number DeployInnerRadius The inner radius in meters around the cargo coordinate to deploy the cargo.
-- @field Core.Zone#ZONE_BASE HomeZone The home zone where the carriers will return when there is no more cargo to pickup.
-- @field #number MonitorTimeInterval The interval in seconds when the cargo dispatcher will search for new cargo to be picked up.
-- @extends Core.Fsm#FSM


--- A dynamic cargo handling capability for AI groups.
-- 
-- ---   
-- 
-- Carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI_CARGO_DISPATCHER module uses the @{Cargo.Cargo} capabilities within the MOOSE framework, to enable Carrier GROUP objects 
-- to transport @{Cargo.Cargo} towards several deploy zones.
-- @{Cargo.Cargo} must be declared within the mission to make the AI_CARGO_DISPATCHER object recognize the cargo.
-- Please consult the @{Cargo.Cargo} module for more information. 
-- 
-- # 1) AI_CARGO_DISPATCHER constructor.
--   
--   * @{#AI_CARGO_DISPATCHER.New}(): Creates a new AI_CARGO_DISPATCHER object.
-- 
-- Find below some examples of AI cargo dispatcher objects created.
-- 
-- ### An AI dispatcher object for a helicopter squadron, moving infantry from pickup zones to deploy zones.
-- 
--        local SetCargoInfantry = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--        local SetHelicopter = SET_GROUP:New():FilterPrefixes( "Helicopter" ):FilterStart()
--        local SetPickupZones = SET_ZONE:New():FilterPrefixes( "Pickup" ):FilterStart()
--        local SetDeployZones = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
--      
--        AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
--        AICargoDispatcherHelicopter:SetHomeZone( ZONE:FindByName( "Home" ) )
-- 
-- ### An AI dispatcher object for a vehicle squadron, moving infantry from pickup zones to deploy zones.
-- 
--        local SetCargoInfantry = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--        local SetAPC = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
--        local SetDeployZones = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
--      
--        AICargoDispatcherAPC = AI_CARGO_DISPATCHER_APC:New( SetAPC, SetCargoInfantry, nil, SetDeployZones ) 
--        AICargoDispatcherAPC:Start()
-- 
-- ### An AI dispatcher object for an airplane squadron, moving infantry and vehicles from pickup airbases to deploy airbases.
--   
--        local CargoInfantrySet = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--        local AirplanesSet = SET_GROUP:New():FilterPrefixes( "Airplane" ):FilterStart()
--        local PickupZoneSet = SET_ZONE:New()
--        local DeployZoneSet = SET_ZONE:New()
--      
--        PickupZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Gudauta ) )
--        DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Sochi_Adler ) )
--        DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Maykop_Khanskaya ) )
--        DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Mineralnye_Vody ) )
--        DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Vaziani ) )
--      
--        AICargoDispatcherAirplanes = AI_CARGO_DISPATCHER_AIRPLANE:New( AirplanesSet, CargoInfantrySet, PickupZoneSet, DeployZoneSet ) 
--        AICargoDispatcherAirplanes:SetHomeZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Kobuleti ) )
-- 
-- ---
-- 
-- # 2) AI_CARGO_DISPATCHER is a Finite State Machine.
-- 
-- This section must be read as follows. Each of the rows indicate a state transition, triggered through an event, and with an ending state of the event was executed.
-- The first column is the **From** state, the second column the **Event**, and the third column the **To** state.
-- 
-- So, each of the rows have the following structure.
-- 
--   * **From** => **Event** => **To**
-- 
-- Important to know is that an event can only be executed if the **current state** is the **From** state.
-- This, when an **Event** that is being triggered has a **From** state that is equal to the **Current** state of the state machine, the event will be executed,
-- and the resulting state will be the **To** state.
-- 
-- These are the different possible state transitions of this state machine implementation: 
-- 
--   * Idle => Start => Monitoring
--   * Monitoring => Monitor => Monitoring
--   * Monitoring => Stop => Idle
--      
--   * Monitoring => Pickup => Monitoring
--   * Monitoring => Load => Monitoring
--   * Monitoring => Loading => Monitoring
--   * Monitoring => Loaded => Monitoring
--   * Monitoring => PickedUp => Monitoring
--   * Monitoring => Deploy => Monitoring
--   * Monitoring => Unload => Monitoring
--   * Monitoring => Unloaded => Monitoring
--   * Monitoring => Deployed => Monitoring
--   * Monitoring => Home => Monitoring
--
-- ## 2.1) AI_CARGO_DISPATCHER States.
-- 
--   * **Monitoring**: The process is dispatching.
--   * **Idle**: The process is idle.
-- 
-- ## 2.2) AI_CARGO_DISPATCHER Events.
-- 
--   * **Start**: Start the transport process.
--   * **Stop**: Stop the transport process.
--   * **Monitor**: Monitor and take action.
--   
--   * **Pickup**: Pickup cargo.
--   * **Load**: Load the cargo.
--   * **Loading**: The dispatcher is coordinating the loading of a cargo.
--   * **Loaded**: Flag that the cargo is loaded.
--   * **PickedUp**: The dispatcher has loaded all requested cargo into the CarrierGroup.
--   * **Deploy**: Deploy cargo to a location.
--   * **Unload**: Unload the cargo.
--   * **Unloaded**: Flag that the cargo is unloaded.
--   * **Deployed**: All cargo is unloaded from the carriers in the group.
--   * **Home**: A Carrier is going home.
-- 
-- ---
-- 
-- # 3) Enhance your mission scripts with **Tailored** Event Handling!
-- 
-- Use these methods to capture the events and tailor the events with your own code!
-- All classes derived from AI_CARGO_DISPATCHER can capture these events, and you can write your own code.
-- 
-- In order to properly capture the events, it is mandatory that you execute the following actions using your script:
-- 
--   * Copy / Paste the code section into your script.
--   * Change the CLASS literal to the object name you have in your script.
--   * Within the function, you can now write your own code!
--   * IntelliSense will recognize the type of the variables provided by the function. Note: the From, Event and To variables can be safely ignored, 
--     but you need to declare them as they are automatically provided by the event handling system of MOOSE.
-- 
-- You can send messages or fire off any other events within the code section. The sky is the limit!
-- 
-- Mission AID-CGO-140, AID-CGO-240 and AID-CGO-340 contain examples how these events can be tailored.
-- 
-- For those who don't have the time to check the test missions, find the underlying example of a Deployed event that is tailored.
-- 
--      --- Deployed Handler OnAfter for AI_CARGO_DISPATCHER.
--      -- Use this event handler to tailor the event when a carrier has deployed all cargo objects from the CarrierGroup.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @function OnAfterDeployed
--      -- @param #AICargoDispatcherHelicopter self
--      -- @param #string From A string that contains the "*from state name*" when the event was fired.
--      -- @param #string Event A string that contains the "*event name*" when the event was fired.
--      -- @param #string To A string that contains the "*to state name*" when the event was fired.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function AICargoDispatcherHelicopter:OnAfterDeployed( From, Event, To, CarrierGroup, DeployZone )
--      
--        MESSAGE:NewType( "Group " .. CarrierGroup:GetName() .. " deployed all cargo in zone " .. DeployZone:GetName(), MESSAGE.Type.Information ):ToAll()
--      
--      end 
-- 
-- 
-- ## 3.1) Tailor the **Pickup** event
-- 
-- Use this event handler to tailor the event when a CarrierGroup is routed towards a new pickup Coordinate and a specified Speed.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
-- 
--      --- Pickup event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierGroup is routed towards a new pickup Coordinate and a specified Speed.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Point#COORDINATE Coordinate The coordinate of the pickup location.
--      -- @param #number Speed The velocity in meters per second on which the CarrierGroup is routed towards the pickup Coordinate.
--      -- @param #number Height Height in meters to move to the pickup coordinate.
--      -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
--      function CLASS:OnAfterPickup( From, Event, To, CarrierGroup, Coordinate, Speed, Height, PickupZone )
--      
--        -- Write here your own code.
--      
--      end
--      
-- 
-- ## 3.2) Tailor the **Load** event
-- 
-- Use this event handler to tailor the event when a CarrierGroup has initiated the loading or boarding of cargo within reporting or near range.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
-- 
--      --- Load event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierGroup has initiated the loading or boarding of cargo within reporting or near range.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
--      function CLASS:OnAfterLoad( From, Event, To, CarrierGroup, PickupZone )
--      
--        -- Write here your own code.
--      
--      end
--      
-- 
-- ## 3.3) Tailor the **Loading** event
-- 
-- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup is in the process of loading or boarding of a cargo object.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
-- 
--      --- Loading event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup is in the process of loading or boarding of a cargo object.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- Note that this event is triggered repeatedly until all cargo (units) have been boarded into the carrier.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Cargo.Cargo#CARGO Cargo The cargo object.
--      -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo loading operation.
--      -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
--      function CLASS:OnAfterLoading( From, Event, To, CarrierGroup, Cargo, CarrierUnit, PickupZone )
--      
--        -- Write here your own code.
--      
--      end
-- 
-- 
-- ## 3.4) Tailor the **Loaded** event
-- 
-- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup has loaded a cargo object.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- Note that if more cargo objects were loading or boarding into the CarrierUnit, then this event can be triggered multiple times for each different Cargo/CarrierUnit.
-- 
-- The function provides the CarrierGroup, which is the main group that was loading the Cargo into the CarrierUnit.
-- A CarrierUnit is part of the larger CarrierGroup.
-- 
-- 
--      --- Loaded event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup has loaded a cargo object.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- Note that if more cargo objects were loading or boarding into the CarrierUnit, then this event can be triggered multiple times for each different Cargo/CarrierUnit.
--      -- A CarrierUnit can be part of the larger CarrierGroup.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Cargo.Cargo#CARGO Cargo The cargo object.
--      -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo loading operation.
--      -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
--      function CLASS:OnAfterLoaded( From, Event, To, CarrierGroup, Cargo, CarrierUnit, PickupZone )
--      
--        -- Write here your own code.
--      
--      end
-- 
-- 
-- ## 3.5) Tailor the **PickedUp** event
--
-- Use this event handler to tailor the event when a carrier has picked up all cargo objects into the CarrierGroup.
-- You can use this event handler to post messages to players, or provide status updates etc.
--
--
--      --- PickedUp event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a carrier has picked up all cargo objects into the CarrierGroup.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
--      function CLASS:OnAfterPickedUp( From, Event, To, CarrierGroup, PickupZone )
--      
--        -- Write here your own code.
--      
--      end
--      
-- 
-- ## 3.6) Tailor the **Deploy** event
-- 
-- Use this event handler to tailor the event when a CarrierGroup is routed to a deploy coordinate, to Unload all cargo objects in each CarrierUnit.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
-- 
--      --- Deploy event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierGroup is routed to a deploy coordinate, to Unload all cargo objects in each CarrierUnit.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Point#COORDINATE Coordinate The deploy coordinate.
--      -- @param #number Speed The velocity in meters per second on which the CarrierGroup is routed towards the deploy Coordinate.
--      -- @param #number Height Height in meters to move to the deploy coordinate.
--      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function CLASS:OnAfterDeploy( From, Event, To, CarrierGroup, Coordinate, Speed, Height, DeployZone )
--      
--        -- Write here your own code.
--      
--      end
-- 
-- 
-- ## 3.7) Tailor the **Unload** event
--
-- Use this event handler to tailor the event when a CarrierGroup has initiated the unloading or unboarding of cargo.
-- You can use this event handler to post messages to players, or provide status updates etc.
--
--
--      --- Unload event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierGroup has initiated the unloading or unboarding of cargo.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function CLASS:OnAfterUnload( From, Event, To, CarrierGroup, DeployZone )
--      
--        -- Write here your own code.
--      
--      end
-- 
-- 
-- ## 3.8) Tailor the **Unloading** event
-- 
-- 
--      --- UnLoading event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup is in the process of unloading or unboarding of a cargo object.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- Note that this event is triggered repeatedly until all cargo (units) have been unboarded from the CarrierUnit.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Cargo.Cargo#CARGO Cargo The cargo object.
--      -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo unloading operation.
--      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function CLASS:OnAfterUnload( From, Event, To, CarrierGroup, Cargo, CarrierUnit, DeployZone )
--      
--        -- Write here your own code.
--      
--      end
--      
--      
-- ## 3.9) Tailor the **Unloaded** event
-- 
-- 
-- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup has unloaded a cargo object.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
--      --- Unloaded event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup has unloaded a cargo object.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- Note that if more cargo objects were unloading or unboarding from the CarrierUnit, then this event can be triggered multiple times for each different Cargo/CarrierUnit.
--      -- A CarrierUnit can be part of the larger CarrierGroup.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Cargo.Cargo#CARGO Cargo The cargo object.
--      -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo unloading operation.
--      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function CLASS:OnAfterUnloaded( From, Event, To, CarrierGroup, Cargo, CarrierUnit, DeployZone )
--      
--        -- Write here your own code.
--      
--      end
--      
--      
-- ## 3.10) Tailor the **Deployed** event
-- 
-- Use this event handler to tailor the event when a carrier has deployed all cargo objects from the CarrierGroup.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
-- 
--      --- Deployed event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a carrier has deployed all cargo objects from the CarrierGroup.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function CLASS:OnAfterDeployed( From, Event, To, CarrierGroup, DeployZone )
--      
--        -- Write here your own code.
--      
--      end
-- 
-- ## 3.11) Tailor the **Home** event
-- 
-- Use this event handler to tailor the event when a CarrierGroup is returning to the HomeZone, after it has deployed all cargo objects from the CarrierGroup.
-- You can use this event handler to post messages to players, or provide status updates etc.
-- 
--      --- Home event handler OnAfter for CLASS.
--      -- Use this event handler to tailor the event when a CarrierGroup is returning to the HomeZone, after it has deployed all cargo objects from the CarrierGroup.
--      -- You can use this event handler to post messages to players, or provide status updates etc.
--      -- If there is no HomeZone is specified, the CarrierGroup will stay at the current location after having deployed all cargo and this event won't be triggered.
--      -- @param #CLASS self
--      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
--      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
--      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
--      -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
--      -- @param Core.Point#COORDINATE Coordinate The home coordinate the Carrier will arrive and stop it's activities.
--      -- @param #number Speed The velocity in meters per second on which the CarrierGroup is routed towards the home Coordinate.
--      -- @param #number Height Height in meters to move to the home coordinate.
--      -- @param Core.Zone#ZONE HomeZone The zone wherein the carrier will return when all cargo has been transported. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
--      function CLASS:OnAfterHome( From, Event, To, CarrierGroup, Coordinate, Speed, Height, HomeZone )
--
--        -- Write here your own code.
--      
--      end      
-- 
-- ---
-- 
-- # 4) Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER.SetPickupRadius}(): Sets or randomizes the pickup location for the carrier around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
--    * @{#AI_CARGO_DISPATCHER.SetPickupHeight}(): Set the height or randomizes the height in meters to pickup the cargo.
--    
-- ---   
--    
-- # 5) Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER.SetDeployRadius}(): Sets or randomizes the deploy location for the carrier around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
--    * @{#AI_CARGO_DISPATCHER.SetDeployHeight}(): Set the height or randomizes the height in meters to deploy the cargo.
-- 
-- ---
-- 
-- # 6) Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the Carriers will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER.SetHomeZone}() to specify the home zone.
-- 
-- If no home zone is specified, the carriers will wait near the deploy zone for a new pickup command.   
-- 
-- ===
--   
-- @field #AI_CARGO_DISPATCHER
AI_CARGO_DISPATCHER = {
  ClassName = "AI_CARGO_DISPATCHER",
  AI_Cargo = {},
  PickupCargo = {}
}

--- @field #list 
AI_CARGO_DISPATCHER.AI_Cargo = {}

--- @field #list
AI_CARGO_DISPATCHER.PickupCargo = {}


--- Creates a new AI_CARGO_DISPATCHER object.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Set#SET_GROUP CarrierSet The set of @{Wrapper.Group#GROUP} objects of carriers that will transport the cargo. 
-- @param Core.Set#SET_CARGO CargoSet The set of @{Cargo.Cargo#CARGO} objects, which can be CARGO_GROUP, CARGO_CRATE, CARGO_SLINGLOAD objects.
-- @param Core.Set#SET_ZONE PickupZoneSet (optional) The set of pickup zones, which are used to where the cargo can be picked up by the carriers. If nil, then cargo can be picked up everywhere. 
-- @param Core.Set#SET_ZONE DeployZoneSet The set of deploy zones, which are used to where the cargo will be deployed by the carriers. 
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
--      -- An AI dispatcher object for a helicopter squadron, moving infantry from pickup zones to deploy zones.
-- 
--      local SetCargoInfantry = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--      local SetHelicopter = SET_GROUP:New():FilterPrefixes( "Helicopter" ):FilterStart()
--      local SetPickupZones = SET_ZONE:New():FilterPrefixes( "Pickup" ):FilterStart()
--      local SetDeployZones = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
--      
--      AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
--      AICargoDispatcherHelicopter:Start()
-- 
-- @usage
-- 
--      -- An AI dispatcher object for a vehicle squadron, moving infantry from pickup zones to deploy zones.
-- 
--      local SetCargoInfantry = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--      local SetAPC = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
--      local SetDeployZones = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
--      
--      AICargoDispatcherAPC = AI_CARGO_DISPATCHER_APC:New( SetAPC, SetCargoInfantry, nil, SetDeployZones ) 
--      AICargoDispatcherAPC:Start()
-- 
-- @usage
-- 
--      -- An AI dispatcher object for an airplane squadron, moving infantry and vehicles from pickup airbases to deploy airbases.
--   
--      local CargoInfantrySet = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--      local AirplanesSet = SET_GROUP:New():FilterPrefixes( "Airplane" ):FilterStart()
--      local PickupZoneSet = SET_ZONE:New()
--      local DeployZoneSet = SET_ZONE:New()
--      
--      PickupZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Gudauta ) )
--      DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Sochi_Adler ) )
--      DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Maykop_Khanskaya ) )
--      DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Mineralnye_Vody ) )
--      DeployZoneSet:AddZone( ZONE_AIRBASE:New( AIRBASE.Caucasus.Vaziani ) )
--      
--      AICargoDispatcherAirplanes = AI_CARGO_DISPATCHER_AIRPLANE:New( AirplanesSet, CargoInfantrySet, PickupZoneSet, DeployZoneSet ) 
--      AICargoDispatcherAirplanes:Start()
-- 
function AI_CARGO_DISPATCHER:New( CarrierSet, CargoSet, PickupZoneSet, DeployZoneSet )

  local self = BASE:Inherit( self, FSM:New() ) -- #AI_CARGO_DISPATCHER

  self.SetCarrier = CarrierSet -- Core.Set#SET_GROUP
  self.SetCargo = CargoSet -- Core.Set#SET_CARGO
  

  self.PickupZoneSet=PickupZoneSet
  self.DeployZoneSet=DeployZoneSet

  self:SetStartState( "Idle" ) 
  
  self:AddTransition( "Monitoring", "Monitor", "Monitoring" )

  self:AddTransition( "Idle", "Start", "Monitoring" )
  self:AddTransition( "Monitoring", "Stop", "Idle" )
  

  self:AddTransition( "Monitoring", "Pickup", "Monitoring" )
  self:AddTransition( "Monitoring", "Load", "Monitoring" )
  self:AddTransition( "Monitoring", "Loading", "Monitoring" )
  self:AddTransition( "Monitoring", "Loaded", "Monitoring" )
  self:AddTransition( "Monitoring", "PickedUp", "Monitoring" )

  self:AddTransition( "Monitoring", "Transport", "Monitoring" )

  self:AddTransition( "Monitoring", "Deploy", "Monitoring" )
  self:AddTransition( "Monitoring", "Unload", "Monitoring" )
  self:AddTransition( "Monitoring", "Unloading", "Monitoring" )
  self:AddTransition( "Monitoring", "Unloaded", "Monitoring" )
  self:AddTransition( "Monitoring", "Deployed", "Monitoring" )
  
  self:AddTransition( "Monitoring", "Home", "Monitoring" )
  
  self:SetMonitorTimeInterval( 30 )
  
  self:SetDeployRadius( 500, 200 )
  
  self.PickupCargo = {}
  self.CarrierHome = {}
  
  -- Put a Dead event handler on SetCarrier, to ensure that when a carrier is destroyed, that all internal parameters are reset.
  function self.SetCarrier.OnAfterRemoved( SetCarrier, From, Event, To, CarrierName, Carrier )
    self:F( { Carrier = Carrier:GetName() } )
    self.PickupCargo[Carrier] = nil
    self.CarrierHome[Carrier] = nil
  end
  
  return self
end


--- Set the monitor time interval.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MonitorTimeInterval The interval in seconds when the cargo dispatcher will search for new cargo to be picked up.
-- @return #AI_CARGO_DISPATCHER
function AI_CARGO_DISPATCHER:SetMonitorTimeInterval( MonitorTimeInterval )

  self.MonitorTimeInterval = MonitorTimeInterval
  
  return self
end


--- Set the home zone.
-- When there is nothing anymore to pickup, the carriers will go to a random coordinate in this zone.
-- They will await here new orders.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Zone#ZONE_BASE HomeZone The home zone where the carriers will return when there is no more cargo to pickup.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the home coordinate
-- local HomeZone = ZONE:New( "Home" )
-- AICargoDispatcherHelicopter:SetHomeZone( HomeZone )
-- 
function AI_CARGO_DISPATCHER:SetHomeZone( HomeZone )

  self.HomeZone = HomeZone
  
  return self
end


--- Sets or randomizes the pickup location for the carrier around the cargo coordinate in a radius defined an outer and optional inner radius.
-- This radius is influencing the location where the carrier will land to pickup the cargo.
-- There are two aspects that are very important to remember and take into account:
-- 
--   - Ensure that the outer and inner radius are within reporting radius set by the cargo.
--     For example, if the cargo has a reporting radius of 400 meters, and the outer and inner radius is set to 500 and 450 respectively, 
--     then no cargo will be loaded!!!
--   - Also take care of the potential cargo position and possible reasons to crash the carrier. This is especially important
--     for locations which are crowded with other objects, like in the middle of villages or cities.
--     So, for the best operation of cargo operations, always ensure that the cargo is located at open spaces.
-- 
-- The default radius is 0, so the center. In case of a polygon zone, a random location will be selected as the center in the zone.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number OuterRadius The outer radius in meters around the cargo coordinate.
-- @param #number InnerRadius (optional) The inner radius in meters around the cargo coordinate.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the carrier to land within a band around the cargo coordinate between 500 and 300 meters!
-- AICargoDispatcherHelicopter:SetPickupRadius( 500, 300 )
-- 
function AI_CARGO_DISPATCHER:SetPickupRadius( OuterRadius, InnerRadius )

  OuterRadius = OuterRadius or 0
  InnerRadius = InnerRadius or OuterRadius

  self.PickupOuterRadius = OuterRadius
  self.PickupInnerRadius = InnerRadius
  
  return self
end


--- Set the speed or randomizes the speed in km/h to pickup the cargo.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MaxSpeed (optional) The maximum speed to move to the cargo pickup location.
-- @param #number MinSpeed The minimum speed to move to the cargo pickup location.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the minimum pickup speed to be 100 km/h and the maximum speed to be 200 km/h.
-- AICargoDispatcherHelicopter:SetPickupSpeed( 200, 100 )
-- 
function AI_CARGO_DISPATCHER:SetPickupSpeed( MaxSpeed, MinSpeed )

  MaxSpeed = MaxSpeed or 999
  MinSpeed = MinSpeed or MaxSpeed

  self.PickupMinSpeed = MinSpeed
  self.PickupMaxSpeed = MaxSpeed
  
  return self
end


--- Sets or randomizes the deploy location for the carrier around the cargo coordinate in a radius defined an outer and an optional inner radius.
-- This radius is influencing the location where the carrier will land to deploy the cargo.
-- There is an aspect that is very important to remember and take into account:
-- 
--   - Take care of the potential cargo position and possible reasons to crash the carrier. This is especially important
--     for locations which are crowded with other objects, like in the middle of villages or cities.
--     So, for the best operation of cargo operations, always ensure that the cargo is located at open spaces.
-- 
-- The default radius is 0, so the center. In case of a polygon zone, a random location will be selected as the center in the zone.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number OuterRadius The outer radius in meters around the cargo coordinate.
-- @param #number InnerRadius (optional) The inner radius in meters around the cargo coordinate.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the carrier to land within a band around the cargo coordinate between 500 and 300 meters!
-- AICargoDispatcherHelicopter:SetDeployRadius( 500, 300 )
-- 
function AI_CARGO_DISPATCHER:SetDeployRadius( OuterRadius, InnerRadius )

  OuterRadius = OuterRadius or 0
  InnerRadius = InnerRadius or OuterRadius

  self.DeployOuterRadius = OuterRadius
  self.DeployInnerRadius = InnerRadius
  
  return self
end


--- Sets or randomizes the speed in km/h to deploy the cargo.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MaxSpeed The maximum speed to move to the cargo deploy location.
-- @param #number MinSpeed (optional) The minimum speed to move to the cargo deploy location.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the minimum deploy speed to be 100 km/h and the maximum speed to be 200 km/h.
-- AICargoDispatcherHelicopter:SetDeploySpeed( 200, 100 )
-- 
function AI_CARGO_DISPATCHER:SetDeploySpeed( MaxSpeed, MinSpeed )

  MaxSpeed = MaxSpeed or 999
  MinSpeed = MinSpeed or MaxSpeed

  self.DeployMinSpeed = MinSpeed
  self.DeployMaxSpeed = MaxSpeed
  
  return self
end


--- Set the height or randomizes the height in meters to fly and pickup the cargo. The default height is 200 meters.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MaxHeight (optional) The maximum height to fly to the cargo pickup location.
-- @param #number MinHeight (optional) The minimum height to fly to the cargo pickup location.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the minimum pickup fly height to be 50 meters and the maximum height to be 200 meters.
-- AICargoDispatcherHelicopter:SetPickupHeight( 200, 50 )
-- 
function AI_CARGO_DISPATCHER:SetPickupHeight( MaxHeight, MinHeight )

  MaxHeight = MaxHeight or 200
  MinHeight = MinHeight or MaxHeight

  self.PickupMinHeight = MinHeight
  self.PickupMaxHeight = MaxHeight
  
  return self
end


--- Set the height or randomizes the height in meters to fly and deploy the cargo.  The default height is 200 meters.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MaxHeight (optional) The maximum height to fly to the cargo deploy location.
-- @param #number MinHeight (optional) The minimum height to fly to the cargo deploy location.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcherHelicopter = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargoInfantry, SetPickupZones, SetDeployZones ) 
-- 
-- -- Set the minimum deploy fly height to be 50 meters and the maximum height to be 200 meters.
-- AICargoDispatcherHelicopter:SetDeployHeight( 200, 50 )
-- 
function AI_CARGO_DISPATCHER:SetDeployHeight( MaxHeight, MinHeight )

  MaxHeight = MaxHeight or 200
  MinHeight = MinHeight or MaxHeight

  self.DeployMinHeight = MinHeight
  self.DeployMaxHeight = MaxHeight
  
  return self
end


--- The Start trigger event, which actually takes action at the specified time interval.
-- @param #AI_CARGO_DISPATCHER self
function AI_CARGO_DISPATCHER:onafterMonitor()

  self:F("Carriers")
  self.SetCarrier:Flush()
  
  for CarrierGroupName, Carrier in pairs( self.SetCarrier:GetSet() ) do
    local Carrier = Carrier -- Wrapper.Group#GROUP
    if Carrier:IsAlive() ~= nil then
      local AI_Cargo = self.AI_Cargo[Carrier]
      if not AI_Cargo then
      
        -- ok, so this Carrier does not have yet an AI_CARGO handling object...
        -- let's create one and also declare the Loaded and UnLoaded handlers.
        self.AI_Cargo[Carrier] = self:AICargo( Carrier, self.SetCargo, self.CombatRadius )
        AI_Cargo = self.AI_Cargo[Carrier]
        
        --- Pickup event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierGroup is routed towards a new pickup Coordinate and a specified Speed.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterPickup
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Point#COORDINATE Coordinate The coordinate of the pickup location.
        -- @param #number Speed The velocity in meters per second on which the CarrierGroup is routed towards the pickup Coordinate.
        -- @param #number Height Height in meters to move to the pickup coordinate.
        -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
        function AI_Cargo.OnAfterPickup( AI_Cargo, CarrierGroup, From, Event, To, Coordinate, Speed, Height, PickupZone )
          self:Pickup( CarrierGroup, Coordinate, Speed, Height, PickupZone )
        end
        
        --- Load event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierGroup has initiated the loading or boarding of cargo within reporting or near range.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterLoad
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
        
        function AI_Cargo.OnAfterLoad( AI_Cargo, CarrierGroup, From, Event, To, PickupZone )
          self:Load( CarrierGroup, PickupZone )
        end
  
        --- Loading event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup is in the process of loading or boarding of a cargo object.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- Note that this event is triggered repeatedly until all cargo (units) have been boarded into the carrier.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterLoading
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Cargo.Cargo#CARGO Cargo The cargo object.
        -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo loading operation.
        -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
        
        function AI_Cargo.OnAfterBoard( AI_Cargo, CarrierGroup, From, Event, To, Cargo, CarrierUnit, PickupZone )
          self:Loading( CarrierGroup, Cargo, CarrierUnit, PickupZone )
        end
  
        --- Loaded event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup has loaded a cargo object.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- Note that if more cargo objects were loading or boarding into the CarrierUnit, then this event can be triggered multiple times for each different Cargo/CarrierUnit.
        -- A CarrierUnit can be part of the larger CarrierGroup.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterLoaded
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Cargo.Cargo#CARGO Cargo The cargo object.
        -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo loading operation.
        -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
        
        function AI_Cargo.OnAfterLoaded( AI_Cargo, CarrierGroup, From, Event, To, Cargo, CarrierUnit, PickupZone )
          self:Loaded( CarrierGroup, Cargo, CarrierUnit, PickupZone )
        end
  
        --- PickedUp event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a carrier has picked up all cargo objects into the CarrierGroup.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterPickedUp
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Zone#ZONE_AIRBASE PickupZone (optional) The zone from where the cargo is picked up. Note that the zone is optional and may not be provided, but for AI_CARGO_DISPATCHER_AIRBASE there will always be a PickupZone, as the pickup location is an airbase zone.
        
        function AI_Cargo.OnAfterPickedUp( AI_Cargo, CarrierGroup, From, Event, To, PickupZone )
          self:PickedUp( CarrierGroup, PickupZone )
          self:Transport( CarrierGroup )
        end
  
  
        --- Deploy event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierGroup is routed to a deploy coordinate, to Unload all cargo objects in each CarrierUnit.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterDeploy
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Point#COORDINATE Coordinate The deploy coordinate.
        -- @param #number Speed The velocity in meters per second on which the CarrierGroup is routed towards the deploy Coordinate.
        -- @param #number Height Height in meters to move to the deploy coordinate.
        -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
        
        function AI_Cargo.OnAfterDeploy( AI_Cargo, CarrierGroup, From, Event, To, Coordinate, Speed, Height, DeployZone )
          self:Deploy( CarrierGroup, Coordinate, Speed, Height, DeployZone )
        end      
  
  
        --- Unload event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierGroup has initiated the unloading or unboarding of cargo.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterUnload
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
        
        function AI_Cargo.OnAfterUnload( AI_Cargo, Carrier, From, Event, To, Cargo, CarrierUnit, DeployZone )
          self:Unloading( Carrier, Cargo, CarrierUnit, DeployZone )
        end      
  
        --- UnLoading event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup is in the process of unloading or unboarding of a cargo object.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- Note that this event is triggered repeatedly until all cargo (units) have been unboarded from the CarrierUnit.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterUnloading
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Cargo.Cargo#CARGO Cargo The cargo object.
        -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo unloading operation.
        -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
        
        function AI_Cargo.OnAfterUnboard( AI_Cargo, CarrierGroup, From, Event, To, Cargo, CarrierUnit, DeployZone )
          self:Unloading( CarrierGroup, Cargo, CarrierUnit, DeployZone )
        end
  
  
        --- Unloaded event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierUnit of a CarrierGroup has unloaded a cargo object.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- Note that if more cargo objects were unloading or unboarding from the CarrierUnit, then this event can be triggered multiple times for each different Cargo/CarrierUnit.
        -- A CarrierUnit can be part of the larger CarrierGroup.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterUnloaded
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Cargo.Cargo#CARGO Cargo The cargo object.
        -- @param Wrapper.Unit#UNIT CarrierUnit The carrier unit that is executing the cargo unloading operation.
        -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
        
        function AI_Cargo.OnAfterUnloaded( AI_Cargo, Carrier, From, Event, To, Cargo, CarrierUnit, DeployZone )
          self:Unloaded( Carrier, Cargo, CarrierUnit, DeployZone )
        end      
  
        --- Deployed event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a carrier has deployed all cargo objects from the CarrierGroup.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterDeployed
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
        
        function AI_Cargo.OnAfterDeployed( AI_Cargo, Carrier, From, Event, To, DeployZone )
          self:Deployed( Carrier, DeployZone )
        end      
  
        --- Home event handler OnAfter for AI_CARGO_DISPATCHER.
        -- Use this event handler to tailor the event when a CarrierGroup is returning to the HomeZone, after it has deployed all cargo objects from the CarrierGroup.
        -- You can use this event handler to post messages to players, or provide status updates etc.
        -- If there is no HomeZone is specified, the CarrierGroup will stay at the current location after having deployed all cargo.
        -- @function [parent=#AI_CARGO_DISPATCHER] OnAfterHome
        -- @param #AI_CARGO_DISPATCHER self
        -- @param #string From A string that contains the "*from state name*" when the event was triggered.
        -- @param #string Event A string that contains the "*event name*" when the event was triggered.
        -- @param #string To A string that contains the "*to state name*" when the event was triggered.
        -- @param Wrapper.Group#GROUP CarrierGroup The group object that contains the CarrierUnits.
        -- @param Core.Point#COORDINATE Coordinate The home coordinate the Carrier will arrive and stop it's activities.
        -- @param #number Speed The velocity in meters per second on which the CarrierGroup is routed towards the home Coordinate.
        -- @param #number Height Height in meters to move to the home coordinate.
        -- @param Core.Zone#ZONE HomeZone The zone wherein the carrier will return when all cargo has been transported. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
        
        function AI_Cargo.OnAfterHome( AI_Cargo, Carrier, From, Event, To, Coordinate, Speed, Height, HomeZone )
          self:Home( Carrier, Coordinate, Speed, Height, HomeZone )
        end      
      end
  
      -- The Pickup sequence ...
      -- Check if this Carrier need to go and Pickup something...
      -- So, if the cargo bay is not full yet with cargo to be loaded ...
      self:T( { Carrier = CarrierGroupName, IsRelocating = AI_Cargo:IsRelocating(), IsTransporting = AI_Cargo:IsTransporting() } )
      if AI_Cargo:IsRelocating() == false and AI_Cargo:IsTransporting() == false then
        -- ok, so there is a free Carrier
        -- now find the first cargo that is Unloaded
        
        local PickupCargo = nil
        local PickupZone = nil
        
        self.SetCargo:Flush()
        for CargoName, Cargo in UTILS.spairs( self.SetCargo:GetSet(), function( t, a, b ) return t[a]:GetWeight() < t[b]:GetWeight() end ) do
          local Cargo = Cargo -- Cargo.Cargo#CARGO
          self:F( { Cargo = Cargo:GetName(), UnLoaded = Cargo:IsUnLoaded(), Deployed = Cargo:IsDeployed(), PickupCargo = self.PickupCargo[Carrier] ~= nil } )
          if Cargo:IsUnLoaded() == true and Cargo:IsDeployed() == false then
            local CargoCoordinate = Cargo:GetCoordinate()
            local CoordinateFree = true
            --self.PickupZoneSet:Flush()
            --PickupZone = self.PickupZoneSet:GetRandomZone()
            PickupZone = self.PickupZoneSet and self.PickupZoneSet:IsCoordinateInZone( CargoCoordinate )
            if not self.PickupZoneSet or PickupZone then
              for CarrierPickup, Coordinate in pairs( self.PickupCargo ) do
                if CarrierPickup:IsAlive() == true then
                  if CargoCoordinate:Get2DDistance( Coordinate ) <= 25 then
                    self:F( { "Coordinate not free for ", Cargo = Cargo:GetName(), Carrier:GetName(), PickupCargo = self.PickupCargo[Carrier] ~= nil } )
                    CoordinateFree = false
                    break
                  end
                else
                  self.PickupCargo[CarrierPickup] = nil
                end
              end
              if CoordinateFree == true then
                -- Check if this cargo can be picked-up by at least one carrier unit of AI_Cargo.
                local LargestLoadCapacity = 0
                for _, Carrier in pairs( Carrier:GetUnits() ) do
                  local LoadCapacity = Carrier:GetCargoBayFreeWeight()
                  if LargestLoadCapacity < LoadCapacity then
                    LargestLoadCapacity = LoadCapacity
                  end
                end
                -- So if there is a carrier that has the required load capacity to load the total weight of the cargo, dispatch the carrier.
                -- Otherwise break and go to the next carrier.
                -- This will skip cargo which is too large to be able to be loaded by carriers
                -- and will secure an efficient dispatching scheme.
                if LargestLoadCapacity >= Cargo:GetWeight() then
                  self.PickupCargo[Carrier] = CargoCoordinate
                  PickupCargo = Cargo
                  break
                else
                  local text=string.format("WARNING: Cargo %s is too heavy to be loaded into transport. Cargo weight %.1f > %.1f load capacity of carrier %s.", 
                  tostring(Cargo:GetName()), Cargo:GetWeight(), LargestLoadCapacity, tostring(Carrier:GetName()))
                  self:I(text)
                end
              end
            end
          end
        end
        
        if PickupCargo then
          self.CarrierHome[Carrier] = nil
          local PickupCoordinate = PickupCargo:GetCoordinate():GetRandomCoordinateInRadius( self.PickupOuterRadius, self.PickupInnerRadius )
          AI_Cargo:Pickup( PickupCoordinate, math.random( self.PickupMinSpeed, self.PickupMaxSpeed ), math.random( self.PickupMinHeight, self.PickupMaxHeight ), PickupZone )
          break
        else
          if self.HomeZone then
            if not self.CarrierHome[Carrier] then
              self.CarrierHome[Carrier] = true
              AI_Cargo:Home( self.HomeZone:GetRandomPointVec2(), math.random( self.PickupMinSpeed, self.PickupMaxSpeed ), math.random( self.PickupMinHeight, self.PickupMaxHeight ), self.HomeZone )
            end
          end
        end
      end
    end
  end

  self:__Monitor( self.MonitorTimeInterval )
end


--- Start Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] Start
-- @param #AI_CARGO_DISPATCHER self

--- Start Asynchronous Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] __Start
-- @param #AI_CARGO_DISPATCHER self
-- @param #number Delay

function AI_CARGO_DISPATCHER:onafterStart( From, Event, To )
  self:__Monitor( -1 )
end


--- Stop Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] Stop
-- @param #AI_CARGO_DISPATCHER self

--- Stop Asynchronous Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] __Stop
-- @param #AI_CARGO_DISPATCHER self
-- @param #number Delay


--- Make a Carrier run for a cargo deploy action after the cargo has been loaded, by default.
-- @param #AI_CARGO_DISPATCHER self
-- @param From
-- @param Event
-- @param To
-- @param Wrapper.Group#GROUP Carrier
-- @param Cargo.Cargo#CARGO Cargo
-- @return #AI_CARGO_DISPATCHER
function AI_CARGO_DISPATCHER:onafterTransport( From, Event, To, Carrier, Cargo )

  if self.DeployZoneSet then
    if self.AI_Cargo[Carrier]:IsTransporting() == true then
      local DeployZone = self.DeployZoneSet:GetRandomZone()
      
      local DeployCoordinate = DeployZone:GetCoordinate():GetRandomCoordinateInRadius( self.DeployOuterRadius, self.DeployInnerRadius )
      self.AI_Cargo[Carrier]:__Deploy( 0.1, DeployCoordinate, math.random( self.DeployMinSpeed, self.DeployMaxSpeed ), math.random( self.DeployMinHeight, self.DeployMaxHeight ), DeployZone )
    end
  end
  
   self:F( { Carrier = Carrier:GetName(), PickupCargo = self.PickupCargo } )
   self.PickupCargo[Carrier] = nil
end

