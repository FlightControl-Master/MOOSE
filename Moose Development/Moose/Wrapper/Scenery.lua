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


--- Register scenery object as POSITIONABLE.
--@param #SCENERY self
--@param #string SceneryName Scenery name.
--@param #DCS.Object SceneryObject DCS scenery object.
--@return #SCENERY Scenery object.
function SCENERY:Register( SceneryName, SceneryObject )
  local self = BASE:Inherit( self, POSITIONABLE:New( SceneryName ) )
  self.SceneryName = SceneryName
  self.SceneryObject = SceneryObject
  return self
end

--- Register scenery object as POSITIONABLE.
--@param #SCENERY self
--@return #DCS.Object DCS scenery object.
function SCENERY:GetDCSObject()
  return self.SceneryObject
end

--- Register scenery object as POSITIONABLE.
--@param #SCENERY self
--@return #number Threat level 0.
--@return #string  "Scenery".
function SCENERY:GetThreatLevel()
  return 0, "Scenery"
end
