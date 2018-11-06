--- **Wrapper** -- GROUP wraps the DCS Class Group objects.
-- 
-- ===
-- 
-- The @{#GROUP} class is a wrapper class to handle the DCS Group objects.
-- 
-- ## Features:
--
--  * Support all DCS Group APIs.
--  * Enhance with Group specific APIs not in the DCS Group API set.
--  * Handle local Group Controller.
--  * Manage the "state" of the DCS Group.
--
-- **IMPORTANT: ONE SHOULD NEVER SANATIZE these GROUP OBJECT REFERENCES! (make the GROUP object references nil).**
--
-- ===
-- 
-- For each DCS Group object alive within a running mission, a GROUP wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts), and dynamically when new DCS Group objects are spawned (using the @{SPAWN} class).
-- 
-- The GROUP class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the DCS Group or the DCS GroupName.
--
-- The GROUP methods will reference the DCS Group object by name when it is needed during API execution.
-- If the DCS Group object does not exist or is nil, the GROUP methods will return nil and may log an exception in the DCS.log file.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
--   * [**Entropy**](https://forums.eagle.ru/member.php?u=111471), **Afinegan**: Came up with the requirement for AIOnOff().
-- 
-- ===
-- 
-- @module Wrapper.Group
-- @image Wrapper_Group.JPG


--- @type GROUP
-- @extends Wrapper.Controllable#CONTROLLABLE
-- @field #string GroupName The name of the group.


--- Wrapper class of the DCS world Group object.
-- 
-- The GROUP class provides the following functions to retrieve quickly the relevant GROUP instance:
--
--  * @{#GROUP.Find}(): Find a GROUP instance from the _DATABASE object using a DCS Group object.
--  * @{#GROUP.FindByName}(): Find a GROUP instance from the _DATABASE object using a DCS Group name.
--
-- # 1. Tasking of groups
--
-- A GROUP is derived from the wrapper class CONTROLLABLE (@{Wrapper.Controllable#CONTROLLABLE}). 
-- See the @{Wrapper.Controllable} task methods section for a description of the task methods.
--
-- But here is an example how a group can be assigned a task.
-- 
-- This test demonstrates the use(s) of the SwitchWayPoint method of the GROUP class.
-- 
-- First we look up the objects. We create a GROUP object `HeliGroup`, using the @{#GROUP:FindByName}() method, looking up the `"Helicopter"` group object.
-- Same for the `"AttackGroup"`.
--          
--          local HeliGroup = GROUP:FindByName( "Helicopter" )
--          local AttackGroup = GROUP:FindByName( "AttackGroup" )
-- 
-- Now we retrieve the @{Wrapper.Unit#UNIT} objects of the `AttackGroup` object, using the method `:GetUnits()`.   
--       
--          local AttackUnits = AttackGroup:GetUnits()
--          
-- Tasks are actually text strings that we build using methods of GROUP.
-- So first, we declare an list of `Tasks`.  
--        
--          local Tasks = {}
-- 
-- Now we loop over the `AttackUnits` using a for loop.
-- We retrieve the `AttackUnit` using the `AttackGroup:GetUnit()` method.
-- Each `AttackUnit` found, will be attacked by `HeliGroup`, using the method `HeliGroup:TaskAttackUnit()`.
-- This method returns a string containing a command line to execute the task to the `HeliGroup`.
-- The code will assign the task string command to the next element in the `Task` list, using `Tasks[#Tasks+1]`.
-- This little code will take the count of `Task` using `#` operator, and will add `1` to the count.
-- This result will be the index of the `Task` element.
--          
--          for i = 1, #AttackUnits do
--            local AttackUnit = AttackGroup:GetUnit( i )
--            Tasks[#Tasks+1] = HeliGroup:TaskAttackUnit( AttackUnit )
--          end
--          
-- Once these tasks have been executed, a function `_Resume` will be called ...
--          
--          Tasks[#Tasks+1] = HeliGroup:TaskFunction( "_Resume", { "''" } )
--          
--          --- @param Wrapper.Group#GROUP HeliGroup
--          function _Resume( HeliGroup )
--            env.info( '_Resume' )
--          
--            HeliGroup:MessageToAll( "Resuming",10,"Info")
--          end
-- 
-- Now here is where the task gets assigned!
-- Using `HeliGroup:PushTask`, the task is pushed onto the task queue of the group `HeliGroup`.
-- Since `Tasks` is an array of tasks, we use the `HeliGroup:TaskCombo` method to execute the tasks.
-- The `HeliGroup:PushTask` method can receive a delay parameter in seconds.
-- In the example, `30` is given as a delay.
-- 
-- 
--          HeliGroup:PushTask( 
--            HeliGroup:TaskCombo(
--            Tasks
--            ), 30 
--          ) 
-- 
-- That's it!
-- But again, please refer to the @{Wrapper.Controllable} task methods section for a description of the different task methods that are available.
-- 
-- 
--
-- ### Obtain the mission from group templates
-- 
-- Group templates contain complete mission descriptions. Sometimes you want to copy a complete mission from a group and assign it to another:
-- 
--   * @{Wrapper.Controllable#CONTROLLABLE.TaskMission}: (AIR + GROUND) Return a mission task from a mission template.
--
-- ## GROUP Command methods
--
-- A GROUP is a @{Wrapper.Controllable}. See the @{Wrapper.Controllable} command methods section for a description of the command methods.
-- 
-- ## GROUP option methods
--
-- A GROUP is a @{Wrapper.Controllable}. See the @{Wrapper.Controllable} option methods section for a description of the option methods.
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
-- The zone can be of any @{Zone} class derived from @{Core.Zone#ZONE_BASE}. So, these methods are polymorphic to the zones tested on.
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
-- It is merely added to the @{Core.Database}.
-- @param #GROUP self
-- @param #table GroupTemplate The GroupTemplate Structure exactly as defined within the mission editor.
-- @param DCS#coalition.side CoalitionSide The coalition.side of the group.
-- @param DCS#Group.Category CategoryID The Group.Category of the group.
-- @param DCS#country.id CountryID the country.id of the group.
-- @return #GROUP self
function GROUP:NewTemplate( GroupTemplate, CoalitionSide, CategoryID, CountryID )
  local GroupName = GroupTemplate.name

  _DATABASE:_RegisterGroupTemplate( GroupTemplate, CoalitionSide, CategoryID, CountryID, GroupName )

  local self = BASE:Inherit( self, CONTROLLABLE:New( GroupName ) )
  self.GroupName = GroupName

  if not _DATABASE.GROUPS[GroupName] then
    _DATABASE.GROUPS[GroupName] = self
  end  

  self:SetEventPriority( 4 )
  return self
end



--- Create a new GROUP from an existing Group in the Mission.
-- @param #GROUP self
-- @param #string GroupName The Group name
-- @return #GROUP self
function GROUP:Register( GroupName )
  local self = BASE:Inherit( self, CONTROLLABLE:New( GroupName ) ) -- #GROUP
  self.GroupName = GroupName
  
  self:SetEventPriority( 4 )
  return self
end

-- Reference methods.

--- Find the GROUP wrapper class instance using the DCS Group.
-- @param #GROUP self
-- @param DCS#Group DCSGroup The DCS Group.
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
-- @return DCS#Group The DCS Group.
function GROUP:GetDCSObject()
  local DCSGroup = Group.getByName( self.GroupName )

  if DCSGroup then
    return DCSGroup
  end

  return nil
end

--- Returns the @{DCS#Position3} position vectors indicating the point and direction vectors in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Position The 3D position vectors of the POSITIONABLE.
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

--- Returns if the group is alive.
-- The Group must:
-- 
--   * Exist at run-time.
--   * Has at least one unit.
-- 
-- When the first @{Wrapper.Unit} of the group is active, it will return true.
-- If the first @{Wrapper.Unit} of the group is inactive, it will return false.
-- 
-- @param #GROUP self
-- @return #boolean true if the group is alive and active.
-- @return #boolean false if the group is alive but inactive.
-- @return #nil if the group does not exist anymore.
function GROUP:IsAlive()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject() -- DCS#Group

  if DCSGroup then
    if DCSGroup:isExist() then
      local DCSUnit = DCSGroup:getUnit(1) -- DCS#Unit
      if DCSUnit then
        local GroupIsAlive = DCSUnit:isActive()
        self:T3( GroupIsAlive )
        return GroupIsAlive
      end
    end
  end

  return nil
end

--- Returns if the group is activated.
-- @param #GROUP self
-- @return #boolean true if group is activated.
-- @return #nil The group is not existing or alive.  
function GROUP:IsActive()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject() -- DCS#Group
  
  if DCSGroup then
  
    local GroupIsActive = DCSGroup:getUnit(1):isActive()
    return GroupIsActive 
  end

  return nil
end



--- Destroys the DCS Group and all of its DCS Units.
-- Note that this destroy method also can raise a destroy event at run-time.
-- So all event listeners will catch the destroy event of this group for each unit in the group.
-- To raise these events, provide the `GenerateEvent` parameter.
-- @param #GROUP self
-- @param #boolean GenerateEvent true if you want to generate a crash or dead event for each unit.
-- @usage
-- -- Air unit example: destroy the Helicopter and generate a S_EVENT_CRASH for each unit in the Helicopter group.
-- Helicopter = GROUP:FindByName( "Helicopter" )
-- Helicopter:Destroy( true )
-- @usage
-- -- Ground unit example: destroy the Tanks and generate a S_EVENT_DEAD for each unit in the Tanks group.
-- Tanks = GROUP:FindByName( "Tanks" )
-- Tanks:Destroy( true )
-- @usage
-- -- Ship unit example: destroy the Ship silently.
-- Ship = GROUP:FindByName( "Ship" )
-- Ship:Destroy()
-- 
-- @usage
-- -- Destroy without event generation example.
-- Ship = GROUP:FindByName( "Boat" )
-- Ship:Destroy( false ) -- Don't generate an event upon destruction.
-- 
function GROUP:Destroy( GenerateEvent )
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      if GenerateEvent and GenerateEvent == true then
        if self:IsAir() then
          self:CreateEventCrash( timer.getTime(), UnitData )
        else
          self:CreateEventDead( timer.getTime(), UnitData )
        end
      elseif GenerateEvent == false then
        -- Do nothing!
      else
        self:CreateEventRemoveUnit( timer.getTime(), UnitData )
      end
    end
    USERFLAG:New( self:GetName() ):Set( 100 )
    DCSGroup:destroy()
    DCSGroup = nil
  end

  return nil
end


--- Returns category of the DCS Group.
-- @param #GROUP self
-- @return DCS#Group.Category The category ID
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
-- @return DCS#coalition.side The coalition side of the DCS Group.
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
-- @return DCS#country.id The country identifier or nil if the DCS Group is not existing or alive.
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


--- Check if at least one (or all) unit(s) has (have) a certain attribute.
-- See [hoggit documentation](https://wiki.hoggitworld.com/view/DCS_func_hasAttribute).
-- @param #GROUP self
-- @param #string attribute The name of the attribute the group is supposed to have. Valid attributes can be found in the "db_attributes.lua" file which is located at in "C:\Program Files\Eagle Dynamics\DCS World\Scripts\Database".
-- @param #boolean all If true, all units of the group must have the attribute in order to return true. Default is only one unit of a heterogenious group needs to have the attribute.
-- @return #boolean Group has this attribute.
function GROUP:HasAttribute(attribute, all)

  -- Get all units of the group.
  local _units=self:GetUnits()
  
  local _allhave=true
  local _onehas=false
  
  for _,_unit in pairs(_units) do
    local _unit=_unit --Wrapper.Unit#UNIT
    if _unit then
      local _hastit=_unit:HasAttribute(attribute)
      if _hastit==true then
        _onehas=true
      else
        _allhave=false
      end
    end 
  end
  
  if all==true then
    return _allhave
  else
    return _onehas
  end
end

--- Returns the maximum speed of the group.
-- If the group is heterogenious and consists of different units, the max speed of the slowest unit is returned.
-- @param #GROUP self
-- @return #number Speed in km/h.
function GROUP:GetSpeedMax()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
  
    local Units=self:GetUnits()
    
    local speedmax=nil
    
    for _,unit in pairs(Units) do
      local unit=unit --Wrapper.Unit#UNIT
      local speed=unit:GetSpeedMax()
      if speedmax==nil then
        speedmax=speed
      elseif speed<speedmax then
        speedmax=speed
      end
    end
    
    return speedmax
  end
  
  return nil
end

--- Returns the maximum range of the group.
-- If the group is heterogenious and consists of different units, the smallest range of all units is returned.
-- @param #GROUP self
-- @return #number Range in meters.
function GROUP:GetRange()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
  
    local Units=self:GetUnits()
    
    local Rangemin=nil
    
    for _,unit in pairs(Units) do
      local unit=unit --Wrapper.Unit#UNIT
      local range=unit:GetRange()
      if range then
        if Rangemin==nil then
          Rangemin=range
        elseif range<Rangemin then
          Rangemin=range
        end
      end
    end
    
    return Rangemin
  end
  
  return nil
end


--- Returns a list of @{Wrapper.Unit} objects of the @{Wrapper.Group}.
-- @param #GROUP self
-- @return #list<Wrapper.Unit#UNIT> The list of @{Wrapper.Unit} objects of the @{Wrapper.Group}.
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


--- Returns a list of @{Wrapper.Unit} objects of the @{Wrapper.Group} that are occupied by a player.
-- @param #GROUP self
-- @return #list<Wrapper.Unit#UNIT> The list of player occupied @{Wrapper.Unit} objects of the @{Wrapper.Group}.
function GROUP:GetPlayerUnits()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits()
    local Units = {}
    for Index, UnitData in pairs( DCSUnits ) do
      local PlayerUnit = UNIT:Find( UnitData )
      if PlayerUnit:GetPlayerName() then
        Units[#Units+1] = PlayerUnit
      end
    end
    self:T3( Units )
    return Units
  end

  return nil
end


--- Returns the UNIT wrapper class with number UnitNumber.
-- If the underlying DCS Unit does not exist, the method will return nil. .
-- @param #GROUP self
-- @param #number UnitNumber The number of the UNIT wrapper class to be returned.
-- @return Wrapper.Unit#UNIT The UNIT wrapper class.
function GROUP:GetUnit( UnitNumber )
  self:F3( { self.GroupName, UnitNumber } )

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
-- @return DCS#Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )
  self:F3( { self.GroupName, UnitNumber } )

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
  self:F3( { self.GroupName } )
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


--- Returns the average velocity Vec3 vector.
-- @param Wrapper.Group#GROUP self
-- @return DCS#Vec3 The velocity Vec3 vector
-- @return #nil The GROUP is not existing or alive.  
function GROUP:GetVelocityVec3()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  
  if DCSGroup and DCSGroup:isExist() then
    local GroupUnits = DCSGroup:getUnits()
    local GroupCount = #GroupUnits
    
    local VelocityVec3 = { x = 0, y = 0, z = 0 }
    
    for _, DCSUnit in pairs( GroupUnits ) do
      local UnitVelocityVec3 = DCSUnit:getVelocity()
      VelocityVec3.x = VelocityVec3.x + UnitVelocityVec3.x
      VelocityVec3.y = VelocityVec3.y + UnitVelocityVec3.y
      VelocityVec3.z = VelocityVec3.z + UnitVelocityVec3.z
    end
    
    VelocityVec3.x = VelocityVec3.x / GroupCount
    VelocityVec3.y = VelocityVec3.y / GroupCount
    VelocityVec3.z = VelocityVec3.z / GroupCount
    
    return VelocityVec3
  end
  
  BASE:E( { "Cannot GetVelocityVec3", Group = self, Alive = self:IsAlive() } )

  return nil
end


--- Returns the average group height in meters.
-- @param Wrapper.Group#GROUP self
-- @param #boolean FromGround Measure from the ground or from sea level. Provide **true** for measuring from the ground. **false** or **nil** if you measure from sea level. 
-- @return DCS#Vec3 The height of the group or nil if is not existing or alive.  
function GROUP:GetHeight( FromGround )
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  
  if DCSGroup then
    local GroupUnits = DCSGroup:getUnits()
    local GroupCount = #GroupUnits
    
    local GroupHeight = 0

    for _, DCSUnit in pairs( GroupUnits ) do
      local GroupPosition = DCSUnit:getPosition()
      
      if FromGround == true then
        local LandHeight =  land.getHeight( { x = GroupPosition.p.x, y = GroupPosition.p.z } )
        GroupHeight = GroupHeight + ( GroupPosition.p.y - LandHeight )
      else
        GroupHeight = GroupHeight + GroupPosition.p.y
      end
    end
    
    return GroupHeight / GroupCount
  end
  
  return nil
end




---
--- Returns the initial size of the DCS Group.
-- If some of the DCS Units of the DCS Group are destroyed, the initial size of the DCS Group is unchanged.
-- @param #GROUP self
-- @return #number The DCS Group initial size.
function GROUP:GetInitialSize()
  self:F3( { self.GroupName } )
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


--- Activates a late activated GROUP.
-- @param #GROUP self
-- @return #GROUP self
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
-- @return DCS#Vec2 Current Vec2 point of the first DCS Unit of the DCS Group.
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
-- @return DCS#Vec3 Current Vec3 of the first DCS Unit of the GROUP.
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


--- Returns a random @{DCS#Vec3} vector (point in 3D of the UNIT within the mission) within a range around the first UNIT of the GROUP.
-- @param #GROUP self
-- @param #number Radius
-- @return DCS#Vec3 The random 3D point vector around the first UNIT of the GROUP.
-- @return #nil The GROUP is invalid or empty
-- @usage 
-- -- If Radius is ignored, returns the DCS#Vec3 of first UNIT of the GROUP
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

--- Return the fuel state and unit reference for the unit with the least
-- amount of fuel in the group.
-- @param #GROUP self
-- @return #number The fuel state of the unit with the least amount of fuel
-- @return #Unit reference to #Unit object for further processing
function GROUP:GetFuelMin()
  self:F(self.ControllableName)

  if not self:GetDCSObject() then
    BASE:E( { "Cannot GetFuel", Group = self, Alive = self:IsAlive() } )
    return 0
  end

  local min  = 65535  -- some sufficiently large number to init with
  local unit = nil
  local tmp  = nil

  for UnitID, UnitData in pairs( self:GetUnits() ) do
    tmp = UnitData:GetFuel()
    if tmp < min then
      min = tmp
      unit = UnitData
    end
  end

  return min, unit
end

--- Returns relative amount of fuel (from 0.0 to 1.0) the group has in its
--  internal tanks. If there are additional fuel tanks the value may be
--  greater than 1.0.
-- @param #GROUP self
-- @return #number The relative amount of fuel (from 0.0 to 1.0).
-- @return #nil The GROUP is not existing or alive.
function GROUP:GetFuelAvg()
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

--- Returns relative amount of fuel (from 0.0 to 1.0) the group has in its internal tanks. If there are additional fuel tanks the value may be greater than 1.0.
-- @param #GROUP self
-- @return #number The relative amount of fuel (from 0.0 to 1.0).
-- @return #nil The GROUP is not existing or alive.
function GROUP:GetFuel()
  return self:GetFuelAvg()
end


do -- Is Zone methods

--- Returns true if all units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is completely within the @{Core.Zone#ZONE_BASE}
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

--- Returns true if some but NOT ALL units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is partially within the @{Core.Zone#ZONE_BASE}
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

--- Returns true if part or all units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is partially or completely within the @{Core.Zone#ZONE_BASE}.
function GROUP:IsPartlyOrCompletelyInZone( Zone )
  return self:IsPartlyInZone(Zone) or self:IsCompletelyInZone(Zone)
end

--- Returns true if none of the group units of the group are within a @{Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is not within the @{Core.Zone#ZONE_BASE}
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

--- Returns true if any units of the group are within a @{Core.Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if any unit of the Group is within the @{Core.Zone#ZONE_BASE}
function GROUP:IsAnyInZone( Zone )

  if not self:IsAlive() then return false end

  for UnitID, UnitData in pairs( self:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    if Zone:IsVec3InZone( Unit:GetVec3() ) then
      return true
    end
  end
  return false
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
  
    local DCSGroup = self:GetDCSObject() -- DCS#Group
    
    if DCSGroup then
      local DCSController = DCSGroup:getController() -- DCS#Controller
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

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupHeightMin = 999999999

    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      local UnitData = UnitData -- DCS#Unit

      local UnitHeight = UnitData:getPoint()

      if UnitHeight < GroupHeightMin then
        GroupHeightMin = UnitHeight
      end
    end

    return GroupHeightMin
  end

  return nil
end

--- Returns the current maximum height of the group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param #GROUP self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
  self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupHeightMax = -999999999

    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      local UnitData = UnitData -- DCS#Unit

      local UnitHeight = UnitData:getPoint()

      if UnitHeight > GroupHeightMax then
        GroupHeightMax = UnitHeight
      end
    end

    return GroupHeightMax
  end

  return nil
end

-- RESPAWNING

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
-- @param DCS#country.id CountryID The country ID.
-- @return #table 
function GROUP:SetTemplateCountry( Template, CountryID )
  Template.CountryID = CountryID
  return Template
end

--- Sets the CoalitionID of the group in a Template.
-- @param #GROUP self
-- @param DCS#coalition.side CoalitionID The coalition ID.
-- @return #table 
function GROUP:SetTemplateCoalition( Template, CoalitionID )
  Template.CoalitionID = CoalitionID
  return Template
end


--- Set the heading for the units in degrees within the respawned group.
-- @param #GROUP self
-- @param #number Heading The heading in meters.
-- @return #GROUP self
function GROUP:InitHeading( Heading )
  self.InitRespawnHeading = Heading
  return self
end


--- Set the height for the units in meters for the respawned group. (This is applicable for air units).
-- @param #GROUP self
-- @param #number Height The height in meters.
-- @return #GROUP self
function GROUP:InitHeight( Height )
  self.InitRespawnHeight = Height
  return self
end


--- Set the respawn @{Zone} for the respawned group.
-- @param #GROUP self
-- @param Core.Zone#ZONE Zone The zone in meters.
-- @return #GROUP self
function GROUP:InitZone( Zone )
  self.InitRespawnZone = Zone
  return self
end


--- Randomize the positions of the units of the respawned group within the @{Zone}.
-- When a Respawn happens, the units of the group will be placed at random positions within the Zone (selected).
-- @param #GROUP self
-- @param #boolean PositionZone true will randomize the positions within the Zone.
-- @return #GROUP self
function GROUP:InitRandomizePositionZone( PositionZone )

  self.InitRespawnRandomizePositionZone = PositionZone
  self.InitRespawnRandomizePositionInner = nil
  self.InitRespawnRandomizePositionOuter = nil

  return self
end


--- Randomize the positions of the units of the respawned group in a circle band.
-- When a Respawn happens, the units of the group will be positioned at random places within the Outer and Inner radius.
-- Thus, a band is created around the respawn location where the units will be placed at random positions.
-- @param #GROUP self
-- @param #boolean OuterRadius Outer band in meters from the center.
-- @param #boolean InnerRadius Inner band in meters from the center.
-- @return #GROUP self
function GROUP:InitRandomizePositionRadius( OuterRadius, InnerRadius )
  
  self.InitRespawnRandomizePositionZone = nil
  self.InitRespawnRandomizePositionOuter = OuterRadius
  self.InitRespawnRandomizePositionInner = InnerRadius
  
  return self
end


--- Respawn the @{Wrapper.Group} at a @{Point}.
-- The method will setup the new group template according the Init(Respawn) settings provided for the group.
-- These settings can be provided by calling the relevant Init...() methods of the Group.
-- 
--   - @{#GROUP.InitHeading}: Set the heading for the units in degrees within the respawned group.
--   - @{#GROUP.InitHeight}: Set the height for the units in meters for the respawned group. (This is applicable for air units).
--   - @{#GROUP.InitRandomizeHeading}: Randomize the headings for the units within the respawned group.
--   - @{#GROUP.InitZone}: Set the respawn @{Zone} for the respawned group.
--   - @{#GROUP.InitRandomizeZones}: Randomize the respawn @{Zone} between one of the @{Zone}s given for the respawned group.
--   - @{#GROUP.InitRandomizePositionZone}: Randomize the positions of the units of the respawned group within the @{Zone}.
--   - @{#GROUP.InitRandomizePositionRadius}: Randomize the positions of the units of the respawned group in a circle band.
--   - @{#GROUP.InitRandomizeTemplates}: Randomize the Template for the respawned group.
-- 
-- 
-- Notes:
-- 
--   - When InitZone or InitRandomizeZones is not used, the position of the respawned group will be its current position.
--   - The current alive group will always be destroyed and respawned using the template definition. 
-- 
-- @param Wrapper.Group#GROUP self
-- @param #table Template (optional) The template of the Group retrieved with GROUP:GetTemplate(). If the template is not provided, the template will be retrieved of the group itself.
function GROUP:Respawn( Template, Reset )

  if not Template then
    Template = self:GetTemplate()
  end

  if self:IsAlive() then
    local Zone = self.InitRespawnZone -- Core.Zone#ZONE
    local Vec3 = Zone and Zone:GetVec3() or self:GetVec3()
    local From = { x = Template.x, y = Template.y }
    Template.x = Vec3.x
    Template.y = Vec3.z
    --Template.x = nil
    --Template.y = nil
    
    self:F( #Template.units )
    if Reset == true then
      for UnitID, UnitData in pairs( self:GetUnits() ) do
        local GroupUnit = UnitData -- Wrapper.Unit#UNIT
        self:F( GroupUnit:GetName() )
        if GroupUnit:IsAlive() then
          self:F( "Alive"  )
          local GroupUnitVec3 = GroupUnit:GetVec3() 
          if Zone then
            if self.InitRespawnRandomizePositionZone then
              GroupUnitVec3 = Zone:GetRandomVec3()
            else
              if self.InitRespawnRandomizePositionInner and self.InitRespawnRandomizePositionOuter then
                GroupUnitVec3 = POINT_VEC3:NewFromVec2( From ):GetRandomPointVec3InRadius( self.InitRespawnRandomizePositionsOuter, self.InitRespawnRandomizePositionsInner )
              else
                GroupUnitVec3 = Zone:GetVec3()
              end
            end
          end
          
          Template.units[UnitID].alt = self.InitRespawnHeight and self.InitRespawnHeight or GroupUnitVec3.y
          Template.units[UnitID].x = ( Template.units[UnitID].x - From.x ) + GroupUnitVec3.x -- Keep the original x position of the template and translate to the new position.
          Template.units[UnitID].y = ( Template.units[UnitID].y - From.y ) + GroupUnitVec3.z -- Keep the original z position of the template and translate to the new position.
          Template.units[UnitID].heading = self.InitRespawnHeading and self.InitRespawnHeading or GroupUnit:GetHeading()
          self:F( { UnitID, Template.units[UnitID], Template.units[UnitID] } )
        end
      end
    else
      for UnitID, TemplateUnitData in pairs( Template.units ) do
        self:F( "Reset"  )
        local GroupUnitVec3 = { x = TemplateUnitData.x, y = TemplateUnitData.alt, z = TemplateUnitData.y }
        if Zone then
          if self.InitRespawnRandomizePositionZone then
            GroupUnitVec3 = Zone:GetRandomVec3()
          else
            if self.InitRespawnRandomizePositionInner and self.InitRespawnRandomizePositionOuter then
              GroupUnitVec3 = POINT_VEC3:NewFromVec2( From ):GetRandomPointVec3InRadius( self.InitRespawnRandomizePositionsOuter, self.InitRespawnRandomizePositionsInner )
            else
              GroupUnitVec3 = Zone:GetVec3()
            end
          end
        end
        
        Template.units[UnitID].alt = self.InitRespawnHeight and self.InitRespawnHeight or GroupUnitVec3.y
        Template.units[UnitID].x = ( Template.units[UnitID].x - From.x ) + GroupUnitVec3.x -- Keep the original x position of the template and translate to the new position.
        Template.units[UnitID].y = ( Template.units[UnitID].y - From.y ) + GroupUnitVec3.z -- Keep the original z position of the template and translate to the new position.
        Template.units[UnitID].heading = self.InitRespawnHeading and self.InitRespawnHeading or TemplateUnitData.heading
        self:F( { UnitID, Template.units[UnitID], Template.units[UnitID] } )
      end
    end      
    
  end
  
  self:Destroy()
  _DATABASE:Spawn( Template )
  
  self:ResetEvents()
  
  return self
  
end


--- Respawn a group at an airbase.
-- Note that the group has to be on parking spots at the airbase already in order for this to work.
-- So each unit of the group is respawned at exactly the same parking spot as it currently occupies.
-- @param Wrapper.Group#GROUP self
-- @param #table SpawnTemplate (Optional) The spawn template for the group. If no template is given it is exacted from the group.
-- @param Core.Spawn#SPAWN.Takeoff Takeoff (Optional) Takeoff type. Sould be either SPAWN.Takeoff.Cold or SPAWN.Takeoff.Hot. Default is SPAWN.Takeoff.Hot.
-- @param #boolean Uncontrolled (Optional) If true, spawn in uncontrolled state.
-- @return Wrapper.Group#GROUP Group spawned at airbase or nil if group could not be spawned.
function GROUP:RespawnAtCurrentAirbase(SpawnTemplate, Takeoff, Uncontrolled) -- R2.4
  self:F2( { SpawnTemplate, Takeoff, Uncontrolled} )

  -- Get closest airbase. Should be the one we are currently on.
  local airbase=self:GetCoordinate():GetClosestAirbase()
  
  if airbase then
    self:F2("Closest airbase = "..airbase:GetName())
  else
    self:E("ERROR: could not find closest airbase!")
    return nil
  end
  -- Takeoff type. Default hot.
  Takeoff = Takeoff or SPAWN.Takeoff.Hot
  
  -- Coordinate of the airbase.
  local AirbaseCoord=airbase:GetCoordinate()
  
  -- Spawn template.  
  SpawnTemplate = SpawnTemplate or self:GetTemplate()

  if SpawnTemplate then

    local SpawnPoint = SpawnTemplate.route.points[1]

    -- These are only for ships.
    SpawnPoint.linkUnit = nil
    SpawnPoint.helipadId = nil
    SpawnPoint.airdromeId = nil

    -- Aibase id and category.
    local AirbaseID       = airbase:GetID()
    local AirbaseCategory = airbase:GetDesc().category
    
    if AirbaseCategory == Airbase.Category.SHIP or AirbaseCategory == Airbase.Category.HELIPAD then
      SpawnPoint.linkUnit  = AirbaseID
      SpawnPoint.helipadId = AirbaseID
    elseif AirbaseCategory == Airbase.Category.AIRDROME then
      SpawnPoint.airdromeId = AirbaseID
    end

    
    SpawnPoint.type   = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
    SpawnPoint.action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action
    
    -- Get the units of the group.
    local units=self:GetUnits()

    local x
    local y
    for UnitID=1,#units do
        
      local unit=units[UnitID] --Wrapper.Unit#UNIT

      -- Get closest parking spot of current unit. Note that we look for occupied spots since the unit is currently sitting on it!
      local Parkingspot, TermialID, Distance=unit:GetCoordinate():GetClosestParkingSpot(airbase)
      
      --Parkingspot:MarkToAll("parking spot")
      self:T2(string.format("Closest parking spot distance = %s, terminal ID=%s", tostring(Distance), tostring(TermialID)))

      -- Get unit coordinates for respawning position.
      local uc=unit:GetCoordinate()
      --uc:MarkToAll(string.format("re-spawnplace %s terminal %d", unit:GetName(), TermialID))
      
      SpawnTemplate.units[UnitID].x   = uc.x --Parkingspot.x
      SpawnTemplate.units[UnitID].y   = uc.z --Parkingspot.z
      SpawnTemplate.units[UnitID].alt = uc.y --Parkingspot.y

      SpawnTemplate.units[UnitID].parking    = TermialID
      SpawnTemplate.units[UnitID].parking_id = nil
      
      --SpawnTemplate.units[UnitID].unitId=nil
    end
    
    --SpawnTemplate.groupId=nil
    
    SpawnPoint.x   = SpawnTemplate.units[1].x   --x --AirbaseCoord.x
    SpawnPoint.y   = SpawnTemplate.units[1].y   --y --AirbaseCoord.z
    SpawnPoint.alt = SpawnTemplate.units[1].alt --AirbaseCoord:GetLandHeight()
               
    SpawnTemplate.x = SpawnTemplate.units[1].x  --x --AirbaseCoord.x
    SpawnTemplate.y = SpawnTemplate.units[1].y  --y --AirbaseCoord.z
    
    -- Set uncontrolled state.
    SpawnTemplate.uncontrolled=Uncontrolled

    -- Destroy old group.
    self:Destroy(false)
    
    _DATABASE:Spawn( SpawnTemplate )
  
    -- Reset events.
    self:ResetEvents()

    return self
  end
  
  return nil
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
-- @return #boolean true if in the first unit of the group is in the air or #nil if the GROUP is not existing or not alive.   
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

--- Returns the DCS descriptor table of the nth unit of the group.
-- @param #GROUP self
-- @param #number n (Optional) The number of the unit for which the dscriptor is returned.
-- @return DCS#Object.Desc The descriptor of the first unit of the group or #nil if the group does not exist any more.   
function GROUP:GetDCSDesc(n)
  -- Default.
  n=n or 1
  
  local unit=self:GetUnit(n)
  if unit and unit:IsAlive()~=nil then
    local desc=unit:GetDesc()
    return desc
  end
  
  return nil
end

do -- Route methods

  --- (AIR) Return the Group to an @{Wrapper.Airbase#AIRBASE}.  
  -- The following things are to be taken into account:
  -- 
  --   * The group is respawned to achieve the RTB, there may be side artefacts as a result of this. (Like weapons suddenly come back).
  --   * A group consisting out of more than one unit, may rejoin formation when respawned.
  --   * A speed can be given in km/h. If no speed is specified, the maximum speed of the first unit will be taken to return to base.
  --   * When there is no @{Wrapper.Airbase} object specified, the group will return to the home base if the route of the group is pinned at take-off or at landing to a base.
  --   * When there is no @{Wrapper.Airbase} object specified and the group route is not pinned to any airbase, it will return to the nearest airbase.
  -- 
  -- @param #GROUP self
  -- @param Wrapper.Airbase#AIRBASE RTBAirbase (optional) The @{Wrapper.Airbase} to return to. If blank, the controllable will return to the nearest friendly airbase.
  -- @param #number Speed (optional) The Speed, if no Speed is given, the maximum Speed of the first unit is selected. 
  -- @return #GROUP
  function GROUP:RouteRTB( RTBAirbase, Speed )
    self:F( { RTBAirbase:GetName(), Speed } )
  
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
    
        self:F(AirbaseAirPoint )
    
        local Points = { PointFrom, AirbaseAirPoint }
    
        self:T3( Points )

        local Template = self:GetTemplate()
        Template.route.points = Points
        self:Respawn( Template )
    
        --self:Route( Points )
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
  
    local HasPlayers = false
  
    local PlayerNames = {}
    
    local Units = self:GetUnits()
    for UnitID, UnitData in pairs( Units ) do
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = Unit:GetPlayerName()
      if PlayerName and PlayerName ~= "" then
        PlayerNames = PlayerNames or {}
        table.insert( PlayerNames, PlayerName )
        HasPlayers = true
      end   
    end

    if HasPlayers == true then    
      self:F2( PlayerNames )
      return PlayerNames
    end
    
    return nil
  end


  --- Get the active player count in the group.
  -- @param #GROUP self
  -- @return #number The amount of players.
  function GROUP:GetPlayerCount()
  
    local PlayerCount = 0
    
    local Units = self:GetUnits()
    for UnitID, UnitData in pairs( Units or {} ) do
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = Unit:GetPlayerName()
      if PlayerName and PlayerName ~= "" then
        PlayerCount = PlayerCount + 1
      end   
    end

    return PlayerCount
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