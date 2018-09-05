--- **AI** -- (2.4) - Models the intelligent transportation of infantry and other cargo using APCs.
--
-- **Features:**
-- 
--   * Quickly transport cargo to various deploy zones using ground vehicles (APCs, trucks ...).
--   * Various @{Cargo.Cargo#CARGO} types can be transported. These are infantry groups and crates.
--   * Define a list of deploy zones of various types to transport the cargo to.
--   * The vehicles follow the roads to ensure the fastest possible cargo transportation over the ground.
--   * Multiple vehicles can transport multiple cargo as one vehicle group.
--   * Multiple vehicle groups can be enabled as one collaborating transportation process.
--   * Infantry loaded as cargo, will unboard in case enemies are nearby and will help defending the vehicles.
--   * Different ranges can be setup for enemy defenses.
--   * Different options can be setup to tweak the cargo transporation behaviour.
--  
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Dispatcher_APC
-- @image AI_Cargo_Dispatching_For_APC.JPG

--- @type AI_CARGO_DISPATCHER_APC
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- A dynamic cargo transportation capability for AI groups.
-- 
-- Armoured Personnel APCs (APC), Trucks, Jeeps and other carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- 
-- The AI_CARGO_DISPATCHER_APC module is derived from the AI_CARGO_DISPATCHER module.
-- 
-- ## Note! In order to fully understand the mechanisms of the AI_CARGO_DISPATCHER_APC class, it is recommended that you
-- ** first consult and READ the documentation of the @{AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER} !!!**
-- 
-- Especially to learn how to **Tailor the different cargo handling events**, this will be very useful!
-- 
-- On top, the AI_CARGO_DISPATCHER_APC class uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- Also ensure that you fully understand how to declare and setup Cargo objects within the MOOSE framework before using this class.
-- CARGO derived objects must be declared within the mission to make the AI_CARGO_DISPATCHER_HELICOPTER object recognize the cargo.
-- 
-- 
-- ## 1. AI\_CARGO\_DISPATCHER\_APC constructor
--   
--   * @{#AI_CARGO_DISPATCHER\_APC.New}(): Creates a new AI\_CARGO\_DISPATCHER\_APC object.
-- 
-- ## 2. AI\_CARGO\_DISPATCHER\_APC is a FSM
-- 
-- ![Process](..\Presentations\AI_CARGO_DISPATCHER_APC\Dia3.JPG)
-- 
-- ### 2.1. AI\_CARGO\_DISPATCHER\_APC States
-- 
--   * **Monitoring**: The process is dispatching.
--   * **Idle**: The process is idle.
-- 
-- ### 2.2. AI\_CARGO\_DISPATCHER\_APC Events
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
--   * **Home**: A APC is going home.
-- 
-- ## 3. Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER\_APC.SetPickupRadius}(): Sets or randomizes the pickup location for the APC around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER\_APC.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
--    
-- ## 4. Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER\_APC.SetDeployRadius}(): Sets or randomizes the deploy location for the APC around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER\_APC.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
-- 
-- ## 5. Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the APCs will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER\_APC.SetHomeZone}() to specify the home zone.
-- 
-- If no home zone is specified, the APCs will wait near the deploy zone for a new pickup command.   
-- 
-- ===
-- 
-- @field #AI_CARGO_DISPATCHER_APC
AI_CARGO_DISPATCHER_APC = {
  ClassName = "AI_CARGO_DISPATCHER_APC",
}

--- Creates a new AI_CARGO_DISPATCHER_APC object.
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param Core.Set#SET_GROUP APCSet The collection of APC @{Wrapper.Group}s.
-- @param Core.Set#SET_CARGO CargoSet The collection of @{Cargo.Cargo} derived objects.
-- @param Core.Set#SET_ZONE PickupZoneSet (optional) The collection of pickup @{Zone}s, which are used to where the cargo can be picked up by the APCs. If nil, then cargo can be picked up everywhere. 
-- @param Core.Set#SET_ZONE DeployZoneSet The collection of deploy @{Zone}s, which are used to where the cargo will be deployed by the APCs. 
-- @param DCS#Distance CombatRadius The cargo will be unloaded from the APC and engage the enemy if the enemy is within CombatRadius range. The radius is in meters, the default value is 500 meters.
-- @return #AI_CARGO_DISPATCHER_APC
-- @usage
-- 
-- -- Create a new cargo dispatcher for the set of APCs, with a combatradius of 500.
-- APCSet = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
-- CargoSet = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- DeployZoneSet = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER_APC:New( APCSet, SCargoSet, nil, DeployZoneSet, 500 )
-- 
function AI_CARGO_DISPATCHER_APC:New( APCSet, CargoSet, PickupZoneSet, DeployZoneSet, CombatRadius )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:NewWithZones( APCSet, CargoSet, PickupZoneSet, DeployZoneSet ) ) -- #AI_CARGO_DISPATCHER_APC

  self.CombatRadius = CombatRadius or 500

  self:SetDeploySpeed( 70, 120 )
  self:SetPickupSpeed( 70, 120 )
  self:SetPickupRadius( 0, 0 )
  self:SetDeployRadius( 0, 0 )

  return self
end


function AI_CARGO_DISPATCHER_APC:AICargo( APC, CargoSet )

  return AI_CARGO_APC:New( APC, CargoSet, self.CombatRadius )
end
