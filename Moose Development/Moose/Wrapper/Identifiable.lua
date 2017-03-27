--- This module contains the IDENTIFIABLE class.
-- 
-- 1) @{#IDENTIFIABLE} class, extends @{Object#OBJECT}
-- ===============================================================
-- The @{#IDENTIFIABLE} class is a wrapper class to handle the DCS Identifiable objects:
--
--  * Support all DCS Identifiable APIs.
--  * Enhance with Identifiable specific APIs not in the DCS Identifiable API set.
--  * Manage the "state" of the DCS Identifiable.
--
-- 1.1) IDENTIFIABLE constructor:
-- ------------------------------
-- The IDENTIFIABLE class provides the following functions to construct a IDENTIFIABLE instance:
--
--  * @{#IDENTIFIABLE.New}(): Create a IDENTIFIABLE instance.
--
-- 1.2) IDENTIFIABLE methods:
-- --------------------------
-- The following methods can be used to identify an identifiable object:
-- 
--    * @{#IDENTIFIABLE.GetName}(): Returns the name of the Identifiable.
--    * @{#IDENTIFIABLE.IsAlive}(): Returns if the Identifiable is alive.
--    * @{#IDENTIFIABLE.GetTypeName}(): Returns the type name of the Identifiable.
--    * @{#IDENTIFIABLE.GetCoalition}(): Returns the coalition of the Identifiable.
--    * @{#IDENTIFIABLE.GetCountry}(): Returns the country of the Identifiable.
--    * @{#IDENTIFIABLE.GetDesc}(): Returns the descriptor structure of the Identifiable.
--    
-- 
-- ===
-- 
-- @module Identifiable

--- The IDENTIFIABLE class
-- @type IDENTIFIABLE
-- @extends Wrapper.Object#OBJECT
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
-- @param Dcs.DCSWrapper.Identifiable#Identifiable IdentifiableName The DCS Identifiable name
-- @return #IDENTIFIABLE self
function IDENTIFIABLE:New( IdentifiableName )
  local self = BASE:Inherit( self, OBJECT:New( IdentifiableName ) )
  self:F2( IdentifiableName )
  self.IdentifiableName = IdentifiableName
  return self
end

--- Returns if the Identifiable is alive.  
-- If the Identifiable is not alive, nil is returned.  
-- If the Identifiable is alive, true is returned.  
-- @param #IDENTIFIABLE self
-- @return #boolean true if Identifiable is alive.
-- @return #nil if the Identifiable is not existing or is not alive.  
function IDENTIFIABLE:IsAlive()
  self:F3( self.IdentifiableName )

  local DCSIdentifiable = self:GetDCSObject() -- Dcs.DCSObject#Object
  
  if DCSIdentifiable then
    local IdentifiableIsAlive  = DCSIdentifiable:isExist()
    return IdentifiableIsAlive
  end 
  
  return false
end




--- Returns DCS Identifiable object name. 
-- The function provides access to non-activated objects too.
-- @param #IDENTIFIABLE self
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
-- @param #IDENTIFIABLE self
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


--- Returns category of the DCS Identifiable.
-- @param #IDENTIFIABLE self
-- @return Dcs.DCSWrapper.Object#Object.Category The category ID
function IDENTIFIABLE:GetCategory()
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local ObjectCategory = DCSObject:getCategory()
    self:T3( ObjectCategory )
    return ObjectCategory
  end

  return nil
end


--- Returns the DCS Identifiable category name as defined within the DCS Identifiable Descriptor.
-- @param #IDENTIFIABLE self
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
-- @param #IDENTIFIABLE self
-- @return Dcs.DCSCoalitionWrapper.Object#coalition.side The side of the coalition.
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
-- @param #IDENTIFIABLE self
-- @return Dcs.DCScountry#country.id The country identifier.
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
-- @param #IDENTIFIABLE self
-- @return Dcs.DCSWrapper.Identifiable#Identifiable.Desc The Identifiable descriptor.
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

--- Gets the CallSign of the IDENTIFIABLE, which is a blank by default.
-- @param #IDENTIFIABLE self
-- @return #string The CallSign of the IDENTIFIABLE.
function IDENTIFIABLE:GetCallsign()
  return ''
end


function IDENTIFIABLE:GetThreatLevel()

  return 0, "Scenery"
end
