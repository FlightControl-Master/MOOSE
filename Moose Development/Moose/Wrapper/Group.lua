--- **Wrapper** - GROUP wraps the DCS Class Group objects.
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
-- **IMPORTANT: ONE SHOULD NEVER SANITIZE these GROUP OBJECT REFERENCES! (make the GROUP object references nil).**
--
-- ===
--
-- For each DCS Group object alive within a running mission, a GROUP wrapper object (instance) will be created within the global _DATABASE object (an instance of @{Core.Database#DATABASE}).
-- This is done at the beginning of the mission (when the mission starts), and dynamically when new DCS Group objects are spawned (using the @{Core.Spawn} class).
--
-- The GROUP class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the DCS Group or the DCS GroupName.
--
-- The GROUP methods will reference the DCS Group object by name when it is needed during API execution.
-- If the DCS Group object does not exist or is nil, the GROUP methods will return nil and may log an exception in the DCS.log file.
--
-- ===
--
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Wrapper/Group)
--
-- ===
--
-- ### Author: **FlightControl**
--
-- ### Contributions:
--
--   * **Entropy**, **Afinegan**: Came up with the requirement for AIOnOff().
--   * **Applevangelist**: various
--
-- ===
--
-- @module Wrapper.Group
-- @image Wrapper_Group.JPG

---
-- @type GROUP
-- @extends Wrapper.Controllable#CONTROLLABLE
-- @field #string GroupName The name of the group.


--- Wrapper class of the DCS world Group object.
--
-- ## Finding groups
--
-- The GROUP class provides the following functions to retrieve quickly the relevant GROUP instance:
--
--  * @{#GROUP.Find}(): Find a GROUP instance from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using a DCS Group object.
--  * @{#GROUP.FindByName}(): Find a GROUP instance from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using a DCS Group name.
--  * @{#GROUP.FindByMatching}(): Find a GROUP instance from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using pattern matching.
--  * @{#GROUP.FindAllByMatching}(): Find all GROUP instances from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using pattern matching.
--
-- ## Tasking of groups
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
--          -- @param Wrapper.Group#GROUP HeliGroup
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
-- The group can be validated whether it is completely, partly or not within a @{Core.Zone}.
-- Use the following Zone validation methods on the group:
--
--   * @{#GROUP.IsCompletelyInZone}: Returns true if all units of the group are within a @{Core.Zone}.
--   * @{#GROUP.IsPartlyInZone}: Returns true if some units of the group are within a @{Core.Zone}.
--   * @{#GROUP.IsNotInZone}: Returns true if none of the group units of the group are within a @{Core.Zone}.
--
-- The zone can be of any @{Core.Zone} class derived from @{Core.Zone#ZONE_BASE}. So, these methods are polymorphic to the zones tested on.
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

--- Generalized group attributes. See [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes) on hoggit.
-- @type GROUP.Attribute
-- @field #string AIR_TRANSPORTPLANE Airplane with transport capability. This can be used to transport other assets.
-- @field #string AIR_AWACS Airborne Early Warning and Control System.
-- @field #string AIR_FIGHTER Fighter, interceptor, ... airplane.
-- @field #string AIR_BOMBER Aircraft which can be used for strategic bombing.
-- @field #string AIR_TANKER Airplane which can refuel other aircraft.
-- @field #string AIR_TRANSPORTHELO Helicopter with transport capability. This can be used to transport other assets.
-- @field #string AIR_ATTACKHELO Attack helicopter.
-- @field #string AIR_UAV Unpiloted Aerial Vehicle, e.g. drones.
-- @field #string AIR_OTHER Any airborne unit that does not fall into any other airborne category.
-- @field #string GROUND_APC Infantry carriers, in particular Amoured Personell Carrier. This can be used to transport other assets.
-- @field #string GROUND_TRUCK Unarmed ground vehicles, which has the DCS "Truck" attribute.
-- @field #string GROUND_INFANTRY Ground infantry assets.
-- @field #string GROUND_IFV Ground Infantry Fighting Vehicle.
-- @field #string GROUND_ARTILLERY Artillery assets.
-- @field #string GROUND_TANK Tanks (modern or old).
-- @field #string GROUND_TRAIN Trains. Not that trains are **not** yet properly implemented in DCS and cannot be used currently.
-- @field #string GROUND_EWR Early Warning Radar.
-- @field #string GROUND_AAA Anti-Aircraft Artillery.
-- @field #string GROUND_SAM Surface-to-Air Missile system or components.
-- @field #string GROUND_OTHER Any ground unit that does not fall into any other ground category.
-- @field #string NAVAL_AIRCRAFTCARRIER Aircraft carrier.
-- @field #string NAVAL_WARSHIP War ship, i.e. cruisers, destroyers, firgates and corvettes.
-- @field #string NAVAL_ARMEDSHIP Any armed ship that is not an aircraft carrier, a cruiser, destroyer, firgatte or corvette.
-- @field #string NAVAL_UNARMEDSHIP Any unarmed naval vessel.
-- @field #string NAVAL_OTHER Any naval unit that does not fall into any other naval category.
-- @field #string OTHER_UNKNOWN Anything that does not fall into any other category.
GROUP.Attribute = {
  AIR_TRANSPORTPLANE="Air_TransportPlane",
  AIR_AWACS="Air_AWACS",
  AIR_FIGHTER="Air_Fighter",
  AIR_BOMBER="Air_Bomber",
  AIR_TANKER="Air_Tanker",
  AIR_TRANSPORTHELO="Air_TransportHelo",
  AIR_ATTACKHELO="Air_AttackHelo",
  AIR_UAV="Air_UAV",
  AIR_OTHER="Air_OtherAir",
  GROUND_APC="Ground_APC",
  GROUND_TRUCK="Ground_Truck",
  GROUND_INFANTRY="Ground_Infantry",
  GROUND_IFV="Ground_IFV",
  GROUND_ARTILLERY="Ground_Artillery",
  GROUND_TANK="Ground_Tank",
  GROUND_TRAIN="Ground_Train",
  GROUND_EWR="Ground_EWR",
  GROUND_AAA="Ground_AAA",
  GROUND_SAM="Ground_SAM",
  GROUND_OTHER="Ground_OtherGround",
  NAVAL_AIRCRAFTCARRIER="Naval_AircraftCarrier",
  NAVAL_WARSHIP="Naval_WarShip",
  NAVAL_ARMEDSHIP="Naval_ArmedShip",
  NAVAL_UNARMEDSHIP="Naval_UnarmedShip",
  NAVAL_OTHER="Naval_OtherNaval",
  OTHER_UNKNOWN="Other_Unknown",
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

--- Find a GROUP using the DCS Group Name.
-- @param #GROUP self
-- @param #string GroupName The DCS Group Name.
-- @return #GROUP The GROUP.
function GROUP:FindByName( GroupName )

  local GroupFound = _DATABASE:FindGroup( GroupName )
  return GroupFound
end

--- Find the first(!) GROUP matching using patterns. Note that this is **a lot** slower than `:FindByName()`!
-- @param #GROUP self
-- @param #string Pattern The pattern to look for. Refer to [LUA patterns](http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_\(Regular_Expressions\)) for regular expressions in LUA.
-- @return #GROUP The GROUP.
-- @usage
--          -- Find a group with a partial group name
--          local grp = GROUP:FindByMatching( "Apple" )
--          -- will return e.g. a group named "Apple-1-1"
--
--          -- using a pattern
--          local grp = GROUP:FindByMatching( ".%d.%d$" )
--          -- will return the first group found ending in "-1-1" to "-9-9", but not e.g. "-10-1"
function GROUP:FindByMatching( Pattern )
  local GroupFound = nil

  for name,group in pairs(_DATABASE.GROUPS) do
    if string.match(name, Pattern ) then
      GroupFound = group
      break
    end
  end

  return GroupFound
end

--- Find all GROUP objects matching using patterns. Note that this is **a lot** slower than `:FindByName()`!
-- @param #GROUP self
-- @param #string Pattern The pattern to look for. Refer to [LUA patterns](http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_\(Regular_Expressions\)) for regular expressions in LUA.
-- @return #table Groups Table of matching #GROUP objects found
-- @usage
--          -- Find all group with a partial group name
--          local grptable = GROUP:FindAllByMatching( "Apple" )
--          -- will return all groups with "Apple" in the name
--
--          -- using a pattern
--          local grp = GROUP:FindAllByMatching( ".%d.%d$" )
--          -- will return the all groups found ending in "-1-1" to "-9-9", but not e.g. "-10-1" or "-1-10"
function GROUP:FindAllByMatching( Pattern )
  local GroupsFound = {}

  for name,group in pairs(_DATABASE.GROUPS) do
    if string.match(name, Pattern ) then
      GroupsFound[#GroupsFound+1] = group
    end
  end

  return GroupsFound
end

-- DCS Group methods support.

--- Returns the DCS Group.
-- @param #GROUP self
-- @return DCS#Group The DCS Group.
function GROUP:GetDCSObject()

  --if (not self.LastCallDCSObject) or (self.LastCallDCSObject and timer.getTime() - self.LastCallDCSObject  > 1) then

    -- Get DCS group.
    local DCSGroup = Group.getByName( self.GroupName )

    if DCSGroup then
      self.LastCallDCSObject = timer.getTime()
      self.DCSObject = DCSGroup
      return DCSGroup
   -- else
     -- self.DCSObject = nil
     -- self.LastCallDCSObject = nil
    end
  
  --else
    --return self.DCSObject
  --end
  
  --self:E(string.format("ERROR: Could not get DCS group object of group %s because DCS object could not be found!", tostring(self.GroupName)))
  return nil
end

--- Returns the @{DCS#Position3} position vectors indicating the point and direction vectors in 3D of the POSITIONABLE within the mission.
-- @param Wrapper.Positionable#POSITIONABLE self
-- @return DCS#Position The 3D position vectors of the POSITIONABLE or #nil if the groups not existing or alive.
function GROUP:GetPositionVec3() -- Overridden from POSITIONABLE:GetPositionVec3()
  --self:F2( self.PositionableName )

  local DCSPositionable = self:GetDCSObject()

  if DCSPositionable then
   local unit = DCSPositionable:getUnits()[1]
   if unit then
     local PositionablePosition = unit:getPosition().p
    --self:T3( PositionablePosition )
    return PositionablePosition
    end
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
-- @return #boolean `true` if the group is alive *and* active, `false` if the group is alive but inactive or `#nil` if the group does not exist anymore.
function GROUP:IsAlive()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject() -- DCS#Group

  if DCSGroup then
    if DCSGroup:isExist() then
      local DCSUnit = DCSGroup:getUnit(1) -- DCS#Unit
      if DCSUnit then
        local GroupIsAlive = DCSUnit:isActive()
        --self:T3( GroupIsAlive )
        return GroupIsAlive
      end
    end
  end

  return nil
end

--- Returns if the group is activated.
-- @param #GROUP self
-- @return #boolean `true` if group is activated or `#nil` The group is not existing or alive.
function GROUP:IsActive()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject() -- DCS#Group

  if DCSGroup and DCSGroup:isExist() then
    local unit = DCSGroup:getUnit(1)
    if unit then
      local GroupIsActive = unit:isActive()
    return GroupIsActive
    end
  end

  return nil
end



--- Destroys the DCS Group and all of its DCS Units.
-- Note that this destroy method also can raise a destroy event at run-time.
-- So all event listeners will catch the destroy event of this group for each unit in the group.
-- To raise these events, provide the `GenerateEvent` parameter.
-- @param #GROUP self
-- @param #boolean GenerateEvent If true, a crash [AIR] or dead [GROUND] event for each unit is generated. If false, if no event is triggered. If nil, a RemoveUnit event is triggered.
-- @param #number delay Delay in seconds before despawning the group.
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
function GROUP:Destroy( GenerateEvent, delay )
  --self:F2( self.GroupName )

  if delay and delay>0 then
    self:ScheduleOnce(delay, GROUP.Destroy, self, GenerateEvent)
  else

    --local DCSGroup = self:GetDCSObject()
    local DCSGroup = Group.getByName( self.GroupName )

    if DCSGroup then
      for Index, UnitData in pairs( DCSGroup:getUnits() ) do
        if GenerateEvent and GenerateEvent == true then
          if self:IsAir() then
            self:CreateEventCrash( timer.getTime(), UnitData )
            --self:ScheduleOnce(1,self.CreateEventCrash,self,timer.getTime(),UnitData)
          else
            self:CreateEventDead( timer.getTime(), UnitData )
            --self:ScheduleOnce(1,self.CreateEventDead,self,timer.getTime(),UnitData)
          end
        elseif GenerateEvent == false then
          -- Do nothing!
        else
          self:CreateEventRemoveUnit( timer.getTime(), UnitData )
          --self:ScheduleOnce(1,self.CreateEventRemoveUnit,self,timer.getTime(),UnitData)
        end
      end
      USERFLAG:New( self:GetName() ):Set( 100 )
      DCSGroup:destroy()
      DCSGroup = nil
    end
  end

  return nil
end


--- Returns category of the DCS Group. Returns one of
--
-- * Group.Category.AIRPLANE
-- * Group.Category.HELICOPTER
-- * Group.Category.GROUND
-- * Group.Category.SHIP
-- * Group.Category.TRAIN
--
-- @param #GROUP self
-- @return DCS#Group.Category The category ID.
function GROUP:GetCategory()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    --self:T3( GroupCategory )
    return GroupCategory
  end

  return nil
end

--- Returns the category name of the #GROUP.
-- @param #GROUP self
-- @return #string Category name = Helicopter, Airplane, Ground Unit, Ship, Train.
function GROUP:GetCategoryName()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local CategoryNames = {
      [Group.Category.AIRPLANE] = "Airplane",
      [Group.Category.HELICOPTER] = "Helicopter",
      [Group.Category.GROUND] = "Ground Unit",
      [Group.Category.SHIP] = "Ship",
      [Group.Category.TRAIN] = "Train",
    }
    local GroupCategory = DCSGroup:getCategory()
    --self:T3( GroupCategory )

    return CategoryNames[GroupCategory]
  end

  return nil
end

--- Returns the coalition of the DCS Group.
-- @param #GROUP self
-- @return DCS#coalition.side The coalition side of the DCS Group.
function GROUP:GetCoalition()
  --self:F2( self.GroupName )
  if self.GroupCoalition ~= nil then
    return self.GroupCoalition
  else
    local DCSGroup = self:GetDCSObject()
    if DCSGroup then
      local GroupCoalition = DCSGroup:getCoalition()
      --self:T3( GroupCoalition )
      self.GroupCoalition = GroupCoalition
      return GroupCoalition
    end
  end
  return nil
end

--- Returns the country of the DCS Group.
-- @param #GROUP self
-- @return DCS#country.id The country identifier or nil if the DCS Group is not existing or alive.
function GROUP:GetCountry()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local GroupCountry = DCSGroup:getUnit(1):getCountry()
    --self:T3( GroupCountry )
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

  if _units then

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

  return nil
end

--- Returns the maximum speed of the group.
-- If the group is heterogenious and consists of different units, the max speed of the slowest unit is returned.
-- @param #GROUP self
-- @return #number Speed in km/h.
function GROUP:GetSpeedMax()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()
  if DCSGroup then

    local Units=self:GetUnits()

    local speedmax=nil

    for _,unit in pairs(Units) do
      local unit=unit --Wrapper.Unit#UNIT

      local speed=unit:GetSpeedMax()

      if speedmax==nil or speed<speedmax then
        speedmax=speed
      end

      --env.info(string.format("FF unit %s: speed=%.1f, speedmax=%.1f", unit:GetName(), speed, speedmax))

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
  --self:F2( self.GroupName )

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
-- @return #table of Wrapper.Unit#UNIT objects, indexed by number.
function GROUP:GetUnits()
  --self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits() or {}
    local Units = {}
    for Index, UnitData in pairs( DCSUnits ) do

      local unit=UNIT:Find( UnitData )
      if unit then
        Units[#Units+1] = UNIT:Find( UnitData )
      else
        local UnitName=UnitData:getName()
        unit=_DATABASE:AddUnit(UnitName)
        Units[#Units+1]=unit
      end
    end
    --self:T3( Units )
    return Units
  end

  return nil
end

--- Returns a list of @{Wrapper.Unit} objects of the @{Wrapper.Group} that are occupied by a player.
-- @param #GROUP self
-- @return #list<Wrapper.Unit#UNIT> The list of player occupied @{Wrapper.Unit} objects of the @{Wrapper.Group}.
function GROUP:GetPlayerUnits()
  --self:F2( { self.GroupName } )
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
    --self:T3( Units )
    return Units
  end

  return nil
end

--- Check if an (air) group is a client or player slot. Information is retrieved from the group template.
-- @param #GROUP self
-- @return #boolean If true, group is associated with a client or player slot.
function GROUP:IsPlayer()
  return self:GetUnit(1):IsPlayer()
end

--- Returns the UNIT wrapper object with number UnitNumber. If it doesn't exist, tries to return the next available unit.
-- If no underlying DCS Units exist, the method will return nil.
-- @param #GROUP self
-- @param #number UnitNumber The number of the UNIT wrapper class to be returned.
-- @return Wrapper.Unit#UNIT The UNIT object or nil
function GROUP:GetUnit( UnitNumber )
  local DCSGroup = self:GetDCSObject()
  if DCSGroup then
    local UnitFound = nil
    -- 2.7.1 dead event bug, return the first alive unit instead
    -- Maybe fixed with 2.8?
    local units = DCSGroup:getUnits() or {}
    if units[UnitNumber] then
      local UnitFound = UNIT:Find(units[UnitNumber])
      if UnitFound then
        return UnitFound
      end
    else
      for _,_unit in pairs(units) do
        local UnitFound = UNIT:Find(_unit)
        if UnitFound then
          return UnitFound
        end
      end
    end
  end
  return nil
end


--- Returns the DCS Unit with number UnitNumber.
-- If the underlying DCS Unit does not exist, the method will return try to find the next unit. Returns nil if no units are found.
-- @param #GROUP self
-- @param #number UnitNumber The number of the DCS Unit to be returned.
-- @return DCS#Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then

    if DCSGroup.getUnit and DCSGroup:getUnit( UnitNumber ) then
      return DCSGroup:getUnit( UnitNumber )
    else

      -- 2.7.1 dead event bug, return the first alive unit instead
      local units = DCSGroup:getUnits() or {}

      for _,_unit in pairs(units) do
        if _unit and _unit:isExist() then
          return _unit
        end
      end
    end
  end

  return nil
end

--- Returns current size of the DCS Group.
-- If some of the DCS Units of the DCS Group are destroyed the size of the DCS Group is changed.
-- @param #GROUP self
-- @return #number The DCS Group size.
function GROUP:GetSize()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then

    local GroupSize = DCSGroup:getSize()

    if GroupSize then
      return GroupSize
    else
      return 0
    end
  end

  return nil
end

--- Count number of alive units in the group.
-- @param #GROUP self
-- @return #number Number of alive units. If DCS group is nil, 0 is returned.
function GROUP:CountAliveUnits()
  --self:F3( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local units=self:GetUnits()
    local n=0
    for _,_unit in pairs(units) do
      local unit=_unit --Wrapper.Unit#UNIT
      if unit and unit:IsAlive() then
        n=n+1
      end
    end
    return n
  end

  return 0
end

--- Get the first unit of the group which is alive.
-- @param #GROUP self
-- @return Wrapper.Unit#UNIT First unit alive.
function GROUP:GetFirstUnitAlive()
  --self:F3({self.GroupName})
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local units=self:GetUnits()
    for _,_unit in pairs(units) do
      local unit=_unit --Wrapper.Unit#UNIT
      if unit and unit:IsAlive() then
        return unit
      end
    end
  end

  return nil
end

--- Get the first unit of the group. Might be nil!
-- @param #GROUP self
-- @return Wrapper.Unit#UNIT First unit or nil if it does not exist.
function GROUP:GetFirstUnit()
  --self:F3({self.GroupName})
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local units=self:GetUnits()
    return units[1]
  end

  return nil
end

--- Returns the average velocity Vec3 vector.
-- @param Wrapper.Group#GROUP self
-- @return DCS#Vec3 The velocity Vec3 vector or `#nil` if the GROUP is not existing or alive.
function GROUP:GetVelocityVec3()
  --self:F2( self.GroupName )

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

--- Returns the average group altitude in meters.
-- @param Wrapper.Group#GROUP self
-- @param #boolean FromGround Measure from the ground or from sea level (ASL). Provide **true** for measuring from the ground (AGL). **false** or **nil** if you measure from sea level.
-- @return #number The altitude of the group or nil if is not existing or alive.
function GROUP:GetAltitude(FromGround)
  --self:F2( self.GroupName )
  return self:GetHeight(FromGround)
end

--- Returns the average group height in meters.
-- @param Wrapper.Group#GROUP self
-- @param #boolean FromGround Measure from the ground or from sea level (ASL). Provide **true** for measuring from the ground (AGL). **false** or **nil** if you measure from sea level.
-- @return #number The height of the group or nil if is not existing or alive.
function GROUP:GetHeight( FromGround )
  --self:F2( self.GroupName )

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
  --self:F3( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupInitialSize = DCSGroup:getInitialSize()
    --self:T3( GroupInitialSize )
    return GroupInitialSize
  end

  return nil
end


--- Returns the DCS Units of the DCS Group.
-- @param #GROUP self
-- @return #table The DCS Units.
function GROUP:GetDCSUnits()
  --self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits()
    --self:T3( DCSUnits )
    return DCSUnits
  end

  return nil
end


--- Activates a late activated GROUP.
-- @param #GROUP self
-- @param #number delay Delay in seconds, before the group is activated.
-- @return #GROUP self
function GROUP:Activate(delay)
  --self:F2( { self.GroupName } )
  if delay and delay>0 then
    self:ScheduleOnce(delay, GROUP.Activate, self)
  else
    trigger.action.activateGroup( self:GetDCSObject() )
  end
  return self
end

--- Deactivates an activated GROUP.
-- @param #GROUP self
-- @param #number delay Delay in seconds, before the group is activated.
-- @return #GROUP self
function GROUP:Deactivate(delay)
  --self:F2( { self.GroupName } )
  if delay and delay>0 then
    self:ScheduleOnce(delay, GROUP.Deactivate, self)
  else
    trigger.action.deactivateGroup( self:GetDCSObject() )
  end
  return self
end


--- Gets the type name of the group.
-- @param #GROUP self
-- @return #string The type name of the group.
function GROUP:GetTypeName()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupTypeName = DCSGroup:getUnit(1):getTypeName()
    --self:T3( GroupTypeName )
    return( GroupTypeName )
  end

  return nil
end

--- [AIRPLANE] Get the NATO reporting name (platform, e.g. "Flanker") of a GROUP (note - first unit the group). "Bogey" if not found. Currently airplanes only!
--@param #GROUP self
--@return #string NatoReportingName or "Bogey" if unknown.
function GROUP:GetNatoReportingName()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupTypeName = DCSGroup:getUnit(1):getTypeName()
    --self:T3( GroupTypeName )
    return UTILS.GetReportingName(GroupTypeName)
  end

  return "Bogey"

end

--- Gets the player name of the group.
-- @param #GROUP self
-- @return #string The player name of the group.
function GROUP:GetPlayerName()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local PlayerName = DCSGroup:getUnit(1):getPlayerName()
    --self:T3( PlayerName )
    return( PlayerName )
  end

  return nil
end


--- Gets the CallSign of the first DCS Unit of the DCS Group.
-- @param #GROUP self
-- @return #string The CallSign of the first DCS Unit of the DCS Group.
function GROUP:GetCallsign()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCallSign = DCSGroup:getUnit(1):getCallsign()
    --self:T3( GroupCallSign )
    return GroupCallSign
  end

  BASE:E( { "Cannot GetCallsign", Positionable = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the current point (Vec2 vector) of the first DCS Unit in the DCS Group.
-- @param #GROUP self
-- @return DCS#Vec2 Current Vec2 point of the first DCS Unit of the DCS Group.
function GROUP:GetVec2()

  local Unit=self:GetUnit(1)

  if Unit then
    local vec2=Unit:GetVec2()
    return vec2
  end

end

--- Returns the current Vec3 vector of the first Unit in the GROUP.
-- @param #GROUP self
-- @return DCS#Vec3 Current Vec3 of the first Unit of the GROUP or nil if cannot be found.
function GROUP:GetVec3()

  -- Get first unit.
  local unit=self:GetUnit(1)

  if unit then
    local vec3=unit:GetVec3()
    return vec3
  end

  self:E("ERROR: Cannot get Vec3 of group "..tostring(self.GroupName))
  return nil
end

--- Returns the average Vec3 vector of the Units in the GROUP.
-- @param #GROUP self
-- @return DCS#Vec3 Current Vec3 of the GROUP  or nil if cannot be found.
function GROUP:GetAverageVec3()
  local units = self:GetUnits() or {}
    -- Init.
  local x=0 ; local y=0 ; local z=0 ; local n=0
  -- Loop over all units.
  for _,unit in pairs(units) do
    local vec3=nil --DCS#Vec3
    if unit and unit:IsAlive() then
      vec3 = unit:GetVec3()
    end
    if vec3 then
      -- Sum up posits.
      x=x+vec3.x
      y=y+vec3.y
      z=z+vec3.z
      -- Increase counter.
      n=n+1
    end
  end

  if n>0 then
    -- Average.
    local Vec3={x=x/n, y=y/n, z=z/n} --DCS#Vec3
    return Vec3
  else
    return self:GetVec3()
  end
end

--- Returns a POINT_VEC2 object indicating the point in 2D of the first UNIT of the GROUP within the mission.
-- @param #GROUP self
-- @return Core.Point#POINT_VEC2 The 2D point vector of the first DCS Unit of the GROUP.
-- @return #nil The first UNIT is not existing or alive.
function GROUP:GetPointVec2()
  --self:F2(self.GroupName)

  local FirstUnit = self:GetUnit(1)

  if FirstUnit then
    local FirstUnitPointVec2 = FirstUnit:GetPointVec2()
    --self:T3(FirstUnitPointVec2)
    return FirstUnitPointVec2
  end

  BASE:E( { "Cannot GetPointVec2", Group = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns a COORDINATE object indicating the average position of the GROUP within the mission.
-- @param Wrapper.Group#GROUP self
-- @return Core.Point#COORDINATE The COORDINATE of the GROUP.
function GROUP:GetAverageCoordinate()
  local vec3 = self:GetAverageVec3()
  if vec3 then
    local coord = COORDINATE:NewFromVec3(vec3)
    local Heading = self:GetHeading()
    coord.Heading = Heading
    return coord
  else
    local coord = self:GetCoordinate()
    if coord then
      return coord
    else
      BASE:E( { "Cannot GetAverageCoordinate", Group = self, Alive = self:IsAlive() } )
      return nil
    end
  end
end

--- Returns a COORDINATE object indicating the point of the first UNIT of the GROUP within the mission.
-- @param Wrapper.Group#GROUP self
-- @return Core.Point#COORDINATE The COORDINATE of the GROUP.
function GROUP:GetCoordinate()

  local Units = self:GetUnits()  or {}

  for _,_unit in pairs(Units) do
    local FirstUnit = _unit -- Wrapper.Unit#UNIT

    if FirstUnit and FirstUnit:IsAlive() then

      local FirstUnitCoordinate = FirstUnit:GetCoordinate()

      if FirstUnitCoordinate then
        local Heading = self:GetHeading()
        FirstUnitCoordinate.Heading = Heading
        return FirstUnitCoordinate
      end

    end
  end
  -- no luck, try the API way
  
  local DCSGroup = Group.getByName(self.GroupName)
  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits() or {}
    for _,_unit in pairs(DCSUnits) do
      if Object.isExist(_unit) then
        local position = _unit:getPosition()
        local point = position.p ~= nil and position.p or _unit:GetPoint()
        if point then
          --self:I(point)
          local coord = COORDINATE:NewFromVec3(point)
          return coord
        end
      end
    end
  end
  
  BASE:E( { "Cannot GetCoordinate", Group = self, Alive = self:IsAlive() } )

end


--- Returns a random @{DCS#Vec3} vector (point in 3D of the UNIT within the mission) within a range around the first UNIT of the GROUP.
-- @param #GROUP self
-- @param #number Radius Radius in meters.
-- @return DCS#Vec3 The random 3D point vector around the first UNIT of the GROUP or #nil The GROUP is invalid or empty.
-- @usage
-- -- If Radius is ignored, returns the DCS#Vec3 of first UNIT of the GROUP
function GROUP:GetRandomVec3(Radius)
  --self:F2(self.GroupName)

  local FirstUnit = self:GetUnit(1)

  if FirstUnit then
    local FirstUnitRandomPointVec3 = FirstUnit:GetRandomVec3(Radius)
    --self:T3(FirstUnitRandomPointVec3)
    return FirstUnitRandomPointVec3
  end

  BASE:E( { "Cannot GetRandomVec3", Group = self, Alive = self:IsAlive() } )

  return nil
end

--- Returns the mean heading of every UNIT in the GROUP in degrees
-- @param #GROUP self
-- @return #number Mean heading of the GROUP in degrees or #nil The first UNIT is not existing or alive.
function GROUP:GetHeading()
  --self:F2(self.GroupName)

  --self:F2(self.GroupName)

  local GroupSize = self:GetSize()
  local HeadingAccumulator = 0
  local n=0
  local Units = self:GetUnits()

  if GroupSize then
    for _,unit in pairs(Units) do
      if unit and unit:IsAlive() then
        HeadingAccumulator = HeadingAccumulator + unit:GetHeading()
        n=n+1
      end
    end
    return math.floor(HeadingAccumulator / n)
  end

  BASE:E( { "Cannot GetHeading", Group = self, Alive = self:IsAlive() } )

  return nil

end

--- Return the fuel state and unit reference for the unit with the least
-- amount of fuel in the group.
-- @param #GROUP self
-- @return #number The fuel state of the unit with the least amount of fuel.
-- @return Wrapper.Unit#UNIT reference to #Unit object for further processing.
function GROUP:GetFuelMin()
  --self:F3(self.ControllableName)

  if not self:GetDCSObject() then
    BASE:E( { "Cannot GetFuel", Group = self, Alive = self:IsAlive() } )
    return 0
  end

  local min  = 65535  -- some sufficiently large number to init with
  local unit = nil
  local tmp  = nil

  for UnitID, UnitData in pairs( self:GetUnits() ) do
    if UnitData and UnitData:IsAlive() then
      tmp = UnitData:GetFuel()
      if tmp < min then
        min = tmp
        unit = UnitData
      end
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
  --self:F( self.ControllableName )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local GroupSize = self:GetSize()
    local TotalFuel = 0
    for UnitID, UnitData in pairs( self:GetUnits() ) do
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local UnitFuel = Unit:GetFuel() or 0
      --self:F( { Fuel = UnitFuel } )
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


--- Get the number of shells, rockets, bombs and missiles the whole group currently has.
-- @param #GROUP self
-- @return #number Total amount of ammo the group has left. This is the sum of shells, rockets, bombs and missiles of all units.
-- @return #number Number of shells left.
-- @return #number Number of rockets left.
-- @return #number Number of bombs left.
-- @return #number Number of missiles left.
-- @return #number Number of artillery shells left (with explosive mass, included in shells; shells can also be machine gun ammo)
function GROUP:GetAmmunition()
  --self:F( self.ControllableName )

  local DCSControllable = self:GetDCSObject()

  local Ntot=0
  local Nshells=0
  local Nrockets=0
  local Nmissiles=0
  local Nbombs=0
  local Narti=0

  if DCSControllable then

    -- Loop over units.
    for UnitID, UnitData in pairs( self:GetUnits() ) do
      local Unit = UnitData -- Wrapper.Unit#UNIT

      -- Get ammo of the unit
      local ntot, nshells, nrockets, nbombs, nmissiles, narti = Unit:GetAmmunition()

      Ntot=Ntot+ntot
      Nshells=Nshells+nshells
      Nrockets=Nrockets+nrockets
      Nmissiles=Nmissiles+nmissiles
      Nbombs=Nbombs+nbombs
      Narti=Narti+narti
    end

  end

  return Ntot, Nshells, Nrockets, Nbombs, Nmissiles, Narti
end


do -- Is Zone methods


--- Check if any unit of a group is inside a @{Core.Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns `true` if *at least one unit* is inside the zone or `false` if *no* unit is inside.
function GROUP:IsInZone( Zone )

  if self:IsAlive() then

    for UnitID, UnitData in pairs(self:GetUnits()) do
      local Unit = UnitData -- Wrapper.Unit#UNIT

      local vec2 = nil
      if Unit then
       -- Get 2D vector. That's all we need for the zone check.
       vec2=Unit:GetVec2()
      end

      if vec2 and Zone:IsVec2InZone(vec2) then
        return true  -- At least one unit is in the zone. That is enough.
      end

    end

    return false
  end

  return nil
end

--- Returns true if all units of the group are within a @{Core.Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is completely within the @{Core.Zone#ZONE_BASE}
function GROUP:IsCompletelyInZone( Zone )
  --self:F2( { self.GroupName, Zone } )

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

--- Returns true if some but NOT ALL units of the group are within a @{Core.Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is partially within the @{Core.Zone#ZONE_BASE}
function GROUP:IsPartlyInZone( Zone )
  --self:F2( { self.GroupName, Zone } )

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

--- Returns true if part or all units of the group are within a @{Core.Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is partially or completely within the @{Core.Zone#ZONE_BASE}.
function GROUP:IsPartlyOrCompletelyInZone( Zone )
  return self:IsPartlyInZone(Zone) or self:IsCompletelyInZone(Zone)
end

--- Returns true if none of the group units of the group are within a @{Core.Zone}.
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the Group is not within the @{Core.Zone#ZONE_BASE}
function GROUP:IsNotInZone( Zone )
  --self:F2( { self.GroupName, Zone } )

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

--- Returns the number of UNITs that are in the @{Core.Zone}
-- @param #GROUP self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #number The number of UNITs that are in the @{Core.Zone}
function GROUP:CountInZone( Zone )
  --self:F2( {self.GroupName, Zone} )
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
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local IsAirResult = DCSGroup:getCategory() == Group.Category.AIRPLANE or DCSGroup:getCategory() == Group.Category.HELICOPTER
    --self:T3( IsAirResult )
    return IsAirResult
  end

  return nil
end

--- Returns if the DCS Group contains Helicopters.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Helicopters.
function GROUP:IsHelicopter()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    --self:T2( GroupCategory )
    return GroupCategory == Group.Category.HELICOPTER
  end

  return nil
end

--- Returns if the DCS Group contains AirPlanes.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains AirPlanes.
function GROUP:IsAirPlane()
  --self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    --self:T2( GroupCategory )
    return GroupCategory == Group.Category.AIRPLANE
  end

  return nil
end

--- Returns if the DCS Group contains Ground troops.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Ground troops.
function GROUP:IsGround()
  --self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    --self:T2( GroupCategory )
    return GroupCategory == Group.Category.GROUND
  end

  return nil
end

--- Returns if the DCS Group contains Ships.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Ships.
function GROUP:IsShip()
  --self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    --self:T2( GroupCategory )
    return GroupCategory == Group.Category.SHIP
  end

  return nil
end

--- Returns if all units of the group are on the ground or landed.
-- If all units of this group are on the ground, this function will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean All units on the ground result.
function GROUP:AllOnGround()
  --self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local AllOnGroundResult = true

    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      if UnitData:inAir() then
        AllOnGroundResult = false
      end
    end

    --self:T3( AllOnGroundResult )
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
  --self:F2()

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
  --self:F2()

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

--- Returns the current maximum height of the group, i.e. the highest unit height of that group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param #GROUP self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
  --self:F2()

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local GroupHeightMax = -999999999

    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      local UnitData = UnitData -- DCS#Unit

      local UnitHeight = UnitData:getPoint().p.y -- Height -- found by @Heavydrinker

      if UnitHeight > GroupHeightMax then
        GroupHeightMax = UnitHeight
      end
    end

    return GroupHeightMax
  end

  return nil
end

-- RESPAWNING

--- Returns the group template from the global _DATABASE object (an instance of @{Core.Database#DATABASE}).
-- @param #GROUP self
-- @return #table Template table.
function GROUP:GetTemplate()
  local GroupName = self:GetName()
  local template=_DATABASE:GetGroupTemplate( GroupName )
  if template then
    return UTILS.DeepCopy( template )
  end
  return nil
end

--- Returns the group template route.points[] (the waypoints) from the global _DATABASE object (an instance of @{Core.Database#DATABASE}).
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


--- Set the respawn @{Core.Zone} for the respawned group.
-- @param #GROUP self
-- @param Core.Zone#ZONE Zone The zone in meters.
-- @return #GROUP self
function GROUP:InitZone( Zone )
  self.InitRespawnZone = Zone
  return self
end


--- Randomize the positions of the units of the respawned group within the @{Core.Zone}.
-- When a Respawn happens, the units of the group will be placed at random positions within the Zone (selected).
-- NOTE: InitRandomizePositionZone will not ensure, that every unit is placed within the zone!
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

--- Set respawn coordinate.
-- @param #GROUP self
-- @param Core.Point#COORDINATE coordinate Coordinate where the group should be respawned.
-- @return #GROUP self
function GROUP:InitCoordinate(coordinate)
  --self:F({coordinate=coordinate})
  self.InitCoord=coordinate
  return self
end

--- Sets the radio comms on or off when the group is respawned. Same as checking/unchecking the COMM box in the mission editor.
-- @param #GROUP self
-- @param #boolean switch If true (or nil), enables the radio comms. If false, disables the radio for the spawned group.
-- @return #GROUP self
function GROUP:InitRadioCommsOnOff(switch)
  --self:F({switch=switch})
  if switch==true or switch==nil then
    self.InitRespawnRadio=true
  else
    self.InitRespawnRadio=false
  end
  return self
end

--- Sets the radio frequency of the group when it is respawned.
-- @param #GROUP self
-- @param #number frequency The frequency in MHz.
-- @return #GROUP self
function GROUP:InitRadioFrequency(frequency)
  --self:F({frequency=frequency})

  self.InitRespawnFreq=frequency

  return self
end

--- Set radio modulation when the group is respawned. Default is AM.
-- @param #GROUP self
-- @param #string modulation Either "FM" or "AM". If no value is given, modulation is set to AM.
-- @return #GROUP self
function GROUP:InitRadioModulation(modulation)
  --self:F({modulation=modulation})
  if modulation and modulation:lower()=="fm" then
    self.InitRespawnModu=radio.modulation.FM
  else
    self.InitRespawnModu=radio.modulation.AM
  end
  return self
end

--- Sets the modex (tail number) of the first unit of the group. If more units are in the group, the number is increased with every unit.
-- @param #GROUP self
-- @param #string modex Tail number of the first unit.
-- @return #GROUP self
function GROUP:InitModex(modex)
  --self:F({modex=modex})
  if modex then
    self.InitRespawnModex=tonumber(modex)
  end
  return self
end

--- Respawn the @{Wrapper.Group} at a @{Core.Point}.
-- The method will setup the new group template according the Init(Respawn) settings provided for the group.
-- These settings can be provided by calling the relevant Init...() methods of the Group.
--
--   - @{#GROUP.InitHeading}: Set the heading for the units in degrees within the respawned group.
--   - @{#GROUP.InitHeight}: Set the height for the units in meters for the respawned group. (This is applicable for air units).
--   - @{#GROUP.InitRandomizeHeading}: Randomize the headings for the units within the respawned group.
--   - @{#GROUP.InitZone}: Set the respawn @{Core.Zone} for the respawned group.
--   - @{#GROUP.InitRandomizePositionZone}: Randomize the positions of the units of the respawned group within the @{Core.Zone}.
--   - @{#GROUP.InitRandomizePositionRadius}: Randomize the positions of the units of the respawned group in a circle band.
--
-- Notes:
--
--   - The current alive group will always be destroyed and respawned using the template definition.
--
-- @param Wrapper.Group#GROUP self
-- @param #table Template (optional) The template of the Group retrieved with GROUP:GetTemplate(). If the template is not provided, the template will be retrieved of the group itself.
-- @param #boolean Reset Reset positions if TRUE.
-- @return Wrapper.Group#GROUP self
function GROUP:Respawn( Template, Reset )

  -- Given template or get old.
  Template = Template or self:GetTemplate()

  -- Get correct heading.
  local function _Heading(course)
    local h
    if course<=180 then
      h=math.rad(course)
    else
      h=-math.rad(360-course)
    end
    return h
  end
  
  local function TransFormRoute(Template,OldPos,NewPos)
    if Template.route and Template.route.points then
      for _,_point in ipairs(Template.route.points) do
        --self:I(string.format("Point x = %f Point y = %f",_point.x,_point.y))
        _point.x = _point.x - OldPos.x + NewPos.x
        _point.y = _point.y - OldPos.y + NewPos.y
        --self:I(string.format("Point x = %f Point y = %f",_point.x,_point.y))
      end
    end
    return Template
  end

  -- First check if group is alive.
  if self:IsAlive() then
    
    local OldPos = self:GetVec2()
    
    -- Respawn zone.
    local Zone = self.InitRespawnZone -- Core.Zone#ZONE

    -- Zone position or current group position.
    local Vec3 = Zone and Zone:GetVec3() or self:GetVec3()

    -- From point of the template.
    local From = { x = Template.x, y = Template.y }

    -- X, Y
    Template.x = Vec3.x
    Template.y = Vec3.z
    
    local NewPos = { x = Vec3.x, y = Vec3.z }

    --Template.x = nil
    --Template.y = nil

    -- Debug number of units.
    --self:F( #Template.units )

    -- Reset position etc?
    if Reset == true then

      -- Loop over units in group.
      for UnitID, UnitData in pairs( self:GetUnits() ) do
        local GroupUnit = UnitData -- Wrapper.Unit#UNIT
        --self:F(GroupUnit:GetName())

        if GroupUnit:IsAlive() then
          --self:I("FF Alive")

          -- Get unit position vector.
          local GroupUnitVec3 = GroupUnit:GetVec3()

          -- Check if respawn zone is set.
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

          -- Coordinate where the group should be respawned.
          if self.InitCoord then
            GroupUnitVec3=self.InitCoord:GetVec3()
          end

          -- Altitude
          Template.units[UnitID].alt = self.InitRespawnHeight and self.InitRespawnHeight or GroupUnitVec3.y

          -- Unit position. Why not simply take the current positon?
          if Zone then
            Template.units[UnitID].x = ( Template.units[UnitID].x - From.x ) + GroupUnitVec3.x -- Keep the original x position of the template and translate to the new position.
            Template.units[UnitID].y = ( Template.units[UnitID].y - From.y ) + GroupUnitVec3.z -- Keep the original z position of the template and translate to the new position.
          else
            Template.units[UnitID].x=GroupUnitVec3.x
            Template.units[UnitID].y=GroupUnitVec3.z
          end

          -- Set heading.
          Template.units[UnitID].heading = _Heading(self.InitRespawnHeading and self.InitRespawnHeading or GroupUnit:GetHeading())
          Template.units[UnitID].psi     = -Template.units[UnitID].heading
          
          -- Debug.
          --self:F( { UnitID, Template.units[UnitID], Template.units[UnitID] } )
        end
      end
      
      Template = TransFormRoute(Template,OldPos,NewPos)

    elseif Reset==false then  -- Reset=false or nil

      -- Loop over template units.
      for UnitID, TemplateUnitData in pairs( Template.units ) do

        --self:F( "Reset"  )

        -- Position from template.
        local GroupUnitVec3 = { x = TemplateUnitData.x, y = TemplateUnitData.alt, z = TemplateUnitData.y }

        -- Respawn zone position.
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

        -- Coordinate where the group should be respawned.
        if self.InitCoord then
          GroupUnitVec3=self.InitCoord:GetVec3()
        end

        -- Set altitude.
        Template.units[UnitID].alt = self.InitRespawnHeight and self.InitRespawnHeight or GroupUnitVec3.y

        -- Unit position.
        Template.units[UnitID].x = ( Template.units[UnitID].x - From.x ) + GroupUnitVec3.x -- Keep the original x position of the template and translate to the new position.
        Template.units[UnitID].y = ( Template.units[UnitID].y - From.y ) + GroupUnitVec3.z -- Keep the original z position of the template and translate to the new position.

        -- Heading
        Template.units[UnitID].heading = self.InitRespawnHeading and self.InitRespawnHeading or TemplateUnitData.heading
        
        -- Debug.
        --self:F( { UnitID, Template.units[UnitID], Template.units[UnitID] } )
      end
      
      Template = TransFormRoute(Template,OldPos,NewPos)
      
    else

      local units=self:GetUnits()

      -- Loop over template units.
      for UnitID, Unit in pairs(Template.units) do

        for _,_unit in pairs(units) do
          local unit=_unit --Wrapper.Unit#UNIT

          if unit:GetName()==Unit.name then
            local coord=unit:GetCoordinate()
            local heading=unit:GetHeading()
            Unit.x=coord.x
            Unit.y=coord.z
            Unit.alt=coord.y
            Unit.heading=math.rad(heading)
            Unit.psi=-Unit.heading
          end
        end

      end

    end

  end

  -- Set tail number.
  if self.InitRespawnModex then
    for UnitID=1,#Template.units do
      Template.units[UnitID].onboard_num=string.format("%03d", self.InitRespawnModex+(UnitID-1))
    end
  end

  -- Set radio frequency and modulation.
  if self.InitRespawnRadio then
    Template.communication=self.InitRespawnRadio
  end
  if self.InitRespawnFreq then
    Template.frequency=self.InitRespawnFreq
  end
  if self.InitRespawnModu then
    Template.modulation=self.InitRespawnModu
  end

  -- Destroy old group. Dont trigger any dead/crash events since this is a respawn.
  self:Destroy(false)

  --UTILS.PrintTableToLog(Template)

  -- Spawn new group.
  self:ScheduleOnce(0.1,_DATABASE.Spawn,_DATABASE,Template)
  --_DATABASE:Spawn(Template)

  -- Reset events.
  self:ResetEvents()

  return self
end

--- Respawn the @{Wrapper.Group} at a @{Core.Point#COORDINATE}.
-- The method will setup the new group template according the Init(Respawn) settings provided for the group.
-- These settings can be provided by calling the relevant Init...() methods of the Group prior.
--
--   - @{#GROUP.InitHeading}: Set the heading for the units in degrees within the respawned group.
--   - @{#GROUP.InitHeight}: Set the height for the units in meters for the respawned group. (This is applicable for air units).
--   - @{#GROUP.InitRandomizeHeading}: Randomize the headings for the units within the respawned group.
--   - @{#GROUP.InitRandomizePositionZone}: Randomize the positions of the units of the respawned group within the @{Core.Zone}.
--   - @{#GROUP.InitRandomizePositionRadius}: Randomize the positions of the units of the respawned group in a circle band.
--
-- Notes:
--
--   - When no coordinate is given, the position of the respawned group will be its current position.
--   - The current alive group will always be destroyed first.
--   - The new group will have all of its original units and health restored.
--
-- @param Wrapper.Group#GROUP self
-- @param Core.Point#COORDINATE Coordinate Where to respawn the group. Can be handed as a @{Core.Zone#ZONE_BASE} object.
-- @return Wrapper.Group#GROUP self
function GROUP:Teleport(Coordinate)
  self:InitZone(Coordinate)
  return self:Respawn(nil,false)
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
  --self:F2( { SpawnTemplate, Takeoff, Uncontrolled} )

  if self and self:IsAlive() then

    -- Get closest airbase. Should be the one we are currently on.
    local airbase=self:GetCoordinate():GetClosestAirbase()

    if airbase then
      --self:F2("Closest airbase = "..airbase:GetName())
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
      local AirbaseCategory = airbase:GetAirbaseCategory()

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
        --self:T2(string.format("Closest parking spot distance = %s, terminal ID=%s", tostring(Distance), tostring(TermialID)))

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

      -- Set radio frequency and modulation.
      if self.InitRespawnRadio then
        SpawnTemplate.communication=self.InitRespawnRadio
      end
      if self.InitRespawnFreq then
        SpawnTemplate.frequency=self.InitRespawnFreq
      end
      if self.InitRespawnModu then
        SpawnTemplate.modulation=self.InitRespawnModu
      end

      -- Destroy old group.
      self:Destroy(false)

      -- Spawn new group.
      _DATABASE:Spawn(SpawnTemplate)

      -- Reset events.
      self:ResetEvents()

      return self
    end
  else
    self:E("WARNING: GROUP is not alive!")
  end

  return nil
end


--- Return the mission template of the group.
-- @param #GROUP self
-- @return #table The MissionTemplate
function GROUP:GetTaskMission()
  --self:F2( self.GroupName )

  return UTILS.DeepCopy( _DATABASE.Templates.Groups[self.GroupName].Template )
end

--- Return the mission route of the group.
-- @param #GROUP self
-- @return #table The mission route defined by points.
function GROUP:GetTaskRoute()
  --self:F2( self.GroupName )
  if _DATABASE.Templates.Groups[self.GroupName].Template and _DATABASE.Templates.Groups[self.GroupName].Template.route and _DATABASE.Templates.Groups[self.GroupName].Template.route.points then
    return UTILS.DeepCopy( _DATABASE.Templates.Groups[self.GroupName].Template.route.points )
  else
    return {}
  end
end

--- Return the route of a group by using the global _DATABASE object (an instance of @{Core.Database#DATABASE}).
-- @param #GROUP self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius.
function GROUP:CopyRoute( Begin, End, Randomize, Radius )
  --self:F2( { Begin, End } )

  local Points = {}

  -- Could be a Spawned Group
  local GroupName = string.match( self:GetName(), ".*#" )
  if GroupName then
    GroupName = GroupName:sub( 1, -2 )
  else
    GroupName = self:GetName()
  end

  --self:T3( { GroupName } )

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
        Points[#Points+1] = UTILS.DeepCopy( Template.route.points[TPointID] )
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
-- @return #number Number between 0 and 10.
function GROUP:CalculateThreatLevelA2G()

  local MaxThreatLevelA2G = 0
  for UnitName, UnitData in pairs( self:GetUnits() ) do
    local ThreatUnit = UnitData -- Wrapper.Unit#UNIT
    local ThreatLevelA2G = ThreatUnit:GetThreatLevel()
    if ThreatLevelA2G > MaxThreatLevelA2G then
      MaxThreatLevelA2G = ThreatLevelA2G
    end
  end

  --self:T3( MaxThreatLevelA2G )
  return MaxThreatLevelA2G
end

--- Get threat level of the group.
-- @param #GROUP self
-- @return #number Max threat level (a number between 0 and 10).
function GROUP:GetThreatLevel()

  local threatlevelMax = 0
  for UnitName, UnitData in pairs(self:GetUnits()) do
    local ThreatUnit = UnitData -- Wrapper.Unit#UNIT

    local threatlevel = ThreatUnit:GetThreatLevel()
    if threatlevel > threatlevelMax then
      threatlevelMax=threatlevel
    end
  end

  return threatlevelMax
end


--- Returns true if the first unit of the GROUP is in the air.
-- @param Wrapper.Group#GROUP self
-- @return #boolean true if in the first unit of the group is in the air or #nil if the GROUP is not existing or not alive.
function GROUP:InAir()
  --self:F2( self.GroupName )

  local DCSGroup = self:GetDCSObject()

  if DCSGroup then
    local DCSUnit = DCSGroup:getUnit(1)
    if DCSUnit then
      local GroupInAir = DCSGroup:getUnit(1):inAir()
      --self:T3( GroupInAir )
      return GroupInAir
    end
  end

  return nil
end

--- Checks whether any unit (or optionally) all units of a group is(are) airbore or not.
-- @param Wrapper.Group#GROUP self
-- @param #boolean AllUnits (Optional) If true, check whether all units of the group are airborne.
-- @return #boolean True if at least one (optionally all) unit(s) is(are) airborne or false otherwise. Nil if no unit exists or is alive.
function GROUP:IsAirborne(AllUnits)
  --self:F2( self.GroupName )

  -- Get all units of the group.
  local units=self:GetUnits()

  if units then

    if AllUnits then

      --- We want to know if ALL units are airborne.

      for _,_unit in pairs(units) do
        local unit=_unit --Wrapper.Unit#UNIT

        if unit then

          -- Unit in air or not.
          local inair=unit:InAir()

          -- At least one unit is not in air.
          if not inair then
            return false
          end
        end

      end

      -- All units are in air.
      return true

    else

      --- We want to know if ANY unit is airborne.

      for _,_unit in pairs(units) do
        local unit=_unit --Wrapper.Unit#UNIT

        if unit then

          -- Unit in air or not.
          local inair=unit:InAir()

          if inair then
            -- At least one unit is in air.
            return true
          end

        end

        -- No unit is in air.
        return false

      end
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


--- Get the generalized attribute of a self.
-- Note that for a heterogenious self, the attribute is determined from the attribute of the first unit!
-- @param #GROUP self
-- @return #string Generalized attribute of the self.
function GROUP:GetAttribute()

  -- Default
  local attribute=GROUP.Attribute.OTHER_UNKNOWN --#GROUP.Attribute

  if self then

    -----------
    --- Air ---
    -----------
    -- Planes
    local transportplane=self:HasAttribute("Transports") and self:HasAttribute("Planes")
    local awacs=self:HasAttribute("AWACS")
    local fighter=self:HasAttribute("Fighters") or self:HasAttribute("Interceptors") or self:HasAttribute("Multirole fighters") or (self:HasAttribute("Bombers") and not self:HasAttribute("Strategic bombers"))
    local bomber=self:HasAttribute("Strategic bombers")
    local tanker=self:HasAttribute("Tankers")
    local uav=self:HasAttribute("UAVs")
    -- Helicopters
    local transporthelo=self:HasAttribute("Transport helicopters")
    local attackhelicopter=self:HasAttribute("Attack helicopters")

    --------------
    --- Ground ---
    --------------
    -- Ground
    local apc=self:HasAttribute("APC")
    local truck=self:HasAttribute("Trucks") and self:GetCategory()==Group.Category.GROUND
    local infantry=self:HasAttribute("Infantry")
    local artillery=self:HasAttribute("Artillery")
    local tank=self:HasAttribute("Old Tanks") or self:HasAttribute("Modern Tanks") or self:HasAttribute("Tanks")
    local aaa=self:HasAttribute("AAA") and (not self:HasAttribute("SAM elements"))
    local ewr=self:HasAttribute("EWR")
    local ifv=self:HasAttribute("IFV")
    local sam=self:HasAttribute("SAM elements") or self:HasAttribute("Optical Tracker")
    -- Train
    local train=self:GetCategory()==Group.Category.TRAIN

    -------------
    --- Naval ---
    -------------
    -- Ships
    local aircraftcarrier=self:HasAttribute("Aircraft Carriers")
    local warship=self:HasAttribute("Heavy armed ships")
    local armedship=self:HasAttribute("Armed ships")
    local unarmedship=self:HasAttribute("Unarmed ships")


    -- Define attribute. Order of attack is important.
    if fighter then
      attribute=GROUP.Attribute.AIR_FIGHTER
    elseif bomber then
      attribute=GROUP.Attribute.AIR_BOMBER
    elseif awacs then
      attribute=GROUP.Attribute.AIR_AWACS
    elseif transportplane then
      attribute=GROUP.Attribute.AIR_TRANSPORTPLANE
    elseif tanker then
      attribute=GROUP.Attribute.AIR_TANKER
      -- helos
    elseif attackhelicopter then
      attribute=GROUP.Attribute.AIR_ATTACKHELO
    elseif transporthelo then
      attribute=GROUP.Attribute.AIR_TRANSPORTHELO
    elseif uav then
      attribute=GROUP.Attribute.AIR_UAV
      -- ground - order of attack
    elseif ewr then
      attribute=GROUP.Attribute.GROUND_EWR
    elseif sam then
      attribute=GROUP.Attribute.GROUND_SAM
    elseif aaa then
      attribute=GROUP.Attribute.GROUND_AAA
    elseif artillery then
      attribute=GROUP.Attribute.GROUND_ARTILLERY
    elseif tank then
      attribute=GROUP.Attribute.GROUND_TANK
    elseif ifv then
      attribute=GROUP.Attribute.GROUND_IFV
    elseif apc then
      attribute=GROUP.Attribute.GROUND_APC
    elseif infantry then
      attribute=GROUP.Attribute.GROUND_INFANTRY
    elseif truck then
      attribute=GROUP.Attribute.GROUND_TRUCK
    elseif train then
      attribute=GROUP.Attribute.GROUND_TRAIN
      -- ships
    elseif aircraftcarrier then
      attribute=GROUP.Attribute.NAVAL_AIRCRAFTCARRIER
    elseif warship then
      attribute=GROUP.Attribute.NAVAL_WARSHIP
    elseif armedship then
      attribute=GROUP.Attribute.NAVAL_ARMEDSHIP
    elseif unarmedship then
      attribute=GROUP.Attribute.NAVAL_UNARMEDSHIP
    else
      if self:IsGround() then
        attribute=GROUP.Attribute.GROUND_OTHER
      elseif self:IsShip() then
        attribute=GROUP.Attribute.NAVAL_OTHER
      elseif self:IsAir() then
        attribute=GROUP.Attribute.AIR_OTHER
      else
        attribute=GROUP.Attribute.OTHER_UNKNOWN
      end
    end
  end

  return attribute
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
  -- @param #number Speed (optional) The Speed, if no Speed is given, 80% of maximum Speed of the group is selected.
  -- @return #GROUP self
  function GROUP:RouteRTB( RTBAirbase, Speed )
    --self:F( { RTBAirbase:GetName(), Speed } )

    local DCSGroup = self:GetDCSObject()

    if DCSGroup then

      if RTBAirbase then

        -- If speed is not given take 80% of max speed.
        local Speed=Speed or self:GetSpeedMax()*0.8

        -- Curent (from) waypoint.
        local coord=self:GetCoordinate()
        local PointFrom=coord:WaypointAirTurningPoint(nil, Speed)

        -- Airbase coordinate.
        --local PointAirbase=RTBAirbase:GetCoordinate():SetAltitude(coord.y):WaypointAirTurningPoint(nil ,Speed)

        -- Landing waypoint. More general than prev version since it should also work with FAPRS and ships.
        local PointLanding=RTBAirbase:GetCoordinate():WaypointAirLanding(Speed, RTBAirbase)

        -- Waypoint table.
        local Points={PointFrom, PointLanding}
        --local Points={PointFrom, PointAirbase, PointLanding}

        -- Debug info.
        --self:T3(Points)

        -- Get group template.
        local Template=self:GetTemplate()

        -- Set route points.
        Template.route.points=Points

        -- Respawn the group.
        self:Respawn(Template, true)

        -- Route the group or this will not work.
        self:Route(Points)
      else

        -- Clear all tasks.
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
    for UnitID, UnitData in pairs( Units or {}) do
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = Unit:GetPlayerName()
      if PlayerName and PlayerName ~= "" then
        PlayerNames = PlayerNames or {}
        table.insert( PlayerNames, PlayerName )
        HasPlayers = true
      end
    end

    if HasPlayers == true then
      --self:F2( PlayerNames )
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

--- GROUND - Switch on/off radar emissions for the group.
-- @param #GROUP self
-- @param #boolean switch If true, emission is enabled. If false, emission is disabled.
-- @return #GROUP self
function GROUP:EnableEmission(switch)
  --self:F2( self.GroupName )
  local switch = switch or false

  local DCSUnit = self:GetDCSObject()

  if DCSUnit then

    DCSUnit:enableEmission(switch)

  end

  return self
end

--- Switch on/off invisible flag for the group.
-- @param #GROUP self
-- @param #boolean switch If true, Invisible is enabled. If false, Invisible is disabled.
-- @return #GROUP self
function GROUP:SetCommandInvisible(switch)
  return self:CommandSetInvisible(switch)
end

--- Switch on/off invisible flag for the group.
-- @param #GROUP self
-- @param #boolean switch If true, Invisible is enabled. If false, Invisible is disabled.
-- @return #GROUP self
function GROUP:CommandSetInvisible(switch)
  --self:F2( self.GroupName )
  if switch==nil then
    switch=false
  end
  local SetInvisible = {id = 'SetInvisible', params = {value = switch}}
  self:SetCommand(SetInvisible)
  return self
end

--- Switch on/off immortal flag for the group.
-- @param #GROUP self
-- @param #boolean switch If true, Immortal is enabled. If false, Immortal is disabled.
-- @return #GROUP self
function GROUP:SetCommandImmortal(switch)
  return self:CommandSetImmortal(switch)
end

--- Switch on/off immortal flag for the group.
-- @param #GROUP self
-- @param #boolean switch If true, Immortal is enabled. If false, Immortal is disabled.
-- @return #GROUP self
function GROUP:CommandSetImmortal(switch)
  --self:F2( self.GroupName )
  if switch==nil then
    switch=false
  end
  local SetImmortal = {id = 'SetImmortal', params = {value = switch}}
  self:SetCommand(SetImmortal)
  return self
end

--- Get skill from Group. Effectively gets the skill from Unit 1 as the group holds no skill value.
-- @param #GROUP self
-- @return #string Skill String of skill name.
function GROUP:GetSkill()
  --self:F2( self.GroupName )
  local unit = self:GetUnit(1)
  local name = unit:GetName()
  local skill = _DATABASE.Templates.Units[name].Template.skill or "Random"
  return skill
end


--- Get the unit in the group with the highest threat level, which is still alive.
-- @param #GROUP self
-- @return Wrapper.Unit#UNIT The most dangerous unit in the group.
-- @return #number Threat level of the unit.
function GROUP:GetHighestThreat()

  -- Get units of the group.
  local units=self:GetUnits()

  if units then

    local threat=nil ; local maxtl=0
    for _,_unit in pairs(units or {}) do
      local unit=_unit --Wrapper.Unit#UNIT

      if unit and unit:IsAlive() then

        -- Threat level of group.
        local tl=unit:GetThreatLevel()

        -- Check if greater the current threat.
        if tl>maxtl then
          maxtl=tl
          threat=unit
        end
      end
    end

    return threat, maxtl
  end

  return nil, nil
end

--- Get TTS friendly, optionally customized callsign mainly for **player groups**. A customized callsign is taken from the #GROUP name, after an optional '#' sign, e.g. "Aerial 1-1#Ghostrider" resulting in "Ghostrider 9", or,
-- if that isn't available, from the playername, as set in the mission editor main screen under Logbook, after an optional '|' sign (actually, more of a personal call sign), e.g. "Apple|Moose" results in "Moose 9 1". Options see below.
-- @param #GROUP self
-- @param #boolean ShortCallsign Return a shortened customized callsign, i.e. "Ghostrider 9" and not "Ghostrider 9 1"
-- @param #boolean Keepnumber (Player only) Return customized callsign, incl optional numbers at the end, e.g. "Aerial 1-1#Ghostrider 109" results in "Ghostrider 109", if you want to e.g. use historical US Navy Callsigns
-- @param #table CallsignTranslations (Optional) Table to translate between DCS standard callsigns and bespoke ones. Overrides personal/parsed callsigns if set
-- callsigns from playername or group name.
-- @param #func CustomFunction (Optional) For player names only(!). If given, this function will return the callsign. Needs to take the groupname and the playername as first arguments.
-- @param #arg ... (Optional) Comma separated arguments to add to the CustomFunction call after groupname and playername.
-- @return #string Callsign
-- @usage
--            -- suppose there are three groups with one (client) unit each:
--            -- Slot 1               -- with mission editor callsign Enfield-1
--            -- Slot 2 # Apollo 403  -- with mission editor callsign Enfield-2
--            -- Slot 3 | Apollo      -- with mission editor callsign Enfield-3
--            -- Slot 4 | Apollo      -- with mission editor callsign Devil-4
--            -- and suppose these Custom CAP Flight Callsigns for use with TTS are set
--            mygroup:GetCustomCallSign(true,false,{
--              Devil = 'Bengal',
--              Snake = 'Winder',
--              Colt = 'Camelot',
--              Enfield = 'Victory',
--              Uzi = 'Evil Eye'
--            })
--            -- then GetCustomCallsign will return
--            -- Enfield-1 for Slot 1
--            -- Apollo for Slot 2 or Apollo 403 if Keepnumber is set
--            -- Apollo for Slot 3
--            -- Bengal-4 for Slot 4
-- 
--            -- Using a custom function (for player units **only**):
--            -- Imagine your playernames are looking like so: "[Squadname] | Cpt Apple" and you only want to have the last word as callsign, i.e. "Apple" here. Then this custom function will return this:
--            local callsign = mygroup:GetCustomCallSign(true,false,nil,function(groupname,playername) return string.match(playername,"([%a]+)$") end)
-- 
function GROUP:GetCustomCallSign(ShortCallsign,Keepnumber,CallsignTranslations,CustomFunction,...)
  --self:I("GetCustomCallSign")

  local callsign = "Ghost 1"
  if self:IsAlive() then
    local IsPlayer = self:IsPlayer()
    local shortcallsign = self:GetCallsign() or "unknown91" -- e.g.Uzi91, but we want Uzi 9 1
    local callsignroot = string.match(shortcallsign, '(%a+)') or "Ghost" -- Uzi
    --self:I("CallSign = " .. callsignroot)
    local groupname = self:GetName()
    local callnumber = string.match(shortcallsign, "(%d+)$" ) or "91" -- 91
    local callnumbermajor = string.char(string.byte(callnumber,1)) -- 9
    local callnumberminor = string.char(string.byte(callnumber,2)) -- 1
    local personalized = false
    local playername = IsPlayer == true and self:GetPlayerName() or shortcallsign
    
    if CustomFunction and IsPlayer then
      local arguments = arg or {}
      local callsign = CustomFunction(groupname,playername,unpack(arguments))
      return callsign
    end
    
    -- prioritize bespoke callsigns over parsing, prefer parsing over default callsigns
    if CallsignTranslations and CallsignTranslations[callsignroot] then
      callsignroot = CallsignTranslations[callsignroot]
    elseif IsPlayer and string.find(groupname,"#") then
      -- personalized flight name in group naming
      if Keepnumber then
        shortcallsign = string.match(groupname,"#(.+)") or "Ghost 111" -- Ghostrider 219
      else
        shortcallsign = string.match(groupname,"#%s*([%a]+)") or "Ghost" -- Ghostrider
      end
      personalized = true
    elseif IsPlayer and string.find(playername,"|") then
      -- personalized flight name in group naming
      shortcallsign = string.match(playername,"|%s*([%a]+)") or string.match(self:GetPlayerName(),"|%s*([%d]+)") or "Ghost" -- Ghostrider
      personalized = true
    end

    if personalized then
      -- player personalized callsign
      -- remove trailing/leading spaces
      shortcallsign=string.gsub(shortcallsign,"^%s*","")
      shortcallsign=string.gsub(shortcallsign,"%s*$","")
      if Keepnumber then
        return shortcallsign -- Ghostrider 219
      elseif ShortCallsign then
        callsign = shortcallsign.." "..callnumbermajor -- Ghostrider 9
      else
        callsign = shortcallsign.." "..callnumbermajor.." "..callnumberminor -- Ghostrider 9 1
      end
      return callsign
    end

    -- AI or not personalized
    if ShortCallsign then
      callsign = callsignroot.." "..callnumbermajor -- Uzi/Victory 9
    else
      callsign = callsignroot.." "..callnumbermajor.." "..callnumberminor -- Uzi/Victory 9 1
    end

    --self:I("Generated Callsign = " .. callsign)
  end

  return callsign
end

--- Set a GROUP to act as recovery tanker
-- @param #GROUP self
-- @param Wrapper.Group#GROUP CarrierGroup.
-- @param #number Speed Speed in knots.
-- @param #boolean ToKIAS If true, adjust speed to altitude (KIAS).
-- @param #number Altitude Altitude the tanker orbits at in feet.
-- @param #number Delay (optional) Set the task after this many seconds. Defaults to one.
-- @param #number LastWaypoint (optional) Waypoint number of carrier group that when reached, ends the recovery tanker task.
-- @return #GROUP self
function GROUP:SetAsRecoveryTanker(CarrierGroup,Speed,ToKIAS,Altitude,Delay,LastWaypoint)

  local speed = ToKIAS == true and UTILS.KnotsToAltKIAS(Speed,Altitude) or Speed
  speed = UTILS.KnotsToMps(speed)

  local alt = UTILS.FeetToMeters(Altitude)
  local delay = Delay or 1

  local task = self:TaskRecoveryTanker(CarrierGroup,speed,alt,LastWaypoint)

  self:SetTask(task,delay)

  local tankertask = self:EnRouteTaskTanker()
  self:PushTask(tankertask,delay+2)

  return self
end

--- Get a list of Link16 S/TN data from a GROUP. Can (as of Nov 2023) be obtained from F-18, F-16, F-15E (not the user flyable one) and A-10C-II groups.
-- @param #GROUP self
-- @return #table Table of data entries, indexed by unit name, each entry is a table containing STN, VCL (voice call label), VCN (voice call number), and Lead (#boolean, if true it's the flight lead)
-- @return #string Report Formatted report of all data
function GROUP:GetGroupSTN()
  local tSTN = {} -- table
  local units = self:GetUnits()
  local gname = self:GetName()
  gname = string.gsub(gname,"(#%d+)$","")
  local report = REPORT:New()
  report:Add("Link16 S/TN Report")
  report:Add("Group: "..gname)
  report:Add("==================")
  for _,_unit in pairs(units) do
   local unit = _unit -- Wrapper.Unit#UNIT
   if unit and unit:IsAlive() then
     local STN, VCL, VCN, Lead = unit:GetSTN()
     local name = unit:GetName()
     tSTN[name] = {
      STN=STN,
      VCL=VCL,
      VCN=VCN,
      Lead=Lead,
     }
     local lead = Lead == true and "(*)" or ""
     report:Add(string.format("| %s%s %s %s",tostring(VCL),tostring(VCN),tostring(STN),lead))
   end
  end
  report:Add("==================")
  local text = report:Text()
  return tSTN,text
end

--- [GROUND] Determine if a GROUP is a SAM unit, i.e. has radar or optical tracker and is no mobile AAA.
-- @param #GROUP self
-- @return #boolean IsSAM True if SAM, else false
function GROUP:IsSAM()
  local issam = false
  local units = self:GetUnits()
  for _,_unit in pairs(units or {}) do
    local unit = _unit -- Wrapper.Unit#UNIT
    if unit:HasSEAD() and unit:IsGround() and (not unit:HasAttribute("Mobile AAA")) then
      issam = true
      break
    end
  end
  return issam
end

--- [GROUND] Determine if a GROUP has a AAA unit, i.e. has no radar or optical tracker but the AAA = true or the "Mobile AAA" = true attribute.
-- @param #GROUP self
-- @return #boolean IsSAM True if AAA, else false
function GROUP:IsAAA()
  local issam = false
  local units = self:GetUnits()
  for _,_unit in pairs(units or {}) do
    local unit = _unit -- Wrapper.Unit#UNIT
    local desc = unit:GetDesc() or {}
    local attr = desc.attributes or {}
    if unit:HasSEAD() then return false end
    if attr["AAA"] or attr["SAM related"] then
      issam = true
    end
  end
  return issam
end
