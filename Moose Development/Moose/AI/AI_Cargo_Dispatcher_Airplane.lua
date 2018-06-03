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
-- The AI\_CARGO\_DISPATCHER\_AIRPLANE module uses the @{Cargo} capabilities within the MOOSE framework.
-- CARGO derived objects must be declared within the mission to make the AI\_CARGO\_DISPATCHER\_AIRPLANE object recognize the cargo.
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
-- @param Core.Set#SET_GROUP SetAirplane
-- @param Core.Set#SET_CARGO SetCargo
-- @param Core.Set#SET_ZONE SetDeployZone
-- @return #AI_CARGO_DISPATCHER_AIRPLANE
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetAirplane = SET_GROUP:New():FilterPrefixes( "Airplane" ):FilterStart()
-- SetCargo = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- SetDeployZone = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER_AIRPLANE:New( SetAirplane, SetCargo )
-- 
function AI_CARGO_DISPATCHER_AIRPLANE:New( SetAirplane, SetCargo, SetDeployZones )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( SetAirplane, SetCargo, SetDeployZones ) ) -- #AI_CARGO_DISPATCHER_AIRPLANE

  return self
end


