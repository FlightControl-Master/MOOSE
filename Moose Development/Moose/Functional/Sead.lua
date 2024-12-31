--- **Functional** - Make SAM sites evasive and execute defensive behaviour when being fired upon.
--
-- ===
--
-- ## Features:
--
--   * When SAM sites are being fired upon, the SAMs will take evasive action will reposition themselves when possible.
--   * When SAM sites are being fired upon, the SAMs will take defensive action by shutting down their radars.
--   * SEAD calculates the time it takes for a HARM to reach the target - and will attempt to minimize the shut-down time.
--   * Detection and evasion of shots has a random component based on the skill level of the SAM groups.
--
-- ===
--
-- ## Missions:
--
-- [SEV - SEAD Evasion](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/Functional/Sead)
--
-- ===
--
-- ### Authors: **applevangelist**, **FlightControl**
--
-- Last Update: Dec 2024
--
-- ===
--
-- @module Functional.Sead
-- @image SEAD.JPG

---
-- @type SEAD
-- @field #string ClassName The Class Name.
-- @field #table TargetSkill Table of target skills.
-- @field #table SEADGroupPrefixes Table of SEAD prefixes.
-- @field #table SuppressedGroups Table of currently suppressed groups.
-- @field #number EngagementRange Engagement Range.
-- @field #number Padding Padding in seconds.
-- @field #function CallBack Callback function for suppression plans.
-- @field #boolean UseCallBack Switch for callback function to be used.
-- @field #boolean debug Debug switch.
-- @field #boolen WeaponTrack Track switch, if true track weapon speed for 30 secs.
-- @extends Core.Base#BASE

--- Make SAM sites execute evasive and defensive behaviour when being fired upon.
--
-- This class is very easy to use. Just setup a SEAD object by using @{#SEAD.New}() and SAMs will evade and take defensive action when being fired upon.
-- Once a HARM attack is detected, SEAD will shut down the radars of the attacked SAM site and take evasive action by moving the SAM
-- vehicles around (*if* they are driveable, that is). There's a component of randomness in detection and evasion, which is based on the
-- skill set of the SAM set (the higher the skill, the more likely). When a missile is fired from far away, the SAM will stay active for a 
-- period of time to stay defensive, before it takes evasive actions.
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
  EngagementRange = 75, --  default 75% engagement range Feature Request #1355
  Padding = 15,
  CallBack = nil,
  UseCallBack = false,
  debug = false,
  WeaponTrack = false,
}

  --- Missile enumerators
  -- @field Harms
  SEAD.Harms = {
  ["AGM_88"] = "AGM_88",
  ["AGM_122"] = "AGM_122",
  ["AGM_84"] = "AGM_84",
  ["AGM_45"] = "AGM_45",
  ["AGM_65"] = "AGM_65",
  ["ALARM"] = "ALARM",
  ["LD-10"] = "LD-10",
  ["X_58"] = "X_58",
  ["X_28"] = "X_28",
  ["X_25"] = "X_25",
  ["X_31"] = "X_31",
  ["Kh25"] = "Kh25",
  ["BGM_109"] = "BGM_109",
  ["AGM_154"] = "AGM_154",
  ["HY-2"] = "HY-2",
  ["ADM_141A"] = "ADM_141A",
  }

  --- Missile enumerators - from DCS ME and Wikipedia
  -- @field HarmData
  SEAD.HarmData = {
  -- km and mach
  ["AGM_88"] = { 150, 3},
  ["AGM_45"] = { 12, 2},
  ["AGM_65"] = { 16, 0.9},
  ["AGM_122"] = { 16.5, 2.3},
  ["AGM_84"] = { 280, 0.8},
  ["ALARM"] = { 45, 2},
  ["LD-10"] = { 60, 4},
  ["X_58"] = { 70, 4},
  ["X_28"] = { 80, 2.5},
  ["X_25"] = { 25, 0.76},
  ["X_31"] = {150, 3},
  ["Kh25"] = {25, 0.8},
  ["BGM_109"] = {460, 0.705}, --in-game ~465kn
  ["AGM_154"] = {130, 0.61},
  ["HY-2"] = {90,1},
  ["ADM_141A"] = {126,0.6},
  }

