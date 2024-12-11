--- **Wrapper** - Weapon functions.
--
-- ## Main Features:
--
--    * Convenient access to DCS API functions
--    * Track weapon and get impact position
--    * Get launcher and target of weapon
--    * Define callback function when weapon impacts
--    * Define callback function when tracking weapon
--    * Mark impact points on F10 map
--    * Put coloured smoke on impact points
--
-- ===
--
-- ## Additional Material:
--
-- * **Demo Missions:** [GitHub](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Wrapper/Weapon)
-- * **YouTube videos:** None
-- * **Guides:** None
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module Wrapper.Weapon
-- @image Wrapper_Weapon.png


--- WEAPON class.
-- @type WEAPON
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field DCS#Weapon weapon The DCS weapon object.
-- @field #string name Name of the weapon object.
-- @field #string typeName Type name of the weapon.
-- @field #number category Weapon category 0=SHELL, 1=MISSILE, 2=ROCKET, 3=BOMB, 4=TORPEDO (Weapon.Category.X).
-- @field #number categoryMissile Missile category 0=AAM, 1=SAM, 2=BM, 3=ANTI_SHIP, 4=CRUISE, 5=OTHER (Weapon.MissileCategory.X).
-- @field #number coalition Coalition ID.
-- @field #number country Country ID.
-- @field DCS#Desc desc Descriptor table.
-- @field DCS#Desc guidance Missile guidance descriptor.
-- @field DCS#Unit launcher Launcher DCS unit.
-- @field Wrapper.Unit#UNIT launcherUnit Launcher Unit.
-- @field #string launcherName Name of launcher unit.
-- @field #number dtTrack Time step in seconds for tracking scheduler.
-- @field #function impactFunc Callback function for weapon impact.
-- @field #table impactArg Optional arguments for the impact callback function.
-- @field #function trackFunc Callback function when weapon is tracked and alive.
-- @field #table trackArg Optional arguments for the track callback function.
-- @field DCS#Vec3 vec3 Last known 3D position vector of the tracked weapon.
-- @field DCS#Position3 pos3 Last known 3D position and direction vector of the tracked weapon.
-- @field Core.Point#COORDINATE coordinate Coordinate object of the weapon. Can be used in other classes.
-- @field DCS#Vec3 impactVec3 Impact 3D vector.
-- @field Core.Point#COORDINATE impactCoord Impact coordinate.
-- @field #number trackScheduleID Tracking scheduler ID. Can be used to remove/destroy the scheduler function.
-- @field #boolean tracking If `true`, scheduler will keep tracking. Otherwise, function will return nil and stop tracking.
-- @field #boolean impactMark If `true`, the impact point is marked on the F10 map. Requires tracking to be started.
-- @field #boolean impactSmoke If `true`, the impact point is marked by smoke. Requires tracking to be started.
-- @field #number impactSmokeColor Colour of impact point smoke.
-- @field #boolean impactDestroy If `true`, destroy weapon before impact. Requires tracking to be started and sufficiently small time step.
-- @field #number impactDestroyDist Distance in meters to the estimated impact point. If smaller, then weapon is destroyed.
-- @field #number distIP Distance in meters for the intercept point estimation.
-- @field Wrapper.Unit#UNIT target Last known target.
-- @extends Wrapper.Positionable#POSITIONABLE

