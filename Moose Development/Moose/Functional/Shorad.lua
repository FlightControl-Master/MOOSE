--- **Functional** - Short Range Air Defense System.
-- 
-- ===
--
-- ## Features: 
-- 
--   * Short Range Air Defense System
--   * Controls a network of short range air/missile defense groups.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [SHORAD - Short Range Air Defense](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/Functional/Shorad)
-- 
-- ===
-- 
-- ### Author : **applevangelist **
-- 
-- @module Functional.Shorad
-- @image Functional.Shorad.jpg
--
-- Date: Nov 2021
-- Last Update: Jan 2025

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
-- @field #number DefenseHighProb Default 90, maximum detection limit
-- @field #boolean UseEmOnOff Decide if we are using Emission on/off (default) or AlarmState red/green
-- @field #boolean shootandscoot If true, shoot and scoot between zones
-- @field #number SkateNumber Number of zones to consider
-- @field Core.Set#SET_ZONE SkateZones Zones in this set are considered
-- @field #number minscootdist Min distance of the next zone
-- @field #number maxscootdist Max distance of the next zone
-- @field #boolean scootrandomcoord If true, use a random coordinate in the zone and not the center
-- @field #string scootformation Formation to take for scooting, e.g. "Vee" or "Cone"  
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
-- ## Customization options   
--  
--  * myshorad:SwitchDebug(debug)
--  * myshorad:SwitchHARMDefense(onoff)
--  * myshorad:SwitchAGMDefense(onoff)
--  * myshorad:SetDefenseLimits(low,high)
--  * myshorad:SetActiveTimer(seconds)
--  * myshorad:SetDefenseRadius(meters)
--  * myshorad:AddScootZones(ZoneSet,Number,Random,Formation)
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
  UseEmOnOff = true,
  shootandscoot = false,
  SkateNumber = 3,
  SkateZones = nil,
  minscootdist = 100,
  minscootdist = 3000,
  scootrandomcoord = false,  
}

-----------------------------------------------------------------------
-- SHORAD System
-----------------------------------------------------------------------

