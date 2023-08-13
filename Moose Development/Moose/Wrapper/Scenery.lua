--- **Wrapper** - SCENERY models scenery within the DCS simulator.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: **Applevangelist**, **funkyfranky**
-- 
-- ===
-- 
-- @module Wrapper.Scenery
-- @image Wrapper_Scenery.JPG


--- SCENERY Class
-- @type SCENERY
-- @field #string ClassName Name of the class.
-- @field #string SceneryName Name of the scenery object.
-- @field DCS#Object SceneryObject DCS scenery object.
-- @field #number Life0 Initial life points.
-- @field #table Properties
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
--@param DCS#Object SceneryObject DCS scenery object.
--@return #SCENERY Scenery object.
function SCENERY:Register( SceneryName, SceneryObject )

  local self = BASE:Inherit( self, POSITIONABLE:New( SceneryName ) )
  
  self.SceneryName = tostring(SceneryName)
  
  self.SceneryObject = SceneryObject
  
  if self.SceneryObject then
    self.Life0 = self.SceneryObject:getLife()
  else
    self.Life0 = 0
  end
  
  self.Properties = {}
  
  return self
end

--- Returns the Value of the zone with the given PropertyName, or nil if no matching property exists.
-- @param #SCENERY self
-- @param #string PropertyName The name of a the QuadZone Property from the scenery assignment to be retrieved.
-- @return #string The Value of the QuadZone Property from the scenery assignment with the given PropertyName, or nil if absent.
function SCENERY:GetProperty(PropertyName)
  return self.Properties[PropertyName]
end

--- Returns the scenery Properties table.
-- @param #SCENERY self
-- @return #table The Key:Value table of QuadZone properties of the zone from the scenery assignment .
function SCENERY:GetAllProperties()
  return self.Properties
end

--- Set a scenery property
-- @param #SCENERY self
-- @param #string PropertyName
-- @param #string PropertyValue
-- @return #SCENERY self
function SCENERY:SetProperty(PropertyName, PropertyValue)
  self.Properties[PropertyName] = PropertyValue
  return self
end
--- Obtain object name.
--@param #SCENERY self
--@return #string Name
function SCENERY:GetName()
  return self.SceneryName
end

--- Obtain DCS Object from the SCENERY Object.
--@param #SCENERY self
--@return DCS#Object DCS scenery object.
function SCENERY:GetDCSObject()
  return self.SceneryObject
end

--- Get current life points from the SCENERY Object.
--  **CAVEAT**: Some objects change their life value or "hitpoints" **after** the first hit. Hence we will adjust the life0 value to 120% 
--  of the last life value if life exceeds life0 (initial life) at any point. Thus will will get a smooth percentage decrease, if you use this e.g. as success 
--  criteria for a bombing task.
--@param #SCENERY self
--@return #number life
function SCENERY:GetLife()
  local life = 0
  if self.SceneryObject then
    life = self.SceneryObject:getLife()
    if life > self.Life0 then
      self.Life0 = math.floor(life * 1.2)
    end
  end
  return life
end

--- Get initial life points of the SCENERY Object.
--@param #SCENERY self
--@return #number life
function SCENERY:GetLife0()
  return self.Life0 or 0
end

--- Check if SCENERY Object is alive.
--@param #SCENERY self
--@return #number life
function SCENERY:IsAlive()
  return self:GetLife() >= 1 and true or false
end 

--- Check if SCENERY Object is dead.
--@param #SCENERY self
--@return #number life
function SCENERY:IsDead()
  return self:GetLife() < 1 and true or false
end 

--- Get the threat level of a SCENERY object. Always 0 as scenery does not pose a threat to anyone.
--@param #SCENERY self
--@return #number Threat level 0.
--@return #string  "Scenery".
function SCENERY:GetThreatLevel()
  return 0, "Scenery"
end