--- *In the long run, the sharpest weapon of all is a kind and gentle spirit.* -- Anne Frank
--
-- ===
--
-- # The WEAPON Concept
--
-- The WEAPON class offers an easy-to-use wrapper interface to all DCS API functions.
--
-- Probably, the most striking highlight is that the position of the weapon can be tracked and its impact position can be determined, which is not
-- possible with the native DCS scripting engine functions.
--
-- **Note** that this wrapper class is different from most others as weapon objects cannot be found with a DCS API function like `getByName()`.
-- They can only be found in DCS events like the "Shot" event, where the weapon object is contained in the event data.
--
-- # Tracking
--
-- The status of the weapon can be tracked with the @{#WEAPON.StartTrack} function. This function will try to determin the position of the weapon in (normally) relatively
-- small time steps. The time step can be set via the @{#WEAPON.SetTimeStepTrack} function and is by default set to 0.01 seconds.
--
-- Once the position cannot be retrieved any more, the weapon has impacted (or was destroyed otherwise) and the last known position is safed as the impact point.
-- The impact point can be accessed with the @{#WEAPON.GetImpactVec3} or @{#WEAPON.GetImpactCoordinate} functions.
--
-- ## Impact Point Marking
--
-- You can mark the impact point on the F10 map with @{#WEAPON.SetMarkImpact}.
--
-- You can also trigger coloured smoke at the impact point via @{#WEAPON.SetSmokeImpact}.
--
-- ## Callback functions
--
-- It is possible to define functions that are called during the tracking of the weapon and upon impact, which help you to customize further actions.
--
-- ### Callback on Impact
--
-- The function called on impact can be set with @{#WEAPON.SetFuncImpact}
--
-- ### Callback when Tracking
--
-- The function called each time the weapon status is tracked can be set with @{#WEAPON.SetFuncTrack}
--
-- # Target
--
-- If the weapon has a specific target, you can get it with the @{#WEAPON.GetTarget} function. Note that the object, which is returned can vary. Normally, it is a UNIT
-- but it could also be a STATIC object.
--
-- Also note that the weapon does not always have a target, it can loose a target and re-aquire it and the target might change to another unit.
--
-- You can get the target name with the @{#WEAPON.GetTargetName} function.
--
-- The distance to the target is returned by the @{#WEAPON.GetTargetDistance} function.
--
-- # Category
--
-- The category (bomb, rocket, missile, shell, torpedo) of the weapon can be retrieved with the @{#WEAPON.GetCategory} function.
--
-- You can check if the weapon is a
--
-- * bomb with @{#WEAPON.IsBomb}
-- * rocket with @{#WEAPON.IsRocket}
-- * missile with @{#WEAPON.IsMissile}
-- * shell with @{#WEAPON.IsShell}
-- * torpedo with @{#WEAPON.IsTorpedo}
--
-- # Parameters
--
-- You can get various parameters of the weapon, *e.g.*
--
-- * position: @{#WEAPON.GetVec3}, @{#WEAPON.GetVec2 }, @{#WEAPON.GetCoordinate}
-- * speed: @{#WEAPON.GetSpeed}
-- * coalition: @{#WEAPON.GetCoalition}
-- * country: @{#WEAPON.GetCountry}
--
-- # Dependencies
--
-- This class is used (at least) in the MOOSE classes:
--
-- * RANGE (to determine the impact points of bombs and missiles)
-- * ARTY (to destroy and replace shells with smoke or illumination)
-- * FOX (to destroy the missile before it hits the target)
--
-- @field #WEAPON
WEAPON = {
  ClassName          = "WEAPON",
  verbose            =     0,
}


--- WEAPON class version.
-- @field #string version
WEAPON.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- TODO: Destroy before impact.
-- TODO: Monitor target.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new WEAPON object from the DCS weapon object.
-- @param #WEAPON self
-- @param DCS#Weapon WeaponObject The DCS weapon object.
-- @return #WEAPON self
function WEAPON:New(WeaponObject)

  -- Nil check on object.
  if WeaponObject==nil then
    env.error("ERROR: Weapon object does NOT exist")
    return nil
  end

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, POSITIONABLE:New("Weapon")) -- #WEAPON

  -- Set DCS weapon object.
  self.weapon=WeaponObject

  -- Descriptors containing a lot of info.
  self.desc=WeaponObject:getDesc()

  -- This gives the object category which is always Object.Category.WEAPON!
  --self.category=WeaponObject:getCategory()

  -- Weapon category: 0=SHELL, 1=MISSILE, 2=ROCKET, 3=BOMB (Weapon.Category.X)
  self.category = self.desc.category

  if self:IsMissile() and self.desc.missileCategory then
    self.categoryMissile=self.desc.missileCategory
    if self.desc.guidance then
      self.guidance = self.desc.guidance
    end
  end

  -- Get type name.
  self.typeName=WeaponObject:getTypeName() or "Unknown Type"

  -- Get name of object. Usually a number like "1234567".
  self.name=WeaponObject:getName()

  -- Get coaliton of weapon.
  self.coalition=WeaponObject:getCoalition()

  -- Get country of weapon.
  self.country=WeaponObject:getCountry()

  -- Get DCS unit of the launcher.
  self.launcher=WeaponObject:getLauncher()

  -- Get launcher of weapon.
  self.launcherName="Unknown Launcher"
  if self.launcher then
    self.launcherName=self.launcher:getName()
    self.launcherUnit=UNIT:Find(self.launcher)
  end

  -- Init the coordinate of the weapon from that of the launcher.
  self.coordinate=COORDINATE:NewFromVec3(self.launcher:getPoint())

  -- Set log ID.
  self.lid=string.format("[%s] %s | ", self.typeName, self.name)

  if self.launcherUnit then
    self.releaseHeading = self.launcherUnit:GetHeading()
    self.releaseAltitudeASL = self.launcherUnit:GetAltitude()
    self.releaseAltitudeAGL = self.launcherUnit:GetAltitude(true)
    self.releaseCoordinate = self.launcherUnit:GetCoordinate()
    self.releasePitch = self.launcherUnit:GetPitch()
  end

  -- Set default parameters
  self:SetTimeStepTrack()
  self:SetDistanceInterceptPoint()

  -- Debug info.
  local text=string.format("Weapon v%s\nName=%s, TypeName=%s, Category=%s, Coalition=%d, Country=%d, Launcher=%s",
  self.version, self.name, self.typeName, self.category, self.coalition, self.country, self.launcherName)
  self:T(self.lid..text)

  -- Descriptors.
  self:T2(self.desc)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #WEAPON self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #WEAPON self
function WEAPON:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set track position time step.
-- @param #WEAPON self
-- @param #number TimeStep Time step in seconds when the position is updated. Default 0.01 sec ==> 100 evaluations per second.
-- @return #WEAPON self
function WEAPON:SetTimeStepTrack(TimeStep)
  self.dtTrack=TimeStep or 0.01
  return self
end

--- Set distance of intercept point for estimated impact point.
-- If the weapon cannot be tracked any more, the intercept point from its last known position and direction is used to get
-- a better approximation of the impact point. Can be useful when using longer time steps in the tracking and still achieve
-- a good result on the impact point.
-- It uses the DCS function [getIP](https://wiki.hoggitworld.com/view/DCS_func_getIP).
-- @param #WEAPON self
-- @param #number Distance Distance in meters. Default is 50 m. Set to 0 to deactivate.
-- @return #WEAPON self
function WEAPON:SetDistanceInterceptPoint(Distance)
  self.distIP=Distance or 50
  return self
end

--- Mark impact point on the F10 map. This requires that the tracking has been started.
-- @param #WEAPON self
-- @param #boolean Switch If `true` or nil, impact is marked.
-- @return #WEAPON self
function WEAPON:SetMarkImpact(Switch)

  if Switch==false then
    self.impactMark=false
  else
    self.impactMark=true
  end

  return self
end


--- Put smoke on impact point. This requires that the tracking has been started.
-- @param #WEAPON self
-- @param #boolean Switch If `true` or nil, impact is smoked.
-- @param #number SmokeColor Color of smoke. Default is `SMOKECOLOR.Red`.
-- @return #WEAPON self
function WEAPON:SetSmokeImpact(Switch, SmokeColor)

  if Switch==false then
    self.impactSmoke=false
  else
    self.impactSmoke=true
  end

  self.impactSmokeColor=SmokeColor or SMOKECOLOR.Red

  return self
end

--- Set callback function when weapon is tracked and still alive. The first argument will be the WEAPON object.
-- Note that this can be called many times per second. So be careful for performance reasons.
-- @param #WEAPON self
-- @param #function FuncTrack Function called during tracking.
-- @param ... Optional function arguments.
-- @return #WEAPON self
function WEAPON:SetFuncTrack(FuncTrack, ...)
  self.trackFunc=FuncTrack
  self.trackArg=arg or {}
  return self
end

--- Set callback function when weapon impacted or was destroyed otherwise, *i.e.* cannot be tracked any more.
-- @param #WEAPON self
-- @param #function FuncImpact Function called once the weapon impacted.
-- @param ... Optional function arguments.
-- @return #WEAPON self
--
-- @usage
-- -- Function called on impact.
-- local function OnImpact(Weapon)
--   Weapon:GetImpactCoordinate():MarkToAll("Impact Coordinate of weapon")
-- end
--
-- -- Set which function to call.
-- myweapon:SetFuncImpact(OnImpact)
--
-- -- Start tracking.
-- myweapon:Track()
--
function WEAPON:SetFuncImpact(FuncImpact, ...)
  self.impactFunc=FuncImpact
  self.impactArg=arg or {}
  return self
end


--- Get the unit that launched the weapon.
-- @param #WEAPON self
-- @return Wrapper.Unit#UNIT Laucher unit.
function WEAPON:GetLauncher()
  return self.launcherUnit
end

--- Get the target, which the weapon is guiding to.
-- @param #WEAPON self
-- @return Wrapper.Object#OBJECT The target object, which can be a UNIT or STATIC object.
function WEAPON:GetTarget()

  local target=nil --Wrapper.Object#OBJECT

  if self.weapon then

    -- Get the DCS target object, which can be a Unit, Weapon, Static, Scenery, Airbase.
    local object=self.weapon:getTarget()

    if object then

      -- Get object category.
      local category=Object.getCategory(object)

      --Target name
      local name=object:getName()
      
      if name then 
      
        -- Debug info.
        self:T(self.lid..string.format("Got Target Object %s, category=%d", name, category))
  
        if category==Object.Category.UNIT then
  
          target=UNIT:FindByName(name)
  
        elseif category==Object.Category.STATIC then
  
          target=STATIC:FindByName(name, false)
  
        elseif category==Object.Category.SCENERY then
          self:E(self.lid..string.format("ERROR: Scenery target not implemented yet!"))
        else
          self:E(self.lid..string.format("ERROR: Object category=%d is not implemented yet!", category))
        end
      end
    end
  end

  return target
end

--- Get the distance to the current target the weapon is guiding to.
-- @param #WEAPON self
-- @param #function ConversionFunction (Optional) Conversion function from meters to desired unit, *e.g.* `UTILS.MpsToKmph`.
-- @return #number Distance from weapon to target in meters.
function WEAPON:GetTargetDistance(ConversionFunction)

  -- Get the target of the weapon.
  local target=self:GetTarget() --Wrapper.Unit#UNIT

  local distance=nil
  if target then

    -- Current position of target.
    local tv3=target:GetVec3()

    -- Current position of weapon.
    local wv3=self:GetVec3()

    if tv3 and wv3 then
      distance=UTILS.VecDist3D(tv3, wv3)

      if ConversionFunction then
        distance=ConversionFunction(distance)
      end

    end

  end

  return distance
end


--- Get name the current target the weapon is guiding to.
-- @param #WEAPON self
-- @return #string Name of the target or "None" if no target.
function WEAPON:GetTargetName()

  -- Get the target of the weapon.
  local target=self:GetTarget() --Wrapper.Unit#UNIT

  local name="None"
  if target then
    name=target:GetName()
  end

  return name
end

--- Get velocity vector of weapon.
-- @param #WEAPON self
-- @return DCS#Vec3 Velocity vector with x, y and z components in meters/second.
function WEAPON:GetVelocityVec3()
  local Vvec3=nil
  if self.weapon then
    Vvec3=self.weapon:getVelocity()
  end
  return Vvec3
end

--- Get speed of weapon.
-- @param #WEAPON self
-- @param #function ConversionFunction (Optional) Conversion function from m/s to desired unit, *e.g.* `UTILS.MpsToKmph`.
-- @return #number Speed in meters per second.
function WEAPON:GetSpeed(ConversionFunction)

  local speed=nil

  if self.weapon then

    local v=self:GetVelocityVec3()

    speed=UTILS.VecNorm(v)

    if ConversionFunction then
      speed=ConversionFunction(speed)
    end

  end

  return speed
end

--- Get the current 3D position vector.
-- @param #WEAPON self
-- @return DCS#Vec3 Current position vector in 3D.
function WEAPON:GetVec3()

  local vec3=nil
  if self.weapon then
    vec3=self.weapon:getPoint()
  end

  return vec3
end


--- Get the current 2D position vector.
-- @param #WEAPON self
-- @return DCS#Vec2 Current position vector in 2D.
function WEAPON:GetVec2()

  local vec3=self:GetVec3()

  if vec3 then

    local vec2={x=vec3.x, y=vec3.z}

    return vec2
  end

  return nil
end

--- Get type name.
-- @param #WEAPON self
-- @return #string The type name.
function WEAPON:GetTypeName()
  return self.typeName
end

--- Get coalition.
-- @param #WEAPON self
-- @return #number Coalition ID.
function WEAPON:GetCoalition()
  return self.coalition
end

--- Get country.
-- @param #WEAPON self
-- @return #number Country ID.
function WEAPON:GetCountry()
  return self.country
end

--- Get DCS object.
-- @param #WEAPON self
-- @return DCS#Weapon The weapon object.
function WEAPON:GetDCSObject()
  -- This polymorphic function is used in Wrapper.Identifiable#IDENTIFIABLE
  return self.weapon
end

--- Get the impact position vector. Note that this might not exist if the weapon has not impacted yet!
-- @param #WEAPON self
-- @return DCS#Vec3 Impact position vector (if any).
function WEAPON:GetImpactVec3()
  return self.impactVec3
end

--- Get the impact coordinate. Note that this might not exist if the weapon has not impacted yet!
-- @param #WEAPON self
-- @return Core.Point#COORDINATE Impact coordinate (if any).
function WEAPON:GetImpactCoordinate()
  return self.impactCoord
end

--- Get the heading on which the weapon was released
-- @param #WEAPON self
-- @param #bool AccountForMagneticInclination (Optional) If true will account for the magnetic declination of the current map. Default is true
-- @return #number Heading
function WEAPON:GetReleaseHeading(AccountForMagneticInclination)
    AccountForMagneticInclination = AccountForMagneticInclination or true
    if AccountForMagneticInclination then return UTILS.ClampAngle(self.releaseHeading - UTILS.GetMagneticDeclination()) else return UTILS.ClampAngle(self.releaseHeading) end
end

--- Get the altitude above sea level at which the weapon was released
-- @param #WEAPON self
-- @return #number Altitude in meters
function WEAPON:GetReleaseAltitudeASL()
    return self.releaseAltitudeASL
end

--- Get the altitude above ground level at which the weapon was released
-- @param #WEAPON self
-- @return #number Altitude in meters
function WEAPON:GetReleaseAltitudeAGL()
    return self.releaseAltitudeAGL
end

--- Get the coordinate where the weapon was released
-- @param #WEAPON self
-- @return Core.Point#COORDINATE Impact coordinate (if any).
function WEAPON:GetReleaseCoordinate()
    return self.releaseCoordinate
end

--- Get the pitch of the unit when the weapon was released
-- @param #WEAPON self
-- @return #number Degrees
function WEAPON:GetReleasePitch()
    return self.releasePitch
end

--- Get the heading of the weapon when it impacted. Note that this might not exist if the weapon has not impacted yet!
-- @param #WEAPON self
-- @param #bool AccountForMagneticInclination (Optional) If true will account for the magnetic declination of the current map. Default is true
-- @return #number Heading
function WEAPON:GetImpactHeading(AccountForMagneticInclination)
    AccountForMagneticInclination = AccountForMagneticInclination or true
    if AccountForMagneticInclination then return UTILS.ClampAngle(self.impactHeading - UTILS.GetMagneticDeclination()) else return self.impactHeading end
end

--- Check if weapon is in the air. Obviously not really useful for torpedos. Well, then again, this is DCS...
-- @param #WEAPON self
-- @return #boolean If `true`, weapon is in the air and `false` if not. Returns `nil` if weapon object itself is `nil`.
function WEAPON:InAir()
  local inAir=nil
  if self.weapon then
    inAir=self.weapon:inAir()
  end
  return inAir
end


--- Check if weapon object (still) exists.
-- @param #WEAPON self
-- @return #boolean If `true`, the weapon object still exists and `false` otherwise. Returns `nil` if weapon object itself is `nil`.
function WEAPON:IsExist()
  local isExist=nil
  if self.weapon then
    isExist=self.weapon:isExist()
  end
  return isExist
end


--- Check if weapon is a bomb.
-- @param #WEAPON self
-- @return #boolean If `true`, is a bomb.
function WEAPON:IsBomb()
  return self.category==Weapon.Category.BOMB
end

--- Check if weapon is a missile.
-- @param #WEAPON self
-- @return #boolean If `true`, is a missile.
function WEAPON:IsMissile()
  return self.category==Weapon.Category.MISSILE
end

--- Check if weapon is a rocket.
-- @param #WEAPON self
-- @return #boolean If `true`, is a missile.
function WEAPON:IsRocket()
  return self.category==Weapon.Category.ROCKET
end

--- Check if weapon is a shell.
-- @param #WEAPON self
-- @return #boolean If `true`, is a shell.
function WEAPON:IsShell()
  return self.category==Weapon.Category.SHELL
end

--- Check if weapon is a torpedo.
-- @param #WEAPON self
-- @return #boolean If `true`, is a torpedo.
function WEAPON:IsTorpedo()
  return self.category==Weapon.Category.TORPEDO
end

--- Check if weapon is a Fox One missile (Radar Semi-Active).
-- @param #WEAPON self
-- @return #boolean If `true`, is a Fox One.
function WEAPON:IsFoxOne()
  return self.guidance==Weapon.GuidanceType.RADAR_SEMI_ACTIVE
end

--- Check if weapon is a Fox Two missile (IR guided).
-- @param #WEAPON self
-- @return #boolean If `true`, is a Fox Two.
function WEAPON:IsFoxTwo()
  return self.guidance==Weapon.GuidanceType.IR
end

--- Check if weapon is a Fox Three missile (Radar Active).
-- @param #WEAPON self
-- @return #boolean If `true`, is a Fox Three.
function WEAPON:IsFoxThree()
 return self.guidance==Weapon.GuidanceType.RADAR_ACTIVE
end

--- Destroy the weapon object.
-- @param #WEAPON self
-- @param #number Delay Delay before destroy in seconds.
-- @return #WEAPON self
function WEAPON:Destroy(Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, WEAPON.Destroy, self, 0)
  else
    if self.weapon then
      self:T(self.lid.."Destroying Weapon NOW!")
      self:StopTrack()
      self.weapon:destroy()
    end
  end

  return self
end

--- Start tracking the weapon until it impacts or is destroyed otherwise.
-- The position of the weapon is monitored in small time steps. Once the position cannot be determined anymore, the monitoring is stopped and the last known position is
-- the (approximate) impact point. Of course, the smaller the time step, the better the position can be determined. However, this can hit the performance as many
-- calculations per second need to be carried out.
-- @param #WEAPON self
-- @param #number Delay Delay in seconds before the tracking starts. Default 0.001 sec.
-- @return #WEAPON self
function WEAPON:StartTrack(Delay)

  -- Set delay before start.
  Delay=math.max(Delay or 0.001, 0.001)

  -- Debug info.
  self:T(self.lid..string.format("Start tracking weapon in %.4f sec", Delay))

  -- Weapon is not yet "alife" just yet. Start timer in 0.001 seconds.
  self.trackScheduleID=timer.scheduleFunction(WEAPON._TrackWeapon, self, timer.getTime() + Delay)

  return self
end


--- Stop tracking the weapon by removing the scheduler function.
-- @param #WEAPON self
-- @param #number Delay (Optional) Delay in seconds before the tracking is stopped.
-- @return #WEAPON self
function WEAPON:StopTrack(Delay)

  if Delay and Delay>0 then
    -- Delayed call.
    self:ScheduleOnce(Delay, WEAPON.StopTrack, self, 0)
  else

    if self.trackScheduleID then

      timer.removeFunction(self.trackScheduleID)

    end

  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Track weapon until impact.
-- @param #WEAPON self
-- @param DCS#Time time Time in seconds.
-- @return #number Time when called next or nil if not called again.
function WEAPON:_TrackWeapon(time)

  -- Debug info.
  if self.verbose>=20 then
    self:I(self.lid..string.format("Tracking at T=%.5f", time))
  end

  -- Protected call to get the weapon position. If the position cannot be determined any more, the weapon has impacted and status is nil.
  local status, pos3= pcall(
    function()
      local point=self.weapon:getPosition()
      return point
    end
  )

  if status then

    -------------------------------
    -- Weapon is still in exists --
    -------------------------------

    -- Update last known position.
    self.pos3 = pos3

    -- Update last known vec3.
    self.vec3 = UTILS.DeepCopy(self.pos3.p)

    -- Update coordinate.
    self.coordinate:UpdateFromVec3(self.vec3)

    -- Safe the last velocity of the weapon. This is needed to get the impact heading
    self.last_velocity = self.weapon:getVelocity()

    -- Keep on tracking by returning the next time below.
    self.tracking=true

    -- Callback function.
    if self.trackFunc then
      self.trackFunc(self, unpack(self.trackArg))
    end

    -- Verbose output.
    if self.verbose>=5 then

      -- Get vec2 of current position.
      local vec2={x=self.vec3.x, y=self.vec3.z}

      -- Land hight.
      local height=land.getHeight(vec2)

      -- Current height above ground level.
      local agl=self.vec3.y-height

      -- Estimated IP (if any)
      local ip=self:_GetIP(self.distIP)

      -- Distance between positon and estimated impact.
      local d=0
      if ip then
        d=UTILS.VecDist3D(self.vec3, ip)
      end

      -- Output.
      self:I(self.lid..string.format("T=%.3f: Height=%.3f m AGL=%.3f m, dIP=%.3f", time, height, agl, d))

    end

  else

    ---------------------------
    -- Weapon does NOT exist --
    ---------------------------

    -- Get intercept point from position (p) and direction (x) in 50 meters.
    local ip = self:_GetIP(self.distIP)

    if self.verbose>=10 and ip then

      -- Output.
      self:I(self.lid.."Got intercept point!")

      -- Coordinate of the impact point.
      local coord=COORDINATE:NewFromVec3(ip)

      -- Mark coordinate.
      coord:MarkToAll("Intercept point")
      coord:SmokeBlue()

      -- Distance to last known pos.
      local d=UTILS.VecDist3D(ip, self.vec3)

      -- Output.
      self:I(self.lid..string.format("FF d(ip, vec3)=%.3f meters", d))

    end

    -- Safe impact vec3.
    self.impactVec3=ip or self.vec3

    -- Safe impact coordinate.
    self.impactCoord=COORDINATE:NewFromVec3(self.vec3)

    -- Safe impact heading, using last_velocity because self:GetVelocityVec3() is no longer possible
    self.impactHeading =  UTILS.VecHdg(self.last_velocity)

    -- Mark impact point on F10 map.
    if self.impactMark then
      self.impactCoord:MarkToAll(string.format("Impact point of weapon %s\ntype=%s\nlauncher=%s", self.name, self.typeName, self.launcherName))
    end

    -- Smoke on impact point.
    if self.impactSmoke then
      self.impactCoord:Smoke(self.impactSmokeColor)
    end

    -- Call callback function.
    if self.impactFunc then
      self.impactFunc(self, unpack(self.impactArg or {}))
    end

    -- Stop tracking by returning nil below.
    self.tracking=false

  end

  -- Return next time the function is called or nil to stop the scheduler.
  if self.tracking then
    if self.dtTrack and self.dtTrack>=0.00001 then
      return time+self.dtTrack
    else
      return nil
    end
  end

  return nil
end

--- Compute estimated intercept/impact point (IP) based on last known position and direction.
-- @param #WEAPON self
-- @param #number Distance Distance in meters. Default 50 m.
-- @return DCS#Vec3 Estimated intercept/impact point. Can also return `nil`, if no IP can be determined.
function WEAPON:_GetIP(Distance)

  Distance=Distance or 50

  local ip=nil --DCS#Vec3

  if Distance>0 and self.pos3 then

    -- Get intercept point from position (p) and direction (x) in 20 meters.
    ip = land.getIP(self.pos3.p, self.pos3.x, Distance or 20) --DCS#Vec3

  end

  return ip
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
