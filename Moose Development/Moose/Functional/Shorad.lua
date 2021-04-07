--- **Functional** -- Short Range Air Defense System
-- 
-- ===
-- 
-- **SHORAD** - Short Range Air Defense System
-- Controls a network of short range air/missile defense groups.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [SHORAD - Short Range Air Defense](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SRD%20-%20SHORAD%20Defense)
-- 
-- ===
-- 
-- ### Author : **applevangelist **
-- 
-- @module Functional.Shorad
-- @image Functional.Shorad.jpg
--
-- Date: Feb 2021

-------------------------------------------------------------------------
--- **SHORAD** class, extends Core.Base#BASE
-- @type SHORAD
-- @field #string ClassName
-- @field #string name Name of this Shorad
-- @field #boolean debug Set the debug state
-- @field #string Prefixes String to be used to build the @{#Core.Set#SET_GROUP} 
-- @field #number Radius Shorad defense radius in meters
-- @field Core.Set#SET_GROUP Groupset The set of Shorad groups
-- @field Core.Set#SET_GROUP Samset The set of SAM groups to defend
-- @field #string Coalition The coalition of this Shorad
-- @field #number ActiveTimer How long a Shorad stays active after wake-up in seconds
-- @field #table ActiveGroups Table for the timer function
-- @field #string lid The log ID for the dcs.log
-- @field #boolean DefendHarms Default true, intercept incoming HARMS
-- @field #boolean DefendMavs Default true, intercept incoming AG-Missiles
-- @field #number DefenseLowProb Default 70, minimum detection limit
-- @field #number DefenseHighProb Default 90, maximim detection limit
-- @field #boolean UseAIOnOff Decide if we are using AI on/off (true) or AlarmState red/green (default).
-- @extends Core.Base#BASE

