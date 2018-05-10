--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo using APCs.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Dispatcher_APC

--- @type AI_CARGO_DISPATCHER_APC
-- @extends AI.AI_Cargo_Dispatcher#AI_CARGO_DISPATCHER


--- # AI\_CARGO\_DISPATCHER\_APC class, extends @{Core.Base#BASE}
-- 
-- ===
-- 
-- AI\_CARGO\_DISPATCHER\_APC brings a dynamic cargo handling capability for AI groups.
-- 
-- Armoured Personnel APCs (APC), Trucks, Jeeps and other carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI\_CARGO\_DISPATCHER\_APC module uses the @{Cargo} capabilities within the MOOSE framework.
-- CARGO derived objects must be declared within the mission to make the AI\_CARGO\_DISPATCHER\_APC object recognize the cargo.
-- Please consult the @{Cargo} module for more information. 
-- 
-- 
-- 
-- @field #AI_CARGO_DISPATCHER_APC
AI_CARGO_DISPATCHER_APC = {
  ClassName = "AI_CARGO_DISPATCHER_APC",
}

--- Creates a new AI_CARGO_DISPATCHER_APC object.
-- @param #AI_CARGO_DISPATCHER_APC self
-- @param Core.Set#SET_GROUP SetAPC
-- @param Core.Set#SET_CARGO SetCargo
-- @param Core.Set#SET_ZONE SetDeployZone
-- @return #AI_CARGO_DISPATCHER_APC
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetAPC = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
-- SetCargo = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- SetDeployZone = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER_APC:New( SetAPC, SetCargo )
-- 
function AI_CARGO_DISPATCHER_APC:New( SetAPC, SetCargo, SetDeployZones )

  local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZones ) ) -- #AI_CARGO_DISPATCHER_APC

  return self
end


