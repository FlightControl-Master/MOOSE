--- **AI** - Models the intelligent transportation of infantry and other cargo using APCs.
--
-- ## Features:
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
-- ## Note! In order to fully understand the mechanisms of the AI_CARGO_DISPATCHER_APC class, it is recommended that you first consult and READ the documentation of the @{AI.AI_Cargo_Dispatcher} module!!!
-- 
-- Especially to learn how to **Tailor the different cargo handling events**, this will be very useful!
-- 
-- On top, the AI_CARGO_DISPATCHER_APC class uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- Also ensure that you fully understand how to declare and setup Cargo objects within the MOOSE framework before using this class.
-- CARGO derived objects must be declared within the mission to make the AI_CARGO_DISPATCHER_HELICOPTER object recognize the cargo.
-- 
-- 
-- # 1) AI_CARGO_DISPATCHER_APC constructor.
--   
--   * @{#AI_CARGO_DISPATCHER_APC.New}(): Creates a new AI_CARGO_DISPATCHER_APC object.
-- 
-- ---
-- 
-- # 2) AI_CARGO_DISPATCHER_APC is a Finite State Machine.
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
-- # 3) Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER_APC.SetPickupRadius}(): Sets or randomizes the pickup location for the APC around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER_APC.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
--    
-- # 4) Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER_APC.SetDeployRadius}(): Sets or randomizes the deploy location for the APC around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER_APC.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
-- 
-- # 5) Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the APCs will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER_APC.SetHomeZone}() to specify the home zone.
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
-- @param Core.Set#SET_GROUP APCSet The set of @{Wrapper.Group#GROUP} objects of vehicles, trucks, APCs that will transport the cargo.
-- @param Core.Set#SET_CARGO CargoSet The set of @{Cargo.Cargo#CARGO} objects, which can be CARGO_GROUP, CARGO_CRATE, CARGO_SLINGLOAD objects.
-- @param Core.Set#SET_ZONE PickupZoneSet (optional) The set of pickup zones, which are used to where the cargo can be picked up by the APCs. If nil, then cargo can be picked up everywhere. 
-- @param Core.Set#SET_ZONE DeployZoneSet The set of deploy zones, which are used to where the cargo will be deployed by the APCs. 
-- @param DCS#Distance CombatRadius The cargo will be unloaded from the APC and engage the enemy if the enemy is within CombatRadius range. The radius is in meters, the default value is 500 meters.
-- @return #AI_CARGO_DISPATCHER_APC
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
function AI_CARGO_DISPATCHER_APC:New( APCSet, CargoSet, PickupZoneSet, DeployZoneSet, CombatRadius )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( APCSet, CargoSet, PickupZoneSet, DeployZoneSet ) ) -- #AI_CARGO_DISPATCHER_APC

  self:SetDeploySpeed( 120, 70 )
  self:SetPickupSpeed( 120, 70 )
  self:SetPickupRadius( 0, 0 )
  self:SetDeployRadius( 0, 0 )
  
  self:SetPickupHeight()
  self:SetDeployHeight()
  
  self:SetCombatRadius( CombatRadius )

  return self
end


--- AI cargo
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param Wrapper.Group#GROUP APC The APC carrier.
-- @param Core.Set#SET_CARGO CargoSet Cargo set.
-- @return AI.AI_Cargo_APC#AI_CARGO_DISPATCHER_APC AI cargo APC object.
function AI_CARGO_DISPATCHER_APC:AICargo( APC, CargoSet )

  local aicargoapc=AI_CARGO_APC:New(APC, CargoSet, self.CombatRadius)
  
  aicargoapc:SetDeployOffRoad(self.deployOffroad, self.deployFormation)
  aicargoapc:SetPickupOffRoad(self.pickupOffroad, self.pickupFormation)
  
  return aicargoapc
end

--- Enable/Disable unboarding of cargo (infantry) when enemies are nearby (to help defend the carrier).
-- This is only valid for APCs and trucks etc, thus ground vehicles.
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param #number CombatRadius Provide the combat radius to defend the carrier by unboarding the cargo when enemies are nearby. 
-- When the combat radius is 0 (default), no defense will happen of the carrier. 
-- When the combat radius is not provided, no defense will happen!
-- @return #AI_CARGO_DISPATCHER_APC
-- @usage
-- 
-- -- Disembark the infantry when the carrier is under attack.
-- AICargoDispatcher:SetCombatRadius( 500 )
-- 
-- -- Keep the cargo in the carrier when the carrier is under attack.
-- AICargoDispatcher:SetCombatRadius( 0 )
function AI_CARGO_DISPATCHER_APC:SetCombatRadius( CombatRadius )

  self.CombatRadius = CombatRadius or 0

  return self
end

--- Set whether the carrier will *not* use roads to *pickup* and *deploy* the cargo.
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param #boolean Offroad If true, carrier will not use roads.
-- @param #number Formation Offroad formation used. Default is `ENUMS.Formation.Vehicle.Offroad`.
-- @return #AI_CARGO_DISPATCHER_APC self
function AI_CARGO_DISPATCHER_APC:SetOffRoad(Offroad, Formation)

  self:SetPickupOffRoad(Offroad, Formation)
  self:SetDeployOffRoad(Offroad, Formation)
  
  return self
end

--- Set whether the carrier will *not* use roads to *pickup* the cargo.
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param #boolean Offroad If true, carrier will not use roads.
-- @param #number Formation Offroad formation used. Default is `ENUMS.Formation.Vehicle.Offroad`.
-- @return #AI_CARGO_DISPATCHER_APC self
function AI_CARGO_DISPATCHER_APC:SetPickupOffRoad(Offroad, Formation)

  self.pickupOffroad=Offroad
  self.pickupFormation=Formation or ENUMS.Formation.Vehicle.OffRoad
  
  return self
end

--- Set whether the carrier will *not* use roads to *deploy* the cargo.
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param #boolean Offroad If true, carrier will not use roads.
-- @param #number Formation Offroad formation used. Default is `ENUMS.Formation.Vehicle.Offroad`.
-- @return #AI_CARGO_DISPATCHER_APC self
function AI_CARGO_DISPATCHER_APC:SetDeployOffRoad(Offroad, Formation)

  self.deployOffroad=Offroad
  self.deployFormation=Formation or ENUMS.Formation.Vehicle.OffRoad
  
  return self
end