--- **Wrapper** -- POSITIONABLE wraps DCS classes that are "positionable".
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Positionable

--- @type POSITIONABLE.__ Methods which are not intended for mission designers, but which are used interally by the moose designer :-)
-- @extends Wrapper.Identifiable#IDENTIFIABLE

--- @type POSITIONABLE
-- @extends Wrapper.Identifiable#IDENTIFIABLE


--- # POSITIONABLE class, extends @{Identifiable#IDENTIFIABLE}
-- 
-- The POSITIONABLE class is a wrapper class to handle the POSITIONABLE objects:
--
--  * Support all DCS APIs.
--  * Enhance with POSITIONABLE specific APIs not in the DCS API set.
--  * Manage the "state" of the POSITIONABLE.
--
-- ## POSITIONABLE constructor
-- 
-- The POSITIONABLE class provides the following functions to construct a POSITIONABLE instance:
--
--  * @{#POSITIONABLE.New}(): Create a POSITIONABLE instance.
-- 
-- ## Get the current speed
-- 
-- There are 3 methods that can be used to determine the speed.
-- Use @{#POSITIONABLE.GetVelocityKMH}() to retrieve the current speed in km/h. Use @{#POSITIONABLE.GetVelocityMPS}() to retrieve the speed in meters per second.
-- The method @{#POSITIONABLE.GetVelocity}() returns the speed vector (a Vec3).
-- 
-- ## Get the current altitude
-- 
-- Altitude can be retrieved using the method @{#POSITIONABLE.GetHeight}() and returns the current altitude in meters from the orthonormal plane.
-- 
-- 
-- @field #POSITIONABLE 
POSITIONABLE = {
  ClassName = "POSITIONABLE",
  PositionableName = "",
}

--- @field #POSITIONABLE.__
POSITIONABLE.__ = {}

--- @field #POSITIONABLE.__.Cargo
POSITIONABLE.__.Cargo = {}


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

--- Returns a COORDINATE object indicating the point in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Core.Point#COORDINATE The COORDINATE of the POSITIONABLE.
function POSITIONABLE:GetCoordinate()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVec3 = self:GetPositionVec3()
    
    local PositionableCoordinate = COORDINATE:NewFromVec3( PositionableVec3 )
    PositionableCoordinate:SetHeading( self:GetHeading() )
    PositionableCoordinate:SetVelocity( self:GetVelocityMPS() )
  
    self:T2( PositionableCoordinate )
    return PositionableCoordinate
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


--- Get the bounding box of the underlying POSITIONABLE DCS Object.
-- @param #POSITIONABLE self
-- @return Dcs.DCSTypes#Distance The bounding box of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetBoundingBox() --R2.1
  self:F2()

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableDesc = DCSPositionable:getDesc() --Dcs.DCSTypes#Desc
    if PositionableDesc then
      local PositionableBox = PositionableDesc.box
      return PositionableBox
    end
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


--- Returns the a @{Velocity} object from the positionable.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Core.Velocity#VELOCITY Velocity The Velocity object.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetVelocity()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local Velocity = VELOCITY:New( self )
    return Velocity
  end
  
  return nil
end


 
--- Returns the POSITIONABLE velocity Vec3 vector.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Vec3 The velocity Vec3 vector
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetVelocityVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVelocityVec3 = DCSPositionable:getVelocity()
    self:T3( PositionableVelocityVec3 )
    return PositionableVelocityVec3
  end
  
  return nil
end


--- Returns the POSITIONABLE height in meters.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Vec3 The height of the positionable.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetHeight() --R2.1
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePosition = DCSPositionable:getPosition()
    if PositionablePosition then
      local PositionableHeight = PositionablePosition.p.y
      self:T2( PositionableHeight )
      return PositionableHeight
    end
  end
  
  return nil
end


--- Returns the POSITIONABLE velocity in km/h.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number The velocity in km/h
function POSITIONABLE:GetVelocityKMH()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local VelocityVec3 = self:GetVelocityVec3()
    local Velocity = ( VelocityVec3.x ^ 2 + VelocityVec3.y ^ 2 + VelocityVec3.z ^ 2 ) ^ 0.5 -- in meters / sec
    local Velocity = Velocity * 3.6 -- now it is in km/h.
    self:T3( Velocity )
    return Velocity
  end
  
  return 0
end

--- Returns the POSITIONABLE velocity in meters per second.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number The velocity in meters per second.
function POSITIONABLE:GetVelocityMPS()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local VelocityVec3 = self:GetVelocityVec3()
    local Velocity = ( VelocityVec3.x ^ 2 + VelocityVec3.y ^ 2 + VelocityVec3.z ^ 2 ) ^ 0.5 -- in meters / sec
    self:T3( Velocity )
    return Velocity
  end
  
  return 0
end


--- Returns the message text with the callsign embedded (if there is one).
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
-- @return #string The message text
function POSITIONABLE:GetMessageText( Message, Name ) --R2.1 added

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    Name = Name and ( " (" .. Name .. ")" ) or ""
    local Callsign = string.format( "%s", self:GetCallsign() ~= "" and self:GetCallsign() or self:GetName() )
    local MessageText = string.format("[%s%s]: %s", Callsign, Name, Message )
    return MessageText
  end

  return nil
end


--- Returns a message with the callsign embedded (if there is one).
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
-- @return Core.Message#MESSAGE
function POSITIONABLE:GetMessage( Message, Duration, Name ) --R2.1 changed callsign and name and using GetMessageText

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local MessageText = self:GetMessageText( Message, Name )
    return MESSAGE:New( MessageText, Duration )
  end

  return nil
end

--- Returns a message of a specified type with the callsign embedded (if there is one).
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Core.Message#MESSAGE MessageType MessageType The message type.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
-- @return Core.Message#MESSAGE
function POSITIONABLE:GetMessageType( Message, MessageType, Name ) -- R2.2 changed callsign and name and using GetMessageText

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local MessageText = self:GetMessageText( Message, Name )
    return MESSAGE:NewType( MessageText, MessageType )
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
function POSITIONABLE:MessageToCoalition( Message, Duration, MessageCoalition )
  self:F2( { Message, Duration } )

  local Name = ""
  
  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToCoalition( MessageCoalition )
  end

  return nil
end


--- Send a message to a coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Core.Message#MESSAGE.Type MessageType The message type that determines the duration.
-- @param Dcs.DCScoalition#coalition MessageCoalition The Coalition receiving the message.
function POSITIONABLE:MessageTypeToCoalition( Message, MessageType, MessageCoalition )
  self:F2( { Message, MessageType } )

  local Name = ""
  
  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessageType( Message, MessageType, Name ):ToCoalition( MessageCoalition )
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
      if MessageGroup:IsAlive() then
        self:GetMessage( Message, Duration, Name ):ToGroup( MessageGroup )
      else
        BASE:E( { "Message not sent to Group; Group is not alive...", Message = Message, MessageGroup = MessageGroup } )
      end
    else
      BASE:E( { "Message not sent to Group; Positionable is not alive ...", Message = Message, Positionable = self, MessageGroup = MessageGroup } )
    end
  end
  

  return nil
end

--- Send a message of a message type to a @{Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Core.Message#MESSAGE.Type MessageType The message type that determines the duration.
-- @param Wrapper.Group#GROUP MessageGroup The GROUP object receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageTypeToGroup( Message, MessageType, MessageGroup, Name )
  self:F2( { Message, MessageType } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    if DCSObject:isExist() then
      self:GetMessageType( Message, MessageType, Name ):ToGroup( MessageGroup )
    end
  end

  return nil
end

--- Send a message to a @{Set#SET_GROUP}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param Dcs.DCSTypes#Duration Duration The duration of the message.
-- @param Core.Set#SET_GROUP MessageSetGroup The SET_GROUP collection receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToSetGroup( Message, Duration, MessageSetGroup, Name )  --R2.1
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    if DCSObject:isExist() then
      MessageSetGroup:ForEachGroup(
        function( MessageGroup )
          self:GetMessage( Message, Duration, Name ):ToGroup( MessageGroup )
        end 
      )
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
function POSITIONABLE:GetRadio() --R2.1
  self:F2(self)
  return RADIO:New(self) 
end

--- Create a @{Radio#BEACON}, to allow this POSITIONABLE to broadcast beacon signals
-- @param #POSITIONABLE self
-- @return #RADIO Radio
function POSITIONABLE:GetBeacon() --R2.1
  self:F2(self)
  return BEACON:New(self) 
end

--- Start Lasing a POSITIONABLE
-- @param #POSITIONABLE self
-- @param #POSITIONABLE Target
-- @param #number LaserCode
-- @param #number Duration
-- @return Core.Spot#SPOT
function POSITIONABLE:LaseUnit( Target, LaserCode, Duration ) --R2.1
  self:F2()

  LaserCode = LaserCode or math.random( 1000, 9999 )

  local RecceDcsUnit = self:GetDCSObject()
  local TargetVec3 = Target:GetVec3()

  self:E("bulding spot")
  self.Spot = SPOT:New( self ) -- Core.Spot#SPOT
  self.Spot:LaseOn( Target, LaserCode, Duration)
  self.LaserCode = LaserCode
  
  return self.Spot
  
end

--- Stop Lasing a POSITIONABLE
-- @param #POSITIONABLE self
-- @return #POSITIONABLE
function POSITIONABLE:LaseOff() --R2.1
  self:F2()

  if self.Spot then
    self.Spot:LaseOff()
    self.Spot = nil
  end

  return self
end

--- Check if the POSITIONABLE is lasing a target
-- @param #POSITIONABLE self
-- @return #boolean true if it is lasing a target
function POSITIONABLE:IsLasing() --R2.1
  self:F2()

  local Lasing = false
  
  if self.Spot then
    Lasing = self.Spot:IsLasing()
  end

  return Lasing
end

--- Get the Spot
-- @param #POSITIONABLE self
-- @return Core.Spot#SPOT The Spot
function POSITIONABLE:GetSpot() --R2.1
  
  return self.Spot
end

--- Get the last assigned laser code
-- @param #POSITIONABLE self
-- @return #number The laser code
function POSITIONABLE:GetLaserCode() --R2.1
  
  return self.LaserCode
end

--- Add cargo.
-- @param #POSITIONABLE self
-- @param Core.Cargo#CARGO Cargo
-- @return #POSITIONABLE
function POSITIONABLE:AddCargo( Cargo )
  self.__.Cargo[Cargo] = Cargo
  return self
end

--- Remove cargo.
-- @param #POSITIONABLE self
-- @param Core.Cargo#CARGO Cargo
-- @return #POSITIONABLE
function POSITIONABLE:RemoveCargo( Cargo )
  self.__.Cargo[Cargo] = nil
  return self
end

--- Returns if carrier has given cargo.
-- @param #POSITIONABLE self
-- @return Core.Cargo#CARGO Cargo
function POSITIONABLE:HasCargo( Cargo )
  return self.__.Cargo[Cargo]
end

--- Clear all cargo.
-- @param #POSITIONABLE self
function POSITIONABLE:ClearCargo()
  self.__.Cargo = {}
end

--- Get cargo item count.
-- @param #POSITIONABLE self
-- @return Core.Cargo#CARGO Cargo
function POSITIONABLE:CargoItemCount()
  local ItemCount = 0
  for CargoName, Cargo in pairs( self.__.Cargo ) do
    ItemCount = ItemCount + Cargo:GetCount()
  end
  return ItemCount
end

--- Signal a flare at the position of the POSITIONABLE.
-- @param #POSITIONABLE self
-- @param Utilities.Utils#FLARECOLOR FlareColor
function POSITIONABLE:Flare( FlareColor )
  self:F2()
  trigger.action.signalFlare( self:GetVec3(), FlareColor , 0 )
end

--- Signal a white flare at the position of the POSITIONABLE.
-- @param #POSITIONABLE self
function POSITIONABLE:FlareWhite()
  self:F2()
  trigger.action.signalFlare( self:GetVec3(), trigger.flareColor.White , 0 )
end

--- Signal a yellow flare at the position of the POSITIONABLE.
-- @param #POSITIONABLE self
function POSITIONABLE:FlareYellow()
  self:F2()
  trigger.action.signalFlare( self:GetVec3(), trigger.flareColor.Yellow , 0 )
end

--- Signal a green flare at the position of the POSITIONABLE.
-- @param #POSITIONABLE self
function POSITIONABLE:FlareGreen()
  self:F2()
  trigger.action.signalFlare( self:GetVec3(), trigger.flareColor.Green , 0 )
end

--- Signal a red flare at the position of the POSITIONABLE.
-- @param #POSITIONABLE self
function POSITIONABLE:FlareRed()
  self:F2()
  local Vec3 = self:GetVec3()
  if Vec3 then
    trigger.action.signalFlare( Vec3, trigger.flareColor.Red, 0 )
  end
end

--- Smoke the POSITIONABLE.
-- @param #POSITIONABLE self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The color to smoke to positionable.
-- @param #number Range The range in meters to randomize the smoking around the positionable.
-- @param #number AddHeight The height in meters to add to the altitude of the positionable.
function POSITIONABLE:Smoke( SmokeColor, Range, AddHeight )
  self:F2()
  if Range then
    local Vec3 = self:GetRandomVec3( Range )
    Vec3.y = Vec3.y + AddHeight or 0
    trigger.action.smoke( Vec3, SmokeColor )
  else
    local Vec3 = self:GetVec3()
    Vec3.y = Vec3.y + AddHeight or 0
    trigger.action.smoke( self:GetVec3(), SmokeColor )
  end
  
end

--- Smoke the POSITIONABLE Green.
-- @param #POSITIONABLE self
function POSITIONABLE:SmokeGreen()
  self:F2()
  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Green )
end

--- Smoke the POSITIONABLE Red.
-- @param #POSITIONABLE self
function POSITIONABLE:SmokeRed()
  self:F2()
  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Red )
end

--- Smoke the POSITIONABLE White.
-- @param #POSITIONABLE self
function POSITIONABLE:SmokeWhite()
  self:F2()
  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.White )
end

--- Smoke the POSITIONABLE Orange.
-- @param #POSITIONABLE self
function POSITIONABLE:SmokeOrange()
  self:F2()
  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Orange )
end

--- Smoke the POSITIONABLE Blue.
-- @param #POSITIONABLE self
function POSITIONABLE:SmokeBlue()
  self:F2()
  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Blue )
end


