--- **Wrapper** -- OBJECT wraps the DCS Object derived objects.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Object


--- @type OBJECT
-- @extends Core.Base#BASE
-- @field #string ObjectName The name of the Object.


--- # OBJECT class, extends @{Base#BASE}
-- 
-- OBJECT handles the DCS Object objects:
--
--  * Support all DCS Object APIs.
--  * Enhance with Object specific APIs not in the DCS Object API set.
--  * Manage the "state" of the DCS Object.
--
-- ## OBJECT constructor:
-- 
-- The OBJECT class provides the following functions to construct a OBJECT instance:
--
--  * @{Object#OBJECT.New}(): Create a OBJECT instance.
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
-- @param Dcs.DCSWrapper.Object#Object ObjectName The Object name
-- @return #OBJECT self
function OBJECT:New( ObjectName, Test )
  local self = BASE:Inherit( self, BASE:New() )
  self:F2( ObjectName )
  self.ObjectName = ObjectName

  return self
end


--- Returns the unit's unique identifier.
-- @param Wrapper.Object#OBJECT self
-- @return Dcs.DCSWrapper.Object#Object.ID ObjectID
-- @return #nil The DCS Object is not existing or alive.  
function OBJECT:GetID()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local ObjectID = DCSObject:getID()
    return ObjectID
  end 

  return nil
end

--- Destroys the OBJECT.
-- @param #OBJECT self
-- @return #nil The DCS Unit is not existing or alive.  
function OBJECT:Destroy()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    USERFLAG:New( self:GetGroup():GetName() ):Set( 100 )
    --BASE:CreateEventCrash( timer.getTime(), DCSObject )
    DCSObject:destroy()
  end

  return nil
end




