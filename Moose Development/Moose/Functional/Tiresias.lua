--- **Functional** - TIRESIAS
--
-- ===
--
-- ## Features:
--
--  * Tbd   
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


---
-- # Documentation
-- 
-- @field #TIRESIAS
TIRESIAS = {
  ClassName = "TIRESIAS",
  debug = false,
  version = "0.0.2",
  Interval = 20,
  GroundSet = nil,
  Coalition = coalition.side.BLUE,
  VehicleSet = nil,
  AAASet = nil,
  SAMSet = nil,
  ExceptionSet = nil,
  AAARange = 60, -- 60%
  HeloSwitchRange = 10, -- NM
  PlaneSwitchRange = 25, -- NM
  SwitchAAA = true,
}

---
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
    
    self:HandleEvent(EVENTS.PlayerEnterAircraft,self._EventHandler)
    
    self.lid = string.format("TIRESIAS %s | ",self.version)
    
    self:I(self.lid.."Managing ground groups!")
    
    self:__Start(1)
  return self
end

-------------------------------------------------------------------------------------------------------------
--
-- Helper Functions
-- 
-------------------------------------------------------------------------------------------------------------

---
-- @param #TIRESIAS self
-- @param Core.Set#SET_GROUP Set
-- @return #TIRESIAS self
function TIRESIAS:AddExceptionSet(Set)
  self:T(self.lid.."AddExceptionSet")
  self.ExceptionSet = Set
  
  Set:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "Exception",
          exception = true,
        }
      end
      BASE:I("TIRESIAS: Added exception group: "..grp:GetName())
    end
  )
  
  return self
end

---
-- @param #TIRESIAS self
-- @param Wrapper.Group#GROUP Group
-- @return #boolean isin
function TIRESIAS._FilterAAA(Group)
  local grp = Group -- Wrapper.Group#GROUP
  local isaaa = grp:IsAAA()
  if isaaa == true and grp:IsGround() then 
    return false -- remove from SET
  else
    return true -- keep in SET
  end
end

---
-- @param #TIRESIAS self
-- @param Wrapper.Group#GROUP Group
-- @return #boolean isin
function TIRESIAS._FilterSAM(Group)
  local grp = Group -- Wrapper.Group#GROUP
  local issam = grp:IsSAM()
  if issam == true and grp:IsGround() then 
    return false -- remove from SET
  else
    return true -- keep in SET
  end
end

---
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
        if  grp.Tiresias.invisible and grp.Tiresias.invisible == false then
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
        if grp.Tiresias and grp.Tiresias.invisible and grp.Tiresias.invisible == false then
          grp:SetCommandInvisible(true)
          grp:SetAIOff()
          grp.Tiresias.invisible = true
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
        if grp.Tiresias and grp.Tiresias.invisible and grp.Tiresias.invisible == false then
          grp:SetCommandInvisible(true)
          grp.Tiresias.invisible = true
        end
      end
      --BASE:I(string.format("Init/Switch off SAM %s (Exception %s)",grp:GetName(),tostring(grp.Tiresias.exception)))
    end
  )
  return self
end

--- (Internal) Event handler function
-- @param #TIRESIAS self
-- @param Core.Event#EVENTDATA EventData
-- @return #TIRESIAS self
function TIRESIAS:_EventHandler(EventData)
  self:T(string.format("%s Event = %d",self.lid, EventData.id))
  local event = EventData -- Core.Event#EVENTDATA
  if event.id == EVENTS.PlayerEnterAircraft or event.id == EVENTS.PlayerEnterUnit then
    local _coalition = event.IniCoalition
    if _coalition ~= self.Coalition then
        return --ignore!
    end
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

---
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
        if grp.Tiresias and grp.Tiresias.type and (not grp.Tiresias.exception == true ) then
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
          BASE:E("TIRESIAS - This group has not been initialized or is an exception!")
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

---
-- @param #TIRESIAS self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #TIRESIAS self
function TIRESIAS:onafterStart(From, Event, To)
  self:T({From, Event, To})
  
  local VehicleSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterAAA):FilterFunction(TIRESIAS._FilterSAM):FilterStart()
  local AAASet = SET_GROUP:New():FilterCategoryGround():FilterFunction(function(grp) return grp:IsAAA() end):FilterStart()
  local SAMSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(function(grp) return grp:IsSAM() end):FilterStart()
  self.FlightSet = SET_GROUP:New():FilterCategories({"plane","helicopter"}):FilterStart()
  
  local EngageRange = self.AAARange
  
  if self.ExceptionSet then
    local ExceptionSet = self.ExceptionSet
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
  
  self:_InitGroups()
  
  self:__Status(1)    
  return self
end

---
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

---
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

---
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
