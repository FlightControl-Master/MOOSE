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
-- @field Core.Set#SET_CLIENT PilotSet
-- @field Core.Set#SET_GROUP GroundSet
-- @field #string CoalitionText
-- @field #number Coalition
-- @field Core.Set#SET_GROUP VehicleSet
-- @field Core.Set#SET_GROUP AAASet
-- @field Core.Set#SET_GROUP SAMSet
-- @field #number AAARange
-- @field #number HeloSwitchRange
-- @field #number PlaneSwitchRange
-- @field Core.Set#SET_GROUP FlightSet
-- @extends Core.Fsm#FSM

---
-- @type TIRESIAS.Data
-- @field #string type
-- @field #number range
-- @field #boolean invisible
-- @field #boolean AIOff


---
-- # Documentation
-- 
-- @field TIRESIAS
TIRESIAS = {
  ClassName = "TIRESIAS",
  debug = true,
  version = "0.0.1",
  Interval = 20,
  PilotSet = nil,
  GroundSet = nil,
  CoalitionText = "blue",
  Coalition = coalition.side.BLUE,
  VehicleSet = nil,
  AAASet = nil,
  SAMSet = nil,
  AAARange = 60,
  HeloSwitchRange = 10, -- NM
  PlaneSwitchRange = 25, -- NM
}

---
-- @param #TIRESIAS self
-- @return #TIRESIAS self 
function TIRESIAS:New()
  
    -- Inherit everything from FSM class.
    local self = BASE:Inherit(self, FSM:New()) -- #TIRESIAS
    
    self.PilotSet = SET_CLIENT:New():FilterActive(true):FilterCoalitions(self.CoalitionText):FilterStart()
    
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
  self:I(self.lid.."_InitGroups")
  -- Set all groups invisible/motionless
  local EngageRange = self.AAARange
  self.AAASet:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then 
        grp:OptionEngageRange(EngageRange)
        grp:SetCommandInvisible(true)
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "AAA",
          invisible = true,
          range = EngageRange,
        }
      end
      if grp.Tiresias and grp.Tiresias.invisible and grp.Tiresias.invisible == false then
        grp:SetCommandInvisible(true)
      end
    end
  )
  self.VehicleSet:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then
        grp:SetAIOff()
        grp:SetCommandInvisible(true)
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "Vehicle",
          invisible = true,
          AIOff = true,
        }
      end
      if grp.Tiresias and grp.Tiresias.invisible and grp.Tiresias.invisible == false then
        grp:SetCommandInvisible(true)
        grp:SetAIOff()
      end
    end
  )
  self.SAMSet:ForEachGroupAlive(
    function(grp)
      if not grp.Tiresias then
        grp:SetCommandInvisible(true)
        grp.Tiresias = { -- #TIRESIAS.Data
          type = "SAM",
          invisible = true,
        }
      end
      if grp.Tiresias and grp.Tiresias.invisible and grp.Tiresias.invisible == false then
        grp:SetCommandInvisible(true)
      end
    end
  )
  return self
end

--- (Internal) Event handler function
-- @param #TIRESIAS self
-- @param Core.Event#EVENTDATA EventData
-- @return #TIRESIAS self
function TIRESIAS:_EventHandler(EventData)
  self:I(string.format("%s Event = %d",self.lid, EventData.id))
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
  self:I(self.lid.."_SwitchOnGroups "..group:GetName().." Radius "..radius.." NM")
  local zone = ZONE_GROUP:New("Zone-"..group:GetName(),group,UTILS.NMToMeters(radius))
  local ground = SET_GROUP:New():FilterCategoryGround():FilterZones({zone}):FilterOnce()
  local count = ground:CountAlive()
  if self.debug then
    local text = string.format("There are %d groups around this plane or helo!",count)
    self:I(text)
  end
  if ground:CountAlive() > 0 then
    ground:ForEachGroupAlive(
      function(grp)
        if grp.Tiresias and grp.Tiresias.type then
          if grp.Tiresias.invisible == true then
            grp:SetCommandInvisible(false)
            grp.Tiresias.invisible = false
          end
          if grp.Tiresias.type == "Vehicle" and grp.Tiresias.AIOff and grp.Tiresias.AIOff == false then
            grp:SetAIOn()
            grp.Tiresias.AIOff = false
          end
        else
          BASE:I("TIRESIAS - This group has not been initialized!")
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
  self:I({From, Event, To})
  
  local VehicleSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(TIRESIAS._FilterAAA):FilterFunction(TIRESIAS._FilterSAM):FilterStart()
  local AAASet = SET_GROUP:New():FilterCategoryGround():FilterFunction(function(grp) return grp:IsAAA() end):FilterStart()
  local SAMSet = SET_GROUP:New():FilterCategoryGround():FilterFunction(function(grp) return grp:IsSAM() end):FilterStart()
  self.FlightSet = SET_GROUP:New():FilterCategories({"plane","helicopter"}):FilterStart()
  
  local EngageRange = self.AAARange
  
  function VehicleSet:OnAfterAdded(From,Event,To,ObjectName,Object)
    BASE:I("TIRESIAS: VEHCILE Object Added: "..Object:GetName())
    if Object and Object:IsAlive() then
      Object:SetAIOff()
      Object:SetCommandInvisible(true)
      Object.Tiresias = { -- #TIRESIAS.Data
        type = "Vehicle",
        invisible = true,
        AIOff = true,
      }
    end
  end
  
  function AAASet:OnAfterAdded(From,Event,To,ObjectName,Object)
    if Object and Object:IsAlive() then
      BASE:I("TIRESIAS: AAA Object Added: "..Object:GetName())
      Object:OptionEngageRange(EngageRange)
      Object:SetCommandInvisible(true)
      Object.Tiresias = { -- #TIRESIAS.Data
        type = "AAA",
        invisible = true,
        range = EngageRange,
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
  self:I({From, Event, To})
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
  self:I({From, Event, To})
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  return self
end

-------------------------------------------------------------------------------------------------------------
--
-- End
-- 
-------------------------------------------------------------------------------------------------------------
