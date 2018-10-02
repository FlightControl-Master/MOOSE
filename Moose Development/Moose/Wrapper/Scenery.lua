--- **Wrapper** -- SCENERY models scenery within the DCS simulator.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Wrapper.Scenery
-- @image Wrapper_Scenery.JPG



--- @type SCENERY
-- @extends Wrapper.Positionable#POSITIONABLE


--- Wrapper class to handle Scenery objects that are defined on the map.
-- 
-- The @{Wrapper.Scenery#SCENERY} class is a wrapper class to handle the DCS Scenery objects:
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