--- Creates the main object which is handling defensive actions for SA sites or moving SA vehicles.
-- When an anti radiation missile is fired (KH-58, KH-31P, KH-31A, KH-25MPU, HARM missiles), the SA will shut down their radars and will take evasive actions...
-- Chances are big that the missile will miss.
-- @param #SEAD self
-- @param #table SEADGroupPrefixes Table of #string entries or single #string, which is a table of Prefixes of the SA Groups in the DCS mission editor on which evasive actions need to be taken.
-- @param #number Padding (Optional) Extra number of seconds to add to radar switch-back-on time
-- @return #SEAD self
-- @usage
-- -- CCCP SEAD Defenses
-- -- Defends the Russian SA installations from SEAD attacks.
-- SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
function SEAD:New( SEADGroupPrefixes, Padding )

  local self = BASE:Inherit( self, FSM:New() )
  self:T( SEADGroupPrefixes )

  if type( SEADGroupPrefixes ) == 'table' then
    for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
      self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
    end
  else
    self.SEADGroupPrefixes[SEADGroupPrefixes] = SEADGroupPrefixes
  end

  local padding = Padding or 10
  if padding < 10 then padding = 10 end
  self.Padding = padding
  self.UseEmissionsOnOff = true
  
  self.debug = false
  
  self.CallBack = nil
  self.UseCallBack = false
    
  self:HandleEvent( EVENTS.Shot, self.HandleEventShot )
  
  -- Start State.
  self:SetStartState("Running")
  self:AddTransition("*",             "ManageEvasion",                "*")
  self:AddTransition("*",             "CalculateHitZone",             "*")
  
  self:I("*** SEAD - Started Version 0.4.9")
  return self
end

--- Update the active SEAD Set (while running)
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
-- @param #number range Set the engagement range in percent, e.g. 55 (default 75)
-- @return #SEAD self
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

--- Set the padding in seconds, which extends the radar off time calculated by SEAD
-- @param #SEAD self
-- @param #number Padding Extra number of seconds to add for the switch-on (default 10 seconds)
-- @return #SEAD self
function SEAD:SetPadding(Padding)
  self:T( { Padding } )
  local padding = Padding or 10
  if padding < 10 then padding = 10 end
  self.Padding = padding
  return self
end

--- Set SEAD to use emissions on/off in addition to alarm state.
-- @param #SEAD self
-- @param #boolean Switch True for on, false for off.
-- @return #SEAD self
function SEAD:SwitchEmissions(Switch)
  self:T({Switch})
  self.UseEmissionsOnOff = Switch
  return self
end

--- Set an object to call back when going evasive.
-- @param #SEAD self
-- @param #table Object The object to call. Needs to have object functions as follows:
-- `:SeadSuppressionPlanned(Group, Name, SuppressionStartTime, SuppressionEndTime)` 
-- `:SeadSuppressionStart(Group, Name)`, 
-- `:SeadSuppressionEnd(Group, Name)`, 
-- @return #SEAD self
function SEAD:AddCallBack(Object)
  self:T({Class=Object.ClassName})
  self.CallBack = Object
  self.UseCallBack = true
  return self
end

--- (Internal) Check if a known HARM was fired
-- @param #SEAD self
-- @param #string WeaponName
-- @return #boolean Returns true for a match
-- @return #string name Name of hit in table
function SEAD:_CheckHarms(WeaponName)
  self:T( { WeaponName } )
  local hit = false
  local name = ""
    for _,_name in pairs (SEAD.Harms) do
      if string.find(WeaponName,_name,1,true) then
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
    --self:T({dist1=distance1, dist2=distance2})
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