--- Find a SCENERY object from its name or id. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string Name The name/id of the scenery object as taken from the ME. Ex. '595785449'
--@param Core.Point#COORDINATE Coordinate Where to find the scenery object
--@param #number Radius (optional) Search radius around coordinate, defaults to 100
--@return #SCENERY Scenery Object or `nil` if it cannot be found
function SCENERY:FindByName(Name, Coordinate, Radius, Role)

  local radius = Radius or 100
  local name = Name or "unknown"
  local scenery = nil
  
  ---
  -- @param Core.Point#COORDINATE coordinate
  -- @param #number radius
  -- @param #string name
  local function SceneryScan(scoordinate, sradius, sname)
    if scoordinate ~= nil then
      local Vec2 = scoordinate:GetVec2()
      local scanzone = ZONE_RADIUS:New("Zone-"..sname,Vec2,sradius,true)
      scanzone:Scan({Object.Category.SCENERY})
      local scanned = scanzone:GetScannedSceneryObjects()
      local rscenery = nil -- Wrapper.Scenery#SCENERY
      for _,_scenery in pairs(scanned) do
        local scenery = _scenery -- Wrapper.Scenery#SCENERY
        if tostring(scenery.SceneryName) == tostring(sname) then
          rscenery = scenery
          if Role then rscenery:SetProperty("ROLE",Role) end
          break
        end
      end
      return rscenery
    end
    return nil
  end
  
  if Coordinate then
    --BASE:I("Coordinate Scenery Scan")
    scenery = SceneryScan(Coordinate, radius, name)
  end

  return scenery  
end

--- Find a SCENERY object from its name or id. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string Name The name or id of the scenery object as taken from the ME. Ex. '595785449'
--@param Core.Zone#ZONE_BASE Zone Where to find the scenery object. Can be handed as zone name.
--@param #number Radius (optional) Search radius around coordinate, defaults to 100
--@return #SCENERY Scenery Object or `nil` if it cannot be found
function SCENERY:FindByNameInZone(Name, Zone, Radius)   
  local radius = Radius or 100
  local name = Name or "unknown"
  if type(Zone) == "string" then
    Zone = ZONE:FindByName(Zone)
  end
  local coordinate = Zone:GetCoordinate()
  return self:FindByName(Name,coordinate,Radius,Zone:GetProperty("ROLE"))
end

--- Find a SCENERY object from its zone name. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string ZoneName The name of the scenery zone as created with a right-click on the map in the mission editor and select "assigned to...". Can be handed over as ZONE object.
--@return #SCENERY First found Scenery Object or `nil` if it cannot be found
function SCENERY:FindByZoneName( ZoneName )
  local zone = ZoneName -- Core.Zone#ZONE_BASE
  if type(ZoneName) == "string" then
    zone = ZONE:FindByName(ZoneName)  -- Core.Zone#ZONE_POLYGON
  end
  local _id = zone:GetProperty('OBJECT ID')
  --local properties = zone:GetAllProperties() or {}
  --BASE:I(string.format("Object ID is: %s",_id or "none"))
  --BASE:T("Object ID ".._id)
  if not _id then
    -- this zone has no object ID
    BASE:E("**** Zone without object ID: "..ZoneName.." | Type: "..tostring(zone.ClassName))
    if string.find(zone.ClassName,"POLYGON") then
      zone:Scan({Object.Category.SCENERY})
      local scanned = zone:GetScannedSceneryObjects()
      for _,_scenery in (scanned) do
        local scenery = _scenery -- Wrapper.Scenery#SCENERY
        if scenery:IsAlive() then
          local role = zone:GetProperty("ROLE")
          if role then scenery:SetProperty("ROLE",role) end
          return scenery
        end
      end
      return nil
    else
      return self:FindByName(_id, zone:GetCoordinate(),nil,zone:GetProperty("ROLE"))
    end
  else
    return self:FindByName(_id, zone:GetCoordinate(),nil,zone:GetProperty("ROLE"))
  end
end

--- Scan and find all SCENERY objects from a zone by zone-name. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string ZoneName The name of the zone, can be handed as ZONE_RADIUS or ZONE_POLYGON object
--@return #table of SCENERY Objects, or `nil` if nothing found
function SCENERY:FindAllByZoneName( ZoneName )
  local zone = ZoneName -- Core.Zone#ZONE_RADIUS
  if type(ZoneName) == "string" then
    zone = ZONE:FindByName(ZoneName) 
  end
  local _id = zone:GetProperty('OBJECT ID')
  --local properties = zone:GetAllProperties() or {}
  if not _id then
    -- this zone has no object ID
    --BASE:E("**** Zone without object ID: "..ZoneName.." | Type: "..tostring(zone.ClassName))
    zone:Scan({Object.Category.SCENERY})
    local scanned = zone:GetScannedSceneryObjects()
    if #scanned > 0 then
      return scanned
    else
      return nil
    end
  else
    local obj = self:FindByName(_id, zone:GetCoordinate(),nil,zone:GetProperty("ROLE"))
    if obj then
      return {obj}
    else
      return nil
    end 
  end
end

--- SCENERY objects cannot be destroyed via the API (at the punishment of game crash).
--@param #SCENERY self
--@return #SCENERY self
function SCENERY:Destroy()
  return self
end