--- *Good friends are worth defending.* Mr Tushman, Wonder (the Movie) 
-- 
-- Simple Class for a more intelligent Short Range Air Defense System
-- 
-- #SHORAD
-- Moose derived missile intercepting short range defense system.
-- Protects a network of SAM sites. Uses events to switch on the defense groups closest to the enemy.
-- Easily integrated with @{Functional.Mantis#MANTIS} to complete the defensive system setup.
--
-- ## Usage
--
-- Set up a #SET_GROUP for the SAM sites to be protected:  
-- 
--        `local SamSet = SET_GROUP:New():FilterPrefixes("Red SAM"):FilterCoalitions("red"):FilterStart()`   
--    
-- By default, SHORAD will defense against both HARMs and AG-Missiles with short to medium range. The default defense probability is 70-90%.
-- When a missile is detected, SHORAD will activate defense groups in the given radius around the target for 10 minutes. It will *not* react to friendly fire.    
--        
-- ### Start a new SHORAD system, parameters are:
--   
--  * Name: Name of this SHORAD.  
--  * ShoradPrefix: Filter for the Shorad #SET_GROUP.  
--  * Samset: The #SET_GROUP of SAM sites to defend.  
--  * Radius: Defense radius in meters. 
--  * ActiveTimer: Determines how many seconds the systems stay on red alert after wake-up call.  
--  * Coalition: Coalition, i.e. "blue", "red", or "neutral".* 
--    
--        `myshorad = SHORAD:New("RedShorad", "Red SHORAD", SamSet, 25000, 600, "red")`       
--
-- ## Customize options   
--  
--  * SHORAD:SwitchDebug(debug)
--  * SHORAD:SwitchHARMDefense(onoff)
--  * SHORAD:SwitchAGMDefense(onoff)
--  * SHORAD:SetDefenseLimits(low,high)
--  * SHORAD:SetActiveTimer(seconds)
--  * SHORAD:SetDefenseRadius(meters)
--
-- @field #SHORAD
SHORAD = {
  ClassName = "SHORAD",
  name = "MyShorad",
  debug = false,
  Prefixes = "",
  Radius = 20000,
  Groupset = nil,
  Samset = nil,
  Coalition = nil,
  ActiveTimer = 600, --stay on 10 mins
  ActiveGroups = {},
  lid = "",
  DefendHarms = true,
  DefendMavs = true,
  DefenseLowProb = 70,
  DefenseHighProb = 90,
  UseAIOnOff = false,  
}

-----------------------------------------------------------------------
-- SHORAD System
-----------------------------------------------------------------------

do
  -- TODO Complete list?
  --- Missile enumerators
  -- @field Harms
  SHORAD.Harms = {
  --[[
  ["X58"] = "weapons.missiles.X_58", --Kh-58X anti-radiation missiles fired
  ["Kh25"] = "weapons.missiles.Kh25MP_PRGS1VP", --Kh-25MP anti-radiation missiles fired
  ["X25"] = "weapons.missiles.X_25MP", --Kh-25MPU anti-radiation missiles fired
  ["X28"] = "weapons.missiles.X_28", --Kh-28 anti-radiation missiles fired
  ["X31"] = "weapons.missiles.X_31P", --Kh-31P anti-radiation missiles fired
  ["AGM45A"] = "weapons.missiles.AGM_45A", --AGM-45A anti-radiation missiles fired
  ["AGM45"] = "weapons.missiles.AGM_45", --AGM-45B anti-radiation missiles fired
  ["AGM88"] = "weapons.missiles.AGM_88", --AGM-88C anti-radiation missiles fired
  ["AGM122"] = "weapons.missiles.AGM_122", --AGM-122 Sidearm anti-radiation missiles fired
  ["LD10"] = "weapons.missiles.LD-10", --LD-10 anti-radiation missiles fired
  ["ALARM"] = "weapons.missiles.ALARM", --ALARM anti-radiation missiles fired
  ["AGM84E"] = "weapons.missiles.AGM_84E", --AGM84 anti-radiation missiles fired
  ["AGM84A"] = "weapons.missiles.AGM_84A", --AGM84 anti-radiation missiles fired
  ["AGM84H"] = "weapons.missiles.AGM_84H", --AGM84 anti-radiation missiles fired
  --]]
  ["AGM_88"] = "AGM_88",
  ["AGM_45"] = "AGM_45",
  ["AGM_122"] = "AGM_122",
  ["AGM_84"] = "AGM_84",
  ["AGM_45"] = "AGM_45",
  ["ALARN"] = "ALARM",
  ["LD-10"] = "LD-10",
  ["X_58"] = "X_58",
  ["X_28"] = "X_28",
  ["X_25"] = "X_25",
  ["X_31"] = "X_31",
  ["Kh25"] = "Kh25",
  }
  
  --- TODO complete list?
  -- @field Mavs
  SHORAD.Mavs = {
  ["AGM"] = "AGM",
  ["C-701"] = "C-701",
  ["Kh25"] = "Kh25",
  ["Kh29"] = "Kh29",
  ["Kh31"] = "Kh31",
  ["Kh66"] = "Kh66",
  }
  
  --- Instantiates a new SHORAD object
  -- @param #SHORAD self
  -- @param #string Name Name of this SHORAD
  -- @param #string ShoradPrefix Filter for the Shorad #SET_GROUP
  -- @param Core.Set#SET_GROUP Samset The #SET_GROUP of SAM sites to defend
  -- @param #number Radius Defense radius in meters, used to switch on groups
  -- @param #number ActiveTimer Determines how many seconds the systems stay on red alert after wake-up call
  -- @param #string Coalition Coalition, i.e. "blue", "red", or "neutral"
  function SHORAD:New(Name, ShoradPrefix, Samset, Radius, ActiveTimer, Coalition) 
    local self = BASE:Inherit( self, BASE:New() )
    self:F({Name, ShoradPrefix, Samset, Radius, ActiveTimer, Coalition})
    
    local GroupSet = SET_GROUP:New():FilterPrefixes(ShoradPrefix):FilterCoalitions(Coalition):FilterCategoryGround():FilterStart()

    self.name = Name or "MyShorad"
    self.Prefixes = ShoradPrefix or "SAM SHORAD"
    self.Radius = Radius or 20000
    self.Coalition = Coalition or "blue"
    self.Samset = Samset or GroupSet
    self.ActiveTimer = ActiveTimer or 600
    self.ActiveGroups = {}
    self.Groupset = GroupSet
    self:HandleEvent( EVENTS.Shot )
    self.DefendHarms = true
    self.DefendMavs = true
    self.DefenseLowProb = 70 -- probability to detect a missile shot, low margin
    self.DefenseHighProb = 90  -- probability to detect a missile shot, high margin
    self.UseAIOnOff = false -- Decide if we are using AI on/off (true) or AlarmState red/green (default)
    self:I("*** SHORAD - Started Version 0.1.0")
    -- Set the string id for output to DCS.log file.
    self.lid=string.format("SHORAD %s | ", self.name)
    self:_InitState()
    return self
  end
  
  --- Initially set all groups to alarm state GREEN
  -- @param #SHORAD self
  function SHORAD:_InitState()
    local table = {}
    local set = self.Groupset
    self:T({set = set})
    local aliveset = set:GetAliveSet() --#table
    for _,_group in pairs (aliveset) do
     if self.UseAIOnOff then
      _group:SetAIOff()
     else
      _group:OptionAlarmStateGreen() --Wrapper.Group#GROUP
     end
    end
    -- gather entropy
    for i=1,10 do
      math.random()
    end
  end
  
  --- Switch debug state
  -- @param #SHORAD self
  -- @param #boolean debug Switch debug on (true) or off (false)
  function SHORAD:SwitchDebug(debug)
    self:F( { debug } )
    local onoff = debug or false
    if debug then
       self.debug = true
       --tracing
       BASE:TraceOn()
       BASE:TraceClass("SHORAD")
    else
      self.debug = false
      BASE:TraceOff()
    end
  end
  
  --- Switch defense for HARMs
  -- @param #SHORAD self
  -- @param #boolean onoff
  function SHORAD:SwitchHARMDefense(onoff)
    self:F( { onoff } )
    local onoff = onoff or true
    self.DefendHarms = onoff
  end
  
  --- Switch defense for AGMs
  -- @param #SHORAD self
  -- @param #boolean onoff
  function SHORAD:SwitchAGMDefense(onoff)
    self:F( { onoff } )
    local onoff = onoff or true
    self.DefendMavs = onoff
  end
  
  --- Set defense probability limits
  -- @param #SHORAD self
  -- @param #number low Minimum detection limit, integer 1-100
  -- @param #number high Maximum detection limit integer 1-100
  function SHORAD:SetDefenseLimits(low,high)
    self:F( { low, high } )
    local low = low or 70
    local high = high or 90
    if (low < 0) or (low > 100) or (low > high) then
      low = 70
    end
    if (high < 0) or (high > 100) or (high < low ) then
      high = 90
    end
    self.DefenseLowProb = low
    self.DefenseHighProb = high
  end
  
  --- Set the number of seconds a SHORAD site will stay active
  -- @param #SHORAD self
  -- @param #number seconds Number of seconds systems stay active
  function SHORAD:SetActiveTimer(seconds)
    local timer = seconds or 600
    if timer < 0 then
      timer = 600
    end
    self.ActiveTimer = timer
  end

  --- Set the number of meters for the SHORAD defense zone
  -- @param #SHORAD self
  -- @param #number meters Radius of the defense search zone in meters. #SHORADs in this range around a targeted group will go active 
  function SHORAD:SetDefenseRadius(meters)
    local radius = meters or 20000
    if radius < 0 then
      radius = 20000
    end
    self.Radius = radius
  end
  
  --- Set using AI on/off instead of changing alarm state
  -- @param #SHORAD self
  -- @param #boolean switch Decide if we are changing alarm state or AI state
  function SHORAD:SetUsingAIOnOff(switch)
    self.UseAIOnOff = switch or false
  end
  
  --- Check if a HARM was fired
  -- @param #SHORAD self
  -- @param #string WeaponName
  -- @return #boolean Returns true for a match
  function SHORAD:_CheckHarms(WeaponName)
    self:F( { WeaponName } )
    local hit = false
    if self.DefendHarms then
      for _,_name in pairs (SHORAD.Harms) do
        if string.find(WeaponName,_name,1) then hit = true end
      end
    end
    return hit
  end
  
  --- Check if an AGM was fired
  -- @param #SHORAD self
  -- @param #string WeaponName
  -- @return #boolean Returns true for a match
  function SHORAD:_CheckMavs(WeaponName)
    self:F( { WeaponName } )
    local hit = false
    if self.DefendMavs then
      for _,_name in pairs (SHORAD.Mavs) do
        if string.find(WeaponName,_name,1) then hit = true end
      end
    end
    return hit
  end
  
  --- Check the coalition of the attacker
  -- @param #SHORAD self
  -- @param #string Coalition name
  -- @return #boolean Returns false for a match
  function SHORAD:_CheckCoalition(Coalition)
    local owncoalition = self.Coalition
    local othercoalition = ""
    if Coalition == 0 then 
      othercoalition = "neutral"
    elseif Coalition == 1 then
      othercoalition = "red"
    else
      othercoalition = "blue"
    end
    self:T({owncoalition = owncoalition, othercoalition = othercoalition})
    if owncoalition ~= othercoalition then
      return true
    else
      return false
    end
  end
  
  --- Check if the missile is aimed at a SHORAD
  -- @param #SHORAD self
  -- @param #string TargetGroupName Name of the target group
  -- @return #boolean Returns true for a match, else false
  function SHORAD:_CheckShotAtShorad(TargetGroupName)
    local tgtgrp = TargetGroupName
    local shorad = self.Groupset
    local shoradset = shorad:GetAliveSet() --#table
    local returnname = false
    for _,_groups in pairs (shoradset) do
      local groupname = _groups:GetName()
      if string.find(groupname, tgtgrp, 1) then
        returnname = true
      end
    end
    return returnname  
  end
  
  --- Check if the missile is aimed at a SAM site
  -- @param #SHORAD self
  -- @param #string TargetGroupName Name of the target group
  -- @return #boolean Returns true for a match, else false
  function SHORAD:_CheckShotAtSams(TargetGroupName)
    local tgtgrp = TargetGroupName
    local shorad = self.Samset
    local shoradset = shorad:GetAliveSet() --#table
    local returnname = false
    for _,_groups in pairs (shoradset) do
      local groupname = _groups:GetName()
      if string.find(groupname, tgtgrp, 1) then
        returnname = true
      end
    end
    return returnname
  end
  
  --- Calculate if the missile shot is detected
  -- @param #SHORAD self
  -- @return #boolean Returns true for a detection, else false
  function SHORAD:_ShotIsDetected()
    local IsDetected = false
    local DetectionProb = math.random(self.DefenseLowProb, self.DefenseHighProb)  -- reference value
    local ActualDetection = math.random(1,100) -- value for this shot
    if ActualDetection <= DetectionProb then
      IsDetected = true
    end
    return IsDetected
  end
  
  --- Wake up #SHORADs in a zone with diameter Radius for ActiveTimer seconds
  -- @param #SHORAD self
  -- @param #string TargetGroup Name of the target group used to build the #ZONE
  -- @param #number Radius Radius of the #ZONE
  -- @param #number ActiveTimer Number of seconds to stay active
  -- @usage Use this function to integrate with other systems, example   
  -- 
  -- local SamSet = SET_GROUP:New():FilterPrefixes("Blue SAM"):FilterCoalitions("blue"):FilterStart()
  -- myshorad = SHORAD:New("BlueShorad", "Blue SHORAD", SamSet, 22000, 600, "blue")
  -- myshorad:SwitchDebug(true)
  -- mymantis = MANTIS:New("BlueMantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
  -- mymantis:AddShorad(myshorad,720)
  -- mymantis:Start()
  function SHORAD:WakeUpShorad(TargetGroup, Radius, ActiveTimer)
    self:F({TargetGroup, Radius, ActiveTimer})
    local targetgroup = GROUP:FindByName(TargetGroup)
    local targetzone = ZONE_GROUP:New("Shorad",targetgroup,Radius) -- create a defense zone to check
    local groupset = self.Groupset --Core.Set#SET_GROUP
    local shoradset = groupset:GetAliveSet() --#table
    -- local function to switch off shorad again
    local function SleepShorad(group)
      local groupname = group:GetName()
      self.ActiveGroups[groupname] = nil
      if self.UseAIOnOff then
        group:SetAIOff()
      else
        group:OptionAlarmStateGreen()
      end
      local text = string.format("Sleeping SHORAD %s", group:GetName())
      self:T(text)
      local m = MESSAGE:New(text,10,"SHORAD"):ToAllIf(self.debug)
    end
    -- go through set and find the one(s) to activate
    for _,_group in pairs (shoradset) do
      if _group:IsAnyInZone(targetzone) then
        local text = string.format("Waking up SHORAD %s", _group:GetName())
        self:T(text)
        local m = MESSAGE:New(text,10,"SHORAD"):ToAllIf(self.debug)
        if self.UseAIOnOff then
          _group:SetAIOn()
        end
        _group:OptionAlarmStateRed()
        local groupname = _group:GetName()
        if self.ActiveGroups[groupname] == nil then -- no timer yet for this group
          self.ActiveGroups[groupname] = { Timing = ActiveTimer }
          local endtime = timer.getTime() + (ActiveTimer * math.random(75,100) / 100 ) -- randomize wakeup a bit
          timer.scheduleFunction(SleepShorad, _group, endtime)
        end
      end
    end
  end
  
  --- Main function - work on the EventData
  -- @param #SHORAD self
  -- @param Core.Event#EVENTDATA EventData The event details table data set
  function SHORAD:OnEventShot( EventData )
    self:F( { EventData } )
  
    --local ShootingUnit = EventData.IniDCSUnit
    --local ShootingUnitName = EventData.IniDCSUnitName
    local ShootingWeapon = EventData.Weapon -- Identify the weapon fired
    local ShootingWeaponName = EventData.WeaponName -- return weapon type
    -- get firing coalition
    local weaponcoalition = EventData.IniGroup:GetCoalition()
    -- get detection probability
    if self:_CheckCoalition(weaponcoalition) then --avoid overhead on friendly fire
      local IsDetected = self:_ShotIsDetected()
      -- convert to text
      local DetectedText = "false"
      if IsDetected then 
        DetectedText = "true"
      end
      local text = string.format("%s Missile Launched = %s | Detected probability state is %s", self.lid, ShootingWeaponName, DetectedText)
      self:T( text )
      local m = MESSAGE:New(text,15,"Info"):ToAllIf(self.debug)
      --
      if (self:_CheckHarms(ShootingWeaponName) or self:_CheckMavs(ShootingWeaponName)) and IsDetected then
        -- get target data
        local targetdata = EventData.Weapon:getTarget() -- Identify target
        local targetunitname = Unit.getName(targetdata) -- Unit name
        local targetgroup = Unit.getGroup(Weapon.getTarget(ShootingWeapon)) --targeted group
        local targetgroupname = targetgroup:getName() -- group name
        -- check if we or a SAM site are the target 
        --local TargetGroup = EventData.TgtGroup -- Wrapper.Group#GROUP
        local shotatus = self:_CheckShotAtShorad(targetgroupname) --#boolean
        local shotatsams = self:_CheckShotAtSams(targetgroupname) --#boolean
        -- if being shot at, find closest SHORADs to activate
        if shotatsams or shotatus then
          self:T({shotatsams=shotatsams,shotatus=shotatus})
          self:WakeUpShorad(targetgroupname, self.Radius, self.ActiveTimer)
        end
      end
    end
  end 
--
end
-----------------------------------------------------------------------
-- SHORAD end
-----------------------------------------------------------------------
