--- **AI** - Models the intelligent transportation of infantry and other cargo using Helicopters.
--
-- ## Features:
-- 
--   * The helicopters will fly towards the pickup locations to pickup the cargo.
--   * The helicopters will fly towards the deploy zones to deploy the cargo.
--   * Precision deployment as well as randomized deployment within the deploy zones are possible.
--   * Helicopters will orbit the deploy zones when there is no space for landing until the deploy zone is free.
--   
-- ===
-- 
-- ## Test Missions:
-- 
-- Test missions can be located on the main GITHUB site.
-- 
-- [FlightControl-Master/MOOSE_MISSIONS/AID - AI Dispatching/AID-CGO - AI Cargo Dispatching/]  
-- (https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/AID%20-%20AI%20Dispatching/AID-CGO%20-%20AI%20Cargo%20Dispatching)
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Dispatcher_Helicopter
-- @image AI_Cargo_Dispatching_For_Helicopters.JPG

--- @type AI_CARGO_DISPATCHER_HELICOPTER
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- A dynamic cargo handling capability for AI helicopter groups.
-- 
-- Helicopters can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- 
-- 
-- The AI_CARGO_DISPATCHER_HELICOPTER module is derived from the AI_CARGO_DISPATCHER module.
-- 
-- ## Note! In order to fully understand the mechanisms of the AI_CARGO_DISPATCHER_HELICOPTER class, it is recommended that you first consult and READ the documentation of the @{AI.AI_Cargo_Dispatcher} module!!!**
-- 
-- Especially to learn how to **Tailor the different cargo handling events**, this will be very useful!
-- 
-- On top, the AI_CARGO_DISPATCHER_HELICOPTER class uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- Also ensure that you fully understand how to declare and setup Cargo objects within the MOOSE framework before using this class.
-- CARGO derived objects must be declared within the mission to make the AI_CARGO_DISPATCHER_HELICOPTER object recognize the cargo.
-- 
-- ---
-- 
-- # 1. AI\_CARGO\_DISPATCHER\_HELICOPTER constructor.
--   
--   * @{#AI_CARGO_DISPATCHER\_HELICOPTER.New}(): Creates a new AI\_CARGO\_DISPATCHER\_HELICOPTER object.
-- 
-- ---
-- 
-- # 2. AI\_CARGO\_DISPATCHER\_HELICOPTER is a Finite State Machine.
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
-- ## 3. Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER_HELICOPTER.SetPickupRadius}(): Sets or randomizes the pickup location for the helicopter around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER_HELICOPTER.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
--    * @{#AI_CARGO_DISPATCHER_HELICOPTER.SetPickupHeight}(): Set the height or randomizes the height in meters to pickup the cargo.
-- 
-- ---   
--    
-- ## 4. Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER_HELICOPTER.SetDeployRadius}(): Sets or randomizes the deploy location for the helicopter around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER_HELICOPTER.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
--    * @{#AI_CARGO_DISPATCHER_HELICOPTER.SetDeployHeight}(): Set the height or randomizes the height in meters to deploy the cargo.
-- 
-- ---
-- 
-- ## 5. Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the Helicopters will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER_HELICOPTER.SetHomeZone}() to specify the home zone.
-- 
-- If no home zone is specified, the helicopters will wait near the deploy zone for a new pickup command.   
-- 
-- ===
-- 
-- @field #AI_CARGO_DISPATCHER_HELICOPTER
AI_CARGO_DISPATCHER_HELICOPTER = {
  ClassName = "AI_CARGO_DISPATCHER_HELICOPTER",
}

--- Creates a new AI_CARGO_DISPATCHER_HELICOPTER object.
-- @param #AI_CARGO_DISPATCHER_HELICOPTER self
-- @param Core.Set#SET_GROUP HelicopterSet The set of @{Wrapper.Group#GROUP} objects of helicopters that will transport the cargo.
-- @param Core.Set#SET_CARGO CargoSet The set of @{Cargo.Cargo#CARGO} objects, which can be CARGO_GROUP, CARGO_CRATE, CARGO_SLINGLOAD objects.
-- @param Core.Set#SET_ZONE PickupZoneSet (optional) The set of pickup zones, which are used to where the cargo can be picked up by the APCs. If nil, then cargo can be picked up everywhere. 
-- @param Core.Set#SET_ZONE DeployZoneSet The set of deploy zones, which are used to where the cargo will be deployed by the Helicopters. 
-- @return #AI_CARGO_DISPATCHER_HELICOPTER
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
function AI_CARGO_DISPATCHER_HELICOPTER:New( HelicopterSet, CargoSet, PickupZoneSet, DeployZoneSet )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( HelicopterSet, CargoSet, PickupZoneSet, DeployZoneSet ) ) -- #AI_CARGO_DISPATCHER_HELICOPTER

  self:SetPickupSpeed( 350, 150 )
  self:SetDeploySpeed( 350, 150 )

  self:SetPickupRadius( 40, 12 )
  self:SetDeployRadius( 40, 12 )
  
  self:SetPickupHeight( 500, 200 )
  self:SetDeployHeight( 500, 200 )
  
  return self
end


function AI_CARGO_DISPATCHER_HELICOPTER:AICargo( Helicopter, CargoSet )

  local dispatcher = AI_CARGO_HELICOPTER:New( Helicopter, CargoSet )
  dispatcher:SetLandingSpeedAndHeight(27, 6)
  return dispatcher
  
end

