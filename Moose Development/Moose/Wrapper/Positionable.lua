--- **Wrapper** -- POSITIONABLE wraps DCS classes that are "positionable".
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Wrapper.Positionable
-- @image Wrapper_Positionable.JPG

--- @type POSITIONABLE.__ Methods which are not intended for mission designers, but which are used interally by the moose designer :-)
-- @extends Wrapper.Identifiable#IDENTIFIABLE

--- @type POSITIONABLE
-- @extends Wrapper.Identifiable#IDENTIFIABLE


--- Wrapper class to handle the POSITIONABLE objects.
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
-- @param #string PositionableName The POSITIONABLE name
-- @return #POSITIONABLE self
function POSITIONABLE:New( PositionableName )
  local self = BASE:Inherit( self, IDENTIFIABLE:New( PositionableName ) )

  self.PositionableName = PositionableName
  return self
end

--- Destroys the POSITIONABLE.
-- @param #POSITIONABLE self
-- @param #boolean GenerateEvent (Optional) true if you want to generate a crash or dead event for the unit.
-- @return #nil The DCS Unit is not existing or alive.  
-- @usage
-- -- Air unit example: destroy the Helicopter and generate a S_EVENT_CRASH for each unit in the Helicopter group.
-- Helicopter = UNIT:FindByName( "Helicopter" )
-- Helicopter:Destroy( true )
-- @usage
-- -- Ground unit example: destroy the Tanks and generate a S_EVENT_DEAD for each unit in the Tanks group.
-- Tanks = UNIT:FindByName( "Tanks" )
-- Tanks:Destroy( true )
-- @usage
-- -- Ship unit example: destroy the Ship silently.
-- Ship = STATIC:FindByName( "Ship" )
-- Ship:Destroy()
-- 
-- @usage
-- -- Destroy without event generation example.
-- Ship = STATIC:FindByName( "Boat" )
-- Ship:Destroy( false ) -- Don't generate an event upon destruction.
-- 
function POSITIONABLE:Destroy( GenerateEvent )
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
  
    local UnitGroup = self:GetGroup()
    local UnitGroupName = UnitGroup:GetName()
    self:F( { UnitGroupName = UnitGroupName } )
    
    if GenerateEvent and GenerateEvent == true then
      if self:IsAir() then
        self:CreateEventCrash( timer.getTime(), DCSObject )
      else
        self:CreateEventDead( timer.getTime(), DCSObject )
      end
    elseif GenerateEvent == false then
      -- Do nothing!
    else
      self:CreateEventRemoveUnit( timer.getTime(), DCSObject )
    end
    
    USERFLAG:New( UnitGroupName ):Set( 100 )
    DCSObject:destroy()
  end

  return nil
end

--- Returns a pos3 table of the objects current position and orientation in 3D space. X, Y, Z values are unit vectors defining the objects orientation.
-- Coordinates are dependent on the position of the maps origin.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Position Table consisting of the point and orientation tables.
function POSITIONABLE:GetPosition()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePosition = DCSPositionable:getPosition()
    self:T3( PositionablePosition )
    return PositionablePosition
  end
  
  BASE:E( { "Cannot GetPositionVec3", Positionable = self, Alive = self:IsAlive() } )
  return nil  
end

