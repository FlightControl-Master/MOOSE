--- **Wrapper** -- SCENERY models scenery within the DCS simulator.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Scenery



--- @type SCENERY
-- @extends Wrapper.Positionable#POSITIONABLE


--- # SCENERY class, extends @{Positionable#POSITIONABLE}
-- 
-- Scenery objects are defined on the map.
-- The @{Scenery#SCENERY} class is a wrapper class to handle the DCS Scenery objects:
-- 
--  * Wraps the DCS Scenery objects.
--  * Support all DCS Scenery APIs.
--  * Enhance with Scenery specific APIs not in the DCS API set.
--  
--  @field #SCENERY
SCENERY = {
	ClassName = "SCENERY",
}


function SCENERY:Register( SceneryName, SceneryObject )
  local self = BASE:Inherit( self, POSITIONABLE:New( SceneryName ) )
  self.SceneryName = SceneryName
  self.SceneryObject = SceneryObject
  return self
end

function SCENERY:GetDCSObject()
  return self.SceneryObject
end

function SCENERY:GetThreatLevel()

  return 0, "Scenery"
end
