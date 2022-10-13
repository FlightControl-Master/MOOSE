--- **Wrapper** -- SCENERY models scenery within the DCS simulator.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: **Applevangelist**
-- 
-- ===
-- 
-- @module Wrapper.Scenery
-- @image Wrapper_Scenery.JPG



--- @type SCENERY
-- @field #string ClassName
-- @field #string SceneryName
-- @field #DCS.Object SceneryObject
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

--- Obtain DCS Object from the SCENERY Object.
--@param #SCENERY self
--@return #DCS.Object DCS scenery object.
function SCENERY:GetDCSObject()
  return self.SceneryObject
end

--- Get the threat level of a SCENERY object. Always 0.
--@param #SCENERY self
--@return #number Threat level 0.
--@return #string  "Scenery".
function SCENERY:GetThreatLevel()
  return 0, "Scenery"
end

--- Find a SCENERY object from it's name/id. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string Name The name/id of the scenery object as taken from the ME. Ex. '595785449'
--@param Core.Point#COORDINATE Coordinate Where to find the scenery object
--@param #number Radius (optional) Search radius around coordinate, defaults to 100
--@return #SCENERY Scenery Object or `nil` if it cannot be found
function SCENERY:FindByName(Name, Coordinate, Radius)
   
  local radius = Radius or 100
  local name = Name or "unknown"
  local scenery = nil
  
  ---
  -- @param Core.Point#COORDINATE coordinate
  -- @param #number radius
  -- @param #string name
  local function SceneryScan (coordinate, radius, name)
    if coordinate ~= nil then
      local scenerylist = coordinate:ScanScenery(radius)
      local rscenery = nil
      for _,_scenery in pairs(scenerylist) do
        local scenery = _scenery -- Wrapper.Scenery#SCENERY
        if tostring(scenery.SceneryName) == tostring(name) then
          rscenery = scenery
          break
        end
      end
      return rscenery
    end
    return nil
  end
  
  if Coordinate then
    scenery = SceneryScan(Coordinate, radius, name)
  end

  return scenery  
end

--- Find a SCENERY object from it's name/id. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string Name The name/id of the scenery object as taken from the ME. Ex. '595785449'
--@param Core.Zone#ZONE Zone Where to find the scenery object. Can be handed as zone name.
--@param #number Radius (optional) Search radius around coordinate, defaults to 100
--@return #SCENERY Scenery Object or `nil` if it cannot be found
function SCENERY:FindByNameInZone(Name, Zone, Radius)   
  local radius = Radius or 100
  local name = Name or "unknown"
  if type(Zone) == "string" then
    Zone = ZONE:FindByName(Zone)
  end
  local coordinate = Zone:GetCoordinate()
  return self:FindByName(Name,coordinate,Radius)  
end
