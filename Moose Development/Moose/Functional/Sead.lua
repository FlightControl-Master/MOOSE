--- **Functional** -- Make SAM sites execute evasive and defensive behaviour when being fired upon.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * When SAM sites are being fired upon, the SAMs will take evasive action will reposition themselves when possible.
--   * When SAM sites are being fired upon, the SAMs will take defensive action by shutting down their radars.
-- 
-- ===
-- 
-- ## Missions:
-- 
-- [SEV - SEAD Evasion](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SEV%20-%20SEAD%20Evasion)
-- 
-- ===
-- 
-- ### Authors: **FlightControl**, **applevangelist**
-- 
-- Last Update: Aug 2021
-- 
-- ===
-- 
-- @module Functional.Sead
-- @image SEAD.JPG

--- @type SEAD
-- @extends Core.Base#BASE

--- Make SAM sites execute evasive and defensive behaviour when being fired upon.
-- 
-- This class is very easy to use. Just setup a SEAD object by using @{#SEAD.New}() and SAMs will evade and take defensive action when being fired upon.
-- 
-- # Constructor:
-- 
-- Use the @{#SEAD.New}() constructor to create a new SEAD object.
-- 
--       SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
-- 
-- @field #SEAD
SEAD = {
  ClassName = "SEAD", 
  TargetSkill = {
    Average   = { Evade = 30, DelayOn = { 40, 60 } } ,
    Good      = { Evade = 20, DelayOn = { 30, 50 } } ,
    High      = { Evade = 15, DelayOn = { 20, 40 } } ,
    Excellent = { Evade = 10, DelayOn = { 10, 30 } } 
  }, 
  SEADGroupPrefixes = {},
  SuppressedGroups = {},
  EngagementRange = 75 --  default 75% engagement range Feature Request #1355
}

  --- Missile enumerators
  -- @field Harms
  SEAD.Harms = {
  ["AGM_88"] = "AGM_88",
  ["AGM_45"] = "AGM_45",
  ["AGM_122"] = "AGM_122",
  ["AGM_84"] = "AGM_84",
  ["AGM_45"] = "AGM_45",
  ["ALARM"] = "ALARM",
  ["LD-10"] = "LD-10",
  ["X_58"] = "X_58",
  ["X_28"] = "X_28",
  ["X_25"] = "X_25",
  ["X_31"] = "X_31",
  ["Kh25"] = "Kh25",
  }
  
  --- Missile enumerators
  -- @field HarmData
  SEAD.HarmData = {
  -- km and mach
  ["AGM_88"] = { 150, 3},
  ["AGM_45"] = { 12, 2},
  ["AGM_122"] = { 16.5, 2.3},
  ["AGM_84"] = { 280, 0.85},
  ["ALARM"] = { 45, 2},
  ["LD-10"] = { 60, 4},
  ["X_58"] = { 70, 4},
  ["X_28"] = { 80, 2.5},
  ["X_25"] = { 25, 0.76},
  ["X_31"] = {150, 3},
  ["Kh25"] = {25, 0.8},
  }
  
--- Creates the main object which is handling defensive actions for SA sites or moving SA vehicles.
-- When an anti radiation missile is fired (KH-58, KH-31P, KH-31A, KH-25MPU, HARM missiles), the SA will shut down their radars and will take evasive actions...
-- Chances are big that the missile will miss.
-- @param #SEAD self
-- @param table{string,...}|string SEADGroupPrefixes which is a table of Prefixes of the SA Groups in the DCS mission editor on which evasive actions need to be taken.
-- @return SEAD
-- @usage
-- -- CCCP SEAD Defenses
-- -- Defends the Russian SA installations from SEAD attacks.
-- SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
function SEAD:New( SEADGroupPrefixes )

  local self = BASE:Inherit( self, BASE:New() )
  self:F( SEADGroupPrefixes )
  
  if type( SEADGroupPrefixes ) == 'table' then
    for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
      self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
    end
  else
    self.SEADGroupPrefixes[SEADGroupPrefixes] = SEADGroupPrefixes
  end
  
  self:HandleEvent( EVENTS.Shot, self.HandleEventShot )
  self:I("*** SEAD - Started Version 0.2.10")
  return self
end

--- Update the active SEAD Set
-- @param #SEAD self
-- @param #table SEADGroupPrefixes The prefixes to add, note: can also be a single #string
-- @return #SEAD self
function SEAD:UpdateSet( SEADGroupPrefixes )

  self:T( SEADGroupPrefixes )
  
  if type( SEADGroupPrefixes ) == 'table' then
    for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
      self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
    end
  else
    self.SEADGroupPrefixes[SEADGroupPrefixes] = SEADGroupPrefixes
  end

  return self
end

--- Sets the engagement range of the SAMs. Defaults to 75% to make it more deadly. Feature Request #1355
-- @param #SEAD self
-- @param #number range Set the engagement range in percent, e.g. 50
-- @return self
function SEAD:SetEngagementRange(range)
  self:T( { range } )
  range = range or 75
  if range < 0 or range > 100 then
    range = 75
  end
  self.EngagementRange = range
  self:T(string.format("*** SEAD - Engagement range set to %s",range))
  return self
end

  --- Check if a known HARM was fired
  -- @param #SEAD self
  -- @param #string WeaponName
  -- @return #boolean Returns true for a match
  -- @return #string name Name of hit in table
  function SEAD:_CheckHarms(WeaponName)
    self:T( { WeaponName } )
    local hit = false
    local name = ""
      for _,_name in pairs (SEAD.Harms) do
        if string.find(WeaponName,_name,1) then 
          hit = true
          name = _name 
          break
        end
      end
    return hit, name
  end

  --- (Internal) Return distance in meters between two coordinates or -1 on error.
  -- @param #SEAD self
  -- @param Core.Point#COORDINATE _point1 Coordinate one
  -- @param Core.Point#COORDINATE _point2 Coordinate two
  -- @return #number Distance in meters
  function SEAD:_GetDistance(_point1, _point2)
    self:T("_GetDistance")
    if _point1 and _point2 then
      local distance1 = _point1:Get2DDistance(_point2)
      local distance2 = _point1:DistanceFromPointVec2(_point2)
      self:I({dist1=distance1, dist2=distance2})
      if distance1 and type(distance1) == "number" then
        return distance1
      elseif distance2 and type(distance2) == "number" then
        return distance2
      else
        self:E("*****Cannot calculate distance!")
        self:E({_point1,_point2})
        return -1
      end
    else
      self:E("******Cannot calculate distance!")
      self:E({_point1,_point2})
      return -1
    end
  end
  
--- Detects if an SAM site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see SEAD
-- @param #SEAD
-- @param Core.Event#EVENTDATA EventData
function SEAD:HandleEventShot( EventData )
  self:T( { EventData } )
  local SEADPlane = EventData.IniUnit -- Wrapper.Unit#UNIT
  local SEADPlanePos = SEADPlane:GetCoordinate() -- Core.Point#COORDINATE
  local SEADUnit = EventData.IniDCSUnit
  local SEADUnitName = EventData.IniDCSUnitName
  local SEADWeapon = EventData.Weapon -- Identify the weapon fired
  local SEADWeaponName = EventData.WeaponName -- return weapon type

  self:T( "*** SEAD - Missile Launched = " .. SEADWeaponName)
  self:T({ SEADWeapon })
  
  if self:_CheckHarms(SEADWeaponName) then
    local _targetskill = "Random"
    local _targetMimgroupName = "none"
    local _evade = math.random (1,100) -- random number for chance of evading action
    local _targetMim = EventData.Weapon:getTarget() -- Identify target
    local _targetUnit = UNIT:Find(_targetMim) -- Wrapper.Unit#UNIT
    local _targetMimgroup = nil -- Wrapper.Group#GROUP
    if _targetUnit and _targetUnit:IsAlive() then
      _targetMimgroup = _targetUnit:GetGroup()
      _targetMimgroupName = _targetMimgroup:GetName() -- group name
      local _targetUnitName = _targetUnit:GetName()
      _targetUnit:GetSkill()
      _targetskill = _targetUnit:GetSkill()
      self:T( self.SEADGroupPrefixes )
      self:T( _targetMimgroupName )
    end
    -- see if we are shot at
    local SEADGroupFound = false
    for SEADGroupPrefixID, SEADGroupPrefix in pairs( self.SEADGroupPrefixes ) do
      self:T( SEADGroupPrefix )
      if string.find( _targetMimgroupName, SEADGroupPrefix, 1, true ) then
        SEADGroupFound = true
        self:T( '*** SEAD - Group Found' )
        break
      end
    end   
    if SEADGroupFound == true then -- yes we are being attacked
      if _targetskill == "Random" then -- when skill is random, choose a skill
        local Skills = { "Average", "Good", "High", "Excellent" }
        _targetskill = Skills[ math.random(1,4) ]
      end
      self:T( _targetskill )
      if self.TargetSkill[_targetskill] then
        if (_evade > self.TargetSkill[_targetskill].Evade) then
          
          -- calculate distance of attacker
          local _targetpos = _targetMimgroup:GetCoordinate()
          local _distance = self:_GetDistance(SEADPlanePos, _targetpos)
          -- weapon speed
          local hit, data = self:_CheckHarms(SEADWeaponName)
          local wpnpeed = 666
          local reach = 10
          if hit then
            local wpndata = SEAD.HarmData[data]
            reach = wpndata[1] * 1,1
            local mach = wpndata[2]
            wpnpeed = math.floor(mach * 340.29)
          end
          -- time to impact
          local _tti = math.floor(_distance / wpnpeed) -- estimated impact time
          if _distance > 0 then
            _distance = math.floor(_distance / 1000) -- km
          else
            _distance = 0
          end
          
          self:T( string.format("*** SEAD - target skill %s, distance %dkm, reach %dkm, tti %dsec", _targetskill, _distance,reach,_tti ))
        
          local _targetMimgroup1 = Unit.getGroup(Weapon.getTarget(SEADWeapon))
          local _targetMimcont1 = _targetMimgroup1:getController()
          
          if reach >= _distance then
            self:T("*** SEAD - Relocating")
            _targetMimgroup:RelocateGroundRandomInRadius(20,300,false,false,"Diamond")
            --routines.groupRandomDistSelf(_targetMimgroup,300,'Diamond',250,20) -- move randomly
            
            --tracker ID table to switch groups off and on again
            local id = { 
            groupName = _targetMimgroup1,
            ctrl = _targetMimcont1
            }
  
            local function SuppressionEnd(id) --switch group back on
             local range = self.EngagementRange -- Feature Request #1355
              --self:T(string.format("*** SEAD - Engagement Range is %d", range))
              self:T("*** SEAD - Radar On")
              id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.RED)
              --id.groupName:enableEmission(true)
              id.ctrl:setOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,range) --Feature Request #1355
              self.SuppressedGroups[id.groupName] = nil  --delete group id from table when done
            end
            -- randomize switch-on time
            local delay = math.random(self.TargetSkill[_targetskill].DelayOn[1], self.TargetSkill[_targetskill].DelayOn[2])
            if delay < _tti then delay = _tti * 1,1 end
            local SuppressionEndTime = timer.getTime() + delay
            --create entry
            if self.SuppressedGroups[id.groupName] == nil then  --no timer entry for this group yet
              self.SuppressedGroups[id.groupName] = {
                SuppressionEndTime = delay
                }
              self:T(string.format("*** SEAD - Radar Off for %dsecs",delay))  
              Controller.setOption(_targetMimcont1, AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
              --_targetMimgroup:enableEmission(false)
              timer.scheduleFunction(SuppressionEnd, id, SuppressionEndTime)  --Schedule the SuppressionEnd() function
            end
          end
        end
      end
    end
  end
end