--- (Internal) Calculate hit zone of an AGM-88
-- @param #SEAD self
-- @param #table SEADWeapon DCS.Weapon object
-- @param Core.Point#COORDINATE pos0 Position of the plane when it fired
-- @param #number height Height when the missile was fired
-- @param Wrapper.Group#GROUP SEADGroup Attacker group
-- @param #string SEADWeaponName Weapon Name
-- @return #SEAD self 
function SEAD:onafterCalculateHitZone(From,Event,To,SEADWeapon,pos0,height,SEADGroup,SEADWeaponName)
  self:T("**** Calculating hit zone for " .. (SEADWeaponName or "None"))
  if SEADWeapon and SEADWeapon:isExist() then
    --local pos = SEADWeapon:getPoint()
    
    -- postion and height
    local position = SEADWeapon:getPosition()
    local mheight = height
    -- heading
    local wph = math.atan2(position.x.z, position.x.x)      
    if wph < 0 then
      wph=wph+2*math.pi
    end   
    wph=math.deg(wph)
    
    -- velocity
    local wpndata = SEAD.HarmData["AGM_88"]
    if string.find(SEADWeaponName,"154",1) then
      wpndata = SEAD.HarmData["AGM_154"]
    end
    local mveloc = math.floor(wpndata[2] * 340.29)
    local c1 = (2*mheight*9.81)/(mveloc^2)
    local c2 = (mveloc^2) / 9.81
    local Ropt = c2 * math.sqrt(c1+1) 
    if height <= 5000 then
      Ropt = Ropt * 0.72
    elseif height <= 7500 then
      Ropt = Ropt * 0.82  
    elseif height <= 10000 then
      Ropt = Ropt * 0.87
    elseif height <= 12500 then
      Ropt = Ropt * 0.98
    end
    
    -- look at a couple of zones across the trajectory
    for n=1,3 do
      local dist = Ropt - ((n-1)*20000)
      local predpos= pos0:Translate(dist,wph)
      if predpos then
  
        local targetzone = ZONE_RADIUS:New("Target Zone",predpos:GetVec2(),20000)
        
        if self.debug then
          predpos:MarkToAll(string.format("height=%dm | heading=%d | velocity=%ddeg | Ropt=%dm",mheight,wph,mveloc,Ropt),false)
          targetzone:DrawZone(coalition.side.BLUE,{0,0,1},0.2,nil,nil,3,true)
        end  
        
        local seadset = SET_GROUP:New():FilterPrefixes(self.SEADGroupPrefixes):FilterZones({targetzone}):FilterOnce()
          local tgtgrp = seadset:GetRandom()
          local _targetgroup = nil
          local _targetgroupname = "none"
          local _targetskill = "Random"
          if tgtgrp and tgtgrp:IsAlive() then
            _targetgroup = tgtgrp
            _targetgroupname = tgtgrp:GetName() -- group name
            _targetskill = tgtgrp:GetUnit(1):GetSkill()
            self:T("*** Found Target = ".. _targetgroupname)
            self:ManageEvasion(_targetskill,_targetgroup,pos0,"AGM_88",SEADGroup, 20)
          end
        --end
      end
    end     
  end
  return self
end

