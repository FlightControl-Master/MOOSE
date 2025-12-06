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
-- @field #table Properties.
-- @field #number ID.
-- @field Core.Zone#ZONE_POLYGON SceneryZone.
-- @field Core.Point#COORDINATE Coordinate.
-- @field DCS#Vec2 Vec2.
-- @field DCS#Vec3 Vec3.
-- @field Core.Vector#VECTOR Vector.
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

_SCENERY = {}

--- Register scenery object as POSITIONABLE.
--@param #SCENERY self
--@param #string SceneryName Scenery name.
--@param DCS#Object SceneryObject DCS scenery object.
--@param Core.Zone#ZONE_POLYGON SceneryZone (optional) The zone object.
--@return #SCENERY Scenery object.
function SCENERY:Register( SceneryName, SceneryObject, SceneryZone )
  
  local ID = (SceneryObject and SceneryObject.getID) and SceneryObject:getID() or SceneryName
  
  if _SCENERY[ID] and _SCENERY[ID].SceneryObject == nil then 
  
    _SCENERY[ID].SceneryObject=SceneryObject 
    SCENERY._UpdateFromDCSObject(_SCENERY[ID])
    
  end
  
  if _SCENERY[ID] then return _SCENERY[ID] end
    
  local self = BASE:Inherit( self, POSITIONABLE:New( SceneryName ) )
  
  self.SceneryName = tostring(SceneryName)
  self.ID = ID
  self.SceneryObject = SceneryObject
  self.SceneryZone = SceneryZone
  
  if SceneryZone then
    self.Vec3 = SceneryZone:GetVec3()
    self.Vec2 = SceneryZone:GetVec2()
    self.Vector = (self.Vec3 and VECTOR) and VECTOR:NewFromVec(self.Vec3) or nil
  end

  if SceneryObject and SceneryObject.getPoint then
    local vec3 = SceneryObject:getPoint()
    self.Vec3 = { x = vec3.x, y = vec3.y, z = vec3.z }
    self.Vec2 = { x = vec3.x, y = vec3.z }
    self.Vector = (self.Vec3 and VECTOR) and VECTOR:NewFromVec(self.Vec3) or nil
  end
  
  if self.SceneryObject and self.SceneryObject.getLife then -- fix some objects do not have all functions
    self.Life0 = self.SceneryObject:getLife() or 1
  else
    self.Life0 = 1
  end
  
  self.Properties = {}
  
  _SCENERY[self.ID] = self
  
  return self
end


--- [INTERNAL] Update data 
-- @param Wrapper.Scenery#SCENERY Scenery The object to update.
function SCENERY._UpdateFromDCSObject(Scenery)
  env.info("APPLE _UpdateFromDCSObject "..tostring(Scenery.SceneryName))
  local self=Scenery
  if self.Vec2 == nil and self.SceneryObject ~= nil then
    self.Vec3 = self.SceneryObject:getPoint()
    if self.Vec3 then
      self.Vec2 = {x=self.Vec3.x,y=self.Vec3.z}
      self.Vector = VECTOR:NewFromVec(self.Vec3)
    end
  end
  if not self.Life0 or self.Life0 == 1 then 
    if self.SceneryObject and self.SceneryObject.getLife() then
      self.Life = self.SceneryObject:getLife() or 1
      self.Life0 = self.Life
    end
  end
  return self
end

--- Returns the value of the scenery with the given PropertyName, or nil if no matching property exists.
-- @param #SCENERY self
-- @param #string PropertyName The name of a the QuadZone Property from the scenery assignment to be retrieved.
-- @return #string The Value of the QuadZone Property from the scenery assignment with the given PropertyName, or nil if absent.
function SCENERY:GetProperty(PropertyName)
  return self.Properties[PropertyName]
end

--- Checks if the value of the scenery with the given PropertyName exists.
-- @param #SCENERY self
-- @param #string PropertyName The name of a the QuadZone Property from the scenery assignment to be retrieved.
-- @return #boolean Outcome True if it exists, else false.
function SCENERY:HasProperty(PropertyName)
  return self.Properties[PropertyName] ~= nil and true or false
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

