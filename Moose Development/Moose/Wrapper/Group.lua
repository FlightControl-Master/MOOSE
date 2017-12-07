--- **Wrapper** -- GROUP wraps the DCS Class Group objects.
-- 
-- ===
-- 
-- The @{#GROUP} class is a wrapper class to handle the DCS Group objects:
--
--  * Support all DCS Group APIs.
--  * Enhance with Group specific APIs not in the DCS Group API set.
--  * Handle local Group Controller.
--  * Manage the "state" of the DCS Group.
--
-- **IMPORTANT: ONE SHOULD NEVER SANATIZE these GROUP OBJECT REFERENCES! (make the GROUP object references nil).**
--
-- See the detailed documentation on the GROUP class.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
--   * [**Entropy**](https://forums.eagle.ru/member.php?u=111471), **Afinegan**: Came up with the requirement for AIOnOff().
-- 
-- ====
-- 
-- @module Group


--- @type GROUP
-- @extends Wrapper.Controllable#CONTROLLABLE
-- @field #string GroupName The name of the group.


--- 
-- # GROUP class, extends @{Controllable#CONTROLLABLE}
-- 
-- For each DCS Group object alive within a running mission, a GROUP wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts), and dynamically when new DCS Group objects are spawned (using the @{SPAWN} class).
--
-- The GROUP class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the DCS Group or the DCS GroupName.
--
-- Another thing to know is that GROUP objects do not "contain" the DCS Group object.
-- The GROUP methods will reference the DCS Group object by name when it is needed during API execution.
-- If the DCS Group object does not exist or is nil, the GROUP methods will return nil and log an exception in the DCS.log file.
--
-- The GROUP class provides the following functions to retrieve quickly the relevant GROUP instance:
--
--  * @{#GROUP.Find}(): Find a GROUP instance from the _DATABASE object using a DCS Group object.
--  * @{#GROUP.FindByName}(): Find a GROUP instance from the _DATABASE object using a DCS Group name.
--
-- ## GROUP task methods
--
-- A GROUP is a @{Controllable}. See the @{Controllable} task methods section for a description of the task methods.
--
-- ### Obtain the mission from group templates
-- 
-- Group templates contain complete mission descriptions. Sometimes you want to copy a complete mission from a group and assign it to another:
-- 
--   * @{Controllable#CONTROLLABLE.TaskMission}: (AIR + GROUND) Return a mission task from a mission template.
--
-- ## GROUP Command methods
--
-- A GROUP is a @{Controllable}. See the @{Controllable} command methods section for a description of the command methods.
-- 
-- ## GROUP option methods
--
-- A GROUP is a @{Controllable}. See the @{Controllable} option methods section for a description of the option methods.
-- 
-- ## GROUP Zone validation methods
-- 
-- The group can be validated whether it is completely, partly or not within a @{Zone}.
-- Use the following Zone validation methods on the group:
-- 
--   * @{#GROUP.IsCompletelyInZone}: Returns true if all units of the group are within a @{Zone}.
--   * @{#GROUP.IsPartlyInZone}: Returns true if some units of the group are within a @{Zone}.
--   * @{#GROUP.IsNotInZone}: Returns true if none of the group units of the group are within a @{Zone}.
--   
-- The zone can be of any @{Zone} class derived from @{Zone#ZONE_BASE}. So, these methods are polymorphic to the zones tested on.
-- 
-- ## GROUP AI methods
-- 
-- A GROUP has AI methods to control the AI activation.
-- 
--   * @{#GROUP.SetAIOnOff}(): Turns the GROUP AI On or Off.
--   * @{#GROUP.SetAIOn}(): Turns the GROUP AI On.
--   * @{#GROUP.SetAIOff}(): Turns the GROUP AI Off.
-- 
-- @field #GROUP GROUP
GROUP = {
  ClassName = "GROUP",
}


--- Enumerator for location at airbases
-- @type GROUP.Takeoff
GROUP.Takeoff = {
  Air = 1,
  Runway = 2,
  Hot = 3,
  Cold = 4,
}

GROUPTEMPLATE = {}

GROUPTEMPLATE.Takeoff = {
  [GROUP.Takeoff.Air] =     { "Turning Point", "Turning Point" },
  [GROUP.Takeoff.Runway] =  { "TakeOff", "From Runway" },
  [GROUP.Takeoff.Hot] =     { "TakeOffParkingHot", "From Parking Area Hot" },
  [GROUP.Takeoff.Cold] =    { "TakeOffParking", "From Parking Area" }
}

--- Create a new GROUP from a given GroupTemplate as a parameter.
-- Note that the GroupTemplate is NOT spawned into the mission.
-- It is merely added to the @{Database}.
-- @param #GROUP self
-- @param #table GroupTemplate The GroupTemplate Structure exactly as defined within the mission editor.
-- @param Dcs.DCScoalition#coalition.side CoalitionSide The coalition.side of the group.
-- @param Dcs.DCSGroup#Group.Category CategoryID The Group.Category of the group.
-- @param Dcs.DCScountry#country.id CountryID the country.id of the group.
-- @return #GROUP self
function GROUP:NewTemplate( GroupTemplate, CoalitionSide, CategoryID, CountryID )
  local GroupName = GroupTemplate.name
  _DATABASE:_RegisterGroupTemplate( GroupTemplate, CategoryID, CountryID, CoalitionSide, GroupName )
  self = BASE:Inherit( self, CONTROLLABLE:New( GroupName ) )
  self:F2( GroupName )
  self.GroupName = GroupName
  
  _DATABASE:AddGroup( GroupName )
  
  self:SetEventPriority( 4 )
  return self
end



--- Create a new GROUP from an existing Group in the Mission.
-- @param #GROUP self
-- @param #string GroupName The Group name
-- @return #GROUP self
function GROUP:Register( GroupName )
  self = BASE:Inherit( self, CONTROLLABLE:New( GroupName ) )
  self:F2( GroupName )
  self.GroupName = GroupName
  
  self:SetEventPriority( 4 )
  return self
end

-- Reference methods.

--- Find the GROUP wrapper class instance using the DCS Group.
-- @param #GROUP self
-- @param Dcs.DCSWrapper.Group#Group DCSGroup The DCS Group.
-- @return #GROUP The GROUP.
function GROUP:Find( DCSGroup )

  local GroupName = DCSGroup:getName() -- Wrapper.Group#GROUP
  local GroupFound = _DATABASE:FindGroup( GroupName )
  return GroupFound
end

--- Find the created GROUP using the DCS Group Name.
-- @param #GROUP self
-- @param #string GroupName The DCS Group Name.
-- @return #GROUP The GROUP.
function GROUP:FindByName( GroupName )

  local GroupFound = _DATABASE:FindGroup( GroupName )
  return GroupFound
end

-- DCS Group methods support.

--- Returns the DCS Group.
-- @param #GROUP self
-- @return Dcs.DCSWrapper.Group#Group The DCS Group.
function GROUP:GetDCSObject()
  local DCSGroup = Group.getByName( self.GroupName )

  if DCSGroup then
    return DCSGroup
  end

  return nil
end

--- Returns the @{DCSTypes#Position3} position vectors indicating the point and direction vectors in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return Dcs.DCSTypes#Position The 3D position vectors of the POSITIONABLE.
-- @return #nil The POSITIONABLE is not existing or alive.  
function GROUP:GetPositionVec3() -- Overridden from POSITIONABLE:GetPositionVec3()
  self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()
  
  if DCSPositionable then
    local PositionablePosition = DCSPositionable:getUnits()[1]:getPosition().p
    self:T3( PositionablePosition )
    return PositionablePosition
  end
  
  return nil
end

--- Returns if the Group is alive.
-- The Group must:
-- 
--   * Exist at run-time.
--   * Has at least one unit.
-- 
-- When the first @{Unit} of the Group is active, it will return true.
-- If the first @{Unit} of the Group is inactive, it will return false.
-- 
-- @param #GROUP self
-- @return #boolean true if the Group is alive and active.
-- @return #boolean false if the Group is alive but inactive.
-- @return #nil if the group does not exist anymore.
function GROUP:IsAlive()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject() -- Dcs.DCSGroup#Group

  if DCSGroup then
    if DCSGroup:isExist() then
      local DCSUnit = DCSGroup:getUnit(1) -- Dcs.DCSUnit#Unit
      if DCSUnit then
        local GroupIsAlive = DCSUnit:isActive()
        self:T3( GroupIsAlive )
        return GroupIsAlive
      end
    end
  end

  return nil
end

--- Destroys the DCS Group and all of its DCS Units.
-- Note that this destroy method also raises a destroy event at run-time.
-- So all event listeners will catch the destroy event of this DCS Group.
-- @param #GROUP self
function GROUP:Destroy()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      self:CreateEventCrash( timer.getTime(), UnitData )
    end
    USERFLAG:New( self:GetName() ):Set( 100 )
    DCSGroup:destroy()
    DCSGroup = nil
  end

  return nil
end


--- Returns category of the DCS Group.
-- @param #GROUP self
-- @return Dcs.DCSWrapper.Group#Group.Category The category ID
function GROUP:GetCategory()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T3( GroupCategory )
    return GroupCategory
  end

  return nil
end

--- Returns the category name of the #GROUP.
-- @param #GROUP self
-- @return #string Category name = Helicopter, Airplane, Ground Unit, Ship
function GROUP:GetCategoryName()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local CategoryNames = {
      [Group.Category.AIRPLANE] = "Airplane",
      [Group.Category.HELICOPTER] = "Helicopter",
      [Group.Category.GROUND] = "Ground Unit",
      [Group.Category.SHIP] = "Ship",
    }
    local GroupCategory = DCSGroup:getCategory()
    self:T3( GroupCategory )

    return CategoryNames[GroupCategory]
  end

  return nil
end


--- Returns the coalition of the DCS Group.
-- @param #GROUP self
-- @return Dcs.DCSCoalitionWrapper.Object#coalition.side The coalition side of the DCS Group.
function GROUP:GetCoalition()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local GroupCoalition = DCSGroup:getCoalition()
    self:T3( GroupCoalition )
    return GroupCoalition
  end

  return nil
end

--- Returns the country of the DCS Group.
-- @param #GROUP self
-- @return Dcs.DCScountry#country.id The country identifier.
-- @return #nil The DCS Group is not existing or alive.
function GROUP:GetCountry()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local GroupCountry = DCSGroup:getUnit(1):getCountry()
    self:T3( GroupCountry )
    return GroupCountry
  end

  return nil
end

--- Returns the UNIT wrapper class with number UnitNumber.
-- If the underlying DCS Unit does not exist, the method will return nil. .
-- @param #GROUP self
-- @param #number UnitNumber The number of the UNIT wrapper class to be returned.
-- @return Wrapper.Unit#UNIT The UNIT wrapper class.
function GROUP:GetUnit( UnitNumber )
  self:F2( { self.GroupName, UnitNumber } )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnit = DCSGroup:getUnit( UnitNumber )
    local UnitFound = UNIT:Find( DCSGroup:getUnit( UnitNumber ) )
    self:T2( UnitFound )
    return UnitFound
  end

  return nil
end

--- Returns the DCS Unit with number UnitNumber.
-- If the underlying DCS Unit does not exist, the method will return nil. .
-- @param #GROUP self
-- @param #number UnitNumber The number of the DCS Unit to be returned.
-- @return Dcs.DCSWrapper.Unit#Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )
  self:F2( { self.GroupName, UnitNumber } )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnitFound = DCSGroup:getUnit( UnitNumber )
    self:T3( DCSUnitFound )
    return DCSUnitFound
  end

  return nil
end

--- Returns current size of the DCS Group.
-- If some of the DCS Units of the DCS Group are destroyed the size of the DCS Group is changed.
-- @param #GROUP self
-- @return #number The DCS Group size.
function GROUP:GetSize()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupSize = DCSGroup:getSize()
    
    if GroupSize then
      self:T3( GroupSize )
      return GroupSize
    else
      return 0
    end
  end

  return nil
end

---
--- Returns the initial size of the DCS Group.
-- If some of the DCS Units of the DCS Group are destroyed, the initial size of the DCS Group is unchanged.
-- @param #GROUP self
-- @return #number The DCS Group initial size.
function GROUP:GetInitialSize()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupInitialSize = DCSGroup:getInitialSize()
    self:T3( GroupInitialSize )
    return GroupInitialSize
  end

  return nil
end


--- Returns the DCS Units of the DCS Group.
-- @param #GROUP self
-- @return #table The DCS Units.
function GROUP:GetDCSUnits()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits()
    self:T3( DCSUnits )
    return DCSUnits
  end

  return nil
end


--- Activates a GROUP.
-- @param #GROUP self
function GROUP:Activate()
  self:F2( { self.GroupName } )
  trigger.action.activateGroup( self:GetDCSObject() )
  return self:GetDCSObject()
end


--- Gets the type name of the group.
-- @param #GROUP self
-- @return #string The type name of the group.
function GROUP:GetTypeName()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupTypeName = DCSGroup:getUnit(1):getTypeName()
    self:T3( GroupTypeName )
    return( GroupTypeName )
  end

  return nil
end

--- Gets the player name of the group.
-- @param #GROUP self
-- @return #string The player name of the group.
function GROUP:GetPlayerName()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local PlayerName = DCSGroup:getUnit(1):getPlayerName()
    self:T3( PlayerName )
    return( PlayerName )
  end

  return nil
end


--- Gets the CallSign of the first DCS Unit of the DCS Group.
-- @param #GROUP self
-- @return #string The CallSign of the first DCS Unit of the DCS Group.
function GROUP:GetCallsign()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCallSign = DCSGroup:getUnit(1):getCallsign()
    self:T3( GroupCallSign )
    return GroupCallSign
  end

  BASE:E( { "Cannot GetCallsign", Positionable = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the current point (Vec2 vector) of the first DCS Unit in the DCS Group.
-- @param #GROUP self
-- @return Dcs.DCSTypes#Vec2 Current Vec2 point of the first DCS Unit of the DCS Group.
function GROUP:GetVec2()
  self:F2( self.GroupName )

  local UnitPoint = self:GetUnit(1)
  UnitPoint:GetVec2()
  local GroupPointVec2 = UnitPoint:GetVec2()
  self:T3( GroupPointVec2 )
  return GroupPointVec2
end

--- Returns the current Vec3 vector of the first DCS Unit in the GROUP.
-- @param #GROUP self
-- @return Dcs.DCSTypes#Vec3 Current Vec3 of the first DCS Unit of the GROUP.
function GROUP:GetVec3()
  self:F2( self.GroupName )

  local GroupVec3 = self:GetUnit(1):GetVec3()
  self:T3( GroupVec3 )
  return GroupVec3
end

--- Returns a POINT_VEC2 object indicating the point in 2D of the first UNIT of the GROUP within the mission.
-- @param #GROUP self
-- @return Core.Point#POINT_VEC2 The 2D point vector of the first DCS Unit of the GROUP.
-- @return #nil The first UNIT is not existing or alive.  
function GROUP:GetPointVec2()
  self:F2(self.GroupName)

  local FirstUnit = self:GetUnit(1)
  
  if FirstUnit then
    local FirstUnitPointVec2 = FirstUnit:GetPointVec2()
    self:T3(FirstUnitPointVec2)
    return FirstUnitPointVec2
  end
  
  BASE:E( { "Cannot GetPointVec2", Group = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns a COORDINATE object indicating the point of the first UNIT of the GROUP within the mission.
-- @param Wrapper.Group#GROUP self
-- @return Core.Point#COORDINATE The COORDINATE of the GROUP.
function GROUP:GetCoordinate()
  self:F2( self.PositionableName )

  local FirstUnit = self:GetUnit(1)
  
  if FirstUnit then
    local FirstUnitCoordinate = FirstUnit:GetCoordinate()
    self:T3(FirstUnitCoordinate)
    return FirstUnitCoordinate
  end
  
  BASE:E( { "Cannot GetCoordinate", Group = self, Alive = self:IsAlive() } )

  return nil
end


--- Returns a random @{DCSTypes#Vec3} vector (point in 3D of the UNIT within the mission) within a range around the first UNIT of the GROUP.
-- @param #GROUP self
-- @param #number Radius
-- @return Dcs.DCSTypes#Vec3 The random 3D point vector around the first UNIT of the GROUP.
-- @return #nil The GROUP is invalid or empty
-- @usage 
-- -- If Radius is ignored, returns the Dcs.DCSTypes#Vec3 of first UNIT of the GROUP
function GROUP:GetRandomVec3(Radius)
  self:F2(self.GroupName)
  
  local FirstUnit = self:GetUnit(1)
  
  if FirstUnit then
    local FirstUnitRandomPointVec3 = FirstUnit:GetRandomVec3(Radius)
    self:T3(FirstUnitRandomPointVec3)
    return FirstUnitRandomPointVec3
  end
  
  BASE:E( { "Cannot GetRandomVec3", Group = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the mean heading of every UNIT in the GROUP in degrees
-- @param #GROUP self
-- @return #number mean heading of the GROUP
-- @return #nil The first UNIT is not existing or alive.
function GROUP:GetHeading()
  self:F2(self.GroupName)

  local GroupSize = self:GetSize()
  local HeadingAccumulator = 0
  
  if GroupSize then
    for i = 1, GroupSize do
      HeadingAccumulator = HeadingAccumulator + self:GetUnit(i):GetHeading()
    end
    return math.floor(HeadingAccumulator / GroupSize)
  end
  
  BASE:E( { "Cannot GetHeading", Group = self, Alive = self:IsAlive() } )

  return nil
  
end

--- Returns relative amount of fuel (from 0.0 to 1.0) the group has in its internal tanks. If there are additional fuel tanks the value may be greater than 1.0.
-- @param #GROUP self
-- @return #number The relative amount of fuel (from 0.0 to 1.0).
-- @return #nil The GROUP is not existing or alive.  
function GROUP:GetFuel()
  self:F( self.ControllableName )

  local DCSControllable = self:GetDCSObject()
  
  if DCSControllable then
    local GroupSize = self:GetSize()
    local TotalFuel = 0
    for UnitID, UnitData in pairs( self:GetUnits() ) do
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local UnitFuel = Unit:GetFuel()
      self:F( { Fuel = UnitFuel } )
      TotalFuel = TotalFuel + UnitFuel
    end
    local GroupFuel = TotalFuel / GroupSize
    return GroupFuel
  end
  
  BASE:E( { "Cannot GetFuel", Group = self, Alive = self:IsAlive() } )

  return 0
end


do -- Is Zone methods

--- Returns true if all units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is completely within the @{Zone#ZONE_BASE}
function GROUP:IsCompletelyInZone( Zone )
  self:F2( { self.GroupName, Zone } )
  
  if not self:IsAlive() then return false end
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsVec3InZone( Unit:GetVec3() ) then
    else
      return false
    end
  end
  
  return true
end

--- Returns true if some units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is partially within the @{Zone#ZONE_BASE}
function GROUP:IsPartlyInZone( Zone )
  self:F2( { self.GroupName, Zone } )
  
  local IsOneUnitInZone = false
  local IsOneUnitOutsideZone = false
  
  if not self:IsAlive() then return false end
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsVec3InZone( Unit:GetVec3() ) then
      IsOneUnitInZone = true
    else
      IsOneUnitOutsideZone = true
    end
  end
  
  if IsOneUnitInZone and IsOneUnitOutsideZone then
    return true
  else
    return false
  end
end

--- Returns true if none of the group units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is not within the @{Zone#ZONE_BASE}
function GROUP:IsNotInZone( Zone )
  self:F2( { self.GroupName, Zone } )
  
  if not self:IsAlive() then return true end
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsVec3InZone( Unit:GetVec3() ) then
      return false
    end
  end
  
  return true
end

--- Returns the number of UNITs that are in the @{Zone}
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #number The number of UNITs that are in the @{Zone}
function GROUP:CountInZone( Zone )
  self:F2( {self.GroupName, Zone} )
  local Count = 0
  
  if not self:IsAlive() then return Count end
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsVec3InZone( Unit:GetVec3() ) then
      Count = Count + 1
    end
  end
  
  return Count
end

--- Returns if the group is of an air category.
-- If the group is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean Air category evaluation result.
function GROUP:IsAir()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local IsAirResult = DCSGroup:getCategory() == Group.Category.AIRPLANE or DCSGroup:getCategory() == Group.Category.HELICOPTER
    self:T3( IsAirResult )
    return IsAirResult
  end

  return nil
end

--- Returns if the DCS Group contains Helicopters.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Helicopters.
function GROUP:IsHelicopter()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.HELICOPTER
  end

  return nil
end

--- Returns if the DCS Group contains AirPlanes.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains AirPlanes.
function GROUP:IsAirPlane()
  self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.AIRPLANE
  end

  return nil
end

--- Returns if the DCS Group contains Ground troops.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Ground troops.
function GROUP:IsGround()
  self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.GROUND
  end

  return nil
end

--- Returns if the DCS Group contains Ships.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Ships.
function GROUP:IsShip()
  self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.SHIP
  end

  return nil
end

--- Returns if all units of the group are on the ground or landed.
-- If all units of this group are on the ground, this function will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean All units on the ground result.
function GROUP:AllOnGround()
  self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local AllOnGroundResult = true

    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      if UnitData:inAir() then
        AllOnGroundResult = false
      end
    end

    self:T3( AllOnGroundResult )
    return AllOnGroundResult
  end

  return nil
end

end

do -- AI methods

  --- Turns the AI On or Off for the GROUP.
  -- @param #GROUP self
  -- @param #boolean AIOnOff The value true turns the AI On, the value false turns the AI Off.
  -- @return #GROUP The GROUP.
  function GROUP:SetAIOnOff( AIOnOff )
  
    local DCSGroup = self:GetDCSObject() -- Dcs.DCSGroup#Group
    
    if DCSGroup then
      local DCSController = DCSGroup:getController() -- Dcs.DCSController#Controller
      if DCSController then
        DCSController:setOnOff( AIOnOff )
        return self
      end
    end
    
    return nil
  end

  --- Turns the AI On for the GROUP.
  -- @param #GROUP self
  -- @return #GROUP The GROUP.
  function GROUP:SetAIOn()

    return self:SetAIOnOff( true )  
  end
  
  --- Turns the AI Off for the GROUP.
  -- @param #GROUP self
  -- @return #GROUP The GROUP.
  function GROUP:SetAIOff()

    return self:SetAIOnOff( false )  
  end

end



--- Returns the current maximum velocity of the group.
-- Each unit within the group gets evaluated, and the maximum velocity (= the unit which is going the fastest) is returned.
-- @param #GROUP self
-- @return #number Maximum velocity found.
function GROUP:GetMaxVelocity()
  self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupVelocityMax = 0

    for Index, UnitData in pairs( DCSGroup:getUnits() ) do

      local UnitVelocityVec3 = UnitData:getVelocity()
      local UnitVelocity = math.abs( UnitVelocityVec3.x ) + math.abs( UnitVelocityVec3.y ) + math.abs( UnitVelocityVec3.z )

      if UnitVelocity > GroupVelocityMax then
        GroupVelocityMax = UnitVelocity
      end
    end

    return GroupVelocityMax
  end

  return nil
end

--- Returns the current minimum height of the group.
-- Each unit within the group gets evaluated, and the minimum height (= the unit which is the lowest elevated) is returned.
-- @param #GROUP self
-- @return #number Minimum height found.
function GROUP:GetMinHeight()
  self:F2()

end

--- Returns the current maximum height of the group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param #GROUP self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
  self:F2()

end

-- SPAWNING

--- Respawn the @{GROUP} using a (tweaked) template of the Group.
-- The template must be retrieved with the @{Group#GROUP.GetTemplate}() function.
-- The template contains all the definitions as declared within the mission file.
-- To understand templates, do the following: 
-- 
--   * unpack your .miz file into a directory using 7-zip.
--   * browse in the directory created to the file **mission**.
--   * open the file and search for the country group definitions.
--   
-- Your group template will contain the fields as described within the mission file.
-- 
-- This function will:
-- 
--  * Get the current position and heading of the group.
--  * When the group is alive, it will tweak the template x, y and heading coordinates of the group and the embedded units to the current units positions.
--  * Then it will destroy the current alive group.
--  * And it will respawn the group using your new template definition.
-- @param Wrapper.Group#GROUP self
-- @param #table Template The template of the Group retrieved with GROUP:GetTemplate()
function GROUP:Respawn( Template )

  if self:IsAlive() then
    local Vec3 = self:GetVec3()
    Template.x = Vec3.x
    Template.y = Vec3.z
    --Template.x = nil
    --Template.y = nil
    
    self:E( #Template.units )
    for UnitID, UnitData in pairs( self:GetUnits() ) do
      local GroupUnit = UnitData -- Wrapper.Unit#UNIT
      self:E( GroupUnit:GetName() )
      if GroupUnit:IsAlive() then
        local GroupUnitVec3 = GroupUnit:GetVec3()
        local GroupUnitHeading = GroupUnit:GetHeading()
        Template.units[UnitID].alt = GroupUnitVec3.y
        Template.units[UnitID].x = GroupUnitVec3.x
        Template.units[UnitID].y = GroupUnitVec3.z
        Template.units[UnitID].heading = GroupUnitHeading
        self:E( { UnitID, Template.units[UnitID], Template.units[UnitID] } )
      end
    end
    
  end
  
  self:Destroy()
  _DATABASE:Spawn( Template )
  
  self:ResetEvents()
  
end

--- Returns the group template from the @{DATABASE} (_DATABASE object).
-- @param #GROUP self
-- @return #table 
function GROUP:GetTemplate()
  local GroupName = self:GetName()
  return UTILS.DeepCopy( _DATABASE:GetGroupTemplate( GroupName ) )
end

--- Returns the group template route.points[] (the waypoints) from the @{DATABASE} (_DATABASE object).
-- @param #GROUP self
-- @return #table 
function GROUP:GetTemplateRoutePoints()
  local GroupName = self:GetName()
  return UTILS.DeepCopy( _DATABASE:GetGroupTemplate( GroupName ).route.points )
end



--- Sets the controlled status in a Template.
-- @param #GROUP self
-- @param #boolean Controlled true is controlled, false is uncontrolled.
-- @return #table 
function GROUP:SetTemplateControlled( Template, Controlled )
  Template.uncontrolled = not Controlled
  return Template
end

--- Sets the CountryID of the group in a Template.
-- @param #GROUP self
-- @param Dcs.DCScountry#country.id CountryID The country ID.
-- @return #table 
function GROUP:SetTemplateCountry( Template, CountryID )
  Template.CountryID = CountryID
  return Template
end

--- Sets the CoalitionID of the group in a Template.
-- @param #GROUP self
-- @param Dcs.DCSCoalitionWrapper.Object#coalition.side CoalitionID The coalition ID.
-- @return #table 
function GROUP:SetTemplateCoalition( Template, CoalitionID )
  Template.CoalitionID = CoalitionID
  return Template
end




--- Return the mission template of the group.
-- @param #GROUP self
-- @return #table The MissionTemplate
function GROUP:GetTaskMission()
  self:F2( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Templates.Groups[self.GroupName].Template )
end

--- Return the mission route of the group.
-- @param #GROUP self
-- @return #table The mission route defined by points.
function GROUP:GetTaskRoute()
  self:F2( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Templates.Groups[self.GroupName].Template.route.points )
end

--- Return the route of a group by using the @{Database#DATABASE} class.
-- @param #GROUP self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius.
function GROUP:CopyRoute( Begin, End, Randomize, Radius )
  self:F2( { Begin, End } )

  local Points = {}

  -- Could be a Spawned Group
  local GroupName = string.match( self:GetName(), ".*#" )
  if GroupName then
    GroupName = GroupName:sub( 1, -2 )
  else
    GroupName = self:GetName()
  end

  self:T3( { GroupName } )

  local Template = _DATABASE.Templates.Groups[GroupName].Template

  if Template then
    if not Begin then
      Begin = 0
    end
    if not End then
      End = 0
    end

    for TPointID = Begin + 1, #Template.route.points - End do
      if Template.route.points[TPointID] then
        Points[#Points+1] = routines.utils.deepCopy( Template.route.points[TPointID] )
        if Randomize then
          if not Radius then
            Radius = 500
          end
          Points[#Points].x = Points[#Points].x + math.random( Radius * -1, Radius )
          Points[#Points].y = Points[#Points].y + math.random( Radius * -1, Radius )
        end
      end
    end
    return Points
  else
    error( "Template not found for Group : " .. GroupName )
  end

  return nil
end

--- Calculate the maxium A2G threat level of the Group.
-- @param #GROUP self
function GROUP:CalculateThreatLevelA2G()
  
  local MaxThreatLevelA2G = 0
  for UnitName, UnitData in pairs( self:GetUnits() ) do
    local ThreatUnit = UnitData -- Wrapper.Unit#UNIT
    local ThreatLevelA2G = ThreatUnit:GetThreatLevel()
    if ThreatLevelA2G > MaxThreatLevelA2G then
      MaxThreatLevelA2G = ThreatLevelA2G
    end
  end

  self:T3( MaxThreatLevelA2G )
  return MaxThreatLevelA2G
end

--- Returns true if the first unit of the GROUP is in the air.
-- @param Wrapper.Group#GROUP self
-- @return #boolean true if in the first unit of the group is in the air.
-- @return #nil The GROUP is not existing or not alive.  
function GROUP:InAir()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  
  if DCSGroup then
    local DCSUnit = DCSGroup:getUnit(1)
    if DCSUnit then
      local GroupInAir = DCSGroup:getUnit(1):inAir()
      self:T3( GroupInAir )
      return GroupInAir
    end
  end
  
  return nil
end

do -- Route methods

  --- (AIR) Return the Group to an @{Airbase#AIRBASE}.  
  -- The following things are to be taken into account:
  -- 
  --   * The group is respawned to achieve the RTB, there may be side artefacts as a result of this. (Like weapons suddenly come back).
  --   * A group consisting out of more than one unit, may rejoin formation when respawned.
  --   * A speed can be given in km/h. If no speed is specified, the maximum speed of the first unit will be taken to return to base.
  --   * When there is no @{Airbase} object specified, the group will return to the home base if the route of the group is pinned at take-off or at landing to a base.
  --   * When there is no @{Airbase} object specified and the group route is not pinned to any airbase, it will return to the nearest airbase.
  -- 
  -- @param #GROUP self
  -- @param Wrapper.Airbase#AIRBASE RTBAirbase (optional) The @{Airbase} to return to. If blank, the controllable will return to the nearest friendly airbase.
  -- @param #number Speed (optional) The Speed, if no Speed is given, the maximum Speed of the first unit is selected. 
  -- @return #GROUP
  function GROUP:RouteRTB( RTBAirbase, Speed )
    self:F2( { RTBAirbase, Speed } )
  
    local DCSGroup = self:GetDCSObject()
  
    if DCSGroup then
  
      if RTBAirbase then
      
        local GroupPoint = self:GetVec2()
        local GroupVelocity = self:GetUnit(1):GetDesc().speedMax
    
        local PointFrom = {}
        PointFrom.x = GroupPoint.x
        PointFrom.y = GroupPoint.y
        PointFrom.type = "Turning Point"
        PointFrom.action = "Turning Point"
        PointFrom.speed = GroupVelocity

    
        local PointTo = {}
        local AirbasePointVec2 = RTBAirbase:GetPointVec2()
        local AirbaseAirPoint = AirbasePointVec2:WaypointAir(
          POINT_VEC3.RoutePointAltType.BARO,
          "Land",
          "Landing", 
          Speed or self:GetUnit(1):GetDesc().speedMax
        )
        
        AirbaseAirPoint["airdromeId"] = RTBAirbase:GetID()
        AirbaseAirPoint["speed_locked"] = true,
    
        self:E(AirbaseAirPoint )
    
        local Points = { PointFrom, AirbaseAirPoint }
    
        self:T3( Points )

        local Template = self:GetTemplate()
        Template.route.points = Points
        self:Respawn( Template )
    
        self:Route( Points )

        self:Respawn(Template)
      else
        self:ClearTasks()
      end
    end
  
    return self
  end

end

function GROUP:OnReSpawn( ReSpawnFunction )

  self.ReSpawnFunction = ReSpawnFunction
end

do -- Event Handling

  --- Subscribe to a DCS Event.
  -- @param #GROUP self
  -- @param Core.Event#EVENTS Event
  -- @param #function EventFunction (optional) The function to be called when the event occurs for the GROUP.
  -- @return #GROUP
  function GROUP:HandleEvent( Event, EventFunction, ... )
  
    self:EventDispatcher():OnEventForGroup( self:GetName(), EventFunction, self, Event, ... )
    
    return self
  end
  
  --- UnSubscribe to a DCS event.
  -- @param #GROUP self
  -- @param Core.Event#EVENTS Event
  -- @return #GROUP
  function GROUP:UnHandleEvent( Event )
  
    self:EventDispatcher():RemoveEvent( self, Event )
    
    return self
  end

  --- Reset the subscriptions.
  -- @param #GROUP self
  -- @return #GROUP
  function GROUP:ResetEvents()
  
    self:EventDispatcher():Reset( self )
    
    for UnitID, UnitData in pairs( self:GetUnits() ) do
      UnitData:ResetEvents()
    end
    
    return self
  end

end

do -- Players

  --- Get player names
  -- @param #GROUP self
  -- @return #table The group has players, an array of player names is returned.
  -- @return #nil The group has no players
  function GROUP:GetPlayerNames()
  
    local PlayerNames = {}
    
    local Units = self:GetUnits()
    for UnitID, UnitData in pairs( Units ) do
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = Unit:GetPlayerName()
      if PlayerName and PlayerName ~= "" then
        PlayerNames = PlayerNames or {}
        table.insert( PlayerNames, PlayerName )
      end   
    end
    
    self:F2( PlayerNames )
    return PlayerNames
  end
  
end

--do -- Smoke
--
----- Signal a flare at the position of the GROUP.
---- @param #GROUP self
---- @param Utilities.Utils#FLARECOLOR FlareColor
--function GROUP:Flare( FlareColor )
--  self:F2()
--  trigger.action.signalFlare( self:GetVec3(), FlareColor , 0 )
--end
--
----- Signal a white flare at the position of the GROUP.
---- @param #GROUP self
--function GROUP:FlareWhite()
--  self:F2()
--  trigger.action.signalFlare( self:GetVec3(), trigger.flareColor.White , 0 )
--end
--
----- Signal a yellow flare at the position of the GROUP.
---- @param #GROUP self
--function GROUP:FlareYellow()
--  self:F2()
--  trigger.action.signalFlare( self:GetVec3(), trigger.flareColor.Yellow , 0 )
--end
--
----- Signal a green flare at the position of the GROUP.
---- @param #GROUP self
--function GROUP:FlareGreen()
--  self:F2()
--  trigger.action.signalFlare( self:GetVec3(), trigger.flareColor.Green , 0 )
--end
--
----- Signal a red flare at the position of the GROUP.
---- @param #GROUP self
--function GROUP:FlareRed()
--  self:F2()
--  local Vec3 = self:GetVec3()
--  if Vec3 then
--    trigger.action.signalFlare( Vec3, trigger.flareColor.Red, 0 )
--  end
--end
--
----- Smoke the GROUP.
---- @param #GROUP self
--function GROUP:Smoke( SmokeColor, Range )
--  self:F2()
--  if Range then
--    trigger.action.smoke( self:GetRandomVec3( Range ), SmokeColor )
--  else
--    trigger.action.smoke( self:GetVec3(), SmokeColor )
--  end
--  
--end
--
----- Smoke the GROUP Green.
---- @param #GROUP self
--function GROUP:SmokeGreen()
--  self:F2()
--  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Green )
--end
--
----- Smoke the GROUP Red.
---- @param #GROUP self
--function GROUP:SmokeRed()
--  self:F2()
--  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Red )
--end
--
----- Smoke the GROUP White.
---- @param #GROUP self
--function GROUP:SmokeWhite()
--  self:F2()
--  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.White )
--end
--
----- Smoke the GROUP Orange.
---- @param #GROUP self
--function GROUP:SmokeOrange()
--  self:F2()
--  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Orange )
--end
--
----- Smoke the GROUP Blue.
---- @param #GROUP self
--function GROUP:SmokeBlue()
--  self:F2()
--  trigger.action.smoke( self:GetVec3(), trigger.smokeColor.Blue )
--end
--
--
--
--end