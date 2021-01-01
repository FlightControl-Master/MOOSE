--- **AI** -- (2.5.1) - Models the intelligent transportation of infantry and other cargo using Ships
--
-- ## Features:
-- 
--   * Transport cargo to various deploy zones using naval vehicles.
--   * Various @{Cargo.Cargo#CARGO} types can be transported, including infantry, vehicles, and crates.
--   * Define a deploy zone of various types to determine the destination of the cargo.
--   * Ships will follow shipping lanes as defined in the Mission Editor.
--   * Multiple ships can transport multiple cargo as a single group.
--
-- ===
--
-- ## Test Missions: 
--
-- NEED TO DO
--
-- ===
--
-- ### Author: **acrojason** (derived from AI_Cargo_Dispatcher_APC by FlightControl)
--
-- ===
--
-- @module AI.AI_Cargo_Dispatcher_Ship
-- @image AI_Cargo_Dispatching_For_Ship.JPG

--- @type AI_CARGO_DISPATCHER_SHIP
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- A dynamic cargo transportation capability for AI groups.
-- 
-- Naval vessels can be mobilized to semi-intelligently transport cargo within the simulation.
--
-- The AI_CARGO_DISPATCHER_SHIP module is derived from the AI_CARGO_DISPATCHER module.
--
-- ## Note! In order to fully understand the mechanisms of the AI_CARGO_DISPATCHER_SHIP class, it is recommended that you first consult and READ the documentation of the @{AI.AI_Cargo_Dispatcher} module!!!
--
-- This will be particularly helpful in order to determine how to **Tailor the different cargo handling events**.
--
-- The AI_CARGO_DISPATCHER_SHIP class uses the @{Cargo.Cargo} capabilities within the MOOSE framwork.
-- Also ensure that you fully understand how to declare and setup Cargo objects within the MOOSE framework before using this class.
-- CARGO derived objects must generally be declared within the mission to make the AI_CARGO_DISPATCHER_SHIP object recognize the cargo.
--
--
-- # 1) AI_CARGO_DISPATCHER_SHIP constructor.
-- 
--   * @{AI_CARGO_DISPATCHER_SHIP.New}(): Creates a new AI_CARGO_DISPATCHER_SHIP object.
--
-- ---
--
-- # 2) AI_CARGO_DISPATCHER_SHIP is a Finite State Machine.
--
-- This section must be read as follows... Each of the rows indicate a state transition, triggered through an event, and with an ending state of the event was executed.
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
-- ## 2.3) Enhance your mission scripts with **Tailored** Event Handling!
-- 
-- Within your mission, you can capture these events when triggered, and tailor the events with your own code!
-- Check out the @{AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER} class at chapter 3 for details on the different event handlers that are available and how to use them.
-- 
-- **There are a lot of templates available that allows you to quickly setup an event handler for a specific event type!**
-- 
-- ---
-- 
-- # 3) Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER_SHIP.SetPickupRadius}(): Sets or randomizes the pickup location for the Ship around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER_SHIP.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
--    
-- # 4) Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER_SHIP.SetDeployRadius}(): Sets or randomizes the deploy location for the Ship around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER_SHIP.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
-- 
-- # 5) Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the Ship will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER_SHIP.SetHomeZone}() to specify the home zone.
-- 
-- If no home zone is specified, the Ship will wait near the deploy zone for a new pickup command.   
-- 
-- ===
-- 
-- @field #AI_CARGO_DISPATCHER_SHIP
AI_CARGO_DISPATCHER_SHIP = {
    ClassName = "AI_CARGO_DISPATCHER_SHIP"
  }
  
--- Creates a new AI_CARGO_DISPATCHER_SHIP object.
-- @param #AI_CARGO_DISPATCHER_SHIP self
-- @param Core.Set#SET_GROUP ShipSet  The set of @{Wrapper.Group#GROUP} objects of Ships that will transport the cargo
-- @param Core.Set#SET_CARGO CargoSet  The set of @{Cargo.Cargo#CARGO} objects, which can be CARGO_GROUP, CARGO_CRATE, or CARGO_SLINGLOAD objects.
-- @param Core.Set#SET_ZONE PickupZoneSet  The set of pickup zones which are used to determine from where the cargo can be picked up by the Ship. 
-- @param Core.Set#SET_ZONE DeployZoneSet  The set of deploy zones which determine where the cargo will be deployed by the Ship.
-- @param #table ShippingLane  Table containing list of Shipping Lanes to be used
-- @return #AI_CARGO_DISPATCHER_SHIP
-- @usage
--
--      -- An AI dispatcher object for a naval group, moving cargo from pickup zones to deploy zones via a predetermined Shipping Lane
--
--      local SetCargoInfantry = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
--      local SetShip = SET_GROUP:New():FilterPrefixes( "Ship" ):FilterStart()
--      local SetPickupZones = SET_ZONE:New():FilterPrefixes( "Pickup" ):FilterStart()
--      local SetDeployZones = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
--      NEED MORE THOUGHT - ShippingLane is part of Warehouse.......
--      local ShippingLane = GROUP:New():FilterPrefixes( "ShippingLane" ):FilterStart()
-- 
--      AICargoDispatcherShip = AI_CARGO_DISPATCHER_SHIP:New( SetShip, SetCargoInfantry, SetPickupZones, SetDeployZones, ShippingLane )
--      AICargoDispatcherShip:Start()
--
function AI_CARGO_DISPATCHER_SHIP:New( ShipSet, CargoSet, PickupZoneSet, DeployZoneSet, ShippingLane )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( ShipSet, CargoSet, PickupZoneSet, DeployZoneSet ) )

  self:SetPickupSpeed( 60, 10 )
  self:SetDeploySpeed( 60, 10 )

  self:SetPickupRadius( 500, 6000 )
  self:SetDeployRadius( 500, 6000 )

  self:SetPickupHeight( 0, 0 )
  self:SetDeployHeight( 0, 0 )

  self:SetShippingLane( ShippingLane )

  self:SetMonitorTimeInterval( 600 )

  return self
end

function AI_CARGO_DISPATCHER_SHIP:SetShippingLane( ShippingLane )
  self.ShippingLane = ShippingLane

  return self

end

function AI_CARGO_DISPATCHER_SHIP:AICargo( Ship, CargoSet )

  return AI_CARGO_SHIP:New( Ship, CargoSet, 0, self.ShippingLane )
end