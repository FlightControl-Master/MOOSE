--- This module contains the POSITIONABLE class.
-- 
-- 1) @{Positionable#POSITIONABLE} class, extends @{Identifiable#IDENTIFIABLE}
-- ===========================================================
-- The @{Positionable#POSITIONABLE} class is a wrapper class to handle the DCS Positionable objects:
--
--  * Support all DCS Positionable APIs.
--  * Enhance with Positionable specific APIs not in the DCS Positionable API set.
--  * Manage the "state" of the DCS Positionable.
--
-- 1.1) POSITIONABLE constructor:
-- ------------------------------
-- The POSITIONABLE class provides the following functions to construct a POSITIONABLE instance:
--
--  * @{Positionable#POSITIONABLE.New}(): Create a POSITIONABLE instance.
--
-- 1.2) POSITIONABLE methods:
-- --------------------------
-- The following methods can be used to identify an measurable object:
-- 
--    * @{Positionable#POSITIONABLE.GetID}(): Returns the ID of the measurable object.
--    * @{Positionable#POSITIONABLE.GetName}(): Returns the name of the measurable object.
-- 
-- ===
-- 
-- @module Positionable
-- @author FlightControl

--- The POSITIONABLE class
-- @type POSITIONABLE
-- @extends Identifiable#IDENTIFIABLE
-- @field #string PositionableName The name of the measurable.
POSITIONABLE = {
  ClassName = "POSITIONABLE",
  PositionableName = "",
}

--- A DCSPositionable
-- @type DCSPositionable
-- @field id_ The ID of the controllable in DCS

--- Create a new POSITIONABLE from a DCSPositionable
-- @param #POSITIONABLE self
-- @param DCSPositionable#Positionable PositionableName The DCS Positionable name
-- @return #POSITIONABLE self
function POSITIONABLE:New( PositionableName )
  local self = BASE:Inherit( self, IDENTIFIABLE:New( PositionableName ) )

  return self
end

--- Returns the @{DCSTypes#Position3} position vectors indicating the point and direction vectors in 3D of the DCS Positionable within the mission.
-- @param Positionable#POSITIONABLE self
-- @return DCSTypes#Position The 3D position vectors of the DCS Positionable.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetPositionVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePosition = DCSPositionable:getPosition()
    self:T3( PositionablePosition )
    return PositionablePosition
  end
  
  return nil
end

--- Returns the @{DCSTypes#Vec2} vector indicating the point in 2D of the DCS Positionable within the mission.
-- @param Positionable#POSITIONABLE self
-- @return DCSTypes#Vec2 The 2D point vector of the DCS Positionable.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetVec2()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPosition().p
    
    local PositionablePointVec2 = {}
    PositionablePointVec2.x = PositionablePointVec3.x
    PositionablePointVec2.y = PositionablePointVec3.z
  
    self:T2( PositionablePointVec2 )
    return PositionablePointVec2
  end
  
  return nil
end


--- Returns a random @{DCSTypes#Vec3} vector within a range, indicating the point in 3D of the DCS Positionable within the mission.
-- @param Positionable#POSITIONABLE self
-- @return DCSTypes#Vec3 The 3D point vector of the DCS Positionable.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetRandomPointVec3( Radius )
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPosition().p
    local PositionableRandomPointVec3 = {}
    local angle = math.random() * math.pi*2;
    PositionableRandomPointVec3.x = PositionablePointVec3.x + math.cos( angle ) * math.random() * Radius;
    PositionableRandomPointVec3.y = PositionablePointVec3.y
    PositionableRandomPointVec3.z = PositionablePointVec3.z + math.sin( angle ) * math.random() * Radius;
    
    self:T3( PositionableRandomPointVec3 )
    return PositionableRandomPointVec3
  end
  
  return nil
end

--- Returns the @{DCSTypes#Vec3} vector indicating the point in 3D of the DCS Positionable within the mission.
-- @param Positionable#POSITIONABLE self
-- @return DCSTypes#Vec3 The 3D point vector of the DCS Positionable.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetPointVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPosition().p
    self:T3( PositionablePointVec3 )
    return PositionablePointVec3
  end
  
  return nil
end

--- Returns the altitude of the DCS Positionable.
-- @param Positionable#POSITIONABLE self
-- @return DCSTypes#Distance The altitude of the DCS Positionable.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetAltitude()
  self:F2()

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPoint() --DCSTypes#Vec3
    return PositionablePointVec3.y
  end
  
  return nil
end 

--- Returns if the Positionable is located above a runway.
-- @param Positionable#POSITIONABLE self
-- @return #boolean true if Positionable is above a runway.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:IsAboveRunway()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
  
    local PointVec2 = self:GetVec2()
    local SurfaceType = land.getSurfaceType( PointVec2 )
    local IsAboveRunway = SurfaceType == land.SurfaceType.RUNWAY
  
    self:T2( IsAboveRunway )
    return IsAboveRunway
  end

  return nil
end



--- Returns the DCS Positionable heading.
-- @param Positionable#POSITIONABLE self
-- @return #number The DCS Positionable heading
function POSITIONABLE:GetHeading()
  local DCSPositionable = self:GetDCSObject()

  if DCSPositionable then

    local PositionablePosition = DCSPositionable:getPosition()
    if PositionablePosition then
      local PositionableHeading = math.atan2( PositionablePosition.x.z, PositionablePosition.x.x )
      if PositionableHeading < 0 then
        PositionableHeading = PositionableHeading + 2 * math.pi
      end
      self:T2( PositionableHeading )
      return PositionableHeading
    end
  end
  
  return nil
end


--- Returns true if the DCS Positionable is in the air.
-- @param Positionable#POSITIONABLE self
-- @return #boolean true if in the air.
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:InAir()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableInAir = DCSPositionable:inAir()
    self:T3( PositionableInAir )
    return PositionableInAir
  end
  
  return nil
end
 
--- Returns the DCS Positionable velocity vector.
-- @param Positionable#POSITIONABLE self
-- @return DCSTypes#Vec3 The velocity vector
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetVelocity()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVelocityVec3 = DCSPositionable:getVelocity()
    self:T3( PositionableVelocityVec3 )
    return PositionableVelocityVec3
  end
  
  return nil
end

--- Returns the @{Unit#UNIT} velocity in km/h.
-- @param Positionable#POSITIONABLE self
-- @return #number The velocity in km/h
-- @return #nil The DCS Positionable is not existing or alive.  
function POSITIONABLE:GetVelocityKMH()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local VelocityVec3 = self:GetVelocity()
    local Velocity = ( VelocityVec3.x ^ 2 + VelocityVec3.y ^ 2 + VelocityVec3.z ^ 2 ) ^ 0.5 -- in meters / sec
    local Velocity = Velocity * 3.6 -- now it is in km/h.
    self:T3( Velocity )
    return Velocity
  end
  
  return nil
end




