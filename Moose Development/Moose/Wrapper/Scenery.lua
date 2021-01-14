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


function SCENERY:FindByName(id)
  local sceneryObject = nil
--if this is the first time thru this function, locate a land based airbase, and scan it for a valid scenery object
  if SCENERY.SceneryObject == nil then
-- iterate thru the list of 'airbases' to find a land based airbase.  Sea based airbases will not work. 
-- return the first land based airbase
    local getLandBase = function(airbases)
      for index,base in ipairs(airbases) do
        local pt = base:getPoint()
        local landtype = land.getSurfaceType({x = pt.x, y=pt.z})
        if landtype ~= land.SurfaceType.SHALLOW_WATER and landtype ~= land.SurfaceType.WATER then
          return base
        end
      end
    end
-- retrieve a list of airbases on the current map/mission 
    local base = world.getAirbases()
-- call function getLandBase() to get the first land based airbase, and save it's coords.
    local basecoord = getLandBase(base):getPoint()
    local foundUnits = {}
-- set up a 400m sphere around the coord of the found airbase to scan for scenery
    local searchsphere = 
    {
      id = world.VolumeType.SPHERE,
      params = 
      {
        point = basecoord,
        radius = 200,
      }
    }
-- function to add a scenery object to the list of 'foundUnits'
    local ifFound = function(foundItem, val)
      foundUnits[#foundUnits + 1] = foundItem
      return true
    end
-- search in the sphere 'searchsphere' for a SCENERY type object.
-- if a SCENERY object is found, call function ifFound() to add it to list.    
    local tempobjects = world.searchObjects(Object.Category.SCENERY, searchsphere, ifFound)
-- if any scenery was found in the sphere, add the first found object to the SCENERY template (SCENERY.SceneryObject    
    if tempobjects > 0 then
      sceneryObject = foundUnits[1]
      SCENERY.SceneryObject = foundUnits[1]
    end
  end
  if SCENERY.SceneryObject then
-- change the id of the found scenery object, register it, return it.
    SCENERY.SceneryObject.id_ = id
    local sceneryobject = SCENERY:Register(SCENERY.SceneryObject.id_,SCENERY.SceneryObject)
    return sceneryobject
  end
  return nil
end