--- Obtain object coordinate.
--@param #SCENERY self
--@return Core.Point#COORDINATE Coordinate
function SCENERY:GetCoordinate()
  if self.Coordinate then
    return self.Coordinate
  elseif self.Vec3 then
    self.Coordinate = COORDINATE:NewFromVec3(self.Vec3):SetAlt()
  end
  return self.Coordinate
end

--- Obtain object coordinate.
--@param #SCENERY self
--@return DCS#Vec3 Vec3
function SCENERY:GetVec3()
  return self.Vec3
end

--- Obtain object coordinate.
--@param #SCENERY self
--@return DCS#Vec2 Vec2
function SCENERY:GetVec2()
  return self.Vec2
end

--- Obtain object coordinate.
--@param #SCENERY self
--@return Core.Vector#VECTOR Vector
function SCENERY:GetVector()
  return self.Vector
end

--- Obtain DCS Object from the SCENERY Object.
--@param #SCENERY self
--@return DCS#Object DCS scenery object.
function SCENERY:GetDCSObject()
  return self.SceneryObject
end

--- Obtain object ID.
--@param #SCENERY self
--@return #string Name
function SCENERY:GetID()
  return self.ID
end

--- Get current life points from the SCENERY Object. Note - Some scenery objects always have 0 life points.
--  **CAVEAT**: Some objects change their life value or "hitpoints" **after** the first hit. Hence we will adjust the life0 value to 120% 
--  of the last life value if life exceeds life0 (initial life) at any point. Thus will will get a smooth percentage decrease, if you use this e.g. as success 
--  criteria for a bombing task.
--@param #SCENERY self
--@return #number life
function SCENERY:GetLife()
  local life = 1
  if self.SceneryObject and self.SceneryObject.getLife then
    life = self.SceneryObject:getLife()
    if life > self.Life0 then
      self.Life0 = math.floor(life * 1.2)
    end
  elseif self.Life then
    life = self.Life
  end
  return life
end

--- Get initial life points of the SCENERY Object.
--@param #SCENERY self
--@return #number life
function SCENERY:GetLife0()
  return self.Life0 or 0
end

--- Check if SCENERY Object is alive. Note - Some scenery objects always have 0 life points.
--@param #SCENERY self
--@param #number Threshold (Optional) If given, SCENERY counts as alive above this relative life in percent (1..100).
--@return #number life
function SCENERY:IsAlive(Threshold)
  if not Threshold then
    return self:GetLife() >= 1 and true or false
  else
    return self:GetRelativeLife() > Threshold and true or false
  end
end 

--- Check if SCENERY Object is dead. Note - Some scenery objects always have 0 life points.
--@param #SCENERY self
--@param #number Threshold (Optional) If given, SCENERY counts as dead below this relative life in percent (1..100).
--@return #number life
function SCENERY:IsDead(Threshold)
  if not Threshold then
    return self:GetLife() < 1 and true or false
  else
    return self:GetRelativeLife() <= Threshold and true or false
  end
end 

