--- **AI** -- Models the intelligent transportation of infantry and other cargo using Helicopters.
--
-- **Features:**
-- 
--   * The helicopters will fly towards the pickup locations to pickup the cargo.
--   * The helicopters will fly towards the deploy zones to deploy the cargo.
--   * Precision deployment as well as randomized deployment within the deploy zones are possible.
--   * Helicopters will orbit the deploy zones when there is no space for landing until the deploy zone is free.
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
-- ## Note! In order to fully understand the mechanisms of the AI_CARGO_DISPATCHER_HELICOPTER class, it is recommended that you
-- ** first consult and READ the documentation of the @{AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER} !!!**
-- 
-- Especially to learn how to **Tailor the different cargo handling events**, this will be very useful!
-- 
-- On top, the AI_CARGO_DISPATCHER_HELICOPTER class uses the @{Cargo} capabilities within the MOOSE framework.
-- Also ensure that you fully understand how to declare and setup Cargo objects within the MOOSE framework before using this class.
-- CARGO derived objects must be declared within the mission to make the AI_CARGO_DISPATCHER_HELICOPTER object recognize the cargo.
-- 
-- ---
-- 
-- ## 1. AI\_CARGO\_DISPATCHER\_HELICOPTER constructor
--   
--   * @{#AI_CARGO_DISPATCHER\_HELICOPTER.New}(): Creates a new AI\_CARGO\_DISPATCHER\_HELICOPTER object.
-- 
-- ---
-- 
-- ## 2. AI\_CARGO\_DISPATCHER\_HELICOPTER is a FSM
-- 
-- ![Process](..\Presentations\AI_CARGO_DISPATCHER_HELICOPTER\Dia3.JPG)
-- 
-- ### 2.1. AI\_CARGO\_DISPATCHER\_HELICOPTER States
-- 
--   * **Monitoring**: The process is dispatching.
--   * **Idle**: The process is idle.
-- 
-- ### 2.2. AI\_CARGO\_DISPATCHER\_HELICOPTER Events
-- 
--   * **Monitor**: Monitor and take action.
--   * **Start**: Start the transport process.
--   * **Stop**: Stop the transport process.
--   * **Pickup**: Pickup cargo.
--   * **Load**: Load the cargo.
--   * **Loaded**: Flag that the cargo is loaded.
--   * **Deploy**: Deploy cargo to a location.
--   * **Unload**: Unload the cargo.
--   * **Unloaded**: Flag that the cargo is unloaded.
--   * **Home**: A Helicopter is going home.
-- 
-- ---
-- 
-- ## 3. Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER\_HELICOPTER.SetPickupRadius}(): Sets or randomizes the pickup location for the helicopter around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER\_HELICOPTER.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
-- 
-- ---   
--    
-- ## 4. Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER\_HELICOPTER.SetDeployRadius}(): Sets or randomizes the deploy location for the helicopter around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER\_HELICOPTER.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
-- 
-- ---
-- 
-- ## 5. Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the Helicopters will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER\_HELICOPTER.SetHomeZone}() to specify the home zone.
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
-- @param Core.Set#SET_GROUP HelicopterSet The collection of Helicopter @{Wrapper.Group}s.
-- @param Core.Set#SET_CARGO CargoSet The collection of @{Cargo} derived objects.
-- @param Core.Set#SET_ZONE PickupZoneSet (optional) The collection of pickup @{Zone}s, which are used to where the cargo can be picked up by the APCs. If nil, then cargo can be picked up everywhere. 
-- @param Core.Set#SET_ZONE DeployZoneSet The collection of deploy @{Zone}s, which are used to where the cargo will be deployed by the Helicopters. 
-- @return #AI_CARGO_DISPATCHER_HELICOPTER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- HelicopterSet = SET_GROUP:New():FilterPrefixes( "Helicopter" ):FilterStart()
-- CargoSet = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- DeployZoneSet = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER_HELICOPTER:New( HelicopterSet, SetCargo, nil, DeployZoneSet )
-- 
function AI_CARGO_DISPATCHER_HELICOPTER:New( HelicopterSet, CargoSet, PickupZoneSet, DeployZoneSet )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:NewWithZones( HelicopterSet, CargoSet, PickupZoneSet, DeployZoneSet ) ) -- #AI_CARGO_DISPATCHER_HELICOPTER

  self:SetDeploySpeed( 200, 150 )
  self:SetPickupSpeed( 200, 150 )
  self:SetPickupRadius( 0, 0 )
  self:SetDeployRadius( 0, 0 )
  
  return self
end

function AI_CARGO_DISPATCHER_HELICOPTER:AICargo( Helicopter, CargoSet )

  return AI_CARGO_HELICOPTER:New( Helicopter, CargoSet )
end

