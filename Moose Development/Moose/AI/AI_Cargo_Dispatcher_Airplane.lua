--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo using Planes.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Dispatcher_Airplane
-- @image AI_Cargo_Dispatching_For_Airplanes.JPG
-- 
--- @type AI_CARGO_DISPATCHER_AIRPLANE
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- Brings a dynamic cargo handling capability for AI groups.
-- 
-- Airplanes can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI_CARGO_DISPATCHER_AIRPLANE module uses the @{Cargo} capabilities within the MOOSE framework.
-- CARGO derived objects must be declared within the mission to make the AI_CARGO_DISPATCHER_AIRPLANE object recognize the cargo.
-- Please consult the @{Cargo} module for more information. 
-- 
-- 
-- 
-- @field #AI_CARGO_DISPATCHER_AIRPLANE
AI_CARGO_DISPATCHER_AIRPLANE = {
  ClassName = "AI_CARGO_DISPATCHER_AIRPLANE",
}

--- Creates a new AI_CARGO_DISPATCHER_AIRPLANE object.
-- @param #AI_CARGO_DISPATCHER_AIRPLANE self
-- @param Core.Set#SET_GROUP SetAirplanes Set of cargo transport airplanes.
-- @param Core.Set#SET_CARGO SetCargos Set of cargo, which is supposed to be transported.
-- @param Core.Set#SET_AIRBASE PickupAirbasesSet Set of airbases where the cargo has to be picked up.
-- @param Core.Set#SET_AIRBASE DeployAirbasesSet Set of airbases where the cargo is deployed. Choice for each cargo is random.
-- @return #AI_CARGO_DISPATCHER_AIRPLANE self
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetAirplanes = SET_GROUP:New():FilterPrefixes( "Airplane" ):FilterStart()
-- SetCargos = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- PickupAirbasesSet = SET_AIRBASE:New()
-- DeployAirbasesSet = SET_AIRBASE:New()
-- AICargoDispatcher = AI_CARGO_DISPATCHER_AIRPLANE:New( SetAirplanes, SetCargos, PickupAirbasesSet, DeployAirbasesSet )
-- 
function AI_CARGO_DISPATCHER_AIRPLANE:New( SetAirplanes, SetCargos, PickupAirbasesSet, DeployAirbasesSet )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:NewWithAirbases( SetAirplanes, SetCargos, PickupAirbasesSet, DeployAirbasesSet ) ) -- #AI_CARGO_DISPATCHER_AIRPLANE

  self:SetDeploySpeed( 200, 150 )
  self:SetPickupSpeed( 200, 150 )
  self:SetPickupRadius( 0, 0 )
  self:SetDeployRadius( 0, 0 )

  return self
end

function AI_CARGO_DISPATCHER_AIRPLANE:AICargo( Airplane, SetCargo )

  return AI_CARGO_AIRPLANE:New( Airplane, SetCargo )
end