--- (Internal) Handle Evasion
-- @param #SEAD self
-- @param #string _targetskill
-- @param Wrapper.Group#GROUP _targetgroup
-- @param Core.Point#COORDINATE SEADPlanePos
-- @param #string SEADWeaponName
-- @param Wrapper.Group#GROUP SEADGroup Attacker Group
-- @param #number timeoffset Offset for tti calc
-- @param Wrapper.Weapon#WEAPON Weapon
-- @return #SEAD self 
function SEAD:onafterManageEvasion(From,Event,To,_targetskill,_targetgroup,SEADPlanePos,SEADWeaponName,SEADGroup,timeoffset,Weapon)
  local timeoffset = timeoffset  or 0
  if _targetskill == "Random" then -- when skill is random, choose a skill
    local Skills = { "Average", "Good", "High", "Excellent" }
    _targetskill = Skills[ math.random(1,4) ]
  end
  --self:T( _targetskill )
  if self.TargetSkill[_targetskill] then
    local _evade = math.random (1,100) -- random number for chance of evading action
    if (_evade > self.TargetSkill[_targetskill].Evade) then
      self:T("*** SEAD - Evading")
      -- calculate distance of attacker
      local _targetpos = _targetgroup:GetCoordinate()
      local _distance = self:_GetDistance(SEADPlanePos, _targetpos)
      -- weapon speed
      local hit, data = self:_CheckHarms(SEADWeaponName)
      local wpnspeed = 666 -- ;)
      local reach = 10
      if hit then
        local wpndata = SEAD.HarmData[data]
        reach = wpndata[1] * 1.1
        local mach = wpndata[2]
        wpnspeed = math.floor(mach * 340.29)
        if Weapon and Weapon:GetSpeed() > 0 then
          wpnspeed = Weapon:GetSpeed()
          self:T(string.format("*** SEAD - Weapon Speed from WEAPON: %f m/s",wpnspeed))
        end
      end
      -- time to impact
      local _tti = math.floor(_distance / wpnspeed) - timeoffset -- estimated impact time
      if _distance > 0 then
        _distance = math.floor(_distance / 1000) -- km
      else
        _distance = 0
      end
  
      self:T( string.format("*** SEAD - target skill %s, distance %dkm, reach %dkm, tti %dsec", _targetskill, _distance,reach,_tti ))
  
      if reach >= _distance then
        self:T("*** SEAD - Shot in Reach")
  
        local function SuppressionStart(args)
          self:T(string.format("*** SEAD - %s Radar Off & Relocating",args[2]))
          local grp = args[1] -- Wrapper.Group#GROUP
          local name = args[2] -- #string Group Name
          local attacker = args[3] -- Wrapper.Group#GROUP
          if self.UseEmissionsOnOff then
            grp:EnableEmission(false)
          end
          grp:OptionAlarmStateGreen() -- needed else we cannot move around
          grp:RelocateGroundRandomInRadius(20,300,false,false,"Diamond",true)
          if self.UseCallBack then
            local object = self.CallBack
            object:SeadSuppressionStart(grp,name,attacker)
          end
        end
  
        local function SuppressionStop(args)
          self:T(string.format("*** SEAD - %s Radar On",args[2]))
          local grp = args[1]  -- Wrapper.Group#GROUP
          local name = args[2] -- #string Group Name
          if self.UseEmissionsOnOff then
            grp:EnableEmission(true)
          end
          grp:OptionAlarmStateRed()
          grp:OptionEngageRange(self.EngagementRange)
          self.SuppressedGroups[name] = false
          if self.UseCallBack then
            local object = self.CallBack
            object:SeadSuppressionEnd(grp,name)
          end
        end
  
        -- randomize switch-on time
        local delay = math.random(self.TargetSkill[_targetskill].DelayOn[1], self.TargetSkill[_targetskill].DelayOn[2])
        if delay > _tti then delay = delay / 2 end -- speed up
        if _tti > 600 then delay =  _tti - 90 end -- shot from afar, 600 is default shorad ontime
  
        local SuppressionStartTime = timer.getTime() + delay
        local SuppressionEndTime = timer.getTime() + delay + _tti + self.Padding + delay
        local _targetgroupname = _targetgroup:GetName()
        if not self.SuppressedGroups[_targetgroupname] then
          self:T(string.format("*** SEAD - %s | Parameters TTI %ds | Switch-Off in %ds",_targetgroupname,_tti,delay))
          timer.scheduleFunction(SuppressionStart,{_targetgroup,_targetgroupname, SEADGroup},SuppressionStartTime)
          timer.scheduleFunction(SuppressionStop,{_targetgroup,_targetgroupname},SuppressionEndTime)
          self.SuppressedGroups[_targetgroupname] = true
          if self.UseCallBack then
            local object = self.CallBack
            object:SeadSuppressionPlanned(_targetgroup,_targetgroupname,SuppressionStartTime,SuppressionEndTime, SEADGroup)
          end
        end
  
      end
    end
  end
  return self
end