--- Get SCENERY relative life in percent, e.g. 75. Note - Some scenery objects always have 0 life points.
--@param #SCENERY self
--@return #number rlife
function SCENERY:GetRelativeLife()
  local life = self:GetLife()
  local life0 = self:GetLife0()
  if life == 0 or life0 == 0 then return 0 end
  local rlife = math.floor((life/life0)*100)
  return rlife
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
--@param #string Name The name/id of the scenery object as taken from the ME. Ex. '595785449'.
--@param Core.Point#COORDINATE Coordinate Where to find the scenery object.
--@param #number Radius (optional) Search radius around coordinate, defaults to 100.
--@param #string Role (optional) The role if set on the zone object.
--@param Core.Zone#ZONE_POLYGON Zone (optional) The Zone where the scenery is located.
--@return #SCENERY Scenery Object or `nil` if it cannot be found.
function SCENERY:FindByName(Name, Coordinate, Radius, Role, Zone)
  
  --BASE:I("Coordinate x = "..Coordinate.x .. " y = "..Coordinate.y.." z = "..Coordinate.z)
  
  local findme = self:_FindByName(Name)
  if findme then return findme end
  
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
      local scanzone = ZONE_RADIUS:New("Zone-"..sname,Vec2,sradius)
      scanzone:Scan({Object.Category.SCENERY})
      local scanned = scanzone:GetScannedSceneryObjects()
      local rscenery = nil -- Wrapper.Scenery#SCENERY
      for _,_scenery in pairs(scanned) do
        local scenery = _scenery -- Wrapper.Scenery#SCENERY
        --BASE:I({tostring(scenery.SceneryName),tostring(sname)})
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
    scenery = SceneryScan(Coordinate, radius, name)
  end
  
  if not scenery then scenery = SCENERY:Register(Name,nil,Zone) end
    
  return scenery  
end

--- Find a SCENERY object that was previously registered(!) by it's ID.
-- @param #SCENERY self
-- @param #number ID
-- @return Wrapper.Scenery#SCENERY Scenery or nil if it could not be found 
function SCENERY:FindByID(ID)
  return _SCENERY[ID]
end

--- Find a SCENERY object that was previously registered(!) by it's name.
-- @param #SCENERY self
-- @param #string Name
-- @return Wrapper.Scenery#SCENERY Scenery or nil if it could not be found 
function SCENERY:_FindByName(Name)
  for _id,_object in pairs(_SCENERY) do
    if _object and _object.GetName and _object:GetName() then
      local name = _object:GetName()
      if Name == name then return _object end
    end
  end
  return nil
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
  local coordinate = Zone:GetCoordinate():SetAlt()
  return self:FindByName(Name,coordinate,Radius,Zone:GetProperty("ROLE"),Zone)
end

--- Find a SCENERY object from its zone name. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object.
--@param #SCENERY self
--@param #string ZoneName The name of the scenery zone as created with a right-click on the map in the mission editor and select "assigned to...". Can be handed over as ZONE object.
--@return #SCENERY First found Scenery Object or `nil` if it cannot be found
function SCENERY:FindByZoneName( ZoneName )
  --BASE:I(ZoneName)

  local zone = ZoneName -- Core.Zone#ZONE_BASE

  if type(ZoneName) == "string" then
    zone = ZONE:FindByName(ZoneName)  -- Core.Zone#ZONE_POLYGON
  end

  local _id = zone:GetProperty('OBJECT ID')

  --BASE:I("Object ID ".._id)

  if not _id then
    -- this zone has no object ID
    BASE:E("**** Zone without object ID: "..ZoneName.." | Type: "..tostring(zone.ClassName))
    if string.find(zone.ClassName,"POLYGON") then
      zone:Scan({Object.Category.SCENERY})
      local scanned = zone:GetScannedSceneryObjects()
      for _,_scenery in (scanned) do
        local scenery = _scenery -- Wrapper.Scenery#SCENERY
        --if scenery:IsAlive() then
          local role = zone:GetProperty("ROLE")
          if role then scenery:SetProperty("ROLE",role) end
          return scenery
        --end
      end
      return nil
    else
      local coordinate = zone:GetCoordinate()
      coordinate:SetAlt()
      return self:FindByName(_id, coordinate,nil,zone:GetProperty("ROLE"),zone)
    end
  else
    local coordinate = zone:GetCoordinate()
    coordinate:SetAlt()
    return self:FindByName(_id, coordinate,nil,zone:GetProperty("ROLE"),zone)
  end
end

--- Scan and find all SCENERY objects from a zone by zone-name. Since SCENERY isn't registered in the Moose database (just too many objects per map), we need to do a scan first
-- to find the correct object. Might return nil!
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
    local obj = self:FindByName(_id, zone:GetCoordinate():SetAlt(),nil,zone:GetProperty("ROLE"), zone)
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
