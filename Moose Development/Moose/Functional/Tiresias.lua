--- **Functional** - TIRESIAS - manages AI behaviour.
--
-- ===
-- 
-- The @{#TIRESIAS} class is working in the back to keep your large-scale ground units in check.
-- 
-- ## Features:
--
--  * Designed to keep CPU and Network usage lower on missions with a lot of ground units.
--  * Does not affect ships to keep the Navy guys happy.
--  * Does not affect OpsGroup type groups.
--  * Distinguishes between SAM groups, AAA groups and other ground groups.
--  * Exceptions can be defined to keep certain actions going.
--  * Works coalition-independent in the back
--  * Easy setup.
--
-- ===
--
-- ## Missions:
--
-- ### [TIRESIAS](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master)
--
-- ===
--
-- ### Author : **applevangelist **
--
-- @module Functional.Tiresias
-- @image Functional.Tiresias.jpg
--
-- Last Update: Dec 2023

-------------------------------------------------------------------------
--- **TIRESIAS** class, extends Core.Base#BASE
-- @type TIRESIAS
-- @field #string ClassName
-- @field #booelan debug
-- @field #string version
-- @field #number Interval
-- @field Core.Set#SET_GROUP GroundSet
-- @field #number Coalition
-- @field Core.Set#SET_GROUP VehicleSet
-- @field Core.Set#SET_GROUP AAASet
-- @field Core.Set#SET_GROUP SAMSet
-- @field Core.Set#SET_GROUP ExceptionSet
-- @field Core.Set#SET_OPSGROUP OpsGroupSet
-- @field #number AAARange
-- @field #number HeloSwitchRange
-- @field #number PlaneSwitchRange
-- @field Core.Set#SET_GROUP FlightSet
-- @field #boolean SwitchAAA 
-- @extends Core.Fsm#FSM

---
-- @type TIRESIAS.Data
-- @field #string type
-- @field #number range
-- @field #boolean invisible
-- @field #boolean AIOff
-- @field #boolean exception


--- *Tiresias, Greek demi-god and shapeshifter, blinded by the Gods, works as oracle for you.* (Wiki)
--
-- ===
--
-- ## TIRESIAS Concept
-- 
--  * Designed to keep CPU and Network usage lower on missions with a lot of ground units.
--  * Does not affect ships to keep the Navy guys happy.
--  * Does not affect OpsGroup type groups.
--  * Distinguishes between SAM groups, AAA groups and other ground groups.
--  * Exceptions can be defined in SET_GROUP objects to keep certain actions going.
--  * Works coalition-independent in the back
--  * Easy setup.
-- 
-- ## Setup
-- 
-- Setup is a one-liner:
-- 
--          local blinder = TIRESIAS:New()
--          
-- Optionally you can set up exceptions, e.g. for convoys driving around
-- 
--          local exceptionset = SET_GROUP:New():FilterCoalitions("red"):FilterPrefixes("Convoy"):FilterStart()
--          local blinder = TIRESIAS:New()
--          blinder:AddExceptionSet(exceptionset)
-- 
-- Options 
-- 
--          -- Setup different radius for activation around helo and airplane groups (applies to AI and humans)
--          blinder:SetActivationRanges(10,25) -- defaults are 10, and 25
--
--          -- Setup engagement ranges for AAA (non-advanced SAM units like Flaks etc) and if you want them to be AIOff
--          blinder:SetAAARanges(60,true) -- defaults are 60, and true
--
-- @field #TIRESIAS
TIRESIAS = {
  ClassName = "TIRESIAS",
  debug = false,
  version = "0.0.5",
  Interval = 20,
  GroundSet = nil,
  VehicleSet = nil,
  AAASet = nil,
  SAMSet = nil,
  ExceptionSet = nil,
  AAARange = 60, -- 60%
  HeloSwitchRange = 10, -- NM
  PlaneSwitchRange = 25, -- NM
  SwitchAAA = true,
}

--- [USER] Create a new Tiresias object and start it up.
-- @param #TIRESIAS self
-- @return #TIRESIAS self 
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
    
    self.ExceptionSet = SET_GROUP:New():Clear(false)
    
    self:HandleEvent(EVENTS.PlayerEnterAircraft,self._EventHandler)
    
    self.lid = string.format("TIRESIAS %s | ",self.version)
    
    self:I(self.lid.."Managing ground groups!")
    
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

-------------------------------------------------------------------------------------------------------------
--
-- Helper Functions
-- 
-------------------------------------------------------------------------------------------------------------

---[USER] Set activation radius for Helos and Planes in Nautical Miles.
-- @param #TIRESIAS self
-- @param #number HeloMiles Radius around a Helicopter in which AI ground units will be activated. Defaults to 10NM.
-- @param #number PlaneMiles Radius around an Airplane in which AI ground units will be activated. Defaults to 25NM.
-- @return #TIRESIAS self 
function TIRESIAS:SetActivationRanges(HeloMiles,PlaneMiles)
  self.HeloSwitchRange = HeloMiles or 10
  self.PlaneSwitchRange = PlaneMiles or 25
  return self
end

---[USER] Set AAA Ranges - AAA equals non-SAM systems which qualify as AAA in DCS world.
-- @param #TIRESIAS self
-- @param #number FiringRange The engagement range that AAA units will be set to. Can be 0 to 100 (percent). Defaults to 60.
-- @param #boolean SwitchAAA Decide if these system will have their AI switched off, too. Defaults to true.
-- @return #TIRESIAS self 
function TIRESIAS:SetAAARanges(FiringRange,SwitchAAA)
  self.AAARange = FiringRange or 60
  self.SwitchAAA = (SwitchAAA == false) and false or true
  return self
end

--- [USER] Add a SET_GROUP of GROUP objects as exceptions. Can be done multiple times. Does **not** work work for GROUP objects spawned into the SET after start, i.e. the groups need to exist in the game already.
-- @param #TIRESIAS self
-- @param Core.Set#SET_GROUP Set to add to the exception list.
-- @return #TIRESIAS self
function TIRESIAS:AddExceptionSet(Set)
  self:T(self.lid.."AddExceptionSet")
  local exceptions = self.ExceptionSet
  Set:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "Exception",
          exception = true,
        }
       exceptions:AddGroup(grp,true)
      end
      BASE:T("TIRESIAS: Added exception group: "..grp:GetName())
    end
  )  
  return self
