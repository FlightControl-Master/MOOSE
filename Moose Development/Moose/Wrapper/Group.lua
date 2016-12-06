--- This module contains the GROUP class.
-- 
-- 1) @{Wrapper.Group#GROUP} class, extends @{Wrapper.Controllable#CONTROLLABLE}
-- =============================================================
-- The @{Wrapper.Group#GROUP} class is a wrapper class to handle the DCS Group objects:
--
--  * Support all DCS Group APIs.
--  * Enhance with Group specific APIs not in the DCS Group API set.
--  * Handle local Group Controller.
--  * Manage the "state" of the DCS Group.
--
-- **IMPORTANT: ONE SHOULD NEVER SANATIZE these GROUP OBJECT REFERENCES! (make the GROUP object references nil).**
--
-- 1.1) GROUP reference methods
-- -----------------------
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
-- 1.2) GROUP task methods
-- -----------------------
-- Several group task methods are available that help you to prepare tasks. 
-- These methods return a string consisting of the task description, which can then be given to either a  
-- @{Wrapper.Controllable#CONTROLLABLE.PushTask} or @{Wrapper.Controllable#CONTROLLABLE.SetTask} method to assign the task to the GROUP.
-- Tasks are specific for the category of the GROUP, more specific, for AIR, GROUND or AIR and GROUND. 
-- Each task description where applicable indicates for which group category the task is valid.
-- There are 2 main subdivisions of tasks: Assigned tasks and EnRoute tasks.
-- 
-- ### 1.2.1) Assigned task methods
-- 
-- Assigned task methods make the group execute the task where the location of the (possible) targets of the task are known before being detected.
-- This is different from the EnRoute tasks, where the targets of the task need to be detected before the task can be executed.
-- 
-- Find below a list of the **assigned task** methods:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskAttackGroup}: (AIR) Attack a Group.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskAttackMapObject}: (AIR) Attacking the map object (building, structure, e.t.c).
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskAttackUnit}: (AIR) Attack the Unit.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskBombing}: (Wrapper.Controllable#CONTROLLABLEDelivering weapon at the point on the ground.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskBombingRunway}: (AIR) Delivering weapon on the runway.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskEmbarking}: (AIR) Move the group to a Vec2 Point, wait for a defined duration and embark a group.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskEmbarkToTransport}: (GROUND) Embark to a Transport landed at a location.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskEscort}: (AIR) Escort another airborne group. 
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskFAC_AttackGroup}: (AIR + GROUND) The task makes the group/unit a FAC and orders the FAC to control the target (enemy ground group) destruction.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskFireAtPoint}: (GROUND) Fire at a VEC2 point until ammunition is finished.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskFollow}: (AIR) Following another airborne group.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskHold}: (GROUND) Hold ground group from moving.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskHoldPosition}: (AIR) Hold position at the current position of the first unit of the group.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskLand}: (AIR HELICOPTER) Landing at the ground. For helicopters only.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskLandAtZone}: (AIR) Land the group at a @{Core.Zone#ZONE_RADIUS).
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskOrbitCircle}: (AIR) Orbit at the current position of the first unit of the group at a specified alititude.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskOrbitCircleAtVec2}: (AIR) Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskRefueling}: (AIR) Refueling from the nearest tanker. No parameters.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskRoute}: (AIR + GROUND) Return a Misson task to follow a given route defined by Points.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskRouteToVec2}: (AIR + GROUND) Make the Group move to a given point.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskRouteToVec3}: (AIR + GROUND) Make the Group move to a given point.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskRouteToZone}: (AIR + GROUND) Route the group to a given zone.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskReturnToBase}: (AIR) Route the group to an airbase.
--
-- ### 1.2.2) EnRoute task methods
-- 
-- EnRoute tasks require the targets of the task need to be detected by the group (using its sensors) before the task can be executed:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskAWACS}: (AIR) Aircraft will act as an AWACS for friendly units (will provide them with information about contacts). No parameters.
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskEngageGroup}: (AIR) Engaging a group. The task does not assign the target group to the unit/group to attack now; it just allows the unit/group to engage the target group as well as other assigned targets.
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskEngageTargets}: (AIR) Engaging targets of defined types.
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskEWR}: (AIR) Attack the Unit.
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskFAC}: (AIR + GROUND) The task makes the group/unit a FAC and lets the FAC to choose a targets (enemy ground group) around as well as other assigned targets.
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskFAC_EngageGroup}: (AIR + GROUND) The task makes the group/unit a FAC and lets the FAC to choose the target (enemy ground group) as well as other assigned targets.
--   * @{Wrapper.Controllable#CONTROLLABLE.EnRouteTaskTanker}: (AIR) Aircraft will act as a tanker for friendly units. No parameters.
-- 
-- ### 1.2.3) Preparation task methods
-- 
-- There are certain task methods that allow to tailor the task behaviour:
--
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskWrappedAction}: Return a WrappedAction Task taking a Command.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskCombo}: Return a Combo Task taking an array of Tasks.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskCondition}: Return a condition section for a controlled task.
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskControlled}: Return a Controlled Task taking a Task and a TaskCondition.
-- 
-- ### 1.2.4) Obtain the mission from group templates
-- 
-- Group templates contain complete mission descriptions. Sometimes you want to copy a complete mission from a group and assign it to another:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskMission}: (AIR + GROUND) Return a mission task from a mission template.
--
-- 1.3) GROUP Command methods
-- --------------------------
-- Group **command methods** prepare the execution of commands using the @{Wrapper.Controllable#CONTROLLABLE.SetCommand} method:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.CommandDoScript}: Do Script command.
--   * @{Wrapper.Controllable#CONTROLLABLE.CommandSwitchWayPoint}: Perform a switch waypoint command.
-- 
-- 1.4) GROUP Option methods
-- -------------------------
-- Group **Option methods** change the behaviour of the Group while being alive.
-- 
-- ### 1.4.1) Rule of Engagement:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEWeaponFree} 
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEOpenFire}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEReturnFire}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEEvadeFire}
-- 
-- To check whether an ROE option is valid for a specific group, use:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEWeaponFreePossible} 
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEOpenFirePossible}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEReturnFirePossible}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROEEvadeFirePossible}
-- 
-- ### 1.4.2) Rule on thread:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTNoReaction}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTPassiveDefense}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTEvadeFire}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTVertical}
-- 
-- To test whether an ROT option is valid for a specific group, use:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTNoReactionPossible}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTPassiveDefensePossible}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTEvadeFirePossible}
--   * @{Wrapper.Controllable#CONTROLLABLE.OptionROTVerticalPossible}
-- 
-- 1.5) GROUP Zone validation methods
-- ----------------------------------
-- The group can be validated whether it is completely, partly or not within a @{Zone}.
-- Use the following Zone validation methods on the group:
-- 
--   * @{#GROUP.IsCompletelyInZone}: Returns true if all units of the group are within a @{Zone}.
--   * @{#GROUP.IsPartlyInZone}: Returns true if some units of the group are within a @{Zone}.
--   * @{#GROUP.IsNotInZone}: Returns true if none of the group units of the group are within a @{Zone}.
--   
-- The zone can be of any @{Zone} class derived from @{Core.Zone#ZONE_BASE}. So, these methods are polymorphic to the zones tested on.
-- 
-- @module Group
-- @author FlightControl

--- The GROUP class
-- @type GROUP
-- @extends Wrapper.Controllable#CONTROLLABLE
-- @field #string GroupName The name of the group.
GROUP = {
  ClassName = "GROUP",
}

--- Create a new GROUP from a DCSGroup
-- @param #GROUP self
-- @param Dcs.DCSWrapper.Group#Group GroupName The DCS Group name
-- @return #GROUP self
function GROUP:Register( GroupName )
  local self = BASE:Inherit( self, CONTROLLABLE:New( GroupName ) )
  self:F2( GroupName )
  self.GroupName = GroupName
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


--- Returns if the DCS Group is alive.
-- When the group exists at run-time, this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean true if the DCS Group is alive.
function GROUP:IsAlive()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupIsAlive = DCSGroup:isExist()
    self:T3( GroupIsAlive )
    return GroupIsAlive
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

--- Returns the category name of the DCS Group.
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
    local UnitFound = UNIT:Find( DCSGroup:getUnit( UnitNumber ) )
    self:T3( UnitFound.UnitName )
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
    self:T3( GroupSize )
    return GroupSize
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

--- Returns the UNITs wrappers of the DCS Units of the DCS Group.
-- @param #GROUP self
-- @return #table The UNITs wrappers.
function GROUP:GetUnits()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits()
    local Units = {}
    for Index, UnitData in pairs( DCSUnits ) do
      Units[#Units+1] = UNIT:Find( UnitData )
    end
    self:T3( Units )
    return Units
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
-- @return Dcs.DCSTypes#Vec3 Current Vec3 of the first DCS Unit of the GROUP.
function GROUP:GetVec3()
  self:F2( self.GroupName )

  local GroupVec3 = self:GetUnit(1):GetVec3()
  self:T3( GroupVec3 )
  return GroupVec3
end



-- Is Zone Functions

--- Returns true if all units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is completely within the @{Core.Zone#ZONE_BASE}
function GROUP:IsCompletelyInZone( Zone )
  self:F2( { self.GroupName, Zone } )
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    -- TODO: Rename IsPointVec3InZone to IsVec3InZone
    if Zone:IsPointVec3InZone( Unit:GetVec3() ) then
    else
      return false
    end
  end
  
  return true
end

--- Returns true if some units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is completely within the @{Core.Zone#ZONE_BASE}
function GROUP:IsPartlyInZone( Zone )
  self:F2( { self.GroupName, Zone } )
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsPointVec3InZone( Unit:GetVec3() ) then
      return true
    end
  end
  
  return false
end

--- Returns true if none of the group units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is completely within the @{Core.Zone#ZONE_BASE}
function GROUP:IsNotInZone( Zone )
  self:F2( { self.GroupName, Zone } )
  
  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsPointVec3InZone( Unit:GetVec3() ) then
      return false
    end
  end
  
  return true
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
-- The template must be retrieved with the @{Wrapper.Group#GROUP.GetTemplate}() function.
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
  
  self:Destroy()
  _DATABASE:Spawn( Template )
end

--- Returns the group template from the @{DATABASE} (_DATABASE object).
-- @param #GROUP self
-- @return #table 
function GROUP:GetTemplate()
  local GroupName = self:GetName()
  self:E( GroupName )
  return _DATABASE:GetGroupTemplate( GroupName )
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

--- Return the route of a group by using the @{Core.Database#DATABASE} class.
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


