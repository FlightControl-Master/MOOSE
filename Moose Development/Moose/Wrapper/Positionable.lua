--- This module contains the POSITIONABLE class.
-- 
-- 1) @{Positionable#POSITIONABLE} class, extends @{Identifiable#IDENTIFIABLE}
-- ===========================================================
-- The @{Positionable#POSITIONABLE} class is a wrapper class to handle the POSITIONABLE objects:
--
--  * Support all DCS APIs.
--  * Enhance with POSITIONABLE specific APIs not in the DCS API set.
--  * Manage the "state" of the POSITIONABLE.
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

--- The POSITIONABLE class
-- @type POSITIONABLE
-- @extends Wrapper.Identifiable#IDENTIFIABLE
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
-- @param Dcs.DCSWrapper.Positionable#Positionable PositionableName The POSITIONABLE name
-- @return #POSITIONABLE self
function POSITIONABLE:New( PositionableName )
  local self = BASE:Inherit( self, IDENTIFIABLE:New( PositionableName ) )

  self.PositionableName = PositionableName
  return self
end

--- Returns the @{DCSTypes#Position3} position vectors indicating the point and direction vectors in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Position The 3D position vectors of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetPositionVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePosition = DCSPositionable:getPosition().p
    self:T3( PositionablePosition )
    return PositionablePosition
  end
  
  return nil
end

--- Returns the @{DCSTypes#Vec2} vector indicating the point in 2D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Vec2 The 2D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetVec2()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVec3 = DCSPositionable:getPosition().p
    
    local PositionableVec2 = {}
    PositionableVec2.x = PositionableVec3.x
    PositionableVec2.y = PositionableVec3.z
  
    self:T2( PositionableVec2 )
    return PositionableVec2
  end
  
  return nil
end

--- Returns a POINT_VEC2 object indicating the point in 2D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Core.Point#POINT_VEC2 The 2D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetPointVec2()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVec3 = DCSPositionable:getPosition().p
    
    local PositionablePointVec2 = POINT_VEC2:NewFromVec3( PositionableVec3 )
  
    self:T2( PositionablePointVec2 )
    return PositionablePointVec2
  end
  
  return nil
end

--- Returns a POINT_VEC3 object indicating the point in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Core.Point#POINT_VEC3 The 3D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetPointVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVec3 = self:GetPositionVec3()
    
    local PositionablePointVec3 = POINT_VEC3:NewFromVec3( PositionableVec3 )
  
    self:T2( PositionablePointVec3 )
    return PositionablePointVec3
  end
  
  return nil
end


--- Returns a random @{DCSTypes#Vec3} vector within a range, indicating the point in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @param #number Radius
-- @return Dcs.DCSTypes#Vec3 The 3D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
-- @usage 
-- -- If Radius is ignored, returns the Dcs.DCSTypes#Vec3 of first UNIT of the GROUP
function POSITIONABLE:GetRandomVec3( Radius )
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPosition().p
    
    if Radius then
      local PositionableRandomVec3 = {}
      local angle = math.random() * math.pi*2;
      PositionableRandomVec3.x = PositionablePointVec3.x + math.cos( angle ) * math.random() * Radius;
      PositionableRandomVec3.y = PositionablePointVec3.y
      PositionableRandomVec3.z = PositionablePointVec3.z + math.sin( angle ) * math.random() * Radius;
    
      self:T3( PositionableRandomVec3 )
      return PositionableRandomVec3
    else 
      self:E("Radius is nil, returning the PointVec3 of the POSITIONABLE", PositionablePointVec3)
      return PositionablePointVec3
    end
  end
  
  return nil
end

--- Returns the @{DCSTypes#Vec3} vector indicating the 3D vector of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Vec3 The 3D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVec3 = DCSPositionable:getPosition().p
    self:T3( PositionableVec3 )
    return PositionableVec3
  end
  
  return nil
end

--- Returns the altitude of the POSITIONABLE.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Distance The altitude of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetAltitude()
  self:F2()

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPoint() --Dcs.DCSTypes#Vec3
    return PositionablePointVec3.y
  end
  
  return nil
end 

--- Returns if the Positionable is located above a runway.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #boolean true if Positionable is above a runway.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:IsAboveRunway()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
  
    local Vec2 = self:GetVec2()
    local SurfaceType = land.getSurfaceType( Vec2 )
    local IsAboveRunway = SurfaceType == land.SurfaceType.RUNWAY
  
    self:T2( IsAboveRunway )
    return IsAboveRunway
  end

  return nil
end



--- Returns the POSITIONABLE heading in degrees.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number The POSTIONABLE heading
-- @return #nil The POSITIONABLE is not existing or alive.
function POSITIONABLE:GetHeading()
  local DCSPositionable = self:GetDCSObject()

  if DCSPositionable then

    local PositionablePosition = DCSPositionable:getPosition()
    if PositionablePosition then
      local PositionableHeading = math.atan2( PositionablePosition.x.z, PositionablePosition.x.x )
      if PositionableHeading < 0 then
        PositionableHeading = PositionableHeading + 2 * math.pi
      end
      PositionableHeading = PositionableHeading * 180 / math.pi
      self:T2( PositionableHeading )
      return PositionableHeading
    end
  end
  
  return nil
end


--- Returns true if the POSITIONABLE is in the air.
-- Polymorphic, is overridden in GROUP and UNIT.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #boolean true if in the air.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:InAir()
  self:F2( self.PositionableName )

  return nil
end

 
--- Returns the POSITIONABLE velocity vector.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Vec3 The velocity vector
-- @return #nil The POSITIONABLE is not existing or alive.  
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

--- Returns the POSITIONABLE velocity in km/h.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number The velocity in km/h
-- @return #nil The POSITIONABLE is not existing or alive.  
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

--- Returns a message with the callsign embedded (if there is one).
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
-- @return Core.Message#MESSAGE
function POSITIONABLE:GetMessage( Message, Duration, Name )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    Name = Name or self:GetTypeName()
    return MESSAGE:New( Message, Duration, self:GetCallsign() .. " (" .. Name .. ")" )
  end

  return nil
end

--- Send a message to all coalitions.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToAll( Message, Duration, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToAll()
  end

  return nil
end

--- Send a message to a coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTYpes#Duration Duration The duration of the message.
-- @param Dcs.DCScoalition#coalition MessageCoalition The Coalition receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToCoalition( Message, Duration, MessageCoalition, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToCoalition( MessageCoalition )
  end

  return nil
end


--- Send a message to the red coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTYpes#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToRed( Message, Duration, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToRed()
  end

  return nil
end

--- Send a message to the blue coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToBlue( Message, Duration, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToBlue()
  end

  return nil
end

--- Send a message to a client.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param Wrapper.Client#CLIENT Client The client object receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToClient( Message, Duration, Client, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToClient( Client )
  end

  return nil
end

--- Send a message to a @{Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param Wrapper.Group#GROUP MessageGroup The GROUP object receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToGroup( Message, Duration, MessageGroup, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    if DCSObject:isExist() then
      self:GetMessage( Message, Duration, Name ):ToGroup( MessageGroup )
    end
  end

  return nil
end

--- Send a message to the players in the @{Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:Message( Message, Duration, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToGroup( self )
  end

  return nil
end

--- Create a @{Radio#RADIO}, to allow radio transmission for this POSITIONABLE. 
-- Set parameters with the methods provided, then use RADIO:Broadcast() to actually broadcast the message
-- @param #POSITIONABLE self
-- @return #RADIO Radio
function POSITIONABLE:GetRadio()
  self:F2(self)
  return RADIO:New(self) 
end
