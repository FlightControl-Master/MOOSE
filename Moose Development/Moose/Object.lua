--- This module contains the OBJECT class.
-- 
-- 1) @{Object#OBJECT} class, extends @{Base#BASE}
-- ===========================================================
-- The @{Object#OBJECT} class is a wrapper class to handle the DCS Object objects:
--
--  * Support all DCS Object APIs.
--  * Enhance with Object specific APIs not in the DCS Object API set.
--  * Manage the "state" of the DCS Object.
--
-- 1.1) OBJECT constructor:
-- ------------------------------
-- The OBJECT class provides the following functions to construct a OBJECT instance:
--
--  * @{Object#OBJECT.New}(): Create a OBJECT instance.
--
-- 1.2) OBJECT methods:
-- --------------------------
-- The following methods can be used to identify an Object object:
-- 
--    * @{Object#OBJECT.GetID}(): Returns the ID of the Object object.
-- 
-- ===
-- 
-- @module Object
-- @author FlightControl

--- The OBJECT class
-- @type OBJECT
-- @extends Base#BASE
-- @field #string ObjectName The name of the Object.
OBJECT = {
  ClassName = "OBJECT",
  ObjectName = "",
}


--- A DCSObject
-- @type DCSObject
-- @field id_ The ID of the controllable in DCS

--- Create a new OBJECT from a DCSObject
-- @param #OBJECT self
-- @param DCSObject#Object ObjectName The Object name
-- @return #OBJECT self
function OBJECT:New( ObjectName )
  local self = BASE:Inherit( self, BASE:New() )
  self:F2( ObjectName )
  self.ObjectName = ObjectName
  return self
end


--- Returns if the Object is alive.
-- @param Object#OBJECT self
-- @return #boolean true if Object is alive.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:IsAlive()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectIsAlive = DCSObject:isExist()
    return ObjectIsAlive
  end 
  
  return false
end




--- Returns DCS Object object name. 
-- The function provides access to non-activated objects too.
-- @param Object#OBJECT self
-- @return #string The name of the DCS Object.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetName()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectName = self.ObjectName
    return ObjectName
  end 
  
  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end


--- Returns the type name of the DCS Object.
-- @param Object#OBJECT self
-- @return #string The type name of the DCS Object.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetTypeName()
  self:F2( self.ObjectName )
  
  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectTypeName = DCSObject:getTypeName()
    self:T3( ObjectTypeName )
    return ObjectTypeName
  end

  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end

--- Returns the Object's callsign - the localized string.
-- @param Object#OBJECT self
-- @return #string The Callsign of the Object.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetCallSign()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectCallSign = DCSObject:getCallsign()
    return ObjectCallSign
  end
  
  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end


--- Returns the DCS Object category name as defined within the DCS Object Descriptor.
-- @param Object#OBJECT self
-- @return #string The DCS Object Category Name
function OBJECT:GetCategoryName()
  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectCategoryName = _CategoryName[ self:GetDesc().category ]
    return ObjectCategoryName
  end
  
  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end

--- Returns coalition of the Object.
-- @param Object#OBJECT self
-- @return DCSCoalitionObject#coalition.side The side of the coalition.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetCoalition()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectCoalition = DCSObject:getCoalition()
    self:T3( ObjectCoalition )
    return ObjectCoalition
  end 
  
  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end

--- Returns country of the Object.
-- @param Object#OBJECT self
-- @return DCScountry#country.id The country identifier.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetCountry()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectCountry = DCSObject:getCountry()
    self:T3( ObjectCountry )
    return ObjectCountry
  end 
  
  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end
 


--- Returns Object descriptor. Descriptor type depends on Object category.
-- @param Object#OBJECT self
-- @return DCSObject#Object.Desc The Object descriptor.
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetDesc()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectDesc = DCSObject:getDesc()
    self:T2( ObjectDesc )
    return ObjectDesc
  end
  
  self:E( self.ClassName .. " " .. self.ObjectName .. " not found!" )
  return nil
end