--- (Internal) Detects if an SAM site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @param #SEAD self
-- @param Core.Event#EVENTDATA EventData
-- @return #SEAD self
function SEAD:HandleEventShot( EventData )
  self:T( { EventData.id } )
  
  local SEADWeapon = EventData.Weapon -- Identify the weapon fired
  local SEADWeaponName = EventData.WeaponName or "None" -- return weapon type
  
  if self:_CheckHarms(SEADWeaponName) then
    --UTILS.PrintTableToLog(EventData)
    local SEADPlane = EventData.IniUnit -- Wrapper.Unit#UNIT
    
    if not SEADPlane then return self end -- case IniUnit is empty
    
    local SEADGroup = EventData.IniGroup -- Wrapper.Group#GROUP
    local SEADPlanePos = SEADPlane:GetCoordinate() -- Core.Point#COORDINATE
    local SEADUnit = EventData.IniDCSUnit
    local SEADUnitName = EventData.IniDCSUnitName
  
    local WeaponWrapper = WEAPON:New(EventData.Weapon) -- Wrapper.Weapon#WEAPON
    
    self:T( "*** SEAD - Missile Launched = " .. SEADWeaponName)

    self:T( '*** SEAD - Weapon Match' )
    if self.WeaponTrack == true then
      WeaponWrapper:SetFuncTrack(function(weapon) env.info(string.format("*** Weapon Speed: %d m/s",weapon:GetSpeed() or -1)) end)
      WeaponWrapper:StartTrack(0.1)
      WeaponWrapper:StopTrack(30)
    end
    local _targetskill = "Random"
    local _targetgroupname = "none"
    local _target = EventData.Weapon:getTarget() -- Identify target
    if not _target or self.debug  then -- AGM-88 or 154 w/o target data
      self:E("***** SEAD - No target data for " .. (SEADWeaponName or "None"))
      if string.find(SEADWeaponName,"AGM_88",1,true) or string.find(SEADWeaponName,"AGM_154",1,true) then
        self:T("**** Tracking AGM-88/154 with no target data.")
        local pos0 = SEADPlane:GetCoordinate()
        local fheight = SEADPlane:GetHeight()
        self:__CalculateHitZone(20,SEADWeapon,pos0,fheight,SEADGroup,SEADWeaponName)
      end
      return self
    end
    local targetcat = Object.getCategory(_target) -- Identify category
    local _targetUnit = nil -- Wrapper.Unit#UNIT
    local _targetgroup = nil -- Wrapper.Group#GROUP
    self:T(string.format("*** Targetcat = %d",targetcat))
    if targetcat == Object.Category.UNIT then -- UNIT
      self:T("*** Target Category UNIT")
      _targetUnit = UNIT:Find(_target) -- Wrapper.Unit#UNIT
      if _targetUnit and _targetUnit:IsAlive() then
        _targetgroup = _targetUnit:GetGroup()
        _targetgroupname = _targetgroup:GetName() -- group name
        local _targetUnitName = _targetUnit:GetName()
        _targetUnit:GetSkill()
        _targetskill = _targetUnit:GetSkill()
      end
    elseif targetcat == Object.Category.STATIC then
      self:T("*** Target Category STATIC")
      local seadset = SET_GROUP:New():FilterPrefixes(self.SEADGroupPrefixes):FilterOnce()
      local targetpoint = _target:getPoint() or {x=0,y=0,z=0}
      local tgtcoord = COORDINATE:NewFromVec3(targetpoint)
      local tgtgrp = seadset:FindNearestGroupFromPointVec2(tgtcoord)
      if tgtgrp and tgtgrp:IsAlive() then
        _targetgroup = tgtgrp
        _targetgroupname = tgtgrp:GetName() -- group name
        _targetskill = tgtgrp:GetUnit(1):GetSkill()
        self:T("*** Found Target = ".. _targetgroupname)
      end
    end
    -- see if we are shot at
    local SEADGroupFound = false
    for SEADGroupPrefixID, SEADGroupPrefix in pairs( self.SEADGroupPrefixes ) do
      self:T("Target = ".. _targetgroupname .. " | Prefix = " .. SEADGroupPrefix )
      if string.find( _targetgroupname, SEADGroupPrefix,1,true ) then
        SEADGroupFound = true
        self:T( '*** SEAD - Group Match Found' )
        break
      end
    end
    if SEADGroupFound == true then -- yes we are being attacked
      if string.find(SEADWeaponName,"ADM_141",1,true) then
        self:__ManageEvasion(2,_targetskill,_targetgroup,SEADPlanePos,SEADWeaponName,SEADGroup,2,WeaponWrapper)
      else
        self:ManageEvasion(_targetskill,_targetgroup,SEADPlanePos,SEADWeaponName,SEADGroup,0,WeaponWrapper)
      end
    end
  end
  return self
end
