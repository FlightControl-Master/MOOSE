--- **Wrapper** - Weapon functions.
--
-- ## Main Features:
--
--    * Convenient access to DCS API functions
--    * Track weapon and get impact position 
--    * Get launcher and target of weapon
--    * Define callback function when weapon impacts
--    * Destroy weapon before impact
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Wrapper%20-%20Weapon).
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
-- @field #number category Weapon category 0=SHELL, 1=MISSILE, 2=ROCKET, 3=BOMB (Weapon.Category.X).
-- @field #number coalition Coalition ID.
-- @field #number country Country ID.
-- @field DCS#Desc desc Descriptor table.
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
-- @field DCS#Vec3 impactVec3 Impact 3D vector.
-- @field Core.Point#COORDINATE impactCoord Impact coordinate.
-- @field #number trackScheduleID Tracking scheduler ID. Can be used to remove/destroy the scheduler function.
-- @field #boolean tracking If `true`, scheduler will keep tracking. Otherwise, function will return nil and stop tracking.
-- @field #boolean markImpact If `true`, the impact point is marked on the F10 map. Requires tracking to be started.
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
-- The status of the weapon can be tracked with the @{#WEAPON.StartTrack}() function. This function will try to determin the position of the weapon in (normally) relatively
-- small time steps. The time step can be set via the @{#WEAPON.SetTimeStepTrack} function and is by default set to 0.01 secons.
-- 
-- Once the position cannot be retrieved any more, the weapon has impacted (or was destroyed otherwise) and the last known position is safed as the impact point.
-- The impact point can be accessed with the @{#WEAPON.GetImpactVec3} or @{#WEAPON.GetImpactCoordinate} functions.
-- 
-- ## Callback functions
-- 
-- It is possible to define functions that are called during the tracking of the weapon and upon impact.
-- 
-- ### Callback on Impact
-- 
-- The function called on impact can be set with @{#WEAPON.SetFuncImpact}
-- 
-- ### Callback when Tracking
-- 
-- The function called each time the weapon status is tracked can be set with @{#WEAPON.SetFuncTrack}
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
WEAPON.version="0.0.1"

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
  end
    
  -- Get type name.
  self.typeName=WeaponObject:getTypeName()
  
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
  
  -- Set log ID.
  self.lid=string.format("[%s] %s | ", self.typeName, self.name)
  
  -- Set default parameters
  self:SetTimeStepTrack()
  
  -- Debug info.
  local text=string.format("FF Weapon: Name=%s, TypeName=%s, Category=%s, Coalition=%d, Country=%d, Launcher=%s", 
  self.name, self.typeName, self.category, self.coalition, self.country, self.launcherName)
  env.info(text)
  
  self:I(self.desc)

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

--- Mark impact point on the F10 map. This requires that the tracking has been started.
-- @param #WEAPON self
-- @param #boolean Switch If `true` or nil, impact is marked.
-- @return #WEAPON self
function WEAPON:SetMarkImpact(Switch)

  if Switch==false then
    self.markImpact=false
  else
    self.markImpact=true
  end

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
      local category=object:getCategory()
      
      -- Get object name.
      local name=object:getName()
      
      -- Debug info.
      self:I(self.lid..string.format("Got Target Object %s, category=%d", name, category))
      
      
      if category==Object.Category.UNIT then
      
        target=UNIT:Find(object)
        
      elseif category==Object.Category.STATIC then
      
        target=STATIC:Find(object)
        
      elseif category==Object.Category.SCENERY then
        self:E(self.lid..string.format("ERROR: Scenery target not implemented yet!"))
      else
        self:E(self.lid..string.format("ERROR: Object category=%d is not implemented yet!", category))
      end
      
    end
  end


  return target
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
-- @return #number Speed in meters per second.
function WEAPON:GetSpeed()

  local speed=nil

  if self.weapon then

    local v=self:GetVelocityVec3()
    
    speed=UTILS.VecNorm(v)
    
  end

  return speed
end

--- Get the current 3D position vector.
-- @param #WEAPON self
-- @return DCS#Vec3 
function WEAPON:GetVec3()

  local vec3=nil
  if self.weapon then
    vec3=self.weapon:getPoint()
  end

  return vec3
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
-- @param #number Delay Delay in seconds before the tracking starts. Default 0.001 sec. This is also the minimum.
-- @return #WEAPON self
function WEAPON:StartTrack(Delay)

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
  self:T3(self.lid..string.format("Tracking at T=%.5f", time))

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
    self.vec3 = self.pos3.p
    
    -- Keep on tracking by returning the next time below.
    self.tracking=true
    
    -- Callback function.
    if self.trackFunc then
      self.trackFunc(self, unpack(self.trackArg or {}))
    end
    
    if self.verbose>=5 then
    
      local vec2={x=self.vec3.x, y=self.vec3.z}
    
      local height=land.getHeight(vec2)

      -- Current height above ground level.           
      local agl=self.vec3.y-height
      
      -- Estimated IP (if any)
      local ip=self:_GetIP(100)
      
      local d=0
      if ip then
        d=UTILS.VecDist3D(self.vec3, ip)
      end
      
      self:I(self.lid..string.format("T=%.3f: Height=%.3f m AGL=%.3f m, dIP=%.3f", time, height, agl, d))
      
    end

  else
  
    ---------------------------
    -- Weapon does NOT exist --
    ---------------------------  
  
    -- Get intercept point from position (p) and direction (x) in 50 meters.
    local ip = self:_GetIP(50)
    
    if ip then
      env.info("FF Got intercept point!")
      
      -- Coordinate of the impact point.
      local coord=COORDINATE:NewFromVec3(ip)
      
      -- Mark coordinate.
      coord:MarkToAll("Intercept point")
      coord:SmokeBlue()
      
      -- Distance to last known pos.
      local d=UTILS.VecDist3D(ip, self.vec3)
      
      env.info(string.format("FF d(ip, vec3)=%.3f meters", d))
      
    end
  
    -- Safe impact vec3.
    self.impactVec3=ip or self.vec3
    
    -- Safe impact coordinate.
    self.impactCoord=COORDINATE:NewFromVec3(self.vec3)
    
    -- Mark impact point on F10 map.
    if self.markImpact then
      self.impactCoord:MarkToAll(string.format("Impact point of weapon %s\ntype=%s\nlauncher=%s", self.name, self.typeName, self.launcherName))
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
    if self.dtTrack and self.dtTrack>0.001 then
      return time+self.dtTrack
    else
      return nil
    end
  end

  return nil
end

--- Compute estimated intercept/impact point (IP) based on last known position and direction.
-- @param #WEAPON self
-- @param #number Distance Distance in meters. Default 20 m.
-- @return DCS#Vec3 Estimated intercept/impact point. Can also return `nil`, if no IP can be determined.
function WEAPON:_GetIP(Distance)

  -- Get intercept point from position (p) and direction (x) in 20 meters.
  local ip = land.getIP(self.pos3.p, self.pos3.x, Distance or 20) --DCS#Vec3

  return ip
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
