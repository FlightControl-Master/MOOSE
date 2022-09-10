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

--- Find a SCENERY object by it's name/id.
--@param #SCENERY self
--@param #string name The name/id of the scenery object as taken from the ME. Ex. '595785449'
--@return #SCENERY Scenery Object or nil if not found.
function SCENERY:FindByName(name)
  local findAirbase = function ()
    local airbases = AIRBASE.GetAllAirbases()
    for index,airbase in pairs(airbases) do
      local surftype = airbase:GetCoordinate():GetSurfaceType()
      if surftype ~= land.SurfaceType.SHALLOW_WATER and surftype ~= land.SurfaceType.WATER then
        return airbase:GetCoordinate()
      end
    end
    return nil
  end

  local sceneryScan = function (scancoord)
    if scancoord ~= nil then
      local _,_,sceneryfound,_,_,scenerylist = scancoord:ScanObjects(200, false, false, true)
      if sceneryfound == true then 
        scenerylist[1].id_ = name
        SCENERY.SceneryObject = SCENERY:Register(scenerylist[1].id_, scenerylist[1])
        return SCENERY.SceneryObject
      end
    end
    return nil
  end
  
  if SCENERY.SceneryObject then
    SCENERY.SceneryObject.SceneryObject.id_ = name
    SCENERY.SceneryObject.SceneryName = name
    return SCENERY:Register(SCENERY.SceneryObject.SceneryObject.id_, SCENERY.SceneryObject.SceneryObject)
  else
    return sceneryScan(findAirbase())
  end
end