end

--- [INTERNAL] Filter Function
-- @param Wrapper.Group#GROUP Group
-- @return #boolean isin
function TIRESIAS._FilterNotAAA(Group)
  local grp = Group -- Wrapper.Group#GROUP
  local isaaa = grp:IsAAA()
  if isaaa == true and grp:IsGround() and not grp:IsShip() then 
    return false -- remove from SET
  else
    return true -- keep in SET
  end
end

--- [INTERNAL] Filter Function
-- @param Wrapper.Group#GROUP Group
-- @return #boolean isin
function TIRESIAS._FilterNotSAM(Group)
  local grp = Group -- Wrapper.Group#GROUP
  local issam = grp:IsSAM()
  if issam == true and grp:IsGround() and not grp:IsShip()  then 
    return false -- remove from SET
  else
    return true -- keep in SET
  end
end

--- [INTERNAL] Filter Function
-- @param Wrapper.Group#GROUP Group
-- @return #boolean isin
function TIRESIAS._FilterAAA(Group)
  local grp = Group -- Wrapper.Group#GROUP
  local isaaa = grp:IsAAA()
  if isaaa == true and grp:IsGround() and not grp:IsShip() then 
    return true -- remove from SET
  else
    return false -- keep in SET
  end
end

--- [INTERNAL] Filter Function
-- @param Wrapper.Group#GROUP Group
-- @return #boolean isin
function TIRESIAS._FilterSAM(Group)
  local grp = Group -- Wrapper.Group#GROUP
  local issam = grp:IsSAM()
  if issam == true and grp:IsGround() and not grp:IsShip()  then 
    return true -- remove from SET
  else
    return false -- keep in SET
  end
end

--- [INTERNAL] Init Groups
-- @param #TIRESIAS self
-- @return #TIRESIAS self
function TIRESIAS:_InitGroups()
  self:T(self.lid.."_InitGroups")
  -- Set all groups invisible/motionless
  local EngageRange = self.AAARange
  local SwitchAAA = self.SwitchAAA
  --- AAA
  self.AAASet:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then 
        grp:OptionEngageRange(EngageRange)
        grp:SetCommandInvisible(true)
        if SwitchAAA then
          grp:SetAIOff()
          grp:EnableEmission(false)
        end
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "AAA",
          invisible = true,
          range = EngageRange,
          exception = false,
          AIOff = SwitchAAA,
        }
      end
      if grp.Tiresias and (not grp.Tiresias.exception == true) then
        if grp.Tiresias.invisible == false then
          grp:SetCommandInvisible(true)
          grp.Tiresias.invisible = true
          if SwitchAAA then
            grp:SetAIOff()
            grp:EnableEmission(false)
            grp.Tiresias.AIOff = true
          end
        end
      end
      --BASE:I(string.format("Init/Switch off AAA %s (Exception %s)",grp:GetName(),tostring(grp.Tiresias.exception)))
    end
  )
  --- Vehicles
  self.VehicleSet:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then
        grp:SetAIOff()
        grp:SetCommandInvisible(true)
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "Vehicle",
          invisible = true,
          AIOff = true,
          exception = false,
        }
      end
      if grp.Tiresias and (not grp.Tiresias.exception == true) then
        if grp.Tiresias and grp.Tiresias.invisible == false then
          grp:SetCommandInvisible(true)
          grp:SetAIOff()
          grp.Tiresias.invisible = true
          grp.Tiresias.AIOff = true
        end
      end     
      --BASE:I(string.format("Init/Switch off Vehicle %s (Exception %s)",grp:GetName(),tostring(grp.Tiresias.exception)))
    end
  )
  --- SAM
  self.SAMSet:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then
        grp:SetCommandInvisible(true)
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "SAM",
          invisible = true,
          exception = false,
        }
      end
      if grp.Tiresias and (not grp.Tiresias.exception == true) then
        if grp.Tiresias and grp.Tiresias.invisible == false then
          grp:SetCommandInvisible(true)
          grp.Tiresias.invisible = true
        end
      end
      --BASE:I(string.format("Init/Switch off SAM %s (Exception %s)",grp:GetName(),tostring(grp.Tiresias.exception)))
    end
  )
  return self
