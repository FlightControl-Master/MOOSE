--- This module contains the IDENTIFIABLE class.
-- 
-- 1) @{Identifiable#IDENTIFIABLE} class, extends @{Object#OBJECT}
-- ===============================================================
-- The @{Identifiable#IDENTIFIABLE} class is a wrapper class to handle the DCS Identifiable objects:
--
--  * Support all DCS Identifiable APIs.
--  * Enhance with Identifiable specific APIs not in the DCS Identifiable API set.
--  * Manage the "state" of the DCS Identifiable.
--
-- 1.1) IDENTIFIABLE constructor:
-- ------------------------------
-- The IDENTIFIABLE class provides the following functions to construct a IDENTIFIABLE instance:
--
--  * @{Identifiable#IDENTIFIABLE.New}(): Create a IDENTIFIABLE instance.
--
-- 1.2) IDENTIFIABLE methods:
-- --------------------------
-- The following methods can be used to identify an identifiable object:
-- 
--    * @{Identifiable#IDENTIFIABLE.GetName}(): Returns the name of the Identifiable.
--    * @{Identifiable#IDENTIFIABLE.IsAlive}(): Returns if the Identifiable is alive.
--    * @{Identifiable#IDENTIFIABLE.GetTypeName}(): Returns the type name of the Identifiable.
--    * @{Identifiable#IDENTIFIABLE.GetCoalition}(): Returns the coalition of the Identifiable.
--    * @{Identifiable#IDENTIFIABLE.GetCountry}(): Returns the country of the Identifiable.
--    * @{Identifiable#IDENTIFIABLE.GetDesc}(): Returns the descriptor structure of the Identifiable.
--    
-- 
-- ===
-- 
-- @module Identifiable
-- @author FlightControl

--- The IDENTIFIABLE class
-- @type IDENTIFIABLE
-- @extends Object#OBJECT
-- @field #string IdentifiableName The name of the identifiable.
IDENTIFIABLE = {
  ClassName = "IDENTIFIABLE",
  IdentifiableName = "",
}

local _CategoryName = { 
  [Unit.Category.AIRPLANE]      = "Airplane",
  [Unit.Category.HELICOPTER]    = "Helicoper",
  [Unit.Category.GROUND_UNIT]   = "Ground Identifiable",
  [Unit.Category.SHIP]          = "Ship",
  [Unit.Category.STRUCTURE]     = "Structure",
  }

--- Create a new IDENTIFIABLE from a DCSIdentifiable
-- @param #IDENTIFIABLE self
-- @param DCSIdentifiable#Identifiable IdentifiableName The DCS Identifiable name
-- @return #IDENTIFIABLE self
function IDENTIFIABLE:New( IdentifiableName )
  local self = BASE:Inherit( self, BASE:New() )
  self:F2( IdentifiableName )
  self.IdentifiableName = IdentifiableName
  return self
end

--- Returns if the Identifiable is alive.
-- @param Identifiable#IDENTIFIABLE self
-- @return #boolean true if Identifiable is alive.
-- @return #nil The DCS Identifiable is not existing or alive.  
function IDENTIFIABLE:IsAlive()
  self:F2( self.IdentifiableName )

  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableIsAlive = DCSIdentifiable:isExist()
    return IdentifiableIsAlive
  end 
  
  return false
end




--- Returns DCS Identifiable object name. 
-- The function provides access to non-activated objects too.
-- @param Identifiable#IDENTIFIABLE self
-- @return #string The name of the DCS Identifiable.
-- @return #nil The DCS Identifiable is not existing or alive.  
function IDENTIFIABLE:GetName()
  self:F2( self.IdentifiableName )

  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableName = self.IdentifiableName
    return IdentifiableName
  end 
  
  self:E( self.ClassName .. " " .. self.IdentifiableName .. " not found!" )
  return nil
end


--- Returns the type name of the DCS Identifiable.
-- @param Identifiable#IDENTIFIABLE self
-- @return #string The type name of the DCS Identifiable.
-- @return #nil The DCS Identifiable is not existing or alive.  
function IDENTIFIABLE:GetTypeName()
  self:F2( self.IdentifiableName )
  
  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableTypeName = DCSIdentifiable:getTypeName()
    self:T3( IdentifiableTypeName )
    return IdentifiableTypeName
  end

  self:E( self.ClassName .. " " .. self.IdentifiableName .. " not found!" )
  return nil
end




--- Returns the DCS Identifiable category name as defined within the DCS Identifiable Descriptor.
-- @param Identifiable#IDENTIFIABLE self
-- @return #string The DCS Identifiable Category Name
function IDENTIFIABLE:GetCategoryName()
  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableCategoryName = _CategoryName[ self:GetDesc().category ]
    return IdentifiableCategoryName
  end
  
  self:E( self.ClassName .. " " .. self.IdentifiableName .. " not found!" )
  return nil
end

--- Returns coalition of the Identifiable.
-- @param Identifiable#IDENTIFIABLE self
-- @return DCSCoalitionObject#coalition.side The side of the coalition.
-- @return #nil The DCS Identifiable is not existing or alive.  
function IDENTIFIABLE:GetCoalition()
  self:F2( self.IdentifiableName )

  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableCoalition = DCSIdentifiable:getCoalition()
    self:T3( IdentifiableCoalition )
    return IdentifiableCoalition
  end 
  
  self:E( self.ClassName .. " " .. self.IdentifiableName .. " not found!" )
  return nil
end

--- Returns country of the Identifiable.
-- @param Identifiable#IDENTIFIABLE self
-- @return DCScountry#country.id The country identifier.
-- @return #nil The DCS Identifiable is not existing or alive.  
function IDENTIFIABLE:GetCountry()
  self:F2( self.IdentifiableName )

  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableCountry = DCSIdentifiable:getCountry()
    self:T3( IdentifiableCountry )
    return IdentifiableCountry
  end 
  
  self:E( self.ClassName .. " " .. self.IdentifiableName .. " not found!" )
  return nil
end
 


--- Returns Identifiable descriptor. Descriptor type depends on Identifiable category.
-- @param Identifiable#IDENTIFIABLE self
-- @return DCSIdentifiable#Identifiable.Desc The Identifiable descriptor.
-- @return #nil The DCS Identifiable is not existing or alive.  
function IDENTIFIABLE:GetDesc()
  self:F2( self.IdentifiableName )

  local DCSIdentifiable = self:GetDCSObject()
  
  if DCSIdentifiable then
    local IdentifiableDesc = DCSIdentifiable:getDesc()
    self:T2( IdentifiableDesc )
    return IdentifiableDesc
  end
  
  self:E( self.ClassName .. " " .. self.IdentifiableName .. " not found!" )
  return nil
end









