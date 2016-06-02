--- AIRBASE Class
-- 
-- @{AIRBASE} class
-- ==============
-- The @{AIRBASE} class is a wrapper class to handle the DCS Airbase objects:
-- 
--  * Support all DCS Airbase APIs.
--  * Enhance with Airbase specific APIs not in the DCS Airbase API set.
--  
--  
-- AIRBASE reference methods
-- ====================== 
-- For each DCS Airbase object alive within a running mission, a AIRBASE wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts).
--  
-- The AIRBASE class **does not contain a :New()** method, rather it provides **:Find()** methods to retrieve the object reference
-- using the DCS Airbase or the DCS AirbaseName.
-- 
-- Another thing to know is that AIRBASE objects do not "contain" the DCS Airbase object. 
-- The AIRBASE methods will reference the DCS Airbase object by name when it is needed during API execution.
-- If the DCS Airbase object does not exist or is nil, the AIRBASE methods will return nil and log an exception in the DCS.log file.
--  
-- The AIRBASE class provides the following functions to retrieve quickly the relevant AIRBASE instance:
-- 
--  * @{#AIRBASE.Find}(): Find a AIRBASE instance from the _DATABASE object using a DCS Airbase object.
--  * @{#AIRBASE.FindByName}(): Find a AIRBASE instance from the _DATABASE object using a DCS Airbase name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these AIRBASE OBJECT REFERENCES! (make the AIRBASE object references nil).
-- 
-- DCS AIRBASE APIs
-- =============
-- The DCS Airbase APIs are used extensively within MOOSE. The AIRBASE class has for each DCS Airbase API a corresponding method.
-- To be able to distinguish easily in your code the difference between a AIRBASE API call and a DCS Airbase API call,
-- the first letter of the method is also capitalized. So, by example, the DCS Airbase method @{DCSAirbase#Airbase.getName}()
-- is implemented in the AIRBASE class as @{#AIRBASE.GetName}().
-- 
-- More functions will be added
-- ----------------------------
-- During the MOOSE development, more functions will be added. 
-- 
-- @module Airbase
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- The AIRBASE class
-- @type AIRBASE
-- @extends Base#BASE
AIRBASE = {
  ClassName="AIRBASE",
  CategoryName = { 
    [Airbase.Category.AIRDROME]   = "Airdrome",
    [Airbase.Category.HELIPAD]    = "Helipad",
    [Airbase.Category.SHIP]       = "Ship",
    },
  }

-- Registration.
  
--- Create a new AIRBASE from DCSAirbase.
-- @param #AIRBASE self
-- @param DCSAirbase#Airbase DCSAirbase
-- @param Database#DATABASE Database
-- @return Airbase#AIRBASE
function AIRBASE:Register( AirbaseName )

  local self = BASE:Inherit( self, BASE:New() )
  self:F2( AirbaseName )
  self.AirbaseName = AirbaseName
  return self
end

-- Reference methods.

--- Finds a AIRBASE from the _DATABASE using a DCSAirbase object.
-- @param #AIRBASE self
-- @param DCSAirbase#Airbase DCSAirbase An existing DCS Airbase object reference.
-- @return Airbase#AIRBASE self
function AIRBASE:Find( DCSAirbase )

  local AirbaseName = DCSAirbase:getName()
  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

--- Find a AIRBASE in the _DATABASE using the name of an existing DCS Airbase.
-- @param #AIRBASE self
-- @param #string AirbaseName The Airbase Name.
-- @return Airbase#AIRBASE self
function AIRBASE:FindByName( AirbaseName )
  
  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

function AIRBASE:GetDCSAirbase()
  local DCSAirbase = Airbase.getByName( self.AirbaseName )
  
  if DCSAirbase then
    return DCSAirbase
  end
    
  return nil
end

--- Returns coalition of the Airbase.
-- @param Airbase#AIRBASE self
-- @return DCSCoalitionObject#coalition.side The side of the coalition.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetCoalition()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseCoalition = DCSAirbase:getCoalition()
    self:T3( AirbaseCoalition )
    return AirbaseCoalition
  end 
  
  return nil
end

--- Returns country of the Airbase.
-- @param Airbase#AIRBASE self
-- @return DCScountry#country.id The country identifier.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetCountry()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseCountry = DCSAirbase:getCountry()
    self:T3( AirbaseCountry )
    return AirbaseCountry
  end 
  
  return nil
end
 

--- Returns DCS Airbase object name. 
-- The function provides access to non-activated units too.
-- @param Airbase#AIRBASE self
-- @return #string The name of the DCS Airbase.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetName()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseName = self.AirbaseName
    return AirbaseName
  end 
  
  return nil
end


--- Returns if the airbase is alive.
-- @param Airbase#AIRBASE self
-- @return #boolean true if Airbase is alive.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:IsAlive()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseIsAlive = DCSAirbase:isExist()
    return AirbaseIsAlive
  end 
  
  return false
end

--- Returns the unit's unique identifier.
-- @param Airbase#AIRBASE self
-- @return DCSAirbase#Airbase.ID Airbase ID
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetID()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseID = DCSAirbase:getID()
    return AirbaseID
  end 

  return nil
end

--- Returns the Airbase's callsign - the localized string.
-- @param Airbase#AIRBASE self
-- @return #string The Callsign of the Airbase.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetCallSign()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseCallSign = DCSAirbase:getCallsign()
    return AirbaseCallSign
  end
  
  return nil
end



--- Returns unit descriptor. Descriptor type depends on unit category.
-- @param Airbase#AIRBASE self
-- @return DCSAirbase#Airbase.Desc The Airbase descriptor.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetDesc()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseDesc = DCSAirbase:getDesc()
    return AirbaseDesc
  end
  
  return nil
end


--- Returns the type name of the DCS Airbase.
-- @param Airbase#AIRBASE self
-- @return #string The type name of the DCS Airbase.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetTypeName()
  self:F2( self.AirbaseName )
  
  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseTypeName = DCSAirbase:getTypeName()
    self:T3( AirbaseTypeName )
    return AirbaseTypeName
  end

  return nil
end


--- Returns the @{DCSTypes#Vec2} vector indicating the point in 2D of the DCS Airbase within the mission.
-- @param Airbase#AIRBASE self
-- @return DCSTypes#Vec2 The 2D point vector of the DCS Airbase.
-- @return #nil The DCS Airbase is not existing or alive.  
function AIRBASE:GetPointVec2()
  self:F2( self.AirbaseName )

  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbasePointVec3 = DCSAirbase:getPosition().p
    
    local AirbasePointVec2 = {}
    AirbasePointVec2.x = AirbasePointVec3.x
    AirbasePointVec2.y = AirbasePointVec3.z
  
    self:T3( AirbasePointVec2 )
    return AirbasePointVec2
  end
  
  return nil
end

--- Returns the DCS Airbase category name as defined within the DCS Airbase Descriptor.
-- @param Airbase#AIRBASE self
-- @return #string The DCS Airbase Category Name
function AIRBASE:GetCategoryName()
  local DCSAirbase = self:GetDCSAirbase()
  
  if DCSAirbase then
    local AirbaseCategoryName = self.CategoryName[ self:GetDesc().category ]
    return AirbaseCategoryName
  end
  
  return nil
end

