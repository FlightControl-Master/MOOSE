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
-- 
-- 
-- @field #AI_CARGO_DISPATCHER_AIRPLANE
AI_CARGO_DISPATCHER_AIRPLANE = {
  ClassName = "AI_CARGO_DISPATCHER_AIRPLANE",
}

--- Creates a new AI_CARGO_DISPATCHER_AIRPLANE object.
-- @param #AI_CARGO_DISPATCHER_AIRPLANE self
-- @param Core.Set#SET_GROUP AirplaneSet Set of cargo transport airplanes.
-- @param Core.Set#SET_CARGO CargoSet Set of cargo, which is supposed to be transported.
-- @param Core.Zone#SET_ZONE PickupZoneSet Set of zone airbases where the cargo has to be picked up.
-- @param Core.Zone#SET_ZONE DeployZoneSet Set of zone airbases where the cargo is deployed. Choice for each cargo is random.
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

  self:SetDeploySpeed( 1200, 600 )
  self:SetPickupSpeed( 1200, 600 )
  self:SetPickupRadius( 0, 0 )
  self:SetDeployRadius( 0, 0 )

  return self
end

function AI_CARGO_DISPATCHER_AIRPLANE:AICargo( Airplane, CargoSet )

  return AI_CARGO_AIRPLANE:New( Airplane, CargoSet )
end