--- Returns a {@DCS#Vec3} table of the objects current orientation in 3D space. X, Y, Z values are unit vectors defining the objects orientation.
-- X is the orientation parallel to the movement of the object, Z perpendicular and Y vertical orientation. 
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 X orientation, i.e. parallel to the direction of movement.
-- @return DCS#Vec3 Y orientation, i.e. vertical.
-- @return DCS#Vec3 Z orientation, i.e. perpendicular to the direction of movement.
function POSITIONABLE:GetOrientation()
  local position=self:GetPosition()
  if position then
    return position.x, position.y, position.z
  else
    BASE:E( { "Cannot GetOrientation", Positionable = self, Alive = self:IsAlive() } )
    return nil, nil, nil
  end 
end

--- Returns a {@DCS#Vec3} table of the objects current X orientation in 3D space, i.e. along the direction of movement.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 X orientation, i.e. parallel to the direction of movement.
function POSITIONABLE:GetOrientationX()
  local position=self:GetPosition()
  if position then
    return position.x
  else
    BASE:E( { "Cannot GetOrientationX", Positionable = self, Alive = self:IsAlive() } )
    return nil
  end 
end

--- Returns a {@DCS#Vec3} table of the objects current Y orientation in 3D space, i.e. vertical orientation.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 Y orientation, i.e. vertical.
function POSITIONABLE:GetOrientationY()
  local position=self:GetPosition()
  if position then
    return position.y
  else
    BASE:E( { "Cannot GetOrientationY", Positionable = self, Alive = self:IsAlive() } )
    return nil
  end 
end

--- Returns a {@DCS#Vec3} table of the objects current Z orientation in 3D space, i.e. perpendicular to direction of movement.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 Z orientation, i.e. perpendicular to movement.
function POSITIONABLE:GetOrientationZ()
  local position=self:GetPosition()
  if position then
    return position.z
  else
    BASE:E( { "Cannot GetOrientationZ", Positionable = self, Alive = self:IsAlive() } )
    return nil
  end 
end

--- Returns the @{DCS#Position3} position vectors indicating the point and direction vectors in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Position The 3D position vectors of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetPositionVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePosition = DCSPositionable:getPosition().p
    self:T3( PositionablePosition )
    return PositionablePosition
  end
  
  BASE:E( { "Cannot GetPositionVec3", Positionable = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the @{DCS#Vec2} vector indicating the point in 2D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec2 The 2D point vector of the POSITIONABLE.
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
  
  BASE:E( { "Cannot GetVec2", Positionable = self, Alive = self:IsAlive() } )

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
  
    --self:F( PositionablePointVec2 )
    return PositionablePointVec2
  end
  
  BASE:E( { "Cannot GetPointVec2", Positionable = self, Alive = self:IsAlive() } )

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

  BASE:E( { "Cannot GetPointVec3", Positionable = self, Alive = self:IsAlive() } )
  
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
  
  BASE:E( { "Cannot GetCoordinate", Positionable = self, Alive = self:IsAlive() } )
  
  return nil
end


--- Returns a random @{DCS#Vec3} vector within a range, indicating the point in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @param #number Radius
-- @return DCS#Vec3 The 3D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
-- @usage 
-- -- If Radius is ignored, returns the DCS#Vec3 of first UNIT of the GROUP
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
      self:F("Radius is nil, returning the PointVec3 of the POSITIONABLE", PositionablePointVec3)
      return PositionablePointVec3
    end
  end
  
  BASE:E( { "Cannot GetRandomVec3", Positionable = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the @{DCS#Vec3} vector indicating the 3D vector of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 The 3D point vector of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableVec3 = DCSPositionable:getPosition().p
    self:T3( PositionableVec3 )
    return PositionableVec3
  end
  
  BASE:E( { "Cannot GetVec3", Positionable = self, Alive = self:IsAlive() } )

  return nil
end


--- Get the bounding box of the underlying POSITIONABLE DCS Object.
-- @param #POSITIONABLE self
-- @return DCS#Box3 The bounding box of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetBoundingBox() --R2.1
  self:F2()

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionableDesc = DCSPositionable:getDesc() --DCS#Desc
    if PositionableDesc then
      local PositionableBox = PositionableDesc.box
      return PositionableBox
    end
  end
  
  BASE:E( { "Cannot GetBoundingBox", Positionable = self, Alive = self:IsAlive() } )

  return nil
end


--- Get the bounding radius of the underlying POSITIONABLE DCS Object.
-- @param #POSITIONABLE self
-- @param #number mindist (Optional) If bounding box is smaller than this value, mindist is returned. 
-- @return DCS#Distance The bounding radius of the POSITIONABLE or #nil if the POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetBoundingRadius(mindist)
  self:F2()

  local Box = self:GetBoundingBox()
  
  local boxmin=mindist or 0
  if Box then
    local X = Box.max.x - Box.min.x
    local Z = Box.max.z - Box.min.z
    local CX = X / 2
    local CZ = Z / 2
    return math.max( math.max( CX, CZ ), boxmin )
  end
  
  BASE:E( { "Cannot GetBoundingRadius", Positionable = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the altitude of the POSITIONABLE.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Distance The altitude of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetAltitude()
  self:F2()

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePointVec3 = DCSPositionable:getPoint() --DCS#Vec3
    return PositionablePointVec3.y
  end
  
  BASE:E( { "Cannot GetAltitude", Positionable = self, Alive = self:IsAlive() } )

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

  BASE:E( { "Cannot IsAboveRunway", Positionable = self, Alive = self:IsAlive() } )

  return nil
end


function POSITIONABLE:GetSize()

  local DCSObject = self:GetDCSObject()

  if DCSObject then
    return 1
  else
    return 0
  end
end



--- Returns the POSITIONABLE heading in degrees.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number The POSITIONABLE heading
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
  
  BASE:E( { "Cannot GetHeading", Positionable = self, Alive = self:IsAlive() } )

  return nil
end

-- Is Methods

--- Returns if the unit is of an air category.
-- If the unit is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #POSITIONABLE self
-- @return #boolean Air category evaluation result.
function POSITIONABLE:IsAir()
  self:F2()
  
  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitDescriptor = DCSUnit:getDesc()
    self:T3( { UnitDescriptor.category, Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
    
    local IsAirResult = ( UnitDescriptor.category == Unit.Category.AIRPLANE ) or ( UnitDescriptor.category == Unit.Category.HELICOPTER )
  
    self:T3( IsAirResult )
    return IsAirResult
  end
  
  return nil
end

--- Returns if the unit is of an ground category.
-- If the unit is a ground vehicle or infantry, this method will return true, otherwise false.
-- @param #POSITIONABLE self
-- @return #boolean Ground category evaluation result.
function POSITIONABLE:IsGround()
  self:F2()
  
  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitDescriptor = DCSUnit:getDesc()
    self:T3( { UnitDescriptor.category, Unit.Category.GROUND_UNIT } )
    
    local IsGroundResult = ( UnitDescriptor.category == Unit.Category.GROUND_UNIT )
  
    self:T3( IsGroundResult )
    return IsGroundResult
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
  
  BASE:E( { "Cannot GetVelocity", Positionable = self, Alive = self:IsAlive() } )

  return nil
end


 
--- Returns the POSITIONABLE velocity Vec3 vector.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 The velocity Vec3 vector
-- @return #nil The POSITIONABLE is not existing or alive.  
function POSITIONABLE:GetVelocityVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable and DCSPositionable:isExist() then
    local PositionableVelocityVec3 = DCSPositionable:getVelocity()
    self:T3( PositionableVelocityVec3 )
    return PositionableVelocityVec3
  end
  
  BASE:E( { "Cannot GetVelocityVec3", Positionable = self, Alive = self:IsAlive() } )

  return nil
end


--- Returns the POSITIONABLE height in meters.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Vec3 The height of the positionable.
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
  
  if DCSPositionable and DCSPositionable:isExist() then
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
  
  if DCSPositionable and DCSPositionable:isExist() then
    local VelocityVec3 = self:GetVelocityVec3()
    local Velocity = ( VelocityVec3.x ^ 2 + VelocityVec3.y ^ 2 + VelocityVec3.z ^ 2 ) ^ 0.5 -- in meters / sec
    self:T3( Velocity )
    return Velocity
  end
  
  return 0
end

--- Returns the Angle of Attack of a positionable.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number Angle of attack in degrees.
function POSITIONABLE:GetAoA()

  -- Get position of the unit.
  local unitpos = self:GetPosition()
  
  if unitpos then
  
    -- Get velocity vector of the unit.
    local unitvel = self:GetVelocityVec3()
    
    if unitvel and UTILS.VecNorm(unitvel)~=0 then
    
      -- Get wind vector including turbulences.
      local wind=self:GetCoordinate():GetWindWithTurbulenceVec3()
    
      -- Include wind vector.      
      unitvel.x=unitvel.x-wind.x
      unitvel.y=unitvel.y-wind.y
      unitvel.z=unitvel.z-wind.z
      
      -- Unit velocity transformed into aircraft axes directions.
      local AxialVel = {}
  
      -- Transform velocity components in direction of aircraft axes.
      AxialVel.x = UTILS.VecDot(unitpos.x, unitvel)
      AxialVel.y = UTILS.VecDot(unitpos.y, unitvel)
      AxialVel.z = UTILS.VecDot(unitpos.z, unitvel)
  
      -- AoA is angle between unitpos.x and the x and y velocities.
      local AoA = math.acos(UTILS.VecDot({x = 1, y = 0, z = 0}, {x = AxialVel.x, y = AxialVel.y, z = 0})/UTILS.VecNorm({x = AxialVel.x, y = AxialVel.y, z = 0}))
  
      --Set correct direction:
      if AxialVel.y > 0 then
        AoA = -AoA
      end
      
      -- Return AoA value in degrees.
      return math.deg(AoA)
    end
    
  end

  return nil
end

--- Returns the unit's climb or descent angle.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number Climb or descent angle in degrees.
function POSITIONABLE:GetClimbAnge()

  -- Get position of the unit.
  local unitpos = self:GetPosition()
  
  if unitpos then
  
    -- Get velocity vector of the unit.
    local unitvel = self:GetVelocityVec3()
    
    if unitvel and UTILS.VecNorm(unitvel)~=0 then

      return math.asin(unitvel.y/UTILS.VecNorm(unitvel))

    end
  end
end

--- Returns the pitch angle of a unit.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number Pitch ange in degrees.
function POSITIONABLE:GetPitch()

  -- Get position of the unit.
  local unitpos = self:GetPosition()
  
  if unitpos then
    return math.deg(math.asin(unitpos.x.y))
  end
  
  return nil
end

--- Returns the roll angle of a unit.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number Pitch ange in degrees.
function POSITIONABLE:GetRoll()

  -- Get position of the unit.
  local unitpos = self:GetPosition()
  
  if unitpos then

    --first, make a vector that is perpendicular to y and unitpos.x with cross product
    local cp = UTILS.VecCross(unitpos.x, {x = 0, y = 1, z = 0})

    --now, get dot product of of this cross product with unitpos.z
    local dp = UTILS.VecDot(cp, unitpos.z)

    --now get the magnitude of the roll (magnitude of the angle between two vectors is acos(vec1.vec2/|vec1||vec2|)
    local Roll = math.acos(dp/(UTILS.VecNorm(cp)*UTILS.VecNorm(unitpos.z)))

    --now, have to get sign of roll.
    -- by convention, making right roll positive
    -- to get sign of roll, use the y component of unitpos.z. For right roll, y component is negative.

    if unitpos.z.y > 0 then -- left roll, flip the sign of the roll
      Roll = -Roll
    end
    
    return math.deg(Roll)  
  end
end

--- Returns the yaw angle of a unit.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return #number Yaw ange in degrees.
function POSITIONABLE:GetYaw()

  local unitpos = self:GetPosition()
  if unitpos then
    -- get unit velocity
    local unitvel = self:GetVelocityVec3()
    
    if unitvel and UTILS.VecNorm(unitvel) ~= 0 then --must have non-zero velocity!
      local AxialVel = {} --unit velocity transformed into aircraft axes directions
  
      --transform velocity components in direction of aircraft axes.
      AxialVel.x = UTILS.VecDot(unitpos.x, unitvel)
      AxialVel.y = UTILS.VecDot(unitpos.y, unitvel)
      AxialVel.z = UTILS.VecDot(unitpos.z, unitvel)
  
      --Yaw is the angle between unitpos.x and the x and z velocities
      --define right yaw as positive
      local Yaw = math.acos(UTILS.VecDot({x = 1, y = 0, z = 0}, {x = AxialVel.x, y = 0, z = AxialVel.z})/UTILS.VecNorm({x = AxialVel.x, y = 0, z = AxialVel.z}))
  
      --now set correct direction:
      if AxialVel.z > 0 then
        Yaw = -Yaw
      end
      return Yaw
    end
  end
  
end


--- Returns the message text with the callsign embedded (if there is one).
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
-- @return #string The message text
function POSITIONABLE:GetMessageText( Message, Name )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local Callsign = string.format( "%s", ( ( Name ~= "" and Name ) or self:GetCallsign() ~= "" and self:GetCallsign() ) or self:GetName() )
    local MessageText = string.format("%s - %s", Callsign, Message )
    return MessageText
  end

  return nil
end


--- Returns a message with the callsign embedded (if there is one).
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param DCS#Duration Duration The duration of the message.
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
-- @param DCS#Duration Duration The duration of the message.
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
-- @param DCS#Duration Duration The duration of the message.
-- @param DCS#coalition MessageCoalition The Coalition receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageToCoalition( Message, Duration, MessageCoalition, Name )
  self:F2( { Message, Duration } )

  local Name = Name or ""
  
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
-- @param DCS#coalition MessageCoalition The Coalition receiving the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:MessageTypeToCoalition( Message, MessageType, MessageCoalition, Name )
  self:F2( { Message, MessageType } )

  local Name = Name or ""
  
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
-- @param DCS#Duration Duration The duration of the message.
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
-- @param DCS#Duration Duration The duration of the message.
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
-- @param DCS#Duration Duration The duration of the message.
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

--- Send a message to a @{Wrapper.Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param DCS#Duration Duration The duration of the message.
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

--- Send a message of a message type to a @{Wrapper.Group}.
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

--- Send a message to a @{Core.Set#SET_GROUP}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param DCS#Duration Duration The duration of the message.
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

--- Send a message to the players in the @{Wrapper.Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #POSITIONABLE self
-- @param #string Message The message text
-- @param DCS#Duration Duration The duration of the message.
-- @param #string Name (optional) The Name of the sender. If not provided, the Name is the type of the Positionable.
function POSITIONABLE:Message( Message, Duration, Name )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration, Name ):ToGroup( self )
  end

  return nil
end

--- Create a @{Core.Radio#RADIO}, to allow radio transmission for this POSITIONABLE. 
-- Set parameters with the methods provided, then use RADIO:Broadcast() to actually broadcast the message
-- @param #POSITIONABLE self
-- @return Core.Radio#RADIO Radio
function POSITIONABLE:GetRadio() --R2.1
  self:F2(self)
  return RADIO:New(self) 
end

--- Create a @{Core.Radio#BEACON}, to allow this POSITIONABLE to broadcast beacon signals
-- @param #POSITIONABLE self
-- @return Core.Radio#RADIO Radio
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

  self:F("bulding spot")
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

do -- Cargo

  --- Add cargo.
  -- @param #POSITIONABLE self
  -- @param Core.Cargo#CARGO Cargo
  -- @return #POSITIONABLE
  function POSITIONABLE:AddCargo( Cargo )
    self.__.Cargo[Cargo] = Cargo
    return self
  end
  
  --- Get all contained cargo.
  -- @param #POSITIONABLE self
  -- @return #POSITIONABLE
  function POSITIONABLE:GetCargo()
    return self.__.Cargo
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
  
  --- Is cargo bay empty.
  -- @param #POSITIONABLE self
  function POSITIONABLE:IsCargoEmpty()
    local IsEmpty = true
    for _, Cargo in pairs( self.__.Cargo ) do
      IsEmpty = false
      break
    end
    return IsEmpty
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
  
--  --- Get Cargo Bay Free Volume in m3.
--  -- @param #POSITIONABLE self
--  -- @return #number CargoBayFreeVolume
--  function POSITIONABLE:GetCargoBayFreeVolume()
--    local CargoVolume = 0
--    for CargoName, Cargo in pairs( self.__.Cargo ) do
--      CargoVolume = CargoVolume + Cargo:GetVolume()
--    end
--    return self.__.CargoBayVolumeLimit - CargoVolume
--  end
-- 
 
  --- Get Cargo Bay Free Weight in kg.
  -- @param #POSITIONABLE self
  -- @return #number CargoBayFreeWeight
  function POSITIONABLE:GetCargoBayFreeWeight()
  
    -- When there is no cargo bay weight limit set, then calculate this for this positionable!
    if not self.__.CargoBayWeightLimit then
      self:SetCargoBayWeightLimit()
    end
    
    local CargoWeight = 0
    for CargoName, Cargo in pairs( self.__.Cargo ) do
      CargoWeight = CargoWeight + Cargo:GetWeight()
    end
    return self.__.CargoBayWeightLimit - CargoWeight
  end

--  --- Get Cargo Bay Volume Limit in m3.
--  -- @param #POSITIONABLE self
--  -- @param #number VolumeLimit
--  function POSITIONABLE:SetCargoBayVolumeLimit( VolumeLimit )
--    self.__.CargoBayVolumeLimit = VolumeLimit
--  end

  --- Set Cargo Bay Weight Limit in kg.
  -- @param #POSITIONABLE self
  -- @param #number WeightLimit
  function POSITIONABLE:SetCargoBayWeightLimit( WeightLimit )
    
    if WeightLimit then
      self.__.CargoBayWeightLimit = WeightLimit
    elseif self.__.CargoBayWeightLimit~=nil then
      -- Value already set ==> Do nothing!
    else
      -- If weightlimit is not provided, we will calculate it depending on the type of unit.
      
      -- When an airplane or helicopter, we calculate the weightlimit based on the descriptor.
      if self:IsAir() then
        local Desc = self:GetDesc()
        self:F({Desc=Desc})

        local Weights = { 
          ["C-17A"] = 35000,   --77519 cannot be used, because it loads way too much apcs and infantry.,
          ["C-130"] = 22000    --The real value cannot be used, because it loads way too much apcs and infantry.,
        } 

        self.__.CargoBayWeightLimit = Weights[Desc.typeName] or ( Desc.massMax - ( Desc.massEmpty + Desc.fuelMassMax ) )
      else
        local Desc = self:GetDesc()

        local Weights = { 
          ["M1126 Stryker ICV"] = 9,
          ["M-113"] = 9,
          ["AAV7"] = 25,
          ["M2A1_halftrack"] = 9,
          ["BMD-1"] = 9,
          ["BMP-1"] = 8,
          ["BMP-2"] = 7,
          ["BMP-3"] = 8,
          ["Boman"] = 25,
          ["BTR-80"] = 9,
          ["BTR_D"] = 12,
          ["Cobra"] = 8,
          ["LAV-25"] = 6,
          ["M-2 Bradley"] = 6,
          ["M1043 HMMWV Armament"] = 4,
          ["M1045 HMMWV TOW"] = 4,
          ["M1126 Stryker ICV"] = 9,
          ["M1134 Stryker ATGM"] = 9,
          ["Marder"] = 6,
          ["MCV-80"] = 9,
          ["MLRS FDDM"] = 4,
          ["MTLB"] = 25,
          ["TPZ"] = 10,
          ["Ural-4320 APA-5D"] = 10,
          ["GAZ-66"] = 8,
          ["GAZ-3307"] = 12,
          ["GAZ-3308"] = 14,
          ["Tigr_233036"] = 6,
          ["KAMAZ Truck"] = 12,
          ["KrAZ6322"] = 12,
          ["M 818"] = 12,
          ["Ural-375"] = 12,
          ["Ural-4320-31"] = 14,
          ["Ural-4320T"] = 14,
        }
    
        local CargoBayWeightLimit = ( Weights[Desc.typeName] or 0 ) * 95
        self.__.CargoBayWeightLimit = CargoBayWeightLimit
      end
    end
    self:F({CargoBayWeightLimit = self.__.CargoBayWeightLimit})
  end
end --- Cargo

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