end

--- [INTERNAL] Event handler function
-- @param #TIRESIAS self
-- @param Core.Event#EVENTDATA EventData
-- @return #TIRESIAS self
function TIRESIAS:_EventHandler(EventData)
  self:T(string.format("%s Event = %d",self.lid, EventData.id))
  local event = EventData -- Core.Event#EVENTDATA
  if event.id == EVENTS.PlayerEnterAircraft or event.id == EVENTS.PlayerEnterUnit then
    --local _coalition = event.IniCoalition
    --if _coalition ~= self.Coalition then
      --  return --ignore!
    --end
    local unitname = event.IniUnitName or "none"
    local _unit = event.IniUnit
    local _group = event.IniGroup
    if _group and _group:IsAlive() then
      local radius = self.PlaneSwitchRange
      if _group:IsHelicopter() then
        radius = self.HeloSwitchRange
      end
      self:_SwitchOnGroups(_group,radius)
    end
  end
  return self
end

--- [INTERNAL] Switch Groups Behaviour
-- @param #TIRESIAS self
-- @param Wrapper.Group#GROUP group
-- @param #number radius Radius in NM
-- @return #TIRESIAS self
function TIRESIAS:_SwitchOnGroups(group,radius)
  self:T(self.lid.."_SwitchOnGroups "..group:GetName().." Radius "..radius.." NM")
  local zone = ZONE_GROUP:New("Zone-"..group:GetName(),group,UTILS.NMToMeters(radius))
  local ground = SET_GROUP:New():FilterCategoryGround():FilterZones({zone}):FilterOnce()
  local count = ground:CountAlive()
  if self.debug then
    local text = string.format("There are %d groups around this plane or helo!",count)
    self:I(text)
  end
  local SwitchAAA = self.SwitchAAA
  if ground:CountAlive() > 0 then
    ground:ForEachGroupAlive(
      function(grp)
        local name = grp:GetName()
        if grp:GetCoalition() ~= group:GetCoalition()
                            and grp.Tiresias and grp.Tiresias.type and (not grp.Tiresias.exception == true ) then
          if grp.Tiresias.invisible == true then
            grp:SetCommandInvisible(false)
            grp.Tiresias.invisible = false
          end
          if grp.Tiresias.type == "Vehicle" and grp.Tiresias.AIOff and grp.Tiresias.AIOff == true then
            grp:SetAIOn()
            grp.Tiresias.AIOff = false
          end
          if SwitchAAA and grp.Tiresias.type == "AAA" and grp.Tiresias.AIOff and grp.Tiresias.AIOff == true then
            grp:SetAIOn()
            grp:EnableEmission(true)
            grp.Tiresias.AIOff = false
          end
          --BASE:I(string.format("TIRESIAS - Switch on %s %s (Exception %s)",tostring(grp.Tiresias.type),grp:GetName(),tostring(grp.Tiresias.exception)))
        else
          BASE:T("TIRESIAS - This group "..tostring(name).. " has not been initialized or is an exception!")
        end
      end
    )
  end
  return self
end

-------------------------------------------------------------------------------------------------------------
--
-- FSM Functions
-- 
-------------------------------------------------------------------------------------------------------------

