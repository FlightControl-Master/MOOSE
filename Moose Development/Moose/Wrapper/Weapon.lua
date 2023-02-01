--- **Wrapper** - Weapon.
--
-- ## Main Features:
--
--    * Convenient access to all DCS API functions
--    * Track weapon and get impact position 
--    * Get launcher and target of weapon
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
-- @field #function impactFunc Callback function for weapon impact.
-- @field #table impactArg Optional arguments for the impact callback function.
-- @field DCS#Vec3 vec3 Last known 3D position vector of the tracked weapon.
-- @field DCS#Position3 pos3 Last known 3D position and direction vector of the tracked weapon.
-- @extends Wrapper.Positionable#POSITIONABLE

--- *Before this time tomorrow I shall have gained a peerage, or Westminster Abbey.* -- Horatio Nelson
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

--- Target data.
-- @type WEAPON.Target
-- @field #number uid Unique ID of the phase.
-- @field #string name Name of the phase.
-- @field Core.Condition#CONDITION conditionOver Conditions when the phase is over.
-- @field #string status Phase status.
-- @field #number Tstart Abs. mission time when the phase was started.
-- @field #number nActive Number of times the phase was active.
-- @field #number duration Duration in seconds how long the phase should be active after it started.
-- @field #WEAPON.Branch branch The branch this phase belongs to.

--- Operation phase.
-- @type WEAPON.PhaseStatus
-- @field #string PLANNED Planned.
-- @field #string ACTIVE Active phase.
-- @field #string OVER Phase is over.
WEAPON.PhaseStatus={
  PLANNED="Planned",
  ACTIVE="Active",
  OVER="Over",
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
  
  self.weapon=WeaponObject
  
  self.desc=WeaponObject:getDesc()
  
  self.category=WeaponObject:getCategory()
  
  self.typeName=WeaponObject:getTypeName()
  
  self.name=WeaponObject:getName()
  
  self.coalition=WeaponObject:getCoalition()
  
  self.country=WeaponObject:getCountry()
  
  -- Get DCS unit of the launcher.
  local launcher=WeaponObject:getLauncher()
  
  self.launcherName="Unknown Launcher"
  if launcher then
    self.launcherName=launcher:getName()
    self.launcher=UNIT:Find(launcher)
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
  self.dtTrackPos=TimeStep or 0.01
  return self
end


--- Get the unit that launched the weapon.
-- @param #WEAPON self
-- @return Wrapper.Unit#UNIT Laucher
function WEAPON:GetLauncher()
  return self.launcherUnit
end

--- Get the target, which the weapon is guiding to.
-- @param #WEAPON self
-- @return Wrapper.Unit#UNIT Laucher
function WEAPON:GetTarget()

  local target=nil
  if self.weapon then
  
    -- Get the DCS target object, which can be a Unit, Weapon, Static, Scenery, Airbase.
    local object=self.weapon:getTarget()
    
    DCStarget:getCategory()
    
    target=UNIT:Find(DCStarget)
  
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
function WEAPON:GetCoalition()
  return self.country
end

--- Get DCS object.
-- @param #WEAPON self
-- @return DCS#Weapon The weapon object. 
function WEAPON:GetDCSObject()
  -- This polymorphic function is used in Wrapper.Identifiable#IDENTIFIABLE
  return self.weapon
end

--- Get the impact position. Note that this might not exist if the weapon has not impacted yet!
-- @param #WEAPON self
-- @return DCS#Vec3 Impact position vector (if any).
function WEAPON:GetImpactVec3()
  return self.impactVec3
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



--- Destroy the weapon object.
-- @param #WEAPON self
-- @param #number Delay Delay before destroy in seconds.
-- @return #WEAPON self
function WEAPON:Destroy(Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, WEAPON.Destroy, self, 0)    
  else
    if self.weapon then
      self.weapon:destroy()
    end    
  end
  
  return self
end

--- Start tracking the position of the weapon until it impacts.
-- The position of the weapon is monitored in small time steps. Once the position cannot be determined anymore, the monitoring is stopped and the last known position is 
-- the (approximate) impact point. Of course, the smaller the time step, the better the position can be determined. However, this can hit the performance as many 
-- calculations per second need to be carried out.
-- @param #WEAPON self 
-- @param #function FuncImpact Function called when weapon has impacted. First argument is the impact coordinate Core.Point#COORDINATE.
-- @param ... Optional arguments passed to the impact function after the impact coordinate.
-- @return #WEAPON self
-- 
-- @usage
-- -- Function called on impact.
-- local function impactfunc(Coordinate, Weapon)
--  Coordinate:MarkToAll("Impact Coordinate of weapon")
-- end
-- 
-- myweapon:Track(impactfunc)
-- 
function WEAPON:TrackPosition(FuncImpact, ...)

  -- Debug info.
  self:T(self.lid..string.format("Tracking weapon")) 

  -- Callback function on impact.  
  self.impactFunc=FuncImpact
  self.impactArg=arg or {}
  
  -- Weapon is not yet "alife" just yet. Start timer in 0.001 seconds.
  timer.scheduleFunction(WEAPON._TrackPosition, self, timer.getTime() + 0.001)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Track weapon until impact.
-- @param #WEAPON self
-- @param DCS#Time time Time in seconds.
-- @return #number Time when called next or nil if not called again.
function WEAPON:_TrackPosition(time)

  -- Debug info.
  --self:I(string.format("Tracking at T=%.5f", time))

  -- When the pcall returns a failure the weapon has hit.
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

    -- Check again in ~0.01 seconds ==> 100 checks per second.
    return time+(self.dtTrackPos or 0.01)
  else
  
    ---------------------------
    -- Weapon does NOT exist --
    ---------------------------  
  
    -- Get intercept point from position (p) and direction (x) in 20 meters.
    local ip = land.getIP(self.pos3.p, self.pos3.x, 20) --DCS#Vec3
    
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
  
    -- Set impact vec3.
    self.impactVec3=ip or self.vec3
    
    -- Set impact coordinate.
    self.impactCoord=COORDINATE:NewFromVec3(self.vec3)
    
    --self.impactCoord:MarkToAll("Impact point")
    
    -- Call callback function.
    if self.impactFunc then
      self.impactFunc(self.impactCoord, self, self.impactArg)
    end
  
    return nil
  end

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