do
  -- TODO Complete list?
  --- Missile enumerators
  -- @field Harms
  SHORAD.Harms = {
  ["AGM_88"] = "AGM_88",
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
  ["HY-2"] = "HY-2",
  ["ADM_141A"] = "ADM_141A",
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
  -- @param #number Radius Defense radius in meters, used to switch on SHORAD groups **within** this radius
  -- @param #number ActiveTimer Determines how many seconds the systems stay on red alert after wake-up call
  -- @param #string Coalition Coalition, i.e. "blue", "red", or "neutral"
  -- @param #boolean UseEmOnOff Use Emissions On/Off rather than Alarm State Red/Green (default: use Emissions switch)
  -- @return #SHORAD self
  function SHORAD:New(Name, ShoradPrefix, Samset, Radius, ActiveTimer, Coalition, UseEmOnOff) 
    local self = BASE:Inherit( self, FSM:New() )
    self:T({Name, ShoradPrefix, Samset, Radius, ActiveTimer, Coalition})
    
    local GroupSet = SET_GROUP:New():FilterPrefixes(ShoradPrefix):FilterCoalitions(Coalition):FilterCategoryGround():FilterStart()

    self.name = Name or "MyShorad"
    self.Prefixes = ShoradPrefix or "SAM SHORAD"
    self.Radius = Radius or 20000
    self.Coalition = Coalition or "blue"
    self.Samset = Samset or GroupSet
    self.ActiveTimer = ActiveTimer or 600
    self.ActiveGroups = {}
    self.Groupset = GroupSet
    self.DefendHarms = true
    self.DefendMavs = true
    self.DefenseLowProb = 70 -- probability to detect a missile shot, low margin
    self.DefenseHighProb = 90  -- probability to detect a missile shot, high margin
    self.UseEmOnOff = true -- Decide if we are using Emission on/off (default) or AlarmState red/green
    if UseEmOnOff == false then self.UseEmOnOff = UseEmOnOff end
    self:I("*** SHORAD - Started Version 0.3.4")
    -- Set the string id for output to DCS.log file.
    self.lid=string.format("SHORAD %s | ", self.name)
    self:_InitState()
    self:HandleEvent(EVENTS.Shot, self.HandleEventShot)
    
    -- Start State.
    self:SetStartState("Running")
    self:AddTransition("*",             "WakeUpShorad",                 "*")
    self:AddTransition("*",             "CalculateHitZone",             "*")
    self:AddTransition("*",             "ShootAndScoot",                "*")
    
    return self
  end
  
  --- Initially set all groups to alarm state GREEN
  -- @param #SHORAD self
  -- @return #SHORAD self
  function SHORAD:_InitState()
    self:T(self.lid .. " _InitState")
    local table = {}
    local set = self.Groupset
    self:T({set = set})
    local aliveset = set:GetAliveSet() --#table
    for _,_group in pairs (aliveset) do
     if self.UseEmOnOff then
      --_group:SetAIOff()
      _group:EnableEmission(false)
      _group:OptionAlarmStateRed() --Wrapper.Group#GROUP
     else
      _group:OptionAlarmStateGreen() --Wrapper.Group#GROUP
     end
     _group:OptionDisperseOnAttack(30)
    end
    -- gather entropy
    for i=1,100 do
      math.random()
    end
    return self
  end
  
  --- Add a SET_ZONE of zones for Shoot&Scoot
  -- @param #SHORAD self
  -- @param Core.Set#SET_ZONE ZoneSet Set of zones to be used. Units will move around to the next (random) zone between 100m and 3000m away.
  -- @param #number Number Number of closest zones to be considered, defaults to 3.
  -- @param #boolean Random If true, use a random coordinate inside the next zone to scoot to.
  -- @param #string Formation Formation to use, defaults to "Cone". See mission editor dropdown for options.
  -- @return #SHORAD self
  function SHORAD:AddScootZones(ZoneSet, Number, Random, Formation)
    self:T(self.lid .. " AddScootZones")
    self.SkateZones = ZoneSet
    self.SkateNumber = Number or 3
    self.shootandscoot = true
    self.scootrandomcoord = Random
    self.scootformation = Formation or "Cone"   
    return self
  end
  
  --- Switch debug state on
  -- @param #SHORAD self
  -- @param #boolean debug Switch debug on (true) or off (false)
  -- @return #SHORAD self 
  function SHORAD:SwitchDebug(onoff)
    self:T( { onoff } )
    if onoff then
      self:SwitchDebugOn()
    else
      self:SwitchDebugOff()
    end
    return self
  end
  
  --- Switch debug state on
  -- @param #SHORAD self
  -- @return #SHORAD self 
  function SHORAD:SwitchDebugOn()
     self.debug = true
     --tracing
     BASE:TraceOn()
     BASE:TraceClass("SHORAD")
     return self
  end
  
  --- Switch debug state off
  -- @param #SHORAD self
  -- @return #SHORAD self 
  function SHORAD:SwitchDebugOff()
    self.debug = false
    BASE:TraceOff()
    return self
  end
  
  --- Switch defense for HARMs
  -- @param #SHORAD self
  -- @param #boolean onoff
  -- @return #SHORAD self 
  function SHORAD:SwitchHARMDefense(onoff)
    self:T( { onoff } )
    local onoff = onoff or true
    self.DefendHarms = onoff
    return self
  end
  
  --- Switch defense for AGMs
  -- @param #SHORAD self
  -- @param #boolean onoff
  -- @return #SHORAD self 
  function SHORAD:SwitchAGMDefense(onoff)
    self:T( { onoff } )
    local onoff = onoff or true
    self.DefendMavs = onoff
    return self
  end
  
  --- Set defense probability limits
  -- @param #SHORAD self
  -- @param #number low Minimum detection limit, integer 1-100
  -- @param #number high Maximum detection limit integer 1-100
  -- @return #SHORAD self 
  function SHORAD:SetDefenseLimits(low,high)
    self:T( { low, high } )
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
    return self
  end
  
  --- Set the number of seconds a SHORAD site will stay active
  -- @param #SHORAD self
  -- @param #number seconds Number of seconds systems stay active
  -- @return #SHORAD self 
  function SHORAD:SetActiveTimer(seconds)
    self:T(self.lid .. " SetActiveTimer")
    local timer = seconds or 600
    if timer < 0 then
      timer = 600
    end
    self.ActiveTimer = timer
    return self
  end

  --- Set the number of meters for the SHORAD defense zone
  -- @param #SHORAD self
  -- @param #number meters Radius of the defense search zone in meters. #SHORADs in this range around a targeted group will go active 
  -- @return #SHORAD self 
  function SHORAD:SetDefenseRadius(meters)
  self:T(self.lid .. " SetDefenseRadius")
    local radius = meters or 20000
    if radius < 0 then
      radius = 20000
    end
    self.Radius = radius
    return self
  end
  
  --- Set using Emission on/off instead of changing alarm state
  -- @param #SHORAD self
  -- @param #boolean switch Decide if we are changing alarm state or AI state
  -- @return #SHORAD self 
  function SHORAD:SetUsingEmOnOff(switch)
  self:T(self.lid .. " SetUsingEmOnOff")
    self.UseEmOnOff = switch or false
    return self
  end
  
  --- Check if a HARM was fired
  -- @param #SHORAD self
  -- @param #string WeaponName
  -- @return #boolean Returns true for a match
  function SHORAD:_CheckHarms(WeaponName)
    self:T(self.lid .. " _CheckHarms")
    self:T( { WeaponName } )
    local hit = false
    if self.DefendHarms then
      for _,_name in pairs (SHORAD.Harms) do
        if string.find(WeaponName,_name,1,true) then hit = true end
      end
    end
    return hit
  end
  
  --- Check if an AGM was fired
  -- @param #SHORAD self
  -- @param #string WeaponName
  -- @return #boolean Returns true for a match
  function SHORAD:_CheckMavs(WeaponName)
    self:T(self.lid .. " _CheckMavs")
    self:T( { WeaponName } )
    local hit = false
    if self.DefendMavs then
      for _,_name in pairs (SHORAD.Mavs) do
        if string.find(WeaponName,_name,1,true) then hit = true end
      end
    end
    return hit
  end
  
  --- Check the coalition of the attacker
  -- @param #SHORAD self
  -- @param #string Coalition name
  -- @return #boolean Returns false for a match
  function SHORAD:_CheckCoalition(Coalition)
    self:T(self.lid .. " _CheckCoalition")
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
    self:T(self.lid .. " _CheckShotAtShorad")
    local tgtgrp = TargetGroupName
    local shorad = self.Groupset
    local shoradset = shorad:GetAliveSet() --#table
    local returnname = false
    --local TDiff = 1
    for _,_groups in pairs (shoradset) do
      local groupname = _groups:GetName()
      if string.find(groupname, tgtgrp, 1, true) then
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
    self:T(self.lid .. " _CheckShotAtSams")
    local tgtgrp = TargetGroupName
    local shorad = self.Samset
    --local shoradset = shorad:GetAliveSet() --#table
    local shoradset = shorad:GetSet() --#table
    local returnname = false
    for _,_groups in pairs (shoradset) do
      local groupname = _groups:GetName()
      if string.find(groupname, tgtgrp, 1, true) then
        returnname = true
      end
    end
    return returnname
  end
  
  --- Calculate if the missile shot is detected
  -- @param #SHORAD self
  -- @return #boolean Returns true for a detection, else false
  function SHORAD:_ShotIsDetected()
    self:T(self.lid .. " _ShotIsDetected")
    if self.debug then return true end
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
  -- @param #number TargetCat (optional) Category, i.e. Object.Category.UNIT or Object.Category.STATIC
  -- @return #SHORAD self 
  -- @usage Use this function to integrate with other systems, example   
  -- 
  -- local SamSet = SET_GROUP:New():FilterPrefixes("Blue SAM"):FilterCoalitions("blue"):FilterStart()
  -- myshorad = SHORAD:New("BlueShorad", "Blue SHORAD", SamSet, 22000, 600, "blue")
  -- myshorad:SwitchDebug(true)
  -- mymantis = MANTIS:New("BlueMantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
  -- mymantis:AddShorad(myshorad,720)
  -- mymantis:Start()
  function SHORAD:onafterWakeUpShorad(From, Event, To, TargetGroup, Radius, ActiveTimer, TargetCat)
    self:T(self.lid .. " WakeUpShorad")
    self:T({TargetGroup, Radius, ActiveTimer, TargetCat})
    local targetcat = TargetCat or Object.Category.UNIT
    local targetgroup = TargetGroup
    local targetvec2 = nil
    if targetcat == Object.Category.UNIT then
      targetvec2 = GROUP:FindByName(targetgroup):GetVec2()
    elseif targetcat == Object.Category.STATIC then
      targetvec2 = STATIC:FindByName(targetgroup,false):GetVec2()
    else
      local samset = self.Samset
      local sam = samset:GetRandom()
      targetvec2 = sam:GetVec2()
    end
    local targetzone = ZONE_RADIUS:New("Shorad",targetvec2,Radius)  -- create a defense zone to check
    local groupset = self.Groupset --Core.Set#SET_GROUP
    local shoradset = groupset:GetAliveSet() --#table
    
    -- local function to switch off shorad again
    local function SleepShorad(group)
      if group and group:IsAlive() then
        local groupname = group:GetName()
        self.ActiveGroups[groupname] = nil
        if self.UseEmOnOff then
          group:EnableEmission(false)
        else
          group:OptionAlarmStateGreen()
        end
        local text = string.format("Sleeping SHORAD %s", group:GetName())
        self:T(text)
        local m = MESSAGE:New(text,10,"SHORAD"):ToAllIf(self.debug)
        --Shoot and Scoot
        if self.shootandscoot then
          self:__ShootAndScoot(1,group)
        end
      end
    end
    
    -- go through set and find the one(s) to activate
    local TDiff = 4
    for _,_group in pairs (shoradset) do
      
      local groupname = _group:GetName()
      
      if groupname == TargetGroup then
        -- Shot at a SHORAD group
        if self.UseEmOnOff then
          _group:EnableEmission(false)
        end
        _group:OptionAlarmStateGreen()
        self.ActiveGroups[groupname] = nil
        local text = string.format("Shot at SHORAD %s! Evading!", _group:GetName())
        self:T(text)
        local m = MESSAGE:New(text,10,"SHORAD"):ToAllIf(self.debug)
        
        --Shoot and Scoot
        if self.shootandscoot then
          self:__ShootAndScoot(1,_group)
        end
        
      elseif _group:IsAnyInZone(targetzone) then
        -- shot at a group we protect
        local text = string.format("Waking up SHORAD %s", _group:GetName())
        self:T(text)
        local m = MESSAGE:New(text,10,"SHORAD"):ToAllIf(self.debug)
        if self.UseEmOnOff then
          _group:EnableEmission(true)
        end
        _group:OptionAlarmStateRed()
        if self.ActiveGroups[groupname] == nil then -- no timer yet for this group
          self.ActiveGroups[groupname] = { Timing = ActiveTimer }
          local endtime = timer.getTime() + (ActiveTimer * math.random(75,100) / 100 ) -- randomize wakeup a bit
          self.ActiveGroups[groupname].Timer = TIMER:New(SleepShorad,_group):Start(endtime)
          --Shoot and Scoot
          if self.shootandscoot then
            self:__ShootAndScoot(TDiff,_group)
            TDiff=TDiff+1
          end
        end
      end
    end
    return self
  end
  
  --- (Internal) Calculate hit zone of an AGM-88
  -- @param #SHORAD self
  -- @param #table SEADWeapon DCS.Weapon object
  -- @param Core.Point#COORDINATE pos0 Position of the plane when it fired
  -- @param #number height Height when the missile was fired
  -- @param Wrapper.Group#GROUP SEADGroup Attacker group
  -- @return #SHORAD self 
  function SHORAD:onafterCalculateHitZone(From,Event,To,SEADWeapon,pos0,height,SEADGroup)
    self:T("**** Calculating hit zone")
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
          
          local seadset = self.Groupset
          local tgtcoord = targetzone:GetRandomPointVec2()
          local tgtgrp = seadset:FindNearestGroupFromPointVec2(tgtcoord)
          local _targetgroup = nil
          local _targetgroupname = "none"
          local _targetskill = "Random"
          if tgtgrp and tgtgrp:IsAlive() then
            _targetgroup = tgtgrp
            _targetgroupname = tgtgrp:GetName() -- group name
            _targetskill = tgtgrp:GetUnit(1):GetSkill()
            self:T("*** Found Target = ".. _targetgroupname)
            self:WakeUpShorad(_targetgroupname, self.Radius, self.ActiveTimer, Object.Category.UNIT)
          end
        end
      end     
    end
    return self
  end
  
  --- (Internal) Shoot and Scoot
  -- @param #SHORAD self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Group#GROUP Shorad Shorad group
  -- @return #SHORAD self 
  function SHORAD:onafterShootAndScoot(From,Event,To,Shorad)
    self:T( { From,Event,To } )
    local possibleZones = {}
    local mindist = self.minscootdist or 100
    local maxdist = self.maxscootdist or 3000
    if Shorad and Shorad:IsAlive() then
      local NowCoord = Shorad:GetCoordinate()
      for _,_zone in pairs(self.SkateZones.Set) do
        local zone = _zone -- Core.Zone#ZONE_RADIUS
        local dist = NowCoord:Get2DDistance(zone:GetCoordinate())
        if dist >= mindist and dist <= maxdist then
          possibleZones[#possibleZones+1] = zone
          if #possibleZones == self.SkateNumber then break end
        end
      end
      if #possibleZones > 0 and Shorad:GetVelocityKMH() < 2 then
        local rand = math.floor(math.random(1,#possibleZones*1000)/1000+0.5)
        if rand == 0 then rand = 1 end
        self:T(self.lid .. " ShootAndScoot to zone "..rand)
        local ToCoordinate = possibleZones[rand]:GetCoordinate()
        if self.scootrandomcoord then
          ToCoordinate = possibleZones[rand]:GetRandomCoordinate(nil,nil,{land.SurfaceType.LAND,land.SurfaceType.ROAD})         
        end
        local formation = self.scootformation or "Cone"
        Shorad:RouteGroundTo(ToCoordinate,20,formation,1)
      end
    end
    return self
  end
  
  --- Main function - work on the EventData
  -- @param #SHORAD self
  -- @param Core.Event#EVENTDATA EventData The event details table data set
  -- @return #SHORAD self 
  function SHORAD:HandleEventShot( EventData )
    self:T( { EventData } )
    self:T(self.lid .. " HandleEventShot")
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
      local m = MESSAGE:New(text,10,"Info"):ToAllIf(self.debug)
      --
      if (self:_CheckHarms(ShootingWeaponName) or self:_CheckMavs(ShootingWeaponName)) and IsDetected then
        -- get target data
        local targetdata = EventData.Weapon:getTarget() -- Identify target
        -- Is there target data?
        if not targetdata or self.debug then 
          if string.find(ShootingWeaponName,"AGM_88",1,true) then
            self:I("**** Tracking AGM-88 with no target data.")
            local pos0 = EventData.IniUnit:GetCoordinate()
            local fheight = EventData.IniUnit:GetHeight()
            self:__CalculateHitZone(20,ShootingWeapon,pos0,fheight,EventData.IniGroup)
          end  
          return self
        end
        
        local targetcat = Object.getCategory(targetdata) -- Identify category
        self:T(string.format("Target Category (3=STATIC, 1=UNIT)= %s",tostring(targetcat)))
        self:T({targetdata})
        local targetunit = nil
        if targetcat == Object.Category.UNIT then -- UNIT
          targetunit = UNIT:Find(targetdata)
        elseif targetcat == Object.Category.STATIC then  -- STATIC
          local tgtcoord = COORDINATE:NewFromVec3(targetdata:getPoint())
         local tgtgrp1 = self.Samset:FindNearestGroupFromPointVec2(tgtcoord)
          local tgtcoord1 = tgtgrp1:GetCoordinate()
          local tgtgrp2 = self.Groupset:FindNearestGroupFromPointVec2(tgtcoord)
          local tgtcoord2 = tgtgrp2:GetCoordinate()
          local dist1 = tgtcoord:Get2DDistance(tgtcoord1)
          local dist2 = tgtcoord:Get2DDistance(tgtcoord2)
          
          if dist1 < dist2 then
            targetunit = tgtgrp1
            targetcat = Object.Category.UNIT
          else
            targetunit = tgtgrp2
            targetcat = Object.Category.UNIT
          end
        end   
        if targetunit and targetunit:IsAlive() then
          local targetunitname = targetunit:GetName()
          local targetgroup = nil
          local targetgroupname = "none"
          if targetcat == Object.Category.UNIT then
            if targetunit.ClassName == "UNIT" then
              targetgroup = targetunit:GetGroup()
            elseif targetunit.ClassName == "GROUP" then
              targetgroup = targetunit
            end
            targetgroupname = targetgroup:GetName() -- group name
          elseif targetcat == Object.Category.STATIC then
            targetgroup = targetunit
            targetgroupname = targetunitname
          end
          local text = string.format("%s Missile Target = %s", self.lid, tostring(targetgroupname))
          self:T( text )
          local m = MESSAGE:New(text,10,"Info"):ToAllIf(self.debug)
          -- check if we or a SAM site are the target 
          local shotatus = self:_CheckShotAtShorad(targetgroupname) --#boolean
          local shotatsams = self:_CheckShotAtSams(targetgroupname) --#boolean
          -- if being shot at, find closest SHORADs to activate
          if shotatsams or shotatus then
            self:T({shotatsams=shotatsams,shotatus=shotatus})
            self:WakeUpShorad(targetgroupname, self.Radius, self.ActiveTimer, targetcat)
          end
        end  
      end
    end
    return self
  end 
--
end
-----------------------------------------------------------------------
-- SHORAD end
-----------------------------------------------------------------------
