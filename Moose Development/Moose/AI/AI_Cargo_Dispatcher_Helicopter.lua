--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo using Helicopters.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Dispatcher_Helicopter

--- @type AI_CARGO_DISPATCHER_HELICOPTER
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- # AI\_CARGO\_DISPATCHER\_HELICOPTER class, extends @{Core.Base#BASE}
-- 
-- ===
-- 
-- AI\_CARGO\_DISPATCHER\_HELICOPTER brings a dynamic cargo handling capability for AI groups.
-- 
-- Helicopters can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI\_CARGO\_DISPATCHER\_HELICOPTER module uses the @{Cargo} capabilities within the MOOSE framework.
-- CARGO derived objects must be declared within the mission to make the AI\_CARGO\_DISPATCHER\_HELICOPTER object recognize the cargo.
-- Please consult the @{Cargo} module for more information. 
-- 
-- 
-- 
-- @field #AI_CARGO_DISPATCHER_HELICOPTER
AI_CARGO_DISPATCHER_HELICOPTER = {
  ClassName = "AI_CARGO_DISPATCHER_HELICOPTER",
}

--- Creates a new AI_CARGO_DISPATCHER_HELICOPTER object.
-- @param #AI_CARGO_DISPATCHER_HELICOPTER self
-- @param Core.Set#SET_GROUP SetAPC
-- @param Core.Set#SET_CARGO SetCargo
-- @param Core.Set#SET_ZONE SetDeployZone
-- @return #AI_CARGO_DISPATCHER_HELICOPTER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetHelicopter = SET_GROUP:New():FilterPrefixes( "Helicopter" ):FilterStart()
-- SetCargo = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- SetDeployZone = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargo )
-- 
function AI_CARGO_DISPATCHER_HELICOPTER:New( SetHelicopter, SetCargo, SetDeployZones )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( SetHelicopter, SetCargo, SetDeployZones ) ) -- #AI_CARGO_DISPATCHER_HELICOPTER

  return self
end


