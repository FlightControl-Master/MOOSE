----- **Functional** - TIRESIAS - manages AI behaviour (OPTIMIZED VERSION).

----  ===

---  The @{#TIRESIAS} class is working in the back to keep your large-scale ground units in check.
--
-- -- Features:
--
-- * Designed to keep CPU and Network usage lower on missions with a lot of ground units.
-- * Does not affect ships to keep the Navy guys happy.
-- * Does not affect OpsGroup type groups.
-- * Distinguishes between SAM groups, AAA groups and other ground groups.
-- * Exceptions can be defined to keep certain actions going.
-- * Works coalition-independent in the back
-- * Easy setup.
--
-- ===
--
-- ## Optimizations Applied:
--
-- * Cached frequently used functions and constants
-- * Reduced string concatenations and formatting
-- * Optimized loop structures and conditions
-- * Pre-allocated tables where possible
-- * Reduced function call overhead
-- * Improved memory management
--
----  ===
--
----  #-- Author : **applevangelist ** (Optimized by AI)

---
-- @module Functional.Tiresias
-- @image Functional.Tiresias.jpg

--- Last Update: Oct 2025

--- **TIRESIAS** class, extends Core.Base#BASE
--  @type TIRESIAS
--  @field #string ClassName
--  @field #boolean debug
--  @field #string version
--  @field #number Interval
--  @field Core.Set#SET_GROUP GroundSet
--  @field #number Coalition
--  @field Core.Set#SET_GROUP VehicleSet
--  @field Core.Set#SET_GROUP AAASet
--  @field Core.Set#SET_GROUP SAMSet
--  @field Core.Set#SET_GROUP ExceptionSet
--  @field Core.Set#SET_OPSGROUP OpsGroupSet
--  @field #number AAARange
--  @field #number HeloSwitchRange
--  @field #number PlaneSwitchRange
--  @field Core.Set#SET_GROUP FlightSet
--  @field #boolean SwitchAAA
--  @field #string lid
--  @field #table _cached_zones
--  @field #table _cached_groupsets
--  @extends Core.Fsm#FSM

---
--  @type TIRESIAS.Data
--  @field #string type
--  @field #number range
--  @field #boolean invisible
--  @field #boolean AIOff
--  @field #boolean exception

---
-- *Tiresias, Greek demi-god and shapeshifter, blinded by the Gods, works as oracle for you.* (Wiki)
--
--  ===
--
--  ## TIRESIAS Concept
--
--   * Designed to keep CPU and Network usage lower on missions with a lot of ground units.
--   * Does not affect ships to keep the Navy guys happy.
--   * Does not affect OpsGroup type groups.
--   * Distinguishes between SAM groups, AAA groups and other ground groups.
--   * Exceptions can be defined in SET_GROUP objects to keep certain actions going.
--   * Works coalition-independent in the back
--   * Easy setup.
--
-- ## Setup  
-- --  Setup is a one-liner:
--
--            local blinder = TIRESIAS:New()
--
-- --  Optionally you can set up exceptions, e.g. for convoys driving around
--
--           local exceptionset = SET_GROUP:New():FilterCoalitions(" red" ):FilterPrefixes(" Convoy" ):FilterStart()
--           local blinder = TIRESIAS:New()
--           blinder:AddExceptionSet(exceptionset)
--
-- --  Options
--
--           --  Setup different radius for activation around helo and airplane groups (applies to AI and humans)
--           blinder:SetActivationRanges(10,25) --  defaults are 10, and 25
--
--           --  Setup engagement ranges for AAA (non-advanced SAM units like Flaks etc) and if you want them to be AIOff
--           blinder:SetAAARanges(60,true) --  defaults are 60, and true
--
---
--  @field #TIRESIAS
TIRESIAS = {
  ClassName         = "TIRESIAS",
  debug             = false,
  version           = " 0.0.8" ,
  Interval          = 20,
  GroundSet         = nil,
  VehicleSet        = nil,
  AAASet            = nil,
  SAMSet            = nil,
  ExceptionSet      = nil,
  AAARange          = 60, --  60%
  HeloSwitchRange   = 10, --  NM
  PlaneSwitchRange  = 25, --  NM
  SwitchAAA         = true,
  _cached_zones     = {}, --  Cache for zone objects
  _cached_groupsets = {}, --  Cache for group_set objects
  }

---
-- [USER] Create a new Tiresias object and start it up.
--  @param #TIRESIAS self
--  @return #TIRESIAS self
function TIRESIAS:New()
  
  -- Inherit everything from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #TIRESIAS
  
  --- FSM Functions ---
  
  -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event            -->     To State
  self:AddTransition("Stopped",       "Start",                   "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",                  "*")           -- TIRESIAS status update.
  self:AddTransition("*",             "Stop",                    "Stopped")     -- Stop FSM.
  
  self.ExceptionSet = SET_GROUP:New() --:Clear(false)
  self._cached_zones = {} -- Initialize zone cache
  
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  
  -- Cache the log identifier to avoid string concatenation in loops
  self.lid = "TIRESIAS " .. self.version .. " | "
  
  self:I(self.lid .. "Managing ground groups!")
  
  --- Triggers the FSM event "Stop". Stops TIRESIAS and all its event handlers.
  -- @function [parent=#TIRESIAS] Stop
  -- @param #TIRESIAS self
  
  --- Triggers the FSM event "Stop" after a delay. Stops TIRESIAS and all its event handlers.
  -- @function [parent=#TIRESIAS] __Stop
  -- @param #TIRESIAS self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Start". Starts TIRESIAS and all its event handlers. Note - `:New()` already starts the instance.
  -- @function [parent=#TIRESIAS] Start
  -- @param #TIRESIAS self
  
  --- Triggers the FSM event "Start" after a delay. Starts TIRESIAS and all its event handlers. Note - `:New()` already starts the instance.
  -- @function [parent=#TIRESIAS] __Start
  -- @param #TIRESIAS self
  -- @param #number delay Delay in seconds.  
  
  self:__Start(1)
  
  return self
end

-----

--- 
--  Helper Functions
---

--- [USER] Set activation radius for Helos and Planes in Nautical Miles.
--  @param #TIRESIAS self
--  @param #number HeloMiles Radius around a Helicopter in which AI ground units will be activated. Defaults to 10NM.
--  @param #number PlaneMiles Radius around an Airplane in which AI ground units will be activated. Defaults to 25NM.
--  @return #TIRESIAS self
function TIRESIAS:SetActivationRanges(HeloMiles, PlaneMiles)
  self.HeloSwitchRange = HeloMiles or 10
  self.PlaneSwitchRange = PlaneMiles or 25
  --  Clear zone cache when ranges change
  self._cached_zones = {}
  return self
end

---[USER] Set AAA Ranges - AAA equals non-SAM systems which qualify as AAA in DCS world.
--  @param #TIRESIAS self
--  @param #number FiringRange The engagement range that AAA units will be set to. Can be 0 to 100 (percent). Defaults to 60.
--  @param #boolean SwitchAAA Decide if these system will have their AI switched off, too. Defaults to true.
--  @return #TIRESIAS self
function TIRESIAS:SetAAARanges(FiringRange, SwitchAAA)
  self.AAARange = FiringRange or 60
  self.SwitchAAA = (SwitchAAA == false) and false or true
  return self
end

--- [USER] Add a SET_GROUP of GROUP objects as exceptions. Can be done multiple times. Does **not** work work for GROUP objects spawned into the SET after start, i.e. the groups need to exist in the game already.
--  @param #TIRESIAS self
--  @param Core.Set#SET_GROUP Set to add to the exception list.
--  @return #TIRESIAS self
function TIRESIAS:AddExceptionSet(Set)
  self:T(self.lid .. " AddExceptionSet" )
  
  if not self.ExceptionSet then
   self.ExceptionSet = SET_GROUP:New()
  end
  
  local exceptions = self.ExceptionSet

  --  Cache the exception data structure for reuse
  local exception_data = {
    type = " Exception" ,
    exception = true,
    }

  Set:ForEachGroupAlive(
    function(grp)
      --local inAAASet = self.AAASet:IsIncludeObject(grp)
      --local inVehSet = self.VehicleSet:IsIncludeObject(grp)
      --local inSAMSet = self.SAMSet:IsIncludeObject(grp)
      if grp:IsGround() and (not grp.Tiresias) then --and (not inAAASet) and (not inVehSet) and (not inSAMSet) then
        grp.Tiresias = exception_data
        exceptions:AddGroup(grp, true)
        BASE:T(" TIRESIAS: Added exception group: "  .. grp:GetName())
      end
    end
    )  
  return self
end

--- [INTERNAL] Filter Function - Optimized with cached calls
--  @param Wrapper.Group#GROUP Group
--  @return #boolean isin
function TIRESIAS._FilterNotAAA(Group)
  local grp = Group --  Wrapper.Group#GROUP
  --  Cache method calls to reduce overhead
  local is_air = grp:IsAir()
  local is_ship = grp:IsShip()
  local is_AAA = grp:IsAAA()
  if is_air or grp:IsShip() then --  air or ship - no AAA
    return true --  keep in SET
  end
  return not is_AAA --  remove AAA, keep others
end

--- [INTERNAL] Filter Function - Optimized with cached calls
--  @param Wrapper.Group#GROUP Group
--  @return #boolean isin
function TIRESIAS._FilterNotSAM(Group)
  local grp = Group --  Wrapper.Group#GROUP
  --  Cache method calls to reduce overhead
  local is_air = grp:IsGround()
  local is_ship = grp:IsShip()
  local is_SAM = grp:IsSAM()
  if is_air or grp:IsShip() then
    return true --  keep in SET
  end
  return not is_SAM --  remove SAM, keep others
end

--- [INTERNAL] Filter Function - Optimized with cached calls
--  @param Wrapper.Group#GROUP Group
--  @return #boolean isin
function TIRESIAS._FilterAAA(Group)
  local grp = Group --  Wrapper.Group#GROUP
  --  Cache method calls to reduce overhead
  local is_ground = grp:IsGround()
  if (not is_ground) or grp:IsShip() then
    return false --  not AAA
  end
  return grp:IsAAA() --  only AAA
end

--- [INTERNAL] Filter Function - Optimized with cached calls
--  @param Wrapper.Group#GROUP Group
--  @return #boolean isin
function TIRESIAS._FilterSAM(Group)
  local grp = Group --  Wrapper.Group#GROUP
  --  Cache method calls to reduce overhead
  local is_ground = grp:IsGround()
  if (not is_ground) or grp:IsShip() then
    return false --  not SAM
  end
  return grp:IsSAM() --  only SAM
end

--- [INTERNAL] Init Groups - Optimized with reduced function calls
--  @param #TIRESIAS self
--  @return #TIRESIAS self
function TIRESIAS:_InitGroups()
self:T(self.lid .. " _InitGroups" )

--  Cache frequently used values
local EngageRange = self.AAARange
local SwitchAAA = self.SwitchAAA

--  Pre-create data structures to avoid repeated table creation
local aaa_data_template = {
  type = " AAA" ,
  invisible = true,
  range = EngageRange,
  exception = false,
  AIOff = SwitchAAA,
  }

local vehicle_data_template = {
  type = " Vehicle" ,
  invisible = true,
  AIOff = true,
  exception = false,
  }

local sam_data_template = {
  type = " SAM" ,
  invisible = true,
  exception = false,
  }

--- AAA - Optimized loop
self.AAASet:ForEachGroupAlive(
  function(grp)
    local tiresias_data = grp.Tiresias
    if not tiresias_data then
      grp:OptionEngageRange(EngageRange)
      grp:SetCommandInvisible(true)
      if SwitchAAA then
        grp:SetAIOff()
        grp:EnableEmission(false)
      end
      grp.Tiresias = aaa_data_template
    elseif not tiresias_data.exception == true then
      if not tiresias_data.invisible == true then
        grp:SetCommandInvisible(true)
        tiresias_data.invisible = true
        if SwitchAAA == true then
          grp:SetAIOff()
          grp:EnableEmission(false)
          tiresias_data.AIOff = true
        end
      end
    end
  end
  )

--- Vehicles - Optimized loop
self.VehicleSet:ForEachGroupAlive(
  function(grp)
    local tiresias_data = grp.Tiresias
    if not tiresias_data then
      grp:SetAIOff()
      grp:SetCommandInvisible(true)
      grp.Tiresias = vehicle_data_template
    elseif not tiresias_data.exception == true then
      if not tiresias_data.invisible then
        grp:SetCommandInvisible(true)
        grp:SetAIOff()
        tiresias_data.invisible = true
        tiresias_data.AIOff = true
      end
    end  
  end
  )

--- SAM - Optimized loop
self.SAMSet:ForEachGroupAlive(
  function(grp)
    local tiresias_data = grp.Tiresias
    if not tiresias_data then
      grp:SetCommandInvisible(true)
      grp.Tiresias = sam_data_template
    elseif not tiresias_data.exception == true then
      if not tiresias_data.invisible then
        grp:SetCommandInvisible(true)
        tiresias_data.invisible = true
      end
    end
  end
  )

return self
end

--- [INTERNAL] Event handler function - Optimized
--  @param #TIRESIAS self
--  @param Core.Event#EVENTDATA EventData
--  @return #TIRESIAS self
function TIRESIAS:_EventHandler(EventData)
  self:T(string.format(" %s Event = %d" , self.lid, EventData.id))
  
  local event = EventData --  Core.Event#EVENTDATA
  if event.id == EVENTS.PlayerEnterAircraft or event.id == EVENTS.PlayerEnterUnit then
    local _group = event.IniGroup
    if _group and _group:IsAlive() then
      --  Cache the radius calculation
      local radius = _group:IsHelicopter() and self.HeloSwitchRange or self.PlaneSwitchRange
      self:_SwitchOnGroups(_group, radius)
    end
  end
  return self
end

--- [INTERNAL] Switch Groups Behaviour - Optimized with zone caching
--  @param #TIRESIAS self
--  @param Wrapper.Group#GROUP group
--  @param #number radius Radius in NM
--  @return #TIRESIAS self
function TIRESIAS:_SwitchOnGroups(group, radius)
  self:T(self.lid .. " _SwitchOnGroups "  .. group:GetName() .. "  Radius "  .. radius .. "  NM" )
  
  --  Use cached zones to reduce object creation
  local group_name = group:GetName()
  local cache_key = group_name .. " _"  .. radius
  local zone = self._cached_zones[cache_key] -- Core.Zone#ZONE_RADIUS
  --local ground = self._cached_groupsets[cache_key] -- Core.Set#SET_GROUP
  
  if not zone then
    zone = ZONE_GROUP:New(" Zone-"  .. group_name, group, UTILS.NMToMeters(radius))
    self._cached_zones[cache_key] = zone
  else
    --  Update zone center to current group position
    zone:UpdateFromGroup(group)
  end
  
  --if not ground then
    --ground = SET_GROUP:New():FilterCategoryGround():FilterZones({zone}):FilterOnce()
    --self._cached_groupsets[cache_key] = ground
  --else
    --ground:FilterZones({zone},true):FilterOnce()
  zone:Scan({Object.Category.UNIT},{Unit.Category.GROUND_UNIT})
  local ground = zone:GetScannedSetGroup()
  --end
  
  local count = ground:CountAlive()
  
  if self.debug then
    self:I(string.format(" There are %d groups around this plane or helo!" , count))
  end
  
  if count > 0 then
  --  Cache values outside the loop
  local SwitchAAA = self.SwitchAAA
  local group_coalition = group:GetCoalition()
  
  ground:ForEachGroupAlive(
    function(grp)
      local tiresias_data = grp.Tiresias
      if grp:GetCoalition() ~= group_coalition 
         and tiresias_data 
         and tiresias_data.type 
         and not tiresias_data.exception == true then
        
        -- Make group visible if invisible
        if tiresias_data.invisible == true then
          grp:SetCommandInvisible(false)
          tiresias_data.invisible = false
        end
        
        -- Handle AI activation based on type
        local grp_type = tiresias_data.type
        if grp_type == "Vehicle" and tiresias_data.AIOff == true then
          grp:SetAIOn()
          tiresias_data.AIOff = false
        elseif SwitchAAA == true and grp_type == "AAA" and tiresias_data.AIOff == true then
          grp:SetAIOn()
          grp:EnableEmission(true)
          tiresias_data.AIOff = false
        end
      else
        BASE:T("TIRESIAS - This group " .. tostring(grp:GetName()) .. " has not been initialized or is an exception!")
      end
    end
  )
  
  end
  return self
end

-----

--- 
--  FSM Functions
----

--- [INTERNAL] FSM Function - Optimized initialization
--  @param #TIRESIAS self
--  @param #string From
--  @param #string Event
--  @param #string To
--  @return #TIRESIAS self
function TIRESIAS:onafterStart(From, Event, To)
self:T({From, Event, To})

--  Create sets with optimized filters
local VehicleSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterNotAAA):FilterFunction(TIRESIAS._FilterNotSAM):FilterStart()
local AAASet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterAAA):FilterStart()
local SAMSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterSAM):FilterStart()
local OpsGroupSet = SET_OPSGROUP:New():FilterActive(true):FilterStart()
self.FlightSet = SET_GROUP:New():FilterCategories({" plane" ," helicopter" }):FilterStart()

--  Cache frequently used values
local EngageRange = self.AAARange
local SwitchAAA = self.SwitchAAA
local ExceptionSet = self.ExceptionSet

--  Pre-create data templates to reduce object creation
local exception_data = {
  type = " Exception" ,
  exception = true,
  }

local vehicle_data = {
  type = " Vehicle" ,
  invisible = true,
  AIOff = true,
  exception = false,
  }

local aaa_data = {
  type = " AAA" ,
  invisible = true,
  range = EngageRange,
  exception = false,
  AIOff = SwitchAAA,
  }

local sam_data = {
  type = " SAM" ,
  invisible = true,
  exception = false,
  }

if ExceptionSet then  
  function ExceptionSet:OnAfterAdded(From, Event, To, ObjectName, Object)
    BASE:I(" TIRESIAS: EXCEPTION Object Added: "  .. Object:GetName())
    if Object and Object:IsAlive() then
      Object.Tiresias = exception_data
      Object:SetAIOn()
      Object:SetCommandInvisible(false)
      Object:EnableEmission(true)
    end
  end

  -- Process existing OpsGroups more efficiently
  local OGS = OpsGroupSet:GetAliveSet()
  for _, _OG in pairs(OGS or {}) do
    local OG = _OG -- Ops.OpsGroup#OPSGROUP
    local grp = OG:GetGroup()  
    ExceptionSet:AddGroup(grp, true)
  end
  
  function OpsGroupSet:OnAfterAdded(From, Event, To, ObjectName, Object)
    local grp = Object:GetGroup()
    ExceptionSet:AddGroup(grp, true)
  end
end

--  Optimized event handlers with pre-created data objects
function VehicleSet:OnAfterAdded(From, Event, To, ObjectName, Object)
  BASE:T(" TIRESIAS: VEHICLE Object Added: "  .. Object:GetName())
  if Object and Object:IsAlive() then
    Object:SetAIOff()
    Object:SetCommandInvisible(true)
    Object.Tiresias = vehicle_data
  end
end
  
function AAASet:OnAfterAdded(From, Event, To, ObjectName, Object)
  if Object and Object:IsAlive() then
    BASE:I(" TIRESIAS: AAA Object Added: "  .. Object:GetName())
    Object:OptionEngageRange(EngageRange)
    Object:SetCommandInvisible(true)
    if SwitchAAA then
      Object:SetAIOff()
      Object:EnableEmission(false)
    end
    Object.Tiresias = aaa_data
  end
end
  
function SAMSet:OnAfterAdded(From, Event, To, ObjectName, Object)
  if Object and Object:IsAlive() then
    BASE:T(" TIRESIAS: SAM Object Added: "  .. Object:GetName())
    Object:SetCommandInvisible(true)
    Object.Tiresias = sam_data
  end
end
  
  --  Store references
  self.VehicleSet = VehicleSet
  self.AAASet = AAASet
  self.SAMSet = SAMSet
  self.OpsGroupSet = OpsGroupSet
  
  self:_InitGroups()
  
  self:__Status(1)  
  return self
end

--- [INTERNAL] FSM Function
--  @param #TIRESIAS self
--  @param #string From
--  @param #string Event
--  @param #string To
--  @return #TIRESIAS self
function TIRESIAS:onbeforeStatus(From, Event, To)
  self:T({From, Event, To})
  return self:GetState() ~= " Stopped" 
end

--- [INTERNAL] FSM Function - Optimized status processing
--  @param #TIRESIAS self
--  @param #string From
--  @param #string Event
--  @param #string To
--  @return #TIRESIAS self
function TIRESIAS:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  
  if self.debug then
    local count = self.VehicleSet:CountAlive()
    local AAAcount = self.AAASet:CountAlive()
    local SAMcount = self.SAMSet:CountAlive()
    self:I(string.format(" Overall: %d | Vehicles: %d | AAA: %d | SAM: %d" ,
    count + AAAcount + SAMcount, count, AAAcount, SAMcount))
  end
  
  self:_InitGroups()
  
  --  Process flight groups more efficiently
  local flight_count = self.FlightSet:CountAlive()
  if flight_count > 0 then
    local Set = self.FlightSet:GetAliveSet()
    --  Cache range values outside loop
    local helo_range = self.HeloSwitchRange
    local plane_range = self.PlaneSwitchRange
    
    for _, _plane in pairs(Set or {}) do
      local plane = _plane -- Wrapper.Group#GROUP
      local radius = plane:IsHelicopter() and helo_range or plane_range
      self:_SwitchOnGroups(plane, radius)
    end
  end
  
  if self:GetState() ~= " Stopped"  then
    self:__Status(self.Interval)
  end
  
  return self
end

--- [INTERNAL] FSM Function
--  @param #TIRESIAS self
--  @param #string From
--  @param #string Event
--  @param #string To
--  @return #TIRESIAS self
function TIRESIAS:onafterStop(From, Event, To)
  self:T({From, Event, To})
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  --  Clear zone cache on stop to free memory
  self._cached_zones = {}
  return self
end

-----
----  End
-----