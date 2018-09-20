--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo using Planes.
--
-- **Features:**
--
--   * The airplanes will fly towards the pickup airbases to pickup the cargo.
--   * The airplanes will fly towards the deploy airbases to deploy the cargo.
--   
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Dispatcher_Airplane
-- @image AI_Cargo_Dispatching_For_Airplanes.JPG


--- @type AI_CARGO_DISPATCHER_AIRPLANE
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- Brings a dynamic cargo handling capability for AI groups.
-- 
-- Airplanes can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- 
-- The AI_CARGO_DISPATCHER_AIRPLANE module is derived from the AI_CARGO_DISPATCHER module.
-- 
-- ## Note! In order to fully understand the mechanisms of the AI_CARGO_DISPATCHER_AIRPLANE class, it is recommended that you
-- **first consult and READ the documentation of the @{AI.AI_Cargo_Dispatcher} module!!!**
-- 
-- Especially to learn how to **Tailor the different cargo handling events**, this will be very useful!
-- 
-- On top, the AI_CARGO_DISPATCHER_AIRPLANE class uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- Also ensure that you fully understand how to declare and setup Cargo objects within the MOOSE framework before using this class.
-- CARGO derived objects must be declared within the mission to make the AI_CARGO_DISPATCHER_HELICOPTER object recognize the cargo.
-- 
-- # 1) AI_CARGO_DISPATCHER_AIRPLANE constructor.
--   
--   * @{#AI_CARGO_DISPATCHER_AIRPLANE.New}(): Creates a new AI_CARGO_DISPATCHER_AIRPLANE object.
-- 
-- ---
-- 
-- # 2) AI_CARGO_DISPATCHER_AIRPLANE is a Finite State Machine.
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
-- 
-- 
-- @field #AI_CARGO_DISPATCHER_AIRPLANE
AI_CARGO_DISPATCHER_AIRPLANE = {
  ClassName = "AI_CARGO_DISPATCHER_AIRPLANE",
}

--- Creates a new AI_CARGO_DISPATCHER_AIRPLANE object.
-- @param #AI_CARGO_DISPATCHER_AIRPLANE self
-- @param Core.Set#SET_GROUP AirplaneSet The set of @{Wrapper.Group#GROUP} objects of airplanes that will transport the cargo.
-- @param Core.Set#SET_CARGO CargoSet The set of @{Cargo.Cargo#CARGO} objects, which can be CARGO_GROUP, CARGO_CRATE, CARGO_SLINGLOAD objects.
-- @param Core.Zone#SET_ZONE PickupZoneSet The set of zone airbases where the cargo has to be picked up.
-- @param Core.Zone#SET_ZONE DeployZoneSet The set of zone airbases where the cargo is deployed. Choice for each cargo is random.
-- @return #AI_CARGO_DISPATCHER_AIRPLANE self
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AirplaneSet = SET_GROUP:New():FilterPrefixes( "Airplane" ):FilterStart()
-- CargoSet = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- PickupZoneSet = SET_AIRBASE:New()
-- DeployZoneSet = SET_AIRBASE:New()
-- PickupZoneSet:AddZone( ZONE_AIRBASE:New( "Gudauta", AIRBASE:FindByName( AIRBASE.Caucasus.Gudauta ), 3000 ) )
-- DeployZoneSet:AddZone( ZONE_AIRBASE:New( "Sochi", AIRBASE:FindByName( AIRBASE.Caucasus.Sochi_Adler ), 3000 ) )
-- AICargoDispatcher = AI_CARGO_DISPATCHER_AIRPLANE:New( AirplaneSet, CargoSet, PickupZoneSet, DeployZoneSet )
-- 
function AI_CARGO_DISPATCHER_AIRPLANE:New( AirplaneSet, CargoSet, PickupZoneSet, DeployZoneSet )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:NewWithZones( AirplaneSet, CargoSet, PickupZoneSet, DeployZoneSet ) ) -- #AI_CARGO_DISPATCHER_AIRPLANE

  self:SetPickupSpeed( 1200, 600 )
  self:SetDeploySpeed( 1200, 600 )
  
  self:SetPickupRadius( 0, 0 )
  self:SetDeployRadius( 0, 0 )

  self:SetPickupHeight( 8000, 6000 )  
  self:SetDeployHeight( 8000, 6000 )
    
  self:SetMonitorTimeInterval( 600 )

  return self
end

function AI_CARGO_DISPATCHER_AIRPLANE:AICargo( Airplane, CargoSet )

  return AI_CARGO_AIRPLANE:New( Airplane, CargoSet )
end