--- [INTERNAL] FSM Function
-- @param #TIRESIAS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TIRESIAS self
function TIRESIAS:onafterStart(From, Event, To)
  self:T({From, Event, To})
  
  local VehicleSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterNotAAA):FilterFunction(TIRESIAS._FilterNotSAM):FilterStart()
  local AAASet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterAAA):FilterStart()
  local SAMSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterSAM):FilterStart()
  local OpsGroupSet = SET_OPSGROUP:New():FilterActive(true):FilterStart()
  self.FlightSet = SET_GROUP:New():FilterCategories({"plane","helicopter"}):FilterStart()
  
  local EngageRange = self.AAARange
  
  local ExceptionSet = self.ExceptionSet
  if self.ExceptionSet then   
    function ExceptionSet:OnAfterAdded(From,Event,To,ObjectName,Object)
      BASE:I("TIRESIAS: EXCEPTION Object Added: "..Object:GetName())
      if Object and Object:IsAlive() then
        Object.Tiresias = { -- #TIRESIAS.Data
          type = "Exception",
          exception = true,
        }
      Object:SetAIOn()
      Object:SetCommandInvisible(false)
      Object:EnableEmission(true)
      end
    end
  
    local OGS = OpsGroupSet:GetAliveSet()
    for _,_OG in pairs(OGS or {}) do
      local OG = _OG -- Ops.OpsGroup#OPSGROUP
      local grp = OG:GetGroup()
      ExceptionSet:AddGroup(grp,true)
    end
    
    function OpsGroupSet:OnAfterAdded(From,Event,To,ObjectName,Object)
      local grp = Object:GetGroup()
      ExceptionSet:AddGroup(grp,true)
    end
  end
  
  function VehicleSet:OnAfterAdded(From,Event,To,ObjectName,Object)
    BASE:I("TIRESIAS: VEHCILE Object Added: "..Object:GetName())
    if Object and Object:IsAlive() then
      Object:SetAIOff()
      Object:SetCommandInvisible(true)
      Object.Tiresias = { -- #TIRESIAS.Data
        type = "Vehicle",
        invisible = true,
        AIOff = true,
        exception = false,
      }
    end
  end
  
  local SwitchAAA = self.SwitchAAA
  
  function AAASet:OnAfterAdded(From,Event,To,ObjectName,Object)
    if Object and Object:IsAlive() then
      BASE:I("TIRESIAS: AAA Object Added: "..Object:GetName())
      Object:OptionEngageRange(EngageRange)
      Object:SetCommandInvisible(true)
      if SwitchAAA then
          Object:SetAIOff()
          Object:EnableEmission(false)
      end
      Object.Tiresias = { -- #TIRESIAS.Data
          type = "AAA",
          invisible = true,
          range = EngageRange,
          exception = false,
          AIOff = SwitchAAA,
        }
    end
  end
  
  function SAMSet:OnAfterAdded(From,Event,To,ObjectName,Object)
    if Object and Object:IsAlive() then
      BASE:I("TIRESIAS: SAM Object Added: "..Object:GetName())
      Object:SetCommandInvisible(true)
      Object.Tiresias = { -- #TIRESIAS.Data
        type = "SAM",
        invisible = true,
        exception = false,
      }
    end
  end
  
  self.VehicleSet = VehicleSet
  self.AAASet = AAASet
  self.SAMSet = SAMSet
  self.OpsGroupSet = OpsGroupSet
  
  self:_InitGroups()
  
  self:__Status(1)    
  return self
end

--- [INTERNAL] FSM Function
-- @param #TIRESIAS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TIRESIAS self
function TIRESIAS:onbeforeStatus(From, Event, To)
  self:T({From, Event, To})
  if self:GetState() == "Stopped" then
    return false
  end
  return self
end

--- [INTERNAL] FSM Function
-- @param #TIRESIAS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TIRESIAS self
function TIRESIAS:onafterStatus(From, Event, To)
  self:T({From, Event, To})
    if self.debug then
    local count = self.VehicleSet:CountAlive()
    local AAAcount = self.AAASet:CountAlive()
    local SAMcount = self.SAMSet:CountAlive()
    local text = string.format("Overall: %d | Vehicles: %d | AAA: %d | SAM: %d",count+AAAcount+SAMcount,count,AAAcount,SAMcount)
    self:I(text)
  end
  self:_InitGroups()
  if self.FlightSet:CountAlive() > 0 then
    local Set = self.FlightSet:GetAliveSet()
    for _,_plane in pairs(Set) do
      local plane = _plane -- Wrapper.Group#GROUP
      local radius = self.PlaneSwitchRange
      if plane:IsHelicopter() then
        radius = self.HeloSwitchRange
      end
      self:_SwitchOnGroups(_plane,radius)
    end
  end
  if self:GetState() ~= "Stopped" then
    self:__Status(self.Interval)
  end
  return self
end

--- [INTERNAL] FSM Function
-- @param #TIRESIAS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TIRESIAS self
function TIRESIAS:onafterStop(From, Event, To)
  self:T({From, Event, To})
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  return self
end

-------------------------------------------------------------------------------------------------------------
--
-- End
-- 
-------------------------------------------------------------------------------------------------------------
