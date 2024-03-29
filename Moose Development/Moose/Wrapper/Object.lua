--- **Wrapper** - OBJECT wraps the DCS Object derived objects.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: **funkyfranky
-- 
-- ===
-- 
-- @module Wrapper.Object
-- @image MOOSE.JPG


--- OBJECT class.
-- @type OBJECT
-- @extends Core.Base#BASE
-- @field #string ObjectName The name of the Object.


--- Wrapper class to handle the DCS Object objects.
--
--  * Support all DCS Object APIs.
--  * Enhance with Object specific APIs not in the DCS Object API set.
--  * Manage the "state" of the DCS Object.
--
-- ## OBJECT constructor:
-- 
-- The OBJECT class provides the following functions to construct a OBJECT instance:
--
--  * @{Wrapper.Object#OBJECT.New}(): Create a OBJECT instance.
--
-- @field #OBJECT
OBJECT = {
  ClassName = "OBJECT",
  ObjectName = "",
}

--- A DCSObject
-- @type DCSObject
-- @field id_ The ID of the controllable in DCS

--- Create a new OBJECT from a DCSObject
-- @param #OBJECT self
-- @param DCS#Object ObjectName The Object name
-- @return #OBJECT self
function OBJECT:New( ObjectName)

  -- Inherit BASE class.
  local self = BASE:Inherit( self, BASE:New() )
  
  -- Debug output.
  self:F2( ObjectName )
  
  -- Set object name.
  self.ObjectName = ObjectName

  return self
end


--- Returns the unit's unique identifier.
-- @param Wrapper.Object#OBJECT self
-- @return DCS#Object.ID ObjectID or #nil if the DCS Object is not existing or alive. Note that the ID is passed as a string and not a number. 
function OBJECT:GetID()

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectID = DCSObject:getID()
    return ObjectID
  end 

  self:E( { "Cannot GetID", Name = self.ObjectName, Class = self:GetClassName() } )

  return nil
end

--- Destroys the OBJECT.
-- @param #OBJECT self
-- @return #boolean Returns `true` if the object is destroyed or #nil if the object is nil.
function OBJECT:Destroy()

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    --BASE:CreateEventCrash( timer.getTime(), DCSObject )
    DCSObject:destroy( false )
    return true
  end

  self:E( { "Cannot Destroy", Name = self.ObjectName, Class = self:GetClassName() } )

  return nil
end






