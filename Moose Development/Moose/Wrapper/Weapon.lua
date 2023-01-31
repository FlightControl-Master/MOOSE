--- **Wrapper** - Weapon.
--
-- ## Main Features:
--
--    * Define operation phases
--    * Define conditions when phases are over
--    * Option to have branches in the phase tree
--    * Dedicate resources to operations
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Operation).
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
-- @extends Wrapper.Positionable#POSITIONABLE

--- *Before this time tomorrow I shall have gained a peerage, or Westminster Abbey.* -- Horatio Nelson
--
-- ===
--
-- # The WEAPON Concept
--
-- The wrapper class is different from most others as weapon objects cannot be found with a DCS API function like `getByName()`.
-- They can only be found in DCS events like "Shot"
-- 
--
--
-- @field #WEAPON
WEAPON = {
  ClassName          = "WEAPON",
  verbose            =     0,
}

--- Operation phase.
-- @type WEAPON.Phase
-- @field #number uid Unique ID of the phase.
-- @field #string name Name of the phase.
-- @field Core.Condition#CONDITION conditionOver Conditions when the phase is over.
-- @field #string status Phase status.
-- @field #number Tstart Abs. mission time when the phase was started.
-- @field #number nActive Number of times the phase was active.
-- @field #number duration Duration in seconds how long the phase should be active after it started.
-- @field #WEAPON.Branch branch The branch this phase belongs to.

--- Operation branch.
-- @type WEAPON.Branch
-- @field #number uid Unique ID of the branch.
-- @field #string name Name of the branch.
-- @field #table phases Phases of this branch.
-- @field #table edges Edges of this branch.

--- Operation edge.
-- @type WEAPON.Edge
-- @field #number uid Unique ID of the edge.
-- @field #WEAPON.Branch branchFrom The from branch.
-- @field #WEAPON.Phase phaseFrom The from phase after which to switch.
-- @field #WEAPON.Branch branchTo The branch to switch to.
-- @field #WEAPON.Phase phaseTo The phase to switch to.
-- @field Core.Condition#CONDITION conditionSwitch Conditions when to switch the branch.

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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new WEAPON object.
-- @param #WEAPON self
-- @param DCS#Weapon WeaponObject The DCS weapon object.
-- @return #WEAPON self
function WEAPON:New(WeaponObject)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, POSITIONABLE:New("Weapon")) -- #WEAPON
  
  self.weapon=WeaponObject
  
  self.desc=WeaponObject:getDesc()
  
  self.category=WeaponObject:getCategory()
  
  self.typeName=WeaponObject:getTypeName()
  
  self.name=WeaponObject:getName()
  
  self.coalition=WeaponObject:getCoalition()
  
  self.country=WeaponObject:getCountry()
  
  
  local text=string.format("FF Weapon: Name=%s, TypeName=%s, Category=%s, Coalition=%d, Country=%d", self.name, self.typeName, self.category, self.coalition, self.country)
  env.info(text)
  
  self:I(self.desc)
  
      
  -- Set log ID.
  self.lid=string.format("%s | ", self.name)
  
  self:Track()

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

--- Check if weapon object (still) exists.
-- @param #WEAPON self
-- @return #boolean If `true`, the weapon object still exists.
function WEAPON:IsExist()
  local isExist=false
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

--- Get velocity vector of weapon.
-- @param #WEAPON self
-- @return DCS#Vec3 Velocity vector with x, y and z components in meters/second.
function WEAPON:GetVelocity()
  self.weapon:getVelocity()
  return self
end

--- Get speed of weapon.
-- @param #WEAPON self
-- @return #number Speed in meters per second.
function WEAPON:GetSpeed()

  local speed=nil

  if self.weapon then

    local v=self:GetVelocity()
    
    speed=UTILS.VecNorm(v)
    
  end

  return speed
end

--- Check if weapon is in the air. Obviously not really useful for torpedos. Well, then again, this is DCS...
-- @param #WEAPON self
-- @return #boolean If `true`, weapon is in the air.
function WEAPON:InAir()
  local inAir=self.weapon:inAir()
  return inAir
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

--- Start tracking the position of the weapon.
-- @param #WEAPON self 
function WEAPON:Track()

  -- Weapon is not yet "alife" just yet. Start timer in one second.
  self:T( self.lid .. string.format( "Tracking weapon") )
  timer.scheduleFunction(WEAPON._Track, self, timer.getTime() + 0.001 )

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Track weapon until impact.
-- @param #WEAPON self
-- @param DCS#Time time Time in seconds.
function WEAPON:_Track(time)

  -- Debug info.
  self:I(string.format("Tracking at T=%.5f", time))

  -- When the pcall returns a failure the weapon has hit.
  local status, vec3= pcall(
    function()
      local point=self.weapon:getPoint()
      return point
    end
  )
  
  self.dtTrack=0.01

  if status then

    -------------------------------
    -- Weapon is still in exists --
    -------------------------------

    -- Remember this position.
    self.vec3 = vec3

    -- Check again in ~0.005 seconds ==> 200 checks per second.
    return time+self.dtTrack
  else
  
    self.impactVec3=self.vec3
    
    local coord=COORDINATE:NewFromVec3(self.vec3)
    
    coord:MarkToAll("Impact point")
  
    return nil
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
